# AnTsiSeCare — iOS 版本需求與相容性說明

**Bundle ID：** `tw.antsicare.app`  
**最低支援版本：** iOS 13.0  
**最佳體驗版本：** iOS 16.0+  
**目標裝置：** iPhone / iPad（直式為主）

---

## 目錄

1. [支援版本概覽](#1-支援版本概覽)
2. [各 iOS 版本功能相容矩陣](#2-各-ios-版本功能相容矩陣)
3. [iOS 13（最低支援）](#3-ios-13最低支援)
4. [iOS 14](#4-ios-14)
5. [iOS 15](#5-ios-15)
6. [iOS 16](#6-ios-16)
7. [iOS 17](#7-ios-17)
8. [iOS 18](#8-ios-18)
9. [權限清單（Info.plist）](#9-權限清單-infoplist)
10. [裝置硬體需求](#10-裝置硬體需求)
11. [支援裝置型號清單](#11-支援裝置型號清單)
12. [不支援裝置與版本](#12-不支援裝置與版本)
13. [版本測試矩陣](#13-版本測試矩陣)
14. [升級相容性注意事項](#14-升級相容性注意事項)

---

## 1. 支援版本概覽

| iOS 版本 | 支援狀態 | 備註 |
|----------|----------|------|
| iOS 12 及以下 | ❌ 不支援 | Flutter 3.22 最低需求 iOS 13 |
| iOS 13.0–13.7 | ⚠️ 基本支援 | 部分 UI 元件降級渲染 |
| iOS 14.0–14.8 | ✅ 完整支援 | 推薦最低版本 |
| iOS 15.0–15.8 | ✅ 完整支援 | |
| iOS 16.0–16.7 | ✅ 完整支援 + 最佳化 | 推薦版本 |
| iOS 17.0–17.x | ✅ 完整支援 + 最佳化 | |
| iOS 18.0+ | ✅ 完整支援 | 已驗證相容 |

> **建議使用者升級至 iOS 16+** 以獲得完整功能（Live Activities、改良推播通知等）。

---

## 2. 各 iOS 版本功能相容矩陣

| 功能模組 | iOS 13 | iOS 14 | iOS 15 | iOS 16 | iOS 17+ |
|----------|--------|--------|--------|--------|---------|
| OTP 手機登入 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 照護日誌（讀寫）| ✅ | ✅ | ✅ | ✅ | ✅ |
| SOS 緊急求救 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 推播通知（基本）| ✅ | ✅ | ✅ | ✅ | ✅ |
| 推播通知（豐富媒體）| ⚠️ 有限 | ✅ | ✅ | ✅ | ✅ |
| 用藥管理提醒 | ✅ | ✅ | ✅ | ✅ | ✅ |
| OSM 地圖（flutter_map）| ✅ | ✅ | ✅ | ✅ | ✅ |
| OSRM 路線計算 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 離線模式（Hive）| ✅ | ✅ | ✅ | ✅ | ✅ |
| 語音輸入（speech_to_text）| ⚠️ 需額外授權 | ✅ | ✅ | ✅ | ✅ |
| 背景同步 | ⚠️ 有限 | ✅ | ✅ | ✅ | ✅ |
| 深色模式（Dark Mode）| ✅ | ✅ | ✅ | ✅ | ✅ |
| 動態島通知 | ❌ | ❌ | ❌ | ⚠️ iPhone 14 Pro+ | ✅ iPhone 15+ |
| Focus 模式過濾 | ❌ | ❌ | ✅ | ✅ | ✅ |
| SharePlay | ❌ | ❌ | ✅ | ✅ | ✅ |
| 文字大小動態調整（Dynamic Type）| ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 3. iOS 13（最低支援）

### 3.1 支援情況

Flutter 3.22 的 iOS 最低部署目標為 **iOS 12**，AnTsiSeCare 設定為 **iOS 13.0**，原因：
- Firebase SDK 11.x 最低需求 iOS 13
- `easy_localization` 部分 API 需要 iOS 13+
- `go_router` 14.x 需要 iOS 13+

### 3.2 已知限制

| 限制項目 | 說明 | 影響 |
|----------|------|------|
| `ASAuthorizationController` | Sign In with Apple 需 iOS 13+ | ✅ 已符合 |
| `UICollectionViewCompositionalLayout` | 部分 Grid UI 降級渲染 | 低，視覺差異小 |
| 背景應用程式重新整理 | 限制較多 | 離線同步延遲 |
| `URLSession` 背景任務 | 功能受限 | SyncService 採用前景模式補償 |

### 3.3 Podfile 設定

```ruby
# ios/Podfile
platform :ios, '13.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

---

## 4. iOS 14

### 4.1 新增支援功能

| 功能 | 說明 |
|------|------|
| `AppTrackingTransparency` | ATT 框架，需在首次啟動請求追蹤授權 |
| 推播通知豐富媒體 | 支援通知附圖（用藥提醒圖示）|
| Widget 支援 | 可新增首頁小工具（需額外開發）|
| 改良的語音辨識 | On-device 語音辨識（照護日誌輸入）|

### 4.2 Info.plist 新增（iOS 14+）

```xml
<!-- 若啟用廣告追蹤（目前未啟用，保留備用）-->
<key>NSUserTrackingUsageDescription</key>
<string>AnTsiSeCare 不追蹤您的廣告活動。</string>
```

### 4.3 背景同步改善

iOS 14 引入 `BGTaskScheduler` 改善版本，AnTsiSeCare `SyncService` 可利用此機制在背景定期同步照護紀錄至 Firestore。

```swift
// ios/Runner/AppDelegate.swift（需手動新增）
import BackgroundTasks

BGTaskScheduler.shared.register(
  forTaskWithIdentifier: "tw.antsicare.app.sync",
  using: nil
) { task in
  // 執行 SyncService.triggerSync()
}
```

---

## 5. iOS 15

### 5.1 新增支援功能

| 功能 | 說明 |
|------|------|
| Focus 模式 | 用藥提醒可設定為緊急通知，穿透 Focus 限制 |
| `UNNotificationInterruptionLevel` | 推播設定為 `.timeSensitive` 確保用藥提醒送達 |
| `URLSession` async/await | 網路請求效能改善 |
| SF Symbols 3 | 系統圖示更豐富 |

### 5.2 用藥提醒時效性設定

iOS 15 起，用藥提醒推播需設定 `interruptionLevel = .timeSensitive`，才能在 Focus 模式下仍顯示通知。

```dart
// notification_service.dart 對應設定
await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  alert: true,
  badge: true,
  sound: true,
);
```

對應 APNs payload：
```json
{
  "aps": {
    "alert": { "title": "用藥提醒 💊", "body": "陳阿婆：服用血壓藥" },
    "sound": "default",
    "interruption-level": "time-sensitive"
  }
}
```

---

## 6. iOS 16

### 6.1 新增支援功能

| 功能 | 說明 |
|------|------|
| Lock Screen Widgets | 鎖定畫面小工具（需額外開發）|
| `UIHostingConfiguration` | SwiftUI 直接嵌入 UITableViewCell |
| 改良的推播設定 | 更精細的通知集中管理 |
| `CKSyncEngine` | CloudKit 同步改善（目前使用 Firestore，無影響）|

### 6.2 推薦最低版本理由

iOS 16 是**推薦最低版本**，原因：
- 市佔率高（約佔全台 iOS 裝置 85%+）
- 推播通知功能最完整
- 地圖渲染效能提升（flutter_map tile 載入速度）
- 語音辨識 on-device 模型更準確

---

## 7. iOS 17

### 7.1 新增支援功能

| 功能 | 說明 |
|------|------|
| `SwiftData` | 本地資料庫（目前使用 Hive，無需遷移）|
| AirDrop 改善 | 連絡人分享（與本 APP 無關）|
| StandBy 模式 | iPhone 充電時橫置顯示（可展示用藥提醒）|
| Sensitive Content Analysis | 照護日誌圖片自動篩選 |
| `TipKit` | 系統引導提示（未來可整合操作說明）|
| 動態島持續互動 | iPhone 15+ 支援 Live Activities 更新 |

### 7.2 StandBy 模式適配

iOS 17 StandBy 模式下，APP 推播通知會以大型卡片顯示，需確保通知標題長度 ≤ 40 字元，AnTsiSeCare 通知模板已符合此限制。

---

## 8. iOS 18

### 8.1 新增支援功能

| 功能 | 說明 |
|------|------|
| RCS 訊息 | 對 SMS OTP 無影響，Firebase Auth 仍使用 APNs |
| Apple Intelligence | 通知摘要功能（用藥提醒建議設定為不摘要）|
| 控制中心自訂 | 未來可加入 SOS 快捷按鈕 |
| `ControlWidget` | 控制中心小工具（未來規劃）|

### 8.2 Apple Intelligence 通知設定

iOS 18 引入 Apple Intelligence 通知摘要，重要通知（用藥、SOS）需標記為不應摘要：

```json
{
  "aps": {
    "interruption-level": "critical",
    "relevance-score": 1.0
  }
}
```

---

## 9. 權限清單（Info.plist）

以下為 `ios/Runner/Info.plist` 所需完整權限設定：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" ...>
<plist version="1.0">
<dict>

  <!-- ── 位置（資源地圖、導航）── -->
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>AnTsiSeCare 需要您的位置以顯示附近長照機構並計算導航路線。</string>

  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
  <string>AnTsiSeCare 在背景追蹤位置以提供即時導航更新。</string>

  <!-- ── 相機（照護日誌附圖）── -->
  <key>NSCameraUsageDescription</key>
  <string>AnTsiSeCare 需要相機以拍攝照護現場照片並附加至日誌。</string>

  <!-- ── 相片庫（照護日誌附圖）── -->
  <key>NSPhotoLibraryUsageDescription</key>
  <string>AnTsiSeCare 需要存取相片庫以選擇照護照片。</string>

  <key>NSPhotoLibraryAddUsageDescription</key>
  <string>AnTsiSeCare 需要儲存照護相關照片至您的相片庫。</string>

  <!-- ── 麥克風（語音輸入）── -->
  <key>NSMicrophoneUsageDescription</key>
  <string>AnTsiSeCare 需要麥克風以使用語音輸入照護日誌（支援印尼語）。</string>

  <!-- ── 語音辨識（iOS 10+）── -->
  <key>NSSpeechRecognitionUsageDescription</key>
  <string>AnTsiSeCare 使用語音辨識將您的語音轉為文字填入照護紀錄。</string>

  <!-- ── 通知（用藥提醒、SOS）── -->
  <!-- 由 Firebase Messaging 自動處理，無需 plist 項目 -->

  <!-- ── 連絡人（緊急聯絡人）── -->
  <key>NSContactsUsageDescription</key>
  <string>AnTsiSeCare 需要存取連絡人以快速設定緊急聯絡人電話。</string>

  <!-- ── FaceID（選用，應用程式鎖）── -->
  <key>NSFaceIDUsageDescription</key>
  <string>AnTsiSeCare 使用 Face ID 以快速解鎖應用程式並保護照護資料。</string>

  <!-- ── 背景模式 ── -->
  <key>UIBackgroundModes</key>
  <array>
    <string>remote-notification</string>
    <string>background-processing</string>
    <string>background-fetch</string>
  </array>

  <!-- ── 最低 iOS 版本 ── -->
  <key>MinimumOSVersion</key>
  <string>13.0</string>

  <!-- ── Bundle ID ── -->
  <key>CFBundleIdentifier</key>
  <string>tw.antsicare.app</string>

  <!-- ── 支援方向（直式為主）── -->
  <key>UISupportedInterfaceOrientations</key>
  <array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
  </array>

  <!-- ── iPad 追加橫式 ── -->
  <key>UISupportedInterfaceOrientations~ipad</key>
  <array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
  </array>

  <!-- ── ATS 允許 HTTP（OSM tile 使用 HTTPS，此設定備用）── -->
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
      <key>tile.openstreetmap.org</key>
      <dict>
        <key>NSExceptionAllowsInsecureHTTPLoads</key>
        <false/>
        <key>NSIncludesSubdomains</key>
        <true/>
      </dict>
    </dict>
  </dict>

</dict>
</plist>
```

---

## 10. 裝置硬體需求

| 項目 | 最低需求 | 建議 |
|------|----------|------|
| RAM | 2 GB | 3 GB+ |
| 儲存空間 | 200 MB（安裝）+ 100 MB（資料）| 500 MB 可用空間 |
| 網路 | Wi-Fi 或行動數據 | 4G LTE+ |
| GPS / 定位 | 非必要（可手動搜尋）| 建議開啟以使用導航 |
| 相機 | 非必要 | 建議用於照護日誌附圖 |
| 麥克風 | 非必要 | 建議用於語音輸入（印尼語）|

---

## 11. 支援裝置型號清單

### iPhone（支援 iOS 13+）

| 機型 | 最低 iOS | 支援狀態 |
|------|----------|----------|
| iPhone SE（第 1 代）| iOS 12 最高 | ❌ 不支援 |
| iPhone 6s / 6s Plus | iOS 13 | ✅ 基本支援 |
| iPhone SE（第 2 代）| iOS 13 | ✅ 完整支援 |
| iPhone 7 / 7 Plus | iOS 13 | ✅ 完整支援 |
| iPhone 8 / 8 Plus | iOS 13 | ✅ 完整支援 |
| iPhone X | iOS 13 | ✅ 完整支援 |
| iPhone XS / XS Max | iOS 13 | ✅ 完整支援 |
| iPhone XR | iOS 13 | ✅ 完整支援 |
| iPhone 11 系列 | iOS 13 | ✅ 完整支援 |
| iPhone SE（第 3 代）| iOS 15 | ✅ 完整支援 |
| iPhone 12 系列 | iOS 14 | ✅ 完整支援 |
| iPhone 13 系列 | iOS 15 | ✅ 完整支援 |
| iPhone 14 / 14 Plus | iOS 16 | ✅ 完整支援 |
| iPhone 14 Pro / Pro Max | iOS 16 | ✅ 完整支援 + 動態島 |
| iPhone 15 系列 | iOS 17 | ✅ 完整支援 + 動態島 |
| iPhone 16 系列 | iOS 18 | ✅ 完整支援 + Apple Intelligence |

### iPad（支援 iOS/iPadOS 13+）

| 機型 | 最低系統 | 支援狀態 |
|------|----------|----------|
| iPad（第 5 代）| iPadOS 13 | ✅ 基本支援 |
| iPad（第 6–10 代）| iPadOS 13–16 | ✅ 完整支援 |
| iPad Air（第 3–6 代）| iPadOS 13+ | ✅ 完整支援 |
| iPad mini（第 5–6 代）| iPadOS 13+ | ✅ 完整支援 |
| iPad Pro 系列 | iPadOS 13+ | ✅ 完整支援 |

---

## 12. 不支援裝置與版本

下列情形無法安裝或使用 AnTsiSeCare：

| 情形 | 原因 |
|------|------|
| iOS 12 及以下 | Firebase SDK 11.x 不支援 |
| iPhone 5s、6、6 Plus | 最高可升至 iOS 12，無法升級 |
| 越獄（Jailbroken）裝置 | Firebase Auth 安全性驗證失敗 |
| 模擬器（Simulator）| Push Notification 無法測試，定位固定 |

---

## 13. 版本測試矩陣

### 測試裝置規劃

| 裝置 | iOS 版本 | 測試重點 |
|------|----------|----------|
| iPhone SE 2 | iOS 13.7 | 最低版本邊界測試 |
| iPhone 8 | iOS 16.7 | 主流舊機型 |
| iPhone 12 | iOS 15.8 | 中低階主流 |
| iPhone 14 | iOS 17.x | 主流機型 |
| iPhone 15 Pro | iOS 18.x | 最新機型 + Apple Intelligence |
| iPad Air 5 | iPadOS 16.x | 平板版面 |

### 必測功能清單（每次 Release 前）

```
[ ] OTP 登入流程
[ ] 照護日誌新增（含生命徵象）
[ ] 異常項目警示顯示
[ ] SOS 緊急求救（含電話撥打）
[ ] 用藥提醒推播（前景 + 背景）
[ ] 長照資源地圖（縣市篩選）
[ ] OSM 地圖載入與路線計算
[ ] 離線模式（關閉網路後測試）
[ ] 語言切換（zh-TW ↔ id ↔ vi）
[ ] Deep Link 測試（/care-log/new）
[ ] 記憶體使用（Instruments）
[ ] 無障礙（VoiceOver 基本操作）
```

---

## 14. 升級相容性注意事項

### Hive 資料遷移

APP 更新時，Hive box schema 若有變更，需處理舊版資料：

```dart
// main.dart
if (appVersion < '2.0.0') {
  await Hive.box(AppConstants.hiveBoxCareLog).clear();
  // 重新從 Firestore 同步
}
```

### Firebase SDK 版本鎖定

| Firebase SDK | 對應最低 iOS |
|------|------|
| Firebase iOS SDK 11.x | iOS 13.0 |
| Firebase iOS SDK 10.x | iOS 11.0 |

當前使用 **Firebase iOS SDK 11.x**，維持 iOS 13 最低需求。

### Flutter 版本升級影響

| Flutter 版本 | iOS 最低需求 | 備註 |
|------|------|------|
| Flutter 3.19 | iOS 12 | |
| Flutter 3.22（當前）| iOS 12（設定為 13）| |
| Flutter 3.24+ | iOS 13（預計）| |

---

## 附錄：Xcode Build Settings 速查

```
IPHONEOS_DEPLOYMENT_TARGET = 13.0
PRODUCT_BUNDLE_IDENTIFIER = tw.antsicare.app
SWIFT_VERSION = 5.0
ENABLE_BITCODE = NO
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym

// Release 專用
SWIFT_OPTIMIZATION_LEVEL = -O
GCC_OPTIMIZATION_LEVEL = s
STRIP_INSTALLED_PRODUCT = YES
```
