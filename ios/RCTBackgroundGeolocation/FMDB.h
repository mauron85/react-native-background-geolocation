/*
 If you are using FMDB in your project, I'd love to hear about it.  Let Gus know
 by sending an email to gus@flyingmeat.com.
 
 And if you happen to come across either Gus Mueller or Rob Ryan in a bar, you
 might consider purchasing a drink of their choosing if FMDB has been useful to
 you.
 
 Finally, and shortly, this is the MIT License.
 
 Copyright (c) 2008-2014 Flying Meat Inc.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <Foundation/Foundation.h>

#ifndef __has_feature      // Optional.
#define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif

#ifndef NS_RETURNS_NOT_RETAINED
#if __has_feature(attribute_ns_returns_not_retained)
#define NS_RETURNS_NOT_RETAINED __attribute__((ns_returns_not_retained))
#else
#define NS_RETURNS_NOT_RETAINED
#endif
#endif

@class FMDatabase;
@class FMStatement;

/** Represents the results of executing a query on an `<FMDatabase>`.
 
 ### See also
 
 - `<FMDatabase>`
 */

@interface FMResultSet : NSObject {
    FMDatabase          *_parentDB;
    FMStatement         *_statement;
    
    NSString            *_query;
    NSMutableDictionary *_columnNameToIndexMap;
}

///-----------------
/// @name Properties
///-----------------

/** Executed query */

@property (atomic, retain) NSString *query;

/** `NSMutableDictionary` mapping column names to numeric index */

@property (readonly) NSMutableDictionary *columnNameToIndexMap;

/** `FMStatement` used by result set. */

@property (atomic, retain) FMStatement *statement;

///------------------------------------
/// @name Creating and closing database
///------------------------------------

/** Create result set from `<FMStatement>`
 
 @param statement A `<FMStatement>` to be performed
 
 @param aDB A `<FMDatabase>` to be used
 
 @return A `FMResultSet` on success; `nil` on failure
 */

+ (instancetype)resultSetWithStatement:(FMStatement *)statement usingParentDatabase:(FMDatabase*)aDB;

/** Close result set */

- (void)close;

- (void)setParentDB:(FMDatabase *)newDb;

///---------------------------------------
/// @name Iterating through the result set
///---------------------------------------

/** Retrieve next row for result set.
 
 You must always invoke `next` or `nextWithError` before attempting to access the values returned in a query, even if you're only expecting one.
 
 @return `YES` if row successfully retrieved; `NO` if end of result set reached
 
 @see hasAnotherRow
 */

- (BOOL)next;

/** Retrieve next row for result set.
 
 You must always invoke `next` or `nextWithError` before attempting to access the values returned in a query, even if you're only expecting one.
 
 @param outErr A 'NSError' object to receive any error object (if any).
 
 @return 'YES' if row successfully retrieved; 'NO' if end of result set reached
 
 @see hasAnotherRow
 */

- (BOOL)nextWithError:(NSError **)outErr;

/** Did the last call to `<next>` succeed in retrieving another row?
 
 @return `YES` if the last call to `<next>` succeeded in retrieving another record; `NO` if not.
 
 @see next
 
 @warning The `hasAnotherRow` method must follow a call to `<next>`. If the previous database interaction was something other than a call to `next`, then this method may return `NO`, whether there is another row of data or not.
 */

- (BOOL)hasAnotherRow;

///---------------------------------------------
/// @name Retrieving information from result set
///---------------------------------------------

/** How many columns in result set
 
 @return Integer value of the number of columns.
 */

- (int)columnCount;

/** Column index for column name
 
 @param columnName `NSString` value of the name of the column.
 
 @return Zero-based index for column.
 */

- (int)columnIndexForName:(NSString*)columnName;

/** Column name for column index
 
 @param columnIdx Zero-based index for column.
 
 @return columnName `NSString` value of the name of the column.
 */

- (NSString*)columnNameForIndex:(int)columnIdx;

/** Result set integer value for column.
 
 @param columnName `NSString` value of the name of the column.
 
 @return `int` value of the result set's column.
 */

- (int)intForColumn:(NSString*)columnName;

/** Result set integer value for column.
 
 @param columnIdx Zero-based index for column.
 
 @return `int` value of the result set's column.
 */

- (int)intForColumnIndex:(int)columnIdx;

/** Result set `long` value for column.
 
 @param columnName `NSString` value of the name of the column.
 
 @return `long` value of the result set's column.
 */

- (long)longForColumn:(NSString*)columnName;

/** Result set long value for column.
 
 @param columnIdx Zero-based index for column.
 
 @return `long` value of the result set's column.
 */

- (long)longForColumnIndex:(int)columnIdx;

/** Result set `long long int` value for column.
 
 @param columnName `NSString` value of the name of the column.
 
 @return `long long int` value of the result set's column.
 */

- (long long int)longLongIntForColumn:(NSString*)columnName;

/** Result set `long long int` value for column.
 
 @param columnIdx Zero-based index for column.
 
 @return `long long int` value of the result set's column.
 */

- (long long int)longLongIntForColumnIndex:(int)columnIdx;

/** Result set `unsigned long long int` value for column.
 
 @param columnName `NSString` value of the name of the column.
 
 @return `unsigned long long int` value of the result set's column.
 */

- (unsigned long long int)unsignedLongLongIntForColumn:(NSString*)columnName;

/** Result set `unsigned long long int` value for column.
 
 @param columnIdx Zero-based index for column.
 
 @return `unsigned long long int` value of the result set's column.
 */

- (unsigned long long int)unsignedLongLongIntForColumnIndex:(int)columnIdx;

/** Result set `BOOL` value for column.
 
 @param columnName `NSString` value of the name of the column.
 
 @return `BOOL` value of the result set's column.
 */

- (BOOL)boolForColumn:(NSString*)columnName;

/** Result set `BOOL` value for column.
 
 @param columnIdx Zero-based index for column.
 
 @return `BOOL` value of the result set's column.
 */

- (BOOL)boolForColumnIndex:(int)columnIdx;

/** Result set `double` value for column.
 
 @param columnName `NSString` value of the name of the column.
 
 @return `double` value of the result set's column.
 
 */

- (double)doubleForColumn:(NSString*)columnName;

/** Result set `double` value for column.
 
 @param columnIdx Zero-based index for column.
 
 @return `double` value of the result set's column.
 
 */

- (double)doubleForColumnIndex:(int)columnIdx;

/** Result set `NSString` value for column.
 
 @param columnName `NSString` value of the name of the column.
 
 @return `NSString` value of the result set's column.
 
 */

- (NSString*)stringForColumn:(NSString*)columnName;

/** Result set `NSString` value for column.
 
 @param columnIdx Zero-based index for column.
 
 @return `NSString` value of the result set's column.
 */

- (NSString*)stringForColumnIndex:(int)columnIdx;

/** Result set `NSDate` value for column.
 
 @param columnName `NSString` value of the name of the column.
 
 @return `NSDate` value of the result set's column.
 */

- (NSDate*)dateForColumn:(NSString*)columnName;

/** Result set `NSDate` value for column.
 
 @param columnIdx Zero-based index for column.
 
 @return `NSDate` value of the result set's column.
 
 */

- (NSDate*)dateForColumnIndex:(int)columnIdx;

/** Result set `NSData` value for column.
 
 This is useful when storing binary data in table (such as image or the like).
 
 @param columnName `NSString` value of the name of the column.
 
 @return `NSData` value of the result set's column.
 
 */

- (NSData*)dataForColumn:(NSString*)columnName;

/** Result set `NSData` value for column.
 
 @param columnIdx Zero-based index for column.
 
 @return `NSData` value of the result set's column.
 */

- (NSData*)dataForColumnIndex:(int)columnIdx;

/** Result set `(const unsigned char *)` value for column.
 
 @param columnName `NSString` value of the name of the column.
 
 @return `(const unsigned char *)` value of the result set's column.
 */

- (const unsigned char *)UTF8StringForColumnName:(NSString*)columnName;

/** Result set `(const unsigned char *)` value for column.
 
 @param columnIdx Zero-based index for column.
 
 @return `(const unsigned char *)` value of the result set's column.
 */

- (const unsigned char *)UTF8StringForColumnIndex:(int)columnIdx;

/** Result set object for column.
 
 @param columnName `NSString` value of the name of the column.
 
 @return Either `NSNumber`, `NSString`, `NSData`, or `NSNull`. If the column was `NULL`, this returns `[NSNull null]` object.
 
 @see objectForKeyedSubscript:
 */

- (id)objectForColumnName:(NSString*)columnName;

/** Result set object for column.
 
 @param columnIdx Zero-based index for column.
 
 @return Either `NSNumber`, `NSString`, `NSData`, or `NSNull`. If the column was `NULL`, this returns `[NSNull null]` object.
 
 @see objectAtIndexedSubscript:
 */

- (id)objectForColumnIndex:(int)columnIdx;

