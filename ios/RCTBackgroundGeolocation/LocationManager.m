////
//  LocationManager
//
//  Created by Marian Hello on 04/06/16.
//  Version 2.0.0
//
//  According to apache license
//
//  This is class is using code from christocracy cordova-plugin-background-geolocation plugin
//  https://github.com/christocracy/cordova-plugin-background-geolocation
//

#import <UIKit/UIKit.h>
#import "LocationManager.h"
#import "LocationUploader.h"
#import "SQLiteLocationDAO.h"
#import "BackgroundTaskManager.h"
#import "Reachability.h"
#import "Logging.h"

// Debug sounds for bg-geolocation life-cycle events.
// http://iphonedevwiki.net/index.php/AudioServices
#define exitRegionSound         1005
#define locationSyncSound       1004
#define paceChangeYesSound      1110
#define paceChangeNoSound       1112
#define acquiringLocationSound  1103
#define acquiredLocationSound   1052
#define locationErrorSound      1073

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define LOCATION_DENIED         "User denied use of location services."
#define LOCATION_RESTRICTED     "Application's use of location services is restricted."
#define LOCATION_NOT_DETERMINED "User undecided on application's use of location services."

static NSString * const Domain = @"com.marianhello";

enum {
    maxLocationWaitTimeInSeconds = 15,
    maxLocationAgeInSeconds = 30
};

@interface LocationManager () <CLLocationManagerDelegate>
@end

@implementation LocationManager {
    BOOL isStarted;
    BOOL isUpdatingLocation;
    BOOL isAcquiringStationaryLocation;
    BOOL isAcquiringSpeed;
    BOOL hasConnectivity;

    BGOperationMode operationMode;
    NSDate *aquireStartTime;
    //    BOOL shouldStart; //indicating intent to start service, but we're waiting for user permission

    CLLocationManager *locationManager;
    Location *lastLocation;
    CLCircularRegion *stationaryRegion;
    NSDate *stationarySince;

    NSMutableArray *locationQueue;
    NSError* locationError;

    UILocalNotification *localNotification;

    NSNumber *maxBackgroundHours;
    UIBackgroundTaskIdentifier bgTask;
    NSDate *lastBgTaskAt;

    // configurable options
    Config *_config;

    LocationUploader *uploader;
    Reachability *reach;
}


- (id) init
{
    self = [super init];

    if (self == nil) {
        return self;
    }

    // background location cache, for when no network is detected.
    locationManager = [[CLLocationManager alloc] init];

    reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    reach.reachableBlock = ^(Reachability *reach){
        // keep in mind this is called on a background thread
        // and if you are updating the UI it needs to happen
        // on the main thread, like this:
        DDLogInfo(@"Network is now reachable");
        hasConnectivity = YES;
    };

    reach.unreachableBlock = ^(Reachability *reach) {
        DDLogInfo(@"Network is now unreachable");
        hasConnectivity = NO;
    };


    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        DDLogDebug(@"LocationManager iOS9 detected");
        locationManager.allowsBackgroundLocationUpdates = YES;
    }

    locationManager.delegate = self;

    localNotification = [[UILocalNotification alloc] init];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];

    locationQueue = [[NSMutableArray alloc] init];

    bgTask = UIBackgroundTaskInvalid;

    isStarted = NO;
    isUpdatingLocation = NO;
    isAcquiringStationaryLocation = NO;
    isAcquiringSpeed = NO;
    hasConnectivity = YES;
    //    shouldStart = NO;
    stationaryRegion = nil;

    return self;
}

/**
 * configure plugin
 * @param {NSInteger} stationaryRadius
 * @param {NSInteger} distanceFilter
 * @param {NSInteger} desiredAccuracy
 * @param {BOOL} debug
 * @param {NSString*} activityType
 * @param {BOOL} stopOnTerminate
 * @param {NSString*} url
 * @param {NSMutableDictionary*} httpHeaders
 */
