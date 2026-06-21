-- 001_init.sql — Initial database schema (NexusAI)
-- Zgodne z migracją Alembic: 0001_initial_schema.py
-- Zasada: zero utraty funkcjonalności — wszystkie tabele, indeksy, klucze

-- ============================================================
-- Core OLTP tables
-- ============================================================

-- invoices
CREATE TABLE IF NOT EXISTS invoices (
    id                      TEXT PRIMARY KEY,
    number                  TEXT,
    amount_net              DECIMAL(12,2) NOT NULL DEFAULT 0.0,
    amount_gross            DECIMAL(12,2) NOT NULL DEFAULT 0.0,
    currency                TEXT(3) NOT NULL DEFAULT 'PLN',
    issue_date              TEXT,
    contractor_nip          TEXT(10),
    contractor_id           TEXT,
    status                  TEXT NOT NULL DEFAULT 'NEW',
    file_path               TEXT NOT NULL,
    tenant_id               TEXT NOT NULL DEFAULT 'default',
    created_at              TEXT,
    updated_at              TEXT,
    created_by              TEXT NOT NULL DEFAULT 'worker:taskiq',
    updated_by              TEXT NOT NULL DEFAULT 'worker:taskiq',
    deletion_date           TEXT,
    retention_period_years  INTEGER NOT NULL DEFAULT 5,
    version_id              INTEGER NOT NULL DEFAULT 1,
    is_deleted              INTEGER NOT NULL DEFAULT 0,
    deleted_at              TEXT,
    retry_count             INTEGER NOT NULL DEFAULT 0,
    processing_status       TEXT
);

CREATE INDEX IF NOT EXISTS idx_invoices_contractor_nip ON invoices(contractor_nip);
CREATE INDEX IF NOT EXISTS idx_invoices_tenant_status ON invoices(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_invoices_updated_at ON invoices(updated_at);
CREATE INDEX IF NOT EXISTS idx_invoices_number ON invoices(number);

-- contractors
CREATE TABLE IF NOT EXISTS contractors (
    id           TEXT PRIMARY KEY,
    name         TEXT NOT NULL,
    nip          TEXT(10) NOT NULL UNIQUE,
    address      TEXT,
    bank_account TEXT(26),
    version_id   INTEGER NOT NULL DEFAULT 1,
    created_at   TEXT,
    updated_at   TEXT
);

CREATE INDEX IF NOT EXISTS idx_contractors_nip ON contractors(nip);

-- outbox_events
CREATE TABLE IF NOT EXISTS outbox_events (
    id                     TEXT PRIMARY KEY,
    event_type             TEXT NOT NULL,
    aggregate_id           TEXT NOT NULL,
    payload                TEXT NOT NULL,
    status                 TEXT NOT NULL DEFAULT 'PENDING',
    retry_count            INTEGER NOT NULL DEFAULT 0,
    processed              INTEGER NOT NULL DEFAULT 0,
    created_at             TEXT,
    processed_at           TEXT,
    processing_started_at  TEXT
);

CREATE INDEX IF NOT EXISTS idx_outbox_pending ON outbox_events(status, processed, retry_count, created_at);

-- audit_logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id             TEXT PRIMARY KEY,
    invoice_id     TEXT,
    user_id        TEXT NOT NULL DEFAULT 'System',
    action         TEXT NOT NULL,
    field_changed  TEXT,
    old_value      TEXT,
    new_value      TEXT,
    timestamp      TEXT,
    created_at     TEXT
);

CREATE INDEX IF NOT EXISTS idx_audit_invoice_id ON audit_logs(invoice_id);

-- active_learning_patterns
CREATE TABLE IF NOT EXISTS active_learning_patterns (
    id                 TEXT PRIMARY KEY,
    contractor_nip     TEXT(10) NOT NULL,
    correction_payload TEXT NOT NULL,
    created_at         TEXT
);

CREATE INDEX IF NOT EXISTS idx_alp_contractor_nip ON active_learning_patterns(contractor_nip);

-- users
CREATE TABLE IF NOT EXISTS users (
    id            TEXT PRIMARY KEY,
    username      TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role          TEXT NOT NULL DEFAULT 'worker',
    tenant_id     TEXT NOT NULL DEFAULT 'default',
    is_active     INTEGER NOT NULL DEFAULT 1,
    created_at    TEXT
);

-- security_alerts
CREATE TABLE IF NOT EXISTS security_alerts (
    id          TEXT PRIMARY KEY,
    actor       TEXT NOT NULL,
    operation   TEXT NOT NULL,
    details     TEXT NOT NULL,
    created_at  TEXT
);

-- refresh_tokens
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id      TEXT NOT NULL,
    token_hash   TEXT NOT NULL UNIQUE,
    expires_at   TEXT NOT NULL,
    is_revoked   INTEGER NOT NULL DEFAULT 0,
    created_at   TEXT
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires ON refresh_tokens(expires_at);

-- ui_drafts
CREATE TABLE IF NOT EXISTS ui_drafts (
    tenant_id    TEXT NOT NULL,
    actor_id     TEXT NOT NULL,
    draft_key    TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    updated_at   TEXT NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (tenant_id, actor_id, draft_key)
);

