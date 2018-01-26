package com.marianhello.bgloc.sync;

import android.accounts.Account;
import android.app.NotificationManager;
import android.content.AbstractThreadedSyncAdapter;
import android.content.ContentProviderClient;
import android.content.ContentResolver;
import android.content.Context;
import android.content.SyncResult;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.support.v4.app.NotificationCompat;

import com.marianhello.bgloc.Config;
import com.marianhello.bgloc.HttpPostService;
import com.marianhello.bgloc.UploadingCallback;
import com.marianhello.bgloc.data.ConfigurationDAO;
import com.marianhello.bgloc.data.DAOFactory;
import com.marianhello.logging.LoggerManager;

import org.json.JSONException;

import java.io.File;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.util.HashMap;

/**
 * Handle the transfer of data between a server and an
 * app, using the Android sync adapter framework.
 */
public class SyncAdapter extends AbstractThreadedSyncAdapter implements UploadingCallback {

    private static final int NOTIFICATION_ID = 666;

    ContentResolver contentResolver;
    private ConfigurationDAO configDAO;
    private NotificationManager notifyManager;
    private BatchManager batchManager;

    private org.slf4j.Logger logger;

    /**
     * Set up the sync adapter
     */
    public SyncAdapter(Context context, boolean autoInitialize) {
        super(context, autoInitialize);
        logger = LoggerManager.getLogger(SyncAdapter.class);

        /*
         * If your app uses a content resolver, get an instance of it
         * from the incoming Context
         */
        contentResolver = context.getContentResolver();
        configDAO = DAOFactory.createConfigurationDAO(context);
        batchManager = new BatchManager(this.getContext());
        notifyManager = (NotificationManager) getContext().getSystemService(Context.NOTIFICATION_SERVICE);
    }


    /**
     * Set up the sync adapter. This form of the
     * constructor maintains compatibility with Android 3.0
     * and later platform versions
     */
    public SyncAdapter(
            Context context,
            boolean autoInitialize,
            boolean allowParallelSyncs) {
        super(context, autoInitialize, allowParallelSyncs);

        logger = LoggerManager.getLogger(SyncAdapter.class);

        /*
         * If your app uses a content resolver, get an instance of it
         * from the incoming Context
         */
        contentResolver = context.getContentResolver();
        configDAO = DAOFactory.createConfigurationDAO(context);
        batchManager = new BatchManager(this.getContext());
        notifyManager = (NotificationManager) getContext().getSystemService(Context.NOTIFICATION_SERVICE);
    }

    /*
     * Specify the code you want to run in the sync adapter. The entire
     * sync adapter runs in a background thread, so you don't have to set
     * up your own background processing.
     */
    @Override
    public void onPerformSync(
            Account account,
            Bundle extras,
            String authority,
            ContentProviderClient provider,
            SyncResult syncResult) {

        Config config = null;
        try {
            config = configDAO.retrieveConfiguration();
        } catch (JSONException e) {
            logger.error("Error retrieving config: {}", e.getMessage());
        }

        if (config == null || !config.hasValidSyncUrl()) {
            return;
        }

        logger.debug("Sync request: {}", config.toString());
        Long batchStartMillis = System.currentTimeMillis();

        File file = null;
        try {
            file = batchManager.createBatch(batchStartMillis, config.getSyncThreshold(), config.getTemplate());
        } catch (IOException e) {
            logger.error("Failed to create batch: {}", e.getMessage());
        }

        if (file == null) {
            logger.info("Nothing to sync");
            return;
        }

        logger.info("Syncing startAt: {}", batchStartMillis);
        String url = config.getSyncUrl();
        HashMap<String, String> httpHeaders = new HashMap<String, String>();
        httpHeaders.putAll(config.getHttpHeaders());
        httpHeaders.put("x-batch-id", String.valueOf(batchStartMillis));

        if (uploadLocations(file, url, httpHeaders)) {
            logger.info("Batch sync successful");
            batchManager.setBatchCompleted(batchStartMillis);
            if (file.delete()) {
                logger.info("Batch file has been deleted: {}", file.getAbsolutePath());
            } else {
                logger.warn("Batch file has not been deleted: {}", file.getAbsolutePath());
            }
        } else {
            logger.warn("Batch sync failed due server error");
            syncResult.stats.numIoExceptions++;
        }
    }

    private boolean uploadLocations(File file, String url, HashMap httpHeaders) {
        NotificationCompat.Builder builder = new NotificationCompat.Builder(getContext());
        builder.setOngoing(true);
        builder.setContentTitle("Syncing locations");
        builder.setContentText("Sync in progress");
        builder.setSmallIcon(android.R.drawable.ic_dialog_info);
        notifyManager.notify(NOTIFICATION_ID, builder.build());

        try {
            int responseCode = HttpPostService.postFile(url, file, httpHeaders, this);
            if (responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED) {
                builder.setContentText("Sync completed");
            } else {
                builder.setContentText("Sync failed due server error");
            }

            return responseCode == HttpURLConnection.HTTP_OK || responseCode == HttpURLConnection.HTTP_CREATED;
        } catch (IOException e) {
            logger.warn("Error uploading locations: {}", e.getMessage());
            builder.setContentText("Sync failed: " + e.getMessage());
        } finally {
            logger.info("Syncing endAt: {}", System.currentTimeMillis());

            builder.setOngoing(false);
            builder.setProgress(0, 0, false);
            builder.setAutoCancel(true);
            notifyManager.notify(NOTIFICATION_ID, builder.build());
            
            Handler h = new Handler(Looper.getMainLooper());
            long delayInMilliseconds = 5000;
            h.postDelayed(new Runnable() {
                public void run() {
                    logger.info("Notification cancelledAt: {}", System.currentTimeMillis());
                    notifyManager.cancel(NOTIFICATION_ID);
                }
            }, delayInMilliseconds);
        }

        return false;
    }

    public void uploadListener(int progress) {
        logger.debug("Syncing progress: {} updatedAt: {}", progress, System.currentTimeMillis());
        NotificationCompat.Builder builder = new NotificationCompat.Builder(getContext());
        builder.setOngoing(true);
        builder.setContentTitle("Syncing locations");
        builder.setContentText("Sync in progress");
        builder.setSmallIcon(android.R.drawable.ic_dialog_info);
        builder.setProgress(100, progress, false);
        notifyManager.notify(NOTIFICATION_ID, builder.build());
    }
}
