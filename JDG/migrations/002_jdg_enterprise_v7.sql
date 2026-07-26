-- ═══════════════════════════════════════════════════════════════════════════════
-- NexusAI JDG — DuckDB RuleStore Migration 002
-- ═══════════════════════════════════════════════════════════════════════════════
-- v7.0 Enterprise Audit: Adds prediction history and stale rules tracking.
--
-- New Tables:
--   6. jdg_prediction_history — C1 Judgment Predictor shadow mode history
--   7. jdg_stale_rules_registry — stale rule detection audit trail
--   8. jdg_conflict_registry — cross-package conflict resolution log
--   9. jdg_explanation_cache — LLM Bridge C2 explanation cache
--
-- Date: 2026-07-25
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- TABLE 6: jdg_prediction_history — C1 Prediction Shadow Mode
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS jdg_prediction_history (
    prediction_id       UUID PRIMARY KEY DEFAULT uuid(),
    tenant_id           VARCHAR NOT NULL,
    input_hash          VARCHAR NOT NULL,
    risk_score          DOUBLE NOT NULL,        -- 0-100
    max_severity        VARCHAR NOT NULL,       -- LOW/MEDIUM/HIGH/CRITICAL
    total_findings      INTEGER NOT NULL,
    total_potential_fines DOUBLE,
    total_expected_cost DOUBLE,
    findings_json       JSON,                   -- Pełna lista znalezisk
    summary             TEXT,
    evaluated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_verdict_id   UUID REFERENCES jdg_verdict_audit(verdict_id)
);

CREATE INDEX IF NOT EXISTS idx_prediction_tenant
    ON jdg_prediction_history (tenant_id, evaluated_at);

CREATE INDEX IF NOT EXISTS idx_prediction_severity
    ON jdg_prediction_history (max_severity, evaluated_at);

-- ═══════════════════════════════════════════════════════════════════════════════
-- TABLE 7: jdg_stale_rules_registry — Stale Rule Tracking
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS jdg_stale_rules_registry (
    entry_id            INTEGER PRIMARY KEY DEFAULT nextval('rule_versions_seq'),
    rule_id             VARCHAR NOT NULL,
    rego_file           VARCHAR NOT NULL,
    days_since_update   INTEGER NOT NULL,
    cited_articles      VARCHAR[],
    isap_changes_json   JSON,
    detected_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status              VARCHAR DEFAULT 'PENDING',  -- PENDING, ACKNOWLEDGED, FIXED, FALSE_POSITIVE
    github_issue_url    VARCHAR,
    acknowledged_by     VARCHAR,
    acknowledged_at     TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_stale_rules_status
    ON jdg_stale_rules_registry (status, detected_at);

-- ═══════════════════════════════════════════════════════════════════════════════
-- TABLE 8: jdg_conflict_registry — Cross-Package Conflict Log
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS jdg_conflict_registry (
    conflict_id         UUID PRIMARY KEY DEFAULT uuid(),
    package_a           VARCHAR NOT NULL,
    package_b           VARCHAR NOT NULL,
    conflict_type       VARCHAR NOT NULL,
    severity            VARCHAR NOT NULL,       -- CRITICAL/HIGH/MEDIUM/LOW
    severity_score      INTEGER,
    shared_articles     VARCHAR[],
    dominant_routing_a  VARCHAR,
    dominant_routing_b  VARCHAR,
    recommendation      TEXT,
    detected_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at         TIMESTAMP,
    resolution_note     TEXT,
    resolved_by         VARCHAR
);

CREATE INDEX IF NOT EXISTS idx_conflict_severity
    ON jdg_conflict_registry (severity, detected_at);

-- ═══════════════════════════════════════════════════════════════════════════════
-- TABLE 9: jdg_explanation_cache — LLM Bridge C2 Response Cache
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS jdg_explanation_cache (
    cache_key           VARCHAR PRIMARY KEY,    -- SHA-256(rule_id + style + model)
    rule_id             VARCHAR NOT NULL,
    style               VARCHAR NOT NULL,
    model_used          VARCHAR NOT NULL,
    explanation_json    JSON NOT NULL,
    token_count         INTEGER,
    cost_estimate_usd   DOUBLE,
    generated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at          TIMESTAMP,              -- Cache TTL (default 30 days)
    hit_count           INTEGER DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_explanation_rule
    ON jdg_explanation_cache (rule_id, style);
