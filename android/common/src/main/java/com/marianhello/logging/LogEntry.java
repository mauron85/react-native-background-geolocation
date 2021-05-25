package com.marianhello.logging;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Collection;

public class LogEntry {
    private Integer id;
    private Integer context;
    private String level;
    private String message;
    private Long timestamp;
    private String loggerName;
    private Collection<String> stackTrace;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

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

    public boolean hasStackTrace() {
        return stackTrace != null;
    }

    public String getStackTrace() {
        if (this.stackTrace == null) {
            return null;
        }

        StringBuilder stackTraceBuilder = new StringBuilder();
        for (String traceLine : this.stackTrace) {
            stackTraceBuilder.append(traceLine).append("\n");
        }
        return stackTraceBuilder.toString();
    }

    public void setStackTrace(Collection<String> stackTrace) {
        this.stackTrace = stackTrace;
    }

    public JSONObject toJSONObject() throws JSONException {
        JSONObject json = new JSONObject();
        json.put("id", this.id);
        json.put("context", this.context);
        json.put("level", this.level);
        json.put("message", this.message);
        json.put("timestamp", this.timestamp);
        json.put("logger", this.loggerName);
        if (hasStackTrace()) {
            json.put("stackTrace", this.getStackTrace());
        }

        return json;
    }
}
