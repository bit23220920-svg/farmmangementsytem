/* ==========================================================================
   AI Farm Overview Analysis — agronomy, livestock, equipment and pest
   knowledge base. The analysis engine (ai-overview.js) matches the names
   recorded in the system (crop name, species, machine type, pest name)
   against the keywords below and pulls the matching guidance.

   Chemical guidance names commonly registered active ingredients only as
   a starting point. Always confirm local registration, the label rate,
   PPE and the pre-harvest / withdrawal interval before applying anything.
   ========================================================================== */

export const STAGES = ['Germination', 'Vegetative', 'Flowering', 'Maturity'];

/* ---------------------------------------------------------------------- */
/* Crops                                                                  */
/* ---------------------------------------------------------------------- */
export const CROP_KB = [
  {
    keys: ['maize', 'corn'], name: 'Maize', ph: [5.5, 7.0],
    stages: {
      Germination: ['Check emergence 7–10 days after planting and gap-fill quickly if the stand is below 90%.', 'Keep the field weed-free for the first 6 weeks — early weeds cost the most yield.'],
      Vegetative: ['Top-dress nitrogen (e.g. AN or urea) at the 4–6 leaf stage and again at 8–10 leaves, ideally just before rain.', 'Scout whorls twice a week for fall armyworm and stalk borer.'],
      Flowering: ['Tasselling to silking is the most water-sensitive stage — avoid any moisture stress now.', 'Look for grey leaf spot and rust on the ear leaf and above.'],
      Maturity: ['Harvest once the black layer forms and grain moisture falls to about 12.5–13% for safe storage.', 'Treat grain with a registered protectant or use hermetic bags against weevils and the larger grain borer.'],
    },
    care: ['Rotate with a legume (soybean, groundnut, beans) to break pest cycles and add nitrogen.', 'Basal fertiliser (compound D or similar) at planting; lime if soil pH is below 5.5.'],
  },
  {
    keys: ['tomato'], name: 'Tomato', ph: [6.0, 6.8],
    stages: {
      Germination: ['Harden seedlings for a week before transplanting; transplant in the late afternoon.', 'Protect young plants from cutworm with collars or a clean seedbed.'],
      Vegetative: ['Stake or trellis early and prune suckers on indeterminate varieties.', 'Use pheromone traps for Tuta absoluta from transplanting.'],
      Flowering: ['Keep watering even — irregular watering causes blossom-end rot and fruit cracking.', 'Apply calcium and potassium; reduce nitrogen once fruit sets.'],
      Maturity: ['Pick at breaker/turning stage for distant markets, ripe for local sale.', 'Store cool and shaded; never refrigerate green fruit.'],
    },
    care: ['Avoid planting after potato, pepper or eggplant (same diseases) — rotate for 3 years.', 'Water at the base, not over the leaves, to reduce blight.'],
  },
  {
    keys: ['wheat', 'barley'], name: 'Wheat / barley', ph: [6.0, 7.5],
    stages: {
      Germination: ['Aim for an even stand; check emergence and soil crusting after the first irrigation.'],
      Vegetative: ['Apply top-dress nitrogen at tillering; irrigate at crown-root initiation.', 'Scout for aphids and rust on the upper leaves.'],
      Flowering: ['Do not let the crop stress at heading and flowering; protect the flag leaf from rust.'],
      Maturity: ['Harvest at about 12–13% moisture and keep birds off the ripening crop.'],
    },
    care: ['Use certified, rust-resistant seed.', 'Plan irrigation — winter wheat depends on it.'],
  },
  {
    keys: ['soy', 'soya'], name: 'Soybean', ph: [6.0, 7.0],
    stages: {
      Germination: ['Inoculate seed with Bradyrhizobium just before planting, out of direct sun.'],
      Vegetative: ['Check roots for pink nodules at 4–6 weeks — pink means nitrogen fixation is working.', 'Keep weed-free until canopy closure.'],
      Flowering: ['Scout for soybean rust, stink bugs and red spider mite during flowering and pod fill.'],
      Maturity: ['Harvest promptly when 95% of pods are brown to avoid shattering losses.'],
    },
    care: ['Great rotation crop before maize.', 'Phosphorus and potassium matter more than nitrogen here.'],
  },
  {
    keys: ['potato'], name: 'Potato', ph: [5.0, 6.5],
    stages: {
      Germination: ['Plant certified, sprouted seed; cover 8–10 cm deep.'],
      Vegetative: ['Ridge (hill) soil around stems twice to protect tubers from light and tuber moth.', 'Start a preventive blight programme in wet or humid weather.'],
      Flowering: ['Tuber bulking — keep soil moisture even; irregular watering gives cracked, hollow tubers.'],
      Maturity: ['Cut the haulms 2 weeks before harvest so skins set; cure in shade before storing.'],
    },
    care: ['Rotate away from tomato and other potato crops for at least 3 years.'],
  },
  {
    keys: ['tobacco'], name: 'Tobacco', ph: [5.5, 6.5],
    stages: {
      Germination: ['Use float trays or clean seedbeds; manage damping-off with good ventilation.'],
      Vegetative: ['Transplant healthy, hardened seedlings; scout for aphids and cutworms.'],
      Flowering: ['Top and control suckers on time to push leaf weight and quality.'],
      Maturity: ['Reap leaves as they ripen from the bottom up; cure carefully and keep barn records.'],
    },
    care: ['Nematodes are a major risk — rotate with grass crops like Katambora Rhodes grass.'],
  },
  {
    keys: ['bean', 'cowpea'], name: 'Beans', ph: [6.0, 7.0],
    stages: {
      Germination: ['Use treated seed against bean fly; plant into warm, moist soil.'],
      Vegetative: ['Weed early and avoid working in the crop when leaves are wet (spreads disease).'],
      Flowering: ['Scout for rust, angular leaf spot and aphids.'],
      Maturity: ['Harvest when pods are dry; dry the grain to about 12% and store against bruchids.'],
    },
    care: ['Beans fix some nitrogen — keep phosphorus up for good nodulation.'],
  },
  {
    keys: ['cabbage', 'brassica', 'rape', 'kale', 'covo', 'broccoli', 'cauliflower'], name: 'Brassicas', ph: [6.0, 7.5],
    stages: {
      Germination: ['Raise seedlings under net to keep off diamondback moth and aphids.'],
      Vegetative: ['Top-dress nitrogen every 2–3 weeks; scout twice weekly for diamondback moth.'],
      Flowering: ['For leaf crops, remove flower stalks to extend harvest.'],
      Maturity: ['Harvest heads when firm; harvest leaves regularly from the bottom up.'],
    },
    care: ['Rotate away from other brassicas to manage black rot and clubroot.'],
  },
  {
    keys: ['groundnut', 'peanut'], name: 'Groundnuts', ph: [5.5, 7.0],
    stages: {
      Germination: ['Plant shelled, treated seed at the start of the rains.'],
      Vegetative: ['Apply gypsum at flowering for good pod fill; control aphids that spread rosette virus.'],
      Flowering: ['Do not disturb the soil once pegs start entering it.'],
      Maturity: ['Lift when the inside of most shells has darkened; dry quickly to prevent aflatoxin.'],
    },
    care: ['Never store damp nuts — aflatoxin is a serious health risk.'],
  },
  {
    keys: ['sorghum', 'millet', 'rapoko', 'finger millet'], name: 'Sorghum / millet', ph: [5.5, 7.5],
    stages: {
      Germination: ['Shallow planting (2–3 cm); small seed needs a fine seedbed.'],
      Vegetative: ['Thin to the right spacing; scout for stalk borer.'],
      Flowering: ['Watch for sorghum midge and aphids at heading.'],
      Maturity: ['Protect ripening heads from quelea and other birds; harvest promptly.'],
    },
    care: ['A strong drought-tolerant option for low-rainfall fields.'],
  },
  {
    keys: ['cotton'], name: 'Cotton', ph: [5.8, 8.0],
    stages: {
      Germination: ['Plant once soils are warm; check stand and gap-fill early.'],
      Vegetative: ['Scout for aphids, jassids and red spider mite weekly.'],
      Flowering: ['Bollworm pressure peaks at squaring and flowering — scout for eggs and young larvae.'],
      Maturity: ['Pick clean, dry lint; keep it free of contamination (polypropylene, hair).'],
    },
    care: ['Destroy stalks after harvest (closed season) to break the pest cycle.'],
  },
  {
    keys: ['onion', 'garlic'], name: 'Onion / garlic', ph: [6.0, 7.0],
    stages: {
      Germination: ['Keep the nursery moist; transplant at pencil thickness.'],
      Vegetative: ['Shallow roots — irrigate little and often and keep weeds out.', 'Scout for thrips in the leaf necks.'],
      Flowering: ['Remove any flower stalks (bolters) in bulb crops.'],
      Maturity: ['Stop irrigating when tops start to fall; cure bulbs in shade for 2–3 weeks.'],
    },
    care: ['Purple blotch and downy mildew follow humid weather — keep spacing for airflow.'],
  },
];

