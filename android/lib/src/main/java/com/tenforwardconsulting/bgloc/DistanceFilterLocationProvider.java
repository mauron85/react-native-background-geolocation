/*
According to apache license

This is fork of christocracy cordova-plugin-background-geolocation plugin
https://github.com/christocracy/cordova-plugin-background-geolocation

Differences to original version:

1. location is not persisted to db anymore, but broadcasted using intents instead
*/

package com.tenforwardconsulting.bgloc;

import android.app.AlarmManager;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.location.Criteria;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.os.PowerManager;
import android.widget.Toast;

import com.marianhello.bgloc.AbstractLocationProvider;
import com.marianhello.bgloc.LocationService;
import com.marianhello.logging.LoggerManager;

import java.util.List;

import static java.lang.Math.abs;
import static java.lang.Math.pow;
import static java.lang.Math.round;


public class DistanceFilterLocationProvider extends AbstractLocationProvider implements LocationListener {
    private static final String TAG = DistanceFilterLocationProvider.class.getSimpleName();
    private static final String P_NAME = "com.tenforwardconsulting.cordova.bgloc";

    private static final String STATIONARY_REGION_ACTION        = P_NAME + ".STATIONARY_REGION_ACTION";
    private static final String STATIONARY_ALARM_ACTION         = P_NAME + ".STATIONARY_ALARM_ACTION";
    private static final String SINGLE_LOCATION_UPDATE_ACTION   = P_NAME + ".SINGLE_LOCATION_UPDATE_ACTION";
    private static final String STATIONARY_LOCATION_MONITOR_ACTION = P_NAME + ".STATIONARY_LOCATION_MONITOR_ACTION";

    private static final long STATIONARY_TIMEOUT                                = 5 * 1000 * 60;    // 5 minutes.
    private static final long STATIONARY_LOCATION_POLLING_INTERVAL_LAZY         = 3 * 1000 * 60;    // 3 minutes.
    private static final long STATIONARY_LOCATION_POLLING_INTERVAL_AGGRESSIVE   = 1 * 1000 * 60;    // 1 minute.
    private static final Integer MAX_STATIONARY_ACQUISITION_ATTEMPTS = 5;
    private static final Integer MAX_SPEED_ACQUISITION_ATTEMPTS = 3;

    private Boolean isMoving = false;
    private Boolean isAcquiringStationaryLocation = false;
    private Boolean isAcquiringSpeed = false;
    private Integer locationAcquisitionAttempts = 0;

    private PowerManager.WakeLock wakeLock;

    private Location stationaryLocation;
    private PendingIntent stationaryAlarmPI;
    private PendingIntent stationaryLocationPollingPI;
    private long stationaryLocationPollingInterval;
    private PendingIntent stationaryRegionPI;
    private PendingIntent singleUpdatePI;
    private Integer scaledDistanceFilter;

    private String activity;
    private Criteria criteria;

    private LocationManager locationManager;
    private AlarmManager alarmManager;
    private NotificationManager notificationManager;

    private org.slf4j.Logger log;

    public DistanceFilterLocationProvider(LocationService context) {
        super(context);
        PROVIDER_ID = 0;
    }

    @Override
    public void onCreate() {
        super.onCreate();

        log = LoggerManager.getLogger(DistanceFilterLocationProvider.class);
        log.info("Creating DistanceFilterLocationProvider");

        locationManager = (LocationManager) locationService.getSystemService(Context.LOCATION_SERVICE);
        alarmManager = (AlarmManager) locationService.getSystemService(Context.ALARM_SERVICE);

        // Stop-detection PI
        stationaryAlarmPI = PendingIntent.getBroadcast(locationService, 0, new Intent(STATIONARY_ALARM_ACTION), 0);
        registerReceiver(stationaryAlarmReceiver, new IntentFilter(STATIONARY_ALARM_ACTION));

        // Stationary region PI
        stationaryRegionPI = PendingIntent.getBroadcast(locationService, 0, new Intent(STATIONARY_REGION_ACTION), PendingIntent.FLAG_CANCEL_CURRENT);
        registerReceiver(stationaryRegionReceiver, new IntentFilter(STATIONARY_REGION_ACTION));

        // Stationary location monitor PI
        stationaryLocationPollingPI = PendingIntent.getBroadcast(locationService, 0, new Intent(STATIONARY_LOCATION_MONITOR_ACTION), 0);
        registerReceiver(stationaryLocationMonitorReceiver, new IntentFilter(STATIONARY_LOCATION_MONITOR_ACTION));

        // One-shot PI (TODO currently unused)
        singleUpdatePI = PendingIntent.getBroadcast(locationService, 0, new Intent(SINGLE_LOCATION_UPDATE_ACTION), PendingIntent.FLAG_CANCEL_CURRENT);
        registerReceiver(singleUpdateReceiver, new IntentFilter(SINGLE_LOCATION_UPDATE_ACTION));

        PowerManager pm = (PowerManager) locationService.getSystemService(Context.POWER_SERVICE);
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, TAG);
        wakeLock.acquire();

