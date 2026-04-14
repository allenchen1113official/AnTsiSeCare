# AnTsiSeCare - Flutter + Firebase 技術實作指導

> 無伺服器（Serverless）架構｜時區：Asia/Taipei（UTC+8）｜印尼語優先

---

## 一、技術棧總覽

| 層級 | 技術 | 說明 |
|------|------|------|
| APP 框架 | Flutter 3.22+ (Dart) | iOS / Android 單一程式碼庫 |
| 後端即服務 | Firebase (Spark 免費方案) | 完全無伺服器 |
| 資料庫 | Cloud Firestore | NoSQL 即時同步 |
| 認證 | Firebase Auth | 手機 OTP 登入 |
| 檔案儲存 | Firebase Storage | 照護照片、語音備註 |
| 推播通知 | Firebase Cloud Messaging | 多語言通知 |
| 本地快取 | Hive | 離線紀錄（偏鄉適用） |
| 多語言 | easy_localization | 5語言 JSON 管理 |
| 地圖 | google_maps_flutter | 機構地圖 |
| 語音輸入 | speech_to_text | 印尼語語音轉文字 |
| 時區 | timezone package | Asia/Taipei (UTC+8) |

---

## 二、Firestore 資料模型設計

### 2.1 時區設定原則

```dart
// 所有 Timestamp 儲存 UTC，顯示時轉換為台北時間
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

void initTimezone() {
  tz.initializeTimeZones();
}

// UTC+8 台北時間轉換
DateTime toTaipeiTime(DateTime utc) {
  final taipei = tz.getLocation('Asia/Taipei');
  return tz.TZDateTime.from(utc, taipei);
}

String formatTaipeiTime(DateTime utc) {
  final local = toTaipeiTime(utc);
  return '${local.year}/${local.month.toString().padLeft(2,'0')}/'
         '${local.day.toString().padLeft(2,'0')} '
         '${local.hour.toString().padLeft(2,'0')}:'
         '${local.minute.toString().padLeft(2,'0')}';
}
```

### 2.2 User Profile

```
Collection: users/{userId}

{
  uid: string,                    // Firebase Auth UID
  phone: string,                  // 台灣手機格式 09xxxxxxxx
  role: 'elder' | 'family' | 'caregiver' | 'care_manager',
  language: 'zh-TW' | 'id' | 'vi' | 'th' | 'en',  // 介面語言
  displayName: string,
  elderIds: string[],             // 關聯的長者 ID（家屬/看護用）
  
  // 看護專屬
  nationality: 'ID' | 'VN' | 'TH' | 'PH' | null,
  prayerReminderEnabled: bool,    // 禱告提醒（印尼籍選用）
  
  // 長者專屬
  disabilityLevel: number,        // 失能等級 1-8
  township: string,               // 苗栗縣鄉鎮市
  safeZone: GeoPoint | null,      // 遊走警報圓心
  safeZoneRadius: number,         // 公尺
  
  createdAt: Timestamp,           // UTC 儲存
  updatedAt: Timestamp,
  timezone: 'Asia/Taipei'         // 固定台北時區
}
```

### 2.3 Daily Care Log（照護日誌）

