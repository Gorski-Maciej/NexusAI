-- ═══════════════════════════════════════════════════════════════════════════════
-- NexusAI JDG — DuckDB RuleStore Migration
-- ═══════════════════════════════════════════════════════════════════════════════
-- Source: NexusAI_JDG_7000_MASTER_IMPLEMENTATION_PLAN.txt, Sections 5.1-5.2
--
-- Purpose: Creates the relational schema for JDG tax thresholds and temporal
-- rule versioning. Replaces 265 hardcoded magic numbers in .rego files with
-- dynamic DuckDB thresholds (B2 Strategic Initiative).
--
-- Architecture:
--   DuckDB → OPA Data API → data.thresholds.jdg.* → Rego evaluation
--
-- Tables:
--   1. jdg_tax_thresholds — progi, stawki, limity (B2 Threshold Injection)
--   2. rule_versions — temporal registry (A2 Temporal Causality Chain)
--   3. jdg_verdict_audit — immutable audit log (A1 Provenance)
--   4. isap_history — ISAP crawl history (C3 Legal Radar)
--   5. jdg_legal_cartography — RDF/SPARQL legal ontology (A3)
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- TABLE 1: jdg_tax_thresholds — B2 Decoupled Threshold Injection
-- ═══════════════════════════════════════════════════════════════════════════════
-- Purpose: Zastępuje 265 hardcoded magic numbers w .rego.
-- Każdy próg/stawka/limit ma wersjonowanie temporalne (valid_from/valid_to).
-- Zmiana prawa = UPDATE w DuckDB, nie modyfikacja kodu Rego.
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS jdg_tax_thresholds (
    threshold_id        VARCHAR PRIMARY KEY,  -- np. 'vat_receipt_450_limit', 'P189.bad_debt_days'
    description         TEXT NOT NULL,        -- 'Limit kwoty na paragonie VAT (Art. 106e ust. 3)'
    value_numeric       DOUBLE,               -- 450.00 (PLN, EUR, dni, %)
    value_string        VARCHAR,              -- 'ZW', '2026-02-01' (dla wartości nie-numerycznych)
    value_unit          VARCHAR,              -- 'PLN', 'EUR', 'DAYS', 'PERCENT', 'DATE'
    legal_basis         TEXT,                 -- 'Ustawa o VAT Art. 106e ust. 3'
    valid_from          DATE NOT NULL,        -- temporal registry: początek obowiązywania
    valid_to            DATE,                 -- NULL = current (nadal obowiązuje)
    scope_tenant_type   VARCHAR,              -- 'jdg', 'cit', 'all'
    scope_pit_form      VARCHAR,              -- 'SCALE', 'LINEAR', 'LUMP_SUM', 'TAX_CARD', NULL
    scope_pkpid         VARCHAR,              -- PKD główne (np. '62.01.Z'), NULL = wszystkie
    source_url          TEXT,                 -- link do ISAP/RCL
    source_isap_id      VARCHAR,              -- ISAP identifier (np. 'WDU20240000361')
    last_modified       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    modified_by         VARCHAR,
    version             INTEGER DEFAULT 1,
    superseded_by       VARCHAR               -- threshold_id który zastąpił ten próg
);

-- Indeksy dla szybkiego lookup
CREATE INDEX IF NOT EXISTS idx_thresholds_lookup
    ON jdg_tax_thresholds (threshold_id, valid_from, valid_to);

CREATE INDEX IF NOT EXISTS idx_thresholds_active
    ON jdg_tax_thresholds (threshold_id)
    WHERE valid_to IS NULL;

CREATE INDEX IF NOT EXISTS idx_thresholds_scope
    ON jdg_tax_thresholds (scope_tenant_type, scope_pit_form, scope_pkpid);

-- ═══════════════════════════════════════════════════════════════════════════════
-- TABLE 2: rule_versions — A2 Temporal Causality Chain
-- ═══════════════════════════════════════════════════════════════════════════════
-- Purpose: Wersjonowanie reguł OPA/Rego w czasie. Umożliwia time-travel
-- evaluation — odtworzenie werdyktu wg stanu prawnego z dnia transakcji.
-- Kluczowe dla kontroli KAS za zaległe lata (2022-2025).
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE SEQUENCE IF NOT EXISTS rule_versions_seq START 1;

