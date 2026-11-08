/* ==========================================================================
   Farm assistant — the chat on the AI Farm Overview Analysis page.

   Two ways of answering:
   - With Claude, when the backend has ANTHROPIC_API_KEY set
     (api/ai_chat.php). The page sends a compact summary of the records it
     has already loaded, so the assistant only ever sees the farm(s) this
     person is allowed to see.
   - Built-in, otherwise (or if Claude can't be reached): answers from the
     same analysis and knowledge base that drive the rest of the page.
   ========================================================================== */
import { Api } from './api.js';
import { CROP_KB, LIVESTOCK_KB, EQUIPMENT_KB, PEST_KB, STAGES, SAFETY_NOTE, SEASON_SOUTH, SEASON_NORTH } from './ai-knowledge.js';
import { fmtNum } from './ai-charts.js';
import { formatMoney } from './currency.js';

const MAX_TURNS = 16;

/* Kept while the app is open, so the conversation survives tab switches. */
const chat = { open: false, key: null, messages: [], claude: null, busy: false };

/* ---------------------------------------------------------------------- */
/* Small helpers (same conventions as ai-overview.js)                     */
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
const iso = d => d ? `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` : '?';
const nice = d => d ? d.toLocaleDateString(undefined, { day: 'numeric', month: 'short' }) : '?';
/* Set from the page on every question: the currency the page shows money in. */
let CUR = '';
const money = v => CUR ? formatMoney(v, CUR, 0) : fmtNum(v, 2);
const words = s => String(s || '').replace(/_/g, ' ');
const plural = (k, one, many = one + 's') => `${fmtNum(k)} ${k === 1 ? one : many}`;
function matchKb(text, kb){
  const s = ' ' + String(text || '').toLowerCase() + ' ';
  return kb.find(e => e.keys.some(k => new RegExp(`[^a-z]${k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`).test(s))) || null;
}

