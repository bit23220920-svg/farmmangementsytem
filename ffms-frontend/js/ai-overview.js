/* ==========================================================================
   AI Farm Overview Analysis
   One page that reads every module's records, scores the farm's health,
   and turns the data into prioritised suggestions — crops, livestock,
   equipment, pests & diseases, inventory, tasks and profit/loss — with
   growth and finance charts.

   The analysis runs entirely in the browser from the same records the
   rest of the system already loads: rules + the knowledge base in
   ai-knowledge.js. The records API only returns the signed-in person's
   farm (administrators: the farm picked in the top bar), so the page
   never sees another farm's data. The farm assistant chat lives in
   ai-chat.js.
   ========================================================================== */
import {
  STAGES, CROP_KB, CROP_GENERIC, LIVESTOCK_KB, LIVESTOCK_GENERIC,
  EQUIPMENT_KB, EQUIPMENT_GENERIC, PEST_KB, PEST_GENERIC, SAFETY_NOTE,
  SEASON_SOUTH, SEASON_NORTH,
} from './ai-knowledge.js';
import {
  SERIES, INCOME, EXPENSE, NET, SEVERITY,
  barChart, hbarChart, lineChart, scoreRing, fmtNum,
  chartSlot, resetChartSlots, fillChartSlots,
} from './ai-charts.js';
import { getSelectedFarm } from './api.js';
import { mountFarmChat } from './ai-chat.js';
import * as Cur from './currency.js';

/* Chart helpers that draw at the container's real width (see ai-charts.js). */
const bar = (cats, series, opts = {}) => chartSlot(w => barChart(cats, series, { ...opts, width: w }));
const hbar = (items, opts = {}) => chartSlot(w => hbarChart(items, { ...opts, width: w }));
const line = (series, opts = {}) => chartSlot(w => lineChart(series, { ...opts, width: w }));

const ENTITIES_NEEDED = [
  'farms', 'fields', 'crop_varieties', 'crop_plantings', 'crop_growth_logs',
  'water_sources', 'irrigation_systems', 'irrigation_schedules',
  'livestock', 'livestock_health_records', 'livestock_production_logs', 'livestock_feed_logs',
  'inventory_items', 'inventory_batches',
  'machinery', 'machinery_maintenance', 'machinery_usage',
  'task_allocations',
  'pest_disease_catalog', 'scouting_records', 'chemical_applications',
  'weather_logs', 'harvests', 'warehouses', 'produce_storage',
  'sales_orders', 'financial_transactions',
];

const TABS = [
  { id: 'overview',  label: 'Overview' },
  { id: 'crops',     label: 'Crops & growth' },
  { id: 'livestock', label: 'Livestock' },
  { id: 'equipment', label: 'Equipment' },
  { id: 'pests',     label: 'Pest & disease control' },
  { id: 'finance',   label: 'Profit & loss' },
  { id: 'actions',   label: 'All suggestions' },
];

const SEV = {
  urgent:  { rank: 0, label: 'Urgent',  pill: 'rust' },
  soon:    { rank: 1, label: 'Soon',    pill: 'ochre' },
  routine: { rank: 2, label: 'Routine', pill: 'slate' },
  good:    { rank: 3, label: 'On track', pill: 'olive' },
};
const SEVERITY_RANK = { low: 1, moderate: 2, high: 3, severe: 4 };

/* Remembered across re-renders while the app is open. */
const state = { tab: 'overview', weather: null };

/* ---------------------------------------------------------------------- */
/* Small helpers                                                          */
/* ---------------------------------------------------------------------- */
const DAY = 864e5;
const TODAY = () => { const t = new Date(); t.setHours(0, 0, 0, 0); return t; };
function toDate(v){
  if (!v) return null;
  const s = String(v);
  const t = new Date(s.length === 10 ? s + 'T00:00:00' : s.replace(' ', 'T'));
  return isNaN(t) ? null : t;
}
const daysBetween = (a, b) => Math.round((b - a) / DAY);
const n = v => { const x = Number(v); return Number.isFinite(x) ? x : 0; };
const has = v => v !== null && v !== undefined && v !== '';
const clamp = (v, lo = 0, hi = 100) => Math.max(lo, Math.min(hi, v));
const fmtDate = d => d ? d.toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' }) : '—';
/* Money is shown in one currency per page: the farm's own, or the one picked
   in the top bar's Currency box. toDisplayCurrency() converts the records. */
let MONEY = Cur.DEFAULT_CURRENCY;
const money = v => Cur.formatMoney(v, MONEY, 0);
const monthKey = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
const monthLabel = k => { const [y, m] = k.split('-'); return new Date(+y, +m - 1, 1).toLocaleDateString(undefined, { month: 'short', year: '2-digit' }); };
function lastMonths(count){
  const out = []; const t = TODAY(); t.setDate(1);
  for (let i = count - 1; i >= 0; i--){ out.push(monthKey(new Date(t.getFullYear(), t.getMonth() - i, 1))); }
  return out;
}
function matchKb(text, kb){
  const s = ' ' + String(text || '').toLowerCase() + ' ';
  return kb.find(e => e.keys.some(k => new RegExp(`[^a-z]${k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`).test(s))) || null;
}
const by = (arr, key) => arr.reduce((m, r) => { const k = r[key]; (m[k] = m[k] || []).push(r); return m; }, {});
const latest = (arr, key) => arr.reduce((best, r) => { const d = toDate(r[key]); return d && (!best || d > toDate(best[key])) ? r : best; }, null);

/* ---------------------------------------------------------------------- */
/* Data loading + farm scoping                                            */
/* ---------------------------------------------------------------------- */
async function loadAll(fetchCached){
  const results = await Promise.allSettled(ENTITIES_NEEDED.map(e => fetchCached(e, true)));
  const D = {};
  ENTITIES_NEEDED.forEach((e, i) => {
    const r = results[i];
    D[e] = r.status === 'fulfilled' && Array.isArray(r.value) ? r.value : [];
  });
  return D;
}

/** Returns a copy of D containing only records that belong to farmId. */
function scopeTo(D, farmId){
  if (farmId === 'all') return D;
  const f = String(farmId);
  const idx = (list, fn) => Object.fromEntries(list.map(r => [String(r.id), fn(r)]));
  const fieldFarm = idx(D.fields, r => String(r.farm_id));
  const plantingFarm = idx(D.crop_plantings, r => fieldFarm[String(r.field_id)]);
  const animalFarm = idx(D.livestock, r => String(r.farm_id));
  const machineFarm = idx(D.machinery, r => String(r.farm_id));
  const itemFarm = idx(D.inventory_items, r => String(r.farm_id));
  const systemFarm = idx(D.irrigation_systems, r => fieldFarm[String(r.field_id)]);
  const warehouseFarm = idx(D.warehouses, r => String(r.farm_id));
  const direct = r => String(r.farm_id) === f;
  const via = (map, key) => r => map[String(r[key])] === f;
  return {
    ...D,
    farms: D.farms.filter(r => String(r.id) === f),
    fields: D.fields.filter(direct),
    crop_plantings: D.crop_plantings.filter(via(fieldFarm, 'field_id')),
    crop_growth_logs: D.crop_growth_logs.filter(via(plantingFarm, 'planting_id')),
    water_sources: D.water_sources.filter(direct),
    irrigation_systems: D.irrigation_systems.filter(via(fieldFarm, 'field_id')),
    irrigation_schedules: D.irrigation_schedules.filter(via(systemFarm, 'system_id')),
    livestock: D.livestock.filter(direct),
    livestock_health_records: D.livestock_health_records.filter(via(animalFarm, 'animal_id')),
    livestock_production_logs: D.livestock_production_logs.filter(direct),
    livestock_feed_logs: D.livestock_feed_logs.filter(direct),
    inventory_items: D.inventory_items.filter(direct),
    inventory_batches: D.inventory_batches.filter(via(itemFarm, 'item_id')),
    machinery: D.machinery.filter(direct),
    machinery_maintenance: D.machinery_maintenance.filter(via(machineFarm, 'machinery_id')),
    machinery_usage: D.machinery_usage.filter(via(machineFarm, 'machinery_id')),
    task_allocations: D.task_allocations.filter(direct),
    scouting_records: D.scouting_records.filter(via(fieldFarm, 'field_id')),
    chemical_applications: D.chemical_applications.filter(via(plantingFarm, 'planting_id')),
    weather_logs: D.weather_logs.filter(direct),
    harvests: D.harvests.filter(via(plantingFarm, 'planting_id')),
    warehouses: D.warehouses.filter(direct),
    produce_storage: D.produce_storage.filter(via(warehouseFarm, 'warehouse_id')),
    sales_orders: D.sales_orders.filter(direct),
    financial_transactions: D.financial_transactions.filter(direct),
  };
}

/* Money columns, converted from each record's farm currency to MONEY. */
const MONEY_FIELDS = {
  financial_transactions: ['amount'],
  sales_orders: ['total_amount'],
  machinery_maintenance: ['cost'],
  livestock_health_records: ['cost'],
  irrigation_schedules: ['electricity_cost'],
  inventory_batches: ['cost_per_unit'],
  machinery: ['purchase_price'],
};
/** Returns { D, from } with every amount in D converted to MONEY; `from` = currencies the records were in. */
function toDisplayCurrency(D, ALL){
  const index = {};
  const getRec = (entity, id) => {
    if (!index[entity]) index[entity] = new Map((ALL[entity] || []).map(r => [String(r.id), r]));
    return index[entity].get(String(id));
  };
  const from = new Set();
  const out = { ...D };
  Object.entries(MONEY_FIELDS).forEach(([entity, cols]) => {
    out[entity] = (D[entity] || []).map(r => {
      const code = Cur.rowCurrency(entity, r, getRec);
      const copy = { ...r };
      cols.forEach(c => {
        if (!has(r[c])) return;
        from.add(code);
        copy[c] = Cur.convert(r[c], code, MONEY);   // null (counted as 0) when no rate exists
      });
      return copy;
    });
  });
  return { D: out, from };
}

