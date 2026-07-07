# 🏛️ Plan Reguł OPA/Rego dla NexusAI — Silnik Decyzyjny ENTERPRISE

> **Status:** Plan Architektoniczny v1.0  
> **Data:** 2026-07-07  
> **Autor:** Zespół NexusAI  
> **Zakres:** Wyłącznie katalog `Plan OPA/` w repozytorium  
> **Źródła prawne:** `Plan OPA/Docs` — kompletny wykaz ustaw, rozporządzeń i interpretacji

---

## 0. Filozofia Projektowa

### 0.1 Fundamenty architektoniczne

System reguł NexusAI opiera się na czterech nienaruszalnych zasadach:

| Zasada | Opis | Implementacja |
|--------|------|---------------|
| **First-Match-Wins** | Pierwsza pasująca reguła wygrywa — deterministyczna kolejność | Rego `else` chain |
| **Zero Hardcoded Values** | Żadna liczba (stawka, próg, limit) nie jest zakodowana w `.rego` | Wszystko przez `input.thresholds.*` |
| **Temporalność** | Reguły obowiązują od-do; ta sama faktura z 2021 używa stawek z 2021 | `valid_from` / `valid_to` w warunkach |
| **Audytowalność** | Każda decyzja ma ślad: która reguła, dlaczego, na jakiej podstawie | `rule_id`, `_legal_basis` w werdykcie |

### 0.2 Model danych (przepływ)

```
DuckDB RuleStore           OPA Policy (Rego)            Werdykt
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│ tax_rules        │──►    │ package tax.xxx   │──►    │ {                │
│  rule_id         │       │                   │       │   "matched":true,│
│  condition_sql   │       │ default decide =  │       │   "rule_id":"...",│
│  action_json     │       │   {...}           │       │   "vat_rate":"..",│
│  priority        │       │                   │       │   "gtu_code":"..",│
│  valid_from/to   │       │ decide = {...} {  │       │   "_routing":"..",│
└──────────────────┘       │   cond1           │       │   "_legal_basis":│
        │                  │ } else = {...} {  │       │     "Art.41..."  │
        ▼                  │   cond2           │       │ }                │
┌──────────────────┐       │ } ...             │       └──────────────────┘
│ thresholds       │──►    └──────────────────┘
│  rates           │                │
│  limits          │                ▼
│  days            │       ┌──────────────────┐
└──────────────────┘       │ input (JSON)     │
                           │  invoice.*       │
                           │  vendor.*        │
                           │  company.*       │
                           │  confidence.*    │
                           │  thresholds.*    │
                           └──────────────────┘
```

### 0.3 Konwencja nazewnicza werdyktu

Każda reguła zwraca ustandaryzowany obiekt:

```rego
{
    "matched": true,                    # Czy reguła dopasowana
    "rule_id": "vat.gtu.fuel.pl",       # Unikalny identyfikator
    "package": "tax.vat.substantive",   # Pakiet źródłowy
    "priority": 65,                     # Priorytet
    "vat_rate": "0.23",                 # Stawka VAT (string "0.23" = 23%)
    "rounding_level": "position",       # "position" | "total"
    "gtu_code": "GTU_04",              # Kod GTU (lub "")
    "procedure": "",                    # "VAT_REVERSE_CHARGE" | "IMPORT" | "MARGIN" | ""
    "income_tax_qualification": "deductible_full",  # Kwalifikacja KUP
    "_routing": "",                     # "BLOCK_AND_ALERT" | "TRIAGE_QUEUE" | ""
    "_routing_reason": "",             # Czytelny powód routingu
    "_legal_basis": "Art.41 ust.1",    # Podstawa prawna
    "_warnings": []                     # Ostrzeżenia (MPP, terminy, etc.)
}
```

---

## 1. Architektura Pakietów i Priorytetów

### 1.1 Hierarchia pakietów (drzewo)

```
policies/
├── tax/
│   ├── risk.rego              # P0-P9:   Ryzyko i fraud (NAJWYŻSZY)
│   ├── routing.rego           # P10-P19: Field confidence + routing
│   ├── compliance.rego        # P20-P39: Zgodność dokumentacyjna
│   ├── crossborder.rego       # P40-P49: Transakcje transgraniczne
│   ├── vat/
│   │   ├── substantive.rego   # P50-P69: Reguły merytoryczne VAT
│   │   ├── gtu.rego           # P50-P69: Mapowanie kategorii→GTU
│   │   └── exemptions.rego    # P50-P69: Zwolnienia VAT
│   ├── direct/
│   │   ├── cit.rego           # P70-P79: CIT (standard/estoński/mały)
│   │   ├── pit.rego           # P70-P79: PIT (skala/liniowy/ryczałt)
│   │   └── deductions.rego    # P70-P79: Wspólne odliczenia
│   ├── allowances.rego        # P80-P89: Ulgi podatkowe
│   ├── accounting.rego        # P90-P94: Reguły rachunkowe
│   ├── zus.rego               # P95-P99: Składki ZUS i zdrowotne
│   ├── uor_books.rego         # P320-P321, P326: UoR księgi, podwójny zapis, dowody
│   ├── uor_valuation.rego     # P322, P330: UoR rezerwy, koszt wytworzenia
│   ├── uor_reports.rego       # P327: UoR klasyfikacja bilansowa
│   ├── cit_deductions.rego    # P323: CIT ulga na złe długi (wierzyciel)
│   ├── vat_registration.rego  # P324: VAT-R obowiązkowa rejestracja
│   ├── ordynacja_extended.rego # P325, P329: Ordynacja zabezpieczenia, ulgi
│   ├── labor_extended.rego    # P328: KP badania BHP/medycyna pracy KUP
│   ├── pit_withholding.rego   # P331: PIT małe umowy ryczałt 12%
│   └── fallback.rego          # P100+:   Reguły domyślne
└── tests/
    ├── tax_rules_test.rego
    ├── vat_test.rego
    ├── cit_test.rego
    ├── pit_test.rego
    └── compliance_test.rego
```

### 1.2 Macierz priorytetów

| Zakres priorytetów | Pakiet | Odpowiedzialność | Skutek dopasowania |
|---|---|---|---|
| **P0-P9** | `tax.risk` | Fraud, anomalie, semantic guard | BLOCK — faktura zablokowana |
| **P10-P19** | `tax.routing` | OCR confidence, field quality | BLOCK_AND_ALERT / TRIAGE_QUEUE |
| **P20-P39** | `tax.compliance` | Biała lista, MPP, KSeF, retencja | BLOCK / MPP flag / ostrzeżenia |
| **P40-P49** | `tax.crossborder` | UE reverse charge, import, export | Procedura specjalna |
| **P50-P69** | `tax.vat.*` | Stawki VAT, GTU, zwolnienia | Stawka + GTU + metoda zaokrąglania |
| **P70-P79** | `tax.direct.*` | CIT/PIT — kwalifikacja kosztów, stawki | Stawka podatku + KUP |
| **P80-P89** | `tax.allowances` | Ulgi: B+R, IP Box, termo, prototyp | Odliczenie / preferencja |
| **P90-P94** | `tax.accounting` | Amortyzacja, FIFO, RMK, rewaluacja FX | Metoda księgowa |
| **P95-P99** | `tax.zus` | Składki ZUS, zdrowotna, ulgi składkowe | Stawki składek |
| **P100+** | `tax.fallback` | Domyślne reguły dla PL i nieznanych | Fallback 23% VAT |
| **P320-P331** | `tax.uor_books`, `tax.uor_valuation`, `tax.uor_reports`, `tax.cit_deductions`, `tax.vat_registration`, `tax.ordynacja_extended`, `tax.labor_extended`, `tax.pit_withholding` | Deep Docs: podwójny zapis, zamknięcie ksiąg, rezerwy UoR, dowody, bilans, wycena, CIT złe długi, VAT-R, zabezpieczenia, ulgi w spłacie, BHP, małe umowy PIT | BLOCK/TRIAGE/dedukcje |

### 1.3 Diagram pierwszeństwa (first-match-wins)