/** Result set object for column.
 
 This method allows the use of the "boxed" syntax supported in Modern Objective-C. For example, by defining this method, the following syntax is now supported:
 
 id result = rs[@"employee_name"];
 
 This simplified syntax is equivalent to calling:
 
 id result = [rs objectForKeyedSubscript:@"employee_name"];
 
 which is, it turns out, equivalent to calling:
 
 id result = [rs objectForColumnName:@"employee_name"];
 
 @param columnName `NSString` value of the name of the column.
 
 @return Either `NSNumber`, `NSString`, `NSData`, or `NSNull`. If the column was `NULL`, this returns `[NSNull null]` object.
 */

- (id)objectForKeyedSubscript:(NSString *)columnName;

/** Result set object for column.
 
 This method allows the use of the "boxed" syntax supported in Modern Objective-C. For example, by defining this method, the following syntax is now supported:
 
 id result = rs[0];
 
 This simplified syntax is equivalent to calling:
 
 id result = [rs objectForKeyedSubscript:0];
 
 which is, it turns out, equivalent to calling:
 
 id result = [rs objectForColumnName:0];
 
 @param columnIdx Zero-based index for column.
 
 @return Either `NSNumber`, `NSString`, `NSData`, or `NSNull`. If the column was `NULL`, this returns `[NSNull null]` object.
 */

- (id)objectAtIndexedSubscript:(int)columnIdx;

/** Result set `NSData` value for column.
 
 @param columnName `NSString` value of the name of the column.
 
 @return `NSData` value of the result set's column.
 
 @warning If you are going to use this data after you iterate over the next row, or after you close the
 result set, make sure to make a copy of the data first (or just use `<dataForColumn:>`/`<dataForColumnIndex:>`)
 If you don't, you're going to be in a world of hurt when you try and use the data.
 
 */

- (NSData*)dataNoCopyForColumn:(NSString*)columnName NS_RETURNS_NOT_RETAINED;

/** Result set `NSData` value for column.
 
 @param columnIdx Zero-based index for column.
 
 @return `NSData` value of the result set's column.
 
 @warning If you are going to use this data after you iterate over the next row, or after you close the
 result set, make sure to make a copy of the data first (or just use `<dataForColumn:>`/`<dataForColumnIndex:>`)
 If you don't, you're going to be in a world of hurt when you try and use the data.
 
 */

- (NSData*)dataNoCopyForColumnIndex:(int)columnIdx NS_RETURNS_NOT_RETAINED;

/** Is the column `NULL`?
 
 @param columnIdx Zero-based index for column.
 
 @return `YES` if column is `NULL`; `NO` if not `NULL`.
 */

- (BOOL)columnIndexIsNull:(int)columnIdx;

/** Is the column `NULL`?
 
 @param columnName `NSString` value of the name of the column.
 
 @return `YES` if column is `NULL`; `NO` if not `NULL`.
 */

- (BOOL)columnIsNull:(NSString*)columnName;


/** Returns a dictionary of the row results mapped to case sensitive keys of the column names.
 
 @returns `NSDictionary` of the row results.
 
 @warning The keys to the dictionary are case sensitive of the column names.
 */

- (NSDictionary*)resultDictionary;

/** Returns a dictionary of the row results
 
 @see resultDictionary
 
 @warning **Deprecated**: Please use `<resultDictionary>` instead.  Also, beware that `<resultDictionary>` is case sensitive!
 */

- (NSDictionary*)resultDict  __attribute__ ((deprecated));

///-----------------------------
/// @name Key value coding magic
///-----------------------------

/** Performs `setValue` to yield support for key value observing.
 
 @param object The object for which the values will be set. This is the key-value-coding compliant object that you might, for example, observe.
 
 */

- (void)kvcMagic:(id)object;


@end



#if ! __has_feature(objc_arc)
#define FMDBAutorelease(__v) ([__v autorelease]);
#define FMDBReturnAutoreleased FMDBAutorelease

#define FMDBRetain(__v) ([__v retain]);
#define FMDBReturnRetained FMDBRetain

#define FMDBRelease(__v) ([__v release]);

#define FMDBDispatchQueueRelease(__v) (dispatch_release(__v));
#else
// -fobjc-arc
#define FMDBAutorelease(__v)
#define FMDBReturnAutoreleased(__v) (__v)

#define FMDBRetain(__v)
#define FMDBReturnRetained(__v) (__v)

#define FMDBRelease(__v)

// If OS_OBJECT_USE_OBJC=1, then the dispatch objects will be treated like ObjC objects
// and will participate in ARC.
// See the section on "Dispatch Queues and Automatic Reference Counting" in "Grand Central Dispatch (GCD) Reference" for details.
#if OS_OBJECT_USE_OBJC
#define FMDBDispatchQueueRelease(__v)
#else
#define FMDBDispatchQueueRelease(__v) (dispatch_release(__v));
#endif
#endif

#if !__has_feature(objc_instancetype)
#define instancetype id
#endif


typedef int(^FMDBExecuteStatementsCallbackBlock)(NSDictionary *resultsDictionary);


/** A SQLite ([http://sqlite.org/](http://sqlite.org/)) Objective-C wrapper.
 
 ### Usage
 The three main classes in FMDB are:
 
 - `FMDatabase` - Represents a single SQLite database.  Used for executing SQL statements.
 - `<FMResultSet>` - Represents the results of executing a query on an `FMDatabase`.
 - `<FMDatabaseQueue>` - If you want to perform queries and updates on multiple threads, you'll want to use this class.
 
 ### See also
 
 - `<FMDatabasePool>` - A pool of `FMDatabase` objects.
 - `<FMStatement>` - A wrapper for `sqlite_stmt`.
 
 ### External links
 
 - [FMDB on GitHub](https://github.com/ccgus/fmdb) including introductory documentation
 - [SQLite web site](http://sqlite.org/)
 - [FMDB mailing list](http://groups.google.com/group/fmdb)
 - [SQLite FAQ](http://www.sqlite.org/faq.html)
 
 @warning Do not instantiate a single `FMDatabase` object and use it across multiple threads. Instead, use `<FMDatabaseQueue>`.
 
 */

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"


@interface FMDatabase : NSObject  {
    
    void*               _db;
    NSString*           _databasePath;
    BOOL                _logsErrors;
    BOOL                _crashOnErrors;
    BOOL                _traceExecution;
    BOOL                _checkedOut;
    BOOL                _shouldCacheStatements;
    BOOL                _isExecutingStatement;
    BOOL                _inTransaction;
    NSTimeInterval      _maxBusyRetryTimeInterval;
    NSTimeInterval      _startBusyRetryTime;
    
    NSMutableDictionary *_cachedStatements;
    NSMutableSet        *_openResultSets;
    NSMutableSet        *_openFunctions;
    
    NSDateFormatter     *_dateFormat;
}

///-----------------
/// @name Properties
///-----------------

/** Whether should trace execution */

@property (atomic, assign) BOOL traceExecution;

/** Whether checked out or not */

@property (atomic, assign) BOOL checkedOut;

/** Crash on errors */

@property (atomic, assign) BOOL crashOnErrors;

/** Logs errors */

@property (atomic, assign) BOOL logsErrors;

/** Dictionary of cached statements */

@property (atomic, retain) NSMutableDictionary *cachedStatements;

///---------------------
/// @name Initialization
///---------------------

/** Create a `FMDatabase` object.
 
 An `FMDatabase` is created with a path to a SQLite database file.  This path can be one of these three:
 
 1. A file system path.  The file does not have to exist on disk.  If it does not exist, it is created for you.
 2. An empty string (`@""`).  An empty database is created at a temporary location.  This database is deleted with the `FMDatabase` connection is closed.
 3. `nil`.  An in-memory database is created.  This database will be destroyed with the `FMDatabase` connection is closed.
 
 For example, to create/open a database in your Mac OS X `tmp` folder:
 
 FMDatabase *db = [FMDatabase databaseWithPath:@"/tmp/tmp.db"];
 
 Or, in iOS, you might open a database in the app's `Documents` directory:
 
 NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
 NSString *dbPath   = [docsPath stringByAppendingPathComponent:@"test.db"];
 FMDatabase *db     = [FMDatabase databaseWithPath:dbPath];
 
 (For more information on temporary and in-memory databases, read the sqlite documentation on the subject: [http://www.sqlite.org/inmemorydb.html](http://www.sqlite.org/inmemorydb.html))
 
 @param inPath Path of database file
 
 @return `FMDatabase` object if successful; `nil` if failure.
 
 */

+ (instancetype)databaseWithPath:(NSString*)inPath;

/** Initialize a `FMDatabase` object.
 
 An `FMDatabase` is created with a path to a SQLite database file.  This path can be one of these three:
 
 1. A file system path.  The file does not have to exist on disk.  If it does not exist, it is created for you.
 2. An empty string (`@""`).  An empty database is created at a temporary location.  This database is deleted with the `FMDatabase` connection is closed.
 3. `nil`.  An in-memory database is created.  This database will be destroyed with the `FMDatabase` connection is closed.
 
 For example, to create/open a database in your Mac OS X `tmp` folder:
 
 FMDatabase *db = [FMDatabase databaseWithPath:@"/tmp/tmp.db"];
 
 Or, in iOS, you might open a database in the app's `Documents` directory:
 
 NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
 NSString *dbPath   = [docsPath stringByAppendingPathComponent:@"test.db"];
 FMDatabase *db     = [FMDatabase databaseWithPath:dbPath];
 
 (For more information on temporary and in-memory databases, read the sqlite documentation on the subject: [http://www.sqlite.org/inmemorydb.html](http://www.sqlite.org/inmemorydb.html))
 
 @param inPath Path of database file
 
 @return `FMDatabase` object if successful; `nil` if failure.
 
 */

