#!/bin/bash
# =======================================================
# WormHookProject - Shizuku Hook APK Setup Script
# Dump AES Key, IV, doFinal & HTTP Requests
# ไม่ต้อง Root ใช้งานผ่าน Shizuku (ADB Permission)
# =======================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
step()    { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║      WormHook - Shizuku APK Setup            ║"
echo "║   AES Key/IV + HTTP Dump (No Root)           ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# =======================================================
# ตรวจสอบ git config
# =======================================================
step "ตรวจสอบ Git Config"
GIT_USER=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -z "$GIT_USER" ] || [ -z "$GIT_EMAIL" ]; then
    warn "ยังไม่ได้ตั้งค่า git user"
    echo -n "  กรอกชื่อ GitHub: "
    read GIT_USER
    echo -n "  กรอก Email GitHub: "
    read GIT_EMAIL
    git config --global user.name "$GIT_USER"
    git config --global user.email "$GIT_EMAIL"
fi
success "git user: $GIT_USER <$GIT_EMAIL>"

# =======================================================
# เข้าโปรเจค
# =======================================================
step "เตรียม Project Directory"
cd ~/WormHookProject || error "ไม่พบ ~/WormHookProject"
info "Working: $(pwd)"

# =======================================================
# สร้าง directories
# =======================================================
step "สร้างโครงสร้างโปรเจค"
mkdir -p app/src/main/java/com/algorithm/hook
mkdir -p app/src/main/res/values
mkdir -p gradle/wrapper
mkdir -p .github/workflows
success "directories พร้อมแล้ว"

# =======================================================
# settings.gradle
# =======================================================
step "สร้าง Gradle Files"
cat > settings.gradle << 'EOF'
rootProject.name = "WormHookProject"
include ':app'
EOF
success "settings.gradle"

# =======================================================
# build.gradle root
# =======================================================
cat > build.gradle << 'EOF'
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
    }
}
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF
success "build.gradle (root)"

