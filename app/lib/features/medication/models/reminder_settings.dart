// 用藥提醒設定模型
//
// 儲存於 Hive（本機），key = 'medication_reminder_settings'
// 每個藥品可個別開關；全域設定影響所有藥品

class ReminderSettings {
  /// 全域提醒總開關
  final bool enabled;

  /// 提前幾分鐘提醒（0 = 準時，5 / 10 / 15 分鐘前）
  final int advanceMinutes;

  /// 貪睡間隔（分鐘）：5 / 10 / 15 / 30
  final int snoozeMinutes;

  /// 通知聲音
  final bool soundEnabled;

  /// 震動
  final bool vibrationEnabled;

  /// 個別藥品開關：key = medicineId，value = 是否啟用提醒
  /// 未設定的 key 預設視為 true（啟用）
  final Map<String, bool> medicationEnabled;

  const ReminderSettings({
    this.enabled = true,
    this.advanceMinutes = 0,
    this.snoozeMinutes = 10,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.medicationEnabled = const {},
  });

  // ── 查詢 ──────────────────────────────────────────────────────────────────

  bool isMedicationEnabled(String medId) =>
      enabled && (medicationEnabled[medId] ?? true);

  static const advanceOptions = [0, 5, 10, 15];
  static const snoozeOptions  = [5, 10, 15, 30];

  String get advanceLabel {
    if (advanceMinutes == 0) return '準時提醒';
    return '提前 $advanceMinutes 分鐘';
  }

  String get advanceLabelId {
    if (advanceMinutes == 0) return 'Tepat waktu';
    return '$advanceMinutes menit sebelumnya';
  }

  String get snoozeLabel   => '貪睡 $snoozeMinutes 分鐘';
  String get snoozeLabelId => 'Tunda $snoozeMinutes menit';

  // ── 不可變更新 ────────────────────────────────────────────────────────────

  ReminderSettings copyWith({
    bool? enabled,
    int? advanceMinutes,
    int? snoozeMinutes,
    bool? soundEnabled,
    bool? vibrationEnabled,
    Map<String, bool>? medicationEnabled,
  }) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        advanceMinutes: advanceMinutes ?? this.advanceMinutes,
        snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
        medicationEnabled: medicationEnabled ?? this.medicationEnabled,
      );

  ReminderSettings withMedicationToggle(String medId, bool value) =>
      copyWith(
        medicationEnabled: Map.from(medicationEnabled)..[medId] = value,
      );

  // ── 序列化 ────────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'advanceMinutes': advanceMinutes,
    'snoozeMinutes': snoozeMinutes,
    'soundEnabled': soundEnabled,
    'vibrationEnabled': vibrationEnabled,
    'medicationEnabled': medicationEnabled,
  };

  factory ReminderSettings.fromMap(Map<String, dynamic> map) =>
      ReminderSettings(
        enabled: map['enabled'] as bool? ?? true,
        advanceMinutes: map['advanceMinutes'] as int? ?? 0,
        snoozeMinutes: map['snoozeMinutes'] as int? ?? 10,
        soundEnabled: map['soundEnabled'] as bool? ?? true,
        vibrationEnabled: map['vibrationEnabled'] as bool? ?? true,
        medicationEnabled: (map['medicationEnabled'] as Map?)
                ?.map((k, v) => MapEntry(k as String, v as bool)) ??
            {},
      );

  static const defaultSettings = ReminderSettings();

  @override
  String toString() =>
      'ReminderSettings(enabled:$enabled, advance:${advanceMinutes}m, snooze:${snoozeMinutes}m)';
}
