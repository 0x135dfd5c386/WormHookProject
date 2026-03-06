#!/bin/bash
# =======================================================
# WormHookProject - Setup Script
# สร้างโปรเจค Hook สำหรับ Dump AES Key, IV & HTTP Requests
# =======================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║        WormHookProject Setup             ║"
echo "║   AESHOOK + URL Hook + GitHub Deploy     ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# =======================================================
# ตรวจสอบ git config
# =======================================================
info "ตรวจสอบ git config..."
GIT_USER=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -z "$GIT_USER" ] || [ -z "$GIT_EMAIL" ]; then
    warn "ยังไม่ได้ตั้งค่า git user"
    echo -n "  กรอกชื่อ GitHub ของคุณ: "
    read GIT_USER
    echo -n "  กรอก Email GitHub ของคุณ: "
    read GIT_EMAIL
    git config --global user.name "$GIT_USER"
    git config --global user.email "$GIT_EMAIL"
    success "ตั้งค่า git user เรียบร้อย"
else
    success "git user: $GIT_USER <$GIT_EMAIL>"
fi

# =======================================================
# เข้าไปที่โปรเจค
# =======================================================
cd ~/WormHookProject || error "ไม่พบโฟลเดอร์ ~/WormHookProject"
info "Working directory: $(pwd)"

# =======================================================
# สร้างโครงสร้าง directories
# =======================================================
info "สร้างโครงสร้างโปรเจค..."
mkdir -p app/src/main/java/com/algorithm/hook
mkdir -p app/src/main/res/values
mkdir -p gradle/wrapper
mkdir -p .github/workflows
success "สร้าง directories เรียบร้อย"

# =======================================================
# settings.gradle
# =======================================================
info "สร้าง settings.gradle..."
cat > settings.gradle << 'EOF'
rootProject.name = "WormHookProject"
include ':app'
EOF
success "settings.gradle"

