package com.marianhello.logging;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteException;

import java.io.File;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;

import ch.qos.logback.classic.LoggerContext;
import ch.qos.logback.classic.db.names.ColumnName;
import ch.qos.logback.classic.db.names.DefaultDBNameResolver;
import ch.qos.logback.core.CoreConstants;
import ch.qos.logback.core.android.CommonPathUtil;

public class DBLogReader implements LogReader {

    private DefaultDBNameResolver dbNameResolver;
    private SQLiteDatabase db;

    public Collection<LogEntry> getEntries(Integer limit) {
        try {
            return getDbEntries(limit);
        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }

    private Collection<LogEntry> getDbEntries(Integer limit) throws SQLException {
        Collection<LogEntry> entries = new ArrayList<LogEntry>();

        String packageName = null;
        LoggerContext context = (LoggerContext) org.slf4j.LoggerFactory.getILoggerFactory();

        if (context != null) {
            packageName = context.getProperty(CoreConstants.PACKAGE_NAME_KEY);
        }

        if (packageName == null || packageName.length() == 0) {
            throw new SQLException("Cannot open database without package name");
        }

        boolean dbOpened = false;
        try {
            File dbfile = new File(CommonPathUtil.getDatabaseDirectoryPath(packageName), "logback.db");
            db = SQLiteDatabase.openDatabase(dbfile.getPath(), null, SQLiteDatabase.OPEN_READONLY);
            dbOpened = true;
        } catch (SQLiteException e) {
            throw new SQLException("Cannot open database", e);
        }

        Cursor cursor = null;
        if (dbOpened) {
            try {
                if (dbNameResolver == null) {
                    dbNameResolver = new DefaultDBNameResolver();
                }
                String sql = com.marianhello.logging.SQLBuilder.buildSelectSQL(dbNameResolver);
                cursor = db.rawQuery(sql, new String[] { String.valueOf(limit) });
                while (cursor.moveToNext()) {
                    entries.add(hydrate(cursor));
                }
            } catch (SQLiteException e) {
                throw new SQLException("Cannot retrieve log entries", e);
            } finally {
                if (cursor != null) {
                    cursor.close();
                }
                if (db != null) {
                    db.close();
                }
            }
        }

        return entries;
    }

    private LogEntry hydrate(Cursor c) {
        LogEntry entry = new LogEntry();
        entry.setContext(0);
        entry.setLevel(c.getString(c.getColumnIndex(dbNameResolver.getColumnName(ColumnName.LEVEL_STRING))));
        entry.setMessage(c.getString(c.getColumnIndex(dbNameResolver.getColumnName(ColumnName.FORMATTED_MESSAGE))));
        entry.setTimestamp(c.getLong(c.getColumnIndex(dbNameResolver.getColumnName(ColumnName.TIMESTMP))));
        entry.setLoggerName(c.getString(c.getColumnIndex(dbNameResolver.getColumnName(ColumnName.LOGGER_NAME))));

        return entry;
    }
}