        // Location criteria
        criteria = new Criteria();
        criteria.setAltitudeRequired(false);
        criteria.setBearingRequired(false);
        criteria.setSpeedRequired(true);
        criteria.setCostAllowed(true);
    }

    public void startRecording() {
        log.info("Start recording");
        scaledDistanceFilter = config.getDistanceFilter();
        setPace(false);
    }

    public void stopRecording() {
        log.info("stopRecording not implemented yet");
    }

    /**
     *
     * @param value set true to engage "aggressive", battery-consuming tracking, false for stationary-region tracking
     */
    private void setPace(Boolean value) {
        log.info("Setting pace: {}", value);

        Boolean wasMoving   = isMoving;
        isMoving            = value;
        isAcquiringStationaryLocation = false;
        isAcquiringSpeed    = false;
        stationaryLocation  = null;

        try {
            locationManager.removeUpdates(this);
            criteria.setAccuracy(Criteria.ACCURACY_FINE);
            criteria.setHorizontalAccuracy(translateDesiredAccuracy(config.getDesiredAccuracy()));
            criteria.setPowerRequirement(Criteria.POWER_HIGH);

            if (isMoving) {
                // setPace can be called while moving, after distanceFilter has been recalculated.  We don't want to re-acquire velocity in this case.
                if (!wasMoving) {
                    isAcquiringSpeed = true;
                }
            } else {
                isAcquiringStationaryLocation = true;
            }

            // Temporarily turn on super-aggressive geolocation on all providers when acquiring velocity or stationary location.
            if (isAcquiringSpeed || isAcquiringStationaryLocation) {
                locationAcquisitionAttempts = 0;
                // Turn on each provider aggressively for a short period of time
                List<String> matchingProviders = locationManager.getAllProviders();
                for (String provider: matchingProviders) {
                    if (provider != LocationManager.PASSIVE_PROVIDER) {
                        locationManager.requestLocationUpdates(provider, 0, 0, this);
                    }
                }
            } else {
                locationManager.requestLocationUpdates(locationManager.getBestProvider(criteria, true), config.getInterval(), scaledDistanceFilter, this);
            }
        } catch (SecurityException e) {
            log.error("Security exception: {}", e.getMessage());
            this.handleSecurityException(e);
        }
    }

    /**
    * Translates a number representing desired accuracy of Geolocation system from set [0, 10, 100, 1000].
    * 0:  most aggressive, most accurate, worst battery drain
    * 1000:  least aggressive, least accurate, best for battery.
    */
    private Integer translateDesiredAccuracy(Integer accuracy) {
        switch (accuracy) {
            case 1000:
                accuracy = Criteria.ACCURACY_LOW;
                break;
            case 100:
                accuracy = Criteria.ACCURACY_MEDIUM;
                break;
            case 10:
                accuracy = Criteria.ACCURACY_HIGH;
                break;
            case 0:
                accuracy = Criteria.ACCURACY_HIGH;
                break;
            default:
                accuracy = Criteria.ACCURACY_MEDIUM;
        }
        return accuracy;
    }

    /**
     * Returns the most accurate and timely previously detected location.
     * Where the last result is beyond the specified maximum distance or
     * latency a one-off location update is returned via the {@link LocationListener}
     * specified in {@link setChangedLocationListener}.
     * @param minTime Minimum time required between location updates.
     * @return The most accurate and / or timely previously detected location.
     */
    public Location getLastBestLocation() {
        Location bestResult = null;
        String bestProvider = null;
        float bestAccuracy = Float.MAX_VALUE;
        long bestTime = Long.MIN_VALUE;
        long minTime = System.currentTimeMillis() - config.getInterval();

        log.info("Fetching last best location: radius={} minTime={}", config.getStationaryRadius(), minTime);

        try {
            // Iterate through all the providers on the system, keeping
            // note of the most accurate result within the acceptable time limit.
            // If no result is found within maxTime, return the newest Location.
            List<String> matchingProviders = locationManager.getAllProviders();
            for (String provider: matchingProviders) {
                Location location = locationManager.getLastKnownLocation(provider);
                if (location != null) {
                    log.debug("Test provider={} lat={} lon={} acy={} v={}m/s time={}", provider, location.getLatitude(), location.getLongitude(), location.getAccuracy(), location.getSpeed(), location.getTime());
                    float accuracy = location.getAccuracy();
                    long time = location.getTime();
                    if ((time > minTime && accuracy < bestAccuracy)) {
                        bestProvider = provider;
                        bestResult = location;
                        bestAccuracy = accuracy;
                        bestTime = time;
                    }
                }
            }

            if (bestResult != null) {
                log.debug("Best result found provider={} lat={} lon={} acy={} v={}m/s time={}", bestProvider, bestResult.getLatitude(), bestResult.getLongitude(), bestResult.getAccuracy(), bestResult.getSpeed(), bestResult.getTime());
            }
        } catch (SecurityException e) {
            log.error("Security exception: {}", e.getMessage());
            this.handleSecurityException(e);
        }

        return bestResult;
    }

    public void onLocationChanged(Location location) {
        log.debug("Location change: {} isMoving={}", location.toString(), isMoving);

        if (!isMoving && !isAcquiringStationaryLocation && stationaryLocation==null) {
            // Perhaps our GPS signal was interupted, re-acquire a stationaryLocation now.
            setPace(false);
        }

        if (config.isDebugging()) {
            Toast.makeText(locationService, "mv:" + isMoving + ",acy:" + location.getAccuracy() + ",v:" + location.getSpeed() + ",df:" + scaledDistanceFilter, Toast.LENGTH_LONG).show();
        }
        if (isAcquiringStationaryLocation) {
            if (stationaryLocation == null || stationaryLocation.getAccuracy() > location.getAccuracy()) {
                stationaryLocation = location;
            }
            if (++locationAcquisitionAttempts == MAX_STATIONARY_ACQUISITION_ATTEMPTS) {
                isAcquiringStationaryLocation = false;
                startMonitoringStationaryRegion(stationaryLocation);
                if (config.isDebugging()) {
                    startTone(Tone.LONG_BEEP);
                }
            } else {
                // Unacceptable stationary-location: bail-out and wait for another.
                if (config.isDebugging()) {
                    startTone(Tone.BEEP);
                }
                return;
            }
        } else if (isAcquiringSpeed) {
            if (++locationAcquisitionAttempts == MAX_SPEED_ACQUISITION_ATTEMPTS) {
                // Got enough samples, assume we're confident in reported speed now.  Play "woohoo" sound.
                if (config.isDebugging()) {
                    startTone(Tone.DOODLY_DOO);
                }
                isAcquiringSpeed = false;
                scaledDistanceFilter = calculateDistanceFilter(location.getSpeed());
                setPace(true);
            } else {
                if (config.isDebugging()) {
                    startTone(Tone.BEEP);
                }
                return;
            }
        } else if (isMoving) {
            if (config.isDebugging()) {
                startTone(Tone.BEEP);
            }
            // Only reset stationaryAlarm when accurate speed is detected, prevents spurious locations from resetting when stopped.
            if ( (location.getSpeed() >= 1) && (location.getAccuracy() <= config.getStationaryRadius()) ) {
                resetStationaryAlarm();
            }
            // Calculate latest distanceFilter, if it changed by 5 m/s, we'll reconfigure our pace.
            Integer newDistanceFilter = calculateDistanceFilter(location.getSpeed());
            if (newDistanceFilter != scaledDistanceFilter.intValue()) {
                log.info("Updating distanceFilter: new={} old={}", newDistanceFilter, scaledDistanceFilter);
                scaledDistanceFilter = newDistanceFilter;
                setPace(true);
            }
            if (location.distanceTo(lastLocation) < config.getDistanceFilter()) {
                return;
            }
        } else if (stationaryLocation != null) {
            return;
        }
        // Go ahead and cache, push to server
        lastLocation = location;
        handleLocation(location);
    }

    public void resetStationaryAlarm() {
        alarmManager.cancel(stationaryAlarmPI);
        alarmManager.set(AlarmManager.RTC_WAKEUP, System.currentTimeMillis() + STATIONARY_TIMEOUT, stationaryAlarmPI); // Millisec * Second * Minute
    }

    private Integer calculateDistanceFilter(Float speed) {
        Double newDistanceFilter = (double) config.getDistanceFilter();
        if (speed < 100) {
            float roundedDistanceFilter = (round(speed / 5) * 5);
            newDistanceFilter = pow(roundedDistanceFilter, 2) + (double) config.getDistanceFilter();
        }
        return (newDistanceFilter.intValue() < 1000) ? newDistanceFilter.intValue() : 1000;
    }

    private void startMonitoringStationaryRegion(Location location) {
        try {
            locationManager.removeUpdates(this);

            float stationaryRadius = config.getStationaryRadius();
            float proximityAccuracy = (location.getAccuracy() < stationaryRadius) ? stationaryRadius : location.getAccuracy();
            stationaryLocation = location;

            log.info("startMonitoringStationaryRegion: lat={} lon={} acy={}", location.getLatitude(), location.getLongitude(), proximityAccuracy);

            // Here be the execution of the stationary region monitor
            locationManager.addProximityAlert(
                    location.getLatitude(),
                    location.getLongitude(),
                    proximityAccuracy,
                    (long)-1,
                    stationaryRegionPI
            );

            startPollingStationaryLocation(STATIONARY_LOCATION_POLLING_INTERVAL_LAZY);
        } catch (SecurityException e) {
            log.error("Security exception: {}", e.getMessage());
            this.handleSecurityException(e);
        }
    }

    /**
     * User has exit his stationary region!  Initiate aggressive geolocation!
     */
    public void onExitStationaryRegion(Location location) {
        // Filter-out spurious region-exits:  must have at least a little speed to move out of stationary-region
        if (config.isDebugging()) {
            startTone(Tone.BEEP_BEEP_BEEP);
        }

        log.info("Exited stationary: lat={} long={} acy={}}'",
                location.getLatitude(), location.getLongitude(), location.getAccuracy());

        try {
            // Cancel the periodic stationary location monitor alarm.
            alarmManager.cancel(stationaryLocationPollingPI);
            // Kill the current region-monitor we just walked out of.
            locationManager.removeProximityAlert(stationaryRegionPI);
            // Engage aggressive tracking.
            this.setPace(true);
        } catch (SecurityException e) {
            log.error("Security exception: {}", e.getMessage());
            this.handleSecurityException(e);
        }
    }

    public void startPollingStationaryLocation(long interval) {
        // proximity-alerts don't seem to work while suspended in latest Android 4.42 (works in 4.03).  Have to use AlarmManager to sample
        //  location at regular intervals with a one-shot.
        stationaryLocationPollingInterval = interval;
        alarmManager.cancel(stationaryLocationPollingPI);
        long start = System.currentTimeMillis() + (60 * 1000);
        alarmManager.setInexactRepeating(AlarmManager.RTC_WAKEUP, start, interval, stationaryLocationPollingPI);
    }

    public void onPollStationaryLocation(Location location) {
        float stationaryRadius = config.getStationaryRadius();
        if (isMoving) {
            return;
        }
        if (config.isDebugging()) {
            startTone(Tone.BEEP);
        }
        float distance = abs(location.distanceTo(stationaryLocation) - stationaryLocation.getAccuracy() - location.getAccuracy());

        if (config.isDebugging()) {
            Toast.makeText(locationService, "Stationary exit in " + (stationaryRadius-distance) + "m", Toast.LENGTH_LONG).show();
        }

        // TODO http://www.cse.buffalo.edu/~demirbas/publications/proximity.pdf
        // determine if we're almost out of stationary-distance and increase monitoring-rate.
        log.info("Distance from stationary location: {}", distance);
        if (distance > stationaryRadius) {
            onExitStationaryRegion(location);
        } else if (distance > 0) {
            startPollingStationaryLocation(STATIONARY_LOCATION_POLLING_INTERVAL_AGGRESSIVE);
        } else if (stationaryLocationPollingInterval != STATIONARY_LOCATION_POLLING_INTERVAL_LAZY) {
            startPollingStationaryLocation(STATIONARY_LOCATION_POLLING_INTERVAL_LAZY);
        }
    }

    /**
    * Broadcast receiver for receiving a single-update from LocationManager.
    */
    private BroadcastReceiver singleUpdateReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String key = LocationManager.KEY_LOCATION_CHANGED;
            Location location = (Location)intent.getExtras().get(key);
            if (location != null) {
                log.debug("Single location update: " + location.toString());
                onPollStationaryLocation(location);
            }
        }
    };

    /**
    * Broadcast receiver which detects a user has stopped for a long enough time to be determined as STOPPED
    */
    private BroadcastReceiver stationaryAlarmReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent)
        {
            log.info("stationaryAlarm fired");
            setPace(false);
        }
    };

    /**
     * Broadcast receiver to handle stationaryMonitor alarm, fired at low frequency while monitoring stationary-region.
     * This is required because latest Android proximity-alerts don't seem to operate while suspended.  Regularly polling
     * the location seems to trigger the proximity-alerts while suspended.
     */
     private BroadcastReceiver stationaryLocationMonitorReceiver = new BroadcastReceiver() {
         @Override
         public void onReceive(Context context, Intent intent)
         {
             log.info("Stationary location monitor fired");
             if (config.isDebugging()) {
                 startTone(Tone.DIALTONE);
             }

             criteria.setAccuracy(Criteria.ACCURACY_FINE);
             criteria.setHorizontalAccuracy(Criteria.ACCURACY_HIGH);
             criteria.setPowerRequirement(Criteria.POWER_HIGH);

             try {
                 locationManager.requestSingleUpdate(criteria, singleUpdatePI);
             } catch (SecurityException e) {
                log.error("Security exception: {}", e.getMessage());
             }
         }
     };

    /**
    * Broadcast receiver which detects a user has exit his circular stationary-region determined by the greater of stationaryLocation.getAccuracy() OR stationaryRadius
    */
    private BroadcastReceiver stationaryRegionReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String key = LocationManager.KEY_PROXIMITY_ENTERING;
            Boolean entering = intent.getBooleanExtra(key, false);

            if (entering) {
                log.debug("Entering stationary region");
                if (isMoving) {
                    setPace(false);
                }
            }
            else {
                log.debug("Exiting stationary region");
                // There MUST be a valid, recent location if this event-handler was called.
                Location location = getLastBestLocation();
                if (location != null) {
                    onExitStationaryRegion(location);
                }
            }
        }
    };

    public void onProviderDisabled(String provider) {
        // TODO Auto-generated method stub
        log.debug("Provider {} was disabled", provider);
    }

    public void onProviderEnabled(String provider) {
        // TODO Auto-generated method stub
        log.debug("Provider {} was enabled", provider);
    }

    public void onStatusChanged(String provider, int status, Bundle extras) {
        // TODO Auto-generated method stub
        log.debug("Provider {} status changed: {}", provider, status);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        log.info("Destroying DistanceFilterLocationProvider");

        try {
            locationManager.removeUpdates(this);
            locationManager.removeProximityAlert(stationaryRegionPI);
        } catch (SecurityException e) {
            //noop
        }
        alarmManager.cancel(stationaryAlarmPI);
        alarmManager.cancel(stationaryLocationPollingPI);

        unregisterReceiver(stationaryAlarmReceiver);
        unregisterReceiver(singleUpdateReceiver);
        unregisterReceiver(stationaryRegionReceiver);
        unregisterReceiver(stationaryLocationMonitorReceiver);

        wakeLock.release();
    }
}
