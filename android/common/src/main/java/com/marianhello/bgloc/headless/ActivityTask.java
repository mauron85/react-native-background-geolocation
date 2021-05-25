package com.marianhello.bgloc.headless;

import android.os.Bundle;

import com.marianhello.bgloc.data.BackgroundActivity;

import org.json.JSONException;

public abstract class ActivityTask extends Task {
    private BackgroundActivity mActivity;

    public ActivityTask(BackgroundActivity activity) {
        mActivity = activity;
    }

    @Override
    public String getName() {
        return "activity";
    }

    @Override
    public Bundle getBundle() {
        Bundle bundle = new Bundle();
        Bundle params = new Bundle();

        params.putInt("confidence", mActivity.getConfidence());
        params.putString("type", BackgroundActivity.getActivityString(mActivity.getType()));

        bundle.putString("name", getName());
        bundle.putBundle("params", params);
        return bundle;
    }

    @Override
    public String toString() {
        if (mActivity == null) {
            return null;
        }

        try {
            return mActivity.toJSONObject().toString();
        } catch (JSONException e) {
            onError("Error processing params: " + e.getMessage());
        }

        return null;
    }
}
