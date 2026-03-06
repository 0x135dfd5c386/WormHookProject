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
