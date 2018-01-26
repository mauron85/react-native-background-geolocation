#import "FMDB.h"
#import "unistd.h"
#import <objc/runtime.h>

#if FMDB_SQLITE_STANDALONE
#import <sqlite3/sqlite3.h>
#else
#import <sqlite3.h>
#endif

@interface FMDatabase ()
- (void)resultSetDidClose:(FMResultSet *)resultSet;
- (FMResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray*)arrayArgs orDictionary:(NSDictionary *)dictionaryArgs orVAList:(va_list)args;
- (BOOL)executeUpdate:(NSString*)sql error:(NSError**)outErr withArgumentsInArray:(NSArray*)arrayArgs orDictionary:(NSDictionary *)dictionaryArgs orVAList:(va_list)args;

@end

@implementation FMDatabase
@synthesize cachedStatements=_cachedStatements;
@synthesize logsErrors=_logsErrors;
@synthesize crashOnErrors=_crashOnErrors;
@synthesize checkedOut=_checkedOut;
@synthesize traceExecution=_traceExecution;

#pragma mark FMDatabase instantiation and deallocation

+ (instancetype)databaseWithPath:(NSString*)aPath {
    return FMDBReturnAutoreleased([[self alloc] initWithPath:aPath]);
}

- (instancetype)init {
    return [self initWithPath:nil];
}

- (instancetype)initWithPath:(NSString*)aPath {
    
    assert(sqlite3_threadsafe()); // whoa there big boy- gotta make sure sqlite it happy with what we're going to do.
    
    self = [super init];
    
    if (self) {
        _databasePath               = [aPath copy];
        _openResultSets             = [[NSMutableSet alloc] init];
        _db                         = nil;
        _logsErrors                 = YES;
        _crashOnErrors              = NO;
        _maxBusyRetryTimeInterval   = 2;
    }
    
    return self;
}

- (void)finalize {
    [self close];
    [super finalize];
}