- (instancetype)initWithPath:(NSString*)inPath;


///-----------------------------------
/// @name Opening and closing database
///-----------------------------------

/** Opening a new database connection
 
 The database is opened for reading and writing, and is created if it does not already exist.
 
 @return `YES` if successful, `NO` on error.
 
 @see [sqlite3_open()](http://sqlite.org/c3ref/open.html)
 @see openWithFlags:
 @see close
 */

- (BOOL)open;

/** Opening a new database connection with flags and an optional virtual file system (VFS)
 
 @param flags one of the following three values, optionally combined with the `SQLITE_OPEN_NOMUTEX`, `SQLITE_OPEN_FULLMUTEX`, `SQLITE_OPEN_SHAREDCACHE`, `SQLITE_OPEN_PRIVATECACHE`, and/or `SQLITE_OPEN_URI` flags:
 
 `SQLITE_OPEN_READONLY`
 
 The database is opened in read-only mode. If the database does not already exist, an error is returned.
 
 `SQLITE_OPEN_READWRITE`
 
 The database is opened for reading and writing if possible, or reading only if the file is write protected by the operating system. In either case the database must already exist, otherwise an error is returned.
 
 `SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE`
 
 The database is opened for reading and writing, and is created if it does not already exist. This is the behavior that is always used for `open` method.
 
 @return `YES` if successful, `NO` on error.
 
 @see [sqlite3_open_v2()](http://sqlite.org/c3ref/open.html)
 @see open
 @see close
 */

- (BOOL)openWithFlags:(int)flags;

/** Opening a new database connection with flags and an optional virtual file system (VFS)
 
 @param flags one of the following three values, optionally combined with the `SQLITE_OPEN_NOMUTEX`, `SQLITE_OPEN_FULLMUTEX`, `SQLITE_OPEN_SHAREDCACHE`, `SQLITE_OPEN_PRIVATECACHE`, and/or `SQLITE_OPEN_URI` flags:
 
 `SQLITE_OPEN_READONLY`
 
 The database is opened in read-only mode. If the database does not already exist, an error is returned.
 
 `SQLITE_OPEN_READWRITE`
 
 The database is opened for reading and writing if possible, or reading only if the file is write protected by the operating system. In either case the database must already exist, otherwise an error is returned.
 
 `SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE`
 
 The database is opened for reading and writing, and is created if it does not already exist. This is the behavior that is always used for `open` method.
 
 @param vfsName   If vfs is given the value is passed to the vfs parameter of sqlite3_open_v2.
 
 @return `YES` if successful, `NO` on error.
 
 @see [sqlite3_open_v2()](http://sqlite.org/c3ref/open.html)
 @see open
 @see close
 */

- (BOOL)openWithFlags:(int)flags vfs:(NSString *)vfsName;

/** Closing a database connection
 
 @return `YES` if success, `NO` on error.
 
 @see [sqlite3_close()](http://sqlite.org/c3ref/close.html)
 @see open
 @see openWithFlags:
 */

- (BOOL)close;

/** Test to see if we have a good connection to the database.
 
 This will confirm whether:
 
 - is database open
 - if open, it will try a simple SELECT statement and confirm that it succeeds.
 
 @return `YES` if everything succeeds, `NO` on failure.
 */

- (BOOL)goodConnection;


///----------------------
/// @name Perform updates
///----------------------

/** Execute single update statement
 
 This method executes a single SQL update statement (i.e. any SQL that does not return results, such as `UPDATE`, `INSERT`, or `DELETE`. This method employs [`sqlite3_prepare_v2`](http://sqlite.org/c3ref/prepare.html), [`sqlite3_bind`](http://sqlite.org/c3ref/bind_blob.html) to bind values to `?` placeholders in the SQL with the optional list of parameters, and [`sqlite_step`](http://sqlite.org/c3ref/step.html) to perform the update.
 
 The optional values provided to this method should be objects (e.g. `NSString`, `NSNumber`, `NSNull`, `NSDate`, and `NSData` objects), not fundamental data types (e.g. `int`, `long`, `NSInteger`, etc.). This method automatically handles the aforementioned object types, and all other object types will be interpreted as text values using the object's `description` method.
 
 @param sql The SQL to be performed, with optional `?` placeholders.
 
 @param outErr A reference to the `NSError` pointer to be updated with an auto released `NSError` object if an error if an error occurs. If `nil`, no `NSError` object will be returned.
 
 @param ... Optional parameters to bind to `?` placeholders in the SQL statement. These should be Objective-C objects (e.g. `NSString`, `NSNumber`, etc.), not fundamental C data types (e.g. `int`, `char *`, etc.).
 
 @return `YES` upon success; `NO` upon failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see lastError
 @see lastErrorCode
 @see lastErrorMessage
 @see [`sqlite3_bind`](http://sqlite.org/c3ref/bind_blob.html)
 */

- (BOOL)executeUpdate:(NSString*)sql withErrorAndBindings:(NSError**)outErr, ...;

/** Execute single update statement
 
 @see executeUpdate:withErrorAndBindings:
 
 @warning **Deprecated**: Please use `<executeUpdate:withErrorAndBindings>` instead.
 */

- (BOOL)update:(NSString*)sql withErrorAndBindings:(NSError**)outErr, ... __attribute__ ((deprecated));

/** Execute single update statement
 
 This method executes a single SQL update statement (i.e. any SQL that does not return results, such as `UPDATE`, `INSERT`, or `DELETE`. This method employs [`sqlite3_prepare_v2`](http://sqlite.org/c3ref/prepare.html), [`sqlite3_bind`](http://sqlite.org/c3ref/bind_blob.html) to bind values to `?` placeholders in the SQL with the optional list of parameters, and [`sqlite_step`](http://sqlite.org/c3ref/step.html) to perform the update.
 
 The optional values provided to this method should be objects (e.g. `NSString`, `NSNumber`, `NSNull`, `NSDate`, and `NSData` objects), not fundamental data types (e.g. `int`, `long`, `NSInteger`, etc.). This method automatically handles the aforementioned object types, and all other object types will be interpreted as text values using the object's `description` method.
 
 @param sql The SQL to be performed, with optional `?` placeholders.
 
 @param ... Optional parameters to bind to `?` placeholders in the SQL statement. These should be Objective-C objects (e.g. `NSString`, `NSNumber`, etc.), not fundamental C data types (e.g. `int`, `char *`, etc.).
 
 @return `YES` upon success; `NO` upon failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see lastError
 @see lastErrorCode
 @see lastErrorMessage
 @see [`sqlite3_bind`](http://sqlite.org/c3ref/bind_blob.html)
 
 @note This technique supports the use of `?` placeholders in the SQL, automatically binding any supplied value parameters to those placeholders. This approach is more robust than techniques that entail using `stringWithFormat` to manually build SQL statements, which can be problematic if the values happened to include any characters that needed to be quoted.
 
 @note If you want to use this from Swift, please note that you must include `FMDatabaseVariadic.swift` in your project. Without that, you cannot use this method directly, and instead have to use methods such as `<executeUpdate:withArgumentsInArray:>`.
 */

- (BOOL)executeUpdate:(NSString*)sql, ...;

/** Execute single update statement
 
 This method executes a single SQL update statement (i.e. any SQL that does not return results, such as `UPDATE`, `INSERT`, or `DELETE`. This method employs [`sqlite3_prepare_v2`](http://sqlite.org/c3ref/prepare.html) and [`sqlite_step`](http://sqlite.org/c3ref/step.html) to perform the update. Unlike the other `executeUpdate` methods, this uses printf-style formatters (e.g. `%s`, `%d`, etc.) to build the SQL. Do not use `?` placeholders in the SQL if you use this method.
 
 @param format The SQL to be performed, with `printf`-style escape sequences.
 
 @param ... Optional parameters to bind to use in conjunction with the `printf`-style escape sequences in the SQL statement.
 
 @return `YES` upon success; `NO` upon failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see executeUpdate:
 @see lastError
 @see lastErrorCode
 @see lastErrorMessage
 
 @note This method does not technically perform a traditional printf-style replacement. What this method actually does is replace the printf-style percent sequences with a SQLite `?` placeholder, and then bind values to that placeholder. Thus the following command
 
 [db executeUpdateWithFormat:@"INSERT INTO test (name) VALUES (%@)", @"Gus"];
 
 is actually replacing the `%@` with `?` placeholder, and then performing something equivalent to `<executeUpdate:>`
 
 [db executeUpdate:@"INSERT INTO test (name) VALUES (?)", @"Gus"];
 
 There are two reasons why this distinction is important. First, the printf-style escape sequences can only be used where it is permissible to use a SQLite `?` placeholder. You can use it only for values in SQL statements, but not for table names or column names or any other non-value context. This method also cannot be used in conjunction with `pragma` statements and the like. Second, note the lack of quotation marks in the SQL. The `VALUES` clause was _not_ `VALUES ('%@')` (like you might have to do if you built a SQL statement using `NSString` method `stringWithFormat`), but rather simply `VALUES (%@)`.
 */

