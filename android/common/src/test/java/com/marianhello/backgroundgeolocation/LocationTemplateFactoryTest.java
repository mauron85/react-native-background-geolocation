package com.marianhello.backgroundgeolocation;

import com.marianhello.bgloc.data.LocationTemplate;
import com.marianhello.bgloc.data.LocationTemplateFactory;

import junit.framework.Assert;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;
import org.junit.Test;

/**
 * Created by finch on 9.12.2017.
 */

public class LocationTemplateFactoryTest {
    @Test
    public void testTemplateFromJsonArray() {
        String jsonString = "[\"foo\",\"bar\",123]";

        try {
            LocationTemplate tpl = LocationTemplateFactory.fromJSONString(jsonString);
            JSONArray expected = new JSONArray();
            expected.put("foo");
            expected.put("bar");
            expected.put(123);
            Assert.assertEquals(expected.toString(), tpl.toString());
        } catch (JSONException e) {
            org.junit.Assert.fail(e.getMessage());
        }
    }

    @Test
    public void testTemplateFromJsonObject() {
        String jsonString = "{\"foo\":\"bar\",\"pretzels\":123}";

        try {
            LocationTemplate tpl = LocationTemplateFactory.fromJSONString(jsonString);
            JSONObject expected = new JSONObject();
            expected.put("foo", "bar");
            expected.put("pretzels", 123);
            Assert.assertEquals(expected.toString(), tpl.toString());
        } catch (JSONException e) {
            org.junit.Assert.fail(e.getMessage());
        }
    }

}