export const CROP_GENERIC = {
  name: 'General crop care', ph: [5.8, 7.0],
  stages: {
    Germination: ['Check the stand and gap-fill early; keep the seedbed moist but not waterlogged.'],
    Vegetative: ['Keep weeds down, top-dress nutrients on time and scout weekly.'],
    Flowering: ['Avoid water stress and protect against pests that attack flowers and fruit.'],
    Maturity: ['Harvest on time, dry properly and store clean to cut post-harvest loss.'],
  },
  care: ['Rotate crop families every season and keep growth logs up to date so the analysis stays accurate.'],
};

/* ---------------------------------------------------------------------- */
/* Livestock                                                              */
/* ---------------------------------------------------------------------- */
export const LIVESTOCK_KB = [
  {
    keys: ['cattle', 'cow', 'bull', 'heifer', 'steer', 'calf', 'ox', 'dairy', 'beef'], name: 'Cattle',
    feeding: ['Provide 40–60 L of clean water per animal per day (dairy cows need up to 100 L).', 'Supplement with protein licks in the dry season when grazing quality falls.'],
    housing: ['Clean, well-drained pens; keep the kraal dry to prevent foot rot.'],
    health: ['Dip or spray for ticks weekly in the rainy season (tick-borne diseases such as January disease/theileriosis spread fast then).', 'Vaccinate against anthrax, blackleg and lumpy skin disease on your vet’s schedule.', 'Deworm at the start and end of the rains.'],
    signs: ['Off feed, isolated from the herd, swollen lymph nodes, laboured breathing or a high temperature — call the vet.'],
  },
  {
    keys: ['goat'], name: 'Goats',
    feeding: ['Goats prefer browse (shrubs) to grass; offer clean water daily and a mineral lick.'],
    housing: ['Raised, slatted housing keeps them dry and reduces worms and pneumonia.'],
    health: ['Check eyelids monthly (FAMACHA) for anaemia from wireworm; deworm only animals that need it.', 'Trim hooves every 3–4 months; vaccinate against pulpy kidney and pasteurella as advised.'],
    signs: ['Bottle jaw, pale eyelids, coughing or diarrhoea need prompt attention.'],
  },
  {
    keys: ['sheep', 'lamb', 'ewe', 'ram'], name: 'Sheep',
    feeding: ['Good grazing plus supplementary feed for ewes in late pregnancy.'],
    housing: ['Shelter from cold rain, especially for lambs and newly shorn sheep.'],
    health: ['Monitor worm burdens and deworm strategically; vaccinate against pulpy kidney and blue tongue as advised.', 'Check for foot rot and fly strike in wet weather.'],
    signs: ['Lameness, wool loss, weakness or sudden deaths should be investigated quickly.'],
  },
  {
    keys: ['pig', 'swine', 'sow', 'boar', 'piglet', 'hog'], name: 'Pigs',
    feeding: ['Feed a balanced ration for each stage (creep, grower, finisher); always give clean water.'],
    housing: ['Keep pens dry, shaded and ventilated — pigs suffer badly in heat.'],
    health: ['Strict biosecurity: control visitors, no swill feeding (African swine fever risk).', 'Give piglets iron within 3 days of birth; deworm and control mange regularly.'],
    signs: ['Fever, red/blue skin blotches, off feed or sudden death — isolate and report to the vet immediately.'],
  },
  {
    keys: ['poultry', 'chicken', 'broiler', 'layer', 'hen', 'cock', 'duck', 'turkey', 'guinea', 'bird', 'quail'], name: 'Poultry',
    feeding: ['Use the right feed for the stage (starter, grower, finisher, layer mash) and keep drinkers clean every day.'],
    housing: ['Brood chicks at 32–35 °C the first week and lower by about 3 °C each week; keep litter dry.', 'Give enough space and ventilation — ammonia smell means it’s too crowded or wet.'],
    health: ['Vaccinate against Newcastle disease and Gumboro (and Marek’s for layers) on schedule.', 'Use footbaths and restrict visitors; clean and rest houses between batches.'],
    signs: ['Sudden drop in feed or water intake, egg drop, twisted necks or many deaths — call the vet and stop movement.'],
  },
  {
    keys: ['rabbit'], name: 'Rabbits',
    feeding: ['Mostly hay/grass with pellets and clean water; avoid sudden feed changes.'],
    housing: ['Cool, shaded hutches with wire floors cleaned daily.'],
    health: ['Check for ear mites, sore hocks and diarrhoea weekly.'],
    signs: ['Not eating for more than 12 hours is an emergency in rabbits.'],
  },
  {
    keys: ['fish', 'tilapia', 'catfish'], name: 'Fish',
    feeding: ['Feed 2–3 times a day at 3–5% of body weight; reduce feeding in cold weather.'],
    housing: ['Monitor water quality (oxygen, ammonia) and keep stocking density right.'],
    health: ['Remove dead fish immediately and check for gasping at the surface at dawn (low oxygen).'],
    signs: ['Fish gasping, red sores or fin rot — change water and check oxygen levels.'],
  },
];

