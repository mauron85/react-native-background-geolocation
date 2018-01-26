// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2016, Deusty, LLC
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Neither the name of Deusty nor the names of its contributors may be used
//   to endorse or promote products derived from this software without specific
//   prior written permission of Deusty, LLC.

#import "CocoaLumberjack.h"

// Disable legacy macros
#ifndef DD_LEGACY_MACROS
    #define DD_LEGACY_MACROS 0
#endif

#include <asl.h>
#include <notify.h>
#include <notify_keys.h>
#include <sys/time.h>

static BOOL _cancel = YES;
static DDLogLevel _captureLevel = DDLogLevelVerbose;

#ifdef __IPHONE_8_0
    #define DDASL_IOS_PIVOT_VERSION __IPHONE_8_0
#endif
#ifdef __MAC_10_10
    #define DDASL_OSX_PIVOT_VERSION __MAC_10_10
#endif

@implementation DDASLLogCapture

static aslmsg (*dd_asl_next)(aslresponse obj);
static void (*dd_asl_release)(aslresponse obj);

+ (void)initialize
{
    #if (defined(DDASL_IOS_PIVOT_VERSION) && __IPHONE_OS_VERSION_MAX_ALLOWED >= DDASL_IOS_PIVOT_VERSION) || (defined(DDASL_OSX_PIVOT_VERSION) && __MAC_OS_X_VERSION_MAX_ALLOWED >= DDASL_OSX_PIVOT_VERSION)
        #if __IPHONE_OS_VERSION_MIN_REQUIRED < DDASL_IOS_PIVOT_VERSION || __MAC_OS_X_VERSION_MIN_REQUIRED < DDASL_OSX_PIVOT_VERSION
            #pragma GCC diagnostic push
            #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
                // Building on falsely advertised SDK, targeting deprecated API
                dd_asl_next    = &aslresponse_next;
                dd_asl_release = &aslresponse_free;
            #pragma GCC diagnostic pop
        #else
            // Building on lastest, correct SDK, targeting latest API
            dd_asl_next    = &asl_next;
            dd_asl_release = &asl_release;
        #endif
    #else
        // Building on old SDKs, targeting deprecated API
        dd_asl_next    = &aslresponse_next;
        dd_asl_release = &aslresponse_free;
    #endif
}

+ (void)start {
    // Ignore subsequent calls
    if (!_cancel) {
        return;
    }
    
    _cancel = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self captureAslLogs];
    });
}

+ (void)stop {
    _cancel = YES;
}

+ (DDLogLevel)captureLevel {
    return _captureLevel;
}

+ (void)setCaptureLevel:(DDLogLevel)level {
    _captureLevel = level;
}

#pragma mark - Private methods

+ (void)configureAslQuery:(aslmsg)query {
    const char param[] = "7";  // ASL_LEVEL_DEBUG, which is everything. We'll rely on regular DDlog log level to filter
    
    asl_set_query(query, ASL_KEY_LEVEL, param, ASL_QUERY_OP_LESS_EQUAL | ASL_QUERY_OP_NUMERIC);

    // Don't retrieve logs from our own DDASLLogger
    asl_set_query(query, kDDASLKeyDDLog, kDDASLDDLogValue, ASL_QUERY_OP_NOT_EQUAL);
    
#if !TARGET_OS_IPHONE || TARGET_SIMULATOR
    int processId = [[NSProcessInfo processInfo] processIdentifier];
    char pid[16];
    sprintf(pid, "%d", processId);
    asl_set_query(query, ASL_KEY_PID, pid, ASL_QUERY_OP_EQUAL | ASL_QUERY_OP_NUMERIC);
#endif
}

+ (void)aslMessageReceived:(aslmsg)msg {
    const char* messageCString = asl_get( msg, ASL_KEY_MSG );
    if ( messageCString == NULL )
        return;

    int flag;
    BOOL async;

    const char* levelCString = asl_get(msg, ASL_KEY_LEVEL);
    switch (levelCString? atoi(levelCString) : 0) {
        // By default all NSLog's with a ASL_LEVEL_WARNING level
        case ASL_LEVEL_EMERG    :
        case ASL_LEVEL_ALERT    :
        case ASL_LEVEL_CRIT     : flag = DDLogFlagError;    async = NO;  break;
        case ASL_LEVEL_ERR      : flag = DDLogFlagWarning;  async = YES; break;
        case ASL_LEVEL_WARNING  : flag = DDLogFlagInfo;     async = YES; break;
        case ASL_LEVEL_NOTICE   : flag = DDLogFlagDebug;    async = YES; break;
        case ASL_LEVEL_INFO     :
        case ASL_LEVEL_DEBUG    :
        default                 : flag = DDLogFlagVerbose;  async = YES;  break;
    }

    if (!(_captureLevel & flag)) {
        return;
    }

    //  NSString * sender = [NSString stringWithCString:asl_get(msg, ASL_KEY_SENDER) encoding:NSUTF8StringEncoding];
    NSString *message = @(messageCString);

    const char* secondsCString = asl_get( msg, ASL_KEY_TIME );
    const char* nanoCString = asl_get( msg, ASL_KEY_TIME_NSEC );
    NSTimeInterval seconds = secondsCString ? strtod(secondsCString, NULL) : [NSDate timeIntervalSinceReferenceDate] - NSTimeIntervalSince1970;
    double nanoSeconds = nanoCString? strtod(nanoCString, NULL) : 0;
    NSTimeInterval totalSeconds = seconds + (nanoSeconds / 1e9);

    NSDate *timeStamp = [NSDate dateWithTimeIntervalSince1970:totalSeconds];

    DDLogMessage *logMessage = [[DDLogMessage alloc]initWithMessage:message
                                                              level:_captureLevel
                                                               flag:flag
                                                            context:0
                                                               file:@"DDASLLogCapture"
                                                           function:0
                                                               line:0
                                                                tag:nil
                                                            options:0
                                                          timestamp:timeStamp];
    
    [DDLog log:async message:logMessage];
}

+ (void)captureAslLogs {
    @autoreleasepool
    {
        /*
           We use ASL_KEY_MSG_ID to see each message once, but there's no
           obvious way to get the "next" ID. To bootstrap the process, we'll
           search by timestamp until we've seen a message.
         */

        struct timeval timeval = {
            .tv_sec = 0
        };
        gettimeofday(&timeval, NULL);
        unsigned long long startTime = timeval.tv_sec;
        __block unsigned long long lastSeenID = 0;

        /*
           syslogd posts kNotifyASLDBUpdate (com.apple.system.logger.message)
           through the notify API when it saves messages to the ASL database.
           There is some coalescing - currently it is sent at most twice per
           second - but there is no documented guarantee about this. In any
           case, there may be multiple messages per notification.

           Notify notifications don't carry any payload, so we need to search
           for the messages.
         */
        int notifyToken = 0;  // Can be used to unregister with notify_cancel().
        notify_register_dispatch(kNotifyASLDBUpdate, &notifyToken, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(int token)
        {
            // At least one message has been posted; build a search query.
            @autoreleasepool
            {
                aslmsg query = asl_new(ASL_TYPE_QUERY);
                char stringValue[64];

                if (lastSeenID > 0) {
                    snprintf(stringValue, sizeof stringValue, "%llu", lastSeenID);
                    asl_set_query(query, ASL_KEY_MSG_ID, stringValue, ASL_QUERY_OP_GREATER | ASL_QUERY_OP_NUMERIC);
                } else {
                    snprintf(stringValue, sizeof stringValue, "%llu", startTime);
                    asl_set_query(query, ASL_KEY_TIME, stringValue, ASL_QUERY_OP_GREATER_EQUAL | ASL_QUERY_OP_NUMERIC);
                }

                [self configureAslQuery:query];

                // Iterate over new messages.
                aslmsg msg;
                aslresponse response = asl_search(NULL, query);
                
                while ((msg = dd_asl_next(response)))
                {
                    [self aslMessageReceived:msg];

                    // Keep track of which messages we've seen.
                    lastSeenID = atoll(asl_get(msg, ASL_KEY_MSG_ID));
                }
                dd_asl_release(response);
                asl_free(query);

                if (_cancel) {
                    notify_cancel(token);
                    return;
                }

            }
        });
    }
}

@end
// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2016, Deusty, LLC
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Neither the name of Deusty nor the names of its contributors may be used
//   to endorse or promote products derived from this software without specific
//   prior written permission of Deusty, LLC.

#import <asl.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

const char* const kDDASLKeyDDLog = "DDLog";

const char* const kDDASLDDLogValue = "1";

static DDASLLogger *sharedInstance;

@interface DDASLLogger () {
    aslclient _client;
}

@end


@implementation DDASLLogger

