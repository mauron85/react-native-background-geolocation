//
//  SQLiteLocationDAO.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 10/06/16.
//

#ifndef SQLiteLocationDAO_h
#define SQLiteLocationDAO_h

#import <Foundation/Foundation.h>
#import "Location.h"

@class Location;

@interface SQLiteLocationDAO : NSObject

+ (instancetype) sharedInstance;
- (id) init NS_UNAVAILABLE;
- (NSArray<Location*>*) getAllLocations;
- (NSArray<Location*>*) getLocationsForSync;
- (NSArray<Location*>*) getValidLocations;
- (NSNumber*) getLocationsCount;
- (NSNumber*) persistLocation:(Location*)location;
- (NSNumber*) persistLocation:(Location*)location limitRows:(NSInteger)maxRows;
- (BOOL) deleteLocation:(NSNumber*)locationId error:(NSError * __autoreleasing *)outError;
- (BOOL) deleteAllLocations:(NSError * __autoreleasing *)outError;
- (BOOL) clearDatabase;
- (NSString*) getDatabaseName;
- (NSString*) getDatabasePath;

@end

#endif /* SQLiteLocationDAO_h */
