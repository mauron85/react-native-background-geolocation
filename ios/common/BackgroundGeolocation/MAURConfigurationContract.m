//
//  MAURConfigurationContract.m
//  BackgroundGeolocation
//
//  Created by Marian Hello on 01/12/2017.
//  Copyright © 2017 mauron85. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAURSQLiteHelper.h"
#import "MAURConfigurationContract.h"

@implementation MAURConfigurationContract

+ (NSString*) createTableSQL
{
    NSArray *columns = @[
        @{ @"name": @CC_COLUMN_NAME_ID, @"type": [SQLPrimaryKeyAutoIncColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @CC_COLUMN_NAME_RADIUS, @"type": [SQLColumnType sqlColumnWithType: kReal]},
        @{ @"name": @CC_COLUMN_NAME_DISTANCE_FILTER, @"type": [SQLColumnType sqlColumnWithType: kReal]},
        @{ @"name": @CC_COLUMN_NAME_DESIRED_ACCURACY, @"type": [SQLColumnType sqlColumnWithType: kReal]},
        @{ @"name": @CC_COLUMN_NAME_DEBUG, @"type": [SQLColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @CC_COLUMN_NAME_ACTIVITY_TYPE, @"type": [SQLColumnType sqlColumnWithType: kText]},
        @{ @"name": @CC_COLUMN_NAME_NOTIF_TITLE, @"type": [SQLColumnType sqlColumnWithType: kText]},
        @{ @"name": @CC_COLUMN_NAME_NOTIF_TEXT, @"type": [SQLColumnType sqlColumnWithType: kText]},
        @{ @"name": @CC_COLUMN_NAME_NOTIF_ICON_LARGE, @"type": [SQLColumnType sqlColumnWithType: kText]},
        @{ @"name": @CC_COLUMN_NAME_NOTIF_ICON_SMALL, @"type": [SQLColumnType sqlColumnWithType: kText]},
        @{ @"name": @CC_COLUMN_NAME_NOTIF_COLOR, @"type": [SQLColumnType sqlColumnWithType: kText]},
        @{ @"name": @CC_COLUMN_NAME_STOP_TERMINATE, @"type": [SQLColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @CC_COLUMN_NAME_START_BOOT, @"type": [SQLColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @CC_COLUMN_NAME_START_FOREGROUND, @"type": [SQLColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @CC_COLUMN_NAME_STOP_ON_STILL, @"type": [SQLColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @CC_COLUMN_NAME_LOCATION_PROVIDER, @"type": [SQLColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @CC_COLUMN_NAME_INTERVAL, @"type": [SQLColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @CC_COLUMN_NAME_FASTEST_INTERVAL, @"type": [SQLColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @CC_COLUMN_NAME_ACTIVITIES_INTERVAL, @"type": [SQLColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @CC_COLUMN_NAME_URL, @"type": [SQLColumnType sqlColumnWithType: kText]},
        @{ @"name": @CC_COLUMN_NAME_SYNC_URL, @"type": [SQLColumnType sqlColumnWithType: kText]},
        @{ @"name": @CC_COLUMN_NAME_SYNC_THRESHOLD, @"type": [SQLColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @CC_COLUMN_NAME_HEADERS, @"type": [SQLColumnType sqlColumnWithType: kText]},
        @{ @"name": @CC_COLUMN_NAME_SAVE_BATTERY, @"type": [SQLColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @CC_COLUMN_NAME_MAX_LOCATIONS, @"type": [SQLColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @CC_COLUMN_NAME_PAUSE_LOCATION_UPDATES, @"type": [SQLColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @CC_COLUMN_NAME_TEMPLATE, @"type": [SQLColumnType sqlColumnWithType: kText]},
        @{ @"name": @CC_COLUMN_NAME_LAST_UPDATED_AT, @"type": [SQLColumnType sqlColumnWithType: kInteger]}        
    ];
    
    return [MAURSQLiteHelper createTableSqlStatement:@CC_TABLE_NAME columns:columns];
}

@end
