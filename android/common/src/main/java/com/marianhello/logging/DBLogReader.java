package com.marianhello.logging;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteException;

import ru.andremoniy.sqlbuilder.SqlExpression;
import ru.andremoniy.sqlbuilder.SqlSelectStatement;

import org.slf4j.event.Level;

import java.io.File;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;

import ch.qos.logback.classic.LoggerContext;
import ch.qos.logback.classic.db.names.ColumnName;
import ch.qos.logback.classic.db.names.DBNameResolver;
import ch.qos.logback.classic.db.names.DefaultDBNameResolver;
import ch.qos.logback.classic.db.names.TableName;
import ch.qos.logback.core.CoreConstants;
import ch.qos.logback.core.android.CommonPathUtil;

public class DBLogReader {

    public static final String DB_FILENAME = "logback.db";

    private DefaultDBNameResolver mDbNameResolver;
    private SQLiteDatabase mDatabase;

    public static class QueryBuilder {
        DBNameResolver mDbNameResolver;

        public QueryBuilder() {
            mDbNameResolver = new DefaultDBNameResolver();
        }

        public QueryBuilder(DBNameResolver dbNameResolver) {
            mDbNameResolver = dbNameResolver;
        }

        /**
         * Generate array of levels that are same or above provided level
         *
         * @param level
         * @return array of levels that are same or above level
         */
        private Object[] aboveLevel(Level level) {
            ArrayList<String> levels = new ArrayList();
            for (Level l : Level.values()) {
                if (level.compareTo(l) >= 0) {
                    levels.add(l.toString());
                }
            }
            return levels.toArray();
        }

        public String buildStackTraceQuery(int eventId) {
            SqlSelectStatement builder = new SqlSelectStatement();
            builder.column(mDbNameResolver.getColumnName(ColumnName.TRACE_LINE));
            builder.from(mDbNameResolver.getTableName(TableName.LOGGING_EVENT_EXCEPTION));
            builder.where(mDbNameResolver.getColumnName(ColumnName.I), SqlExpression.SqlOperatorEqualTo, Integer.valueOf(eventId));
            builder.orderBy(mDbNameResolver.getColumnName(ColumnName.I));

            return builder.statement();
        }

        public String buildQuery(int limit, int fromLogEntryId, Level minLevel) {
            SqlSelectStatement builder = new SqlSelectStatement();
            builder.columns(new String[]{
                    mDbNameResolver.getColumnName(ColumnName.EVENT_ID),
                    mDbNameResolver.getColumnName(ColumnName.TIMESTMP),
                    mDbNameResolver.getColumnName(ColumnName.FORMATTED_MESSAGE),
                    mDbNameResolver.getColumnName(ColumnName.LOGGER_NAME),
                    mDbNameResolver.getColumnName(ColumnName.LEVEL_STRING),
            });
            builder.from(mDbNameResolver.getTableName(TableName.LOGGING_EVENT));
            builder.where(mDbNameResolver.getColumnName(ColumnName.LEVEL_STRING), SqlExpression.SqlOperatorIn, aboveLevel(minLevel));
            if (fromLogEntryId > 0) {
                if (limit >= 0) {
                    builder.where(mDbNameResolver.getColumnName(ColumnName.EVENT_ID), SqlExpression.SqlOperatorLessThan, fromLogEntryId);
                } else {
                    builder.where(mDbNameResolver.getColumnName(ColumnName.EVENT_ID), SqlExpression.SqlOperatorGreaterThan, fromLogEntryId);
                }
            }
            if (limit < 0) {
                builder.orderBy(mDbNameResolver.getColumnName(ColumnName.TIMESTMP));
                builder.orderBy(mDbNameResolver.getColumnName(ColumnName.EVENT_ID));
            } else {
                builder.orderBy(mDbNameResolver.getColumnName(ColumnName.TIMESTMP), true);
                builder.orderBy(mDbNameResolver.getColumnName(ColumnName.EVENT_ID), true);
            }
            builder.limit(limit);

            return builder.statement();
        }
    }

