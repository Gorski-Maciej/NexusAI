-- ═══════════════════════════════════════════════════════════════════════════════
-- NexusAI JDG — Orchestrator Data Contract (ETAP 05/29)
-- Migracja 008: tabele kontraktu danych orkiestratora
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. Rejestr pól werdyktu (25-field contract)
CREATE TABLE IF NOT EXISTS orchestrator_verdict_fields (
    field_name        TEXT PRIMARY KEY,
    field_type        TEXT NOT NULL CHECK (field_type IN ('boolean', 'string', 'number', 'integer', 'array', 'object')),
    required          BOOLEAN NOT NULL DEFAULT FALSE,
    description       TEXT,
    api_equivalent    TEXT,
    rego_source       TEXT,
    invariant_ref     TEXT,
    created_at        TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 2. Rejestr invariantów (INV-018..INV-042)
CREATE TABLE IF NOT EXISTS orchestrator_invariants (
    invariant_id      TEXT PRIMARY KEY,
    description       TEXT NOT NULL,
    severity          TEXT NOT NULL CHECK (severity IN ('BLOCK', 'WARNING', 'INFO')),
    check_type        TEXT NOT NULL CHECK (check_type IN ('structural', 'runtime', 'publication')),
    rego_source       TEXT,
    last_verified     TEXT,
    status            TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'DEPRECATED', 'FAILED'))
);

-- 3. Log walidacji (append-only)
CREATE TABLE IF NOT EXISTS orchestrator_validation_log (
    validation_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    validated_at      TEXT NOT NULL DEFAULT (datetime('now')),
    schema_version    TEXT NOT NULL,
    status            TEXT NOT NULL CHECK (status IN ('PASS', 'FAIL')),
    checks_run        INTEGER NOT NULL DEFAULT 0,
    checks_passed     INTEGER NOT NULL DEFAULT 0,
    checks_failed     INTEGER NOT NULL DEFAULT 0,
    findings_json     TEXT NOT NULL,
    bundle_hash       TEXT
);

-- 4. PASS definitions registry
CREATE TABLE IF NOT EXISTS orchestrator_pass_definitions (
    pass_id           INTEGER PRIMARY KEY,
    pass_name         TEXT NOT NULL,
    package_count     INTEGER NOT NULL,
    abort_on          TEXT,
    description       TEXT,
    active            BOOLEAN NOT NULL DEFAULT TRUE
);

-- 5. Safe merge allowlist
CREATE TABLE IF NOT EXISTS orchestrator_immutable_allowlist (
    package_name      TEXT PRIMARY KEY,
    reason            TEXT,
    added_at          TEXT NOT NULL DEFAULT (datetime('now')),
    active            BOOLEAN NOT NULL DEFAULT TRUE
);

-- 6. Publication gate (fail-closed)
CREATE VIEW IF NOT EXISTS orchestrator_publication_gate AS
SELECT
    v.validation_id,
    v.status AS validation_status,
    v.checks_failed,
    CASE
        WHEN v.status = 'PASS' AND v.checks_failed = 0 THEN 'PUBLICATION_ALLOWED'
        ELSE 'PUBLICATION_BLOCKED'
    END AS publication_decision,
    v.validated_at,
    v.schema_version
FROM orchestrator_validation_log v
WHERE v.validation_id = (
    SELECT MAX(validation_id) FROM orchestrator_validation_log
);

-- ── Seed data: PASS definitions ────────────────────────────────────────────

INSERT OR IGNORE INTO orchestrator_pass_definitions VALUES
(0, 'RISK', 1, 'BLOCK_AND_ALERT', 'fraud/GKS/GAAR — early abort', TRUE),
(1, 'ROUTING', 1, 'BLOCK_AND_ALERT', 'field confidence + shard routing', TRUE),
(2, 'COMPLIANCE', 8, 'BLOCK_AND_ALERT', 'Biała Lista/MPP/EPS/KSeF', TRUE),
(3, 'CROSSBORDER', 5, 'BLOCK_AND_ALERT', 'WNT/WDT/import', TRUE),
(4, 'VAT', 3, NULL, 'stawki + GTU + deductions', TRUE),
(5, 'PIT', 8, NULL, 'forma + KUP + zaliczki', TRUE),
(6, 'ALLOWANCES', 2, NULL, 'ulgi podatkowe', TRUE),
(7, 'ACCOUNTING', 7, NULL, 'PKPiR + amortyzacja', TRUE),
(8, 'ZUS_BUSINESS_MISC', 17, NULL, 'ZUS + BUSINESS + KSeF + JPK + RESZTA', TRUE);

-- ── Seed data: Immutable allowlist ──────────────────────────────────────────

INSERT OR IGNORE INTO orchestrator_immutable_allowlist (package_name, reason) VALUES
('jdg.zus', 'ZUS: stable rates enforced by law, non-overwritable'),
('jdg.zus.sickness_benefits', 'ZUS sickness: stable rate, non-overwritable'),
('jdg.zus.health_contribution', 'ZUS health: tiered rates, non-overwritable'),
('jdg.business', 'Business: entity status immutable during evaluation'),
('jdg.security.fortress', 'Security: HMAC/verdict integrity');

-- ── Seed data: Invariants ───────────────────────────────────────────────────

INSERT OR IGNORE INTO orchestrator_invariants (invariant_id, description, severity, check_type) VALUES
('INV-018', 'safe_merge: left argument wins on conflict; immutable_verdict packages must never be overwritten', 'BLOCK', 'structural'),
('INV-020', 'routing_context must be attached BEFORE invariant enforcement', 'BLOCK', 'structural'),
('INV-030', 'bundle_version, rule_version, threshold_version in provenance tree', 'BLOCK', 'structural'),
('INV-035', 'NEEDS_ADVICE / CERTAINTY_BLOCKED → no AUTO_POST', 'BLOCK', 'runtime'),
('INV-036', 'evaluation_date is part of routing context (temporal guard)', 'BLOCK', 'structural'),
('INV-042', 'safe_merge integrity — no key overwrites for immutable packages', 'BLOCK', 'structural');
