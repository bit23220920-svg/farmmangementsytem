/* ==========================================================================
   FFMS Schema — one config object per entity drives the generic list/form
   engine in app.js. `fields` define the add/edit drawer; `columns` define
   what shows in the table (defaults to fields if omitted).
   Field types: text, textarea, number, date, datetime, select
   Extra field options:
     money: true   an amount in the farm's currency (converted for display)
     options       list of values, list of {value, label}, or a function
     blank         text for an empty first choice in a select
     fills         { field, with(value) } sets another field when this changes
     cell(value)   text shown in the table instead of the raw value
     help          a hint under the field in the form
   ========================================================================== */
import { ROLES } from './store.js';
import { countryOptions, currencyOptions, currencyForCountry, countryName } from './currency.js';

const ALL = ROLES.map(r => r.id);

export const NAV_GROUPS = [
  {
    label: 'Overview',
    items: ['dashboard', 'ai_overview', 'notifications'],
  },
  {
    label: 'Land & Crops',
    items: ['farms', 'fields', 'crop_varieties', 'crop_plantings', 'crop_growth_logs'],
  },
  {
    label: 'Water',
    items: ['water_sources', 'irrigation_systems', 'irrigation_schedules'],
  },
  {
    label: 'Livestock',
    items: ['livestock', 'livestock_health_records', 'livestock_production_logs', 'livestock_feed_logs'],
  },
  {
    label: 'Inventory & Buying',
    items: ['inventory_items', 'inventory_batches', 'inventory_transactions', 'suppliers', 'purchase_orders'],
  },
  {
    label: 'Equipment',
    items: ['machinery', 'machinery_maintenance', 'machinery_usage'],
  },
  {
    label: 'People & Tasks',
    items: ['employees', 'task_allocations', 'labor_assignments'],
  },
  {
    label: 'Crop Protection',
    items: ['pest_disease_catalog', 'scouting_records', 'chemical_applications'],
  },
  {
    label: 'Environment',
    items: ['weather', 'weather_logs'],
  },
  {
    label: 'Harvest & Storage',
    items: ['harvests', 'warehouses', 'produce_storage'],
  },
  {
    label: 'Sales',
    items: ['customers', 'sales_orders', 'sales_order_items'],
  },
  {
    label: 'Finance',
    items: ['financial_transactions', 'reports'],
  },
  {
    label: 'Administration',
    items: ['team', 'audit_logs'],
  },
];

