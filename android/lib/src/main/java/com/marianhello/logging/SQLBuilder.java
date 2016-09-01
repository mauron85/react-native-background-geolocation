package com.marianhello.logging;

import ch.qos.logback.classic.db.names.ColumnName;
import ch.qos.logback.classic.db.names.DBNameResolver;
import ch.qos.logback.classic.db.names.TableName;

public class SQLBuilder {

    public static String buildSelectSQL(DBNameResolver dbNameResolver) {
        StringBuilder sqlBuilder = new StringBuilder("SELECT ");
        sqlBuilder.append(dbNameResolver.getColumnName(ColumnName.TIMESTMP)).append(", ")
                .append(dbNameResolver.getColumnName(ColumnName.FORMATTED_MESSAGE)).append(", ")
                .append(dbNameResolver.getColumnName(ColumnName.LOGGER_NAME)).append(", ")
                .append(dbNameResolver.getColumnName(ColumnName.LEVEL_STRING)).append(", ")
                .append(dbNameResolver.getColumnName(ColumnName.THREAD_NAME)).append(", ")
                .append(dbNameResolver.getColumnName(ColumnName.REFERENCE_FLAG)).append(", ")
                .append(dbNameResolver.getColumnName(ColumnName.ARG0)).append(", ")
                .append(dbNameResolver.getColumnName(ColumnName.ARG1)).append(", ")
                .append(dbNameResolver.getColumnName(ColumnName.ARG2)).append(", ")
                .append(dbNameResolver.getColumnName(ColumnName.ARG3)).append(", ")
                .append(dbNameResolver.getColumnName(ColumnName.CALLER_FILENAME)).append(", ")
                .append(dbNameResolver.getColumnName(ColumnName.CALLER_CLASS)).append(", ")
                .append(dbNameResolver.getColumnName(ColumnName.CALLER_METHOD)).append(", ")
                .append(dbNameResolver.getColumnName(ColumnName.CALLER_LINE))
                .append(" FROM ").append(dbNameResolver.getTableName(TableName.LOGGING_EVENT))
                .append(" ORDER BY ").append(dbNameResolver.getColumnName(ColumnName.TIMESTMP))
                .append(" DESC LIMIT ?");
        return sqlBuilder.toString();
    }
}