- (BOOL) configure:(Config*)config error:(NSError * __autoreleasing *)outError
{
    DDLogVerbose(@"LocationManager configure");
    _config = config;

    DDLogDebug(@"%@", config);

    locationManager.pausesLocationUpdatesAutomatically = YES;
    locationManager.activityType = [_config decodeActivityType];
    locationManager.distanceFilter = _config.distanceFilter; // meters
    locationManager.desiredAccuracy = [_config decodeDesiredAccuracy];

    // ios 8 requires permissions to send local-notifications
    if (_config.isDebugging) {
        UIApplication *app = [UIApplication sharedApplication];
        if ([app respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            [app registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
        }
    }

    if (_config.syncUrl != nil) {
        uploader = [[LocationUploader alloc] init];
    }

    return YES;
}

/**
 * Turn on background geolocation
 * in case of failure it calls error callback from configure method
 * may fire two callback when location services are disabled and when authorization failed
 */
- (BOOL) start:(NSError * __autoreleasing *)outError
{
    DDLogInfo(@"LocationManager will start: %d", isStarted);

    if (isStarted) {
        return NO;
    }

    NSUInteger authStatus;

    if ([CLLocationManager respondsToSelector:@selector(authorizationStatus)]) { // iOS 4.2+
        authStatus = [CLLocationManager authorizationStatus];

        if (authStatus == kCLAuthorizationStatusDenied) {
            NSDictionary *errorDictionary = @{ @"code": [NSNumber numberWithInt:DENIED], @"message" : @LOCATION_DENIED };
            if (outError != NULL) {
                *outError = [NSError errorWithDomain:Domain code:DENIED userInfo:errorDictionary];
            }

            return NO;
        }

        if (authStatus == kCLAuthorizationStatusRestricted) {
            NSDictionary *errorDictionary = @{ @"code": [NSNumber numberWithInt:DENIED], @"message" : @LOCATION_RESTRICTED };
            if (outError != NULL) {
                *outError = [NSError errorWithDomain:Domain code:DENIED userInfo:errorDictionary];
            }

            return NO;
        }

#ifdef __IPHONE_8_0
        // we do startUpdatingLocation even though we might not get permissions granted
        // we can stop later on when recieved callback on user denial
        // it's neccessary to start call startUpdatingLocation in iOS < 8.0 to show user prompt!

        if (authStatus == kCLAuthorizationStatusNotDetermined) {
            if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {  //iOS 8.0+
                DDLogVerbose(@"LocationManager requestAlwaysAuthorization");
                [locationManager requestAlwaysAuthorization];
            }
        }
#endif
    }

    isStarted = YES;
    [self switchMode:FOREGROUND];

    return YES;
}

/**
 * Turn it off
 */
- (BOOL) stop:(NSError * __autoreleasing *)outError
{
    DDLogInfo(@"LocationManager stop");

    if (!isStarted) {
        return YES;
    }

    isStarted = NO;

    [self stopUpdatingLocation];
    [self stopMonitoringSignificantLocationChanges];
    [self stopMonitoringForRegion];

    [reach stopNotifier];

    return YES;
}

/**
 * Called by js to signify the end of a background-geolocation event
 */
- (BOOL) finish
{
    DDLogInfo(@"LocationManager finish");
    [self stopBackgroundTask];
    return YES;
}

/**
 * toggle between foreground and background operation mode
 */
- (void) switchMode:(BGOperationMode)mode
{
    DDLogInfo(@"LocationManager switchMode %lu", (unsigned long)mode);

    operationMode = mode;

    if (!isStarted) return;

    if (_config.isDebugging) {
        AudioServicesPlaySystemSound (operationMode  == FOREGROUND ? paceChangeYesSound : paceChangeNoSound);
    }

    if (operationMode == FOREGROUND || !_config.saveBatteryOnBackground) {
        isAcquiringSpeed = YES;
        isAcquiringStationaryLocation = NO;
        [self stopMonitoringForRegion];
        [self stopMonitoringSignificantLocationChanges];
    } else if (operationMode == BACKGROUND) {
        isAcquiringSpeed = NO;
        isAcquiringStationaryLocation = YES;
        [self startMonitoringSignificantLocationChanges];
    }

    aquireStartTime = [NSDate date];

    // Crank up the GPS power temporarily to get a good fix on our current location
    [self stopUpdatingLocation];
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    [self startUpdatingLocation];
}

- (BOOL) isLocationEnabled
{
    if ([CLLocationManager respondsToSelector:@selector(locationServicesEnabled)]) { // iOS 4.x
        return [CLLocationManager locationServicesEnabled];
    }

    return NO;
}

- (void) showAppSettings
{
    BOOL canGoToSettings = (UIApplicationOpenSettingsURLString != NULL);
    if (canGoToSettings) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

- (void) showLocationSettings
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=LOCATION_SERVICES"]];
}

- (NSMutableDictionary*) getStationaryLocation
{
    if (stationaryRegion != nil) {
        CLLocationDistance radius = [stationaryRegion radius];
        CLLocationCoordinate2D coordinate = [stationaryRegion center];
        double timestamp = [stationarySince timeIntervalSince1970] * 1000;

        NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
        [data setObject:[NSNumber numberWithDouble:coordinate.latitude] forKey:@"latitude"];
        [data setObject:[NSNumber numberWithDouble:coordinate.longitude] forKey:@"longitude"];
        [data setObject:[NSNumber numberWithDouble:radius] forKey:@"radius"];
        [data setObject:[NSNumber numberWithDouble:timestamp] forKey:@"time"];
        return data;
    }
    return nil;
}

- (NSArray<Location*>*) getLocations
{
    SQLiteLocationDAO* locationDAO = [SQLiteLocationDAO sharedInstance];
    NSArray* locations = [locationDAO getAllLocations];
    NSMutableArray* dictionaryLocations = [[NSMutableArray alloc] initWithCapacity:[locations count]];
    for (Location* location in locations) {
        [dictionaryLocations addObject:[location toDictionary]];
    }
    return dictionaryLocations;
}

- (NSArray<NSMutableDictionary*>*) getValidLocations
{
    SQLiteLocationDAO* locationDAO = [SQLiteLocationDAO sharedInstance];
    NSArray* locations = [locationDAO getValidLocations];
    NSMutableArray* dictionaryLocations = [[NSMutableArray alloc] initWithCapacity:[locations count]];
    for (Location* location in locations) {
        [dictionaryLocations addObject:[location toDictionaryWithId]];
    }
    return dictionaryLocations;
}

- (BOOL) deleteLocation:(NSNumber*) locationId
{
    SQLiteLocationDAO* locationDAO = [SQLiteLocationDAO sharedInstance];
    return [locationDAO deleteLocation:locationId];
}

- (BOOL) deleteAllLocations
{
    SQLiteLocationDAO* locationDAO = [SQLiteLocationDAO sharedInstance];
    return [locationDAO deleteAllLocations];
}

- (void) queue:(Location*)location
{
    DDLogDebug(@"LocationManager queue %@", location);

    SQLiteLocationDAO* locationDAO = [SQLiteLocationDAO sharedInstance];
    location.id = [locationDAO persistLocation:location limitRows:_config.maxLocations];

    [locationQueue addObject:location];
    [self flushQueue];
}

- (void) flushQueue
{
    // Sanity-check the duration of last bgTask:  If greater than 30s, kill it.
    if (bgTask != UIBackgroundTaskInvalid) {
        if (-[lastBgTaskAt timeIntervalSinceNow] > 30.0) {
            DDLogWarn(@"LocationManager#flushQueue has to kill an out-standing background-task!");
            if (_config.isDebugging) {
                [self notify:@"Outstanding bg-task was force-killed"];
            }
            [self stopBackgroundTask];
        }
        return;
    }

    if ([locationQueue count] < 1) {
        return;
    }

    // Create a background-task and delegate to Javascript for syncing location
    bgTask = [self createBackgroundTask];
    // retrieve first queued location
    Location *location = [locationQueue firstObject];
    [locationQueue removeObject:location];

    [self sync:location];

    if (![location.type isEqual: @"current"]) {
        return;
    }

    if ([_config hasSyncUrl] || [_config hasUrl]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if (hasConnectivity && [_config hasUrl]) {
                NSError *error = nil;
                if ([location postAsJSON:_config.url withHttpHeaders:_config.httpHeaders error:&error]) {
                    SQLiteLocationDAO* locationDAO = [SQLiteLocationDAO sharedInstance];
                    if (location.id != nil) {
                        [locationDAO deleteLocation:location.id];
                    }
                } else {
                    DDLogWarn(@"LocationManager postJSON failed: error: %@", error.userInfo[@"NSLocalizedDescription"]);
                    hasConnectivity = [reach isReachable];
                    [reach startNotifier];
                }
            }

            NSString *syncUrl = [_config hasSyncUrl] ? _config.syncUrl : _config.url;
            [uploader sync:syncUrl onLocationThreshold:_config.syncThreshold];
        });
    }

}

