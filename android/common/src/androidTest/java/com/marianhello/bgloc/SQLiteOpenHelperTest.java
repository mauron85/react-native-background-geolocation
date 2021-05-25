package com.marianhello.bgloc;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.location.Location;
import android.support.test.InstrumentationRegistry;
import android.support.test.runner.AndroidJUnit4;
import android.support.test.filters.SmallTest;

import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.sqlite.SQLiteConfigurationContract;
import com.marianhello.bgloc.data.sqlite.SQLiteLocationContract;
import com.marianhello.bgloc.data.sqlite.SQLiteLocationDAO;
import com.marianhello.bgloc.data.sqlite.SQLiteOpenHelper;
import com.marianhello.bgloc.sqlite.SQLiteOpenHelper10;

import junit.framework.Assert;

import org.json.JSONObject;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Created by finch on 13/07/16.
 */
@RunWith(AndroidJUnit4.class)
@SmallTest
public class SQLiteOpenHelperTest {
    @Before
    public void deleteDatabase() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteOpenHelper.getHelper(ctx).close();
        ctx.deleteDatabase(SQLiteOpenHelper.SQLITE_DATABASE_NAME);
    }

    @Test
    public void upgradeDatabaseFromVersion10() {
        Cursor cursor = null;
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db10 = new SQLiteOpenHelper10(ctx).getWritableDatabase();

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

        Config config = Config.getDefault();
        config.setActivitiesInterval(1000);
        config.setDesiredAccuracy(200);
        config.setDistanceFilter(300);
        config.setFastestInterval(5000);
        config.setInterval(10000);
        config.setLocationProvider(0);
        config.setMaxLocations(15000);
        config.setUrl("http://server:1234/locations");
        config.setStopOnTerminate(false);
        config.setStopOnStillActivity(false);
        config.setStationaryRadius(50);
        config.setStartOnBoot(false);
        config.setStartForeground(false);
        config.setSmallNotificationIcon("smallico");
        config.setLargeNotificationIcon("largeico");
        config.setNotificationTitle("test");
        config.setNotificationText("in progress");
        config.setNotificationIconColor("yellow");

        ContentValues locationValues = new ContentValues();
        locationValues.put(SQLiteLocationContract.LocationEntry.COLUMN_NAME_TIME, bgLocation.getTime());
        locationValues.put(SQLiteLocationContract.LocationEntry.COLUMN_NAME_ACCURACY, bgLocation.getAccuracy());
        locationValues.put(SQLiteLocationContract.LocationEntry.COLUMN_NAME_SPEED, bgLocation.getSpeed());
        locationValues.put(SQLiteLocationContract.LocationEntry.COLUMN_NAME_BEARING, bgLocation.getBearing());
        locationValues.put(SQLiteLocationContract.LocationEntry.COLUMN_NAME_ALTITUDE, bgLocation.getAltitude());
        locationValues.put(SQLiteLocationContract.LocationEntry.COLUMN_NAME_LATITUDE, bgLocation.getLatitude());
        locationValues.put(SQLiteLocationContract.LocationEntry.COLUMN_NAME_LONGITUDE, bgLocation.getLongitude());
        locationValues.put(SQLiteLocationContract.LocationEntry.COLUMN_NAME_PROVIDER, bgLocation.getProvider());
        locationValues.put(SQLiteLocationContract.LocationEntry.COLUMN_NAME_LOCATION_PROVIDER, bgLocation.getLocationProvider());

        db10.insert(SQLiteLocationContract.LocationEntry.TABLE_NAME, null, locationValues);
        cursor = db10.query(SQLiteLocationContract.LocationEntry.TABLE_NAME, null, null, null, null, null, null);
        Assert.assertEquals(1, cursor.getCount());
        cursor.close();

        ContentValues configValues = new ContentValues();
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_RADIUS, config.getStationaryRadius());
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_DISTANCE_FILTER, config.getDistanceFilter());
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_DESIRED_ACCURACY, config.getDesiredAccuracy());
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_DEBUG, (config.isDebugging() == true) ? 1 : 0);
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_NOTIF_TITLE, config.getNotificationTitle());
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_NOTIF_TEXT, config.getNotificationText());
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_NOTIF_ICON_SMALL, config.getSmallNotificationIcon());
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_NOTIF_ICON_LARGE, config.getLargeNotificationIcon());
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_NOTIF_COLOR, config.getNotificationIconColor());
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_STOP_TERMINATE, (config.getStopOnTerminate() == true) ? 1 : 0);
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_START_BOOT, (config.getStartOnBoot() == true) ? 1 : 0);
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_START_FOREGROUND, (config.getStartForeground() == true) ? 1 : 0);
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_LOCATION_PROVIDER, config.getLocationProvider());
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_INTERVAL, config.getInterval());
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_FASTEST_INTERVAL, config.getFastestInterval());
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_ACTIVITIES_INTERVAL, config.getActivitiesInterval());
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_URL, config.getUrl());
        configValues.put(SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_HEADERS, new JSONObject(config.getHttpHeaders()).toString());

        db10.insert(SQLiteConfigurationContract.ConfigurationEntry.TABLE_NAME, null, configValues);
        cursor = db10.query(SQLiteConfigurationContract.ConfigurationEntry.TABLE_NAME, null, null, null, null, null, null);
        Assert.assertEquals(1, cursor.getCount());
        cursor.close();

        db10.close();

        // begin test

        List<String> columnNames = null;
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();

        cursor = db.query(SQLiteLocationContract.LocationEntry.TABLE_NAME, null, null, null, null, null, null);
        columnNames = Arrays.asList(cursor.getColumnNames());

        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_TIME)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_ACCURACY)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_SPEED)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_BEARING)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_ALTITUDE)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_LATITUDE)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_LONGITUDE)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_RADIUS)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_ACCURACY)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_SPEED)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_BEARING)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_ALTITUDE)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_RADIUS)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_PROVIDER)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_LOCATION_PROVIDER)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_STATUS)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_BATCH_START_MILLIS)));
        Assert.assertTrue(columnNames.contains((SQLiteLocationContract.LocationEntry.COLUMN_NAME_MOCK_FLAGS)));

        cursor.close();

        // locations should survive db upgrade
        SQLiteLocationDAO dao = new SQLiteLocationDAO(db);
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


        // test configuration table upgrade

        cursor = db.query(SQLiteConfigurationContract.ConfigurationEntry.TABLE_NAME, null, null, null, null, null, null);
        columnNames = Arrays.asList(cursor.getColumnNames());

        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_RADIUS)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_DISTANCE_FILTER)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_DESIRED_ACCURACY)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_DEBUG)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_NOTIF_TITLE)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_NOTIF_TEXT)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_NOTIF_ICON_LARGE)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_NOTIF_ICON_SMALL)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_NOTIF_COLOR)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_START_BOOT)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_START_FOREGROUND)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_STOP_ON_STILL)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_STOP_TERMINATE)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_LOCATION_PROVIDER)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_INTERVAL)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_FASTEST_INTERVAL)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_ACTIVITIES_INTERVAL)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_URL)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_SYNC_URL)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_SYNC_THRESHOLD)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_HEADERS)));
        Assert.assertTrue(columnNames.contains((SQLiteConfigurationContract.ConfigurationEntry.COLUMN_NAME_MAX_LOCATIONS)));

        cursor.close();

