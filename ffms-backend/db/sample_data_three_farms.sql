-- ============================================================================
-- John Dhiri Intelligent Farm System - sample data for three farms
--
--   Green Valley Farm  (16 Miles, Lusaka)
--   North Ridge        (Chipata)
--   Valley Heights     (Kafue)
--   Owner: John Sichula <test@gmail.com>
--
-- Import AFTER ffms_schema.sql, auth_migration.sql, seed_roles.sql,
-- farm_access_migration.sql and currency_migration.sql (phpMyAdmin > Import,
-- or the mysql command line).
--
-- Sign-in for every account created here: password  Farm@2026
-- If test@gmail.com already exists, it keeps its current password and is made
-- an administrator so John can switch between his three farms.
--
-- Safe to import again: it first removes the previous copy of these three
-- farms (owned by test@gmail.com) and their records, then adds them fresh.
-- Nothing else in the database is touched.
-- Amounts are in Zambian kwacha (ZMW). Dates are around November 2026.
--
-- For a local copy only. Do not import it into the live site: every account
-- here shares one known password.
-- ============================================================================

USE ffms_db;
SET NAMES utf8mb4;
START TRANSACTION;

-- --------------------------------------------------------------------------
-- Owner account: John Sichula (administrator, owns all three farms)
-- --------------------------------------------------------------------------
SET @r_admin = (SELECT role_id FROM roles WHERE role_name = 'admin');
SET @r_owner = (SELECT role_id FROM roles WHERE role_name = 'owner');
SET @r_manager = (SELECT role_id FROM roles WHERE role_name = 'manager');
SET @r_agronomist = (SELECT role_id FROM roles WHERE role_name = 'agronomist');
SET @r_accountant = (SELECT role_id FROM roles WHERE role_name = 'accountant');
SET @r_worker = (SELECT role_id FROM roles WHERE role_name = 'worker');
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`)
VALUES (@r_admin, NULL, 'John', 'Sichula', 'test@gmail.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 977 412 300', 'active', NOW(), '2025-09-01 08:00:00', NOW())
ON DUPLICATE KEY UPDATE `role_id` = @r_admin, `farm_id` = NULL, `first_name` = 'John', `last_name` = 'Sichula', `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @john = (SELECT user_id FROM users WHERE email = 'test@gmail.com');