-- fx_rates
CREATE TABLE IF NOT EXISTS fx_rates (
    id           TEXT PRIMARY KEY,
    currency     TEXT NOT NULL,
    rate_to_pln  REAL NOT NULL,
    effective_at TEXT NOT NULL,
    source       TEXT NOT NULL DEFAULT 'manual',
    created_at   TEXT
);

CREATE INDEX IF NOT EXISTS idx_fx_rates_currency_effective ON fx_rates(currency, effective_at);

-- task_status
CREATE TABLE IF NOT EXISTS task_status (
    task_id       TEXT PRIMARY KEY,
    task_name     TEXT NOT NULL,
    user_id       TEXT,
    status        TEXT NOT NULL DEFAULT 'QUEUED',
    progress      REAL NOT NULL DEFAULT 0.0,
    result        TEXT,
    error_message TEXT,
    created_at    TEXT,
    updated_at    TEXT
);

CREATE INDEX IF NOT EXISTS idx_task_status_user ON task_status(user_id);
CREATE INDEX IF NOT EXISTS idx_task_status_status ON task_status(status);

-- processed_events (idempotency)
CREATE TABLE IF NOT EXISTS processed_events (
    id            TEXT PRIMARY KEY,
    event_type    TEXT NOT NULL,
    aggregate_id  TEXT NOT NULL,
    payload_hash  TEXT NOT NULL,
    processed_at  TEXT,
    UNIQUE(event_type, aggregate_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_processed_events_business_key ON processed_events(event_type, aggregate_id);

-- ============================================================
-- Roboton_Reflekton tables
-- ============================================================

-- company_profiles
CREATE TABLE IF NOT EXISTS company_profiles (
    id                    TEXT(36) PRIMARY KEY,
    name                  TEXT(255) NOT NULL,
    nip                   TEXT(10) NOT NULL UNIQUE,
    legal_form            TEXT(32) NOT NULL,
    ksef_active           INTEGER NOT NULL DEFAULT 1,
    ksef_token            TEXT(512),
    vat_active            INTEGER NOT NULL DEFAULT 1,
    vat_proportion        NUMERIC(5,4) NOT NULL DEFAULT 1.0000,
    tigerbeetle_ledger_map TEXT NOT NULL DEFAULT '{}',
    company_policy        TEXT NOT NULL DEFAULT '{}',
    created_at            TEXT NOT NULL
);

-- company_partners
CREATE TABLE IF NOT EXISTS company_partners (
    id          TEXT(36) PRIMARY KEY,
    company_id  TEXT(36) NOT NULL REFERENCES company_profiles(id) ON DELETE CASCADE,
    full_name   TEXT(255) NOT NULL,
    tax_id      TEXT(10) NOT NULL,
    share_ratio NUMERIC(5,4) NOT NULL
);

-- tax_policies
CREATE TABLE IF NOT EXISTS tax_policies (
    id                    TEXT(36) PRIMARY KEY,
    company_id            TEXT(36) NOT NULL REFERENCES company_profiles(id) ON DELETE CASCADE,
    tax_form              TEXT(32) NOT NULL,
    pit_costs_enabled     INTEGER NOT NULL DEFAULT 1,
    requires_full_ledger  INTEGER NOT NULL DEFAULT 0,
    vat_settlement_cycle  TEXT(32) NOT NULL DEFAULT 'monthly',
    effective_from        TEXT NOT NULL,
    UNIQUE(company_id)
);

-- ledger_transfers
CREATE TABLE IF NOT EXISTS ledger_transfers (
    id                  TEXT(36) PRIMARY KEY,
    company_id          TEXT(36) NOT NULL REFERENCES company_profiles(id) ON DELETE CASCADE,
    source_account      BIGINT NOT NULL,
    target_account      BIGINT NOT NULL,
    amount_minor        BIGINT NOT NULL,
    currency            TEXT(3) NOT NULL DEFAULT 'PLN',
    source_document_id  TEXT(36) NOT NULL,
    status              TEXT(32) NOT NULL DEFAULT 'pending',
    meta                TEXT NOT NULL DEFAULT '{}',
    created_at          TEXT NOT NULL
);

-- financial_periods
CREATE TABLE IF NOT EXISTS financial_periods (
    period_id          TEXT(7) NOT NULL,
    company_id         TEXT(36) NOT NULL REFERENCES company_profiles(id) ON DELETE CASCADE,
    status             TEXT(32) NOT NULL DEFAULT 'open',
    closed_at          TEXT,
    vat_declaration_id TEXT(128),
    PRIMARY KEY (period_id, company_id)
);

-- manual_cashflow_items (analytics)
CREATE TABLE IF NOT EXISTS manual_cashflow_items (
    id          TEXT(36) PRIMARY KEY,
    type        TEXT NOT NULL,
    expected_date TEXT,
    amount      NUMERIC(18,2),
    description TEXT,
    is_active   INTEGER NOT NULL DEFAULT 1
);

-- ============================================================
-- Saga store table (runtime)
-- ============================================================

CREATE TABLE IF NOT EXISTS saga_log (
    saga_id    TEXT PRIMARY KEY,
    saga_type  TEXT NOT NULL,
    state      TEXT NOT NULL DEFAULT 'STARTED',
    step_data  TEXT NOT NULL DEFAULT '{}',
    created_at TEXT,
    updated_at TEXT
);
