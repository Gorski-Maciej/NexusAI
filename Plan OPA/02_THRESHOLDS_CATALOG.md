# 📊 Katalog Parametrów Dynamicznych (Thresholds)

> **Status:** Katalog v1.0  
> **Data:** 2026-07-07  
> **Powiązany:** `Plan OPA/00_PLAN_STRUKTURA.md`, `Plan OPA/01_INPUT_SPEC.md`

---

## 1. Zasady Zarządzania Thresholdami

### 1.1 Źródło prawdy

Wszystkie progi, stawki i limity są przechowywane w **DuckDB** w tabeli `tax_thresholds`:

```sql
CREATE TABLE IF NOT EXISTS tax_thresholds (
    threshold_key   VARCHAR PRIMARY KEY,
    threshold_value VARCHAR NOT NULL,
    valid_from      DATE NOT NULL DEFAULT '2024-01-01',
    valid_to        DATE,
    description     VARCHAR,
    legal_basis     VARCHAR,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indeks dla szybkiego wyszukiwania aktywnych thresholdów
CREATE INDEX IF NOT EXISTS idx_tax_thresholds_valid
    ON tax_thresholds(valid_from, valid_to);
```

### 1.2 Proces aktualizacji

```
Zmiana przepisów
    │
    ▼
DuckDB: INSERT/UPDATE tax_thresholds (z nowym valid_from)
    │
    ▼
NATS: Publikuj tax.thresholds.updated
    │
    ▼
HotReloadListener: Odśwież cache
    │
    ▼
OPA: Następna ewaluacja używa nowych wartości
    │
    ▼
ZERO zmian w kodzie Rego ✓
```

### 1.3 Temporalność thresholdów

Każdy threshold ma `valid_from` i opcjonalnie `valid_to`. Przy budowaniu `input` dla OPA, Python/Rust wybiera thresholdy obowiązujące w `input.invoice.transaction_date`:

```python
def get_thresholds_for_date(conn, transaction_date: str) -> dict:
    """Pobierz wszystkie thresholdy aktywne na daną datę."""
    rows = conn.execute("""
        SELECT threshold_key, threshold_value
        FROM tax_thresholds
        WHERE valid_from <= ?
          AND (valid_to IS NULL OR valid_to >= ?)
    """, [transaction_date, transaction_date]).fetchall()
    
    # Konwertuj płaską strukturę na zagnieżdżony JSON
    thresholds = {}
    for key, value in rows:
        parts = key.split(".")
        d = thresholds
        for part in parts[:-1]:
            d = d.setdefault(part, {})
        d[parts[-1]] = _parse_value(value)
    return thresholds
```

---

## 2. Kompletny Katalog Thresholdów

### 2.1 Stawki podatkowe (`thresholds.rates.*`)