- (void)dealloc {
    [self close];
    FMDBRelease(_openResultSets);
    FMDBRelease(_cachedStatements);
    FMDBRelease(_dateFormat);
    FMDBRelease(_databasePath);
    FMDBRelease(_openFunctions);
    
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (NSString *)databasePath {
    return _databasePath;
}

+ (NSString*)FMDBUserVersion {
    return @"2.6.2";
}

// returns 0x0240 for version 2.4.  This makes it super easy to do things like:
// /* need to make sure to do X with FMDB version 2.4 or later */
// if ([FMDatabase FMDBVersion] >= 0x0240) { … }

+ (SInt32)FMDBVersion {
    
    // we go through these hoops so that we only have to change the version number in a single spot.
    static dispatch_once_t once;
    static SInt32 FMDBVersionVal = 0;
    
    dispatch_once(&once, ^{
        NSString *prodVersion = [self FMDBUserVersion];
        
        if ([[prodVersion componentsSeparatedByString:@"."] count] < 3) {
            prodVersion = [prodVersion stringByAppendingString:@".0"];
        }
        
        NSString *junk = [prodVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
        
        char *e = nil;
        FMDBVersionVal = (int) strtoul([junk UTF8String], &e, 16);
        
    });
    
    return FMDBVersionVal;
}

#pragma mark SQLite information

+ (NSString*)sqliteLibVersion {
    return [NSString stringWithFormat:@"%s", sqlite3_libversion()];
}

+ (BOOL)isSQLiteThreadSafe {
    // make sure to read the sqlite headers on this guy!
    return sqlite3_threadsafe() != 0;
}

- (void*)sqliteHandle {
    return _db;
}

- (const char*)sqlitePath {
    
    if (!_databasePath) {
        return ":memory:";
    }
    
    if ([_databasePath length] == 0) {
        return ""; // this creates a temporary database (it's an sqlite thing).
    }
    
    return [_databasePath fileSystemRepresentation];
    
}

#pragma mark Open and close database

- (BOOL)open {
    if (_db) {
        return YES;
    }
    
    int err = sqlite3_open([self sqlitePath], (sqlite3**)&_db );
    if(err != SQLITE_OK) {
        NSLog(@"error opening!: %d", err);
        return NO;
    }
    
    if (_maxBusyRetryTimeInterval > 0.0) {
        // set the handler
        [self setMaxBusyRetryTimeInterval:_maxBusyRetryTimeInterval];
    }
    
    
    return YES;
}

- (BOOL)openWithFlags:(int)flags {
    return [self openWithFlags:flags vfs:nil];
}
- (BOOL)openWithFlags:(int)flags vfs:(NSString *)vfsName {
#if SQLITE_VERSION_NUMBER >= 3005000
    if (_db) {
        return YES;
    }
    
    int err = sqlite3_open_v2([self sqlitePath], (sqlite3**)&_db, flags, [vfsName UTF8String]);
    if(err != SQLITE_OK) {
        NSLog(@"error opening!: %d", err);
        return NO;
    }
    
    if (_maxBusyRetryTimeInterval > 0.0) {
        // set the handler
        [self setMaxBusyRetryTimeInterval:_maxBusyRetryTimeInterval];
    }
    
    return YES;
#else
    NSLog(@"openWithFlags requires SQLite 3.5");
    return NO;
#endif
}


- (BOOL)close {
    
    [self clearCachedStatements];
    [self closeOpenResultSets];
    
    if (!_db) {
        return YES;
    }
    
    int  rc;
    BOOL retry;
    BOOL triedFinalizingOpenStatements = NO;
    
    do {
        retry   = NO;
        rc      = sqlite3_close(_db);
        if (SQLITE_BUSY == rc || SQLITE_LOCKED == rc) {
            if (!triedFinalizingOpenStatements) {
                triedFinalizingOpenStatements = YES;
                sqlite3_stmt *pStmt;
                while ((pStmt = sqlite3_next_stmt(_db, nil)) !=0) {
                    NSLog(@"Closing leaked statement");
                    sqlite3_finalize(pStmt);
                    retry = YES;
                }
            }
        }
        else if (SQLITE_OK != rc) {
            NSLog(@"error closing!: %d", rc);
        }
    }
    while (retry);
    
    _db = nil;
    return YES;
}

#pragma mark Busy handler routines

// NOTE: appledoc seems to choke on this function for some reason;
//       so when generating documentation, you might want to ignore the
//       .m files so that it only documents the public interfaces outlined
//       in the .h files.
//
//       This is a known appledoc bug that it has problems with C functions
//       within a class implementation, but for some reason, only this
//       C function causes problems; the rest don't. Anyway, ignoring the .m
//       files with appledoc will prevent this problem from occurring.

static int FMDBDatabaseBusyHandler(void *f, int count) {
    FMDatabase *self = (__bridge FMDatabase*)f;
    
    if (count == 0) {
        self->_startBusyRetryTime = [NSDate timeIntervalSinceReferenceDate];
        return 1;
    }
    
    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - (self->_startBusyRetryTime);
    
    if (delta < [self maxBusyRetryTimeInterval]) {
        int requestedSleepInMillseconds = (int) arc4random_uniform(50) + 50;
        int actualSleepInMilliseconds = sqlite3_sleep(requestedSleepInMillseconds);
        if (actualSleepInMilliseconds != requestedSleepInMillseconds) {
            NSLog(@"WARNING: Requested sleep of %i milliseconds, but SQLite returned %i. Maybe SQLite wasn't built with HAVE_USLEEP=1?", requestedSleepInMillseconds, actualSleepInMilliseconds);
        }
        return 1;
    }
    
    return 0;
}

- (void)setMaxBusyRetryTimeInterval:(NSTimeInterval)timeout {
    
    _maxBusyRetryTimeInterval = timeout;
    
    if (!_db) {
        return;
    }
    
    if (timeout > 0) {
        sqlite3_busy_handler(_db, &FMDBDatabaseBusyHandler, (__bridge void *)(self));
    }
    else {
        // turn it off otherwise
        sqlite3_busy_handler(_db, nil, nil);
    }
}

- (NSTimeInterval)maxBusyRetryTimeInterval {
    return _maxBusyRetryTimeInterval;
}


// we no longer make busyRetryTimeout public
// but for folks who don't bother noticing that the interface to FMDatabase changed,
// we'll still implement the method so they don't get suprise crashes
- (int)busyRetryTimeout {
    NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    NSLog(@"FMDB: busyRetryTimeout no longer works, please use maxBusyRetryTimeInterval");
    return -1;
}

- (void)setBusyRetryTimeout:(int)i {
#pragma unused(i)
    NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    NSLog(@"FMDB: setBusyRetryTimeout does nothing, please use setMaxBusyRetryTimeInterval:");
}

#pragma mark Result set functions

- (BOOL)hasOpenResultSets {
    return [_openResultSets count] > 0;
}

- (void)closeOpenResultSets {
    
    //Copy the set so we don't get mutation errors
    NSSet *openSetCopy = FMDBReturnAutoreleased([_openResultSets copy]);
    for (NSValue *rsInWrappedInATastyValueMeal in openSetCopy) {
        FMResultSet *rs = (FMResultSet *)[rsInWrappedInATastyValueMeal pointerValue];
        
        [rs setParentDB:nil];
        [rs close];
        
        [_openResultSets removeObject:rsInWrappedInATastyValueMeal];
    }
}

- (void)resultSetDidClose:(FMResultSet *)resultSet {
    NSValue *setValue = [NSValue valueWithNonretainedObject:resultSet];
    
    [_openResultSets removeObject:setValue];
}

#pragma mark Cached statements

- (void)clearCachedStatements {
    
    for (NSMutableSet *statements in [_cachedStatements objectEnumerator]) {
        for (FMStatement *statement in [statements allObjects]) {
            [statement close];
        }
    }
    
    [_cachedStatements removeAllObjects];
}

- (FMStatement*)cachedStatementForQuery:(NSString*)query {
    
    NSMutableSet* statements = [_cachedStatements objectForKey:query];
    
    return [[statements objectsPassingTest:^BOOL(FMStatement* statement, BOOL *stop) {
        
        *stop = ![statement inUse];
        return *stop;
        
    }] anyObject];
}


- (void)setCachedStatement:(FMStatement*)statement forQuery:(NSString*)query {
    
    query = [query copy]; // in case we got handed in a mutable string...
    [statement setQuery:query];
    
    NSMutableSet* statements = [_cachedStatements objectForKey:query];
    if (!statements) {
        statements = [NSMutableSet set];
    }
    
    [statements addObject:statement];
    
    [_cachedStatements setObject:statements forKey:query];
    
    FMDBRelease(query);
}

#pragma mark Key routines

- (BOOL)rekey:(NSString*)key {
    NSData *keyData = [NSData dataWithBytes:(void *)[key UTF8String] length:(NSUInteger)strlen([key UTF8String])];
    
    return [self rekeyWithData:keyData];
}

- (BOOL)rekeyWithData:(NSData *)keyData {
#ifdef SQLITE_HAS_CODEC
    if (!keyData) {
        return NO;
    }
    
    int rc = sqlite3_rekey(_db, [keyData bytes], (int)[keyData length]);
    
    if (rc != SQLITE_OK) {
        NSLog(@"error on rekey: %d", rc);
        NSLog(@"%@", [self lastErrorMessage]);
    }
    
    return (rc == SQLITE_OK);
#else
#pragma unused(keyData)
    return NO;
#endif
}

- (BOOL)setKey:(NSString*)key {
    NSData *keyData = [NSData dataWithBytes:[key UTF8String] length:(NSUInteger)strlen([key UTF8String])];
    
    return [self setKeyWithData:keyData];
}

- (BOOL)setKeyWithData:(NSData *)keyData {
#ifdef SQLITE_HAS_CODEC
    if (!keyData) {
        return NO;
    }
    
    int rc = sqlite3_key(_db, [keyData bytes], (int)[keyData length]);
    
    return (rc == SQLITE_OK);
#else
#pragma unused(keyData)
    return NO;
#endif
}

#pragma mark Date routines

+ (NSDateFormatter *)storeableDateFormat:(NSString *)format {
    
    NSDateFormatter *result = FMDBReturnAutoreleased([[NSDateFormatter alloc] init]);
    result.dateFormat = format;
    result.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    result.locale = FMDBReturnAutoreleased([[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]);
    return result;
}


- (BOOL)hasDateFormatter {
    return _dateFormat != nil;
}

- (void)setDateFormat:(NSDateFormatter *)format {
    FMDBAutorelease(_dateFormat);
    _dateFormat = FMDBReturnRetained(format);
}

- (NSDate *)dateFromString:(NSString *)s {
    return [_dateFormat dateFromString:s];
}

- (NSString *)stringFromDate:(NSDate *)date {
    return [_dateFormat stringFromDate:date];
}

#pragma mark State of database

- (BOOL)goodConnection {
    
    if (!_db) {
        return NO;
    }
    
    FMResultSet *rs = [self executeQuery:@"select name from sqlite_master where type='table'"];
    
    if (rs) {
        [rs close];
        return YES;
    }
    
    return NO;
}

- (void)warnInUse {
    NSLog(@"The FMDatabase %@ is currently in use.", self);
    
#ifndef NS_BLOCK_ASSERTIONS
    if (_crashOnErrors) {
        NSAssert(false, @"The FMDatabase %@ is currently in use.", self);
        abort();
    }
#endif
}

- (BOOL)databaseExists {
    
    if (!_db) {
        
        NSLog(@"The FMDatabase %@ is not open.", self);
        
#ifndef NS_BLOCK_ASSERTIONS
        if (_crashOnErrors) {
            NSAssert(false, @"The FMDatabase %@ is not open.", self);
            abort();
        }
#endif
        
        return NO;
    }
    
    return YES;
}

#pragma mark Error routines

- (NSString*)lastErrorMessage {
    return [NSString stringWithUTF8String:sqlite3_errmsg(_db)];
}

- (BOOL)hadError {
    int lastErrCode = [self lastErrorCode];
    
    return (lastErrCode > SQLITE_OK && lastErrCode < SQLITE_ROW);
}

- (int)lastErrorCode {
    return sqlite3_errcode(_db);
}

- (NSError*)errorWithMessage:(NSString*)message {
    NSDictionary* errorMessage = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:@"FMDatabase" code:sqlite3_errcode(_db) userInfo:errorMessage];
}

- (NSError*)lastError {
    return [self errorWithMessage:[self lastErrorMessage]];
}

#pragma mark Update information routines

- (sqlite_int64)lastInsertRowId {
    
    if (_isExecutingStatement) {
        [self warnInUse];
        return NO;
    }
    
    _isExecutingStatement = YES;
    
    sqlite_int64 ret = sqlite3_last_insert_rowid(_db);
    
    _isExecutingStatement = NO;
    
    return ret;
}

- (int)changes {
    if (_isExecutingStatement) {
        [self warnInUse];
        return 0;
    }
    
    _isExecutingStatement = YES;
    
    int ret = sqlite3_changes(_db);
    
    _isExecutingStatement = NO;
    
    return ret;
}

#pragma mark SQL manipulation

- (void)bindObject:(id)obj toColumn:(int)idx inStatement:(sqlite3_stmt*)pStmt {
    
    if ((!obj) || ((NSNull *)obj == [NSNull null])) {
        sqlite3_bind_null(pStmt, idx);
    }
    
    // FIXME - someday check the return codes on these binds.
    else if ([obj isKindOfClass:[NSData class]]) {
        const void *bytes = [obj bytes];
        if (!bytes) {
            // it's an empty NSData object, aka [NSData data].
            // Don't pass a NULL pointer, or sqlite will bind a SQL null instead of a blob.
            bytes = "";
        }
        sqlite3_bind_blob(pStmt, idx, bytes, (int)[obj length], SQLITE_STATIC);
    }
    else if ([obj isKindOfClass:[NSDate class]]) {
        if (self.hasDateFormatter)
            sqlite3_bind_text(pStmt, idx, [[self stringFromDate:obj] UTF8String], -1, SQLITE_STATIC);
        else
            sqlite3_bind_double(pStmt, idx, [obj timeIntervalSince1970]);
    }
    else if ([obj isKindOfClass:[NSNumber class]]) {
        
        if (strcmp([obj objCType], @encode(char)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj charValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned char)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj unsignedCharValue]);
        }
        else if (strcmp([obj objCType], @encode(short)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj shortValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned short)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj unsignedShortValue]);
        }
        else if (strcmp([obj objCType], @encode(int)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj intValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned int)) == 0) {
            sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedIntValue]);
        }
        else if (strcmp([obj objCType], @encode(long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, [obj longValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedLongValue]);
        }
        else if (strcmp([obj objCType], @encode(long long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, [obj longLongValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned long long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedLongLongValue]);
        }
        else if (strcmp([obj objCType], @encode(float)) == 0) {
            sqlite3_bind_double(pStmt, idx, [obj floatValue]);
        }
        else if (strcmp([obj objCType], @encode(double)) == 0) {
            sqlite3_bind_double(pStmt, idx, [obj doubleValue]);
        }
        else if (strcmp([obj objCType], @encode(BOOL)) == 0) {
            sqlite3_bind_int(pStmt, idx, ([obj boolValue] ? 1 : 0));
        }
        else {
            sqlite3_bind_text(pStmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
        }
    }
    else {
        sqlite3_bind_text(pStmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
    }
}

- (void)extractSQL:(NSString *)sql argumentsList:(va_list)args intoString:(NSMutableString *)cleanedSQL arguments:(NSMutableArray *)arguments {
    
    NSUInteger length = [sql length];
    unichar last = '\0';
    for (NSUInteger i = 0; i < length; ++i) {
        id arg = nil;
        unichar current = [sql characterAtIndex:i];
        unichar add = current;
        if (last == '%') {
            switch (current) {
                case '@':
                    arg = va_arg(args, id);
                    break;
                case 'c':
                    // warning: second argument to 'va_arg' is of promotable type 'char'; this va_arg has undefined behavior because arguments will be promoted to 'int'
                    arg = [NSString stringWithFormat:@"%c", va_arg(args, int)];
                    break;
                case 's':
                    arg = [NSString stringWithUTF8String:va_arg(args, char*)];
                    break;
                case 'd':
                case 'D':
                case 'i':
                    arg = [NSNumber numberWithInt:va_arg(args, int)];
                    break;
                case 'u':
                case 'U':
                    arg = [NSNumber numberWithUnsignedInt:va_arg(args, unsigned int)];
                    break;
                case 'h':
                    i++;
                    if (i < length && [sql characterAtIndex:i] == 'i') {
                        //  warning: second argument to 'va_arg' is of promotable type 'short'; this va_arg has undefined behavior because arguments will be promoted to 'int'
                        arg = [NSNumber numberWithShort:(short)(va_arg(args, int))];
                    }
                    else if (i < length && [sql characterAtIndex:i] == 'u') {
                        // warning: second argument to 'va_arg' is of promotable type 'unsigned short'; this va_arg has undefined behavior because arguments will be promoted to 'int'
                        arg = [NSNumber numberWithUnsignedShort:(unsigned short)(va_arg(args, uint))];
                    }
                    else {
                        i--;
                    }
                    break;
                case 'q':
                    i++;
                    if (i < length && [sql characterAtIndex:i] == 'i') {
                        arg = [NSNumber numberWithLongLong:va_arg(args, long long)];
                    }
                    else if (i < length && [sql characterAtIndex:i] == 'u') {
                        arg = [NSNumber numberWithUnsignedLongLong:va_arg(args, unsigned long long)];
                    }
                    else {
                        i--;
                    }
                    break;
                case 'f':
                    arg = [NSNumber numberWithDouble:va_arg(args, double)];
                    break;
                case 'g':
                    // warning: second argument to 'va_arg' is of promotable type 'float'; this va_arg has undefined behavior because arguments will be promoted to 'double'
                    arg = [NSNumber numberWithFloat:(float)(va_arg(args, double))];
                    break;
                case 'l':
                    i++;
                    if (i < length) {
                        unichar next = [sql characterAtIndex:i];
                        if (next == 'l') {
                            i++;
                            if (i < length && [sql characterAtIndex:i] == 'd') {
                                //%lld
                                arg = [NSNumber numberWithLongLong:va_arg(args, long long)];
                            }
                            else if (i < length && [sql characterAtIndex:i] == 'u') {
                                //%llu
                                arg = [NSNumber numberWithUnsignedLongLong:va_arg(args, unsigned long long)];
                            }
                            else {
                                i--;
                            }
                        }
                        else if (next == 'd') {
                            //%ld
                            arg = [NSNumber numberWithLong:va_arg(args, long)];
                        }
                        else if (next == 'u') {
                            //%lu
                            arg = [NSNumber numberWithUnsignedLong:va_arg(args, unsigned long)];
                        }
                        else {
                            i--;
                        }
                    }
                    else {
                        i--;
                    }
                    break;
                default:
                    // something else that we can't interpret. just pass it on through like normal
                    break;
            }
        }
        else if (current == '%') {
            // percent sign; skip this character
            add = '\0';
        }
        
        if (arg != nil) {
            [cleanedSQL appendString:@"?"];
            [arguments addObject:arg];
        }
        else if (add == (unichar)'@' && last == (unichar) '%') {
            [cleanedSQL appendFormat:@"NULL"];
        }
        else if (add != '\0') {
            [cleanedSQL appendFormat:@"%C", add];
        }
        last = current;
    }
}

#pragma mark Execute queries

- (FMResultSet *)executeQuery:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments {
    return [self executeQuery:sql withArgumentsInArray:nil orDictionary:arguments orVAList:nil];
}

- (FMResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray*)arrayArgs orDictionary:(NSDictionary *)dictionaryArgs orVAList:(va_list)args {
    
    if (![self databaseExists]) {
        return 0x00;
    }
    
    if (_isExecutingStatement) {
        [self warnInUse];
        return 0x00;
    }
    
    _isExecutingStatement = YES;
    
    int rc                  = 0x00;
    sqlite3_stmt *pStmt     = 0x00;
    FMStatement *statement  = 0x00;
    FMResultSet *rs         = 0x00;
    
    if (_traceExecution && sql) {
        NSLog(@"%@ executeQuery: %@", self, sql);
    }
    
    if (_shouldCacheStatements) {
        statement = [self cachedStatementForQuery:sql];
        pStmt = statement ? [statement statement] : 0x00;
        [statement reset];
    }
    
    if (!pStmt) {
        
        rc = sqlite3_prepare_v2(_db, [sql UTF8String], -1, &pStmt, 0);
        
        if (SQLITE_OK != rc) {
            if (_logsErrors) {
                NSLog(@"DB Error: %d \"%@\"", [self lastErrorCode], [self lastErrorMessage]);
                NSLog(@"DB Query: %@", sql);
                NSLog(@"DB Path: %@", _databasePath);
            }
            
            if (_crashOnErrors) {
                NSAssert(false, @"DB Error: %d \"%@\"", [self lastErrorCode], [self lastErrorMessage]);
                abort();
            }
            
            sqlite3_finalize(pStmt);
            _isExecutingStatement = NO;
            return nil;
        }
    }
    
    id obj;
    int idx = 0;
    int queryCount = sqlite3_bind_parameter_count(pStmt); // pointed out by Dominic Yu (thanks!)
    
    // If dictionaryArgs is passed in, that means we are using sqlite's named parameter support
    if (dictionaryArgs) {
        
        for (NSString *dictionaryKey in [dictionaryArgs allKeys]) {
            
            // Prefix the key with a colon.
            NSString *parameterName = [[NSString alloc] initWithFormat:@":%@", dictionaryKey];
            
            if (_traceExecution) {
                NSLog(@"%@ = %@", parameterName, [dictionaryArgs objectForKey:dictionaryKey]);
            }
            
            // Get the index for the parameter name.
            int namedIdx = sqlite3_bind_parameter_index(pStmt, [parameterName UTF8String]);
            
            FMDBRelease(parameterName);
            
            if (namedIdx > 0) {
                // Standard binding from here.
                [self bindObject:[dictionaryArgs objectForKey:dictionaryKey] toColumn:namedIdx inStatement:pStmt];
                // increment the binding count, so our check below works out
                idx++;
            }
            else {
                NSLog(@"Could not find index for %@", dictionaryKey);
            }
        }
    }
    else {
        
        while (idx < queryCount) {
            
            if (arrayArgs && idx < (int)[arrayArgs count]) {
                obj = [arrayArgs objectAtIndex:(NSUInteger)idx];
            }
            else if (args) {
                obj = va_arg(args, id);
            }
            else {
                //We ran out of arguments
                break;
            }
            
            if (_traceExecution) {
                if ([obj isKindOfClass:[NSData class]]) {
                    NSLog(@"data: %ld bytes", (unsigned long)[(NSData*)obj length]);
                }
                else {
                    NSLog(@"obj: %@", obj);
                }
            }
            
            idx++;
            
            [self bindObject:obj toColumn:idx inStatement:pStmt];
        }
    }
    
    if (idx != queryCount) {
        NSLog(@"Error: the bind count is not correct for the # of variables (executeQuery)");
        sqlite3_finalize(pStmt);
        _isExecutingStatement = NO;
        return nil;
    }
    
    FMDBRetain(statement); // to balance the release below
    
    if (!statement) {
        statement = [[FMStatement alloc] init];
        [statement setStatement:pStmt];
        
        if (_shouldCacheStatements && sql) {
            [self setCachedStatement:statement forQuery:sql];
        }
    }
    
    // the statement gets closed in rs's dealloc or [rs close];
    rs = [FMResultSet resultSetWithStatement:statement usingParentDatabase:self];
    [rs setQuery:sql];
    
    NSValue *openResultSet = [NSValue valueWithNonretainedObject:rs];
    [_openResultSets addObject:openResultSet];
    
    [statement setUseCount:[statement useCount] + 1];
    
    FMDBRelease(statement);
    
    _isExecutingStatement = NO;
    
    return rs;
}

- (FMResultSet *)executeQuery:(NSString*)sql, ... {
    va_list args;
    va_start(args, sql);
    
    id result = [self executeQuery:sql withArgumentsInArray:nil orDictionary:nil orVAList:args];
    
    va_end(args);
    return result;
}

- (FMResultSet *)executeQueryWithFormat:(NSString*)format, ... {
    va_list args;
    va_start(args, format);
    
    NSMutableString *sql = [NSMutableString stringWithCapacity:[format length]];
    NSMutableArray *arguments = [NSMutableArray array];
    [self extractSQL:format argumentsList:args intoString:sql arguments:arguments];
    
    va_end(args);
    
    return [self executeQuery:sql withArgumentsInArray:arguments];
}

- (FMResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {
    return [self executeQuery:sql withArgumentsInArray:arguments orDictionary:nil orVAList:nil];
}

- (FMResultSet *)executeQuery:(NSString *)sql values:(NSArray *)values error:(NSError * __autoreleasing *)error {
    FMResultSet *rs = [self executeQuery:sql withArgumentsInArray:values orDictionary:nil orVAList:nil];
    if (!rs && error) {
        *error = [self lastError];
    }
    return rs;
}

- (FMResultSet *)executeQuery:(NSString*)sql withVAList:(va_list)args {
    return [self executeQuery:sql withArgumentsInArray:nil orDictionary:nil orVAList:args];
}

#pragma mark Execute updates

- (BOOL)executeUpdate:(NSString*)sql error:(NSError**)outErr withArgumentsInArray:(NSArray*)arrayArgs orDictionary:(NSDictionary *)dictionaryArgs orVAList:(va_list)args {
    
    if (![self databaseExists]) {
        return NO;
    }
    
    if (_isExecutingStatement) {
        [self warnInUse];
        return NO;
    }
    
    _isExecutingStatement = YES;
    
    int rc                   = 0x00;
    sqlite3_stmt *pStmt      = 0x00;
    FMStatement *cachedStmt  = 0x00;
    
    if (_traceExecution && sql) {
        NSLog(@"%@ executeUpdate: %@", self, sql);
    }
    
    if (_shouldCacheStatements) {
        cachedStmt = [self cachedStatementForQuery:sql];
        pStmt = cachedStmt ? [cachedStmt statement] : 0x00;
        [cachedStmt reset];
    }
    
    if (!pStmt) {
        rc = sqlite3_prepare_v2(_db, [sql UTF8String], -1, &pStmt, 0);
        
        if (SQLITE_OK != rc) {
            if (_logsErrors) {
                NSLog(@"DB Error: %d \"%@\"", [self lastErrorCode], [self lastErrorMessage]);
                NSLog(@"DB Query: %@", sql);
                NSLog(@"DB Path: %@", _databasePath);
            }
            
            if (_crashOnErrors) {
                NSAssert(false, @"DB Error: %d \"%@\"", [self lastErrorCode], [self lastErrorMessage]);
                abort();
            }
            
            if (outErr) {
                *outErr = [self errorWithMessage:[NSString stringWithUTF8String:sqlite3_errmsg(_db)]];
            }
            
            sqlite3_finalize(pStmt);
            
            _isExecutingStatement = NO;
            return NO;
        }
    }
    
    id obj;
    int idx = 0;
    int queryCount = sqlite3_bind_parameter_count(pStmt);
    
    // If dictionaryArgs is passed in, that means we are using sqlite's named parameter support
    if (dictionaryArgs) {
        
        for (NSString *dictionaryKey in [dictionaryArgs allKeys]) {
            
            // Prefix the key with a colon.
            NSString *parameterName = [[NSString alloc] initWithFormat:@":%@", dictionaryKey];
            
            if (_traceExecution) {
                NSLog(@"%@ = %@", parameterName, [dictionaryArgs objectForKey:dictionaryKey]);
            }
            // Get the index for the parameter name.
            int namedIdx = sqlite3_bind_parameter_index(pStmt, [parameterName UTF8String]);
            
            FMDBRelease(parameterName);
            
            if (namedIdx > 0) {
                // Standard binding from here.
                [self bindObject:[dictionaryArgs objectForKey:dictionaryKey] toColumn:namedIdx inStatement:pStmt];
                
                // increment the binding count, so our check below works out
                idx++;
            }
            else {
                NSString *message = [NSString stringWithFormat:@"Could not find index for %@", dictionaryKey];
                
                if (_logsErrors) {
                    NSLog(@"%@", message);
                }
                if (outErr) {
                    *outErr = [self errorWithMessage:message];
                }
            }
        }
    }
    else {
        
        while (idx < queryCount) {
            
            if (arrayArgs && idx < (int)[arrayArgs count]) {
                obj = [arrayArgs objectAtIndex:(NSUInteger)idx];
            }
            else if (args) {
                obj = va_arg(args, id);
            }
            else {
                //We ran out of arguments
                break;
            }
            
            if (_traceExecution) {
                if ([obj isKindOfClass:[NSData class]]) {
                    NSLog(@"data: %ld bytes", (unsigned long)[(NSData*)obj length]);
                }
                else {
                    NSLog(@"obj: %@", obj);
                }
            }
            
            idx++;
            
            [self bindObject:obj toColumn:idx inStatement:pStmt];
        }
    }
    
    
    if (idx != queryCount) {
        NSString *message = [NSString stringWithFormat:@"Error: the bind count (%d) is not correct for the # of variables in the query (%d) (%@) (executeUpdate)", idx, queryCount, sql];
        if (_logsErrors) {
            NSLog(@"%@", message);
        }
        if (outErr) {
            *outErr = [self errorWithMessage:message];
        }
        
        sqlite3_finalize(pStmt);
        _isExecutingStatement = NO;
        return NO;
    }
    
    /* Call sqlite3_step() to run the virtual machine. Since the SQL being
     ** executed is not a SELECT statement, we assume no data will be returned.
     */
    
    rc      = sqlite3_step(pStmt);
    
    if (SQLITE_DONE == rc) {
        // all is well, let's return.
    }
    else if (SQLITE_INTERRUPT == rc) {
        if (_logsErrors) {
            NSLog(@"Error calling sqlite3_step. Query was interrupted (%d: %s) SQLITE_INTERRUPT", rc, sqlite3_errmsg(_db));
            NSLog(@"DB Query: %@", sql);
        }
    }
    else if (rc == SQLITE_ROW) {
        NSString *message = [NSString stringWithFormat:@"A executeUpdate is being called with a query string '%@'", sql];
        if (_logsErrors) {
            NSLog(@"%@", message);
            NSLog(@"DB Query: %@", sql);
        }
        if (outErr) {
            *outErr = [self errorWithMessage:message];
        }
    }
    else {
        if (outErr) {
            *outErr = [self errorWithMessage:[NSString stringWithUTF8String:sqlite3_errmsg(_db)]];
        }
        
        if (SQLITE_ERROR == rc) {
            if (_logsErrors) {
                NSLog(@"Error calling sqlite3_step (%d: %s) SQLITE_ERROR", rc, sqlite3_errmsg(_db));
                NSLog(@"DB Query: %@", sql);
            }
        }
        else if (SQLITE_MISUSE == rc) {
            // uh oh.
            if (_logsErrors) {
                NSLog(@"Error calling sqlite3_step (%d: %s) SQLITE_MISUSE", rc, sqlite3_errmsg(_db));
                NSLog(@"DB Query: %@", sql);
            }
        }
        else {
            // wtf?
            if (_logsErrors) {
                NSLog(@"Unknown error calling sqlite3_step (%d: %s) eu", rc, sqlite3_errmsg(_db));
                NSLog(@"DB Query: %@", sql);
            }
        }
    }
    
    if (_shouldCacheStatements && !cachedStmt) {
        cachedStmt = [[FMStatement alloc] init];
        
        [cachedStmt setStatement:pStmt];
        
        [self setCachedStatement:cachedStmt forQuery:sql];
        
        FMDBRelease(cachedStmt);
    }
    
    int closeErrorCode;
    
    if (cachedStmt) {
        [cachedStmt setUseCount:[cachedStmt useCount] + 1];
        closeErrorCode = sqlite3_reset(pStmt);
    }
    else {
        /* Finalize the virtual machine. This releases all memory and other
         ** resources allocated by the sqlite3_prepare() call above.
         */
        closeErrorCode = sqlite3_finalize(pStmt);
    }
    
    if (closeErrorCode != SQLITE_OK) {
        if (_logsErrors) {
            NSLog(@"Unknown error finalizing or resetting statement (%d: %s)", closeErrorCode, sqlite3_errmsg(_db));
            NSLog(@"DB Query: %@", sql);
        }
    }
    
    _isExecutingStatement = NO;
    return (rc == SQLITE_DONE || rc == SQLITE_OK);
}


- (BOOL)executeUpdate:(NSString*)sql, ... {
    va_list args;
    va_start(args, sql);
    
    BOOL result = [self executeUpdate:sql error:nil withArgumentsInArray:nil orDictionary:nil orVAList:args];
    
    va_end(args);
    return result;
}

- (BOOL)executeUpdate:(NSString*)sql withArgumentsInArray:(NSArray *)arguments {
    return [self executeUpdate:sql error:nil withArgumentsInArray:arguments orDictionary:nil orVAList:nil];
}

- (BOOL)executeUpdate:(NSString*)sql values:(NSArray *)values error:(NSError * __autoreleasing *)error {
    return [self executeUpdate:sql error:error withArgumentsInArray:values orDictionary:nil orVAList:nil];
}

- (BOOL)executeUpdate:(NSString*)sql withParameterDictionary:(NSDictionary *)arguments {
    return [self executeUpdate:sql error:nil withArgumentsInArray:nil orDictionary:arguments orVAList:nil];
}

- (BOOL)executeUpdate:(NSString*)sql withVAList:(va_list)args {
    return [self executeUpdate:sql error:nil withArgumentsInArray:nil orDictionary:nil orVAList:args];
}

- (BOOL)executeUpdateWithFormat:(NSString*)format, ... {
    va_list args;
    va_start(args, format);
    
    NSMutableString *sql      = [NSMutableString stringWithCapacity:[format length]];
    NSMutableArray *arguments = [NSMutableArray array];
    
    [self extractSQL:format argumentsList:args intoString:sql arguments:arguments];
    
    va_end(args);
    
    return [self executeUpdate:sql withArgumentsInArray:arguments];
}


int FMDBExecuteBulkSQLCallback(void *theBlockAsVoid, int columns, char **values, char **names); // shhh clang.
int FMDBExecuteBulkSQLCallback(void *theBlockAsVoid, int columns, char **values, char **names) {
    
    if (!theBlockAsVoid) {
        return SQLITE_OK;
    }
    
    int (^execCallbackBlock)(NSDictionary *resultsDictionary) = (__bridge int (^)(NSDictionary *__strong))(theBlockAsVoid);
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:(NSUInteger)columns];
    
    for (NSInteger i = 0; i < columns; i++) {
        NSString *key = [NSString stringWithUTF8String:names[i]];
        id value = values[i] ? [NSString stringWithUTF8String:values[i]] : [NSNull null];
        [dictionary setObject:value forKey:key];
    }
    
    return execCallbackBlock(dictionary);
}

- (BOOL)executeStatements:(NSString *)sql {
    return [self executeStatements:sql withResultBlock:nil];
}

- (BOOL)executeStatements:(NSString *)sql withResultBlock:(FMDBExecuteStatementsCallbackBlock)block {
    
    int rc;
    char *errmsg = nil;
    
    rc = sqlite3_exec([self sqliteHandle], [sql UTF8String], block ? FMDBExecuteBulkSQLCallback : nil, (__bridge void *)(block), &errmsg);
    
    if (errmsg && [self logsErrors]) {
        NSLog(@"Error inserting batch: %s", errmsg);
        sqlite3_free(errmsg);
    }
    
    return (rc == SQLITE_OK);
}

- (BOOL)executeUpdate:(NSString*)sql withErrorAndBindings:(NSError**)outErr, ... {
    
    va_list args;
    va_start(args, outErr);
    
    BOOL result = [self executeUpdate:sql error:outErr withArgumentsInArray:nil orDictionary:nil orVAList:args];
    
    va_end(args);
    return result;
}


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (BOOL)update:(NSString*)sql withErrorAndBindings:(NSError**)outErr, ... {
    va_list args;
    va_start(args, outErr);
    
    BOOL result = [self executeUpdate:sql error:outErr withArgumentsInArray:nil orDictionary:nil orVAList:args];
    
    va_end(args);
    return result;
}

#pragma clang diagnostic pop

#pragma mark Transactions

- (BOOL)rollback {
    BOOL b = [self executeUpdate:@"rollback transaction"];
    
    if (b) {
        _inTransaction = NO;
    }
    
    return b;
}

- (BOOL)commit {
    BOOL b =  [self executeUpdate:@"commit transaction"];
    
    if (b) {
        _inTransaction = NO;
    }
    
    return b;
}

- (BOOL)beginDeferredTransaction {
    
    BOOL b = [self executeUpdate:@"begin deferred transaction"];
    if (b) {
        _inTransaction = YES;
    }
    
    return b;
}

- (BOOL)beginTransaction {
    
    BOOL b = [self executeUpdate:@"begin exclusive transaction"];
    if (b) {
        _inTransaction = YES;
    }
    
    return b;
}

- (BOOL)inTransaction {
    return _inTransaction;
}

- (BOOL)interrupt
{
    if (_db) {
        sqlite3_interrupt([self sqliteHandle]);
        return YES;
    }
    return NO;
}

static NSString *FMDBEscapeSavePointName(NSString *savepointName) {
    return [savepointName stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
}

- (BOOL)startSavePointWithName:(NSString*)name error:(NSError**)outErr {
#if SQLITE_VERSION_NUMBER >= 3007000
    NSParameterAssert(name);
    
    NSString *sql = [NSString stringWithFormat:@"savepoint '%@';", FMDBEscapeSavePointName(name)];
    
    return [self executeUpdate:sql error:outErr withArgumentsInArray:nil orDictionary:nil orVAList:nil];
#else
    NSString *errorMessage = NSLocalizedString(@"Save point functions require SQLite 3.7", nil);
    if (self.logsErrors) NSLog(@"%@", errorMessage);
    return NO;
#endif
}

- (BOOL)releaseSavePointWithName:(NSString*)name error:(NSError**)outErr {
#if SQLITE_VERSION_NUMBER >= 3007000
    NSParameterAssert(name);
    
    NSString *sql = [NSString stringWithFormat:@"release savepoint '%@';", FMDBEscapeSavePointName(name)];
    
    return [self executeUpdate:sql error:outErr withArgumentsInArray:nil orDictionary:nil orVAList:nil];
#else
    NSString *errorMessage = NSLocalizedString(@"Save point functions require SQLite 3.7", nil);
    if (self.logsErrors) NSLog(@"%@", errorMessage);
    return NO;
#endif
}

- (BOOL)rollbackToSavePointWithName:(NSString*)name error:(NSError**)outErr {
#if SQLITE_VERSION_NUMBER >= 3007000
    NSParameterAssert(name);
    
    NSString *sql = [NSString stringWithFormat:@"rollback transaction to savepoint '%@';", FMDBEscapeSavePointName(name)];
    
    return [self executeUpdate:sql error:outErr withArgumentsInArray:nil orDictionary:nil orVAList:nil];
#else
    NSString *errorMessage = NSLocalizedString(@"Save point functions require SQLite 3.7", nil);
    if (self.logsErrors) NSLog(@"%@", errorMessage);
    return NO;
#endif
}

- (NSError*)inSavePoint:(void (^)(BOOL *rollback))block {
#if SQLITE_VERSION_NUMBER >= 3007000
    static unsigned long savePointIdx = 0;
    
    NSString *name = [NSString stringWithFormat:@"dbSavePoint%ld", savePointIdx++];
    
    BOOL shouldRollback = NO;
    
    NSError *err = 0x00;
    
    if (![self startSavePointWithName:name error:&err]) {
        return err;
    }
    
    if (block) {
        block(&shouldRollback);
    }
    
    if (shouldRollback) {
        // We need to rollback and release this savepoint to remove it
        [self rollbackToSavePointWithName:name error:&err];
    }
    [self releaseSavePointWithName:name error:&err];
    
    return err;
#else
    NSString *errorMessage = NSLocalizedString(@"Save point functions require SQLite 3.7", nil);
    if (self.logsErrors) NSLog(@"%@", errorMessage);
    return [NSError errorWithDomain:@"FMDatabase" code:0 userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
#endif
}


#pragma mark Cache statements

- (BOOL)shouldCacheStatements {
    return _shouldCacheStatements;
}

- (void)setShouldCacheStatements:(BOOL)value {
    
    _shouldCacheStatements = value;
    
    if (_shouldCacheStatements && !_cachedStatements) {
        [self setCachedStatements:[NSMutableDictionary dictionary]];
    }
    
    if (!_shouldCacheStatements) {
        [self setCachedStatements:nil];
    }
}

#pragma mark Callback function

void FMDBBlockSQLiteCallBackFunction(sqlite3_context *context, int argc, sqlite3_value **argv); // -Wmissing-prototypes
void FMDBBlockSQLiteCallBackFunction(sqlite3_context *context, int argc, sqlite3_value **argv) {
#if ! __has_feature(objc_arc)
    void (^block)(sqlite3_context *context, int argc, sqlite3_value **argv) = (id)sqlite3_user_data(context);
#else
    void (^block)(sqlite3_context *context, int argc, sqlite3_value **argv) = (__bridge id)sqlite3_user_data(context);
#endif
    if (block) {
        block(context, argc, argv);
    }
}


- (void)makeFunctionNamed:(NSString*)name maximumArguments:(int)count withBlock:(void (^)(void *context, int argc, void **argv))block {
    
    if (!_openFunctions) {
        _openFunctions = [NSMutableSet new];
    }
    
    id b = FMDBReturnAutoreleased([block copy]);
    
    [_openFunctions addObject:b];
    
    /* I tried adding custom functions to release the block when the connection is destroyed- but they seemed to never be called, so we use _openFunctions to store the values instead. */
#if ! __has_feature(objc_arc)
    sqlite3_create_function([self sqliteHandle], [name UTF8String], count, SQLITE_UTF8, (void*)b, &FMDBBlockSQLiteCallBackFunction, 0x00, 0x00);
#else
    sqlite3_create_function([self sqliteHandle], [name UTF8String], count, SQLITE_UTF8, (__bridge void*)b, &FMDBBlockSQLiteCallBackFunction, 0x00, 0x00);
#endif
}

@end



@implementation FMStatement
@synthesize statement=_statement;
@synthesize query=_query;
@synthesize useCount=_useCount;
@synthesize inUse=_inUse;

- (void)finalize {
    [self close];
    [super finalize];
}

- (void)dealloc {
    [self close];
    FMDBRelease(_query);
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)close {
    if (_statement) {
        sqlite3_finalize(_statement);
        _statement = 0x00;
    }
    
    _inUse = NO;
}

- (void)reset {
    if (_statement) {
        sqlite3_reset(_statement);
    }
    
    _inUse = NO;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %ld hit(s) for query %@", [super description], _useCount, _query];
}


@end

//
//  FMDatabaseAdditions.m
//  fmdb
//
//  Created by August Mueller on 10/30/05.
//  Copyright 2005 Flying Meat Inc.. All rights reserved.
//

#import "TargetConditionals.h"

@interface FMDatabase (PrivateStuff)
- (FMResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray*)arrayArgs orDictionary:(NSDictionary *)dictionaryArgs orVAList:(va_list)args;
@end

@implementation FMDatabase (FMDatabaseAdditions)

#define RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(type, sel)             \
va_list args;                                                        \
va_start(args, query);                                               \
FMResultSet *resultSet = [self executeQuery:query withArgumentsInArray:0x00 orDictionary:0x00 orVAList:args];   \
va_end(args);                                                        \
if (![resultSet next]) { return (type)0; }                           \
type ret = [resultSet sel:0];                                        \
[resultSet close];                                                   \
[resultSet setParentDB:nil];                                         \
return ret;


- (NSString*)stringForQuery:(NSString*)query, ... {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(NSString *, stringForColumnIndex);
}

- (int)intForQuery:(NSString*)query, ... {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(int, intForColumnIndex);
}

- (long)longForQuery:(NSString*)query, ... {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(long, longForColumnIndex);
}

- (BOOL)boolForQuery:(NSString*)query, ... {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(BOOL, boolForColumnIndex);
}

- (double)doubleForQuery:(NSString*)query, ... {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(double, doubleForColumnIndex);
}

- (NSData*)dataForQuery:(NSString*)query, ... {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(NSData *, dataForColumnIndex);
}

- (NSDate*)dateForQuery:(NSString*)query, ... {
    RETURN_RESULT_FOR_QUERY_WITH_SELECTOR(NSDate *, dateForColumnIndex);
}


- (BOOL)tableExists:(NSString*)tableName {
    
    tableName = [tableName lowercaseString];
    
    FMResultSet *rs = [self executeQuery:@"select [sql] from sqlite_master where [type] = 'table' and lower(name) = ?", tableName];
    
    //if at least one next exists, table exists
    BOOL returnBool = [rs next];
    
    //close and free object
    [rs close];
    
    return returnBool;
}

/*
 get table with list of tables: result colums: type[STRING], name[STRING],tbl_name[STRING],rootpage[INTEGER],sql[STRING]
 check if table exist in database  (patch from OZLB)
 */
- (FMResultSet*)getSchema {
    
    //result colums: type[STRING], name[STRING],tbl_name[STRING],rootpage[INTEGER],sql[STRING]
    FMResultSet *rs = [self executeQuery:@"SELECT type, name, tbl_name, rootpage, sql FROM (SELECT * FROM sqlite_master UNION ALL SELECT * FROM sqlite_temp_master) WHERE type != 'meta' AND name NOT LIKE 'sqlite_%' ORDER BY tbl_name, type DESC, name"];
    
    return rs;
}

/*
 get table schema: result colums: cid[INTEGER], name,type [STRING], notnull[INTEGER], dflt_value[],pk[INTEGER]
 */
- (FMResultSet*)getTableSchema:(NSString*)tableName {
    
    //result colums: cid[INTEGER], name,type [STRING], notnull[INTEGER], dflt_value[],pk[INTEGER]
    FMResultSet *rs = [self executeQuery:[NSString stringWithFormat: @"pragma table_info('%@')", tableName]];
    
    return rs;
}

- (BOOL)columnExists:(NSString*)columnName inTableWithName:(NSString*)tableName {
    
    BOOL returnBool = NO;
    
    tableName  = [tableName lowercaseString];
    columnName = [columnName lowercaseString];
    
    FMResultSet *rs = [self getTableSchema:tableName];
    
    //check if column is present in table schema
    while ([rs next]) {
        if ([[[rs stringForColumn:@"name"] lowercaseString] isEqualToString:columnName]) {
            returnBool = YES;
            break;
        }
    }
    
    //If this is not done FMDatabase instance stays out of pool
    [rs close];
    
    return returnBool;
}



- (uint32_t)applicationID {
#if SQLITE_VERSION_NUMBER >= 3007017
    uint32_t r = 0;
    
    FMResultSet *rs = [self executeQuery:@"pragma application_id"];
    
    if ([rs next]) {
        r = (uint32_t)[rs longLongIntForColumnIndex:0];
    }
    
    [rs close];
    
    return r;
#else
    NSString *errorMessage = NSLocalizedString(@"Application ID functions require SQLite 3.7.17", nil);
    if (self.logsErrors) NSLog(@"%@", errorMessage);
    return 0;
#endif
}

- (void)setApplicationID:(uint32_t)appID {
#if SQLITE_VERSION_NUMBER >= 3007017
    NSString *query = [NSString stringWithFormat:@"pragma application_id=%d", appID];
    FMResultSet *rs = [self executeQuery:query];
    [rs next];
    [rs close];
#else
    NSString *errorMessage = NSLocalizedString(@"Application ID functions require SQLite 3.7.17", nil);
    if (self.logsErrors) NSLog(@"%@", errorMessage);
#endif
}


#if TARGET_OS_MAC && !TARGET_OS_IPHONE

- (NSString*)applicationIDString {
#if SQLITE_VERSION_NUMBER >= 3007017
    NSString *s = NSFileTypeForHFSTypeCode([self applicationID]);
    
    assert([s length] == 6);
    
    s = [s substringWithRange:NSMakeRange(1, 4)];
    
    
    return s;
#else
    NSString *errorMessage = NSLocalizedString(@"Application ID functions require SQLite 3.7.17", nil);
    if (self.logsErrors) NSLog(@"%@", errorMessage);
    return nil;
#endif
}

- (void)setApplicationIDString:(NSString*)s {
#if SQLITE_VERSION_NUMBER >= 3007017
    if ([s length] != 4) {
        NSLog(@"setApplicationIDString: string passed is not exactly 4 chars long. (was %ld)", [s length]);
    }
    
    [self setApplicationID:NSHFSTypeCodeFromFileType([NSString stringWithFormat:@"'%@'", s])];
#else
    NSString *errorMessage = NSLocalizedString(@"Application ID functions require SQLite 3.7.17", nil);
    if (self.logsErrors) NSLog(@"%@", errorMessage);
#endif
}

#endif

- (uint32_t)userVersion {
    uint32_t r = 0;
    
    FMResultSet *rs = [self executeQuery:@"pragma user_version"];
    
    if ([rs next]) {
        r = (uint32_t)[rs longLongIntForColumnIndex:0];
    }
    
    [rs close];
    return r;
}

- (void)setUserVersion:(uint32_t)version {
    NSString *query = [NSString stringWithFormat:@"pragma user_version = %d", version];
    FMResultSet *rs = [self executeQuery:query];
    [rs next];
    [rs close];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (BOOL)columnExists:(NSString*)tableName columnName:(NSString*)columnName __attribute__ ((deprecated)) {
    return [self columnExists:columnName inTableWithName:tableName];
}

#pragma clang diagnostic pop


- (BOOL)validateSQL:(NSString*)sql error:(NSError**)error {
    sqlite3_stmt *pStmt = NULL;
    BOOL validationSucceeded = YES;
    
    int rc = sqlite3_prepare_v2(_db, [sql UTF8String], -1, &pStmt, 0);
    if (rc != SQLITE_OK) {
        validationSucceeded = NO;
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:[self lastErrorCode]
                                     userInfo:[NSDictionary dictionaryWithObject:[self lastErrorMessage]
                                                                          forKey:NSLocalizedDescriptionKey]];
        }
    }
    
    sqlite3_finalize(pStmt);
    
    return validationSucceeded;
}

@end
//
//  FMDatabasePool.m
//  fmdb
//
//  Created by August Mueller on 6/22/11.
//  Copyright 2011 Flying Meat Inc. All rights reserved.
//

@interface FMDatabasePool()

- (void)pushDatabaseBackInPool:(FMDatabase*)db;
- (FMDatabase*)db;

@end


@implementation FMDatabasePool
@synthesize path=_path;
@synthesize delegate=_delegate;
@synthesize maximumNumberOfDatabasesToCreate=_maximumNumberOfDatabasesToCreate;
@synthesize openFlags=_openFlags;


+ (instancetype)databasePoolWithPath:(NSString*)aPath {
    return FMDBReturnAutoreleased([[self alloc] initWithPath:aPath]);
}

+ (instancetype)databasePoolWithPath:(NSString*)aPath flags:(int)openFlags {
    return FMDBReturnAutoreleased([[self alloc] initWithPath:aPath flags:openFlags]);
}

- (instancetype)initWithPath:(NSString*)aPath flags:(int)openFlags vfs:(NSString *)vfsName {
    
    self = [super init];
    
    if (self != nil) {
        _path               = [aPath copy];
        _lockQueue          = dispatch_queue_create([[NSString stringWithFormat:@"fmdb.%@", self] UTF8String], NULL);
        _databaseInPool     = FMDBReturnRetained([NSMutableArray array]);
        _databaseOutPool    = FMDBReturnRetained([NSMutableArray array]);
        _openFlags          = openFlags;
        _vfsName            = [vfsName copy];
    }
    
    return self;
}

- (instancetype)initWithPath:(NSString*)aPath flags:(int)openFlags {
    return [self initWithPath:aPath flags:openFlags vfs:nil];
}

- (instancetype)initWithPath:(NSString*)aPath
{
    // default flags for sqlite3_open
    return [self initWithPath:aPath flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE];
}

- (instancetype)init {
    return [self initWithPath:nil];
}

+ (Class)databaseClass {
    return [FMDatabase class];
}

- (void)dealloc {
    
    _delegate = 0x00;
    FMDBRelease(_path);
    FMDBRelease(_databaseInPool);
    FMDBRelease(_databaseOutPool);
    
    if (_lockQueue) {
        FMDBDispatchQueueRelease(_lockQueue);
        _lockQueue = 0x00;
    }
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}


- (void)executeLocked:(void (^)(void))aBlock {
    dispatch_sync(_lockQueue, aBlock);
}

- (void)pushDatabaseBackInPool:(FMDatabase*)db {
    
    if (!db) { // db can be null if we set an upper bound on the # of databases to create.
        return;
    }
    
    [self executeLocked:^() {
        
        if ([self->_databaseInPool containsObject:db]) {
            [[NSException exceptionWithName:@"Database already in pool" reason:@"The FMDatabase being put back into the pool is already present in the pool" userInfo:nil] raise];
        }
        
        [self->_databaseInPool addObject:db];
        [self->_databaseOutPool removeObject:db];
        
    }];
}

- (FMDatabase*)db {
    
    __block FMDatabase *db;
    
    
    [self executeLocked:^() {
        db = [self->_databaseInPool lastObject];
        
        BOOL shouldNotifyDelegate = NO;
        
        if (db) {
            [self->_databaseOutPool addObject:db];
            [self->_databaseInPool removeLastObject];
        }
        else {
            
            if (self->_maximumNumberOfDatabasesToCreate) {
                NSUInteger currentCount = [self->_databaseOutPool count] + [self->_databaseInPool count];
                
                if (currentCount >= self->_maximumNumberOfDatabasesToCreate) {
                    NSLog(@"Maximum number of databases (%ld) has already been reached!", (long)currentCount);
                    return;
                }
            }
            
            db = [[[self class] databaseClass] databaseWithPath:self->_path];
            shouldNotifyDelegate = YES;
        }
        
        //This ensures that the db is opened before returning
#if SQLITE_VERSION_NUMBER >= 3005000
        BOOL success = [db openWithFlags:self->_openFlags vfs:self->_vfsName];
#else
        BOOL success = [db open];
#endif
        if (success) {
            if ([self->_delegate respondsToSelector:@selector(databasePool:shouldAddDatabaseToPool:)] && ![self->_delegate databasePool:self shouldAddDatabaseToPool:db]) {
                [db close];
                db = 0x00;
            }
            else {
                //It should not get added in the pool twice if lastObject was found
                if (![self->_databaseOutPool containsObject:db]) {
                    [self->_databaseOutPool addObject:db];
                    
                    if (shouldNotifyDelegate && [self->_delegate respondsToSelector:@selector(databasePool:didAddDatabase:)]) {
                        [self->_delegate databasePool:self didAddDatabase:db];
                    }
                }
            }
        }
        else {
            NSLog(@"Could not open up the database at path %@", self->_path);
            db = 0x00;
        }
    }];
    
    return db;
}

- (NSUInteger)countOfCheckedInDatabases {
    
    __block NSUInteger count;
    
    [self executeLocked:^() {
        count = [self->_databaseInPool count];
    }];
    
    return count;
}

- (NSUInteger)countOfCheckedOutDatabases {
    
    __block NSUInteger count;
    
    [self executeLocked:^() {
        count = [self->_databaseOutPool count];
    }];
    
    return count;
}

- (NSUInteger)countOfOpenDatabases {
    __block NSUInteger count;
    
    [self executeLocked:^() {
        count = [self->_databaseOutPool count] + [self->_databaseInPool count];
    }];
    
    return count;
}

- (void)releaseAllDatabases {
    [self executeLocked:^() {
        [self->_databaseOutPool removeAllObjects];
        [self->_databaseInPool removeAllObjects];
    }];
}

- (void)inDatabase:(void (^)(FMDatabase *db))block {
    
    FMDatabase *db = [self db];
    
    block(db);
    
    [self pushDatabaseBackInPool:db];
}

- (void)beginTransaction:(BOOL)useDeferred withBlock:(void (^)(FMDatabase *db, BOOL *rollback))block {
    
    BOOL shouldRollback = NO;
    
    FMDatabase *db = [self db];
    
    if (useDeferred) {
        [db beginDeferredTransaction];
    }
    else {
        [db beginTransaction];
    }
    
    
    block(db, &shouldRollback);
    
    if (shouldRollback) {
        [db rollback];
    }
    else {
        [db commit];
    }
    
    [self pushDatabaseBackInPool:db];
}

- (void)inDeferredTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block {
    [self beginTransaction:YES withBlock:block];
}

- (void)inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block {
    [self beginTransaction:NO withBlock:block];
}

- (NSError*)inSavePoint:(void (^)(FMDatabase *db, BOOL *rollback))block {
#if SQLITE_VERSION_NUMBER >= 3007000
    static unsigned long savePointIdx = 0;
    
    NSString *name = [NSString stringWithFormat:@"savePoint%ld", savePointIdx++];
    
    BOOL shouldRollback = NO;
    
    FMDatabase *db = [self db];
    
    NSError *err = 0x00;
    
    if (![db startSavePointWithName:name error:&err]) {
        [self pushDatabaseBackInPool:db];
        return err;
    }
    
    block(db, &shouldRollback);
    
    if (shouldRollback) {
        // We need to rollback and release this savepoint to remove it
        [db rollbackToSavePointWithName:name error:&err];
    }
    [db releaseSavePointWithName:name error:&err];
    
    [self pushDatabaseBackInPool:db];
    
    return err;
#else
    NSString *errorMessage = NSLocalizedString(@"Save point functions require SQLite 3.7", nil);
    if (self.logsErrors) NSLog(@"%@", errorMessage);
    return [NSError errorWithDomain:@"FMDatabase" code:0 userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
#endif
}

@end
//
//  FMDatabaseQueue.m
//  fmdb
//
//  Created by August Mueller on 6/22/11.
//  Copyright 2011 Flying Meat Inc. All rights reserved.
//

/*
 
 Note: we call [self retain]; before using dispatch_sync, just incase
 FMDatabaseQueue is released on another thread and we're in the middle of doing
 something in dispatch_sync
 
 */

/*
 * A key used to associate the FMDatabaseQueue object with the dispatch_queue_t it uses.
 * This in turn is used for deadlock detection by seeing if inDatabase: is called on
 * the queue's dispatch queue, which should not happen and causes a deadlock.
 */
static const void * const kDispatchQueueSpecificKey = &kDispatchQueueSpecificKey;

@implementation FMDatabaseQueue

@synthesize path = _path;
@synthesize openFlags = _openFlags;
@synthesize vfsName = _vfsName;

+ (instancetype)databaseQueueWithPath:(NSString*)aPath {
    
    FMDatabaseQueue *q = [[self alloc] initWithPath:aPath];
    
    FMDBAutorelease(q);
    
    return q;
}

+ (instancetype)databaseQueueWithPath:(NSString*)aPath flags:(int)openFlags {
    
    FMDatabaseQueue *q = [[self alloc] initWithPath:aPath flags:openFlags];
    
    FMDBAutorelease(q);
    
    return q;
}

+ (Class)databaseClass {
    return [FMDatabase class];
}

- (instancetype)initWithPath:(NSString*)aPath flags:(int)openFlags vfs:(NSString *)vfsName {
    
    self = [super init];
    
    if (self != nil) {
        
        _db = [[[self class] databaseClass] databaseWithPath:aPath];
        FMDBRetain(_db);
        
#if SQLITE_VERSION_NUMBER >= 3005000
        BOOL success = [_db openWithFlags:openFlags vfs:vfsName];
#else
        BOOL success = [_db open];
#endif
        if (!success) {
            NSLog(@"Could not create database queue for path %@", aPath);
            FMDBRelease(self);
            return 0x00;
        }
        
        _path = FMDBReturnRetained(aPath);
        
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"fmdb.%@", self] UTF8String], NULL);
        dispatch_queue_set_specific(_queue, kDispatchQueueSpecificKey, (__bridge void *)self, NULL);
        _openFlags = openFlags;
        _vfsName = [vfsName copy];
    }
    
    return self;
}

- (instancetype)initWithPath:(NSString*)aPath flags:(int)openFlags {
    return [self initWithPath:aPath flags:openFlags vfs:nil];
}

- (instancetype)initWithPath:(NSString*)aPath {
    
    // default flags for sqlite3_open
    return [self initWithPath:aPath flags:SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE vfs:nil];
}

- (instancetype)init {
    return [self initWithPath:nil];
}


- (void)dealloc {
    
    FMDBRelease(_db);
    FMDBRelease(_path);
    
    if (_queue) {
        FMDBDispatchQueueRelease(_queue);
        _queue = 0x00;
    }
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)close {
    FMDBRetain(self);
    dispatch_sync(_queue, ^() {
        [self->_db close];
        FMDBRelease(_db);
        self->_db = 0x00;
    });
    FMDBRelease(self);
}

- (void)interrupt
{
    [[self database] interrupt];
}

- (FMDatabase*)database {
    if (!_db) {
        _db = FMDBReturnRetained([[[self class] databaseClass] databaseWithPath:_path]);
        
#if SQLITE_VERSION_NUMBER >= 3005000
        BOOL success = [_db openWithFlags:_openFlags vfs:_vfsName];
#else
        BOOL success = [_db open];
#endif
        if (!success) {
            NSLog(@"FMDatabaseQueue could not reopen database for path %@", _path);
            FMDBRelease(_db);
            _db  = 0x00;
            return 0x00;
        }
    }
    
    return _db;
}

- (void)inDatabase:(void (^)(FMDatabase *db))block {
    /* Get the currently executing queue (which should probably be nil, but in theory could be another DB queue
     * and then check it against self to make sure we're not about to deadlock. */
    FMDatabaseQueue *currentSyncQueue = (__bridge id)dispatch_get_specific(kDispatchQueueSpecificKey);
    assert(currentSyncQueue != self && "inDatabase: was called reentrantly on the same queue, which would lead to a deadlock");
    
    FMDBRetain(self);
    
    dispatch_sync(_queue, ^() {
        
        FMDatabase *db = [self database];
        block(db);
        
        if ([db hasOpenResultSets]) {
            NSLog(@"Warning: there is at least one open result set around after performing [FMDatabaseQueue inDatabase:]");
            
#if defined(DEBUG) && DEBUG
            NSSet *openSetCopy = FMDBReturnAutoreleased([[db valueForKey:@"_openResultSets"] copy]);
            for (NSValue *rsInWrappedInATastyValueMeal in openSetCopy) {
                FMResultSet *rs = (FMResultSet *)[rsInWrappedInATastyValueMeal pointerValue];
                NSLog(@"query: '%@'", [rs query]);
            }
#endif
        }
    });
    
    FMDBRelease(self);
}


- (void)beginTransaction:(BOOL)useDeferred withBlock:(void (^)(FMDatabase *db, BOOL *rollback))block {
    FMDBRetain(self);
    dispatch_sync(_queue, ^() {
        
        BOOL shouldRollback = NO;
        
        if (useDeferred) {
            [[self database] beginDeferredTransaction];
        }
        else {
            [[self database] beginTransaction];
        }
        
        block([self database], &shouldRollback);
        
        if (shouldRollback) {
            [[self database] rollback];
        }
        else {
            [[self database] commit];
        }
    });
    
    FMDBRelease(self);
}

- (void)inDeferredTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block {
    [self beginTransaction:YES withBlock:block];
}

- (void)inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block {
    [self beginTransaction:NO withBlock:block];
}

- (NSError*)inSavePoint:(void (^)(FMDatabase *db, BOOL *rollback))block {
#if SQLITE_VERSION_NUMBER >= 3007000
    static unsigned long savePointIdx = 0;
    __block NSError *err = 0x00;
    FMDBRetain(self);
    dispatch_sync(_queue, ^() {
        
        NSString *name = [NSString stringWithFormat:@"savePoint%ld", savePointIdx++];
        
        BOOL shouldRollback = NO;
        
        if ([[self database] startSavePointWithName:name error:&err]) {
            
            block([self database], &shouldRollback);
            
            if (shouldRollback) {
                // We need to rollback and release this savepoint to remove it
                [[self database] rollbackToSavePointWithName:name error:&err];
            }
            [[self database] releaseSavePointWithName:name error:&err];
            
        }
    });
    FMDBRelease(self);
    return err;
#else
    NSString *errorMessage = NSLocalizedString(@"Save point functions require SQLite 3.7", nil);
    if (self.logsErrors) NSLog(@"%@", errorMessage);
    return [NSError errorWithDomain:@"FMDatabase" code:0 userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
#endif
}

@end

//@interface FMDatabase ()
//- (void)resultSetDidClose:(FMResultSet *)resultSet;
//@end


@implementation FMResultSet
@synthesize query=_query;
@synthesize statement=_statement;

+ (instancetype)resultSetWithStatement:(FMStatement *)statement usingParentDatabase:(FMDatabase*)aDB {
    
    FMResultSet *rs = [[FMResultSet alloc] init];
    
    [rs setStatement:statement];
    [rs setParentDB:aDB];
    
    NSParameterAssert(![statement inUse]);
    [statement setInUse:YES]; // weak reference
    
    return FMDBReturnAutoreleased(rs);
}

- (void)finalize {
    [self close];
    [super finalize];
}

- (void)dealloc {
    [self close];
    
    FMDBRelease(_query);
    _query = nil;
    
    FMDBRelease(_columnNameToIndexMap);
    _columnNameToIndexMap = nil;
    
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)close {
    [_statement reset];
    FMDBRelease(_statement);
    _statement = nil;
    
    // we don't need this anymore... (i think)
    //[_parentDB setInUse:NO];
    [_parentDB resultSetDidClose:self];
    _parentDB = nil;
}

- (int)columnCount {
    return sqlite3_column_count([_statement statement]);
}

- (NSMutableDictionary *)columnNameToIndexMap {
    if (!_columnNameToIndexMap) {
        int columnCount = sqlite3_column_count([_statement statement]);
        _columnNameToIndexMap = [[NSMutableDictionary alloc] initWithCapacity:(NSUInteger)columnCount];
        int columnIdx = 0;
        for (columnIdx = 0; columnIdx < columnCount; columnIdx++) {
            [_columnNameToIndexMap setObject:[NSNumber numberWithInt:columnIdx]
                                      forKey:[[NSString stringWithUTF8String:sqlite3_column_name([_statement statement], columnIdx)] lowercaseString]];
        }
    }
    return _columnNameToIndexMap;
}

- (void)kvcMagic:(id)object {
    
    int columnCount = sqlite3_column_count([_statement statement]);
    
    int columnIdx = 0;
    for (columnIdx = 0; columnIdx < columnCount; columnIdx++) {
        
        const char *c = (const char *)sqlite3_column_text([_statement statement], columnIdx);
        
        // check for a null row
        if (c) {
            NSString *s = [NSString stringWithUTF8String:c];
            
            [object setValue:s forKey:[NSString stringWithUTF8String:sqlite3_column_name([_statement statement], columnIdx)]];
        }
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (NSDictionary*)resultDict {
    
    NSUInteger num_cols = (NSUInteger)sqlite3_data_count([_statement statement]);
    
    if (num_cols > 0) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:num_cols];
        
        NSEnumerator *columnNames = [[self columnNameToIndexMap] keyEnumerator];
        NSString *columnName = nil;
        while ((columnName = [columnNames nextObject])) {
            id objectValue = [self objectForColumnName:columnName];
            [dict setObject:objectValue forKey:columnName];
        }
        
        return FMDBReturnAutoreleased([dict copy]);
    }
    else {
        NSLog(@"Warning: There seem to be no columns in this set.");
    }
    
    return nil;
}

#pragma clang diagnostic pop

- (NSDictionary*)resultDictionary {
    
    NSUInteger num_cols = (NSUInteger)sqlite3_data_count([_statement statement]);
    
    if (num_cols > 0) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:num_cols];
        
        int columnCount = sqlite3_column_count([_statement statement]);
        
        int columnIdx = 0;
        for (columnIdx = 0; columnIdx < columnCount; columnIdx++) {
            
            NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name([_statement statement], columnIdx)];
            id objectValue = [self objectForColumnIndex:columnIdx];
            [dict setObject:objectValue forKey:columnName];
        }
        
        return dict;
    }
    else {
        NSLog(@"Warning: There seem to be no columns in this set.");
    }
    
    return nil;
}




