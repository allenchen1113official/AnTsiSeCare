import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  late String _selected;

  final _languages = [
    _LangOption(
      code: 'zh-TW', flag: '🇹🇼',
      nativeName: '繁體中文',
      subtitle: 'Traditional Chinese',
    ),
    _LangOption(
      code: 'id', flag: '🇮🇩',
      nativeName: 'Bahasa Indonesia',
      subtitle: 'Indonesian',
      note: 'Prioritas 1 / 第一優先',
    ),
    _LangOption(
      code: 'vi', flag: '🇻🇳',
      nativeName: 'Tiếng Việt',
      subtitle: 'Vietnamese',
    ),
    _LangOption(
      code: 'th', flag: '🇹🇭',
      nativeName: 'ภาษาไทย',
      subtitle: 'Thai',
    ),
    _LangOption(
      code: 'en', flag: '🇬🇧',
      nativeName: 'English',
      subtitle: 'English',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = context.locale.toString().replaceAll('_', '-');
    if (_selected == 'zh_TW') _selected = 'zh-TW';
  }

  void _confirm() {
    final parts = _selected.split('-');
    context.setLocale(Locale(parts[0], parts.length > 1 ? parts[1] : null));
    context.go('/home');
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
                tr('auth.select_language'),
                style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select / 選擇 / Pilih Bahasa',
                style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView.separated(
                  itemCount: _languages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final lang = _languages[i];
                    final isSelected = _selected == lang.code;
                    return _LangTile(
                      option: lang,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selected = lang.code),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _confirm,
                child: Text(tr('common.done')),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangOption {
  final String code, flag, nativeName, subtitle;
  final String? note;
  const _LangOption({
    required this.code,
    required this.flag,
    required this.nativeName,
    required this.subtitle,
    this.note,
  });
}

class _LangTile extends StatelessWidget {
  final _LangOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(option.flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        option.nativeName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (option.note != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondarySurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            option.note!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    option.subtitle,
                    style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
