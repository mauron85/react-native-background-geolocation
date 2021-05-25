package com.marianhello.bgloc.data;

import android.content.ContentValues;
import android.database.Cursor;
import android.location.Location;
import android.os.Build;
import android.os.Bundle;
import android.os.Parcel;
import android.os.Parcelable;
import android.support.v4.util.TimeUtils;

import com.marianhello.bgloc.data.sqlite.SQLiteLocationContract;
import com.marianhello.bgloc.data.sqlite.SQLiteLocationContract.LocationEntry;

import org.json.JSONException;
import org.json.JSONObject;

public class BackgroundLocation implements Parcelable {
    public static final int DELETED = 0;
    public static final int POST_PENDING = 1;
    public static final int SYNC_PENDING = 2;

    private Long locationId = null;
    private Integer locationProvider = null;
    private Long batchStartMillis = null;
    private String provider;
    private double latitude = 0.0;
    private double longitude = 0.0;
    private long time = 0;
    private long elapsedRealtimeNanos = 0;
    private float accuracy = 0.0f;
    private float speed = 0.0f;
    private float bearing = 0.0f;
    private double altitude = 0.0f;
    private float radius = 0.0f;
    private boolean hasAccuracy = false;
    private boolean hasAltitude = false;
    private boolean hasSpeed = false;
    private boolean hasBearing = false;
    private boolean hasRadius = false;
    private int mockFlags = 0x0000;
    private int status = POST_PENDING;
    private Bundle extras = null;

    private static final long TWO_MINUTES_IN_NANOS = 1000000000L * 60 * 2;

    public BackgroundLocation() {}

    public BackgroundLocation(String provider) {
        this.provider = provider;
    }

    /**
     * Construct BackgroundLocation by copying properties from android Location.
     * @param location
     */
    @Deprecated
    public BackgroundLocation(Location location) {
        this(BackgroundLocation.fromLocation(location));
    }

    @Deprecated
    public BackgroundLocation(Integer locationProvider, Location location) {
        this(location);
        this.locationProvider = locationProvider;
    }

    /**
     * Construct stationary BackgroundLocation.
     * @param locationProvider
     * @param location
     * @param radius radius of stationary region
     */
    @Deprecated
    public BackgroundLocation(Integer locationProvider, Location location, float radius) {
        this(locationProvider, location);
        setRadius(radius);
    }

    /**
     * Construct a new Location object that is copied from an existing one.
     * @param location
     */
    public BackgroundLocation(BackgroundLocation l) {
        locationId = l.locationId;
        locationProvider = l.locationProvider;
        batchStartMillis = l.batchStartMillis;
        provider = l.provider;
        latitude = l.latitude;
        longitude = l.longitude;
        time = l.time;
        elapsedRealtimeNanos = l.elapsedRealtimeNanos;
        accuracy = l.accuracy;
        speed = l.speed;
        bearing = l.bearing;
        altitude = l.altitude;
        radius = l.radius;
        hasAccuracy = l.hasAccuracy;
        hasAltitude = l.hasAltitude;
        hasSpeed = l.hasSpeed;
        hasBearing = l.hasBearing;
        hasRadius = l.hasRadius;
        mockFlags = l.mockFlags;
        status = l.status;
        extras = (l.extras == null) ? null : new Bundle(l.extras);
    }

    private static BackgroundLocation fromParcel(Parcel in) {
        BackgroundLocation l = new BackgroundLocation();

        l.locationId = in.readLong();
        l.locationProvider = in.readInt();
        l.batchStartMillis = in.readLong();
        l.provider = in.readString();
        l.latitude = in.readDouble();
        l.longitude = in.readDouble();
        l.time = in.readLong();
        l.elapsedRealtimeNanos = in.readLong();
        l.accuracy = in.readFloat();
        l.speed = in.readFloat();
        l.bearing = in.readFloat();
        l.altitude = in.readDouble();
        l.radius = in.readFloat();
        l.hasAccuracy = in.readInt() != 0;
        l.hasAltitude = in.readInt() != 0;
        l.hasSpeed = in.readInt() != 0;
        l.hasBearing = in.readInt() != 0;
        l.hasRadius = in.readInt() != 0;
        l.mockFlags = in.readInt();
        l.status = in.readInt();
        l.extras = in.readBundle();

        return l;
    }