- (BOOL)next {
    return [self nextWithError:nil];
}

- (BOOL)nextWithError:(NSError **)outErr {
    
    int rc = sqlite3_step([_statement statement]);
    
    if (SQLITE_BUSY == rc || SQLITE_LOCKED == rc) {
        NSLog(@"%s:%d Database busy (%@)", __FUNCTION__, __LINE__, [_parentDB databasePath]);
        NSLog(@"Database busy");
        if (outErr) {
            *outErr = [_parentDB lastError];
        }
    }
    else if (SQLITE_DONE == rc || SQLITE_ROW == rc) {
        // all is well, let's return.
    }
    else if (SQLITE_ERROR == rc) {
        NSLog(@"Error calling sqlite3_step (%d: %s) rs", rc, sqlite3_errmsg([_parentDB sqliteHandle]));
        if (outErr) {
            *outErr = [_parentDB lastError];
        }
    }
    else if (SQLITE_MISUSE == rc) {
        // uh oh.
        NSLog(@"Error calling sqlite3_step (%d: %s) rs", rc, sqlite3_errmsg([_parentDB sqliteHandle]));
        if (outErr) {
            if (_parentDB) {
                *outErr = [_parentDB lastError];
            }
            else {
                // If 'next' or 'nextWithError' is called after the result set is closed,
                // we need to return the appropriate error.
                NSDictionary* errorMessage = [NSDictionary dictionaryWithObject:@"parentDB does not exist" forKey:NSLocalizedDescriptionKey];
                *outErr = [NSError errorWithDomain:@"FMDatabase" code:SQLITE_MISUSE userInfo:errorMessage];
            }
            
        }
    }
    else {
        // wtf?
        NSLog(@"Unknown error calling sqlite3_step (%d: %s) rs", rc, sqlite3_errmsg([_parentDB sqliteHandle]));
        if (outErr) {
            *outErr = [_parentDB lastError];
        }
    }
    
    
    if (rc != SQLITE_ROW) {
        [self close];
    }
    
    return (rc == SQLITE_ROW);
}

