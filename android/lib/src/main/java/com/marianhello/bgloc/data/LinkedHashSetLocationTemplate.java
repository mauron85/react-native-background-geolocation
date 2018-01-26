package com.marianhello.bgloc.data;

import org.json.JSONArray;
import org.json.JSONException;

import java.io.Serializable;
import java.util.Iterator;
import java.util.LinkedHashSet;

/**
 * Created by finch on 9.12.2017.
 */

public class LinkedHashSetLocationTemplate extends AbstractLocationTemplate implements Serializable {
    private LinkedHashSet set;
    private static final long serialVersionUID = 1234L;

    public LinkedHashSetLocationTemplate(LinkedHashSet set) {
        this.set = set;
    }

    @Override
    public Object locationToJson(BackgroundLocation location) {
        JSONArray jArray = new JSONArray();
        if (set == null) {
            return jArray;
        }

        Iterator it = set.iterator();
        while (it.hasNext()) {
            Object value = null;
            Object key = it.next();
            if (key instanceof String) {
                value = location.getValueForKey((String)key);
            }
            jArray.put(value != null ? value : key);
        }

        return jArray;
    }

    public Iterator iterator() {
        return set.iterator();
    }

    public boolean containsKey(String key) {
        return set.contains(key);
    }

    @Override
    public boolean isEmpty() {
        return set == null || set.isEmpty();
    }

    @Override
    public boolean equals(Object other) {
        if (other == null) return false;
        if (other == this) return true;
        if (!(other instanceof LinkedHashSetLocationTemplate)) return false;
        return ((LinkedHashSetLocationTemplate) other).set.equals(this.set);
    }

    @Override
    public String toString() {
        if (set == null) {
            return "null";
        }

        JSONArray jArray = new JSONArray();
        Iterator<?> it = (set).iterator();
        while (it.hasNext()) {
            jArray.put(it.next());
        }
        return jArray.toString();
    }

    public Object[] toArray() {
        if (set == null) {
            return null;
        }

        return set.toArray();
    }
}
