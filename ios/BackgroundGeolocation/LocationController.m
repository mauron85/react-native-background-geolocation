//
//  LocationController.m
//
//  Created by Jinru on 12/19/09.
//  Copyright 2009 Arizona State University. All rights reserved.
//

#import "Location.h"
#import "LocationController.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define LOCATION_DENIED         "User denied use of location services."
#define LOCATION_RESTRICTED     "Application's use of location services is restricted."
#define LOCATION_NOT_DETERMINED "User undecided on application's use of location services."

static LocationController* sharedCLDelegate = nil;
static NSString * const Domain = @"com.marianhello";

@implementation LocationController
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
    NSUInteger authStatus;
    
    if ([CLLocationManager respondsToSelector:@selector(authorizationStatus)]) { // iOS 4.2+
        authStatus = [CLLocationManager authorizationStatus];
        
        if (authStatus == kCLAuthorizationStatusDenied) {
            if (outError != NULL) {
                NSDictionary *errorDictionary = @{
                                                  NSLocalizedDescriptionKey: NSLocalizedString(@LOCATION_DENIED, nil)
                                                  };

                *outError = [NSError errorWithDomain:Domain code:BG_PERMISSION_DENIED userInfo:errorDictionary];
            }
            
            return NO;
        }
        
        if (authStatus == kCLAuthorizationStatusRestricted) {
            if (outError != NULL) {
                NSDictionary *errorDictionary = @{
                                                  NSLocalizedDescriptionKey: NSLocalizedString(@LOCATION_RESTRICTED, nil)
                                                  };
                *outError = [NSError errorWithDomain:Domain code:BG_PERMISSION_DENIED userInfo:errorDictionary];
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
    [locationManager stopUpdatingLocation];
    return YES;
}

- (void) setPausesLocationUpdatesAutomatically:(BOOL)newPausesLocationsUpdatesAutomatically
{
    locationManager.pausesLocationUpdatesAutomatically = newPausesLocationsUpdatesAutomatically;
}

- (BOOL) getPausesLocationUpdatesAutomatically
{
    return locationManager.pausesLocationUpdatesAutomatically;
}

- (void) setDistanceFilter:(CLLocationDistance)newDistanceFiler
{
    locationManager.distanceFilter = newDistanceFiler;
}

- (CLLocationDistance) getDistanceFilter
{
    return locationManager.distanceFilter;
}

- (void) setActivityType:(CLActivityType)newActivityType
{
    locationManager.activityType = newActivityType;
}

- (CLActivityType) getActivityType
{
    return locationManager.activityType;
}

- (void) setDesiredAccuracy:(CLLocationAccuracy)newDesiredAccuracy
{
    locationManager.desiredAccuracy = newDesiredAccuracy;
}

- (CLLocationAccuracy) setDesiredAccuracy
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
        NSDictionary *errorDictionary = @{
                                          NSUnderlyingErrorKey : error
                                          };
        NSError *outError = [NSError errorWithDomain:Domain code:BG_SERVICE_ERROR userInfo:errorDictionary];

        [self.delegate onError:outError];
    }
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
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


#pragma mark - Singleton implementation in ARC
+ (LocationController *)sharedInstance
{
    static LocationController *sharedLocationControllerInstance = nil;
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