- (BOOL)hasAnotherRow {
    return sqlite3_errcode([_parentDB sqliteHandle]) == SQLITE_ROW;
}

- (int)columnIndexForName:(NSString*)columnName {
    columnName = [columnName lowercaseString];
    
    NSNumber *n = [[self columnNameToIndexMap] objectForKey:columnName];
    
    if (n) {
        return [n intValue];
    }
    
    NSLog(@"Warning: I could not find the column named '%@'.", columnName);
    
    return -1;
}



- (int)intForColumn:(NSString*)columnName {
    return [self intForColumnIndex:[self columnIndexForName:columnName]];
}

- (int)intForColumnIndex:(int)columnIdx {
    return sqlite3_column_int([_statement statement], columnIdx);
}

- (long)longForColumn:(NSString*)columnName {
    return [self longForColumnIndex:[self columnIndexForName:columnName]];
}

- (long)longForColumnIndex:(int)columnIdx {
    return (long)sqlite3_column_int64([_statement statement], columnIdx);
}

- (long long int)longLongIntForColumn:(NSString*)columnName {
    return [self longLongIntForColumnIndex:[self columnIndexForName:columnName]];
}

- (long long int)longLongIntForColumnIndex:(int)columnIdx {
    return sqlite3_column_int64([_statement statement], columnIdx);
}

