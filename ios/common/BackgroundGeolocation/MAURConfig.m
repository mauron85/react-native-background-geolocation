//
//  MAURConfig.m
//  BackgroundGeolocation
//
//  Created by Marian Hello on 11/06/16.
//

#import "MAURConfig.h"

#define isNull(value) (value == nil || value == (id)[NSNull null])
#define isNotNull(value) (value != nil && value != (id)[NSNull null])

@implementation MAURConfig 

@synthesize stationaryRadius, distanceFilter, desiredAccuracy, _debug, activityType, activitiesInterval, _stopOnTerminate, url, syncUrl, syncThreshold, httpHeaders, _saveBatteryOnBackground, maxLocations, _pauseLocationUpdates, locationProvider, _template;

-(instancetype) initWithDefaults {
    self = [super init];
    
    if (self == nil) {
        return self;
    }
    
    stationaryRadius = [NSNumber numberWithInt:50];
    distanceFilter = [NSNumber numberWithInt:500];
    desiredAccuracy = [NSNumber numberWithInt:100];
    _debug = [NSNumber numberWithBool:NO];
    activityType = @"OtherNavigation";
    activitiesInterval = [NSNumber numberWithInt:10000];
    _stopOnTerminate = [NSNumber numberWithBool:YES];
    _saveBatteryOnBackground = [NSNumber numberWithBool:NO];
    maxLocations = [NSNumber numberWithInt:10000];
    syncThreshold = [NSNumber numberWithInt:100];
    _pauseLocationUpdates = [NSNumber numberWithBool:NO];
    locationProvider = [NSNumber numberWithInt:DISTANCE_FILTER_PROVIDER];
//    template =
    
    return self;
}

+(instancetype) fromDictionary:(NSDictionary*)config
{
    MAURConfig *instance = [[MAURConfig alloc] init];

    if (isNotNull(config[@"stationaryRadius"])) {
        instance.stationaryRadius = config[@"stationaryRadius"];
    }
    if (isNotNull(config[@"distanceFilter"])) {
        instance.distanceFilter = config[@"distanceFilter"];
    }
    if (isNotNull(config[@"desiredAccuracy"])) {
        instance.desiredAccuracy = config[@"desiredAccuracy"];
    }
    if (isNotNull(config[@"debug"])) {
        instance._debug = config[@"debug"];
    }
    if (isNotNull(config[@"activityType"])) {
        instance.activityType = config[@"activityType"];
    }
    if (isNull(config[@"activitiesInterval"])) {
        instance.activitiesInterval = config[@"activitiesInterval"];
    }
    if (isNotNull(config[@"stopOnTerminate"])) {
        instance._stopOnTerminate = config[@"stopOnTerminate"];
    }
    if (config[@"url"] != nil) {
        instance.url = config[@"url"];
    }
    if (config[@"syncUrl"] != nil) {
        instance.syncUrl = config[@"syncUrl"];
    }
    if (isNotNull(config[@"syncThreshold"])) {
        instance.syncThreshold = config[@"syncThreshold"];
    }
    if (config[@"httpHeaders"] != nil) {
        instance.httpHeaders = config[@"httpHeaders"];
    }
    if (isNotNull(config[@"saveBatteryOnBackground"])) {
        instance._saveBatteryOnBackground = config[@"saveBatteryOnBackground"];
    }
    if (isNotNull(config[@"maxLocations"])) {
        instance.maxLocations = config[@"maxLocations"];
    }
    if (isNotNull(config[@"pauseLocationUpdates"])) {
        instance._pauseLocationUpdates = config[@"pauseLocationUpdates"];
    }
    if (isNotNull(config[@"locationProvider"])) {
        instance.locationProvider = config[@"locationProvider"];
    }
    if (config[@"postTemplate"] != nil) {
        instance._template = config[@"postTemplate"];
    }

    return instance;
}

+ (instancetype) merge:(MAURConfig*)config withConfig:(MAURConfig*)newConfig
{
    if (config == nil) {
        return newConfig;
    }

    if (newConfig == nil) {
        return config;
    }
    
    MAURConfig *merger= [config copy];

    if ([newConfig hasStationaryRadius]) {
        merger.stationaryRadius = newConfig.stationaryRadius;
    }
    if ([newConfig hasDistanceFilter]) {
        merger.distanceFilter = newConfig.distanceFilter;
    }
    if ([newConfig hasDesiredAccuracy]) {
        merger.desiredAccuracy = newConfig.desiredAccuracy;
    }
    if ([newConfig hasDebug]) {
        merger._debug = newConfig._debug;
    }
    if ([newConfig hasActivityType]) {
        merger.activityType = newConfig.activityType;
    }
    if ([newConfig hasActivitiesInterval]) {
        merger.activitiesInterval = newConfig.activitiesInterval;
    }
    if ([newConfig hasStopOnTerminate]) {
        merger._stopOnTerminate = newConfig._stopOnTerminate;
    }
    if ([newConfig hasUrl]) {
        merger.url = newConfig.url;
    }
    if ([newConfig hasSyncUrl]) {
        merger.syncUrl = newConfig.syncUrl;
    }
    if ([newConfig hasSyncThreshold]) {
        merger.syncThreshold = newConfig.syncThreshold;
    }
    if ([newConfig hasHttpHeaders]) {
        merger.httpHeaders = newConfig.httpHeaders;
    }
    if ([newConfig hasSaveBatteryOnBackground]) {
        merger._saveBatteryOnBackground = newConfig._saveBatteryOnBackground;
    }
    if ([newConfig hasMaxLocations]) {
        merger.maxLocations = newConfig.maxLocations;
    }
    if ([newConfig hasPauseLocationUpdates]) {
        merger._pauseLocationUpdates = newConfig._pauseLocationUpdates;
    }
    if ([newConfig hasLocationProvider]) {
        merger.locationProvider = newConfig.locationProvider;
    }
    if ([newConfig hasTemplate]) {
        merger._template = newConfig._template;
    }

    return merger;
}

