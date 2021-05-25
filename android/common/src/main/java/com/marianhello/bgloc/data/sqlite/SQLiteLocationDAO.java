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
import ru.andremoniy.sqlbuilder.SqlExpression;
import ru.andremoniy.sqlbuilder.SqlSelectStatement;

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

  /**
   * Get all locations that match whereClause
   *
   * @param whereClause
   * @param whereArgs
   * @return collection of locations
     */
  private Collection<BackgroundLocation> getLocations(String whereClause, String[] whereArgs) {
    Collection<BackgroundLocation> locations = new ArrayList<BackgroundLocation>();

    String[] columns = queryColumns();
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
    String whereClause = LocationEntry.COLUMN_NAME_STATUS + " <> ?";
    String[] whereArgs = { String.valueOf(BackgroundLocation.DELETED) };

    return getLocations(whereClause, whereArgs);
  }

  public BackgroundLocation getLocationById(long id) {
    String[] columns = queryColumns();
    String whereClause = LocationEntry._ID + " = ?";
    String[] whereArgs = { String.valueOf(id) };

    BackgroundLocation location = null;
    Cursor cursor = null;
    try {
      cursor = db.query(
              LocationEntry.TABLE_NAME,  // The table to query
              columns,                   // The columns to return
              whereClause,               // The columns for the WHERE clause
              whereArgs,                 // The values for the WHERE clause
              null,              // don't group the rows
              null,               // don't filter by row groups
              null               // The sort order
      );
      while (cursor.moveToNext()) {
        location = hydrate(cursor);
        if (!cursor.isLast()) {
          throw new RuntimeException("Location " + id + " is not unique");
        }
      }
    } finally {
      if (cursor != null) {
        cursor.close();
      }
    }

    return location;
  }

  public BackgroundLocation getFirstUnpostedLocation() {
    SqlSelectStatement subsql = new SqlSelectStatement();
    subsql.column(new SqlExpression(String.format("MIN(%s)", LocationEntry._ID)), LocationEntry._ID);
    subsql.from(LocationEntry.TABLE_NAME);
    subsql.where(LocationEntry.COLUMN_NAME_STATUS, SqlExpression.SqlOperatorEqualTo, BackgroundLocation.POST_PENDING);
    subsql.orderBy(LocationEntry.COLUMN_NAME_TIME);

    SqlSelectStatement sql = new SqlSelectStatement();
    sql.columns(queryColumns());
    sql.from(LocationEntry.TABLE_NAME);
    sql.where(LocationEntry._ID, SqlExpression.SqlOperatorEqualTo, subsql);

    BackgroundLocation location = null;
    Cursor cursor = null;
    try {
      cursor = db.rawQuery(sql.statement(), new String[]{});
      while (cursor.moveToNext()) {
        location = hydrate(cursor);
        if (!cursor.isLast()) {
          throw new RuntimeException("Expected single location");
        }
      }
    } finally {
      if (cursor != null) {
        cursor.close();
      }
    }

    return location;
  }

  public BackgroundLocation getNextUnpostedLocation(long fromId) {
    SqlSelectStatement subsql = new SqlSelectStatement();
    subsql.column(new SqlExpression(String.format("MIN(%s)", LocationEntry._ID)), LocationEntry._ID);
    subsql.from(LocationEntry.TABLE_NAME);
    subsql.where(LocationEntry.COLUMN_NAME_STATUS, SqlExpression.SqlOperatorEqualTo, BackgroundLocation.POST_PENDING);
    subsql.where(LocationEntry._ID, SqlExpression.SqlOperatorNotEqualTo, fromId);
    subsql.orderBy(LocationEntry.COLUMN_NAME_TIME);

    SqlSelectStatement sql = new SqlSelectStatement();
    sql.columns(queryColumns());
    sql.from(LocationEntry.TABLE_NAME);
    sql.where(LocationEntry._ID, SqlExpression.SqlOperatorEqualTo, subsql);

    BackgroundLocation location = null;
    Cursor cursor = null;
    try {
      cursor = db.rawQuery(sql.statement(), new String[]{});
      while (cursor.moveToNext()) {
        location = hydrate(cursor);
        if (!cursor.isLast()) {
          throw new RuntimeException("Expected single location");
        }
      }
    } finally {
      if (cursor != null) {
        cursor.close();
      }
    }

    return location;
  }

  public long getUnpostedLocationsCount() {
    String whereClause = SQLiteLocationContract.LocationEntry.COLUMN_NAME_STATUS + " = ?";
    String[] whereArgs = { String.valueOf(BackgroundLocation.POST_PENDING) };

    return DatabaseUtils.queryNumEntries(db, LocationEntry.TABLE_NAME, whereClause, whereArgs);
  }

  public long getLocationsForSyncCount(long millisSinceLastBatch) {
    String whereClause = TextUtils.join("", new String[]{
            SQLiteLocationContract.LocationEntry.COLUMN_NAME_STATUS + " = ? AND ( ",
            SQLiteLocationContract.LocationEntry.COLUMN_NAME_BATCH_START_MILLIS + " IS NULL OR ",
            SQLiteLocationContract.LocationEntry.COLUMN_NAME_BATCH_START_MILLIS + " < ? )",
    });
    String[] whereArgs = {
            String.valueOf(BackgroundLocation.SYNC_PENDING),
            String.valueOf(millisSinceLastBatch)
    };

    return DatabaseUtils.queryNumEntries(db, LocationEntry.TABLE_NAME, whereClause, whereArgs);
  }

  /**
   * Persist location into database
   *
   * @param location
   * @return rowId or -1 when error occured
   */
  public long persistLocation(BackgroundLocation location) {
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
  public long persistLocation(BackgroundLocation location, int maxRows) {
    if (maxRows == 0) {
      return -1;
    }

    String sql = null;
    Boolean shouldVacuum = false;

    long rowCount = DatabaseUtils.queryNumEntries(db, LocationEntry.TABLE_NAME);

    if (rowCount < maxRows) {
      ContentValues values = getContentValues(location);
      return db.insertOrThrow(LocationEntry.TABLE_NAME, LocationEntry.COLUMN_NAME_NULLABLE, values);
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

    // get oldest location id to be overwritten
    Cursor cursor = null;
    long locationId;
    try {
      cursor = db.query(
              LocationEntry.TABLE_NAME,
              new String[] { "min(" + LocationEntry._ID + ")" },
              TextUtils.join("", new String[]{
                      LocationEntry.COLUMN_NAME_TIME,
                      "= (SELECT min(",
                      LocationEntry.COLUMN_NAME_TIME,
                      ") FROM ",
                      LocationEntry.TABLE_NAME,
                      ")"
              }),
              null, null, null, null);
      cursor.moveToFirst();
      locationId = cursor.getLong(0);
    } finally {
      if (cursor != null) {
        cursor.close();
      }
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
            .append(LocationEntry.COLUMN_NAME_STATUS).append("= ?,")
            .append(LocationEntry.COLUMN_NAME_MOCK_FLAGS).append("= ?")
            .append(" WHERE ").append(LocationEntry._ID)
            .append("= ?")
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
            location.getStatus(),
            location.getMockFlags(),
            locationId
    });

    db.setTransactionSuccessful();
    db.endTransaction();

    if (shouldVacuum) { db.execSQL("VACUUM"); }

    return locationId;
  }

  /**
   * Delete location by given locationId
   *
   * Note: location is not actually deleted only flagged as non valid
   * @param locationId
   */
  public void deleteLocationById(long locationId) {
    if (locationId < 0) {
      return;
    }

    ContentValues values = new ContentValues();
    values.put(LocationEntry.COLUMN_NAME_STATUS, BackgroundLocation.DELETED);

    String whereClause = LocationEntry._ID + " = ?";
    String[] whereArgs = { String.valueOf(locationId) };

    db.update(LocationEntry.TABLE_NAME, values, whereClause, whereArgs);
  }

  public BackgroundLocation deleteFirstUnpostedLocation() {
    BackgroundLocation location = getFirstUnpostedLocation();
    deleteLocationById(location.getLocationId());

    return location;
  }

  public long persistLocationForSync(BackgroundLocation location, int maxRows) {
    Long locationId = location.getLocationId();

    if (locationId == null) {
      location.setStatus(BackgroundLocation.SYNC_PENDING);
      return persistLocation(location, maxRows);
    } else {
      ContentValues values = new ContentValues();
      values.put(LocationEntry.COLUMN_NAME_STATUS, BackgroundLocation.SYNC_PENDING);

      String whereClause = LocationEntry._ID + " = ?";
      String[] whereArgs = { String.valueOf(locationId) };

      db.update(LocationEntry.TABLE_NAME, values, whereClause, whereArgs);
      return locationId;
    }
  }

  public void updateLocationForSync(long locationId) {
    ContentValues values = new ContentValues();
    values.put(LocationEntry.COLUMN_NAME_STATUS, BackgroundLocation.SYNC_PENDING);

    String whereClause = LocationEntry._ID + " = ?";
    String[] whereArgs = { String.valueOf(locationId) };

    db.update(LocationEntry.TABLE_NAME, values, whereClause, whereArgs);
  }

  /**
   * Delete all locations
   *
   * Note: location are not actually deleted only flagged as non valid
   */
  public int deleteAllLocations() {
    ContentValues values = new ContentValues();
    values.put(LocationEntry.COLUMN_NAME_STATUS, BackgroundLocation.DELETED);

    return db.update(LocationEntry.TABLE_NAME, values, null, null);
  }

  /**
   * Delete all locations that are in post location queue
   *
   * Note: Instead of deleting, location status is changed so they can be still synced
   */
  public int deleteUnpostedLocations() {
    ContentValues values = new ContentValues();
    values.put(LocationEntry.COLUMN_NAME_STATUS, BackgroundLocation.SYNC_PENDING);

    String whereClause = LocationEntry.COLUMN_NAME_STATUS + " = ?";
    String[] whereArgs = { String.valueOf(BackgroundLocation.POST_PENDING) };

    return db.update(LocationEntry.TABLE_NAME, values, whereClause, whereArgs);
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
    l.setStatus(c.getInt(c.getColumnIndex(LocationEntry.COLUMN_NAME_STATUS)));
    l.setLocationId(c.getLong(c.getColumnIndex(LocationEntry._ID)));
    l.setMockFlags(c.getInt((c.getColumnIndex(LocationEntry.COLUMN_NAME_MOCK_FLAGS))));

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
    values.put(LocationEntry.COLUMN_NAME_STATUS, l.getStatus());
    values.put(LocationEntry.COLUMN_NAME_BATCH_START_MILLIS, l.getBatchStartMillis());
    values.put(LocationEntry.COLUMN_NAME_MOCK_FLAGS, l.getMockFlags());

    return values;
  }

  private String[] queryColumns() {
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
            LocationEntry.COLUMN_NAME_STATUS,
            LocationEntry.COLUMN_NAME_BATCH_START_MILLIS,
            LocationEntry.COLUMN_NAME_MOCK_FLAGS
    };

    return columns;
  }
}
