//
//  MAURLocation.m
//  BackgroundGeolocation
//
//  Created by Marian Hello on 10/06/16.
//

#import <Foundation/Foundation.h>
#import "MAURLocation.h"

enum {
    TWO_MINUTES = 120,
    MAX_SECONDS_FROM_NOW = 86400
};

@interface MAURLocationMapper : NSObject
- (NSDictionary*) withDictionary:(NSDictionary*)values;
- (NSArray*) withArray:(NSArray*)values;
+ (instancetype) map:(MAURLocation*)location;
@end

@implementation MAURLocationMapper
MAURLocation* _location;

- (id) mapValue:(id)value
{
    if ([value isKindOfClass:[NSString class]]) {
        id locationValue = [_location getValueForKey:value];
        return locationValue != nil ? locationValue : value;
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        return [self withDictionary:value];
    } else if ([value isKindOfClass:[NSArray class]]) {
        return [self withArray:value];
    }

    return value;
}

- (NSDictionary*) withDictionary:(NSDictionary*)values
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:values.count];

    for (id key in values) {
        id value = [values objectForKey:key];
        [dict setObject:[self mapValue:value] forKey:key];
    }

    return dict;
}

- (NSArray*) withArray:(NSArray*)values
{
    NSMutableArray *locationArray = [[NSMutableArray alloc] initWithCapacity:values.count];

    for (id value in values) {
        [locationArray addObject:[self mapValue:value]];
    }

    return locationArray;
}

+ (instancetype) map:(MAURLocation*)location
{
    MAURLocationMapper *instance = [[MAURLocationMapper alloc] init];
    _location = location;
    return instance;
}
@end


@implementation MAURLocation

@synthesize locationId, time, accuracy, altitudeAccuracy, speed, heading, altitude, latitude, longitude, provider, locationProvider, radius, isValid, recordedAt;

+ (instancetype) fromCLLocation:(CLLocation*)location;
{
    MAURLocation *instance = [[MAURLocation alloc] init];

    instance.time = location.timestamp;
    instance.accuracy = [NSNumber numberWithDouble:location.horizontalAccuracy];
    instance.altitudeAccuracy = [NSNumber numberWithDouble:location.verticalAccuracy];
    instance.speed = [NSNumber numberWithDouble:location.speed];
    instance.heading = [NSNumber numberWithDouble:location.course]; // will be deprecated
    instance.altitude = [NSNumber numberWithDouble:location.altitude];
    instance.latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
    instance.longitude = [NSNumber numberWithDouble:location.coordinate.longitude];

    return instance;
}

+ (NSTimeInterval) locationAge:(CLLocation*)location
{
    return -[location.timestamp timeIntervalSinceNow];
}

+ (NSDictionary*) toDictionary:(CLLocation*)location;
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];

    NSNumber* timestamp = [NSNumber numberWithDouble:([location.timestamp timeIntervalSince1970] * 1000)];
    [dict setObject:timestamp forKey:@"time"];
    [dict setObject:[NSNumber numberWithDouble:location.horizontalAccuracy] forKey:@"accuracy"];
    [dict setObject:[NSNumber numberWithDouble:location.verticalAccuracy] forKey:@"altitudeAccuracy"];
    [dict setObject:[NSNumber numberWithDouble:location.speed] forKey:@"speed"];
    [dict setObject:[NSNumber numberWithDouble:location.course] forKey:@"heading"];
    [dict setObject:[NSNumber numberWithDouble:location.course] forKey:@"bearing"];
    [dict setObject:[NSNumber numberWithDouble:location.altitude] forKey:@"altitude"];
    [dict setObject:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"latitude"];
    [dict setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"longitude"];

    return dict;
}

- (instancetype) init
{
    self = [super init];
    if (self != nil) {
        [self commonInit];
    }

    return self;
}

- (void) commonInit
{
    isValid = true;
}

/*
 * Age of location measured from now in seconds
 *
 */