-(id) copyWithZone: (NSZone *) zone
{
    MAURConfig *copy = [[[self class] allocWithZone: zone] init];
    if (copy) {
        copy.stationaryRadius = stationaryRadius;
        copy.distanceFilter = distanceFilter;
        copy.desiredAccuracy = desiredAccuracy;
        copy._debug = _debug;
        copy.activityType = activityType;
        copy.activitiesInterval = activitiesInterval;
        copy._stopOnTerminate = _stopOnTerminate;
        copy.url = url;
        copy.syncUrl = syncUrl;
        copy.syncThreshold = syncThreshold;
        copy.httpHeaders = httpHeaders;
        copy._saveBatteryOnBackground = _saveBatteryOnBackground;
        copy.maxLocations = maxLocations;
        copy._pauseLocationUpdates = _pauseLocationUpdates;
        copy.locationProvider = locationProvider;
        copy._template = _template;
    }
    
    return copy;
}

- (BOOL) hasStationaryRadius
{
    return stationaryRadius != nil;
}

- (BOOL) hasDistanceFilter
{
    return distanceFilter != nil;
}

- (BOOL) hasDesiredAccuracy
{
    return desiredAccuracy != nil;
}

- (BOOL) hasDebug
{
    return _debug != nil;
}

- (BOOL) hasActivityType
{
    return activityType != nil;
}

- (BOOL) hasActivitiesInterval
{
    return activitiesInterval != nil;
}

- (BOOL) hasStopOnTerminate
{
    return _stopOnTerminate != nil;
}

- (BOOL) hasUrl
{
    return url != nil;
}

- (BOOL) hasValidUrl
{
    return url != nil && url.length > 0;
}

- (void) setUrl:(NSString*)newUrl
{
    if (newUrl == (id)[NSNull null]) {
        url = @"";
    } else {
        url = newUrl;
    }
}

- (NSString*) url
{
    if (url == nil) {
        url = @"";
    }
    return url;
}

- (BOOL) hasSyncUrl
{
    return syncUrl != nil;
}

- (BOOL) hasValidSyncUrl
{
    return syncUrl != nil && syncUrl.length > 0;
}

- (void) setSyncUrl:(NSString*)newSyncUrl
{
    if (newSyncUrl == (id)[NSNull null]) {
        syncUrl = @"";
    } else {
        syncUrl = newSyncUrl;
    }
}

- (NSString*) syncUrl
{
    if (syncUrl == nil) {
        syncUrl = @"";
    }
    return syncUrl;
}

- (BOOL) hasSyncThreshold
{
    return syncThreshold != nil;
}

- (BOOL) hasHttpHeaders
{
    return httpHeaders != nil;
}

- (void) setHttpHeaders:(NSMutableDictionary *)newHttpHeaders
{
    if (newHttpHeaders == (id)[NSNull null]) {
        httpHeaders = [[NSMutableDictionary alloc] init];
    } else {
        httpHeaders = newHttpHeaders;
    }
}

- (NSMutableDictionary *) httpHeaders
{
    if (httpHeaders == nil) {
        httpHeaders = [[NSMutableDictionary alloc] init];
    }
    return httpHeaders;
}

- (BOOL) hasSaveBatteryOnBackground
{
    return _saveBatteryOnBackground != nil;
}

- (BOOL) hasMaxLocations
{
    return maxLocations != nil;
}

- (BOOL) hasPauseLocationUpdates
{
    return _pauseLocationUpdates != nil;
}

- (BOOL) hasLocationProvider
{
    return locationProvider != nil;
}

- (BOOL) hasTemplate
{
    return _template != nil;
}

- (void) set_template:(NSObject*)template
{
    if (template == (id)[NSNull null]) {
        _template = [MAURConfig getDefaultTemplate];
    } else {
        _template = template;
    }
}

- (NSObject*) _template{
    if (_template == nil) {
        _template = [MAURConfig getDefaultTemplate];
    }
    return _template;
}

