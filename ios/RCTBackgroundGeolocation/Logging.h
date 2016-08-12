//
//  Logging.h
//  CDVBackgroundGeolocation
//
//  Created by Marian Hello on 02/07/16.
//  Copyright © 2016 mauron85. All rights reserved.
//

#ifndef Logging_h
#define Logging_h

#define LOG_LEVEL_DEF ddLogLevel
#import "CocoaLumberjack.h"
#import "FMDBLogger.h"

// we will override this global level later
// https://github.com/CocoaLumberjack/CocoaLumberjack/issues/469
static const DDLogLevel ddLogLevel = DDLogLevelAll;


@interface LogReader : NSObject

+ (NSArray*) getEntries:(NSString*)path limit:(NSInteger)limit;

@end

#endif /* Logging_h */