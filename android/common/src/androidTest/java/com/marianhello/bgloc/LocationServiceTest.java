package com.marianhello.bgloc;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.location.Location;
import android.os.Bundle;
import android.os.IBinder;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.test.InstrumentationRegistry;
import android.support.test.rule.ServiceTestRule;
import android.support.test.runner.AndroidJUnit4;
import android.support.v4.content.LocalBroadcastManager;

import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.provider.MockLocationProvider;
import com.marianhello.bgloc.provider.TestLocationProviderFactory;
import com.marianhello.bgloc.service.LocationServiceImpl;
import com.marianhello.bgloc.service.LocationServiceIntentBuilder;
import com.marianhello.bgloc.data.LocationTransform;

import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.Arrays;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import static org.hamcrest.core.Is.is;
import static org.hamcrest.core.Is.isA;
import static org.hamcrest.core.IsEqual.equalTo;
import static org.hamcrest.core.IsInstanceOf.any;
import static org.junit.Assert.assertThat;

@RunWith(AndroidJUnit4.class)
public class LocationServiceTest {

    @Rule
    public final ServiceTestRule mServiceRule = new ServiceTestRule();

    private LocationServiceImpl mService;
    private TestLocationProviderFactory mLocationProviderFactory = new TestLocationProviderFactory();

    @Before
    public void setUp() {
        mLocationProviderFactory.setProvider(new MockLocationProvider());
        LocationServiceImpl.setLocationProviderFactory(mLocationProviderFactory);

        try {
            Context context = InstrumentationRegistry.getTargetContext();
            // Create the mService Intent.
            Intent serviceIntent = new Intent(context, LocationServiceImpl.class);
            // Bind the mService and grab a reference to the binder.
            IBinder binder = mServiceRule.bindService(serviceIntent);
            // Get the reference to the mService, or you can call
            // public methods on the binder directly.
            mService = ((LocationServiceImpl.LocalBinder) binder).getService();
        } catch (TimeoutException e) {
            throw new RuntimeException(e);
        }
    }

    @After
    public void tearDown() {
        LocationServiceImpl.setLocationProviderFactory(null);
        LocationServiceImpl.setLocationTransform(null);
        mService.stop();
        mServiceRule.unbindService();
    }

