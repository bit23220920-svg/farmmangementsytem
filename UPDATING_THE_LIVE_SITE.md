# Putting this version on the live site (Railway + Netlify)

Nothing in this update has been applied to your live sites. Do these steps yourself, in this order.
The order matters: the new backend expects the farm columns in the database, so sign-in on the live
site fails if the backend is deployed before the database is updated.

1. **Back up the Railway database.** In Railway, open the MySQL service and take a backup or export
   (or run `mysqldump` against it) so you can roll back.

2. **Run the farm migration on the Railway database, once.** Connect to the Railway MySQL (Railway's
   "Connect" tab gives a `mysql` command, or use TablePlus / MySQL Workbench with the same details)
   and run the contents of `ffms-backend/db/farm_access_migration.sql`.
   - It adds a farm to every person, customer and supplier, and fills it in from what already exists
     (owners get the farm they own, staff get their employee record's farm, and if there is only one
     farm everyone goes on it).
   - The last query lists anyone still without a farm. Note them for step 5.
   - Run it only once. A second run stops with "Duplicate column name", which is harmless.

   **Currency update:** also run `ffms-backend/db/currency_migration.sql` once, before deploying the
   version with the Currency box. If the farm migration is already on the live database, run only this
   one. It adds a country and currency to every farm; farms without one are shown in US dollars until
   someone picks their country on the Farms page. If the Railway database isn't called `ffms_db`,
   delete the `USE ffms_db;` line before running it (or change it to the Railway database's name).

3. **Make yourself an administrator** (only admins see all farms and can switch between them).
   In the same SQL session:
   ```sql
   UPDATE users SET role_id = (SELECT role_id FROM roles WHERE role_name = 'admin')
   WHERE email = 'your@email.com';
   ```

4. **Deploy the backend, then the website.** Push `ffms-backend` so Railway redeploys it (Railway runs
   `composer install`, which now also installs the Claude library), then push `ffms-frontend` so
   Netlify redeploys. Sign out and back in afterwards.

5. **Put people on their farms.** As an administrator, open Administration → Team & Roles and pick a
   farm for anyone listed in step 2. Customers or suppliers that the migration could not place
   (only possible with more than one farm) are visible to administrators; edit them and pick a farm.

6. **Optional: switch Claude on for the farm assistant.** In Railway → backend service → Variables,
   add `ANTHROPIC_API_KEY` with a key from https://console.anthropic.com. Optionally add
   `AI_CHAT_HOURLY_LIMIT` (default 40 questions per person per hour). Without a key the assistant
   still works using the built-in farm knowledge.