/* ---------------------------------------------------------------------- */
/* Farm summary sent to Claude                                            */
/* ---------------------------------------------------------------------- */
function buildContext(X){
  const { D, A, scopeName, weather } = X;
  CUR = X.currency || '';
  const L = [];
  const today = TODAY();
  const farmById = Object.fromEntries(D.farms.map(f => [String(f.id), f]));
  const fieldById = Object.fromEntries(D.fields.map(f => [String(f.id), f]));
  const many = D.farms.length > 1;

  L.push(`Scope: ${scopeName}. Today: ${iso(today)}.${CUR ? ` All money amounts are in ${CUR}.` : ''}`);
  D.farms.forEach(f => L.push(`Farm: ${f.farm_name}${has(f.total_area_hectares) ? `, ${fmtNum(f.total_area_hectares)} ha` : ''}${f.address ? `, ${f.address}` : ''}${has(f.latitude) ? `, lat ${f.latitude}, long ${f.longitude}` : ''}.`));

  const sc = A.scores;
  const scoreBits = [['crops', 'Crops'], ['livestock', 'Livestock'], ['equipment', 'Equipment'], ['pests', 'Pest & disease'], ['inventory', 'Inventory & tasks'], ['finance', 'Finance']]
    .filter(([k]) => sc[k] !== null && sc[k] !== undefined).map(([k, l]) => `${l} ${Math.round(sc[k])}`);
  if (A.overall !== null) L.push(`Health scores out of 100: overall ${Math.round(A.overall)}; ${scoreBits.join(', ')}.`);
  L.push(`Suggestions: ${A.counts.urgent} urgent, ${A.counts.soon} soon, ${A.counts.routine} routine.`);

  const top = A.suggestions.filter(s => s.sev !== 'good').slice(0, 30);
  if (top.length){
    L.push('', 'Suggestions from the app (most urgent first):');
    top.forEach(s => L.push(`- [${s.sev}] ${s.area}: ${s.title}. ${s.detail}${s.actions && s.actions.length ? ' Advice: ' + s.actions.slice(0, 2).join(' ') : ''}`));
  }

  if (D.fields.length){
    L.push('', 'Fields:');
    D.fields.slice(0, 40).forEach(f => L.push(`- ${f.field_name}${many && farmById[f.farm_id] ? ` (${farmById[f.farm_id].farm_name})` : ''}: ${has(f.area_hectares) ? fmtNum(f.area_hectares) + ' ha' : 'area not set'}${f.soil_type ? ', ' + f.soil_type + ' soil' : ''}${has(f.ph_level) ? ', pH ' + fmtNum(f.ph_level, 1) : ''}${has(f.organic_matter_pct) ? ', organic matter ' + fmtNum(f.organic_matter_pct, 1) + '%' : ''}${f.current_land_use ? ', use: ' + f.current_land_use : ''}`));
  }

  const rows = A.crops.rows.slice().sort((a, b) => (a.p.status === 'active' ? 0 : 1) - (b.p.status === 'active' ? 0 : 1));
  if (rows.length){
    L.push('', 'Crop plantings:');
    rows.slice(0, 40).forEach(r => {
      const p = r.p;
      const f = fieldById[String(p.field_id)];
      const farm = f && farmById[String(f.farm_id)];
      const stage = r.loggedStage !== null ? STAGES[r.loggedStage] : null;
      L.push(`- ${r.label}${many && farm ? ` [${farm.farm_name}]` : ''}: ${p.status}, planted ${p.planting_date || '?'}, expected harvest ${p.expected_harvest_date || '?'}, ${Math.round(Math.min(r.progress, 1) * 100)}% of the way to harvest`
        + (stage ? `, last log ${stage}${r.last.health_status ? ' (' + r.last.health_status + ')' : ''} on ${r.last.log_date}` : ', no growth logs')
        + (r.flags.length ? `, flags: ${r.flags.join(', ')}` : ''));
    });
  }
  const hb = Object.entries(A.crops.harvestByCrop);
  if (hb.length) L.push('', 'Harvests recorded: ' + hb.map(([k, v]) => `${k}: ${fmtNum(v.q)} harvested, ${fmtNum(v.loss)} lost`).join('; ') + '.');

  const LS = A.livestock;
  if (D.livestock.length){
    L.push('', `Livestock on hand: ${Object.entries(LS.bySpecies).map(([s, list]) => `${s} ${list.length}`).join(', ') || 'none active'}.`);
    if (LS.overdue.length) L.push('Overdue animal health treatments: ' + LS.overdue.slice(0, 15).map(o => `${o.a.species} ${o.a.tag_number} ${words(o.r.record_type)} ${-o.days} days overdue`).join('; ') + '.');
    if (LS.dueSoon.length) L.push('Due in the next 14 days: ' + LS.dueSoon.slice(0, 15).map(o => `${o.a.species} ${o.a.tag_number} ${words(o.r.record_type)} in ${o.days} days`).join('; ') + '.');
  }

  if (A.equipment.rows.length){
    L.push('', 'Machinery:');
    A.equipment.rows.slice(0, 30).forEach(r => L.push(`- ${r.m.name} (${r.m.type || 'machine'}): ${words(r.m.status)}, ${fmtNum(r.m.current_operating_hours)} h`
      + (r.remaining !== null ? (r.remaining <= 0 ? `, service overdue by ${fmtNum(-r.remaining)} h` : `, next service in ${fmtNum(r.remaining)} h`) : ', no service history')
      + (r.last ? `, last serviced ${r.last.service_date}` : '')));
  }

  const T = A.pests.threatList;
  if (T.length){
    L.push('', 'Pests and diseases scouted in the last 90 days:');
    T.slice(0, 15).forEach(t => L.push(`- ${t.name} (${t.type}): ${plural(t.count, 'report')}, worst ${t.maxSevName}, last ${iso(t.last)}, on ${[...t.fields].join(', ')}`));
  } else if (D.crop_plantings.length) {
    L.push('', 'No pest or disease scouting reports in the last 90 days.');
  }
  if (D.chemical_applications.length){
    const recentApps = D.chemical_applications.slice().sort((a, b) => toDate(b.application_date) - toDate(a.application_date)).slice(0, 8);
    L.push('Recent chemical applications: ' + recentApps.map(a => `${a.application_date}${has(a.dosage_per_ha) ? ' at ' + fmtNum(a.dosage_per_ha, 2) + '/ha' : ''}${a.effectiveness ? ', ' + words(a.effectiveness) : ''}`).join('; ') + '.');
  }

  const I = A.inventory;
  if (I.low.length) L.push('', 'Low stock: ' + I.low.map(i => `${i.item_name} ${fmtNum(i.current_stock)} ${i.unit_of_measure || ''} (reorder at ${fmtNum(i.reorder_threshold)})`).join('; ') + '.');
  if (I.expiring.length) L.push('Batches expiring within 45 days or expired: ' + I.expiring.length + '.');
  if (D.inventory_items.length) L.push('Inventory items: ' + D.inventory_items.slice(0, 40).map(i => `${i.item_name} ${fmtNum(i.current_stock)} ${i.unit_of_measure || ''}`.trim()).join('; ') + '.');
  if (I.overdueTasks.length) L.push('Overdue tasks: ' + I.overdueTasks.slice(0, 15).map(t => `${t.title} (due ${t.due_date})`).join('; ') + '.');
  const openTasks = D.task_allocations.filter(t => t.status === 'pending' || t.status === 'in_progress');
  if (openTasks.length) L.push('Open tasks: ' + openTasks.slice(0, 20).map(t => `${t.title} (${words(t.status)}, due ${t.due_date || '?'})`).join('; ') + '.');

  const F = A.finance;
  if (D.financial_transactions.length){
    L.push('', `Finance over the last 12 months (recorded transactions): income ${money(F.totalInc)}, expenses ${money(F.totalExp)}, net ${money(F.totalInc - F.totalExp)}, margin ${Math.round(F.margin * 100)}%.`);
    L.push('Monthly net: ' + F.months.map((m, i) => `${m} ${money(F.net[i])}`).join(', ') + '.');
    const ec = Object.entries(F.expCat).sort((a, b) => b[1] - a[1]).slice(0, 6);
    if (ec.length) L.push('Biggest expense categories: ' + ec.map(([k, v]) => `${k} ${money(v)}`).join(', ') + '.');
    const ic = Object.entries(F.incCat).sort((a, b) => b[1] - a[1]).slice(0, 6);
    if (ic.length) L.push('Income categories: ' + ic.map(([k, v]) => `${k} ${money(v)}`).join(', ') + '.');
  }
  if (F.receivable > 0) L.push(`Unpaid sales orders: ${F.unpaid.length}, owed ${money(F.receivable)}.`);

  const wx = weatherDays(weather);
  if (wx.length) L.push('', 'Forecast: ' + wx.map(d => `${d.label} max ${fmtNum(d.temp, 0)}°C, rain ${fmtNum(d.rain, 1)} mm (${fmtNum(d.prob)}% chance), wind ${fmtNum(d.wind, 0)} km/h`).join('; ') + '.');

  return L.join('\n').slice(0, 28000);
}