```
Collection: careLogs/{logId}

{
  elderId: string,
  caregiverId: string,
  
  // 時間（UTC 儲存，顯示時轉台北時間）
  logDate: string,               // 'YYYY-MM-DD'（台北日期）
  checkInAt: Timestamp,          // UTC
  checkOutAt: Timestamp | null,
  checkInLocation: GeoPoint,
  
  // 圖示化勾選項目（語言無關）
  careItems: {
    feeding: 'normal' | 'abnormal' | 'refused' | null,
    medication: 'taken' | 'skipped' | 'partial' | null,
    excretion: 'normal' | 'abnormal' | null,
    bathing: 'done' | 'skipped' | null,
    exercise: 'done' | 'skipped' | null,
    sleep: 'good' | 'poor' | null,
    mood: 'happy' | 'normal' | 'sad' | 'agitated' | null,
    wound: 'stable' | 'worsened' | 'new' | null,
  },
  
  // 生理數值（語言無關，數字）
  vitals: {
    systolicBP: number | null,
    diastolicBP: number | null,
    bloodSugar: number | null,
    temperature: number | null,
    heartRate: number | null,
    weight: number | null,
    oxygenSat: number | null,
  },
  
  // 備註（以看護母語填寫）
  noteOriginal: string,          // 原始語言（印尼語/越南語等）
  noteLang: string,              // 原始語言代碼 'id'
  noteTranslated: string,        // 自動翻譯成中文（Claude API）
  noteTranslatedAt: Timestamp | null,
  
  // 語音備註
  voiceNoteUrl: string | null,   // Firebase Storage URL
  voiceNoteDuration: number,     // 秒數
  
  // 照片
  photoUrls: string[],
  
  // 異常事件
  hasAbnormalEvent: bool,
  abnormalEventType: 'fall' | 'injury' | 'behavior' | 'other' | null,
  abnormalEventNote: string,
  
  // 交接班
  isHandoverDone: bool,
  handoverNote: string,
  handoverReceiverName: string,
  
  syncStatus: 'synced' | 'pending',  // Hive 離線同步狀態
  createdAt: Timestamp,
}
```

### 2.4 Medicine Scheduler（用藥提醒）

```
Collection: medicines/{medicineId}

{
  elderId: string,
  
  // 藥品名稱（多語言）
  nameTW: string,     // 中文名（必填）
  nameID: string,     // 印尼語名（選填）
  nameEN: string,     // 英文名（選填）
  
  dosage: string,     // '5mg'（語言無關）
  dosageNote: string, // 服藥說明（看護母語）
  
  // 排程（台北時間）
  scheduleTimes: string[],  // ['08:00', '20:00']（HH:mm, 台北時間）
  scheduleDays: string[],   // ['mon','tue','wed','thu','fri','sat','sun'] or ['daily']
  
  startDate: string,  // 'YYYY-MM-DD'（台北日期）
  endDate: string | null,
  
  reminderEnabled: bool,
  reminderMinutesBefore: number,  // 提醒提前幾分鐘，預設 10
  
  photoUrl: string | null,  // 藥品照片（看護辨識用）
  isActive: bool,
  createdAt: Timestamp,
}

// 服藥紀錄
Collection: medicationLogs/{logId}

{
  medicineId: string,
  elderId: string,
  caregiverId: string,
  
  scheduledAt: Timestamp,   // 應服藥時間（UTC）
  takenAt: Timestamp | null,
  status: 'taken' | 'skipped' | 'pending',
  skipReason: string,       // 以看護母語填寫
  
  createdAt: Timestamp,
}
```

### 2.5 Emergency Alert（緊急通報）

```
Collection: emergencyAlerts/{alertId}

{
  triggeredBy: string,        // userId
  elderId: string,
  alertType: 'sos_button' | 'fall_detected' | 'wandering' | 'health_alert',
  
  location: GeoPoint,
  address: string,            // 反向地理編碼結果
  
  status: 'triggered' | 'notified' | 'responded' | 'resolved' | 'false_alarm',
  
  notifiedContacts: [{
    name: string,
    phone: string,
    notifiedAt: Timestamp,
  }],
  
  resolvedAt: Timestamp | null,
  resolvedBy: string | null,
  falseAlarmNote: string,
  
  triggeredAt: Timestamp,     // UTC
  triggeredAtTaipei: string,  // 'YYYY-MM-DD HH:mm' 台北時間（供顯示）
}
```

---

## 三、easy_localization 多語言技術棧

### 3.1 pubspec.yaml 設定

```yaml
dependencies:
  flutter:
    sdk: flutter
  easy_localization: ^3.0.7
  flutter_localizations:
    sdk: flutter

flutter:
  assets:
    - assets/translations/
```

