package com.marianhello.bgloc;

import android.os.Parcel;

import com.marianhello.bgloc.Config;
import com.marianhello.bgloc.data.LocationTemplateFactory;

import junit.framework.Assert;

import org.junit.Test;

import java.util.HashMap;
import java.util.LinkedHashSet;

/**
 * Created by finch on 9.12.2017.
 */

public class ConfigTest {
    @Test
    public void testParcelable() {
        Config config = Config.getDefault();

        Parcel configParcel = config.toParcel();
        Config configFromParcel = Config.fromByteArray(configParcel.marshall());

        Assert.assertEquals(config.getStationaryRadius(), configFromParcel.getStationaryRadius());
        Assert.assertEquals(config.getDistanceFilter(), configFromParcel.getDistanceFilter());
        Assert.assertEquals(config.getDesiredAccuracy(), configFromParcel.getDesiredAccuracy());
        Assert.assertFalse(config.isDebugging());
        Assert.assertEquals(config.getNotificationTitle(), configFromParcel.getNotificationTitle());
        Assert.assertEquals(config.getNotificationText(), configFromParcel.getNotificationText());
        Assert.assertTrue(config.getStopOnTerminate());
        Assert.assertFalse(config.getStartOnBoot());
        Assert.assertEquals(config.getLocationProvider(), configFromParcel.getLocationProvider());
        Assert.assertEquals(config.getInterval(), configFromParcel.getInterval());
        Assert.assertEquals(config.getFastestInterval(), configFromParcel.getFastestInterval());
        Assert.assertEquals(config.getActivitiesInterval(), configFromParcel.getActivitiesInterval());
        Assert.assertEquals(config.getNotificationIconColor(), configFromParcel.getNotificationIconColor());
        Assert.assertEquals(config.getLargeNotificationIcon(), configFromParcel.getLargeNotificationIcon());
        Assert.assertEquals(config.getSmallNotificationIcon(), configFromParcel.getSmallNotificationIcon());
        Assert.assertTrue(config.getStartForeground());
        Assert.assertTrue(config.getStopOnStillActivity());
        Assert.assertEquals(config.getUrl(), configFromParcel.getUrl());
        Assert.assertEquals(config.getSyncUrl(), configFromParcel.getSyncUrl());
        Assert.assertEquals(config.getSyncThreshold(), configFromParcel.getSyncThreshold());
        Assert.assertTrue(config.getHttpHeaders().isEmpty());
        Assert.assertEquals(config.getMaxLocations(), configFromParcel.getMaxLocations());
    }

    @Test
    public void testTemplateParcelableFromHashMap() {
        Config config = Config.getDefault();

        HashMap map = new HashMap<String, String>();
        map.put("@id", "id");
        map.put("@provider", "provider");
        map.put("@time", "time");
        map.put("@altitude", "altitude");
        map.put("@latitude", "latitude");
        map.put("@longitude", "longitude");
        map.put("@foo", "foo");
        map.put("@locationProvider", "locationProvider");
        map.put("@accuracy", "accuracy");
        map.put("@speed", "speed");
        map.put("@bearing", "bearing");

        config.setTemplate(LocationTemplateFactory.fromHashMap(map));

        Parcel configParcel = config.toParcel();
        Config configFromParcel = Config.fromByteArray(configParcel.marshall());

        Assert.assertEquals(config.getTemplate(), configFromParcel.getTemplate());
    }

}