    public Collection<LogEntry> getEntries(int limit, int fromLogEntryId, Level minLevel) {
        try {
            return getDbEntries(limit, fromLogEntryId, minLevel);
        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }

    private SQLiteDatabase openDatabase() throws SQLException {
        if (mDatabase != null && mDatabase.isOpen()) {
            return mDatabase;
        }

        String packageName = null;
        LoggerContext context = (LoggerContext) org.slf4j.LoggerFactory.getILoggerFactory();

        if (context != null) {
            packageName = context.getProperty(CoreConstants.PACKAGE_NAME_KEY);
        }

        if (packageName == null || packageName.length() == 0) {
            throw new SQLException("Cannot open database without package name");
        }

        try {
            File dbfile = new File(CommonPathUtil.getDatabaseDirectoryPath(packageName), DB_FILENAME);
            mDatabase = SQLiteDatabase.openDatabase(dbfile.getPath(), null, SQLiteDatabase.OPEN_READONLY);
        } catch (SQLiteException e) {
            throw new SQLException("Cannot open database", e);
        }

        return mDatabase;
    }

    private DefaultDBNameResolver getDbNameResolver() {
        if (mDbNameResolver != null) {
            return mDbNameResolver;
        }

        mDbNameResolver = new DefaultDBNameResolver();
        return mDbNameResolver;
    }

    private Collection<String> getStackTrace(int logEntryId) throws SQLException {
        Collection<String> stackTrace = new ArrayList();
        SQLiteDatabase db = openDatabase();
        Cursor cursor = null;

        try {
            DefaultDBNameResolver dbNameResolver = getDbNameResolver();
            QueryBuilder qb = new QueryBuilder(dbNameResolver);
            cursor = mDatabase.rawQuery(qb.buildStackTraceQuery(logEntryId), new String[] {});
            while (cursor.moveToNext()) {
                stackTrace.add(cursor.getString(cursor.getColumnIndex(dbNameResolver.getColumnName(ColumnName.TRACE_LINE))));
            }
        } catch (SQLiteException e) {
            throw new SQLException("Cannot retrieve log entries", e);
        } finally {
            if (cursor != null) {
                cursor.close();
            }
        }

        return stackTrace;
    }

    private Collection<LogEntry> getDbEntries(int limit, int fromLogEntryId, Level minLevel) throws SQLException {
        Collection<LogEntry> entries = new ArrayList<LogEntry>();
        SQLiteDatabase db = openDatabase();
        Cursor cursor = null;

        try {
            DefaultDBNameResolver dbNameResolver = getDbNameResolver();
            QueryBuilder qb = new QueryBuilder(dbNameResolver);
            cursor = db.rawQuery(qb.buildQuery(limit, fromLogEntryId, minLevel), new String[] {});
            while (cursor.moveToNext()) {
                LogEntry entry = new LogEntry();
                entry.setContext(0);
                entry.setId(cursor.getInt(cursor.getColumnIndex(mDbNameResolver.getColumnName(ColumnName.EVENT_ID))));
                entry.setLevel(cursor.getString(cursor.getColumnIndex(dbNameResolver.getColumnName(ColumnName.LEVEL_STRING))));
                entry.setMessage(cursor.getString(cursor.getColumnIndex(dbNameResolver.getColumnName(ColumnName.FORMATTED_MESSAGE))));
                entry.setTimestamp(cursor.getLong(cursor.getColumnIndex(dbNameResolver.getColumnName(ColumnName.TIMESTMP))));
                entry.setLoggerName(cursor.getString(cursor.getColumnIndex(dbNameResolver.getColumnName(ColumnName.LOGGER_NAME))));
                if ("ERROR".equals(entry.getLevel())) {
                    entry.setStackTrace(getStackTrace(entry.getId()));
                }
                entries.add(entry);
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

        return entries;
    }
}
