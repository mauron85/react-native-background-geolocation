package com.marianhello.bgloc.data.provider;

import android.content.ContentProvider;
import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.ContentValues;
import android.content.Context;
import android.content.UriMatcher;
import android.database.Cursor;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteQueryBuilder;
import android.net.Uri;
import android.text.TextUtils;

import com.marianhello.bgloc.ResourceResolver;
import com.marianhello.bgloc.data.sqlite.SQLiteLocationContract.LocationEntry;
import com.marianhello.bgloc.data.sqlite.SQLiteOpenHelper;

/**
 * Content provider implementation based on
 * https://shellmonger.com/2017/06/28/android-notes-app-content-providers/
 */
public class LocationContentProvider extends ContentProvider {

    /**
     * Creates a UriMatcher for matching the path elements for this content provider
     */
    private static final UriMatcher sUriMatcher = new UriMatcher(UriMatcher.NO_MATCH);

    /**
     * The code for the UriMatch matching all notes
     */
    private static final int ALL_ITEMS = 10;

    /**
     * The code for the UriMatch matching a single note
     */
    private static final int ONE_ITEM = 20;

    /**
     * The database helper for this content provider
     */
    private SQLiteOpenHelper mDatabaseHelper;

    /*
     * Initialize the UriMatcher with the URIs that this content provider handles
     *
     * All paths added to the UriMatcher have a corresponding code to return when a match is
     * found. The code passed into the constructor of UriMatcher here represents the code to
     * return for the root URI. It's common to use NO_MATCH as the code for this case.
     */
    private static void initialize(String authority) {

        /* This URI is content://com.example.location/location/ */
        sUriMatcher.addURI(
                authority,
                LocationEntry.TABLE_NAME,
                ALL_ITEMS);


        /*
         * This URI would look something like content://com.example.location/location/1
         * The "/#" signifies to the UriMatcher that if TABLE_NAME is followed by ANY number,
         * that it should return the ONE_ITEM code
         */
        sUriMatcher.addURI(
                authority,
                LocationEntry.TABLE_NAME + "/#",
                ONE_ITEM);
    }

    /**
     * Part of the Content Provider interface.  The system calls onCreate() when it starts up
     * the provider.  You should only perform fast-running initialization tasks in this method.
     * Defer database creation and data loading until the provider actually receives a request
     * for the data.  This runs on the UI thread.
     *
     * @return true if the provider was successfully loaded; false otherwise
     */
    @Override
    public boolean onCreate() {
        Context context = getContext();
        ResourceResolver resourceResolver = ResourceResolver.newInstance(getContext());
        initialize(resourceResolver.getAuthority());
        mDatabaseHelper = new SQLiteOpenHelper(context);
        return true;
    }

    /**
     * The content provider must return the content type for its supported URIs.  The supported
     * URIs are defined in the UriMatcher
     *
     * As we don't export this content provider, we return null here.
     *
     * @param uri the URI for typing
     * @return the type of the URI
     */
    @Override
    public String getType(Uri uri) {
        return null;
    }

    /**
     * Handles query requests from clients. We will use this method to query for all
     * of our location data as well as to query for the specific location record.
     *
     * @param uri           The URI to query
     * @param projection    The list of columns to put into the cursor. If null, all columns are
     *                      included.
     * @param selection     A selection criteria to apply when filtering rows. If null, then all
     *                      rows are included.
     * @param selectionArgs You may include ?s in selection, which will be replaced by
     *                      the values from selectionArgs, in order that they appear in the
     *                      selection.
     * @param sortOrder     How the rows in the cursor should be sorted.
     * @return A Cursor containing the results of the query. In our implementation,
     */
    @Override
    public Cursor query(
            Uri uri,
            String[] projection,
            String selection,
            String[] selectionArgs,
            String sortOrder) {

        int uriType = sUriMatcher.match(uri);
        SQLiteDatabase db = mDatabaseHelper.getWritableDatabase();
        SQLiteQueryBuilder queryBuilder = new SQLiteQueryBuilder();

        switch (uriType) {
            /*
             * When sUriMatcher's match method is called with a URI that looks EXACTLY like this
             *
             *      content://com.example.location/location
             *
             * sUriMatcher's match method will return the code that indicates to us that we need
             * to return all of the records in our location table.
             *
             * In this case, we want to return a cursor that contains every record
             * in our location table.
             */
            case ALL_ITEMS:
                queryBuilder.setTables(LocationEntry.TABLE_NAME);
                if (TextUtils.isEmpty(sortOrder)) {
                    sortOrder = LocationEntry.COLUMN_NAME_TIME + " ASC";
                }
                break;


            /*
             * When sUriMatcher's match method is called with a URI that looks something like this
             *
             *      content://com.example.location/location/2
             *
             * sUriMatcher's match method will return the code that indicates to us that we need
             * to return the location for a particular id. The id in this code is encoded in
             * int and is at the very end of the URI (2) and can be accessed
             * programmatically using Uri's getLastPathSegment method.
             *
             * In this case, we want to return a cursor that contains one row of location data for
             * a particular date.
             */
            case ONE_ITEM:
                queryBuilder.setTables(LocationEntry.TABLE_NAME);
                queryBuilder.appendWhere(LocationEntry._ID + " = " + uri.getLastPathSegment());
                break;

            default:
                throw new IllegalArgumentException("Unsupported URI: " + uri);
        }

        Cursor cursor = queryBuilder.query(db, projection, selection, selectionArgs, null, null, sortOrder);
        cursor.setNotificationUri(getContext().getContentResolver(), uri);
        return cursor;
    }

