<?php
require_once __DIR__ . '/bootstrap.php';

$schema = require __DIR__ . '/../src/Schema.php';

$entity = $_GET['entity'] ?? '';
if (!isset($schema[$entity])) {
    Response::error('Unknown entity.', 404);
}
$def = $schema[$entity];
$pk = $def['pk'];

// Server-side role enforcement — the real security boundary. The front
// end's sidebar filtering is just UX; this is what actually protects data.
//
// Reads (GET) are allowed for any logged-in user, regardless of role —
// this is what lets e.g. a Worker viewing "Machinery Usage" see which
// Field it happened in, even though "Fields" itself is an Owner/Manager/
// Agronomist-only module. Writes (POST/PUT/DELETE) still require the
// entity's own permitted roles — that's where the real protection is.
$method = $_SERVER['REQUEST_METHOD'];
if ($method === 'GET') {
    $user = Auth::requireUser();
} else {
    $user = Auth::requireRole($def['roles']);
}
$userId = (int) $user['user_id'];

$pdo = Database::connection();
$id = isset($_GET['id']) ? (int) $_GET['id'] : null;

// ---- Farm scoping -------------------------------------------------------
// Admins see every farm (optionally narrowed with ?farm=<id>). Everyone
// else only ever sees and changes the farm they are assigned to.
require_once __DIR__ . '/../src/FarmScope.php';
$isAdmin = FarmScope::isAdmin($user);
$myFarm = FarmScope::userFarm($user);
$link = FarmScope::link($entity);
$scoped = !in_array($link, ['global', 'user'], true);
$adminFarm = ($isAdmin && isset($_GET['farm']) && ctype_digit((string) $_GET['farm'])) ? (int) $_GET['farm'] : null;
$noFarmMsg = 'Your account is not linked to a farm yet. Ask your farm owner or an administrator to add you in Team & Roles.';

/** Halts unless the signed-in user may touch a record on $farm. */
$assertFarm = function (?int $farm) use ($isAdmin, $myFarm, $noFarmMsg) {
    if ($isAdmin) return;
    if ($myFarm === null) Response::error($noFarmMsg, 403);
    if ($farm === null || $farm !== $myFarm) Response::error('Not found.', 404);
};

/** WHERE clause + params limiting $entity rows (alias t) to what this user may see. */
$scopeWhere = function () use ($scoped, $link, $entity, $isAdmin, $myFarm, $adminFarm, $userId) {
    if ($link === 'user') return ['`t`.`user_id` = :__uid', ['__uid' => $userId]];
    if (!$scoped) return ['1=1', []];
    $expr = FarmScope::farmExpr($entity, 't');
    if ($isAdmin) {
        return $adminFarm !== null ? ["{$expr} = :__farm", ['__farm' => $adminFarm]] : ['1=1', []];
    }
    if ($myFarm === null) return ['1=0', []];
    return ["{$expr} = :__farm", ['__farm' => $myFarm]];
};

