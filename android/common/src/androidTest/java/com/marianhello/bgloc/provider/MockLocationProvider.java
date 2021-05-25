package com.marianhello.bgloc.provider;

import android.location.Location;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public class MockLocationProvider extends AbstractLocationProvider {
    private boolean mIsStarted = false;
    private List<Location> mMockLocations = new ArrayList();

    public MockLocationProvider() {
        super(null);
        PROVIDER_ID = 99;
    }

    @Override
    public void onStart() {
        mIsStarted = true;
        Iterator<Location> it = mMockLocations.iterator();
        while(mIsStarted && it.hasNext()) {
            handleLocation(it.next());
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                mIsStarted = false;
            }
        }
    }

    @Override
    public void onStop() {
        mIsStarted = false;
    }

    @Override
    public boolean isStarted() {
        return false;
    }

    @Override
    public Boolean hasMockLocationsEnabled() {
        return true;
    }

    public void setMockLocations(List<Location> locations) {
        mMockLocations = locations;
    }
}