export const LIVESTOCK_GENERIC = {
  name: 'General animal care',
  feeding: ['Clean water at all times and a ration matched to age and production.'],
  housing: ['Dry, ventilated shelter with enough space.'],
  health: ['Keep a vaccination and deworming calendar with your vet and record every treatment here.'],
  signs: ['Isolate any sick animal and record the symptoms straight away.'],
};

/* ---------------------------------------------------------------------- */
/* Equipment                                                              */
/* ---------------------------------------------------------------------- */
export const EQUIPMENT_KB = [
  {
    keys: ['tractor'], name: 'Tractors', interval: 250,
    daily: ['Check engine oil, coolant, hydraulic oil and tyre pressure before starting.', 'Grease all nipples on the PTO shaft, linkages and front axle.', 'Clean the air filter in dusty conditions.'],
    periodic: ['Engine oil and filter about every 250 hours; fuel and hydraulic filters every 500 hours.', 'Check the battery, belts, brakes and lights monthly.'],
    storage: ['Park under cover with implements lowered; keep the fuel tank full to stop condensation.'],
  },
  {
    keys: ['pump', 'borehole', 'submersible'], name: 'Pumps', interval: 500,
    daily: ['Listen for unusual noise or vibration and check for leaks at seals and joints.'],
    periodic: ['Clean the intake screen and foot valve; check electrical connections and pressure readings monthly.', 'Service bearings and seals every 500 hours (or as per the manual).'],
    storage: ['Drain the pump before frost; protect electrical panels from water and rodents.'],
  },
  {
    keys: ['harvester', 'combine', 'sheller', 'thresher'], name: 'Harvesters & shellers', interval: 200,
    daily: ['Clear chaff and dust from the engine bay to prevent fires; check belts and chains.'],
    periodic: ['Full service before each season; replace worn knives, sieves and bearings.'],
    storage: ['Clean out all grain and residue after the season (rodents and rust).'],
  },
  {
    keys: ['sprayer', 'boom', 'knapsack', 'mister'], name: 'Sprayers', interval: 100,
    daily: ['Triple-rinse the tank and lines after every use; never leave chemical in the tank.', 'Check nozzles for blockages and wear.'],
    periodic: ['Calibrate the sprayer at the start of each season and whenever nozzles change.', 'Replace worn nozzles — wear of more than 10% wastes chemical.'],
    storage: ['Store clean and dry, away from food and feed.'],
  },
  {
    keys: ['generator', 'genset'], name: 'Generators', interval: 200,
    daily: ['Check the oil level and fuel; run under load, never dry.'],
    periodic: ['Change oil every 100–200 hours; exercise the generator monthly if it’s on standby.'],
    storage: ['Keep in a ventilated, dry place; never run indoors.'],
  },
  {
    keys: ['pivot', 'irrigation', 'drip', 'sprinkler'], name: 'Irrigation equipment', interval: 500,
    daily: ['Walk the lines for leaks, blocked emitters and broken risers.'],
    periodic: ['Flush drip lines monthly and clean filters weekly in the season.', 'Check pivot wheel tracks, gearboxes and tyres.'],
    storage: ['Drain lines and protect from sun damage and rodents off-season.'],
  },
  {
    keys: ['truck', 'vehicle', 'bakkie', 'pickup', 'van', 'car', 'motorbike', 'motorcycle'], name: 'Vehicles', interval: 300,
    daily: ['Check tyres, lights, oil and coolant before each trip.'],
    periodic: ['Service every 5,000–10,000 km or as per the manual; keep a logbook.'],
    storage: ['Park on hard standing; check the battery if it’s idle for long.'],
  },
  {
    keys: ['planter', 'plough', 'plow', 'harrow', 'ripper', 'disc', 'cultivator', 'trailer'], name: 'Implements', interval: 150,
    daily: ['Grease moving parts and check bolts and shear pins.'],
    periodic: ['Replace worn shares, discs and tines before the season starts.'],
    storage: ['Clean off soil, oil bare metal and store under cover.'],
  },
];

