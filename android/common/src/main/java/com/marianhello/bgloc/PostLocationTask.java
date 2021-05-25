package com.marianhello.bgloc;

import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.LocationDAO;
import com.marianhello.logging.LoggerManager;

import org.json.JSONArray;
import org.json.JSONException;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.TimeUnit;

/**
 * Location task to post/sync locations from location providers
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
 */
public class PostLocationTask {
    private final LocationDAO mLocationDAO;
    private final PostLocationTaskListener mTaskListener;
    private final ConnectivityListener mConnectivityListener;

    private final ExecutorService mExecutor;

    private volatile boolean mHasConnectivity = true;
    private volatile Config mConfig;

    private org.slf4j.Logger logger;

    public interface PostLocationTaskListener
    {
        void onSyncRequested();
        void onRequestedAbortUpdates();
        void onHttpAuthorizationUpdates();
    }

    public PostLocationTask(LocationDAO dao, PostLocationTaskListener taskListener,
                            ConnectivityListener connectivityListener) {
        logger = LoggerManager.getLogger(PostLocationTask.class);
        logger.info("Creating PostLocationTask");

        mLocationDAO = dao;
        mTaskListener = taskListener;
        mConnectivityListener = connectivityListener;

        mExecutor = Executors.newSingleThreadExecutor();
    }

    public void setConfig(Config config) {
        mConfig = config;
    }

    public void setHasConnectivity(boolean hasConnectivity) {
        mHasConnectivity = hasConnectivity;
    }

    public void clearQueue() {
        mExecutor.execute(new Runnable() {
            @Override
            public void run() {
                mLocationDAO.deleteUnpostedLocations();
            }
        });
    }

    public void add(final BackgroundLocation location) {
        if (mConfig == null) {
            logger.warn("PostLocationTask has no config. Did you called setConfig? Skipping location.");
            return;
        }

        long locationId = mLocationDAO.persistLocation(location);
        location.setLocationId(locationId);

        try {
            mExecutor.execute(new Runnable() {
                @Override
                public void run() {
                    post(location);
                }
            });
        } catch (RejectedExecutionException ex) {
            mLocationDAO.updateLocationForSync(locationId);
        }
    }

    public void shutdown() {
        shutdown(60);
    }

    public void shutdown(int waitSeconds) {
        mExecutor.shutdown();
        try {
            if (!mExecutor.awaitTermination(waitSeconds, TimeUnit.SECONDS)) {
                mExecutor.shutdownNow();
                mLocationDAO.deleteUnpostedLocations();
            }
        } catch (InterruptedException e) {
            mExecutor.shutdownNow();
        }
    }

    private void post(final BackgroundLocation location) {
        long locationId = location.getLocationId();

        if (mHasConnectivity && mConfig.hasValidUrl()) {
            if (postLocation(location)) {
                mLocationDAO.deleteLocationById(locationId);

                return; // if posted successfully do nothing more
            } else {
                mLocationDAO.updateLocationForSync(locationId);
            }
        } else {
            mLocationDAO.updateLocationForSync(locationId);
        }

        if (mConfig.hasValidSyncUrl()) {
            long syncLocationsCount = mLocationDAO.getLocationsForSyncCount(System.currentTimeMillis());
            if (syncLocationsCount >= mConfig.getSyncThreshold()) {
                logger.debug("Attempt to sync locations: {} threshold: {}", syncLocationsCount, mConfig.getSyncThreshold());
                mTaskListener.onSyncRequested();
            }
        }
    }

    private boolean postLocation(BackgroundLocation location) {
        logger.debug("Executing PostLocationTask#postLocation");
        JSONArray jsonLocations = new JSONArray();

        try {
            jsonLocations.put(mConfig.getTemplate().locationToJson(location));
        } catch (JSONException e) {
            logger.warn("Location to json failed: {}", location.toString());
            return false;
        }

        String url = mConfig.getUrl();
        logger.debug("Posting json to url: {} headers: {}", url, mConfig.getHttpHeaders());
        int responseCode;

        try {
            responseCode = HttpPostService.postJSON(url, jsonLocations, mConfig.getHttpHeaders());
        } catch (Exception e) {
            mHasConnectivity = mConnectivityListener.hasConnectivity();
            logger.warn("Error while posting locations: {}", e.getMessage());
            return false;
        }

        if (responseCode == 285) {
            // Okay, but we don't need to continue sending these

            logger.debug("Location was sent to the server, and received an \"HTTP 285 Updates Not Required\"");

            if (mTaskListener != null)
                mTaskListener.onRequestedAbortUpdates();
        }

        if (responseCode == 401) {
            if (mTaskListener != null)
                mTaskListener.onHttpAuthorizationUpdates();
        }

        // All 2xx statuses are okay
        boolean isStatusOkay = responseCode >= 200 && responseCode < 300;

        if (!isStatusOkay) {
            logger.warn("Server error while posting locations responseCode: {}", responseCode);
            return false;
        }

        return true;
    }
}
