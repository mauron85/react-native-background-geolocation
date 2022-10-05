package com.marianhello.bgloc.react;

import android.content.Context;
import androidx.test.InstrumentationRegistry;
import androidx.test.runner.AndroidJUnit4;
import androidx.test.filters.SmallTest;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.soloader.SoLoader;
import com.marianhello.bgloc.Config;
import com.marianhello.bgloc.data.ArrayListLocationTemplate;
import com.marianhello.bgloc.data.HashMapLocationTemplate;
import com.marianhello.bgloc.data.LocationTemplate;
import com.marianhello.bgloc.data.LocationTemplateFactory;

import junit.framework.Assert;

import org.json.JSONException;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;

@RunWith(AndroidJUnit4.class)
@SmallTest
public class ConfigMapperTest {

    private Context mContext;

    @Before
    public void setUp() throws IOException {
        Context mContext = InstrumentationRegistry.getContext();
        SoLoader.init(mContext, 0);
    }

    @Test
    public void testDefaultToJSONObject() {
        Config config = Config.getDefault();
        ReadableMap map = ConfigMapper.toMap(config);

        Assert.assertEquals(config.getStationaryRadius(), map.getDouble("stationaryRadius"), 0f);
        Assert.assertEquals(config.getDistanceFilter().intValue(), map.getInt("distanceFilter"));
        Assert.assertEquals(config.getDesiredAccuracy().intValue(), map.getInt("desiredAccuracy"));
        Assert.assertEquals(config.isDebugging().booleanValue(), map.getBoolean("debug"));
        Assert.assertEquals(config.getNotificationTitle(), map.getString("notificationTitle"));
        Assert.assertEquals(config.getNotificationText(), map.getString("notificationText"));
        Assert.assertEquals(config.getStopOnTerminate().booleanValue(), map.getBoolean("stopOnTerminate"));
        Assert.assertEquals(config.getStartOnBoot().booleanValue(), map.getBoolean("startOnBoot"));
        Assert.assertEquals(config.getLocationProvider().intValue(), map.getInt("locationProvider"));
        Assert.assertEquals(config.getInterval().intValue(), map.getInt("interval"));
        Assert.assertEquals(config.getFastestInterval().intValue(), map.getInt("fastestInterval"));
        Assert.assertEquals(config.getActivitiesInterval().intValue(), map.getInt("activitiesInterval"));
        Assert.assertEquals(config.getNotificationIconColor(), map.getString("notificationIconColor"));
        Assert.assertEquals(config.getLargeNotificationIcon(), map.getString("notificationIconLarge"));
        Assert.assertEquals(config.getSmallNotificationIcon(), map.getString("notificationIconSmall"));
        Assert.assertEquals(config.getStartForeground().booleanValue(), map.getBoolean("startForeground"));
        Assert.assertEquals(config.getStopOnStillActivity().booleanValue(), map.getBoolean("stopOnStillActivity"));
        Assert.assertEquals(config.getUrl(), map.getString("url"));
        Assert.assertEquals(config.getSyncUrl(), map.getString("syncUrl"));
        Assert.assertEquals(config.getSyncThreshold().intValue(), map.getInt("syncThreshold"));
        Assert.assertEquals(config.getHttpHeaders(), map.getMap("httpHeaders").toHashMap());
        Assert.assertEquals(config.getMaxLocations().intValue(), map.getInt("maxLocations"));
        Assert.assertEquals(LocationTemplateFactory.getDefault(), LocationTemplateFactory.fromHashMap(map.getMap("postTemplate").toHashMap()));
    }

    @Test
    public void testNullableProps() throws JSONException {
        WritableMap map = Arguments.createMap();
        map.putNull("url");
        map.putNull("syncUrl");
        map.putNull("notificationIconColor");
        map.putNull("notificationTitle");
        map.putNull("notificationText");
        map.putNull("notificationIconLarge");
        map.putNull("notificationIconSmall");

        Config config = ConfigMapper.fromMap((ReadableMap)map);

        Assert.assertEquals(Config.NullString, config.getUrl());
        Assert.assertTrue(config.hasUrl());
        Assert.assertFalse(config.hasValidUrl());

        Assert.assertEquals(Config.NullString, config.getSyncUrl());
        Assert.assertTrue(config.hasSyncUrl());
        Assert.assertFalse(config.hasValidSyncUrl());

        Assert.assertEquals(Config.NullString, config.getNotificationIconColor());
        Assert.assertFalse(config.hasNotificationIconColor());

        Assert.assertEquals(Config.NullString, config.getNotificationTitle());
        Assert.assertTrue(config.hasNotificationTitle());

        Assert.assertEquals(Config.NullString, config.getNotificationText());
        Assert.assertTrue(config.hasNotificationText());

        Assert.assertEquals(Config.NullString, config.getLargeNotificationIcon());
        Assert.assertFalse(config.hasLargeNotificationIcon());

        Assert.assertEquals(Config.NullString, config.getSmallNotificationIcon());
        Assert.assertFalse(config.hasSmallNotificationIcon());
    }