switch ($method) {
    case 'GET':
        [$where, $wp] = $scopeWhere();
        if ($id !== null) {
            $stmt = $pdo->prepare("SELECT `t`.*, `t`.`{$pk}` AS id FROM `{$entity}` `t` WHERE `t`.`{$pk}` = :id AND {$where} LIMIT 1");
            $stmt->execute(array_merge(['id' => $id], $wp));
            $row = $stmt->fetch();
            if (!$row) Response::error('Not found.', 404);
            Response::ok($row);
        }

        $limit = min((int) ($_GET['limit'] ?? 500), 1000);
        $stmt = $pdo->prepare("SELECT `t`.*, `t`.`{$pk}` AS id FROM `{$entity}` `t` WHERE {$where} ORDER BY `t`.`{$pk}` DESC LIMIT {$limit}");
        $stmt->execute($wp);
        Response::ok($stmt->fetchAll());
        break;

    case 'POST':
        $body = ffms_body();
        [$cols, $params] = ffms_filter_columns($body, $def['columns']);

        // Farm ownership can never be spoofed by the client — always the
        // authenticated user who's creating it.
        if ($entity === 'farms') {
            if (!$isAdmin && $myFarm !== null) {
                Response::error('You already have a farm. Only an administrator can add another farm.', 403);
            }
            $cols = array_values(array_diff($cols, ['owner_id']));
            unset($params['owner_id']);
            $cols[] = 'owner_id';
            $params['owner_id'] = $userId;
        }
        // Scouting records need the person who scouted (NOT NULL in the
        // schema) but the form doesn't ask for it — default to the signed-in user.
        if ($entity === 'scouting_records' && !in_array('scout_id', $cols, true)) {
            $cols[] = 'scout_id';
            $params['scout_id'] = $userId;
        }
        if ($link === 'user') {
            $cols = array_values(array_diff($cols, ['user_id']));
            unset($params['user_id']);
            $cols[] = 'user_id';
            $params['user_id'] = $userId;
        }
        // A non-admin's records always land on their own farm.
        if ($scoped && $link === 'direct' && !$isAdmin) {
            if ($myFarm === null) Response::error($noFarmMsg, 403);
            if (!in_array('farm_id', $cols, true)) $cols[] = 'farm_id';
            $params['farm_id'] = $myFarm;
        }
        if ($scoped && $entity !== 'farms') {
            $farm = FarmScope::farmOfValues($pdo, $entity, $params);
            if ($farm === null) Response::error('Choose which farm (or parent record) this belongs to.');
            $assertFarm($farm);
            $err = FarmScope::checkReferences($pdo, $entity, $params, $farm);
            if ($err) Response::error($err);
        }

        if (empty($cols)) Response::error('No valid fields supplied.');

        $columnList = implode(', ', array_map(fn($c) => "`{$c}`", $cols));
        $placeholderList = implode(', ', array_map(fn($c) => ":{$c}", $cols));
        $stmt = $pdo->prepare("INSERT INTO `{$entity}` ({$columnList}) VALUES ({$placeholderList})");

        try {
            $stmt->execute($params);
        } catch (PDOException $e) {
            Response::error(ffms_friendly_db_error($e), 400);
        }

        $newId = (int) $pdo->lastInsertId();
        // An owner's first farm becomes the farm their account belongs to.
        if ($entity === 'farms' && !$isAdmin && $myFarm === null) {
            $pdo->prepare('UPDATE users SET farm_id = :f WHERE user_id = :u')->execute(['f' => $newId, 'u' => $userId]);
        }
        AuditLogger::log($userId, 'create', $entity, $newId);

        $fetch = $pdo->prepare("SELECT *, `{$pk}` AS id FROM `{$entity}` WHERE `{$pk}` = :id LIMIT 1");
        $fetch->execute(['id' => $newId]);
        Response::ok($fetch->fetch(), 201);
        break;

    case 'PUT':
        if ($id === null) Response::error('Missing id.');
        $body = ffms_body();
        [$cols, $params] = ffms_filter_columns($body, $def['columns']);
        // Ownership columns can't be reassigned through the generic endpoint.
        $locked = $entity === 'farms' ? ['owner_id'] : ($link === 'user' ? ['user_id'] : []);
        if (!$isAdmin && $link === 'direct') $locked[] = 'farm_id';
        foreach ($locked as $lc) { $cols = array_values(array_diff($cols, [$lc])); unset($params[$lc]); }
        if (empty($cols)) Response::error('No valid fields supplied.');

        $existing = $pdo->prepare("SELECT * FROM `{$entity}` WHERE `{$pk}` = :id LIMIT 1");
        $existing->execute(['id' => $id]);
        $current = $existing->fetch();
        if (!$current) Response::error('Not found.', 404);
        if ($link === 'user' && (int) $current['user_id'] !== $userId) Response::error('Not found.', 404);
        if ($scoped) {
            $assertFarm(FarmScope::farmOfRecord($pdo, $entity, $id));
            $merged = array_merge($current, $params);
            $newFarm = $entity === 'farms' ? $id : FarmScope::farmOfValues($pdo, $entity, $merged);
            $assertFarm($newFarm);
            $err = FarmScope::checkReferences($pdo, $entity, $params, $newFarm);
            if ($err) Response::error($err);
        }

        $setList = implode(', ', array_map(fn($c) => "`{$c}` = :{$c}", $cols));
        $params['__id'] = $id;
        $stmt = $pdo->prepare("UPDATE `{$entity}` SET {$setList} WHERE `{$pk}` = :__id");

        try {
            $stmt->execute($params);
        } catch (PDOException $e) {
            Response::error(ffms_friendly_db_error($e), 400);
        }

        AuditLogger::log($userId, 'update', $entity, $id);

        $fetch = $pdo->prepare("SELECT *, `{$pk}` AS id FROM `{$entity}` WHERE `{$pk}` = :id LIMIT 1");
        $fetch->execute(['id' => $id]);
        $row = $fetch->fetch();
        if (!$row) Response::error('Not found.', 404);
        Response::ok($row);
        break;

    case 'DELETE':
        if ($id === null) Response::error('Missing id.');
        if ($scoped) {
            $exists = $pdo->prepare("SELECT 1 FROM `{$entity}` WHERE `{$pk}` = :id");
            $exists->execute(['id' => $id]);
            if (!$exists->fetch()) Response::error('Not found.', 404);
            $assertFarm(FarmScope::farmOfRecord($pdo, $entity, $id));
        }
        $extra = $link === 'user' ? ' AND `user_id` = :__uid' : '';
        $stmt = $pdo->prepare("DELETE FROM `{$entity}` WHERE `{$pk}` = :id{$extra}");
        try {
            $stmt->execute($link === 'user' ? ['id' => $id, '__uid' => $userId] : ['id' => $id]);
        } catch (PDOException $e) {
            Response::error(ffms_friendly_db_error($e), 400);
        }
        if ($stmt->rowCount() === 0) Response::error('Not found.', 404);

        AuditLogger::log($userId, 'delete', $entity, $id);
        Response::ok(['deleted' => true, 'id' => $id]);
        break;

    default:
        Response::error('Method not allowed.', 405);
}

/**
 * Keeps only keys present in the whitelist, so a request can never write
 * to a column that doesn't exist on this entity (or, worse, the primary
 * key / another table entirely).
 * @return array{0: string[], 1: array<string, mixed>}
 */
function ffms_filter_columns(array $body, array $whitelist): array
{
    $cols = [];
    $params = [];
    foreach ($whitelist as $col) {
        if (array_key_exists($col, $body)) {
            $value = $body[$col];
            $cols[] = $col;
            $params[$col] = $value === '' ? null : $value;
        }
    }
    return [$cols, $params];
}

function ffms_friendly_db_error(PDOException $e): string
{
    $msg = $e->getMessage();
    if (str_contains($msg, 'foreign key constraint fails')) {
        return 'That record is referenced by other data, or references something that doesn\'t exist.';
    }
    if (str_contains($msg, 'Duplicate entry')) {
        return 'That value already exists and must be unique.';
    }
    if (str_contains($msg, "doesn't have a default value") || str_contains($msg, 'cannot be null')) {
        return 'A required field is missing.';
    }
    return 'That request could not be saved.';
}