# =======================================================
# build.gradle (root)
# =======================================================
info "สร้าง build.gradle (root)..."
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
info "สร้าง app/build.gradle..."
cat > app/build.gradle << 'EOF'
plugins {
    id 'com.android.library'
}
android {
    compileSdk 34
    defaultConfig {
        minSdk 21
        targetSdk 28
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}
dependencies {
    compileOnly 'com.squareup.okhttp3:okhttp:4.9.3'
}
EOF
success "app/build.gradle"

# =======================================================
# AndroidManifest.xml
# =======================================================
info "สร้าง AndroidManifest.xml..."
cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.algorithm.hook">

    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.INTERNET"/>

</manifest>
EOF
success "AndroidManifest.xml"

# =======================================================
# AESHOOK.java
# =======================================================
info "สร้าง AESHOOK.java..."
cat > app/src/main/java/com/algorithm/hook/AESHOOK.java << 'EOF'
package com.algorithm.hook;

import android.util.Base64;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.security.Key;
import java.security.spec.AlgorithmParameterSpec;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

public class AESHOOK {

    private static final String TAG = "AESHOOK";
    private static final String LOG_PATH = "/sdcard/Algorithm/Logs.json";

    // ========== SecretKeySpec ==========
    public static SecretKeySpec SecretKeySpec(byte[] key, String algorithm) {
        String keyBase64 = Base64.encodeToString(key, Base64.NO_WRAP);
        String keyHex    = bytesToHex(key);
        log("SecretKeySpec", new String[][]{
            {"Algorithm", algorithm},
            {"Key_Base64", keyBase64},
            {"Key_Hex",    keyHex},
            {"Key_UTF8",   safeUtf8(key)}
        });
        return new SecretKeySpec(key, algorithm);
    }

    // ========== IvParameterSpec ==========
    public static IvParameterSpec IvParameterSpec(byte[] iv) {
        String ivBase64 = Base64.encodeToString(iv, Base64.NO_WRAP);
        String ivHex    = bytesToHex(iv);
        log("IvParameterSpec", new String[][]{
            {"IV_Base64", ivBase64},
            {"IV_Hex",    ivHex},
            {"IV_UTF8",   safeUtf8(iv)}
        });
        return new IvParameterSpec(iv);
    }

    // ========== Cipher.getInstance ==========
    public static Cipher getInstance(String transformation) throws Exception {
        log("CipherAlgorithm", new String[][]{
            {"Transformation", transformation}
        });
        return Cipher.getInstance(transformation);
    }

    // ========== Cipher.init ==========
    public static void init(Cipher cipher, int mode, Key key,
                            AlgorithmParameterSpec params) throws Exception {
        String modeStr = (mode == Cipher.ENCRYPT_MODE) ? "ENCRYPT" : "DECRYPT";
        byte[] keyBytes = key.getEncoded();
        log("CipherInit", new String[][]{
            {"Mode",       modeStr},
            {"Key_Base64", Base64.encodeToString(keyBytes, Base64.NO_WRAP)},
            {"Key_Hex",    bytesToHex(keyBytes)},
            {"Key_UTF8",   safeUtf8(keyBytes)}
        });
        cipher.init(mode, key, params);
    }

    // ========== doFinal ==========
    public static byte[] doFinal(Cipher cipher, byte[] input) throws Exception {
        byte[] output = cipher.doFinal(input);
        log("doFinal", new String[][]{
            {"Input_Base64",  Base64.encodeToString(input, Base64.NO_WRAP)},
            {"Input_Hex",     bytesToHex(input)},
            {"Output_Base64", Base64.encodeToString(output, Base64.NO_WRAP)},
            {"Output_Hex",    bytesToHex(output)}
        });
        return output;
    }

    // ========== Logger ==========
    private static void log(String type, String[][] fields) {
        try {
            JSONObject entry = new JSONObject();
            entry.put("type", type);
            entry.put("timestamp", System.currentTimeMillis());
            for (String[] field : fields) {
                entry.put(field[0], field[1]);
            }
            Log.d(TAG, entry.toString(2));
            writeToFile(entry);
        } catch (Exception e) {
            Log.e(TAG, "Log error: " + e.getMessage());
        }
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

    // ========== Helpers ==========
    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) sb.append(String.format("%02X", b));
        return sb.toString();
    }

    private static String safeUtf8(byte[] bytes) {
        try { return new String(bytes, "UTF-8"); }
        catch (Exception e) { return "[non-utf8]"; }
    }
}
EOF
success "AESHOOK.java"

# =======================================================
# URL.java
# =======================================================
info "สร้าง URL.java..."
cat > app/src/main/java/com/algorithm/hook/URL.java << 'EOF'
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
EOF
success "URL.java"

# =======================================================
# gradle-wrapper.properties
# =======================================================
info "สร้าง gradle-wrapper.properties..."
cat > gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.1.1-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
success "gradle-wrapper.properties"

# =======================================================
# gradlew
# =======================================================
info "สร้าง gradlew..."
cat > gradlew << 'GRADLEW'
#!/bin/sh
GRADLE_OPTS="${GRADLE_OPTS:-"-Xmx512m"}"
exec gradle "$@"
GRADLEW
chmod +x gradlew
success "gradlew (chmod +x)"

# =======================================================
# .gitignore
# =======================================================
info "สร้าง .gitignore..."
cat > .gitignore << 'EOF'
*.iml
.gradle
/local.properties
/.idea
.DS_Store
/build
/captures
.externalNativeBuild
.cxx
local.properties
app/build/
EOF
success ".gitignore"

# =======================================================
# README.md
# =======================================================
info "สร้าง README.md..."
cat > README.md << 'EOF'
# WormHookProject

Hook สำหรับ Dump AES Key, IV, Algorithm, doFinal และ HTTP Headers/URL

## Log Path
```
/sdcard/Algorithm/Logs.json
```

## Hook Classes
| Class | หน้าที่ |
|---|---|
| `com.algorithm.hook.AESHOOK` | ดัก SecretKeySpec, IvParameterSpec, getInstance, init, doFinal |
| `com.algorithm.hook.URL` | ดัก URLConnection, HttpURLConnection, OkHttp3 |

