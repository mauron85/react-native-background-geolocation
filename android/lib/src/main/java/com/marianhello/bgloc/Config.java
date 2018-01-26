/*
According to apache license

This is fork of christocracy cordova-plugin-background-geolocation plugin
https://github.com/christocracy/cordova-plugin-background-geolocation

This is a new class
*/

package com.marianhello.bgloc;

import android.os.Bundle;
import android.os.Parcel;
import android.os.Parcelable;

import com.marianhello.bgloc.data.AbstractLocationTemplate;
import com.marianhello.bgloc.data.HashMapLocationTemplate;
import com.marianhello.bgloc.data.LocationTemplate;
import com.marianhello.bgloc.data.LocationTemplateFactory;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Iterator;

/**
 * Config class
 */
public class Config implements Parcelable, Cloneable
{
    public static final String BUNDLE_KEY = "config";

    public static final int DISTANCE_FILTER_PROVIDER = 0;
    public static final int ACTIVITY_PROVIDER = 1;
    public static final int RAW_PROVIDER = 2;

    // actual values should be read from strings.xml
    public static final String ACCOUNT_TYPE_RESOURCE = "account_type";
    public static final String CONTENT_AUTHORITY_RESOURCE = "content_authority";

    private Float stationaryRadius;
    private Integer distanceFilter;
    private Integer desiredAccuracy;
    private Boolean debug;
    private String notificationTitle;
    private String notificationText;
    private String notificationIconLarge;
    private String notificationIconSmall;
    private String notificationIconColor;
    private Integer locationProvider;
    private Integer interval; //milliseconds
    private Integer fastestInterval; //milliseconds
    private Integer activitiesInterval; //milliseconds
    private Boolean stopOnTerminate;
    private Boolean startOnBoot;
    private Boolean startForeground;
    private Boolean stopOnStillActivity;
    private String url;
    private String syncUrl;
    private Integer syncThreshold;
    private HashMap httpHeaders;
    private Integer maxLocations;
    private LocationTemplate template;

    public Config () {
    }

    private Config(Parcel in) {
        setStationaryRadius(in.readFloat());
        setDistanceFilter(in.readInt());
        setDesiredAccuracy(in.readInt());
        setDebugging((Boolean) in.readValue(null));
        setNotificationTitle(in.readString());
        setNotificationText(in.readString());
        setLargeNotificationIcon(in.readString());
        setSmallNotificationIcon(in.readString());
        setNotificationIconColor(in.readString());
        setStopOnTerminate((Boolean) in.readValue(null));
        setStartOnBoot((Boolean) in.readValue(null));
        setStartForeground((Boolean) in.readValue(null));
        setLocationProvider(in.readInt());
        setInterval(in.readInt());
        setFastestInterval(in.readInt());
        setActivitiesInterval(in.readInt());
        setStopOnStillActivity((Boolean) in.readValue(null));
        setUrl(in.readString());
        setSyncUrl(in.readString());
        setSyncThreshold(in.readInt());
        setMaxLocations(in.readInt());
        Bundle bundle = in.readBundle();
        setHttpHeaders((HashMap<String, String>) bundle.getSerializable("httpHeaders"));
        setTemplate((LocationTemplate) bundle.getSerializable(AbstractLocationTemplate.BUNDLE_KEY));
    }

    public static Config getDefault() {
        Config config = new Config();
        config.stationaryRadius = 50f;
        config.distanceFilter = 500;
        config.desiredAccuracy = 100;
        config.debug = false;
        config.notificationTitle = "Background tracking";
        config.notificationText = "ENABLED";
        config.notificationIconLarge = "";
        config.notificationIconSmall = "";
        config.notificationIconColor = "";
        config.locationProvider = DISTANCE_FILTER_PROVIDER;
        config.interval = 600000; //milliseconds
        config.fastestInterval = 120000; //milliseconds
        config.activitiesInterval = 10000; //milliseconds
        config.stopOnTerminate = true;
        config.startOnBoot = false;
        config.startForeground = true;
        config.stopOnStillActivity = true;
        config.url = "";
        config.syncUrl = "";
        config.syncThreshold = 100;
        config.httpHeaders = null;
        config.maxLocations = 10000;
        config.template = null;

        return config;
    }

    public int describeContents() {
        return 0;
    }

