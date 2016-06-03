package com.marianhello.bgloc.data.sqlite;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.TimeZone;
import java.util.List;
import java.util.Collection;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import org.json.JSONObject;
import org.json.JSONException;

import com.marianhello.bgloc.Config;
import com.marianhello.bgloc.data.ConfigurationDAO;
import com.marianhello.bgloc.data.sqlite.ConfigurationContract.ConfigurationEntry;

public class SQLiteConfigurationDAO implements ConfigurationDAO {
  public static final String DATE_FORMAT = "yyyy-MM-dd'T'HH:mm'Z'";
  private static final String TAG = "SQLiteConfigurationDAO";
  private Context context;

  public SQLiteConfigurationDAO(Context context) {
      this.context = context;
  }

  public Config retrieveConfiguration() throws JSONException {
    SQLiteDatabase db = null;
    Cursor cursor = null;

    String[] columns = {
    	ConfigurationEntry._ID,
      ConfigurationEntry.COLUMN_NAME_RADIUS,
      ConfigurationEntry.COLUMN_NAME_DISTANCE_FILTER,
      ConfigurationEntry.COLUMN_NAME_DESIRED_ACCURACY,
      ConfigurationEntry.COLUMN_NAME_DEBUG,
      ConfigurationEntry.COLUMN_NAME_NOTIF_TITLE,
      ConfigurationEntry.COLUMN_NAME_NOTIF_TEXT,
      ConfigurationEntry.COLUMN_NAME_NOTIF_ICON_LARGE,
      ConfigurationEntry.COLUMN_NAME_NOTIF_ICON_SMALL,
      ConfigurationEntry.COLUMN_NAME_NOTIF_COLOR,
      ConfigurationEntry.COLUMN_NAME_STOP_TERMINATE,
      ConfigurationEntry.COLUMN_NAME_START_BOOT,
      ConfigurationEntry.COLUMN_NAME_START_FOREGROUND,
      ConfigurationEntry.COLUMN_NAME_LOCATION_PROVIDER,
      ConfigurationEntry.COLUMN_NAME_INTERVAL,
      ConfigurationEntry.COLUMN_NAME_FASTEST_INTERVAL,
      ConfigurationEntry.COLUMN_NAME_ACTIVITIES_INTERVAL,
      ConfigurationEntry.COLUMN_NAME_URL,
      ConfigurationEntry.COLUMN_NAME_HEADERS
    };

    String whereClause = null;
    String[] whereArgs = null;
    String groupBy = null;
    String having = null;
    String orderBy = null;

    Config config = null;
    try {
      db = new SQLiteOpenHelper(context).getReadableDatabase();
      cursor = db.query(
          ConfigurationEntry.TABLE_NAME,  // The table to query
          columns,                   // The columns to return
          whereClause,               // The columns for the WHERE clause
          whereArgs,                 // The values for the WHERE clause
          groupBy,                   // don't group the rows
          having,                    // don't filter by row groups
          orderBy                    // The sort order
      );
      if (cursor.moveToFirst()) {
        config = hydrate(cursor);
      }
    } finally {
      if (cursor != null) {
        cursor.close();
      }
      if (db != null) {
        db.close();
      }
    }
    return config;
  }

  public boolean persistConfiguration(Config config) throws NullPointerException {
    SQLiteDatabase db = new SQLiteOpenHelper(context).getWritableDatabase();
    db.beginTransaction();
    db.delete(ConfigurationEntry.TABLE_NAME, null, null);
    long rowId = db.insert(ConfigurationEntry.TABLE_NAME, ConfigurationEntry.COLUMN_NAME_NULLABLE, getContentValues(config));
    Log.d(TAG, "After insert, rowId = " + rowId);
    db.setTransactionSuccessful();
    db.endTransaction();
    db.close();
    if (rowId > -1) {
      return true;
    } else {
      return false;
    }
  }