### 3.2 main.dart 初始化

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();  // 初始化台北時區
  await EasyLocalization.ensureInitialized();
  
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('zh', 'TW'),  // 繁體中文（預設）
        Locale('id'),        // 印尼語（P1優先）
        Locale('vi'),        // 越南語
        Locale('th'),        // 泰語
        Locale('en'),        // 英語
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('zh', 'TW'),
      // 自動偵測裝置語言
      useOnlyLangCode: false,
      child: const AnTsiSeCareApp(),
    ),
  );
}
```

### 3.3 五語言 JSON 辭典結構範本

#### `assets/translations/zh-TW.json`
```json
{
  "app": {
    "name": "安心照護",
    "tagline": "苗栗縣長照整合平台"
  },
  "nav": {
    "home": "首頁",
    "map": "資源地圖",
    "care": "我的照護",
    "sos": "緊急",
    "more": "更多"
  },
  "careLog": {
    "title": "照護日誌",
    "date": "日期",
    "checkIn": "到達簽到",
    "checkOut": "離開簽退",
    "items": {
      "feeding": "飲食",
      "medication": "用藥",
      "excretion": "排泄",
      "bathing": "沐浴",
      "exercise": "運動",
      "sleep": "睡眠",
      "mood": "情緒",
      "wound": "傷口"
    },
    "status": {
      "normal": "正常",
      "abnormal": "異常",
      "done": "完成",
      "skipped": "略過",
      "taken": "已服藥",
      "refused": "拒食"
    },
    "note": "備註",
    "voiceNote": "語音備註",
    "submit": "送出日誌",
    "familyView": "家屬將以中文查閱"
  },
  "medication": {
    "title": "用藥提醒",
    "addMedicine": "新增藥品",
    "reminderAt": "提醒時間",
    "taken": "已服藥",
    "skip": "跳過"
  },
  "emergency": {
    "sos": "緊急求救",
    "holdToActivate": "長按 3 秒啟動",
    "calling": "正在通知緊急聯絡人",
    "call119": "撥打 119",
    "call1966": "長照專線 1966",
    "call1955": "移工諮詢 1955",
    "location": "目前位置"
  },
  "vitals": {
    "bloodPressure": "血壓",
    "bloodSugar": "血糖",
    "temperature": "體溫",
    "heartRate": "心率",
    "weight": "體重",
    "oxygenSat": "血氧"
  },
  "time": {
    "timezone": "台北時間 (UTC+8)",
    "today": "今天",
    "yesterday": "昨天"
  }
}
```

#### `assets/translations/id.json`（印尼語 P1 優先）
```json
{
  "app": {
    "name": "AnTsiSeCare",
    "tagline": "Platform Perawatan Lansia Miaoli"
  },
  "nav": {
    "home": "Beranda",
    "map": "Peta Layanan",
    "care": "Perawatan Saya",
    "sos": "Darurat",
    "more": "Lainnya"
  },
  "careLog": {
    "title": "Jurnal Perawatan",
    "date": "Tanggal",
    "checkIn": "Absen Tiba",
    "checkOut": "Absen Pulang",
    "items": {
      "feeding": "Makan",
      "medication": "Obat",
      "excretion": "Toilet",
      "bathing": "Mandi",
      "exercise": "Olahraga",
      "sleep": "Tidur",
      "mood": "Emosi",
      "wound": "Luka"
    },
    "status": {
      "normal": "Normal",
      "abnormal": "Tidak Normal",
      "done": "Selesai",
      "skipped": "Dilewati",
      "taken": "Sudah Minum",
      "refused": "Menolak Makan"
    },
    "note": "Catatan",
    "voiceNote": "Rekam Suara",
    "submit": "Kirim Jurnal",
    "familyView": "Keluarga akan melihat dalam 中文"
  },
  "medication": {
    "title": "Pengingat Obat",
    "addMedicine": "Tambah Obat",
    "reminderAt": "Waktu Pengingat",
    "taken": "Sudah Diminum",
    "skip": "Lewati"
  },
  "emergency": {
    "sos": "DARURAT",
    "holdToActivate": "Tahan 3 detik untuk aktifkan",
    "calling": "Menghubungi kontak darurat",
    "call119": "Hubungi 119",
    "call1966": "Layanan LTC 1966",
    "call1955": "Hotline TKI 1955",
    "location": "Lokasi Saat Ini"
  },
  "vitals": {
    "bloodPressure": "Tekanan Darah",
    "bloodSugar": "Gula Darah",
    "temperature": "Suhu",
    "heartRate": "Detak Jantung",
    "weight": "Berat Badan",
    "oxygenSat": "Saturasi O2"
  },
  "time": {
    "timezone": "Waktu Taipei (UTC+8)",
    "today": "Hari Ini",
    "yesterday": "Kemarin"
  }
}
```

#### `assets/translations/vi.json`（越南語）
```json
{
  "app": { "name": "AnTsiSeCare", "tagline": "Nền tảng chăm sóc dài hạn Miaoli" },
  "nav": {
    "home": "Trang chủ", "map": "Bản đồ dịch vụ",
    "care": "Chăm sóc của tôi", "sos": "Khẩn cấp", "more": "Thêm"
  },
  "careLog": {
    "title": "Nhật ký chăm sóc",
    "checkIn": "Điểm danh đến", "checkOut": "Điểm danh về",
    "items": {
      "feeding": "Ăn uống", "medication": "Thuốc", "excretion": "Vệ sinh",
      "bathing": "Tắm rửa", "exercise": "Tập thể dục", "sleep": "Ngủ",
      "mood": "Cảm xúc", "wound": "Vết thương"
    },
    "status": {
      "normal": "Bình thường", "abnormal": "Bất thường",
      "done": "Hoàn thành", "taken": "Đã uống thuốc"
    },
    "submit": "Gửi nhật ký",
    "familyView": "Gia đình sẽ xem bằng tiếng Trung"
  },
  "emergency": {
    "sos": "KHẨN CẤP", "holdToActivate": "Giữ 3 giây để kích hoạt",
    "call119": "Gọi 119", "call1955": "Đường dây lao động 1955"
  }
}
```

#### `assets/translations/th.json`（泰語）
```json
{
  "app": { "name": "AnTsiSeCare", "tagline": "แพลตฟอร์มดูแลผู้สูงอายุเมียวลี่" },
  "nav": {
    "home": "หน้าหลัก", "map": "แผนที่บริการ",
    "care": "การดูแลของฉัน", "sos": "ฉุกเฉิน", "more": "เพิ่มเติม"
  },
  "careLog": {
    "title": "บันทึกการดูแล",
    "checkIn": "เช็คอินเข้างาน", "checkOut": "เช็คเอาท์",
    "items": {
      "feeding": "อาหาร", "medication": "ยา", "excretion": "ห้องน้ำ",
      "bathing": "อาบน้ำ", "exercise": "ออกกำลัง", "sleep": "นอนหลับ",
      "mood": "อารมณ์", "wound": "แผล"
    },
    "status": {
      "normal": "ปกติ", "abnormal": "ผิดปกติ",
      "done": "เสร็จแล้ว", "taken": "รับประทานยาแล้ว"
    },
    "submit": "ส่งบันทึก",
    "familyView": "ครอบครัวจะดูเป็นภาษาจีน"
  },
  "emergency": {
    "sos": "ฉุกเฉิน", "holdToActivate": "กดค้างไว้ 3 วินาที",
    "call119": "โทร 119", "call1955": "สายด่วนแรงงาน 1955"
  }
}
```

#### `assets/translations/en.json`（英語）
```json
{
  "app": { "name": "AnTsiSeCare", "tagline": "Miaoli Long-Term Care Platform" },
  "nav": {
    "home": "Home", "map": "Resource Map",
    "care": "My Care", "sos": "Emergency", "more": "More"
  },
  "careLog": {
    "title": "Care Log", "checkIn": "Check In", "checkOut": "Check Out",
    "items": {
      "feeding": "Feeding", "medication": "Medication", "excretion": "Excretion",
      "bathing": "Bathing", "exercise": "Exercise", "sleep": "Sleep",
      "mood": "Mood", "wound": "Wound"
    },
    "status": {
      "normal": "Normal", "abnormal": "Abnormal",
      "done": "Done", "taken": "Taken"
    },
    "submit": "Submit Log",
    "familyView": "Family will view in Chinese"
  },
  "emergency": {
    "sos": "SOS", "holdToActivate": "Hold 3 seconds to activate",
    "call119": "Call 119", "call1955": "Migrant Hotline 1955"
  }
}
```

---

## 四、離線 Hive + Firestore 背景同步邏輯

### 4.1 架構設計

```
看護操作APP（偏鄉弱訊號）
    ↓ 寫入
