////
//  BackgroundGeolocationDelegate
//  RCTBackgroundGeolocation
//
//  Created by Marian Hello on 04/06/16.
//  According to apache license
//
//  This is class is using code from christocracy cordova-plugin-background-geolocation plugin
//  https://github.com/christocracy/cordova-plugin-background-geolocation
//

@import UIKit;
#import "BackgroundGeolocationDelegate.h"

// Debug sounds for bg-geolocation life-cycle events.
// http://iphonedevwiki.net/index.php/AudioServices
#define exitRegionSound         1005
#define locationSyncSound       1004
#define paceChangeYesSound      1110
#define paceChangeNoSound       1112
#define acquiringLocationSound  1103
#define acquiredLocationSound   1052
#define locationErrorSound      1073

//Edited by kingalione: START
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
//Edited by kingalione: END

@interface BackgroundGeolocationDelegate () <CLLocationManagerDelegate>

@end

@implementation BackgroundGeolocationDelegate {
    BOOL enabled;
    BOOL isUpdatingLocation;

    UIBackgroundTaskIdentifier bgTask;
    NSDate *lastBgTaskAt;

    NSError *locationError;

    BOOL isMoving;

    NSNumber *maxBackgroundHours;
    CLLocationManager *locationManager;
    UILocalNotification *localNotification;

    CLLocation *lastLocation;
    NSMutableArray *locationQueue;

    NSDate *suspendedAt;

    CLLocation *stationaryLocation;
    CLCircularRegion *stationaryRegion;
    NSInteger locationAcquisitionAttempts;

    BOOL isAcquiringStationaryLocation;
    NSInteger maxStationaryLocationAttempts;

    BOOL isAcquiringSpeed;
    NSInteger maxSpeedAcquistionAttempts;

    NSInteger stationaryRadius;
    NSInteger distanceFilter;
    NSInteger locationTimeout;
    NSInteger desiredAccuracy;
    BOOL isDebugging;
    NSString* activityType;
    BOOL stopOnTerminate;
}

@synthesize stationaryRegionListeners;

- (id)init
{
    self = [super init];
    
    if (self == nil) {
        return self;
    }

    // background location cache, for when no network is detected.
    locationManager = [[CLLocationManager alloc] init];

    //Edited by kingalione: START
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        NSLog(@"BackgroundGeolocationDelegate iOS9 detected");
        locationManager.allowsBackgroundLocationUpdates = YES;
    }
    //Edited by kingalione: END

    locationManager.delegate = self;

    localNotification = [[UILocalNotification alloc] init];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];

    locationQueue = [[NSMutableArray alloc] init];

    isMoving = NO;
    isUpdatingLocation = NO;
    stationaryLocation = nil;
    stationaryRegion = nil;

    stationaryRadius = 50;
    distanceFilter = 500;
    locationTimeout = 60;
    desiredAccuracy = 100;
    isDebugging = NO;
    activityType = @"OTHER";
    stopOnTerminate = NO;

    maxStationaryLocationAttempts   = 4;
    maxSpeedAcquistionAttempts      = 3;

    bgTask = UIBackgroundTaskInvalid;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSuspend:) name:UIApplicationDidEnterBackgroundNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onResume:) name:UIApplicationWillEnterForegroundNotification object:nil];

    return self;
}

- (BOOL) isAuthorized
{
    BOOL authorizationStatusClassPropertyAvailable = [CLLocationManager respondsToSelector:@selector(authorizationStatus)]; // iOS 4.2+
    
    if (authorizationStatusClassPropertyAvailable) {
        NSUInteger authStatus = [CLLocationManager authorizationStatus];
#ifdef __IPHONE_8_0
        NSLog(@"BackgroundGeolocationDelegate requestAlwaysAuthorization");
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {  //iOS 8.0+
            return (authStatus == kCLAuthorizationStatusAuthorizedWhenInUse) || (authStatus == kCLAuthorizationStatusAuthorizedAlways) || (authStatus == kCLAuthorizationStatusNotDetermined);
        }
#endif
        return (authStatus == kCLAuthorizationStatusAuthorized) || (authStatus == kCLAuthorizationStatusNotDetermined);
    }
    
    // by default, assume YES (for iOS < 4.2)
    return YES;
}

