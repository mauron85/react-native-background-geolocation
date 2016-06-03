package com.marianhello.bgloc.data.sqlite;


import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import com.marianhello.bgloc.data.sqlite.LocationContract.LocationEntry;
import com.marianhello.bgloc.data.sqlite.ConfigurationContract.ConfigurationEntry;

public class SQLiteOpenHelper extends android.database.sqlite.SQLiteOpenHelper {
    private static final String SQLITE_DATABASE_NAME = "cordova_bg_geolocation.db";
    private static final int DATABASE_VERSION = 10;
    private static final String TEXT_TYPE = " TEXT";
    private static final String INTEGER_TYPE = " INTEGER";
    private static final String REAL_TYPE = " REAL";
    private static final String COMMA_SEP = ",";

    private static final String SQL_CREATE_LOCATION_TABLE =
        "CREATE TABLE " + LocationEntry.TABLE_NAME + " (" +
        LocationEntry._ID + " INTEGER PRIMARY KEY," +
        LocationEntry.COLUMN_NAME_TIME + INTEGER_TYPE + COMMA_SEP +
        LocationEntry.COLUMN_NAME_ACCURACY + REAL_TYPE + COMMA_SEP +
        LocationEntry.COLUMN_NAME_SPEED + REAL_TYPE + COMMA_SEP +
        LocationEntry.COLUMN_NAME_BEARING + REAL_TYPE + COMMA_SEP +
        LocationEntry.COLUMN_NAME_ALTITUDE + REAL_TYPE + COMMA_SEP +
        LocationEntry.COLUMN_NAME_LATITUDE + REAL_TYPE + COMMA_SEP +
        LocationEntry.COLUMN_NAME_LONGITUDE + REAL_TYPE + COMMA_SEP +
        LocationEntry.COLUMN_NAME_PROVIDER + TEXT_TYPE + COMMA_SEP +
        LocationEntry.COLUMN_NAME_LOCATION_PROVIDER + INTEGER_TYPE + COMMA_SEP +
        LocationEntry.COLUMN_NAME_DEBUG + INTEGER_TYPE +
        " )";

    private static final String SQL_CREATE_CONFIG_TABLE =
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
        ConfigurationEntry.COLUMN_NAME_START_BOOT + INTEGER_TYPE + COMMA_SEP +
        ConfigurationEntry.COLUMN_NAME_START_FOREGROUND + INTEGER_TYPE + COMMA_SEP +
        ConfigurationEntry.COLUMN_NAME_LOCATION_PROVIDER + TEXT_TYPE + COMMA_SEP +
        ConfigurationEntry.COLUMN_NAME_INTERVAL + INTEGER_TYPE + COMMA_SEP +
        ConfigurationEntry.COLUMN_NAME_FASTEST_INTERVAL + INTEGER_TYPE + COMMA_SEP +
        ConfigurationEntry.COLUMN_NAME_ACTIVITIES_INTERVAL + INTEGER_TYPE + COMMA_SEP +
        ConfigurationEntry.COLUMN_NAME_URL + TEXT_TYPE + COMMA_SEP +
        ConfigurationEntry.COLUMN_NAME_HEADERS + TEXT_TYPE +
        " )";

    private static final String SQL_DELETE_CONFIG_TABLE =
            "DROP TABLE IF EXISTS " + ConfigurationEntry.TABLE_NAME;

    private static final String SQL_DELETE_LOCATION_TABLE =
            "DROP TABLE IF EXISTS " + LocationEntry.TABLE_NAME;

    SQLiteOpenHelper(Context context) {
        super(context, SQLITE_DATABASE_NAME, null, DATABASE_VERSION);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        db.execSQL(SQL_CREATE_LOCATION_TABLE);
        Log.d(this.getClass().getName(), SQL_CREATE_LOCATION_TABLE);
        db.execSQL(SQL_CREATE_CONFIG_TABLE);
        Log.d(this.getClass().getName(), SQL_CREATE_CONFIG_TABLE);
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        // This database is only a cache for online data, so its upgrade policy is
        // to simply to discard the data and start over
        db.execSQL(SQL_DELETE_LOCATION_TABLE);
        Log.d(this.getClass().getName(), SQL_DELETE_LOCATION_TABLE);
        db.execSQL(SQL_DELETE_CONFIG_TABLE);
        Log.d(this.getClass().getName(), SQL_DELETE_CONFIG_TABLE);
        onCreate(db);
    }

    @Override
    public void onDowngrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        onUpgrade(db, oldVersion, newVersion);
    }
}