function weatherDays(weather){
  const d = weather && weather.data && weather.data.daily;
  if (!d || !d.time) return [];
  return d.time.map((t, i) => ({
    label: new Date(t + 'T00:00:00').toLocaleDateString(undefined, { weekday: 'short', day: 'numeric', month: 'short' }),
    temp: n(d.temperature_2m_max?.[i]), rain: n(d.precipitation_sum?.[i]), prob: n(d.precipitation_probability_max?.[i]),
    wind: n(d.wind_speed_10m_max?.[i]), hum: n(d.relative_humidity_2m_mean?.[i]),
  }));
}

/* ---------------------------------------------------------------------- */
/* Built-in answers                                                       */
/* ---------------------------------------------------------------------- */
const list = items => items.filter(Boolean).map(i => `- ${i}`).join('\n');
const link = (label, route) => `[${label}](${route})`;

function priorities(A, filter = null, limit = 6){
  const items = A.suggestions.filter(s => (s.sev === 'urgent' || s.sev === 'soon') && (!filter || filter(s)));
  if (!items.length) return null;
  return list(items.slice(0, limit).map(s => `**${s.title}** (${s.sev === 'urgent' ? 'urgent' : 'soon'}). ${s.actions && s.actions[0] ? s.actions[0] : s.detail}`))
    + (items.length > limit ? `\n\n…and ${items.length - limit} more on the **All suggestions** tab.` : '');
}

function summary(X){
  const { D, A, scopeName } = X;
  const bits = [];
  if (A.overall !== null) bits.push(`The farm health score for ${scopeName} is **${Math.round(A.overall)}/100**.`);
  const active = A.crops.rows.filter(r => r.p.status === 'active');
  if (active.length) bits.push(`${plural(active.length, 'planting')} ${active.length === 1 ? 'is' : 'are'} growing (${[...new Set(active.map(r => r.crop))].slice(0, 4).join(', ')}).`);
  if (A.livestock.animals.length) bits.push(`${plural(A.livestock.animals.length, 'animal')} on hand.`);
  if (D.machinery.length) bits.push(`${A.equipment.operational} of ${D.machinery.length} machines are working.`);
  if (D.financial_transactions.length){
    const net = A.finance.totalInc - A.finance.totalExp;
    bits.push(`Recorded ${net >= 0 ? 'profit' : 'loss'} over 12 months: **${money(Math.abs(net))}**.`);
  }
  const p = priorities(A, null, 4);
  return bits.join(' ') + (p ? `\n\nWhat needs attention first:\n${p}` : '\n\nNothing is urgent right now.');
}

function cropAnswer(kb, X){
  const { A } = X;
  const mine = A.crops.rows.filter(r => matchKb(r.crop, CROP_KB) === kb && (r.p.status === 'active' || r.p.status === 'planned'));
  const out = [];
  if (mine.length){
    out.push(`You have ${plural(mine.length, kb.name.toLowerCase() + ' planting')}:`);
    out.push(list(mine.slice(0, 6).map(r => {
      const stage = STAGES[r.loggedStage ?? r.expectedStage];
      return `**${r.label}**: ${r.p.status}, ${stage.toLowerCase()} stage, about ${Math.round(Math.min(r.progress, 1) * 100)}% of the way to harvest${r.daysToHarvest !== null && r.daysToHarvest >= 0 ? ` (harvest in ~${r.daysToHarvest} days)` : ''}${r.flags.length ? `. Watch: ${r.flags.join(', ').toLowerCase()}` : ''}`;
    })));
    const stage = STAGES[mine[0].loggedStage ?? mine[0].expectedStage];
    const tips = kb.stages[stage] || [];
    if (tips.length) out.push(`\n**What to do at the ${stage.toLowerCase()} stage:**\n${list(tips)}`);
  } else {
    out.push(`Here is how to look after **${kb.name.toLowerCase()}**:`);
    out.push(list(STAGES.map(s => kb.stages[s] && kb.stages[s][0] ? `**${s}:** ${kb.stages[s][0]}` : null)));
  }
  out.push(`\n**General care:**\n${list([...(kb.care || []), `Best soil pH is ${kb.ph[0]}–${kb.ph[1]}.`])}`);
  const issues = priorities(A, s => s.area === 'Crops' && s.title.toLowerCase().includes(kb.name.toLowerCase()), 3);
  if (issues) out.push(`\n**From your records:**\n${issues}`);
  return out.join('\n');
}

