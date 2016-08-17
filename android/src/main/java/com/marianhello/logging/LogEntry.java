package com.marianhello.logging;

import org.json.JSONException;
import org.json.JSONObject;

public class LogEntry {
    private Integer context;
    private String level;
    private String message;
    private Long timestamp;
    private String loggerName;

    public Integer getContext() {
        return context;
    }

    public void setContext(Integer context) {
        this.context = context;
    }

    public String getLevel() {
        return level;
    }

    public void setLevel(String level) {
        this.level = level;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public Long getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Long timestamp) {
        this.timestamp = timestamp;
    }

    public String getLoggerName() {
        return loggerName;
    }

    public void setLoggerName(String loggerName) {
        this.loggerName = loggerName;
    }

    public JSONObject toJSONObject() throws JSONException {
        JSONObject json = new JSONObject();
        json.put("context", this.context);
        json.put("level", this.level);
        json.put("message", this.message);
        json.put("timestamp", this.timestamp);
        json.put("logger", this.loggerName);

        return json;
    }
}
