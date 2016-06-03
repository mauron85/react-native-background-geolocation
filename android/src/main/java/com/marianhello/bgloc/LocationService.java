/*
According to apache license

This is fork of christocracy cordova-plugin-background-geolocation plugin
https://github.com/christocracy/cordova-plugin-background-geolocation

This is a new class
*/

package com.marianhello.bgloc;

import android.app.Notification;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.RemoteException;
import android.os.AsyncTask;
import android.os.Build;
import android.support.v4.app.NotificationCompat;
import android.util.Log;

import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.DAOFactory;
import com.marianhello.bgloc.data.LocationDAO;
import com.marianhello.bgloc.HttpPostService;

import java.util.ArrayList;
import java.util.Random;

import org.json.JSONException;

public class LocationService extends Service {
    private static final String TAG = "LocationService";

    private LocationDAO dao;
    private Config config;
    private LocationProvider provider;

    /** Keeps track of all current registered clients. */
    ArrayList<Messenger> mClients = new ArrayList<Messenger>();

    /**
     * Command to the service to register a client, receiving callbacks
     * from the service.  The Message's replyTo field must be a Messenger of
     * the client where callbacks should be sent.
     */
    public static final int MSG_REGISTER_CLIENT = 1;

    /**
     * Command to the service to unregister a client, ot stop receiving callbacks
     * from the service.  The Message's replyTo field must be a Messenger of
     * the client as previously given with MSG_REGISTER_CLIENT.
     */
    public static final int MSG_UNREGISTER_CLIENT = 2;

    /**
     * Command ent by the service to
     * any registered clients with the new position.
     */
    public static final int MSG_LOCATION_UPDATE = 3;

