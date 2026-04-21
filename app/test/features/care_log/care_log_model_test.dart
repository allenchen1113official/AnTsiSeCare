import 'package:flutter_test/flutter_test.dart';

// 只測試純 Dart 邏輯，不依賴 Firebase
// 直接複製相關 enum / class 邏輯進行隔離測試

// ── 複製必要的枚舉與類別（避免 Firebase 依賴）────────────────────────────

enum CareItemStatus { normal, abnormal, done, skipped, refused, partial }

extension CareItemStatusExt on CareItemStatus {
  bool get isAbnormal => this == CareItemStatus.abnormal;
  bool get isDone =>
      this == CareItemStatus.done || this == CareItemStatus.normal;

  static CareItemStatus fromString(String? s) =>
      CareItemStatus.values.firstWhere(
        (e) => e.name == s,
        orElse: () => CareItemStatus.skipped,
      );
}

class CareItems {
  final CareItemStatus? feeding, medication, excretion, bathing,
      exercise, sleep, mood, wound;

  const CareItems({
    this.feeding, this.medication, this.excretion, this.bathing,
    this.exercise, this.sleep, this.mood, this.wound,
  });

  bool get hasAnyAbnormal => [
        feeding, medication, excretion, bathing, exercise, sleep, mood, wound,
      ].any((s) => s?.isAbnormal == true);
}

class Vitals {
  final double? systolicBP, diastolicBP, bloodSugar, temperature,
      heartRate, oxygenSat;

  const Vitals({
    this.systolicBP, this.diastolicBP, this.bloodSugar,
    this.temperature, this.heartRate, this.oxygenSat,
  });

  bool get hasAnyAbnormal {
    if (systolicBP != null && (systolicBP! > 140 || systolicBP! < 90)) return true;
    if (bloodSugar != null && (bloodSugar! > 180 || bloodSugar! < 70)) return true;
    if (temperature != null && (temperature! > 37.5 || temperature! < 36.0)) return true;
    if (heartRate != null && (heartRate! > 100 || heartRate! < 60)) return true;
    if (oxygenSat != null && oxygenSat! < 95) return true;
    return false;
  }
}

// ── 測試 ──────────────────────────────────────────────────────────────────────

void main() {
  group('CareItemStatus', () {
    test('正常狀態不算異常', () {
      expect(CareItemStatus.normal.isAbnormal, false);
      expect(CareItemStatus.done.isAbnormal, false);
      expect(CareItemStatus.skipped.isAbnormal, false);
    });

    test('abnormal 狀態為真異常', () {
      expect(CareItemStatus.abnormal.isAbnormal, true);
    });

    test('fromString 解析已知值', () {
      expect(CareItemStatusExt.fromString('normal'), CareItemStatus.normal);
      expect(CareItemStatusExt.fromString('abnormal'), CareItemStatus.abnormal);
      expect(CareItemStatusExt.fromString('done'), CareItemStatus.done);
    });

    test('fromString 未知值 fallback to skipped', () {
      expect(CareItemStatusExt.fromString(null), CareItemStatus.skipped);
      expect(CareItemStatusExt.fromString('unknown'), CareItemStatus.skipped);
      expect(CareItemStatusExt.fromString(''), CareItemStatus.skipped);
    });
  });

  group('CareItems.hasAnyAbnormal', () {
    test('全部正常 → false', () {
      const items = CareItems(
        feeding: CareItemStatus.normal,
        medication: CareItemStatus.done,
        excretion: CareItemStatus.normal,
      );
      expect(items.hasAnyAbnormal, false);
    });

    test('飲食異常 → true', () {
      const items = CareItems(feeding: CareItemStatus.abnormal);
      expect(items.hasAnyAbnormal, true);
    });

    test('多項正常其中一項異常 → true', () {
      const items = CareItems(
        feeding: CareItemStatus.normal,
        medication: CareItemStatus.done,
        excretion: CareItemStatus.abnormal,
        sleep: CareItemStatus.normal,
      );
      expect(items.hasAnyAbnormal, true);
    });

    test('全部 null → false', () {
      const items = CareItems();
      expect(items.hasAnyAbnormal, false);
    });

    test('skipped 不算異常', () {
      const items = CareItems(
        feeding: CareItemStatus.skipped,
        bathing: CareItemStatus.refused,
      );
      expect(items.hasAnyAbnormal, false);
    });
  });

  group('Vitals.hasAnyAbnormal', () {
    test('血壓正常 → false', () {
      const v = Vitals(systolicBP: 120, diastolicBP: 80);
      expect(v.hasAnyAbnormal, false);
    });

    test('血壓偏高 > 140 → true', () {
      const v = Vitals(systolicBP: 155, diastolicBP: 95);
      expect(v.hasAnyAbnormal, true);
    });

    test('血壓偏低 < 90 → true', () {
      const v = Vitals(systolicBP: 85, diastolicBP: 60);
      expect(v.hasAnyAbnormal, true);
    });

    test('血糖正常（空腹 80）→ false', () {
      const v = Vitals(bloodSugar: 80);
      expect(v.hasAnyAbnormal, false);
    });

    test('血糖過高 > 180 → true', () {
      const v = Vitals(bloodSugar: 220);
      expect(v.hasAnyAbnormal, true);
    });

    test('血糖過低 < 70 → true（低血糖）', () {
      const v = Vitals(bloodSugar: 55);
      expect(v.hasAnyAbnormal, true);
    });

    test('體溫偏高 37.8°C → true', () {
      const v = Vitals(temperature: 37.8);
      expect(v.hasAnyAbnormal, true);
    });

    test('體溫正常 36.5°C → false', () {
      const v = Vitals(temperature: 36.5);
      expect(v.hasAnyAbnormal, false);
    });

    test('血氧 SpO2 94% < 95 → true', () {
      const v = Vitals(oxygenSat: 94);
      expect(v.hasAnyAbnormal, true);
    });

    test('血氧 SpO2 98% → false', () {
      const v = Vitals(oxygenSat: 98);
      expect(v.hasAnyAbnormal, false);
    });

    test('心率過快 > 100 → true', () {
      const v = Vitals(heartRate: 115);
      expect(v.hasAnyAbnormal, true);
    });

    test('心率正常 72 → false', () {
      const v = Vitals(heartRate: 72);
      expect(v.hasAnyAbnormal, false);
    });

    test('全部 null → false', () {
      const v = Vitals();
      expect(v.hasAnyAbnormal, false);
    });

    test('邊界值：血壓 140（臨界正常）→ false', () {
      const v = Vitals(systolicBP: 140);
      expect(v.hasAnyAbnormal, false);
    });

    test('邊界值：血壓 141（臨界異常）→ true', () {
      const v = Vitals(systolicBP: 141);
      expect(v.hasAnyAbnormal, true);
    });
  });
}
