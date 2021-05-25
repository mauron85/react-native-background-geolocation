package com.marianhello.bgloc;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.support.test.InstrumentationRegistry;
import android.support.test.runner.AndroidJUnit4;
import android.support.test.filters.SmallTest;
import android.util.JsonReader;
import android.util.JsonToken;

import com.marianhello.bgloc.data.ArrayListLocationTemplate;
import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.HashMapLocationTemplate;
import com.marianhello.bgloc.data.LocationTemplate;
import com.marianhello.bgloc.data.LocationTemplateFactory;
import com.marianhello.bgloc.data.sqlite.SQLiteLocationDAO;
import com.marianhello.bgloc.data.sqlite.SQLiteOpenHelper;
import com.marianhello.bgloc.sync.BatchManager;

import junit.framework.Assert;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import static com.marianhello.bgloc.data.sqlite.SQLiteLocationContract.LocationEntry.SQL_DROP_LOCATION_TABLE;

/**
 * Created by finch on 22/07/16.
 */
@RunWith(AndroidJUnit4.class)
@SmallTest
public class BatchManagerTest {
    Context mContext;
    SQLiteOpenHelper mDbHelper;

    public void prepareDatabase() {
        SQLiteDatabase db = mDbHelper.getWritableDatabase();
        mDbHelper.execAndLogSql(db, SQL_DROP_LOCATION_TABLE);
        mDbHelper.onCreate(db);
    }

    @Before
    public void setUp() {
        mContext = InstrumentationRegistry.getTargetContext();
        mDbHelper = SQLiteOpenHelper.getHelper(mContext);
        prepareDatabase();
    }

    private List<BackgroundLocation> readLocationsArray(JsonReader reader) throws IOException {
        List<BackgroundLocation> locations = new ArrayList<BackgroundLocation>();
        reader.beginArray();
        while (reader.hasNext()) {
            BackgroundLocation l = new BackgroundLocation();
            reader.beginObject();
            while (reader.hasNext()) {
                String name = reader.nextName();
                if (name.equals("id")) {
                    l.setLocationId(reader.nextLong());
                } else if (name.equals("time")) {
                    l.setTime(reader.nextLong());
                } else if (name.equals("latitude")) {
                    l.setLatitude(reader.nextDouble());
                } else if (name.equals("longitude")) {
                    l.setLongitude(reader.nextDouble());
                } else if (name.equals("accuracy")) {
                    l.setAccuracy((float)reader.nextDouble());
                } else if (name.equals("speed")) {
                    l.setSpeed((float)reader.nextDouble());
                } else if (name.equals("bearing")) {
                    l.setBearing((float)reader.nextDouble());
                } else if (name.equals("altitude")) {
                    l.setAltitude(reader.nextDouble());
                } else if (name.equals("radius")) {
                    JsonToken token = reader.peek();
                    if (token != JsonToken.NULL) {
                        l.setRadius((float)reader.nextDouble());
                    } else {
                        reader.skipValue();
                    }
                } else if (name.equals("provider")) {
                    l.setProvider(reader.nextString());
                } else if (name.equals("locationProvider")) {
                    l.setLocationProvider(reader.nextInt());
                } else {
                    reader.skipValue();
                }
            }
            reader.endObject();
            locations.add(l);
        }
        reader.endArray();
        return locations;
    }

    @Test
    public void testCreateBatch() {
        SQLiteLocationDAO dao = new SQLiteLocationDAO(mDbHelper.getWritableDatabase());

        int i = 1;
        for (int j = i; j < 100; j++) {
            BackgroundLocation location = new BackgroundLocation();
            location.setTime(1000 + i);
            location.setLatitude(40.21 + i);
            location.setLongitude(23.45 + i);
            location.setAccuracy(200 +i);
            location.setAltitude(900 +i);
            location.setSpeed(20 + i);
            location.setBearing(2 + i);
            location.setProvider("test");
            location.setLocationProvider(1);
            if ((j % 3) == 0) {
                // exactly 33 locations (out of 99) should be eligible for sync for given batch id 1000
                location.setBatchStartMillis(1000L);
            } else if ((j % 2) == 0) {
                // exactly 33 locations as deleted
                location.setStatus(BackgroundLocation.DELETED);
            } else {
                location.setStatus(BackgroundLocation.SYNC_PENDING);
                i++;
            }
            dao.persistLocation(location);
        }

        List<BackgroundLocation> locations = null;
        BatchManager batchManager = new BatchManager(mContext);
        try {
            File batchFile = batchManager.createBatch(1000L, 0);
            JsonReader reader = new JsonReader(new FileReader(batchFile));
            locations = readLocationsArray(reader);
        } catch (Exception e) {
            Assert.fail(e.getMessage());
        }

        Assert.assertEquals(33, locations.size());
        i = 1;
        for (BackgroundLocation l : locations) {
            Assert.assertEquals(200 + i, l.getAccuracy(), 0);
            Assert.assertEquals(900 + i, l.getAltitude(), 0);
            Assert.assertEquals(2 + i, l.getBearing(), 0);
            Assert.assertEquals(40.21 + i, l.getLatitude(), 0);
            Assert.assertEquals(23.45 + i,l.getLongitude(), 0);
            Assert.assertEquals(20 + i, l.getSpeed(), 0);
            Assert.assertEquals("test", l.getProvider());
            Assert.assertEquals(1000 + i, l.getTime(), 0);
            i++;
        }
    }

