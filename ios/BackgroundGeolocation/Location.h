//
//  Location.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 10/06/16.
//

#ifndef Location_h
#define Location_h

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Location : NSObject <NSCopying>

@property (nonatomic, retain) NSNumber *locationId;
@property (nonatomic, retain) NSDate *time;
@property (nonatomic, retain) NSNumber *accuracy;
@property (nonatomic, retain) NSNumber *altitudeAccuracy;
@property (nonatomic, retain) NSNumber *speed;
@property (nonatomic, retain) NSNumber *heading;
@property (nonatomic, retain) NSNumber *altitude;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSString *provider;
@property (nonatomic, retain) NSNumber *locationProvider;
@property (nonatomic, retain) NSNumber *radius; //only for stationary locations
@property (nonatomic) BOOL isValid;
@property (nonatomic, retain) NSDate *recordedAt;

+ (instancetype) fromCLLocation:(CLLocation*)location;
+ (NSTimeInterval) locationAge:(CLLocation*)location;
+ (NSMutableDictionary*) toDictionary:(CLLocation*)location;
- (NSTimeInterval) locationAge;
- (NSDictionary*) toDictionary;
- (NSDictionary*) toDictionaryWithId;
- (id) toResultFromTemplate:(id)locationTemplate;
- (CLLocationCoordinate2D) coordinate;
- (BOOL) hasAccuracy;
- (BOOL) hasTime;
- (double) distanceFromLocation:(Location*)location;
- (BOOL) isBetterLocation:(Location*)location;
- (BOOL) isBeyond:(Location*)location radius:(NSInteger)radius;
- (BOOL) postAsJSON:(NSString*)url withTemplate:(id)locationTemplate withHttpHeaders:(NSMutableDictionary*)httpHeaders error:(NSError * __autoreleasing *)outError;
- (id) copyWithZone: (NSZone *)zone;

@end

#endif /* Location_h */
