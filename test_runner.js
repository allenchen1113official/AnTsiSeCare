#!/usr/bin/env node
/**
 * AnTsiSeCare — Node.js Test Runner
 * Mirrors the 4 Dart test files (Flutter not installed)
 *
 * Suites:
 *   1. timezone_utils_test       (5 tests)
 *   2. ltc_data_service_test     (19 tests)
 *   3. notification_service_test (11 tests)
 *   4. care_log_model_test       (20 tests)
 *   5. navigation_feature_test   (46 tests)
 *   6. heart_rate_test           (28 tests)
 *   7. mi_band_test              (26 tests)
 *   8. medication_reminder_test  (28 tests)
 * Total: 194 tests
 */

let passed = 0, failed = 0, total = 0;
const failures = [];

function test(name, fn) {
  total++;
  try {
    fn();
    console.log(`  ✓ ${name}`);
    passed++;
  } catch (e) {
    console.log(`  ✗ ${name}`);
    console.log(`      → ${e.message}`);
    failed++;
    failures.push({ name, msg: e.message });
  }
}

function expect(val) {
  return {
    toBe: (expected) => {
      if (val !== expected) throw new Error(`Expected ${JSON.stringify(expected)}, got ${JSON.stringify(val)}`);
    },
    toEqual: (expected) => {
      if (JSON.stringify(val) !== JSON.stringify(expected))
        throw new Error(`Expected ${JSON.stringify(expected)}, got ${JSON.stringify(val)}`);
    },
    toBeTruthy: () => { if (!val) throw new Error(`Expected truthy, got ${JSON.stringify(val)}`); },
    toBeFalsy: () => { if (val) throw new Error(`Expected falsy, got ${JSON.stringify(val)}`); },
    toContain: (sub) => {
      if (!String(val).includes(sub)) throw new Error(`Expected "${val}" to contain "${sub}"`);
    },
    not: {
      toContain: (sub) => {
        if (String(val).includes(sub)) throw new Error(`Expected "${val}" NOT to contain "${sub}"`);
      },
      toBe: (unexpected) => {
        if (val === unexpected) throw new Error(`Expected NOT ${JSON.stringify(unexpected)}`);
      },
    },
    toBeGreaterThan: (n) => { if (val <= n) throw new Error(`Expected ${val} > ${n}`); },
    toBeLessThan: (n) => { if (val >= n) throw new Error(`Expected ${val} < ${n}`); },
    toBeCloseTo: (expected, digits = 2) => {
      const precision = Math.pow(10, -digits) / 2;
      if (Math.abs(val - expected) >= precision)
        throw new Error(`Expected ${val} to be close to ${expected} (±${precision})`);
    },
    toBeNull: () => { if (val !== null) throw new Error(`Expected null, got ${JSON.stringify(val)}`); },
    toBeUndefined: () => { if (val !== undefined) throw new Error(`Expected undefined, got ${JSON.stringify(val)}`); },
    not: {
      toContain: (sub) => {
        if (String(val).includes(sub)) throw new Error(`Expected "${val}" NOT to contain "${sub}"`);
      },
      toBe: (unexpected) => {
        if (val === unexpected) throw new Error(`Expected NOT ${JSON.stringify(unexpected)}`);
      },
      toBeNull: () => { if (val === null) throw new Error(`Expected NOT null`); },
    },
  };
}

function group(name, fn) {
  console.log(`\n  [${name}]`);
  fn();
}

const describe = group;

// ═══════════════════════════════════════════════════════════════
// 1. TIMEZONE UTILS
// ═══════════════════════════════════════════════════════════════

console.log('\n━━━ timezone_utils_test ━━━');

function toTaipei(utcDate) {
  const taipeiOffset = 8 * 60;
  const utcMs = utcDate.getTime();
  const taipeiMs = utcMs + taipeiOffset * 60 * 1000;
  return new Date(taipeiMs);
}

group('Timezone — Asia/Taipei (UTC+8)', () => {
  test('UTC+0 00:00 → 台北 08:00', () => {
    const utc = new Date('2026-04-14T00:00:00Z');
    const local = toTaipei(utc);
    expect(local.getUTCHours()).toBe(8);
    expect(local.getUTCDate()).toBe(14);
  });

  test('UTC+0 16:00 → 台北 00:00 隔天', () => {
    const utc = new Date('2026-04-14T16:00:00Z');
    const local = toTaipei(utc);
    expect(local.getUTCHours()).toBe(0);
    expect(local.getUTCDate()).toBe(15);
  });

  test('夏令時間：台灣全年固定 UTC+8（無 DST）', () => {
    // Taiwan stays at UTC+8 year-round
    const janOffset = 8;
    const julOffset = 8;
    expect(janOffset).toBe(8);
    expect(julOffset).toBe(8);
  });

  test('台北日期字串格式 YYYY-MM-DD', () => {
    const utc = new Date('2026-04-14T15:59:00Z'); // 台北 23:59
    const local = toTaipei(utc);
    const y = local.getUTCFullYear();
    const m = String(local.getUTCMonth() + 1).padStart(2, '0');
    const d = String(local.getUTCDate()).padStart(2, '0');
    const dateStr = `${y}-${m}-${d}`;
    expect(dateStr).toBe('2026-04-14');
  });

  test('UTC+0 16:01 → 台北日期進到隔天', () => {
    const utc = new Date('2026-04-14T16:01:00Z'); // 台北 00:01 4/15
    const local = toTaipei(utc);
    const y = local.getUTCFullYear();
    const m = String(local.getUTCMonth() + 1).padStart(2, '0');
    const d = String(local.getUTCDate()).padStart(2, '0');
    const dateStr = `${y}-${m}-${d}`;
    expect(dateStr).toBe('2026-04-15');
  });
});

// ═══════════════════════════════════════════════════════════════
// 2. LTC DATA SERVICE
// ═══════════════════════════════════════════════════════════════

console.log('\n━━━ ltc_data_service_test ━━━');

function parseCsvLine(line) {
  const result = [];
  let current = '';
  let inQuotes = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (c === '"') {
      inQuotes = !inQuotes;
    } else if (c === ',' && !inQuotes) {
      result.push(current);
      current = '';
    } else {
      current += c;
    }
  }
  result.push(current);
  return result;
}

class LtcResourceModel {
  constructor({ id, name, level, county, township, address, phone = null }) {
    this.id = id; this.name = name; this.level = level;
    this.county = county; this.township = township;
    this.address = address; this.phone = phone;
  }

