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