CREATE TABLE IF NOT EXISTS rule_versions (
    version_id          INTEGER PRIMARY KEY DEFAULT nextval('rule_versions_seq'),
    rule_id             VARCHAR NOT NULL,    -- np. 'P189', 'P58', 'P500'
    rule_version        INTEGER NOT NULL,    -- 1, 2, 3...
    rego_package        VARCHAR NOT NULL,    -- 'jdg.vat', 'jdg.pit.forms', 'jdg.kks'
    rego_location       TEXT NOT NULL,       -- 'JDG/rules/vat/substantive.rego:42'
    rule_body_hash      VARCHAR NOT NULL,    -- SHA-256 treści reguły
    legal_change_summary TEXT,               -- 'SLIM VAT 3: 150→90 dni'
    valid_from          DATE NOT NULL,
    valid_to            DATE,                -- NULL = current
    superseded_by       INTEGER REFERENCES rule_versions(version_id),
    threshold_keys      VARCHAR[],           -- Lista threshold_id powiązanych z tą wersją
    isap_act_ref        VARCHAR,             -- Referencja do aktu w ISAP
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR,
    UNIQUE(rule_id, rule_version)
);

CREATE INDEX IF NOT EXISTS idx_rule_versions_active
    ON rule_versions (rule_id, valid_from, valid_to)
    WHERE valid_to IS NULL;

CREATE INDEX IF NOT EXISTS idx_rule_versions_date
    ON rule_versions (rule_id, valid_from, valid_to);

CREATE INDEX IF NOT EXISTS idx_rule_versions_package
    ON rule_versions (rego_package);