Hive 本地儲存（立即成功，不等網路）
    ↓ 背景
ConnectivityService 監聽網路狀態
    ↓ 網路恢復時
SyncService 批次上傳 pending 資料
    ↓
Firestore（家屬端即時收到通知）
    ↓
FCM 推播通知（多語言）
```

### 4.2 Hive 模型定義

```dart
import 'package:hive/hive.dart';

part 'care_log_local.g.dart';

@HiveType(typeId: 0)
class CareLogLocal extends HiveObject {
  @HiveField(0) late String logId;           // UUID
  @HiveField(1) late String elderId;
  @HiveField(2) late String caregiverId;
  @HiveField(3) late String logDate;         // YYYY-MM-DD 台北日期
  @HiveField(4) late DateTime checkInAt;     // UTC
  @HiveField(5) late Map<String, String?> careItems;
  @HiveField(6) late Map<String, double?> vitals;
  @HiveField(7) late String noteOriginal;
  @HiveField(8) late String noteLang;
  @HiveField(9) late String noteTranslated;
  @HiveField(10) late List<String> photoUrls;
  @HiveField(11) late String syncStatus;    // 'pending' | 'synced'
  @HiveField(12) late DateTime createdAt;   // UTC
}

@HiveType(typeId: 1)
class MedicationLogLocal extends HiveObject {
  @HiveField(0) late String logId;
  @HiveField(1) late String medicineId;
  @HiveField(2) late DateTime scheduledAt;  // UTC
  @HiveField(3) late String status;
  @HiveField(4) late String syncStatus;
}
```

### 4.3 SyncService 實作

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:timezone/timezone.dart' as tz;

class SyncService {
  static final _firestore = FirebaseFirestore.instance;
  static final _taipei = tz.getLocation('Asia/Taipei');

  // 啟動監聽（APP 啟動時呼叫）
  static void startSync() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _syncPendingLogs();
        _syncPendingMedLogs();
      }
    });
  }

  // 同步待上傳的照護日誌
  static Future<void> _syncPendingLogs() async {
    final box = Hive.box<CareLogLocal>('careLogs');
    final pending = box.values
        .where((log) => log.syncStatus == 'pending')
        .toList();

    for (final log in pending) {
      try {
        // 計算台北時間日期字串
        final taipeiTime = tz.TZDateTime.from(log.checkInAt, _taipei);
        final logDate =
            '${taipeiTime.year}-'
            '${taipeiTime.month.toString().padLeft(2, '0')}-'
            '${taipeiTime.day.toString().padLeft(2, '0')}';

        await _firestore
            .collection('careLogs')
            .doc(log.logId)
            .set({
          'elderId': log.elderId,
          'caregiverId': log.caregiverId,
          'logDate': logDate,           // 台北日期
          'checkInAt': Timestamp.fromDate(log.checkInAt),
          'careItems': log.careItems,
          'vitals': log.vitals,
          'noteOriginal': log.noteOriginal,
          'noteLang': log.noteLang,
          'noteTranslated': log.noteTranslated,
          'photoUrls': log.photoUrls,
          'syncStatus': 'synced',
          'createdAt': Timestamp.fromDate(log.createdAt),
        });

        log.syncStatus = 'synced';
        await log.save();
      } catch (e) {
        // 保持 pending，下次再試
      }
    }
  }

  // 離線時本地寫入（立即回傳成功）
  static Future<void> saveLogOffline(CareLogLocal log) async {
    final box = Hive.box<CareLogLocal>('careLogs');
    log.syncStatus = 'pending';
    await box.put(log.logId, log);

    // 嘗試立即同步
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      await _syncPendingLogs();
    }
  }

  // 未同步筆數（顯示在 UI 的小徽章）
  static int get pendingCount {
    final box = Hive.box<CareLogLocal>('careLogs');
    return box.values.where((l) => l.syncStatus == 'pending').length;
  }
}
```