    @Test
    public void testCreateBatchWithArrayListTemplate() {
        SQLiteLocationDAO dao = new SQLiteLocationDAO(mDbHelper.getWritableDatabase());

        for (int i = 1; i < 3; i++) {
            BackgroundLocation location = new BackgroundLocation();
            location.setTime(1000 * i);
            location.setLatitude(30.21 + i);
            location.setLongitude(13.45 + i);
            location.setBatchStartMillis(1000L);
            location.setIsFromMockProvider(false);
            location.setMockLocationsEnabled(true);
            location.setStatus(BackgroundLocation.SYNC_PENDING);
            dao.persistLocation(location);
        }


        ArrayList list = new ArrayList();
        list.add("@latitude");
        list.add("@longitude");
        list.add("foo");
        list.add("bar");
        list.add("@isFromMockProvider");
        list.add("@mockLocationsEnabled");

        LocationTemplate template = new ArrayListLocationTemplate(list);

        ArrayList<HashMap> locations = new ArrayList();
        BatchManager batchManager = new BatchManager(mContext);

        try {
            File batchFile = batchManager.createBatch(3000L, 0, template);
            JsonReader reader = new JsonReader(new FileReader(batchFile));

            reader.beginArray();
            while (reader.hasNext()) {
                HashMap hashLocation = new HashMap<String, Object>();
                reader.beginArray();
                hashLocation.put("latitude", reader.nextDouble());
                hashLocation.put("longitude", reader.nextDouble());
                hashLocation.put("foo", reader.nextString());
                hashLocation.put("bar", reader.nextString());
                hashLocation.put("isFromMockProvider", reader.nextBoolean());
                hashLocation.put("mockLocationsEnabled", reader.nextBoolean());
                reader.endArray();
                locations.add(hashLocation);
            }
            reader.endArray();
        } catch (Exception e) {
            Assert.fail(e.getMessage());
        }

        Assert.assertEquals(2, locations.size());
        int i = 1;
        for (HashMap l : locations) {
            Assert.assertEquals(30.21 + i, (Double) l.get("latitude"), 0);
            Assert.assertEquals(13.45 + i, (Double) l.get("longitude"), 0);
            Assert.assertEquals("foo", (String) l.get("foo"));
            Assert.assertEquals("bar", (String) l.get("bar"));
            Assert.assertEquals(false, l.get("isFromMockProvider"));
            Assert.assertEquals(true, l.get("mockLocationsEnabled"));
            i++;
        }
    }

