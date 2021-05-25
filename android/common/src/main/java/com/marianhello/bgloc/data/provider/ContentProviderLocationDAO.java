package com.marianhello.bgloc.data.provider;

import android.content.ContentProviderOperation;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.text.TextUtils;

import com.marianhello.bgloc.ResourceResolver;
import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.LocationDAO;
import com.marianhello.bgloc.data.sqlite.SQLiteLocationContract;
import com.marianhello.bgloc.data.sqlite.SQLiteLocationContract.LocationEntry;
import com.marianhello.logging.LoggerManager;

import java.util.ArrayList;
import java.util.Collection;

import ru.andremoniy.sqlbuilder.SqlExpression;
import ru.andremoniy.sqlbuilder.SqlSelectStatement;

public class ContentProviderLocationDAO implements LocationDAO {
    private org.slf4j.Logger logger;
    private ContentResolver mResolver;
    private Uri mContentUri;
    private String mAuthority;

    public ContentProviderLocationDAO(Context context) {
        logger = LoggerManager.getLogger(ContentProviderLocationDAO.class);
        ResourceResolver resourceResolver = ResourceResolver.newInstance(context);
        mAuthority = resourceResolver.getAuthority();
        mContentUri = LocationContentProvider.getContentUri(mAuthority);
        mResolver = context.getApplicationContext().getContentResolver();
    }

    /**
     * Get ocations that match whereClause
     *
     * @param whereClause
     * @param whereArgs
     * @return collection of locations
     */
    private Collection<BackgroundLocation> getLocations(String whereClause, String[] whereArgs) {
        Collection<BackgroundLocation> locations = new ArrayList<BackgroundLocation>();
        Cursor cursor = null;

        try {
            cursor = mResolver.query(
                    mContentUri,
                    null,
                    whereClause,
                    whereArgs,
                    LocationEntry.COLUMN_NAME_TIME + " ASC"
            );
            while (cursor.moveToNext()) {
                locations.add(BackgroundLocation.fromCursor(cursor));
            }
        } finally {
            if (cursor != null) {
                cursor.close();
            }
        }

        return locations;
    }

    @Override
    public Collection<BackgroundLocation> getAllLocations() {
        return getLocations(null, null);
    }

    @Override
    public Collection<BackgroundLocation> getValidLocations() {
        String whereClause = LocationEntry.COLUMN_NAME_STATUS + " <> ?";
        String[] whereArgs = { String.valueOf(BackgroundLocation.DELETED) };

        return getLocations(whereClause, whereArgs);
    }

