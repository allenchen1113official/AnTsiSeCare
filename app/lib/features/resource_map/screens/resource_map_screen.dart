import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/ltc_resource_model.dart';
import '../../../core/services/ltc_data_service.dart';
import '../../../core/theme/app_theme.dart';

class ResourceMapScreen extends StatefulWidget {
  const ResourceMapScreen({super.key});

  @override
  State<ResourceMapScreen> createState() => _ResourceMapScreenState();
}

class _ResourceMapScreenState extends State<ResourceMapScreen> {
  List<LtcResourceModel> _all = [];
  List<LtcResourceModel> _filtered = [];
  bool _loading = true;

  String _searchText = '';
  String? _selectedLevel;    // null = 全部
  String? _selectedCounty;   // null = 全台
  String? _selectedTownship;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    final data = await LtcDataService.getTaiwanResources(
      forceRefresh: forceRefresh);
    setState(() {
      _all = data;
      _loading = false;
      _applyFilters();
    });
  }

  void _applyFilters() {
    var result = _all;
    result = LtcDataService.filterByCounty(result, _selectedCounty);
    result = LtcDataService.filterByLevel(result, _selectedLevel);
    result = LtcDataService.filterByTownship(result, _selectedTownship);
    result = LtcDataService.search(result, _searchText);
    setState(() => _filtered = result);
  }

  List<String> get _currentTownships {
    if (_selectedCounty == null) return [];
    return AppConstants.countyTownships[_selectedCounty] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final isIndonesian = locale == 'id';

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('map.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '重新載入資料',
            onPressed: () => _loadData(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 搜尋欄 ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: tr('map.search_hint'),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchText = '');
                          _applyFilters();
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (v) {
                setState(() => _searchText = v);
                _applyFilters();
              },
            ),
          ),

          // ── 等級篩選 chips ───────────────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _LevelChip(label: tr('common.all'), level: null,
                  selected: _selectedLevel == null,
                  onTap: () { setState(() => _selectedLevel = null); _applyFilters(); }),
                const SizedBox(width: 8),
                _LevelChip(label: 'A 級', level: 'A',
                  selected: _selectedLevel == 'A', color: AppColors.success,
                  onTap: () { setState(() => _selectedLevel = _selectedLevel == 'A' ? null : 'A'); _applyFilters(); }),
                const SizedBox(width: 8),
                _LevelChip(label: 'B 級', level: 'B',
                  selected: _selectedLevel == 'B', color: AppColors.primary,
                  onTap: () { setState(() => _selectedLevel = _selectedLevel == 'B' ? null : 'B'); _applyFilters(); }),
                const SizedBox(width: 8),
                _LevelChip(label: 'C 級', level: 'C',
                  selected: _selectedLevel == 'C', color: AppColors.info,
                  onTap: () { setState(() => _selectedLevel = _selectedLevel == 'C' ? null : 'C'); _applyFilters(); }),
              ],
            ),
          ),

          // ── 縣市下拉選單 ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: DropdownButtonFormField<String?>(
              value: _selectedCounty,
              isDense: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixIcon: Icon(Icons.map_rounded, size: 18),
              ),
              hint: const Text('全台灣'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('全台灣')),
                ...AppConstants.taiwanCounties.map((c) =>
                  DropdownMenuItem<String?>(value: c, child: Text(c))),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedCounty = v;
                  _selectedTownship = null;
                });
                _applyFilters();
              },
            ),
          ),

          // ── 鄉鎮市篩選 chips（依選定縣市動態顯示）────────────────────────
          if (_currentTownships.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                children: [
                  _TownshipChip(label: '全鄉鎮', selected: _selectedTownship == null,
                    onTap: () { setState(() => _selectedTownship = null); _applyFilters(); }),
                  ..._currentTownships.map((t) =>
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _TownshipChip(label: t,
                        selected: _selectedTownship == t,
                        onTap: () {
                          setState(() => _selectedTownship =
                              _selectedTownship == t ? null : t);
                          _applyFilters();
                        }),
                    )),
                ],
              ),
            ),

          const SizedBox(height: 4),
          // 結果數量
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '找到 ${_filtered.length} 間機構',
                  style: const TextStyle(
                    fontSize: 12, color: AppColors.textHint),
                ),
                if (isIndonesian) ...[
                  const SizedBox(width: 6),
                  Text(
                    '（${_filtered.length} fasilitas）',
                    style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ── 機構清單 ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _EmptyResult()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _ResourceCard(
                          resource: _filtered[i],
                          isIndonesian: isIndonesian,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── 等級標籤 ─────────────────────────────────────────────────────────────────

class _LevelChip extends StatelessWidget {
  final String label;
  final String? level;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _LevelChip({
    required this.label,
    required this.level,
    required this.selected,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : AppColors.divider),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          )),
      ),
    );
  }
}

