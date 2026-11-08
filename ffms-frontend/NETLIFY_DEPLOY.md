# Deploying the John Dhiri Intelligent Farm System front end to Netlify

Two ways to do this — pick whichever fits how you work.

## Option A: Drag-and-drop (fastest, no GitHub needed)

1. Go to https://app.netlify.com → **Add new site → Deploy manually**.
2. Drag the whole `ffms` folder onto the upload area (the one containing
   `login.html`, `netlify.toml`, `js/`, `css/`, etc. — not a zip, the
   unzipped folder itself; Netlify's drop zone accepts a folder).
3. Netlify gives you a random URL like `https://random-name-123.netlify.app`.
   That's your live front end.
4. To redeploy after any change (e.g. updating `js/config.js`), just
   drag the folder onto the same site's **Deploys** tab again.

## Option B: Connect a Git repo (auto-deploys on every push)

1. Push the `ffms` folder to its own GitHub repo.
2. In Netlify: **Add new site → Import an existing project → GitHub**,
   pick the repo.
3. Build settings: leave **Build command** empty (there is no build
   step) and set **Publish directory** to `.` (the repo root) —
   `netlify.toml` already sets this, so Netlify should pick it up
   automatically.
4. Deploy. Every `git push` after this redeploys automatically.

## After the first deploy — connecting it to your Railway backend

1. Get your Railway backend's public URL (looks like
   `https://your-app-name.up.railway.app`) — visiting it directly should
   show the `index.php` health-check JSON.
2. Edit `js/config.js` in the `ffms` folder:
   ```js
   export const API_BASE = 'https://your-app-name.up.railway.app/api';
   ```
3. Redeploy (drag-and-drop again, or `git push` if using Option B).
4. On the **Railway** side, open your PHP service's environment
   variables and set `ALLOWED_ORIGINS` to include your Netlify URL,
   e.g.:
   ```
   ALLOWED_ORIGINS=https://your-site-name.netlify.app
   ```
   and `FRONTEND_URL` to the same value (it's used to build the links
   inside verification/reset emails). Redeploy the backend so it picks
   up the new variables.
5. Test the full loop: open the Netlify URL → Sign up → check email for
   the verification link → click it → sign in.

## Optional: a real domain instead of `*.netlify.app`

Netlify → **Domain settings → Add a custom domain**, then point your
domain's DNS at Netlify as it instructs. If you do this, remember to
update `ALLOWED_ORIGINS` and `FRONTEND_URL` on the Railway side to the
new domain too — CORS will silently block everything otherwise.

## Quick troubleshooting

- **Blank page / console errors about modules** — Netlify serves static
  files correctly out of the box for ES modules, so this usually means
  a typo in `js/config.js`. Check the browser console.
- **"Could not reach the server" toast on login/signup** — `API_BASE` in
  `js/config.js` is wrong, or the Railway backend isn't running. Visit
  the backend URL directly to confirm it responds.
- **Login/signup requests fail with no clear error, or the browser
  console shows a CORS error** — `ALLOWED_ORIGINS` on the Railway side
  doesn't include your exact Netlify URL (must match scheme + host
  exactly, no trailing slash).
- **Verification/reset emails never arrive** — SMTP isn't configured
  yet on the Railway side (see `ffms-backend/README.md`). Until then the
  backend logs what it *would* have sent instead of failing outright.
