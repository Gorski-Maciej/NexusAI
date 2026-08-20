-- ═══════════════════════════════════════════════════════════════════════════════
-- NexusAI JDG — VAT Macro Audit (ETAP 07/29)
-- Migracja 010: tabele audytu VAT Macro
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. VAT article coverage registry
CREATE TABLE IF NOT EXISTS vat_macro_article_coverage (
    article_number    TEXT PRIMARY KEY,
    description       TEXT NOT NULL,
    covered           BOOLEAN NOT NULL DEFAULT FALSE,
    coverage_source   TEXT,
    last_verified     TEXT
);

-- 2. VAT rate registry (all rates: 23%, 8%, 5%, 0%, ZW, NP)
CREATE TABLE IF NOT EXISTS vat_macro_rates (
    rate_id           TEXT PRIMARY KEY,
    rate_value        TEXT NOT NULL,
    legal_basis       TEXT NOT NULL,
    gtu_codes         TEXT,
    valid_from        TEXT NOT NULL,
    valid_to          TEXT,
    category          TEXT CHECK (category IN ('STANDARD', 'REDUCED', 'ZERO', 'EXEMPT', 'NOT_SUBJECT')),
    created_at        TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 3. MPP/Split Payment audit log
CREATE TABLE IF NOT EXISTS vat_macro_mpp_audit (
    audit_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    audited_at        TEXT NOT NULL DEFAULT (datetime('now')),
    invoice_amount    REAL,
    mpp_required      BOOLEAN,
    mpp_used          BOOLEAN,
    sanction_applied  BOOLEAN,
    findings_json     TEXT
);

-- 4. Fraud detection log
CREATE TABLE IF NOT EXISTS vat_macro_fraud_log (
    detection_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    detected_at       TEXT NOT NULL DEFAULT (datetime('now')),
    fraud_type        TEXT NOT NULL,
    rule_id           TEXT,
    severity          TEXT CHECK (severity IN ('BLOCK', 'TRIAGE', 'WARNING')),
    findings_json     TEXT
);

-- 5. Duplicate rule_id audit
CREATE TABLE IF NOT EXISTS vat_macro_duplicate_audit (
    scan_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    scanned_at        TEXT NOT NULL DEFAULT (datetime('now')),
    total_rule_ids    INTEGER NOT NULL DEFAULT 0,
    unique_rule_ids   INTEGER NOT NULL DEFAULT 0,
    duplicates_found  INTEGER NOT NULL DEFAULT 0,
    findings_json     TEXT
);

-- 6. Publication gate (fail-closed)
CREATE VIEW IF NOT EXISTS vat_macro_publication_gate AS
SELECT
    d.scan_id,
    d.duplicates_found,
    CASE
        WHEN d.duplicates_found = 0 THEN 'PUBLICATION_ALLOWED'
        ELSE 'PUBLICATION_BLOCKED'
    END AS publication_decision,
    d.scanned_at
FROM vat_macro_duplicate_audit d
WHERE d.scan_id = (SELECT MAX(scan_id) FROM vat_macro_duplicate_audit);

-- ── Seed data: key VAT rates ────────────────────────────────────────────────

INSERT OR IGNORE INTO vat_macro_rates VALUES
('RATE_23', '0.23', 'Art. 41 ust. 1 VAT', 'GTU_02,GTU_09,GTU_10,GTU_13', '2011-01-01', NULL, 'STANDARD'),
('RATE_8', '0.08', 'Art. 41 ust. 2 VAT', 'GTU_08', '2011-01-01', NULL, 'REDUCED'),
('RATE_5', '0.05', 'Art. 41 ust. 2a VAT', 'GTU_01', '2011-01-01', NULL, 'REDUCED'),
('RATE_0', '0.00', 'Art. 41a VAT (WDT)', NULL, '2011-01-01', NULL, 'ZERO'),
('RATE_ZW', 'ZW', 'Art. 43 ust. 1 VAT', NULL, '2011-01-01', NULL, 'EXEMPT'),
('RATE_NP', 'NP', 'Art. 5-6 VAT (out of scope)', NULL, '2011-01-01', NULL, 'NOT_SUBJECT');
