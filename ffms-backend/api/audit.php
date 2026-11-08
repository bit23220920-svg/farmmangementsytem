<?php
require_once __DIR__ . '/bootstrap.php';

require_once __DIR__ . '/../src/FarmScope.php';
$user = Auth::requireRole(['admin', 'owner']);

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed.', 405);
}

$pdo = Database::connection();
$limit = min((int) ($_GET['limit'] ?? 200), 1000);

// Admins see everything; an owner sees what people on their own farm did.
$where = '';
$params = [];
if (!FarmScope::isAdmin($user)) {
    $where = 'WHERE u.farm_id = :farm';
    $params['farm'] = FarmScope::userFarm($user) ?? 0;
}
$stmt = $pdo->prepare(
    "SELECT al.log_id AS id, al.action, al.table_affected AS tableAffected,
            al.record_id AS recordId, al.ip_address AS ipAddress, al.created_at AS createdAt,
            COALESCE(CONCAT(u.first_name, ' ', u.last_name), u.email, 'Unknown') AS actor
     FROM audit_logs al
     LEFT JOIN users u ON u.user_id = al.user_id
     {$where}
     ORDER BY al.created_at DESC
     LIMIT {$limit}"
);
$stmt->execute($params);
Response::ok($stmt->fetchAll());
