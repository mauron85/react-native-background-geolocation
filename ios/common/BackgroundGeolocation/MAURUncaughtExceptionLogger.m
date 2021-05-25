//
//  MAURUncaughtExceptionLogger.m
//  BackgroundGeolocation
//
//  Created by Marian Hello on 12/04/2018.
//  Based on https://github.com/kstenerud/KSCrash
//
//  TODO: consider use of https://plcrashreporter.org
//  TODO: consider use of https://github.com/kstenerud/KSCrash
//  TODO: trap SIGSEGV, SIGBUS, … signals
//  https://creativeinaustria.wordpress.com/2008/10/20/crash-reporter-for-iphone-applications-part-2/

#import <Foundation/Foundation.h>
#import "MAURUncaughtExceptionLogger.h"
#import "MAURLogging.h"

static volatile bool g_isEnabled = 0;

/** The exception handler that was in place before we installed ours. */
static NSUncaughtExceptionHandler* g_previousUncaughtExceptionHandler;

void uncaughtExceptionHandler(NSException *exception) {
    if (g_isEnabled) {
        // TODO: store stack trace separately
        DDLogError(@"CRASH: %@ Stack Trace: %@", exception, [exception callStackSymbols]);
    }
    if (g_previousUncaughtExceptionHandler != NULL) {
        g_previousUncaughtExceptionHandler(exception);
    }
}

static void setEnabled(bool isEnabled)
{
    if (isEnabled != g_isEnabled) {
        g_isEnabled = isEnabled;
        if (isEnabled) {
            DDLogDebug(@"Backing up original handler.");
            g_previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler();
            
            DDLogDebug(@"Setting new handler.");
            NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
        }
        else {
            DDLogDebug(@"Restoring original handler.");
            NSSetUncaughtExceptionHandler(g_previousUncaughtExceptionHandler);
        }
    }
}

static bool isEnabled()
{
    return g_isEnabled;
}

MAHUncaughtExceptionLogger* mah_get_uncaught_exception_logger(void)
{
    static MAHUncaughtExceptionLogger logger = {
        .setEnabled = setEnabled,
        .isEnabled = isEnabled
    };
    return &logger;
}
