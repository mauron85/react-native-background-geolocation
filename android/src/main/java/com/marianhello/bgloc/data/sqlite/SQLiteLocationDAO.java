package com.marianhello.bgloc.data.sqlite;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.DatabaseUtils;
import android.database.sqlite.SQLiteDatabase;
import android.text.TextUtils;

import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.LocationDAO;
import com.marianhello.bgloc.data.sqlite.SQLiteLocationContract.LocationEntry;

import java.util.ArrayList;
import java.util.Collection;

public class SQLiteLocationDAO implements LocationDAO {
  private SQLiteDatabase db;

  public SQLiteLocationDAO(Context context) {
    SQLiteOpenHelper helper = SQLiteOpenHelper.getHelper(context);
    this.db = helper.getWritableDatabase();
  }

  public SQLiteLocationDAO(SQLiteDatabase db) {
    this.db = db;
  }

  public long getLastInsertRowId(SQLiteDatabase db) {
    Cursor cur = db.rawQuery("SELECT last_insert_rowid()", null);
    cur.moveToFirst();
    long id = cur.getLong(0);
    cur.close();
    return id;
  }

  /**
   * Get all locations that match whereClause
   *
   * @param whereClause
   * @param whereArgs
   * @return collection of locations
     */
  private Collection<BackgroundLocation> getLocations(String whereClause, String[] whereArgs) {
    Collection<BackgroundLocation> locations = new ArrayList<BackgroundLocation>();

    String[] columns = {
      LocationEntry._ID,
      LocationEntry.COLUMN_NAME_PROVIDER,
      LocationEntry.COLUMN_NAME_TIME,
      LocationEntry.COLUMN_NAME_ACCURACY,
      LocationEntry.COLUMN_NAME_SPEED,
      LocationEntry.COLUMN_NAME_BEARING,
      LocationEntry.COLUMN_NAME_ALTITUDE,
      LocationEntry.COLUMN_NAME_RADIUS,
      LocationEntry.COLUMN_NAME_LATITUDE,
      LocationEntry.COLUMN_NAME_LONGITUDE,
      LocationEntry.COLUMN_NAME_HAS_ACCURACY,
      LocationEntry.COLUMN_NAME_HAS_SPEED,
      LocationEntry.COLUMN_NAME_HAS_BEARING,
      LocationEntry.COLUMN_NAME_HAS_ALTITUDE,
      LocationEntry.COLUMN_NAME_HAS_RADIUS,
      LocationEntry.COLUMN_NAME_LOCATION_PROVIDER,
      LocationEntry.COLUMN_NAME_VALID,
      LocationEntry.COLUMN_NAME_BATCH_START_MILLIS
    };

    String groupBy = null;
    String having = null;
    String orderBy = LocationEntry.COLUMN_NAME_TIME + " ASC";
    Cursor cursor = null;

    try {
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
        locations.add(hydrate(cursor));
      }
    } finally {
      if (cursor != null) {
        cursor.close();
      }
    }