-- --------------------------------------------------------------------------
-- Remove an earlier import of this sample data (children first)
-- --------------------------------------------------------------------------
SET @old_farms = (SELECT GROUP_CONCAT(farm_id) FROM farms WHERE owner_id = @john AND farm_name IN ('Green Valley Farm', 'North Ridge', 'Valley Heights'));
DELETE i FROM sales_order_items i JOIN sales_orders o ON o.order_id = i.order_id WHERE FIND_IN_SET(o.farm_id, COALESCE(@old_farms, ''));
DELETE s FROM produce_storage s JOIN warehouses w ON w.warehouse_id = s.warehouse_id WHERE FIND_IN_SET(w.farm_id, COALESCE(@old_farms, ''));
DELETE s FROM produce_storage s JOIN harvests h ON h.harvest_id = s.harvest_id JOIN crop_plantings p ON p.planting_id = h.planting_id JOIN fields f ON f.field_id = p.field_id WHERE FIND_IN_SET(f.farm_id, COALESCE(@old_farms, ''));
DELETE a FROM chemical_applications a JOIN crop_plantings p ON p.planting_id = a.planting_id JOIN fields f ON f.field_id = p.field_id WHERE FIND_IN_SET(f.farm_id, COALESCE(@old_farms, ''));
DELETE a FROM chemical_applications a JOIN inventory_batches b ON b.batch_id = a.batch_id JOIN inventory_items it ON it.item_id = b.item_id WHERE FIND_IN_SET(it.farm_id, COALESCE(@old_farms, ''));
DELETE s FROM scouting_records s JOIN fields f ON f.field_id = s.field_id WHERE FIND_IN_SET(f.farm_id, COALESCE(@old_farms, ''));
DELETE h FROM harvests h JOIN crop_plantings p ON p.planting_id = h.planting_id JOIN fields f ON f.field_id = p.field_id WHERE FIND_IN_SET(f.farm_id, COALESCE(@old_farms, ''));
DELETE g FROM crop_growth_logs g JOIN crop_plantings p ON p.planting_id = g.planting_id JOIN fields f ON f.field_id = p.field_id WHERE FIND_IN_SET(f.farm_id, COALESCE(@old_farms, ''));
DELETE p FROM crop_plantings p JOIN fields f ON f.field_id = p.field_id WHERE FIND_IN_SET(f.farm_id, COALESCE(@old_farms, ''));
DELETE s FROM irrigation_schedules s JOIN irrigation_systems i ON i.system_id = s.system_id JOIN fields f ON f.field_id = i.field_id WHERE FIND_IN_SET(f.farm_id, COALESCE(@old_farms, ''));
DELETE i FROM irrigation_systems i JOIN fields f ON f.field_id = i.field_id WHERE FIND_IN_SET(f.farm_id, COALESCE(@old_farms, ''));
DELETE i FROM irrigation_systems i JOIN water_sources w ON w.source_id = i.source_id WHERE FIND_IN_SET(w.farm_id, COALESCE(@old_farms, ''));
DELETE h FROM livestock_health_records h JOIN livestock a ON a.animal_id = h.animal_id WHERE FIND_IN_SET(a.farm_id, COALESCE(@old_farms, ''));
DELETE FROM livestock_production_logs WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE FROM livestock_feed_logs WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
UPDATE livestock SET sire_id = NULL, dam_id = NULL WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE FROM livestock WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE t FROM inventory_transactions t JOIN inventory_batches b ON b.batch_id = t.batch_id JOIN inventory_items it ON it.item_id = b.item_id WHERE FIND_IN_SET(it.farm_id, COALESCE(@old_farms, ''));
DELETE l FROM labor_assignments l JOIN task_allocations t ON t.task_id = l.task_id WHERE FIND_IN_SET(t.farm_id, COALESCE(@old_farms, ''));
DELETE l FROM labor_assignments l JOIN employees e ON e.employee_id = l.employee_id WHERE FIND_IN_SET(e.farm_id, COALESCE(@old_farms, ''));
DELETE u FROM machinery_usage u JOIN machinery m ON m.machinery_id = u.machinery_id WHERE FIND_IN_SET(m.farm_id, COALESCE(@old_farms, ''));
DELETE x FROM machinery_maintenance x JOIN machinery m ON m.machinery_id = x.machinery_id WHERE FIND_IN_SET(m.farm_id, COALESCE(@old_farms, ''));
DELETE b FROM inventory_batches b JOIN inventory_items it ON it.item_id = b.item_id WHERE FIND_IN_SET(it.farm_id, COALESCE(@old_farms, ''));
DELETE FROM inventory_items WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE FROM purchase_orders WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE FROM sales_orders WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE FROM customers WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE FROM suppliers WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE FROM employees WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE FROM task_allocations WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE FROM machinery WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE FROM warehouses WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE FROM water_sources WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE FROM weather_logs WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE FROM financial_transactions WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE FROM fields WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));
DELETE n FROM notifications n JOIN users u ON u.user_id = n.user_id WHERE u.email IN ('mwansa.banda@example.com', 'chipo.mulenga@example.com', 'bwalya.chanda@example.com', 'joseph.phiri@example.com', 'ruth.zulu@example.com', 'grace.tembo@example.com', 'peter.mbewe@example.com', 'esther.daka@example.com', 'moses.ngoma@example.com', 'agnes.lungu@example.com', 'kelvin.mwale@example.com', 'natasha.siame@example.com', 'brian.hamoonga@example.com', 'mutale.kapembwa@example.com', 'charity.muleya@example.com');
-- (John's sample notifications are cleared just before they are re-added, further down.)
DELETE FROM farms WHERE FIND_IN_SET(farm_id, COALESCE(@old_farms, ''));

-- --------------------------------------------------------------------------
-- Farms
-- --------------------------------------------------------------------------
INSERT INTO `farms` (`owner_id`, `farm_name`, `country_code`, `currency_code`, `total_area_hectares`, `latitude`, `longitude`, `address`, `created_at`) VALUES (@john, 'Green Valley Farm', 'ZM', 'ZMW', 320.0, -15.295000, 28.438000, 'Plot 1142, 16 Miles, Great East Road, Lusaka', '2025-09-02 09:00:00');
SET @gv = LAST_INSERT_ID();
INSERT INTO `farms` (`owner_id`, `farm_name`, `country_code`, `currency_code`, `total_area_hectares`, `latitude`, `longitude`, `address`, `created_at`) VALUES (@john, 'North Ridge', 'ZM', 'ZMW', 210.0, -13.621000, 32.624000, 'Farm 77, Lundazi Road, Chipata, Eastern Province', '2025-09-05 10:30:00');
SET @nr = LAST_INSERT_ID();
INSERT INTO `farms` (`owner_id`, `farm_name`, `country_code`, `currency_code`, `total_area_hectares`, `latitude`, `longitude`, `address`, `created_at`) VALUES (@john, 'Valley Heights', 'ZM', 'ZMW', 280.0, -15.802000, 28.165000, 'Farm 905/A, Chanyanya Road, Kafue', '2025-09-09 11:15:00');
SET @vh = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Staff accounts, one farm each (password Farm@2026)
-- --------------------------------------------------------------------------
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`) VALUES (@r_manager, @gv, 'Mwansa', 'Banda', 'mwansa.banda@example.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 966 201 114', 'active', NOW(), '2025-09-15 08:00:00', NOW()) ON DUPLICATE KEY UPDATE `role_id` = @r_manager, `farm_id` = @gv, `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @u_gv_mgr = (SELECT user_id FROM users WHERE email = 'mwansa.banda@example.com');
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`) VALUES (@r_agronomist, @gv, 'Chipo', 'Mulenga', 'chipo.mulenga@example.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 977 330 951', 'active', NOW(), '2025-09-15 08:00:00', NOW()) ON DUPLICATE KEY UPDATE `role_id` = @r_agronomist, `farm_id` = @gv, `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @u_gv_agr = (SELECT user_id FROM users WHERE email = 'chipo.mulenga@example.com');
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`) VALUES (@r_accountant, @gv, 'Bwalya', 'Chanda', 'bwalya.chanda@example.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 955 118 402', 'active', NOW(), '2025-09-15 08:00:00', NOW()) ON DUPLICATE KEY UPDATE `role_id` = @r_accountant, `farm_id` = @gv, `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @u_gv_acc = (SELECT user_id FROM users WHERE email = 'bwalya.chanda@example.com');
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`) VALUES (@r_worker, @gv, 'Joseph', 'Phiri', 'joseph.phiri@example.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 976 540 233', 'active', NOW(), '2025-09-15 08:00:00', NOW()) ON DUPLICATE KEY UPDATE `role_id` = @r_worker, `farm_id` = @gv, `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @u_gv_w1 = (SELECT user_id FROM users WHERE email = 'joseph.phiri@example.com');
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`) VALUES (@r_worker, @gv, 'Ruth', 'Zulu', 'ruth.zulu@example.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 968 772 015', 'active', NOW(), '2025-09-15 08:00:00', NOW()) ON DUPLICATE KEY UPDATE `role_id` = @r_worker, `farm_id` = @gv, `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @u_gv_w2 = (SELECT user_id FROM users WHERE email = 'ruth.zulu@example.com');
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`) VALUES (@r_manager, @nr, 'Grace', 'Tembo', 'grace.tembo@example.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 977 615 880', 'active', NOW(), '2025-09-15 08:00:00', NOW()) ON DUPLICATE KEY UPDATE `role_id` = @r_manager, `farm_id` = @nr, `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @u_nr_mgr = (SELECT user_id FROM users WHERE email = 'grace.tembo@example.com');
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`) VALUES (@r_agronomist, @nr, 'Peter', 'Mbewe', 'peter.mbewe@example.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 966 904 127', 'active', NOW(), '2025-09-15 08:00:00', NOW()) ON DUPLICATE KEY UPDATE `role_id` = @r_agronomist, `farm_id` = @nr, `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @u_nr_agr = (SELECT user_id FROM users WHERE email = 'peter.mbewe@example.com');
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`) VALUES (@r_accountant, @nr, 'Esther', 'Daka', 'esther.daka@example.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 955 437 690', 'active', NOW(), '2025-09-15 08:00:00', NOW()) ON DUPLICATE KEY UPDATE `role_id` = @r_accountant, `farm_id` = @nr, `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @u_nr_acc = (SELECT user_id FROM users WHERE email = 'esther.daka@example.com');
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`) VALUES (@r_worker, @nr, 'Moses', 'Ngoma', 'moses.ngoma@example.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 979 213 548', 'active', NOW(), '2025-09-15 08:00:00', NOW()) ON DUPLICATE KEY UPDATE `role_id` = @r_worker, `farm_id` = @nr, `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @u_nr_w1 = (SELECT user_id FROM users WHERE email = 'moses.ngoma@example.com');
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`) VALUES (@r_worker, @nr, 'Agnes', 'Lungu', 'agnes.lungu@example.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 965 380 772', 'active', NOW(), '2025-09-15 08:00:00', NOW()) ON DUPLICATE KEY UPDATE `role_id` = @r_worker, `farm_id` = @nr, `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @u_nr_w2 = (SELECT user_id FROM users WHERE email = 'agnes.lungu@example.com');
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`) VALUES (@r_manager, @vh, 'Kelvin', 'Mwale', 'kelvin.mwale@example.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 977 820 336', 'active', NOW(), '2025-09-15 08:00:00', NOW()) ON DUPLICATE KEY UPDATE `role_id` = @r_manager, `farm_id` = @vh, `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @u_vh_mgr = (SELECT user_id FROM users WHERE email = 'kelvin.mwale@example.com');
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`) VALUES (@r_agronomist, @vh, 'Natasha', 'Siame', 'natasha.siame@example.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 966 152 907', 'active', NOW(), '2025-09-15 08:00:00', NOW()) ON DUPLICATE KEY UPDATE `role_id` = @r_agronomist, `farm_id` = @vh, `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @u_vh_agr = (SELECT user_id FROM users WHERE email = 'natasha.siame@example.com');
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`) VALUES (@r_accountant, @vh, 'Brian', 'Hamoonga', 'brian.hamoonga@example.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 955 671 248', 'active', NOW(), '2025-09-15 08:00:00', NOW()) ON DUPLICATE KEY UPDATE `role_id` = @r_accountant, `farm_id` = @vh, `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @u_vh_acc = (SELECT user_id FROM users WHERE email = 'brian.hamoonga@example.com');
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`) VALUES (@r_worker, @vh, 'Mutale', 'Kapembwa', 'mutale.kapembwa@example.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 978 409 615', 'active', NOW(), '2025-09-15 08:00:00', NOW()) ON DUPLICATE KEY UPDATE `role_id` = @r_worker, `farm_id` = @vh, `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @u_vh_w1 = (SELECT user_id FROM users WHERE email = 'mutale.kapembwa@example.com');
INSERT INTO `users` (`role_id`, `farm_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `status`, `email_verified_at`, `created_at`, `updated_at`) VALUES (@r_worker, @vh, 'Charity', 'Muleya', 'charity.muleya@example.com', '$2y$10$EBECnjEr8ZTRUKhRuIngMewLzhYZA/jf7y0yw76JUWbnFwxbYCWxq', '+260 967 255 390', 'active', NOW(), '2025-09-15 08:00:00', NOW()) ON DUPLICATE KEY UPDATE `role_id` = @r_worker, `farm_id` = @vh, `status` = 'active', `email_verified_at` = COALESCE(`email_verified_at`, NOW());
SET @u_vh_w2 = (SELECT user_id FROM users WHERE email = 'charity.muleya@example.com');

-- --------------------------------------------------------------------------
-- Fields
-- --------------------------------------------------------------------------
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@gv, 'Pivot 1 (North)', 60.0, 'sandy loam', 5.8, 2.1, 'Irrigated maize / wheat rotation', '2025-09-20 09:00:00');
SET @f_gv_p1 = LAST_INSERT_ID();
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@gv, 'Pivot 2 (South)', 55.0, 'loam', 6.2, 2.6, 'Irrigated wheat / soybean rotation', '2025-09-20 09:00:00');
SET @f_gv_p2 = LAST_INSERT_ID();
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@gv, 'Block A - Dambo', 12.0, 'clay loam', 6.4, 3.4, 'Vegetables (cabbage, onion)', '2025-09-20 09:00:00');
SET @f_gv_ba = LAST_INSERT_ID();
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@gv, 'Vegetable Garden', 6.0, 'loam', 6.5, 3.8, 'Tomatoes under drip', '2025-09-20 09:00:00');
SET @f_gv_vg = LAST_INSERT_ID();
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@gv, 'Paddock 1 (Dairy)', 40.0, 'sandy loam', 5.6, 2.9, 'Grazing - Rhodes grass pasture', '2025-09-20 09:00:00');
SET @f_gv_pd = LAST_INSERT_ID();
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@gv, 'Block B - Upland', 85.0, 'red clay', 5.1, 1.6, 'Rain-fed maize / soybean', '2025-09-20 09:00:00');
SET @f_gv_bb = LAST_INSERT_ID();
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@nr, 'Lundazi Road Block', 60.0, 'red clay', 5.4, 1.9, 'Rain-fed maize', '2025-09-20 09:00:00');
SET @f_nr_lr = LAST_INSERT_ID();
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@nr, 'Hilltop Field', 35.0, 'sandy loam', 5.9, 1.3, 'Sunflower / fallow', '2025-09-20 09:00:00');
SET @f_nr_hf = LAST_INSERT_ID();
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@nr, 'Groundnut Plot', 25.0, 'sandy loam', 6.1, 1.7, 'Groundnuts', '2025-09-20 09:00:00');
SET @f_nr_gn = LAST_INSERT_ID();
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@nr, 'Cotton Block', 40.0, 'clay loam', 6.6, 2.2, 'Cotton', '2025-09-20 09:00:00');
SET @f_nr_ct = LAST_INSERT_ID();
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@nr, 'Tobacco Barn Field', 15.0, 'sandy loam', 5.7, 2.0, 'Virginia tobacco', '2025-09-20 09:00:00');
SET @f_nr_tb = LAST_INSERT_ID();
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@vh, 'Riverside Pivot', 50.0, 'alluvial loam', 6.8, 3.1, 'Irrigated wheat / maize', '2025-09-20 09:00:00');
SET @f_vh_rp = LAST_INSERT_ID();
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@vh, 'Kafue Flats Block', 45.0, 'heavy clay', 7.2, 2.8, 'Seasonal crops (flood-prone)', '2025-09-20 09:00:00');
SET @f_vh_kf = LAST_INSERT_ID();
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@vh, 'Drip Garden', 8.0, 'loam', 6.3, 3.5, 'Onions and tomatoes under drip', '2025-09-20 09:00:00');
SET @f_vh_dg = LAST_INSERT_ID();
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@vh, 'Sugarcane Block', 70.0, 'clay loam', 6.9, 2.4, 'Sugarcane (furrow irrigated)', '2025-09-20 09:00:00');
SET @f_vh_sc = LAST_INSERT_ID();
INSERT INTO `fields` (`farm_id`, `field_name`, `area_hectares`, `soil_type`, `ph_level`, `organic_matter_pct`, `current_land_use`, `created_at`) VALUES (@vh, 'Grazing Camp', 60.0, 'sandy clay', 6.0, 1.8, 'Grazing - beef cattle and sheep', '2025-09-20 09:00:00');
SET @f_vh_gc = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Crop varieties (shared by all farms; only added if missing)
-- --------------------------------------------------------------------------
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Maize', 'SC 513', 120, 53000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Maize' AND variety_name = 'SC 513');
SET @v_maize_sc513 = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Maize' AND variety_name = 'SC 513' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Maize', 'PAN 53', 130, 44000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Maize' AND variety_name = 'PAN 53');
SET @v_maize_pan53 = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Maize' AND variety_name = 'PAN 53' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Maize', 'ZMS 606', 140, 44000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Maize' AND variety_name = 'ZMS 606');
SET @v_maize_zms606 = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Maize' AND variety_name = 'ZMS 606' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Soybean', 'Lukanga', 115, 350000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Soybean' AND variety_name = 'Lukanga');
SET @v_soy_lukanga = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Soybean' AND variety_name = 'Lukanga' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Soybean', 'Kafue', 120, 330000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Soybean' AND variety_name = 'Kafue');
SET @v_soy_kafue = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Soybean' AND variety_name = 'Kafue' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Wheat', 'Loerie', 125, 2500000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Wheat' AND variety_name = 'Loerie');
SET @v_wheat = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Wheat' AND variety_name = 'Loerie' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Groundnut', 'MGV 5', 130, 150000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Groundnut' AND variety_name = 'MGV 5');
SET @v_gnut_mgv5 = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Groundnut' AND variety_name = 'MGV 5' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Groundnut', 'Chalimbana', 140, 120000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Groundnut' AND variety_name = 'Chalimbana');
SET @v_gnut_chal = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Groundnut' AND variety_name = 'Chalimbana' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Cotton', 'QM 301', 170, 44000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Cotton' AND variety_name = 'QM 301');
SET @v_cotton = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Cotton' AND variety_name = 'QM 301' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Tobacco', 'K326', 120, 15000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Tobacco' AND variety_name = 'K326');
SET @v_tobacco = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Tobacco' AND variety_name = 'K326' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Sunflower', 'PAN 7351', 110, 40000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Sunflower' AND variety_name = 'PAN 7351');
SET @v_sunflower = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Sunflower' AND variety_name = 'PAN 7351' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Tomato', 'Tengeru 97', 100, 25000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Tomato' AND variety_name = 'Tengeru 97');
SET @v_tomato_ten = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Tomato' AND variety_name = 'Tengeru 97' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Tomato', 'Rodade', 100, 25000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Tomato' AND variety_name = 'Rodade');
SET @v_tomato_rod = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Tomato' AND variety_name = 'Rodade' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Cabbage', 'Drumhead', 90, 40000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Cabbage' AND variety_name = 'Drumhead');
SET @v_cabbage = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Cabbage' AND variety_name = 'Drumhead' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Onion', 'Texas Grano', 130, 500000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Onion' AND variety_name = 'Texas Grano');
SET @v_onion = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Onion' AND variety_name = 'Texas Grano' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Beans', 'Lyambai', 90, 200000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Beans' AND variety_name = 'Lyambai');
SET @v_beans = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Beans' AND variety_name = 'Lyambai' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Sorghum', 'Sima', 110, 100000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Sorghum' AND variety_name = 'Sima');
SET @v_sorghum = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Sorghum' AND variety_name = 'Sima' ORDER BY variety_id LIMIT 1);
INSERT INTO `crop_varieties` (`crop_name`, `variety_name`, `typical_maturity_days`, `optimal_density_per_ha`, `created_at`) SELECT 'Sugarcane', 'NCo 376', 540, 15000, '2025-09-01 08:00:00' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM crop_varieties WHERE crop_name = 'Sugarcane' AND variety_name = 'NCo 376');
SET @v_sugarcane = (SELECT variety_id FROM crop_varieties WHERE crop_name = 'Sugarcane' AND variety_name = 'NCo 376' ORDER BY variety_id LIMIT 1);

-- --------------------------------------------------------------------------
-- Pest & disease catalogue (shared by all farms; only added if missing)
-- --------------------------------------------------------------------------
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Fall armyworm', 'pest', 'Ragged holes and window-pane feeding in the whorl, sawdust-like frass, larvae with an inverted Y on the head.', 'Scout twice a week; spray emamectin benzoate or chlorantraniliprole into the whorl when 20% of plants show fresh damage. Rotate chemical groups.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Fall armyworm');
SET @c_faw = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Fall armyworm' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Maize stalk borer', 'pest', 'Shot-holes in leaves, dead heart in young plants, tunnels in stems.', 'Destroy old stalks after harvest; apply granules into the whorl at first signs.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Maize stalk borer');
SET @c_borer = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Maize stalk borer' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Aphids', 'pest', 'Clusters of small soft insects under leaves, curling and sticky honeydew.', 'Encourage ladybirds; spray soap or a registered systemic insecticide when colonies spread.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Aphids');
SET @c_aphid = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Aphids' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Red spider mite', 'pest', 'Fine webbing, yellow speckling on leaves, worse in hot dry weather.', 'Keep plants watered; use abamectin or a registered miticide, rotate groups.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Red spider mite');
SET @c_mite = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Red spider mite' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Tuta absoluta (tomato leafminer)', 'pest', 'Blotch mines in leaves, holes in fruit, larvae inside mines.', 'Pheromone traps, remove infested leaves, spray chlorantraniliprole or spinetoram in rotation.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Tuta absoluta (tomato leafminer)');
SET @c_tuta = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Tuta absoluta (tomato leafminer)' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Cutworm', 'pest', 'Seedlings cut at ground level overnight; grey larvae curl up in the soil.', 'Clean seedbed, bait or a registered soil spray along rows at planting.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Cutworm');
SET @c_cutworm = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Cutworm' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Diamondback moth', 'pest', 'Small green caterpillars making windows in cabbage leaves.', 'Bt sprays, rotate insecticide groups, remove crop residues.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Diamondback moth');
SET @c_dbm = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Diamondback moth' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'African bollworm', 'pest', 'Holes in cotton bolls and tomato fruit, larvae feeding inside.', 'Scout squares and bolls; Bt or a registered insecticide at threshold.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'African bollworm');
SET @c_bollworm = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'African bollworm' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Termites', 'pest', 'Wilting plants, hollowed stems and mud tubes on stems.', 'Remove crop residue near mounds; seed dressing or registered soil treatment.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Termites');
SET @c_termite = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Termites' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Larger grain borer', 'pest', 'Fine flour dust and holes in stored maize grain.', 'Dry grain to 12.5% moisture, use hermetic bags or a registered grain protectant.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Larger grain borer');
SET @c_lgb = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Larger grain borer' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Quelea birds', 'pest', 'Large flocks feeding on ripening wheat and sorghum.', 'Report to the district agricultural office; bird scaring at dawn and dusk.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Quelea birds');
SET @c_quelea = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Quelea birds' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Grey leaf spot', 'disease', 'Long rectangular grey lesions between leaf veins on maize.', 'Rotate crops, plant tolerant hybrids, fungicide at tasselling in wet seasons.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Grey leaf spot');
SET @c_gls = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Grey leaf spot' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Late blight', 'disease', 'Dark water-soaked patches on tomato leaves and stems, white mould under leaves in humid weather.', 'Protectant fungicide (mancozeb) ahead of wet spells; systemic fungicide once seen.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Late blight');
SET @c_lateblight = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Late blight' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Soybean rust', 'disease', 'Small tan to red-brown pustules under leaves, early leaf drop.', 'Scout from flowering; triazole or strobilurin fungicide at first signs.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Soybean rust');
SET @c_rust = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Soybean rust' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Groundnut rosette virus', 'disease', 'Stunted bushy plants with yellow or dark green mottled leaves, spread by aphids.', 'Early planting at the right density, control aphids, remove infected plants.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Groundnut rosette virus');
SET @c_rosette = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Groundnut rosette virus' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Bacterial wilt', 'disease', 'Sudden wilting of tomato plants while leaves stay green; brown stem inside.', 'Rotate away from tomato/potato for 3 years, use clean seedlings, remove affected plants.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Bacterial wilt');
SET @c_wilt = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Bacterial wilt' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Striga (witchweed)', 'weed', 'Bright pink-flowered weed attached to maize and sorghum roots; host plants stunted.', 'Rotate with legumes, pull before flowering, use tolerant varieties.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Striga (witchweed)');
SET @c_striga = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Striga (witchweed)' ORDER BY catalog_id LIMIT 1);
INSERT INTO `pest_disease_catalog` (`name`, `type`, `symptoms`, `recommended_control`) SELECT 'Blackjack (Bidens pilosa)', 'weed', 'Fast-growing broadleaf weed with barbed seeds competing early with crops.', 'Early weeding in the first 6 weeks; registered pre-emergence herbicide.' FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM pest_disease_catalog WHERE name = 'Blackjack (Bidens pilosa)');
SET @c_blackjack = (SELECT catalog_id FROM pest_disease_catalog WHERE name = 'Blackjack (Bidens pilosa)' ORDER BY catalog_id LIMIT 1);

-- --------------------------------------------------------------------------
-- Crop plantings
-- --------------------------------------------------------------------------
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_gv_p1, @v_maize_sc513, '2025-11-12', '2026-04-10', '2026-04-18', 58.0, 53000, 75.0, 25.0, 'harvested', '2025-11-12 07:30:00');
SET @p_gv_maize25 = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_gv_p2, @v_wheat, '2026-05-05', '2026-09-15', '2026-09-18', 52.0, 2500000, 20.0, 2.0, 'harvested', '2026-05-05 07:30:00');
SET @p_gv_wheat26 = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_gv_bb, @v_soy_lukanga, '2025-12-03', '2026-04-05', '2026-04-08', 80.0, 350000, 45.0, 5.0, 'harvested', '2025-12-03 07:30:00');
SET @p_gv_soy25 = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_gv_vg, @v_cabbage, '2026-03-01', '2026-05-30', '2026-06-02', 5.0, 40000, 60.0, 40.0, 'harvested', '2026-03-01 07:30:00');
SET @p_gv_cab26 = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_gv_ba, @v_onion, '2026-04-10', '2026-08-18', '2026-08-20', 10.0, 500000, 30.0, 7.0, 'harvested', '2026-04-10 07:30:00');
SET @p_gv_onion26 = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_nr_lr, @v_maize_pan53, '2025-11-22', '2026-04-25', '2026-05-02', 58.0, 44000, 90.0, 25.0, 'harvested', '2025-11-22 07:30:00');
SET @p_nr_maize25 = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_nr_gn, @v_gnut_mgv5, '2025-12-01', '2026-04-10', '2026-04-12', 24.0, 150000, 45.0, 15.0, 'harvested', '2025-12-01 07:30:00');
SET @p_nr_gnut25 = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_nr_ct, @v_cotton, '2025-12-08', '2026-05-25', '2026-05-28', 38.0, 44000, 90.0, 25.0, 'harvested', '2025-12-08 07:30:00');
SET @p_nr_cot25 = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_nr_tb, @v_tobacco, '2025-11-18', '2026-03-20', '2026-03-25', 14.0, 15000, 120.0, 55.0, 'harvested', '2025-11-18 07:30:00');
SET @p_nr_tob25 = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_nr_hf, @v_sunflower, '2026-01-08', '2026-04-28', '2026-05-03', 30.0, 40000, 90.0, 30.0, 'harvested', '2026-01-08 07:30:00');
SET @p_nr_sun26 = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_vh_rp, @v_wheat, '2026-05-12', '2026-09-20', '2026-09-25', 48.0, 2500000, 20.0, 2.0, 'harvested', '2026-05-12 07:30:00');
SET @p_vh_wheat26 = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_vh_dg, @v_tomato_rod, '2026-03-01', '2026-06-05', '2026-06-10', 4.0, 25000, 120.0, 35.0, 'harvested', '2026-03-01 07:30:00');
SET @p_vh_tom26 = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_vh_kf, @v_beans, '2026-02-05', '2026-05-05', NULL, 40.0, 200000, 50.0, 10.0, 'failed', '2026-02-05 07:30:00');
SET @p_vh_beans26 = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_gv_vg, @v_tomato_ten, '2026-08-20', '2026-11-25', NULL, 5.0, 25000, 120.0, 35.0, 'active', '2026-08-20 07:30:00');
SET @p_gv_tom = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_gv_ba, @v_cabbage, '2026-09-10', '2026-12-05', NULL, 10.0, 40000, 60.0, 40.0, 'active', '2026-09-10 07:30:00');
SET @p_gv_cab = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_gv_p1, @v_maize_sc513, '2026-10-25', '2027-02-22', NULL, 58.0, 53000, 75.0, 25.0, 'active', '2026-10-25 07:30:00');
SET @p_gv_maize = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_nr_lr, @v_maize_pan53, '2026-10-30', '2027-03-09', NULL, 58.0, 44000, 90.0, 25.0, 'active', '2026-10-30 07:30:00');
SET @p_nr_maize = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_nr_tb, @v_tobacco, '2026-10-15', '2027-02-12', NULL, 14.0, 15000, 120.0, 55.0, 'active', '2026-10-15 07:30:00');
SET @p_nr_tob = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_vh_rp, @v_maize_sc513, '2026-10-20', '2027-02-17', NULL, 48.0, 53000, 75.0, 25.0, 'active', '2026-10-20 07:30:00');
SET @p_vh_maize = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_vh_dg, @v_onion, '2026-07-01', '2026-11-08', NULL, 3.0, 500000, 30.0, 7.0, 'active', '2026-07-01 07:30:00');
SET @p_vh_onion = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_vh_dg, @v_tomato_rod, '2026-09-15', '2026-12-20', NULL, 4.0, 25000, 120.0, 35.0, 'active', '2026-09-15 07:30:00');
SET @p_vh_tom = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_vh_sc, @v_sugarcane, '2026-03-15', '2027-09-05', NULL, 65.0, 15000, 150.0, 50.0, 'active', '2026-03-15 07:30:00');
SET @p_vh_cane = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_gv_p2, @v_soy_kafue, '2026-11-20', '2027-03-20', NULL, 52.0, 330000, 45.0, 6.0, 'planned', '2026-11-20 07:30:00');
SET @p_gv_soy = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_gv_bb, @v_maize_zms606, '2026-11-25', '2027-04-14', NULL, 80.0, 44000, 90.0, 25.0, 'planned', '2026-11-25 07:30:00');
SET @p_gv_maizeB = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_nr_gn, @v_gnut_chal, '2026-11-28', '2027-04-17', NULL, 24.0, 120000, 45.0, 18.0, 'planned', '2026-11-28 07:30:00');
SET @p_nr_gnut = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_nr_ct, @v_cotton, '2026-12-01', '2027-05-20', NULL, 38.0, 44000, 90.0, 25.0, 'planned', '2026-12-01 07:30:00');
SET @p_nr_cot = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_nr_hf, @v_sunflower, '2027-01-10', '2027-04-30', NULL, 30.0, 40000, 90.0, 30.0, 'planned', '2027-01-10 07:30:00');
SET @p_nr_sun = LAST_INSERT_ID();
INSERT INTO `crop_plantings` (`field_id`, `variety_id`, `planting_date`, `expected_harvest_date`, `actual_harvest_date`, `planted_area_hectares`, `planting_density_per_ha`, `spacing_row_cm`, `spacing_plant_cm`, `status`, `created_at`) VALUES (@f_vh_kf, @v_sorghum, '2026-12-10', '2027-03-30', NULL, 40.0, 100000, 75.0, 15.0, 'planned', '2026-12-10 07:30:00');
SET @p_vh_sorg = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Crop growth logs
-- --------------------------------------------------------------------------
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_maize25, '2025-11-24', 'Germination', 6.0, 'Good', 'Even emergence, about 95% stand.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_maize25, '2025-12-20', 'Vegetative', 65.0, 'Good', 'V8, first top-dressing done.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_maize25, '2026-01-22', 'Flowering', 210.0, 'Good', 'Tasselling and silking well.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_maize25, '2026-03-10', 'Maturity', 240.0, 'Good', 'Black layer forming; drying down.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_wheat26, '2026-05-18', 'Germination', 5.0, 'Good', 'Good emergence under pivot.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_wheat26, '2026-06-25', 'Vegetative', 40.0, 'Good', 'Tillering well.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_wheat26, '2026-08-01', 'Flowering', 80.0, 'Fair', 'Some aphids on flag leaves.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_wheat26, '2026-09-01', 'Maturity', 92.0, 'Good', 'Grain filling done.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_soy25, '2025-12-15', 'Germination', 4.0, 'Good', 'Nodulation checked - pink nodules.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_soy25, '2026-01-20', 'Vegetative', 45.0, 'Good', 'Canopy closing.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_soy25, '2026-02-18', 'Flowering', 70.0, 'Fair', 'Rust pustules seen on lower leaves.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_soy25, '2026-03-25', 'Maturity', 85.0, 'Good', 'Leaves dropping, pods brown.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_cab26, '2026-03-12', 'Germination', 8.0, 'Good', 'Transplants established.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_cab26, '2026-04-10', 'Vegetative', 25.0, 'Fair', 'Diamondback moth damage on outer leaves.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_cab26, '2026-05-15', 'Maturity', 35.0, 'Good', 'Heads firm, 2-3 kg.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_onion26, '2026-04-25', 'Germination', 6.0, 'Good', 'Transplants rooted.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_onion26, '2026-06-10', 'Vegetative', 35.0, 'Good', 'Bulbing started.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_onion26, '2026-08-05', 'Maturity', 45.0, 'Good', 'Necks softening.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_maize25, '2025-12-05', 'Germination', 5.0, 'Fair', 'Patchy emergence on the eastern side, cutworm.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_maize25, '2026-01-10', 'Vegetative', 90.0, 'Fair', 'Fall armyworm damage on 25% of plants.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_maize25, '2026-02-12', 'Flowering', 205.0, 'Good', 'Recovered after spraying.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_maize25, '2026-04-01', 'Maturity', 225.0, 'Good', 'Drying in the field.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_gnut25, '2025-12-14', 'Germination', 3.0, 'Good', 'Good stand.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_gnut25, '2026-01-25', 'Vegetative', 18.0, 'Fair', 'A few rosette plants pulled out.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_gnut25, '2026-02-20', 'Flowering', 30.0, 'Good', 'Pegging well.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_gnut25, '2026-03-30', 'Maturity', 35.0, 'Good', 'Pods filled, inner shell dark.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_cot25, '2025-12-22', 'Germination', 5.0, 'Good', 'Thinned to one plant per station.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_cot25, '2026-02-05', 'Vegetative', 60.0, 'Good', 'Squaring.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_cot25, '2026-03-10', 'Flowering', 95.0, 'Fair', 'Bollworm eggs on squares.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_cot25, '2026-04-28', 'Maturity', 110.0, 'Good', 'Bolls opening.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_tob25, '2025-11-30', 'Germination', 10.0, 'Good', 'Transplants established.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_tob25, '2026-01-05', 'Vegetative', 70.0, 'Good', 'Topped at 18 leaves.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_tob25, '2026-02-15', 'Maturity', 120.0, 'Good', 'Reaping lower leaves.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_sun26, '2026-01-20', 'Germination', 6.0, 'Good', 'Even stand.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_sun26, '2026-02-25', 'Vegetative', 90.0, 'Good', 'Fast growth after rains.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_sun26, '2026-03-20', 'Flowering', 160.0, 'Fair', 'Bird pressure starting.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_wheat26, '2026-05-24', 'Germination', 5.0, 'Good', 'Good emergence.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_wheat26, '2026-07-01', 'Vegetative', 45.0, 'Good', 'Tillering.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_wheat26, '2026-08-05', 'Flowering', 85.0, 'Good', 'Heading evenly.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_wheat26, '2026-09-05', 'Maturity', 95.0, 'Fair', 'Quelea pressure on the river edge.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_tom26, '2026-03-12', 'Germination', 12.0, 'Good', 'Transplants established.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_tom26, '2026-04-05', 'Vegetative', 55.0, 'Good', 'Staked and pruned.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_tom26, '2026-04-28', 'Flowering', 95.0, 'Good', 'First trusses setting.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_tom26, '2026-05-18', 'Maturity', 120.0, 'Fair', 'Some blossom-end rot.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_beans26, '2026-02-18', 'Germination', 5.0, 'Good', 'Good emergence.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_beans26, '2026-03-12', 'Vegetative', 20.0, 'Poor', 'Waterlogged after Kafue flats flooding; plants yellow and wilting.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_tom, '2026-09-01', 'Germination', 12.0, 'Good', 'Transplants established under drip.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_tom, '2026-09-25', 'Vegetative', 55.0, 'Good', 'Staked; first pruning.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_tom, '2026-10-12', 'Flowering', 90.0, 'Good', 'Trusses setting fruit.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_tom, '2026-10-28', 'Flowering', 105.0, 'Poor - leaf mines and fruit damage', 'Tuta absoluta mines on upper leaves, some holed fruit.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_cab, '2026-09-22', 'Germination', 8.0, 'Good', 'Transplants established.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_cab, '2026-10-10', 'Vegetative', 22.0, 'Good', 'Weeded and top-dressed.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_cab, '2026-10-27', 'Flowering', 30.0, 'Good', 'Heads starting to form.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_gv_maize, '2026-11-01', 'Germination', 4.0, 'Good', 'Uniform emergence under pivot.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_maize, '2026-11-02', 'Germination', 3.0, 'Fair', 'Emerging unevenly; a few seedlings cut at ground level.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_nr_tob, '2026-10-15', 'Germination', 9.0, 'Good', 'Transplanted from seedbeds; watered in.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_maize, '2026-10-27', 'Germination', 5.0, 'Good', 'Good stand.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_maize, '2026-11-01', 'Vegetative', 18.0, 'Good', 'V3-V4.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_onion, '2026-07-15', 'Germination', 6.0, 'Good', 'Transplants rooted.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_onion, '2026-08-25', 'Vegetative', 38.0, 'Good', 'Bulbing well.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_onion, '2026-10-30', 'Maturity', 48.0, 'Good', 'Necks falling over - ready to lift soon.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_tom, '2026-09-28', 'Germination', 14.0, 'Good', 'Established.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_tom, '2026-10-15', 'Vegetative', 60.0, 'Fair', 'Red spider mite on lower leaves in the hot spell.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_tom, '2026-10-31', 'Flowering', 85.0, 'Good', 'Mites under control after spraying.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_cane, '2026-04-10', 'Germination', 20.0, 'Good', 'Setts sprouted well.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_cane, '2026-06-20', 'Vegetative', 90.0, 'Good', 'Tillering.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_cane, '2026-09-15', 'Vegetative', 170.0, 'Good', 'Grand growth stage.');
INSERT INTO `crop_growth_logs` (`planting_id`, `log_date`, `growth_stage`, `avg_height_cm`, `health_status`, `remarks`) VALUES (@p_vh_cane, '2026-10-30', 'Vegetative', 205.0, 'Good', 'Growing well; furrows cleaned.');

-- --------------------------------------------------------------------------
-- Water sources
-- --------------------------------------------------------------------------
INSERT INTO `water_sources` (`farm_id`, `source_name`, `capacity_cubic_meters`) VALUES (@gv, 'Borehole 1 (North)', 180.0);
SET @w_gv_bh1 = LAST_INSERT_ID();
INSERT INTO `water_sources` (`farm_id`, `source_name`, `capacity_cubic_meters`) VALUES (@gv, 'Borehole 2 (Dairy)', 120.0);
SET @w_gv_bh2 = LAST_INSERT_ID();
INSERT INTO `water_sources` (`farm_id`, `source_name`, `capacity_cubic_meters`) VALUES (@gv, 'Earth dam', 85000.0);
SET @w_gv_dam = LAST_INSERT_ID();
INSERT INTO `water_sources` (`farm_id`, `source_name`, `capacity_cubic_meters`) VALUES (@gv, 'Reservoir tank', 450.0);
SET @w_gv_tank = LAST_INSERT_ID();
INSERT INTO `water_sources` (`farm_id`, `source_name`, `capacity_cubic_meters`) VALUES (@gv, 'Seasonal stream weir', 12000.0);
SET @w_gv_stream = LAST_INSERT_ID();
INSERT INTO `water_sources` (`farm_id`, `source_name`, `capacity_cubic_meters`) VALUES (@nr, 'Main borehole', 150.0);
SET @w_nr_bh = LAST_INSERT_ID();
INSERT INTO `water_sources` (`farm_id`, `source_name`, `capacity_cubic_meters`) VALUES (@nr, 'Hilltop borehole', 90.0);
SET @w_nr_bh2 = LAST_INSERT_ID();
INSERT INTO `water_sources` (`farm_id`, `source_name`, `capacity_cubic_meters`) VALUES (@nr, 'Small dam', 30000.0);
SET @w_nr_dam = LAST_INSERT_ID();
INSERT INTO `water_sources` (`farm_id`, `source_name`, `capacity_cubic_meters`) VALUES (@nr, 'Rainwater tanks', 60.0);
SET @w_nr_tanks = LAST_INSERT_ID();
INSERT INTO `water_sources` (`farm_id`, `source_name`, `capacity_cubic_meters`) VALUES (@nr, 'River pump point', 20000.0);
SET @w_nr_river = LAST_INSERT_ID();
INSERT INTO `water_sources` (`farm_id`, `source_name`, `capacity_cubic_meters`) VALUES (@vh, 'Kafue River intake', 500000.0);
SET @w_vh_river = LAST_INSERT_ID();
INSERT INTO `water_sources` (`farm_id`, `source_name`, `capacity_cubic_meters`) VALUES (@vh, 'Borehole A', 200.0);
SET @w_vh_bhA = LAST_INSERT_ID();
INSERT INTO `water_sources` (`farm_id`, `source_name`, `capacity_cubic_meters`) VALUES (@vh, 'Borehole B', 160.0);
SET @w_vh_bhB = LAST_INSERT_ID();
INSERT INTO `water_sources` (`farm_id`, `source_name`, `capacity_cubic_meters`) VALUES (@vh, 'Night storage dam', 60000.0);
SET @w_vh_dam = LAST_INSERT_ID();
INSERT INTO `water_sources` (`farm_id`, `source_name`, `capacity_cubic_meters`) VALUES (@vh, 'Fish pond inflow canal', 8000.0);
SET @w_vh_canal = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Irrigation systems
-- --------------------------------------------------------------------------
INSERT INTO `irrigation_systems` (`field_id`, `source_id`, `system_type`, `installation_date`, `flow_rate_liters_per_hr`, `status`) VALUES (@f_gv_p1, @w_gv_dam, 'pivot', '2024-04-10', 180000.0, 'active');
SET @i_gv_piv1 = LAST_INSERT_ID();
INSERT INTO `irrigation_systems` (`field_id`, `source_id`, `system_type`, `installation_date`, `flow_rate_liters_per_hr`, `status`) VALUES (@f_gv_p2, @w_gv_dam, 'pivot', '2024-04-10', 170000.0, 'active');
SET @i_gv_piv2 = LAST_INSERT_ID();
INSERT INTO `irrigation_systems` (`field_id`, `source_id`, `system_type`, `installation_date`, `flow_rate_liters_per_hr`, `status`) VALUES (@f_gv_vg, @w_gv_bh1, 'drip', '2025-07-01', 12000.0, 'active');
SET @i_gv_drip = LAST_INSERT_ID();
INSERT INTO `irrigation_systems` (`field_id`, `source_id`, `system_type`, `installation_date`, `flow_rate_liters_per_hr`, `status`) VALUES (@f_gv_ba, @w_gv_stream, 'sprinkler', '2023-08-15', 25000.0, 'active');
SET @i_gv_spr = LAST_INSERT_ID();
INSERT INTO `irrigation_systems` (`field_id`, `source_id`, `system_type`, `installation_date`, `flow_rate_liters_per_hr`, `status`) VALUES (@f_gv_pd, @w_gv_bh2, 'other', '2023-02-01', 4000.0, 'inactive');
SET @i_gv_pad = LAST_INSERT_ID();
INSERT INTO `irrigation_systems` (`field_id`, `source_id`, `system_type`, `installation_date`, `flow_rate_liters_per_hr`, `status`) VALUES (@f_nr_tb, @w_nr_bh, 'drip', '2025-08-20', 15000.0, 'active');
SET @i_nr_drip = LAST_INSERT_ID();
INSERT INTO `irrigation_systems` (`field_id`, `source_id`, `system_type`, `installation_date`, `flow_rate_liters_per_hr`, `status`) VALUES (@f_nr_gn, @w_nr_dam, 'sprinkler', '2024-10-01', 20000.0, 'active');
SET @i_nr_spr = LAST_INSERT_ID();
INSERT INTO `irrigation_systems` (`field_id`, `source_id`, `system_type`, `installation_date`, `flow_rate_liters_per_hr`, `status`) VALUES (@f_nr_hf, @w_nr_bh2, 'sprinkler', '2022-09-01', 9000.0, 'inactive');
SET @i_nr_hill = LAST_INSERT_ID();
INSERT INTO `irrigation_systems` (`field_id`, `source_id`, `system_type`, `installation_date`, `flow_rate_liters_per_hr`, `status`) VALUES (@f_nr_lr, @w_nr_river, 'flood', '2023-11-01', 30000.0, 'active');
SET @i_nr_lr = LAST_INSERT_ID();
INSERT INTO `irrigation_systems` (`field_id`, `source_id`, `system_type`, `installation_date`, `flow_rate_liters_per_hr`, `status`) VALUES (@f_nr_ct, @w_nr_dam, 'other', '2024-11-15', 10000.0, 'maintenance');
SET @i_nr_cot = LAST_INSERT_ID();
INSERT INTO `irrigation_systems` (`field_id`, `source_id`, `system_type`, `installation_date`, `flow_rate_liters_per_hr`, `status`) VALUES (@f_vh_rp, @w_vh_river, 'pivot', '2023-05-01', 200000.0, 'active');
SET @i_vh_piv = LAST_INSERT_ID();
INSERT INTO `irrigation_systems` (`field_id`, `source_id`, `system_type`, `installation_date`, `flow_rate_liters_per_hr`, `status`) VALUES (@f_vh_dg, @w_vh_bhA, 'drip', '2025-02-01', 14000.0, 'active');
SET @i_vh_drip = LAST_INSERT_ID();
INSERT INTO `irrigation_systems` (`field_id`, `source_id`, `system_type`, `installation_date`, `flow_rate_liters_per_hr`, `status`) VALUES (@f_vh_sc, @w_vh_dam, 'flood', '2025-12-01', 120000.0, 'active');
SET @i_vh_cane = LAST_INSERT_ID();
INSERT INTO `irrigation_systems` (`field_id`, `source_id`, `system_type`, `installation_date`, `flow_rate_liters_per_hr`, `status`) VALUES (@f_vh_kf, @w_vh_river, 'flood', '2022-06-01', 60000.0, 'inactive');
SET @i_vh_kf = LAST_INSERT_ID();
INSERT INTO `irrigation_systems` (`field_id`, `source_id`, `system_type`, `installation_date`, `flow_rate_liters_per_hr`, `status`) VALUES (@f_vh_gc, @w_vh_bhB, 'sprinkler', '2024-03-01', 18000.0, 'maintenance');
SET @i_vh_gc = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Irrigation schedules
-- --------------------------------------------------------------------------
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_gv_piv1, '2026-10-22 05:00:00', 150, 416420.0, 876.55, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_gv_piv1, '2026-10-29 05:00:00', 120, 354320.0, 762.15, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_gv_piv1, '2026-11-02 18:00:00', 240, 671164.0, 1474.43, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_gv_piv1, '2026-11-05 18:00:00', 240, 659638.0, 1247.42, 'scheduled');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_gv_drip, '2026-10-22 05:00:00', 45, 8038.0, 18.48, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_gv_drip, '2026-10-29 05:00:00', 90, 17134.0, 40.35, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_gv_drip, '2026-11-02 17:00:00', 75, 14955.0, 40.6, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_gv_drip, '2026-11-05 18:00:00', 120, 22696.0, 59.27, 'scheduled');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_gv_spr, '2026-10-22 05:00:00', 120, 46535.0, 98.03, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_gv_spr, '2026-10-29 06:00:00', 120, 44817.0, 105.46, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_gv_spr, '2026-11-02 17:00:00', 75, 28724.0, 58.02, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_gv_spr, '2026-11-05 18:00:00', 45, 17134.0, 39.98, 'scheduled');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_nr_drip, '2026-10-22 18:00:00', 90, 22219.0, 50.75, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_nr_drip, '2026-10-29 18:00:00', 120, 29668.0, 70.91, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_nr_drip, '2026-11-02 05:00:00', 120, 26510.0, 58.9, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_nr_drip, '2026-11-05 05:00:00', 120, 29491.0, 65.15, 'scheduled');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_nr_spr, '2026-10-22 18:00:00', 90, 26141.0, 64.75, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_nr_spr, '2026-10-29 05:00:00', 90, 28534.0, 68.44, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_nr_spr, '2026-11-02 17:00:00', 120, 36412.0, 92.09, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_nr_spr, '2026-11-05 18:00:00', 90, 27449.0, 60.54, 'scheduled');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_vh_piv, '2026-10-22 17:00:00', 90, 256490.0, 502.5, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_vh_piv, '2026-10-29 18:00:00', 240, 791235.0, 1461.23, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_vh_piv, '2026-11-02 06:00:00', 150, 476949.0, 900.16, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_vh_piv, '2026-11-05 18:00:00', 180, 560205.0, 1151.09, 'scheduled');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_vh_drip, '2026-10-22 17:00:00', 75, 16076.0, 40.99, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_vh_drip, '2026-10-29 18:00:00', 120, 24887.0, 64.77, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_vh_drip, '2026-11-02 06:00:00', 90, 20504.0, 49.0, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_vh_drip, '2026-11-05 05:00:00', 75, 17246.0, 40.32, 'scheduled');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_vh_cane, '2026-10-22 06:00:00', 360, 704517.0, 982.03, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_vh_cane, '2026-10-29 05:00:00', 90, 153006.0, 233.21, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_vh_cane, '2026-11-02 05:00:00', 240, 465151.0, 662.54, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_vh_cane, '2026-11-05 05:00:00', 240, 476858.0, 739.39, 'scheduled');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_gv_piv2, '2026-09-02 06:00:00', 300, 820000.0, 1720.0, 'completed');
INSERT INTO `irrigation_schedules` (`system_id`, `start_time`, `duration_minutes`, `water_volume_liters`, `electricity_cost`, `status`) VALUES (@i_vh_cane, '2026-11-06 05:00:00', 360, 0.0, 0.0, 'cancelled');

-- --------------------------------------------------------------------------
-- Suppliers (each belongs to one farm)
-- --------------------------------------------------------------------------
INSERT INTO `suppliers` (`farm_id`, `supplier_name`, `contact_person`, `phone`, `email`, `address`, `rating`, `created_at`) VALUES (@gv, 'Lusaka Agro Inputs Ltd', 'Mercy Kalaba', '+260 211 286 450', 'sales@lusakaagro.example.com', 'Plot 32, Lumumba Road, Lusaka', 4.5, '2025-09-25 10:00:00');
SET @s_gv_agro = LAST_INSERT_ID();
INSERT INTO `suppliers` (`farm_id`, `supplier_name`, `contact_person`, `phone`, `email`, `address`, `rating`, `created_at`) VALUES (@gv, 'Mutende Vet Supplies', 'Dr. Paul Siwale', '+260 977 118 230', 'orders@mutendevet.example.com', 'Shop 5, Kabwe Roundabout, Lusaka', 4.7, '2025-09-25 10:00:00');
SET @s_gv_vet = LAST_INSERT_ID();
INSERT INTO `suppliers` (`farm_id`, `supplier_name`, `contact_person`, `phone`, `email`, `address`, `rating`, `created_at`) VALUES (@gv, 'Great East Fuels', 'Lameck Zimba', '+260 966 450 912', 'accounts@greateastfuels.example.com', 'Great East Road, 15 Miles, Lusaka', 3.9, '2025-09-25 10:00:00');
SET @s_gv_fuel = LAST_INSERT_ID();
INSERT INTO `suppliers` (`farm_id`, `supplier_name`, `contact_person`, `phone`, `email`, `address`, `rating`, `created_at`) VALUES (@gv, 'Kanyama Packaging Co.', 'Ireen Musonda', '+260 955 320 641', 'info@kanyamapack.example.com', 'Light Industrial Area, Lusaka', 4.1, '2025-09-25 10:00:00');
SET @s_gv_pack = LAST_INSERT_ID();
INSERT INTO `suppliers` (`farm_id`, `supplier_name`, `contact_person`, `phone`, `email`, `address`, `rating`, `created_at`) VALUES (@gv, 'Chongwe Stockfeeds', 'Victor Mumba', '+260 977 905 113', 'sales@chongwefeeds.example.com', 'Chongwe Boma, Lusaka Province', 4.3, '2025-09-25 10:00:00');
SET @s_gv_feed = LAST_INSERT_ID();
INSERT INTO `suppliers` (`farm_id`, `supplier_name`, `contact_person`, `phone`, `email`, `address`, `rating`, `created_at`) VALUES (@nr, 'Chipata Farmers Depot', 'Alick Banda', '+260 216 221 845', 'depot@chipatafarmers.example.com', 'Umodzi Highway, Chipata', 4.2, '2025-09-25 10:00:00');
SET @s_nr_depot = LAST_INSERT_ID();
INSERT INTO `suppliers` (`farm_id`, `supplier_name`, `contact_person`, `phone`, `email`, `address`, `rating`, `created_at`) VALUES (@nr, 'Eastern Agro-Chem Traders', 'Loveness Phiri', '+260 977 226 508', 'sales@easternagrochem.example.com', 'Chipata Main Market, Chipata', 3.8, '2025-09-25 10:00:00');
SET @s_nr_chem = LAST_INSERT_ID();
INSERT INTO `suppliers` (`farm_id`, `supplier_name`, `contact_person`, `phone`, `email`, `address`, `rating`, `created_at`) VALUES (@nr, 'Kapata Seed Centre', 'Daniel Mwanza', '+260 966 713 044', 'seed@kapata.example.com', 'Kapata Road, Chipata', 4.6, '2025-09-25 10:00:00');
SET @s_nr_seed = LAST_INSERT_ID();
INSERT INTO `suppliers` (`farm_id`, `supplier_name`, `contact_person`, `phone`, `email`, `address`, `rating`, `created_at`) VALUES (@nr, 'Chipata Vet Clinic Supplies', 'Dr. Ruth Nkhoma', '+260 955 802 377', 'vet@chipatavet.example.com', 'Hospital Road, Chipata', 4.4, '2025-09-25 10:00:00');
SET @s_nr_vet = LAST_INSERT_ID();
INSERT INTO `suppliers` (`farm_id`, `supplier_name`, `contact_person`, `phone`, `email`, `address`, `rating`, `created_at`) VALUES (@nr, 'Mchini Fuel & Lubricants', 'Isaac Tembo', '+260 979 340 266', 'fuel@mchini.example.com', 'Mchini, Chipata', 3.6, '2025-09-25 10:00:00');
SET @s_nr_fuel = LAST_INSERT_ID();
INSERT INTO `suppliers` (`farm_id`, `supplier_name`, `contact_person`, `phone`, `email`, `address`, `rating`, `created_at`) VALUES (@vh, 'Kafue Irrigation & Pumps', 'Chola Mutale', '+260 211 312 770', 'service@kafuepumps.example.com', 'Industrial Area, Kafue', 4.5, '2025-09-25 10:00:00');
SET @s_vh_pumps = LAST_INSERT_ID();
INSERT INTO `suppliers` (`farm_id`, `supplier_name`, `contact_person`, `phone`, `email`, `address`, `rating`, `created_at`) VALUES (@vh, 'Riverside Feeds Kafue', 'Gift Hamweemba', '+260 977 640 155', 'orders@riversidefeeds.example.com', 'Kafue Estates Road, Kafue', 4.0, '2025-09-25 10:00:00');
SET @s_vh_feeds = LAST_INSERT_ID();
INSERT INTO `suppliers` (`farm_id`, `supplier_name`, `contact_person`, `phone`, `email`, `address`, `rating`, `created_at`) VALUES (@vh, 'Shimabala Agro Dealers', 'Precious Mweemba', '+260 966 284 931', 'shop@shimabala.example.com', 'Shimabala, Kafue Road', 4.2, '2025-09-25 10:00:00');
SET @s_vh_agro = LAST_INSERT_ID();
INSERT INTO `suppliers` (`farm_id`, `supplier_name`, `contact_person`, `phone`, `email`, `address`, `rating`, `created_at`) VALUES (@vh, 'Kafue Fish Feed Suppliers', 'Bernard Simwanza', '+260 955 917 402', 'fishfeed@kafue.example.com', 'Chanyanya Harbour, Kafue', 3.7, '2025-09-25 10:00:00');
SET @s_vh_fish = LAST_INSERT_ID();
INSERT INTO `suppliers` (`farm_id`, `supplier_name`, `contact_person`, `phone`, `email`, `address`, `rating`, `created_at`) VALUES (@vh, 'Chanyanya Fuel Point', 'Emmanuel Lungu', '+260 979 501 688', 'fuel@chanyanya.example.com', 'Chanyanya Road, Kafue', 3.9, '2025-09-25 10:00:00');
SET @s_vh_fuel = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Inventory items
-- --------------------------------------------------------------------------
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@gv, 'Maize seed SC 513 (10 kg)', 'seed', 'bags', 34.0, 10.0, '2025-09-28 09:00:00');
SET @it_gv_seed = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@gv, 'Soybean seed Kafue (25 kg)', 'seed', 'bags', 80.0, 20.0, '2025-09-28 09:00:00');
SET @it_gv_soyseed = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@gv, 'Compound D fertiliser (50 kg)', 'fertilizer', 'bags', 260.0, 80.0, '2025-09-28 09:00:00');
SET @it_gv_compd = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@gv, 'Urea 46% N (50 kg)', 'fertilizer', 'bags', 95.0, 60.0, '2025-09-28 09:00:00');
SET @it_gv_urea = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@gv, 'Emamectin benzoate 5% WG', 'chemical', 'kg', 2.0, 5.0, '2025-09-28 09:00:00');
SET @it_gv_emab = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@gv, 'Mancozeb 80% WP', 'chemical', 'kg', 40.0, 10.0, '2025-09-28 09:00:00');
SET @it_gv_mancozeb = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@gv, 'Dairy meal (50 kg)', 'feed', 'bags', 18.0, 25.0, '2025-09-28 09:00:00');
SET @it_gv_dairy = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@gv, 'Layers mash (50 kg)', 'feed', 'bags', 45.0, 20.0, '2025-09-28 09:00:00');
SET @it_gv_layers = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@gv, 'Newcastle disease vaccine (1000 doses)', 'medicine', 'vials', 6.0, 2.0, '2025-09-28 09:00:00');
SET @it_gv_ncd = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@gv, 'Ivermectin 1% injectable', 'medicine', 'L', 1.5, 1.0, '2025-09-28 09:00:00');
SET @it_gv_ivo = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@gv, 'Diesel', 'fuel', 'L', 3200.0, 1500.0, '2025-09-28 09:00:00');
SET @it_gv_diesel = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@gv, 'Grain bags (50 kg, woven)', 'packaging', 'units', 1800.0, 1000.0, '2025-09-28 09:00:00');
SET @it_gv_bags = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@gv, 'Egg trays (30 eggs)', 'packaging', 'units', 900.0, 500.0, '2025-09-28 09:00:00');
SET @it_gv_trays = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@nr, 'Maize seed PAN 53 (10 kg)', 'seed', 'bags', 12.0, 10.0, '2025-09-28 09:00:00');
SET @it_nr_seed = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@nr, 'Groundnut seed Chalimbana (shelled)', 'seed', 'kg', 2400.0, 500.0, '2025-09-28 09:00:00');
SET @it_nr_gnseed = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@nr, 'Compound D fertiliser (50 kg)', 'fertilizer', 'bags', 140.0, 60.0, '2025-09-28 09:00:00');
SET @it_nr_compd = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@nr, 'Urea 46% N (50 kg)', 'fertilizer', 'bags', 0.0, 20.0, '2025-09-28 09:00:00');
SET @it_nr_urea = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@nr, 'Lambda-cyhalothrin 5% EC', 'chemical', 'L', 14.0, 5.0, '2025-09-28 09:00:00');
SET @it_nr_lambda = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@nr, 'Imidacloprid 350 SC', 'chemical', 'L', 6.0, 2.0, '2025-09-28 09:00:00');
SET @it_nr_imid = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@nr, 'Pig grower pellets (50 kg)', 'feed', 'bags', 22.0, 10.0, '2025-09-28 09:00:00');
SET @it_nr_pigfeed = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@nr, 'Ivermectin 1% injectable', 'medicine', 'L', 2.0, 1.0, '2025-09-28 09:00:00');
SET @it_nr_ivo = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@nr, 'Diesel', 'fuel', 'L', 900.0, 800.0, '2025-09-28 09:00:00');
SET @it_nr_diesel = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@nr, 'Hand hoes', 'tool', 'units', 30.0, 10.0, '2025-09-28 09:00:00');
SET @it_nr_hoes = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@vh, 'Maize seed SC 513 (10 kg)', 'seed', 'bags', 20.0, 10.0, '2025-09-28 09:00:00');
SET @it_vh_seed = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@vh, 'NPK 10-20-10 (50 kg)', 'fertilizer', 'bags', 180.0, 60.0, '2025-09-28 09:00:00');
SET @it_vh_npk = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@vh, 'Ammonium nitrate 34.5% (50 kg)', 'fertilizer', 'bags', 75.0, 40.0, '2025-09-28 09:00:00');
SET @it_vh_an = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@vh, 'Abamectin 1.8% EC', 'chemical', 'L', 8.0, 3.0, '2025-09-28 09:00:00');
SET @it_vh_abam = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@vh, 'Mancozeb 80% WP', 'chemical', 'kg', 25.0, 10.0, '2025-09-28 09:00:00');
SET @it_vh_mancozeb = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@vh, 'Fish pellets 32% protein', 'feed', 'kg', 150.0, 500.0, '2025-09-28 09:00:00');
SET @it_vh_fish = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@vh, 'Cattle winter lick (50 kg)', 'feed', 'bags', 40.0, 15.0, '2025-09-28 09:00:00');
SET @it_vh_lick = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@vh, 'Anthrax & blackleg vaccine', 'medicine', 'doses', 60.0, 20.0, '2025-09-28 09:00:00');
SET @it_vh_vacc = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@vh, 'Diesel', 'fuel', 'L', 4100.0, 2000.0, '2025-09-28 09:00:00');
SET @it_vh_diesel = LAST_INSERT_ID();
INSERT INTO `inventory_items` (`farm_id`, `item_name`, `category`, `unit_of_measure`, `current_stock`, `reorder_threshold`, `created_at`) VALUES (@vh, 'Vegetable crates', 'packaging', 'units', 650.0, 300.0, '2025-09-28 09:00:00');
SET @it_vh_crates = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Inventory batches
-- --------------------------------------------------------------------------
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_gv_seed, @s_gv_agro, 'SC513-2610', 120.0, 34.0, 1150.0, '2026-10-05', '2027-09-30');
SET @b_gv_seed = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_gv_soyseed, @s_gv_agro, 'KAF-2609', 100.0, 80.0, 950.0, '2026-09-28', '2027-06-30');
SET @b_gv_soyseed = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_gv_compd, @s_gv_agro, 'CD-2610', 400.0, 260.0, 920.0, '2026-10-02', NULL);
SET @b_gv_compd = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_gv_urea, @s_gv_agro, 'UR-2610', 200.0, 95.0, 880.0, '2026-10-02', NULL);
SET @b_gv_urea = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_gv_emab, @s_gv_agro, 'EB-0525', 8.0, 2.0, 1450.0, '2026-05-20', '2027-05-20');
SET @b_gv_emab = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_gv_mancozeb, @s_gv_agro, 'MZ-2608', 50.0, 40.0, 145.0, '2026-08-12', '2028-08-01');
SET @b_gv_mancozeb = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_gv_dairy, @s_gv_feed, 'DM-2610', 60.0, 18.0, 620.0, '2026-10-01', '2027-01-15');
SET @b_gv_dairy = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_gv_layers, @s_gv_feed, 'LM-2610', 80.0, 45.0, 580.0, '2026-09-30', '2027-01-20');
SET @b_gv_layers = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_gv_ncd, @s_gv_vet, 'NCD-L4471', 10.0, 6.0, 320.0, '2026-06-15', '2026-11-20');
SET @b_gv_ncd = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_gv_ivo, @s_gv_vet, 'IVO-2604', 2.0, 1.5, 1800.0, '2026-04-02', '2027-12-31');
SET @b_gv_ivo = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_gv_diesel, @s_gv_fuel, 'GEF-102611', 5000.0, 3200.0, 27.4, '2026-10-26', NULL);
SET @b_gv_diesel = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_gv_bags, @s_gv_pack, 'KP-2603', 3000.0, 1800.0, 9.5, '2026-03-30', NULL);
SET @b_gv_bags = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_gv_trays, @s_gv_pack, 'KP-ET-2609', 1500.0, 900.0, 3.2, '2026-09-10', NULL);
SET @b_gv_trays = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_nr_seed, @s_nr_seed, 'PAN53-2610', 70.0, 12.0, 1050.0, '2026-10-12', '2027-09-30');
SET @b_nr_seed = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_nr_gnseed, @s_nr_seed, 'CHAL-2610', 3000.0, 2400.0, 38.0, '2026-10-20', '2027-03-31');
SET @b_nr_gnseed = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_nr_compd, @s_nr_depot, 'CD-E-2610', 250.0, 140.0, 945.0, '2026-10-14', NULL);
SET @b_nr_compd = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_nr_urea, @s_nr_depot, 'UR-E-2601', 120.0, 0.0, 870.0, '2026-01-06', NULL);
SET @b_nr_urea = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_nr_lambda, @s_nr_chem, 'LC-2609', 20.0, 14.0, 210.0, '2026-09-18', '2028-09-01');
SET @b_nr_lambda = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_nr_imid, @s_nr_chem, 'IM-2610', 8.0, 6.0, 640.0, '2026-10-03', '2028-10-01');
SET @b_nr_imid = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_nr_pigfeed, @s_nr_depot, 'PG-2610', 40.0, 22.0, 540.0, '2026-10-06', '2027-01-06');
SET @b_nr_pigfeed = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_nr_ivo, @s_nr_vet, 'IVO-E-2512', 3.0, 2.0, 1750.0, '2025-12-10', '2026-12-10');
SET @b_nr_ivo = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_nr_diesel, @s_nr_fuel, 'MF-2610', 2000.0, 900.0, 28.1, '2026-10-09', NULL);
SET @b_nr_diesel = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_nr_hoes, @s_nr_depot, 'HH-2609', 40.0, 30.0, 85.0, '2026-09-02', NULL);
SET @b_nr_hoes = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_vh_seed, @s_vh_agro, 'SC513-K-2610', 110.0, 20.0, 1160.0, '2026-10-06', '2027-09-30');
SET @b_vh_seed = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_vh_npk, @s_vh_agro, 'NPK-2609', 300.0, 180.0, 890.0, '2026-09-20', NULL);
SET @b_vh_npk = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_vh_an, @s_vh_agro, 'AN-2610', 150.0, 75.0, 860.0, '2026-10-10', NULL);
SET @b_vh_an = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_vh_abam, @s_vh_agro, 'AB-2609', 12.0, 8.0, 520.0, '2026-09-25', '2028-09-01');
SET @b_vh_abam = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_vh_mancozeb, @s_vh_agro, 'MZ-K-2410', 30.0, 5.0, 140.0, '2024-10-15', '2026-10-15');
SET @b_vh_mancozeb_old = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_vh_mancozeb, @s_vh_agro, 'MZ-K-2610', 25.0, 20.0, 150.0, '2026-10-18', '2028-10-01');
SET @b_vh_mancozeb = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_vh_fish, @s_vh_fish, 'FP32-2610', 1500.0, 150.0, 21.0, '2026-10-02', '2027-02-28');
SET @b_vh_fish = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_vh_lick, @s_vh_feeds, 'WL-2607', 60.0, 40.0, 480.0, '2026-07-12', '2027-07-12');
SET @b_vh_lick = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_vh_vacc, @s_vh_agro, 'ABV-2608', 100.0, 60.0, 18.0, '2026-08-01', '2027-02-01');
SET @b_vh_vacc = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_vh_diesel, @s_vh_fuel, 'CFP-2610', 6000.0, 4100.0, 27.2, '2026-10-20', NULL);
SET @b_vh_diesel = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_vh_crates, @s_vh_pumps, 'VC-2605', 800.0, 650.0, 45.0, '2026-05-15', NULL);
SET @b_vh_crates = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_gv_mancozeb, @s_gv_agro, 'MZ-2512', 50.0, 0.0, 138.0, '2025-12-10', '2027-12-01');
SET @b_gv_mancozeb25 = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_nr_lambda, @s_nr_chem, 'LC-2512', 20.0, 0.0, 198.0, '2025-12-05', '2027-12-01');
SET @b_nr_lambda25 = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_nr_imid, @s_nr_chem, 'IM-2601', 8.0, 0.0, 610.0, '2026-01-15', '2028-01-01');
SET @b_nr_imid25 = LAST_INSERT_ID();
INSERT INTO `inventory_batches` (`item_id`, `supplier_id`, `batch_number`, `quantity_received`, `quantity_remaining`, `cost_per_unit`, `purchase_date`, `expiry_date`) VALUES (@it_vh_abam, @s_vh_agro, 'AB-2603', 12.0, 0.0, 505.0, '2026-03-20', '2028-03-01');
SET @b_vh_abam26 = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Inventory transactions
-- --------------------------------------------------------------------------
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_gv_seed, 'stock_in', 120.0, NULL, NULL, '2026-10-05 10:00:00', @u_gv_mgr, 'Received from Lusaka Agro Inputs.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_gv_seed, 'stock_out', 86.0, NULL, NULL, '2026-10-24 07:00:00', @u_gv_w1, 'Issued for Pivot 1 planting.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_gv_compd, 'stock_in', 400.0, NULL, NULL, '2026-10-02 11:30:00', @u_gv_mgr, 'Season basal fertiliser.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_gv_compd, 'stock_out', 140.0, NULL, NULL, '2026-10-24 07:30:00', @u_gv_w1, 'Basal dressing, Pivot 1.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_gv_urea, 'stock_out', 105.0, NULL, NULL, '2026-10-18 08:00:00', @u_gv_w1, 'Top-dressing cabbage and tomatoes.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_gv_emab, 'stock_out', 6.0, NULL, NULL, '2026-10-29 06:30:00', @u_gv_agr, 'Tomato spray against Tuta.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_gv_dairy, 'stock_out', 42.0, NULL, NULL, '2026-10-31 17:00:00', @u_gv_w2, 'October dairy feeding.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_gv_ncd, 'stock_out', 4.0, NULL, NULL, '2026-09-20 07:00:00', @u_gv_w2, 'Layer flock vaccination.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_gv_diesel, 'stock_in', 5000.0, NULL, NULL, '2026-10-26 09:00:00', @u_gv_mgr, 'Bulk diesel delivery.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_gv_diesel, 'stock_out', 1800.0, NULL, NULL, '2026-11-01 16:00:00', @u_gv_w1, 'Planting and pivot pumps.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_gv_bags, 'adjustment', -60.0, NULL, NULL, '2026-07-01 12:00:00', @u_gv_acc, 'Stock count: 60 bags damaged by rats.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_gv_trays, 'stock_out', 600.0, NULL, NULL, '2026-10-30 15:00:00', @u_gv_w2, 'Egg packing, October.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_nr_seed, 'stock_in', 70.0, NULL, NULL, '2026-10-12 10:00:00', @u_nr_mgr, 'Seed for Lundazi Road Block.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_nr_seed, 'stock_out', 58.0, NULL, NULL, '2026-10-29 07:00:00', @u_nr_w1, 'Planting Lundazi Road Block.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_nr_gnseed, 'stock_in', 3000.0, NULL, NULL, '2026-10-20 14:00:00', @u_nr_mgr, 'Groundnut seed for November planting.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_nr_gnseed, 'stock_out', 600.0, NULL, NULL, '2026-10-25 09:00:00', @u_nr_w2, 'Seed sorted, damaged kernels removed.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_nr_compd, 'stock_out', 110.0, NULL, NULL, '2026-10-29 07:30:00', @u_nr_w1, 'Basal dressing maize.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_nr_urea, 'stock_out', 120.0, NULL, NULL, '2026-01-12 08:00:00', @u_nr_w1, 'Last season top-dressing - finished.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_nr_lambda, 'stock_out', 6.0, NULL, NULL, '2026-10-28 06:00:00', @u_nr_agr, 'Aphid spray on tobacco.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_nr_pigfeed, 'stock_out', 18.0, NULL, NULL, '2026-10-31 17:30:00', @u_nr_w2, 'October pig feeding.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_nr_diesel, 'stock_out', 1100.0, NULL, NULL, '2026-10-31 16:00:00', @u_nr_w1, 'Ploughing and planting.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_nr_hoes, 'return', 2.0, NULL, NULL, '2026-09-10 10:00:00', @u_nr_mgr, 'Returned two hoes with broken handles.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_vh_seed, 'stock_out', 90.0, NULL, NULL, '2026-10-19 07:00:00', @u_vh_w1, 'Riverside Pivot planting.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_vh_npk, 'stock_out', 120.0, NULL, NULL, '2026-10-19 07:30:00', @u_vh_w1, 'Basal NPK, Riverside Pivot.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_vh_an, 'stock_out', 75.0, NULL, NULL, '2026-10-30 08:00:00', @u_vh_w1, 'Sugarcane top-dressing.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_vh_abam, 'stock_out', 4.0, NULL, NULL, '2026-10-17 06:30:00', @u_vh_agr, 'Mite spray on tomatoes.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_vh_mancozeb_old, 'adjustment', -5.0, NULL, NULL, '2026-10-16 12:00:00', @u_vh_acc, 'Expired stock set aside for disposal.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_vh_fish, 'stock_in', 1500.0, NULL, NULL, '2026-10-02 11:00:00', @u_vh_mgr, 'Fish feed delivery.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_vh_fish, 'stock_out', 1350.0, NULL, NULL, '2026-11-01 17:00:00', @u_vh_w2, 'October pond feeding.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_vh_vacc, 'stock_out', 40.0, NULL, NULL, '2026-08-14 07:00:00', @u_vh_w2, 'Herd vaccination.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_vh_diesel, 'stock_out', 1900.0, NULL, NULL, '2026-11-02 16:00:00', @u_vh_w1, 'Planting and pumping.');
INSERT INTO `inventory_transactions` (`batch_id`, `transaction_type`, `quantity`, `reference_type`, `reference_id`, `transaction_date`, `performed_by`, `notes`) VALUES (@b_vh_crates, 'stock_out', 150.0, NULL, NULL, '2026-06-10 13:00:00', @u_vh_w2, 'Tomato harvest packing.');

-- --------------------------------------------------------------------------
-- Purchase orders
-- --------------------------------------------------------------------------
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@gv, @s_gv_agro, '2026-09-28', 552800.0, 'fulfilled', @john);
SET @po_gv1 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@gv, @s_gv_feed, '2026-09-30', 83600.0, 'fulfilled', @u_gv_mgr);
SET @po_gv2 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@gv, @s_gv_fuel, '2026-10-24', 137000.0, 'fulfilled', @u_gv_mgr);
SET @po_gv3 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@gv, @s_gv_vet, '2026-10-30', 6400.0, 'approved', @u_gv_mgr);
SET @po_gv4 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@gv, @s_gv_agro, '2026-11-02', 14500.0, 'requested', NULL);
SET @po_gv5 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@gv, @s_gv_pack, '2026-11-03', 12800.0, 'draft', NULL);
SET @po_gv6 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@nr, @s_nr_seed, '2026-10-10', 187500.0, 'fulfilled', @john);
SET @po_nr1 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@nr, @s_nr_depot, '2026-10-12', 236250.0, 'fulfilled', @u_nr_mgr);
SET @po_nr2 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@nr, @s_nr_chem, '2026-09-15', 9320.0, 'fulfilled', @u_nr_mgr);
SET @po_nr3 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@nr, @s_nr_depot, '2026-11-01', 52200.0, 'requested', NULL);
SET @po_nr4 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@nr, @s_nr_fuel, '2026-10-08', 56200.0, 'fulfilled', @u_nr_mgr);
SET @po_nr5 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@nr, @s_nr_vet, '2026-08-20', 4100.0, 'cancelled', NULL);
SET @po_nr6 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@vh, @s_vh_agro, '2026-09-18', 395600.0, 'fulfilled', @john);
SET @po_vh1 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@vh, @s_vh_fish, '2026-09-30', 31500.0, 'fulfilled', @u_vh_mgr);
SET @po_vh2 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@vh, @s_vh_fuel, '2026-10-18', 163200.0, 'fulfilled', @u_vh_mgr);
SET @po_vh3 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@vh, @s_vh_fish, '2026-11-02', 42000.0, 'approved', @u_vh_mgr);
SET @po_vh4 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@vh, @s_vh_pumps, '2026-10-27', 28500.0, 'approved', @john);
SET @po_vh5 = LAST_INSERT_ID();
INSERT INTO `purchase_orders` (`farm_id`, `supplier_id`, `order_date`, `total_amount`, `status`, `approved_by`) VALUES (@vh, @s_vh_feeds, '2026-11-03', 9600.0, 'draft', NULL);
SET @po_vh6 = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Livestock
-- --------------------------------------------------------------------------
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@gv, 'GV-B001', 'Cattle', 'Friesian', 'male', '2021-03-14', NULL, NULL, 'active');
SET @a_gv_bull = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@gv, 'GV-C001', 'Cattle', 'Friesian', 'female', '2020-08-02', NULL, NULL, 'active');
SET @a_gv_c1 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@gv, 'GV-C002', 'Cattle', 'Friesian', 'female', '2021-01-19', NULL, NULL, 'active');
SET @a_gv_c2 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@gv, 'GV-C003', 'Cattle', 'Jersey', 'female', '2021-06-25', NULL, NULL, 'active');
SET @a_gv_c3 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@gv, 'GV-C004', 'Cattle', 'Friesian x Jersey', 'female', '2022-02-11', NULL, NULL, 'active');
SET @a_gv_c4 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@gv, 'GV-C005', 'Cattle', 'Jersey', 'female', '2022-09-30', NULL, NULL, 'active');
SET @a_gv_c5 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@gv, 'GV-C006', 'Cattle', 'Friesian', 'female', '2019-11-05', NULL, NULL, 'sold');
SET @a_gv_c6 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@gv, 'GV-H007', 'Cattle', 'Friesian', 'female', '2025-07-18', @a_gv_bull, @a_gv_c1, 'active');
SET @a_gv_h1 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@gv, 'GV-H008', 'Cattle', 'Friesian', 'male', '2026-03-02', @a_gv_bull, @a_gv_c2, 'active');
SET @a_gv_h2 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@gv, 'GV-LAYERS-A', 'Poultry', 'Lohmann Brown layers (1,200 birds)', 'female', '2026-02-10', NULL, NULL, 'active');
SET @a_gv_flockA = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@gv, 'GV-LAYERS-B', 'Poultry', 'Hy-Line Brown layers (800 birds)', 'female', '2026-06-01', NULL, NULL, 'active');
SET @a_gv_flockB = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@nr, 'NR-B001', 'Cattle', 'Angoni', 'male', '2020-12-01', NULL, NULL, 'active');
SET @a_nr_bull = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@nr, 'NR-C001', 'Cattle', 'Angoni', 'female', '2019-10-10', NULL, NULL, 'active');
SET @a_nr_c1 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@nr, 'NR-C002', 'Cattle', 'Angoni', 'female', '2020-04-22', NULL, NULL, 'active');
SET @a_nr_c2 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@nr, 'NR-C003', 'Cattle', 'Angoni x Boran', 'female', '2021-09-14', NULL, NULL, 'active');
SET @a_nr_c3 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@nr, 'NR-OX01', 'Cattle', 'Angoni (draught ox)', 'male', '2018-05-05', NULL, NULL, 'active');
SET @a_nr_ox1 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@nr, 'NR-OX02', 'Cattle', 'Angoni (draught ox)', 'male', '2018-07-19', NULL, NULL, 'deceased');
SET @a_nr_ox2 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@nr, 'NR-G001', 'Goat', 'Boer', 'male', '2023-01-15', NULL, NULL, 'active');
SET @a_nr_g1 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@nr, 'NR-G002', 'Goat', 'Boer', 'female', '2023-03-02', NULL, NULL, 'active');
SET @a_nr_g2 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@nr, 'NR-G003', 'Goat', 'Boer x local', 'female', '2023-08-27', NULL, NULL, 'active');
SET @a_nr_g3 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@nr, 'NR-G004', 'Goat', 'Boer x local', 'female', '2024-02-09', NULL, NULL, 'active');
SET @a_nr_g4 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@nr, 'NR-G005', 'Goat', 'Boer', 'male', '2025-12-20', @a_nr_g1, @a_nr_g2, 'active');
SET @a_nr_g5 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@nr, 'NR-P001', 'Pig', 'Large White', 'female', '2024-05-11', NULL, NULL, 'active');
SET @a_nr_pig1 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@nr, 'NR-P002', 'Pig', 'Large White', 'female', '2024-06-03', NULL, NULL, 'active');
SET @a_nr_pig2 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@nr, 'NR-P003', 'Pig', 'Landrace', 'male', '2024-01-28', NULL, NULL, 'active');
SET @a_nr_pig3 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@nr, 'NR-P004', 'Pig', 'Large White x Landrace', 'male', '2026-04-15', @a_nr_pig3, @a_nr_pig1, 'sold');
SET @a_nr_pig4 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@vh, 'VH-B001', 'Cattle', 'Boran', 'male', '2020-02-17', NULL, NULL, 'active');
SET @a_vh_bull = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@vh, 'VH-C001', 'Cattle', 'Boran', 'female', '2019-09-08', NULL, NULL, 'active');
SET @a_vh_c1 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@vh, 'VH-C002', 'Cattle', 'Boran', 'female', '2020-11-23', NULL, NULL, 'active');
SET @a_vh_c2 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@vh, 'VH-C003', 'Cattle', 'Brahman', 'female', '2021-05-30', NULL, NULL, 'active');
SET @a_vh_c3 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@vh, 'VH-C004', 'Cattle', 'Boran', 'female', '2022-01-12', NULL, NULL, 'active');
SET @a_vh_c4 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@vh, 'VH-S005', 'Cattle', 'Boran x Brahman (steer)', 'male', '2024-08-03', @a_vh_bull, @a_vh_c1, 'active');
SET @a_vh_st1 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@vh, 'VH-S006', 'Cattle', 'Boran (steer)', 'male', '2024-09-21', @a_vh_bull, @a_vh_c2, 'sold');
SET @a_vh_st2 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@vh, 'VH-SH01', 'Sheep', 'Dorper', 'male', '2023-04-04', NULL, NULL, 'active');
SET @a_vh_sh1 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@vh, 'VH-SH02', 'Sheep', 'Dorper', 'female', '2023-06-16', NULL, NULL, 'active');
SET @a_vh_sh2 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@vh, 'VH-SH03', 'Sheep', 'Dorper', 'female', '2024-01-09', NULL, NULL, 'active');
SET @a_vh_sh3 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@vh, 'VH-SH04', 'Sheep', 'Dorper', 'female', '2025-10-30', @a_vh_sh1, @a_vh_sh2, 'active');
SET @a_vh_sh4 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@vh, 'VH-POND-1', 'Fish', 'Tilapia (O. andersonii), 4,000 fingerlings', 'female', '2026-05-10', NULL, NULL, 'active');
SET @a_vh_pond1 = LAST_INSERT_ID();
INSERT INTO `livestock` (`farm_id`, `tag_number`, `species`, `breed`, `gender`, `birth_date`, `sire_id`, `dam_id`, `status`) VALUES (@vh, 'VH-POND-2', 'Fish', 'Tilapia (O. macrochir), 3,000 fingerlings', 'female', '2026-07-01', NULL, NULL, 'active');
SET @a_vh_pond2 = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Livestock health records
-- --------------------------------------------------------------------------
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_gv_c1, 'vaccination', 'Lumpy skin disease', 'Annual LSD vaccine, 2 ml subcutaneous.', NULL, 2.0, 85.0, '2025-11-14', '2026-11-14');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_gv_c4, 'vaccination', 'Lumpy skin disease', 'Annual LSD vaccine.', NULL, 2.0, 85.0, '2025-10-20', '2026-10-20');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_gv_c2, 'treatment', 'Mastitis (left rear quarter)', 'Intramammary antibiotic for 3 days; milk withheld 4 days. Quarter clear on re-check.', NULL, 1.0, 320.0, '2026-10-05', NULL);
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_gv_c3, 'treatment', 'Internal parasites', 'Ivermectin injection.', @b_gv_ivo, 4.0, 60.0, '2026-09-12', '2027-03-12');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_gv_c5, 'disease_check', 'Pregnancy check - confirmed 4 months', 'Rectal palpation by vet.', NULL, NULL, 150.0, '2026-10-14', '2027-01-14');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_gv_flockA, 'vaccination', 'Newcastle disease', 'Drinking water vaccination, whole flock.', @b_gv_ncd, 2.0, 640.0, '2026-09-20', '2026-12-20');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_gv_flockB, 'vaccination', 'Newcastle disease and Gumboro', 'Eye-drop vaccination.', @b_gv_ncd, 2.0, 640.0, '2026-08-25', '2026-11-12');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_gv_h1, 'treatment', 'Ticks', 'Spray dip (amitraz) - weekly in the rains.', NULL, NULL, 25.0, '2026-10-30', '2026-11-06');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_nr_c1, 'vaccination', 'Anthrax and blackleg', 'Combined vaccine before the rains.', NULL, 2.0, 40.0, '2025-10-25', '2026-10-25');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_nr_c2, 'treatment', 'East Coast fever (corridor disease) suspected', 'Buparvaquone injection, isolated from herd; recovered.', NULL, 10.0, 950.0, '2026-02-14', NULL);
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_nr_c3, 'vaccination', 'Lumpy skin disease', 'Annual LSD vaccine.', NULL, 2.0, 85.0, '2026-03-10', '2027-03-10');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_nr_g2, 'treatment', 'Wireworm (pale eyelids, FAMACHA 4)', 'Deworming with ivermectin.', @b_nr_ivo, 1.0, 45.0, '2026-08-10', '2026-11-10');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_nr_g3, 'treatment', 'Foot rot', 'Hoof trimming and zinc sulphate foot bath.', NULL, NULL, 30.0, '2026-09-28', NULL);
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_nr_pig1, 'vaccination', 'Erysipelas', 'Sow vaccination before farrowing.', NULL, 2.0, 70.0, '2026-06-01', '2026-12-01');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_nr_pig2, 'disease_check', 'African swine fever screening', 'Blood sample to district vet - negative.', NULL, NULL, 200.0, '2026-09-05', NULL);
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_nr_bull, 'treatment', 'Ticks', 'Plunge dip.', NULL, NULL, 15.0, '2026-10-26', '2026-11-09');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_vh_c1, 'vaccination', 'Anthrax and blackleg', 'Combined vaccine (last season stock).', NULL, 2.0, 36.0, '2025-11-12', '2026-11-12');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_vh_c2, 'vaccination', 'Anthrax and blackleg', 'Combined vaccine.', @b_vh_vacc, 2.0, 36.0, '2026-08-14', '2027-08-14');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_vh_c3, 'vaccination', 'Foot and mouth disease', 'Government FMD campaign (Kafue district).', NULL, 2.0, 0.0, '2026-05-20', '2026-11-20');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_vh_c4, 'treatment', 'Heartwater', 'Oxytetracycline 20% injection, 5 days.', NULL, 15.0, 380.0, '2026-01-22', NULL);
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_vh_st1, 'disease_check', 'Weight check 395 kg', 'Weighbridge before finishing ration.', NULL, NULL, 0.0, '2026-10-01', '2026-12-01');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_vh_sh2, 'treatment', 'Internal parasites', 'Oral drench (albendazole).', NULL, 10.0, 25.0, '2026-07-15', '2026-10-15');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_vh_sh3, 'vaccination', 'Pulpy kidney (enterotoxaemia)', 'Annual booster.', NULL, 2.0, 20.0, '2026-04-12', '2027-04-12');
INSERT INTO `livestock_health_records` (`animal_id`, `record_type`, `diagnosis`, `treatment_details`, `batch_id`, `dosage`, `cost`, `administered_date`, `next_due_date`) VALUES (@a_vh_pond1, 'disease_check', 'Water quality and sampling', 'Dissolved oxygen low in the afternoon; aerator run 2 extra hours.', NULL, NULL, 0.0, '2026-10-20', '2026-11-20');

-- --------------------------------------------------------------------------
-- Livestock production
-- --------------------------------------------------------------------------
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c1, @gv, 'milk', 16.4, 'L', '2026-10-06');
SET @prod_milk_c1_0 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c3, @gv, 'milk', 10.2, 'L', '2026-10-06');
SET @prod_milk_c3_0 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c4, @gv, 'milk', 12.5, 'L', '2026-10-06');
SET @prod_milk_c4_0 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c5, @gv, 'milk', 10.2, 'L', '2026-10-06');
SET @prod_milk_c5_0 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c1, @gv, 'milk', 16.9, 'L', '2026-10-13');
SET @prod_milk_c1_1 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c2, @gv, 'milk', 15.3, 'L', '2026-10-13');
SET @prod_milk_c2_1 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c3, @gv, 'milk', 11.0, 'L', '2026-10-13');
SET @prod_milk_c3_1 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c4, @gv, 'milk', 13.6, 'L', '2026-10-13');
SET @prod_milk_c4_1 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c5, @gv, 'milk', 9.3, 'L', '2026-10-13');
SET @prod_milk_c5_1 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c1, @gv, 'milk', 15.1, 'L', '2026-10-20');
SET @prod_milk_c1_2 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c2, @gv, 'milk', 14.2, 'L', '2026-10-20');
SET @prod_milk_c2_2 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c3, @gv, 'milk', 12.0, 'L', '2026-10-20');
SET @prod_milk_c3_2 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c4, @gv, 'milk', 14.0, 'L', '2026-10-20');
SET @prod_milk_c4_2 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c5, @gv, 'milk', 10.0, 'L', '2026-10-20');
SET @prod_milk_c5_2 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c1, @gv, 'milk', 14.7, 'L', '2026-10-27');
SET @prod_milk_c1_3 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c2, @gv, 'milk', 14.5, 'L', '2026-10-27');
SET @prod_milk_c2_3 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c3, @gv, 'milk', 12.0, 'L', '2026-10-27');
SET @prod_milk_c3_3 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c4, @gv, 'milk', 13.7, 'L', '2026-10-27');
SET @prod_milk_c4_3 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c5, @gv, 'milk', 10.8, 'L', '2026-10-27');
SET @prod_milk_c5_3 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c1, @gv, 'milk', 15.4, 'L', '2026-11-01');
SET @prod_milk_c1_4 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c2, @gv, 'milk', 13.8, 'L', '2026-11-01');
SET @prod_milk_c2_4 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c3, @gv, 'milk', 11.7, 'L', '2026-11-01');
SET @prod_milk_c3_4 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c4, @gv, 'milk', 13.1, 'L', '2026-11-01');
SET @prod_milk_c4_4 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_c5, @gv, 'milk', 9.4, 'L', '2026-11-01');
SET @prod_milk_c5_4 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_flockA, @gv, 'eggs', 1011.0, 'count', '2026-10-04');
SET @prod_egg_a_0 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_flockB, @gv, 'eggs', 587.0, 'count', '2026-10-04');
SET @prod_egg_b_0 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_flockA, @gv, 'eggs', 1059.0, 'count', '2026-10-11');
SET @prod_egg_a_1 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_flockB, @gv, 'eggs', 578.0, 'count', '2026-10-11');
SET @prod_egg_b_1 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_flockA, @gv, 'eggs', 1016.0, 'count', '2026-10-18');
SET @prod_egg_a_2 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_flockB, @gv, 'eggs', 648.0, 'count', '2026-10-18');
SET @prod_egg_b_2 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_flockA, @gv, 'eggs', 1055.0, 'count', '2026-10-25');
SET @prod_egg_a_3 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_flockB, @gv, 'eggs', 566.0, 'count', '2026-10-25');
SET @prod_egg_b_3 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_flockA, @gv, 'eggs', 1013.0, 'count', '2026-11-01');
SET @prod_egg_a_4 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_gv_flockB, @gv, 'eggs', 690.0, 'count', '2026-11-01');
SET @prod_egg_b_4 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (NULL, @gv, 'manure', 6.5, 't', '2026-10-15');
SET @prod_gv_manure = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_nr_pig4, @nr, 'meat', 92.0, 'kg', '2026-09-18');
SET @prod_nr_pig = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (NULL, @nr, 'meat', 64.0, 'kg', '2026-08-30');
SET @prod_nr_goatmeat = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (NULL, @nr, 'manure', 3.2, 't', '2026-10-20');
SET @prod_nr_manure = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_nr_c1, @nr, 'milk', 4.5, 'L', '2026-10-28');
SET @prod_nr_milk = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_vh_pond1, @vh, 'meat', 640.0, 'kg', '2026-10-12');
SET @prod_vh_fish1 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_vh_pond1, @vh, 'meat', 410.0, 'kg', '2026-10-26');
SET @prod_vh_fish2 = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (@a_vh_st2, @vh, 'meat', 238.0, 'kg', '2026-09-06');
SET @prod_vh_beef = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (NULL, @vh, 'meat', 48.0, 'kg', '2026-10-03');
SET @prod_vh_mutton = LAST_INSERT_ID();
INSERT INTO `livestock_production_logs` (`animal_id`, `farm_id`, `production_type`, `quantity`, `unit`, `logged_date`) VALUES (NULL, @vh, 'manure', 4.8, 't', '2026-10-18');
SET @prod_vh_manure = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Livestock feeding
-- --------------------------------------------------------------------------
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@gv, 'Cattle', @b_gv_dairy, 8.0, '2026-10-05');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@gv, 'Poultry', @b_gv_layers, 9.4, '2026-10-05');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@vh, 'Fish', @b_vh_fish, 263.0, '2026-10-05');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@gv, 'Cattle', @b_gv_dairy, 8.8, '2026-10-12');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@gv, 'Poultry', @b_gv_layers, 9.0, '2026-10-12');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@vh, 'Fish', @b_vh_fish, 263.0, '2026-10-12');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@gv, 'Cattle', @b_gv_dairy, 8.2, '2026-10-19');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@gv, 'Poultry', @b_gv_layers, 8.3, '2026-10-19');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@vh, 'Fish', @b_vh_fish, 270.0, '2026-10-19');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@gv, 'Cattle', @b_gv_dairy, 7.4, '2026-10-26');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@gv, 'Poultry', @b_gv_layers, 9.2, '2026-10-26');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@vh, 'Fish', @b_vh_fish, 263.0, '2026-10-26');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@gv, 'Cattle', @b_gv_dairy, 7.5, '2026-11-02');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@gv, 'Poultry', @b_gv_layers, 9.4, '2026-11-02');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@vh, 'Fish', @b_vh_fish, 267.0, '2026-11-02');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@nr, 'Pig', @b_nr_pigfeed, 4.0, '2026-10-07');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@nr, 'Pig', @b_nr_pigfeed, 4.6, '2026-10-14');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@nr, 'Pig', @b_nr_pigfeed, 4.2, '2026-10-21');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@nr, 'Pig', @b_nr_pigfeed, 4.6, '2026-10-28');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@vh, 'Cattle', @b_vh_lick, 11.0, '2026-10-09');
INSERT INTO `livestock_feed_logs` (`farm_id`, `species`, `batch_id`, `quantity_used`, `feeding_date`) VALUES (@vh, 'Cattle', @b_vh_lick, 9.0, '2026-10-23');

-- --------------------------------------------------------------------------
-- Machinery
-- --------------------------------------------------------------------------
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@gv, 'Massey Ferguson 385', 'Tractor', 'MF385-ZM-11872', 685000.0, '2019-02-20', 3860.0, 'operational');
SET @m_gv_mf = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@gv, 'John Deere 5503', 'Tractor', 'JD5503-PY4410', 742000.0, '2021-08-11', 2140.0, 'operational');
SET @m_gv_jd = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@gv, 'Boom sprayer 600 L', 'Sprayer', 'BS600-GV-0193', 68000.0, '2022-09-01', 410.0, 'operational');
SET @m_gv_spr = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@gv, 'Grundfos borehole pump', 'Pump', 'GF-SP17-88231', 54000.0, '2023-03-15', 6120.0, 'operational');
SET @m_gv_pump = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@gv, 'Diesel generator 20 kVA', 'Generator', 'GEN20-PK-55120', 96000.0, '2020-06-30', 1980.0, 'operational');
SET @m_gv_gen = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@gv, 'Toyota Hilux farm bakkie', 'Vehicle', 'AHU-LSK-3341', 455000.0, '2020-01-10', 7400.0, 'operational');
SET @m_gv_bakkie = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@gv, 'Disc harrow 20-disc', 'Implement', 'DH20-BAL-7712', 58000.0, '2019-03-02', 1620.0, 'under_maintenance');
SET @m_gv_disc = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@nr, 'Massey Ferguson 290', 'Tractor', 'MF290-CP-30418', 410000.0, '2016-09-14', 6120.0, 'operational');
SET @m_nr_mf = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@nr, 'Knapsack sprayers (set of 6)', 'Sprayer', 'KN16-CP-SET06', 9000.0, '2025-10-01', 310.0, 'operational');
SET @m_nr_knap = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@nr, 'Maize sheller', 'Harvester', 'MS-CP-2219', 42000.0, '2022-04-20', 520.0, 'operational');
SET @m_nr_sheller = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@nr, 'Ox-drawn ripper', 'Implement', 'RIP-OX-0045', 3500.0, '2021-10-05', 380.0, 'operational');
SET @m_nr_ripper = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@nr, 'Generator 10 kVA (tobacco barn)', 'Generator', 'GEN10-CP-11458', 48000.0, '2021-11-12', 2640.0, 'under_maintenance');
SET @m_nr_gen = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@nr, 'Honda XR150 motorbike', 'Vehicle', 'MBK-CP-7781', 32000.0, '2023-05-08', 2150.0, 'operational');
SET @m_nr_moto = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@vh, 'New Holland TT75', 'Tractor', 'NHTT75-KF-22903', 690000.0, '2022-03-03', 2245.0, 'operational');
SET @m_vh_nh = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@vh, 'Pivot pump set (river intake)', 'Pump', 'PPS-KF-40018', 186000.0, '2023-05-01', 4380.0, 'operational');
SET @m_vh_pivpump = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@vh, 'Claas Dominator combine', 'Harvester', 'CLD-KF-98217', 1250000.0, '2015-07-22', 5120.0, 'out_of_service');
SET @m_vh_combine = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@vh, 'Generator 50 kVA', 'Generator', 'GEN50-KF-70334', 210000.0, '2022-11-18', 1560.0, 'operational');
SET @m_vh_gen = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@vh, 'Isuzu FTR 7-tonne truck', 'Vehicle', 'ISZ-KF-5520', 980000.0, '2021-02-02', 9100.0, 'operational');
SET @m_vh_truck = LAST_INSERT_ID();
INSERT INTO `machinery` (`farm_id`, `name`, `type`, `serial_number`, `purchase_price`, `purchase_date`, `current_operating_hours`, `status`) VALUES (@vh, 'Fish pond aerator', 'Pump', 'AER-KF-0091', 18500.0, '2025-04-04', 2900.0, 'operational');
SET @m_vh_aer = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Machinery maintenance
-- --------------------------------------------------------------------------
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_gv_mf, 'routine', '2026-06-02', 3560.0, 'Engine oil, oil filter, fuel filters; greased all points.', 4850.0, 3810.0);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_gv_mf, 'repair', '2026-09-14', 3740.0, 'Replaced leaking hydraulic hose.', 2300.0, NULL);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_gv_jd, 'routine', '2026-09-20', 2050.0, '250-hour service.', 5200.0, 2300.0);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_gv_spr, 'routine', '2026-08-30', 330.0, 'Nozzles replaced, pump diaphragm checked, calibrated.', 1650.0, 430.0);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_gv_pump, 'inspection', '2026-07-05', 5700.0, 'Pressure and amps checked; bearings OK.', 900.0, 6200.0);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_gv_gen, 'routine', '2026-08-18', 1850.0, 'Oil and air filter changed.', 1400.0, 2050.0);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_gv_bakkie, 'routine', '2026-10-02', 7250.0, 'Minor service and brake pads.', 6800.0, 7550.0);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_gv_disc, 'repair', '2026-10-28', 1620.0, 'Replacing worn disc bearings (in progress).', 3900.0, NULL);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_nr_mf, 'routine', '2026-08-10', 5950.0, 'Oil service, clutch adjusted.', 4200.0, 6200.0);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_nr_sheller, 'routine', '2026-04-20', 450.0, 'Belts and sieve replaced before harvest.', 1800.0, 650.0);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_nr_gen, 'repair', '2026-10-30', 2640.0, 'AVR failed - sent to Chipata for repair.', 2600.0, NULL);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_nr_moto, 'routine', '2026-09-01', 2000.0, 'Oil change and chain.', 450.0, 2300.0);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_nr_knap, 'inspection', '2026-10-20', 300.0, 'Seals and lances checked before the season.', 300.0, 400.0);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_vh_nh, 'routine', '2026-07-28', 2000.0, '250-hour service.', 5400.0, 2250.0);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_vh_combine, 'repair', '2026-09-28', 5120.0, 'Threshing drum bearing failed; part ordered from Lusaka.', 18500.0, NULL);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_vh_gen, 'routine', '2026-09-05', 1450.0, 'Service and load test.', 2100.0, 1650.0);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_vh_truck, 'routine', '2026-08-15', 8800.0, 'Full service, tyres rotated.', 9600.0, 9300.0);
INSERT INTO `machinery_maintenance` (`machinery_id`, `maintenance_type`, `service_date`, `operating_hours_at_service`, `description`, `cost`, `next_service_due_hours`) VALUES (@m_vh_aer, 'inspection', '2026-10-01', 2750.0, 'Paddle wheel bearings greased.', 350.0, 3250.0);

-- --------------------------------------------------------------------------
-- Machinery usage
-- --------------------------------------------------------------------------
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_gv_mf, @f_gv_p1, @u_gv_w1, '2026-10-25', 9.5, 62.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_gv_mf, @f_gv_p1, @u_gv_w1, '2026-10-26', 10.0, 66.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_gv_mf, @f_gv_p1, @u_gv_w1, '2026-10-27', 8.0, 51.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_gv_mf, @f_gv_p1, @u_gv_w1, '2026-10-31', 6.0, 40.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_gv_jd, @f_gv_bb, @u_gv_w1, '2026-10-20', 8.0, 47.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_gv_jd, @f_gv_bb, @u_gv_w1, '2026-10-22', 9.0, 52.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_gv_jd, @f_gv_bb, @u_gv_w1, '2026-10-29', 7.5, 44.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_gv_spr, @f_gv_vg, @u_gv_w1, '2026-10-28', 2.5, 6.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_gv_spr, @f_gv_vg, @u_gv_w1, '2026-11-02', 3.0, 7.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_gv_bakkie, NULL, @u_gv_mgr, '2026-10-24', 4.0, 22.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_gv_bakkie, NULL, @u_gv_mgr, '2026-11-01', 3.0, 18.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_gv_gen, NULL, @u_gv_w2, '2026-10-30', 6.0, 21.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_nr_mf, @f_nr_lr, @u_nr_w1, '2026-10-23', 9.0, 70.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_nr_mf, @f_nr_lr, @u_nr_w1, '2026-10-24', 9.5, 74.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_nr_mf, @f_nr_lr, @u_nr_w1, '2026-10-28', 8.0, 61.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_nr_mf, @f_nr_lr, @u_nr_w1, '2026-10-29', 7.0, 55.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_nr_mf, @f_nr_gn, @u_nr_w1, '2026-11-01', 6.0, 45.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_nr_knap, @f_nr_tb, @u_nr_w2, '2026-10-28', 5.0, NULL);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_nr_knap, @f_nr_tb, @u_nr_w2, '2026-11-02', 4.0, NULL);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_nr_moto, NULL, @u_nr_mgr, '2026-10-26', 3.0, 5.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_nr_moto, NULL, @u_nr_mgr, '2026-10-31', 2.5, 4.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_vh_nh, @f_vh_rp, @u_vh_w1, '2026-10-18', 8.0, 50.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_vh_nh, @f_vh_rp, @u_vh_w1, '2026-10-19', 9.0, 55.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_vh_nh, @f_vh_rp, @u_vh_w1, '2026-10-20', 7.0, 43.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_vh_nh, @f_vh_sc, @u_vh_w1, '2026-10-30', 6.0, 39.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_vh_pivpump, @f_vh_rp, @u_vh_w1, '2026-10-27', 12.0, 58.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_vh_pivpump, @f_vh_rp, @u_vh_w1, '2026-10-31', 12.0, 60.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_vh_pivpump, @f_vh_rp, @u_vh_w1, '2026-11-02', 10.0, 49.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_vh_truck, NULL, @u_vh_mgr, '2026-10-25', 5.0, 41.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_vh_truck, NULL, @u_vh_mgr, '2026-11-01', 6.0, 50.0);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_vh_aer, NULL, @u_vh_w2, '2026-10-29', 10.0, NULL);
INSERT INTO `machinery_usage` (`machinery_id`, `field_id`, `driver_id`, `date_used`, `hours_worked`, `fuel_consumed_liters`) VALUES (@m_vh_aer, NULL, @u_vh_w2, '2026-11-01', 12.0, NULL);

-- --------------------------------------------------------------------------
-- Employees
-- --------------------------------------------------------------------------
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@gv, @u_gv_mgr, 'Mwansa', 'Banda', '214563/10/1', 'Farm Manager', 'permanent', 650.0, '2025-09-15');
SET @e_gv_mgr = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@gv, @u_gv_agr, 'Chipo', 'Mulenga', '388120/11/1', 'Agronomist', 'permanent', 520.0, '2025-09-15');
SET @e_gv_agr = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@gv, @u_gv_acc, 'Bwalya', 'Chanda', '402771/61/1', 'Accounts Officer', 'permanent', 480.0, '2025-10-01');
SET @e_gv_acc = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@gv, @u_gv_w1, 'Joseph', 'Phiri', '119034/31/1', 'Tractor Driver', 'permanent', 260.0, '2025-09-20');
SET @e_gv_w1 = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@gv, @u_gv_w2, 'Ruth', 'Zulu', '276590/10/1', 'Dairy & Poultry Hand', 'permanent', 230.0, '2025-09-20');
SET @e_gv_w2 = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@gv, NULL, 'Lazarus', 'Mumba', '501288/10/1', 'General Hand', 'casual', 150.0, '2026-10-01');
SET @e_gv_c1 = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@gv, NULL, 'Memory', 'Sakala', '533019/10/1', 'Picker', 'casual', 140.0, '2026-10-15');
SET @e_gv_c2 = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@nr, @u_nr_mgr, 'Grace', 'Tembo', '308845/51/1', 'Farm Manager', 'permanent', 600.0, '2025-09-15');
SET @e_nr_mgr = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@nr, @u_nr_agr, 'Peter', 'Mbewe', '297113/51/1', 'Agronomist', 'contract', 500.0, '2025-11-01');
SET @e_nr_agr = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@nr, @u_nr_acc, 'Esther', 'Daka', '415562/51/1', 'Bookkeeper', 'permanent', 420.0, '2025-10-01');
SET @e_nr_acc = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@nr, @u_nr_w1, 'Moses', 'Ngoma', '166720/51/1', 'Tractor Driver', 'permanent', 240.0, '2025-09-20');
SET @e_nr_w1 = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@nr, @u_nr_w2, 'Agnes', 'Lungu', '254908/51/1', 'Livestock Hand', 'permanent', 210.0, '2025-09-20');
SET @e_nr_w2 = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@nr, NULL, 'Jacob', 'Mwale', '612490/51/1', 'Tobacco Grader', 'casual', 160.0, '2026-02-01');
SET @e_nr_c1 = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@nr, NULL, 'Febby', 'Zimba', '630177/51/1', 'General Hand', 'casual', 130.0, '2026-10-20');
SET @e_nr_c2 = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@vh, @u_vh_mgr, 'Kelvin', 'Mwale', '322764/10/1', 'Farm Manager', 'permanent', 640.0, '2025-09-15');
SET @e_vh_mgr = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@vh, @u_vh_agr, 'Natasha', 'Siame', '377802/76/1', 'Agronomist', 'permanent', 520.0, '2025-10-01');
SET @e_vh_agr = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@vh, @u_vh_acc, 'Brian', 'Hamoonga', '420916/76/1', 'Accounts Officer', 'contract', 450.0, '2025-10-01');
SET @e_vh_acc = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@vh, @u_vh_w1, 'Mutale', 'Kapembwa', '188342/76/1', 'Irrigation Operator', 'permanent', 260.0, '2025-09-20');
SET @e_vh_w1 = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@vh, @u_vh_w2, 'Charity', 'Muleya', '265071/76/1', 'Fish & Livestock Hand', 'permanent', 230.0, '2025-09-20');
SET @e_vh_w2 = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@vh, NULL, 'Godfrey', 'Hachinene', '541336/76/1', 'Cane Cutter', 'casual', 150.0, '2026-08-01');
SET @e_vh_c1 = LAST_INSERT_ID();
INSERT INTO `employees` (`farm_id`, `user_id`, `first_name`, `last_name`, `national_id`, `designation`, `employment_type`, `daily_rate`, `hire_date`) VALUES (@vh, NULL, 'Loveness', 'Moonga', '558720/76/1', 'Packhouse Hand', 'casual', 140.0, '2026-05-15');
SET @e_vh_c2 = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Tasks
-- --------------------------------------------------------------------------
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@gv, @f_gv_p1, 'Plant maize on Pivot 1', 'SC 513 at 53,000 plants/ha with Compound D basal.', 'Planting', '2026-10-23', '2026-10-27', 'completed');
SET @t_gv1 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@gv, @f_gv_vg, 'Spray tomatoes for Tuta absoluta', 'Rotate to a different chemical group from the last spray; check traps.', 'Spraying', '2026-10-29', '2026-11-01', 'in_progress');
SET @t_gv2 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@gv, @f_gv_ba, 'Weed and top-dress cabbage', 'Urea at 100 kg/ha after weeding.', 'Weeding', '2026-10-15', '2026-10-18', 'completed');
SET @t_gv3 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@gv, @f_gv_pd, 'Vaccinate dairy herd (LSD)', 'GV-C001 and GV-C004 are due.', 'Livestock', '2026-10-20', '2026-10-31', 'pending');
SET @t_gv4 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@gv, @f_gv_bb, 'Lime Block B before planting', '2 t/ha dolomitic lime, pH is 5.1.', 'Land preparation', '2026-11-05', '2026-11-15', 'pending');
SET @t_gv5 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@gv, @f_gv_p2, 'Plant soybean on Pivot 2', 'Inoculate seed just before planting.', 'Planting', '2026-11-18', '2026-11-22', 'pending');
SET @t_gv6 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@nr, @f_nr_lr, 'Plant maize - Lundazi Road Block', 'PAN 53 at 44,000 plants/ha.', 'Planting', '2026-10-28', '2026-10-31', 'completed');
SET @t_nr1 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@nr, @f_nr_lr, 'Gap-fill and cutworm control', 'Replant cut seedlings; bait along the eastern rows.', 'Planting', '2026-11-03', '2026-11-06', 'pending');
SET @t_nr2 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@nr, @f_nr_tb, 'Record tobacco growth and scout', 'No growth log since transplanting.', 'Scouting', '2026-10-25', '2026-10-30', 'pending');
SET @t_nr3 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@nr, @f_nr_gn, 'Prepare groundnut seedbed', 'Ridges at 45 cm; sort seed.', 'Land preparation', '2026-11-10', '2026-11-25', 'pending');
SET @t_nr4 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@nr, NULL, 'Repair barn generator', 'Collect from Chipata once the AVR is fixed.', 'Maintenance', '2026-10-30', '2026-11-08', 'in_progress');
SET @t_nr5 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@nr, @f_nr_ct, 'Uproot last season cotton stalks', 'Required by the closed season rules.', 'Land preparation', '2026-08-01', '2026-08-31', 'completed');
SET @t_nr6 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@vh, @f_vh_dg, 'Lift and cure onions', 'Lift when 70% of necks have fallen; cure in shade 10 days.', 'Harvesting', '2026-11-06', '2026-11-12', 'pending');
SET @t_vh1 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@vh, @f_vh_rp, 'Top-dress maize on Riverside Pivot', 'AN at 150 kg/ha at V6.', 'Fertilising', '2026-11-08', '2026-11-12', 'pending');
SET @t_vh2 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@vh, @f_vh_sc, 'Clean sugarcane furrows', 'Remove weeds and silt from furrows.', 'Weeding', '2026-10-26', '2026-10-30', 'completed');
SET @t_vh3 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@vh, @f_vh_gc, 'Repair grazing camp sprinklers', 'Two risers broken; pump pressure low.', 'Maintenance', '2026-10-20', '2026-10-28', 'in_progress');
SET @t_vh4 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@vh, NULL, 'Harvest fish from Pond 1', 'Partial harvest of table-size fish for Kafue market.', 'Harvesting', '2026-10-25', '2026-10-26', 'completed');
SET @t_vh5 = LAST_INSERT_ID();
INSERT INTO `task_allocations` (`farm_id`, `field_id`, `title`, `description`, `task_type`, `start_date`, `due_date`, `status`) VALUES (@vh, @f_vh_kf, 'Plough Kafue Flats Block for sorghum', 'Only once the ground can carry the tractor.', 'Land preparation', '2026-11-25', '2026-12-05', 'cancelled');
SET @t_vh6 = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Labour
-- --------------------------------------------------------------------------
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_gv1, @e_gv_w1, 9.0, '2026-10-24', 292.5);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_gv1, @e_gv_w1, 10.0, '2026-10-25', 325.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_gv1, @e_gv_c1, 8.0, '2026-10-25', 150.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_gv1, @e_gv_c2, 8.0, '2026-10-26', 140.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_gv2, @e_gv_agr, 3.0, '2026-10-29', 195.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_gv2, @e_gv_c1, 6.0, '2026-10-30', 112.5);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_gv3, @e_gv_c1, 8.0, '2026-10-16', 150.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_gv3, @e_gv_c2, 8.0, '2026-10-16', 140.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_gv3, @e_gv_w2, 4.0, '2026-10-17', 115.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_nr1, @e_nr_w1, 9.0, '2026-10-29', 270.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_nr1, @e_nr_w2, 8.0, '2026-10-29', 210.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_nr1, @e_nr_c2, 8.0, '2026-10-30', 130.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_nr5, @e_nr_mgr, 2.0, '2026-10-30', 150.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_nr6, @e_nr_c1, 8.0, '2026-08-12', 160.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_nr6, @e_nr_c2, 8.0, '2026-08-13', 130.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_nr6, @e_nr_w1, 6.0, '2026-08-14', 180.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_vh3, @e_vh_c1, 8.0, '2026-10-27', 150.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_vh3, @e_vh_c1, 8.0, '2026-10-28', 150.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_vh3, @e_vh_w1, 5.0, '2026-10-28', 162.5);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_vh4, @e_vh_w1, 4.0, '2026-10-22', 130.0);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_vh5, @e_vh_w2, 7.0, '2026-10-26', 201.25);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_vh5, @e_vh_c2, 7.0, '2026-10-26', 122.5);
INSERT INTO `labor_assignments` (`task_id`, `employee_id`, `hours_worked`, `date_performed`, `labor_cost`) VALUES (@t_vh5, @e_vh_mgr, 3.0, '2026-10-26', 240.0);

-- --------------------------------------------------------------------------
-- Scouting
-- --------------------------------------------------------------------------
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_gv_vg, @u_gv_agr, '2026-10-28', @c_tuta, 'high', 30.0, NULL, 'Mines on upper leaves of most plants; about 1 in 10 fruit holed.');
SET @sc_gv_tuta = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_gv_vg, @u_gv_agr, '2026-10-14', @c_tuta, 'moderate', 12.0, NULL, 'First mines found; pheromone trap catching 15 moths/day.');
SET @sc_gv_tuta0 = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_gv_ba, @u_gv_agr, '2026-10-21', @c_dbm, 'moderate', 15.0, NULL, 'Larvae on outer cabbage leaves.');
SET @sc_gv_dbm = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_gv_p2, @u_gv_agr, '2026-08-01', @c_aphid, 'low', 5.0, NULL, 'Aphids on wheat flag leaves; ladybirds present.');
SET @sc_gv_aph = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_gv_p1, @u_gv_w1, '2026-11-01', @c_cutworm, 'low', 2.0, NULL, 'A few cut seedlings near the pivot centre.');
SET @sc_gv_cut = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_gv_bb, @u_gv_agr, '2026-02-18', @c_rust, 'moderate', 20.0, NULL, 'Rust pustules on lower soybean leaves.');
SET @sc_gv_rust = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_nr_lr, @u_nr_agr, '2026-11-02', @c_cutworm, 'moderate', 8.0, NULL, 'Seedlings cut at ground level on the eastern rows.');
SET @sc_nr_cut = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_nr_tb, @u_nr_agr, '2026-10-27', @c_aphid, 'moderate', 18.0, NULL, 'Aphid colonies under tobacco leaves.');
SET @sc_nr_aph = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_nr_hf, @u_nr_agr, '2026-09-12', @c_termite, 'low', 4.0, NULL, 'Termite mounds active along the field edge.');
SET @sc_nr_term = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_nr_lr, @u_nr_agr, '2026-03-05', @c_striga, 'moderate', 10.0, NULL, 'Striga flowering among maize rows.');
SET @sc_nr_striga = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_nr_lr, @u_nr_agr, '2026-01-10', @c_faw, 'severe', 25.0, NULL, 'Fresh whorl damage on a quarter of plants.');
SET @sc_nr_faw = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_nr_lr, @u_nr_mgr, '2026-08-20', @c_lgb, 'high', 0.0, NULL, 'Larger grain borer found in the temporary maize store.');
SET @sc_nr_lgb = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_vh_dg, @u_vh_agr, '2026-10-15', @c_mite, 'moderate', 14.0, NULL, 'Webbing and speckling on lower tomato leaves after hot dry week.');
SET @sc_vh_mite = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_vh_dg, @u_vh_agr, '2026-10-31', @c_mite, 'low', 3.0, NULL, 'Mites mostly gone after spraying.');
SET @sc_vh_mite2 = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_vh_dg, @u_vh_agr, '2026-11-02', @c_lateblight, 'moderate', 6.0, NULL, 'Dark patches on a few tomato plants after the first humid days.');
SET @sc_vh_blight = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_vh_rp, @u_vh_mgr, '2026-09-05', @c_quelea, 'high', 15.0, NULL, 'Quelea flocks on ripening wheat near the river.');
SET @sc_vh_quelea = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_vh_rp, @u_vh_w1, '2026-11-01', @c_blackjack, 'low', 10.0, NULL, 'Blackjack coming up between maize rows.');
SET @sc_vh_bkj = LAST_INSERT_ID();
INSERT INTO `scouting_records` (`field_id`, `scout_id`, `scout_date`, `catalog_id`, `severity_level`, `affected_area_pct`, `image_url`, `notes`) VALUES (@f_vh_dg, @u_vh_agr, '2026-05-10', @c_wilt, 'moderate', 4.0, NULL, 'A few tomato plants wilted with brown stems; removed.');
SET @sc_vh_wilt = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Chemical applications
-- --------------------------------------------------------------------------
INSERT INTO `chemical_applications` (`scouting_id`, `planting_id`, `batch_id`, `application_date`, `dosage_per_ha`, `total_chemical_used`, `effectiveness`) VALUES (@sc_gv_tuta0, @p_gv_tom, @b_gv_emab, '2026-10-16', 0.25, 1.25, 'partially_effective');
INSERT INTO `chemical_applications` (`scouting_id`, `planting_id`, `batch_id`, `application_date`, `dosage_per_ha`, `total_chemical_used`, `effectiveness`) VALUES (@sc_gv_dbm, @p_gv_cab, @b_gv_emab, '2026-10-22', 0.25, 2.5, 'effective');
INSERT INTO `chemical_applications` (`scouting_id`, `planting_id`, `batch_id`, `application_date`, `dosage_per_ha`, `total_chemical_used`, `effectiveness`) VALUES (NULL, @p_gv_tom, @b_gv_mancozeb, '2026-10-05', 2.0, 10.0, 'effective');
INSERT INTO `chemical_applications` (`scouting_id`, `planting_id`, `batch_id`, `application_date`, `dosage_per_ha`, `total_chemical_used`, `effectiveness`) VALUES (@sc_gv_rust, @p_gv_soy25, @b_gv_mancozeb25, '2026-02-20', 2.0, 160.0, 'partially_effective');
INSERT INTO `chemical_applications` (`scouting_id`, `planting_id`, `batch_id`, `application_date`, `dosage_per_ha`, `total_chemical_used`, `effectiveness`) VALUES (@sc_gv_tuta, @p_gv_tom, @b_gv_emab, '2026-10-29', 0.25, 1.25, 'pending');
INSERT INTO `chemical_applications` (`scouting_id`, `planting_id`, `batch_id`, `application_date`, `dosage_per_ha`, `total_chemical_used`, `effectiveness`) VALUES (NULL, @p_gv_cab, @b_gv_mancozeb, '2026-10-08', 2.0, 20.0, 'effective');
INSERT INTO `chemical_applications` (`scouting_id`, `planting_id`, `batch_id`, `application_date`, `dosage_per_ha`, `total_chemical_used`, `effectiveness`) VALUES (@sc_nr_aph, @p_nr_tob, @b_nr_lambda, '2026-10-28', 0.4, 5.6, 'partially_effective');
INSERT INTO `chemical_applications` (`scouting_id`, `planting_id`, `batch_id`, `application_date`, `dosage_per_ha`, `total_chemical_used`, `effectiveness`) VALUES (@sc_nr_faw, @p_nr_maize25, @b_nr_lambda25, '2026-01-12', 0.3, 17.4, 'ineffective');
INSERT INTO `chemical_applications` (`scouting_id`, `planting_id`, `batch_id`, `application_date`, `dosage_per_ha`, `total_chemical_used`, `effectiveness`) VALUES (NULL, @p_nr_maize25, @b_nr_imid25, '2026-01-20', 0.2, 11.6, 'effective');
INSERT INTO `chemical_applications` (`scouting_id`, `planting_id`, `batch_id`, `application_date`, `dosage_per_ha`, `total_chemical_used`, `effectiveness`) VALUES (NULL, @p_nr_tob, @b_nr_imid, '2026-10-16', 0.15, 2.1, 'effective');
INSERT INTO `chemical_applications` (`scouting_id`, `planting_id`, `batch_id`, `application_date`, `dosage_per_ha`, `total_chemical_used`, `effectiveness`) VALUES (@sc_nr_cut, @p_nr_maize, @b_nr_lambda, '2026-11-02', 0.3, 17.4, 'pending');
INSERT INTO `chemical_applications` (`scouting_id`, `planting_id`, `batch_id`, `application_date`, `dosage_per_ha`, `total_chemical_used`, `effectiveness`) VALUES (@sc_vh_mite, @p_vh_tom, @b_vh_abam, '2026-10-17', 0.5, 2.0, 'effective');
INSERT INTO `chemical_applications` (`scouting_id`, `planting_id`, `batch_id`, `application_date`, `dosage_per_ha`, `total_chemical_used`, `effectiveness`) VALUES (@sc_vh_blight, @p_vh_tom, @b_vh_mancozeb, '2026-11-02', 2.0, 8.0, 'pending');
INSERT INTO `chemical_applications` (`scouting_id`, `planting_id`, `batch_id`, `application_date`, `dosage_per_ha`, `total_chemical_used`, `effectiveness`) VALUES (NULL, @p_vh_onion, @b_vh_mancozeb_old, '2026-08-10', 2.0, 6.0, 'effective');
INSERT INTO `chemical_applications` (`scouting_id`, `planting_id`, `batch_id`, `application_date`, `dosage_per_ha`, `total_chemical_used`, `effectiveness`) VALUES (NULL, @p_vh_tom26, @b_vh_abam26, '2026-04-20', 0.5, 2.0, 'effective');

-- --------------------------------------------------------------------------
-- Weather
-- --------------------------------------------------------------------------
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@gv, '2026-10-24 14:00:00', 31.5, 38.0, 0.0, 12.0, 'Hot and dry');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@gv, '2026-10-25 14:00:00', 32.0, 35.0, 0.0, 14.0, 'Hot, clear skies');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@gv, '2026-10-26 14:00:00', 33.1, 33.0, 0.0, 10.0, 'Very hot');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@gv, '2026-10-27 14:00:00', 30.4, 48.0, 0.0, 16.0, 'Partly cloudy');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@gv, '2026-10-28 14:00:00', 29.0, 62.0, 4.5, 18.0, 'Afternoon showers');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@gv, '2026-10-29 14:00:00', 31.8, 44.0, 0.0, 11.0, 'Hot');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@gv, '2026-10-30 14:00:00', 28.2, 71.0, 12.0, 22.0, 'Thunderstorm in the evening');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@gv, '2026-10-31 14:00:00', 27.5, 76.0, 8.5, 15.0, 'Cloudy with showers');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@gv, '2026-11-01 14:00:00', 30.1, 58.0, 0.0, 9.0, 'Warm, building clouds');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@gv, '2026-11-02 14:00:00', 29.4, 66.0, 2.0, 13.0, 'Isolated showers');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@nr, '2026-10-24 14:00:00', 32.8, 30.0, 0.0, 15.0, 'Hot and dry');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@nr, '2026-10-25 14:00:00', 33.5, 28.0, 0.0, 18.0, 'Hot, windy');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@nr, '2026-10-26 14:00:00', 31.9, 40.0, 0.0, 12.0, 'Hot');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@nr, '2026-10-27 14:00:00', 30.2, 55.0, 6.0, 20.0, 'First rains');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@nr, '2026-10-28 14:00:00', 28.7, 68.0, 18.5, 24.0, 'Heavy thunderstorm');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@nr, '2026-10-29 14:00:00', 29.5, 61.0, 3.0, 14.0, 'Showers');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@nr, '2026-10-30 14:00:00', 30.8, 52.0, 0.0, 11.0, 'Warm');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@nr, '2026-10-31 14:00:00', 29.9, 64.0, 9.0, 19.0, 'Thunderstorm');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@nr, '2026-11-01 14:00:00', 28.4, 72.0, 14.0, 16.0, 'Rainy afternoon');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@nr, '2026-11-02 14:00:00', 29.6, 63.0, 0.0, 10.0, 'Humid, cloudy');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@vh, '2026-10-24 14:00:00', 33.9, 34.0, 0.0, 9.0, 'Very hot');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@vh, '2026-10-25 14:00:00', 34.2, 31.0, 0.0, 11.0, 'Very hot and dry');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@vh, '2026-10-26 14:00:00', 32.6, 39.0, 0.0, 13.0, 'Hot');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@vh, '2026-10-27 14:00:00', 31.1, 50.0, 0.0, 10.0, 'Hazy');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@vh, '2026-10-28 14:00:00', 29.8, 63.0, 5.5, 17.0, 'Showers');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@vh, '2026-10-29 14:00:00', 30.5, 57.0, 0.0, 12.0, 'Warm');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@vh, '2026-10-30 14:00:00', 28.9, 69.0, 10.0, 21.0, 'Thunderstorm');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@vh, '2026-10-31 14:00:00', 27.6, 78.0, 6.5, 14.0, 'Cloudy, light rain');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@vh, '2026-11-01 14:00:00', 28.3, 74.0, 1.5, 8.0, 'Humid');
INSERT INTO `weather_logs` (`farm_id`, `log_timestamp`, `temp_celsius`, `humidity_pct`, `rainfall_mm`, `wind_speed_kmh`, `forecast_summary`) VALUES (@vh, '2026-11-02 14:00:00', 27.1, 82.0, 3.0, 7.0, 'Humid and overcast');

-- --------------------------------------------------------------------------
-- Warehouses
-- --------------------------------------------------------------------------
INSERT INTO `warehouses` (`farm_id`, `name`, `type`, `capacity_metric_tons`) VALUES (@gv, 'Main grain shed', 'shed', 600.0);
SET @wh_gv_shed = LAST_INSERT_ID();
INSERT INTO `warehouses` (`farm_id`, `name`, `type`, `capacity_metric_tons`) VALUES (@gv, 'Cold room', 'cold_storage', 40.0);
SET @wh_gv_cold = LAST_INSERT_ID();
INSERT INTO `warehouses` (`farm_id`, `name`, `type`, `capacity_metric_tons`) VALUES (@gv, 'Silo 1', 'silo', 500.0);
SET @wh_gv_silo1 = LAST_INSERT_ID();
INSERT INTO `warehouses` (`farm_id`, `name`, `type`, `capacity_metric_tons`) VALUES (@gv, 'Silo 2', 'silo', 500.0);
SET @wh_gv_silo2 = LAST_INSERT_ID();
INSERT INTO `warehouses` (`farm_id`, `name`, `type`, `capacity_metric_tons`) VALUES (@gv, 'Input store', 'ambient', 120.0);
SET @wh_gv_input = LAST_INSERT_ID();
INSERT INTO `warehouses` (`farm_id`, `name`, `type`, `capacity_metric_tons`) VALUES (@nr, 'Grain shed', 'shed', 400.0);
SET @wh_nr_shed = LAST_INSERT_ID();
INSERT INTO `warehouses` (`farm_id`, `name`, `type`, `capacity_metric_tons`) VALUES (@nr, 'Tobacco barn store', 'ambient', 60.0);
SET @wh_nr_tob = LAST_INSERT_ID();
INSERT INTO `warehouses` (`farm_id`, `name`, `type`, `capacity_metric_tons`) VALUES (@nr, 'Groundnut store', 'ambient', 80.0);
SET @wh_nr_gn = LAST_INSERT_ID();
INSERT INTO `warehouses` (`farm_id`, `name`, `type`, `capacity_metric_tons`) VALUES (@nr, 'Cotton shed', 'shed', 120.0);
SET @wh_nr_cot = LAST_INSERT_ID();
INSERT INTO `warehouses` (`farm_id`, `name`, `type`, `capacity_metric_tons`) VALUES (@nr, 'Small silo', 'silo', 150.0);
SET @wh_nr_silo = LAST_INSERT_ID();
INSERT INTO `warehouses` (`farm_id`, `name`, `type`, `capacity_metric_tons`) VALUES (@vh, 'Cold store', 'cold_storage', 60.0);
SET @wh_vh_cold = LAST_INSERT_ID();
INSERT INTO `warehouses` (`farm_id`, `name`, `type`, `capacity_metric_tons`) VALUES (@vh, 'Silo A', 'silo', 600.0);
SET @wh_vh_siloA = LAST_INSERT_ID();
INSERT INTO `warehouses` (`farm_id`, `name`, `type`, `capacity_metric_tons`) VALUES (@vh, 'Packhouse', 'ambient', 90.0);
SET @wh_vh_pack = LAST_INSERT_ID();
INSERT INTO `warehouses` (`farm_id`, `name`, `type`, `capacity_metric_tons`) VALUES (@vh, 'Feed store', 'shed', 50.0);
SET @wh_vh_feed = LAST_INSERT_ID();
INSERT INTO `warehouses` (`farm_id`, `name`, `type`, `capacity_metric_tons`) VALUES (@vh, 'Fish cold room', 'cold_storage', 15.0);
SET @wh_vh_fish = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Harvests
-- --------------------------------------------------------------------------
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_gv_maize25, '2026-04-18', 495.0, 'tons', 'Grade A', 14.0, 'Cob rot in wet patches and handling losses.');
SET @h_gv_maize = LAST_INSERT_ID();
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_gv_wheat26, '2026-09-18', 286.0, 'tons', 'Grade 1', 6.0, 'Combine losses at the pivot edges.');
SET @h_gv_wheat = LAST_INSERT_ID();
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_gv_soy25, '2026-04-08', 232.0, 'tons', 'Grade A', 11.0, 'Pod shatter - harvested a week late.');
SET @h_gv_soy = LAST_INSERT_ID();
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_gv_cab26, '2026-05-22', 98000.0, 'kg', 'Grade A', 3000.0, 'Split heads.');
SET @h_gv_cab1 = LAST_INSERT_ID();
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_gv_cab26, '2026-06-02', 76000.0, 'kg', 'Grade B', 5200.0, 'Diamondback damage on outer leaves.');
SET @h_gv_cab2 = LAST_INSERT_ID();
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_gv_onion26, '2026-08-20', 290000.0, 'kg', 'Grade A', 12000.0, 'Neck rot in a few bags.');
SET @h_gv_onion = LAST_INSERT_ID();
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_nr_maize25, '2026-05-02', 348.0, 'tons', 'Grade B', 31.0, 'Larger grain borer in the temporary store.');
SET @h_nr_maize = LAST_INSERT_ID();
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_nr_gnut25, '2026-04-12', 41.0, 'tons', 'Grade A', 2.5, 'Pods left in the soil when lifting.');
SET @h_nr_gnut = LAST_INSERT_ID();
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_nr_cot25, '2026-05-28', 76.0, 'tons', 'Grade A', 1.8, 'Stained lint from late picking.');
SET @h_nr_cot = LAST_INSERT_ID();
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_nr_tob25, '2026-02-28', 12.5, 'tons', 'Grade L1O', 0.4, 'Barn burn on one curing.');
SET @h_nr_tob1 = LAST_INSERT_ID();
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_nr_tob25, '2026-03-25', 19.0, 'tons', 'Grade M2F', 0.8, 'Leaf breakage during grading.');
SET @h_nr_tob2 = LAST_INSERT_ID();
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_nr_sun26, '2026-05-03', 45.0, 'tons', 'Grade A', 4.2, 'Bird damage to heads.');
SET @h_nr_sun = LAST_INSERT_ID();
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_vh_wheat26, '2026-09-25', 264.0, 'tons', 'Grade 1', 9.0, 'Quelea damage on the river edge.');
SET @h_vh_wheat = LAST_INSERT_ID();
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_vh_tom26, '2026-05-20', 62000.0, 'kg', 'Grade A', 2100.0, 'Cracked fruit.');
SET @h_vh_tom1 = LAST_INSERT_ID();
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_vh_tom26, '2026-06-10', 48000.0, 'kg', 'Grade B', 9500.0, 'Blossom-end rot and transport bruising.');
SET @h_vh_tom2 = LAST_INSERT_ID();
INSERT INTO `harvests` (`planting_id`, `harvest_date`, `quantity_harvested`, `unit_of_measure`, `grade`, `loss_quantity`, `loss_reason`) VALUES (@p_vh_onion, '2026-11-01', 6500.0, 'kg', 'Grade A', 0.0, NULL);
SET @h_vh_onion0 = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Produce storage
-- --------------------------------------------------------------------------
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_gv_maize, @wh_gv_silo1, 300.0, '2026-04-20', 2.0, 'dispatched');
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_gv_maize, @wh_gv_silo2, 195.0, '2026-04-21', 0.0, 'stored');
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_gv_wheat, @wh_gv_shed, 286.0, '2026-09-19', 0.0, 'dispatched');
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_gv_soy, @wh_gv_shed, 232.0, '2026-04-09', 1.5, 'dispatched');
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_gv_cab2, @wh_gv_cold, 20000.0, '2026-06-02', 1800.0, 'dispatched');
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_gv_onion, @wh_gv_shed, 120000.0, '2026-08-21', 3500.0, 'stored');
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_nr_maize, @wh_nr_shed, 220.0, '2026-05-04', 18.0, 'dispatched');
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_nr_maize, @wh_nr_silo, 128.0, '2026-05-05', 2.0, 'stored');
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_nr_gnut, @wh_nr_gn, 41.0, '2026-04-20', 0.6, 'dispatched');
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_nr_cot, @wh_nr_cot, 76.0, '2026-05-30', 0.0, 'dispatched');
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_nr_tob2, @wh_nr_tob, 19.0, '2026-03-26', 0.2, 'dispatched');
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_nr_sun, @wh_nr_shed, 45.0, '2026-05-05', 0.5, 'stored');
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_vh_wheat, @wh_vh_siloA, 264.0, '2026-09-26', 0.0, 'stored');
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_vh_tom2, @wh_vh_cold, 15000.0, '2026-06-10', 2400.0, 'disposed');
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_vh_tom1, @wh_vh_pack, 62000.0, '2026-05-20', 900.0, 'dispatched');
INSERT INTO `produce_storage` (`harvest_id`, `warehouse_id`, `quantity_stored`, `entry_date`, `spoilage_quantity`, `status`) VALUES (@h_vh_onion0, @wh_vh_pack, 6500.0, '2026-11-01', 0.0, 'stored');

-- --------------------------------------------------------------------------
-- Customers (each belongs to one farm)
-- --------------------------------------------------------------------------
INSERT INTO `customers` (`farm_id`, `customer_name`, `company_name`, `contact_phone`, `email`, `address`, `created_at`) VALUES (@gv, 'Chanda Mwila', 'City Millers Ltd', '+260 211 245 870', 'procurement@citymillers.example.com', 'Heavy Industrial Area, Lusaka', '2025-10-01 10:00:00');
SET @cu_gv_mill = LAST_INSERT_ID();
INSERT INTO `customers` (`farm_id`, `customer_name`, `company_name`, `contact_phone`, `email`, `address`, `created_at`) VALUES (@gv, 'Ireen Lungu', 'Lusaka Fresh Produce Wholesalers', '+260 977 322 410', 'orders@lusakafresh.example.com', 'Soweto Market, Lusaka', '2025-10-01 10:00:00');
SET @cu_gv_fresh = LAST_INSERT_ID();
INSERT INTO `customers` (`farm_id`, `customer_name`, `company_name`, `contact_phone`, `email`, `address`, `created_at`) VALUES (@gv, 'Patrick Musonda', 'Matero Dairy Cooperative', '+260 966 118 509', 'milk@materodairy.example.com', 'Matero, Lusaka', '2025-10-01 10:00:00');
SET @cu_gv_dairy = LAST_INSERT_ID();
INSERT INTO `customers` (`farm_id`, `customer_name`, `company_name`, `contact_phone`, `email`, `address`, `created_at`) VALUES (@gv, 'Chef Natasha Phiri', 'Chelston Hotel Kitchens', '+260 955 874 223', 'kitchen@chelstonhotel.example.com', 'Chelston, Lusaka', '2025-10-01 10:00:00');
SET @cu_gv_hotel = LAST_INSERT_ID();
INSERT INTO `customers` (`farm_id`, `customer_name`, `company_name`, `contact_phone`, `email`, `address`, `created_at`) VALUES (@gv, 'Brenda Tembo', 'Eggs Direct Lusaka', '+260 979 612 334', 'brenda@eggsdirect.example.com', 'Kalingalinga, Lusaka', '2025-10-01 10:00:00');
SET @cu_gv_eggs = LAST_INSERT_ID();
INSERT INTO `customers` (`farm_id`, `customer_name`, `company_name`, `contact_phone`, `email`, `address`, `created_at`) VALUES (@nr, 'Frank Banda', 'Eastern Grain Buyers', '+260 216 223 900', 'buy@easterngrain.example.com', 'Chipata Industrial Area', '2025-10-01 10:00:00');
SET @cu_nr_grain = LAST_INSERT_ID();
INSERT INTO `customers` (`farm_id`, `customer_name`, `company_name`, `contact_phone`, `email`, `address`, `created_at`) VALUES (@nr, 'Stella Phiri', 'Chipata Cotton Ginners Ltd', '+260 216 224 117', 'seedcotton@chipataginners.example.com', 'Ginnery Road, Chipata', '2025-10-01 10:00:00');
SET @cu_nr_gin = LAST_INSERT_ID();
INSERT INTO `customers` (`farm_id`, `customer_name`, `company_name`, `contact_phone`, `email`, `address`, `created_at`) VALUES (@nr, 'Henry Zulu', 'Eastern Leaf Buyers', '+260 977 455 802', 'leaf@easternleaf.example.com', 'Auction floor, Chipata', '2025-10-01 10:00:00');
SET @cu_nr_leaf = LAST_INSERT_ID();
INSERT INTO `customers` (`farm_id`, `customer_name`, `company_name`, `contact_phone`, `email`, `address`, `created_at`) VALUES (@nr, 'Mary Mbewe', 'Chipata Market Traders', '+260 966 730 245', NULL, 'Chipata Main Market', '2025-10-01 10:00:00');
SET @cu_nr_mkt = LAST_INSERT_ID();
INSERT INTO `customers` (`farm_id`, `customer_name`, `company_name`, `contact_phone`, `email`, `address`, `created_at`) VALUES (@nr, 'Kenneth Daka', 'Kapata Oil Pressers', '+260 955 600 188', 'oil@kapatapress.example.com', 'Kapata, Chipata', '2025-10-01 10:00:00');
SET @cu_nr_oil = LAST_INSERT_ID();
INSERT INTO `customers` (`farm_id`, `customer_name`, `company_name`, `contact_phone`, `email`, `address`, `created_at`) VALUES (@vh, 'Joyce Hamoonga', 'Kafue Town Market', '+260 977 801 662', NULL, 'Kafue Town Centre', '2025-10-01 10:00:00');
SET @cu_vh_mkt = LAST_INSERT_ID();
INSERT INTO `customers` (`farm_id`, `customer_name`, `company_name`, `contact_phone`, `email`, `address`, `created_at`) VALUES (@vh, 'Alex Mutale', 'Lusaka South Supermarkets', '+260 211 271 455', 'fresh@lusakasouth.example.com', 'Makeni, Lusaka', '2025-10-01 10:00:00');
SET @cu_vh_super = LAST_INSERT_ID();
INSERT INTO `customers` (`farm_id`, `customer_name`, `company_name`, `contact_phone`, `email`, `address`, `created_at`) VALUES (@vh, 'Rosemary Siame', 'Riverside Fish Traders', '+260 966 402 918', 'rosemary@riversidefish.example.com', 'Kafue Bridge Market', '2025-10-01 10:00:00');
SET @cu_vh_fish = LAST_INSERT_ID();
INSERT INTO `customers` (`farm_id`, `customer_name`, `company_name`, `contact_phone`, `email`, `address`, `created_at`) VALUES (@vh, 'Thomas Mwale', 'Kafue Flour Mills', '+260 211 312 006', 'wheat@kafueflour.example.com', 'Kafue Industrial Area', '2025-10-01 10:00:00');
SET @cu_vh_mill = LAST_INSERT_ID();
INSERT INTO `customers` (`farm_id`, `customer_name`, `company_name`, `contact_phone`, `email`, `address`, `created_at`) VALUES (@vh, 'Esther Moonga', 'Chilanga Meat Processors', '+260 955 228 740', 'livestock@chilangameat.example.com', 'Chilanga, Lusaka Province', '2025-10-01 10:00:00');
SET @cu_vh_meat = LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Sales orders and items
-- --------------------------------------------------------------------------
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@gv, @cu_gv_mill, '2026-05-06', 1860000.0, 'paid', 'delivered');
SET @so_gv1 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_gv1, @h_gv_maize, NULL, 'White maize, Grade A (tons)', 300.0, 6200.0, 1860000);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@gv, @cu_gv_mill, '2026-04-20', 2254000.0, 'paid', 'delivered');
SET @so_gv2 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_gv2, @h_gv_soy, NULL, 'Soybean (tons)', 230.0, 9800.0, 2254000);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@gv, @cu_gv_fresh, '2026-06-04', 651500.0, 'paid', 'delivered');
SET @so_gv3 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_gv3, @h_gv_cab1, NULL, 'Cabbage, Grade A (kg)', 95000.0, 4.5, 427500.0);
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_gv3, @h_gv_cab2, NULL, 'Cabbage, Grade B (kg)', 70000.0, 3.2, 224000.0);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@gv, @cu_gv_mill, '2026-09-25', 2268000.0, 'paid', 'delivered');
SET @so_gv4 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_gv4, @h_gv_wheat, NULL, 'Wheat, Grade 1 (tons)', 280.0, 8100.0, 2268000);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@gv, @cu_gv_fresh, '2026-09-08', 1440000.0, 'partially_paid', 'delivered');
SET @so_gv5 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_gv5, @h_gv_onion, NULL, 'Onions, Grade A (kg)', 160000.0, 9.0, 1440000.0);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@gv, @cu_gv_dairy, '2026-10-31', 20900.0, 'pending', 'delivered');
SET @so_gv6 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_gv6, NULL, @prod_milk_c1_3, 'Fresh milk, October (L)', 1900.0, 9.5, 18050.0);
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_gv6, NULL, @prod_milk_c3_3, 'Fresh milk bulk (L)', 300.0, 9.5, 2850.0);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@gv, @cu_gv_eggs, '2026-10-30', 40800.0, 'paid', 'delivered');
SET @so_gv7 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_gv7, NULL, @prod_egg_a_3, 'Eggs, trays of 30', 600.0, 68.0, 40800);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@gv, @cu_gv_hotel, '2026-11-02', 21000.0, 'pending', 'confirmed');
SET @so_gv8 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_gv8, NULL, NULL, 'Tomatoes, Grade A (kg)', 1500.0, 14.0, 21000);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@nr, @cu_nr_grain, '2026-05-15', 1160000.0, 'paid', 'delivered');
SET @so_nr1 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_nr1, @h_nr_maize, NULL, 'White maize, Grade B (tons)', 200.0, 5800.0, 1160000);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@nr, @cu_nr_gin, '2026-06-05', 699200.0, 'paid', 'delivered');
SET @so_nr2 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_nr2, @h_nr_cot, NULL, 'Seed cotton, Grade A (tons)', 76.0, 9200.0, 699200);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@nr, @cu_nr_leaf, '2026-04-02', 1278000.0, 'paid', 'delivered');
SET @so_nr3 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_nr3, @h_nr_tob1, NULL, 'Virginia tobacco L1O (tons)', 12.0, 48000.0, 576000);
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_nr3, @h_nr_tob2, NULL, 'Virginia tobacco M2F (tons)', 18.0, 39000.0, 702000);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@nr, @cu_nr_mkt, '2026-04-25', 551000.0, 'paid', 'delivered');
SET @so_nr4 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_nr4, @h_nr_gnut, NULL, 'Groundnuts in shell (tons)', 38.0, 14500.0, 551000);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@nr, @cu_nr_oil, '2026-06-20', 258000.0, 'partially_paid', 'delivered');
SET @so_nr5 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_nr5, @h_nr_sun, NULL, 'Sunflower seed (tons)', 30.0, 8600.0, 258000);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@nr, @cu_nr_mkt, '2026-09-19', 5060.0, 'paid', 'delivered');
SET @so_nr6 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_nr6, NULL, @prod_nr_pig, 'Pork carcass (kg)', 92.0, 55.0, 5060);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@nr, @cu_nr_grain, '2026-10-22', 640000.0, 'pending', 'confirmed');
SET @so_nr7 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_nr7, @h_nr_maize, NULL, 'White maize from silo (tons)', 100.0, 6400.0, 640000);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@vh, @cu_vh_super, '2026-05-22', 551000.0, 'paid', 'delivered');
SET @so_vh1 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_vh1, @h_vh_tom1, NULL, 'Tomatoes, Grade A (kg)', 58000.0, 9.5, 551000.0);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@vh, @cu_vh_mkt, '2026-06-12', 150000.0, 'paid', 'delivered');
SET @so_vh2 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_vh2, @h_vh_tom2, NULL, 'Tomatoes, Grade B (kg)', 25000.0, 6.0, 150000.0);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@vh, @cu_vh_mill, '2026-10-05', 1476000.0, 'partially_paid', 'dispatched');
SET @so_vh3 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_vh3, @h_vh_wheat, NULL, 'Wheat, Grade 1 (tons)', 180.0, 8200.0, 1476000);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@vh, @cu_vh_fish, '2026-10-13', 38440.0, 'paid', 'delivered');
SET @so_vh4 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_vh4, NULL, @prod_vh_fish1, 'Fresh tilapia (kg)', 620.0, 62.0, 38440);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@vh, @cu_vh_fish, '2026-10-27', 24800.0, 'pending', 'delivered');
SET @so_vh5 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_vh5, NULL, @prod_vh_fish2, 'Fresh tilapia (kg)', 400.0, 62.0, 24800);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@vh, @cu_vh_meat, '2026-09-08', 18564.0, 'paid', 'delivered');
SET @so_vh6 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_vh6, NULL, @prod_vh_beef, 'Boran steer carcass (kg)', 238.0, 78.0, 18564);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@vh, @cu_vh_super, '2026-11-03', 63000.0, 'pending', 'pending');
SET @so_vh7 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_vh7, @h_vh_onion0, NULL, 'Onions, Grade A (kg)', 6000.0, 10.5, 63000.0);
INSERT INTO `sales_orders` (`farm_id`, `customer_id`, `order_date`, `total_amount`, `payment_status`, `order_status`) VALUES (@vh, @cu_vh_meat, '2026-08-12', 9600.0, 'paid', 'cancelled');
SET @so_vh8 = LAST_INSERT_ID();
INSERT INTO `sales_order_items` (`order_id`, `harvest_id`, `production_id`, `description`, `quantity`, `unit_price`, `subtotal`) VALUES (@so_vh8, NULL, NULL, 'Dorper lambs (live)', 4.0, 2400.0, 9600);

-- --------------------------------------------------------------------------
-- Income and expenses (last 12 months)
-- --------------------------------------------------------------------------
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Crop & produce sales', 1860000.0, '2026-05-13', 'sales_orders', @so_gv1, 'Payment received - order GV1-1', '2026-05-13 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Crop & produce sales', 2254000.0, '2026-04-27', 'sales_orders', @so_gv2, 'Payment received - order GV2-2', '2026-04-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Crop & produce sales', 651500.0, '2026-06-11', 'sales_orders', @so_gv3, 'Payment received - order GV3-3', '2026-06-11 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Crop & produce sales', 2268000.0, '2026-10-02', 'sales_orders', @so_gv4, 'Payment received - order GV4-4', '2026-10-02 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Crop & produce sales', 720000.0, '2026-09-18', 'sales_orders', @so_gv5, 'Part payment (50%) - order GV5-5', '2026-09-18 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Crop & produce sales', 40800.0, '2026-11-03', 'sales_orders', @so_gv7, 'Payment received - order GV7-7', '2026-11-03 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'income', 'Crop & produce sales', 1160000.0, '2026-05-22', 'sales_orders', @so_nr1, 'Payment received - order NR1-1', '2026-05-22 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'income', 'Crop & produce sales', 699200.0, '2026-06-12', 'sales_orders', @so_nr2, 'Payment received - order NR2-2', '2026-06-12 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'income', 'Crop & produce sales', 1278000.0, '2026-04-09', 'sales_orders', @so_nr3, 'Payment received - order NR3-3', '2026-04-09 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'income', 'Crop & produce sales', 551000.0, '2026-05-02', 'sales_orders', @so_nr4, 'Payment received - order NR4-4', '2026-05-02 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'income', 'Crop & produce sales', 129000.0, '2026-06-30', 'sales_orders', @so_nr5, 'Part payment (50%) - order NR5-5', '2026-06-30 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'income', 'Crop & produce sales', 5060.0, '2026-09-26', 'sales_orders', @so_nr6, 'Payment received - order NR6-6', '2026-09-26 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'income', 'Crop & produce sales', 551000.0, '2026-05-29', 'sales_orders', @so_vh1, 'Payment received - order VH1-1', '2026-05-29 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'income', 'Crop & produce sales', 150000.0, '2026-06-19', 'sales_orders', @so_vh2, 'Payment received - order VH2-2', '2026-06-19 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'income', 'Crop & produce sales', 738000.0, '2026-10-15', 'sales_orders', @so_vh3, 'Part payment (50%) - order VH3-3', '2026-10-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'income', 'Crop & produce sales', 38440.0, '2026-10-20', 'sales_orders', @so_vh4, 'Payment received - order VH4-4', '2026-10-20 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'income', 'Crop & produce sales', 18564.0, '2026-09-15', 'sales_orders', @so_vh6, 'Payment received - order VH6-6', '2026-09-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Milk sales', 20972.0, '2025-12-25', NULL, NULL, 'Monthly milk cheque', '2025-12-25 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Milk sales', 20063.0, '2026-01-25', NULL, NULL, 'Monthly milk cheque', '2026-01-25 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Milk sales', 19435.0, '2026-02-25', NULL, NULL, 'Monthly milk cheque', '2026-02-25 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Egg sales', 13411.0, '2026-02-27', NULL, NULL, 'Egg cash sales', '2026-02-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Milk sales', 17582.0, '2026-03-25', NULL, NULL, 'Monthly milk cheque', '2026-03-25 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Egg sales', 13197.0, '2026-03-27', NULL, NULL, 'Egg cash sales', '2026-03-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Milk sales', 18375.0, '2026-04-25', NULL, NULL, 'Monthly milk cheque', '2026-04-25 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Egg sales', 14737.0, '2026-04-27', NULL, NULL, 'Egg cash sales', '2026-04-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Milk sales', 21078.0, '2026-05-25', NULL, NULL, 'Monthly milk cheque', '2026-05-25 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Egg sales', 9895.0, '2026-05-27', NULL, NULL, 'Egg cash sales', '2026-05-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Milk sales', 20145.0, '2026-06-25', NULL, NULL, 'Monthly milk cheque', '2026-06-25 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Egg sales', 10209.0, '2026-06-27', NULL, NULL, 'Egg cash sales', '2026-06-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Milk sales', 18591.0, '2026-07-25', NULL, NULL, 'Monthly milk cheque', '2026-07-25 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Egg sales', 12465.0, '2026-07-27', NULL, NULL, 'Egg cash sales', '2026-07-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Milk sales', 20972.0, '2026-08-25', NULL, NULL, 'Monthly milk cheque', '2026-08-25 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Egg sales', 11491.0, '2026-08-27', NULL, NULL, 'Egg cash sales', '2026-08-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Milk sales', 18249.0, '2026-09-25', NULL, NULL, 'Monthly milk cheque', '2026-09-25 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Egg sales', 10136.0, '2026-09-27', NULL, NULL, 'Egg cash sales', '2026-09-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'income', 'Fish sales', 7392.0, '2026-09-20', NULL, NULL, 'Fish cash sales at the pond', '2026-09-20 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Milk sales', 21497.0, '2026-10-25', NULL, NULL, 'Monthly milk cheque', '2026-10-25 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Egg sales', 14297.0, '2026-10-27', NULL, NULL, 'Egg cash sales', '2026-10-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'income', 'Fish sales', 6863.0, '2026-10-20', NULL, NULL, 'Fish cash sales at the pond', '2026-10-20 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Seed & fertiliser', 552800.0, '2026-10-01', 'purchase_orders', @po_gv1, 'Paid Lusaka Agro Inputs Ltd', '2026-10-01 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Stock feed', 83600.0, '2026-10-03', 'purchase_orders', @po_gv2, 'Paid Chongwe Stockfeeds', '2026-10-03 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Fuel', 137000.0, '2026-10-27', 'purchase_orders', @po_gv3, 'Paid Great East Fuels', '2026-10-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Seed & fertiliser', 187500.0, '2026-10-13', 'purchase_orders', @po_nr1, 'Paid Kapata Seed Centre', '2026-10-13 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Seed & fertiliser', 236250.0, '2026-10-15', 'purchase_orders', @po_nr2, 'Paid Chipata Farmers Depot', '2026-10-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Crop chemicals', 9320.0, '2026-09-18', 'purchase_orders', @po_nr3, 'Paid Eastern Agro-Chem Traders', '2026-09-18 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Fuel', 56200.0, '2026-10-11', 'purchase_orders', @po_nr5, 'Paid Mchini Fuel & Lubricants', '2026-10-11 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Seed & fertiliser', 395600.0, '2026-09-21', 'purchase_orders', @po_vh1, 'Paid Shimabala Agro Dealers', '2026-09-21 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Stock feed', 31500.0, '2026-10-03', 'purchase_orders', @po_vh2, 'Paid Kafue Fish Feed Suppliers', '2026-10-03 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Fuel', 163200.0, '2026-10-21', 'purchase_orders', @po_vh3, 'Paid Chanyanya Fuel Point', '2026-10-21 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Labour', 106540.0, '2025-12-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2025-12-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Salaries', 36000.0, '2025-12-27', NULL, NULL, 'Management and office salaries', '2025-12-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Electricity', 15476.0, '2025-12-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2025-12-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Fuel', 44340.0, '2025-12-05', NULL, NULL, 'Diesel top-up between bulk orders', '2025-12-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Labour', 62365.0, '2025-12-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2025-12-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Salaries', 24000.0, '2025-12-27', NULL, NULL, 'Management and office salaries', '2025-12-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Electricity', 3960.0, '2025-12-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2025-12-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Fuel', 13038.0, '2025-12-05', NULL, NULL, 'Diesel top-up between bulk orders', '2025-12-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Labour', 53961.0, '2025-12-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2025-12-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Salaries', 18000.0, '2025-12-27', NULL, NULL, 'Management and office salaries', '2025-12-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Electricity', 12484.0, '2025-12-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2025-12-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Fuel', 18177.0, '2025-12-05', NULL, NULL, 'Diesel top-up between bulk orders', '2025-12-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Crop chemicals', 56352.0, '2025-12-10', NULL, NULL, 'Fungicides and insecticides', '2025-12-10 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Crop chemicals', 41671.0, '2025-12-11', NULL, NULL, 'Insecticides for maize, cotton and tobacco', '2025-12-11 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Seed & fertiliser', 480000.0, '2025-12-02', NULL, NULL, 'Basal fertiliser and seed, 2025/26 season', '2025-12-02 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Seed & fertiliser', 300000.0, '2025-12-03', NULL, NULL, 'Basal fertiliser and seed, 2025/26 season', '2025-12-03 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Labour', 109931.0, '2026-01-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-01-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Salaries', 36000.0, '2026-01-27', NULL, NULL, 'Management and office salaries', '2026-01-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Electricity', 14422.0, '2026-01-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-01-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Fuel', 39530.0, '2026-01-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-01-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Labour', 67253.0, '2026-01-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-01-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Salaries', 24000.0, '2026-01-27', NULL, NULL, 'Management and office salaries', '2026-01-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Electricity', 4075.0, '2026-01-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-01-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Fuel', 18360.0, '2026-01-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-01-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Labour', 57891.0, '2026-01-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-01-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Salaries', 18000.0, '2026-01-27', NULL, NULL, 'Management and office salaries', '2026-01-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Electricity', 11886.0, '2026-01-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-01-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Fuel', 20442.0, '2026-01-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-01-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Crop chemicals', 48414.0, '2026-01-10', NULL, NULL, 'Fungicides and insecticides', '2026-01-10 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Crop chemicals', 40025.0, '2026-01-11', NULL, NULL, 'Insecticides for maize, cotton and tobacco', '2026-01-11 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Seed & fertiliser', 315787.0, '2026-01-08', NULL, NULL, 'Top-dressing fertiliser', '2026-01-08 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Seed & fertiliser', 184190.0, '2026-01-08', NULL, NULL, 'Top-dressing fertiliser', '2026-01-08 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Labour', 85534.0, '2026-02-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-02-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Salaries', 36000.0, '2026-02-27', NULL, NULL, 'Management and office salaries', '2026-02-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Electricity', 15925.0, '2026-02-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-02-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Fuel', 31989.0, '2026-02-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-02-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Labour', 53464.0, '2026-02-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-02-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Salaries', 24000.0, '2026-02-27', NULL, NULL, 'Management and office salaries', '2026-02-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Electricity', 3861.0, '2026-02-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-02-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Fuel', 12616.0, '2026-02-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-02-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Labour', 43227.0, '2026-02-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-02-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Salaries', 18000.0, '2026-02-27', NULL, NULL, 'Management and office salaries', '2026-02-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Electricity', 11492.0, '2026-02-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-02-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Fuel', 14138.0, '2026-02-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-02-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Crop chemicals', 64070.0, '2026-02-10', NULL, NULL, 'Fungicides and insecticides', '2026-02-10 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Crop chemicals', 37919.0, '2026-02-11', NULL, NULL, 'Insecticides for maize, cotton and tobacco', '2026-02-11 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Seed & fertiliser', 259569.0, '2026-02-08', NULL, NULL, 'Top-dressing fertiliser', '2026-02-08 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Seed & fertiliser', 168813.0, '2026-02-08', NULL, NULL, 'Top-dressing fertiliser', '2026-02-08 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Labour', 85749.0, '2026-03-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-03-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Salaries', 36000.0, '2026-03-27', NULL, NULL, 'Management and office salaries', '2026-03-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Electricity', 14057.0, '2026-03-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-03-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Fuel', 43977.0, '2026-03-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-03-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Labour', 50239.0, '2026-03-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-03-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Salaries', 24000.0, '2026-03-27', NULL, NULL, 'Management and office salaries', '2026-03-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Electricity', 3995.0, '2026-03-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-03-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Fuel', 10083.0, '2026-03-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-03-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Labour', 46649.0, '2026-03-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-03-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Salaries', 18000.0, '2026-03-27', NULL, NULL, 'Management and office salaries', '2026-03-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Electricity', 13620.0, '2026-03-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-03-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Fuel', 13542.0, '2026-03-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-03-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Crop chemicals', 68963.0, '2026-03-10', NULL, NULL, 'Fungicides and insecticides', '2026-03-10 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Crop chemicals', 26146.0, '2026-03-11', NULL, NULL, 'Insecticides for maize, cotton and tobacco', '2026-03-11 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Seed & fertiliser', 77057.0, '2026-03-06', NULL, NULL, 'Wheat and vegetable inputs', '2026-03-06 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Labour', 104230.0, '2026-04-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-04-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Salaries', 36000.0, '2026-04-27', NULL, NULL, 'Management and office salaries', '2026-04-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Electricity', 14149.0, '2026-04-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-04-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Fuel', 49943.0, '2026-04-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-04-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Labour', 68173.0, '2026-04-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-04-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Salaries', 24000.0, '2026-04-27', NULL, NULL, 'Management and office salaries', '2026-04-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Electricity', 4500.0, '2026-04-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-04-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Fuel', 15457.0, '2026-04-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-04-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Labour', 56003.0, '2026-04-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-04-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Salaries', 18000.0, '2026-04-27', NULL, NULL, 'Management and office salaries', '2026-04-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Electricity', 12917.0, '2026-04-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-04-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Fuel', 21171.0, '2026-04-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-04-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Harvest & transport', 152661.0, '2026-04-22', NULL, NULL, 'Combine hire and haulage', '2026-04-22 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Harvest & transport', 96168.0, '2026-04-22', NULL, NULL, 'Shelling, bags and haulage to buyers', '2026-04-22 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Seed & fertiliser', 88234.0, '2026-04-06', NULL, NULL, 'Wheat and vegetable inputs', '2026-04-06 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Labour', 107249.0, '2026-05-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-05-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Salaries', 36000.0, '2026-05-27', NULL, NULL, 'Management and office salaries', '2026-05-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Electricity', 15172.0, '2026-05-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-05-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Fuel', 52180.0, '2026-05-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-05-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Labour', 62526.0, '2026-05-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-05-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Salaries', 24000.0, '2026-05-27', NULL, NULL, 'Management and office salaries', '2026-05-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Electricity', 4094.0, '2026-05-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-05-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Fuel', 16910.0, '2026-05-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-05-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Labour', 58918.0, '2026-05-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-05-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Salaries', 18000.0, '2026-05-27', NULL, NULL, 'Management and office salaries', '2026-05-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Electricity', 11974.0, '2026-05-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-05-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Fuel', 17877.0, '2026-05-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-05-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Harvest & transport', 207177.0, '2026-05-22', NULL, NULL, 'Combine hire and haulage', '2026-05-22 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Harvest & transport', 82305.0, '2026-05-22', NULL, NULL, 'Shelling, bags and haulage to buyers', '2026-05-22 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Harvest & transport', 52879.0, '2026-05-22', NULL, NULL, 'Packhouse labour and transport', '2026-05-22 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Seed & fertiliser', 96353.0, '2026-05-06', NULL, NULL, 'Wheat and vegetable inputs', '2026-05-06 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Labour', 103928.0, '2026-06-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-06-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Salaries', 36000.0, '2026-06-27', NULL, NULL, 'Management and office salaries', '2026-06-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Electricity', 29756.0, '2026-06-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-06-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Fuel', 53179.0, '2026-06-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-06-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Labour', 66749.0, '2026-06-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-06-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Salaries', 24000.0, '2026-06-27', NULL, NULL, 'Management and office salaries', '2026-06-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Electricity', 9099.0, '2026-06-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-06-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Fuel', 15316.0, '2026-06-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-06-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Labour', 55781.0, '2026-06-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-06-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Salaries', 18000.0, '2026-06-27', NULL, NULL, 'Management and office salaries', '2026-06-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Electricity', 25631.0, '2026-06-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-06-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Fuel', 15758.0, '2026-06-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-06-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Crop chemicals', 21568.0, '2026-06-12', NULL, NULL, 'Wheat and vegetable sprays', '2026-06-12 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Harvest & transport', 39936.0, '2026-06-22', NULL, NULL, 'Packhouse labour and transport', '2026-06-22 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Labour', 81227.0, '2026-07-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-07-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Salaries', 36000.0, '2026-07-27', NULL, NULL, 'Management and office salaries', '2026-07-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Electricity', 33862.0, '2026-07-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-07-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Fuel', 32432.0, '2026-07-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-07-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Labour', 50038.0, '2026-07-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-07-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Salaries', 24000.0, '2026-07-27', NULL, NULL, 'Management and office salaries', '2026-07-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Electricity', 7623.0, '2026-07-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-07-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Fuel', 13136.0, '2026-07-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-07-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Labour', 45436.0, '2026-07-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-07-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Salaries', 18000.0, '2026-07-27', NULL, NULL, 'Management and office salaries', '2026-07-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Electricity', 27585.0, '2026-07-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-07-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Fuel', 13813.0, '2026-07-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-07-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Crop chemicals', 16248.0, '2026-07-12', NULL, NULL, 'Wheat and vegetable sprays', '2026-07-12 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Labour', 81824.0, '2026-08-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-08-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Salaries', 36000.0, '2026-08-27', NULL, NULL, 'Management and office salaries', '2026-08-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Electricity', 30278.0, '2026-08-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-08-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Fuel', 35658.0, '2026-08-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-08-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Labour', 53438.0, '2026-08-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-08-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Salaries', 24000.0, '2026-08-27', NULL, NULL, 'Management and office salaries', '2026-08-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Electricity', 8673.0, '2026-08-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-08-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Fuel', 14649.0, '2026-08-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-08-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Labour', 43576.0, '2026-08-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-08-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Salaries', 18000.0, '2026-08-27', NULL, NULL, 'Management and office salaries', '2026-08-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Electricity', 22823.0, '2026-08-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-08-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Fuel', 16304.0, '2026-08-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-08-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Crop chemicals', 17413.0, '2026-08-12', NULL, NULL, 'Wheat and vegetable sprays', '2026-08-12 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Labour', 85467.0, '2026-09-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-09-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Salaries', 36000.0, '2026-09-27', NULL, NULL, 'Management and office salaries', '2026-09-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Electricity', 33197.0, '2026-09-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-09-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Fuel', 41799.0, '2026-09-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-09-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Labour', 50587.0, '2026-09-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-09-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Salaries', 24000.0, '2026-09-27', NULL, NULL, 'Management and office salaries', '2026-09-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Electricity', 7588.0, '2026-09-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-09-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Fuel', 13247.0, '2026-09-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-09-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Labour', 44630.0, '2026-09-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-09-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Salaries', 18000.0, '2026-09-27', NULL, NULL, 'Management and office salaries', '2026-09-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Electricity', 27511.0, '2026-09-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-09-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Fuel', 12832.0, '2026-09-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-09-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Crop chemicals', 18268.0, '2026-09-12', NULL, NULL, 'Wheat and vegetable sprays', '2026-09-12 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Harvest & transport', 144472.0, '2026-09-24', NULL, NULL, 'Wheat combining and haulage to the mill', '2026-09-24 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Harvest & transport', 39483.0, '2026-09-22', NULL, NULL, 'Packhouse labour and transport', '2026-09-22 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Labour', 81073.0, '2026-10-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-10-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Salaries', 36000.0, '2026-10-27', NULL, NULL, 'Management and office salaries', '2026-10-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Electricity', 33055.0, '2026-10-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-10-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Fuel', 42357.0, '2026-10-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-10-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Labour', 53663.0, '2026-10-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-10-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Salaries', 24000.0, '2026-10-27', NULL, NULL, 'Management and office salaries', '2026-10-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Electricity', 8132.0, '2026-10-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-10-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Fuel', 13123.0, '2026-10-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-10-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Labour', 46094.0, '2026-10-28', NULL, NULL, 'Monthly wages, permanent and casual workers', '2026-10-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Salaries', 18000.0, '2026-10-27', NULL, NULL, 'Management and office salaries', '2026-10-27 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Electricity', 22964.0, '2026-10-15', NULL, NULL, 'ZESCO bill - pumps and cold rooms', '2026-10-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Fuel', 17044.0, '2026-10-05', NULL, NULL, 'Diesel top-up between bulk orders', '2026-10-05 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Machinery repairs', 4850.0, '2026-06-02', NULL, NULL, 'MF 385 service', '2026-06-02 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Machinery repairs', 5200.0, '2026-09-20', NULL, NULL, 'John Deere 250-hour service', '2026-09-20 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Veterinary', 3400.0, '2026-10-14', NULL, NULL, 'Pregnancy checks and mastitis treatment', '2026-10-14 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'expense', 'Insurance', 18500.0, '2026-01-15', NULL, NULL, 'Farm buildings and vehicle insurance', '2026-01-15 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Machinery repairs', 4200.0, '2026-08-10', NULL, NULL, 'MF 290 service', '2026-08-10 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Machinery repairs', 2600.0, '2026-10-30', NULL, NULL, 'Generator AVR repair', '2026-10-30 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Veterinary', 1650.0, '2026-02-14', NULL, NULL, 'East Coast fever treatment', '2026-02-14 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Tobacco curing', 125000.0, '2026-02-20', NULL, NULL, 'Firewood and coal for curing barns', '2026-02-20 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Tobacco curing', 45000.0, '2026-03-18', NULL, NULL, 'Grading, baling and hessian for the auction floor', '2026-03-18 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Insurance', 9800.0, '2026-01-20', NULL, NULL, 'Barns and vehicle insurance', '2026-01-20 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Insurance', 14200.0, '2026-01-18', NULL, NULL, 'Pivot and pump insurance', '2026-01-18 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'expense', 'Seed & fertiliser', 52000.0, '2026-11-02', NULL, NULL, 'Urea for top-dressing (deposit)', '2026-11-02 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Machinery repairs', 18500.0, '2026-09-28', NULL, NULL, 'Combine threshing drum bearing', '2026-09-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Machinery repairs', 5400.0, '2026-07-28', NULL, NULL, 'New Holland 250-hour service', '2026-07-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Water levy', 8800.0, '2026-03-31', NULL, NULL, 'WARMA water abstraction permit', '2026-03-31 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Stock purchase', 21000.0, '2026-05-08', NULL, NULL, 'Tilapia fingerlings for Pond 1', '2026-05-08 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'expense', 'Stock purchase', 15500.0, '2026-06-28', NULL, NULL, 'Tilapia fingerlings for Pond 2', '2026-06-28 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@vh, 'income', 'Livestock sales', 4800.0, '2026-07-02', NULL, NULL, 'Two Dorper rams sold', '2026-07-02 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@gv, 'income', 'Livestock sales', 14500.0, '2026-08-18', NULL, NULL, 'Cull cow GV-C006 sold', '2026-08-18 16:00:00');
INSERT INTO `financial_transactions` (`farm_id`, `transaction_type`, `category`, `amount`, `transaction_date`, `reference_type`, `reference_id`, `description`, `created_at`) VALUES (@nr, 'income', 'Livestock sales', 3600.0, '2026-09-03', NULL, NULL, 'Goat meat sold locally', '2026-09-03 16:00:00');

-- --------------------------------------------------------------------------
-- Audit log (recent activity by the team)
-- --------------------------------------------------------------------------
DELETE FROM audit_logs WHERE (user_id, action, table_affected, created_at) IN ((@john, 'login', 'account', '2026-10-05 07:42:10'), (@john, 'staff changed', 'team', '2026-10-05 07:50:31'), (@u_gv_mgr, 'login', 'account', '2026-10-06 06:15:02'), (@u_gv_mgr, 'create', 'purchase_orders', '2026-09-28 09:05:44'), (@u_gv_agr, 'create', 'scouting_records', '2026-10-14 15:22:18'), (@u_gv_agr, 'update', 'crop_plantings', '2026-10-16 08:10:05'), (@u_gv_acc, 'update', 'sales_orders', '2026-10-12 11:40:27'), (@u_gv_w1, 'update', 'machinery', '2026-10-24 17:05:51'), (@u_gv_agr, 'create', 'scouting_records', '2026-10-28 12:18:40'), (@u_gv_mgr, 'update', 'task_allocations', '2026-11-01 06:30:12'), (@u_nr_mgr, 'login', 'account', '2026-10-08 06:02:33'), (@u_nr_mgr, 'create', 'purchase_orders', '2026-10-08 06:20:09'), (@u_nr_acc, 'create', 'sales_orders', '2026-10-22 10:12:56'), (@u_nr_agr, 'create', 'scouting_records', '2026-10-27 16:45:03'), (@u_nr_mgr, 'update', 'machinery', '2026-10-30 14:55:20'), (@u_nr_agr, 'create', 'scouting_records', '2026-11-02 10:58:41'), (@u_nr_w1, 'password changed', 'account', '2026-10-19 18:20:00'), (@u_vh_mgr, 'login', 'account', '2026-10-09 05:58:47'), (@u_vh_acc, 'update', 'sales_orders', '2026-10-15 13:48:09'), (@u_vh_agr, 'create', 'scouting_records', '2026-10-15 09:33:25'), (@u_vh_acc, 'update', 'purchase_orders', '2026-10-21 08:41:16'), (@u_vh_w2, 'update', 'livestock', '2026-10-20 07:12:30'), (@u_vh_mgr, 'create', 'purchase_orders', '2026-11-02 08:20:14'), (@u_vh_agr, 'create', 'scouting_records', '2026-11-02 15:05:52'));
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@john, 'login', 'account', NULL, '192.168.1.10', '2026-10-05 07:42:10');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@john, 'staff changed', 'team', @u_nr_w2, '192.168.1.10', '2026-10-05 07:50:31');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_gv_mgr, 'login', 'account', NULL, '192.168.1.21', '2026-10-06 06:15:02');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_gv_mgr, 'create', 'purchase_orders', @po_gv1, '192.168.1.21', '2026-09-28 09:05:44');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_gv_agr, 'create', 'scouting_records', @sc_gv_tuta0, '192.168.1.22', '2026-10-14 15:22:18');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_gv_agr, 'update', 'crop_plantings', @p_gv_tom, '192.168.1.22', '2026-10-16 08:10:05');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_gv_acc, 'update', 'sales_orders', @so_gv3, '192.168.1.23', '2026-10-12 11:40:27');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_gv_w1, 'update', 'machinery', @m_gv_jd, '192.168.1.24', '2026-10-24 17:05:51');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_gv_agr, 'create', 'scouting_records', @sc_gv_tuta, '192.168.1.22', '2026-10-28 12:18:40');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_gv_mgr, 'update', 'task_allocations', @t_gv2, '192.168.1.21', '2026-11-01 06:30:12');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_nr_mgr, 'login', 'account', NULL, '10.20.0.11', '2026-10-08 06:02:33');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_nr_mgr, 'create', 'purchase_orders', @po_nr3, '10.20.0.11', '2026-10-08 06:20:09');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_nr_acc, 'create', 'sales_orders', @so_nr6, '10.20.0.13', '2026-10-22 10:12:56');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_nr_agr, 'create', 'scouting_records', @sc_nr_aph, '10.20.0.12', '2026-10-27 16:45:03');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_nr_mgr, 'update', 'machinery', @m_nr_gen, '10.20.0.11', '2026-10-30 14:55:20');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_nr_agr, 'create', 'scouting_records', @sc_nr_cut, '10.20.0.12', '2026-11-02 10:58:41');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_nr_w1, 'password changed', 'account', NULL, '10.20.0.14', '2026-10-19 18:20:00');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_vh_mgr, 'login', 'account', NULL, '172.16.4.31', '2026-10-09 05:58:47');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_vh_acc, 'update', 'sales_orders', @so_vh2, '172.16.4.33', '2026-10-15 13:48:09');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_vh_agr, 'create', 'scouting_records', @sc_vh_mite, '172.16.4.32', '2026-10-15 09:33:25');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_vh_acc, 'update', 'purchase_orders', @po_vh3, '172.16.4.33', '2026-10-21 08:41:16');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_vh_w2, 'update', 'livestock', @a_vh_pond1, '172.16.4.35', '2026-10-20 07:12:30');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_vh_mgr, 'create', 'purchase_orders', @po_vh5, '172.16.4.31', '2026-11-02 08:20:14');
INSERT INTO `audit_logs` (`user_id`, `action`, `table_affected`, `record_id`, `ip_address`, `created_at`) VALUES (@u_vh_agr, 'create', 'scouting_records', @sc_vh_blight, '172.16.4.32', '2026-11-02 15:05:52');

-- --------------------------------------------------------------------------
-- Notifications
-- --------------------------------------------------------------------------
DELETE FROM notifications WHERE user_id = @john AND message IN ('Green Valley Farm: GV-C004 lumpy skin disease vaccination was due on 20 Oct 2026.', 'Green Valley Farm: Tuta absoluta at a high level on the Vegetable Garden tomatoes.', 'North Ridge: Urea is out of stock. A purchase order is waiting for approval.', 'Green Valley Farm: Massey Ferguson 385 is 50 hours past its service.', 'Valley Heights: Kafue Flour Mills paid half of the wheat order.', 'North Ridge: heavy thunderstorm recorded (18.5 mm). Check for waterlogging.', 'Valley Heights: onions on the Drip Garden are ready to lift this week.');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@john, 'Vaccination Due', 'Green Valley Farm: GV-C004 lumpy skin disease vaccination was due on 20 Oct 2026.', 0, '2026-10-21 07:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@john, 'Pest Alert', 'Green Valley Farm: Tuta absoluta at a high level on the Vegetable Garden tomatoes.', 0, '2026-10-28 12:30:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@john, 'Low Stock', 'North Ridge: Urea is out of stock. A purchase order is waiting for approval.', 0, '2026-11-01 09:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@john, 'Machinery Service', 'Green Valley Farm: Massey Ferguson 385 is 50 hours past its service.', 0, '2026-11-02 08:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@john, 'Payment', 'Valley Heights: Kafue Flour Mills paid half of the wheat order.', 1, '2026-10-15 14:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@john, 'Weather', 'North Ridge: heavy thunderstorm recorded (18.5 mm). Check for waterlogging.', 1, '2026-10-28 18:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@john, 'Harvest', 'Valley Heights: onions on the Drip Garden are ready to lift this week.', 0, '2026-11-02 07:30:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@u_gv_mgr, 'Task Reminder', 'Vaccinate dairy herd (LSD) was due on 31 Oct 2026.', 0, '2026-11-01 06:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@u_gv_mgr, 'Low Stock', 'Emamectin benzoate is below its reorder level (2 kg left).', 0, '2026-10-30 10:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@u_gv_agr, 'Pest Alert', 'Pheromone trap counts rising in the Vegetable Garden.', 1, '2026-10-14 16:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@u_gv_w2, 'Expiry', 'Newcastle disease vaccine batch NCD-L4471 expires on 20 Nov 2026.', 0, '2026-11-01 08:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@u_nr_mgr, 'Task Reminder', 'Record tobacco growth and scout was due on 30 Oct 2026.', 0, '2026-10-31 06:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@u_nr_mgr, 'Machinery Service', 'Barn generator sent for repair (AVR failure).', 1, '2026-10-30 15:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@u_nr_agr, 'Pest Alert', 'Cutworm damage on Lundazi Road Block seedlings.', 0, '2026-11-02 11:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@u_nr_acc, 'Payment', 'Kapata Oil Pressers still owe half of the sunflower order.', 0, '2026-10-20 09:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@u_vh_mgr, 'Machinery Service', 'New Holland TT75 service is due in 5 hours.', 0, '2026-11-02 08:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@u_vh_mgr, 'Low Stock', 'Fish pellets are below the reorder level (150 kg left).', 0, '2026-11-01 17:30:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@u_vh_agr, 'Weather', 'Humid and overcast: higher late blight risk on tomatoes.', 0, '2026-11-02 15:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@u_vh_acc, 'Expiry', 'Mancozeb batch MZ-K-2410 expired on 15 Oct 2026. Dispose of it safely.', 1, '2026-10-16 09:00:00');
INSERT INTO `notifications` (`user_id`, `alert_type`, `message`, `is_read`, `created_at`) VALUES (@u_vh_w2, 'Task Reminder', 'Pond 1 dissolved oxygen check due on 20 Nov 2026.', 0, '2026-11-03 06:00:00');

COMMIT;

-- Summary of what was added:
--   audit_logs                   24
--   chemical_applications        15
--   crop_growth_logs             68
--   crop_plantings               28
--   crop_varieties               18
--   customers                    15
--   employees                    21
--   farms                        3
--   fields                       16
--   financial_transactions       230
--   harvests                     16
--   inventory_batches            38
--   inventory_items              33
--   inventory_transactions       32
--   irrigation_schedules         34
--   irrigation_systems           15
--   labor_assignments            23
--   livestock                    39
--   livestock_feed_logs          21
--   livestock_health_records     24
--   livestock_production_logs    44
--   machinery                    19
--   machinery_maintenance        18
--   machinery_usage              32
--   notifications                20
--   pest_disease_catalog         18
--   produce_storage              16
--   purchase_orders              18
--   sales_order_items            26
--   sales_orders                 23
--   scouting_records             18
--   suppliers                    15
--   task_allocations             18
--   users                        16
--   warehouses                   15
--   water_sources                15
--   weather_logs                 30
