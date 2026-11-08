# John Dhiri Intelligent Farm System — Front End

Plain HTML / CSS / vanilla JS (ES modules). No framework, no bundler, no
build step. Talks to a real PHP + MySQL backend (see `ffms-backend/`)
over `fetch()` — nothing here uses `localStorage` for business data
anymore; only the session token is cached locally.

## Run it

1. Get the backend running first (see `ffms-backend/README.md`) — this
   front end has nothing to show without it.
2. Open `js/config.js` and confirm `API_BASE` points at your backend
   (defaults to `http://localhost:8888/ffms-backend/api` for MAMP).
3. Then:

```
npm run dev
```

Open **http://localhost:5500/login.html**

`npm run dev` needs no `npm install` — it runs a small built-in Node
static file server (`server.cjs`) using only Node's standard library.

Alternatives: VS Code's "Live Server" extension, or
`python3 -m http.server 8000`.

## What's here

```
login.html            Sign in
signup.html            Create account — role picker, password strength meter
verify-email.html       Landing page for the emailed verification link
forgot-password.html    Request a password reset email
reset-password.html     Landing page for the emailed reset link
app.html                 The app shell (sidebar, top bar, drawer, toasts)
css/styles.css            Design system (Natural palette) + password UI + banners
js/config.js                The one line to edit once your backend is deployed
js/store.js                Auth/Store — now a thin wrapper over api.js, not localStorage
js/api.js                   Fetch client + bearer token handling (reads API_BASE from config.js)
js/schema.js                 Every module's fields, table columns, icons, role permissions
js/app.js                     Router + generic add/edit/delete engine (fully async)
js/banners.js                  Illustrated SVG hero banners per module category
js/password-ui.js               Eye-toggle + live strength meter, shared component
server.cjs                       Zero-dependency dev server
```

## Accounts are real now

Signing up creates a row in the real `users` table and sends a genuine
verification email. You can't sign in until that link is clicked.
Forgotten passwords go through a real emailed reset link, not a
client-side reset. See `ffms-backend/README.md` for how to configure
SMTP (Gmail app password, Mailtrap, etc.) — until that's set up,
verification/reset emails won't actually arrive (the backend logs what
it *would* have sent, for local testing).

Password rule, enforced both in the strength meter and again on the
server (client-side validation is only ever a UX nicety): at least 8
characters, one uppercase letter, one lowercase letter, one number, one
symbol.

## Weather is automatic

The Weather & Maps page reads each farm's saved latitude/longitude and
fetches a live forecast from Open-Meteo (free, no API key) — nothing to
configure. A farm with no coordinates just shows "no coordinates saved."

## Role access is enforced twice

The sidebar hides modules a role can't use, which is nice UX — but the
**real** boundary is server-side: every API call re-checks the logged-in
user's role against `Schema.php`'s whitelist before touching the
database. Guessing a URL client-side changes nothing.

## Deploying

This front end → Netlify (drag-and-drop the folder, or connect the
repo). The PHP backend **cannot** run on Netlify — see
`ffms-backend/README.md` for hosting (Railway is what this project is
set up for). Before publishing, edit `js/config.js` with your deployed
backend's real URL, and add your Netlify URL to `ALLOWED_ORIGINS` in the
backend's environment variables.

Full step-by-step: see `NETLIFY_DEPLOY.md`.