// icons: small stroke-based glyphs (24x24 viewBox), reused across nav + empty states
export const ICONS = {
  dashboard: '<path d="M4 13h7V4H4v9Zm9 7h7v-9h-7v9ZM4 20h7v-5H4v5ZM13 4v5h7V4h-7Z"/>',
  ai_overview: '<path d="M12 3l1.8 4.7 4.7 1.8-4.7 1.8L12 16l-1.8-4.7-4.7-1.8 4.7-1.8L12 3Z"/><path d="M19 15l.8 2.2 2.2.8-2.2.8L19 21l-.8-2.2-2.2-.8 2.2-.8L19 15ZM5 16l.6 1.4L7 18l-1.4.6L5 20l-.6-1.4L3 18l1.4-.6L5 16Z"/>',
  notifications: '<path d="M12 22a2.2 2.2 0 0 0 2.2-2.2h-4.4A2.2 2.2 0 0 0 12 22Zm7-6v-5a7 7 0 0 0-5-6.7V3a2 2 0 1 0-4 0v1.3A7 7 0 0 0 5 11v5l-2 2v1h16v-1l-2-2Z"/>',
  farms: '<path d="M3 20h18M5 20V10l7-6 7 6v10M9 20v-6h6v6"/>',
  fields: '<path d="M3 3h18v18H3z"/><path d="M3 9h18M3 15h18M9 3v18M15 3v18"/>',
  crop_varieties: '<path d="M12 22V12M12 12C7 12 5 8 5 4c5 0 7 3 7 8Zm0 0c5 0 7-4 7-8-5 0-7 3-7 8Z"/>',
  crop_plantings: '<path d="M12 3v11M8 8l4-4 4 4"/><path d="M4 21c1.5-4 4-6 8-6s6.5 2 8 6"/>',
  crop_growth_logs: '<path d="M3 20h18M6 20V9M12 20V4M18 20v13"/>',
  water_sources: '<path d="M12 3s6 6.5 6 11a6 6 0 1 1-12 0c0-4.5 6-11 6-11Z"/>',
  irrigation_systems: '<path d="M12 2v6M5 11h14M12 11v11M7 15v4M17 15v4"/>',
  irrigation_schedules: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  livestock: '<path d="M4 15c0-3 2-5 5-5h6c3 0 5 2 5 5v2a3 3 0 0 1-3 3H7a3 3 0 0 1-3-3v-2Z"/><path d="M8 10V7M16 10V7"/>',
  livestock_health_records: '<path d="M9 3h6l1 4h3v4l-4 1v9h-6v-9l-4-1V7h3l1-4Z"/>',
  livestock_production_logs: '<path d="M4 4h16v6H4zM4 14h10v6H4z"/>',
  livestock_feed_logs: '<path d="M4 4h16l-2 8H6L4 4Z"/><path d="M8 12v8M16 12v8"/>',
  inventory_items: '<path d="M3 7l9-4 9 4-9 4-9-4Z"/><path d="M3 7v10l9 4 9-4V7M12 11v10"/>',
  inventory_batches: '<path d="M4 4h16v6H4zM4 14h16v6H4z"/>',
  inventory_transactions: '<path d="M7 7h13l-2 6H9L7 7Z"/><path d="M7 7 5 3H2M9 21a1 1 0 1 0 0-2 1 1 0 0 0 0 2Zm9 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2Z"/>',
  suppliers: '<path d="M3 21V9l9-6 9 6v12M9 21v-6h6v6"/>',
  purchase_orders: '<path d="M6 3h9l3 3v15H6z"/><path d="M9 8h6M9 12h6M9 16h4"/>',
  machinery: '<circle cx="7" cy="17" r="3"/><circle cx="17" cy="17" r="3"/><path d="M7 17V8h7l4 5v4M11 8V4H4v4"/>',
  machinery_maintenance: '<path d="M14.7 6.3a4 4 0 0 1-5.4 5.4L4 17l3 3 5.3-5.3a4 4 0 0 1 5.4-5.4L21 6l-3-3-3.3 3.3Z"/>',
  machinery_usage: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l4 2"/>',
  employees: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-7 8-7s8 3 8 7"/>',
  task_allocations: '<path d="M5 4h14v17H5z"/><path d="M9 11l2 2 4-4"/>',
  labor_assignments: '<path d="M9 21V9l3-6 3 6v12"/><path d="M4 21h16"/>',
  pest_disease_catalog: '<circle cx="12" cy="12" r="4"/><path d="M12 2v4M12 18v4M4 12h4M16 12h4M6 6l3 3M18 6l-3 3M6 18l3-3M18 18l-3-3"/>',
  scouting_records: '<circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/>',
  chemical_applications: '<path d="M9 3h6v4l3 10a3 3 0 0 1-3 4H9a3 3 0 0 1-3-4l3-10V3Z"/><path d="M8 14h8"/>',
  weather_logs: '<circle cx="9" cy="10" r="4"/><path d="M11 17h6a3 3 0 0 0 0-6 5 5 0 0 0-9.6-1.6"/>',
  weather: '<path d="M6 19a4 4 0 0 1 0-8 5.5 5.5 0 0 1 10.8-1.3A4.5 4.5 0 0 1 18 19H6Z"/><path d="M8 22v1M12 22v1M16 22v1"/>',
  harvests: '<path d="M12 21c5-1 8-5 8-10a8 8 0 0 0-8-2 8 8 0 0 0-8 2c0 5 3 9 8 10Z"/>',
  warehouses: '<path d="M3 21V10l9-6 9 6v11H3Z"/><path d="M9 21v-7h6v7"/>',
  produce_storage: '<path d="M4 4h16v16H4z"/><path d="M4 10h16M10 10v10"/>',
  customers: '<circle cx="9" cy="8" r="3"/><circle cx="17" cy="9" r="2.5"/><path d="M3 21c0-3.3 2.7-6 6-6s6 2.7 6 6M15 21c0-2.5 1.8-4.6 4.2-5"/>',
  sales_orders: '<path d="M4 4h13l3 5-9 12L4 9V4Z"/><path d="M4 9h16"/>',
  sales_order_items: '<path d="M4 6h16M4 12h16M4 18h10"/>',
  financial_transactions: '<circle cx="12" cy="12" r="9"/><path d="M12 7v10M15 9.5c0-1.4-1.3-2.5-3-2.5s-3 1-3 2.3c0 3 6 1.4 6 4.4 0 1.3-1.3 2.3-3 2.3s-3-1.1-3-2.5"/>',
  reports: '<path d="M5 3h11l3 3v15H5z"/><path d="M9 17v-5M13 17v-8M17 17v-3"/>',
  team: '<circle cx="8" cy="8" r="3"/><circle cx="16" cy="8" r="3"/><path d="M2 20c0-3 2.7-5 6-5s6 2 6 5M12 20c0-2.5 2.2-4.5 5-4.5s5 2 5 4.5"/>',
  audit_logs: '<path d="M6 3h9l3 3v15H6z"/><path d="M9 9h6M9 13h6M9 17h3"/>',
};

const OWNER_UP = ['admin', 'owner'];
const OPS = ['admin', 'owner', 'manager'];
const OPS_AGRO = ['admin', 'owner', 'manager', 'agronomist'];
const OPS_WORKER = ['admin', 'owner', 'manager', 'worker'];
const FIELD_TEAM = ['admin', 'owner', 'manager', 'agronomist', 'worker'];
const FIN = ['admin', 'owner', 'accountant'];
const SALES = ['admin', 'owner', 'manager', 'accountant'];

