package com.marianhello.bgloc;

import android.util.Log;

import java.util.Map;
import java.util.Iterator;
import org.json.JSONObject;

import java.net.URL;
import java.net.HttpURLConnection;
import java.io.OutputStreamWriter;

public class HttpPostService {

    private static final String TAG = "BGPlugin/HttpPostService";

    public static boolean postJSON(String url, JSONObject json, Map headers)	{
        try {
            Log.d(TAG, "Posting json: " + json.toString() + " to url: " + url + " headers: " + headers.toString());

            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
            // conn.setConnectTimeout(5000);
            conn.setChunkedStreamingMode(0);
            conn.setDoOutput(true);
            // conn.setDoInput(true);
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
            Iterator<Map.Entry<String, String>> it = headers.entrySet().iterator();
            while (it.hasNext()) {
                Map.Entry<String, String> pair = it.next();
                conn.setRequestProperty(pair.getKey(), pair.getValue());
            }

            OutputStreamWriter os = new OutputStreamWriter(conn.getOutputStream());
            os.write(json.toString());
            os.flush();
            os.close();

            Log.d(TAG, "Posting json response code: " + conn.getResponseCode());

            if (conn.getResponseCode() == HttpURLConnection.HTTP_OK) {
                return true;
            }
            
            return false;

        } catch (Throwable e) {
            Log.w(TAG, "Exception posting json: " + e);
            e.printStackTrace();
            return false;
        }
    }
}