- (BOOL)executeUpdateWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

/** Execute single update statement
 
 This method executes a single SQL update statement (i.e. any SQL that does not return results, such as `UPDATE`, `INSERT`, or `DELETE`. This method employs [`sqlite3_prepare_v2`](http://sqlite.org/c3ref/prepare.html) and [`sqlite3_bind`](http://sqlite.org/c3ref/bind_blob.html) binding any `?` placeholders in the SQL with the optional list of parameters.
 
 The optional values provided to this method should be objects (e.g. `NSString`, `NSNumber`, `NSNull`, `NSDate`, and `NSData` objects), not fundamental data types (e.g. `int`, `long`, `NSInteger`, etc.). This method automatically handles the aforementioned object types, and all other object types will be interpreted as text values using the object's `description` method.
 
 @param sql The SQL to be performed, with optional `?` placeholders.
 
 @param arguments A `NSArray` of objects to be used when binding values to the `?` placeholders in the SQL statement.
 
 @return `YES` upon success; `NO` upon failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see executeUpdate:values:error:
 @see lastError
 @see lastErrorCode
 @see lastErrorMessage
 */

- (BOOL)executeUpdate:(NSString*)sql withArgumentsInArray:(NSArray *)arguments;

/** Execute single update statement
 
 This method executes a single SQL update statement (i.e. any SQL that does not return results, such as `UPDATE`, `INSERT`, or `DELETE`. This method employs [`sqlite3_prepare_v2`](http://sqlite.org/c3ref/prepare.html) and [`sqlite3_bind`](http://sqlite.org/c3ref/bind_blob.html) binding any `?` placeholders in the SQL with the optional list of parameters.
 
 The optional values provided to this method should be objects (e.g. `NSString`, `NSNumber`, `NSNull`, `NSDate`, and `NSData` objects), not fundamental data types (e.g. `int`, `long`, `NSInteger`, etc.). This method automatically handles the aforementioned object types, and all other object types will be interpreted as text values using the object's `description` method.
 
 This is similar to `<executeUpdate:withArgumentsInArray:>`, except that this also accepts a pointer to a `NSError` pointer, so that errors can be returned.
 
 In Swift 2, this throws errors, as if it were defined as follows:
 
 `func executeUpdate(sql: String!, values: [AnyObject]!) throws -> Bool`
 
 @param sql The SQL to be performed, with optional `?` placeholders.
 
 @param values A `NSArray` of objects to be used when binding values to the `?` placeholders in the SQL statement.
 
 @param error A `NSError` object to receive any error object (if any).
 
 @return `YES` upon success; `NO` upon failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see lastError
 @see lastErrorCode
 @see lastErrorMessage
 
 */

- (BOOL)executeUpdate:(NSString*)sql values:(NSArray *)values error:(NSError * __autoreleasing *)error;

/** Execute single update statement
 
 This method executes a single SQL update statement (i.e. any SQL that does not return results, such as `UPDATE`, `INSERT`, or `DELETE`. This method employs [`sqlite3_prepare_v2`](http://sqlite.org/c3ref/prepare.html) and [`sqlite_step`](http://sqlite.org/c3ref/step.html) to perform the update. Unlike the other `executeUpdate` methods, this uses printf-style formatters (e.g. `%s`, `%d`, etc.) to build the SQL.
 
 The optional values provided to this method should be objects (e.g. `NSString`, `NSNumber`, `NSNull`, `NSDate`, and `NSData` objects), not fundamental data types (e.g. `int`, `long`, `NSInteger`, etc.). This method automatically handles the aforementioned object types, and all other object types will be interpreted as text values using the object's `description` method.
 
 @param sql The SQL to be performed, with optional `?` placeholders.
 
 @param arguments A `NSDictionary` of objects keyed by column names that will be used when binding values to the `?` placeholders in the SQL statement.
 
 @return `YES` upon success; `NO` upon failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see lastError
 @see lastErrorCode
 @see lastErrorMessage
 */

- (BOOL)executeUpdate:(NSString*)sql withParameterDictionary:(NSDictionary *)arguments;


/** Execute single update statement
 
 This method executes a single SQL update statement (i.e. any SQL that does not return results, such as `UPDATE`, `INSERT`, or `DELETE`. This method employs [`sqlite3_prepare_v2`](http://sqlite.org/c3ref/prepare.html) and [`sqlite_step`](http://sqlite.org/c3ref/step.html) to perform the update. Unlike the other `executeUpdate` methods, this uses printf-style formatters (e.g. `%s`, `%d`, etc.) to build the SQL.
 
 The optional values provided to this method should be objects (e.g. `NSString`, `NSNumber`, `NSNull`, `NSDate`, and `NSData` objects), not fundamental data types (e.g. `int`, `long`, `NSInteger`, etc.). This method automatically handles the aforementioned object types, and all other object types will be interpreted as text values using the object's `description` method.
 
 @param sql The SQL to be performed, with optional `?` placeholders.
 
 @param args A `va_list` of arguments.
 
 @return `YES` upon success; `NO` upon failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see lastError
 @see lastErrorCode
 @see lastErrorMessage
 */

- (BOOL)executeUpdate:(NSString*)sql withVAList: (va_list)args;

/** Execute multiple SQL statements
 
 This executes a series of SQL statements that are combined in a single string (e.g. the SQL generated by the `sqlite3` command line `.dump` command). This accepts no value parameters, but rather simply expects a single string with multiple SQL statements, each terminated with a semicolon. This uses `sqlite3_exec`.
 
 @param  sql  The SQL to be performed
 
 @return      `YES` upon success; `NO` upon failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see executeStatements:withResultBlock:
 @see [sqlite3_exec()](http://sqlite.org/c3ref/exec.html)
 
 */

- (BOOL)executeStatements:(NSString *)sql;

/** Execute multiple SQL statements with callback handler
 
 This executes a series of SQL statements that are combined in a single string (e.g. the SQL generated by the `sqlite3` command line `.dump` command). This accepts no value parameters, but rather simply expects a single string with multiple SQL statements, each terminated with a semicolon. This uses `sqlite3_exec`.
 
 @param sql       The SQL to be performed.
 @param block     A block that will be called for any result sets returned by any SQL statements.
 Note, if you supply this block, it must return integer value, zero upon success (this would be a good opportunity to use SQLITE_OK),
 non-zero value upon failure (which will stop the bulk execution of the SQL).  If a statement returns values, the block will be called with the results from the query in NSDictionary *resultsDictionary.
 This may be `nil` if you don't care to receive any results.
 
 @return          `YES` upon success; `NO` upon failure. If failed, you can call `<lastError>`,
 `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see executeStatements:
 @see [sqlite3_exec()](http://sqlite.org/c3ref/exec.html)
 
 */

- (BOOL)executeStatements:(NSString *)sql withResultBlock:(FMDBExecuteStatementsCallbackBlock)block;

/** Last insert rowid
 
 Each entry in an SQLite table has a unique 64-bit signed integer key called the "rowid". The rowid is always available as an undeclared column named `ROWID`, `OID`, or `_ROWID_` as long as those names are not also used by explicitly declared columns. If the table has a column of type `INTEGER PRIMARY KEY` then that column is another alias for the rowid.
 
 This routine returns the rowid of the most recent successful `INSERT` into the database from the database connection in the first argument. As of SQLite version 3.7.7, this routines records the last insert rowid of both ordinary tables and virtual tables. If no successful `INSERT`s have ever occurred on that database connection, zero is returned.
 
 @return The rowid of the last inserted row.
 
 @see [sqlite3_last_insert_rowid()](http://sqlite.org/c3ref/last_insert_rowid.html)
 
 */

- (int64_t)lastInsertRowId;

/** The number of rows changed by prior SQL statement.
 
 This function returns the number of database rows that were changed or inserted or deleted by the most recently completed SQL statement on the database connection specified by the first parameter. Only changes that are directly specified by the INSERT, UPDATE, or DELETE statement are counted.
 
 @return The number of rows changed by prior SQL statement.
 
 @see [sqlite3_changes()](http://sqlite.org/c3ref/changes.html)
 
 */

- (int)changes;


///-------------------------
/// @name Retrieving results
///-------------------------

/** Execute select statement
 
 Executing queries returns an `<FMResultSet>` object if successful, and `nil` upon failure.  Like executing updates, there is a variant that accepts an `NSError **` parameter.  Otherwise you should use the `<lastErrorMessage>` and `<lastErrorMessage>` methods to determine why a query failed.
 
 In order to iterate through the results of your query, you use a `while()` loop.  You also need to "step" (via `<[FMResultSet next]>`) from one record to the other.
 
 This method employs [`sqlite3_bind`](http://sqlite.org/c3ref/bind_blob.html) for any optional value parameters. This  properly escapes any characters that need escape sequences (e.g. quotation marks), which eliminates simple SQL errors as well as protects against SQL injection attacks. This method natively handles `NSString`, `NSNumber`, `NSNull`, `NSDate`, and `NSData` objects. All other object types will be interpreted as text values using the object's `description` method.
 
 @param sql The SELECT statement to be performed, with optional `?` placeholders.
 
 @param ... Optional parameters to bind to `?` placeholders in the SQL statement. These should be Objective-C objects (e.g. `NSString`, `NSNumber`, etc.), not fundamental C data types (e.g. `int`, `char *`, etc.).
 
 @return A `<FMResultSet>` for the result set upon success; `nil` upon failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see FMResultSet
 @see [`FMResultSet next`](<[FMResultSet next]>)
 @see [`sqlite3_bind`](http://sqlite.org/c3ref/bind_blob.html)
 
 @note If you want to use this from Swift, please note that you must include `FMDatabaseVariadic.swift` in your project. Without that, you cannot use this method directly, and instead have to use methods such as `<executeQuery:withArgumentsInArray:>`.
 */

