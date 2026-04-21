import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// 不直接 import TimezoneUtils（需 Firebase 初始化）；直接測試時區邏輯
void main() {
  setUpAll(() => tz_data.initializeTimeZones());

  group('Timezone — Asia/Taipei (UTC+8)', () {
    test('UTC+0 00:00 → 台北 08:00', () {
      final utc = DateTime.utc(2026, 4, 14, 0, 0, 0);
      final taipei = tz.getLocation('Asia/Taipei');
      final local = tz.TZDateTime.from(utc, taipei);
      expect(local.hour, 8);
      expect(local.day, 14);
    });

    test('UTC+0 16:00 → 台北 00:00 隔天', () {
      final utc = DateTime.utc(2026, 4, 14, 16, 0, 0);
      final taipei = tz.getLocation('Asia/Taipei');
      final local = tz.TZDateTime.from(utc, taipei);
      expect(local.hour, 0);
      expect(local.day, 15);
    });

    test('夏令時間：台灣全年固定 UTC+8（無 DST）', () {
      // 台灣不實施夏令時間，1 月與 7 月偏移量相同
      final taipei = tz.getLocation('Asia/Taipei');
      final jan = tz.TZDateTime(taipei, 2026, 1, 1);
      final jul = tz.TZDateTime(taipei, 2026, 7, 1);
      expect(jan.timeZoneOffset.inHours, 8);
      expect(jul.timeZoneOffset.inHours, 8);
    });

    test('台北日期字串格式 YYYY-MM-DD', () {
      final utc = DateTime.utc(2026, 4, 14, 15, 59, 0); // 台北 23:59
      final taipei = tz.getLocation('Asia/Taipei');
      final local = tz.TZDateTime.from(utc, taipei);
      final dateStr = '${local.year}-'
          '${local.month.toString().padLeft(2, '0')}-'
          '${local.day.toString().padLeft(2, '0')}';
      expect(dateStr, '2026-04-14');
    });

    test('UTC+0 16:01 → 台北日期進到隔天', () {
      final utc = DateTime.utc(2026, 4, 14, 16, 1, 0); // 台北 00:01 4/15
      final taipei = tz.getLocation('Asia/Taipei');
      final local = tz.TZDateTime.from(utc, taipei);
      final dateStr = '${local.year}-'
          '${local.month.toString().padLeft(2, '0')}-'
          '${local.day.toString().padLeft(2, '0')}';
      expect(dateStr, '2026-04-15');
    });
  });
}
