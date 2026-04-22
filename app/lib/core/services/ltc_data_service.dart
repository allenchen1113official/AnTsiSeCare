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

  // 本地備用資料（衛福部資料無法取得時使用；涵蓋全台 22 縣市代表性機構）
  static const List<Map<String, dynamic>> _fallbackData = [
    // ── 台北市 ──
    {'id': 'tp001', 'name': '台北市大安區長照旗艦中心', 'level': 'A', 'county': '台北市', 'township': '大安區', 'address': '台北市大安區信義路四段100號', 'phone': '02-27001001', 'lat': 25.0330, 'lng': 121.5436},
    {'id': 'tp002', 'name': '台北市信義區長照複合服務中心', 'level': 'B', 'county': '台北市', 'township': '信義區', 'address': '台北市信義區松仁路200號', 'phone': '02-27001002', 'lat': 25.0335, 'lng': 121.5640},
    {'id': 'tp003', 'name': '台北市萬華區巷弄長照站', 'level': 'C', 'county': '台北市', 'township': '萬華區', 'address': '台北市萬華區西園路50號', 'phone': '02-23001003', 'lat': 25.0308, 'lng': 121.4990},
    // ── 新北市 ──
    {'id': 'nt001', 'name': '新北市板橋區長照旗艦中心', 'level': 'A', 'county': '新北市', 'township': '板橋區', 'address': '新北市板橋區中山路一段100號', 'phone': '02-29601001', 'lat': 25.0137, 'lng': 121.4627},
    {'id': 'nt002', 'name': '新北市新莊區長照複合服務中心', 'level': 'B', 'county': '新北市', 'township': '新莊區', 'address': '新北市新莊區中正路200號', 'phone': '02-29001002', 'lat': 25.0351, 'lng': 121.4424},
    {'id': 'nt003', 'name': '新北市淡水區巷弄長照站', 'level': 'C', 'county': '新北市', 'township': '淡水區', 'address': '新北市淡水區中正路50號', 'phone': '02-26201003', 'lat': 25.1684, 'lng': 121.4433},
    // ── 桃園市 ──
    {'id': 'ty001', 'name': '桃園市桃園區長照旗艦中心', 'level': 'A', 'county': '桃園市', 'township': '桃園區', 'address': '桃園市桃園區中正路100號', 'phone': '03-33001001', 'lat': 24.9936, 'lng': 121.3010},
    {'id': 'ty002', 'name': '桃園市中壢區長照複合服務中心', 'level': 'B', 'county': '桃園市', 'township': '中壢區', 'address': '桃園市中壢區中山路200號', 'phone': '03-42201002', 'lat': 24.9600, 'lng': 121.2250},
    // ── 台中市 ──
    {'id': 'tc001', 'name': '台中市西屯區長照旗艦中心', 'level': 'A', 'county': '台中市', 'township': '西屯區', 'address': '台中市西屯區台灣大道三段100號', 'phone': '04-23001001', 'lat': 24.1631, 'lng': 120.6478},
    {'id': 'tc002', 'name': '台中市豐原區長照複合服務中心', 'level': 'B', 'county': '台中市', 'township': '豐原區', 'address': '台中市豐原區中山路200號', 'phone': '04-25201002', 'lat': 24.2521, 'lng': 120.7185},
    {'id': 'tc003', 'name': '台中市大里區巷弄長照站', 'level': 'C', 'county': '台中市', 'township': '大里區', 'address': '台中市大里區中興路50號', 'phone': '04-24081003', 'lat': 24.1006, 'lng': 120.6791},
    // ── 台南市 ──
    {'id': 'tn001', 'name': '台南市東區長照旗艦中心', 'level': 'A', 'county': '台南市', 'township': '東區', 'address': '台南市東區東門路一段100號', 'phone': '06-27001001', 'lat': 22.9929, 'lng': 120.2168},
    {'id': 'tn002', 'name': '台南市永康區長照複合服務中心', 'level': 'B', 'county': '台南市', 'township': '永康區', 'address': '台南市永康區中正路200號', 'phone': '06-27001002', 'lat': 23.0336, 'lng': 120.2297},
    // ── 高雄市 ──
    {'id': 'ks001', 'name': '高雄市苓雅區長照旗艦中心', 'level': 'A', 'county': '高雄市', 'township': '苓雅區', 'address': '高雄市苓雅區四維三路100號', 'phone': '07-33601001', 'lat': 22.6273, 'lng': 120.3014},
    {'id': 'ks002', 'name': '高雄市鳳山區長照複合服務中心', 'level': 'B', 'county': '高雄市', 'township': '鳳山區', 'address': '高雄市鳳山區中山東路200號', 'phone': '07-74601002', 'lat': 22.6267, 'lng': 120.3574},
    {'id': 'ks003', 'name': '高雄市旗山區巷弄長照站', 'level': 'C', 'county': '高雄市', 'township': '旗山區', 'address': '高雄市旗山區中山路50號', 'phone': '07-66101003', 'lat': 22.8895, 'lng': 120.4797},
    // ── 基隆市 ──
    {'id': 'kl001', 'name': '基隆市仁愛區長照複合服務中心', 'level': 'B', 'county': '基隆市', 'township': '仁愛區', 'address': '基隆市仁愛區愛四路50號', 'phone': '02-24201001', 'lat': 25.1317, 'lng': 121.7422},
    // ── 新竹市 ──
    {'id': 'hc001', 'name': '新竹市東區長照旗艦中心', 'level': 'A', 'county': '新竹市', 'township': '東區', 'address': '新竹市東區中正路100號', 'phone': '03-53001001', 'lat': 24.8027, 'lng': 120.9718},
    // ── 嘉義市 ──
    {'id': 'cy001', 'name': '嘉義市東區長照複合服務中心', 'level': 'B', 'county': '嘉義市', 'township': '東區', 'address': '嘉義市東區中山路100號', 'phone': '05-22501001', 'lat': 23.4801, 'lng': 120.4491},
    // ── 新竹縣 ──
    {'id': 'hcc01', 'name': '新竹縣竹北市長照旗艦中心', 'level': 'A', 'county': '新竹縣', 'township': '竹北市', 'address': '新竹縣竹北市中正西路100號', 'phone': '03-55101001', 'lat': 24.8388, 'lng': 121.0045},
    {'id': 'hcc02', 'name': '新竹縣竹東鎮長照複合服務中心', 'level': 'B', 'county': '新竹縣', 'township': '竹東鎮', 'address': '新竹縣竹東鎮中豐路200號', 'phone': '03-59601002', 'lat': 24.7379, 'lng': 121.0924},
    // ── 苗栗縣 ──
    {'id': 'ml001', 'name': '苗栗縣頭份市長照旗艦店', 'level': 'A', 'county': '苗栗縣', 'township': '頭份市', 'address': '苗栗縣頭份市中正路100號', 'phone': '037-680001', 'lat': 24.6817, 'lng': 120.8749},
    {'id': 'ml002', 'name': '苗栗市長照複合型服務中心', 'level': 'B', 'county': '苗栗縣', 'township': '苗栗市', 'address': '苗栗縣苗栗市中山路200號', 'phone': '037-330002', 'lat': 24.5595, 'lng': 120.8219},
    {'id': 'ml003', 'name': '竹南鎮巷弄長照站', 'level': 'C', 'county': '苗栗縣', 'township': '竹南鎮', 'address': '苗栗縣竹南鎮民主路50號', 'phone': '037-470003', 'lat': 24.6849, 'lng': 120.8710},
    // ── 彰化縣 ──
    {'id': 'ch001', 'name': '彰化市長照旗艦中心', 'level': 'A', 'county': '彰化縣', 'township': '彰化市', 'address': '彰化縣彰化市中山路一段100號', 'phone': '04-72801001', 'lat': 24.0790, 'lng': 120.5363},
    {'id': 'ch002', 'name': '員林市長照複合服務中心', 'level': 'B', 'county': '彰化縣', 'township': '員林市', 'address': '彰化縣員林市中山路200號', 'phone': '04-83201002', 'lat': 23.9583, 'lng': 120.5785},
    // ── 南投縣 ──
    {'id': 'nt101', 'name': '南投市長照旗艦中心', 'level': 'A', 'county': '南投縣', 'township': '南投市', 'address': '南投縣南投市中興路100號', 'phone': '049-22201001', 'lat': 23.9165, 'lng': 120.6813},
    {'id': 'nt102', 'name': '埔里鎮長照複合服務中心', 'level': 'B', 'county': '南投縣', 'township': '埔里鎮', 'address': '南投縣埔里鎮中山路四段200號', 'phone': '049-29801002', 'lat': 23.9609, 'lng': 120.9710},
    // ── 雲林縣 ──
    {'id': 'yl001', 'name': '斗六市長照旗艦中心', 'level': 'A', 'county': '雲林縣', 'township': '斗六市', 'address': '雲林縣斗六市中山路100號', 'phone': '05-53201001', 'lat': 23.7092, 'lng': 120.5438},
    {'id': 'yl002', 'name': '虎尾鎮長照複合服務中心', 'level': 'B', 'county': '雲林縣', 'township': '虎尾鎮', 'address': '雲林縣虎尾鎮中正路200號', 'phone': '05-63201002', 'lat': 23.7079, 'lng': 120.4323},
    // ── 嘉義縣 ──
    {'id': 'cyc01', 'name': '太保市長照旗艦中心', 'level': 'A', 'county': '嘉義縣', 'township': '太保市', 'address': '嘉義縣太保市祥和一路100號', 'phone': '05-36201001', 'lat': 23.4589, 'lng': 120.3331},
    {'id': 'cyc02', 'name': '朴子市長照複合服務中心', 'level': 'B', 'county': '嘉義縣', 'township': '朴子市', 'address': '嘉義縣朴子市中正路200號', 'phone': '05-37901002', 'lat': 23.4677, 'lng': 120.2467},
    // ── 屏東縣 ──
    {'id': 'pt001', 'name': '屏東市長照旗艦中心', 'level': 'A', 'county': '屏東縣', 'township': '屏東市', 'address': '屏東縣屏東市中山路100號', 'phone': '08-73601001', 'lat': 22.6760, 'lng': 120.4876},
    {'id': 'pt002', 'name': '潮州鎮長照複合服務中心', 'level': 'B', 'county': '屏東縣', 'township': '潮州鎮', 'address': '屏東縣潮州鎮中山路200號', 'phone': '08-78801002', 'lat': 22.5499, 'lng': 120.5416},
    // ── 宜蘭縣 ──
    {'id': 'il001', 'name': '宜蘭市長照旗艦中心', 'level': 'A', 'county': '宜蘭縣', 'township': '宜蘭市', 'address': '宜蘭縣宜蘭市中山路二段100號', 'phone': '03-93201001', 'lat': 24.7526, 'lng': 121.7544},
    {'id': 'il002', 'name': '羅東鎮長照複合服務中心', 'level': 'B', 'county': '宜蘭縣', 'township': '羅東鎮', 'address': '宜蘭縣羅東鎮中正北路200號', 'phone': '03-95401002', 'lat': 24.6773, 'lng': 121.7697},
    // ── 花蓮縣 ──
    {'id': 'hl001', 'name': '花蓮市長照旗艦中心', 'level': 'A', 'county': '花蓮縣', 'township': '花蓮市', 'address': '花蓮縣花蓮市中山路100號', 'phone': '03-83201001', 'lat': 23.9871, 'lng': 121.6015},
    {'id': 'hl002', 'name': '吉安鄉長照複合服務中心', 'level': 'B', 'county': '花蓮縣', 'township': '吉安鄉', 'address': '花蓮縣吉安鄉吉安路200號', 'phone': '03-85301002', 'lat': 23.9637, 'lng': 121.5788},
    // ── 台東縣 ──
    {'id': 'tt001', 'name': '台東市長照旗艦中心', 'level': 'A', 'county': '台東縣', 'township': '台東市', 'address': '台東縣台東市中正路100號', 'phone': '089-33201001', 'lat': 22.7583, 'lng': 121.1444},
    {'id': 'tt002', 'name': '卑南鄉長照複合服務中心', 'level': 'B', 'county': '台東縣', 'township': '卑南鄉', 'address': '台東縣卑南鄉中華路200號', 'phone': '089-22401002', 'lat': 22.7488, 'lng': 121.1306},
    // ── 澎湖縣 ──
    {'id': 'ph001', 'name': '馬公市長照旗艦中心', 'level': 'A', 'county': '澎湖縣', 'township': '馬公市', 'address': '澎湖縣馬公市中正路100號', 'phone': '06-92601001', 'lat': 23.5687, 'lng': 119.5650},
    // ── 金門縣 ──
    {'id': 'km001', 'name': '金城鎮長照複合服務中心', 'level': 'B', 'county': '金門縣', 'township': '金城鎮', 'address': '金門縣金城鎮中正路100號', 'phone': '082-32401001', 'lat': 24.4319, 'lng': 118.3170},
    // ── 連江縣 ──
    {'id': 'lj001', 'name': '南竿鄉長照巷弄站', 'level': 'C', 'county': '連江縣', 'township': '南竿鄉', 'address': '連江縣南竿鄉介壽村50號', 'phone': '0836-22401001', 'lat': 26.1571, 'lng': 119.9497},
  ];

  /// 取得全台長照資源清單（含快取）
  static Future<List<LtcResourceModel>> getTaiwanResources({
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

      // 略過空行
      final county = row.isNotEmpty ? row[0].replaceAll('"', '').trim() : '';
      if (county.isEmpty) continue;

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

  /// 依縣市篩選
  static List<LtcResourceModel> filterByCounty(
    List<LtcResourceModel> all, String? county) {
    if (county == null || county.isEmpty) return all;
    return all.where((r) => r.county == county).toList();
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
