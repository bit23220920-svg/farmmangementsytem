import { Store, Auth, Audit, getSelectedFarm, setSelectedFarm } from './store.js';
import { NAV_GROUPS, ENTITIES, ICONS, groupForEntity, GROUP_BY, GROUP_NULL_LABEL } from './schema.js';
import { mountMapPicker } from './map-picker.js';
import { bannerKeyForGroup, bannerMarkup } from './banners.js';
import { renderAiOverview } from './ai-overview.js';
import * as Cur from './currency.js';

/* ---------------------------------------------------------------------- */
/* Bootstrap — resolves the session against the real backend before any   */
/* UI renders, so a stale/invalid token bounces straight back to login.   */
/* ---------------------------------------------------------------------- */
const user = await Auth.requireSession();

if (user){
  document.getElementById('avatarInitials').textContent =
    (user.firstName[0] + user.lastName[0]).toUpperCase();
  document.getElementById('userName').textContent = `${user.firstName} ${user.lastName}`;
  document.getElementById('userRole').textContent = Auth.roleLabel(user.role);
  document.getElementById('topRoleBadge').textContent = Auth.roleLabel(user.role);

  document.getElementById('signOutBtn').addEventListener('click', async () => {
    await Auth.signOut();
    window.location.href = 'login.html';
  });
}

function icon(key, size = 16){
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${ICONS[key] || ''}</svg>`;
}

function canAccess(entityKey){
  const def = ENTITIES[entityKey];
  if (!def) return false;
  return def.roles.includes(user.role);
}

/* ---------------------------------------------------------------------- */
/* In-memory cache — avoids re-fetching a referenced entity's whole table  */
/* every time a foreign-key label needs resolving (e.g. every row in the  */
/* Fields table needs the parent Farm's name). Cheap and good enough for  */
/* a single session; invalidated on writes to that entity.                */
/* ---------------------------------------------------------------------- */
const cache = {};
async function fetchCached(entity, force = false){
  if (force || !cache[entity]){
    cache[entity] = await Store.all(entity);
  }
  return cache[entity];
}
function invalidate(entity){
  delete cache[entity];
}

/* ---------------------------------------------------------------------- */
/* Sidebar                                                                */
/* ---------------------------------------------------------------------- */
/* Each sidebar group is a dropdown. The group holding the current page is
   always open; any others the user opened stay open (remembered per browser). */
const NAV_OPEN_KEY = 'ffms_nav_open';
function navOpenSet(){
  try{ return new Set(JSON.parse(localStorage.getItem(NAV_OPEN_KEY) || '["Overview"]')); }catch(e){ return new Set(['Overview']); }
}
function saveNavOpen(set){
  try{ localStorage.setItem(NAV_OPEN_KEY, JSON.stringify([...set])); }catch(e){ /* storage blocked */ }
}
function buildSidebar(activeKey){
  const nav = document.getElementById('navContainer');
  nav.innerHTML = '';
  const openSet = navOpenSet();
  NAV_GROUPS.forEach(group => {
    const visible = group.items.filter(canAccess);
    if (!visible.length) return;
    const hasActive = visible.includes(activeKey);
    const isOpen = hasActive || openSet.has(group.label);

    const toggle = document.createElement('button');
    toggle.type = 'button';
    toggle.className = 'group-label group-toggle' + (isOpen ? ' open' : '') + (hasActive ? ' has-active' : '');
    toggle.setAttribute('aria-expanded', String(isOpen));
    toggle.innerHTML = `<span>${group.label}</span>${CHEVRON}`;
    nav.appendChild(toggle);

    const list = document.createElement('div');
    list.className = 'group-items';
    list.hidden = !isOpen;
    visible.forEach(key => {
      const def = ENTITIES[key];
      const a = document.createElement('a');
      a.href = `#/${key}`;
      a.className = 'nav-item' + (key === activeKey ? ' active' : '');
      a.innerHTML = `${icon(key)}<span>${def.label}</span>`;
      list.appendChild(a);
    });
    nav.appendChild(list);

    toggle.addEventListener('click', () => {
      const open = list.hidden;
      list.hidden = !open;
      toggle.classList.toggle('open', open);
      toggle.setAttribute('aria-expanded', String(open));
      const set = navOpenSet();
      if (open) set.add(group.label); else set.delete(group.label);
      saveNavOpen(set);
    });
  });
}

function setSidebarOpen(open){
  document.getElementById('sidebar').classList.toggle('open', open);
  document.getElementById('sidebarBackdrop').classList.toggle('show', open);
}
document.getElementById('menuToggle').addEventListener('click', () => {
  const isOpen = document.getElementById('sidebar').classList.contains('open');
  setSidebarOpen(!isOpen);
});
document.getElementById('sidebarBackdrop').addEventListener('click', () => setSidebarOpen(false));

/* ---------------------------------------------------------------------- */
/* Farm picker                                                            */
/* ---------------------------------------------------------------------- */
/* Only administrators can switch farms. Everyone else is locked to the farm
   their account belongs to — the server enforces this too, the picker just
   shows it. */
const isAdmin = user && user.role === 'admin';
async function refreshFarmPicker(){
  const picker = document.getElementById('farmPicker');
  if (!isAdmin){
    picker.disabled = true;
    picker.title = 'Your account belongs to this farm';
    picker.innerHTML = user.farmId
      ? `<option value="${user.farmId}">${escapeHtml(user.farmName || 'My farm')}</option>`
      : `<option>No farm assigned</option>`;
    setSelectedFarm(user.farmId || '');
    return;
  }
  const farms = await fetchCached('farms');
  let selected = getSelectedFarm();
  if (selected !== 'all' && !farms.some(f => String(f.id) === selected)){
    selected = 'all';
    setSelectedFarm('all');
  }
  picker.disabled = false;
  picker.title = 'Switch farm (administrators only)';
  picker.innerHTML = `<option value="all" ${selected === 'all' ? 'selected' : ''}>All farms</option>` + farms.map(f =>
    `<option value="${f.id}" ${String(f.id) === selected ? 'selected' : ''}>${escapeHtml(f.farm_name)}</option>`
  ).join('');
}
document.getElementById('farmPicker').addEventListener('change', (e) => {
  if (!isAdmin) return;
  setSelectedFarm(e.target.value);
  // Everything cached belonged to the previous farm selection.
  Object.keys(cache).forEach(k => { if (k !== 'farms') invalidate(k); });
  renderRoute();
});

/* ---------------------------------------------------------------------- */
/* Currency box: which currency money is shown in (see currency.js)       */
/* ---------------------------------------------------------------------- */
async function refreshCurrencyPicker(){
  try{ Cur.setFarms(await fetchCached('farms')); }catch(e){ /* keep the farms we knew */ }
  const picker = document.getElementById('currencyPicker');
  const shared = Cur.sharedCurrency();
  const farmCodes = [...new Set((cache.farms || []).map(f => String(f.currency_code || Cur.DEFAULT_CURRENCY).toUpperCase()))];
  const first = ['USD', ...farmCodes.filter(c => c !== 'USD')];
  const pref = Cur.getDisplay();
  const opt = o => `<option value="${escapeHtml(o.value)}"${o.value === pref ? ' selected' : ''}>${escapeHtml(o.label)}</option>`;
  picker.innerHTML =
    opt({ value: Cur.LOCAL, label: shared ? `Farm currency (${shared})` : 'Each farm\'s own currency' }) +
    `<optgroup label="Convert to">${first.map(c => opt({ value: c, label: `${c} \u00b7 ${Cur.currencyName(c)}` })).join('')}</optgroup>` +
    `<optgroup label="All currencies">${Cur.currencyOptions().filter(o => !first.includes(o.value)).map(opt).join('')}</optgroup>`;
  if (picker.value !== pref) picker.value = Cur.LOCAL;
  const info = Cur.ratesInfo();
  picker.title = info.approx
    ? 'Show money in this currency. Live exchange rates could not be loaded, so approximate rates are used.'
    : `Show money in this currency. Exchange rates from ${info.source}.`;
}
document.getElementById('currencyPicker').addEventListener('change', (e) => {
  Cur.setDisplay(e.target.value);
  renderRoute();
});

