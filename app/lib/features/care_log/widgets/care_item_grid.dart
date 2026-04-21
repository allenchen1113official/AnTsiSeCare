import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../models/care_log_model.dart';

/// 圖示化照護項目格狀介面（語言無關設計）
class CareItemGrid extends StatelessWidget {
  final CareItems careItems;
  final void Function(String key, CareItemStatus? status) onToggle;

  const CareItemGrid({
    super.key,
    required this.careItems,
    required this.onToggle,
  });

  static final _items = [
    _CareItemDef(key: AppConstants.careFeeding,       icon: '🍚', i18nKey: 'care_log.feeding'),
    _CareItemDef(key: AppConstants.careMedication,    icon: '💊', i18nKey: 'care_log.medication'),
    _CareItemDef(key: AppConstants.careExcretion,     icon: '🚽', i18nKey: 'care_log.excretion'),
    _CareItemDef(key: AppConstants.careBathing,       icon: '🛁', i18nKey: 'care_log.bathing'),
    _CareItemDef(key: AppConstants.careExercise,      icon: '💪', i18nKey: 'care_log.exercise'),
    _CareItemDef(key: AppConstants.careSleep,         icon: '😴', i18nKey: 'care_log.sleep'),
    _CareItemDef(key: AppConstants.careMood,          icon: '😊', i18nKey: 'care_log.mood'),
    _CareItemDef(key: AppConstants.careWound,         icon: '🩹', i18nKey: 'care_log.wound'),
    _CareItemDef(key: AppConstants.careCommunication, icon: '🗣️', i18nKey: 'care_log.communication'),
    _CareItemDef(key: AppConstants.careMobility,      icon: '🚶', i18nKey: 'care_log.mobility'),
    _CareItemDef(key: AppConstants.careHousekeeping,  icon: '🏠', i18nKey: 'care_log.housekeeping'),
    _CareItemDef(key: AppConstants.careCognition,     icon: '🧠', i18nKey: 'care_log.cognition'),
  ];

  CareItemStatus? _statusFor(String key) {
    switch (key) {
      case AppConstants.careFeeding:       return careItems.feeding;
      case AppConstants.careMedication:    return careItems.medication;
      case AppConstants.careExcretion:     return careItems.excretion;
      case AppConstants.careBathing:       return careItems.bathing;
      case AppConstants.careExercise:      return careItems.exercise;
      case AppConstants.careSleep:         return careItems.sleep;
      case AppConstants.careMood:          return careItems.mood;
      case AppConstants.careWound:         return careItems.wound;
      case AppConstants.careCommunication: return careItems.communication;
      case AppConstants.careMobility:      return careItems.mobility;
      case AppConstants.careHousekeeping:  return careItems.housekeeping;
      case AppConstants.careCognition:     return careItems.cognition;
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: _items.map((item) {
        final status = _statusFor(item.key);
        return _CareItemTile(
          item: item,
          status: status,
          onTap: () => _showStatusPicker(context, item, status),
        );
      }).toList(),
    );
  }

  void _showStatusPicker(
    BuildContext context,
    _CareItemDef item,
    CareItemStatus? current,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StatusPickerSheet(
        item: item,
        current: current,
        onSelect: (s) {
          onToggle(item.key, s);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _CareItemDef {
  final String key, icon, i18nKey;
  const _CareItemDef({required this.key, required this.icon, required this.i18nKey});
}

class _CareItemTile extends StatelessWidget {
  final _CareItemDef item;
  final CareItemStatus? status;
  final VoidCallback onTap;

  const _CareItemTile({
    required this.item,
    required this.status,
    required this.onTap,
  });

  Color get _bgColor {
    switch (status) {
      case CareItemStatus.normal:
      case CareItemStatus.done: return AppColors.successSurface;
      case CareItemStatus.abnormal: return AppColors.emergencySurface;
      case CareItemStatus.skipped:
      case CareItemStatus.refused: return AppColors.surface;
      case CareItemStatus.partial: return AppColors.warningSurface;
      default: return AppColors.surface;
    }
  }

  Color get _borderColor {
    switch (status) {
      case CareItemStatus.normal:
      case CareItemStatus.done: return AppColors.success;
      case CareItemStatus.abnormal: return AppColors.emergency;
      case CareItemStatus.partial: return AppColors.warning;
      default: return AppColors.divider;
    }
  }

  String get _statusSymbol {
    switch (status) {
      case CareItemStatus.normal:
      case CareItemStatus.done: return '✓';
      case CareItemStatus.abnormal: return '✕';
      case CareItemStatus.skipped: return '─';
      case CareItemStatus.refused: return '✕';
      case CareItemStatus.partial: return '~';
      default: return '';
    }
  }

  Color get _symbolColor {
    switch (status) {
      case CareItemStatus.normal:
      case CareItemStatus.done: return AppColors.success;
      case CareItemStatus.abnormal:
      case CareItemStatus.refused: return AppColors.emergency;
      case CareItemStatus.partial: return AppColors.warning;
      default: return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _borderColor,
            width: status != null ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              tr(item.i18nKey),
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: status != null
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_statusSymbol.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                _statusSymbol,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: _symbolColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPickerSheet extends StatelessWidget {
  final _CareItemDef item;
  final CareItemStatus? current;
  final void Function(CareItemStatus?) onSelect;

  const _StatusPickerSheet({
    required this.item,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Text(
                  tr(item.i18nKey),
                  style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _StatusOption(
              label: tr('care_log.status_normal'),
              symbol: '✓',
              color: AppColors.success,
              isSelected: current == CareItemStatus.normal,
              onTap: () => onSelect(CareItemStatus.normal),
            ),
            const SizedBox(height: 8),
            _StatusOption(
              label: tr('care_log.status_abnormal'),
              symbol: '⚠️',
              color: AppColors.emergency,
              isSelected: current == CareItemStatus.abnormal,
              onTap: () => onSelect(CareItemStatus.abnormal),
            ),
            const SizedBox(height: 8),
            _StatusOption(
              label: tr('care_log.status_skipped'),
              symbol: '─',
              color: AppColors.textHint,
              isSelected: current == CareItemStatus.skipped,
              onTap: () => onSelect(CareItemStatus.skipped),
            ),
            const SizedBox(height: 8),
            _StatusOption(
              label: tr('care_log.status_refused'),
              symbol: '✕',
              color: AppColors.warning,
              isSelected: current == CareItemStatus.refused,
              onTap: () => onSelect(CareItemStatus.refused),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => onSelect(null),
              child: Text(
                tr('common.cancel'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label, symbol;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.label,
    required this.symbol,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(symbol, style: TextStyle(fontSize: 20, color: color)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(Icons.check_circle_rounded, color: color, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
