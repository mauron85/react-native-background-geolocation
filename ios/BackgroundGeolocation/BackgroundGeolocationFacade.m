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
#import "SQLiteConfigurationDAO.h"
#import "SQLiteLocationDAO.h"
#import "BackgroundTaskManager.h"
#import "Reachability.h"
#import "FMDBLogger.h"
#import "Logging.h"
#import "LogReader.h"
#import "ActivityLocationProvider.h"
#import "DistanceFilterLocationProvider.h"
#import "RawLocationProvider.h"

// error messages
#define CONFIGURE_ERROR_MSG             "Configuration error."
#define SERVICE_ERROR_MSG               "Cannot start service error."
#define UNKNOWN_LOCATION_PROVIDER_MSG   "Unknown location provider."

static NSString * const BGGeolocationDomain = @"com.marianhello";
static NSString * const TAG = @"BgGeo";

FMDBLogger *sqliteLogger;

@interface BackgroundGeolocationFacade () <ProviderDelegate>
@end

@implementation BackgroundGeolocationFacade {
    BOOL isStarted;
    BOOL hasConnectivity;

    BGOperationMode operationMode;

    UILocalNotification *localNotification;

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
   
    [DDLog addLogger:[DDASLLogger sharedInstance] withLevel:DDLogLevelInfo];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelDebug];
    
    sqliteLogger = [[FMDBLogger alloc] initWithLogDirectory:[self loggerDirectory]];
    sqliteLogger.saveThreshold     = 1;
    sqliteLogger.saveInterval      = 0;
    sqliteLogger.maxAge            = 60 * 60 * 24 * 7; //  7 days
    sqliteLogger.deleteInterval    = 60 * 60 * 24;     //  1 day
    sqliteLogger.deleteOnEverySave = NO;
    
    [DDLog addLogger:sqliteLogger withLevel:DDLogLevelDebug];

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
    __block NSError *error = nil;

    Config *currentConfig = [self getConfig];
    _config = [Config merge:currentConfig withConfig:config];
    
    DDLogInfo(@"%@ #configure: %@", TAG, _config);
    
    SQLiteConfigurationDAO* configDAO = [SQLiteConfigurationDAO sharedInstance];
    [configDAO persistConfiguration:_config];

    // ios 8 requires permissions to send local-notifications
    if ([_config isDebugging]) {
        UIApplication *app = [UIApplication sharedApplication];
        if ([[UIApplication sharedApplication]respondsToSelector:@selector(currentUserNotificationSettings)]) {
            UIUserNotificationType wantedTypes = UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert;
            UIUserNotificationSettings *currentSettings = [app currentUserNotificationSettings];
            if (!currentSettings || (currentSettings.types != wantedTypes)) {
                if ([app respondsToSelector:@selector(registerUserNotificationSettings:)]) {
                    [app registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:wantedTypes categories:nil]];
                }
            }
        }
    }

    if (isStarted) {
        // Note: CLLocationManager must be created on a thread with an active run loop (main thread)
        [self runOnMainThread:^{

            // requesting new provider
            if (![currentConfig.locationProvider isEqual:_config.locationProvider]) {
                [locationProvider onDestroy]; // destroy current provider
                locationProvider = [self getProvider:_config.locationProvider.intValue error:&error];
            }

            if (locationProvider == nil) {
                return;
            }

            // trap configuration errors
            if (![locationProvider onConfigure:_config error:&error]) {
                return;
            }

            isStarted = [locationProvider onStart:&error];
            locationProvider.delegate = self;
        }];
    }
    
    if (error != nil) {
        if (outError != nil) {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey: NSLocalizedString(@CONFIGURE_ERROR_MSG, nil),
                NSUnderlyingErrorKey : error
                };
            *outError = [NSError errorWithDomain:BGGeolocationDomain code:BG_CONFIGURE_ERROR userInfo:userInfo];
        }

        return NO;
    }
   
    if ([_config hasValidSyncUrl] && uploader == nil) {
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
    
    __block NSError *error = nil;
    Config *config = [self getConfig];
    
    // Note: CLLocationManager must be created on a thread with an active run loop (main thread)
    [self runOnMainThread:^{
        locationProvider = [self getProvider:config.locationProvider.intValue error:&error];

        if (locationProvider == nil) {
            return;
        }

        // trap configuration errors
        if (![locationProvider onConfigure:config error:&error]) {
            return;
        }
        
        isStarted = [locationProvider onStart:&error];
        locationProvider.delegate = self;
    }];

    
    if (!isStarted) {
        if (outError != nil) {
            *outError = error;
        }

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
        isStarted = ![locationProvider onStop:outError];
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

    if ([self getConfig].isDebugging) {
        AudioServicesPlaySystemSound (operationMode  == FOREGROUND ? paceChangeYesSound : paceChangeNoSound);
    }
   
    [self runOnMainThread:^{
        [locationProvider onSwitchMode:mode];
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

- (AbstractLocationProvider<LocationProvider>*) getProvider:(int)providerId error:(NSError * __autoreleasing *)outError
{
    NSDictionary *errorDictionary;
    AbstractLocationProvider<LocationProvider> *locationProvider = nil;
    switch (providerId) {
        case DISTANCE_FILTER_PROVIDER:
            locationProvider = [[DistanceFilterLocationProvider alloc] init];
            break;
        case ACTIVITY_PROVIDER:
            locationProvider = [[ActivityLocationProvider alloc] init];
            break;
        case RAW_PROVIDER:
            locationProvider = [[RawLocationProvider alloc] init];
            break;
        default:
            if (outError != nil) {
                errorDictionary = @{
                                    NSLocalizedDescriptionKey: NSLocalizedString(@UNKNOWN_LOCATION_PROVIDER_MSG, nil),
                                    };
                *outError = [NSError errorWithDomain:BGGeolocationDomain code:BG_CONFIGURE_ERROR userInfo:errorDictionary];
            }
            return nil;
    }
    [locationProvider onCreate];
    return locationProvider;
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
    if (@available(iOS 10, *)) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root=Privacy&path=LOCATION"]];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=LOCATION_SERVICES"]];
    }
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

- (BOOL) deleteLocation:(NSNumber*)locationId error:(NSError * __autoreleasing *)outError
{
    SQLiteLocationDAO* locationDAO = [SQLiteLocationDAO sharedInstance];
    return [locationDAO deleteLocation:locationId error:outError];
}

- (BOOL) deleteAllLocations:(NSError * __autoreleasing *)outError;
{
    SQLiteLocationDAO* locationDAO = [SQLiteLocationDAO sharedInstance];
    return [locationDAO deleteAllLocations:outError];
}

- (Config*) getConfig
{
    if (_config == nil) {
        SQLiteConfigurationDAO* configDAO = [SQLiteConfigurationDAO sharedInstance];
        _config = [configDAO retrieveConfiguration];
        if (_config == nil) {
            _config = [[Config alloc] initWithDefaults];
        }
    }

    return _config;
}

- (NSArray*) getLogEntries:(NSInteger)limit
{
    NSString *path = [[self loggerDirectory] stringByAppendingPathComponent:@"log.sqlite"];
    NSArray *logs = [LogReader getEntries:path limit:(NSInteger)limit];
    return logs;
}

- (void) post:(Location *)location
{
    Config *config = [self getConfig];
    
    SQLiteLocationDAO* locationDAO = [SQLiteLocationDAO sharedInstance];
    // TODO: investigate location id always 0
    location.locationId = [locationDAO persistLocation:location limitRows:config.maxLocations.integerValue];

    if (hasConnectivity && [config hasValidUrl]) {
        NSError *error = nil;
        if ([location postAsJSON:config.url withTemplate:config._template withHttpHeaders:config.httpHeaders error:&error]) {
            SQLiteLocationDAO* locationDAO = [SQLiteLocationDAO sharedInstance];
            if (location.locationId != nil) {
                [locationDAO deleteLocation:location.locationId error:nil];
            }
        } else {
            DDLogWarn(@"%@ postJSON failed: error: %@", TAG, error.userInfo[@"NSLocalizedDescription"]);
            hasConnectivity = [reach isReachable];
            [reach startNotifier];
        }
    }
}

- (void) sync
{
    Config *config = [self getConfig];

    if ([config hasValidSyncUrl]) {
        [uploader sync:config.syncUrl onLocationThreshold:config.syncThreshold.integerValue withTemplate:config._template withHttpHeaders:config.httpHeaders];
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

- (NSString *)loggerDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();

    return [basePath stringByAppendingPathComponent:@"SQLiteLogger"];
}

- (void) onStationaryChanged:(Location *)location
{
    DDLogDebug(@"%@ #onStationaryChanged", TAG);
    stationaryLocation = location;

    Config *config = [self getConfig];
    if ([config isDebugging]) {
        [self notify:[NSString stringWithFormat:@"Stationary update: %s\nSPD: %0.0f | DF: %ld | ACY: %0.0f | RAD: %0.0f",
                      ((operationMode == FOREGROUND) ? "FG" : "BG"),
                      [location.speed doubleValue],
                      (long) nil, //locationProvider.distanceFilter,
                      [location.accuracy doubleValue],
                      [location.radius doubleValue]
                      ]];
        
        AudioServicesPlaySystemSound (locationSyncSound);
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self post:location];
        [self sync];
    });

    // Any javascript stationaryRegion event-listeners?
    if (self.delegate && [self.delegate respondsToSelector:@selector(onStationaryChanged:)]) {
        [self.delegate onStationaryChanged:location];
    }
}

- (void) onLocationChanged:(Location *)location
{
    DDLogDebug(@"%@ #onLocationChanged %@", TAG, location);
    stationaryLocation = nil;
    
    Config *config = [self getConfig];

    if ([config isDebugging]) {
        [self notify:[NSString stringWithFormat:@"Location update: %s\nSPD: %0.0f | DF: %ld | ACY: %0.0f",
                      ((operationMode == FOREGROUND) ? "FG" : "BG"),
                      [location.speed doubleValue],
                      (long) nil, //locationProvider.distanceFilter,
                      [location.accuracy doubleValue]
                      ]];
        
        AudioServicesPlaySystemSound (locationSyncSound);
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self post:location];
        [self sync];
    });

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

- (void) onActivityChanged:(Activity *)activity
{
    DDLogDebug(@"%@ #onActivityChanged %@", TAG, activity);
    [self.delegate onActivityChanged:activity];
}

/**@
 * If you don't stopMonitoring when application terminates, the app will be awoken still when a
 * new location arrives, essentially monitoring the user's location even when they've killed the app.
 * Might be desirable in certain apps.
 */
- (void) onAppTerminate
{
    Config *config = [self getConfig];
    if ([config stopOnTerminate]) {
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
