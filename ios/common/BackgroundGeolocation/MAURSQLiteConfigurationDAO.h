//
//  MAURSQLiteConfigurationDAO.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 01/12/2017.
//  Copyright © 2017 mauron85. All rights reserved.
//

#ifndef MAURSQLiteConfigurationDAO_h
#define MAURSQLiteConfigurationDAO_h

#import "MAURConfig.h"

@interface MAURSQLiteConfigurationDAO : NSObject

+ (instancetype) sharedInstance;
- (id) init NS_UNAVAILABLE;
- (BOOL) persistConfiguration:(MAURConfig*)config;
- (MAURConfig*) retrieveConfiguration;
- (BOOL) clearDatabase;
- (NSString*) getDatabaseName;
- (NSString*) getDatabasePath;

@end

#endif /* MAURSQLiteConfigurationDAO_h */
