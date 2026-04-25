import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/route_plan_model.dart';

/// 使用 OSRM 公共路由伺服器計算行駛路徑
/// 端點：router.project-osrm.org（免費、無需 API Key）
class OsrmService {
  static const String _base =
      'https://router.project-osrm.org/route/v1/driving';

  /// 計算兩點間最短行車路徑，填入 RoutePlan
  static Future<void> fetchRoute(RoutePlan plan) async {
    final o = plan.origin.position;
    final d = plan.destination.position;
    final url = Uri.parse(
      '$_base/${o.longitude},${o.latitude};${d.longitude},${d.latitude}'
      '?overview=full&geometries=geojson&steps=false',
    );

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = json['routes'] as List?;
      if (routes == null || routes.isEmpty) return;

      final route = routes.first as Map<String, dynamic>;
      final distM = (route['distance'] as num).toDouble();
      final durSec = (route['duration'] as num).toDouble();

      final coords = (route['geometry']['coordinates'] as List)
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      plan
        ..polyline = coords
        ..distanceKm = distM / 1000
        ..durationMin = (durSec / 60).ceil();
    } catch (_) {
      // 網路失敗：保持 polyline 為空，UI 顯示計算失敗
    }
  }

  /// 批次計算多條路徑
  static Future<void> fetchAll(List<RoutePlan> plans) async {
    await Future.wait(plans.map(fetchRoute));
  }
}
