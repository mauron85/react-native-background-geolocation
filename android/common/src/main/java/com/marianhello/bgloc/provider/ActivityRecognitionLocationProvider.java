package com.marianhello.bgloc.provider;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.location.Location;
import android.os.Bundle;
import android.os.PowerManager;
import android.util.Log;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.location.ActivityRecognition;
import com.google.android.gms.location.ActivityRecognitionResult;
import com.google.android.gms.location.DetectedActivity;
import com.google.android.gms.location.LocationListener;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationServices;
import com.marianhello.bgloc.Config;
import com.marianhello.bgloc.data.BackgroundActivity;

import java.util.ArrayList;

public class ActivityRecognitionLocationProvider extends AbstractLocationProvider implements GoogleApiClient.ConnectionCallbacks,
        GoogleApiClient.OnConnectionFailedListener, LocationListener {

    private static final String TAG = ActivityRecognitionLocationProvider.class.getSimpleName();
    private static final String P_NAME = " com.marianhello.bgloc";
    private static final String DETECTED_ACTIVITY_UPDATE = P_NAME + ".DETECTED_ACTIVITY_UPDATE";

    private GoogleApiClient googleApiClient;
    private PendingIntent detectedActivitiesPI;

    private boolean isStarted = true;
    private boolean isTracking = false;
    private boolean isWatchingActivity = false;
    private Location lastLocation;
    private DetectedActivity lastActivity = new DetectedActivity(DetectedActivity.UNKNOWN, 100);

    public ActivityRecognitionLocationProvider(Context context) {
        super(context);
        PROVIDER_ID = Config.ACTIVITY_PROVIDER;
    }

    @Override
    public void onCreate() {
        super.onCreate();

        Intent detectedActivitiesIntent = new Intent(DETECTED_ACTIVITY_UPDATE);
        detectedActivitiesPI = PendingIntent.getBroadcast(mContext, 9002, detectedActivitiesIntent, PendingIntent.FLAG_UPDATE_CURRENT);
        registerReceiver(detectedActivitiesReceiver, new IntentFilter(DETECTED_ACTIVITY_UPDATE));
    }

    @Override
    public void onStart() {
        logger.info("Start recording");
        this.isStarted = true;
        attachRecorder();
    }

    @Override
    public void onStop() {
        logger.info("Stop recording");
        this.isStarted = false;
        detachRecorder();
        stopTracking();
    }

    @Override
    public void onConfigure(Config config) {
        super.onConfigure(config);
        if (isStarted) {
            onStop();
            onStart();
        }
    }

    @Override
    public boolean isStarted() {
        return isStarted;
    }

    @Override
    public void onLocationChanged(Location location) {
        logger.debug("Location change: {}", location.toString());

        if (lastActivity.getType() == DetectedActivity.STILL) {
            handleStationary(location);
            stopTracking();
            return;
        }

        showDebugToast("acy:" + location.getAccuracy() + ",v:" + location.getSpeed());

        lastLocation = location;
        handleLocation(location);
    }

    public void startTracking() {
        if (isTracking) { return; }

        Integer priority = translateDesiredAccuracy(mConfig.getDesiredAccuracy());
        LocationRequest locationRequest = LocationRequest.create()
                .setPriority(priority) // this.accuracy
                .setFastestInterval(mConfig.getFastestInterval())
                .setInterval(mConfig.getInterval());
        // .setSmallestDisplacement(mConfig.getStationaryRadius());
        try {
            LocationServices.FusedLocationApi.requestLocationUpdates(googleApiClient, locationRequest, this);
            isTracking = true;
            logger.debug("Start tracking with priority={} fastestInterval={} interval={} activitiesInterval={} stopOnStillActivity={}", priority, mConfig.getFastestInterval(), mConfig.getInterval(), mConfig.getActivitiesInterval(), mConfig.getStopOnStillActivity());
        } catch (SecurityException e) {
            logger.error("Security exception: {}", e.getMessage());
            this.handleSecurityException(e);
        }
    }

    public void stopTracking() {
        if (!isTracking) { return; }

        LocationServices.FusedLocationApi.removeLocationUpdates(googleApiClient, this);
        isTracking = false;
    }

    private void connectToPlayAPI() {
        logger.debug("Connecting to Google Play Services");
        googleApiClient =  new GoogleApiClient.Builder(mContext)
                .addApi(LocationServices.API)
                .addApi(ActivityRecognition.API)
                .addConnectionCallbacks(this)
                //.addOnConnectionFailedListener(this)
                .build();
        googleApiClient.connect();
    }

    private void disconnectFromPlayAPI() {
        if (googleApiClient != null && googleApiClient.isConnected()) {
            googleApiClient.disconnect();
        }
    }

    private void attachRecorder() {
        if (googleApiClient == null) {
            connectToPlayAPI();
        } else if (googleApiClient.isConnected()) {
            if (isWatchingActivity) { return; }
            startTracking();
            if (mConfig.getStopOnStillActivity()) {
                ActivityRecognition.ActivityRecognitionApi.requestActivityUpdates(
                        googleApiClient,
                        mConfig.getActivitiesInterval(),
                        detectedActivitiesPI
                );
                isWatchingActivity = true;
            }
        } else {
            googleApiClient.connect();
        }
    }

    private void detachRecorder() {
        if (isWatchingActivity) {
            logger.debug("Detaching recorder");
            ActivityRecognition.ActivityRecognitionApi.removeActivityUpdates(googleApiClient, detectedActivitiesPI);
            isWatchingActivity = false;
        }
    }

    @Override
    public void onConnected(Bundle connectionHint) {
        logger.debug("Connected to Google Play Services");
        if (this.isStarted) {
            attachRecorder();
        }
    }

    @Override
    public void onConnectionSuspended(int cause) {
        // googleApiClient.connect();
        logger.info("Connection to Google Play Services suspended");
    }

    @Override
    public void onConnectionFailed(ConnectionResult connectionResult) {
        logger.error("Connection to Google Play Services failed");
    }

    /**
     * Translates a number representing desired accuracy of Geolocation system from set [0, 10, 100, 1000].
     * 0:  most aggressive, most accurate, worst battery drain
     * 1000:  least aggressive, least accurate, best for battery.
     */
    private Integer translateDesiredAccuracy(Integer accuracy) {
        if (accuracy >= 10000) {
            return LocationRequest.PRIORITY_NO_POWER;
        }
        if (accuracy >= 1000) {
            return LocationRequest.PRIORITY_LOW_POWER;
        }
        if (accuracy >= 100) {
            return LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY;
        }
        if (accuracy >= 10) {
            return LocationRequest.PRIORITY_HIGH_ACCURACY;
        }
        if (accuracy >= 0) {
            return LocationRequest.PRIORITY_HIGH_ACCURACY;
        }

        return LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY;
    }


    public static DetectedActivity getProbableActivity(ArrayList<DetectedActivity> detectedActivities) {
        int highestConfidence = 0;
        DetectedActivity mostLikelyActivity = new DetectedActivity(0, DetectedActivity.UNKNOWN);

        for(DetectedActivity da: detectedActivities) {
            if(da.getType() != DetectedActivity.TILTING || da.getType() != DetectedActivity.UNKNOWN) {
                Log.w(TAG, "Received a Detected Activity that was not tilting / unknown");
                if (highestConfidence < da.getConfidence()) {
                    highestConfidence = da.getConfidence();
                    mostLikelyActivity = da;
                }
            }
        }
        return mostLikelyActivity;
    }

    private BroadcastReceiver detectedActivitiesReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            ActivityRecognitionResult result = ActivityRecognitionResult.extractResult(intent);
            ArrayList<DetectedActivity> detectedActivities = (ArrayList) result.getProbableActivities();

            //Find the activity with the highest percentage
            lastActivity = getProbableActivity(detectedActivities);

            logger.debug("Detected activity={} confidence={}", BackgroundActivity.getActivityString(lastActivity.getType()), lastActivity.getConfidence());

            handleActivity(lastActivity);

            if (lastActivity.getType() == DetectedActivity.STILL) {
                showDebugToast("Detected STILL Activity");
                // stopTracking();
                // we will delay stop tracking after position is found
            } else {
                showDebugToast("Detected ACTIVE Activity");
                startTracking();
            }
            //else do nothing
        }
    };

    @Override
    public void onDestroy() {
        logger.info("Destroying ActivityRecognitionLocationProvider");
        onStop();
        disconnectFromPlayAPI();
        unregisterReceiver(detectedActivitiesReceiver);
        super.onDestroy();
    }
}