```
INPUT ──────────────────────────────────────────────────────────────────────► WERDYKT

P0 ──► fraud_graph_match          Czy kontrahent w sieci fraudowej?
P2 ──► anomaly_amount             Czy kwota odbiega >3σ od średniej?
P5 ──► semantic_guard             Czy wydatek oczywiście niedozwolony?
         │
P10──► ocr_vat_confidence_low     Czy OCR VAT rate poniżej progu?
P15──► ocr_nip_confidence_low     Czy OCR NIP poniżej progu?
         │
P20──► whitelist_missing          Czy brak na Białej Liście >15k PLN?
P25──► split_payment_mandatory    Czy obowiązkowy MPP?
P30──► ksef_retention_flag        Okres przechowywania dokumentu
         │
P40──► eu_reverse_charge          Czy WDT/unijne reverse charge?
P45──► import_non_eu              Czy import spoza UE?
P48──► export_goods               Czy eksport towarów (0% VAT)?
         │
P50──► vat_margin_scheme          Czy procedura marży?
P55──► vat_23_exemption           Czy zwolnienie podmiotowe VAT?
P60──► bad_debt_relief            Czy ulga na złe długi?
P65──► vat_gtu_mapping            Mapowanie kategorii na kod GTU
         │
P70──► cit_estonian_rules         Estoński CIT — ukryta dywidenda?
P72──► cit_thin_cap               Cienka kapitalizacja / TP?
P74──► pit_lump_sum_rate          Stawka ryczałtu wg PKWiU
P76──► pit_joint_filing           Wspólne rozliczenie małżonków
         │
P80──► relief_rd_proto            Ulga B+R / prototyp
P82──► relief_ip_box              IP Box 5%
P85──► relief_thermo              Ulga termomodernizacyjna
         │
P90──► acc_depreciation           Metoda amortyzacji (liniowa/degresywna)
P92──► acc_rmk_deferral           RMK — rozliczenia międzyokresowe
P94──► acc_fx_revaluation         Rewaluacja walutowa
         │
P95──► zus_maly_plus              Mały ZUS Plus — obniżona podstawa
P98──► zus_health_contrib         Składka zdrowotna 9% / 4.9%
         │
P100─► domestic_fallback          Domyślna stawka PL 23%
         │
P320─► uor_double_entry_validation  Czy zapis Wn=Ma?
P321─► uor_closing_books            Czy księgi zamknięte?
P323─► cit_bad_debt_creditor        Ulga CIT na złe długi (wierzyciel)
P324─► vat_registration_mandatory   Czy wymagany VAT-R?
P325─► ord_tax_securing             Zabezpieczenie US
P326─► uor_evidence_fields           Czy dowód ma strony + opis?
P327─► uor_bs_classification        Aktywa trwałe vs obrotowe
P328─► labor_ohs_exams_kup          Badania BHP → 100% KUP
P329─► ord_payment_relief           Opłata prolongacyjna
P330─► uor_manufacturing_cost       Koszt wytworzenia vs zakup
P331─► pit_small_mandate            Umowa ≤200 PLN → ryczałt 12%
         │
P200─► no_match                   NO_MATCHING_RULE (zawsze na końcu)
```

---

## 2. Struktura Danych Wejściowych (`input`)

### 2.1 Pełna specyfikacja `input`

```json
{
  "invoice": {
    "transaction_date": "2026-06-15",
    "category_code": "IT_OFFICE",
    "amount_net": 10000.00,
    "amount_net_grosze": 1000000,
    "amount_gross": 12300.00,
    "amount_gross_grosze": 1230000,
    "currency": "PLN",
    "procedure": "",
    "expense_type": "OPERATIONAL",
    "pkwiu_code": "62.01.12.0",
    "is_cash_payment": false
  },
  "vendor": {
    "nip": "1234567890",
    "country": "PL",
    "vat_status": "active",
    "on_whitelist": true,
    "whitelist_checked_at": "2026-06-15T10:00:00Z",
    "account_on_whitelist": true,
    "pkd": "62.01.Z",
    "is_related_party": false,
    "trust_score": 0.92
  },
  "company": {
    "tax_form": "CIT_STANDARD",
    "zus_status": "STANDARD",
    "is_vat_payer": true,
    "is_small_taxpayer": false,
    "annual_turnover_net": 500000.00,
    "has_rd_status": false,
    "fiscal_year_start": "2026-01-01",
    "employees_count": 5
  },
  "confidence": {
    "fc_minimum": 0.95,
    "fc_vat_rate": 0.98,
    "fc_total_net": 0.97,
    "fc_vendor_nip": 0.99,
    "fc_category_code": 0.96,
    "fc_invoice_number": 0.99
  },
  "thresholds": {
    "mpp_limit": 15000,
    "vat_exemption_limit": 200000,
    "vat_exemption_limit_startup": 200000,
    "cash_transaction_limit": 15000,
    "bad_debt_days": 150,
    "thin_cap_ratio": 3.0,
    "transfer_pricing_limit": 10000000,
    "retention_years_invoice": 5,
    "retention_years_ledger": 5,
    "retention_years_payroll": 10,
    "trust_auto_post": 0.92,
    "trust_suggest": 0.75,
    "rates": {
      "vat_standard": "0.23",
      "vat_reduced_8": "0.08",
      "vat_reduced_5": "0.05",
      "vat_zero": "0.00",
      "cit_standard": "0.19",
      "cit_small": "0.09",
      "cit_estonian_effective": "0.20",
      "pit_scale_low": "0.12",
      "pit_scale_high": "0.32",
      "pit_linear": "0.19",
      "pit_ip_box": "0.05",
      "zus_pension": "0.1952",
      "zus_disability": "0.08",
      "zus_sickness": "0.0245",
      "zus_accident": "0.0167",
      "zus_health": "0.09",
      "zus_health_lump": "0.049",
      "zus_labour_fund": "0.0245",
      "zus_fgsp": "0.001"
    },
    "bounds": {
      "pit_scale_threshold": 120000,
      "pit_tax_free_amount": 30000,
      "pit_tax_free_reduction": 3600,
      "pit_young_exemption_limit": 85528,
      "pit_return_exemption_limit": 85528,
      "pit_family_4plus_limit": 85528,
      "relief_thermo_max": 53000,
      "relief_internet_max": 760,
      "relief_internet_years": 2,
      "relief_rd_base": 100,
      "relief_rd_centrum": 200,
      "relief_prototype_percent": 30,
      "relief_robotization_percent": 50,
      "relief_expansion_max": 1000000,
      "amortization_rates": {},
      "zus_maly_plus_months": 36,
      "zus_maly_plus_min_wage_percent": 0.30,
      "zus_start_months": 6
    },
    "fc_thresholds": {
      "cit_standard_vat_rate": 0.98,
      "cit_standard_total_net": 0.95,
      "cit_standard_minimum": 0.85,
      "cit_estonian_vat_rate": 0.95,
      "linear_minimum": 0.85,
      "lump_sum_vat_rate": 0.95,
      "lump_sum_total_net": 0.60,
      "mixed_auto_minimum": 0.90,
      "representation_minimum": 0.95,
      "vendor_nip": 0.80,
      "category_code": 0.80,
      "global_minimum": 0.70
    }
  }
}
```

### 2.2 Źródła danych

| Sekcja `input` | Źródło w NexusAI | Aktualizacja |
|---|---|---|
| `invoice.*` | OCR Pipeline + KSeF API | Per faktura |
| `vendor.*` | GUS BIR + Biała Lista MF + VendorIntelligence | Cache 30 dni |
| `company.*` | Konfiguracja użytkownika (konfiguracja TOML) | Manualnie / przy zmianie |
| `confidence.*` | OCR Consensus Engine | Per faktura |
| `thresholds.*` | DuckDB RuleStore (`tax_thresholds` table) | Hot-reload przez NATS |

---

## 3. Katalog Parametrów Dynamicznych (`thresholds`)

### 3.1 Tabela thresholdów w DuckDB

