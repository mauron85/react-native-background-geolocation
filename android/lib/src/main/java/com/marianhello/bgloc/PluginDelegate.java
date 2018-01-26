package com.marianhello.bgloc;

import android.app.Activity;
import android.content.Context;

import com.marianhello.bgloc.data.BackgroundActivity;
import com.marianhello.bgloc.data.BackgroundLocation;

/**
 * Created by finch on 27.11.2017.
 */

public interface PluginDelegate {
    Activity getActivity();
    Context getContext();

    void onAuthorizationChanged(int authStatus);
    void onLocationChanged(BackgroundLocation location);
    void onStationaryChanged(BackgroundLocation location);
    void onActitivyChanged(BackgroundActivity activity);
    void onLocationPause();
    void onLocationResume();
    void onError(PluginError error);
}
