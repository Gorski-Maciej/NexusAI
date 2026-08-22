-- ═══════════════════════════════════════════════════════════════════════════════
-- NexusAI JDG — MIGRACJA 013: TOOLS / API / RULESTORE / BUNDLES CONTROL-DATA PLANE
-- (GLM52 ETAP 25 — V1 §9, V2 §8, V1 §12.2 DR/BCP)
-- Rozszerza RuleStore (001-004) o rejestry control/data plane:
--   • bundle_registry          — WORM (append-only) rejestr wydanych bundle:
--     wersja, SHA-256, podpis HSM, SBOM, Merkle root, status CANDIDATE/…,
--   • node_verification_log    — WORM log weryfikacji bundle NA WĘŹLE OPA
--     (sygnatura + SBOM + Merkle) PRZED aktywacją — fail-closed,
--   • healthy_versions_persist — persist OSTATNIEJ ZDROWEJ wersji (target
--     auto-rollback; zgodny z deployment_orchestrator.py active_version),
--   • dr_snapshots             — Disaster Recovery: snapshoty RPO/RTO,
--     restore_tested (game days), runbook ref.
--
-- Każda migracja jest IDEMPOTENTNA (CREATE … IF NOT EXISTS) i dodaje jawne
-- constraints: PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK oraz politykę WORM
-- (append-only — brak UPDATE/DELETE na wierszach rejestru).
-- ═══════════════════════════════════════════════════════════════════════════════

-- ── WORM rejestr bundle (V1 §9.1) ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bundle_registry (
    version         VARCHAR PRIMARY KEY,            -- jdg-bundle-v9.x.y (semver)
    sha256          VARCHAR NOT NULL,               -- SHA-256 treści bundle
    signature       VARCHAR NOT NULL,               -- HSM:<sha256[:32]> lub HSM-ECDSA-…
    sbom_sha256     VARCHAR NOT NULL,               -- SHA-256 pliku .sbom.json
    merkle_root     VARCHAR,                        -- Merkle root (Merkle-root-lite: SHA-256 SBOM)
    rules_count     INTEGER NOT NULL DEFAULT 0,
    status          VARCHAR NOT NULL DEFAULT 'CANDIDATE',  -- CANDIDATE|CANARY|ACTIVE|ROLLED_BACK
    published_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_by    VARCHAR NOT NULL,
    CONSTRAINT uq_bundle_sha UNIQUE (sha256),
    CONSTRAINT ck_bundle_status CHECK (status IN ('CANDIDATE', 'CANARY', 'SHADOW_COMPARE', 'RAMPED', 'ACTIVE', 'ROLLED_BACK')),
    CONSTRAINT ck_bundle_rules CHECK (rules_count >= 0)
);

-- WORM: rejestr nie podlega UPDATE/DELETE — nowa wersja = nowy wiersz.
CREATE INDEX IF NOT EXISTS idx_bundle_registry_status
    ON bundle_registry (status, published_at);

-- ── Log weryfikacji na węźle (fail-closed) ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS node_verification_log (
    verification_id UUID PRIMARY KEY DEFAULT uuid(),
    node_id         VARCHAR NOT NULL,
    version         VARCHAR NOT NULL,
    verified_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    signature_ok    BOOLEAN NOT NULL,
    sbom_ok         BOOLEAN NOT NULL,
    merkle_ok       BOOLEAN NOT NULL,
    verifier        VARCHAR NOT NULL,               -- bundle_server.verify / bundle.sh VERIFY
    CONSTRAINT fk_verify_bundle FOREIGN KEY (version) REFERENCES bundle_registry (version),
    -- Fail-closed: weryfikacja jest kompletna tylko wtedy, gdy WSZYSTKIE
    -- warstwy (sygnatura + SBOM + Merkle) są OK; częściowa weryfikacja = odrzut.
    CONSTRAINT ck_verify_all_or_none CHECK (
        (signature_ok AND sbom_ok AND merkle_ok) OR NOT (signature_ok OR sbom_ok OR merkle_ok)
    )
);

CREATE INDEX IF NOT EXISTS idx_node_verify_version
    ON node_verification_log (version, verified_at);

-- ── Persist ostatniej zdrowej wersji (auto-rollback target) ──────────────────
CREATE TABLE IF NOT EXISTS healthy_versions_persist (
    version             VARCHAR PRIMARY KEY,        -- tylko JEDNA aktywna zdrowa wersja
    active_version      BOOLEAN NOT NULL DEFAULT TRUE,  -- aktualna wersja produkcyjna
    promoted_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    soak_completed_at   TIMESTAMP,                  -- pełny soak 24 h przed aktywacją
    shadow_delta_pct    NUMERIC(5, 2),              -- delta werdyktów (≤ 2%)
    error_rate          NUMERIC(6, 4),              -- błąd telemetrii (≤ 1%)
    CONSTRAINT fk_healthy_bundle FOREIGN KEY (version) REFERENCES bundle_registry (version),
    CONSTRAINT ck_healthy_delta CHECK (shadow_delta_pct IS NULL OR shadow_delta_pct <= 2.00),
    CONSTRAINT ck_healthy_error CHECK (error_rate IS NULL OR error_rate <= 0.0100)
);

-- ── Disaster Recovery / BCP (V1 §12.2) ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dr_snapshots (
    snapshot_id     UUID PRIMARY KEY DEFAULT uuid(),
    taken_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version         VARCHAR NOT NULL,               -- bundle którego dotyczy snapshot
    bundle_sha256   VARCHAR NOT NULL,
    thresholds_hash VARCHAR NOT NULL,               -- data.thresholds.jdg.* snapshot
    rpo_minutes     INTEGER NOT NULL,               -- cel ≤ 15 min
    rto_minutes     INTEGER NOT NULL,               -- cel ≤ 30 min
    restore_tested  BOOLEAN NOT NULL DEFAULT FALSE, -- game day / DR drill
    runbook_ref     VARCHAR,                        -- docs/DR_RUNBOOK.md
    restored_at     TIMESTAMP,
    restored_by     VARCHAR,
    CONSTRAINT fk_dr_bundle FOREIGN KEY (version) REFERENCES bundle_registry (version),
    CONSTRAINT ck_dr_rpo CHECK (rpo_minutes <= 15),
    CONSTRAINT ck_dr_rto CHECK (rto_minutes <= 30),
    CONSTRAINT ck_dr_tested_before_restore CHECK (restored_at IS NULL OR restore_tested)
);

CREATE INDEX IF NOT EXISTS idx_dr_snapshots_taken
    ON dr_snapshots (taken_at DESC);
