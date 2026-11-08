/* ==========================================================================
   Money and currencies

   Each farm records its money in its own currency, chosen from the farm's
   country on the Farms page (a Zambian farm in kwacha, a Kenyan farm in
   shillings, and so on). Everyone can choose which currency to SEE amounts
   in, using the Currency box in the top bar:

     "Farm currency"  each amount in the currency its farm records in
     USD, ZAR, ...    every amount converted to that currency

   Totals that mix farms with different currencies are shown in US dollars
   unless another currency is picked. Rates are US-dollar based, fetched
   from free public rate services and kept for 12 hours. Without internet,
   built-in approximate rates are used and the page says so.
   ========================================================================== */

export const DEFAULT_CURRENCY = 'USD';
export const LOCAL = 'LOCAL';

const PREF_KEY = 'jd_display_currency';
const RATES_KEY = 'jd_fx_rates_v1';
const MAX_AGE_MS = 12 * 60 * 60 * 1000;

/* Country (ISO 3166) -> the currency it normally uses (ISO 4217). */
const COUNTRY_CURRENCY = Object.fromEntries((
  'AD:EUR AE:AED AF:AFN AG:XCD AI:XCD AL:ALL AM:AMD AO:AOA AR:ARS AS:USD AT:EUR AU:AUD AW:AWG AX:EUR AZ:AZN ' +
  'BA:BAM BB:BBD BD:BDT BE:EUR BF:XOF BG:EUR BH:BHD BI:BIF BJ:XOF BL:EUR BM:BMD BN:BND BO:BOB BQ:USD BR:BRL ' +
  'BS:BSD BT:BTN BW:BWP BY:BYN BZ:BZD CA:CAD CC:AUD CD:CDF CF:XAF CG:XAF CH:CHF CI:XOF CK:NZD CL:CLP CM:XAF ' +
  'CN:CNY CO:COP CR:CRC CU:CUP CV:CVE CW:XCG CX:AUD CY:EUR CZ:CZK DE:EUR DJ:DJF DK:DKK DM:XCD DO:DOP DZ:DZD ' +
  'EC:USD EE:EUR EG:EGP EH:MAD ER:ERN ES:EUR ET:ETB FI:EUR FJ:FJD FK:FKP FM:USD FO:DKK FR:EUR GA:XAF GB:GBP ' +
  'GD:XCD GE:GEL GF:EUR GG:GBP GH:GHS GI:GIP GL:DKK GM:GMD GN:GNF GP:EUR GQ:XAF GR:EUR GT:GTQ GU:USD GW:XOF ' +
  'GY:GYD HK:HKD HN:HNL HR:EUR HT:HTG HU:HUF ID:IDR IE:EUR IL:ILS IM:GBP IN:INR IO:USD IQ:IQD IR:IRR IS:ISK ' +
  'IT:EUR JE:GBP JM:JMD JO:JOD JP:JPY KE:KES KG:KGS KH:KHR KI:AUD KM:KMF KN:XCD KP:KPW KR:KRW KW:KWD KY:KYD ' +
  'KZ:KZT LA:LAK LB:LBP LC:XCD LI:CHF LK:LKR LR:LRD LS:LSL LT:EUR LU:EUR LV:EUR LY:LYD MA:MAD MC:EUR MD:MDL ' +
  'ME:EUR MF:EUR MG:MGA MH:USD MK:MKD ML:XOF MM:MMK MN:MNT MO:MOP MP:USD MQ:EUR MR:MRU MS:XCD MT:EUR MU:MUR ' +
  'MV:MVR MW:MWK MX:MXN MY:MYR MZ:MZN NA:NAD NC:XPF NE:XOF NF:AUD NG:NGN NI:NIO NL:EUR NO:NOK NP:NPR NR:AUD ' +
  'NU:NZD NZ:NZD OM:OMR PA:PAB PE:PEN PF:XPF PG:PGK PH:PHP PK:PKR PL:PLN PM:EUR PN:NZD PR:USD PS:ILS PT:EUR ' +
  'PW:USD PY:PYG QA:QAR RE:EUR RO:RON RS:RSD RU:RUB RW:RWF SA:SAR SB:SBD SC:SCR SD:SDG SE:SEK SG:SGD SH:SHP ' +
  'SI:EUR SJ:NOK SK:EUR SL:SLE SM:EUR SN:XOF SO:SOS SR:SRD SS:SSP ST:STN SV:USD SX:XCG SY:SYP SZ:SZL TC:USD ' +
  'TD:XAF TF:EUR TG:XOF TH:THB TJ:TJS TK:NZD TL:USD TM:TMT TN:TND TO:TOP TR:TRY TT:TTD TV:AUD TW:TWD TZ:TZS ' +
  'UA:UAH UG:UGX UM:USD US:USD UY:UYU UZ:UZS VA:EUR VC:XCD VE:VES VG:USD VI:USD VN:VND VU:VUV WF:XPF WS:WST ' +
  'XK:EUR YE:YER YT:EUR ZA:ZAR ZM:ZMW ZW:ZWG'
).split(' ').map(p => p.split(':')));

