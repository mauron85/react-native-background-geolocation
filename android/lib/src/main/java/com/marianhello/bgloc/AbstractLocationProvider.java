/*
According to apache license

This is fork of christocracy cordova-plugin-background-geolocation plugin
https://github.com/christocracy/cordova-plugin-background-geolocation

This is a new class
*/

package com.marianhello.bgloc;

import android.app.Activity;
import android.location.Location;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.BroadcastReceiver;
import android.media.AudioManager;
import android.media.ToneGenerator;
import android.widget.Toast;

import com.google.android.gms.location.DetectedActivity;
import com.marianhello.bgloc.data.BackgroundActivity;
import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.utils.Tone;

/**
 * AbstractLocationProvider
 */
public abstract class AbstractLocationProvider implements LocationProvider {

    protected Integer PROVIDER_ID;
    protected LocationService mLocationService;
    protected Config mConfig;

    protected ToneGenerator toneGenerator;

    protected AbstractLocationProvider(LocationService locationService, Config config) {
        this.mLocationService = locationService;
        this.mConfig = config;
    }

    @Override
    public void onCreate() {
        toneGenerator = new android.media.ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100);
    }

    @Override
    public void onDestroy() {
        toneGenerator.release();
        toneGenerator = null;
    }

    @Override
    public void onConfigure(Config config) {
        mConfig = config;
    }

    @Override
    public void onSwitchMode(int mode) {
        // override in child class
    }

    /**
     * Register broadcast reciever
     * @param receiver
     */
    protected Intent registerReceiver (BroadcastReceiver receiver, IntentFilter filter) {
        return mLocationService.registerReceiver(receiver, filter);
    }

    /**
     * Unregister broadcast reciever
     * @param receiver
     */
    protected void unregisterReceiver (BroadcastReceiver receiver) {
        mLocationService.unregisterReceiver(receiver);
    }

    /**
     * Handle location as recorder by provider
     * @param location
     */
    protected void handleLocation (Location location) {
        playDebugTone(Tone.BEEP);
        mLocationService.handleLocation(new BackgroundLocation(PROVIDER_ID, location));
    }

    /**
     * Handle stationary location with radius
     *
     * @param location
     * @param radius radius of stationary region
     */
    protected void handleStationary (Location location, float radius) {
        playDebugTone(Tone.LONG_BEEP);
        mLocationService.handleStationary(new BackgroundLocation(PROVIDER_ID, location, radius));
    }

    /**
     * Handle stationary location without radius
     *
     * @param location
     */
    protected void handleStationary (Location location) {
        playDebugTone(Tone.LONG_BEEP);
        mLocationService.handleStationary(new BackgroundLocation(PROVIDER_ID, location));
    }

    protected void handleActivity(DetectedActivity activity) {
        mLocationService.handleActivity(new BackgroundActivity(PROVIDER_ID, activity));
    }

    /**
     * Handle security exception
     * @param exception
     */
    protected void handleSecurityException (SecurityException exception) {
        PluginError error = new PluginError(PluginError.PERMISSION_DENIED_ERROR, exception.getMessage());
        mLocationService.handleError(error);
    }

    protected void showDebugToast (String text) {
        if (mConfig.isDebugging()) {
            Toast.makeText(mLocationService, text, Toast.LENGTH_LONG).show();
        }
    }

    /**
     * Plays debug sound
     * @param name toneGenerator
     */
    protected void playDebugTone (int name) {
        if (toneGenerator == null || !mConfig.isDebugging()) return;

        int duration = 1000;

        toneGenerator.startTone(name, duration);
    }
}