export const ENTITIES = {

  /* ---------- Land & Crops ---------- */
  farms: {
    label: 'Farms', singular: 'Farm', roles: OWNER_UP,
    mapPicker: { lat: 'latitude', lng: 'longitude', address: 'address', before: 'address' },
    description: 'The farm properties you manage — the top-level record everything else attaches to.',
    fields: [
      { name: 'farm_name', label: 'Farm name', type: 'text', required: true },
      { name: 'country_code', label: 'Country', type: 'select', options: countryOptions, blank: 'Choose the country…', required: true, cell: countryName,
        fills: { field: 'currency_code', with: currencyForCountry } },
      { name: 'currency_code', label: 'Currency', type: 'select', options: currencyOptions, blank: 'Choose the currency…', required: true, cell: v => v,
        help: "Money for this farm is entered in this currency. It is set from the country; change it if the farm works in another one, such as US dollars." },
      { name: 'total_area_hectares', label: 'Total area (ha)', type: 'number', required: true },
      { name: 'address', label: 'Address', type: 'textarea' },
      { name: 'latitude', label: 'Latitude (filled in by the map)', type: 'number', step: 'any' },
      { name: 'longitude', label: 'Longitude (filled in by the map)', type: 'number', step: 'any' },
    ],
  },
  fields: {
    label: 'Fields', singular: 'Field', roles: OPS_AGRO,
    description: 'Individual plots within a farm, with soil characteristics and current use.',
    fields: [
      { name: 'field_name', label: 'Field name', type: 'text', required: true },
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'area_hectares', label: 'Area (ha)', type: 'number', required: true },
      { name: 'soil_type', label: 'Soil type', type: 'text' },
      { name: 'ph_level', label: 'Soil pH', type: 'number', step: '0.1' },
      { name: 'organic_matter_pct', label: 'Organic matter (%)', type: 'number', step: '0.1' },
      { name: 'current_land_use', label: 'Current land use', type: 'text' },
    ],
  },
  crop_varieties: {
    label: 'Crop Varieties', singular: 'Variety', roles: OPS_AGRO,
    description: 'A reference catalogue of crops and varieties available for planting.',
    fields: [
      { name: 'crop_name', label: 'Crop', type: 'text', required: true, placeholder: 'e.g. Maize' },
      { name: 'variety_name', label: 'Variety', type: 'text', required: true, placeholder: 'e.g. SC719' },
      { name: 'typical_maturity_days', label: 'Maturity (days)', type: 'number' },
      { name: 'optimal_density_per_ha', label: 'Optimal density / ha', type: 'number' },
    ],
  },
  crop_plantings: {
    label: 'Plantings', singular: 'Planting', roles: OPS_AGRO,
    description: 'Each time a variety is planted into a field, tracked from planting to harvest.',
    fields: [
      { name: 'field_id', label: 'Field', type: 'select', ref: 'fields', refLabel: 'field_name', required: true },
      { name: 'variety_id', label: 'Variety', type: 'select', ref: 'crop_varieties', refLabel: 'variety_name', required: true },
      { name: 'planting_date', label: 'Planting date', type: 'date', required: true },
      { name: 'expected_harvest_date', label: 'Expected harvest', type: 'date' },
      { name: 'actual_harvest_date', label: 'Actual harvest', type: 'date' },
      { name: 'planted_area_hectares', label: 'Planted area (ha)', type: 'number', required: true },
      { name: 'planting_density_per_ha', label: 'Density / ha', type: 'number' },
      { name: 'spacing_row_cm', label: 'Row spacing (cm)', type: 'number' },
      { name: 'spacing_plant_cm', label: 'Plant spacing (cm)', type: 'number' },
      { name: 'status', label: 'Status', type: 'select', options: ['planned', 'active', 'harvested', 'failed'], default: 'active' },
    ],
  },
  crop_growth_logs: {
    label: 'Growth Logs', singular: 'Growth log', roles: FIELD_TEAM,
    description: 'Periodic field observations of crop stage, height and health.',
    fields: [
      { name: 'planting_id', label: 'Planting', type: 'select', ref: 'crop_plantings', refLabel: '#planting_id', required: true },
      { name: 'log_date', label: 'Date', type: 'date', required: true },
      { name: 'growth_stage', label: 'Growth stage', type: 'select', options: ['Germination', 'Vegetative', 'Flowering', 'Maturity'] },
      { name: 'avg_height_cm', label: 'Avg. height (cm)', type: 'number' },
      { name: 'health_status', label: 'Health status', type: 'text' },
      { name: 'remarks', label: 'Remarks', type: 'textarea' },
    ],
  },

  /* ---------- Water ---------- */
  water_sources: {
    label: 'Water Sources', singular: 'Water source', roles: OPS_AGRO,
    description: 'Rivers, boreholes, dams and other sources supplying the farm.',
    fields: [
      { name: 'source_name', label: 'Source name', type: 'text', required: true },
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'capacity_cubic_meters', label: 'Capacity (m\u00b3)', type: 'number' },
    ],
  },
  irrigation_systems: {
    label: 'Irrigation Systems', singular: 'System', roles: OPS_AGRO,
    description: 'Drip, sprinkler, pivot and other systems installed on fields.',
    fields: [
      { name: 'field_id', label: 'Field', type: 'select', ref: 'fields', refLabel: 'field_name', required: true },
      { name: 'source_id', label: 'Water source', type: 'select', ref: 'water_sources', refLabel: 'source_name', required: true },
      { name: 'system_type', label: 'Type', type: 'select', options: ['drip', 'sprinkler', 'pivot', 'flood', 'other'], required: true },
      { name: 'installation_date', label: 'Installed', type: 'date' },
      { name: 'flow_rate_liters_per_hr', label: 'Flow rate (L/hr)', type: 'number' },
      { name: 'status', label: 'Status', type: 'select', options: ['active', 'maintenance', 'inactive'], default: 'active' },
    ],
  },
  irrigation_schedules: {
    label: 'Irrigation Schedules', singular: 'Schedule', roles: FIELD_TEAM,
    description: 'Planned and completed watering sessions per system.',
    fields: [
      { name: 'system_id', label: 'System', type: 'select', ref: 'irrigation_systems', refLabel: '#system_id', required: true },
      { name: 'start_time', label: 'Start', type: 'datetime', required: true },
      { name: 'duration_minutes', label: 'Duration (min)', type: 'number', required: true },
      { name: 'water_volume_liters', label: 'Volume (L)', type: 'number' },
      { name: 'electricity_cost', label: 'Electricity cost', type: 'number', step: '0.01', money: true },
      { name: 'status', label: 'Status', type: 'select', options: ['scheduled', 'completed', 'cancelled'], default: 'scheduled' },
    ],
  },

  /* ---------- Livestock ---------- */
  livestock: {
    label: 'Livestock', singular: 'Animal', roles: OPS_WORKER,
    description: 'Individual animals or herd records with tag, breed and status.',
    fields: [
      { name: 'tag_number', label: 'Tag number', type: 'text', required: true },
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'species', label: 'Species', type: 'text', required: true, placeholder: 'e.g. Cattle, Poultry' },
      { name: 'breed', label: 'Breed', type: 'text' },
      { name: 'gender', label: 'Gender', type: 'select', options: ['male', 'female'], required: true },
      { name: 'birth_date', label: 'Birth date', type: 'date' },
      { name: 'status', label: 'Status', type: 'select', options: ['active', 'sold', 'deceased'], default: 'active' },
    ],
  },
  livestock_health_records: {
    label: 'Health Records', singular: 'Health record', roles: OPS_WORKER,
    description: 'Vaccinations, treatments and disease checks per animal.',
    fields: [
      { name: 'animal_id', label: 'Animal', type: 'select', ref: 'livestock', refLabel: 'tag_number', required: true },
      { name: 'record_type', label: 'Type', type: 'select', options: ['vaccination', 'treatment', 'disease_check'], required: true },
      { name: 'diagnosis', label: 'Diagnosis', type: 'text' },
      { name: 'treatment_details', label: 'Treatment details', type: 'textarea' },
      { name: 'dosage', label: 'Dosage', type: 'number' },
      { name: 'cost', label: 'Cost', type: 'number', step: '0.01', money: true },
      { name: 'administered_date', label: 'Administered', type: 'date', required: true },
      { name: 'next_due_date', label: 'Next due', type: 'date' },
    ],
  },
  livestock_production_logs: {
    label: 'Production Logs', singular: 'Production log', roles: OPS_WORKER,
    description: 'Milk, egg, wool, meat and manure yields, by animal or by farm.',
    fields: [
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'animal_id', label: 'Animal (optional)', type: 'select', ref: 'livestock', refLabel: 'tag_number' },
      { name: 'production_type', label: 'Type', type: 'select', options: ['milk', 'eggs', 'wool', 'meat', 'manure'], required: true },
      { name: 'quantity', label: 'Quantity', type: 'number', required: true },
      { name: 'unit', label: 'Unit', type: 'text', placeholder: 'L, kg, count', required: true },
      { name: 'logged_date', label: 'Date', type: 'date', required: true },
    ],
  },
  livestock_feed_logs: {
    label: 'Feed Logs', singular: 'Feed log', roles: OPS_WORKER,
    description: 'Feed dispensed from inventory, by species and date.',
    fields: [
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'species', label: 'Species', type: 'text' },
      { name: 'batch_id', label: 'Feed batch', type: 'select', ref: 'inventory_batches', refLabel: '#batch_id', required: true },
      { name: 'quantity_used', label: 'Quantity used', type: 'number', required: true },
      { name: 'feeding_date', label: 'Date', type: 'date', required: true },
    ],
  },

  /* ---------- Inventory & Buying ---------- */
  inventory_items: {
    label: 'Inventory Items', singular: 'Item', roles: OPS,
    description: 'Seeds, fertiliser, chemicals, feed and other stocked supplies.',
    fields: [
      { name: 'item_name', label: 'Item name', type: 'text', required: true },
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'category', label: 'Category', type: 'select', options: ['seed', 'fertilizer', 'chemical', 'feed', 'medicine', 'packaging', 'fuel', 'tool', 'other'], required: true },
      { name: 'unit_of_measure', label: 'Unit', type: 'text', placeholder: 'kg, L, bags', required: true },
      { name: 'current_stock', label: 'Current stock', type: 'number', default: 0 },
      { name: 'reorder_threshold', label: 'Reorder threshold', type: 'number', default: 0 },
    ],
  },
  inventory_batches: {
    label: 'Inventory Batches', singular: 'Batch', roles: OPS,
    description: 'Received stock batches with cost, quantity and expiry.',
    fields: [
      { name: 'item_id', label: 'Item', type: 'select', ref: 'inventory_items', refLabel: 'item_name', required: true },
      { name: 'supplier_id', label: 'Supplier', type: 'select', ref: 'suppliers', refLabel: 'supplier_name' },
      { name: 'batch_number', label: 'Batch number', type: 'text' },
      { name: 'quantity_received', label: 'Quantity received', type: 'number', required: true },
      { name: 'quantity_remaining', label: 'Quantity remaining', type: 'number', required: true },
      { name: 'cost_per_unit', label: 'Cost per unit', type: 'number', step: '0.01', required: true, money: true },
      { name: 'purchase_date', label: 'Purchase date', type: 'date', required: true },
      { name: 'expiry_date', label: 'Expiry date', type: 'date' },
    ],
  },
  inventory_transactions: {
    label: 'Stock Transactions', singular: 'Transaction', roles: OPS,
    description: 'Every stock movement — received, used, adjusted or returned.',
    fields: [
      { name: 'batch_id', label: 'Batch', type: 'select', ref: 'inventory_batches', refLabel: '#batch_id', required: true },
      { name: 'transaction_type', label: 'Type', type: 'select', options: ['stock_in', 'stock_out', 'adjustment', 'return'], required: true },
      { name: 'quantity', label: 'Quantity', type: 'number', required: true },
      { name: 'reference_type', label: 'Reference type', type: 'text' },
      { name: 'notes', label: 'Notes', type: 'textarea' },
    ],
  },
  suppliers: {
    label: 'Suppliers', singular: 'Supplier', roles: OPS,
    description: 'Vendors that supply inputs, feed, chemicals and equipment.',
    fields: [
      { name: 'supplier_name', label: 'Supplier name', type: 'text', required: true },
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'contact_person', label: 'Contact person', type: 'text' },
      { name: 'phone', label: 'Phone', type: 'text' },
      { name: 'email', label: 'Email', type: 'text' },
      { name: 'address', label: 'Address', type: 'textarea' },
      { name: 'rating', label: 'Rating (1-5)', type: 'number', step: '0.1' },
    ],
  },
  purchase_orders: {
    label: 'Purchase Orders', singular: 'Purchase order', roles: OPS,
    description: 'Orders placed with suppliers, from draft through fulfilment.',
    fields: [
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'supplier_id', label: 'Supplier', type: 'select', ref: 'suppliers', refLabel: 'supplier_name', required: true },
      { name: 'order_date', label: 'Order date', type: 'date', required: true },
      { name: 'total_amount', label: 'Total amount', type: 'number', step: '0.01', default: 0, money: true },
      { name: 'status', label: 'Status', type: 'select', options: ['draft', 'requested', 'approved', 'fulfilled', 'cancelled'], default: 'draft' },
    ],
  },

  /* ---------- Equipment ---------- */
  machinery: {
    label: 'Machinery', singular: 'Machine', roles: OPS_WORKER,
    description: 'Tractors, harvesters, pumps and other equipment on the farm.',
    fields: [
      { name: 'name', label: 'Name', type: 'text', required: true },
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'type', label: 'Type', type: 'text', placeholder: 'Tractor, Harvester, Pump', required: true },
      { name: 'serial_number', label: 'Serial number', type: 'text' },
      { name: 'purchase_price', label: 'Purchase price', type: 'number', step: '0.01', money: true },
      { name: 'purchase_date', label: 'Purchase date', type: 'date' },
      { name: 'current_operating_hours', label: 'Operating hours', type: 'number', default: 0 },
      { name: 'status', label: 'Status', type: 'select', options: ['operational', 'under_maintenance', 'out_of_service'], default: 'operational' },
    ],
  },
  machinery_maintenance: {
    label: 'Maintenance', singular: 'Maintenance record', roles: OPS_WORKER,
    description: 'Service history — routine care, repairs and inspections.',
    fields: [
      { name: 'machinery_id', label: 'Machine', type: 'select', ref: 'machinery', refLabel: 'name', required: true },
      { name: 'maintenance_type', label: 'Type', type: 'select', options: ['routine', 'repair', 'inspection'], required: true },
      { name: 'service_date', label: 'Service date', type: 'date', required: true },
      { name: 'operating_hours_at_service', label: 'Hours at service', type: 'number' },
      { name: 'description', label: 'Description', type: 'textarea' },
      { name: 'cost', label: 'Cost', type: 'number', step: '0.01', default: 0, money: true },
      { name: 'next_service_due_hours', label: 'Next service due (hrs)', type: 'number' },
    ],
  },
  machinery_usage: {
    label: 'Usage Logs', singular: 'Usage log', roles: OPS_WORKER,
    description: 'Hours worked and fuel used per machine, field and operator.',
    fields: [
      { name: 'machinery_id', label: 'Machine', type: 'select', ref: 'machinery', refLabel: 'name', required: true },
      { name: 'field_id', label: 'Field', type: 'select', ref: 'fields', refLabel: 'field_name' },
      { name: 'date_used', label: 'Date', type: 'date', required: true },
      { name: 'hours_worked', label: 'Hours worked', type: 'number', required: true },
      { name: 'fuel_consumed_liters', label: 'Fuel used (L)', type: 'number' },
    ],
  },

  /* ---------- People & Tasks ---------- */
  employees: {
    label: 'Employees', singular: 'Employee', roles: OPS,
    description: 'Farm staff records, employment type and pay rate.',
    fields: [
      { name: 'first_name', label: 'First name', type: 'text', required: true },
      { name: 'last_name', label: 'Last name', type: 'text', required: true },
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'national_id', label: 'National ID', type: 'text' },
      { name: 'designation', label: 'Designation', type: 'text' },
      { name: 'employment_type', label: 'Employment type', type: 'select', options: ['permanent', 'casual', 'contract'], required: true },
      { name: 'daily_rate', label: 'Daily rate', type: 'number', step: '0.01', default: 0, money: true },
      { name: 'hire_date', label: 'Hire date', type: 'date' },
    ],
  },
  task_allocations: {
    label: 'Tasks', singular: 'Task', roles: OPS,
    description: 'Work items assigned across fields — planting, weeding, spraying and more.',
    fields: [
      { name: 'title', label: 'Title', type: 'text', required: true },
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'field_id', label: 'Field', type: 'select', ref: 'fields', refLabel: 'field_name' },
      { name: 'task_type', label: 'Task type', type: 'text', placeholder: 'Planting, Weeding, Spraying' },
      { name: 'description', label: 'Description', type: 'textarea' },
      { name: 'start_date', label: 'Start date', type: 'date' },
      { name: 'due_date', label: 'Due date', type: 'date' },
      { name: 'status', label: 'Status', type: 'select', options: ['pending', 'in_progress', 'completed', 'cancelled'], default: 'pending' },
    ],
  },
  labor_assignments: {
    label: 'Labour Assignments', singular: 'Assignment', roles: OPS,
    description: 'Hours and cost logged by employees against a task.',
    fields: [
      { name: 'task_id', label: 'Task', type: 'select', ref: 'task_allocations', refLabel: 'title', required: true },
      { name: 'employee_id', label: 'Employee', type: 'select', ref: 'employees', refLabel: 'first_name', required: true },
      { name: 'hours_worked', label: 'Hours worked', type: 'number', default: 0 },
      { name: 'date_performed', label: 'Date', type: 'date', required: true },
      { name: 'labor_cost', label: 'Labour cost', type: 'number', step: '0.01', default: 0, money: true },
    ],
  },

  /* ---------- Crop Protection ---------- */
  pest_disease_catalog: {
    label: 'Pest & Disease Catalogue', singular: 'Catalogue entry', roles: OPS_AGRO,
    description: 'Reference list of pests, diseases and weeds with control guidance.',
    fields: [
      { name: 'name', label: 'Name', type: 'text', required: true },
      { name: 'type', label: 'Type', type: 'select', options: ['pest', 'disease', 'weed'], required: true },
      { name: 'symptoms', label: 'Symptoms', type: 'textarea' },
      { name: 'recommended_control', label: 'Recommended control', type: 'textarea' },
    ],
  },
  scouting_records: {
    label: 'Scouting Records', singular: 'Scouting record', roles: FIELD_TEAM,
    description: 'Field inspections logging pest, disease or weed pressure.',
    fields: [
      { name: 'field_id', label: 'Field', type: 'select', ref: 'fields', refLabel: 'field_name', required: true },
      { name: 'scout_date', label: 'Date', type: 'date', required: true },
      { name: 'catalog_id', label: 'Pest/disease', type: 'select', ref: 'pest_disease_catalog', refLabel: 'name' },
      { name: 'severity_level', label: 'Severity', type: 'select', options: ['low', 'moderate', 'high', 'severe'], required: true },
      { name: 'affected_area_pct', label: 'Affected area (%)', type: 'number' },
      { name: 'notes', label: 'Notes', type: 'textarea' },
    ],
  },
  chemical_applications: {
    label: 'Chemical Applications', singular: 'Application', roles: OPS_AGRO,
    description: 'Chemical treatments applied to plantings and their effectiveness.',
    fields: [
      { name: 'planting_id', label: 'Planting', type: 'select', ref: 'crop_plantings', refLabel: '#planting_id', required: true },
      { name: 'batch_id', label: 'Chemical batch', type: 'select', ref: 'inventory_batches', refLabel: '#batch_id', required: true },
      { name: 'scouting_id', label: 'Related scouting', type: 'select', ref: 'scouting_records', refLabel: '#scouting_id' },
      { name: 'application_date', label: 'Date', type: 'date', required: true },
      { name: 'dosage_per_ha', label: 'Dosage / ha', type: 'number', required: true },
      { name: 'total_chemical_used', label: 'Total used', type: 'number', required: true },
      { name: 'effectiveness', label: 'Effectiveness', type: 'select', options: ['pending', 'effective', 'partially_effective', 'ineffective'], default: 'pending' },
    ],
  },

  /* ---------- Environment ---------- */
  weather_logs: {
    label: 'Weather Logs', singular: 'Weather log', roles: OPS_AGRO,
    description: 'Recorded conditions and forecasts for each farm.',
    fields: [
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'log_timestamp', label: 'Recorded at', type: 'datetime', required: true },
      { name: 'temp_celsius', label: 'Temp (\u00b0C)', type: 'number', step: '0.1' },
      { name: 'humidity_pct', label: 'Humidity (%)', type: 'number', step: '0.1' },
      { name: 'rainfall_mm', label: 'Rainfall (mm)', type: 'number', step: '0.1' },
      { name: 'wind_speed_kmh', label: 'Wind speed (km/h)', type: 'number', step: '0.1' },
      { name: 'forecast_summary', label: 'Forecast summary', type: 'text' },
    ],
  },

  /* ---------- Harvest & Storage ---------- */
  harvests: {
    label: 'Harvests', singular: 'Harvest', roles: OPS_AGRO,
    description: 'Recorded yield from each planting, including grade and losses.',
    fields: [
      { name: 'planting_id', label: 'Planting', type: 'select', ref: 'crop_plantings', refLabel: '#planting_id', required: true },
      { name: 'harvest_date', label: 'Harvest date', type: 'date', required: true },
      { name: 'quantity_harvested', label: 'Quantity harvested', type: 'number', required: true },
      { name: 'unit_of_measure', label: 'Unit', type: 'text', placeholder: 'kg, tons', required: true },
      { name: 'grade', label: 'Grade', type: 'text' },
      { name: 'loss_quantity', label: 'Loss quantity', type: 'number', default: 0 },
      { name: 'loss_reason', label: 'Loss reason', type: 'textarea' },
    ],
  },
  warehouses: {
    label: 'Warehouses', singular: 'Warehouse', roles: OPS_AGRO,
    description: 'Storage facilities — ambient, cold storage, silos and sheds.',
    fields: [
      { name: 'name', label: 'Name', type: 'text', required: true },
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'type', label: 'Type', type: 'select', options: ['ambient', 'cold_storage', 'silo', 'shed'], required: true },
      { name: 'capacity_metric_tons', label: 'Capacity (t)', type: 'number' },
    ],
  },
  produce_storage: {
    label: 'Produce Storage', singular: 'Storage entry', roles: OPS_AGRO,
    description: 'Harvested produce held in storage, tracked through to dispatch.',
    fields: [
      { name: 'harvest_id', label: 'Harvest', type: 'select', ref: 'harvests', refLabel: '#harvest_id', required: true },
      { name: 'warehouse_id', label: 'Warehouse', type: 'select', ref: 'warehouses', refLabel: 'name', required: true },
      { name: 'quantity_stored', label: 'Quantity stored', type: 'number', required: true },
      { name: 'entry_date', label: 'Entry date', type: 'date', required: true },
      { name: 'spoilage_quantity', label: 'Spoilage quantity', type: 'number', default: 0 },
      { name: 'status', label: 'Status', type: 'select', options: ['stored', 'dispatched', 'disposed'], default: 'stored' },
    ],
  },

  /* ---------- Sales ---------- */
  customers: {
    label: 'Customers', singular: 'Customer', roles: SALES,
    description: 'Buyers of farm produce and livestock products.',
    fields: [
      { name: 'customer_name', label: 'Customer name', type: 'text', required: true },
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'company_name', label: 'Company name', type: 'text' },
      { name: 'contact_phone', label: 'Phone', type: 'text' },
      { name: 'email', label: 'Email', type: 'text' },
      { name: 'address', label: 'Address', type: 'textarea' },
    ],
  },
  sales_orders: {
    label: 'Sales Orders', singular: 'Sales order', roles: SALES,
    description: 'Orders placed by customers, from pending through delivery.',
    fields: [
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'customer_id', label: 'Customer', type: 'select', ref: 'customers', refLabel: 'customer_name', required: true },
      { name: 'order_date', label: 'Order date', type: 'date', required: true },
      { name: 'total_amount', label: 'Total amount', type: 'number', step: '0.01', required: true, money: true },
      { name: 'payment_status', label: 'Payment status', type: 'select', options: ['pending', 'partially_paid', 'paid'], default: 'pending' },
      { name: 'order_status', label: 'Order status', type: 'select', options: ['pending', 'confirmed', 'dispatched', 'delivered', 'cancelled'], default: 'pending' },
    ],
  },
  sales_order_items: {
    label: 'Order Line Items', singular: 'Line item', roles: SALES,
    description: 'Individual produce or product lines within a sales order.',
    fields: [
      { name: 'order_id', label: 'Sales order', type: 'select', ref: 'sales_orders', refLabel: '#order_id', required: true },
      { name: 'description', label: 'Description', type: 'text', required: true },
      { name: 'quantity', label: 'Quantity', type: 'number', required: true },
      { name: 'unit_price', label: 'Unit price', type: 'number', step: '0.01', required: true, money: true },
      { name: 'subtotal', label: 'Subtotal', type: 'number', step: '0.01', required: true, money: true },
    ],
  },

  /* ---------- Finance ---------- */
  financial_transactions: {
    label: 'Transactions', singular: 'Transaction', roles: FIN,
    description: 'Income and expenses recorded against each farm.',
    fields: [
      { name: 'farm_id', label: 'Farm', type: 'select', ref: 'farms', refLabel: 'farm_name', required: true },
      { name: 'transaction_type', label: 'Type', type: 'select', options: ['income', 'expense'], required: true },
      { name: 'category', label: 'Category', type: 'text', placeholder: 'Input purchase, Labour, Sales, Fuel', required: true },
      { name: 'amount', label: 'Amount', type: 'number', step: '0.01', required: true, money: true },
      { name: 'transaction_date', label: 'Date', type: 'date', required: true },
      { name: 'description', label: 'Description', type: 'textarea' },
    ],
  },
  reports: {
    label: 'Reports & Analytics', singular: 'Report', roles: FIN.concat('manager'),
    description: 'Rolled-up figures across the farm — populates automatically as records are added.',
    readonly: true,
  },

  /* ---------- Overview / Admin (special pages) ---------- */
  dashboard: { label: 'Dashboard', roles: ALL, special: true },
  ai_overview: { label: 'AI Farm Overview Analysis', roles: ALL, special: 'ai_overview', description: 'Farm-wide analysis with suggestions, growth and profit/loss charts.' },
  notifications: { label: 'Notifications', roles: ALL, special: true },
  weather: { label: 'Weather & Maps', roles: ALL, special: 'weather', description: 'Live forecasts for each farm, generated automatically from its saved coordinates.' },
  team: {
    label: 'Team & Roles', singular: 'Team member', roles: OWNER_UP,
    description: 'People with access to this system and the role each one holds.',
    special: 'team',
  },
  audit_logs: {
    label: 'Audit Log', singular: 'Entry', roles: OWNER_UP,
    description: 'Who did what, and when — logins, password changes, and every create, update and delete.',
    special: 'audit',
  },
};

