//
//  MAURSQLiteOpenHelper.m
//
//  Created by Marian Hello on 22/06/16.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "MAURSQLiteHelper.h"
#import "MAURSQLiteOpenHelper.h"

@implementation MAURSQLiteOpenHelper {
    FMDatabaseQueue *mQueue;
    BOOL mIsInitializing;
    BOOL mIsReadOnly;
    NSInteger mNewVersion; //  REMARK: never use mNewVersion < 1 in your subclasses
    NSString* mName;
}

static NSString *const metaTableName = @"__META";
static int const OPEN_READONLY = SQLITE_OPEN_READONLY|SQLITE_OPEN_FULLMUTEX;
static int const OPEN_READWRITE = SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX;

- (instancetype)init:(NSString*)name version:(NSInteger)version
{
    self = [super init];
    if (self) {
        self->mName = name;
        self->mNewVersion = version;
    }
    return self;
}

- (FMDatabaseQueue*) getReadableDatabase
{
    
    @synchronized(self) {
        return [self getDatabaseLocked: NO];
    }
}

- (FMDatabaseQueue*) getWritableDatabase
{
    @synchronized(self) {
        return [self getDatabaseLocked: YES];
    }
}

- (FMDatabaseQueue*) getDatabaseLocked:(BOOL)writable
{
    if (mQueue != nil) {
        // TODO: add check if db was closed by user
        return mQueue;
    }
    
    if (mIsInitializing) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"getDatabaseLocked called recursively"]
                                     userInfo:nil];
    }
    
    FMDatabaseQueue* queue = mQueue;
    mIsInitializing = true;
    
    if (queue != nil) {
        if (writable && mIsReadOnly) {
            // TODO reopen as writable
        }
    } else if (mName == nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"in memory database is not supported"]
                                     userInfo:nil];
    } else {
        if (writable) {
            queue = [self openOrCreateDatabase:mName];
        } else {
            queue = [self openDatabase:[self getDatabasePath] flags: OPEN_READONLY];
        }
    }
    
    [self onConfigure:queue];
    
    NSInteger version = [self getVersion:queue];
    NSLog(@"Current db version: %ld", (long)version);
    
    if (version != mNewVersion) {
        if (version == 0) {
            [self onCreate:queue];
        } else {
            if (version < mNewVersion) {
                [self onUpgrade:queue fromVersion:version toVersion:mNewVersion];
            } else if (version > mNewVersion) {
                [self onDowngrade:queue fromVersion:version toVersion:mNewVersion];
            }
        }
        [self setVersion:queue version:mNewVersion];
    }
    
    [self onOpen:queue];
    
    mQueue = queue;
    mIsInitializing = false;
    mIsReadOnly = !writable;
    return queue;
}

- (FMDatabaseQueue*) openDatabase:(NSString*)path flags:(int)flags
{
    return [FMDatabaseQueue databaseQueueWithPath:path flags:flags];
}

- (FMDatabaseQueue*) openOrCreateDatabase:(NSString*)name
{
    __block BOOL isOpen;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[self getDatabasePath:name]];
    
    [queue inDatabase:^(FMDatabase *database) {
        isOpen = [database open];
    }];
    
    if (!isOpen) {
        return nil;
    }
    
    if ([self getVersion:queue] == -1) {
        NSArray *columns = @[
            @{ @"name": @"id", @"type": [SQLPrimaryKeyColumnType sqlColumnWithType: kInteger]},
            @{ @"name": @"db_version", @"type": [SQLColumnType sqlColumnWithType: kInteger]},
            @{ @"name": @"created", @"type": [SQLColumnType sqlColumnWithType: kInteger]},
            @{ @"name": @"last_updated", @"type": [SQLColumnType sqlColumnWithType: kInteger]}
         ];
        
        [queue inDatabase:^(FMDatabase *database) {
            if ([database executeStatements:[MAURSQLiteHelper createTableSqlStatement:metaTableName columns:columns]]) {
                NSString *sql = [NSString stringWithFormat: @"INSERT INTO %@ (id,db_version,created,last_updated) VALUES (1,%d,datetime(),null)", metaTableName, 0];
                if (![database executeUpdate:sql]) {
                    NSLog(@"%@ failed code: %d: message: %@", sql, [database lastErrorCode], [database lastErrorMessage]);
                }
            } else {
                NSLog(@"Creating meta table %@ failed code: %d: message: %@", metaTableName, [database lastErrorCode], [database lastErrorMessage]);
            }
        }];
    }
    
    return queue;
}

