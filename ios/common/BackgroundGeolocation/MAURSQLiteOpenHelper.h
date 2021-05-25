//
//  MAURSQLiteOpenHelper.h
//  version: 1.0.0
//
//  A helper class to manage database creation and version management.
//  heavily inspired by Android implementation
//  https://android.googlesource.com/platform/frameworks/base/+/refs/heads/master/core/java/android/database/sqlite/SQLiteOpenHelper.java
//
//  Note: Not for direct use, but as subclass instead (abstract class in java terminology)
//
//  Created by Marian Hello on 22/06/16.
//

#ifndef MAURSQLiteOpenHelper_h
#define MAURSQLiteOpenHelper_h

#import <Foundation/Foundation.h>
#import "FMDB.h"

@interface MAURSQLiteOpenHelper : NSObject

- (instancetype)init:(NSString*)name version:(NSInteger)version;
- (NSDictionary*) getDatabaseMetadata;
- (NSString*) getDatabaseName;
- (NSString*) getDatabasePath;
- (FMDatabaseQueue*) getReadableDatabase;
- (FMDatabaseQueue*) getWritableDatabase;
- (void) close;

@end

#endif /* MAURSQLiteOpenHelper_h */