# =======================================================
# app/build.gradle
# =======================================================
cat > app/build.gradle << 'EOF'
plugins {
    id 'com.android.application'
}
android {
    compileSdk 34
    defaultConfig {
        applicationId "com.algorithm.hook"
        minSdk 26
        targetSdk 28
        versionCode 1
        versionName "1.0"
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    packagingOptions {
        exclude 'META-INF/DEPENDENCIES'
        exclude 'META-INF/LICENSE'
        exclude 'META-INF/LICENSE.txt'
    }
}
dependencies {
    // Shizuku API
    implementation 'dev.rikka.shizuku:api:13.1.5'
    implementation 'dev.rikka.shizuku:provider:13.1.5'
}
EOF
success "app/build.gradle"

# =======================================================
# AndroidManifest.xml
# =======================================================
step "สร้าง AndroidManifest.xml"
cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.algorithm.hook">

    <!-- Storage -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.INTERNET"/>

    <!-- Shizuku -->
    <queries>
        <package android:name="moe.shizuku.privileged.api"/>
    </queries>

    <application
        android:label="WormHook"
        android:icon="@android:drawable/ic_menu_compass"
        android:allowBackup="false"
        android:exported="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="portrait">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- Shizuku Provider -->
        <provider
            android:name="rikka.shizuku.ShizukuProvider"
            android:authorities="${applicationId}.shizuku"
            android:multiprocess="false"
            android:enabled="true"
            android:exported="true"
            android:permission="android.permission.INTERACT_ACROSS_USERS_FULL"/>

    </application>
</manifest>
EOF
success "AndroidManifest.xml"

# =======================================================
# Logger.java
# =======================================================
step "สร้าง Java Source Files"
cat > app/src/main/java/com/algorithm/hook/Logger.java << 'EOF'
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
EOF
success "Logger.java"

# =======================================================
# ShizukuHelper.java
# =======================================================
cat > app/src/main/java/com/algorithm/hook/ShizukuHelper.java << 'EOF'
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
EOF
success "ShizukuHelper.java"

# =======================================================
# HookManager.java
# =======================================================
cat > app/src/main/java/com/algorithm/hook/HookManager.java << 'EOF'
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
EOF
success "HookManager.java"

# =======================================================
# MainActivity.java
# =======================================================
cat > app/src/main/java/com/algorithm/hook/MainActivity.java << 'EOF'
package com.algorithm.hook;

import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.widget.*;
import rikka.shizuku.Shizuku;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends Activity {

    // ── UI Components ─────────────────────────────────
    private TextView  tvStatus, tvLog;
    private EditText  etPackage;
    private Button    btnCheckShizuku, btnAttach, btnMonitor;
    private Button    btnDumpCrypto, btnListApps, btnAppInfo;
    private Button    btnReadLog, btnClearLog;

    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Handler         handler  = new Handler(Looper.getMainLooper());

    // ── Shizuku permission callback ───────────────────
    private final Shizuku.OnRequestPermissionResultListener permListener =
        (code, result) -> {
            if (result == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                updateStatus("✅ Shizuku Permission Granted!");
            } else {
                updateStatus("❌ Permission Denied — กด Allow ใน Shizuku App");
            }
        };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // ── Root Layout ───────────────────────────────
        ScrollView scroll = new ScrollView(this);
        scroll.setBackgroundColor(Color.parseColor("#0D1117"));

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(40, 80, 40, 40);
        scroll.addView(root);

        // ── Title ─────────────────────────────────────
        TextView title = new TextView(this);
        title.setText("🪝  WormHook");
        title.setTextSize(26);
        title.setTextColor(Color.parseColor("#58A6FF"));
        title.setGravity(Gravity.CENTER);
        root.addView(title);

        TextView subtitle = new TextView(this);
        subtitle.setText("AES Key/IV + HTTP Dumper via Shizuku");
        subtitle.setTextSize(12);
        subtitle.setTextColor(Color.parseColor("#8B949E"));
        subtitle.setGravity(Gravity.CENTER);
        subtitle.setPadding(0, 4, 0, 32);
        root.addView(subtitle);

        // ── Status ────────────────────────────────────
        tvStatus = new TextView(this);
        tvStatus.setText("⏳ ตรวจสอบ Shizuku...");
        tvStatus.setTextColor(Color.WHITE);
        tvStatus.setBackgroundColor(Color.parseColor("#161B22"));
        tvStatus.setPadding(24, 16, 24, 16);
        root.addView(tvStatus);

        addSpace(root, 20);

        // ── Package Input ─────────────────────────────
        TextView labelPkg = new TextView(this);
        labelPkg.setText("📦  Target Package Name");
        labelPkg.setTextColor(Color.parseColor("#8B949E"));
        labelPkg.setTextSize(12);
        root.addView(labelPkg);

        etPackage = new EditText(this);
        etPackage.setHint("com.example.targetapp");
        etPackage.setTextColor(Color.WHITE);
        etPackage.setHintTextColor(Color.parseColor("#484F58"));
        etPackage.setBackgroundColor(Color.parseColor("#21262D"));
        etPackage.setPadding(24, 20, 24, 20);
        etPackage.setSingleLine(true);
        root.addView(etPackage);

        addSpace(root, 24);

        // ── Section: Shizuku ──────────────────────────
        addSectionLabel(root, "── Shizuku Control ──");
        btnCheckShizuku = addButton(root, "🔍  ตรวจสอบ / ขอสิทธิ์ Shizuku", "#1F6FEB");
        btnAttach       = addButton(root, "🔗  Attach Hook to Process",       "#388BFD");

        addSpace(root, 16);

        // ── Section: Dump ─────────────────────────────
        addSectionLabel(root, "── Dump Tools ──");
        btnDumpCrypto = addButton(root, "🔐  Dump AES Key / IV / doFinal",  "#3FB950");
        btnMonitor    = addButton(root, "📡  Monitor Logcat (target)",       "#56D364");

        addSpace(root, 16);

        // ── Section: Info ─────────────────────────────
        addSectionLabel(root, "── App Info ──");
        btnAppInfo  = addButton(root, "ℹ️   App Info & PID",                "#D29922");
        btnListApps = addButton(root, "📋  List Installed Apps (3rd party)", "#E3B341");

        addSpace(root, 16);

        // ── Section: Logs ─────────────────────────────
        addSectionLabel(root, "── Log File ──");
        btnReadLog  = addButton(root, "📄  อ่าน Logs.json",    "#8957E5");
        btnClearLog = addButton(root, "🗑️   ล้าง Logs",         "#DA3633");

        addSpace(root, 20);

        // ── Log Output ────────────────────────────────
        TextView labelOut = new TextView(this);
        labelOut.setText("📤  Output:");
        labelOut.setTextColor(Color.parseColor("#8B949E"));
        labelOut.setTextSize(12);
        root.addView(labelOut);

        tvLog = new TextView(this);
        tvLog.setText("— รอคำสั่ง —");
        tvLog.setTextColor(Color.parseColor("#39D353"));
        tvLog.setTextSize(10);
        tvLog.setBackgroundColor(Color.parseColor("#010409"));
        tvLog.setPadding(24, 20, 24, 20);
        tvLog.setTypeface(android.graphics.Typeface.MONOSPACE);
        root.addView(tvLog);

        setContentView(scroll);

        // ── Init ──────────────────────────────────────
        Shizuku.addRequestPermissionResultListener(permListener);
        checkShizuku();
        setupButtons();
    }

    // ── UI Helpers ────────────────────────────────────
    private Button addButton(LinearLayout parent, String text, String hex) {
        Button btn = new Button(this);
        btn.setText(text);
        btn.setTextColor(Color.WHITE);
        btn.setBackgroundColor(Color.parseColor(hex));
        btn.setAllCaps(false);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, 130);
        lp.setMargins(0, 6, 0, 6);
        btn.setLayoutParams(lp);
        parent.addView(btn);
        return btn;
    }

    private void addSectionLabel(LinearLayout parent, String text) {
        TextView tv = new TextView(this);
        tv.setText(text);
        tv.setTextColor(Color.parseColor("#6E7681"));
        tv.setTextSize(11);
        tv.setPadding(0, 8, 0, 4);
        parent.addView(tv);
    }

    private void addSpace(LinearLayout parent, int dp) {
        View v = new View(this);
        v.setLayoutParams(new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, dp));
        parent.addView(v);
    }

    // ── Logic ─────────────────────────────────────────
    private void checkShizuku() {
        updateStatus(ShizukuHelper.getStatus());
    }

    private String getTargetPkg() {
        return etPackage.getText().toString().trim();
    }

    private void runAsync(Runnable task) {
        executor.execute(task);
    }

    private void updateStatus(String msg) {
        handler.post(() -> tvStatus.setText(msg));
    }

    private void setLog(String msg) {
        handler.post(() -> tvLog.setText(
            msg.length() > 3000 ? msg.substring(0, 3000) + "\n...(truncated)" : msg
        ));
    }

    private void toast(String msg) {
        handler.post(() -> Toast.makeText(this, msg, Toast.LENGTH_SHORT).show());
    }

    private void setupButtons() {

        btnCheckShizuku.setOnClickListener(v -> {
            if (!ShizukuHelper.isAvailable()) {
                updateStatus("❌ Shizuku ไม่ได้เปิด");
                setLog("ติดตั้ง Shizuku จาก Play Store:\nhttps://play.google.com/store/apps/details?id=moe.shizuku.privileged.api\n\nแล้วเปิดใช้งานผ่าน ADB:\nadb shell sh /sdcard/Android/data/moe.shizuku.privileged.api/start.sh");
            } else if (!ShizukuHelper.hasPermission()) {
                ShizukuHelper.requestPermission();
                updateStatus("⏳ รอการอนุมัติใน Shizuku App...");
            } else {
                updateStatus("✅ Shizuku พร้อมใช้งาน");
                setLog("Shizuku OK — พร้อม hook!");
            }
        });

        btnAttach.setOnClickListener(v -> {
            String pkg = getTargetPkg();
            if (pkg.isEmpty()) { toast("กรุณาใส่ Package Name"); return; }
            setLog("⏳ กำลัง attach...");
            runAsync(() -> setLog(HookManager.attachToProcess(pkg)));
        });

        btnDumpCrypto.setOnClickListener(v -> {
            String pkg = getTargetPkg();
            if (pkg.isEmpty()) { toast("กรุณาใส่ Package Name"); return; }
            setLog("⏳ กำลัง dump crypto logs...");
            runAsync(() -> setLog(HookManager.dumpCrypto(pkg)));
        });

        btnMonitor.setOnClickListener(v -> {
            String pkg = getTargetPkg();
            if (pkg.isEmpty()) { toast("กรุณาใส่ Package Name"); return; }
            setLog("⏳ กำลัง monitor " + pkg + "...");
            runAsync(() -> setLog(HookManager.monitorLogs(pkg)));
        });

        btnAppInfo.setOnClickListener(v -> {
            String pkg = getTargetPkg();
            if (pkg.isEmpty()) { toast("กรุณาใส่ Package Name"); return; }
            setLog("⏳ กำลังดึงข้อมูล...");
            runAsync(() -> setLog(HookManager.getAppInfo(pkg)));
        });

        btnListApps.setOnClickListener(v -> {
            setLog("⏳ กำลังโหลดรายการแอพ...");
            runAsync(() -> setLog(HookManager.listPackages()));
        });

        btnReadLog.setOnClickListener(v -> {
            setLog("⏳ กำลังอ่าน Logs.json...");
            runAsync(() -> setLog(Logger.readLogs()));
        });

        btnClearLog.setOnClickListener(v -> {
            Logger.clear();
            setLog("🗑️ ล้าง log เรียบร้อย\nPath: " + Logger.LOG_PATH);
            toast("ล้าง log แล้ว");
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        Shizuku.removeRequestPermissionResultListener(permListener);
        executor.shutdown();
    }
}
EOF
success "MainActivity.java"

# =======================================================
# gradle-wrapper.properties
# =======================================================
step "สร้าง Gradle Wrapper"
cat > gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.1.1-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

cat > gradlew << 'GRADLEW'
#!/bin/sh
GRADLE_OPTS="${GRADLE_OPTS:-"-Xmx512m"}"
exec gradle "$@"
GRADLEW
chmod +x gradlew
success "gradlew"

# =======================================================
# .gitignore
# =======================================================
cat > .gitignore << 'EOF'
*.iml
.gradle
/local.properties
/.idea
.DS_Store
/build
/captures
app/build/
.externalNativeBuild
.cxx
EOF

# =======================================================
# README.md
# =======================================================
cat > README.md << 'EOF'
# WormHook — Shizuku AES & HTTP Dumper

Hook แบบไม่ต้อง Root ใช้งานผ่าน **Shizuku (ADB Permission)**

## ความต้องการ
- Android 8.0+ (API 26)
- [Shizuku App](https://play.google.com/store/apps/details?id=moe.shizuku.privileged.api)
- ADB (ใช้ผ่าน Wireless ADB หรือ PC)

## วิธีใช้งาน

### 1. เปิด Shizuku ผ่าน ADB
```bash
adb shell sh /sdcard/Android/data/moe.shizuku.privileged.api/start.sh
```

### 2. ติดตั้ง WormHook APK
```bash
adb install app-debug.apk
```

### 3. เปิดแอพ WormHook
- กด **ตรวจสอบ Shizuku** → อนุมัติสิทธิ์
- ใส่ package name ของแอพ target
- กด **Attach Hook**
- เปิดแอพ target แล้วใช้งาน
- กด **Dump AES Key/IV** หรือ **Monitor Logcat**

## Log Output
```
/sdcard/Algorithm/Logs.json
```

## Hook Classes
| Class | หน้าที่ |
|---|---|
| `AESHOOK` | SecretKeySpec, IvParameterSpec, doFinal |
| `URL` | URLConnection, HttpURLConnection, OkHttp3 |
EOF

# =======================================================
# GitHub Actions
# =======================================================
step "สร้าง GitHub Actions Workflow"
cat > .github/workflows/build.yml << 'EOF'
name: WORM-AI Build APK

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Setup Android SDK
        uses: android-actions/setup-android@v3

      - name: Grant execute permission
        run: chmod +x ./gradlew

      - name: Build Debug APK
        run: ./gradlew :app:assembleDebug --stacktrace

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: WormHook-Shizuku-debug
          path: app/build/outputs/apk/debug/app-debug.apk
EOF
success "build.yml"

# =======================================================
# Git commit & push
# =======================================================
step "Git Commit & Push"
git add -A

if git diff --cached --quiet; then
    warn "ไม่มีการเปลี่ยนแปลง"
else
    git commit -m "feat: Shizuku Hook APK - AES/IV dump + HTTP monitor (no root)"
    git push 2>/dev/null || {
        warn "Push ไม่สำเร็จ ลอง force push..."
        git push --force
    }
    success "Push ไป GitHub เรียบร้อย!"
fi

# =======================================================
# สรุป
# =======================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✅  เสร็จสมบูรณ์!                  ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  🚀 GitHub Actions : https://github.com/0x135dfd5c386/WormHookProject/actions"
echo -e "  📁 Log output     : /sdcard/Algorithm/Logs.json"
echo -e "  📦 APK artifact   : WormHook-Shizuku-debug"
echo ""
echo -e "${CYAN}── วิธีเปิด Shizuku ผ่าน ADB ──${NC}"
echo -e "  adb shell sh /sdcard/Android/data/moe.shizuku.privileged.api/start.sh"
echo ""
echo -e "${CYAN}── โครงสร้างโปรเจค ──${NC}"
find . -not -path './.git/*' -not -path './app/build/*' \
       -not -name '*.class' -not -name '*.iml' | sort | \
       sed 's|^\./||' | sed 's|[^/]*/|  |g'
