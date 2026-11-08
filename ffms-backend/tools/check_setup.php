<?php
/**
 * Local setup checker — run from the ffms-backend folder:
 *
 *     php tools/check_setup.php
 *
 * Checks PHP extensions, Composer packages, the .env values, the database
 * connection, the tables and roles, and lists the accounts with their
 * verification status, so you can see exactly why signing in fails.
 * Command line only; the web server refuses to serve this folder.
 */
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
// Show the ✓ / ✗ marks properly in the Windows Command Prompt.
if (function_exists('sapi_windows_cp_set')) { @sapi_windows_cp_set(65001); }
$win = PHP_OS_FAMILY === 'Windows';

require_once __DIR__ . '/../config/config.php';
$c = ffms_config();
$ok = fn($m) => print("  \u{2713} $m\n");
$bad = function ($m, $fix = '') { print("  \u{2717} $m\n" . ($fix ? "      \u{2192} $fix\n" : '')); };
$problems = 0;

echo "\nJohn Dhiri Intelligent Farm System - local setup check\n\n";

echo "PHP\n";
version_compare(PHP_VERSION, '8.1', '>=') ? $ok('PHP ' . PHP_VERSION) : ($bad('PHP ' . PHP_VERSION . ' is too old', ($win ? 'Use XAMPP 8.1 or 8.2 (C:\\xampp\\php\\php.exe)' : 'Use PHP 8.1 or newer (MAMP: /Applications/MAMP/bin/php/php8.x.x/bin/php)')) || $problems++);
foreach (['pdo_mysql', 'mbstring', 'curl'] as $ext) {
    extension_loaded($ext) ? $ok("extension $ext") : ($bad("extension $ext missing", $win ? "Open C:\\xampp\\php\\php.ini, remove the ; in front of extension=$ext, save, and open a new terminal" : 'Use MAMP\'s PHP, which includes it') || $problems++);
}
if ($win && !extension_loaded('zip')) {
    $bad('extension zip is off - composer install may fail', 'Open C:\\xampp\\php\\php.ini, remove the ; in front of extension=zip, save, and open a new terminal');
}
is_file(__DIR__ . '/../vendor/autoload.php') ? $ok('Composer packages installed (vendor/)') : ($bad('vendor/ folder missing - sign-up will crash', 'Run: composer install') || $problems++);
if (is_file(__DIR__ . '/../vendor/autoload.php') && !is_file(__DIR__ . '/../vendor/anthropic-ai/sdk/composer.json')) {
    $bad('Claude SDK not installed yet (only needed for the farm assistant)', 'Run: composer install');
}

echo "\n.env\n";
is_file(__DIR__ . '/../.env') ? $ok('.env found') : ($bad('.env not found', $win ? 'Run: copy .env.local-xampp .env' : 'Run: cp .env.local-mamp .env') || $problems++);
$db = $c['db'];
echo "  DB: {$db['user']}@{$db['host']}:{$db['port']} / {$db['name']}" . (getenv('DB_SOCKET') ? " (socket " . getenv('DB_SOCKET') . ")" : '') . "\n";
echo "  ALLOWED_ORIGINS: " . implode(', ', $c['app']['allowed_origins']) . "\n";
if (!in_array('http://localhost:5500', $c['app']['allowed_origins'], true)) {
    $bad('http://localhost:5500 is not in ALLOWED_ORIGINS - the browser will block every request', 'Set ALLOWED_ORIGINS=http://localhost:5500,http://127.0.0.1:5500'); $problems++;
}

