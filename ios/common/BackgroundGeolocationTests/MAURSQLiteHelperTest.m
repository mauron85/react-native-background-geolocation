//
//  MAURSQLiteHelperTest.m
//  BackgroundGeolocationTests
//
//  Created by Marian Hello on 27/06/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MAURSQLiteHelper.h"

@interface MAURSQLiteHelperTest : XCTestCase

@end

@implementation MAURSQLiteHelperTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCreateTableSQLStatement {
    NSString *tableName = @"TEST_TABLE";
    NSArray *columns = @[
        @{ @"name": @"pk_col", @"type": [SQLPrimaryKeyAutoIncColumnType sqlColumnWithType: kInteger]},
        @{ @"name": @"text_col", @"type": [SQLColumnType sqlColumnWithType: kText]},
        @{ @"name": @"real_col", @"type": [SQLColumnType sqlColumnWithType: kReal]},
        @{ @"name": @"int_col", @"type": [SQLColumnType sqlColumnWithType: kInteger]}
    ];
    NSString *sql = [MAURSQLiteHelper createTableSqlStatement:tableName columns:columns];
    XCTAssertEqualObjects(sql, @"CREATE TABLE IF NOT EXISTS TEST_TABLE ( pk_col INTEGER PRIMARY KEY AUTOINCREMENT , text_col TEXT , real_col REAL , int_col INTEGER );");
}


@end
