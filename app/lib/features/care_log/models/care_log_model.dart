import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/timezone_utils.dart';

enum CareItemStatus { normal, abnormal, done, skipped, refused, partial }

extension CareItemStatusExt on CareItemStatus {
  String get value => name;
  static CareItemStatus fromString(String? s) {
    return CareItemStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => CareItemStatus.skipped,
    );
  }

  bool get isAbnormal => this == CareItemStatus.abnormal;
  bool get isDone =>
      this == CareItemStatus.done || this == CareItemStatus.normal;
}

class CareItems {
  final CareItemStatus? feeding;
  final CareItemStatus? medication;
  final CareItemStatus? excretion;
  final CareItemStatus? bathing;
  final CareItemStatus? exercise;
  final CareItemStatus? sleep;
  final CareItemStatus? mood;
  final CareItemStatus? wound;
  final CareItemStatus? communication;
  final CareItemStatus? mobility;
  final CareItemStatus? housekeeping;
  final CareItemStatus? cognition;

  const CareItems({
    this.feeding,
    this.medication,
    this.excretion,
    this.bathing,
    this.exercise,
    this.sleep,
    this.mood,
    this.wound,
    this.communication,
    this.mobility,
    this.housekeeping,
    this.cognition,
  });

  bool get hasAnyAbnormal => [
        feeding, medication, excretion, bathing, exercise,
        sleep, mood, wound, communication, mobility,
      ].any((s) => s?.isAbnormal == true);

  factory CareItems.fromMap(Map<String, dynamic> map) => CareItems(
    feeding: CareItemStatusExt.fromString(map[AppConstants.careFeeding]),
    medication: CareItemStatusExt.fromString(map[AppConstants.careMedication]),
    excretion: CareItemStatusExt.fromString(map[AppConstants.careExcretion]),
    bathing: CareItemStatusExt.fromString(map[AppConstants.careBathing]),
    exercise: CareItemStatusExt.fromString(map[AppConstants.careExercise]),
    sleep: CareItemStatusExt.fromString(map[AppConstants.careSleep]),
    mood: CareItemStatusExt.fromString(map[AppConstants.careMood]),
    wound: CareItemStatusExt.fromString(map[AppConstants.careWound]),
    communication: CareItemStatusExt.fromString(map[AppConstants.careCommunication]),
    mobility: CareItemStatusExt.fromString(map[AppConstants.careMobility]),
    housekeeping: CareItemStatusExt.fromString(map[AppConstants.careHousekeeping]),
    cognition: CareItemStatusExt.fromString(map[AppConstants.careCognition]),
  );

  Map<String, dynamic> toMap() => {
    AppConstants.careFeeding: feeding?.value,
    AppConstants.careMedication: medication?.value,
    AppConstants.careExcretion: excretion?.value,
    AppConstants.careBathing: bathing?.value,
    AppConstants.careExercise: exercise?.value,
    AppConstants.careSleep: sleep?.value,
    AppConstants.careMood: mood?.value,
    AppConstants.careWound: wound?.value,
    AppConstants.careCommunication: communication?.value,
    AppConstants.careMobility: mobility?.value,
    AppConstants.careHousekeeping: housekeeping?.value,
    AppConstants.careCognition: cognition?.value,
  };

  CareItems copyWithItem(String key, CareItemStatus? status) {
    return CareItems(
      feeding: key == AppConstants.careFeeding ? status : feeding,
      medication: key == AppConstants.careMedication ? status : medication,
      excretion: key == AppConstants.careExcretion ? status : excretion,
      bathing: key == AppConstants.careBathing ? status : bathing,
      exercise: key == AppConstants.careExercise ? status : exercise,
      sleep: key == AppConstants.careSleep ? status : sleep,
      mood: key == AppConstants.careMood ? status : mood,
      wound: key == AppConstants.careWound ? status : wound,
      communication: key == AppConstants.careCommunication ? status : communication,
      mobility: key == AppConstants.careMobility ? status : mobility,
      housekeeping: key == AppConstants.careHousekeeping ? status : housekeeping,
      cognition: key == AppConstants.careCognition ? status : cognition,
    );
  }
}

class Vitals {
  final double? systolicBP;
  final double? diastolicBP;
  final double? bloodSugar;
  final double? temperature;
  final double? heartRate;
  final double? weight;
  final double? oxygenSat;

  const Vitals({
    this.systolicBP,
    this.diastolicBP,
    this.bloodSugar,
    this.temperature,
    this.heartRate,
    this.weight,
    this.oxygenSat,
  });

  bool get hasAnyAbnormal {
    if (systolicBP != null && (systolicBP! > 140 || systolicBP! < 90)) return true;
    if (bloodSugar != null && (bloodSugar! > 180 || bloodSugar! < 70)) return true;
    if (temperature != null && (temperature! > 37.5 || temperature! < 36.0)) return true;
    if (heartRate != null && (heartRate! > 100 || heartRate! < 60)) return true;
    if (oxygenSat != null && oxygenSat! < 95) return true;
    return false;
  }

