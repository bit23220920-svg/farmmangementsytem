<?php
/**
 * A single shared PDO connection for the request, configured for safety:
 * exceptions on error, real prepared statements (not emulated), and
 * associative fetches by default.
 */
class Database
{
    private static ?PDO $instance = null;

    public static function connection(): PDO
    {
        if (self::$instance !== null) {
            return self::$instance;
        }

        require_once __DIR__ . '/../config/config.php';

        $config = ffms_config();
        $db = $config['db'];

        // Optional DB_SOCKET (e.g. MAMP on a Mac: /Applications/MAMP/tmp/mysql/mysql.sock)
        // connects through the MySQL socket file instead of host + port.
        $socket = ffms_env('DB_SOCKET', '');
        $dsn = $socket
            ? sprintf('mysql:unix_socket=%s;dbname=%s;charset=utf8mb4', $socket, $db['name'])
            : sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $db['host'], $db['port'], $db['name']);

        try {
            self::$instance = new PDO($dsn, $db['user'], $db['pass'], [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]);
        } catch (PDOException $e) {
            Response::error('Database connection failed. Check your .env settings.', 500);
        }

        return self::$instance;
    }
}