/**
 * configure plugin
 * @param {Number} stationaryRadius
 * @param {Number} distanceFilter
 * @param {Number} locationTimeout
 */
- (void) configure:(NSDictionary*)config
{
    NSLog(@"BackgroundGeolocationDelegate configure");

    if (config[@"stationaryRadius"]) {
        stationaryRadius = [config[@"stationaryRadius"] intValue];
    }
    if (config[@"distanceFilter"]) {
        distanceFilter = [config[@"distanceFilter"] intValue];
    }
    if (config[@"locationTimeout"]) {
        locationTimeout = [config[@"locationTimeout"] intValue];
    }
    if (config[@"desiredAccuracy"]) {
        desiredAccuracy = [self decodeDesiredAccuracy:[config[@"desiredAccuracy"] floatValue]];
    }
    if (config[@"debug"]) {
        isDebugging = [config[@"debug"] boolValue];
    }
    if (config[@"activityType"]) {
        activityType = config[@"activityType"];
    }
    if (config[@"stopOnTerminate"]) {
        stopOnTerminate = [config[@"stopOnTerminate"] boolValue];
    }

    locationManager.activityType = [self decodeActivityType:activityType];
    locationManager.pausesLocationUpdatesAutomatically = YES;
    locationManager.distanceFilter = distanceFilter; // meters
    locationManager.desiredAccuracy = desiredAccuracy;

    NSLog(@"distanceFilter: %ld, stationaryRadius: %ld, locationTimeout: %ld, desiredAccuracy: %ld, activityType: %@, debug: %d, stopOnTerminate: %d", (long)distanceFilter, (long)stationaryRadius, (long)locationTimeout, (long)desiredAccuracy, activityType, isDebugging, stopOnTerminate);

    // ios 8 requires permissions to send local-notifications
    if (isDebugging) {
        UIApplication *app = [UIApplication sharedApplication];
        if ([app respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            [app registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
        }
    }
}

// - (void) addStationaryRegionListener:(CDVInvokedUrlCommand*)command
// {
//     if (self.stationaryRegionListeners == nil) {
//         self.stationaryRegionListeners = [[NSMutableArray alloc] init];
//     }
//     [self.stationaryRegionListeners addObject:command.callbackId];
//     if (stationaryRegion) {
//         [self queue:stationaryLocation type:@"stationary"];
//     }
// }

- (void) flushQueue
{
    // Sanity-check the duration of last bgTask:  If greater than 30s, kill it.
    if (bgTask != UIBackgroundTaskInvalid) {
        if (-[lastBgTaskAt timeIntervalSinceNow] > 30.0) {
            NSLog(@"BackgroundGeolocationDelegate#flushQueue has to kill an out-standing background-task!");
            if (isDebugging) {
                [self notify:@"Outstanding bg-task was force-killed"];
            }
            [self stopBackgroundTask];
        }
        return;
    }
    if ([locationQueue count] > 0) {
        NSMutableDictionary *data = [locationQueue lastObject];
        [locationQueue removeObject:data];

        // Create a background-task and delegate to Javascript for syncing location
        bgTask = [self createBackgroundTask];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sync:data];
        });
    }
}

