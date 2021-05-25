package com.marianhello.bgloc;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.support.test.InstrumentationRegistry;
import android.support.test.runner.AndroidJUnit4;
import android.support.test.filters.SmallTest;

import com.marianhello.bgloc.Config;
import com.marianhello.bgloc.data.HashMapLocationTemplate;
import com.marianhello.bgloc.data.LocationTemplate;
import com.marianhello.bgloc.data.LocationTemplateFactory;
import com.marianhello.bgloc.data.sqlite.SQLiteConfigurationContract;
import com.marianhello.bgloc.data.sqlite.SQLiteConfigurationDAO;
import com.marianhello.bgloc.data.sqlite.SQLiteOpenHelper;

import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashSet;

/**
 * Created by finch on 13/07/16.
 */
@RunWith(AndroidJUnit4.class)
@SmallTest
public class SQLiteConfigurationDAOTest {
    @Before
    public void deleteDatabase() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteOpenHelper.getHelper(ctx).close();
        ctx.deleteDatabase(SQLiteOpenHelper.SQLITE_DATABASE_NAME);
    }

    @Test
    public void persistConfiguration() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteConfigurationDAO dao = new SQLiteConfigurationDAO(db);

        Config config = new Config();
        config.setActivitiesInterval(1000);
        config.setDesiredAccuracy(200);
        config.setDistanceFilter(300);
        config.setFastestInterval(5000);
        config.setInterval(10000);
        config.setLocationProvider(0);
        config.setMaxLocations(15000);
        config.setUrl("http://server:1234/locations");
        config.setSyncUrl("http://server:1234/syncLocations");
        config.setSyncThreshold(200);
        config.setStopOnTerminate(false);
        config.setStopOnStillActivity(false);
        config.setStationaryRadius(50);
        config.setStartOnBoot(true);
        config.setStartForeground(true);
        config.setSmallNotificationIcon("smallico");
        config.setLargeNotificationIcon("largeico");
        config.setNotificationTitle("test");
        config.setNotificationText("in progress");
        config.setNotificationIconColor("yellow");
        config.setNotificationsEnabled(true);

        dao.persistConfiguration(config);
        dao.persistConfiguration(config); // try once more

        Cursor cursor = db.query(SQLiteConfigurationContract.ConfigurationEntry.TABLE_NAME, null, null, null, null, null, null);
        Assert.assertEquals(1, cursor.getCount());
        cursor.close();

        try {
            Config storedConfig = dao.retrieveConfiguration();
            Assert.assertEquals(1000, storedConfig.getActivitiesInterval().intValue());
            Assert.assertEquals(200, storedConfig.getDesiredAccuracy().intValue());
            Assert.assertEquals(300, storedConfig.getDistanceFilter().intValue());
            Assert.assertEquals(5000, storedConfig.getFastestInterval().intValue());
            Assert.assertEquals(10000, storedConfig.getInterval().intValue());
            Assert.assertEquals(0, storedConfig.getLocationProvider().intValue());
            Assert.assertEquals(15000, storedConfig.getMaxLocations().intValue());
            Assert.assertEquals("http://server:1234/locations", storedConfig.getUrl());
            Assert.assertEquals("http://server:1234/syncLocations", storedConfig.getSyncUrl());
            Assert.assertEquals(200, storedConfig.getSyncThreshold().intValue());
            Assert.assertEquals(Boolean.FALSE, storedConfig.getStopOnTerminate());
            Assert.assertEquals(Boolean.FALSE, storedConfig.getStopOnStillActivity());
            Assert.assertEquals(50, storedConfig.getStationaryRadius(), 0);
            Assert.assertEquals(Boolean.TRUE, storedConfig.getStartOnBoot());
            Assert.assertEquals(Boolean.TRUE, storedConfig.getStartForeground());
            Assert.assertEquals("smallico", storedConfig.getSmallNotificationIcon());
            Assert.assertEquals("largeico", storedConfig.getLargeNotificationIcon());
            Assert.assertEquals("test", storedConfig.getNotificationTitle());
            Assert.assertEquals("in progress", storedConfig.getNotificationText());
            Assert.assertEquals("yellow", storedConfig.getNotificationIconColor());

        } catch (JSONException e) {
            Assert.fail(e.getMessage());
        }
    }

    @Test
    public void persistConfigurationWithArrayListTemplate() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteConfigurationDAO dao = new SQLiteConfigurationDAO(db);

        Config config = Config.getDefault();
        ArrayList props = new ArrayList();
        props.add("@id");
        props.add("@provider");
        props.add("@time");
        props.add("@altitude");
        props.add("@latitude");
        props.add("@longitude");
        props.add("foo");
        props.add("@locationProvider");
        props.add("@accuracy");
        props.add("@speed");
        props.add("@bearing");

        config.setTemplate(LocationTemplateFactory.fromArrayList(props));
        dao.persistConfiguration(config);

        try {
            Config storedConfig = dao.retrieveConfiguration();
            Assert.assertEquals(config.getTemplate(), storedConfig.getTemplate());
        } catch (JSONException e) {
            Assert.fail(e.getMessage());
        }
    }

    @Test
    public void persistConfigurationWithHashMapTemplate() {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteConfigurationDAO dao = new SQLiteConfigurationDAO(db);

        Config config = Config.getDefault();
        HashMap props = new HashMap<String, String>();
        props.put("@id", "Id");
        props.put("@provider", "Provider");
        props.put("@time", "Time");
        props.put("@altitude", "Altitude");
        props.put("@latitude", "Latitude");
        props.put("@longitude", "Longitude");
        props.put("Bar", "Foo");
        props.put("@locationProvider", "LocationProvider");
        props.put("@accuracy", "Accuracy");
        props.put("@speed", "Speed");
        props.put("@bearing", "Bearing");

        config.setTemplate(new HashMapLocationTemplate(props));
        dao.persistConfiguration(config);

        try {
            Config storedConfig = dao.retrieveConfiguration();
            Assert.assertEquals(config.getTemplate(), storedConfig.getTemplate());
        } catch (JSONException e) {
            Assert.fail(e.getMessage());
        }
    }

    @Test
    public void persistConfigurationWithComplexTemplate() throws JSONException {
        Context ctx = InstrumentationRegistry.getTargetContext();
        SQLiteDatabase db = new SQLiteOpenHelper(ctx).getWritableDatabase();
        SQLiteConfigurationDAO dao = new SQLiteConfigurationDAO(db);

        Config config = Config.getDefault();
        JSONObject template = new JSONObject(
                "{\"data\":{\"Id\":\"@id\"," +
                        "\"Provider\":\"@provider\"," +
                        "\"Time\":\"@time\"," +
                        "\"Altitude\":\"@altitude\"," +
                        "\"Latitude\":\"@latitude\"," +
                        "\"Longitude\":\"@longitude\"," +
                        "\"Foo\":\"bar\"," +
                        "\"LocationProvider\":\"@locationProvider\"," +
                        "\"Accuracy\":\"@accuracy\"," +
                        "\"Speed\":\"@speed\"," +
                        "\"Bearing\":\"@bearing\"}" +
                        "}"
        );

        LocationTemplate tpl = LocationTemplateFactory.fromJSON(template);
        config.setTemplate(tpl);
        dao.persistConfiguration(config);

        try {
            Config storedConfig = dao.retrieveConfiguration();
            Assert.assertEquals(config.getTemplate(), storedConfig.getTemplate());
        } catch (JSONException e) {
            Assert.fail(e.getMessage());
        }
    }

}