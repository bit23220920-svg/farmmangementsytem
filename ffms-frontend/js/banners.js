/* ==========================================================================
   Module banners. Every category uses a real photo (brown-tinted so it sits
   in the Natural palette). The illustrated SVGs below are only a fallback
   if a photo is ever removed.
   To change a photo, drop a new file into images/banners/ with the same name.
   ========================================================================== */

const PHOTO_BANNERS = {
  fields:      'images/banners/fields.jpg',
  water:       'images/banners/water.jpg',
  livestock:   'images/banners/livestock.jpg',
  inventory:   'images/banners/inventory.jpg',
  equipment:   'images/banners/equipment.jpg',
  people:      'images/banners/people.jpg',
  environment: 'images/banners/environment.jpg',
  overview:    'images/banners/overview.jpg',
  protection:  'images/banners/protection.jpg',
  market:      'images/banners/market.jpg',
  finance:     'images/banners/finance.jpg',
  admin:       'images/banners/admin.jpg',
};

const SKY = (top, bottom) => `<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="${top}"/><stop offset="1" stop-color="${bottom}"/>
</linearGradient></defs><rect width="100%" height="100%" fill="url(#sky)"/>`;

const SVG_BANNERS = {
  market: `<svg viewBox="0 0 800 200" preserveAspectRatio="xMidYMid slice" xmlns="http://www.w3.org/2000/svg">
    ${SKY('#F0E4D2', '#D6B98F')}
    <rect x="0" y="170" width="800" height="30" fill="#8A6A4C"/>
    <g fill="#997B66">
      <rect x="120" y="110" width="120" height="60" rx="4"/>
      <polygon points="110,110 250,110 230,80 130,80" fill="#CB997E"/>
    </g>
    <g fill="#B98A5F">
      <rect x="480" y="120" width="110" height="50" rx="4"/>
      <polygon points="470,120 600,120 582,92 488,92" fill="#E9C9AE"/>
    </g>
    <circle cx="700" cy="150" r="16" fill="#EDC65F"/>
    <circle cx="730" cy="160" r="12" fill="#EDC65F"/>
  </svg>`,

  admin: `<svg viewBox="0 0 800 200" preserveAspectRatio="xMidYMid slice" xmlns="http://www.w3.org/2000/svg">
    <rect width="100%" height="100%" fill="#6E5A48"/>
    ${Array.from({length:10}).map((_,i)=>`<rect x="${i*92-30}" y="0" width="46" height="200" fill="#7C654F" transform="skewX(-12)"/>`).join('')}
  </svg>`,
};

const GROUP_BANNER = {
  'Overview': 'overview',
  'Land & Crops': 'fields',
  'Water': 'water',
  'Livestock': 'livestock',
  'Inventory & Buying': 'inventory',
  'Equipment': 'equipment',
  'People & Tasks': 'people',
  'Crop Protection': 'protection',
  'Environment': 'environment',
  'Harvest & Storage': 'inventory',
  'Sales': 'market',
  'Finance': 'finance',
  'Administration': 'admin',
};

export function bannerKeyForGroup(groupLabel){
  return GROUP_BANNER[groupLabel] || 'admin';
}

/** Returns the markup to place inside .module-banner: an <img> for photo banners, inline SVG otherwise. */
export function bannerMarkup(key){
  if (PHOTO_BANNERS[key]){
    return `<img src="${PHOTO_BANNERS[key]}" alt="" decoding="async">`;
  }
  return SVG_BANNERS[key] || SVG_BANNERS.admin;
}