//- (void) setConfig:(NSDictionary*)config
//{
//    NSLog(@"BackgroundGeolocationDelegate setConfig");
//
//    if (config[@"desiredAccuracy"]) {
//        desiredAccuracy = [self decodeDesiredAccuracy:[config[@"desiredAccuracy"] floatValue]];
//        NSLog(@"desiredAccuracy: %@", config[@"desiredAccuracy"]);
//    }
//    if (config[@"stationaryRadius"]) {
//        stationaryRadius = [config[@"stationaryRadius"] intValue];
//        NSLog(@"stationaryRadius: %@", config[@"stationaryRadius"]);
//    }
//    if (config[@"distanceFilter"]) {
//        distanceFilter = [config[@"distanceFilter"] intValue];
//        NSLog(@"distanceFilter: %@", config[@"distanceFilter"]);
//    }
//    if (config[@"locationTimeout"]) {
//        locationTimeout = [config[@"locationTimeout"] intValue];
//        NSLog(@"locationTimeout: %@", config[@"locationTimeout"]);
//    }
//}

-(NSInteger)decodeDesiredAccuracy:(NSInteger)accuracy
{
    switch (accuracy) {
        case 1000:
            accuracy = kCLLocationAccuracyKilometer;
            break;
        case 100:
            accuracy = kCLLocationAccuracyHundredMeters;
            break;
        case 10:
            accuracy = kCLLocationAccuracyNearestTenMeters;
            break;
        case 0:
            accuracy = kCLLocationAccuracyBest;
            break;
        default:
            accuracy = kCLLocationAccuracyHundredMeters;
    }
    return accuracy;
}

-(CLActivityType)decodeActivityType:(NSString*)name
{
    if ([name caseInsensitiveCompare:@"AutomotiveNavigation"]) {
        return CLActivityTypeAutomotiveNavigation;
    } else if ([name caseInsensitiveCompare:@"OtherNavigation"]) {
        return CLActivityTypeOtherNavigation;
    } else if ([name caseInsensitiveCompare:@"Fitness"]) {
        return CLActivityTypeFitness;
    } else {
        return CLActivityTypeOther;
    }
}

/**
 * Turn on background geolocation
 * in case of failure it calls error callback from configure method
 * may fire two callback when location services are disabled and when authorization failed
 */
- (void) start
{
    NSString* message = nil;
    NSLog(@"BackgroundGeolocationDelegate starting attempt");

    if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [locationManager requestAlwaysAuthorization];
    }

    if ([self isLocationEnabled] == NO) {
        message = @"Location services are disabled.";
        NSMutableDictionary* posError = [NSMutableDictionary dictionaryWithCapacity:2];
        [posError setObject:[NSNumber numberWithInt:PERMISSIONDENIED] forKey:@"code"];
        [posError setObject:message forKey:@"message"];
        // TODO: return result
        // CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:posError];
        // [result setKeepCallbackAsBool:YES];
        // for compatibility reasons with call configure error callback instead of start callback
        // [self.commandDelegate sendPluginResult:result callbackId:self.syncCallbackId];
    }

    if (![self isAuthorized]) {
        BOOL authStatusAvailable = [CLLocationManager respondsToSelector:@selector(authorizationStatus)]; // iOS 4.2+
        if (authStatusAvailable) {
            NSUInteger code = [CLLocationManager authorizationStatus];
            if (code == kCLAuthorizationStatusNotDetermined) {
                // could return POSITION_UNAVAILABLE but need to coordinate with other platforms
                message = @"User undecided on application's use of location services.";
                NSLog(@"- BackgroundGeolocationDelegate start failed: %@)", message);
                NSMutableDictionary* posError = [NSMutableDictionary dictionaryWithCapacity:2];
                [posError setObject:[NSNumber numberWithInt:PERMISSIONDENIED] forKey:@"code"];
                [posError setObject:message forKey:@"message"];
                // TODO: return result
                // CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:posError];
                // [result setKeepCallbackAsBool:YES];
                // // for compatibility reasons with call configure error callback instead of start callback
                // [self.commandDelegate sendPluginResult:result callbackId:self.syncCallbackId];
                // go ahead start service
            } else if (code == kCLAuthorizationStatusRestricted) {
                message = @"Application's use of location services is restricted.";
                NSLog(@"- BackgroundGeolocationDelegate start failed: %@)", message);
                NSMutableDictionary* posError = [NSMutableDictionary dictionaryWithCapacity:2];
                [posError setObject:[NSNumber numberWithInt:PERMISSIONDENIED] forKey:@"code"];
                [posError setObject:message forKey:@"message"];
                // TODO: return result
                // CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:posError];
                // [result setKeepCallbackAsBool:YES];
                // // for compatibility reasons with call configure error callback instead of start callback
                // [self.commandDelegate sendPluginResult:result callbackId:self.syncCallbackId];
                return;
            } else if (code == kCLAuthorizationStatusDenied) {
                message = @"User denied use of location services.";
                NSLog(@"- BackgroundGeolocationDelegate start failed: %@)", message);
                NSMutableDictionary* posError = [NSMutableDictionary dictionaryWithCapacity:2];
                [posError setObject:[NSNumber numberWithInt:PERMISSIONDENIED] forKey:@"code"];
                [posError setObject:message forKey:@"message"];
                // TODO: return result
                // CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:posError];
                // [result setKeepCallbackAsBool:YES];
                // // for compatibility reasons with call configure error callback instead of start callback
                // [self.commandDelegate sendPluginResult:result callbackId:self.syncCallbackId];
                return;
            } else {
                NSLog(@"BackgroundGeolocationDelegate start code %lu", (unsigned long)code);                
            }
        }
    }

    enabled = YES;
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    
    NSLog(@"BackgroundGeolocationDelegate start (background? %ld)", (long)state);
    
    [locationManager startMonitoringSignificantLocationChanges];
    [self setPace:isMoving];
    // TODO: return result
    // CDVPluginResult* result = nil;
    // result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    // [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

