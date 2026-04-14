import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../models/care_log_model.dart';

class VitalsInputSection extends StatefulWidget {
  final Vitals vitals;
  final ValueChanged<Vitals> onChanged;

  const VitalsInputSection({
    super.key,
    required this.vitals,
    required this.onChanged,
  });

  @override
  State<VitalsInputSection> createState() => _VitalsInputSectionState();
}

class _VitalsInputSectionState extends State<VitalsInputSection> {
  bool _expanded = false;

  // Controllers
  late final TextEditingController _sbpCtrl;
  late final TextEditingController _dbpCtrl;
  late final TextEditingController _sugarCtrl;
  late final TextEditingController _tempCtrl;
  late final TextEditingController _hrCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _spo2Ctrl;

  @override
  void initState() {
    super.initState();
    final v = widget.vitals;
    _sbpCtrl = TextEditingController(text: _fmt(v.systolicBP));
    _dbpCtrl = TextEditingController(text: _fmt(v.diastolicBP));
    _sugarCtrl = TextEditingController(text: _fmt(v.bloodSugar));
    _tempCtrl = TextEditingController(text: _fmt(v.temperature));
    _hrCtrl = TextEditingController(text: _fmt(v.heartRate));
    _weightCtrl = TextEditingController(text: _fmt(v.weight));
    _spo2Ctrl = TextEditingController(text: _fmt(v.oxygenSat));
  }

  String _fmt(double? v) => v == null ? '' : v.toStringAsFixed(1);

  double? _parse(String s) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  void _notify() {
    widget.onChanged(Vitals(
      systolicBP: _parse(_sbpCtrl.text),
      diastolicBP: _parse(_dbpCtrl.text),
      bloodSugar: _parse(_sugarCtrl.text),
      temperature: _parse(_tempCtrl.text),
      heartRate: _parse(_hrCtrl.text),
      weight: _parse(_weightCtrl.text),
      oxygenSat: _parse(_spo2Ctrl.text),
    ));
  }

  @override
  void dispose() {
    for (final c in [
      _sbpCtrl, _dbpCtrl, _sugarCtrl, _tempCtrl, _hrCtrl, _weightCtrl, _spo2Ctrl
    ]) { c.dispose(); }
    super.dispose();
  }

  bool _isAbnormal(String key) {
    final v = widget.vitals;
    switch (key) {
      case 'bp':
        return v.systolicBP != null &&
            (v.systolicBP! > 140 || v.systolicBP! < 90);
      case 'sugar':
        return v.bloodSugar != null &&
            (v.bloodSugar! > 180 || v.bloodSugar! < 70);
      case 'temp':
        return v.temperature != null &&
            (v.temperature! > 37.5 || v.temperature! < 36.0);
      case 'hr':
        return v.heartRate != null &&
            (v.heartRate! > 100 || v.heartRate! < 60);
      case 'spo2':
        return v.oxygenSat != null && v.oxygenSat! < 95;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Blood pressure (always visible — most important)
        _VitalRow(
          icon: '❤️',
          label: tr('care_log.vitals_bp'),
          isAbnormal: _isAbnormal('bp'),
          child: Row(
            children: [
              Expanded(
                child: _VitalField(
                  ctrl: _sbpCtrl,
                  hint: '120',
                  unit: '',
                  onChanged: (_) => _notify(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('/', style: TextStyle(
                  fontSize: 18, color: AppColors.textHint,
                )),
              ),
              Expanded(
                child: _VitalField(
                  ctrl: _dbpCtrl,
                  hint: '80',
                  unit: tr('care_log.bp_unit'),
                  onChanged: (_) => _notify(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Temperature
        _VitalRow(
          icon: '🌡️',
          label: tr('care_log.vitals_temp'),
          isAbnormal: _isAbnormal('temp'),
          child: _VitalField(
            ctrl: _tempCtrl,
            hint: '36.5',
            unit: tr('care_log.temp_unit'),
            onChanged: (_) => _notify(),
          ),
        ),

        // Expand/collapse for more vitals
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _expanded ? '▲ 收起' : '▼ 更多生命徵象',
                  style: const TextStyle(
                    fontSize: 13, color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_expanded) ...[
          _VitalRow(
            icon: '🩸',
            label: tr('care_log.vitals_sugar'),
            isAbnormal: _isAbnormal('sugar'),
            child: _VitalField(
              ctrl: _sugarCtrl,
              hint: '100',
              unit: tr('care_log.sugar_unit'),
              onChanged: (_) => _notify(),
            ),
          ),
          const SizedBox(height: 8),
          _VitalRow(
            icon: '💓',
            label: tr('care_log.vitals_pulse'),
            isAbnormal: _isAbnormal('hr'),
            child: _VitalField(
              ctrl: _hrCtrl,
              hint: '72',
              unit: tr('care_log.pulse_unit'),
              onChanged: (_) => _notify(),
            ),
          ),
          const SizedBox(height: 8),
          _VitalRow(
            icon: '😮‍💨',
            label: tr('care_log.vitals_spo2'),
            isAbnormal: _isAbnormal('spo2'),
            child: _VitalField(
              ctrl: _spo2Ctrl,
              hint: '98',
              unit: tr('care_log.spo2_unit'),
              onChanged: (_) => _notify(),
            ),
          ),
          const SizedBox(height: 8),
          _VitalRow(
            icon: '⚖️',
            label: tr('care_log.vitals_weight'),
            isAbnormal: false,
            child: _VitalField(
              ctrl: _weightCtrl,
              hint: '60',
              unit: tr('care_log.weight_unit'),
              onChanged: (_) => _notify(),
            ),
          ),
        ],
      ],
    );
  }
}

class _VitalRow extends StatelessWidget {
  final String icon, label;
  final bool isAbnormal;
  final Widget child;

  const _VitalRow({
    required this.icon,
    required this.label,
    required this.isAbnormal,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isAbnormal
            ? AppColors.emergencySurface
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAbnormal ? AppColors.emergency.withOpacity(0.4) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isAbnormal ? AppColors.emergency : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: child),
          if (isAbnormal)
            const Icon(Icons.warning_amber_rounded,
              color: AppColors.emergency, size: 16),
        ],
      ),
    );
  }
}

class _VitalField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint, unit;
  final ValueChanged<String> onChanged;

  const _VitalField({
    required this.ctrl,
    required this.hint,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textHint),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
            onChanged: onChanged,
          ),
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(width: 2),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 11, color: AppColors.textHint,
            ),
          ),
        ],
      ],
    );
  }
}
