package com.marianhello.bgloc;

import android.database.sqlite.SQLiteDatabase;
import android.location.Location;

import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.LocationDAO;
import com.marianhello.bgloc.data.provider.ContentProviderLocationDAO;
import com.marianhello.bgloc.data.sqlite.SQLiteOpenHelper;
import com.marianhello.bgloc.test.LocationProviderTestCase;

import org.junit.Before;
import org.junit.Test;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;

import static android.support.test.InstrumentationRegistry.getContext;
import static com.marianhello.bgloc.data.sqlite.SQLiteLocationContract.LocationEntry.SQL_DROP_LOCATION_TABLE;
import static junit.framework.Assert.assertEquals;

public class ContentProviderLocationDAOTest extends LocationProviderTestCase {
    public void deleteDatabase() {
        SQLiteOpenHelper dbHelper = new SQLiteOpenHelper(getContext());
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        dbHelper.execAndLogSql(db, SQL_DROP_LOCATION_TABLE);
        dbHelper.onCreate(db);
    }

    @Before
    @Override
    public void setUp() throws Exception {
        super.setUp();
        deleteDatabase();
    }

    @Test
    public void testPersistLocation() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

        Location location = new Location("fake");
        location.setAccuracy(200);
        location.setAltitude(900);
        location.setBearing(2);
        location.setLatitude(40.21);
        location.setLongitude(23.45);
        location.setSpeed(20);
        location.setProvider("test");
        location.setTime(1000);
        BackgroundLocation bgLocation = BackgroundLocation.fromLocation(location);

        dao.persistLocation(bgLocation);

        ArrayList<BackgroundLocation> locations = new ArrayList(dao.getAllLocations());
        assertEquals(1, locations.size());