    /**
     * Insert a new record into the database.
     *
     * @param uri the base URI to insert at (must be a directory-based URI)
     * @param values the values to be inserted
     * @return the URI of the inserted item
     */
    @Override
    public Uri insert(Uri uri, ContentValues values) {
        int uriType = sUriMatcher.match(uri);
        switch (uriType) {
            case ALL_ITEMS:
                SQLiteDatabase db = mDatabaseHelper.getWritableDatabase();
                long id = db.insert(
                        LocationEntry.TABLE_NAME,
                        null,
                        values);
                if (id > 0) {
                    Uri item = ContentUris.withAppendedId(uri, id);
                    notifyAllListeners(item);
                    return item;
                }

                throw new SQLException("Error inserting for URI " + uri + " result:" + id);
            default:
                throw new IllegalArgumentException("Unsupported URI: " + uri);
        }
    }

    /**
     * Delete one or more records from the SQLite database.
     *
     * @param uri the URI of the record(s) to delete
     * @param selection A WHERE clause to use for the deletion
     * @param selectionArgs Any arguments to replace the ? in the selection
     * @return the number of rows deleted.
     */
    @Override
    public int delete(Uri uri, String selection, String[] selectionArgs) {
        int uriType = sUriMatcher.match(uri);
        int rows;
        SQLiteDatabase db = mDatabaseHelper.getWritableDatabase();
        switch (uriType) {
            case ALL_ITEMS:
                rows = db.delete(
                        LocationEntry.TABLE_NAME,  // The table name
                        selection, selectionArgs); // The WHERE clause
                break;
            case ONE_ITEM:
                String where = LocationEntry._ID + " = " + uri.getLastPathSegment();
                if (!TextUtils.isEmpty(selection)) {
                    where += " AND " + selection;
                }
                rows = db.delete(
                        LocationEntry.TABLE_NAME,  // The table name
                        where, selectionArgs);     // The WHERE clause
                break;
            default:
                throw new IllegalArgumentException("Unsupported URI: " + uri);
        }
        if (rows > 0) {
            notifyAllListeners(uri);
        }
        return rows;
    }

    @Override
    public int update(
            Uri uri,
            ContentValues values,
            String selection,
            String[] selectionArgs) {
        int uriType = sUriMatcher.match(uri);
        int rows;
        SQLiteDatabase db = mDatabaseHelper.getWritableDatabase();
        switch (uriType) {
            case ALL_ITEMS:
                rows = db.update(
                        LocationEntry.TABLE_NAME,  // The table name
                        values,                    // The values to replace
                        selection, selectionArgs); // The WHERE clause
                break;
            case ONE_ITEM:
                String where = LocationEntry._ID + " = " + uri.getLastPathSegment();
                if (!TextUtils.isEmpty(selection)) {
                    where += " AND " + selection;
                }
                rows = db.update(
                        LocationEntry.TABLE_NAME,  // The table name
                        values,                    // The values to replace
                        where, selectionArgs);     // The WHERE clause
                break;
            default:
                throw new IllegalArgumentException("Unsupported URI: " + uri);
        }
        if (rows > 0) {
            notifyAllListeners(uri);
        }
        return rows;
    }

    /**
     * Notify all listeners that the specified URI has changed
     * @param uri the URI that changed
     */
    private void notifyAllListeners(Uri uri) {
        ContentResolver resolver = getContext().getContentResolver();
        if (resolver != null) {
            resolver.notifyChange(uri, null);
        }
    }

    /**
     * The base CONTENT_URI used to query the Location table from the content provider
     */
    public static Uri getBaseContentUri(String authority) {
        return Uri.parse("content://" + authority);
    }

    /**
     * The content URI for this table
     */
    public static Uri getContentUri(String authority) {
        return getBaseContentUri(authority).buildUpon()
                .appendPath(LocationEntry.TABLE_NAME)
                .build();
    }

    /**
     * Builds a URI that adds the task _ID to the end of the location content URI path.
     * This is used to query details about a single location entry by _ID. This is what we
     * use for the detail view query.
     *
     * @param authority The authority of the locations content provider
     * @param id Unique id pointing to that row
     * @return Uri to query details about a single location entry
     */
    public static Uri buildUriWithId(String authority, long id) {
        return getContentUri(authority).buildUpon()
                .appendPath(Long.toString(id))
                .build();
    }
}