```sql
CREATE TABLE IF NOT EXISTS tax_thresholds (
    threshold_key   VARCHAR PRIMARY KEY,
    threshold_value VARCHAR NOT NULL,
    valid_from      DATE NOT NULL,
    valid_to        DATE,
    description     VARCHAR,
    legal_basis     VARCHAR,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3.2 Pełny katalog thresholdów

#### Stawki podatkowe (`thresholds.rates.*`)

| Klucz | Wartość domyślna | Podstawa prawna | Opis |
|---|---|---|---|
| `rates.vat_standard` | `"0.23"` | Art. 41 ust. 1 ustawy o VAT | Podstawowa stawka VAT |
| `rates.vat_reduced_8` | `"0.08"` | Art. 41 ust. 2 + rozp. MF | Obniżona stawka 8% |
| `rates.vat_reduced_5` | `"0.05"` | Art. 41 ust. 2a + rozp. MF | Obniżona stawka 5% |
| `rates.vat_zero` | `"0.00"` | Art. 83 ustawy o VAT | Stawka 0% (eksport, WDT, zw.) |
| `rates.cit_standard` | `"0.19"` | Art. 19 ust. 1 ustawy o CIT | Podstawowa stawka CIT |
| `rates.cit_small` | `"0.09"` | Art. 19 ust. 1a ustawy o CIT | CIT dla małego podatnika |
| `rates.cit_estonian_effective` | `"0.20"` | Rozdział 6b ustawy o CIT | Efektywna stawka CIT estońskiego |
| `rates.pit_scale_low` | `"0.12"` | Art. 27 ust. 1 ustawy o PIT | Skala podatkowa — I próg |
| `rates.pit_scale_high` | `"0.32"` | Art. 27 ust. 1 ustawy o PIT | Skala podatkowa — II próg |
| `rates.pit_linear` | `"0.19"` | Art. 30c ustawy o PIT | Podatek liniowy |
| `rates.pit_ip_box` | `"0.05"` | Art. 30ca ustawy o PIT | IP Box |
| `rates.zus_pension` | `"0.1952"` | Art. 22 ustawy o SUS | Składka emerytalna |
| `rates.zus_disability` | `"0.08"` | Art. 22 ustawy o SUS | Składka rentowa |
| `rates.zus_sickness` | `"0.0245"` | Art. 22 ustawy o SUS | Składka chorobowa |
| `rates.zus_accident` | `"0.0167"` | Art. 22 ustawy o SUS | Składka wypadkowa |
| `rates.zus_health` | `"0.09"` | Art. 79 ustawy zdrowotnej | Składka zdrowotna |
| `rates.zus_health_lump` | `"0.049"` | Art. 81 ustawy zdrowotnej | Składka zdrow. (ryczałt/liniowy) |
| `rates.zus_labour_fund` | `"0.0245"` | Art. 22 ustawy o SUS | Fundusz Pracy |
| `rates.zus_fgsp` | `"0.001"` | Art. 22 ustawy o SUS | FGŚP |

#### Limity i progi (`thresholds.bounds.*`)

| Klucz | Wartość domyślna | Podstawa prawna | Opis |
|---|---|---|---|
| `bounds.pit_scale_threshold` | `120000` | Art. 27 ust. 1 PIT | Próg między 12% a 32% |
| `bounds.pit_tax_free_amount` | `30000` | Art. 27 ust. 1a PIT | Kwota wolna od podatku |
| `bounds.pit_young_exemption_limit` | `85528` | Art. 21 ust. 1 pkt 148 PIT | Ulga dla młodych |
| `bounds.relief_thermo_max` | `53000` | Art. 26h PIT | Ulga termomodernizacyjna |
| `bounds.relief_internet_max` | `760` | Art. 26 PIT | Ulga na internet (rocznie) |
| `bounds.zus_maly_plus_months` | `36` | Art. 18c SUS | Okres Małego ZUS Plus |
| `bounds.zus_start_months` | `6` | Art. 18a SUS | Okres ulgi na start |

#### Progi field confidence (`thresholds.fc_thresholds.*`)

| Klucz | Wartość domyślna | Routing |
|---|---|---|
| `fc_thresholds.cit_standard_vat_rate` | `0.98` | BLOCK_AND_ALERT |
| `fc_thresholds.cit_standard_total_net` | `0.95` | BLOCK_AND_ALERT |
| `fc_thresholds.cit_standard_minimum` | `0.85` | BLOCK_AND_ALERT |
| `fc_thresholds.vendor_nip` | `0.80` | BLOCK_AND_ALERT |
| `fc_thresholds.category_code` | `0.80` | TRIAGE_QUEUE |
| `fc_thresholds.global_minimum` | `0.70` | TRIAGE_QUEUE |

---

## 4. Szczegółowy Opis Reguł

### 4.1 Pakiet `tax.risk` — Ryzyko i Fraud (P0-P9)

#### P0: `fraud_graph_match`
- **Cel biznesowy:** Wykrycie kontrahenta w sieci fraudowej VAT (karuzela podatkowa)
- **Przesłanki:** `input.vendor.nip` znajduje się w grafie fraudowym (FraudGraphScanner)
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `fraud_detected: true`
- **Podstawa prawna:** Art. 86 ust. 1 ustawy o VAT (prawo do odliczenia), art. 55 KKS
- **Zależności:** FraudGraphScanner musi wcześniej oznaczyć vendor.fraud_flag
- **Priorytet:** 0 (najwyższy — blokuje wszystko)

#### P2: `anomaly_amount`
- **Cel biznesowy:** Wykrycie anomalii kwotowej (>3σ od średniej dla danej kategorii)
- **Przesłanki:** `input.invoice.amount_net > (avg_category_amount + 3 * stddev_category_amount)`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `_anomaly_zscore: <value>`
- **Podstawa prawna:** Art. 22 UoR (zasada ostrożności)
- **Priorytet:** 2

#### P5: `semantic_guard_disallowed`
- **Cel biznesowy:** Wykrycie wydatków niezwiązanych z działalnością (alkohol, rozrywka)
- **Przesłanki:** `SemanticGuard` oznacza wydatek jako `disallowed`
- **Rezultat:** `income_tax_qualification: "non_deductible"`, `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 23 PIT, art. 16 ust. 1 pkt 28 CIT
- **Priorytet:** 5

---

### 4.2 Pakiet `tax.routing` — Field Confidence (P10-P19)

#### P10: `fc_vat_rate_low`
- **Cel biznesowy:** Niska pewność stawki VAT → blokada automatycznego księgowania
- **Przesłanki:** `input.company.tax_form` == `"CIT_STANDARD"` AND `input.confidence.fc_vat_rate < input.thresholds.fc_thresholds.cit_standard_vat_rate` AND `input.confidence.fc_vat_rate > 0`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 22 UoR (rzetelność ksiąg)
- **Priorytet:** 10