/**
 * Turn it off
 */
- (void) stop
{
    NSLog(@"BackgroundGeolocationDelegate stop");
    enabled = NO;
    isMoving = NO;

    [self stopUpdatingLocation];
    [locationManager stopMonitoringSignificantLocationChanges];
    if (stationaryRegion != nil) {
        [locationManager stopMonitoringForRegion:stationaryRegion];
        stationaryRegion = nil;
    }
    // TODO: return result
    // CDVPluginResult* result = nil;
    // result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    // [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

/**
 * Change pace to moving/stopped
 * @param {Boolean} isMoving
 */
- (void) onPaceChange:(BOOL)moving
{
    NSLog(@"BackgroundGeolocationDelegate onPaceChange %d", moving);
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state == UIApplicationStateBackground) {
        [self setPace:moving];
    }
}

/**
 * toggle passive or aggressive location services
 */
- (void)setPace:(BOOL)value
{
    NSLog(@"BackgroundGeolocationDelegate setPace %d, stationaryRegion? %d", value, stationaryRegion!=nil);
    isMoving                        = value;
    isAcquiringStationaryLocation   = NO;
    isAcquiringSpeed                = NO;
    locationAcquisitionAttempts     = 0;
    stationaryLocation              = nil;

    if (isDebugging) {
        AudioServicesPlaySystemSound (isMoving ? paceChangeYesSound : paceChangeNoSound);
    }
    if (isMoving) {
        if (stationaryRegion) {
            [locationManager stopMonitoringForRegion:stationaryRegion];
            stationaryRegion = nil;
        }
        isAcquiringSpeed = YES;
    } else {
        isAcquiringStationaryLocation   = YES;
    }
    if (isAcquiringSpeed || isAcquiringStationaryLocation) {
        // Crank up the GPS power temporarily to get a good fix on our current location
        [self stopUpdatingLocation];
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        [self startUpdatingLocation];
    }
}

/**
 * Fetches current stationaryLocation
 */
// - (void) getStationaryLocation:(CDVInvokedUrlCommand *)command
// {
//     NSLog(@"- BackgroundGeolocationDelegate getStationaryLocation");
// 
//     // Build a resultset for javascript callback.
//     CDVPluginResult* result = nil;
// 
//     if (stationaryLocation) {
//         NSMutableDictionary *returnInfo = [self locationToHash:stationaryLocation];
// 
//         result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnInfo];
//     } else {
//         result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:NO];
//     }
//     [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
// }

