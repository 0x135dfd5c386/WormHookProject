package com.algorithm.hook;

import android.util.Base64;
import android.util.Log;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.*;

public class Logger {
    private static final String TAG    = "WormHook";
    public  static final String LOG_DIR  = "/sdcard/Algorithm";
    public  static final String LOG_PATH = "/sdcard/Algorithm/Logs.json";

    // บันทึก log แบบ key-value fields
    public static synchronized void save(String type, String[][] fields) {
        try {
            JSONObject entry = new JSONObject();
            entry.put("type", type);
            entry.put("timestamp", System.currentTimeMillis());
            for (String[] f : fields) {
                entry.put(f[0], f[1]);
            }
            Log.d(TAG, "[" + type + "] " + entry.toString());
            writeToFile(entry);
        } catch (Exception e) {
            Log.e(TAG, "Logger.save error: " + e.getMessage());
        }
    }

    private static void writeToFile(JSONObject entry) throws Exception {
        File dir = new File(LOG_DIR);
        if (!dir.exists()) dir.mkdirs();

        File file = new File(LOG_PATH);
        JSONArray arr = new JSONArray();

        if (file.exists()) {
            StringBuilder sb = new StringBuilder();
            BufferedReader br = new BufferedReader(new FileReader(file));
            String line;
            while ((line = br.readLine()) != null) sb.append(line);
            br.close();
            try { arr = new JSONArray(sb.toString()); } catch (Exception ignored) {}
        }

        arr.put(entry);
        FileWriter fw = new FileWriter(file, false);
        fw.write(arr.toString(2));
        fw.close();
    }

    public static void clear() {
        try {
            new File(LOG_PATH).delete();
        } catch (Exception ignored) {}
    }

    // ── Helpers ──────────────────────────────────────
    public static String toHex(byte[] b) {
        if (b == null) return "";
        StringBuilder sb = new StringBuilder();
        for (byte x : b) sb.append(String.format("%02X", x));
        return sb.toString();
    }

    public static String toBase64(byte[] b) {
        if (b == null) return "";
        return Base64.encodeToString(b, Base64.NO_WRAP);
    }

    public static String toUtf8(byte[] b) {
        if (b == null) return "";
        try { return new String(b, "UTF-8"); }
        catch (Exception e) { return "[non-utf8]"; }
    }

    public static String readLogs() {
        try {
            File file = new File(LOG_PATH);
            if (!file.exists()) return "ยังไม่มี log";
            StringBuilder sb = new StringBuilder();
            BufferedReader br = new BufferedReader(new FileReader(file));
            String line;
            while ((line = br.readLine()) != null) sb.append(line).append("\n");
            br.close();
            return sb.toString();
        } catch (Exception e) {
            return "Error: " + e.getMessage();
        }
    }
}