    @Test
    public void testCreateBatchWithMapHashTemplate() {
        SQLiteLocationDAO dao = new SQLiteLocationDAO(mDbHelper.getWritableDatabase());

        for (int i = 1; i < 3; i++) {
            BackgroundLocation location = new BackgroundLocation();
            location.setTime(1000 * i);
            location.setLatitude(30.21 + i);
            location.setLongitude(13.45 + i);
            location.setBatchStartMillis(1000L);
            location.setIsFromMockProvider(true);
            location.setMockLocationsEnabled(false);
            location.setStatus(BackgroundLocation.SYNC_PENDING);
            dao.persistLocation(location);
        }

        HashMap map = new HashMap<String, String>();
        map.put("lat", "@latitude");
        map.put("lon", "@longitude");
        map.put("foo", "bar");
        map.put("pretzels", 123);
        map.put("isFromMockProvider", "@isFromMockProvider");
        map.put("mockLocationsEnabled", "@mockLocationsEnabled");
        LocationTemplate template = new HashMapLocationTemplate(map);

        ArrayList<HashMap> locations = new ArrayList();
        BatchManager batchManager = new BatchManager(mContext);

        try {
            File batchFile = batchManager.createBatch(3000L, 0, template);
            JsonReader reader = new JsonReader(new FileReader(batchFile));

            reader.beginArray();
            while (reader.hasNext()) {
                HashMap hashLocation = new HashMap<String, Object>();
                reader.beginObject();
                while (reader.hasNext()) {
                    String name = reader.nextName();
                    if ("lat".equals(name)) {
                        hashLocation.put(name, reader.nextDouble());
                    } else if ("lon".equals(name)) {
                        hashLocation.put(name, reader.nextDouble());
                    } else if ("foo".equals(name)) {
                        hashLocation.put(name, reader.nextString());
                    } else if ("isFromMockProvider".equals(name)) {
                        hashLocation.put(name, reader.nextBoolean());
                    } else if ("mockLocationsEnabled".equals(name)) {
                        hashLocation.put(name, reader.nextBoolean());
                    } else {
                        reader.skipValue();
                    }
                }
                reader.endObject();
                locations.add(hashLocation);
            }
            reader.endArray();
        } catch (Exception e) {
            Assert.fail(e.getMessage());
        }

        Assert.assertEquals(2, locations.size());
        int i = 1;
        for (HashMap l : locations) {
            Assert.assertEquals(30.21 + i, (Double) l.get("lat"), 0);
            Assert.assertEquals(13.45 + i, (Double) l.get("lon"), 0);
            Assert.assertEquals("bar", (String) l.get("foo"));
            Assert.assertEquals(true, l.get("isFromMockProvider"));
            Assert.assertEquals(false, l.get("mockLocationsEnabled"));
            i++;
        }
    }

    @Test
    public void testSetBatchCompleted() {
        SQLiteLocationDAO dao = new SQLiteLocationDAO(mDbHelper.getWritableDatabase());

        int i = 1;
        BackgroundLocation location;
        for (int j = i; j < 100; j++) {
            location = new BackgroundLocation();
            location.setProvider("test");
            location.setTime(1000 + i);
            location.setLatitude(40.21 + i);
            location.setLongitude(23.45 + i);
            location.setAccuracy(200 +i);
            location.setAltitude(900 +i);
            location.setSpeed(20 + i);
            location.setBearing(2 + i);
            location.setProvider("test");
            location.setLocationProvider(1);
            if ((j % 99) == 0) {
                location.setBatchStartMillis(1000L);
            } else if ((j % 2) == 0) {
                location.setStatus(BackgroundLocation.DELETED);
            } else {
                location.setStatus(BackgroundLocation.SYNC_PENDING);
                i++;
            }
            dao.persistLocation(location);
        }

        // distribution of location: 49 of invalid, (49 + 1 in sync) of valid, 1 in sync

        Assert.assertEquals(99, dao.getAllLocations().size());
        Assert.assertEquals(50, dao.getValidLocations().size());
        Assert.assertEquals(49, dao.getLocationsForSyncCount(1000L));
        BatchManager batchManager = new BatchManager(mContext);
        try {
            batchManager.createBatch(1000L, 0);
            batchManager.setBatchCompleted(1000L);
            Assert.assertEquals(0, dao.getValidLocations().size());
            Assert.assertEquals(0, dao.getLocationsForSyncCount(2000L));
        } catch (Exception e) {
            Assert.fail(e.getMessage());
        }
    }

