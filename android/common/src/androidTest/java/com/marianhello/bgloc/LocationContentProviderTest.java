package com.marianhello.bgloc;

import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.net.Uri;
import android.test.RenamingDelegatingContext;
import android.test.mock.MockContentResolver;

import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.provider.LocationContentProvider;
import com.marianhello.bgloc.data.sqlite.SQLiteLocationContract.LocationEntry;
import com.marianhello.bgloc.data.sqlite.SQLiteOpenHelper;
import com.marianhello.bgloc.test.LocationProviderTestCase;
import com.marianhello.bgloc.test.TestConstants;

import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import java.util.ArrayList;

import static com.marianhello.bgloc.data.sqlite.SQLiteLocationContract.LocationEntry.SQL_DROP_LOCATION_TABLE;

public class LocationContentProviderTest extends LocationProviderTestCase {

    private MockContentResolver mResolver;
    private final Uri mContentUri;

    public LocationContentProviderTest() {
        super();
        mContentUri = LocationContentProvider.getContentUri(TestConstants.Authority);
    }

    public void deleteDatabase() {
        // TODO: investigate why prefix is not automatically used when deleteDatabase
        RenamingDelegatingContext context = ((RenamingDelegatingContext) getMockContext().getBaseContext());

        SQLiteOpenHelper dbHelper = new SQLiteOpenHelper(context);
        SQLiteDatabase db = dbHelper.getWritableDatabase();
        dbHelper.execAndLogSql(db, SQL_DROP_LOCATION_TABLE);
        dbHelper.onCreate(db);
    }

    @Before
    @Override
    public void setUp() throws Exception {
        super.setUp();
        mResolver = getMockContentResolver();
        deleteDatabase();
    }

    @Test
    public void testResolveProvider() {
        Cursor cursor = mResolver.query(mContentUri, null, null, null,null);
        Assert.assertNotNull(cursor);
        cursor.close();
    }

    @Test
     public void testShouldCreateAndRetrieveLocation() {
        BackgroundLocation location = new BackgroundLocation();
        location.setAccuracy(200);
        location.setAltitude(900);
        location.setBearing(2);
        location.setLatitude(40.21);
        location.setLongitude(23.45);
        location.setSpeed(20);
        location.setProvider("test");
        location.setTime(1000);

        createLocation(location);

        Cursor cursor = mResolver.query(mContentUri, null, null, null,null);
        assertEquals(1, cursor.getCount());
        assertTrue(cursor.moveToFirst());

        assertEquals(200, cursor.getFloat(cursor.getColumnIndex(LocationEntry.COLUMN_NAME_ACCURACY)), 0);
        assertEquals(900, cursor.getDouble(cursor.getColumnIndex(LocationEntry.COLUMN_NAME_ALTITUDE)), 0);
        assertEquals(2, cursor.getFloat(cursor.getColumnIndex(LocationEntry.COLUMN_NAME_BEARING)), 0);
        assertEquals(40.21, cursor.getDouble(cursor.getColumnIndex(LocationEntry.COLUMN_NAME_LATITUDE)), 0);
        assertEquals(23.45, cursor.getDouble(cursor.getColumnIndex(LocationEntry.COLUMN_NAME_LONGITUDE)), 0);
        assertEquals(20, cursor.getFloat(cursor.getColumnIndex(LocationEntry.COLUMN_NAME_SPEED)), 0);
        assertEquals("test", cursor.getString(cursor.getColumnIndex(LocationEntry.COLUMN_NAME_PROVIDER)));
        assertEquals(1000, cursor.getLong(cursor.getColumnIndex(LocationEntry.COLUMN_NAME_TIME)), 0);

        cursor.close();
    }

    @Test
    public void testShouldDeleteSingleLocation() {
        BackgroundLocation location = new BackgroundLocation();
        location.setAccuracy(200);
        location.setAltitude(900);
        location.setBearing(2);
        location.setLatitude(40.21);
        location.setLongitude(23.45);
        location.setSpeed(20);
        location.setProvider("test");
        location.setTime(1000);

        Uri locationUri = createLocation(location);
        int rowsDeleted = mResolver.delete(locationUri, null, null);

        assertEquals(1, rowsDeleted);
    }

    @Test
    public void testShouldDeleteMultipleLocations() {
        ArrayList<Uri> locationUris = new ArrayList<Uri>();

        for (int i = 1; i <= 2; i++) {
            BackgroundLocation location = new BackgroundLocation();
            location.setAccuracy(200);
            location.setAltitude(900);
            location.setBearing(2);
            location.setLatitude(40.21);
            location.setLongitude(23.45);
            location.setSpeed(20);
            location.setProvider("test");
            location.setTime(1000);

            Uri locationUri = createLocation(location);
            locationUris.add(locationUri);
        }

        int rowsDeleted = mResolver.delete(mContentUri, null, null);
        assertEquals(2, rowsDeleted);
    }

    @Test
    public void testShouldUpdateSingleLocation() {
        BackgroundLocation location = new BackgroundLocation();
        location.setAccuracy(200);
        location.setAltitude(900);
        location.setBearing(2);
        location.setLatitude(40.21);
        location.setLongitude(23.45);
        location.setSpeed(20);
        location.setProvider("test");
        location.setTime(1000);

        Uri locationUri = createLocation(location);

        location.setProvider("new test");

        int rowsUpdated = mResolver.update(locationUri, location.toContentValues(), null, null);
        assertEquals(1, rowsUpdated);

        Cursor cursor = mResolver.query(locationUri, null, null, null,null);
        assertEquals(1, cursor.getCount());
        assertTrue(cursor.moveToFirst());

        assertEquals("new test", cursor.getString(cursor.getColumnIndex(LocationEntry.COLUMN_NAME_PROVIDER)));
    }

    private Uri createLocation(BackgroundLocation location) {
        return mResolver.insert(mContentUri, location.toContentValues());
    }
}
