//
//  MAURLogReader.m
//  BackgroundGeolocation
//
//  Created by Marian Hello on 02/07/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "FMDB.h"
#import "ZIMSqlSelectStatement.h"
#import "MAURLogReader.h"

// Convert DDLogFlag to string
static NSString* logFlag_toString(DDLogFlag logFlag)
{
    switch (logFlag) {
        case DDLogFlagVerbose:
            return @"TRACE";
        case DDLogFlagDebug:
            return @"DEBUG";
        case DDLogFlagInfo:
            return @"INFO";
        case DDLogFlagWarning:
            return @"WARN";
        case DDLogFlagError:
            return @"ERROR";
    }
    return @"N/A";
}

static DDLogFlag string_toLogFlag(NSString *logFlag)
{
    if ([@"TRACE" isEqualToString:logFlag]) {
        return DDLogFlagVerbose;
    }
    if ([@"DEBUG" isEqualToString:logFlag]) {
        return DDLogFlagDebug;
    }
    if ([@"INFO" isEqualToString:logFlag]) {
        return DDLogFlagInfo;
    }
    if ([@"WARN" isEqualToString:logFlag]) {
        return DDLogFlagWarning;
    }
    if ([@"ERROR" isEqualToString:logFlag]) {
        return DDLogFlagError;
    }
    
    return DDLogFlagVerbose; // maybe we should throw exception instead
}

@implementation MAURLogReader : NSObject

- (id)initWithLogDirectory:(NSString *)aLogDirectory
{
    if ((self = [super init]))
    {
        logDirectory = [aLogDirectory copy];
    }
    
    return self;
}

- (NSString*) prepareSQL:(NSInteger)limit fromLogEntryId:(NSInteger)entryId minLogLevel:(NSInteger)minLogLevel
{
    ZIMSqlSelectStatement *sql = [[ZIMSqlSelectStatement alloc] init];
    [sql column: @"rowid"];
    [sql column: @"context"];
    [sql column: @"level"];
    [sql column: @"message"];
    [sql column: @"timestamp"];
    [sql from: @"logs"];
    [sql where: @"level" operator: ZIMSqlOperatorLessThanOrEqualTo value: [NSNumber numberWithInteger:minLogLevel]];
    if (entryId > 0) {
        if (limit >= 0) {
            [sql where: @"rowid" operator: ZIMSqlOperatorLessThan value: [NSNumber numberWithInteger:entryId]];
        } else {
            [sql where: @"rowid" operator: ZIMSqlOperatorGreaterThan value: [NSNumber numberWithInteger:entryId]];
        }
    }
    [sql orderBy: @"timestamp" descending:limit >= 0];
    [sql orderBy: @"rowid" descending:limit >= 0];
    [sql limit: ABS(limit)];
    
    return [sql statement];
}

- (NSArray*) getLogEntries:(NSInteger)limit fromLogEntryId:(NSInteger)entryId minLogLevelAsString:(NSString *)minLogLevel;
{
    return [self getEntries:limit fromLogEntryId:entryId minLogLevel:string_toLogFlag(minLogLevel)];
}

- (NSArray*) getEntries:(NSInteger)limit fromLogEntryId:(NSInteger)entryId minLogLevel:(DDLogFlag)minLogLevel;
{
    NSMutableArray *logs = [[NSMutableArray alloc] init];
    NSString *dbPath = [logDirectory stringByAppendingPathComponent:@"log.sqlite"];
    FMDatabase *database = [[FMDatabase alloc] initWithPath:dbPath];
    if (![database openWithFlags:SQLITE_OPEN_READONLY]) {
        NSLog(@"%@: Failed opening database!", [self class]);
        database = nil;
        return nil;
    }
    
    FMResultSet *rs = [database executeQuery:[self prepareSQL:limit fromLogEntryId:entryId minLogLevel:minLogLevel]];
    while([rs next]) {
        NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithCapacity:4];
        [entry setObject:[NSNumber numberWithInt:[rs intForColumnIndex:0]] forKey:@"id"];
        [entry setObject:[NSNumber numberWithInt:[rs intForColumnIndex:1]] forKey:@"context"];
        [entry setObject:logFlag_toString([rs intForColumnIndex:2]) forKey:@"level"];
        [entry setObject:[rs stringForColumnIndex:3] forKey:@"message"];
        [entry setObject:[NSNumber numberWithDouble:[rs doubleForColumnIndex:4] * 1000] forKey:@"timestamp"];
        [logs addObject:entry];
    }
    [rs close];
    [database close];
    
    return logs;
}

@end
