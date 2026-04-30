import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/heart_rate_model.dart';
import '../models/mi_band_device.dart';

// 小米手環 BLE 心率服務
//
// 資料流：小米手環 → BLE → flutter_blue_plus → Flutter UI
//
// iOS 需在 Info.plist 加入：
//   NSBluetoothAlwaysUsageDescription
//   NSBluetoothPeripheralUsageDescription
//
// Android 需在 AndroidManifest.xml 加入：
//   <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
//   <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
//   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
//   （API < 31 額外需要 BLUETOOTH、BLUETOOTH_ADMIN）

class MiBandService {
  // ── 內部狀態 ──────────────────────────────────────────────────────────────
  static BluetoothDevice? _device;
  static StreamSubscription<List<int>>? _hrSub;
  static StreamSubscription<BluetoothConnectionState>? _connSub;

  // ── 公開 Stream ───────────────────────────────────────────────────────────

  /// 即時心率資料串流（每筆 Mi Band 量測推送一次）
  static final _readingsCtrl =
      StreamController<HeartRateReading>.broadcast();
  static Stream<HeartRateReading> get readingsStream => _readingsCtrl.stream;

  /// 連線狀態串流（供 UI 即時更新）
  static final _stateCtrl =
      StreamController<MiBandConnectionState>.broadcast();
  static Stream<MiBandConnectionState> get connectionStateStream =>
      _stateCtrl.stream;

  static bool get isConnected => _device != null;

  // ── 掃描 ──────────────────────────────────────────────────────────────────

  /// 掃描周圍的小米手環（10 秒 timeout）
  /// 回傳符合條件的裝置清單
  static Future<List<MiBandDevice>> scan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final found = <MiBandDevice>[];
    final seen = <String>{};

    try {
      _stateCtrl.add(MiBandConnectionState.scanning);
      await FlutterBluePlus.startScan(timeout: timeout);

      await for (final results in FlutterBluePlus.scanResults) {
        for (final r in results) {
          final name = r.device.platformName;
          final id = r.device.remoteId.str;
          if (MiBandDevice.isMiBandDevice(name) && !seen.contains(id)) {
            seen.add(id);
            found.add(MiBandDevice(
              deviceId: id,
              deviceName: name,
              rssi: r.rssi,
            ));
          }
        }
      }
    } catch (_) {
      // 藍牙未開啟或權限被拒：回傳空清單
    } finally {
      await FlutterBluePlus.stopScan();
      _stateCtrl.add(MiBandConnectionState.disconnected);
    }
    return found;
  }

  // ── 連線 ──────────────────────────────────────────────────────────────────

  /// 連線至指定小米手環並開始心率監測
  static Future<bool> connect(MiBandDevice miBand) async {
    try {
      _stateCtrl.add(MiBandConnectionState.connecting);
      _device = BluetoothDevice.fromId(miBand.deviceId);

      await _device!.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      // 監聽連線狀態（自動斷線時通知 UI）
      _connSub = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _stateCtrl.add(MiBandConnectionState.disconnected);
          _cleanup();
        }
      });

      // 發現 GATT 服務
      final services = await _device!.discoverServices();
      final hrService = _findService(services, MiBandDevice.hrServiceUuid);
      if (hrService == null) {
        await disconnect();
        return false;
      }

      // Heart Rate Measurement：訂閱通知
      final hrChar = _findChar(hrService, MiBandDevice.hrMeasurementUuid);
      if (hrChar == null) {
        await disconnect();
        return false;
      }
      await hrChar.setNotifyValue(true);
      _hrSub = hrChar.onValueReceived.listen(_onHrData);

      // Control Point：啟動持續量測（寫入 Mi Band 指令）
      final ctrlChar = _findChar(hrService, MiBandDevice.hrControlPointUuid);
      if (ctrlChar != null) {
        // [0x15, 0x02, 0x01] = 開始連續心率監測
        await ctrlChar.write([0x15, 0x02, 0x01], withoutResponse: false);
      }

      _stateCtrl.add(MiBandConnectionState.connected);
      return true;
    } catch (_) {
      _stateCtrl.add(MiBandConnectionState.error);
      await _cleanup();
      return false;
    }
  }

  // ── 斷線 ──────────────────────────────────────────────────────────────────

  static Future<void> disconnect() async {
    try {
      // 停止持續量測
      if (_device != null) {
        final services = await _device!.discoverServices();
        final hrService = _findService(services, MiBandDevice.hrServiceUuid);
        if (hrService != null) {
          final ctrlChar = _findChar(hrService, MiBandDevice.hrControlPointUuid);
          if (ctrlChar != null) {
            // [0x15, 0x02, 0x00] = 停止連續心率監測
            await ctrlChar.write([0x15, 0x02, 0x00], withoutResponse: false)
                .catchError((_) {});
          }
        }
        await _device!.disconnect();
      }
    } catch (_) {}
    _stateCtrl.add(MiBandConnectionState.disconnected);
    await _cleanup();
  }

  // ── 私有：BLE 資料解析 ────────────────────────────────────────────────────

  // 標準 BLE Heart Rate Measurement 格式：
  //   Byte 0: flags（bit 0 = HR value format: 0=uint8, 1=uint16）
  //   Byte 1（+ Byte 2 若 uint16）: heart rate value
  static void _onHrData(List<int> data) {
    if (data.isEmpty) return;
    final flags = data[0];
    double bpm;
    if (flags & 0x01 == 0) {
      bpm = data.length > 1 ? data[1].toDouble() : 0;
    } else {
      bpm = data.length > 2
          ? (data[1] | (data[2] << 8)).toDouble()
          : 0;
    }
    if (bpm > 0) {
      _readingsCtrl.add(HeartRateReading(
        timestamp: DateTime.now(),
        bpm: bpm,
        source: 'Mi Band',
      ));
    }
  }

  static BluetoothService? _findService(
      List<BluetoothService> services, String uuid) {
    try {
      return services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == uuid.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  static BluetoothCharacteristic? _findChar(
      BluetoothService service, String uuid) {
    try {
      return service.characteristics.firstWhere(
        (c) => c.uuid.toString().toLowerCase() == uuid.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _cleanup() async {
    await _hrSub?.cancel();
    await _connSub?.cancel();
    _hrSub = null;
    _connSub = null;
    _device = null;
  }

  // ── 異常判斷（供背景通知使用）────────────────────────────────────────────

  static bool shouldAlert(HeartRateReading reading) => reading.isAbnormal;
}