+ (instancetype)sharedInstance {
    static dispatch_once_t DDASLLoggerOnceToken;

    dispatch_once(&DDASLLoggerOnceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init {
    if (sharedInstance != nil) {
        return nil;
    }

    if ((self = [super init])) {
        // A default asl client is provided for the main thread,
        // but background threads need to create their own client.

        _client = asl_open(NULL, "com.apple.console", 0);
    }

    return self;
}

- (void)logMessage:(DDLogMessage *)logMessage {
    // Skip captured log messages
    if ([logMessage->_fileName isEqualToString:@"DDASLLogCapture"]) {
        return;
    }

    NSString * message = _logFormatter ? [_logFormatter formatLogMessage:logMessage] : logMessage->_message;

    if (logMessage) {
        const char *msg = [message UTF8String];

        size_t aslLogLevel;
        switch (logMessage->_flag) {
            // Note: By default ASL will filter anything above level 5 (Notice).
            // So our mappings shouldn't go above that level.
            case DDLogFlagError     : aslLogLevel = ASL_LEVEL_CRIT;     break;
            case DDLogFlagWarning   : aslLogLevel = ASL_LEVEL_ERR;      break;
            case DDLogFlagInfo      : aslLogLevel = ASL_LEVEL_WARNING;  break; // Regular NSLog's level
            case DDLogFlagDebug     :
            case DDLogFlagVerbose   :
            default                 : aslLogLevel = ASL_LEVEL_NOTICE;   break;
        }

        static char const *const level_strings[] = { "0", "1", "2", "3", "4", "5", "6", "7" };

        // NSLog uses the current euid to set the ASL_KEY_READ_UID.
        uid_t const readUID = geteuid();

        char readUIDString[16];
#ifndef NS_BLOCK_ASSERTIONS
        int l = snprintf(readUIDString, sizeof(readUIDString), "%d", readUID);
#else
        snprintf(readUIDString, sizeof(readUIDString), "%d", readUID);
#endif

        NSAssert(l < sizeof(readUIDString),
                 @"Formatted euid is too long.");
        NSAssert(aslLogLevel < (sizeof(level_strings) / sizeof(level_strings[0])),
                 @"Unhandled ASL log level.");

        aslmsg m = asl_new(ASL_TYPE_MSG);
        if (m != NULL) {
            if (asl_set(m, ASL_KEY_LEVEL, level_strings[aslLogLevel]) == 0 &&
                asl_set(m, ASL_KEY_MSG, msg) == 0 &&
                asl_set(m, ASL_KEY_READ_UID, readUIDString) == 0 &&
                asl_set(m, kDDASLKeyDDLog, kDDASLDDLogValue) == 0) {
                asl_send(_client, m);
            }
            asl_free(m);
        }
        //TODO handle asl_* failures non-silently?
    }
}

- (NSString *)loggerName {
    return @"cocoa.lumberjack.aslLogger";
}

@end
// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2016, Deusty, LLC
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Neither the name of Deusty nor the names of its contributors may be used
//   to endorse or promote products derived from this software without specific
//   prior written permission of Deusty, LLC.

#import <math.h>


#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

@interface DDAbstractDatabaseLogger ()

- (void)destroySaveTimer;
- (void)destroyDeleteTimer;

@end

#pragma mark -

@implementation DDAbstractDatabaseLogger

- (instancetype)init {
    if ((self = [super init])) {
        _saveThreshold = 500;
        _saveInterval = 60;           // 60 seconds
        _maxAge = (60 * 60 * 24 * 7); //  7 days
        _deleteInterval = (60 * 5);   //  5 minutes
    }

    return self;
}

- (void)dealloc {
    [self destroySaveTimer];
    [self destroyDeleteTimer];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Override Me
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)db_log:(DDLogMessage *)logMessage {
    // Override me and add your implementation.
    //
    // Return YES if an item was added to the buffer.
    // Return NO if the logMessage was ignored.

    return NO;
}

- (void)db_save {
    // Override me and add your implementation.
}

- (void)db_delete {
    // Override me and add your implementation.
}

- (void)db_saveAndDelete {
    // Override me and add your implementation.
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private API
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)performSaveAndSuspendSaveTimer {
    if (_unsavedCount > 0) {
        if (_deleteOnEverySave) {
            [self db_saveAndDelete];
        } else {
            [self db_save];
        }
    }

    _unsavedCount = 0;
    _unsavedTime = 0;

    if (_saveTimer && !_saveTimerSuspended) {
        dispatch_suspend(_saveTimer);
        _saveTimerSuspended = YES;
    }
}

- (void)performDelete {
    if (_maxAge > 0.0) {
        [self db_delete];

        _lastDeleteTime = dispatch_time(DISPATCH_TIME_NOW, 0);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Timers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)destroySaveTimer {
    if (_saveTimer) {
        dispatch_source_cancel(_saveTimer);

        if (_saveTimerSuspended) {
            // Must resume a timer before releasing it (or it will crash)
            dispatch_resume(_saveTimer);
            _saveTimerSuspended = NO;
        }

        #if !OS_OBJECT_USE_OBJC
        dispatch_release(_saveTimer);
        #endif
        _saveTimer = NULL;
    }
}

- (void)updateAndResumeSaveTimer {
    if ((_saveTimer != NULL) && (_saveInterval > 0.0) && (_unsavedTime > 0.0)) {
        uint64_t interval = (uint64_t)(_saveInterval * NSEC_PER_SEC);
        dispatch_time_t startTime = dispatch_time(_unsavedTime, interval);

        dispatch_source_set_timer(_saveTimer, startTime, interval, 1.0);

        if (_saveTimerSuspended) {
            dispatch_resume(_saveTimer);
            _saveTimerSuspended = NO;
        }
    }
}

- (void)createSuspendedSaveTimer {
    if ((_saveTimer == NULL) && (_saveInterval > 0.0)) {
        _saveTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.loggerQueue);

        dispatch_source_set_event_handler(_saveTimer, ^{ @autoreleasepool {
                                                            [self performSaveAndSuspendSaveTimer];
                                                        } });

        _saveTimerSuspended = YES;
    }
}

- (void)destroyDeleteTimer {
    if (_deleteTimer) {
        dispatch_source_cancel(_deleteTimer);
        #if !OS_OBJECT_USE_OBJC
        dispatch_release(_deleteTimer);
        #endif
        _deleteTimer = NULL;
    }
}

- (void)updateDeleteTimer {
    if ((_deleteTimer != NULL) && (_deleteInterval > 0.0) && (_maxAge > 0.0)) {
        uint64_t interval = (uint64_t)(_deleteInterval * NSEC_PER_SEC);
        dispatch_time_t startTime;

        if (_lastDeleteTime > 0) {
            startTime = dispatch_time(_lastDeleteTime, interval);
        } else {
            startTime = dispatch_time(DISPATCH_TIME_NOW, interval);
        }

        dispatch_source_set_timer(_deleteTimer, startTime, interval, 1.0);
    }
}

- (void)createAndStartDeleteTimer {
    if ((_deleteTimer == NULL) && (_deleteInterval > 0.0) && (_maxAge > 0.0)) {
        _deleteTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.loggerQueue);

        if (_deleteTimer != NULL) {
            dispatch_source_set_event_handler(_deleteTimer, ^{ @autoreleasepool {
                                                                  [self performDelete];
                                                              } });

            [self updateDeleteTimer];

            if (_deleteTimer != NULL) {
                dispatch_resume(_deleteTimer);
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSUInteger)saveThreshold {
    // The design of this method is taken from the DDAbstractLogger implementation.
    // For extensive documentation please refer to the DDAbstractLogger implementation.

    // Note: The internal implementation MUST access the colorsEnabled variable directly,
    // This method is designed explicitly for external access.
    //
    // Using "self." syntax to go through this method will cause immediate deadlock.
    // This is the intended result. Fix it by accessing the ivar directly.
    // Great strides have been take to ensure this is safe to do. Plus it's MUCH faster.

    NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");
    NSAssert(![self isOnInternalLoggerQueue], @"MUST access ivar directly, NOT via self.* syntax.");

    dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];

    __block NSUInteger result;

    dispatch_sync(globalLoggingQueue, ^{
        dispatch_sync(self.loggerQueue, ^{
            result = _saveThreshold;
        });
    });

    return result;
}

- (void)setSaveThreshold:(NSUInteger)threshold {
    dispatch_block_t block = ^{
        @autoreleasepool {
            if (_saveThreshold != threshold) {
                _saveThreshold = threshold;

                // Since the saveThreshold has changed,
                // we check to see if the current unsavedCount has surpassed the new threshold.
                //
                // If it has, we immediately save the log.

                if ((_unsavedCount >= _saveThreshold) && (_saveThreshold > 0)) {
                    [self performSaveAndSuspendSaveTimer];
                }
            }
        }
    };

    // The design of the setter logic below is taken from the DDAbstractLogger implementation.
    // For documentation please refer to the DDAbstractLogger implementation.

    if ([self isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
        NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");

        dispatch_async(globalLoggingQueue, ^{
            dispatch_async(self.loggerQueue, block);
        });
    }
}

- (NSTimeInterval)saveInterval {
    // The design of this method is taken from the DDAbstractLogger implementation.
    // For extensive documentation please refer to the DDAbstractLogger implementation.

    // Note: The internal implementation MUST access the colorsEnabled variable directly,
    // This method is designed explicitly for external access.
    //
    // Using "self." syntax to go through this method will cause immediate deadlock.
    // This is the intended result. Fix it by accessing the ivar directly.
    // Great strides have been take to ensure this is safe to do. Plus it's MUCH faster.

    NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");
    NSAssert(![self isOnInternalLoggerQueue], @"MUST access ivar directly, NOT via self.* syntax.");

    dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];

    __block NSTimeInterval result;

    dispatch_sync(globalLoggingQueue, ^{
        dispatch_sync(self.loggerQueue, ^{
            result = _saveInterval;
        });
    });

    return result;
}

- (void)setSaveInterval:(NSTimeInterval)interval {
    dispatch_block_t block = ^{
        @autoreleasepool {
            // C99 recommended floating point comparison macro
            // Read: isLessThanOrGreaterThan(floatA, floatB)

            if (/* saveInterval != interval */ islessgreater(_saveInterval, interval)) {
                _saveInterval = interval;

                // There are several cases we need to handle here.
                //
                // 1. If the saveInterval was previously enabled and it just got disabled,
                //    then we need to stop the saveTimer. (And we might as well release it.)
                //
                // 2. If the saveInterval was previously disabled and it just got enabled,
                //    then we need to setup the saveTimer. (Plus we might need to do an immediate save.)
                //
                // 3. If the saveInterval increased, then we need to reset the timer so that it fires at the later date.
                //
                // 4. If the saveInterval decreased, then we need to reset the timer so that it fires at an earlier date.
                //    (Plus we might need to do an immediate save.)

                if (_saveInterval > 0.0) {
                    if (_saveTimer == NULL) {
                        // Handles #2
                        //
                        // Since the saveTimer uses the unsavedTime to calculate it's first fireDate,
                        // if a save is needed the timer will fire immediately.

                        [self createSuspendedSaveTimer];
                        [self updateAndResumeSaveTimer];
                    } else {
                        // Handles #3
                        // Handles #4
                        //
                        // Since the saveTimer uses the unsavedTime to calculate it's first fireDate,
                        // if a save is needed the timer will fire immediately.

                        [self updateAndResumeSaveTimer];
                    }
                } else if (_saveTimer) {
                    // Handles #1

                    [self destroySaveTimer];
                }
            }
        }
    };

    // The design of the setter logic below is taken from the DDAbstractLogger implementation.
    // For documentation please refer to the DDAbstractLogger implementation.

    if ([self isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
        NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");

        dispatch_async(globalLoggingQueue, ^{
            dispatch_async(self.loggerQueue, block);
        });
    }
}

- (NSTimeInterval)maxAge {
    // The design of this method is taken from the DDAbstractLogger implementation.
    // For extensive documentation please refer to the DDAbstractLogger implementation.

    // Note: The internal implementation MUST access the colorsEnabled variable directly,
    // This method is designed explicitly for external access.
    //
    // Using "self." syntax to go through this method will cause immediate deadlock.
    // This is the intended result. Fix it by accessing the ivar directly.
    // Great strides have been take to ensure this is safe to do. Plus it's MUCH faster.

    NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");
    NSAssert(![self isOnInternalLoggerQueue], @"MUST access ivar directly, NOT via self.* syntax.");

    dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];

    __block NSTimeInterval result;

    dispatch_sync(globalLoggingQueue, ^{
        dispatch_sync(self.loggerQueue, ^{
            result = _maxAge;
        });
    });

    return result;
}

- (void)setMaxAge:(NSTimeInterval)interval {
    dispatch_block_t block = ^{
        @autoreleasepool {
            // C99 recommended floating point comparison macro
            // Read: isLessThanOrGreaterThan(floatA, floatB)

            if (/* maxAge != interval */ islessgreater(_maxAge, interval)) {
                NSTimeInterval oldMaxAge = _maxAge;
                NSTimeInterval newMaxAge = interval;

                _maxAge = interval;

                // There are several cases we need to handle here.
                //
                // 1. If the maxAge was previously enabled and it just got disabled,
                //    then we need to stop the deleteTimer. (And we might as well release it.)
                //
                // 2. If the maxAge was previously disabled and it just got enabled,
                //    then we need to setup the deleteTimer. (Plus we might need to do an immediate delete.)
                //
                // 3. If the maxAge was increased,
                //    then we don't need to do anything.
                //
                // 4. If the maxAge was decreased,
                //    then we should do an immediate delete.

                BOOL shouldDeleteNow = NO;

                if (oldMaxAge > 0.0) {
                    if (newMaxAge <= 0.0) {
                        // Handles #1

                        [self destroyDeleteTimer];
                    } else if (oldMaxAge > newMaxAge) {
                        // Handles #4
                        shouldDeleteNow = YES;
                    }
                } else if (newMaxAge > 0.0) {
                    // Handles #2
                    shouldDeleteNow = YES;
                }

                if (shouldDeleteNow) {
                    [self performDelete];

                    if (_deleteTimer) {
                        [self updateDeleteTimer];
                    } else {
                        [self createAndStartDeleteTimer];
                    }
                }
            }
        }
    };

    // The design of the setter logic below is taken from the DDAbstractLogger implementation.
    // For documentation please refer to the DDAbstractLogger implementation.

    if ([self isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
        NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");

        dispatch_async(globalLoggingQueue, ^{
            dispatch_async(self.loggerQueue, block);
        });
    }
}

- (NSTimeInterval)deleteInterval {
    // The design of this method is taken from the DDAbstractLogger implementation.
    // For extensive documentation please refer to the DDAbstractLogger implementation.

    // Note: The internal implementation MUST access the colorsEnabled variable directly,
    // This method is designed explicitly for external access.
    //
    // Using "self." syntax to go through this method will cause immediate deadlock.
    // This is the intended result. Fix it by accessing the ivar directly.
    // Great strides have been take to ensure this is safe to do. Plus it's MUCH faster.

    NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");
    NSAssert(![self isOnInternalLoggerQueue], @"MUST access ivar directly, NOT via self.* syntax.");

    dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];

    __block NSTimeInterval result;

    dispatch_sync(globalLoggingQueue, ^{
        dispatch_sync(self.loggerQueue, ^{
            result = _deleteInterval;
        });
    });

    return result;
}

- (void)setDeleteInterval:(NSTimeInterval)interval {
    dispatch_block_t block = ^{
        @autoreleasepool {
            // C99 recommended floating point comparison macro
            // Read: isLessThanOrGreaterThan(floatA, floatB)

            if (/* deleteInterval != interval */ islessgreater(_deleteInterval, interval)) {
                _deleteInterval = interval;

                // There are several cases we need to handle here.
                //
                // 1. If the deleteInterval was previously enabled and it just got disabled,
                //    then we need to stop the deleteTimer. (And we might as well release it.)
                //
                // 2. If the deleteInterval was previously disabled and it just got enabled,
                //    then we need to setup the deleteTimer. (Plus we might need to do an immediate delete.)
                //
                // 3. If the deleteInterval increased, then we need to reset the timer so that it fires at the later date.
                //
                // 4. If the deleteInterval decreased, then we need to reset the timer so that it fires at an earlier date.
                //    (Plus we might need to do an immediate delete.)

                if (_deleteInterval > 0.0) {
                    if (_deleteTimer == NULL) {
                        // Handles #2
                        //
                        // Since the deleteTimer uses the lastDeleteTime to calculate it's first fireDate,
                        // if a delete is needed the timer will fire immediately.

                        [self createAndStartDeleteTimer];
                    } else {
                        // Handles #3
                        // Handles #4
                        //
                        // Since the deleteTimer uses the lastDeleteTime to calculate it's first fireDate,
                        // if a save is needed the timer will fire immediately.

                        [self updateDeleteTimer];
                    }
                } else if (_deleteTimer) {
                    // Handles #1

                    [self destroyDeleteTimer];
                }
            }
        }
    };

    // The design of the setter logic below is taken from the DDAbstractLogger implementation.
    // For documentation please refer to the DDAbstractLogger implementation.

    if ([self isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
        NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");

        dispatch_async(globalLoggingQueue, ^{
            dispatch_async(self.loggerQueue, block);
        });
    }
}

- (BOOL)deleteOnEverySave {
    // The design of this method is taken from the DDAbstractLogger implementation.
    // For extensive documentation please refer to the DDAbstractLogger implementation.

    // Note: The internal implementation MUST access the colorsEnabled variable directly,
    // This method is designed explicitly for external access.
    //
    // Using "self." syntax to go through this method will cause immediate deadlock.
    // This is the intended result. Fix it by accessing the ivar directly.
    // Great strides have been take to ensure this is safe to do. Plus it's MUCH faster.

    NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");
    NSAssert(![self isOnInternalLoggerQueue], @"MUST access ivar directly, NOT via self.* syntax.");

    dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];

    __block BOOL result;

    dispatch_sync(globalLoggingQueue, ^{
        dispatch_sync(self.loggerQueue, ^{
            result = _deleteOnEverySave;
        });
    });

    return result;
}

- (void)setDeleteOnEverySave:(BOOL)flag {
    dispatch_block_t block = ^{
        _deleteOnEverySave = flag;
    };

    // The design of the setter logic below is taken from the DDAbstractLogger implementation.
    // For documentation please refer to the DDAbstractLogger implementation.

    if ([self isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
        NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");

        dispatch_async(globalLoggingQueue, ^{
            dispatch_async(self.loggerQueue, block);
        });
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Public API
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)savePendingLogEntries {
    dispatch_block_t block = ^{
        @autoreleasepool {
            [self performSaveAndSuspendSaveTimer];
        }
    };

    if ([self isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_async(self.loggerQueue, block);
    }
}

- (void)deleteOldLogEntries {
    dispatch_block_t block = ^{
        @autoreleasepool {
            [self performDelete];
        }
    };

    if ([self isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_async(self.loggerQueue, block);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark DDLogger
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)didAddLogger {
    // If you override me be sure to invoke [super didAddLogger];

    [self createSuspendedSaveTimer];

    [self createAndStartDeleteTimer];
}

- (void)willRemoveLogger {
    // If you override me be sure to invoke [super willRemoveLogger];

    [self performSaveAndSuspendSaveTimer];

    [self destroySaveTimer];
    [self destroyDeleteTimer];
}

- (void)logMessage:(DDLogMessage *)logMessage {
    if ([self db_log:logMessage]) {
        BOOL firstUnsavedEntry = (++_unsavedCount == 1);

        if ((_unsavedCount >= _saveThreshold) && (_saveThreshold > 0)) {
            [self performSaveAndSuspendSaveTimer];
        } else if (firstUnsavedEntry) {
            _unsavedTime = dispatch_time(DISPATCH_TIME_NOW, 0);
            [self updateAndResumeSaveTimer];
        }
    }
}

- (void)flush {
    // This method is invoked by DDLog's flushLog method.
    //
    // It is called automatically when the application quits,
    // or if the developer invokes DDLog's flushLog method prior to crashing or something.

    [self performSaveAndSuspendSaveTimer];
}

@end
// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2016, Deusty, LLC
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Neither the name of Deusty nor the names of its contributors may be used
//   to endorse or promote products derived from this software without specific
//   prior written permission of Deusty, LLC.

#import <unistd.h>
#import <sys/attr.h>
#import <sys/xattr.h>
#import <libkern/OSAtomic.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

// We probably shouldn't be using DDLog() statements within the DDLog implementation.
// But we still want to leave our log statements for any future debugging,
// and to allow other developers to trace the implementation (which is a great learning tool).
//
// So we use primitive logging macros around NSLog.
// We maintain the NS prefix on the macros to be explicit about the fact that we're using NSLog.

#ifndef DD_NSLOG_LEVEL
    #define DD_NSLOG_LEVEL 2
#endif

#define NSLogError(frmt, ...)    do{ if(DD_NSLOG_LEVEL >= 1) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogWarn(frmt, ...)     do{ if(DD_NSLOG_LEVEL >= 2) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogInfo(frmt, ...)     do{ if(DD_NSLOG_LEVEL >= 3) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogDebug(frmt, ...)    do{ if(DD_NSLOG_LEVEL >= 4) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogVerbose(frmt, ...)  do{ if(DD_NSLOG_LEVEL >= 5) NSLog((frmt), ##__VA_ARGS__); } while(0)


#if TARGET_OS_IPHONE
BOOL doesAppRunInBackground(void);
#endif

unsigned long long const kDDDefaultLogMaxFileSize      = 1024 * 1024;      // 1 MB
NSTimeInterval     const kDDDefaultLogRollingFrequency = 60 * 60 * 24;     // 24 Hours
NSUInteger         const kDDDefaultLogMaxNumLogFiles   = 5;                // 5 Files
unsigned long long const kDDDefaultLogFilesDiskQuota   = 20 * 1024 * 1024; // 20 MB

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface DDLogFileManagerDefault () {
    NSUInteger _maximumNumberOfLogFiles;
    unsigned long long _logFilesDiskQuota;
    NSString *_logsDirectory;
#if TARGET_OS_IPHONE
    NSString *_defaultFileProtectionLevel;
#endif
}

- (void)deleteOldLogFiles;
- (NSString *)defaultLogsDirectory;

@end

@implementation DDLogFileManagerDefault

@synthesize maximumNumberOfLogFiles = _maximumNumberOfLogFiles;
@synthesize logFilesDiskQuota = _logFilesDiskQuota;


- (instancetype)init {
    return [self initWithLogsDirectory:nil];
}

- (instancetype)initWithLogsDirectory:(NSString *)aLogsDirectory {
    if ((self = [super init])) {
        _maximumNumberOfLogFiles = kDDDefaultLogMaxNumLogFiles;
        _logFilesDiskQuota = kDDDefaultLogFilesDiskQuota;

        if (aLogsDirectory) {
            _logsDirectory = [aLogsDirectory copy];
        } else {
            _logsDirectory = [[self defaultLogsDirectory] copy];
        }

        NSKeyValueObservingOptions kvoOptions = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;

        [self addObserver:self forKeyPath:NSStringFromSelector(@selector(maximumNumberOfLogFiles)) options:kvoOptions context:nil];
        [self addObserver:self forKeyPath:NSStringFromSelector(@selector(logFilesDiskQuota)) options:kvoOptions context:nil];

        NSLogVerbose(@"DDFileLogManagerDefault: logsDirectory:\n%@", [self logsDirectory]);
        NSLogVerbose(@"DDFileLogManagerDefault: sortedLogFileNames:\n%@", [self sortedLogFileNames]);
    }

    return self;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey
{
    BOOL automatic = NO;
    if ([theKey isEqualToString:@"maximumNumberOfLogFiles"] || [theKey isEqualToString:@"logFilesDiskQuota"]) {
        automatic = NO;
    } else {
        automatic = [super automaticallyNotifiesObserversForKey:theKey];
    }
    
    return automatic;
}

#if TARGET_OS_IPHONE
- (instancetype)initWithLogsDirectory:(NSString *)logsDirectory defaultFileProtectionLevel:(NSString *)fileProtectionLevel {
    if ((self = [self initWithLogsDirectory:logsDirectory])) {
        if ([fileProtectionLevel isEqualToString:NSFileProtectionNone] ||
            [fileProtectionLevel isEqualToString:NSFileProtectionComplete] ||
            [fileProtectionLevel isEqualToString:NSFileProtectionCompleteUnlessOpen] ||
            [fileProtectionLevel isEqualToString:NSFileProtectionCompleteUntilFirstUserAuthentication]) {
            _defaultFileProtectionLevel = fileProtectionLevel;
        }
    }

    return self;
}

#endif

- (void)dealloc {
    // try-catch because the observer might be removed or never added. In this case, removeObserver throws and exception
    @try {
        [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(maximumNumberOfLogFiles))];
        [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(logFilesDiskQuota))];
    } @catch (NSException *exception) {
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    NSNumber *old = change[NSKeyValueChangeOldKey];
    NSNumber *new = change[NSKeyValueChangeNewKey];

    if ([old isEqual:new]) {
        // No change in value - don't bother with any processing.
        return;
    }

    if ([keyPath isEqualToString:NSStringFromSelector(@selector(maximumNumberOfLogFiles))] ||
        [keyPath isEqualToString:NSStringFromSelector(@selector(logFilesDiskQuota))]) {
        NSLogInfo(@"DDFileLogManagerDefault: Responding to configuration change: %@", keyPath);

        dispatch_async([DDLog loggingQueue], ^{ @autoreleasepool {
                                                    [self deleteOldLogFiles];
                                                } });
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark File Deleting
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Deletes archived log files that exceed the maximumNumberOfLogFiles or logFilesDiskQuota configuration values.
 **/
- (void)deleteOldLogFiles {
    NSLogVerbose(@"DDLogFileManagerDefault: deleteOldLogFiles");

    NSArray *sortedLogFileInfos = [self sortedLogFileInfos];

    NSUInteger firstIndexToDelete = NSNotFound;

    const unsigned long long diskQuota = self.logFilesDiskQuota;
    const NSUInteger maxNumLogFiles = self.maximumNumberOfLogFiles;

    if (diskQuota) {
        unsigned long long used = 0;

        for (NSUInteger i = 0; i < sortedLogFileInfos.count; i++) {
            DDLogFileInfo *info = sortedLogFileInfos[i];
            used += info.fileSize;

            if (used > diskQuota) {
                firstIndexToDelete = i;
                break;
            }
        }
    }

    if (maxNumLogFiles) {
        if (firstIndexToDelete == NSNotFound) {
            firstIndexToDelete = maxNumLogFiles;
        } else {
            firstIndexToDelete = MIN(firstIndexToDelete, maxNumLogFiles);
        }
    }

    if (firstIndexToDelete == 0) {
        // Do we consider the first file?
        // We are only supposed to be deleting archived files.
        // In most cases, the first file is likely the log file that is currently being written to.
        // So in most cases, we do not want to consider this file for deletion.

        if (sortedLogFileInfos.count > 0) {
            DDLogFileInfo *logFileInfo = sortedLogFileInfos[0];

            if (!logFileInfo.isArchived) {
                // Don't delete active file.
                ++firstIndexToDelete;
            }
        }
    }

    if (firstIndexToDelete != NSNotFound) {
        // removing all logfiles starting with firstIndexToDelete

        for (NSUInteger i = firstIndexToDelete; i < sortedLogFileInfos.count; i++) {
            DDLogFileInfo *logFileInfo = sortedLogFileInfos[i];

            NSLogInfo(@"DDLogFileManagerDefault: Deleting file: %@", logFileInfo.fileName);

            [[NSFileManager defaultManager] removeItemAtPath:logFileInfo.filePath error:nil];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Log Files
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the path to the default logs directory.
 * If the logs directory doesn't exist, this method automatically creates it.
 **/
- (NSString *)defaultLogsDirectory {
#if TARGET_OS_IPHONE
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *baseDir = paths.firstObject;
    NSString *logsDirectory = [baseDir stringByAppendingPathComponent:@"Logs"];

#else
    NSString *appName = [[NSProcessInfo processInfo] processName];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? paths[0] : NSTemporaryDirectory();
    NSString *logsDirectory = [[basePath stringByAppendingPathComponent:@"Logs"] stringByAppendingPathComponent:appName];

#endif

    return logsDirectory;
}

- (NSString *)logsDirectory {
    // We could do this check once, during initalization, and not bother again.
    // But this way the code continues to work if the directory gets deleted while the code is running.

    if (![[NSFileManager defaultManager] fileExistsAtPath:_logsDirectory]) {
        NSError *err = nil;

        if (![[NSFileManager defaultManager] createDirectoryAtPath:_logsDirectory
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&err]) {
            NSLogError(@"DDFileLogManagerDefault: Error creating logsDirectory: %@", err);
        }
    }

    return _logsDirectory;
}

- (BOOL)isLogFile:(NSString *)fileName {
    NSString *appName = [self applicationName];

    BOOL hasProperPrefix = [fileName hasPrefix:appName];
    BOOL hasProperSuffix = [fileName hasSuffix:@".log"];
    BOOL hasProperDate = NO;

    if (hasProperPrefix && hasProperSuffix) {
        NSUInteger lengthOfMiddle = fileName.length - appName.length - @".log".length;

        // Date string should have at least 16 characters - " 2013-12-03 17-14"
        if (lengthOfMiddle >= 17) {
            NSRange range = NSMakeRange(appName.length, lengthOfMiddle);

            NSString *middle = [fileName substringWithRange:range];
            NSArray *components = [middle componentsSeparatedByString:@" "];

            // When creating logfile if there is existing file with the same name, we append attemp number at the end.
            // Thats why here we can have three or four components. For details see createNewLogFile method.
            //
            // Components:
            //     "", "2013-12-03", "17-14"
            // or
            //     "", "2013-12-03", "17-14", "1"
            if (components.count == 3 || components.count == 4) {
                NSString *dateString = [NSString stringWithFormat:@"%@ %@", components[1], components[2]];
                NSDateFormatter *dateFormatter = [self logFileDateFormatter];

                NSDate *date = [dateFormatter dateFromString:dateString];

                if (date) {
                    hasProperDate = YES;
                }
            }
        }
    }

    return (hasProperPrefix && hasProperDate && hasProperSuffix);
}

- (NSDateFormatter *)logFileDateFormatter {
    NSMutableDictionary *dictionary = [[NSThread currentThread]
                                       threadDictionary];
    NSString *dateFormat = @"yyyy'-'MM'-'dd' 'HH'-'mm'";
    NSString *key = [NSString stringWithFormat:@"logFileDateFormatter.%@", dateFormat];
    NSDateFormatter *dateFormatter = dictionary[key];

    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [dateFormatter setDateFormat:dateFormat];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        dictionary[key] = dateFormatter;
    }

    return dateFormatter;
}

- (NSArray *)unsortedLogFilePaths {
    NSString *logsDirectory = [self logsDirectory];
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logsDirectory error:nil];

    NSMutableArray *unsortedLogFilePaths = [NSMutableArray arrayWithCapacity:[fileNames count]];

    for (NSString *fileName in fileNames) {
        // Filter out any files that aren't log files. (Just for extra safety)

    #if TARGET_IPHONE_SIMULATOR
        // In case of iPhone simulator there can be 'archived' extension. isLogFile:
        // method knows nothing about it. Thus removing it for this method.
        //
        // See full explanation in the header file.
        NSString *theFileName = [fileName stringByReplacingOccurrencesOfString:@".archived"
                                                                    withString:@""];

        if ([self isLogFile:theFileName])
    #else

        if ([self isLogFile:fileName])
    #endif
        {
            NSString *filePath = [logsDirectory stringByAppendingPathComponent:fileName];

            [unsortedLogFilePaths addObject:filePath];
        }
    }

    return unsortedLogFilePaths;
}

- (NSArray *)unsortedLogFileNames {
    NSArray *unsortedLogFilePaths = [self unsortedLogFilePaths];

    NSMutableArray *unsortedLogFileNames = [NSMutableArray arrayWithCapacity:[unsortedLogFilePaths count]];

    for (NSString *filePath in unsortedLogFilePaths) {
        [unsortedLogFileNames addObject:[filePath lastPathComponent]];
    }

    return unsortedLogFileNames;
}

- (NSArray *)unsortedLogFileInfos {
    NSArray *unsortedLogFilePaths = [self unsortedLogFilePaths];

    NSMutableArray *unsortedLogFileInfos = [NSMutableArray arrayWithCapacity:[unsortedLogFilePaths count]];

    for (NSString *filePath in unsortedLogFilePaths) {
        DDLogFileInfo *logFileInfo = [[DDLogFileInfo alloc] initWithFilePath:filePath];

        [unsortedLogFileInfos addObject:logFileInfo];
    }

    return unsortedLogFileInfos;
}

- (NSArray *)sortedLogFilePaths {
    NSArray *sortedLogFileInfos = [self sortedLogFileInfos];

    NSMutableArray *sortedLogFilePaths = [NSMutableArray arrayWithCapacity:[sortedLogFileInfos count]];

    for (DDLogFileInfo *logFileInfo in sortedLogFileInfos) {
        [sortedLogFilePaths addObject:[logFileInfo filePath]];
    }

    return sortedLogFilePaths;
}

- (NSArray *)sortedLogFileNames {
    NSArray *sortedLogFileInfos = [self sortedLogFileInfos];

    NSMutableArray *sortedLogFileNames = [NSMutableArray arrayWithCapacity:[sortedLogFileInfos count]];

    for (DDLogFileInfo *logFileInfo in sortedLogFileInfos) {
        [sortedLogFileNames addObject:[logFileInfo fileName]];
    }

    return sortedLogFileNames;
}

- (NSArray *)sortedLogFileInfos {
    return [[self unsortedLogFileInfos] sortedArrayUsingSelector:@selector(reverseCompareByCreationDate:)];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Creation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *)newLogFileName {
    NSString *appName = [self applicationName];

    NSDateFormatter *dateFormatter = [self logFileDateFormatter];
    NSString *formattedDate = [dateFormatter stringFromDate:[NSDate date]];

    return [NSString stringWithFormat:@"%@ %@.log", appName, formattedDate];
}

- (NSString *)createNewLogFile {
    NSString *fileName = [self newLogFileName];
    NSString *logsDirectory = [self logsDirectory];

    NSUInteger attempt = 1;

    do {
        NSString *actualFileName = fileName;

        if (attempt > 1) {
            NSString *extension = [actualFileName pathExtension];

            actualFileName = [actualFileName stringByDeletingPathExtension];
            actualFileName = [actualFileName stringByAppendingFormat:@" %lu", (unsigned long)attempt];

            if (extension.length) {
                actualFileName = [actualFileName stringByAppendingPathExtension:extension];
            }
        }

        NSString *filePath = [logsDirectory stringByAppendingPathComponent:actualFileName];

        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSLogVerbose(@"DDLogFileManagerDefault: Creating new log file: %@", actualFileName);

            NSDictionary *attributes = nil;

        #if TARGET_OS_IPHONE
            // When creating log file on iOS we're setting NSFileProtectionKey attribute to NSFileProtectionCompleteUnlessOpen.
            //
            // But in case if app is able to launch from background we need to have an ability to open log file any time we
            // want (even if device is locked). Thats why that attribute have to be changed to
            // NSFileProtectionCompleteUntilFirstUserAuthentication.

            NSString *key = _defaultFileProtectionLevel ? :
                (doesAppRunInBackground() ? NSFileProtectionCompleteUntilFirstUserAuthentication : NSFileProtectionCompleteUnlessOpen);

            attributes = @{
                NSFileProtectionKey: key
            };
        #endif

            [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:attributes];

            // Since we just created a new log file, we may need to delete some old log files
            [self deleteOldLogFiles];

            return filePath;
        } else {
            attempt++;
        }
    } while (YES);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Utility
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSString *)applicationName {
    static NSString *_appName;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];

        if (!_appName) {
            _appName = [[NSProcessInfo processInfo] processName];
        }

        if (!_appName) {
            _appName = @"";
        }
    });

    return _appName;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface DDLogFileFormatterDefault () {
    NSDateFormatter *_dateFormatter;
}

@end

@implementation DDLogFileFormatterDefault

- (instancetype)init {
    return [self initWithDateFormatter:nil];
}

- (instancetype)initWithDateFormatter:(NSDateFormatter *)aDateFormatter {
    if ((self = [super init])) {
        if (aDateFormatter) {
            _dateFormatter = aDateFormatter;
        } else {
            _dateFormatter = [[NSDateFormatter alloc] init];
            [_dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4]; // 10.4+ style
            [_dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
        }
    }

    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *dateAndTime = [_dateFormatter stringFromDate:(logMessage->_timestamp)];

    return [NSString stringWithFormat:@"%@  %@", dateAndTime, logMessage->_message];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface DDFileLogger () {
    __strong id <DDLogFileManager> _logFileManager;
    
    DDLogFileInfo *_currentLogFileInfo;
    NSFileHandle *_currentLogFileHandle;
    
    dispatch_source_t _currentLogFileVnode;
    dispatch_source_t _rollingTimer;
    
    unsigned long long _maximumFileSize;
    NSTimeInterval _rollingFrequency;
}

- (void)rollLogFileNow;
- (void)maybeRollLogFileDueToAge;
- (void)maybeRollLogFileDueToSize;

@end

@implementation DDFileLogger

- (instancetype)init {
    DDLogFileManagerDefault *defaultLogFileManager = [[DDLogFileManagerDefault alloc] init];

    return [self initWithLogFileManager:defaultLogFileManager];
}

- (instancetype)initWithLogFileManager:(id <DDLogFileManager>)aLogFileManager {
    if ((self = [super init])) {
        _maximumFileSize = kDDDefaultLogMaxFileSize;
        _rollingFrequency = kDDDefaultLogRollingFrequency;
        _automaticallyAppendNewlineForCustomFormatters = YES;

        logFileManager = aLogFileManager;

        self.logFormatter = [DDLogFileFormatterDefault new];
    }

    return self;
}

- (void)dealloc {
    [_currentLogFileHandle synchronizeFile];
    [_currentLogFileHandle closeFile];

    if (_currentLogFileVnode) {
        dispatch_source_cancel(_currentLogFileVnode);
        _currentLogFileVnode = NULL;
    }

    if (_rollingTimer) {
        dispatch_source_cancel(_rollingTimer);
        _rollingTimer = NULL;
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Properties
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@synthesize logFileManager;

- (unsigned long long)maximumFileSize {
    __block unsigned long long result;

    dispatch_block_t block = ^{
        result = _maximumFileSize;
    };

    // The design of this method is taken from the DDAbstractLogger implementation.
    // For extensive documentation please refer to the DDAbstractLogger implementation.

    // Note: The internal implementation MUST access the maximumFileSize variable directly,
    // This method is designed explicitly for external access.
    //
    // Using "self." syntax to go through this method will cause immediate deadlock.
    // This is the intended result. Fix it by accessing the ivar directly.
    // Great strides have been take to ensure this is safe to do. Plus it's MUCH faster.

    NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");
    NSAssert(![self isOnInternalLoggerQueue], @"MUST access ivar directly, NOT via self.* syntax.");

    dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];

    dispatch_sync(globalLoggingQueue, ^{
        dispatch_sync(self.loggerQueue, block);
    });

    return result;
}

- (void)setMaximumFileSize:(unsigned long long)newMaximumFileSize {
    dispatch_block_t block = ^{
        @autoreleasepool {
            _maximumFileSize = newMaximumFileSize;
            [self maybeRollLogFileDueToSize];
        }
    };

    // The design of this method is taken from the DDAbstractLogger implementation.
    // For extensive documentation please refer to the DDAbstractLogger implementation.

    // Note: The internal implementation MUST access the maximumFileSize variable directly,
    // This method is designed explicitly for external access.
    //
    // Using "self." syntax to go through this method will cause immediate deadlock.
    // This is the intended result. Fix it by accessing the ivar directly.
    // Great strides have been take to ensure this is safe to do. Plus it's MUCH faster.

    NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");
    NSAssert(![self isOnInternalLoggerQueue], @"MUST access ivar directly, NOT via self.* syntax.");

    dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];

    dispatch_async(globalLoggingQueue, ^{
        dispatch_async(self.loggerQueue, block);
    });
}

- (NSTimeInterval)rollingFrequency {
    __block NSTimeInterval result;

    dispatch_block_t block = ^{
        result = _rollingFrequency;
    };

    // The design of this method is taken from the DDAbstractLogger implementation.
    // For extensive documentation please refer to the DDAbstractLogger implementation.

    // Note: The internal implementation should access the rollingFrequency variable directly,
    // This method is designed explicitly for external access.
    //
    // Using "self." syntax to go through this method will cause immediate deadlock.
    // This is the intended result. Fix it by accessing the ivar directly.
    // Great strides have been take to ensure this is safe to do. Plus it's MUCH faster.

    NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");
    NSAssert(![self isOnInternalLoggerQueue], @"MUST access ivar directly, NOT via self.* syntax.");

    dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];

    dispatch_sync(globalLoggingQueue, ^{
        dispatch_sync(self.loggerQueue, block);
    });

    return result;
}

- (void)setRollingFrequency:(NSTimeInterval)newRollingFrequency {
    dispatch_block_t block = ^{
        @autoreleasepool {
            _rollingFrequency = newRollingFrequency;
            [self maybeRollLogFileDueToAge];
        }
    };

    // The design of this method is taken from the DDAbstractLogger implementation.
    // For extensive documentation please refer to the DDAbstractLogger implementation.

    // Note: The internal implementation should access the rollingFrequency variable directly,
    // This method is designed explicitly for external access.
    //
    // Using "self." syntax to go through this method will cause immediate deadlock.
    // This is the intended result. Fix it by accessing the ivar directly.
    // Great strides have been take to ensure this is safe to do. Plus it's MUCH faster.

    NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");
    NSAssert(![self isOnInternalLoggerQueue], @"MUST access ivar directly, NOT via self.* syntax.");

    dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];

    dispatch_async(globalLoggingQueue, ^{
        dispatch_async(self.loggerQueue, block);
    });
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark File Rolling
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)scheduleTimerToRollLogFileDueToAge {
    if (_rollingTimer) {
        dispatch_source_cancel(_rollingTimer);
        _rollingTimer = NULL;
    }

    if (_currentLogFileInfo == nil || _rollingFrequency <= 0.0) {
        return;
    }

    NSDate *logFileCreationDate = [_currentLogFileInfo creationDate];

    NSTimeInterval ti = [logFileCreationDate timeIntervalSinceReferenceDate];
    ti += _rollingFrequency;

    NSDate *logFileRollingDate = [NSDate dateWithTimeIntervalSinceReferenceDate:ti];

    NSLogVerbose(@"DDFileLogger: scheduleTimerToRollLogFileDueToAge");

    NSLogVerbose(@"DDFileLogger: logFileCreationDate: %@", logFileCreationDate);
    NSLogVerbose(@"DDFileLogger: logFileRollingDate : %@", logFileRollingDate);

    _rollingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.loggerQueue);

    dispatch_source_set_event_handler(_rollingTimer, ^{ @autoreleasepool {
                                                           [self maybeRollLogFileDueToAge];
                                                       } });

    #if !OS_OBJECT_USE_OBJC
    dispatch_source_t theRollingTimer = _rollingTimer;
    dispatch_source_set_cancel_handler(_rollingTimer, ^{
        dispatch_release(theRollingTimer);
    });
    #endif

    uint64_t delay = (uint64_t)([logFileRollingDate timeIntervalSinceNow] * NSEC_PER_SEC);
    dispatch_time_t fireTime = dispatch_time(DISPATCH_TIME_NOW, delay);

    dispatch_source_set_timer(_rollingTimer, fireTime, DISPATCH_TIME_FOREVER, 1.0);
    dispatch_resume(_rollingTimer);
}

- (void)rollLogFile {
    [self rollLogFileWithCompletionBlock:nil];
}

- (void)rollLogFileWithCompletionBlock:(void (^)())completionBlock {
    // This method is public.
    // We need to execute the rolling on our logging thread/queue.

    dispatch_block_t block = ^{
        @autoreleasepool {
            [self rollLogFileNow];

            if (completionBlock) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    completionBlock();
                });
            }
        }
    };

    // The design of this method is taken from the DDAbstractLogger implementation.
    // For extensive documentation please refer to the DDAbstractLogger implementation.

    if ([self isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
        NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");

        dispatch_async(globalLoggingQueue, ^{
            dispatch_async(self.loggerQueue, block);
        });
    }
}

- (void)rollLogFileNow {
    NSLogVerbose(@"DDFileLogger: rollLogFileNow");

    if (_currentLogFileHandle == nil) {
        return;
    }

    [_currentLogFileHandle synchronizeFile];
    [_currentLogFileHandle closeFile];
    _currentLogFileHandle = nil;

    _currentLogFileInfo.isArchived = YES;

    if ([logFileManager respondsToSelector:@selector(didRollAndArchiveLogFile:)]) {
        [logFileManager didRollAndArchiveLogFile:(_currentLogFileInfo.filePath)];
    }

    _currentLogFileInfo = nil;

    if (_currentLogFileVnode) {
        dispatch_source_cancel(_currentLogFileVnode);
        _currentLogFileVnode = NULL;
    }

    if (_rollingTimer) {
        dispatch_source_cancel(_rollingTimer);
        _rollingTimer = NULL;
    }
}

- (void)maybeRollLogFileDueToAge {
    if (_rollingFrequency > 0.0 && _currentLogFileInfo.age >= _rollingFrequency) {
        NSLogVerbose(@"DDFileLogger: Rolling log file due to age...");

        [self rollLogFileNow];
    } else {
        [self scheduleTimerToRollLogFileDueToAge];
    }
}

- (void)maybeRollLogFileDueToSize {
    // This method is called from logMessage.
    // Keep it FAST.

    // Note: Use direct access to maximumFileSize variable.
    // We specifically wrote our own getter/setter method to allow us to do this (for performance reasons).

    if (_maximumFileSize > 0) {
        unsigned long long fileSize = [_currentLogFileHandle offsetInFile];

        if (fileSize >= _maximumFileSize) {
            NSLogVerbose(@"DDFileLogger: Rolling log file due to size (%qu)...", fileSize);

            [self rollLogFileNow];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark File Logging
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns the log file that should be used.
 * If there is an existing log file that is suitable,
 * within the constraints of maximumFileSize and rollingFrequency, then it is returned.
 *
 * Otherwise a new file is created and returned.
 **/
- (DDLogFileInfo *)currentLogFileInfo {
    if (_currentLogFileInfo == nil) {
        NSArray *sortedLogFileInfos = [logFileManager sortedLogFileInfos];

        if ([sortedLogFileInfos count] > 0) {
            DDLogFileInfo *mostRecentLogFileInfo = sortedLogFileInfos[0];

            BOOL shouldArchiveMostRecent = NO;

            if (mostRecentLogFileInfo.isArchived) {
                shouldArchiveMostRecent = NO;
            } else if (_maximumFileSize > 0 && mostRecentLogFileInfo.fileSize >= _maximumFileSize) {
                shouldArchiveMostRecent = YES;
            } else if (_rollingFrequency > 0.0 && mostRecentLogFileInfo.age >= _rollingFrequency) {
                shouldArchiveMostRecent = YES;
            }

        #if TARGET_OS_IPHONE
            // When creating log file on iOS we're setting NSFileProtectionKey attribute to NSFileProtectionCompleteUnlessOpen.
            //
            // But in case if app is able to launch from background we need to have an ability to open log file any time we
            // want (even if device is locked). Thats why that attribute have to be changed to
            // NSFileProtectionCompleteUntilFirstUserAuthentication.
            //
            // If previous log was created when app wasn't running in background, but now it is - we archive it and create
            // a new one.
            //
            // If user has overwritten to NSFileProtectionNone there is no neeed to create a new one.

            if (!_doNotReuseLogFiles && doesAppRunInBackground()) {
                NSString *key = mostRecentLogFileInfo.fileAttributes[NSFileProtectionKey];

                if ([key length] > 0 && !([key isEqualToString:NSFileProtectionCompleteUntilFirstUserAuthentication] || [key isEqualToString:NSFileProtectionNone])) {
                    shouldArchiveMostRecent = YES;
                }
            }

        #endif

            if (!_doNotReuseLogFiles && !mostRecentLogFileInfo.isArchived && !shouldArchiveMostRecent) {
                NSLogVerbose(@"DDFileLogger: Resuming logging with file %@", mostRecentLogFileInfo.fileName);

                _currentLogFileInfo = mostRecentLogFileInfo;
            } else {
                if (shouldArchiveMostRecent) {
                    mostRecentLogFileInfo.isArchived = YES;

                    if ([logFileManager respondsToSelector:@selector(didArchiveLogFile:)]) {
                        [logFileManager didArchiveLogFile:(mostRecentLogFileInfo.filePath)];
                    }
                }
            }
        }

        if (_currentLogFileInfo == nil) {
            NSString *currentLogFilePath = [logFileManager createNewLogFile];

            _currentLogFileInfo = [[DDLogFileInfo alloc] initWithFilePath:currentLogFilePath];
        }
    }

    return _currentLogFileInfo;
}

- (NSFileHandle *)currentLogFileHandle {
    if (_currentLogFileHandle == nil) {
        NSString *logFilePath = [[self currentLogFileInfo] filePath];

        _currentLogFileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
        [_currentLogFileHandle seekToEndOfFile];

        if (_currentLogFileHandle) {
            [self scheduleTimerToRollLogFileDueToAge];

            // Here we are monitoring the log file. In case if it would be deleted ormoved
            // somewhere we want to roll it and use a new one.
            _currentLogFileVnode = dispatch_source_create(
                    DISPATCH_SOURCE_TYPE_VNODE,
                    [_currentLogFileHandle fileDescriptor],
                    DISPATCH_VNODE_DELETE | DISPATCH_VNODE_RENAME,
                    self.loggerQueue
                    );

            dispatch_source_set_event_handler(_currentLogFileVnode, ^{ @autoreleasepool {
                                                                          NSLogInfo(@"DDFileLogger: Current logfile was moved. Rolling it and creating a new one");
                                                                          [self rollLogFileNow];
                                                                      } });

            #if !OS_OBJECT_USE_OBJC
            dispatch_source_t vnode = _currentLogFileVnode;
            dispatch_source_set_cancel_handler(_currentLogFileVnode, ^{
                dispatch_release(vnode);
            });
            #endif

            dispatch_resume(_currentLogFileVnode);
        }
    }

    return _currentLogFileHandle;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark DDLogger Protocol
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static int exception_count = 0;
- (void)logMessage:(DDLogMessage *)logMessage {
    NSString *message = logMessage->_message;
    BOOL isFormatted = NO;

    if (_logFormatter) {
        message = [_logFormatter formatLogMessage:logMessage];
        isFormatted = message != logMessage->_message;
    }

    if (message) {
        if ((!isFormatted || _automaticallyAppendNewlineForCustomFormatters) &&
            (![message hasSuffix:@"\n"])) {
            message = [message stringByAppendingString:@"\n"];
        }

        NSData *logData = [message dataUsingEncoding:NSUTF8StringEncoding];

        @try {
            [[self currentLogFileHandle] writeData:logData];

            [self maybeRollLogFileDueToSize];
        } @catch (NSException *exception) {
            exception_count++;

            if (exception_count <= 10) {
                NSLogError(@"DDFileLogger.logMessage: %@", exception);

                if (exception_count == 10) {
                    NSLogError(@"DDFileLogger.logMessage: Too many exceptions -- will not log any more of them.");
                }
            }
        }
    }
}

- (void)willRemoveLogger {
    // If you override me be sure to invoke [super willRemoveLogger];

    [self rollLogFileNow];
}

- (NSString *)loggerName {
    return @"cocoa.lumberjack.fileLogger";
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if TARGET_IPHONE_SIMULATOR
    static NSString * const kDDXAttrArchivedName = @"archived";
#else
    static NSString * const kDDXAttrArchivedName = @"lumberjack.log.archived";
#endif

@interface DDLogFileInfo () {
    __strong NSString *_filePath;
    __strong NSString *_fileName;
    
    __strong NSDictionary *_fileAttributes;
    
    __strong NSDate *_creationDate;
    __strong NSDate *_modificationDate;
    
    unsigned long long _fileSize;
}

@end


@implementation DDLogFileInfo

@synthesize filePath;

@dynamic fileName;
@dynamic fileAttributes;
@dynamic creationDate;
@dynamic modificationDate;
@dynamic fileSize;
@dynamic age;

@dynamic isArchived;


#pragma mark Lifecycle

+ (instancetype)logFileWithPath:(NSString *)aFilePath {
    return [[self alloc] initWithFilePath:aFilePath];
}

- (instancetype)initWithFilePath:(NSString *)aFilePath {
    if ((self = [super init])) {
        filePath = [aFilePath copy];
    }

    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Standard Info
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSDictionary *)fileAttributes {
    if (_fileAttributes == nil) {
        _fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    }

    return _fileAttributes;
}

- (NSString *)fileName {
    if (_fileName == nil) {
        _fileName = [filePath lastPathComponent];
    }

    return _fileName;
}

- (NSDate *)modificationDate {
    if (_modificationDate == nil) {
        _modificationDate = self.fileAttributes[NSFileModificationDate];
    }

    return _modificationDate;
}

- (NSDate *)creationDate {
    if (_creationDate == nil) {
        _creationDate = self.fileAttributes[NSFileCreationDate];
    }

    return _creationDate;
}

- (unsigned long long)fileSize {
    if (_fileSize == 0) {
        _fileSize = [self.fileAttributes[NSFileSize] unsignedLongLongValue];
    }

    return _fileSize;
}

- (NSTimeInterval)age {
    return [[self creationDate] timeIntervalSinceNow] * -1.0;
}

- (NSString *)description {
    return [@{ @"filePath": self.filePath ? : @"",
               @"fileName": self.fileName ? : @"",
               @"fileAttributes": self.fileAttributes ? : @"",
               @"creationDate": self.creationDate ? : @"",
               @"modificationDate": self.modificationDate ? : @"",
               @"fileSize": @(self.fileSize),
               @"age": @(self.age),
               @"isArchived": @(self.isArchived) } description];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Archiving
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)isArchived {
#if TARGET_IPHONE_SIMULATOR

    // Extended attributes don't work properly on the simulator.
    // So we have to use a less attractive alternative.
    // See full explanation in the header file.

    return [self hasExtensionAttributeWithName:kDDXAttrArchivedName];

#else

    return [self hasExtendedAttributeWithName:kDDXAttrArchivedName];

#endif
}

- (void)setIsArchived:(BOOL)flag {
#if TARGET_IPHONE_SIMULATOR

    // Extended attributes don't work properly on the simulator.
    // So we have to use a less attractive alternative.
    // See full explanation in the header file.

    if (flag) {
        [self addExtensionAttributeWithName:kDDXAttrArchivedName];
    } else {
        [self removeExtensionAttributeWithName:kDDXAttrArchivedName];
    }

#else

    if (flag) {
        [self addExtendedAttributeWithName:kDDXAttrArchivedName];
    } else {
        [self removeExtendedAttributeWithName:kDDXAttrArchivedName];
    }

#endif
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Changes
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)reset {
    _fileName = nil;
    _fileAttributes = nil;
    _creationDate = nil;
    _modificationDate = nil;
}

- (void)renameFile:(NSString *)newFileName {
    // This method is only used on the iPhone simulator, where normal extended attributes are broken.
    // See full explanation in the header file.

    if (![newFileName isEqualToString:[self fileName]]) {
        NSString *fileDir = [filePath stringByDeletingLastPathComponent];

        NSString *newFilePath = [fileDir stringByAppendingPathComponent:newFileName];

        NSLogVerbose(@"DDLogFileInfo: Renaming file: '%@' -> '%@'", self.fileName, newFileName);

        NSError *error = nil;

        if ([[NSFileManager defaultManager] fileExistsAtPath:newFilePath] &&
            ![[NSFileManager defaultManager] removeItemAtPath:newFilePath error:&error]) {
            NSLogError(@"DDLogFileInfo: Error deleting archive (%@): %@", self.fileName, error);
        }

        if (![[NSFileManager defaultManager] moveItemAtPath:filePath toPath:newFilePath error:&error]) {
            NSLogError(@"DDLogFileInfo: Error renaming file (%@): %@", self.fileName, error);
        }

        filePath = newFilePath;
        [self reset];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Attribute Management
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if TARGET_IPHONE_SIMULATOR

// Extended attributes don't work properly on the simulator.
// So we have to use a less attractive alternative.
// See full explanation in the header file.

- (BOOL)hasExtensionAttributeWithName:(NSString *)attrName {
    // This method is only used on the iPhone simulator, where normal extended attributes are broken.
    // See full explanation in the header file.

    // Split the file name into components. File name may have various format, but generally
    // structure is same:
    //
    // <name part>.<extension part> and <name part>.archived.<extension part>
    // or
    // <name part> and <name part>.archived
    //
    // So we want to search for the attrName in the components (ignoring the first array index).

    NSArray *components = [[self fileName] componentsSeparatedByString:@"."];

    // Watch out for file names without an extension

    for (NSUInteger i = 1; i < components.count; i++) {
        NSString *attr = components[i];

        if ([attrName isEqualToString:attr]) {
            return YES;
        }
    }

    return NO;
}

- (void)addExtensionAttributeWithName:(NSString *)attrName {
    // This method is only used on the iPhone simulator, where normal extended attributes are broken.
    // See full explanation in the header file.

    if ([attrName length] == 0) {
        return;
    }

    // Example:
    // attrName = "archived"
    //
    // "mylog.txt" -> "mylog.archived.txt"
    // "mylog"     -> "mylog.archived"

    NSArray *components = [[self fileName] componentsSeparatedByString:@"."];

    NSUInteger count = [components count];

    NSUInteger estimatedNewLength = [[self fileName] length] + [attrName length] + 1;
    NSMutableString *newFileName = [NSMutableString stringWithCapacity:estimatedNewLength];

    if (count > 0) {
        [newFileName appendString:components.firstObject];
    }

    NSString *lastExt = @"";

    NSUInteger i;

    for (i = 1; i < count; i++) {
        NSString *attr = components[i];

        if ([attr length] == 0) {
            continue;
        }

        if ([attrName isEqualToString:attr]) {
            // Extension attribute already exists in file name
            return;
        }

        if ([lastExt length] > 0) {
            [newFileName appendFormat:@".%@", lastExt];
        }

        lastExt = attr;
    }

    [newFileName appendFormat:@".%@", attrName];

    if ([lastExt length] > 0) {
        [newFileName appendFormat:@".%@", lastExt];
    }

    [self renameFile:newFileName];
}

- (void)removeExtensionAttributeWithName:(NSString *)attrName {
    // This method is only used on the iPhone simulator, where normal extended attributes are broken.
    // See full explanation in the header file.

    if ([attrName length] == 0) {
        return;
    }

    // Example:
    // attrName = "archived"
    //
    // "mylog.archived.txt" -> "mylog.txt"
    // "mylog.archived"     -> "mylog"

    NSArray *components = [[self fileName] componentsSeparatedByString:@"."];

    NSUInteger count = [components count];

    NSUInteger estimatedNewLength = [[self fileName] length];
    NSMutableString *newFileName = [NSMutableString stringWithCapacity:estimatedNewLength];

    if (count > 0) {
        [newFileName appendString:components.firstObject];
    }

    BOOL found = NO;

    NSUInteger i;

    for (i = 1; i < count; i++) {
        NSString *attr = components[i];

        if ([attrName isEqualToString:attr]) {
            found = YES;
        } else {
            [newFileName appendFormat:@".%@", attr];
        }
    }

    if (found) {
        [self renameFile:newFileName];
    }
}

#else /* if TARGET_IPHONE_SIMULATOR */

- (BOOL)hasExtendedAttributeWithName:(NSString *)attrName {
    const char *path = [filePath UTF8String];
    const char *name = [attrName UTF8String];

    ssize_t result = getxattr(path, name, NULL, 0, 0, 0);

    return (result >= 0);
}

- (void)addExtendedAttributeWithName:(NSString *)attrName {
    const char *path = [filePath UTF8String];
    const char *name = [attrName UTF8String];

    int result = setxattr(path, name, NULL, 0, 0, 0);

    if (result < 0) {
        NSLogError(@"DDLogFileInfo: setxattr(%@, %@): error = %s",
                   attrName,
                   filePath,
                   strerror(errno));
    }
}

- (void)removeExtendedAttributeWithName:(NSString *)attrName {
    const char *path = [filePath UTF8String];
    const char *name = [attrName UTF8String];

    int result = removexattr(path, name, 0);

    if (result < 0 && errno != ENOATTR) {
        NSLogError(@"DDLogFileInfo: removexattr(%@, %@): error = %s",
                   attrName,
                   self.fileName,
                   strerror(errno));
    }
}

#endif /* if TARGET_IPHONE_SIMULATOR */

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Comparisons
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        DDLogFileInfo *another = (DDLogFileInfo *)object;

        return [filePath isEqualToString:[another filePath]];
    }

    return NO;
}

- (NSComparisonResult)reverseCompareByCreationDate:(DDLogFileInfo *)another {
    NSDate *us = [self creationDate];
    NSDate *them = [another creationDate];

    NSComparisonResult result = [us compare:them];

    if (result == NSOrderedAscending) {
        return NSOrderedDescending;
    }

    if (result == NSOrderedDescending) {
        return NSOrderedAscending;
    }

    return NSOrderedSame;
}

- (NSComparisonResult)reverseCompareByModificationDate:(DDLogFileInfo *)another {
    NSDate *us = [self modificationDate];
    NSDate *them = [another modificationDate];

    NSComparisonResult result = [us compare:them];

    if (result == NSOrderedAscending) {
        return NSOrderedDescending;
    }

    if (result == NSOrderedDescending) {
        return NSOrderedAscending;
    }

    return NSOrderedSame;
}

@end

#if TARGET_OS_IPHONE
/**
 * When creating log file on iOS we're setting NSFileProtectionKey attribute to NSFileProtectionCompleteUnlessOpen.
 *
 * But in case if app is able to launch from background we need to have an ability to open log file any time we
 * want (even if device is locked). Thats why that attribute have to be changed to
 * NSFileProtectionCompleteUntilFirstUserAuthentication.
 */
BOOL doesAppRunInBackground() {
    BOOL answer = NO;

    NSArray *backgroundModes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"];

    for (NSString *mode in backgroundModes) {
        if (mode.length > 0) {
            answer = YES;
            break;
        }
    }

    return answer;
}

#endif
// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2016, Deusty, LLC
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Neither the name of Deusty nor the names of its contributors may be used
//   to endorse or promote products derived from this software without specific
//   prior written permission of Deusty, LLC.

// Disable legacy macros
#ifndef DD_LEGACY_MACROS
    #define DD_LEGACY_MACROS 0
#endif

#import <pthread.h>
#import <objc/runtime.h>
#import <mach/mach_host.h>
#import <mach/host_info.h>
#import <libkern/OSAtomic.h>
#import <Availability.h>
#if TARGET_OS_IOS
    #import <UIKit/UIDevice.h>
#endif


#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

// We probably shouldn't be using DDLog() statements within the DDLog implementation.
// But we still want to leave our log statements for any future debugging,
// and to allow other developers to trace the implementation (which is a great learning tool).
//
// So we use a primitive logging macro around NSLog.
// We maintain the NS prefix on the macros to be explicit about the fact that we're using NSLog.

#ifndef DD_DEBUG
    #define DD_DEBUG NO
#endif


// Specifies the maximum queue size of the logging thread.
//
// Since most logging is asynchronous, its possible for rogue threads to flood the logging queue.
// That is, to issue an abundance of log statements faster than the logging thread can keepup.
// Typically such a scenario occurs when log statements are added haphazardly within large loops,
// but may also be possible if relatively slow loggers are being used.
//
// This property caps the queue size at a given number of outstanding log statements.
// If a thread attempts to issue a log statement when the queue is already maxed out,
// the issuing thread will block until the queue size drops below the max again.

#define LOG_MAX_QUEUE_SIZE 1000 // Should not exceed INT32_MAX

// The "global logging queue" refers to [DDLog loggingQueue].
// It is the queue that all log statements go through.
//
// The logging queue sets a flag via dispatch_queue_set_specific using this key.
// We can check for this key via dispatch_get_specific() to see if we're on the "global logging queue".

static void *const GlobalLoggingQueueIdentityKey = (void *)&GlobalLoggingQueueIdentityKey;

@interface DDLoggerNode : NSObject
{
    // Direct accessors to be used only for performance
    @public
    id <DDLogger> _logger;
    DDLogLevel _level;
    dispatch_queue_t _loggerQueue;
}

@property (nonatomic, readonly) id <DDLogger> logger;
@property (nonatomic, readonly) DDLogLevel level;
@property (nonatomic, readonly) dispatch_queue_t loggerQueue;

+ (DDLoggerNode *)nodeWithLogger:(id <DDLogger>)logger
                     loggerQueue:(dispatch_queue_t)loggerQueue
                           level:(DDLogLevel)level;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface DDLog ()

// An array used to manage all the individual loggers.
// The array is only modified on the loggingQueue/loggingThread.
@property (nonatomic, strong) NSMutableArray *_loggers;

@end

@implementation DDLog

// All logging statements are added to the same queue to ensure FIFO operation.
static dispatch_queue_t _loggingQueue;

// Individual loggers are executed concurrently per log statement.
// Each logger has it's own associated queue, and a dispatch group is used for synchrnoization.
static dispatch_group_t _loggingGroup;

// In order to prevent to queue from growing infinitely large,
// a maximum size is enforced (LOG_MAX_QUEUE_SIZE).
static dispatch_semaphore_t _queueSemaphore;

// Minor optimization for uniprocessor machines
static NSUInteger _numProcessors;

/**
 *  Returns the singleton `DDLog`.
 *  The instance is used by `DDLog` class methods.
 *
 *  @return The singleton `DDLog`.
 */
+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

/**
 * The runtime sends initialize to each class in a program exactly one time just before the class,
 * or any class that inherits from it, is sent its first message from within the program. (Thus the
 * method may never be invoked if the class is not used.) The runtime sends the initialize message to
 * classes in a thread-safe manner. Superclasses receive this message before their subclasses.
 *
 * This method may also be called directly (assumably by accident), hence the safety mechanism.
 **/
+ (void)initialize {
    static dispatch_once_t DDLogOnceToken;
    
    dispatch_once(&DDLogOnceToken, ^{
        NSLogDebug(@"DDLog: Using grand central dispatch");
        
        _loggingQueue = dispatch_queue_create("cocoa.lumberjack", NULL);
        _loggingGroup = dispatch_group_create();
        
        void *nonNullValue = GlobalLoggingQueueIdentityKey; // Whatever, just not null
        dispatch_queue_set_specific(_loggingQueue, GlobalLoggingQueueIdentityKey, nonNullValue, NULL);
        
        _queueSemaphore = dispatch_semaphore_create(LOG_MAX_QUEUE_SIZE);
        
        // Figure out how many processors are available.
        // This may be used later for an optimization on uniprocessor machines.
        
        _numProcessors = MAX([NSProcessInfo processInfo].processorCount, 1);
        
        NSLogDebug(@"DDLog: numProcessors = %@", @(_numProcessors));
    });
}

/**
 *  The `DDLog` initializer.
 *  Static variables are set only once.
 *
 *  @return An initialized `DDLog` instance.
 */
- (id)init {
    self = [super init];
    
    if (self) {
        self._loggers = [[NSMutableArray alloc] initWithCapacity:4];
        
#if TARGET_OS_IOS
        NSString *notificationName = @"UIApplicationWillTerminateNotification";
#else
        NSString *notificationName = nil;
        
        // On Command Line Tool apps AppKit may not be avaliable
#ifdef NSAppKitVersionNumber10_0
        
        if (NSApp) {
            notificationName = @"NSApplicationWillTerminateNotification";
        }
        
#endif
        
        if (!notificationName) {
            // If there is no NSApp -> we are running Command Line Tool app.
            // In this case terminate notification wouldn't be fired, so we use workaround.
            atexit_b (^{
                [self applicationWillTerminate:nil];
            });
        }
        
#endif /* if TARGET_OS_IOS */
        
        if (notificationName) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationWillTerminate:)
                                                         name:notificationName
                                                       object:nil];
        }
    }
    
    return self;
}

/**
 * Provides access to the logging queue.
 **/
+ (dispatch_queue_t)loggingQueue {
    return _loggingQueue;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Notifications
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)applicationWillTerminate:(NSNotification * __attribute__((unused)))notification {
    [self flushLog];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Logger Management
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (void)addLogger:(id <DDLogger>)logger {
    [self.sharedInstance addLogger:logger];
}

- (void)addLogger:(id <DDLogger>)logger {
    [self addLogger:logger withLevel:DDLogLevelAll]; // DDLogLevelAll has all bits set
}

+ (void)addLogger:(id <DDLogger>)logger withLevel:(DDLogLevel)level {
    [self.sharedInstance addLogger:logger withLevel:level];
}

- (void)addLogger:(id <DDLogger>)logger withLevel:(DDLogLevel)level {
    if (!logger) {
        return;
    }
    
    dispatch_async(_loggingQueue, ^{ @autoreleasepool {
        [self lt_addLogger:logger level:level];
    } });
}

+ (void)removeLogger:(id <DDLogger>)logger {
    [self.sharedInstance removeLogger:logger];
}

- (void)removeLogger:(id <DDLogger>)logger {
    if (!logger) {
        return;
    }
    
    dispatch_async(_loggingQueue, ^{ @autoreleasepool {
        [self lt_removeLogger:logger];
    } });
}

+ (void)removeAllLoggers {
    [self.sharedInstance removeAllLoggers];
}

- (void)removeAllLoggers {
    dispatch_async(_loggingQueue, ^{ @autoreleasepool {
        [self lt_removeAllLoggers];
    } });
}

+ (NSArray *)allLoggers {
    return [self.sharedInstance allLoggers];
}

- (NSArray *)allLoggers {
    __block NSArray *theLoggers;
    
    dispatch_sync(_loggingQueue, ^{ @autoreleasepool {
        theLoggers = [self lt_allLoggers];
    } });
    
    return theLoggers;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Master Logging
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)queueLogMessage:(DDLogMessage *)logMessage asynchronously:(BOOL)asyncFlag {
    // We have a tricky situation here...
    //
    // In the common case, when the queueSize is below the maximumQueueSize,
    // we want to simply enqueue the logMessage. And we want to do this as fast as possible,
    // which means we don't want to block and we don't want to use any locks.
    //
    // However, if the queueSize gets too big, we want to block.
    // But we have very strict requirements as to when we block, and how long we block.
    //
    // The following example should help illustrate our requirements:
    //
    // Imagine that the maximum queue size is configured to be 5,
    // and that there are already 5 log messages queued.
    // Let us call these 5 queued log messages A, B, C, D, and E. (A is next to be executed)
    //
    // Now if our thread issues a log statement (let us call the log message F),
    // it should block before the message is added to the queue.
    // Furthermore, it should be unblocked immediately after A has been unqueued.
    //
    // The requirements are strict in this manner so that we block only as long as necessary,
    // and so that blocked threads are unblocked in the order in which they were blocked.
    //
    // Returning to our previous example, let us assume that log messages A through E are still queued.
    // Our aforementioned thread is blocked attempting to queue log message F.
    // Now assume we have another separate thread that attempts to issue log message G.
    // It should block until log messages A and B have been unqueued.


    // We are using a counting semaphore provided by GCD.
    // The semaphore is initialized with our LOG_MAX_QUEUE_SIZE value.
    // Everytime we want to queue a log message we decrement this value.
    // If the resulting value is less than zero,
    // the semaphore function waits in FIFO order for a signal to occur before returning.
    //
    // A dispatch semaphore is an efficient implementation of a traditional counting semaphore.
    // Dispatch semaphores call down to the kernel only when the calling thread needs to be blocked.
    // If the calling semaphore does not need to block, no kernel call is made.

    dispatch_semaphore_wait(_queueSemaphore, DISPATCH_TIME_FOREVER);

    // We've now sure we won't overflow the queue.
    // It is time to queue our log message.

    dispatch_block_t logBlock = ^{
        @autoreleasepool {
            [self lt_log:logMessage];
        }
    };

    if (asyncFlag) {
        dispatch_async(_loggingQueue, logBlock);
    } else {
        dispatch_sync(_loggingQueue, logBlock);
    }
}

+ (void)log:(BOOL)asynchronous
      level:(DDLogLevel)level
       flag:(DDLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format, ... {
    va_list args;
    
    if (format) {
        va_start(args, format);
        
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        [self log:asynchronous
          message:message
            level:level
             flag:flag
          context:context
             file:file
         function:function
             line:line
              tag:tag];
        
        va_end(args);
    }
}

- (void)log:(BOOL)asynchronous
      level:(DDLogLevel)level
       flag:(DDLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format, ... {
    va_list args;
    
    if (format) {
        va_start(args, format);
        
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        [self log:asynchronous
          message:message
            level:level
             flag:flag
          context:context
             file:file
         function:function
             line:line
              tag:tag];
        
        va_end(args);
    }
}

+ (void)log:(BOOL)asynchronous
      level:(DDLogLevel)level
       flag:(DDLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format
       args:(va_list)args {
    [self.sharedInstance log:asynchronous level:level flag:flag context:context file:file function:function line:line tag:tag format:format args:args];
}

- (void)log:(BOOL)asynchronous
      level:(DDLogLevel)level
       flag:(DDLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format
       args:(va_list)args {
    if (format) {
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        [self log:asynchronous
          message:message
            level:level
             flag:flag
          context:context
             file:file
         function:function
             line:line
              tag:tag];
    }
}

+ (void)log:(BOOL)asynchronous
    message:(NSString *)message
      level:(DDLogLevel)level
       flag:(DDLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag {
    [self.sharedInstance log:asynchronous message:message level:level flag:flag context:context file:file function:function line:line tag:tag];
}

- (void)log:(BOOL)asynchronous
    message:(NSString *)message
      level:(DDLogLevel)level
       flag:(DDLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag {
    DDLogMessage *logMessage = [[DDLogMessage alloc] initWithMessage:message
                                                               level:level
                                                                flag:flag
                                                             context:context
                                                                file:[NSString stringWithFormat:@"%s", file]
                                                            function:[NSString stringWithFormat:@"%s", function]
                                                                line:line
                                                                 tag:tag
                                                             options:(DDLogMessageOptions)0
                                                           timestamp:nil];
    
    [self queueLogMessage:logMessage asynchronously:asynchronous];
}

+ (void)log:(BOOL)asynchronous
    message:(DDLogMessage *)logMessage {
    [self.sharedInstance log:asynchronous message:logMessage];
}

- (void)log:(BOOL)asynchronous
    message:(DDLogMessage *)logMessage {
    [self queueLogMessage:logMessage asynchronously:asynchronous];
}

+ (void)flushLog {
    [self.sharedInstance flushLog];
}

- (void)flushLog {
    dispatch_sync(_loggingQueue, ^{ @autoreleasepool {
        [self lt_flush];
    } });
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Registered Dynamic Logging
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (BOOL)isRegisteredClass:(Class)class {
    SEL getterSel = @selector(ddLogLevel);
    SEL setterSel = @selector(ddSetLogLevel:);

#if TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR

    // Issue #6 (GoogleCode) - Crashes on iOS 4.2.1 and iPhone 4
    //
    // Crash caused by class_getClassMethod(2).
    //
    //     "It's a bug with UIAccessibilitySafeCategory__NSObject so it didn't pop up until
    //      users had VoiceOver enabled [...]. I was able to work around it by searching the
    //      result of class_copyMethodList() instead of calling class_getClassMethod()"

    BOOL result = NO;

    unsigned int methodCount, i;
    Method *methodList = class_copyMethodList(object_getClass(class), &methodCount);

    if (methodList != NULL) {
        BOOL getterFound = NO;
        BOOL setterFound = NO;

        for (i = 0; i < methodCount; ++i) {
            SEL currentSel = method_getName(methodList[i]);

            if (currentSel == getterSel) {
                getterFound = YES;
            } else if (currentSel == setterSel) {
                setterFound = YES;
            }

            if (getterFound && setterFound) {
                result = YES;
                break;
            }
        }

        free(methodList);
    }

    return result;

#else /* if TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR */

    // Issue #24 (GitHub) - Crashing in in ARC+Simulator
    //
    // The method +[DDLog isRegisteredClass] will crash a project when using it with ARC + Simulator.
    // For running in the Simulator, it needs to execute the non-iOS code.

    Method getter = class_getClassMethod(class, getterSel);
    Method setter = class_getClassMethod(class, setterSel);

    if ((getter != NULL) && (setter != NULL)) {
        return YES;
    }

    return NO;

#endif /* if TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR */
}

+ (NSArray *)registeredClasses {

    // We're going to get the list of all registered classes.
    // The Objective-C runtime library automatically registers all the classes defined in your source code.
    //
    // To do this we use the following method (documented in the Objective-C Runtime Reference):
    //
    // int objc_getClassList(Class *buffer, int bufferLen)
    //
    // We can pass (NULL, 0) to obtain the total number of
    // registered class definitions without actually retrieving any class definitions.
    // This allows us to allocate the minimum amount of memory needed for the application.

    NSUInteger numClasses = 0;
    Class *classes = NULL;

    while (numClasses == 0) {

        numClasses = (NSUInteger)MAX(objc_getClassList(NULL, 0), 0);

        // numClasses now tells us how many classes we have (but it might change)
        // So we can allocate our buffer, and get pointers to all the class definitions.

        NSUInteger bufferSize = numClasses;

        classes = numClasses ? (Class *)malloc(sizeof(Class) * bufferSize) : NULL;
        if (classes == NULL) {
            return nil; //no memory or classes?
        }

        numClasses = (NSUInteger)MAX(objc_getClassList(classes, (int)bufferSize),0);

        if (numClasses > bufferSize || numClasses == 0) {
            //apparently more classes added between calls (or a problem); try again
            free(classes);
            numClasses = 0;
        }
    }

    // We can now loop through the classes, and test each one to see if it is a DDLogging class.

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:numClasses];

    for (NSUInteger i = 0; i < numClasses; i++) {
        Class class = classes[i];

        if ([self isRegisteredClass:class]) {
            [result addObject:class];
        }
    }

    free(classes);

    return result;
}

+ (NSArray *)registeredClassNames {
    NSArray *registeredClasses = [self registeredClasses];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[registeredClasses count]];

    for (Class class in registeredClasses) {
        [result addObject:NSStringFromClass(class)];
    }
    return result;
}

+ (DDLogLevel)levelForClass:(Class)aClass {
    if ([self isRegisteredClass:aClass]) {
        return [aClass ddLogLevel];
    }
    return (DDLogLevel)-1;
}

+ (DDLogLevel)levelForClassWithName:(NSString *)aClassName {
    Class aClass = NSClassFromString(aClassName);

    return [self levelForClass:aClass];
}

+ (void)setLevel:(DDLogLevel)level forClass:(Class)aClass {
    if ([self isRegisteredClass:aClass]) {
        [aClass ddSetLogLevel:level];
    }
}

+ (void)setLevel:(DDLogLevel)level forClassWithName:(NSString *)aClassName {
    Class aClass = NSClassFromString(aClassName);
    [self setLevel:level forClass:aClass];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Logging Thread
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)lt_addLogger:(id <DDLogger>)logger level:(DDLogLevel)level {
    // Add to loggers array.
    // Need to create loggerQueue if loggerNode doesn't provide one.

    for (DDLoggerNode* node in self._loggers) {
        if (node->_logger == logger
            && node->_level == level) {
            // Exactly same logger already added, exit
            return;
        }
    }

    NSAssert(dispatch_get_specific(GlobalLoggingQueueIdentityKey),
             @"This method should only be run on the logging thread/queue");

    dispatch_queue_t loggerQueue = NULL;

    if ([logger respondsToSelector:@selector(loggerQueue)]) {
        // Logger may be providing its own queue

        loggerQueue = [logger loggerQueue];
    }

    if (loggerQueue == nil) {
        // Automatically create queue for the logger.
        // Use the logger name as the queue name if possible.

        const char *loggerQueueName = NULL;

        if ([logger respondsToSelector:@selector(loggerName)]) {
            loggerQueueName = [[logger loggerName] UTF8String];
        }

        loggerQueue = dispatch_queue_create(loggerQueueName, NULL);
    }

    DDLoggerNode *loggerNode = [DDLoggerNode nodeWithLogger:logger loggerQueue:loggerQueue level:level];
    [self._loggers addObject:loggerNode];

    if ([logger respondsToSelector:@selector(didAddLogger)]) {
        dispatch_async(loggerNode->_loggerQueue, ^{ @autoreleasepool {
            [logger didAddLogger];
        } });
    }
}

- (void)lt_removeLogger:(id <DDLogger>)logger {
    // Find associated loggerNode in list of added loggers

    NSAssert(dispatch_get_specific(GlobalLoggingQueueIdentityKey),
             @"This method should only be run on the logging thread/queue");

    DDLoggerNode *loggerNode = nil;

    for (DDLoggerNode *node in self._loggers) {
        if (node->_logger == logger) {
            loggerNode = node;
            break;
        }
    }
    
    if (loggerNode == nil) {
        NSLogDebug(@"DDLog: Request to remove logger which wasn't added");
        return;
    }
    
    // Notify logger
    if ([logger respondsToSelector:@selector(willRemoveLogger)]) {
        dispatch_async(loggerNode->_loggerQueue, ^{ @autoreleasepool {
            [logger willRemoveLogger];
        } });
    }
    
    // Remove from loggers array
    [self._loggers removeObject:loggerNode];
}

- (void)lt_removeAllLoggers {
    NSAssert(dispatch_get_specific(GlobalLoggingQueueIdentityKey),
             @"This method should only be run on the logging thread/queue");
    
    // Notify all loggers
    for (DDLoggerNode *loggerNode in self._loggers) {
        if ([loggerNode->_logger respondsToSelector:@selector(willRemoveLogger)]) {
            dispatch_async(loggerNode->_loggerQueue, ^{ @autoreleasepool {
                [loggerNode->_logger willRemoveLogger];
            } });
        }
    }
    
    // Remove all loggers from array

    [self._loggers removeAllObjects];
}

- (NSArray *)lt_allLoggers {
    NSAssert(dispatch_get_specific(GlobalLoggingQueueIdentityKey),
             @"This method should only be run on the logging thread/queue");

    NSMutableArray *theLoggers = [NSMutableArray new];

    for (DDLoggerNode *loggerNode in self._loggers) {
        [theLoggers addObject:loggerNode->_logger];
    }

    return [theLoggers copy];
}

- (void)lt_log:(DDLogMessage *)logMessage {
    // Execute the given log message on each of our loggers.

    NSAssert(dispatch_get_specific(GlobalLoggingQueueIdentityKey),
             @"This method should only be run on the logging thread/queue");

    if (_numProcessors > 1) {
        // Execute each logger concurrently, each within its own queue.
        // All blocks are added to same group.
        // After each block has been queued, wait on group.
        //
        // The waiting ensures that a slow logger doesn't end up with a large queue of pending log messages.
        // This would defeat the purpose of the efforts we made earlier to restrict the max queue size.

        for (DDLoggerNode *loggerNode in self._loggers) {
            // skip the loggers that shouldn't write this message based on the log level

            if (!(logMessage->_flag & loggerNode->_level)) {
                continue;
            }
            
            dispatch_group_async(_loggingGroup, loggerNode->_loggerQueue, ^{ @autoreleasepool {
                [loggerNode->_logger logMessage:logMessage];
            } });
        }
        
        dispatch_group_wait(_loggingGroup, DISPATCH_TIME_FOREVER);
    } else {
        // Execute each logger serialy, each within its own queue.
        
        for (DDLoggerNode *loggerNode in self._loggers) {
            // skip the loggers that shouldn't write this message based on the log level

            if (!(logMessage->_flag & loggerNode->_level)) {
                continue;
            }
            
            dispatch_sync(loggerNode->_loggerQueue, ^{ @autoreleasepool {
                [loggerNode->_logger logMessage:logMessage];
            } });
        }
    }

    // If our queue got too big, there may be blocked threads waiting to add log messages to the queue.
    // Since we've now dequeued an item from the log, we may need to unblock the next thread.

    // We are using a counting semaphore provided by GCD.
    // The semaphore is initialized with our LOG_MAX_QUEUE_SIZE value.
    // When a log message is queued this value is decremented.
    // When a log message is dequeued this value is incremented.
    // If the value ever drops below zero,
    // the queueing thread blocks and waits in FIFO order for us to signal it.
    //
    // A dispatch semaphore is an efficient implementation of a traditional counting semaphore.
    // Dispatch semaphores call down to the kernel only when the calling thread needs to be blocked.
    // If the calling semaphore does not need to block, no kernel call is made.

    dispatch_semaphore_signal(_queueSemaphore);
}

- (void)lt_flush {
    // All log statements issued before the flush method was invoked have now been executed.
    //
    // Now we need to propogate the flush request to any loggers that implement the flush method.
    // This is designed for loggers that buffer IO.
    
    NSAssert(dispatch_get_specific(GlobalLoggingQueueIdentityKey),
             @"This method should only be run on the logging thread/queue");
    
    for (DDLoggerNode *loggerNode in self._loggers) {
        if ([loggerNode->_logger respondsToSelector:@selector(flush)]) {
            dispatch_group_async(_loggingGroup, loggerNode->_loggerQueue, ^{ @autoreleasepool {
                [loggerNode->_logger flush];
            } });
        }
    }
    
    dispatch_group_wait(_loggingGroup, DISPATCH_TIME_FOREVER);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Utilities
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

NSString * DDExtractFileNameWithoutExtension(const char *filePath, BOOL copy) {
    if (filePath == NULL) {
        return nil;
    }

    char *lastSlash = NULL;
    char *lastDot = NULL;

    char *p = (char *)filePath;

    while (*p != '\0') {
        if (*p == '/') {
            lastSlash = p;
        } else if (*p == '.') {
            lastDot = p;
        }

        p++;
    }

    char *subStr;
    NSUInteger subLen;

    if (lastSlash) {
        if (lastDot) {
            // lastSlash -> lastDot
            subStr = lastSlash + 1;
            subLen = (NSUInteger)(lastDot - subStr);
        } else {
            // lastSlash -> endOfString
            subStr = lastSlash + 1;
            subLen = (NSUInteger)(p - subStr);
        }
    } else {
        if (lastDot) {
            // startOfString -> lastDot
            subStr = (char *)filePath;
            subLen = (NSUInteger)(lastDot - subStr);
        } else {
            // startOfString -> endOfString
            subStr = (char *)filePath;
            subLen = (NSUInteger)(p - subStr);
        }
    }

    if (copy) {
        return [[NSString alloc] initWithBytes:subStr
                                        length:subLen
                                      encoding:NSUTF8StringEncoding];
    } else {
        // We can take advantage of the fact that __FILE__ is a string literal.
        // Specifically, we don't need to waste time copying the string.
        // We can just tell NSString to point to a range within the string literal.

        return [[NSString alloc] initWithBytesNoCopy:subStr
                                              length:subLen
                                            encoding:NSUTF8StringEncoding
                                        freeWhenDone:NO];
    }
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation DDLoggerNode

- (instancetype)initWithLogger:(id <DDLogger>)logger loggerQueue:(dispatch_queue_t)loggerQueue level:(DDLogLevel)level {
    if ((self = [super init])) {
        _logger = logger;

        if (loggerQueue) {
            _loggerQueue = loggerQueue;
            #if !OS_OBJECT_USE_OBJC
            dispatch_retain(loggerQueue);
            #endif
        }

        _level = level;
    }
    return self;
}

+ (DDLoggerNode *)nodeWithLogger:(id <DDLogger>)logger loggerQueue:(dispatch_queue_t)loggerQueue level:(DDLogLevel)level {
    return [[DDLoggerNode alloc] initWithLogger:logger loggerQueue:loggerQueue level:level];
}

- (void)dealloc {
    #if !OS_OBJECT_USE_OBJC
    if (_loggerQueue) {
        dispatch_release(_loggerQueue);
    }
    #endif
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation DDLogMessage

// Can we use DISPATCH_CURRENT_QUEUE_LABEL ?
// Can we use dispatch_get_current_queue (without it crashing) ?
//
// a) Compiling against newer SDK's (iOS 7+/OS X 10.9+) where DISPATCH_CURRENT_QUEUE_LABEL is defined
//    on a (iOS 7.0+/OS X 10.9+) runtime version
//
// b) Systems where dispatch_get_current_queue is not yet deprecated and won't crash (< iOS 6.0/OS X 10.9)
//
//    dispatch_get_current_queue(void);
//      __OSX_AVAILABLE_BUT_DEPRECATED(__MAC_10_6,__MAC_10_9,__IPHONE_4_0,__IPHONE_6_0)

#if TARGET_OS_IOS

// Compiling for iOS

    #define USE_DISPATCH_CURRENT_QUEUE_LABEL ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    #define USE_DISPATCH_GET_CURRENT_QUEUE   ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.1)

#elif TARGET_OS_WATCH || TARGET_OS_TV

// Compiling for watchOS, tvOS

#define USE_DISPATCH_CURRENT_QUEUE_LABEL YES
#define USE_DISPATCH_GET_CURRENT_QUEUE   YES

#else

// Compiling for Mac OS X

  #ifndef MAC_OS_X_VERSION_10_9
    #define MAC_OS_X_VERSION_10_9            1090
  #endif

  #if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_9 // Mac OS X 10.9 or later required

    #define USE_DISPATCH_CURRENT_QUEUE_LABEL YES
    #define USE_DISPATCH_GET_CURRENT_QUEUE   NO

  #else

    #define USE_DISPATCH_CURRENT_QUEUE_LABEL ([NSTimer instancesRespondToSelector : @selector(tolerance)]) // OS X 10.9+
    #define USE_DISPATCH_GET_CURRENT_QUEUE   (![NSTimer instancesRespondToSelector : @selector(tolerance)]) // < OS X 10.9

  #endif

#endif /* if TARGET_OS_IOS */

// Should we use pthread_threadid_np ?
// With iOS 8+/OSX 10.10+ NSLog uses pthread_threadid_np instead of pthread_mach_thread_np

#if TARGET_OS_IOS

// Compiling for iOS

  #ifndef kCFCoreFoundationVersionNumber_iOS_8_0
    #define kCFCoreFoundationVersionNumber_iOS_8_0 1140.10
  #endif

    #define USE_PTHREAD_THREADID_NP                (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0)

#elif TARGET_OS_WATCH || TARGET_OS_TV

// Compiling for watchOS, tvOS

#define USE_PTHREAD_THREADID_NP                    YES

#else

// Compiling for Mac OS X

  #ifndef kCFCoreFoundationVersionNumber10_10
    #define kCFCoreFoundationVersionNumber10_10    1151.16
  #endif

    #define USE_PTHREAD_THREADID_NP                (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber10_10)

#endif /* if TARGET_OS_IOS */

- (instancetype)initWithMessage:(NSString *)message
                          level:(DDLogLevel)level
                           flag:(DDLogFlag)flag
                        context:(NSInteger)context
                           file:(NSString *)file
                       function:(NSString *)function
                           line:(NSUInteger)line
                            tag:(id)tag
                        options:(DDLogMessageOptions)options
                      timestamp:(NSDate *)timestamp {
    if ((self = [super init])) {
        _message      = [message copy];
        _level        = level;
        _flag         = flag;
        _context      = context;

        BOOL copyFile = (options & DDLogMessageCopyFile) == DDLogMessageCopyFile;
        _file = copyFile ? [file copy] : file;

        BOOL copyFunction = (options & DDLogMessageCopyFunction) == DDLogMessageCopyFunction;
        _function = copyFunction ? [function copy] : function;

        _line         = line;
        _tag          = tag;
        _options      = options;
        _timestamp    = timestamp ?: [NSDate new];

        if (USE_PTHREAD_THREADID_NP) {
            __uint64_t tid;
            pthread_threadid_np(NULL, &tid);
            _threadID = [[NSString alloc] initWithFormat:@"%llu", tid];
        } else {
            _threadID = [[NSString alloc] initWithFormat:@"%x", pthread_mach_thread_np(pthread_self())];
        }
        _threadName   = NSThread.currentThread.name;

        // Get the file name without extension
        _fileName = [_file lastPathComponent];
        NSUInteger dotLocation = [_fileName rangeOfString:@"." options:NSBackwardsSearch].location;
        if (dotLocation != NSNotFound)
        {
            _fileName = [_fileName substringToIndex:dotLocation];
        }
        
        // Try to get the current queue's label
        if (USE_DISPATCH_CURRENT_QUEUE_LABEL) {
            _queueLabel = [[NSString alloc] initWithFormat:@"%s", dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)];
        } else if (USE_DISPATCH_GET_CURRENT_QUEUE) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            dispatch_queue_t currentQueue = dispatch_get_current_queue();
            #pragma clang diagnostic pop
            _queueLabel = [[NSString alloc] initWithFormat:@"%s", dispatch_queue_get_label(currentQueue)];
        } else {
            _queueLabel = @""; // iOS 6.x only
        }
    }
    return self;
}

- (id)copyWithZone:(NSZone * __attribute__((unused)))zone {
    DDLogMessage *newMessage = [DDLogMessage new];
    
    newMessage->_message = _message;
    newMessage->_level = _level;
    newMessage->_flag = _flag;
    newMessage->_context = _context;
    newMessage->_file = _file;
    newMessage->_fileName = _fileName;
    newMessage->_function = _function;
    newMessage->_line = _line;
    newMessage->_tag = _tag;
    newMessage->_options = _options;
    newMessage->_timestamp = _timestamp;
    newMessage->_threadID = _threadID;
    newMessage->_threadName = _threadName;
    newMessage->_queueLabel = _queueLabel;

    return newMessage;
}

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation DDAbstractLogger

- (instancetype)init {
    if ((self = [super init])) {
        const char *loggerQueueName = NULL;

        if ([self respondsToSelector:@selector(loggerName)]) {
            loggerQueueName = [[self loggerName] UTF8String];
        }

        _loggerQueue = dispatch_queue_create(loggerQueueName, NULL);

        // We're going to use dispatch_queue_set_specific() to "mark" our loggerQueue.
        // Later we can use dispatch_get_specific() to determine if we're executing on our loggerQueue.
        // The documentation states:
        //
        // > Keys are only compared as pointers and are never dereferenced.
        // > Thus, you can use a pointer to a static variable for a specific subsystem or
        // > any other value that allows you to identify the value uniquely.
        // > Specifying a pointer to a string constant is not recommended.
        //
        // So we're going to use the very convenient key of "self",
        // which also works when multiple logger classes extend this class, as each will have a different "self" key.
        //
        // This is used primarily for thread-safety assertions (via the isOnInternalLoggerQueue method below).

        void *key = (__bridge void *)self;
        void *nonNullValue = (__bridge void *)self;

        dispatch_queue_set_specific(_loggerQueue, key, nonNullValue, NULL);
    }

    return self;
}

- (void)dealloc {
    #if !OS_OBJECT_USE_OBJC

    if (_loggerQueue) {
        dispatch_release(_loggerQueue);
    }

    #endif
}

- (void)logMessage:(DDLogMessage * __attribute__((unused)))logMessage {
    // Override me
}

- (id <DDLogFormatter>)logFormatter {
    // This method must be thread safe and intuitive.
    // Therefore if somebody executes the following code:
    //
    // [logger setLogFormatter:myFormatter];
    // formatter = [logger logFormatter];
    //
    // They would expect formatter to equal myFormatter.
    // This functionality must be ensured by the getter and setter method.
    //
    // The thread safety must not come at a cost to the performance of the logMessage method.
    // This method is likely called sporadically, while the logMessage method is called repeatedly.
    // This means, the implementation of this method:
    // - Must NOT require the logMessage method to acquire a lock.
    // - Must NOT require the logMessage method to access an atomic property (also a lock of sorts).
    //
    // Thread safety is ensured by executing access to the formatter variable on the loggerQueue.
    // This is the same queue that the logMessage method operates on.
    //
    // Note: The last time I benchmarked the performance of direct access vs atomic property access,
    // direct access was over twice as fast on the desktop and over 6 times as fast on the iPhone.
    //
    // Furthermore, consider the following code:
    //
    // DDLogVerbose(@"log msg 1");
    // DDLogVerbose(@"log msg 2");
    // [logger setFormatter:myFormatter];
    // DDLogVerbose(@"log msg 3");
    //
    // Our intuitive requirement means that the new formatter will only apply to the 3rd log message.
    // This must remain true even when using asynchronous logging.
    // We must keep in mind the various queue's that are in play here:
    //
    // loggerQueue : Our own private internal queue that the logMessage method runs on.
    //               Operations are added to this queue from the global loggingQueue.
    //
    // globalLoggingQueue : The queue that all log messages go through before they arrive in our loggerQueue.
    //
    // All log statements go through the serial gloabalLoggingQueue before they arrive at our loggerQueue.
    // Thus this method also goes through the serial globalLoggingQueue to ensure intuitive operation.

    // IMPORTANT NOTE:
    //
    // Methods within the DDLogger implementation MUST access the formatter ivar directly.
    // This method is designed explicitly for external access.
    //
    // Using "self." syntax to go through this method will cause immediate deadlock.
    // This is the intended result. Fix it by accessing the ivar directly.
    // Great strides have been take to ensure this is safe to do. Plus it's MUCH faster.

    NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");
    NSAssert(![self isOnInternalLoggerQueue], @"MUST access ivar directly, NOT via self.* syntax.");

    dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];

    __block id <DDLogFormatter> result;

    dispatch_sync(globalLoggingQueue, ^{
        dispatch_sync(_loggerQueue, ^{
            result = _logFormatter;
        });
    });

    return result;
}

- (void)setLogFormatter:(id <DDLogFormatter>)logFormatter {
    // The design of this method is documented extensively in the logFormatter message (above in code).

    NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");
    NSAssert(![self isOnInternalLoggerQueue], @"MUST access ivar directly, NOT via self.* syntax.");

    dispatch_block_t block = ^{
        @autoreleasepool {
            if (_logFormatter != logFormatter) {
                if ([_logFormatter respondsToSelector:@selector(willRemoveFromLogger:)]) {
                    [_logFormatter willRemoveFromLogger:self];
                }

                _logFormatter = logFormatter;

                if ([_logFormatter respondsToSelector:@selector(didAddToLogger:)]) {
                    [_logFormatter didAddToLogger:self];
                }
            }
        }
    };

    dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];

    dispatch_async(globalLoggingQueue, ^{
        dispatch_async(_loggerQueue, block);
    });
}

- (dispatch_queue_t)loggerQueue {
    return _loggerQueue;
}

- (NSString *)loggerName {
    return NSStringFromClass([self class]);
}

- (BOOL)isOnGlobalLoggingQueue {
    return (dispatch_get_specific(GlobalLoggingQueueIdentityKey) != NULL);
}

- (BOOL)isOnInternalLoggerQueue {
    void *key = (__bridge void *)self;

    return (dispatch_get_specific(key) != NULL);
}

@end
// Software License Agreement (BSD License)
//
// Copyright (c) 2010-2016, Deusty, LLC
// All rights reserved.
//
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Neither the name of Deusty nor the names of its contributors may be used
//   to endorse or promote products derived from this software without specific
//   prior written permission of Deusty, LLC.

#import <unistd.h>
#import <sys/uio.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

// We probably shouldn't be using DDLog() statements within the DDLog implementation.
// But we still want to leave our log statements for any future debugging,
// and to allow other developers to trace the implementation (which is a great learning tool).
//
// So we use primitive logging macros around NSLog.
// We maintain the NS prefix on the macros to be explicit about the fact that we're using NSLog.

#ifndef DD_NSLOG_LEVEL
    #define DD_NSLOG_LEVEL 2
#endif

#define NSLogError(frmt, ...)    do{ if(DD_NSLOG_LEVEL >= 1) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogWarn(frmt, ...)     do{ if(DD_NSLOG_LEVEL >= 2) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogInfo(frmt, ...)     do{ if(DD_NSLOG_LEVEL >= 3) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogDebug(frmt, ...)    do{ if(DD_NSLOG_LEVEL >= 4) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogVerbose(frmt, ...)  do{ if(DD_NSLOG_LEVEL >= 5) NSLog((frmt), ##__VA_ARGS__); } while(0)

// Xcode does NOT natively support colors in the Xcode debugging console.
// You'll need to install the XcodeColors plugin to see colors in the Xcode console.
// https://github.com/robbiehanson/XcodeColors
//
// The following is documentation from the XcodeColors project:
//
//
// How to apply color formatting to your log statements:
//
// To set the foreground color:
// Insert the ESCAPE_SEQ into your string, followed by "fg124,12,255;" where r=124, g=12, b=255.
//
// To set the background color:
// Insert the ESCAPE_SEQ into your string, followed by "bg12,24,36;" where r=12, g=24, b=36.
//
// To reset the foreground color (to default value):
// Insert the ESCAPE_SEQ into your string, followed by "fg;"
//
// To reset the background color (to default value):
// Insert the ESCAPE_SEQ into your string, followed by "bg;"
//
// To reset the foreground and background color (to default values) in one operation:
// Insert the ESCAPE_SEQ into your string, followed by ";"

#define XCODE_COLORS_ESCAPE_SEQ "\033["

#define XCODE_COLORS_RESET_FG   XCODE_COLORS_ESCAPE_SEQ "fg;" // Clear any foreground color
#define XCODE_COLORS_RESET_BG   XCODE_COLORS_ESCAPE_SEQ "bg;" // Clear any background color
#define XCODE_COLORS_RESET      XCODE_COLORS_ESCAPE_SEQ ";"  // Clear any foreground or background color

// If running in a shell, not all RGB colors will be supported.
// In this case we automatically map to the closest available color.
// In order to provide this mapping, we have a hard-coded set of the standard RGB values available in the shell.
// However, not every shell is the same, and Apple likes to think different even when it comes to shell colors.
//
// Map to standard Terminal.app colors (1), or
// map to standard xterm colors (0).

#define MAP_TO_TERMINAL_APP_COLORS 1


@interface DDTTYLoggerColorProfile : NSObject {
    @public
    DDLogFlag mask;
    NSInteger context;

    uint8_t fg_r;
    uint8_t fg_g;
    uint8_t fg_b;

    uint8_t bg_r;
    uint8_t bg_g;
    uint8_t bg_b;

    NSUInteger fgCodeIndex;
    NSString *fgCodeRaw;

    NSUInteger bgCodeIndex;
    NSString *bgCodeRaw;

    char fgCode[24];
    size_t fgCodeLen;

    char bgCode[24];
    size_t bgCodeLen;

    char resetCode[8];
    size_t resetCodeLen;
}

- (instancetype)initWithForegroundColor:(DDColor *)fgColor backgroundColor:(DDColor *)bgColor flag:(DDLogFlag)mask context:(NSInteger)ctxt;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface DDTTYLogger () {
    NSUInteger _calendarUnitFlags;
    
    NSString *_appName;
    char *_app;
    size_t _appLen;
    
    NSString *_processID;
    char *_pid;
    size_t _pidLen;
    
    BOOL _colorsEnabled;
    NSMutableArray *_colorProfilesArray;
    NSMutableDictionary *_colorProfilesDict;
}

@end


@implementation DDTTYLogger

static BOOL isaColorTTY;
static BOOL isaColor256TTY;
static BOOL isaXcodeColorTTY;

static NSArray *codes_fg = nil;
static NSArray *codes_bg = nil;
static NSArray *colors   = nil;

static DDTTYLogger *ttySharedInstance;

/**
 * Initializes the colors array, as well as the codes_fg and codes_bg arrays, for 16 color mode.
 *
 * This method is used when the application is running from within a shell that only supports 16 color mode.
 * This method is not invoked if the application is running within Xcode, or via normal UI app launch.
 **/
+ (void)initialize_colors_16 {
    if (codes_fg || codes_bg || colors) {
        return;
    }

    NSMutableArray *m_codes_fg = [NSMutableArray arrayWithCapacity:16];
    NSMutableArray *m_codes_bg = [NSMutableArray arrayWithCapacity:16];
    NSMutableArray *m_colors   = [NSMutableArray arrayWithCapacity:16];

    // In a standard shell only 16 colors are supported.
    //
    // More information about ansi escape codes can be found online.
    // http://en.wikipedia.org/wiki/ANSI_escape_code

    [m_codes_fg addObject:@"30m"];   // normal - black
    [m_codes_fg addObject:@"31m"];   // normal - red
    [m_codes_fg addObject:@"32m"];   // normal - green
    [m_codes_fg addObject:@"33m"];   // normal - yellow
    [m_codes_fg addObject:@"34m"];   // normal - blue
    [m_codes_fg addObject:@"35m"];   // normal - magenta
    [m_codes_fg addObject:@"36m"];   // normal - cyan
    [m_codes_fg addObject:@"37m"];   // normal - gray
    [m_codes_fg addObject:@"1;30m"]; // bright - darkgray
    [m_codes_fg addObject:@"1;31m"]; // bright - red
    [m_codes_fg addObject:@"1;32m"]; // bright - green
    [m_codes_fg addObject:@"1;33m"]; // bright - yellow
    [m_codes_fg addObject:@"1;34m"]; // bright - blue
    [m_codes_fg addObject:@"1;35m"]; // bright - magenta
    [m_codes_fg addObject:@"1;36m"]; // bright - cyan
    [m_codes_fg addObject:@"1;37m"]; // bright - white

    [m_codes_bg addObject:@"40m"];   // normal - black
    [m_codes_bg addObject:@"41m"];   // normal - red
    [m_codes_bg addObject:@"42m"];   // normal - green
    [m_codes_bg addObject:@"43m"];   // normal - yellow
    [m_codes_bg addObject:@"44m"];   // normal - blue
    [m_codes_bg addObject:@"45m"];   // normal - magenta
    [m_codes_bg addObject:@"46m"];   // normal - cyan
    [m_codes_bg addObject:@"47m"];   // normal - gray
    [m_codes_bg addObject:@"1;40m"]; // bright - darkgray
    [m_codes_bg addObject:@"1;41m"]; // bright - red
    [m_codes_bg addObject:@"1;42m"]; // bright - green
    [m_codes_bg addObject:@"1;43m"]; // bright - yellow
    [m_codes_bg addObject:@"1;44m"]; // bright - blue
    [m_codes_bg addObject:@"1;45m"]; // bright - magenta
    [m_codes_bg addObject:@"1;46m"]; // bright - cyan
    [m_codes_bg addObject:@"1;47m"]; // bright - white

#if MAP_TO_TERMINAL_APP_COLORS

    // Standard Terminal.app colors:
    //
    // These are the default colors used by Apple's Terminal.app.

    [m_colors addObject:DDMakeColor(  0,   0,   0)]; // normal - black
    [m_colors addObject:DDMakeColor(194,  54,  33)]; // normal - red
    [m_colors addObject:DDMakeColor( 37, 188,  36)]; // normal - green
    [m_colors addObject:DDMakeColor(173, 173,  39)]; // normal - yellow
    [m_colors addObject:DDMakeColor( 73,  46, 225)]; // normal - blue
    [m_colors addObject:DDMakeColor(211,  56, 211)]; // normal - magenta
    [m_colors addObject:DDMakeColor( 51, 187, 200)]; // normal - cyan
    [m_colors addObject:DDMakeColor(203, 204, 205)]; // normal - gray
    [m_colors addObject:DDMakeColor(129, 131, 131)]; // bright - darkgray
    [m_colors addObject:DDMakeColor(252,  57,  31)]; // bright - red
    [m_colors addObject:DDMakeColor( 49, 231,  34)]; // bright - green
    [m_colors addObject:DDMakeColor(234, 236,  35)]; // bright - yellow
    [m_colors addObject:DDMakeColor( 88,  51, 255)]; // bright - blue
    [m_colors addObject:DDMakeColor(249,  53, 248)]; // bright - magenta
    [m_colors addObject:DDMakeColor( 20, 240, 240)]; // bright - cyan
    [m_colors addObject:DDMakeColor(233, 235, 235)]; // bright - white

#else /* if MAP_TO_TERMINAL_APP_COLORS */

    // Standard xterm colors:
    //
    // These are the default colors used by most xterm shells.

    [m_colors addObject:DDMakeColor(  0,   0,   0)]; // normal - black
    [m_colors addObject:DDMakeColor(205,   0,   0)]; // normal - red
    [m_colors addObject:DDMakeColor(  0, 205,   0)]; // normal - green
    [m_colors addObject:DDMakeColor(205, 205,   0)]; // normal - yellow
    [m_colors addObject:DDMakeColor(  0,   0, 238)]; // normal - blue
    [m_colors addObject:DDMakeColor(205,   0, 205)]; // normal - magenta
    [m_colors addObject:DDMakeColor(  0, 205, 205)]; // normal - cyan
    [m_colors addObject:DDMakeColor(229, 229, 229)]; // normal - gray
    [m_colors addObject:DDMakeColor(127, 127, 127)]; // bright - darkgray
    [m_colors addObject:DDMakeColor(255,   0,   0)]; // bright - red
    [m_colors addObject:DDMakeColor(  0, 255,   0)]; // bright - green
    [m_colors addObject:DDMakeColor(255, 255,   0)]; // bright - yellow
    [m_colors addObject:DDMakeColor( 92,  92, 255)]; // bright - blue
    [m_colors addObject:DDMakeColor(255,   0, 255)]; // bright - magenta
    [m_colors addObject:DDMakeColor(  0, 255, 255)]; // bright - cyan
    [m_colors addObject:DDMakeColor(255, 255, 255)]; // bright - white

#endif /* if MAP_TO_TERMINAL_APP_COLORS */

    codes_fg = [m_codes_fg copy];
    codes_bg = [m_codes_bg copy];
    colors   = [m_colors   copy];

    NSAssert([codes_fg count] == [codes_bg count], @"Invalid colors/codes array(s)");
    NSAssert([codes_fg count] == [colors count],   @"Invalid colors/codes array(s)");
}

/**
 * Initializes the colors array, as well as the codes_fg and codes_bg arrays, for 256 color mode.
 *
 * This method is used when the application is running from within a shell that supports 256 color mode.
 * This method is not invoked if the application is running within Xcode, or via normal UI app launch.
 **/
+ (void)initialize_colors_256 {
    if (codes_fg || codes_bg || colors) {
        return;
    }

    NSMutableArray *m_codes_fg = [NSMutableArray arrayWithCapacity:(256 - 16)];
    NSMutableArray *m_codes_bg = [NSMutableArray arrayWithCapacity:(256 - 16)];
    NSMutableArray *m_colors   = [NSMutableArray arrayWithCapacity:(256 - 16)];

    #if MAP_TO_TERMINAL_APP_COLORS

    // Standard Terminal.app colors:
    //
    // These are the colors the Terminal.app uses in xterm-256color mode.
    // In this mode, the terminal supports 256 different colors, specified by 256 color codes.
    //
    // The first 16 color codes map to the original 16 color codes supported by the earlier xterm-color mode.
    // These are actually configurable, and thus we ignore them for the purposes of mapping,
    // as we can't rely on them being constant. They are largely duplicated anyway.
    //
    // The next 216 color codes are designed to run the spectrum, with several shades of every color.
    // While the color codes are standardized, the actual RGB values for each color code is not.
    // Apple's Terminal.app uses different RGB values from that of a standard xterm.
    // Apple's choices in colors are designed to be a little nicer on the eyes.
    //
    // The last 24 color codes represent a grayscale.
    //
    // Unfortunately, unlike the standard xterm color chart,
    // Apple's RGB values cannot be calculated using a simple formula (at least not that I know of).
    // Also, I don't know of any ways to programmatically query the shell for the RGB values.
    // So this big giant color chart had to be made by hand.
    //
    // More information about ansi escape codes can be found online.
    // http://en.wikipedia.org/wiki/ANSI_escape_code

    // Colors

    [m_colors addObject:DDMakeColor( 47,  49,  49)];
    [m_colors addObject:DDMakeColor( 60,  42, 144)];
    [m_colors addObject:DDMakeColor( 66,  44, 183)];
    [m_colors addObject:DDMakeColor( 73,  46, 222)];
    [m_colors addObject:DDMakeColor( 81,  50, 253)];
    [m_colors addObject:DDMakeColor( 88,  51, 255)];
    
    [m_colors addObject:DDMakeColor( 42, 128,  37)];
    [m_colors addObject:DDMakeColor( 42, 127, 128)];
    [m_colors addObject:DDMakeColor( 44, 126, 169)];
    [m_colors addObject:DDMakeColor( 56, 125, 209)];
    [m_colors addObject:DDMakeColor( 59, 124, 245)];
    [m_colors addObject:DDMakeColor( 66, 123, 255)];
    
    [m_colors addObject:DDMakeColor( 51, 163,  41)];
    [m_colors addObject:DDMakeColor( 39, 162, 121)];
    [m_colors addObject:DDMakeColor( 42, 161, 162)];
    [m_colors addObject:DDMakeColor( 53, 160, 202)];
    [m_colors addObject:DDMakeColor( 45, 159, 240)];
    [m_colors addObject:DDMakeColor( 58, 158, 255)];
    
    [m_colors addObject:DDMakeColor( 31, 196,  37)];
    [m_colors addObject:DDMakeColor( 48, 196, 115)];
    [m_colors addObject:DDMakeColor( 39, 195, 155)];
    [m_colors addObject:DDMakeColor( 49, 195, 195)];
    [m_colors addObject:DDMakeColor( 32, 194, 235)];
    [m_colors addObject:DDMakeColor( 53, 193, 255)];
    
    [m_colors addObject:DDMakeColor( 50, 229,  35)];
    [m_colors addObject:DDMakeColor( 40, 229, 109)];
    [m_colors addObject:DDMakeColor( 27, 229, 149)];
    [m_colors addObject:DDMakeColor( 49, 228, 189)];
    [m_colors addObject:DDMakeColor( 33, 228, 228)];
    [m_colors addObject:DDMakeColor( 53, 227, 255)];
    
    [m_colors addObject:DDMakeColor( 27, 254,  30)];
    [m_colors addObject:DDMakeColor( 30, 254, 103)];
    [m_colors addObject:DDMakeColor( 45, 254, 143)];
    [m_colors addObject:DDMakeColor( 38, 253, 182)];
    [m_colors addObject:DDMakeColor( 38, 253, 222)];
    [m_colors addObject:DDMakeColor( 42, 253, 252)];
    
    [m_colors addObject:DDMakeColor(140,  48,  40)];
    [m_colors addObject:DDMakeColor(136,  51, 136)];
    [m_colors addObject:DDMakeColor(135,  52, 177)];
    [m_colors addObject:DDMakeColor(134,  52, 217)];
    [m_colors addObject:DDMakeColor(135,  56, 248)];
    [m_colors addObject:DDMakeColor(134,  53, 255)];
    
    [m_colors addObject:DDMakeColor(125, 125,  38)];
    [m_colors addObject:DDMakeColor(124, 125, 125)];
    [m_colors addObject:DDMakeColor(122, 124, 166)];
    [m_colors addObject:DDMakeColor(123, 124, 207)];
    [m_colors addObject:DDMakeColor(123, 122, 247)];
    [m_colors addObject:DDMakeColor(124, 121, 255)];
    
    [m_colors addObject:DDMakeColor(119, 160,  35)];
    [m_colors addObject:DDMakeColor(117, 160, 120)];
    [m_colors addObject:DDMakeColor(117, 160, 160)];
    [m_colors addObject:DDMakeColor(115, 159, 201)];
    [m_colors addObject:DDMakeColor(116, 158, 240)];
    [m_colors addObject:DDMakeColor(117, 157, 255)];
    
    [m_colors addObject:DDMakeColor(113, 195,  39)];
    [m_colors addObject:DDMakeColor(110, 194, 114)];
    [m_colors addObject:DDMakeColor(111, 194, 154)];
    [m_colors addObject:DDMakeColor(108, 194, 194)];
    [m_colors addObject:DDMakeColor(109, 193, 234)];
    [m_colors addObject:DDMakeColor(108, 192, 255)];
    
    [m_colors addObject:DDMakeColor(105, 228,  30)];
    [m_colors addObject:DDMakeColor(103, 228, 109)];
    [m_colors addObject:DDMakeColor(105, 228, 148)];
    [m_colors addObject:DDMakeColor(100, 227, 188)];
    [m_colors addObject:DDMakeColor( 99, 227, 227)];
    [m_colors addObject:DDMakeColor( 99, 226, 253)];
    
    [m_colors addObject:DDMakeColor( 92, 253,  34)];
    [m_colors addObject:DDMakeColor( 96, 253, 103)];
    [m_colors addObject:DDMakeColor( 97, 253, 142)];
    [m_colors addObject:DDMakeColor( 88, 253, 182)];
    [m_colors addObject:DDMakeColor( 93, 253, 221)];
    [m_colors addObject:DDMakeColor( 88, 254, 251)];
    
    [m_colors addObject:DDMakeColor(177,  53,  34)];
    [m_colors addObject:DDMakeColor(174,  54, 131)];
    [m_colors addObject:DDMakeColor(172,  55, 172)];
    [m_colors addObject:DDMakeColor(171,  57, 213)];
    [m_colors addObject:DDMakeColor(170,  55, 249)];
    [m_colors addObject:DDMakeColor(170,  57, 255)];
    
    [m_colors addObject:DDMakeColor(165, 123,  37)];
    [m_colors addObject:DDMakeColor(163, 123, 123)];
    [m_colors addObject:DDMakeColor(162, 123, 164)];
    [m_colors addObject:DDMakeColor(161, 122, 205)];
    [m_colors addObject:DDMakeColor(161, 121, 241)];
    [m_colors addObject:DDMakeColor(161, 121, 255)];
    
    [m_colors addObject:DDMakeColor(158, 159,  33)];
    [m_colors addObject:DDMakeColor(157, 158, 118)];
    [m_colors addObject:DDMakeColor(157, 158, 159)];
    [m_colors addObject:DDMakeColor(155, 157, 199)];
    [m_colors addObject:DDMakeColor(155, 157, 239)];
    [m_colors addObject:DDMakeColor(154, 156, 255)];
    
    [m_colors addObject:DDMakeColor(152, 193,  40)];
    [m_colors addObject:DDMakeColor(151, 193, 113)];
    [m_colors addObject:DDMakeColor(150, 193, 153)];
    [m_colors addObject:DDMakeColor(150, 192, 193)];
    [m_colors addObject:DDMakeColor(148, 192, 232)];
    [m_colors addObject:DDMakeColor(149, 191, 253)];
    
    [m_colors addObject:DDMakeColor(146, 227,  28)];
    [m_colors addObject:DDMakeColor(144, 227, 108)];
    [m_colors addObject:DDMakeColor(144, 227, 147)];
    [m_colors addObject:DDMakeColor(144, 227, 187)];
    [m_colors addObject:DDMakeColor(142, 226, 227)];
    [m_colors addObject:DDMakeColor(142, 225, 252)];
    
    [m_colors addObject:DDMakeColor(138, 253,  36)];
    [m_colors addObject:DDMakeColor(137, 253, 102)];
    [m_colors addObject:DDMakeColor(136, 253, 141)];
    [m_colors addObject:DDMakeColor(138, 254, 181)];
    [m_colors addObject:DDMakeColor(135, 255, 220)];
    [m_colors addObject:DDMakeColor(133, 255, 250)];
    
    [m_colors addObject:DDMakeColor(214,  57,  30)];
    [m_colors addObject:DDMakeColor(211,  59, 126)];
    [m_colors addObject:DDMakeColor(209,  57, 168)];
    [m_colors addObject:DDMakeColor(208,  55, 208)];
    [m_colors addObject:DDMakeColor(207,  58, 247)];
    [m_colors addObject:DDMakeColor(206,  61, 255)];
    
    [m_colors addObject:DDMakeColor(204, 121,  32)];
    [m_colors addObject:DDMakeColor(202, 121, 121)];
    [m_colors addObject:DDMakeColor(201, 121, 161)];
    [m_colors addObject:DDMakeColor(200, 120, 202)];
    [m_colors addObject:DDMakeColor(200, 120, 241)];
    [m_colors addObject:DDMakeColor(198, 119, 255)];
    
    [m_colors addObject:DDMakeColor(198, 157,  37)];
    [m_colors addObject:DDMakeColor(196, 157, 116)];
    [m_colors addObject:DDMakeColor(195, 156, 157)];
    [m_colors addObject:DDMakeColor(195, 156, 197)];
    [m_colors addObject:DDMakeColor(194, 155, 236)];
    [m_colors addObject:DDMakeColor(193, 155, 255)];
    
    [m_colors addObject:DDMakeColor(191, 192,  36)];
    [m_colors addObject:DDMakeColor(190, 191, 112)];
    [m_colors addObject:DDMakeColor(189, 191, 152)];
    [m_colors addObject:DDMakeColor(189, 191, 191)];
    [m_colors addObject:DDMakeColor(188, 190, 230)];
    [m_colors addObject:DDMakeColor(187, 190, 253)];
    
    [m_colors addObject:DDMakeColor(185, 226,  28)];
    [m_colors addObject:DDMakeColor(184, 226, 106)];
    [m_colors addObject:DDMakeColor(183, 225, 146)];
    [m_colors addObject:DDMakeColor(183, 225, 186)];
    [m_colors addObject:DDMakeColor(182, 225, 225)];
    [m_colors addObject:DDMakeColor(181, 224, 252)];
    
    [m_colors addObject:DDMakeColor(178, 255,  35)];
    [m_colors addObject:DDMakeColor(178, 255, 101)];
    [m_colors addObject:DDMakeColor(177, 254, 141)];
    [m_colors addObject:DDMakeColor(176, 254, 180)];
    [m_colors addObject:DDMakeColor(176, 254, 220)];
    [m_colors addObject:DDMakeColor(175, 253, 249)];
    
    [m_colors addObject:DDMakeColor(247,  56,  30)];
    [m_colors addObject:DDMakeColor(245,  57, 122)];
    [m_colors addObject:DDMakeColor(243,  59, 163)];
    [m_colors addObject:DDMakeColor(244,  60, 204)];
    [m_colors addObject:DDMakeColor(242,  59, 241)];
    [m_colors addObject:DDMakeColor(240,  55, 255)];
    
    [m_colors addObject:DDMakeColor(241, 119,  36)];
    [m_colors addObject:DDMakeColor(240, 120, 118)];
    [m_colors addObject:DDMakeColor(238, 119, 158)];
    [m_colors addObject:DDMakeColor(237, 119, 199)];
    [m_colors addObject:DDMakeColor(237, 118, 238)];
    [m_colors addObject:DDMakeColor(236, 118, 255)];
    
    [m_colors addObject:DDMakeColor(235, 154,  36)];
    [m_colors addObject:DDMakeColor(235, 154, 114)];
    [m_colors addObject:DDMakeColor(234, 154, 154)];
    [m_colors addObject:DDMakeColor(232, 154, 194)];
    [m_colors addObject:DDMakeColor(232, 153, 234)];
    [m_colors addObject:DDMakeColor(232, 153, 255)];
    
    [m_colors addObject:DDMakeColor(230, 190,  30)];
    [m_colors addObject:DDMakeColor(229, 189, 110)];
    [m_colors addObject:DDMakeColor(228, 189, 150)];
    [m_colors addObject:DDMakeColor(227, 189, 190)];
    [m_colors addObject:DDMakeColor(227, 189, 229)];
    [m_colors addObject:DDMakeColor(226, 188, 255)];
    
    [m_colors addObject:DDMakeColor(224, 224,  35)];
    [m_colors addObject:DDMakeColor(223, 224, 105)];
    [m_colors addObject:DDMakeColor(222, 224, 144)];
    [m_colors addObject:DDMakeColor(222, 223, 184)];
    [m_colors addObject:DDMakeColor(222, 223, 224)];
    [m_colors addObject:DDMakeColor(220, 223, 253)];
    
    [m_colors addObject:DDMakeColor(217, 253,  28)];
    [m_colors addObject:DDMakeColor(217, 253,  99)];
    [m_colors addObject:DDMakeColor(216, 252, 139)];
    [m_colors addObject:DDMakeColor(216, 252, 179)];
    [m_colors addObject:DDMakeColor(215, 252, 218)];
    [m_colors addObject:DDMakeColor(215, 251, 250)];
    
    [m_colors addObject:DDMakeColor(255,  61,  30)];
    [m_colors addObject:DDMakeColor(255,  60, 118)];
    [m_colors addObject:DDMakeColor(255,  58, 159)];
    [m_colors addObject:DDMakeColor(255,  56, 199)];
    [m_colors addObject:DDMakeColor(255,  55, 238)];
    [m_colors addObject:DDMakeColor(255,  59, 255)];
    
    [m_colors addObject:DDMakeColor(255, 117,  29)];
    [m_colors addObject:DDMakeColor(255, 117, 115)];
    [m_colors addObject:DDMakeColor(255, 117, 155)];
    [m_colors addObject:DDMakeColor(255, 117, 195)];
    [m_colors addObject:DDMakeColor(255, 116, 235)];
    [m_colors addObject:DDMakeColor(254, 116, 255)];
    
    [m_colors addObject:DDMakeColor(255, 152,  27)];
    [m_colors addObject:DDMakeColor(255, 152, 111)];
    [m_colors addObject:DDMakeColor(254, 152, 152)];
    [m_colors addObject:DDMakeColor(255, 152, 192)];
    [m_colors addObject:DDMakeColor(254, 151, 231)];
    [m_colors addObject:DDMakeColor(253, 151, 253)];
    
    [m_colors addObject:DDMakeColor(255, 187,  33)];
    [m_colors addObject:DDMakeColor(253, 187, 107)];
    [m_colors addObject:DDMakeColor(252, 187, 148)];
    [m_colors addObject:DDMakeColor(253, 187, 187)];
    [m_colors addObject:DDMakeColor(254, 187, 227)];
    [m_colors addObject:DDMakeColor(252, 186, 252)];
    
    [m_colors addObject:DDMakeColor(252, 222,  34)];
    [m_colors addObject:DDMakeColor(251, 222, 103)];
    [m_colors addObject:DDMakeColor(251, 222, 143)];
    [m_colors addObject:DDMakeColor(250, 222, 182)];
    [m_colors addObject:DDMakeColor(251, 221, 222)];
    [m_colors addObject:DDMakeColor(252, 221, 252)];
    
    [m_colors addObject:DDMakeColor(251, 252,  15)];
    [m_colors addObject:DDMakeColor(251, 252,  97)];
    [m_colors addObject:DDMakeColor(249, 252, 137)];
    [m_colors addObject:DDMakeColor(247, 252, 177)];
    [m_colors addObject:DDMakeColor(247, 253, 217)];
    [m_colors addObject:DDMakeColor(254, 255, 255)];
    
    // Grayscale
    
    [m_colors addObject:DDMakeColor( 52,  53,  53)];
    [m_colors addObject:DDMakeColor( 57,  58,  59)];
    [m_colors addObject:DDMakeColor( 66,  67,  67)];
    [m_colors addObject:DDMakeColor( 75,  76,  76)];
    [m_colors addObject:DDMakeColor( 83,  85,  85)];
    [m_colors addObject:DDMakeColor( 92,  93,  94)];
    
    [m_colors addObject:DDMakeColor(101, 102, 102)];
    [m_colors addObject:DDMakeColor(109, 111, 111)];
    [m_colors addObject:DDMakeColor(118, 119, 119)];
    [m_colors addObject:DDMakeColor(126, 127, 128)];
    [m_colors addObject:DDMakeColor(134, 136, 136)];
    [m_colors addObject:DDMakeColor(143, 144, 145)];
    
    [m_colors addObject:DDMakeColor(151, 152, 153)];
    [m_colors addObject:DDMakeColor(159, 161, 161)];
    [m_colors addObject:DDMakeColor(167, 169, 169)];
    [m_colors addObject:DDMakeColor(176, 177, 177)];
    [m_colors addObject:DDMakeColor(184, 185, 186)];
    [m_colors addObject:DDMakeColor(192, 193, 194)];
    
    [m_colors addObject:DDMakeColor(200, 201, 202)];
    [m_colors addObject:DDMakeColor(208, 209, 210)];
    [m_colors addObject:DDMakeColor(216, 218, 218)];
    [m_colors addObject:DDMakeColor(224, 226, 226)];
    [m_colors addObject:DDMakeColor(232, 234, 234)];
    [m_colors addObject:DDMakeColor(240, 242, 242)];
    
    // Color codes

    int index = 16;

    while (index < 256) {
        [m_codes_fg addObject:[NSString stringWithFormat:@"38;5;%dm", index]];
        [m_codes_bg addObject:[NSString stringWithFormat:@"48;5;%dm", index]];

        index++;
    }

    #else /* if MAP_TO_TERMINAL_APP_COLORS */

    // Standard xterm colors:
    //
    // These are the colors xterm shells use in xterm-256color mode.
    // In this mode, the shell supports 256 different colors, specified by 256 color codes.
    //
    // The first 16 color codes map to the original 16 color codes supported by the earlier xterm-color mode.
    // These are generally configurable, and thus we ignore them for the purposes of mapping,
    // as we can't rely on them being constant. They are largely duplicated anyway.
    //
    // The next 216 color codes are designed to run the spectrum, with several shades of every color.
    // The last 24 color codes represent a grayscale.
    //
    // While the color codes are standardized, the actual RGB values for each color code is not.
    // However most standard xterms follow a well known color chart,
    // which can easily be calculated using the simple formula below.
    //
    // More information about ansi escape codes can be found online.
    // http://en.wikipedia.org/wiki/ANSI_escape_code

    int index = 16;

    int r; // red
    int g; // green
    int b; // blue

    int ri; // r increment
    int gi; // g increment
    int bi; // b increment

    // Calculate xterm colors (using standard algorithm)

    int r = 0;
    int g = 0;
    int b = 0;

    for (ri = 0; ri < 6; ri++) {
        r = (ri == 0) ? 0 : 95 + (40 * (ri - 1));

        for (gi = 0; gi < 6; gi++) {
            g = (gi == 0) ? 0 : 95 + (40 * (gi - 1));

            for (bi = 0; bi < 6; bi++) {
                b = (bi == 0) ? 0 : 95 + (40 * (bi - 1));

                [m_codes_fg addObject:[NSString stringWithFormat:@"38;5;%dm", index]];
                [m_codes_bg addObject:[NSString stringWithFormat:@"48;5;%dm", index]];
                [m_colors addObject:DDMakeColor(r, g, b)];

                index++;
            }
        }
    }

    // Calculate xterm grayscale (using standard algorithm)

    r = 8;
    g = 8;
    b = 8;

    while (index < 256) {
        [m_codes_fg addObject:[NSString stringWithFormat:@"38;5;%dm", index]];
        [m_codes_bg addObject:[NSString stringWithFormat:@"48;5;%dm", index]];
        [m_colors addObject:DDMakeColor(r, g, b)];

        r += 10;
        g += 10;
        b += 10;

        index++;
    }

    #endif /* if MAP_TO_TERMINAL_APP_COLORS */

    codes_fg = [m_codes_fg copy];
    codes_bg = [m_codes_bg copy];
    colors   = [m_colors   copy];

    NSAssert([codes_fg count] == [codes_bg count], @"Invalid colors/codes array(s)");
    NSAssert([codes_fg count] == [colors count],   @"Invalid colors/codes array(s)");
}

+ (void)getRed:(CGFloat *)rPtr green:(CGFloat *)gPtr blue:(CGFloat *)bPtr fromColor:(DDColor *)color {
    #if TARGET_OS_IPHONE

    // iOS

    BOOL done = NO;

    if ([color respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
        done = [color getRed:rPtr green:gPtr blue:bPtr alpha:NULL];
    }

    if (!done) {
        // The method getRed:green:blue:alpha: was only available starting iOS 5.
        // So in iOS 4 and earlier, we have to jump through hoops.

        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();

        unsigned char pixel[4];
        CGContextRef context = CGBitmapContextCreate(&pixel, 1, 1, 8, 4, rgbColorSpace, (CGBitmapInfo)(kCGBitmapAlphaInfoMask & kCGImageAlphaNoneSkipLast));

        CGContextSetFillColorWithColor(context, [color CGColor]);
        CGContextFillRect(context, CGRectMake(0, 0, 1, 1));

        if (rPtr) {
            *rPtr = pixel[0] / 255.0f;
        }

        if (gPtr) {
            *gPtr = pixel[1] / 255.0f;
        }

        if (bPtr) {
            *bPtr = pixel[2] / 255.0f;
        }

        CGContextRelease(context);
        CGColorSpaceRelease(rgbColorSpace);
    }

    #elif defined(DD_CLI) || !__has_include(<AppKit/NSColor.h>)

    // OS X without AppKit

    [color getRed:rPtr green:gPtr blue:bPtr alpha:NULL];

    #else /* if TARGET_OS_IPHONE */

    // OS X with AppKit

    NSColor *safeColor = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

    [safeColor getRed:rPtr green:gPtr blue:bPtr alpha:NULL];
    #endif /* if TARGET_OS_IPHONE */
}

/**
 * Maps the given color to the closest available color supported by the shell.
 * The shell may support 256 colors, or only 16.
 *
 * This method loops through the known supported color set, and calculates the closest color.
 * The array index of that color, within the colors array, is then returned.
 * This array index may also be used as the index within the codes_fg and codes_bg arrays.
 **/
+ (NSUInteger)codeIndexForColor:(DDColor *)inColor {
    CGFloat inR, inG, inB;

    [self getRed:&inR green:&inG blue:&inB fromColor:inColor];

    NSUInteger bestIndex = 0;
    CGFloat lowestDistance = 100.0f;

    NSUInteger i = 0;

    for (DDColor *color in colors) {
        // Calculate Euclidean distance (lower value means closer to given color)

        CGFloat r, g, b;
        [self getRed:&r green:&g blue:&b fromColor:color];

    #if CGFLOAT_IS_DOUBLE
        CGFloat distance = sqrt(pow(r - inR, 2.0) + pow(g - inG, 2.0) + pow(b - inB, 2.0));
    #else
        CGFloat distance = sqrtf(powf(r - inR, 2.0f) + powf(g - inG, 2.0f) + powf(b - inB, 2.0f));
    #endif

        NSLogVerbose(@"DDTTYLogger: %3lu : %.3f,%.3f,%.3f & %.3f,%.3f,%.3f = %.6f",
                     (unsigned long)i, inR, inG, inB, r, g, b, distance);

        if (distance < lowestDistance) {
            bestIndex = i;
            lowestDistance = distance;

            NSLogVerbose(@"DDTTYLogger: New best index = %lu", (unsigned long)bestIndex);
        }

        i++;
    }

    return bestIndex;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t DDTTYLoggerOnceToken;

    dispatch_once(&DDTTYLoggerOnceToken, ^{
        // Xcode does NOT natively support colors in the Xcode debugging console.
        // You'll need to install the XcodeColors plugin to see colors in the Xcode console.
        //
        // PS - Please read the header file before diving into the source code.

        char *xcode_colors = getenv("XcodeColors");
        char *term = getenv("TERM");

        if (xcode_colors && (strcmp(xcode_colors, "YES") == 0)) {
            isaXcodeColorTTY = YES;
        } else if (term) {
            if (strcasestr(term, "color") != NULL) {
                isaColorTTY = YES;
                isaColor256TTY = (strcasestr(term, "256") != NULL);

                if (isaColor256TTY) {
                    [self initialize_colors_256];
                } else {
                    [self initialize_colors_16];
                }
            }
        }

        NSLogInfo(@"DDTTYLogger: isaColorTTY = %@", (isaColorTTY ? @"YES" : @"NO"));
        NSLogInfo(@"DDTTYLogger: isaColor256TTY: %@", (isaColor256TTY ? @"YES" : @"NO"));
        NSLogInfo(@"DDTTYLogger: isaXcodeColorTTY: %@", (isaXcodeColorTTY ? @"YES" : @"NO"));

        ttySharedInstance = [[[self class] alloc] init];
    });

    return ttySharedInstance;
}

- (instancetype)init {
    if (ttySharedInstance != nil) {
        return nil;
    }

    if ((self = [super init])) {
        _calendarUnitFlags = (NSCalendarUnitYear     |
                             NSCalendarUnitMonth    |
                             NSCalendarUnitDay      |
                             NSCalendarUnitHour     |
                             NSCalendarUnitMinute   |
                             NSCalendarUnitSecond);

        // Initialze 'app' variable (char *)

        _appName = [[NSProcessInfo processInfo] processName];

        _appLen = [_appName lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

        if (_appLen == 0) {
            _appName = @"<UnnamedApp>";
            _appLen = [_appName lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        }

        _app = (char *)malloc(_appLen + 1);

        if (_app == NULL) {
            return nil;
        }

        BOOL processedAppName = [_appName getCString:_app maxLength:(_appLen + 1) encoding:NSUTF8StringEncoding];

        if (NO == processedAppName) {
            free(_app);
            return nil;
        }

        // Initialize 'pid' variable (char *)

        _processID = [NSString stringWithFormat:@"%i", (int)getpid()];

        _pidLen = [_processID lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        _pid = (char *)malloc(_pidLen + 1);

        if (_pid == NULL) {
            free(_app);
            return nil;
        }

        BOOL processedID = [_processID getCString:_pid maxLength:(_pidLen + 1) encoding:NSUTF8StringEncoding];

        if (NO == processedID) {
            free(_app);
            free(_pid);
            return nil;
        }

        // Initialize color stuff

        _colorsEnabled = NO;
        _colorProfilesArray = [[NSMutableArray alloc] initWithCapacity:8];
        _colorProfilesDict = [[NSMutableDictionary alloc] initWithCapacity:8];

        _automaticallyAppendNewlineForCustomFormatters = YES;
    }

    return self;
}

- (void)loadDefaultColorProfiles {
    [self setForegroundColor:DDMakeColor(214,  57,  30) backgroundColor:nil forFlag:DDLogFlagError];
    [self setForegroundColor:DDMakeColor(204, 121,  32) backgroundColor:nil forFlag:DDLogFlagWarning];
}

- (BOOL)colorsEnabled {
    // The design of this method is taken from the DDAbstractLogger implementation.
    // For extensive documentation please refer to the DDAbstractLogger implementation.

    // Note: The internal implementation MUST access the colorsEnabled variable directly,
    // This method is designed explicitly for external access.
    //
    // Using "self." syntax to go through this method will cause immediate deadlock.
    // This is the intended result. Fix it by accessing the ivar directly.
    // Great strides have been take to ensure this is safe to do. Plus it's MUCH faster.

    NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");
    NSAssert(![self isOnInternalLoggerQueue], @"MUST access ivar directly, NOT via self.* syntax.");

    dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];

    __block BOOL result;

    dispatch_sync(globalLoggingQueue, ^{
        dispatch_sync(self.loggerQueue, ^{
            result = _colorsEnabled;
        });
    });

    return result;
}

- (void)setColorsEnabled:(BOOL)newColorsEnabled {
    dispatch_block_t block = ^{
        @autoreleasepool {
            _colorsEnabled = newColorsEnabled;

            if ([_colorProfilesArray count] == 0) {
                [self loadDefaultColorProfiles];
            }
        }
    };

    // The design of this method is taken from the DDAbstractLogger implementation.
    // For extensive documentation please refer to the DDAbstractLogger implementation.

    // Note: The internal implementation MUST access the colorsEnabled variable directly,
    // This method is designed explicitly for external access.
    //
    // Using "self." syntax to go through this method will cause immediate deadlock.
    // This is the intended result. Fix it by accessing the ivar directly.
    // Great strides have been take to ensure this is safe to do. Plus it's MUCH faster.

    NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");
    NSAssert(![self isOnInternalLoggerQueue], @"MUST access ivar directly, NOT via self.* syntax.");

    dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];

    dispatch_async(globalLoggingQueue, ^{
        dispatch_async(self.loggerQueue, block);
    });
}

- (void)setForegroundColor:(DDColor *)txtColor backgroundColor:(DDColor *)bgColor forFlag:(DDLogFlag)mask {
    [self setForegroundColor:txtColor backgroundColor:bgColor forFlag:mask context:LOG_CONTEXT_ALL];
}

- (void)setForegroundColor:(DDColor *)txtColor backgroundColor:(DDColor *)bgColor forFlag:(DDLogFlag)mask context:(NSInteger)ctxt {
    dispatch_block_t block = ^{
        @autoreleasepool {
            DDTTYLoggerColorProfile *newColorProfile =
                [[DDTTYLoggerColorProfile alloc] initWithForegroundColor:txtColor
                                                         backgroundColor:bgColor
                                                                    flag:mask
                                                                 context:ctxt];

            NSLogInfo(@"DDTTYLogger: newColorProfile: %@", newColorProfile);

            NSUInteger i = 0;

            for (DDTTYLoggerColorProfile *colorProfile in _colorProfilesArray) {
                if ((colorProfile->mask == mask) && (colorProfile->context == ctxt)) {
                    break;
                }

                i++;
            }

            if (i < [_colorProfilesArray count]) {
                _colorProfilesArray[i] = newColorProfile;
            } else {
                [_colorProfilesArray addObject:newColorProfile];
            }
        }
    };

    // The design of the setter logic below is taken from the DDAbstractLogger implementation.
    // For documentation please refer to the DDAbstractLogger implementation.

    if ([self isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
        NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");

        dispatch_async(globalLoggingQueue, ^{
            dispatch_async(self.loggerQueue, block);
        });
    }
}

- (void)setForegroundColor:(DDColor *)txtColor backgroundColor:(DDColor *)bgColor forTag:(id <NSCopying>)tag {
    NSAssert([(id < NSObject >) tag conformsToProtocol: @protocol(NSCopying)], @"Invalid tag");

    dispatch_block_t block = ^{
        @autoreleasepool {
            DDTTYLoggerColorProfile *newColorProfile =
                [[DDTTYLoggerColorProfile alloc] initWithForegroundColor:txtColor
                                                         backgroundColor:bgColor
                                                                    flag:(DDLogFlag)0
                                                                 context:0];

            NSLogInfo(@"DDTTYLogger: newColorProfile: %@", newColorProfile);

            _colorProfilesDict[tag] = newColorProfile;
        }
    };

    // The design of the setter logic below is taken from the DDAbstractLogger implementation.
    // For documentation please refer to the DDAbstractLogger implementation.

    if ([self isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
        NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");

        dispatch_async(globalLoggingQueue, ^{
            dispatch_async(self.loggerQueue, block);
        });
    }
}

- (void)clearColorsForFlag:(DDLogFlag)mask {
    [self clearColorsForFlag:mask context:0];
}

- (void)clearColorsForFlag:(DDLogFlag)mask context:(NSInteger)context {
    dispatch_block_t block = ^{
        @autoreleasepool {
            NSUInteger i = 0;

            for (DDTTYLoggerColorProfile *colorProfile in _colorProfilesArray) {
                if ((colorProfile->mask == mask) && (colorProfile->context == context)) {
                    break;
                }

                i++;
            }

            if (i < [_colorProfilesArray count]) {
                [_colorProfilesArray removeObjectAtIndex:i];
            }
        }
    };

    // The design of the setter logic below is taken from the DDAbstractLogger implementation.
    // For documentation please refer to the DDAbstractLogger implementation.

    if ([self isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
        NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");

        dispatch_async(globalLoggingQueue, ^{
            dispatch_async(self.loggerQueue, block);
        });
    }
}

- (void)clearColorsForTag:(id <NSCopying>)tag {
    NSAssert([(id < NSObject >) tag conformsToProtocol: @protocol(NSCopying)], @"Invalid tag");

    dispatch_block_t block = ^{
        @autoreleasepool {
            [_colorProfilesDict removeObjectForKey:tag];
        }
    };

    // The design of the setter logic below is taken from the DDAbstractLogger implementation.
    // For documentation please refer to the DDAbstractLogger implementation.

    if ([self isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
        NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");

        dispatch_async(globalLoggingQueue, ^{
            dispatch_async(self.loggerQueue, block);
        });
    }
}

- (void)clearColorsForAllFlags {
    dispatch_block_t block = ^{
        @autoreleasepool {
            [_colorProfilesArray removeAllObjects];
        }
    };

    // The design of the setter logic below is taken from the DDAbstractLogger implementation.
    // For documentation please refer to the DDAbstractLogger implementation.

    if ([self isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
        NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");

        dispatch_async(globalLoggingQueue, ^{
            dispatch_async(self.loggerQueue, block);
        });
    }
}

- (void)clearColorsForAllTags {
    dispatch_block_t block = ^{
        @autoreleasepool {
            [_colorProfilesDict removeAllObjects];
        }
    };

    // The design of the setter logic below is taken from the DDAbstractLogger implementation.
    // For documentation please refer to the DDAbstractLogger implementation.

    if ([self isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
        NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");

        dispatch_async(globalLoggingQueue, ^{
            dispatch_async(self.loggerQueue, block);
        });
    }
}

- (void)clearAllColors {
    dispatch_block_t block = ^{
        @autoreleasepool {
            [_colorProfilesArray removeAllObjects];
            [_colorProfilesDict removeAllObjects];
        }
    };

    // The design of the setter logic below is taken from the DDAbstractLogger implementation.
    // For documentation please refer to the DDAbstractLogger implementation.

    if ([self isOnInternalLoggerQueue]) {
        block();
    } else {
        dispatch_queue_t globalLoggingQueue = [DDLog loggingQueue];
        NSAssert(![self isOnGlobalLoggingQueue], @"Core architecture requirement failure");

        dispatch_async(globalLoggingQueue, ^{
            dispatch_async(self.loggerQueue, block);
        });
    }
}

- (void)logMessage:(DDLogMessage *)logMessage {
    NSString *logMsg = logMessage->_message;
    BOOL isFormatted = NO;

    if (_logFormatter) {
        logMsg = [_logFormatter formatLogMessage:logMessage];
        isFormatted = logMsg != logMessage->_message;
    }

    if (logMsg) {
        // Search for a color profile associated with the log message

        DDTTYLoggerColorProfile *colorProfile = nil;

        if (_colorsEnabled) {
            if (logMessage->_tag) {
                colorProfile = _colorProfilesDict[logMessage->_tag];
            }

            if (colorProfile == nil) {
                for (DDTTYLoggerColorProfile *cp in _colorProfilesArray) {
                    if (logMessage->_flag & cp->mask) {
                        // Color profile set for this context?
                        if (logMessage->_context == cp->context) {
                            colorProfile = cp;

                            // Stop searching
                            break;
                        }

                        // Check if LOG_CONTEXT_ALL was specified as a default color for this flag
                        if (cp->context == LOG_CONTEXT_ALL) {
                            colorProfile = cp;

                            // We don't break to keep searching for more specific color profiles for the context
                        }
                    }
                }
            }
        }

        // Convert log message to C string.
        //
        // We use the stack instead of the heap for speed if possible.
        // But we're extra cautious to avoid a stack overflow.

        NSUInteger msgLen = [logMsg lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        const BOOL useStack = msgLen < (1024 * 4);

        char msgStack[useStack ? (msgLen + 1) : 1]; // Analyzer doesn't like zero-size array, hence the 1
        char *msg = useStack ? msgStack : (char *)malloc(msgLen + 1);

        if (msg == NULL) {
            return;
        }

        BOOL logMsgEnc = [logMsg getCString:msg maxLength:(msgLen + 1) encoding:NSUTF8StringEncoding];

        if (!logMsgEnc) {
            if (!useStack && msg != NULL) {
                free(msg);
            }

            return;
        }

        // Write the log message to STDERR

        if (isFormatted) {
            // The log message has already been formatted.
            int iovec_len = (_automaticallyAppendNewlineForCustomFormatters) ? 5 : 4;
            struct iovec v[iovec_len];

            if (colorProfile) {
                v[0].iov_base = colorProfile->fgCode;
                v[0].iov_len = colorProfile->fgCodeLen;

                v[1].iov_base = colorProfile->bgCode;
                v[1].iov_len = colorProfile->bgCodeLen;

                v[iovec_len - 1].iov_base = colorProfile->resetCode;
                v[iovec_len - 1].iov_len = colorProfile->resetCodeLen;
            } else {
                v[0].iov_base = "";
                v[0].iov_len = 0;

                v[1].iov_base = "";
                v[1].iov_len = 0;

                v[iovec_len - 1].iov_base = "";
                v[iovec_len - 1].iov_len = 0;
            }

            v[2].iov_base = (char *)msg;
            v[2].iov_len = msgLen;

            if (iovec_len == 5) {
                v[3].iov_base = "\n";
                v[3].iov_len = (msg[msgLen] == '\n') ? 0 : 1;
            }

            writev(STDERR_FILENO, v, iovec_len);
        } else {
            // The log message is unformatted, so apply standard NSLog style formatting.

            int len;
            char ts[24] = "";
            size_t tsLen = 0;

            // Calculate timestamp.
            // The technique below is faster than using NSDateFormatter.
            if (logMessage->_timestamp) {
                NSDateComponents *components = [[NSCalendar autoupdatingCurrentCalendar] components:_calendarUnitFlags fromDate:logMessage->_timestamp];

                NSTimeInterval epoch = [logMessage->_timestamp timeIntervalSinceReferenceDate];
                int milliseconds = (int)((epoch - floor(epoch)) * 1000);

                len = snprintf(ts, 24, "%04ld-%02ld-%02ld %02ld:%02ld:%02ld:%03d", // yyyy-MM-dd HH:mm:ss:SSS
                               (long)components.year,
                               (long)components.month,
                               (long)components.day,
                               (long)components.hour,
                               (long)components.minute,
                               (long)components.second, milliseconds);

                tsLen = (NSUInteger)MAX(MIN(24 - 1, len), 0);
            }

            // Calculate thread ID
            //
            // How many characters do we need for the thread id?
            // logMessage->machThreadID is of type mach_port_t, which is an unsigned int.
            //
            // 1 hex char = 4 bits
            // 8 hex chars for 32 bit, plus ending '\0' = 9

            char tid[9];
            len = snprintf(tid, 9, "%s", [logMessage->_threadID cStringUsingEncoding:NSUTF8StringEncoding]);

            size_t tidLen = (NSUInteger)MAX(MIN(9 - 1, len), 0);

            // Here is our format: "%s %s[%i:%s] %s", timestamp, appName, processID, threadID, logMsg

            struct iovec v[13];

            if (colorProfile) {
                v[0].iov_base = colorProfile->fgCode;
                v[0].iov_len = colorProfile->fgCodeLen;

                v[1].iov_base = colorProfile->bgCode;
                v[1].iov_len = colorProfile->bgCodeLen;

                v[12].iov_base = colorProfile->resetCode;
                v[12].iov_len = colorProfile->resetCodeLen;
            } else {
                v[0].iov_base = "";
                v[0].iov_len = 0;

                v[1].iov_base = "";
                v[1].iov_len = 0;

                v[12].iov_base = "";
                v[12].iov_len = 0;
            }

            v[2].iov_base = ts;
            v[2].iov_len = tsLen;

            v[3].iov_base = " ";
            v[3].iov_len = 1;

            v[4].iov_base = _app;
            v[4].iov_len = _appLen;

            v[5].iov_base = "[";
            v[5].iov_len = 1;

            v[6].iov_base = _pid;
            v[6].iov_len = _pidLen;

            v[7].iov_base = ":";
            v[7].iov_len = 1;

            v[8].iov_base = tid;
            v[8].iov_len = MIN((size_t)8, tidLen); // snprintf doesn't return what you might think

            v[9].iov_base = "] ";
            v[9].iov_len = 2;

            v[10].iov_base = (char *)msg;
            v[10].iov_len = msgLen;

            v[11].iov_base = "\n";
            v[11].iov_len = (msg[msgLen] == '\n') ? 0 : 1;

            writev(STDERR_FILENO, v, 13);
        }

        if (!useStack) {
            free(msg);
        }
    }
}

- (NSString *)loggerName {
    return @"cocoa.lumberjack.ttyLogger";
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation DDTTYLoggerColorProfile

- (instancetype)initWithForegroundColor:(DDColor *)fgColor backgroundColor:(DDColor *)bgColor flag:(DDLogFlag)aMask context:(NSInteger)ctxt {
    if ((self = [super init])) {
        mask = aMask;
        context = ctxt;

        CGFloat r, g, b;

        if (fgColor) {
            [DDTTYLogger getRed:&r green:&g blue:&b fromColor:fgColor];

            fg_r = (uint8_t)(r * 255.0f);
            fg_g = (uint8_t)(g * 255.0f);
            fg_b = (uint8_t)(b * 255.0f);
        }

        if (bgColor) {
            [DDTTYLogger getRed:&r green:&g blue:&b fromColor:bgColor];

            bg_r = (uint8_t)(r * 255.0f);
            bg_g = (uint8_t)(g * 255.0f);
            bg_b = (uint8_t)(b * 255.0f);
        }

        if (fgColor && isaColorTTY) {
            // Map foreground color to closest available shell color

            fgCodeIndex = [DDTTYLogger codeIndexForColor:fgColor];
            fgCodeRaw   = codes_fg[fgCodeIndex];

            NSString *escapeSeq = @"\033[";

            NSUInteger len1 = [escapeSeq lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            NSUInteger len2 = [fgCodeRaw lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

            BOOL escapeSeqEnc = [escapeSeq getCString:(fgCode)      maxLength:(len1 + 1) encoding:NSUTF8StringEncoding];
            BOOL fgCodeRawEsc = [fgCodeRaw getCString:(fgCode + len1) maxLength:(len2 + 1) encoding:NSUTF8StringEncoding];

            if (!escapeSeqEnc || !fgCodeRawEsc) {
                return nil;
            }

            fgCodeLen = len1 + len2;
        } else if (fgColor && isaXcodeColorTTY) {
            // Convert foreground color to color code sequence

            const char *escapeSeq = XCODE_COLORS_ESCAPE_SEQ;

            int result = snprintf(fgCode, 24, "%sfg%u,%u,%u;", escapeSeq, fg_r, fg_g, fg_b);
            fgCodeLen = (NSUInteger)MAX(MIN(result, (24 - 1)), 0);
        } else {
            // No foreground color or no color support

            fgCode[0] = '\0';
            fgCodeLen = 0;
        }

        if (bgColor && isaColorTTY) {
            // Map background color to closest available shell color

            bgCodeIndex = [DDTTYLogger codeIndexForColor:bgColor];
            bgCodeRaw   = codes_bg[bgCodeIndex];

            NSString *escapeSeq = @"\033[";

            NSUInteger len1 = [escapeSeq lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
            NSUInteger len2 = [bgCodeRaw lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

            BOOL escapeSeqEnc = [escapeSeq getCString:(bgCode)      maxLength:(len1 + 1) encoding:NSUTF8StringEncoding];
            BOOL bgCodeRawEsc = [bgCodeRaw getCString:(bgCode + len1) maxLength:(len2 + 1) encoding:NSUTF8StringEncoding];

            if (!escapeSeqEnc || !bgCodeRawEsc) {
                return nil;
            }

            bgCodeLen = len1 + len2;
        } else if (bgColor && isaXcodeColorTTY) {
            // Convert background color to color code sequence

            const char *escapeSeq = XCODE_COLORS_ESCAPE_SEQ;

            int result = snprintf(bgCode, 24, "%sbg%u,%u,%u;", escapeSeq, bg_r, bg_g, bg_b);
            bgCodeLen = (NSUInteger)MAX(MIN(result, (24 - 1)), 0);
        } else {
            // No background color or no color support

            bgCode[0] = '\0';
            bgCodeLen = 0;
        }

        if (isaColorTTY) {
            resetCodeLen = (NSUInteger)MAX(snprintf(resetCode, 8, "\033[0m"), 0);
        } else if (isaXcodeColorTTY) {
            resetCodeLen = (NSUInteger)MAX(snprintf(resetCode, 8, XCODE_COLORS_RESET), 0);
        } else {
            resetCode[0] = '\0';
            resetCodeLen = 0;
        }
    }

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:
            @"<DDTTYLoggerColorProfile: %p mask:%i ctxt:%ld fg:%u,%u,%u bg:%u,%u,%u fgCode:%@ bgCode:%@>",
            self, (int)mask, (long)context, fg_r, fg_g, fg_b, bg_r, bg_g, bg_b, fgCodeRaw, bgCodeRaw];
}

@end
