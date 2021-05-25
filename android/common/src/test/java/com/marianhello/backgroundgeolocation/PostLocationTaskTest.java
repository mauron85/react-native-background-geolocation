package com.marianhello.backgroundgeolocation;

import com.marianhello.bgloc.Config;
import com.marianhello.bgloc.ConnectivityListener;
import com.marianhello.bgloc.PostLocationTask;
import com.marianhello.bgloc.PostLocationTask.PostLocationTaskListener;
import com.marianhello.bgloc.data.BackgroundLocation;
import com.marianhello.bgloc.data.LocationDAO;

import org.junit.After;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;
import org.junit.runner.RunWith;
import org.mockito.MockitoAnnotations;
import org.robolectric.RobolectricTestRunner;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.ProtocolException;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLStreamHandler;
import java.net.URLStreamHandlerFactory;
import java.util.concurrent.RejectedExecutionException;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

/**
 * Test inspired by
 * https://github.com/google/agera/blob/master/extensions/net/src/test/java/com/google/android/agera/net/HttpFunctionsTest.java
 */
@RunWith(RobolectricTestRunner.class)
public class PostLocationTaskTest {
    private static final String TEST_PROTOCOL = "httptest";
    private static final String SLOW_PROTOCOL = "httpslow";

    private static HttpURLConnection mockHttpURLConnection;

    private ConnectivityListener connectivityListener = new ConnectivityListener() {
        @Override
        public boolean hasConnectivity() {
            return true;
        }
    };

    @Rule
    public final ExpectedException exception = ExpectedException.none();

    @BeforeClass
    public static void onlyOnce() throws Throwable {
        mockHttpURLConnection = mock(HttpURLConnection.class);
        URL.setURLStreamHandlerFactory(new URLStreamHandlerFactory() {
            @Override
            public URLStreamHandler createURLStreamHandler(final String s) {
                if (TEST_PROTOCOL.equals(s)) {
                    return new URLStreamHandler() {
                        @Override
                        protected URLConnection openConnection(final URL url) throws IOException {
                            return mockHttpURLConnection;
                        }
                    };
                }
                if (SLOW_PROTOCOL.equals(s)) {
                    return new URLStreamHandler() {
                        @Override
                        protected URLConnection openConnection(final URL url) throws IOException {
                            try {
                                Thread.sleep(100);
                            } catch (InterruptedException e) { /* noop */ }
                            return mockHttpURLConnection;
                        }
                    };
                }

                return null;
            }
        });
    }

    @Before
    public void setUp() {
        MockitoAnnotations.initMocks(this);
    }

    @After
    public void tearDown() {
        reset(mockHttpURLConnection);
    }

    @Test
    public void persistTask() throws ProtocolException, InterruptedException {
        LocationDAO mockDAO = mock(LocationDAO.class);

        PostLocationTaskListener mockListener = mock(PostLocationTaskListener.class);
        PostLocationTask task = new PostLocationTask(mockDAO,mockListener, connectivityListener);

        Config config = Config.getDefault();
        config.setUrl(TEST_PROTOCOL + "://localhost:3000/locations");
        config.setSyncUrl(TEST_PROTOCOL + "://localhost:3000/sync");
        task.setConfig(config);

        for (int i = 0; i < 10; i++) {
            task.add(new BackgroundLocation());
        }

        Thread.sleep(3000);
        verify(mockHttpURLConnection, times(10)).setRequestMethod("POST");
    }

    @Test
    public void persistTaskShouldRejectAfterShutdown() {
        exception.expect(RejectedExecutionException.class);

        LocationDAO mockDAO = mock(LocationDAO.class);

        PostLocationTaskListener mockListener = mock(PostLocationTaskListener.class);
        PostLocationTask task = new PostLocationTask(mockDAO,mockListener, connectivityListener);

        Config config = Config.getDefault();
        config.setUrl(TEST_PROTOCOL + "://localhost:3000/locations");
        config.setSyncUrl(TEST_PROTOCOL + "://localhost:3000/sync");
        task.setConfig(config);

        for (int i = 0; i < 10; i++) {
            task.add(new BackgroundLocation());
        }

        task.shutdown();
        task.add(new BackgroundLocation());
    }

    @Test
    public void persistTaskOnShutdown() throws ProtocolException, InterruptedException {
        LocationDAO mockDAO = mock(LocationDAO.class);

        PostLocationTaskListener mockListener = mock(PostLocationTaskListener.class);
        PostLocationTask task = new PostLocationTask(mockDAO,mockListener, connectivityListener);

        Config config = Config.getDefault();
        config.setUrl(SLOW_PROTOCOL + "://localhost:3000/locations");
        config.setSyncUrl(SLOW_PROTOCOL + "://localhost:3000/sync");
        task.setConfig(config);

        for (int i = 0; i < 10; i++) {
            task.add(new BackgroundLocation());
        }

        task.shutdown(600);

        Thread.sleep(3000);
        verify(mockHttpURLConnection, times(10)).setRequestMethod("POST");
    }

    @Test
    public void persistTaskSetUnsyncedOnShutdown() throws InterruptedException {
        LocationDAO mockDAO = mock(LocationDAO.class);

        PostLocationTaskListener mockListener = mock(PostLocationTaskListener.class);
        PostLocationTask task = new PostLocationTask(mockDAO,mockListener, connectivityListener);

        Config config = Config.getDefault();
        config.setUrl(SLOW_PROTOCOL + "://localhost:3000/locations");
        config.setSyncUrl(SLOW_PROTOCOL + "://localhost:3000/sync");
        task.setConfig(config);

        for (int i = 0; i < 10; i++) {
            task.add(new BackgroundLocation());
        }

        task.shutdown(1);

        Thread.sleep(3000);
        verify(mockDAO).deleteUnpostedLocations();
    }
}
