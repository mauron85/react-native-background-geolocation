package com.marianhello.bgloc.data;

import org.json.JSONException;

/**
 * Created by finch on 9.12.2017.
 */

public interface LocationTemplate {
    Object locationToJson(BackgroundLocation location) throws JSONException;
    boolean isEmpty();
}
