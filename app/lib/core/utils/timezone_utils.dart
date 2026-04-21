import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:intl/intl.dart';

class TimezoneUtils {
  static const String _taipeiTz = 'Asia/Taipei';
  static bool _initialized = false;

  /// 初始化時區資料（在 main() 呼叫一次）
  static void init() {
    if (!_initialized) {
      tz_data.initializeTimeZones();
      _initialized = true;
    }
  }

  /// 取得台北時區 Location
  static tz.Location get taipei => tz.getLocation(_taipeiTz);

  /// UTC DateTime → 台北時間 TZDateTime
  static tz.TZDateTime toTaipei(DateTime utc) {
    if (!_initialized) init();
    final utcTime = utc.isUtc ? utc : utc.toUtc();
    return tz.TZDateTime.from(utcTime, taipei);
  }

  /// 取得現在台北時間
  static tz.TZDateTime nowTaipei() {
    if (!_initialized) init();
    return tz.TZDateTime.now(taipei);
  }

  /// 台北時間 → UTC
  static DateTime toUtc(tz.TZDateTime taipeiTime) {
    return taipeiTime.toUtc();
  }

  /// 格式化為 yyyy/MM/dd HH:mm（台北時間）
  static String formatDateTime(DateTime utc) {
    final local = toTaipei(utc);
    return DateFormat('yyyy/MM/dd HH:mm').format(local);
  }

  /// 格式化為 yyyy/MM/dd（台北日期）
  static String formatDate(DateTime utc) {
    final local = toTaipei(utc);
    return DateFormat('yyyy/MM/dd').format(local);
  }

  /// 格式化為 HH:mm（台北時間）
  static String formatTime(DateTime utc) {
    final local = toTaipei(utc);
    return DateFormat('HH:mm').format(local);
  }

  /// 取得今日台北日期字串 'YYYY-MM-DD'
  static String todayString() {
    final now = nowTaipei();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  /// 相對時間標籤（幾分鐘前 / 幾小時前）
  static String relativeTime(DateTime utc) {
    final now = DateTime.now().toUtc();
    final diff = now.difference(utc.isUtc ? utc : utc.toUtc());

    if (diff.inSeconds < 60) return '剛剛';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分鐘前';
    if (diff.inHours < 24) return '${diff.inHours} 小時前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return formatDate(utc);
  }
}
