//
//  MAURBackgroundGeolocationFacade.h
//
//  Created by Marian Hello on 04/06/16.
//  Version 2.0.0
//
//  According to apache license
//
//  This is class is using code from christocracy cordova-plugin-background-geolocation plugin
//  https://github.com/christocracy/cordova-plugin-background-geolocation

#ifndef MAURBackgroundGeolocationFacade_h
#define MAURBackgroundGeolocationFacade_h

#import "MAURProviderDelegate.h"
#import "MAURLocation.h"
#import "MAURConfig.h"

@interface MAURBackgroundGeolocationFacade : NSObject

@property (weak, nonatomic) id<MAURProviderDelegate> delegate;

- (BOOL) configure:(MAURConfig*)config error:(NSError * __autoreleasing *)outError;
- (BOOL) start:(NSError * __autoreleasing *)outError;
- (BOOL) stop:(NSError * __autoreleasing *)outError;
- (BOOL) locationServicesEnabled;
- (MAURLocationAuthorizationStatus) authorizationStatus;
- (BOOL) isStarted;
- (void) showAppSettings;
- (void) showLocationSettings;
- (void) switchMode:(MAUROperationalMode)mode;
- (MAURLocation*)getStationaryLocation;
- (NSArray<MAURLocation*>*) getLocations;
- (NSArray<MAURLocation*>*) getValidLocations;
- (BOOL) deleteLocation:(NSNumber*)locationId error:(NSError * __autoreleasing *)outError;
- (BOOL) deleteAllLocations:(NSError * __autoreleasing *)outError;
- (MAURLocation*)getCurrentLocation:(int)timeout maximumAge:(long)maximumAge
                 enableHighAccuracy:(BOOL)enableHighAccuracy
                              error:(NSError * __autoreleasing *)outError;
- (MAURConfig*) getConfig;
- (NSArray*) getLogEntries:(NSInteger)limit;
- (NSArray*) getLogEntries:(NSInteger)limit fromLogEntryId:(NSInteger)entryId minLogLevelFromString:(NSString *)minLogLevel;
- (void) forceSync;
- (void) onAppTerminate;


/**
 * Sets a transform for each coordinate about to be committed (sent or saved for later sync).
 * You can use this for modifying the coordinates in any way.
 *
 * If the transform returns <code>nil</code>, it will prevent the location from being committed.
 * @param transform - the transform block
 */
+ (void) setLocationTransform:(MAURLocationTransform _Nullable)transform;
+ (MAURLocationTransform _Nullable) locationTransform;

@end

#endif /* MAURBackgroundGeolocationFacade_h */