#### P11: `fc_total_net_low_cit`
- **Cel biznesowy:** Niska pewność kwoty netto dla CIT → blokada
- **Przesłanki:** `input.company.tax_form` in `["CIT_STANDARD", "CIT_ESTONIAN"]` AND `input.confidence.fc_total_net < input.thresholds.fc_thresholds.cit_standard_total_net`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`
- **Priorytet:** 11

#### P12: `fc_vendor_nip_low`
- **Cel biznesowy:** Niska pewność NIP kontrahenta (>15k PLN → problem z Białą Listą)
- **Przesłanki:** `input.confidence.fc_vendor_nip < input.thresholds.fc_thresholds.vendor_nip` AND `input.confidence.fc_vendor_nip > 0`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 96b ustawy o VAT (Biała Lista), art. 22 UoR
- **Priorytet:** 12

#### P13-P18: Reguły per forma podatkowa
- **P13:** `fc_cit_estonian` — CIT estoński, niższe progi
- **P14:** `fc_linear_minimum` — Podatek liniowy, TRIAGE_QUEUE
- **P15:** `fc_lump_sum_vat` — Ryczałt, TRIAGE_QUEUE
- **P16:** `fc_lump_sum_net` — Ryczałt, niższy próg dla kwot
- **P17:** `fc_mixed_auto_minimum` — Kategorie mieszane (samochody)
- **P18:** `fc_representation_minimum` — Reprezentacja (najwyższe wymagania)

#### P19: `fc_global_minimum_low`
- **Cel biznesowy:** Ogólnie niska pewność → TRIAGE
- **Przesłanki:** `input.confidence.fc_minimum < input.thresholds.fc_thresholds.global_minimum`
- **Rezultat:** `_routing: "TRIAGE_QUEUE"`
- **Priorytet:** 19

---

### 4.3 Pakiet `tax.compliance` — Zgodność dokumentacyjna (P20-P39)

#### P20: `whitelist_missing_over_limit`
- **Cel biznesowy:** Weryfikacja Białej Listy MF dla przelewów >15 000 PLN
- **Przesłanki:** `input.invoice.amount_gross >= input.thresholds.mpp_limit` AND `input.vendor.on_whitelist == false`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `_warning: "Brak kontrahenta na Białej Liście MF"`
- **Podstawa prawna:** Art. 96b ustawy o VAT, art. 117ba Ordynacji podatkowej
- **Priorytet:** 20

#### P21: `whitelist_account_mismatch`
- **Cel biznesowy:** Rachunek kontrahenta niezgodny z Białą Listą
- **Przesłanki:** `input.invoice.amount_gross >= input.thresholds.mpp_limit` AND `input.vendor.account_on_whitelist == false`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, odpowiedzialność solidarna
- **Podstawa prawna:** Art. 117ba § 1 Ordynacji podatkowej
- **Priorytet:** 21

#### P25: `split_payment_mandatory`
- **Cel biznesowy:** Obowiązkowy MPP dla faktur >15k PLN z towarami wrażliwymi
- **Przesłanki:** `input.invoice.amount_gross >= input.thresholds.mpp_limit` AND kategoria w załączniku nr 15
- **Rezultat:** `mpp_required: true`, `_warning: "Obowiązkowy mechanizm podzielonej płatności"`
- **Podstawa prawna:** Art. 108a ustawy o VAT
- **Priorytet:** 25

#### P30: `ksef_retention_faktura`
- **Cel biznesowy:** Określenie okresu przechowywania dokumentu
- **Przesłanki:** Typ dokumentu = faktura VAT
- **Rezultat:** `retention_years: input.thresholds.retention_years_invoice`
- **Podstawa prawna:** Art. 86 § 1 Ordynacji podatkowej, art. 74 UoR
- **Priorytet:** 30

#### P35: `cash_transaction_over_limit`
- **Cel biznesowy:** Płatność gotówkowa powyżej 15k PLN → brak KUP
- **Przesłanki:** `input.invoice.is_cash_payment == true` AND `input.invoice.amount_gross >= input.thresholds.cash_transaction_limit`
- **Rezultat:** `income_tax_qualification: "non_deductible"`, `_warning: "Płatność gotówkowa powyżej limitu"`
- **Podstawa prawna:** Art. 22p ustawy o PIT, art. 15d ustawy o CIT
- **Priorytet:** 35

---

### 4.4 Pakiet `tax.crossborder` — Transakcje transgraniczne (P40-P49)

#### P40: `eu_reverse_charge`
- **Cel biznesowy:** Wewnątrzwspólnotowe nabycie — reverse charge
- **Przesłanki:** `input.vendor.country` == `"EU"` AND `input.vendor.vat_status` == `"active"`
- **Rezultat:** `vat_rate: "0.00"`, `procedure: "VAT_REVERSE_CHARGE"`, `gtu_code: "GTU_12"`
- **Podstawa prawna:** Art. 17 ust. 1 pkt 3 ustawy o VAT
- **Priorytet:** 40

#### P41: `eu_reverse_charge_import_uslug`
- **Cel biznesowy:** Import usług z UE — reverse charge
- **Przesłanki:** `input.vendor.country` == `"EU"` AND kategoria = usługa AND `input.vendor.vat_status` == `"active"`
- **Rezultat:** `vat_rate: "0.00"`, `procedure: "VAT_REVERSE_CHARGE"`
- **Podstawa prawna:** Art. 28b ustawy o VAT (miejsce świadczenia usług)
- **Priorytet:** 41

#### P42: `eu_reverse_charge_wdt`
- **Cel biznesowy:** Wewnątrzwspólnotowa dostawa towarów (WDT) — 0% VAT
- **Przesłanki:** Sprzedaż do UE, nabywca ma aktywny VAT-UE
- **Rezultat:** `vat_rate: "0.00"`, `procedure: "WDT"`, `gtu_code: ""`
- **Podstawa prawna:** Art. 42 ustawy o VAT
- **Priorytet:** 42

#### P45: `import_non_eu`
- **Cel biznesowy:** Import towarów spoza UE
- **Przesłanki:** `input.vendor.country` == `"NON_EU"`
- **Rezultat:** `vat_rate: "0.23"`, `procedure: "IMPORT"`, `gtu_code: "GTU_13"`
- **Podstawa prawna:** Art. 17 ust. 1 pkt 1 ustawy o VAT
- **Priorytet:** 45

#### P48: `export_goods`
- **Cel biznesowy:** Eksport towarów poza UE — 0% VAT
- **Przesłanki:** Sprzedaż do NON_EU, potwierdzenie wywozu
- **Rezultat:** `vat_rate: "0.00"`, `procedure: "EXPORT"`, `gtu_code: ""`
- **Podstawa prawna:** Art. 41 ust. 4-11 ustawy o VAT
- **Priorytet:** 48

---

### 4.5 Pakiet `tax.vat.substantive` — Reguły merytoryczne VAT (P50-P69)

#### P50: `vat_margin_scheme`
- **Cel biznesowy:** Procedura VAT-marża dla towarów używanych
- **Przesłanki:** `input.invoice.procedure` == `"MARGIN"` lub kategoria = dzieła sztuki/antyki
- **Rezultat:** `vat_rate: "0.23"` (od marży), `procedure: "MARGIN"`
- **Podstawa prawna:** Art. 120 ustawy o VAT
- **Priorytet:** 50

#### P52: `vat_rate_fuel_pl`
- **Cel biznesowy:** Paliwo w PL → 23% VAT + GTU_04
- **Przesłanki:** `input.invoice.category_code` == `"FUEL"` AND `input.vendor.country` == `"PL"`
- **Rezultat:** `vat_rate: "0.23"`, `gtu_code: "GTU_04"`, `rounding_level: "position"`
- **Podstawa prawna:** Art. 41 ust. 1 ustawy o VAT, § 10 rozp. w sprawie JPK_VAT
- **Priorytet:** 52

#### P53: `vat_rate_food_pl`
- **Cel biznesowy:** Żywność w PL → 8% VAT (lub 5% dla wybranych)
- **Przesłanki:** `input.invoice.category_code` == `"FOOD"` AND `input.vendor.country` == `"PL"`
- **Rezultat:** `vat_rate: "0.08"`, `gtu_code: "GTU_07"`
- **Podstawa prawna:** Art. 41 ust. 2 ustawy o VAT, rozp. MF w sprawie obniżonych stawek
- **Priorytet:** 53

#### P54: `vat_rate_books_pl`
- **Cel biznesowy:** Książki → 5% VAT
- **Przesłanki:** `input.invoice.category_code` == `"BOOKS"` AND `input.vendor.country` == `"PL"`
- **Rezultat:** `vat_rate: "0.05"`, `gtu_code: "GTU_01"`
- **Podstawa prawna:** Art. 41 ust. 2a ustawy o VAT
- **Priorytet:** 54

#### P55: `vat_exemption_education`
- **Cel biznesowy:** Edukacja → zwolniona z VAT
- **Przesłanki:** `lower(input.invoice.category_code)` == `"education"` AND `input.vendor.country` == `"PL"`
- **Rezultat:** `vat_rate: "0.00"`, `rounding_level: "total"`
- **Podstawa prawna:** Art. 43 ust. 1 pkt 26-29 ustawy o VAT
- **Priorytet:** 55

#### P56: `vat_exemption_healthcare`
- **Cel biznesowy:** Opieka medyczna → zwolniona z VAT
- **Przesłanki:** `lower(input.invoice.category_code)` == `"healthcare"` AND `input.vendor.country` == `"PL"`
- **Rezultat:** `vat_rate: "0.00"`, `rounding_level: "total"`
- **Podstawa prawna:** Art. 43 ust. 1 pkt 18-20 ustawy o VAT
- **Priorytet:** 56

#### P57: `vat_exemption_finance`
- **Cel biznesowy:** Usługi finansowe/ubezpieczeniowe → zwolnione
- **Przesłanki:** Kategoria = finanse/ubezpieczenia
- **Rezultat:** `vat_rate: "0.00"`, `rounding_level: "total"`
- **Podstawa prawna:** Art. 43 ust. 1 pkt 7, 37-41 ustawy o VAT
- **Priorytet:** 57

#### P58: `vat_23_exemption_subject`
- **Cel biznesowy:** Zwolnienie podmiotowe VAT (limit 200 000 PLN)
- **Przesłanki:** `input.company.annual_turnover_net < input.thresholds.vat_exemption_limit` AND `input.company.is_vat_payer == false`
- **Rezultat:** `vat_rate: "0.00"`, `vat_exemption: "SUBJECT"`
- **Podstawa prawna:** Art. 113 ust. 1 ustawy o VAT
- **Priorytet:** 58

#### P60: `vat_bad_debt_relief`
- **Cel biznesowy:** Ulga na złe długi — korekta VAT po 150 dniach
- **Przesłanki:** Faktura nieopłacona > `input.thresholds.bad_debt_days` dni
- **Rezultat:** `bad_debt_relief_eligible: true`
- **Podstawa prawna:** Art. 89a ustawy o VAT
- **Priorytet:** 60

#### P61: `vat_prepayment_rule`
- **Cel biznesowy:** Obowiązek podatkowy przy zaliczce
- **Przesłanki:** `input.invoice.procedure` == `"PREPAYMENT"`
- **Rezultat:** `tax_point: "prepayment"`
- **Podstawa prawna:** Art. 19a ust. 8 ustawy o VAT
- **Priorytet:** 61

---

### 4.6 Pakiet `tax.vat.gtu` — Kody GTU (P65-P69)

#### P65: `gtu_mapping_by_category`
- **Cel biznesowy:** Automatyczne przypisanie kodu GTU na podstawie kategorii
- **Mapowanie kategorii → GTU:**

| Kategoria | GTU | Opis |
|---|---|---|
| FUEL | GTU_04 | Paliwa, oleje |
| IT_OFFICE | GTU_01 | Sprzęt elektroniczny |
| FOOD | GTU_07 | Żywność |
| CONSTRUCTION | GTU_08 | Roboty budowlane |
| TRANSPORT | GTU_06 | Usługi transportowe |
| SCRAP | GTU_05 | Złom, odpady |
| ALCOHOL | GTU_02 | Alkohol |
| TOBACCO | GTU_03 | Wyroby tytoniowe |
| PHARMA | GTU_09 | Leki, wyroby medyczne |
| REAL_ESTATE | GTU_10 | Nieruchomości |
| GAS_ENERGY | GTU_11 | Gaz, energia |
| EU_SERVICES | GTU_12 | Usługi wewnątrzwspólnotowe |
| NON_EU_GOODS | GTU_13 | Import spoza UE |

- **Podstawa prawna:** § 10 rozporządzenia w sprawie JPK_VAT
- **Priorytet:** 65

---

### 4.7 Pakiet `tax.direct.cit` — CIT (P70-P74)

#### P70: `cit_estonian_effective`
- **Cel biznesowy:** Estoński CIT — efektywna stawka 20% od wypłaconego zysku
- **Przesłanki:** `input.company.tax_form` == `"CIT_ESTONIAN"`
- **Rezultat:** `cit_rate: input.thresholds.rates.cit_estonian_effective`, `tax_deferral: true`
- **Podstawa prawna:** Rozdział 6b ustawy o CIT (art. 28c-28t)
- **Priorytet:** 70

#### P71: `cit_small_taxpayer`
- **Cel biznesowy:** Mały podatnik CIT — 9%
- **Przesłanki:** `input.company.tax_form` == `"CIT_STANDARD"` AND `input.company.is_small_taxpayer == true`
- **Rezultat:** `cit_rate: input.thresholds.rates.cit_small`
- **Podstawa prawna:** Art. 19 ust. 1a ustawy o CIT
- **Priorytet:** 71

#### P72: `cit_thin_capitalization`
- **Cel biznesowy:** Cienka kapitalizacja — wyłączenie z KUP nadmiernych odsetek
- **Przesłanki:** `input.vendor.is_related_party == true` AND zadłużenie/kapitał > `input.thresholds.thin_cap_ratio`
- **Rezultat:** `income_tax_qualification: "non_deductible"`, `_warning: "Przekroczony limit cienkiej kapitalizacji"`
- **Podstawa prawna:** Art. 15c ustawy o CIT
- **Priorytet:** 72

#### P74: `cit_loss_carry_forward`
- **Cel biznesowy:** Rozliczenie straty z lat ubiegłych
- **Przesłanki:** Firma ma stratę do rozliczenia
- **Rezultat:** `loss_carry_forward_limit_percent: 50`, `max_years: 5`
- **Podstawa prawna:** Art. 7 ust. 5 ustawy o CIT
- **Priorytet:** 74

---

### 4.8 Pakiet `tax.direct.pit` — PIT (P74-P79)

#### P74: `pit_lump_sum_rate`
- **Cel biznesowy:** Stawka ryczałtu wg PKWiU (2%-17%)
- **Przesłanki:** `input.company.tax_form` == `"LUMP_SUM"`
- **Rezultat:** Stawka zależna od `input.invoice.pkwiu_code`
- **Podstawa prawna:** Art. 12 ustawy o ryczałcie ewidencjonowanym
- **Priorytet:** 74

#### P75: `pit_tax_scale`
- **Cel biznesowy:** Skala podatkowa 12%/32%
- **Przesłanki:** `input.company.tax_form` == `"LINEAR"`? Nie — to `"PIT_SCALE"`
- **Rezultat:** `pit_bracket: "low"` (12%) lub `"high"` (32%)
- **Podstawa prawna:** Art. 27 ust. 1 ustawy o PIT
- **Priorytet:** 75

#### P76: `pit_joint_filing`
- **Cel biznesowy:** Wspólne rozliczenie małżonków (podwaja próg)
- **Przesłanki:** `input.company.tax_form` == `"PIT_SCALE"` AND `joint_filing == true`
- **Rezultat:** Efektywny próg = `input.thresholds.bounds.pit_scale_threshold * 2`
- **Podstawa prawna:** Art. 6 ust. 2 ustawy o PIT
- **Priorytet:** 76

#### P77: `pit_young_exemption`
- **Cel biznesowy:** Ulga dla młodych (do 26 r.ż.)
- **Przesłanki:** `input.company.tax_form` == `"PIT_SCALE"` AND `taxpayer_age <= 26` AND `income <= input.thresholds.bounds.pit_young_exemption_limit`
- **Rezultat:** `pit_rate: "0.00"`, `exemption: "YOUNG"`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 148 ustawy o PIT
- **Priorytet:** 77

#### P78: `pit_return_exemption`
- **Cel biznesowy:** Ulga na powrót (4 lata zwolnienia po emigracji)
- **Przesłanki:** Powrót z emigracji, `income <= input.thresholds.bounds.pit_return_exemption_limit`
- **Rezultat:** `pit_rate: "0.00"`, `exemption: "RETURN"`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 152 ustawy o PIT
- **Priorytet:** 78

#### P79: `pit_family_4plus`
- **Cel biznesowy:** Ulga dla rodzin 4+ dzieci
- **Przesłanki:** 4+ dzieci, `income <= input.thresholds.bounds.pit_family_4plus_limit`
- **Rezultat:** `pit_rate: "0.00"`, `exemption: "FAMILY_4PLUS"`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 153 ustawy o PIT
- **Priorytet:** 79

---

### 4.9 Pakiet `tax.allowances` — Ulgi podatkowe (P80-P89)

#### P80: `relief_rd`
- **Cel biznesowy:** Ulga B+R — 100% (lub 200% dla centrum badawczego)
- **Przesłanki:** `input.company.has_rd_status == true` AND koszty kwalifikowane B+R
- **Rezultat:** `relief_percent: input.thresholds.bounds.relief_rd_base` (lub `relief_rd_centrum`)
- **Podstawa prawna:** Art. 26e PIT / art. 18d CIT
- **Priorytet:** 80

#### P81: `relief_prototype`
- **Cel biznesowy:** Ulga na prototyp — 30% kosztów
- **Przesłanki:** Koszty produkcji próbnej
- **Rezultat:** `relief_percent: input.thresholds.bounds.relief_prototype_percent`
- **Podstawa prawna:** Art. 26eb PIT / art. 18db CIT
- **Priorytet:** 81

#### P82: `relief_ip_box`
- **Cel biznesowy:** IP Box — 5% od dochodów z własności intelektualnej
- **Przesłanki:** Dochód z kwalifikowanego IP
- **Rezultat:** `pit_rate: input.thresholds.rates.pit_ip_box`
- **Podstawa prawna:** Art. 30ca PIT / art. 24d CIT
- **Priorytet:** 82

#### P83: `relief_robotization`
- **Cel biznesowy:** Ulga na robotyzację — 50% kosztów
- **Przesłanki:** Zakup robotów przemysłowych
- **Rezultat:** `relief_percent: input.thresholds.bounds.relief_robotization_percent`
- **Podstawa prawna:** Art. 26gb PIT / art. 38eb CIT
- **Priorytet:** 83

#### P84: `relief_expansion`
- **Cel biznesowy:** Ulga na ekspansję — koszty targów, reklamy zagranicznej
- **Przesłanki:** Koszty ekspansji zagranicznej
- **Rezultat:** `relief_type: "EXPANSION"`
- **Podstawa prawna:** Art. 26ec PIT / art. 18dc CIT
- **Priorytet:** 84

#### P85: `relief_thermomodernization`
- **Cel biznesowy:** Ulga termomodernizacyjna — max 53 000 PLN
- **Przesłanki:** Wydatki na termomodernizację
- **Rezultat:** `relief_max: input.thresholds.bounds.relief_thermo_max`
- **Podstawa prawna:** Art. 26h ustawy o PIT
- **Priorytet:** 85

#### P86: `relief_internet`
- **Cel biznesowy:** Ulga na internet — 760 PLN rocznie przez 2 lata
- **Przesłanki:** `internet_years_used < input.thresholds.bounds.relief_internet_years`
- **Rezultat:** `relief_max: input.thresholds.bounds.relief_internet_max`
- **Podstawa prawna:** Art. 26 ustawy o PIT
- **Priorytet:** 86

#### P87: `relief_rehabilitation`
- **Cel biznesowy:** Ulga rehabilitacyjna
- **Przesłanki:** Wydatki na cele rehabilitacyjne
- **Rezultat:** `relief_type: "REHABILITATION"`
- **Podstawa prawna:** Art. 26 ustawy o PIT
- **Priorytet:** 87

---

### 4.10 Pakiet `tax.accounting` — Reguły Rachunkowe (P90-P94)

#### P90: `acc_depreciation_linear`
- **Cel biznesowy:** Amortyzacja liniowa środków trwałych
- **Przesłanki:** `input.invoice.expense_type` == `"FIXED_ASSET"` AND metoda = liniowa
- **Rezultat:** `depreciation_method: "LINEAR"`, `rate` z KŚT
- **Podstawa prawna:** Art. 32 ust. 1 UoR, KŚT
- **Priorytet:** 90

#### P91: `acc_depreciation_degressive`
- **Cel biznesowy:** Amortyzacja degresywna
- **Przesłanki:** Metoda degresywna, środek trwały z grup 3-6 KŚT
- **Rezultat:** `depreciation_method: "DEGRESSIVE"`, współczynnik 2.0
- **Podstawa prawna:** Art. 32 ust. 2 UoR
- **Priorytet:** 91

#### P92: `acc_rmk_deferral`
- **Cel biznesowy:** RMK — rozliczenia międzyokresowe kosztów
- **Przesłanki:** Koszt dotyczy przyszłych okresów
- **Rezultat:** `rmk_required: true`, `rmk_period_type: "MONTHLY"`
- **Podstawa prawna:** Art. 39 UoR
- **Priorytet:** 92

#### P93: `acc_fx_revaluation`
- **Cel biznesowy:** Rewaluacja walutowa na dzień bilansowy
- **Przesłanki:** `input.invoice.currency` != `"PLN"` AND data bilansowa
- **Rezultat:** `fx_revaluation_required: true`
- **Podstawa prawna:** Art. 30 UoR, IAS 21
- **Priorytet:** 93

#### P94: `acc_fifo_inventory`
- **Cel biznesowy:** Wycena zapasów FIFO
- **Przesłanki:** Faktura zakupu towarów
- **Rezultat:** `inventory_method: "FIFO"`
- **Podstawa prawna:** Art. 28 ust. 1 UoR, IAS 2
- **Priorytet:** 94

---

### 4.11 Pakiet `tax.zus` — Składki ZUS (P95-P99)

#### P95: `zus_maly_plus`
- **Cel biznesowy:** Mały ZUS Plus — obniżona podstawa przez 36 miesięcy
- **Przesłanki:** `input.company.zus_status` == `"MALY_ZUS_PLUS"` AND `months_used < input.thresholds.bounds.zus_maly_plus_months`
- **Rezultat:** `zus_base_percent: input.thresholds.bounds.zus_maly_plus_min_wage_percent`
- **Podstawa prawna:** Art. 18c ustawy o SUS
- **Priorytet:** 95

#### P96: `zus_start_relief`
- **Cel biznesowy:** Ulga na start — 6 miesięcy bez składek społecznych
- **Przesłanki:** `input.company.zus_status` == `"START_RELIEF"` AND `months_used < input.thresholds.bounds.zus_start_months`
- **Rezultat:** `zus_social: "0.00"`, `zus_health_only: true`
- **Podstawa prawna:** Art. 18a ustawy o SUS
- **Priorytet:** 96

#### P97: `zus_preferential`
- **Cel biznesowy:** Preferencyjny ZUS (30% minimalnego wynagrodzenia)
- **Przesłanki:** `input.company.zus_status` == `"PREFERENTIAL"` AND `months_used < 24`
- **Rezultat:** `zus_base_percent: 0.30`
- **Podstawa prawna:** Art. 18a ustawy o SUS
- **Priorytet:** 97

#### P98: `zus_health_contrib`
- **Cel biznesowy:** Składka zdrowotna — 9% (skala) lub 4.9% (liniowy/ryczałt)
- **Przesłanki:** Forma opodatkowania
- **Rezultat:** `zus_health_rate` zależna od `input.company.tax_form`
- **Podstawa prawna:** Art. 79-81 ustawy zdrowotnej
- **Priorytet:** 98

---

### 4.12 Pakiet `tax.fallback` — Reguły domyślne (P100+)

#### P100: `domestic_fallback`
- **Cel biznesowy:** Domyślna stawka VAT 23% dla Polski
- **Przesłanki:** `input.vendor.country` == `"PL"` AND żadna konkretna reguła nie pasuje
- **Rezultat:** `vat_rate: input.thresholds.rates.vat_standard`, `rounding_level: "position"`
- **Podstawa prawna:** Art. 41 ust. 1 ustawy o VAT
- **Priorytet:** 100

#### P200: `no_match`
- **Cel biznesowy:** Ostateczny fallback — brak dopasowania
- **Przesłanki:** Żadna reguła nie pasuje
- **Rezultat:** `matched: false`, `error: "NO_MATCHING_RULE"`
- **Priorytet:** 200 (always last via `default decide`)

---

### 4.13 Pakiet `tax.uor_books` — UoR Księgi (P320, P321, P326)

#### P320: `uor_double_entry_validation`
- **Cel biznesowy:** Walidacja integralności księgowej — Wn musi równać się Ma
- **Przesłanki:** `input.document.type` == `"journal_entry"` AND `abs(sum(debet) - sum(kredyt)) > 0.01`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, zablokowanie niezbilansowanego zapisu
- **Podstawa prawna:** Art. 22 ust. 1 UoR
- **Priorytet:** 320

#### P321: `uor_closing_books_mandatory`
- **Cel biznesowy:** Blokada księgowania w zamkniętym roku obrotowym
- **Przesłanki:** `input.invoice.issue_date <= input.company.closed_financial_year_end` AND `input.company.is_fs_approved == true`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, należy użyć korekty błędu podstawowego
- **Podstawa prawna:** Art. 12 ust. 2 pkt 1 UoR
- **Priorytet:** 321

#### P326: `uor_evidence_mandatory_fields`
- **Cel biznesowy:** Walidacja obowiązkowych elementów dowodu księgowego
- **Przesłanki:** Brak określenia stron (`parties_identified == false`) lub brak opisu operacji (`has_operation_description == false`)
- **Rezultat:** `_routing: "TRIAGE_QUEUE"`, `evidence_status: "INVALID"`
- **Podstawa prawna:** Art. 21 ust. 1 UoR
- **Priorytet:** 326

---

### 4.14 Pakiet `tax.uor_valuation` — UoR Wycena (P322, P330)

#### P322: `uor_provisions_recognition`
- **Cel biznesowy:** Rezerwy wg polskiego GAAP (firmy niestosujące MSSF)
- **Przesłanki:** `input.company.uses_ifrs == false` AND `input.document.has_certain_or_probable_loss == true`
- **Rezultat:** `provision_required: true`, `provision_type: "UOR_ART_31"`, `income_tax_qualification: "deductible_partial"`
- **Podstawa prawna:** Art. 31 ust. 1 UoR
- **Priorytet:** 322

#### P330: `uor_valuation_manufacturing_cost`
- **Cel biznesowy:** Wycena wg kosztu wytworzenia (produkcja własna)
- **Przesłanki:** `input.asset.produced_internally == true` AND `input.asset.purchase_cost == 0`
- **Rezultat:** `valuation_base: "manufacturing_cost"`
- **Podstawa prawna:** Art. 28 ust. 1-3 UoR
- **Priorytet:** 330

---

### 4.15 Pakiet `tax.uor_reports` — UoR Sprawozdania (P327)

#### P327: `uor_financial_statement_structure`
- **Cel biznesowy:** Automatyczna klasyfikacja aktywów do bilansu (trwałe vs obrotowe)
- **Przesłanki:** `input.asset.expected_usage_months > 12` AND `input.asset.is_held_for_trading == false` → non_current; wpp → current
- **Rezultat:** `bs_category: "non_current_assets"` lub `"current_assets"`
- **Podstawa prawna:** Art. 35-44 UoR + Załącznik nr 1
- **Priorytet:** 327

---

### 4.16 Pakiet `tax.cit_deductions` — CIT Odliczenia (P323)

#### P323: `cit_bad_debt_relief_creditor`
- **Cel biznesowy:** Ulga CIT na złe długi — pomniejszenie podstawy opodatkowania przez wierzyciela
- **Przesłanki:** `input.invoice.days_overdue > 90` AND `input.invoice.is_paid == false` AND `input.invoice.was_recognized_as_revenue == true` AND `input.company.tax_form` in `["CIT_STANDARD", "CIT_ESTONIAN"]`
- **Rezultat:** `cit_deduction_eligible: true`, `cit_deduction_amount: input.invoice.amount_net`
- **Podstawa prawna:** Art. 18f CIT
- **Priorytet:** 323

---

### 4.17 Pakiet `tax.vat_registration` — VAT Rejestracja (P324)

#### P324: `vat_registration_vat_r_mandatory`
- **Cel biznesowy:** Blokada faktury dla podmiotu niezarejestrowanego jako czynny podatnik VAT
- **Przesłanki:** `input.company.vat_status == "unregistered"` AND `input.invoice.vat_taxable == true`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, wymagany VAT-R
- **Podstawa prawna:** Art. 15, Art. 96 VAT
- **Priorytet:** 324

---

### 4.18 Pakiet `tax.ordynacja_extended` — Ordynacja (P325, P329)

#### P325: `ord_tax_securing_deadline`
- **Cel biznesowy:** Obsługa decyzji US o zabezpieczeniu — natychmiastowy depozyt
- **Przesłanki:** `input.document.type == "us_securing_decision"` AND `input.document.is_appealed_without_stay == true`
- **Rezultat:** `tax_securing_required: true`, `requires_immediate_deposit: true`
- **Podstawa prawna:** Art. 33, Art. 36 Ordynacji podatkowej
- **Priorytet:** 325

#### P329: `ord_payment_relief_deferral`
- **Cel biznesowy:** Opłata prolongacyjna zamiast odsetek za zwłokę przy odroczeniu/ratach
- **Przesłanki:** `input.company.has_active_deferral_decision == true` AND `input.document.type == "tax_payment"`
- **Rezultat:** `apply_prolongation_fee: true`, `prolongation_rate` z thresholds
- **Podstawa prawna:** Art. 54, Art. 67a-69 Ordynacji podatkowej
- **Priorytet:** 329

---

### 4.19 Pakiet `tax.labor_extended` — Prawo Pracy (P328)

#### P328: `labor_ohs_medical_exams_kup`
- **Cel biznesowy:** Badania BHP i medycyna pracy → 100% KUP jako koszt obowiązkowy
- **Przesłanki:** `input.invoice.category_code == "MEDICAL_EXAMS_OHS"` AND `input.invoice.beneficiary_type == "employee"`
- **Rezultat:** `income_tax_qualification: "deductible_full"`
- **Podstawa prawna:** Art. 229 KP w zw. z Art. 15 CIT
- **Priorytet:** 328

---

### 4.20 Pakiet `tax.pit_withholding` — PIT Pobór (P331)

#### P331: `pit_small_mandate_flat_rate`
- **Cel biznesowy:** Małe umowy zlecenia/dzieło ≤200 PLN — ryczałt 12%, bez KUP wykonawcy
- **Przesłanki:** `input.document.type == "contract_of_mandate"` AND `input.invoice.amount_gross <= 200` AND `input.invoice.contractor_is_employee == false`
- **Rezultat:** `pit_rate: "0.12"`, `pit_withholding_type: "LUMP_SUM"`, `apply_contractor_kup: false`
- **Podstawa prawna:** Art. 30 ust. 1 pkt 5a PIT
- **Priorytet:** 331

---

## 5. Zależności Między Regułami

### 5.1 Łańcuch przyczynowo-skutkowy

```
FraudGraphScanner ──► fraud_graph_match (P0)
                          │
