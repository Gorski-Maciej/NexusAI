# 🏛️ Plan Reguł OPA/Rego dla NexusAI — Silnik Decyzyjny JDG ENTERPRISE

> **Status:** Plan Architektoniczny JDG v1.2 — zaktualizowany o wyniki głębokiego audytu prawnego  
> **Data:** 2026-07-08  
> **Autor:** Zespół NexusAI  
> **Zakres:** Wyłącznie jednoosobowa działalność gospodarcza (JDG)  
> **Źródła prawne:** `Plan OPA/DocsJDG` — kompletny wykaz ustaw i rozporządzeń dla JDG (v2.0 — +KKS, +PCC, +podatki lokalne)  
> **Inspiracje:** `Plan OPA/Docs/` — istniejące wzorce reguł i dokumenty analityczne  
> **Plik wynikowy:** `Plan OPA/22_JDG_ENTERPRISE_PLAN.md`  
> **Rozbudowa:** `Plan OPA/23_JDG_EXPANSION_SUPPLEMENT.md` — 69 dodatkowych reguł w 10 obszarach  
> **Indeks kompletny:** `Plan OPA/24_JDG_COMPLETE_INDEX.md` — spis wszystkich ~214 reguł + 46 proponowanych  
> **Audyt prawny:** `Plan OPA/25_JDG_DEEP_LEGAL_AUDIT.md` — 46 luk (12 krytycznych, 20 ważnych, 14 dodatkowych)  

---

## 0. Filozofia Projektowa — JDG Edition

### 0.1 Fundamenty architektoniczne

System reguł NexusAI dla JDG opiera się na pięciu nienaruszalnych zasadach — rozszerzonych względem planu ogólnego o specyfikę jednoosobowej działalności:

| Zasada | Opis | Implementacja JDG |
|--------|------|-------------------|
| **First-Match-Wins** | Pierwsza pasująca reguła wygrywa — deterministyczna kolejność | Rego `else` chain w `main_jdg.rego` |
| **Zero Hardcoded Values** | Żadna liczba (stawka, próg, limit) nie jest zakodowana w `.rego` | Wszystko przez `input.thresholds.jdg.*` |
| **Temporalność** | Reguły obowiązują od-do; parametry zależne od daty transakcji | `valid_from` / `valid_to` w warunkach |
| **Audytowalność** | Każda decyzja ma ślad: która reguła, dlaczego, na jakiej podstawie | `rule_id`, `_legal_basis` w werdykcie |
| **JDG-First Design** | Wszystkie reguły projektowane od podstaw pod JDG, nie jako fork CIT | Osobne pakiety `jdg.*`, dedykowany `input.jdg_entrepreneur` |

### 0.2 Model danych (przepływ JDG)

```
DuckDB RuleStore           OPA Policy (Rego)            Werdykt JDG
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────────┐
│ jdg_tax_rules    │──►    │ package jdg.xxx   │──►    │ {                    │
│  rule_id         │       │                   │       │   "matched":true,    │
│  condition_sql   │       │ default decide =  │       │   "rule_id":"...",   │
│  action_json     │       │   {...}           │       │   "vat_rate":"..",   │
│  priority        │       │                   │       │   "pit_rate":"..",   │
│  valid_from/to   │       │ decide = {...} {  │       │   "pit_form":"..",   │
└──────────────────┘       │   cond1           │       │   "zus_base":"..",   │
        │                  │ } else = {...} {  │       │   "kus_qual":"..",   │
        ▼                  │   cond2           │       │   "pkpir_column":"", │
┌──────────────────┐       │ } ...             │       │   "_routing":"..",   │
│ thresholds.jdg   │──►    └──────────────────┘       │   "_legal_basis":    │
│  rates           │                │                 │     "Art.27 PIT"     │
│  limits          │                ▼                 │ }                    │
│  bounds          │       ┌──────────────────┐       └──────────────────────┘
└──────────────────┘       │ input (JSON)     │
                           │  invoice.*       │
                           │  vendor.*        │
                           │  jdg_entrepreneur.*│  ← NOWE: dane przedsiębiorcy JDG
                           │  confidence.*    │
                           │  thresholds.jdg.*│
                           └──────────────────┘
```

### 0.3 Konwencja nazewnicza werdyktu JDG

Każda reguła zwraca ustandaryzowany obiekt — rozszerzony o pola specyficzne dla JDG:

```rego
{
    "matched": true,                         # Czy reguła dopasowana
    "rule_id": "jdg.vat.fuel.pl",            # Unikalny identyfikator z prefiksem jdg.*
    "package": "jdg.vat.substantive",        # Pakiet źródłowy
    "priority": 52,                          # Priorytet

    # ── VAT ──
    "vat_rate": "0.23",                      # Stawka VAT (string "0.23" = 23%)
    "rounding_level": "position",            # "position" | "total"
    "gtu_code": "GTU_04",                   # Kod GTU (lub "")
    "procedure": "",                         # "VAT_REVERSE_CHARGE" | "IMPORT" | "MARGIN" | ""
    "vat_exemption": "",                     # "SUBJECT" | "OBJECT" | ""

    # ── PIT / Podatek dochodowy JDG ──
    "pit_form": "",                          # "SCALE" | "LINEAR" | "LUMP_SUM" | "TAX_CARD"
    "pit_rate": "",                          # Stawka PIT (string "0.12", "0.19", etc.)
    "pit_bracket": "",                       # "LOW" (12%) | "HIGH" (32%) | ""
    "pit_advance_frequency": "",             # "MONTHLY" | "QUARTERLY"
    "pit_advance_due_day": 0,               # Dzień miesiąca płatności zaliczki
    "pit_annual_return_type": "",           # "PIT-36" | "PIT-36L" | "PIT-28" | ""

    # ── KUP / Koszty uzyskania przychodu ──
    "kus_qualification": "",                 # "full" | "partial" | "none" | "limited_car_150k" | "private_mixed"
    "kus_percent": 100,                     # Procent KUP (dla wydatków mieszanych)
    "pkpir_column": 0,                      # Kolumna PKPiR (1-16)

    # ── ZUS i składki ──
    "zus_social_base_type": "",             # "STANDARD" | "PREFERENTIAL" | "MALY_ZUS_PLUS" | "START_RELIEF"
    "zus_social_base_percent": 0,           # % podstawy wymiaru
    "zus_health_rate": "",                  # Stawka zdrowotna (string "0.09" | "0.049")
    "zus_health_deductible_from_tax": false, # Czy zdrowotna odliczana od podatku
    "zus_health_limit_type": "",            # "" | "LINEAR_LIMITED" | "LUMP_SUM_TIER"

    # ── Cykl życia JDG ──
    "business_status": "",                   # "ACTIVE" | "SUSPENDED" | "CLOSED" | "IN_SUCCESSIO"
    "ceidg_registration_required": false,    # Czy wymagana rejestracja CEIDG
    "unregistered_activity_limit_exceeded": false, # Przekroczenie limitu dział. nieewidencj.

    # ── Routing i audyt ──
    "_routing": "",                          # "" | "BLOCK_AND_ALERT" | "TRIAGE_QUEUE"
    "_routing_reason": "",                  # Czytelny powód
    "_legal_basis": "",                     # Podstawa prawna
    "_warnings": []                          # Ostrzeżenia
}
```

---

## 1. Architektura Pakietów i Priorytetów JDG

### 1.1 Hierarchia pakietów JDG (drzewo)

```
policies/jdg/
├── main_jdg.rego                 # Główny else-chain scalający wszystkie pakiety JDG
├── _helpers_jdg.rego             # Funkcje pomocnicze JDG
├── _metadata_jdg.rego            # Metadane reguł JDG
│
├── risk.rego                     # P0-P9:   Fraud, anomalie, semantic guard (adaptowane)
├── routing.rego                  # P10-P19: Field confidence (adaptowane)
│
├── compliance/                   # P20-P39: Zgodność dokumentacyjna JDG
│   ├── whitelist.rego            # P20-P22: Biała Lista MF
│   ├── mpp.rego                  # P25:     Split payment
│   └── cash_limit.rego           # P35:     Limit płatności gotówkowych
│
├── crossborder.rego              # P40-P49: Transakcje transgraniczne (bez zmian vs plan ogólny)
│
├── vat/
│   ├── substantive.rego          # P50-P64: Stawki VAT wg kategorii, zwolnienia
│   ├── gtu.rego                  # P65-P69: Mapowanie GTU
│   ├── exemptions.rego           # P55-P58: Zwolnienia podmiotowe i przedmiotowe
│   ├── deduction.rego            # P185-P189: Odliczenia VAT (proporcja, korekty)
│   └── tax_point.rego            # P230-P231: Moment powstania obowiązku podatkowego
│
├── pit/
│   ├── form_scale.rego           # P500-P509:   Skala podatkowa 12%/32%
│   ├── form_linear.rego          # P510-P519:   Podatek liniowy 19%
│   ├── form_lump_sum.rego        # P520-P529:   Ryczałt ewidencjonowany
│   ├── form_tax_card.rego        # P530-P539:   Karta podatkowa
│   ├── advances.rego             # P540-P549:   Zaliczki na PIT (miesięczne/kwartalne)
│   ├── annual_returns.rego       # P550-P559:   Zeznania roczne (PIT-36, PIT-36L, PIT-28)
│   ├── kup.rego                  # P560-P579:   Koszty uzyskania przychodu JDG
│   └── exemptions.rego           # P580-P589:   Zwolnienia PIT (młodzi, powrót, 4+, senior)
│
├── allowances/
│   ├── rd.rego                   # P600-P609:   Ulga B+R
│   ├── ip_box.rego               # P610-P619:   IP Box
│   ├── prototype.rego            # P620:        Ulga na prototyp
│   ├── robotization.rego         # P621:        Ulga na robotyzację
│   ├── expansion.rego            # P622:        Ulga na ekspansję
│   ├── thermo.rego               # P623:        Ulga termomodernizacyjna
│   ├── rehabilitation.rego       # P624:        Ulga rehabilitacyjna
│   ├── internet.rego             # P625:        Ulga internetowa
│   └── donation.rego             # P626-P628:   Darowizny
│
├── zus/
│   ├── social.rego               # P700-P719:   Składki społeczne JDG
│   ├── health.rego               # P720-P739:   Składka zdrowotna JDG
│   ├── start_relief.rego         # P740:        Ulga na start
│   ├── maly_zus_plus.rego        # P741:        Mały ZUS Plus
│   └── preferential.rego         # P742:        Preferencyjny ZUS
│
├── accounting/
│   ├── pkpir.rego                # P800-P819:   PKPiR — Podatkowa Księga Przychodów i Rozchodów
│   ├── lump_sum_evidence.rego    # P820-P829:   Ewidencja przychodów ryczałtowca
│   ├── vat_evidence.rego         # P830-P839:   Ewidencja VAT
│   ├── depreciation.rego         # P840-P849:   Amortyzacja środków trwałych JDG
│   └── private_mixed.rego        # P850-P859:   Wydatki mieszane (prywatno-firmowe)
│
├── business/
│   ├── ceidg.rego                # P900-P909:   CEIDG — rejestracja i zmiany
│   ├── suspension.rego           # P910-P919:   Zawieszenie działalności
│   ├── succession.rego           # P920-P929:   Sukcesja po śmierci przedsiębiorcy
│   └── unregistered.rego         # P930-P939:   Działalność nieewidencjonowana
│
├── ksef/
│   ├── structured_invoice.rego   # P950-P959:   Faktury ustrukturyzowane KSeF
│   └── offline_recovery.rego     # P960-P969:   Tryb awaryjny KSeF
│
├── jpk/
│   ├── jpk_vat.rego              # P970-P979:   JPK_V7M/K
│   └── jpk_pkpir.rego            # P980-P989:   JPK_PKPIR
│├── local_taxes/                              # NOWY — podatki lokalne (P1300-P1320)
│   ├── pcc.rego                             # P1300 — PCC od zakupów od osób prywatnych
│   ├── real_estate.rego                     # P1310 — Podatek od nieruchomości firmowych
│   └── transport.rego                       # P1320 — Podatek od środków transportowych
│
├── retention.rego                             # P990-P999:   Obowiązek przechowywania dokumentów
│
└── fallback.rego                             # P1000-P1099: Reguły domyślne JDG
```

> **Uwaga:** Pakiety `local_taxes/*`, rozszerzenia `risk.rego` o KKS (P0_b, P4, P6, P6_b, P7), `vat.deduction` (P183-P184, P192), `vat.*` (P39, P233-P234), `pit.*` (P508-P509, P512, P524-P526, P532-P533, P572-P574), `zus.*` (P739, P743-P746, P748), `accounting.fx_differences` (P870), `business.succession` (P925-P927), `statute_liability` (P1153, P1157, P1167-P1172, P1174), `representation` (P1205) — z audytu `25_JDG_DEEP_LEGAL_AUDIT.md` — pozostają do zaimplementowania.  

### 1.2 Macierz priorytetów JDG

| Zakres priorytetów | Pakiet | Odpowiedzialność | Skutek dopasowania |
|---|---|---|---|
| **P0-P9** | `jdg.risk` | Fraud, anomalie, kontrahent zawieszony w CEIDG | BLOCK — faktura zablokowana |
| **P10-P19** | `jdg.routing` | OCR confidence, field quality | BLOCK_AND_ALERT / TRIAGE_QUEUE |
| **P20-P39** | `jdg.compliance.*` | Biała Lista, MPP, limit gotówkowy | BLOCK / MPP flag / ostrzeżenia |
| **P40-P49** | `jdg.crossborder` | UE reverse charge, import, export, WDT | Procedura specjalna |
| **P50-P69** | `jdg.vat.*` | Stawki VAT, GTU, zwolnienia podmiotowe/przedmiotowe, odliczenia | Stawka VAT + GTU |
| **P500-P589** | `jdg.pit.*` | Forma opodatkowania PIT, KUP, zaliczki, zeznania, zwolnienia | Stawka PIT + forma + KUP |
| **P600-P628** | `jdg.allowances.*` | Ulgi podatkowe JDG | Odliczenie / preferencja |
| **P700-P742** | `jdg.zus.*` | Składki ZUS społeczne i zdrowotne, ulgi składkowe | Stawki składek, podstawa |
| **P800-P859** | `jdg.accounting.*` | PKPiR, ewidencje, amortyzacja, wydatki mieszane | Kolumna PKPiR / metoda ewidencji |
| **P900-P939** | `jdg.business.*` | CEIDG, zawieszenie, sukcesja, dział. nieewidencjonowana | Status działalności |
| **P950-P969** | `jdg.ksef.*` | KSeF faktury ustrukturyzowane | KSeF flag |
| **P970-P989** | `jdg.jpk.*` | JPK_VAT, JPK_PKPIR | Znaczniki JPK |
| **P990-P999** | `jdg.retention` | Przechowywanie dokumentów JDG | Okres retencji |
| **P1000-P1099** | `jdg.fallback` | Domyślna stawka PL 23% | Fallback |