  factory Vitals.fromMap(Map<String, dynamic> map) => Vitals(
    systolicBP: (map['systolicBP'] as num?)?.toDouble(),
    diastolicBP: (map['diastolicBP'] as num?)?.toDouble(),
    bloodSugar: (map['bloodSugar'] as num?)?.toDouble(),
    temperature: (map['temperature'] as num?)?.toDouble(),
    heartRate: (map['heartRate'] as num?)?.toDouble(),
    weight: (map['weight'] as num?)?.toDouble(),
    oxygenSat: (map['oxygenSat'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'systolicBP': systolicBP,
    'diastolicBP': diastolicBP,
    'bloodSugar': bloodSugar,
    'temperature': temperature,
    'heartRate': heartRate,
    'weight': weight,
    'oxygenSat': oxygenSat,
  };
}

class CareLogModel {
  final String? id;
  final String elderId;
  final String caregiverId;
  final String logDate;         // 'YYYY-MM-DD'（台北日期）
  final DateTime? checkInAt;    // UTC
  final DateTime? checkOutAt;   // UTC
  final CareItems careItems;
  final Vitals vitals;
  final String? noteOriginal;         // 原文（印尼語等）
  final String? noteTranslated;       // 中文翻譯
  final String? noteLanguage;         // 原文語言代碼
  final List<String> photoUrls;
  final String syncStatus;            // 'pending' | 'synced'

  const CareLogModel({
    this.id,
    required this.elderId,
    required this.caregiverId,
    required this.logDate,
    this.checkInAt,
    this.checkOutAt,
    this.careItems = const CareItems(),
    this.vitals = const Vitals(),
    this.noteOriginal,
    this.noteTranslated,
    this.noteLanguage,
    this.photoUrls = const [],
    this.syncStatus = 'pending',
  });

  /// 使用今日台北日期建立新日誌
  factory CareLogModel.newToday({
    required String elderId,
    required String caregiverId,
  }) => CareLogModel(
    elderId: elderId,
    caregiverId: caregiverId,
    logDate: TimezoneUtils.todayString(),
    checkInAt: DateTime.now().toUtc(),
  );

  factory CareLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CareLogModel(
      id: doc.id,
      elderId: data['elderId'] ?? '',
      caregiverId: data['caregiverId'] ?? '',
      logDate: data['logDate'] ?? '',
      checkInAt: (data['checkInAt'] as Timestamp?)?.toDate(),
      checkOutAt: (data['checkOutAt'] as Timestamp?)?.toDate(),
      careItems: CareItems.fromMap(
          Map<String, dynamic>.from(data['careItems'] ?? {})),
      vitals: Vitals.fromMap(
          Map<String, dynamic>.from(data['vitals'] ?? {})),
      noteOriginal: data['noteOriginal'],
      noteTranslated: data['noteTranslated'],
      noteLanguage: data['noteLanguage'],
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      syncStatus: data['syncStatus'] ?? 'synced',
    );
  }

  factory CareLogModel.fromHive(Map data) => CareLogModel(
    id: data['id'],
    elderId: data['elderId'] ?? '',
    caregiverId: data['caregiverId'] ?? '',
    logDate: data['logDate'] ?? '',
    noteOriginal: data['noteOriginal'],
    noteTranslated: data['noteTranslated'],
    noteLanguage: data['noteLanguage'],
    careItems: CareItems.fromMap(
        Map<String, dynamic>.from(data['careItems'] ?? {})),
    vitals: Vitals.fromMap(
        Map<String, dynamic>.from(data['vitals'] ?? {})),
    photoUrls: List<String>.from(data['photoUrls'] ?? []),
    syncStatus: data['syncStatus'] ?? 'pending',
  );

  Map<String, dynamic> toFirestore() => {
    'elderId': elderId,
    'caregiverId': caregiverId,
    'logDate': logDate,
    'checkInAt': checkInAt != null
        ? Timestamp.fromDate(checkInAt!)
        : FieldValue.serverTimestamp(),
    'checkOutAt': checkOutAt != null
        ? Timestamp.fromDate(checkOutAt!)
        : null,
    'careItems': careItems.toMap(),
    'vitals': vitals.toMap(),
    'noteOriginal': noteOriginal,
    'noteTranslated': noteTranslated,
    'noteLanguage': noteLanguage,
    'photoUrls': photoUrls,
    'syncStatus': 'synced',
    'timezone': 'Asia/Taipei',
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toHive() => {
    'id': id,
    'elderId': elderId,
    'caregiverId': caregiverId,
    'logDate': logDate,
    'checkInAt': checkInAt?.toIso8601String(),
    'checkOutAt': checkOutAt?.toIso8601String(),
    'careItems': careItems.toMap(),
    'vitals': vitals.toMap(),
    'noteOriginal': noteOriginal,
    'noteTranslated': noteTranslated,
    'noteLanguage': noteLanguage,
    'photoUrls': photoUrls,
    'syncStatus': 'pending',
  };

  CareLogModel copyWith({
    CareItems? careItems,
    Vitals? vitals,
    String? noteOriginal,
    String? noteTranslated,
    String? noteLanguage,
    DateTime? checkOutAt,
    List<String>? photoUrls,
  }) => CareLogModel(
    id: id,
    elderId: elderId,
    caregiverId: caregiverId,
    logDate: logDate,
    checkInAt: checkInAt,
    checkOutAt: checkOutAt ?? this.checkOutAt,
    careItems: careItems ?? this.careItems,
    vitals: vitals ?? this.vitals,
    noteOriginal: noteOriginal ?? this.noteOriginal,
    noteTranslated: noteTranslated ?? this.noteTranslated,
    noteLanguage: noteLanguage ?? this.noteLanguage,
    photoUrls: photoUrls ?? this.photoUrls,
    syncStatus: syncStatus,
  );
}
