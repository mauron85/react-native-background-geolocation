package com.marianhello.bgloc.react;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.JavaOnlyArray;
import com.facebook.react.bridge.JavaOnlyMap;
import com.facebook.react.bridge.ReadableMap;
import com.marianhello.bgloc.Config;

import junit.framework.Assert;

import org.junit.Before;
import org.junit.Ignore;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.powermock.api.mockito.PowerMockito;
import org.powermock.core.classloader.annotations.PowerMockIgnore;
import org.powermock.core.classloader.annotations.PrepareForTest;
import org.robolectric.RobolectricTestRunner;

/**
 * Running following test suite is currently NOT possible!
 * Run instrumented test (androidTest) instead.
 *
 * TL;DR
 * It requires jni native lib "reactnativejni" (libreactnativejni.so),
 * which with lot of effort can be built for Linux.
 * However "libreactnativejni.so" has dependency on "libandroid.so" which
 * doesn't exist for Linux.

 * Related links::
 * [1] https://facebook.github.io/react-native/docs/building-from-source.html
 * [2] https://stackoverflow.com/questions/35275772/unsatisfiedlinkerror-when-unit-testing-writablenativemap/36504987#comment87006105_36504987
 * [3] https://stackoverflow.com/questions/50005396/libreactnativejni-so-is-built-as-elf32-i386-on-64bit-android-ndk/50007861#50007861
 * [5] https://github.com/SoftwareMansion/jsc-android-buildscripts
 */

@PrepareForTest({Arguments.class})
@RunWith(RobolectricTestRunner.class)
@PowerMockIgnore({"org.mockito.*", "org.robolectric.*", "android.*"})
public class ConfigMapperTest {
    @Before
    public void setUp() {
        PowerMockito.mockStatic(Arguments.class);
        PowerMockito.when(Arguments.createArray()).thenAnswer(new Answer<Object>() {
            @Override
            public Object answer(InvocationOnMock invocation) throws Throwable {
                return new JavaOnlyArray();
            }
        });
        PowerMockito.when(Arguments.createMap()).thenAnswer(new Answer<Object>() {
            @Override
            public Object answer(InvocationOnMock invocation) throws Throwable {
                return new JavaOnlyMap();
            }
        });
    }

    @Test
    @Ignore
    public void testDefaultToJSONObject() {
        Config config = Config.getDefault();
        ReadableMap map = ConfigMapper.toMap(config);

        Assert.assertEquals(config.getStationaryRadius(), map.getDouble("stationaryRadius"), 0f);
        Assert.assertEquals(config.getDistanceFilter().intValue(), map.getInt("distanceFilter"));
        Assert.assertEquals(config.getDesiredAccuracy().intValue(), map.getInt("desiredAccuracy"));
        Assert.assertEquals(config.isDebugging().booleanValue(), map.getBoolean("debug"));
        Assert.assertEquals(config.getNotificationTitle(), map.getString("notificationTitle"));
        Assert.assertEquals(config.getNotificationText(), map.getString("notificationText"));
        Assert.assertEquals(config.getStopOnTerminate().booleanValue(), map.getBoolean("stopOnTerminate"));
        Assert.assertEquals(config.getStartOnBoot().booleanValue(), map.getBoolean("startOnBoot"));
        Assert.assertEquals(config.getLocationProvider().intValue(), map.getInt("locationProvider"));
        Assert.assertEquals(config.getInterval().intValue(), map.getInt("interval"));
        Assert.assertEquals(config.getFastestInterval().intValue(), map.getInt("fastestInterval"));
        Assert.assertEquals(config.getActivitiesInterval().intValue(), map.getInt("activitiesInterval"));
        Assert.assertEquals(config.getNotificationIconColor(), map.getString("notificationIconColor"));
        Assert.assertEquals(config.getLargeNotificationIcon(), map.getString("notificationIconLarge"));
        Assert.assertEquals(config.getSmallNotificationIcon(), map.getString("notificationIconSmall"));
        Assert.assertEquals(config.getStartForeground().booleanValue(), map.getBoolean("startForeground"));
        Assert.assertEquals(config.getStopOnStillActivity().booleanValue(), map.getBoolean("stopOnStillActivity"));
        Assert.assertEquals(config.getUrl(), map.getString("url"));
        Assert.assertEquals(config.getSyncUrl(), map.getString("syncUrl"));
        Assert.assertEquals(config.getSyncThreshold().intValue(), map.getInt("syncThreshold"));
//        Assert.assertEquals(new JSONObject(config.getHttpHeaders()).toString(), map.getJSONObject("httpHeaders").toString());
        Assert.assertEquals(config.getMaxLocations().intValue(), map.getInt("maxLocations"));
//        Assert.assertEquals(LocationTemplateFactory.getDefault().toString(), map.get("postTemplate").toString());

    }
}