//
//  GeolocationOpenHelper.m
//  CDVBackgroundGeolocation
//
//  Created by Marian Hello on 27/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeolocationOpenHelper.h"
#import "LocationContract.h"

@implementation GeolocationOpenHelper

static NSString *const kDatabaseName = @"cordova_bg_geolocation.db";
static NSInteger const kDatabaseVersion = 1;

- (instancetype)init
{
    self = [super init:kDatabaseName version:kDatabaseVersion];
    return self;
}

- (void) drop:(NSString*)table inDatabase:(FMDatabase*)database
{
    NSString *sql = [NSString stringWithFormat: @"DROP TABLE %@", table];
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
            [LocationContract createTableSQL],
            @"CREATE INDEX time_idx ON " @LC_TABLE_NAME @" (" @LC_COLUMN_NAME_TIME @");"
        ]  componentsJoinedByString:@""];
        if (![database executeStatements:sql]) {
            NSLog(@"%@ failed code: %d: message: %@", sql, [database lastErrorCode], [database lastErrorMessage]);
        }
    }];
}

- (void) onDowngrade:(FMDatabaseQueue*)queue fromVersion:(NSInteger)oldVersion toVersion:(NSInteger)newVersion
{
    // no upgrade policy yet
}

- (void) onUpgrade:(FMDatabaseQueue*)queue fromVersion:(NSInteger)oldVersion toVersion:(NSInteger)newVersion
{
    // no downgrade policy yet
}

@end