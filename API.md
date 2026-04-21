# AnTsiSeCare - API 設計文件

> RESTful API，版本前綴：`/api/v1`
> 所有請求需帶 `Authorization: Bearer <JWT>` Header（除公開端點外）

---

## 一、認證 API（Auth）

### POST `/api/v1/auth/request-otp`
請求手機 OTP 驗證碼

**Request Body:**
```json
{
  "phone": "0912345678"
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "OTP 已發送",
  "expiresIn": 300
}
```

---

### POST `/api/v1/auth/verify-otp`
驗證 OTP，取得登入 Token

**Request Body:**
```json
{
  "phone": "0912345678",
  "otp": "123456"
}
```

**Response 200:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "clxxx",
    "phone": "0912345678",
    "role": "FAMILY",
    "profile": { ... }
  }
}
```

---

### POST `/api/v1/auth/refresh`
刷新 Access Token

**Response 200:**
```json
{
  "accessToken": "eyJ..."
}
```

---

### POST `/api/v1/auth/logout`
登出（清除 Refresh Token）

---

## 二、長照資源 API（Resources）

### GET `/api/v1/resources`
查詢苗栗縣長照資源（公開端點）

**Query Parameters:**
| 參數 | 類型 | 說明 |
|------|------|------|
| township | string | 鄉鎮市名稱（如：苗栗市） |
| level | A \| B \| C | 機構等級 |
| serviceType | string | 服務類型 |
| lat | float | 目前緯度（距離排序用） |
| lng | float | 目前經度 |
| radius | int | 搜尋半徑（公尺，預設 5000） |
| page | int | 頁碼（預設 1） |
| limit | int | 每頁筆數（預設 20） |

**Response 200:**
```json
{
  "data": [
    {
      "id": "inst_001",
      "name": "苗栗市長照A級旗艦服務中心",
      "level": "A",
      "township": "苗栗市",
      "address": "苗栗市中正路 100 號",
      "phone": "037-123456",
      "lat": 24.5678,
      "lng": 120.8234,
      "rating": 4.5,
      "currentOccupancy": 15,
      "capacity": 20,
      "distance": 850,
      "services": ["HOME_CARE", "DAY_CARE", "TRANSPORT"],
      "openHours": {
        "weekday": "08:00-17:00",
        "weekend": "休館"
      }
    }
  ],
  "total": 45,
  "page": 1,
  "totalPages": 3
}
```

---

### GET `/api/v1/resources/:id`
取得單一機構詳細資訊

---

## 三、個人照護計畫 API（Care Plans）

### GET `/api/v1/care-plans`
取得照護計畫列表（依角色返回相應資料）

**Response 200:**
```json
{
  "data": [
    {
      "id": "cp_001",
      "elder": {
        "id": "elder_001",
        "name": "陳阿婆",
        "township": "苗栗市"
      },
      "status": "ACTIVE",
      "startDate": "2026-01-01",
      "adlScore": 60,
      "services": [
        {
          "serviceType": "HOME_CARE",
          "frequency": "每週3次",
          "duration": 120,
          "govSubsidy": 700,
          "selfPay": 200
        }
      ],
      "goals": [
        {
          "description": "恢復獨立進食能力",
          "targetDate": "2026-06-30",
          "isAchieved": false
        }
      ],
      "careManager": {
        "name": "王社工"
      }
    }
  ]
}
```

---

### POST `/api/v1/care-plans`
建立新照護計畫（照管專員權限）

**Request Body:**
```json
{
  "elderProfileId": "elder_001",
  "startDate": "2026-04-14",
  "adlScore": 60,
  "iadlScore": 45,
  "needsAssessment": {
    "mobility": "需協助",
    "feeding": "獨立",
    "bathing": "需協助"
  },
  "services": [
    {
      "serviceType": "HOME_CARE",
      "frequency": "每週3次",
      "duration": 120
    }
  ],
  "goals": [
    {
      "description": "恢復獨立進食能力",
      "targetDate": "2026-06-30"
    }
  ]
}
```

---

### PATCH `/api/v1/care-plans/:id`
更新照護計畫

### GET `/api/v1/care-plans/:id/subsidy-estimate`
試算補助金額

**Response 200:**
```json
{
  "elderDisabilityLevel": 4,
  "monthlyBudget": 36180,
  "usedBudget": 28800,
  "remainingBudget": 7380,
  "selfPayEstimate": 3200,
  "additionalSubsidies": [
    {
      "name": "苗栗縣低收入戶額外補助",
      "amount": 2000
    }
  ]
}
```

---

## 四、服務預約 API（Bookings）

### GET `/api/v1/bookings`
查詢預約列表

**Query Parameters:**
| 參數 | 說明 |
|------|------|
| status | 預約狀態篩選 |
| startDate | 開始日期 |
| endDate | 結束日期 |
| elderProfileId | 長者 ID（照管專員用） |

---

### POST `/api/v1/bookings`
建立新預約

**Request Body:**
```json
{
  "elderProfileId": "elder_001",
  "institutionId": "inst_001",
  "serviceType": "HOME_CARE",
  "scheduledAt": "2026-04-20T09:00:00+08:00",
  "durationMinutes": 120,
  "preferCaregiverGender": "FEMALE",
  "preferHakka": true,
  "notes": "請帶備替換床單"
}
```

**Response 201:**
```json
{
  "id": "booking_001",
  "status": "PENDING",
  "caregiver": {
    "name": "李小姐",
    "phone": "0923xxx",
    "canSpeakHakka": true
  },
  "scheduledAt": "2026-04-20T09:00:00+08:00"
}
```

---

### PATCH `/api/v1/bookings/:id/cancel`
取消預約

**Request Body:**
```json
{
  "cancelReason": "長者臨時住院"
}
```

---

### POST `/api/v1/bookings/:id/review`
服務後評價

**Request Body:**
```json
{
  "rating": 5,
  "comment": "李小姐服務非常細心，推薦！"
}
```

---

## 五、照護日誌 API（Care Logs）

### GET `/api/v1/care-logs`
查詢照護日誌

**Query Parameters:**
| 參數 | 說明 |
|------|------|
| elderProfileId | 長者 ID |
| startDate | 起始日 |
| endDate | 結束日 |

---

### POST `/api/v1/care-logs`
建立照護日誌（照服員）

**Request Body:**
```json
{
  "bookingId": "booking_001",
  "checkInTime": "2026-04-20T09:05:00+08:00",
  "checkInLat": 24.5678,
  "checkInLng": 120.8234,
  "serviceContent": "協助沐浴、準備午餐、陪同散步",
  "elderCondition": "精神狀態良好，食慾正常",
  "abnormalEvents": null
}
```

---

### PATCH `/api/v1/care-logs/:id/checkout`
服務結束打卡

**Request Body:**
```json
{
  "checkOutTime": "2026-04-20T11:00:00+08:00"
}
```

---

### POST `/api/v1/care-logs/:id/attachments`
上傳日誌附件（照片）

**Content-Type:** `multipart/form-data`

**Response 201:**
```json
{
  "id": "att_001",
  "fileUrl": "https://s3.amazonaws.com/antsisecare/...",
  "fileType": "image"
}
```

---

## 六、健康監測 API（Health）

### POST `/api/v1/health-records`
新增健康記錄

**Request Body:**
```json
{
  "elderProfileId": "elder_001",
  "recordedAt": "2026-04-14T08:00:00+08:00",
  "systolicBP": 125,
  "diastolicBP": 82,
  "bloodSugar": 105.5,
  "temperature": 36.5,
  "heartRate": 72,
  "weight": 58.5,
  "moodScore": 4,
  "notes": "今日精神佳"
}
```

---

### GET `/api/v1/health-records`
查詢健康記錄趨勢

**Query Parameters:**
| 參數 | 說明 |
|------|------|
| elderProfileId | 長者 ID |
| metrics | 指標清單（bp,sugar,weight,...） |
| days | 查詢天數（7/14/30/90） |

**Response 200:**
```json
{
  "elder": { "name": "陳阿婆" },
  "period": { "start": "2026-03-15", "end": "2026-04-14" },
  "data": {
    "bloodPressure": [
      { "date": "2026-04-14", "systolic": 125, "diastolic": 82 },
      { "date": "2026-04-13", "systolic": 130, "diastolic": 85 }
    ],
    "bloodSugar": [ ... ],
    "weight": [ ... ]
  },
  "alerts": [
    {
      "date": "2026-04-10",
      "metric": "bloodPressure",
      "message": "收縮壓偏高（145 mmHg），建議就醫"
    }
  ]
}
```

---

### GET `/api/v1/medications`
查詢用藥清單

### POST `/api/v1/medications`
新增用藥記錄

### POST `/api/v1/medications/:id/logs`
回報服藥（打卡）

**Request Body:**
```json
{
  "medicationLogId": "medlog_001",
  "isTaken": true,
  "takenAt": "2026-04-14T08:15:00+08:00"
}
```

---

## 七、緊急通報 API（Emergency）

### POST `/api/v1/emergency/sos`
觸發 SOS 緊急通報

**Request Body:**
```json
{
  "alertType": "SOS_BUTTON",
  "lat": 24.5678,
  "lng": 120.8234
}
```

**Response 200:**
```json
{
  "alertId": "alert_001",
  "status": "NOTIFYING",
  "contactsNotified": [
    { "name": "張大明", "phone": "0912xxx", "notifiedAt": "2026-04-14T10:00:01+08:00" }
  ],
  "message": "已通知 2 位緊急聯絡人"
}
```

---

### PATCH `/api/v1/emergency/:id/resolve`
解除緊急警報

**Request Body:**
```json
{
  "status": "FALSE_ALARM",
  "notes": "誤觸按鈕"
}
```

---

## 八、通知 API（Notifications）

### GET `/api/v1/notifications`
查詢通知列表

**Response 200:**
```json
{
  "data": [
    {
      "id": "notif_001",
      "type": "MEDICATION_REMINDER",
      "title": "用藥提醒",
      "body": "陳阿婆，現在是服用血壓藥的時間（08:00）",
      "isRead": false,
      "sentAt": "2026-04-14T08:00:00+08:00"
    }
  ],
  "unreadCount": 3
}
```

### PATCH `/api/v1/notifications/:id/read`
標記為已讀

### PATCH `/api/v1/notifications/read-all`
全部標記已讀

---

## 九、後台管理 API（Admin）

### GET `/api/v1/admin/dashboard`
管理後台統計（機構管理員）

**Response 200:**
```json
{
  "today": {
    "bookingsCount": 24,
    "completedCount": 18,
    "cancelledCount": 2,
    "alertsCount": 1
  },
  "month": {
    "totalServiceHours": 480,
    "totalElders": 52,
    "satisfaction": 4.6
  },
  "caregivers": {
    "total": 12,
    "onDuty": 8
  }
}
```

---

## 十、API 錯誤格式

```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "請先登入",
    "details": null
  },
  "timestamp": "2026-04-14T10:00:00+08:00"
}
```

**錯誤代碼清單：**
| Code | HTTP Status | 說明 |
|------|-------------|------|
| UNAUTHORIZED | 401 | 未登入或 Token 失效 |
| FORBIDDEN | 403 | 無權限執行此操作 |
| NOT_FOUND | 404 | 資源不存在 |
| VALIDATION_ERROR | 422 | 輸入資料驗證失敗 |
| RATE_LIMIT | 429 | 請求過於頻繁 |
| INTERNAL_ERROR | 500 | 伺服器錯誤 |
