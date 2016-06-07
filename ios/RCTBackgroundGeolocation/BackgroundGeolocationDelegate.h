//
//  BackgroundGeolocationDelegate.h
//  RCTBackgroundGeolocation
//
//  Created by Marian Hello on 04/06/16.
//  According to apache license
//
//  This is class is using code from christocracy cordova-plugin-background-geolocation plugin
//  https://github.com/christocracy/cordova-plugin-background-geolocation


#import <CoreLocation/CoreLocation.h>
#import <AudioToolbox/AudioToolbox.h>

enum BGLocationStatus {
    PERMISSIONDENIED = 1,
    POSITIONUNAVAILABLE,
    TIMEOUT
};
typedef NSUInteger BGLocationStatus;

@interface BackgroundGeolocationDelegate : NSObject

//@property (nonatomic, strong) NSString* syncCallbackId;
@property (nonatomic, strong) NSMutableArray* stationaryRegionListeners;

@property (copy) void (^onLocationChanged) (NSMutableDictionary *location);

- (void) configure:(NSDictionary*)config;
- (void) start;
- (void) stop;
- (void) finish;
- (void) onPaceChange:(BOOL)moving;
- (void) setConfig:(NSDictionary*)config;
// - (void) addStationaryRegionListener:(CDVInvokedUrlCommand*)command;
// - (void) getStationaryLocation:(CDVInvokedUrlCommand *)command;
- (BOOL) isLocationEnabled;
- (void) showAppSettings;
- (void) showLocationSettings;
// - (void) watchLocationMode:(CDVInvokedUrlCommand*)command;
// - (void) stopWatchingLocationMode:(CDVInvokedUrlCommand*)command;
//- (void) getLocations;
//- (void) deleteLocation:(int)command;
//- (void) deleteAllLocations:()command;
-(NSMutableDictionary*) locationToHash:(CLLocation*)location;

@end