    @Test
    public void testCreateBatchWithNestedTemplate() throws JSONException, IOException {
        SQLiteLocationDAO dao = new SQLiteLocationDAO(mDbHelper.getWritableDatabase());
        ArrayList<BackgroundLocation> testLocations = new ArrayList<BackgroundLocation>();

        for (int i = 0; i < 3; i++) {
            BackgroundLocation location = new BackgroundLocation();
            location.setProvider("test");
            location.setTime(1000 * i);
            location.setAltitude(999 + i);
            location.setLatitude(30.21 + i);
            location.setLongitude(13.45 + i);
            location.setAccuracy(9);
            location.setSpeed(66);
            location.setBearing(99);
            location.setBatchStartMillis(1000L);
            location.setIsFromMockProvider(true);
            location.setMockLocationsEnabled(false);
            location.setStatus(BackgroundLocation.SYNC_PENDING);
            dao.persistLocation(location);
            testLocations.add(location);
        }

        JSONObject templateJSON = new JSONObject(
                "{\"data\":{\"Id-Number\":\"@id\"," +
                        "\"Provider-String\":\"@provider\"," +
                        "\"Time-Number\":\"@time\"," +
                        "\"Altitude-Number\":\"@altitude\"," +
                        "\"Latitude-Number\":\"@latitude\"," +
                        "\"Longitude-Number\":\"@longitude\"," +
                        "\"Foo-String\":\"bar\"," +
                        "\"LocationProvider-Number\":\"@locationProvider\"," +
                        "\"Accuracy-Number\":\"@accuracy\"," +
                        "\"Speed-Number\":\"@speed\"," +
                        "\"Bearing-Number\":\"@bearing\"," +
                        "\"FooNumber-Number\":111}" +
                        "}"
        );
        LocationTemplate template = LocationTemplateFactory.fromJSON(templateJSON);

        BatchManager batchManager = new BatchManager(mContext);
        File batchFile = batchManager.createBatch(3000L, 0, template);

        ArrayList<HashMap<String, Object>> hashLocations = new ArrayList();
        JsonReader reader = new JsonReader(new FileReader(batchFile));
        reader.beginArray();
        while (reader.hasNext()) {
            reader.beginObject();
            if (reader.hasNext() && "data".equals(reader.nextName())) {
                HashMap hashLocation = new HashMap<String, Object>();
                reader.beginObject();
                while (reader.hasNext()) {
                    String name = reader.nextName();
                    if (name.endsWith("-String")) {
                        hashLocation.put(name, reader.nextString());
                    } else if (name.endsWith("-Number")) {
                        hashLocation.put(name, reader.nextDouble());
                    } else if (name.endsWith("-Boolean")) {
                        hashLocation.put(name, reader.nextBoolean());
                    } else {
                        reader.skipValue();
                    }
                }
                reader.endObject();
                hashLocations.add(hashLocation);
            }
            reader.endObject();
        }
        reader.endArray();

        Assert.assertEquals(3, hashLocations.size());
        int i = 0;
        for (HashMap l : hashLocations) {
            Assert.assertEquals("test", l.get("Provider-String"));
            Assert.assertEquals(0, (Double) l.get("LocationProvider-Number"), 0);
            Assert.assertEquals(9, (Double) l.get("Accuracy-Number"), 0);
            Assert.assertEquals(99, (Double) l.get("Bearing-Number"), 0);
            Assert.assertEquals(66, (Double) l.get("Speed-Number"), 0);
            Assert.assertEquals(testLocations.get(i).getAltitude(), (Double) l.get("Altitude-Number"), 0);
            Assert.assertEquals(testLocations.get(i).getLatitude(), (Double) l.get("Latitude-Number"), 0);
            Assert.assertEquals(testLocations.get(i).getLongitude(), (Double) l.get("Longitude-Number"), 0);
            Assert.assertEquals(testLocations.get(i).getTime(), (Double) l.get("Time-Number"), 0);
            Assert.assertEquals("bar", l.get("Foo-String"));
            Assert.assertEquals(111, (Double) l.get("FooNumber-Number"), 0);
            i++;
        }
    }

