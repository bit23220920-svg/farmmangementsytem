/* ==========================================================================
   Lightweight inline-SVG charts for the AI Farm Overview Analysis page.
   No chart library and no build step — same as the rest of the front end.
   Every mark carries a data-tip attribute; bindChartTips() shows it in a
   floating tooltip on hover/tap. Each chart also gets a "View as table".
   ========================================================================== */

/* Categorical order (validated for colour-vision deficiency on white). */
export const SERIES = ['#9C5A1E', '#008C85', '#C7861A', '#4F68B8', '#C0392B'];
export const INCOME = '#008C85';
export const EXPENSE = '#C0392B';
export const NET = 'var(--chart-net)';   /* follows light/dark theme */
/* Ordinal severity ramp (light → dark, one hue). */
export const SEVERITY = { low: '#E9B9A9', moderate: '#D9826A', high: '#C0392B', severe: '#7E2118' };

const DEFAULT_W = 640;
const GRID = 'var(--chart-grid)';
const AXIS = 'var(--chart-axis)';

function esc(s){
  if (s === null || s === undefined) return '';
  return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

export function fmtNum(v, digits = 0){
  if (v === null || v === undefined || !Number.isFinite(Number(v))) return '—';
  return Number(v).toLocaleString(undefined, { maximumFractionDigits: digits, minimumFractionDigits: 0 });
}
function compact(v){
  const a = Math.abs(v);
  if (a >= 1e6) return (v / 1e6).toFixed(a >= 1e7 ? 0 : 1).replace(/\.0$/, '') + 'M';
  if (a >= 1e3) return (v / 1e3).toFixed(a >= 1e4 ? 0 : 1).replace(/\.0$/, '') + 'k';
  return String(Math.round(v * 100) / 100);
}

function niceStep(range, count){
  const raw = range / Math.max(1, count);
  const p = Math.pow(10, Math.floor(Math.log10(raw || 1)));
  const n = raw / p;
  return (n <= 1 ? 1 : n <= 2 ? 2 : n <= 2.5 ? 2.5 : n <= 5 ? 5 : 10) * p;
}
function domain(min, max, count = 4){
  if (min === max){ max = min + 1; }
  min = Math.min(0, min); max = Math.max(0, max);
  const step = niceStep(max - min, count);
  const lo = Math.floor(min / step) * step;
  const hi = Math.ceil(max / step) * step;
  const ticks = [];
  for (let v = lo; v <= hi + step / 2; v += step) ticks.push(Math.round(v * 1e6) / 1e6);
  return { lo, hi, ticks };
}

/** A bar path rounded (4px) at the data end only, square on the baseline. */
function barPath(x, y0, w, y1, r = 4){
  const up = y1 < y0;
  const h = Math.abs(y1 - y0);
  r = Math.min(r, w / 2, h);
  if (h < 0.5) return '';
  if (up){
    return `M${x},${y0}V${y1 + r}Q${x},${y1} ${x + r},${y1}H${x + w - r}Q${x + w},${y1} ${x + w},${y1 + r}V${y0}Z`;
  }
  return `M${x},${y0}V${y1 - r}Q${x},${y1} ${x + r},${y1}H${x + w - r}Q${x + w},${y1} ${x + w},${y1 - r}V${y0}Z`;
}

export function legend(series){
  if (series.length < 2) return '';
  return `<div class="ai-legend">${series.map(s => `<span><i style="background:${s.color}"></i>${esc(s.name)}</span>`).join('')}</div>`;
}

function tableView(headers, rows){
  return `<details class="ai-table"><summary>View as table</summary>
    <div class="table-wrap"><table>
      <thead><tr>${headers.map(h => `<th>${esc(h)}</th>`).join('')}</tr></thead>
      <tbody>${rows.map(r => `<tr>${r.map((c, i) => `<td${i ? ' class="num"' : ''}>${esc(c)}</td>`).join('')}</tr>`).join('')}</tbody>
    </table></div></details>`;
}

function emptyChart(msg){
  return `<div class="ai-chart-empty">${esc(msg)}</div>`;
}

/**
 * Vertical bar chart. series: [{name, color, values:[...]}] aligned with cats.
 * opts: { stacked, height, fmt, colorFor(value, seriesIndex) , empty }
 */
export function barChart(cats, series, opts = {}){
  const W = opts.width || DEFAULT_W;
  const H = opts.height || 230;
  const fmt = opts.fmt || (v => fmtNum(v, 2));
  const hasData = series.some(s => s.values.some(v => Number(v)));
  if (!cats.length || !hasData) return emptyChart(opts.empty || 'No data recorded for this chart yet.');

  const L = 52, R = 10, T = 12, B = 34;
  const pw = W - L - R, ph = H - T - B;
  let min = 0, max = 0;
  cats.forEach((_, i) => {
    if (opts.stacked){
      let pos = 0, neg = 0;
      series.forEach(s => { const v = Number(s.values[i]) || 0; if (v >= 0) pos += v; else neg += v; });
      max = Math.max(max, pos); min = Math.min(min, neg);
    } else {
      series.forEach(s => { const v = Number(s.values[i]) || 0; max = Math.max(max, v); min = Math.min(min, v); });
    }
  });
  const d = domain(min, max);
  const y = v => T + ph - ((v - d.lo) / (d.hi - d.lo)) * ph;
  const band = pw / cats.length;
  const groups = opts.stacked ? 1 : series.length;
  const bw = Math.max(3, Math.min(30, (band * 0.72 - (groups - 1) * 2) / groups));
  const groupW = bw * groups + (groups - 1) * 2;
  const labelEvery = Math.max(1, Math.ceil(cats.length / Math.max(1, Math.floor(pw / 46))));

  let svg = '';
  d.ticks.forEach(t => {
    svg += `<line x1="${L}" x2="${W - R}" y1="${y(t)}" y2="${y(t)}" stroke="${t === 0 ? AXIS : GRID}" stroke-width="1"/>`;
    svg += `<text x="${L - 8}" y="${y(t) + 4}" text-anchor="end" class="ai-axis">${compact(t)}</text>`;
  });
  cats.forEach((c, i) => {
    const gx = L + band * i + (band - groupW) / 2;
    let pos = 0, neg = 0;
    series.forEach((s, si) => {
      const v = Number(s.values[i]) || 0;
      if (!v) return;
      const color = opts.colorFor ? opts.colorFor(v, si) : s.color;
      let x, y0, y1;
      if (opts.stacked){
        x = gx;
        if (v >= 0){ y0 = y(pos); pos += v; y1 = y(pos); }
        else { y0 = y(neg); neg += v; y1 = y(neg); }
        // 2px surface gap between stacked segments
        if (v >= 0 && pos !== v) y0 -= 2; else if (v < 0 && neg !== v) y0 += 2;
      } else {
        x = gx + si * (bw + 2);
        y0 = y(0); y1 = y(v);
      }
      const tip = `${c} · ${s.name}: ${fmt(v)}`;
      svg += `<path d="${barPath(x, y0, bw, y1)}" fill="${color}" data-tip="${esc(tip)}"/>`;
      // bigger, invisible hit target
      svg += `<rect x="${x - 2}" y="${Math.min(y0, y1) - 4}" width="${bw + 4}" height="${Math.abs(y1 - y0) + 8}" fill="transparent" data-tip="${esc(tip)}"/>`;
    });
    if (i % labelEvery === 0){
      svg += `<text x="${L + band * i + band / 2}" y="${H - B + 18}" text-anchor="middle" class="ai-axis">${esc(String(c).length > 10 ? String(c).slice(0, 9) + '…' : c)}</text>`;
    }
  });

  return `${legend(series)}
    <div class="ai-chart"><svg viewBox="0 0 ${W} ${H}" role="img" aria-label="${esc(opts.title || 'Bar chart')}">${svg}</svg></div>
    ${tableView(['', ...series.map(s => s.name)], cats.map((c, i) => [c, ...series.map(s => fmt(Number(s.values[i]) || 0))]))}`;
}

/** Horizontal bars for ranked categories. items: [{label, value, color?}] */
export function hbarChart(items, opts = {}){
  const W = opts.width || DEFAULT_W;
  const fmt = opts.fmt || (v => fmtNum(v, 2));
  items = items.filter(i => Number(i.value));
  if (!items.length) return emptyChart(opts.empty || 'No data recorded for this chart yet.');
  const rowH = 26, T = 6, L = Math.min(150, Math.round(W * 0.34)), R = 64;
  const H = T * 2 + items.length * rowH;
  const max = Math.max(...items.map(i => Math.abs(i.value)));
  const pw = W - L - R;
  let svg = '';
  items.forEach((it, i) => {
    const yy = T + i * rowH;
    const w = Math.max(2, (Math.abs(it.value) / max) * pw);
    const label = String(it.label).length > 22 ? String(it.label).slice(0, 21) + '…' : it.label;
    const tip = `${it.label}: ${fmt(it.value)}`;
    svg += `<text x="${L - 10}" y="${yy + 17}" text-anchor="end" class="ai-axis ai-axis-strong">${esc(label)}</text>`;
    svg += `<path d="M${L},${yy + 5}H${L + w - 4}Q${L + w},${yy + 5} ${L + w},${yy + 9}V${yy + 17}Q${L + w},${yy + 21} ${L + w - 4},${yy + 21}H${L}Z" fill="${it.color || opts.color || SERIES[0]}" data-tip="${esc(tip)}"/>`;
    svg += `<rect x="${L}" y="${yy}" width="${pw}" height="${rowH}" fill="transparent" data-tip="${esc(tip)}"/>`;
    svg += `<text x="${L + w + 8}" y="${yy + 17}" class="ai-axis">${esc(fmt(it.value))}</text>`;
  });
  return `<div class="ai-chart"><svg viewBox="0 0 ${W} ${H}" role="img" aria-label="${esc(opts.title || 'Bar chart')}">
      <line x1="${L}" x2="${L}" y1="0" y2="${H}" stroke="${AXIS}"/>${svg}</svg></div>
    ${tableView(['', opts.valueLabel || 'Value'], items.map(i => [i.label, fmt(i.value)]))}`;
}

/**
 * Time-series line chart. series: [{name, color, points:[[Date, value], ...]}]
 */
export function lineChart(series, opts = {}){
  const W = opts.width || DEFAULT_W;
  const H = opts.height || 240;
  const fmt = opts.fmt || (v => fmtNum(v, 1));
  series = series.filter(s => s.points.length);
  if (!series.length) return emptyChart(opts.empty || 'No data recorded for this chart yet.');

  const L = 52, R = 14, T = 14, B = 34;
  const pw = W - L - R, ph = H - T - B;
  const all = series.flatMap(s => s.points);
  let xmin = Math.min(...all.map(p => +p[0])), xmax = Math.max(...all.map(p => +p[0]));
  if (xmin === xmax){ xmin -= 864e5 * 3; xmax += 864e5 * 3; }
  const vals = all.map(p => p[1]);
  const d = domain(Math.min(...vals), Math.max(...vals));
  const x = t => L + ((+t - xmin) / (xmax - xmin)) * pw;
  const y = v => T + ph - ((v - d.lo) / (d.hi - d.lo)) * ph;

  let svg = '';
  d.ticks.forEach(t => {
    svg += `<line x1="${L}" x2="${W - R}" y1="${y(t)}" y2="${y(t)}" stroke="${t === 0 ? AXIS : GRID}"/>`;
    svg += `<text x="${L - 8}" y="${y(t) + 4}" text-anchor="end" class="ai-axis">${compact(t)}</text>`;
  });
  const spanDays = (xmax - xmin) / 864e5;
  const nT = W < 420 ? 3 : 5;
  for (let i = 0; i <= nT; i++){
    const t = new Date(xmin + (xmax - xmin) * i / nT);
    const label = spanDays > 400
      ? t.toLocaleDateString(undefined, { month: 'short', year: '2-digit' })
      : t.toLocaleDateString(undefined, { day: 'numeric', month: 'short' });
    svg += `<text x="${x(t)}" y="${H - B + 18}" text-anchor="${i === 0 ? 'start' : i === nT ? 'end' : 'middle'}" class="ai-axis">${esc(label)}</text>`;
  }
  series.forEach(s => {
    const pts = [...s.points].sort((a, b) => a[0] - b[0]);
    if (pts.length > 1){
      svg += `<path d="${pts.map((p, i) => `${i ? 'L' : 'M'}${x(p[0]).toFixed(1)},${y(p[1]).toFixed(1)}`).join('')}" fill="none" stroke="${s.color}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>`;
    }
    pts.forEach(p => {
      const tip = `${s.name} · ${p[0].toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' })}: ${fmt(p[1])}`;
      svg += `<circle cx="${x(p[0])}" cy="${y(p[1])}" r="4" fill="${s.color}" stroke="var(--chart-dot)" stroke-width="2"/>`;
      svg += `<circle cx="${x(p[0])}" cy="${y(p[1])}" r="11" fill="transparent" data-tip="${esc(tip)}"/>`;
    });
  });
  // direct label at the end of each line when there are few series
  if (series.length >= 2 && series.length <= 4){
    series.forEach(s => {
      const last = [...s.points].sort((a, b) => a[0] - b[0]).at(-1);
      svg += `<text x="${x(last[0]) - 8}" y="${y(last[1]) - 9}" text-anchor="end" class="ai-axis ai-axis-strong">${esc(String(s.short || s.name).slice(0, 18))}</text>`;
    });
  }

  const rows = series.flatMap(s => s.points.map(p => [s.name, p[0].toLocaleDateString(), fmt(p[1])]));
  return `${legend(series)}
    <div class="ai-chart"><svg viewBox="0 0 ${W} ${H}" role="img" aria-label="${esc(opts.title || 'Line chart')}">${svg}</svg></div>
    ${tableView(['Series', 'Date', opts.valueLabel || 'Value'], rows)}`;
}

/**
 * Charts are drawn at the real pixel width of their container (so text
 * stays 11px everywhere). chartSlot() returns a placeholder; after the
 * HTML is in the page, fillChartSlots() measures and draws each one, and
 * redraws on resize.
 */
let slots = [];
export function chartSlot(draw){
  slots.push(draw);
  return `<div class="ai-chart-slot" data-slot="${slots.length - 1}"></div>`;
}
export function resetChartSlots(){ slots = []; }
export function fillChartSlots(root){
  const current = slots;
  const paint = () => {
    root.querySelectorAll('.ai-chart-slot').forEach(el => {
      const draw = current[Number(el.dataset.slot)];
      if (!draw) return;
      const w = Math.max(260, Math.floor(el.clientWidth || 600));
      if (el.dataset.w === String(w)) return;
      el.dataset.w = String(w);
      el.innerHTML = draw(w);
    });
    bindChartTips(root);
  };
  paint();
  if (fillChartSlots._onResize) window.removeEventListener('resize', fillChartSlots._onResize);
  let t = null;
  fillChartSlots._onResize = () => { clearTimeout(t); t = setTimeout(() => { if (document.body.contains(root)) paint(); }, 150); };
  window.addEventListener('resize', fillChartSlots._onResize);
}

/** Score ring (0–100) with the number in the middle. */
export function scoreRing(score, label){
  const r = 46, c = 2 * Math.PI * r;
  const s = Math.max(0, Math.min(100, Math.round(score)));
  const color = s >= 75 ? INCOME : s >= 50 ? '#C7861A' : EXPENSE;
  return `<svg viewBox="0 0 120 120" class="ai-ring" role="img" aria-label="${esc(label)}: ${s} out of 100">
    <circle cx="60" cy="60" r="${r}" fill="none" stroke="${GRID}" stroke-width="10"/>
    <circle cx="60" cy="60" r="${r}" fill="none" stroke="${color}" stroke-width="10" stroke-linecap="round"
      stroke-dasharray="${(c * s / 100).toFixed(1)} ${c.toFixed(1)}" transform="rotate(-90 60 60)"/>
    <text x="60" y="64" text-anchor="middle" class="ai-ring-num">${s}</text>
    <text x="60" y="82" text-anchor="middle" class="ai-ring-sub">/ 100</text>
  </svg>`;
}

/** One floating tooltip for every [data-tip] inside root. */
export function bindChartTips(root){
  let tip = document.getElementById('aiTip');
  if (!tip){
    tip = document.createElement('div');
    tip.id = 'aiTip';
    tip.className = 'ai-tip';
    document.body.appendChild(tip);
  }
  const show = (e, text) => {
    tip.textContent = text;
    tip.style.display = 'block';
    const pad = 14;
    let left = e.clientX + pad, top = e.clientY + pad;
    const r = tip.getBoundingClientRect();
    if (left + r.width > window.innerWidth - 8) left = e.clientX - r.width - pad;
    if (top + r.height > window.innerHeight - 8) top = e.clientY - r.height - pad;
    tip.style.left = left + 'px';
    tip.style.top = top + 'px';
  };
  root.querySelectorAll('[data-tip]').forEach(el => {
    el.addEventListener('mousemove', e => show(e, el.dataset.tip));
    el.addEventListener('mouseleave', () => { tip.style.display = 'none'; });
    el.addEventListener('click', e => show(e, el.dataset.tip));
  });
  window.addEventListener('scroll', () => { tip.style.display = 'none'; }, { passive: true, once: true });
}
