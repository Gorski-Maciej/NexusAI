-- ═══════════════════════════════════════════════════════════════════════════════
-- NexusAI JDG — MIGRACJA 004: CONTROL PLANE v9 (GLM52 P17 — ENTERPRISE AI + SYSTEM OPA)
-- Rozszerza RuleStore (001-003) o tabele control plane V2 F1-F6:
--   • runtime_invariants        — katalog INV (INV-001..INV-042) + wynik per werdykt,
--   • decision_certificates     — certyfikaty decyzyjne (F4) z pieczęcią SHA-256/HSM,
--   • draft_law_radar_events    — zdarzenia Law Radar (F5): projekty, countdowny,
--   • bundle_rollouts           — stan rolloutów (canary/ramped/auto-rollback, V2 §8),
--   • rule_shadow_preparations  — reguły SHADOW przygotowane przez Law Radar (F6).
-- ═══════════════════════════════════════════════════════════════════════════════

-- ── Katalog niezmienników systemowych (F2 V2 §3) ─────────────────────────────
CREATE TABLE IF NOT EXISTS runtime_invariants (
    inv_id          VARCHAR PRIMARY KEY,            -- INV-001..INV-042
    severity        VARCHAR NOT NULL,               -- BLOCK | ALERT | INFO
    description     VARCHAR NOT NULL,
    source          VARCHAR,                        -- F2 V2 §3.x | P03 | P17
    valid_from      DATE,
    valid_to        DATE
);

-- ── Certyfikaty decyzyjne (F4 V2 §5) — WORM (append-only) ───────────────────
CREATE TABLE IF NOT EXISTS decision_certificates (
    certificate_id  VARCHAR PRIMARY KEY,            -- DC-/CS-YYYY-MM-DD-NNNNNNNN
    transaction_date DATE NOT NULL,
    certainty_class VARCHAR NOT NULL,               -- CERTAIN | CONDITIONAL | NEEDS_ADVICE
    rule_id         VARCHAR NOT NULL,
    matched         BOOLEAN,
    amount_pln      NUMERIC(14, 2),
    legal_basis     JSONB,
    payload_hash    VARCHAR NOT NULL,               -- SHA-256 (Merkle-root-lite)
    hsm_signature   VARCHAR NOT NULL,               -- HSM-ECDSA-...
    verification_url VARCHAR,
    generated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cert_seal UNIQUE (payload_hash)
);

CREATE INDEX IF NOT EXISTS idx_cert_class
    ON decision_certificates (certainty_class, transaction_date);

-- ── Law Radar (F5 V2 §6) — zdarzenia i countdowny ────────────────────────────
CREATE TABLE IF NOT EXISTS draft_law_radar_events (
    event_id        UUID PRIMARY KEY DEFAULT uuid(),
    draft_id        UUID NOT NULL,                  -- FK → draft_law_radar (003)
    event_type      VARCHAR NOT NULL,               -- DETECTED | STATUS_CHANGE | PREPARED | ENACTED
    event_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details_json    JSONB,
    FOREIGN KEY (draft_id) REFERENCES draft_law_radar (draft_id)
);

CREATE INDEX IF NOT EXISTS idx_radar_events_draft
    ON draft_law_radar_events (draft_id, event_at);

-- ── Rollouty bundle (V2 §8) — canary/ramped/auto-rollback ───────────────────
CREATE TABLE IF NOT EXISTS bundle_rollouts (
    version         VARCHAR PRIMARY KEY,            -- jdg-bundle-v9.x.y
    previous        VARCHAR,
    stage           VARCHAR NOT NULL,               -- INIT|CANARY|RAMPED|ACTIVE|ROLLED_BACK
    pct             INTEGER DEFAULT 0,
    started_at      TIMESTAMP,
    promoted_at     TIMESTAMP,
    shadow_delta_pct NUMERIC(5, 2),                 -- delta werdyktów (≤ 2%)
    shadow_passed   BOOLEAN,
    error_rate      NUMERIC(6, 4),
    rollback_reason VARCHAR,
    rollback_at     TIMESTAMP,
    mttr_s          INTEGER,                        -- auto-rollback ≤ 300 s
    FOREIGN KEY (previous) REFERENCES bundle_rollouts (version)
);

CREATE INDEX IF NOT EXISTS idx_rollouts_stage
    ON bundle_rollouts (stage, started_at);

-- ── Reguły SHADOW przygotowane przez Law Radar (F6) ─────────────────────────
CREATE TABLE IF NOT EXISTS rule_shadow_preparations (
    shadow_id       UUID PRIMARY KEY DEFAULT uuid(),
    rule_id         VARCHAR NOT NULL,               -- nowa/zmieniona reguła
    draft_id        UUID NOT NULL,
    valid_from      DATE NOT NULL,                  -- data wejścia projektu
    status          VARCHAR DEFAULT 'SHADOW',       -- SHADOW|CANDIDATE|ACTIVE
    prepared_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (draft_id) REFERENCES draft_law_radar (draft_id)
);