  private Config hydrate(Cursor c) throws JSONException {
    Config config = new Config();
    config.setStationaryRadius(c.getFloat(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_RADIUS)));
    config.setDistanceFilter(c.getInt(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_DISTANCE_FILTER)));
    config.setDesiredAccuracy(c.getInt(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_DESIRED_ACCURACY)));
    config.setDebugging( (c.getInt(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_DEBUG)) == 1) ? true : false );
    config.setNotificationTitle(c.getString(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_NOTIF_TITLE)));
    config.setNotificationText(c.getString(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_NOTIF_TEXT)));
    config.setSmallNotificationIcon(c.getString(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_NOTIF_ICON_SMALL)));
    config.setLargeNotificationIcon(c.getString(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_NOTIF_ICON_LARGE)));
    config.setNotificationIconColor(c.getString(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_NOTIF_COLOR)));
    config.setStopOnTerminate( (c.getInt(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_STOP_TERMINATE)) == 1) ? true : false );
    config.setStartOnBoot( (c.getInt(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_START_BOOT)) == 1) ? true : false );
    config.setStartForeground( (c.getInt(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_START_FOREGROUND)) == 1) ? true : false );
    config.setLocationProvider(c.getInt(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_LOCATION_PROVIDER)));
    config.setInterval(c.getInt(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_INTERVAL)));
    config.setFastestInterval(c.getInt(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_FASTEST_INTERVAL)));
    config.setActivitiesInterval(c.getInt(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_ACTIVITIES_INTERVAL)));
    config.setUrl(c.getString(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_URL)));
    config.setHttpHeaders(new JSONObject(c.getString(c.getColumnIndex(ConfigurationEntry.COLUMN_NAME_HEADERS))));

    return config;
  }

  private ContentValues getContentValues(Config config) throws NullPointerException {
    ContentValues values = new ContentValues();
    values.put(ConfigurationEntry.COLUMN_NAME_RADIUS, config.getStationaryRadius());
    values.put(ConfigurationEntry.COLUMN_NAME_DISTANCE_FILTER, config.getDistanceFilter());
    values.put(ConfigurationEntry.COLUMN_NAME_DESIRED_ACCURACY, config.getDesiredAccuracy());
    values.put(ConfigurationEntry.COLUMN_NAME_DEBUG, (config.isDebugging() == true) ? 1 : 0);
    values.put(ConfigurationEntry.COLUMN_NAME_NOTIF_TITLE, config.getNotificationTitle());
    values.put(ConfigurationEntry.COLUMN_NAME_NOTIF_TEXT, config.getNotificationText());
    values.put(ConfigurationEntry.COLUMN_NAME_NOTIF_ICON_SMALL, config.getSmallNotificationIcon());
    values.put(ConfigurationEntry.COLUMN_NAME_NOTIF_ICON_LARGE, config.getLargeNotificationIcon());
    values.put(ConfigurationEntry.COLUMN_NAME_NOTIF_COLOR, config.getNotificationIconColor());
    values.put(ConfigurationEntry.COLUMN_NAME_STOP_TERMINATE, (config.getStopOnTerminate() == true) ? 1 : 0);
    values.put(ConfigurationEntry.COLUMN_NAME_START_BOOT, (config.getStartOnBoot() == true) ? 1 : 0);
    values.put(ConfigurationEntry.COLUMN_NAME_START_FOREGROUND, (config.getStartForeground() == true) ? 1 : 0);
    values.put(ConfigurationEntry.COLUMN_NAME_LOCATION_PROVIDER, config.getLocationProvider());
    values.put(ConfigurationEntry.COLUMN_NAME_INTERVAL, config.getInterval());
    values.put(ConfigurationEntry.COLUMN_NAME_FASTEST_INTERVAL, config.getFastestInterval());
    values.put(ConfigurationEntry.COLUMN_NAME_ACTIVITIES_INTERVAL, config.getActivitiesInterval());
    values.put(ConfigurationEntry.COLUMN_NAME_URL, config.getUrl());
    values.put(ConfigurationEntry.COLUMN_NAME_HEADERS, new JSONObject(config.getHttpHeaders()).toString());

    return values;
  }
}
