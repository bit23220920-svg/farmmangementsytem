<?php
/**
 * Makes an existing account an administrator. Administrators are not tied
 * to one farm: they see every farm and can switch between them in the
 * top bar. Run from the ffms-backend folder:
 *
 *     php tools/make_admin.php you@example.com
 *
 * Command line only; the web server refuses to serve this folder.
 */
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
if (function_exists('sapi_windows_cp_set')) { @sapi_windows_cp_set(65001); }

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../src/Database.php';

$email = strtolower(trim($argv[1] ?? ''));
if ($email === '') {
    fwrite(STDERR, "Usage: php tools/make_admin.php you@example.com\n");
    exit(1);
}

$pdo = Database::connection();
$role = $pdo->query("SELECT role_id FROM roles WHERE role_name = 'admin'")->fetchColumn();
if (!$role) {
    fwrite(STDERR, "The admin role is missing. Import db/seed_roles.sql first.\n");
    exit(1);
}
$stmt = $pdo->prepare('UPDATE users SET role_id = :role WHERE LOWER(email) = :email');
$stmt->execute(['role' => $role, 'email' => $email]);
if (!$stmt->rowCount()) {
    $exists = $pdo->prepare('SELECT 1 FROM users WHERE LOWER(email) = :email');
    $exists->execute(['email' => $email]);
    if (!$exists->fetchColumn()) {
        fwrite(STDERR, "No account with the email {$email}. Sign up in the app first.\n");
        exit(1);
    }
    echo "{$email} is already an administrator.\n";
    exit(0);
}
// Sign them out everywhere so the next sign-in picks up the new role.
$pdo->prepare('DELETE t FROM auth_tokens t JOIN users u ON u.user_id = t.user_id WHERE LOWER(u.email) = :email')
    ->execute(['email' => $email]);
echo "{$email} is now an administrator. Sign in again to see every farm.\n";
