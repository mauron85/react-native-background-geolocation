//
//  LocationContract.m
//  CDVBackgroundGeolocation
//
//  Created by Marian Hello on 23/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLiteHelper.h"
#import "LocationContract.h"

@implementation LocationContract

+ (NSString*) createTableSQL
{
    NSArray *columns = @[
        @{ @"name": @LC_COLUMN_NAME_ID, @"type": [SQLPrimaryKeyAutoIncColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @LC_COLUMN_NAME_TIME, @"type": [SQLColumnType sqlColumnWithType: kReal]},
        @{ @"name": @LC_COLUMN_NAME_ACCURACY, @"type": [SQLColumnType sqlColumnWithType: kReal]},
        @{ @"name": @LC_COLUMN_NAME_SPEED, @"type": [SQLColumnType sqlColumnWithType: kReal]},
        @{ @"name": @LC_COLUMN_NAME_BEARING, @"type": [SQLColumnType sqlColumnWithType: kReal]},
        @{ @"name": @LC_COLUMN_NAME_ALTITUDE, @"type": [SQLColumnType sqlColumnWithType: kReal]},
        @{ @"name": @LC_COLUMN_NAME_LATITUDE, @"type": [SQLColumnType sqlColumnWithType: kReal]},
        @{ @"name": @LC_COLUMN_NAME_LONGITUDE, @"type": [SQLColumnType sqlColumnWithType: kReal]},
        @{ @"name": @LC_COLUMN_NAME_PROVIDER, @"type": [SQLColumnType sqlColumnWithType: kText]},
        @{ @"name": @LC_COLUMN_NAME_LOCATION_PROVIDER, @"type": [SQLColumnType sqlColumnWithType: kText]},
        @{ @"name": @LC_COLUMN_NAME_VALID, @"type": [SQLColumnType sqlColumnWithType: kInteger]}
    ];
    
    return [SQLiteHelper createTableSqlStatement:@LC_TABLE_NAME columns:columns];
}

@end
