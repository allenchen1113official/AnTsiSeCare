class LtcResourceModel {
  final String id;
  final String name;
  final String level;       // 'A' | 'B' | 'C'
  final String county;      // 縣市
  final String township;    // 鄉鎮市
  final String address;
  final String? phone;
  final String? serviceHours;
  final List<String> services;
  final double? lat;
  final double? lng;

  const LtcResourceModel({
    required this.id,
    required this.name,
    required this.level,
    required this.county,
    required this.township,
    required this.address,
    this.phone,
    this.serviceHours,
    this.services = const [],
    this.lat,
    this.lng,
  });

  bool get hasLocation => lat != null && lng != null;

  String get levelLabel {
    switch (level) {
      case 'A': return 'A 級｜整合服務中心';
      case 'B': return 'B 級｜複合型服務中心';
      case 'C': return 'C 級｜巷弄長照站';
      default:  return level;
    }
  }

  String get levelLabelId {
    switch (level) {
      case 'A': return 'Tingkat A – Pusat Layanan Terpadu';
      case 'B': return 'Tingkat B – Pusat Komprehensif';
      case 'C': return 'Tingkat C – Pos Perawatan';
      default:  return level;
    }
  }

  factory LtcResourceModel.fromMap(Map<String, dynamic> map) =>
      LtcResourceModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        level: map['level'] ?? 'C',
        county: map['county'] ?? '',
        township: map['township'] ?? '',
        address: map['address'] ?? '',
        phone: map['phone'],
        serviceHours: map['serviceHours'],
        services: List<String>.from(map['services'] ?? []),
        lat: (map['lat'] as num?)?.toDouble(),
        lng: (map['lng'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'level': level,
    'county': county, 'township': township,
    'address': address, 'phone': phone,
    'serviceHours': serviceHours, 'services': services,
    'lat': lat, 'lng': lng,
  };

  /// 從衛福部 CSV 欄位解析（欄位順序依官方格式）
  factory LtcResourceModel.fromCsvRow(List<String> row, String id) {
    // CSV 欄位（依衛福部長期照顧服務資源資料集）:
    // 0:縣市, 1:鄉鎮市區, 2:機構名稱, 3:服務類型, 4:地址, 5:電話, 6:服務時間
    String _clean(int i) =>
        (i < row.length ? row[i].trim() : '').replaceAll('"', '');

    final serviceType = _clean(3);
    final level = serviceType.contains('A級') || serviceType.contains('旗艦')
        ? 'A'
        : serviceType.contains('B級') || serviceType.contains('複合')
            ? 'B'
            : 'C';

    return LtcResourceModel(
      id: id,
      name: _clean(2),
      level: level,
      county: _clean(0),
      township: _clean(1),
      address: _clean(4),
      phone: _clean(5).isEmpty ? null : _clean(5),
      serviceHours: _clean(6).isEmpty ? null : _clean(6),
      services: serviceType.isNotEmpty ? [serviceType] : [],
    );
  }
}
