//
//  MAURSQLiteConfigurationDAO.m
//  BackgroundGeolocation
//
//  Created by Marian Hello on 01/12/2017.
//  Copyright © 2017 mauron85. All rights reserved.
//

#import "sqlite3.h"
#import <CoreLocation/CoreLocation.h>
#import "MAURSQLiteHelper.h"
#import "MAURGeolocationOpenHelper.h"
#import "MAURSQLiteConfigurationDAO.h"
#import "MAURConfigurationContract.h"
#import "MAURConfig.h"

@implementation MAURSQLiteConfigurationDAO {
    FMDatabaseQueue* queue;
    MAURGeolocationOpenHelper *helper;
}

#pragma mark Singleton Methods

+ (instancetype) sharedInstance
{
    static MAURSQLiteConfigurationDAO *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (id) init {
    if (self = [super init]) {
        helper = [[MAURGeolocationOpenHelper alloc] init];
        queue = [helper getWritableDatabase];
    }
    return self;
}

- (BOOL) persistConfiguration:(MAURConfig*)config
{
    __block BOOL success = NO;

    NSError *error = nil;
    
    NSString *httpHeadersString = [config getHttpHeadersAsString:&error];
    if (error != nil) {
        NSLog(@"Http headers serialization error: %@", error);
        return false;
    }

    NSString *templateString = [config getTemplateAsString:&error];
    if (error != nil) {
        NSLog(@"Template serialization error: %@", error);
        return false;
    }
   
    NSString *sql = @"INSERT OR REPLACE INTO " @CC_TABLE_NAME @" ("
        @CC_COLUMN_NAME_ID
        @COMMA_SEP @CC_COLUMN_NAME_RADIUS
        @COMMA_SEP @CC_COLUMN_NAME_DISTANCE_FILTER
        @COMMA_SEP @CC_COLUMN_NAME_DESIRED_ACCURACY
        @COMMA_SEP @CC_COLUMN_NAME_DEBUG
        @COMMA_SEP @CC_COLUMN_NAME_ACTIVITY_TYPE
        @COMMA_SEP @CC_COLUMN_NAME_NOTIF_TITLE
        @COMMA_SEP @CC_COLUMN_NAME_NOTIF_TEXT
        @COMMA_SEP @CC_COLUMN_NAME_NOTIF_ICON_LARGE
        @COMMA_SEP @CC_COLUMN_NAME_NOTIF_ICON_SMALL
        @COMMA_SEP @CC_COLUMN_NAME_NOTIF_COLOR
        @COMMA_SEP @CC_COLUMN_NAME_STOP_TERMINATE
        @COMMA_SEP @CC_COLUMN_NAME_START_BOOT
        @COMMA_SEP @CC_COLUMN_NAME_START_FOREGROUND
        @COMMA_SEP @CC_COLUMN_NAME_STOP_ON_STILL
        @COMMA_SEP @CC_COLUMN_NAME_LOCATION_PROVIDER
        @COMMA_SEP @CC_COLUMN_NAME_INTERVAL
        @COMMA_SEP @CC_COLUMN_NAME_FASTEST_INTERVAL
        @COMMA_SEP @CC_COLUMN_NAME_ACTIVITIES_INTERVAL
        @COMMA_SEP @CC_COLUMN_NAME_URL
        @COMMA_SEP @CC_COLUMN_NAME_SYNC_URL
        @COMMA_SEP @CC_COLUMN_NAME_SYNC_THRESHOLD
        @COMMA_SEP @CC_COLUMN_NAME_HEADERS
        @COMMA_SEP @CC_COLUMN_NAME_SAVE_BATTERY
        @COMMA_SEP @CC_COLUMN_NAME_MAX_LOCATIONS
        @COMMA_SEP @CC_COLUMN_NAME_PAUSE_LOCATION_UPDATES
        @COMMA_SEP @CC_COLUMN_NAME_TEMPLATE
        @COMMA_SEP @CC_COLUMN_NAME_LAST_UPDATED_AT
        @") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,DateTime('now'))";

    [queue inDatabase:^(FMDatabase *database) {
        success = [database executeUpdate:sql,
                    @(1), // config id
                    [config hasStationaryRadius] ? config.stationaryRadius : @CC_COLUMN_NAME_NULLABLE,
                    [config hasDistanceFilter] ? config.distanceFilter : @CC_COLUMN_NAME_NULLABLE,
                    [config hasDesiredAccuracy] ? config.desiredAccuracy : @CC_COLUMN_NAME_NULLABLE,
                    [config hasDebug] ? config._debug : @CC_COLUMN_NAME_NULLABLE,
                    [config hasActivityType] ? config.activityType : @CC_COLUMN_NAME_NULLABLE,
                    [NSNull null], // unsupported notificationTitle
                    [NSNull null], // unsupported notificationText
                    [NSNull null], // unsupported notificationIconLarge
                    [NSNull null], // unsupported notificationIconSmall
                    [NSNull null], // unsupported notificationIconColor
                    [config hasStopOnTerminate] ? config._stopOnTerminate : @CC_COLUMN_NAME_NULLABLE,
                    [NSNull null], // unsupported startOnBoot,
                    [NSNull null], // unsupported startForeground
                    [NSNull null], // unsupported stopOnStillActivity
                    [config hasLocationProvider] ? config.locationProvider : @CC_COLUMN_NAME_NULLABLE,
                    [NSNull null], // unsupported interval
                    [NSNull null], // unsupported fastestInterval
                    [config hasActivitiesInterval] ? config.activitiesInterval : @CC_COLUMN_NAME_NULLABLE,
                    [config hasUrl] ? config.url : @CC_COLUMN_NAME_NULLABLE,
                    [config hasSyncUrl] ? config.syncUrl : @CC_COLUMN_NAME_NULLABLE,
                    [config hasSyncThreshold] ? config.syncThreshold : @CC_COLUMN_NAME_NULLABLE,
                    (httpHeadersString != nil) ? httpHeadersString : @CC_COLUMN_NAME_NULLABLE,
                    [config hasSaveBatteryOnBackground] ? config._saveBatteryOnBackground : @CC_COLUMN_NAME_NULLABLE,
                    [config hasMaxLocations] ? config.maxLocations : @CC_COLUMN_NAME_NULLABLE,
                    [config hasPauseLocationUpdates] ? config._pauseLocationUpdates : @CC_COLUMN_NAME_NULLABLE,
                    (templateString != nil) ? templateString : @CC_COLUMN_NAME_NULLABLE
                ];

        if (success) {
            NSLog(@"Configuration persisted succesfuly");
        } else {
            NSLog(@"Persisting configuration has failed code: %d: message: %@", [database lastErrorCode], [database lastErrorMessage]);
        }
    }];
    
    return success;
}

- (MAURConfig*) retrieveConfiguration
{
    __block MAURConfig *config = nil;

    NSString *sql = @"SELECT "
    CC_COLUMN_NAME_ID
    @COMMA_SEP @CC_COLUMN_NAME_RADIUS
    @COMMA_SEP @CC_COLUMN_NAME_DISTANCE_FILTER
    @COMMA_SEP @CC_COLUMN_NAME_DESIRED_ACCURACY
    @COMMA_SEP @CC_COLUMN_NAME_DEBUG
    @COMMA_SEP @CC_COLUMN_NAME_ACTIVITY_TYPE
    @COMMA_SEP @CC_COLUMN_NAME_NOTIF_TITLE
    @COMMA_SEP @CC_COLUMN_NAME_NOTIF_TEXT
    @COMMA_SEP @CC_COLUMN_NAME_NOTIF_ICON_LARGE
    @COMMA_SEP @CC_COLUMN_NAME_NOTIF_ICON_SMALL
    @COMMA_SEP @CC_COLUMN_NAME_NOTIF_COLOR
    @COMMA_SEP @CC_COLUMN_NAME_STOP_TERMINATE
    @COMMA_SEP @CC_COLUMN_NAME_START_BOOT
    @COMMA_SEP @CC_COLUMN_NAME_START_FOREGROUND
    @COMMA_SEP @CC_COLUMN_NAME_STOP_ON_STILL
    @COMMA_SEP @CC_COLUMN_NAME_LOCATION_PROVIDER
    @COMMA_SEP @CC_COLUMN_NAME_INTERVAL
    @COMMA_SEP @CC_COLUMN_NAME_FASTEST_INTERVAL
    @COMMA_SEP @CC_COLUMN_NAME_ACTIVITIES_INTERVAL
    @COMMA_SEP @CC_COLUMN_NAME_URL
    @COMMA_SEP @CC_COLUMN_NAME_SYNC_URL
    @COMMA_SEP @CC_COLUMN_NAME_SYNC_THRESHOLD
    @COMMA_SEP @CC_COLUMN_NAME_HEADERS
    @COMMA_SEP @CC_COLUMN_NAME_SAVE_BATTERY
    @COMMA_SEP @CC_COLUMN_NAME_MAX_LOCATIONS
    @COMMA_SEP @CC_COLUMN_NAME_PAUSE_LOCATION_UPDATES
    @COMMA_SEP @CC_COLUMN_NAME_TEMPLATE
    @" FROM " @CC_TABLE_NAME @" WHERE " @CC_COLUMN_NAME_ID @" = 1";
    
    [queue inDatabase:^(FMDatabase *database) {
        FMResultSet *rs = [database executeQuery:sql];
        while([rs next]) {
            config = [[MAURConfig alloc] init];
            if ([self isNonNull:rs columnIndex:1]) {
                config.stationaryRadius = [NSNumber numberWithInt:[rs intForColumnIndex:1]];
            }
            if ([self isNonNull:rs columnIndex:2]) {
                config.distanceFilter = [NSNumber numberWithInt:[rs intForColumnIndex:2]];
            }
            if ([self isNonNull:rs columnIndex:3]) {
                config.desiredAccuracy = [NSNumber numberWithInt:[rs intForColumnIndex:3]];
            }
            if ([self isNonNull:rs columnIndex:4]) {
                config._debug = [NSNumber numberWithBool:[rs intForColumnIndex:4] == 1 ? YES : NO];
            }
            if ([self isNonNull:rs columnIndex:5]) {
                config.activityType = [rs stringForColumnIndex:5];
            }
            if ([self isNonNull:rs columnIndex:11]) {
                config._stopOnTerminate =  [NSNumber numberWithBool:[rs intForColumnIndex:11] == 1 ? YES : NO];
            }
            if ([self isNonNull:rs columnIndex:15]) {
                config.locationProvider = [NSNumber numberWithInt:[rs intForColumnIndex:15]];
            }
            if ([self isNonNull:rs columnIndex:18]) {
                config.activitiesInterval = [NSNumber numberWithInt:[rs intForColumnIndex:18]];
            }
            if ([self isNonNull:rs columnIndex:19]) {
                config.url = [rs stringForColumnIndex:19];
            }
            if ([self isNonNull:rs columnIndex:20]) {
                config.syncUrl = [rs stringForColumnIndex:20];
            }
            if ([self isNonNull:rs columnIndex:21]) {
                config.syncThreshold = [NSNumber numberWithInt:[rs intForColumnIndex:21]];
            }
            if ([self isNonNull:rs columnIndex:22]) {
                NSString *httpHeadersString = [rs stringForColumnIndex:22];
                if (httpHeadersString != nil) {
                    NSData *jsonHttpHeaders = [httpHeadersString dataUsingEncoding:NSUTF8StringEncoding];
                    config.httpHeaders = [NSJSONSerialization JSONObjectWithData:jsonHttpHeaders options:0 error:nil];
                }
            }
            if ([self isNonNull:rs columnIndex:23]) {
                config._saveBatteryOnBackground = [NSNumber numberWithBool:[rs intForColumnIndex:23] == 1 ? YES : NO];
            }
            if ([self isNonNull:rs columnIndex:24]) {
                config.maxLocations = [NSNumber numberWithInt:[rs intForColumnIndex:24]];
            }
            if ([self isNonNull:rs columnIndex:25]) {
                config._pauseLocationUpdates = [NSNumber numberWithBool:[rs intForColumnIndex:25] == 1 ? YES : NO];
            }
            if ([self isNonNull:rs columnIndex:26]) {
                NSString *templateAsString = [rs stringForColumnIndex:26];
                if (templateAsString != nil) {
                    NSData *jsonTemplate = [templateAsString dataUsingEncoding:NSUTF8StringEncoding];
                    config._template = [NSJSONSerialization JSONObjectWithData:jsonTemplate options:0 error:nil];
                }
            }
        }
        
        [rs close];
    }];
    
    return config;
}

- (BOOL) clearDatabase
{
    __block BOOL success;
    
    [queue inDatabase:^(FMDatabase *database) {
        NSString *sql = [NSString stringWithFormat: @"DELETE FROM %@", @CC_TABLE_NAME];
        if (![database executeStatements:sql]) {
            NSLog(@"%@ failed code: %d: message: %@", sql, [database lastErrorCode], [database lastErrorMessage]);
            success = NO;
        } else {
            success = YES;
        }
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

- (BOOL) isNonNull:(FMResultSet*)resultSet columnIndex:(int)index
{
    if (![[resultSet stringForColumnIndex:index] isEqualToString:@CC_COLUMN_NAME_NULLABLE]) {
        return YES;
    }

    return NO;
}

- (void) dealloc {
    [helper close];
    [queue close];
    helper = nil;
    queue = nil;
}

@end
