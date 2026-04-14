# AnTsiSeCare（安心照護）

> 以苗栗縣為場域的台灣長照服務整合 APP

## 專案簡介

AnTsiSeCare 是一款專為苗栗縣設計的長照數位平台，整合苗栗縣 18 個鄉鎮市的長照 A/B/C 級服務資源，提供長者、家庭照顧者、居家照服員與照管專員一站式數位化服務。

## 規劃文件索引

| 文件 | 說明 |
|------|------|
| [PLANNING.md](./PLANNING.md) | APP 整體規劃：使用者角色、功能模組、苗栗在地化、KPI |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | 技術架構：前後端技術棧、雲端基礎設施、安全設計 |
| [DATABASE.md](./DATABASE.md) | 資料庫設計：Prisma Schema、Entity Relationship、索引 |
| [UIUX.md](./UIUX.md) | UI/UX 規範：色彩、字體、元件、無障礙、客語介面 |
| [API.md](./API.md) | API 設計：REST 端點、Request/Response 格式 |
| [ROADMAP.md](./ROADMAP.md) | 開發路線圖：四個 Phase、團隊分工、風險管理 |

## 核心功能

- 長照資源地圖（苗栗縣 A/B/C 級機構）
- 個人化照護計畫管理
- 服務預約與電子日誌
- SOS 緊急通報系統
- 健康監測與用藥提醒
- 費用管理與補助試算
- 客語語音介面（四縣腔）
- 長者無障礙模式

## 技術棧

- **APP**：React Native 0.74（TypeScript）
- **後端**：NestJS + PostgreSQL + Prisma
- **快取**：Redis
- **推播**：Firebase Cloud Messaging
- **地圖**：Google Maps API

## 服務場域

苗栗縣 18 個鄉鎮市：苗栗市、頭份市、竹南鎮、苑裡鎮、通霄鎮、後龍鎮、銅鑼鄉、三義鄉、西湖鄉、造橋鄉、頭屋鄉、公館鄉、大湖鄉、泰安鄉、南庄鄉、獅潭鄉、三灣鄉、卓蘭鎮
