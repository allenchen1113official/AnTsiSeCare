import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  String? _selectedRole;
  String? _selectedNationality;
  bool _loading = false;

  final _roles = [
    _RoleOption(
      role: AppConstants.roleElder,
      icon: Icons.elderly_rounded,
      color: AppColors.primaryMid,
    ),
    _RoleOption(
      role: AppConstants.roleFamily,
      icon: Icons.family_restroom_rounded,
      color: AppColors.secondary,
    ),
    _RoleOption(
      role: AppConstants.roleCaregiver,
      icon: Icons.medical_services_rounded,
      color: AppColors.info,
    ),
    _RoleOption(
      role: AppConstants.roleCareManager,
      icon: Icons.assignment_ind_rounded,
      color: AppColors.success,
    ),
  ];

  Future<void> _confirm() async {
    if (_selectedRole == null) return;
    setState(() => _loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final phone = FirebaseAuth.instance.currentUser!.phoneNumber ?? '';

    await FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(uid)
        .set({
      'uid': uid,
      'phone': phone,
      'role': _selectedRole,
      'nationality': _selectedNationality,
      'language': context.locale.toString().replaceAll('_', '-'),
      'elderMode': false,
      'darkMode': false,
      'elderIds': [],
      'prayerReminderEnabled': false,
      'timezone': 'Asia/Taipei',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() => _loading = false);
    if (mounted) context.go('/auth/language');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.pageHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                tr('auth.select_role'),
                style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '請選擇最符合您的身份',
                style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Role grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: _roles.map((r) => _RoleCard(
                    option: r,
                    isSelected: _selectedRole == r.role,
                    onTap: () => setState(() => _selectedRole = r.role),
                  )).toList(),
                ),
              ),

              // Caregiver nationality (shown only for caregiver role)
              if (_selectedRole == AppConstants.roleCaregiver) ...[
                const SizedBox(height: 16),
                Text(
                  '國籍（照服員 / 看護工）',
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: AppConstants.nationalityLabels.entries
                      .map((e) => ChoiceChip(
                            label: Text(e.value),
                            selected: _selectedNationality == e.key,
                            onSelected: (_) =>
                                setState(() => _selectedNationality = e.key),
                            selectedColor: AppColors.primarySurface,
                            checkmarkColor: AppColors.primary,
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _selectedRole == null || _loading ? null : _confirm,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      )
                    : Text(tr('common.next')),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOption {
  final String role;
  final IconData icon;
  final Color color;
  const _RoleOption({required this.role, required this.icon, required this.color});
}

class _RoleCard extends StatelessWidget {
  final _RoleOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  String _labelKey() {
    switch (option.role) {
      case AppConstants.roleElder: return 'auth.role_elder';
      case AppConstants.roleFamily: return 'auth.role_family';
      case AppConstants.roleCaregiver: return 'auth.role_caregiver';
      case AppConstants.roleCareManager: return 'auth.role_care_manager';
      default: return option.role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withOpacity(0.12)
              : AppColors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
            color: isSelected ? option.color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: option.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(option.icon, size: 30, color: option.color),
            ),
            const SizedBox(height: 12),
            Text(
              tr(_labelKey()),
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? option.color : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
