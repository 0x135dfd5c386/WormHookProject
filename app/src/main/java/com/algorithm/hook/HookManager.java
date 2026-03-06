package com.algorithm.hook;

import android.util.Log;

public class HookManager {
    private static final String TAG = "WormHook";

    // ── ดึง PID ของ target app ───────────────────────
    public static String getPid(String pkg) {
        return ShizukuHelper.runCommand("pidof " + pkg).trim();
    }

    // ── Attach hook เข้า target process ─────────────
    public static String attachToProcess(String targetPkg) {
        if (!ShizukuHelper.isAvailable())   return "❌ Shizuku ไม่พร้อม";
        if (!ShizukuHelper.hasPermission()) return "❌ ยังไม่ได้รับสิทธิ์ Shizuku";

        String pid = getPid(targetPkg);
        if (pid.isEmpty()) {
            return "❌ ไม่พบ process: " + targetPkg + "\nกรุณาเปิดแอพ target ก่อน";
        }

        Logger.save("HookAttach", new String[][]{
            {"target",  targetPkg},
            {"pid",     pid},
            {"status",  "attached"}
        });

        Log.d(TAG, "Attached to " + targetPkg + " PID=" + pid);
        return "✅ Attached to: " + targetPkg + "\n📌 PID: " + pid +
               "\n📁 Log: " + Logger.LOG_PATH;
    }

    // ── Monitor logcat ของ target app ────────────────
    public static String monitorLogs(String targetPkg) {
        if (!ShizukuHelper.isAvailable()) return "❌ Shizuku ไม่พร้อม";

        String pid = getPid(targetPkg);
        if (pid.isEmpty()) return "❌ ไม่พบ process: " + targetPkg;

        // clear logcat เก่า
        ShizukuHelper.runCommand("logcat -c");

        // ดึง log ของ target
        String logs = ShizukuHelper.runCommand(
            "logcat -d --pid=" + pid + " *:D 2>&1 | tail -100"
        );

        Logger.save("Monitor", new String[][]{
            {"target",     targetPkg},
            {"pid",        pid},
            {"log_length", String.valueOf(logs.length())}
        });

        return logs.isEmpty() ? "ยังไม่มี log จาก " + targetPkg : logs;
    }

    // ── Dump crypto ผ่าน logcat filter ───────────────
    public static String dumpCrypto(String targetPkg) {
        if (!ShizukuHelper.isAvailable()) return "❌ Shizuku ไม่พร้อม";

        String pid = getPid(targetPkg);
        if (pid.isEmpty()) return "❌ ไม่พบ process: " + targetPkg;

        String result = ShizukuHelper.runCommand(
            "logcat -d --pid=" + pid + " -s WormHook:D AESHOOK:D URL_HOOK:D 2>&1"
        );

        Logger.save("CryptoDump", new String[][]{
            {"target", targetPkg},
            {"pid",    pid},
            {"result", result.substring(0, Math.min(result.length(), 1000))}
        });

        return result.isEmpty()
            ? "ไม่พบ crypto log จาก " + targetPkg
              + "\nเปิดแอพและทำ action ที่ต้องการ dump ก่อน"
            : result;
    }

    // ── List installed apps ───────────────────────────
    public static String listPackages() {
        return ShizukuHelper.runCommand(
            "pm list packages -3 2>&1 | sed 's/package://' | sort"
        );
    }

    // ── ดูข้อมูล app ─────────────────────────────────
    public static String getAppInfo(String pkg) {
        String pid    = getPid(pkg);
        String dumpsys = ShizukuHelper.runCommand(
            "dumpsys package " + pkg + " 2>&1 | grep -E 'versionName|targetSdk|dataDir' | head -5"
        );
        return "📦 Package: " + pkg + "\n📌 PID: " +
               (pid.isEmpty() ? "ไม่ได้รัน" : pid) + "\n" + dumpsys;
    }
}
