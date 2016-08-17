package com.marianhello.bgloc.sync;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.text.TextUtils;
import android.util.JsonWriter;

import com.marianhello.bgloc.data.sqlite.SQLiteLocationContract;
import com.marianhello.bgloc.data.sqlite.SQLiteOpenHelper;
import com.marianhello.logging.LoggerManager;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;

/**
 * Created by finch on 20/07/16.
 */
public class BatchManager {
    private Context context;
    private org.slf4j.Logger log;

    public BatchManager(Context context) {
        log = LoggerManager.getLogger(BatchManager.class);
        this.context = context;
    }

    public File createBatch(Long batchStartMillis, Integer syncThreshold) throws IOException {
        log.info("Creating batch {}", batchStartMillis);

        SQLiteOpenHelper helper = SQLiteOpenHelper.getHelper(context);
        SQLiteDatabase db = helper.getWritableDatabase();

        String[] columns = {
                SQLiteLocationContract.LocationEntry._ID,
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_PROVIDER,
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_TIME,
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_LATITUDE,
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_LONGITUDE,
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_ACCURACY,
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_SPEED,
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_BEARING,
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_ALTITUDE,
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_RADIUS,
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_ACCURACY,
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_SPEED,
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_BEARING,
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_ALTITUDE,
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_RADIUS,
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_LOCATION_PROVIDER
        };

        String whereClause = TextUtils.join("", new String[]{
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_VALID + " = ? AND ( ",
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_BATCH_START_MILLIS + " IS NULL OR ",
                SQLiteLocationContract.LocationEntry.COLUMN_NAME_BATCH_START_MILLIS + " < ? )",
        });
        String[] whereArgs = { "1", String.valueOf(batchStartMillis) };
        String groupBy = null;
        String having = null;
        String orderBy = SQLiteLocationContract.LocationEntry.COLUMN_NAME_TIME + " ASC";

        Cursor cursor = null;
        JsonWriter writer = null;

        try {
            db.beginTransactionNonExclusive();

            cursor = db.query(
                    SQLiteLocationContract.LocationEntry.TABLE_NAME,  // The table to query
                    columns,                   // The columns to return
                    whereClause,               // The columns for the WHERE clause
                    whereArgs,                 // The values for the WHERE clause
                    groupBy,                   // don't group the rows
                    having,                    // don't filter by row groups
                    orderBy                    // The sort order
            );

            if (cursor.getCount() < syncThreshold) {
                return null;
            }

            File file = File.createTempFile("locations", ".json");
            FileOutputStream fs = new FileOutputStream(file);
            writer = new JsonWriter(new OutputStreamWriter(fs, "UTF-8"));
            writer.beginArray();

            while (cursor.moveToNext()) {
                writer.beginObject();
                String provider = cursor.getString(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_PROVIDER));
                Long time = cursor.getLong(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_TIME));
                Double latitude = cursor.getDouble(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_LATITUDE));
                Double longitude = cursor.getDouble(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_LONGITUDE));
                Integer locationProvider = cursor.getInt(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_LOCATION_PROVIDER));

                if (provider != null) writer.name("provider").value(provider);
                if (time != null) writer.name("time").value(time);
                if (latitude != null) writer.name("latitude").value(latitude);
                if (longitude != null) writer.name("longitude").value(longitude);
                if (cursor.getInt(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_ACCURACY)) == 1) {
                    writer.name("accuracy").value(cursor.getFloat(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_ACCURACY)));
                }
                if (cursor.getInt(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_SPEED)) == 1) {
                    writer.name("speed").value(cursor.getFloat(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_SPEED)));
                }
                if (cursor.getInt(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_BEARING)) == 1) {
                    writer.name("bearing").value(cursor.getFloat(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_BEARING)));
                }
                if (cursor.getInt(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_ALTITUDE)) == 1) {
                    writer.name("altitude").value(cursor.getDouble(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_ALTITUDE)));
                }
                if (cursor.getInt(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_RADIUS)) == 1) {
                    writer.name("radius").value(cursor.getFloat(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_RADIUS)));
                }
                if (locationProvider != null) writer.name("locationProvider").value(locationProvider);
                writer.endObject();
            }
            writer.endArray();
            writer.close();
            fs.close();

            // set batchStartMillis for all synced locations
            ContentValues values = new ContentValues();
            values.put(SQLiteLocationContract.LocationEntry.COLUMN_NAME_BATCH_START_MILLIS, batchStartMillis);
            db.update(SQLiteLocationContract.LocationEntry.TABLE_NAME, values, whereClause, whereArgs);

            db.setTransactionSuccessful();

            log.info("Batch file: {} created successfully", file.getName());

            return file;
        } finally {
            if (cursor != null) {
                cursor.close();
            }
            if (writer != null) {
                writer.close();
            }
            db.endTransaction();
        }
    }

    public void setBatchCompleted(Long batchId) {
        SQLiteOpenHelper helper = SQLiteOpenHelper.getHelper(context);
        SQLiteDatabase db = helper.getWritableDatabase();

        String whereClause = SQLiteLocationContract.LocationEntry.COLUMN_NAME_BATCH_START_MILLIS + " = ?";
        String[] whereArgs = { String.valueOf(batchId) };

        ContentValues values = new ContentValues();
        values.put(SQLiteLocationContract.LocationEntry.COLUMN_NAME_VALID, 0);
        db.update(SQLiteLocationContract.LocationEntry.TABLE_NAME, values, whereClause, whereArgs);
    }
}