- (UIBackgroundTaskIdentifier) createBackgroundTask
{
    lastBgTaskAt = [NSDate date];
    return [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self stopBackgroundTask];
    }];
}

- (void) stopBackgroundTask
{
    UIApplication *app = [UIApplication sharedApplication];
    if (bgTask != UIBackgroundTaskInvalid) {
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }
    [self flushQueue];
}

/**
 * We are running in the background if this is being executed.
 * We can't assume normal network access.
 * bgTask is defined as an instance variable of type UIBackgroundTaskIdentifier
 */
- (void) sync:(Location*)location
{
    DDLogInfo(@"LocationManager#sync %@", location);
    if (_config.isDebugging) {
        [self notify:[NSString stringWithFormat:@"Location update: %s\nSPD: %0.0f | DF: %ld | ACY: %0.0f",
            ((operationMode == FOREGROUND) ? "FG" : "BG"),
            [location.speed doubleValue],
            (long) locationManager.distanceFilter,
            [location.accuracy doubleValue]
        ]];

        AudioServicesPlaySystemSound (locationSyncSound);
    }

    // Build a resultset for javascript callback.
    if ([location.type isEqualToString:@"stationary"]) {
        [self fireStationaryRegionListeners:[location toDictionary]];
    } else if ([location.type isEqualToString:@"current"]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onLocationChanged:)]) {
            [self.delegate onLocationChanged:[location toDictionary]];
        }
    } else {
        DDLogError(@"LocationManager#sync could not determine location_type.");
        [self stopBackgroundTask];
    }
}

