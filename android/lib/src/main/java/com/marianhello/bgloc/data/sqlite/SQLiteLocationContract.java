package com.marianhello.bgloc.data.sqlite;

import android.provider.BaseColumns;

public final class SQLiteLocationContract {
    // To prevent someone from accidentally instantiating the contract class,
    // give it an empty constructor.
    public SQLiteLocationContract() {}

    /* Inner class that defines the table contents */
    public static abstract class LocationEntry implements BaseColumns {
        public static final String TABLE_NAME = "location";
        public static final String COLUMN_NAME_NULLABLE = "NULLHACK";
        public static final String COLUMN_NAME_TIME = "time";
        public static final String COLUMN_NAME_ACCURACY = "accuracy";
        public static final String COLUMN_NAME_SPEED = "speed";
        public static final String COLUMN_NAME_BEARING = "bearing";
        public static final String COLUMN_NAME_ALTITUDE = "altitude";
        public static final String COLUMN_NAME_LATITUDE = "latitude";
        public static final String COLUMN_NAME_LONGITUDE = "longitude";
        public static final String COLUMN_NAME_RADIUS = "radius";
        public static final String COLUMN_NAME_HAS_ACCURACY = "has_accuracy";
        public static final String COLUMN_NAME_HAS_SPEED = "has_speed";
        public static final String COLUMN_NAME_HAS_BEARING = "has_bearing";
        public static final String COLUMN_NAME_HAS_ALTITUDE = "has_altitude";
        public static final String COLUMN_NAME_HAS_RADIUS = "has_radius";
        public static final String COLUMN_NAME_PROVIDER = "provider";
        public static final String COLUMN_NAME_LOCATION_PROVIDER = "service_provider";
        public static final String COLUMN_NAME_VALID = "valid";
        public static final String COLUMN_NAME_BATCH_START_MILLIS = "batch_start";
    }
}
