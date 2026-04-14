import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/timezone_utils.dart';
import '../models/care_log_model.dart';

class CareLogListScreen extends StatelessWidget {
  const CareLogListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('care_log.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => context.push('/care-log/new'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.colCareLogs)
            .where('caregiverId', isEqualTo: uid)
            .orderBy('checkInAt', descending: true)
            .limit(30)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(tr('common.error')));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppConstants.pageHorizontalPadding),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final log = CareLogModel.fromFirestore(docs[i]);
              return _CareLogCard(log: log);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/care-log/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          tr('care_log.new_log'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _CareLogCard extends StatelessWidget {
  final CareLogModel log;
  const _CareLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final hasAbnormal = log.careItems.hasAnyAbnormal || log.vitals.hasAnyAbnormal;

    return Card(
      child: InkWell(
        onTap: () => context.push('/care-log/${log.id}'),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Date badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.logDate,
                      style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (log.checkInAt != null)
                    Text(
                      TimezoneUtils.formatTime(log.checkInAt!),
                      style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary,
                      ),
                    ),
                  const Spacer(),
                  // Sync status
                  if (log.syncStatus == 'pending')
                    const Icon(Icons.cloud_upload_outlined,
                      size: 16, color: AppColors.warning),
                  if (hasAbnormal)
                    const Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.emergency),
                ],
              ),
              const SizedBox(height: 10),

              // Care item indicators
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _buildItemChips(log.careItems),
              ),

              // Note preview
              if (log.noteOriginal != null && log.noteOriginal!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Text(
                  log.noteOriginal!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (log.noteTranslated != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.translate_rounded,
                        size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          log.noteTranslated!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12, color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItemChips(CareItems items) {
    final chips = <Widget>[];
    void add(String? icon, CareItemStatus? status) {
      if (status == null || status == CareItemStatus.skipped) return;
      final isAbnormal = status.isAbnormal;
      chips.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isAbnormal
              ? AppColors.emergencySurface
              : AppColors.successSurface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '$icon ${isAbnormal ? "!" : "✓"}',
          style: TextStyle(
            fontSize: 12,
            color: isAbnormal ? AppColors.emergency : AppColors.success,
          ),
        ),
      ));
    }

    add('🍚', items.feeding);
    add('💊', items.medication);
    add('🚽', items.excretion);
    add('🛁', items.bathing);
    add('💪', items.exercise);
    add('😴', items.sleep);
    add('😊', items.mood);
    add('🩹', items.wound);

    return chips;
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            tr('care_log.title'),
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/care-log/new'),
            icon: const Icon(Icons.add),
            label: Text(tr('care_log.new_log')),
          ),
        ],
      ),
    );
  }
}
