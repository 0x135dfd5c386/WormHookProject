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
