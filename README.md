# AnTsiSeCare（安心照護）

> 全台長照服務整合 APP — 覆蓋台灣 22 縣市，為長者、家庭照顧者與外籍看護工設計

## 專案簡介

AnTsiSeCare 是一款全台灣範圍的長照數位平台，整合全國 22 縣市的長照 A/B/C 級服務資源。支援繁體中文、印尼語（Bahasa Indonesia）、越南語、泰語、英語五種語言，提供長者、家庭照顧者、居家照服員與照管專員一站式數位化服務。

## 核心功能

| 功能 | 說明 |
|------|------|
| 📋 照護日誌 | 填寫照護紀錄（印尼語 → 自動翻譯中文），含生命徵象、異常警示 |
| 🆘 SOS 緊急求救 | 一鍵啟動，附近資源速查 + 1955 移工專線 + 119 緊急救護 |
| 💊 用藥管理 | 排班提醒、服藥紀錄、多語言推播通知 |
| 🗺️ 長照資源地圖 | 全台 A/B/C 級機構查詢，支援縣市 + 鄉鎮篩選 |
| 🧭 導航規劃 | OpenStreetMap + OSRM 路線計算，三組預設路線（急診 / 衛生所 / 長照中心）|
| 👨‍👩‍👧 家庭檢視 | 家屬遠端查看長者最新照護狀況 |
| 👤 個人設定 | 多語言切換、角色管理、通知設定 |

## 服務場域

全台灣 22 縣市：台北市、新北市、桃園市、台中市、台南市、高雄市、基隆市、新竹市、嘉義市、新竹縣、苗栗縣、彰化縣、南投縣、雲林縣、嘉義縣、屏東縣、宜蘭縣、花蓮縣、台東縣、澎湖縣、金門縣、連江縣

## 多語言支援

| 語言 | 代碼 | 主要族群 |
|------|------|------|
| 繁體中文 | zh-TW | 長者、家屬、照管專員 |
| 印尼語 Bahasa Indonesia | id | 印尼籍家庭看護工（第一優先）|
| 越南語 Tiếng Việt | vi | 越南籍看護工 |
| 泰語 ภาษาไทย | th | 泰籍看護工 |
| English | en | 機構管理員 |

## 技術棧

| 層次 | 技術 |
|------|------|
| APP 框架 | Flutter 3.22 / Dart 3.4（iOS + Android）|
| 後端 / 資料庫 | Firebase Firestore（NoSQL）|
| 身份驗證 | Firebase Auth（手機號碼 OTP）|
| 推播通知 | Firebase Cloud Messaging（FCM）|
| 離線快取 | Hive（本機 key-value）|
| 地圖 | flutter_map 6.1 + OpenStreetMap（免費、無需 API Key）|
| 路線規劃 | OSRM 公共路由伺服器（免費、無需 API Key）|
| 多語言 | easy_localization + ARB 格式 |
| 路由 | GoRouter 14 |
| 狀態管理 | Riverpod |
| Bundle ID | tw.antsicare.app |

## 專案結構

```
AnTsiSeCare/
├── app/                          # Flutter APP
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/        # AppConstants（22 縣市資料）
│   │   │   ├── models/           # UserModel, LtcResourceModel
│   │   │   ├── services/         # LtcDataService, SyncService, NotificationService
│   │   │   ├── theme/            # AppColors（WCAG AAA 無障礙色彩）
│   │   │   └── utils/            # TimezoneUtils（Asia/Taipei）
│   │   ├── features/
│   │   │   ├── auth/             # 手機 OTP 登入、角色選擇、語言選擇
│   │   │   ├── care_log/         # 照護日誌（新增/編輯/列表）
│   │   │   ├── family/           # 家庭檢視
│   │   │   ├── home/             # 首頁、底部導覽
│   │   │   ├── medication/       # 用藥管理
│   │   │   ├── navigation/       # OSM 導航規劃（三組預設路線）
│   │   │   ├── profile/          # 個人設定
│   │   │   ├── resource_map/     # 長照資源地圖
│   │   │   └── sos/              # SOS 緊急求救
│   │   ├── router.dart           # GoRouter 路由定義
│   │   └── main.dart             # 應用程式進入點
│   ├── test/                     # 單元測試（Dart）
│   ├── pubspec.yaml
│   ├── firestore.rules
│   └── firestore.indexes.json
├── demo/
│   └── index.html                # 互動展示網頁（Leaflet OSM + 全台篩選）
├── test_runner.js                 # Node.js 測試執行器（66 tests）
├── USER_MANUAL.md                 # 完整功能操作說明（13 章）
└── 規劃文件/
```

## 快速執行測試

Flutter 環境未就緒時，可使用 Node.js 測試執行器：

```bash
node test_runner.js
```

測試涵蓋：時區轉換、長照資料篩選（全台縣市）、推播通知多語言、照護紀錄模型。

## 規劃文件索引

| 文件 | 說明 |
|------|------|
| [PLANNING.md](./PLANNING.md) | APP 整體規劃：使用者角色、功能模組、全台在地化、KPI |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | 技術架構：Flutter、Firebase、OSM、OSRM |
| [DATABASE.md](./DATABASE.md) | Firestore 資料結構設計 |
| [UIUX.md](./UIUX.md) | UI/UX 規範：WCAG AAA 無障礙、多語言介面 |
| [API.md](./API.md) | Firebase REST / Cloud Functions API |
| [I18N.md](./I18N.md) | 多語言國際化：印尼語優先、ARB 格式 |
| [ROADMAP.md](./ROADMAP.md) | 開發路線圖：四個 Phase、風險管理 |
| [DEPLOY_IOS.md](./DEPLOY_IOS.md) | iOS App Store 上架說明 |
| [DEPLOY_ANDROID.md](./DEPLOY_ANDROID.md) | Android Google Play 上架說明 |
| [USER_MANUAL.md](./USER_MANUAL.md) | 功能操作說明（中文）|

## 導航功能（OpenStreetMap）

三組預設路線（以台北市大安區為起點示範）：

| 路線 | 目的地 | 分類 |
|------|--------|------|
| 路線 A | 台大醫院急診 | 急診醫院 |
| 路線 B | 大安區健康服務中心 | 衛生所 |
| 路線 C | 大安區長照旗艦整合中心 | A 級長照 |

- 地圖：OpenStreetMap（免費圖磚，無 API Key）
- 路線計算：OSRM 公共伺服器（`router.project-osrm.org`）
- 支援開啟 Google Maps / OSM Web 進行實際導航
- 離線時顯示預估距離與時間

## 重要電話

| 服務 | 電話 |
|------|------|
| 長照服務 | 1966 |
| 移工諮詢（印尼語）| 1955 |
| 緊急救護 | 119 |
| 警察 | 110 |