/* ---------------------------------------------------------------------- */
/* Analysis engine                                                        */
/* ---------------------------------------------------------------------- */
function analyse(D){
  const today = TODAY();
  const out = { suggestions: [], scores: {}, crops: {}, livestock: {}, equipment: {}, pests: {}, finance: {}, inventory: {} };
  const add = (sev, area, title, detail, actions = [], link = null) =>
    out.suggestions.push({ sev, area, title, detail, actions, link });

  const fieldById = Object.fromEntries(D.fields.map(f => [String(f.id), f]));
  const varietyById = Object.fromEntries(D.crop_varieties.map(v => [String(v.id), v]));
  const plantingById = Object.fromEntries(D.crop_plantings.map(p => [String(p.id), p]));

  /* ================= Crops ================= */
  const logsByPlanting = by(D.crop_growth_logs, 'planting_id');
  // With several farms in view, say which farm each crop is on.
  const farmName = Object.fromEntries(D.farms.map(f => [String(f.id), f.farm_name]));
  const manyFarms = D.farms.length > 1;
  const plantingLabel = p => {
    const f = fieldById[String(p.field_id)], v = varietyById[String(p.variety_id)];
    const where = f ? f.field_name + (manyFarms && farmName[String(f.farm_id)] ? ` (${farmName[String(f.farm_id)]})` : '') : 'Field #' + p.field_id;
    return `${where} · ${v ? v.crop_name + (v.variety_name ? ' (' + v.variety_name + ')' : '') : 'Planting #' + p.id}`;
  };
  const cropRows = [];
  let cropPenalty = 0;
  D.crop_plantings.forEach(p => {
    const v = varietyById[String(p.variety_id)] || {};
    const kb = matchKb(v.crop_name, CROP_KB) || CROP_GENERIC;
    const planted = toDate(p.planting_date);
    const expected = toDate(p.expected_harvest_date);
    let maturity = n(v.typical_maturity_days) || (planted && expected ? daysBetween(planted, expected) : 0) || 120;
    const elapsed = planted ? daysBetween(planted, today) : 0;
    const progress = p.status === 'harvested' ? 1 : clamp(elapsed / maturity, 0, 1.2);
    const expectedStage = progress < 0.1 ? 0 : progress < 0.55 ? 1 : progress < 0.8 ? 2 : 3;
    const logs = (logsByPlanting[p.id] || []).slice().sort((a, b) => toDate(a.log_date) - toDate(b.log_date));
    const last = logs.at(-1);
    const loggedStage = last && STAGES.indexOf(last.growth_stage) >= 0 ? STAGES.indexOf(last.growth_stage) : null;
    const harvestDate = expected || (planted ? new Date(+planted + maturity * DAY) : null);
    const daysToHarvest = harvestDate ? daysBetween(today, harvestDate) : null;
    const label = plantingLabel(p);
    const row = { p, label, crop: v.crop_name || 'Unknown crop', kb, progress, elapsed, maturity, expectedStage, loggedStage, last, logs, daysToHarvest, flags: [] };
    cropRows.push(row);

    if (p.status === 'active' || p.status === 'planned'){
      const stageName = STAGES[loggedStage ?? expectedStage];
      if (p.status === 'active'){
        add('routine', 'Crops', `${label}: ${stageName.toLowerCase()} stage care`,
          `About ${Math.round(Math.min(progress, 1) * 100)}% of the way to harvest (${elapsed} of ~${maturity} days).`,
          kb.stages[stageName] || [], '#/crop_growth_logs');
      }
      if (p.status === 'active' && (!last || daysBetween(toDate(last.log_date), today) > 14)){
        cropPenalty += 4; row.flags.push('No recent log');
        add('soon', 'Crops', `${label}: no growth log for ${last ? daysBetween(toDate(last.log_date), today) + ' days' : 'this planting yet'}`,
          'Regular logs (stage, height, health) let the system spot problems early and draw the growth chart.',
          ['Walk the field, record growth stage, average height and health status under Growth Logs.'], '#/crop_growth_logs');
      }
      if (last && /poor|bad|yellow|wilt|disease|stress|weak|sick|stunt|pest|damage|lodg|purple|chloro/i.test(String(last.health_status || '') + ' ' + String(last.remarks || ''))){
        cropPenalty += 15; row.flags.push('Health concern');
        add('urgent', 'Crops', `${label}: health concern in the last log`,
          `Last log (${fmtDate(toDate(last.log_date))}) says "${String(last.health_status || last.remarks).slice(0, 120)}".`,
          ['Scout the field and record any pest or disease under Scouting Records.',
           'Yellowing often means nitrogen shortage or waterlogging; purple leaves can mean phosphorus shortage or cold.',
           'Check soil moisture and drainage, then top-dress or treat based on what you find.'], '#/scouting_records');
      }
      if (p.status === 'active' && loggedStage !== null && loggedStage < expectedStage){
        cropPenalty += 8; row.flags.push('Behind schedule');
        add('soon', 'Crops', `${label}: may be behind schedule`,
          `Logged at ${STAGES[loggedStage]} but at day ${elapsed} it would normally be around ${STAGES[expectedStage]}.`,
          ['Check for water stress, nutrient deficiency or pest damage.', 'Update the growth log if the crop has moved on.'], '#/crop_growth_logs');
      }
      if (p.status === 'active' && daysToHarvest !== null && daysToHarvest < 0){
        cropPenalty += 5; row.flags.push('Harvest overdue');
        add('soon', 'Crops', `${label}: harvest is ${-daysToHarvest} days past the expected date`,
          'Crops left too long lose weight and quality, and face more pest and weather damage.',
          ['Harvest as soon as moisture allows, or update the expected harvest date.', 'Record the harvest and set the planting status to harvested.'], '#/harvests');
      } else if (p.status === 'active' && daysToHarvest !== null && daysToHarvest <= 21){
        add('soon', 'Crops', `${label}: harvest due in about ${daysToHarvest} days`,
          'Get ready now so nothing is lost at harvest.',
          ['Book labour and machinery; service the harvester or sheller.', 'Check warehouse space, bags and grain protectants.', ...(kb.stages.Maturity || [])], '#/harvests');
      }
      // density vs optimum
      if (n(p.planting_density_per_ha) && n(v.optimal_density_per_ha)){
        const dev = (n(p.planting_density_per_ha) - n(v.optimal_density_per_ha)) / n(v.optimal_density_per_ha);
        if (Math.abs(dev) > 0.2){
          add('routine', 'Crops', `${label}: plant density ${dev > 0 ? 'above' : 'below'} the optimum`,
            `${fmtNum(p.planting_density_per_ha)} plants/ha vs about ${fmtNum(v.optimal_density_per_ha)} recommended for this variety.`,
            [dev > 0 ? 'High density increases competition for water and nutrients — thin if still early, or adjust next season.' : 'Low density leaves yield on the table — gap-fill early or adjust the planter next season.']);
        }
      }
    }
    if (p.status === 'failed'){ cropPenalty += 10; }
  });

  // Field soil checks against the crops on them
  D.fields.forEach(f => {
    const crops = cropRows.filter(r => String(r.p.field_id) === String(f.id) && r.p.status !== 'harvested' && r.p.status !== 'failed');
    const ph = n(f.ph_level);
    if (has(f.ph_level) && crops.length){
      crops.forEach(r => {
        const [lo, hi] = r.kb.ph;
        if (ph < lo) add('soon', 'Crops', `${f.field_name}: soil pH ${fmtNum(ph, 1)} is low for ${r.crop}`,
          `${r.crop} does best at pH ${lo}–${hi}. Acid soils lock up phosphorus and can cause aluminium toxicity.`,
          ['Apply agricultural or dolomitic lime based on a soil test (often 1–2 t/ha), ideally before the next planting.'], '#/fields');
        else if (ph > hi) add('routine', 'Crops', `${f.field_name}: soil pH ${fmtNum(ph, 1)} is high for ${r.crop}`,
          `${r.crop} does best at pH ${lo}–${hi}. High pH reduces iron, zinc and phosphorus availability.`,
          ['Use ammonium-based fertilisers and organic matter; consider foliar micronutrients.'], '#/fields');
      });
    } else if (!has(f.ph_level)){
      add('routine', 'Crops', `${f.field_name}: no soil pH on record`,
        'Without a soil test the system can’t check whether the soil suits the crop.',
        ['Take a soil sample (0–20 cm, 10–15 spots mixed) and record pH and organic matter on the field.'], '#/fields');
    }
    if (has(f.organic_matter_pct) && n(f.organic_matter_pct) < 2){
      add('routine', 'Crops', `${f.field_name}: low organic matter (${fmtNum(f.organic_matter_pct, 1)}%)`,
        'Below about 2% the soil holds less water and nutrients.',
        ['Add manure or compost, keep crop residues, and use cover crops or legumes in the rotation.'], '#/fields');
    }
  });

  // Harvest losses
  const harvestByCrop = {};
  let totalHarvest = 0, totalLoss = 0;
  D.harvests.forEach(h => {
    const p = plantingById[String(h.planting_id)];
    const v = p ? varietyById[String(p.variety_id)] : null;
    const key = `${v ? v.crop_name : 'Unknown'} (${h.unit_of_measure || 'units'})`;
    harvestByCrop[key] = harvestByCrop[key] || { q: 0, loss: 0 };
    harvestByCrop[key].q += n(h.quantity_harvested);
    harvestByCrop[key].loss += n(h.loss_quantity);
    totalHarvest += n(h.quantity_harvested); totalLoss += n(h.loss_quantity);
  });
  Object.entries(harvestByCrop).forEach(([k, v]) => {
    const pct = v.q ? v.loss / (v.q + v.loss) : 0;
    if (pct > 0.1) add(pct > 0.2 ? 'urgent' : 'soon', 'Harvest', `${k}: ${Math.round(pct * 100)}% lost after harvest`,
      'Post-harvest losses above 10% are a quick win to fix.',
      ['Dry produce to safe moisture before storage and handle it gently.', 'Use clean, pest-free stores, pallets, and hermetic bags or a registered protectant.', 'Record the loss reason each time so the cause can be tracked.'], '#/harvests');
  });
  D.produce_storage.filter(s => s.status === 'stored' && n(s.spoilage_quantity) > 0 && n(s.quantity_stored) && n(s.spoilage_quantity) / n(s.quantity_stored) > 0.05).forEach(s => {
    add('soon', 'Harvest', `Spoilage in storage entry #${s.id}`,
      `${fmtNum(s.spoilage_quantity)} of ${fmtNum(s.quantity_stored)} has spoiled.`,
      ['Inspect the store for moisture, heat and pests; move good produce away from spoiled stock; sell or process sooner.'], '#/produce_storage');
  });

  out.crops = { rows: cropRows, harvestByCrop, totalHarvest, totalLoss };
  const activeP = D.crop_plantings.filter(p => p.status === 'active').length;
  out.scores.crops = D.crop_plantings.length ? clamp(100 - cropPenalty * (activeP ? 1 : 0.5)) : null;

  /* ================= Livestock ================= */
  const animals = D.livestock.filter(a => a.status === 'active');
  const bySpecies = by(animals, 'species');
  const healthByAnimal = by(D.livestock_health_records, 'animal_id');
  const animalById = Object.fromEntries(D.livestock.map(a => [String(a.id), a]));
  let lsPenalty = 0;
  const overdue = [], dueSoon = [];
  // the most recent record of each type per animal decides what's next due
  Object.entries(healthByAnimal).forEach(([aid, recs]) => {
    const a = animalById[aid];
    if (!a || a.status !== 'active') return;
    const byType = by(recs, 'record_type');
    Object.values(byType).forEach(list => {
      const r = latest(list, 'administered_date');
      const due = toDate(r && r.next_due_date);
      if (!due) return;
      const days = daysBetween(today, due);
      if (days < 0) overdue.push({ a, r, days });
      else if (days <= 14) dueSoon.push({ a, r, days });
    });
  });
  overdue.forEach(({ a, r, days }) => {
    lsPenalty += 12;
    add('urgent', 'Livestock', `${a.species} ${a.tag_number}: ${String(r.record_type).replace(/_/g, ' ')} overdue by ${-days} days`,
      `${r.diagnosis ? r.diagnosis + ' — ' : ''}was due ${fmtDate(toDate(r.next_due_date))}.`,
      ['Book the vet or treat today, then record it in Health Records with the next due date.'], '#/livestock_health_records');
  });
  dueSoon.forEach(({ a, r, days }) => {
    lsPenalty += 3;
    add('soon', 'Livestock', `${a.species} ${a.tag_number}: ${String(r.record_type).replace(/_/g, ' ')} due in ${days} days`,
      `Due ${fmtDate(toDate(r.next_due_date))}.`, ['Make sure the vaccine/medicine is in stock and the animals can be handled that day.'], '#/livestock_health_records');
  });
  const unchecked = animals.filter(a => {
    const l = latest(healthByAnimal[a.id] || [], 'administered_date');
    return !l || daysBetween(toDate(l.administered_date), today) > 180;
  });
  if (unchecked.length){
    lsPenalty += Math.min(20, unchecked.length * 2);
    add('routine', 'Livestock', `${unchecked.length} animal${unchecked.length === 1 ? ' has' : 's have'} no health record in the last 6 months`,
      unchecked.slice(0, 6).map(a => `${a.species} ${a.tag_number}`).join(', ') + (unchecked.length > 6 ? '…' : ''),
      ['Do a health check (body condition, eyes, feet, parasites) and record it.', 'Set a next-due date on every vaccination and deworming record.'], '#/livestock_health_records');
  }
  const recentDiag = D.livestock_health_records.filter(r => r.record_type === 'treatment' && toDate(r.administered_date) && daysBetween(toDate(r.administered_date), today) <= 30);
  if (recentDiag.length >= 3){
    lsPenalty += 10;
    add('soon', 'Livestock', `${recentDiag.length} treatments in the last 30 days`,
      'Several animals needing treatment at once can point to a herd-level problem (feed, water, parasites or an infectious disease).',
      ['Look for a common cause and talk to your vet about herd testing or vaccination.', 'Isolate sick animals and tighten biosecurity.'], '#/livestock_health_records');
  }
  // feeding records per species
  const feedRecent = D.livestock_feed_logs.filter(f => toDate(f.feeding_date) && daysBetween(toDate(f.feeding_date), today) <= 14);
  Object.keys(bySpecies).forEach(sp => {
    const kb = matchKb(sp, LIVESTOCK_KB) || LIVESTOCK_GENERIC;
    add('routine', 'Livestock', `${sp} (${bySpecies[sp].length}): care checklist`,
      kb.name !== LIVESTOCK_GENERIC.name ? `Guidance for ${kb.name.toLowerCase()}.` : 'General guidance.',
      [...kb.feeding, ...kb.health].slice(0, 4), '#/livestock');
    if (!feedRecent.some(f => String(f.species || '').toLowerCase() === sp.toLowerCase()) && D.livestock_feed_logs.length){
      add('routine', 'Livestock', `No feed logged for ${sp} in 14 days`,
        'Feed logs show what each group eats and what it costs.', ['Record feed issued from inventory under Feed Logs.'], '#/livestock_feed_logs');
    }
  });
  // production trend: last 30 days vs the 30 before
  const prodByType = by(D.livestock_production_logs, 'production_type');
  Object.entries(prodByType).forEach(([type, list]) => {
    const sum = (from, to) => list.filter(r => { const d = toDate(r.logged_date); return d && daysBetween(d, today) >= from && daysBetween(d, today) < to; }).reduce((s, r) => s + n(r.quantity), 0);
    const now = sum(0, 30), before = sum(30, 60);
    if (before > 0 && now < before * 0.85){
      lsPenalty += 8;
      add('soon', 'Livestock', `${type.charAt(0).toUpperCase() + type.slice(1)} production down ${Math.round((1 - now / before) * 100)}% on the previous month`,
        `${fmtNum(now)} in the last 30 days vs ${fmtNum(before)} in the 30 before.`,
        ['Check feed quality and quantity, water supply, heat stress and parasite load.', 'Look for sick animals and review any change in routine.'], '#/livestock_production_logs');
    }
  });
  out.livestock = { animals, bySpecies, overdue, dueSoon, prodByType };
  out.scores.livestock = D.livestock.length ? clamp(100 - lsPenalty) : null;

  /* ================= Equipment ================= */
  const maintByMachine = by(D.machinery_maintenance, 'machinery_id');
  const usageByMachine = by(D.machinery_usage, 'machinery_id');
  let eqPenalty = 0;
  const machineRows = D.machinery.map(m => {
    const kb = matchKb(`${m.type} ${m.name}`, EQUIPMENT_KB) || EQUIPMENT_GENERIC;
    const recs = maintByMachine[m.id] || [];
    const last = latest(recs, 'service_date');
    const hours = n(m.current_operating_hours);
    let dueAt = null;
    if (last){
      const at = n(last.operating_hours_at_service);
      const next = n(last.next_service_due_hours);
      dueAt = next ? (next > at ? next : at + next) : (at ? at + kb.interval : null);
    }
    const remaining = dueAt !== null ? dueAt - hours : null;
    const usage = usageByMachine[m.id] || [];
    const fuel = usage.reduce((s, u) => s + n(u.fuel_consumed_liters), 0);
    const worked = usage.reduce((s, u) => s + n(u.hours_worked), 0);
    const cost = recs.reduce((s, r) => s + n(r.cost), 0);
    const row = { m, kb, last, remaining, dueAt, fuelRate: worked ? fuel / worked : null, cost, worked };

    if (m.status === 'out_of_service'){
      eqPenalty += 10;
      add('soon', 'Equipment', `${m.name} is out of service`, 'Plan the repair or replacement before it’s needed in the field.',
        ['Get a repair quote and log it under Maintenance once done.'], '#/machinery');
    }
    if (!last){
      eqPenalty += 5;
      add('routine', 'Equipment', `${m.name}: no service history`, `Record a service so the system can work out when the next one is due (${kb.name.toLowerCase()} typically every ~${kb.interval} hours).`,
        [...kb.periodic.slice(0, 1), 'Log the service with the hour-meter reading and next-due hours.'], '#/machinery_maintenance');
    } else if (remaining !== null && remaining <= 0){
      eqPenalty += 15;
      add('urgent', 'Equipment', `${m.name}: service overdue by ${fmtNum(-remaining)} hours`,
        `Last serviced ${fmtDate(toDate(last.service_date))} at ${fmtNum(last.operating_hours_at_service)} h; now at ${fmtNum(hours)} h.`,
        kb.periodic, '#/machinery_maintenance');
    } else if (remaining !== null && remaining <= 25){
      eqPenalty += 4;
      add('soon', 'Equipment', `${m.name}: service due in ${fmtNum(remaining)} hours`, 'Book it before the next big job.', kb.periodic, '#/machinery_maintenance');
    } else if (daysBetween(toDate(last.service_date), today) > 365){
      eqPenalty += 4;
      add('routine', 'Equipment', `${m.name}: not serviced for over a year`, 'Seals, filters and oil age even when the machine stands.', kb.periodic, '#/machinery_maintenance');
    }
    // fuel efficiency: last 30 days vs overall
    if (usage.length >= 4 && row.fuelRate){
      const recent = usage.filter(u => toDate(u.date_used) && daysBetween(toDate(u.date_used), today) <= 30);
      const rf = recent.reduce((s, u) => s + n(u.fuel_consumed_liters), 0), rh = recent.reduce((s, u) => s + n(u.hours_worked), 0);
      if (rh && rf / rh > row.fuelRate * 1.25){
        add('soon', 'Equipment', `${m.name}: fuel use up ${Math.round((rf / rh / row.fuelRate - 1) * 100)}%`,
          `${fmtNum(rf / rh, 1)} L/h in the last 30 days vs ${fmtNum(row.fuelRate, 1)} L/h on average.`,
          ['Check the air and fuel filters, injectors and tyre pressure.', 'Make sure the implement is matched to the machine and set correctly.'], '#/machinery_usage');
      }
    }
    return row;
  });
  D.irrigation_systems.filter(s => s.status === 'maintenance').forEach(s => {
    const f = fieldById[String(s.field_id)];
    add('soon', 'Equipment', `${s.system_type} irrigation on ${f ? f.field_name : 'a field'} is under maintenance`,
      'Crops on this field may be short of water.', (EQUIPMENT_KB.find(k => k.keys.includes('irrigation')) || EQUIPMENT_GENERIC).periodic, '#/irrigation_systems');
  });
  const operational = D.machinery.filter(m => m.status === 'operational').length;
  out.equipment = { rows: machineRows, operational };
  out.scores.equipment = D.machinery.length ? clamp((operational / D.machinery.length) * 100 - eqPenalty) : null;

  /* ================= Pests & diseases ================= */
  const catById = Object.fromEntries(D.pest_disease_catalog.map(c => [String(c.id), c]));
  const recent = D.scouting_records.filter(s => toDate(s.scout_date) && daysBetween(toDate(s.scout_date), today) <= 90);
  const threats = {};
  recent.forEach(s => {
    const key = s.catalog_id ? String(s.catalog_id) : 'unknown';
    const c = catById[key];
    const t = threats[key] = threats[key] || {
      key, cat: c, name: c ? c.name : 'Unidentified problem', type: c ? c.type : 'pest',
      count: 0, maxSev: 0, maxSevName: 'low', last: null, fields: new Set(), area: [],
    };
    t.count++;
    const r = SEVERITY_RANK[s.severity_level] || 1;
    if (r > t.maxSev){ t.maxSev = r; t.maxSevName = s.severity_level; }
    const d = toDate(s.scout_date);
    if (!t.last || d > t.last) t.last = d;
    const f = fieldById[String(s.field_id)];
    t.fields.add(f ? f.field_name : 'Field #' + s.field_id);
    if (has(s.affected_area_pct)) t.area.push(n(s.affected_area_pct));
  });
  const threatList = Object.values(threats).sort((a, b) => b.maxSev - a.maxSev || b.count - a.count);
  threatList.forEach(t => {
    t.kb = matchKb(`${t.name} ${t.cat ? t.cat.symptoms || '' : ''}`, PEST_KB) || PEST_GENERIC[t.type] || PEST_GENERIC.pest;
  });
  let pestLoad = 0;
  recent.forEach(s => {
    const age = daysBetween(toDate(s.scout_date), today);
    const w = { low: 2, moderate: 6, high: 12, severe: 20 }[s.severity_level] || 2;
    pestLoad += age <= 30 ? w : w / 3;
  });
  // high/severe records without a treatment logged afterwards
  const appsByScout = by(D.chemical_applications, 'scouting_id');
  D.scouting_records.filter(s => (s.severity_level === 'high' || s.severity_level === 'severe') && toDate(s.scout_date) && daysBetween(toDate(s.scout_date), today) <= 30).forEach(s => {
    const linked = appsByScout[s.id] || [];
    const fieldPlantings = D.crop_plantings.filter(p => String(p.field_id) === String(s.field_id)).map(p => String(p.id));
    const treatedAfter = D.chemical_applications.some(a => fieldPlantings.includes(String(a.planting_id)) && toDate(a.application_date) >= toDate(s.scout_date));
    if (linked.length || treatedAfter) return;
    const c = catById[String(s.catalog_id)];
    const kb = matchKb(`${c ? c.name : ''} ${c ? c.symptoms || '' : ''}`, PEST_KB) || PEST_GENERIC[c ? c.type : 'pest'];
    const f = fieldById[String(s.field_id)];
    add('urgent', 'Pests', `${c ? c.name : 'Pest/disease'} at ${s.severity_level} level on ${f ? f.field_name : 'a field'} — no treatment recorded`,
      `Scouted ${fmtDate(toDate(s.scout_date))}${has(s.affected_area_pct) ? `, ${fmtNum(s.affected_area_pct, 1)}% of the area affected` : ''}.${c && c.recommended_control ? ' Your catalogue says: ' + c.recommended_control : ''}`,
      [...kb.cultural.slice(0, 1), ...kb.biological.slice(0, 1), ...kb.chemical.slice(0, 1), 'Record what you apply under Chemical Applications.'].filter(Boolean), '#/chemical_applications');
  });
  // ineffective treatments
  D.chemical_applications.filter(a => a.effectiveness === 'ineffective' || a.effectiveness === 'partially_effective').forEach(a => {
    const p = plantingById[String(a.planting_id)];
    add(a.effectiveness === 'ineffective' ? 'urgent' : 'soon', 'Pests',
      `Treatment on ${p ? plantingLabel(p) : 'planting #' + a.planting_id} was ${a.effectiveness.replace(/_/g, ' ')}`,
      `Applied ${fmtDate(toDate(a.application_date))} at ${fmtNum(a.dosage_per_ha, 2)}/ha.`,
      ['Switch to a product from a different mode-of-action group — repeating the same group builds resistance.',
       'Check the timing (young larvae are much easier to kill), the dose, spray water quality and coverage.',
       'Re-scout 5–7 days after spraying and record the result.'], '#/chemical_applications');
  });
  if (D.crop_plantings.some(p => p.status === 'active')){
    const lastScout = latest(D.scouting_records, 'scout_date');
    if (!lastScout || daysBetween(toDate(lastScout.scout_date), today) > 10){
      add('soon', 'Pests', lastScout ? `No scouting for ${daysBetween(toDate(lastScout.scout_date), today)} days` : 'No scouting recorded yet',
        'Active crops should be scouted at least weekly — most pests are cheapest to control when caught early.',
        ['Walk each field in a W pattern, check 20 plants per spot, and record what you find under Scouting Records.'], '#/scouting_records');
    }
  }
  // weather-driven disease risk from the latest recorded log
  const lastWx = latest(D.weather_logs, 'log_timestamp');
  if (lastWx && n(lastWx.humidity_pct) >= 80 && n(lastWx.temp_celsius) >= 15 && n(lastWx.temp_celsius) <= 30){
    add('soon', 'Pests', 'Humid, mild weather: higher fungal disease risk',
      `Last weather log: ${fmtNum(lastWx.temp_celsius, 1)} °C and ${fmtNum(lastWx.humidity_pct)}% humidity.`,
      ['Scout for blight, mildew and leaf spots over the next week.', 'Apply a protectant fungicide ahead of wet spells on susceptible crops.'], '#/scouting_records');
  }
  out.pests = { recent, threatList, pestLoad };
  out.scores.pests = (D.scouting_records.length || D.crop_plantings.length) ? clamp(100 - pestLoad) : null;

  /* ================= Inventory & tasks ================= */
  let invPenalty = 0;
  const low = D.inventory_items.filter(i => n(i.reorder_threshold) > 0 && n(i.current_stock) <= n(i.reorder_threshold));
  low.forEach(i => {
    invPenalty += i.category === 'chemical' || i.category === 'medicine' || i.category === 'feed' ? 12 : 8;
    add(i.current_stock <= 0 ? 'urgent' : 'soon', 'Inventory', `${i.item_name} is ${n(i.current_stock) <= 0 ? 'out of stock' : 'below its reorder point'}`,
      `${fmtNum(i.current_stock)} ${i.unit_of_measure || ''} left (reorder at ${fmtNum(i.reorder_threshold)}).`,
      ['Raise a purchase order now so it arrives before it’s needed.'], '#/purchase_orders');
  });
  const expiring = D.inventory_batches.filter(b => n(b.quantity_remaining) > 0 && toDate(b.expiry_date) && daysBetween(today, toDate(b.expiry_date)) <= 45);
  const itemById = Object.fromEntries(D.inventory_items.map(i => [String(i.id), i]));
  expiring.forEach(b => {
    const days = daysBetween(today, toDate(b.expiry_date));
    const it = itemById[String(b.item_id)];
    invPenalty += days < 0 ? 8 : 4;
    add(days < 0 ? 'urgent' : 'soon', 'Inventory', `${it ? it.item_name : 'Batch #' + b.id}${b.batch_number ? ' (batch ' + b.batch_number + ')' : ''} ${days < 0 ? 'expired ' + -days + ' days ago' : 'expires in ' + days + ' days'}`,
      `${fmtNum(b.quantity_remaining)} remaining.`,
      days < 0 ? ['Do not use expired chemicals, medicines or seed; dispose of them safely as the label directs.'] : ['Use this batch first (first-expiry, first-out).'], '#/inventory_batches');
  });
  const overdueTasks = D.task_allocations.filter(t => (t.status === 'pending' || t.status === 'in_progress') && toDate(t.due_date) && toDate(t.due_date) < today);
  if (overdueTasks.length){
    add(overdueTasks.length > 3 ? 'urgent' : 'soon', 'Tasks', `${overdueTasks.length} task${overdueTasks.length === 1 ? ' is' : 's are'} overdue`,
      overdueTasks.slice(0, 5).map(t => t.title).join(', ') + (overdueTasks.length > 5 ? '…' : ''),
      ['Reassign labour or reschedule, and mark finished tasks as completed.'], '#/task_allocations');
  }
  out.inventory = { low, expiring, overdueTasks };
  out.scores.inventory = (D.inventory_items.length || D.task_allocations.length) ? clamp(100 - invPenalty - overdueTasks.length * 4) : null;

  /* ================= Finance ================= */
  const months = lastMonths(12);
  const inc = Object.fromEntries(months.map(m => [m, 0])), exp = Object.fromEntries(months.map(m => [m, 0]));
  const expCat = {}, incCat = {};
  let totalInc = 0, totalExp = 0;
  D.financial_transactions.forEach(t => {
    const d = toDate(t.transaction_date); const a = n(t.amount);
    const cat = (t.category || 'Other').trim() || 'Other';
    if (t.transaction_type === 'income'){ totalInc += a; incCat[cat] = (incCat[cat] || 0) + a; }
    else { totalExp += a; expCat[cat] = (expCat[cat] || 0) + a; }
    if (d){ const k = monthKey(d); if (k in inc){ if (t.transaction_type === 'income') inc[k] += a; else exp[k] += a; } }
  });
  const net = months.map(m => inc[m] - exp[m]);
  let cum = 0; const cumulative = months.map((m, i) => (cum += net[i]));
  const margin = totalInc ? (totalInc - totalExp) / totalInc : (totalExp ? -1 : 0);
  const unpaid = D.sales_orders.filter(o => o.payment_status !== 'paid' && o.order_status !== 'cancelled');
  const receivable = unpaid.reduce((s, o) => s + n(o.total_amount), 0);
  const area = D.farms.reduce((s, f) => s + n(f.total_area_hectares), 0);

  if (D.financial_transactions.length){
    if (totalInc - totalExp < 0){
      add('urgent', 'Finance', `Running at a loss of ${money(totalExp - totalInc)}`,
        `Recorded expenses (${money(totalExp)}) are higher than income (${money(totalInc)}).`,
        ['Check the biggest expense categories below for savings.', 'Make sure every sale is recorded as income.', 'Collect money owed on unpaid sales orders.'], '#/financial_transactions');
    } else if (margin < 0.15 && totalInc){
      add('soon', 'Finance', `Thin profit margin (${Math.round(margin * 100)}%)`,
        'A margin under 15% leaves little room for a bad season.', ['Look for input savings and better-priced markets for your produce.'], '#/reports');
    } else if (totalInc){
      add('good', 'Finance', `Profitable: ${Math.round(margin * 100)}% margin`, `Net ${money(totalInc - totalExp)} on recorded figures.`, ['Keep recording every transaction so the picture stays accurate.']);
    }
    const topExp = Object.entries(expCat).sort((a, b) => b[1] - a[1])[0];
    if (topExp && totalExp && topExp[1] / totalExp > 0.4){
      add('routine', 'Finance', `"${topExp[0]}" is ${Math.round(topExp[1] / totalExp * 100)}% of all spending`,
        `${money(topExp[1])} of ${money(totalExp)}.`, ['Compare supplier prices, buy in bulk ahead of the season, and check for waste.'], '#/financial_transactions');
    }
    const e3 = months.slice(-3).reduce((s, m) => s + exp[m], 0), e3b = months.slice(-6, -3).reduce((s, m) => s + exp[m], 0);
    if (e3b > 0 && e3 > e3b * 1.25){
      add('soon', 'Finance', `Spending up ${Math.round((e3 / e3b - 1) * 100)}% on the previous 3 months`,
        `${money(e3)} vs ${money(e3b)}.`, ['Check whether this is planned seasonal spending or a cost creeping up.'], '#/financial_transactions');
    }
    const lossMonths = months.filter((m, i) => net[i] < 0 && (inc[m] || exp[m])).length;
    if (lossMonths >= 3){
      add('routine', 'Finance', `${lossMonths} of the last 12 months ran at a loss`, 'Farming cash flow is seasonal, but it helps to plan for the gaps.',
        ['Build a cash-flow plan for the lean months and time input purchases with expected sales.'], '#/reports');
    }
    const lastTx = latest(D.financial_transactions, 'transaction_date');
    if (lastTx && daysBetween(toDate(lastTx.transaction_date), today) > 30){
      add('routine', 'Finance', 'No transactions recorded in the last 30 days', 'Profit and loss can only be as accurate as the records.', ['Record recent sales and expenses.'], '#/financial_transactions');
    }
  } else {
    add('routine', 'Finance', 'No income or expenses recorded yet', 'Profit and loss charts appear once transactions are recorded.', ['Start with this season’s input purchases, labour and sales.'], '#/financial_transactions');
  }
  if (receivable > 0){
    add(unpaid.length > 3 ? 'soon' : 'routine', 'Finance', `${money(receivable)} owed on ${unpaid.length} unpaid sales order${unpaid.length === 1 ? '' : 's'}`,
      'Unpaid orders tie up cash you could use for inputs.', ['Follow up with customers and record payments as they come in.'], '#/sales_orders');
  }
  out.finance = { months, inc, exp, net, cumulative, expCat, incCat, totalInc, totalExp, margin, receivable, unpaid, area };
  out.scores.finance = D.financial_transactions.length ? clamp(55 + margin * 100) : null;

  /* ================= Overall ================= */
  const parts = Object.values(out.scores).filter(v => v !== null);
  out.overall = parts.length ? parts.reduce((a, b) => a + b, 0) / parts.length : null;
  out.suggestions.sort((a, b) => SEV[a.sev].rank - SEV[b.sev].rank);
  out.counts = Object.fromEntries(Object.keys(SEV).map(k => [k, out.suggestions.filter(s => s.sev === k).length]));
  return out;
}

