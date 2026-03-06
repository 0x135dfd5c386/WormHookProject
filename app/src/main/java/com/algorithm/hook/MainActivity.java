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
