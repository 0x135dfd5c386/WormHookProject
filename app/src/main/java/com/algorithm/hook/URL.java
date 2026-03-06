package com.algorithm.hook;

import android.util.Log;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URLConnection;

public class URL {

    private static final String TAG = "URL_HOOK";
    private static final String LOG_PATH = "/sdcard/Algorithm/Logs.json";

    // ========== URLConnection ==========
    public static URLConnection openConnection(java.net.URL url) throws IOException {
        log("URLConnection", "URL", url.toString());
        return url.openConnection();
    }

    // ========== HttpURLConnection ==========
    public static void connect(HttpURLConnection conn) throws IOException {
        try {
            JSONObject entry = new JSONObject();
            entry.put("type", "HttpURLConnection");
            entry.put("timestamp", System.currentTimeMillis());
            entry.put("URL", conn.getURL().toString());
            entry.put("Method", conn.getRequestMethod());

            java.util.Map<String, java.util.List<String>> headers =
                conn.getRequestProperties();
            JSONObject hdrs = new JSONObject();
            for (java.util.Map.Entry<String, java.util.List<String>> h
                    : headers.entrySet()) {
                if (h.getKey() != null)
                    hdrs.put(h.getKey(), h.getValue().toString());
            }
            entry.put("Headers", hdrs);
            Log.d(TAG, entry.toString(2));
            writeToFile(entry);
        } catch (Exception ignored) {}
        conn.connect();
    }

    // ========== OkHttp3 Request.url() ==========
    public static okhttp3.HttpUrl url(okhttp3.Request request) {
        try {
            JSONObject entry = new JSONObject();
            entry.put("type", "OkHttp_Request");
            entry.put("timestamp", System.currentTimeMillis());
            entry.put("URL", request.url().toString());
            entry.put("Method", request.method());

            JSONObject hdrs = new JSONObject();
            for (int i = 0; i < request.headers().size(); i++) {
                hdrs.put(request.headers().name(i), request.headers().value(i));
            }
            entry.put("Headers", hdrs);
            Log.d(TAG, entry.toString(2));
            writeToFile(entry);
        } catch (Exception ignored) {}
        return request.url();
    }

    // ========== OkHttp3 newCall ==========
    public static okhttp3.Call newCall(okhttp3.OkHttpClient client,
                                       okhttp3.Request request) {
        try {
            JSONObject entry = new JSONObject();
            entry.put("type", "OkHttp_NewCall");
            entry.put("timestamp", System.currentTimeMillis());
            entry.put("URL", request.url().toString());
            entry.put("Method", request.method());
            Log.d(TAG, entry.toString(2));
            writeToFile(entry);
        } catch (Exception ignored) {}
        return client.newCall(request);
    }

    // ========== Helpers ==========
    private static void log(String type, String key, String value) {
        try {
            JSONObject entry = new JSONObject();
            entry.put("type", type);
            entry.put("timestamp", System.currentTimeMillis());
            entry.put(key, value);
            Log.d(TAG, entry.toString(2));
            writeToFile(entry);
        } catch (Exception ignored) {}
    }

    private static synchronized void writeToFile(JSONObject entry) {
        try {
            File dir = new File("/sdcard/Algorithm");
            if (!dir.exists()) dir.mkdirs();

            File file = new File(LOG_PATH);
            JSONArray array = new JSONArray();

            if (file.exists()) {
                StringBuilder sb = new StringBuilder();
                java.io.BufferedReader br =
                    new java.io.BufferedReader(new java.io.FileReader(file));
                String line;
                while ((line = br.readLine()) != null) sb.append(line);
                br.close();
                try { array = new JSONArray(sb.toString()); } catch (Exception ignored) {}
            }

            array.put(entry);
            FileWriter writer = new FileWriter(file, false);
            writer.write(array.toString(2));
            writer.close();
        } catch (IOException e) {
            Log.e(TAG, "Write error: " + e.getMessage());
        }
    }
}