- (void) close
{
    @synchronized(self) {
        if (mQueue != nil) {
            [mQueue close];
            mQueue = nil;
        }
    }
}

- (NSDictionary*) getDatabaseMetadata
{
    FMDatabaseQueue *queue = [self getReadableDatabase];
    NSMutableDictionary *metadata = [[NSMutableDictionary alloc] init];
    [metadata setObject:[NSNumber numberWithInt:-1] forKey:@"dbVersion"];
    
    NSString *sql =[NSString stringWithFormat: @"SELECT db_version, created, last_updated FROM %@ LIMIT 1", metaTableName];
    [queue inDatabase:^(FMDatabase *database) {
        FMResultSet *rs = [database executeQuery:sql];
        while ([rs next]) {
            NSNumber *dbVersion = [NSNumber numberWithInt:[rs intForColumnIndex:0]];
            NSString *created = [rs stringForColumnIndex:1] ?: @"";
            NSString *lastUpdated = [rs stringForColumnIndex:2] ?: @"";
            
            [metadata setObject:dbVersion forKey:@"dbVersion"];
            [metadata setObject:created forKey:@"created"];
            [metadata setObject:lastUpdated forKey:@"last_updated"];
        }
        
        // TODO error handling
        // NSLog(@"Retrieving meta data failed code: %d: message: %s", sqlite3_errcode(database), sqlite3_errmsg(database));
        [rs close];
        
    }];
    
    [queue close];
    
    return metadata;
}

- (NSString*) getDatabaseName
{
    return mName;
}

- (NSString*) getDatabasePath:(NSString*)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    NSString *databasePath = [[NSString alloc]initWithString:[libraryDirectory stringByAppendingPathComponent:name]];
    
    return databasePath;
}

- (NSString*) getDatabasePath
{
    return [self getDatabasePath:mName];
}

- (FMDatabaseQueue*) getDatabaseQueue
{
    @synchronized(self) {
        if (mQueue == nil) {
            mQueue = [FMDatabaseQueue databaseQueueWithPath:[self getDatabasePath]];
        }
        
        return mQueue;
    }
}

- (NSInteger) getVersion:(FMDatabaseQueue*)queue
{
    __block NSInteger dbVersion = -1;
    NSString *sql =[NSString stringWithFormat: @"SELECT db_version FROM %@", metaTableName];
    [queue inDatabase:^(FMDatabase *database) {
        database.logsErrors = NO;
        NSError *lastError;
        FMResultSet *rs = [database executeQuery:sql values:nil error:&lastError];
        if (rs != nil) {
            while ([rs next]) {
                dbVersion = [rs intForColumnIndex:0];
            }
            [rs close];
        } else {
            NSLog(@"Determining db version returned error (ok for first run): %@", [lastError localizedDescription]);
        }
        database.logsErrors = YES;
    }];
    
    return dbVersion;
}

- (void) setVersion:(FMDatabaseQueue*)queue version:(NSInteger)version
{
    NSString *sql = [NSString stringWithFormat: @"UPDATE %@ SET db_version = %ld, last_updated = datetime()", metaTableName, (long)version];
    [queue inDatabase:^(FMDatabase *database) {
        if (![database executeUpdate:sql]) {
            NSLog(@"%@ failed code: %d: message: %@", sql, [database lastErrorCode], [database lastErrorMessage]);
        }
    }];
}

- (void) onOpen:(FMDatabaseQueue*)database
{
    // ment to be implemented in subclass
}

- (void) onConfigure:(FMDatabaseQueue*)database;
{
    // ment to be implemented in subclass
}

- (void) onCreate:(FMDatabaseQueue*)database
{
    // has to be implemented in subclass
}

- (void) onUpgrade:(FMDatabaseQueue*)database fromVersion:(NSInteger)oldVersion toVersion:(NSInteger)newVersion
{
    // upgrade policy has to be implemented in subclass
}

- (void) onDowngrade:(FMDatabaseQueue*)database fromVersion:(NSInteger)oldVersion toVersion:(NSInteger)newVersion
{
    // upgrade policy has to be implemented in subclass
}


@end
