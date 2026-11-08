/* ==========================================================================
   Light, dark or system theme.

   Loaded in the <head> of app.html (before the page draws, so it never
   flashes the wrong colours) and imported by hero.js on the sign-in pages.
   "System" follows the device's own light/dark setting; the colours for
   each theme live in css/styles.css.
   ========================================================================== */
(function () {
  var KEY = 'jd_theme';
  var media = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;

  function read() {
    try {
      var v = localStorage.getItem(KEY);
      return v === 'light' || v === 'dark' ? v : 'system';
    } catch (e) { return 'system'; }
  }
  function apply(mode) {
    var root = document.documentElement;
    if (mode === 'light' || mode === 'dark') root.setAttribute('data-theme', mode);
    else root.removeAttribute('data-theme');
  }
  function isDark() {
    var mode = read();
    if (mode === 'system') return !!(media && media.matches);
    return mode === 'dark';
  }
  function set(mode) {
    try {
      if (mode === 'light' || mode === 'dark') localStorage.setItem(KEY, mode);
      else localStorage.removeItem(KEY);
    } catch (e) { /* storage blocked: still apply for this page */ }
    apply(mode);
    notify();
  }
  function notify() {
    try { document.dispatchEvent(new CustomEvent('jd-theme-change', { detail: { mode: read(), dark: isDark() } })); } catch (e) { /* old browser */ }
  }

  apply(read());
  // Follow the device when it switches between light and dark ("System").
  if (media) {
    var onChange = function () { if (read() === 'system') notify(); };
    if (media.addEventListener) media.addEventListener('change', onChange);
    else if (media.addListener) media.addListener(onChange);
  }
  // Keep other open tabs in step.
  window.addEventListener('storage', function (e) { if (e.key === KEY) { apply(read()); notify(); } });

  window.JDTheme = { get: read, set: set, isDark: isDark };
})();
