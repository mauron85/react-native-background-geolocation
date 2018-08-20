package com.marianhello.bgloc.react;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.bridge.WritableMap;
import com.iodine.start.ArrayUtil;
import com.iodine.start.MapUtil;
import com.marianhello.bgloc.Config;
import com.marianhello.bgloc.data.ArrayListLocationTemplate;
import com.marianhello.bgloc.data.HashMapLocationTemplate;
import com.marianhello.bgloc.data.LocationTemplate;
import com.marianhello.bgloc.data.LocationTemplateFactory;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

/**
 * Created by finch on 29.11.2016.
 */

public class ConfigMapper {
    public static Config fromMap(ReadableMap options) throws JSONException {
        Config config = new Config();
        if (options.hasKey("stationaryRadius")) config.setStationaryRadius((float) options.getDouble("stationaryRadius"));
        if (options.hasKey("distanceFilter")) config.setDistanceFilter(options.getInt("distanceFilter"));
        if (options.hasKey("desiredAccuracy")) config.setDesiredAccuracy(options.getInt("desiredAccuracy"));
        if (options.hasKey("debug")) config.setDebugging(options.getBoolean("debug"));
        if (options.hasKey("notificationTitle")) config.setNotificationTitle(
                !options.isNull("notificationTitle") ? options.getString("notificationTitle") : Config.NullString
        );
        if (options.hasKey("notificationText")) config.setNotificationText(
                !options.isNull("notificationText") ? options.getString("notificationText") : Config.NullString
        );
        if (options.hasKey("notificationIconLarge")) config.setLargeNotificationIcon(
                !options.isNull("notificationIconLarge") ? options.getString("notificationIconLarge") : Config.NullString
        );
        if (options.hasKey("notificationIconSmall")) config.setSmallNotificationIcon(
                !options.isNull("notificationIconSmall") ? options.getString("notificationIconSmall") : Config.NullString
        );
        if (options.hasKey("notificationIconColor")) config.setNotificationIconColor(
                !options.isNull("notificationIconColor") ? options.getString("notificationIconColor") : Config.NullString
        );
        if (options.hasKey("stopOnTerminate")) config.setStopOnTerminate(options.getBoolean("stopOnTerminate"));
        if (options.hasKey("startOnBoot")) config.setStartOnBoot(options.getBoolean("startOnBoot"));
        if (options.hasKey("startForeground")) config.setStartForeground(options.getBoolean("startForeground"));
        if (options.hasKey("notificationsEnabled")) config.setNotificationsEnabled(options.getBoolean("notificationsEnabled"));
        if (options.hasKey("locationProvider")) config.setLocationProvider(options.getInt("locationProvider"));
        if (options.hasKey("interval")) config.setInterval(options.getInt("interval"));
        if (options.hasKey("fastestInterval")) config.setFastestInterval(options.getInt("fastestInterval"));
        if (options.hasKey("activitiesInterval")) config.setActivitiesInterval(options.getInt("activitiesInterval"));
        if (options.hasKey("stopOnStillActivity")) config.setStopOnStillActivity(options.getBoolean("stopOnStillActivity"));
        if (options.hasKey("url")) config.setUrl(
                !options.isNull("url") ? options.getString("url") : Config.NullString
        );
        if (options.hasKey("syncUrl")) config.setSyncUrl(
                !options.isNull("syncUrl") ? options.getString("syncUrl") : Config.NullString
        );
        if (options.hasKey("syncThreshold")) config.setSyncThreshold(options.getInt("syncThreshold"));
        if (options.hasKey("httpHeaders")) {
            HashMap httpHeaders = new HashMap<String, String>();
            ReadableType type = options.getType("httpHeaders");
            if (type != ReadableType.Map) {
                throw new JSONException("httpHeaders must be object");
            }
            JSONObject httpHeadersJson =  MapUtil.toJSONObject(options.getMap("httpHeaders"));
            config.setHttpHeaders(httpHeadersJson);
        }
        if (options.hasKey("maxLocations")) config.setMaxLocations(options.getInt("maxLocations"));

        if (options.hasKey("postTemplate")) {
            if (options.isNull("postTemplate")) {
                config.setTemplate(LocationTemplateFactory.getDefault());
            } else {
                ReadableType type = options.getType("postTemplate");
                Object postTemplate = null;
                if (type == ReadableType.Map) {
                    postTemplate = MapUtil.toJSONObject(options.getMap("postTemplate"));
                } else if (type == ReadableType.Array) {
                    postTemplate = ArrayUtil.toJSONArray(options.getArray("postTemplate"));
                }
                config.setTemplate(LocationTemplateFactory.fromJSON(postTemplate));
            }
        }

        return config;
    }

