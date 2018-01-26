package com.marianhello.backgroundgeolocation;

import android.os.Build;
import android.test.suitebuilder.annotation.SmallTest;

import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.HashMapLocationTemplate;
import com.marianhello.bgloc.data.LinkedHashSetLocationTemplate;
import com.marianhello.bgloc.data.LocationTemplate;

import junit.framework.Assert;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Test;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.util.HashMap;
import java.util.LinkedHashSet;

/**
 * Created by finch on 10/08/16.
 */
@SmallTest
public class BackgroundLocationTest {

    static void setSDKVersion(Object newValue) {

        Field modifiersField = null;
        try {
            Field field = Build.VERSION.class.getField("SDK_INT");

            field.setAccessible(true);

            modifiersField = Field.class.getDeclaredField("modifiers");
            modifiersField.setAccessible(true);
            modifiersField.setInt(field, field.getModifiers() & ~Modifier.FINAL);

            field.set(null, newValue);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Test
    public void olderLocationShouldBeWorse() {
        setSDKVersion(17);

        BackgroundLocation netLocation = new BackgroundLocation();
        netLocation.setProvider("network");
        netLocation.setLatitude(49);
        netLocation.setLongitude(5);
        netLocation.setAccuracy(38);
        netLocation.setElapsedRealtimeNanos(1470776557324L * 1000000L);

        BackgroundLocation gpsLocation = new BackgroundLocation();
        gpsLocation.setProvider("gps");
        gpsLocation.setLatitude(49);
        gpsLocation.setLongitude(5);
        gpsLocation.setAccuracy(5);
        gpsLocation.setElapsedRealtimeNanos(1470773246000L * 1000000L);

        Assert.assertFalse(gpsLocation.isBetterLocationThan(netLocation));
    }

    @Test
    public void newerLocationShouldBeBetter() {
        setSDKVersion(17);

        BackgroundLocation netLocation = new BackgroundLocation();
        netLocation.setProvider("network");
        netLocation.setLatitude(49);
        netLocation.setLongitude(5);
        netLocation.setAccuracy(38);
        netLocation.setElapsedRealtimeNanos(0);

        BackgroundLocation gpsLocation = new BackgroundLocation();
        gpsLocation.setProvider("gps");
        gpsLocation.setLatitude(49);
        gpsLocation.setLongitude(5);
        gpsLocation.setAccuracy(105);
        gpsLocation.setElapsedRealtimeNanos(2000000000L * 60 * 2);

        Assert.assertFalse(netLocation.isBetterLocationThan(gpsLocation));
    }
}