- (void) fireStationaryRegionListeners:(NSMutableDictionary*)data
{
    DDLogDebug(@"LocationManager#fireStationaryRegionListener");
    // Any javascript stationaryRegion event-listeners?
    if (self.delegate && [self.delegate respondsToSelector:@selector(onStationaryChanged:)]) {
        [data setObject:[NSNumber numberWithDouble:_config.stationaryRadius] forKey:@"radius"];
        [self.delegate onStationaryChanged:data];
    }
//    [self stopBackgroundTask];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    DDLogDebug(@"LocationManager didUpdateLocations (operationMode: %lu)", (unsigned long)operationMode);

    locationError = nil;
    BGOperationMode actAsInMode = operationMode;

    if (actAsInMode == BACKGROUND) {
        if (_config.saveBatteryOnBackground == NO) actAsInMode = FOREGROUND;
    }

    if (actAsInMode == FOREGROUND) {
        if (!isUpdatingLocation) [self startUpdatingLocation];
    }

    if (actAsInMode == BACKGROUND) {
        if (!isAcquiringStationaryLocation && !stationaryRegion) {
            // Perhaps our GPS signal was interupted, re-acquire a stationaryLocation now.
            [self switchMode:operationMode];
        }
    }


    for (CLLocation *location in locations) {
        Location *bgloc = [Location fromCLLocation:location];
        bgloc.type = @"current";

        // test the age of the location measurement to determine if the measurement is cached
        // in most cases you will not want to rely on cached measurements
        DDLogDebug(@"Location age %f", [bgloc locationAge]);
        if ([bgloc locationAge] > maxLocationAgeInSeconds || ![bgloc hasAccuracy] || ![bgloc hasTime]) {
            continue;
        }

        if (lastLocation == nil) {
            lastLocation = bgloc;
            continue;
        }

        if ([bgloc isBetterLocation:lastLocation]) {
            DDLogInfo(@"Better location found: %@", bgloc);
            lastLocation = bgloc;
        }
    }

    if (lastLocation == nil) {
        return;
    }

    // test the measurement to see if it is more accurate than the previous measurement
    if (isAcquiringStationaryLocation) {
        DDLogDebug(@"Acquiring stationary location, accuracy: %@", lastLocation.accuracy);
        if (_config.isDebugging) {
            AudioServicesPlaySystemSound (acquiringLocationSound);
        }

        if ([lastLocation.accuracy doubleValue] <= [[NSNumber numberWithInteger:_config.desiredAccuracy] doubleValue]) {
            DDLogDebug(@"LocationManager found most accurate stationary before timeout");
        } else if (-[aquireStartTime timeIntervalSinceNow] < maxLocationWaitTimeInSeconds) {
            // we still have time to aquire better location
            return;
        }

        isAcquiringStationaryLocation = NO;
        [self stopUpdatingLocation]; //saving power while monitoring region

        Location *stationaryLocation = [lastLocation copy];
        stationaryLocation.type = @"stationary";
        [self startMonitoringStationaryRegion:stationaryLocation];
        // fire onStationary @event for Javascript.
        [self queue:stationaryLocation];
    } else if (isAcquiringSpeed) {
        if (_config.isDebugging) {
            AudioServicesPlaySystemSound (acquiringLocationSound);
        }

        if ([lastLocation.accuracy doubleValue] <= [[NSNumber numberWithInteger:_config.desiredAccuracy] doubleValue]) {
            DDLogDebug(@"LocationManager found most accurate location before timeout");
        } else if (-[aquireStartTime timeIntervalSinceNow] < maxLocationWaitTimeInSeconds) {
            // we still have time to aquire better location
            return;
        }

        if (_config.isDebugging) {
            [self notify:@"Aggressive monitoring engaged"];
        }

        // We should have a good sample for speed now, power down our GPS as configured by user.
        isAcquiringSpeed = NO;
        locationManager.desiredAccuracy = _config.desiredAccuracy;
        locationManager.distanceFilter = [self calculateDistanceFilter:[lastLocation.speed floatValue]];
        [self startUpdatingLocation];

    } else if (actAsInMode == FOREGROUND) {
        // Adjust distanceFilter incrementally based upon current speed
        float newDistanceFilter = [self calculateDistanceFilter:[lastLocation.speed floatValue]];
        if (newDistanceFilter != locationManager.distanceFilter) {
            DDLogInfo(@"LocationManager updated distanceFilter, new: %f, old: %f", newDistanceFilter, locationManager.distanceFilter);
            locationManager.distanceFilter = newDistanceFilter;
            [self startUpdatingLocation];
        }
    } else if ([self locationIsBeyondStationaryRegion:lastLocation]) {
        if (_config.isDebugging) {
            [self notify:@"Manual stationary exit-detection"];
        }
        [self switchMode:operationMode];
    }

    [self queue:lastLocation];
}