/* ---------------------------------------------------------------------- */
/* Rendering                                                              */
/* ---------------------------------------------------------------------- */
export async function renderAiOverview(ctx){
  const { escapeHtml: esc, bannerHtml, fetchCached, user, icon } = ctx;
  const view = document.getElementById('view');
  view.innerHTML = `<div class="empty-state"><p>Analysing your farm…</p></div>`;

  const ALL = await loadAll(fetchCached);
  // The server already limits records to the person's farm. Administrators
  // pick a farm (or all farms) in the top bar; narrow the farm list to match.
  const picked = user && user.role === 'admin' ? getSelectedFarm() : 'all';
  const scope = picked !== 'all' && ALL.farms.some(f => String(f.id) === String(picked)) ? String(picked) : 'all';
  const scoped = scopeTo(ALL, scope);
  const farmCodes = scoped.farms.length ? scoped.farms.map(f => Cur.farmCurrency(f.id)) : [Cur.sharedCurrency() || Cur.DEFAULT_CURRENCY];
  MONEY = Cur.totalCurrency(farmCodes);
  const { D, from: moneyFrom } = toDisplayCurrency(scoped, ALL);
  const A = analyse(D);

  const scopeName = D.farms.length > 1 ? `all ${D.farms.length} farms`
    : (D.farms[0] ? D.farms[0].farm_name : (user && user.farmName) || 'your farm');

  const anyData = Object.entries(D).some(([k, v]) => !['crop_varieties', 'pest_disease_catalog'].includes(k) && v.length);

  view.innerHTML = `
    ${bannerHtml('ai_overview')}
    <div class="page-head">
      <div>
        <h1>AI Farm Overview Analysis</h1>
        <p class="desc">Everything recorded across ${esc(scopeName)}, analysed in one place — health scores, growth and profit trends, and prioritised suggestions for crops, animals, equipment and pest control. Money is in ${esc(MONEY)}.</p>
      </div>
      <div class="ai-head-actions">
        <button class="btn btn-ghost btn-sm" id="aiRefresh">Re-run analysis</button>
        <button class="btn btn-ghost btn-sm" id="aiPrint">Print report</button>
      </div>
    </div>
    <div class="subtabs ai-tabs" role="tablist">
      ${TABS.map(t => `<div class="subtab${t.id === state.tab ? ' active' : ''}" role="tab" tabindex="0" data-tab="${t.id}">${t.label}${t.id === 'actions' && (A.counts.urgent + A.counts.soon) ? ` <span class="ai-tab-count">${A.counts.urgent + A.counts.soon}</span>` : ''}</div>`).join('')}
    </div>
    ${Cur.ratesNoteHtml(moneyFrom, MONEY)}
    <div id="aiBody"></div>
    <p class="help-text ai-foot">Analysis generated ${new Date().toLocaleString()} from the records in this system and built-in agronomy, livestock and equipment guidelines. It is advice, not a substitute for your agronomist, vet or extension officer. ${esc(SAFETY_NOTE)}</p>
  `;

  const body = document.getElementById('aiBody');
  const draw = () => {
    if (!anyData){
      body.innerHTML = `<div class="table-wrap"><div class="empty-state">
        <div class="glyph">${icon('ai_overview', 44)}</div>
        <h3>Nothing to analyse yet</h3>
        <p>Add farms, fields, plantings, animals, machinery and transactions, and this page will build a full analysis with suggestions and charts.</p>
        <a href="#/farms" class="btn btn-primary">Add a farm</a>
      </div></div>`;
      return;
    }
    const renderers = { overview: tabOverview, crops: tabCrops, livestock: tabLivestock, equipment: tabEquipment, pests: tabPests, finance: tabFinance, actions: tabActions };
    resetChartSlots();
    body.innerHTML = (renderers[state.tab] || tabOverview)(D, A, ALL, esc, user);
    fillChartSlots(body);
    body.querySelectorAll('[data-goto]').forEach(b => b.addEventListener('click', () => switchTab(b.dataset.goto)));
    if (state.tab === 'pests' || state.tab === 'overview') loadSprayWindow(D.farms.length ? D.farms : ALL.farms, esc);
  };
  const switchTab = (id) => {
    state.tab = id;
    view.querySelectorAll('.ai-tabs .subtab').forEach(x => x.classList.toggle('active', x.dataset.tab === id));
    draw();
  };
  view.querySelectorAll('.ai-tabs .subtab').forEach(t => {
    t.addEventListener('click', () => switchTab(t.dataset.tab));
    t.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' '){ e.preventDefault(); switchTab(t.dataset.tab); } });
  });
  document.getElementById('aiRefresh').addEventListener('click', () => { state.weather = null; renderAiOverview(ctx); });
  document.getElementById('aiPrint').addEventListener('click', () => window.print());
  draw();
  mountFarmChat(view, () => ({ D, A, user, scopeName, currency: MONEY, weather: state.weather && D.farms.some(f => f.id === state.weather.farmId) ? state.weather : null }), esc);
}