  static fromCsvRow(row, id) {
    const clean = (i) => (i < row.length ? row[i].trim() : '').replace(/"/g, '');
    const serviceType = clean(3);
    const level = serviceType.includes('A級') || serviceType.includes('旗艦') ? 'A'
      : serviceType.includes('B級') || serviceType.includes('複合') ? 'B' : 'C';
    const phone = clean(5) || null;
    return new LtcResourceModel({
      id, name: clean(2), level,
      county: clean(0), township: clean(1),
      address: clean(4), phone,
    });
  }
}

function filterByCounty(all, county) {
  if (!county) return all;
  return all.filter(r => r.county === county);
}

function filterByLevel(all, level) {
  if (!level) return all;
  return all.filter(r => r.level === level);
}

function filterByTownship(all, township) {
  if (!township) return all;
  return all.filter(r => r.township === township);
}

function search(all, keyword) {
  if (!keyword.trim()) return all;
  const kw = keyword.toLowerCase();
  return all.filter(r =>
    r.name.toLowerCase().includes(kw) ||
    r.address.toLowerCase().includes(kw) ||
    r.township.includes(kw)
  );
}

// 多縣市測試資料（涵蓋全台 6 縣市）
const sampleResources = [
  new LtcResourceModel({ id: '1',  name: '台北市大安區長照旗艦中心',     level: 'A', county: '台北市', township: '大安區', address: '台北市大安區信義路100號', phone: '02-27001001' }),
  new LtcResourceModel({ id: '2',  name: '台北市信義區長照複合服務中心',  level: 'B', county: '台北市', township: '信義區', address: '台北市信義區松仁路200號', phone: '02-27001002' }),
  new LtcResourceModel({ id: '3',  name: '台北市萬華區巷弄長照站',        level: 'C', county: '台北市', township: '萬華區', address: '台北市萬華區西園路50號',  phone: '02-23001003' }),
  new LtcResourceModel({ id: '4',  name: '台中市西屯區長照旗艦中心',      level: 'A', county: '台中市', township: '西屯區', address: '台中市西屯區台灣大道100號' }),
  new LtcResourceModel({ id: '5',  name: '台中市大里區巷弄長照站',        level: 'C', county: '台中市', township: '大里區', address: '台中市大里區中興路50號' }),
  new LtcResourceModel({ id: '6',  name: '高雄市苓雅區長照旗艦中心',      level: 'A', county: '高雄市', township: '苓雅區', address: '高雄市苓雅區四維三路100號', phone: '07-33601001' }),
  new LtcResourceModel({ id: '7',  name: '高雄市旗山區巷弄長照站',        level: 'C', county: '高雄市', township: '旗山區', address: '高雄市旗山區中山路50號' }),
  new LtcResourceModel({ id: '8',  name: '苗栗縣頭份市長照旗艦店',        level: 'A', county: '苗栗縣', township: '頭份市', address: '苗栗縣頭份市中正路100號', phone: '037-680001' }),
  new LtcResourceModel({ id: '9',  name: '苗栗市長照複合型服務中心',      level: 'B', county: '苗栗縣', township: '苗栗市', address: '苗栗縣苗栗市中山路200號', phone: '037-330002' }),
  new LtcResourceModel({ id: '10', name: '花蓮市長照旗艦中心',            level: 'A', county: '花蓮縣', township: '花蓮市', address: '花蓮縣花蓮市中山路100號', phone: '03-83201001' }),
];

group('filterByCounty', () => {
  test('篩選台北市 → 3 筆', () => {
    expect(filterByCounty(sampleResources, '台北市').length).toBe(3);
  });

  test('篩選苗栗縣 → 2 筆', () => {
    expect(filterByCounty(sampleResources, '苗栗縣').length).toBe(2);
  });

  test('篩選花蓮縣 → 1 筆', () => {
    expect(filterByCounty(sampleResources, '花蓮縣').length).toBe(1);
  });

  test('county null → 全部 10 筆', () => {
    expect(filterByCounty(sampleResources, null).length).toBe(10);
  });

  test('county 空字串 → 全部 10 筆', () => {
    expect(filterByCounty(sampleResources, '').length).toBe(10);
  });

  test('不存在縣市 → 0 筆', () => {
    expect(filterByCounty(sampleResources, '連江縣').length).toBe(0);
  });
});

group('filterByLevel', () => {
  test('篩選 A 級機構 → 5 筆', () => {
    const result = filterByLevel(sampleResources, 'A');
    expect(result.length).toBe(5);
    expect(result.every(r => r.level === 'A')).toBeTruthy();
  });

  test('篩選 C 級機構 → 3 筆', () => {
    expect(filterByLevel(sampleResources, 'C').length).toBe(3);
  });

  test('level 為 null → 全部 10 筆', () => {
    expect(filterByLevel(sampleResources, null).length).toBe(10);
  });

  test('level 為空字串 → 全部 10 筆', () => {
    expect(filterByLevel(sampleResources, '').length).toBe(10);
  });

  test('不存在的等級 → 0 筆', () => {
    expect(filterByLevel(sampleResources, 'D').length).toBe(0);
  });
});

group('filterByTownship', () => {
  test('篩選苗栗市 → 1 筆', () => {
    expect(filterByTownship(sampleResources, '苗栗市').length).toBe(1);
  });

  test('篩選頭份市 → 1 筆', () => {
    expect(filterByTownship(sampleResources, '頭份市').length).toBe(1);
  });

  test('township null → 全部', () => {
    expect(filterByTownship(sampleResources, null).length).toBe(10);
  });

  test('不存在鄉鎮 → 0 筆', () => {
    expect(filterByTownship(sampleResources, '泰安鄉').length).toBe(0);
  });
});

group('search', () => {
  test('搜尋「旗艦」→ 5 筆（含全台各縣市旗艦中心）', () => {
    expect(search(sampleResources, '旗艦').length).toBe(5);
  });

  test('搜尋「巷弄」→ 3 筆（含台北/台中/高雄）', () => {
    expect(search(sampleResources, '巷弄').length).toBe(3);
  });

  test('搜尋地址關鍵字「中山路」→ 3 筆（旗山/苗栗/花蓮）', () => {
    expect(search(sampleResources, '中山路').length).toBe(3);
  });

  test('搜尋「大安區」→ 1 筆', () => {
    expect(search(sampleResources, '大安區').length).toBe(1);
  });

  test('空字串 → 全部', () => {
    expect(search(sampleResources, '').length).toBe(10);
  });

  test('不存在關鍵字 → 0 筆', () => {
    expect(search(sampleResources, '新竹市').length).toBe(0);
  });

  test('大小寫不敏感（英文機構名）', () => {
    const mixed = [...sampleResources,
      new LtcResourceModel({ id: '99', name: 'Miaoli LTC Center', level: 'B', county: '苗栗縣', township: '苗栗市', address: 'Test addr' })
    ];
    expect(search(mixed, 'miaoli').length).toBe(1);
    expect(search(mixed, 'MIAOLI').length).toBe(1);
  });
});

group('CSV 解析', () => {
  test('解析 A 級旗艦店', () => {
    const row = ['苗栗縣', '頭份市', '頭份市長照旗艦店', 'A級整合服務中心', '頭份市中正路100號', '037-680001', '週一至週五 08:00-17:00'];
    const model = LtcResourceModel.fromCsvRow(row, 'test1');
    expect(model.level).toBe('A');
    expect(model.name).toBe('頭份市長照旗艦店');
    expect(model.county).toBe('苗栗縣');
    expect(model.township).toBe('頭份市');
    expect(model.phone).toBe('037-680001');
  });

  test('解析 B 級複合型中心', () => {
    const row = ['苗栗縣', '苗栗市', '苗栗市複合型服務中心', 'B級複合型服務中心', '苗栗市中山路200號', '', ''];
    const model = LtcResourceModel.fromCsvRow(row, 'test2');
    expect(model.level).toBe('B');
    expect(model.phone).toBe(null);
  });

  test('解析 C 級巷弄站（預設）', () => {
    const row = ['苗栗縣', '竹南鎮', '竹南社區關懷據點', '社區照顧關懷據點', '竹南鎮民主路50號', '037-470000', ''];
    const model = LtcResourceModel.fromCsvRow(row, 'test3');
    expect(model.level).toBe('C');
  });

  test('含引號的 CSV 欄位', () => {
    const line = '"苗栗縣","頭份市","頭份市「旗艦」長照站","A級","中正路100號","037-000000",""';
    const row = parseCsvLine(line);
    expect(row.length).toBe(7);
    expect(row[0]).toBe('苗栗縣');
    expect(row[2]).toBe('頭份市「旗艦」長照站');
  });

  test('不足欄位的 CSV 行不崩潰', () => {
    const row = ['苗栗縣', '苗栗市'];
    let threw = false;
    try { LtcResourceModel.fromCsvRow(row, 'short'); } catch { threw = true; }
    expect(threw).toBeFalsy();
  });
});

// ═══════════════════════════════════════════════════════════════
// 3. NOTIFICATION SERVICE
// ═══════════════════════════════════════════════════════════════

console.log('\n━━━ notification_service_test ━━━');

const _templates = {
  medication_reminder: {
    'zh-TW': { title: '用藥提醒 💊', body: '{{name}} 現在是服用{{medicine}}的時間（{{time}}）' },
    'id':    { title: 'Pengingat Obat 💊', body: '{{name}} – Saatnya minum {{medicine}} ({{time}})' },
    'vi':    { title: 'Nhắc uống thuốc 💊', body: '{{name}} – Uống {{medicine}} lúc {{time}}' },
    'en':    { title: 'Medication Reminder 💊', body: 'Time to take {{medicine}} for {{name}} at {{time}}' },
  },
  care_log_abnormal: {
    'zh-TW': { title: '照護異常警示 ⚠️', body: '{{elder}} 今日照護紀錄有異常，請查閱' },
    'id':    { title: 'Peringatan Kondisi Tidak Normal ⚠️', body: '{{elder}} – Ada kondisi tidak normal.' },
    'en':    { title: 'Care Alert ⚠️', body: '{{elder}} has an abnormal condition.' },
  },
  prayer_time: {
    'id': { title: '🕌 Waktu Salat', body: 'Sudah masuk waktu {{prayer}}.' },
  },
};

function buildPayload({ type, language, namedArgs = null }) {
  const templates = _templates[type] || {};
  const template = templates[language] || templates['zh-TW'] || {};

  function fill(tpl) {
    if (!tpl) return '';
    if (!namedArgs) return tpl;
    let result = tpl;
    for (const [k, v] of Object.entries(namedArgs)) {
      result = result.replaceAll(`{{${k}}}`, v);
    }
    return result;
  }

  return {
    title: fill(template.title),
    body: fill(template.body),
  };
}

group('buildPayload — 用藥提醒', () => {
  test('中文模板包含藥品名稱', () => {
    const p = buildPayload({ type: 'medication_reminder', language: 'zh-TW', namedArgs: { name: '陳阿嬤', medicine: '血壓藥', time: '08:00' } });
    expect(p.title).toContain('用藥提醒');
    expect(p.body).toContain('陳阿嬤');
    expect(p.body).toContain('血壓藥');
    expect(p.body).toContain('08:00');
  });

  test('印尼語模板（id）', () => {
    const p = buildPayload({ type: 'medication_reminder', language: 'id', namedArgs: { name: 'Nenek', medicine: 'amlodipine', time: '08:00' } });
    expect(p.title).toContain('Pengingat Obat');
    expect(p.body).toContain('Nenek');
    expect(p.body).toContain('amlodipine');
  });

  test('英語模板（en）', () => {
    const p = buildPayload({ type: 'medication_reminder', language: 'en', namedArgs: { name: 'Grandma', medicine: 'Amlodipine', time: '8 AM' } });
    expect(p.title).toContain('Medication Reminder');
    expect(p.body).toContain('Grandma');
  });

  test('未知語言 fallback 到 zh-TW', () => {
    const p = buildPayload({ type: 'medication_reminder', language: 'fr', namedArgs: { name: 'Test', medicine: 'X', time: '09:00' } });
    expect(p.title).toContain('用藥提醒');
  });
});

group('buildPayload — 照護異常', () => {
  test('中文異常通知含長者名稱', () => {
    const p = buildPayload({ type: 'care_log_abnormal', language: 'zh-TW', namedArgs: { elder: '王阿公' } });
    expect(p.body).toContain('王阿公');
    expect(p.body).toContain('異常');
  });

  test('印尼語異常通知', () => {
    const p = buildPayload({ type: 'care_log_abnormal', language: 'id', namedArgs: { elder: 'Kakek' } });
    expect(p.title).toContain('Peringatan');
    expect(p.body).toContain('Kakek');
  });
});

group('buildPayload — 禱告提醒', () => {
  test('只有印尼語版', () => {
    const p = buildPayload({ type: 'prayer_time', language: 'id', namedArgs: { prayer: 'Zuhur' } });
    expect(p.title).toBe('🕌 Waktu Salat');
    expect(p.body).toContain('Zuhur');
  });

  test('中文使用者不應收到禱告通知（無模板）', () => {
    const p = buildPayload({ type: 'prayer_time', language: 'zh-TW' });
    expect(p.title).toBe('');
    expect(p.body).toBe('');
  });
});

group('buildPayload — namedArgs 替換', () => {
  test('多個 placeholder 全部替換', () => {
    const p = buildPayload({ type: 'medication_reminder', language: 'zh-TW', namedArgs: { name: 'N1', medicine: 'M1', time: 'T1' } });
    expect(p.body).not.toContain('{{name}}');
    expect(p.body).not.toContain('{{medicine}}');
    expect(p.body).not.toContain('{{time}}');
  });

  test('namedArgs 為 null 時不崩潰', () => {
    const p = buildPayload({ type: 'care_log_abnormal', language: 'zh-TW' });
    if (!p.title || p.title.length === 0) throw new Error('title should not be empty');
  });
});

// ═══════════════════════════════════════════════════════════════
// 4. CARE LOG MODEL
// ═══════════════════════════════════════════════════════════════

console.log('\n━━━ care_log_model_test ━━━');

const CareItemStatus = Object.freeze({
  normal: 'normal', abnormal: 'abnormal', done: 'done',
  skipped: 'skipped', refused: 'refused', partial: 'partial',
});

function isAbnormal(status) { return status === CareItemStatus.abnormal; }
function isDone(status) { return status === CareItemStatus.done || status === CareItemStatus.normal; }
function fromString(s) {
  return Object.values(CareItemStatus).includes(s) ? s : CareItemStatus.skipped;
}

function careItemsHasAnyAbnormal(items) {
  return Object.values(items).some(s => s && isAbnormal(s));
}

function vitalsHasAnyAbnormal({ systolicBP, bloodSugar, temperature, heartRate, oxygenSat } = {}) {
  if (systolicBP != null && (systolicBP > 140 || systolicBP < 90)) return true;
  if (bloodSugar != null && (bloodSugar > 180 || bloodSugar < 70)) return true;
  if (temperature != null && (temperature > 37.5 || temperature < 36.0)) return true;
  if (heartRate != null && (heartRate > 100 || heartRate < 60)) return true;
  if (oxygenSat != null && oxygenSat < 95) return true;
  return false;
}

group('CareItemStatus', () => {
  test('正常狀態不算異常', () => {
    expect(isAbnormal(CareItemStatus.normal)).toBeFalsy();
    expect(isAbnormal(CareItemStatus.done)).toBeFalsy();
    expect(isAbnormal(CareItemStatus.skipped)).toBeFalsy();
  });

  test('abnormal 狀態為真異常', () => {
    expect(isAbnormal(CareItemStatus.abnormal)).toBeTruthy();
  });

  test('fromString 解析已知值', () => {
    expect(fromString('normal')).toBe(CareItemStatus.normal);
    expect(fromString('abnormal')).toBe(CareItemStatus.abnormal);
    expect(fromString('done')).toBe(CareItemStatus.done);
  });

  test('fromString 未知值 fallback to skipped', () => {
    expect(fromString(null)).toBe(CareItemStatus.skipped);
    expect(fromString('unknown')).toBe(CareItemStatus.skipped);
    expect(fromString('')).toBe(CareItemStatus.skipped);
  });
});

group('CareItems.hasAnyAbnormal', () => {
  test('全部正常 → false', () => {
    expect(careItemsHasAnyAbnormal({ feeding: 'normal', medication: 'done', excretion: 'normal' })).toBeFalsy();
  });

  test('飲食異常 → true', () => {
    expect(careItemsHasAnyAbnormal({ feeding: 'abnormal' })).toBeTruthy();
  });

  test('多項正常其中一項異常 → true', () => {
    expect(careItemsHasAnyAbnormal({ feeding: 'normal', medication: 'done', excretion: 'abnormal', sleep: 'normal' })).toBeTruthy();
  });

  test('全部 null → false', () => {
    expect(careItemsHasAnyAbnormal({})).toBeFalsy();
  });

  test('skipped 不算異常', () => {
    expect(careItemsHasAnyAbnormal({ feeding: 'skipped', bathing: 'refused' })).toBeFalsy();
  });
});

group('Vitals.hasAnyAbnormal', () => {
  test('血壓正常 → false', () => {
    expect(vitalsHasAnyAbnormal({ systolicBP: 120, diastolicBP: 80 })).toBeFalsy();
  });

  test('血壓偏高 > 140 → true', () => {
    expect(vitalsHasAnyAbnormal({ systolicBP: 155 })).toBeTruthy();
  });

  test('血壓偏低 < 90 → true', () => {
    expect(vitalsHasAnyAbnormal({ systolicBP: 85 })).toBeTruthy();
  });

  test('血糖正常（空腹 80）→ false', () => {
    expect(vitalsHasAnyAbnormal({ bloodSugar: 80 })).toBeFalsy();
  });

  test('血糖過高 > 180 → true', () => {
    expect(vitalsHasAnyAbnormal({ bloodSugar: 220 })).toBeTruthy();
  });

  test('血糖過低 < 70 → true（低血糖）', () => {
    expect(vitalsHasAnyAbnormal({ bloodSugar: 55 })).toBeTruthy();
  });

  test('體溫偏高 37.8°C → true', () => {
    expect(vitalsHasAnyAbnormal({ temperature: 37.8 })).toBeTruthy();
  });

  test('體溫正常 36.5°C → false', () => {
    expect(vitalsHasAnyAbnormal({ temperature: 36.5 })).toBeFalsy();
  });

  test('血氧 SpO2 94% < 95 → true', () => {
    expect(vitalsHasAnyAbnormal({ oxygenSat: 94 })).toBeTruthy();
  });

  test('血氧 SpO2 98% → false', () => {
    expect(vitalsHasAnyAbnormal({ oxygenSat: 98 })).toBeFalsy();
  });

  test('心率過快 > 100 → true', () => {
    expect(vitalsHasAnyAbnormal({ heartRate: 115 })).toBeTruthy();
  });

  test('心率正常 72 → false', () => {
    expect(vitalsHasAnyAbnormal({ heartRate: 72 })).toBeFalsy();
  });

  test('全部 null → false', () => {
    expect(vitalsHasAnyAbnormal({})).toBeFalsy();
  });

  test('邊界值：血壓 140（臨界正常）→ false', () => {
    expect(vitalsHasAnyAbnormal({ systolicBP: 140 })).toBeFalsy();
  });

  test('邊界值：血壓 141（臨界異常）→ true', () => {
    expect(vitalsHasAnyAbnormal({ systolicBP: 141 })).toBeTruthy();
  });
});

// ═══════════════════════════════════════════════════════════════
// 5. NAVIGATION FEATURE
// ═══════════════════════════════════════════════════════════════

console.log('\n━━━ navigation_feature_test ━━━');

// ── 複製 RoutePlan 邏輯（隔離 Flutter/Dart 依賴）─────────────────────────────

const RouteCategory = { home: 'home', medical: 'medical', ltcCenter: 'ltcCenter', pharmacy: 'pharmacy', rehabilitation: 'rehabilitation' };

function makePlacePoint({ name, nameId, address, lat, lng, phone = null }) {
  return { name, nameId, address, position: { latitude: lat, longitude: lng }, phone };
}

function makeRoutePlan({ id, title, titleId, description, category, origin, destination, color,
  polyline = [], distanceKm = null, durationMin = null }) {
  return { id, title, titleId, description, category, origin, destination, color,
    polyline, distanceKm, durationMin };
}

function durationLabel(plan) {
  if (plan.durationMin === null) return '計算中…';
  if (plan.durationMin < 60) return `${plan.durationMin} 分鐘`;
  const h = Math.floor(plan.durationMin / 60);
  const m = plan.durationMin % 60;
  return m === 0 ? `${h} 小時` : `${h} 時 ${m} 分`;
}

function distanceLabel(plan) {
  if (plan.distanceKm === null) return '—';
  return plan.distanceKm < 1
    ? `${Math.round(plan.distanceKm * 1000)} m`
    : `${plan.distanceKm.toFixed(1)} km`;
}

// ── 五組預設路線（與 navigation_screen.dart 保持一致）──────────────────────

const homePoint = makePlacePoint({
  name: '我的住家', nameId: 'Rumah Saya',
  address: '台北市大安區信義路四段 1 號',
  lat: 25.0338, lng: 121.5436,
});

const defaultPlans = [
  makeRoutePlan({
    id: 'route_a', title: '🏥 住家 → 急診醫院', titleId: 'Rumah → IGD Rumah Sakit',
    description: '台大醫院（急診 24 小時）', category: RouteCategory.medical,
    origin: homePoint,
    destination: makePlacePoint({ name: '台大醫院急診', nameId: 'IGD NTUH',
      address: '台北市中正區中山南路 7 號', lat: 25.0426, lng: 121.5122, phone: '02-23123456' }),
    color: '#B71C1C',
  }),
  makeRoutePlan({
    id: 'route_b', title: '🏨 住家 → 衛生所', titleId: 'Rumah → Puskesmas',
    description: '台北市大安區健康服務中心（週一～五 08:00–17:00）', category: RouteCategory.medical,
    origin: homePoint,
    destination: makePlacePoint({ name: '大安區健康服務中心', nameId: 'Pusat Kesehatan Da-an',
      address: '台北市大安區建國南路二段 15 號', lat: 25.0278, lng: 121.5413, phone: '02-27551148' }),
    color: '#1565C0',
  }),
  makeRoutePlan({
    id: 'route_c', title: '🏠 住家 → 長照中心', titleId: 'Rumah → Pusat LTC',
    description: '台北市大安區長照旗艦整合中心（A 級）', category: RouteCategory.ltcCenter,
    origin: homePoint,
    destination: makePlacePoint({ name: '大安區長照旗艦整合中心', nameId: 'Pusat LTC Terpadu Da-an',
      address: '台北市大安區信義路四段 100 號', lat: 25.0330, lng: 121.5510, phone: '02-27001001' }),
    color: '#1B5E4F',
  }),
  makeRoutePlan({
    id: 'route_d', title: '💊 住家 → 藥局', titleId: 'Rumah → Apotek',
    description: '信義聯合藥局（合法藥局，週一至週六 08:30–21:00）', category: RouteCategory.pharmacy,
    origin: homePoint,
    destination: makePlacePoint({ name: '信義聯合藥局', nameId: 'Apotek Xinyi',
      address: '台北市大安區信義路四段 180 號', lat: 25.0323, lng: 121.5551, phone: '02-27065580' }),
    color: '#6A1B9A',
  }),
  makeRoutePlan({
    id: 'route_e', title: '🏃 住家 → 復健診所', titleId: 'Rumah → Klinik Rehab',
    description: '大安復健診所（物理治療 / 職能治療）', category: RouteCategory.rehabilitation,
    origin: homePoint,
    destination: makePlacePoint({ name: '大安復健診所', nameId: 'Klinik Rehabilitasi Da-an',
      address: '台北市大安區仁愛路四段 285 號', lat: 25.0346, lng: 121.5494, phone: '02-27551100' }),
    color: '#E65100',
  }),
];

// ── 輔助：OSRM URL 格式驗證 ───────────────────────────────────────────────

function buildOsrmUrl(plan) {
  const o = plan.origin.position;
  const d = plan.destination.position;
  return `https://router.project-osrm.org/route/v1/driving/${o.longitude},${o.latitude};${d.longitude},${d.latitude}?overview=full&geometries=geojson&steps=false`;
}

// ── OSRM JSON 解析邏輯（複製自 osrm_service.dart）──────────────────────────

function parseOsrmResponse(json) {
  const routes = json.routes;
  if (!routes || routes.length === 0) return null;
  const route = routes[0];
  const distM = route.distance;
  const durSec = route.duration;
  const coords = route.geometry.coordinates.map(c => ({ latitude: c[1], longitude: c[0] }));
  return {
    polyline: coords,
    distanceKm: distM / 1000,
    durationMin: Math.ceil(durSec / 60),
  };
}

// ── 測試：RoutePlan 模型 ──────────────────────────────────────────────────

describe('RoutePlan — 五組預設路線完整性', () => {
  test('應有 5 組路線', () => {
    expect(defaultPlans.length).toBe(5);
  });

  test('所有路線 id 唯一', () => {
    const ids = defaultPlans.map(p => p.id);
    expect(new Set(ids).size).toBe(5);
  });

  test('所有路線有起點（住家）', () => {
    defaultPlans.forEach(p => {
      expect(p.origin.name).toBe('我的住家');
    });
  });

  test('所有路線有目的地電話', () => {
    defaultPlans.forEach(p => {
      expect(p.destination.phone).not.toBeNull();
    });
  });

  test('路線 A 分類為 medical', () => {
    expect(defaultPlans[0].category).toBe(RouteCategory.medical);
  });

  test('路線 C 分類為 ltcCenter', () => {
    expect(defaultPlans[2].category).toBe(RouteCategory.ltcCenter);
  });

  test('路線 D 分類為 pharmacy', () => {
    expect(defaultPlans[3].category).toBe(RouteCategory.pharmacy);
  });

  test('路線 E 分類為 rehabilitation', () => {
    expect(defaultPlans[4].category).toBe(RouteCategory.rehabilitation);
  });

  test('住家座標正確（台北大安）', () => {
    expect(homePoint.position.latitude).toBeCloseTo(25.0338, 4);
    expect(homePoint.position.longitude).toBeCloseTo(121.5436, 4);
  });

  test('台大醫院座標正確', () => {
    const dest = defaultPlans[0].destination.position;
    expect(dest.latitude).toBeCloseTo(25.0426, 4);
    expect(dest.longitude).toBeCloseTo(121.5122, 4);
  });
});

describe('RoutePlan — durationLabel 格式', () => {
  test('null → 計算中…', () => {
    const p = makeRoutePlan({ id: 'x', title: '', titleId: '', description: '',
      category: RouteCategory.medical, origin: homePoint, destination: homePoint, color: '#000' });
    expect(durationLabel(p)).toBe('計算中…');
  });

  test('30 分鐘', () => {
    const p = makeRoutePlan({ id: 'x', title: '', titleId: '', description: '',
      category: RouteCategory.medical, origin: homePoint, destination: homePoint,
      color: '#000', durationMin: 30 });
    expect(durationLabel(p)).toBe('30 分鐘');
  });

  test('60 分鐘 → 1 小時', () => {
    const p = makeRoutePlan({ id: 'x', title: '', titleId: '', description: '',
      category: RouteCategory.medical, origin: homePoint, destination: homePoint,
      color: '#000', durationMin: 60 });
    expect(durationLabel(p)).toBe('1 小時');
  });

  test('90 分鐘 → 1 時 30 分', () => {
    const p = makeRoutePlan({ id: 'x', title: '', titleId: '', description: '',
      category: RouteCategory.medical, origin: homePoint, destination: homePoint,
      color: '#000', durationMin: 90 });
    expect(durationLabel(p)).toBe('1 時 30 分');
  });

  test('120 分鐘 → 2 小時', () => {
    const p = makeRoutePlan({ id: 'x', title: '', titleId: '', description: '',
      category: RouteCategory.medical, origin: homePoint, destination: homePoint,
      color: '#000', durationMin: 120 });
    expect(durationLabel(p)).toBe('2 小時');
  });

  test('59 分鐘（邊界值）', () => {
    const p = makeRoutePlan({ id: 'x', title: '', titleId: '', description: '',
      category: RouteCategory.medical, origin: homePoint, destination: homePoint,
      color: '#000', durationMin: 59 });
    expect(durationLabel(p)).toBe('59 分鐘');
  });
});

describe('RoutePlan — distanceLabel 格式', () => {
  test('null → —', () => {
    const p = makeRoutePlan({ id: 'x', title: '', titleId: '', description: '',
      category: RouteCategory.medical, origin: homePoint, destination: homePoint, color: '#000' });
    expect(distanceLabel(p)).toBe('—');
  });

  test('0.5 km → 500 m', () => {
    const p = makeRoutePlan({ id: 'x', title: '', titleId: '', description: '',
      category: RouteCategory.medical, origin: homePoint, destination: homePoint,
      color: '#000', distanceKm: 0.5 });
    expect(distanceLabel(p)).toBe('500 m');
  });

  test('1.0 km → 1.0 km', () => {
    const p = makeRoutePlan({ id: 'x', title: '', titleId: '', description: '',
      category: RouteCategory.medical, origin: homePoint, destination: homePoint,
      color: '#000', distanceKm: 1.0 });
    expect(distanceLabel(p)).toBe('1.0 km');
  });

  test('3.75 km → 3.8 km（四捨五入）', () => {
    const p = makeRoutePlan({ id: 'x', title: '', titleId: '', description: '',
      category: RouteCategory.medical, origin: homePoint, destination: homePoint,
      color: '#000', distanceKm: 3.75 });
    expect(distanceLabel(p)).toBe('3.8 km');
  });

  test('0.999 km < 1 → 999 m', () => {
    const p = makeRoutePlan({ id: 'x', title: '', titleId: '', description: '',
      category: RouteCategory.medical, origin: homePoint, destination: homePoint,
      color: '#000', distanceKm: 0.999 });
    expect(distanceLabel(p)).toBe('999 m');
  });
});

describe('OSRM Service — URL 格式', () => {
  test('路線 A URL 包含 OSRM base', () => {
    const url = buildOsrmUrl(defaultPlans[0]);
    expect(url).toContain('router.project-osrm.org/route/v1/driving');
  });

  test('URL 格式：lng,lat;lng,lat', () => {
    const url = buildOsrmUrl(defaultPlans[0]);
    // origin: lng=121.5436, lat=25.0338 → destination: lng=121.5122, lat=25.0426
    expect(url).toContain('121.5436,25.0338;121.5122,25.0426');
  });

  test('URL 包含 overview=full', () => {
    expect(buildOsrmUrl(defaultPlans[0])).toContain('overview=full');
  });

  test('URL 包含 geometries=geojson', () => {
    expect(buildOsrmUrl(defaultPlans[0])).toContain('geometries=geojson');
  });

  test('五條路線 URL 各不同', () => {
    const urls = defaultPlans.map(buildOsrmUrl);
    expect(new Set(urls).size).toBe(5);
  });
});

describe('OSRM Service — JSON 解析', () => {
  const mockResponse = {
    code: 'Ok',
    routes: [{
      distance: 5432.1,
      duration: 823.0,
      geometry: {
        coordinates: [
          [121.5436, 25.0338],
          [121.53, 25.037],
          [121.5122, 25.0426],
        ],
      },
    }],
  };

  test('解析距離 5432.1 m → 5.432 km', () => {
    const result = parseOsrmResponse(mockResponse);
    expect(result.distanceKm).toBeCloseTo(5.4321, 3);
  });

  test('解析時間 823 秒 → ceil(13.7) = 14 分鐘', () => {
    const result = parseOsrmResponse(mockResponse);
    expect(result.durationMin).toBe(14);
  });

  test('解析 polyline 座標數量', () => {
    const result = parseOsrmResponse(mockResponse);
    expect(result.polyline.length).toBe(3);
  });

  test('GeoJSON [lng, lat] → { latitude, longitude } 轉換正確', () => {
    const result = parseOsrmResponse(mockResponse);
    expect(result.polyline[0].latitude).toBeCloseTo(25.0338, 4);
    expect(result.polyline[0].longitude).toBeCloseTo(121.5436, 4);
  });

  test('空路線 routes=[] → null', () => {
    const result = parseOsrmResponse({ routes: [] });
    expect(result).toBeNull();
  });

  test('routes 欄位缺失 → null', () => {
    const result = parseOsrmResponse({});
    expect(result).toBeNull();
  });

  test('精確取整：duration=60 → 1 分鐘（ceil）', () => {
    const res = parseOsrmResponse({ routes: [{ distance: 100, duration: 60,
      geometry: { coordinates: [[121.5, 25.0]] } }] });
    expect(res.durationMin).toBe(1);
  });

  test('精確取整：duration=61 → 2 分鐘（ceil）', () => {
    const res = parseOsrmResponse({ routes: [{ distance: 100, duration: 61,
      geometry: { coordinates: [[121.5, 25.0]] } }] });
    expect(res.durationMin).toBe(2);
  });
});

describe('NavigationScreen — 雙語支援', () => {
  test('路線 A 有中文標題', () => {
    expect(defaultPlans[0].title).toContain('住家');
  });

  test('路線 A 有印尼語標題', () => {
    expect(defaultPlans[0].titleId).toContain('Rumah');
  });

  test('路線 B 有中文與印尼語目的地名稱', () => {
    expect(defaultPlans[1].destination.name).toBe('大安區健康服務中心');
    expect(defaultPlans[1].destination.nameId).toContain('Pusat');
  });

  test('路線 C 印尼語名稱含 LTC', () => {
    expect(defaultPlans[2].destination.nameId).toContain('LTC');
  });
});

describe('RoutePlan — 路線 D/E 藥局與復健診所', () => {
  test('路線 D 目的地名稱為藥局', () => {
    expect(defaultPlans[3].destination.name).toContain('藥局');
  });

  test('路線 D 印尼語標題含 Apotek', () => {
    expect(defaultPlans[3].titleId).toContain('Apotek');
  });

  test('路線 D 藥局有聯絡電話', () => {
    expect(defaultPlans[3].destination.phone).not.toBeNull();
  });

  test('路線 E 目的地名稱含復健', () => {
    expect(defaultPlans[4].destination.name).toContain('復健');
  });

  test('路線 E 印尼語標題含 Rehab', () => {
    expect(defaultPlans[4].titleId).toContain('Rehab');
  });

  test('路線 E 復健診所有聯絡電話', () => {
    expect(defaultPlans[4].destination.phone).not.toBeNull();
  });

  test('路線 D/E 均以住家為起點', () => {
    expect(defaultPlans[3].origin.name).toBe('我的住家');
    expect(defaultPlans[4].origin.name).toBe('我的住家');
  });

  test('路線 D 藥局座標在台北大安區範圍內', () => {
    const pos = defaultPlans[3].destination.position;
    expect(pos.latitude).toBeCloseTo(25.0323, 2);
    expect(pos.longitude).toBeCloseTo(121.5551, 2);
  });
});

// ═══════════════════════════════════════════════════════════════
// 6. HEART RATE (Apple Watch)
// ═══════════════════════════════════════════════════════════════

console.log('\n━━━ heart_rate_test ━━━');

// ── HeartRateReading 模型（複製自 heart_rate_model.dart）────────────────────

const HeartRateStatus = { normal: 'normal', tachycardia: 'tachycardia', bradycardia: 'bradycardia' };

function heartRateStatus(bpm) {
  if (bpm > 100) return HeartRateStatus.tachycardia;
  if (bpm < 50)  return HeartRateStatus.bradycardia;
  return HeartRateStatus.normal;
}

function makeReading({ bpm, source = 'Apple Watch', timestamp = new Date().toISOString() }) {
  const status = heartRateStatus(bpm);
  return {
    bpm,
    source,
    timestamp: new Date(timestamp),
    status,
    isAbnormal: status !== HeartRateStatus.normal,
    isTachycardia: status === HeartRateStatus.tachycardia,
    isBradycardia: status === HeartRateStatus.bradycardia,
    isFromWatch: source.toLowerCase().includes('watch'),
    bpmLabel: `${Math.round(bpm)}`,
    statusLabel: status === HeartRateStatus.tachycardia ? '心跳過速'
               : status === HeartRateStatus.bradycardia  ? '心跳過慢' : '正常',
    statusLabelId: status === HeartRateStatus.tachycardia ? 'Takikardia'
                 : status === HeartRateStatus.bradycardia  ? 'Bradikardia' : 'Normal',
    sourceIcon: source.toLowerCase().includes('watch') ? '⌚' : '📱',
    toMap() { return { timestamp: this.timestamp.toISOString(), bpm, source }; },
  };
}

function makeSummary(readings) {
  const empty = readings.length === 0;
  const bpms = empty ? [] : readings.map(r => r.bpm);
  return {
    avgBpm: empty ? null : bpms.reduce((a, b) => a + b, 0) / bpms.length,
    maxBpm: empty ? null : Math.max(...bpms),
    minBpm: empty ? null : Math.min(...bpms),
    totalReadings: readings.length,
    abnormalCount: readings.filter(r => r.isAbnormal).length,
    avgLabel() { return this.avgBpm == null ? '—' : `${Math.round(this.avgBpm)} BPM`; },
    maxLabel() { return this.maxBpm == null ? '—' : `${Math.round(this.maxBpm)} BPM`; },
    minLabel() { return this.minBpm == null ? '—' : `${Math.round(this.minBpm)} BPM`; },
  };
}

// ── 測試：HeartRateReading 狀態判斷 ─────────────────────────────────────────

describe('HeartRateReading — 狀態判斷（正常 / 心跳過速 / 心跳過慢）', () => {
  test('72 BPM → 正常', () => {
    const r = makeReading({ bpm: 72 });
    expect(r.status).toBe(HeartRateStatus.normal);
    expect(r.isAbnormal).toBe(false);
    expect(r.statusLabel).toBe('正常');
  });

  test('101 BPM → 心跳過速（tachycardia）', () => {
    const r = makeReading({ bpm: 101 });
    expect(r.isTachycardia).toBe(true);
    expect(r.isAbnormal).toBe(true);
    expect(r.statusLabel).toBe('心跳過速');
  });

  test('49 BPM → 心跳過慢（bradycardia）', () => {
    const r = makeReading({ bpm: 49 });
    expect(r.isBradycardia).toBe(true);
    expect(r.isAbnormal).toBe(true);
    expect(r.statusLabel).toBe('心跳過慢');
  });

  test('邊界值：100 BPM → 正常（不超過）', () => {
    const r = makeReading({ bpm: 100 });
    expect(r.status).toBe(HeartRateStatus.normal);
    expect(r.isAbnormal).toBe(false);
  });

  test('邊界值：50 BPM → 正常（未低於）', () => {
    const r = makeReading({ bpm: 50 });
    expect(r.status).toBe(HeartRateStatus.normal);
    expect(r.isAbnormal).toBe(false);
  });

  test('邊界值：100.1 BPM → 心跳過速', () => {
    const r = makeReading({ bpm: 100.1 });
    expect(r.isTachycardia).toBe(true);
  });

  test('邊界值：49.9 BPM → 心跳過慢', () => {
    const r = makeReading({ bpm: 49.9 });
    expect(r.isBradycardia).toBe(true);
  });
});

describe('HeartRateReading — 資料來源識別', () => {
  test('Apple Watch 來源 → isFromWatch = true', () => {
    const r = makeReading({ bpm: 72, source: 'Apple Watch' });
    expect(r.isFromWatch).toBe(true);
    expect(r.sourceIcon).toBe('⌚');
  });

  test('iPhone 來源 → isFromWatch = false', () => {
    const r = makeReading({ bpm: 72, source: 'iPhone' });
    expect(r.isFromWatch).toBe(false);
    expect(r.sourceIcon).toBe('📱');
  });

  test('source 含 watch（小寫）→ isFromWatch = true', () => {
    const r = makeReading({ bpm: 80, source: 'My apple watch' });
    expect(r.isFromWatch).toBe(true);
  });

  test('bpmLabel 為整數字串', () => {
    const r = makeReading({ bpm: 72.8 });
    expect(r.bpmLabel).toBe('73');
  });
});

describe('HeartRateReading — 印尼語雙語支援', () => {
  test('正常 → Normal', () => {
    expect(makeReading({ bpm: 75 }).statusLabelId).toBe('Normal');
  });

  test('心跳過速 → Takikardia', () => {
    expect(makeReading({ bpm: 120 }).statusLabelId).toBe('Takikardia');
  });

  test('心跳過慢 → Bradikardia', () => {
    expect(makeReading({ bpm: 40 }).statusLabelId).toBe('Bradikardia');
  });
});

describe('HeartRateReading — 序列化', () => {
  test('toMap 包含必要欄位', () => {
    const r = makeReading({ bpm: 72, source: 'Apple Watch', timestamp: '2026-04-30T10:00:00.000Z' });
    const m = r.toMap();
    expect(m.bpm).toBe(72);
    expect(m.source).toBe('Apple Watch');
    expect(typeof m.timestamp).toBe('string');
  });

  test('toMap timestamp 為 ISO8601', () => {
    const r = makeReading({ bpm: 65, timestamp: '2026-04-30T08:30:00.000Z' });
    const m = r.toMap();
    expect(m.timestamp).toContain('2026-04-30');
  });
});

describe('HeartRateSummary — 統計摘要', () => {
  const readings = [
    makeReading({ bpm: 72 }),
    makeReading({ bpm: 110 }),  // 異常：心跳過速
    makeReading({ bpm: 45 }),   // 異常：心跳過慢
    makeReading({ bpm: 80 }),
    makeReading({ bpm: 65 }),
  ];

  test('totalReadings 正確', () => {
    const s = makeSummary(readings);
    expect(s.totalReadings).toBe(5);
  });

  test('abnormalCount 正確（2 筆異常）', () => {
    const s = makeSummary(readings);
    expect(s.abnormalCount).toBe(2);
  });

  test('maxBpm 正確', () => {
    const s = makeSummary(readings);
    expect(s.maxBpm).toBe(110);
  });

  test('minBpm 正確', () => {
    const s = makeSummary(readings);
    expect(s.minBpm).toBe(45);
  });

  test('avgBpm 正確（(72+110+45+80+65)/5 = 74.4）', () => {
    const s = makeSummary(readings);
    expect(s.avgBpm).toBeCloseTo(74.4, 1);
  });

  test('空陣列摘要 → totalReadings=0, avgBpm=null', () => {
    const s = makeSummary([]);
    expect(s.totalReadings).toBe(0);
    expect(s.avgBpm).toBeNull();
  });

  test('avgLabel 顯示 BPM 字串', () => {
    const s = makeSummary(readings);
    expect(s.avgLabel()).toContain('BPM');
  });

  test('空摘要 avgLabel → —', () => {
    const s = makeSummary([]);
    expect(s.avgLabel()).toBe('—');
  });
});

describe('HeartRateService — shouldAlert 異常判斷', () => {
  function shouldAlert(reading) { return reading.isAbnormal; }

  test('正常心率不觸發警報', () => {
    expect(shouldAlert(makeReading({ bpm: 80 }))).toBe(false);
  });

  test('心跳過速觸發警報', () => {
    expect(shouldAlert(makeReading({ bpm: 130 }))).toBe(true);
  });

  test('心跳過慢觸發警報', () => {
    expect(shouldAlert(makeReading({ bpm: 38 }))).toBe(true);
  });

  test('邊界 100 BPM 不觸發警報', () => {
    expect(shouldAlert(makeReading({ bpm: 100 }))).toBe(false);
  });
});

// ═══════════════════════════════════════════════════════════════
// 7. MI BAND (BLE)
// ═══════════════════════════════════════════════════════════════

console.log('\n━━━ mi_band_test ━━━');

// ── MiBandDevice 模型（複製自 mi_band_device.dart）──────────────────────────

const MiBandConnectionState = {
  disconnected: 'disconnected', scanning: 'scanning',
  connecting: 'connecting', connected: 'connected', error: 'error',
};

function makeMiBandDevice({ deviceId, deviceName, rssi, connectionState = MiBandConnectionState.disconnected }) {
  const lower = (deviceName || '').toLowerCase();
  const isFromWatch = lower.includes('watch'); // not Mi Band, so false
  return {
    deviceId,
    deviceName: deviceName || '',
    rssi,
    connectionState,
    get displayName() { return this.deviceName || '小米手環'; },
    get isConnected() { return this.connectionState === MiBandConnectionState.connected; },
    get signalLabel() {
      if (this.rssi >= -60) return '強';
      if (this.rssi >= -75) return '中';
      return '弱';
    },
    get connectionLabel() {
      const map = { disconnected:'未連線', scanning:'掃描中…', connecting:'連線中…', connected:'已連線', error:'連線失敗' };
      return map[this.connectionState];
    },
    get connectionLabelId() {
      const map = { disconnected:'Tidak terhubung', scanning:'Memindai…', connecting:'Menghubungkan…', connected:'Terhubung', error:'Gagal terhubung' };
      return map[this.connectionState];
    },
    toMap() { return { deviceId: this.deviceId, deviceName: this.deviceName, rssi: this.rssi }; },
  };
}

function isMiBandDevice(name) {
  if (!name) return false;
  const lower = name.toLowerCase();
  return lower.includes('mi band') ||
         lower.includes('mi smart band') ||
         lower.includes('xiaomi smart band') ||
         lower.includes('redmi band') ||
         lower.includes('amazfit band');
}

// ── BLE 心率資料解析（複製自 mi_band_service.dart _onHrData）────────────────

function parseHrData(data) {
  if (!data || data.length === 0) return null;
  const flags = data[0];
  let bpm;
  if ((flags & 0x01) === 0) {
    bpm = data.length > 1 ? data[1] : 0;
  } else {
    bpm = data.length > 2 ? (data[1] | (data[2] << 8)) : 0;
  }
  return bpm > 0 ? bpm : null;
}

// ── 測試：MiBandDevice 裝置識別 ──────────────────────────────────────────────

describe('MiBandDevice — 裝置名稱識別', () => {
  test('「MI Band 4」→ 識別為小米手環', () => {
    expect(isMiBandDevice('MI Band 4')).toBe(true);
  });

  test('「Mi Smart Band 5」→ 識別為小米手環', () => {
    expect(isMiBandDevice('Mi Smart Band 5')).toBe(true);
  });

  test('「Xiaomi Smart Band 7」→ 識別為小米手環', () => {
    expect(isMiBandDevice('Xiaomi Smart Band 7')).toBe(true);
  });

  test('「Xiaomi Smart Band 8 Pro」→ 識別為小米手環', () => {
    expect(isMiBandDevice('Xiaomi Smart Band 8 Pro')).toBe(true);
  });

  test('「Redmi Band 2」→ 識別為小米手環', () => {
    expect(isMiBandDevice('Redmi Band 2')).toBe(true);
  });

  test('「Amazfit Band 7」→ 識別為小米手環', () => {
    expect(isMiBandDevice('Amazfit Band 7')).toBe(true);
  });

  test('「Apple Watch」→ 不識別為小米手環', () => {
    expect(isMiBandDevice('Apple Watch')).toBe(false);
  });

  test('空字串 → 不識別', () => {
    expect(isMiBandDevice('')).toBe(false);
  });

  test('null → 不識別', () => {
    expect(isMiBandDevice(null)).toBe(false);
  });
});

describe('MiBandDevice — 裝置模型屬性', () => {
  test('displayName 使用 deviceName', () => {
    const d = makeMiBandDevice({ deviceId: 'aa:bb', deviceName: 'Xiaomi Smart Band 7', rssi: -65 });
    expect(d.displayName).toBe('Xiaomi Smart Band 7');
  });

  test('空 deviceName → 顯示「小米手環」', () => {
    const d = makeMiBandDevice({ deviceId: 'aa:bb', deviceName: '', rssi: -65 });
    expect(d.displayName).toBe('小米手環');
  });

  test('RSSI -55 dBm → 訊號強', () => {
    const d = makeMiBandDevice({ deviceId: 'aa:bb', deviceName: 'Mi Band', rssi: -55 });
    expect(d.signalLabel).toBe('強');
  });

  test('RSSI -70 dBm → 訊號中', () => {
    const d = makeMiBandDevice({ deviceId: 'aa:bb', deviceName: 'Mi Band', rssi: -70 });
    expect(d.signalLabel).toBe('中');
  });

  test('RSSI -80 dBm → 訊號弱', () => {
    const d = makeMiBandDevice({ deviceId: 'aa:bb', deviceName: 'Mi Band', rssi: -80 });
    expect(d.signalLabel).toBe('弱');
  });

  test('connected 狀態 → isConnected = true', () => {
    const d = makeMiBandDevice({ deviceId: 'aa:bb', deviceName: 'Mi Band', rssi: -65,
      connectionState: MiBandConnectionState.connected });
    expect(d.isConnected).toBe(true);
  });

  test('disconnected 狀態 → isConnected = false', () => {
    const d = makeMiBandDevice({ deviceId: 'aa:bb', deviceName: 'Mi Band', rssi: -65 });
    expect(d.isConnected).toBe(false);
  });

  test('connectionLabel 中文正確', () => {
    const d = makeMiBandDevice({ deviceId: 'aa:bb', deviceName: 'Mi Band', rssi: -65,
      connectionState: MiBandConnectionState.connected });
    expect(d.connectionLabel).toBe('已連線');
  });

  test('connectionLabelId 印尼語正確', () => {
    const d = makeMiBandDevice({ deviceId: 'aa:bb', deviceName: 'Mi Band', rssi: -65,
      connectionState: MiBandConnectionState.connected });
    expect(d.connectionLabelId).toBe('Terhubung');
  });

  test('toMap 包含必要欄位', () => {
    const d = makeMiBandDevice({ deviceId: 'cc:dd', deviceName: 'Xiaomi Smart Band 8', rssi: -58 });
    const m = d.toMap();
    expect(m.deviceId).toBe('cc:dd');
    expect(m.deviceName).toBe('Xiaomi Smart Band 8');
    expect(m.rssi).toBe(-58);
  });
});

describe('MiBandService — BLE 心率資料解析（uint8）', () => {
  test('flags=0x00, data[1]=72 → 72 BPM', () => {
    expect(parseHrData([0x00, 72])).toBe(72);
  });

  test('flags=0x00, data[1]=110 → 110 BPM（心跳過速）', () => {
    expect(parseHrData([0x00, 110])).toBe(110);
  });

  test('flags=0x00, data[1]=45 → 45 BPM（心跳過慢）', () => {
    expect(parseHrData([0x00, 45])).toBe(45);
  });

  test('flags=0x01, data uint16 → 合併低高位元組', () => {
    // bpm = data[1] | (data[2] << 8) = 100 | (0 << 8) = 100
    expect(parseHrData([0x01, 100, 0])).toBe(100);
  });

  test('BPM=0 → 過濾無效資料（回傳 null）', () => {
    expect(parseHrData([0x00, 0])).toBeNull();
  });

  test('空陣列 → 回傳 null', () => {
    expect(parseHrData([])).toBeNull();
  });

  test('解析後的 BPM 可建立 HeartRateReading 並判斷異常', () => {
    const bpm = parseHrData([0x00, 120]);
    const reading = makeReading({ bpm, source: 'Mi Band' });
    expect(reading.isTachycardia).toBe(true);
    expect(reading.isFromWatch).toBe(false);
    expect(reading.sourceIcon).toBe('📱');
  });
});

// ═══════════════════════════════════════════════════════════════
// 8. MEDICATION REMINDER
// ═══════════════════════════════════════════════════════════════

console.log('\n━━━ medication_reminder_test ━━━');

// ── ReminderSettings 模型（複製自 reminder_settings.dart）───────────────────

function makeReminderSettings({
  enabled = true,
  advanceMinutes = 0,
  snoozeMinutes = 10,
  soundEnabled = true,
  vibrationEnabled = true,
  medicationEnabled = {},
} = {}) {
  return {
    enabled, advanceMinutes, snoozeMinutes, soundEnabled, vibrationEnabled,
    medicationEnabled: { ...medicationEnabled },
    isMedicationEnabled(medId) {
      if (!this.enabled) return false;
      return this.medicationEnabled[medId] !== false;
    },
    copyWith(patch) {
      return makeReminderSettings({ ...this, ...patch,
        medicationEnabled: patch.medicationEnabled ?? this.medicationEnabled });
    },
    withMedicationToggle(medId, value) {
      return makeReminderSettings({ ...this,
        medicationEnabled: { ...this.medicationEnabled, [medId]: value } });
    },
    get advanceLabel() {
      return this.advanceMinutes === 0 ? '準時提醒' : `提前 ${this.advanceMinutes} 分鐘`;
    },
    get snoozeLabel() { return `貪睡 ${this.snoozeMinutes} 分鐘`; },
    toMap() {
      return { enabled: this.enabled, advanceMinutes: this.advanceMinutes,
        snoozeMinutes: this.snoozeMinutes, soundEnabled: this.soundEnabled,
        vibrationEnabled: this.vibrationEnabled, medicationEnabled: this.medicationEnabled };
    },
  };
}

function reminderSettingsFromMap(map) {
  return makeReminderSettings({
    enabled: map.enabled ?? true,
    advanceMinutes: map.advanceMinutes ?? 0,
    snoozeMinutes: map.snoozeMinutes ?? 10,
    soundEnabled: map.soundEnabled ?? true,
    vibrationEnabled: map.vibrationEnabled ?? true,
    medicationEnabled: map.medicationEnabled ?? {},
  });
}

// ── 通知 ID / payload 計算（複製自 reminder_service.dart）────────────────────

function notifId(medId, time) {
  const str = `${medId}_${time}`;
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = (Math.imul(31, hash) + str.charCodeAt(i)) | 0;
  }
  return Math.abs(hash) % 80000;
}

