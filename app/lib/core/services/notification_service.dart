import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Firebase Cloud Messaging 多語言推播服務
/// 依使用者語言設定推送對應語言通知
class NotificationService {
  static final _fcm = FirebaseMessaging.instance;

  /// 初始化（在 main() 呼叫）
  static Future<void> init() async {
    // 請求通知權限（iOS / Android 13+）
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
      announcement: false, criticalAlert: true,
    );

    // 取得 FCM Token 並儲存至 Firestore
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveToken(token);
    }

    // Token 更新時重新儲存
    _fcm.onTokenRefresh.listen(_saveToken);

    // 前景訊息處理
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 背景 / 終止狀態訊息點擊
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 設定背景訊息 handler（必須是頂層函式）
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _saveToken(String token) async {
    final uid = await _getCurrentUid();
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(uid)
        .update({'fcmToken': token, 'fcmUpdatedAt': FieldValue.serverTimestamp()});
  }

  static Future<String?> _getCurrentUid() async {
    // 避免 firebase_auth 循環依賴：讀取 SharedPreferences 中快取的 UID
    return null; // 由 auth listener 在登入後呼叫 _saveToken
  }

  /// 根據使用者語言取得多語言通知 payload
  static Map<String, String> buildPayload({
    required String type,
    required String language,
    Map<String, String>? namedArgs,
  }) {
    final templates = _notificationTemplates[type] ?? {};
    final template = templates[language] ?? templates['zh-TW'] ?? {};

    String _fill(String? tpl) {
      if (tpl == null) return '';
      if (namedArgs == null) return tpl;
      var result = tpl;
      namedArgs.forEach((k, v) { result = result.replaceAll('{{$k}}', v); });
      return result;
    }

    return {
      'title': _fill(template['title']),
      'body': _fill(template['body']),
    };
  }

  static void _handleForegroundMessage(RemoteMessage msg) {
    // TODO: 在 App 內顯示自訂通知 banner（使用 overlay 或 flutter_local_notifications）
    debugPrint('[FCM] 前景訊息: ${msg.notification?.title}');
  }

  static void _handleNotificationTap(RemoteMessage msg) {
    final type = msg.data['type'];
    // TODO: 依 type 導航至對應頁面（如 /care-log、/sos）
    debugPrint('[FCM] 通知點擊: type=$type');
  }

  // ── 通知模板（多語言）────────────────────────────────────────────────────

  static const _notificationTemplates = <String, Map<String, Map<String, String>>>{
    'medication_reminder': {
      'zh-TW': {'title': '用藥提醒 💊', 'body': '{{name}} 現在是服用{{medicine}}的時間（{{time}}）'},
      'id':    {'title': 'Pengingat Obat 💊', 'body': '{{name}} – Saatnya minum {{medicine}} ({{time}})'},
      'vi':    {'title': 'Nhắc uống thuốc 💊', 'body': '{{name}} – Uống {{medicine}} lúc {{time}}'},
      'th':    {'title': 'แจ้งเตือนยา 💊', 'body': 'ถึงเวลารับประทาน {{medicine}} แล้ว ({{time}})'},
      'en':    {'title': 'Medication Reminder 💊', 'body': 'Time to take {{medicine}} for {{name}} at {{time}}'},
    },
    'care_log_abnormal': {
      'zh-TW': {'title': '照護異常警示 ⚠️', 'body': '{{elder}} 今日照護紀錄有異常，請查閱'},
      'id':    {'title': 'Peringatan Kondisi Tidak Normal ⚠️', 'body': '{{elder}} – Ada kondisi tidak normal. Harap periksa catatan perawatan.'},
      'vi':    {'title': 'Cảnh báo bất thường ⚠️', 'body': '{{elder}} có tình trạng bất thường hôm nay'},
      'en':    {'title': 'Care Alert ⚠️', 'body': '{{elder}} has an abnormal condition. Please check the care log.'},
    },
    'sos_triggered': {
      'zh-TW': {'title': '🆘 緊急求助', 'body': '{{name}} 已觸發緊急通報，位置已傳送'},
      'id':    {'title': '🆘 Panggilan Darurat', 'body': '{{name}} mengaktifkan SOS. Lokasi telah dikirim.'},
      'vi':    {'title': '🆘 Khẩn cấp', 'body': '{{name}} đã kích hoạt SOS. Vị trí đã gửi.'},
      'en':    {'title': '🆘 Emergency Alert', 'body': '{{name}} triggered SOS. Location shared.'},
    },
    'prayer_time': {
      'id': {'title': '🕌 Waktu Salat', 'body': 'Sudah masuk waktu {{prayer}}. Jangan lupa beribadah.'},
    },
    'care_log_translated': {
      'zh-TW': {'title': '照護日誌已翻譯 📋', 'body': '{{caregiver}} 的今日照護備註已完成中文翻譯，請查閱'},
    },
  };
}

/// 必須是頂層函式（非 class method）
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 背景/終止狀態收到推播時的處理
  debugPrint('[FCM Background] ${message.notification?.title}');
}