export function fieldsFor(entityKey){
  return ENTITIES[entityKey]?.fields || [];
}

export function groupForEntity(entityKey){
  const g = NAV_GROUPS.find(g => g.items.includes(entityKey));
  return g ? g.label : 'Overview';
}


/* ==========================================================================
   Grouped record lists. For these entities the list page shows ONE row per
   parent (e.g. one row per animal) with an arrow that expands to every
   individual record logged against it. Value = the field that points at the
   parent record.
   ========================================================================== */
export const GROUP_BY = {
  crop_plantings: 'field_id',
  crop_growth_logs: 'planting_id',
  chemical_applications: 'planting_id',
  harvests: 'planting_id',
  scouting_records: 'field_id',
  irrigation_systems: 'field_id',
  irrigation_schedules: 'system_id',
  livestock_health_records: 'animal_id',
  livestock_production_logs: 'animal_id',
  livestock_feed_logs: 'batch_id',
  machinery_maintenance: 'machinery_id',
  machinery_usage: 'machinery_id',
  inventory_batches: 'item_id',
  inventory_transactions: 'batch_id',
  labor_assignments: 'employee_id',
  produce_storage: 'warehouse_id',
  sales_order_items: 'order_id',
  sales_orders: 'customer_id',
  purchase_orders: 'supplier_id',
  weather_logs: 'farm_id',
};

/** Heading used for records whose parent link is empty (e.g. herd-level production). */
export const GROUP_NULL_LABEL = {
  livestock_production_logs: 'Herd-level (not tied to one animal)',
};
