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

/**
 * Legacy macros used for 1.9.x backwards compatibility.
 *
 * Imported by default when importing a DDLog.h directly and DD_LEGACY_MACROS is not defined and set to 0.
 **/
#if DD_LEGACY_MACROS

#warning CocoaLumberjack 1.9.x legacy macros enabled. \
Disable legacy macros by importing CocoaLumberjack.h or DDLogMacros.h instead of DDLog.h or add `#define DD_LEGACY_MACROS 0` before importing DDLog.h.

#ifndef LOG_LEVEL_DEF
    #define LOG_LEVEL_DEF ddLogLevel
#endif

#define LOG_FLAG_ERROR    DDLogFlagError
#define LOG_FLAG_WARN     DDLogFlagWarning
#define LOG_FLAG_INFO     DDLogFlagInfo
#define LOG_FLAG_DEBUG    DDLogFlagDebug
#define LOG_FLAG_VERBOSE  DDLogFlagVerbose

#define LOG_LEVEL_OFF     DDLogLevelOff
#define LOG_LEVEL_ERROR   DDLogLevelError
#define LOG_LEVEL_WARN    DDLogLevelWarning
#define LOG_LEVEL_INFO    DDLogLevelInfo
#define LOG_LEVEL_DEBUG   DDLogLevelDebug
#define LOG_LEVEL_VERBOSE DDLogLevelVerbose
#define LOG_LEVEL_ALL     DDLogLevelAll

#define LOG_ASYNC_ENABLED YES

#define LOG_ASYNC_ERROR    ( NO && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_WARN     (YES && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_INFO     (YES && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_DEBUG    (YES && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_VERBOSE  (YES && LOG_ASYNC_ENABLED)

