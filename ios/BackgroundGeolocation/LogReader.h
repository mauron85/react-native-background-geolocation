//
//  LogReader.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 02/07/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#ifndef LogReader_h
#define LogReader_h

#define LOG_LEVEL_DEF ddLogLevel

@interface LogReader : NSObject

+ (NSArray*) getEntries:(NSString*)dbPath limit:(NSInteger)limit;

@end

#endif /* LogReader_h */
