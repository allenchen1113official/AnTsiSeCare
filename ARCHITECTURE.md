# AnTsiSeCare - 技術架構設計

---

## 一、技術架構總覽

```
┌─────────────────────────────────────────────────────────────┐
│                        使用者裝置                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  iOS App     │  │ Android App  │  │   Web Admin      │  │
│  │ (React Native│  │(React Native)│  │   (React.js)     │  │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘  │
└─────────┼─────────────────┼───────────────────┼────────────┘
          │                 │                   │
          └─────────────────┴───────────────────┘
                            │ HTTPS / WebSocket
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway Layer                       │
│              (AWS API Gateway / Nginx)                       │
│         - Rate Limiting  - Auth Token Validation             │
│         - SSL Termination  - Load Balancing                  │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                    Backend Services                          │
│  ┌────────────┐ ┌────────────┐ ┌─────────────┐             │
│  │ Auth       │ │ Care Plan  │ │ Notification│             │
│  │ Service    │ │ Service    │ │ Service     │             │
│  └────────────┘ └────────────┘ └─────────────┘             │
│  ┌────────────┐ ┌────────────┐ ┌─────────────┐             │
│  │ Resource   │ │ Emergency  │ │ Health      │             │
│  │ Service    │ │ Service    │ │ Monitor     │             │
│  └────────────┘ └────────────┘ └─────────────┘             │
│              Node.js (NestJS) Microservices                  │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                      Data Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  PostgreSQL  │  │    Redis     │  │   AWS S3         │  │
│  │  (主資料庫)  │  │  (快取/Session│  │  (檔案儲存)      │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 二、前端技術棧

### 2.1 行動 APP（iOS / Android）

| 技術 | 選擇 | 理由 |
|------|------|------|
| 框架 | React Native 0.74+ | 跨平台、社群成熟、效能接近原生 |
| 語言 | TypeScript | 型別安全、維護性高 |
| 狀態管理 | Zustand + React Query | 輕量、搭配 API 快取 |
| UI 元件庫 | React Native Paper | Material Design 3、無障礙支援好 |
| 導航 | React Navigation v6 | 業界標準 |
| 地圖 | react-native-maps | Google Maps 整合 |
| 推播通知 | Firebase Cloud Messaging | iOS + Android 統一，多語言 payload |
| 本地儲存 | MMKV | 高效能本地儲存（替代 AsyncStorage） |
| 離線支援 | WatermelonDB | 本地資料庫，離線模式 |
| 無障礙 | React Native Accessibility API | 符合 WCAG 2.1 |
| **多語言（i18n）** | **i18next + react-i18next** | **支援 zh-TW / id / en，自動偵測裝置語言** |
| **語言偵測** | **react-native-localize** | **偵測裝置語言，印尼系統自動切換** |
| **翻譯 AI** | **Claude API (claude-sonnet-4-6)** | **照護日誌自動翻譯（中文↔印尼語）** |

### 2.2 Web 管理後台

| 技術 | 選擇 |
|------|------|
| 框架 | Next.js 14 (App Router) |
| UI | Ant Design 5 + Tailwind CSS |
| 圖表 | Recharts |
| 表單 | React Hook Form + Zod |
| 認證 | NextAuth.js |

### 2.3 APP 頁面結構

```
App
├── 未登入流程
│   ├── 歡迎頁（onboarding）
│   ├── 登入頁
│   └── 角色選擇
├── 主要 Tab 導航
│   ├── 首頁（Home）
│   ├── 資源地圖（Map）
│   ├── 我的照護（Care）
│   ├── 緊急 SOS（SOS）
│   └── 更多（More）
└── 功能頁面群組
    ├── 照護計畫相關
    ├── 服務預約相關
    ├── 健康記錄相關
    └── 設定相關
```

---

## 三、後端技術棧

### 3.1 核心框架

| 技術 | 選擇 | 說明 |
|------|------|------|
| 語言 | Node.js + TypeScript | 生態系豐富 |
| 框架 | NestJS | 模組化、適合微服務 |
| ORM | Prisma | 型別安全、migration 管理 |
| API 格式 | REST + GraphQL（部分） | REST 為主，GraphQL 用於複雜查詢 |
| 即時通訊 | Socket.IO | 緊急通報、即時通知 |
| 排程任務 | Bull Queue + Redis | 用藥提醒、定期報表 |
| 文件 | Swagger / OpenAPI 3.0 | 自動 API 文件 |

### 3.2 微服務拆分

```
services/
├── auth-service/          # 認證授權（JWT, OAuth2）
├── user-service/          # 使用者管理（含語言偏好）
├── care-plan-service/     # 照護計畫
├── booking-service/       # 服務預約
├── care-log-service/      # 照護日誌（含多語言翻譯）
├── health-service/        # 健康監測
├── emergency-service/     # 緊急通報（多語言語音）
├── resource-service/      # 長照資源地圖
├── notification-service/  # 推播通知（依語言推送）
├── translation-service/   # 多語言翻譯服務（Claude API + 術語表）
└── report-service/        # 報表統計（多語言輸出）
```

### 3.3 認證與授權

```
認證流程：
1. 使用者登入（手機號碼 + OTP 驗證碼）
2. 後端產生 JWT Access Token（15分鐘）+ Refresh Token（30天）
3. Access Token 存於記憶體，Refresh Token 存於 HttpOnly Cookie
4. 角色基礎存取控制（RBAC）：
   - elder：長者本人
   - family：家庭照顧者
   - caregiver：照服員
   - care_manager：照管專員
   - institution_admin：機構管理員
   - system_admin：系統管理員
```

---

## 四、資料庫架構

### 4.1 PostgreSQL（主資料庫）
- 使用者資料、照護計畫、服務記錄
- 敏感健康資料使用 pgcrypto 加密

### 4.2 Redis（快取層）
- Session 管理
- OTP 驗證碼（TTL 5分鐘）
- 長照資源列表快取（TTL 1小時）
- 實時位置暫存

### 4.3 AWS S3（檔案儲存）
- 使用者頭像
- 照護記錄附件（照片、影片）
- 報表 PDF 檔案

---

## 五、雲端基礎設施

### 5.1 AWS 架構（建議）

```
Route 53（DNS）
    │
CloudFront（CDN）
    │
Application Load Balancer
    ├── ECS Fargate（後端服務）
    │   ├── auth-service
    │   ├── care-plan-service
    │   └── ... 其他微服務
    └── S3 Static（Web Admin）

RDS PostgreSQL（Multi-AZ）
ElastiCache Redis
S3（媒體儲存）
SES（Email 通知）
SNS（SMS 驗證碼）
```

### 5.2 在台灣的替代方案（成本考量）

若預算有限，可採用：
- **Zeabur** 或 **Railway**（後端部署）
- **Supabase**（PostgreSQL + Auth + Storage 一站式）
- **Vercel**（Web Admin 部署）
- **Firebase**（推播通知、實時資料庫）

---

## 六、安全性設計

### 6.1 資料加密
```
傳輸加密：TLS 1.3
靜態加密：AES-256（健康資料）
密碼：bcrypt（cost factor 12）
個資欄位：Column-level encryption（姓名、身分證號、電話）
```

### 6.2 API 安全
- Rate Limiting：登入 API 每分鐘最多5次
- CORS：僅允許指定 origin
- SQL Injection：使用 Prisma ORM（參數化查詢）
- XSS：輸入驗證 + Content Security Policy
- CSRF：SameSite Cookie 設定

### 6.3 個資保護
- 資料最小化原則
- 目的外使用限制
- 刪除權實作
- 存取日誌留存（保存3年）
