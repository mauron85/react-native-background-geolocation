package com.marianhello.bgloc.provider;

public class TestLocationProviderFactory extends LocationProviderFactory {
    private LocationProvider mProvider = new MockLocationProvider();

    public TestLocationProviderFactory() {
        super(null);
    }

    public LocationProvider getInstance (Integer locationProvider) {
        return mProvider;
    }

    public void setProvider(LocationProvider provider) {
        mProvider = mProvider;
    }
}