    // write your object's data to the passed-in Parcel
    public void writeToParcel(Parcel out, int flags) {
        out.writeFloat(getStationaryRadius());
        out.writeInt(getDistanceFilter());
        out.writeInt(getDesiredAccuracy());
        out.writeValue(isDebugging());
        out.writeString(getNotificationTitle());
        out.writeString(getNotificationText());
        out.writeString(getLargeNotificationIcon());
        out.writeString(getSmallNotificationIcon());
        out.writeString(getNotificationIconColor());
        out.writeValue(getStopOnTerminate());
        out.writeValue(getStartOnBoot());
        out.writeValue(getStartForeground());
        out.writeInt(getLocationProvider());
        out.writeInt(getInterval());
        out.writeInt(getFastestInterval());
        out.writeInt(getActivitiesInterval());
        out.writeValue(getStopOnStillActivity());
        out.writeString(getUrl());
        out.writeString(getSyncUrl());
        out.writeInt(getSyncThreshold());
        out.writeInt(getMaxLocations());
        Bundle bundle = new Bundle();
        bundle.putSerializable("httpHeaders", getHttpHeaders());
        bundle.putSerializable(AbstractLocationTemplate.BUNDLE_KEY, (AbstractLocationTemplate) getTemplate());
        out.writeBundle(bundle);
    }

    public static final Parcelable.Creator<Config> CREATOR
            = new Parcelable.Creator<Config>() {
        public Config createFromParcel(Parcel in) {
            return new Config(in);
        }

        public Config[] newArray(int size) {
            return new Config[size];
        }
    };

    public boolean hasStationaryRadius() {
        return stationaryRadius != null;
    }

    public Float getStationaryRadius() {
        return stationaryRadius;
    }

    public void setStationaryRadius(float stationaryRadius) {
        this.stationaryRadius = stationaryRadius;
    }

    public void setStationaryRadius(double stationaryRadius) {
        this.stationaryRadius = (float) stationaryRadius;
    }

    public boolean hasDesiredAccuracy() {
        return desiredAccuracy != null;
    }

    public Integer getDesiredAccuracy() {
        return desiredAccuracy;
    }

    public void setDesiredAccuracy(Integer desiredAccuracy) {
        this.desiredAccuracy = desiredAccuracy;
    }

    public boolean hasDistanceFilter() {
        return distanceFilter != null;
    }

    public Integer getDistanceFilter() {
        return distanceFilter;
    }

    public void setDistanceFilter(Integer distanceFilter) {
        this.distanceFilter = distanceFilter;
    }

    public boolean hasDebug() {
        return debug != null;
    }

    public Boolean isDebugging() {
        return debug != null && debug;
    }

    public void setDebugging(Boolean debug) {
        this.debug = debug;
    }

    public Boolean hasNotificationIconColor() {
        return notificationIconColor != null && !notificationIconColor.isEmpty();
    }

    public String getNotificationIconColor() {
        return notificationIconColor;
    }

    public void setNotificationIconColor(String notificationIconColor) {
        if ("null".equals(notificationIconColor)) {
            this.notificationIconColor = "";
        } else {
            this.notificationIconColor = notificationIconColor;
        }
    }

    public boolean hasNotificationTitle() {
        return notificationTitle != null;
    }

    public String getNotificationTitle() {
        return notificationTitle;
    }

    public void setNotificationTitle(String notificationTitle) {
        if ("null".equals(notificationTitle)) {
            this.notificationTitle = "";
        } else {
            this.notificationTitle = notificationTitle;
        }
    }

    public boolean hasNotificationText() {
        return notificationText != null;
    }

    public String getNotificationText() {
        return notificationText;
    }

    public void setNotificationText(String notificationText) {
        if ("null".equals(notificationText)) {
            this.notificationText = "";
        } else{
            this.notificationText = notificationText;
        }
    }

    public Boolean hasLargeNotificationIcon() {
        return notificationIconLarge != null && !notificationIconLarge.isEmpty();
    }

    public String getLargeNotificationIcon () {
        return notificationIconLarge;
    }

    public void setLargeNotificationIcon (String icon) {
        if ("null".equals(icon)) {
            this.notificationIconLarge = "";
        } else{
            this.notificationIconLarge = icon;
        }
    }

    public Boolean hasSmallNotificationIcon() {
        return notificationIconSmall != null && !notificationIconSmall.isEmpty();
    }

    public String getSmallNotificationIcon () {
        return notificationIconSmall;
    }

    public void setSmallNotificationIcon (String icon) {
        if ("null".equals(icon)) {
            this.notificationIconSmall = "";
        } else{
            this.notificationIconSmall = icon;
        }
    }

    public boolean hasStopOnTerminate() {
        return stopOnTerminate != null;
    }

    public Boolean getStopOnTerminate() {
        return stopOnTerminate;
    }

    public void setStopOnTerminate(Boolean stopOnTerminate) {
        this.stopOnTerminate = stopOnTerminate;
    }

    public boolean hasStartOnBoot() {
        return startOnBoot != null;
    }