/** "ZMW 1,250.00", converted to the currency picked in the top bar. */
function moneyHtml(value, from){
  if (value === undefined || value === null || value === '') return '<span class="num">\u2014</span>';
  const pref = Cur.getDisplay();
  const to = pref === Cur.LOCAL ? from : pref;
  const v = Cur.convert(value, from, to);
  if (v === null){
    return `<span class="num money-cell" title="No exchange rate for ${escapeHtml(from)}">${escapeHtml(Cur.formatMoney(value, from))}</span>`;
  }
  const title = to !== from ? ` title="${escapeHtml(Cur.formatMoney(value, from))} as recorded"` : '';
  return `<span class="num money-cell"${title}>${escapeHtml(Cur.formatMoney(v, to))}</span>`;
}

/** Adds up amounts recorded in different currencies, in currency `to`. */
function sumMoney(rows, amountOf, codeOf, to){
  let total = 0;
  const missing = new Set();
  rows.forEach(r => {
    const v = Number(amountOf(r));
    if (!Number.isFinite(v)) return;
    const from = codeOf(r);
    const c = Cur.convert(v, from, to);
    if (c === null) missing.add(from); else total += c;
  });
  return { total, missing };
}
function missingRatesNote(...sums){
  const codes = new Set(sums.flatMap(x => [...x.missing]));
  return codes.size ? `<p class="fx-note">Amounts in ${escapeHtml([...codes].join(', '))} are left out of these totals: there is no exchange rate for them.</p>` : '';
}

/* ---------------------------------------------------------------------- */
/* Light / dark / system theme menu (see theme.js)                        */
/* ---------------------------------------------------------------------- */
const THEME_ICONS = {
  light: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2.5v2M12 19.5v2M4.6 4.6l1.4 1.4M18 18l1.4 1.4M2.5 12h2M19.5 12h2M4.6 19.4L6 18M18 6l1.4-1.4"/></svg>',
  dark: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"><path d="M20 14.6A8.4 8.4 0 0 1 9.4 4a8.4 8.4 0 1 0 10.6 10.6Z"/></svg>',
  system: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8M12 16v4"/></svg>',
};
const THEME_LABELS = { light: 'Light', dark: 'Dark', system: 'System (follow this device)' };
/* Big totals shrink only as much as they need to fit their card (see .value.num in styles.css). */
(function fitStatNumbers(){
  const view = document.getElementById('view');
  if (!view || !window.MutationObserver) return;
  const fit = () => view.querySelectorAll('.stat-card .value.num').forEach(v =>
    v.style.setProperty('--chars', Math.max(v.textContent.trim().length, 8)));
  new MutationObserver(fit).observe(view, { childList: true, subtree: true });
  fit();
})();

(function setupThemeMenu(){
  const T = window.JDTheme;
  const btn = document.getElementById('themeBtn');
  const menu = document.getElementById('themeMenu');
  if (!btn || !menu) return;
  if (!T){ btn.parentElement.hidden = true; return; }
  const draw = () => {
    const mode = T.get();
    btn.innerHTML = THEME_ICONS[mode];
    btn.title = `Theme: ${THEME_LABELS[mode]}`;
    menu.innerHTML = ['light', 'dark', 'system'].map(m =>
      `<button type="button" role="menuitemradio" aria-checked="${m === mode}" data-mode="${m}">${THEME_ICONS[m]}<span>${THEME_LABELS[m]}</span><span class="tick">\u2713</span></button>`
    ).join('');
  };
  const close = () => { menu.hidden = true; btn.setAttribute('aria-expanded', 'false'); };
  btn.addEventListener('click', (e) => {
    e.stopPropagation();
    const opening = menu.hidden;
    menu.hidden = !opening;
    btn.setAttribute('aria-expanded', String(opening));
    if (opening){
      // Open toward whichever side has room (on a phone the button can sit at the left edge).
      menu.style.left = menu.style.right = '';
      if (menu.getBoundingClientRect().left < 8){ menu.style.left = '0'; menu.style.right = 'auto'; }
    }
  });
  menu.addEventListener('click', (e) => {
    const b = e.target.closest('[data-mode]');
    if (!b) return;
    T.set(b.dataset.mode);
    close();
  });
  document.addEventListener('click', (e) => { if (!e.target.closest('.theme-menu')) close(); });
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape') close(); });
  document.addEventListener('jd-theme-change', draw);
  draw();
})();

/* ---------------------------------------------------------------------- */
/* Toasts                                                                 */
/* ---------------------------------------------------------------------- */
function toast(msg, isErr = false){
  const stack = document.getElementById('toastStack');
  const t = document.createElement('div');
  t.className = 'toast' + (isErr ? ' err' : '');
  t.textContent = msg;
  stack.appendChild(t);
  setTimeout(() => t.remove(), 2800);
}

