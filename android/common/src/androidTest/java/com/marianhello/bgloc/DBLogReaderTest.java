package com.marianhello.bgloc;

import android.content.Context;
import android.support.test.InstrumentationRegistry;
import android.support.test.runner.AndroidJUnit4;
import android.support.test.filters.SmallTest;

import com.marianhello.logging.DBLogReader;
import com.marianhello.logging.LogEntry;
import com.marianhello.logging.LoggerManager;

import junit.framework.Assert;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.slf4j.Logger;
import org.slf4j.event.Level;

import java.io.File;
import java.util.ArrayList;
import java.util.Collection;

import ch.qos.logback.classic.LoggerContext;
import ch.qos.logback.core.CoreConstants;
import ch.qos.logback.core.android.CommonPathUtil;

@RunWith(AndroidJUnit4.class)
@SmallTest
public class DBLogReaderTest {
    private static final String TAG = "DBLogReaderTest";

    @Before
    public void deleteDatabase() {
        LoggerManager.disableDBLogging();
        String packageName = null;
        LoggerContext context = (LoggerContext) org.slf4j.LoggerFactory.getILoggerFactory();

        if (context != null) {
            packageName = context.getProperty(CoreConstants.PACKAGE_NAME_KEY);
        }

        if (!(packageName == null || packageName.length() == 0)) {
            File dbfile = new File(CommonPathUtil.getDatabaseDirectoryPath(packageName), DBLogReader.DB_FILENAME);
            Context ctx = InstrumentationRegistry.getTargetContext();
            ctx.deleteDatabase(dbfile.getPath());
        }
    }

    @Test
    public void testReadLogEntriesWithLimit() {
        LoggerManager.enableDBLogging();
        Logger logger = LoggerManager.getLogger(DBLogReaderTest.class);

        for (int i = 0; i < 100; i++) {
            logger.debug("Message #" + i);
        }

        DBLogReader logReader = new DBLogReader();
        Collection<LogEntry> entries = logReader.getEntries(10, 0, Level.DEBUG);
        Assert.assertEquals(10, entries.size());
    }

    @Test
    public void testReadLogEntriesWithOffset() {
        LoggerManager.enableDBLogging();
        Logger logger = LoggerManager.getLogger(DBLogReaderTest.class);

        for (int i = 0; i < 100; i++) {
            logger.debug("Message #" + i);
        }

        DBLogReader logReader = new DBLogReader();
        ArrayList<LogEntry> entries = (ArrayList) logReader.getEntries(10, 0, Level.DEBUG);
        LogEntry lastEntry = entries.get(entries.size() - 1);
        entries = (ArrayList) logReader.getEntries(10, lastEntry.getId(), Level.DEBUG);
        Assert.assertEquals(lastEntry.getId() - 1, entries.get(0).getId().intValue());
    }

    @Test
    public void testReadLogEntriesWithOffsetAsc() {
        LoggerManager.enableDBLogging();
        Logger logger = LoggerManager.getLogger(DBLogReaderTest.class);

        for (int i = 0; i < 100; i++) {
            logger.debug("Message #" + i);
        }

        DBLogReader logReader = new DBLogReader();
        ArrayList<LogEntry> entries = (ArrayList) logReader.getEntries(10, 0, Level.DEBUG);
        LogEntry lastEntry = entries.get(entries.size() - 1);
        entries = (ArrayList) logReader.getEntries(-10, lastEntry.getId(), Level.DEBUG);
        Assert.assertEquals(lastEntry.getId() + 1, entries.get(0).getId().intValue());
    }
}
