import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _normalizePhone(String raw) {
    // 09xxxxxxxx → +8869xxxxxxxx
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('09') && digits.length == 10) {
      return '+886${digits.substring(1)}';
    }
    return '+$digits';
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final phone = _normalizePhone(_phoneCtrl.text.trim());

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        // Auto-fill OTP (Android only)
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) context.go('/auth/role');
      },
      verificationFailed: (e) {
        setState(() {
          _error = e.message ?? tr('error.network');
          _loading = false;
        });
      },
      codeSent: (verificationId, resendToken) {
        setState(() => _loading = false);
        if (mounted) {
          context.push('/auth/otp', extra: {
            'phone': _phoneCtrl.text.trim(),
            'verificationId': verificationId,
          });
        }
      },
      codeAutoRetrievalTimeout: (_) {
        setState(() => _loading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.pageHorizontalPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo / Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr('app.name'),
                        style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('app.tagline'),
                        style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                Text(
                  tr('auth.welcome'),
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('auth.phone_label'),
                  style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Phone input
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 18, letterSpacing: 1.5),
                  decoration: InputDecoration(
                    hintText: tr('auth.phone_hint'),
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇹🇼', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text('+886',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            height: 24, width: 1,
                            color: AppColors.divider,
                          ),
                        ],
                      ),
                    ),
                  ),
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    if (digits.length != 10 || !digits.startsWith('09')) {
                      return tr('auth.phone_invalid');
                    }
                    return null;
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.emergencySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                          color: AppColors.emergency, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                            style: const TextStyle(
                              color: AppColors.emergency, fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(tr('auth.send_otp')),
                ),

                const SizedBox(height: 24),

                // Language quick switch
                Center(
                  child: Wrap(
                    spacing: 8,
                    children: const [
                      _LangChip(locale: 'zh-TW', label: '中文'),
                      _LangChip(locale: 'id', label: 'Indonesia'),
                      _LangChip(locale: 'vi', label: 'Tiếng Việt'),
                      _LangChip(locale: 'en', label: 'English'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String locale;
  final String label;

  const _LangChip({required this.locale, required this.label});

  @override
  Widget build(BuildContext context) {
    final current = context.locale.toString().replaceAll('_', '-');
    final isSelected = current == locale ||
        (locale == 'zh-TW' && current == 'zh_TW');

    return GestureDetector(
      onTap: () {
        final parts = locale.split('-');
        context.setLocale(Locale(parts[0], parts.length > 1 ? parts[1] : null));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
