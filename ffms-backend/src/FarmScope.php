<?php
/**
 * Farm-level access control.
 *
 * Every record belongs to exactly one farm, either directly (a farm_id
 * column) or through its parent (a harvest belongs to a planting, which
 * belongs to a field, which belongs to a farm). This class knows that
 * chain for every table, so the API can:
 *
 *   - list only the rows of the signed-in user's farm,
 *   - refuse to read, change or delete a row from another farm,
 *   - refuse to link a new row to another farm's records.
 *
 * Administrators are not tied to a farm: they see every farm, and may
 * narrow a list to one farm with ?farm=<id>. Everyone else is tied to the
 * farm in users.farm_id and only ever sees that farm's data.
 */
class FarmScope
{
    /** How each table reaches its farm: 'self', 'direct', 'global', 'user', or [fkColumn, parentTable]. */
    public const LINKS = [
        'farms' => 'self',
        'fields' => 'direct',
        'water_sources' => 'direct',
        'livestock' => 'direct',
        'livestock_production_logs' => 'direct',
        'livestock_feed_logs' => 'direct',
        'inventory_items' => 'direct',
        'purchase_orders' => 'direct',
        'machinery' => 'direct',
        'employees' => 'direct',
        'task_allocations' => 'direct',
        'weather_logs' => 'direct',
        'warehouses' => 'direct',
        'sales_orders' => 'direct',
        'financial_transactions' => 'direct',
        'customers' => 'direct',
        'suppliers' => 'direct',
        'crop_plantings' => ['field_id', 'fields'],
        'crop_growth_logs' => ['planting_id', 'crop_plantings'],
        'irrigation_systems' => ['field_id', 'fields'],
        'irrigation_schedules' => ['system_id', 'irrigation_systems'],
        'livestock_health_records' => ['animal_id', 'livestock'],
        'inventory_batches' => ['item_id', 'inventory_items'],
        'inventory_transactions' => ['batch_id', 'inventory_batches'],
        'machinery_maintenance' => ['machinery_id', 'machinery'],
        'machinery_usage' => ['machinery_id', 'machinery'],
        'labor_assignments' => ['task_id', 'task_allocations'],
        'scouting_records' => ['field_id', 'fields'],
        'chemical_applications' => ['planting_id', 'crop_plantings'],
        'harvests' => ['planting_id', 'crop_plantings'],
        'produce_storage' => ['warehouse_id', 'warehouses'],
        'sales_order_items' => ['order_id', 'sales_orders'],
        // Shared reference catalogues, the same for every farm.
        'crop_varieties' => 'global',
        'pest_disease_catalog' => 'global',
        // Belongs to a person, not a farm.
        'notifications' => 'user',
    ];

    public static function isAdmin(array $user): bool
    {
        return ($user['role_name'] ?? '') === 'admin';
    }

    /** The farm a non-admin is tied to, or null if not assigned yet. */
    public static function userFarm(array $user): ?int
    {
        return isset($user['farm_id']) && $user['farm_id'] !== null ? (int) $user['farm_id'] : null;
    }

    public static function link(string $entity)
    {
        return self::LINKS[$entity] ?? 'global';
    }

    /**
     * SQL expression that evaluates to the farm_id of the row aliased as
     * $alias in table $entity. Built from LINKS, nesting a sub-select per
     * level, with only whitelisted table/column names.
     */
    public static function farmExpr(string $entity, string $alias, int $depth = 0): ?string
    {
        $schema = self::schema();
        $link = self::link($entity);
        if ($link === 'self') return "`{$alias}`.`farm_id`";
        if ($link === 'direct') return "`{$alias}`.`farm_id`";
        if (!is_array($link)) return null;
        [$col, $parent] = $link;
        $p = 'p' . $depth;
        $parentPk = $schema[$parent]['pk'];
        $inner = self::farmExpr($parent, $p, $depth + 1);
        return "(SELECT {$inner} FROM `{$parent}` `{$p}` WHERE `{$p}`.`{$parentPk}` = `{$alias}`.`{$col}`)";
    }

    /** The farm a stored record belongs to (null if it can't be resolved). */
    public static function farmOfRecord(PDO $pdo, string $entity, $id): ?int
    {
        if ($id === null || $id === '') return null;
        $schema = self::schema();
        if (!isset($schema[$entity])) return null;
        $expr = self::farmExpr($entity, 't');
        if ($expr === null) return null;
        $pk = $schema[$entity]['pk'];
        $stmt = $pdo->prepare("SELECT {$expr} AS farm FROM `{$entity}` `t` WHERE `t`.`{$pk}` = :id LIMIT 1");
        $stmt->execute(['id' => $id]);
        $v = $stmt->fetchColumn();
        return ($v === false || $v === null) ? null : (int) $v;
    }

    /**
     * The farm a new/updated row would belong to, from its values
     * ($row = submitted columns merged over the stored row for updates).
     */
    public static function farmOfValues(PDO $pdo, string $entity, array $row): ?int
    {
        $link = self::link($entity);
        if ($link === 'self') return isset($row['farm_id']) ? (int) $row['farm_id'] : null;
        if ($link === 'direct') return (isset($row['farm_id']) && $row['farm_id'] !== '' && $row['farm_id'] !== null) ? (int) $row['farm_id'] : null;
        if (!is_array($link)) return null;
        [$col, $parent] = $link;
        return self::farmOfRecord($pdo, $parent, $row[$col] ?? null);
    }

    /**
     * Every other farm-owned record this row points at (e.g. a chemical
     * application's batch and scouting record) must be on the same farm.
     * Returns an error message, or null when everything matches.
     */
    public static function checkReferences(PDO $pdo, string $entity, array $row, ?int $farm): ?string
    {
        $schema = self::schema();
        foreach ($schema[$entity]['foreign_keys'] as $col => $fk) {
            $target = $fk['table'];
            if (!array_key_exists($col, $row) || $row[$col] === null || $row[$col] === '') continue;
            if (!isset(self::LINKS[$target])) continue;              // users, roles, ...
            $tl = self::LINKS[$target];
            if ($tl === 'global' || $tl === 'user') continue;
            $refFarm = self::farmOfRecord($pdo, $target, $row[$col]);
            if ($refFarm === null || $farm === null || $refFarm !== $farm) {
                return 'That record links to something from a different farm, or something that does not exist.';
            }
        }
        return null;
    }

    private static function schema(): array
    {
        static $schema = null;
        if ($schema === null) $schema = require __DIR__ . '/Schema.php';
        return $schema;
    }
}
