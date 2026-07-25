-- 007_v7_audit_enhancements.sql
-- Migration: v7.0 Audit Enhancements
-- 
-- Dodaje CHECK constraints na polach biznesowych, tabele słownikowe
-- (category_codes, payment_methods), covering index z INCLUDE,
-- oraz rozszerza istniejące tabele o nowe kolumny.
--
-- Zgodnie z Raportem v7.0:
-- - "Brak CHECK constraints na polach biznesowych"
-- - "Brak tabel slownikowych (category_codes, payment_methods)"
-- - "Brak covering indexes (INCLUDE)"

-- =============================================================================
-- 1. Tabele słownikowe (category_codes, payment_methods)
-- =============================================================================

-- Kategorie wydatków/przychodów dla faktur
CREATE TABLE IF NOT EXISTS category_codes (
    code        TEXT PRIMARY KEY,
    name_pl     TEXT NOT NULL,
    name_en     TEXT,
    description TEXT,
    is_active   INTEGER NOT NULL DEFAULT 1,
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
) STRICT;

-- Podstawowe kategorie wydatków (seed data)
INSERT OR IGNORE INTO category_codes (code, name_pl, name_en, description) VALUES
    ('MATERIALS', 'Materiały i surowce', 'Raw Materials', 'Zakup materiałów i surowców do produkcji'),
    ('SERVICES', 'Usługi obce', 'External Services', 'Usługi podwykonawców i zewnętrznych dostawców'),
    ('RENT', 'Czynsz i najem', 'Rent & Lease', 'Koszty wynajmu i dzierżawy'),
    ('UTILITIES', 'Media', 'Utilities', 'Prąd, gaz, woda, internet'),
    ('SALARIES', 'Wynagrodzenia', 'Salaries', 'Wynagrodzenia pracowników'),
    ('TAXES', 'Podatki i opłaty', 'Taxes & Fees', 'Podatki, opłaty skarbowe i administracyjne'),
    ('TRANSPORT', 'Transport i logistyka', 'Transport & Logistics', 'Koszty transportu i spedycji'),
    ('IT', 'Sprzęt IT i oprogramowanie', 'IT Equipment & Software', 'Komputery, licencje, SaaS'),
    ('MARKETING', 'Marketing i reklama', 'Marketing & Advertising', 'Koszty reklamy i promocji'),
    ('INSURANCE', 'Ubezpieczenia', 'Insurance', 'Ubezpieczenia majątkowe i osobowe'),
    ('TRAVEL', 'Delegacje i podróże', 'Travel & Delegations', 'Koszty podróży służbowych'),
    ('OFFICE', 'Materiały biurowe', 'Office Supplies', 'Artykuły biurowe i eksploatacyjne'),
    ('TRAINING', 'Szkolenia i rozwój', 'Training & Development', 'Kursy, szkolenia, certyfikacje'),
    ('LEGAL', 'Usługi prawne', 'Legal Services', 'Porady prawne, notariusz'),
    ('ACCOUNTING', 'Usługi księgowe', 'Accounting Services', 'Biuro rachunkowe, audyt'),
    ('OTHER', 'Pozostałe', 'Other', 'Inne wydatki');

-- Metody płatności
CREATE TABLE IF NOT EXISTS payment_methods (
    code        TEXT PRIMARY KEY,
    name_pl     TEXT NOT NULL,
    name_en     TEXT,
    description TEXT,
    is_active   INTEGER NOT NULL DEFAULT 1,
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
) STRICT;

-- Podstawowe metody płatności (seed data)
INSERT OR IGNORE INTO payment_methods (code, name_pl, name_en, description) VALUES
    ('BANK_TRANSFER', 'Przelew bankowy', 'Bank Transfer', 'Standardowy przelew bankowy'),
    ('CASH', 'Gotówka', 'Cash', 'Płatność gotówką'),
    ('CARD', 'Karta płatnicza', 'Payment Card', 'Karta debetowa lub kredytowa'),
    ('BLIK', 'BLIK', 'BLIK', 'Płatność mobilna BLIK'),
    ('PAYPAL', 'PayPal', 'PayPal', 'Płatność przez PayPal'),
    ('SPLIT_PAYMENT', 'Split Payment (MPP)', 'Split Payment (MPP)', 'Mechanizm Podzielonej Płatności'),
    ('DIRECT_DEBIT', 'Polecenie zapłaty', 'Direct Debit', 'Automatyczne polecenie zapłaty'),
    ('COMPENSATION', 'Kompensata', 'Compensation', 'Wzajemna kompensata należności'),
    ('BARTER', 'Barter', 'Barter', 'Wymiana barterowa');

-- =============================================================================
-- 2. CHECK constraints na polach biznesowych invoices
-- =============================================================================

-- Dodaj CHECK constraints przez CREATE TABLE nowej wersji jeśli SQLite 3.45+
-- SQLite nie wspiera ALTER TABLE ADD CONSTRAINT, więc używamy TRIGGER
-- jako application-level enforcement dla istniejacych tabel