- (BOOL) isLocationEnabled
{
    BOOL locationServicesEnabledInstancePropertyAvailable = [locationManager respondsToSelector:@selector(locationServicesEnabled)]; // iOS 3.x
    BOOL locationServicesEnabledClassPropertyAvailable = [CLLocationManager respondsToSelector:@selector(locationServicesEnabled)]; // iOS 4.x
    
    if (locationServicesEnabledClassPropertyAvailable) { // iOS 4.x
        return [CLLocationManager locationServicesEnabled];
    } else if (locationServicesEnabledInstancePropertyAvailable) { // iOS 2.x, iOS 3.x
        return [(id)locationManager locationServicesEnabled];
    } else {
        return NO;
    }
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

- (void) watchLocationMode
{
    // TODO: yet to be implemented
}

- (void) stopWatchingLocationMode
{
     // TODO: yet to be implemented
}

//- (void) getLocations:(CDVInvokedUrlCommand*)command
//{
//    // TODO: yet to be implemented
//}
//
//- (void) deleteLocation:(CDVInvokedUrlCommand*)command
//{
//    // TODO: yet to be implemented
//}
//
//- (void) deleteAllLocations:(CDVInvokedUrlCommand*)command
//{
//    // TODO: yet to be implemented    
//}


-(NSMutableDictionary*) locationToHash:(CLLocation*)location
{
    NSMutableDictionary *returnInfo;
    returnInfo = [NSMutableDictionary dictionaryWithCapacity:10];

    NSNumber* timestamp = [NSNumber numberWithDouble:([location.timestamp timeIntervalSince1970] * 1000)];
    [returnInfo setObject:timestamp forKey:@"timestamp"];
    [returnInfo setObject:[NSNumber numberWithDouble:location.speed] forKey:@"speed"];
    [returnInfo setObject:[NSNumber numberWithDouble:location.verticalAccuracy] forKey:@"altitudeAccuracy"];
    [returnInfo setObject:[NSNumber numberWithDouble:location.horizontalAccuracy] forKey:@"accuracy"];
    [returnInfo setObject:[NSNumber numberWithDouble:location.course] forKey:@"heading"];
    [returnInfo setObject:[NSNumber numberWithDouble:location.altitude] forKey:@"altitude"];
    [returnInfo setObject:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"latitude"];
    [returnInfo setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"longitude"];

    return returnInfo;
}
/**
 * Called by js to signify the end of a background-geolocation event
 */
-(void) finish
{
    NSLog(@"BackgroundGeolocationDelegate finish");
    [self stopBackgroundTask];
}

/**
 * Suspend.  Turn on passive location services
 */
-(void) onSuspend:(NSNotification *) notification
{
    NSLog(@"BackgroundGeolocationDelegate suspend (enabled? %d)", enabled);
    suspendedAt = [NSDate date];

    if (enabled) {
        // Sample incoming stationary-location candidate:  Is it within the current stationary-region?  If not, I guess we're moving.
        if (!isMoving && stationaryRegion) {
            if ([self locationAge:stationaryLocation] < (5 * 60.0)) {
                if (isDebugging) {
                    AudioServicesPlaySystemSound (acquiredLocationSound);
                    [self notify:[NSString stringWithFormat:@"Continue stationary\n%f,%f", [stationaryLocation coordinate].latitude, [stationaryLocation coordinate].longitude]];
                }
                [self queue:stationaryLocation type:@"stationary"];
                return;
            }
        }
        [self setPace: isMoving];
    }
}
/**@
 * Resume.  Turn background off
 */
-(void) onResume:(NSNotification *) notification
{
    NSLog(@"BackgroundGeolocationDelegate resume");
    if (enabled) {
        [self stopUpdatingLocation];
    }
}



/**@
 * Termination. Checks to see if it should turn off
 */
-(void) onAppTerminate
{
    NSLog(@"BackgroundGeolocationDelegate appTerminate");
    if (enabled && stopOnTerminate) {
        NSLog(@"BackgroundGeolocationDelegate stoping on terminate");

        enabled = NO;
        isMoving = NO;

        [self stopUpdatingLocation];
        [locationManager stopMonitoringSignificantLocationChanges];
        if (stationaryRegion != nil) {
            [locationManager stopMonitoringForRegion:stationaryRegion];
            stationaryRegion = nil;
        }
    }
}


-(void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"BackgroundGeolocationDelegate didUpdateLocations (isMoving: %d)", isMoving);

    locationError = nil;
    if (isMoving && !isUpdatingLocation) {
        [self startUpdatingLocation];
    }

    CLLocation *location = [locations lastObject];

    if (!isMoving && !isAcquiringStationaryLocation && !stationaryLocation) {
        // Perhaps our GPS signal was interupted, re-acquire a stationaryLocation now.
        [self setPace: NO];
    }

    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    if ([self locationAge:location] > 5.0) return;

    // test that the horizontal accuracy does not indicate an invalid measurement
    if (location.horizontalAccuracy < 0) return;

    lastLocation = location;

    // test the measurement to see if it is more accurate than the previous measurement
    if (isAcquiringStationaryLocation) {
        NSLog(@"Acquiring stationary location, accuracy: %f", location.horizontalAccuracy);
        if (isDebugging) {
            AudioServicesPlaySystemSound (acquiringLocationSound);
        }
        if (stationaryLocation == nil || stationaryLocation.horizontalAccuracy > location.horizontalAccuracy) {
            stationaryLocation = location;
        }
        if (++locationAcquisitionAttempts == maxStationaryLocationAttempts) {
            isAcquiringStationaryLocation = NO;
            [self startMonitoringStationaryRegion:stationaryLocation];
        } else {
            // Unacceptable stationary-location: bail-out and wait for another.
            return;
        }
    } else if (isAcquiringSpeed) {
        if (isDebugging) {
            AudioServicesPlaySystemSound (acquiringLocationSound);
        }
        if (++locationAcquisitionAttempts == maxSpeedAcquistionAttempts) {
            if (isDebugging) {
                [self notify:@"Aggressive monitoring engaged"];
            }
            // We should have a good sample for speed now, power down our GPS as configured by user.
            isAcquiringSpeed = NO;
            [locationManager setDesiredAccuracy:desiredAccuracy];
            [locationManager setDistanceFilter:[self calculateDistanceFilter:location.speed]];
            [self startUpdatingLocation];
        } else {
            return;
        }
    } else if (isMoving) {
        // Adjust distanceFilter incrementally based upon current speed
        float newDistanceFilter = [self calculateDistanceFilter:location.speed];
        if (newDistanceFilter != locationManager.distanceFilter) {
            NSLog(@"BackgroundGeolocationDelegate updated distanceFilter, new: %f, old: %f", newDistanceFilter, locationManager.distanceFilter);
            [locationManager setDistanceFilter:newDistanceFilter];
            [self startUpdatingLocation];
        }
    } else if ([self locationIsBeyondStationaryRegion:location]) {
        if (isDebugging) {
            [self notify:@"Manual stationary exit-detection"];
        }
        [self setPace:YES];
    }
    [self queue:location type:@"current"];
}
/**
* Manual stationary location his-testing.  This seems to help stationary-exit detection in some places where the automatic geo-fencing soesn't
*/
-(bool)locationIsBeyondStationaryRegion:(CLLocation*)location
{
    NSLog(@"BackgroundGeolocationDelegate locationIsBeyondStationaryRegion");
    if (![stationaryRegion containsCoordinate:[location coordinate]]) {
        double pointDistance = [stationaryLocation distanceFromLocation:location];
        return (pointDistance - stationaryLocation.horizontalAccuracy - location.horizontalAccuracy) > stationaryRadius;
    } else {
        return NO;
    }
}
/**
 * Calculates distanceFilter by rounding speed to nearest 5 and multiplying by 10.  Clamped at 1km max.
 */
