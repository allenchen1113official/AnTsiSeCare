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

  // --- Taiwan Counties / Cities ---
  static const List<String> taiwanCounties = [
    '台北市', '新北市', '桃園市', '台中市', '台南市', '高雄市',
    '基隆市', '新竹市', '嘉義市',
    '新竹縣', '苗栗縣', '彰化縣', '南投縣', '雲林縣', '嘉義縣',
    '屏東縣', '宜蘭縣', '花蓮縣', '台東縣', '澎湖縣', '金門縣', '連江縣',
  ];

  // --- County → major townships (for UI filter chips) ---
  static const Map<String, List<String>> countyTownships = {
    '台北市': ['中正區','大安區','信義區','松山區','內湖區','士林區','北投區','中山區','萬華區','文山區','南港區','大同區'],
    '新北市': ['板橋區','新莊區','中和區','永和區','土城區','三重區','蘆洲區','淡水區','新店區','汐止區','三峽區','林口區'],
    '桃園市': ['桃園區','中壢區','平鎮區','八德區','楊梅區','蘆竹區','龜山區','大溪區','龍潭區','大園區','觀音區','新屋區'],
    '台中市': ['西屯區','北屯區','南屯區','中區','東區','北區','西區','南區','豐原區','大里區','太平區','清水區'],
    '台南市': ['東區','北區','中西區','南區','安平區','安南區','永康區','歸仁區','新化區','善化區','仁德區','麻豆區'],
    '高雄市': ['苓雅區','前鎮區','三民區','鼓山區','左營區','楠梓區','鳳山區','仁武區','大社區','岡山區','路竹區','旗山區'],
    '基隆市': ['中正區','信義區','仁愛區','中山區','安樂區','暖暖區','七堵區'],
    '新竹市': ['東區','北區','香山區'],
    '嘉義市': ['東區','西區'],
    '新竹縣': ['竹北市','竹東鎮','新埔鎮','關西鎮','湖口鄉','新豐鄉','峨眉鄉','寶山鄉','橫山鄉','芎林鄉'],
    '苗栗縣': ['苗栗市','頭份市','竹南鎮','苑裡鎮','通霄鎮','後龍鎮','銅鑼鄉','三義鄉','西湖鄉','造橋鄉','頭屋鄉','公館鄉','大湖鄉','泰安鄉','南庄鄉','獅潭鄉','三灣鄉','卓蘭鎮'],
    '彰化縣': ['彰化市','員林市','和美鎮','鹿港鎮','溪湖鎮','二林鎮','田中鎮','北斗鎮','花壇鄉','芬園鄉'],
    '南投縣': ['南投市','埔里鎮','草屯鎮','竹山鎮','集集鎮','名間鄉','鹿谷鄉','中寮鄉','魚池鄉','國姓鄉'],
    '雲林縣': ['斗六市','斗南鎮','虎尾鎮','西螺鎮','土庫鎮','北港鎮','古坑鄉','大埤鄉','莿桐鄉','林內鄉'],
    '嘉義縣': ['太保市','朴子市','布袋鎮','大林鎮','民雄鄉','溪口鄉','新港鄉','六腳鄉','東石鄉','義竹鄉'],
    '屏東縣': ['屏東市','潮州鎮','東港鎮','恆春鎮','萬丹鄉','長治鄉','麟洛鄉','九如鄉','里港鄉','鹽埔鄉'],
    '宜蘭縣': ['宜蘭市','羅東鎮','蘇澳鎮','頭城鎮','礁溪鄉','壯圍鄉','員山鄉','冬山鄉','五結鄉','三星鄉'],
    '花蓮縣': ['花蓮市','吉安鄉','新城鄉','秀林鄉','壽豐鄉','鳳林鎮','光復鄉','豐濱鄉','瑞穗鄉','富里鄉'],
    '台東縣': ['台東市','成功鎮','關山鎮','卑南鄉','鹿野鄉','池上鄉','東河鄉','長濱鄉','太麻里鄉','金峰鄉'],
    '澎湖縣': ['馬公市','湖西鄉','白沙鄉','西嶼鄉','望安鄉','七美鄉'],
    '金門縣': ['金城鎮','金湖鎮','金沙鎮','金寧鄉','烈嶼鄉','烏坵鄉'],
    '連江縣': ['南竿鄉','北竿鄉','莒光鄉','東引鄉'],
  };

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
