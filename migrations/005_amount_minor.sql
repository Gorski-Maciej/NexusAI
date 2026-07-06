-- 005_amount_minor.sql — Add INTEGER minor-unit columns for financial precision (Enterprise Audit)
-- SQLite REAL → INTEGER migration for amount_net/amount_gross
-- These columns store values in minor units (grosze) eliminating float drift.

-- invoices
ALTER TABLE invoices ADD COLUMN amount_net_minor INTEGER;
ALTER TABLE invoices ADD COLUMN amount_gross_minor INTEGER;

-- Backfill from existing REAL columns (best-effort for existing data)
UPDATE invoices SET amount_net_minor = CAST(ROUND(amount_net * 100) AS INTEGER)
WHERE amount_net_minor IS NULL AND amount_net IS NOT NULL;

UPDATE invoices SET amount_gross_minor = CAST(ROUND(amount_gross * 100) AS INTEGER)
WHERE amount_gross_minor IS NULL AND amount_gross IS NOT NULL;

-- company_profiles (if financial columns existed)
-- ALTER TABLE company_profiles ADD COLUMN capital_minor INTEGER;

-- fx_rates — fix REAL to DECIMAL text representation for precision
-- Note: SQLite lacks native DECIMAL; we store as TEXT with a parallel integer basis-points column.
ALTER TABLE fx_rates ADD COLUMN rate_basis_points INTEGER;
UPDATE fx_rates SET rate_basis_points = CAST(ROUND(rate_to_pln * 10000) AS INTEGER)
WHERE rate_basis_points IS NULL;