/**
 * Called when user exits their stationary radius (ie: they walked ~50m away from their last recorded location.
 *
 */
- (void) locationManager:(CLLocationManager *)manager didExitRegion:(CLCircularRegion *)region
{
    CLLocationDistance radius = [region radius];
    CLLocationCoordinate2D coordinate = [region center];

    DDLogDebug(@"LocationManager didExitRegion {%f,%f,%f}", coordinate.latitude, coordinate.longitude, radius);
    if (_config.isDebugging) {
        AudioServicesPlaySystemSound (exitRegionSound);
        [self notify:@"Exit stationary region"];
    }
    [self switchMode:operationMode];
}

- (void) locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
    DDLogDebug(@"LocationManager location updates paused");
    if (_config.isDebugging) {
        [self notify:@"Location updates paused"];
    }
}

- (void) locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{
    DDLogDebug(@"LocationManager location updates resumed");
    if (_config.isDebugging) {
        [self notify:@"Location updates resumed b"];
    }
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DDLogError(@"LocationManager didFailWithError: %@", error);
    if (_config.isDebugging) {
        AudioServicesPlaySystemSound (locationErrorSound);
        [self notify:[NSString stringWithFormat:@"Location error: %@", error.localizedDescription]];
    }

    locationError = error;

    switch(error.code) {
        case kCLErrorLocationUnknown:
        case kCLErrorNetwork:
        case kCLErrorRegionMonitoringDenied:
        case kCLErrorRegionMonitoringSetupDelayed:
        case kCLErrorRegionMonitoringResponseDelayed:
        case kCLErrorGeocodeFoundNoResult:
        case kCLErrorGeocodeFoundPartialResult:
        case kCLErrorGeocodeCanceled:
            break;
        case kCLErrorDenied:
            break;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(onError:)]) {
        [self.delegate onError:error];
    }
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    DDLogInfo(@"LocationManager didChangeAuthorizationStatus %u", status);
    if (_config.isDebugging) {
        [self notify:[NSString stringWithFormat:@"Authorization status changed %u", status]];
    }

    switch(status) {
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            if (self.delegate && [self.delegate respondsToSelector:@selector(onAuthorizationChanged:)]) {
                [self.delegate onAuthorizationChanged:DENIED];
            }
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            if (self.delegate && [self.delegate respondsToSelector:@selector(onAuthorizationChanged:)]) {
                [self.delegate onAuthorizationChanged:ALLOWED];
            }
            break;
        default:
            break;
    }

}