/* ---------------------------------------------------------------------- */
/* Helpers                                                                */
/* ---------------------------------------------------------------------- */
function escapeHtml(str){
  if (str === null || str === undefined) return '';
  return String(str).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

/* Friendly names for records that have no single "name" column — so a dropdown or
   group heading reads "North Block · Maize (SC719) · 2026-10-01" instead of "Planting #4". */
const REF_DEPS = {
  fields: ['farms'],
  crop_plantings: ['fields', 'crop_varieties'],
  irrigation_systems: ['fields'],
  inventory_batches: ['inventory_items'],
  harvests: ['crop_plantings'],
  sales_orders: ['customers'],
  purchase_orders: ['suppliers'],
  scouting_records: ['fields'],
};
function cachedRec(entity, id){
  return (cache[entity] || []).find(r => String(r.id) === String(id));
}
/* "North Block (Maburo Farm)" — so every crop, planting and field shows which farm it is on. */
function fieldWithFarm(f){
  if (!f) return null;
  const farm = cachedRec('farms', f.farm_id);
  return farm ? `${f.field_name} (${farm.farm_name})` : f.field_name;
}
const RECORD_LABELS = {
  employees: r => `${r.first_name || ''} ${r.last_name || ''}`.trim(),
  fields: r => fieldWithFarm(r),
  crop_plantings: r => {
    const f = cachedRec('fields', r.field_id), v = cachedRec('crop_varieties', r.variety_id);
    return [f ? fieldWithFarm(f) : `Field #${r.field_id}`,
            v ? `${v.crop_name} (${v.variety_name})` : `Variety #${r.variety_id}`,
            r.planting_date].filter(Boolean).join(' \u00b7 ');
  },
  irrigation_systems: r => {
    const f = cachedRec('fields', r.field_id);
    return `${f ? fieldWithFarm(f) : 'Field #' + r.field_id} \u00b7 ${r.system_type}`;
  },
  inventory_batches: r => {
    const it = cachedRec('inventory_items', r.item_id);
    return `${it ? it.item_name : 'Item #' + r.item_id} \u00b7 ${r.batch_number ? 'batch ' + r.batch_number : 'batch #' + r.id}`;
  },
  harvests: r => {
    const p = cachedRec('crop_plantings', r.planting_id);
    return `${p ? RECORD_LABELS.crop_plantings(p) : 'Planting #' + r.planting_id} \u00b7 harvested ${r.harvest_date}`;
  },
  sales_orders: r => {
    const c = cachedRec('customers', r.customer_id);
    return `Order #${r.id} \u00b7 ${c ? c.customer_name : 'Customer #' + r.customer_id}`;
  },
  purchase_orders: r => {
    const sp = cachedRec('suppliers', r.supplier_id);
    return `PO #${r.id} \u00b7 ${sp ? sp.supplier_name : 'Supplier #' + r.supplier_id}`;
  },
  scouting_records: r => {
    const f = cachedRec('fields', r.field_id);
    return `${f ? fieldWithFarm(f) : 'Field #' + r.field_id} \u00b7 ${r.scout_date}`;
  },
};

/** Fetches the given entities plus whatever else is needed to name their records. */
async function prefetchRefs(entities){
  const seen = new Set();
  let queue = [...entities];
  while (queue.length){
    const batch = queue.filter(e => e && !seen.has(e));
    queue = [];
    batch.forEach(e => seen.add(e));
    await Promise.all(batch.map(e => fetchCached(e)));
    batch.forEach(e => (REF_DEPS[e] || []).forEach(d => queue.push(d)));
  }
}

function labelForRef(field, record){
  if (!record) return null;
  const deep = RECORD_LABELS[field.ref];
  if (deep){
    try{ const t = deep(record); if (t) return t; }catch(e){ /* fall through to the simple label */ }
  }
  if (field.refLabel && !field.refLabel.startsWith('#') && record[field.refLabel] !== undefined && record[field.refLabel] !== ''){
    return record[field.refLabel];
  }
  const def = ENTITIES[field.ref];
  return `${def?.singular || field.ref} #${record.id}`;
}

/** Synchronous — assumes the referenced entity is already in cache (renderEntityView/openDrawer pre-fetch it). */
function resolveRefLabelSync(field, value){
  if (value === undefined || value === null || value === '') return '\u2014';
  const list = cache[field.ref] || [];
  const rec = list.find(r => String(r.id) === String(value));
  if (!rec) return `#${value}`;
  return labelForRef(field, rec);
}

const STATUS_PILL = {
  active: 'olive', operational: 'olive', completed: 'olive', paid: 'olive',
  effective: 'olive', delivered: 'olive', confirmed: 'olive', approved: 'olive',
  fulfilled: 'olive', stored: 'olive', permanent: 'olive',
  pending: 'neutral', scheduled: 'neutral', draft: 'neutral', requested: 'neutral',
  planned: 'neutral', casual: 'neutral', in_progress: 'ochre',
  maintenance: 'ochre', under_maintenance: 'ochre', partially_paid: 'ochre',
  dispatched: 'ochre', partially_effective: 'ochre', moderate: 'ochre', contract: 'neutral',
  cancelled: 'rust', failed: 'rust', deceased: 'rust', out_of_service: 'rust',
  ineffective: 'rust', disposed: 'rust', inactive: 'rust', suspended: 'rust', severe: 'rust', high: 'rust',
};
/** A select field's fixed choices as {value, label}; `options` may be a list or a function. */
function optionList(f){
  const list = typeof f.options === 'function' ? f.options() : (f.options || []);
  return list.map(o => (o && typeof o === 'object') ? { value: String(o.value), label: o.label } : { value: String(o), label: String(o).replace(/_/g, ' ') });
}

function pill(value){
  if (value === undefined || value === null || value === '') return '\u2014';
  const cls = STATUS_PILL[String(value)] || 'neutral';
  return `<span class="pill pill-${cls}">${escapeHtml(String(value).replace(/_/g, ' '))}</span>`;
}

function bannerHtml(entityKey){
  const groupLabel = groupForEntity(entityKey);
  const key = bannerKeyForGroup(groupLabel);
  return `<div class="module-banner">${bannerMarkup(key)}<span class="banner-label">${escapeHtml(groupLabel)}</span></div>`;
}

/* ---------------------------------------------------------------------- */
/* Drawer (add / edit)                                                    */
/* ---------------------------------------------------------------------- */
const overlay = document.getElementById('overlay');
const drawer = document.getElementById('drawer');
const drawerBody = document.getElementById('drawerBody');
const drawerTitle = document.getElementById('drawerTitle');
const drawerSave = document.getElementById('drawerSave');

let activeEntity = null;
let editingId = null;
let mapHandle = null;

function destroyMap(){
  if (mapHandle){ try{ mapHandle.destroy(); }catch(e){} mapHandle = null; }
}

/**
 * @param {string} entityKey
 * @param {object|null} record     existing record when editing
 * @param {object} defaults        values to pre-fill on a new record (e.g. the parent it belongs to)
 */
async function openDrawer(entityKey, record = null, defaults = {}){
  destroyMap();
  activeEntity = entityKey;
  editingId = record ? record.id : null;
  const def = ENTITIES[entityKey];
  drawerTitle.textContent = record ? `Edit ${def.singular}` : `Add ${def.singular}`;
  drawerBody.innerHTML = '';

  // Pre-fetch every referenced entity this form's selects will need.
  await prefetchRefs([...new Set(def.fields.filter(f => f.type === 'select' && f.ref).map(f => f.ref))]);

  for (const f of def.fields){
    const wrap = document.createElement('div');
    wrap.className = 'field';
    const initial = defaults[f.name] !== undefined ? defaults[f.name] : (f.default !== undefined ? f.default : '');
    const val = record ? record[f.name] : initial;

    let inputHtml = '';
    if (f.type === 'textarea'){
      inputHtml = `<textarea id="fld_${f.name}">${escapeHtml(val)}</textarea>`;
    } else if (f.type === 'select' && f.ref){
      const selected = isAdmin ? (/^\d+$/.test(getSelectedFarm()) ? getSelectedFarm() : '') : String(user.farmId || '');
      const options = (cache[f.ref] || []).map(r =>
        `<option value="${r.id}" ${String(val) === String(r.id) ? 'selected' : ''}>${escapeHtml(labelForRef(f, r))}</option>`
      ).join('');
      const preselect = !record && defaults[f.name] === undefined && f.name === 'farm_id' && selected;
      inputHtml = `<select id="fld_${f.name}"><option value="">Select\u2026</option>${options}</select>`;
      wrap.dataset.preselect = preselect ? selected : '';
    } else if (f.type === 'select'){
      const opts = optionList(f);
      const cur = val === null || val === undefined ? '' : String(val);
      if (cur && !opts.some(o => String(o.value) === cur)) opts.unshift({ value: cur, label: cur });
      const blank = f.blank ? `<option value="">${escapeHtml(f.blank)}</option>` : '';
      const options = opts.map(o =>
        `<option value="${escapeHtml(o.value)}" ${cur === String(o.value) ? 'selected' : ''}>${escapeHtml(o.label)}</option>`
      ).join('');
      inputHtml = `<select id="fld_${f.name}">${blank}${options}</select>`;
    } else if (f.type === 'datetime'){
      const dv = val ? String(val).replace(' ', 'T').slice(0,16) : '';
      inputHtml = `<input type="datetime-local" id="fld_${f.name}" value="${dv}">`;
    } else {
      const step = f.step ? ` step="${f.step}"` : '';
      inputHtml = `<input type="${f.type}" id="fld_${f.name}" value="${escapeHtml(val)}"${step} placeholder="${escapeHtml(f.placeholder || '')}">`;
    }

    wrap.innerHTML = `<label for="fld_${f.name}">${f.label}</label>${inputHtml}${f.help ? `<p class="help-text">${escapeHtml(f.help)}</p>` : ''}`;
    drawerBody.appendChild(wrap);

    if (f.type === 'select' && f.ref && wrap.dataset.preselect){
      wrap.querySelector('select').value = wrap.dataset.preselect;
    }
    if (f.type === 'select' && f.ref && !(cache[f.ref] || []).length){
      const note = document.createElement('p');
      note.className = 'help-text';
      note.textContent = `No ${ENTITIES[f.ref].label.toLowerCase()} recorded yet \u2014 add one first.`;
      wrap.appendChild(note);
    }
  }

  // A choice that fills in another field (a farm's country sets its currency).
  def.fields.filter(f => f.fills).forEach(f => {
    const src = document.getElementById(`fld_${f.name}`);
    const dst = document.getElementById(`fld_${f.fills.field}`);
    if (!src || !dst) return;
    src.addEventListener('change', () => {
      const v = f.fills.with(src.value);
      if (v && [...dst.options].some(o => o.value === v)) dst.value = v;
    });
  });

  // Money fields say which currency to type in: the currency of the farm the record belongs to.
  const moneyFields = def.fields.filter(f => f.money);
  if (moneyFields.length){
    const updateMoneyLabels = () => {
      const draft = {};
      def.fields.forEach(f => { const el = document.getElementById(`fld_${f.name}`); if (el) draft[f.name] = el.value; });
      const farm = Cur.farmOfRow(entityKey, draft, cachedRec);
      const code = farm !== null && farm !== undefined && farm !== '' ? Cur.farmCurrency(farm) : Cur.sharedCurrency();
      moneyFields.forEach(f => {
        const label = drawerBody.querySelector(`label[for="fld_${f.name}"]`);
        if (label) label.textContent = `${f.label} (${code || 'in the farm\'s currency'})`;
      });
    };
    drawerBody.querySelectorAll('select').forEach(el => el.addEventListener('change', updateMoneyLabels));
    updateMoneyLabels();
  }

  // Farm form: pick the location on a map instead of typing coordinates.
  if (def.mapPicker){
    const mp = def.mapPicker;
    const latEl = document.getElementById(`fld_${mp.lat}`);
    const lngEl = document.getElementById(`fld_${mp.lng}`);
    const addrEl = document.getElementById(`fld_${mp.address}`);
    const anchor = document.getElementById(`fld_${mp.before}`)?.closest('.field');
    const host = document.createElement('div');
    drawerBody.insertBefore(host, anchor || null);
    mapHandle = mountMapPicker(host, {
      lat: latEl.value,
      lng: lngEl.value,
      onPick: ({ lat, lng }) => { latEl.value = lat; lngEl.value = lng; },
      onAddress: (text) => { addrEl.value = text; },
    });
    const sync = () => {
      const a = parseFloat(latEl.value), b = parseFloat(lngEl.value);
      if (Number.isFinite(a) && Number.isFinite(b)) mapHandle.setPoint(a, b, 14);
    };
    latEl.addEventListener('change', sync);
    lngEl.addEventListener('change', sync);
  }

  overlay.classList.add('show');
  drawer.classList.add('show');
  drawerBody.scrollTop = 0;
}

function closeDrawer(){
  overlay.classList.remove('show');
  drawer.classList.remove('show');
  destroyMap();
  activeEntity = null;
  editingId = null;
}
document.getElementById('drawerClose').addEventListener('click', closeDrawer);
document.getElementById('drawerCancel').addEventListener('click', closeDrawer);
overlay.addEventListener('click', closeDrawer);

drawerSave.addEventListener('click', async () => {
  const def = ENTITIES[activeEntity];
  const record = {};
  for (const f of def.fields){
    const el = document.getElementById(`fld_${f.name}`);
    let v = el.value;
    if (f.required && !v){
      el.focus();
      toast(`${f.label} is required.`, true);
      return;
    }
    if (v !== '' && f.type === 'number') v = Number(v);
    if (f.type === 'select' && f.ref && v !== '') v = Number(v);
    record[f.name] = v;
  }

  drawerSave.disabled = true;
  drawerSave.textContent = 'Saving\u2026';
  try{
    if (editingId){
      await Store.update(activeEntity, editingId, record);
      toast(`${def.singular} updated.`);
    } else {
      await Store.insert(activeEntity, record);
      toast(`${def.singular} added.`);
    }
    const savedEntity = activeEntity;
    invalidate(activeEntity);
    closeDrawer();
    if (savedEntity === 'farms' && !isAdmin && !user.farmId){
      const fresh = await Auth.verifySession();
      if (fresh) Object.assign(user, fresh);
    }
    await renderRoute();
  }catch(err){
    toast(err.message || 'Could not save.', true);
  }finally{
    drawerSave.disabled = false;
    drawerSave.textContent = 'Save';
  }
});

/* ---------------------------------------------------------------------- */
/* Generic entity list view                                               */
/* ---------------------------------------------------------------------- */
const openGroups = {};   // entityKey -> Set of expanded group keys (survives re-renders)
const NONE = '__none__';
const CHEVRON = '<svg class="chev" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6-6 6"/></svg>';

async function renderEntityView(entityKey){
  const def = ENTITIES[entityKey];
  const view = document.getElementById('view');
  view.innerHTML = `<div class="empty-state"><p>Loading\u2026</p></div>`;

  const rows = await fetchCached(entityKey, true);
  const groupName = GROUP_BY[entityKey];
  const groupField = groupName ? def.fields.find(f => f.name === groupName) : null;
  // In a grouped list the parent is the heading, so its column is left out of the rows.
  const cols = (def.fields || []).filter(f => !groupField || f.name !== groupField.name).slice(0, 6);

  await prefetchRefs([...new Set(def.fields.filter(f => f.type === 'select' && f.ref).map(f => f.ref))]);
  if (!openGroups[entityKey]) openGroups[entityKey] = new Set();
  const open = openGroups[entityKey];

  view.innerHTML = `
    ${bannerHtml(entityKey)}
    <div class="page-head">
      <div>
        <h1>${def.label}</h1>
        <p class="desc">${def.description || ''}</p>
      </div>
      <button class="btn btn-primary" id="addBtn">+ Add ${def.singular}</button>
    </div>
    <div class="toolbar">
      <div class="search-box">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
        <input type="text" id="searchInput" placeholder="Search ${def.label.toLowerCase()}\u2026">
      </div>
      ${groupField ? `<button class="btn btn-ghost btn-sm" id="expandAll">Expand all</button><button class="btn btn-ghost btn-sm" id="collapseAll">Collapse all</button>` : ''}
      <div class="toolbar-spacer"></div>
      <span class="count-tag" id="countTag">${rows.length} record${rows.length === 1 ? '' : 's'}</span>
    </div>
    ${groupField ? `<p class="help-text" style="margin:-4px 0 12px;">Grouped by ${escapeHtml(groupField.label.toLowerCase())} \u2014 click a row to see everything recorded against it.</p>` : ''}
    ${cols.some(f => f.money) && Cur.getDisplay() !== Cur.LOCAL ? Cur.ratesNoteHtml(new Set(rows.map(r => Cur.rowCurrency(entityKey, r, cachedRec))), Cur.getDisplay()) : ''}
    <div id="tableHost"></div>
  `;

  const guarded = (fn) => async () => {
    try{ await fn(); }catch(err){ toast(err.message || 'Could not open the form.', true); }
  };
  document.getElementById('addBtn').addEventListener('click', guarded(() => openDrawer(entityKey)));

  const rowCurrency = r => Cur.rowCurrency(entityKey, r, cachedRec);

  function cellHtml(f, r){
    if (f.money) return `<td>${moneyHtml(r[f.name], rowCurrency(r))}</td>`;
    if (f.cell){
      const t = r[f.name] !== undefined && r[f.name] !== null && r[f.name] !== '' ? f.cell(r[f.name]) : '';
      return `<td>${t ? escapeHtml(t) : '\u2014'}</td>`;
    }
    if (f.type === 'select' && f.ref) return `<td>${escapeHtml(resolveRefLabelSync(f, r[f.name]))}</td>`;
    if (f.type === 'select') return `<td>${pill(r[f.name])}</td>`;
    if (f.type === 'number'){
      return `<td><span class="num">${r[f.name] !== undefined && r[f.name] !== null && r[f.name] !== '' ? r[f.name] : '\u2014'}</span></td>`;
    }
    const v = r[f.name];
    return `<td>${v !== undefined && v !== null && v !== '' ? escapeHtml(v) : '\u2014'}</td>`;
  }

  function rowHtml(r, extra = ''){
    return `
      <tr ${extra} data-id="${r.id}">
        ${cols.map(f => cellHtml(f, r)).join('')}
        <td>
          <div class="row-actions">
            <button class="edit-btn" data-id="${r.id}">Edit</button>
            <button class="del del-btn" data-id="${r.id}">Delete</button>
          </div>
        </td>
      </tr>`;
  }

  function groupLabel(key){
    if (key === NONE) return GROUP_NULL_LABEL[entityKey] || 'Not linked to anything';
    return resolveRefLabelSync(groupField, key);
  }

  function bindRowActions(host){
    host.querySelectorAll('.edit-btn').forEach(b => b.addEventListener('click', guarded(async () => {
      const rec = rows.find(r => String(r.id) === b.dataset.id);
      await openDrawer(entityKey, rec);
    })));
    host.querySelectorAll('.del-btn').forEach(b => b.addEventListener('click', async () => {
      if (!confirm(`Delete this ${def.singular.toLowerCase()}? This can't be undone.`)) return;
      try{
        await Store.remove(entityKey, Number(b.dataset.id));
        invalidate(entityKey);
        toast(`${def.singular} deleted.`);
        await renderRoute();
      }catch(err){
        toast(err.message || 'Could not delete.', true);
      }
    }));
  }

  function drawEmpty(host){
    host.innerHTML = emptyStateHtml(entityKey, def);
    host.querySelector('.empty-add')?.addEventListener('click', guarded(() => openDrawer(entityKey)));
  }

  function drawFlat(filtered){
    const host = document.getElementById('tableHost');
    if (!filtered.length) return drawEmpty(host);
    host.innerHTML = `
      <div class="table-wrap">
        <table>
          <thead><tr>${cols.map(f => `<th>${f.label}</th>`).join('')}<th></th></tr></thead>
          <tbody>${filtered.map(r => rowHtml(r)).join('')}</tbody>
        </table>
      </div>`;
    bindRowActions(host);
  }

  function drawGrouped(filtered, searching){
    const host = document.getElementById('tableHost');
    if (!filtered.length) return drawEmpty(host);

    const groups = new Map();
    filtered.forEach(r => {
      const v = r[groupField.name];
      const k = (v === null || v === undefined || v === '') ? NONE : String(v);
      if (!groups.has(k)) groups.set(k, []);
      groups.get(k).push(r);
    });
    if (!searching && groups.size === 1 && !open.size) open.add([...groups.keys()][0]);

    const span = cols.length + 1;
    let body = '';
    groups.forEach((list, key) => {
      const isOpen = searching || open.has(key);
      body += `
        <tr class="group-row${isOpen ? ' open' : ''}" data-group="${escapeHtml(key)}">
          <td colspan="${span}">
            <div class="group-title">
              ${CHEVRON}
              <span>${escapeHtml(groupLabel(key))}</span>
              <span class="group-count">${list.length} record${list.length === 1 ? '' : 's'}</span>
              <button class="btn btn-ghost btn-sm group-add" data-group="${escapeHtml(key)}">+ Add</button>
            </div>
          </td>
        </tr>`;
      list.forEach(r => { body += rowHtml(r, `class="child-row" data-group="${escapeHtml(key)}"${isOpen ? '' : ' hidden'}`); });
    });

    host.innerHTML = `
      <div class="table-wrap">
        <table>
          <thead><tr>${cols.map(f => `<th>${f.label}</th>`).join('')}<th></th></tr></thead>
          <tbody>${body}</tbody>
        </table>
      </div>`;

    const setGroup = (key, expand) => {
      const gr = [...host.querySelectorAll('.group-row')].find(x => x.dataset.group === key);
      if (gr) gr.classList.toggle('open', expand);
      host.querySelectorAll('.child-row').forEach(tr => { if (tr.dataset.group === key) tr.hidden = !expand; });
      if (expand) open.add(key); else open.delete(key);
    };

    host.querySelectorAll('.group-row').forEach(gr => gr.addEventListener('click', () => {
      setGroup(gr.dataset.group, !gr.classList.contains('open'));
    }));
    host.querySelectorAll('.group-add').forEach(b => b.addEventListener('click', async (e) => {
      e.stopPropagation();   // don't also toggle the group row underneath the button
      const key = b.dataset.group;
      open.add(key);         // keep this group expanded after saving
      try{
        await openDrawer(entityKey, null, key === NONE ? {} : { [groupField.name]: Number(key) });
      }catch(err){
        toast(err.message || 'Could not open the form.', true);
      }
    }));

    document.getElementById('expandAll')?.addEventListener('click', () => groups.forEach((_, k) => setGroup(k, true)));
    document.getElementById('collapseAll')?.addEventListener('click', () => groups.forEach((_, k) => setGroup(k, false)));

    bindRowActions(host);
  }

  const draw = (filtered, searching = false) => groupField ? drawGrouped(filtered, searching) : drawFlat(filtered);

  function searchText(r){
    const parts = cols.map(f => (f.type === 'select' && f.ref) ? resolveRefLabelSync(f, r[f.name]) : (r[f.name] ?? ''));
    if (groupField) parts.push(groupLabel(r[groupField.name] ? String(r[groupField.name]) : NONE));
    return parts.join(' ').toLowerCase();
  }

  draw(rows);

  document.getElementById('searchInput').addEventListener('input', (e) => {
    const q = e.target.value.trim().toLowerCase();
    const filtered = !q ? rows : rows.filter(r => searchText(r).includes(q));
    document.getElementById('countTag').textContent = `${filtered.length} record${filtered.length === 1 ? '' : 's'}`;
    draw(filtered, !!q);
  });
}

function emptyStateHtml(entityKey, def){
  return `
    <div class="table-wrap">
      <div class="empty-state">
        <div class="glyph">${icon(entityKey, 44)}</div>
        <h3>No ${def.label.toLowerCase()} yet</h3>
        <p>Records you add will appear here. Start by adding your first ${def.singular.toLowerCase()}.</p>
        <button class="btn btn-primary empty-add">+ Add ${def.singular}</button>
      </div>
    </div>`;
}

/* ---------------------------------------------------------------------- */
/* Dashboard                                                              */
/* ---------------------------------------------------------------------- */
async function renderDashboard(){
  const view = document.getElementById('view');
  view.innerHTML = `<div class="empty-state"><p>Loading\u2026</p></div>`;

  const [farms, fields, plantings, livestock, inventoryItems, tasks, finance] = await Promise.all([
    fetchCached('farms', true), fetchCached('fields', true), fetchCached('crop_plantings', true),
    fetchCached('livestock', true), fetchCached('inventory_items', true),
    fetchCached('task_allocations', true), fetchCached('financial_transactions', true),
  ]);

  const activePlantings = plantings.filter(p => p.status === 'active').length;
  const livestockCount = livestock.filter(a => a.status === 'active').length;
  const lowStock = inventoryItems.filter(i => Number(i.current_stock) <= Number(i.reorder_threshold)).length;
  const pendingTasks = tasks.filter(t => t.status === 'pending' || t.status === 'in_progress').length;
  const finCode = t => Cur.farmCurrency(t.farm_id);
  const finTo = Cur.totalCurrency(finance.map(finCode));
  const incSum = sumMoney(finance.filter(t => t.transaction_type === 'income'), t => t.amount, finCode, finTo);
  const expSum = sumMoney(finance.filter(t => t.transaction_type === 'expense'), t => t.amount, finCode, finTo);
  const income = incSum.total, expense = expSum.total;
  const fmtTotal = v => Cur.formatMoney(v, finTo, 0);

  const hasAnyData = farms.length || fields.length || plantings.length;

  view.innerHTML = `
    ${bannerHtml('dashboard')}
    <div class="page-head">
      <div>
        <h1>Good day, ${escapeHtml(user.firstName)}</h1>
        <p class="desc">Here's where things stand across ${farms.length ? escapeHtml(farms[0].farm_name) + (farms.length > 1 ? ` and ${farms.length - 1} other farm${farms.length > 2 ? 's' : ''}` : '') : 'your farm'}.</p>
      </div>
    </div>
    ${noFarmNote()}

    <div class="stat-grid">
      <div class="stat-card"><div class="label">Farms</div><div class="value olive">${farms.length}</div></div>
      <div class="stat-card"><div class="label">Fields</div><div class="value olive">${fields.length}</div></div>
      <div class="stat-card"><div class="label">Active plantings</div><div class="value ochre">${activePlantings}</div></div>
      <div class="stat-card"><div class="label">Livestock on hand</div><div class="value ochre">${livestockCount}</div></div>
      <div class="stat-card"><div class="label">Items below reorder point</div><div class="value ${lowStock ? 'rust' : 'olive'}">${lowStock}</div></div>
      <div class="stat-card"><div class="label">Open tasks</div><div class="value slate">${pendingTasks}</div></div>
    </div>

    <div class="panel-grid">
      <div class="panel">
        <h3>Net position (recorded so far)</h3>
        ${income || expense ? `
          <div class="stat-grid" style="grid-template-columns:1fr 1fr 1fr;margin-bottom:8px;">
            <div class="stat-card"><div class="label">Income</div><div class="value olive num">${fmtTotal(income)}</div></div>
            <div class="stat-card"><div class="label">Expense</div><div class="value rust num">${fmtTotal(expense)}</div></div>
            <div class="stat-card"><div class="label">Net</div><div class="value num">${fmtTotal(income - expense)}</div></div>
          </div>
          ${Cur.ratesNoteHtml(new Set(finance.map(finCode)), finTo)}${missingRatesNote(incSum, expSum)}
        ` : `<div class="empty-state" style="padding:28px 10px;">
              <p>No financial transactions recorded yet. Figures will total here once income or expenses are logged.</p>
            </div>`}
      </div>
      <div class="panel">
        <h3>Getting started</h3>
        ${hasAnyData ? `
          <p style="color:var(--ink-soft);font-size:13.5px;line-height:1.6;">Keep building out records \u2014 add plantings, log growth stages, and track harvests as the season moves forward.</p>
        ` : `
          <p style="color:var(--ink-soft);font-size:13.5px;line-height:1.6;margin-bottom:12px;">Nothing recorded yet. A good first step:</p>
          <ol style="padding-left:18px;color:var(--ink-soft);font-size:13.5px;line-height:1.9;">
            <li>Add your <a href="#/farms" style="color:var(--olive-dark);font-weight:600;">first farm</a></li>
            <li>Break it into <a href="#/fields" style="color:var(--olive-dark);font-weight:600;">fields</a></li>
            <li>Record a <a href="#/crop_plantings" style="color:var(--olive-dark);font-weight:600;">planting</a> to start tracking a season</li>
          </ol>
        `}
      </div>
    </div>
  `;
}

/** Shown to people whose account isn't on a farm yet. */
function noFarmNote(){
  if (isAdmin || user.farmId) return '';
  return user.role === 'owner'
    ? `<div class="access-note">Your account isn't linked to a farm yet. <a href="#/farms" style="color:var(--olive-dark);font-weight:600;">Add your farm</a> and it becomes yours \u2014 then add your team to it in Team &amp; Roles.</div>`
    : `<div class="access-note">Your account isn't linked to a farm yet, so there's no farm data to show. Ask your farm owner or an administrator to add you to your farm in Team &amp; Roles.</div>`;
}

/* ---------------------------------------------------------------------- */
/* Notifications                                                          */
/* ---------------------------------------------------------------------- */
async function renderNotifications(){
  const view = document.getElementById('view');
  view.innerHTML = `<div class="empty-state"><p>Loading\u2026</p></div>`;
  const all = await fetchCached('notifications', true);
  const items = all.filter(n => Number(n.user_id) === Number(user.id));

  view.innerHTML = `
    ${bannerHtml('notifications')}
    <div class="page-head">
      <div><h1>Notifications</h1><p class="desc">Low stock, weather and task alerts land here.</p></div>
    </div>
    <div id="notifHost"></div>
  `;
  const host = document.getElementById('notifHost');
  if (!items.length){
    host.innerHTML = `
      <div class="table-wrap">
        <div class="empty-state">
          <div class="glyph">${icon('notifications', 44)}</div>
          <h3>You're all caught up</h3>
          <p>Alerts about low stock, upcoming irrigation, and due tasks will show up here as your data grows.</p>
        </div>
      </div>`;
    return;
  }
  host.innerHTML = `<div class="table-wrap"><table>
    <thead><tr><th>Type</th><th>Message</th><th>When</th></tr></thead>
    <tbody>${items.map(n => `<tr><td>${pill(n.alert_type)}</td><td>${escapeHtml(n.message)}</td><td>${n.created_at ? new Date(n.created_at).toLocaleString() : '\u2014'}</td></tr>`).join('')}</tbody>
  </table></div>`;
}

/* ---------------------------------------------------------------------- */
/* Live Weather & Maps \u2014 generated automatically from each farm's saved  */
/* coordinates, via Open-Meteo (free, no API key, CORS-open).             */
/* ---------------------------------------------------------------------- */
async function renderWeather(){
  const view = document.getElementById('view');
  view.innerHTML = `<div class="empty-state"><p>Loading\u2026</p></div>`;
  const farms = await fetchCached('farms', true);

  view.innerHTML = `
    ${bannerHtml('weather')}
    <div class="page-head">
      <div><h1>Weather & Maps</h1><p class="desc">Forecasts are generated automatically from each farm's saved coordinates \u2014 no manual entry needed.</p></div>
    </div>
    <div id="weatherHost"></div>
  `;
  const host = document.getElementById('weatherHost');

  const withCoords = farms.filter(f => f.latitude !== null && f.latitude !== '' && f.longitude !== null && f.longitude !== '');
  if (!farms.length){
    host.innerHTML = `<div class="table-wrap"><div class="empty-state">
      <div class="glyph">${icon('weather', 44)}</div>
      <h3>No farms yet</h3>
      <p>Add a farm with its latitude and longitude to see an automatic forecast here.</p>
      <a href="#/farms" class="btn btn-primary">Add a farm</a>
    </div></div>`;
    return;
  }

  host.innerHTML = farms.map(f => `
    <div class="panel">
      <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px;">
        <div>
          <h3 style="margin-bottom:2px;">${escapeHtml(f.farm_name)}</h3>
          <p class="help-text" style="margin:0;">${escapeHtml(f.address || 'No address on file')}${(f.latitude && f.longitude) ? ` \u00b7 ${f.latitude}, ${f.longitude}` : ''}</p>
        </div>
        ${(f.latitude && f.longitude)
          ? `<button class="btn btn-primary btn-sm load-forecast" data-id="${f.id}" data-lat="${f.latitude}" data-lon="${f.longitude}" data-name="${escapeHtml(f.farm_name)}">Load forecast</button>`
          : `<span class="pill pill-neutral">No coordinates saved</span>`}
      </div>
      <div id="forecast_${f.id}" style="margin-top:14px;"></div>
    </div>
  `).join('');

  host.querySelectorAll('.load-forecast').forEach(btn => btn.addEventListener('click', async () => {
    const { lat, lon, id, name } = btn.dataset;
    const target = document.getElementById(`forecast_${id}`);
    btn.disabled = true;
    btn.textContent = 'Loading\u2026';
    target.innerHTML = `<p class="help-text">Fetching forecast\u2026</p>`;
    try{
      const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=auto`;
      const res = await fetch(url);
      if (!res.ok) throw new Error('Weather service unavailable right now.');
      const data = await res.json();
      target.innerHTML = renderForecast(data, name);
    }catch(err){
      target.innerHTML = `<p class="help-text" style="color:var(--rust);">Couldn't load the forecast: ${escapeHtml(err.message)}</p>`;
    }finally{
      btn.disabled = false;
      btn.textContent = 'Reload forecast';
    }
  }));
}

function renderForecast(data, farmName){
  const cur = data.current || {};
  const daily = data.daily || {};
  const days = (daily.time || []).map((date, i) => ({
    date,
    low: daily.temperature_2m_min?.[i],
    high: daily.temperature_2m_max?.[i],
    rain: daily.precipitation_sum?.[i],
  }));

  return `
    <div class="stat-grid" style="grid-template-columns:repeat(3,1fr);margin-bottom:14px;">
      <div class="stat-card"><div class="label">Temperature</div><div class="value slate">${cur.temperature_2m ?? '\u2014'} \u00b0C</div></div>
      <div class="stat-card"><div class="label">Humidity</div><div class="value slate">${cur.relative_humidity_2m ?? '\u2014'}%</div></div>
      <div class="stat-card"><div class="label">Wind</div><div class="value slate">${cur.wind_speed_10m ?? '\u2014'} km/h</div></div>
    </div>
    <div class="table-wrap">
      <table>
        <thead><tr><th>Date</th><th>Low \u00b0C</th><th>High \u00b0C</th><th>Rain mm</th></tr></thead>
        <tbody>${days.map(d => `
          <tr>
            <td>${new Date(d.date).toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' })}</td>
            <td class="num">${d.low ?? '\u2014'}</td>
            <td class="num">${d.high ?? '\u2014'}</td>
            <td class="num">${d.rain ?? 0}</td>
          </tr>`).join('')}
        </tbody>
      </table>
    </div>
    <p class="help-text" style="margin-top:10px;">Weather data: <a href="https://open-meteo.com" target="_blank" rel="noopener" style="color:var(--olive-dark);">Open-Meteo</a>, generated from ${escapeHtml(farmName)}'s saved coordinates. Check local conditions before changing irrigation or field work.</p>
  `;
}

/* ---------------------------------------------------------------------- */
/* Team & Roles                                                           */
/* ---------------------------------------------------------------------- */
async function renderTeam(){
  const view = document.getElementById('view');
  view.innerHTML = `<div class="empty-state"><p>Loading\u2026</p></div>`;
  const [users, farms] = await Promise.all([Auth.listUsers(), isAdmin ? fetchCached('farms', true) : Promise.resolve([])]);
  const canEdit = ['admin', 'owner'].includes(user.role);
  const ROLE_OPTIONS = [
    ['admin','Administrator'],['owner','Farm Owner'],['manager','Farm Manager'],
    ['agronomist','Agronomist'],['accountant','Accountant'],['worker','Worker'],
  ].filter(([id]) => isAdmin || id !== 'admin');
  // Owners can only edit people on their own farm (or bring in people not on a farm yet).
  const editable = u => canEdit && u.id !== user.id && (isAdmin || (u.role !== 'admin' && (u.farmId === null || u.farmId === user.farmId)));
  function farmCell(u){
    if (u.role === 'admin') return '<span class="pill pill-slate">All farms</span>';
    if (!editable(u)) return u.farmName ? escapeHtml(u.farmName) : '<span class="pill pill-neutral">No farm</span>';
    const opts = isAdmin
      ? farms.map(f => [String(f.id), f.farm_name])
      : (user.farmId ? [[String(user.farmId), user.farmName || 'My farm']] : []);
    return `<select class="farm-edit" data-id="${u.id}">
      <option value="" ${u.farmId === null ? 'selected' : ''}>No farm</option>
      ${opts.map(([id, name]) => `<option value="${id}" ${String(u.farmId) === id ? 'selected' : ''}>${escapeHtml(name)}</option>`).join('')}
    </select>`;
  }

  view.innerHTML = `
    ${bannerHtml('team')}
    <div class="page-head">
      <div><h1>Team & Roles</h1><p class="desc">Everyone who can sign in, and what they're allowed to see and do.</p></div>
    </div>
    ${canEdit ? '' : `<div class="access-note">Only an Administrator or Farm Owner can change a teammate's role or status.</div>`}
    ${canEdit ? `<p class="help-text" style="margin:-8px 0 14px;">${isAdmin
      ? 'Each person belongs to one farm and only sees that farm\u2019s data. Administrators see every farm.'
      : 'Your team only sees your farm\u2019s data. New sign-ups appear here with \u201cNo farm\u201d \u2014 set their farm to add them to your team.'}</p>` : ''}
    <div class="table-wrap">
      <table>
        <thead><tr><th>Name</th><th>Email</th><th>Role</th><th>Farm</th><th>Status</th><th>Verified</th><th>Joined</th></tr></thead>
        <tbody>
          ${users.map(u => `
            <tr>
              <td>${escapeHtml(u.firstName)} ${escapeHtml(u.lastName)}${u.id === user.id ? ' <span class="pill pill-slate">You</span>' : ''}</td>
              <td>${escapeHtml(u.email)}</td>
              <td>
                ${editable(u)
                  ? `<select class="role-edit" data-id="${u.id}">${ROLE_OPTIONS.map(([id,label]) => `<option value="${id}" ${id===u.role?'selected':''}>${label}</option>`).join('')}</select>`
                  : Auth.roleLabel(u.role)}
              </td>
              <td>${farmCell(u)}</td>
              <td>
                ${editable(u)
                  ? `<select class="status-edit" data-id="${u.id}">
                      ${['active','inactive','suspended'].map(s => `<option value="${s}" ${s===u.status?'selected':''}>${s}</option>`).join('')}
                     </select>`
                  : pill(u.status)}
              </td>
              <td>${u.emailVerifiedAt ? pill('verified') : pill('pending')}</td>
              <td>${u.createdAt ? new Date(u.createdAt).toLocaleDateString() : '\u2014'}</td>
            </tr>`).join('')}
        </tbody>
      </table>
    </div>
  `;

  if (canEdit){
    view.querySelectorAll('.role-edit').forEach(sel => sel.addEventListener('change', async (e) => {
      try{
        await Auth.updateUser(Number(e.target.dataset.id), { role: e.target.value });
        toast('Role updated.');
      }catch(err){ toast(err.message || 'Could not update role.', true); }
      renderTeam();
    }));
    view.querySelectorAll('.farm-edit').forEach(sel => sel.addEventListener('change', async (e) => {
      try{
        await Auth.updateUser(Number(e.target.dataset.id), { farmId: e.target.value ? Number(e.target.value) : null });
        toast('Farm updated. They\u2019ll see the new farm next time they sign in.');
      }catch(err){ toast(err.message || 'Could not update farm.', true); }
      renderTeam();
    }));
    view.querySelectorAll('.status-edit').forEach(sel => sel.addEventListener('change', async (e) => {
      try{
        await Auth.updateUser(Number(e.target.dataset.id), { status: e.target.value });
        toast('Status updated.');
      }catch(err){ toast(err.message || 'Could not update status.', true); }
      renderTeam();
    }));
  }
}

/* ---------------------------------------------------------------------- */
/* Audit log \u2014 visible to Farm Owner and Administrator                   */
/* ---------------------------------------------------------------------- */
async function renderAudit(){
  const view = document.getElementById('view');
  view.innerHTML = `<div class="empty-state"><p>Loading\u2026</p></div>`;
  const logs = await Audit.list();

  view.innerHTML = `
    ${bannerHtml('audit_logs')}
    <div class="page-head">
      <div><h1>Audit Log</h1><p class="desc">Logins, password changes, and every create, update and delete \u2014 who did it, and when.</p></div>
    </div>
    <div id="auditHost"></div>
  `;
  const host = document.getElementById('auditHost');
  if (!logs.length){
    host.innerHTML = `<div class="table-wrap"><div class="empty-state">
      <div class="glyph">${icon('audit_logs', 44)}</div>
      <h3>Nothing logged yet</h3>
      <p>As people sign in and records are created, edited or removed, an entry will appear here.</p>
    </div></div>`;
    return;
  }
  host.innerHTML = `<div class="table-wrap"><table>
    <thead><tr><th>When</th><th>Who</th><th>Action</th><th>Table</th><th>Record</th><th>IP</th></tr></thead>
    <tbody>${logs.map(l => `
      <tr>
        <td>${new Date(l.createdAt).toLocaleString()}</td>
        <td>${escapeHtml(l.actor)}</td>
        <td>${pill(l.action)}</td>
        <td>${escapeHtml(l.tableAffected || '\u2014')}</td>
        <td class="num">${l.recordId ? '#' + l.recordId : '\u2014'}</td>
        <td class="num">${escapeHtml(l.ipAddress || '\u2014')}</td>
      </tr>`).join('')}</tbody>
  </table></div>`;
}

/* ---------------------------------------------------------------------- */
/* Reports                                                                */
/* ---------------------------------------------------------------------- */
async function renderReports(){
  const view = document.getElementById('view');
  view.innerHTML = `<div class="empty-state"><p>Loading\u2026</p></div>`;

  const [harvests, sales, finance] = await Promise.all([
    fetchCached('harvests', true), fetchCached('sales_orders', true), fetchCached('financial_transactions', true),
  ]);
  const totalHarvest = harvests.reduce((s,h)=>s+Number(h.quantity_harvested||0),0);
  const totalLoss = harvests.reduce((s,h)=>s+Number(h.loss_quantity||0),0);
  const codeOf = r => Cur.farmCurrency(r.farm_id);
  const allCodes = [...sales.map(codeOf), ...finance.map(codeOf)];
  const to = Cur.totalCurrency(allCodes);
  const salesSum = sumMoney(sales, o => o.total_amount, codeOf, to);
  const incSum = sumMoney(finance.filter(t => t.transaction_type === 'income'), t => t.amount, codeOf, to);
  const expSum = sumMoney(finance.filter(t => t.transaction_type === 'expense'), t => t.amount, codeOf, to);
  const totalSales = salesSum.total, totalIncome = incSum.total, totalExpense = expSum.total;
  const fmtTotal = v => Cur.formatMoney(v, to, 0);
  const anyData = harvests.length || sales.length || finance.length;

  view.innerHTML = `
    ${bannerHtml('reports')}
    <div class="page-head">
      <div><h1>Reports & Analytics</h1><p class="desc">Rolled-up figures across harvests, sales and finance. Updates automatically as records are added.</p></div>
    </div>
    ${anyData ? `
      <div class="stat-grid">
        <div class="stat-card"><div class="label">Total harvested</div><div class="value olive num">${totalHarvest.toLocaleString()}</div></div>
        <div class="stat-card"><div class="label">Total post-harvest loss</div><div class="value rust num">${totalLoss.toLocaleString()}</div></div>
        <div class="stat-card"><div class="label">Total sales value</div><div class="value ochre num">${fmtTotal(totalSales)}</div></div>
        <div class="stat-card"><div class="label">Recorded income</div><div class="value olive num">${fmtTotal(totalIncome)}</div></div>
        <div class="stat-card"><div class="label">Recorded expense</div><div class="value rust num">${fmtTotal(totalExpense)}</div></div>
        <div class="stat-card"><div class="label">Net</div><div class="value num">${fmtTotal(totalIncome - totalExpense)}</div></div>
      </div>
      ${Cur.ratesNoteHtml(new Set(allCodes), to)}${missingRatesNote(salesSum, incSum, expSum)}
    ` : `
      <div class="table-wrap"><div class="empty-state">
        <div class="glyph">${icon('reports', 44)}</div>
        <h3>Nothing to report yet</h3>
        <p>Once harvests, sales orders or financial transactions are recorded, summary figures will appear here.</p>
      </div></div>
    `}
  `;
}

/* ---------------------------------------------------------------------- */
/* Router                                                                 */
/* ---------------------------------------------------------------------- */
async function renderRoute(){
  const hash = window.location.hash.replace('#/', '') || 'dashboard';
  const def = ENTITIES[hash];
  window.scrollTo(0, 0);

  if (!def || !def.roles.includes(user.role)){
    document.getElementById('view').innerHTML = `
      <div class="table-wrap"><div class="empty-state">
        <h3>Access restricted</h3>
        <p>Your role (${Auth.roleLabel(user.role)}) doesn't have access to this module.</p>
        <a href="#/dashboard" class="btn btn-primary">Back to dashboard</a>
      </div></div>`;
    buildSidebar(null);
    return;
  }

  setSidebarOpen(false);
  buildSidebar(hash);
  refreshFarmPicker();
  await refreshCurrencyPicker().catch(() => {});

  try{
    if (hash === 'dashboard') return await renderDashboard();
    if (def.special === 'ai_overview') return await renderAiOverview({ user, fetchCached, escapeHtml, bannerHtml, icon });
    if (hash === 'notifications') return await renderNotifications();
    if (def.special === 'weather') return await renderWeather();
    if (def.special === 'team') return await renderTeam();
    if (def.special === 'audit') return await renderAudit();
    if (hash === 'reports') return await renderReports();
    return await renderEntityView(hash);
  }catch(err){
    document.getElementById('view').innerHTML = `
      <div class="table-wrap"><div class="empty-state">
        <h3>Couldn't load this page</h3>
        <p>${escapeHtml(err.message || 'Something went wrong while fetching data.')}</p>
        <button class="btn btn-primary" id="retryRoute">Try again</button>
      </div></div>`;
    document.getElementById('retryRoute')?.addEventListener('click', () => renderRoute());
  }
}

window.addEventListener('hashchange', () => { renderRoute(); });
// Today's exchange rates (cached for 12 hours); never holds the page up for more than a few seconds.
await Cur.ratesReady();
renderRoute();
