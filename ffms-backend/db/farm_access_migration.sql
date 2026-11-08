-- ============================================================================
-- John Dhiri Intelligent Farm System — FARM ACCESS MIGRATION
-- Run this ONCE, after ffms_schema.sql, auth_migration.sql and
-- seed_roles.sql, and BEFORE deploying the backend code that uses it.
--
-- What it does:
--   * links every user account to one farm (users.farm_id)
--   * gives customers and suppliers a farm, so each farm keeps its own
--   * fills those links in for existing data where it can
-- After this, non-admin users only see their own farm's data.
-- Administrators see every farm and can switch between them.
-- ============================================================================

USE ffms_db;

ALTER TABLE users
  ADD COLUMN farm_id INT NULL AFTER role_id,
  ADD CONSTRAINT fk_users_farm FOREIGN KEY (farm_id) REFERENCES farms(farm_id) ON DELETE SET NULL;

ALTER TABLE customers
  ADD COLUMN farm_id INT NULL AFTER customer_id,
  ADD CONSTRAINT fk_customers_farm FOREIGN KEY (farm_id) REFERENCES farms(farm_id) ON DELETE CASCADE;

ALTER TABLE suppliers
  ADD COLUMN farm_id INT NULL AFTER supplier_id,
  ADD CONSTRAINT fk_suppliers_farm FOREIGN KEY (farm_id) REFERENCES farms(farm_id) ON DELETE CASCADE;

-- ---- Fill in links for existing data -------------------------------------

-- Farm owners belong to the (first) farm they own.
UPDATE users u
  JOIN (SELECT owner_id, MIN(farm_id) AS farm_id FROM farms GROUP BY owner_id) f ON f.owner_id = u.user_id
  JOIN roles r ON r.role_id = u.role_id
SET u.farm_id = f.farm_id
WHERE u.farm_id IS NULL AND r.role_name <> 'admin';

-- Staff who have an employee record belong to that employee's farm.
UPDATE users u
  JOIN (SELECT user_id, MIN(farm_id) AS farm_id FROM employees WHERE user_id IS NOT NULL GROUP BY user_id) e ON e.user_id = u.user_id
SET u.farm_id = e.farm_id
WHERE u.farm_id IS NULL;

-- If there is only one farm, everyone else joins it.
UPDATE users u
  JOIN roles r ON r.role_id = u.role_id
SET u.farm_id = (SELECT MIN(farm_id) FROM farms)
WHERE u.farm_id IS NULL AND r.role_name <> 'admin' AND (SELECT COUNT(*) FROM farms) = 1;

-- Customers belong to the farm that sold to them; suppliers to the farm that bought from them.
UPDATE customers c
SET c.farm_id = (SELECT MIN(so.farm_id) FROM sales_orders so WHERE so.customer_id = c.customer_id)
WHERE c.farm_id IS NULL;

UPDATE suppliers s
SET s.farm_id = (SELECT MIN(po.farm_id) FROM purchase_orders po WHERE po.supplier_id = s.supplier_id)
WHERE s.farm_id IS NULL;

UPDATE suppliers s
SET s.farm_id = (SELECT MIN(i.farm_id) FROM inventory_batches b JOIN inventory_items i ON i.item_id = b.item_id WHERE b.supplier_id = s.supplier_id)
WHERE s.farm_id IS NULL;

UPDATE customers SET farm_id = (SELECT MIN(farm_id) FROM farms) WHERE farm_id IS NULL AND (SELECT COUNT(*) FROM farms) = 1;
UPDATE suppliers SET farm_id = (SELECT MIN(farm_id) FROM farms) WHERE farm_id IS NULL AND (SELECT COUNT(*) FROM farms) = 1;

-- ---- Check the result ------------------------------------------------------
-- Accounts still without a farm (an administrator assigns them in Team & Roles):
SELECT u.user_id, u.email, r.role_name FROM users u JOIN roles r ON r.role_id = u.role_id
WHERE u.farm_id IS NULL AND r.role_name <> 'admin';

-- If you have no administrator yet, make your own account one:
--   UPDATE users SET role_id = (SELECT role_id FROM roles WHERE role_name = 'admin') WHERE email = 'you@example.com';
