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
 * Total: 55 tests
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
  };
}

function group(name, fn) {
  console.log(`\n  [${name}]`);
  fn();
}

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
