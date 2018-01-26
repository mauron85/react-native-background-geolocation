//
//  GeolocationOpenHelperTest.m
//  BackgroundGeolocationTests
//
//  Created by Marian Hello on 01/07/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SQLiteOpenHelper.h"
#import "LocationContract.h"
#import "ConfigurationContract.h"
#import "GeolocationOpenHelper.h"


// Warning: This has to be last test in suite, because it unlinks db file
@interface xGeolocationOpenHelperTest : XCTestCase

@end

@implementation xGeolocationOpenHelperTest

- (void)setUp {
    [super setUp];
    GeolocationOpenHelper *helper = [[GeolocationOpenHelper alloc] init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dbPath = [helper getDatabasePath];
    [fileManager removeItemAtPath:dbPath error:nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testIfLocationTableIsCreated {
    GeolocationOpenHelper *helper = [[GeolocationOpenHelper alloc] init];
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
    GeolocationOpenHelper *helper = [[GeolocationOpenHelper alloc] init];
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

    SQLiteOpenHelper *baseHelper = [[SQLiteOpenHelper alloc] init:@"cordova_bg_geolocation.db" version:2];
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

    GeolocationOpenHelper *helper = [[GeolocationOpenHelper alloc] init];
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
    NSString *sql = [LocationContract createTableSQL];
    XCTAssertEqualObjects(sql, @"CREATE TABLE IF NOT EXISTS location ( id INTEGER PRIMARY KEY AUTOINCREMENT , time REAL , accuracy REAL , speed REAL , bearing REAL , altitude REAL , latitude REAL , longitude REAL , provider TEXT , service_provider TEXT , valid INTEGER , recorded_at INTEGER );");
}

@end