export const EQUIPMENT_GENERIC = {
  name: 'General equipment care', interval: 250,
  daily: ['Inspect before use and record operating hours in Usage Logs.'],
  periodic: ['Follow the manufacturer’s service schedule and log every service under Maintenance.'],
  storage: ['Store clean, dry and under cover.'],
};

/* ---------------------------------------------------------------------- */
/* Pests, diseases and weeds — integrated pest management (IPM)           */
/* ---------------------------------------------------------------------- */
export const PEST_KB = [
  {
    keys: ['fall armyworm', 'armyworm', 'faw'], name: 'Fall armyworm', kind: 'pest',
    monitor: 'Scout 20 plants in a W pattern twice a week from emergence. A common action threshold is about 20% of plants with fresh damage at early whorl.',
    cultural: ['Plant early and at the same time as neighbours; intercrop with legumes or use push–pull (desmodium + Napier/Brachiaria).', 'Crush egg masses and young larvae by hand in small plots.'],
    biological: ['Bt (Bacillus thuringiensis) products work well on young larvae.', 'Protect natural enemies (parasitic wasps, earwigs) by avoiding broad-spectrum sprays.'],
    chemical: ['Commonly registered options include emamectin benzoate, chlorantraniliprole and spinetoram. Aim the spray into the whorl, early morning or late afternoon.', 'Pyrethroids such as lambda-cyhalothrin often fail due to resistance — rotate mode-of-action groups.'],
  },
  {
    keys: ['stalk borer', 'stem borer', 'borer'], name: 'Stalk borer', kind: 'pest',
    monitor: 'Look for window-pane feeding and shot-holes in the whorl from 3–6 weeks after emergence.',
    cultural: ['Destroy or graze old stalks after harvest; rotate with non-cereal crops.'],
    biological: ['Bt granules or sprays into the whorl.'],
    chemical: ['Registered granules or sprays (e.g. chlorantraniliprole, lambda-cyhalothrin granules) placed into the whorl at first signs.'],
  },
  {
    keys: ['aphid'], name: 'Aphids', kind: 'pest',
    monitor: 'Check the undersides of young leaves and growing tips; look for honeydew and ants.',
    cultural: ['Avoid too much nitrogen (soft growth attracts aphids); remove heavily infested plants early.'],
    biological: ['Ladybirds, lacewings and parasitic wasps often control them — spare them.', 'Soap or neem sprays for light infestations.'],
    chemical: ['Selective options such as pirimicarb; systemic options such as acetamiprid or imidacloprid where registered. Rotate groups.'],
  },
  {
    keys: ['whitefly'], name: 'Whitefly', kind: 'pest',
    monitor: 'Use yellow sticky traps; shake plants and look for adults flying up.',
    cultural: ['Remove weeds that host whitefly; use insect netting in nurseries.'],
    biological: ['Neem and soap sprays; protect predatory insects.'],
    chemical: ['Options include spirotetramat, pyriproxyfen or acetamiprid where registered — rotate, as whitefly builds resistance fast.'],
  },
  {
    keys: ['spider mite', 'red spider', 'mites'], name: 'Red spider mite', kind: 'pest',
    monitor: 'Look for fine speckling and webbing under leaves, worst in hot, dry, dusty weather.',
    cultural: ['Reduce dust on roads near fields; keep plants well watered.'],
    biological: ['Predatory mites; avoid pyrethroids, which often make mite outbreaks worse.'],
    chemical: ['Registered miticides such as abamectin, spiromesifen or bifenazate; spray the leaf undersides.'],
  },
  {
    keys: ['tuta', 'leafminer', 'leaf miner', 'pinworm'], name: 'Tuta absoluta (tomato leafminer)', kind: 'pest',
    monitor: 'Pheromone traps from transplanting; check for mines and holes in fruit.',
    cultural: ['Remove and destroy infested leaves and fruit; deep-plough after harvest; avoid continuous tomato.'],
    biological: ['Mass trapping with pheromones; Bt for young larvae.'],
    chemical: ['Options include chlorantraniliprole, spinosad, indoxacarb or emamectin benzoate — rotate groups every generation.'],
  },
  {
    keys: ['cutworm'], name: 'Cutworm', kind: 'pest',
    monitor: 'Seedlings cut at ground level overnight; dig around them to find grey larvae.',
    cultural: ['Keep the field weed-free 2 weeks before planting; use collars around transplants.'],
    biological: ['Hand-pick larvae in the evening.'],
    chemical: ['A registered bait or a spray at the base of plants in the late afternoon (e.g. lambda-cyhalothrin).'],
  },
  {
    keys: ['diamondback', 'dbm'], name: 'Diamondback moth', kind: 'pest',
    monitor: 'Check the undersides of brassica leaves for small green larvae that wriggle when touched.',
    cultural: ['Overhead irrigation knocks larvae off; remove crop residues.'],
    biological: ['Bt products are very effective; protect parasitic wasps.'],
    chemical: ['Spinosad, emamectin benzoate or chlorantraniliprole where registered; resistance to pyrethroids is widespread.'],
  },
  {
    keys: ['bollworm', 'budworm', 'heliothis', 'helicoverpa'], name: 'Bollworm', kind: 'pest',
    monitor: 'Count eggs and young larvae on growing points, flowers and young bolls/fruit weekly.',
    cultural: ['Destroy crop residues; trap crops such as pigeon pea or sunflower on the border.'],
    biological: ['Bt and NPV virus products for young larvae.'],
    chemical: ['Options include indoxacarb, spinosad or chlorantraniliprole — time sprays to egg hatch.'],
  },
  {
    keys: ['thrip'], name: 'Thrips', kind: 'pest',
    monitor: 'Blue sticky traps; look for silvery streaks on leaves and damage in flowers.',
    cultural: ['Remove weeds and old crops nearby; avoid planting next to an older onion crop.'],
    biological: ['Predatory mites and bugs; neem.'],
    chemical: ['Spinosad or abamectin where registered; add a wetter and spray into the leaf necks.'],
  },
  {
    keys: ['termite'], name: 'Termites', kind: 'pest',
    monitor: 'Wilting plants with soil tunnels on stems or roots, especially in dry spells.',
    cultural: ['Keep crops well watered; remove dead wood; break up nearby mounds.'],
    biological: ['Mulch and organic matter give termites food other than your crop.'],
    chemical: ['Seed or soil treatment with registered products (e.g. imidacloprid or fipronil based).'],
  },
  {
    keys: ['weevil', 'grain borer', 'storage'], name: 'Storage pests (weevils, grain borer)', kind: 'pest',
    monitor: 'Check stored grain every 2 weeks for holes, dust and live insects.',
    cultural: ['Dry grain to about 12–13% moisture; clean and repair stores before filling.', 'Hermetic (airtight) bags or silos stop insects without chemicals.'],
    biological: ['Mix grain with clean wood ash or diatomaceous earth for small quantities.'],
    chemical: ['A registered grain protectant applied at storage; phosphine fumigation only by trained, licensed people.'],
  },
  {
    keys: ['rat', 'rodent', 'mice', 'mouse'], name: 'Rodents', kind: 'pest',
    monitor: 'Droppings, gnawed bags and burrows around stores.',
    cultural: ['Store on pallets away from walls; remove rubbish and long grass around buildings.'],
    biological: ['Encourage owls (nest boxes); traps.'],
    chemical: ['Rodenticide in tamper-proof bait stations only, away from children, pets and livestock.'],
  },
  {
    keys: ['quelea', 'bird'], name: 'Birds (quelea)', kind: 'pest',
    monitor: 'Watch ripening sorghum, millet, wheat and rice for flocks.',
    cultural: ['Plant at the same time as neighbours, scare birds at dawn and dusk, use nets on small plots, harvest promptly.'],
    biological: [],
    chemical: ['Large outbreaks are handled by the plant protection authorities — report them.'],
  },
  {
    keys: ['locust'], name: 'Locusts', kind: 'pest',
    monitor: 'Report swarms or hopper bands immediately.',
    cultural: ['Report to the plant protection authorities, who coordinate control.'],
    biological: ['Metarhizium-based biopesticides are used in coordinated campaigns.'],
    chemical: ['Do not spray swarms yourself without guidance — coordinated control works best.'],
  },
  {
    keys: ['tick'], name: 'Ticks (livestock)', kind: 'pest',
    monitor: 'Check ears, tail brush, udder and between the legs weekly.',
    cultural: ['Rotate grazing; burn or slash tick-infested paddocks where appropriate.'],
    biological: ['Chickens and guinea fowl pick ticks around kraals.'],
    chemical: ['Dip or spray with a registered acaricide (e.g. amitraz or pyrethroid pour-on) weekly in the rains, every 2 weeks in the dry season.'],
  },
  {
    keys: ['late blight', 'phytophthora'], name: 'Late blight', kind: 'disease',
    monitor: 'Dark, water-soaked patches with white growth under leaves in cool, wet weather; it spreads within days.',
    cultural: ['Plant tolerant varieties; avoid overhead irrigation; remove and destroy infected plants.'],
    biological: [],
    chemical: ['Protect before rain with mancozeb or copper; use systemic products (metalaxyl + mancozeb, cymoxanil) once disease appears. Rotate groups.'],
  },
  {
    keys: ['early blight', 'alternaria', 'target spot'], name: 'Early blight', kind: 'disease',
    monitor: 'Brown spots with rings ("target" pattern) on older leaves first.',
    cultural: ['Remove lower infected leaves; rotate; mulch to stop soil splash.'],
    biological: [],
    chemical: ['Mancozeb, chlorothalonil or azoxystrobin based products where registered.'],
  },
  {
    keys: ['rust'], name: 'Rust', kind: 'disease',
    monitor: 'Orange-brown powdery pustules on leaves that rub off on your fingers.',
    cultural: ['Use resistant varieties; avoid late planting; remove volunteer plants.'],
    biological: [],
    chemical: ['Triazole (e.g. tebuconazole) or strobilurin fungicides at first signs, protecting the upper leaves.'],
  },
  {
    keys: ['powdery mildew'], name: 'Powdery mildew', kind: 'disease',
    monitor: 'White powder on the upper leaf surface, worst in dry days with cool nights.',
    cultural: ['Improve airflow with spacing and pruning.'],
    biological: ['Potassium bicarbonate or milk sprays for light cases.'],
    chemical: ['Sulphur (not in hot weather) or triazole fungicides.'],
  },
  {
    keys: ['downy mildew'], name: 'Downy mildew', kind: 'disease',
    monitor: 'Yellow patches on top of leaves with grey-purple growth underneath in humid weather.',
    cultural: ['Wider spacing, morning irrigation, remove infected leaves.'],
    biological: [],
    chemical: ['Metalaxyl, mancozeb or copper based products where registered.'],
  },
  {
    keys: ['grey leaf spot', 'gray leaf spot', 'gls'], name: 'Grey leaf spot', kind: 'disease',
    monitor: 'Long, rectangular grey lesions between the veins of maize leaves.',
    cultural: ['Tolerant hybrids, rotation away from maize, bury or remove residues.'],
    biological: [],
    chemical: ['Strobilurin + triazole fungicide at early lesions before tasselling if the hybrid is susceptible.'],
  },
  {
    keys: ['bacterial wilt', 'wilt'], name: 'Bacterial wilt', kind: 'disease',
    monitor: 'Plants wilt suddenly in the heat while still green; cut stems ooze milky liquid in water.',
    cultural: ['No chemical cure — uproot and destroy infected plants, rotate 3+ years with non-host crops (cereals), use clean water and tools, and consider grafted seedlings.'],
    biological: [],
    chemical: ['Chemicals do not cure bacterial wilt; focus on prevention and hygiene.'],
  },
  {
    keys: ['streak', 'virus', 'mosaic', 'rosette', 'curl'], name: 'Virus diseases', kind: 'disease',
    monitor: 'Streaks, mosaic patterns, curling or stunting; often spread by insects (leafhoppers, aphids, whitefly).',
    cultural: ['Rogue infected plants early; plant early and use resistant varieties; control weeds that host the virus.'],
    biological: [],
    chemical: ['There is no cure for the virus itself — control the insect vector instead.'],
  },
  {
    keys: ['leaf spot', 'blight', 'anthracnose', 'rot', 'damping'], name: 'Fungal leaf and stem disease', kind: 'disease',
    monitor: 'Spots, lesions or rot spreading after wet, humid weather.',
    cultural: ['Rotate crops, remove infected material, avoid wetting leaves, improve spacing and drainage.'],
    biological: ['Trichoderma-based products for soil-borne problems.'],
    chemical: ['A registered protectant fungicide (e.g. mancozeb or copper) ahead of wet spells.'],
  },
  {
    keys: ['striga', 'witchweed'], name: 'Striga (witchweed)', kind: 'weed',
    monitor: 'Pink/purple-flowered weed attached to maize, sorghum or millet roots; the crop looks drought-stressed.',
    cultural: ['Rotate with trap crops (soybean, cotton, groundnut, cowpea); hand-pull before it flowers; add manure and nitrogen.', 'Use striga-tolerant varieties and push–pull with desmodium.'],
    biological: [],
    chemical: ['Herbicide-coated (imazapyr-resistant) maize seed where available.'],
  },
  {
    keys: ['couch', 'nutsedge', 'nut grass', 'sedge', 'grass weed'], name: 'Perennial grass weeds', kind: 'weed',
    monitor: 'Spreading underground runners or tubers that regrow after weeding.',
    cultural: ['Repeated dry-season tillage to dry out rhizomes; mulching; competitive crop stands.'],
    biological: [],
    chemical: ['Glyphosate on actively growing weeds before planting; selective grass herbicides in-crop where registered.'],
  },
];

