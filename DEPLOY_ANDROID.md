# AnTsiSeCare — Android 上架完整說明

**Application ID：** `tw.miaoli.antsicare`  
**最低 API Level：** 21（Android 5.0 Lollipop）  
**目標 API Level：** 34（Android 14）  
**架構：** arm64-v8a, armeabi-v7a, x86_64

---

## 目錄

1. [前置環境需求](#1-前置環境需求)
2. [Google Play Console 設定](#2-google-play-console-設定)
3. [Firebase Android 設定](#3-firebase-android-設定)
4. [Gradle 專案設定](#4-gradle-專案設定)
5. [簽署金鑰設定](#5-簽署金鑰設定)
6. [環境變數與 API 金鑰注入](#6-環境變數與-api-金鑰注入)
7. [建置前檢查](#7-建置前檢查)
8. [建置 App Bundle (AAB)](#8-建置-app-bundle-aab)
9. [Google Play Console 上傳與發布](#9-google-play-console-上傳與發布)
10. [Store Listing 填寫](#10-store-listing-填寫)
11. [審核注意事項](#11-審核注意事項)
12. [常見錯誤排查](#12-常見錯誤排查)

---

## 1. 前置環境需求

| 工具 | 版本需求 | 說明 |
|------|----------|------|
| JDK | 17（LTS） | `java -version` 確認 |
| Android Studio | Hedgehog 2023.1.1+ | 含 Android SDK |
| Flutter SDK | 3.22.0+ | `flutter --version` |
| Android SDK | API 34 | SDK Manager 安裝 |
| Build Tools | 34.0.0+ | SDK Manager 安裝 |
| Google Play 帳號 | 已付費（$25 一次性） | 正式上架必備 |

```bash
# 確認環境
flutter doctor -v
java -version
# 預期：openjdk version "17.x.x"

# 接受 Android 授權
flutter doctor --android-licenses
```

---

## 2. Google Play Console 設定

### 2.1 建立應用程式

1. 登入 [Google Play Console](https://play.google.com/console)
2. **建立應用程式**
3. 填入：
   - **應用程式名稱：** 安心照護 AnTsiSeCare
   - **預設語言：** 繁體中文（台灣）
   - **應用程式或遊戲：** 應用程式
   - **免費或付費：** 免費
4. 勾選開發人員計畫政策聲明

### 2.2 設定應用程式分類

```
應用程式類別：醫療
標記（Tags）：長照, 照護, 移工, 印尼語, 苗栗
```

---

## 3. Firebase Android 設定

### 3.1 在 Firebase Console 新增 Android App

1. 前往 [Firebase Console](https://console.firebase.google.com)
2. 專案 `antsicare-miaoli` → **新增應用程式 → Android**
3. 填入：
   - **Android 套件名稱：** `tw.miaoli.antsicare`
   - **應用程式暱稱：** AnTsiSeCare Android
   - **偵錯用簽署憑證 SHA-1：**（見下方取得方式）

```bash
# 取得 debug keystore SHA-1
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android \
  | grep SHA1
```

### 3.2 下載並放置 google-services.json

```bash
# 下載後放置至：
app/android/app/google-services.json
```

> ⚠️ **重要：** 此檔案含有私密金鑰，已加入 `.gitignore`，**勿提交至 Git**

### 3.3 設定 Firebase Phone Auth（電話號碼登入）

1. Firebase Console → Authentication → **Sign-in method**
2. 啟用 **電話號碼**
3. 加入測試用電話號碼（避免真實 SMS 費用）：
   ```
   +886 912 345 678 → 驗證碼：123456
   ```

### 3.4 設定 SHA-256（正式版必要）

```bash
# 取得 release keystore SHA-256（簽署後填入）
keytool -list -v \
  -keystore android/app/antsicare-release.jks \
  -alias antsicare \
  | grep SHA256
```

將 SHA-256 加入 Firebase Console → 專案設定 → 應用程式 → SHA 憑證指紋

---

## 4. Gradle 專案設定

### 4.1 `android/app/build.gradle` 完整設定

```groovy
android {
    compileSdkVersion 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions { jvmTarget = '17' }

    defaultConfig {
        applicationId "tw.miaoli.antsicare"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true

        // Google Maps
        manifestPlaceholders += [GOOGLE_MAPS_API_KEY: GOOGLE_MAPS_API_KEY]
    }

    signingConfigs {
        release {
            storeFile file(KEYSTORE_PATH)
            storePassword KEYSTORE_PASSWORD
            keyAlias KEY_ALIAS
            keyPassword KEY_PASSWORD
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                          'proguard-rules.pro'
        }
    }

    bundle {
        language { enableSplit = true }
        density  { enableSplit = true }
        abi      { enableSplit = true }
    }
}

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.4.0'
    implementation 'com.google.android.gms:play-services-maps:18.2.0'
    implementation 'androidx.multidex:multidex:2.0.1'
}

apply plugin: 'com.google.gms.google-services'
```

### 4.2 `android/build.gradle` 設定

```groovy
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.1'
        classpath 'com.android.tools.build:gradle:8.2.2'
    }
}
```

### 4.3 `android/gradle.properties` 設定

```properties
# Flutter
org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=512m
android.useAndroidX=true
android.enableJetifier=true

# 簽署設定（CI 由環境變數覆寫，本機開發用）
KEYSTORE_PATH=./antsicare-release.jks
KEYSTORE_PASSWORD=your_store_password
KEY_ALIAS=antsicare
KEY_PASSWORD=your_key_password

# API Keys（CI 由環境變數覆寫）
GOOGLE_MAPS_API_KEY=AIzaSy...
```

> 🔒 **安全提示：** `gradle.properties` 加入 `.gitignore`，CI/CD 透過 Secrets 注入

---

## 5. 簽署金鑰設定

### 5.1 建立 Release Keystore（首次，只做一次）

```bash
keytool -genkey -v \
  -keystore android/app/antsicare-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias antsicare \
  -dname "CN=AnTsiSeCare, OU=MiaoliLTC, O=MiaoliCounty, L=Miaoli, S=Taiwan, C=TW"
```

系統提示輸入：
- **Keystore 密碼：** 設定強密碼並安全保存
- **Key 密碼：** 可與 Keystore 密碼相同

> ⚠️ **極重要：** 此 `.jks` 檔案一旦遺失，將無法更新已上架的 App。
> 請備份至：加密雲端儲存、公司保險箱、團隊密碼管理工具（如 1Password）

### 5.2 啟用 Google Play App Signing（強烈建議）

```
Play Console → 設定 → 應用程式完整性
→ 選擇「Google 管理並保護您的應用程式簽署金鑰」
→ 首次上傳後，由 Google 管理正式簽署金鑰
```

好處：即使遺失上傳金鑰，Google 仍可協助復原

---

## 6. 環境變數與 API 金鑰注入

### 方法 A：命令列 --dart-define（開發/CI 適用）

```bash
flutter build appbundle \
  --release \
  --dart-define=CLAUDE_API_KEY=sk-ant-... \
  --dart-define=GOOGLE_MAPS_API_KEY=AIzaSy... \
  --build-name=1.0.0 \
  --build-number=1
```

### 方法 B：GitHub Actions Secrets

```yaml
# .github/workflows/android-release.yml
- name: Build Android App Bundle
  run: |
    flutter build appbundle \
      --release \
      --dart-define=CLAUDE_API_KEY=${{ secrets.CLAUDE_API_KEY }} \
      --dart-define=GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }} \
      --build-name=${{ env.VERSION_NAME }} \
      --build-number=${{ env.VERSION_CODE }}
  env:
    KEYSTORE_PATH: ${{ secrets.KEYSTORE_PATH }}
    KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
    KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
    KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
```

---

## 7. 建置前檢查

```bash
cd app

# 1. 更新依賴
flutter pub get

# 2. 靜態分析
flutter analyze
# 預期：No issues found!

# 3. 執行單元測試
flutter test test/
# 預期：All tests passed

# 4. 確認 AndroidManifest.xml 權限完整
cat android/app/src/main/AndroidManifest.xml | grep uses-permission

# 5. 確認 google-services.json 存在
ls android/app/google-services.json

# 6. 試建置（debug 版本確認編譯正確）
flutter build apk --debug

# 7. 確認 APK 基本功能正常（在模擬器）
flutter run --release
```

---

## 8. 建置 App Bundle (AAB)

Google Play **要求** 上傳 AAB（而非 APK）：

```bash
# 建置 Release AAB
flutter build appbundle \
  --release \
  --dart-define=CLAUDE_API_KEY=$CLAUDE_API_KEY \
  --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY \
  --build-name=1.0.0 \
  --build-number=1

# 輸出路徑
ls -lh build/app/outputs/bundle/release/app-release.aab
# 預期大小：30-80 MB
```

### 驗證 AAB 內容

```bash
# 使用 bundletool 驗證
java -jar bundletool.jar validate \
  --bundle=build/app/outputs/bundle/release/app-release.aab

# 產生 APK 集合測試（可選）
java -jar bundletool.jar build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=antsicare.apks \
  --ks=android/app/antsicare-release.jks \
  --ks-pass=pass:$KEYSTORE_PASSWORD \
  --ks-key-alias=antsicare \
  --key-pass=pass:$KEY_PASSWORD
```

---

## 9. Google Play Console 上傳與發布

### 9.1 選擇發布軌道

```
內部測試軌道  → 最多 100 位測試人員（無需審核，立即可用）
封閉式測試    → 特定群組測試人員
開放式測試    → 公開測試（類似 Beta）
正式版        → 公開上架（需 Google 審核，通常 1-3 天）
```

**建議流程：** 內部測試 → 封閉測試 → 正式版

### 9.2 上傳 AAB

```
Play Console → 應用程式 → 測試 → 內部測試
→ 建立新版本
→ 上傳 App Bundle：build/app/outputs/bundle/release/app-release.aab
→ 版本說明（What's new）：
   zh-TW：安心照護 1.0.0 首次發布
   id：Rilis pertama AnTsiSeCare 1.0.0
→ 儲存 → 審閱 → 開始推送
```

### 9.3 版本說明範本（每次更新填寫）

```
【v1.0.0 首次發布】
✅ 照護日誌：12 項照護記錄 + 生命跡象
✅ AI 翻譯：印尼語備註自動翻譯中文
✅ SOS：一鍵 119 + GPS 位置傳送
✅ 長照資源地圖：苗栗縣 18 鄉鎮機構
✅ 用藥管理：每日服藥提醒
✅ 離線模式：偏鄉無網路仍可使用

[Bahasa Indonesia]
✅ Catatan perawatan: 12 item + tanda vital
✅ Terjemahan AI: Catatan otomatis ke bahasa Mandarin
✅ SOS: Darurat 119 + kirim lokasi GPS
```

---

## 10. Store Listing 填寫

### 10.1 主要商店資訊

```
應用程式名稱（30字）：安心照護 AnTsiSeCare
簡短說明（80字）：
苗栗縣長照整合服務，印尼語優先設計。照護日誌、SOS緊急通報、
長照機構地圖、用藥提醒，偏鄉離線可用。

完整說明（4000字以內）：（詳見 App Store Connect 說明內容）
```

### 10.2 圖形資源

| 資源類型 | 規格 | 說明 |
|---------|------|------|
| 應用程式圖示 | 512×512 px PNG | 無 Alpha 透明度 |
| 特色圖片 | 1024×500 px JPG/PNG | 商店頂部橫幅 |
| 手機截圖 | 最少 2 張，最多 8 張 | 16:9 或 9:16 |
| 7 吋平板截圖 | 可選 | — |
| 10 吋平板截圖 | 可選 | — |

```bash
# 使用 Flutter 截圖（在模擬器）
# 建議截圖解析度：1080×1920（FHD）
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png
```

### 10.3 內容分級問卷

前往 **政策 → 應用程式內容 → 內容分級**：

```
問卷類別：醫療保健
暴力：無
性內容：無
語言：無冒犯性語言
個人資訊：收集（電話號碼，用於登入驗證）
```

預期評分：**所有人（ESRB）**

### 10.4 資料安全（Play Console 必填）

```
收集的資料類型：
✅ 位置（概略）- SOS 緊急通報
✅ 個人資訊（電話號碼）- 帳號驗證
✅ 應用程式活動（照護日誌）- 功能核心

資料加密：✅ 傳輸中加密（Firebase TLS）
使用者可要求刪除：✅ 可透過帳號設定刪除
```

---

## 11. 審核注意事項

### 11.1 Android 特定注意事項

| 項目 | 要求 |
|------|------|
| targetSdkVersion | ≥ 33（2024 年 8 月新規定） |
| 64-bit 支援 | 必須（arm64-v8a） |
| 背景位置 | 需額外聲明理由（SOS 功能） |
| CALL_PHONE 權限 | 需在商店說明中解釋用途 |
| 精確位置 vs 概略位置 | 說明為何需要精確位置（SOS） |

### 11.2 常見被拒原因與對策

| 問題 | 對策 |
|------|------|
| 電話撥打未解釋用途 | AndroidManifest 加入 `<uses-feature android:required="false">` |
| 背景位置被拒 | 僅在 SOS 觸發時請求，前景請求即可 |
| 目標 API Level 過低 | 確認 targetSdkVersion=34 |
| 政策違規（健康資訊） | 加入「非醫療建議」免責聲明 |
| 應用程式不完整 | 確保所有連結和功能在審核期間正常運作 |

### 11.3 健康類 App 特殊政策

Google Play 對醫療健康類 App 有額外要求：

```
在 Store Listing 中加入：
「本應用程式提供長照照護記錄輔助工具，不提供醫療診斷建議。
 生命跡象數值僅供參考，如有醫療疑慮請諮詢專業醫護人員。」
```

---

## 12. 常見錯誤排查

### `Keystore file not found`

```bash
# 確認路徑
ls android/app/antsicare-release.jks

# 若使用相對路徑，確認從專案根目錄執行
pwd  # 應為 .../AnTsiSeCare/app
```

### `minSdkVersion XX cannot be smaller than version XX`

```bash
# 找出要求最高 minSdk 的套件
flutter pub deps | grep minSdk
# 通常是 Firebase 或 Google Maps

# 更新 build.gradle
minSdkVersion 21  # Firebase 最低需求
```

### `D8: Cannot fit requested classes in a single dex file`

```groovy
// android/app/build.gradle
defaultConfig {
    multiDexEnabled true
}
dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

### `Google Maps blank screen`

```bash
# 確認 API Key 已啟用以下 APIs：
# - Maps SDK for Android
# - Geocoding API
# - Places API（若需要）

# 確認 SHA-1/SHA-256 已加入 Google Cloud Console
# 確認 AndroidManifest.xml 中 API Key 格式正確
```

### `FCM Token 取得失敗`

```bash
# 確認 google-services.json 是最新版本
# 確認 Firebase 專案中 Android App 的 SHA-1 正確
# 確認測試裝置有 Google Play Services
```

### `flutter build appbundle` 緩慢

```bash
# 增加 JVM heap size
export GRADLE_OPTS="-Xmx4g -XX:MaxMetaspaceSize=1g"

# 使用 Gradle daemon
echo "org.gradle.daemon=true" >> android/gradle.properties
echo "org.gradle.parallel=true" >> android/gradle.properties
echo "org.gradle.caching=true" >> android/gradle.properties
```

---

## 附錄 A：GitHub Actions 完整 CI/CD

```yaml
# .github/workflows/android-release.yml
name: Android Release

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: stable

      - name: Decode google-services.json
        run: echo "${{ secrets.GOOGLE_SERVICES_JSON }}" | base64 -d > app/android/app/google-services.json

      - name: Decode Keystore
        run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > app/android/app/antsicare-release.jks

      - name: Flutter pub get
        run: cd app && flutter pub get

      - name: Run tests
        run: cd app && flutter test

      - name: Build App Bundle
        run: |
          cd app && flutter build appbundle --release \
            --dart-define=CLAUDE_API_KEY=${{ secrets.CLAUDE_API_KEY }} \
            --dart-define=GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }} \
            --build-name=${GITHUB_REF_NAME#v} \
            --build-number=${{ github.run_number }}
        env:
          KEYSTORE_PATH: ./antsicare-release.jks
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: antsicare
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
          GOOGLE_MAPS_API_KEY: ${{ secrets.GOOGLE_MAPS_API_KEY }}

      - name: Upload to Play Store (Internal Track)
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}
          packageName: tw.miaoli.antsicare
          releaseFiles: app/build/app/outputs/bundle/release/app-release.aab
          track: internal
          changesNotSentForReview: false
```

## 附錄 B：ProGuard 規則

```proguard
# app/android/app/proguard-rules.pro

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Hive
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Speech to Text
-keep class com.codeheadlabs.soundstream.** { *; }

# 保留所有 Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}
```

## 附錄 C：版本號管理策略

```
版本號格式：主版本.次版本.修補版本+建置號
範例：1.0.0+1, 1.0.1+2, 1.1.0+10

Google Play versionCode 規則：
- 每次上傳必須 > 上一次
- 建議用 CI run number 或 yyyyMMddHH 格式
- 例：2026042109（2026年04月21日09時）

pubspec.yaml:
version: 1.0.0+2026042109
```

---

*文件版本：1.0.0 | 最後更新：2026-04-21*