/* ---------- shared pieces ---------- */
function sevPill(sev){ const s = SEV[sev]; return `<span class="pill pill-${s.pill}">${s.label}</span>`; }

function suggestionList(list, esc, { limit = 0, empty = 'Nothing needs attention here right now.' } = {}){
  const items = limit ? list.slice(0, limit) : list;
  if (!items.length) return `<p class="ai-muted">${esc(empty)}</p>`;
  return `<ul class="ai-suggest">${items.map(s => `
    <li class="ai-s ai-s-${s.sev}">
      <div class="ai-s-head">${sevPill(s.sev)}<span class="ai-s-area">${esc(s.area)}</span>${s.link ? `<a class="ai-s-link" href="${s.link}">Open →</a>` : ''}</div>
      <div class="ai-s-title">${esc(s.title)}</div>
      ${s.detail ? `<p class="ai-s-detail">${esc(s.detail)}</p>` : ''}
      ${s.actions && s.actions.length ? `<ul class="ai-s-actions">${s.actions.map(a => `<li>${esc(a)}</li>`).join('')}</ul>` : ''}
    </li>`).join('')}</ul>`;
}

function scoreBars(scores){
  const names = { crops: 'Crops', livestock: 'Livestock', equipment: 'Equipment', pests: 'Pest pressure (higher is better)', inventory: 'Inventory & tasks', finance: 'Finance' };
  return `<div class="ai-scorebars">${Object.entries(names).map(([k, label]) => {
    const v = scores[k];
    if (v === null || v === undefined) return `<div class="ai-scorebar"><span>${label}</span><div class="ai-progress"><i style="width:0"></i></div><b class="num">n/a</b></div>`;
    const color = v >= 75 ? INCOME : v >= 50 ? '#C7861A' : EXPENSE;
    return `<div class="ai-scorebar"><span>${label}</span><div class="ai-progress"><i style="width:${Math.round(v)}%;background:${color}"></i></div><b class="num">${Math.round(v)}</b></div>`;
  }).join('')}</div>`;
}