class _TownshipChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TownshipChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          )),
      ),
    );
  }
}

// ── 機構卡片 ─────────────────────────────────────────────────────────────────

class _ResourceCard extends StatelessWidget {
  final LtcResourceModel resource;
  final bool isIndonesian;

  const _ResourceCard(
      {required this.resource, required this.isIndonesian});

  Color get _levelColor {
    switch (resource.level) {
      case 'A': return AppColors.success;
      case 'B': return AppColors.primary;
      default:  return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Level badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _levelColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _levelColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      '${resource.level} 級',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: _levelColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      resource.township,
                      style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (resource.phone != null)
                    GestureDetector(
                      onTap: () => _call(resource.phone!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_rounded,
                              size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(tr('map.call_now'),
                              style: const TextStyle(
                                fontSize: 12, color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              )),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                resource.name,
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isIndonesian) ...[
                const SizedBox(height: 2),
                Text(
                  resource.levelLabelId,
                  style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                    size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      resource.address,
                      style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (resource.serviceHours != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                      size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      resource.serviceHours!,
                      style: const TextStyle(
                        fontSize: 12, color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _call(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _navigate(BuildContext context) async {
    if (!resource.hasLocation) return;
    final uri = Uri.parse(
      'geo:${resource.lat},${resource.lng}?q=${Uri.encodeComponent(resource.address)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (ctx, sc) => _DetailSheet(
          resource: resource,
          scrollCtrl: sc,
          isIndonesian: isIndonesian,
          onCall: resource.phone != null ? () => _call(resource.phone!) : null,
          onNavigate: resource.hasLocation ? () => _navigate(context) : null,
        ),
      ),
    );
  }
}

// ── 詳細資訊 bottom sheet ────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final LtcResourceModel resource;
  final ScrollController scrollCtrl;
  final bool isIndonesian;
  final VoidCallback? onCall;
  final VoidCallback? onNavigate;

  const _DetailSheet({
    required this.resource,
    required this.scrollCtrl,
    required this.isIndonesian,
    this.onCall,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text(resource.name,
          style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          )),

        const SizedBox(height: 4),
        Text(
          isIndonesian ? resource.levelLabelId : resource.levelLabel,
          style: const TextStyle(fontSize: 14, color: AppColors.primary),
        ),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),

        _InfoRow(icon: Icons.location_on_rounded,
          label: tr('map.address'), value: resource.address),

        if (resource.phone != null)
          _InfoRow(icon: Icons.phone_rounded,
            label: tr('map.phone'), value: resource.phone!),

        if (resource.serviceHours != null)
          _InfoRow(icon: Icons.schedule_rounded,
            label: tr('map.service_hours'), value: resource.serviceHours!),

        if (resource.services.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(tr('map.services'),
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            )),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 4,
            children: resource.services.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(s, style: const TextStyle(
                fontSize: 11, color: AppColors.primary)),
            )).toList(),
          ),
        ],

        const SizedBox(height: 24),

        Row(
          children: [
            if (onCall != null)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  label: Text(tr('map.call_now')),
                ),
              ),
            if (onCall != null && onNavigate != null)
              const SizedBox(width: 12),
            if (onNavigate != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: Text(tr('map.navigate')),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text(label,
              style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              )),
          ),
          Expanded(
            child: Text(value,
              style: const TextStyle(
                fontSize: 14, color: AppColors.textPrimary,
              )),
          ),
        ],
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(tr('map.no_result'),
            style: const TextStyle(
              fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('請嘗試調整縣市或搜尋條件',
            style: TextStyle(fontSize: 12, color: AppColors.textHint)),
        ],
      ),
    );
  }
}
