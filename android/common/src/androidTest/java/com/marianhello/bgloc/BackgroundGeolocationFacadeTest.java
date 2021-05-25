package com.marianhello.bgloc;

import android.support.test.InstrumentationRegistry;
import android.support.test.runner.AndroidJUnit4;

import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.provider.TestLocationProviderFactory;
import com.marianhello.bgloc.service.LocationServiceImpl;

import org.junit.After;
import org.junit.Ignore;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.concurrent.CountDownLatch;

@RunWith(AndroidJUnit4.class)
public class BackgroundGeolocationFacadeTest {
    @After
    public void tearDown() {
        LocationServiceImpl.setLocationProviderFactory(null);
    }

    @Ignore("Ignore test waiting for issue to be closed")
    @Test(timeout = 5000)
    public void testOnLocationChanged() throws InterruptedException {
        final CountDownLatch latch = new CountDownLatch(1);
        LocationServiceImpl.setLocationProviderFactory(new TestLocationProviderFactory());

        class FacadeDelegate extends TestPluginDelegate {
            @Override
            public void onLocationChanged(BackgroundLocation location) {
                latch.countDown();
            }
        }

        TestPluginDelegate delegate = new FacadeDelegate();

        final BackgroundGeolocationFacade facade = new BackgroundGeolocationFacade(
                InstrumentationRegistry.getContext(), delegate);

        facade.start();
        latch.await();
    }
}
