<?php
require_once __DIR__ . '/bootstrap.php';
require_once __DIR__ . '/../src/FarmScope.php';

$currentUser = Auth::requireUser();
$pdo = Database::connection();
$method = $_SERVER['REQUEST_METHOD'];
$isAdmin = FarmScope::isAdmin($currentUser);
$myFarm = FarmScope::userFarm($currentUser);
$myId = (int) $currentUser['user_id'];

$select = 'SELECT u.user_id AS id, u.first_name AS firstName, u.last_name AS lastName,
                  u.email, u.phone, u.status, u.email_verified_at AS emailVerifiedAt,
                  u.created_at AS createdAt, r.role_name AS role,
                  u.farm_id AS farmId, f.farm_name AS farmName
           FROM users u
           JOIN roles r ON r.role_id = u.role_id
           LEFT JOIN farms f ON f.farm_id = u.farm_id';

if ($method === 'GET') {
    if ($isAdmin) {
        $stmt = $pdo->query("{$select} ORDER BY u.created_at DESC");
    } else {
        // Your own farm's team. Owners also see accounts that are not on any
        // farm yet (never administrators), so they can bring new staff in.
        $unassigned = $currentUser['role_name'] === 'owner' ? " OR (u.farm_id IS NULL AND r.role_name <> 'admin')" : '';
        $stmt = $pdo->prepare("{$select} WHERE u.user_id = :me OR (u.farm_id = :farm AND u.farm_id IS NOT NULL){$unassigned} ORDER BY u.created_at DESC");
        $stmt->execute(['me' => $myId, 'farm' => $myFarm ?? 0]);
    }
    $rows = array_map(function ($r) {
        $r['id'] = (int) $r['id'];
        $r['farmId'] = $r['farmId'] !== null ? (int) $r['farmId'] : null;
        return $r;
    }, $stmt->fetchAll());
    Response::ok($rows);
}

if ($method === 'PUT') {
    // Only admins/owners may change someone else's role, status or farm.
    Auth::requireRole(['admin', 'owner']);

    $id = isset($_GET['id']) ? (int) $_GET['id'] : null;
    if (!$id) Response::error('Missing id.');
    if ($id === $myId) {
        Response::error("You can't change your own role, status or farm here.");
    }

    $targetStmt = $pdo->prepare('SELECT u.user_id, u.farm_id, r.role_name FROM users u JOIN roles r ON r.role_id = u.role_id WHERE u.user_id = :id');
    $targetStmt->execute(['id' => $id]);
    $target = $targetStmt->fetch();
    if (!$target) Response::error('Not found.', 404);
    $targetFarm = $target['farm_id'] !== null ? (int) $target['farm_id'] : null;

    if (!$isAdmin) {
        if ($myFarm === null) Response::error('Add your farm first, then you can manage its team.', 403);
        if ($target['role_name'] === 'admin') Response::error('Only an administrator can change an administrator.', 403);
        if ($targetFarm !== null && $targetFarm !== $myFarm) Response::error('Not found.', 404);
    }

    $body = ffms_body();
    $updates = [];
    $params = ['id' => $id];

    if (isset($body['role'])) {
        if ($body['role'] === 'admin' && !$isAdmin) Response::error('Only an administrator can make someone an administrator.', 403);
        $roleStmt = $pdo->prepare('SELECT role_id FROM roles WHERE role_name = :name LIMIT 1');
        $roleStmt->execute(['name' => $body['role']]);
        $role = $roleStmt->fetch();
        if (!$role) Response::error('Unknown role.');
        $updates[] = 'role_id = :role_id';
        $params['role_id'] = $role['role_id'];
    }
    if (isset($body['status']) && in_array($body['status'], ['active', 'inactive', 'suspended'], true)) {
        $updates[] = 'status = :status';
        $params['status'] = $body['status'];
    }
    if (array_key_exists('farmId', $body)) {
        $farmId = ($body['farmId'] === null || $body['farmId'] === '') ? null : (int) $body['farmId'];
        if (!$isAdmin && $farmId !== null && $farmId !== $myFarm) {
            Response::error('You can only add people to your own farm.', 403);
        }
        if ($farmId !== null) {
            $chk = $pdo->prepare('SELECT 1 FROM farms WHERE farm_id = :f');
            $chk->execute(['f' => $farmId]);
            if (!$chk->fetch()) Response::error('That farm does not exist.');
        }
        $updates[] = 'farm_id = :farm_id';
        $params['farm_id'] = $farmId;
        // Moving someone to another farm signs them out everywhere, so an
        // old session can't keep showing the previous farm's data.
        if ($farmId !== $targetFarm) {
            $pdo->prepare('DELETE FROM auth_tokens WHERE user_id = :id')->execute(['id' => $id]);
        }
    }
    if (empty($updates)) Response::error('Nothing to update.');

    $updates[] = 'updated_at = NOW()';
    $sql = 'UPDATE users SET ' . implode(', ', $updates) . ' WHERE user_id = :id';
    $pdo->prepare($sql)->execute($params);

    AuditLogger::log($myId, 'staff changed', 'team', $id);
    Response::ok(['message' => 'Updated.']);
}

Response::error('Method not allowed.', 405);
