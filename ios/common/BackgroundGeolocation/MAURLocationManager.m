//
//  MAURLocationManager.m
//
//  Created by Jinru on 12/19/09.
//  Copyright 2009 Arizona State University. All rights reserved.
//

#import "MAURLocation.h"
#import "MAURLocationManager.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define LOCATION_DENIED         "User denied use of location services."
#define LOCATION_RESTRICTED     "Application's use of location services is restricted."
#define LOCATION_NOT_DETERMINED "User undecided on application's use of location services."

static MAURLocationManager* sharedCLDelegate = nil;
static NSString *const TAG = @"MAURLocationManager";
static NSString *const Domain = @"com.marianhello";

@implementation MAURLocationManager
@synthesize locationManager, delegate;

- (id)init
{
    self = [super init];
    if (self != nil) {
        locationManager = [[CLLocationManager alloc] init];

        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
            locationManager.allowsBackgroundLocationUpdates = YES;
        }

        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
    return self;
}

- (BOOL) start:(NSError * __autoreleasing *)outError
{
    NSAssert([NSThread isMainThread], @"%@ %@", TAG, @"should only be called from the main thread.");

    NSUInteger authStatus;
    
    if ([CLLocationManager respondsToSelector:@selector(authorizationStatus)]) { // iOS 4.2+
        authStatus = [CLLocationManager authorizationStatus];
        
        if (authStatus == kCLAuthorizationStatusDenied) {
            if (outError != NULL) {
                NSDictionary *errorDictionary = @{
                                                  NSLocalizedDescriptionKey: NSLocalizedString(@LOCATION_DENIED, nil)
                                                  };

                *outError = [NSError errorWithDomain:Domain code:MAURBGPermissionDenied userInfo:errorDictionary];
            }
            
            return NO;
        }
        
        if (authStatus == kCLAuthorizationStatusRestricted) {
            if (outError != NULL) {
                NSDictionary *errorDictionary = @{
                                                  NSLocalizedDescriptionKey: NSLocalizedString(@LOCATION_RESTRICTED, nil)
                                                  };
                *outError = [NSError errorWithDomain:Domain code:MAURBGPermissionDenied userInfo:errorDictionary];
            }
            
            return NO;
        }
        
#ifdef __IPHONE_8_0
        // we do startUpdatingLocation even though we might not get permissions granted
        // we can stop later on when recieved callback on user denial
        // it's neccessary to start call startUpdatingLocation in iOS < 8.0 to show user prompt!
        
        if (authStatus == kCLAuthorizationStatusNotDetermined) {
            if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {  //iOS 8.0+
                [locationManager requestAlwaysAuthorization];
            }
        }
#endif
    }
    
    [locationManager startUpdatingLocation];
    return YES;
}

- (BOOL) stop:(NSError * __autoreleasing *)outError
{
    NSAssert([NSThread isMainThread], @"%@ %@", TAG, @"should only be called from the main thread.");
    [locationManager stopUpdatingLocation];
    return YES;
}

- (BOOL) startMonitoringSignificantLocationChanges
{
    NSAssert([NSThread isMainThread], @"%@ %@", TAG, @"should only be called from the main thread.");
    [locationManager startMonitoringSignificantLocationChanges];
    return YES;
}

- (BOOL) stopMonitoringSignificantLocationChanges
{
    NSAssert([NSThread isMainThread], @"%@ %@", TAG, @"should only be called from the main thread.");
    [locationManager stopMonitoringSignificantLocationChanges];
    return YES;
}

- (void) startMonitoringForRegion:(CLRegion*)region
{
    NSAssert([NSThread isMainThread], @"%@ %@", TAG, @"should only be called from the main thread.");
    [locationManager startMonitoringForRegion:region];
}

- (void) stopMonitoringForRegion:(CLRegion*)region
{
    NSAssert([NSThread isMainThread], @"%@ %@", TAG, @"should only be called from the main thread.");
    [locationManager stopMonitoringForRegion:region];
}

- (void) stopMonitoringForRegionIdentifier:(NSString*)identifier
{
    NSAssert([NSThread isMainThread], @"%@ %@", TAG, @"should only be called from the main thread.");
    for (CLRegion *region in [locationManager monitoredRegions]){
        if([region.identifier isEqualToString:identifier]){
            [locationManager stopMonitoringForRegion:region];
        }
    }
}

- (void) stopMonitoringAllRegions
{
    NSAssert([NSThread isMainThread], @"%@ %@", TAG, @"should only be called from the main thread.");
    for (CLRegion *region in [locationManager monitoredRegions]) {
        [locationManager stopMonitoringForRegion:region];
    }
}

- (NSSet<__kindof CLRegion *>*) monitoredRegions
{
    return locationManager.monitoredRegions;
}

- (void) setShowsBackgroundLocationIndicator:(BOOL)shows
{
    if (@available(iOS 11, *)) {
        locationManager.showsBackgroundLocationIndicator = shows;
    }
}

- (void) setPausesLocationUpdatesAutomatically:(BOOL)newPausesLocationsUpdatesAutomatically
{
    locationManager.pausesLocationUpdatesAutomatically = newPausesLocationsUpdatesAutomatically;
}

- (BOOL) pausesLocationUpdatesAutomatically
{
    return locationManager.pausesLocationUpdatesAutomatically;
}

- (void) setDistanceFilter:(CLLocationDistance)newDistanceFiler
{
    locationManager.distanceFilter = newDistanceFiler;
}

- (CLLocationDistance) distanceFilter
{
    return locationManager.distanceFilter;
}

- (void) setActivityType:(CLActivityType)newActivityType
{
    locationManager.activityType = newActivityType;
}

- (CLActivityType) activityType
{
    return locationManager.activityType;
}

- (void) setDesiredAccuracy:(CLLocationAccuracy)newDesiredAccuracy
{
    locationManager.desiredAccuracy = newDesiredAccuracy;
}

- (CLLocationAccuracy) desiredAccuracy
{
    return locationManager.desiredAccuracy;
}


#pragma mark -
#pragma mark CLLocationManagerDelegate Methods
- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [self.delegate onLocationsChanged:locations];
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onError:)]) {
        NSDictionary *errorDictionary = @{
                                          NSUnderlyingErrorKey : error
                                          };
        NSError *outError = [NSError errorWithDomain:Domain code:MAURBGServiceError userInfo:errorDictionary];

        [self.delegate onError:outError];
    }
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    MAURLocationAuthorizationStatus authStatus;
    
    switch(status) {
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            authStatus = MAURLocationAuthorizationDenied;
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            authStatus = MAURLocationAuthorizationAlways;
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            authStatus = MAURLocationAuthorizationForeground;
            break;
        default:
            return;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(onAuthorizationChanged:)]) {
        [self.delegate onAuthorizationChanged:authStatus];
    }
}

- (void) locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onLocationPause:)]) {
        [self.delegate onLocationPause:manager];
    }
}

- (void) locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onLocationResume:)]) {
        [self.delegate onLocationResume:manager];
    }
}

- (void) locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onRegionExit:)]) {
        [self.delegate onRegionExit:region];
    }
}

#pragma mark - Singleton implementation in ARC
+ (MAURLocationManager *)sharedInstance
{
    static MAURLocationManager *sharedLocationControllerInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedLocationControllerInstance = [[self alloc] init];
    });
    return sharedLocationControllerInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedCLDelegate == nil) {
            sharedCLDelegate = [super allocWithZone:zone];
            return sharedCLDelegate;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
