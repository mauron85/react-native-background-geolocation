//
//  MAURLocationContract.m
//  BackgroundGeolocation
//
//  Created by Marian Hello on 23/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAURSQLiteHelper.h"
#import "MAURLocationContract.h"

@implementation MAURLocationContract

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
        @{ @"name": @LC_COLUMN_NAME_STATUS, @"type": [SQLColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @LC_COLUMN_NAME_RECORDED_AT, @"type": [SQLColumnType sqlColumnWithType: kInteger]}
    ];
    
    return [MAURSQLiteHelper createTableSqlStatement:@LC_TABLE_NAME columns:columns];
}

@end
