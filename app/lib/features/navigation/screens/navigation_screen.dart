import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../models/route_plan_model.dart';
import '../services/osrm_service.dart';

// ── 五組預設地點（住家 + 五個常用目的地）──────────────────────────────────────
//
// 路線 A：住家  → 台大醫院（急診）
// 路線 B：住家  → 台北市大安區衛生所
// 路線 C：住家  → 最近 A 級長照旗艦中心
// 路線 D：住家  → 社區藥局
// 路線 E：住家  → 復健診所
//
// 住家預設座標：台北市大安區（使用者可在設定中修改）

const _homePoint = PlacePoint(
  name: '我的住家',
  nameId: 'Rumah Saya',
  address: '台北市大安區信義路四段 1 號',
  position: LatLng(25.0338, 121.5436),
);

final List<RoutePlan> _defaultPlans = [
  // ── 路線 A：急診醫院 ─────────────────────────────────────────────────────
  RoutePlan(
    id: 'route_a',
    title: '🏥 住家 → 急診醫院',
    titleId: 'Rumah → IGD Rumah Sakit',
    description: '台大醫院（國立台灣大學醫學院附設醫院）\n急診 24 小時',
    category: RouteCategory.medical,
    origin: _homePoint,
    destination: const PlacePoint(
      name: '台大醫院急診',
      nameId: 'IGD NTUH',
      address: '台北市中正區中山南路 7 號',
      position: LatLng(25.0426, 121.5122),
      phone: '02-23123456',
    ),
    color: Color(0xFFB71C1C),  // Emergency Red
  ),

  // ── 路線 B：衛生所 / 診所 ─────────────────────────────────────────────────
  RoutePlan(
    id: 'route_b',
    title: '🏨 住家 → 衛生所',
    titleId: 'Rumah → Puskesmas',
    description: '台北市大安區健康服務中心\n週一至週五 08:00–17:00',
    category: RouteCategory.medical,
    origin: _homePoint,
    destination: const PlacePoint(
      name: '大安區健康服務中心',
      nameId: 'Pusat Kesehatan Da-an',
      address: '台北市大安區建國南路二段 15 號',
      position: LatLng(25.0278, 121.5413),
      phone: '02-27551148',
    ),
    color: Color(0xFF1565C0),  // Info Blue
  ),

  // ── 路線 C：A 級長照旗艦中心 ─────────────────────────────────────────────
  RoutePlan(
    id: 'route_c',
    title: '🏠 住家 → 長照中心',
    titleId: 'Rumah → Pusat LTC',
    description: '台北市大安區長照旗艦整合中心（A 級）\n長照 2.0 服務資源',
    category: RouteCategory.ltcCenter,
    origin: _homePoint,
    destination: const PlacePoint(
      name: '大安區長照旗艦整合中心',
      nameId: 'Pusat LTC Terpadu Da-an',
      address: '台北市大安區信義路四段 100 號',
      position: LatLng(25.0330, 121.5510),
      phone: '02-27001001',
    ),
    color: Color(0xFF1B5E4F),  // Trust Green
  ),

  // ── 路線 D：社區藥局 ──────────────────────────────────────────────────────
  RoutePlan(
    id: 'route_d',
    title: '💊 住家 → 藥局',
    titleId: 'Rumah → Apotek',
    description: '信義聯合藥局（合法藥局）\n週一至週六 08:30–21:00',
    category: RouteCategory.pharmacy,
    origin: _homePoint,
    destination: const PlacePoint(
      name: '信義聯合藥局',
      nameId: 'Apotek Xinyi',
      address: '台北市大安區信義路四段 180 號',
      position: LatLng(25.0323, 121.5551),
      phone: '02-27065580',
    ),
    color: Color(0xFF6A1B9A),  // Pharmacy Purple
  ),

  // ── 路線 E：復健診所 ──────────────────────────────────────────────────────
  RoutePlan(
    id: 'route_e',
    title: '🏃 住家 → 復健診所',
    titleId: 'Rumah → Klinik Rehab',
    description: '大安復健診所（物理治療 / 職能治療）\n週一至週五 08:00–17:30',
    category: RouteCategory.rehabilitation,
    origin: _homePoint,
    destination: const PlacePoint(
      name: '大安復健診所',
      nameId: 'Klinik Rehabilitasi Da-an',
      address: '台北市大安區仁愛路四段 285 號',
      position: LatLng(25.0346, 121.5494),
      phone: '02-27551100',
    ),
    color: Color(0xFFE65100),  // Rehab Orange
  ),
];