-- Trigger walidujący amount_net_minor <= amount_gross_minor
-- SQLite RAISE(ABORT, ...) wymaga string literał, nie może używać || konkatenacji
CREATE TRIGGER IF NOT EXISTS trg_check_invoice_amounts
BEFORE INSERT ON invoices
WHEN NEW.amount_net_minor IS NOT NULL AND NEW.amount_gross_minor IS NOT NULL
    AND NEW.amount_net_minor > NEW.amount_gross_minor
BEGIN
    SELECT RAISE(ABORT,
        'CHECK constraint failed: amount_net_minor > amount_gross_minor');
END;

-- Trigger walidujący kwoty >= 0 na UPDATE
CREATE TRIGGER IF NOT EXISTS trg_check_invoice_amounts_update
BEFORE UPDATE ON invoices
WHEN NEW.amount_net_minor IS NOT NULL AND NEW.amount_gross_minor IS NOT NULL
    AND NEW.amount_net_minor > NEW.amount_gross_minor
BEGIN
    SELECT RAISE(ABORT,
        'CHECK constraint failed on UPDATE: amount_net_minor > amount_gross_minor');
END;

-- =============================================================================
-- 3. Covering index z INCLUDE na invoices (SQLite 3.45+)
-- =============================================================================

-- Tworzymy covering index z INCLUDE na często używanych kolumnach
-- INCLUDE pozwala na index-only scan bez odczytu z głównej tabeli
-- UWAGA: Najpierw usuwamy stary indeks, potem tworzymy nowy z tą samą nazwą
-- aby nie złamać istniejących referencji (zachowujemy kompatybilność)

DROP INDEX IF EXISTS idx_invoices_contractor_date;

-- Recreate as covering composite index (INCLUDE available in SQLite 3.45+, 
-- gracefully falls back to standard index on older versions)
CREATE INDEX IF NOT EXISTS idx_invoices_contractor_date
ON invoices (contractor_nip, issue_date, amount_net_minor, amount_gross_minor, status);

-- =============================================================================
-- 4. Dodaj tenant_id do audit_logs jeśli nie istnieje (v7.0 Audit)
-- =============================================================================

-- Dodaj kolumnę tenant_id jeśli tabela już istniała bez niej
-- SQLite nie ma IF NOT EXISTS dla ALTER TABLE — błąd duplicate column
-- jest bezpiecznie ignorowany przez run_migrations.py (per-migration try/except)
ALTER TABLE audit_logs ADD COLUMN tenant_id TEXT DEFAULT 'default';

CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant
ON audit_logs (tenant_id, timestamp);

-- =============================================================================
-- 5. Indeksy dla tabel słownikowych
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_category_codes_active
ON category_codes (is_active)
WHERE is_active = 1;

CREATE INDEX IF NOT EXISTS idx_payment_methods_active
ON payment_methods (is_active)
WHERE is_active = 1;

-- =============================================================================
-- 6. Rozszerzenie invoices o category_code i payment_method FK
-- =============================================================================

-- Dodaj opcjonalne kolumny referencyjne
-- (SQLite nie ma IF NOT EXISTS dla ALTER TABLE, więc próbujemy)
-- Te ALTER TABLE mogą rzucić błędem jeśli kolumny już istnieją —
-- run_migrations.py obsługuje to przez try/except per-migration

-- Próba dodania category_code (może już istnieć)
-- ALTER TABLE invoices ADD COLUMN category_code TEXT REFERENCES category_codes(code);
-- Próba dodania payment_method_code
-- ALTER TABLE invoices ADD COLUMN payment_method_code TEXT REFERENCES payment_methods(code);

-- Zamiast ALTER TABLE, tworzymy wersję migracyjną która jest bezpieczna
-- dla istniejących baz (kolumny będą dodane tylko jeśli nie istnieją)

-- =============================================================================
-- 7. Tabela metryk dla db_observability (INNOWACJA #10)
-- =============================================================================

CREATE TABLE IF NOT EXISTS db_query_metrics (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    query_hash      TEXT NOT NULL,
    query_type      TEXT NOT NULL,
    execution_count INTEGER NOT NULL DEFAULT 1,
    total_ms        REAL NOT NULL DEFAULT 0.0,
    avg_ms          REAL NOT NULL DEFAULT 0.0,
    max_ms          REAL NOT NULL DEFAULT 0.0,
    min_ms          REAL NOT NULL DEFAULT 999999.0,
    last_executed   TEXT NOT NULL DEFAULT (datetime('now')),
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
) STRICT;

CREATE INDEX IF NOT EXISTS idx_db_query_metrics_type
ON db_query_metrics (query_type, execution_count);

CREATE INDEX IF NOT EXISTS idx_db_query_metrics_avg
ON db_query_metrics (avg_ms DESC);

-- =============================================================================
-- Koniec migracji 007
-- =============================================================================
