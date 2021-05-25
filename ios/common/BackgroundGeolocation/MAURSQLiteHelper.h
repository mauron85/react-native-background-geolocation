//
//  MAURSQLiteHelper.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 23/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#ifndef MAURSQLiteHelper_h
#define MAURSQLiteHelper_h

#import <Foundation/Foundation.h>

#define COMMA_SEP ","
#define SPACE_SEP " "
#define EQ_BIND "= ?"

static NSString * const Domain = @"SQLiteHelper";

typedef NS_ENUM(NSInteger, SQLType) {
    kReal = 0, kInteger = 1, kText = 2, kDateTime = 3
};


@interface SQLColumnType : NSObject
{
@protected enum SQLType type;
}


@property enum SQLType type;
+ (SQLColumnType*) sqlColumnWithType:(SQLType)type;
- (NSString*) asString;
@end


@interface SQLPrimaryKeyColumnType : SQLColumnType
+ (SQLColumnType*) sqlColumnWithType:(SQLType)type;
- (NSString*) asString;
@end


@interface SQLPrimaryKeyAutoIncColumnType : SQLColumnType
+ (SQLColumnType*) sqlColumnWithType:(SQLType)type;
- (NSString*) asString;
@end


typedef NSArray<NSDictionary<NSString*, SQLColumnType*>*> SQLColumns;


@interface MAURSQLiteHelper : NSObject
+ (NSString*) createTableSqlStatement:(NSString*)tableName columns:(SQLColumns*)columns;
@end


#endif /* MAURSQLiteHelper_h */
