//
//  SQLiteConfigurationDAO.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 01/12/2017.
//  Copyright © 2017 mauron85. All rights reserved.
//

#ifndef SQLiteConfigurationDAO_h
#define SQLiteConfigurationDAO_h

@class Config;

@interface SQLiteConfigurationDAO : NSObject

+ (instancetype) sharedInstance;
- (id) init NS_UNAVAILABLE;
- (BOOL) persistConfiguration:(Config*)config;
- (Config*) retrieveConfiguration;
- (BOOL) clearDatabase;
- (NSString*) getDatabaseName;
- (NSString*) getDatabasePath;

@end

#endif /* SQLiteConfigurationDAO_h */
