//
//  MAURGeolocationOpenHelperTest.m
//  BackgroundGeolocationTests
//
//  Created by Marian Hello on 01/07/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MAURSQLiteOpenHelper.h"
#import "MAURLocationContract.h"
#import "MAURConfigurationContract.h"
#import "MAURGeolocationOpenHelper.h"


// Warning: This has to be last test in suite, because it unlinks db file
@interface xGeolocationOpenHelperTest : XCTestCase

@end

@implementation xGeolocationOpenHelperTest

- (void)setUp {
    [super setUp];
    MAURGeolocationOpenHelper *helper = [[MAURGeolocationOpenHelper alloc] init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dbPath = [helper getDatabasePath];
    [fileManager removeItemAtPath:dbPath error:nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testIfLocationTableIsCreated {
    MAURGeolocationOpenHelper *helper = [[MAURGeolocationOpenHelper alloc] init];
    FMDatabaseQueue *queue = [helper getWritableDatabase];
    
    [queue inDatabase:^(FMDatabase *database) {
        NSString *sql = [NSString stringWithFormat: @"SELECT count(name) FROM sqlite_master WHERE type='table' AND name='%@';", @LC_TABLE_NAME];
        FMResultSet *rs = [database executeQuery:sql];
        while([rs next]) {
            XCTAssertEqual([rs intForColumnIndex:0], 1);
        }
        [rs close];
    }];
    
    [helper close];
}

- (void)testIfConfigurationTableIsCreated {
    MAURGeolocationOpenHelper *helper = [[MAURGeolocationOpenHelper alloc] init];
    FMDatabaseQueue *queue = [helper getWritableDatabase];
    
    [queue inDatabase:^(FMDatabase *database) {
        NSString *sql = [NSString stringWithFormat: @"SELECT count(name) FROM sqlite_master WHERE type='table' AND name='%@';", @CC_TABLE_NAME];
        FMResultSet *rs = [database executeQuery:sql];
        while([rs next]) {
            XCTAssertEqual([rs intForColumnIndex:0], 1);
        }
        [rs close];
    }];
    
    [helper close];
}

- (void)testIfDbIsUpgradedFromVersion2ToVersion3 {
    FMDatabaseQueue *queue;

    MAURSQLiteOpenHelper *baseHelper = [[MAURSQLiteOpenHelper alloc] init:@"cordova_bg_geolocation.db" version:2];
    [baseHelper getWritableDatabase];

    queue = [baseHelper getWritableDatabase];
    [queue inDatabase:^(FMDatabase *database) {
        NSString *sql = [NSString stringWithFormat: @"SELECT count(name) FROM sqlite_master WHERE type='table' AND name='%@';", @CC_TABLE_NAME];
        FMResultSet *rs = [database executeQuery:sql];
        while([rs next]) {
            XCTAssertEqual([rs intForColumnIndex:0], 0);
        }
        [rs close];
    }];

    MAURGeolocationOpenHelper *helper = [[MAURGeolocationOpenHelper alloc] init];
    queue = [helper getWritableDatabase];
    
    [queue inDatabase:^(FMDatabase *database) {
        NSString *sql = [NSString stringWithFormat: @"SELECT count(name) FROM sqlite_master WHERE type='table' AND name='%@';", @CC_TABLE_NAME];
        FMResultSet *rs = [database executeQuery:sql];
        while([rs next]) {
            XCTAssertEqual([rs intForColumnIndex:0], 1);
        }
        [rs close];
    }];
}

- (void)testLocationTableSQLStatement {
    NSString *sql = [MAURLocationContract createTableSQL];
    XCTAssertEqualObjects(sql, @"CREATE TABLE IF NOT EXISTS location ( id INTEGER PRIMARY KEY AUTOINCREMENT , time REAL , accuracy REAL , speed REAL , bearing REAL , altitude REAL , latitude REAL , longitude REAL , provider TEXT , service_provider TEXT , valid INTEGER , recorded_at INTEGER );");
}

@end
