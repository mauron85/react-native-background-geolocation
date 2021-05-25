package com.marianhello.bgloc;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.os.IBinder;
import android.support.test.InstrumentationRegistry;
import android.support.test.rule.ServiceTestRule;
import android.support.test.runner.AndroidJUnit4;
import android.support.v4.content.LocalBroadcastManager;

import com.marianhello.bgloc.provider.TestLocationProviderFactory;
import com.marianhello.bgloc.service.LocationServiceImpl;
import com.marianhello.bgloc.service.LocationServiceIntentBuilder;
import com.marianhello.bgloc.service.LocationServiceProxy;

import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Ignore;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeoutException;

import static org.hamcrest.core.Is.is;
import static org.hamcrest.core.IsEqual.equalTo;
import static org.junit.Assert.assertThat;

@RunWith(AndroidJUnit4.class)
public class LocationServiceProxyTest {

    @Rule
    public final ServiceTestRule mServiceRule = new ServiceTestRule();

    private LocationServiceProxy proxy;

    @Before
    public void setUp() {
        LocationServiceImpl.setLocationProviderFactory(new TestLocationProviderFactory());
        proxy = new LocationServiceProxy(InstrumentationRegistry.getTargetContext());
    }

    @After
    public void tearDown() {
        LocationServiceImpl.setLocationProviderFactory(null);
        Context ctx = InstrumentationRegistry.getTargetContext();
        ctx.stopService(new Intent(ctx, LocationServiceImpl.class));
    }

    @Test(timeout = 5000)
    public void testStart() throws InterruptedException {
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

        LocalBroadcastManager lbm = LocalBroadcastManager.getInstance(InstrumentationRegistry.getTargetContext());
        lbm.registerReceiver(serviceBroadcastReceiver, new IntentFilter(LocationServiceImpl.ACTION_BROADCAST));

        proxy.start();
        latch.await();
        lbm.unregisterReceiver(serviceBroadcastReceiver);
    }

    @Test(timeout = 5000)
    public void testStop() throws InterruptedException {
        final CountDownLatch latch = new CountDownLatch(1);
        BroadcastReceiver serviceBroadcastReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                Bundle bundle = intent.getExtras();
                int action = bundle.getInt("action");

                if (action == LocationServiceImpl.MSG_ON_SERVICE_STOPPED) {
                    latch.countDown();
                }
            }
        };

        LocalBroadcastManager lbm = LocalBroadcastManager.getInstance(InstrumentationRegistry.getTargetContext());
        lbm.registerReceiver(serviceBroadcastReceiver, new IntentFilter(LocationServiceImpl.ACTION_BROADCAST));

        proxy.start();
        proxy.stop();
        latch.await();
        lbm.unregisterReceiver(serviceBroadcastReceiver);
    }

    @Test(timeout = 5000)
    public void testConfigure() throws TimeoutException, InterruptedException {
        Context context = InstrumentationRegistry.getTargetContext();
        // Create the service Intent.
        Intent serviceIntent = new Intent(context, LocationServiceImpl.class);
        // Bind the service and grab a reference to the binder.
        IBinder binder = mServiceRule.bindService(serviceIntent);
        // Get the reference to the service, or you can call
        // public methods on the binder directly.
        LocationServiceImpl service = ((LocationServiceImpl.LocalBinder) binder).getService();

        Config config = Config.getDefault();
        config.setUrl("http://locationserviceproxy.net/");

        proxy.start();
        proxy.configure(config);
        Thread.sleep(4000);
        assertThat(service.getConfig().getUrl(), equalTo("http://locationserviceproxy.net/"));

        mServiceRule.unbindService();
    }

    @Test(timeout = 5000)
    public void testShouldNotBeRunningAfterConfigure() throws TimeoutException, InterruptedException {
        assertThat(proxy.isStarted(), is(false));
        assertThat(proxy.isRunning(), is(false));
        proxy.configure(Config.getDefault());
        assertThat(proxy.isStarted(), is(false));
        assertThat(proxy.isRunning(), is(false));
    }


    @Ignore
    @Test(timeout = 5000)
    public void testRegisterHeadlessTask() {
        // TODO
    }

    @Ignore
    @Test(timeout = 5000)
    public void testStartHeadlessTask() {
        // TODO
    }

    @Ignore
    @Test(timeout = 5000)
    public void testExecuteProviderCommand() {
        // TODO
    }

    @Ignore
    @Test(timeout = 5000)
    public void testStartForeground() {
        // TODO
    }

    @Ignore
    @Test(timeout = 5000)
    public void testStopForeground() {
        // TODO
    }
}
