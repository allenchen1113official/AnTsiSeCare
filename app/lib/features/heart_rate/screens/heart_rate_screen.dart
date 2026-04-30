import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/heart_rate_model.dart';
import '../models/mi_band_device.dart';
import '../services/heart_rate_service.dart';
import '../services/mi_band_service.dart';

// 心率監測畫面（雙裝置）
//
// Tab 1 — ⌚ Apple Watch：經 HealthKit 讀取（iOS 原生 / Android Health Connect）
// Tab 2 — 📿 小米手環：經 BLE 直接連線（flutter_blue_plus）

class HeartRateScreen extends StatelessWidget {
  const HeartRateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isId = context.locale.languageCode == 'id';
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.primaryBg,
        appBar: AppBar(
          title: Text(isId ? 'Monitor Detak Jantung' : '心率監測'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(icon: const Icon(Icons.watch_rounded), text: isId ? 'Apple Watch' : 'Apple Watch'),
              Tab(icon: const Icon(Icons.watch_outlined), text: isId ? 'Mi Band' : '小米手環'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AppleWatchTab(),
            _MiBandTab(),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Tab 1：Apple Watch（HealthKit）
// ═════════════════════════════════════════════════════════════════════════════

class _AppleWatchTab extends StatefulWidget {
  const _AppleWatchTab();

  @override
  State<_AppleWatchTab> createState() => _AppleWatchTabState();
}

class _AppleWatchTabState extends State<_AppleWatchTab>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  bool _hasPermission = false;
  bool _loading = true;
  HeartRateReading? _latest;
  List<HeartRateReading> _history = [];
  HeartRateSummary? _summary;
  Timer? _refreshTimer;

  static const _refreshInterval = Duration(seconds: 30);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initPulse(72);
    _init();
  }

  void _initPulse(double bpm) {
    _pulseCtrl.dispose();
    final ms = (60000 / bpm.clamp(30, 200)).round();
    _pulseCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: ms))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  Future<void> _init() async {
    final granted = await HeartRateService.requestPermissions();
    setState(() => _hasPermission = granted);
    if (granted) {
      await _refresh();
      _refreshTimer = Timer.periodic(_refreshInterval, (_) => _refresh());
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      HeartRateService.fetchLatest(),
      HeartRateService.fetchLast24Hours(),
      HeartRateService.fetchSummary24h(),
    ]);
    final latest  = results[0] as HeartRateReading?;
    final history = results[1] as List<HeartRateReading>;
    final summary = results[2] as HeartRateSummary;
    if (mounted) {
      setState(() {
        _latest  = latest;
        _history = history;
        _summary = summary;
        _loading = false;
      });
      if (latest != null) _initPulse(latest.bpm);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isId = context.locale.languageCode == 'id';
    if (!_hasPermission) return _PermissionView(onRetry: _init, isId: isId);
    if (_loading && _latest == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          children: [
            _BpmCard(latest: _latest, loading: _loading, pulseAnim: _pulseAnim, isId: isId),
            const SizedBox(height: 16),
            if (_summary != null) _SummaryCard(summary: _summary!, isId: isId),
            const SizedBox(height: 16),
            _HistorySection(history: _history, isId: isId),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Tab 2：小米手環（BLE 直連）
// ═════════════════════════════════════════════════════════════════════════════

class _MiBandTab extends StatefulWidget {
  const _MiBandTab();

  @override
  State<_MiBandTab> createState() => _MiBandTabState();
}

class _MiBandTabState extends State<_MiBandTab>
    with AutomaticKeepAliveClientMixin {

  MiBandConnectionState _connState = MiBandConnectionState.disconnected;
  MiBandDevice? _pairedDevice;
  List<MiBandDevice> _foundDevices = [];
  HeartRateReading? _latestReading;
  final List<HeartRateReading> _sessionReadings = [];
  StreamSubscription<HeartRateReading>? _hrSub;
  StreamSubscription<MiBandConnectionState>? _stateSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _stateSub = MiBandService.connectionStateStream.listen((s) {
      if (mounted) setState(() => _connState = s);
    });
    _hrSub = MiBandService.readingsStream.listen((r) {
      if (mounted) setState(() {
        _latestReading = r;
        _sessionReadings.insert(0, r);
        if (_sessionReadings.length > 200) _sessionReadings.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _hrSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _foundDevices = [];
      _connState = MiBandConnectionState.scanning;
    });
    final devices = await MiBandService.scan();
    if (mounted) setState(() => _foundDevices = devices);
  }

  Future<void> _connect(MiBandDevice device) async {
    setState(() => _pairedDevice = device);
    final ok = await MiBandService.connect(device);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('無法連線 ${device.displayName}，請重試')),
      );
    }
  }

  Future<void> _disconnect() async {
    await MiBandService.disconnect();
    if (mounted) setState(() {
      _latestReading = null;
      _sessionReadings.clear();
      _pairedDevice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isId = context.locale.languageCode == 'id';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 連線狀態卡片 ─────────────────────────────────────────────────
          _MiBandStatusCard(
            device: _pairedDevice,
            connState: _connState,
            latest: _latestReading,
            isId: isId,
            onScan: _scan,
            onDisconnect: _disconnect,
          ),
          const SizedBox(height: 16),

          // ── 掃描結果列表（未連線時顯示）──────────────────────────────────
          if (_connState != MiBandConnectionState.connected) ...[
            if (_foundDevices.isNotEmpty) ...[
              Text(
                isId ? 'Perangkat Ditemukan (${_foundDevices.length})' : '找到裝置（${_foundDevices.length}）',
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _DeviceList(devices: _foundDevices, onConnect: _connect, isId: isId),
              const SizedBox(height: 16),
            ],
            if (_connState == MiBandConnectionState.scanning)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('掃描小米手環中…', style: TextStyle(color: AppColors.textSecondary)),
                ]),
              )),
          ],

          // ── 本次連線記錄（已連線時顯示）──────────────────────────────────
          if (_connState == MiBandConnectionState.connected) ...[
            if (_latestReading != null) ...[
              _SummaryCard(
                summary: HeartRateSummary.fromReadings(_sessionReadings),
                isId: isId,
              ),
              const SizedBox(height: 16),
            ],
            _HistorySection(history: _sessionReadings, isId: isId),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 小米手環狀態卡片
// ─────────────────────────────────────────────────────────────────────────────

class _MiBandStatusCard extends StatelessWidget {
  final MiBandDevice? device;
  final MiBandConnectionState connState;
  final HeartRateReading? latest;
  final bool isId;
  final VoidCallback onScan;
  final VoidCallback onDisconnect;

  const _MiBandStatusCard({
    required this.device,
    required this.connState,
    required this.latest,
    required this.isId,
    required this.onScan,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = connState == MiBandConnectionState.connected;
    final bpmColor = latest?.statusColor ?? AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? bpmColor.withOpacity(0.3) : AppColors.divider,
          width: 1.5,
        ),
        boxShadow: [BoxShadow(
          color: (isConnected ? bpmColor : Colors.black).withOpacity(0.06),
          blurRadius: 12, offset: const Offset(0, 3),
        )],
      ),
      child: Column(
        children: [
          // 裝置圖示 + 名稱
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isConnected ? const Color(0xFFFF6D00) : AppColors.textHint)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.watch_outlined,
                  size: 28,
                  color: isConnected ? const Color(0xFFFF6D00) : AppColors.textHint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device?.displayName ?? (isId ? 'Mi Band' : '小米手環'),
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected ? const Color(0xFF2E7D32) : AppColors.textHint,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isId ? (device?.connectionLabelId ?? 'Tidak terhubung')
                               : (device?.connectionLabel ?? '未連線'),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        if (device != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'RSSI ${device!.rssi} dBm（${isId ? _signalId(device!.signalLabel) : device!.signalLabel}）',
                            style: TextStyle(fontSize: 11, color: device!.signalColor),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 即時 BPM（已連線時顯示）
          if (isConnected && latest != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.favorite_rounded, size: 32, color: bpmColor),
                const SizedBox(width: 8),
                Text(
                  latest!.bpmLabel,
                  style: TextStyle(
                    fontSize: 60, fontWeight: FontWeight.w800, color: bpmColor, height: 1.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(' BPM',
                    style: TextStyle(fontSize: 18, color: bpmColor.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: bpmColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: bpmColor.withOpacity(0.3)),
              ),
              child: Text(
                isId ? latest!.statusLabelId : latest!.statusLabel,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: bpmColor),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (isConnected && latest == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('等待心率資料…', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),

          // 操作按鈕
          if (!isConnected)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: connState == MiBandConnectionState.scanning ? null : onScan,
                icon: const Icon(Icons.bluetooth_searching_rounded, size: 18),
                label: Text(isId ? 'Cari Mi Band' : '掃描小米手環'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDisconnect,
                icon: const Icon(Icons.bluetooth_disabled_rounded, size: 18),
                label: Text(isId ? 'Putus Koneksi' : '中斷連線'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.emergency,
                  side: const BorderSide(color: AppColors.emergency),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _signalId(String zh) {
    if (zh == '強') return 'Kuat';
    if (zh == '中') return 'Sedang';
    return 'Lemah';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 掃描到的裝置清單
// ─────────────────────────────────────────────────────────────────────────────

class _DeviceList extends StatelessWidget {
  final List<MiBandDevice> devices;
  final void Function(MiBandDevice) onConnect;
  final bool isId;

  const _DeviceList({required this.devices, required this.onConnect, required this.isId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: devices.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final d = devices[i];
          return ListTile(
            leading: Icon(Icons.watch_outlined, color: d.signalColor),
            title: Text(d.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('${d.rssi} dBm · 訊號${d.signalLabel}',
              style: TextStyle(fontSize: 12, color: d.signalColor)),
            trailing: ElevatedButton(
              onPressed: () => onConnect(d),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: Text(isId ? 'Hubungkan' : '連線'),
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 共用元件（Apple Watch + Mi Band 共享）
// ═════════════════════════════════════════════════════════════════════════════

class _BpmCard extends StatelessWidget {
  final HeartRateReading? latest;
  final bool loading;
  final Animation<double> pulseAnim;
  final bool isId;

  const _BpmCard({
    required this.latest,
    required this.loading,
    required this.pulseAnim,
    required this.isId,
  });

  @override
  Widget build(BuildContext context) {
    final color = latest?.statusColor ?? AppColors.textHint;
    final status = latest == null
        ? (isId ? 'Belum ada data' : '尚無資料')
        : (isId ? latest!.statusLabelId : latest!.statusLabel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4))],
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: pulseAnim,
            child: Icon(Icons.favorite_rounded, size: 64, color: color),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                latest == null ? '--' : latest!.bpmLabel,
                style: TextStyle(fontSize: 72, fontWeight: FontWeight.w800, color: color, height: 1.0),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(' BPM', style: TextStyle(fontSize: 20, color: color.withOpacity(0.7))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(status, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
          ),
          const SizedBox(height: 16),
          if (latest != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(latest!.sourceIcon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(latest!.source,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 4),
            Text(_formatTime(latest!.timestamp),
              style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ],
          if (loading) ...[
            const SizedBox(height: 12),
            const SizedBox(height: 16, width: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '剛剛';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分鐘前';
    if (diff.inHours < 24) return '${diff.inHours} 小時前';
    return DateFormat('MM/dd HH:mm').format(dt);
  }
}

class _SummaryCard extends StatelessWidget {
  final HeartRateSummary summary;
  final bool isId;

  const _SummaryCard({required this.summary, required this.isId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isId ? 'Ringkasan' : '統計摘要',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(children: [
            _StatItem(label: isId ? 'Rata-rata' : '平均', value: summary.avgLabel),
            _StatItem(label: isId ? 'Tertinggi' : '最高', value: summary.maxLabel, color: const Color(0xFFB71C1C)),
            _StatItem(label: isId ? 'Terendah' : '最低', value: summary.minLabel, color: const Color(0xFF1565C0)),
            _StatItem(
              label: isId ? 'Abnormal' : '異常次數',
              value: '${summary.abnormalCount}',
              color: summary.abnormalCount > 0 ? AppColors.emergency : AppColors.textSecondary,
            ),
          ]),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatItem({required this.label, required this.value, this.color = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<HeartRateReading> history;
  final bool isId;
  const _HistorySection({required this.history, required this.isId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isId ? 'Riwayat (${history.length} data)' : '記錄（${history.length} 筆）',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        if (history.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Center(child: Text(
              isId ? 'Belum ada data' : '尚無心率資料',
              style: const TextStyle(color: AppColors.textHint, fontSize: 13),
            )),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _HistoryItem(reading: history[i], isId: isId),
            ),
          ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final HeartRateReading reading;
  final bool isId;
  const _HistoryItem({required this.reading, required this.isId});

  @override
  Widget build(BuildContext context) {
    final color = reading.statusColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(DateFormat('HH:mm').format(reading.timestamp),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Row(children: [
              Icon(Icons.favorite_rounded, size: 14, color: color),
              const SizedBox(width: 4),
              Text('${reading.bpmLabel} BPM',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
              if (reading.isAbnormal) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isId ? reading.statusLabelId : reading.statusLabel,
                    style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ]),
          ),
          Text(reading.sourceIcon, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isId;
  const _PermissionView({required this.onRetry, required this.isId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.watch_rounded, size: 72, color: AppColors.textHint),
            const SizedBox(height: 20),
            Text(isId ? 'Izin Diperlukan' : '需要健康資料權限',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Text(
              isId
                ? 'Izinkan AnTsiSeCare mengakses data kesehatan untuk memantau detak jantung.'
                : '請允許 AnTsiSeCare 存取 Apple Health 資料\n以讀取 Apple Watch 心率記錄。\n\n設定 → 健康 → 資料存取 → AnTsiSeCare',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.security_rounded),
              label: Text(isId ? 'Minta Izin' : '重新授權'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
