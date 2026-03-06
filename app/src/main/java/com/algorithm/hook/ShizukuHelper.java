package com.algorithm.hook;

import android.content.pm.PackageManager;
import android.util.Log;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import rikka.shizuku.Shizuku;

public class ShizukuHelper {
    private static final String TAG = "WormHook";
    public  static final int    REQUEST_CODE = 100;

    // ── ตรวจสอบสถานะ Shizuku ─────────────────────────
    public static boolean isAvailable() {
        try {
            return Shizuku.pingBinder();
        } catch (Exception e) {
            return false;
        }
    }

    public static boolean hasPermission() {
        try {
            if (Shizuku.isPreV11()) return false;
            return Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED;
        } catch (Exception e) {
            return false;
        }
    }

    public static void requestPermission() {
        try {
            if (!Shizuku.isPreV11()) {
                Shizuku.requestPermission(REQUEST_CODE);
            }
        } catch (Exception e) {
            Log.e(TAG, "requestPermission: " + e.getMessage());
        }
    }

    public static String getStatus() {
        if (!isAvailable())   return "❌ Shizuku ไม่ได้เปิดใช้งาน";
        if (!hasPermission()) return "⚠️ ยังไม่ได้รับสิทธิ์ Shizuku";
        return "✅ Shizuku พร้อมใช้งาน";
    }

    // ── รัน shell command ผ่าน Shizuku (ADB level) ───
    public static String runCommand(String cmd) {
        StringBuilder out = new StringBuilder();
        StringBuilder err = new StringBuilder();
        try {
            ProcessBuilder pb = new ProcessBuilder("sh", "-c", cmd);
            pb.redirectErrorStream(false);
            Process process = pb.start();

            BufferedReader stdout = new BufferedReader(
                new InputStreamReader(process.getInputStream()));
            BufferedReader stderr = new BufferedReader(
                new InputStreamReader(process.getErrorStream()));

            String line;
            while ((line = stdout.readLine()) != null) out.append(line).append("\n");
            while ((line = stderr.readLine()) != null) err.append(line).append("\n");

            process.waitFor();
        } catch (Exception e) {
            return "Error: " + e.getMessage();
        }
        String result = out.toString().trim();
        String errStr = err.toString().trim();
        if (result.isEmpty() && !errStr.isEmpty()) return "stderr: " + errStr;
        return result.isEmpty() ? "(no output)" : result;
    }
}