OCR Consensus ────────► fc_* rules (P10-P19)
                          │
WhiteListService ─────► whitelist_* (P20-P21)
                          │
KSeF/JPK ─────────────► retention_* (P30)
                          │
Vendor Country ───────► crossborder_* (P40-P48)
                          │
Category Code ────────► vat_gtu_* (P52-P69)
                          │
Company Tax Form ─────► cit_*/pit_* (P70-P79)
                          │
Expense Type ─────────► allowances_* (P80-P89)
                          │
Asset Type ───────────► acc_* (P90-P94)
                          │
ZUS Status ───────────► zus_* (P95-P99)
                          │
                       domestic_fallback (P100)
                          │
                       no_match (P200)
```

### 5.2 Interakcje między pakietami

| Pakiet źródłowy | Wpływa na | Mechanizm |
|---|---|---|
| `tax.risk` | Blokuje wszystkie następne | `_routing: "BLOCK_AND_ALERT"` |
| `tax.routing` | Kieruje do triage lub blokuje | `_routing` |
| `tax.compliance` | Dodaje ostrzeżenia, flagi MPP | `_warnings[]`, `mpp_required` |
| `tax.crossborder` | Ustawia procedurę specjalną | `procedure` |
| `tax.vat.*` | Określa stawkę i GTU | `vat_rate`, `gtu_code` |
| `tax.direct.*` | Określa kwalifikację KUP | `income_tax_qualification` |
| `tax.allowances` | Dodaje ulgi i preferencje | `relief_*` |
| `tax.accounting` | Określa metodę księgową | `depreciation_method`, `inventory_method` |
| `tax.zus` | Określa stawki składek | `zus_*` |
| `tax.fallback` | Zawsze na końcu | Domyślna stawka |

---

## 6. Plan Implementacji

### 6.1 Fazy wdrożenia

| Faza | Zakres | Pliki Rego | Testy |
|---|---|---|---|
| **Faza 0** (istnieje) | Field confidence + podstawowe VAT | `tax/rules.rego` | `tests/rego/tax_rules_test.rego` |
| **Faza 1** | Compliance: Biała Lista, MPP, KSeF | `compliance.rego` | `compliance_test.rego` |
| **Faza 2** | Cross-border: reverse charge, import, export | `crossborder.rego` | — |
| **Faza 3** | VAT substantive + GTU mapping | `vat/substantive.rego`, `vat/gtu.rego` | `vat_test.rego` |
| **Faza 4** | Direct taxes: CIT + PIT | `direct/cit.rego`, `direct/pit.rego` | `cit_test.rego`, `pit_test.rego` |
| **Faza 5** | Allowances: ulgi podatkowe | `allowances.rego` | — |
| **Faza 6** | Accounting: amortyzacja, FIFO, FX | `accounting.rego` | — |
| **Faza 7** | ZUS: składki i ulgi składkowe | `zus.rego` | — |
| **Faza 8** | Risk: fraud graph, anomalie | `risk.rego` | — |
| **Faza 9** | PPK, Akcyza, IFRS, Leasing, AML, KŚT, JPK, Darowizny | `ppk.rego`, `excise.rego`, `ifrs.rego`, `leasing.rego`, `aml.rego`, `kst.rego`, `jpk.rego`, `donations.rego` | — |
| **Faza 10** | VAT odliczenia/korekty, Praca, BDO, NGO, UoR zasady, PKPiR | `vat/deductions.rego`, `labor.rego`, `environmental.rego`, `ngo.rego`, `uor.rego`, `pkpir.rego` | — |
| **Faza 11** | VAT obowiązek podatkowy/podstawa, CIT/PIT zaliczki i przychody, Ordynacja terminy/odpowiedzialność, UoR księgi/sprawozdania, Spółdzielnie, Energetyka, Transport, KSeF/JPK szczegóły, Podatki lokalne | `vat/tax_point.rego`, `vat/tax_base.rego`, `direct/advances.rego`, `direct/revenue.rego`, `uor/books.rego`, `uor/reports.rego`, `special/coop.rego`, `special/energy.rego`, `special/transport.rego`, `ksef/advanced.rego`, `jpk/advanced.rego`, `local/tax.rego` | — |
| **Faza 12** | CIT/PIT KUP wyłączenia szczegółowe, PCC, SD, prawo dewizowe, akcyza tytoń/składy, KP nagrody/delegacje, MSSF 2, UoR zmiany zasad/błędy | `direct/cit/kup.rego`, `direct/pit/kup.rego`, `vat/deductions.rego`, `compliance/pcc.rego`, `compliance/sd.rego`, `compliance/fx.rego`, `compliance/excise.rego`, `labor.rego`, `accounting/ifrs2.rego`, `accounting/uor_changes.rego` | — |

### 6.2 Konwencja nazewnicza reguł

```
<domena>.<podatkowa>.<kategoria>_<szczegół>

