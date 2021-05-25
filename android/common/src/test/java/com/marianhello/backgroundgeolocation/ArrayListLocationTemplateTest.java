package com.marianhello.backgroundgeolocation;

import com.marianhello.bgloc.data.ArrayListLocationTemplate;
import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.LocationTemplate;

import junit.framework.Assert;

import org.json.JSONArray;
import org.json.JSONException;
import org.junit.Test;

import java.util.ArrayList;

/**
 * Created by finch on 15.12.2017.
 */

public class ArrayListLocationTemplateTest {
    @Test
    public void testArrayTemplateToString() {
        ArrayList props = new ArrayList();
        props.add("foo");
        props.add("bar");
        props.add(123);
        props.add("foo");
        ArrayListLocationTemplate tpl = new ArrayListLocationTemplate(props);

        Assert.assertEquals("[\"foo\",\"bar\",123,\"foo\"]" , tpl.toString());
    }

    @Test
    public void testLocationToJSONArray() throws JSONException {
        BackgroundLocation location = new BackgroundLocation();
        location.setLocationId(11L);
        location.setProvider("test");
        location.setElapsedRealtimeNanos(2000000000L * 60 * 2);
        location.setAltitude(100);
        location.setLatitude(49);
        location.setLongitude(5);
        location.setLocationProvider(1);
        location.setAccuracy(105);
        location.setSpeed(50);
        location.setBearing(1);

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
        props.add(123);

        LocationTemplate tpl = new ArrayListLocationTemplate(props);
        JSONArray expected = (JSONArray) tpl.locationToJson(location);

        Assert.assertEquals(expected.get(0), location.getLocationId());
        Assert.assertEquals(expected.get(1), location.getProvider());
        Assert.assertEquals(expected.get(2), location.getTime());
        Assert.assertEquals(expected.get(3), location.getAltitude());
        Assert.assertEquals(expected.get(4), location.getLatitude());
        Assert.assertEquals(expected.get(5), location.getLongitude());
        Assert.assertEquals(expected.get(6), "foo");
        Assert.assertEquals(expected.get(7), location.getLocationProvider());
        Assert.assertEquals(expected.get(8), location.getAccuracy());
        Assert.assertEquals(expected.get(9), location.getSpeed());
        Assert.assertEquals(expected.get(10), location.getBearing());
        Assert.assertEquals(expected.get(11), 123);
    }

    @Test
    public void testNullToString() {
        ArrayListLocationTemplate tpl = new ArrayListLocationTemplate((ArrayList)null);
        Assert.assertEquals("null", tpl.toString());
    }
}
