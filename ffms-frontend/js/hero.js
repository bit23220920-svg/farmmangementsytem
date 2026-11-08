import './theme.js';   // apply the saved light/dark theme on the sign-in pages
/* ==========================================================================
   Rotating farm photos behind the login / sign-up panel.
   To add pictures: put the file in images/hero/ (portrait, around
   1000x1250 works best) and add its path to HERO_IMAGES below.
   ========================================================================== */
const HERO_IMAGES = [
  'images/hero/hero-1.jpg',
  'images/hero/hero-2.jpg',
  'images/hero/hero-3.jpg',
  'images/hero/hero-4.jpg',
  'images/hero/hero-5.jpg',
  'images/hero/hero-6.jpg',
];
const INTERVAL_MS = 7000;

function startHero(){
  const panel = document.querySelector('.auth-brand');
  if (!panel || !HERO_IMAGES.length) return;

  const wrap = document.createElement('div');
  wrap.className = 'hero-slides';
  wrap.setAttribute('aria-hidden', 'true');
  const slides = HERO_IMAGES.map(src => {
    const d = document.createElement('div');
    d.className = 'hero-slide';
    d.style.backgroundImage = `url("${src}")`;
    wrap.appendChild(d);
    return d;
  });
  panel.prepend(wrap);

  let current = Math.floor(Math.random() * slides.length);  // different first photo each visit

  // Show the first photo only once it has loaded, so it fades in instead of popping.
  const first = new Image();
  first.onload = first.onerror = () => slides[current].classList.add('active');
  first.src = HERO_IMAGES[current];

  if (slides.length < 2) return;

  // Warm the cache for the rest in the background.
  HERO_IMAGES.forEach((src, i) => { if (i !== current) new Image().src = src; });

  setInterval(() => {
    if (document.hidden) return;
    slides[current].classList.remove('active');
    current = (current + 1) % slides.length;
    slides[current].classList.add('active');
  }, INTERVAL_MS);
}

startHero();
