//
//  MAURGeolocationOpenHelper.m
//  BackgroundGeolocation
//
//  Created by Marian Hello on 27/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAURGeolocationOpenHelper.h"
#import "MAURLocationContract.h"
#import "MAURConfigurationContract.h"

@implementation MAURGeolocationOpenHelper

static NSString *const kDatabaseName = @"cordova_bg_geolocation.db";
static NSInteger const kDatabaseVersion = 3;

- (instancetype)init
{
    self = [super init:kDatabaseName version:kDatabaseVersion];
    return self;
}

- (void) drop:(NSString*)table inDatabase:(FMDatabase*)database
{
    NSString *sql = [NSString stringWithFormat: @"DROP TABLE IF EXISTS %@", table];
    if (![database executeStatements:sql]) {
        NSLog(@"%@ failed code: %d: message: %@", sql, [database lastErrorCode], [database lastErrorMessage]);
    }
}

- (void) onCreate:(FMDatabaseQueue*)queue
{
    [queue inDatabase:^(FMDatabase *database) {
        // because of some legacy code we have to drop table
        [self drop:@LC_TABLE_NAME inDatabase:database];
        
        NSString *sql = [@[
                           [MAURLocationContract createTableSQL],
                           [MAURConfigurationContract createTableSQL],
                           @"CREATE INDEX recorded_at_idx ON " @LC_TABLE_NAME @" (" @LC_COLUMN_NAME_RECORDED_AT @")"
                           ]  componentsJoinedByString:@";"];
        if (![database executeStatements:sql]) {
            NSLog(@"%@ failed code: %d: message: %@", sql, [database lastErrorCode], [database lastErrorMessage]);
        }
    }];
}

- (void) onDowngrade:(FMDatabaseQueue*)queue fromVersion:(NSInteger)oldVersion toVersion:(NSInteger)newVersion
{
    NSLog(@"Downgrading geolocation db oldVersion: %ld, newVersion: %ld", oldVersion, newVersion);

    NSString *sql = [@[
         @"DROP TABLE IF EXISTS " @LC_TABLE_NAME
    ] componentsJoinedByString:@";"];

    [queue inDatabase:^(FMDatabase *database) {
        if (![database executeStatements:sql]) {
            NSLog(@"Db downgrade failed code: %d: message: %@", [database lastErrorCode], [database lastErrorMessage]);
        } else {
            [self onCreate:queue];
        }
    }];
}

- (void) onUpgrade:(FMDatabaseQueue*)queue fromVersion:(NSInteger)oldVersion toVersion:(NSInteger)newVersion
{
    NSLog(@"Upgrading geolocation db oldVersion: %ld, newVersion: %ld", oldVersion, newVersion);
    NSMutableArray *sql = [[NSMutableArray alloc] init];
    
    switch (oldVersion) {
        case 1:
            [sql addObjectsFromArray: @[
                @"ALTER TABLE " @LC_TABLE_NAME @" ADD COLUMN " @LC_COLUMN_NAME_RECORDED_AT @" INTEGER",
                @"UPDATE " @LC_TABLE_NAME @" SET " @LC_COLUMN_NAME_RECORDED_AT @" =" @LC_COLUMN_NAME_TIME,
                @"CREATE INDEX recorded_at_idx ON " @LC_TABLE_NAME @" (" @LC_COLUMN_NAME_RECORDED_AT @")",
                @"DROP INDEX IF EXISTS time_idx"
            ]];
        case 2:
            [sql addObjectsFromArray: @[
                [MAURConfigurationContract createTableSQL]
            ]];
            break; // break only for previous db version (cascade statements)
        default:
            return;
    }

    [queue inDatabase:^(FMDatabase *database) {
        NSString *stmt = [sql componentsJoinedByString:@";"];
        if (![database executeStatements:stmt]) {
            NSLog(@"Db upgrade failed code: %d: message: %@", [database lastErrorCode], [database lastErrorMessage]);
        }
    }];
}

@end