| Klucz | Wartość | Typ | Podstawa prawna | Opis |
|---|---|---|---|---|
| `rates.vat_standard` | `"0.23"` | `string` | Art. 41 ust. 1 VAT | Podstawowa stawka VAT 23% |
| `rates.vat_reduced_8` | `"0.08"` | `string` | Art. 41 ust. 2 VAT + rozp. MF | Obniżona stawka VAT 8% |
| `rates.vat_reduced_5` | `"0.05"` | `string` | Art. 41 ust. 2a VAT + rozp. MF | Obniżona stawka VAT 5% |
| `rates.vat_zero` | `"0.00"` | `string` | Art. 83 VAT | Stawka 0% (eksport, WDT, zwolnienie przedmiotowe) |
| `rates.cit_standard` | `"0.19"` | `string` | Art. 19 ust. 1 CIT | Podstawowa stawka CIT 19% |
| `rates.cit_small` | `"0.09"` | `string` | Art. 19 ust. 1a CIT | CIT dla małego podatnika 9% |
| `rates.cit_estonian_effective` | `"0.20"` | `string` | Rozdz. 6b CIT | Efektywna stawka CIT estońskiego ~20% |
| `rates.pit_scale_low` | `"0.12"` | `string` | Art. 27 ust. 1 PIT | Skala podatkowa — I próg 12% |
| `rates.pit_scale_high` | `"0.32"` | `string` | Art. 27 ust. 1 PIT | Skala podatkowa — II próg 32% |
| `rates.pit_linear` | `"0.19"` | `string` | Art. 30c PIT | Podatek liniowy 19% |
| `rates.pit_ip_box` | `"0.05"` | `string` | Art. 30ca PIT | IP Box 5% |
| `rates.zus_pension` | `"0.1952"` | `string` | Art. 22 SUS | Składka emerytalna 19,52% |
| `rates.zus_disability` | `"0.08"` | `string` | Art. 22 SUS | Składka rentowa 8% |
| `rates.zus_sickness` | `"0.0245"` | `string` | Art. 22 SUS | Składka chorobowa 2,45% |
| `rates.zus_accident` | `"0.0167"` | `string` | Art. 22 SUS | Składka wypadkowa 1,67% |
| `rates.zus_health` | `"0.09"` | `string` | Art. 79 ustawy zdrowotnej | Składka zdrowotna 9% (skala) |
| `rates.zus_health_lump` | `"0.049"` | `string` | Art. 81 ustawy zdrowotnej | Składka zdrowotna 4,9% (liniowy/ryczałt) |
| `rates.zus_labour_fund` | `"0.0245"` | `string` | Art. 22 SUS | Fundusz Pracy 2,45% |
| `rates.zus_fgsp` | `"0.001"` | `string` | Art. 22 SUS | FGŚP 0,1% |

### 2.2 Limity kwotowe (`thresholds.limits.*`)

| Klucz | Wartość | Typ | Podstawa prawna | Opis |
|---|---|---|---|---|
| `limits.mpp_limit` | `15000` | `number` | Art. 108a VAT | Próg obowiązkowego MPP (15 000 PLN brutto) |
| `limits.vat_exemption_limit` | `200000` | `number` | Art. 113 ust. 1 VAT | Limit zwolnienia podmiotowego VAT |
| `limits.cash_transaction_limit` | `15000` | `number` | Art. 22p PIT / 15d CIT | Limit płatności gotówkowych (KUP) |
| `limits.bad_debt_days` | `150` | `number` | Art. 89a VAT | Dni do ulgi na złe długi |
| `limits.thin_cap_ratio` | `3.0` | `number` | Art. 15c CIT | Wskaźnik cienkiej kapitalizacji (zadłużenie:kapitał) |
| `limits.transfer_pricing_limit` | `10000000` | `number` | Art. 11a CIT | Próg dokumentacji cen transferowych |
| `limits.retention_years_invoice` | `5` | `number` | Art. 86 § 1 Ordynacji podatkowej | Okres przechowywania faktur |
| `limits.retention_years_ledger` | `5` | `number` | Art. 74 UoR | Okres przechowywania ksiąg rachunkowych |
| `limits.retention_years_payroll` | `10` | `number` | Art. 125a ustawy o emeryturach | Okres przechowywania list płac |
| `limits.trust_auto_post` | `0.92` | `number` | ADR-009 (polityka wewnętrzna) | Próg automatycznego księgowania |
| `limits.trust_suggest` | `0.75` | `number` | ADR-009 (polityka wewnętrzna) | Próg sugestii |

### 2.3 Progi podatkowe (`thresholds.bounds.*`)

