import 'package:flutter/material.dart' show Color;

// 小米手環裝置模型
//
// 支援型號：Mi Band 4 / 5 / 6、Xiaomi Smart Band 7 / 7 Pro / 8 / 8 Pro、Redmi Band 1 / 2
// BLE 協議：標準 BLE Heart Rate Profile (0x180D) + Mi Band 自訂 Control Point

enum MiBandConnectionState {
  disconnected,  // 未連線
  scanning,      // 掃描中
  connecting,    // 連線中
  connected,     // 已連線（監測中）
  error,         // 連線失敗
}

class MiBandDevice {
  final String deviceId;    // BLE remoteId
  final String deviceName;
  final int rssi;           // 訊號強度 dBm
  MiBandConnectionState connectionState;

  MiBandDevice({
    required this.deviceId,
    required this.deviceName,
    required this.rssi,
    this.connectionState = MiBandConnectionState.disconnected,
  });

  // ── 顯示 ──────────────────────────────────────────────────────────────────

  String get displayName => deviceName.isNotEmpty ? deviceName : '小米手環';

  String get signalLabel {
    if (rssi >= -60) return '強';
    if (rssi >= -75) return '中';
    return '弱';
  }

  Color get signalColor {
    if (rssi >= -60) return const Color(0xFF2E7D32);
    if (rssi >= -75) return const Color(0xFFF57F17);
    return const Color(0xFFB71C1C);
  }

  bool get isConnected => connectionState == MiBandConnectionState.connected;

  String get connectionLabel {
    switch (connectionState) {
      case MiBandConnectionState.disconnected: return '未連線';
      case MiBandConnectionState.scanning:     return '掃描中…';
      case MiBandConnectionState.connecting:   return '連線中…';
      case MiBandConnectionState.connected:    return '已連線';
      case MiBandConnectionState.error:        return '連線失敗';
    }
  }

  String get connectionLabelId {
    switch (connectionState) {
      case MiBandConnectionState.disconnected: return 'Tidak terhubung';
      case MiBandConnectionState.scanning:     return 'Memindai…';
      case MiBandConnectionState.connecting:   return 'Menghubungkan…';
      case MiBandConnectionState.connected:    return 'Terhubung';
      case MiBandConnectionState.error:        return 'Gagal terhubung';
    }
  }

  // ── 裝置識別（BLE 裝置名稱過濾）─────────────────────────────────────────

  /// 判斷 BLE 裝置名稱是否為小米 / Redmi 手環
  static bool isMiBandDevice(String name) {
    if (name.isEmpty) return false;
    final lower = name.toLowerCase();
    return lower.contains('mi band') ||
           lower.contains('mi smart band') ||
           lower.contains('xiaomi smart band') ||
           lower.contains('redmi band') ||
           lower.contains('amazfit band');
  }

  // ── BLE UUID 常數 ─────────────────────────────────────────────────────────

  /// 標準 BLE Heart Rate Service UUID
  static const hrServiceUuid = '0000180d-0000-1000-8000-00805f9b34fb';

  /// Heart Rate Measurement Characteristic UUID
  static const hrMeasurementUuid = '00002a37-0000-1000-8000-00805f9b34fb';

  /// Heart Rate Control Point UUID（觸發量測）
  static const hrControlPointUuid = '00002a39-0000-1000-8000-00805f9b34fb';

  /// Mi Band 自訂服務 UUID
  static const miBandServiceUuid = '0000fee0-0000-1000-8000-00805f9b34fb';

  // ── 序列化 ────────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'rssi': rssi,
  };

  factory MiBandDevice.fromMap(Map<String, dynamic> map) => MiBandDevice(
    deviceId: map['deviceId'] as String,
    deviceName: map['deviceName'] as String? ?? '',
    rssi: map['rssi'] as int? ?? -80,
  );

  @override
  String toString() => 'MiBandDevice($displayName, rssi: $rssi, $connectionLabel)';
}