Przykłady:
  vat.substantive.fuel_pl_23
  vat.gtu.mapping_fuel
  cit.estonian.effective_rate
  pit.lump_sum.rate_by_pkwiu
  compliance.whitelist.missing_over_limit
  zus.maly_plus.base_reduction
  allowances.rd.standard_100
```

### 6.3 Konwencja komentarzy w Rego

Każda reguła MUSI zawierać:

```rego
# ── Nazwa reguły ──────────────────────────
# Cel biznesowy: ...
# Przesłanki: ...
# Podstawa prawna: Art. X ustawy Y (Dz.U. ZZZZ poz. XXX)
# Priorytet: N (zakres)
# Zależności: ...
```

---

## 7. Testowanie Reguł

### 7.1 Testy OPA (Rego test)

```rego
package tax.vat.substantive.test

import data.tax.vat.substantive

# Pozytywny: paliwo w PL → 23% VAT + GTU_04
test_fuel_pl_23_vat {
    result := substantive.decide with input as {
        "invoice": {
            "category_code": "FUEL",
            "transaction_date": "2026-06-01"
        },
        "vendor": {"country": "PL"},
        "thresholds": {"rates": {"vat_standard": "0.23"}}
    }
    result.vat_rate == "0.23"
    result.gtu_code == "GTU_04"
}

