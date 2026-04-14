import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Box _settings;

  @override
  void initState() {
    super.initState();
    _settings = Hive.box(AppConstants.hiveBoxSettings);
  }

  bool get _elderMode =>
      _settings.get('elder_mode', defaultValue: false) as bool;
  bool get _darkMode =>
      _settings.get('dark_mode', defaultValue: false) as bool;
  bool get _prayerReminder =>
      _settings.get('prayer_reminder', defaultValue: false) as bool;

  void _setSetting(String key, bool value) {
    _settings.put(key, value);
    setState(() {});
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('profile.logout')),
        content: const Text('確認要登出嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('profile.logout'),
              style: const TextStyle(color: AppColors.emergency)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) context.go('/auth/phone');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('profile.title'))),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.pageHorizontalPadding),
        children: [
          // Language section
          _SectionTitle(title: tr('profile.language')),
          _LangSelector(),

          const SizedBox(height: 20),

          // Accessibility
          _SectionTitle(title: '無障礙設定'),
          _SettingTile(
            icon: Icons.text_fields_rounded,
            title: tr('profile.elder_mode'),
            subtitle: '加大字體與按鈕（長者適用）',
            value: _elderMode,
            onChanged: (v) => _setSetting('elder_mode', v),
          ),
          _SettingTile(
            icon: Icons.dark_mode_rounded,
            title: tr('profile.dark_mode'),
            subtitle: '弱光環境適用（移工宿舍）',
            value: _darkMode,
            onChanged: (v) => _setSetting('dark_mode', v),
          ),
          _SettingTile(
            icon: Icons.mosque_rounded,
            title: tr('profile.prayer_reminder'),
            subtitle: 'Waktu Salat — 適合穆斯林看護工',
            value: _prayerReminder,
            onChanged: (v) => _setSetting('prayer_reminder', v),
          ),

          const SizedBox(height: 20),

          // About
          _SectionTitle(title: '關於'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded,
              color: AppColors.primary),
            title: Text(tr('profile.about')),
            subtitle: Text(
              tr('profile.version',
                namedArgs: {'version': AppConstants.appVersion})),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: AppColors.white,
          ),

          const SizedBox(height: 24),

          // Logout
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.emergency),
            label: Text(
              tr('profile.logout'),
              style: const TextStyle(color: AppColors.emergency),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.emergency),
              minimumSize: const Size(double.infinity, 52),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: AppColors.textHint, letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(title,
          style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _LangSelector extends StatelessWidget {
  static const _langs = [
    ('zh-TW', '🇹🇼', '中文'),
    ('id', '🇮🇩', 'Indonesia'),
    ('vi', '🇻🇳', 'Việt Nam'),
    ('th', '🇹🇭', 'ภาษาไทย'),
    ('en', '🇬🇧', 'English'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = context.locale.toString().replaceAll('_', '-');

    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _langs.map(((code, flag, label)) {
        final selected = current == code ||
            (code == 'zh-TW' && current == 'zh_TW');
        return GestureDetector(
          onTap: () {
            final parts = code.split('-');
            context.setLocale(
              Locale(parts[0], parts.length > 1 ? parts[1] : null));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primarySurface : AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected
                        ? FontWeight.w700 : FontWeight.w400,
                    color: selected
                        ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