    @Test
    public void testCreateBatchWithNestedListTemplate() throws JSONException, IOException {
        SQLiteLocationDAO dao = new SQLiteLocationDAO(mDbHelper.getWritableDatabase());
        ArrayList<BackgroundLocation> testLocations = new ArrayList<BackgroundLocation>();

        for (int i = 0; i < 3; i++) {
            BackgroundLocation location = new BackgroundLocation();
            location.setProvider("test");
            location.setTime(1000 * i);
            location.setAltitude(999 + i);
            location.setLatitude(30.21 + i);
            location.setLongitude(13.45 + i);
            location.setAccuracy(9);
            location.setSpeed(66);
            location.setBearing(99);
            location.setBatchStartMillis(1000L);
            location.setIsFromMockProvider(true);
            location.setMockLocationsEnabled(false);
            location.setStatus(BackgroundLocation.SYNC_PENDING);
            dao.persistLocation(location);
            testLocations.add(location);
        }

        JSONArray templateJSON = new JSONArray(
                "[\"@id\"," +
                    "{" +
                        "\"Provider-String\":\"@provider\"," +
                        "\"Time-Number\":\"@time\"," +
                        "\"Altitude-Number\":\"@altitude\"," +
                        "\"Latitude-Number\":\"@latitude\"," +
                        "\"Longitude-Number\":\"@longitude\"," +
                        "\"Foo-String\":\"bar\"," +
                        "\"LocationProvider-Number\":\"@locationProvider\"," +
                        "\"Accuracy-Number\":\"@accuracy\"," +
                        "\"Speed-Number\":\"@speed\"," +
                        "\"Bearing-Number\":\"@bearing\"," +
                        "\"FooNumber-Number\":111" +
                        "}]"
        );
        LocationTemplate template = LocationTemplateFactory.fromJSON(templateJSON);
        BatchManager batchManager = new BatchManager(mContext);
        File batchFile = batchManager.createBatch(3000L, 0, template);

        ArrayList<HashMap<String, Object>> hashLocations = new ArrayList();
        JsonReader reader = new JsonReader(new FileReader(batchFile));
        reader.beginArray();
        while (reader.hasNext()) {
            reader.beginArray();
            while(reader.hasNext()) {
                HashMap hashLocation = new HashMap<String, Object>();
                hashLocation.put("id", reader.nextInt());
                reader.beginObject();
                while(reader.hasNext()) {
                    String name = reader.nextName();
                    if (name.endsWith("-String")) {
                        hashLocation.put(name, reader.nextString());
                    } else if (name.endsWith("-Number")) {
                        hashLocation.put(name, reader.nextDouble());
                    } else if (name.endsWith("-Boolean")) {
                        hashLocation.put(name, reader.nextBoolean());
                    } else {
                        reader.skipValue();
                    }
                }
                reader.endObject();
                hashLocations.add(hashLocation);
            }
            reader.endArray();
        }

        Assert.assertEquals(3, hashLocations.size());
        int i = 0;
        for (HashMap l : hashLocations) {
            Assert.assertEquals(i+1, l.get("id"));
            Assert.assertEquals("test", l.get("Provider-String"));
            Assert.assertEquals(0, (Double) l.get("LocationProvider-Number"), 0);
            Assert.assertEquals(9, (Double) l.get("Accuracy-Number"), 0);
            Assert.assertEquals(99, (Double) l.get("Bearing-Number"), 0);
            Assert.assertEquals(66, (Double) l.get("Speed-Number"), 0);
            Assert.assertEquals(testLocations.get(i).getAltitude(), (Double) l.get("Altitude-Number"), 0);
            Assert.assertEquals(testLocations.get(i).getLatitude(), (Double) l.get("Latitude-Number"), 0);
            Assert.assertEquals(testLocations.get(i).getLongitude(), (Double) l.get("Longitude-Number"), 0);
            Assert.assertEquals(testLocations.get(i).getTime(), (Double) l.get("Time-Number"), 0);
            Assert.assertEquals("bar", l.get("Foo-String"));
            Assert.assertEquals(111, (Double) l.get("FooNumber-Number"), 0);
            i++;
        }

    }

    @Test
    public void testBatchWithNulls() throws JSONException, IOException {

        BackgroundLocation location = new BackgroundLocation();
        location.setBatchStartMillis(1000L);
        location.setStatus(BackgroundLocation.SYNC_PENDING);
        SQLiteLocationDAO dao = new SQLiteLocationDAO(mDbHelper.getWritableDatabase());
        dao.persistLocation(location);

        JSONObject templateJSON = new JSONObject("{\"Nullable\":null, \"NullRadius\": \"@radius\"}");
        LocationTemplate template = LocationTemplateFactory.fromJSON(templateJSON);

        BatchManager batchManager = new BatchManager(mContext);
        File batchFile = batchManager.createBatch(3000L, 0, template);

        HashMap hashLocation = new HashMap<String, Object>();
        JsonReader reader = new JsonReader(new FileReader(batchFile));
        reader.beginArray();
        while (reader.hasNext()) {
            reader.beginObject();
            while(reader.hasNext()) { ;
                hashLocation.put(reader.nextName(), null);
                reader.nextNull();
            }
            reader.endObject();
        }
        reader.endArray();

        Assert.assertTrue(hashLocation.containsKey("Nullable"));
        Assert.assertTrue(hashLocation.containsKey("NullRadius"));
    }

    public static String slurp (final File file) throws IOException {
        StringBuilder result = new StringBuilder();
        BufferedReader reader = null;
        try {
            reader = new BufferedReader(new FileReader(file));
            char[] buf = new char[1024];
            int r = 0;
            while ((r = reader.read(buf)) != -1) {
                result.append(buf, 0, r);
            }
        }
        finally {
            reader.close();
        }

        return result.toString();
    }
}