---

## 五、政府 Open Data API 介接實作

### 5.1 衛福部長照特約機構解析

```dart
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:geocoding/geocoding.dart';

class LtcDataService {
  // 衛福部開放資料（免費，無需申請）
  static const _ltcCsvUrl =
      'https://data.mohw.gov.tw/Datasets/Download?Type=0&Index=1';

  static Future<List<LtcInstitution>> fetchMiaoliInstitutions() async {
    // 1. 讀取 Hive 快取（24小時內不重新抓取）
    final box = Hive.box('ltcCache');
    final cachedAt = box.get('ltcCachedAt') as DateTime?;
    if (cachedAt != null &&
        DateTime.now().difference(cachedAt).inHours < 24) {
      final cached = box.get('ltcData') as List?;
      if (cached != null) return cached.cast<LtcInstitution>();
    }

    // 2. 下載政府 CSV
    final response = await http.get(Uri.parse(_ltcCsvUrl))
        .timeout(const Duration(seconds: 30));

    final csvStr = const Utf8Decoder().convert(response.bodyBytes);
    final rows = const CsvToListConverter(eol: '\n').convert(csvStr);

    // 3. 篩選苗栗縣機構
    final institutions = <LtcInstitution>[];
    for (final row in rows.skip(1)) {  // 跳過標題行
      if (row[2].toString().startsWith('苗栗')) {
        final inst = LtcInstitution(
          id: row[0].toString(),
          name: row[1].toString(),
          county: row[2].toString(),
          township: row[3].toString(),
          address: '${row[2]}${row[3]}${row[4]}',
          phone: row[5].toString(),
          level: _parseLevel(row[6].toString()),
          services: _parseServices(row[7].toString()),
        );
        institutions.add(inst);
      }
    }

    // 4. Geocoding：地址 → 座標（批次，限速處理）
    await _geocodeInstitutions(institutions);

    // 5. 存入 Hive 快取
    box.put('ltcData', institutions);
    box.put('ltcCachedAt', DateTime.now());

    return institutions;
  }

  // 使用內政部 TGOS API（免費，每日 5000 次）
  static Future<void> _geocodeInstitutions(
      List<LtcInstitution> institutions) async {
    for (final inst in institutions) {
      if (inst.lat != null) continue;  // 已有座標則跳過
      try {
        final locations = await locationFromAddress(inst.address);
        if (locations.isNotEmpty) {
          inst.lat = locations.first.latitude;
          inst.lng = locations.first.longitude;
        }
        // 限速：避免超過 API 配額
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (_) {}
    }
  }

  static LtcLevel _parseLevel(String raw) {
    if (raw.contains('A')) return LtcLevel.a;
    if (raw.contains('B')) return LtcLevel.b;
    return LtcLevel.c;
  }

  static List<String> _parseServices(String raw) {
    return raw.split('、').map((s) => s.trim()).toList();
  }
}
```