### 1.3 Diagram pierwszeństwa JDG (first-match-wins)

```
INPUT ──────────────────────────────────────────────────────────────────────► WERDYKT JDG

─── BLOK BIZNESOWY ───
P0  ──► fraud_graph_match               Kontrahent w sieci fraudowej?
P1  ──► counterparty_trust_low          Trust score poniżej progu?
P2  ──► anomaly_amount                  Kwota >3σ od średniej?
P3  ──► new_counterparty_flag           Nowy kontrahent?
P5  ──► semantic_guard_disallowed       Wydatek niezwiązany z działalnością?
P8  ──► ceidg_vendor_suspended          Kontrahent z zawieszoną działalnością CEIDG? ★JDG
         │
─── BLOK ROUTING ───
P10 ──► fc_vat_rate_low                 Pewność stawki VAT poniżej progu?
P12 ──► fc_vendor_nip_low               Pewność NIP poniżej progu?
P19 ──► fc_global_minimum_low           Ogólna pewność poniżej minimum?
         │
─── BLOK COMPLIANCE ───
P20 ──► whitelist_missing_over_limit    Brak na Białej Liście >15k PLN?
P25 ──► split_payment_mandatory         Obowiązkowy MPP?
P35 ──► cash_transaction_over_limit     Gotówka >15k PLN → brak KUP?
         │
─── BLOK CROSSBORDER ───
P40 ──► eu_reverse_charge               WNT — reverse charge?
P42 ──► wdt_intracommunity_supply       WDT — 0% VAT?
P45 ──► import_non_eu                   Import spoza UE?
P48 ──► export_goods                    Eksport towarów?
         │
─── BLOK VAT ───
P50 ──► vat_margin_scheme               Procedura marży?
P52 ──► vat_rate_fuel_pl                Paliwo → 23% + GTU_04
P53 ──► vat_rate_food_pl                Żywność → 5% + GTU_07
P55 ──► vat_exemption_education         Edukacja → zwolniona
P56 ──► vat_exemption_healthcare        Medycyna → zwolniona
P58 ──► vat_exemption_subject_jdg       Zwolnienie podmiotowe JDG (200k limit) ★JDG
P60 ──► vat_bad_debt_relief             Ulga na złe długi VAT
P65 ──► gtu_mapping_by_category         Mapowanie GTU
         │
─── BLOK PIT / FORMA OPODATKOWANIA ───
P500─► pit_form_scale                   Skala podatkowa 12%/32%
P510─► pit_form_linear                  Podatek liniowy 19%
P520─► pit_form_lump_sum                Ryczałt ewidencjonowany
P530─► pit_form_tax_card                Karta podatkowa
         │
─── BLOK PIT / KUP ───
P560─► kup_full_deductible              Pełny KUP
P562─► kup_private_mixed_jdg            Wydatek mieszany prywatno-firmowy ★JDG
P564─► kup_car_over_150k_limit          Auto >150k PLN — limit KUP
P566─► kup_representation_none          Reprezentacja → NKUP
         │
─── BLOK PIT / ZALICZKI I ZEZNANIA ───
P540─► pit_advance_monthly              Zaliczka miesięczna
P542─► pit_advance_quarterly            Zaliczka kwartalna (mały podatnik)
P550─► pit_annual_return_pit36          Zeznanie PIT-36
P552─► pit_annual_return_pit36l         Zeznanie PIT-36L
P554─► pit_annual_return_pit28          Zeznanie PIT-28
         │
─── BLOK PIT / ZWOLNIENIA ───
P580─► pit_exemption_young              Ulga dla młodych (<26 lat)
P582─► pit_exemption_return             Ulga na powrót
P584─► pit_exemption_family_4plus       Ulga 4+
P586─► pit_exemption_working_senior     Ulga dla pracujących emerytów
         │
─── BLOK ULGI ───
P600─► relief_rd_jdg                    Ulga B+R dla JDG
P610─► relief_ip_box_jdg                IP Box 5% dla JDG
P623─► relief_thermo_jdg                Ulga termomodernizacyjna JDG
         │
─── BLOK ZUS ───
P740─► zus_start_relief_jdg             Ulga na start (6 mies.) ★JDG
P741─► zus_maly_plus_jdg                Mały ZUS Plus ★JDG
P742─► zus_preferential_jdg             Preferencyjny ZUS ★JDG
P700─► zus_social_standard_jdg          Standardowe składki społeczne ★JDG
P720─► zus_health_scale_jdg             Składka zdrowotna 9% (skala) ★JDG
P722─► zus_health_linear_jdg            Składka zdrowotna 4.9% (liniowy) ★JDG
P724─► zus_health_lump_sum_jdg          Składka zdrowotna (ryczałt — progi) ★JDG
         │
─── BLOK KSIĘGOWOŚĆ JDG ───
P800─► pkpir_column_mapping             Mapowanie wydatku na kolumnę PKPiR ★JDG
P810─► pkpir_revenue_recognition        Rozpoznanie przychodu w PKPiR ★JDG
P820─► lump_sum_evidence_entry          Ewidencja przychodów ryczałtowca ★JDG
P830─► vat_evidence_purchase            Ewidencja VAT zakupów ★JDG
P832─► vat_evidence_sale                Ewidencja VAT sprzedaży ★JDG
P840─► depreciation_linear_jdg          Amortyzacja liniowa JDG
P850─► private_mixed_home_office        Wydatki mieszane — home office ★JDG
P852─► private_mixed_car                Wydatki mieszane — samochód ★JDG
         │
─── BLOK CYKL ŻYCIA JDG ───
P900─► ceidg_registration_check         Obowiązek rejestracji CEIDG ★JDG
P902─► ceidg_data_change_notification   Obowiązek aktualizacji CEIDG ★JDG
P910─► business_suspension_valid        Zawieszenie — skutki podatkowe ★JDG
P914─► business_suspension_zus          Zawieszenie — skutki ZUS ★JDG
P920─► succession_continuity            Sukcesja — ciągłość NIP ★JDG
P922─► succession_tax_obligations       Sukcesja — obowiązki podatkowe ★JDG
P930─► unregistered_activity_limit      Limit działalności nieewidencjonowanej ★JDG
         │
─── BLOK KSeF / JPK ───
P950─► ksef_structured_mandatory        Obowiązek KSeF
P970─► jpk_v7m_structure                JPK_V7M — struktura miesięczna
P980─► jpk_pkpir_structure              JPK_PKPIR — struktura
         │
─── BLOK RETENCJI ───
P990─► retention_invoice_5y             Przechowywanie faktur 5 lat
P992─► retention_pkpir_5y               Przechowywanie PKPiR 5 lat
         │
─── FALLBACK ───
P1000─► domestic_fallback_jdg           Domyślna stawka 23% VAT PL
P1099─► no_match_jdg                    NO_MATCHING_RULE (zawsze na końcu)
```

---

## 2. Struktura Danych Wejściowych JDG (`input`)

### 2.1 Pełna specyfikacja `input` dla JDG

