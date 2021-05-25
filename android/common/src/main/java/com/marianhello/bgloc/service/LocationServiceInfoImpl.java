package com.marianhello.bgloc.service;

import android.app.ActivityManager;
import android.content.Context;

public class LocationServiceInfoImpl implements LocationServiceInfo {
    private Context mContext;

    public LocationServiceInfoImpl(Context context) {
        mContext = context;
    }

    @Override
    public boolean isStarted() {
        ActivityManager.RunningServiceInfo info = getRunningServiceInfo();
        if (info != null) {
            return info.started;
        }
        return false;
    }

    @Override
    public boolean isBound() {
        ActivityManager.RunningServiceInfo info = getRunningServiceInfo();
        if (info != null) {
            return info.clientCount > 0;
        }
        return false;
    }

    public ActivityManager.RunningServiceInfo getRunningServiceInfo() {
        String serviceName = LocationServiceImpl.class.getName();
        ActivityManager manager = (ActivityManager) mContext.getSystemService(Context.ACTIVITY_SERVICE);
        for (ActivityManager.RunningServiceInfo info : manager.getRunningServices(Integer.MAX_VALUE)) {
            if (serviceName.equals(info.service.getClassName())) {
                return info;
            }
        }
        return null;
    }
}
