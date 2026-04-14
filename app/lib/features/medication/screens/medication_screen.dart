import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/timezone_utils.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('medication.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.today_rounded,
                  color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${tr("medication.today_schedule")} — ${TimezoneUtils.todayString()}',
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💊', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    tr('medication.add_medication'),
                    style: const TextStyle(
                      fontSize: 16, color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: Text(tr('medication.add_medication')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