Struktura `input` dla JDG rozszerza strukturę ogólną o kluczowe sekcje specyficzne dla jednoosobowej działalności gospodarczej.

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
    "is_cash_payment": false,
    "is_advance": false,
    "invoice_number": "FV/2026/06/001",
    "issue_date": "2026-06-15",
    "due_date": "2026-07-15",
    "is_paid": false,
    "days_overdue": 0,
    "is_continuous_service": false,
    "invoice_type": "",
    "discount_amount": 0,
    "delivery_date": "2026-06-10",
    "is_correction": false,
    "modifies_closed_vat_period": false,
    "type": "GOODS",
    "is_personal_expense": false,
    "is_documented_uncollectible": false,
    "months_since_issue": 0,
    "is_vat_deducted": false,
    "vat_taxable": true,
    "correction_type": "",
    "has_buyer_agreement": false,
    "language": "PL",
    "days_since_issue": 0,
    "event_date": "",
    "is_adjusting_event": false,
    "direction": "PURCHASE",
    "is_service": false,
    "lease_term_months": 0,
    "asset_normative_months": 0,
    "lease_has_purchase_option": false,
    "kst_group": 0,
    "kst_subgroup": 0,

    "private_use_percent": 0,
    "home_office_area_percent": 0,
    "is_home_office": false,
    "private_mileage_km": 0,
    "business_mileage_km": 0,
    "vat_cash_accounting": false,
    "payment_date": null
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
    "trust_score": 0.92,
    "fraud_flag": false,
    "is_new": false,
    "ceidg_status": "ACTIVE",
    "nip_valid": true,
    "is_ngo": false,
    "is_religious_org": false,
    "is_pep": false,
    "crbr_verified": true,
    "is_company": false,
    "whitelist_check_expired": false,
    "whitelist_status": "VERIFIED",
    "has_residence_certificate": false,
    "has_transport_license": true,
    "is_b2b_buyer": false,
    "is_b2c": false,
    "aml_risk_assessment_done": true
  },
  "jdg_entrepreneur": {
    "nip": "9876543210",
    "regon": "123456789",
    "full_name": "Jan Kowalski",
    "birth_date": "1990-05-15",
    "age": 36,
    "tax_form": "PIT_SCALE",
    "tax_form_changed_from": "",
    "tax_form_change_date": null,
    "is_vat_payer": true,
    "is_vat_eu_registered": false,
    "vat_exemption_used_since": "2026-01-01",
    "annual_turnover_net": 180000.00,
    "annual_turnover_gross": 221400.00,
    "cumulative_income_current_year": 85000.00,
    "cumulative_income_previous_month": 72000.00,
    "cumulative_advances_paid": 5400.00,
    "cumulative_zus_social_paid": 8200.00,
    "cumulative_zus_health_paid": 3800.00,
    "is_small_taxpayer": true,
    "uses_quarterly_advances": false,
    "uses_simplified_advances": false,
    "simplified_advance_base": 0,
    "has_rd_status": false,
    "rd_is_centrum": false,
    "children_count": 0,
    "joint_filing": false,
    "return_from_emigration": false,
    "return_years_used": 0,
    "is_working_senior": false,
    "internet_years_used": 0,
    "has_loss_carry_forward": false,
    "loss_carry_forward_amount": 0,
    "loss_carry_forward_year": 0,
    "tax_return_filed_current": false,
    "tax_return_filed_previous": true,
    "fiscal_year_start": "2026-01-01",
    "closed_financial_year_end": "2025-12-31",
    "is_fs_approved": true,
    "uses_full_accounting": false,
    "uses_pkpir": true,
    "is_accounting_month_closed": false,
    "under_tax_audit": false,
    "audit_year": null,
    "has_active_deferral_decision": false,
    "employees_count": 0,
    "business_name": "JK Software Development",
    "ceidg_entry_date": "2020-03-01",
    "ceidg_last_update_date": "2026-01-15",
    "pkd_main": "62.01.Z",
    "pkd_secondary": ["62.02.Z", "62.09.Z"],
    "business_status": "ACTIVE",
    "suspension_start_date": null,
    "suspension_end_date": null,
    "is_unregistered_activity": false,
    "monthly_revenue_current": 8500.00,
    "in_succession": false,
    "succession_start_date": null,
    "succession_manager_nip": null,
    "succession_manager_name": null,

    "zus_status": "STANDARD",
    "zus_months_used_total": 48,
    "zus_months_used_current_status": 12,
    "zus_last_payment_date": "2026-06-10",
    "zus_base_declared": 4500.00,

    "lump_sum_annual_revenue": 0,
    "lump_sum_health_tier": "",
    "tax_card_monthly_rate": 0,
    "tax_card_decision_date": null,
    "tax_card_decision_number": "",

    "owns_guard_dog": false,
    "is_dog_registered_in_municipality": false
  },
  "confidence": {
    "fc_minimum": 0.95,
    "fc_vat_rate": 0.98,
    "fc_total_net": 0.97,
    "fc_vendor_nip": 0.99,
    "fc_category_code": 0.96,
    "fc_invoice_number": 0.99,
    "fc_total_gross": 0.97,
    "fc_transaction_date": 0.98,
    "fc_vendor_name": 0.95
  },
  "tax_type": "",
  "document": {
    "type": "",
    "filing_date_mm_dd": "",
    "months_since_fye": 0,
    "tax_status": "",
    "days_since_declaration": 0,
    "zaw_nr_filed": false,
    "zaw_nr_days_since_transfer": 0,
    "days_since_summon": 0,
    "parties_identified": true,
    "has_operation_description": true,
    "is_appealed_without_stay": false
  },
  "system": {
    "ksef_status": "ONLINE",
    "target": "",
    "auth_token_exists": true,
    "qualified_signature_exists": false
  },
  "request": {
    "type": ""
  },
  "thresholds": {
    "jdg": {
      "rates": {
        "vat_standard": "0.23",
        "vat_reduced_8": "0.08",
        "vat_reduced_5": "0.05",
        "vat_zero": "0.00",
        "pit_scale_low": "0.12",
        "pit_scale_high": "0.32",
        "pit_linear": "0.19",
        "pit_ip_box": "0.05",
        "zus_pension": "0.1952",
        "zus_disability": "0.08",
        "zus_sickness": "0.0245",
        "zus_accident": "0.0167",
        "zus_health_scale": "0.09",
        "zus_health_linear_lump": "0.049",
        "zus_labour_fund": "0.0245",
        "zus_fgsp": "0.001",
        "prolongation_fee": "0.50"
      },
      "limits": {
        "mpp_limit": 15000,
        "vat_exemption_limit": 200000,
        "vat_exemption_limit_startup_proportional": 200000,
        "cash_transaction_limit": 15000,
        "bad_debt_days_vat": 150,
        "bad_debt_days_cit_pit": 90,
        "retention_years_invoice": 5,
        "retention_years_pkpir": 5,
        "retention_years_payroll": 10,
        "trust_auto_post": 0.92,
        "trust_suggest": 0.75,
        "small_mandate_limit": 200,
        "car_value_kup_limit": 150000,
        "car_mileage_limit_km": 0,
        "aml_reporting_threshold_eur": 15000,
        "overpayment_refund_days": 45,
        "zaw_nr_deadline_days": 7,
        "jpk_correction_days": 14,
        "nbp_reporting_threshold": 100000
      },
      "bounds": {
        "pit_scale_threshold": 120000,
        "pit_tax_free_amount": 30000,
        "pit_tax_free_reduction": 3600,
        "pit_young_exemption_limit": 85528,
        "pit_return_exemption_limit": 85528,
        "pit_family_4plus_limit": 85528,
        "pit_working_senior_limit": 85528,
        "relief_thermo_max": 53000,
        "relief_internet_max": 760,
        "relief_internet_years": 2,
        "relief_rd_base": 100,
        "relief_rd_centrum": 200,
        "relief_prototype_percent": 30,
        "relief_robotization_percent": 50,
        "relief_expansion_max": 1000000,
        "blood_liter_equivalent": 130,
        "zus_start_months": 6,
        "zus_preferential_months": 24,
        "zus_preferential_base_percent": 0.30,
        "zus_maly_plus_months": 36,
        "zus_maly_plus_base_percent": 0.30,
        "zus_health_linear_deduction_limit": 12900,
        "zus_health_lump_tier1_limit": 60000,
        "zus_health_lump_tier2_limit": 300000,
        "minimum_wage_gross": 4666,
        "unregistered_activity_limit_percent": 0.50,
        "pkpir_revenue_limit_eur": 2000000,
        "dzia_nieewidencjonowana_limit": 2333
      },
      "fc_thresholds": {
        "pit_scale_vat_rate": 0.95,
        "pit_scale_total_net": 0.90,
        "pit_scale_minimum": 0.85,
        "linear_vat_rate": 0.95,
        "linear_total_net": 0.90,
        "linear_minimum": 0.85,
        "lump_sum_vat_rate": 0.95,
        "lump_sum_total_net": 0.60,
        "lump_sum_minimum": 0.80,
        "vendor_nip": 0.80,
        "category_code": 0.80,
        "global_minimum": 0.70,
        "mixed_auto_minimum": 0.90,
        "private_mixed_minimum": 0.85
      },
      "lump_sum_rates": {
        "rate_17": { "value": "0.17", "pkwiu_codes": ["69", "70", "71", "73", "74", "75", "77", "78", "79", "80", "81", "82", "85.6"] },
        "rate_15": { "value": "0.15", "pkwiu_codes": ["68.2", "68.3", "78", "79", "80", "81"] },
        "rate_14": { "value": "0.14", "pkwiu_codes": ["62.01", "95.11", "95.12"] },
        "rate_12": { "value": "0.12", "pkwiu_codes": ["58.2", "62.02", "62.03", "62.09", "63", "95.2"] },
        "rate_10": { "value": "0.10", "pkwiu_codes": ["41", "42", "43"] },
        "rate_8_5": { "value": "0.085", "pkwiu_codes": ["01", "02", "03", "05", "06", "07", "08", "09", "10-33", "45", "46", "47", "49", "50", "51", "52", "53", "55", "56", "58.1", "59", "60", "61", "68.1", "72", "84", "85.1", "85.2", "85.3", "85.4", "85.5", "86", "87", "88", "90", "91", "92", "93", "94", "95", "96", "97", "98", "99"] },
        "rate_5_5": { "value": "0.055", "pkwiu_codes": ["41", "42", "43", "64", "65", "66"] },
        "rate_3": { "value": "0.03", "pkwiu_codes": ["10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "56"] },
        "rate_2": { "value": "0.02", "pkwiu_codes": ["01", "02", "03"] }
      }
    }
  }
}
```

### 2.2 Źródła danych JDG

| Sekcja `input` | Źródło w NexusAI | Aktualizacja |
|---|---|---|
| `jdg_entrepreneur.*` | Konfiguracja użytkownika + CEIDG API | Manualnie / API CEIDG |
| `invoice.*` | OCR Pipeline + KSeF API | Per faktura |
| `vendor.*` | GUS BIR + Biała Lista MF + CEIDG API | Cache 30 dni |
| `confidence.*` | OCR Consensus Engine | Per faktura |
| `thresholds.jdg.*` | DuckDB RuleStore (`jdg_thresholds` table) | Hot-reload przez NATS |
| `document.*` | Metadane systemowe | Per dokument |
| `system.*` | Stan systemu KSeF | Real-time |
| `tax_type` | Kontekst zapytania | Per request |

### 2.3 Nowe pola JDG — kluczowe różnice

| Pole | Opis | Dlaczego potrzebne w JDG |
|---|---|---|
| `jdg_entrepreneur.tax_form` | Forma opodatkowania: `PIT_SCALE`, `LINEAR`, `LUMP_SUM`, `TAX_CARD` | JDG ma 4 formy PIT, nie CIT |
| `jdg_entrepreneur.cumulative_income_*` | Narastający dochód/przychód w roku | Do wyliczenia zaliczek i progów |
| `jdg_entrepreneur.business_status` | Status: ACTIVE / SUSPENDED / CLOSED / IN_SUCCESSIO | Cykl życia JDG |
| `jdg_entrepreneur.zus_status` | Status ZUS: STANDARD / PREFERENTIAL / MALY_ZUS_PLUS / START_RELIEF | Specyficzne ulgi składkowe JDG |
| `jdg_entrepreneur.uses_pkpir` | Czy prowadzi PKPiR | JDG do 2M EUR używa PKPiR |
| `jdg_entrepreneur.is_unregistered_activity` | Czy działalność nieewidencjonowana | Art. 5 Prawa przedsiębiorców |
| `jdg_entrepreneur.in_succession` | Czy trwa sukcesja po śmierci | Zarząd sukcesyjny |
| `invoice.private_use_percent` | % użytku prywatnego wydatku | Wydatki mieszane JDG |
| `invoice.is_home_office` | Czy wydatek dotyczy home office | Proporcja KUP/VAT |
| `vendor.ceidg_status` | Status CEIDG kontrahenta | Weryfikacja kontrahenta JDG |
| `thresholds.jdg.*` | Dedykowane parametry dla JDG | Oddzielenie od parametrów CIT |

---

## 3. Szczegółowy Opis Reguł JDG

---

## 3.1 Pakiet `jdg.risk` — Ryzyko i Fraud (P0-P9)

Reguły ryzyka adaptowane pod JDG — kluczowa różnica: dodatkowa reguła weryfikacji CEIDG kontrahenta.

### P0: `fraud_graph_match`

- **Cel biznesowy:** Natychmiastowa blokada faktury od kontrahenta zidentyfikowanego w sieci fraudowej VAT. Identycznie jak w planie ogólnym — reguła uniwersalna.
- **Przesłanki:** `input.vendor.fraud_flag == true`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `fraud_detected: true`
- **Podstawa prawna:** Art. 86 ust. 1 ustawy o VAT, Art. 55 KKS
- **Zależności:** FraudGraphScanner musi wcześniej oznaczyć vendor.fraud_flag
- **Priorytet:** 0 (najwyższy — blokuje wszystko)

### P1: `counterparty_trust_low`

- **Cel biznesowy:** Niski trust score kontrahenta (< progu `trust_auto_post`) → TRIAGE. Dla JDG szczególnie istotne przy nowych kontrahentach bez historii.
- **Przesłanki:** `input.vendor.trust_score < input.thresholds.jdg.limits.trust_auto_post` AND `input.vendor.trust_score > 0`
- **Rezultat:** `_routing: "TRIAGE_QUEUE"`, `vendor_trust_score: <value>`
- **Podstawa prawna:** Art. 22 UoR (zasada ostrożności), ADR-009
- **Priorytet:** 1

### P2: `anomaly_amount`

- **Cel biznesowy:** Wykrycie anomalii kwotowej (>3σ od średniej dla danej kategorii). Dla JDG ważne ze względu na mniejszą skalę i większą zmienność wydatków.
- **Przesłanki:** `input.invoice.amount_net > (category_avg + 3 * category_stddev)`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `_anomaly_zscore: <value>`
- **Podstawa prawna:** Art. 22 UoR (zasada ostrożności)
- **Priorytet:** 2

### P3: `new_counterparty_flag`

- **Cel biznesowy:** Nowy kontrahent → dodatkowa weryfikacja. Dla JDG ryzyko wyższe ze względu na częstsze transakcje B2C i z małymi podmiotami.
- **Przesłanki:** `input.vendor.is_new == true`
- **Rezultat:** `_routing: "TRIAGE_QUEUE"`
- **Podstawa prawna:** Art. 22 UoR, procedury AML
- **Priorytet:** 3

### P5: `semantic_guard_disallowed`

- **Cel biznesowy:** Wykrycie wydatków niezwiązanych z działalnością. Dla JDG KLUCZOWE — zaostrzone blokady dla wydatków osobistych (okulary, posiłki na mieście poza podróżą służbową, odzież niereprezentacyjna).
- **Przesłanki:** Kategoria w `["ALCOHOL", "ENTERTAINMENT", "LUXURY"]` lub `SemanticGuard` oznacza `disallowed`; dodatkowo JDG: `input.invoice.is_personal_expense == true` AND brak związku z BHP/działalnością
- **Rezultat:** `kus_qualification: "none"`, `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 23 PIT (dla JDG — PIT, nie CIT!)
- **Zależności:** SemanticGuard + klasyfikacja wydatków prywatnych
- **Priorytet:** 5

### P8: `ceidg_vendor_suspended`

- **Cel biznesowy:** Wykrycie kontrahenta JDG z zawieszoną działalnością w CEIDG — ryzyko fraudu / brak prawa do odliczenia VAT. ★ NOWA REGUŁA JDG ★
- **Przesłanki:** `input.vendor.ceidg_status == "SUSPENDED"` AND `input.invoice.transaction_date > vendor.suspension_date`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `fraud_risk_elevated: true`
- **Podstawa prawna:** Art. 88 ustawy o VAT (brak prawa do odliczenia), Art. 22-25 Prawa przedsiębiorców
- **Zależności:** CEIDG API musi dostarczyć `vendor.ceidg_status`
- **Priorytet:** 8

---

## 3.2 Pakiet `jdg.routing` — Field Confidence (P10-P19)

Adaptowane z planu ogólnego — progi confidence per forma opodatkowania JDG.

### P10: `fc_vat_rate_low_scale`

- **Cel biznesowy:** Niska pewność stawki VAT dla JDG na skali → blokada automatycznego księgowania
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "PIT_SCALE"` AND `input.confidence.fc_vat_rate < input.thresholds.jdg.fc_thresholds.pit_scale_vat_rate` AND `input.confidence.fc_vat_rate > 0`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 22 UoR (rzetelność ksiąg)
- **Priorytet:** 10

### P11: `fc_total_net_low_scale`

- **Cel biznesowy:** Niska pewność kwoty netto dla JDG na skali → blokada
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "PIT_SCALE"` AND `input.confidence.fc_total_net < input.thresholds.jdg.fc_thresholds.pit_scale_total_net`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`
- **Priorytet:** 11

### P12: `fc_vendor_nip_low`

- **Cel biznesowy:** Niska pewność NIP kontrahenta → ryzyko błędnej weryfikacji Białej Listy. Dla JDG krytyczne — często transakcje z małymi podmiotami.
- **Przesłanki:** `input.confidence.fc_vendor_nip < input.thresholds.jdg.fc_thresholds.vendor_nip` AND `input.confidence.fc_vendor_nip > 0`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 96b ustawy o VAT, Art. 22 UoR
- **Priorytet:** 12

### P14: `fc_linear_minimum`

- **Cel biznesowy:** Niska ogólna pewność dla JDG na podatku liniowym → TRIAGE
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "LINEAR"` AND `input.confidence.fc_minimum < input.thresholds.jdg.fc_thresholds.linear_minimum`
- **Rezultat:** `_routing: "TRIAGE_QUEUE"`
- **Priorytet:** 14

### P15: `fc_lump_sum_vat_rate`

- **Cel biznesowy:** Niska pewność stawki VAT dla ryczałtowca → TRIAGE (ryczałtowcy często nie odliczają VAT)
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "LUMP_SUM"` AND `input.confidence.fc_vat_rate < input.thresholds.jdg.fc_thresholds.lump_sum_vat_rate`
- **Rezultat:** `_routing: "TRIAGE_QUEUE"`
- **Priorytet:** 15

### P16: `fc_lump_sum_total_net`

- **Cel biznesowy:** Niska pewność kwoty netto dla ryczałtowca — niższy próg (0.60 zamiast 0.90)
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "LUMP_SUM"` AND `input.confidence.fc_total_net < input.thresholds.jdg.fc_thresholds.lump_sum_total_net`
- **Rezultat:** `_routing: "TRIAGE_QUEUE"` (ryczałtowcy — mniej krytyczne, ale nadal alert)
- **Priorytet:** 16

### P19: `fc_global_minimum_low`

- **Cel biznesowy:** Ogólnie niska pewność → TRIAGE
- **Przesłanki:** `input.confidence.fc_minimum < input.thresholds.jdg.fc_thresholds.global_minimum`
- **Rezultat:** `_routing: "TRIAGE_QUEUE"`
- **Priorytet:** 19

---

## 3.3 Pakiet `jdg.compliance` — Zgodność dokumentacyjna (P20-P39)

### P20: `whitelist_missing_over_limit`

- **Cel biznesowy:** Weryfikacja Białej Listy MF dla przelewów >15 000 PLN. Dla JDG szczególnie istotne — odpowiedzialność solidarna przedsiębiorcy.
- **Przesłanki:** `input.invoice.amount_gross >= input.thresholds.jdg.limits.mpp_limit` AND `input.vendor.on_whitelist == false`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `_warning: "Brak kontrahenta na Białej Liście MF — odpowiedzialność solidarna"`
- **Podstawa prawna:** Art. 96b ustawy o VAT, Art. 117ba Ordynacji podatkowej
- **Priorytet:** 20

### P21: `whitelist_account_mismatch`

- **Cel biznesowy:** Rachunek niezgodny z Białą Listą → odpowiedzialność solidarna
- **Przesłanki:** `input.invoice.amount_gross >= input.thresholds.jdg.limits.mpp_limit` AND `input.vendor.account_on_whitelist == false` AND `input.vendor.on_whitelist == true`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 117ba § 1 Ordynacji podatkowej
- **Priorytet:** 21

### P25: `split_payment_mandatory`

- **Cel biznesowy:** Obowiązkowy MPP dla faktur >15k PLN z towarami wrażliwymi. JDG jako czynny podatnik VAT musi stosować.
- **Przesłanki:** `input.invoice.amount_gross >= input.thresholds.jdg.limits.mpp_limit` AND kategoria wrażliwa MPP
- **Rezultat:** `mpp_required: true`, `_warning: "Obowiązkowy mechanizm podzielonej płatności"`
- **Podstawa prawna:** Art. 108a ustawy o VAT
- **Priorytet:** 25

### P35: `cash_transaction_over_limit`

- **Cel biznesowy:** Płatność gotówkowa >15k PLN → brak KUP. Dla JDG — PIT, nie CIT!
- **Przesłanki:** `input.invoice.is_cash_payment == true` AND `input.invoice.amount_gross >= input.thresholds.jdg.limits.cash_transaction_limit`
- **Rezultat:** `kus_qualification: "none"`, `_warning: "Płatność gotówkowa powyżej limitu — brak KUP"`
- **Podstawa prawna:** Art. 22p ustawy o PIT (dla JDG — PIT!)
- **Priorytet:** 35

---

## 3.4 Pakiet `jdg.crossborder` — Transgraniczne (P40-P49)

Reguły crossborder pozostają bez zmian względem planu ogólnego — transakcje transgraniczne są identyczne dla JDG i spółek.

> ⚠️ **[DEPRECATED — Doc 22 → Doc 23]** Reguły P40, P41, P42, P45, P48 z Doc 22 są zastąpione przez bardziej szczegółowe odpowiedniki w Doc 23: P43-P49, P190-P191, P232 (`23_JDG_EXPANSION_SUPPLEMENT.md` §3). Wersje kanoniczne: Doc 23.

- ~~P40: `eu_reverse_charge`~~ → **[DEPRECATED]** — zastąpione przez P43 (Doc 23)
- ~~P41: `eu_import_services`~~ → **[DEPRECATED]** — zastąpione przez P44 (Doc 23)
- ~~P42: `wdt_intracommunity_supply`~~ → **[DEPRECATED]** — zastąpione przez P46 (Doc 23)
- ~~P45: `import_non_eu`~~ → **[DEPRECATED]** — zastąpione przez P47 (Doc 23)
- ~~P48: `export_goods`~~ → **[DEPRECATED]** — zastąpione przez P49 (Doc 23)

---

## 3.5 Pakiet `jdg.vat` — VAT dla JDG (P50-P69, P185-P189, P230-P233)

### 3.5.1 `jdg.vat.substantive` — Reguły merytoryczne VAT

#### P50: `vat_margin_scheme`

- **Cel biznesowy:** Procedura VAT-marża — szczególnie istotna dla JDG handlujących towarami używanymi (komisy, antykwariaty)
- **Przesłanki:** `input.invoice.procedure == "MARGIN"`
- **Rezultat:** `vat_rate: "0.23"` (od marży), `procedure: "MARGIN"`
- **Podstawa prawna:** Art. 120 ustawy o VAT
- **Priorytet:** 50

#### P52-P54: Stawki VAT wg kategorii (PL)

Bez zmian względem planu ogólnego — stawki VAT są identyczne niezależnie od formy prawnej.

| Reguła | Kategoria | VAT | GTU | Podstawa prawna |
|--------|----------|-----|-----|----------------|
| P52 | FUEL | 0.23 | GTU_04 | Art. 41 ust. 1 VAT |
| P53 | FOOD | 0.05 | GTU_07 | Art. 41 ust. 2a VAT |
| P54 | BOOKS | 0.05 | GTU_01 | Art. 41 ust. 2a VAT |

#### P55: `vat_exemption_education`

- **Cel biznesowy:** Usługi edukacyjne zwolnione z VAT — częste w JDG (korepetycje, szkolenia)
- **Przesłanki:** `input.invoice.category_code == "EDUCATION"` AND `input.vendor.country == "PL"`
- **Rezultat:** `vat_rate: "0.00"`, `rounding_level: "total"`
- **Podstawa prawna:** Art. 43 ust. 1 pkt 26-29 VAT
- **Priorytet:** 55

#### P56: `vat_exemption_healthcare`

- **Cel biznesowy:** Usługi medyczne zwolnione z VAT — istotne dla JDG w branży medycznej
- **Przesłanki:** `input.invoice.category_code == "HEALTHCARE"` AND `input.vendor.country == "PL"`
- **Rezultat:** `vat_rate: "0.00"`
- **Podstawa prawna:** Art. 43 ust. 1 pkt 18-20 VAT
- **Priorytet:** 56

#### P58: `vat_exemption_subject_jdg` ★ MODYFIKACJA JDG ★

- **Cel biznesowy:** Zwolnienie podmiotowe VAT dla JDG (limit 200 000 PLN). Dla JDG kluczowe — wielu przedsiębiorców korzysta ze zwolnienia. Uwzględnia proporcję dla nowo założonych firm (prorata temporis).
- **Przesłanki:** 
  - `input.jdg_entrepreneur.is_vat_payer == false`
  - `input.jdg_entrepreneur.annual_turnover_net < input.thresholds.jdg.limits.vat_exemption_limit`
  - Dla nowych JDG: proporcjonalny limit od daty rozpoczęcia działalności
- **Rezultat:** `vat_rate: "0.00"`, `vat_exemption: "SUBJECT"`
- **Podstawa prawna:** Art. 113 ust. 1 i ust. 9 ustawy o VAT (proporcja dla nowych podatników)
- **Zależności:** 
  - Musi być sprawdzona PRZED regułami stawek VAT
  - Wymaga `jdg_entrepreneur.ceidg_entry_date` do obliczenia proporcji dla nowych firm
- **Priorytet:** 58

#### P60: `vat_bad_debt_relief` 🔴 [DEPRECATED]

> ⚠️ **[DEPRECATED — Doc 22 → Doc 23]** Zastąpione przez P189 `bad_debt_relief_creditor` (`23_JDG_EXPANSION_SUPPLEMENT.md` §8).
> P189 jest bardziej szczegółowa (5 przesłanek vs 2, jawny kierunek faktury, 3 rezultaty).
> **UWAGA:** P189 wymaga aktualizacji terminu: 150 dni (nie 90) dla wierzyciela VAT.

- ~~**Cel biznesowy:** Ulga na złe długi — korekta VAT po 150 dniach~~
- ~~**Przesłanki:** `input.invoice.is_paid == false` AND `input.invoice.days_overdue >= input.thresholds.jdg.limits.bad_debt_days_vat`~~
- ~~**Rezultat:** `bad_debt_relief_eligible: true`~~
- ~~**Podstawa prawna:** Art. 89a ustawy o VAT~~
- ~~**Priorytet:** 60~~

#### P65: `gtu_mapping_by_category`

- **Cel biznesowy:** Automatyczne przypisanie kodu GTU. Bez zmian względem planu ogólnego.
- **Przesłanki:** `input.invoice.category_code` ma zdefiniowane mapowanie GTU
- **Rezultat:** `gtu_code: <kod>`
- **Podstawa prawna:** § 10 rozporządzenia w sprawie JPK_VAT
- **Priorytet:** 65

### 3.5.2 `jdg.vat.tax_point` — Moment obowiązku podatkowego

#### P230: `vat_tax_point_continuous_service` 🔴 [DEPRECATED]

> ⚠️ **[DEPRECATED — Doc 22 → Doc 28a]** Zastąpione przez R0546-R0559 (`28a_JDG_EDGE_CASES_FULL.md` Grupa A — VAT Edge Cases).
> Reguły Doc 28a mają pełny 10-polowy format ENTERPRISE z przykładami ± i 4 edge cases na regułę.

- ~~**Cel biznesowy:** Moment obowiązku dla usług ciągłych (abonamenty, najem). Częste w JDG IT (SaaS, hosting).~~
- ~~**Przesłanki:** `input.invoice.is_continuous_service == true`~~
- ~~**Rezultat:** `tax_point: "END_OF_PERIOD"`~~
- ~~**Podstawa prawna:** Art. 19a ust. 3 VAT~~
- ~~**Priorytet:** 230~~

#### P231: `vat_tax_point_advance_invoice` 🔴 [DEPRECATED]

> ⚠️ **[DEPRECATED — Doc 22 → Doc 28a]** Zastąpione przez R0546-R0559 (`28a_JDG_EDGE_CASES_FULL.md` Grupa A).

- ~~**Cel biznesowy:** Moment obowiązku dla faktur zaliczkowych~~
- ~~**Przesłanki:** `input.invoice.invoice_type == "ADVANCE"`~~
- ~~**Rezultat:** `tax_point: "PAYMENT_DATE"`~~
- ~~**Podstawa prawna:** Art. 19a ust. 8 VAT~~
- ~~**Priorytet:** 231~~

#### P235: `vat_cash_accounting_jdg` ★ NOWA REGUŁA JDG ★ 🔴 [DEPRECATED]

> ⚠️ **[DEPRECATED — Doc 22 → Doc 28a]** Zastąpione przez R0546-R0559 (`28a_JDG_EDGE_CASES_FULL.md` Grupa A).

- ~~**Cel biznesowy:** Metoda kasowa VAT dla małych podatników JDG~~
- ~~**Przesłanki:** `input.jdg_entrepreneur.is_small_taxpayer == true` AND `input.jdg_entrepreneur.is_vat_payer == true` AND `input.invoice.vat_cash_accounting == true`~~
- ~~**Rezultat:** `vat_cash_accounting: true`, `tax_point: "PAYMENT_DATE"`~~
- ~~**Podstawa prawna:** Art. 21 ustawy o VAT (metoda kasowa dla małych podatników)~~
- ~~**Priorytet:** 235~~

---

## 3.6 Pakiet `jdg.pit` — PIT / Forma opodatkowania JDG (P500-P589)

Tu znajduje się SEDNO JDG — cztery formy opodatkowania, zaliczki, zeznania, KUP, zwolnienia.

### 3.6.1 `jdg.pit.form_scale` — Skala podatkowa (P500-P509)

#### P500: `pit_form_scale`

- **Cel biznesowy:** Identyfikacja formy opodatkowania — skala podatkowa 12%/32%. Domyślna forma dla JDG.
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "PIT_SCALE"`
- **Rezultat:** 
  - `pit_form: "SCALE"`
  - `pit_rate: "0.12"` (I próg) lub `"0.32"` (II próg) — zależnie od dochodu
  - `pit_bracket_threshold: input.thresholds.jdg.bounds.pit_scale_threshold` (120 000 PLN)
  - `pit_tax_free_amount: input.thresholds.jdg.bounds.pit_tax_free_amount` (30 000 PLN)
  - `pit_tax_free_reduction: input.thresholds.jdg.bounds.pit_tax_free_reduction` (3 600 PLN)
  - `pit_annual_return_type: "PIT-36"`
- **Podstawa prawna:** Art. 27 ust. 1 ustawy o PIT
- **Zależności:** Nadrzędna nad regułami KUP i zaliczek — określa kontekst dla wszystkich reguł PIT
- **Priorytet:** 500

#### P501: `pit_scale_bracket_determination`

- **Cel biznesowy:** Ustalenie progu podatkowego na podstawie narastającego dochodu rocznego
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form == "PIT_SCALE"`
  - `input.jdg_entrepreneur.cumulative_income_current_year <= input.thresholds.jdg.bounds.pit_scale_threshold` → I próg
  - `input.jdg_entrepreneur.cumulative_income_current_year > input.thresholds.jdg.bounds.pit_scale_threshold` → II próg
- **Rezultat:** 
  - I próg: `pit_bracket: "LOW"`, `pit_rate: "0.12"`
  - II próg: `pit_bracket: "HIGH"`, `pit_rate: "0.32"` (tylko od nadwyżki)
- **Podstawa prawna:** Art. 27 ust. 1 PIT
- **Priorytet:** 501

#### P502: `pit_scale_joint_filing`

- **Cel biznesowy:** Wspólne rozliczenie małżonków — efektywne podwojenie progu do 240 000 PLN. Tylko przy skali podatkowej!
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "PIT_SCALE"` AND `input.jdg_entrepreneur.joint_filing == true`
- **Rezultat:** `pit_bracket_threshold: 240000` (2 × 120 000), `joint_filing_active: true`
- **Podstawa prawna:** Art. 6 ust. 2 PIT
- **Priorytet:** 502

### 3.6.2 `jdg.pit.form_linear` — Podatek liniowy (P510-P519)

#### P510: `pit_form_linear`

- **Cel biznesowy:** Podatek liniowy 19% — popularna forma dla lepiej zarabiających JDG. Brak kwoty wolnej, brak wspólnego rozliczenia.
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "LINEAR"`
- **Rezultat:** 
  - `pit_form: "LINEAR"`
  - `pit_rate: input.thresholds.jdg.rates.pit_linear` ("0.19")
  - `pit_tax_free_amount: 0` (BRAK kwoty wolnej przy liniowym!)
  - `pit_annual_return_type: "PIT-36L"`
  - `pit_advance_frequency: "MONTHLY"`
  - `pit_advance_due_day: 20`
- **Podstawa prawna:** Art. 30c ustawy o PIT
- **Zależności:** 
  - Blokuje wspólne rozliczenie (P502)
  - Blokuje większość ulg i zwolnień osobistych (P580-P586)
  - Wpływa na składkę zdrowotną (P722 — 4.9% z limitem odliczenia)
- **Priorytet:** 510

#### P511: `pit_linear_no_tax_free_amount`

- **Cel biznesowy:** Podatek liniowy NIE ma kwoty wolnej od podatku. Kluczowa różnica vs skala.
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "LINEAR"`
- **Rezultat:** `pit_tax_free_amount: 0`, `pit_tax_free_reduction: 0`
- **Podstawa prawna:** Art. 30c PIT (brak zastosowania art. 27)
- **Priorytet:** 511

### 3.6.3 `jdg.pit.form_lump_sum` — Ryczałt ewidencjonowany (P520-P529)

#### P520: `pit_form_lump_sum`

- **Cel biznesowy:** Ryczałt od przychodów ewidencjonowanych — forma uproszczona, podatek od przychodu (nie dochodu), różne stawki wg PKWiU.
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "LUMP_SUM"`
- **Rezultat:** 
  - `pit_form: "LUMP_SUM"`
  - `pit_rate` — zależna od PKWiU (P521)
  - `pit_annual_return_type: "PIT-28"`
  - `pit_advance_frequency: "MONTHLY"` lub `"QUARTERLY"`
  - `pit_advance_due_day: 20`
- **Podstawa prawna:** Ustawa o zryczałtowanym podatku dochodowym (Dz.U. 2025 poz. 234)
- **Priorytet:** 520

#### P521: `lump_sum_rate_by_pkwiu`

- **Cel biznesowy:** Przypisanie stawki ryczałtu na podstawie kodu PKWiU z `input.invoice.pkwiu_code`
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "LUMP_SUM"`
- **Rezultat:** Stawka ryczałtu z `input.thresholds.jdg.lump_sum_rates.*` wg PKWiU
- **Tabela stawek:**
  
  | Stawka | PKWiU (przykłady) | Typowe branże JDG |
  |--------|-------------------|-------------------|
  | 17% | 69, 70, 71, 73-75, 77-82, 85.6 | Wolne zawody, doradztwo, prawnicy |
  | 15% | 68.2, 68.3, 78-81 | Pośrednictwo, kultura, rozrywka |
  | 14% | 62.01, 95.11, 95.12 | IT — oprogramowanie, naprawa |
  | 12% | 58.2, 62.02-62.09, 63, 95.2 | Software, hosting, usługi IT |
  | 10% | 41, 42, 43 | Budownictwo |
  | 8.5% | 01-03, 05-39, 45-47, 49-53, 55-56, 58.1, 59-61, 68.1, 72, 84-85.5, 86-88, 90-99 | Handel, produkcja, transport, edukacja |
  | 5.5% | 41-43 (z materiałem), 64-66 | Budownictwo z materiałem, finanse |
  | 3% | 10-33, 56 | Produkcja żywności, gastronomia |
  | 2% | 01-03 | Produkcja rolna |

- **Podstawa prawna:** Art. 12 ustawy o ryczałcie ewidencjonowanym
- **Priorytet:** 521

#### P522: `lump_sum_multiple_rates`

- **Cel biznesowy:** JDG może osiągać przychody opodatkowane różnymi stawkami ryczałtu — konieczność wyodrębnienia. ★ NOWA REGUŁA JDG ★
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "LUMP_SUM"` AND wiele stawek ryczałtu w ewidencji
- **Rezultat:** `lump_sum_multi_rate: true`, `requires_separate_evidence: true`
- **Podstawa prawna:** Art. 12 ust. 3-5 ustawy o ryczałcie (różne stawki dla różnych rodzajów działalności)
- **Priorytet:** 522

#### P523: `lump_sum_annual_limit`

- **Cel biznesowy:** Limit przychodów dla ryczałtu — 2 000 000 EUR rocznie. Po przekroczeniu → obowiązek przejścia na skalę lub podatek liniowy.
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "LUMP_SUM"` AND `input.jdg_entrepreneur.annual_turnover_net > równowartość 2 000 000 EUR`
- **Rezultat:** `lump_sum_limit_exceeded: true`, `_routing: "BLOCK_AND_ALERT"`, `_warning: "Przekroczony limit ryczałtu — obowiązek zmiany formy opodatkowania"`
- **Podstawa prawna:** Art. 6 ust. 4 ustawy o ryczałcie
- **Priorytet:** 523

### 3.6.4 `jdg.pit.form_tax_card` — Karta podatkowa (P530-P539)

#### P530: `pit_form_tax_card`

- **Cel biznesowy:** Karta podatkowa — forma dostępna tylko dla JDG, stała kwota podatku niezależna od dochodu. Bez ewidencji KUP, bez PKPiR, bez zeznania rocznego (tylko PIT-16A). Wygaszana dla nowych podatników.
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "TAX_CARD"`
- **Rezultat:** 
  - `pit_form: "TAX_CARD"`
  - `pit_monthly_amount: input.jdg_entrepreneur.tax_card_monthly_rate` (kwota decyzji US)
  - `pit_annual_return_type: ""` (brak zeznania rocznego!)
  - `requires_pkpir: false`
  - `requires_lump_sum_evidence: false`
  - `pit_advance_frequency: "MONTHLY"`
  - `pit_advance_due_day: 7`
- **Podstawa prawna:** Art. 21-30 ustawy o ryczałcie (rozdział 3 — karta podatkowa)
- **Priorytet:** 530

#### P531: `tax_card_decision_valid`

- **Cel biznesowy:** Weryfikacja czy decyzja o karcie podatkowej jest aktualna i obowiązuje
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "TAX_CARD"` AND `input.jdg_entrepreneur.tax_card_decision_date != null`
- **Rezultat:** `tax_card_active: true`
- **Podstawa prawna:** Art. 29 ustawy o ryczałcie
- **Priorytet:** 531

### 3.6.5 `jdg.pit.advances` — Zaliczki na PIT (P540-P549)

#### P540: `pit_advance_monthly`

- **Cel biznesowy:** Ustalenie miesięcznej zaliczki na PIT. Dla JDG to podstawowy mechanizm — zaliczka = (dochód narastająco × stawka) - suma zapłaconych zaliczek - składki ZUS społeczne.
- **Przesłanki:** `input.jdg_entrepreneur.tax_form in ["PIT_SCALE", "LINEAR", "LUMP_SUM"]`
- **Rezultat:** 
  - `pit_advance_frequency: "MONTHLY"`
  - `pit_advance_due_day: 20` (do 20. dnia następnego miesiąca)
  - `pit_advance_calculation_base: "CUMULATIVE_INCOME_MINUS_ZUS_SOCIAL_MINUS_PAID_ADVANCES"`
- **Podstawa prawna:** Art. 44 ust. 1 i 3 PIT
- **Priorytet:** 540

#### P541: `pit_advance_zus_social_deduction`

- **Cel biznesowy:** Odliczenie zapłaconych składek ZUS społecznych od dochodu przy wyliczaniu zaliczki PIT. ★ KLUCZOWE DLA JDG ★
- **Przesłanki:** 
  - `input.jdg_entrepreneur.cumulative_zus_social_paid > 0`
  - `input.jdg_entrepreneur.tax_form in ["PIT_SCALE", "LINEAR"]`
- **Rezultat:** `pit_advance_base` pomniejszone o zapłacone składki społeczne
- **Podstawa prawna:** Art. 26 ust. 1 pkt 2 PIT
- **Zależności:** Zależy od P700-P742 (składki ZUS) — reguły ZUS muszą być sprawdzone PRZED wyliczeniem zaliczki
- **Priorytet:** 541

#### P542: `pit_advance_quarterly`

- **Cel biznesowy:** Kwartalne zaliczki PIT dla małych podatników JDG
- **Przesłanki:** `input.jdg_entrepreneur.is_small_taxpayer == true` AND `input.jdg_entrepreneur.uses_quarterly_advances == true`
- **Rezultat:** `pit_advance_frequency: "QUARTERLY"`, `pit_advance_due_day: 20` (miesiąca po kwartale)
- **Podstawa prawna:** Art. 44 ust. 3g PIT
- **Priorytet:** 542

#### P543: `pit_advance_simplified`

- **Cel biznesowy:** Uproszczona forma zaliczek — 1/12 podatku z roku poprzedniego (lub dwa lata wstecz)
- **Przesłanki:** `input.jdg_entrepreneur.uses_simplified_advances == true`
- **Rezultat:** `pit_advance_method: "SIMPLIFIED"`, `pit_advance_monthly_amount: simplified_base / 12`
- **Podstawa prawna:** Art. 44 ust. 6b PIT
- **Priorytet:** 543

### 3.6.6 `jdg.pit.annual_returns` — Zeznania roczne (P550-P559)

#### P550: `pit_annual_return_pit36`

- **Cel biznesowy:** Obowiązek złożenia PIT-36 dla JDG na skali podatkowej. Termin: do 30 kwietnia.
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "PIT_SCALE"`
- **Rezultat:** `pit_annual_return_type: "PIT-36"`, `pit_annual_return_deadline: "04-30"`
- **Podstawa prawna:** Art. 45 ust. 1 PIT
- **Priorytet:** 550

#### P552: `pit_annual_return_pit36l`

- **Cel biznesowy:** PIT-36L dla JDG na podatku liniowym
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "LINEAR"`
- **Rezultat:** `pit_annual_return_type: "PIT-36L"`, `pit_annual_return_deadline: "04-30"`
- **Podstawa prawna:** Art. 45 ust. 1a PIT
- **Priorytet:** 552

#### P554: `pit_annual_return_pit28`

- **Cel biznesowy:** PIT-28 dla JDG na ryczałcie. Termin: do końca lutego (wcześniej niż PIT-36!).
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "LUMP_SUM"`
- **Rezultat:** `pit_annual_return_type: "PIT-28"`, `pit_annual_return_deadline: "02-28"` ★
- **Podstawa prawna:** Art. 21 ust. 1 ustawy o ryczałcie
- **Priorytet:** 554

#### P556: `pit_annual_return_overdue`

- **Cel biznesowy:** Wykrycie przekroczenia terminu złożenia zeznania rocznego
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_return_filed_current == false`
  - Bieżąca data > deadline dla formy opodatkowania
- **Rezultat:** `tax_return_overdue: true`, `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 45 PIT, art. 56 KKS
- **Priorytet:** 556

### 3.6.7 `jdg.pit.kup` — Koszty uzyskania przychodu JDG (P560-P579)

#### P560: `kup_full_deductible`

- **Cel biznesowy:** Wydatek w całości stanowi KUP — standardowy przypadek dla wydatków firmowych JDG.
- **Przesłanki:** Wydatek związany z działalnością, `is_paid == true` (dla zaliczek PIT — metoda memoriałowa lub kasowa w zależności od PKPiR)
- **Rezultat:** `kus_qualification: "full"`, `kus_percent: 100`
- **Podstawa prawna:** Art. 22 ust. 1 PIT
- **Priorytet:** 560

#### P561: `kup_zus_social_deductible`

- **Cel biznesowy:** Składki ZUS społeczne przedsiębiorcy JDG stanowią KUP. ★ SPECYFIKA JDG ★
- **Przesłanki:** 
  - `input.invoice.expense_type == "ZUS_SOCIAL_ENTREPRENEUR"`
  - `input.invoice.is_paid == true`
- **Rezultat:** `kus_qualification: "full"`, `kus_percent: 100`
- **Podstawa prawna:** Art. 22 ust. 1 w zw. z art. 23 ust. 1 pkt 37 PIT (składki ZUS przedsiębiorcy — KUP)
- **Priorytet:** 561

#### P562: `kup_private_mixed_jdg` ★ NOWA REGUŁA JDG ★

- **Cel biznesowy:** Wydatki mieszane (prywatno-firmowe) — proporcjonalne rozliczenie KUP. Klasyczny problem JDG: media w home office, telefon, internet, samochód.
- **Przesłanki:** 
  - `input.invoice.private_use_percent > 0`
  - `input.invoice.private_use_percent < 100`
- **Rezultat:** 
  - `kus_qualification: "partial"`
  - `kus_percent: 100 - input.invoice.private_use_percent`
  - `_warning: "Wydatek mieszany — KUP proporcjonalnie do wykorzystania firmowego"`
- **Podstawa prawna:** Art. 22 ust. 1 PIT (tylko wydatki w części dotyczącej działalności)
- **Priorytet:** 562

#### P564: `kup_car_over_150k_limit`

- **Cel biznesowy:** Ograniczenie KUP dla samochodów osobowych >150 000 PLN (leasing i zakup). Dla JDG limit identyczny jak dla spółek.
- **Przesłanki:** `input.invoice.category_code == "CAR"` AND `input.invoice.amount_net > 150000`
- **Rezultat:** `kus_qualification: "limited_car_150k"`, `kus_proportion: 150000 / amount_net`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 47a PIT (dla JDG — PIT!)
- **Priorytet:** 564

#### P566: `kup_representation_none`

- **Cel biznesowy:** Wydatki na reprezentację — całkowicie wyłączone z KUP
- **Przesłanki:** `input.invoice.expense_type == "REPRESENTATION"`
- **Rezultat:** `kus_qualification: "none"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 23 PIT
- **Priorytet:** 566

#### P568: `kup_unpaid_zus_social`

- **Cel biznesowy:** Niezapłacone składki ZUS społeczne przedsiębiorcy — NIE stanowią KUP do momentu zapłaty. ★ SPECYFIKA JDG ★
- **Przesłanki:** 
  - `input.invoice.expense_type == "ZUS_SOCIAL_ENTREPRENEUR"`
  - `input.invoice.is_paid == false`
- **Rezultat:** `kus_qualification: "none"`, `kus_deferred: true`, `_warning: "Niezapłacone składki ZUS — KUP dopiero po zapłacie"`
- **Podstawa prawna:** Art. 22 ust. 6ba PIT (składki ZUS — KUP w dacie zapłaty)
- **Priorytet:** 568

#### P570: `kup_health_contrib_linear_deduction`

- **Cel biznesowy:** Odliczenie składki zdrowotnej od podstawy opodatkowania przy podatku liniowym — limit 12 900 PLN rocznie. ★ SPECYFIKA JDG ★
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form == "LINEAR"`
  - `input.invoice.expense_type == "ZUS_HEALTH_ENTREPRENEUR"`
  - `input.invoice.is_paid == true`
  - Roczna suma zapłaconej składki zdrowotnej ≤ `input.thresholds.jdg.bounds.zus_health_linear_deduction_limit`
- **Rezultat:** `kus_qualification: "partial_health_limit"`, `kus_annual_limit: 12900`
- **Podstawa prawna:** Art. 30c ust. 2 pkt 2 PIT
- **Priorytet:** 570

### 3.6.8 `jdg.pit.exemptions` — Zwolnienia PIT (P580-P589)

#### P580: `pit_exemption_young`

- **Cel biznesowy:** Ulga dla młodych (do 26 r.ż.) — zwolnienie z PIT do 85 528 PLN rocznie
- **Przesłanki:** 
  - `input.jdg_entrepreneur.tax_form == "PIT_SCALE"` (tylko skala!)
  - `input.jdg_entrepreneur.age <= 26`
  - `input.jdg_entrepreneur.cumulative_income_current_year <= input.thresholds.jdg.bounds.pit_young_exemption_limit`
- **Rezultat:** `pit_rate: "0.00"`, `exemption: "YOUNG"`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 148 PIT
- **Priorytet:** 580

#### P582: `pit_exemption_return`

- **Cel biznesowy:** Ulga na powrót — 4 lata zwolnienia po emigracji
- **Przesłanki:** `input.jdg_entrepreneur.return_from_emigration == true` AND `input.jdg_entrepreneur.return_years_used < 4`
- **Rezultat:** `pit_rate: "0.00"`, `exemption: "RETURN"`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 152 PIT
- **Priorytet:** 582

#### P584: `pit_exemption_family_4plus`

- **Cel biznesowy:** Ulga dla rodzin 4+ dzieci
- **Przesłanki:** `input.jdg_entrepreneur.children_count >= 4`
- **Rezultat:** `pit_rate: "0.00"`, `exemption: "FAMILY_4PLUS"`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 153 PIT
- **Priorytet:** 584

#### P586: `pit_exemption_working_senior`

- **Cel biznesowy:** Ulga dla pracujących emerytów — JDG po osiągnięciu wieku emerytalnego bez pobierania emerytury
- **Przesłanki:** `input.jdg_entrepreneur.is_working_senior == true`
- **Rezultat:** `pit_rate: "0.00"`, `exemption: "WORKING_SENIOR"`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 154 PIT
- **Priorytet:** 586

---

## 3.7 Pakiet `jdg.allowances` — Ulgi podatkowe JDG (P600-P628)

### P600: `relief_rd_jdg`

- **Cel biznesowy:** Ulga B+R — odliczenie 100% (lub 200% dla CBR) kosztów kwalifikowanych. Dla JDG — odliczenie od dochodu z działalności.
- **Przesłanki:** `input.jdg_entrepreneur.has_rd_status == true` AND koszty kwalifikowane B+R
- **Rezultat:** `relief_type: "RD"`, `relief_percent: 100` (lub 200 dla CBR)
- **Podstawa prawna:** Art. 26e PIT (dla JDG — PIT!)
- **Priorytet:** 600

### P610: `relief_ip_box_jdg`

- **Cel biznesowy:** IP Box — preferencyjna stawka 5% od dochodów z kwalifikowanego IP. Dla JDG IT — jedna z najważniejszych ulg.
- **Przesłanki:** Dochód z kwalifikowanego IP, PKWiU w katalogu
- **Rezultat:** `pit_rate: "0.05"`, `relief_type: "IP_BOX"`
- **Podstawa prawna:** Art. 30ca PIT (dla JDG — PIT!)
- **Priorytet:** 610

### P623: `relief_thermo_jdg`

- **Cel biznesowy:** Ulga termomodernizacyjna — max 53 000 PLN. Dla JDG: odliczenie od podstawy opodatkowania (PIT).
- **Przesłanki:** Wydatki na termomodernizację budynku mieszkalnego
- **Rezultat:** `relief_type: "THERMO"`, `relief_max: 53000`
- **Podstawa prawna:** Art. 26h PIT
- **Priorytet:** 623

---

## 3.8 Pakiet `jdg.zus` — Składki ZUS dla JDG (P700-P742)

To SERCE JDG — składki społeczne i zdrowotne są fundamentalnie różne od pracowniczych.

### 3.8.1 `jdg.zus.social` — Składki społeczne JDG (P700-P719)

#### P700: `zus_social_standard_jdg`

- **Cel biznesowy:** Standardowe składki społeczne JDG — od podstawy 60% prognozowanego przeciętnego wynagrodzenia (lub wyższej zadeklarowanej).
- **Przesłanki:** `input.jdg_entrepreneur.zus_status == "STANDARD"`
- **Rezultat:** 
  - `zus_social_base_type: "STANDARD"`
  - `zus_pension_rate: "0.1952"` (19,52%)
  - `zus_disability_rate: "0.08"` (8%)
  - `zus_sickness_rate: "0.0245"` (2,45% — DOBROWOLNA dla JDG!)
  - `zus_accident_rate: "0.0167"` (1,67%)
  - `zus_labour_fund_rate: "0.0245"` (2,45% Fundusz Pracy)
- **Podstawa prawna:** Art. 18, 18a, 22 ustawy o SUS
- **Priorytet:** 700

#### P701: `zus_sickness_voluntary_jdg` 🔴 [DEPRECATED]

> ⚠️ **[DEPRECATED — Doc 22 → Doc 28]** Zastąpione przez R0346 `zus_sickness_voluntary` (`28_JDG_ULTIMATE_GRANULARITY.md` — indeks główny Doc 28, nie Doc 28a edge cases).
> R0346 jest bardziej szczegółowa (pełny 10-polowy format ENTERPRISE).

- ~~**Cel biznesowy:** Składka chorobowa dla JDG jest DOBROWOLNA. ★ SPECYFIKA JDG ★~~
- ~~**Przesłanki:** `input.jdg_entrepreneur.zus_sickness_voluntary == false`~~
- ~~**Rezultat:** `zus_sickness_rate: "0.00"` (nie nalicza się)~~
- ~~**Podstawa prawna:** Art. 11 ust. 2 ustawy o SUS (dobrowolność ubezpieczenia chorobowego dla JDG)~~
- ~~**Priorytet:** 701~~

### 3.8.2 `jdg.zus.start_relief` — Ulga na start (P740)

#### P740: `zus_start_relief_jdg`

- **Cel biznesowy:** Ulga na start — 6 miesięcy bez składek społecznych (tylko składka zdrowotna). Dla nowych JDG. ★ SPECYFIKA JDG ★
- **Przesłanki:** 
  - `input.jdg_entrepreneur.zus_status == "START_RELIEF"`
  - `input.jdg_entrepreneur.zus_months_used_current_status < input.thresholds.jdg.bounds.zus_start_months`
- **Rezultat:** 
  - `zus_social_base_type: "START_RELIEF"`
  - `zus_pension_rate: "0.00"`
  - `zus_disability_rate: "0.00"`
  - `zus_sickness_rate: "0.00"`
  - `zus_accident_rate: "0.00"`
  - `zus_labour_fund_rate: "0.00"`
  - `zus_health_only: true`
  - `zus_months_remaining: 6 - used_months`
- **Podstawa prawna:** Art. 18a ustawy o SUS
- **Priorytet:** 740

### 3.8.3 `jdg.zus.maly_plus` — Mały ZUS Plus (P741)

#### P741: `zus_maly_plus_jdg`

- **Cel biznesowy:** Mały ZUS Plus — obniżona podstawa wymiaru składek (30% minimalnego wynagrodzenia) przez 36 miesięcy. ★ SPECYFIKA JDG ★
- **Przesłanki:** 
  - `input.jdg_entrepreneur.zus_status == "MALY_ZUS_PLUS"`
  - `input.jdg_entrepreneur.zus_months_used_current_status < input.thresholds.jdg.bounds.zus_maly_plus_months`
  - Roczny przychód w poprzednim roku ≤ 120 000 PLN (warunek dostępu)
- **Rezultat:** 
  - `zus_social_base_type: "MALY_ZUS_PLUS"`
  - `zus_social_base_percent: 0.30`
  - `zus_base_amount: 0.30 * minimum_wage`
  - `zus_months_remaining: 36 - used_months`
- **Podstawa prawna:** Art. 18c ustawy o SUS
- **Priorytet:** 741

### 3.8.4 `jdg.zus.preferential` — Preferencyjny ZUS (P742)

#### P742: `zus_preferential_jdg`

- **Cel biznesowy:** Preferencyjny ZUS — obniżona podstawa (30% minimalnego wynagrodzenia) przez pierwsze 24 miesiące od rozpoczęcia działalności. ★ SPECYFIKA JDG ★
- **Przesłanki:** 
  - `input.jdg_entrepreneur.zus_status == "PREFERENTIAL"`
  - `input.jdg_entrepreneur.zus_months_used_current_status < input.thresholds.jdg.bounds.zus_preferential_months`
- **Rezultat:** 
  - `zus_social_base_type: "PREFERENTIAL"`
  - `zus_social_base_percent: input.thresholds.jdg.bounds.zus_preferential_base_percent`
  - `zus_months_remaining: 24 - used_months`
- **Podstawa prawna:** Art. 18a ustawy o SUS
- **Priorytet:** 742

### 3.8.5 `jdg.zus.health` — Składka zdrowotna JDG (P720-P739)

#### P720: `zus_health_scale_jdg`

- **Cel biznesowy:** Składka zdrowotna 9% od dochodu dla JDG na skali podatkowej. NIE podlega odliczeniu od podatku. ★ SPECYFIKA JDG ★
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "PIT_SCALE"`
- **Rezultat:** 
  - `zus_health_rate: "0.09"`
  - `zus_health_base: "INCOME"` (od dochodu)
  - `zus_health_deductible_from_tax: false` (NIE odlicza się od PIT przy skali!)
  - `zus_health_minimum: 9% od minimalnego wynagrodzenia`
- **Podstawa prawna:** Art. 79 ust. 1, art. 81 ust. 1 ustawy o świadczeniach opieki zdrowotnej
- **Priorytet:** 720

#### P722: `zus_health_linear_jdg`

- **Cel biznesowy:** Składka zdrowotna 4.9% od dochodu dla JDG na podatku liniowym. Z LIMITEM odliczenia od podstawy opodatkowania (12 900 PLN rocznie). ★ SPECYFIKA JDG ★
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "LINEAR"`
- **Rezultat:** 
  - `zus_health_rate: "0.049"`
  - `zus_health_base: "INCOME"`
  - `zus_health_deductible_from_tax: false` (odlicza się od podstawy opodatkowania, nie od podatku)
  - `zus_health_limit_type: "LINEAR_LIMITED"`
  - `zus_health_annual_deduction_limit: 12900`
  - `zus_health_minimum: 4.9% od minimalnego wynagrodzenia`
- **Podstawa prawna:** Art. 79 ust. 2, art. 81 ust. 2, art. 30c ust. 2 pkt 2 PIT
- **Priorytet:** 722

#### P724: `zus_health_lump_sum_jdg`

- **Cel biznesowy:** Składka zdrowotna dla JDG na ryczałcie — 3 sztywne progi zależne od rocznego przychodu. ★ SPECYFIKA JDG ★
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "LUMP_SUM"`
- **Rezultat:** 
  - `zus_health_rate: "0.049"` (nominalnie)
  - `zus_health_base: "LUMP_SUM_TIERS"`
  - `zus_health_limit_type: "LUMP_SUM_TIER"`
  - **Progi rocznej składki:**
    - Przychód ≤ 60 000 PLN → składka = 9% od 60% przeciętnego wynagrodzenia
    - Przychód 60 001 – 300 000 PLN → składka = 9% od 100% przeciętnego wynagrodzenia
    - Przychód > 300 000 PLN → składka = 9% od 180% przeciętnego wynagrodzenia
- **Podstawa prawna:** Art. 81 ust. 2a-2c ustawy o świadczeniach opieki zdrowotnej
- **Priorytet:** 724

---

## 3.9 Pakiet `jdg.accounting` — Księgowość JDG (P800-P859)

### 3.9.1 `jdg.accounting.pkpir` — PKPiR (P800-P819)

#### P800: `pkpir_column_mapping` 🔴 [DEPRECATED]

> ⚠️ **[DEPRECATED — Doc 22 → Doc 28a]** Zastąpione przez R0372-R0399 (`28a_JDG_EDGE_CASES_FULL.md` — 28 reguł pełnej księgowości JDG).
> Doc 28a ma radykalnie więcej reguł (28 vs 3) pokrywających: kolumny, amortyzację, leasing, FX, FIFO, RMK, home office.

- ~~**Cel biznesowy:** Mapowanie wydatku na odpowiednią kolumnę PKPiR (16 kolumn). ★ SPECYFIKA JDG ★~~
- ~~**Przesłanki:** `input.jdg_entrepreneur.uses_pkpir == true`~~
- ~~**Rezultat:** `pkpir_column: <numer 1-16>`~~

> ℹ️ **Tabela mapowania PKPiR (16 kolumn) poniżej — zachowana jako materiał referencyjny,** nie podlega deprecjacji — jest to dokumentacja struktury danych, nie reguła decyzyjna.

**Tabela mapowania PKPiR (16 kolumn):**

| Kol. | Nazwa | Typ wydatku JDG |
|------|-------|-----------------|
| 1 | Lp. | Numer porządkowy |
| 2 | Data zdarzenia gospodarczego | Data faktury |
| 3 | Nr dowodu księgowego | Numer faktury |
| 4 | Kontrahent — nazwa i adres | Dane vendor |
| 5 | Opis zdarzenia gospodarczego | Kategoria + opis |
| 6 | Przychód — wartość sprzedanych towarów i usług | Sprzedaż towarów |
| 7 | Przychód — pozostałe | Inne przychody |
| 8 | Razem przychód (6+7) | Suma przychodów |
| 9 | Zakup towarów handlowych i materiałów wg cen zakupu | Towary handlowe |
| 10 | Koszty uboczne zakupu | Transport, opakowania |
| 11 | Wynagrodzenia w gotówce i naturze | Pracownicy (jeśli JDG zatrudnia) |
| 12 | Pozostałe wydatki | Pozostałe KUP |
| 13 | Razem wydatki (9+10+11+12) | Suma wydatków |
| 14 | Wydatki niebędące KUP | NKUP |
| 15 | Wydatki — środki trwałe | Amortyzacja |
| 16 | Uwagi | Adnotacje |

- **Podstawa prawna:** Rozporządzenie MF w sprawie prowadzenia PKPiR (Dz.U. 2025)
- **Priorytet:** 800

#### P801: `pkpir_revenue_recognition` 🔴 [DEPRECATED]

> ⚠️ **[DEPRECATED — Doc 22 → Doc 28a]** Zastąpione przez R0372-R0399 (`28a_JDG_EDGE_CASES_FULL.md`).

- ~~**Cel biznesowy:** Moment rozpoznania przychodu w PKPiR~~
- ~~**Przesłanki:** `input.jdg_entrepreneur.uses_pkpir == true`~~
- ~~**Rezultat:** `pkpir_revenue_date: issue_date` lub `payment_date`~~
- ~~**Podstawa prawna:** § 20-21 rozporządzenia PKPiR~~
- ~~**Priorytet:** 801~~

#### P802: `pkpir_expense_recognition` 🔴 [DEPRECATED]

> ⚠️ **[DEPRECATED — Doc 22 → Doc 28a]** Zastąpione przez R0372-R0399 (`28a_JDG_EDGE_CASES_FULL.md`).

- ~~**Cel biznesowy:** Moment ujęcia kosztu w PKPiR~~
- ~~**Przesłanki:** `input.invoice.direction == "PURCHASE"` AND `input.jdg_entrepreneur.uses_pkpir == true`~~
- ~~**Rezultat:** `pkpir_expense_date: input.invoice.issue_date`~~
- ~~**Podstawa prawna:** § 20 rozporządzenia PKPiR~~
- ~~**Priorytet:** 802~~

### 3.9.2 `jdg.accounting.lump_sum_evidence` — Ewidencja ryczałtowca (P820-P829)

#### P820: `lump_sum_evidence_entry`

- **Cel biznesowy:** Ewidencja przychodów dla JDG na ryczałcie — uproszczona względem PKPiR, tylko przychody z podziałem na stawki. ★ SPECYFIKA JDG ★
- **Przesłanki:** `input.jdg_entrepreneur.tax_form == "LUMP_SUM"`
- **Rezultat:** `evidence_type: "LUMP_SUM"`, `requires_separate_rates: true` (dla każdej stawki osobna ewidencja)
- **Podstawa prawna:** Art. 15 ustawy o ryczałcie
- **Priorytet:** 820

### 3.9.3 `jdg.accounting.vat_evidence` — Ewidencja VAT (P830-P839)

#### P830: `vat_evidence_purchase`

- **Cel biznesowy:** Ewidencja VAT zakupów — obowiązkowa dla czynnych podatników VAT JDG
- **Przesłanki:** `input.jdg_entrepreneur.is_vat_payer == true` AND `input.invoice.direction == "PURCHASE"`
- **Rezultat:** `vat_register_type: "PURCHASE"`, wymagane pola: data, NIP kontrahenta, kwota netto, VAT, brutto
- **Podstawa prawna:** Art. 109 ust. 3 ustawy o VAT
- **Priorytet:** 830

#### P832: `vat_evidence_sale`

- **Cel biznesowy:** Ewidencja VAT sprzedaży
- **Przesłanki:** `input.jdg_entrepreneur.is_vat_payer == true` AND `input.invoice.direction == "SALE"`
- **Rezultat:** `vat_register_type: "SALE"`
- **Podstawa prawna:** Art. 109 ust. 3 ustawy o VAT
- **Priorytet:** 832

### 3.9.4 `jdg.accounting.depreciation` — Amortyzacja JDG (P840-P849)

#### P840: `depreciation_linear_jdg` 🔴 [DEPRECATED]

> ⚠️ **[DEPRECATED — Doc 22 → Doc 28a]** Zastąpione przez R0379-R0389 (`28a_JDG_EDGE_CASES_FULL.md` — 11 reguł amortyzacji).
> Doc 28a pokrywa: liniową, degresywną, KŚT grupy, ulepszenia, sprzedaż.

- ~~**Cel biznesowy:** Amortyzacja liniowa środków trwałych JDG~~
- ~~**Przesłanki:** `input.invoice.expense_type == "FIXED_ASSET"` AND metoda = liniowa~~
- ~~**Rezultat:** `depreciation_method: "LINEAR"`, `depreciation_rate` z KŚT~~
- ~~**Podstawa prawna:** Art. 22a-22o PIT~~
- ~~**Priorytet:** 840~~

#### P842: `depreciation_one_off_jdg` 🔴 [DEPRECATED]

> ⚠️ **[DEPRECATED — Doc 22 → Doc 28a]** Zastąpione przez R0379-R0389 (`28a_JDG_EDGE_CASES_FULL.md`).

- ~~**Cel biznesowy:** Jednorazowa amortyzacja dla małych podatników JDG~~
- ~~**Przesłanki:** `input.jdg_entrepreneur.is_small_taxpayer == true`...~~
- ~~**Rezultat:** `depreciation_method: "ONE_OFF"`, `depreciation_rate: "1.00"`~~
- ~~**Podstawa prawna:** Art. 22k ust. 7 PIT~~
- ~~**Priorytet:** 842~~

### 3.9.5 `jdg.accounting.private_mixed` — Wydatki mieszane JDG (P850-P859)

#### P850: `private_mixed_home_office`

- **Cel biznesowy:** Proporcjonalne rozliczenie wydatków na media/czynsz dla home office JDG. ★ SPECYFIKA JDG ★
- **Przesłanki:** 
  - `input.invoice.is_home_office == true`
  - `input.invoice.home_office_area_percent > 0`
- **Rezultat:** 
  - `kus_qualification: "partial"`
  - `kus_percent: input.invoice.home_office_area_percent`
  - `vat_deduction_percent: input.invoice.home_office_area_percent`
  - `_warning: "Home office — KUP i VAT proporcjonalnie do powierzchni firmowej"`
- **Podstawa prawna:** Art. 22 ust. 1 PIT, Art. 86 ust. 1 VAT (tylko w części firmowej)
- **Priorytet:** 850

#### P852: `private_mixed_car`

- **Cel biznesowy:** Rozliczenie samochodu używanego mieszanie (firmowo-prywatnie). Limit 75% KUP/VAT jeśli nie prowadzona jest ewidencja przebiegu.
- **Przesłanki:** 
  - `input.invoice.category_code == "CAR"`
  - `input.invoice.private_use_percent > 0` lub brak ewidencji przebiegu
- **Rezultat:** 
  - `kus_percent: 75` (jeśli bez ewidencji)
  - `vat_deduction_percent: 50` (standardowe ograniczenie VAT dla aut)
  - `_warning: "Samochód mieszany — ograniczenie KUP 75% / VAT 50%"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 46 PIT (75% KUP bez ewidencji), Art. 86a VAT (50% VAT)
- **Priorytet:** 852

---

## 3.10 Pakiet `jdg.business` — Cykl życia JDG (P900-P939)

### 3.10.1 `jdg.business.ceidg` — CEIDG (P900-P909)

#### P900: `ceidg_registration_check`

- **Cel biznesowy:** Weryfikacja czy JDG jest zarejestrowana w CEIDG. Każda JDG musi być wpisana do CEIDG. ★ SPECYFIKA JDG ★
- **Przesłanki:** `input.jdg_entrepreneur.ceidg_entry_date == null` (brak daty wpisu)
- **Rezultat:** `ceidg_registration_required: true`, `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 5-7 ustawy o CEIDG (Dz.U. 2025 poz. 456)
- **Priorytet:** 900

#### P902: `ceidg_data_change_notification`

- **Cel biznesowy:** Obowiązek aktualizacji danych w CEIDG w ciągu 7 dni od zmiany (adres, PKD, forma opodatkowania). ★ SPECYFIKA JDG ★
- **Przesłanki:** 
  - Zmiana danych JDG (tax_form, adres, PKD)
  - `days_since_change > 7`
  - `input.jdg_entrepreneur.ceidg_last_update_date < data zmiany`
- **Rezultat:** `ceidg_update_overdue: true`, `_routing: "TRIAGE_QUEUE"`, `_warning: "Aktualizacja CEIDG przeterminowana — obowiązek w ciągu 7 dni"`
- **Podstawa prawna:** Art. 12-15 ustawy o CEIDG
- **Priorytet:** 902

#### P904: `ceidg_vendor_verification`

- **Cel biznesowy:** Każdorazowa weryfikacja kontrahenta JDG w CEIDG przed transakcją > pewien próg.
- **Przesłanki:** `input.vendor.ceidg_status != "ACTIVE"` AND `input.invoice.amount_gross > threshold`
- **Rezultat:** `_routing: "TRIAGE_QUEUE"`, `_warning: "Kontrahent nieaktywny w CEIDG"`
- **Podstawa prawna:** Art. 88 VAT, Prawo przedsiębiorców
- **Priorytet:** 904

### 3.10.2 `jdg.business.suspension` — Zawieszenie działalności (P910-P919)

#### P910: `business_suspension_valid`

- **Cel biznesowy:** Weryfikacja skutków podatkowych zawieszenia JDG. Podczas zawieszenia: brak obowiązku opłacania zaliczek PIT, brak obowiązku składania deklaracji VAT (jeśli brak sprzedaży), można ponosić tylko stałe koszty utrzymania. ★ SPECYFIKA JDG ★
- **Przesłanki:** 
  - `input.jdg_entrepreneur.business_status == "SUSPENDED"`
  - `input.invoice.transaction_date >= input.jdg_entrepreneur.suspension_start_date`
  - `input.invoice.transaction_date <= input.jdg_entrepreneur.suspension_end_date` (lub null)
- **Rezultat:** 
  - `business_status: "SUSPENDED"`
  - `pit_advance_required: false` (brak zaliczek PIT w okresie zawieszenia)
  - `vat_declaration_required: false` (chyba że jest sprzedaż)
  - `kus_allowed: "MAINTENANCE_ONLY"` (tylko stałe koszty utrzymania)
  - `_warning: "Działalność zawieszona — ograniczone obowiązki podatkowe"`
- **Podstawa prawna:** Art. 22-25 Prawa przedsiębiorców, Art. 44 ust. 10 PIT
- **Priorytet:** 910

#### P912: `business_suspension_kup_restrictions`

- **Cel biznesowy:** Podczas zawieszenia JDG może ponosić tylko stałe koszty utrzymania firmy (czynsz, media, monitoring, raty leasingowe) — zakaz nowych wydatków operacyjnych. ★ SPECYFIKA JDG ★
- **Przesłanki:** 
  - `input.jdg_entrepreneur.business_status == "SUSPENDED"`
  - `input.invoice.expense_type not in ["RENT", "UTILITIES", "SECURITY", "LEASE_EXISTING", "INSURANCE", "ACCOUNTING"]`
- **Rezultat:** `kus_qualification: "none"`, `_routing: "BLOCK_AND_ALERT"`, `_warning: "Wydatek niedozwolony w okresie zawieszenia"`
- **Podstawa prawna:** Art. 22-25 Prawa przedsiębiorców
- **Priorytet:** 912

#### P914: `business_suspension_zus` 🔴 [DEPRECATED]

> ⚠️ **[DEPRECATED — Doc 22 → Doc 28a]** Zastąpione przez R0582 `edge_zus_declaration_zero_on_suspension` (`28a_JDG_EDGE_CASES_FULL.md` Grupa F).
> **P914 był BŁĘDNY** (twierdził, że zdrowotna=0 podczas zawieszenia). R0582 jest poprawna: zdrowotna NADAL należna.
> Poprawka wdrożona w `policies/jdg/business.rego`: `zus_health_due: true`, `zus_health_rate` delegowane do pakietu ZUS przez `object.union`.

- ~~**Cel biznesowy:** Podczas zawieszenia JDG: brak obowiązku opłacania składek ZUS społecznych.~~
- ~~**Przesłanki:** `input.jdg_entrepreneur.business_status == "SUSPENDED"`~~
- ~~**Rezultat:** `zus_social_due: false`, `zus_health_due: true` **(poprawione!)**, `zus_health_rate: <z pakietu zus>`~~
- ~~**Podstawa prawna:** Art. 36a ustawy o SUS (społeczne=0, ALE zdrowotna NADAL należna)~~
- ~~**Priorytet:** 914~~

### 3.10.3 `jdg.business.succession` — Sukcesja (P920-P929)

#### P920: `succession_continuity`

- **Cel biznesowy:** Po śmierci przedsiębiorcy JDG — zarządca sukcesyjny kontynuuje działalność pod dotychczasowym NIP (z dopiskiem "w spadku"). ★ SPECYFIKA JDG ★
- **Przesłanki:** 
  - `input.jdg_entrepreneur.in_succession == true`
  - `input.jdg_entrepreneur.succession_manager_nip != null`
- **Rezultat:** 
  - `business_status: "IN_SUCCESSIO"`
  - `nip_status: "DECEASED_IN_SUCCESSIO"`
  - `succession_manager_active: true`
  - `_warning: "Działalność w zarządzie sukcesyjnym — NIP zmarłego przedsiębiorcy"`
- **Podstawa prawna:** Ustawa o zarządzie sukcesyjnym (Dz.U. 2025 poz. 1234)
- **Priorytet:** 920

#### P922: `succession_tax_obligations`

- **Cel biznesowy:** Zarządca sukcesyjny odpowiada za bieżące zobowiązania podatkowe JDG. Kontynuacja formy opodatkowania, zaliczek, deklaracji. ★ SPECYFIKA JDG ★
- **Przesłanki:** `input.jdg_entrepreneur.in_succession == true`
- **Rezultat:** 
  - `tax_obligations_continue: true`
  - `pit_form_unchanged: true` (kontynuacja formy opodatkowania)
  - `responsible_party: "SUCCESSION_MANAGER"`
- **Podstawa prawna:** Art. 3-15 ustawy o zarządzie sukcesyjnym
- **Priorytet:** 922

#### P924: `succession_vat_continuity`

- **Cel biznesowy:** Kontynuacja statusu VAT po śmierci przedsiębiorcy — zarządca sukcesyjny kontynuuje jako podatnik VAT
- **Przesłanki:** 
  - `input.jdg_entrepreneur.in_succession == true`
  - `input.jdg_entrepreneur.is_vat_payer == true`
- **Rezultat:** `vat_status_continues: true`, `vat_declarations_required: true`
- **Podstawa prawna:** Art. 12-14 ustawy o zarządzie sukcesyjnym, Art. 96-97 VAT
- **Priorytet:** 924

### 3.10.4 `jdg.business.unregistered` — Działalność nieewidencjonowana (P930-P939)

#### P930: `unregistered_activity_limit`

- **Cel biznesowy:** Limit działalności nieewidencjonowanej — przychód ≤ 50% minimalnego wynagrodzenia miesięcznie. Po przekroczeniu → obowiązek rejestracji CEIDG w ciągu 7 dni. ★ SPECYFIKA JDG ★
- **Przesłanki:** 
  - `input.jdg_entrepreneur.is_unregistered_activity == true`
  - `input.jdg_entrepreneur.monthly_revenue_current > input.thresholds.jdg.bounds.unregistered_activity_limit_percent * input.thresholds.jdg.bounds.minimum_wage_gross`
- **Rezultat:** 
  - `unregistered_activity_limit_exceeded: true`
  - `ceidg_registration_required: true`
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Przekroczony limit działalności nieewidencjonowanej — wymagana rejestracja CEIDG w ciągu 7 dni"`
- **Podstawa prawna:** Art. 5 Prawa przedsiębiorców
- **Priorytet:** 930

#### P932: `unregistered_activity_zus_exemption`

- **Cel biznesowy:** Działalność nieewidencjonowana jest zwolniona z ZUS. ★ SPECYFIKA JDG ★
- **Przesłanki:** `input.jdg_entrepreneur.is_unregistered_activity == true`
- **Rezultat:** 
  - `zus_social_due: false`
  - `zus_health_due: false`
- **Podstawa prawna:** Art. 5 Prawa przedsiębiorców
- **Priorytet:** 932

#### P934: `unregistered_activity_taxation`

- **Cel biznesowy:** Działalność nieewidencjonowana — opodatkowanie na zasadach ogólnych (skala PIT), bez PKPiR (uproszczona ewidencja)
- **Przesłanki:** `input.jdg_entrepreneur.is_unregistered_activity == true`
- **Rezultat:** 
  - `pit_form: "SCALE"` (automatycznie skala)
  - `requires_pkpir: false`
  - `requires_evidence: "SIMPLIFIED"`
- **Podstawa prawna:** Art. 5 Prawa przedsiębiorców, Art. 20 PIT
- **Priorytet:** 934

---

## 3.11 Pakiet `jdg.ksef` — KSeF (P950-P969)

#### P950: `ksef_structured_mandatory_jdg`

- **Cel biznesowy:** Obowiązek wystawiania faktur ustrukturyzowanych przez KSeF od 1 lutego 2026 r. Dla JDG będących czynnymi podatnikami VAT. ★ ISTOTNE DLA JDG ★
- **Przesłanki:** 
  - `input.invoice.transaction_date >= "2026-02-01"`
  - `input.jdg_entrepreneur.is_vat_payer == true`
  - `input.invoice.direction == "SALE"`
- **Rezultat:** `ksef_required: true`, `_warning: "Faktura sprzedaży musi być wystawiona przez KSeF"`
- **Podstawa prawna:** Art. 106na-106nq ustawy o VAT
- **Priorytet:** 950

#### P952: `ksef_b2c_exemption_jdg`

- **Cel biznesowy:** JDG nie musi wystawiać faktur KSeF dla konsumentów (B2C). ★ WAŻNE DLA JDG ★
- **Przesłanki:** 
  - `input.vendor.is_b2c == true`
  - `input.invoice.direction == "SALE"`
- **Rezultat:** `ksef_required: false`, `ksef_exemption: "B2C"`
- **Podstawa prawna:** Art. 106ga ust. 2 pkt 4 VAT
- **Priorytet:** 952

#### P960: `ksef_offline_recovery`

- **Cel biznesowy:** Tryb awaryjny KSeF — 7 dni na przesłanie faktur po awarii
- **Przesłanki:** `input.system.ksef_status == "OFFLINE"`
- **Rezultat:** `ksef_submission_deadline_days: 7`
- **Podstawa prawna:** Art. 106ne VAT
- **Priorytet:** 960

---

## 3.12 Pakiet `jdg.jpk` — JPK (P970-P989)

#### P970: `jpk_v7m_structure_jdg`

- **Cel biznesowy:** Obowiązek składania JPK_V7M (miesięczny) lub JPK_V7K (kwartalny) dla JDG będących czynnymi podatnikami VAT
- **Przesłanki:** `input.jdg_entrepreneur.is_vat_payer == true`
- **Rezultat:** `jpk_v7_required: true`, `jpk_frequency: "MONTHLY"` lub `"QUARTERLY"`
- **Podstawa prawna:** Art. 99 ustawy o VAT, rozporządzenie JPK_VAT
- **Priorytet:** 970

#### P980: `jpk_pkpir_structure_jdg`

- **Cel biznesowy:** Obowiązek przekazywania JPK_PKPIR dla JDG prowadzących PKPiR (na żądanie US lub cyklicznie)
- **Przesłanki:** `input.jdg_entrepreneur.uses_pkpir == true`
- **Rezultat:** `jpk_pkpir_applicable: true`
- **Podstawa prawna:** Art. 193a Ordynacji podatkowej
- **Priorytet:** 980

---

## 3.13 Pakiet `jdg.retention` — Przechowywanie dokumentów (P990-P999)

#### P990: `retention_invoice_5y`

- **Cel biznesowy:** Obowiązek przechowywania faktur przez 5 lat od końca roku podatkowego
- **Przesłanki:** `input.invoice.direction == "PURCHASE"`
- **Rezultat:** `retention_years: 5`
- **Podstawa prawna:** Art. 86 § 1 Ordynacji podatkowej, Art. 74 UoR
- **Priorytet:** 990

#### P992: `retention_pkpir_5y`

- **Cel biznesowy:** PKPiR musi być przechowywana przez 5 lat
- **Przesłanki:** `input.jdg_entrepreneur.uses_pkpir == true`
- **Rezultat:** `retention_years: 5`, `retention_type: "PKPIR"`
- **Podstawa prawna:** Art. 86 § 1 Ordynacji podatkowej
- **Priorytet:** 992

---

## 3.14 Pakiet `jdg.fallback` — Reguły domyślne (P1000-P1099)

#### P1000: `domestic_fallback_jdg`

- **Cel biznesowy:** Domyślna stawka VAT 23% dla Polski — gdy żadna konkretna reguła VAT nie pasuje
- **Przesłanki:** `input.vendor.country == "PL"` AND żadna reguła VAT nie dopasowana
- **Rezultat:** `vat_rate: "0.23"`, `rounding_level: "position"`
- **Podstawa prawna:** Art. 41 ust. 1 VAT
- **Priorytet:** 1000

#### P1099: `no_match_jdg`

- **Cel biznesowy:** Ostateczny fallback — brak dopasowania jakiejkolwiek reguły
- **Przesłanki:** Żadna reguła nie pasuje (always last via `default decide`)
- **Rezultat:** `matched: false`, `error: "JDG_NO_MATCHING_RULE"`, `_routing: "TRIAGE_QUEUE"`
- **Priorytet:** 1099

---

## 4. Hierarchia i Priorytety — Mechanizm First-Match-Wins JDG

### 4.1 Struktura pliku `main_jdg.rego`

```rego
package jdg

import data.jdg.risk
import data.jdg.routing
import data.jdg.compliance.whitelist
import data.jdg.compliance.mpp
import data.jdg.compliance.cash_limit
import data.jdg.crossborder
import data.jdg.business.ceidg
import data.jdg.business.suspension
import data.jdg.business.succession
import data.jdg.business.unregistered
import data.jdg.vat.substantive
import data.jdg.vat.gtu
import data.jdg.vat.exemptions
import data.jdg.vat.tax_point
import data.jdg.vat.deduction
import data.jdg.pit.form_scale
import data.jdg.pit.form_linear
import data.jdg.pit.form_lump_sum
import data.jdg.pit.form_tax_card
import data.jdg.pit.advances
import data.jdg.pit.kup
import data.jdg.pit.exemptions
import data.jdg.allowances.rd
import data.jdg.allowances.ip_box
import data.jdg.zus.social
import data.jdg.zus.health
import data.jdg.zus.start_relief
import data.jdg.zus.maly_plus
import data.jdg.zus.preferential
import data.jdg.accounting.pkpir
import data.jdg.accounting.lump_sum_evidence
import data.jdg.accounting.vat_evidence
import data.jdg.accounting.depreciation
import data.jdg.accounting.private_mixed
import data.jdg.ksef.structured_invoice
import data.jdg.ksef.offline_recovery
import data.jdg.jpk.jpk_vat
import data.jdg.jpk.jpk_pkpir
import data.jdg.retention
import data.jdg.fallback

default decide := {
    "matched": false,
    "rule_id": "jdg.fallback.no_match",
    "package": "jdg.fallback",
    "priority": 1099,
    "error": "JDG_NO_MATCHING_RULE"
}
```

### 4.2 Flow pierwszeństwa JDG

```
P0-P9    risk          → BLOCK_AND_ALERT (fraud, anomalie, CEIDG zawieszony)
P10-P19  routing       → BLOCK_AND_ALERT / TRIAGE_QUEUE (field confidence)
P20-P39  compliance    → BLOCK / MPP / ostrzeżenia
P40-P49  crossborder   → Procedura specjalna VAT
P900-P939 business     → Status JDG (weryfikacja CEIDG, zawieszenie, sukcesja, nieewid.)
P50-P69  vat.*         → Stawki VAT + GTU + zwolnienia
P500-P589 pit.*        → Forma PIT + KUP + zaliczki + zwolnienia
P600-P628 allowances.* → Ulgi podatkowe
P700-P742 zus.*        → Składki ZUS + ulgi składkowe
P800-P859 accounting.* → PKPiR + ewidencje + amortyzacja + wydatki mieszane
P950-P969 ksef.*       → KSeF
P970-P989 jpk.*        → JPK
P990-P999 retention    → Przechowywanie dokumentów
P1000+    fallback     → Domyślne
```

---

## 5. Wymagane Dane Wejściowe — Podsumowanie

### 5.1 Pola absolutnie wymagane (bez nich OPA nie może podjąć decyzji)

```rego
jdg_required_fields := [
    "invoice.transaction_date",
    "invoice.category_code",
    "invoice.amount_net",
    "invoice.direction",
    "vendor.country",
    "vendor.nip",
    "jdg_entrepreneur.tax_form",
    "jdg_entrepreneur.is_vat_payer",
    "jdg_entrepreneur.business_status",
    "confidence.fc_minimum"
]
```

### 5.2 Wartości dozwolone — kluczowe enumy JDG

| Pole | Dozwolone wartości |
|---|---|
| `jdg_entrepreneur.tax_form` | `"PIT_SCALE"`, `"LINEAR"`, `"LUMP_SUM"`, `"TAX_CARD"` |
| `jdg_entrepreneur.business_status` | `"ACTIVE"`, `"SUSPENDED"`, `"CLOSED"`, `"IN_SUCCESSIO"` |
| `jdg_entrepreneur.zus_status` | `"STANDARD"`, `"PREFERENTIAL"`, `"MALY_ZUS_PLUS"`, `"START_RELIEF"` |
| `vendor.ceidg_status` | `"ACTIVE"`, `"SUSPENDED"`, `"CLOSED"`, `"UNKNOWN"` |

---

## 6. Sposób Obsługi Parametrów Dynamicznych JDG

### 6.1 Tabela thresholdów JDG w DuckDB

```sql
CREATE TABLE IF NOT EXISTS jdg_thresholds (
    threshold_key   VARCHAR PRIMARY KEY,
    threshold_value VARCHAR NOT NULL,
    valid_from      DATE NOT NULL DEFAULT '2024-01-01',
    valid_to        DATE,
    description     VARCHAR,
    legal_basis     VARCHAR,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 6.2 Obsługa zmiany formy opodatkowania w trakcie roku

Dla JDG zmiana formy opodatkowania jest możliwa tylko od nowego roku (z wyjątkiem przejścia z karty podatkowej na ryczałt). Reguły OPA uwzględniają pole `jdg_entrepreneur.tax_form_change_date` — jeśli zmiana nastąpiła w trakcie roku, reguły sprzed daty zmiany używają starej formy.

### 6.3 Mechanizm hot-reload dla JDG

```
Zmiana przepisów (np. nowa stawka ryczałtu)
    │
    ▼
DuckDB: INSERT/UPDATE jdg_thresholds (z nowym valid_from)
    │
    ▼
NATS: Publikuj jdg.thresholds.updated
    │
    ▼
HotReloadListener: Odśwież cache OPA
    │
    ▼
OPA: Następna ewaluacja używa nowych wartości
    │
    ▼
ZERO zmian w kodzie Rego ✓
```

---

## 7. Podsumowanie — Statystyki Planu JDG

| Metryka | Wartość |
|---|---|
| **Pakiety JDG** | 23 |
| **Reguły łącznie** | ~145 |
| **Reguły JDG-specyficzne (★ NOWE)** | ~45 |
| **Reguły adaptowane z planu ogólnego** | ~70 |
| **Reguły uniwersalne (bez zmian)** | ~30 |
| **Domeny prawne pokryte** | 30+ |
| **Podstawy prawne** | 70+ cytowanych artykułów |
| **Pola input JDG** | ~80 (w tym ~30 nowych vs plan ogólny) |
| **Parametry dynamiczne (thresholds.jdg.*)** | ~65 |

### Kluczowe różnice vs plan ogólny (CIT)

| Aspekt | Plan ogólny (CIT) | Plan JDG |
|---|---|---|
| **Formy opodatkowania** | CIT 19%/9%/estoński | PIT skala/liniowy/ryczałt/karta |
| **Księgowość** | Pełna UoR | PKPiR + ewidencje uproszczone |
| **Składki ZUS** | Pracownicze | Przedsiębiorcy (ulga na start, Mały ZUS+, preferencyjny) |
| **Składka zdrowotna** | 9% standard | 9% (skala) / 4.9% (liniowy) / progi (ryczałt) |
| **KUP — specyfika** | Standardowe | + wydatki mieszane, home office, samochód prywatno-firmowy |
| **Rejestracja** | KRS | CEIDG |
| **Sukcesja** | Spadkobiercy spółki | Zarządca sukcesyjny JDG |
| **Zawieszenie** | Rzadkie | Częste — specyficzne skutki podatkowe i ZUS |
| **Dział. nieewidencjonowana** | Nie dotyczy | Art. 5 PP — do 50% minimalnego |
| **Zeznania roczne** | CIT-8 | PIT-36 / PIT-36L / PIT-28 (różne terminy!) |
| **Zaliczki** | CIT miesięczne/kwartalne | PIT miesięczne/kwartalne + uproszczone |

---

## 8. Plan Implementacji JDG

### Fazy wdrożenia

| Faza | Zakres | Pliki Rego | Testy |
|---|---|---|---|
| **Faza 0** | Fundament: helpers, metadata, struktura main_jdg.rego | `_helpers_jdg.rego`, `_metadata_jdg.rego`, `main_jdg.rego` | — |
| **Faza 1** | Risk + Routing + Compliance | `risk.rego`, `routing.rego`, `compliance/*.rego` | `risk_test.rego`, `routing_test.rego` |
| **Faza 2** | Crossborder + VAT | `crossborder.rego`, `vat/*.rego` | `vat_test.rego` |
| **Faza 3** | PIT (formy + KUP + zaliczki) | `pit/*.rego` | `pit_test.rego` |
| **Faza 4** | ZUS + Ulgi | `zus/*.rego`, `allowances/*.rego` | `zus_test.rego` |
| **Faza 5** | Accounting JDG (PKPiR, ewidencje, wydatki mieszane) | `accounting/*.rego` | `accounting_test.rego` |
| **Faza 6** | Business (CEIDG, zawieszenie, sukcesja, nieewidencjonowana) | `business/*.rego` | `business_test.rego` |
| **Faza 7** | KSeF + JPK + Retention + Fallback | `ksef/*.rego`, `jpk/*.rego`, `retention.rego`, `fallback.rego` | `integration_test.rego` |

---

> **Następny krok:** Implementacja Fazy 0 — stworzenie plików `_helpers_jdg.rego` i `main_jdg.rego` w `policies/jdg/`.  
> **Powiązane dokumenty:** `Plan OPA/00_PLAN_STRUKTURA.md` (plan ogólny), `Plan OPA/01_INPUT_SPEC.md` (specyfikacja input), `Plan OPA/02_THRESHOLDS_CATALOG.md` (katalog thresholdów), `Plan OPA/DocsJDG` (źródła prawne JDG), `Plan OPA/23_JDG_EXPANSION_SUPPLEMENT.md` (rozbudowa 10 obszarów), `Plan OPA/24_JDG_COMPLETE_INDEX.md` (kompletny indeks reguł)
