package com.marianhello.bgloc.sync;

import android.content.ContentProviderOperation;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.net.Uri;
import android.text.TextUtils;
import android.util.JsonWriter;

import com.marianhello.bgloc.ResourceResolver;
import com.marianhello.bgloc.data.AbstractLocationTemplate;
import com.marianhello.bgloc.data.ArrayListLocationTemplate;
import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.HashMapLocationTemplate;
import com.marianhello.bgloc.data.LocationTemplate;
import com.marianhello.bgloc.data.LocationTemplateFactory;
import com.marianhello.bgloc.data.provider.LocationContentProvider;
import com.marianhello.bgloc.data.sqlite.SQLiteLocationContract;
import com.marianhello.bgloc.data.sqlite.SQLiteLocationContract.LocationEntry;
import com.marianhello.bgloc.data.sqlite.SQLiteOpenHelper;
import com.marianhello.logging.LoggerManager;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
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

    private Uri getLocationContentUri() {
        ResourceResolver resourceResolver = ResourceResolver.newInstance(context);
        String authority = resourceResolver.getAuthority();
        return LocationContentProvider.getContentUri(authority);
    }

    private File createBatchFromTemplate(Long batchStartMillis, Integer syncThreshold, LocationTemplate template) throws IOException {
        logger.info("Creating batch {}", batchStartMillis);

        ContentResolver resolver = context.getContentResolver();
        Uri contentUri = getLocationContentUri();

        String whereClause = TextUtils.join("", new String[]{
                LocationEntry.COLUMN_NAME_STATUS + " = ? AND ( ",
                LocationEntry.COLUMN_NAME_BATCH_START_MILLIS + " IS NULL OR ",
                LocationEntry.COLUMN_NAME_BATCH_START_MILLIS + " < ? )",
        });
        String[] whereArgs = {
                String.valueOf(BackgroundLocation.SYNC_PENDING),
                String.valueOf(batchStartMillis)
        };

        Cursor cursor = null;
        LocationWriter writer = null;

        try {
            cursor = resolver.query(
                    contentUri,
                    null,
                    whereClause,
                    whereArgs,
                    LocationEntry.COLUMN_NAME_TIME + " ASC"

            );

            if (cursor.getCount() < syncThreshold) {
                return null;
            }

            File file = File.createTempFile("locations", ".json");
            FileOutputStream fs = new FileOutputStream(file);
            writer = new LocationWriter(fs, template);

            writer.beginArray();
            while (cursor.moveToNext()) {
                BackgroundLocation location = BackgroundLocation.fromCursor(cursor);
                writer.write(location);
            }

            writer.endArray();
            writer.close();
            fs.close();

            // set batchStartMillis for all synced locations
            ContentValues values = new ContentValues();
            values.put(LocationEntry.COLUMN_NAME_BATCH_START_MILLIS, batchStartMillis);
            resolver.update(contentUri, values, whereClause, whereArgs);

            logger.info("Batch file: {} created successfully", file.getName());

            return file;
        } finally {
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
        ContentResolver resolver = context.getApplicationContext().getContentResolver();
        Uri contentUri = getLocationContentUri();

        String whereClause = LocationEntry.COLUMN_NAME_BATCH_START_MILLIS + " = ?";
        String[] whereArgs = { String.valueOf(batchId) };

        ContentValues values = new ContentValues();
        values.put(LocationEntry.COLUMN_NAME_STATUS, BackgroundLocation.DELETED);
        resolver.update(contentUri, values, whereClause, whereArgs);
    }

    private static class LocationTemplateWriter {
        private BackgroundLocation location;
        private JsonWriter writer;

        public LocationTemplateWriter(JsonWriter writer, BackgroundLocation location) {
            this.writer = writer;
            this.location = location;
        }

        private void writeValue(Object value) throws IOException {
            if (value instanceof String ) {
                writer.value((String) value);
            } else if (value instanceof Map) {
                writeMap((Map) value);
            } else if (value instanceof List) {
                writeList((List) value);
            } else if (Integer.class.isInstance(value)) {
                writer.value((Integer) value);
            } else if (Double.class.isInstance(value)) {
                writer.value((Double) value);
            } else if (Float.class.isInstance(value)) {
                writer.value((Float) value);
            } else if (Long.class.isInstance(value)) {
                writer.value((Long) value);
            } else if (Boolean.class.isInstance(value)) {
                writer.value((Boolean) value);
            } else if (value == JSONObject.NULL) {
                writer.nullValue();
            } else {
                writer.value(String.valueOf(value));
            }
        }

        public void writeMap(Map values) throws IOException {
            writer.beginObject();
            Iterator<?> it = values.entrySet().iterator();
            while (it.hasNext()) {
                Map.Entry<String, Object> pair = (Map.Entry) it.next();
                String key = pair.getKey();
                Object value = pair.getValue();
                Object locationValue = null;
                if (value instanceof String) {
                    locationValue = location.getValueForKey((String)value);
                }
                writer.name(key);
                writeValue(locationValue != null ? locationValue : value);
            }
            writer.endObject();
        }

        public void writeList(List values) throws IOException {
            writer.beginArray();
            Iterator<?> it = values.iterator();
            while (it.hasNext()) {
                Object value = it.next();
                Object locationValue = null;
                if (value instanceof  String) {
                    locationValue = location.getValueForKey((String) value);
                }
                writeValue(locationValue != null ? locationValue : value);
            }
            writer.endArray();
        }
    }

    private static class LocationWriter {
        private JsonWriter writer = null;
        private LocationTemplate template;

        public LocationWriter(FileOutputStream fos, LocationTemplate template) throws IOException {
            writer = new JsonWriter(new OutputStreamWriter(fos, "UTF-8"));
            this.template = template;
        }

        public void beginArray() throws IOException {
            writer.beginArray();
        }

        public void endArray() throws IOException {
            writer.endArray();
        }

        public void close() throws IOException {
            writer.close();
        }

        public void write(BackgroundLocation location) throws IOException {
            LocationTemplateWriter writer = new LocationTemplateWriter(this.writer, location);
            if (template instanceof HashMapLocationTemplate) {
                HashMapLocationTemplate hashTemplate = (HashMapLocationTemplate) template;
                writer.writeMap(hashTemplate.toMap());
            } else if (template instanceof ArrayListLocationTemplate) {
                ArrayListLocationTemplate listTemplate = (ArrayListLocationTemplate) template;
                writer.writeList(listTemplate.toList());
            }
        }
    }
}
