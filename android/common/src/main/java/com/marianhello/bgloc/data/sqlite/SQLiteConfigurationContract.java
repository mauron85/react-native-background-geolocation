package com.marianhello.bgloc.data.sqlite;

import android.provider.BaseColumns;

import static com.marianhello.bgloc.data.sqlite.SQLiteOpenHelper.COMMA_SEP;
import static com.marianhello.bgloc.data.sqlite.SQLiteOpenHelper.INTEGER_TYPE;
import static com.marianhello.bgloc.data.sqlite.SQLiteOpenHelper.REAL_TYPE;
import static com.marianhello.bgloc.data.sqlite.SQLiteOpenHelper.TEXT_TYPE;

public final class SQLiteConfigurationContract {
    // To prevent someone from accidentally instantiating the contract class,
    // give it an empty constructor.
    public SQLiteConfigurationContract() {}

    /* Inner class that defines the table contents */
    public static abstract class ConfigurationEntry implements BaseColumns {
        public static final String TABLE_NAME = "configuration";
        public static final String COLUMN_NAME_NULLABLE = "NULLHACK";
        public static final String COLUMN_NAME_RADIUS = "stationary_radius";
        public static final String COLUMN_NAME_DISTANCE_FILTER = "distance_filter";
        public static final String COLUMN_NAME_DESIRED_ACCURACY = "desired_accuracy";
        public static final String COLUMN_NAME_DEBUG = "debugging";
        public static final String COLUMN_NAME_NOTIF_TITLE = "notification_title";
        public static final String COLUMN_NAME_NOTIF_TEXT = "notification_text";
        public static final String COLUMN_NAME_NOTIF_ICON_LARGE = "notification_icon_large";
        public static final String COLUMN_NAME_NOTIF_ICON_SMALL = "notification_icon_small";
        public static final String COLUMN_NAME_NOTIF_COLOR = "notification_icon_color";
        public static final String COLUMN_NAME_STOP_TERMINATE = "stop_terminate";
        public static final String COLUMN_NAME_START_BOOT = "start_boot";
        public static final String COLUMN_NAME_START_FOREGROUND = "start_foreground";
        public static final String COLUMN_NAME_NOTIFICATIONS_ENABLED = "notifications_enabled";
        public static final String COLUMN_NAME_STOP_ON_STILL = "stop_still";
        public static final String COLUMN_NAME_LOCATION_PROVIDER = "service_provider";
        public static final String COLUMN_NAME_INTERVAL = "interval";
        public static final String COLUMN_NAME_FASTEST_INTERVAL = "fastest_interval";
        public static final String COLUMN_NAME_ACTIVITIES_INTERVAL = "activities_interval";
        public static final String COLUMN_NAME_URL = "url";
        public static final String COLUMN_NAME_SYNC_URL = "sync_url";
        public static final String COLUMN_NAME_SYNC_THRESHOLD = "sync_threshold";
        public static final String COLUMN_NAME_HEADERS = "http_headers";
        public static final String COLUMN_NAME_MAX_LOCATIONS = "max_locations";
        public static final String COLUMN_NAME_TEMPLATE = "template";

        public static final String SQL_CREATE_CONFIG_TABLE =
                "CREATE TABLE " + ConfigurationEntry.TABLE_NAME + " (" +
                        ConfigurationEntry._ID + " INTEGER PRIMARY KEY," +
                        ConfigurationEntry.COLUMN_NAME_RADIUS + REAL_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_DISTANCE_FILTER + INTEGER_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_DESIRED_ACCURACY + INTEGER_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_DEBUG + INTEGER_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_NOTIF_TITLE + TEXT_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_NOTIF_TEXT + TEXT_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_NOTIF_ICON_SMALL + TEXT_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_NOTIF_ICON_LARGE + TEXT_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_NOTIF_COLOR + TEXT_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_STOP_TERMINATE + INTEGER_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_STOP_ON_STILL + INTEGER_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_START_BOOT + INTEGER_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_START_FOREGROUND + INTEGER_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_NOTIFICATIONS_ENABLED + INTEGER_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_LOCATION_PROVIDER + TEXT_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_INTERVAL + INTEGER_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_FASTEST_INTERVAL + INTEGER_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_ACTIVITIES_INTERVAL + INTEGER_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_URL + TEXT_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_SYNC_URL + TEXT_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_SYNC_THRESHOLD + INTEGER_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_HEADERS + TEXT_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_MAX_LOCATIONS + INTEGER_TYPE + COMMA_SEP +
                        ConfigurationEntry.COLUMN_NAME_TEMPLATE + TEXT_TYPE +
                        " )";

        public static final String SQL_DROP_CONFIG_TABLE =
                "DROP TABLE IF EXISTS " + ConfigurationEntry.TABLE_NAME;
    }
}