    @Override
    public BackgroundLocation getLocationById(long id) {
        BackgroundLocation location = null;

        Cursor cursor = null;
        try {
            cursor = mResolver.query(
                    LocationContentProvider.buildUriWithId(mAuthority, id),
                    null,
                    null,
                    null,
                    null
            );
            while (cursor.moveToNext()) {
                location = BackgroundLocation.fromCursor(cursor);
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

    public int getLocationsCount() {
        Cursor cursor = mResolver.query(
                mContentUri,
                null,
                null,
                null,
                ""
        );

        int count = cursor.getCount();
        cursor.close();
        return count;
    }

    @Override
    public BackgroundLocation getFirstUnpostedLocation() {
        SqlSelectStatement subsql = new SqlSelectStatement();
        subsql.column(new SqlExpression(String.format("MIN(%s)", LocationEntry._ID)), LocationEntry._ID);
        subsql.from(LocationEntry.TABLE_NAME);
        subsql.where(LocationEntry.COLUMN_NAME_STATUS, SqlExpression.SqlOperatorEqualTo, BackgroundLocation.POST_PENDING);
        subsql.orderBy(LocationEntry.COLUMN_NAME_TIME);

        String substmt = subsql.statement();
        substmt = com.marianhello.utils.TextUtils.removeLastChar(substmt, ";");

        BackgroundLocation location = null;
        Cursor cursor = null;
        try {
            cursor = mResolver.query(
                    mContentUri,
                    null,
                    LocationEntry._ID + " = (" + substmt + ")",
                    null,
                    null
                    );

            while (cursor.moveToNext()) {
                location = BackgroundLocation.fromCursor(cursor);
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

    @Override
    public BackgroundLocation getNextUnpostedLocation(long fromId) {
        SqlSelectStatement subsql = new SqlSelectStatement();
        subsql.column(new SqlExpression(String.format("MIN(%s)", LocationEntry._ID)), LocationEntry._ID);
        subsql.from(LocationEntry.TABLE_NAME);
        subsql.where(LocationEntry.COLUMN_NAME_STATUS, SqlExpression.SqlOperatorEqualTo, BackgroundLocation.POST_PENDING);
        subsql.where(LocationEntry._ID, SqlExpression.SqlOperatorNotEqualTo, fromId);
        subsql.orderBy(LocationEntry.COLUMN_NAME_TIME);

        String substmt = subsql.statement();
        substmt = com.marianhello.utils.TextUtils.removeLastChar(substmt, ";");

        BackgroundLocation location = null;
        Cursor cursor = null;
        try {
            cursor = mResolver.query(
                    mContentUri,
                    null,
                    LocationEntry._ID + " = (" + substmt + ")",
                    null,
                    null
            );

            while (cursor.moveToNext()) {
                location = BackgroundLocation.fromCursor(cursor);
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

    @Override
    public long getUnpostedLocationsCount() {
        String whereClause = SQLiteLocationContract.LocationEntry.COLUMN_NAME_STATUS + " = ?";
        String[] whereArgs = { String.valueOf(BackgroundLocation.POST_PENDING) };

        Cursor cursor = mResolver.query(
                mContentUri,
                null,
                whereClause,
                whereArgs,
                null);

        int count = cursor.getCount();
        cursor.close();
        return count;
    }

    @Override
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

        Cursor cursor = mResolver.query(
                mContentUri,
                null,
                whereClause,
                whereArgs,
                null);

        int count = cursor.getCount();
        cursor.close();
        return count;
    }

    public Uri getOldestLocationUri() {
        Cursor cursor = null;
        try {
            cursor = mResolver.query(
                    mContentUri,
                    new String[]{"min(" + LocationEntry._ID + ")"},
                    TextUtils.join("", new String[]{
                            LocationEntry.COLUMN_NAME_TIME,
                            "= (SELECT min(",
                            LocationEntry.COLUMN_NAME_TIME,
                            ") FROM ",
                            LocationEntry.TABLE_NAME,
                            ")"
                    }),
                    null,
                    null
            );

            cursor.moveToFirst();
            return LocationContentProvider.buildUriWithId(mAuthority, cursor.getLong(0));
        } finally {
            if (cursor != null) {
                cursor.close();
            }
        }
    }

    /**
     * Persist location into database
     *
     * @param location
     * @return rowId or -1 when error occured
     */
    @Override
    public long persistLocation(BackgroundLocation location) {
        Uri locationUri = mResolver.insert(mContentUri, location.toContentValues());
        return Integer.valueOf(locationUri.getLastPathSegment());
    }

    @Override
    public long persistLocation(BackgroundLocation location, int maxRows) {
        if (maxRows == 0) {
            return -1;
        }

        long rowCount = getLocationsCount();

        if (rowCount < maxRows) {
            return persistLocation(location);
        }

        ArrayList<ContentProviderOperation> operations = new ArrayList<ContentProviderOperation>();

        // TODO: move this logic as separate action somewhere else
        // TODO: add db vaccum
        if (rowCount > maxRows) {
            // delete some locations to reduce their count to maxRows
            String selection = new StringBuilder()
                    .append(LocationEntry._ID)
                    .append(" IN (SELECT ").append(LocationEntry._ID)
                    .append(" FROM ").append(LocationEntry.TABLE_NAME)
                    .append(" ORDER BY ").append(LocationEntry.COLUMN_NAME_TIME)
                    .append(" LIMIT ?)")
                    .toString();

            operations.add(
                    ContentProviderOperation.newDelete(mContentUri)
                    .withSelection(selection, new String[] {(String.valueOf(rowCount - maxRows))})
                    .build()
            );
        }

        operations.add(
                ContentProviderOperation.newUpdate(getOldestLocationUri())
                    .withValues(location.toContentValues())
                    .build()
        );

        try {
            mResolver.applyBatch(mAuthority, operations);
        } catch (Exception e) {
            logger.error("Error persisting location (maxRows: {}): {}", maxRows, e.getMessage());
            return -1;
        }

        return 0;
    }

    @Override
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

            mResolver.update(mContentUri, values, whereClause, whereArgs);
            return locationId;
        }
    }

    @Override
    public void updateLocationForSync(long locationId) {
        ContentValues values = new ContentValues();
        values.put(LocationEntry.COLUMN_NAME_STATUS, BackgroundLocation.SYNC_PENDING);

        String whereClause = LocationEntry._ID + " = ?";
        String[] whereArgs = { String.valueOf(locationId) };

        mResolver.update(mContentUri, values, whereClause, whereArgs);
    }

    @Override
    public void deleteLocationById(long locationId) {
        mResolver.delete(LocationContentProvider.buildUriWithId(mAuthority, locationId), null, null);
    }

    @Override
    public BackgroundLocation deleteFirstUnpostedLocation() {
        BackgroundLocation location = getFirstUnpostedLocation();
        deleteLocationById(location.getLocationId());

        return location;
    }

    @Override
    public int deleteAllLocations() {
        return mResolver.delete(mContentUri, null, null);
    }

    @Override
    public int deleteUnpostedLocations() {
        ContentValues values = new ContentValues();
        values.put(LocationEntry.COLUMN_NAME_STATUS, BackgroundLocation.SYNC_PENDING);

        String whereClause = LocationEntry.COLUMN_NAME_STATUS + " = ?";
        String[] whereArgs = { String.valueOf(BackgroundLocation.POST_PENDING) };

        return mResolver.update(mContentUri, values, whereClause, whereArgs);
    }
}
