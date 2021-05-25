package com.marianhello.backgroundgeolocation;

import android.support.test.filters.SmallTest;

import com.marianhello.logging.DBLogReader;

import junit.framework.Assert;

import org.junit.Test;
import org.slf4j.event.Level;

@SmallTest
public class DBLogReaderTest {
    @Test
    public void testBuildQuery() {
        DBLogReader.QueryBuilder qb = new DBLogReader.QueryBuilder();
        String sql = qb.buildQuery(100, 0, Level.DEBUG);

        Assert.assertEquals("SELECT [event_id], [timestmp], [formatted_message], [logger_name], [level_string] FROM [logging_event] WHERE [level_string] IN ('ERROR', 'WARN', 'INFO', 'DEBUG') ORDER BY [timestmp] DESC, [event_id] DESC LIMIT 100;", sql);
    }

    @Test
    public void testBuildQueryWithOffset() {
        DBLogReader.QueryBuilder qb = new DBLogReader.QueryBuilder();
        String sql = qb.buildQuery(100, 10, Level.ERROR);

        Assert.assertEquals("SELECT [event_id], [timestmp], [formatted_message], [logger_name], [level_string] FROM [logging_event] WHERE [level_string] IN ('ERROR') AND [event_id] < 10 ORDER BY [timestmp] DESC, [event_id] DESC LIMIT 100;", sql);
    }

    @Test
    public void testBuildStackTraceQuery() {
        DBLogReader.QueryBuilder qb = new DBLogReader.QueryBuilder();
        String sql = qb.buildStackTraceQuery(100);

        Assert.assertEquals("SELECT [trace_line] FROM [logging_event_exception] WHERE [i] = 100 ORDER BY [i] ASC;", sql);
    }
}
