package com.marianhello.bgloc;

import android.os.Bundle;

import org.json.JSONException;
import org.json.JSONObject;

public class PluginError {
    public static final int PERMISSION_DENIED_ERROR = 1000;
    public static final int SETTINGS_ERROR = 1001;
    public static final int CONFIGURE_ERROR = 1002;
    public static final int SERVICE_ERROR = 1003;
    public static final int JSON_ERROR = 1004;

    private Integer errorCode;
    private String errorMessage;

    public PluginError(Integer errorCode, String errorMessage) {
        this.errorCode = errorCode;
        this.errorMessage = errorMessage;
    }

    public Integer getErrorCode() {
        return errorCode;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public JSONObject toJSONObject() throws JSONException {
        JSONObject message = new JSONObject();
        message.put("code", this.errorCode);
        message.put("message", this.errorMessage);

        return message;
    }

    public Bundle toBundle() {
        Bundle bundle = new Bundle();
        bundle.putInt("code", this.errorCode);
        bundle.putString("message", this.errorMessage);

        return bundle;
    }
}