## Smali Patch Patterns

### SecretKeySpec
```
(invoke-direct \{([pv]\d+), ([pv]\d+), ([pv]\d+)\}, Ljavax/crypto/spec/SecretKeySpec;-><init>\(\[BLjava/lang/String;\)V)
→ $1\n    invoke-static {$3, $4}, Lcom/algorithm/hook/AESHOOK;->SecretKeySpec([BLjava/lang/String;)V
```

### IvParameterSpec
```
(invoke-direct \{([pv]\d+), ([pv]\d+)\}, Ljavax/crypto/spec/IvParameterSpec;-><init>\(\[B\)V)
→ $1\n    invoke-static {$3}, Lcom/algorithm/hook/AESHOOK;->IvParameterSpec([B)V
```

### Cipher.getInstance
```
invoke-static \{([pv]\d+)\}, Ljavax/crypto/Cipher;->getInstance\(Ljava/lang/String;\)Ljavax/crypto/Cipher;
→ invoke-static {$1}, Lcom/algorithm/hook/AESHOOK;->getInstance(Ljava/lang/String;)Ljavax/crypto/Cipher;
```

### Cipher.init
```
invoke-virtual \{([pv]\d+), ([pv]\d+), ([pv]\d+), ([pv]\d+)\}, Ljavax/crypto/Cipher;->init\(ILjava/security/Key;Ljava/security/spec/AlgorithmParameterSpec;\)V
→ invoke-static {$1, $2, $3, $4}, Lcom/algorithm/hook/AESHOOK;->init(Ljavax/crypto/Cipher;ILjava/security/Key;Ljava/security/spec/AlgorithmParameterSpec;)V
```

### doFinal
```
invoke-virtual \{([pv]\d+), ([pv]\d+)\}, Ljavax/crypto/Cipher;->doFinal\(\[B\)\[B
→ invoke-static {$1, $2}, Lcom/algorithm/hook/AESHOOK;->doFinal(Ljavax/crypto/Cipher;[B)[B
```

### OkHttp3 newCall
```
invoke-virtual \{([pv]\d+), ([pv]\d+)\}, Lokhttp3/OkHttpClient;->newCall\(Lokhttp3/Request;\)Lokhttp3/Call;
→ invoke-static {$1, $2}, Lcom/algorithm/hook/URL;->newCall(Lokhttp3/OkHttpClient;Lokhttp3/Request;)Lokhttp3/Call;
```
EOF
success "README.md"

# =======================================================
# GitHub Actions workflow
# =======================================================
info "สร้าง GitHub Actions workflow..."
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
      - name: Checkout code
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

      - name: Build Release AAR
        run: ./gradlew :app:assembleRelease

      - name: Upload AAR
        uses: actions/upload-artifact@v4
        with:
          name: hook-release
          path: app/build/outputs/aar/app-release.aar
EOF
success "GitHub Actions workflow"

# =======================================================
# Git commit & push
# =======================================================
echo ""
info "กำลัง commit และ push ไป GitHub..."
git add -A

# ตรวจว่ามีอะไรให้ commit ไหม
if git diff --cached --quiet; then
    warn "ไม่มีการเปลี่ยนแปลง ข้าม commit"
else
    git commit -m "feat: add AESHOOK + URL hook classes with full AES/HTTP logging"
    git push
    success "Push ไป GitHub เรียบร้อย!"
fi

# =======================================================
# สรุป
# =======================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✅ เสร็จสมบูรณ์!               ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  📁 โปรเจค : ~/WormHookProject"
echo -e "  📄 Log    : /sdcard/Algorithm/Logs.json"
echo -e "  🔧 Hook   : com.algorithm.hook.AESHOOK"
echo -e "  🌐 Hook   : com.algorithm.hook.URL"
echo -e "  🚀 GitHub : Actions จะ build อัตโนมัติ"
echo ""
echo -e "${CYAN}โครงสร้างโปรเจค:${NC}"
find . -not -path './.git/*' -not -path './app/build/*' \
       -not -name '*.class' | sort | sed 's|[^/]*/|  |g'