- (unsigned long long int)unsignedLongLongIntForColumn:(NSString*)columnName {
    return [self unsignedLongLongIntForColumnIndex:[self columnIndexForName:columnName]];
}

- (unsigned long long int)unsignedLongLongIntForColumnIndex:(int)columnIdx {
    return (unsigned long long int)[self longLongIntForColumnIndex:columnIdx];
}

- (BOOL)boolForColumn:(NSString*)columnName {
    return [self boolForColumnIndex:[self columnIndexForName:columnName]];
}

- (BOOL)boolForColumnIndex:(int)columnIdx {
    return ([self intForColumnIndex:columnIdx] != 0);
}

- (double)doubleForColumn:(NSString*)columnName {
    return [self doubleForColumnIndex:[self columnIndexForName:columnName]];
}

- (double)doubleForColumnIndex:(int)columnIdx {
    return sqlite3_column_double([_statement statement], columnIdx);
}

- (NSString*)stringForColumnIndex:(int)columnIdx {
    
    if (sqlite3_column_type([_statement statement], columnIdx) == SQLITE_NULL || (columnIdx < 0)) {
        return nil;
    }
    
    const char *c = (const char *)sqlite3_column_text([_statement statement], columnIdx);
    
    if (!c) {
        // null row.
        return nil;
    }
    
    return [NSString stringWithUTF8String:c];
}

