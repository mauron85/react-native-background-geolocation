/*
According to apache license

This is fork of christocracy cordova-plugin-background-geolocation plugin
https://github.com/christocracy/cordova-plugin-background-geolocation

This is a new class
*/

package com.marianhello.bgloc.provider;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.location.Location;
import android.media.AudioManager;
import android.provider.Settings;
import android.widget.Toast;

import com.google.android.gms.location.DetectedActivity;
import com.marianhello.bgloc.Config;
import com.marianhello.bgloc.PluginException;
import com.marianhello.bgloc.data.BackgroundActivity;
import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.logging.LoggerManager;
import com.marianhello.utils.ToneGenerator;
import com.marianhello.utils.ToneGenerator.Tone;

/**
 * AbstractLocationProvider
 */
public abstract class AbstractLocationProvider implements LocationProvider {

    protected Integer PROVIDER_ID;
    protected Config mConfig;
    protected Context mContext;

    protected ToneGenerator toneGenerator;
    protected org.slf4j.Logger logger;

    private ProviderDelegate mDelegate;

    protected AbstractLocationProvider(Context context) {
        mContext = context;
        logger = LoggerManager.getLogger(getClass());
        logger.info("Creating {}", getClass().getSimpleName());
    }

    @Override
    public void onCreate() {
        toneGenerator = new ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100);
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
    public void onCommand(int commandId, int arg1) {
        // override in child class
    }

    public void setDelegate(ProviderDelegate delegate) {
        mDelegate = delegate;
    }

    /**
     * Register broadcast reciever
     * @param receiver
     */
    protected Intent registerReceiver (BroadcastReceiver receiver, IntentFilter filter) {
        return mContext.registerReceiver(receiver, filter);
    }

    /**
     * Unregister broadcast reciever
     * @param receiver
     */
    protected void unregisterReceiver (BroadcastReceiver receiver) {
        mContext.unregisterReceiver(receiver);
    }

    /**
     * Handle location as recorder by provider
     * @param location
     */
    protected void handleLocation (Location location) {
        playDebugTone(Tone.BEEP);
        if (mDelegate != null) {
            BackgroundLocation bgLocation = new BackgroundLocation(PROVIDER_ID, location);
            bgLocation.setMockLocationsEnabled(hasMockLocationsEnabled());
            mDelegate.onLocation(bgLocation);
        }
    }

    /**
     * Handle stationary location with radius
     *
     * @param location
     * @param radius radius of stationary region
     */
    protected void handleStationary (Location location, float radius) {
        playDebugTone(Tone.LONG_BEEP);
        if (mDelegate != null) {
            BackgroundLocation bgLocation = new BackgroundLocation(PROVIDER_ID, location);
            bgLocation.setRadius(radius);
            bgLocation.setMockLocationsEnabled(hasMockLocationsEnabled());
            mDelegate.onStationary(bgLocation);
        }
    }

    /**
     * Handle stationary location without radius
     *
     * @param location
     */
    protected void handleStationary (Location location) {
        playDebugTone(Tone.LONG_BEEP);
        if (mDelegate != null) {
            BackgroundLocation bgLocation = new BackgroundLocation(PROVIDER_ID, location);
            bgLocation.setMockLocationsEnabled(hasMockLocationsEnabled());
            mDelegate.onStationary(bgLocation);
        }
    }

    protected void handleActivity(DetectedActivity activity) {
        if (mDelegate != null) {
            mDelegate.onActivity(new BackgroundActivity(PROVIDER_ID, activity));
        }
    }

    /**
     * Handle security exception
     * @param exception
     */
    protected void handleSecurityException (SecurityException exception) {
        PluginException error = new PluginException(exception.getMessage(), PluginException.PERMISSION_DENIED_ERROR);
        if (mDelegate != null) {
            mDelegate.onError(error);
        }
    }

    protected void showDebugToast (String text) {
        if (mConfig.isDebugging()) {
            Toast.makeText(mContext, text, Toast.LENGTH_LONG).show();
        }
    }

    public Boolean hasMockLocationsEnabled() {
        return Settings.Secure.getString(mContext.getContentResolver(), android.provider.Settings.Secure.ALLOW_MOCK_LOCATION).equals("1");
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
