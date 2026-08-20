-- ═══════════════════════════════════════════════════════════════════════════════
-- NexusAI JDG — Core Guards Temporal Thresholds (ETAP 06/29)
-- Migracja 009: tabele constitutional layer, invariants, thresholds, temporal
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. Invariant catalog (INV-001..INV-042)
CREATE TABLE IF NOT EXISTS core_guards_invariants (
    invariant_id      TEXT PRIMARY KEY,
    description       TEXT NOT NULL,
    level             TEXT NOT NULL CHECK (level IN ('RUNTIME', 'BUILD', 'STATISTICAL')),
    enforcement       TEXT NOT NULL CHECK (enforcement IN ('BLOCK', 'ALERT', 'AUTO_REVERT')),
    active            BOOLEAN NOT NULL DEFAULT TRUE,
    created_at        TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 2. Invariant evaluation log (append-only)
CREATE TABLE IF NOT EXISTS core_guards_evaluation_log (
    evaluation_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    evaluated_at      TEXT NOT NULL DEFAULT (datetime('now')),
    verdict_hash      TEXT,
    invariant_failed  BOOLEAN NOT NULL,
    certainty_class   TEXT NOT NULL CHECK (certainty_class IN ('CERTAIN', 'CONDITIONAL', 'NEEDS_ADVICE')),
    failed_invariants TEXT NOT NULL DEFAULT '[]',
    checked_count     INTEGER NOT NULL DEFAULT 0
);

-- 3. Threshold version registry (time-travel)
CREATE TABLE IF NOT EXISTS core_guards_threshold_versions (
    threshold_key     TEXT NOT NULL,
    version           TEXT NOT NULL,
    value             REAL NOT NULL,
    valid_from        TEXT NOT NULL,
    valid_to          TEXT,
    source_act        TEXT,
    changed_by        TEXT,
    changed_at        TEXT NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (threshold_key, version)
);

-- 4. Temporal version registry (rule versions with validity windows)
CREATE TABLE IF NOT EXISTS core_guards_temporal_versions (
    rule_id           TEXT NOT NULL,
    version           TEXT NOT NULL,
    valid_from        TEXT NOT NULL,
    valid_to          TEXT,
    status            TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('SHADOW', 'CANDIDATE', 'ACTIVE', 'DEPRECATED', 'RETIRED', 'ROLLED_BACK')),
    supersedes        TEXT,
    created_at        TEXT NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (rule_id, version)
);

-- 5. Hardcoded audit log
CREATE TABLE IF NOT EXISTS core_guards_hardcoded_log (
    scan_id           INTEGER PRIMARY KEY AUTOINCREMENT,
    scanned_at        TEXT NOT NULL DEFAULT (datetime('now')),
    total_hardcoded   INTEGER NOT NULL DEFAULT 0,
    files_affected    INTEGER NOT NULL DEFAULT 0,
    gate_threshold    INTEGER,
    gate_result       TEXT CHECK (gate_result IN ('PASS', 'FAIL', NULL))
);

-- 6. Publication gate (fail-closed)
CREATE VIEW IF NOT EXISTS core_guards_publication_gate AS
SELECT
    e.evaluation_id,
    e.invariant_failed,
    e.certainty_class,
    CASE
        WHEN e.invariant_failed = 0 AND e.certainty_class = 'CERTAIN' THEN 'PUBLICATION_ALLOWED'
        ELSE 'PUBLICATION_BLOCKED'
    END AS publication_decision,
    e.evaluated_at
FROM core_guards_evaluation_log e
WHERE e.evaluation_id = (
    SELECT MAX(evaluation_id) FROM core_guards_evaluation_log
);

-- ── Seed data: INV-001..INV-042 ────────────────────────────────────────────

