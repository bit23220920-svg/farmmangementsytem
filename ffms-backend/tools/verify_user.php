<?php
/**
 * Marks an account's email as verified, for local development where no
 * verification email is sent. Run from the ffms-backend folder:
 *
 *     php tools/verify_user.php you@example.com
 *
 * Command line only; the web server refuses to serve this folder.
 */
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
if (function_exists('sapi_windows_cp_set')) { @sapi_windows_cp_set(65001); }
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../src/Response.php';
require_once __DIR__ . '/../src/Database.php';

$email = strtolower(trim($argv[1] ?? ''));
if (!$email) { fwrite(STDERR, "Usage: php tools/verify_user.php you@example.com\n"); exit(1); }

$pdo = Database::connection();
$stmt = $pdo->prepare('UPDATE users SET email_verified_at = COALESCE(email_verified_at, NOW()), status = \'active\' WHERE email = :email');
$stmt->execute(['email' => $email]);
if ($stmt->rowCount() === 0) {
    $exists = $pdo->prepare('SELECT email_verified_at FROM users WHERE email = :email');
    $exists->execute(['email' => $email]);
    $row = $exists->fetch();
    if (!$row) {
        $all = $pdo->query('SELECT email FROM users ORDER BY user_id')->fetchAll(PDO::FETCH_COLUMN);
        fwrite(STDERR, "No account with email {$email}.\nAccounts in the database: " . ($all ? implode(', ', $all) : '(none - sign up in the app first)') . "\n");
        exit(1);
    }
}
echo "{$email} is verified and active. You can sign in now.\n";
