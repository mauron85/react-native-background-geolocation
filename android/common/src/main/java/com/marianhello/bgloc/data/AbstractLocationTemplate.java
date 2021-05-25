package com.marianhello.bgloc.data;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.Serializable;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

/**
 * Created by finch on 9.12.2017.
 */

abstract public class AbstractLocationTemplate implements LocationTemplate, Serializable {
    public static final String BUNDLE_KEY = "template";
    public abstract LocationTemplate clone();

    static class LocationMapper {
        private BackgroundLocation location;

        private LocationMapper() {}

        private Object mapValue(Object value) throws JSONException {
            if (value instanceof String) {
                Object locationValue = location.getValueForKey((String) value);
                return locationValue != null ? locationValue : value;
            } else if (value instanceof Map) {
                return withMap((Map) value);
            } else if (value instanceof List) {
                return withList((List) value);
            }

            return value;
        }

        public JSONArray withList(List values) throws JSONException {
            JSONArray result = new JSONArray();
            Iterator<?> it = values.iterator();
            while (it.hasNext()) {
                Object value = it.next();
                result.put(mapValue(value));
            }

            return result;

        }

        public JSONObject withMap(Map values) throws JSONException {
            JSONObject result = new JSONObject();
            Iterator<?> it = values.entrySet().iterator();
            while (it.hasNext()) {
                Map.Entry<String, Object> pair = (Map.Entry) it.next();
                String key = pair.getKey();
                Object value = pair.getValue();
                result.put(key, mapValue(value));
            }

            return result;
        }

        public static LocationMapper map(BackgroundLocation location) {
            LocationMapper instance = new LocationMapper();
            instance.location = location;
            return instance;
        }
    }
}