export const PEST_GENERIC = {
  pest: {
    name: 'Insect pests (general IPM)', kind: 'pest',
    monitor: 'Scout weekly in a W pattern, record what you find, and act only when damage passes a threshold.',
    cultural: ['Rotate crops, remove crop residues and weeds that host pests, and plant at the right time.'],
    biological: ['Protect natural enemies by choosing selective products; use Bt, neem or soap where they work.'],
    chemical: ['Pick a registered product for the pest and crop, follow the label rate and pre-harvest interval, and rotate mode-of-action groups.'],
  },
  disease: {
    name: 'Plant diseases (general)', kind: 'disease',
    monitor: 'Watch for spots, wilting or rot after rain or humid spells.',
    cultural: ['Clean seed, rotation, good spacing and drainage, and remove infected plants.'],
    biological: ['Trichoderma or Bacillus subtilis based products for some soil and leaf diseases.'],
    chemical: ['Protectant fungicides before wet weather; systemic ones once disease appears. Rotate groups.'],
  },
  weed: {
    name: 'Weeds (general)', kind: 'weed',
    monitor: 'Weed when weeds are small — the first 6 weeks after planting matter most.',
    cultural: ['Timely hand or mechanical weeding, mulching, and dense crop stands.'],
    biological: ['Cover crops and intercrops to shade weeds out.'],
    chemical: ['Pre-emergence herbicide at planting and post-emergence products registered for the crop.'],
  },
};

