/* ==========================================================================
   Map location picker — search a place or click the map to drop a pin.
   Uses Leaflet + OpenStreetMap (free, no API key). Leaflet itself is loaded
   by a <script> tag in app.html and exposed as the global `L`.
   ========================================================================== */

const DEFAULT_CENTER = [-13.1339, 27.8493];   // Zambia
const DEFAULT_ZOOM = 6;

async function searchPlaces(query){
  const url = `https://nominatim.openstreetmap.org/search?format=jsonv2&limit=6&q=${encodeURIComponent(query)}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error('Place search is unavailable right now.');
  return res.json();
}

async function reverseGeocode(lat, lng){
  const url = `https://nominatim.openstreetmap.org/reverse?format=jsonv2&zoom=16&lat=${lat}&lon=${lng}`;
  const res = await fetch(url);
  if (!res.ok) return null;
  const data = await res.json();
  return data && data.display_name ? data.display_name : null;
}

function esc(s){
  return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

/**
 * @param {HTMLElement} host   element to render the picker into
 * @param {{lat?:number|string, lng?:number|string,
 *          onPick:(p:{lat:number,lng:number})=>void,
 *          onAddress?:(text:string)=>void}} opts
 * @returns {{destroy:()=>void, setPoint:(lat:number,lng:number,zoom?:number)=>void}}
 */
export function mountMapPicker(host, { lat, lng, onPick, onAddress }){
  host.innerHTML = `
    <div class="map-picker">
      <label>Farm location</label>
      <div class="map-search">
        <input type="text" placeholder="Search a town, address or landmark…" aria-label="Search for a place">
        <button type="button" class="btn btn-primary btn-sm" data-act="search">Search</button>
        <button type="button" class="btn btn-ghost btn-sm" data-act="locate">My location</button>
      </div>
      <ul class="map-results"></ul>
      <div class="map-canvas"></div>
      <p class="map-status">Search above, or click the map to drop a pin. You can drag the pin to fine-tune it.</p>
    </div>`;

  const input = host.querySelector('.map-search input');
  const results = host.querySelector('.map-results');
  const status = host.querySelector('.map-status');
  const canvas = host.querySelector('.map-canvas');

  const say = (msg, isErr = false) => { status.textContent = msg; status.classList.toggle('err', isErr); };

  if (!window.L){
    canvas.style.display = 'none';
    host.querySelector('.map-search').style.display = 'none';
    say('The map could not load (check your internet connection). You can still type the latitude and longitude below.', true);
    return { destroy(){}, setPoint(){} };
  }

  const startLat = parseFloat(lat), startLng = parseFloat(lng);
  const hasStart = Number.isFinite(startLat) && Number.isFinite(startLng);

  const map = L.map(canvas, { scrollWheelZoom: true })
    .setView(hasStart ? [startLat, startLng] : DEFAULT_CENTER, hasStart ? 14 : DEFAULT_ZOOM);

  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
  }).addTo(map);

  let marker = null;

  function place(latV, lngV, { zoom, pan = true, lookupAddress = true } = {}){
    const p = [latV, lngV];
    if (!marker){
      marker = L.marker(p, { draggable: true }).addTo(map);
      marker.on('dragend', () => {
        const ll = marker.getLatLng();
        picked(ll.lat, ll.lng, true);
      });
    } else {
      marker.setLatLng(p);
    }
    if (pan) map.setView(p, zoom || Math.max(map.getZoom(), 14));
    onPick({ lat: +latV.toFixed(6), lng: +lngV.toFixed(6) });
    if (lookupAddress) fillAddress(latV, lngV);
  }

  function picked(latV, lngV, lookup){
    onPick({ lat: +latV.toFixed(6), lng: +lngV.toFixed(6) });
    if (lookup) fillAddress(latV, lngV);
  }

  async function fillAddress(latV, lngV){
    if (!onAddress) return;
    say('Looking up the address…');
    try{
      const text = await reverseGeocode(latV, lngV);
      if (text){ onAddress(text); say('Location set. Drag the pin or click elsewhere to change it.'); }
      else say('Location set (no street address found for this spot).');
    }catch(e){
      say('Location set (could not look up the address).');
    }
  }

  if (hasStart) place(startLat, startLng, { pan: false, lookupAddress: false });

  map.on('click', (e) => place(e.latlng.lat, e.latlng.lng, { pan: false }));

  async function doSearch(){
    const q = input.value.trim();
    if (!q) return;
    results.innerHTML = '';
    say('Searching…');
    try{
      const found = await searchPlaces(q);
      if (!found.length){ say('No places found. Try a nearby town or add the country name.', true); return; }
      say('Pick the right place from the list.');
      results.innerHTML = found.map((r, i) => `<li data-i="${i}">${esc(r.display_name)}</li>`).join('');
      results.querySelectorAll('li').forEach(li => li.addEventListener('click', () => {
        const r = found[Number(li.dataset.i)];
        results.innerHTML = '';
        input.value = r.display_name;
        place(parseFloat(r.lat), parseFloat(r.lon), { zoom: 15, lookupAddress: false });
        if (onAddress) onAddress(r.display_name);
        say('Location set. Drag the pin or click elsewhere to fine-tune it.');
      }));
    }catch(err){
      say(err.message || 'Search failed. Try again.', true);
    }
  }

  host.querySelector('[data-act="search"]').addEventListener('click', doSearch);
  input.addEventListener('keydown', (e) => { if (e.key === 'Enter'){ e.preventDefault(); doSearch(); } });

  host.querySelector('[data-act="locate"]').addEventListener('click', () => {
    if (!navigator.geolocation){ say('Your browser does not support location lookup.', true); return; }
    say('Finding your location…');
    navigator.geolocation.getCurrentPosition(
      (pos) => place(pos.coords.latitude, pos.coords.longitude, { zoom: 16 }),
      () => say('Could not get your location (permission denied?). Search or click the map instead.', true),
      { enableHighAccuracy: true, timeout: 10000 }
    );
  });

  // The drawer slides in, so the map needs to re-measure itself once it has settled.
  setTimeout(() => map.invalidateSize(), 300);
  setTimeout(() => map.invalidateSize(), 700);

  return {
    destroy(){ map.remove(); },
    setPoint(latV, lngV, zoom){ place(latV, lngV, { zoom, lookupAddress: false }); },
  };
}
