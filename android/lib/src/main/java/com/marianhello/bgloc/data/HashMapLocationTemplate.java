package com.marianhello.bgloc.data;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

/**
 * Created by finch on 9.12.2017.
 */

public class HashMapLocationTemplate extends AbstractLocationTemplate implements Serializable {
    private HashMap<?, String> map;
    private static final long serialVersionUID = 1234L;

    public HashMapLocationTemplate(HashMap map) {
        this.map = map;
    }

    @Override
    public Object locationToJson(BackgroundLocation location) throws JSONException {
        JSONObject jObject = new JSONObject();

        Iterator<?> it = map.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry<String, Object> pair = (Map.Entry) it.next();
            Object value = null;
            Object key = pair.getValue();
            if (key instanceof String) {
                value = location.getValueForKey((String)key);
            }
            jObject.put(pair.getKey(), value != null ? value : pair.getValue());
        }

        return jObject;
    }

    public Iterator iterator() {
        return map.entrySet().iterator();
    }

    public boolean containsKey(String propName) {
        return map.containsKey(propName);
    }

    public String get(String key) {
        return map.get(key);
    }

    @Override
    public boolean isEmpty() {
        return map == null || map.isEmpty();
    }

    @Override
    public boolean equals(Object other) {
        if (other == null) return false;
        if (other == this) return true;
        if (!(other instanceof HashMapLocationTemplate)) return false;
        return ((HashMapLocationTemplate) other).map.equals(this.map);
    }

    @Override
    public String toString() {
        if (map == null) {
            return "null";
        }

        JSONObject jObject = new JSONObject(map);
        return jObject.toString();
    }

    public Map toMap() {
        return map;
    }
}