    public static BackgroundLocation fromLocation(Location location) {
        BackgroundLocation l = new BackgroundLocation();

        l.provider = location.getProvider();
        l.latitude = location.getLatitude();
        l.longitude = location.getLongitude();
        l.time = location.getTime();
        l.accuracy = location.getAccuracy();
        l.speed = location.getSpeed();
        l.bearing = location.getBearing();
        l.altitude = location.getAltitude();
        l.hasAccuracy = location.hasAccuracy();
        l.hasAltitude = location.hasAltitude();
        l.hasSpeed = location.hasSpeed();
        l.hasBearing = location.hasBearing();
        l.extras = location.getExtras();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            l.elapsedRealtimeNanos = location.getElapsedRealtimeNanos();
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            l.setIsFromMockProvider(location.isFromMockProvider());
        }

        return l;
    }

    /**
     * Create a new Location from a cursor
     *
     * @param c the cursor
     * @return the note
     */
    public static BackgroundLocation fromCursor(Cursor c) {
        BackgroundLocation l = new BackgroundLocation();

        l.setProvider(c.getString(c.getColumnIndex(LocationEntry.COLUMN_NAME_PROVIDER)));
        l.setTime(c.getLong(c.getColumnIndex(LocationEntry.COLUMN_NAME_TIME)));
        if (c.getInt(c.getColumnIndex(LocationEntry.COLUMN_NAME_HAS_ACCURACY)) == 1) {
            l.setAccuracy(c.getFloat(c.getColumnIndex(LocationEntry.COLUMN_NAME_ACCURACY)));
        }
        if (c.getInt(c.getColumnIndex(LocationEntry.COLUMN_NAME_HAS_SPEED)) == 1) {
            l.setSpeed(c.getFloat(c.getColumnIndex(LocationEntry.COLUMN_NAME_SPEED)));
        }
        if (c.getInt(c.getColumnIndex(LocationEntry.COLUMN_NAME_HAS_BEARING)) == 1) {
            l.setBearing(c.getFloat(c.getColumnIndex(LocationEntry.COLUMN_NAME_BEARING)));
        }
        if (c.getInt(c.getColumnIndex(LocationEntry.COLUMN_NAME_HAS_ALTITUDE)) == 1) {
            l.setAltitude(c.getDouble(c.getColumnIndex(LocationEntry.COLUMN_NAME_ALTITUDE)));
        }
        if (c.getInt(c.getColumnIndex(LocationEntry.COLUMN_NAME_HAS_RADIUS)) == 1) {
            l.setRadius(c.getFloat(c.getColumnIndex(LocationEntry.COLUMN_NAME_RADIUS)));
        }
        l.setLatitude(c.getDouble(c.getColumnIndex(LocationEntry.COLUMN_NAME_LATITUDE)));
        l.setLongitude(c.getDouble(c.getColumnIndex(LocationEntry.COLUMN_NAME_LONGITUDE)));
        l.setLocationProvider(c.getInt(c.getColumnIndex(LocationEntry.COLUMN_NAME_LOCATION_PROVIDER)));
        l.setBatchStartMillis(c.getLong(c.getColumnIndex(LocationEntry.COLUMN_NAME_BATCH_START_MILLIS)));
        l.setStatus(c.getInt(c.getColumnIndex(LocationEntry.COLUMN_NAME_STATUS)));
        l.setLocationId(c.getLong(c.getColumnIndex(LocationEntry._ID)));
        l.setMockFlags(c.getInt((c.getColumnIndex(LocationEntry.COLUMN_NAME_MOCK_FLAGS))));

        return l;
    }

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeLong(locationId);
        dest.writeInt(locationProvider);
        dest.writeLong(batchStartMillis);
        dest.writeString(provider);
        dest.writeDouble(latitude);
        dest.writeDouble(longitude);
        dest.writeLong(time);
        dest.writeLong(elapsedRealtimeNanos);
        dest.writeFloat(accuracy);
        dest.writeFloat(speed);
        dest.writeFloat(bearing);
        dest.writeDouble(altitude);
        dest.writeFloat(radius);
        dest.writeInt(hasAccuracy ? 1 : 0);
        dest.writeInt(hasAltitude ? 1 : 0);
        dest.writeInt(hasSpeed ? 1 : 0);
        dest.writeInt(hasBearing ? 1 : 0);
        dest.writeInt(hasRadius ? 1 : 0);
        dest.writeInt(mockFlags);
        dest.writeInt(status);
        dest.writeBundle(extras);
    }

    public static final Parcelable.Creator<BackgroundLocation> CREATOR
            = new Parcelable.Creator<BackgroundLocation>() {
        public BackgroundLocation createFromParcel(Parcel in) {
            return BackgroundLocation.fromParcel(in);
        }
        public BackgroundLocation[] newArray(int size) {
            return new BackgroundLocation[size];
        }
    };

    public BackgroundLocation makeClone() {
        return new BackgroundLocation(this);
    }

    /**
     * Returns locationId if location was stored in db.
     * @return locationId or null
     */
    public Long getLocationId() {
        return locationId;
    }


    /**
     * Sets locationId
     * used when location was persisted into db and returned db id is used locationId
     * @param locationId
     */
    public void setLocationId(Long locationId) {
        this.locationId = locationId;
    }

    /**
     * Returns location provider that generated this location.
     * @return location provider id
     */
    public Integer getLocationProvider() {
        return locationProvider;
    }

    /**
     * Sets the location provider that generated this location.
     * @param locationProvider
     */
    public void setLocationProvider(Integer locationProvider) {
        this.locationProvider = locationProvider;
    }

    /**
     * Returns batch start time in milliseconds when location is being synced with remote server.
     * @return batch run time or null
     */
    public Long getBatchStartMillis() {
        return batchStartMillis;
    }

    /**
     * Sets batch start time
     * @param batch run time in milliseconds
     */
    public void setBatchStartMillis(Long batchStartMillis) {
        this.batchStartMillis = batchStartMillis;
    }

    /**
     * Returns the name of the provider that generated this fix.
     * @return the provider, or null if it has not been set
     */
    public String getProvider() {
        return provider;
    }

    /**
     * Sets the name of the provider that generated this fix.
     */
    public void setProvider(String provider) {
        this.provider = provider;
    }

    /**
     * Get the altitude if available, in meters above the WGS 84 reference
     * ellipsoid.
     *
     * <p>If this location does not have an altitude then 0.0 is returned.
     */
    public double getLatitude() {
        return latitude;
    }

    /**
     * Set the altitude, in meters above the WGS 84 reference ellipsoid.
     *
     * <p>Following this call {@link #hasAltitude} will return true.
     */
    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }

    /**
     * Get the longitude, in degrees.
     *
     * <p>All locations generated by the {@link LocationManager}
     * will have a valid longitude.
     */
    public double getLongitude() {
        return longitude;
    }

    /**
     * Set the longitude, in degrees.
     */
    public void setLongitude(double longitude) {
        this.longitude = longitude;
    }


    /**
     * Return the UTC time of this fix, in milliseconds since January 1, 1970.
     *
     * <p>Note that the UTC time on a device is not monotonic: it
     * can jump forwards or backwards unpredictably. So always use
     * {@link #getElapsedRealtimeNanos} when calculating time deltas.
     *
     * <p>On the other hand, {@link #getTime} is useful for presenting
     * a human readable time to the user, or for carefully comparing
     * location fixes across reboot or across devices.
     *
     * <p>All locations generated by the {@link LocationManager}
     * are guaranteed to have a valid UTC time, however remember that
     * the system time may have changed since the location was generated.
     *
     * @return time of fix, in milliseconds since January 1, 1970.
     */
    public long getTime() {
        return time;
    }

    /**
     * Set the UTC time of this fix, in milliseconds since January 1,
     * 1970.
     *
     * @param time UTC time of this fix, in milliseconds since January 1, 1970
     */
    public void setTime(long time) {
        this.time = time;
    }

    /**
     * Return the time of this fix, in elapsed real-time since system boot.
     *
     * <p>This value can be reliably compared to
     * {@link android.os.SystemClock#elapsedRealtimeNanos},
     * to calculate the age of a fix and to compare Location fixes. This
     * is reliable because elapsed real-time is guaranteed monotonic for
     * each system boot and continues to increment even when the system
     * is in deep sleep (unlike {@link #getTime}.
     *
     * <p>All locations generated by the {@link LocationManager}
     * are guaranteed to have a valid elapsed real-time.
     *
     * @return elapsed real-time of fix, in nanoseconds since system boot.
     */
    public long getElapsedRealtimeNanos() {
        return elapsedRealtimeNanos;
    }

    /**
     * Set the time of this fix, in elapsed real-time since system boot.
     *
     * @param time elapsed real-time of fix, in nanoseconds since system boot.
     */
    public void setElapsedRealtimeNanos(long elapsedRealtimeNanos) {
        this.elapsedRealtimeNanos = elapsedRealtimeNanos;
    }

    /**
     * Get the estimated accuracy of this location, in meters.
     *
     * <p>We define accuracy as the radius of 68% confidence. In other
     * words, if you draw a circle centered at this location's
     * latitude and longitude, and with a radius equal to the accuracy,
     * then there is a 68% probability that the true location is inside
     * the circle.
     *
     * <p>In statistical terms, it is assumed that location errors
     * are random with a normal distribution, so the 68% confidence circle
     * represents one standard deviation. Note that in practice, location
     * errors do not always follow such a simple distribution.
     *
     * <p>This accuracy estimation is only concerned with horizontal
     * accuracy, and does not indicate the accuracy of bearing,
     * velocity or altitude if those are included in this Location.
     *
     * <p>If this location does not have an accuracy, then 0.0 is returned.
     * All locations generated by the {@link LocationManager} include
     * an accuracy.
     */
    public float getAccuracy() {
        return accuracy;
    }

    /**
     * Set the estimated accuracy of this location, meters.
     *
     * <p>See {@link #getAccuracy} for the definition of accuracy.
     *
     * <p>Following this call {@link #hasAccuracy} will return true.
     */
    public void setAccuracy(float accuracy) {
        this.accuracy = accuracy;
        this.hasAccuracy = true;
    }

    /**
     * Get the speed if it is available, in meters/second over ground.
     *
     * <p>If this location does not have a speed then 0.0 is returned.
     */
    public float getSpeed() {
        return speed;
    }

    /**
     * Set the speed, in meters/second over ground.
     *
     * <p>Following this call {@link #hasSpeed} will return true.
     */
    public void setSpeed(float speed) {
        this.speed = speed;
        this.hasSpeed = true;
    }

    /**
     * Get the bearing, in degrees.
     *
     * <p>Bearing is the horizontal direction of travel of this device,
     * and is not related to the device orientation. It is guaranteed to
     * be in the range (0.0, 360.0] if the device has a bearing.
     *
     * <p>If this location does not have a bearing then 0.0 is returned.
     */
    public float getBearing() {
        return bearing;
    }

    /**
     * Set the bearing, in degrees.
     *
     * <p>Bearing is the horizontal direction of travel of this device,
     * and is not related to the device orientation.
     *
     * <p>The input will be wrapped into the range (0.0, 360.0].
     */
    public void setBearing(float bearing) {
        this.bearing = bearing;
        this.hasBearing = true;
    }

    /**
     * Get the altitude if available, in meters above the WGS 84 reference
     * ellipsoid.
     *
     * <p>If this location does not have an altitude then 0.0 is returned.
     */
    public double getAltitude() {
        return altitude;
    }

    /**
     * Set the altitude, in meters above the WGS 84 reference ellipsoid.
     *
     * <p>Following this call {@link #hasAltitude} will return true.
     */
    public void setAltitude(double altitude) {
        this.altitude = altitude;
        this.hasAltitude = true;
    }

    /**
     * Return radius of stationary region.
     */
    public float getRadius() {
        return radius;
    }

    /**
     * Sets radius of stationary region.
     */
    public void setRadius(float radius) {
        this.radius = radius;
        this.hasRadius = true;
    }

    /**
     * True if this location has an accuracy.
     *
     * <p>All locations generated by the {@link LocationManager} have an
     * accuracy.
     */
    public boolean hasAccuracy() {
        return hasAccuracy;
    }

    /**
     * True if this location has an altitude.
     */
    public boolean hasAltitude() {
        return hasAltitude;
    }

    /**
     * True if this location has a speed.
     */
    public boolean hasSpeed() {
        return hasSpeed;
    }

    /**
     * True if this location has a bearing.
     */
    public boolean hasBearing() {
        return hasBearing;
    }

    /**
     * True if this location has a radius.
     */
    public boolean hasRadius() {
        return hasRadius;
    }

    /**
     * Mock flags is 4-bit representation of mock status
     *
     * xxx0 - isFromMockProvider is false
     * xxx1 - isFromMockProvider is true
     * xx0x - hasIsFromMockProvider is false
     * xx1x - hasIsFromMockProvider is true
     * x0xx - areMockLocationsEnabled is false
     * x1xx - areMockLocationsEnabled is true
     * 0xxx - hasMockLocationsEnabled is false
     * 1xxx - hasMockLocationsEnabled is true
     *
     * @return mock flags
     */
    public int getMockFlags() {
        return mockFlags;
    }

    public void setMockFlags(int mockFlags) {
        this.mockFlags = mockFlags;
    }

    /**
     * Return true if method setIsFromMockProvider was called on location instance
     * @return true indicates that result from isFromMockProvider method is valid
     */
    public boolean hasIsFromMockProvider() {
        return ((mockFlags & 0x0002) >> 1) == 1;
    }

    /**
     * Returns true if the Location came from a mock provider.
     * Always check hasIsFromMockProvider() before this method
     *
     * @return true if this Location came from a mock provider, false otherwise
     */
    public boolean isFromMockProvider() {
        return (mockFlags & 0x0001) == 1;
    }

    /**
     * Method should be called to indicate that location was recorded by mock provider
     * If this method was called hasIsFromMockProvider method will always return true
     *
     * @param isFromMockProvider
     */
    public void setIsFromMockProvider(boolean isFromMockProvider) {
        mockFlags |= isFromMockProvider ? 0x0003 : 0x0002;
    }

    /**
     * Return true if method setMockLocationsEnabled was called on location instance
     * @return true indicates that result from areMockLocationsEnabled method is valid
     */
    public boolean hasMockLocationsEnabled() {
        return ((mockFlags & 0x0008) >> 3) == 1;
    }

    /**
     * Returns true if mock locations were enabled
     * Always check hasMockLocationsEnabled() before this method
     *
     * @return true if mock locations were enabled
     */
    public boolean areMockLocationsEnabled() {
        return ((mockFlags & 0x0004) >> 2) == 1;
    }

    /**
     * Method should be called when mock locations were detect in settings
     * If this method was called hasMockLocationsEnabled method will always return true
     *
     * @param mockLocationsEnabled
     */
    public void setMockLocationsEnabled(Boolean mockLocationsEnabled) {
        mockFlags |= mockLocationsEnabled ? 0x000C : 0x0008;
    }

    /**
     * Returns status of location. Can be one of:
     * <ul>
     *     <li>{@value #DELETED}</li>
     *     <li>{@value #POST_PENDING}</li>
     *     <li>{@value #SYNC_PENDING}</li>
     * </ul>
     * @return status
     */
    public int getStatus() {
        return status;
    }

    /**
     * Sets status of location. Can be one of:
     * <ul>
     *     <li>{@value #DELETED}</li>
     *     <li>{@value #POST_PENDING}</li>
     *     <li>{@value #SYNC_PENDING}</li>
     * </ul>
     * @param status
     */
    public void setStatus(int status) {
        this.status = status;
    }

    /**
     * Returns additional provider-specific information about the
     * location fix as a Bundle.  The keys and values are determined
     * by the provider.  If no additional information is available,
     * null is returned.
     *
     * <p> A number of common key/value pairs are listed
     * below. Providers that use any of the keys on this list must
     * provide the corresponding value as described below.
     *
     * <ul>
     * <li> satellites - the number of satellites used to derive the fix
     * </ul>
     */
    public Bundle getExtras() {
        return extras;
    }

    /**
     * Sets the extra information associated with this fix to the
     * given Bundle.
     */
    public void setExtras(Bundle extras) {
        this.extras = extras;
    }

    /**
     * Return android Location instance
     *
     * @return android.location.Location instance
     */
    public Location getLocation() {
        Location l = new Location(provider);
        l.setLatitude(latitude);
        l.setLongitude(longitude);
        l.setTime(time);
        if (hasAccuracy) l.setAccuracy(accuracy);
        if (hasAltitude) l.setAltitude(altitude);
        if (hasSpeed) l.setSpeed(speed);
        if (hasBearing) l.setBearing(bearing);
        l.setExtras(extras);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            l.setElapsedRealtimeNanos(elapsedRealtimeNanos);
        }

        return l;
    }

    /** Determines whether one Location reading is better than the current Location fix
     *
     * Origin: https://developer.android.com/guide/topics/location/strategies.html
     *
     * @param location  The new Location that you want to evaluate
     * @param currentBestLocation  The current Location fix, to which you want to compare the new one
     */
    public static boolean isBetterLocation(BackgroundLocation location, BackgroundLocation currentBestLocation) {
        if (location == null) {
            return false;
        }
        if (currentBestLocation == null) {
            // A new location is always better than no location
            return true;
        }

        long timeDeltaInNanos = 0;
        // Check whether the new location fix is newer or older
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            // because getTime is not monotonic
            timeDeltaInNanos = location.getElapsedRealtimeNanos() - currentBestLocation.getElapsedRealtimeNanos();
        } else {
            // unfortunately there is no other way for pre JELLY_BEAN_MR1 (API Level 17)
            timeDeltaInNanos = (location.getTime() - currentBestLocation.getTime()) * 1000000;
        }

        boolean isSignificantlyNewer = timeDeltaInNanos > TWO_MINUTES_IN_NANOS;
        boolean isSignificantlyOlder = timeDeltaInNanos < -TWO_MINUTES_IN_NANOS;
        boolean isNewer = timeDeltaInNanos > 0;

        // If it's been more than two minutes since the current location, use the new location
        // because the user has likely moved
        if (isSignificantlyNewer) {
            return true;
            // If the new location is more than two minutes older, it must be worse
        } else if (isSignificantlyOlder) {
            return false;
        }

        // Check whether the new location fix is more or less accurate
        int accuracyDelta = (int) (location.getAccuracy() - currentBestLocation.getAccuracy());
        boolean isLessAccurate = accuracyDelta > 0;
        boolean isMoreAccurate = accuracyDelta < 0;
        boolean isSignificantlyLessAccurate = accuracyDelta > 200;

        // Check if the old and new location are from the same provider
        boolean isFromSameProvider = isSameProvider(location.getProvider(),
                currentBestLocation.getProvider());

        // Determine location quality using a combination of timeliness and accuracy
        if (isMoreAccurate) {
            return true;
        } else if (isNewer && !isLessAccurate) {
            return true;
        } else if (isNewer && !isSignificantlyLessAccurate && isFromSameProvider) {
            return true;
        }
        return false;
    }

    /**
     * Check if given location is better that instance
     * @param location to compare is android Location
     * @return true if location is better and false if not
     */
    public boolean isBetterLocationThan(Location location) {
        if (location == null) {
            return true;
        }
        return !isBetterLocation(new BackgroundLocation(location), this);
    }

    /**
     * Check if given location is better that instance
     * @param location to compare
     * @return true if location is better and false if not
     */
    public boolean isBetterLocationThan(BackgroundLocation location) {
        if (location == null) {
            return true;
        }
        return !isBetterLocation(location, this);
    }

    /** Checks whether two providers are the same */
    private static boolean isSameProvider(String provider1, String provider2) {
        if (provider1 == null) {
            return provider2 == null;
        }
        return provider1.equals(provider2);
    }

    @Override
    public String toString () {
        StringBuilder s = new StringBuilder();
        s.append("BGLocation[").append(provider);
        s.append(String.format(" %.6f,%.6f", latitude, longitude));
        s.append(" id=").append(locationId);
        if (hasAccuracy) {
            s.append(String.format(" acc=%.0f", accuracy));
        } else {
            s.append(" acc=???");
        }
        if (time == 0) {
            s.append(" t=?!?");
        } else {
            s.append(" t=").append(time);
        }
        if (elapsedRealtimeNanos == 0) {
            s.append(" et=?!?");
        } else {
            s.append(" et=");
            TimeUtils.formatDuration(elapsedRealtimeNanos / 1000000L, s);
        }
        if (hasAltitude) s.append(" alt=").append(altitude);
        if (hasSpeed) s.append(" vel=").append(speed);
        if (hasBearing) s.append(" bear=").append(bearing);
        if (hasRadius) s.append(" radius=").append(radius);
        if (isFromMockProvider()) s.append(" mock");
        if (areMockLocationsEnabled()) s.append(" mocksEnabled");
        if (extras != null) {
            s.append(" {").append(extras).append('}');
        }
        s.append(" locprov=").append(locationProvider);
        s.append("]");

        return s.toString();
    }

    /**
     * Returns location as JSON object.
     * @throws JSONException
     */
    public JSONObject toJSONObject() throws JSONException {
        JSONObject json = new JSONObject();
        json.put("provider", provider);
        json.put("locationProvider", locationProvider);
        json.put("time", time);
        json.put("latitude", latitude);
        json.put("longitude", longitude);
        if (hasAccuracy) json.put("accuracy", accuracy);
        if (hasSpeed) json.put("speed", speed);
        if (hasAltitude) json.put("altitude", altitude);
        if (hasBearing) json.put("bearing", bearing);
        if (hasRadius) json.put("radius", radius);
        if (hasIsFromMockProvider()) json.put("isFromMockProvider", isFromMockProvider());
        if (hasMockLocationsEnabled()) json.put("mockLocationsEnabled", areMockLocationsEnabled());

        return json;
  	}

    /**
     * Returns location as JSON object containing location id
     * Note: Location id is not unique and is usually being recycled when
     * maximum number of locations is stored.
     *
     * @throws JSONException
     */
    public JSONObject toJSONObjectWithId() throws JSONException {
        JSONObject json = toJSONObject();
        json.put("id", locationId);
        return json;
    }

    /**
     * Return the contentvalues for this record
     */
    public ContentValues toContentValues() {
        ContentValues values = new ContentValues();
        //values.put(LocationEntry._ID, locationId);
        values.put(LocationEntry.COLUMN_NAME_TIME, time);
        values.put(LocationEntry.COLUMN_NAME_ACCURACY, accuracy);
        values.put(LocationEntry.COLUMN_NAME_SPEED, speed);
        values.put(LocationEntry.COLUMN_NAME_BEARING, bearing);
        values.put(LocationEntry.COLUMN_NAME_ALTITUDE, altitude);
        values.put(LocationEntry.COLUMN_NAME_LATITUDE, latitude);
        values.put(LocationEntry.COLUMN_NAME_LONGITUDE, longitude);
        values.put(LocationEntry.COLUMN_NAME_RADIUS, radius);
        values.put(LocationEntry.COLUMN_NAME_HAS_ACCURACY, hasAccuracy);
        values.put(LocationEntry.COLUMN_NAME_HAS_SPEED, hasSpeed);
        values.put(LocationEntry.COLUMN_NAME_HAS_BEARING, hasBearing);
        values.put(LocationEntry.COLUMN_NAME_HAS_ALTITUDE, hasAltitude);
        values.put(LocationEntry.COLUMN_NAME_HAS_RADIUS, hasRadius);
        values.put(LocationEntry.COLUMN_NAME_PROVIDER, provider);
        values.put(LocationEntry.COLUMN_NAME_LOCATION_PROVIDER, locationProvider);
        values.put(LocationEntry.COLUMN_NAME_STATUS, status);
        values.put(LocationEntry.COLUMN_NAME_BATCH_START_MILLIS, batchStartMillis);
        values.put(LocationEntry.COLUMN_NAME_MOCK_FLAGS, mockFlags);
        return values;
    }

    public Object getValueForKey(String key) {
        if ("@id".equals(key)) {
            return locationId;
        }
        if ("@provider".equals(key)) {
            return provider;
        }
        if ("@locationProvider".equals(key)) {
            return locationProvider;
        }
        if ("@time".equals(key)) {
            return time;
        }
        if ("@latitude".equals(key)) {
            return latitude;
        }
        if ("@longitude".equals(key)) {
            return longitude;
        }
        if ("@accuracy".equals(key)) {
            return hasAccuracy ? accuracy : JSONObject.NULL;
        }
        if ("@speed".equals(key)) {
            return hasSpeed ? speed : JSONObject.NULL;
        }
        if ("@altitude".equals(key)) {
            return hasAltitude ? altitude : JSONObject.NULL;
        }
        if ("@bearing".equals(key)) {
            return hasBearing ? bearing : JSONObject.NULL;
        }
        if ("@radius".equals(key)) {
            return hasRadius ? radius : JSONObject.NULL;
        }
        if ("@isFromMockProvider".equals(key)) {
            return hasIsFromMockProvider() ? isFromMockProvider() : JSONObject.NULL;
        }
        if ("@mockLocationsEnabled".equals(key)) {
            return hasMockLocationsEnabled() ? areMockLocationsEnabled() : JSONObject.NULL;
        }

        return null;
    }
}