function pestAnswer(kb, X){
  const { A } = X;
  const seen = A.pests.threatList.filter(t => t.kb === kb || matchKb(t.name, PEST_KB) === kb);
  const out = [];
  if (seen.length){
    const t = seen[0];
    out.push(`**${kb.name}** was reported ${plural(t.count, 'time')} in the last 90 days on ${[...t.fields].join(', ')}, worst level **${t.maxSevName}** (last ${nice(t.last)}).`);
  } else {
    out.push(`There are no scouting reports of **${kb.name.toLowerCase()}** in the last 90 days. Here is how to manage it:`);
  }
  out.push(`\n**Monitor:** ${kb.monitor}`);
  if (kb.cultural?.length) out.push(`\n**Cultural control:**\n${list(kb.cultural)}`);
  if (kb.biological?.length) out.push(`\n**Biological control:**\n${list(kb.biological)}`);
  if (kb.chemical?.length) out.push(`\n**Chemical control:**\n${list(kb.chemical)}`);
  out.push(`\n${SAFETY_NOTE}`);
  return out.join('\n');
}

function pestsOverview(X){
  const { A } = X;
  const T = A.pests.threatList;
  if (!T.length) return `No pests or diseases have been scouted in the last 90 days. Keep scouting each field weekly and record what you find under ${link('Scouting Records', '#/scouting_records')}.`;
  const out = [`Pests and diseases seen in the last 90 days:`, list(T.slice(0, 6).map(t => `**${t.name}**: ${plural(t.count, 'report')}, worst ${t.maxSevName}, on ${[...t.fields].slice(0, 3).join(', ')}`))];
  const top = T[0].kb;
  if (top && top.chemical) out.push(`\nFor **${T[0].name}**, the first steps are:\n${list([top.cultural?.[0], top.biological?.[0], top.chemical?.[0]])}`);
  const p = priorities(A, s => s.area === 'Pests', 3);
  if (p) out.push(`\n**Needs action:**\n${p}`);
  out.push(`\nAsk me about a specific pest (for example "fall armyworm") for full control advice.`);
  return out.join('\n');
}

function weatherAnswer(X){
  const days = weatherDays(X.weather);
  if (!days.length) return `I don't have a forecast yet. Save the farm's location under ${link('Farms', '#/farms')} and open the Overview or Pest & disease tab to load the 3-day forecast.`;
  return 'The next 3 days:\n' + list(days.map(d => {
    let v;
    if (d.rain >= 5 || d.prob >= 60) v = 'rain likely, so don’t spray';
    else if (d.wind > 20) v = 'too windy to spray';
    else if (d.temp >= 32) v = 'hot, so spray only early or late';
    else v = 'good spray window';
    return `**${d.label}**: ${v} (${fmtNum(d.temp, 0)}°C, wind ${fmtNum(d.wind, 0)} km/h, rain ${fmtNum(d.rain, 1)} mm${d.hum >= 80 ? ', humid so fungal risk is higher' : ''})`;
  })) + `\n\n${SAFETY_NOTE}`;
}

function livestockAnswer(kb, X){
  const { A } = X;
  const out = [];
  const mine = kb ? A.livestock.animals.filter(a => matchKb(a.species, LIVESTOCK_KB) === kb) : A.livestock.animals;
  const name = kb ? kb.name.toLowerCase() : 'animals';
  out.push(mine.length ? `You have **${plural(mine.length, kb ? kb.name.toLowerCase().replace(/s$/, '') : 'animal')}** on hand.` : `There are no active ${name} on record.`);
  const due = [...A.livestock.overdue.map(o => ({ ...o, over: true })), ...A.livestock.dueSoon]
    .filter(o => !kb || matchKb(o.a.species, LIVESTOCK_KB) === kb);
  if (due.length) out.push(`\n**Health treatments:**\n${list(due.slice(0, 6).map(o => `${o.a.species} ${o.a.tag_number}: ${words(o.r.record_type)} ${o.over ? `**overdue by ${-o.days} days**` : `due in ${o.days} days`}`))}`);
  if (kb){
    out.push(`\n**Feeding:**\n${list(kb.feeding)}`);
    out.push(`\n**Health:**\n${list(kb.health)}`);
    if (kb.housing?.length) out.push(`\n**Housing:**\n${list(kb.housing)}`);
    if (kb.signs?.length) out.push(`\n**Call the vet if you see:** ${kb.signs.join(' ')}`);
  } else if (Object.keys(A.livestock.bySpecies).length){
    out.push(`\nBy species: ${Object.entries(A.livestock.bySpecies).map(([s, l]) => `${s} ${l.length}`).join(', ')}. Ask about one (for example "goats") for care advice.`);
  }
  return out.join('\n');
}

function healthDueAnswer(kb, X){
  const { A } = X;
  const due = [...A.livestock.overdue.map(o => ({ ...o, over: true })), ...A.livestock.dueSoon]
    .filter(o => !kb || matchKb(o.a.species, LIVESTOCK_KB) === kb);
  if (!due.length) return `No vaccinations or treatments are overdue or due in the next 14 days${kb ? ' for ' + kb.name.toLowerCase() : ''}, going by the next-due dates in ${link('Health Records', '#/livestock_health_records')}.`;
  return `Animal health treatments coming up:\n${list(due.slice(0, 10).map(o => `${o.a.species} ${o.a.tag_number}: ${words(o.r.record_type)}${o.r.diagnosis ? ' (' + o.r.diagnosis + ')' : ''} ${o.over ? `**overdue by ${-o.days} days**` : `due in ${o.days} days`}`))}\n\nRecord each one in ${link('Health Records', '#/livestock_health_records')} with the next due date once done.`;
}