function progressCell(pct){
  const p = Math.round(clamp(pct * 100, 0, 100));
  return `<div class="ai-progress ai-progress-inline" title="${p}%"><i style="width:${p}%;background:${SERIES[0]}"></i></div><span class="num ai-progress-num">${p}%</span>`;
}

function seasonal(D, ALL){
  const farm = (D.farms[0] || ALL.farms[0]);
  const south = !farm || !has(farm.latitude) || n(farm.latitude) < 0;
  const m = new Date().getMonth();
  const tips = (south ? SEASON_SOUTH : SEASON_NORTH)[m] || [];
  const next = (south ? SEASON_SOUTH : SEASON_NORTH)[(m + 1) % 12] || [];
  const monthName = d => new Date(2000, d, 1).toLocaleDateString(undefined, { month: 'long' });
  return `<div class="panel">
    <h3>Seasonal outlook — ${monthName(m)}</h3>
    <ul class="ai-bullets">${tips.map(t => `<li>${t}</li>`).join('')}</ul>
    <p class="ai-subhead">Coming up in ${monthName((m + 1) % 12)}</p>
    <ul class="ai-bullets">${next.map(t => `<li>${t}</li>`).join('')}</ul>
    <p class="help-text" style="margin:8px 0 12px;">${south ? 'Southern-hemisphere (Southern Africa) calendar' : 'Northern-hemisphere calendar'}, based on the farm’s saved latitude.</p>
  </div>`;
}

function summaryText(D, A, esc){
  const bits = [];
  const active = D.crop_plantings.filter(p => p.status === 'active');
  if (active.length){
    const crops = [...new Set(A.crops.rows.filter(r => r.p.status === 'active').map(r => r.crop))];
    const avg = A.crops.rows.filter(r => r.p.status === 'active').reduce((s, r) => s + Math.min(r.progress, 1), 0) / active.length;
    bits.push(`${active.length} active planting${active.length === 1 ? '' : 's'} (${crops.slice(0, 4).join(', ')}${crops.length > 4 ? '…' : ''}) are on average ${Math.round(avg * 100)}% of the way to harvest.`);
  } else bits.push('There are no active plantings right now.');
  if (A.livestock.animals.length){
    bits.push(`${A.livestock.animals.length} animal${A.livestock.animals.length === 1 ? '' : 's'} on hand across ${Object.keys(A.livestock.bySpecies).length} species${A.livestock.overdue.length ? `, with ${A.livestock.overdue.length} overdue health treatment${A.livestock.overdue.length === 1 ? '' : 's'}` : ''}.`);
  }
  if (D.machinery.length) bits.push(`${A.equipment.operational} of ${D.machinery.length} machines are operational.`);
  if (A.pests.threatList.length){
    const top = A.pests.threatList[0];
    bits.push(`The biggest crop-protection threat in the last 90 days is ${top.name} (up to ${top.maxSevName}) on ${[...top.fields].slice(0, 3).join(', ')}.`);
  }
  if (D.financial_transactions.length){
    const netV = A.finance.totalInc - A.finance.totalExp;
    bits.push(`Recorded ${netV >= 0 ? 'profit' : 'loss'} so far is ${money(Math.abs(netV))} (income ${money(A.finance.totalInc)}, expenses ${money(A.finance.totalExp)}).`);
  }
  bits.push(A.counts.urgent ? `${A.counts.urgent} item${A.counts.urgent === 1 ? ' needs' : 's need'} urgent attention.` : 'Nothing is urgent right now.');
  return esc(bits.join(' '));
}

