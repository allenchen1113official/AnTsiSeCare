import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/timezone_utils.dart';
import '../../care_log/models/care_log_model.dart';

/// 家屬查閱介面 — 顯示中文翻譯版照護日誌
class FamilyViewScreen extends StatelessWidget {
  final String elderId;
  const FamilyViewScreen({super.key, required this.elderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('care_log.family_view')),
        backgroundColor: AppColors.primarySurface,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colCareLogs)
            .where('elderId', isEqualTo: elderId)
            .orderBy('checkInAt', descending: true)
            .limit(20)
            .snapshots(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('目前沒有照護紀錄',
                style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppConstants.pageHorizontalPadding),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final log = CareLogModel.fromFirestore(docs[i]);
              return _FamilyLogCard(log: log);
            },
          );
        },
      ),
    );
  }
}

class _FamilyLogCard extends StatelessWidget {
  final CareLogModel log;
  const _FamilyLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final hasAbnormal =
        log.careItems.hasAnyAbnormal || log.vitals.hasAnyAbnormal;

    return Card(
      elevation: hasAbnormal ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        side: BorderSide(
          color: hasAbnormal
              ? AppColors.emergency.withOpacity(0.4)
              : AppColors.divider,
          width: hasAbnormal ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  log.logDate,
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                if (log.checkInAt != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    TimezoneUtils.formatTime(log.checkInAt!),
                    style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const Spacer(),
                if (hasAbnormal)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.emergencySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                          size: 12, color: AppColors.emergency),
                        SizedBox(width: 4),
                        Text('需注意',
                          style: TextStyle(
                            fontSize: 11, color: AppColors.emergency,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Vitals (if any)
            if (_hasVitals(log.vitals)) ...[
              _VitalsRow(vitals: log.vitals),
              const SizedBox(height: 10),
            ],

            // Chinese translation (family reads)
            if (log.noteTranslated?.isNotEmpty == true) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.translate_rounded,
                          size: 14, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text('照護員備註（已翻譯）',
                          style: TextStyle(
                            fontSize: 11, color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      log.noteTranslated!,
                      style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (log.noteOriginal?.isNotEmpty == true) ...[
              Text(
                log.noteOriginal!,
                style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasVitals(Vitals v) =>
      v.systolicBP != null ||
      v.temperature != null ||
      v.bloodSugar != null ||
      v.heartRate != null;
}

class _VitalsRow extends StatelessWidget {
  final Vitals vitals;
  const _VitalsRow({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 4,
      children: [
        if (vitals.systolicBP != null)
          _VitalBadge(
            icon: '❤️',
            value: '${vitals.systolicBP!.toInt()}/'
                '${vitals.diastolicBP?.toInt() ?? '?'} mmHg',
            isAbnormal: vitals.systolicBP! > 140 || vitals.systolicBP! < 90,
          ),
        if (vitals.temperature != null)
          _VitalBadge(
            icon: '🌡️',
            value: '${vitals.temperature}°C',
            isAbnormal:
                vitals.temperature! > 37.5 || vitals.temperature! < 36.0,
          ),
        if (vitals.bloodSugar != null)
          _VitalBadge(
            icon: '🩸',
            value: '${vitals.bloodSugar} mg/dL',
            isAbnormal:
                vitals.bloodSugar! > 180 || vitals.bloodSugar! < 70,
          ),
      ],
    );
  }
}

class _VitalBadge extends StatelessWidget {
  final String icon, value;
  final bool isAbnormal;

  const _VitalBadge({
    required this.icon,
    required this.value,
    required this.isAbnormal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAbnormal
            ? AppColors.emergencySurface
            : AppColors.successSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isAbnormal ? AppColors.emergency : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
