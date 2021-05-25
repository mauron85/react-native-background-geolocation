package com.marianhello.bgloc.data;

import com.marianhello.utils.CloneHelper;

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
    private HashMap<?, String> mMap;
    private static final long serialVersionUID = 1234L;

    // copy constructor
    public HashMapLocationTemplate(HashMapLocationTemplate tpl) {
        if (tpl == null || tpl.mMap == null) {
            return;
        }

        mMap = CloneHelper.deepCopy(tpl.mMap);
    }

    public HashMapLocationTemplate(HashMap map) {
        this.mMap = map;
    }

    @Override
    public Object locationToJson(BackgroundLocation location) throws JSONException {
        return LocationMapper.map(location).withMap(mMap);
    }

    public Iterator iterator() {
        return mMap.entrySet().iterator();
    }

    public boolean containsKey(String propName) {
        return mMap.containsKey(propName);
    }

    public String get(String key) {
        return mMap.get(key);
    }

    @Override
    public boolean isEmpty() {
        return mMap == null || mMap.isEmpty();
    }

    @Override
    public boolean equals(Object other) {
        if (other == null) return false;
        if (other == this) return true;
        if (!(other instanceof HashMapLocationTemplate)) return false;
        return ((HashMapLocationTemplate) other).mMap.equals(this.mMap);
    }

    @Override
    public String toString() {
        if (mMap == null) {
            return "null";
        }

        JSONObject jObject = new JSONObject(mMap);
        return jObject.toString();
    }

    public Map toMap() {
        return mMap;
    }

    @Override
    public LocationTemplate clone() {
        return new HashMapLocationTemplate(this);
    }
}