echo "\nDatabase\n";
try {
    $socket = getenv('DB_SOCKET');
    $dsn = $socket
        ? "mysql:unix_socket={$socket};dbname={$db['name']};charset=utf8mb4"
        : "mysql:host={$db['host']};port={$db['port']};dbname={$db['name']};charset=utf8mb4";
    $pdo = new PDO($dsn, $db['user'], $db['pass'], [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
    $ok('connected');
} catch (PDOException $e) {
    $bad('cannot connect: ' . $e->getMessage(),
        str_contains($e->getMessage(), 'Unknown database') ? 'Import db/ffms_schema.sql first (it creates ffms_db)'
        : ($win
            ? 'Check that MySQL shows green/Running in the XAMPP Control Panel, and that .env has DB_PORT=3306, DB_USER=root and an empty DB_PASS= (XAMPP\'s default)'
            : 'Check that MySQL is running in MAMP and that DB_PORT matches the port on MAMP\'s start page (usually 8889). On a Mac you can also set DB_SOCKET=/Applications/MAMP/tmp/mysql/mysql.sock'));
    echo "\n$problems other problem(s) found. Fix the database connection first.\n\n";
    exit(1);
}
$tables = $pdo->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN);
$schema = require __DIR__ . '/../src/Schema.php';
$missing = array_diff(array_merge(array_keys($schema), ['users', 'roles', 'auth_tokens', 'email_verifications', 'password_resets']), $tables);
$missing ? ($bad('missing tables: ' . implode(', ', $missing), 'Import ffms_schema.sql, then auth_migration.sql (in that order)') || $problems++) : $ok(count($tables) . ' tables present');
$cols = $pdo->query("SHOW COLUMNS FROM users LIKE 'email_verified_at'")->fetchAll();
$cols ? $ok('users.email_verified_at present') : ($bad('users.email_verified_at missing', 'Import db/auth_migration.sql') || $problems++);
$roles = $pdo->query('SELECT role_name FROM roles')->fetchAll(PDO::FETCH_COLUMN);
count($roles) >= 6 ? $ok('roles seeded: ' . implode(', ', $roles)) : ($bad('roles not seeded (' . count($roles) . ' found) - sign-up says "That role is not recognised"', 'Import db/seed_roles.sql') || $problems++);
$farmCol = $pdo->query("SHOW COLUMNS FROM users LIKE 'farm_id'")->fetchAll();
$farmCol ? $ok('farm access columns present (users.farm_id)') : ($bad('users.farm_id missing - signing in will fail', 'Import db/farm_access_migration.sql') || $problems++);
$curCol = $pdo->query("SHOW COLUMNS FROM farms LIKE 'currency_code'")->fetchAll();
$curCol ? $ok('farm currency columns present (farms.currency_code)') : ($bad('farms.currency_code missing - saving a farm will fail', 'Run db/currency_migration.sql once') || $problems++);

echo "\nAccounts\n";
if ($cols) {
    $farmSel = $farmCol ? 'f.farm_name' : 'NULL';
    $farmJoin = $farmCol ? 'LEFT JOIN farms f ON f.farm_id = u.farm_id' : '';
    $users = $pdo->query("SELECT u.email, u.status, u.email_verified_at, r.role_name, {$farmSel} AS farm_name FROM users u LEFT JOIN roles r ON r.role_id = u.role_id {$farmJoin} ORDER BY u.user_id")->fetchAll();
    if (!$users) echo "  (none yet - sign up in the app first)\n";
    foreach ($users as $u) {
        $v = $u['email_verified_at'] ? 'verified' : 'NOT VERIFIED';
        $farm = $u['role_name'] === 'admin' ? 'all farms' : ($u['farm_name'] ?? 'no farm yet');
        printf("  %-34s %-11s %-8s %-13s %s\n", $u['email'], $u['role_name'], $u['status'], $v, $farm);
        if (!$u['email_verified_at']) { echo "      \u{2192} php tools/verify_user.php {$u['email']}\n"; }
    }
    if ($users && !in_array('admin', array_column($users, 'role_name'), true)) {
        echo "  No administrator yet. Only admins can see and switch between every farm.\n";
        echo "      \u{2192} php tools/make_admin.php you@example.com\n";
    }
}

echo "\nFarm assistant\n";
trim((string) $c['ai']['anthropic_api_key']) !== ''
    ? $ok('ANTHROPIC_API_KEY set - the assistant answers with Claude')
    : print("  - ANTHROPIC_API_KEY not set - the assistant uses its built-in farm knowledge (that's fine)\n");
if ($win && trim((string) $c['ai']['anthropic_api_key']) !== '' && !ini_get('curl.cainfo')) {
    $bad('curl.cainfo is not set, so PHP cannot check Claude\'s HTTPS certificate on Windows',
        'In C:\\xampp\\php\\php.ini set curl.cainfo="C:\\xampp\\apache\\bin\\curl-ca-bundle.crt" (and the same for openssl.cafile), then restart the backend');
}

echo "\n" . ($problems ? "$problems problem(s) found - fix the \u{2717} items above.\n\n" : "All good. Start the API with: php -S localhost:8000 router.php\n\n");
exit($problems ? 1 : 0);
