package com.marianhello.bgloc;

import com.facebook.react.modules.network.OkHttpClientProvider;
import com.squareup.okhttp.Headers;
import com.squareup.okhttp.MediaType;
import com.squareup.okhttp.OkHttpClient;
import com.squareup.okhttp.Request;
import com.squareup.okhttp.RequestBody;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.Map;

public class HttpPostService {

    public static final OkHttpClient OK_HTTP_CLIENT = OkHttpClientProvider.getOkHttpClient();

    public static int postJSON(String url, Object json, Map<String, String> headers) throws IOException {
        Headers.Builder headersBuilder = new Headers.Builder();
        for (Map.Entry<String, String> pair : headers.entrySet()) {
            headersBuilder.set(pair.getKey(), pair.getValue());
        }

        Request.Builder builder = new Request.Builder();
        RequestBody body = RequestBody.create(
            MediaType.parse("application/json"),
            json.toString());
        return OK_HTTP_CLIENT.newCall(builder.url(url)
                                             .post(body)
                                             .headers(headersBuilder.build())
                                             .build()).execute().code();
    }

    public static int postFile(String url, File file, Map<String, String> headers)
        throws Exception {
        Request.Builder builder = new Request.Builder();
        Headers.Builder headersBuilder = new Headers.Builder();

        for (Map.Entry<String, String> pair : headers.entrySet()) {
            headersBuilder.set(pair.getKey(), pair.getValue());
        }
        String content = convertStreamToString(new FileInputStream(file));
        RequestBody body = RequestBody.create(
            MediaType.parse("application/json"),
            content);
        return OK_HTTP_CLIENT.newCall(builder.url(url)
                                             .post(body)
                                             .headers(headersBuilder.build())
                                             .build()).execute().code();
    }

    private static String convertStreamToString(InputStream is) throws Exception {
        BufferedReader reader = new BufferedReader(new InputStreamReader(is));
        StringBuilder sb = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            sb.append(line).append("\n");
        }
        reader.close();
        return sb.toString();
    }
}