    @Test
    public void testNullablePropsToJSONObject() throws JSONException {
        Config config = new Config();
        config.setUrl(Config.NullString);
        config.setSyncUrl(Config.NullString);
        config.setNotificationIconColor(Config.NullString);
        config.setNotificationTitle(Config.NullString);
        config.setNotificationText(Config.NullString);
        config.setLargeNotificationIcon(Config.NullString);
        config.setSmallNotificationIcon(Config.NullString);

        ReadableMap map = ConfigMapper.toMap(config);

        Assert.assertEquals(null, map.getString("url"));
        Assert.assertEquals(null, map.getString("syncUrl"));
        Assert.assertEquals(null, map.getString("notificationIconColor"));
        Assert.assertEquals(null, map.getString("notificationTitle"));
        Assert.assertEquals(null, map.getString("notificationText"));
        Assert.assertEquals(null, map.getString("notificationIconLarge"));
        Assert.assertEquals(null, map.getString("notificationIconSmall"));
    }

    @Test
    public void testNullHashMapTemplateToJSONObject() {
        Config config = new Config();
        LocationTemplate tpl = new HashMapLocationTemplate((HashMap)null);
        config.setTemplate(tpl);

        ReadableMap jConfig = ConfigMapper.toMap(config);
        Assert.assertEquals(null, jConfig.getMap("postTemplate"));
    }

    @Test
    public void testEmptyHashMapTemplateToJSONObject() {
        Config config = new Config();
        HashMap map = new HashMap();
        LocationTemplate tpl = new HashMapLocationTemplate(map);
        config.setTemplate(tpl);

        ReadableMap jConfig = ConfigMapper.toMap(config);
        Assert.assertFalse(jConfig.getMap("postTemplate").keySetIterator().hasNextKey());
    }

    @Test
    public void testHashMapTemplateToJSONObject() {
        Config config = new Config();
        HashMap map = new HashMap();
        map.put("foo", "bar");
        map.put("pretzels", 123);
        LocationTemplate tpl = new HashMapLocationTemplate(map);
        config.setTemplate(tpl);

        ReadableMap jConfig = ConfigMapper.toMap(config);
        Assert.assertEquals("{ NativeMap: {\"foo\":\"bar\",\"pretzels\":123} }", jConfig.getMap("postTemplate").toString());
    }

    @Test
    public void testNullArrayListLocationTemplateToJSONObject() {
        Config config = new Config();
        LocationTemplate tpl = new ArrayListLocationTemplate((ArrayListLocationTemplate)null);
        config.setTemplate(tpl);

        ReadableMap jConfig = ConfigMapper.toMap(config);
        Assert.assertEquals(null, jConfig.getMap("postTemplate"));
    }

    @Test
    public void testEmptyArrayListLocationTemplateToJSONObject() {
        Config config = new Config();
        ArrayList list = new ArrayList();
        LocationTemplate tpl = new ArrayListLocationTemplate(list);
        config.setTemplate(tpl);

        ReadableMap jConfig = ConfigMapper.toMap(config);
        Assert.assertTrue(jConfig.getArray("postTemplate").size() == 0);
    }

    @Test
    public void testArrayListLocationTemplateToJSONObject() {
        Config config = new Config();
        ArrayList list = new ArrayList();
        list.add("foo");
        list.add(123);
        list.add("foo");

        LocationTemplate tpl = new ArrayListLocationTemplate(list);
        config.setTemplate(tpl);

        ReadableMap jConfig = ConfigMapper.toMap(config);
        Assert.assertEquals("[\"foo\",123,\"foo\"]", jConfig.getArray("postTemplate").toString());
    }
}