| Klucz | Wartość | Typ | Podstawa prawna | Opis |
|---|---|---|---|---|
| `bounds.pit_scale_threshold` | `120000` | `number` | Art. 27 ust. 1 PIT | Próg między 12% a 32% |
| `bounds.pit_tax_free_amount` | `30000` | `number` | Art. 27 ust. 1a PIT | Kwota wolna od podatku |
| `bounds.pit_tax_free_reduction` | `3600` | `number` | Art. 27 ust. 1a PIT | Kwota zmniejszająca podatek (30 000 × 12% × 1/12...) |
| `bounds.pit_young_exemption_limit` | `85528` | `number` | Art. 21 ust. 1 pkt 148 PIT | Limit ulgi dla młodych |
| `bounds.pit_return_exemption_limit` | `85528` | `number` | Art. 21 ust. 1 pkt 152 PIT | Limit ulgi na powrót |
| `bounds.pit_family_4plus_limit` | `85528` | `number` | Art. 21 ust. 1 pkt 153 PIT | Limit ulgi dla rodzin 4+ |
| `bounds.relief_thermo_max` | `53000` | `number` | Art. 26h PIT | Maksymalna ulga termomodernizacyjna |
| `bounds.relief_internet_max` | `760` | `number` | Art. 26 PIT | Maksymalna ulga internetowa (rocznie) |
| `bounds.relief_internet_years` | `2` | `number` | Art. 26 PIT | Liczba lat ulgi internetowej |
| `bounds.relief_rd_base` | `100` | `number` | Art. 26e PIT / 18d CIT | Ulga B+R podstawowa (100%) |
| `bounds.relief_rd_centrum` | `200` | `number` | Art. 26e PIT / 18d CIT | Ulga B+R dla CBR (200%) |
| `bounds.relief_prototype_percent` | `30` | `number` | Art. 26eb PIT / 18db CIT | Ulga na prototyp (30%) |
| `bounds.relief_robotization_percent` | `50` | `number` | Art. 26gb PIT / 38eb CIT | Ulga na robotyzację (50%) |
| `bounds.relief_expansion_max` | `1000000` | `number` | Art. 26ec PIT / 18dc CIT | Maksymalna ulga na ekspansję |
| `bounds.zus_maly_plus_months` | `36` | `number` | Art. 18c SUS | Maksymalny okres Małego ZUS Plus |
| `bounds.zus_maly_plus_min_wage_percent` | `0.30` | `number` | Art. 18c SUS | Podstawa Małego ZUS (30% min. wynagrodzenia) |
| `bounds.zus_start_months` | `6` | `number` | Art. 18a SUS | Okres ulgi na start (bez składek społecznych) |
| `bounds.zus_preferential_months` | `24` | `number` | Art. 18a SUS | Okres preferencyjnego ZUS |

### 2.4 Progi field confidence (`thresholds.fc_thresholds.*`)

| Klucz | Wartość | Routing | Opis |
|---|---|---|---|
| `fc_thresholds.cit_standard_vat_rate` | `0.98` | BLOCK_AND_ALERT | CIT standard — VAT rate confidence |
| `fc_thresholds.cit_standard_total_net` | `0.95` | BLOCK_AND_ALERT | CIT standard — net amount confidence |
| `fc_thresholds.cit_standard_minimum` | `0.85` | BLOCK_AND_ALERT | CIT standard — minimum confidence |
| `fc_thresholds.cit_estonian_vat_rate` | `0.95` | BLOCK_AND_ALERT | CIT estoński — VAT rate confidence |
| `fc_thresholds.linear_minimum` | `0.85` | TRIAGE_QUEUE | Podatek liniowy — minimum |
| `fc_thresholds.lump_sum_vat_rate` | `0.95` | TRIAGE_QUEUE | Ryczałt — VAT rate confidence |
| `fc_thresholds.lump_sum_total_net` | `0.60` | TRIAGE_QUEUE | Ryczałt — net amount confidence |
| `fc_thresholds.mixed_auto_minimum` | `0.90` | BLOCK_AND_ALERT | Kategorie mieszane (samochody) |
| `fc_thresholds.representation_minimum` | `0.95` | BLOCK_AND_ALERT | Reprezentacja |
| `fc_thresholds.vendor_nip` | `0.80` | BLOCK_AND_ALERT | Uniwersalny — NIP confidence |
| `fc_thresholds.category_code` | `0.80` | TRIAGE_QUEUE | Uniwersalny — category confidence |
| `fc_thresholds.global_minimum` | `0.70` | TRIAGE_QUEUE | Uniwersalny — global minimum |

