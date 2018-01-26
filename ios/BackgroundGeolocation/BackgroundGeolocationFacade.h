//
//  BackgroundGeolocationFacade.h
//
//  Created by Marian Hello on 04/06/16.
//  Version 2.0.0
//
//  According to apache license
//
//  This is class is using code from christocracy cordova-plugin-background-geolocation plugin
//  https://github.com/christocracy/cordova-plugin-background-geolocation

#ifndef BackgroundGeolocationFacade_h
#define BackgroundGeolocationFacade_h

#import "ProviderDelegate.h"
#import "Location.h"
#import "Config.h"

typedef NS_ENUM(NSInteger, BGOperationMode) {
    BACKGROUND = 0,
    FOREGROUND = 1
};

@interface BackgroundGeolocationFacade : NSObject

@property (weak, nonatomic) id<ProviderDelegate> delegate;

- (BOOL) configure:(Config*)config error:(NSError * __autoreleasing *)outError;
- (BOOL) start:(NSError * __autoreleasing *)outError;
- (BOOL) stop:(NSError * __autoreleasing *)outError;
- (BOOL) isLocationEnabled;
- (BOOL) isStarted;
- (void) showAppSettings;
- (void) showLocationSettings;
- (void) switchMode:(BGOperationMode)mode;
- (Location*)getStationaryLocation;
- (NSArray<Location*>*) getLocations;
- (NSArray<Location*>*) getValidLocations;
- (BOOL) deleteLocation:(NSNumber*)locationId error:(NSError * __autoreleasing *)outError;
- (BOOL) deleteAllLocations:(NSError * __autoreleasing *)outError;
- (Config*) getConfig;
- (NSArray*) getLogEntries:(NSInteger)limit;
- (void) onAppTerminate;

@end

#endif /* BackgroundGeolocationFacade_h */