#define LOG_MACRO(isAsynchronous, lvl, flg, ctx, atag, fnct, frmt, ...) \
        [DDLog log : isAsynchronous                                     \
             level : lvl                                                \
              flag : flg                                                \
           context : ctx                                                \
              file : __FILE__                                           \
          function : fnct                                               \
              line : __LINE__                                           \
               tag : atag                                               \
            format : (frmt), ## __VA_ARGS__]

#define LOG_MAYBE(async, lvl, flg, ctx, fnct, frmt, ...)                       \
        do { if(lvl & flg) LOG_MACRO(async, lvl, flg, ctx, nil, fnct, frmt, ##__VA_ARGS__); } while(0)

#define LOG_OBJC_MAYBE(async, lvl, flg, ctx, frmt, ...) \
        LOG_MAYBE(async, lvl, flg, ctx, __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)

#define DDLogError(frmt, ...)   LOG_OBJC_MAYBE(LOG_ASYNC_ERROR,   LOG_LEVEL_DEF, LOG_FLAG_ERROR,   0, frmt, ##__VA_ARGS__)
#define DDLogWarn(frmt, ...)    LOG_OBJC_MAYBE(LOG_ASYNC_WARN,    LOG_LEVEL_DEF, LOG_FLAG_WARN,    0, frmt, ##__VA_ARGS__)
#define DDLogInfo(frmt, ...)    LOG_OBJC_MAYBE(LOG_ASYNC_INFO,    LOG_LEVEL_DEF, LOG_FLAG_INFO,    0, frmt, ##__VA_ARGS__)
#define DDLogDebug(frmt, ...)   LOG_OBJC_MAYBE(LOG_ASYNC_DEBUG,   LOG_LEVEL_DEF, LOG_FLAG_DEBUG,   0, frmt, ##__VA_ARGS__)
#define DDLogVerbose(frmt, ...) LOG_OBJC_MAYBE(LOG_ASYNC_VERBOSE, LOG_LEVEL_DEF, LOG_FLAG_VERBOSE, 0, frmt, ##__VA_ARGS__)

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

#import <Foundation/Foundation.h>

// Enable 1.9.x legacy macros if imported directly
#ifndef DD_LEGACY_MACROS
    #define DD_LEGACY_MACROS 1
#endif

#if OS_OBJECT_USE_OBJC
    #define DISPATCH_QUEUE_REFERENCE_TYPE strong
#else
    #define DISPATCH_QUEUE_REFERENCE_TYPE assign
#endif

@class DDLogMessage;
@protocol DDLogger;
@protocol DDLogFormatter;

/**
 * Define the standard options.
 *
 * We default to only 4 levels because it makes it easier for beginners
 * to make the transition to a logging framework.
 *
 * More advanced users may choose to completely customize the levels (and level names) to suite their needs.
 * For more information on this see the "Custom Log Levels" page:
 * Documentation/CustomLogLevels.md
 *
 * Advanced users may also notice that we're using a bitmask.
 * This is to allow for custom fine grained logging:
 * Documentation/FineGrainedLogging.md
 *
 * -- Flags --
 *
 * Typically you will use the LOG_LEVELS (see below), but the flags may be used directly in certain situations.
 * For example, say you have a lot of warning log messages, and you wanted to disable them.
 * However, you still needed to see your error and info log messages.
 * You could accomplish that with the following:
 *
 * static const DDLogLevel ddLogLevel = DDLogFlagError | DDLogFlagInfo;
 *
 * When LOG_LEVEL_DEF is defined as ddLogLevel.
 *
 * Flags may also be consulted when writing custom log formatters,
 * as the DDLogMessage class captures the individual flag that caused the log message to fire.
 *
 * -- Levels --
 *
 * Log levels are simply the proper bitmask of the flags.
 *
 * -- Booleans --
 *
 * The booleans may be used when your logging code involves more than one line.
 * For example:
 *
 * if (LOG_VERBOSE) {
 *     for (id sprocket in sprockets)
 *         DDLogVerbose(@"sprocket: %@", [sprocket description])
 * }
 *
 * -- Async --
 *
 * Defines the default asynchronous options.
 * The default philosophy for asynchronous logging is very simple:
 *
 * Log messages with errors should be executed synchronously.
 *     After all, an error just occurred. The application could be unstable.
 *
 * All other log messages, such as debug output, are executed asynchronously.
 *     After all, if it wasn't an error, then it was just informational output,
 *     or something the application was easily able to recover from.
 *
 * -- Changes --
 *
 * You are strongly discouraged from modifying this file.
 * If you do, you make it more difficult on yourself to merge future bug fixes and improvements from the project.
 * Instead, create your own MyLogging.h or ApplicationNameLogging.h or CompanyLogging.h
 *
 * For an example of customizing your logging experience, see the "Custom Log Levels" page:
 * Documentation/CustomLogLevels.md
 **/

/**
 *  Flags accompany each log. They are used together with levels to filter out logs.
 */
typedef NS_OPTIONS(NSUInteger, DDLogFlag){
    /**
     *  0...00001 DDLogFlagError
     */
    DDLogFlagError      = (1 << 0),
    
    /**
     *  0...00010 DDLogFlagWarning
     */
    DDLogFlagWarning    = (1 << 1),
    
    /**
     *  0...00100 DDLogFlagInfo
     */
    DDLogFlagInfo       = (1 << 2),
    
    /**
     *  0...01000 DDLogFlagDebug
     */
    DDLogFlagDebug      = (1 << 3),
    
    /**
     *  0...10000 DDLogFlagVerbose
     */
    DDLogFlagVerbose    = (1 << 4)
};

/**
 *  Log levels are used to filter out logs. Used together with flags.
 */
typedef NS_ENUM(NSUInteger, DDLogLevel){
    /**
     *  No logs
     */
    DDLogLevelOff       = 0,
    
    /**
     *  Error logs only
     */
    DDLogLevelError     = (DDLogFlagError),
    
    /**
     *  Error and warning logs
     */
    DDLogLevelWarning   = (DDLogLevelError   | DDLogFlagWarning),
    
    /**
     *  Error, warning and info logs
     */
    DDLogLevelInfo      = (DDLogLevelWarning | DDLogFlagInfo),
    
    /**
     *  Error, warning, info and debug logs
     */
    DDLogLevelDebug     = (DDLogLevelInfo    | DDLogFlagDebug),
    
    /**
     *  Error, warning, info, debug and verbose logs
     */
    DDLogLevelVerbose   = (DDLogLevelDebug   | DDLogFlagVerbose),
    
    /**
     *  All logs (1...11111)
     */
    DDLogLevelAll       = NSUIntegerMax
};

/**
 *  Extracts just the file name, no path or extension
 *
 *  @param filePath input file path
 *  @param copy     YES if we want the result to be copied
 *
 *  @return the file name
 */
NSString * DDExtractFileNameWithoutExtension(const char *filePath, BOOL copy);

/**
 * The THIS_FILE macro gives you an NSString of the file name.
 * For simplicity and clarity, the file name does not include the full path or file extension.
 *
 * For example: DDLogWarn(@"%@: Unable to find thingy", THIS_FILE) -> @"MyViewController: Unable to find thingy"
 **/
#define THIS_FILE         (DDExtractFileNameWithoutExtension(__FILE__, NO))

/**
 * The THIS_METHOD macro gives you the name of the current objective-c method.
 *
 * For example: DDLogWarn(@"%@ - Requires non-nil strings", THIS_METHOD) -> @"setMake:model: requires non-nil strings"
 *
 * Note: This does NOT work in straight C functions (non objective-c).
 * Instead you should use the predefined __FUNCTION__ macro.
 **/
#define THIS_METHOD       NSStringFromSelector(_cmd)


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 *  The main class, exposes all logging mechanisms, loggers, ...
 *  For most of the users, this class is hidden behind the logging functions like `DDLogInfo`
 */
@interface DDLog : NSObject

/**
 *  Returns the singleton `DDLog`.
 *  The instance is used by `DDLog` class methods.
 *
 *  @return The singleton `DDLog`.
 */
+ (instancetype)sharedInstance;

/**
 * Provides access to the underlying logging queue.
 * This may be helpful to Logger classes for things like thread synchronization.
 **/
+ (dispatch_queue_t)loggingQueue;

/**
 * Logging Primitive.
 *
 * This method is used by the macros or logging functions.
 * It is suggested you stick with the macros as they're easier to use.
 *
 *  @param asynchronous YES if the logging is done async, NO if you want to force sync
 *  @param level        the log level
 *  @param flag         the log flag
 *  @param context      the context (if any is defined)
 *  @param file         the current file
 *  @param function     the current function
 *  @param line         the current code line
 *  @param tag          potential tag
 *  @param format       the log format
 */
+ (void)log:(BOOL)asynchronous
      level:(DDLogLevel)level
       flag:(DDLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format, ... NS_FORMAT_FUNCTION(9,10);

/**
 * Logging Primitive.
 *
 * This method is used by the macros or logging functions.
 * It is suggested you stick with the macros as they're easier to use.
 *
 *  @param asynchronous YES if the logging is done async, NO if you want to force sync
 *  @param level        the log level
 *  @param flag         the log flag
 *  @param context      the context (if any is defined)
 *  @param file         the current file
 *  @param function     the current function
 *  @param line         the current code line
 *  @param tag          potential tag
 *  @param format       the log format
 */
- (void)log:(BOOL)asynchronous
      level:(DDLogLevel)level
       flag:(DDLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format, ... NS_FORMAT_FUNCTION(9,10);

/**
 * Logging Primitive.
 *
 * This method can be used if you have a prepared va_list.
 * Similar to `log:level:flag:context:file:function:line:tag:format:...`
 *
 *  @param asynchronous YES if the logging is done async, NO if you want to force sync
 *  @param level        the log level
 *  @param flag         the log flag
 *  @param context      the context (if any is defined)
 *  @param file         the current file
 *  @param function     the current function
 *  @param line         the current code line
 *  @param tag          potential tag
 *  @param format       the log format
 *  @param argList      the arguments list as a va_list
 */
+ (void)log:(BOOL)asynchronous
      level:(DDLogLevel)level
       flag:(DDLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format
       args:(va_list)argList;

/**
 * Logging Primitive.
 *
 * This method can be used if you have a prepared va_list.
 * Similar to `log:level:flag:context:file:function:line:tag:format:...`
 *
 *  @param asynchronous YES if the logging is done async, NO if you want to force sync
 *  @param level        the log level
 *  @param flag         the log flag
 *  @param context      the context (if any is defined)
 *  @param file         the current file
 *  @param function     the current function
 *  @param line         the current code line
 *  @param tag          potential tag
 *  @param format       the log format
 *  @param argList      the arguments list as a va_list
 */
- (void)log:(BOOL)asynchronous
      level:(DDLogLevel)level
       flag:(DDLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format
       args:(va_list)argList;

/**
 * Logging Primitive.
 *
 * This method can be used if you manualy prepared DDLogMessage.
 *
 *  @param asynchronous YES if the logging is done async, NO if you want to force sync
 *  @param logMessage   the log message stored in a `DDLogMessage` model object
 */
+ (void)log:(BOOL)asynchronous
    message:(DDLogMessage *)logMessage;

/**
 * Logging Primitive.
 *
 * This method can be used if you manualy prepared DDLogMessage.
 *
 *  @param asynchronous YES if the logging is done async, NO if you want to force sync
 *  @param logMessage   the log message stored in a `DDLogMessage` model object
 */
- (void)log:(BOOL)asynchronous
    message:(DDLogMessage *)logMessage;

/**
 * Since logging can be asynchronous, there may be times when you want to flush the logs.
 * The framework invokes this automatically when the application quits.
 **/
+ (void)flushLog;

/**
 * Since logging can be asynchronous, there may be times when you want to flush the logs.
 * The framework invokes this automatically when the application quits.
 **/
- (void)flushLog;

/**
 * Loggers
 *
 * In order for your log statements to go somewhere, you should create and add a logger.
 *
 * You can add multiple loggers in order to direct your log statements to multiple places.
 * And each logger can be configured separately.
 * So you could have, for example, verbose logging to the console, but a concise log file with only warnings & errors.
 **/

/**
 * Adds the logger to the system.
 *
 * This is equivalent to invoking `[DDLog addLogger:logger withLogLevel:DDLogLevelAll]`.
 **/
+ (void)addLogger:(id <DDLogger>)logger;

/**
 * Adds the logger to the system.
 *
 * This is equivalent to invoking `[DDLog addLogger:logger withLogLevel:DDLogLevelAll]`.
 **/
- (void)addLogger:(id <DDLogger>)logger;

/**
 * Adds the logger to the system.
 *
 * The level that you provide here is a preemptive filter (for performance).
 * That is, the level specified here will be used to filter out logMessages so that
 * the logger is never even invoked for the messages.
 *
 * More information:
 * When you issue a log statement, the logging framework iterates over each logger,
 * and checks to see if it should forward the logMessage to the logger.
 * This check is done using the level parameter passed to this method.
 *
 * For example:
 *
 * `[DDLog addLogger:consoleLogger withLogLevel:DDLogLevelVerbose];`
 * `[DDLog addLogger:fileLogger    withLogLevel:DDLogLevelWarning];`
 *
 * `DDLogError(@"oh no");` => gets forwarded to consoleLogger & fileLogger
 * `DDLogInfo(@"hi");`     => gets forwarded to consoleLogger only
 *
 * It is important to remember that Lumberjack uses a BITMASK.
 * Many developers & third party frameworks may define extra log levels & flags.
 * For example:
 *
 * `#define SOME_FRAMEWORK_LOG_FLAG_TRACE (1 << 6) // 0...1000000`
 *
 * So if you specify `DDLogLevelVerbose` to this method, you won't see the framework's trace messages.
 *
 * `(SOME_FRAMEWORK_LOG_FLAG_TRACE & DDLogLevelVerbose) => (01000000 & 00011111) => NO`
 *
 * Consider passing `DDLogLevelAll` to this method, which has all bits set.
 * You can also use the exclusive-or bitwise operator to get a bitmask that has all flags set,
 * except the ones you explicitly don't want. For example, if you wanted everything except verbose & debug:
 *
 * `((DDLogLevelAll ^ DDLogLevelVerbose) | DDLogLevelInfo)`
 **/
+ (void)addLogger:(id <DDLogger>)logger withLevel:(DDLogLevel)level;

/**
 * Adds the logger to the system.
 *
 * The level that you provide here is a preemptive filter (for performance).
 * That is, the level specified here will be used to filter out logMessages so that
 * the logger is never even invoked for the messages.
 *
 * More information:
 * When you issue a log statement, the logging framework iterates over each logger,
 * and checks to see if it should forward the logMessage to the logger.
 * This check is done using the level parameter passed to this method.
 *
 * For example:
 *
 * `[DDLog addLogger:consoleLogger withLogLevel:DDLogLevelVerbose];`
 * `[DDLog addLogger:fileLogger    withLogLevel:DDLogLevelWarning];`
 *
 * `DDLogError(@"oh no");` => gets forwarded to consoleLogger & fileLogger
 * `DDLogInfo(@"hi");`     => gets forwarded to consoleLogger only
 *
 * It is important to remember that Lumberjack uses a BITMASK.
 * Many developers & third party frameworks may define extra log levels & flags.
 * For example:
 *
 * `#define SOME_FRAMEWORK_LOG_FLAG_TRACE (1 << 6) // 0...1000000`
 *
 * So if you specify `DDLogLevelVerbose` to this method, you won't see the framework's trace messages.
 *
 * `(SOME_FRAMEWORK_LOG_FLAG_TRACE & DDLogLevelVerbose) => (01000000 & 00011111) => NO`
 *
 * Consider passing `DDLogLevelAll` to this method, which has all bits set.
 * You can also use the exclusive-or bitwise operator to get a bitmask that has all flags set,
 * except the ones you explicitly don't want. For example, if you wanted everything except verbose & debug:
 *
 * `((DDLogLevelAll ^ DDLogLevelVerbose) | DDLogLevelInfo)`
 **/
- (void)addLogger:(id <DDLogger>)logger withLevel:(DDLogLevel)level;

/**
 *  Remove the logger from the system
 */
+ (void)removeLogger:(id <DDLogger>)logger;

/**
 *  Remove the logger from the system
 */
- (void)removeLogger:(id <DDLogger>)logger;

/**
 *  Remove all the current loggers
 */
+ (void)removeAllLoggers;

/**
 *  Remove all the current loggers
 */
- (void)removeAllLoggers;

/**
 *  Return all the current loggers
 */
+ (NSArray *)allLoggers;

/**
 *  Return all the current loggers
 */
- (NSArray *)allLoggers;

/**
 * Registered Dynamic Logging
 *
 * These methods allow you to obtain a list of classes that are using registered dynamic logging,
 * and also provides methods to get and set their log level during run time.
 **/

/**
 *  Returns an array with the classes that are using registered dynamic logging
 */
+ (NSArray *)registeredClasses;

/**
 *  Returns an array with the classes names that are using registered dynamic logging
 */
+ (NSArray *)registeredClassNames;

/**
 *  Returns the current log level for a certain class
 *
 *  @param aClass `Class` param
 */
+ (DDLogLevel)levelForClass:(Class)aClass;

/**
 *  Returns the current log level for a certain class
 *
 *  @param aClassName string param
 */
+ (DDLogLevel)levelForClassWithName:(NSString *)aClassName;

/**
 *  Set the log level for a certain class
 *
 *  @param level  the new level
 *  @param aClass `Class` param
 */
+ (void)setLevel:(DDLogLevel)level forClass:(Class)aClass;

/**
 *  Set the log level for a certain class
 *
 *  @param level      the new level
 *  @param aClassName string param
 */
+ (void)setLevel:(DDLogLevel)level forClassWithName:(NSString *)aClassName;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 *  This protocol describes a basic logger behavior. 
 *  Basically, it can log messages, store a logFormatter plus a bunch of optional behaviors.
 *  (i.e. flush, get its loggerQueue, get its name, ...
 */
@protocol DDLogger <NSObject>

/**
 *  The log message method
 *
 *  @param logMessage the message (model)
 */
- (void)logMessage:(DDLogMessage *)logMessage;

/**
 * Formatters may optionally be added to any logger.
 *
 * If no formatter is set, the logger simply logs the message as it is given in logMessage,
 * or it may use its own built in formatting style.
 **/
@property (nonatomic, strong) id <DDLogFormatter> logFormatter;

@optional

/**
 * Since logging is asynchronous, adding and removing loggers is also asynchronous.
 * In other words, the loggers are added and removed at appropriate times with regards to log messages.
 *
 * - Loggers will not receive log messages that were executed prior to when they were added.
 * - Loggers will not receive log messages that were executed after they were removed.
 *
 * These methods are executed in the logging thread/queue.
 * This is the same thread/queue that will execute every logMessage: invocation.
 * Loggers may use these methods for thread synchronization or other setup/teardown tasks.
 **/
- (void)didAddLogger;

/**
 *  See the above description for `didAddLoger`
 */
- (void)willRemoveLogger;

/**
 * Some loggers may buffer IO for optimization purposes.
 * For example, a database logger may only save occasionaly as the disk IO is slow.
 * In such loggers, this method should be implemented to flush any pending IO.
 *
 * This allows invocations of DDLog's flushLog method to be propogated to loggers that need it.
 *
 * Note that DDLog's flushLog method is invoked automatically when the application quits,
 * and it may be also invoked manually by the developer prior to application crashes, or other such reasons.
 **/
- (void)flush;

/**
 * Each logger is executed concurrently with respect to the other loggers.
 * Thus, a dedicated dispatch queue is used for each logger.
 * Logger implementations may optionally choose to provide their own dispatch queue.
 **/
@property (nonatomic, DISPATCH_QUEUE_REFERENCE_TYPE, readonly) dispatch_queue_t loggerQueue;

/**
 * If the logger implementation does not choose to provide its own queue,
 * one will automatically be created for it.
 * The created queue will receive its name from this method.
 * This may be helpful for debugging or profiling reasons.
 **/
@property (nonatomic, readonly) NSString *loggerName;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 *  This protocol describes the behavior of a log formatter
 */
@protocol DDLogFormatter <NSObject>
@required

/**
 * Formatters may optionally be added to any logger.
 * This allows for increased flexibility in the logging environment.
 * For example, log messages for log files may be formatted differently than log messages for the console.
 *
 * For more information about formatters, see the "Custom Formatters" page:
 * Documentation/CustomFormatters.md
 *
 * The formatter may also optionally filter the log message by returning nil,
 * in which case the logger will not log the message.
 **/
- (NSString *)formatLogMessage:(DDLogMessage *)logMessage;

@optional

/**
 * A single formatter instance can be added to multiple loggers.
 * These methods provides hooks to notify the formatter of when it's added/removed.
 *
 * This is primarily for thread-safety.
 * If a formatter is explicitly not thread-safe, it may wish to throw an exception if added to multiple loggers.
 * Or if a formatter has potentially thread-unsafe code (e.g. NSDateFormatter),
 * it could possibly use these hooks to switch to thread-safe versions of the code.
 **/
- (void)didAddToLogger:(id <DDLogger>)logger;

/**
 *  See the above description for `didAddToLogger:`
 */
- (void)willRemoveFromLogger:(id <DDLogger>)logger;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 *  This protocol describes a dynamic logging component
 */
@protocol DDRegisteredDynamicLogging

/**
 * Implement these methods to allow a file's log level to be managed from a central location.
 *
 * This is useful if you'd like to be able to change log levels for various parts
 * of your code from within the running application.
 *
 * Imagine pulling up the settings for your application,
 * and being able to configure the logging level on a per file basis.
 *
 * The implementation can be very straight-forward:
 *
 * ```
 * + (int)ddLogLevel
 * {
 *     return ddLogLevel;
 * }
 *
 * + (void)ddSetLogLevel:(DDLogLevel)level
 * {
 *     ddLogLevel = level;
 * }
 * ```
 **/
+ (DDLogLevel)ddLogLevel;

/**
 *  See the above description for `ddLogLevel`
 */
+ (void)ddSetLogLevel:(DDLogLevel)level;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef NS_DESIGNATED_INITIALIZER
    #define NS_DESIGNATED_INITIALIZER
#endif

/**
 *  Log message options, allow copying certain log elements
 */
typedef NS_OPTIONS(NSInteger, DDLogMessageOptions){
    /**
     *  Use this to use a copy of the file path
     */
    DDLogMessageCopyFile     = 1 << 0,
    /**
     *  Use this to use a copy of the function name
     */
    DDLogMessageCopyFunction = 1 << 1
};

/**
 * The `DDLogMessage` class encapsulates information about the log message.
 * If you write custom loggers or formatters, you will be dealing with objects of this class.
 **/
@interface DDLogMessage : NSObject <NSCopying>
{
    // Direct accessors to be used only for performance
    @public
    NSString *_message;
    DDLogLevel _level;
    DDLogFlag _flag;
    NSInteger _context;
    NSString *_file;
    NSString *_fileName;
    NSString *_function;
    NSUInteger _line;
    id _tag;
    DDLogMessageOptions _options;
    NSDate *_timestamp;
    NSString *_threadID;
    NSString *_threadName;
    NSString *_queueLabel;
}

/**
 *  Default `init` is not available
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Standard init method for a log message object.
 * Used by the logging primitives. (And the macros use the logging primitives.)
 *
 * If you find need to manually create logMessage objects, there is one thing you should be aware of:
 *
 * If no flags are passed, the method expects the file and function parameters to be string literals.
 * That is, it expects the given strings to exist for the duration of the object's lifetime,
 * and it expects the given strings to be immutable.
 * In other words, it does not copy these strings, it simply points to them.
 * This is due to the fact that __FILE__ and __FUNCTION__ are usually used to specify these parameters,
 * so it makes sense to optimize and skip the unnecessary allocations.
 * However, if you need them to be copied you may use the options parameter to specify this.
 *
 *  @param message   the message
 *  @param level     the log level
 *  @param flag      the log flag
 *  @param context   the context (if any is defined)
 *  @param file      the current file
 *  @param function  the current function
 *  @param line      the current code line
 *  @param tag       potential tag
 *  @param options   a bitmask which supports DDLogMessageCopyFile and DDLogMessageCopyFunction.
 *  @param timestamp the log timestamp
 *
 *  @return a new instance of a log message model object
 */
- (instancetype)initWithMessage:(NSString *)message
                          level:(DDLogLevel)level
                           flag:(DDLogFlag)flag
                        context:(NSInteger)context
                           file:(NSString *)file
                       function:(NSString *)function
                           line:(NSUInteger)line
                            tag:(id)tag
                        options:(DDLogMessageOptions)options
                      timestamp:(NSDate *)timestamp NS_DESIGNATED_INITIALIZER;

/**
 * Read-only properties
 **/

/**
 *  The log message
 */
@property (readonly, nonatomic) NSString *message;
@property (readonly, nonatomic) DDLogLevel level;
@property (readonly, nonatomic) DDLogFlag flag;
@property (readonly, nonatomic) NSInteger context;
@property (readonly, nonatomic) NSString *file;
@property (readonly, nonatomic) NSString *fileName;
@property (readonly, nonatomic) NSString *function;
@property (readonly, nonatomic) NSUInteger line;
@property (readonly, nonatomic) id tag;
@property (readonly, nonatomic) DDLogMessageOptions options;
@property (readonly, nonatomic) NSDate *timestamp;
@property (readonly, nonatomic) NSString *threadID; // ID as it appears in NSLog calculated from the machThreadID
@property (readonly, nonatomic) NSString *threadName;
@property (readonly, nonatomic) NSString *queueLabel;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * The `DDLogger` protocol specifies that an optional formatter can be added to a logger.
 * Most (but not all) loggers will want to support formatters.
 *
 * However, writting getters and setters in a thread safe manner,
 * while still maintaining maximum speed for the logging process, is a difficult task.
 *
 * To do it right, the implementation of the getter/setter has strict requiremenets:
 * - Must NOT require the `logMessage:` method to acquire a lock.
 * - Must NOT require the `logMessage:` method to access an atomic property (also a lock of sorts).
 *
 * To simplify things, an abstract logger is provided that implements the getter and setter.
 *
 * Logger implementations may simply extend this class,
 * and they can ACCESS THE FORMATTER VARIABLE DIRECTLY from within their `logMessage:` method!
 **/
@interface DDAbstractLogger : NSObject <DDLogger>
{
    // Direct accessors to be used only for performance
    @public
    id <DDLogFormatter> _logFormatter;
    dispatch_queue_t _loggerQueue;
}

@property (nonatomic, strong) id <DDLogFormatter> logFormatter;
@property (nonatomic, DISPATCH_QUEUE_REFERENCE_TYPE) dispatch_queue_t loggerQueue;

// For thread-safety assertions

/**
 *  Return YES if the current logger uses a global queue for logging
 */
@property (nonatomic, readonly, getter=isOnGlobalLoggingQueue)  BOOL onGlobalLoggingQueue;

/**
 *  Return YES if the current logger uses the internal designated queue for logging
 */
@property (nonatomic, readonly, getter=isOnInternalLoggerQueue) BOOL onInternalLoggerQueue;

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

// Disable legacy macros
#ifndef DD_LEGACY_MACROS
    #define DD_LEGACY_MACROS 0
#endif

/**
 * The constant/variable/method responsible for controlling the current log level.
 **/
#ifndef LOG_LEVEL_DEF
    #define LOG_LEVEL_DEF ddLogLevel
#endif

/**
 * Whether async should be used by log messages, excluding error messages that are always sent sync.
 **/
#ifndef LOG_ASYNC_ENABLED
    #define LOG_ASYNC_ENABLED YES
#endif

/**
 * These are the two macros that all other macros below compile into.
 * These big multiline macros makes all the other macros easier to read.
 **/
#define LOG_MACRO(isAsynchronous, lvl, flg, ctx, atag, fnct, frmt, ...) \
        [DDLog log : isAsynchronous                                     \
             level : lvl                                                \
              flag : flg                                                \
           context : ctx                                                \
              file : __FILE__                                           \
          function : fnct                                               \
              line : __LINE__                                           \
               tag : atag                                               \
            format : (frmt), ## __VA_ARGS__]

#define LOG_MACRO_TO_DDLOG(ddlog, isAsynchronous, lvl, flg, ctx, atag, fnct, frmt, ...) \
        [ddlog log : isAsynchronous                                     \
             level : lvl                                                \
              flag : flg                                                \
           context : ctx                                                \
              file : __FILE__                                           \
          function : fnct                                               \
              line : __LINE__                                           \
               tag : atag                                               \
            format : (frmt), ## __VA_ARGS__]

/**
 * Define version of the macro that only execute if the log level is above the threshold.
 * The compiled versions essentially look like this:
 *
 * if (logFlagForThisLogMsg & ddLogLevel) { execute log message }
 *
 * When LOG_LEVEL_DEF is defined as ddLogLevel.
 *
 * As shown further below, Lumberjack actually uses a bitmask as opposed to primitive log levels.
 * This allows for a great amount of flexibility and some pretty advanced fine grained logging techniques.
 *
 * Note that when compiler optimizations are enabled (as they are for your release builds),
 * the log messages above your logging threshold will automatically be compiled out.
 *
 * (If the compiler sees LOG_LEVEL_DEF/ddLogLevel declared as a constant, the compiler simply checks to see
 *  if the 'if' statement would execute, and if not it strips it from the binary.)
 *
 * We also define shorthand versions for asynchronous and synchronous logging.
 **/
#define LOG_MAYBE(async, lvl, flg, ctx, tag, fnct, frmt, ...) \
        do { if(lvl & flg) LOG_MACRO(async, lvl, flg, ctx, tag, fnct, frmt, ##__VA_ARGS__); } while(0)

#define LOG_MAYBE_TO_DDLOG(ddlog, async, lvl, flg, ctx, tag, fnct, frmt, ...) \
        do { if(lvl & flg) LOG_MACRO_TO_DDLOG(ddlog, async, lvl, flg, ctx, tag, fnct, frmt, ##__VA_ARGS__); } while(0)

/**
 * Ready to use log macros with no context or tag.
 **/
#define DDLogError(frmt, ...)   LOG_MAYBE(NO,                LOG_LEVEL_DEF, DDLogFlagError,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogWarn(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagWarning, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogInfo(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagInfo,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogDebug(frmt, ...)   LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagDebug,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogVerbose(frmt, ...) LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagVerbose, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define DDLogErrorToDDLog(ddlog, frmt, ...)   LOG_MAYBE_TO_DDLOG(ddlog, NO,                LOG_LEVEL_DEF, DDLogFlagError,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogWarnToDDLog(ddlog, frmt, ...)    LOG_MAYBE_TO_DDLOG(ddlog, LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagWarning, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogInfoToDDLog(ddlog, frmt, ...)    LOG_MAYBE_TO_DDLOG(ddlog, LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagInfo,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogDebugToDDLog(ddlog, frmt, ...)   LOG_MAYBE_TO_DDLOG(ddlog, LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagDebug,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogVerboseToDDLog(ddlog, frmt, ...) LOG_MAYBE_TO_DDLOG(ddlog, LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagVerbose, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
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

/**
 * NSAsset replacement that will output a log message even when assertions are disabled.
 **/
#define DDAssert(condition, frmt, ...)                                                \
        if (!(condition)) {                                                           \
            NSString *description = [NSString stringWithFormat:frmt, ## __VA_ARGS__]; \
            DDLogError(@"%@", description);                                           \
            NSAssert(NO, description);                                                \
        }
#define DDAssertCondition(condition) DDAssert(condition, @"Condition not satisfied: %s", #condition)

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


@protocol DDLogger;

/**
 *  This class provides the ability to capture the ASL (Apple System Logs)
 */
@interface DDASLLogCapture : NSObject

/**
 *  Start capturing logs
 */
+ (void)start;

/**
 *  Stop capturing logs
 */
+ (void)stop;

/**
 *  Returns the current capture level.
 *  @note Default log level: DDLogLevelVerbose (i.e. capture all ASL messages).
 */
+ (DDLogLevel)captureLevel;

/**
 *  Set the capture level
 *
 *  @param level new level
 */
+ (void)setCaptureLevel:(DDLogLevel)level;

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

// Disable legacy macros
#ifndef DD_LEGACY_MACROS
    #define DD_LEGACY_MACROS 0
#endif

#define LOG_CONTEXT_ALL INT_MAX

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
#if TARGET_OS_IPHONE
    // iOS
    #import <UIKit/UIColor.h>
    typedef UIColor DDColor;
    static inline DDColor* DDMakeColor(CGFloat r, CGFloat g, CGFloat b) {return [DDColor colorWithRed:(r/255.0f) green:(g/255.0f) blue:(b/255.0f) alpha:1.0f];}
#elif defined(DD_CLI) || !__has_include(<AppKit/NSColor.h>)
    // OS X CLI
    #import "CLIColor.h"
    typedef CLIColor DDColor;
    static inline DDColor* DDMakeColor(CGFloat r, CGFloat g, CGFloat b) {return [DDColor colorWithCalibratedRed:(r/255.0f) green:(g/255.0f) blue:(b/255.0f) alpha:1.0f];}
#else
    // OS X with AppKit
    #import <AppKit/NSColor.h>
    typedef NSColor DDColor;
    static inline DDColor* DDMakeColor(CGFloat r, CGFloat g, CGFloat b) {return [DDColor colorWithCalibratedRed:(r/255.0f) green:(g/255.0f) blue:(b/255.0f) alpha:1.0f];}
#endif
#pragma clang diagnostic pop


/**
 * This class provides a logger for Terminal output or Xcode console output,
 * depending on where you are running your code.
 *
 * As described in the "Getting Started" page,
 * the traditional NSLog() function directs it's output to two places:
 *
 * - Apple System Log (so it shows up in Console.app)
 * - StdErr (if stderr is a TTY, so log statements show up in Xcode console)
 *
 * To duplicate NSLog() functionality you can simply add this logger and an asl logger.
 * However, if you instead choose to use file logging (for faster performance),
 * you may choose to use only a file logger and a tty logger.
 **/
@interface DDTTYLogger : DDAbstractLogger <DDLogger>

/**
 *  Singleton method
 */
+ (instancetype)sharedInstance;

/* Inherited from the DDLogger protocol:
 *
 * Formatters may optionally be added to any logger.
 *
 * If no formatter is set, the logger simply logs the message as it is given in logMessage,
 * or it may use its own built in formatting style.
 *
 * More information about formatters can be found here:
 * Documentation/CustomFormatters.md
 *
 * The actual implementation of these methods is inherited from DDAbstractLogger.

   - (id <DDLogFormatter>)logFormatter;
   - (void)setLogFormatter:(id <DDLogFormatter>)formatter;

 */

/**
 * Want to use different colors for different log levels?
 * Enable this property.
 *
 * If you run the application via the Terminal (not Xcode),
 * the logger will map colors to xterm-256color or xterm-color (if available).
 *
 * Xcode does NOT natively support colors in the Xcode debugging console.
 * You'll need to install the XcodeColors plugin to see colors in the Xcode console.
 * https://github.com/robbiehanson/XcodeColors
 *
 * The default value is NO.
 **/
@property (readwrite, assign) BOOL colorsEnabled;

/**
 * When using a custom formatter you can set the `logMessage` method not to append
 * `\n` character after each output. This allows for some greater flexibility with
 * custom formatters. Default value is YES.
 **/
@property (nonatomic, readwrite, assign) BOOL automaticallyAppendNewlineForCustomFormatters;

/**
 * The default color set (foregroundColor, backgroundColor) is:
 *
 * - DDLogFlagError   = (red, nil)
 * - DDLogFlagWarning = (orange, nil)
 *
 * You can customize the colors however you see fit.
 * Please note that you are passing a flag, NOT a level.
 *
 * GOOD : [ttyLogger setForegroundColor:pink backgroundColor:nil forFlag:DDLogFlagInfo];  // <- Good :)
 *  BAD : [ttyLogger setForegroundColor:pink backgroundColor:nil forFlag:DDLogLevelInfo]; // <- BAD! :(
 *
 * DDLogFlagInfo  = 0...00100
 * DDLogLevelInfo = 0...00111 <- Would match DDLogFlagInfo and DDLogFlagWarning and DDLogFlagError
 *
 * If you run the application within Xcode, then the XcodeColors plugin is required.
 *
 * If you run the application from a shell, then DDTTYLogger will automatically map the given color to
 * the closest available color. (xterm-256color or xterm-color which have 256 and 16 supported colors respectively.)
 *
 * This method invokes setForegroundColor:backgroundColor:forFlag:context: and applies it to `LOG_CONTEXT_ALL`.
 **/
- (void)setForegroundColor:(DDColor *)txtColor backgroundColor:(DDColor *)bgColor forFlag:(DDLogFlag)mask;

/**
 * Just like setForegroundColor:backgroundColor:flag, but allows you to specify a particular logging context.
 *
 * A logging context is often used to identify log messages coming from a 3rd party framework,
 * although logging context's can be used for many different functions.
 *
 * Use LOG_CONTEXT_ALL to set the deafult color for all contexts that have no specific color set defined.
 *
 * Logging context's are explained in further detail here:
 * Documentation/CustomContext.md
 **/
- (void)setForegroundColor:(DDColor *)txtColor backgroundColor:(DDColor *)bgColor forFlag:(DDLogFlag)mask context:(NSInteger)ctxt;

/**
 * Similar to the methods above, but allows you to map DDLogMessage->tag to a particular color profile.
 * For example, you could do something like this:
 *
 * static NSString *const PurpleTag = @"PurpleTag";
 *
 * #define DDLogPurple(frmt, ...) LOG_OBJC_TAG_MACRO(NO, 0, 0, 0, PurpleTag, frmt, ##__VA_ARGS__)
 * 
 * And then where you configure CocoaLumberjack:
 *
 * purple = DDMakeColor((64/255.0), (0/255.0), (128/255.0));
 *
 * or any UIColor/NSColor constructor.
 *
 * Note: For CLI OS X projects that don't link with AppKit use CLIColor objects instead
 *
 * [[DDTTYLogger sharedInstance] setForegroundColor:purple backgroundColor:nil forTag:PurpleTag];
 * [DDLog addLogger:[DDTTYLogger sharedInstance]];
 *
 * This would essentially give you a straight NSLog replacement that prints in purple:
 *
 * DDLogPurple(@"I'm a purple log message!");
 **/
- (void)setForegroundColor:(DDColor *)txtColor backgroundColor:(DDColor *)bgColor forTag:(id <NSCopying>)tag;

/**
 * Clearing color profiles.
 **/
- (void)clearColorsForFlag:(DDLogFlag)mask;
- (void)clearColorsForFlag:(DDLogFlag)mask context:(NSInteger)context;
- (void)clearColorsForTag:(id <NSCopying>)tag;
- (void)clearColorsForAllFlags;
- (void)clearColorsForAllTags;
- (void)clearAllColors;

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

#import <Foundation/Foundation.h>

// Disable legacy macros
#ifndef DD_LEGACY_MACROS
    #define DD_LEGACY_MACROS 0
#endif

// Custom key set on messages sent to ASL
extern const char* const kDDASLKeyDDLog;

// Value set for kDDASLKeyDDLog
extern const char* const kDDASLDDLogValue;

/**
 * This class provides a logger for the Apple System Log facility.
 *
 * As described in the "Getting Started" page,
 * the traditional NSLog() function directs its output to two places:
 *
 * - Apple System Log
 * - StdErr (if stderr is a TTY) so log statements show up in Xcode console
 *
 * To duplicate NSLog() functionality you can simply add this logger and a tty logger.
 * However, if you instead choose to use file logging (for faster performance),
 * you may choose to use a file logger and a tty logger.
 **/
@interface DDASLLogger : DDAbstractLogger <DDLogger>

/**
 *  Singleton method
 *
 *  @return the shared instance
 */
+ (instancetype)sharedInstance;

// Inherited from DDAbstractLogger

// - (id <DDLogFormatter>)logFormatter;
// - (void)setLogFormatter:(id <DDLogFormatter>)formatter;

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

// Disable legacy macros
#ifndef DD_LEGACY_MACROS
    #define DD_LEGACY_MACROS 0
#endif

@class DDLogFileInfo;

/**
 * This class provides a logger to write log statements to a file.
 **/


// Default configuration and safety/sanity values.
//
// maximumFileSize         -> kDDDefaultLogMaxFileSize
// rollingFrequency        -> kDDDefaultLogRollingFrequency
// maximumNumberOfLogFiles -> kDDDefaultLogMaxNumLogFiles
// logFilesDiskQuota       -> kDDDefaultLogFilesDiskQuota
//
// You should carefully consider the proper configuration values for your application.

extern unsigned long long const kDDDefaultLogMaxFileSize;
extern NSTimeInterval     const kDDDefaultLogRollingFrequency;
extern NSUInteger         const kDDDefaultLogMaxNumLogFiles;
extern unsigned long long const kDDDefaultLogFilesDiskQuota;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 *  The LogFileManager protocol is designed to allow you to control all aspects of your log files.
 *
 *  The primary purpose of this is to allow you to do something with the log files after they have been rolled.
 *  Perhaps you want to compress them to save disk space.
 *  Perhaps you want to upload them to an FTP server.
 *  Perhaps you want to run some analytics on the file.
 *
 *  A default LogFileManager is, of course, provided.
 *  The default LogFileManager simply deletes old log files according to the maximumNumberOfLogFiles property.
 *
 *  This protocol provides various methods to fetch the list of log files.
 *
 *  There are two variants: sorted and unsorted.
 *  If sorting is not necessary, the unsorted variant is obviously faster.
 *  The sorted variant will return an array sorted by when the log files were created,
 *  with the most recently created log file at index 0, and the oldest log file at the end of the array.
 *
 *  You can fetch only the log file paths (full path including name), log file names (name only),
 *  or an array of `DDLogFileInfo` objects.
 *  The `DDLogFileInfo` class is documented below, and provides a handy wrapper that
 *  gives you easy access to various file attributes such as the creation date or the file size.
 */
@protocol DDLogFileManager <NSObject>
@required

// Public properties

/**
 * The maximum number of archived log files to keep on disk.
 * For example, if this property is set to 3,
 * then the LogFileManager will only keep 3 archived log files (plus the current active log file) on disk.
 * Once the active log file is rolled/archived, then the oldest of the existing 3 rolled/archived log files is deleted.
 *
 * You may optionally disable this option by setting it to zero.
 **/
@property (readwrite, assign, atomic) NSUInteger maximumNumberOfLogFiles;

/**
 * The maximum space that logs can take. On rolling logfile all old logfiles that exceed logFilesDiskQuota will
 * be deleted.
 *
 * You may optionally disable this option by setting it to zero.
 **/
@property (readwrite, assign, atomic) unsigned long long logFilesDiskQuota;

// Public methods

/**
 *  Returns the logs directory (path)
 */
- (NSString *)logsDirectory;

/**
 * Returns an array of `NSString` objects,
 * each of which is the filePath to an existing log file on disk.
 **/
- (NSArray *)unsortedLogFilePaths;

/**
 * Returns an array of `NSString` objects,
 * each of which is the fileName of an existing log file on disk.
 **/
- (NSArray *)unsortedLogFileNames;

/**
 * Returns an array of `DDLogFileInfo` objects,
 * each representing an existing log file on disk,
 * and containing important information about the log file such as it's modification date and size.
 **/
- (NSArray *)unsortedLogFileInfos;

/**
 * Just like the `unsortedLogFilePaths` method, but sorts the array.
 * The items in the array are sorted by creation date.
 * The first item in the array will be the most recently created log file.
 **/
- (NSArray *)sortedLogFilePaths;

/**
 * Just like the `unsortedLogFileNames` method, but sorts the array.
 * The items in the array are sorted by creation date.
 * The first item in the array will be the most recently created log file.
 **/
- (NSArray *)sortedLogFileNames;

/**
 * Just like the `unsortedLogFileInfos` method, but sorts the array.
 * The items in the array are sorted by creation date.
 * The first item in the array will be the most recently created log file.
 **/
- (NSArray *)sortedLogFileInfos;

// Private methods (only to be used by DDFileLogger)

/**
 * Generates a new unique log file path, and creates the corresponding log file.
 **/
- (NSString *)createNewLogFile;

@optional

// Notifications from DDFileLogger

/**
 *  Called when a log file was archieved
 */
- (void)didArchiveLogFile:(NSString *)logFilePath;

/**
 *  Called when the roll action was executed and the log was archieved
 */
- (void)didRollAndArchiveLogFile:(NSString *)logFilePath;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Default log file manager.
 *
 * All log files are placed inside the logsDirectory.
 * If a specific logsDirectory isn't specified, the default directory is used.
 * On Mac, this is in `~/Library/Logs/<Application Name>`.
 * On iPhone, this is in `~/Library/Caches/Logs`.
 *
 * Log files are named `"<bundle identifier> <date> <time>.log"`
 * Example: `com.organization.myapp 2013-12-03 17-14.log`
 *
 * Archived log files are automatically deleted according to the `maximumNumberOfLogFiles` property.
 **/
@interface DDLogFileManagerDefault : NSObject <DDLogFileManager>

/**
 *  Default initializer
 */
- (instancetype)init;

/**
 *  Designated initialized, requires the logs directory
 */
- (instancetype)initWithLogsDirectory:(NSString *)logsDirectory NS_DESIGNATED_INITIALIZER;

#if TARGET_OS_IPHONE
/*
 * Calling this constructor you can override the default "automagically" chosen NSFileProtection level.
 * Useful if you are writing a command line utility / CydiaSubstrate addon for iOS that has no NSBundle
 * or like SpringBoard no BackgroundModes key in the NSBundle:
 *    iPhone:~ root# cycript -p SpringBoard
 *    cy# [NSBundle mainBundle]
 *    #"NSBundle </System/Library/CoreServices/SpringBoard.app> (loaded)"
 *    cy# [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"];
 *    null
 *    cy#
 **/
- (instancetype)initWithLogsDirectory:(NSString *)logsDirectory defaultFileProtectionLevel:(NSString *)fileProtectionLevel;
#endif

/*
 * Methods to override.
 *
 * Log files are named `"<bundle identifier> <date> <time>.log"`
 * Example: `com.organization.myapp 2013-12-03 17-14.log`
 *
 * If you wish to change default filename, you can override following two methods.
 * - `newLogFileName` method would be called on new logfile creation.
 * - `isLogFile:` method would be called to filter logfiles from all other files in logsDirectory.
 *   You have to parse given filename and return YES if it is logFile.
 *
 * **NOTE**
 * `newLogFileName` returns filename. If appropriate file already exists, number would be added
 * to filename before extension. You have to handle this case in isLogFile: method.
 *
 * Example:
 * - newLogFileName returns `"com.organization.myapp 2013-12-03.log"`,
 *   file `"com.organization.myapp 2013-12-03.log"` would be created.
 * - after some time `"com.organization.myapp 2013-12-03.log"` is archived
 * - newLogFileName again returns `"com.organization.myapp 2013-12-03.log"`,
 *   file `"com.organization.myapp 2013-12-03 2.log"` would be created.
 * - after some time `"com.organization.myapp 2013-12-03 1.log"` is archived
 * - newLogFileName again returns `"com.organization.myapp 2013-12-03.log"`,
 *   file `"com.organization.myapp 2013-12-03 3.log"` would be created.
 **/

/**
 * Generates log file name with default format `"<bundle identifier> <date> <time>.log"`
 * Example: `MobileSafari 2013-12-03 17-14.log`
 *
 * You can change it by overriding `newLogFileName` and `isLogFile:` methods.
 **/
@property (readonly, copy) NSString *newLogFileName;

/**
 * Default log file name is `"<bundle identifier> <date> <time>.log"`.
 * Example: `MobileSafari 2013-12-03 17-14.log`
 *
 * You can change it by overriding `newLogFileName` and `isLogFile:` methods.
 **/
- (BOOL)isLogFile:(NSString *)fileName;

/* Inherited from DDLogFileManager protocol:

   @property (readwrite, assign, atomic) NSUInteger maximumNumberOfLogFiles;
   @property (readwrite, assign, atomic) NSUInteger logFilesDiskQuota;

   - (NSString *)logsDirectory;

   - (NSArray *)unsortedLogFilePaths;
   - (NSArray *)unsortedLogFileNames;
   - (NSArray *)unsortedLogFileInfos;

   - (NSArray *)sortedLogFilePaths;
   - (NSArray *)sortedLogFileNames;
   - (NSArray *)sortedLogFileInfos;

 */

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Most users will want file log messages to be prepended with the date and time.
 * Rather than forcing the majority of users to write their own formatter,
 * we will supply a logical default formatter.
 * Users can easily replace this formatter with their own by invoking the `setLogFormatter:` method.
 * It can also be removed by calling `setLogFormatter:`, and passing a nil parameter.
 *
 * In addition to the convenience of having a logical default formatter,
 * it will also provide a template that makes it easy for developers to copy and change.
 **/
@interface DDLogFileFormatterDefault : NSObject <DDLogFormatter>

/**
 *  Default initializer
 */
- (instancetype)init;

/**
 *  Designated initializer, requires a date formatter
 */
- (instancetype)initWithDateFormatter:(NSDateFormatter *)dateFormatter NS_DESIGNATED_INITIALIZER;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 *  The standard implementation for a file logger
 */
@interface DDFileLogger : DDAbstractLogger <DDLogger>

/**
 *  Default initializer
 */
- (instancetype)init;

/**
 *  Designated initializer, requires a `DDLogFileManager` instance
 */
- (instancetype)initWithLogFileManager:(id <DDLogFileManager>)logFileManager NS_DESIGNATED_INITIALIZER;

/**
 * Log File Rolling:
 *
 * `maximumFileSize`:
 *   The approximate maximum size (in bytes) to allow log files to grow.
 *   If a log file is larger than this value after a log statement is appended,
 *   then the log file is rolled.
 *
 * `rollingFrequency`
 *   How often to roll the log file.
 *   The frequency is given as an `NSTimeInterval`, which is a double that specifies the interval in seconds.
 *   Once the log file gets to be this old, it is rolled.
 *
 * `doNotReuseLogFiles`
 *   When set, will always create a new log file at application launch.
 *
 * Both the `maximumFileSize` and the `rollingFrequency` are used to manage rolling.
 * Whichever occurs first will cause the log file to be rolled.
 *
 * For example:
 * The `rollingFrequency` is 24 hours,
 * but the log file surpasses the `maximumFileSize` after only 20 hours.
 * The log file will be rolled at that 20 hour mark.
 * A new log file will be created, and the 24 hour timer will be restarted.
 *
 * You may optionally disable rolling due to filesize by setting `maximumFileSize` to zero.
 * If you do so, rolling is based solely on `rollingFrequency`.
 *
 * You may optionally disable rolling due to time by setting `rollingFrequency` to zero (or any non-positive number).
 * If you do so, rolling is based solely on `maximumFileSize`.
 *
 * If you disable both `maximumFileSize` and `rollingFrequency`, then the log file won't ever be rolled.
 * This is strongly discouraged.
 **/
@property (readwrite, assign) unsigned long long maximumFileSize;

/**
 *  See description for `maximumFileSize`
 */
@property (readwrite, assign) NSTimeInterval rollingFrequency;

/**
 *  See description for `maximumFileSize`
 */
@property (readwrite, assign, atomic) BOOL doNotReuseLogFiles;

/**
 * The DDLogFileManager instance can be used to retrieve the list of log files,
 * and configure the maximum number of archived log files to keep.
 *
 * @see DDLogFileManager.maximumNumberOfLogFiles
 **/
@property (strong, nonatomic, readonly) id <DDLogFileManager> logFileManager;

/**
 * When using a custom formatter you can set the `logMessage` method not to append
 * `\n` character after each output. This allows for some greater flexibility with
 * custom formatters. Default value is YES.
 **/
@property (nonatomic, readwrite, assign) BOOL automaticallyAppendNewlineForCustomFormatters;

/**
 *  You can optionally force the current log file to be rolled with this method.
 *  CompletionBlock will be called on main queue.
 */
- (void)rollLogFileWithCompletionBlock:(void (^)())completionBlock;

/**
 *  Method is deprecated.
 *  @deprecated Use `rollLogFileWithCompletionBlock:` method instead.
 */
- (void)rollLogFile __attribute((deprecated));

// Inherited from DDAbstractLogger

// - (id <DDLogFormatter>)logFormatter;
// - (void)setLogFormatter:(id <DDLogFormatter>)formatter;

/**
 * Returns the log file that should be used.
 * If there is an existing log file that is suitable,
 * within the constraints of `maximumFileSize` and `rollingFrequency`, then it is returned.
 *
 * Otherwise a new file is created and returned.
 **/
- (DDLogFileInfo *)currentLogFileInfo;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * `DDLogFileInfo` is a simple class that provides access to various file attributes.
 * It provides good performance as it only fetches the information if requested,
 * and it caches the information to prevent duplicate fetches.
 *
 * It was designed to provide quick snapshots of the current state of log files,
 * and to help sort log files in an array.
 *
 * This class does not monitor the files, or update it's cached attribute values if the file changes on disk.
 * This is not what the class was designed for.
 *
 * If you absolutely must get updated values,
 * you can invoke the reset method which will clear the cache.
 **/
@interface DDLogFileInfo : NSObject

@property (strong, nonatomic, readonly) NSString *filePath;
@property (strong, nonatomic, readonly) NSString *fileName;

@property (strong, nonatomic, readonly) NSDictionary *fileAttributes;

@property (strong, nonatomic, readonly) NSDate *creationDate;
@property (strong, nonatomic, readonly) NSDate *modificationDate;

@property (nonatomic, readonly) unsigned long long fileSize;

@property (nonatomic, readonly) NSTimeInterval age;

@property (nonatomic, readwrite) BOOL isArchived;

+ (instancetype)logFileWithPath:(NSString *)filePath;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFilePath:(NSString *)filePath NS_DESIGNATED_INITIALIZER;

- (void)reset;
- (void)renameFile:(NSString *)newFileName;

#if TARGET_IPHONE_SIMULATOR

// So here's the situation.
// Extended attributes are perfect for what we're trying to do here (marking files as archived).
// This is exactly what extended attributes were designed for.
//
// But Apple screws us over on the simulator.
// Everytime you build-and-go, they copy the application into a new folder on the hard drive,
// and as part of the process they strip extended attributes from our log files.
// Normally, a copy of a file preserves extended attributes.
// So obviously Apple has gone to great lengths to piss us off.
//
// Thus we use a slightly different tactic for marking log files as archived in the simulator.
// That way it "just works" and there's no confusion when testing.
//
// The difference in method names is indicative of the difference in functionality.
// On the simulator we add an attribute by appending a filename extension.
//
// For example:
// "mylog.txt" -> "mylog.archived.txt"
// "mylog"     -> "mylog.archived"

- (BOOL)hasExtensionAttributeWithName:(NSString *)attrName;

- (void)addExtensionAttributeWithName:(NSString *)attrName;
- (void)removeExtensionAttributeWithName:(NSString *)attrName;

#else /* if TARGET_IPHONE_SIMULATOR */

// Normal use of extended attributes used everywhere else,
// such as on Macs and on iPhone devices.

- (BOOL)hasExtendedAttributeWithName:(NSString *)attrName;

- (void)addExtendedAttributeWithName:(NSString *)attrName;
- (void)removeExtendedAttributeWithName:(NSString *)attrName;

#endif /* if TARGET_IPHONE_SIMULATOR */

- (NSComparisonResult)reverseCompareByCreationDate:(DDLogFileInfo *)another;
- (NSComparisonResult)reverseCompareByModificationDate:(DDLogFileInfo *)another;

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

// Disable legacy macros
#ifndef DD_LEGACY_MACROS
    #define DD_LEGACY_MACROS 0
#endif

/**
 * This class provides an abstract implementation of a database logger.
 *
 * That is, it provides the base implementation for a database logger to build atop of.
 * All that is needed for a concrete database logger is to extend this class
 * and override the methods in the implementation file that are prefixed with "db_".
 **/
@interface DDAbstractDatabaseLogger : DDAbstractLogger {
    
@protected
    NSUInteger _saveThreshold;
    NSTimeInterval _saveInterval;
    NSTimeInterval _maxAge;
    NSTimeInterval _deleteInterval;
    BOOL _deleteOnEverySave;
    
    BOOL _saveTimerSuspended;
    NSUInteger _unsavedCount;
    dispatch_time_t _unsavedTime;
    dispatch_source_t _saveTimer;
    dispatch_time_t _lastDeleteTime;
    dispatch_source_t _deleteTimer;
}

/**
 * Specifies how often to save the data to disk.
 * Since saving is an expensive operation (disk io) it is not done after every log statement.
 * These properties allow you to configure how/when the logger saves to disk.
 *
 * A save is done when either (whichever happens first):
 *
 * - The number of unsaved log entries reaches saveThreshold
 * - The amount of time since the oldest unsaved log entry was created reaches saveInterval
 *
 * You can optionally disable the saveThreshold by setting it to zero.
 * If you disable the saveThreshold you are entirely dependent on the saveInterval.
 *
 * You can optionally disable the saveInterval by setting it to zero (or a negative value).
 * If you disable the saveInterval you are entirely dependent on the saveThreshold.
 *
 * It's not wise to disable both saveThreshold and saveInterval.
 *
 * The default saveThreshold is 500.
 * The default saveInterval is 60 seconds.
 **/
@property (assign, readwrite) NSUInteger saveThreshold;

/**
 *  See the description for the `saveThreshold` property
 */
@property (assign, readwrite) NSTimeInterval saveInterval;

/**
 * It is likely you don't want the log entries to persist forever.
 * Doing so would allow the database to grow infinitely large over time.
 *
 * The maxAge property provides a way to specify how old a log statement can get
 * before it should get deleted from the database.
 *
 * The deleteInterval specifies how often to sweep for old log entries.
 * Since deleting is an expensive operation (disk io) is is done on a fixed interval.
 *
 * An alternative to the deleteInterval is the deleteOnEverySave option.
 * This specifies that old log entries should be deleted during every save operation.
 *
 * You can optionally disable the maxAge by setting it to zero (or a negative value).
 * If you disable the maxAge then old log statements are not deleted.
 *
 * You can optionally disable the deleteInterval by setting it to zero (or a negative value).
 *
 * If you disable both deleteInterval and deleteOnEverySave then old log statements are not deleted.
 *
 * It's not wise to enable both deleteInterval and deleteOnEverySave.
 *
 * The default maxAge is 7 days.
 * The default deleteInterval is 5 minutes.
 * The default deleteOnEverySave is NO.
 **/
@property (assign, readwrite) NSTimeInterval maxAge;

/**
 *  See the description for the `maxAge` property
 */
@property (assign, readwrite) NSTimeInterval deleteInterval;

/**
 *  See the description for the `maxAge` property
 */
@property (assign, readwrite) BOOL deleteOnEverySave;

/**
 * Forces a save of any pending log entries (flushes log entries to disk).
 **/
- (void)savePendingLogEntries;

/**
 * Removes any log entries that are older than maxAge.
 **/
- (void)deleteOldLogEntries;

@end
