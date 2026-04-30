import 'dart:async';
import 'dart:math' show pi, sin;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/heart_rate_model.dart';
import '../services/heart_rate_service.dart';

// Apple Watch 心率監測畫面
//
// 功能：
//  1. 動態心跳動畫（依 BPM 調整脈動頻率）
//  2. 顯示最新 BPM、狀態（正常 / 心跳過速 / 心跳過慢）、資料來源
//  3. 24 小時記錄列表（異常項目紅色標記）
//  4. 24h 統計摘要（平均 / 最高 / 最低）
//  5. 每 30 秒自動更新（模擬 Apple Watch 同步）

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen>
    with TickerProviderStateMixin {

  // ── 動畫控制 ──────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── 資料狀態 ──────────────────────────────────────────────────────────────
  bool _hasPermission = false;
  bool _loading = true;
  HeartRateReading? _latest;
  List<HeartRateReading> _history = [];
  HeartRateSummary? _summary;
  Timer? _refreshTimer;

  static const _refreshInterval = Duration(seconds: 30);
  static const _heartColor = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _initPulse(72);
    _init();
  }

  void _initPulse(double bpm) {
    _pulseCtrl?.dispose();
    // 每分鐘 bpm 次 → 每次間隔 = 60/bpm 秒
    final beatDuration = Duration(milliseconds: (60000 / bpm.clamp(30, 200)).round());
    _pulseCtrl = AnimationController(vsync: this, duration: beatDuration)
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
    final latest = results[0] as HeartRateReading?;
    final history = results[1] as List<HeartRateReading>;
    final summary = results[2] as HeartRateSummary;
    if (mounted) {
      setState(() {
        _latest = latest;
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isId = context.locale.languageCode == 'id';
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text(isId ? 'Monitor Detak Jantung' : '⌚ 心率監測'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '立即更新',
            onPressed: _refresh,
          ),
        ],
      ),
      body: !_hasPermission
          ? _PermissionDeniedView(onRetry: _init)
          : _loading && _latest == null
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(isId),
    );
  }

  Widget _buildBody(bool isId) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          children: [
            _BpmCard(
              latest: _latest,
              loading: _loading,
              pulseAnim: _pulseAnim,
              isId: isId,
            ),
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

// ─────────────────────────────────────────────────────────────────────────────
// 主 BPM 卡片
// ─────────────────────────────────────────────────────────────────────────────

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
    final bpm = latest?.bpm ?? 0;
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
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        children: [
          // 動態心跳圖示
          ScaleTransition(
            scale: pulseAnim,
            child: Icon(Icons.favorite_rounded, size: 64, color: color),
          ),
          const SizedBox(height: 16),

          // BPM 大字
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                latest == null ? '--' : latest!.bpmLabel,
                style: TextStyle(
                  fontSize: 72, fontWeight: FontWeight.w800, color: color,
                  height: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  ' BPM',
                  style: TextStyle(fontSize: 20, color: color.withOpacity(0.7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 狀態 chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          const SizedBox(height: 16),

          // 資料來源 + 時間
          if (latest != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(latest!.sourceIcon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  latest!.source,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(latest!.timestamp),
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],

          // 更新中指示
          if (loading) ...[
            const SizedBox(height: 12),
            const SizedBox(
              height: 16, width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '剛剛';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分鐘前';
    if (diff.inHours < 24) return '${diff.inHours} 小時前';
    return DateFormat('MM/dd HH:mm').format(dt);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 24h 統計摘要卡片
// ─────────────────────────────────────────────────────────────────────────────

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
          Text(
            isId ? 'Ringkasan 24 Jam' : '24 小時統計',
            style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatItem(label: isId ? 'Rata-rata' : '平均', value: summary.avgLabel),
              _StatItem(label: isId ? 'Tertinggi' : '最高', value: summary.maxLabel,
                  color: const Color(0xFFB71C1C)),
              _StatItem(label: isId ? 'Terendah' : '最低', value: summary.minLabel,
                  color: const Color(0xFF1565C0)),
              _StatItem(
                label: isId ? 'Abnormal' : '異常次數',
                value: '${summary.abnormalCount}',
                color: summary.abnormalCount > 0 ? AppColors.emergency : AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: color,
          )),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(
            fontSize: 10, color: AppColors.textSecondary,
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 歷史記錄列表
// ─────────────────────────────────────────────────────────────────────────────

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
          isId ? 'Riwayat 24 Jam (${history.length} data)' : '24 小時記錄（${history.length} 筆）',
          style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
          ),
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
            child: Center(
              child: Text(
                isId ? 'Belum ada data dari Apple Watch' : '尚無 Apple Watch 心率資料',
                style: const TextStyle(color: AppColors.textHint, fontSize: 13),
              ),
            ),
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
          // 時間
          SizedBox(
            width: 70,
            child: Text(
              DateFormat('HH:mm').format(reading.timestamp),
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
              ),
            ),
          ),

          // BPM + 狀態
          Expanded(
            child: Row(
              children: [
                Icon(Icons.favorite_rounded, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  '${reading.bpmLabel} BPM',
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: color,
                  ),
                ),
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
              ],
            ),
          ),

          // 來源
          Text(
            reading.sourceIcon,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 未授權畫面
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onRetry;

  const _PermissionDeniedView({required this.onRetry});

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
            const Text(
              '需要健康資料權限',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '請允許 AnTsiSeCare 存取 Apple Health 資料，\n以讀取 Apple Watch 心率記錄。\n\n設定 → 健康 → 資料存取與裝置 → AnTsiSeCare',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.security_rounded),
              label: const Text('重新授權'),
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
