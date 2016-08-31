/*
According to apache license

This is fork of christocracy cordova-plugin-background-geolocation plugin
https://github.com/christocracy/cordova-plugin-background-geolocation

This is a new class
*/

package com.marianhello.bgloc;

import android.accounts.Account;
import android.app.Notification;
import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.database.SQLException;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.IBinder;
import android.os.Looper;
import android.os.Message;
import android.os.Messenger;
import android.os.RemoteException;
import android.support.v4.app.NotificationCompat;

import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.ConfigurationDAO;
import com.marianhello.bgloc.data.DAOFactory;
import com.marianhello.bgloc.data.LocationDAO;
import com.marianhello.bgloc.sync.AccountHelper;
import com.marianhello.bgloc.sync.AuthenticatorService;
import com.marianhello.bgloc.sync.SyncService;
import com.marianhello.logging.LoggerManager;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.net.HttpURLConnection;
import java.util.ArrayList;

public class LocationService extends Service {

    /** Keeps track of all current registered clients. */
    ArrayList<Messenger> mClients = new ArrayList<Messenger>();

    /**
     * Command sent by the service to
     * any registered clients with error.
     */
    public static final int MSG_ERROR = 1;

    /**
     * Command to the service to register a client, receiving callbacks
     * from the service.  The Message's replyTo field must be a Messenger of
     * the client where callbacks should be sent.
     */
    public static final int MSG_REGISTER_CLIENT = 2;

    /**
     * Command to the service to unregister a client, ot stop receiving callbacks
     * from the service.  The Message's replyTo field must be a Messenger of
     * the client as previously given with MSG_REGISTER_CLIENT.
     */
    public static final int MSG_UNREGISTER_CLIENT = 3;

    /**
     * Command sent by the service to
     * any registered clients with the new position.
     */
    public static final int MSG_LOCATION_UPDATE = 4;

    /**
     * Command sent by the service to
     * any registered clients whenever the devices enters "stationary-mode"
     */
    public static final int MSG_ON_STATIONARY = 5;


    /**
     * Command sent by the service to
     * any registered clients whenever the clients want to change provider operation mode
     */
    public static final int MSG_SWITCH_MODE = 6;


    /** background operation mode of location provider */
    public static final int BACKGROUND_MODE = 0;

    /** foreground operation mode of location provider */
    public static final int FOREGROUND_MODE = 1;

    private static final int ONE_MINUTE = 1000 * 60;
    private static final int FIVE_MINUTES = 1000 * 60 * 5;

    private LocationDAO dao;
    private Config config;
    private LocationProvider provider;
    private Account syncAccount;
    private Boolean hasConnectivity = true;
    private BackgroundLocation lastLocation;

    private org.slf4j.Logger log;

    private volatile HandlerThread handlerThread;
    private ServiceHandler serviceHandler;

    private class ServiceHandler extends Handler {
        public ServiceHandler(Looper looper) {
            super(looper);
        }

        @Override
        public void handleMessage(Message msg) {
        }
    }