### 2.5 Stawki ryczałtu wg PKWiU (`thresholds.lump_sum_rates.*`)

| Klucz | Wartość | PKWiU | Opis |
|---|---|---|---|
| `lump_sum_rates.rate_17` | `"0.17"` | 69, 70, 71, 73, 74, 75, 77-82, 85.6 | Wolne zawody, doradztwo |
| `lump_sum_rates.rate_15` | `"0.15"` | 68.2, 68.3, 78, 79, 80, 81 | Pośrednictwo, kultura |
| `lump_sum_rates.rate_14` | `"0.14"` | 62.01, 95.11, 95.12 | IT, naprawa komputerów |
| `lump_sum_rates.rate_12` | `"0.12"` | 58.2, 62.02, 62.03, 62.09, 63, 95.2 | Software, hosting, naprawa |
| `lump_sum_rates.rate_10` | `"0.10"` | 41, 42, 43 | Budownictwo |
| `lump_sum_rates.rate_8_5` | `"0.085"` | 01-03, 05-39, 45-47, 49-53, 55, 56, 58.1, 59-61, 68.1, 72, 84-85.5, 86-88, 90-99 | Handel, produkcja, transport, edukacja |
| `lump_sum_rates.rate_5_5` | `"0.055"` | 41-43 (budowa z materiałów), 64-66 | Budownictwo z materiałem, finanse |
| `lump_sum_rates.rate_3` | `"0.03"` | 10-33, 56 | Produkcja żywności, gastronomia |
| `lump_sum_rates.rate_2` | `"0.02"` | 01-03, 10-33 (niektóre) | Produkcja rolna |

---

## 3. Seed Data — zapytania SQL

### 3.1 Inicjalizacja thresholdów