# Negatywny: paliwo w EU z aktywnym VAT → reverse charge NIE 23%
test_fuel_eu_reverse_charge_not_23 {
    result := substantive.decide with input as {
        "invoice": {
            "category_code": "FUEL",
            "transaction_date": "2026-06-01"
        },
        "vendor": {"country": "EU", "vat_status": "active"},
        "thresholds": {"rates": {"vat_standard": "0.23"}}
    }
    # Cross-border reguła powinna przejąć, więc substantive NIE zwraca 0.23
    not result.vat_rate
}
```

### 7.2 Testy integracyjne (Python)

```python
# tests/test_opa_rules_comprehensive.py
async def test_full_pipeline_fuel_pl():
    """Pełny pipeline: input → OPA → werdykt dla paliwa w PL."""
    opa = OpaClient()
    await opa.load_policy("tax/full.rego", FULL_POLICY)
    
    verdict = await opa.evaluate("tax/decide", {
        "invoice": {"category_code": "FUEL", ...},
        "vendor": {"country": "PL", ...},
        ...
    })
    
    assert verdict["vat_rate"] == "0.23"
    assert verdict["gtu_code"] == "GTU_04"
    assert verdict["_routing"] == ""  # brak routingu = OK
```

---

## 8. Utrzymanie i Aktualizacja

### 8.1 Proces aktualizacji thresholdów

1. Zmiana przepisów (np. nowa stawka VAT) → aktualizacja DuckDB `tax_thresholds`
2. NATS publikuje `tax.thresholds.updated`
3. `HotReloadListener` odświeża cache OPA
4. Następna ewaluacja używa nowych wartości
5. **Zero zmian w kodzie Rego**

### 8.2 Proces dodawania nowej reguły

1. Zidentyfikuj podstawę prawną (artykuł, ustawa, Dz.U.)
2. Określ priorytet (gdzie w łańcuchu first-match-wins?)
3. Zdefiniuj warunki (przez `input.*` i `input.thresholds.*`)
4. Dodaj regułę do odpowiedniego pliku `.rego`
5. Dodaj testy Rego (pozytywne + negatywne)
6. Dodaj testy integracyjne Python
7. Zaktualizuj dokumentację (`Plan OPA/`)

---

> **Następny dokument:** `Plan OPA/01_INPUT_SPEC.md` — Pełna specyfikacja struktury `input`  
> **Następny dokument:** `Plan OPA/02_THRESHOLDS_CATALOG.md` — Kompletny katalog thresholdów  
> **Następny dokument:** `Plan OPA/03_RULES_DETAILED.md` — Szczegółowy opis reguł (część bazowa)  
> **Następny dokument:** `Plan OPA/05_ARCHITECTURE_DECISION.md` — ADR-001: Multi-Pass Evaluation  
> **Następny dokument:** `Plan OPA/06_COMPLETE_RULES_SUPPLEMENT.md` — Kompendium CIT, PIT, ulgi, księgowość, ZUS  
> **Następny dokument:** `Plan OPA/07_ADVANCED_RULES_EXPANSION.md` — Rozszerzenie: PPK, Akcyza, IFRS, AML, KŚT, JPK (33 reguły)  
> **Następny dokument:** `Plan OPA/08_OPA_PATTERNS_FROM_RESEARCH.md` — Wzorce z FINOS, OpenFisca, OPA Library  
> **Następny dokument:** `Plan OPA/09_LEGAL_DEEP_DIVE_RULES.md` — Deep Dive: VAT odliczenia, Praca, BDO, NGO, UoR (27 reguł)  
> **Następny dokument:** `Plan OPA/10_OPA_IMPLEMENTATION_GUIDE.md` — Praktyczny przewodnik implementacji ENTERPRISE  
> **Następny dokument:** `Plan OPA/11_ENTERPRISE_FINAL_EXPANSION.md` — Finalna ekspansja: 36 reguł z 18 obszarów (191 reguł łącznie)  
> **Następny dokument:** `Plan OPA/12_DATA_INTEGRATION_PATTERNS.md` — Wzorce integracji danych OPA dla NexusAI  
> **Następny dokument:** `Plan OPA/13_KUBESCAPE_PATTERNS_DEEP_DIVE.md` — Deep dive kubescape: Rule→Control→Framework, testy, CI  
> **Następny dokument:** `Plan OPA/14_SPECIALIZED_TAX_RULES.md` — Specjalistyczne: CIT/PIT KUP, PCC, SD, dewizy, akcyza, KP, MSSF2, UoR (212 reguł łącznie)  
> **Następny dokument:** `Plan OPA/15_SERVICE_INTEGRATION_MAP.md` — Mapa 12 serwisów NexusAI → reguły OPA  
> **Następny dokument:** `Plan OPA/16_FINAL_FRONTIER_RULES.md` — Ostatnia granica: 16 reguł + styrainc/finos research (228 reguł)  
> **Następny dokument:** `Plan OPA/17_IMPLEMENTATION_ROADMAP.md` — Roadmap wdrożenia: 13 faz, M1-M4, macierz ryzyka  
> **Następny dokument:** `Plan OPA/18_OPA_API_REFERENCE.md` — Dokumentacja API OPA REST dla NexusAI  
> **Następny dokument:** `Plan OPA/19_DEPLOYMENT_GUIDE.md` — Przewodnik wdrożenia: Docker, K8s, CI/CD, monitoring  
> **Następny dokument:** `Plan OPA/20_MASTER_RULES_REFERENCE.md` — Kompletny spis 228 reguł z pseudokodem i cross-reference