- (NSTimeInterval) locationAge
{
    return -[time timeIntervalSinceNow];
}

- (NSDictionary*) toDictionaryWithId
{
    NSMutableDictionary *dict = (NSMutableDictionary*)[self toDictionary];

    // locationId is solely for internal purposes like deleteLocation method!!!
    if (locationId != nil) [dict setObject:locationId forKey:@"id"];

    return dict;
}

- (NSMutableDictionary*) toDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:13];

    if (time != nil) [dict setObject:[NSNumber numberWithDouble:([time timeIntervalSince1970] * 1000)] forKey:@"time"];
    if (accuracy != nil) [dict setObject:accuracy forKey:@"accuracy"];
    if (altitudeAccuracy != nil) [dict setObject:altitudeAccuracy forKey:@"altitudeAccuracy"];
    if (speed != nil) [dict setObject:speed forKey:@"speed"];
    if (heading != nil) [dict setObject:heading forKey:@"heading"]; // @deprecated
    if (heading != nil) [dict setObject:heading forKey:@"bearing"];
    if (altitude != nil) [dict setObject:altitude forKey:@"altitude"];
    if (latitude != nil) [dict setObject:latitude forKey:@"latitude"];
    if (longitude != nil) [dict setObject:longitude forKey:@"longitude"];
    if (provider != nil) [dict setObject:provider forKey:@"provider"];
    if (locationProvider != nil) [dict setObject:locationProvider forKey:@"locationProvider"];
    if (radius != nil) [dict setObject:radius forKey:@"radius"];
    if (recordedAt != nil) [dict setObject:[NSNumber numberWithDouble:([recordedAt timeIntervalSince1970] * 1000)] forKey:@"recordedAt"];

    return dict;
}

- (id) getValueForKey:(id)key
{
    if (key == nil || ![key isKindOfClass:[NSString class]]) {
        return nil;
    }

    if ([key isEqualToString:@"@id"]) {
        return locationId;
    }
    if ([key isEqualToString:@"@time"]) {
        return [NSNumber numberWithDouble:([time timeIntervalSince1970] * 1000)];
    }
    if ([key isEqualToString:@"@accuracy"]) {
        return accuracy;
    }
    if ([key isEqualToString:@"@altitudeAccuracy"]) {
        return altitudeAccuracy;
    }
    if ([key isEqualToString:@"@speed"]) {
        return speed;
    }
    if ([key isEqualToString:@"@heading"]) {
        return heading;
    }
    if ([key isEqualToString:@"@bearing"]) {
        return heading;
    }
    if ([key isEqualToString:@"@altitude"]) {
        return altitude;
    }
    if ([key isEqualToString:@"@latitude"]) {
        return latitude;
    }
    if ([key isEqualToString:@"@longitude"]) {
        return longitude;
    }
    if ([key isEqualToString:@"@provider"]) {
        return provider;
    }
    if ([key isEqualToString:@"@locationProvider"]) {
        return locationProvider;
    }
    if ([key isEqualToString:@"@radius"]) {
        return radius;
    }
    if ([key isEqualToString:@"@recordedAt"]) {
        return [NSNumber numberWithDouble:([recordedAt timeIntervalSince1970] * 1000)];
    }
    
    return nil;
}

- (id) toResultFromTemplate:(id)locationTemplate
{
    if ([locationTemplate isKindOfClass:[NSArray class]]) {
        MAURLocationMapper *mapper = [MAURLocationMapper map:self];
        return [mapper withArray:locationTemplate];
    } else if ([locationTemplate isKindOfClass:[NSDictionary class]]) {
        MAURLocationMapper *mapper = [MAURLocationMapper map:self];
        return [mapper withDictionary:locationTemplate];
    }
    
    return [self toDictionary];
}

- (CLLocationCoordinate2D) coordinate
{
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [latitude doubleValue];
    coordinate.longitude = [longitude doubleValue];
    return coordinate;
}