    /**
     * Handler of incoming messages from clients.
     */
    private class IncomingHandler extends Handler {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case MSG_REGISTER_CLIENT:
                    mClients.add(msg.replyTo);
                    break;
                case MSG_UNREGISTER_CLIENT:
                    mClients.remove(msg.replyTo);
                    break;
                case MSG_SWITCH_MODE:
                    switchMode(msg.arg1);
                    break;
                default:
                    super.handleMessage(msg);
            }
        }
    }

    /**
     * Target we publish for clients to send messages to IncomingHandler.
     */
    final Messenger messenger = new Messenger(new IncomingHandler());

    /**
     * When binding to the service, we return an interface to our messenger
     * for sending messages to the service.
     */
    @Override
    public IBinder onBind(Intent intent) {
        return messenger.getBinder();
    }

    @Override
    public void onCreate() {
        super.onCreate();
        log = LoggerManager.getLogger(LocationService.class);
        log.info("Creating LocationService");

        // An Android handler thread internally operates on a looper.
        handlerThread = new HandlerThread("LocationService.HandlerThread");
        handlerThread.start();
        // An Android service handler is a handler running on a specific background thread.
        serviceHandler = new ServiceHandler(handlerThread.getLooper());

        dao = (DAOFactory.createLocationDAO(this));
        syncAccount = AccountHelper.CreateSyncAccount(this,
                AuthenticatorService.getAccount(getStringResource(Config.ACCOUNT_TYPE_RESOURCE)));

        registerReceiver(connectivityChangeReceiver, new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION));
    }

    @Override
    public void onDestroy() {
        log.info("Destroying LocationService");
        provider.onDestroy();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            handlerThread.quitSafely();
        } else {
            handlerThread.quit(); //sorry
        }
        unregisterReceiver(connectivityChangeReceiver);
        super.onDestroy();
    }

    @Override
    public void onTaskRemoved(Intent rootIntent) {
        log.debug("Task has been removed");
        if (config.getStopOnTerminate()) {
            log.info("Stopping self");
            stopSelf();
        } else {
            log.info("Continue running in background");
        }
        super.onTaskRemoved(rootIntent);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        log.info("Received start startId: {} intent: {}", startId, intent);

        if (provider != null) {
            provider.onDestroy();
        }

        if (intent == null) {
            //service has been probably restarted so we need to load config from db
            ConfigurationDAO dao = DAOFactory.createConfigurationDAO(this);
            try {
                config = dao.retrieveConfiguration();
            } catch (JSONException e) {
                log.error("Config exception: {}", e.getMessage());
                config = new Config(); //using default config
            }
        } else {
            if (intent.hasExtra("config")) {
                config = intent.getParcelableExtra("config");
            } else {
                config = new Config(); //using default config
            }
        }

        log.debug("Will start service with: {}", config.toString());

        LocationProviderFactory spf = new LocationProviderFactory(this);
        provider = spf.getInstance(config.getLocationProvider());

        if (config.getStartForeground()) {
            // Build a Notification required for running service in foreground.
            NotificationCompat.Builder builder = new NotificationCompat.Builder(this);
            builder.setContentTitle(config.getNotificationTitle());
            builder.setContentText(config.getNotificationText());
            if (config.getSmallNotificationIcon() != null) {
                builder.setSmallIcon(getDrawableResource(config.getSmallNotificationIcon()));
            } else {
                builder.setSmallIcon(android.R.drawable.ic_menu_mylocation);
            }
            if (config.getLargeNotificationIcon() != null) {
                builder.setLargeIcon(BitmapFactory.decodeResource(getApplication().getResources(), getDrawableResource(config.getLargeNotificationIcon())));
            }
            if (config.getNotificationIconColor() != null) {
                builder.setColor(this.parseNotificationIconColor(config.getNotificationIconColor()));
            }

            // Add an onclick handler to the notification
            Context context = getApplicationContext();
            String packageName = context.getPackageName();
            Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(packageName);
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            PendingIntent contentIntent = PendingIntent.getActivity(context, 0, launchIntent, PendingIntent.FLAG_CANCEL_CURRENT);
            builder.setContentIntent(contentIntent);

            Notification notification = builder.build();
            notification.flags |= Notification.FLAG_ONGOING_EVENT | Notification.FLAG_FOREGROUND_SERVICE | Notification.FLAG_NO_CLEAR;
            startForeground(startId, notification);
        }

        provider.startRecording();

        //We want this service to continue running until it is explicitly stopped
        return START_STICKY;
    }

    protected int getAppResource(String name, String type) {
        return getApplication().getResources().getIdentifier(name, type, getApplication().getPackageName());
    }

    protected Integer getDrawableResource(String resourceName) {
        return getAppResource(resourceName, "drawable");
    }

    protected String getStringResource(String name) {
        return getApplication().getString(getAppResource(name, "string"));
    }

    private Integer parseNotificationIconColor(String color) {
        int iconColor = 0;
        if (color != null) {
            try {
                iconColor = Color.parseColor(color);
            } catch (IllegalArgumentException e) {
                log.error("Couldn't parse color from android options");
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


    /**
     * Handle location from location location provider
     *
     * All locations updates are recorded in local db at all times.
     * Also location is also send to all messenger clients.
     *
     * If option.url is defined, each location is also immediately posted.
     * If post is successful, the location is deleted from local db.
     * All failed to post locations are coalesced and send in some time later in one single batch.
     * Batch sync takes place only when number of failed to post locations reaches syncTreshold.
     *
     * If only option.syncUrl is defined, locations are send only in single batch,
     * when number of locations reaches syncTreshold.
     *
     * @param location
     * @param PROVIDER_ID
     */
    public void handleLocation(BackgroundLocation location) {
        log.debug("New location {}", location.toString());

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            // we do check only of API level >= 17 because in lower version it does more harm than good
            if (location.isBetterLocationThan(lastLocation) == false) {
                log.debug("Previous location: [{} acc={} t={}] is better than current",
                        lastLocation.getProvider(), lastLocation.getAccuracy(), lastLocation.getTime());
                return;
            }
        }

        location.setBatchStartMillis(System.currentTimeMillis() + ONE_MINUTE); // prevent sync of not yet posted location
        persistLocation(location);

        if (config.hasUrl() || config.hasSyncUrl()) {
            Long locationsCount = dao.locationsForSyncCount(System.currentTimeMillis());
            log.debug("Location to sync: {} threshold: {}", locationsCount, config.getSyncThreshold());
            if (locationsCount >= config.getSyncThreshold()) {
                log.debug("Attempt to sync locations: {} threshold: {}", locationsCount, config.getSyncThreshold());
                SyncService.sync(syncAccount, getStringResource(Config.CONTENT_AUTHORITY_RESOURCE));
            }
        }

        if (hasConnectivity && config.hasUrl()) {
            postLocationAsync(location);
        }

        Bundle bundle = new Bundle();
        bundle.putParcelable("location", location);
        Message msg = Message.obtain(null, MSG_LOCATION_UPDATE);
        msg.setData(bundle);

        sendClientMessage(msg);

        lastLocation = location;
    }

    public void handleStationary(BackgroundLocation location) {
        log.debug("New stationary {}", location.toString());

        Bundle bundle = new Bundle();
        bundle.putParcelable("location", location);
        Message msg = Message.obtain(null, MSG_ON_STATIONARY);
        msg.setData(bundle);

        sendClientMessage(msg);
    }

    public void switchMode(int mode) {
        // TODO: implement
    }

    public void sendClientMessage(Message msg) {
        for (int i = mClients.size() - 1; i >= 0; i--) {
            try {
                mClients.get(i).send(msg);
            } catch (RemoteException e) {
                // The client is dead.  Remove it from the list;
                // we are going through the list from back to front
                // so this is safe to do inside the loop.
                mClients.remove(i);
            }
        }
    }

    @Override
    public Intent registerReceiver(BroadcastReceiver receiver, IntentFilter filter) {
        return super.registerReceiver(receiver, filter, null, serviceHandler);
    }

    @Override
    public void unregisterReceiver (BroadcastReceiver receiver) {
        super.unregisterReceiver(receiver);
    }

    public void handleError(JSONObject error) {
        Bundle bundle = new Bundle();
        bundle.putString("error", error.toString());
        Message msg = Message.obtain(null, MSG_ERROR);
        msg.setData(bundle);

        sendClientMessage(msg);
    }

    // method will mutate location
    public Long persistLocation (BackgroundLocation location) {
        Long locationId = -1L;
        try {
            locationId = dao.persistLocationWithLimit(location, config.getMaxLocations());
            location.setLocationId(locationId);
            log.debug("Persisted location: {}", location.toString());
        } catch (SQLException e) {
            log.error("Failed to persist location: {} error: {}", location.toString(), e.getMessage());
        }

        return locationId;
    }

    public void postLocation(BackgroundLocation location) {
        PostLocationTask task = new LocationService.PostLocationTask();
        task.doInBackground(location);
    }

    public void postLocationAsync(BackgroundLocation location) {
        PostLocationTask task = new LocationService.PostLocationTask();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
            task.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, location);
        }
        else {
            task.execute(location);
        }
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
            log.debug("Executing PostLocationTask#doInBackground");
            JSONArray jsonLocations = new JSONArray();
            for (BackgroundLocation location : locations) {
                try {
                    JSONObject jsonLocation = location.toJSONObject();
                    jsonLocations.put(jsonLocation);
                } catch (JSONException e) {
                    log.warn("Location to json failed: {}", location.toString());
                    return false;
                }
            }

            String url = config.getUrl();
            log.debug("Posting json to url: {} headers: {}", url, config.getHttpHeaders());
            int responseCode;

            try {
                responseCode = HttpPostService.postJSON(url, jsonLocations, config.getHttpHeaders());
            } catch (Exception e) {
                hasConnectivity = isNetworkAvailable();
                log.warn("Error while posting locations: {}", e.getMessage());
                return false;
            }

            if (responseCode != HttpURLConnection.HTTP_OK) {
                log.warn("Server error while posting locations responseCode: {}", responseCode);
                return false;
            }

            for (BackgroundLocation location : locations) {
                Long locationId = location.getLocationId();
                if (locationId != null) {
                    dao.deleteLocation(locationId);
                }
            }

            return true;
        }
    }

    /**
     * Broadcast receiver which detects connectivity change condition
     */
    private BroadcastReceiver connectivityChangeReceiver = new BroadcastReceiver() {
        private static final String LOG_TAG = "NetworkChangeReceiver";

        @Override
        public void onReceive(Context context, Intent intent) {
            hasConnectivity = isNetworkAvailable();
            log.info("Network condition changed hasConnectivity: {}", hasConnectivity);
        }
    };

    private boolean isNetworkAvailable() {
        ConnectivityManager cm =
                (ConnectivityManager) this.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetwork = cm.getActiveNetworkInfo();
        return activeNetwork != null && activeNetwork.isConnectedOrConnecting();
    }
}
