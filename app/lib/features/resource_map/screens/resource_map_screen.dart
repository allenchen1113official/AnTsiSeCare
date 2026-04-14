import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ResourceMapScreen extends StatelessWidget {
  const ResourceMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('map.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: tr('map.search_hint'),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: const Icon(Icons.tune_rounded),
              ),
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _FilterChip(label: tr('common.all'), selected: true),
                _FilterChip(label: 'A 級', selected: false),
                _FilterChip(label: 'B 級', selected: false),
                _FilterChip(label: 'C 級', selected: false),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Map placeholder (Google Maps requires API key)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryMid.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🗺️', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    tr('map.loading'),
                    style: const TextStyle(
                      fontSize: 16, color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '苗栗縣 18 鄉鎮市長照資源',
                    style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A 級 整合服務中心\nB 級 複合型服務中心\nC 級 巷弄長照站',
                    style: TextStyle(
                      fontSize: 12, color: AppColors.textHint, height: 1.6,
                    ),
                    textAlign: TextAlign.center,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _FilterChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.divider,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}
