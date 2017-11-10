////
//  BackgroundGeolocationFacade.m
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
#import <CoreLocation/CoreLocation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "BackgroundGeolocationFacade.h"
#import "BackgroundSync.h"
#import "SQLiteLocationDAO.h"
#import "BackgroundTaskManager.h"
#import "Reachability.h"
#import "Logging.h"
#import "ActivityLocationProvider.h"
#import "DistanceFilterLocationProvider.h"
#import "RawLocationProvider.h"

// error messages
#define UNKNOWN_LOCATION_PROVIDER_MSG   "Unknown location provider."

static NSString * const Domain = @"com.marianhello";
static NSString * const TAG = @"BgGeo";

@interface BackgroundGeolocationFacade () <LocationDelegate>
@end

@implementation BackgroundGeolocationFacade {
    BOOL isStarted;
    BOOL hasConnectivity;

    BGOperationMode operationMode;

    UILocalNotification *localNotification;

    NSNumber *maxBackgroundHours;

    // configurable options
    Config *_config;

    Location *stationaryLocation;
    AbstractLocationProvider<LocationProvider> *locationProvider;
    BackgroundSync *uploader;
    Reachability *reach;
}


- (instancetype) init
{
    self = [super init];

    if (self == nil) {
        return self;
    }

    _config = [[Config alloc] init];

    reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    reach.reachableBlock = ^(Reachability *_reach){
        // keep in mind this is called on a background thread
        // and if you are updating the UI it needs to happen
        // on the main thread:
        DDLogInfo(@"Network is now reachable");
        hasConnectivity = YES;
        [_reach stopNotifier];
    };

    reach.unreachableBlock = ^(Reachability *reach) {
        DDLogInfo(@"Network is now unreachable");
        hasConnectivity = NO;
    };

    localNotification = [[UILocalNotification alloc] init];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];

    isStarted = NO;
    hasConnectivity = YES;

    return self;
}

/**
 * configure manager
 * @param {Config} configuration
 * @param {NSError} optional error
 */
