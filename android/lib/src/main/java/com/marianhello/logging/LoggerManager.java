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
    public static final String ROLLING_FILE_APPENDER_NAME = "rolling";
    public static final String LOG_DIR = "logs";
    public static final String LOG_FILE_NAME = "plugin.log";
    public static final String ARCHIVE_FILE_NAME_PATTERN = "plugin.%d{yyyy-MM-dd}.log";
    public static final String LOG_FILE_PATTERN = "%d{ISO8601} %-5level %logger{0} - %msg%n";

    static {
//        BasicLogcatConfigurator.configureDefaultContext();

        // reset the default context (which may already have been initialized)
        // since we want to reconfigure it
        LoggerContext context = (LoggerContext) org.slf4j.LoggerFactory.getILoggerFactory();
        context.reset();

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

    public static void enableRollingFileLogging() {
        ch.qos.logback.classic.Logger root = (ch.qos.logback.classic.Logger) org.slf4j.LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        if (root.getAppender(ROLLING_FILE_APPENDER_NAME) == null) {
            LoggerContext context = (LoggerContext) org.slf4j.LoggerFactory.getILoggerFactory();

            RollingFileAppender appender = new RollingFileAppender();
            appender.setName(ROLLING_FILE_APPENDER_NAME);
            appender.setAppend(true);
            appender.setContext(context);
            appender.setFile(LOG_DIR + File.separator + LOG_FILE_NAME);

            TimeBasedRollingPolicy<ILoggingEvent> policy = new TimeBasedRollingPolicy<ILoggingEvent>();
            policy.setFileNamePattern(LOG_DIR + File.separator + ARCHIVE_FILE_NAME_PATTERN);
            policy.setMaxHistory(7); //keep 7 days' worth of history
            policy.setParent(appender);
            policy.setContext(context);
            policy.setCleanHistoryOnStart(true);
            policy.start();

            PatternLayoutEncoder encoder = new PatternLayoutEncoder();
            encoder.setPattern(LOG_FILE_PATTERN);
            encoder.setContext(context);
            encoder.start();

            appender.setTriggeringPolicy(policy);
            appender.setEncoder(encoder);
            appender.start();
            root.addAppender(appender);

            StatusPrinter.print(context);
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

    public static void disableRollingFileLogging() {
        ch.qos.logback.classic.Logger root = (ch.qos.logback.classic.Logger) org.slf4j.LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        Appender<ILoggingEvent> appender = root.getAppender(ROLLING_FILE_APPENDER_NAME);
        if (appender != null) {
            appender.stop();
            root.detachAppender(appender);
        }
    }

    public static org.slf4j.Logger getLogger(Class forClass) {
        return org.slf4j.LoggerFactory.getLogger(forClass);
    }
}
