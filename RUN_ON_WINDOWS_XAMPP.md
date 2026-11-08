# Run John Dhiri Intelligent Farm System on Windows with XAMPP

Everything runs on this computer: MySQL from XAMPP, the PHP backend, and the website.
You do not need Node.js, because PHP serves the website too. Nothing here touches the live Railway or Netlify sites.

Use **Command Prompt** for every command below, not PowerShell. To open one in a folder, open the folder in File Explorer, click the address bar, type `cmd` and press Enter.

## Once only: set up the computer

1. **XAMPP with PHP 8.1 or 8.2.** The current download from apachefriends.org (8.2.x) is right. If yours is older, install the 8.2 version.

2. **Turn on PHP's zip extension** (Composer needs it). In the XAMPP Control Panel, click **Config** on the Apache row, then **PHP (php.ini)**. In Notepad, press Ctrl+F and search for `extension=zip`. If the line starts with `;`, delete the `;` and save. It's fine if it's already on.

3. **Install Composer** from https://getcomposer.org/download/ using **Composer-Setup.exe**. When it asks for PHP, choose `C:\xampp\php\php.exe` and let it add PHP to your PATH. Close any open Command Prompt windows afterwards, because only new ones see the change.

   Check it in a new Command Prompt:
   ```
   php -v
   composer -V
   ```

4. **Unzip the project** with right-click, **Extract All**, for example to `C:\farm`, so you have `C:\farm\ffms-backend` and `C:\farm\ffms-frontend`. Don't run anything from inside the zip window.

## Once only: database and backend

5. **Start XAMPP.** In the XAMPP Control Panel, click **Start** for **Apache** and **MySQL** (Apache is only needed for phpMyAdmin).

6. **Create the database.** Open http://localhost/phpmyadmin, click **Import**, and import these files from `C:\farm\ffms-backend\db\`, one at a time, in this order:
   1. `ffms_schema.sql`
   2. `auth_migration.sql`
   3. `seed_roles.sql`
   4. `farm_access_migration.sql`
   5. `currency_migration.sql` (gives each farm a country and currency)

   Import each one only once. If phpMyAdmin gives you trouble, the "Importing without phpMyAdmin" section below does the same thing from Command Prompt.

   **Optional sample data:** import `sample_data_three_farms.sql` from the same folder as a sixth file. It adds John Sichula (`test@gmail.com`, password `Farm@2026`) as an administrator with Green Valley Farm, North Ridge and Valley Heights, 15 staff accounts, and 15 or more records in every module. You can import it again at any time to reset those three farms to the sample state.

7. **Install the backend's packages and settings.** Open Command Prompt in `C:\farm\ffms-backend` and run:
   ```
   composer install
   copy .env.local-xampp .env
   php tools\check_setup.php
   ```
   `.env.local-xampp` already has XAMPP's defaults (port 3306, user `root`, no password). If you gave MySQL's root user a password, put it after `DB_PASS=` in `.env`. Fix anything `check_setup` marks with ✗; it says how.

## Every time: start it

8. **XAMPP Control Panel:** make sure **MySQL** is running.

9. **Backend.** Open Command Prompt in `C:\farm\ffms-backend` and leave this window open:
   ```
   php -S localhost:8000 router.php
   ```
   If Windows Firewall asks about PHP, click **Allow**. Cancel also works, because everything stays on this computer.
   http://localhost:8000/ should show `"status":"ok"`.

10. **Website.** Open a **second** Command Prompt in `C:\farm\ffms-frontend` and leave it open too:
    ```
    php -S localhost:5500
    ```
    (If you have Node.js installed, `npm run dev` does the same job.)

11. Open **http://localhost:5500/login.html**.

## Once only: your account

12. Sign up and choose **Administrator** as the role. The first administrator can sign up directly. No email is sent locally, so open a **third** Command Prompt in `C:\farm\ffms-backend` and run:
    ```
    php tools\verify_user.php your@email.com
    ```
    Then sign in.

    Accounts and records from the Mac or the live site are not on this computer. Sign up again here.
    To make an existing account an administrator: `php tools\make_admin.php your@email.com`.

## Farm assistant with Claude (optional)

The chat on the AI page works without any setup. To have Claude answer, put a key from https://console.anthropic.com after `ANTHROPIC_API_KEY=` in `.env` and restart the backend (step 9). On XAMPP you also need to tell PHP where its security certificates are. In `php.ini` (step 2), set both of these lines (remove any `;` in front), save, and restart the backend:
```
curl.cainfo="C:\xampp\apache\bin\curl-ca-bundle.crt"
openssl.cafile="C:\xampp\apache\bin\curl-ca-bundle.crt"
```
`php tools\check_setup.php` warns you if this is missing.

## If something goes wrong

| What you see | Fix |
|---|---|
| `'php' is not recognized…` or `'composer' is not recognized…` | Open a **new** Command Prompt after installing Composer. Or type `C:\xampp\php\php.exe` instead of `php`. |
| Composer says "The zip extension and unzip/7z commands are both missing" | Step 2, then open a new Command Prompt and run `composer install` again. |
| Composer says your PHP version doesn't satisfy a requirement | XAMPP's PHP is older than 8.1. Install XAMPP 8.2. |
| MySQL won't start in XAMPP (port 3306 in use) | Another MySQL is already running. Open `services.msc`, stop the "MySQL" or "MySQL80" service, and start MySQL in XAMPP again. |
| Apache won't start (port 80 in use) | You only need Apache for phpMyAdmin. Import from Command Prompt instead (below). |
| Sign-in says "Could not reach the server at http://localhost:8000/api…" | The backend window (step 9) was closed or stopped. Start it again. Restart it after any `.env` change. |
| "Database connection failed. Check your .env settings." | MySQL isn't running in XAMPP, or root has a password that isn't in `DB_PASS=`. |
| "Something went wrong on the server." when signing in | `farm_access_migration.sql` wasn't imported. Import it (step 6). |
| "Please verify your email before signing in…" | `php tools\verify_user.php your@email.com` |
| "Incorrect email or password." | That account doesn't exist on this computer. Sign up here. |
| "Your account is not linked to a farm yet…" | An administrator or that farm's owner adds the account in Administration, Team & Roles. |
| The page looks old or half-loaded | Press Ctrl+F5. |
| "Something went wrong on the server." when saving a farm | `currency_migration.sql` wasn't run. Run it once (step 6). |
| The assistant says Claude couldn't be reached | Set the certificate lines in the "Farm assistant with Claude" section. |

## Importing without phpMyAdmin

In Command Prompt (not PowerShell), in `C:\farm\ffms-backend`:
```
C:\xampp\mysql\bin\mysql -u root < db\ffms_schema.sql
C:\xampp\mysql\bin\mysql -u root < db\auth_migration.sql
C:\xampp\mysql\bin\mysql -u root < db\seed_roles.sql
C:\xampp\mysql\bin\mysql -u root < db\farm_access_migration.sql
C:\xampp\mysql\bin\mysql -u root < db\currency_migration.sql
C:\xampp\mysql\bin\mysql -u root < db\sample_data_three_farms.sql
```
The last line is the optional sample data.
If root has a password, add `-p` after `root` and type the password when asked.
