import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _locationSending = false;
  bool _locationSent = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: AppConstants.sosPulseDuration,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _callNumber(String number) async {
    final confirmed = await _showCallConfirm(number);
    if (!confirmed) return;

    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<bool> _showCallConfirm(String number) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            ),
            title: Row(
              children: [
                const Icon(Icons.phone_rounded,
                  color: AppColors.emergency, size: 24),
                const SizedBox(width: 8),
                const Text('確認撥打'),
              ],
            ),
            content: Text(
              tr('sos.confirm_call', namedArgs: {'number': number}),
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('common.cancel'),
                  style: const TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergency,
                  minimumSize: const Size(80, 40),
                ),
                child: Text(tr('common.confirm')),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _notifyFamily() async {
    setState(() { _locationSending = true; _locationSent = false; });

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final alertData = {
        'uid': uid,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'alertType': 'family_notification',
        'timestamp': FieldValue.serverTimestamp(),
        'timezone': 'Asia/Taipei',
      };

      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.colEmergencyAlerts)
            .add(alertData);
      } catch (_) {
        // Offline: save to Hive
        final box = await Hive.openBox<Map>('emergency_alerts_pending');
        await box.put(const Uuid().v4(), {
          ...alertData,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      setState(() { _locationSent = true; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('error.permission_location')),
          backgroundColor: AppColors.warning,
        ));
      }
    } finally {
      setState(() => _locationSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final isIndonesian = locale == 'id';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(tr('sos.title')),
        backgroundColor: AppColors.emergency,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.pageHorizontalPadding),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Big SOS button with pulse
              Center(
                child: ScaleTransition(
                  scale: _pulseAnim,
                  child: GestureDetector(
                    onTap: () => _callNumber(AppConstants.emergencyHotline),
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.emergency,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emergency.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emergency_rounded,
                            size: 56, color: Colors.white),
                          const SizedBox(height: 8),
                          const Text(
                            'SOS',
                            style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w900,
                              color: Colors.white, letterSpacing: 4,
                            ),
                          ),
                          const Text(
                            '119',
                            style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                tr('sos.call_119_sub'),
                style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Emergency type buttons
              Text(
                '選擇緊急類型',
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.3,
                children: [
                  _EmergencyTypeBtn(emoji: '🤕', label: tr('sos.fall'),
                    onTap: () => _callNumber(AppConstants.emergencyHotline)),
                  _EmergencyTypeBtn(emoji: '🤒', label: tr('sos.fever'),
                    onTap: () => _callNumber(AppConstants.emergencyHotline)),
                  _EmergencyTypeBtn(emoji: '💔', label: tr('sos.chest_pain'),
                    onTap: () => _callNumber(AppConstants.emergencyHotline)),
                  _EmergencyTypeBtn(emoji: '😵', label: tr('sos.unconscious'),
                    onTap: () => _callNumber(AppConstants.emergencyHotline)),
                  _EmergencyTypeBtn(emoji: '🧠', label: tr('sos.stroke'),
                    onTap: () => _callNumber(AppConstants.emergencyHotline)),
                  _EmergencyTypeBtn(emoji: '👪', label: tr('sos.call_family'),
                    onTap: _notifyFamily,
                    color: AppColors.info),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Hotlines
              Text(
                '服務專線',
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              _HotlineTile(
                icon: '📞',
                number: AppConstants.ltcHotline,
                title: tr('sos.call_1966'),
                subtitle: tr('sos.call_1966_sub'),
                color: AppColors.primary,
                onTap: () => _callNumber(AppConstants.ltcHotline),
              ),
              const SizedBox(height: 8),

              // 1955 — shown prominently for Indonesian caregivers
              _HotlineTile(
                icon: '🇮🇩',
                number: AppConstants.migrantHotline,
                title: tr('sos.call_1955'),
                subtitle: tr('sos.call_1955_sub'),
                color: isIndonesian ? AppColors.secondary : AppColors.info,
                highlighted: isIndonesian,
                onTap: () => _callNumber(AppConstants.migrantHotline),
              ),

              const SizedBox(height: 24),

              // Notify family + location
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningSurface,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                          color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationSent
                                ? tr('sos.location_sent')
                                : tr('sos.call_family_sub'),
                            style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _locationSending ? null : _notifyFamily,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      icon: _locationSending
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                      label: Text(
                        _locationSending
                            ? tr('sos.location_sending')
                            : tr('sos.call_family'),
                        style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyTypeBtn extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  final Color color;

  const _EmergencyTypeBtn({
    required this.emoji,
    required this.label,
    required this.onTap,
    this.color = AppColors.emergency,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _HotlineTile extends StatelessWidget {
  final String icon, number, title, subtitle;
  final Color color;
  final bool highlighted;
  final VoidCallback onTap;

  const _HotlineTile({
    required this.icon,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: highlighted ? color.withOpacity(0.08) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlighted ? color : AppColors.divider,
            width: highlighted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_rounded,
                    color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