    return locations;
  }
  public Collection<BackgroundLocation> getAllLocations() {
    return getLocations(null, null);
  }

  public Collection<BackgroundLocation> getValidLocations() {
    String whereClause = LocationEntry.COLUMN_NAME_VALID + " = ?";
    String[] whereArgs = { "1" };

    return getLocations(whereClause, whereArgs);
  }

  public Long locationsForSyncCount(Long millisSinceLastBatch) {
    String whereClause = TextUtils.join("", new String[]{
            SQLiteLocationContract.LocationEntry.COLUMN_NAME_VALID + " = ? AND ( ",
            SQLiteLocationContract.LocationEntry.COLUMN_NAME_BATCH_START_MILLIS + " IS NULL OR ",
            SQLiteLocationContract.LocationEntry.COLUMN_NAME_BATCH_START_MILLIS + " < ? )",
    });
    String[] whereArgs = { "1", String.valueOf(millisSinceLastBatch) };

    return DatabaseUtils.queryNumEntries(db, LocationEntry.TABLE_NAME, whereClause, whereArgs);
  }

  /**
   * Persist location into database
   *
   * @param location
   * @return rowId or -1 when error occured
   */
  public Long persistLocation(BackgroundLocation location) {
    ContentValues values = getContentValues(location);
    long rowId = db.insertOrThrow(LocationEntry.TABLE_NAME, LocationEntry.COLUMN_NAME_NULLABLE, values);

    return rowId;
  }

  /**
   * Persist location into database with maximum row limit
   *
   * Method will ensure that there will be no more records than maxRows.
   * Instead old records will be replaced with newer ones.
   * If maxRows will change in time, method will delete excess records and vacuum table.
   *
   * @param location
   * @param maxRows
   * @return rowId or -1 when error occured
   */
  public Long persistLocationWithLimit(BackgroundLocation location, Integer maxRows) {
    Long rowId = null;
    String sql = null;
    Boolean shouldVacuum = false;

    long rowCount = DatabaseUtils.queryNumEntries(db, LocationEntry.TABLE_NAME);

    if (rowCount < maxRows) {
      ContentValues values = getContentValues(location);
      rowId = db.insertOrThrow(LocationEntry.TABLE_NAME, LocationEntry.COLUMN_NAME_NULLABLE, values);

      return rowId;
    }

    db.beginTransactionNonExclusive();

    if (rowCount > maxRows) {
      sql = new StringBuilder("DELETE FROM ")
              .append(LocationEntry.TABLE_NAME)
              .append(" WHERE ").append(LocationEntry._ID)
              .append(" IN (SELECT ").append(LocationEntry._ID)
              .append(" FROM ").append(LocationEntry.TABLE_NAME)
              .append(" ORDER BY ").append(LocationEntry.COLUMN_NAME_TIME)
              .append(" LIMIT ?)")
              .toString();
      db.execSQL(sql, new Object[] {(rowCount - maxRows)});
      shouldVacuum = true;
    }

    sql = new StringBuilder("UPDATE ")
            .append(LocationEntry.TABLE_NAME).append(" SET ")
            .append(LocationEntry.COLUMN_NAME_PROVIDER).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_TIME).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_ACCURACY).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_SPEED).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_BEARING).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_ALTITUDE).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_RADIUS).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_LATITUDE).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_LONGITUDE).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_HAS_ACCURACY).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_HAS_SPEED).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_HAS_BEARING).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_HAS_ALTITUDE).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_HAS_RADIUS).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_LOCATION_PROVIDER).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_BATCH_START_MILLIS).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_VALID).append("= ?")
            .append(" WHERE ").append(LocationEntry.COLUMN_NAME_TIME)
            .append("= (SELECT min(").append(LocationEntry.COLUMN_NAME_TIME).append(") FROM ")
            .append(LocationEntry.TABLE_NAME).append(")")
            .toString();
    db.execSQL(sql, new Object[] {
            location.getProvider(),
            location.getTime(),
            location.getAccuracy(),
            location.getSpeed(),
            location.getBearing(),
            location.getAltitude(),
            location.getRadius(),
            location.getLatitude(),
            location.getLongitude(),
            location.hasAccuracy() ? 1 : 0,
            location.hasSpeed() ? 1 : 0,
            location.hasBearing() ? 1 : 0,
            location.hasAltitude() ? 1 : 0,
            location.hasRadius() ? 1 : 0,
            location.getLocationProvider(),
            location.getBatchStartMillis(),
            location.isValid() ? 1 : 0
    });

    rowId = getLastInsertRowId(db);
    db.setTransactionSuccessful();
    db.endTransaction();

    if (shouldVacuum) { db.execSQL("VACUUM"); }

    return rowId;
  }

  /**
   * Delete location by given locationId
   *
   * Note: location is not actually deleted only flagged as non valid
   * @param locationId
   */
  public void deleteLocation(Long locationId) {
    ContentValues values = new ContentValues();
    values.put(LocationEntry.COLUMN_NAME_VALID, 0);

    String whereClause = LocationEntry._ID + " = ?";
    String[] whereArgs = { String.valueOf(locationId) };

    db.update(LocationEntry.TABLE_NAME, values, whereClause, whereArgs);
  }

  /**
   * Delete all locations
   *
   * Note: location are not actually deleted only flagged as non valid
   */
  public void deleteAllLocations() {
    ContentValues values = new ContentValues();
    values.put(LocationEntry.COLUMN_NAME_VALID, 0);

    db.update(LocationEntry.TABLE_NAME, values, null, null);
  }

  private BackgroundLocation hydrate(Cursor c) {
    BackgroundLocation l = new BackgroundLocation(c.getString(c.getColumnIndex(LocationEntry.COLUMN_NAME_PROVIDER)));
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
    l.setValid(c.getInt(c.getColumnIndex(LocationEntry.COLUMN_NAME_VALID)) != 0);
    l.setLocationId(c.getLong(c.getColumnIndex(LocationEntry._ID)));

    return l;
  }

  private ContentValues getContentValues(BackgroundLocation l) {
    ContentValues values = new ContentValues();
    values.put(LocationEntry.COLUMN_NAME_PROVIDER, l.getProvider());
    values.put(LocationEntry.COLUMN_NAME_TIME, l.getTime());
    values.put(LocationEntry.COLUMN_NAME_ACCURACY, l.getAccuracy());
    values.put(LocationEntry.COLUMN_NAME_SPEED, l.getSpeed());
    values.put(LocationEntry.COLUMN_NAME_BEARING, l.getBearing());
    values.put(LocationEntry.COLUMN_NAME_ALTITUDE, l.getAltitude());
    values.put(LocationEntry.COLUMN_NAME_RADIUS, l.getRadius());
    values.put(LocationEntry.COLUMN_NAME_LATITUDE, l.getLatitude());
    values.put(LocationEntry.COLUMN_NAME_LONGITUDE, l.getLongitude());
    values.put(LocationEntry.COLUMN_NAME_HAS_ACCURACY, l.hasAccuracy() ? 1 : 0);
    values.put(LocationEntry.COLUMN_NAME_HAS_SPEED, l.hasSpeed() ? 1 : 0);
    values.put(LocationEntry.COLUMN_NAME_HAS_BEARING, l.hasBearing() ? 1 : 0);
    values.put(LocationEntry.COLUMN_NAME_HAS_ALTITUDE, l.hasAltitude() ? 1 : 0);
    values.put(LocationEntry.COLUMN_NAME_HAS_RADIUS, l.hasRadius() ? 1 : 0);
    values.put(LocationEntry.COLUMN_NAME_LOCATION_PROVIDER, l.getLocationProvider());
    values.put(LocationEntry.COLUMN_NAME_VALID, l.isValid() ? 1 : 0);
    values.put(LocationEntry.COLUMN_NAME_BATCH_START_MILLIS, l.getBatchStartMillis());

    return values;
  }
}
