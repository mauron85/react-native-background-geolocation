package com.marianhello.bgloc.data;

import org.json.JSONArray;
import org.json.JSONException;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

/**
 * Created by finch on 15.12.2017.
 */

public class ArrayListLocationTemplate extends AbstractLocationTemplate implements Serializable {
    private ArrayList mList;
    private static final long serialVersionUID = 1234L;

    // copy constructor
    public ArrayListLocationTemplate(ArrayListLocationTemplate tpl) {
        if (tpl == null || tpl.mList == null) {
            return;
        }

        mList = new ArrayList();
        Iterator it = tpl.mList.iterator();
        while (it.hasNext()) {
            mList.add(it.next());
        }
    }

    public ArrayListLocationTemplate(ArrayList list) {
        this.mList = list;
    }

    @Override
    public Object locationToJson(BackgroundLocation location) throws JSONException {
        return LocationMapper.map(location).withList(mList);
    }

    public Iterator iterator() {
        return mList.iterator();
    }

    public boolean containsKey(String key) {
        return mList.contains(key);
    }

    @Override
    public boolean isEmpty() {
        return mList == null || mList.isEmpty();
    }

    @Override
    public boolean equals(Object other) {
        if (other == null) return false;
        if (other == this) return true;
        if (!(other instanceof ArrayListLocationTemplate)) return false;
        return ((ArrayListLocationTemplate) other).mList.equals(this.mList);
    }

    @Override
    public String toString() {
        if (mList == null) {
            return "null";
        }

        JSONArray jArray = new JSONArray(mList);
        return jArray.toString();
    }

    public Object[] toArray() {
        if (mList == null) {
            return null;
        }

        return mList.toArray();
    }

    public List toList() {
        return mList;
    }

    @Override
    public LocationTemplate clone() {
        return new ArrayListLocationTemplate(this);
    }
}
