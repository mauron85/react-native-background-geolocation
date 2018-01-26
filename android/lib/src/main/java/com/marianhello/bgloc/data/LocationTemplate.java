package com.marianhello.bgloc.data;

import org.json.JSONException;

/**
 * Created by finch on 9.12.2017.
 */

public interface LocationTemplate {
    boolean isEmpty();
    Object locationToJson(BackgroundLocation location) throws JSONException;
}
