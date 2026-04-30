import 'package:health/health.dart';

import '../models/heart_rate_model.dart';

// Apple Watch 心率服務
//
// 資料流：Apple Watch → HealthKit → health 套件 → Flutter
// iOS 需在 Xcode 啟用 HealthKit capability 並在 Info.plist 加入：
//   NSHealthShareUsageDescription
//   NSHealthUpdateUsageDescription
//
// Android：使用 Google Health Connect（health 套件自動切換）
//   需在 AndroidManifest.xml 加入 BODY_SENSORS 權限

class HeartRateService {
  static final Health _health = Health();
  static const List<HealthDataType> _types = [HealthDataType.HEART_RATE];
  static const List<HealthDataAccess> _perms = [HealthDataAccess.READ];

  // ── 權限 ──────────────────────────────────────────────────────────────────

  static Future<bool> requestPermissions() async {
    try {
      return await _health.requestAuthorization(_types, permissions: _perms);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> get hasPermission async {
    try {
      return await _health.hasPermissions(_types, permissions: _perms) ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── 資料讀取 ──────────────────────────────────────────────────────────────

  /// 取得過去 24 小時的心率記錄（最新在前）
  static Future<List<HeartRateReading>> fetchLast24Hours() async {
    return _fetch(const Duration(hours: 24));
  }

  /// 取得最新一筆心率（Apple Watch 最後同步）
  static Future<HeartRateReading?> fetchLatest() async {
    final readings = await fetchLast24Hours();
    return readings.isEmpty ? null : readings.first;
  }

  /// 取得過去 N 天記錄（用於趨勢圖）
  static Future<List<HeartRateReading>> fetchLastDays(int days) async {
    return _fetch(Duration(days: days));
  }

  // ── 私有：統一讀取邏輯 ────────────────────────────────────────────────────

  static Future<List<HeartRateReading>> _fetch(Duration window) async {
    final now = DateTime.now();
    final start = now.subtract(window);
    try {
      final raw = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: _types,
      );
      final unique = Health.removeDuplicates(raw);
      final readings = unique.map(_toReading).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return readings;
    } catch (_) {
      return [];
    }
  }

  static HeartRateReading _toReading(HealthDataPoint point) {
    final bpm = (point.value as NumericHealthValue).numericValue.toDouble();
    // sourceName 通常含 "Apple Watch" / "iPhone" / "Health"
    final src = point.sourceName.isNotEmpty ? point.sourceName : 'Apple Watch';
    return HeartRateReading(timestamp: point.dateFrom, bpm: bpm, source: src);
  }

  // ── 24h 統計摘要 ──────────────────────────────────────────────────────────

  static Future<HeartRateSummary> fetchSummary24h() async {
    final readings = await fetchLast24Hours();
    return HeartRateSummary.fromReadings(readings);
  }

  // ── Firestore 同步（將異常心率寫入照護日誌）─────────────────────────────────
  //
  // 呼叫時機：背景工作（WorkManager / BGTask）偵測到異常心率時
  // 由 NotificationService 發送照護異常推播通知

  static bool shouldAlert(HeartRateReading reading) => reading.isAbnormal;
}
