package com.marianhello.bgloc.headless;

import android.os.Bundle;

import com.marianhello.bgloc.data.BackgroundLocation;

import org.json.JSONException;

public abstract class StationaryTask extends LocationTask {
    public StationaryTask(BackgroundLocation location) {
        super(location);
    }

    @Override
    public String getName() {
        return "stationary";
    }

    @Override
    public Bundle getBundle() {
        Bundle bundle = super.getBundle();

        return bundle;
    }
}