-(float) calculateDistanceFilter:(float)speed
{
    float newDistanceFilter = distanceFilter;
    if (speed < 100) {
        // (rounded-speed-to-nearest-5) / 2)^2
        // eg 5.2 becomes (5/2)^2
        newDistanceFilter = pow((5.0 * floorf(fabsf(speed) / 5.0 + 0.5f)), 2) + distanceFilter;
    }
    return (newDistanceFilter < 1000) ? newDistanceFilter : 1000;
}

-(void) queue:(CLLocation*)location type:(id)type
{
    NSLog(@"BackgroundGeolocationDelegate queue %@", type);
    NSMutableDictionary *data = [self locationToHash:location];
    [data setObject:type forKey:@"location_type"];
    [locationQueue addObject:data];
    [self flushQueue];
}

-(UIBackgroundTaskIdentifier) createBackgroundTask
{
    lastBgTaskAt = [NSDate date];
    return [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self stopBackgroundTask];
    }];
}

/**
 * We are running in the background if this is being executed.
 * We can't assume normal network access.
 * bgTask is defined as an instance variable of type UIBackgroundTaskIdentifier
 */
-(void) sync:(NSMutableDictionary*)data
{
    NSLog(@"BackgroundGeolocationDelegate#sync");
    NSLog(@"type: %@, position: %@,%@ speed: %@", [data objectForKey:@"location_type"], [data objectForKey:@"latitude"], [data objectForKey:@"longitude"], [data objectForKey:@"speed"]);
    if (isDebugging) {
        [self notify:[NSString stringWithFormat:@"Location update: %s\nSPD: %0.0f | DF: %ld | ACY: %0.0f",
                      ((isMoving) ? "MOVING" : "STATIONARY"),
                      [[data objectForKey:@"speed"] doubleValue],
                      (long) locationManager.distanceFilter,
                      [[data objectForKey:@"accuracy"] doubleValue]]];

        AudioServicesPlaySystemSound (locationSyncSound);
    }

    // Build a resultset for javascript callback.
    NSString *locationType = [data objectForKey:@"location_type"];
    if ([locationType isEqualToString:@"stationary"]) {
        [self fireStationaryRegionListeners:data];
    } else if ([locationType isEqualToString:@"current"]) {

        self.onLocationChanged(data);
//        CDVPluginResult* result = nil;
//        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
//        [result setKeepCallbackAsBool:YES];
//        [self.commandDelegate sendPluginResult:result callbackId:self.syncCallbackId];
    } else {
        NSLog(@"BackgroundGeolocationDelegate#sync could not determine location_type.");
        [self stopBackgroundTask];
    }
}

