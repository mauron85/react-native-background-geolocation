package com.marianhello.bgloc;

import com.marianhello.bgloc.data.BackgroundActivity;
import com.marianhello.bgloc.data.BackgroundLocation;

public class TestPluginDelegate implements PluginDelegate {
    @Override
    public void onAuthorizationChanged(int authStatus) {

    }

    @Override
    public void onLocationChanged(BackgroundLocation location) {

    }

    @Override
    public void onStationaryChanged(BackgroundLocation location) {

    }

    @Override
    public void onActivityChanged(BackgroundActivity activity) {

    }

    @Override
    public void onServiceStatusChanged(int status) {

    }

    @Override
    public void onAbortRequested() {

    }

    @Override
    public void onHttpAuthorization() {

    }

    @Override
    public void onError(PluginException error) {

    }
}
