"""
SUPERMOC: Generated Columns (GENERATED ALWAYS AS ... STORED)

SQLite 3.31+ wspiera ``GENERATED ALWAYS AS (expr) STORED`` — kolumny,
których wartość jest automatycznie obliczana przez SQLite przy każdym
INSERT/UPDATE. Nie wymagają kodu Pythona do utrzymywania spójności.

Korzyści:
- Automatyczna kalkulacja VAT: amount_vat = amount_gross - amount_net
- Zero kodu Python do synchronizacji
- Atomiczność: SQLite aktualizuje w tej samej transakcji co INSERT
- Brak możliwości ręcznego ustawienia błędnej wartości

Usage:
    sqlite3 nexus_oltp.db < 0002_generated_columns.sql
"""

-- =========================================================================
-- Krok 1: Dodaj kolumny GENERATED ALWAYS AS ... STORED
-- =========================================================================

-- SUPERMOC: amount_vat — automatycznie obliczany VAT
-- amount_vat = amount_gross - amount_net
-- Przykład: amount_net=1000, amount_gross=1230 → amount_vat=230
-- Nie można ręcznie ustawić amount_vat na błędną wartość
ALTER TABLE invoices ADD COLUMN amount_vat REAL
    GENERATED ALWAYS AS (COALESCE(amount_gross, 0) - COALESCE(amount_net, 0)) STORED;

-- SUPERMOC: contractor_name_upper — case-insensitive sortowanie/wyszukiwanie
-- UPPER(name) dla szybkich zapytań WHERE UPPER(name) = 'KOWALSKI'
ALTER TABLE contractors ADD COLUMN name_upper TEXT
    GENERATED ALWAYS AS (UPPER(COALESCE(name, ''))) STORED;

-- SUPERMOC: is_high_value — czy faktura jest wysokowartościowa (>10k PLN)
-- Przydatne dla partial indexes i szybkich agregacji
ALTER TABLE invoices ADD COLUMN is_high_value INTEGER
    GENERATED ALWAYS AS (CASE WHEN COALESCE(amount_gross, 0) > 10000 THEN 1 ELSE 0 END) STORED;

-- =========================================================================
-- Krok 2: Indeksy na generated columns dla szybkich zapytań
-- =========================================================================

-- SUPERMOC: Partial index na wysokowartościowe faktury
-- Indeksuje tylko faktury > 10k PLN — mniejszy i szybszy indeks
CREATE INDEX IF NOT EXISTS idx_invoices_high_value
    ON invoices(is_high_value) WHERE is_high_value = 1;

-- SUPERMOC: Indeks na amount_vat dla szybkich agregacji
-- Szybkie: SELECT SUM(amount_vat) FROM invoices WHERE ...
CREATE INDEX IF NOT EXISTS idx_invoices_amount_vat
    ON invoices(amount_vat);

-- SUPERMOC: Indeks na contractor_name_upper dla case-insensitive search
-- Szybkie: SELECT * FROM contractors WHERE name_upper = UPPER('Kowalski')
CREATE INDEX IF NOT EXISTS idx_contractors_name_upper
    ON contractors(name_upper);

-- =========================================================================
-- Krok 3: Widok z generated columns dla łatwego dostępu
-- =========================================================================

-- SUPERMOC: Widok invoice_summary z pre-kalkulowanymi polami
-- Używa generated columns dla zerowego narzutu na zapytanie
CREATE VIEW IF NOT EXISTS invoice_summary AS
SELECT
    id,
    number,
    contractor_nip,
    amount_net,
    amount_gross,
    amount_vat,          -- generated column
    is_high_value,       -- generated column
    CASE
        WHEN amount_vat > 0 THEN ROUND(amount_vat / amount_net * 100, 2)
        ELSE 0
    END AS vat_rate_pct,
    CASE
        WHEN amount_gross > 0 THEN ROUND(amount_vat / amount_gross * 100, 2)
        ELSE 0
    END AS vat_share_pct,
    status,
    created_at
FROM invoices;

-- =========================================================================
-- Krok 4: Weryfikacja — sprawdź czy generated columns działają
-- =========================================================================

-- Test:
-- INSERT INTO invoices (id, number, amount_net, amount_gross)
-- VALUES ('test-001', 'FV/2026/TEST', 1000.00, 1230.00);
-- SELECT amount_net, amount_gross, amount_vat, is_high_value FROM invoices WHERE id = 'test-001';
-- Wynik: amount_net=1000, amount_gross=1230, amount_vat=230, is_high_value=0

-- SELECT * FROM invoice_summary WHERE id = 'test-001';
-- Wynik: amount_vat=230, vat_rate_pct=23.0, vat_share_pct=18.70
