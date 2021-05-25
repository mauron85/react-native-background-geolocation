//
//  MAURLogging.h
//  BackgroundGeolocation
//
//  Created by Marian Hello on 10/11/2017.
//  Copyright © 2017 mauron85. All rights reserved.
//

#ifndef MAURLogging_h
#define MAURLogging_h

#define LOG_LEVEL_DEF ddLogLevel
#import "CocoaLumberjack.h"

// we will override this global level later
// https://github.com/CocoaLumberjack/CocoaLumberjack/issues/469
static const DDLogLevel ddLogLevel = DDLogLevelAll;

#endif /* MAURLogging_h */
