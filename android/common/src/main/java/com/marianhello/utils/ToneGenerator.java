package com.marianhello.utils;

import com.marianhello.logging.LoggerManager;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * Created by finch on 27.11.2017.
 */

public class ToneGenerator {
    public class Tone {
        public static final int BEEP = android.media.ToneGenerator.TONE_PROP_BEEP;
        public static final int BEEP_BEEP_BEEP = android.media.ToneGenerator.TONE_CDMA_CONFIRM;
        public static final int LONG_BEEP = android.media.ToneGenerator.TONE_CDMA_ABBR_ALERT;
        public static final int DOODLY_DOO = android.media.ToneGenerator.TONE_CDMA_ALERT_NETWORK_LITE;
        public static final int CHIRP_CHIRP_CHIRP = android.media.ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD;
        public static final int DIALTONE = android.media.ToneGenerator.TONE_SUP_RINGTONE;
    };

    private int mStreamType;
    private int mVolume;
    private final ScheduledExecutorService mExecutor;
    private org.slf4j.Logger logger;

    public ToneGenerator(int streamType, int volume) {
        mStreamType = streamType;
        mVolume = volume;
        mExecutor = Executors.newScheduledThreadPool(1);
        logger = LoggerManager.getLogger(getClass());
    }

    public void release() {
        mExecutor.shutdown();
        try {
            if (!mExecutor.awaitTermination(1, TimeUnit.SECONDS)) {
                mExecutor.shutdownNow();
            }
        } catch (InterruptedException e) {
            mExecutor.shutdownNow();
        }
    }

    public void startTone(final int toneType, final int durationMs) {
        final android.media.ToneGenerator toneGenerator = new android.media.ToneGenerator(mStreamType, mVolume);
        mExecutor.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    toneGenerator.startTone(toneType, durationMs);
                } catch (Exception e) {
                    logger.debug("Exception while playing tone: {}", e.getMessage());
                }
            }
        });
        mExecutor.schedule(new Runnable() {
            public void run() {
                try {
                    toneGenerator.release();
                } catch (Exception e) {
                    logger.debug("Exception while playing tone: {}", e.getMessage());
                }
            }
        }, durationMs,  TimeUnit.MILLISECONDS);
    }
}
