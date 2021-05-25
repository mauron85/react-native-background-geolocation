package com.marianhello.logging;

import android.content.Context;

public class UncaughtExceptionLogger implements Thread.UncaughtExceptionHandler {
    private static volatile boolean mIsCrashing = false;
    private static Thread.UncaughtExceptionHandler sDefaultHandler;

    private org.slf4j.Logger logger;

    public UncaughtExceptionLogger(Context context) {
        logger = LoggerManager.getLogger(UncaughtExceptionLogger.class);
    }

    @Override
    public void uncaughtException(Thread thread, Throwable throwable) {
        // prevent accidental loop
        if(mIsCrashing){
            return;
        }

        mIsCrashing = true;
        logger.error("FATAL EXCEPTION: {}", thread.getName(), throwable);
        if (sDefaultHandler != null) {
            sDefaultHandler.uncaughtException(thread, throwable);
        }
    }

    public static void register(Context context) {
        Thread.UncaughtExceptionHandler defaultHandler = Thread.getDefaultUncaughtExceptionHandler();
        if (!(defaultHandler instanceof UncaughtExceptionLogger)) {
            sDefaultHandler = defaultHandler;
            Thread.setDefaultUncaughtExceptionHandler(new UncaughtExceptionLogger(context));
        }
    }
}