- (BOOL) configure:(Config*)config error:(NSError * __autoreleasing *)outError
{
    DDLogInfo(@"%@ #configure: %@", TAG, config);
    _config = config;

    // ios 8 requires permissions to send local-notifications
    if (_config.isDebugging) {
        UIApplication *app = [UIApplication sharedApplication];
        if ([app respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            [app registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
        }
    }
   
    if ([config hasSyncUrl] && uploader == nil) {
        uploader = [[BackgroundSync alloc] init];
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
    DDLogInfo(@"%@ #start: %d", TAG, isStarted);

    if (isStarted) {
        return NO;
    }
    
    // Note: CLLocationManager must be created on a thread with an active run loop (main thread)
    __block NSError *error = nil;
    __block NSDictionary *errorDictionary;
    
    [self runOnMainThread:^{
        switch (_config.locationProvider) {
            // TODO: implement ACTIVITY_PROVIDER
            case ACTIVITY_PROVIDER:
            case DISTANCE_FILTER_PROVIDER:
                locationProvider = [[DistanceFilterLocationProvider alloc] init];
                break;
//            case ACTIVITY_PROVIDER:
//                locationProvider = [[ActivityLocationProvider alloc] init];
//                break;
            case RAW_PROVIDER:
                locationProvider = [[RawLocationProvider alloc] init];
                break;
            default:
                errorDictionary = @{ @"code": [NSNumber numberWithInt:UNKNOWN_LOCATION_PROVIDER], @"message": @UNKNOWN_LOCATION_PROVIDER_MSG };
                error = [NSError errorWithDomain:Domain code:UNKNOWN_LOCATION_PROVIDER userInfo:errorDictionary];
                return;
        }
       
        // trap configuration errors
        if (![locationProvider configure:_config error:&error]) {
            if (outError != nil) *outError = error;
            return;
        }
        
        isStarted = [locationProvider start:&error];
        locationProvider.delegate = self;
    }];

    if (locationProvider == nil) {
        if (outError != nil) *outError = error;
        return NO;
    }
    
    if (!isStarted) {
        if (outError != nil) *outError = error;
        return NO;
    }
  
    return isStarted;
}

/**
 * Turn off background geolocation
 */
- (BOOL) stop:(NSError * __autoreleasing *)outError
{
    DDLogInfo(@"%@ #stop", TAG);

    if (!isStarted) {
        return YES;
    }

    [reach stopNotifier];
    
    [self runOnMainThread:^{
        isStarted = ![locationProvider stop:outError];
    }];

    return isStarted;
}

/**
 * toggle between foreground and background operation mode
 */
- (void) switchMode:(BGOperationMode)mode
{
    DDLogInfo(@"%@ #switchMode %lu", TAG, (unsigned long)mode);

    operationMode = mode;

    if (!isStarted) return;

    if (_config.isDebugging) {
        AudioServicesPlaySystemSound (operationMode  == FOREGROUND ? paceChangeYesSound : paceChangeNoSound);
    }
   
    [self runOnMainThread:^{
        [locationProvider switchMode:mode];
    }];
}

- (BOOL) isLocationEnabled
{
    if ([CLLocationManager respondsToSelector:@selector(locationServicesEnabled)]) { // iOS 4.x
        return [CLLocationManager locationServicesEnabled];
    }

    return NO;
}

- (BOOL) isStarted
{
    return isStarted;
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

- (Location*) getStationaryLocation
{
    return stationaryLocation;
}

- (NSArray<Location*>*) getLocations
{
    SQLiteLocationDAO* locationDAO = [SQLiteLocationDAO sharedInstance];
    return [locationDAO getAllLocations];
}

- (NSArray<Location*>*) getValidLocations
{
    SQLiteLocationDAO* locationDAO = [SQLiteLocationDAO sharedInstance];
    return [locationDAO getValidLocations];
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

- (Config*) getConfig
{
    return _config;
}

- (void) sync:(Location *)location
{
    if (hasConnectivity && [_config hasUrl]) {
        NSError *error = nil;
        if ([location postAsJSON:_config.url withHttpHeaders:_config.httpHeaders error:&error]) {
            SQLiteLocationDAO* locationDAO = [SQLiteLocationDAO sharedInstance];
            if (location.id != nil) {
                [locationDAO deleteLocation:location.id];
            }
        } else {
            DDLogWarn(@"%@ postJSON failed: error: %@", TAG, error.userInfo[@"NSLocalizedDescription"]);
            hasConnectivity = [reach isReachable];
            [reach startNotifier];
        }
    }
    
    if ([_config hasSyncUrl]) {
        [uploader sync:_config.syncUrl onLocationThreshold:_config.syncThreshold];
    }
}

- (void) notify:(NSString*)message
{
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = message;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

-(void) runOnMainThread:(dispatch_block_t)completionHandle {
    BOOL alreadyOnMainThread = [NSThread isMainThread];
    // this check avoids possible deadlock resulting from
    // calling dispatch_sync() on the same queue as current one
    if (alreadyOnMainThread) {
        // execute code in place
        completionHandle();
    } else {
        // dispatch to main queue
        dispatch_sync(dispatch_get_main_queue(), completionHandle);
    }
}

- (void) onStationaryChanged:(Location *)location
{
    DDLogDebug(@"%@ #onStationaryChanged", TAG);
    stationaryLocation = location;

    // Any javascript stationaryRegion event-listeners?
    if (self.delegate && [self.delegate respondsToSelector:@selector(onStationaryChanged:)]) {
        [self.delegate onStationaryChanged:location];
    }
}

- (void) onLocationChanged:(Location *)location
{
    DDLogDebug(@"%@ #onLocationChanged %@", TAG, location);
    stationaryLocation = nil;
    
    if (_config.isDebugging) {
        [self notify:[NSString stringWithFormat:@"Location update: %s\nSPD: %0.0f | DF: %ld | ACY: %0.0f",
                      ((operationMode == FOREGROUND) ? "FG" : "BG"),
                      [location.speed doubleValue],
                      (long) nil, //locationProvider.distanceFilter,
                      [location.accuracy doubleValue]
                      ]];
        
        AudioServicesPlaySystemSound (locationSyncSound);
    }
    
    SQLiteLocationDAO* locationDAO = [SQLiteLocationDAO sharedInstance];
    // TODO: investigate location id always 0
    location.id = [locationDAO persistLocation:location limitRows:_config.maxLocations];

    if ([_config hasSyncUrl] || [_config hasUrl]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self sync:location];
        });
    }

    // Delegate to main module
    if (self.delegate && [self.delegate respondsToSelector:@selector(onLocationChanged:)]) {
        [self.delegate onLocationChanged:location];
    }
}

- (void) onAuthorizationChanged:(BGAuthorizationStatus)authStatus
{
    [self.delegate onAuthorizationChanged:authStatus];
}

- (void) onError:(NSError*)error
{
    [self.delegate onError:error];
}

- (void) onLocationPause
{
    [self.delegate onLocationPause];
}

- (void) onLocationResume
{
    [self.delegate onLocationResume];
}

/**@
 * If you don't stopMonitoring when application terminates, the app will be awoken still when a
 * new location arrives, essentially monitoring the user's location even when they've killed the app.
 * Might be desirable in certain apps.
 */
- (void) onAppTerminate
{
    if (_config.stopOnTerminate) {
        DDLogInfo(@"%@ #onAppTerminate.", TAG);
        [self stop:nil];
    } else {
        [self switchMode:BACKGROUND];
    }
}

- (void) dealloc
{
    [locationProvider onDestroy];
    //    [super dealloc];
}

@end
