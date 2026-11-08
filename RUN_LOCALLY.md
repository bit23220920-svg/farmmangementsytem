# Run John Dhiri Intelligent Farm System on your Mac

Everything runs on your own computer: MySQL from MAMP, the PHP backend, and the website.
On Windows with XAMPP, follow `RUN_ON_WINDOWS_XAMPP.md` instead.
Nothing here touches your live Railway or Netlify sites.

## What makes local login easier

- `ffms-frontend/js/config.js` uses `http://localhost:8000/api` automatically when the site is opened from `localhost` or `127.0.0.1`. You never edit this file, so there is nothing to change back before pushing to GitHub. The live Netlify site still uses Railway.
- `ffms-backend/.env.local-mamp` is a ready-made `.env` for MAMP, with both `http://localhost:5500` and `http://127.0.0.1:5500` allowed.
- `php tools/check_setup.php` checks PHP, Composer, `.env`, the database, the tables, roles and farm access, and lists every account with its farm and whether it is verified.
- `php tools/verify_user.php you@example.com` verifies an account, so you do not need phpMyAdmin for that step.
- `php tools/make_admin.php you@example.com` makes an account an administrator.
- If the website cannot reach the backend, the sign-in error says which address it tried and what to check.

## Steps

1. **Start MAMP** and click Start. Note the MySQL port on MAMP's start page (usually 8889).

2. **Create the database.** In phpMyAdmin, go to Import and import these files from `ffms-backend/db/`, one at a time, in this order:
   1. `ffms_schema.sql`
   2. `auth_migration.sql`
   3. `seed_roles.sql`
   4. `farm_access_migration.sql` (links people, customers and suppliers to farms)
   5. `currency_migration.sql` (new: gives each farm a country and currency)

   If you imported some of these before, import only the ones you haven't, each only once. Step 5 tells you whether anything is missing.

   **Optional sample data:** import `sample_data_three_farms.sql` as well. It adds John Sichula (`test@gmail.com`, password `Farm@2026`) as an administrator with three farms, 15 staff accounts and 15 or more records in every module. Importing it again resets those three farms to the sample state.

3. **Open Terminal in the backend folder:**
   ```bash
   cd path/to/ffms-backend
   ```
   If `php -v` says "command not found", use MAMP's PHP for every `php` command below, for example:
   ```bash
   alias php=/Applications/MAMP/bin/php/php8.2.0/bin/php
   ```
   Run `ls /Applications/MAMP/bin/php/` to see the exact version folder on your Mac.

4. **Install and configure:**
   ```bash
   composer install
   cp .env.local-mamp .env
   ```
   Run `composer install` again even if you ran it before: it now also installs the Claude library for the farm assistant. If your MAMP MySQL port is not 8889, change `DB_PORT` in `.env`.

5. **Check the setup:**
   ```bash
   php tools/check_setup.php
   ```
   Fix anything marked ✗. It tells you how.

6. **Start the backend** and leave this Terminal window open:
   ```bash
   php -S localhost:8000 router.php
   ```
   http://localhost:8000/ should show `"status":"ok"`.

7. **Start the website** in a second Terminal window:
   ```bash
   cd path/to/ffms-frontend
   npm run dev
   ```
   Open **http://localhost:5500/login.html**.

8. **Create your account.** Sign up and choose **Administrator** as the role (the very first administrator can sign up directly; after that only an administrator can create more). No email is sent locally, so in the backend folder run:
   ```bash
   php tools/verify_user.php the-email-you-signed-up-with@example.com
   ```
   Then sign in. If you already have an account, make it an administrator instead:
   ```bash
   php tools/make_admin.php your@email.com
   ```

## Farms and who sees what

- **Administrators** see every farm. The farm box at the top of every page lets them switch between "All farms" and one farm.
- **Everyone else belongs to one farm** and only ever sees that farm's fields, crops, animals, machinery, stock, money, customers, suppliers, team and audit log. Their farm box shows their farm and can't be changed. The server enforces this, so it holds even if someone edits the page or calls the API directly.
- **A farm owner who signs up without a farm** can add one farm under Farms, and is put on it automatically.
- **Anyone else who signs up** sees nothing until they are added to a farm. An administrator, or the owner of that farm, does this in **Administration → Team & Roles** using the Farm column. They are signed out once so their next sign-in picks up the farm.

## Farm assistant (the chat on the AI page)

Click **Ask the farm assistant** at the bottom right of the AI Farm Overview Analysis page.

- **Without any setup** it answers from your records and the built-in farm guides: what needs attention, crop care by stage, pest control, animal treatments due, machinery services, profit and loss, low stock, the spray forecast and the seasonal calendar.
- **With Claude switched on** it can answer any farming question in your own words, using the same records. Put an Anthropic API key (from https://console.anthropic.com) in `.env`:
  ```
  ANTHROPIC_API_KEY=sk-ant-...
  ```
  then restart the backend (step 6). It uses Claude Opus 5.5 with quick, low-effort replies. A typical question costs about US$0.01 to $0.05. `AI_CHAT_HOURLY_LIMIT` (default 40) caps questions per person per hour. If a safety check declines a question, the request automatically retries on another Claude model that Anthropic recommends.
- The assistant only receives the farm data that the person asking is allowed to see.

## If sign-in still fails, match the red message

| Message | Cause | Fix |
|---|---|---|
| "Could not reach the server at http://localhost:8000/api…" | The backend is not running, or `.env` does not allow this website address | Step 6 must be running. Run `php tools/check_setup.php` to confirm `ALLOWED_ORIGINS`. Restart the backend after any `.env` change. |
| "Could not reach the server. Check your connection…" (no address shown) | The browser is still using the old `config.js` | Use the files from this zip, then hard-refresh (Cmd+Shift+R). |
| "Database connection failed. Check your .env settings." | Wrong MySQL port, or MAMP is stopped | Match `DB_PORT` to MAMP's start page. If it still fails, uncomment `DB_SOCKET=` in `.env`. |
| "Something went wrong on the server." when signing in | `farm_access_migration.sql` was not imported | Import it (step 2), then run `php tools/check_setup.php`. |
| "Please verify your email before signing in…" | The account is not verified | `php tools/verify_user.php your@email.com` |
| "Something went wrong on the server." when saving a farm | `currency_migration.sql` was not imported | Import it once (step 2). |
| "Incorrect email or password." | No account with that email in the **local** database, or a typo | Accounts from the live site are not in the local database. Sign up again locally. |
| "Your account is not linked to a farm yet…" | The account has no farm | An administrator or the farm's owner adds it in Team & Roles. |
| "That role is not recognised." (on sign-up) | `seed_roles.sql` was not imported | Import it (step 2). |
| "Request failed (500)" on sign-up | `composer install` was not run | Step 4. |

## Using the live Railway data from your Mac instead

Open the browser console on http://localhost:5500 and run:
```js
localStorage.setItem('ffms_api_base', 'https://web-production-bdd2b6.up.railway.app/api')
```
Then reload. Railway must also list `http://localhost:5500` in its `ALLOWED_ORIGINS` variable, and anything you change is real data. The live database also needs the farm migration first (see `UPDATING_THE_LIVE_SITE.md`). To switch back, run `localStorage.removeItem('ffms_api_base')`.
