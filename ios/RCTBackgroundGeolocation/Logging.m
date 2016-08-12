//
//  Logging.m
//  CDVBackgroundGeolocation
//
//  Created by Marian Hello on 02/07/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "Logging.h"
#import "FMDB.h"

@implementation LogReader : NSObject

+ (NSArray*) getEntries:(NSString*)path limit:(NSInteger)limit
{
    limit = (limit > 0) ? limit : 100;

    NSMutableArray *logs = [[NSMutableArray alloc] init];
    FMDatabase *database = [[FMDatabase alloc] initWithPath:path];
    if (![database openWithFlags:SQLITE_OPEN_READONLY]) {
        NSLog(@"%@: Failed opening database!", [self class]);
        database = nil;
        return nil;
    }

    NSString *sql = [NSString stringWithFormat:@"SELECT context,level,message,timestamp FROM logs ORDER BY timestamp DESC LIMIT %ld", limit];
    FMResultSet *rs = [database executeQuery:sql];
    while([rs next]) {
        NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithCapacity:4];
        [entry setObject:[NSNumber numberWithInt:[rs intForColumnIndex:0]] forKey:@"context"];
        [entry setObject:[NSNumber numberWithInt:[rs intForColumnIndex:1]] forKey:@"level"];
        [entry setObject:[rs stringForColumnIndex:2] forKey:@"message"];
        [entry setObject:[NSNumber numberWithInt:[rs doubleForColumnIndex:3]] forKey:@"timestamp"];
        [logs addObject:entry];
    }
    [rs close];
    [database close];
    
    return logs;
    
}

@end