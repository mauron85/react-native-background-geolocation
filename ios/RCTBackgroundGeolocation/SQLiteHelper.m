//
//  SQLiteHelper.m
//  CDVBackgroundGeolocation
//
//  Created by Marian Hello on 23/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLiteHelper.h"

@implementation SQLColumnType

+ (SQLColumnType*) sqlColumnWithType:(SQLType)type
{
    SQLColumnType *instance = [[SQLColumnType alloc] init];
    instance.type = type;
    return instance;
}

- (NSString*) asString
{
    switch (_type) {
        case kReal:
            return @"REAL";
        case kText:
            return @"TEXT";
        case kInteger:
            return @"INTEGER";
    }
}
@end


@implementation SQLPrimaryKeyColumnType : SQLColumnType
+ (SQLColumnType*) sqlColumnWithType:(SQLType)type
{
    SQLPrimaryKeyAutoIncColumnType *instance = [[SQLPrimaryKeyAutoIncColumnType alloc] init];
    instance.type = type;
    return instance;
}

- (NSString*) asString
{
    return [NSString stringWithFormat:@"%@ PRIMARY KEY", [super asString]];
}
@end


@implementation SQLPrimaryKeyAutoIncColumnType : SQLColumnType
+ (SQLColumnType*) sqlColumnWithType:(SQLType)type
{
    SQLPrimaryKeyAutoIncColumnType *instance = [[SQLPrimaryKeyAutoIncColumnType alloc] init];
    instance.type = type;
    return instance;
}

- (NSString*) asString
{
    return [NSString stringWithFormat:@"%@ PRIMARY KEY AUTOINCREMENT", [super asString]];
}
@end


@implementation SQLiteHelper

+ (NSString*) createTableSqlStatement:(NSString*)tableName columns:(SQLColumns*)columns
{
    NSMutableArray *sql = [NSMutableArray arrayWithObject: @"CREATE TABLE IF NOT EXISTS"];
    [sql addObjectsFromArray: @[tableName, @"("]];
    NSEnumerator *enumerator = [columns objectEnumerator];
    id column = [enumerator nextObject];
    while (nil != column) {
        NSString *columnName = [column objectForKey: @"name"];
        SQLColumnType *columnType = [column objectForKey: @"type"];
        id nextColumn = [enumerator nextObject];
        if (nil != nextColumn) {
            [sql addObjectsFromArray: @[columnName, [columnType asString], @COMMA_SEP]];
        } else {
            [sql addObjectsFromArray: @[columnName, [columnType asString]]];
        }
        column = nextColumn;
    }
    [sql addObject: @");"];
    
    return [sql componentsJoinedByString: @SPACE_SEP];
}

@end