//
//  LocationController.h
//
//  Created by Jinru on 12/19/09.
//  Copyright 2009 Arizona State University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "ProviderDelegate.h"

// protocol for sending location updates to another view controller
@protocol LocationControllerDelegate
@required
- (void) onAuthorizationChanged:(BGAuthorizationStatus)authStatus;
- (void) onLocationsChanged:(NSArray*)locations;
- (void) onError:(NSError*)error;
- (void) onLocationPause:(CLLocationManager*)manager;
- (void) onLocationResume:(CLLocationManager*)manager;
@end

@interface LocationController : NSObject <CLLocationManagerDelegate>  {
    
    CLLocationManager* locationManager;
    CLLocation* location;
    __weak id delegate;
}

@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, weak) id  delegate;

- (BOOL) start:(NSError * __autoreleasing *)outError;
- (BOOL) stop:(NSError * __autoreleasing *)outError;
- (void) setPausesLocationUpdatesAutomatically:(BOOL)newPausesLocationsUpdatesAutomatically;
- (BOOL) getPausesLocationUpdatesAutomatically;
- (void) setDistanceFilter:(CLLocationDistance)newDistanceFiler;
- (CLLocationDistance) getDistanceFilter;
- (void) setActivityType:(CLActivityType)newActivityType;
- (CLActivityType) getActivityType;
- (void) setDesiredAccuracy:(CLLocationAccuracy)newDesiredAccuracy;
- (CLLocationAccuracy) setDesiredAccuracy;

+ (LocationController*)sharedInstance; // Singleton method

@end
