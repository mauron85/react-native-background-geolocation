package com.marianhello.react;

import android.Manifest;
import android.annotation.TargetApi;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.location.LocationManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.os.RemoteException;
import android.provider.Settings;
import android.provider.Settings.SettingNotFoundException;
import android.support.annotation.NonNull;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.text.TextUtils;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.marianhello.bgloc.Config;
import com.marianhello.bgloc.LocationService;
import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.ConfigurationDAO;
import com.marianhello.bgloc.data.DAOFactory;
import com.marianhello.bgloc.data.LocationDAO;
import com.marianhello.logging.DBLogReader;
import com.marianhello.logging.LogEntry;
import com.marianhello.logging.LogReader;
import com.marianhello.logging.LoggerManager;
import com.marianhello.react.data.LocationMapper;

import org.json.JSONException;

import java.util.Collection;

public class BackgroundGeolocationModule extends ReactContextBaseJavaModule implements LifecycleEventListener, ActivityCompat.OnRequestPermissionsResultCallback {

    public static final String LOCATION_EVENT = "location";
    public static final String STATIONARY_EVENT = "stationary";
    public static final String START_EVENT = "start";
    public static final String STOP_EVENT = "stop";
    public static final String ERROR_EVENT = "error";
    public static final String AUTHORIZATION_EVENT = "authorization";
    public static final String FOREGROUND_EVENT = "foreground";
    public static final String BACKGROUND_EVENT = "background";
    public static final String[] PERMISSIONS = { Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION };
    private static final int PERMISSIONS_REQUEST = 1;
    private static final int MESSENGER_CLIENT_ID = 666;
    private static final int AUTHORIZATION_AUTHORIZED = 1;
    private static final int AUTHORIZATION_DENIED = 0;

    /** Messenger for communicating with the service. */
    private Messenger mService = null;
    /** Flag indicating whether we have called bind on the service. */
    private Boolean mIsBound = false;
    private Boolean locationModeChangeReceiverRegistered = false;
    private Config mConfig = null;

    private org.slf4j.Logger log;

    Messenger mMessenger;

    public BackgroundGeolocationModule(ReactApplicationContext reactContext) {
        super(reactContext);
        reactContext.addLifecycleEventListener(this);

        LoggerManager.enableDBLogging();
        log = LoggerManager.getLogger(BackgroundGeolocationModule.class);
        log.info("Initializing plugin");
    }

    @Override
    public String getName() {
        return "BackgroundGeolocation";
    }

    @Override
    public void onHostResume() {
        log.info("App will be resumed");
        if (LocationService.isRunning()) {
            if (!mIsBound) {
                doBindService();
            }
            if (!locationModeChangeReceiverRegistered) {
                registerLocationModeChangeReceiver();
            }
        }
        sendEvent(FOREGROUND_EVENT, null);
    }

    @Override
    public void onHostPause() {
        log.info("App will be paused");
        sendEvent(BACKGROUND_EVENT, null);
    }