- (void) stopUpdatingLocation
{
    if (isUpdatingLocation) {
        [locationManager stopUpdatingLocation];
        isUpdatingLocation = NO;
    }
}

- (void) startUpdatingLocation
{
    if (!isUpdatingLocation) {
        [locationManager startUpdatingLocation];
        isUpdatingLocation = YES;
    }
}

- (void) startMonitoringSignificantLocationChanges
{
    [locationManager startMonitoringSignificantLocationChanges];
}

- (void) stopMonitoringSignificantLocationChanges
{
    [locationManager stopMonitoringSignificantLocationChanges];
}

/**
 * Creates a new circle around user and region-monitors it for exit
 */
- (void) startMonitoringStationaryRegion:(Location*)location {
    CLLocationCoordinate2D coord = [location coordinate];
    DDLogDebug(@"LocationManager startMonitoringStationaryRegion {%f,%f,%ld}", coord.latitude, coord.longitude, (long)_config.stationaryRadius);

    if (_config.isDebugging) {
        AudioServicesPlaySystemSound (acquiredLocationSound);
        [self notify:[NSString stringWithFormat:@"Monitoring region {%f,%f,%ld}", location.coordinate.latitude, location.coordinate.longitude, (long)_config.stationaryRadius]];
    }

    [self stopMonitoringForRegion];
    stationaryRegion = [[CLCircularRegion alloc] initWithCenter: coord radius:_config.stationaryRadius identifier:@"LocationManager stationary region"];
    stationaryRegion.notifyOnExit = YES;
    [locationManager startMonitoringForRegion:stationaryRegion];
    stationarySince = [NSDate date];
}

- (void) stopMonitoringForRegion
{
    if (stationaryRegion != nil) {
        [locationManager stopMonitoringForRegion:stationaryRegion];
        stationaryRegion = nil;
        stationarySince = nil;
    }
}

/**
 * Calculates distanceFilter by rounding speed to nearest 5 and multiplying by 10.  Clamped at 1km max.
 */
- (float) calculateDistanceFilter:(float)speed
{
    float newDistanceFilter = _config.distanceFilter;
    if (speed < 100) {
        // (rounded-speed-to-nearest-5) / 2)^2
        // eg 5.2 becomes (5/2)^2
        newDistanceFilter = pow((5.0 * floorf(fabsf(speed) / 5.0 + 0.5f)), 2) + _config.distanceFilter;
    }
    return (newDistanceFilter < 1000) ? newDistanceFilter : 1000;
}

/**
 * Manual stationary location his-testing.  This seems to help stationary-exit detection in some places where the automatic geo-fencing doesn't
 */
- (BOOL) locationIsBeyondStationaryRegion:(Location*)location
{
    CLLocationCoordinate2D regionCenter = [stationaryRegion center];
    BOOL containsCoordinate = [stationaryRegion containsCoordinate:[location coordinate]];

    DDLogVerbose(@"LocationManager location {%@,%@} region {%f,%f,%f} contains: %d",
          location.latitude, location.longitude, regionCenter.latitude, regionCenter.longitude,
          [stationaryRegion radius], containsCoordinate);

    return !containsCoordinate;
}

- (void) notify:(NSString*)message
{
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = message;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

/**@
 * If you don't stopMonitoring when application terminates, the app will be awoken still when a
 * new location arrives, essentially monitoring the user's location even when they've killed the app.
 * Might be desirable in certain apps.
 */
- (void) onAppTerminate
{
    if (_config.stopOnTerminate) {
        DDLogInfo(@"LocationManager is stopping on app terminate.");
        [self stop:nil];
    } else {
        [self switchMode:BACKGROUND];
    }
}

- (void) dealloc
{
    locationManager.delegate = nil;
    //    [super dealloc];
}

@end