- (BOOL) isDebugging
{
    return _debug.boolValue;
}

- (BOOL) stopOnTerminate
{
    return _stopOnTerminate.boolValue;
}

- (BOOL) saveBatteryOnBackground
{
    return _saveBatteryOnBackground.boolValue;
}

- (BOOL) pauseLocationUpdates
{
    return _pauseLocationUpdates.boolValue;
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
    NSInteger desiredAccuracy = self.desiredAccuracy.integerValue;

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

+ (NSDictionary*) getDefaultTemplate
{
    return @{
             @"time": @"@time",
             @"accuracy": @"@accuracy",
             @"altitudeAccuracy": @"@altitudeAccuracy",
             @"speed": @"@speed",
             @"bearing": @"@bearing",
             @"altitude": @"@altitude",
             @"latitude": @"@latitude",
             @"longitude": @"@longitude",
             @"provider": @"provider",
             @"locationProvider": @"@locationProvider",
             @"radius": @"@radius",
             };
}

- (NSString*) getHttpHeadersAsString:(NSError * __autoreleasing *)outError;
{
    NSError *error = nil;
    NSString *httpHeadersString;
    
    if ([self hasHttpHeaders]) {
        NSData *jsonHttpHeaders = [NSJSONSerialization dataWithJSONObject:httpHeaders options:NSJSONWritingPrettyPrinted error:&error];
        if (jsonHttpHeaders) {
            httpHeadersString = [[NSString alloc] initWithData:jsonHttpHeaders encoding:NSUTF8StringEncoding];
        } else {
            if (outError != nil) {
                NSLog(@"Http headers serialization error: %@", error);
                *outError = error;
            }
        }
    }

    return httpHeadersString;
}

- (NSString*) getTemplateAsString:(NSError * __autoreleasing *)outError;
{
    NSError *error = nil;
    NSString *templateAsString;

    if ([self hasTemplate]) {
        NSData *jsonTemplate = [NSJSONSerialization dataWithJSONObject:_template options:0 error:&error];
        if (jsonTemplate) {
            templateAsString = [[NSString alloc] initWithData:jsonTemplate encoding:NSUTF8StringEncoding];
        } else {
            if (outError != nil) {
                NSLog(@"Template serialization error: %@", error);
                *outError = error;
            }
        }
    }

    return templateAsString;
}

- (NSDictionary*) toDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
 
    if ([self hasActivityType]) [dict setObject:self.activityType forKey:@"activityType"];
    if ([self hasActivitiesInterval]) [dict setObject:self.activitiesInterval forKey:@"activitiesInterval"];
    if ([self hasUrl]) [dict setObject:self.url forKey:@"url"];
    if ([self hasSyncUrl]) [dict setObject:self.syncUrl forKey:@"syncUrl"];
    if ([self hasHttpHeaders]) [dict setObject:self.httpHeaders forKey:@"httpHeaders"];
    if ([self hasStationaryRadius]) [dict setObject:self.stationaryRadius forKey:@"stationaryRadius"];
    if ([self hasDistanceFilter]) [dict setObject:self.distanceFilter forKey:@"distanceFilter"];
    if ([self hasDesiredAccuracy]) [dict setObject:self.desiredAccuracy forKey:@"desiredAccuracy"];
    if ([self hasDebug]) [dict setObject:self._debug forKey:@"debug"];
    if ([self hasStopOnTerminate]) [dict setObject:self._stopOnTerminate forKey:@"stopOnTerminate"];
    if ([self hasSyncThreshold]) [dict setObject:self.syncThreshold forKey:@"syncThreshold"];
    if ([self hasSaveBatteryOnBackground]) [dict setObject:self._saveBatteryOnBackground forKey:@"saveBatteryOnBackground"];
    if ([self hasMaxLocations]) [dict setObject:self.maxLocations forKey:@"maxLocations"];
    if ([self hasPauseLocationUpdates]) [dict setObject:self._pauseLocationUpdates forKey:@"pauseLocationUpdates"];
    if ([self hasLocationProvider]) [dict setObject:self.locationProvider forKey:@"locationProvider"];
    [dict setObject:self._template forKey:@"postTemplate"];

    return dict;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"Config: distanceFilter=%@ stationaryRadius=%@ desiredAccuracy=%@ activityType=%@ activitiesInterval=%@ isDebugging=%@ stopOnTerminate=%@ url=%@ syncThreshold=%@ maxLocations=%@ httpHeaders=%@ pauseLocationUpdates=%@ saveBatteryOnBackground=%@ locationProvider=%@ postTemplate=%@", self.distanceFilter, self.stationaryRadius, self.desiredAccuracy, self.activityType, self.activitiesInterval, self._debug, self._stopOnTerminate, self.url, self.syncThreshold, self.maxLocations, self.httpHeaders, self._pauseLocationUpdates, self._saveBatteryOnBackground, self.locationProvider, self._template];

}

@end