    public static ReadableMap toMap(Config config) {
        WritableMap out = Arguments.createMap();
        WritableMap httpHeaders = Arguments.createMap();
        if (config.getStationaryRadius() != null) {
            out.putDouble("stationaryRadius", config.getStationaryRadius());
        }
        if (config.getDistanceFilter() != null) {
            out.putInt("distanceFilter", config.getDistanceFilter());
        }
        if (config.getDesiredAccuracy() != null) {
            out.putInt("desiredAccuracy", config.getDesiredAccuracy());
        }
        if (config.isDebugging() != null) {
            out.putBoolean("debug", config.isDebugging());
        }
        if (config.getNotificationTitle() != null) {
            if (config.getNotificationTitle() != Config.NullString) {
                out.putString("notificationTitle", config.getNotificationTitle());
            } else {
                out.putNull("notificationTitle");
            }
        }
        if (config.getNotificationText() != null) {
            if (config.getNotificationText() != Config.NullString) {
                out.putString("notificationText", config.getNotificationText());
            } else {
                out.putNull("notificationText");
            }
        }
        if (config.getLargeNotificationIcon() != null) {
            if (config.getLargeNotificationIcon() != Config.NullString) {
                out.putString("notificationIconLarge", config.getLargeNotificationIcon());
            } else {
                out.putNull("notificationIconLarge");
            }
        }
        if (config.getSmallNotificationIcon() != null) {
            if (config.getSmallNotificationIcon() != Config.NullString) {
                out.putString("notificationIconSmall", config.getSmallNotificationIcon());
            } else {
                out.putNull("notificationIconSmall");
            }
        }
        if (config.getNotificationIconColor() != null) {
            if (config.getNotificationIconColor() != Config.NullString) {
                out.putString("notificationIconColor", config.getNotificationIconColor());
            } else {
                out.putNull("notificationIconColor");
            }
        }
        if (config.getStopOnTerminate() != null) {
            out.putBoolean("stopOnTerminate", config.getStopOnTerminate());
        }
        if (config.getStartOnBoot() != null) {
            out.putBoolean("startOnBoot", config.getStartOnBoot());
        }
        if (config.getStartForeground() != null) {
            out.putBoolean("startForeground", config.getStartForeground());
        }
        if (config.getNotificationsEnabled() != null) {
            out.putBoolean("notificationsEnabled", config.getNotificationsEnabled());
        }
        if (config.getLocationProvider() != null) {
            out.putInt("locationProvider", config.getLocationProvider());
        }
        if (config.getInterval() != null) {
            out.putInt("interval", config.getInterval());
        }
        if (config.getFastestInterval() != null) {
            out.putInt("fastestInterval", config.getFastestInterval());
        }
        if (config.getActivitiesInterval() != null) {
            out.putInt("activitiesInterval", config.getActivitiesInterval());
        }
        if (config.getStopOnStillActivity() != null) {
            out.putBoolean("stopOnStillActivity", config.getStopOnStillActivity());
        }
        if (config.getUrl() != null) {
            if (config.getUrl() != Config.NullString) {
                out.putString("url", config.getUrl());
            } else {
                out.putNull("url");
            }
        }
        if (config.getSyncUrl() != null) {
            if (config.getSyncUrl() != Config.NullString) {
                out.putString("syncUrl", config.getSyncUrl());
            } else {
                out.putNull("syncUrl");
            }
        }
        if (config.getSyncThreshold() != null) {
            out.putInt("syncThreshold", config.getSyncThreshold());
        }
        // httpHeaders
        Iterator<Map.Entry<String, String>> it = config.getHttpHeaders().entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry<String, String> pair = it.next();
            httpHeaders.putString(pair.getKey(), pair.getValue());
        }
        out.putMap("httpHeaders", httpHeaders);
        if (config.getMaxLocations() != null) {
            out.putInt("maxLocations", config.getMaxLocations());
        }

        LocationTemplate tpl = config.getTemplate();
        if (tpl instanceof HashMapLocationTemplate) {
            Map map = ((HashMapLocationTemplate)tpl).toMap();
            if (map != null) {
                out.putMap("postTemplate", MapUtil.toWritableMap(map));
            } else {
                out.putNull("postTemplate");
            }
        } else if (tpl instanceof ArrayListLocationTemplate) {
            Object[] keys = ((ArrayListLocationTemplate)tpl).toArray();
            if (keys != null) {
                out.putArray("postTemplate", ArrayUtil.toWritableArray(keys));
            } else {
                out.putNull("postTemplate");
            }
        }
        return out;
    }
}
