import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/timezone_utils.dart';
import '../models/medication_model.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final today = TimezoneUtils.todayString();
    final locale = context.locale.languageCode;
    final isIndonesian = locale == 'id';

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('medication.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showAddMedDialog(context, uid),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: AppColors.primarySurface,
            child: Row(
              children: [
                const Icon(Icons.today_rounded,
                  color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${tr("medication.today_schedule")} — $today',
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.colMedicines)
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _EmptyState(
                    isIndonesian: isIndonesian,
                    onAdd: () => _showAddMedDialog(context, uid),
                  );
                }

                final meds = docs
                    .map((d) => MedicationModel.fromFirestore(d))
                    .toList();

                return ListView.separated(
                  padding: const EdgeInsets.all(AppConstants.pageHorizontalPadding),
                  itemCount: meds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _MedicationCard(
                    medication: meds[i],
                    caregiverId: uid,
                    isIndonesian: isIndonesian,
                    today: today,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMedDialog(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddMedicationSheet(caregiverId: uid),
    );
  }
}

// ── 用藥卡片 ──────────────────────────────────────────────────────────────────

class _MedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final String caregiverId;
  final bool isIndonesian;
  final String today;

  const _MedicationCard({
    required this.medication,
    required this.caregiverId,
    required this.isIndonesian,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💊', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medication.name,
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                      if (isIndonesian && medication.nameId != null)
                        Text(medication.nameId!,
                          style: const TextStyle(
                            fontSize: 13, color: AppColors.primary,
                          )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(medication.dosage,
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    )),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Reminder times with take/skip buttons
            Wrap(
              spacing: 8, runSpacing: 6,
              children: medication.reminderTimes.map((time) =>
                _TimeSlot(
                  time: time,
                  medicationId: medication.id ?? '',
                  elderId: medication.elderId,
                  caregiverId: caregiverId,
                  today: today,
                )).toList(),
            ),

            if (medication.instructions != null) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(medication.instructions!,
                      style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint,
                      )),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 時段按鈕（已服用 / 未服用）────────────────────────────────────────────────

class _TimeSlot extends StatefulWidget {
  final String time, medicationId, elderId, caregiverId, today;

  const _TimeSlot({
    required this.time,
    required this.medicationId,
    required this.elderId,
    required this.caregiverId,
    required this.today,
  });

  @override
  State<_TimeSlot> createState() => _TimeSlotState();
}

class _TimeSlotState extends State<_TimeSlot> {
  bool? _taken;   // null = 尚未記錄
  bool _saving = false;

  String get _logDocId =>
      '${widget.medicationId}_${widget.today}_${widget.time.replaceAll(':', '')}';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection(AppConstants.colMedicationLogs)
        .doc(_logDocId)
        .get();
    if (doc.exists && mounted) {
      setState(() => _taken = doc.data()?['taken'] as bool?);
    }
  }

  Future<void> _record(bool taken) async {
    setState(() { _saving = true; });

    final log = MedicationLogModel(
      id: _logDocId,
      medicineId: widget.medicationId,
      elderId: widget.elderId,
      takenBy: widget.caregiverId,
      taken: taken,
      takenAt: DateTime.now().toUtc(),
    );

    await FirebaseFirestore.instance
        .collection(AppConstants.colMedicationLogs)
        .doc(_logDocId)
        .set(log.toFirestore());

    setState(() { _taken = taken; _saving = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _taken == true
            ? AppColors.successSurface
            : _taken == false
                ? AppColors.emergencySurface
                : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _taken == true
              ? AppColors.success
              : _taken == false
                  ? AppColors.emergency
                  : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.time,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: _taken == true
                  ? AppColors.success
                  : _taken == false
                      ? AppColors.emergency
                      : AppColors.textSecondary,
            )),
          const SizedBox(width: 8),
          if (_saving)
            const SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
          else if (_taken == null) ...[
            GestureDetector(
              onTap: () => _record(true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('✓ 已服',
                  style: TextStyle(
                    fontSize: 11, color: Colors.white,
                    fontWeight: FontWeight.w700,
                  )),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _record(false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emergency,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('✕ 未服',
                  style: TextStyle(
                    fontSize: 11, color: Colors.white,
                    fontWeight: FontWeight.w700,
                  )),
              ),
            ),
          ] else
            Icon(
              _taken! ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 16,
              color: _taken! ? AppColors.success : AppColors.emergency,
            ),
        ],
      ),
    );
  }
}

// ── 新增藥品 sheet ────────────────────────────────────────────────────────────

class _AddMedicationSheet extends StatefulWidget {
  final String caregiverId;
  const _AddMedicationSheet({required this.caregiverId});

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final _nameCtrl = TextEditingController();
  final _nameIdCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _instrCtrl = TextEditingController();
  MedicationFrequency _freq = MedicationFrequency.daily;
  final List<String> _times = ['08:00'];
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _nameIdCtrl.dispose();
    _dosageCtrl.dispose(); _instrCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _dosageCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final med = MedicationModel(
      elderId: uid,  // 簡化：以照服員 uid 作為關聯
      name: _nameCtrl.text.trim(),
      nameId: _nameIdCtrl.text.trim().isEmpty ? null : _nameIdCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      frequency: _freq,
      reminderTimes: _times,
      instructions: _instrCtrl.text.trim().isEmpty ? null : _instrCtrl.text.trim(),
      createdAt: DateTime.now().toUtc(),
    );

    await FirebaseFirestore.instance
        .collection(AppConstants.colMedicines)
        .add(med.toFirestore());

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                )),
            ),
            const SizedBox(height: 16),
            Text(tr('medication.add_medication'),
              style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: tr('medication.medicine_name'),
                hintText: '例：血壓藥 / amlodipine',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameIdCtrl,
              decoration: const InputDecoration(
                labelText: '🇮🇩 Nama Obat (Indonesia)',
                hintText: 'Obat darah tinggi',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dosageCtrl,
              decoration: InputDecoration(
                labelText: tr('medication.dosage'),
                hintText: '5mg × 1 顆',
              ),
            ),
            const SizedBox(height: 10),

            // Frequency picker
            Text(tr('medication.frequency'),
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              )),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 4,
              children: MedicationFrequency.values.map((f) =>
                ChoiceChip(
                  label: Text(f.label, style: const TextStyle(fontSize: 12)),
                  selected: _freq == f,
                  onSelected: (_) => setState(() => _freq = f),
                  selectedColor: AppColors.primarySurface,
                  checkmarkColor: AppColors.primary,
                )).toList(),
            ),
            const SizedBox(height: 10),

            // Reminder times
            Text(tr('medication.time'),
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              )),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ..._times.map((t) => Chip(
                  label: Text(t),
                  onDeleted: _times.length > 1
                      ? () => setState(() => _times.remove(t))
                      : null,
                )),
                ActionChip(
                  label: const Text('+ 新增時間'),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      final formatted =
                          '${picked.hour.toString().padLeft(2,'0')}:'
                          '${picked.minute.toString().padLeft(2,'0')}';
                      setState(() => _times.add(formatted));
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),
            TextField(
              controller: _instrCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '備註 / Catatan',
                hintText: '飯後服用 / Diminum setelah makan',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                  : Text(tr('common.save')),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isIndonesian;
  final VoidCallback onAdd;

  const _EmptyState({required this.isIndonesian, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💊', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            isIndonesian
                ? 'Belum ada obat yang ditambahkan'
                : '尚未新增任何藥品',
            style: const TextStyle(
              fontSize: 16, color: AppColors.textSecondary,
            )),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(tr('medication.add_medication')),
          ),
        ],
      ),
    );
  }
}