- (double) distanceFromLocation:(MAURLocation*)location
{
    const float EarthRadius = 6378137.0f;
    double a_lat = [self.latitude doubleValue];
    double a_lon = [self.longitude doubleValue];
    double b_lat = [location.latitude doubleValue];
    double b_lon = [location.longitude doubleValue];
    double dtheta = (a_lat - b_lat) * (M_PI / 180.0);
    double dlambda = (a_lon - b_lon) * (M_PI / 180.0);
    double mean_t = (a_lat + b_lat) * (M_PI / 180.0) / 2.0;
    double cos_meant = cosf(mean_t);

    return sqrtf((EarthRadius * EarthRadius) * (dtheta * dtheta + cos_meant * cos_meant * dlambda * dlambda));
}

/**
 * Determines whether instance is better then Location reading
 * @param location  The new Location that you want to evaluate
 * Note: code taken from https://developer.android.com/guide/topics/location/strategies.html
 */
- (BOOL) isBetterLocation:(MAURLocation*)location
{
    if (location == nil) {
        // A instance location is always better than no location
        return NO;
    }

    // Check whether the new location fix is newer or older
    NSTimeInterval timeDelta = [self.time timeIntervalSinceDate:location.time];
    BOOL isSignificantlyNewer = timeDelta > TWO_MINUTES;
    BOOL isSignificantlyOlder = timeDelta < -TWO_MINUTES;
    BOOL isNewer = timeDelta > 0;

    // If it's been more than two minutes since the current location, use the new location
    // because the user has likely moved
    if (isSignificantlyNewer) {
        return YES;
        // If the new location is more than two minutes older, it must be worse
    } else if (isSignificantlyOlder) {
        return NO;
    }

    // Check whether the new location fix is more or less accurate
    NSInteger accuracyDelta = [self.accuracy integerValue] - [location.accuracy integerValue];
    BOOL isLessAccurate = accuracyDelta > 0;
    BOOL isMoreAccurate = accuracyDelta < 0;
    BOOL isSignificantlyLessAccurate = accuracyDelta > 200;

    // Check if the old and new location are from the same provider
    BOOL isFromSameProvider = YES; //TODO: check

    // Determine location quality using a combination of timeliness and accuracy
    if (isMoreAccurate) {
        return YES;
    } else if (isNewer && !isLessAccurate) {
        return YES;
    } else if (isNewer && !isSignificantlyLessAccurate && isFromSameProvider) {
        return YES;
    }

    return NO;
}

- (BOOL) isBeyond:(MAURLocation*)location radius:(NSInteger)definedRadius
{
    double pointDistance = [self distanceFromLocation:location];
    return (pointDistance - [self.accuracy doubleValue] - [location.accuracy doubleValue]) > definedRadius;
}

- (BOOL) hasAccuracy
{
    if (accuracy == nil || accuracy < 0) return NO;
    return YES;
}

- (BOOL) hasTime
{
    if (time != nil && [time timeIntervalSinceNow] > MAX_SECONDS_FROM_NOW) return NO;
    return YES;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"Location: id=%@ time=%@ lat=%@ lon=%@ accu=%@ aaccu=%@ speed=%@ bear=%@ alt=%@", locationId, time, latitude, longitude, accuracy, altitudeAccuracy, speed, heading, altitude];
}

-(id) copyWithZone: (NSZone *) zone
{
    MAURLocation *copy = [[[self class] allocWithZone: zone] init];
    if (copy) {
        copy.time = time;
        copy.accuracy = accuracy;
        copy.altitudeAccuracy = altitudeAccuracy;
        copy.speed = speed;
        copy.heading = heading;
        copy.altitude = altitude;
        copy.latitude = latitude;
        copy.longitude = longitude;
        copy.provider = provider;
        copy.locationProvider = locationProvider;
        copy.radius = radius;
        copy.isValid = isValid;
    }

    return copy;
}

@end