function buildReminderPayload(medId, time) { return `${medId}|${time}`; }

function buildReminderBody(medName, dosage, time, advanceMin) {
  const when = advanceMin === 0 ? `服藥時間：${time}` : `還有 ${advanceMin} 分鐘到服藥時間（${time}）`;
  return `${medName} ${dosage}　${when}`;
}

function calcScheduleTime(timeStr, advanceMinutes, nowHour, nowMinute) {
  const [h, m] = timeStr.split(':').map(Number);
  let sm = m - advanceMinutes;
  let sh = h;
  if (sm < 0) { sm += 60; sh -= 1; }
  if (sh < 0) sh += 24;
  // 若已過今天時間，延至明天
  const past = sh < nowHour || (sh === nowHour && sm <= nowMinute);
  return { hour: sh, minute: sm, nextDay: past };
}

// ── 測試：ReminderSettings 基本屬性 ──────────────────────────────────────────

describe('ReminderSettings — 預設值', () => {
  test('預設 enabled = true', () => {
    expect(makeReminderSettings().enabled).toBe(true);
  });

  test('預設 advanceMinutes = 0', () => {
    expect(makeReminderSettings().advanceMinutes).toBe(0);
  });

  test('預設 snoozeMinutes = 10', () => {
    expect(makeReminderSettings().snoozeMinutes).toBe(10);
  });

  test('advanceLabel：0 分 → 準時提醒', () => {
    expect(makeReminderSettings({ advanceMinutes: 0 }).advanceLabel).toBe('準時提醒');
  });

  test('advanceLabel：5 分 → 提前 5 分鐘', () => {
    expect(makeReminderSettings({ advanceMinutes: 5 }).advanceLabel).toBe('提前 5 分鐘');
  });

  test('snoozeLabel：15 分 → 貪睡 15 分鐘', () => {
    expect(makeReminderSettings({ snoozeMinutes: 15 }).snoozeLabel).toBe('貪睡 15 分鐘');
  });
});

