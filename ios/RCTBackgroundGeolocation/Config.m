//
//  Config.m
//  CDVBackgroundGeolocation
//
//  Created by Marian Hello on 11/06/16.
//

#import <Foundation/Foundation.h>
#import "Config.h"

#define isNull(value) value == nil || [value isKindOfClass:[NSNull class]]

@implementation Config

@synthesize stationaryRadius, distanceFilter, desiredAccuracy, isDebugging, activityType, stopOnTerminate, url, syncUrl, syncThreshold, httpHeaders, saveBatteryOnBackground, maxLocations, pauseLocationUpdates, locationProvider;

-(id) init {
    self = [super init];

    if (self == nil) {
        return self;
    }

    stationaryRadius = 50;
    distanceFilter = 500;
    desiredAccuracy = 100;
    isDebugging = NO;
    activityType = @"OTHER";
    stopOnTerminate = NO;
    saveBatteryOnBackground = YES;
    maxLocations = 10000;
    syncThreshold = 100;
    pauseLocationUpdates = YES;
    locationProvider = DISTANCE_FILTER_PROVIDER;

    return self;
}

+(instancetype) fromDictionary:(NSDictionary*)config
{
    Config *instance = [[Config alloc] init];

    if (isNull(config[@"stationaryRadius"]) == NO) {
        instance.stationaryRadius = [config[@"stationaryRadius"] integerValue];
    }
    if (isNull(config[@"distanceFilter"]) == NO) {
        instance.distanceFilter = [config[@"distanceFilter"] integerValue];
    }
    if (isNull(config[@"desiredAccuracy"]) == NO) {
        instance.desiredAccuracy = [config[@"desiredAccuracy"] integerValue];
    }
    if (isNull(config[@"debug"]) == NO) {
        instance.isDebugging = [config[@"debug"] boolValue];
    }
    if (isNull(config[@"activityType"]) == NO) {
        instance.activityType = config[@"activityType"];
    }
    if (isNull(config[@"stopOnTerminate"]) == NO) {
        instance.stopOnTerminate = [config[@"stopOnTerminate"] boolValue];
    }
    if (isNull(config[@"url"]) == NO) {
        instance.url = config[@"url"];
    }
    if (isNull(config[@"syncUrl"]) == NO) {
        instance.syncUrl = config[@"syncUrl"];
    } else if (isNull(config[@"url"]) == NO) {
        instance.syncUrl = config[@"url"];
    }
    if (isNull(config[@"syncThreshold"]) == NO) {
        instance.syncThreshold = [config[@"syncThreshold"] integerValue];
    }
    if (isNull(config[@"httpHeaders"]) == NO) {
        instance.httpHeaders = config[@"httpHeaders"];
    }
    if (isNull(config[@"saveBatteryOnBackground"]) == NO) {
        instance.saveBatteryOnBackground = [config[@"saveBatteryOnBackground"] boolValue];
    }
    if (isNull(config[@"maxLocations"]) == NO) {
        instance.maxLocations = [config[@"maxLocations"] integerValue];
    }
    if (isNull(config[@"pauseLocationUpdates"]) == NO) {
        instance.pauseLocationUpdates = [config[@"pauseLocationUpdates"] boolValue];
    }
    if (isNull(config[@"locationProvider"]) == NO) {
        instance.locationProvider = [config[@"locationProvider"] integerValue];
    }

    return instance;
}

- (BOOL) hasUrl
{
    return (url != nil && url.length > 0);
}

- (BOOL) hasSyncUrl
{
    return (syncUrl != nil && syncUrl.length > 0);
}

- (CLActivityType) decodeActivityType
{
    if ([activityType caseInsensitiveCompare:@"AutomotiveNavigation"]) {
        return CLActivityTypeAutomotiveNavigation;
    }
    if ([activityType caseInsensitiveCompare:@"OtherNavigation"]) {
        return CLActivityTypeOtherNavigation;
    }
    if ([activityType caseInsensitiveCompare:@"Fitness"]) {
        return CLActivityTypeFitness;
    }

    return CLActivityTypeOther;
}

- (NSInteger) decodeDesiredAccuracy
{
    if (desiredAccuracy >= 1000) {
        return kCLLocationAccuracyKilometer;
    }
    if (desiredAccuracy >= 100) {
        return kCLLocationAccuracyHundredMeters;
    }
    if (desiredAccuracy >= 10) {
        return kCLLocationAccuracyNearestTenMeters;
    }
    if (desiredAccuracy >= 0) {
        return kCLLocationAccuracyBest;
    }

    return kCLLocationAccuracyHundredMeters;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"Config: distanceFilter=%ld stationaryRadius=%ld desiredAccuracy=%ld activityType=%@ isDebugging=%d stopOnTerminate=%d url=%@ httpHeaders=%@ pauseLocationUpdates=%d", (long)distanceFilter, (long)stationaryRadius, (long)desiredAccuracy, activityType, isDebugging, stopOnTerminate, url, httpHeaders, pauseLocationUpdates];
}


@end