    @Test(timeout = 5000)
    public void testWithStartedService() throws TimeoutException, InterruptedException {
        final Context context = InstrumentationRegistry.getTargetContext();
        final CountDownLatch latch = new CountDownLatch(1);

        BroadcastReceiver serviceBroadcastReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                Bundle bundle = intent.getExtras();
                int action = bundle.getInt("action");

                if (action == LocationServiceImpl.MSG_ON_SERVICE_STARTED) {
                    latch.countDown();
                }
            }
        };
        LocalBroadcastManager.getInstance(context)
                .registerReceiver(serviceBroadcastReceiver, new IntentFilter(LocationServiceImpl.ACTION_BROADCAST));


        //assertThat(mService.isBound(), is(false));
        assertThat(mService.isRunning(), is(false));
        Intent intent = LocationServiceIntentBuilder
                .getInstance(context)
                .setCommand(0)
                .build();
        mServiceRule.startService(intent);

        latch.await(5, TimeUnit.SECONDS);
        assertThat(mService.isRunning(), is(true));
    }

    @Test(timeout = 5000)
    public void testWithBoundService() {
        // Verify that the mService is working correctly.
        assertThat(mService.isRunning(), is(false));
        assertThat(mService.isBound(), is(true));
        assertThat(mService.getConfig(), is(any(Config.class)));
    }

    @Test(timeout = 5000)
    public void testStartStop() {
        assertThat(mService.isRunning(), is(false));
        mService.start();
        assertThat(mService.isRunning(), is(true));
        mService.stop();
        assertThat(mService.isRunning(), is(false));
    }

    @Test(timeout = 5000)
    public void testOnLocation() throws InterruptedException {
        final CountDownLatch latch = new CountDownLatch(1);
        BroadcastReceiver serviceBroadcastReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                Bundle bundle = intent.getExtras();
                int action = bundle.getInt("action");

                if (action == LocationServiceImpl.MSG_ON_LOCATION) {
                    bundle.setClassLoader(LocationServiceImpl.class.getClassLoader());
                    BackgroundLocation location = bundle.getParcelable("payload");

                    assertThat(location, isA(BackgroundLocation.class));
                    assertThat(location.getAltitude(), equalTo(666.0));
                    latch.countDown();
                }
            }
        };

        LocalBroadcastManager lbm = LocalBroadcastManager.getInstance(InstrumentationRegistry.getTargetContext());
        lbm.registerReceiver(serviceBroadcastReceiver, new IntentFilter(LocationServiceImpl.ACTION_BROADCAST));

        mService.start();
        BackgroundLocation location = new BackgroundLocation();
        location.setAltitude(666.0);
        mService.onLocation(location);

        latch.await();
        lbm.unregisterReceiver(serviceBroadcastReceiver);
    }

    @Test(timeout = 5000)
    public void testOnLocationOnStoppedService() throws InterruptedException {
        final CountDownLatch latch = new CountDownLatch(3);
        BroadcastReceiver serviceBroadcastReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                Bundle bundle = intent.getExtras();
                int action = bundle.getInt("action");

                if (action == LocationServiceImpl.MSG_ON_SERVICE_STARTED) {
                    latch.countDown();
                    mService.stop();
                    //mService.onDestroy();
                }
                if (action == LocationServiceImpl.MSG_ON_SERVICE_STOPPED) {
                    latch.countDown();
                    mService.onLocation(new BackgroundLocation());
                }
                if (action == LocationServiceImpl.MSG_ON_LOCATION) {
                    latch.countDown();
                }
            }
        };

        LocalBroadcastManager lbm = LocalBroadcastManager.getInstance(InstrumentationRegistry.getTargetContext());
        lbm.registerReceiver(serviceBroadcastReceiver, new IntentFilter(LocationServiceImpl.ACTION_BROADCAST));

        Config config = Config.getDefault();
        config.setStartForeground(false);

        MockLocationProvider provider = new MockLocationProvider();
        Location location = new Location("gps");
        location.setProvider("mock");
        location.setElapsedRealtimeNanos(2000000000L);
        location.setAltitude(100);
        location.setLatitude(49);
        location.setLongitude(5);
        location.setAccuracy(105);
        location.setSpeed(50);
        location.setBearing(1);

        provider.setMockLocations(Arrays.asList(location));
        mLocationProviderFactory.setProvider(provider);

        mService.setLocationProviderFactory(mLocationProviderFactory);
        mService.configure(config);
        mService.start();

        latch.await();
        lbm.unregisterReceiver(serviceBroadcastReceiver);
    }

    @Test(timeout = 5000)
    public void testTransform() throws InterruptedException {
        final CountDownLatch latch = new CountDownLatch(1);
        BroadcastReceiver serviceBroadcastReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                Bundle bundle = intent.getExtras();
                int action = bundle.getInt("action");

                if (action == LocationServiceImpl.MSG_ON_LOCATION) {
                    latch.countDown();

                    bundle.setClassLoader(LocationServiceImpl.class.getClassLoader());
                    BackgroundLocation location = (BackgroundLocation) bundle.getParcelable("payload");

                    assertThat(location.getAltitude(), equalTo(8848.0));
                }
            }
        };

        LocalBroadcastManager lbm = LocalBroadcastManager.getInstance(InstrumentationRegistry.getTargetContext());
        lbm.registerReceiver(serviceBroadcastReceiver, new IntentFilter(LocationServiceImpl.ACTION_BROADCAST));

        LocationServiceImpl.setLocationTransform(new LocationTransform() {
            @Nullable
            @Override
            public BackgroundLocation transformLocationBeforeCommit(@NonNull Context context, @NonNull BackgroundLocation location) {
                location.setAltitude(8848.0);
                return location;
            }
        });

        mService.onLocation(new BackgroundLocation());
        latch.await();
        lbm.unregisterReceiver(serviceBroadcastReceiver);
        LocationServiceImpl.setLocationTransform(null);
    }
}
