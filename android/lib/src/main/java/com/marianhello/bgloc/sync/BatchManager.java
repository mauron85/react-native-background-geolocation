package com.marianhello.bgloc.sync;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.text.TextUtils;
import android.util.JsonWriter;

import com.marianhello.bgloc.data.ArrayListLocationTemplate;
import com.marianhello.bgloc.data.HashMapLocationTemplate;
import com.marianhello.bgloc.data.LinkedHashSetLocationTemplate;
import com.marianhello.bgloc.data.LocationTemplate;
import com.marianhello.bgloc.data.LocationTemplateFactory;
import com.marianhello.bgloc.data.sqlite.SQLiteLocationContract;
import com.marianhello.bgloc.data.sqlite.SQLiteOpenHelper;
import com.marianhello.logging.LoggerManager;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

/**
 * Created by finch on 20/07/16.
 */
public class BatchManager {
    private Context context;
    private org.slf4j.Logger logger;

    public BatchManager(Context context) {
        logger = LoggerManager.getLogger(BatchManager.class);
        this.context = context;
    }

    private File createBatchFromTemplate(Long batchStartMillis, Integer syncThreshold, LocationTemplate template) throws IOException {
        logger.info("Creating batch {}", batchStartMillis);

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
                long locationId = cursor.getLong(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry._ID));
                int locationProvider = cursor.getInt(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_LOCATION_PROVIDER));
                String provider = cursor.getString(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_PROVIDER));
                double latitude = cursor.getDouble(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_LATITUDE));
                double longitude = cursor.getDouble(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_LONGITUDE));
                long time = cursor.getLong(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_TIME));
                ;
                float accuracy = cursor.getFloat(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_ACCURACY));
                float speed = cursor.getFloat(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_SPEED));
                float bearing = cursor.getFloat(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_BEARING));
                double altitude = cursor.getDouble(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_ALTITUDE));
                float radius = cursor.getFloat(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_RADIUS));
                boolean hasAccuracy = cursor.getInt(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_ACCURACY)) == 1;
                boolean hasAltitude = cursor.getInt(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_ALTITUDE)) == 1;
                boolean hasSpeed = cursor.getInt(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_SPEED)) == 1;
                boolean hasBearing = cursor.getInt(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_BEARING)) == 1;
                boolean hasRadius = cursor.getInt(cursor.getColumnIndex(SQLiteLocationContract.LocationEntry.COLUMN_NAME_HAS_RADIUS)) == 1;

                if (template instanceof HashMapLocationTemplate) {
                    writer.beginObject();
                    HashMapLocationTemplate hashTemplate = (HashMapLocationTemplate) template;
                    Iterator it = hashTemplate.iterator();
                    while (it.hasNext()) {
                        Map.Entry<String, String> pair = (Map.Entry) it.next();
                        String key = pair.getKey();
                        String value = String.valueOf(pair.getValue());

                        if ("@id".equals(value)) {
                            writer.name(key).value(locationId);
                        } else if ("@locationProvider".equals(value)) {
                            writer.name(key).value(locationProvider);
                        } else if ("@provider".equals(value)) {
                            writer.name(key).value(provider);
                        } else if ("@time".equals(value)) {
                            writer.name(key).value(time);
                        } else if ("@latitude".equals(value)) {
                            writer.name(key).value(latitude);
                        } else if ("@longitude".equals(value)) {
                            writer.name(key).value(longitude);
                        } else if ("@accuracy".equals(value)) {
                            if (hasAccuracy) {
                                writer.name(key).value(accuracy);
                            } else {
                                writer.name(key).nullValue();
                            }
                        } else if ("@speed".equals(value)) {
                            if (hasSpeed) {
                                writer.name(key).value(speed);
                            } else {
                                writer.name(key).nullValue();
                            }
                        } else if ("@bearing".equals(value)) {
                            if (hasBearing) {
                                writer.name(key).value(bearing);
                            } else {
                                writer.name(key).nullValue();
                            }
                        } else if ("@altitude".equals(value)) {
                            if (hasAltitude) {
                                writer.name(key).value(altitude);
                            } else {
                                writer.name(key).nullValue();
                            }
                        } else if ("@radius".equals(value)) {
                            if (hasRadius) {
                                writer.name(key).value(radius);
                            } else {
                                writer.name(key).nullValue();
                            }
                        } else {
                            writer.name(key).value(value);
                        }
                    }
                    writer.endObject();
                } else if (template instanceof ArrayListLocationTemplate) {
                    ArrayListLocationTemplate hashTemplate = (ArrayListLocationTemplate) template;
                    writer.beginArray();
                    Iterator it = hashTemplate.iterator();
                    while (it.hasNext()) {
                        String key = it.next().toString();
                        if ("@id".equals(key)) {
                            writer.value(locationId);
                        } else if ("@locationProvider".equals(key)) {
                            writer.value(locationProvider);
                        } else if ("@provider".equals(key)) {
                            writer.value(provider);
                        } else if ("@time".equals(key)) {
                            writer.value(time);
                        } else if ("@latitude".equals(key)) {
                            writer.value(latitude);
                        } else if ("@longitude".equals(key)) {
                            writer.value(longitude);
                        } else if ("@accuracy".equals(key)) {
                            if (hasAccuracy) {
                                writer.value(accuracy);
                            } else {
                                writer.nullValue();
                            }
                        } else if ("@speed".equals(key)) {
                            if (hasSpeed) {
                                writer.value(speed);
                            } else {
                                writer.nullValue();
                            }
                        } else if ("@bearing".equals(key)) {
                            if (hasBearing) {
                                writer.value(bearing);
                            } else {
                                writer.nullValue();
                            }
                        } else if ("@altitude".equals(key)) {
                            if (hasAltitude) {
                                writer.value(altitude);
                            } else {
                                writer.nullValue();
                            }
                        } else if ("@radius".equals(key)) {
                            if (hasRadius) {
                                writer.value(radius);
                            } else {
                                writer.nullValue();
                            }
                        } else {
                            writer.value(key);
                        }
                    }
                    writer.endArray();
                }
            }
            writer.endArray();
            writer.close();
            fs.close();

            // set batchStartMillis for all synced locations
            ContentValues values = new ContentValues();
            values.put(SQLiteLocationContract.LocationEntry.COLUMN_NAME_BATCH_START_MILLIS, batchStartMillis);
            db.update(SQLiteLocationContract.LocationEntry.TABLE_NAME, values, whereClause, whereArgs);

            db.setTransactionSuccessful();

            logger.info("Batch file: {} created successfully", file.getName());

            return file;
        } finally {
            db.endTransaction();

            if (cursor != null) {
                cursor.close();
            }
            if (writer != null) {
                writer.close();
            }
        }
    }

    public File createBatch(Long batchStartMillis, Integer syncThreshold, LocationTemplate template) throws IOException {
        LocationTemplate tpl;
        if (template != null) {
            tpl = template;
        } else {
            tpl = LocationTemplateFactory.getDefault();
        }
        return createBatchFromTemplate(batchStartMillis, syncThreshold, tpl);
    }

    public File createBatch(Long batchStartMillis, Integer syncThreshold) throws IOException {
        return createBatch(batchStartMillis, syncThreshold, null);
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
