import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phone;
  final String role;
  final String language;
  final String displayName;
  final List<String> elderIds;

  // Caregiver-specific
  final String? nationality;
  final bool prayerReminderEnabled;

  // Elder-specific
  final int? disabilityLevel;
  final String? township;

  // Settings
  final bool elderMode;
  final bool darkMode;

  final DateTime createdAt;
  final DateTime updatedAt;
  static const String timezone = 'Asia/Taipei';

  const UserModel({
    required this.uid,
    required this.phone,
    required this.role,
    required this.language,
    required this.displayName,
    this.elderIds = const [],
    this.nationality,
    this.prayerReminderEnabled = false,
    this.disabilityLevel,
    this.township,
    this.elderMode = false,
    this.darkMode = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'family',
      language: data['language'] ?? 'zh-TW',
      displayName: data['displayName'] ?? '',
      elderIds: List<String>.from(data['elderIds'] ?? []),
      nationality: data['nationality'],
      prayerReminderEnabled: data['prayerReminderEnabled'] ?? false,
      disabilityLevel: data['disabilityLevel'],
      township: data['township'],
      elderMode: data['elderMode'] ?? false,
      darkMode: data['darkMode'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'phone': phone,
    'role': role,
    'language': language,
    'displayName': displayName,
    'elderIds': elderIds,
    'nationality': nationality,
    'prayerReminderEnabled': prayerReminderEnabled,
    'disabilityLevel': disabilityLevel,
    'township': township,
    'elderMode': elderMode,
    'darkMode': darkMode,
    'timezone': timezone,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  UserModel copyWith({
    String? language,
    String? displayName,
    bool? elderMode,
    bool? darkMode,
    bool? prayerReminderEnabled,
    String? township,
    List<String>? elderIds,
  }) => UserModel(
    uid: uid,
    phone: phone,
    role: role,
    language: language ?? this.language,
    displayName: displayName ?? this.displayName,
    elderIds: elderIds ?? this.elderIds,
    nationality: nationality,
    prayerReminderEnabled: prayerReminderEnabled ?? this.prayerReminderEnabled,
    disabilityLevel: disabilityLevel,
    township: township ?? this.township,
    elderMode: elderMode ?? this.elderMode,
    darkMode: darkMode ?? this.darkMode,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );

  bool get isCaregiver => role == 'caregiver';
  bool get isFamily => role == 'family';
  bool get isElder => role == 'elder';
  bool get isCareManager => role == 'care_manager';
  bool get isIndonesian => nationality == 'ID';
  bool get needsIndonesianInterface => language == 'id';
}
