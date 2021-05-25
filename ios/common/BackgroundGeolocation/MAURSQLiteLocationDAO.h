//
//  MAURSQLiteLocationDAO.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 10/06/16.
//

#ifndef MAURSQLiteLocationDAO_h
#define MAURSQLiteLocationDAO_h

#import <Foundation/Foundation.h>
#import "MAURLocation.h"

@class Location;

@interface MAURSQLiteLocationDAO : NSObject

+ (instancetype) sharedInstance;
- (id) init NS_UNAVAILABLE;
- (NSArray<MAURLocation*>*) getAllLocations;
- (NSArray<MAURLocation*>*) getLocationsForSync;
- (NSArray<MAURLocation*>*) getValidLocations;
- (NSNumber*) getLocationsForSyncCount;
- (NSNumber*) persistLocation:(MAURLocation*)location;
- (NSNumber*) persistLocation:(MAURLocation*)location limitRows:(NSInteger)maxRows;
- (BOOL) deleteLocation:(NSNumber*)locationId error:(NSError * __autoreleasing *)outError;
- (BOOL) deleteAllLocations:(NSError * __autoreleasing *)outError;
- (BOOL) clearDatabase;
- (NSString*) getDatabaseName;
- (NSString*) getDatabasePath;

@end

#endif /* MAURSQLiteLocationDAO_h */