INSERT OR IGNORE INTO core_guards_invariants VALUES
('INV-001', 'stawka VAT ∈ {0, 0.05, 0.08, 0.23, ZW, NP, OO}', 'RUNTIME', 'BLOCK', TRUE),
('INV-002', 'kwota netto ≥ 0, podatek ≥ 0', 'RUNTIME', 'BLOCK', TRUE),
('INV-003', 'brutto = netto × (1+stawka) ± epsilon', 'RUNTIME', 'BLOCK', TRUE),
('INV-004', 'suma odliczeń ≤ podstawa opodatkowania', 'RUNTIME', 'BLOCK', TRUE),
('INV-005', 'werdykt domeny niemutowalnej nigdy nie nadpisany', 'RUNTIME', 'BLOCK', TRUE),
('INV-006', 'BLOCK_AND_ALERT w PASS 0 → brak AUTO_POST', 'RUNTIME', 'BLOCK', TRUE),
('INV-007', 'każda kwota ma walutę i jest ≥ 0', 'RUNTIME', 'BLOCK', TRUE),
('INV-008', 'rule_id istnieje w rejestrze i jest ACTIVE', 'RUNTIME', 'BLOCK', TRUE),
('INV-009', '_legal_basis_refs niepuste dla matched=true', 'RUNTIME', 'BLOCK', TRUE),
('INV-010', 'determinizm: ten sam input = ten sam hash', 'STATISTICAL', 'ALERT', TRUE),
('INV-011', 'vat_rate ma węzeł LKG dla daty ewaluacji', 'RUNTIME', 'BLOCK', TRUE),
('INV-012', 'kwoty walutowe zaokrąglone do 2 miejsc', 'RUNTIME', 'BLOCK', TRUE),
('INV-013', 'suma stawek cząstkowych = stawka całości', 'BUILD', 'BLOCK', TRUE),
('INV-014', 'podstawa opodatkowania nie może być ujemna', 'RUNTIME', 'BLOCK', TRUE),
('INV-015', 'terminy nie w przeszłości dla zdarzeń przyszłych', 'BUILD', 'BLOCK', TRUE),
('INV-016', 'progi progresji PIT uporządkowane rosnąco', 'BUILD', 'BLOCK', TRUE),
('INV-017', 'stawki składek ZUS w (0, 1)', 'BUILD', 'BLOCK', TRUE),
('INV-018', 'brak sprzecznych werdyktów tej samej domeny', 'RUNTIME', 'BLOCK', TRUE),
('INV-019', 'każdy warning ma kod i severity', 'BUILD', 'BLOCK', TRUE),
('INV-020', 'routing O(1): _routing.context obowiązkowy', 'RUNTIME', 'BLOCK', TRUE),
('INV-021', 'kwoty brutto ≥ netto (dla stawek ≥ 0)', 'RUNTIME', 'BLOCK', TRUE),
('INV-022', 'VAT = stawka × podstawa ± epsilon', 'RUNTIME', 'BLOCK', TRUE),
('INV-023', 'limit obrotu zwolnienia ≥ 0', 'BUILD', 'BLOCK', TRUE),
('INV-024', 'zawieszenie = brak składek ZUS', 'RUNTIME', 'BLOCK', TRUE),
('INV-025', 'korekta nie zmienia historycznych werdyktów', 'STATISTICAL', 'AUTO_REVERT', TRUE),
('INV-026', 'przedawnienie zgodne z OrdPU', 'BUILD', 'BLOCK', TRUE),
('INV-027', 'sankcje KKS ≤ maksymalny wymiar kary', 'BUILD', 'BLOCK', TRUE),
('INV-028', 'wartość zwolnienia ≤ podatek należny', 'RUNTIME', 'BLOCK', TRUE),
('INV-029', 'werdykt niemutowalny ma decision_hash', 'RUNTIME', 'BLOCK', TRUE),
('INV-030', 'bundle_version + rule_version + threshold_version', 'RUNTIME', 'BLOCK', TRUE),
('INV-031', 'matched=true ma decision_hash (F3 V2)', 'RUNTIME', 'BLOCK', TRUE),
('INV-032', 'certainty_class ∈ {CERTAIN, CONDITIONAL, NEEDS_ADVICE}', 'RUNTIME', 'BLOCK', TRUE),
('INV-033', '_legal_basis_refs spójne z _legal_basis', 'RUNTIME', 'BLOCK', TRUE),
('INV-034', 'bundle/rule/threshold version współspójne', 'RUNTIME', 'BLOCK', TRUE),
('INV-035', 'BLOCK_AND_ALERT → brak AUTO_POST', 'RUNTIME', 'BLOCK', TRUE),
('INV-036', 'kontekst routingu kompletny (4 pola)', 'RUNTIME', 'BLOCK', TRUE),
('INV-037', 'okna ważności: zero luk + zero nakładek', 'BUILD', 'BLOCK', TRUE),
('INV-038', '_degraded_context → brak CERTAIN', 'RUNTIME', 'BLOCK', TRUE),
('INV-039', 'provenance_tree.path ≥ 1 dla matched=true', 'RUNTIME', 'BLOCK', TRUE),
('INV-040', 'input_hash cache-key deterministyczny', 'STATISTICAL', 'ALERT', TRUE),
('INV-041', 'graf zależności acykliczny', 'BUILD', 'BLOCK', TRUE),
('INV-042', 'allowlist niemutowalna w runtime (safe_merge)', 'RUNTIME', 'BLOCK', TRUE);
