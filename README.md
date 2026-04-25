# AnTsiSeCare（安心照護）

> 全台長照數位服務平台 — 覆蓋台灣 22 縣市

[![Tests](https://img.shields.io/badge/tests-66%20passed-brightgreen)](#快速執行測試)
[![Flutter](https://img.shields.io/badge/Flutter-3.22-blue)](#技術棧)
[![License](https://img.shields.io/badge/license-MIT-green)](#)

## 專案簡介

**AnTsiSeCare（安心照護）** 是一款以 Flutter 開發的全台長照數位服務平台，整合全國 22 縣市長照 A/B/C 級服務資源，支援五種語言（中文 / 印尼語 / 越南語 / 泰語 / 英語），專為以下四類使用者設計：

| 角色 | 說明 |
|------|------|
| 👴 長者 | 接受照護服務的主要對象 |
| 👩‍👧 家庭照顧者 | 家屬遠端監看、接收異常通知 |
| 🧑‍⚕️ 居家照服員 | 填寫照護日誌（支援印尼語輸入）|
| 📋 照管專員 | 管理個案、查閱資源地圖 |

---

## 核心功能

| 模組 | 功能摘要 |
|------|----------|
| 📋 **照護日誌** | 記錄飲食、用藥、生命徵象等 12 項照護項目；印尼語輸入 → 自動翻譯中文；異常項目紅色警示 |
| 🆘 **SOS 緊急求救** | 一鍵啟動脈衝動畫介面；顯示 119 急救、1966 長照、1955 移工三條熱線；離線可用 |
| 💊 **用藥管理** | 建立多筆藥品排班；多語言推播提醒；記錄服藥歷史 |
| 🗺️ **長照資源地圖** | 衛福部開放資料 + 本地快取；全台縣市下拉 + 鄉鎮 chips 篩選；A/B/C 級分類 |
| 👨‍👩‍👧 **家庭檢視** | 家屬輸入長者 ID 後即可遠端查看最新照護紀錄與生命徵象 |
| 👤 **個人設定** | 即時切換五種語言；管理角色資訊與緊急聯絡人；離線模式設定 |

---

## 服務場域

全台灣 **22 縣市**：

| | | | | |
|---|---|---|---|---|
| 台北市 | 新北市 | 桃園市 | 台中市 | 台南市 |
| 高雄市 | 基隆市 | 新竹市 | 嘉義市 | 新竹縣 |
| 苗栗縣 | 彰化縣 | 南投縣 | 雲林縣 | 嘉義縣 |
| 屏東縣 | 宜蘭縣 | 花蓮縣 | 台東縣 | 澎湖縣 |
| 金門縣 | 連江縣 | | | |

---

## 多語言支援

| 語言 | 代碼 | 主要服務族群 | 優先級 |
|------|------|------------|--------|
| 繁體中文 | `zh-TW` | 長者、家屬、照管專員 | 預設 |
| 印尼語 Bahasa Indonesia | `id` | 印尼籍家庭看護工 | 第一優先 |
| 越南語 Tiếng Việt | `vi` | 越南籍看護工 | 第二優先 |
| 泰語 ภาษาไทย | `th` | 泰籍看護工 | 第三優先 |
| English | `en` | 機構管理員 | 輔助 |

---

## 技術棧

| 層次 | 技術 | 說明 |
|------|------|------|
| APP 框架 | Flutter 3.22 / Dart 3.4 | iOS + Android 雙平台 |
| 後端 / 資料庫 | Firebase Firestore | NoSQL 即時同步 |
| 身份驗證 | Firebase Auth | 手機號碼 OTP 登入 |
| 推播通知 | Firebase Cloud Messaging | 多語言推播 |
| 離線快取 | Hive | 本機 key-value，斷網可用 |
| 地圖 | flutter_map 6.1 + OpenStreetMap | 免費、無需 API Key |
| 路線規劃 | OSRM 公共伺服器 | 免費、無需 API Key |
| 多語言 | easy_localization + ARB | 動態語言切換 |
| 路由 | GoRouter 14 | 宣告式路由 |
| 狀態管理 | Riverpod | 響應式依賴注入 |
| Bundle ID | `tw.antsicare.app` | iOS / Android 統一 |
| Firebase Project | `antsicare-tw` | 全台專案 ID |

---

## 專案結構

```
AnTsiSeCare/
├── app/
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/        # AppConstants（22 縣市 + 鄉鎮完整資料）
│   │   │   ├── models/           # UserModel、LtcResourceModel
│   │   │   ├── services/         # LtcDataService、SyncService、NotificationService
│   │   │   ├── theme/            # AppColors（WCAG AAA 無障礙色彩）
│   │   │   └── utils/            # TimezoneUtils（Asia/Taipei UTC+8）
│   │   └── features/
│   │       ├── auth/             # OTP 登入、角色選擇、語言選擇
│   │       ├── care_log/         # 照護日誌（新增 / 編輯 / 列表）
│   │       ├── family/           # 家庭檢視
│   │       ├── home/             # 首頁、底部導覽列
│   │       ├── medication/       # 用藥管理
│   │       ├── profile/          # 個人設定
│   │       ├── resource_map/     # 長照資源地圖（全台縣市篩選）
│   │       └── sos/              # SOS 緊急求救
│   ├── test/                     # Dart 單元測試
│   ├── firestore.rules           # Firestore 安全規則
│   └── pubspec.yaml
├── demo/
│   └── index.html                # 互動展示網頁（Leaflet OSM + 全台篩選）
├── test_runner.js                 # Node.js 測試執行器（66 tests）
├── USER_MANUAL.md                 # 完整功能操作說明（13 章）
├── PLANNING.md
├── ARCHITECTURE.md
├── DATABASE.md
├── UIUX.md
├── API.md
├── I18N.md
├── ROADMAP.md
├── DEPLOY_IOS.md
└── DEPLOY_ANDROID.md
```

---

## 快速執行測試

Flutter 環境未就緒時，使用 Node.js 測試執行器（共 66 項）：

```bash
node test_runner.js
```

| 測試套件 | 項目數 | 涵蓋範圍 |
|----------|--------|----------|
| timezone_utils | 5 | UTC+8 轉換、台北日期格式 |
| ltc_data_service | 19 | 全台縣市篩選、CSV 解析、關鍵字搜尋 |
| notification_service | 11 | 多語言推播模板、placeholder 替換 |
| care_log_model | 20 | 照護狀態、生命徵象異常判斷邊界值 |

---

## 規劃文件索引

| 文件 | 說明 |
|------|------|
| [USER_MANUAL.md](./USER_MANUAL.md) | 功能操作說明（13 章，使用者導向）|
| [PLANNING.md](./PLANNING.md) | 產品規劃：角色、功能模組、全台在地化、KPI |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | 技術架構：Flutter、Firebase、OSM |
| [DATABASE.md](./DATABASE.md) | Firestore 資料結構與索引設計 |
| [UIUX.md](./UIUX.md) | WCAG AAA 無障礙設計規範 |
| [API.md](./API.md) | Firebase / Cloud Functions API 文件 |
| [I18N.md](./I18N.md) | 多語言國際化：印尼語優先、ARB 格式 |
| [ROADMAP.md](./ROADMAP.md) | 開發路線圖：四個 Phase |
| [DEPLOY_IOS.md](./DEPLOY_IOS.md) | iOS App Store 上架說明 |
| [DEPLOY_ANDROID.md](./DEPLOY_ANDROID.md) | Android Google Play 上架說明 |

---

## 重要聯絡電話

| 服務 | 電話 | 說明 |
|------|------|------|
| 長照服務專線 | **1966** | 長照 2.0 資源諮詢 |
| 移工諮詢專線 | **1955** | 支援印尼語 / 越南語 / 泰語 |
| 緊急救護 | **119** | 24 小時 |
| 警察報案 | **110** | 24 小時 |

---

## 授權

MIT License © 2025 AnTsiSeCare Team