- (NSString*)stringForColumn:(NSString*)columnName {
    return [self stringForColumnIndex:[self columnIndexForName:columnName]];
}

- (NSDate*)dateForColumn:(NSString*)columnName {
    return [self dateForColumnIndex:[self columnIndexForName:columnName]];
}

- (NSDate*)dateForColumnIndex:(int)columnIdx {
    
    if (sqlite3_column_type([_statement statement], columnIdx) == SQLITE_NULL || (columnIdx < 0)) {
        return nil;
    }
    
    return [_parentDB hasDateFormatter] ? [_parentDB dateFromString:[self stringForColumnIndex:columnIdx]] : [NSDate dateWithTimeIntervalSince1970:[self doubleForColumnIndex:columnIdx]];
}


- (NSData*)dataForColumn:(NSString*)columnName {
    return [self dataForColumnIndex:[self columnIndexForName:columnName]];
}

- (NSData*)dataForColumnIndex:(int)columnIdx {
    
    if (sqlite3_column_type([_statement statement], columnIdx) == SQLITE_NULL || (columnIdx < 0)) {
        return nil;
    }
    
    const char *dataBuffer = sqlite3_column_blob([_statement statement], columnIdx);
    int dataSize = sqlite3_column_bytes([_statement statement], columnIdx);
    
    if (dataBuffer == NULL) {
        return nil;
    }
    
    return [NSData dataWithBytes:(const void *)dataBuffer length:(NSUInteger)dataSize];
}