---

## 六、8 週 MVP 開發衝刺計畫

### Week 1：專案基礎建設

```
□ Flutter 專案建立（flutter create antsicare）
□ Firebase 專案設定（開發、正式兩個環境）
□ easy_localization 整合（zh-TW / id 兩語言先上）
□ Firebase Auth 手機 OTP 登入
□ Hive 初始化（careLog、medicationLog 兩個 Box）
□ 時區設定（timezone package，Asia/Taipei）
□ 基本路由設定（go_router）
□ 環境變數管理（flutter_dotenv）
```

### Week 2：使用者系統 + 語言偵測

```
□ 使用者角色選擇頁（長者 / 家屬 / 看護 / 照管專員）
□ 裝置語言自動偵測（印尼系統 → 自動切換 id）
□ 語言手動切換（設定頁）
□ Firestore User Profile 建立
□ 角色對應的首頁導覽架構（BottomNavigationBar）
□ 長者大字體模式（Provider 狀態）
```

### Week 3：照護日誌核心（最重要功能）

```
□ 圖示化勾選介面（12 個照護項目）
□ 正常 / 異常切換（綠色 / 紅色回饋）
□ 數值輸入（血壓、血糖、體溫 - 數字鍵盤）
□ 語音備註（speech_to_text，印尼語 id-ID）
□ 離線寫入 Hive（SyncService）
□ 台北時間顯示（Asia/Taipei）
□ 日誌送出 → Firestore 同步
```

