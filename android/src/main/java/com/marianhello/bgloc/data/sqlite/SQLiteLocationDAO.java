package com.marianhello.bgloc.data.sqlite;

import java.util.ArrayList;
import java.util.Collection;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.util.Log;

import com.marianhello.bgloc.data.LocationDAO;
import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.sqlite.LocationContract.LocationEntry;

public class SQLiteLocationDAO implements LocationDAO {
  public static final String DATE_FORMAT = "yyyy-MM-dd'T'HH:mm'Z'";
  private static final String TAG = "SQLiteLocationDAO";
  private Context context;

  public SQLiteLocationDAO(Context context) {
    this.context = context;
  }

  public Collection<BackgroundLocation> getAllLocations() {
    SQLiteDatabase db = null;
    Cursor cursor = null;

    String[] columns = {
    	LocationEntry._ID,
      LocationEntry.COLUMN_NAME_TIME,
      LocationEntry.COLUMN_NAME_ACCURACY,
      LocationEntry.COLUMN_NAME_SPEED,
      LocationEntry.COLUMN_NAME_BEARING,
      LocationEntry.COLUMN_NAME_ALTITUDE,
      LocationEntry.COLUMN_NAME_LATITUDE,
      LocationEntry.COLUMN_NAME_LONGITUDE,
      LocationEntry.COLUMN_NAME_PROVIDER,
      LocationEntry.COLUMN_NAME_LOCATION_PROVIDER,
      LocationEntry.COLUMN_NAME_DEBUG
    };

    String whereClause = null;
    String[] whereArgs = null;
    String groupBy = null;
    String having = null;

    String orderBy =
        LocationEntry.COLUMN_NAME_TIME + " ASC";

    Collection<BackgroundLocation> all = new ArrayList<BackgroundLocation>();
    try {
      db = new SQLiteOpenHelper(context).getReadableDatabase();
      cursor = db.query(
          LocationEntry.TABLE_NAME,  // The table to query
          columns,                   // The columns to return
          whereClause,               // The columns for the WHERE clause
          whereArgs,                 // The values for the WHERE clause
          groupBy,                   // don't group the rows
          having,                    // don't filter by row groups
          orderBy                    // The sort order
      );
      while (cursor.moveToNext()) {
        all.add(hydrate(cursor));
      }
    } finally {
      if (cursor != null) {
        cursor.close();
      }
      if (db != null) {
        db.close();
      }
    }
    return all;
  }

  public Long persistLocation(BackgroundLocation location) {
    SQLiteDatabase db = new SQLiteOpenHelper(context).getWritableDatabase();
    db.beginTransaction();
    ContentValues values = getContentValues(location);
    long rowId = db.insert(LocationEntry.TABLE_NAME, LocationEntry.COLUMN_NAME_NULLABLE, values);
    Log.d(TAG, "After insert, rowId = " + rowId);
    db.setTransactionSuccessful();
    db.endTransaction();
    db.close();
    return rowId;
  }

  public void deleteLocation(Long locationId) {
    String whereClause = LocationEntry._ID + " = ?";
    String[] whereArgs = { String.valueOf(locationId) };
    SQLiteDatabase db = new SQLiteOpenHelper(context).getWritableDatabase();
    db.beginTransaction();
    db.delete(LocationEntry.TABLE_NAME, whereClause, whereArgs);
    db.setTransactionSuccessful();
    db.endTransaction();
    db.close();
  }

  public void deleteAllLocations() {
    SQLiteDatabase db = new SQLiteOpenHelper(context).getWritableDatabase();
    db.beginTransaction();
    db.delete(LocationEntry.TABLE_NAME, null, null);
    db.setTransactionSuccessful();
    db.endTransaction();
    db.close();
  }

  private BackgroundLocation hydrate(Cursor c) {
    BackgroundLocation l = new BackgroundLocation(c.getString(c.getColumnIndex(LocationEntry.COLUMN_NAME_PROVIDER)));
    l.setLocationId(c.getLong(c.getColumnIndex(LocationEntry._ID)));
    l.setTime(c.getLong(c.getColumnIndex(LocationEntry.COLUMN_NAME_TIME)));
    l.setAccuracy(c.getFloat(c.getColumnIndex(LocationEntry.COLUMN_NAME_ACCURACY)));
    l.setSpeed(c.getFloat(c.getColumnIndex(LocationEntry.COLUMN_NAME_SPEED)));
    l.setBearing(c.getFloat(c.getColumnIndex(LocationEntry.COLUMN_NAME_BEARING)));
    l.setAltitude(c.getDouble(c.getColumnIndex(LocationEntry.COLUMN_NAME_ALTITUDE)));
    l.setLatitude(c.getDouble(c.getColumnIndex(LocationEntry.COLUMN_NAME_LATITUDE)));
    l.setLongitude(c.getDouble(c.getColumnIndex(LocationEntry.COLUMN_NAME_LONGITUDE)));
    l.setLocationProvider(c.getInt(c.getColumnIndex(LocationEntry.COLUMN_NAME_LOCATION_PROVIDER)));
    l.setDebug( (c.getInt(c.getColumnIndex(LocationEntry.COLUMN_NAME_DEBUG)) == 1) ? true : false);

    return l;
  }

  private ContentValues getContentValues(BackgroundLocation location) {
    ContentValues values = new ContentValues();
    values.put(LocationEntry.COLUMN_NAME_TIME, location.getTime());
    values.put(LocationEntry.COLUMN_NAME_ACCURACY, location.getAccuracy());
    values.put(LocationEntry.COLUMN_NAME_SPEED, location.getSpeed());
    values.put(LocationEntry.COLUMN_NAME_BEARING, location.getBearing());
    values.put(LocationEntry.COLUMN_NAME_ALTITUDE, location.getAltitude());
    values.put(LocationEntry.COLUMN_NAME_LATITUDE, location.getLatitude());
    values.put(LocationEntry.COLUMN_NAME_LONGITUDE, location.getLongitude());
    values.put(LocationEntry.COLUMN_NAME_PROVIDER, location.getProvider());
    values.put(LocationEntry.COLUMN_NAME_LOCATION_PROVIDER, location.getLocationProvider());
    values.put(LocationEntry.COLUMN_NAME_DEBUG, (location.getDebug() == true) ? 1 : 0);

    return values;
  }
}
