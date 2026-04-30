import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../models/medication_model.dart';
import '../models/reminder_settings.dart';
import '../services/reminder_service.dart';

// 用藥提醒設定畫面
//
// 提供：
//  1. 全域提醒總開關
//  2. 提前提醒時間（0 / 5 / 10 / 15 分鐘）
//  3. 貪睡時間（5 / 10 / 15 / 30 分鐘）
//  4. 聲音 / 震動開關
//  5. 每個藥品的個別提醒開關
//  6. 測試通知按鈕

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  ReminderSettings _settings = const ReminderSettings();
  List<MedicationModel> _meds = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final results = await Future.wait([
      ReminderService.loadSettings(),
      FirebaseFirestore.instance
          .collection(AppConstants.colMedicines)
          .where('isActive', isEqualTo: true)
          .get(),
    ]);

    final settings = results[0] as ReminderSettings;
    final snap = results[1] as QuerySnapshot;
    final meds = snap.docs.map((d) => MedicationModel.fromFirestore(d)).toList();

    if (mounted) setState(() {
      _settings = settings;
      _meds = meds;
      _loading = false;
    });
  }

  Future<void> _save(ReminderSettings updated) async {
    setState(() { _settings = updated; _saving = true; });
    await ReminderService.saveSettings(updated);
    await ReminderService.rescheduleAll(_meds, updated);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _sendTestNotification() async {
    final ok = await ReminderService.requestPermissions();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請在系統設定中允許通知權限')),
      );
      return;
    }
    // 5 秒後發送測試通知
    final when = DateTime.now().add(const Duration(seconds: 5));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('將在 5 秒後發送測試通知')),
    );
    final testMed = MedicationModel(
      id: 'test',
      elderId: '',
      name: '測試藥品',
      dosage: '1 顆',
      frequency: MedicationFrequency.daily,
      reminderTimes: [
        '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}',
      ],
      createdAt: DateTime.now(),
    );
    await ReminderService.scheduleForMedication(testMed, _settings);
  }

  @override
  Widget build(BuildContext context) {
    final isId = context.locale.languageCode == 'id';

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text(isId ? 'Pengaturan Pengingat' : '用藥提醒設定'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── 全域總開關 ─────────────────────────────────────────────
                _SectionCard(
                  children: [
                    SwitchListTile(
                      value: _settings.enabled,
                      activeColor: AppColors.primary,
                      title: Text(isId ? 'Aktifkan Pengingat' : '啟用用藥提醒',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        isId
                          ? 'Notifikasi otomatis sesuai jadwal obat'
                          : '依據藥品時間表自動發送本機通知',
                        style: const TextStyle(fontSize: 12),
                      ),
                      secondary: Icon(
                        _settings.enabled
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        color: _settings.enabled
                            ? AppColors.primary
                            : AppColors.textHint,
                      ),
                      onChanged: (v) => _save(_settings.copyWith(enabled: v)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── 提前提醒 ───────────────────────────────────────────────
                _SectionHeader(isId ? 'Waktu Pengingat' : '提前提醒時間'),
                _SectionCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        isId ? 'Berapa menit sebelum jadwal minum obat?'
                             : '在服藥時間前幾分鐘發送通知？',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Wrap(
                        spacing: 8, runSpacing: 8,
                        children: ReminderSettings.advanceOptions.map((min) {
                          final selected = _settings.advanceMinutes == min;
                          final label = min == 0
                              ? (isId ? 'Tepat waktu' : '準時')
                              : (isId ? '$min menit sebelumnya' : '提前 $min 分');
                          return ChoiceChip(
                            label: Text(label, style: const TextStyle(fontSize: 13)),
                            selected: selected,
                            selectedColor: AppColors.primarySurface,
                            checkmarkColor: AppColors.primary,
                            onSelected: (_) => _save(
                                _settings.copyWith(advanceMinutes: min)),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── 貪睡設定 ───────────────────────────────────────────────
                _SectionHeader(isId ? 'Waktu Tunda' : '貪睡時間'),
                _SectionCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        isId ? 'Durasi penundaan saat menekan "Tunda"'
                             : '點擊「稍後提醒」後延遲幾分鐘再次提醒',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Wrap(
                        spacing: 8, runSpacing: 8,
                        children: ReminderSettings.snoozeOptions.map((min) {
                          final selected = _settings.snoozeMinutes == min;
                          return ChoiceChip(
                            label: Text(
                              isId ? '$min menit' : '$min 分鐘',
                              style: const TextStyle(fontSize: 13),
                            ),
                            selected: selected,
                            selectedColor: AppColors.primarySurface,
                            checkmarkColor: AppColors.primary,
                            onSelected: (_) => _save(
                                _settings.copyWith(snoozeMinutes: min)),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── 聲音 / 震動 ────────────────────────────────────────────
                _SectionHeader(isId ? 'Suara & Getaran' : '聲音與震動'),
                _SectionCard(
                  children: [
                    SwitchListTile(
                      value: _settings.soundEnabled,
                      activeColor: AppColors.primary,
                      title: Text(isId ? 'Suara Notifikasi' : '通知聲音'),
                      secondary: const Icon(Icons.volume_up_rounded),
                      onChanged: _settings.enabled
                          ? (v) => _save(_settings.copyWith(soundEnabled: v))
                          : null,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: _settings.vibrationEnabled,
                      activeColor: AppColors.primary,
                      title: Text(isId ? 'Getaran' : '震動'),
                      secondary: const Icon(Icons.vibration_rounded),
                      onChanged: _settings.enabled
                          ? (v) => _save(_settings.copyWith(vibrationEnabled: v))
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── 個別藥品開關 ───────────────────────────────────────────
                _SectionHeader(
                  isId ? 'Pengingat per Obat (${_meds.length})'
                       : '個別藥品提醒（${_meds.length} 筆）',
                ),
                if (_meds.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Center(
                      child: Text(
                        isId ? 'Belum ada obat aktif' : '尚無有效藥品',
                        style: const TextStyle(color: AppColors.textHint),
                      ),
                    ),
                  )
                else
                  _SectionCard(
                    children: List.generate(_meds.length * 2 - 1, (i) {
                      if (i.isOdd) return const Divider(height: 1);
                      final med = _meds[i ~/ 2];
                      final medEnabled = _settings.isMedicationEnabled(med.id ?? '');
                      return SwitchListTile(
                        value: medEnabled,
                        activeColor: AppColors.primary,
                        title: Text(med.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${med.dosage}　${med.reminderTimes.join(' / ')}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        secondary: Text('💊', style: const TextStyle(fontSize: 20)),
                        onChanged: _settings.enabled
                            ? (v) => _save(
                                _settings.withMedicationToggle(med.id ?? '', v))
                            : null,
                      );
                    }),
                  ),

                const SizedBox(height: 24),

                // ── 測試通知 ───────────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: _settings.enabled ? _sendTestNotification : null,
                  icon: const Icon(Icons.notifications_rounded),
                  label: Text(isId ? 'Kirim Notifikasi Uji Coba' : '發送測試通知（5 秒後）'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),

                const SizedBox(height: 12),

                // 取消全部
                OutlinedButton.icon(
                  onPressed: () async {
                    await ReminderService.cancelAll();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isId
                          ? 'Semua pengingat dibatalkan'
                          : '已取消所有待發提醒')),
                      );
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(isId ? 'Batalkan Semua Pengingat' : '取消所有待發提醒'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.emergency,
                    side: const BorderSide(color: AppColors.emergency),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
        style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: AppColors.textSecondary, letterSpacing: 0.5,
        )),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: children),
    );
  }
}
