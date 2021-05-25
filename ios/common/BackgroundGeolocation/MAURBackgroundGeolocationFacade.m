//
//  MAURBackgroundGeolocationFacade.m
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
#import "MAURBackgroundGeolocationFacade.h"
#import "MAURPostLocationTask.h"
#import "MAURSQLiteConfigurationDAO.h"
#import "MAURSQLiteLocationDAO.h"
#import "MAURBackgroundTaskManager.h"
#import "MAURLogging.h"
#import "FMDBLogger.h"
#import "MAURLogReader.h"
#import "MAURLocationManager.h"
#import "MAURActivityLocationProvider.h"
#import "MAURDistanceFilterLocationProvider.h"
#import "MAURRawLocationProvider.h"
#import "MAURUncaughtExceptionLogger.h"
#import "MAURPostLocationTask.h"
#import "INTULocationManager.h"

// error messages
#define CONFIGURE_ERROR_MSG             "Configuration error."
#define SERVICE_ERROR_MSG               "Cannot start service error."
#define UNKNOWN_LOCATION_PROVIDER_MSG   "Unknown location provider."

// Position errors
// https://developer.mozilla.org/en-US/docs/Web/API/PositionError
#define PERMISSION_DENIED       1
#define POSITION_UNAVAILABLE    2
#define TIMEOUT                 3

static NSString * const BGGeolocationDomain = @"com.marianhello";
static NSString * const TAG = @"BgGeo";

FMDBLogger *sqliteLogger;

@interface MAURBackgroundGeolocationFacade () <MAURProviderDelegate, MAURPostLocationTaskDelegate>
@end

@implementation MAURBackgroundGeolocationFacade {
    BOOL isStarted;
    MAUROperationalMode operationMode;
    
    UILocalNotification *localNotification;
    
    // configurable options
    MAURConfig *_config;
    
    MAURLocation *stationaryLocation;
    MAURAbstractLocationProvider<MAURLocationProvider> *locationProvider;
    MAURPostLocationTask *postLocationTask;
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
    
    MAHUncaughtExceptionLogger *logger = mah_get_uncaught_exception_logger();
    logger->setEnabled(YES);
    
    postLocationTask = [[MAURPostLocationTask alloc] init];
    postLocationTask.delegate = self;
    
    localNotification = [[UILocalNotification alloc] init];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    
    isStarted = NO;
    
    return self;
}

/**
 * configure manager
 * @param {Config} configuration
 * @param {NSError} optional error
 */
- (BOOL) configure:(MAURConfig*)config error:(NSError * __autoreleasing *)outError
{
    __block NSError *error = nil;
    
    MAURConfig *currentConfig = [self getConfig];
    _config = [MAURConfig merge:currentConfig withConfig:config];
    
    DDLogInfo(@"%@ #configure: %@", TAG, _config);
    
    postLocationTask.config = _config;
    
    MAURSQLiteConfigurationDAO* configDAO = [MAURSQLiteConfigurationDAO sharedInstance];
    [configDAO persistConfiguration:_config];
    
    // ios 8 requires permissions to send local-notifications
    if ([_config isDebugging]) {
        [self runOnMainThread:^{
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
        }];
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
            *outError = [NSError errorWithDomain:BGGeolocationDomain code:MAURBGConfigureError userInfo:userInfo];
        }
        
        return NO;
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
    MAURConfig *config = [self getConfig];
    
    postLocationTask.config = config;
    [postLocationTask start];
    
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
    
    [postLocationTask stop];
    
    [self runOnMainThread:^{
        isStarted = ![locationProvider onStop:outError];
    }];
    
    return isStarted;
}

/**
 * toggle between foreground and background operation mode
 */
