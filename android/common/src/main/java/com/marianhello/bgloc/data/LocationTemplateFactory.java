package com.marianhello.bgloc.data;

import com.marianhello.utils.Convert;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

/**
 * Created by finch on 9.12.2017.
 */

public class LocationTemplateFactory {

    public static LocationTemplate fromJSON(Object json) throws JSONException {
        if (json instanceof JSONObject) {
            JSONObject jsonObject = (JSONObject) json;

            return new HashMapLocationTemplate((HashMap) Convert.toMap(jsonObject));
        } else if (json instanceof JSONArray) {
            JSONArray jsonArray = (JSONArray) json;

            return new ArrayListLocationTemplate((ArrayList) Convert.toList(jsonArray));
        }

        return null;
    }

    public static LocationTemplate fromJSONString(String jsonString) throws JSONException {
        if (jsonString == null) {
            return null;
        }
        Object json = new JSONTokener(jsonString).nextValue();
        return fromJSON(json);
    }

    public static LocationTemplate fromHashMap(HashMap template) {
        return new HashMapLocationTemplate(template);
    }

    public static LocationTemplate fromArrayList(ArrayList template) {
        return new ArrayListLocationTemplate(template);
    }

    public static LocationTemplate getDefault() {
        HashMap attrs = new HashMap<String, String>();
        attrs.put("provider", "@provider");
        attrs.put("locationProvider", "@locationProvider");
        attrs.put("time", "@time");
        attrs.put("latitude", "@latitude");
        attrs.put("longitude", "@longitude");
        attrs.put("accuracy", "@accuracy");
        attrs.put("speed", "@speed");
        attrs.put("altitude", "@altitude");
        attrs.put("bearing", "@bearing");
        attrs.put("radius", "@radius");
        return new HashMapLocationTemplate(attrs);
    }
}
