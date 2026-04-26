# AnTsiSeCare — Android 版本需求與相容性說明

**Application ID：** `tw.antsicare.app`  
**最低支援版本：** Android 5.0（API 21 / Lollipop）  
**目標 SDK：** Android 14（API 34）  
**最佳體驗版本：** Android 10（API 29）+  
**支援架構：** arm64-v8a、armeabi-v7a、x86_64

---

## 目錄

1. [支援版本概覽](#1-支援版本概覽)
2. [各 Android 版本功能相容矩陣](#2-各-android-版本功能相容矩陣)
3. [Android 5–6（API 21–23，最低支援）](#3-android-56api-2123最低支援)
4. [Android 7–8（API 24–27）](#4-android-78api-2427)
5. [Android 9–10（API 28–29）](#5-android-910api-2829)
6. [Android 11–12（API 30–32）](#6-android-1112api-3032)
7. [Android 13（API 33）](#7-android-13api-33)
8. [Android 14（API 34，目標版本）](#8-android-14api-34目標版本)
9. [Android 15（API 35）](#9-android-15api-35)
10. [AndroidManifest 權限清單](#10-androidmanifest-權限清單)
11. [裝置硬體需求](#11-裝置硬體需求)
12. [支援裝置型號清單](#12-支援裝置型號清單)
13. [不支援裝置與版本](#13-不支援裝置與版本)
14. [版本測試矩陣](#14-版本測試矩陣)
15. [升級相容性注意事項](#15-升級相容性注意事項)
16. [Gradle 版本設定速查](#16-gradle-版本設定速查)

---

## 1. 支援版本概覽

| Android 版本 | API Level | 代號 | 支援狀態 | 市佔（台灣估計）|
|-------------|-----------|------|----------|----------------|
| Android 4.4 以下 | ≤ 19 | KitKat | ❌ 不支援 | < 1% |
| Android 5.0–5.1 | 21–22 | Lollipop | ⚠️ 基本支援 | < 2% |
| Android 6.0 | 23 | Marshmallow | ⚠️ 基本支援 | < 2% |
| Android 7.0–7.1 | 24–25 | Nougat | ✅ 支援 | ~3% |
| Android 8.0–8.1 | 26–27 | Oreo | ✅ 支援 | ~5% |
| Android 9 | 28 | Pie | ✅ 完整支援 | ~8% |
| Android 10 | 29 | Q | ✅ 完整支援（推薦最低）| ~12% |
| Android 11 | 30 | R | ✅ 完整支援 | ~15% |
| Android 12–12L | 31–32 | S | ✅ 完整支援 | ~18% |
| Android 13 | 33 | Tiramisu | ✅ 完整支援 + 最佳化 | ~20% |
| Android 14 | 34 | Upside Down Cake | ✅ 目標版本 | ~15% |
| Android 15 | 35 | Vanilla Ice Cream | ✅ 已驗證 | ~2% |

> **最低需求設為 API 21** 是為涵蓋仍在使用舊款平價 Android 手機的外籍看護族群；**建議使用者升級至 Android 10+** 以獲得最佳體驗。

---

## 2. 各 Android 版本功能相容矩陣

| 功能模組 | API 21–22 | API 23–25 | API 26–28 | API 29–32 | API 33+ |
|----------|-----------|-----------|-----------|-----------|---------|
| OTP 手機登入 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 照護日誌（讀寫）| ✅ | ✅ | ✅ | ✅ | ✅ |
| SOS 緊急求救 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 推播通知（基本）| ✅ | ✅ | ✅ | ✅ | ✅ |
| 推播通知（頻道）| ❌ | ❌ | ✅ API 26+ | ✅ | ✅ |
| 推播通知（運行時授權）| ❌ 自動 | ❌ 自動 | ❌ 自動 | ❌ 自動 | ✅ 需明確授權 |
| 用藥管理提醒 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 精確鬧鐘（用藥）| ✅ | ✅ | ✅ | ✅ | ⚠️ 需 SCHEDULE_EXACT_ALARM |
| OSM 地圖（flutter_map）| ✅ | ✅ | ✅ | ✅ | ✅ |
| OSRM 路線計算 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 離線模式（Hive）| ✅ | ✅ | ✅ | ✅ | ✅ |
| 語音輸入 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 背景同步 | ⚠️ 受限 | ⚠️ 受限 | ✅ JobScheduler | ✅ WorkManager | ✅ WorkManager |
| 深色模式 | ❌ | ❌ | ❌ | ✅ API 29+ | ✅ |
| 相片存取（媒體）| ✅ READ_EXTERNAL_STORAGE | ✅ | ✅ | ✅ | ✅ READ_MEDIA_IMAGES |
| 藍牙（未使用）| — | — | — | — | — |
| 分割畫面 | ❌ | ✅ API 24+ | ✅ | ✅ | ✅ |
| 鍵盤高度感知 | ❌ | ❌ | ❌ | ❌ | ✅ WindowInsets |


---

## 3. Android 5–6（API 21–23，最低支援）

### 3.1 支援原因

設定 `minSdkVersion 21` 的理由：
- Flutter 3.22 官方最低需求為 API 21
- Firebase Android SDK 33.x 最低需求 API 21
- 台灣仍有部分外籍看護使用平價舊機（如 OPPO A 系列舊款）

### 3.2 已知限制

| 限制項目 | API Level | 影響 | 補償方案 |
|----------|-----------|------|----------|
| 執行時期權限（Runtime Permission）| API 23+ 才需 | API 21–22 安裝時自動授予 | 無需處理 |
| 通知頻道（Notification Channel）| API 26+ 才有 | 舊版無法分類通知 | 降級為單一通知 |
| JobScheduler 完整版 | API 21 基本 / 23+ 完整 | 背景同步不穩定 | WorkManager 自動降級處理 |
| `VectorDrawable` 動畫 | API 21 限制 | 部分動畫降級 | 已使用 `AppCompatImageView` 補償 |
| WebP 動畫格式 | API 28+ 支援 | — | 使用靜態 PNG 替代 |

### 3.3 build.gradle 設定

```groovy
android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
        compileSdkVersion 34
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true   // API 21 需要 MultiDex
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

### 3.4 Application 類別設定（API 21 MultiDex）

```kotlin
// android/app/src/main/kotlin/.../MainApplication.kt
class MainApplication : FlutterApplication() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }
}
```

---

## 4. Android 7–8（API 24–27）

### 4.1 新增支援功能

| 功能 | API | 說明 |
|------|-----|------|
| 分割畫面（Split Screen）| 24 | 照服員可同時開啟照護日誌與訊息 |
| 直接回覆通知（Direct Reply）| 24 | 推播通知可直接回覆（未實作，保留擴充）|
| 自適應圖示（Adaptive Icons）| 26 | 主畫面圖示適應不同形狀 |
| 通知頻道（Notification Channels）| 26 | 分類：用藥提醒、SOS警報、照護異常 |
| 後台執行限制 | 26 | Background Execution Limits，影響 SyncService |
| 自動填入（Autofill）| 26 | 支援 OTP 自動填入 |
| 畫中畫（PiP）| 26 | 未使用，保留未來影像通話擴充 |

### 4.2 通知頻道設定（API 26+）

```kotlin
// android/app/src/main/kotlin/.../NotificationHelper.kt
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
    val channels = listOf(
        NotificationChannel(
            "medication_reminder",
            "用藥提醒",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "定時提醒服藥"
            enableVibration(true)
            setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION), null)
        },
        NotificationChannel(
            "sos_alert",
            "SOS 緊急警報",
            NotificationManager.IMPORTANCE_MAX
        ).apply {
            description = "緊急求救通知"
            enableLights(true)
            lightColor = Color.RED
        },
        NotificationChannel(
            "care_abnormal",
            "照護異常警示",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "照護項目異常通知"
        },
        NotificationChannel(
            "sync_status",
            "資料同步",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "背景資料同步狀態"
        }
    )
    val notificationManager = getSystemService(NotificationManager::class.java)
    channels.forEach { notificationManager.createNotificationChannel(it) }
}
```

### 4.3 自適應圖示設定（API 26+）

```xml
<!-- android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml -->
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
```

---

## 5. Android 9–10（API 28–29）

### 5.1 重要政策變更（API 28）

| 變更 | 影響 | 處理方式 |
|------|------|----------|
| 禁止明文 HTTP 流量 | OSM tile、OSRM 均使用 HTTPS，無影響 | 已符合 |
| 前台服務需聲明 | SyncService 若使用前台服務需加入 manifest | 已加入 `FOREGROUND_SERVICE` |
| 不允許後台啟動 Activity | SOS 觸發時需使用通知跳轉 | 使用 PendingIntent |
| `Process.killProcess` 限制 | — | 無影響 |

### 5.2 深色模式支援（API 29+）

```kotlin
// Android 10+ 跟隨系統深色模式
// Flutter 已透過 ThemeData 自動處理
AppCompatDelegate.setDefaultNightMode(
    AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
)
```

對應 Flutter 設定：
```dart
// main.dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system,  // 跟隨系統
)
```

### 5.3 Scoped Storage 前期（API 29）

```xml
<!-- AndroidManifest.xml — API 29 過渡設定 -->
<application
    android:requestLegacyExternalStorage="true">
    <!-- API 29 暫時允許舊版儲存存取，API 30+ 此屬性無效 -->
</application>
```

### 5.4 WorkManager 背景同步（API 28+ 最佳化）

```kotlin
val syncRequest = PeriodicWorkRequestBuilder<SyncWorker>(
    repeatInterval = 6,
    repeatIntervalTimeUnit = TimeUnit.HOURS
)
    .setConstraints(
        Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .setRequiresBatteryNotLow(true)
            .build()
    )
    .build()

WorkManager.getInstance(context)
    .enqueueUniquePeriodicWork(
        "antsicare_sync",
        ExistingPeriodicWorkPolicy.KEEP,
        syncRequest
    )
```

---

## 6. Android 11–12（API 30–32）

### 6.1 Android 11（API 30）重要變更

| 變更 | 影響 | 處理方式 |
|------|------|----------|
| Scoped Storage 強制執行 | 不能直接存取外部儲存 | 使用 `MediaStore` API |
| 套件可見性（Package Visibility）| 無法直接查詢其他 APP | 在 manifest 加入 `<queries>` |
| 一次性權限 | 位置/麥克風/相機為一次性授權 | 每次使用前重新確認 |
| 背景位置權限 | 需分兩步驟申請 | 已實作二階段申請流程 |
| 自動重置權限 | 長期未使用的 APP 權限自動重置 | 引導使用者重新授權 |

```xml
<!-- AndroidManifest.xml — 套件可見性（API 30+）-->
<queries>
    <!-- 撥打電話 -->
    <intent>
        <action android:name="android.intent.action.DIAL"/>
    </intent>
    <!-- 開啟地圖（Google Maps）-->
    <intent>
        <action android:name="android.intent.action.VIEW"/>
        <data android:scheme="geo"/>
    </intent>
    <!-- 開啟瀏覽器（OSM Web）-->
    <intent>
        <action android:name="android.intent.action.VIEW"/>
        <data android:scheme="https"/>
    </intent>
</queries>
```

### 6.2 Android 12（API 31–32）重要變更

| 變更 | 影響 | 處理方式 |
|------|------|----------|
| `SCHEDULE_EXACT_ALARM` 權限 | 精確用藥提醒需宣告 | 已加入 manifest |
| 通知 trampoline 限制 | 通知點擊不能跳轉 Service/BroadcastReceiver | 改用 Activity PendingIntent |
| Splash Screen API | 系統強制顯示 Splash | 已設定 `windowSplashScreenBackground` |
| `PendingIntent` 可變性 | 需明確指定 FLAG_MUTABLE / FLAG_IMMUTABLE | 已更新所有 PendingIntent |
| 藍牙權限拆分 | — | 本 APP 未使用藍牙 |
| Material You（動態顏色）| 系統可能覆蓋主題色 | 已設定 `colorPrimary` 防止覆蓋 |

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"
    android:maxSdkVersion="32" />

<!-- API 33+ 改用 USE_EXACT_ALARM（無需使用者授權）-->
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```

---

## 7. Android 13（API 33）

### 7.1 重要變更

| 變更 | 影響 | 處理方式 |
|------|------|----------|
| **推播通知須明確授權** | 使用者需主動允許通知 | 初次啟動時請求 `POST_NOTIFICATIONS` |
| 相片/影片細粒度權限 | `READ_MEDIA_IMAGES` 取代 `READ_EXTERNAL_STORAGE` | 已依版本分別申請 |
| 語言偏好（Per-app Language）| 使用者可個別設定 APP 語言 | 與 `easy_localization` 整合 |
| 主題圖示（Themed Icons）| 圖示可跟隨桌布色彩 | 已提供單色版圖示 |
| Wi-Fi 權限拆分 | — | 無影響 |

### 7.2 通知授權（API 33 最重要變更）

```kotlin
// 在 MainActivity 或初始化流程中請求通知權限
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
    ActivityCompat.requestPermissions(
        this,
        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
        NOTIFICATION_PERMISSION_CODE
    )
}
```

對應 Flutter（使用 `permission_handler`）：
```dart
if (Platform.isAndroid) {
  final status = await Permission.notification.request();
  if (status.isDenied) {
    // 引導使用者至設定頁開啟
  }
}
```

### 7.3 細粒度媒體權限

```kotlin
// 依 API 版本申請對應權限
val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
    arrayOf(
        Manifest.permission.READ_MEDIA_IMAGES,
        Manifest.permission.READ_MEDIA_VIDEO
    )
} else {
    arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
}
```

---

## 8. Android 14（API 34，目標版本）

### 8.1 重要變更

| 變更 | 影響 | 處理方式 |
|------|------|----------|
| 精確鬧鐘預設關閉 | 用藥提醒需額外引導授權 | 引導至「鬧鐘與提醒」設定 |
| 前台服務類型強制宣告 | SyncService 需指定 `dataSync` 類型 | 已更新 manifest |
| 相片存取選擇器 | 系統相片選擇器（Photo Picker）| 使用 `image_picker` 套件自動處理 |
| 隱式 Intent 限制 | 不可使用隱式 Intent 啟動元件 | 已改用明確 Intent |
| `minSdkVersion` 升至 23 的趨勢 | Google Play 2024 新 APP 建議最低 API 23 | 現行設 21，計畫於 v2.0 升至 23 |

### 8.2 前台服務類型宣告

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />

<service
    android:name=".SyncForegroundService"
    android:foregroundServiceType="dataSync"
    android:exported="false" />
```

### 8.3 精確鬧鐘授權引導

```dart
// 用藥提醒設定時，若 Android 14+ 需引導授權
Future<void> checkExactAlarmPermission() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 34) {
      // 開啟系統「鬧鐘與提醒」設定頁
      await openAppSettings();
    }
  }
}
```

---

## 9. Android 15（API 35）

### 9.1 主要變更（預計影響）

| 變更 | 影響 | 處理方式 |
|------|------|----------|
| Edge-to-Edge 強制執行 | 內容延伸至系統列區域 | Flutter 已透過 `SafeArea` 處理 |
| 健康資料 API | 可整合步數、心率（未來擴充）| 規劃 v3.0 整合 |
| NFC 改善 | — | 本 APP 未使用 NFC |
| PDF Viewer API | 可內嵌顯示照護報告 PDF | 規劃 v2.0 使用 |
| `predictiveBackNavigationEnabled` | 手勢返回預覽 | Flutter 3.22 已支援 |

### 9.2 Edge-to-Edge 適配

```xml
<!-- android/app/src/main/res/values/styles.xml -->
<style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
    <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    <item name="android:windowEdgeToEdge">true</item>
</style>
```


---

## 10. AndroidManifest 權限清單

以下為 `android/app/src/main/AndroidManifest.xml` 完整權限設定：

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="tw.antsicare.app">

    <!-- ── 網路（Firestore、OSM、OSRM）── -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />

    <!-- ── 位置（資源地圖、導航）── -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <!-- 背景位置（API 29+，需分兩步驟申請）-->
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

    <!-- ── 相機（照護日誌附圖）── -->
    <uses-permission android:name="android.permission.CAMERA" />

    <!-- ── 媒體存取 ── -->
    <!-- API 21–32：舊版儲存權限 -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <!-- API 33+：細粒度媒體權限 -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />

    <!-- ── 推播通知 ── -->
    <!-- API 33+ 需明確授權 -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <!-- 用藥精確提醒 API 32 以下 -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"
        android:maxSdkVersion="32" />
    <!-- 用藥精確提醒 API 33+ -->
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />

    <!-- ── 前台服務（背景同步）── -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />

    <!-- ── 開機自啟（用藥提醒重新排程）── -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

    <!-- ── 振動（SOS、用藥提醒）── -->
    <uses-permission android:name="android.permission.VIBRATE" />

    <!-- ── 喚醒鎖（同步時防止休眠）── -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <!-- ── 套件可見性（API 30+，撥話 / 開啟地圖）── -->
    <queries>
        <intent>
            <action android:name="android.intent.action.DIAL" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="geo" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="http" />
        </intent>
    </queries>

    <application
        android:name=".MainApplication"
        android:label="安心照護"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:allowBackup="false"
        android:supportsRtl="false"
        android:hardwareAccelerated="true"
        android:requestLegacyExternalStorage="true"
        android:theme="@style/NormalTheme"
        android:networkSecurityConfig="@xml/network_security_config">

        <!-- Firebase Cloud Messaging -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>

        <!-- 開機自啟（用藥提醒重新排程）-->
        <receiver
            android:name=".BootReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
            </intent-filter>
        </receiver>

        <!-- 前台服務（背景同步）-->
        <service
            android:name=".SyncForegroundService"
            android:foregroundServiceType="dataSync"
            android:exported="false" />

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:windowSoftInputMode="adjustResize"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

    </application>
</manifest>
```

---

## 11. 裝置硬體需求

| 項目 | 最低需求 | 建議 |
|------|----------|------|
| RAM | 2 GB | 3 GB+ |
| 儲存空間 | 200 MB（安裝）+ 150 MB（資料）| 500 MB 可用空間 |
| 螢幕解析度 | 720 × 1280（HD）| 1080 × 1920（FHD）+ |
| 螢幕密度 | 160 dpi（mdpi）| 420 dpi（xxhdpi）+ |
| 網路 | Wi-Fi 或行動數據 | 4G LTE+ |
| GPS / 定位 | 非必要（可手動搜尋）| 建議開啟以使用導航 |
| 相機 | 非必要 | 建議用於照護日誌附圖 |
| 麥克風 | 非必要 | 建議用於語音輸入（印尼語）|
| CPU 架構 | armeabi-v7a（32-bit）| arm64-v8a（64-bit）|

---

## 12. 支援裝置型號清單

### 主要品牌支援狀況

| 品牌 | 建議系列 | 最低型號 | 備註 |
|------|----------|----------|------|
| Samsung | Galaxy A / S 系列 | Galaxy A32（API 30）| 外籍看護主流機型 |
| OPPO | A 系列、Reno 系列 | OPPO A54（API 30）| 台灣外籍看護常用 |
| Xiaomi / Redmi | Redmi 系列 | Redmi 9（API 29）| 平價高 CP 值 |
| vivo | Y 系列 | vivo Y33s（API 31）| |
| realme | C / 數字系列 | realme C21（API 30）| |
| ASUS | ZenFone 系列 | ZenFone 8（API 31）| |
| Google Pixel | 全系列 | Pixel 3a（API 28）| 最佳相容性 |
| HTC | — | — | 市佔低，基本相容 |

### 確認測試機型（QA 裝置）

| 裝置 | Android 版本 | API | 測試重點 |
|------|-------------|-----|----------|
| Samsung Galaxy A32 | Android 11 | 30 | 外籍看護主流機 |
| OPPO A54 | Android 10 | 29 | 低階主流 |
| Redmi Note 10 | Android 11 | 30 | 中階主流 |
| Samsung Galaxy S22 | Android 13 | 33 | 高階最新政策 |
| Google Pixel 6 | Android 14 | 34 | 目標版本驗證 |
| Google Pixel 8 | Android 15 | 35 | 最新版本驗證 |
| Android Emulator（API 21）| Android 5.0 | 21 | 最低版本邊界 |

---

## 13. 不支援裝置與版本

| 情形 | 原因 |
|------|------|
| Android 4.4 及以下（API ≤ 19）| Flutter 3.22 不支援 |
| 僅支援 x86（Intel Atom 舊款平板）| 未提供 x86 ABI（可補充建置）|
| Android Go Edition（部分功能受限）| RAM 1 GB 以下可能 OOM |
| 已 Root 裝置 | Firebase Auth SafetyNet / Play Integrity 可能失敗 |
| 模擬器 | Push Notification 需 Google Play Services，部分模擬器無法使用 |

---

## 14. 版本測試矩陣

### 必測功能清單（每次 Release 前）

```
[ ] OTP 登入流程（含自動填入 SMS OTP）
[ ] 照護日誌新增（含生命徵象輸入）
[ ] 異常項目紅色警示顯示
[ ] SOS 緊急求救（含電話撥打 119 / 1966 / 1955）
[ ] 用藥提醒推播（前景通知、背景通知、鎖定畫面通知）
[ ] 用藥精確提醒（設定後 1 分鐘內觸發）
[ ] 長照資源地圖（縣市下拉 + 鄉鎮篩選）
[ ] OSM 地圖載入與路線計算（OSRM）
[ ] 離線模式（關閉 Wi-Fi 與行動數據後測試）
[ ] 語言切換（zh-TW ↔ id ↔ vi）
[ ] 相機拍照附加至照護日誌
[ ] 相片庫選取附加至照護日誌
[ ] 深色模式切換（Android 10+）
[ ] 分割畫面使用（Android 7+）
[ ] 背景切換後資料不遺失
[ ] 記憶體壓力測試（連續操作 30 分鐘）
[ ] 無障礙（TalkBack 基本操作）
```

### 版本特定測試

| 測試項目 | 測試版本 | 說明 |
|----------|----------|------|
| 通知頻道設定正確 | API 26+ | 確認用藥 / SOS / 同步各頻道存在 |
| 通知授權提示 | API 33+ | 首次啟動是否出現授權對話框 |
| 精確鬧鐘授權引導 | API 34 | 是否正確引導至系統設定 |
| Scoped Storage | API 30+ | 相片選取、儲存正常 |
| 套件可見性（撥話）| API 30+ | SOS 一鍵撥話正常 |
| MultiDex 啟動 | API 21–22 | 不閃退、啟動時間 < 5 秒 |

---

## 15. 升級相容性注意事項

### APP 版本升級時的 Hive 資料遷移

```dart
// lib/core/services/migration_service.dart
class MigrationService {
  static Future<void> runMigrations() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVersion = prefs.getString('app_version') ?? '0.0.0';

    if (_compareVersion(lastVersion, '2.0.0') < 0) {
      // v2.0 資料結構變更：清空照護日誌快取，重新從 Firestore 同步
      await Hive.box(AppConstants.hiveBoxCareLog).clear();
    }

    await prefs.setString('app_version', AppConstants.appVersion);
  }

  static int _compareVersion(String v1, String v2) {
    final p1 = v1.split('.').map(int.parse).toList();
    final p2 = v2.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      if (p1[i] != p2[i]) return p1[i].compareTo(p2[i]);
    }
    return 0;
  }
}
```

### Firebase SDK 版本鎖定

| Firebase Android SDK | 最低 API | 目標 API |
|---------------------|----------|----------|
| Firebase BOM 33.x（當前）| API 21 | API 34 |
| Firebase BOM 32.x | API 19 | API 33 |

### minSdkVersion 升級計畫

| 版本 | 計畫 minSdk | 說明 |
|------|------------|------|
| v1.x（當前）| API 21 | 涵蓋外籍看護舊機 |
| v2.0（規劃中）| API 23 | Google Play 2024 建議最低值 |
| v3.0（未來）| API 26 | 通知頻道為基礎功能 |

---

## 16. Gradle 版本設定速查

### app/build.gradle（完整設定）

```groovy
plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'com.google.gms.google-services'    // Firebase
}

android {
    compileSdkVersion 34
    ndkVersion "25.1.8937393"

    defaultConfig {
        applicationId "tw.antsicare.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutter.versionCode.toInteger()
        versionName flutter.versionName
        multiDexEnabled true
        vectorDrawables.useSupportLibrary = true

        // 僅打包需要的 ABI（減少 APK 體積）
        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86_64'
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
        coreLibraryDesugaringEnabled true   // API 21 支援 Java 8+ API
    }

    kotlinOptions {
        jvmTarget = '17'
    }

    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                          'proguard-rules.pro'
            signingConfig signingConfigs.release
        }
        debug {
            minifyEnabled false
            applicationIdSuffix ".debug"
            versionNameSuffix "-debug"
        }
    }

    // App Bundle 設定
    bundle {
        language { enableSplit = true }
        density  { enableSplit = true }
        abi      { enableSplit = true }
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
    implementation platform('com.google.firebase:firebase-bom:33.0.0')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.firebase:firebase-firestore'
    implementation 'com.google.firebase:firebase-messaging'
    implementation 'androidx.work:work-runtime-ktx:2.9.0'
}
```

### 版本相依速查表

| 工具 / 函式庫 | 當前版本 | 最低相容 API |
|---------------|----------|-------------|
| Flutter | 3.22.0 | API 21 |
| Kotlin | 1.9.x | API 21 |
| Gradle Plugin | 8.2.x | — |
| Firebase BOM | 33.0.0 | API 21 |
| WorkManager | 2.9.0 | API 14 |
| androidx.core | 1.12.0 | API 14 |
| Hive（Flutter）| 2.2.3 | API 21 |
| flutter_map | 6.1.0 | API 21 |

