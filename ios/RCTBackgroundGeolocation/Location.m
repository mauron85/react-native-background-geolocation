//
//  Location.m
//  CDVBackgroundGeolocation
//
//  Created by Marian Hello on 10/06/16.
//

#import <Foundation/Foundation.h>
#import "Location.h"

enum {
    TWO_MINUTES = 120,
    MAX_SECONDS_FROM_NOW = 86400
};

@implementation Location

@synthesize id, time, accuracy, altitudeAccuracy, speed, heading, altitude, latitude, longitude, provider, serviceProvider, type, isValid;

+ (instancetype) fromCLLocation:(CLLocation*)location;
{
    Location *instance = [[Location alloc] init];
    
    instance.time = location.timestamp;
    instance.accuracy = [NSNumber numberWithDouble:location.horizontalAccuracy];
    instance.altitudeAccuracy = [NSNumber numberWithDouble:location.verticalAccuracy];
    instance.speed = [NSNumber numberWithDouble:location.speed];
    instance.heading = [NSNumber numberWithDouble:location.course];
    instance.altitude = [NSNumber numberWithDouble:location.altitude];
    instance.latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
    instance.longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
    
    return instance;
}

+ (NSTimeInterval) locationAge:(CLLocation*)location
{
    return -[location.timestamp timeIntervalSinceNow];    
}

+ (NSMutableDictionary*) toDictionary:(CLLocation*)location;
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
    
    NSNumber* timestamp = [NSNumber numberWithDouble:([location.timestamp timeIntervalSince1970] * 1000)];
    [dict setObject:timestamp forKey:@"time"];
    [dict setObject:[NSNumber numberWithDouble:location.horizontalAccuracy] forKey:@"accuracy"];
    [dict setObject:[NSNumber numberWithDouble:location.verticalAccuracy] forKey:@"altitudeAccuracy"];
    [dict setObject:[NSNumber numberWithDouble:location.speed] forKey:@"speed"];
    [dict setObject:[NSNumber numberWithDouble:location.course] forKey:@"heading"];
    [dict setObject:[NSNumber numberWithDouble:location.altitude] forKey:@"altitude"];
    [dict setObject:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"latitude"];
    [dict setObject:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"longitude"];
    
    return dict;
}

- (id) init
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

- (NSMutableDictionary*) toDictionaryWithId
{
    NSMutableDictionary *dict = [self toDictionary];

    // id is solely for internal purposes like deleteLocation method!!!
    if (id != nil) [dict setObject:id forKey:@"id"];
    
    return dict;
}

- (NSMutableDictionary*) toDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
    
    if (time != nil) [dict setObject:[NSNumber numberWithDouble:([time timeIntervalSince1970] * 1000)] forKey:@"time"];
    if (accuracy != nil) [dict setObject:accuracy forKey:@"accuracy"];
    if (altitudeAccuracy != nil) [dict setObject:altitudeAccuracy forKey:@"altitudeAccuracy"];
    if (speed != nil) [dict setObject:speed forKey:@"speed"];
    if (heading != nil) [dict setObject:heading forKey:@"heading"];
    if (altitude != nil) [dict setObject:altitude forKey:@"altitude"];
    if (latitude != nil) [dict setObject:latitude forKey:@"latitude"];
    if (longitude != nil) [dict setObject:longitude forKey:@"longitude"];
    if (provider != nil) [dict setObject:provider forKey:@"provider"];
    if (serviceProvider != nil) [dict setObject:serviceProvider forKey:@"service_provider"];
    if (type != nil) [dict setObject:type forKey:@"location_type"];
    
    return dict;
}

- (CLLocationCoordinate2D) coordinate
{
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [latitude doubleValue];
    coordinate.longitude = [longitude doubleValue];
    return coordinate;
}

- (double) distanceFromLocation:(Location*)location
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
- (BOOL) isBetterLocation:(Location*)location
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

- (BOOL) isBeyond:(Location*)location radius:(NSInteger)radius
{
    double pointDistance = [self distanceFromLocation:location];
    return (pointDistance - [self.accuracy doubleValue] - [location.accuracy doubleValue]) > radius;
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
    return [NSString stringWithFormat:@"Location: id=%ld time=%ld lat=%@ lon=%@ accu=%@ aaccu=%@ speed=%@ head=%@ alt=%@ type=%@", (long)id, (long)time, latitude, longitude, accuracy, altitudeAccuracy, speed, heading, altitude, type];
}

- (BOOL) postAsJSON:(NSString*)url withHttpHeaders:(NSMutableDictionary*)httpHeaders error:(NSError * __autoreleasing *)outError;
{
    NSArray *locations = [[NSArray alloc] initWithObjects:[self toDictionary], nil];
    //    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];
    NSData *data = [NSJSONSerialization dataWithJSONObject:locations options:0 error:outError];
    if (!data) {
        return NO;
    }
    
    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    if (httpHeaders != nil) {
        for(id key in httpHeaders) {
            id value = [httpHeaders objectForKey:key];
            [request addValue:value forHTTPHeaderField:key];
        }
    }
    [request setHTTPBody:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Create url connection and fire request
    NSHTTPURLResponse* urlResponse = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:outError];
    
    if (*outError == nil && [urlResponse statusCode] == 200) {
        return YES;
    }
    
    return NO;    
}

-(id) copyWithZone: (NSZone *) zone
{
    Location *copy = [[[self class] allocWithZone: zone] init];
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
        copy.serviceProvider = serviceProvider;
        copy.type = type;
        copy.isValid = isValid;
    }
    
    return copy;
}

@end