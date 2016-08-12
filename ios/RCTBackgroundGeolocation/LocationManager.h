//
//  LocationManager.h
//
//  Created by Marian Hello on 04/06/16.
//  Version 2.0.0
//
//  According to apache license
//
//  This is class is using code from christocracy cordova-plugin-background-geolocation plugin
//  https://github.com/christocracy/cordova-plugin-background-geolocation


#import <CoreLocation/CoreLocation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Config.h"

enum BGAuthorizationStatus {
    NOT_DETERMINED = 0,
    ALLOWED,
    DENIED
};

enum BGOperationMode {
    BACKGROUND = 0,
    FOREGROUND = 1
};

typedef NSUInteger BGAuthorizationStatus;
typedef NSUInteger BGOperationMode;

@protocol LocationManagerDelegate <NSObject>

- (void) onAuthorizationChanged:(NSInteger)authStatus;
- (void) onLocationChanged:(NSMutableDictionary*)location;
- (void) onStationaryChanged:(NSMutableDictionary*)location;
- (void) onError:(NSError*)error;

@end

@interface LocationManager : NSObject

@property (weak, nonatomic) id<LocationManagerDelegate> delegate;

- (BOOL) configure:(Config*)config error:(NSError * __autoreleasing *)outError;
- (BOOL) start:(NSError * __autoreleasing *)outError;
- (BOOL) stop:(NSError * __autoreleasing *)outError;
- (BOOL) finish;
- (BOOL) isLocationEnabled;
- (void) showAppSettings;
- (void) showLocationSettings;
- (void) switchMode:(BGOperationMode)mode;
- (NSMutableDictionary*)getStationaryLocation;
- (NSArray<NSMutableDictionary*>*) getLocations;
- (NSArray<NSMutableDictionary*>*) getValidLocations;
- (BOOL) deleteLocation:(NSNumber*)locationId;
- (BOOL) deleteAllLocations;
- (void) onAppTerminate;

@end