-- ═══════════════════════════════════════════════════════════════════════════════
-- TABLE 3: jdg_verdict_audit — A1 Immutable Audit Log
-- ═══════════════════════════════════════════════════════════════════════════════
-- Purpose: Niezmienny log wszystkich werdyktów JDG. Każdy werdykt ma:
--   - Merkle root hash (dla non-repudiation)
--   - Provenance tree (A1)
--   - Temporal snapshot (A2)
--   - Sygnaturę ECDSA (dla audytu kryminalistycznego)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS jdg_verdict_audit (
    verdict_id          UUID PRIMARY KEY DEFAULT uuid(),
    tenant_id           VARCHAR NOT NULL,
    transaction_date    DATE NOT NULL,
    evaluation_datetime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    input_hash          VARCHAR NOT NULL,        -- SHA-256 pełnego input JSON
    rule_id_matched     VARCHAR,                 -- P58, P189, etc.
    action              VARCHAR,                 -- BLOCK_AND_ALERT, TRIAGE_QUEUE, ALLOW
    vat_rate            VARCHAR,
    pit_form            VARCHAR,
    zus_base_type       VARCHAR,
    verdict_json        JSON NOT NULL,           -- Pełny werdykt JSON
    provenance_tree     JSON,                    -- A1: _provenance_tree
    temporal_snapshot   JSON,                    -- A2: snapshot thresholdów
    merkle_root         VARCHAR,                 -- Merkle tree root hash
    ecdsa_signature     VARCHAR,                 -- Sygnatura ECDSA (A1)
    bundle_version      VARCHAR,                 -- Wersja paczki OPA
    shard_routed        VARCHAR,                 -- Nazwa shardu (B1)
    evaluation_ms       DOUBLE,                  -- Czas ewaluacji w ms
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_verdict_tenant_date
    ON jdg_verdict_audit (tenant_id, transaction_date);

CREATE INDEX IF NOT EXISTS idx_verdict_created
    ON jdg_verdict_audit (created_at);

-- ═══════════════════════════════════════════════════════════════════════════════
-- TABLE 4: isap_history — C3 Legal Radar crawl history
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS isap_history (
    id                  INTEGER PRIMARY KEY DEFAULT nextval('rule_versions_seq'),
    act_key             VARCHAR NOT NULL,        -- 'I_vat', 'II_pit', etc.
    act_name            VARCHAR NOT NULL,
    content_hash        VARCHAR NOT NULL,        -- SHA-256 treści aktu
    content_preview     TEXT,                    -- Pierwsze 1000 znaków treści
    diff_from_previous  TEXT,                    -- Unified diff vs poprzednia wersja
    change_detected     BOOLEAN DEFAULT FALSE,
    crawled_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    github_issue_url    VARCHAR,                 -- URL do automatycznie utworzonego issue
    jdg_rules_affected  VARCHAR[]                -- Lista pakietów Rego do aktualizacji
);

CREATE INDEX IF NOT EXISTS idx_isap_history_act
    ON isap_history (act_key, crawled_at);

-- ═══════════════════════════════════════════════════════════════════════════════
-- TABLE 5: jdg_legal_cartography — A3 RDF/SPARQL Ontology Mapping
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS jdg_legal_cartography (
    provision_id        VARCHAR PRIMARY KEY,     -- 'lex:VAT:Art113', 'lex:PIT:Art27'
    act_key             VARCHAR NOT NULL,        -- 'I_vat', 'II_pit'
    article_number      INTEGER NOT NULL,
    article_title       TEXT NOT NULL,
    jdg_rules           VARCHAR[] NOT NULL,      -- ['jdg.vat.a113.r1', ...]
    coverage_status     VARCHAR,                 -- 'COMPLETE', 'PARTIAL', 'PLANNED', 'MISSING'
    thresholds_refs     VARCHAR[],               -- ['vat_subject_exemption_limit', ...]
    gaps_description    TEXT,                    -- Opis luk w pokryciu
    temporal_versions   JSON,                    -- Historia zmian artykułu
    last_isap_check     TIMESTAMP,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- SEED DATA: Top 50 progów (migracja B2 — initial thresholds)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Te dane zastępują 265 hardcoded magic numbers z plików .rego.
-- W produkcji ładowane przez OPA Data API do data.thresholds.jdg.*.
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO jdg_tax_thresholds (threshold_id, description, value_numeric, value_unit, legal_basis, valid_from, valid_to, scope_tenant_type, scope_pit_form, source_url) VALUES
-- VAT thresholds
('vat_receipt_450_limit',           'Limit paragonu VAT z NIP',                    450.00,     'PLN',    'Art. 106e ust. 3 VAT',                 '2018-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('vat_subject_exemption_limit',     'Zwolnienie podmiotowe VAT — roczny limit',    200000.00,  'PLN',    'Art. 113 ust. 1 VAT',                  '2018-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('vat_bad_debt_days',               'Złe długi — dni po terminie (SLIM VAT 3)',    90.00,      'DAYS',   'Art. 89a ust. 1a VAT',                 '2025-07-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('vat_standard_rate',               'Stawka podstawowa VAT',                       0.23,       'PERCENT','Art. 41 ust. 1 VAT',                    '2011-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('vat_reduced_rate_8',              'Stawka obniżona VAT 8%',                      0.08,       'PERCENT','Art. 41 ust. 2 VAT',                    '2011-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('vat_reduced_rate_5',              'Stawka obniżona VAT 5%',                      0.05,       'PERCENT','Art. 41 ust. 2a VAT',                   '2011-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('vat_car_deduction_no_log',        'VAT od auta — bez ewidencji',                 0.50,       'PERCENT','Art. 86a ust. 1 VAT',                    '2014-04-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('vat_car_deduction_with_log',      'VAT od auta — z ewidencją',                   1.00,       'PERCENT','Art. 86a ust. 3-4 VAT',                  '2014-04-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('vat_mpp_mandatory_threshold',     'Split payment — próg obowiązkowy',            15000.00,   'PLN',    'Art. 108a ust. 1a VAT',                  '2019-11-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),

-- PIT thresholds
('pit_scale_low_rate',              'Skala PIT — pierwszy próg',                   0.12,       'PERCENT','Art. 27 ust. 1 PIT',                     '2022-01-01', NULL, 'jdg', 'SCALE', 'https://isap.sejm.gov.pl'),
('pit_scale_high_rate',             'Skala PIT — drugi próg',                      0.32,       'PERCENT','Art. 27 ust. 1 PIT',                     '2022-01-01', NULL, 'jdg', 'SCALE', 'https://isap.sejm.gov.pl'),
('pit_scale_threshold',             'Skala PIT — próg 12%/32%',                    120000.00,  'PLN',    'Art. 27 ust. 1 PIT',                     '2022-01-01', NULL, 'jdg', 'SCALE', 'https://isap.sejm.gov.pl'),
('pit_tax_free_amount',             'Kwota wolna od podatku',                      30000.00,   'PLN',    'Art. 27 ust. 1b PIT',                    '2022-01-01', NULL, 'jdg', 'SCALE', 'https://isap.sejm.gov.pl'),
('pit_linear_rate',                 'Podatek liniowy',                             0.19,       'PERCENT','Art. 30c ust. 1 PIT',                    '2004-01-01', NULL, 'jdg', 'LINEAR', 'https://isap.sejm.gov.pl'),
('pit_ip_box_rate',                 'IP Box',                                      0.05,       'PERCENT','Art. 30ca ust. 1 PIT',                   '2019-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('pit_car_value_limit_standard',    'Limit wartości auta — KUP',                   150000.00,  'PLN',    'Art. 23 ust. 1 pkt 4 PIT',               '2019-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('pit_car_value_limit_ev',          'Limit wartości auta EV — KUP',                225000.00,  'PLN',    'Art. 23 ust. 1 pkt 4 PIT',               '2019-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('pit_car_kup_no_log',              'Auto — KUP bez ewidencji',                    0.75,       'PERCENT','Art. 23 ust. 1 pkt 46 PIT',              '2007-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('pit_loss_carry_years',            'Rozliczenie straty — max lat',                5.00,       'YEARS',  'Art. 9 ust. 3 PIT',                       '2019-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('pit_loss_carry_max_pct',          'Rozliczenie straty — max % rocznie',          0.50,       'PERCENT','Art. 9 ust. 3 PIT',                       '2019-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),

-- ZUS / SUS thresholds
('zus_start_relief_months',         'Ulga na start — okres',                       6.00,       'MONTHS', 'Art. 18a ust. 1 SUS',                    '2018-04-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('zus_maly_plus_months',            'Mały ZUS Plus — okres',                       36.00,      'MONTHS', 'Art. 18c ust. 1 SUS',                    '2019-04-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('zus_maly_plus_income_limit',      'Mały ZUS Plus — limit przychodu rocznego',    60000.00,   'PLN',    'Art. 18c ust. 4 SUS',                    '2019-04-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('zus_preferential_months',         'Preferencyjny ZUS — okres',                   24.00,      'MONTHS', 'Art. 18a ust. 2 SUS',                    '2018-04-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('zus_health_scale_rate',           'Zdrowotna — skala',                           0.09,       'PERCENT','Art. 81 ust. 2 ustawy o świadczeniach',  '2022-01-01', NULL, 'jdg', 'SCALE', 'https://isap.sejm.gov.pl'),
('zus_health_linear_rate',          'Zdrowotna — liniowy',                         0.049,      'PERCENT','Art. 81 ust. 2 ustawy o świadczeniach',  '2022-01-01', NULL, 'jdg', 'LINEAR', 'https://isap.sejm.gov.pl'),
('zus_health_linear_deduction_max', 'Zdrowotna liniowy — max odliczenie roczne',   12900.00,   'PLN',    'Art. 30c ust. 2 PIT',                    '2022-01-01', NULL, 'jdg', 'LINEAR', 'https://isap.sejm.gov.pl'),
('zus_sickness_waiting_days',       'Zasiłek chorobowy — okres wyczekiwania',      90.00,      'DAYS',   'Art. 4 ust. 1 ustawy zasiłkowej',        '2017-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),

-- Ryczałt thresholds
('lump_sum_annual_limit_eur',       'Ryczałt — limit roczny EUR',                  2000000.00, 'EUR',    'Art. 6 ust. 1 ustawy o ryczałcie',       '2022-01-01', NULL, 'jdg', 'LUMP_SUM', 'https://isap.sejm.gov.pl'),

-- Ordynacja Podatkowa / KKS
('ord_statute_of_limitations_years','Przedawnienie zobowiązań',                     5.00,       'YEARS',  'Art. 70 § 1 OrdPU',                      '1997-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('ord_cash_payment_limit',          'Limit płatności gotówkowej',                   15000.00,   'PLN',    'Art. 22p PIT',                           '2017-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('ord_whitelist_verification_days', 'Biała Lista — ważność weryfikacji',            30.00,      'DAYS',   'Art. 96b ust. 4a VAT',                   '2019-09-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),

-- Amortyzacja
('depr_one_off_limit',              'Amortyzacja jednorazowa — limit',              10000.00,   'PLN',    'Art. 22d ust. 1 PIT',                    '2018-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('depr_de_minimis_annual',          'Amortyzacja de minimis — limit roczny',        100000.00,  'PLN',    'Art. 22k ust. 7 PIT',                    '2018-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('depr_improvement_threshold',      'Ulepszenie środka trwałego — próg',            10000.00,   'PLN',    'Art. 22g ust. 17 PIT',                   '2018-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),

-- KSeF
('ksef_mandatory_from_date',        'KSeF obowiązkowy od',                          NULL,       'DATE',   'Art. 106na VAT',                         '2026-02-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('ksef_offline_grace_days',         'KSeF offline — okres na przesłanie',           7.00,       'DAYS',   'Art. 106ne VAT',                         '2026-02-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('ksef_sanction_max_pln',           'KSeF — max sankcja za brak',                   500000.00,  'PLN',    'Art. 106nq VAT',                         '2026-02-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),

-- Business / CEIDG
('business_suspension_max_months',  'Zawieszenie JDG — max okres',                  6.00,       'MONTHS', 'Art. 22 PP',                            '2018-04-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('business_unregistered_revenue_pct','Działalność nierejestrowana — % min. płacy',  0.50,       'PERCENT','Art. 5 PP',                              '2018-04-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),

-- Local taxes (Klasa IX)
('local_land_business_rate',        'Podatek od nieruchomości — grunt firmowy',     1.43,       'PLN/m²', 'Art. 5 UoPiOL',                          '2026-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('local_building_business_rate',    'Podatek od nieruchomości — budynek firmowy',   33.10,      'PLN/m²', 'Art. 5 UoPiOL',                          '2026-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),

-- CFC / Cross-border
('cfc_control_threshold',           'CFC — próg kontroli',                          0.50,       'PERCENT','Art. 30f ust. 2 PIT',                    '2015-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl'),
('cfc_passive_income_threshold',    'CFC — próg dochodu pasywnego',                 0.33,       'PERCENT','Art. 30f ust. 3 PIT',                    '2015-01-01', NULL, 'jdg', NULL, 'https://isap.sejm.gov.pl');

-- ═══════════════════════════════════════════════════════════════════════════════
-- SEED DATA: Temporal rule versions (A2)
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO rule_versions (rule_id, rule_version, rego_package, rego_location, rule_body_hash, legal_change_summary, valid_from, valid_to, superseded_by, created_by) VALUES
('P189', 1, 'jdg.vat', 'JDG/rules/vat/substantive.rego:189', 'sha256:abc123_v1', 'Przed SLIM VAT 3: 150 dni', '2017-01-01', '2025-06-30', 2, 'system'),
('P189', 2, 'jdg.vat', 'JDG/rules/vat/substantive.rego:195', 'sha256:def456_v2', 'SLIM VAT 3/2025: 150→90 dni', '2025-07-01', NULL, NULL, 'system'),
('P500', 1, 'jdg.pit.forms', 'JDG/rules/pit/forms.rego:500', 'sha256:ghi789_v1', 'Przed Polskim Ładem: kwota wolna 8k, próg 85 528', '2019-01-01', '2021-12-31', 2, 'system'),
('P500', 2, 'jdg.pit.forms', 'JDG/rules/pit/forms.rego:510', 'sha256:jkl012_v2', 'Polski Ład 2022: kwota wolna 30k, próg 120k', '2022-01-01', NULL, NULL, 'system'),
('P523', 1, 'jdg.pit.forms', 'JDG/rules/pit/forms.rego:523', 'sha256:mno345_v1', 'Przed Polskim Ładem: limit 250k EUR', '2019-01-01', '2021-12-31', 2, 'system'),
('P523', 2, 'jdg.pit.forms', 'JDG/rules/pit/forms.rego:530', 'sha256:pqr678_v2', 'Polski Ład 2022: limit 2M EUR', '2022-01-01', NULL, NULL, 'system');

-- ═══════════════════════════════════════════════════════════════════════════════
-- SEED DATA: Legal Cartography (A3)
-- ═══════════════════════════════════════════════════════════════════════════════

INSERT INTO jdg_legal_cartography (provision_id, act_key, article_number, article_title, jdg_rules, coverage_status, gaps_description) VALUES
('lex:VAT:Art113', 'I_vat', 113, 'Zwolnienie podmiotowe — limit 200 000 PLN',
 ARRAY['jdg.vat.a113.r1', 'jdg.edge_cases.vat_breach_mid_year', 'jdg.edge_cases.vat_breach_proportion_new_jdg'],
 'COMPLETE', NULL),
('lex:VAT:Art89a', 'I_vat', 89, 'Ulga na złe długi — wierzyciel (90 dni)',
 ARRAY['jdg.vat.a89a.r1', 'jdg.conflicts.bad_debt_creditor_vat_corrected_but_not_pit'],
 'COMPLETE', NULL),
('lex:VAT:Art89b', 'I_vat', 89, 'Złe długi — obowiązek korekty dłużnika',
 ARRAY['jdg.vat.a89b.r1', 'jdg.conflicts.bad_debt_debtor_vat_vs_pit_income'],
 'COMPLETE', NULL),
('lex:PIT:Art27', 'II_pit', 27, 'Skala podatkowa 12%/32%',
 ARRAY['jdg.pit.a27.r1', 'jdg.pit.forms.scale'],
 'COMPLETE', NULL),
('lex:PIT:Art30c', 'II_pit', 30, 'Podatek liniowy 19%',
 ARRAY['jdg.pit.a30c.r1', 'jdg.pit.forms.linear'],
 'COMPLETE', NULL),
('lex:PIT:Art30ca', 'II_pit', 30, 'IP Box — 5% od kwalifikowanego IP',
 ARRAY['jdg.pit.a30ca.r1', 'jdg.conflicts.ip_box_qualification_failed', 'jdg.conflicts.ip_box_vs_rd_same_income'],
 'COMPLETE', NULL),
('lex:KKS:Art62', 'IV_kks', 62, 'Puste faktury — kara do 25 lat',
 ARRAY['jdg.kks.empty_invoice_art62', 'jdg.kks.empty_invoice_issued', 'jdg.kks.empty_invoice_value_bands_p315'],
 'COMPLETE', NULL),
('lex:KKS:Art54', 'IV_kks', 54, 'Uchylanie się od opodatkowania',
 ARRAY['jdg.kks.tax_evasion_false_declaration', 'jdg.kks.tax_evasion_hiding_revenue', 'jdg.kks.tax_evasion_inflated_costs_p243'],
 'PARTIAL', 'Brak szczegółowych wariantów art. 54 § 2 (oszukańcze metody)'),
('lex:SUS:Art36a', 'V_sus', 36, 'Zawieszenie JDG — składki',
 ARRAY['jdg.business.suspension_zus', 'jdg.edge_cases.zus_declaration_zero_on_suspension'],
 'COMPLETE', NULL),
('lex:OP:Art70', 'III_ord', 70, 'Przedawnienie zobowiązań podatkowych (5 lat)',
 ARRAY['jdg.ord.a70.r1', 'jdg.liability.statute_5_years'],
 'COMPLETE', NULL);

-- ═══════════════════════════════════════════════════════════════════════════════
-- End of migration
-- ═══════════════════════════════════════════════════════════════════════════════
