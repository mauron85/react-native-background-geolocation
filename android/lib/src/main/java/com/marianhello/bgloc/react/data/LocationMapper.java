package com.marianhello.bgloc.react.data;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.utils.Convert;

/**
 * Created by finch on 29.11.2016.
 */

public class LocationMapper {
    public static WritableMap toWriteableMap(BackgroundLocation location) {
        WritableMap out = Arguments.createMap();
        out.putString("provider", location.getProvider());
        Integer locationProvider = location.getLocationProvider();
        if (locationProvider != null) out.putInt("locationProvider", locationProvider);
        out.putDouble("time", new Long(location.getTime()).doubleValue());
        out.putDouble("latitude", location.getLatitude());
        out.putDouble("longitude", location.getLongitude());
        if (location.hasAccuracy()) out.putDouble("accuracy", location.getAccuracy());
        if (location.hasSpeed()) out.putDouble("speed", location.getSpeed());
        if (location.hasAltitude()) out.putDouble("altitude", location.getAltitude());
        if (location.hasBearing()) out.putDouble("bearing", location.getBearing());
        if (location.hasRadius()) out.putDouble("radius", location.getRadius());
        if (location.hasIsFromMockProvider()) out.putBoolean("isFromMockProvider", location.isFromMockProvider());
        if (location.hasMockLocationsEnabled()) out.putBoolean("mockLocationsEnabled", location.areMockLocationsEnabled());

        return out;
    }

    public static WritableMap toWriteableMapWithId(BackgroundLocation location) {
        WritableMap out = toWriteableMap(location);
        Long locationId = location.getLocationId();
        if (locationId != null) out.putInt("id", Convert.safeLongToInt(locationId));

        return out;
    }

}
