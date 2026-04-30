import 'package:flutter/material.dart' show Color;

// Apple Watch 心率監測域模型
//
// 正常範圍：50–100 BPM（靜息心率）
// < 50 BPM → 心跳過慢（bradycardia），標記異常
// > 100 BPM → 心跳過速（tachycardia），標記異常

enum HeartRateStatus { normal, tachycardia, bradycardia }

class HeartRateReading {
  final DateTime timestamp;
  final double bpm;
  final String source; // 'Apple Watch', 'iPhone', 'Manual'

  const HeartRateReading({
    required this.timestamp,
    required this.bpm,
    required this.source,
  });

  // ── 狀態判斷 ──────────────────────────────────────────────────────────────

  HeartRateStatus get status {
    if (bpm > 100) return HeartRateStatus.tachycardia;
    if (bpm < 50)  return HeartRateStatus.bradycardia;
    return HeartRateStatus.normal;
  }

  bool get isAbnormal => status != HeartRateStatus.normal;
  bool get isTachycardia => status == HeartRateStatus.tachycardia;
  bool get isBradycardia => status == HeartRateStatus.bradycardia;
  bool get isFromWatch   => source.toLowerCase().contains('watch');

  // ── 顯示字串 ──────────────────────────────────────────────────────────────

  String get bpmLabel => '${bpm.round()}';

  String get statusLabel {
    switch (status) {
      case HeartRateStatus.tachycardia: return '心跳過速';
      case HeartRateStatus.bradycardia: return '心跳過慢';
      case HeartRateStatus.normal:      return '正常';
    }
  }

  String get statusLabelId {
    switch (status) {
      case HeartRateStatus.tachycardia: return 'Takikardia';
      case HeartRateStatus.bradycardia: return 'Bradikardia';
      case HeartRateStatus.normal:      return 'Normal';
    }
  }

  String get sourceIcon => isFromWatch ? '⌚' : '📱';

  Color get statusColor {
    switch (status) {
      case HeartRateStatus.tachycardia: return const Color(0xFFB71C1C);
      case HeartRateStatus.bradycardia: return const Color(0xFFE65100);
      case HeartRateStatus.normal:      return const Color(0xFF2E7D32);
    }
  }

  // ── 序列化 ────────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'timestamp': timestamp.toIso8601String(),
    'bpm': bpm,
    'source': source,
  };

  factory HeartRateReading.fromMap(Map<String, dynamic> map) => HeartRateReading(
    timestamp: DateTime.parse(map['timestamp'] as String),
    bpm: (map['bpm'] as num).toDouble(),
    source: map['source'] as String? ?? 'Unknown',
  );

  @override
  String toString() => 'HeartRateReading(bpm: $bpm, source: $source, status: $statusLabel)';
}

// ── 24h 統計摘要 ──────────────────────────────────────────────────────────────

class HeartRateSummary {
  final double? avgBpm;
  final double? maxBpm;
  final double? minBpm;
  final int totalReadings;
  final int abnormalCount;
  final DateTime? lastUpdated;

  const HeartRateSummary({
    this.avgBpm,
    this.maxBpm,
    this.minBpm,
    required this.totalReadings,
    required this.abnormalCount,
    this.lastUpdated,
  });

  factory HeartRateSummary.fromReadings(List<HeartRateReading> readings) {
    if (readings.isEmpty) {
      return const HeartRateSummary(totalReadings: 0, abnormalCount: 0);
    }
    final bpms = readings.map((r) => r.bpm).toList();
    final avg = bpms.reduce((a, b) => a + b) / bpms.length;
    return HeartRateSummary(
      avgBpm: avg,
      maxBpm: bpms.reduce((a, b) => a > b ? a : b),
      minBpm: bpms.reduce((a, b) => a < b ? a : b),
      totalReadings: readings.length,
      abnormalCount: readings.where((r) => r.isAbnormal).length,
      lastUpdated: readings.first.timestamp,
    );
  }

  String get avgLabel => avgBpm == null ? '—' : '${avgBpm!.round()} BPM';
  String get maxLabel => maxBpm == null ? '—' : '${maxBpm!.round()} BPM';
  String get minLabel => minBpm == null ? '—' : '${minBpm!.round()} BPM';
}