/* Approximate units per US dollar, used only when no live rate can be
   fetched (no internet). The page labels these as approximate. */
const FALLBACK_RATES = {
  USD: 1, EUR: 0.86, GBP: 0.75, CHF: 0.80, JPY: 150, CNY: 7.1, INR: 88, AUD: 1.52, CAD: 1.39, NZD: 1.72,
  ZAR: 17.5, ZMW: 23.5, ZWG: 26.8, BWP: 13.6, NAD: 17.5, LSL: 17.5, SZL: 17.5, MWK: 1740, MZN: 63.9,
  AOA: 915, TZS: 2450, KES: 129, UGX: 3500, RWF: 1450, BIF: 2970, CDF: 2500, ETB: 150, SOS: 571,
  NGN: 1480, GHS: 11.0, XOF: 565, XAF: 565, EGP: 48, MAD: 9.2, TND: 2.95, DZD: 130, MUR: 45.5,
  MGA: 4450, SCR: 14.2, SLE: 23, LRD: 180, GMD: 72, GNF: 8680, SDG: 600, SSP: 4500, ERN: 15, DJF: 178,
  BRL: 5.4, MXN: 18.4, ARS: 1450, CLP: 950, COP: 3900, PEN: 3.45, UYU: 40, PYG: 7300, BOB: 6.91,
  AED: 3.6725, SAR: 3.75, QAR: 3.64, KWD: 0.306, BHD: 0.376, OMR: 0.385, JOD: 0.709, ILS: 3.3, TRY: 42,
  PKR: 281, BDT: 122, LKR: 300, NPR: 141, IDR: 16500, MYR: 4.2, PHP: 58, THB: 32.5, VND: 26300,
  SGD: 1.29, HKD: 7.78, KRW: 1400, TWD: 30.5, RUB: 81, UAH: 41.5, PLN: 3.65, CZK: 20.9, HUF: 335,
  RON: 4.35, SEK: 9.4, NOK: 10.0, DKK: 6.4, ISK: 122, RSD: 101, KZT: 530, UZS: 12100, GEL: 2.7,
  AMD: 385, AZN: 1.7, XCD: 2.7, JMD: 160, TTD: 6.78, DOP: 63, GTQ: 7.67, HNL: 26.2, CRC: 503, PAB: 1,
  FJD: 2.25, PGK: 4.1, XPF: 103, BND: 1.29, MOP: 8.01, MNT: 3580, KHR: 4010, LAK: 21600, MMK: 2100,
};

/* ---------------------------------------------------------------------- */
/* Names                                                                  */
/* ---------------------------------------------------------------------- */
const LANG = 'en';
let regionNames = null, currencyNames = null;
try { regionNames = new Intl.DisplayNames([LANG], { type: 'region' }); } catch (e) { /* older browser */ }
try { currencyNames = new Intl.DisplayNames([LANG], { type: 'currency' }); } catch (e) { /* older browser */ }

