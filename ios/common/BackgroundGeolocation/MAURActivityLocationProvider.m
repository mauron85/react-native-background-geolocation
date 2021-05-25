//
//  MAURActivityLocationProvider.m
//  BackgroundGeolocation
//
//  Created by Marian Hello on 14/09/2016.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAURActivityLocationProvider.h"
#import "MAURActivity.h"
#import "SOMotionDetector.h"
#import "MAURLocationManager.h"
#import "MAURLogging.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

static NSString * const TAG = @"ActivityLocationProvider";
static NSString * const Domain = @"com.marianhello";

@interface MAURActivityLocationProvider () <SOMotionDetectorDelegate>
@end

@implementation MAURActivityLocationProvider {
    BOOL isStarted;
    BOOL isTracking;
    SOMotionType lastMotionType;

    MAURLocationManager *locationManager;
}

- (instancetype) init
{
    self = [super init];
    
    if (self) {
        isStarted = NO;
        isTracking = NO;
    }
    
    return self;
}

- (void) onCreate {
    locationManager = [MAURLocationManager sharedInstance];
    locationManager.delegate = self;

    SOMotionDetector *motionDetector = [SOMotionDetector sharedInstance];
    motionDetector.delegate = self;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        motionDetector.useM7IfAvailable = YES; //Use M7 chip if available, otherwise use lib's algorithm
    }
}

- (BOOL) onConfigure:(MAURConfig*)config error:(NSError * __autoreleasing *)outError
{
    DDLogVerbose(@"%@ configure", TAG);
    
    locationManager.pausesLocationUpdatesAutomatically = [config pauseLocationUpdates];
    locationManager.activityType = [config decodeActivityType];
    locationManager.distanceFilter = config.distanceFilter.integerValue; // meters
    locationManager.desiredAccuracy = [config decodeDesiredAccuracy];
    [SOMotionDetector sharedInstance].activityDetectionInterval = config.activitiesInterval.intValue / 1000;
    
    return YES;
}

- (BOOL) onStart:(NSError * __autoreleasing *)outError
{
    DDLogInfo(@"%@ will start", TAG);
    
    if (!isStarted) {
        [[SOMotionDetector sharedInstance] startDetection];
        [self startTracking];
        isStarted = YES;
    }
    
    return YES;
}

- (BOOL) onStop:(NSError * __autoreleasing *)outError
{
    DDLogInfo(@"%@ will stop", TAG);
    
    if (isStarted) {
        [[SOMotionDetector sharedInstance] stopDetection];
        [self stopTracking];
        isStarted = NO;
    }
    
    return YES;
}

- (void) startTracking
{
    if (isTracking) {
        return;
    }

    NSError *error = nil;
    if ([locationManager start:&error]) {
        isTracking = YES;
    } else {
        [self.delegate onError:error];
    }
}

- (void) stopTracking
{
    if (isTracking) {
        [locationManager stop:nil];
        isTracking = NO;
    }
}

- (void) onSwitchMode:(MAUROperationalMode)mode
{
    /* do nothing */
}

- (void) onAuthorizationChanged:(MAURLocationAuthorizationStatus)authStatus
{
    [self.delegate onAuthorizationChanged:authStatus];
}

- (void) onLocationsChanged:(NSArray*)locations
{
    if (lastMotionType == MotionTypeNotMoving) {
        [self stopTracking];
        [self.delegate onStationaryChanged:[MAURLocation fromCLLocation:[locations lastObject]]];
    }

    for (CLLocation *location in locations) {
        MAURLocation *bgloc = [MAURLocation fromCLLocation:location];
        [self.delegate onLocationChanged:bgloc];
    }
}

- (void)motionDetector:(SOMotionDetector *)motionDetector activityTypeChanged:(SOMotionActivity *)motionActivity;
{
    int confidence = motionActivity.confidence;
    SOMotionType motionType = motionActivity.motionType;
    lastMotionType = motionType;

    if (motionType != MotionTypeNotMoving) {
        [self startTracking];
    } else {
        // we delay tracking stop after location is found
    }

    NSString *type;
    switch (motionType) {
        case MotionTypeNotMoving:
            type = @"STILL";
            break;
        case MotionTypeWalking:
            type = @"WALKING";
            break;
        case MotionTypeRunning:
            type = @"RUNNING";
            break;
        case MotionTypeAutomotive:
            type = @"IN_VEHICLE";
            break;
        case MotionTypeUnknown:
            type = @"UNKNOWN";
            break;
    }
    
    DDLogDebug(@"%@ activityTypeChanged: %@", TAG, type);
    MAURActivity *activity = [[MAURActivity alloc] init];
    activity.type = type;
    activity.confidence = [NSNumber numberWithInt:confidence];
    
    [super.delegate onActivityChanged:activity];
}

- (void) onError:(NSError*)error
{
    [self.delegate onError:error];
}

- (void) onPause:(CLLocationManager*)manager
{
    [self.delegate onLocationPause];
}

- (void) onResume:(CLLocationManager*)manager
{
    [self.delegate onLocationResume];
}

- (void) onDestroy {
    DDLogInfo(@"Destroying %@ ", TAG);
    [self onStop:nil];
}

@end
