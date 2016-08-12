//
//  SQLiteLocationDAO.m
//  CDVBackgroundGeolocation
//
//  Created by Marian Hello on 10/06/16.
//

#import "sqlite3.h"
#import <CoreLocation/CoreLocation.h>
#import "SQLiteHelper.h"
#import "GeolocationOpenHelper.h"
#import "SQLiteLocationDAO.h"
#import "LocationContract.h"

@implementation SQLiteLocationDAO {
    FMDatabaseQueue* queue;
    GeolocationOpenHelper *helper;
}

#pragma mark Singleton Methods

+ (instancetype) sharedInstance
{
    static SQLiteLocationDAO *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (id) init {
    if (self = [super init]) {
        helper = [[GeolocationOpenHelper alloc] init];
        queue = [helper getWritableDatabase];
    }
    return self;
}

- (NSArray<Location*>*) getValidLocations
{
    __block NSMutableArray* locations = [[NSMutableArray alloc] init];

    NSString *sql = @"SELECT "
    @LC_COLUMN_NAME_ID
    @COMMA_SEP @LC_COLUMN_NAME_TIME
    @COMMA_SEP @LC_COLUMN_NAME_ACCURACY
    @COMMA_SEP @LC_COLUMN_NAME_SPEED
    @COMMA_SEP @LC_COLUMN_NAME_BEARING
    @COMMA_SEP @LC_COLUMN_NAME_ALTITUDE
    @COMMA_SEP @LC_COLUMN_NAME_LATITUDE
    @COMMA_SEP @LC_COLUMN_NAME_LONGITUDE
    @COMMA_SEP @LC_COLUMN_NAME_PROVIDER
    @COMMA_SEP @LC_COLUMN_NAME_LOCATION_PROVIDER
    @" FROM " @LC_TABLE_NAME @" WHERE " @LC_COLUMN_NAME_VALID @" = 1 ORDER BY " @LC_COLUMN_NAME_TIME;
    
    [queue inDatabase:^(FMDatabase *database) {
        FMResultSet *rs = [database executeQuery:sql];
        while([rs next]) {
            Location *location = [[Location alloc] init];
            location.id = [NSNumber numberWithDouble:[rs doubleForColumnIndex:0]];
            NSTimeInterval timestamp = [rs doubleForColumnIndex:1];
            location.time = [NSDate dateWithTimeIntervalSince1970:timestamp];
            location.accuracy = [NSNumber numberWithDouble:[rs doubleForColumnIndex:2]];
            location.speed = [NSNumber numberWithDouble:[rs doubleForColumnIndex:3]];
            location.heading = [NSNumber numberWithDouble:[rs doubleForColumnIndex:4]];
            location.altitude = [NSNumber numberWithDouble:[rs doubleForColumnIndex:5]];
            location.latitude = [NSNumber numberWithDouble:[rs doubleForColumnIndex:6]];
            location.longitude = [NSNumber numberWithDouble:[rs doubleForColumnIndex:7]];
            location.provider = [rs stringForColumnIndex:8];
            location.serviceProvider = [NSNumber numberWithInt:[rs intForColumnIndex:9]];
            
            [locations addObject:location];
        }
        // TODO
        // NSLog(@"Retrieving locations failed code: %d: message: %s", sqlite3_errcode(database), sqlite3_errmsg(database));

        [rs close];
    }];
    
    return locations;
}

- (NSArray<Location*>*) getAllLocations
{
    __block NSMutableArray* locations = [[NSMutableArray alloc] init];
    
    NSString *sql = @"SELECT "
    @LC_COLUMN_NAME_ID
    @COMMA_SEP @LC_COLUMN_NAME_TIME
    @COMMA_SEP @LC_COLUMN_NAME_ACCURACY
    @COMMA_SEP @LC_COLUMN_NAME_SPEED
    @COMMA_SEP @LC_COLUMN_NAME_BEARING
    @COMMA_SEP @LC_COLUMN_NAME_ALTITUDE
    @COMMA_SEP @LC_COLUMN_NAME_LATITUDE
    @COMMA_SEP @LC_COLUMN_NAME_LONGITUDE
    @COMMA_SEP @LC_COLUMN_NAME_PROVIDER
    @COMMA_SEP @LC_COLUMN_NAME_LOCATION_PROVIDER
    @COMMA_SEP @LC_COLUMN_NAME_VALID
    @" FROM " @LC_TABLE_NAME @" ORDER BY " @LC_COLUMN_NAME_TIME;
    
    [queue inDatabase:^(FMDatabase *database) {
        FMResultSet *rs = [database executeQuery:sql];
        while([rs next]) {
            Location *location = [[Location alloc] init];
            location.id = [NSNumber numberWithDouble:[rs doubleForColumnIndex:0]];
            NSTimeInterval timestamp = [rs doubleForColumnIndex:1];
            location.time = [NSDate dateWithTimeIntervalSince1970:timestamp];
            location.accuracy = [NSNumber numberWithDouble:[rs doubleForColumnIndex:2]];
            location.speed = [NSNumber numberWithDouble:[rs doubleForColumnIndex:3]];
            location.heading = [NSNumber numberWithDouble:[rs doubleForColumnIndex:4]];
            location.altitude = [NSNumber numberWithDouble:[rs doubleForColumnIndex:5]];
            location.latitude = [NSNumber numberWithDouble:[rs doubleForColumnIndex:6]];
            location.longitude = [NSNumber numberWithDouble:[rs doubleForColumnIndex:7]];
            location.provider = [rs stringForColumnIndex:8];
            location.serviceProvider = [NSNumber numberWithInt:[rs intForColumnIndex:9]];
            location.isValid = [rs intForColumnIndex:10] == 1 ? YES : NO;
            
            [locations addObject:location];
        }
        // TODO
        // NSLog(@"Retrieving locations failed code: %d: message: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
        
        [rs close];
    }];
    
    return locations;
}

- (NSArray<Location*>*) getLocationsForSync
{
    __block NSMutableArray* locations = [[NSMutableArray alloc] init];
    
    [queue inTransaction:^(FMDatabase *database, BOOL *rollback) {
        NSString *sql = @"SELECT "
        @LC_COLUMN_NAME_ID
        @COMMA_SEP @LC_COLUMN_NAME_TIME
        @COMMA_SEP @LC_COLUMN_NAME_ACCURACY
        @COMMA_SEP @LC_COLUMN_NAME_SPEED
        @COMMA_SEP @LC_COLUMN_NAME_BEARING
        @COMMA_SEP @LC_COLUMN_NAME_ALTITUDE
        @COMMA_SEP @LC_COLUMN_NAME_LATITUDE
        @COMMA_SEP @LC_COLUMN_NAME_LONGITUDE
        @COMMA_SEP @LC_COLUMN_NAME_PROVIDER
        @COMMA_SEP @LC_COLUMN_NAME_LOCATION_PROVIDER
        @" FROM " @LC_TABLE_NAME @" WHERE " @LC_COLUMN_NAME_VALID @" = 1 ORDER BY " @LC_COLUMN_NAME_TIME;

        FMResultSet *rs = [database executeQuery:sql];
        while([rs next]) {
            Location *location = [[Location alloc] init];
            location.id = [NSNumber numberWithDouble:[rs doubleForColumnIndex:0]];
            NSTimeInterval timestamp = [rs doubleForColumnIndex:1];
            location.time = [NSDate dateWithTimeIntervalSince1970:timestamp];
            location.accuracy = [NSNumber numberWithDouble:[rs doubleForColumnIndex:2]];
            location.speed = [NSNumber numberWithDouble:[rs doubleForColumnIndex:3]];
            location.heading = [NSNumber numberWithDouble:[rs doubleForColumnIndex:4]];
            location.altitude = [NSNumber numberWithDouble:[rs doubleForColumnIndex:5]];
            location.latitude = [NSNumber numberWithDouble:[rs doubleForColumnIndex:6]];
            location.longitude = [NSNumber numberWithDouble:[rs doubleForColumnIndex:7]];
            location.provider = [rs stringForColumnIndex:8];
            location.serviceProvider = [NSNumber numberWithInt:[rs intForColumnIndex:9]];
            
            [locations addObject:location];
        }
        [rs close];

        sql = @"UPDATE " @LC_TABLE_NAME @" SET " @LC_COLUMN_NAME_VALID @" = 0";
        if (![database executeUpdate:sql]) {
            NSLog(@"Deleting all location failed code: %d: message: %@", [database lastErrorCode], [database lastErrorMessage]);
        }
    }];
    
    return locations;
    
}

- (NSNumber*) getLocationsCount
{
    __block NSNumber* rowCount = nil;

    [queue inTransaction:^(FMDatabase *database, BOOL *rollback) {
        NSString *sql = @"SELECT COUNT(*) FROM " @LC_TABLE_NAME @" WHERE " @LC_COLUMN_NAME_VALID @" = 1";
        
        FMResultSet *rs = [database executeQuery:sql];
        if ([rs next]) {
            rowCount = [NSNumber numberWithInt:[rs intForColumnIndex:0]];
        }
        [rs close];
    }];
    
    return rowCount;
}

- (NSNumber*) persistLocation:(Location*)location intoDatabase:(FMDatabase*)database
{
    NSNumber* locationId = nil;
    
    NSString *sql = @"INSERT INTO " @LC_TABLE_NAME @" ("
    @LC_COLUMN_NAME_TIME
    @COMMA_SEP @LC_COLUMN_NAME_ACCURACY
    @COMMA_SEP @LC_COLUMN_NAME_SPEED
    @COMMA_SEP @LC_COLUMN_NAME_BEARING
    @COMMA_SEP @LC_COLUMN_NAME_ALTITUDE
    @COMMA_SEP @LC_COLUMN_NAME_LATITUDE
    @COMMA_SEP @LC_COLUMN_NAME_LONGITUDE
    @COMMA_SEP @LC_COLUMN_NAME_PROVIDER
    @COMMA_SEP @LC_COLUMN_NAME_LOCATION_PROVIDER
    @COMMA_SEP @LC_COLUMN_NAME_VALID
    @") VALUES (?,?,?,?,?,?,?,?,?,?)";
    
    BOOL success = [database executeUpdate:sql,
        [NSNumber numberWithDouble:[location.time timeIntervalSince1970]],
        location.accuracy,
        location.speed,
        location.heading,
        location.altitude,
        location.latitude,
        location.longitude,
        location.provider ?: [NSNull null],
        location.serviceProvider ?: [NSNull null],
        location.isValid == YES ? @(1) : @(0)
    ];
    
    if (success) {
        locationId = [NSNumber numberWithLongLong:[database lastInsertRowId]];
    } else {
        NSLog(@"Inserting location %@ failed code: %d: message: %@", location.time, [database lastErrorCode], [database lastErrorMessage]);
    }
    
    return locationId;
}

- (NSNumber*) persistLocation:(Location*)location
{
    __block NSNumber* locationId = nil;
    
    [queue inDatabase:^(FMDatabase *database) {
        locationId = [self persistLocation:location intoDatabase:database];
    }];
    
    return locationId;
}

- (NSNumber*) persistLocation:(Location*)location limitRows:(NSInteger)maxRows
{
    __block NSNumber *locationId;
    
    [queue inDatabase:^(FMDatabase *database) {
        NSInteger rowCount = 0;
        NSString *sql = @"SELECT COUNT(*) FROM " @LC_TABLE_NAME;

        FMResultSet *rs = [database executeQuery:sql];
        if ([rs next]) {
            rowCount = [rs intForColumnIndex:0];
        }
        [rs close];
        
        if (rowCount < maxRows) {
            locationId = [self persistLocation:location intoDatabase:database];
            return;
        } else if (rowCount > maxRows) {
            sql = [NSString stringWithFormat:@"DELETE FROM %1$@ WHERE %2$@ IN (SELECT %2$@ FROM %1$@ ORDER BY %3$@ LIMIT %4$ld);VACUUM;",
                   @LC_TABLE_NAME, @LC_COLUMN_NAME_ID, @LC_COLUMN_NAME_TIME, (rowCount - maxRows)];
            if (![database executeStatements:sql]) {
                NSLog(@"%@ failed code: %d: message: %@", sql, [database lastErrorCode], [database lastErrorMessage]);
            }
        }

        sql = @"UPDATE " @LC_TABLE_NAME @" SET "
        @LC_COLUMN_NAME_TIME @EQ_BIND
        @COMMA_SEP @LC_COLUMN_NAME_ACCURACY @EQ_BIND
        @COMMA_SEP @LC_COLUMN_NAME_SPEED @EQ_BIND
        @COMMA_SEP @LC_COLUMN_NAME_BEARING @EQ_BIND
        @COMMA_SEP @LC_COLUMN_NAME_ALTITUDE @EQ_BIND
        @COMMA_SEP @LC_COLUMN_NAME_LATITUDE @EQ_BIND
        @COMMA_SEP @LC_COLUMN_NAME_LONGITUDE @EQ_BIND
        @COMMA_SEP @LC_COLUMN_NAME_PROVIDER @EQ_BIND
        @COMMA_SEP @LC_COLUMN_NAME_LOCATION_PROVIDER @EQ_BIND
        @COMMA_SEP @LC_COLUMN_NAME_VALID @EQ_BIND
        @" WHERE " @LC_COLUMN_NAME_TIME @" = (SELECT min(" @LC_COLUMN_NAME_TIME @") FROM " @LC_TABLE_NAME @")";

        BOOL success = [database executeUpdate:sql,
            [NSNumber numberWithDouble:[location.time timeIntervalSince1970]],
            location.accuracy,
            location.speed,
            location.heading,
            location.altitude,
            location.latitude,
            location.longitude,
            location.provider ?: [NSNull null],
            location.serviceProvider ?: [NSNull null],
            location.isValid == YES ? @(1) : @(0)
        ];
        
        if (success) {
            locationId = [NSNumber numberWithLongLong:[database lastInsertRowId]];
        } else {
            NSLog(@"Inserting location %@ failed code: %d: message: %@", location.time, [database lastErrorCode], [database lastErrorMessage]);
        }

    }];
    
    return locationId;
}

- (BOOL) deleteLocation:(NSNumber*)locationId
{
    __block BOOL success;
    NSString *sql = @"UPDATE " @LC_TABLE_NAME @" SET " @LC_COLUMN_NAME_VALID @" = 0 WHERE " @LC_COLUMN_NAME_ID @" = ?";
    
    [queue inDatabase:^(FMDatabase *database) {
        if (![database executeUpdate:sql, locationId]) {
            NSLog(@"Delete location %@ failed code: %d: message: %@", locationId, [database lastErrorCode], [database lastErrorMessage]);
            success = NO;
        }
        
        success = YES;
    }];
    
    return success;
}

- (BOOL) deleteAllLocations
{
    __block BOOL success;
    NSString *sql = @"UPDATE " @LC_TABLE_NAME @" SET " @LC_COLUMN_NAME_VALID @" = 0";
    
    [queue inDatabase:^(FMDatabase *database) {
        if ([database executeUpdate:sql]) {
            success = YES;
        } else {
            NSLog(@"Deleting all location failed code: %d: message: %@", [database lastErrorCode], [database lastErrorMessage]);
            success = NO;
        }
    }];

    return success;
}

- (BOOL) clearDatabase
{
    __block BOOL success;
    
    [queue inDatabase:^(FMDatabase *database) {
        NSString *sql = [NSString stringWithFormat: @"DROP TABLE %@", @LC_TABLE_NAME];
        if (![database executeStatements:sql]) {
            NSLog(@"%@ failed code: %d: message: %@", sql, [database lastErrorCode], [database lastErrorMessage]);
        }
        sql = [LocationContract createTableSQL];
        if (![database executeStatements:sql]) {
            NSLog(@"%@ failed code: %d: message: %@", sql, [database lastErrorCode], [database lastErrorMessage]);
            success = NO;
        }
        success = YES;
    }];
    
    return success;
}

- (NSString*) getDatabaseName
{
    return [helper getDatabaseName];
}

- (NSString*) getDatabasePath
{
    return [helper getDatabasePath];
}

- (void) dealloc {
    [helper close];
    [queue close];
    helper = nil;
    queue = nil;
}

@end