### Week 4：自動翻譯 + 家屬閱讀

```
□ Claude API 整合（印尼語備註 → 中文翻譯）
□ 翻譯結果回寫 Firestore
□ 家屬端日誌查閱頁（中文版）
□ 日誌時間軸視圖（照護紀錄時間軸）
□ 異常標記高亮顯示
□ FCM 推播：日誌更新通知家屬
```

### Week 5：SOS 緊急通報

```
□ SOS 大按鈕（GestureDetector + 3 秒長按）
□ GPS 位置取得（geolocator）
□ 緊急聯絡人資料庫
□ FCM 推播家屬（含位置）
□ 119 / 1966 / 1955 一鍵撥打（url_launcher）
□ 印尼語語音指引（audioplayers：Hubungi 119!）
```

### Week 6：苗栗長照資源地圖

```
□ 政府 CSV 解析（LtcDataService）
□ Geocoding 地址轉座標
□ Google Maps 整合（google_maps_flutter）
□ A/B/C 級機構分層圖示
□ 篩選功能（鄉鎮市 / 服務類型）
□ 機構卡片（含距離、候補、電話）
□ 1966 / 機構電話一鍵撥打
```

### Week 7：用藥提醒 + 健康記錄

```
□ 藥品新增（中文 + 印尼語名、照片）
□ 台北時間排程提醒（flutter_local_notifications）
□ 服藥確認打卡 → Hive + Firestore
□ 健康數值趨勢圖（fl_chart）
□ 異常值預警（家屬 FCM 通知）
□ 禱告時間提醒（印尼籍看護選用）
```

### Week 8：測試 + 上架準備

```
□ 整合測試（Patrol 框架）
□ 效能優化（冷啟動 < 2 秒）
□ 離線模式壓力測試（飛航模式 + 大量資料）
□ iOS TestFlight 上架（App Store Connect）
□ Android Google Play Beta 上架
□ 印尼語 UI 全面檢查（母語人士校對）
□ 隱私政策（中文 + 印尼語版本）
□ App Store / Play Store 截圖（中文 + 印尼語）
```

---

## 七、關鍵套件清單

```yaml
# pubspec.yaml 完整依賴

dependencies:
  # Firebase 核心
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  firebase_storage: ^12.3.2
  firebase_messaging: ^15.1.3
  
  # 離線快取
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # 多語言
  easy_localization: ^3.0.7
  
  # 時區（台北時間）
  timezone: ^0.9.4
  
  # 地圖與定位
  google_maps_flutter: ^2.9.0
  geolocator: ^13.0.1
  geocoding: ^3.0.0
  
  # 語音輸入
  speech_to_text: ^7.0.0
  audioplayers: ^6.1.0
  
  # 通知
  flutter_local_notifications: ^18.0.0
  
  # 網路與資料
  http: ^1.2.2
  csv: ^6.0.0
  connectivity_plus: ^6.1.0
  
  # UI 工具
  fl_chart: ^0.69.0
  url_launcher: ^6.3.0
  image_picker: ^1.1.2
  cached_network_image: ^3.4.1
  
  # 路由
  go_router: ^14.3.0
  
  # 狀態管理
  provider: ^6.1.2
  
  # 工具
  uuid: ^4.5.1
  flutter_dotenv: ^5.2.1
  intl: ^0.19.0

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.12
  flutter_test:
    sdk: flutter
```
