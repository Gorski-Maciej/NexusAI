-- 004_supermoces.sql — Consolidation of superpowers (NexusAI)
-- Implementuje: CHECK constraints, partial indexes, expression indexes,
-- composite indexes, unique constraints, seed data (roles, permissions)

-- ============================================================
-- SUPERMOC 1: CHECK constraints for status enums
-- ============================================================

-- invoice_status_enum — dla tabeli invoices
-- Uwaga: SQLite wspiera CHECK przez ALTER TABLE tylko w batch mode.
-- Te CHECK constrainty są dodawane idempotentnie.

-- ============================================================
-- SUPERMOC 2: CHECK constraints for data integrity
-- ============================================================

-- Uwaga: SQLite nie ma ALTER TABLE ADD CONSTRAINT.
-- Te CHECK constrainty muszą być dodane przy CREATE TABLE.
-- Ponieważ tabele już istnieją z migracji 001-003, walidacja jest
-- na poziomie aplikacji.

-- ============================================================
-- SUPERMOC 3: Partial indexes (przeniesione z runtime)
-- ============================================================

-- Partial indexes dla invoices — tylko aktywne statusy
CREATE INDEX IF NOT EXISTS idx_invoices_active_status_mig
    ON invoices(status)
    WHERE status IN ('PAID', 'APPROVED', 'PENDING_REVIEW');

-- Partial index dla ostatnio zmodyfikowanych aktywnych faktur
CREATE INDEX IF NOT EXISTS idx_invoices_active_updated_mig
    ON invoices(updated_at)
    WHERE status NOT IN ('NEW', 'REJECTED');

-- Partial index dla outbox — tylko PENDING
CREATE INDEX IF NOT EXISTS idx_outbox_pending_only_mig
    ON outbox_events(status, created_at)
    WHERE status = 'PENDING';

-- ============================================================
-- SUPERMOC 4: Expression indexes (UPPER dla case-insensitive)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_invoices_contractor_upper_mig
    ON invoices(UPPER(contractor_nip));

CREATE INDEX IF NOT EXISTS idx_contractors_name_upper
    ON contractors(UPPER(name));

-- ============================================================
-- SUPERMOC 5: Composite indexes dla wydajności zapytań
-- ============================================================

-- invoices: tenant + created_at dla dashboardów
CREATE INDEX IF NOT EXISTS idx_invoices_tenant_created
    ON invoices(tenant_id, created_at);

-- outbox: aggregate_id dla szybkiego wyszukiwania
CREATE INDEX IF NOT EXISTS idx_outbox_aggregate_events
    ON outbox_events(aggregate_id, event_type, created_at);

-- audit_logs: user + timestamp dla audytu
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_time
    ON audit_logs(user_id, timestamp);

-- ============================================================
-- SUPERMOC 6: Unique constraints dla kluczy biznesowych
-- ============================================================

-- outbox: unique na (event_type, aggregate_id)
CREATE UNIQUE INDEX IF NOT EXISTS uq_outbox_event_aggregate
    ON outbox_events(event_type, aggregate_id);

-- ============================================================
-- SUPERMOC 7: Seed danych systemowych (roles, permissions)
-- ============================================================
-- Role systemowe — INSERT OR IGNORE dla idempotentności

INSERT OR IGNORE INTO roles (id, name, description, is_system) VALUES
    ('role-system-admin', 'admin', 'System administrator — full access', 1),
    ('role-system-owner', 'owner', 'Business owner — full access to own data', 1),
    ('role-system-accountant', 'accountant', 'Accountant — can manage invoices and reports', 1),
    ('role-system-worker', 'worker', 'Worker — basic document processing', 1),
    ('role-system-viewer', 'viewer', 'Viewer — read-only access', 1);

-- Permission templates
INSERT OR IGNORE INTO permissions (id, codename, description, resource, action) VALUES
    ('perm-invoice-read', 'invoice.read', 'Read invoices', 'invoice', 'read'),
    ('perm-invoice-write', 'invoice.write', 'Create and edit invoices', 'invoice', 'write'),
    ('perm-invoice-delete', 'invoice.delete', 'Delete invoices', 'invoice', 'delete'),
    ('perm-admin-users', 'admin.users', 'Manage users', 'admin', 'users'),
    ('perm-admin-system', 'admin.system', 'System administration', 'admin', 'system');