function equipmentAnswer(kb, X){
  const { A, D } = X;
  if (!D.machinery.length && !kb) return `There is no machinery on record yet. Add it under ${link('Machinery', '#/machinery')} with the hour-meter reading and the system will track services.`;
  // Most urgent first: overdue, then due soonest, then no service history.
  const urgency = r => r.m.status === 'out_of_service' ? -1e9 : r.remaining === null ? 1e9 : r.remaining;
  const rows = (kb ? A.equipment.rows.filter(r => r.kb === kb) : A.equipment.rows).slice().sort((a, b) => urgency(a) - urgency(b));
  const out = [];
  if (rows.length){
    out.push(list(rows.slice(0, 8).map(r => `**${r.m.name}**: ${words(r.m.status)}, ${fmtNum(r.m.current_operating_hours)} h, ${r.remaining === null ? 'no service history' : r.remaining <= 0 ? `**service overdue by ${fmtNum(-r.remaining)} h**` : `next service in ${fmtNum(r.remaining)} h`}`)));
  }
  const tips = kb || (rows[0] && rows[0].kb);
  if (tips && kb){
    out.push(`\n**${tips.name}: daily checks**\n${list(tips.daily || [])}`);
    out.push(`\n**Regular service**\n${list(tips.periodic || [])}`);
    if (tips.storage?.length) out.push(`\n**Storage**\n${list(tips.storage)}`);
  } else if (tips && rows[0]){
    out.push(`\n**Start with ${rows[0].m.name}:**\n${list(tips.periodic || [])}`);
    out.push(`\nLog each service under ${link('Maintenance', '#/machinery_maintenance')} with the hour-meter reading. Ask about one type (for example "tractor") for daily checks.`);
  }
  return out.join('\n');
}

function harvestAnswer(X){
  const { A } = X;
  const soon = A.crops.rows.filter(r => r.p.status === 'active' && r.daysToHarvest !== null).sort((a, b) => a.daysToHarvest - b.daysToHarvest);
  const out = [];
  if (soon.length) out.push(`Upcoming harvests:\n${list(soon.slice(0, 6).map(r => `**${r.label}**: ${r.daysToHarvest < 0 ? `**${-r.daysToHarvest} days past** the expected date` : `in about ${r.daysToHarvest} days`}`))}`);
  else out.push('No active plantings have an expected harvest date.');
  const hb = Object.entries(A.crops.harvestByCrop);
  if (hb.length) out.push(`\nHarvested so far:\n${list(hb.map(([k, v]) => `${k}: ${fmtNum(v.q)} harvested${v.loss ? `, ${fmtNum(v.loss)} lost (${Math.round(v.loss / (v.q + v.loss) * 100)}%)` : ''}`))}`);
  out.push(`\nBefore harvest: book labour and machinery, service the harvester or sheller, and check storage space, bags and grain protectants.`);
  return out.join('\n');
}

function financeAnswer(X){
  const { A, D } = X;
  const F = A.finance;
  if (!D.financial_transactions.length) return `No income or expenses are recorded yet, so I can't work out profit and loss. Start with this season's inputs, labour and sales under ${link('Transactions', '#/financial_transactions')}.`;
  const net = F.totalInc - F.totalExp;
  const out = [`Over the last 12 months you recorded **${money(F.totalInc)}** income and **${money(F.totalExp)}** expenses, a **${net >= 0 ? 'profit' : 'loss'} of ${money(Math.abs(net))}** (${Math.round(F.margin * 100)}% margin).`];
  const ec = Object.entries(F.expCat).sort((a, b) => b[1] - a[1]).slice(0, 3);
  if (ec.length) out.push(`\nBiggest costs:\n${list(ec.map(([k, v]) => `${k}: ${money(v)} (${Math.round(v / F.totalExp * 100)}%)`))}`);
  const lastNet = F.net.slice(-3);
  out.push(`\nLast 3 months net: ${F.months.slice(-3).map((m, i) => money(lastNet[i])).join(', ')}.`);
  if (F.receivable > 0) out.push(`\nCustomers owe **${money(F.receivable)}** on ${plural(F.unpaid.length, 'unpaid order')}. Following these up frees cash for inputs.`);
  const p = priorities(A, s => s.area === 'Finance', 3);
  if (p) out.push(`\n${p}`);
  return out.join('\n');
}

function inventoryAnswer(X){
  const { A, D } = X;
  const I = A.inventory;
  const out = [];
  if (I.low.length) out.push(`Low or out of stock:\n${list(I.low.slice(0, 8).map(i => `**${i.item_name}**: ${fmtNum(i.current_stock)} ${i.unit_of_measure || ''} left (reorder at ${fmtNum(i.reorder_threshold)})`))}`);
  else if (D.inventory_items.length) out.push('Nothing is below its reorder point.');
  else out.push(`No inventory items are recorded yet. Add them under ${link('Inventory Items', '#/inventory_items')}.`);
  const exp = priorities(A, s => s.area === 'Inventory' && /expire/.test(s.title), 4);
  if (exp) out.push(`\nExpiry:\n${exp}`);
  if (I.low.length) out.push(`\nRaise a ${link('purchase order', '#/purchase_orders')} now so stock arrives before it's needed.`);
  return out.join('\n');
}

