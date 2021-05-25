//
//  MAURConfig.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 11/06/16.
//

#ifndef MAURConfig_h
#define MAURConfig_h

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

enum {
    DISTANCE_FILTER_PROVIDER = 0,
    ACTIVITY_PROVIDER = 1,
    RAW_PROVIDER = 2
};

@interface MAURConfig : NSObject <NSCopying>

@property NSNumber *stationaryRadius;
@property NSNumber *distanceFilter;
@property NSNumber *desiredAccuracy;
@property NSNumber *_debug;
@property NSString *activityType;
@property NSNumber *activitiesInterval;
@property NSNumber *_stopOnTerminate;
@property NSString *url;
@property NSString *syncUrl;
@property NSNumber *syncThreshold;
@property NSMutableDictionary* httpHeaders;
@property NSNumber *_saveBatteryOnBackground;
@property NSNumber *maxLocations;
@property NSNumber *_pauseLocationUpdates;
@property NSNumber *locationProvider;
@property NSObject *_template;

- (instancetype) initWithDefaults;
+ (instancetype) fromDictionary:(NSDictionary*)config;
+ (instancetype) merge:(MAURConfig*)config withConfig:(MAURConfig*)newConfig;
+ (NSDictionary*) getDefaultTemplate;

- (BOOL) hasStationaryRadius;
- (BOOL) hasDistanceFilter;
- (BOOL) hasDesiredAccuracy;
- (BOOL) hasDebug;
- (BOOL) hasActivityType;
- (BOOL) hasStopOnTerminate;
- (BOOL) hasUrl;
- (BOOL) hasValidUrl;
- (BOOL) hasSyncUrl;
- (BOOL) hasValidSyncUrl;
- (BOOL) hasSyncThreshold;
- (BOOL) hasHttpHeaders;
- (BOOL) hasSaveBatteryOnBackground;
- (BOOL) hasMaxLocations;
- (BOOL) hasPauseLocationUpdates;
- (BOOL) hasLocationProvider;
- (BOOL) hasTemplate;
- (BOOL) hasActivitiesInterval;
- (BOOL) isDebugging;
- (BOOL) stopOnTerminate;
- (BOOL) saveBatteryOnBackground;
- (BOOL) pauseLocationUpdates;
- (CLActivityType) decodeActivityType;
- (NSInteger) decodeDesiredAccuracy;
- (NSString*) getHttpHeadersAsString:(NSError * __autoreleasing *)outError;
- (NSString*) getTemplateAsString:(NSError * __autoreleasing *)outError;
- (NSDictionary*) toDictionary;

@end;

#endif /* MAURConfig_h */