        BackgroundLocation storedLocation = locations.get(0);
        assertEquals(200, storedLocation.getAccuracy(), 0);
        assertEquals(900, storedLocation.getAltitude(), 0);
        assertEquals(2, storedLocation.getBearing(), 0);
        assertEquals(40.21, storedLocation.getLatitude(), 0);
        assertEquals(23.45, storedLocation.getLongitude(), 0);
        assertEquals(20, storedLocation.getSpeed(), 0);
        assertEquals("test", storedLocation.getProvider(), "test");
        assertEquals(1000, storedLocation.getTime(), 0);
        junit.framework.Assert.assertFalse(storedLocation.hasMockLocationsEnabled());
        junit.framework.Assert.assertFalse(storedLocation.areMockLocationsEnabled());
        junit.framework.Assert.assertTrue(storedLocation.hasIsFromMockProvider()); // because setIsFromMockProvider is called in constructor
        junit.framework.Assert.assertFalse(storedLocation.isFromMockProvider());
    }

    @Test
    public void testPersistLocationIsMock() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

        BackgroundLocation bgLocation = new BackgroundLocation();
        bgLocation.setMockLocationsEnabled(true);
        bgLocation.setIsFromMockProvider(true);

        dao.persistLocation(bgLocation);

        ArrayList<BackgroundLocation> locations = new ArrayList(dao.getAllLocations());
        assertEquals(1, locations.size());

        BackgroundLocation storedLocation = locations.get(0);
        junit.framework.Assert.assertTrue(storedLocation.hasMockLocationsEnabled());
        junit.framework.Assert.assertTrue(storedLocation.areMockLocationsEnabled());
        junit.framework.Assert.assertTrue(storedLocation.hasIsFromMockProvider());
        junit.framework.Assert.assertTrue(storedLocation.isFromMockProvider());
    }

    @Test
    public void testDeleteLocationById() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

        BackgroundLocation bgLocation = BackgroundLocation.fromLocation(new Location("fake"));
        Collection<BackgroundLocation> locations = null;

        Long locationId = dao.persistLocation(bgLocation);

        locations = dao.getAllLocations();
        assertEquals(1, locations.size());

        dao.deleteLocationById(locationId);

        locations = dao.getValidLocations();
        assertEquals(0, locations.size());
    }

    @Test
    public void testDeleteAllLocations() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());
        Collection<BackgroundLocation> locations = null;

        for (int i = 0; i < 10; i++) {
            dao.persistLocation(BackgroundLocation.fromLocation(new Location("fake")));
        }

        locations = dao.getValidLocations();
        assertEquals(10, locations.size());

        dao.deleteAllLocations();

        locations = dao.getValidLocations();
        assertEquals(0, locations.size());
    }

    @Test
    public void testGetAllLocations() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

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
            bgLocation = BackgroundLocation.fromLocation(location);
            dao.persistLocation(bgLocation);
        }

        Collection<BackgroundLocation> locations = dao.getAllLocations();
        Iterator<BackgroundLocation> it = locations.iterator();
        BackgroundLocation storedLocation = null;
        for (int i = 0; i < 10; i++) {
            storedLocation = it.next();
            assertEquals(200 + i, storedLocation.getAccuracy(), 0);
            assertEquals(900 + i, storedLocation.getAltitude(), 0);
            assertEquals(2 + i, storedLocation.getBearing(), 0);
            assertEquals(40.21 + i, storedLocation.getLatitude(), 0);
            assertEquals(23.45 + i,storedLocation.getLongitude(), 0);
            assertEquals(20 + i, storedLocation.getSpeed(), 0);
            assertEquals("test", storedLocation.getProvider());
            assertEquals(1000 + i, storedLocation.getTime(), 0);
        }
    }

    @Test
    public void testPersistLocationWithRowLimit() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

        int maxRows = 100;

        for (int i = 0; i < maxRows * 2; i++) {
            dao.persistLocation(BackgroundLocation.fromLocation(new Location("fake")), maxRows);
        }

        Collection<BackgroundLocation> locations = dao.getAllLocations();
        assertEquals(maxRows, locations.size());
    }

    @Test
    public void testShouldReplaceOldLocation() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

        dao.persistLocation(BackgroundLocation.fromLocation(new Location("old")), 1);
        dao.persistLocation(BackgroundLocation.fromLocation(new Location("new")), 1);

        Collection<BackgroundLocation> locations = dao.getAllLocations();
        assertEquals(1, locations.size());
        assertEquals("new", locations.iterator().next().getProvider());
    }

    @Test
    public void testPersistLocationWithRowLimitWhenMaxRowsReduced() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

        int maxRowsRun[] = {100, 10};

        for (int i = 0; i < maxRowsRun.length; i++) {
            int maxRows = maxRowsRun[i];
            for (int j = 0; j < maxRows * 2; j++) {
                dao.persistLocation(BackgroundLocation.fromLocation(new Location("fake")), maxRows);
            }
            Collection<BackgroundLocation> locations = dao.getAllLocations();
            assertEquals(maxRows, locations.size());
        }

        Long locationId = dao.persistLocation(BackgroundLocation.fromLocation(new Location("fake")));
        assertEquals(locationId, Long.valueOf(101));
    }

    @Test
    public void testPersistLocationWithBatchId() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

        BackgroundLocation location = new BackgroundLocation();
        location.setBatchStartMillis(1000L);
        dao.persistLocation(location);
        ArrayList<BackgroundLocation> locations = new ArrayList(dao.getAllLocations());
        assertEquals(Long.valueOf(1000L), locations.get(0).getBatchStartMillis());
    }

    @Test
    public void testGetLocationsForSyncCount() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

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

        assertEquals(66, dao.getValidLocations().size());
        assertEquals(99, dao.getAllLocations().size());
        assertEquals(66L, dao.getLocationsForSyncCount(10001L));
        assertEquals(33L, dao.getLocationsForSyncCount(1000L));
    }

    @Test
    public void testGetLocationById() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

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
            bgLocation = BackgroundLocation.fromLocation(location);
            dao.persistLocation(bgLocation);
        }

        BackgroundLocation pending = dao.getLocationById(2);
        assertEquals(Long.valueOf(2), pending.getLocationId());
    }

    @Test
    public void testGetFirstPendingLocation() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

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
        assertEquals(Long.valueOf(4), pending.getLocationId());
    }

    @Test
    public void testGetNextPendingLocation() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

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
        assertEquals(Long.valueOf(5), pending.getLocationId());
    }

    @Test
    public void testGetPendingLocationsCount() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

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

        assertEquals(2, dao.getUnpostedLocationsCount());
    }

    @Test
    public void testDeleteFirstPendingLocation() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

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
        assertEquals(Long.valueOf(4), deleted.getLocationId());
    }

    @Test
    public void testDeletePendingLocations() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

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
        assertEquals(0, dao.getUnpostedLocationsCount());
        assertEquals(2, dao.getLocationsForSyncCount(0));
    }

    @Test
    public void testPersistLocationForSync() {
        LocationDAO dao = new ContentProviderLocationDAO(getContext());

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
        assertEquals(1, dao.getUnpostedLocationsCount());
        assertEquals(0, dao.getLocationsForSyncCount(0));

        dao.persistLocationForSync(location, 100);
        assertEquals(0, dao.getUnpostedLocationsCount());
        assertEquals(1, dao.getLocationsForSyncCount(0));
    }
}