function tasksAnswer(X){
  const { A, D } = X;
  const open = D.task_allocations.filter(t => t.status === 'pending' || t.status === 'in_progress')
    .sort((a, b) => (toDate(a.due_date) || 0) - (toDate(b.due_date) || 0));
  if (!open.length) return `There are no open tasks. Plan work under ${link('Tasks', '#/task_allocations')}.`;
  const today = TODAY();
  return `Open tasks (${open.length}):\n${list(open.slice(0, 8).map(t => {
    const due = toDate(t.due_date);
    const late = due && due < today;
    return `**${t.title}**: ${words(t.status)}${due ? (late ? `, **${daysBetween(due, today)} days overdue**` : `, due ${nice(due)}`) : ''}`;
  }))}`;
}

function soilAnswer(X){
  const { D, A } = X;
  if (!D.fields.length) return `No fields are recorded yet. Add them under ${link('Fields', '#/fields')} with a soil test (pH and organic matter).`;
  const out = [list(D.fields.slice(0, 8).map(f => `**${f.field_name}**: ${has(f.ph_level) ? 'pH ' + fmtNum(f.ph_level, 1) : 'no pH on record'}${has(f.organic_matter_pct) ? ', organic matter ' + fmtNum(f.organic_matter_pct, 1) + '%' : ''}${f.soil_type ? ', ' + f.soil_type : ''}`))];
  const p = priorities(A, s => s.area === 'Crops' && /pH|organic/i.test(s.title), 4) || list(A.suggestions.filter(s => /pH|organic/i.test(s.title)).slice(0, 3).map(s => `${s.title}. ${s.actions?.[0] || ''}`));
  if (p) out.push(`\n${p}`);
  out.push('\nMost crops do best between pH 5.5 and 7. Lime acid soils based on a soil test, ideally before planting, and add manure, compost or crop residues to build organic matter.');
  return out.join('\n');
}

function seasonAnswer(X){
  const farm = X.D.farms.find(f => has(f.latitude)) || X.D.farms[0];
  const south = !farm || !has(farm.latitude) || n(farm.latitude) < 0;
  const cal = south ? SEASON_SOUTH : SEASON_NORTH;
  const m = new Date().getMonth();
  const name = i => new Date(2000, i, 1).toLocaleDateString(undefined, { month: 'long' });
  return `**${name(m)}:**\n${list(cal[m] || [])}\n\n**Coming up in ${name((m + 1) % 12)}:**\n${list(cal[(m + 1) % 12] || [])}\n\nThis follows the ${south ? 'southern' : 'northern'}-hemisphere calendar, based on the farm's saved location.`;
}

function helpAnswer(X){
  return `I can answer questions about ${X.scopeName} and about farming in general. Try:\n${list([
    'What needs my attention this week?',
    'How are my maize plantings doing?',
    'How do I control fall armyworm?',
    'Which animals are due for vaccination?',
    'Which machines need a service?',
    'Are we making a profit?',
    'What is low in stock?',
    'Is it a good time to spray?',
  ])}`;
}

function localAnswer(q, X){
  CUR = X.currency || '';
  const s = ' ' + q.toLowerCase() + ' ';
  const pest = matchKb(s, PEST_KB);
  const crop = matchKb(s, CROP_KB);
  const animal = matchKb(s, LIVESTOCK_KB);
  const machine = matchKb(s, EQUIPMENT_KB);
  const is = re => re.test(s);

  if (is(/^\s*(hi|hello|hey|good (morning|afternoon|evening)|thanks|thank you)\b/) && s.trim().split(/\s+/).length <= 4)
    return is(/thank/) ? 'You’re welcome. Ask me anything else about the farm.' : helpAnswer(X);
  if (is(/\b(help|what can you|how do you work|what do you know)\b/)) return helpAnswer(X);
  if (pest && !is(/\bweather|forecast\b/)) return pestAnswer(pest, X);
  if (is(/\b(weather|forecast|rain|wind|spray(ing)? (window|today|tomorrow)|good time to spray|can i spray)\b/)) return weatherAnswer(X);
  if (is(/\b(vaccin|deworm|dip(ping)?|vet|jab|injection|treatment|health record)/)) return healthDueAnswer(animal, X);
  if (animal) return livestockAnswer(animal, X);
  if (machine) return equipmentAnswer(machine, X);
  if (is(/\b(machine|machinery|equipment|service|maintenance|engine|repair|hours?)\b/)) return equipmentAnswer(null, X);
  if (is(/\b(harvest|yield|ready to pick|reap)/)) return harvestAnswer(X);
  if (is(/\b(profit|loss|money|income|expense|spend|spent|cost|financ|cash|revenue|earn|owe|owed|debt|paid|budget)/)) return financeAnswer(X);
  if (is(/\b(stock|inventory|reorder|expir|run(ning)? out|supplies)/)) return inventoryAnswer(X);
  if (is(/\b(task|labou?r|worker|job|chore)/)) return tasksAnswer(X);
  if (is(/\b(soil|ph|lime|liming|organic matter|acid)\b/)) return soilAnswer(X);
  if (crop) return cropAnswer(crop, X);
  if (is(/\b(pest|disease|insect|bug|worm|fung|blight|mildew|rust|rot|scout|spray|weed)/)) return pestsOverview(X);
  if (is(/\b(season|this month|next month|calendar|what (should|can) i (plant|grow)|when (should i|to) plant)/)) return seasonAnswer(X);
  if (is(/\b(urgent|priorit|attention|today|this week|to ?do|should i|next|focus|problem|issue|wrong|worry|risk)/)) {
    const p = priorities(X.A, null, 8);
    return p ? `Here is what needs attention first:\n${p}` : 'Nothing is urgent or due soon right now. Keep your logs up to date so the analysis stays accurate.';
  }
  if (is(/\b(crop|plant|grow|field)/)) {
    const active = X.A.crops.rows.filter(r => r.p.status === 'active');
    if (!active.length) return `There are no active plantings. Record a planting under ${link('Crop Plantings', '#/crop_plantings')}.`;
    return `Active plantings:\n${list(active.slice(0, 8).map(r => `**${r.label}**: ${STAGES[r.loggedStage ?? r.expectedStage].toLowerCase()} stage, ${Math.round(Math.min(r.progress, 1) * 100)}% of the way to harvest${r.flags.length ? ` (${r.flags.join(', ').toLowerCase()})` : ''}`))}\n\nAsk about one crop (for example "maize") for stage-by-stage care.`;
  }
  if (is(/\b(animal|livestock|herd|flock|cattle|chicken)/)) return livestockAnswer(null, X);
  if (is(/\b(how (is|are)|summary|overview|status|score|doing|going|farm)\b/)) return summary(X);

  return `I couldn't match that to your records or my built-in farm guides. ${chat.claude === false ? 'Full free-text answers need the Claude connection to be switched on by your administrator. ' : ''}${helpAnswer(X)}`;
}

