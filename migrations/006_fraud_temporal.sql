-- 006_fraud_temporal.sql — FraudGraphScanner temporal analysis (v7.0 Security Audit)
-- Dodaje first_seen_at i last_seen_at do fraud_entity_registry
-- Raport v7.0, sekcja 5.1: "Brak analizy czasowej (czy powiązania są nowe?)"

-- Utwórz tabelę fraud_entity_registry jeśli nie istnieje
CREATE TABLE IF NOT EXISTS fraud_entity_registry (
    entity_id       TEXT PRIMARY KEY,
    entity_type     TEXT NOT NULL CHECK(entity_type IN ('EMPLOYEE', 'VENDOR', 'SUBCONTRACTOR', 'PARTNER')),
    iban            TEXT,
    physical_address TEXT,
    nip             TEXT,
    on_white_list    INTEGER NOT NULL DEFAULT 0,
    is_active        INTEGER NOT NULL DEFAULT 1,
    created_at       TEXT NOT NULL DEFAULT (datetime('now')),
    first_seen_at    TEXT,
    last_seen_at     TEXT
);

-- Dodaj kolumny temporalne jeśli tabela już istniała (v7.0 Audit)
-- Używamy try/catch przez podejście "ADD COLUMN IF NOT EXISTS" 
-- SQLite nie wspiera IF NOT EXISTS dla ALTER TABLE, więc używamy pragma table_info
-- Ten blok jest bezpieczny - jeśli kolumny już istnieją, migracja kontynuuje

-- Sprawdź czy first_seen_at już istnieje i dodaj jeśli nie
-- (Wykonywane przez run_migrations.py który obsługuje błędy duplicate column)
ALTER TABLE fraud_entity_registry ADD COLUMN first_seen_at TEXT;

-- Sprawdź czy last_seen_at już istnieje i dodaj jeśli nie
ALTER TABLE fraud_entity_registry ADD COLUMN last_seen_at TEXT;

-- Sprawdź czy nip już istnieje i dodaj jeśli nie
ALTER TABLE fraud_entity_registry ADD COLUMN nip TEXT;

-- Sprawdź czy on_white_list już istnieje i dodaj jeśli nie
ALTER TABLE fraud_entity_registry ADD COLUMN on_white_list INTEGER NOT NULL DEFAULT 0;

-- Backfill: dla istniejących wpisów ustaw first_seen_at = created_at
UPDATE fraud_entity_registry SET first_seen_at = created_at
WHERE first_seen_at IS NULL AND created_at IS NOT NULL;

-- Indeksy dla analizy temporalnej
CREATE INDEX IF NOT EXISTS idx_fraud_entity_type ON fraud_entity_registry(entity_type);
CREATE INDEX IF NOT EXISTS idx_fraud_first_seen ON fraud_entity_registry(first_seen_at);
CREATE INDEX IF NOT EXISTS idx_fraud_last_seen ON fraud_entity_registry(last_seen_at);