    public Boolean getStartOnBoot() {
        return startOnBoot;
    }

    public void setStartOnBoot(Boolean startOnBoot) {
        this.startOnBoot = startOnBoot;
    }

    public boolean hasStartForeground() {
        return startForeground != null;
    }

    public Boolean getStartForeground() {
        return startForeground;
    }

    public void setStartForeground(Boolean startForeground) {
        this.startForeground = startForeground;
    }

    public boolean hasLocationProvider() {
        return locationProvider != null;
    }

    public Integer getLocationProvider() {
        return locationProvider;
    }

    public void setLocationProvider(Integer locationProvider) {
        this.locationProvider = locationProvider;
    }

    public boolean hasInterval() {
        return interval != null;
    }

    public Integer getInterval() {
        return interval;
    }

    public void setInterval(Integer interval) {
        this.interval = interval;
    }

    public boolean hasFastestInterval() {
        return fastestInterval != null;
    }

    public Integer getFastestInterval() {
        return fastestInterval;
    }

    public void setFastestInterval(Integer fastestInterval) {
        this.fastestInterval = fastestInterval;
    }

    public boolean hasActivitiesInterval() {
        return activitiesInterval != null;
    }

    public Integer getActivitiesInterval() {
        return activitiesInterval;
    }

    public void setActivitiesInterval(Integer activitiesInterval) {
        this.activitiesInterval = activitiesInterval;
    }

    public boolean hasStopOnStillActivity() {
        return stopOnStillActivity != null;
    }

    public Boolean getStopOnStillActivity() {
        return stopOnStillActivity;
    }

    public void setStopOnStillActivity(Boolean stopOnStillActivity) {
        this.stopOnStillActivity = stopOnStillActivity;
    }

    public Boolean hasUrl() {
        return url != null;
    }
    public Boolean hasValidUrl() {
        return url != null && !url.isEmpty();
    }

    public String getUrl() {
        if (!hasUrl()) {
            url = "";
        }
        return url;
    }

    public void setUrl(String url) {
        if ("null".equals(url)) {
            this.url = "";
        } else{
            this.url = url;
        }
    }

    public Boolean hasSyncUrl() {
        return syncUrl != null;
    }
    public Boolean hasValidSyncUrl() {
        return syncUrl != null && !syncUrl.isEmpty();
    }

    public String getSyncUrl() {
        if (!hasSyncUrl()) {
            syncUrl = "";
        }
        return syncUrl;
    }

    public void setSyncUrl(String syncUrl) {
        if ("null".equals(syncUrl)) {
            this.syncUrl = "";
        } else{
            this.syncUrl = syncUrl;
        }
    }

    public boolean hasSyncThreshold() {
        return syncThreshold != null;
    }

    public Integer getSyncThreshold() {
        return syncThreshold;
    }

    public void setSyncThreshold(Integer syncThreshold) {
        this.syncThreshold = syncThreshold;
    }

    public boolean hasHttpHeaders() {
        return httpHeaders != null;
    }

    public HashMap<String, String> getHttpHeaders() {
        if (!hasHttpHeaders()) {
            httpHeaders = new HashMap<String, String>();
        }

        return httpHeaders;
    }

    public void setHttpHeaders(HashMap httpHeaders) {
        this.httpHeaders = httpHeaders;
    }

    public void setHttpHeaders(JSONObject httpHeaders) throws JSONException {
        // intentionally set httpHeaders to empty hash map
        // this allows to reset headers in .fromJSONArray providing empty httpHeaders JSONObject
        this.httpHeaders = new HashMap<String, String>();
        if (httpHeaders == null) {
            return;
        }
        Iterator<?> it = httpHeaders.keys();
        while (it.hasNext()) {
            String key = (String) it.next();
            this.httpHeaders.put(key, httpHeaders.getString(key));
        }
    }

    public boolean hasMaxLocations() {
        return maxLocations != null;
    }

    public Integer getMaxLocations() {
        return maxLocations;
    }

    public void setMaxLocations(Integer maxLocations) {
        this.maxLocations = maxLocations;
    }

    public boolean hasTemplate() {
        return template != null;
    }

    public LocationTemplate getTemplate() {
        if (!hasTemplate()) {
            template = LocationTemplateFactory.getDefault();
        }
        return template;
    }

    public void setTemplate(LocationTemplate template) {
        this.template = template;
    }

