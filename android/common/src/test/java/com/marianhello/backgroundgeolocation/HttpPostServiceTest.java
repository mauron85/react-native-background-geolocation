package com.marianhello.backgroundgeolocation;

import android.os.Build;

import com.marianhello.bgloc.HttpPostService;
import com.marianhello.bgloc.HttpPostService.UploadingProgressListener;

import org.json.JSONArray;
import org.json.JSONObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;
import org.junit.runner.RunWith;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.robolectric.RobolectricTestRunner;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.UnknownHostException;
import java.util.HashMap;
import java.util.Random;

import static org.hamcrest.core.Is.is;
import static org.junit.Assert.assertThat;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@RunWith(RobolectricTestRunner.class)
public class HttpPostServiceTest {
    @Mock
    HttpURLConnection mockHttpURLConnection;

    private static final int DEFAULT_SDK_INT = Build.VERSION.SDK_INT;

    @Rule
    public final ExpectedException exception = ExpectedException.none();

    @Before
    public void setUp() {
        MockitoAnnotations.initMocks(this);
    }

    @After
    public void cleanUp() {
        try {
            TestHelper.setFinalStatic(Build.VERSION.class.getField("SDK_INT"), DEFAULT_SDK_INT);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Test
    public void testPostJSONThrowsMalformedURLException() throws IOException {
        exception.expect(MalformedURLException.class);
        HttpPostService.postJSON(null, (JSONObject) null, null);
    }

    @Test
    public void testPostJSONThrowsUnknownHostException() throws IOException {
        exception.expect(UnknownHostException.class);
        HttpPostService.postJSON("http://unknown/json", (JSONObject) null, null);
    }

    @Test
    public void testPostJSONResult() throws IOException {
        final ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        when(mockHttpURLConnection.getOutputStream()).thenReturn(outputStream);
        when(mockHttpURLConnection.getResponseCode()).thenReturn(200);

        HttpPostService service = new HttpPostService(mockHttpURLConnection);
        assertThat(service.postJSON((JSONObject) new JSONObject(), null), is(200));
        verify(mockHttpURLConnection).setRequestMethod("POST");
    }


    @Test
    public void testPostJSONShouldPostHeaders() throws IOException {
        final ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        when(mockHttpURLConnection.getOutputStream()).thenReturn(outputStream);

        HashMap headers = new HashMap();
        headers.put("foo", "bar");

        HttpPostService service = new HttpPostService(mockHttpURLConnection);
        service.postJSON((JSONObject) null, headers);
        verify(mockHttpURLConnection).setRequestMethod("POST");
        verify(mockHttpURLConnection).setRequestProperty("Content-Type", "application/json");
        verify(mockHttpURLConnection).setRequestProperty("foo", "bar");
    }

    @Test
    public void testPostJSONObject() throws IOException {
        final ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        when(mockHttpURLConnection.getOutputStream()).thenReturn(outputStream);

        HttpPostService service = new HttpPostService(mockHttpURLConnection);
        service.postJSON(new JSONObject(), null);
        verify(mockHttpURLConnection).setRequestMethod("POST");
        assertThat(outputStream.toString(), is("{}"));
    }

    @Test
    public void testPostJSONArray() throws IOException {
        final ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        when(mockHttpURLConnection.getOutputStream()).thenReturn(outputStream);

        HttpPostService service = new HttpPostService(mockHttpURLConnection);
        service.postJSON(new JSONArray(), null);
        verify(mockHttpURLConnection).setRequestMethod("POST");
        assertThat(outputStream.toString(), is("[]"));
    }

    @Test
    public void testPostJSONObjectNull() throws IOException {
        final ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        when(mockHttpURLConnection.getOutputStream()).thenReturn(outputStream);

        HttpPostService service = new HttpPostService(mockHttpURLConnection);
        service.postJSON((JSONObject) null, null);
        verify(mockHttpURLConnection).setRequestMethod("POST");
        assertThat(outputStream.toString(), is("null"));
    }

    @Test
    public void testPostJSONArrayNull() throws IOException {
        final ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        when(mockHttpURLConnection.getOutputStream()).thenReturn(outputStream);

        HttpPostService service = new HttpPostService(mockHttpURLConnection);
        service.postJSON((JSONArray) null, null);
        verify(mockHttpURLConnection).setRequestMethod("POST");
        assertThat(outputStream.toString(), is("null"));
    }

    @Test
    public void testPostString() throws IOException {
        final ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        when(mockHttpURLConnection.getOutputStream()).thenReturn(outputStream);

        HttpPostService service = new HttpPostService(mockHttpURLConnection);
        service.postJSONString("test", null);
        verify(mockHttpURLConnection).setRequestMethod("POST");
        verify(mockHttpURLConnection).setRequestProperty("Content-Type", "application/json");
        assertThat(outputStream.toString(), is("test"));
    }

    @Test
    public void testPostStream() throws Exception {
        TestHelper.setFinalStatic(Build.VERSION.class.getField("SDK_INT"), Build.VERSION_CODES.KITKAT);

        final ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        when(mockHttpURLConnection.getOutputStream()).thenReturn(outputStream);
        when(mockHttpURLConnection.getResponseCode()).thenReturn(200);

        String body = "test";
        InputStream inputStream = new ByteArrayInputStream(body.getBytes());
        HashMap headers = new HashMap();
        headers.put("foo", "bar");

        HttpPostService service = new HttpPostService(mockHttpURLConnection);
        assertThat(service.postJSONFile(inputStream, headers, null), is(200));
        verify(mockHttpURLConnection).setRequestMethod("POST");
        verify(mockHttpURLConnection).setRequestProperty("foo", "bar");
        verify(mockHttpURLConnection).setFixedLengthStreamingMode((long) body.length());
        //verify(mockHttpURLConnection).setChunkedStreamingMode(0);
        assertThat(outputStream.toString(), is("test"));
    }

    @Test
    public void testJSONPostFile() throws Exception {
        TestHelper.setFinalStatic(Build.VERSION.class.getField("SDK_INT"), Build.VERSION_CODES.KITKAT);

        final ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        when(mockHttpURLConnection.getOutputStream()).thenReturn(outputStream);
        when(mockHttpURLConnection.getResponseCode()).thenReturn(200);

        File file = new File("./README.md");

        HashMap headers = new HashMap();
        headers.put("foo", "bar");

        HttpPostService service = new HttpPostService(mockHttpURLConnection);
        assertThat(service.postJSONFile(file, headers, null), is(200));
        verify(mockHttpURLConnection).setRequestMethod("POST");
        verify(mockHttpURLConnection).setRequestProperty("Content-Type", "application/json");
        verify(mockHttpURLConnection).setRequestProperty("foo", "bar");
        verify(mockHttpURLConnection).setFixedLengthStreamingMode((long) file.length());
        //verify(mockHttpURLConnection).setChunkedStreamingMode(0);
    }

    @Test
    public void testJSONPostFileProgressListener() throws IOException {
        HttpPostService service = new HttpPostService(mockHttpURLConnection);
        UploadingProgressListener mockListener = mock(UploadingProgressListener.class);

        final ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        when(mockHttpURLConnection.getOutputStream()).thenReturn(outputStream);

        int bodySize = HttpPostService.BUFFER_SIZE * 5;
        byte[] body = new byte[bodySize];
        new Random().nextBytes(body);
        InputStream inputStream = new ByteArrayInputStream(body);

        service.postJSONFile(inputStream, null, mockListener);
        InOrder inOrder = inOrder(mockListener);
        inOrder.verify(mockListener).onProgress(20);
        inOrder.verify(mockListener).onProgress(40);
        inOrder.verify(mockListener).onProgress(60);
        inOrder.verify(mockListener).onProgress(80);
        inOrder.verify(mockListener).onProgress(100);
    }
}
