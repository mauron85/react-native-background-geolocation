//
//  MAURLogReaderTest.m
//  BackgroundGeolocationTests
//
//  Created by Marian Hello on 13/04/2018.
//  Copyright © 2018 mauron85. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "MAURLogReader.h"

@interface MAURLogReaderTest : XCTestCase

@end

@implementation MAURLogReaderTest

- (void)testSqlStatementDescending {
    MAURLogReader *lr = [[MAURLogReader alloc] init];
    NSString *stmt = [lr prepareSQL:100 fromLogEntryId:0 minLogLevel:14];
    XCTAssertEqualObjects(stmt, @"SELECT [rowid], [context], [level], [message], [timestamp] FROM [logs] WHERE [level] <= 14 ORDER BY [timestamp] DESC, [rowid] DESC LIMIT 100;");
}

- (void)testSqlStatementAscending {
    MAURLogReader *lr = [[MAURLogReader alloc] init];
    NSString *stmt = [lr prepareSQL:-100 fromLogEntryId:0 minLogLevel:14];
    XCTAssertEqualObjects(stmt, @"SELECT [rowid], [context], [level], [message], [timestamp] FROM [logs] WHERE [level] <= 14 ORDER BY [timestamp] ASC, [rowid] ASC LIMIT 100;");
}

- (void)testSqlStatementFromOffsetDescending {
    MAURLogReader *lr = [[MAURLogReader alloc] init];
    NSString *stmt = [lr prepareSQL:100 fromLogEntryId:100 minLogLevel:14];
    XCTAssertEqualObjects(stmt, @"SELECT [rowid], [context], [level], [message], [timestamp] FROM [logs] WHERE [level] <= 14 AND [rowid] < 100 ORDER BY [timestamp] DESC, [rowid] DESC LIMIT 100;");
}

- (void)testSqlStatementFromOffsetAscending {
    MAURLogReader *lr = [[MAURLogReader alloc] init];
    NSString *stmt = [lr prepareSQL:-100 fromLogEntryId:100 minLogLevel:14];
    XCTAssertEqualObjects(stmt, @"SELECT [rowid], [context], [level], [message], [timestamp] FROM [logs] WHERE [level] <= 14 AND [rowid] > 100 ORDER BY [timestamp] ASC, [rowid] ASC LIMIT 100;");
}

@end
