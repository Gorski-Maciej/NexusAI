-- ═══════════════════════════════════════════════════════════════════════════════
-- NexusAI JDG — VAT Micro Special Audit (ETAP 09/29)
-- Migracja 012: tabele audytu VAT Micro Special
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. KSeF scenario registry
CREATE TABLE IF NOT EXISTS vat_micro_ksef_scenarios (
    scenario_id       TEXT PRIMARY KEY,
    rule_id           TEXT NOT NULL,
    description       TEXT NOT NULL,
    routing           TEXT CHECK (routing IN ('ALLOW', 'BLOCK_AND_ALERT', 'TRIAGE_QUEUE', 'RETRY_QUEUE', 'FALLBACK_QUEUE', 'VERIFICATION_QUEUE')),
    legal_basis       TEXT NOT NULL,
    valid_from        TEXT NOT NULL DEFAULT '2024-07-01',
    active            BOOLEAN NOT NULL DEFAULT TRUE
);

-- 2. Margin scheme registry
CREATE TABLE IF NOT EXISTS vat_micro_margin_scenarios (
    scenario_id       TEXT PRIMARY KEY,
    rule_id           TEXT NOT NULL,
    description       TEXT NOT NULL,
    vat_rate          TEXT NOT NULL,
    procedure         TEXT NOT NULL,
    legal_basis       TEXT NOT NULL,
    active            BOOLEAN NOT NULL DEFAULT TRUE
);

-- 3. Place of supply registry
CREATE TABLE IF NOT EXISTS vat_micro_pos_scenarios (
    scenario_id       TEXT PRIMARY KEY,
    rule_id           TEXT NOT NULL,
    description       TEXT NOT NULL,
    article           TEXT NOT NULL,
    customer_type     TEXT CHECK (customer_type IN ('B2B', 'B2C', 'ANY')),
    routing           TEXT,
    legal_basis       TEXT NOT NULL,
    active            BOOLEAN NOT NULL DEFAULT TRUE
);

-- 4. Proportion scenario registry
CREATE TABLE IF NOT EXISTS vat_micro_proportion_scenarios (
    scenario_id       TEXT PRIMARY KEY,
    rule_id           TEXT NOT NULL,
    description       TEXT NOT NULL,
    threshold_key     TEXT,
    legal_basis       TEXT NOT NULL,
    active            BOOLEAN NOT NULL DEFAULT TRUE
);

-- 5. Cross-domain conflict log
CREATE TABLE IF NOT EXISTS vat_micro_cross_domain_log (
    detection_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    detected_at       TEXT NOT NULL DEFAULT (datetime('now')),
    domain_a          TEXT NOT NULL,
    domain_b          TEXT NOT NULL,
    conflict_type     TEXT NOT NULL,
    severity          TEXT CHECK (severity IN ('BLOCK', 'TRIAGE', 'WARNING')),
    findings_json     TEXT
);

-- ── Seed data: KSeF scenarios ───────────────────────────────────────────────

INSERT OR IGNORE INTO vat_micro_ksef_scenarios VALUES
('KSEF-M01', 'jdg.micro.vat.ksef.ksef_m01', 'Token KSeF ważny', 'ALLOW', 'Art. 106na ust. 1 VAT'),
('KSEF-M02', 'jdg.micro.vat.ksef.ksef_m02', 'Token wygasł', 'BLOCK_AND_ALERT', 'Art. 106na ust. 2 VAT'),
('KSEF-M03', 'jdg.micro.vat.ksef.ksef_m03', 'Brak podpisu kwalifikowanego', 'VERIFICATION_QUEUE', 'Art. 106na ust. 3 VAT'),
('KSEF-M04', 'jdg.micro.vat.ksef.ksef_m04', 'Błąd walidacji XSD', 'BLOCK_AND_ALERT', 'Art. 106nb ust. 1 VAT'),
('KSEF-M05', 'jdg.micro.vat.ksef.ksef_m05', 'Błąd biznesowy', 'BLOCK_AND_ALERT', 'Art. 106nb ust. 2 VAT'),
('KSEF-M06', 'jdg.micro.vat.ksef.ksef_m06', 'Timeout API', 'RETRY_QUEUE', 'Art. 106ne VAT'),
('KSEF-M07', 'jdg.micro.vat.ksef.ksef_m07', 'Tryb offline', 'FALLBACK_QUEUE', 'Art. 106ne ust. 1-3 VAT'),
('KSEF-M08', 'jdg.micro.vat.ksef.ksef_m08', 'Numeracja /OFFLINE', 'ALLOW', 'Art. 106ne ust. 4 VAT'),
('KSEF-M09', 'jdg.micro.vat.ksef.ksef_m09', 'Deadline 7 dni przekroczony', 'BLOCK_AND_ALERT', 'Art. 106ne ust. 5 VAT'),
('KSEF-M10', 'jdg.micro.vat.ksef.ksef_m10', 'API error 5xx retry', 'RETRY_QUEUE', 'Art. 106ne VAT');

-- ── Seed data: Margin scenarios ─────────────────────────────────────────────

INSERT OR IGNORE INTO vat_micro_margin_scenarios VALUES
('MAR-01', 'jdg.micro.vat.margin.mar_01', 'Towary używane', '23%', 'MARGIN_USED_GOODS', 'Art. 119 ust. 1 VAT'),
('MAR-04', 'jdg.micro.vat.margin.mar_04', 'Marża ujemna', '0%', 'MARGIN_NEGATIVE', 'Art. 119 ust. 1 VAT'),
('MAR-06', 'jdg.micro.vat.margin.mar_06', 'Dzieła sztuki', '8%', 'MARGIN_ART', 'Art. 120 ust. 1-3 VAT'),
('MAR-07', 'jdg.micro.vat.margin.mar_07', 'Antyki >100 lat', '8%', 'MARGIN_ANTIQUES', 'Art. 120 ust. 1 VAT'),
('MAR-09', 'jdg.micro.vat.margin.mar_09', 'Biuro podróży', '23%', 'MARGIN_TRAVEL', 'Art. 119 VAT');