export function countryName(code){
  if (!code) return '';
  try { return (regionNames && regionNames.of(code)) || code; } catch (e) { return code; }
}
export function currencyName(code){
  if (!code) return '';
  try { return (currencyNames && currencyNames.of(code)) || code; } catch (e) { return code; }
}
export function currencyForCountry(country){
  return COUNTRY_CURRENCY[String(country || '').toUpperCase()] || '';
}

/** Options for the farm form's Country box, sorted by name. */
export function countryOptions(){
  return Object.keys(COUNTRY_CURRENCY)
    .map(c => ({ value: c, label: countryName(c) }))
    .sort((a, b) => a.label.localeCompare(b.label));
}

/** Every currency we know about: those used by a country plus any the rate service lists. */
function knownCurrencies(){
  const set = new Set(Object.values(COUNTRY_CURRENCY));
  Object.keys(rates()).forEach(c => { if (/^[A-Z]{3}$/.test(c)) set.add(c); });
  return [...set].filter(c => { try { return !!new Intl.NumberFormat(LANG, { style: 'currency', currency: c }); } catch (e) { return false; } });
}

/** Options for a currency box: "ZMW · Zambian Kwacha", sorted by code. */
export function currencyOptions(){
  return knownCurrencies().sort().map(c => ({ value: c, label: `${c} · ${currencyName(c)}` }));
}

/* ---------------------------------------------------------------------- */
/* Exchange rates                                                         */
/* ---------------------------------------------------------------------- */
let state = readCachedRates() || { rates: FALLBACK_RATES, source: 'built-in', updated: null, approx: true, fetchedAt: 0 };

function readCachedRates(){
  try {
    const s = JSON.parse(localStorage.getItem(RATES_KEY) || 'null');
    if (s && s.rates && s.rates.USD) return { ...s, rates: { ...FALLBACK_RATES, ...s.rates } };
  } catch (e) { /* storage blocked or corrupt */ }
  return null;
}
function saveRates(s){
  try { localStorage.setItem(RATES_KEY, JSON.stringify(s)); } catch (e) { /* storage blocked */ }
}

function rates(){ return state.rates; }

async function fetchJson(url, ms = 6000){
  const ctl = typeof AbortController !== 'undefined' ? new AbortController() : null;
  const timer = ctl ? setTimeout(() => ctl.abort(), ms) : null;
  try {
    const res = await fetch(url, { signal: ctl ? ctl.signal : undefined, cache: 'no-store' });
    if (!res.ok) throw new Error('HTTP ' + res.status);
    return await res.json();
  } finally {
    if (timer) clearTimeout(timer);
  }
}

/* Free, key-less, US-dollar based sources, tried in order. */
const SOURCES = [
  {
    name: 'ExchangeRate-API',
    link: 'https://www.exchangerate-api.com',
    url: 'https://open.er-api.com/v6/latest/USD',
    parse: d => d && d.result === 'success' && d.rates
      ? { rates: d.rates, updated: d.time_last_update_unix ? new Date(d.time_last_update_unix * 1000).toISOString() : null }
      : null,
  },
  {
    name: 'Currency API',
    link: 'https://github.com/fawazahmed0/exchange-api',
    url: 'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.json',
    parse: d => d && d.usd
      ? { rates: Object.fromEntries(Object.entries(d.usd).map(([k, v]) => [k.toUpperCase(), v])), updated: d.date ? d.date + 'T00:00:00Z' : null }
      : null,
  },
];

