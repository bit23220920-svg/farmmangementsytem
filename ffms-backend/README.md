# John Dhiri Intelligent Farm System — Backend (PHP + MySQL API)

A dependency-light PHP API (no framework — plain PHP files, one per
endpoint) backing the FFMS front end. The only third-party code is
PHPMailer, for sending real verification/reset emails over SMTP.

> **I could not run or test this PHP code in the environment I built it
> in** (no PHP interpreter available there). It's written carefully
> against standard PDO/PHP 8.1+ patterns, but please run through the
> smoke-test steps below on your own machine (you have MAMP, per your
> screenshots) before trusting it with real data.

## 1. Set up the database

In order:

```bash
mysql -u root -p < db/ffms_schema.sql        # your original 38-table schema
mysql -u root -p < db/auth_migration.sql      # adds email_verifications, password_resets, auth_tokens
mysql -u root -p < db/seed_roles.sql          # seeds the 6 roles with exact lowercase names
mysql -u root -p ffms_db < db/farm_access_migration.sql  # links people, customers and suppliers to farms
mysql -u root -p < db/currency_migration.sql             # gives each farm a country and currency
mysql -u root -p < db/sample_data_three_farms.sql         # optional: John Sichula's 3 sample farms (local use only)
```

## 2. Install PHPMailer

```bash
cd ffms-backend
composer install
```

If you don't have Composer: https://getcomposer.org/download/ — it's a
one-time install, then `composer install` just works.

## 3. Configure environment

```bash
cp .env.example .env
```

Then edit `.env`:
- `DB_*` — match your MAMP MySQL credentials (MAMP's default MySQL port
  is often **8889**, not 3306 — check MAMP's preferences panel).
- `ALLOWED_ORIGINS` — add wherever your front end runs (e.g.
  `http://localhost:5500` for the dev server, plus your Netlify URL
  once deployed).
- `SMTP_*` — for Gmail: turn on 2-Step Verification, then generate an
  **App Password** at https://myaccount.google.com/apppasswords and use
  that (not your normal password). Mailtrap.io is a good alternative for
  testing without sending real email.

## 4. Point your web server at this folder

With MAMP: put this `ffms-backend` folder inside MAMP's `htdocs`, then
it's reachable at `http://localhost:8888/ffms-backend/` (or whatever
port MAMP uses). Visiting that URL directly should return the JSON
health check from `index.php`.

## 5. Smoke test

```bash
# Health check
curl http://localhost:8888/ffms-backend/

# Sign up
curl -X POST http://localhost:8888/ffms-backend/api/auth_signup.php \
  -H "Content-Type: application/json" \
  -d '{"firstName":"Jane","lastName":"Mwansa","email":"jane@example.com","password":"Str0ng!Pass","role":"owner"}'

# Check your inbox (or the PHP error log if SMTP isn't configured yet —
# Mailer.php logs what it *would* have sent) for the verification link,
# copy the token out of it, then:
curl -X POST http://localhost:8888/ffms-backend/api/auth_verify.php \
  -H "Content-Type: application/json" \
  -d '{"token":"PASTE_TOKEN_HERE"}'

# Now log in
curl -X POST http://localhost:8888/ffms-backend/api/auth_login.php \
  -H "Content-Type: application/json" \
  -d '{"email":"jane@example.com","password":"Str0ng!Pass"}'
# -> returns { "data": { "token": "...", "user": {...} } }

# Use that token for everything else
curl http://localhost:8888/ffms-backend/api/records.php?entity=farms \
  -H "Authorization: Bearer PASTE_LOGIN_TOKEN_HERE"
```

## Deploying to Railway (recommended — native PHP, no Docker)

Railway builds this repo as a **native PHP app** — no Dockerfile involved, which matters if you want the deployment to visibly be "just PHP." It detects `composer.json`, runs `composer install`, and starts it using the `Procfile` included in this repo:

```
web: php -S 0.0.0.0:$PORT -t . router.php
```

This uses PHP's own built-in web server rather than Apache — it's the most portable option across PHP buildpacks (an earlier version of this Procfile used `heroku-php-apache2`, which isn't available on Railway's PHP build image; `php -S` is, since the `php` binary itself has to exist for `composer install` to even run). Because the built-in server doesn't read `.htaccess`, `router.php` does that job instead — it blocks direct requests to `src/`, `config/`, `vendor/`, `db/`, `.env`, etc., and lets everything else (`index.php`, `api/*.php`) through normally. Railway also offers MySQL as a first-party managed database plugin, in the same project — so the whole backend, database included, lives in one account.

1. **Push this folder to its own GitHub repo** (Railway deploys from Git).
2. In Railway, **New Project → Deploy from GitHub repo**, pick it.
3. In the same project, click **+ New → Database → Add MySQL**. Railway provisions it and shows its connection variables (host, port, user, password, database name) on the MySQL service's **Variables** tab — the exact names are shown there in your dashboard.
4. On your **PHP service's** Variables tab, set:
   - `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS` — reference the MySQL service's variables using Railway's `${{ServiceName.VARIABLE_NAME}}` syntax (Railway's variable editor autocompletes this when you type `${{` — pick the matching field from the MySQL service).
   - `ALLOWED_ORIGINS` — your frontend's real URL (Netlify).
   - `FRONTEND_URL` — same, used to build the links inside verification/reset emails.
   - `TOKEN_TTL_DAYS`, `VERIFICATION_TTL_HOURS`, `RESET_TTL_MINUTES` — same defaults as `.env.example`, or your own.
   - `SMTP_HOST`, `SMTP_PORT`, `SMTP_ENCRYPTION`, `SMTP_USER`, `SMTP_PASS`, `MAIL_FROM_EMAIL`, `MAIL_FROM_NAME`.
   - There's no `.env` file in production — `config/config.php` reads real environment variables directly, and only falls back to a local `.env` file if one exists (i.e. on your own machine). Nothing to change there.
5. Run the five SQL files against the Railway MySQL database once, from your machine, using the connection details from its Variables tab:
   ```bash
   mysql -h <MYSQL_HOST> -P <MYSQL_PORT> -u <MYSQL_USER> -p <MYSQL_DATABASE> < db/ffms_schema.sql
   mysql -h <MYSQL_HOST> -P <MYSQL_PORT> -u <MYSQL_USER> -p <MYSQL_DATABASE> < db/auth_migration.sql
   mysql -h <MYSQL_HOST> -P <MYSQL_PORT> -u <MYSQL_USER> -p <MYSQL_DATABASE> < db/seed_roles.sql
   mysql -h <MYSQL_HOST> -P <MYSQL_PORT> -u <MYSQL_USER> -p <MYSQL_DATABASE> < db/farm_access_migration.sql
   mysql -h <MYSQL_HOST> -P <MYSQL_PORT> -u <MYSQL_USER> -p <MYSQL_DATABASE> < db/currency_migration.sql
   ```
   (Already live? Run only the migrations the live database doesn't have yet, before deploying this version. The `USE ffms_db;` line in each file must name the Railway database, so remove it or change it first. See `UPDATING_THE_LIVE_SITE.md`.)
6. Deploy. Railway gives the service a public `*.up.railway.app` URL under **Settings → Networking → Public Networking** (click **Generate Domain** if none exists yet) — visiting it should return the `index.php` health check JSON.
7. If it instead shows "Application failed to respond," check the service's **Deploy Logs** tab first — that's where the real error shows up (e.g. a missing DB variable, or the Procfile command not being picked up). If Railway isn't running the Procfile at all, open **Settings → Deploy → Custom Start Command** and paste the same command in manually: `php -S 0.0.0.0:$PORT -t . router.php`.
8. Update `js/config.js` in the front end to this service's real URL, and redeploy the front end.

## Other hosting options

If you'd rather not use Railway:

- **DigitalOcean App Platform** — also has a native PHP buildpack (no Docker needed) and offers its own managed MySQL database as a first-party product, so it's another genuine single-vendor option. Typically no permanent free tier.
- **Classic shared hosting** (Hostinger, and similar cPanel-style hosts) — the most traditional LAMP-style option: upload via FTP/Git, MySQL database created in cPanel. Very cheap, but no git-push deploy workflow — you manage updates manually.
- **Render** (via Docker) — Render has no managed MySQL and no native PHP runtime, so this route means wrapping the app in a `Dockerfile` (a Docker web service) and pointing it at MySQL hosted elsewhere (e.g. Railway or Aiven's MySQL, used purely as a database with nothing else deployed there). Ask if you want this Dockerfile built instead.

Whichever host, the same three SQL files and the same environment-variable list apply — only the deployment mechanics change.

## How auth works here (since front end and backend are different domains)

Regular PHP sessions rely on cookies tied to one domain — awkward once
the front end lives on Netlify and the backend lives elsewhere. Instead:

1. Login returns a random 64-character **bearer token** (`auth_tokens`
   table stores only its SHA-256 hash, never the raw value).
2. The front end stores that token and sends it back as
   `Authorization: Bearer <token>` on every request.
3. Every protected endpoint re-resolves that header to a user via
   `Auth::requireUser()` / `Auth::requireRole([...])` — **this is the
   real access-control boundary**. The front end's sidebar hiding
   modules by role is just UX; this is what actually stops a Worker
   account from writing to `financial_transactions` even if they guess
   the URL.

## Files

```
index.php               Health check
Procfile                 Tells the PHP buildpack how to start the web server
router.php                Replicates .htaccess's protections for PHP's built-in server (php -S doesn't read .htaccess)
composer.json           PHPMailer, Claude SDK + Guzzle, required PHP extensions
.env.example            Copy to .env and fill in
.htaccess                Blocks direct access to src/config/vendor/db
config/config.php        Reads .env, central settings
db/ffms_schema.sql       Your original 38-table schema
db/auth_migration.sql    New tables: email_verifications, password_resets, auth_tokens
db/seed_roles.sql        Seeds the 6 roles with exact lowercase names
db/farm_access_migration.sql  Adds farm_id to users, customers, suppliers and backfills it
db/currency_migration.sql     Adds country_code and currency_code to farms
db/sample_data_three_farms.sql  Optional sample data: 3 farms, 16 accounts, 15+ records per module
src/FarmScope.php        Farm-level access: which farm every table's rows belong to
api/ai_chat.php          Farm assistant (Claude, when ANTHROPIC_API_KEY is set)
tools/                   CLI helpers: check_setup, verify_user, make_admin
src/Database.php         PDO connection singleton
src/Response.php         JSON response helper
src/Auth.php             Token generation, password hashing/policy, current-user resolution
src/AuditLogger.php      Writes to audit_logs
src/Mailer.php           PHPMailer wrapper (verification + reset emails)
src/Schema.php           Auto-generated table/column/role whitelist (do not hand-edit — see below)
api/bootstrap.php        CORS + error handling, included by every endpoint
api/auth_signup.php
api/auth_verify.php
api/auth_resend_verification.php
api/auth_login.php
api/auth_logout.php
api/auth_me.php
api/auth_change_password.php
api/auth_forgot_password.php
api/auth_reset_password.php
api/records.php          Generic CRUD for all 35 data tables (farms, fields, livestock, ...)
api/team.php             List/update team members (role, status)
api/audit.php            Audit log (admin + owner only)
```

`src/Schema.php` is generated from the real parsed SQL schema, not
hand-typed, so table/column/primary-key names are guaranteed to match
`ffms_schema.sql` exactly. If you alter the database schema later,
regenerate it rather than editing it by hand.
