import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';

/// SyncService: 當網路恢復時，將 Hive 中 pending 的照護紀錄批次上傳至 Firestore
class SyncService {
  static StreamSubscription? _connectivitySub;
  static bool _isSyncing = false;

  static void startListening() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isConnected = results.any(
        (r) => r != ConnectivityResult.none,
      );
      if (isConnected && !_isSyncing) {
        _syncAll();
      }
    });
  }

  static void stopListening() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  static Future<void> _syncAll() async {
    _isSyncing = true;
    try {
      await Future.wait([
        _syncPendingCareLogs(),
        _syncPendingMedicationLogs(),
        _syncPendingAlerts(),
      ]);
    } finally {
      _isSyncing = false;
    }
  }

  /// 同步照護日誌
  static Future<void> _syncPendingCareLogs() async {
    final box = await Hive.openBox<Map>(AppConstants.hiveBoxCareLog);
    if (box.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      final data = box.get(key);
      if (data == null) continue;

      final docRef = data['id'] != null
          ? firestore.collection(AppConstants.colCareLogs).doc(data['id'] as String)
          : firestore.collection(AppConstants.colCareLogs).doc();

      batch.set(docRef, {
        ...Map<String, dynamic>.from(data),
        'syncStatus': 'synced',
        'syncedAt': FieldValue.serverTimestamp(),
      });
      keysToDelete.add(key);
    }

    await batch.commit();
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// 同步用藥紀錄
  static Future<void> _syncPendingMedicationLogs() async {
    final box = await Hive.openBox<Map>(AppConstants.hiveBoxMedication);
    if (box.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      final data = box.get(key);
      if (data == null || data['syncStatus'] != 'pending') continue;

      final docRef = firestore
          .collection(AppConstants.colMedicationLogs)
          .doc(data['id'] as String?);

      batch.set(docRef, {
        ...Map<String, dynamic>.from(data),
        'syncStatus': 'synced',
      });
      keysToDelete.add(key);
    }

    await batch.commit();
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// 同步緊急通報
  static Future<void> _syncPendingAlerts() async {
    final box = await Hive.openBox<Map>('emergency_alerts_pending');
    if (box.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final keysToDelete = <dynamic>[];

    for (final key in box.keys) {
      final data = box.get(key);
      if (data == null) continue;

      final docRef = firestore
          .collection(AppConstants.colEmergencyAlerts)
          .doc();

      batch.set(docRef, Map<String, dynamic>.from(data));
      keysToDelete.add(key);
    }

    await batch.commit();
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  /// 立即嘗試同步（手動觸發）
  static Future<bool> triggerSync() async {
    final results = await Connectivity().checkConnectivity();
    final isConnected = results.any((r) => r != ConnectivityResult.none);
    if (isConnected) {
      await _syncAll();
      return true;
    }
    return false;
  }

  /// 檢查是否有未同步資料
  static Future<int> pendingCount() async {
    final box = await Hive.openBox<Map>(AppConstants.hiveBoxCareLog);
    return box.length;
  }
}
