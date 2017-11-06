//
//  Config.h
//  CDVBackgroundGeolocation
//
//  Created by Marian Hello on 11/06/16.
//

#ifndef Config_h
#define Config_h

#import <CoreLocation/CoreLocation.h>

enum {
    DISTANCE_FILTER_PROVIDER = 0,
    ACTIVITY_PROVIDER = 1,
    RAW_PROVIDER = 2
};

@interface Config : NSObject

@property NSInteger stationaryRadius;
@property NSInteger distanceFilter;
@property NSInteger desiredAccuracy;
@property BOOL isDebugging;
@property NSString* activityType;
@property BOOL stopOnTerminate;
@property NSString* url;
@property NSString* syncUrl;
@property NSInteger syncThreshold;
@property NSMutableDictionary* httpHeaders;
@property BOOL saveBatteryOnBackground;
@property NSInteger maxLocations;
@property BOOL pauseLocationUpdates;
@property NSInteger locationProvider;

+ (instancetype) fromDictionary:(NSDictionary*)config;
- (CLActivityType) decodeActivityType;
- (NSInteger) decodeDesiredAccuracy;
- (BOOL) hasUrl;
- (BOOL) hasSyncUrl;
- (NSDictionary*) toDictionary;

@end;

#endif /* Config_h */
