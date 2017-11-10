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

#import "AbstractLocationProvider.h"
#import "LocationDelegate.h"
#import "Config.h"

@interface BackgroundGeolocationFacade : NSObject

@property (weak, nonatomic) id<LocationDelegate> delegate;

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
- (BOOL) deleteLocation:(NSNumber*)locationId;
- (BOOL) deleteAllLocations;
- (Config*) getConfig;
- (void) onAppTerminate;

@end

#endif /* BackgroundGeolocationFacade_h */