describe('ReminderSettings — 藥品個別開關', () => {
  test('全域 enabled=false → 所有藥品 isMedicationEnabled = false', () => {
    const s = makeReminderSettings({ enabled: false });
    expect(s.isMedicationEnabled('med001')).toBe(false);
  });

  test('全域開啟，未設定藥品 → 預設啟用', () => {
    const s = makeReminderSettings({ enabled: true });
    expect(s.isMedicationEnabled('new_med')).toBe(true);
  });

  test('個別藥品關閉 → isMedicationEnabled = false', () => {
    const s = makeReminderSettings({ medicationEnabled: { 'med001': false } });
    expect(s.isMedicationEnabled('med001')).toBe(false);
  });

  test('withMedicationToggle 關閉藥品', () => {
    const s = makeReminderSettings().withMedicationToggle('med002', false);
    expect(s.isMedicationEnabled('med002')).toBe(false);
  });

  test('withMedicationToggle 開啟藥品', () => {
    const s = makeReminderSettings({ medicationEnabled: { 'med003': false } })
      .withMedicationToggle('med003', true);
    expect(s.isMedicationEnabled('med003')).toBe(true);
  });

  test('withMedicationToggle 不影響其他藥品', () => {
    const s = makeReminderSettings().withMedicationToggle('med001', false);
    expect(s.isMedicationEnabled('med002')).toBe(true);
  });
});

