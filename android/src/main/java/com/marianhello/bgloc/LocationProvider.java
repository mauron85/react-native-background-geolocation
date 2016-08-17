/*
According to apache license

This is fork of christocracy cordova-plugin-background-geolocation plugin
https://github.com/christocracy/cordova-plugin-background-geolocation

This is a new class
*/

package com.marianhello.bgloc;

import android.location.Location;

/**
 * DummyContentProvider
 */
public interface LocationProvider {

    void onCreate();
    void onDestroy();
    void startRecording();
    void stopRecording();
}
