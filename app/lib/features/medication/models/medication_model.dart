import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/timezone_utils.dart';

enum MedicationFrequency { daily, twiceDaily, threeTimesDaily, weekly, asNeeded }

extension MedicationFrequencyExt on MedicationFrequency {
  String get label {
    switch (this) {
      case MedicationFrequency.daily:           return '每日一次';
      case MedicationFrequency.twiceDaily:      return '每日兩次';
      case MedicationFrequency.threeTimesDaily: return '每日三次';
      case MedicationFrequency.weekly:          return '每週一次';
      case MedicationFrequency.asNeeded:        return '需要時服用';
    }
  }

  String get labelId {
    switch (this) {
      case MedicationFrequency.daily:           return 'Sekali sehari';
      case MedicationFrequency.twiceDaily:      return 'Dua kali sehari';
      case MedicationFrequency.threeTimesDaily: return 'Tiga kali sehari';
      case MedicationFrequency.weekly:          return 'Seminggu sekali';
      case MedicationFrequency.asNeeded:        return 'Bila diperlukan';
    }
  }

  static MedicationFrequency fromString(String? s) =>
      MedicationFrequency.values.firstWhere(
        (e) => e.name == s,
        orElse: () => MedicationFrequency.daily,
      );

  /// 每日幾次
  int get timesPerDay {
    switch (this) {
      case MedicationFrequency.daily:           return 1;
      case MedicationFrequency.twiceDaily:      return 2;
      case MedicationFrequency.threeTimesDaily: return 3;
      default: return 1;
    }
  }
}

class MedicationModel {
  final String? id;
  final String elderId;
  final String name;
  final String? nameId;        // 印尼語藥品名稱（選填）
  final String dosage;
  final MedicationFrequency frequency;
  final List<String> reminderTimes; // ['08:00', '20:00'] 台北時間
  final String? instructions;
  final bool isActive;
  final DateTime createdAt;

  const MedicationModel({
    this.id,
    required this.elderId,
    required this.name,
    this.nameId,
    required this.dosage,
    required this.frequency,
    required this.reminderTimes,
    this.instructions,
    this.isActive = true,
    required this.createdAt,
  });

  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicationModel(
      id: doc.id,
      elderId: data['elderId'] ?? '',
      name: data['name'] ?? '',
      nameId: data['nameId'],
      dosage: data['dosage'] ?? '',
      frequency: MedicationFrequencyExt.fromString(data['frequency']),
      reminderTimes: List<String>.from(data['reminderTimes'] ?? []),
      instructions: data['instructions'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'elderId': elderId,
    'name': name,
    'nameId': nameId,
    'dosage': dosage,
    'frequency': frequency.name,
    'reminderTimes': reminderTimes,
    'instructions': instructions,
    'isActive': isActive,
    'timezone': 'Asia/Taipei',
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class MedicationLogModel {
  final String? id;
  final String medicineId;
  final String elderId;
  final String takenBy;      // caregiverId
  final bool taken;
  final DateTime takenAt;    // UTC
  final String? note;

  const MedicationLogModel({
    this.id,
    required this.medicineId,
    required this.elderId,
    required this.takenBy,
    required this.taken,
    required this.takenAt,
    this.note,
  });

  factory MedicationLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicationLogModel(
      id: doc.id,
      medicineId: data['medicineId'] ?? '',
      elderId: data['elderId'] ?? '',
      takenBy: data['takenBy'] ?? '',
      taken: data['taken'] ?? false,
      takenAt: (data['takenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'medicineId': medicineId,
    'elderId': elderId,
    'takenBy': takenBy,
    'taken': taken,
    'takenAt': Timestamp.fromDate(takenAt),
    'logDate': TimezoneUtils.formatDate(takenAt),
    'note': note,
    'timezone': 'Asia/Taipei',
  };
}
