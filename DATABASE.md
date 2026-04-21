# AnTsiSeCare - 資料庫結構設計

> 使用 PostgreSQL + Prisma ORM

---

## 一、Entity Relationship 概覽

```
User ─── Elder Profile
 │  └── Family Profile
 │  └── Caregiver Profile
 │  └── CareManager Profile
 │
 ├── CarePlan ─── CarePlanGoal
 │       └── CareService (照護服務項目)
 │
 ├── Booking (服務預約)
 │       └── BookingReview (服務評價)
 │
 ├── CareLog (照護日誌)
 │       └── CareLogAttachment
 │
 ├── HealthRecord (健康記錄)
 │       └── Medication (用藥)
 │       └── MedicationLog (服藥記錄)
 │
 ├── EmergencyAlert (緊急通報)
 │
 └── Notification (通知)

Institution (機構) ─── CareService
                  └── Booking
                  └── StaffSchedule (排班)

Resource (長照資源) ─── ResourceService (服務項目)
```

---

## 二、Prisma Schema

```prisma
// schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// =====================
// 使用者核心資料
// =====================

enum UserRole {
  ELDER           // 長者本人
  FAMILY          // 家庭照顧者
  CAREGIVER       // 照服員
  CARE_MANAGER    // 照管專員
  INSTITUTION_ADMIN
  SYSTEM_ADMIN
}

enum Gender {
  MALE
  FEMALE
  OTHER
}

model User {
  id            String    @id @default(cuid())
  phone         String    @unique          // 手機號碼（台灣格式）
  passwordHash  String?
  role          UserRole
  isActive      Boolean   @default(true)
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  lastLoginAt   DateTime?

  // 關聯
  elderProfile      ElderProfile?
  familyProfile     FamilyProfile?
  caregiverProfile  CaregiverProfile?
  careManagerProfile CareManagerProfile?
  notifications     Notification[]
  emergencyAlerts   EmergencyAlert[]
  sentMessages      Message[]

  @@map("users")
}

model ElderProfile {
  id              String    @id @default(cuid())
  userId          String    @unique
  user            User      @relation(fields: [userId], references: [id])

  // 基本資料（加密欄位）
  nameEncrypted   String                    // 姓名（加密）
  idNumberEncrypted String?                 // 身分證號（加密）
  birthDate       DateTime
  gender          Gender
  township        String                    // 苗栗縣鄉鎮市
  addressEncrypted String?                  // 地址（加密）
  photo           String?                   // S3 URL

  // 健康基本資料
  disabilityLevel Int?                      // 失能等級 1-8
  dementia        Boolean   @default(false) // 失智症
  aboriginalStatus Boolean  @default(false) // 原住民身分
  lowIncomeStatus Boolean   @default(false) // 低收入戶

  // 緊急聯絡人
  emergencyContacts EmergencyContact[]

  // 安全範圍（失智遊走警報）
  safeZoneLat     Float?
  safeZoneLng     Float?
  safeZoneRadius  Int?                      // 公尺

  // 關聯
  carePlans       CarePlan[]
  healthRecords   HealthRecord[]
  medications     Medication[]
  caregiverRelations ElderCaregiverRelation[]
  familyRelations    ElderFamilyRelation[]

  @@map("elder_profiles")
}

model EmergencyContact {
  id            String    @id @default(cuid())
  elderProfileId String
  elderProfile  ElderProfile @relation(fields: [elderProfileId], references: [id])
  name          String
  phone         String
  relationship  String    // 子女、配偶、親戚等
  priority      Int       // 撥打順序 1, 2, 3...
  isActive      Boolean   @default(true)

  @@map("emergency_contacts")
}

model FamilyProfile {
  id       String @id @default(cuid())
  userId   String @unique
  user     User   @relation(fields: [userId], references: [id])
  nameEncrypted String
  elders   ElderFamilyRelation[]

  @@map("family_profiles")
}

model ElderFamilyRelation {
  id             String       @id @default(cuid())
  elderProfileId String
  familyProfileId String
  relationship   String
  canViewRecords Boolean      @default(true)
  canBookService Boolean      @default(false)
  elderProfile   ElderProfile @relation(fields: [elderProfileId], references: [id])
  familyProfile  FamilyProfile @relation(fields: [familyProfileId], references: [id])

  @@unique([elderProfileId, familyProfileId])
  @@map("elder_family_relations")
}

model CaregiverProfile {
  id              String   @id @default(cuid())
  userId          String   @unique
  user            User     @relation(fields: [userId], references: [id])
  nameEncrypted   String
  institutionId   String?
  institution     Institution? @relation(fields: [institutionId], references: [id])
  certificateNo   String?      // 照服員證號
  canSpeakHakka   Boolean  @default(false)  // 客語能力
  canSpeakIndigenous Boolean @default(false)
  serviceArea     String[] // 可服務鄉鎮市清單
  bookings        Booking[]
  elderRelations  ElderCaregiverRelation[]
  schedules       StaffSchedule[]

  @@map("caregiver_profiles")
}

model ElderCaregiverRelation {
  id              String          @id @default(cuid())
  elderProfileId  String
  caregiverProfileId String
  startDate       DateTime
  endDate         DateTime?
  elderProfile    ElderProfile    @relation(fields: [elderProfileId], references: [id])
  caregiverProfile CaregiverProfile @relation(fields: [caregiverProfileId], references: [id])

  @@map("elder_caregiver_relations")
}

model CareManagerProfile {
  id            String   @id @default(cuid())
  userId        String   @unique
  user          User     @relation(fields: [userId], references: [id])
  nameEncrypted String
  staffId       String?  // 員工編號
  serviceArea   String[] // 負責鄉鎮市
  carePlans     CarePlan[]

  @@map("care_manager_profiles")
}

// =====================
// 機構管理
// =====================

enum InstitutionLevel {
  A  // A級旗艦店
  B  // B級複合型服務中心
  C  // C級巷弄長照站
}

model Institution {
  id            String          @id @default(cuid())
  name          String
  level         InstitutionLevel
  township      String          // 鄉鎮市
  address       String
  phone         String
  email         String?
  lat           Float
  lng           Float
  openHours     Json            // 營業時間 JSON
  capacity      Int?            // 日照名額
  currentOccupancy Int         @default(0)
  rating        Float?          // 評鑑星等
  isActive      Boolean         @default(true)
  services      InstitutionService[]
  bookings      Booking[]
  caregivers    CaregiverProfile[]
  schedules     StaffSchedule[]

  @@map("institutions")
}

model InstitutionService {
  id            String      @id @default(cuid())
  institutionId String
  institution   Institution @relation(fields: [institutionId], references: [id])
  serviceType   ServiceType
  description   String?
  unitPrice     Decimal?    // 自費單價
  isActive      Boolean     @default(true)

  @@map("institution_services")
}

enum ServiceType {
  HOME_CARE          // 居家照顧
  DAY_CARE           // 日間照顧
  TRANSPORT          // 交通接送
  MEAL_DELIVERY      // 送餐服務
  RESPITE            // 喘息服務
  BATHING            // 沐浴服務
  PHYSICAL_THERAPY   // 物理治療
  OCCUPATIONAL_THERAPY // 職能治療
  NURSING            // 護理服務
  DEMENTIA_CARE      // 失智照護
  INDIGENOUS_CARE    // 原住民族長照
}

// =====================
// 照護計畫
// =====================

enum CarePlanStatus {
  DRAFT
  ACTIVE
  REVIEWING
  COMPLETED
  CANCELLED
}

model CarePlan {
  id              String         @id @default(cuid())
  elderProfileId  String
  elderProfile    ElderProfile   @relation(fields: [elderProfileId], references: [id])
  careManagerId   String?
  careManager     CareManagerProfile? @relation(fields: [careManagerId], references: [id])
  status          CarePlanStatus @default(DRAFT)
  startDate       DateTime
  endDate         DateTime?
  adlScore        Int?           // ADL 量表分數
  iadlScore       Int?           // IADL 量表分數
  needsAssessment Json           // 需求評估 JSON
  services        CarePlanService[]
  goals           CarePlanGoal[]
  createdAt       DateTime       @default(now())
  updatedAt       DateTime       @updatedAt

  @@map("care_plans")
}

model CarePlanService {
  id          String      @id @default(cuid())
  carePlanId  String
  carePlan    CarePlan    @relation(fields: [carePlanId], references: [id])
  serviceType ServiceType
  frequency   String      // 每週幾次
  duration    Int         // 每次分鐘數
  govSubsidy  Decimal?    // 政府補助額
  selfPay     Decimal?    // 自費金額

  @@map("care_plan_services")
}

model CarePlanGoal {
  id          String   @id @default(cuid())
  carePlanId  String
  carePlan    CarePlan @relation(fields: [carePlanId], references: [id])
  description String
  targetDate  DateTime?
  isAchieved  Boolean  @default(false)

  @@map("care_plan_goals")
}

// =====================
// 服務預約
// =====================

enum BookingStatus {
  PENDING
  CONFIRMED
  IN_PROGRESS
  COMPLETED
  CANCELLED
  NO_SHOW
}

model Booking {
  id              String         @id @default(cuid())
  elderProfileId  String
  institutionId   String
  institution     Institution    @relation(fields: [institutionId], references: [id])
  caregiverProfileId String?
  caregiver       CaregiverProfile? @relation(fields: [caregiverProfileId], references: [id])
  serviceType     ServiceType
  scheduledAt     DateTime
  durationMinutes Int
  status          BookingStatus  @default(PENDING)
  notes           String?
  cancelReason    String?
  careLogs        CareLog[]
  review          BookingReview?
  createdAt       DateTime       @default(now())
  updatedAt       DateTime       @updatedAt

  @@map("bookings")
}

model BookingReview {
  id        String  @id @default(cuid())
  bookingId String  @unique
  booking   Booking @relation(fields: [bookingId], references: [id])
  rating    Int     // 1-5
  comment   String?
  createdAt DateTime @default(now())

  @@map("booking_reviews")
}

// =====================
// 照護日誌
// =====================

model CareLog {
  id            String   @id @default(cuid())
  bookingId     String
  booking       Booking  @relation(fields: [bookingId], references: [id])
  checkInTime   DateTime
  checkOutTime  DateTime?
  checkInLat    Float?
  checkInLng    Float?
  serviceContent String  // 服務內容說明
  elderCondition String? // 長者狀況觀察
  abnormalEvents String? // 異常事件記錄
  attachments   CareLogAttachment[]
  createdAt     DateTime @default(now())

  @@map("care_logs")
}

model CareLogAttachment {
  id        String  @id @default(cuid())
  careLogId String
  careLog   CareLog @relation(fields: [careLogId], references: [id])
  fileUrl   String  // S3 URL
  fileType  String  // image, video, document
  createdAt DateTime @default(now())

  @@map("care_log_attachments")
}

// =====================
// 健康監測
// =====================

model HealthRecord {
  id             String       @id @default(cuid())
  elderProfileId String
  elderProfile   ElderProfile @relation(fields: [elderProfileId], references: [id])
  recordedAt     DateTime
  recordedBy     String?      // userId
  systolicBP     Int?         // 收縮壓 mmHg
  diastolicBP    Int?         // 舒張壓 mmHg
  bloodSugar     Decimal?     // 血糖 mg/dL
  temperature    Decimal?     // 體溫 °C
  heartRate      Int?         // 心率 bpm
  weight         Decimal?     // 體重 kg
  oxygenSat      Int?         // 血氧飽和度 %
  moodScore      Int?         // 情緒評分 1-5
  notes          String?

  @@map("health_records")
}

model Medication {
  id             String       @id @default(cuid())
  elderProfileId String
  elderProfile   ElderProfile @relation(fields: [elderProfileId], references: [id])
  name           String       // 藥名
  dosage         String       // 劑量
  frequency      String       // 用藥頻率
  startDate      DateTime
  endDate        DateTime?
  reminderTimes  String[]     // 提醒時間列表 ["08:00", "20:00"]
  isActive       Boolean      @default(true)
  logs           MedicationLog[]

  @@map("medications")
}

model MedicationLog {
  id           String     @id @default(cuid())
  medicationId String
  medication   Medication @relation(fields: [medicationId], references: [id])
  scheduledAt  DateTime
  takenAt      DateTime?
  isTaken      Boolean    @default(false)
  skippedReason String?

  @@map("medication_logs")
}

// =====================
// 緊急通報
// =====================

enum AlertType {
  SOS_BUTTON      // 手動按 SOS
  FALL_DETECTED   // 跌倒偵測
  WANDERING       // 遊走警報
  HEALTH_ABNORMAL // 健康數值異常
}

enum AlertStatus {
  TRIGGERED
  NOTIFYING
  RESPONDING
  RESOLVED
  FALSE_ALARM
}

model EmergencyAlert {
  id           String      @id @default(cuid())
  userId       String
  user         User        @relation(fields: [userId], references: [id])
  alertType    AlertType
  status       AlertStatus @default(TRIGGERED)
  lat          Float?
  lng          Float?
  resolvedAt   DateTime?
  resolvedBy   String?
  notes        String?
  createdAt    DateTime    @default(now())

  @@map("emergency_alerts")
}

// =====================
// 通知系統
// =====================

enum NotificationType {
  BOOKING_REMINDER     // 預約提醒
  MEDICATION_REMINDER  // 用藥提醒
  CARE_LOG_UPDATED     // 照護日誌更新
  HEALTH_ALERT         // 健康異常警示
  CARE_PLAN_UPDATED    // 照護計畫更新
  EMERGENCY            // 緊急通報
  SYSTEM               // 系統公告
}

model Notification {
  id        String           @id @default(cuid())
  userId    String
  user      User             @relation(fields: [userId], references: [id])
  type      NotificationType
  title     String
  body      String
  data      Json?            // 額外資料（跳頁參數）
  isRead    Boolean          @default(false)
  sentAt    DateTime         @default(now())

  @@map("notifications")
}

// =====================
// 排班管理
// =====================

model StaffSchedule {
  id               String           @id @default(cuid())
  caregiverProfileId String
  caregiver        CaregiverProfile @relation(fields: [caregiverProfileId], references: [id])
  institutionId    String
  institution      Institution      @relation(fields: [institutionId], references: [id])
  workDate         DateTime
  startTime        String           // "08:00"
  endTime          String           // "17:00"
  isLeave          Boolean          @default(false)
  leaveReason      String?

  @@map("staff_schedules")
}

// =====================
// 訊息系統
// =====================

model Message {
  id         String   @id @default(cuid())
  senderId   String
  sender     User     @relation(fields: [senderId], references: [id])
  receiverId String
  content    String
  isRead     Boolean  @default(false)
  sentAt     DateTime @default(now())

  @@map("messages")
}
```

---

## 三、索引設計

```sql
-- 常用查詢索引
CREATE INDEX idx_elder_township ON elder_profiles(township);
CREATE INDEX idx_booking_scheduled ON bookings(scheduled_at, status);
CREATE INDEX idx_health_record_elder ON health_records(elder_profile_id, recorded_at DESC);
CREATE INDEX idx_care_log_booking ON care_logs(booking_id);
CREATE INDEX idx_notification_user ON notifications(user_id, is_read, sent_at DESC);
CREATE INDEX idx_emergency_alert_user ON emergency_alerts(user_id, created_at DESC);
CREATE INDEX idx_institution_township ON institutions(township, level, is_active);
```

---

## 四、資料種子（苗栗縣初始資料）

```typescript
// seed.ts - 苗栗縣18鄉鎮市初始長照資源
const miaoliTownships = [
  "苗栗市", "頭份市", "竹南鎮", "苑裡鎮", "通霄鎮",
  "後龍鎮", "銅鑼鄉", "三義鄉", "西湖鄉", "造橋鄉",
  "頭屋鄉", "公館鄉", "大湖鄉", "泰安鄉", "南庄鄉",
  "獅潭鄉", "三灣鄉", "卓蘭鎮"
];
```
