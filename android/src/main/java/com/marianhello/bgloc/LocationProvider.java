package com.marianhello.bgloc;

import android.location.Location;

/**
 * LocationProvider
 */
public interface LocationProvider {

    void onCreate();
    void onDestroy();
    void startRecording();
    void stopRecording();
}