```sql
-- Stawki podatkowe
INSERT OR REPLACE INTO tax_thresholds (threshold_key, threshold_value, valid_from, description, legal_basis)
VALUES
    ('rates.vat_standard', '0.23', '2024-01-01', 'Podstawowa stawka VAT 23%', 'Art. 41 ust. 1 ustawy o VAT'),
    ('rates.vat_reduced_8', '0.08', '2024-01-01', 'Obniżona stawka VAT 8%', 'Art. 41 ust. 2 ustawy o VAT'),
    ('rates.vat_reduced_5', '0.05', '2024-01-01', 'Obniżona stawka VAT 5%', 'Art. 41 ust. 2a ustawy o VAT'),
    ('rates.vat_zero', '0.00', '2024-01-01', 'Stawka VAT 0%', 'Art. 83 ustawy o VAT'),
    ('rates.cit_standard', '0.19', '2024-01-01', 'CIT 19%', 'Art. 19 ust. 1 ustawy o CIT'),
    ('rates.cit_small', '0.09', '2024-01-01', 'CIT dla małego podatnika 9%', 'Art. 19 ust. 1a ustawy o CIT'),
    ('rates.cit_estonian_effective', '0.20', '2024-01-01', 'CIT estoński ~20%', 'Rozdział 6b ustawy o CIT'),
    ('rates.pit_scale_low', '0.12', '2024-01-01', 'PIT 12% — I próg', 'Art. 27 ust. 1 ustawy o PIT'),
    ('rates.pit_scale_high', '0.32', '2024-01-01', 'PIT 32% — II próg', 'Art. 27 ust. 1 ustawy o PIT'),
    ('rates.pit_linear', '0.19', '2024-01-01', 'Podatek liniowy 19%', 'Art. 30c ustawy o PIT'),
    ('rates.pit_ip_box', '0.05', '2024-01-01', 'IP Box 5%', 'Art. 30ca ustawy o PIT');

-- Limity kwotowe
INSERT OR REPLACE INTO tax_thresholds (threshold_key, threshold_value, valid_from, description, legal_basis)
VALUES
    ('limits.mpp_limit', '15000', '2024-01-01', 'Próg MPP', 'Art. 108a ustawy o VAT'),
    ('limits.vat_exemption_limit', '200000', '2024-01-01', 'Limit zwolnienia podmiotowego VAT', 'Art. 113 ust. 1 ustawy o VAT'),
    ('limits.cash_transaction_limit', '15000', '2024-01-01', 'Limit płatności gotówkowych', 'Art. 22p PIT / 15d CIT'),
    ('limits.bad_debt_days', '150', '2024-01-01', 'Dni dla ulgi na złe długi', 'Art. 89a ustawy o VAT'),
    ('limits.thin_cap_ratio', '3.0', '2024-01-01', 'Wskaźnik cienkiej kapitalizacji', 'Art. 15c ustawy o CIT');

-- Progi podatkowe
INSERT OR REPLACE INTO tax_thresholds (threshold_key, threshold_value, valid_from, description, legal_basis)
VALUES
    ('bounds.pit_scale_threshold', '120000', '2024-01-01', 'Próg 12%/32%', 'Art. 27 ust. 1 PIT'),
    ('bounds.pit_tax_free_amount', '30000', '2024-01-01', 'Kwota wolna od podatku', 'Art. 27 ust. 1a PIT'),
    ('bounds.relief_thermo_max', '53000', '2024-01-01', 'Max ulgi termomodernizacyjnej', 'Art. 26h PIT');

-- Field confidence
INSERT OR REPLACE INTO tax_thresholds (threshold_key, threshold_value, valid_from, description, legal_basis)
VALUES
    ('fc_thresholds.cit_standard_vat_rate', '0.98', '2024-01-01', 'CIT standard — VAT rate confidence', 'Polityka wewnętrzna'),
    ('fc_thresholds.vendor_nip', '0.80', '2024-01-01', 'NIP confidence — BLOCK', 'Polityka wewnętrzna'),
    ('fc_thresholds.global_minimum', '0.70', '2024-01-01', 'Global minimum — TRIAGE', 'Polityka wewnętrzna');
```

### 3.2 Aktualizacja thresholda (np. zmiana stawki VAT)

```sql
-- 1. Zamknij stary threshold
UPDATE tax_thresholds 
SET valid_to = '2026-06-30'
WHERE threshold_key = 'rates.vat_standard' AND valid_to IS NULL;

-- 2. Dodaj nowy threshold
INSERT INTO tax_thresholds (threshold_key, threshold_value, valid_from, description, legal_basis)
VALUES ('rates.vat_standard', '0.24', '2026-07-01', 'Podstawowa stawka VAT 24%', 'Art. 41 ust. 1 ustawy o VAT (nowelizacja)');

-- 3. Opublikuj przez NATS
-- NATS: tax.thresholds.updated
```

---

## 4. Rego Helper — odczyt thresholdów

```rego
# Helper: pobierz stawkę VAT dla danego poziomu
get_vat_rate(level) = rate {
    level == "standard"
    rate := input.thresholds.rates.vat_standard
} else = rate {
    level == "reduced_8"
    rate := input.thresholds.rates.vat_reduced_8
} else = rate {
    level == "reduced_5"
    rate := input.thresholds.rates.vat_reduced_5
} else = rate {
    level == "zero"
    rate := input.thresholds.rates.vat_zero
} else = rate {
    # Fallback
    rate := "0.23"
}

# Helper: sprawdź czy kwota przekracza próg MPP
is_over_mpp_limit {
    input.invoice.amount_gross >= input.thresholds.limits.mpp_limit
}
```

---

## 5. Odniesienia

- **Master Plan:** `Plan OPA/00_PLAN_STRUKTURA.md`
- **Input Spec:** `Plan OPA/01_INPUT_SPEC.md`
- **Detailed Rules:** `Plan OPA/03_RULES_DETAILED.md`
