# AnTsiSeCare — iOS 上架完整說明

**Bundle ID：** `tw.miaoli.antsicare`  
**最低 iOS 版本：** 13.0  
**目標裝置：** iPhone / iPad（直式）

---

## 目錄

1. [前置環境需求](#1-前置環境需求)
2. [Apple Developer 帳號設定](#2-apple-developer-帳號設定)
3. [Firebase iOS 設定](#3-firebase-ios-設定)
4. [Xcode 專案設定](#4-xcode-專案設定)
5. [環境變數與 API 金鑰注入](#5-環境變數與-api-金鑰注入)
6. [建置前檢查](#6-建置前檢查)
7. [Archive 與上傳至 App Store Connect](#7-archive-與上傳至-app-store-connect)
8. [App Store Connect 設定](#8-app-store-connect-設定)
9. [審核注意事項](#9-審核注意事項)
10. [TestFlight 內部測試](#10-testflight-內部測試)
11. [常見錯誤排查](#11-常見錯誤排查)

---

## 1. 前置環境需求

| 工具 | 版本需求 | 說明 |
|------|----------|------|
| macOS | 14.0+ (Sonoma) | Xcode 15 最低需求 |
| Xcode | 15.0+ | App Store 提交需求 |
| Flutter SDK | 3.22.0+ | `flutter --version` 確認 |
| CocoaPods | 1.14.0+ | `pod --version` 確認 |
| Ruby | 3.0+ | CocoaPods 依賴 |
| Apple Developer 帳號 | 已付費 ($99/年) | 正式上架必備 |

```bash
# 確認環境
flutter doctor -v
xcode-select --version
pod --version
```

---

## 2. Apple Developer 帳號設定

### 2.1 建立 App ID

1. 登入 [Apple Developer Portal](https://developer.apple.com/account)
2. 前往 **Certificates, IDs & Profiles → Identifiers**
3. 點擊 **＋** 建立新 App ID
4. 填入：
   - **Description：** AnTsiSeCare
   - **Bundle ID：** `tw.miaoli.antsicare`（Explicit）
5. 啟用以下 Capabilities：
   - ✅ Push Notifications
   - ✅ Sign In with Apple（可選）
   - ✅ Background Modes（Remote notifications, Background fetch）

### 2.2 建立 Provisioning Profile

```
類型：App Store Distribution
App ID：tw.miaoli.antsicare
憑證：選擇您的 Distribution Certificate
名稱：AnTsiSeCare_AppStore
```

下載後雙擊安裝至 Xcode。

### 2.3 建立 Push Notification Key (APNs)

1. **Keys → ＋**
2. Key Name：`AnTsiSeCare APNs Key`
3. 啟用：**Apple Push Notifications service (APNs)**
4. 下載 `.p8` 檔案（**只能下載一次**，妥善保管）
5. 記錄 **Key ID** 與 **Team ID**

---

## 3. Firebase iOS 設定

### 3.1 在 Firebase Console 新增 iOS App

1. 前往 [Firebase Console](https://console.firebase.google.com)
2. 選擇專案 `antsicare-miaoli`
3. **新增應用程式 → iOS**
4. Bundle ID：`tw.miaoli.antsicare`
5. App Nickname：`AnTsiSeCare iOS`
6. App Store ID：（上架後填入）

### 3.2 下載並放置 GoogleService-Info.plist

```bash
# 下載後放置至：
app/ios/Runner/GoogleService-Info.plist
```

> ⚠️ **重要：** 此檔案含有私密金鑰，已加入 `.gitignore`，**勿提交至 Git**

### 3.3 設定 APNs 至 Firebase

1. Firebase Console → 專案設定 → **雲端通訊**
2. Apple 應用程式設定 → 上傳 APNs 驗證金鑰
3. 上傳步驟 2.3 的 `.p8` 檔案
4. 填入 Key ID 與 Team ID

### 3.4 更新 firebase_options.dart

```bash
# 使用 FlutterFire CLI 自動生成（推薦）
dart pub global activate flutterfire_cli
cd app
flutterfire configure \
  --project=antsicare-miaoli \
  --platforms=ios,android
```

或手動編輯 `app/lib/firebase_options.dart`，填入 Firebase Console 的真實值：

```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIzaSy...',           // 從 GoogleService-Info.plist 複製
  appId: '1:123456:ios:abc123',
  messagingSenderId: '123456789',
  projectId: 'antsicare-miaoli',
  storageBucket: 'antsicare-miaoli.appspot.com',
  iosBundleId: 'tw.miaoli.antsicare',
);
```

---

## 4. Xcode 專案設定

### 4.1 開啟 Xcode 專案

```bash
cd app
flutter pub get
cd ios
pod install
cd ..
open ios/Runner.xcworkspace   # 注意：用 .xcworkspace，非 .xcodeproj
```

### 4.2 Signing & Capabilities 設定

在 Xcode 中選擇 **Runner target → Signing & Capabilities**：

```
Team：          [您的 Apple Developer Team]
Bundle Identifier：tw.miaoli.antsicare
Provisioning Profile：AnTsiSeCare_AppStore
Signing Certificate：Apple Distribution
```

### 4.3 啟用所需 Capabilities

點擊 **+ Capability** 新增：

| Capability | 用途 |
|------------|------|
| Push Notifications | FCM 推播通知 |
| Background Modes | 勾選 Remote notifications + Background fetch |
| Location Updates（若需背景定位） | SOS GPS |

### 4.4 版本號設定

```
Version（CFBundleShortVersionString）：1.0.0
Build（CFBundleVersion）：1
```

或在 `app/pubspec.yaml` 控制：

```yaml
version: 1.0.0+1  # 格式：版本號+建置號
```

然後執行：
```bash
flutter build ios --build-name=1.0.0 --build-number=1
```

### 4.5 Google Maps API Key

在 `app/ios/Runner/AppDelegate.swift` 加入：

```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 5. 環境變數與 API 金鑰注入

**不將金鑰寫死在程式碼中**，改用 `--dart-define` 注入：

```bash
flutter build ios \
  --release \
  --dart-define=CLAUDE_API_KEY=sk-ant-... \
  --dart-define=GOOGLE_MAPS_API_KEY=AIzaSy... \
  --build-name=1.0.0 \
  --build-number=1
```

在 Xcode Build Settings 中設定（對應 `Info.plist` 的 `$(GOOGLE_MAPS_API_KEY)`）：

```
GOOGLE_MAPS_API_KEY = AIzaSy...
```

> 建議使用 Xcode Cloud 或 CI/CD（如 Codemagic、GitHub Actions）透過 Secrets 注入。

---

## 6. 建置前檢查

```bash
cd app

# 1. 檢查依賴
flutter pub get
flutter pub outdated

# 2. 靜態分析
flutter analyze
# 預期：No issues found!

# 3. 執行單元測試
flutter test test/
# 預期：All tests passed (55 tests)

# 4. 確認 Info.plist 隱私權說明完整
grep -A2 "NSLocationWhen" ios/Runner/Info.plist
grep -A2 "NSMicrophoneUsage" ios/Runner/Info.plist
grep -A2 "NSCameraUsage" ios/Runner/Info.plist

# 5. 試建置（不上傳）
flutter build ios --release --no-codesign
```

---

## 7. Archive 與上傳至 App Store Connect

### 方法 A：Xcode GUI（推薦首次上架）

```
1. Xcode → Product → Destination → Any iOS Device (arm64)
2. Product → Archive
3. 等待完成後，Organizer 自動開啟
4. 選擇最新 Archive → Distribute App
5. 選擇：App Store Connect → Upload
6. 勾選：
   - Include bitcode for iOS content
   - Upload your app's symbols
7. 選擇 Distribution Certificate 與 Provisioning Profile
8. 點擊 Upload
```

### 方法 B：命令列（CI/CD 適用）

```bash
# 建置 .ipa
flutter build ipa \
  --release \
  --dart-define=CLAUDE_API_KEY=$CLAUDE_API_KEY \
  --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY \
  --build-name=1.0.0 \
  --build-number=1

# 上傳至 App Store Connect
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/antsicare.ipa \
  --apiKey $APP_STORE_CONNECT_API_KEY_ID \
  --apiIssuer $APP_STORE_CONNECT_ISSUER_ID

# 或使用 Transporter（macOS App）
```

---

## 8. App Store Connect 設定

### 8.1 建立新 App

1. [App Store Connect](https://appstoreconnect.apple.com) → 我的 App → ＋
2. 填入：
   - **名稱：** 安心照護
   - **主要語言：** 繁體中文
   - **Bundle ID：** tw.miaoli.antsicare
   - **SKU：** antsicare-miaoli-2026

### 8.2 App 資訊填寫

```
分類：醫療保健
副分類：社交

名稱：安心照護 AnTsiSeCare
副標題：苗栗縣長照服務整合

關鍵字：
  長照,照護,照服員,失能,安心照護,苗栗,
  perawatan,caregiver,lansia,Indonesia

描述（中文 4000字以內）：
安心照護（AnTsiSeCare）是專為苗栗縣長照服務設計的整合 APP，
以印尼語照服員為優先使用族群，提供中文 / 印尼語雙語介面。

主要功能：
• 照護日誌：12 項照護圖示記錄 + 生命跡象輸入 + 語音備註
• AI 翻譯：Claude AI 自動將印尼語照護備註翻譯成中文供家屬閱讀
• SOS 緊急通報：一鍵撥打 119，GPS 位置即時傳送家屬
• 長照資源地圖：苗栗縣 18 鄉鎮長照機構搜尋（ABC 三級）
• 用藥管理：每日排程 + 服藥記錄 + 多語言提醒通知
• 離線支援：偏鄉無網路時仍可記錄，上線後自動同步
```

### 8.3 截圖規格

需提交以下尺寸（使用 iPhone Simulator 截圖）：

| 裝置 | 尺寸 | 必要 |
|------|------|------|
| iPhone 6.7" (15 Pro Max) | 1290 × 2796 | ✅ 必要 |
| iPhone 6.5" (14 Plus) | 1242 × 2688 | ✅ 必要 |
| iPad Pro 12.9" | 2048 × 2732 | 若支援 iPad |

建議截圖內容（至少 3 張，最多 10 張）：
1. 首頁 — 問候語 + 快速操作格
2. 照護日誌 — 12 項圖示格（含異常警示）
3. SOS 畫面 — 脈搏動畫大按鈕
4. 長照資源地圖 — 篩選結果列表
5. 用藥管理 — 每日服藥排程

### 8.4 隱私權政策 URL

Apple 審核必填，需提供可公開存取的 URL：

```
https://antsicare.miaoli.gov.tw/privacy
```

---

## 9. 審核注意事項

### 9.1 隱私權說明（Info.plist 必備）

已在 `app/ios/Runner/Info.plist` 設定，審核員會核對：

| 權限 | 說明文字需包含 |
|------|--------------|
| 位置 | 緊急 SOS 座標傳送 + 長照機構查詢 |
| 麥克風 | 語音輸入照護備註（印尼語/中文） |
| 相機 | 拍攝照護現場照片 |
| 相簿 | 選取照護相關照片 |
| 聯絡人 | 設定緊急聯絡人 |

### 9.2 可能被退審的原因與對策

| 可能問題 | 對策 |
|---------|------|
| 需要帳號才能使用 | 提供審核專用測試帳號（照服員角色） |
| 外部 API（Claude）無法連線 | 提供 demo 模式，無需網路可展示基本功能 |
| 位置權限說明不清楚 | 確認中英文都有說明使用目的 |
| 缺少隱私政策連結 | 提供可公開存取的隱私政策頁面 |
| Firebase Phone Auth 需說明 | 備註：使用 Firebase 電話號碼驗證登入 |

### 9.3 審核帳號準備

在 App Store Connect 審核說明欄填入：

```
測試帳號：+886 912 345 678
OTP 驗證碼：123456（測試環境固定）
角色：照服員

測試流程：
1. 輸入手機號碼，點擊「發送驗證碼」
2. 輸入 OTP 123456 登入
3. 選擇角色「照服員」，語言「印尼語」
4. 功能均可在無需實際 Firebase 連線的 demo 模式下展示
```

---

## 10. TestFlight 內部測試

```
1. 上傳成功後，App Store Connect → TestFlight
2. 等待 Apple 審核（通常 15 分鐘）
3. 內部測試群組 → 新增測試人員（以 Apple ID）
4. 測試人員收到邀請 Email → 安裝 TestFlight App → 安裝測試版
```

建議測試人員：
- 台灣籍督導（中文介面測試）
- 印尼籍照服員（印尼語介面測試）
- 家屬（家屬觀看角色測試）

---

## 11. 常見錯誤排查

### `No matching provisioning profiles found`
```bash
# Xcode → Preferences → Accounts → 下載所有 Profiles
# 或手動指定：
open ios/Runner.xcworkspace
# Signing & Capabilities → Provisioning Profile → 選擇正確 Profile
```

### `CocoaPods could not find compatible versions`
```bash
cd ios
pod repo update
pod install --repo-update
```

### `Firebase: No GoogleService-Info.plist found`
```bash
# 確認檔案位置正確
ls ios/Runner/GoogleService-Info.plist
# 確認在 Xcode 中已加入 Target membership
```

### `flutter build ios` 失敗
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
```

### `ITMS-90683: Missing Purpose String`
- 確認 `Info.plist` 包含所有已使用權限的 `UsageDescription`
- 執行 `grep -n "UsageDescription" ios/Runner/Info.plist`

---

## 附錄：Codemagic CI/CD 設定範例

```yaml
# codemagic.yaml
workflows:
  ios-release:
    name: iOS Release
    environment:
      flutter: stable
      xcode: latest
      vars:
        BUNDLE_ID: tw.miaoli.antsicare
      groups:
        - app_store_credentials
        - firebase_credentials
    scripts:
      - flutter pub get
      - flutter test
      - flutter build ios --release
        --dart-define=CLAUDE_API_KEY=$CLAUDE_API_KEY
        --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY
    publishing:
      app_store_connect:
        api_key: $APP_STORE_CONNECT_PRIVATE_KEY
        key_id: $APP_STORE_CONNECT_KEY_ID
        issuer_id: $APP_STORE_CONNECT_ISSUER_ID
        submit_to_testflight: true
```

---

*文件版本：1.0.0 | 最後更新：2026-04-21*
