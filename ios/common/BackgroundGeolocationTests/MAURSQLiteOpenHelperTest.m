//
//  MAURSQLiteOpenHelperTest.m
//  BackgroundGeolocationTests
//
//  Created by Marian Hello on 01/07/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MAURSQLiteHelper.h"
#import "MAURSQLiteOpenHelper.h"

@interface MockCreateOpenHelper : MAURSQLiteOpenHelper
@property (readwrite, nonatomic) BOOL wasCreated;
- (void) onCreate:(FMDatabase*)database;
@end

@implementation MockCreateOpenHelper : MAURSQLiteOpenHelper
- (instancetype)init
{
    self = [super init:@"geolocationtest.db" version:1];
    self.wasCreated = NO;
    return self;
}
- (void) onCreate:(FMDatabase*)database
{
    self.wasCreated = YES;
}
@end


@interface MockUpgradeOpenHelper : MAURSQLiteOpenHelper
@property (readwrite, nonatomic) BOOL wasUpgraded;
- (void) onUpgrade:(FMDatabase*)database fromVersion:(NSInteger)oldVersion toVersion:(NSInteger)newVersion;
@end

@implementation MockUpgradeOpenHelper : MAURSQLiteOpenHelper
- (instancetype)init
{
    self = [super init:@"geolocationtest.db" version:2];
    self.wasUpgraded = NO;
    return self;
}
- (void) onUpgrade:(FMDatabase*)database fromVersion:(NSInteger)oldVersion toVersion:(NSInteger)newVersion
{
    self.wasUpgraded = YES;
}
@end


@interface MockDowngradeOpenHelper : MAURSQLiteOpenHelper
@property (readwrite, nonatomic) BOOL wasDowngraded;
- (void) onDowngrade:(FMDatabase*)database fromVersion:(NSInteger)oldVersion toVersion:(NSInteger)newVersion;
@end

@implementation MockDowngradeOpenHelper : MAURSQLiteOpenHelper
- (instancetype)init
{
    self = [super init:@"geolocationtest.db" version:1];
    self.wasDowngraded = NO;
    return self;
}
- (void) onDowngrade:(FMDatabase*)database fromVersion:(NSInteger)oldVersion toVersion:(NSInteger)newVersion
{
    self.wasDowngraded = YES;
}
@end


@interface MAURSQLiteOpenHelperTest : XCTestCase

@end

@implementation MAURSQLiteOpenHelperTest

- (void)setUp {
    [super setUp];
    MockCreateOpenHelper *helper = [[MockCreateOpenHelper alloc] init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *dbPath = [helper getDatabasePath];
    [fileManager removeItemAtPath:dbPath error:nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testIfDbIsCreated {
    MockCreateOpenHelper *helper = [[MockCreateOpenHelper alloc] init];
    [helper getWritableDatabase];
    [helper close];
    NSDictionary *meta = [helper getDatabaseMetadata];
    NSLog(@"meta %@ %@ %@", meta[@"dbVersion"], meta[@"created"], meta[@"last_updated"]);
    XCTAssertEqual([[meta valueForKey:@"dbVersion"] integerValue], 1);
    XCTAssertTrue(helper.wasCreated);
}

- (void)testIfDbIsUpgraded {
    MAURSQLiteOpenHelper *helper;
    
    // first create empty db version 1
    helper = [[MockCreateOpenHelper alloc] init];
    [helper getWritableDatabase];
    [helper close];
    
    // now upgrade to version 2
    helper = [[MockUpgradeOpenHelper alloc] init];
    [helper getWritableDatabase];
    [helper close];
    NSDictionary *meta = [helper getDatabaseMetadata];
    NSLog(@"meta %@ %@ %@", meta[@"dbVersion"], meta[@"created"], meta[@"last_updated"]);
    XCTAssertEqual([[meta valueForKey:@"dbVersion"] integerValue], 2);
    XCTAssertTrue(((MockUpgradeOpenHelper*)helper).wasUpgraded);
}

- (void)testIfDbIsDowngraded {
    MAURSQLiteOpenHelper *helper;
    NSDictionary *meta;
    
    // first create empty db version 1
    helper = [[MockCreateOpenHelper alloc] init];
    [helper getWritableDatabase];
    [helper close];
    
    // now upgrade to version 2
    helper = [[MockUpgradeOpenHelper alloc] init];
    [helper getWritableDatabase];
    [helper close];
    meta = [helper getDatabaseMetadata];
    XCTAssertEqual([[meta valueForKey:@"dbVersion"] integerValue], 2);
    
    
    helper = [[MockDowngradeOpenHelper alloc] init];
    [helper getWritableDatabase];
    [helper close];
    meta = [helper getDatabaseMetadata];
    NSLog(@"meta %@ %@ %@", meta[@"dbVersion"], meta[@"created"], meta[@"last_updated"]);
    XCTAssertEqual([[meta valueForKey:@"dbVersion"] integerValue], 1);
    XCTAssertTrue(((MockDowngradeOpenHelper*)helper).wasDowngraded);
}


@end