/* ---------- tabs ---------- */
function tabOverview(D, A, ALL, esc){
  const F = A.finance;
  const netV = F.totalInc - F.totalExp;
  const area = F.area;
  const pnlCats = F.months.map(monthLabel);
  return `
    <div class="ai-hero panel">
      <div class="ai-hero-score">
        ${A.overall !== null ? scoreRing(A.overall, 'Overall farm health') : ''}
        <div class="ai-hero-score-label">Farm health score</div>
      </div>
      <div class="ai-hero-text">
        <h3>Summary</h3>
        <p class="ai-summary">${summaryText(D, A, esc)}</p>
        <div class="ai-counts">
          <span>${sevPill('urgent')} <b class="num">${A.counts.urgent}</b></span>
          <span>${sevPill('soon')} <b class="num">${A.counts.soon}</b></span>
          <span>${sevPill('routine')} <b class="num">${A.counts.routine}</b></span>
        </div>
      </div>
      <div class="ai-hero-bars">${scoreBars(A.scores)}</div>
    </div>

    <div class="stat-grid">
      <div class="stat-card"><div class="label">Total area (ha)</div><div class="value olive">${fmtNum(area, 1)}</div></div>
      <div class="stat-card"><div class="label">Fields</div><div class="value olive">${D.fields.length}</div></div>
      <div class="stat-card"><div class="label">Active plantings</div><div class="value ochre">${D.crop_plantings.filter(p => p.status === 'active').length}</div></div>
      <div class="stat-card"><div class="label">Animals on hand</div><div class="value ochre">${A.livestock.animals.length}</div></div>
      <div class="stat-card"><div class="label">Machines ready</div><div class="value slate">${A.equipment.operational}/${D.machinery.length}</div></div>
      <div class="stat-card"><div class="label">Net profit / loss</div><div class="value ${netV < 0 ? 'rust' : 'olive'} num">${money(netV)}</div></div>
    </div>

    <div class="panel-grid">
      <div class="panel">
        <h3>Top priority actions</h3>
        ${suggestionList(A.suggestions.filter(s => s.sev !== 'good' && !(s.sev === 'routine' && /care checklist|stage care/.test(s.title))), esc, { limit: 6 })}
        <p style="margin:4px 0 14px;"><button class="btn btn-ghost btn-sm" data-goto="actions">See all ${A.suggestions.length} suggestions</button></p>
      </div>
      <div>
        ${seasonal(D, ALL)}
        <div class="panel"><h3>Spray &amp; field-work window</h3><div class="ai-spray" data-spray>${sprayPlaceholder(D, ALL)}</div></div>
      </div>
    </div>

    <div class="panel-grid ai-even">
      <div class="panel">
        <h3>Monthly profit / loss</h3>
        ${bar(pnlCats, [{ name: 'Net', color: INCOME, values: F.net }], { colorFor: v => v >= 0 ? INCOME : EXPENSE, fmt: money, title: 'Monthly profit and loss', empty: 'Record income and expenses to see profit and loss by month.' })}
        <p style="margin:8px 0 14px;"><button class="btn btn-ghost btn-sm" data-goto="finance">Open profit &amp; loss</button></p>
      </div>
      <div class="panel">
        <h3>Crop progress to harvest</h3>
        ${cropProgressTable(A, esc, 6)}
        <p style="margin:8px 0 14px;"><button class="btn btn-ghost btn-sm" data-goto="crops">Open crops &amp; growth</button></p>
      </div>
    </div>`;
}

function cropProgressTable(A, esc, limit = 0){
  let rows = A.crops.rows.filter(r => r.p.status === 'active' || r.p.status === 'planned');
  rows.sort((a, b) => (a.daysToHarvest ?? 9e9) - (b.daysToHarvest ?? 9e9));
  if (limit) rows = rows.slice(0, limit);
  if (!rows.length) return `<p class="ai-muted">No active plantings. <a href="#/crop_plantings">Record a planting</a> to track progress.</p>`;
  return `<div class="table-wrap ai-flat"><table>
    <thead><tr><th>Planting</th><th>Stage</th><th>Progress</th><th>Harvest</th></tr></thead>
    <tbody>${rows.map(r => `<tr>
      <td>${esc(r.label)}${r.flags.length ? ` <span class="pill pill-ochre">${esc(r.flags[0])}</span>` : ''}</td>
      <td>${esc(STAGES[r.loggedStage ?? r.expectedStage])}${r.loggedStage === null ? ' <span class="ai-muted">(est.)</span>' : ''}</td>
      <td class="ai-progress-cell">${progressCell(r.progress)}</td>
      <td class="num">${r.daysToHarvest === null ? '—' : r.daysToHarvest < 0 ? `${-r.daysToHarvest} d overdue` : `in ${r.daysToHarvest} d`}</td>
    </tr>`).join('')}</tbody></table></div>`;
}

function tabCrops(D, A, ALL, esc){
  const rows = A.crops.rows;
  // growth chart: avg height over time, up to 5 plantings with the most logs
  const withLogs = rows.filter(r => r.logs.some(l => has(l.avg_height_cm))).sort((a, b) => b.logs.length - a.logs.length).slice(0, 5);
  const growthSeries = withLogs.map((r, i) => ({
    name: r.label.split(' · ').slice(-1)[0] + ' · ' + r.label.split(' · ')[0],
    short: r.crop,
    color: SERIES[i],
    points: r.logs.filter(l => has(l.avg_height_cm) && toDate(l.log_date)).map(l => [toDate(l.log_date), n(l.avg_height_cm)]),
  }));
  const harvestItems = Object.entries(A.crops.harvestByCrop).map(([k, v]) => ({ label: k, value: v.q })).sort((a, b) => b.value - a.value).slice(0, 10);
  const lossItems = Object.entries(A.crops.harvestByCrop).map(([k, v]) => ({ label: k, value: v.q + v.loss ? Math.round(v.loss / (v.q + v.loss) * 1000) / 10 : 0, color: EXPENSE })).filter(i => i.value).sort((a, b) => b.value - a.value);
  const cropsPresent = [...new Map(rows.filter(r => r.p.status === 'active' || r.p.status === 'planned').map(r => [r.kb.name, r])).values()];
  const cropSugs = A.suggestions.filter(s => s.area === 'Crops' || s.area === 'Harvest');

  return `
    <div class="stat-grid">
      <div class="stat-card"><div class="label">Plantings on record</div><div class="value olive">${D.crop_plantings.length}</div></div>
      <div class="stat-card"><div class="label">Active</div><div class="value ochre">${D.crop_plantings.filter(p => p.status === 'active').length}</div></div>
      <div class="stat-card"><div class="label">Growth logs</div><div class="value slate">${D.crop_growth_logs.length}</div></div>
      <div class="stat-card"><div class="label">Total harvested</div><div class="value olive num">${fmtNum(A.crops.totalHarvest)}</div></div>
      <div class="stat-card"><div class="label">Post-harvest loss</div><div class="value rust num">${fmtNum(A.crops.totalLoss)}</div></div>
    </div>
    <div class="panel">
      <h3>Growth progress — average plant height (cm)</h3>
      ${line(growthSeries, { fmt: v => fmtNum(v, 1) + ' cm', valueLabel: 'Height (cm)', title: 'Average plant height over time', empty: 'Log growth stage and average height under Growth Logs to see growth curves here.' })}
      <div style="height:12px"></div>
    </div>
    <div class="panel">
      <h3>Every planting — progress to harvest</h3>
      ${cropProgressTable(A, esc)}
      <div style="height:12px"></div>
    </div>
    <div class="panel-grid ai-even">
      <div class="panel"><h3>Yield by crop</h3>${hbar(harvestItems, { fmt: v => fmtNum(v), valueLabel: 'Harvested', color: SERIES[1], empty: 'No harvests recorded yet.' })}<div style="height:12px"></div></div>
      <div class="panel"><h3>Post-harvest loss (%)</h3>${hbar(lossItems, { fmt: v => fmtNum(v, 1) + '%', valueLabel: 'Loss %', empty: 'No harvest losses recorded.' })}<div style="height:12px"></div></div>
    </div>
    <div class="panel"><h3>Suggestions for your crops</h3>${suggestionList(cropSugs, esc)}</div>
    ${cropsPresent.length ? `<div class="panel"><h3>How to keep your crops</h3><div class="ai-kb-grid">${cropsPresent.map(r => `
      <div class="ai-kb">
        <h4>${esc(r.kb.name)}</h4>
        <p class="ai-kb-meta">Ideal soil pH ${r.kb.ph[0]}–${r.kb.ph[1]}</p>
        ${STAGES.map(st => `<p class="ai-subhead">${st}</p><ul class="ai-bullets">${(r.kb.stages[st] || []).map(t => `<li>${esc(t)}</li>`).join('')}</ul>`).join('')}
        <p class="ai-subhead">General care</p><ul class="ai-bullets">${r.kb.care.map(t => `<li>${esc(t)}</li>`).join('')}</ul>
      </div>`).join('')}</div></div>` : ''}`;
}

