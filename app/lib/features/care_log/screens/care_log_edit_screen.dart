import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/timezone_utils.dart';
import '../models/care_log_model.dart';
import '../widgets/care_item_grid.dart';
import '../widgets/vitals_input_section.dart';

class CareLogEditScreen extends StatefulWidget {
  final String? elderId;
  final String? logId;

  const CareLogEditScreen({super.key, this.elderId, this.logId});

  @override
  State<CareLogEditScreen> createState() => _CareLogEditScreenState();
}

class _CareLogEditScreenState extends State<CareLogEditScreen> {
  late CareLogModel _log;
  final _noteCtrl = TextEditingController();
  final _speechToText = SpeechToText();
  bool _speechAvailable = false;
  bool _listening = false;
  bool _translating = false;
  bool _saving = false;
  bool _showTranslation = false;

  // Current display language (for bilingual toggle)
  bool _showIndonesian = true;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _log = CareLogModel.newToday(
      elderId: widget.elderId ?? '',
      caregiverId: uid,
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speechToText.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _speechToText.stop();
    super.dispose();
  }

  // ── Care item toggle ──────────────────────────────────────────────────────

  void _toggleCareItem(String key, CareItemStatus? status) {
    setState(() {
      _log = _log.copyWith(
        careItems: _log.careItems.copyWithItem(key, status),
      );
    });
  }

  // ── Voice input ──────────────────────────────────────────────────────────

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() {
            _noteCtrl.text = result.recognizedWords;
            _listening = false;
          });
        }
      },
      localeId: context.locale.languageCode == 'id' ? 'id_ID' : 'zh_TW',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
    setState(() => _listening = true);
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() => _listening = false);
  }

  // ── Claude translation ────────────────────────────────────────────────────

  Future<void> _translate() async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _translating = true);

    final result = await TranslationService.translateCareNote(
      originalText: text,
      sourceLanguage: context.locale.toString().replaceAll('_', '-'),
    );

    setState(() {
      _translating = false;
      _showTranslation = true;
      _log = _log.copyWith(
        noteOriginal: text,
        noteTranslated: result.translated,
        noteLanguage: context.locale.languageCode,
      );
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    // Validate: abnormal items need notes
    if (_log.careItems.hasAnyAbnormal &&
        _noteCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('care_log.abnormal_note_required')),
        backgroundColor: AppColors.emergency,
      ));
      return;
    }

    setState(() => _saving = true);

    final finalLog = _log.copyWith(
      noteOriginal: _noteCtrl.text.trim().isNotEmpty
          ? _noteCtrl.text.trim()
          : null,
      checkOutAt: DateTime.now().toUtc(),
    );

    try {
      // Try Firestore first
      final docRef = FirebaseFirestore.instance
          .collection(AppConstants.colCareLogs)
          .doc();
      await docRef.set(finalLog.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('care_log.save_success')),
          backgroundColor: AppColors.success,
        ));
        context.pop();
      }
    } catch (_) {
      // Offline: save to Hive
      final box = Hive.box<Map>(AppConstants.hiveBoxCareLog);
      final id = const Uuid().v4();
      await box.put(id, {...finalLog.toHive(), 'id': id});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('care_log.save_offline')),
          backgroundColor: AppColors.warning,
        ));
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final isIndonesian = locale == 'id';

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('care_log.new_log')),
        actions: [
          // Bilingual toggle button
          GestureDetector(
            onTap: () => setState(() => _showIndonesian = !_showIndonesian),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary),
              ),
              child: Text(
                _showIndonesian ? '🌐 中 / id' : '🌐 id / 中',
                style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pageHorizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Check-in time
            _SectionHeader(
              icon: Icons.access_time_rounded,
              title: TimezoneUtils.formatDateTime(
                  _log.checkInAt ?? DateTime.now().toUtc()),
            ),

            const SizedBox(height: 20),

            // A. Care item icon grid
            Text(
              tr('care_log.care_items'),
              style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            CareItemGrid(
              careItems: _log.careItems,
              onToggle: _toggleCareItem,
            ),

            const SizedBox(height: 24),

            // B. Vitals
            Text(
              tr('care_log.vitals'),
              style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            VitalsInputSection(
              vitals: _log.vitals,
              onChanged: (v) => setState(() => _log = _log.copyWith(vitals: v)),
            ),

            const SizedBox(height: 24),

            // C. Note with voice input
            Text(
              tr('care_log.note'),
              style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Abnormal warning
            if (_log.careItems.hasAnyAbnormal || _log.vitals.hasAnyAbnormal)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emergencySurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.emergency.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                      color: AppColors.emergency, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr('care_log.abnormal_note_required'),
                        style: const TextStyle(
                          fontSize: 13, color: AppColors.emergency,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            TextField(
              controller: _noteCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: isIndonesian
                    ? tr('care_log.note_hint')
                    : tr('care_log.note_hint'),
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() => _showTranslation = false),
            ),

            const SizedBox(height: 12),

            // Voice input button
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onLongPressStart: (_) => _startListening(),
                    onLongPressEnd: (_) => _stopListening(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      decoration: BoxDecoration(
                        color: _listening
                            ? AppColors.emergencySurface
                            : AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _listening
                              ? AppColors.emergency
                              : AppColors.primary,
                          width: _listening ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _listening ? Icons.mic : Icons.mic_none_rounded,
                            color: _listening
                                ? AppColors.emergency
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _listening
                                ? '🔴 ${tr("care_log.voice_input")}...'
                                : tr('care_log.voice_hint'),
                            style: TextStyle(
                              color: _listening
                                  ? AppColors.emergency
                                  : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Translate button
                OutlinedButton.icon(
                  onPressed: _translating ? null : _translate,
                  icon: _translating
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.translate_rounded, size: 18),
                  label: Text(
                    _translating
                        ? tr('care_log.translating')
                        : tr('care_log.translate'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),

            // Translation result
            if (_showTranslation && _log.noteTranslated != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primarySurface),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.translate_rounded,
                          color: AppColors.primary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          tr('care_log.translated_label'),
                          style: const TextStyle(
                            fontSize: 12, color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _log.noteTranslated!,
                      style: const TextStyle(
                        fontSize: 15, color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // D. Emergency zone (always visible at bottom)
            _EmergencyZone(),

            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white,
                      ),
                    )
                  : Text(tr('care_log.save_success')),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14, color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EmergencyZone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.emergencySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.emergency.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SosButton(
              label: '🆘 ${tr("sos.call_119")}',
              number: AppConstants.emergencyHotline,
              color: AppColors.emergency,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SosButton(
              label: '📞 1955',
              number: AppConstants.migrantHotline,
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  final String label;
  final String number;
  final Color color;

  const _SosButton({
    required this.label,
    required this.number,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.push('/sos'),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
