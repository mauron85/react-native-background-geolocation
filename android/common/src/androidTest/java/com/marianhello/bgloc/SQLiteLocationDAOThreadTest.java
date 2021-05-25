package com.marianhello.bgloc;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.location.Location;
import android.support.test.InstrumentationRegistry;
import android.support.test.runner.AndroidJUnit4;
import android.support.test.filters.SmallTest;

import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.sqlite.SQLiteLocationDAO;
import com.marianhello.bgloc.data.sqlite.SQLiteOpenHelper;

import junit.framework.Assert;

import org.junit.Before;
import org.junit.Ignore;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.Collection;
import java.util.Iterator;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/**
 * Created by finch on 13/07/16.
 */
@Ignore
@RunWith(AndroidJUnit4.class)
@SmallTest
public class SQLiteLocationDAOThreadTest {

    @Before
    public void deleteDatabase() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        ctx.deleteDatabase(SQLiteOpenHelper.SQLITE_DATABASE_NAME);
    }

    @Test
    public void persistLocationFromMultipleThreads() {
        int threadsCount = 100;

        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        final SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        ExecutorService es = Executors.newCachedThreadPool();
        for (int j = 0; j < threadsCount; j++) {
            final int i = j;
            es.execute(new Runnable() {
                public void run() {
                    Location location = new Location("fake");
                    location.setAccuracy(200 + i);
                    location.setAltitude(900 + i);
                    location.setBearing(2 + i);
                    location.setLatitude(40.21 + i);
                    location.setLongitude(23.45 + i);
                    location.setSpeed(20 + i);
                    location.setProvider("test");
                    location.setTime(1000 + i);
                    BackgroundLocation bgLocation = new BackgroundLocation(location);

                    dao.persistLocation(bgLocation);
                }
            });
        }
        es.shutdown();
        try {
            boolean finished = es.awaitTermination(1, TimeUnit.MINUTES);
        } catch (InterruptedException e) {
            e.printStackTrace();
            Assert.fail("Test terminated. Operation toked too long.");
        }

        Collection<BackgroundLocation> locations = dao.getValidLocations();
        Assert.assertEquals(threadsCount, locations.size());

        int i = 0;
        BackgroundLocation storedLocation = null;
        Iterator<BackgroundLocation> it = locations.iterator();
        while(it.hasNext()) {
            storedLocation = it.next();
            Assert.assertEquals(200 + i, storedLocation.getAccuracy(), 0);
            Assert.assertEquals(900 + i, storedLocation.getAltitude(), 0);
            Assert.assertEquals(2 + i, storedLocation.getBearing(), 0);
            Assert.assertEquals(40.21 + i, storedLocation.getLatitude(), 0);
            Assert.assertEquals(23.45 + i,storedLocation.getLongitude(), 0);
            Assert.assertEquals(20 + i, storedLocation.getSpeed(), 0);
            Assert.assertEquals("test", storedLocation.getProvider());
            Assert.assertEquals(1000 + i, storedLocation.getTime(), 0);
            i++;
        }
    }
}
