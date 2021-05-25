package com.marianhello.logging;

import java.io.File;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.LoggerContext;
import ch.qos.logback.classic.android.LogcatAppender;
import ch.qos.logback.classic.android.SQLiteAppender;
import ch.qos.logback.classic.encoder.PatternLayoutEncoder;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.Appender;
import ch.qos.logback.core.rolling.RollingFileAppender;
import ch.qos.logback.core.rolling.TimeBasedRollingPolicy;
import ch.qos.logback.core.util.StatusPrinter;

public class LoggerManager {

    public static final String SQLITE_APPENDER_NAME = "sqlite";

    static {
        // reset the default context (which may already have been initialized)
        // since we want to reconfigure it
        LoggerContext context = (LoggerContext) org.slf4j.LoggerFactory.getILoggerFactory();
        context.reset();
        // Disable class packaging data
        // @see https://github.com/tony19/logback-android/issues/171
        context.setPackagingDataEnabled(false);

        PatternLayoutEncoder encoder = new PatternLayoutEncoder();
        encoder.setContext(context);
        encoder.setPattern("%msg");
        encoder.start();

        LogcatAppender logcatAppender = new LogcatAppender();
        logcatAppender.setContext(context);
        logcatAppender.setEncoder(encoder);
        logcatAppender.start();

        ch.qos.logback.classic.Logger root = (ch.qos.logback.classic.Logger) org.slf4j.LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        root.setLevel(Level.TRACE);
        root.addAppender(logcatAppender);
    }

    public static void enableDBLogging() {
        ch.qos.logback.classic.Logger root = (ch.qos.logback.classic.Logger) org.slf4j.LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        if (root.getAppender(SQLITE_APPENDER_NAME) == null) {
            LoggerContext context = (LoggerContext) org.slf4j.LoggerFactory.getILoggerFactory();
            SQLiteAppender appender = new SQLiteAppender();
            appender.setName(SQLITE_APPENDER_NAME);
            appender.setMaxHistory("7 days"); //keep 7 days' worth of history
            appender.setContext(context);
            appender.start();
            root.addAppender(appender);
        }
    }

    public static void disableDBLogging() {
        ch.qos.logback.classic.Logger root = (ch.qos.logback.classic.Logger) org.slf4j.LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        Appender<ILoggingEvent> appender = root.getAppender(SQLITE_APPENDER_NAME);
        if (appender != null) {
            appender.stop();
            root.detachAppender(appender);
        }
    }

    public static org.slf4j.Logger getLogger(Class forClass) {
        return org.slf4j.LoggerFactory.getLogger(forClass);
    }
}
