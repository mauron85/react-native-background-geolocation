package com.marianhello.bgloc;

import android.content.Context;
import android.location.Criteria;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.widget.Toast;

import com.marianhello.logging.LoggerManager;
import com.tenforwardconsulting.bgloc.DistanceFilterLocationProvider;

/**
 * Created by finch on 7.11.2017.
 */

public class RawLocationProvider extends AbstractLocationProvider implements LocationListener {
    private org.slf4j.Logger logger;
    private LocationManager locationManager;
    private Boolean isStarted = false;

    public RawLocationProvider(LocationService context) {
        super(context);
        PROVIDER_ID = Config.RAW_PROVIDER;
    }

    @Override
    public void onCreate() {
        super.onCreate();

        logger = LoggerManager.getLogger(RawLocationProvider.class);
        logger.debug("Creating RawLocationProvider");

        locationManager = (LocationManager) locationService.getSystemService(Context.LOCATION_SERVICE);
    }

    @Override
    public void onLocationChanged(Location location) {
        logger.debug("Location change: {}", location.toString());

        if (config.isDebugging()) {
            Toast.makeText(locationService, "acy:" + location.getAccuracy() + ",v:" + location.getSpeed(), Toast.LENGTH_LONG).show();
            startTone(Tone.BEEP);
        }
        handleLocation(location);
    }

    @Override
    public void onStatusChanged(String provider, int status, Bundle bundle) {
        logger.debug("Provider {} status changed: {}", provider, status);
    }

    @Override
    public void onProviderEnabled(String provider) {
        logger.debug("Provider {} was enabled", provider);
    }

    @Override
    public void onProviderDisabled(String provider) {
        logger.debug("Provider {} was disabled", provider);
    }

    @Override
    public void startRecording() {
        if (isStarted) {
            return;
        }

        Criteria criteria = new Criteria();
        criteria.setAltitudeRequired(false);
        criteria.setBearingRequired(false);
        criteria.setSpeedRequired(true);
        criteria.setCostAllowed(true);
        criteria.setAccuracy(Criteria.ACCURACY_FINE);
        criteria.setHorizontalAccuracy(translateDesiredAccuracy(config.getDesiredAccuracy()));
        criteria.setPowerRequirement(Criteria.POWER_HIGH);

        try {
            locationManager.requestLocationUpdates(locationManager.getBestProvider(criteria, true), config.getInterval(), config.getDistanceFilter(), this);
            isStarted = true;
        } catch (SecurityException e) {
            logger.error("Security exception: {}", e.getMessage());
            this.handleSecurityException(e);
        }
    }

    @Override
    public void stopRecording() {
        if (!isStarted) {
            return;
        }
        try {
            locationManager.removeUpdates(this);
        } catch (SecurityException e) {
            logger.error("Security exception: {}", e.getMessage());
            this.handleSecurityException(e);
        }
    }

    /**
     * Translates a number representing desired accuracy of Geolocation system from set [0, 10, 100, 1000].
     * 0:  most aggressive, most accurate, worst battery drain
     * 1000:  least aggressive, least accurate, best for battery.
     */
    private Integer translateDesiredAccuracy(Integer accuracy) {
        if (accuracy >= 1000) {
            return Criteria.ACCURACY_LOW;
        }
        if (accuracy >= 100) {
            return Criteria.ACCURACY_MEDIUM;
        }
        if (accuracy >= 10) {
            return Criteria.ACCURACY_HIGH;
        }
        if (accuracy >= 0) {
            return Criteria.ACCURACY_HIGH;
        }

        return Criteria.ACCURACY_MEDIUM;
    }

    @Override
    public void onDestroy() {
        logger.debug("Destroying DistanceFilterLocationProvider");
        this.stopRecording();
        super.onDestroy();
    }
}
