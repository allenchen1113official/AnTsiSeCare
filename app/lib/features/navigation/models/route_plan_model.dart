import 'dart:ui' show Color;
import 'package:latlong2/latlong.dart';

enum RouteCategory { home, medical, ltcCenter, pharmacy, rehabilitation }

class PlacePoint {
  final String name;
  final String nameId;
  final String address;
  final LatLng position;
  final String? phone;

  const PlacePoint({
    required this.name,
    required this.nameId,
    required this.address,
    required this.position,
    this.phone,
  });
}

class RoutePlan {
  final String id;
  final String title;
  final String titleId;
  final String description;
  final RouteCategory category;
  final PlacePoint origin;
  final PlacePoint destination;
  final Color color;

  List<LatLng> polyline;
  double? distanceKm;
  int? durationMin;

  RoutePlan({
    required this.id,
    required this.title,
    required this.titleId,
    required this.description,
    required this.category,
    required this.origin,
    required this.destination,
    required this.color,
    this.polyline = const [],
    this.distanceKm,
    this.durationMin,
  });

  String get durationLabel {
    if (durationMin == null) return '計算中…';
    if (durationMin! < 60) return '$durationMin 分鐘';
    final h = durationMin! ~/ 60;
    final m = durationMin! % 60;
    return m == 0 ? '$h 小時' : '$h 時 $m 分';
  }

  String get distanceLabel {
    if (distanceKm == null) return '—';
    return distanceKm! < 1
        ? '${(distanceKm! * 1000).round()} m'
        : '${distanceKm!.toStringAsFixed(1)} km';
  }
}