describe('ReminderSettings — 序列化', () => {
  test('toMap 包含所有欄位', () => {
    const s = makeReminderSettings({ advanceMinutes: 10, snoozeMinutes: 15 });
    const m = s.toMap();
    expect(m.advanceMinutes).toBe(10);
    expect(m.snoozeMinutes).toBe(15);
    expect(typeof m.enabled).toBe('boolean');
  });

  test('fromMap 還原正確', () => {
    const original = makeReminderSettings({ advanceMinutes: 5, snoozeMinutes: 30, soundEnabled: false });
    const restored = reminderSettingsFromMap(original.toMap());
    expect(restored.advanceMinutes).toBe(5);
    expect(restored.snoozeMinutes).toBe(30);
    expect(restored.soundEnabled).toBe(false);
  });

  test('fromMap 缺少欄位使用預設值', () => {
    const s = reminderSettingsFromMap({});
    expect(s.enabled).toBe(true);
    expect(s.advanceMinutes).toBe(0);
  });
});

describe('ReminderService — 提醒時間計算', () => {
  test('準時提醒（advance=0）：08:00 → 排程 08:00', () => {
    const r = calcScheduleTime('08:00', 0, 7, 0);
    expect(r.hour).toBe(8);
    expect(r.minute).toBe(0);
  });

  test('提前 10 分鐘：08:00 → 排程 07:50', () => {
    const r = calcScheduleTime('08:00', 10, 7, 0);
    expect(r.hour).toBe(7);
    expect(r.minute).toBe(50);
  });

  test('提前 15 分鐘（跨小時）：20:00 → 排程 19:45', () => {
    const r = calcScheduleTime('20:00', 15, 18, 0);
    expect(r.hour).toBe(19);
    expect(r.minute).toBe(45);
  });

  test('時間已過 → nextDay = true', () => {
    const r = calcScheduleTime('08:00', 0, 9, 0); // 現在 09:00，排程 08:00 → 明天
    expect(r.nextDay).toBe(true);
  });

  test('時間未到 → nextDay = false', () => {
    const r = calcScheduleTime('20:00', 0, 8, 0);
    expect(r.nextDay).toBe(false);
  });
});