    /**
     * Handler of incoming messages from clients.
     */
    class IncomingHandler extends Handler {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case MSG_REGISTER_CLIENT:
                    mClients.add(msg.replyTo);
                    break;
                case MSG_UNREGISTER_CLIENT:
                    mClients.remove(msg.replyTo);
                    break;
                default:
                    super.handleMessage(msg);
            }
        }
    }

    /**
     * Target we publish for clients to send messages to IncomingHandler.
     */
    final Messenger mMessenger = new Messenger(new IncomingHandler());

    /**
     * When binding to the service, we return an interface to our messenger
     * for sending messages to the service.
     */
    @Override
    public IBinder onBind(Intent intent) {
        return mMessenger.getBinder();
    }

    @Override
    public void onCreate() {
        super.onCreate();
        dao = (DAOFactory.createLocationDAO(this));
    }

    @Override
    public void onDestroy() {
        Log.w(TAG, "Destroying Location Service");
        provider.onDestroy();
//        stopForeground(true);
        super.onDestroy();
    }

    // @TargetApi(Build.VERSION_CODES.ICE_CREAM_SANDWICH)
    @Override
    public void onTaskRemoved(Intent rootIntent) {
        Log.d(TAG, "Task has been removed");
        if (config.getStopOnTerminate()) {
            Log.d(TAG, "Stopping self");
            stopSelf();
        } else {
            Log.d(TAG, "Continue running in background");
//            Intent intent = new Intent( this, DummyActivity.class );
//            intent.addFlags( Intent.FLAG_ACTIVITY_NEW_TASK );
//            startActivity(intent);
        }
        super.onTaskRemoved(rootIntent);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.i(TAG, "Received start id " + startId + ": " + intent);

        if (intent.hasExtra("config")) {
            config = (Config) intent.getParcelableExtra("config");
        } else {
            config = new Config();
        }

        LocationProviderFactory spf = new LocationProviderFactory(this);
        provider = spf.getInstance(config.getLocationProvider());

        if (config.getStartForeground()) {
            // Build a Notification required for running service in foreground.
            NotificationCompat.Builder builder = new NotificationCompat.Builder(this);
            builder.setContentTitle(config.getNotificationTitle());
            builder.setContentText(config.getNotificationText());
            if (config.getSmallNotificationIcon() != null) {
                builder.setSmallIcon(getPluginResource(config.getSmallNotificationIcon()));
            } else {
                builder.setSmallIcon(android.R.drawable.ic_menu_mylocation);
            }
            if (config.getLargeNotificationIcon() != null) {
                builder.setLargeIcon(BitmapFactory.decodeResource(getApplication().getResources(), getPluginResource(config.getLargeNotificationIcon())));
            }
            if (config.getNotificationIconColor() != null) {
                builder.setColor(this.parseNotificationIconColor(config.getNotificationIconColor()));
            }

            setClickEvent(builder);

            Notification notification = builder.build();
            notification.flags |= Notification.FLAG_ONGOING_EVENT | Notification.FLAG_FOREGROUND_SERVICE | Notification.FLAG_NO_CLEAR;
            startForeground(startId, notification);
        }

        provider.startRecording();

        //We want this service to continue running until it is explicitly stopped
        return START_REDELIVER_INTENT;
    }

    protected Integer getPluginResource(String resourceName) {
        return getApplication().getResources().getIdentifier(resourceName, "drawable", getApplication().getPackageName());
    }

    /**
     * Adds an onclick handler to the notification
     */
    protected NotificationCompat.Builder setClickEvent (NotificationCompat.Builder builder) {
        int requestCode = new Random().nextInt();
        Context context     = getApplicationContext();
        String packageName  = context.getPackageName();
        Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(packageName);
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        PendingIntent contentIntent = PendingIntent.getActivity(context, requestCode, launchIntent, PendingIntent.FLAG_CANCEL_CURRENT);

        return builder.setContentIntent(contentIntent);
    }

    private Integer parseNotificationIconColor(String color) {
        int iconColor = 0;
        if (color != null) {
            try {
                iconColor = Color.parseColor(color);
            } catch (IllegalArgumentException e) {
                Log.e(TAG, "couldn't parse color from android options");
            }
        }
        return iconColor;
    }

    public void startRecording() {
        provider.startRecording();
    }

    public void stopRecording() {
        provider.stopRecording();
    }

    public void handleLocation (BackgroundLocation location) {
        // Boolean shouldPersists = mClients.size() == 0;

        for (int i=mClients.size()-1; i>=0; i--) {
            try {
                Bundle bundle = new Bundle();
                bundle.putParcelable("location", location);
                Message msg = Message.obtain(null, MSG_LOCATION_UPDATE);
                msg.setData(bundle);
                mClients.get(i).send(msg);
            } catch (RemoteException e) {
                // The client is dead.  Remove it from the list;
                // we are going through the list from back to front
                // so this is safe to do inside the loop.
                mClients.remove(i);
                // shouldPersists = true;
            }
        }

        if (config.getUrl() != null) {
            postLocation(location);
        }

        if (config.isDebugging()) {
            BackgroundLocation cloned = location.makeClone();
            cloned.setDebug(true);
            persistLocation(cloned);
        }

        // if (shouldPersists) {
        //     Log.d(TAG, "Persisting location. Reason: Main activity was probably killed.");
        //     persistLocation(location);
        // }
    }

    public void persistLocation (BackgroundLocation location) {
        if (dao.persistLocation(location) > -1) {
            Log.d(TAG, "Persisted Location: " + location.toString());
        } else {
            Log.w(TAG, "Failed to persist location");
        }
    }

    public void postLocation(BackgroundLocation location) {
        PostLocationTask task = new LocationService.PostLocationTask();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
            task.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, location);
        }
        else {
            task.execute(location);
        }
    }

    /**
     * Forces the main activity to re-launch if it's unloaded.
     */
    private void forceMainActivityReload() {
        PackageManager pm = getPackageManager();
        Intent launchIntent = pm.getLaunchIntentForPackage(getApplicationContext().getPackageName());
        startActivity(launchIntent);
    }

    public Config getConfig() {
        return this.config;
    }

    public void setConfig(Config config) {
        this.config = config;
    }

    private class PostLocationTask extends AsyncTask<BackgroundLocation, Integer, Boolean> {

        @Override
        protected Boolean doInBackground(BackgroundLocation... locations) {
            Log.d(TAG, "Executing PostLocationTask#doInBackground");
            int count = locations.length;
            for (int i = 0; i < count; i++) {
                BackgroundLocation location = locations[i];
                Long locationId = location.getLocationId();
                try {
                    if (HttpPostService.postJSON(config.getUrl(), location.toJSONObject(), config.getHttpHeaders())) {
                        if (locationId != null) {
                            dao.deleteLocation(locationId);
                        }
                    } else {
                        if (locationId == null) {
                            persistLocation(location);
                        }
                    }
                } catch (JSONException e) {
                    Log.w(TAG, "location to json failed" + location.toString());
                }
            }

            return true;
        }

        @Override
        protected void onPostExecute(Boolean result) {
            Log.d(TAG, "PostLocationTask#onPostExecture");
        }
    }
}