export const SAFETY_NOTE = 'Before any spray: confirm the product is registered for that crop and pest, read the label, wear the PPE it lists, spray in calm conditions (wind under about 15 km/h, no rain expected for 6 hours), and respect the pre-harvest and re-entry intervals.';

/* ---------------------------------------------------------------------- */
/* Seasonal outlook — month-by-month reminders.                           */
/* Southern hemisphere calendar (e.g. Zimbabwe / Southern Africa).        */
/* ---------------------------------------------------------------------- */
export const SEASON_SOUTH = {
  0: ['Peak rains: top-dress maize and scout weekly for fall armyworm, stalk borer and leaf diseases.', 'Dip cattle weekly — tick-borne diseases peak now.', 'Clear drainage around fields and pens.'],
  1: ['Watch maize for grey leaf spot and rust; keep weeding late-planted crops.', 'Plan storage space, bags and grain protectants for the coming harvest.'],
  2: ['Early harvest of green maize and groundnuts; dry produce well before storage.', 'Start preparing winter wheat land and irrigation.'],
  3: ['Main harvest: shell, dry to 12–13% moisture and treat or seal grain.', 'Plant winter wheat and vegetables under irrigation.'],
  4: ['Harvest and market; conserve crop residues as dry-season feed.', 'Service equipment used in the harvest before storing it.'],
  5: ['Frost risk — protect seedlings and young livestock.', 'Supplement grazing animals as pasture quality drops.'],
  6: ['Dry season: check boreholes and pumps, fix fences and housing.', 'Soil test and order lime and fertiliser early.'],
  7: ['Winter land preparation; plan the summer cropping programme and order seed.', 'Wheat: watch for aphids and rust.'],
  8: ['Hot and dry: water stress and spider mites rise; give livestock shade and water.', 'Service tractors and planters before the season.'],
  9: ['Pre-season: apply lime, prepare land, and make sure seed and fertiliser are in stock.', 'Destroy old crop residues to cut pest carry-over.'],
  10: ['Plant with the first effective rains (about 25 mm); gap-fill quickly.', 'Start scouting for cutworm and fall armyworm on emerging crops.', 'Vaccinate and deworm livestock before the main rains.'],
  11: ['Weed early and top-dress on time; heavy rain — avoid spraying before storms.', 'Tick and worm pressure rising — keep dipping on schedule.'],
};

export const SEASON_NORTH = {
  0: ['Plan the season, service machinery, order seed and inputs.'],
  1: ['Prepare land and nurseries; check stored produce for pests.'],
  2: ['Start planting early crops; protect seedlings from late frost.'],
  3: ['Main planting; begin weekly scouting.'],
  4: ['Weed and top-dress; watch for aphids as temperatures rise.'],
  5: ['Irrigation demand climbs — check pumps and lines.'],
  6: ['Heat stress on livestock and crops; scout for mites and fungal disease after storms.'],
  7: ['Plan harvest logistics and storage.'],
  8: ['Harvest early crops; dry produce well before storage.'],
  9: ['Main harvest; clean and service equipment after use.'],
  10: ['Store crops safely; prepare housing for winter.'],
  11: ['Review the year’s records and profit/loss; plan rotations.'],
};