- (FMResultSet *)executeQuery:(NSString*)sql, ...;

/** Execute select statement
 
 Executing queries returns an `<FMResultSet>` object if successful, and `nil` upon failure.  Like executing updates, there is a variant that accepts an `NSError **` parameter.  Otherwise you should use the `<lastErrorMessage>` and `<lastErrorMessage>` methods to determine why a query failed.
 
 In order to iterate through the results of your query, you use a `while()` loop.  You also need to "step" (via `<[FMResultSet next]>`) from one record to the other.
 
 @param format The SQL to be performed, with `printf`-style escape sequences.
 
 @param ... Optional parameters to bind to use in conjunction with the `printf`-style escape sequences in the SQL statement.
 
 @return A `<FMResultSet>` for the result set upon success; `nil` upon failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see executeQuery:
 @see FMResultSet
 @see [`FMResultSet next`](<[FMResultSet next]>)
 
 @note This method does not technically perform a traditional printf-style replacement. What this method actually does is replace the printf-style percent sequences with a SQLite `?` placeholder, and then bind values to that placeholder. Thus the following command
 
 [db executeQueryWithFormat:@"SELECT * FROM test WHERE name=%@", @"Gus"];
 
 is actually replacing the `%@` with `?` placeholder, and then performing something equivalent to `<executeQuery:>`
 
 [db executeQuery:@"SELECT * FROM test WHERE name=?", @"Gus"];
 
 There are two reasons why this distinction is important. First, the printf-style escape sequences can only be used where it is permissible to use a SQLite `?` placeholder. You can use it only for values in SQL statements, but not for table names or column names or any other non-value context. This method also cannot be used in conjunction with `pragma` statements and the like. Second, note the lack of quotation marks in the SQL. The `WHERE` clause was _not_ `WHERE name='%@'` (like you might have to do if you built a SQL statement using `NSString` method `stringWithFormat`), but rather simply `WHERE name=%@`.
 
 */

- (FMResultSet *)executeQueryWithFormat:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);

/** Execute select statement
 
 Executing queries returns an `<FMResultSet>` object if successful, and `nil` upon failure.  Like executing updates, there is a variant that accepts an `NSError **` parameter.  Otherwise you should use the `<lastErrorMessage>` and `<lastErrorMessage>` methods to determine why a query failed.
 
 In order to iterate through the results of your query, you use a `while()` loop.  You also need to "step" (via `<[FMResultSet next]>`) from one record to the other.
 
 @param sql The SELECT statement to be performed, with optional `?` placeholders.
 
 @param arguments A `NSArray` of objects to be used when binding values to the `?` placeholders in the SQL statement.
 
 @return A `<FMResultSet>` for the result set upon success; `nil` upon failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see -executeQuery:values:error:
 @see FMResultSet
 @see [`FMResultSet next`](<[FMResultSet next]>)
 */