- (void) fireStationaryRegionListeners:(NSMutableDictionary*)data
{
    NSLog(@"BackgroundGeolocationDelegate#fireStationaryRegionListener");
    if (![self.stationaryRegionListeners count]) {
        [self stopBackgroundTask];
        return;
    }
    // Any javascript stationaryRegion event-listeners?
    [data setObject:[NSNumber numberWithDouble:stationaryRadius] forKey:@"radius"];

//    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
//    [result setKeepCallbackAsBool:YES];
//    for (NSString *callbackId in self.stationaryRegionListeners)
//    {
//        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
//    }
}

/**
 * Creates a new circle around user and region-monitors it for exit
 */
- (void) startMonitoringStationaryRegion:(CLLocation*)location {
    stationaryLocation = location;

    // fire onStationary @event for Javascript.
    [self queue:location type:@"stationary"];

    CLLocationCoordinate2D coord = [location coordinate];
    NSLog(@"- BackgroundGeolocationDelegate createStationaryRegion (%f,%f)", coord.latitude, coord.longitude);

    if (isDebugging) {
        AudioServicesPlaySystemSound (acquiredLocationSound);
        [self notify:[NSString stringWithFormat:@"Acquired stationary location\n%f, %f", location.coordinate.latitude,location.coordinate.longitude]];
    }
    if (stationaryRegion != nil) {
        [locationManager stopMonitoringForRegion:stationaryRegion];
    }
    isAcquiringStationaryLocation = NO;
    stationaryRegion = [[CLCircularRegion alloc] initWithCenter: coord radius:stationaryRadius identifier:@"BackgroundGeolocationDelegate stationary region"];
    stationaryRegion.notifyOnExit = YES;
    [locationManager startMonitoringForRegion:stationaryRegion];

    [self stopUpdatingLocation];
    locationManager.distanceFilter = distanceFilter;
    locationManager.desiredAccuracy = desiredAccuracy;
}