- (void) switchMode:(MAUROperationalMode)mode
{
    DDLogInfo(@"%@ #switchMode %lu", TAG, (unsigned long)mode);
    
    operationMode = mode;
    
    if (!isStarted) return;
    
    if ([self getConfig].isDebugging) {
        AudioServicesPlaySystemSound (operationMode  == MAURForegroundMode ? paceChangeYesSound : paceChangeNoSound);
    }
    
    [self runOnMainThread:^{
        [locationProvider onSwitchMode:mode];
    }];
}

- (BOOL) locationServicesEnabled
{
    if ([CLLocationManager respondsToSelector:@selector(locationServicesEnabled)]) { // iOS 4.x
        return [CLLocationManager locationServicesEnabled];
    }
    
    return NO;
}

- (MAURLocationAuthorizationStatus) authorizationStatus
{
    CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
    switch (authStatus) {
        case kCLAuthorizationStatusNotDetermined:
            return MAURLocationAuthorizationNotDetermined;
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            return MAURLocationAuthorizationDenied;
        case kCLAuthorizationStatusAuthorizedAlways:
            return MAURLocationAuthorizationAlways;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            return MAURLocationAuthorizationForeground;
    }
}

- (BOOL) isStarted
{
    return isStarted;
}

- (MAURAbstractLocationProvider<MAURLocationProvider>*) getProvider:(int)providerId error:(NSError * __autoreleasing *)outError
{
    NSDictionary *errorDictionary;
    MAURAbstractLocationProvider<MAURLocationProvider> *locationProvider = nil;
    switch (providerId) {
        case DISTANCE_FILTER_PROVIDER:
            locationProvider = [[MAURDistanceFilterLocationProvider alloc] init];
            break;
        case ACTIVITY_PROVIDER:
            locationProvider = [[MAURActivityLocationProvider alloc] init];
            break;
        case RAW_PROVIDER:
            locationProvider = [[MAURRawLocationProvider alloc] init];
            break;
        default:
            if (outError != nil) {
                errorDictionary = @{
                                    NSLocalizedDescriptionKey: NSLocalizedString(@UNKNOWN_LOCATION_PROVIDER_MSG, nil),
                                    };
                *outError = [NSError errorWithDomain:BGGeolocationDomain code:MAURBGConfigureError userInfo:errorDictionary];
            }
            return nil;
    }
    [locationProvider onCreate];
    return locationProvider;
}

- (void) showAppSettings
{
    [self runOnMainThread:^{
        BOOL canGoToSettings = (UIApplicationOpenSettingsURLString != NULL);
        if (canGoToSettings) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }];
}

- (void) showLocationSettings
{
    // NOOP - Since Apple started rejecting apps using non public url schemes
    // https://github.com/mauron85/cordova-plugin-background-geolocation/issues/394
}

- (MAURLocation*) getStationaryLocation
{
    return stationaryLocation;
}

- (NSArray<MAURLocation*>*) getLocations
{
    MAURSQLiteLocationDAO* locationDAO = [MAURSQLiteLocationDAO sharedInstance];
    return [locationDAO getAllLocations];
}

- (NSArray<MAURLocation*>*) getValidLocations
{
    MAURSQLiteLocationDAO* locationDAO = [MAURSQLiteLocationDAO sharedInstance];
    return [locationDAO getValidLocations];
}

- (BOOL) deleteLocation:(NSNumber*)locationId error:(NSError * __autoreleasing *)outError
{
    MAURSQLiteLocationDAO* locationDAO = [MAURSQLiteLocationDAO sharedInstance];
    return [locationDAO deleteLocation:locationId error:outError];
}

- (BOOL) deleteAllLocations:(NSError * __autoreleasing *)outError
{
    MAURSQLiteLocationDAO* locationDAO = [MAURSQLiteLocationDAO sharedInstance];
    return [locationDAO deleteAllLocations:outError];
}

