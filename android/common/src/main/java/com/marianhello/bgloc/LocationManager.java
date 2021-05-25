package com.marianhello.bgloc;

import android.Manifest;
import android.annotation.SuppressLint;
import android.content.Context;
import android.location.Criteria;
import android.location.Location;
import android.location.LocationListener;
import android.os.Bundle;
import android.os.Looper;

import com.github.jparkie.promise.Promise;
import com.github.jparkie.promise.Promises;
import com.intentfilter.androidpermissions.PermissionManager;

import java.util.Arrays;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

public class LocationManager {
    private Context mContext;
    private static LocationManager mLocationManager;

    public static final String[] PERMISSIONS = {
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_FINE_LOCATION
    };

    private LocationManager(Context context) {
        mContext = context;
    }

    public class PermissionDeniedException extends Exception {}

    public static LocationManager getInstance(Context context) {
        if (mLocationManager == null) {
            mLocationManager = new LocationManager(context.getApplicationContext());
        }
        return mLocationManager;
    }

    public Promise<Location> getCurrentLocation(final int timeout, final long maximumAge, final boolean enableHighAccuracy) {
        final Promise<Location> promise = Promises.promise();

        PermissionManager permissionManager = PermissionManager.getInstance(mContext);
        permissionManager.checkPermissions(Arrays.asList(PERMISSIONS), new PermissionManager.PermissionRequestListener() {
            @Override
            public void onPermissionGranted() {
                try {
                    Location currentLocation = getCurrentLocationNoCheck(timeout, maximumAge, enableHighAccuracy);
                    promise.set(currentLocation);
                } catch (TimeoutException e) {
                    promise.setError(e);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }

            @Override
            public void onPermissionDenied() {
                promise.setError(new PermissionDeniedException());
            }
        });

        return promise;
    }

    /**
     * Get current location without permission checking
     *
     * @param timeout
     * @param maximumAge
     * @param enableHighAccuracy
     * @return
     * @throws InterruptedException
     * @throws TimeoutException
     */
    @SuppressLint("MissingPermission")
    public Location getCurrentLocationNoCheck(int timeout, long maximumAge, boolean enableHighAccuracy) throws InterruptedException, TimeoutException {
        final long minLocationTime = System.currentTimeMillis() - maximumAge;
        final android.location.LocationManager locationManager = (android.location.LocationManager) mContext.getSystemService(Context.LOCATION_SERVICE);

        Location lastKnownGPSLocation = locationManager.getLastKnownLocation(android.location.LocationManager.GPS_PROVIDER);
        if (lastKnownGPSLocation != null && lastKnownGPSLocation.getTime() >= minLocationTime) {
            return lastKnownGPSLocation;
        }

        Location lastKnownNetworkLocation = locationManager.getLastKnownLocation(android.location.LocationManager.NETWORK_PROVIDER);
        if (lastKnownNetworkLocation != null && lastKnownNetworkLocation.getTime() >= minLocationTime) {
            return lastKnownNetworkLocation;
        }

        Criteria criteria = new Criteria();
        criteria.setAccuracy(enableHighAccuracy ? Criteria.ACCURACY_FINE : Criteria.ACCURACY_COARSE);

        CurrentLocationListener locationListener = new CurrentLocationListener();
        locationManager.requestSingleUpdate(criteria, locationListener, Looper.getMainLooper());

        if (!locationListener.mCountDownLatch.await(timeout, TimeUnit.MILLISECONDS)) {
            locationManager.removeUpdates(locationListener);
            throw new TimeoutException();
        }

        if (locationListener.mLocation != null) {
            return locationListener.mLocation;
        }

        return null;
    }

    static class CurrentLocationListener implements LocationListener {
        Location mLocation = null;
        final CountDownLatch mCountDownLatch = new CountDownLatch(1);

        @Override
        public void onLocationChanged(Location location) {
            mLocation = location;
            mCountDownLatch.countDown();
        }

        @Override
        public void onStatusChanged(String s, int i, Bundle bundle) {

        }

        @Override
        public void onProviderEnabled(String s) {

        }

        @Override
        public void onProviderDisabled(String s) {

        }
    }
}