function tabLivestock(D, A, ALL, esc){
  const L = A.livestock;
  const species = Object.entries(L.bySpecies).sort((a, b) => b[1].length - a[1].length);
  const herd = hbar(species.map(([s, list], i) => ({ label: s, value: list.length, color: SERIES[i % SERIES.length] })), { fmt: v => fmtNum(v), valueLabel: 'Animals', empty: 'No active animals recorded.' });
  const months = lastMonths(12);
  const prodTypes = Object.keys(L.prodByType).slice(0, 5);
  const prodSeries = prodTypes.map((t, i) => {
    const units = [...new Set(L.prodByType[t].map(r => r.unit).filter(Boolean))].join('/');
    const totals = Object.fromEntries(months.map(m => [m, 0]));
    L.prodByType[t].forEach(r => { const d = toDate(r.logged_date); if (d && monthKey(d) in totals) totals[monthKey(d)] += n(r.quantity); });
    return { name: `${t}${units ? ' (' + units + ')' : ''}`, color: SERIES[i], points: months.filter(m => totals[m]).map(m => [new Date(+m.slice(0, 4), +m.slice(5) - 1, 15), totals[m]]) };
  });
  const healthCost = {};
  D.livestock_health_records.forEach(r => { const d = toDate(r.administered_date); if (d && months.includes(monthKey(d))) healthCost[monthKey(d)] = (healthCost[monthKey(d)] || 0) + n(r.cost); });
  const kbs = [...new Map(species.map(([s]) => { const kb = matchKb(s, LIVESTOCK_KB) || LIVESTOCK_GENERIC; return [kb.name, kb]; })).values()];
  const due = [...L.overdue.map(x => ({ ...x, sev: 'urgent' })), ...L.dueSoon.map(x => ({ ...x, sev: 'soon' }))];

  return `
    <div class="stat-grid">
      <div class="stat-card"><div class="label">Animals on hand</div><div class="value ochre">${L.animals.length}</div></div>
      <div class="stat-card"><div class="label">Species</div><div class="value olive">${species.length}</div></div>
      <div class="stat-card"><div class="label">Treatments overdue</div><div class="value ${L.overdue.length ? 'rust' : 'olive'}">${L.overdue.length}</div></div>
      <div class="stat-card"><div class="label">Due in 14 days</div><div class="value slate">${L.dueSoon.length}</div></div>
    </div>
    <div class="panel-grid ai-even">
      <div class="panel"><h3>Herd by species</h3>${herd}<div style="height:12px"></div></div>
      <div class="panel"><h3>Health spending by month</h3>${bar(months.map(monthLabel), [{ name: 'Health cost', color: SERIES[3], values: months.map(m => healthCost[m] || 0) }], { fmt: money, empty: 'No health record costs in the last 12 months.' })}<div style="height:12px"></div></div>
    </div>
    <div class="panel"><h3>Production trend (monthly totals)</h3>${line(prodSeries, { fmt: v => fmtNum(v, 1), valueLabel: 'Quantity', empty: 'Record milk, eggs or other output under Production Logs to see the trend.' })}<div style="height:12px"></div></div>
    <div class="panel"><h3>Vaccinations &amp; treatments due</h3>
      ${due.length ? `<div class="table-wrap ai-flat"><table><thead><tr><th></th><th>Animal</th><th>Type</th><th>Due</th></tr></thead><tbody>
        ${due.sort((a, b) => a.days - b.days).map(x => `<tr><td>${sevPill(x.sev)}</td><td>${esc(x.a.species)} ${esc(x.a.tag_number)}</td><td>${esc(String(x.r.record_type).replace(/_/g, ' '))}${x.r.diagnosis ? ' · ' + esc(x.r.diagnosis) : ''}</td><td class="num">${fmtDate(toDate(x.r.next_due_date))}</td></tr>`).join('')}
      </tbody></table></div>` : `<p class="ai-muted">Nothing overdue or due in the next 14 days. Add a next-due date on each health record to keep this list accurate.</p>`}
      <div style="height:12px"></div>
    </div>
    <div class="panel"><h3>Suggestions for your animals</h3>${suggestionList(A.suggestions.filter(s => s.area === 'Livestock' && !/care checklist/.test(s.title)), esc)}</div>
    ${kbs.length ? `<div class="panel"><h3>How to keep your animals</h3><div class="ai-kb-grid">${kbs.map(kb => `
      <div class="ai-kb"><h4>${esc(kb.name)}</h4>
        <p class="ai-subhead">Feeding &amp; water</p><ul class="ai-bullets">${kb.feeding.map(t => `<li>${esc(t)}</li>`).join('')}</ul>
        <p class="ai-subhead">Housing</p><ul class="ai-bullets">${kb.housing.map(t => `<li>${esc(t)}</li>`).join('')}</ul>
        <p class="ai-subhead">Health &amp; prevention</p><ul class="ai-bullets">${kb.health.map(t => `<li>${esc(t)}</li>`).join('')}</ul>
        <p class="ai-subhead">Warning signs</p><ul class="ai-bullets">${kb.signs.map(t => `<li>${esc(t)}</li>`).join('')}</ul>
      </div>`).join('')}</div></div>` : ''}`;
}

function tabEquipment(D, A, ALL, esc){
  const E = A.equipment;
  const statusCounts = ['operational', 'under_maintenance', 'out_of_service'].map(s => ({ s, c: D.machinery.filter(m => m.status === s).length }));
  const costItems = E.rows.map((r, i) => ({ label: r.m.name, value: r.cost, color: SERIES[0] })).sort((a, b) => b.value - a.value).slice(0, 10);
  const months = lastMonths(12);
  const hoursByMonth = Object.fromEntries(months.map(m => [m, 0]));
  D.machinery_usage.forEach(u => { const d = toDate(u.date_used); if (d && monthKey(d) in hoursByMonth) hoursByMonth[monthKey(d)] += n(u.hours_worked); });
  const kbs = [...new Map(E.rows.map(r => [r.kb.name, r.kb])).values()];
  return `
    <div class="stat-grid">
      ${statusCounts.map(x => `<div class="stat-card"><div class="label">${x.s.replace(/_/g, ' ').replace(/^./, c => c.toUpperCase())}</div><div class="value ${x.s === 'operational' ? 'olive' : x.s === 'out_of_service' ? 'rust' : 'ochre'}">${x.c}</div></div>`).join('')}
      <div class="stat-card"><div class="label">Maintenance spend</div><div class="value slate num">${money(E.rows.reduce((s, r) => s + r.cost, 0))}</div></div>
    </div>
    <div class="panel"><h3>Service status</h3>
      ${E.rows.length ? `<div class="table-wrap ai-flat"><table><thead><tr><th>Machine</th><th>Type</th><th>Status</th><th>Hours</th><th>Last service</th><th>Next service</th><th>Fuel L/h</th></tr></thead><tbody>
        ${E.rows.map(r => `<tr>
          <td>${esc(r.m.name)}</td><td>${esc(r.m.type)}</td>
          <td><span class="pill pill-${r.m.status === 'operational' ? 'olive' : r.m.status === 'out_of_service' ? 'rust' : 'ochre'}">${esc(String(r.m.status).replace(/_/g, ' '))}</span></td>
          <td class="num">${fmtNum(r.m.current_operating_hours)}</td>
          <td>${r.last ? fmtDate(toDate(r.last.service_date)) : '<span class="ai-muted">none</span>'}</td>
          <td>${r.remaining === null ? '<span class="ai-muted">unknown</span>' : r.remaining <= 0 ? `<span class="pill pill-rust">${fmtNum(-r.remaining)} h overdue</span>` : r.remaining <= 25 ? `<span class="pill pill-ochre">in ${fmtNum(r.remaining)} h</span>` : `in ${fmtNum(r.remaining)} h`}</td>
          <td class="num">${r.fuelRate ? fmtNum(r.fuelRate, 1) : '—'}</td>
        </tr>`).join('')}</tbody></table></div>` : `<p class="ai-muted">No machinery recorded yet. <a href="#/machinery">Add your equipment</a>.</p>`}
      <div style="height:12px"></div>
    </div>
    <div class="panel-grid ai-even">
      <div class="panel"><h3>Maintenance cost by machine</h3>${hbar(costItems, { fmt: money, valueLabel: 'Cost', empty: 'No maintenance costs recorded.' })}<div style="height:12px"></div></div>
      <div class="panel"><h3>Machine hours worked per month</h3>${bar(months.map(monthLabel), [{ name: 'Hours', color: SERIES[1], values: months.map(m => hoursByMonth[m]) }], { fmt: v => fmtNum(v, 1) + ' h', empty: 'Log machine use under Usage Logs to see working hours.' })}<div style="height:12px"></div></div>
    </div>
    <div class="panel"><h3>Suggestions for your equipment</h3>${suggestionList(A.suggestions.filter(s => s.area === 'Equipment'), esc)}</div>
    ${kbs.length ? `<div class="panel"><h3>Maintenance guide for your equipment</h3><div class="ai-kb-grid">${kbs.map(kb => `
      <div class="ai-kb"><h4>${esc(kb.name)}</h4><p class="ai-kb-meta">Typical service interval: about ${kb.interval} hours</p>
        <p class="ai-subhead">Before each use</p><ul class="ai-bullets">${kb.daily.map(t => `<li>${esc(t)}</li>`).join('')}</ul>
        <p class="ai-subhead">Periodic service</p><ul class="ai-bullets">${kb.periodic.map(t => `<li>${esc(t)}</li>`).join('')}</ul>
        <p class="ai-subhead">Storage</p><ul class="ai-bullets">${kb.storage.map(t => `<li>${esc(t)}</li>`).join('')}</ul>
      </div>`).join('')}</div></div>` : ''}`;
}

