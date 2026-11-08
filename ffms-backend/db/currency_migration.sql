-- ============================================================================
-- John Dhiri Intelligent Farm System - CURRENCY MIGRATION
-- Run this ONCE, after farm_access_migration.sql (phpMyAdmin > Import, or
-- paste it into the SQL tab and click Go).
--
-- Gives every farm a country and the currency its money is recorded in.
-- Farms left without a currency are treated as US dollars until someone
-- picks their country on the Farms page.
-- A second run stops with "Duplicate column name", which is harmless.
-- ============================================================================

USE ffms_db;

ALTER TABLE farms
  ADD COLUMN country_code CHAR(2) NULL AFTER farm_name,
  ADD COLUMN currency_code CHAR(3) NULL AFTER country_code;

-- The three sample farms are in Zambia, and their amounts are in kwacha.
UPDATE farms
SET country_code = 'ZM', currency_code = 'ZMW'
WHERE farm_name IN ('Green Valley Farm', 'North Ridge', 'Valley Heights')
  AND currency_code IS NULL;