let loading = null;
/** Loads today's rates (cached for 12 hours). Resolves when done; never throws. */
export function loadRates(force = false){
  if (!force && state.fetchedAt && Date.now() - state.fetchedAt < MAX_AGE_MS) return Promise.resolve(state);
  if (loading) return loading;
  loading = (async () => {
    for (const src of SOURCES){
      try {
        const parsed = src.parse(await fetchJson(src.url));
        if (parsed && Number(parsed.rates.USD) === 1){
          const clean = {};
          Object.entries(parsed.rates).forEach(([k, v]) => { const x = Number(v); if (/^[A-Z]{3}$/.test(k) && x > 0) clean[k] = x; });
          state = { rates: { ...FALLBACK_RATES, ...clean }, source: src.name, link: src.link, updated: parsed.updated, approx: false, fetchedAt: Date.now() };
          saveRates({ ...state, rates: clean });
          return state;
        }
      } catch (e) { /* try the next source */ }
    }
    return state;   // keep whatever we had (cached or built-in)
  })().finally(() => { loading = null; });
  return loading;
}

/** Waits for rates at most `ms` milliseconds, so a slow network never holds up the page. */
export function ratesReady(ms = 3500){
  return Promise.race([loadRates(), new Promise(r => setTimeout(r, ms))]);
}

export function ratesInfo(){
  return { source: state.source, link: state.link || null, updated: state.updated, approx: !!state.approx };
}

/** Units of `code` per US dollar, or null if unknown. */
export function rateOf(code){
  const r = rates()[String(code || '').toUpperCase()];
  return r > 0 ? r : null;
}

/** Converts an amount between currencies. Returns null when a rate is missing. */
export function convert(amount, from, to){
  const v = Number(amount);
  if (!Number.isFinite(v)) return null;
  from = (from || DEFAULT_CURRENCY).toUpperCase(); to = (to || DEFAULT_CURRENCY).toUpperCase();
  if (from === to) return v;
  const a = rateOf(from), b = rateOf(to);
  if (!a || !b) return null;
  return v / a * b;
}

/* ---------------------------------------------------------------------- */
/* Formatting                                                             */
/* ---------------------------------------------------------------------- */
const fmtCache = {};
/** "ZMW 1,234.50" / "$1,234.50". `digits` fixes the decimals (default 2). */
export function formatMoney(amount, code, digits = 2){
  const v = Number(amount);
  if (amount === null || amount === undefined || amount === '' || !Number.isFinite(v)) return '—';
  code = (code || DEFAULT_CURRENCY).toUpperCase();
  const key = code + '|' + digits;
  try {
    if (!fmtCache[key]) fmtCache[key] = new Intl.NumberFormat(undefined, { style: 'currency', currency: code, minimumFractionDigits: digits, maximumFractionDigits: digits });
    return fmtCache[key].format(v);
  } catch (e) {
    return `${code} ${v.toLocaleString(undefined, { minimumFractionDigits: digits, maximumFractionDigits: digits })}`;
  }
}

/* ---------------------------------------------------------------------- */
/* Farms and the person's display choice                                  */
/* ---------------------------------------------------------------------- */
let farmCur = new Map();   // farm id -> currency code

/** Call with the farms this person can see, whenever they are (re)loaded. */
export function setFarms(farms){
  farmCur = new Map((farms || []).map(f => [String(f.id ?? f.farm_id), String(f.currency_code || DEFAULT_CURRENCY).toUpperCase()]));
}
export function farmCurrency(farmId){
  return farmCur.get(String(farmId)) || sharedCurrency() || DEFAULT_CURRENCY;
}
/** The single currency all known farms use, or null when they differ. */
export function sharedCurrency(farmIds = null){
  const codes = new Set(farmIds ? farmIds.map(id => farmCur.get(String(id)) || DEFAULT_CURRENCY) : farmCur.values());
  return codes.size === 1 ? [...codes][0] : (codes.size === 0 ? DEFAULT_CURRENCY : null);
}