/* ---------------------------------------------------------------------- */
/* Rendering                                                              */
/* ---------------------------------------------------------------------- */
function inline(text, esc){
  return esc(text)
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\[([^\]]+)\]\((#\/[a-z_]+)\)/g, '<a href="$2">$1</a>');
}
/** Minimal, safe formatting: paragraphs, "- " / "1. " lists, **bold**, in-app links. */
function format(text, esc){
  const blocks = String(text).replace(/\r/g, '').split(/\n{2,}/);
  return blocks.map(b => {
    const lines = b.split('\n');
    const html = [];
    let listTag = null;
    lines.forEach(l => {
      const m = l.match(/^\s*(?:[-*•]|(\d+)[.)])\s+(.*)$/);
      if (m){
        const tag = m[1] ? 'ol' : 'ul';
        if (listTag !== tag){ if (listTag) html.push(`</${listTag}>`); html.push(`<${tag}>`); listTag = tag; }
        html.push(`<li>${inline(m[2], esc)}</li>`);
      } else {
        if (listTag){ html.push(`</${listTag}>`); listTag = null; }
        const t = l.replace(/^#+\s*/, '');
        if (t.trim()) html.push(`<p>${inline(t, esc)}</p>`);
      }
    });
    if (listTag) html.push(`</${listTag}>`);
    return html.join('');
  }).join('');
}

const SPARK = '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 3l1.8 4.7 4.7 1.8-4.7 1.8L12 16l-1.8-4.7-4.7-1.8 4.7-1.8L12 3Z"/><path d="M19 15l.8 2.2 2.2.8-2.2.8L19 21l-.8-2.2-2.2-.8 2.2-.8L19 15Z"/></svg>';
const CLOSE = '<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"/></svg>';
const RESET = '<svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 12a9 9 0 1 0 3-6.7"/><path d="M3 4v5h5"/></svg>';
const SEND = '<svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 12l16-8-6 16-2.5-6.5L4 12Z"/></svg>';

const STARTERS = [
  'What needs my attention this week?',
  'How are my crops doing?',
  'Which animals are due for treatment?',
  'Are we making a profit?',
  'Is it a good time to spray?',
];

/**
 * Adds the assistant to the AI page. `getX()` returns the current
 * { D, A, user, scopeName, weather } so answers use the latest data.
 */
export function mountFarmChat(view, getX, esc){
  const X0 = getX();
  const key = `${X0.user && X0.user.id}|${X0.scopeName}`;
  if (chat.key !== key){
    chat.key = key;
    const first = X0.user && X0.user.firstName ? `, ${X0.user.firstName}` : '';
    chat.messages = [{ role: 'assistant', content: `Hi${first}. I'm the farm assistant for ${X0.scopeName}. Ask me anything about farming or your records, such as what needs doing this week, how to deal with a pest, or how profit is tracking.`, greeting: true }];
  }

  const wrap = document.createElement('div');
  wrap.className = 'ai-chat-root';
  wrap.innerHTML = `
    <button type="button" class="ai-chat-fab" aria-controls="aiChat" aria-expanded="${chat.open}">${SPARK}<span>Ask the farm assistant</span></button>
    <section class="ai-chat" id="aiChat" role="dialog" aria-label="Farm assistant" ${chat.open ? '' : 'hidden'}>
      <header class="ai-chat-head">
        <span class="ai-chat-avatar">${SPARK}</span>
        <div class="ai-chat-title">
          <h3>Farm assistant</h3>
          <span class="ai-chat-mode" data-mode></span>
        </div>
        <button type="button" class="ai-chat-icon" data-act="reset" title="Start a new conversation" aria-label="Start a new conversation">${RESET}</button>
        <button type="button" class="ai-chat-icon" data-act="close" title="Close" aria-label="Close the assistant">${CLOSE}</button>
      </header>
      <div class="ai-chat-log" aria-live="polite"></div>
      <div class="ai-chat-starters"></div>
      <form class="ai-chat-form" autocomplete="off">
        <label class="sr-only" for="aiChatInput">Your question</label>
        <textarea id="aiChatInput" rows="1" maxlength="2000" placeholder="Ask about your farm or farming…"></textarea>
        <button type="submit" class="ai-chat-send" aria-label="Send">${SEND}</button>
      </form>
    </section>`;
  view.appendChild(wrap);

  const fab = wrap.querySelector('.ai-chat-fab');
  const panel = wrap.querySelector('.ai-chat');
  const log = wrap.querySelector('.ai-chat-log');
  const starters = wrap.querySelector('.ai-chat-starters');
  const form = wrap.querySelector('.ai-chat-form');
  const input = wrap.querySelector('textarea');
  const mode = wrap.querySelector('[data-mode]');

  const setMode = () => {
    mode.textContent = chat.claude === true ? 'Claude + your farm records' : chat.claude === false ? 'Built-in knowledge + your records' : 'Uses your farm records';
  };
  const draw = () => {
    log.innerHTML = chat.messages.map(m => `<div class="ai-msg ai-msg-${m.role}${m.note ? ' ai-msg-note' : ''}">${m.role === 'user' ? `<p>${esc(m.content)}</p>` : format(m.content, esc)}</div>`).join('')
      + (chat.busy ? '<div class="ai-msg ai-msg-assistant ai-msg-typing" aria-label="The assistant is typing"><i></i><i></i><i></i></div>' : '');
    const asked = chat.messages.some(m => m.role === 'user');
    starters.innerHTML = asked ? '' : STARTERS.map(q => `<button type="button" class="ai-chip">${esc(q)}</button>`).join('');
    log.scrollTop = log.scrollHeight;
    form.querySelector('button').disabled = chat.busy;
  };
  const setOpen = (open) => {
    chat.open = open;
    panel.hidden = !open;
    fab.setAttribute('aria-expanded', String(open));
    fab.classList.toggle('is-open', open);
    if (open){ draw(); setTimeout(() => input.focus(), 30); }
  };

  async function ensureMode(){
    if (chat.claude !== null) return;
    try{ const s = await Api.aiStatus(); chat.claude = !!(s && s.enabled); }
    catch(e){ chat.claude = false; }
    setMode();
  }

  async function ask(q){
    q = q.trim();
    if (!q || chat.busy) return;
    chat.messages.push({ role: 'user', content: q });
    chat.busy = true; draw();
    await ensureMode();
    const X = getX();
    let answer = null, note = false;
    if (chat.claude){
      try{
        const history = chat.messages.filter(m => !m.greeting && !m.note).slice(-MAX_TURNS).map(m => ({ role: m.role, content: m.content }));
        const res = await Api.aiChat(history, buildContext(X));
        answer = res && res.answer;
      }catch(e){
        if (e.status === 429){ answer = e.message; note = true; }
        else {
          if (e.status === 503 && /not connected/i.test(e.message)){ chat.claude = false; setMode(); }
          answer = localAnswer(q, X) + (chat.claude ? '\n\n(Claude could not be reached, so this answer uses the built-in farm knowledge.)' : '');
        }
      }
    } else {
      answer = localAnswer(q, X);
    }
    chat.messages.push({ role: 'assistant', content: answer || 'Sorry, I could not answer that. Try asking another way.', note });
    chat.busy = false; draw();
  }

  fab.addEventListener('click', () => { setOpen(!chat.open); ensureMode(); });
  panel.querySelector('[data-act="close"]').addEventListener('click', () => { setOpen(false); fab.focus(); });
  panel.querySelector('[data-act="reset"]').addEventListener('click', () => {
    if (chat.busy) return;
    chat.messages = chat.messages.slice(0, 1);
    draw(); input.focus();
  });
  panel.addEventListener('keydown', e => { if (e.key === 'Escape'){ setOpen(false); fab.focus(); } });
  starters.addEventListener('click', e => { const b = e.target.closest('.ai-chip'); if (b) ask(b.textContent); });
  log.addEventListener('click', e => { if (e.target.closest('a[href^="#/"]')) setOpen(false); });
  form.addEventListener('submit', e => { e.preventDefault(); const q = input.value; input.value = ''; input.style.height = ''; ask(q); });
  input.addEventListener('keydown', e => { if (e.key === 'Enter' && !e.shiftKey){ e.preventDefault(); form.requestSubmit(); } });
  input.addEventListener('input', () => { input.style.height = 'auto'; input.style.height = Math.min(input.scrollHeight, 120) + 'px'; });

  setMode();
  if (chat.open) setOpen(true);
}

/* Exposed for testing the built-in answers without the UI. */
export const _test = { localAnswer, buildContext, format };
