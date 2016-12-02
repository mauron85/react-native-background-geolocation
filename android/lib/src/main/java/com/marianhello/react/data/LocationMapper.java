package com.marianhello.react.data;

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
        Integer locationProvider = location.getLocationProvider();
        if (locationProvider != null) out.putInt("locationProvider", locationProvider);
        out.putDouble("time", new Long(location.getTime()).doubleValue());
        out.putDouble("latitude", location.getLatitude());
        out.putDouble("longitude", location.getLongitude());
        out.putDouble("accuracy", location.getAccuracy());
        out.putDouble("speed", location.getSpeed());
        out.putDouble("altitude", location.getAltitude());
        out.putDouble("bearing", location.getBearing());

        return out;
    }

    public static WritableMap toWriteableMapWithId(BackgroundLocation location) {
        WritableMap out = toWriteableMap(location);
        Long locationId = location.getLocationId();
        if (locationId != null) out.putInt("locationId", Convert.safeLongToInt(locationId));

        return out;
    }

}