export function getDisplay(){
  try {
    const v = localStorage.getItem(PREF_KEY);
    if (v === LOCAL || /^[A-Z]{3}$/.test(v || '')) return v;
  } catch (e) { /* storage blocked */ }
  return LOCAL;
}
export function setDisplay(code){
  try { localStorage.setItem(PREF_KEY, code); } catch (e) { /* storage blocked */ }
}

/** Currency used for a total over amounts recorded in `codes`. */
export function totalCurrency(codes){
  const pref = getDisplay();
  if (pref !== LOCAL) return pref;
  const set = new Set([...codes].filter(Boolean));
  return set.size === 1 ? [...set][0] : (set.size === 0 ? (sharedCurrency() || DEFAULT_CURRENCY) : DEFAULT_CURRENCY);
}

/* ---------------------------------------------------------------------- */
/* Which farm (and so which currency) a record's money belongs to         */
/* ---------------------------------------------------------------------- */
const FARM_LINK = {
  farms: 'self',
  fields: 'farm_id', livestock: 'farm_id', machinery: 'farm_id', inventory_items: 'farm_id',
  employees: 'farm_id', task_allocations: 'farm_id', purchase_orders: 'farm_id', sales_orders: 'farm_id',
  financial_transactions: 'farm_id', livestock_production_logs: 'farm_id', warehouses: 'farm_id',
  machinery_maintenance: ['machinery_id', 'machinery'],
  machinery_usage: ['machinery_id', 'machinery'],
  livestock_health_records: ['animal_id', 'livestock'],
  inventory_batches: ['item_id', 'inventory_items'],
  irrigation_systems: ['field_id', 'fields'],
  irrigation_schedules: ['system_id', 'irrigation_systems'],
  labor_assignments: ['task_id', 'task_allocations'],
  sales_order_items: ['order_id', 'sales_orders'],
};

/** Farm id for a record, following parent links with getRec(entity, id). */
export function farmOfRow(entity, row, getRec, depth = 0){
  const link = FARM_LINK[entity];
  if (!link || !row || depth > 4) return null;
  if (link === 'self') return row.id ?? null;
  if (typeof link === 'string') return has(row[link]) ? row[link] : null;
  const [fk, parent] = link;
  if (!has(row[fk])) return null;
  const p = getRec(parent, row[fk]);
  return p ? farmOfRow(parent, p, getRec, depth + 1) : null;
}

/** Currency a record's money was recorded in. */
export function rowCurrency(entity, row, getRec){
  const farm = farmOfRow(entity, row, getRec);
  return farm !== null && farm !== undefined ? farmCurrency(farm) : (sharedCurrency() || DEFAULT_CURRENCY);
}

function has(v){ return v !== null && v !== undefined && v !== ''; }

/* ---------------------------------------------------------------------- */
/* A one-line note saying which currency is shown and where rates are from */
/* ---------------------------------------------------------------------- */
export function ratesNoteHtml(fromCodes, to){
  const froms = [...new Set([...fromCodes].filter(c => c && c !== to))];
  if (!froms.length) return '';
  const info = ratesInfo();
  const pairs = froms.slice(0, 4).map(c => {
    const r = convert(1, DEFAULT_CURRENCY, c), t = convert(1, DEFAULT_CURRENCY, to);
    if (!r || !t) return `${c} (no rate)`;
    return to === DEFAULT_CURRENCY ? `1 USD = ${trim(r)} ${c}` : `1 ${to} = ${trim(r / t)} ${c}`;
  }).join(', ');
  const when = info.updated ? new Date(info.updated).toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' }) : '';
  const src = info.approx
    ? 'approximate built-in rates, because live rates could not be loaded'
    : `rates from <a href="${info.link}" target="_blank" rel="noopener">${info.source}</a>${when ? `, ${when}` : ''}`;
  return `<p class="fx-note">Amounts shown in ${to}, converted at ${pairs} (${src}).</p>`;
}
function trim(v){
  return Number(v).toLocaleString(undefined, { maximumFractionDigits: v >= 100 ? 0 : v >= 1 ? 2 : 4 });
}
