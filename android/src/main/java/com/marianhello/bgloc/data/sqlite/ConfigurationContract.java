package com.marianhello.bgloc.data.sqlite;

import android.provider.BaseColumns;

public final class ConfigurationContract {
    // To prevent someone from accidentally instantiating the contract class,
    // give it an empty constructor.
    public ConfigurationContract() {}

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
        public static final String COLUMN_NAME_LOCATION_PROVIDER = "service_provider";
        public static final String COLUMN_NAME_INTERVAL = "interval";
        public static final String COLUMN_NAME_FASTEST_INTERVAL = "fastest_interval";
        public static final String COLUMN_NAME_ACTIVITIES_INTERVAL = "activities_interval";
        public static final String COLUMN_NAME_URL = "url";
        public static final String COLUMN_NAME_HEADERS = "http_headers";
    }
}