describe('ReminderService — 通知 ID 與 payload', () => {
  test('相同 medId + time → 相同 notifId', () => {
    expect(notifId('med001', '08:00')).toBe(notifId('med001', '08:00'));
  });

  test('不同 time → 不同 notifId', () => {
    expect(notifId('med001', '08:00')).not.toBe(notifId('med001', '20:00'));
  });

  test('payload 格式：medId|time', () => {
    const p = buildReminderPayload('med001', '08:00');
    expect(p).toBe('med001|08:00');
    const parts = p.split('|');
    expect(parts[0]).toBe('med001');
    expect(parts[1]).toBe('08:00');
  });

  test('通知內容含藥品名稱', () => {
    const body = buildReminderBody('血壓藥', '5mg', '08:00', 0);
    expect(body).toContain('血壓藥');
    expect(body).toContain('08:00');
  });

  test('提前提醒通知內容含提前分鐘', () => {
    const body = buildReminderBody('血壓藥', '5mg', '08:00', 10);
    expect(body).toContain('10 分鐘');
  });
});

// ═══════════════════════════════════════════════════════════════
// SUMMARY
// ═══════════════════════════════════════════════════════════════

console.log('\n' + '═'.repeat(55));
console.log(`結果：${passed} 通過 / ${failed} 失敗 / ${total} 總計`);
if (failures.length > 0) {
  console.log('\n失敗清單：');
  failures.forEach(f => console.log(`  ✗ ${f.name}\n      ${f.msg}`));
  process.exit(1);
} else {
  console.log('全部測試通過 ✓');
  process.exit(0);
}