function tabPests(D, A, ALL, esc){
  const P = A.pests;
  const months = lastMonths(12);
  const sevs = ['low', 'moderate', 'high', 'severe'];
  const counts = Object.fromEntries(sevs.map(s => [s, Object.fromEntries(months.map(m => [m, 0]))]));
  D.scouting_records.forEach(s => { const d = toDate(s.scout_date); const sv = sevs.includes(s.severity_level) ? s.severity_level : 'low'; if (d && monthKey(d) in counts[sv]) counts[sv][monthKey(d)]++; });
  const chart = bar(months.map(monthLabel), sevs.map(s => ({ name: s[0].toUpperCase() + s.slice(1), color: SEVERITY[s], values: months.map(m => counts[s][m]) })), { stacked: true, fmt: v => fmtNum(v) + ' record' + (v === 1 ? '' : 's'), empty: 'No scouting records in the last 12 months.' });
  const effect = {};
  D.chemical_applications.forEach(a => { effect[a.effectiveness || 'pending'] = (effect[a.effectiveness || 'pending'] || 0) + 1; });
  const effColors = { effective: INCOME, partially_effective: '#C7861A', ineffective: EXPENSE, pending: '#A08C76' };
  // guidance cards for active threats, then for catalogue entries not yet seen
  const seen = new Set(P.threatList.map(t => t.key));
  const catalogueOnly = D.pest_disease_catalog.filter(c => !seen.has(String(c.id))).slice(0, 6).map(c => ({
    name: c.name, type: c.type, cat: c, kb: matchKb(`${c.name} ${c.symptoms || ''}`, PEST_KB) || PEST_GENERIC[c.type] || PEST_GENERIC.pest, catalogueOnly: true,
  }));
  const guide = [...P.threatList, ...catalogueOnly];

  return `
    <div class="stat-grid">
      <div class="stat-card"><div class="label">Scouting records (90 days)</div><div class="value olive">${P.recent.length}</div></div>
      <div class="stat-card"><div class="label">Active threats</div><div class="value ${P.threatList.some(t => t.maxSev >= 3) ? 'rust' : 'ochre'}">${P.threatList.length}</div></div>
      <div class="stat-card"><div class="label">Chemical applications</div><div class="value slate">${D.chemical_applications.length}</div></div>
      <div class="stat-card"><div class="label">Pest pressure score</div><div class="value ${A.scores.pests !== null && A.scores.pests < 50 ? 'rust' : 'olive'}">${A.scores.pests === null ? 'n/a' : Math.round(A.scores.pests)}</div></div>
    </div>
    <div class="panel"><h3>Threat board (last 90 days)</h3>
      ${P.threatList.length ? `<div class="table-wrap ai-flat"><table><thead><tr><th>Pest / disease / weed</th><th>Type</th><th>Worst level</th><th>Records</th><th>Fields</th><th>Avg. area hit</th><th>Last seen</th></tr></thead><tbody>
        ${P.threatList.map(t => `<tr>
          <td>${esc(t.name)}</td><td>${esc(t.type || '')}</td>
          <td><span class="pill pill-${t.maxSev >= 3 ? 'rust' : t.maxSev === 2 ? 'ochre' : 'neutral'}">${esc(t.maxSevName)}</span></td>
          <td class="num">${t.count}</td><td>${esc([...t.fields].join(', '))}</td>
          <td class="num">${t.area.length ? fmtNum(t.area.reduce((a, b) => a + b, 0) / t.area.length, 1) + '%' : '—'}</td>
          <td class="num">${fmtDate(t.last)}</td></tr>`).join('')}
      </tbody></table></div>` : `<p class="ai-muted">No pests or diseases scouted in the last 90 days. Keep scouting weekly and record what you find.</p>`}
      <div style="height:12px"></div>
    </div>
    <div class="panel-grid ai-even">
      <div class="panel"><h3>Pest &amp; disease pressure by month</h3>${chart}<div style="height:12px"></div></div>
      <div class="panel"><h3>Treatment effectiveness</h3>${hbar(Object.entries(effect).map(([k, v]) => ({ label: k.replace(/_/g, ' '), value: v, color: effColors[k] || SERIES[0] })), { fmt: v => fmtNum(v), valueLabel: 'Applications', empty: 'No chemical applications recorded.' })}
        <div class="ai-spray" data-spray style="margin-top:10px;">${sprayPlaceholder(D, ALL)}</div><div style="height:12px"></div></div>
    </div>
    <div class="panel"><h3>Pest control actions</h3>${suggestionList(A.suggestions.filter(s => s.area === 'Pests' || (s.area === 'Inventory' && /chemical|spray|pesticide|fungicide|herbicide/i.test(s.title))), esc, { empty: 'No pest control actions needed right now.' })}</div>
    <div class="panel"><h3>How to control or manage them</h3>
      ${guide.length ? `<div class="ai-kb-grid">${guide.map(t => `
        <div class="ai-kb">
          <h4>${esc(t.name)} ${t.maxSevName && !t.catalogueOnly ? `<span class="pill pill-${t.maxSev >= 3 ? 'rust' : t.maxSev === 2 ? 'ochre' : 'neutral'}">${esc(t.maxSevName)}</span>` : '<span class="pill pill-neutral">in catalogue</span>'}</h4>
          <p class="ai-kb-meta">${esc(t.kb.name)}</p>
          ${t.cat && t.cat.recommended_control ? `<p class="ai-subhead">Your catalogue’s recommended control</p><p class="ai-kb-text">${esc(t.cat.recommended_control)}</p>` : ''}
          <p class="ai-subhead">Monitor</p><p class="ai-kb-text">${esc(t.kb.monitor)}</p>
          <p class="ai-subhead">Cultural &amp; prevention</p><ul class="ai-bullets">${t.kb.cultural.map(x => `<li>${esc(x)}</li>`).join('')}</ul>
          ${t.kb.biological.length ? `<p class="ai-subhead">Biological &amp; low-toxicity</p><ul class="ai-bullets">${t.kb.biological.map(x => `<li>${esc(x)}</li>`).join('')}</ul>` : ''}
          <p class="ai-subhead">Chemical (last resort, rotate groups)</p><ul class="ai-bullets">${t.kb.chemical.map(x => `<li>${esc(x)}</li>`).join('')}</ul>
        </div>`).join('')}</div>` : `<p class="ai-muted">Add pests, diseases and weeds to the <a href="#/pest_disease_catalog">Pest &amp; Disease Catalogue</a> and record scouting, and control guidance for each will appear here.</p>`}
      <p class="help-text" style="margin:6px 0 14px;">${esc(SAFETY_NOTE)}</p>
    </div>`;
}

function tabFinance(D, A, ALL, esc){
  const F = A.finance;
  const cats = F.months.map(monthLabel);
  const expItems = Object.entries(F.expCat).sort((a, b) => b[1] - a[1]).slice(0, 10).map(([k, v]) => ({ label: k, value: v, color: EXPENSE }));
  const incItems = Object.entries(F.incCat).sort((a, b) => b[1] - a[1]).slice(0, 10).map(([k, v]) => ({ label: k, value: v, color: INCOME }));
  const cumSeries = [{ name: 'Cumulative profit / loss', color: NET, points: F.months.map((m, i) => [new Date(+m.slice(0, 4), +m.slice(5) - 1, 15), F.cumulative[i]]) }];
  const netV = F.totalInc - F.totalExp;
  return `
    <div class="stat-grid">
      <div class="stat-card"><div class="label">Income</div><div class="value olive num">${money(F.totalInc)}</div></div>
      <div class="stat-card"><div class="label">Expenses</div><div class="value rust num">${money(F.totalExp)}</div></div>
      <div class="stat-card"><div class="label">Net profit / loss</div><div class="value ${netV < 0 ? 'rust' : 'olive'} num">${money(netV)}</div></div>
      <div class="stat-card"><div class="label">Margin</div><div class="value slate num">${F.totalInc ? Math.round(F.margin * 100) + '%' : '—'}</div></div>
      <div class="stat-card"><div class="label">Owed by customers</div><div class="value ochre num">${money(F.receivable)}</div></div>
      <div class="stat-card"><div class="label">Net per hectare</div><div class="value slate num">${F.area ? money(netV / F.area) : '—'}</div></div>
    </div>
    <div class="panel"><h3>Income vs expenses by month</h3>
      ${bar(cats, [{ name: 'Income', color: INCOME, values: F.months.map(m => F.inc[m]) }, { name: 'Expenses', color: EXPENSE, values: F.months.map(m => F.exp[m]) }], { fmt: money, title: 'Income and expenses by month', empty: 'Record income and expenses under Transactions to see this chart.' })}
      <div style="height:12px"></div>
    </div>
    <div class="panel-grid ai-even">
      <div class="panel"><h3>Monthly profit / loss</h3>${bar(cats, [{ name: 'Net', color: INCOME, values: F.net }], { colorFor: v => v >= 0 ? INCOME : EXPENSE, fmt: money, empty: 'No transactions in the last 12 months.' })}<div style="height:12px"></div></div>
      <div class="panel"><h3>Cumulative profit / loss (12 months)</h3>${F.net.some(v => v) ? line(cumSeries, { fmt: money, valueLabel: 'Cumulative net' }) : '<div class="ai-chart-empty">No transactions in the last 12 months.</div>'}<div style="height:12px"></div></div>
    </div>
    <div class="panel-grid ai-even">
      <div class="panel"><h3>Where the money goes</h3>${hbar(expItems, { fmt: money, valueLabel: 'Expense', empty: 'No expenses recorded.' })}<div style="height:12px"></div></div>
      <div class="panel"><h3>Where the money comes from</h3>${hbar(incItems, { fmt: money, valueLabel: 'Income', empty: 'No income recorded.' })}<div style="height:12px"></div></div>
    </div>
    <div class="panel"><h3>Financial suggestions</h3>${suggestionList(A.suggestions.filter(s => s.area === 'Finance'), esc)}</div>`;
}

function tabActions(D, A, ALL, esc){
  const areas = [...new Set(A.suggestions.map(s => s.area))];
  return `
    <div class="ai-counts" style="margin-bottom:14px;">
      ${Object.keys(SEV).map(k => `<span>${sevPill(k)} <b class="num">${A.counts[k]}</b></span>`).join('')}
    </div>
    ${areas.map(area => `<div class="panel"><h3>${esc(area)}</h3>${suggestionList(A.suggestions.filter(s => s.area === area), esc)}</div>`).join('')}`;
}

/* ---------- live spray / field-work window (Open-Meteo, no key) ---------- */
function sprayPlaceholder(D, ALL){
  const farm = (D.farms.length ? D.farms : ALL.farms).find(f => has(f.latitude) && has(f.longitude));
  return farm ? '<p class="ai-muted">Checking the 3-day forecast…</p>' : '<p class="ai-muted">Save the farm’s location (Farms → Edit → map) to get spray and field-work windows from the live forecast.</p>';
}

async function loadSprayWindow(farms, esc){
  const farm = farms.find(f => has(f.latitude) && has(f.longitude));
  const targets = () => document.querySelectorAll('[data-spray]');
  if (!farm || !targets().length) return;
  try{
    if (!state.weather || state.weather.farmId !== farm.id){
      const url = `https://api.open-meteo.com/v1/forecast?latitude=${farm.latitude}&longitude=${farm.longitude}&daily=temperature_2m_max,precipitation_sum,precipitation_probability_max,wind_speed_10m_max,relative_humidity_2m_mean&forecast_days=3&timezone=auto`;
      const res = await fetch(url);
      if (!res.ok) throw new Error('forecast unavailable');
      state.weather = { farmId: farm.id, data: await res.json() };
    }
    const d = state.weather.data.daily || {};
    const rows = (d.time || []).map((t, i) => {
      const rain = n(d.precipitation_sum?.[i]), prob = n(d.precipitation_probability_max?.[i]), wind = n(d.wind_speed_10m_max?.[i]), temp = n(d.temperature_2m_max?.[i]), hum = n(d.relative_humidity_2m_mean?.[i]);
      let verdict, cls;
      if (rain >= 5 || prob >= 60){ verdict = 'Rain likely — don’t spray; good for planting/top-dressing if soil allows'; cls = 'ochre'; }
      else if (wind > 20){ verdict = 'Too windy to spray — drift risk'; cls = 'rust'; }
      else if (temp >= 32){ verdict = 'Hot — spray only early morning or evening; watch livestock heat stress'; cls = 'ochre'; }
      else { verdict = 'Good spray window (calm and dry)'; cls = 'olive'; }
      const dayLabel = new Date(t + 'T00:00:00').toLocaleDateString(undefined, { weekday: 'short', day: 'numeric', month: 'short' });
      const extra = hum >= 80 ? ' · humid: fungal risk' : '';
      return `<li><span class="pill pill-${cls}">${esc(dayLabel)}</span> ${esc(verdict)}<span class="ai-muted"> · ${fmtNum(temp, 0)}°C, wind ${fmtNum(wind, 0)} km/h, rain ${fmtNum(rain, 1)} mm${extra}</span></li>`;
    });
    targets().forEach(el => { el.innerHTML = `<ul class="ai-weather">${rows.join('')}</ul><p class="help-text" style="margin:6px 0 0;">Live forecast for ${esc(farm.farm_name)} from Open-Meteo.</p>`; });
  }catch(e){
    targets().forEach(el => { el.innerHTML = '<p class="ai-muted">Live forecast unavailable right now. Check local conditions before spraying.</p>'; });
  }
}
