package com.marianhello.bgloc.data;

import org.json.JSONArray;
import org.json.JSONException;

import java.util.ArrayList;
import java.util.Iterator;

/**
 * Created by finch on 15.12.2017.
 */

public class ArrayListLocationTemplate implements LocationTemplate {
    private ArrayList list;
    private static final long serialVersionUID = 1234L;

    public ArrayListLocationTemplate(ArrayList list) {
        this.list = list;
    }

    @Override
    public Object locationToJson(BackgroundLocation location) throws JSONException {
        JSONArray jArray = new JSONArray();
        if (list == null) {
            return jArray;
        }

        Iterator it = list.iterator();
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
        return list.iterator();
    }

    public boolean containsKey(String key) {
        return list.contains(key);
    }

    @Override
    public boolean isEmpty() {
        return list == null || list.isEmpty();
    }

    @Override
    public boolean equals(Object other) {
        if (other == null) return false;
        if (other == this) return true;
        if (!(other instanceof ArrayListLocationTemplate)) return false;
        return ((ArrayListLocationTemplate) other).list.equals(this.list);
    }

    @Override
    public String toString() {
        if (list == null) {
            return "null";
        }

        JSONArray jArray = new JSONArray();
        Iterator<?> it = (list).iterator();
        while (it.hasNext()) {
            jArray.put(it.next());
        }
        return jArray.toString();
    }

    public Object[] toArray() {
        if (list == null) {
            return null;
        }

        return list.toArray();
    }
}
