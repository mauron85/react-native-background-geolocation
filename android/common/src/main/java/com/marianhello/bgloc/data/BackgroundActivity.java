package com.marianhello.bgloc.data;

import android.os.Parcel;
import android.os.Parcelable;

import com.google.android.gms.location.DetectedActivity;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by finch on 5.12.2017.
 */

public class BackgroundActivity implements Parcelable {
    private int confidence;
    private int type;

    public BackgroundActivity(Integer locationProvider, DetectedActivity activity) {
        confidence = activity.getConfidence();
        type = activity.getType();
    }

    private BackgroundActivity(Parcel in) {
        confidence = in.readInt();
        type = in.readInt();
    }

    /**
     * Returns location as JSON object.
     * @throws JSONException
     */
    public JSONObject toJSONObject() throws JSONException {
        JSONObject json = new JSONObject();
        json.put("confidence", confidence);
        json.put("type", getActivityString(type));
        return json;
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
                return "UNKNOWN";
        }
    }

    public int getConfidence() {
        return confidence;
    }

    public void setConfidence(int confidence) {
        this.confidence = confidence;
    }

    public int getType() {
        return type;
    }

    public void setType(int type) {
        this.type = type;
    }

    public static final Parcelable.Creator<BackgroundActivity> CREATOR
            = new Parcelable.Creator<BackgroundActivity>() {
        public BackgroundActivity createFromParcel(Parcel in) {
            return new BackgroundActivity(in);
        }
        public BackgroundActivity[] newArray(int size) {
            return new BackgroundActivity[size];
        }
    };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int i) {
        dest.writeInt(confidence);
        dest.writeInt(type);
    }

    @Override
    public String toString () {
        return new StringBuffer()
                .append("BackgroundActivity[confidence=").append(confidence)
                .append(" type=").append(getActivityString(type))
                .append("]")
                .toString();
    }
}
