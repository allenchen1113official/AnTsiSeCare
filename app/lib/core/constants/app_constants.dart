class AppConstants {
  // --- App Info ---
  static const String appName = 'AnTsiSeCare';
  static const String appNameZh = '安心照護';
  static const String appVersion = '1.0.0';

  // --- Supported Languages ---
  static const List<String> supportedLocales = ['zh-TW', 'id', 'vi', 'th', 'en'];
  static const String defaultLocale = 'zh-TW';
  static const String indonesianLocale = 'id';

  // --- Hotlines ---
  static const String ltcHotline = '1966';         // 長照服務 A
  static const String migrantHotline = '1955';     // 移工諮詢（印尼語服務）
  static const String emergencyHotline = '119';    // 緊急救護
  static const String policeHotline = '110';       // 警察

  // --- Miaoli Townships ---
  static const List<String> miaoliTownships = [
    '苗栗市', '頭份市', '竹南鎮', '苑裡鎮', '通霄鎮', '後龍鎮',
    '銅鑼鄉', '三義鄉', '西湖鄉', '造橋鄉', '頭屋鄉', '公館鄉',
    '大湖鄉', '泰安鄉', '南庄鄉', '獅潭鄉', '三灣鄉', '卓蘭鎮',
  ];

  // --- User Roles ---
  static const String roleElder = 'elder';
  static const String roleFamily = 'family';
  static const String roleCaregiver = 'caregiver';
  static const String roleCareManager = 'care_manager';

  // --- Caregiver Nationalities ---
  static const Map<String, String> nationalityLabels = {
    'ID': '印尼 / Indonesia',
    'VN': '越南 / Việt Nam',
    'TH': '泰國 / Thailand',
    'PH': '菲律賓 / Philippines',
    'TW': '台灣',
  };

  // --- Care Item Keys (icon-based, language agnostic) ---
  static const String careFeeding = 'feeding';
  static const String careMedication = 'medication';
  static const String careExcretion = 'excretion';
  static const String careBathing = 'bathing';
  static const String careExercise = 'exercise';
  static const String careSleep = 'sleep';
  static const String careMood = 'mood';
  static const String careWound = 'wound';
  static const String careCommunication = 'communication';
  static const String careMobility = 'mobility';
  static const String careHousekeeping = 'housekeeping';
  static const String careCognition = 'cognition';

  // --- Hive Box Names ---
  static const String hiveBoxCareLog = 'care_logs_pending';
  static const String hiveBoxUser = 'user_cache';
  static const String hiveBoxSettings = 'app_settings';
  static const String hiveBoxLtcData = 'ltc_resources';
  static const String hiveBoxMedication = 'medications';

  // --- Firestore Collections ---
  static const String colUsers = 'users';
  static const String colCareLogs = 'careLogs';
  static const String colMedicines = 'medicines';
  static const String colMedicationLogs = 'medicationLogs';
  static const String colEmergencyAlerts = 'emergencyAlerts';
  static const String colLtcResources = 'ltcResources';

  // --- Claude API ---
  static const String claudeModel = 'claude-sonnet-4-6';
  static const int claudeMaxTokens = 1024;

  // --- Government Open Data ---
  static const String ltcCsvUrl =
      'https://data.mohw.gov.tw/Datasets/Download?Type=0&Index=1';

  // --- Cache TTL ---
  static const Duration ltcCacheTtl = Duration(hours: 24);
  static const Duration userCacheTtl = Duration(hours: 1);

  // --- UI ---
  static const double minTouchTarget = 48.0;
  static const double elderTouchTarget = 64.0;
  static const double borderRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double pageHorizontalPadding = 20.0;

  // --- SOS Pulse Animation ---
  static const Duration sosPulseDuration = Duration(milliseconds: 1500);
}
