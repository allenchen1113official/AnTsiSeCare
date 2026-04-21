# AnTsiSeCare（安心照護）

> 以苗栗縣為場域的台灣長照服務整合 APP

## 專案簡介

AnTsiSeCare 是一款專為苗栗縣設計的長照數位平台，整合苗栗縣 18 個鄉鎮市的長照 A/B/C 級服務資源，提供長者、家庭照顧者、居家照服員與照管專員一站式數位化服務。

## 規劃文件索引

| 文件 | 說明 |
|------|------|
| [PLANNING.md](./PLANNING.md) | APP 整體規劃：使用者角色（含印尼籍看護工）、功能模組、苗栗在地化、KPI |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | 技術架構：前後端技術棧、i18n 框架、雲端基礎設施、安全設計 |
| [DATABASE.md](./DATABASE.md) | 資料庫設計：Prisma Schema、Entity Relationship、索引 |
| [UIUX.md](./UIUX.md) | UI/UX 規範：色彩、字體、元件、無障礙、多語言介面設計 |
| [API.md](./API.md) | API 設計：REST 端點、Request/Response 格式 |
| [I18N.md](./I18N.md) | 多語言國際化：印尼語優先、i18next 實作、自動翻譯橋梁 |
| [ROADMAP.md](./ROADMAP.md) | 開發路線圖：四個 Phase（含 i18n 計畫）、團隊分工、風險管理 |

## 多語言支援

| 語言 | 代碼 | 族群 | 狀態 |
|------|------|------|------|
| 繁體中文 | zh-TW | 長者、家屬、照管專員 | 完整支援 |
| 印尼語 Bahasa Indonesia | id | 印尼籍家庭看護工 | 第一優先 |
| 客語（四縣腔） | hak-TW | 苗栗在地長者 | 語音輔助 |
| English | en | 機構管理員 | 管理後台 |
| 越南語 | vi | 越南籍看護工 | 規劃中 |

## 核心功能

- 長照資源地圖（苗栗縣 A/B/C 級機構）
- 個人化照護計畫管理
- 服務預約與電子日誌（**印尼語填寫 → 自動翻譯中文**）
- SOS 緊急通報系統（含印尼語語音指引 + 1955 移工專線）
- 健康監測與用藥提醒
- 費用管理與補助試算
- 客語語音介面（四縣腔）
- 長者無障礙模式
- 雙語照護詞彙學習模組

## 技術棧

- **APP**：React Native 0.74（TypeScript）
- **多語言**：i18next + react-i18next
- **翻譯**：Claude API（照護日誌自動翻譯）
- **後端**：NestJS + PostgreSQL + Prisma
- **快取**：Redis
- **推播**：Firebase Cloud Messaging（多語言）
- **地圖**：Google Maps API

## 服務場域

苗栗縣 18 個鄉鎮市：苗栗市、頭份市、竹南鎮、苑裡鎮、通霄鎮、後龍鎮、銅鑼鄉、三義鄉、西湖鄉、造橋鄉、頭屋鄉、公館鄉、大湖鄉、泰安鄉、南庄鄉、獅潭鄉、三灣鄉、卓蘭鎮
