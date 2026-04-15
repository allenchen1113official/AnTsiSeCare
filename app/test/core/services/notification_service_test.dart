import 'package:flutter_test/flutter_test.dart';

// 複製通知模板邏輯進行隔離測試

const _templates = <String, Map<String, Map<String, String>>>{
  'medication_reminder': {
    'zh-TW': {'title': '用藥提醒 💊', 'body': '{{name}} 現在是服用{{medicine}}的時間（{{time}}）'},
    'id':    {'title': 'Pengingat Obat 💊', 'body': '{{name}} – Saatnya minum {{medicine}} ({{time}})'},
    'vi':    {'title': 'Nhắc uống thuốc 💊', 'body': '{{name}} – Uống {{medicine}} lúc {{time}}'},
    'en':    {'title': 'Medication Reminder 💊', 'body': 'Time to take {{medicine}} for {{name}} at {{time}}'},
  },
  'care_log_abnormal': {
    'zh-TW': {'title': '照護異常警示 ⚠️', 'body': '{{elder}} 今日照護紀錄有異常，請查閱'},
    'id':    {'title': 'Peringatan Kondisi Tidak Normal ⚠️', 'body': '{{elder}} – Ada kondisi tidak normal.'},
    'en':    {'title': 'Care Alert ⚠️', 'body': '{{elder}} has an abnormal condition.'},
  },
  'prayer_time': {
    'id': {'title': '🕌 Waktu Salat', 'body': 'Sudah masuk waktu {{prayer}}.'},
  },
};

Map<String, String> buildPayload({
  required String type,
  required String language,
  Map<String, String>? namedArgs,
}) {
  final templates = _templates[type] ?? {};
  final template = templates[language] ?? templates['zh-TW'] ?? {};

  String fill(String? tpl) {
    if (tpl == null) return '';
    if (namedArgs == null) return tpl;
    var result = tpl;
    namedArgs.forEach((k, v) { result = result.replaceAll('{{$k}}', v); });
    return result;
  }

  return {
    'title': fill(template['title']),
    'body': fill(template['body']),
  };
}

void main() {
  group('buildPayload — 用藥提醒', () {
    test('中文模板包含藥品名稱', () {
      final p = buildPayload(
        type: 'medication_reminder',
        language: 'zh-TW',
        namedArgs: {'name': '陳阿嬤', 'medicine': '血壓藥', 'time': '08:00'},
      );
      expect(p['title'], contains('用藥提醒'));
      expect(p['body'], contains('陳阿嬤'));
      expect(p['body'], contains('血壓藥'));
      expect(p['body'], contains('08:00'));
    });

    test('印尼語模板（id）', () {
      final p = buildPayload(
        type: 'medication_reminder',
        language: 'id',
        namedArgs: {'name': 'Nenek', 'medicine': 'amlodipine', 'time': '08:00'},
      );
      expect(p['title'], contains('Pengingat Obat'));
      expect(p['body'], contains('Nenek'));
      expect(p['body'], contains('amlodipine'));
    });

    test('英語模板（en）', () {
      final p = buildPayload(
        type: 'medication_reminder',
        language: 'en',
        namedArgs: {'name': 'Grandma', 'medicine': 'Amlodipine', 'time': '8 AM'},
      );
      expect(p['title'], contains('Medication Reminder'));
      expect(p['body'], contains('Grandma'));
    });

    test('未知語言 fallback 到 zh-TW', () {
      final p = buildPayload(
        type: 'medication_reminder',
        language: 'fr',  // 法語未定義
        namedArgs: {'name': 'Test', 'medicine': 'X', 'time': '09:00'},
      );
      expect(p['title'], contains('用藥提醒'));
    });
  });

  group('buildPayload — 照護異常', () {
    test('中文異常通知含長者名稱', () {
      final p = buildPayload(
        type: 'care_log_abnormal',
        language: 'zh-TW',
        namedArgs: {'elder': '王阿公'},
      );
      expect(p['body'], contains('王阿公'));
      expect(p['body'], contains('異常'));
    });

    test('印尼語異常通知', () {
      final p = buildPayload(
        type: 'care_log_abnormal',
        language: 'id',
        namedArgs: {'elder': 'Kakek'},
      );
      expect(p['title'], contains('Peringatan'));
      expect(p['body'], contains('Kakek'));
    });
  });

  group('buildPayload — 禱告提醒', () {
    test('只有印尼語版', () {
      final p = buildPayload(
        type: 'prayer_time',
        language: 'id',
        namedArgs: {'prayer': 'Zuhur'},
      );
      expect(p['title'], '🕌 Waktu Salat');
      expect(p['body'], contains('Zuhur'));
    });

    test('中文使用者不應收到禱告通知（無模板）', () {
      final p = buildPayload(
        type: 'prayer_time',
        language: 'zh-TW',
      );
      // zh-TW 沒有 prayer_time 模板，且沒有 fallback（空字串）
      expect(p['title'], '');
      expect(p['body'], '');
    });
  });

  group('buildPayload — namedArgs 替換', () {
    test('多個 placeholder 全部替換', () {
      final p = buildPayload(
        type: 'medication_reminder',
        language: 'zh-TW',
        namedArgs: {'name': 'N1', 'medicine': 'M1', 'time': 'T1'},
      );
      expect(p['body'], isNot(contains('{{name}}')));
      expect(p['body'], isNot(contains('{{medicine}}')));
      expect(p['body'], isNot(contains('{{time}}')));
    });

    test('namedArgs 為 null 時不崩潰', () {
      final p = buildPayload(
        type: 'care_log_abnormal',
        language: 'zh-TW',
      );
      expect(p['title'], isNotEmpty);
    });
  });
}
