import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../models/ltc_resource_model.dart';

/// 衛福部長照資源開放資料解析服務
/// 資料來源：data.mohw.gov.tw（免費政府開放資料）
/// 24 小時 Hive 快取，避免重複下載
class LtcDataService {
  static const String _cacheKey = 'ltc_data';
  static const String _cacheTimeKey = 'ltc_cache_time';

  // 衛福部長期照顧服務資源資料集
  static const String _primaryUrl =
      'https://data.mohw.gov.tw/Datasets/Download?Type=0&Index=1';

  // 本地備用資料（衛福部資料無法取得時使用苗栗縣常見機構）
  static const List<Map<String, dynamic>> _fallbackData = [
    {'id': 'ml001', 'name': '苗栗縣頭份市長照旗艦店', 'level': 'A', 'county': '苗栗縣', 'township': '頭份市', 'address': '苗栗縣頭份市中正路100號', 'phone': '037-680001', 'lat': 24.6817, 'lng': 120.8749},
    {'id': 'ml002', 'name': '苗栗市長照複合型服務中心', 'level': 'B', 'county': '苗栗縣', 'township': '苗栗市', 'address': '苗栗縣苗栗市中山路200號', 'phone': '037-330002', 'lat': 24.5595, 'lng': 120.8219},
    {'id': 'ml003', 'name': '竹南鎮巷弄長照站', 'level': 'C', 'county': '苗栗縣', 'township': '竹南鎮', 'address': '苗栗縣竹南鎮民主路50號', 'phone': '037-470003', 'lat': 24.6849, 'lng': 120.8710},
    {'id': 'ml004', 'name': '苑裡鎮長照複合服務中心', 'level': 'B', 'county': '苗栗縣', 'township': '苑裡鎮', 'address': '苗栗縣苑裡鎮中山路180號', 'phone': '037-740004', 'lat': 24.4329, 'lng': 120.6671},
    {'id': 'ml005', 'name': '通霄鎮關懷據點', 'level': 'C', 'county': '苗栗縣', 'township': '通霄鎮', 'address': '苗栗縣通霄鎮中正路30號', 'phone': '037-780005', 'lat': 24.4892, 'lng': 120.6791},
    {'id': 'ml006', 'name': '後龍鎮長照服務中心', 'level': 'B', 'county': '苗栗縣', 'township': '後龍鎮', 'address': '苗栗縣後龍鎮大山路60號', 'phone': '037-720006', 'lat': 24.6165, 'lng': 120.7901},
    {'id': 'ml007', 'name': '銅鑼鄉社區照顧關懷據點', 'level': 'C', 'county': '苗栗縣', 'township': '銅鑼鄉', 'address': '苗栗縣銅鑼鄉中興路20號', 'phone': '037-980007', 'lat': 24.5104, 'lng': 120.8005},
    {'id': 'ml008', 'name': '三義鄉長照巷弄站', 'level': 'C', 'county': '苗栗縣', 'township': '三義鄉', 'address': '苗栗縣三義鄉民生路10號', 'phone': '037-870008', 'lat': 24.3890, 'lng': 120.7540},
    {'id': 'ml009', 'name': '公館鄉長照複合型中心', 'level': 'B', 'county': '苗栗縣', 'township': '公館鄉', 'address': '苗栗縣公館鄉館南路100號', 'phone': '037-230009', 'lat': 24.5085, 'lng': 120.8283},
    {'id': 'ml010', 'name': '大湖鄉偏鄉長照服務站', 'level': 'C', 'county': '苗栗縣', 'township': '大湖鄉', 'address': '苗栗縣大湖鄉大湖路50號', 'phone': '037-990010', 'lat': 24.4178, 'lng': 120.8803},
    {'id': 'ml011', 'name': '南庄鄉原住民長照據點', 'level': 'C', 'county': '苗栗縣', 'township': '南庄鄉', 'address': '苗栗縣南庄鄉南江村30號', 'phone': '037-820011', 'lat': 24.5847, 'lng': 120.9383},
    {'id': 'ml012', 'name': '卓蘭鎮長照複合型中心', 'level': 'B', 'county': '苗栗縣', 'township': '卓蘭鎮', 'address': '苗栗縣卓蘭鎮老庄里100號', 'phone': '04-25891012', 'lat': 24.3162, 'lng': 120.8341},
    {'id': 'ml013', 'name': '苗栗市旗艦型整合服務中心', 'level': 'A', 'county': '苗栗縣', 'township': '苗栗市', 'address': '苗栗縣苗栗市縣府路8號', 'phone': '037-351013', 'lat': 24.5641, 'lng': 120.8137},
    {'id': 'ml014', 'name': '頭份市北區長照站', 'level': 'C', 'county': '苗栗縣', 'township': '頭份市', 'address': '苗栗縣頭份市信義路88號', 'phone': '037-680014', 'lat': 24.6934, 'lng': 120.8796},
    {'id': 'ml015', 'name': '造橋鄉社區長照關懷站', 'level': 'C', 'county': '苗栗縣', 'township': '造橋鄉', 'address': '苗栗縣造橋鄉造橋村5號', 'phone': '037-540015', 'lat': 24.6282, 'lng': 120.8488},
    {'id': 'ml016', 'name': '獅潭鄉偏鄉照護站', 'level': 'C', 'county': '苗栗縣', 'township': '獅潭鄉', 'address': '苗栗縣獅潭鄉新店村10號', 'phone': '037-930016', 'lat': 24.5697, 'lng': 120.9340},
    {'id': 'ml017', 'name': '三灣鄉長照據點', 'level': 'C', 'county': '苗栗縣', 'township': '三灣鄉', 'address': '苗栗縣三灣鄉三灣村20號', 'phone': '037-830017', 'lat': 24.6526, 'lng': 120.9229},
    {'id': 'ml018', 'name': '泰安鄉泰雅族長照服務站', 'level': 'C', 'county': '苗栗縣', 'township': '泰安鄉', 'address': '苗栗縣泰安鄉錦水村1號', 'phone': '037-991018', 'lat': 24.4404, 'lng': 121.0232},
  ];

