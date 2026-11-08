/* ==========================================================================
   John Dhiri Intelligent Farm System — backend URL configuration.
   This is the ONE line to change once your Railway backend is live:

     export const API_BASE = 'https://your-app-name.up.railway.app/api';

   Everything else in the front end imports API_BASE from here — nothing
   else needs to change. After editing this file, redeploy the Netlify
   site (drag-and-drop the folder again, or git push if connected).

   Alternative, no-redeploy option: leave this file alone and instead set
   window.FFMS_API_BASE via Netlify's Snippet Injection (Site settings →
   Build & deploy → Post processing → Snippet injection → Before </head>):
     <script>window.FFMS_API_BASE = 'https://your-app-name.up.railway.app/api';</script>
   That overrides this file's value without touching any code.
   ========================================================================== */

const LIVE_API = 'https://web-production-bdd2b6.up.railway.app/api';
const LOCAL_API = 'http://localhost:8000/api';

/* Running on your own computer (http://localhost:5500 or 127.0.0.1)?
   Then talk to the local PHP backend automatically, so this file never
   has to be edited back and forth before pushing to GitHub. The live
   Netlify site is unaffected and keeps using LIVE_API.
   To use the live Railway backend from your computer instead, run this
   once in the browser console and reload:
     localStorage.setItem('ffms_api_base', 'https://web-production-bdd2b6.up.railway.app/api')
   (and localStorage.removeItem('ffms_api_base') to switch back). */
const IS_LOCAL = ['localhost', '127.0.0.1', '[::1]'].includes(window.location.hostname);
let override = null;
try{ override = localStorage.getItem('ffms_api_base'); }catch(e){ /* storage blocked */ }

export const API_BASE = window.FFMS_API_BASE || override || (IS_LOCAL ? LOCAL_API : LIVE_API);