    @Override
    public String toString () {
        return new StringBuffer()
                .append("Config[distanceFilter=").append(getDistanceFilter())
                .append(" stationaryRadius=").append(getStationaryRadius())
                .append(" desiredAccuracy=").append(getDesiredAccuracy())
                .append(" interval=").append(getInterval())
                .append(" fastestInterval=").append(getFastestInterval())
                .append(" activitiesInterval=").append(getActivitiesInterval())
                .append(" isDebugging=").append(isDebugging())
                .append(" stopOnTerminate=" ).append(getStopOnTerminate())
                .append(" stopOnStillActivity=").append(getStopOnStillActivity())
                .append(" startOnBoot=").append(getStartOnBoot())
                .append(" startForeground=").append(getStartForeground())
                .append(" locationProvider=").append(getLocationProvider())
                .append(" nTitle=").append(getNotificationTitle())
                .append(" nText=").append(getNotificationText())
                .append(" nIconLarge=").append(getLargeNotificationIcon())
                .append(" nIconSmall=").append(getSmallNotificationIcon())
                .append(" nIconColor=").append(getNotificationIconColor())
                .append(" url=").append(getUrl())
                .append(" syncUrl=").append(getSyncUrl())
                .append(" syncThreshold=").append(getSyncThreshold())
                .append(" httpHeaders=").append(getHttpHeaders().toString())
                .append(" maxLocations=").append(getMaxLocations())
                .append(" postTemplate=").append(hasTemplate() ? getTemplate().toString() : null)
                .append("]")
                .toString();
    }

    public Parcel toParcel () {
        Parcel parcel = Parcel.obtain();
        this.writeToParcel(parcel, 0);
        parcel.setDataPosition(0);
        return parcel;
    }

    public Bundle toBundle () {
        Bundle bundle = new Bundle();
        bundle.putParcelable(BUNDLE_KEY, this);
        return bundle;
    }

    public static Config merge(Config config1, Config config2) throws CloneNotSupportedException {
        Config merger = (Config) config1.clone();

        if (config2.hasStationaryRadius()) {
            merger.setStationaryRadius(config2.getStationaryRadius());
        }
        if (config2.hasDistanceFilter()) {
            merger.setDistanceFilter(config2.getDistanceFilter());
        }
        if (config2.hasDesiredAccuracy()) {
            merger.setDesiredAccuracy(config2.getDesiredAccuracy());
        }
        if (config2.hasDebug()) {
            merger.setDebugging(config2.isDebugging());
        }
        if (config2.hasNotificationTitle()) {
            merger.setNotificationTitle(config2.getNotificationTitle());
        }
        if (config2.hasNotificationText()) {
            merger.setNotificationText(config2.getNotificationText());
        }
        if (config2.hasStopOnTerminate()) {
            merger.setStopOnTerminate(config2.getStopOnTerminate());
        }
        if (config2.hasStartOnBoot()) {
            merger.setStartOnBoot(config2.getStartOnBoot());
        }
        if (config2.hasLocationProvider()) {
            merger.setLocationProvider(config2.getLocationProvider());
        }
        if (config2.hasInterval()) {
            merger.setInterval(config2.getInterval());
        }
        if (config2.hasFastestInterval()) {
            merger.setFastestInterval(config2.getFastestInterval());
        }
        if (config2.hasActivitiesInterval()) {
            merger.setActivitiesInterval(config2.getActivitiesInterval());
        }
        if (config2.hasNotificationIconColor()) {
            merger.setNotificationIconColor(config2.getNotificationIconColor());
        }
        if (config2.hasLargeNotificationIcon()) {
            merger.setLargeNotificationIcon(config2.getLargeNotificationIcon());
        }
        if (config2.hasSmallNotificationIcon()) {
            merger.setSmallNotificationIcon(config2.getSmallNotificationIcon());
        }
        if (config2.hasStartForeground()) {
            merger.setStartForeground(config2.getStartForeground());
        }
        if (config2.hasStopOnStillActivity()) {
            merger.setStopOnStillActivity(config2.getStopOnStillActivity());
        }
        if (config2.hasUrl()) {
            merger.setUrl(config2.getUrl());
        }
        if (config2.hasSyncUrl()) {
            merger.setSyncUrl(config2.getSyncUrl());
        }
        if (config2.hasSyncThreshold()) {
            merger.setSyncThreshold(config2.getSyncThreshold());
        }
        if (config2.hasHttpHeaders()) {
            merger.setHttpHeaders(config2.getHttpHeaders());
        }
        if (config2.hasMaxLocations()) {
            merger.setMaxLocations(config2.getMaxLocations());
        }
        if (config2.hasTemplate()) {
            merger.setTemplate(config2.getTemplate());
        }

        return merger;
    }

    public static Config fromByteArray (byte[] byteArray) {
        Parcel parcel = Parcel.obtain();
        parcel.unmarshall(byteArray, 0, byteArray.length);
        parcel.setDataPosition(0);
        return Config.CREATOR.createFromParcel(parcel);
    }
}