-- ── Seed katalogu INV (42 niezmienników — spójne z runtime_invariants_check.py) ─
INSERT INTO runtime_invariants (inv_id, severity, description, source) VALUES
    ('INV-001', 'BLOCK', 'determinizm werdyktu', 'F2 V2 §3.1'),
    ('INV-002', 'BLOCK', 'kompletność pól werdyktu', 'F2 V2 §3.2'),
    ('INV-003', 'BLOCK', 'rule_id unikalne w ścieżce', 'F2 V2 §3.3'),
    ('INV-004', 'ALERT', 'legal_basis kanoniczne', 'F2 V2 §3.4'),
    ('INV-005', 'BLOCK', 'no_match nie nadpisuje decyzji', 'F2 V2 §3.5'),
    ('INV-006', 'BLOCK', 'CERTAINTY_BLOCKED nigdy AUTO_POST', 'F2 V2 §3.6'),
    ('INV-007', 'ALERT', 'temporalność valid_from ≤ valid_to', 'F2 V2 §3.7'),
    ('INV-008', 'BLOCK', 'thresholdy z data.thresholds (0 hardcode)', 'F2 V2 §3.8'),
    ('INV-009', 'ALERT', 'routing per kontekst (O(1))', 'F2 V2 §3.9'),
    ('INV-010', 'ALERT', 'progi graniczne > vs ≥', 'F2 V2 §3.10'),
    ('INV-011', 'BLOCK', 'brak martwych fallbacków {true}', 'F2 V2 §3.11'),
    ('INV-012', 'BLOCK', 'brak duplikatów rule_id w pakiecie', 'F2 V2 §3.12'),
    ('INV-013', 'ALERT', 'golden path bez regresji', 'F2 V2 §3.13'),
    ('INV-014', 'ALERT', 'wersje w certyfikacie', 'F2 V2 §3.14'),
    ('INV-015', 'ALERT', 'degradacja graceful', 'F2 V2 §3.15'),
    ('INV-016', 'ALERT', 'graf zależności acykliczny', 'F2 V2 §3.16'),
    ('INV-017', 'ALERT', 'spójność z manifestem 2.0', 'F2 V2 §3.17'),
    ('INV-018', 'BLOCK', 'Dual-Layer: mikro nie nadpisuje makro (safe_merge)', 'P03'),
    ('INV-019', 'BLOCK', 'wszystkie pakiety wpięte w rejestr decyzji', 'P03'),
    ('INV-020', 'BLOCK', 'routing_context dołączony PRZED enforce()', 'P03'),
    ('INV-021', 'ALERT', 'certyfikat decyzyjny z decision_hash', 'P03'),
    ('INV-022', 'ALERT', 'wersje bundle/rule/threshold w certyfikacie', 'P03'),
    ('INV-023', 'ALERT', 'degradacja przy braku danych (0/None)', 'P03'),
    ('INV-024', 'ALERT', 'graf zależności acykliczny (DAG)', 'P03'),
    ('INV-025', 'ALERT', 'golden path: werdykty referencyjne stabilne', 'P03'),
    ('INV-026', 'ALERT', 'spójność thresholds z regułami konsumenckimi', 'P03'),
    ('INV-027', 'ALERT', 'rule_id zgodne z policy_registry', 'P03'),
    ('INV-028', 'ALERT', 'legal_basis wskazuje węzły LKG (RV)', 'P03'),
    ('INV-029', 'ALERT', 'progi graniczne (off-by-one) testowane', 'P03'),
    ('INV-030', 'ALERT', 'wersja reguły semver w rule_registry', 'P03'),
    ('INV-031', 'BLOCK', 'determinizm: ten sam input → ten sam werdykt', 'P17'),
    ('INV-032', 'BLOCK', 'certyfikat decyzyjny kompletny (pieczęć SHA-256)', 'P17'),
    ('INV-033', 'ALERT', 'wersje bundle/rule/threshold obecne', 'P17'),
    ('INV-034', 'ALERT', 'degradacja graceful przy braku pakietu', 'P17'),
    ('INV-035', 'BLOCK', 'CERTAINTY_BLOCKED nigdy nie wykonuje AUTO_POST', 'P17'),
    ('INV-036', 'ALERT', 'routing_context obecny w werdykcie końcowym', 'P17'),
    ('INV-037', 'ALERT', 'graf zależności reguł acykliczny', 'P17'),
    ('INV-038', 'ALERT', 'golden path: replay bez regresji', 'P17'),
    ('INV-039', 'ALERT', 'spójność z manifest_v2 (0 rozbieżności)', 'P17'),
    ('INV-040', 'ALERT', 'thresholdy spójne z rejestrami limitów', 'P17'),
    ('INV-041', 'ALERT', 'rule_id unikalne w całym bundle', 'P17'),
    ('INV-042', 'ALERT', 'legal_basis kanoniczne (0 UNKNOWN_ACT)', 'P17')
ON CONFLICT (inv_id) DO NOTHING;