//        SQLiteConfigurationDAO configDAO = new SQLiteConfigurationDAO(db);
//        try {
//            Config storedConfig = configDAO.retrieveConfiguration();
//            Assert.assertEquals(1000, storedConfig.getActivitiesInterval().intValue());
//            Assert.assertEquals(200, storedConfig.getDesiredAccuracy().intValue());
//            Assert.assertEquals(300, storedConfig.getDistanceFilter().intValue());
//            Assert.assertEquals(5000, storedConfig.getFastestInterval().intValue());
//            Assert.assertEquals(10000, storedConfig.getInterval().intValue());
//            Assert.assertEquals(0, storedConfig.getLocationProvider().intValue());
//            Assert.assertEquals(10000, storedConfig.getMaxLocations().intValue());
//            Assert.assertEquals("http://server:1234/locations", storedConfig.getUrl());
//            Assert.assertEquals(Boolean.FALSE, storedConfig.getStopOnTerminate());
//            Assert.assertEquals(Boolean.FALSE, storedConfig.getStopOnStillActivity());
//            Assert.assertEquals(50, storedConfig.getStationaryRadius(), 0);
//            Assert.assertEquals(Boolean.FALSE, storedConfig.getStartOnBoot());
//            Assert.assertEquals(Boolean.FALSE, storedConfig.getStartForeground());
//            Assert.assertEquals("smallico", storedConfig.getSmallNotificationIcon());
//            Assert.assertEquals("largeico", storedConfig.getLargeNotificationIcon());
//            Assert.assertEquals("test", storedConfig.getNotificationTitle());
//            Assert.assertEquals("in progress", storedConfig.getNotificationText());
//            Assert.assertEquals("yellow", storedConfig.getNotificationIconColor());
////            Assert.assertEquals("", storedConfig.getHttpHeaders());
//
//        } catch (JSONException e) {
//            Assert.fail(e.getMessage());
//        }
    }
}
