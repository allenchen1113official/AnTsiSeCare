import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/timezone_utils.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = TimezoneUtils.nowTaipei().hour;
    if (hour < 12) return 'home.greeting_morning';
    if (hour < 18) return 'home.greeting_afternoon';
    return 'home.greeting_evening';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🇹🇼', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          tr('app.name'),
                          style: const TextStyle(
                            fontSize: 14, color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        // Pending sync badge
                        FutureBuilder<int>(
                          future: SyncService.pendingCount(),
                          builder: (_, snap) {
                            final count = snap.data ?? 0;
                            if (count == 0) return const SizedBox.shrink();
                            return GestureDetector(
                              onTap: SyncService.triggerSync,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '⬆ $count',
                                  style: const TextStyle(
                                    fontSize: 11, color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection(AppConstants.colUsers)
                          .doc(uid)
                          .snapshots(),
                      builder: (_, snap) {
                        final name = snap.hasData && snap.data!.exists
                            ? (snap.data!.data()
                                    as Map<String, dynamic>)['displayName'] ??
                                '使用者'
                            : '使用者';
                        return Text(
                          tr(_greeting(),
                            namedArgs: {'name': name}),
                          style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      TimezoneUtils.formatDate(DateTime.now().toUtc()),
                      style: const TextStyle(
                        fontSize: 13, color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.pageHorizontalPadding),
                child: Text(
                  tr('home.quick_actions'),
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.pageHorizontalPadding),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _QuickAction(
                      icon: '📋', label: tr('care_log.new_log'),
                      color: AppColors.primary,
                      onTap: () => context.push('/care-log/new'),
                    ),
                    _QuickAction(
                      icon: '🆘', label: tr('sos.title'),
                      color: AppColors.emergency,
                      onTap: () => context.go('/sos'),
                    ),
                    _QuickAction(
                      icon: '🗺️', label: tr('map.title'),
                      color: AppColors.info,
                      onTap: () => context.go('/map'),
                    ),
                    _QuickAction(
                      icon: '💊', label: tr('medication.title'),
                      color: AppColors.secondary,
                      onTap: () => context.push('/medication'),
                    ),
                    _QuickAction(
                      icon: '🧭', label: tr('nav.title'),
                      color: const Color(0xFF00695C),
                      onTap: () => context.push('/navigation'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent care logs
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.pageHorizontalPadding),
                child: Row(
                  children: [
                    Text(
                      tr('home.recent_logs'),
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/care-log'),
                      child: Text(tr('common.all'),
                        style: const TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(AppConstants.colCareLogs)
                    .where('caregiverId', isEqualTo: uid)
                    .orderBy('checkInAt', descending: true)
                    .limit(3)
                    .snapshots(),
                builder: (_, snap) {
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.pageHorizontalPadding),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(
                              AppConstants.cardRadius),
                        ),
                        child: Center(
                          child: Text(
                            '尚無照護紀錄，點擊下方新增',
                            style: const TextStyle(
                              color: AppColors.textHint, fontSize: 14),
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.pageHorizontalPadding),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final data =
                          docs[i].data() as Map<String, dynamic>;
                      final logDate = data['logDate'] ?? '';
                      final hasAbnormal =
                          (data['careItems'] as Map? ?? {})
                              .values
                              .any((v) => v == 'abnormal');
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(
                              AppConstants.cardRadius),
                          border: Border.all(
                            color: hasAbnormal
                                ? AppColors.emergency.withOpacity(0.3)
                                : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                logDate,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                data['noteOriginal'] ?? '（無備註）',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (hasAbnormal)
                              const Icon(Icons.warning_amber_rounded,
                                color: AppColors.emergency, size: 16),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String icon, label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
