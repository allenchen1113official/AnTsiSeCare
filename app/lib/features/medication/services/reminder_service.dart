import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/timezone_utils.dart';
import '../models/medication_model.dart';
import '../models/reminder_settings.dart';

// 用藥提醒服務
//
// 功能：
//  1. 使用 flutter_local_notifications 排程本機通知
//  2. 每日定時（matchDateTimeComponents.time）自動重複
//  3. 通知動作：✓ 已服用 → 寫入 Firestore；⏰ 稍後提醒 → 貪睡 N 分鐘
//  4. 設定值儲存於 Hive，App 重啟後自動重排

class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _hiveBox  = 'app_settings';
  static const _hiveKey  = 'medication_reminder_settings';
  static const _taipeiTz = 'Asia/Taipei';

  // ── 初始化 ────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_taipeiTz));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // 稍後透過 requestPermissions() 請求
      requestBadgePermission: true,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onAction,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundAction,
    );

    // Android：建立通知頻道
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      'medication_reminder',
      '用藥提醒',
      description: '定時提醒照服員或長者服藥',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    ));
  }

  // ── 權限 ──────────────────────────────────────────────────────────────────

  static Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    final androidOk = await android?.requestNotificationsPermission() ?? true;
    final iosOk = await ios?.requestPermissions(
      alert: true, badge: true, sound: true,
    ) ?? true;

    return androidOk && iosOk;
  }

  // ── 設定讀寫（Hive）────────────────────────────────────────────────────────

  static Future<ReminderSettings> loadSettings() async {
    final box = await Hive.openBox(_hiveBox);
    final raw = box.get(_hiveKey);
    if (raw == null) return const ReminderSettings();
    try {
      return ReminderSettings.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw as String)));
    } catch (_) {
      return const ReminderSettings();
    }
  }

  static Future<void> saveSettings(ReminderSettings settings) async {
    final box = await Hive.openBox(_hiveBox);
    await box.put(_hiveKey, jsonEncode(settings.toMap()));
  }

  // ── 排程 ──────────────────────────────────────────────────────────────────

  /// 為單一藥品排程所有提醒
  static Future<void> scheduleForMedication(
    MedicationModel med,
    ReminderSettings settings,
  ) async {
    if (!settings.isMedicationEnabled(med.id ?? '')) return;

    for (final timeStr in med.reminderTimes) {
      final parts = timeStr.split(':');
      if (parts.length < 2) continue;

      var h = int.tryParse(parts[0]) ?? 0;
      var m = int.tryParse(parts[1]) ?? 0;

      // 計算提前時間
      m -= settings.advanceMinutes;
      if (m < 0) { m += 60; h -= 1; }
      if (h < 0) h += 24;

      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _notifId(med.id ?? '', timeStr),
        _buildTitle(med),
        _buildBody(med, timeStr, settings.advanceMinutes),
        scheduled,
        _details(med, settings),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // 每日重複
        payload: _payload(med.id ?? '', timeStr),
      );
    }
  }

  /// 取消單一藥品所有提醒
  static Future<void> cancelForMedication(
      String medId, List<String> times) async {
    for (final t in times) {
      await _plugin.cancel(_notifId(medId, t));
    }
  }

  /// 取消全部提醒
  static Future<void> cancelAll() async => _plugin.cancelAll();

  /// App 啟動時重排所有藥品提醒
  static Future<void> rescheduleAll(
    List<MedicationModel> meds,
    ReminderSettings settings,
  ) async {
    await cancelAll();
    if (!settings.enabled) return;
    for (final med in meds) {
      if (med.isActive) await scheduleForMedication(med, settings);
    }
  }

  // ── 貪睡 ──────────────────────────────────────────────────────────────────

  static Future<void> snooze({
    required int originalId,
    required String payload,
    required int minutes,
  }) async {
    final when = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
    await _plugin.zonedSchedule(
      originalId + 90000, // 貪睡 ID 不與每日排程衝突
      '💊 用藥提醒（再次提醒）',
      '請記得服藥，貪睡 $minutes 分鐘已到',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminder', '用藥提醒',
          importance: Importance.high, priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ── 通知動作處理 ──────────────────────────────────────────────────────────

  static void _onAction(NotificationResponse r) async {
    final payload = r.payload ?? '';
    if (r.actionId == 'taken') {
      await _markTaken(payload);
    } else if (r.actionId == 'snooze') {
      final settings = await loadSettings();
      await snooze(
        originalId: r.id ?? 0,
        payload: payload,
        minutes: settings.snoozeMinutes,
      );
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundAction(NotificationResponse r) =>
      _onAction(r);

  // ── 從通知直接記錄服藥 ────────────────────────────────────────────────────

  static Future<void> _markTaken(String payload) async {
    // payload = 'medId|HH:mm'
    final parts = payload.split('|');
    if (parts.length < 2) return;
    final medId = parts[0];
    final time  = parts[1];
    final today = TimezoneUtils.todayString();
    final logId = '${medId}_${today}_${time.replaceAll(':', '')}';

    await FirebaseFirestore.instance
        .collection(AppConstants.colMedicationLogs)
        .doc(logId)
        .set({
      'medicineId': medId,
      'takenBy': 'notification_action',
      'taken': true,
      'takenAt': Timestamp.now(),
      'logDate': today,
      'note': '由通知快速標記',
      'timezone': 'Asia/Taipei',
    }, SetOptions(merge: true));
  }

  // ── 私有 helpers ──────────────────────────────────────────────────────────

  static int _notifId(String medId, String time) =>
      '${medId}_$time'.hashCode.abs() % 80000;

  static String _payload(String medId, String time) => '$medId|$time';

  static String _buildTitle(MedicationModel med) => '💊 用藥提醒';

  static String _buildBody(
      MedicationModel med, String time, int advanceMin) {
    final when = advanceMin == 0 ? '服藥時間：$time' : '還有 $advanceMin 分鐘到服藥時間（$time）';
    return '${med.name} ${med.dosage}　$when';
  }

  static NotificationDetails _details(
      MedicationModel med, ReminderSettings s) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_reminder',
        '用藥提醒',
        channelDescription: '定時提醒照服員或長者服藥',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: s.vibrationEnabled,
        playSound: s.soundEnabled,
        styleInformation: BigTextStyleInformation(
          '${med.name} ${med.dosage}\n${med.instructions ?? ''}',
        ),
        actions: const [
          AndroidNotificationAction(
            'taken', '✓ 已服用',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'snooze', '⏰ 稍後提醒',
            showsUserInterface: false,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: 'MEDICATION',
        interruptionLevel: InterruptionLevel.timeSensitive,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