- (MAURLocation*)getCurrentLocation:(int)timeout maximumAge:(long)maximumAge
                 enableHighAccuracy:(BOOL)enableHighAccuracy
                              error:(NSError * __autoreleasing *)outError
{
    __block NSError *error = nil;
    __block CLLocation *location = nil;
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [self runOnMainThread:^{
        CLLocation *currentLocation = [MAURLocationManager sharedInstance].locationManager.location;
        if (currentLocation != nil) {
            long locationAge = ceil(fabs([currentLocation.timestamp timeIntervalSinceNow]) * 1000);
            if (locationAge <= maximumAge) {
                location = currentLocation;
                dispatch_semaphore_signal(sema);
                return;
            }
        }

        INTULocationManager *locationManager = [INTULocationManager sharedInstance];
        float timeoutInSeconds = ceil((float)timeout/1000);
        [locationManager requestLocationWithDesiredAccuracy:enableHighAccuracy ? INTULocationAccuracyRoom : INTULocationAccuracyCity
                                                    timeout:timeoutInSeconds
                                       delayUntilAuthorized:YES    // This parameter is optional, defaults to NO if omitted
                                                      block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
                                                          if (status == INTULocationStatusSuccess) {
                                                              // Request succeeded, meaning achievedAccuracy is at least the requested accuracy, and
                                                              // currentLocation contains the device's current location.
                                                              location = currentLocation;
                                                          }
                                                          else if (status == INTULocationStatusTimedOut) {
                                                              // Wasn't able to locate the user with the requested accuracy within the timeout interval.
                                                              // However, currentLocation contains the best location available (if any) as of right now,
                                                              // and achievedAccuracy has info on the accuracy/recency of the location in currentLocation.
                                                              error = [NSError errorWithDomain:BGGeolocationDomain code:TIMEOUT userInfo:nil];
                                                          }
                                                          else {
                                                              // An error occurred, more info is available by looking at the specific status returned.
                                                              error = [NSError errorWithDomain:BGGeolocationDomain code:POSITION_UNAVAILABLE userInfo:nil];
                                                          }
                                                          dispatch_semaphore_signal(sema);
                                                      }];
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    if (location != nil) {
        return [MAURLocation fromCLLocation:location];
    }

    if (outError != nil) {
        *outError = error;
    }

    return nil;
}

- (MAURConfig*) getConfig
{
    if (_config == nil) {
        MAURSQLiteConfigurationDAO* configDAO = [MAURSQLiteConfigurationDAO sharedInstance];
        _config = [configDAO retrieveConfiguration];
        if (_config == nil) {
            _config = [[MAURConfig alloc] initWithDefaults];
        }
    }
    
    return _config;
}

- (NSArray*) getLogEntries:(NSInteger)limit
{
    MAURLogReader *logReader = [[MAURLogReader alloc] initWithLogDirectory:[self loggerDirectory]];
    return [logReader getEntries:limit fromLogEntryId:0 minLogLevel:DDLogFlagDebug];
}

- (NSArray*) getLogEntries:(NSInteger)limit fromLogEntryId:(NSInteger)entryId minLogLevelFromString:(NSString *)minLogLevel
{
    MAURLogReader *logReader = [[MAURLogReader alloc] initWithLogDirectory:[self loggerDirectory]];
    return [logReader getLogEntries:limit fromLogEntryId:entryId minLogLevelAsString:minLogLevel];
}

- (NSArray*) getLogEntries:(NSInteger)limit fromLogEntryId:(NSInteger)entryId minLogLevel:(DDLogFlag)minLogLevel
{
    MAURLogReader *logReader = [[MAURLogReader alloc] initWithLogDirectory:[self loggerDirectory]];
    NSArray *logs = [logReader getEntries:limit fromLogEntryId:entryId minLogLevel:minLogLevel];
    return logs;
}

- (void) forceSync
{
    [postLocationTask sync];
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

- (void) onStationaryChanged:(MAURLocation *)location
{
    DDLogDebug(@"%@ #onStationaryChanged", TAG);
    stationaryLocation = location;
    
    [postLocationTask add:location];
    
    MAURConfig *config = [self getConfig];
    if ([config isDebugging]) {
        double distanceFilter = [MAURLocationManager sharedInstance].distanceFilter;
        [self notify:[NSString stringWithFormat:@"Stationary update: %s\nSPD: %0.0f | DF: %f | ACY: %0.0f | RAD: %0.0f",
                      ((operationMode == MAURForegroundMode) ? "FG" : "BG"),
                      [location.speed doubleValue],
                      distanceFilter,
                      [location.accuracy doubleValue],
                      [location.radius doubleValue]
                      ]];
        
        AudioServicesPlaySystemSound (locationSyncSound);
    }
    
    // Any javascript stationaryRegion event-listeners?
    if (self.delegate && [self.delegate respondsToSelector:@selector(onStationaryChanged:)]) {
        [self.delegate onStationaryChanged:location];
    }
}

- (void) onLocationChanged:(MAURLocation *)location
{
    DDLogDebug(@"%@ #onLocationChanged %@", TAG, location);
    stationaryLocation = nil;
    
    [postLocationTask add:location];
    
    MAURConfig *config = [self getConfig];
    if ([config isDebugging]) {
        double distanceFilter = [MAURLocationManager sharedInstance].distanceFilter;
        [self notify:[NSString stringWithFormat:@"Location update: %s\nSPD: %0.0f | DF: %f | ACY: %0.0f",
                      ((operationMode == MAURForegroundMode) ? "FG" : "BG"),
                      [location.speed doubleValue],
                      distanceFilter,
                      [location.accuracy doubleValue]
                      ]];
        
        AudioServicesPlaySystemSound (locationSyncSound);
    }
    
    // Delegate to main module
    if (self.delegate && [self.delegate respondsToSelector:@selector(onLocationChanged:)]) {
        [self.delegate onLocationChanged:location];
    }
}

- (void) onAuthorizationChanged:(MAURLocationAuthorizationStatus)authStatus
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

- (void) onActivityChanged:(MAURActivity *)activity
{
    DDLogDebug(@"%@ #onActivityChanged %@", TAG, activity);
    
    if ([self getConfig].isDebugging) {
        [self notify:[NSString stringWithFormat:@"%@ activity detected: %@ activity, confidence: %@", TAG, activity.type, activity.confidence]];
    }
    
    [self.delegate onActivityChanged:activity];
}

/**@
 * If you don't stopMonitoring when application terminates, the app will be awoken still when a
 * new location arrives, essentially monitoring the user's location even when they've killed the app.
 * Might be desirable in certain apps.
 */
- (void) onAppTerminate
{
    MAURConfig *config = [self getConfig];
    if ([config stopOnTerminate]) {
        DDLogInfo(@"%@ #onAppTerminate.", TAG);
        [self stop:nil];
    } else {
        [locationProvider onTerminate];
    }
}

- (void) dealloc
{
    DDLogDebug(@"%@ #dealloc", TAG);
    // currently noop
}

#pragma mark - Location transform

+ (void) setLocationTransform:(MAURLocationTransform _Nullable)transform
{
    [MAURPostLocationTask setLocationTransform:transform];
}

+ (MAURLocationTransform _Nullable) locationTransform
{
    return [MAURPostLocationTask locationTransform];
}

#pragma mark - MAURPostLocationTaskDelegate

- (void) postLocationTaskRequestedAbortUpdates:(MAURPostLocationTask *)task
{
    if (_delegate && [_delegate respondsToSelector:@selector(onAbortRequested)])
    {
        // We have a delegate, tell it that there's a request.
        // It will decide whether to stop or not.
        [_delegate onAbortRequested];
    }
    else
    {
        // No delegate, we may be running in the background.
        // Let's just stop.
        [self stop:nil];
    }
}

- (void) postLocationTaskHttpAuthorizationUpdates:(MAURPostLocationTask *)task
{
    if (_delegate && [_delegate respondsToSelector:@selector(onHttpAuthorization)])
    {
        [_delegate onHttpAuthorization];
    }
}

@end