// ─────────────────────────────────────────────────────────────────────────────

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final MapController _mapCtrl = MapController();

  List<RoutePlan> _plans = [];
  bool _loading = true;
  int _selectedIdx = 0;

  @override
  void initState() {
    super.initState();
    _plans = _defaultPlans.map((p) => RoutePlan(
      id: p.id, title: p.title, titleId: p.titleId,
      description: p.description, category: p.category,
      origin: p.origin, destination: p.destination, color: p.color,
    )).toList();
    _tabCtrl = TabController(length: _plans.length, vsync: this)
      ..addListener(() {
        if (_tabCtrl.indexIsChanging) return;
        setState(() => _selectedIdx = _tabCtrl.index);
        _fitRoute(_plans[_tabCtrl.index]);
      });
    _loadRoutes();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() => _loading = true);
    await OsrmService.fetchAll(_plans);
    if (mounted) {
      setState(() => _loading = false);
      _fitRoute(_plans[_selectedIdx]);
    }
  }

  void _fitRoute(RoutePlan plan) {
    if (plan.polyline.isEmpty) {
      _mapCtrl.move(plan.origin.position, 13);
      return;
    }
    final lats = plan.polyline.map((p) => p.latitude);
    final lngs = plan.polyline.map((p) => p.longitude);
    final bounds = LatLngBounds(
      LatLng(lats.reduce((a, b) => a < b ? a : b),
             lngs.reduce((a, b) => a < b ? a : b)),
      LatLng(lats.reduce((a, b) => a > b ? a : b),
             lngs.reduce((a, b) => a > b ? a : b)),
    );
    _mapCtrl.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIndonesian = context.locale.languageCode == 'id';
    final plan = _plans[_selectedIdx];

    return Scaffold(
      appBar: AppBar(
        title: Text(isIndonesian ? 'Navigasi' : '導航規劃'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '重新計算路徑',
            onPressed: _loadRoutes,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _plans.map((p) => Tab(
            text: isIndonesian ? p.titleId.split('→').last.trim() : p.title.split('→').last.trim(),
          )).toList(),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: Column(
        children: [
          // ── OSM 地圖 ──────────────────────────────────────────────────────
          Expanded(
            flex: 6,
            child: FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: plan.origin.position,
                initialZoom: 13,
              ),
              children: [
                // OpenStreetMap 圖磚
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'tw.antsicare.app',
                  maxZoom: 19,
                ),
                // 路徑 Polyline
                if (!_loading && plan.polyline.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: plan.polyline,
                        color: plan.color,
                        strokeWidth: 5.0,
                      ),
                    ],
                  ),
                // 起點 / 終點標記
                MarkerLayer(
                  markers: [
                    _buildMarker(
                      point: plan.origin.position,
                      icon: Icons.home_rounded,
                      color: AppColors.primary,
                      label: isIndonesian ? plan.origin.nameId : plan.origin.name,
                    ),
                    _buildMarker(
                      point: plan.destination.position,
                      icon: _destIcon(plan.category),
                      color: plan.color,
                      label: isIndonesian
                          ? plan.destination.nameId
                          : plan.destination.name,
                    ),
                  ],
                ),
                // OSM 版權標示（必填）
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),

          // ── 路線資訊卡 ───────────────────────────────────────────────────
          _RouteInfoCard(
            plan: plan,
            loading: _loading,
            isIndonesian: isIndonesian,
            onNavigate: () => _openExternalNav(plan),
          ),
        ],
      ),
    );
  }

  Marker _buildMarker({
    required LatLng point,
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Marker(
      point: point,
      width: 80,
      height: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 6, spreadRadius: 1,
              )],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _destIcon(RouteCategory cat) {
    switch (cat) {
      case RouteCategory.medical:       return Icons.local_hospital_rounded;
      case RouteCategory.ltcCenter:     return Icons.elderly_rounded;
      case RouteCategory.pharmacy:      return Icons.local_pharmacy_rounded;
      case RouteCategory.rehabilitation: return Icons.accessibility_new_rounded;
      default:                          return Icons.place_rounded;
    }
  }

  Future<void> _openExternalNav(RoutePlan plan) async {
    final d = plan.destination.position;
    final label = Uri.encodeComponent(plan.destination.name);
    // 優先開啟 Google Maps，fallback 到 OSM
    final gUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${plan.origin.position.latitude},${plan.origin.position.longitude}'
      '&destination=${d.latitude},${d.longitude}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(gUri)) {
      await launchUrl(gUri, mode: LaunchMode.externalApplication);
    } else {
      final osmUri = Uri.parse(
        'https://www.openstreetmap.org/directions'
        '?from=${plan.origin.position.latitude},${plan.origin.position.longitude}'
        '&to=${d.latitude},${d.longitude}',
      );
      await launchUrl(osmUri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── 路線資訊卡 ────────────────────────────────────────────────────────────────

class _RouteInfoCard extends StatelessWidget {
  final RoutePlan plan;
  final bool loading;
  final bool isIndonesian;
  final VoidCallback onNavigate;

  const _RouteInfoCard({
    required this.plan,
    required this.loading,
    required this.isIndonesian,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 路線標題
          Text(
            isIndonesian ? plan.titleId : plan.title,
            style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            plan.description,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),

          // 距離 / 時間 / 電話
          Row(
            children: [
              _InfoBadge(
                icon: Icons.straighten_rounded,
                value: loading ? '計算中' : plan.distanceLabel,
                color: plan.color,
              ),
              const SizedBox(width: 8),
              _InfoBadge(
                icon: Icons.schedule_rounded,
                value: loading ? '計算中' : plan.durationLabel,
                color: plan.color,
              ),
              const Spacer(),
              if (plan.destination.phone != null)
                GestureDetector(
                  onTap: () => _call(plan.destination.phone!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          plan.destination.phone!,
                          style: const TextStyle(
                            fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 目的地地址
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 14, color: plan.color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  plan.destination.address,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 導航按鈕
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: Text(isIndonesian ? 'Mulai Navigasi' : '開始導航'),
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _InfoBadge({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