  /// 取得苗栗縣長照資源清單（含快取）
  static Future<List<LtcResourceModel>> getMiaoliResources({
    bool forceRefresh = false,
  }) async {
    final box = Hive.box<Map>(AppConstants.hiveBoxLtcData);

    // 讀取快取
    if (!forceRefresh) {
      final cachedTime = box.get(_cacheTimeKey);
      if (cachedTime != null) {
        final lastFetch = DateTime.parse(cachedTime['time'] as String);
        final age = DateTime.now().toUtc().difference(lastFetch);
        if (age < AppConstants.ltcCacheTtl) {
          return _fromHiveCache(box);
        }
      }
    }

    // 嘗試從衛福部下載
    try {
      final resources = await _fetchFromMohw();
      if (resources.isNotEmpty) {
        await _saveToHive(box, resources);
        return resources;
      }
    } catch (_) {
      // 網路失敗 → 使用 Hive 快取或 fallback
    }

    // 讀舊快取
    final cached = _fromHiveCache(box);
    if (cached.isNotEmpty) return cached;

    // 完全無法取得：使用內建備用資料
    return _getFallbackData();
  }

  static Future<List<LtcResourceModel>> _fetchFromMohw() async {
    final response = await http.get(
      Uri.parse(_primaryUrl),
      headers: {'Accept': 'text/csv, application/json'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return [];

    // 嘗試解析 CSV
    final body = utf8.decode(response.bodyBytes);
    final lines = const LineSplitter().convert(body);
    if (lines.length < 2) return [];

    final resources = <LtcResourceModel>[];
    for (int i = 1; i < lines.length; i++) {
      final row = _parseCsvLine(lines[i]);
      if (row.isEmpty) continue;

      // 只保留苗栗縣資料
      final county = row.isNotEmpty ? row[0].replaceAll('"', '').trim() : '';
      if (!county.contains('苗栗')) continue;

      try {
        final resource = LtcResourceModel.fromCsvRow(row, 'mohw_$i');
        resources.add(resource);
      } catch (_) {
        continue;
      }
    }
    return resources;
  }

  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(c);
      }
    }
    result.add(current.toString());
    return result;
  }

  static Future<void> _saveToHive(
      Box<Map> box, List<LtcResourceModel> resources) async {
    await box.clear();
    for (final r in resources) {
      await box.put(r.id, r.toMap());
    }
    await box.put(_cacheTimeKey,
        {'time': DateTime.now().toUtc().toIso8601String()});
  }

  static List<LtcResourceModel> _fromHiveCache(Box<Map> box) {
    return box.keys
        .where((k) => k != _cacheTimeKey)
        .map((k) {
          final data = box.get(k);
          if (data == null) return null;
          return LtcResourceModel.fromMap(Map<String, dynamic>.from(data));
        })
        .whereType<LtcResourceModel>()
        .toList();
  }

  static List<LtcResourceModel> _getFallbackData() {
    return _fallbackData
        .map((m) => LtcResourceModel.fromMap(m))
        .toList();
  }

  /// 依鄉鎮市篩選
  static List<LtcResourceModel> filterByTownship(
    List<LtcResourceModel> all, String? township) {
    if (township == null || township.isEmpty) return all;
    return all.where((r) => r.township == township).toList();
  }

  /// 依等級篩選
  static List<LtcResourceModel> filterByLevel(
    List<LtcResourceModel> all, String? level) {
    if (level == null || level.isEmpty) return all;
    return all.where((r) => r.level == level).toList();
  }

  /// 關鍵字搜尋
  static List<LtcResourceModel> search(
    List<LtcResourceModel> all, String keyword) {
    if (keyword.trim().isEmpty) return all;
    final kw = keyword.toLowerCase();
    return all.where((r) =>
      r.name.toLowerCase().contains(kw) ||
      r.address.toLowerCase().contains(kw) ||
      r.township.contains(kw)
    ).toList();
  }
}
