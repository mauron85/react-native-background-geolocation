package com.marianhello.cordova;

import org.json.JSONException;
import org.json.JSONObject;

public class JSONErrorFactory {

    public static JSONObject getJSONError(Integer errorCode, String errorMessage) {
        JSONObject message = new JSONObject();
        try {
            message.put("code", errorCode);
            message.put("message", errorMessage);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        return message;
    }
}
