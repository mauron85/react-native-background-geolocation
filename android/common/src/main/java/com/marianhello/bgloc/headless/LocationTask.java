package com.marianhello.bgloc.headless;

import android.os.Bundle;

import com.marianhello.bgloc.data.BackgroundLocation;

import org.json.JSONException;

public abstract class LocationTask extends Task {
    protected BackgroundLocation mLocation;

    public LocationTask(BackgroundLocation location) {
        mLocation = location;
    }

    @Override
    public String getName() {
        return "location";
    }

    @Override
    public Bundle getBundle() {
        Bundle bundle = new Bundle();
        Bundle params = new Bundle();

        params.putString("provider", mLocation.getProvider());
        params.putInt("locationProvider", mLocation.getLocationProvider());
        params.putLong("time", mLocation.getTime());
        params.putDouble("latitude", mLocation.getLatitude());
        params.putDouble("longitude", mLocation.getLongitude());
        if (mLocation.hasAccuracy()) params.putFloat("accuracy", mLocation.getAccuracy());
        if (mLocation.hasSpeed()) params.putFloat("speed", mLocation.getSpeed());
        if (mLocation.hasAltitude()) params.putDouble("altitude", mLocation.getAltitude());
        if (mLocation.hasBearing()) params.putFloat("bearing", mLocation.getBearing());
        if (mLocation.hasRadius()) params.putFloat("radius", mLocation.getRadius());
        if (mLocation.hasIsFromMockProvider()) params.putBoolean("isFromMockProvider", mLocation.isFromMockProvider());
        if (mLocation.hasMockLocationsEnabled()) params.putBoolean("mockLocationsEnabled", mLocation.areMockLocationsEnabled());

        bundle.putString("name", getName());
        bundle.putBundle("params", params);

        return bundle;
    }

    @Override
    public String toString() {
        if (mLocation == null) {
            return null;
        }

        try {
            return mLocation.toJSONObject().toString();
        } catch (JSONException e) {
            onError("Error processing params: " + e.getMessage());
        }

        return null;
    }
}
