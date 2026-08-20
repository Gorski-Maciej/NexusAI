-- ═══════════════════════════════════════════════════════════════════════════════
-- NexusAI JDG — VAT Micro Core Audit (ETAP 08/29)
-- Migracja 011: tabele audytu VAT Micro Core
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. Micro rule registry (per-article atomic rules)
CREATE TABLE IF NOT EXISTS vat_micro_rule_registry (
    rule_id           TEXT PRIMARY KEY,
    article_number    TEXT NOT NULL,
    rule_pattern      TEXT CHECK (rule_pattern IN ('eligibility', 'positive', 'negative', 'exception', 'interaction', 'deadline', 'sanction')),
    file_path         TEXT NOT NULL,
    priority          INTEGER,
    legal_basis       TEXT,
    temporal          BOOLEAN NOT NULL DEFAULT FALSE,
    valid_from        TEXT,
    valid_to          TEXT,
    status            TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'STUB', 'DEAD', 'DUPLICATE')),
    created_at        TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 2. Article coverage matrix
CREATE TABLE IF NOT EXISTS vat_micro_article_coverage (
    article_number    TEXT PRIMARY KEY,
    description       TEXT NOT NULL,
    micro_rules_count INTEGER NOT NULL DEFAULT 0,
    coverage_status   TEXT CHECK (coverage_status IN ('COMPLETE', 'PARTIAL', 'MISSING')),
    binding_macro     TEXT,
    binding_verdict   TEXT,
    last_verified     TEXT
);

-- 3. Duplicate audit log
CREATE TABLE IF NOT EXISTS vat_micro_duplicate_log (
    scan_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    scanned_at        TEXT NOT NULL DEFAULT (datetime('now')),
    total_rules       INTEGER NOT NULL DEFAULT 0,
    unique_rules      INTEGER NOT NULL DEFAULT 0,
    duplicates_found  INTEGER NOT NULL DEFAULT 0,
    findings_json     TEXT
);

-- 4. Stub detection log
CREATE TABLE IF NOT EXISTS vat_micro_stub_log (
    scan_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    scanned_at        TEXT NOT NULL DEFAULT (datetime('now')),
    total_stubs       INTEGER NOT NULL DEFAULT 0,
    stub_files        INTEGER NOT NULL DEFAULT 0,
    gate_threshold    INTEGER,
    gate_result       TEXT CHECK (gate_result IN ('PASS', 'FAIL', NULL))
);

-- 5. Publication gate (fail-closed)
CREATE VIEW IF NOT EXISTS vat_micro_publication_gate AS
SELECT
    d.scan_id,
    d.duplicates_found,
    d.total_stubs,
    CASE
        WHEN d.duplicates_found = 0 AND d.total_stubs = 0 THEN 'PUBLICATION_ALLOWED'
        ELSE 'PUBLICATION_BLOCKED'
    END AS publication_decision,
    d.scanned_at
FROM vat_micro_duplicate_log d
WHERE d.scan_id = (SELECT MAX(scan_id) FROM vat_micro_duplicate_log);
