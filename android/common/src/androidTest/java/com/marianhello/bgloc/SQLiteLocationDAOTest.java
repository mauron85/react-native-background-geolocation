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

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;

/**
 * Created by finch on 12/07/16.
 */
@Ignore
@RunWith(AndroidJUnit4.class)
@SmallTest
public class SQLiteLocationDAOTest {

    @Before
    public void deleteDatabase() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        ctx.deleteDatabase(SQLiteOpenHelper.SQLITE_DATABASE_NAME);
    }

    @Test
    public void persistLocation() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        Location location = new Location("fake");
        location.setAccuracy(200);
        location.setAltitude(900);
        location.setBearing(2);
        location.setLatitude(40.21);
        location.setLongitude(23.45);
        location.setSpeed(20);
        location.setProvider("test");
        location.setTime(1000);
        BackgroundLocation bgLocation = new BackgroundLocation(location);

        dao.persistLocation(bgLocation);

        ArrayList<BackgroundLocation> locations = new ArrayList(dao.getAllLocations());
        Assert.assertEquals(1, locations.size());

        BackgroundLocation storedLocation = locations.get(0);
        Assert.assertEquals(200, storedLocation.getAccuracy(), 0);
        Assert.assertEquals(900, storedLocation.getAltitude(), 0);
        Assert.assertEquals(2, storedLocation.getBearing(), 0);
        Assert.assertEquals(40.21, storedLocation.getLatitude(), 0);
        Assert.assertEquals(23.45, storedLocation.getLongitude(), 0);
        Assert.assertEquals(20, storedLocation.getSpeed(), 0);
        Assert.assertEquals("test", storedLocation.getProvider(), "test");
        Assert.assertEquals(1000, storedLocation.getTime(), 0);
        Assert.assertFalse(storedLocation.hasMockLocationsEnabled());
        Assert.assertFalse(storedLocation.areMockLocationsEnabled());
        Assert.assertTrue(storedLocation.hasIsFromMockProvider()); // because setIsFromMockProvider is called in constructor
        Assert.assertFalse(storedLocation.isFromMockProvider());
    }

    @Test
    public void persistLocationIsMock() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        BackgroundLocation bgLocation = new BackgroundLocation();
        bgLocation.setMockLocationsEnabled(true);
        bgLocation.setIsFromMockProvider(true);

        dao.persistLocation(bgLocation);

        ArrayList<BackgroundLocation> locations = new ArrayList(dao.getAllLocations());
        Assert.assertEquals(1, locations.size());

        BackgroundLocation storedLocation = locations.get(0);
        Assert.assertTrue(storedLocation.hasMockLocationsEnabled());
        Assert.assertTrue(storedLocation.areMockLocationsEnabled());
        Assert.assertTrue(storedLocation.hasIsFromMockProvider());
        Assert.assertTrue(storedLocation.isFromMockProvider());
    }

    @Test
    public void deleteLocationById() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        BackgroundLocation bgLocation = new BackgroundLocation(new Location("fake"));
        Collection<BackgroundLocation> locations = null;

        Long locationId = dao.persistLocation(bgLocation);

        locations = dao.getAllLocations();
        Assert.assertEquals(1, locations.size());

        dao.deleteLocationById(locationId);

        locations = dao.getValidLocations();
        Assert.assertEquals(0, locations.size());
    }

    @Test
    public void deleteAllLocations() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        Collection<BackgroundLocation> locations = null;

        for (int i = 0; i < 10; i++) {
            dao.persistLocation(new BackgroundLocation(new Location("fake")));
        }

        locations = dao.getValidLocations();
        Assert.assertEquals(10, locations.size());

        dao.deleteAllLocations();

        locations = dao.getValidLocations();
        Assert.assertEquals(0, locations.size());
    }

    @Test
    public void getAllLocations() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        Location location = null;
        BackgroundLocation bgLocation = null;

        for (int i = 0; i < 10; i++) {
            location = new Location("fake");
            location.setAccuracy(200 + i);
            location.setAltitude(900 + i);
            location.setBearing(2 + i);
            location.setLatitude(40.21 + i);
            location.setLongitude(23.45 + i);
            location.setSpeed(20 + i);
            location.setProvider("test");
            location.setTime(1000 + i);
            bgLocation = new BackgroundLocation(location);
            dao.persistLocation(bgLocation);
        }

        Collection<BackgroundLocation> locations = dao.getAllLocations();
        Iterator<BackgroundLocation> it = locations.iterator();
        BackgroundLocation storedLocation = null;
        for (int i = 0; i < 10; i++) {
            storedLocation = it.next();
            Assert.assertEquals(200 + i, storedLocation.getAccuracy(), 0);
            Assert.assertEquals(900 + i, storedLocation.getAltitude(), 0);
            Assert.assertEquals(2 + i, storedLocation.getBearing(), 0);
            Assert.assertEquals(40.21 + i, storedLocation.getLatitude(), 0);
            Assert.assertEquals(23.45 + i,storedLocation.getLongitude(), 0);
            Assert.assertEquals(20 + i, storedLocation.getSpeed(), 0);
            Assert.assertEquals("test", storedLocation.getProvider());
            Assert.assertEquals(1000 + i, storedLocation.getTime(), 0);
        }
    }

    @Test
    public void persistLocationWithRowLimit() {
        int maxRows = 100;
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        for (int i = 0; i < maxRows * 2; i++) {
            dao.persistLocation(new BackgroundLocation(new Location("fake")), maxRows);
        }

        Collection<BackgroundLocation> locations = dao.getAllLocations();
        Assert.assertEquals(maxRows, locations.size());
    }

    @Test
    public void persistLocationWithRowLimitWhenMaxRowsReduced() {
        int maxRowsRun[] = {100, 10};
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        for (int i = 0; i < maxRowsRun.length; i++) {
            int maxRows = maxRowsRun[i];
            for (int j = 0; j < maxRows * 2; j++) {
                dao.persistLocation(new BackgroundLocation(new Location("fake")), maxRows);
            }
            Collection<BackgroundLocation> locations = dao.getAllLocations();
            Assert.assertEquals(maxRows, locations.size());
        }

        Long locationId = dao.persistLocation(new BackgroundLocation(new Location("fake")));
        Assert.assertEquals(locationId, Long.valueOf(101));
    }

    @Test
    public void persistLocationWithBatchId() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        BackgroundLocation location = new BackgroundLocation();
        location.setBatchStartMillis(1000L);
        dao.persistLocation(location);
        ArrayList<BackgroundLocation> locations = new ArrayList(dao.getAllLocations());
        Assert.assertEquals(Long.valueOf(1000L), locations.get(0).getBatchStartMillis());
    }

    @Test
    public void getLocationsForSyncCount() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        BackgroundLocation location;
        for (int i = 1; i < 100; i++) {
            location = new BackgroundLocation();
            if ((i % 3) == 0) {
                // exactly 33 locations (out of 99) should be eligible for sync for given batch id 1000
                location.setBatchStartMillis(1000L);
                location.setStatus(BackgroundLocation.SYNC_PENDING);
            } else if ((i % 2) == 0) {
                // exactly 33 locations as deleted
                location.setStatus(BackgroundLocation.DELETED);
            } else {
                location.setStatus(BackgroundLocation.SYNC_PENDING);
            }
            dao.persistLocation(location);
        }

        Assert.assertEquals(66, dao.getValidLocations().size());
        Assert.assertEquals(99, dao.getAllLocations().size());
        Assert.assertEquals(66L, dao.getLocationsForSyncCount(10001L));
        Assert.assertEquals(33L, dao.getLocationsForSyncCount(1000L));
    }

    @Test
    public void getLocationById() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        Location location = null;
        BackgroundLocation bgLocation = null;

        for (int i = 0; i < 10; i++) {
            location = new Location("fake");
            location.setAccuracy(200 + i);
            location.setAltitude(900 + i);
            location.setBearing(2 + i);
            location.setLatitude(40.21 + i);
            location.setLongitude(23.45 + i);
            location.setSpeed(20 + i);
            location.setProvider("test");
            location.setTime(1000 + i);
            bgLocation = new BackgroundLocation(location);
            dao.persistLocation(bgLocation);
        }

        BackgroundLocation pending = dao.getLocationById(2);
        Assert.assertEquals(Long.valueOf(2), pending.getLocationId());
    }

    @Test
    public void getFirstPendingLocation() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        BackgroundLocation location = null;

        for (int i = 1; i <= 5; i++) {
            location = new BackgroundLocation();
            location.setProvider("fake");
            location.setAccuracy(200 + i);
            location.setAltitude(900 + i);
            location.setBearing(2 + i);
            location.setLatitude(40.21 + i);
            location.setLongitude(23.45 + i);
            location.setSpeed(20 + i);
            location.setProvider("test");
            location.setTime(1000 + i);
            if (i <= 3) {
                location.setStatus(BackgroundLocation.DELETED);
            }

            dao.persistLocation(location);
        }

        BackgroundLocation pending = dao.getFirstUnpostedLocation();
        Assert.assertEquals(Long.valueOf(4), pending.getLocationId());
    }

    @Test
    public void getNextPendingLocation() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        BackgroundLocation location = null;

        for (int i = 1; i <= 5; i++) {
            location = new BackgroundLocation();
            location.setProvider("fake");
            location.setAccuracy(200 + i);
            location.setAltitude(900 + i);
            location.setBearing(2 + i);
            location.setLatitude(40.21 + i);
            location.setLongitude(23.45 + i);
            location.setSpeed(20 + i);
            location.setProvider("test");
            location.setTime(1000 + i);
            if (i <= 3) {
                location.setStatus(BackgroundLocation.DELETED);
            }

            dao.persistLocation(location);
        }

        BackgroundLocation pending = dao.getNextUnpostedLocation(4);
        Assert.assertEquals(Long.valueOf(5), pending.getLocationId());
    }

    @Test
    public void getPendingLocationsCount() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        BackgroundLocation location = null;

        for (int i = 0; i < 5; i++) {
            location = new BackgroundLocation();
            location.setProvider("fake");
            location.setAccuracy(200 + i);
            location.setAltitude(900 + i);
            location.setBearing(2 + i);
            location.setLatitude(40.21 + i);
            location.setLongitude(23.45 + i);
            location.setSpeed(20 + i);
            location.setProvider("test");
            location.setTime(1000 + i);
            if (i < 3) {
                location.setStatus(BackgroundLocation.DELETED);
            }

            dao.persistLocation(location);
        }

        Assert.assertEquals(2, dao.getUnpostedLocationsCount());
    }

    @Test
    public void deleteFirstPendingLocation() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        BackgroundLocation location = null;

        for (int i = 1; i <= 5; i++) {
            location = new BackgroundLocation();
            location.setProvider("fake");
            location.setAccuracy(200 + i);
            location.setAltitude(900 + i);
            location.setBearing(2 + i);
            location.setLatitude(40.21 + i);
            location.setLongitude(23.45 + i);
            location.setSpeed(20 + i);
            location.setProvider("test");
            location.setTime(1000 + i);
            if (i <= 3) {
                location.setStatus(BackgroundLocation.DELETED);
            }

            dao.persistLocation(location);
        }

        BackgroundLocation deleted = dao.deleteFirstUnpostedLocation();
        Assert.assertEquals(Long.valueOf(4), deleted.getLocationId());
    }

    @Test
    public void deletePendingLocations() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        BackgroundLocation location = null;

        for (int i = 0; i < 5; i++) {
            location = new BackgroundLocation();
            location.setProvider("fake");
            location.setAccuracy(200 + i);
            location.setAltitude(900 + i);
            location.setBearing(2 + i);
            location.setLatitude(40.21 + i);
            location.setLongitude(23.45 + i);
            location.setSpeed(20 + i);
            location.setProvider("test");
            location.setTime(1000 + i);
            if (i < 3) {
                location.setStatus(BackgroundLocation.DELETED);
            }

            dao.persistLocation(location);
        }

        dao.deleteUnpostedLocations();
        Assert.assertEquals(0, dao.getUnpostedLocationsCount());
        Assert.assertEquals(2, dao.getLocationsForSyncCount(0));
    }

    @Test
    public void persistLocationForSync() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);

        BackgroundLocation location = new BackgroundLocation();
        location.setProvider("fake");
        location.setAccuracy(200);
        location.setAltitude(900);
        location.setBearing(2);
        location.setLatitude(40.21);
        location.setLongitude(23.45);
        location.setSpeed(20);
        location.setProvider("test");
        location.setTime(1000);

        long locationId = dao.persistLocation(location);
        location.setLocationId(locationId);
        Assert.assertEquals(1, dao.getUnpostedLocationsCount());
        Assert.assertEquals(0, dao.getLocationsForSyncCount(0));

        dao.persistLocationForSync(location, 100);
        Assert.assertEquals(0, dao.getUnpostedLocationsCount());
        Assert.assertEquals(1, dao.getLocationsForSyncCount(0));
    }
}
