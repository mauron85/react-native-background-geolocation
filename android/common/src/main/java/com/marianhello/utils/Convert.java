/*
 * Kindly taken from
 * http://stackoverflow.com/questions/1590831/safely-casting-long-to-int-in-java
 */

package com.marianhello.utils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

public class Convert {

  public static int safeLongToInt(long l) {
    if (l < Integer.MIN_VALUE || l > Integer.MAX_VALUE) {
      throw new IllegalArgumentException
        (l + " cannot be cast to int without changing its value.");
    }
    return (int) l;
  }

  public static Map<String, Object> toMap(JSONObject jsonobj)  throws JSONException {
    Map<String, Object> map = new HashMap<String, Object>();
    Iterator<String> keys = jsonobj.keys();
    while(keys.hasNext()) {
      String key = keys.next();
      Object value = jsonobj.get(key);
      if (value instanceof JSONArray) {
        value = toList((JSONArray) value);
      } else if (value instanceof JSONObject) {
        value = toMap((JSONObject) value);
      }
      map.put(key, value);
    }   return map;
  }

  public static List<Object> toList(JSONArray array) throws JSONException {
    List<Object> list = new ArrayList<Object>();
    for(int i = 0; i < array.length(); i++) {
      Object value = array.get(i);
      if (value instanceof JSONArray) {
        value = toList((JSONArray) value);
      }
      else if (value instanceof JSONObject) {
        value = toMap((JSONObject) value);
      }
      list.add(value);
    }   return list;
  }
}