    @Override
    public void onHostDestroy() {
        log.info("Destroying plugin");

        unregisterLocationModeChangeReceiver();
        // Unbind from the service
        doUnbindService();
        if (mConfig == null || mConfig.getStopOnTerminate()) {
            stopBackgroundService();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        switch (requestCode) {
            case PERMISSIONS_REQUEST: {
                // If request is cancelled, the result arrays are empty.
                if (grantResults.length == 0) {
                    // permission denied
                    log.info("User denied requested permissions");
                    sendEvent(AUTHORIZATION_EVENT, AUTHORIZATION_DENIED);
                    return;
                }
                for (int grant : grantResults) {
                    if (grant != PackageManager.PERMISSION_GRANTED) {
                        // permission denied
                        log.info("User denied requested permissions");
                        sendEvent(AUTHORIZATION_EVENT, AUTHORIZATION_DENIED);
                        return;
                    }
                }

                // permission was granted
                // start service
                log.info("User granted requested permissions");
                startAndBindBackgroundService();
                // watch location mode changes
                registerLocationModeChangeReceiver();

                return;
            }
        }
    }

    /**
     * Handler of incoming messages from service.
     */
    class IncomingHandler extends Handler {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case LocationService.MSG_LOCATION_UPDATE:
                    try {
                        log.debug("Sending location to webview");
                        Bundle bundle = msg.getData();
                        bundle.setClassLoader(LocationService.class.getClassLoader());
                        BackgroundLocation location = (BackgroundLocation) bundle.getParcelable("location");
                        WritableMap out = LocationMapper.toWriteableMap(location);

                        sendEvent(LOCATION_EVENT, out);
                    } catch (Exception e) {
                        log.warn("Error converting message to json");

                        WritableMap out = Arguments.createMap();
                        out.putString("message", "Error converting message to json");
                        out.putString("detail", e.getMessage());

                        sendEvent(ERROR_EVENT, out);
                    }

                    break;
                case LocationService.MSG_ON_STATIONARY:
                    try {
                        log.debug("Sending stationary location to webview");
                        Bundle bundle = msg.getData();
                        bundle.setClassLoader(LocationService.class.getClassLoader());
                        BackgroundLocation location = (BackgroundLocation) bundle.getParcelable("location");
                        WritableMap out = LocationMapper.toWriteableMap(location);

                        sendEvent(STATIONARY_EVENT, out);
                    } catch (Exception e) {
                        log.warn("Error converting message to json");

                        WritableMap out = Arguments.createMap();
                        out.putString("message", "Error converting message to json");
                        out.putString("detail", e.getMessage());

                        sendEvent(ERROR_EVENT, out);
                    }

                    break;
                default:
                    super.handleMessage(msg);
            }
        }
    }

    /**
     * Class for interacting with the main interface of the service.
     */
    private ServiceConnection mConnection = new ServiceConnection() {
        public void onServiceConnected(ComponentName className, IBinder service) {
            // This is called when the connection with the service has been
            // established, giving us the object we can use to
            // interact with the service.  We are communicating with the
            // service using a Messenger, so here we get a client-side
            // representation of that from the raw IBinder object.
            mService = new Messenger(service);
            mIsBound = true;

            // We want to monitor the service for as long as we are
            // connected to it.
            try {
                Message msg = Message.obtain(null,
                        LocationService.MSG_REGISTER_CLIENT);
                msg.replyTo = mMessenger;
                msg.arg1 = MESSENGER_CLIENT_ID;
                mService.send(msg);
            } catch (RemoteException e) {
                // In this case the service has crashed before we could even
                // do anything with it; we can count on soon being
                // disconnected (and then reconnected if it can be restarted)
                // so there is no need to do anything here.
            }
        }

        public void onServiceDisconnected(ComponentName className) {
            // This is called when the connection with the service has been
            // unexpectedly disconnected -- that is, its process crashed.
            mService = null;
            mIsBound = false;
        }
    };

    private BroadcastReceiver locationModeChangeReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            log.debug("Received AUTHORIZATION_EVENT");
            try {
                sendEvent(AUTHORIZATION_EVENT, getAuthorizationStatus());
            } catch (SettingNotFoundException e) {
                WritableMap out = Arguments.createMap();
                out.putString("message", "Error occured while determining location mode");
                sendEvent(ERROR_EVENT, out);
            }
        }
    };

    @TargetApi(Build.VERSION_CODES.KITKAT)
    private void registerLocationModeChangeReceiver () {
        if (locationModeChangeReceiverRegistered) return;

        getReactApplicationContext().registerReceiver(locationModeChangeReceiver, new IntentFilter(LocationManager.MODE_CHANGED_ACTION));
        locationModeChangeReceiverRegistered = true;
    }

    private void unregisterLocationModeChangeReceiver () {
        if (locationModeChangeReceiverRegistered == false) return;

        Context context = getReactApplicationContext();
        if (context != null) {
            context.unregisterReceiver(locationModeChangeReceiver);
        }
        locationModeChangeReceiverRegistered = false;
    }

    @ReactMethod
    public void start() {
        if (hasPermissions(PERMISSIONS)) {
            log.debug("Permissions granted");
            startAndBindBackgroundService();
            // watch location mode changes
            registerLocationModeChangeReceiver();
        } else {
            log.debug("Permissions not granted");
            requestPermissions(PERMISSIONS);
        }
    }

    @ReactMethod
    public void stop() {
        unregisterLocationModeChangeReceiver();
        doUnbindService();
        stopBackgroundService();
    }

    @Deprecated // use checkStatus as replacement
    @ReactMethod
    public void isLocationEnabled(Callback success, Callback error) {
        log.debug("Location services enabled check");
        try {
            int isLocationEnabled = isLocationEnabled(getReactApplicationContext()) ? 1 : 0;
            success.invoke(isLocationEnabled);
        } catch (SettingNotFoundException e) {
            log.error("Location service checked failed: {}", e.getMessage());
            error.invoke("Location setting error occured");
        }
    }

    @ReactMethod
    public void checkStatus(Callback success, Callback error) {
        try {
            WritableMap out = Arguments.createMap();
            out.putBoolean("isRunning", LocationService.isRunning());
            out.putBoolean("hasPermissions", hasPermissions(PERMISSIONS));
            out.putInt("authorization", getAuthorizationStatus());
            success.invoke(out);
        } catch (SettingNotFoundException e) {
            log.error("Location service checked failed: {}", e.getMessage());
            error.invoke("Location setting error occured");
        }
    }

    @ReactMethod
    public void showAppSettings() {
        Context context = getReactApplicationContext();
        Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        intent.addCategory(Intent.CATEGORY_DEFAULT);
        intent.setData(Uri.parse("package:" + context.getPackageName()));
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY);
        intent.addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS);
        context.startActivity(intent);
    }

    @ReactMethod
    public void showLocationSettings() {
        Context context = getReactApplicationContext();
        Intent intent = new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS);
        intent.addCategory(Intent.CATEGORY_DEFAULT);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY);
        intent.addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS);
        context.startActivity(intent);
    }

    @ReactMethod
    public void getLocations(Callback success, Callback error) {
        WritableArray locationsArray = Arguments.createArray();
        LocationDAO dao = DAOFactory.createLocationDAO(getReactApplicationContext());
        try {
            Collection<BackgroundLocation> locations = dao.getAllLocations();
            for (BackgroundLocation location : locations) {
                locationsArray.pushMap(LocationMapper.toWriteableMapWithId(location));
            }
            success.invoke(locationsArray);
        } catch (Exception e) {
            log.error("Getting all locations failed: {}", e.getMessage());
            error.invoke("Converting locations to JSON failed.");
        }
    }

    @ReactMethod
    public void getValidLocations(Callback success, Callback error) {
        WritableArray locationsArray = Arguments.createArray();
        LocationDAO dao = DAOFactory.createLocationDAO(getReactApplicationContext());
        try {
            Collection<BackgroundLocation> locations = dao.getValidLocations();
            for (BackgroundLocation location : locations) {
                locationsArray.pushMap(LocationMapper.toWriteableMapWithId(location));
            }
            success.invoke(locationsArray);
        } catch (Exception e) {
            log.error("Getting valid locations failed: {}", e.getMessage());
            error.invoke("Converting locations to JSON failed.");
        }
    }

    @ReactMethod
    public void deleteLocation(Integer locationId, Callback success, Callback error) {
        log.info("Deleting location locationId={}", locationId);
        LocationDAO dao = DAOFactory.createLocationDAO(getReactApplicationContext());
        dao.deleteLocation(locationId.longValue());
        success.invoke(true);
    }

    @ReactMethod
    public void deleteAllLocations(Callback success, Callback error) {
        log.info("Deleting all locations");
        LocationDAO dao = DAOFactory.createLocationDAO(getReactApplicationContext());
        dao.deleteAllLocations();
        success.invoke(true);
    }

    @ReactMethod
    public void switchMode(ReadableMap options, Callback success, Callback error) {
        //TODO: implement
        error.invoke("Not implemented yet");
    }

    @ReactMethod
    public void configure(ReadableMap options, Callback success, Callback error) {
        try {
            Config config = ConfigMapper.mapToConfig(options);
            persistConfiguration(config);
            log.debug("Service configured with: {}", config.toString());
            mConfig = config;
            success.invoke(true);
        } catch (NullPointerException e) {
            log.error("Configuration error: {}", e.getMessage());
            error.invoke("Configuration error: " + e.getMessage());
        }
    }

    @ReactMethod
    public void getConfig(Callback success, Callback error) {
        Config config = mConfig;
        try {
            if (config == null) {
                config = getStoredOrDefaultConfig();
            }
            ReadableMap out = ConfigMapper.configToMap(config);
            success.invoke(out);
        } catch (Exception e) {
            log.error("Error getting config: {}", e.getMessage());
            error.invoke("Error getting config: " + e.getMessage());
        }
    }

    @ReactMethod
    public void getLogEntries(int limit, Callback success, Callback error) {
        LogReader logReader = new DBLogReader();
        WritableArray logEntriesArray = Arguments.createArray();
        Collection<LogEntry> logEntries = logReader.getEntries(limit);
        for (LogEntry logEntry : logEntries) {
            WritableMap out = Arguments.createMap();
            out.putInt("context", logEntry.getContext());
            out.putString("level", logEntry.getLevel());
            out.putString("message", logEntry.getMessage());
            out.putString("timestamp", new Long(logEntry.getTimestamp()).toString());
            out.putString("logger", logEntry.getLoggerName());

            logEntriesArray.pushMap(out);
        }

        success.invoke(logEntriesArray);
    }

    protected Config getStoredOrDefaultConfig() throws JSONException {
        Config config = getStoredConfig();
        if (config == null) {
            config = new Config();
        }
        return config;
    }

    protected Config getStoredConfig() throws JSONException {
        ConfigurationDAO dao = DAOFactory.createConfigurationDAO(getReactApplicationContext());
        return dao.retrieveConfiguration();
    }

    private void sendEvent(String eventName, Object params) {
        getReactApplicationContext()
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }

    public boolean hasPermissions(String[] permissions) {
        for (String perm: permissions) {
            if (ContextCompat.checkSelfPermission(getReactApplicationContext(), perm) != PackageManager.PERMISSION_GRANTED) {
                return false;
            }
        }
        return true;
    }

    public void requestPermissions(String[] permissions) {
        log.debug("Requesting permissions");
        ActivityCompat.requestPermissions(getCurrentActivity(), permissions, PERMISSIONS_REQUEST);
    }

    protected void startAndBindBackgroundService() {
        try {
            startBackgroundService();
            doBindService();
        } catch (Exception e) {
            WritableMap out = Arguments.createMap();
            out.putString("message", "Error occured while starting service");
            out.putString("detail", e.getMessage());

            sendEvent(ERROR_EVENT, out);
        }
    }

    protected void startBackgroundService() throws Exception {
        if (LocationService.isRunning()) return;

        log.info("Starting bg service");
        Context context = getReactApplicationContext();
        Intent locationServiceIntent = new Intent(context, LocationService.class);

        if (mConfig == null) {
            log.warn("Attempt to start unconfigured service. Will use stored or default.");
            mConfig = getStoredOrDefaultConfig();
        }

        locationServiceIntent.putExtra("config", mConfig);
        locationServiceIntent.addFlags(Intent.FLAG_FROM_BACKGROUND);
        // start service to keep service running even if no clients are bound to it
        context.startService(locationServiceIntent);
        sendEvent(START_EVENT, null);
    }

    protected void stopBackgroundService() {
        if (!LocationService.isRunning()) return;

        log.info("Stopping bg service");
        Context context = getReactApplicationContext();
        context.stopService(new Intent(context, LocationService.class));
        sendEvent(STOP_EVENT, null);
    }

    void doBindService() {
        // Establish a connection with the service.  We use an explicit
        // class name because there is no reason to be able to let other
        // applications replace our component.
        if (mIsBound) return;

        log.debug("Binding to service");
        mMessenger = new Messenger(new IncomingHandler());

        final Context context = getReactApplicationContext();
        Intent locationServiceIntent = new Intent(context, LocationService.class);
//        locationServiceIntent.putExtra("config", config);
        context.bindService(locationServiceIntent, mConnection, Context.BIND_IMPORTANT);
    }

    void doUnbindService () {
        if (mIsBound == false) return;

        log.debug("Unbinding from service");
        // If we have received the service, and hence registered with
        // it, then now is the time to unregister.
        if (mService != null) {
            try {
                Message msg = Message.obtain(null,
                        LocationService.MSG_UNREGISTER_CLIENT);
                msg.replyTo = mMessenger;
                msg.arg1 = MESSENGER_CLIENT_ID;
                mService.send(msg);
            } catch (RemoteException e) {
                // There is nothing special we need to do if the service
                // has crashed.
            }

            // Detach our existing connection.
            final Context context = getReactApplicationContext();

            if (context != null) { //workaround for issue RN #9791
                // not unbinding from service will cause ServiceConnectionLeaked
                // but there is not much we can do about it now
                context.unbindService(mConnection);
            }

            mIsBound = false;
        }
    }

    public void persistConfiguration(Config config) throws NullPointerException {
        ConfigurationDAO dao = DAOFactory.createConfigurationDAO(getReactApplicationContext());
        dao.persistConfiguration(config);
    }

    public int getAuthorizationStatus() throws SettingNotFoundException {
        boolean enabled = isLocationEnabled(getReactApplicationContext());
        return enabled ? AUTHORIZATION_AUTHORIZED : AUTHORIZATION_DENIED;
    }

    public static boolean isLocationEnabled(Context context) throws SettingNotFoundException {
        int locationMode = 0;
        String locationProviders;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            locationMode = Settings.Secure.getInt(context.getContentResolver(), Settings.Secure.LOCATION_MODE);
            return locationMode != Settings.Secure.LOCATION_MODE_OFF;

        } else {
            locationProviders = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.LOCATION_PROVIDERS_ALLOWED);
            return !TextUtils.isEmpty(locationProviders);
        }
    }
}