- (NSData*)dataNoCopyForColumn:(NSString*)columnName {
    return [self dataNoCopyForColumnIndex:[self columnIndexForName:columnName]];
}

- (NSData*)dataNoCopyForColumnIndex:(int)columnIdx {
    
    if (sqlite3_column_type([_statement statement], columnIdx) == SQLITE_NULL || (columnIdx < 0)) {
        return nil;
    }
    
    const char *dataBuffer = sqlite3_column_blob([_statement statement], columnIdx);
    int dataSize = sqlite3_column_bytes([_statement statement], columnIdx);
    
    NSData *data = [NSData dataWithBytesNoCopy:(void *)dataBuffer length:(NSUInteger)dataSize freeWhenDone:NO];
    
    return data;
}


- (BOOL)columnIndexIsNull:(int)columnIdx {
    return sqlite3_column_type([_statement statement], columnIdx) == SQLITE_NULL;
}

- (BOOL)columnIsNull:(NSString*)columnName {
    return [self columnIndexIsNull:[self columnIndexForName:columnName]];
}

- (const unsigned char *)UTF8StringForColumnIndex:(int)columnIdx {
    
    if (sqlite3_column_type([_statement statement], columnIdx) == SQLITE_NULL || (columnIdx < 0)) {
        return nil;
    }
    
    return sqlite3_column_text([_statement statement], columnIdx);
}

