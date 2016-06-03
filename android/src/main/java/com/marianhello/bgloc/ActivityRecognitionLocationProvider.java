package com.marianhello.bgloc;

import java.util.ArrayList;

import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.location.Location;
import android.os.Bundle;
import android.os.PowerManager;
import android.util.Log;
import android.widget.Toast;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.LocationListener;
import com.google.android.gms.location.ActivityRecognition;
import com.google.android.gms.location.DetectedActivity;
import com.google.android.gms.location.ActivityRecognitionResult;

import com.marianhello.bgloc.Config;
import com.marianhello.bgloc.data.LocationDAO;

public class ActivityRecognitionLocationProvider extends AbstractLocationProvider implements GoogleApiClient.ConnectionCallbacks,
    GoogleApiClient.OnConnectionFailedListener, LocationListener {

    private static final String TAG = "FusedLocationProvider";
    private static final String P_NAME = " com.marianhello.bgloc";
    private static final String DETECTED_ACTIVITY_UPDATE = P_NAME + ".DETECTED_ACTIVITY_UPDATE";

    private PowerManager.WakeLock wakeLock;
    private GoogleApiClient googleApiClient;
    private PendingIntent detectedActivitiesPI;

    private Boolean startRecordingOnConnect = true;
    private Boolean isTracking = false;
    private Boolean isWatchingActivity = false;
    private DetectedActivity lastActivity = new DetectedActivity(DetectedActivity.UNKNOWN, 100);

    public ActivityRecognitionLocationProvider(LocationService context) {
        super(context);
        PROVIDER_ID = 1;
    }

    public void onCreate() {
        super.onCreate();
        Log.i(TAG, "onCreate");

        PowerManager pm = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, TAG);
        wakeLock.acquire();

        Intent detectedActivitiesIntent = new Intent(DETECTED_ACTIVITY_UPDATE);
        detectedActivitiesPI = PendingIntent.getBroadcast(context, 9002, detectedActivitiesIntent, PendingIntent.FLAG_UPDATE_CURRENT);
        registerReceiver(detectedActivitiesReceiver, new IntentFilter(DETECTED_ACTIVITY_UPDATE));
    }

    @Override
    public void onLocationChanged(Location location) {
        Log.d(TAG, "onLocationChanged: " + location.toString());

        if (lastActivity.getType() == DetectedActivity.STILL) {
            stopTracking();
        }

        if (config.isDebugging()) {
            Toast.makeText(context, "acy:" + location.getAccuracy() + ",v:" + location.getSpeed() + ",df:" + config.getDistanceFilter(), Toast.LENGTH_LONG).show();
        }

        // if (lastLocation != null && location.distanceTo(lastLocation) < config.getDistanceFilter()) {
        //     return;
        // }

        if (config.isDebugging()) {
            startTone("beep");
        }

        lastLocation = location;
        handleLocation(location);
    }

    public void startRecording() {
        Log.i(TAG, "startRecording");
        this.startRecordingOnConnect = true;
        attachRecorder();
    }

    public void stopRecording() {
        Log.i(TAG, "stopRecording");
        this.startRecordingOnConnect = false;
        detachRecorder();
        stopTracking();
    }

    public void startTracking() {
        if (isTracking) { return; }

        Integer priority = translateDesiredAccuracy(config.getDesiredAccuracy());
        LocationRequest locationRequest = LocationRequest.create()
                .setPriority(priority) // this.accuracy
                .setFastestInterval(config.getFastestInterval())
                .setInterval(config.getInterval());
                // .setSmallestDisplacement(config.getStationaryRadius());
        LocationServices.FusedLocationApi.requestLocationUpdates(googleApiClient, locationRequest, this);
        isTracking = true;
        Log.d(TAG, "startTracking with priority: "
            + priority + ", fastestInterval: " + config.getFastestInterval() + ", interval: " + config.getInterval() + ", smallestDisplacement: " + config.getStationaryRadius());
    }

    public void stopTracking() {
        if (!isTracking) { return; }

        LocationServices.FusedLocationApi.removeLocationUpdates(googleApiClient, this);
        isTracking = false;
    }

    private void connectToPlayAPI() {
        Log.d(TAG, "connecting to Google Play Services");
        googleApiClient =  new GoogleApiClient.Builder(context)
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
            if (config.getStopOnStillActivity()) {
                ActivityRecognition.ActivityRecognitionApi.requestActivityUpdates(
                    googleApiClient,
                    config.getActivitiesInterval(),
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
            Log.d(TAG, "detachRecorder");
            ActivityRecognition.ActivityRecognitionApi.removeActivityUpdates(googleApiClient, detectedActivitiesPI);
            isWatchingActivity = false;
        }
    }

    @Override
    public void onConnected(Bundle connectionHint) {
        Log.d(TAG, "connected to Google Play Services");
        if (this.startRecordingOnConnect) {
            attachRecorder();
        }
    }

    @Override
    public void onConnectionSuspended(int cause) {
        // googleApiClient.connect();
        Log.i(TAG, "connection to Google Play Services suspended");
    }

    @Override
    public void onConnectionFailed(ConnectionResult connectionResult) {
        Log.e(TAG, "connection to Google Play Services failed");
    }

    /**
    * Translates a number representing desired accuracy of GeoLocation system from set [0, 10, 100, 1000].
    * 0:  most aggressive, most accurate, worst battery drain
    * 1000:  least aggressive, least accurate, best for battery.
    */
    private Integer translateDesiredAccuracy(Integer accuracy) {
        switch (accuracy) {
            case 10000:
                accuracy = LocationRequest.PRIORITY_NO_POWER;
                break;
            case 1000:
                accuracy = LocationRequest.PRIORITY_LOW_POWER;
                break;
            case 100:
                accuracy = LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY;
                break;
            case 10:
                accuracy = LocationRequest.PRIORITY_HIGH_ACCURACY;
                break;
            case 0:
                accuracy = LocationRequest.PRIORITY_HIGH_ACCURACY;
                break;
            default:
                accuracy = LocationRequest.PRIORITY_BALANCED_POWER_ACCURACY;
        }
        return accuracy;
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

    public static String getActivityString(int detectedActivityType) {
          switch(detectedActivityType) {
              case DetectedActivity.IN_VEHICLE:
                  return "IN_VEHICLE";
              case DetectedActivity.ON_BICYCLE:
                  return "ON_BICYCLE";
              case DetectedActivity.ON_FOOT:
                  return "ON_FOOT";
              case DetectedActivity.RUNNING:
                  return "RUNNING";
              case DetectedActivity.STILL:
                  return "STILL";
              case DetectedActivity.TILTING:
                  return "TILTING";
              case DetectedActivity.UNKNOWN:
                  return "UNKNOWN";
              case DetectedActivity.WALKING:
                  return "WALKING";
              default:
                  return "Unknown";
          }
    }

    private BroadcastReceiver detectedActivitiesReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            ActivityRecognitionResult result = ActivityRecognitionResult.extractResult(intent);
            ArrayList<DetectedActivity> detectedActivities = (ArrayList) result.getProbableActivities();

            //Find the activity with the highest percentage
            lastActivity = getProbableActivity(detectedActivities);

            Log.d(TAG, "MOST LIKELY ACTIVITY: " + getActivityString(lastActivity.getType()) + " " + lastActivity.getConfidence());

            if (lastActivity.getType() == DetectedActivity.STILL) {
                if (config.isDebugging()) {
                    Toast.makeText(context, "Detected STILL Activity", Toast.LENGTH_SHORT).show();
                }
                // stopTracking();
                // we will delay stop tracking after position is found
            } else {
                if (config.isDebugging()) {
                    Toast.makeText(context, "Detected ACTIVE Activity", Toast.LENGTH_SHORT).show();
                }
                startTracking();
            }
            //else do nothing
        }
    };

    public void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "onDestroy");
        stopRecording();
        disconnectFromPlayAPI();
        unregisterReceiver(detectedActivitiesReceiver);
        wakeLock.release();
    }
}
