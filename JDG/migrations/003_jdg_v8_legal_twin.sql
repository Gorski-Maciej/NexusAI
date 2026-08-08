-- ═══════════════════════════════════════════════════════════════════════════════
-- NexusAI JDG — DuckDB RuleStore Migration 003 (P01 Fundament — WIZJA V2, §14)
-- ═══════════════════════════════════════════════════════════════════════════════
-- v8.0 Enterprise Legal Twin (F1) + F2/F3/F4/F5 support tables.
-- Ewolucja istniejącej jdg_legal_cartography → legal_graph (Legal Knowledge Graph).
--
-- New Tables:
--  10. legal_graph          — F1 LKG: akty → artykuły → ustępy (wersjonowane węzły)
--  11. invariants           — F2: katalog niezmienników runtime (INV-001..030)
--  12. golden_verdicts      — F3: oracle przeszłości (input_hash → werdykt)
--  13. decision_certificates— F4: certyfikaty decyzyjne (klasa pewności + pieczęć)
--  14. draft_law_radar      — F5: projekty ustaw (Law Radar, DRAFT_LAW status)
--
-- Date: 2026-08-08 · Zgodny: ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md (V1),
--        WIZJA_OPA_ENTERPRISE_V2.md (V2 §1.2, §14), ADR-016..021
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- TABLE 10: legal_graph — F1 Legal Twin (Legal Knowledge Graph)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS legal_graph (
    legal_node_id       UUID PRIMARY KEY DEFAULT uuid(),
    act                 VARCHAR NOT NULL,          -- np. 'Ustawa o VAT'
    act_dz_u            VARCHAR,                   -- np. 'Dz.U. 2025 poz. 456'
    article             VARCHAR NOT NULL,          -- '113', '113.1', '21.1.148'
    article_label       VARCHAR,                   -- 'Art. 113 ust. 1 pkt 148'
    node_type           VARCHAR NOT NULL,          -- ACT | ARTICLE | PARAGRAPH | POINT
    node_text           TEXT,                      -- treść przepisu
    valid_from          DATE NOT NULL,
    valid_to            DATE,
    version             INTEGER DEFAULT 1,         -- wersja węzła po nowelizacjach
    source              VARCHAR NOT NULL,          -- ISAP | Dz.U. | RCL (projekt) | KIS
    status              VARCHAR DEFAULT 'OBOWIAZUJACY',  -- OBOWIAZUJACY/UCHYLONY/ZMIENIONY/DRAFT_LAW
    legal_taxonomy      VARCHAR,                   -- paragraf taksonomii (limit, stawka...)
    rule_ids            VARCHAR[],                 -- reguły implementujące węzeł (reverse coverage)
    threshold_keys      VARCHAR[],                 -- parametry linkowane (jdg_tax_thresholds)
    confidence_draft    DOUBLE,                    -- tylko DRAFT_LAW: pewność projektu (0-1)
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_legal_graph_act
    ON legal_graph (act, article, valid_from);

CREATE INDEX IF NOT EXISTS idx_legal_graph_status
    ON legal_graph (status, valid_to);

-- ═══════════════════════════════════════════════════════════════════════════════
-- TABLE 11: invariants — F2 Warstwa Konstytucyjna (runtime invariants)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS invariants (
    invariant_id        VARCHAR PRIMARY KEY,       -- INV-001 .. INV-030
    description         TEXT NOT NULL,
    check_level         VARCHAR NOT NULL DEFAULT 'BUILD',  -- BUILD | RUNTIME | STATISTICAL
    enforcement         VARCHAR NOT NULL DEFAULT 'BLOCK',  -- BLOCK | ALERT | AUTO_REVERT
    active              BOOLEAN DEFAULT TRUE,
    package             VARCHAR,                   -- pakiet Rego egzekwujący
    verified_smt        BOOLEAN DEFAULT FALSE,     -- F3a: dowód formalny Z3
    added_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- TABLE 12: golden_verdicts — F3 Golden Oracle (oracle przeszłości)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS golden_verdicts (
    input_hash          VARCHAR PRIMARY KEY,
    verdict_json        JSON NOT NULL,
    verdict_hash        VARCHAR NOT NULL,          -- deterministyczny hash werdyktu
    bundle_version      VARCHAR NOT NULL,
    rule_versions       JSON,                      -- {rule_id: version}
    threshold_versions  JSON,
    legal_node_versions JSON,                      -- F1: wersje węzłów LKG
    transaction_date    DATE,
    recorded_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- TABLE 13: decision_certificates — F4 Decision Certificate
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS decision_certificates (
    certificate_id      UUID PRIMARY KEY DEFAULT uuid(),
    verdict_id          UUID REFERENCES jdg_verdict_audit(verdict_id),
    certainty_class     VARCHAR NOT NULL,          -- CERTAIN | CONDITIONAL | NEEDS_ADVICE
    certificate_json    JSON NOT NULL,
    merkle_root         VARCHAR,                   -- SHA-256 → Merkle
    hsm_seal            VARCHAR,                   -- podpis HSM (ECDSA)
    verification_url    VARCHAR,
    generated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_certificates_class
    ON decision_certificates (certainty_class, generated_at);

-- ═══════════════════════════════════════════════════════════════════════════════
-- TABLE 14: draft_law_radar — F5 Law Radar (proaktywna adaptacja)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS draft_law_radar (
    draft_id            UUID PRIMARY KEY DEFAULT uuid(),
    source              VARCHAR NOT NULL,          -- RCL | SEJM | SENAT | ISAP
    title               VARCHAR NOT NULL,
    url                 VARCHAR,
    detected_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status              VARCHAR DEFAULT 'DRAFT_LAW',  -- DRAFT_LAW | ENACTED | WITHDRAWN
    confidence_draft    DOUBLE,                    -- pewność, że projekt wejdzie w życie
    expected_enactment  DATE,                      -- przewidywana data wejścia
    lead_days           INTEGER,                   -- KPI: lead time przed wejściem
    predicted_diff_json JSON,                      -- przewidywany diff prawny (AI-Reader)
    rule_ids_prepared   VARCHAR[],                 -- reguły SHADOW przygotowane
    reviewed_by         VARCHAR,
    reviewed_at         TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_draft_radar_status
    ON draft_law_radar (status, expected_enactment);