- (FMResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments;

/** Execute select statement
 
 Executing queries returns an `<FMResultSet>` object if successful, and `nil` upon failure.  Like executing updates, there is a variant that accepts an `NSError **` parameter.  Otherwise you should use the `<lastErrorMessage>` and `<lastErrorMessage>` methods to determine why a query failed.
 
 In order to iterate through the results of your query, you use a `while()` loop.  You also need to "step" (via `<[FMResultSet next]>`) from one record to the other.
 
 This is similar to `<executeQuery:withArgumentsInArray:>`, except that this also accepts a pointer to a `NSError` pointer, so that errors can be returned.
 
 In Swift 2, this throws errors, as if it were defined as follows:
 
 `func executeQuery(sql: String!, values: [AnyObject]!) throws  -> FMResultSet!`
 
 @param sql The SELECT statement to be performed, with optional `?` placeholders.
 
 @param values A `NSArray` of objects to be used when binding values to the `?` placeholders in the SQL statement.
 
 @param error A `NSError` object to receive any error object (if any).
 
 @return A `<FMResultSet>` for the result set upon success; `nil` upon failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see FMResultSet
 @see [`FMResultSet next`](<[FMResultSet next]>)
 
 @note When called from Swift, only use the first two parameters, `sql` and `values`. This but throws the error.
 
 */

- (FMResultSet *)executeQuery:(NSString *)sql values:(NSArray *)values error:(NSError * __autoreleasing *)error;

/** Execute select statement
 
 Executing queries returns an `<FMResultSet>` object if successful, and `nil` upon failure.  Like executing updates, there is a variant that accepts an `NSError **` parameter.  Otherwise you should use the `<lastErrorMessage>` and `<lastErrorMessage>` methods to determine why a query failed.
 
 In order to iterate through the results of your query, you use a `while()` loop.  You also need to "step" (via `<[FMResultSet next]>`) from one record to the other.
 
 @param sql The SELECT statement to be performed, with optional `?` placeholders.
 
 @param arguments A `NSDictionary` of objects keyed by column names that will be used when binding values to the `?` placeholders in the SQL statement.
 
 @return A `<FMResultSet>` for the result set upon success; `nil` upon failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see FMResultSet
 @see [`FMResultSet next`](<[FMResultSet next]>)
 */

- (FMResultSet *)executeQuery:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments;


// Documentation forthcoming.
- (FMResultSet *)executeQuery:(NSString*)sql withVAList: (va_list)args;

///-------------------
/// @name Transactions
///-------------------

/** Begin a transaction
 
 @return `YES` on success; `NO` on failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see commit
 @see rollback
 @see beginDeferredTransaction
 @see inTransaction
 */

- (BOOL)beginTransaction;

/** Begin a deferred transaction
 
 @return `YES` on success; `NO` on failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see commit
 @see rollback
 @see beginTransaction
 @see inTransaction
 */

- (BOOL)beginDeferredTransaction;

/** Commit a transaction
 
 Commit a transaction that was initiated with either `<beginTransaction>` or with `<beginDeferredTransaction>`.
 
 @return `YES` on success; `NO` on failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see beginTransaction
 @see beginDeferredTransaction
 @see rollback
 @see inTransaction
 */

- (BOOL)commit;

/** Rollback a transaction
 
 Rollback a transaction that was initiated with either `<beginTransaction>` or with `<beginDeferredTransaction>`.
 
 @return `YES` on success; `NO` on failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see beginTransaction
 @see beginDeferredTransaction
 @see commit
 @see inTransaction
 */

- (BOOL)rollback;

/** Identify whether currently in a transaction or not
 
 @return `YES` if currently within transaction; `NO` if not.
 
 @see beginTransaction
 @see beginDeferredTransaction
 @see commit
 @see rollback
 */

- (BOOL)inTransaction;


///----------------------------------------
/// @name Cached statements and result sets
///----------------------------------------

/** Clear cached statements */

- (void)clearCachedStatements;

/** Close all open result sets */

- (void)closeOpenResultSets;

/** Whether database has any open result sets
 
 @return `YES` if there are open result sets; `NO` if not.
 */

- (BOOL)hasOpenResultSets;

/** Return whether should cache statements or not
 
 @return `YES` if should cache statements; `NO` if not.
 */

- (BOOL)shouldCacheStatements;

/** Set whether should cache statements or not
 
 @param value `YES` if should cache statements; `NO` if not.
 */

- (void)setShouldCacheStatements:(BOOL)value;

/** Interupt pending database operation
 
 This method causes any pending database operation to abort and return at its earliest opportunity
 
 @return `YES` on success; `NO` on failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 */

- (BOOL)interrupt;

///-------------------------
/// @name Encryption methods
///-------------------------

/** Set encryption key.
 
 @param key The key to be used.
 
 @return `YES` if success, `NO` on error.
 
 @see https://www.zetetic.net/sqlcipher/
 
 @warning You need to have purchased the sqlite encryption extensions for this method to work.
 */

- (BOOL)setKey:(NSString*)key;

/** Reset encryption key
 
 @param key The key to be used.
 
 @return `YES` if success, `NO` on error.
 
 @see https://www.zetetic.net/sqlcipher/
 
 @warning You need to have purchased the sqlite encryption extensions for this method to work.
 */

- (BOOL)rekey:(NSString*)key;

/** Set encryption key using `keyData`.
 
 @param keyData The `NSData` to be used.
 
 @return `YES` if success, `NO` on error.
 
 @see https://www.zetetic.net/sqlcipher/
 
 @warning You need to have purchased the sqlite encryption extensions for this method to work.
 */

- (BOOL)setKeyWithData:(NSData *)keyData;

/** Reset encryption key using `keyData`.
 
 @param keyData The `NSData` to be used.
 
 @return `YES` if success, `NO` on error.
 
 @see https://www.zetetic.net/sqlcipher/
 
 @warning You need to have purchased the sqlite encryption extensions for this method to work.
 */

- (BOOL)rekeyWithData:(NSData *)keyData;


///------------------------------
/// @name General inquiry methods
///------------------------------

/** The path of the database file
 
 @return path of database.
 
 */

- (NSString *)databasePath;

/** The underlying SQLite handle
 
 @return The `sqlite3` pointer.
 
 */

- (void*)sqliteHandle;


///-----------------------------
/// @name Retrieving error codes
///-----------------------------

/** Last error message
 
 Returns the English-language text that describes the most recent failed SQLite API call associated with a database connection. If a prior API call failed but the most recent API call succeeded, this return value is undefined.
 
 @return `NSString` of the last error message.
 
 @see [sqlite3_errmsg()](http://sqlite.org/c3ref/errcode.html)
 @see lastErrorCode
 @see lastError
 
 */

- (NSString*)lastErrorMessage;

/** Last error code
 
 Returns the numeric result code or extended result code for the most recent failed SQLite API call associated with a database connection. If a prior API call failed but the most recent API call succeeded, this return value is undefined.
 
 @return Integer value of the last error code.
 
 @see [sqlite3_errcode()](http://sqlite.org/c3ref/errcode.html)
 @see lastErrorMessage
 @see lastError
 
 */

- (int)lastErrorCode;

/** Had error
 
 @return `YES` if there was an error, `NO` if no error.
 
 @see lastError
 @see lastErrorCode
 @see lastErrorMessage
 
 */

- (BOOL)hadError;

/** Last error
 
 @return `NSError` representing the last error.
 
 @see lastErrorCode
 @see lastErrorMessage
 
 */

- (NSError*)lastError;


// description forthcoming
- (void)setMaxBusyRetryTimeInterval:(NSTimeInterval)timeoutInSeconds;
- (NSTimeInterval)maxBusyRetryTimeInterval;


///------------------
/// @name Save points
///------------------

/** Start save point
 
 @param name Name of save point.
 
 @param outErr A `NSError` object to receive any error object (if any).
 
 @return `YES` on success; `NO` on failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see releaseSavePointWithName:error:
 @see rollbackToSavePointWithName:error:
 */

- (BOOL)startSavePointWithName:(NSString*)name error:(NSError**)outErr;

/** Release save point
 
 @param name Name of save point.
 
 @param outErr A `NSError` object to receive any error object (if any).
 
 @return `YES` on success; `NO` on failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see startSavePointWithName:error:
 @see rollbackToSavePointWithName:error:
 
 */

- (BOOL)releaseSavePointWithName:(NSString*)name error:(NSError**)outErr;

/** Roll back to save point
 
 @param name Name of save point.
 @param outErr A `NSError` object to receive any error object (if any).
 
 @return `YES` on success; `NO` on failure. If failed, you can call `<lastError>`, `<lastErrorCode>`, or `<lastErrorMessage>` for diagnostic information regarding the failure.
 
 @see startSavePointWithName:error:
 @see releaseSavePointWithName:error:
 
 */

- (BOOL)rollbackToSavePointWithName:(NSString*)name error:(NSError**)outErr;

/** Start save point
 
 @param block Block of code to perform from within save point.
 
 @return The NSError corresponding to the error, if any. If no error, returns `nil`.
 
 @see startSavePointWithName:error:
 @see releaseSavePointWithName:error:
 @see rollbackToSavePointWithName:error:
 
 */

- (NSError*)inSavePoint:(void (^)(BOOL *rollback))block;

///----------------------------
/// @name SQLite library status
///----------------------------

/** Test to see if the library is threadsafe
 
 @return `NO` if and only if SQLite was compiled with mutexing code omitted due to the SQLITE_THREADSAFE compile-time option being set to 0.
 
 @see [sqlite3_threadsafe()](http://sqlite.org/c3ref/threadsafe.html)
 */

+ (BOOL)isSQLiteThreadSafe;

/** Run-time library version numbers
 
 @return The sqlite library version string.
 
 @see [sqlite3_libversion()](http://sqlite.org/c3ref/libversion.html)
 */

+ (NSString*)sqliteLibVersion;


+ (NSString*)FMDBUserVersion;

+ (SInt32)FMDBVersion;


///------------------------
/// @name Make SQL function
///------------------------

/** Adds SQL functions or aggregates or to redefine the behavior of existing SQL functions or aggregates.
 
 For example:
 
 [queue inDatabase:^(FMDatabase *adb) {
 
 [adb executeUpdate:@"create table ftest (foo text)"];
 [adb executeUpdate:@"insert into ftest values ('hello')"];
 [adb executeUpdate:@"insert into ftest values ('hi')"];
 [adb executeUpdate:@"insert into ftest values ('not h!')"];
 [adb executeUpdate:@"insert into ftest values ('definitely not h!')"];
 
 [adb makeFunctionNamed:@"StringStartsWithH" maximumArguments:1 withBlock:^(sqlite3_context *context, int aargc, sqlite3_value **aargv) {
 if (sqlite3_value_type(aargv[0]) == SQLITE_TEXT) {
 @autoreleasepool {
 const char *c = (const char *)sqlite3_value_text(aargv[0]);
 NSString *s = [NSString stringWithUTF8String:c];
 sqlite3_result_int(context, [s hasPrefix:@"h"]);
 }
 }
 else {
 NSLog(@"Unknown formart for StringStartsWithH (%d) %s:%d", sqlite3_value_type(aargv[0]), __FUNCTION__, __LINE__);
 sqlite3_result_null(context);
 }
 }];
 
 int rowCount = 0;
 FMResultSet *ars = [adb executeQuery:@"select * from ftest where StringStartsWithH(foo)"];
 while ([ars next]) {
 rowCount++;
 NSLog(@"Does %@ start with 'h'?", [rs stringForColumnIndex:0]);
 }
 FMDBQuickCheck(rowCount == 2);
 }];
 
 @param name Name of function
 
 @param count Maximum number of parameters
 
 @param block The block of code for the function
 
 @see [sqlite3_create_function()](http://sqlite.org/c3ref/create_function.html)
 */

- (void)makeFunctionNamed:(NSString*)name maximumArguments:(int)count withBlock:(void (^)(void *context, int argc, void **argv))block;


///---------------------
/// @name Date formatter
///---------------------

/** Generate an `NSDateFormatter` that won't be broken by permutations of timezones or locales.
 
 Use this method to generate values to set the dateFormat property.
 
 Example:
 
 myDB.dateFormat = [FMDatabase storeableDateFormat:@"yyyy-MM-dd HH:mm:ss"];
 
 @param format A valid NSDateFormatter format string.
 
 @return A `NSDateFormatter` that can be used for converting dates to strings and vice versa.
 
 @see hasDateFormatter
 @see setDateFormat:
 @see dateFromString:
 @see stringFromDate:
 @see storeableDateFormat:
 
 @warning Note that `NSDateFormatter` is not thread-safe, so the formatter generated by this method should be assigned to only one FMDB instance and should not be used for other purposes.
 
 */

+ (NSDateFormatter *)storeableDateFormat:(NSString *)format;

/** Test whether the database has a date formatter assigned.
 
 @return `YES` if there is a date formatter; `NO` if not.
 
 @see hasDateFormatter
 @see setDateFormat:
 @see dateFromString:
 @see stringFromDate:
 @see storeableDateFormat:
 */

- (BOOL)hasDateFormatter;

/** Set to a date formatter to use string dates with sqlite instead of the default UNIX timestamps.
 
 @param format Set to nil to use UNIX timestamps. Defaults to nil. Should be set using a formatter generated using FMDatabase::storeableDateFormat.
 
 @see hasDateFormatter
 @see setDateFormat:
 @see dateFromString:
 @see stringFromDate:
 @see storeableDateFormat:
 
 @warning Note there is no direct getter for the `NSDateFormatter`, and you should not use the formatter you pass to FMDB for other purposes, as `NSDateFormatter` is not thread-safe.
 */

- (void)setDateFormat:(NSDateFormatter *)format;

/** Convert the supplied NSString to NSDate, using the current database formatter.
 
 @param s `NSString` to convert to `NSDate`.
 
 @return The `NSDate` object; or `nil` if no formatter is set.
 
 @see hasDateFormatter
 @see setDateFormat:
 @see dateFromString:
 @see stringFromDate:
 @see storeableDateFormat:
 */

- (NSDate *)dateFromString:(NSString *)s;

/** Convert the supplied NSDate to NSString, using the current database formatter.
 
 @param date `NSDate` of date to convert to `NSString`.
 
 @return The `NSString` representation of the date; `nil` if no formatter is set.
 
 @see hasDateFormatter
 @see setDateFormat:
 @see dateFromString:
 @see stringFromDate:
 @see storeableDateFormat:
 */

- (NSString *)stringFromDate:(NSDate *)date;

@end


/** Objective-C wrapper for `sqlite3_stmt`
 
 This is a wrapper for a SQLite `sqlite3_stmt`. Generally when using FMDB you will not need to interact directly with `FMStatement`, but rather with `<FMDatabase>` and `<FMResultSet>` only.
 
 ### See also
 
 - `<FMDatabase>`
 - `<FMResultSet>`
 - [`sqlite3_stmt`](http://www.sqlite.org/c3ref/stmt.html)
 */

@interface FMStatement : NSObject {
    void *_statement;
    NSString *_query;
    long _useCount;
    BOOL _inUse;
}

///-----------------
/// @name Properties
///-----------------

/** Usage count */

@property (atomic, assign) long useCount;

/** SQL statement */

@property (atomic, retain) NSString *query;

/** SQLite sqlite3_stmt
 
 @see [`sqlite3_stmt`](http://www.sqlite.org/c3ref/stmt.html)
 */

@property (atomic, assign) void *statement;

/** Indication of whether the statement is in use */

@property (atomic, assign) BOOL inUse;

///----------------------------
/// @name Closing and Resetting
///----------------------------

/** Close statement */

- (void)close;

/** Reset statement */

- (void)reset;

@end

#pragma clang diagnostic pop

//
//  FMDatabaseAdditions.h
//  fmdb
//
//  Created by August Mueller on 10/30/05.
//  Copyright 2005 Flying Meat Inc.. All rights reserved.
//



/** Category of additions for `<FMDatabase>` class.
 
 ### See also
 
 - `<FMDatabase>`
 */

@interface FMDatabase (FMDatabaseAdditions)

///----------------------------------------
/// @name Return results of SQL to variable
///----------------------------------------

/** Return `int` value for query
 
 @param query The SQL query to be performed.
 @param ... A list of parameters that will be bound to the `?` placeholders in the SQL query.
 
 @return `int` value.
 
 @note To use this method from Swift, you must include `FMDatabaseAdditionsVariadic.swift` in your project.
 */

- (int)intForQuery:(NSString*)query, ...;

/** Return `long` value for query
 
 @param query The SQL query to be performed.
 @param ... A list of parameters that will be bound to the `?` placeholders in the SQL query.
 
 @return `long` value.
 
 @note To use this method from Swift, you must include `FMDatabaseAdditionsVariadic.swift` in your project.
 */

- (long)longForQuery:(NSString*)query, ...;

/** Return `BOOL` value for query
 
 @param query The SQL query to be performed.
 @param ... A list of parameters that will be bound to the `?` placeholders in the SQL query.
 
 @return `BOOL` value.
 
 @note To use this method from Swift, you must include `FMDatabaseAdditionsVariadic.swift` in your project.
 */

- (BOOL)boolForQuery:(NSString*)query, ...;

/** Return `double` value for query
 
 @param query The SQL query to be performed.
 @param ... A list of parameters that will be bound to the `?` placeholders in the SQL query.
 
 @return `double` value.
 
 @note To use this method from Swift, you must include `FMDatabaseAdditionsVariadic.swift` in your project.
 */

- (double)doubleForQuery:(NSString*)query, ...;

/** Return `NSString` value for query
 
 @param query The SQL query to be performed.
 @param ... A list of parameters that will be bound to the `?` placeholders in the SQL query.
 
 @return `NSString` value.
 
 @note To use this method from Swift, you must include `FMDatabaseAdditionsVariadic.swift` in your project.
 */

- (NSString*)stringForQuery:(NSString*)query, ...;

/** Return `NSData` value for query
 
 @param query The SQL query to be performed.
 @param ... A list of parameters that will be bound to the `?` placeholders in the SQL query.
 
 @return `NSData` value.
 
 @note To use this method from Swift, you must include `FMDatabaseAdditionsVariadic.swift` in your project.
 */

- (NSData*)dataForQuery:(NSString*)query, ...;

/** Return `NSDate` value for query
 
 @param query The SQL query to be performed.
 @param ... A list of parameters that will be bound to the `?` placeholders in the SQL query.
 
 @return `NSDate` value.
 
 @note To use this method from Swift, you must include `FMDatabaseAdditionsVariadic.swift` in your project.
 */

- (NSDate*)dateForQuery:(NSString*)query, ...;


// Notice that there's no dataNoCopyForQuery:.
// That would be a bad idea, because we close out the result set, and then what
// happens to the data that we just didn't copy?  Who knows, not I.


///--------------------------------
/// @name Schema related operations
///--------------------------------

/** Does table exist in database?
 
 @param tableName The name of the table being looked for.
 
 @return `YES` if table found; `NO` if not found.
 */

- (BOOL)tableExists:(NSString*)tableName;

/** The schema of the database.
 
 This will be the schema for the entire database. For each entity, each row of the result set will include the following fields:
 
 - `type` - The type of entity (e.g. table, index, view, or trigger)
 - `name` - The name of the object
 - `tbl_name` - The name of the table to which the object references
 - `rootpage` - The page number of the root b-tree page for tables and indices
 - `sql` - The SQL that created the entity
 
 @return `FMResultSet` of schema; `nil` on error.
 
 @see [SQLite File Format](http://www.sqlite.org/fileformat.html)
 */

- (FMResultSet*)getSchema;

/** The schema of the database.
 
 This will be the schema for a particular table as report by SQLite `PRAGMA`, for example:
 
 PRAGMA table_info('employees')
 
 This will report:
 
 - `cid` - The column ID number
 - `name` - The name of the column
 - `type` - The data type specified for the column
 - `notnull` - whether the field is defined as NOT NULL (i.e. values required)
 - `dflt_value` - The default value for the column
 - `pk` - Whether the field is part of the primary key of the table
 
 @param tableName The name of the table for whom the schema will be returned.
 
 @return `FMResultSet` of schema; `nil` on error.
 
 @see [table_info](http://www.sqlite.org/pragma.html#pragma_table_info)
 */

- (FMResultSet*)getTableSchema:(NSString*)tableName;

/** Test to see if particular column exists for particular table in database
 
 @param columnName The name of the column.
 
 @param tableName The name of the table.
 
 @return `YES` if column exists in table in question; `NO` otherwise.
 */

- (BOOL)columnExists:(NSString*)columnName inTableWithName:(NSString*)tableName;

/** Test to see if particular column exists for particular table in database
 
 @param columnName The name of the column.
 
 @param tableName The name of the table.
 
 @return `YES` if column exists in table in question; `NO` otherwise.
 
 @see columnExists:inTableWithName:
 
 @warning Deprecated - use `<columnExists:inTableWithName:>` instead.
 */

- (BOOL)columnExists:(NSString*)tableName columnName:(NSString*)columnName __attribute__ ((deprecated));


/** Validate SQL statement
 
 This validates SQL statement by performing `sqlite3_prepare_v2`, but not returning the results, but instead immediately calling `sqlite3_finalize`.
 
 @param sql The SQL statement being validated.
 
 @param error This is a pointer to a `NSError` object that will receive the autoreleased `NSError` object if there was any error. If this is `nil`, no `NSError` result will be returned.
 
 @return `YES` if validation succeeded without incident; `NO` otherwise.
 
 */

- (BOOL)validateSQL:(NSString*)sql error:(NSError**)error;


///-----------------------------------
/// @name Application identifier tasks
///-----------------------------------

/** Retrieve application ID
 
 @return The `uint32_t` numeric value of the application ID.
 
 @see setApplicationID:
 */

- (uint32_t)applicationID;

/** Set the application ID
 
 @param appID The `uint32_t` numeric value of the application ID.
 
 @see applicationID
 */

- (void)setApplicationID:(uint32_t)appID;

#if TARGET_OS_MAC && !TARGET_OS_IPHONE
/** Retrieve application ID string
 
 @return The `NSString` value of the application ID.
 
 @see setApplicationIDString:
 */


- (NSString*)applicationIDString;

/** Set the application ID string
 
 @param string The `NSString` value of the application ID.
 
 @see applicationIDString
 */

- (void)setApplicationIDString:(NSString*)string;

#endif

///-----------------------------------
/// @name user version identifier tasks
///-----------------------------------

/** Retrieve user version
 
 @return The `uint32_t` numeric value of the user version.
 
 @see setUserVersion:
 */

- (uint32_t)userVersion;

/** Set the user-version
 
 @param version The `uint32_t` numeric value of the user version.
 
 @see userVersion
 */

- (void)setUserVersion:(uint32_t)version;

@end
//
//  FMDatabaseQueue.h
//  fmdb
//
//  Created by August Mueller on 6/22/11.
//  Copyright 2011 Flying Meat Inc. All rights reserved.
//


@class FMDatabase;

/** To perform queries and updates on multiple threads, you'll want to use `FMDatabaseQueue`.
 
 Using a single instance of `<FMDatabase>` from multiple threads at once is a bad idea.  It has always been OK to make a `<FMDatabase>` object *per thread*.  Just don't share a single instance across threads, and definitely not across multiple threads at the same time.
 
 Instead, use `FMDatabaseQueue`. Here's how to use it:
 
 First, make your queue.
 
 FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:aPath];
 
 Then use it like so:
 
 [queue inDatabase:^(FMDatabase *db) {
 [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:1]];
 [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:2]];
 [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:3]];
 
 FMResultSet *rs = [db executeQuery:@"select * from foo"];
 while ([rs next]) {
 //…
 }
 }];
 
 An easy way to wrap things up in a transaction can be done like this:
 
 [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
 [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:1]];
 [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:2]];
 [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:3]];
 
 if (whoopsSomethingWrongHappened) {
 *rollback = YES;
 return;
 }
 // etc…
 [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:4]];
 }];
 
 `FMDatabaseQueue` will run the blocks on a serialized queue (hence the name of the class).  So if you call `FMDatabaseQueue`'s methods from multiple threads at the same time, they will be executed in the order they are received.  This way queries and updates won't step on each other's toes, and every one is happy.
 
 ### See also
 
 - `<FMDatabase>`
 
 @warning Do not instantiate a single `<FMDatabase>` object and use it across multiple threads. Use `FMDatabaseQueue` instead.
 
 @warning The calls to `FMDatabaseQueue`'s methods are blocking.  So even though you are passing along blocks, they will **not** be run on another thread.
 
 */

@interface FMDatabaseQueue : NSObject {
    NSString            *_path;
    dispatch_queue_t    _queue;
    FMDatabase          *_db;
    int                 _openFlags;
    NSString            *_vfsName;
}

/** Path of database */

@property (atomic, retain) NSString *path;

/** Open flags */

@property (atomic, readonly) int openFlags;

/**  Custom virtual file system name */

@property (atomic, copy) NSString *vfsName;

///----------------------------------------------------
/// @name Initialization, opening, and closing of queue
///----------------------------------------------------

/** Create queue using path.
 
 @param aPath The file path of the database.
 
 @return The `FMDatabaseQueue` object. `nil` on error.
 */

+ (instancetype)databaseQueueWithPath:(NSString*)aPath;

/** Create queue using path and specified flags.
 
 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database
 
 @return The `FMDatabaseQueue` object. `nil` on error.
 */
+ (instancetype)databaseQueueWithPath:(NSString*)aPath flags:(int)openFlags;

/** Create queue using path.
 
 @param aPath The file path of the database.
 
 @return The `FMDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString*)aPath;

/** Create queue using path and specified flags.
 
 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database
 
 @return The `FMDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString*)aPath flags:(int)openFlags;

/** Create queue using path and specified flags.
 
 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database
 @param vfsName The name of a custom virtual file system
 
 @return The `FMDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString*)aPath flags:(int)openFlags vfs:(NSString *)vfsName;

/** Returns the Class of 'FMDatabase' subclass, that will be used to instantiate database object.
 
 Subclasses can override this method to return specified Class of 'FMDatabase' subclass.
 
 @return The Class of 'FMDatabase' subclass, that will be used to instantiate database object.
 */

+ (Class)databaseClass;

/** Close database used by queue. */

- (void)close;

/** Interupt pending database operation. */

- (void)interrupt;

///-----------------------------------------------
/// @name Dispatching database operations to queue
///-----------------------------------------------

/** Synchronously perform database operations on queue.
 
 @param block The code to be run on the queue of `FMDatabaseQueue`
 */

- (void)inDatabase:(void (^)(FMDatabase *db))block;

/** Synchronously perform database operations on queue, using transactions.
 
 @param block The code to be run on the queue of `FMDatabaseQueue`
 */

- (void)inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;

/** Synchronously perform database operations on queue, using deferred transactions.
 
 @param block The code to be run on the queue of `FMDatabaseQueue`
 */

- (void)inDeferredTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;

///-----------------------------------------------
/// @name Dispatching database operations to queue
///-----------------------------------------------

/** Synchronously perform database operations using save point.
 
 @param block The code to be run on the queue of `FMDatabaseQueue`
 */

// NOTE: you can not nest these, since calling it will pull another database out of the pool and you'll get a deadlock.
// If you need to nest, use FMDatabase's startSavePointWithName:error: instead.
- (NSError*)inSavePoint:(void (^)(FMDatabase *db, BOOL *rollback))block;

@end

//
//  FMDatabasePool.h
//  fmdb
//
//  Created by August Mueller on 6/22/11.
//  Copyright 2011 Flying Meat Inc. All rights reserved.
//


@class FMDatabase;

/** Pool of `<FMDatabase>` objects.
 
 ### See also
 
 - `<FMDatabaseQueue>`
 - `<FMDatabase>`
 
 @warning Before using `FMDatabasePool`, please consider using `<FMDatabaseQueue>` instead.
 
 If you really really really know what you're doing and `FMDatabasePool` is what
 you really really need (ie, you're using a read only database), OK you can use
 it.  But just be careful not to deadlock!
 
 For an example on deadlocking, search for:
 `ONLY_USE_THE_POOL_IF_YOU_ARE_DOING_READS_OTHERWISE_YOULL_DEADLOCK_USE_FMDATABASEQUEUE_INSTEAD`
 in the main.m file.
 */

@interface FMDatabasePool : NSObject {
    NSString            *_path;
    
    dispatch_queue_t    _lockQueue;
    
    NSMutableArray      *_databaseInPool;
    NSMutableArray      *_databaseOutPool;
    
    __unsafe_unretained id _delegate;
    
    NSUInteger          _maximumNumberOfDatabasesToCreate;
    int                 _openFlags;
    NSString            *_vfsName;
}

/** Database path */

@property (atomic, retain) NSString *path;

/** Delegate object */

@property (atomic, assign) id delegate;

/** Maximum number of databases to create */

@property (atomic, assign) NSUInteger maximumNumberOfDatabasesToCreate;

/** Open flags */

@property (atomic, readonly) int openFlags;

/**  Custom virtual file system name */

@property (atomic, copy) NSString *vfsName;


///---------------------
/// @name Initialization
///---------------------

/** Create pool using path.
 
 @param aPath The file path of the database.
 
 @return The `FMDatabasePool` object. `nil` on error.
 */

+ (instancetype)databasePoolWithPath:(NSString*)aPath;

/** Create pool using path and specified flags
 
 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database
 
 @return The `FMDatabasePool` object. `nil` on error.
 */

+ (instancetype)databasePoolWithPath:(NSString*)aPath flags:(int)openFlags;

/** Create pool using path.
 
 @param aPath The file path of the database.
 
 @return The `FMDatabasePool` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString*)aPath;

/** Create pool using path and specified flags.
 
 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database
 
 @return The `FMDatabasePool` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString*)aPath flags:(int)openFlags;

/** Create pool using path and specified flags.
 
 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database
 @param vfsName The name of a custom virtual file system
 
 @return The `FMDatabasePool` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString*)aPath flags:(int)openFlags vfs:(NSString *)vfsName;

/** Returns the Class of 'FMDatabase' subclass, that will be used to instantiate database object.
 
 Subclasses can override this method to return specified Class of 'FMDatabase' subclass.
 
 @return The Class of 'FMDatabase' subclass, that will be used to instantiate database object.
 */

+ (Class)databaseClass;

///------------------------------------------------
/// @name Keeping track of checked in/out databases
///------------------------------------------------

/** Number of checked-in databases in pool
 
 @returns Number of databases
 */

- (NSUInteger)countOfCheckedInDatabases;

/** Number of checked-out databases in pool
 
 @returns Number of databases
 */

- (NSUInteger)countOfCheckedOutDatabases;

/** Total number of databases in pool
 
 @returns Number of databases
 */

- (NSUInteger)countOfOpenDatabases;

/** Release all databases in pool */

- (void)releaseAllDatabases;

///------------------------------------------
/// @name Perform database operations in pool
///------------------------------------------

/** Synchronously perform database operations in pool.
 
 @param block The code to be run on the `FMDatabasePool` pool.
 */

- (void)inDatabase:(void (^)(FMDatabase *db))block;

/** Synchronously perform database operations in pool using transaction.
 
 @param block The code to be run on the `FMDatabasePool` pool.
 */

- (void)inTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;

/** Synchronously perform database operations in pool using deferred transaction.
 
 @param block The code to be run on the `FMDatabasePool` pool.
 */

- (void)inDeferredTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;

/** Synchronously perform database operations in pool using save point.
 
 @param block The code to be run on the `FMDatabasePool` pool.
 
 @return `NSError` object if error; `nil` if successful.
 
 @warning You can not nest these, since calling it will pull another database out of the pool and you'll get a deadlock. If you need to nest, use `<[FMDatabase startSavePointWithName:error:]>` instead.
 */

- (NSError*)inSavePoint:(void (^)(FMDatabase *db, BOOL *rollback))block;

@end


/** FMDatabasePool delegate category
 
 This is a category that defines the protocol for the FMDatabasePool delegate
 */

@interface NSObject (FMDatabasePoolDelegate)

/** Asks the delegate whether database should be added to the pool.
 
 @param pool     The `FMDatabasePool` object.
 @param database The `FMDatabase` object.
 
 @return `YES` if it should add database to pool; `NO` if not.
 
 */

- (BOOL)databasePool:(FMDatabasePool*)pool shouldAddDatabaseToPool:(FMDatabase*)database;

/** Tells the delegate that database was added to the pool.
 
 @param pool     The `FMDatabasePool` object.
 @param database The `FMDatabase` object.
 
 */

- (void)databasePool:(FMDatabasePool*)pool didAddDatabase:(FMDatabase*)database;

@end

