import 'package:flutter_test/flutter_test.dart';

// 純邏輯測試：CSV 解析、篩選、搜尋（不依賴 Firebase / Hive）

// ── 複製 LtcResourceModel（隔離 Firebase 依賴）────────────────────────────

class LtcResourceModel {
  final String id, name, level, county, township, address;
  final String? phone;

  const LtcResourceModel({
    required this.id, required this.name, required this.level,
    required this.county, required this.township, required this.address,
    this.phone,
  });

  factory LtcResourceModel.fromCsvRow(List<String> row, String id) {
    String clean(int i) =>
        (i < row.length ? row[i].trim() : '').replaceAll('"', '');

    final serviceType = clean(3);
    final level = serviceType.contains('A級') || serviceType.contains('旗艦')
        ? 'A'
        : serviceType.contains('B級') || serviceType.contains('複合')
            ? 'B'
            : 'C';

    return LtcResourceModel(
      id: id, name: clean(2), level: level,
      county: clean(0), township: clean(1),
      address: clean(4),
      phone: clean(5).isEmpty ? null : clean(5),
    );
  }
}

// ── CSV 解析輔助（複製自 LtcDataService）────────────────────────────────────

List<String> _parseCsvLine(String line) {
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

// ── 篩選函式（複製自 LtcDataService）────────────────────────────────────────

List<LtcResourceModel> filterByLevel(
    List<LtcResourceModel> all, String? level) {
  if (level == null || level.isEmpty) return all;
  return all.where((r) => r.level == level).toList();
}

List<LtcResourceModel> filterByTownship(
    List<LtcResourceModel> all, String? township) {
  if (township == null || township.isEmpty) return all;
  return all.where((r) => r.township == township).toList();
}

List<LtcResourceModel> search(
    List<LtcResourceModel> all, String keyword) {
  if (keyword.trim().isEmpty) return all;
  final kw = keyword.toLowerCase();
  return all.where((r) =>
    r.name.toLowerCase().contains(kw) ||
    r.address.toLowerCase().contains(kw) ||
    r.township.contains(kw)
  ).toList();
}

// ── 測試 ──────────────────────────────────────────────────────────────────────

void main() {
  final sampleResources = [
    const LtcResourceModel(id: '1', name: '頭份市長照旗艦店', level: 'A',
        county: '苗栗縣', township: '頭份市', address: '頭份市中正路100號', phone: '037-680001'),
    const LtcResourceModel(id: '2', name: '苗栗市複合型中心', level: 'B',
        county: '苗栗縣', township: '苗栗市', address: '苗栗市中山路200號'),
    const LtcResourceModel(id: '3', name: '竹南鎮巷弄長照站', level: 'C',
        county: '苗栗縣', township: '竹南鎮', address: '竹南鎮民主路50號'),
    const LtcResourceModel(id: '4', name: '苗栗市旗艦整合中心', level: 'A',
        county: '苗栗縣', township: '苗栗市', address: '苗栗市縣府路8號'),
    const LtcResourceModel(id: '5', name: '大湖鄉偏鄉照護站', level: 'C',
        county: '苗栗縣', township: '大湖鄉', address: '大湖鄉大湖路50號'),
  ];

  group('filterByLevel', () {
    test('篩選 A 級機構 → 2 筆', () {
      final result = filterByLevel(sampleResources, 'A');
      expect(result.length, 2);
      expect(result.every((r) => r.level == 'A'), true);
    });

    test('篩選 C 級機構 → 2 筆', () {
      final result = filterByLevel(sampleResources, 'C');
      expect(result.length, 2);
    });

    test('level 為 null → 全部 5 筆', () {
      expect(filterByLevel(sampleResources, null).length, 5);
    });

    test('level 為空字串 → 全部 5 筆', () {
      expect(filterByLevel(sampleResources, '').length, 5);
    });

    test('不存在的等級 → 0 筆', () {
      expect(filterByLevel(sampleResources, 'D').length, 0);
    });
  });

  group('filterByTownship', () {
    test('篩選苗栗市 → 2 筆', () {
      expect(filterByTownship(sampleResources, '苗栗市').length, 2);
    });

    test('篩選頭份市 → 1 筆', () {
      expect(filterByTownship(sampleResources, '頭份市').length, 1);
    });

    test('township null → 全部', () {
      expect(filterByTownship(sampleResources, null).length, 5);
    });

    test('不存在鄉鎮 → 0 筆', () {
      expect(filterByTownship(sampleResources, '泰安鄉').length, 0);
    });
  });

  group('search', () {
    test('搜尋「旗艦」→ 2 筆', () {
      expect(search(sampleResources, '旗艦').length, 2);
    });

    test('搜尋「巷弄」→ 1 筆', () {
      expect(search(sampleResources, '巷弄').length, 1);
    });

    test('搜尋地址關鍵字「中山路」→ 1 筆', () {
      expect(search(sampleResources, '中山路').length, 1);
    });

    test('搜尋鄉鎮名稱「大湖」→ 1 筆', () {
      expect(search(sampleResources, '大湖').length, 1);
    });

    test('空字串 → 全部', () {
      expect(search(sampleResources, '').length, 5);
    });

    test('不存在關鍵字 → 0 筆', () {
      expect(search(sampleResources, '新竹市').length, 0);
    });

    test('大小寫不敏感（英文機構名）', () {
      final mixed = [
        ...sampleResources,
        const LtcResourceModel(id: '99', name: 'Miaoli LTC Center', level: 'B',
            county: '苗栗縣', township: '苗栗市', address: 'Test addr'),
      ];
      expect(search(mixed, 'miaoli').length, 1);
      expect(search(mixed, 'MIAOLI').length, 1);
    });
  });

  group('CSV 解析', () {
    test('解析 A 級旗艦店', () {
      final row = ['苗栗縣', '頭份市', '頭份市長照旗艦店', 'A級整合服務中心', '頭份市中正路100號', '037-680001', '週一至週五 08:00-17:00'];
      final model = LtcResourceModel.fromCsvRow(row, 'test1');
      expect(model.level, 'A');
      expect(model.name, '頭份市長照旗艦店');
      expect(model.county, '苗栗縣');
      expect(model.township, '頭份市');
      expect(model.phone, '037-680001');
    });

    test('解析 B 級複合型中心', () {
      final row = ['苗栗縣', '苗栗市', '苗栗市複合型服務中心', 'B級複合型服務中心', '苗栗市中山路200號', '', ''];
      final model = LtcResourceModel.fromCsvRow(row, 'test2');
      expect(model.level, 'B');
      expect(model.phone, null); // 空電話 → null
    });

    test('解析 C 級巷弄站（預設）', () {
      final row = ['苗栗縣', '竹南鎮', '竹南社區關懷據點', '社區照顧關懷據點', '竹南鎮民主路50號', '037-470000', ''];
      final model = LtcResourceModel.fromCsvRow(row, 'test3');
      expect(model.level, 'C');
    });

    test('含引號的 CSV 欄位', () {
      final line = '"苗栗縣","頭份市","頭份市「旗艦」長照站","A級","中正路100號","037-000000",""';
      final row = _parseCsvLine(line);
      expect(row.length, 7);
      expect(row[0], '苗栗縣');
      expect(row[2], '頭份市「旗艦」長照站');
    });

    test('不足欄位的 CSV 行不崩潰', () {
      final row = ['苗栗縣', '苗栗市'];
      expect(() => LtcResourceModel.fromCsvRow(row, 'short'), returnsNormally);
    });
  });
}