- (bool) stationaryRegionContainsLocation:(CLLocation*)location {
    CLCircularRegion *region = [locationManager.monitoredRegions member:stationaryRegion];
    return ([region containsCoordinate:location.coordinate]) ? YES : NO;
}

- (void) stopBackgroundTask
{
    UIApplication *app = [UIApplication sharedApplication];
    NSLog(@"BackgroundGeolocationDelegate stopBackgroundTask (remaining t: %f)", app.backgroundTimeRemaining);
    if (bgTask != UIBackgroundTaskInvalid)
    {
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }
    [self flushQueue];
}

/**
 * Called when user exits their stationary radius (ie: they walked ~50m away from their last recorded location.
 * - turn on more aggressive location monitoring.
 */
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"BackgroundGeolocationDelegate exit region");
    if (isDebugging) {
        AudioServicesPlaySystemSound (exitRegionSound);
        [self notify:@"Exit stationary region"];
    }
    [self setPace:YES];
}

/**
 * 1. turn off std location services
 * 2. turn on significantChanges API
 * 3. create a region and start monitoring exits.
 */
- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
    NSLog(@"BackgroundGeolocationDelegate paused location updates");
    if (isDebugging) {
        [self notify:@"Stop detected"];
    }
    if (locationError) {
        isMoving = NO;
        [self startMonitoringStationaryRegion:lastLocation];
        [self stopUpdatingLocation];
    } else {
        [self setPace:NO];
    }
}

/**
 * 1. Turn off significantChanges ApI
 * 2. turn on std. location services
 * 3. nullify stationaryRegion
 */
- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{
    NSLog(@"BackgroundGeolocationDelegate resume location updates");
    if (isDebugging) {
        [self notify:@"Resume location updates"];
    }
    [self setPace:YES];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"BackgroundGeolocationDelegate locationManager failed:  %@", error);
    if (isDebugging) {
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
            [self stopUpdatingLocation];
            break;
        default:
            [self stopUpdatingLocation];
    }
}

- (void) stopUpdatingLocation
{
    [locationManager stopUpdatingLocation];
    isUpdatingLocation = NO;
}

- (void) startUpdatingLocation
{
    [locationManager startUpdatingLocation];
    isUpdatingLocation = YES;
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"BackgroundGeolocationDelegate didChangeAuthorizationStatus %u", status);
    if (isDebugging) {
        [self notify:[NSString stringWithFormat:@"Authorization status changed %u", status]];
    }
}

- (NSTimeInterval) locationAge:(CLLocation*)location
{
    return -[location.timestamp timeIntervalSinceNow];
}

- (void) notify:(NSString*)message
{
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = message;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}
/**
 * If you don't stopMonitoring when application terminates, the app will be awoken still when a
 * new location arrives, essentially monitoring the user's location even when they've killed the app.
 * Might be desirable in certain apps.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
    [locationManager stopMonitoringSignificantLocationChanges];
    [locationManager stopUpdatingLocation];
    if (stationaryRegion != nil) {
        [locationManager stopMonitoringForRegion:stationaryRegion];
    }
}

- (void)dealloc
{
    locationManager.delegate = nil;
//    [super dealloc];
}

@end
