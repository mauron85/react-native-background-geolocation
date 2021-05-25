package com.marianhello.utils;

import java.util.HashMap;
import java.util.Map;

public class CloneHelper {
    public static <K,V> HashMap<K, V> deepCopy(HashMap<K, V> original)
    {
        if (original == null) {
            return null;
        }

        HashMap<K, V> copy = new HashMap();

        //iterate over the map copying values into new map
        for(Map.Entry<K, V> entry : original.entrySet()) {
            copy.put(entry.getKey(),  entry.getValue());
        }

        return copy;
    }
}