- (const unsigned char *)UTF8StringForColumnName:(NSString*)columnName {
    return [self UTF8StringForColumnIndex:[self columnIndexForName:columnName]];
}

- (id)objectForColumnIndex:(int)columnIdx {
    int columnType = sqlite3_column_type([_statement statement], columnIdx);
    
    id returnValue = nil;
    
    if (columnType == SQLITE_INTEGER) {
        returnValue = [NSNumber numberWithLongLong:[self longLongIntForColumnIndex:columnIdx]];
    }
    else if (columnType == SQLITE_FLOAT) {
        returnValue = [NSNumber numberWithDouble:[self doubleForColumnIndex:columnIdx]];
    }
    else if (columnType == SQLITE_BLOB) {
        returnValue = [self dataForColumnIndex:columnIdx];
    }
    else {
        //default to a string for everything else
        returnValue = [self stringForColumnIndex:columnIdx];
    }
    
    if (returnValue == nil) {
        returnValue = [NSNull null];
    }
    
    return returnValue;
}

- (id)objectForColumnName:(NSString*)columnName {
    return [self objectForColumnIndex:[self columnIndexForName:columnName]];
}

// returns autoreleased NSString containing the name of the column in the result set
- (NSString*)columnNameForIndex:(int)columnIdx {
    return [NSString stringWithUTF8String: sqlite3_column_name([_statement statement], columnIdx)];
}

- (void)setParentDB:(FMDatabase *)newDb {
    _parentDB = newDb;
}

- (id)objectAtIndexedSubscript:(int)columnIdx {
    return [self objectForColumnIndex:columnIdx];
}

- (id)objectForKeyedSubscript:(NSString *)columnName {
    return [self objectForColumnName:columnName];
}


@end
