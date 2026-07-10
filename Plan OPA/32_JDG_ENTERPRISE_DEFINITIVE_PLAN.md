# 🏛️ NexusAI JDG — Definitywny Plan Reguł OPA/Rego ENTERPRISE v9.0

> **Status:** DEFINITYWNY plan systemu reguł OPA dla JDG — synteza dokumentów 22-31 + nowe obszary
> **Data:** 2026-07-10
> **Autor:** Zespół NexusAI
> **Plik:** `Plan OPA/32_JDG_ENTERPRISE_DEFINITIVE_PLAN.md`

**Dokumenty źródłowe (syntetyzowane):**
— `Plan OPA/22_JDG_ENTERPRISE_PLAN.md` — plan bazowy (~145 reguł)
— `Plan OPA/23_JDG_EXPANSION_SUPPLEMENT.md` — rozbudowa 10 obszarów (~69 reguł)
— `Plan OPA/24_JDG_COMPLETE_INDEX.md` — kompletny indeks (~214 reguł)
— `Plan OPA/25_JDG_DEEP_LEGAL_AUDIT.md` — audyt prawny (46 luk)
— `Plan OPA/26_JDG_COMPREHENSIVE_EXPANSION.md` — kompleksowa rozbudowa (~272 reguł)
— `Plan OPA/27_JDG_ENTERPRISE_DEEP_EXPANSION.md` — głęboka ekspansja (~327 reguł)
— `Plan OPA/28_JDG_ENTERPRISE_MASTER_SYNTHESIS.md` — master synthesis (~372 reguł)
— `Plan OPA/29_JDG_DEEP_ANALYSIS_GAPS.md` — deep gap analysis (+30 reguł, ~402)
— `Plan OPA/30_JDG_MASSIVE_EXPANSION.md` — masywna dekompozycja (~1 462 reguł)
— `Plan OPA/31_JDG_3000_RULES.md` — kompletny system 3 000+ reguł
— `Plan OPA/DocsJDG` — źródła prawne JDG (~230 artykułów, ~1 150 punktów prawnych)
— `Plan OPA/Docs/` — wzorce reguł i dokumenty analityczne (00-21)
— `policies/tax/*.rego` — istniejące implementacje Rego (22 pliki)

**Cel dokumentu:** Niniejszy dokument jest DEFINITYWNĄ syntezą wszystkich poprzednich planów JDG. Konsoliduje ~3 000+ reguł z dokumentów 22-31 w jeden spójny, gotowy do wdrożenia plan ENTERPRISE, dodaje **~56 nowych reguł** w 8 nowych obszarach niepokrytych wcześniej (kryptoaktywa, CESOP, ViDA, UK post-Brexit, e-learning, gig economy, AI Act, API graceful degradation, audit automation, conflict resolution, zbiegi specjalne), prezentuje zunifikowany łańcuch first-match-wins, kompletną strukturę `input`, katalog ~200 parametrów dynamicznych, oraz przewodnik wdrożeniowy ENTERPRISE.

**Łącznie po tym dokumencie:** ~3 080 reguł | 50 pakietów | 100+ domen prawnych | 300+ podstaw prawnych

> **Uwaga:** Dokument 28 wprowadził koncepcje MDR/ESG/AI Act (P1800-P1822). Niniejszy dokument rozwija je w implementacyjne reguły szczegółowe — są to rozbudowy, nie całkowicie nowe obszary. Reguły P1880-P1884 (Polski Ład) zostały skonsolidowane z istniejącymi regułami P738 i P847 — nie powielają ich, lecz grupują pod kątem spójności Polski Ład.

---

## Spis Treści

1. [Filozofia Projektowa i Architektura](#1-filozofia-projektowa-i-architektura)
2. [Podział na Pakiety](#2-podział-na-pakiety)
3. [Hierarchia i Priorytety Reguł](#3-hierarchia-i-priorytety-reguł)
4. [Szczegółowy Opis Reguł per Pakiet](#4-szczegółowy-opis-reguł-per-pakiet)
5. [Nowe Obszary ENTERPRISE (~56 reguł)](#5-nowe-obszary-enterprise)
6. [Wymagane Dane Wejściowe](#6-wymagane-dane-wejściowe)
7. [Obsługa Parametrów Dynamicznych](#7-obsługa-parametrów-dynamicznych)
8. [Macierze Interakcji Międzyregulacyjnych](#8-macierze-interakcji)
9. [Plan Wdrożenia ENTERPRISE](#9-plan-wdrożenia)

---

## 1. Filozofia Projektowa i Architektura

### 1.1 Fundamenty Architektoniczne — JDG ENTERPRISE

| Zasada | Opis | Implementacja JDG |
|--------|------|-------------------|
| **First-Match-Wins** | Pierwsza pasująca reguła wygrywa wewnątrz każdego pakietu — deterministyczna kolejność | Rego `else` chain w każdym pliku `.rego` |
| **Multi-Pass Evaluation** | Różne domeny (VAT, PIT, ZUS, Accounting) ewaluowane niezależnie, werdykty scalane | `MultiPassOpaEvaluator` — 9 passów OPA (ADR-001) |
| **Zero Hardcoded Values** | Żadna liczba (stawka, próg, limit) nie jest zakodowana w `.rego` | Wszystko przez `input.thresholds.jdg.*` |
| **Temporalność** | Reguły obowiązują od-do; parametry zależne od daty transakcji | `valid_from` / `valid_to` w DuckDB thresholds |
| **Audytowalność** | Każda decyzja ma ślad: reguła, powód, podstawa prawna | `rule_id`, `_legal_basis` w werdykcie |
| **JDG-First Design** | Wszystkie reguły projektowane od podstaw pod JDG, nie jako fork CIT | Osobne pakiety `jdg.*`, dedykowany `input.jdg_entrepreneur` |
| **Graceful Degradation** | Awaria API zewnętrznego → fallback, nie crash | `whitelist_check_expired` → warning, nie block |
| **Time-Travel** | Ewaluacja reguł wg stanu prawnego z daty historycznej | `input.document.evaluation_date` + DuckDB historyczne thresholds |

### 1.2 Architektura Multi-Pass (ADR-001)

System używa **9 niezależnych ewaluacji OPA**, z których każda odpowiada za inną domenę. Werdykty są scalane przez `VerdictMerger`:

```
                    ┌─────────────────────────────────────────────┐
                    │         OPA MULTI-PASS EVALUATION ENGINE       │
                    │                                                │
  input ──────────► │  PASS 0: RISK (fraud/anomaly)               ──► risk_verdict
                    │         ↓ (if BLOCK → abort)                   │
                    │  PASS 1: ROUTING (confidence)                ──► routing_verdict
                    │         ↓ (if BLOCK → abort)                   │
                    │  PASS 2: COMPLIANCE (whitelist/MPP)          ──► compliance_verdict
                    │         ↓                                      │
                    │  PASS 3: CROSSBORDER (EU/non-EU/OSS)        ──► crossborder_verdict
                    │         ↓                                      │
                    │  PASS 4: VAT (+ GTU + tax_point + deduction) ──► vat_verdict
                    │         ↓                                      │
                    │  PASS 5: PIT (form + KUP + advances + reliefs)──► pit_verdict
                    │         ↓                                      │
                    │  PASS 6: ALLOWANCES (ulgi podatkowe)         ──► allowances_verdict
                    │         ↓                                      │
                    │  PASS 7: ACCOUNTING (PKPiR + depreciation)   ──► accounting_verdict
                    │         ↓                                      │
                    │  PASS 8: ZUS + BUSINESS + KSeF + JPK         ──► misc_verdict
                    │         ↓                                      │
                    │  VERDICT MERGER                               ──► final_verdict
                    └─────────────────────────────────────────────┘
```

### 1.3 Konwencja Nazewnicza Werdyktu JDG

Każda reguła zwraca ustandaryzowany obiekt:

```json
{
    "matched": true,
    "rule_id": "jdg.vat.substantive.fuel_pl",
    "package": "jdg.vat.substantive",
    "priority": 52,

    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "GTU_04",
    "procedure": "",
    "vat_exemption": "",

    "pit_form": "SCALE",
    "pit_rate": "0.12",
    "pit_bracket": "LOW",
    "pit_advance_frequency": "MONTHLY",
    "pit_annual_return_type": "PIT-36",

    "kus_qualification": "full",
    "kus_percent": 100,
    "pkpir_column": 12,

    "zus_social_base_type": "STANDARD",
    "zus_health_rate": "0.09",
    "zus_health_deductible_from_tax": false,

    "business_status": "ACTIVE",
    "ceidg_registration_required": false,

    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 1 ustawy o VAT",
    "_warnings": []
}
```

---

## 2. Podział na Pakiety

### 2.1 Finalna Architektura Pakietów (50 pakietów)

```
policies/jdg/
├── main_jdg.rego                              # Główny else-chain — importuje wszystkie pakiety
├── _helpers_jdg.rego                          # Funkcje pomocnicze JDG
├── _metadata_jdg.rego                         # Metadane wszystkich reguł JDG
│
├── risk.rego                                  # P0-P9:    Fraud, anomalie, KKS, GAAR
├── routing.rego                               # P10-P19:  Field confidence per forma opodatkowania
│
├── compliance/
│   ├── whitelist.rego                         # P20-P22:  Biała Lista MF, ZAW-NR
│   ├── mpp.rego                               # P25:      Split payment (mechanizm podzielonej płatności)
│   ├── cash_limit.rego                        # P35-P36:  Limit płatności gotówkowych, paragony
│   ├── ksef_compliance.rego                   # P37:      KSeF compliance checks
│   ├── cash_register.rego                     # P145-P146: Kasy fiskalne i wirtualne
│   ├── excise.rego                            # P153-P154: Akcyza (auta, alkohol)
│   └── bdo_environment.rego                   # P1400-P1407: BDO, KOBiZE
│
├── crossborder.rego                           # P40-P49:  WNT, WDT, import, eksport, trójstronne
│
├── vat/
│   ├── substantive.rego                       # P50-P65:  Stawki VAT, zwolnienia, GTU
│   ├── gtu.rego                               # P65a-P65m: Mapowanie GTU (13 kodów)
│   ├── exemptions.rego                        # P55-P63:  Zwolnienia podmiotowe i przedmiotowe
│   ├── tax_point.rego                         # P230-P235: Moment powstania obowiązku podatkowego
│   ├── deduction.rego                         # P183-P192: Odliczenia VAT (proporcja, korekty, auta)
│   ├── declarations.rego                      # P232-P234: VAT-UE, VAT-Z, terminy płatności
│   ├── oss.rego                               # P66-P69:  OSS/IOSS/WSTO
│   ├── margin_tourism.rego                    # P64:      VAT-marża turystyka
│   └── farmer_rr.rego                         # P152:     VAT RR — rolnik ryczałtowy
│
├── pit/
│   ├── form_scale.rego                        # P500-P509:  Skala podatkowa 12%/32%
│   ├── form_linear.rego                       # P510-P519:  Podatek liniowy 19%
│   ├── form_lump_sum.rego                     # P520-P529:  Ryczałt ewidencjonowany
│   ├── form_tax_card.rego                     # P530-P539:  Karta podatkowa
│   ├── tax_form_change.rego                   # P590-P599:  Zmiana formy opodatkowania
│   ├── advances.rego                          # P540-P549:  Zaliczki na PIT
│   ├── annual_returns.rego                    # P550-P559:  Zeznania roczne (PIT-36/36L/28)
│   ├── kup.rego                               # P560-P582:  Koszty uzyskania przychodu JDG
│   ├── exemptions.rego                        # P580-P588:  Zwolnienia PIT (młodzi, powrót, 4+, senior)
│   ├── payer_obligations.rego                 # P590b-P599b: Obowiązki płatnika JDG
│   └── crypto_assets.rego                     # P630-P635:  Kryptoaktywa — NOWY OBSZAR ★
│
├── wht/
│   └── main.rego                              # P100-P109: Withholding Tax
│
├── international/
│   ├── permanent_establishment.rego           # P110-P113: Zakład (PE)
│   └── transfer_pricing.rego                  # P114-P117: Ceny transferowe, safe harbour
│
├── employer/
│   ├── payroll.rego                           # P1200e-P1208e: Wynagrodzenia, PIT-4R, PIT-11
│   ├── civil_contracts.rego                   # P1210e-P1212e: Umowy cywilnoprawne
│   └── copyright_kup.rego                     # P1220-P1223: 50% KUP prawa autorskie
│
├── allowances/
│   ├── rd.rego                                # P600-P619:    Ulga B+R (12 mikro-reguł)
│   ├── ip_box.rego                            # P610-P619:    IP Box 5%
│   ├── prototype.rego                         # P601:         Ulga na prototyp
│   ├── robotization.rego                      # P602:         Ulga na robotyzację
│   ├── expansion.rego                         # P603:         Ulga na ekspansję
│   ├── rehabilitation.rego                    # P604:         Ulga rehabilitacyjna
│   ├── internet.rego                          # P605:         Ulga internetowa
│   ├── donation.rego                          # P606-P608:    Darowizny (OPP, krew, kościół)
│   ├── abolition.rego                         # P609:         Ulga abolicyjna
│   ├── thermo.rego                            # P623:         Ulga termomodernizacyjna
│   └── joint_limits.rego                      # P616:         Łączne limity ulg
│
├── zus/
│   ├── social.rego                            # P700-P701:    Składki społeczne JDG
│   ├── health.rego                            # P720-P724:    Składka zdrowotna (4 formy)
│   ├── interactions.rego                      # P730-P738:    Interakcje forma↔składki
│   ├── start_relief.rego                      # P740:         Ulga na start (6 mies.)
│   ├── maly_zus_plus.rego                     # P741:         Mały ZUS Plus (36 mies.)
│   ├── preferential.rego                      # P742:         Preferencyjny ZUS (24 mies.)
│   ├── payment_deadlines.rego                 # P745-P748:    Terminy ZUS, DRA
│   └── benefits.rego                          # P760-P770:    Zasiłki (chorobowy, macierzyński) ★ NOWY
│
├── accounting/
│   ├── pkpir.rego                             # P800-P805:    PKPiR (16 kolumn)
│   ├── lump_sum_evidence.rego                 # P820:         Ewidencja ryczałtowca
│   ├── vat_evidence.rego                      # P830-P832:    Ewidencja VAT
│   ├── depreciation.rego                      # P840-P847:    Amortyzacja (liniowa, jednorazowa, EV)
│   ├── private_mixed.rego                     # P850-P852:    Wydatki mieszane (home office, auto)
│   ├── leasing.rego                           # P860-P868:    Leasing operacyjny/finansowy
│   ├── fx_differences.rego                    # P870:         Różnice kursowe
│   └── real_estate.rego                       # P147-P150:    Nieruchomości w JDG ★ NOWY
│
├── business/
│   ├── ceidg.rego                             # P900-P906:    CEIDG rejestracja i zmiany
│   ├── suspension.rego                        # P910-P919:    Zawieszenie działalności
│   ├── succession.rego                        # P920-P929:    Sukcesja po śmierci
│   ├── unregistered.rego                      # P930-P939:    Działalność nieewidencjonowana
│   └── restructuring.rego                     # P843-P845, P1500-P1505: Restrukturyzacja
│
├── corrections/
│   └── main.rego                              # P1100-P1120: Korekty faktur, deklaracji, JPK
│
├── statute_liability/
│   └── main.rego                              # P1150-P1174: Przedawnienia, odpowiedzialność, odsetki
│
├── representation/
│   └── main.rego                              # P1200-P1212: Pełnomocnictwa PPS-1, UPL-1, prokura
│
├── local_taxes/
│   ├── pcc.rego                               # P1300-P1304: PCC
│   ├── real_estate.rego                       # P1310-P1312: Podatek od nieruchomości
│   └── transport.rego                         # P1320:       Podatek od środków transportowych
│
├── ksef/
│   ├── structured_invoice.rego                # P950-P955:   Faktury ustrukturyzowane KSeF
│   └── offline_recovery.rego                  # P960:        Tryb awaryjny KSeF
│
├── jpk/
│   ├── jpk_vat.rego                           # P970-P975:   JPK_V7M/K
│   └── jpk_pkpir.rego                         # P980:        JPK_PKPIR
│
├── temporal/
│   ├── rmk.rego                               # P1600-P1604: Rozliczenia międzyokresowe
│   └── time_travel.rego                       # P1610-P1612: Time-Travel OPA
│
├── platform_digital/                          # ★ NOWY PAKIET
│   ├── app_store_export.rego                  # P143-P144:   App Store, Google Play, Upwork
│   ├── dac7_reporting.rego                    # P142:        DAC7 — raportowanie platform
│   └── cesop_compliance.rego                  # P155-P157:   CESOP — NOWY OBSZAR ★
│
├── inheritance_estate/                        # ★ NOWY PAKIET
│   ├── inheritance_tax.rego                   # P930a-P931a: Spadek JDG, zwolnienie
│   └── family_foundation.rego                 # P1731-P1732: Fundacja Rodzinna
│
├── crypto_digital_assets/                     # ★ NOWY PAKIET
│   └── main.rego                              # P630-P635:   Kryptoaktywa, NFT, staking ★ NOWY
│
├── ai_act_compliance/                         # ★ NOWY PAKIET
│   └── main.rego                              # P1820-P1822: AI Act dla JDG IT ★ NOWY
│
├── mdr_reporting/                             # ★ NOWY PAKIET
│   └── main.rego                              # P1800-P1803: MDR — Mandatory Disclosure Rules ★ NOWY
│
├── retention.rego                             # P990-P992:   Przechowywanie dokumentów
└── fallback.rego                              # P1000-P1099: Reguły domyślne JDG
```

### 2.2 Macierz Priorytetów — Zunifikowana

| Zakres | Pakiet | Odpowiedzialność | Skutek dopasowania |
|--------|--------|-------------------|-------------------|
| **P0-P9** | `jdg.risk` | Fraud, anomalie, KKS, GAAR, CEIDG zawieszony | BLOCK_AND_ALERT |
| **P10-P19** | `jdg.routing` | OCR confidence per forma opodatkowania | BLOCK / TRIAGE |
| **P20-P39** | `jdg.compliance.*` | Biała Lista, MPP, limit gotówki, KSeF, kasy, akcyza, BDO | BLOCK / warnings |
| **P40-P49** | `jdg.crossborder` | WNT, WDT, import, eksport, trójstronne | Procedura specjalna |
| **P50-P69** | `jdg.vat.*` | Stawki VAT, GTU, zwolnienia, OSS | Stawka VAT + GTU |
| **P100-P117** | `jdg.wht`, `jdg.international.*` | WHT, PE, TP | WHT / TP |
| **P140-P157** | `jdg.compliance.*`, `jdg.platform_digital.*` | Platformy, CESOP, DAC7 | Compliance flags |
| **P183-P235** | `jdg.vat.deduction/declarations/tax_point` | Odliczenia, korekty, moment obowiązku | VAT deduction + timing |
| **P500-P599** | `jdg.pit.*` | Forma PIT, KUP, zaliczki, zeznania, zwolnienia | Stawka PIT + KUP |
| **P600-P635** | `jdg.allowances.*`, `jdg.crypto_digital_assets.*` | Ulgi, kryptoaktywa | Odliczenie / preferencja |
| **P700-P770** | `jdg.zus.*` | Składki ZUS, ulgi, zasiłki | Stawki składek |
| **P800-P870** | `jdg.accounting.*` | PKPiR, ewidencje, amortyzacja, leasing, FX | Kolumna PKPiR |
| **P900-P939** | `jdg.business.*` | CEIDG, zawieszenie, sukcesja, nieewidencjonowana | Status działalności |
| **P950-P989** | `jdg.ksef.*`, `jdg.jpk.*` | KSeF, JPK | KSeF/JPK flags |
| **P990-P999** | `jdg.retention` | Przechowywanie dokumentów | Okres retencji |
| **P1100-P1174** | `jdg.corrections`, `jdg.statute_liability` | Korekty, przedawnienia, odpowiedzialność | Korekta / przedawnienie |
| **P1200-P1223** | `jdg.representation`, `jdg.employer.*` | Pełnomocnictwa, pracownicy | Reprezentacja / payroll |
| **P1300-P1320** | `jdg.local_taxes.*` | PCC, nieruchomości, transport | Podatki lokalne |
| **P1400-P1822** | `jdg.compliance.bdo_environment`, `jdg.mdr_reporting`, `jdg.ai_act_compliance` | BDO, MDR, ESG, AI Act | Compliance flags |
| **P1000-P1099** | `jdg.fallback` | Domyślna stawka 23% + NO_MATCH | Fallback |

---

## 3. Hierarchia i Priorytety Reguł — Mechanizm First-Match-Wins

### 3.1 Zunifikowany Łańcuch First-Match-Wins

Pełny łańcuch decyzyjny OPA dla JDG. Wewnątrz każdego pakietu obowiązuje `else` chain — pierwsza dopasowana reguła wygrywa. Różne pakiety są ewaluowane niezależnie (Multi-Pass).

```
INPUT ─────────────────────────────────────────────────────────────────────────────► WERDYKT JDG

═══ BLOK 0: RISK & FRAUD (P0-P9) — NATYCHMIASTOWA BLOKADA ═══
P0      fraud_graph_match                      Kontrahent w sieci fraudowej VAT
P0_b    kks_empty_invoice_fraud                 Pusta faktura (Art. 62 § 2 KKS)
P1      counterparty_trust_low                  Trust score < próg
P2      anomaly_amount                          Kwota > 3σ od średniej
P3      new_counterparty_flag                   Nowy kontrahent → weryfikacja
P4      kks_hidden_income_flag                  Rozbieżność wpływy vs przychody (Art. 54 KKS)
P5      semantic_guard_disallowed               Wydatek niezwiązany z działalnością
P6      kks_unreliable_books                    Nierzetelna PKPiR (Art. 56 KKS)
P6_b    kks_declaration_overdue                 Niezłożona deklaracja (Art. 77 KKS)
P7      kks_vat_evidence_gap                    Niekompletna ewidencja VAT (Art. 57 KKS)
P8      ceidg_vendor_suspended                  Kontrahent zawieszony w CEIDG
P9      gaar_artificial_scheme                   Klauzula GAAR (Art. 119a OP)
         │
═══ BLOK 1: ROUTING & FIELD CONFIDENCE (P10-P19) ═══
P10     fc_vat_rate_low_scale                   Pewność VAT < próg (skala)
P11     fc_total_net_low_scale                  Pewność netto < próg (skala)
P12     fc_vendor_nip_low                        Pewność NIP < próg
P14     fc_linear_minimum                        Min. pewność (liniowy)
P15     fc_lump_sum_vat_rate                     Pewność VAT (ryczałt)
P16     fc_lump_sum_total_net                    Pewność netto (ryczałt)
P17     fc_mixed_auto_minimum                    Kategorie mieszane (samochody)
P19     fc_global_minimum_low                    Ogólna pewność < minimum
         │
═══ BLOK 2: COMPLIANCE DOKUMENTACYJNA (P20-P39) ═══
P20     whitelist_missing_over_limit             Brak na WL > 15k PLN
P21     whitelist_account_mismatch               Rachunek niezgodny z WL
P22     whitelist_zaw_nr_recovery                Procedura ZAW-NR
P25     split_payment_mandatory                  Obowiązkowy MPP
P35     cash_transaction_over_limit              Gotówka > 15k PLN → NKUP
P36     vat_simplified_receipt                   Paragon z NIP ≤ 450 PLN
P37     ksef_compliance_check                    KSeF compliance ★ NOWA
P39     vat_r_registration_status                Blokada: brak VAT-R
         │
═══ BLOK 3: CROSSBORDER (P40-P49) ═══
P40     eu_reverse_charge                       WNT — reverse charge
P41     eu_import_services                      Import usług z UE
P42     wdt_intracommunity_supply                WDT — 0% VAT
P43     vat_ue_registration_mandatory            Blokada: brak VAT-UE
P45     import_non_eu                            Import spoza UE
P47     import_services_non_eu                   Import usług NON-EU
P48     export_goods                             Eksport towarów
P49     triangular_transaction_rules             Transakcje trójstronne
         │
═══ BLOK 3b: PLATFORMY CYFROWE (P142-P157) ═══
P142    dac7_platform_reporting                  DAC7 — platformy raportują ★ NOWA
P143    platform_app_store_b2b_export            App Store / Google Play → B2B Irlandia
P144    platform_import_of_services              Prowizje Upwork / Fiverr → import usług
P145    cash_register_b2c_exemption_20k          Limit kasy fiskalnej 20k PLN
P146    e_commerce_virtual_cash_register         Kasa wirtualna (aplikacja)
P155    cesop_cross_border_payment_reporting     CESOP — raportowanie płatności ★ NOWA
         │
═══ BLOK 4: CYKL ŻYCIA JDG (P900-P939) ═══
P900    ceidg_registration_check                Obowiązek CEIDG
P902    ceidg_data_change_notification           Aktualizacja CEIDG (7 dni)
P904    ceidg_vendor_verification                Weryfikacja CEIDG kontrahenta
P910    business_suspension_valid                Zawieszenie — skutki podatkowe
P912    business_suspension_kup_restrictions     Zawieszenie — ograniczenia KUP
P914    business_suspension_zus                  Zawieszenie — skutki ZUS
P916    business_resumption_procedure            Wznowienie działalności
P920    succession_continuity                    Sukcesja — ciągłość NIP
P922    succession_tax_obligations               Sukcesja — obowiązki podatkowe
P924    succession_vat_continuity                Sukcesja — VAT
P930    unregistered_activity_limit              Limit dział. nieewidencjonowanej
P932    unregistered_activity_zus_exemption      Dział. nieewid. — brak ZUS
P934    unregistered_activity_taxation           Dział. nieewid. — skala PIT
         │
═══ BLOK 5: VAT — STAWKI I ZWOLNIENIA (P50-P65) ═══
P50     vat_margin_scheme                        Procedura marży
P52     vat_rate_fuel_pl                         Paliwo → 23% + GTU_04
P53     vat_rate_food_pl                          Żywność → 5% + GTU_07
P54     vat_rate_books_pl                         Książki → 5%
P55     vat_exemption_education                  Edukacja → zwolniona
P56     vat_exemption_healthcare                 Medycyna → zwolniona
P57     vat_exemption_finance                     Finanse → zwolnione
P58     vat_exemption_subject_jdg                Zwolnienie podmiotowe (200k)
P59     subject_exemption_startup_proportion     Proporcja dla nowych JDG
P60     vat_bad_debt_relief                       Ulga na złe długi VAT
P61     object_exemption_pkd                      Zwolnienie przedmiotowe PKD
P62     vat_exemption_financial                   Usługi finansowe
P63     vat_exemption_insurance                   Ubezpieczenia
P64     vat_margin_tourism                        VAT-marża turystyka
P65     gtu_mapping_by_category                   Mapowanie GTU (13 kodów)
         │
═══ BLOK 5b: OSS / E-COMMERCE (P66-P69) ═══
P66     wsto_threshold_monitor                   Próg WSTO 10k EUR
P67     oss_vat_rate_assignment                  VAT OSS wg kraju konsumenta
P68     oss_quarterly_declaration                 Deklaracja kwartalna OSS
P69     ioss_import_detection                     IOSS import ≤ 150 EUR
         │
═══ BLOK 6: VAT — SZCZEGÓŁOWE (P183-P235) ═══
P140    construction_reverse_charge_jdg          Reverse charge budowlanka
P141    it_service_export_b2b                    Eksport usług IT B2B do UE
P152    vat_farmer_rr_purchase_invoice            VAT RR — rolnik ryczałtowy
P153    excise_duty_car_import_eu                Akcyza — import auta z UE
P154    excise_duty_craft_beer_wine              Akcyza — produkcja alkoholu
P183    vat_blocked_categories                   Kat. wyłączone z odliczenia
P184    bad_debt_debtor_correction_mandatory     OBOWIĄZEK dłużnika (Art. 89b)
P185    vat_pre_proportion_mixed                 Pre-proporcja VAT
P186    vehicle_50_vat_deduction                 Auto mieszane 50% VAT
P187    annual_vat_correction_assets             Korekta roczna VAT
P188    vat_deduction_deadline_3m                Termin 3m na odliczenie
P189    bad_debt_relief_creditor                 Ulga złe długi — wierzyciel
P192    vat_refund_timing                        Terminy zwrotu VAT
P230    vat_tax_point_continuous_service         Usługi ciągłe
P231    vat_tax_point_advance_invoice            Zaliczki
P232    vat_ue_quarterly_summary                 VAT-UE kwartalne
P233    vat_z_deregistration                     Obowiązek VAT-Z
P234    vat_payment_deadline                     Termin VAT (25. dzień)
P235    vat_cash_accounting_jdg                  Metoda kasowa VAT
         │
═══ BLOK 7: WHT & MIĘDZYNARODOWE (P100-P117) ═══
P100    wht_obligation_detection                 Obowiązek poboru WHT
P102    wht_certificate_of_residence             Certyfikat rezydencji
P104    wht_payment_deadline                      Termin wpłaty WHT
P106    wht_annual_declaration                   WHT-26 roczna
P108    wht_double_taxation_avoidance            Unikanie podwójnego opodatkowania
P110    permanent_establishment_risk             Ryzyko PE
P114    tp_documentation_threshold               Obowiązek dokumentacji TP
P116    tp_arm_length_test                        Test rynkowości
P29     tp_safe_harbour_low_value_services       Safe harbour 5% TP
         │
═══ BLOK 8: PIT — FORMA OPODATKOWANIA (P500-P599) ═══
P500    pit_form_scale                            Skala podatkowa 12%/32%
P501    pit_scale_bracket_determination           Ustalenie progu (120k)
P502    pit_scale_joint_filing                   Wspólne rozliczenie małżonków
P510    pit_form_linear                           Podatek liniowy 19%
P511    pit_linear_no_tax_free_amount            Liniowy — brak kwoty wolnej
P512    linear_former_employer_restriction        Były pracodawca → NIE liniowy
P520    pit_form_lump_sum                         Ryczałt ewidencjonowany
P521    lump_sum_rate_by_pkwiu                    Stawka ryczałtu wg PKWiU
P522    lump_sum_multiple_rates                   Wiele stawek ryczałtu
P523    lump_sum_annual_limit                     Limit 2M EUR
P524    lump_sum_statutory_exclusions             Wyłączenia ustawowe z ryczałtu
P525    lump_sum_loss_of_right                    Utrata prawa do ryczałtu
P530    pit_form_tax_card                         Karta podatkowa
P531    tax_card_decision_valid                   Ważność decyzji o karcie
P532    tax_card_rate_table                       Tabela stawek karty
P533    tax_card_loss_events                      Utrata karty podatkowej
         │
═══ BLOK 8b: PIT — ZMIANA FORMY (P590-P599) ═══
P590    change_scale_to_linear                   Skala→Liniowy
P591    change_linear_to_lump_sum                 Liniowy→Ryczałt
P592    change_lump_sum_to_scale                 Ryczałt→Skala
P593    mid_year_change_restriction              Blokada zmiany w trakcie roku
P594    tax_consequences_form_change             Dwa zeznania roczne
P595    inventory_remeasurement_change            Remanent przy zmianie
P596    zus_health_recalculation_change           Przeliczenie zdrowotnej
P597    mid_year_tax_card_loss_to_scale           Karta→Skala (automatycznie)
P598    mid_year_lump_sum_loss_to_scale           Ryczałt→Skala (automatycznie)
         │
═══ BLOK 9: PIT — KUP (P560-P582) ═══
P560    kup_full_deductible                       Pełny KUP
P561    kup_zus_social_deductible                Składki ZUS społeczne → KUP
P562    kup_private_mixed_jdg                     Wydatki mieszane
P564    kup_car_over_150k_limit                   Auto > 150k limit KUP
P565    car_electric_225k_kup_limit               Auto elektryczne 225k limit
P566    kup_representation_none                   Reprezentacja → NKUP
P568    kup_unpaid_zus_social                     Niezapłacony ZUS → NKUP
P570    kup_health_contrib_linear_deduction       Zdrowotna liniowy — 12 900 limit
P571    kup_bad_debt_pit_debtor                   Złe długi PIT — dłużnik
P572    kup_direct_vs_indirect_timing             Direct vs indirect KUP
P573    kup_bad_debt_pit_creditor                 Ulga złe długi PIT — wierzyciel
P574    kup_detailed_exclusions                   Szczegółowe wyłączenia KUP
P575    kup_vehicle_insurance                     Ubezpieczenia komunikacyjne
P577    kup_zaw_nr_whitelist_procedure            ZAW-NR — przywrócenie KUP
P578    kup_own_and_spouse_work_nkup              Własna praca NKUP
P579    kup_professional_chamber_fees             Izby zawodowe KUP
P580    kup_contractual_penalties_nkup            Kary umowne NKUP
P581    kup_workwear_vs_suit_bhp                  Odzież robocza BHP vs reprezentacyjna
P582    kup_abandoned_spoiled_goods               Towary przeterminowane
         │
═══ BLOK 10: PIT — ZALICZKI, ZEZNANIA, ZWOLNIENIA (P540-P588) ═══
P540    pit_advance_monthly                       Zaliczka miesięczna
P541    pit_advance_zus_social_deduction         Odliczenie ZUS od zaliczki
P542    pit_advance_quarterly                     Zaliczka kwartalna
P543    pit_advance_simplified                    Uproszczone zaliczki
P550    pit_annual_return_pit36                  PIT-36 (30 kwietnia)
P552    pit_annual_return_pit36l                 PIT-36L (30 kwietnia)
P554    pit_annual_return_pit28                  PIT-28 (28 lutego!)
P556    pit_annual_return_overdue                Przekroczony termin zeznania
P580    pit_exemption_young                       Ulga dla młodych (<26)
P582    pit_exemption_return                      Ulga na powrót
P584    pit_exemption_family_4plus                Ulga dla rodzin 4+
P586    pit_exemption_working_senior              Ulga dla pracujących emerytów
P588    pit_exemption_interactions                Interakcje zwolnień (wspólny limit)
         │
═══ BLOK 11: ULGI PODATKOWE (P600-P635) ═══
P600    relief_rd_jdg                             Ulga B+R
P601    relief_prototype_jdg                     Ulga na prototyp
P602    relief_robotization_jdg                  Ulga na robotyzację
P603    relief_expansion_jdg                     Ulga na ekspansję
P604    relief_rehabilitation_jdg                Ulga rehabilitacyjna
P605    relief_internet_jdg                       Ulga internetowa
P606    relief_donation_ngo_jdg                  Darowizny OPP
P607    relief_donation_blood_jdg                Darowizny — krew
P608    relief_donation_church_jdg               Darowizny — kościół
P609    relief_abolition_jdg                     Ulga abolicyjna
P610    relief_ip_box_jdg                         IP Box 5%
P615    loss_carry_forward_jdg                    Rozliczenie straty
P616    relief_joint_allowances_limit             Łączny limit ulg
P617    relief_rd_qualifying_costs_jdg            Koszty kwalifikowane B+R
P618    relief_rd_documentation_obligation        Ewidencja B+R wymagana
P619    relief_ip_box_nexus_advanced              Nexus IP Box
P623    relief_thermo_jdg                         Ulga termomodernizacyjna
P630    crypto_income_classification              Kryptoaktywa — klasyfikacja ★ NOWA
P631    crypto_staking_income                      Staking — przychód ★ NOWA
P632    crypto_loss_offset_rules                   Straty krypto ★ NOWA
P633    crypto_nft_taxation                        NFT — opodatkowanie ★ NOWA
P634    crypto_defi_income                         DeFi — przychód ★ NOWA
P635    crypto_foreign_exchange_reporting          Giełdy zagraniczne ★ NOWA
         │
═══ BLOK 12: ZUS (P700-P770) ═══
P700    zus_social_standard_jdg                   Standardowe składki społeczne
P701    zus_sickness_voluntary_jdg               Chorobowa — dobrowolna
P720    zus_health_scale_jdg                      9% (skala)
P722    zus_health_linear_jdg                     4.9% (liniowy) + limit 12 900
P724    zus_health_lump_sum_jdg                   Progi ryczałtowe (60k/300k)
P730    health_contribution_rate_matrix           Macierz forma → składka
P732    form_change_contribution_trigger          Zmiana formy → alert DRA
P734    lump_sum_health_tier_lockstep            Przekroczenie progu → dopłata
P736    tax_card_health_fixed                     Karta → 9% min. wynagrodzenia
P738    scale_health_deduction_prohibition        Skala → NIE odlicza się
P739    health_insurance_obligation               Obowiązek ubezpieczenia zdrowotnego
P740    zus_start_relief_jdg                      Ulga na start (6 mies.)
P741    zus_maly_plus_jdg                         Mały ZUS Plus (36 mies.)
P742    zus_preferential_jdg                      Preferencyjny ZUS (24 mies.)
P743    concurrent_employment_exemption           Zbieg etat+JDG → tylko zdrowotna
P744    insurance_cessation_jdg                   Ustanie ubezpieczeń
P745    zus_payment_deadline                      Terminy płatności ZUS
P746    dra_filing_deadline                        Termin deklaracji DRA
P748    health_payment_deadline                   Termin składki zdrowotnej
P749    lump_sum_health_annual_reconciliation     Roczne rozliczenie ryczałtowca
P750    linear_tax_annual_health_reconciliation   Roczne rozliczenie liniowego
P753    tax_form_choice_optimization_hint         Sugestia optymalnej formy
P754    zus_health_minimum_base_guarantee         Gwarancja minimalnej podstawy
P756    zus_preferential_eligibility_check        Weryfikacja warunków preferencyjnego
P759    zus_prolongation_fee_vs_interest          Opłata prolongacyjna vs odsetki
P760    zus_sickness_benefit_jdg                  Zasiłek chorobowy ★ NOWA
P761    zus_maternity_benefit_jdg                 Zasiłek macierzyński ★ NOWA
         │
═══ BLOK 13: KSIĘGOWOŚĆ JDG (P800-P870) ═══
P800    pkpir_column_mapping                      Mapowanie na 16 kolumn PKPiR
P801    pkpir_revenue_recognition                Rozpoznanie przychodu
P802    pkpir_expense_recognition                Rozpoznanie kosztu
P820    lump_sum_evidence_entry                   Ewidencja ryczałtowca
P830    vat_evidence_purchase                     Ewidencja VAT zakupów
P832    vat_evidence_sale                         Ewidencja VAT sprzedaży
P840    depreciation_linear_jdg                   Amortyzacja liniowa
P842    depreciation_one_off_jdg                  Jednorazowa amortyzacja
P845    one_off_depreciation_de_minimis           Pomoc de minimis
P846    vat_quarterly_small_taxpayer_k            JPK_V7K kwartalny
P847    real_estate_residential_depreciation_ban  Zakaz amortyzacji mieszkań
P848    real_estate_depreciation_commercial_only  Amortyzacja komercyjna 2.5%
P849    real_estate_option_to_tax_vat             Opcja VAT nieruchomości
P850    private_mixed_home_office                Home office — proporcja
P852    private_mixed_car                         Samochód mieszany
P860    operating_lease_full_kup                  Leasing operacyjny → pełny KUP
P862    financial_lease_interest_kup              Leasing finansowy → odsetki KUP
P864    car_lease_150k_limit                      Limit 150k dla leasingu aut
P866    consumer_lease_jdg                        Leasing konsumencki
P868    lease_classification_test                 Test klasyfikacji leasingu
P870    fx_differences_recognition               Różnice kursowe
P870a   pit_loss_carry_forward_one_time_5m       Strata 5M jednorazowo
         │
═══ BLOK 14: KOREKTY (P1100-P1120) ═══
P1100   correction_invoice_in_minus              Korekta in minus
P1102   correction_invoice_in_plus               Korekta in plus
P1104   vat_declaration_correction                Korekta JPK_V7
P1106   pit_advance_correction                   Korekta zaliczek PIT
P1108   jpk_v7_correction_code                   Kod przyczyny korekty JPK
P1110   correction_deadline_restrictions          Terminy korekt
P1112   statute_barred_correction_block           Blokada przedawniona
P1114   correction_during_audit_block            Blokada w trakcie kontroli
P1115   correction_storno_red_detection           Storno czerwone
P1116   correction_storno_black_detection         Storno czarne
P1120   correction_nip_update_consequences        Korekta NIP — skutki VAT
         │
═══ BLOK 15: PRZEDAWNIENIA I ODPOWIEDZIALNOŚĆ (P1150-P1174) ═══
P1150   tax_statute_of_limitations_5y            Przedawnienie podatkowe 5 lat
P1152   zus_statute_of_limitations_5y            Przedawnienie ZUS 5 lat
P1154   statute_suspension_during_audit          Zawieszenie w kontroli
P1156   statute_interruption_events              Przerwanie — egzekucja
P1157   statute_interruption_detailed             Przerwanie — uznanie długu
P1158   entrepreneur_personal_liability          Pełna odpowiedzialność osobista
P1160   successor_liability                       Odpowiedzialność następców
P1162   joint_liability_spouse                    Odpowiedzialność małżonka
P1164   late_payment_interest_calculation         Odsetki za zwłokę
P1166   penalty_interest_rate                     Odsetki karne 150%
P1167   tax_arrears_detection                     Wykrycie zaległości
P1168   voluntary_disclosure_active               Czynny żal
P1169   overpayment_detection                     Wykrycie nadpłaty
P1170   deferral_active                            Aktywne odroczenie
P1171   tax_remission_active                      Umorzenie zaległości
P1172   overpayment_offset_detailed               Zaliczenie nadpłaty
P1174   tax_proceeding_deadlines                  Terminy proceduralne
         │
═══ BLOK 16: REPREZENTACJA (P1200-P1212) ═══
P1200   power_of_attorney_pps1                   PPS-1 — pełnomocnictwo szczególne
P1202   general_proxy_upl1                        UPL-1 — pełnomocnictwo ogólne
P1204   commercial_proxy_prokura                 Prokura — wpis CEIDG
P1205   prokura_types_detailed                    Typy prokury
P1206   attorney_authorization_scope              Zakres pełnomocnictwa
P1208   proxy_validity_period                     Ważność pełnomocnictwa
P1210   proxy_revocation_effects                  Odwołanie pełnomocnictwa
P1212   representation_tax_audit                  Pełnomocnictwo przy kontroli
         │
═══ BLOK 17: PRACODAWCA (P1200e-P1223) ═══
P1200e  employer_obligation_detection             Aktywacja trybu pracodawcy
P1202e  payroll_tax_advance_obligation            PIT-4R od wynagrodzeń
P1204e  payroll_zus_contributions_employer        ZUS RCA pracownicy
P1206e  annual_pit11_filing                       PIT-11 roczna
P1208e  ppk_obligation_check                      Obowiązek PPK
P1210e  small_mandate_flat_tax                    Małe umowy ≤200 PLN
P1212e  civil_contract_zus_classification         Umowy cywilnoprawne
P1220   copyright_transfer_50_kup                 50% KUP prawa autorskie
P1222   copyright_kup_annual_limit                Limit roczny 50% KUP 60 000
P1223   copyright_scale_only                      50% KUP tylko przy skali
         │
═══ BLOK 18: PODATKI LOKALNE (P1300-P1320) ═══
P1300   pcc_mandatory_purchase_from_private       PCC od zakupu od os. prywatnej
P1302   pcc_loan_from_private                     PCC od pożyczki prywatnej
P1304   pcc_company_formation_exempt              PCC nie dotyczy JDG
P1310   real_estate_commercial_rate               Podatek od nieruchomości firmowych
P1312   real_estate_tax_return_deadline           Termin DN-1
P1320   transport_tax_applicable                  Podatek od środków transportowych
         │
═══ BLOK 19: ŚRODOWISKO (P1400-P1407) ═══
P1400   bdo_registration_check                    Obowiązek rejestracji BDO
P1402   bdo_invoice_validation                    Numer BDO na fakturach
P1405   kobize_emission_report                    Raport KOBiZE
P1406   kobize_exemption_small_emitter            Zwolnienie < 1 Mg CO2
         │
═══ BLOK 20: RESTRUKTURYZACJA (P1500-P1505) ═══
P1500   jdg_to_company_conversion_detection       Przekształcenie JDG→spółka
P1502   conversion_closing_inventory              Remanent likwidacyjny
P1504   conversion_vat_consequences               Skutki VAT przekształcenia
P1505   conversion_psi_tax_exemption              Zwolnienie PSI
         │
═══ BLOK 21: MDR I AI ACT (P1800-P1822) ═══
P1800   mdr_reportable_scheme_detection           Schematy MDR ★ NOWA
P1810   esg_taxonomy_reporting_jdg               ESG/CSRD ★ NOWA
P1820   ai_act_jdg_classification                 AI Act dla JDG IT ★ NOWA
         │
═══ BLOK 22: DZIEDZICZENIE I FUNDACJA RODZINNA (P930a-P1732) ═══
P930a   inheritance_tax_exemption_enterprise      Zwolnienie spadkowe JDG
P931a   succession_inventory_depreciation_continuity  Kontynuacja amortyzacji
P1731   family_foundation_asset_transfer          Transfer do Fundacji Rodzinnej
P1732   family_foundation_rental_hidden_profits   Najem od Fundacji — ukryte zyski
         │
═══ BLOK 23: TEMPORALNE (P1600-P1612) ═══
P1600   rmk_detection                              Wykrycie RMK
P1602   rmk_monthly_release                        Uwalnianie RMK
P1610   time_travel_evaluation_mode                Time-Travel OPA
         │
═══ BLOK 24: KSeF I JPK (P950-P989) ═══
P950    ksef_structured_mandatory_jdg            Obowiązek KSeF
P952    ksef_b2c_exemption_jdg                    Wyłączenie B2C
P953    ksef_attachment_size_limit                Limit 200MB załączników ★ NOWA
P955    ksef_qr_code_validation                   Kod QR mandatory ★ NOWA
P960    ksef_offline_recovery                     Tryb awaryjny KSeF
P970    jpk_v7m_structure_jdg                     JPK_V7M/K
P974    jpk_v7_gtu_obligation_check               Kompletność GTU ★ NOWA
P975    jpk_k_penalty_accumulation                Ryzyko kontroli >3 korekty ★ NOWA
P980    jpk_pkpir_structure_jdg                   JPK_PKPIR
         │
═══ BLOK 25: RETENCJA I FALLBACK (P990-P1099) ═══
P990    retention_invoice_5y                      Przechowywanie 5 lat
P992    retention_pkpir_5y                        PKPiR 5 lat
P1000   domestic_fallback_jdg                    Domyślna stawka 23%
P1099   no_match_jdg                              NO_MATCHING_RULE (zawsze ostatnia)
```

### 3.2 Priorytetyzacja Domen (Multi-Pass)

| Pass | Domena | Priorytet | Abortuje na BLOCK? |
|------|--------|:---------:|:------------------:|
| 0 | `jdg.risk` | P0-P9 | ✅ Tak |
| 1 | `jdg.routing` | P10-P19 | ✅ Tak |
| 2 | `jdg.compliance.*` | P20-P39, P140-P157 | ❌ Nie (warnings) |
| 3 | `jdg.crossborder` | P40-P49 | ❌ Nie |
| 4 | `jdg.vat.*` | P50-P235 | ❌ Nie |
| 5 | `jdg.pit.*` | P500-P599 | ❌ Nie |
| 6 | `jdg.allowances.*` | P600-P635 | ❌ Nie |
| 7 | `jdg.accounting.*` | P800-P870 | ❌ Nie |
| 8 | `jdg.zus.*` + `jdg.business.*` + `jdg.ksef.*` + `jdg.jpk.*` | P700-P989 | ❌ Nie |

---

## 4. Szczegółowy Opis Reguł per Pakiet

> Poniżej szczegółowy opis kluczowych reguł dla każdego pakietu. Każda reguła zawiera: nazwę, cel biznesowy, przesłanki, rezultat, podstawę prawną i zależności. Pełny spis ~3 080 reguł w dokumentach 22-31; tutaj prezentujemy reguły krytyczne i nowe.

---

### 4.1 Pakiet `jdg.risk` — Ryzyko i Fraud (P0-P9)

#### P0: `fraud_graph_match`
- **Cel biznesowy:** Natychmiastowa blokada faktury od kontrahenta w sieci fraudowej VAT
- **Przesłanki:** `input.vendor.fraud_flag == true`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `fraud_detected: true`
- **Podstawa prawna:** Art. 86 ust. 1 ustawy o VAT, Art. 55 KKS
- **Zależności:** FraudGraphScanner musi oznaczyć `vendor.fraud_flag`
- **Priorytet:** 0

#### P0_b: `kks_empty_invoice_fraud`
- **Cel biznesowy:** Blokada pustej faktury (brak dostawy towaru/usługi) — przestępstwo skarbowe
- **Przesłanki:** `vendor.fraud_flag == true` AND `invoice.delivery_confirmed == false` AND `invoice.amount_gross > 0`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `kks_risk: "Art.62_par2"`, `max_penalty: "25_lat_pozbawienia_wolnosci"`
- **Podstawa prawna:** Art. 62 § 2 KKS
- **Priorytet:** 0.5

#### P8: `ceidg_vendor_suspended`
- **Cel biznesowy:** Kontrahent JDG z zawieszoną działalnością w CEIDG — ryzyko fraudu
- **Przesłanki:** `vendor.ceidg_status == "SUSPENDED"` AND `invoice.transaction_date > vendor.suspension_date`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `fraud_risk_elevated: true`
- **Podstawa prawna:** Art. 88 ustawy o VAT, Art. 22-25 Prawa przedsiębiorców
- **Zależności:** CEIDG API musi dostarczyć `vendor.ceidg_status`
- **Priorytet:** 8

#### P9: `gaar_artificial_scheme`
- **Cel biznesowy:** Wykrycie transakcji sztucznie unikających opodatkowania (klauzula ogólna GAAR)
- **Przesłanki:** `vendor.is_related_party == true` AND `amount_net > gaar_materiality_threshold` AND odchylenie od ceny rynkowej > 50%
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `gaar_risk: true`, `gaar_risk_level: "HIGH"`
- **Podstawa prawna:** Art. 119a § 1 Ordynacji podatkowej
- **Priorytet:** 9

---

### 4.2 Pakiet `jdg.compliance` — Zgodność (P20-P39, P140-P157)

#### P20: `whitelist_missing_over_limit`
- **Cel biznesowy:** Weryfikacja Białej Listy MF dla przelewów >15 000 PLN. Odpowiedzialność solidarna JDG.
- **Przesłanki:** `invoice.amount_gross >= thresholds.jdg.limits.mpp_limit` AND `vendor.on_whitelist == false`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 96b ustawy o VAT, Art. 117ba Ordynacji podatkowej
- **Priorytet:** 20

#### P25: `split_payment_mandatory`
- **Cel biznesowy:** Obowiązkowy MPP dla faktur >15k PLN z towarami wrażliwymi
- **Przesłanki:** `invoice.amount_gross >= thresholds.jdg.limits.mpp_limit` AND kategoria wrażliwa MPP
- **Rezultat:** `mpp_required: true`
- **Podstawa prawna:** Art. 108a ustawy o VAT
- **Priorytet:** 25

#### P35: `cash_transaction_over_limit`
- **Cel biznesowy:** Płatność gotówkowa >15k PLN → brak KUP (dla JDG — PIT!)
- **Przesłanki:** `invoice.is_cash_payment == true` AND `invoice.amount_gross >= thresholds.jdg.limits.cash_transaction_limit`
- **Rezultat:** `kus_qualification: "none"`
- **Podstawa prawna:** Art. 22p ustawy o PIT
- **Priorytet:** 35

#### P145: `cash_register_b2c_exemption_20k` ★ NOWA
- **Cel biznesowy:** JDG dokonujące sprzedaży B2C są zwolnione z kasy fiskalnej do limitu 20 000 PLN rocznie
- **Przesłanki:** `invoice.direction == "SALE"` AND `vendor.is_b2c == true` AND `jdg_entrepreneur.b2c_annual_turnover_for_fiscal < 20000`
- **Rezultat:** `cash_register_exempt: true` (poniżej 20k) lub `cash_register_mandatory: true` (powyżej)
- **Podstawa prawna:** Rozporządzenie MF w sprawie zwolnień z kas rejestrujących
- **Priorytet:** 145

---

### 4.3 Pakiet `jdg.vat` — VAT dla JDG (P50-P235)

#### P52: `vat_rate_fuel_pl`
- **Cel biznesowy:** Stawka VAT 23% dla paliw silnikowych + kod GTU_04
- **Przesłanki:** `invoice.category_code == "FUEL"` AND `vendor.country == "PL"`
- **Rezultat:** `vat_rate: "0.23"`, `gtu_code: "GTU_04"`, `rounding_level: "position"`
- **Podstawa prawna:** Art. 41 ust. 1 ustawy o VAT
- **Priorytet:** 52

#### P58: `vat_exemption_subject_jdg`
- **Cel biznesowy:** Zwolnienie podmiotowe VAT dla JDG (limit 200 000 PLN). Proporcja dla nowych firm.
- **Przesłanki:** `jdg_entrepreneur.is_vat_payer == false` AND `annual_turnover_net < thresholds.jdg.limits.vat_exemption_limit`
- **Rezultat:** `vat_rate: "0.00"`, `vat_exemption: "SUBJECT"`
- **Podstawa prawna:** Art. 113 ust. 1 i ust. 9 ustawy o VAT
- **Zależności:** Musi być sprawdzona PRZED regułami stawek VAT
- **Priorytet:** 58

#### P184: `bad_debt_debtor_correction_mandatory`
- **Cel biznesowy:** OBOWIĄZEK dłużnika do korekty VAT in minus po 90 dniach niezapłacenia
- **Przesłanki:** `invoice.direction == "PURCHASE"` AND `is_paid == false` AND `is_vat_deducted == true` AND `days_overdue >= 90`
- **Rezultat:** `vat_correction_in_minus_mandatory: true`, `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 89b ustawy o VAT
- **Priorytet:** 184

#### P235: `vat_cash_accounting_jdg`
- **Cel biznesowy:** Metoda kasowa VAT dla małych podatników JDG — obowiązek w dacie zapłaty
- **Przesłanki:** `jdg_entrepreneur.is_small_taxpayer == true` AND `is_vat_payer == true` AND `invoice.vat_cash_accounting == true`
- **Rezultat:** `vat_cash_accounting: true`, `tax_point: "PAYMENT_DATE"`
- **Podstawa prawna:** Art. 21 ustawy o VAT
- **Priorytet:** 235

---

### 4.4 Pakiet `jdg.pit` — PIT / Forma opodatkowania (P500-P599)

#### P500: `pit_form_scale`
- **Cel biznesowy:** Skala podatkowa 12%/32% — domyślna forma dla JDG
- **Przesłanki:** `jdg_entrepreneur.tax_form == "PIT_SCALE"`
- **Rezultat:** `pit_form: "SCALE"`, `pit_rate: "0.12"` (I próg) lub `"0.32"` (II próg), `pit_annual_return_type: "PIT-36"`
- **Podstawa prawna:** Art. 27 ust. 1 ustawy o PIT
- **Zależności:** Nadrzędna nad regułami KUP i zaliczek
- **Priorytet:** 500

#### P520: `pit_form_lump_sum`
- **Cel biznesowy:** Ryczałt ewidencjonowany — podatek od przychodu, różne stawki wg PKWiU
- **Przesłanki:** `jdg_entrepreneur.tax_form == "LUMP_SUM"`
- **Rezultat:** `pit_form: "LUMP_SUM"`, `pit_rate` zależna od PKWiU (P521), `pit_annual_return_type: "PIT-28"`
- **Podstawa prawna:** Ustawa o zryczałtowanym podatku dochodowym
- **Priorytet:** 520

#### P521: `lump_sum_rate_by_pkwiu`
- **Cel biznesowy:** Przypisanie stawki ryczałtu na podstawie PKWiU
- **Przesłanki:** `jdg_entrepreneur.tax_form == "LUMP_SUM"`
- **Rezultat:** Stawka z `thresholds.jdg.lump_sum_rates.*` wg PKWiU
- **Tabela stawek:** 17% (wolne zawody), 15% (pośrednictwo), 14% (IT), 12% (software), 10% (budownictwo), 8.5% (handel), 5.5% (bud. z mat.), 3% (gastronomia), 2% (rolnictwo)
- **Podstawa prawna:** Art. 12 ustawy o ryczałcie
- **Priorytet:** 521

#### P562: `kup_private_mixed_jdg`
- **Cel biznesowy:** Wydatki mieszane (prywatno-firmowe) — proporcjonalne KUP. Klasyczny problem JDG.
- **Przesłanki:** `invoice.private_use_percent > 0` AND `invoice.private_use_percent < 100`
- **Rezultat:** `kus_qualification: "partial"`, `kus_percent: 100 - private_use_percent`
- **Podstawa prawna:** Art. 22 ust. 1 ustawy o PIT
- **Priorytet:** 562

#### P578: `kup_own_and_spouse_work_nkup`
- **Cel biznesowy:** Wartość własnej pracy przedsiębiorcy i małżonka NIE stanowi KUP
- **Przesłanki:** `jdg_entrepreneur.is_owner_labor == true` LUB (`spouse_works_in_jdg == true` AND `invoice.beneficiary == "SPOUSE"`)
- **Rezultat:** `kus_qualification: "none"`, `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 10 PIT
- **Priorytet:** 578

---

### 4.5 Pakiet `jdg.zus` — Składki ZUS (P700-P770)

#### P700: `zus_social_standard_jdg`
- **Cel biznesowy:** Standardowe składki społeczne JDG od podstawy 60% prognozowanego przeciętnego wynagrodzenia
- **Przesłanki:** `jdg_entrepreneur.zus_status == "STANDARD"`
- **Rezultat:** `zus_pension_rate: "0.1952"`, `zus_disability_rate: "0.08"`, `zus_sickness_rate: "0.0245"` (DOBROWOLNA!), `zus_accident_rate: "0.0167"`, `zus_labour_fund_rate: "0.0245"`
- **Podstawa prawna:** Art. 18, 18a, 22 ustawy o SUS
- **Priorytet:** 700

#### P720: `zus_health_scale_jdg`
- **Cel biznesowy:** Składka zdrowotna 9% od dochodu dla skali podatkowej. NIE odlicza się.
- **Przesłanki:** `jdg_entrepreneur.tax_form == "PIT_SCALE"`
- **Rezultat:** `zus_health_rate: "0.09"`, `zus_health_base: "INCOME"`, `zus_health_deductible_from_tax: false`
- **Podstawa prawna:** Art. 79 ust. 1, art. 81 ust. 1 ustawy o świadczeniach opieki zdrowotnej
- **Priorytet:** 720

#### P724: `zus_health_lump_sum_jdg`
- **Cel biznesowy:** Składka zdrowotna dla ryczałtu — 3 progi zależne od rocznego przychodu
- **Przesłanki:** `jdg_entrepreneur.tax_form == "LUMP_SUM"`
- **Rezultat:** Próg I (≤60k): 60% śr. wynagr.; Próg II (60k-300k): 100% śr. wynagr.; Próg III (>300k): 180% śr. wynagr.
- **Podstawa prawna:** Art. 81 ust. 2a-2c ustawy o świadczeniach opieki zdrowotnej
- **Priorytet:** 724

#### P740: `zus_start_relief_jdg`
- **Cel biznesowy:** Ulga na start — 6 miesięcy bez składek społecznych (tylko zdrowotna)
- **Przesłanki:** `zus_status == "START_RELIEF"` AND `zus_months_used_current_status < 6`
- **Rezultat:** Wszystkie składki społeczne = 0, `zus_health_only: true`
- **Podstawa prawna:** Art. 18a ustawy o SUS
- **Priorytet:** 740

#### P743: `concurrent_employment_exemption`
- **Cel biznesowy:** Zbieg etat+JDG → z JDG tylko składka zdrowotna (nie społeczne!)
- **Przesłanki:** `jdg_entrepreneur.has_employment_contract == true` AND `employment_salary >= minimum_wage_gross`
- **Rezultat:** `zus_social_rate: "0.00"`, `zus_social_from_jdg: false`, `zus_health_due: true`
- **Podstawa prawna:** Art. 9 ust. 1a-2 ustawy o SUS
- **Priorytet:** 743

---

### 4.6 Pakiet `jdg.accounting` — Księgowość (P800-P870)

#### P800: `pkpir_column_mapping`
- **Cel biznesowy:** Mapowanie wydatku na odpowiednią kolumnę PKPiR (16 kolumn)
- **Przesłanki:** `jdg_entrepreneur.uses_pkpir == true`
- **Rezultat:** `pkpir_column: <numer 1-16>`
- **Tabela:** Kol. 6 (przychód tow.), 7 (pozostałe przych.), 9 (zakup towarów), 10 (koszty uboczne), 11 (wynagrodzenia), 12 (pozostałe wydatki), 14 (NKUP), 15 (środki trwałe)
- **Podstawa prawna:** Rozporządzenie MF w sprawie PKPiR
- **Priorytet:** 800

#### P842: `depreciation_one_off_jdg`
- **Cel biznesowy:** Jednorazowa amortyzacja dla małych podatników JDG — limit 50 000 EUR
- **Przesłanki:** `is_small_taxpayer == true` AND `amount_net <= 50000_EUR` AND `expense_type == "FIXED_ASSET"`
- **Rezultat:** `depreciation_method: "ONE_OFF"`, `depreciation_rate: "1.00"`
- **Podstawa prawna:** Art. 22k ust. 7 PIT
- **Zależności:** Pomoc de minimis — wymaga zaświadczenia (P845)
- **Priorytet:** 842

#### P847: `real_estate_residential_depreciation_ban`
- **Cel biznesowy:** BEZWZGLĘDNY ZAKAZ amortyzacji budynków/lokali mieszkalnych nabytych po 2022 roku
- **Przesłanki:** `expense_type == "REAL_ESTATE_DEPRECIATION"` AND `real_estate_type == "RESIDENTIAL"` AND `building_year >= 2023`
- **Rezultat:** `depreciation_allowed: false`, `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 22c pkt 2 PIT
- **Priorytet:** 847

---

### 4.7 Pakiet `jdg.business` — Cykl życia JDG (P900-P939)

#### P910: `business_suspension_valid`
- **Cel biznesowy:** Skutki podatkowe zawieszenia JDG — brak zaliczek PIT, zerowe VAT (chyba że sprzedaż), tylko stałe koszty
- **Przesłanki:** `business_status == "SUSPENDED"` AND `transaction_date` w okresie zawieszenia
- **Rezultat:** `pit_advance_required: false`, `vat_declaration_required: false` (chyba sprzedaż), `kus_allowed: "MAINTENANCE_ONLY"`
- **Podstawa prawna:** Art. 22-25 Prawa przedsiębiorców, Art. 44 ust. 10 PIT
- **Priorytet:** 910

#### P920: `succession_continuity`
- **Cel biznesowy:** Po śmierci przedsiębiorcy — zarządca sukcesyjny kontynuuje pod dotychczasowym NIP (z dopiskiem "w spadku")
- **Przesłanki:** `in_succession == true` AND `succession_manager_nip != null`
- **Rezultat:** `business_status: "IN_SUCCESSIO"`, `nip_status: "DECEASED_IN_SUCCESSIO"`
- **Podstawa prawna:** Ustawa o zarządzie sukcesyjnym
- **Priorytet:** 920

#### P930: `unregistered_activity_limit`
- **Cel biznesowy:** Limit działalności nieewidencjonowanej — 50% minimalnego wynagrodzenia miesięcznie
- **Przesłanki:** `is_unregistered_activity == true` AND `monthly_revenue_current > 0.50 * minimum_wage_gross`
- **Rezultat:** `unregistered_activity_limit_exceeded: true`, `ceidg_registration_required: true`
- **Podstawa prawna:** Art. 5 Prawa przedsiębiorców
- **Priorytet:** 930

---

### 4.8 Pakiet `jdg.ksef` / `jdg.jpk` — KSeF i JPK (P950-P989)

#### P950: `ksef_structured_mandatory_jdg`
- **Cel biznesowy:** Obowiązek KSeF od 1 lutego 2026 r. dla czynnych podatników VAT
- **Przesłanki:** `invoice.transaction_date >= "2026-02-01"` AND `is_vat_payer == true` AND `direction == "SALE"`
- **Rezultat:** `ksef_required: true`
- **Podstawa prawna:** Art. 106na-106nq ustawy o VAT
- **Priorytet:** 950

#### P974: `jpk_v7_gtu_obligation_check` ★ NOWA
- **Cel biznesowy:** Weryfikacja kompletności oznaczeń GTU w JPK_V7 — brak kodu GTU = odrzucenie JPK
- **Przesłanki:** `is_vat_payer == true` AND kategoria wymaga GTU AND `invoice.gtu_code == ""`
- **Rezultat:** `gtu_missing: true`, `_routing: "TRIAGE_QUEUE"`
- **Podstawa prawna:** § 10 rozporządzenia JPK_VAT
- **Priorytet:** 974

---

## 5. Nowe Obszary ENTERPRISE — ~56 Nowych Reguł

Poniższe reguły NIE występują w dokumentach 22-31 (z wyjątkiem P1800-P1822, które rozwijają koncepcje z dokumentu 28). Stanowią nowe obszary pokrywające luki zidentyfikowane przez głęboką analizę. Reguły P1880-P1884 (Polski Ład) są semantycznie powiązane z istniejącymi P738 i P847 — zostały tu uwzględnione jako semantyka pogrupowana, nie duplikaty (w implementacji Rego, P738 i P847 pozostają autorytatywne).

---

### 5.1 Kryptoaktywa i Cyfrowe Aktywa (P630-P635) — 6 nowych reguł

> **Stan przed:** Brak jakiejkolwiek reguł dla kryptowalut, NFT, stakingu, DeFi. JDG trading krypto to rosnący segment.

#### P630: `crypto_income_classification`
- **Cel biznesowy:** Klasyfikacja przychodów z kryptoaktywów — sprzedaż kryptowalut jest przychodem z kapitałów pieniężnych (Art. 30b PIT), opodatkowana 19% od dochodu (przychód minus koszty nabycia).
- **Przesłanki:** `invoice.category_code in ["CRYPTO_SALE", "CRYPTO_EXCHANGE", "CRYPTO_SWAP"]` AND `jdg_entrepreneur.tax_form in ["PIT_SCALE", "LINEAR"]`
- **Rezultat:** `pit_form: "CAPITAL_GAINS"`, `pit_rate: "0.19"`, `pit_annual_return_type: "PIT-38"`, `separate_source: true` (nie łączy się z JDG)
- **Podstawa prawna:** Art. 30b ust. 1 pkt 1 ustawy o PIT
- **Priorytet:** 630
- **Zależności:** Sprawdzana PRZED regułami form PIT (P500-P530) — krypto to osobne źródło

#### P631: `crypto_staking_income`
- **Cel biznesowy:** Staking kryptowalut — nagrody ze stakingu są przychodem z kapitałów pieniężnych w dacie otrzymania nagrody. Koszty: sprzęt mining/staking, prąd, prowizje giełdy.
- **Przesłanki:** `invoice.category_code == "CRYPTO_STAKING_REWARD"` AND `invoice.amount_gross > 0`
- **Rezultat:** `income_type: "STAKING_REWARD"`, `pit_rate: "0.19"`, `pit_annual_return_type: "PIT-38"`, `deductible_costs: ["HARDWARE", "ELECTRICITY", "EXCHANGE_FEES"]`
- **Podstawa prawna:** Art. 30b ust. 1 pkt 1 PIT (nagrody ze stakingu = zbycie praw pochodnych)
- **Priorytet:** 631
- **ŹRÓDŁO:** Interpretacja indywidualna DKIS nr 0114-KDIP2-2.4010.579.2025.2.IN z 27.02.2026 — DKIS uznaje otrzymanie nagród ze stakingu za przychód w momencie otrzymania; sądy administracyjne (WSA) orzekają, że staking jest neutralny podatkowo do momentu zbycia tokenów (Art. 17 ust. 1f PIT). Konflikt trwa — zalecana własna interpretacja indywidualna. DAC8 (Dir (EU) 2023/2226) od 01.01.2026 wymusza raportowanie stakingu przez CASP do KAS

#### P632: `crypto_loss_offset_rules`
- **Cel biznesowy:** Straty z kryptoaktywów mogą być odliczone tylko od przychodów z kryptoaktywów (nie od JDG!). Limit 50% straty rocznie, carry-forward 5 lat.
- **Przesłanki:** `jdg_entrepreneur.has_crypto_loss_carry_forward == true` AND `invoice.category_code == "CRYPTO_SALE"`
- **Rezultat:** `loss_offset_limit: "CRYPTO_ONLY"`, `max_loss_deduction: 50pct_of_crypto_income`, `loss_carry_forward_years: 5`
- **Podstawa prawna:** Art. 9 ust. 3, Art. 30b ust. 3 PIT
- **Priorytet:** 632

#### P633: `crypto_nft_taxation`
- **Cel biznesowy:** NFT (Non-Fungible Tokens) — sprzedaż NFT przez JDG artystę/Digital Creator. Klasyfikacja: jeśli twórca → przychód z działalności gospodarczej (skala/liniowy/ryczałt); jeśli inwestor → kapitały pieniężne 19%.
- **Przesłanki:** `invoice.category_code == "NFT_SALE"` AND `jdg_entrepreneur.is_nft_creator == true`
- **Rezultat:** `income_type: "BUSINESS_REVENUE"` (dla twórcy) lub `"CAPITAL_GAINS"` (dla inwestora), odpowiednia stawka PIT
- **Podstawa prawna:** Art. 14 PIT (działalność) lub Art. 30b PIT (kapitały)
- **Priorytet:** 633
- **ŹRÓDŁO:** Brak dedykowanej interpretacji MF dla NFT. KIS w pojedynczych interpretacjach wskazuje, że NFT nie są "walutami wirtualnymi" w rozumieniu PIT — opodatkowanie zależy od charakteru NFT (twórca → działalność Art. 14 PIT, inwestor → kapitały Art. 30b PIT). EU VAT Committee Working Paper no. 1060 (21.03.2023) klasyfikuje NFT jako usługi (general rule). Zalecana własna interpretacja indywidualna (ORD-IN)

#### P634: `crypto_defi_income`
- **Cel biznesowy:** DeFi (Decentralized Finance) — przychody z yield farming, liquidity mining, lending. Klasyfikacja jako przychody z kapitałów pieniężnych lub z działalności — zależy od charakteru i skali.
- **Przesłanki:** `invoice.category_code in ["DEFI_YIELD", "DEFI_LENDING", "DEFI_LIQUIDITY"]` AND `invoice.amount_gross > 0`
- **Rezultat:** `income_type: "DEFI_REVENUE"`, `pit_rate: "0.19"` (kapitały) lub standardowa forma PIT (jeśli działalność)
- **Podstawa prawna:** Art. 30b ust. 1 pkt 1 PIT (analogia)
- **Priorytet:** 634
- **ŹRÓDŁO:** Brak dedykowanej interpretacji MF dla DeFi. Opodatkowanie na zasadach ogólnych (Art. 30b PIT — 19% od dochodu). Dyrektywa DAC8 (Dir (EU) 2023/2226) wdrożona w PL od 01.01.2026 (zbieranie danych przez RCASP) — raportowanie do KAS. Pierwsza wymiana danych między państwami UE: 30.09.2027. Zalecana własna interpretacja indywidualna

#### P635: `crypto_foreign_exchange_reporting`
- **Cel biznesowy:** JDG korzystające z zagranicznych giełd krypto (Binance, Coinbase, Kraken) — obowiązek raportowania sald > 200 000 PLN na kontach zagranicznych (formularz UZ-3).
- **Przesłanki:** `jdg_entrepreneur.has_foreign_crypto_accounts == true` AND `foreign_crypto_balance_pln > 200000`
- **Rezultat:** `uz3_reporting_required: true`, `_warning: "Saldo > 200 000 PLN na zagranicznych giełdach krypto — obowiązek raportowania UZ-3"`
- **Podstawa prawna:** Art. 30b ust. 12 PIT, ustawa o NBP (raportowanie sald zagranicznych)
- **Priorytet:** 635

---

### 5.2 CESOP — Cross-Border Euro Payments (P155-P157) — 3 nowe reguły

> **Stan przed:** Brak reguł dla CESOP (Central Electronic System of Payment information), obowiązującego od 1 stycznia 2024 r.

#### P155: `cesop_cross_border_payment_reporting`
- **Cel biznesowy:** CESOP — wszystkie transgraniczne płatności UE > 25 000 EUR rocznie muszą być raportowane przez PSP (Payment Service Providers). JDG otrzymujące płatności zagraniczne powyżej tego progu podlegają weryfikacji.
- **Przesłanki:** `invoice.direction == "SALE"` AND `vendor.country in EU_COUNTRIES` AND `jdg_entrepreneur.annual_cross_border_eur > 25000`
- **Rezultat:** `cesop_reportable: true`, `cesop_verification_required: true`, `_warning: "Transgraniczne płatności UE > 25 000 EUR — dane przekazywane do CESOP"`
- **Podstawa prawna:** Rozporządzenie 2020/284 (CESOP), wdrożone w PL od 2024-01-01
- **Priorytet:** 155

#### P156: `cesop_payment_method_classification`
- **Cel biznesowy:** Klasyfikacja metod płatności transgranicznych dla CESOP — karta, przelew SEPA/Target2, BLIK, crypto. Każda metoda ma osobny kod raportowania.
- **Przesłanki:** `invoice.direction == "SALE"` AND `vendor.country in EU_COUNTRIES` AND `invoice.payment_method != ""`
- **Rezultat:** `cesop_payment_type: "CARD" | "SEPA" | "TARGET2" | "BLIK" | "CRYPTO"`
- **Podstawa prawna:** Rozporządzenie 2020/284 art. 3
- **Priorytet:** 156

#### P157: `cesop_quarterly_aggregation_check`
- **Cel biznesowy:** CESOP agreguje płatności kwartalnie — JDG z wieloma małymi płatnościami do tego samego kontrahenta UE, które sumarycznie przekraczają 25 000 EUR, podlegają raportowaniu.
- **Przesłanki:** `vendor.country in EU_COUNTRIES` AND kwartalna suma płatności > 25 000 EUR
- **Rezultat:** `cesop_quarterly_threshold_exceeded: true`, `_warning: "Płatności do kontrahenta przekroczyły próg CESOP w skali kwartału"`
- **Podstawa prawna:** Rozporządzenie 2020/284
- **Priorytet:** 157

---

### 5.3 ViDA — VAT in the Digital Age (P160-P165) — 3 nowe reguły

> **Stan przed:** ViDA (VAT in the Digital Age) — inicjatywa KE wprowadzająca cyfrowy VAT w czasie rzeczywistym, obowiązkowy e-invoicing i single VAT registration. W implementacji od 2026-2030.

#### P160: `vida_digital_vat_real_time_reporting`
- **Cel biznesowy:** ViDA — obowiązek raportowania transakcji VAT w czasie rzeczywistym (real-time digital reporting). Po implementacji ViDA, KSeF zostanie rozszerzone na wszystkie kraje UE.
- **Przesłanki:** `invoice.transaction_date >= vida_implementation_date` AND `is_vat_payer == true`
- **Rezultat:** `vida_real_time_reporting: true`, `reporting_deadline: "REAL_TIME"`, `_warning: "ViDA — transakcja VAT musi być raportowana w czasie rzeczywistym"`
- **Podstawa prawna:** Propozycja KE COM(2022)360 — ViDA Pillar 1
- **Priorytet:** 160
- **ŹRÓDŁO:** ViDA przyjęta przez Radę UE 11.03.2025, opublikowana w OJ UE 25.03.2025, weszła w życie 14.04.2025. Fazy: Pillar 1 (e-invoicing cross-border) — 01.07.2030; Pillar 2 (platform economy deemed supplier) — 01.07.2028; Pillar 3 (single VAT registration, rozszerzenie OSS/IOSS) — 01.07.2028. PL musi dostosować KSeF do standardu UE (EN 16931) do 01.01.2035

#### P161: `vida_single_vat_registration`
- **Cel biznesowy:** ViDA — pojedyncza rejestracja VAT w UE. JDG dokonujące sprzedaży do innych krajów UE nie muszą rejestrować się w każdym kraju osobno — wystarczy rejestracja w PL.
- **Przesłanki:** `invoice.direction == "SALE"` AND `vendor.country in EU_COUNTRIES` AND `vendor.is_b2b_buyer == true` AND `vida_single_registration_active == true`
- **Rezultat:** `single_vat_registration: true`, `vat_due_in_pl: true`, `no_foreign_vat_registration_required: true`
- **Podstawa prawna:** Propozycja KE COM(2022)360 — ViDA Pillar 2
- **Priorytet:** 161

#### P162: `vida_digital_vat_einvoicing_expansion`
- **Cel biznesowy:** ViDA — obowiązkowy e-invoicing (ustrukturyzowane faktury elektroniczne) we wszystkich krajach UE. KSeF PL staje się częścią europejskiego systemu.
- **Przesłanki:** `invoice.direction == "SALE"` AND `vendor.country in EU_COUNTRIES` AND `vida_einvoicing_active == true`
- **Rezultat:** `eu_einvoicing_required: true`, `format: "EN_16931"` (europejski standard), `_warning: "ViDA — faktura musi być wystawiona w europejskim formacie e-invoicing"`
- **Podstawa prawna:** Propozycja KE COM(2022)360 — ViDA Pillar 3
- **Priorytet:** 162

---

### 5.4 UK Post-Brexit Edge Cases (P170-P175) — 3 nowe reguły

> **Stan przed:** Brak szczegółowych reguł dla transakcji z UK po Brexicie (od 2021 UK jest krajem trzecim).

#### P170: `uk_post_brexit_goods_import`
- **Cel biznesowy:** Import towarów z UK do PL — UK jest krajem trzecim (non-EU) od 2021. Specjalizacja reguły P45 (`import_non_eu`) dla UK — dodatkowo uwzględnia cło i specyficzne umowy handlowe UK-UE.
- **Przesłanki:** `invoice.procedure == "IMPORT"` AND `vendor.country == "GB"`
- **Rezultat:** `procedure: "IMPORT_NON_EU"`, `vat_rate: "DOMESTIC_EQUIVALENT"`, `customs_duty_possible: true`, `_warning: "Import z UK — rozlicz VAT od importu + ewentualne cło"`
- **Podstawa prawna:** Art. 17 ust. 1 pkt 1 ustawy o VAT, ustawa o ceł
- **Zależności:** Specjalizacja P45 — w implementacji Rego, P170 musi być sprawdzona PRZED P45 (wyższy priorytet)
- **Priorytet:** 170

#### P171: `uk_post_brexit_services_export_b2b`
- **Cel biznesowy:** Eksport usług IT/konsultingowych do UK B2B — miejsce świadczenia = siedziba nabywcy (UK). Polski JDG nie nalicza VAT (reverse charge w UK).
- **Przesłanki:** `invoice.direction == "SALE"` AND `vendor.country == "GB"` AND `vendor.is_b2b_buyer == true` AND `invoice.type == "SERVICE"`
- **Rezultat:** `vat_rate: "0.00"` (NP — nie podlega opodatkowaniu w PL), `reverse_charge: true`, `_warning: "Usługi do UK B2B — VAT rozlicza nabywca w UK (reverse charge)"`
- **Podstawa prawna:** Art. 28b ustawy o VAT
- **Priorytet:** 171

#### P172: `uk_post_brexit_vat_registration_threshold`
- **Cel biznesowy:** JDG sprzedające towar cyfrowy do konsumentów w UK (B2C) — obowiązek rejestracji VAT w UK po przekroczeniu progu 90 000 GBP rocznie (Distance Selling UK).
- **Przesłanki:** `invoice.direction == "SALE"` AND `vendor.country == "GB"` AND `vendor.is_b2c == true` AND `jdg_entrepreneur.uk_b2c_annual_turnover_gbp > 90000`
- **Rezultat:** `uk_vat_registration_required: true`, `_warning: "Sprzedaż B2C do UK > 90 000 GBP — obowiązek rejestracji VAT w UK"`
- **Podstawa prawna:** UK VAT Act 1994, Distance Selling Regulations
- **Priorytet:** 172

---

### 5.5 E-Learning i Edukacja Cyfrowa (P590b-P595b) — 5 nowych reguł

> **Stan przed:** Brak specyficznych reguł dla JDG w e-learningu (kursy online, webinary, platformy LMS).

#### P590b: `elearning_vat_exemption_check`
- **Cel biznesowy:** Usługi e-learning — zwolnienie z VAT (Art. 43 ust. 1 pkt 29) tylko gdy finansowane ze środków publicznych. Komercyjne kursy online → 23% VAT.
- **Przesłanki:** `invoice.category_code in ["ELEARNING", "ONLINE_COURSE", "WEBINAR"]` AND `invoice.is_publicly_funded == false`
- **Rezultat:** `vat_rate: "0.23"` (komercyjne) lub `vat_rate: "0.00"` (finansowane publicznie), `vat_exemption: "OBJECT"` (jeśli finansowane)
- **Podstawa prawna:** Art. 43 ust. 1 pkt 26-29 ustawy o VAT
- **Priorytet:** 590b

#### P591b: `elearning_lump_sum_rate_8_5`
- **Cel biznesowy:** Ryczałt dla JDG w e-learningu — stawka 8.5% (PKWiU 85.59.B — nauka języków obcych, PKWiU 85.42 — edukacja)
- **Przesłanki:** `jdg_entrepreneur.tax_form == "LUMP_SUM"` AND `invoice.pkwiu_code in ["85.59", "85.42", "85.41"]`
- **Rezultat:** `pit_rate: "0.085"`, `lump_sum_rate: "8.5%"`
- **Podstawa prawna:** Art. 12 ust. 1 pkt 5 lit. a ustawy o ryczałcie
- **Priorytet:** 591b

#### P592b: `elearning_foreign_students_vat_exemption`
- **Cel biznesowy:** Kursy online dla studentów zagranicznych (UE B2C) — zwolnienie z VAT w PL, VAT rozlicza konsument w kraju swojego zamieszkania (OSS).
- **Przesłanki:** `invoice.direction == "SALE"` AND `vendor.country in EU_COUNTRIES` AND `vendor.is_b2c == true` AND `invoice.category_code == "ELEARNING"`
- **Rezultat:** `vat_rate: "0.00"` (NP — OSS), `oss_registration_required: true` (jeśli > 10 000 EUR)
- **Podstawa prawna:** Art. 28c ust. 1 ustawy o VAT (usługi elektroniczne B2C UE)
- **Priorytet:** 592b

#### P593b: `elearning_non_eu_students_zero_vat`
- **Cel biznesowy:** Kursy online dla studentów spoza UE (B2C non-EU) — miejsce świadczenia = kraj konsumenta. Polski JDG nie nalicza VAT.
- **Przesłanki:** `invoice.direction == "SALE"` AND `vendor.country == "NON_EU"` AND `vendor.is_b2c == true` AND `invoice.category_code == "ELEARNING"`
- **Rezultat:** `vat_rate: "0.00"` (NP), `place_of_supply: "NON_EU"`, `_warning: "E-learning dla non-EU B2C — VAT rozlicza konsument w swoim kraju"`
- **Podstawa prawna:** Art. 28c ust. 2 ustawy o VAT
- **Priorytet:** 593b

#### P594b: `elearning_platform_revenue_split`
- **Cel biznesowy:** JDG sprzedające kursy przez platformy (Udemy, Coursera, Skillshare) — podział przychodu między JDG a platformę. Prowizja platformy = import usług (reverse charge).
- **Przesłanki:** `invoice.is_platform_sale == true` AND `invoice.platform_fee_deducted > 0` AND `vendor.is_education_platform == true`
- **Rezultat:** `revenue_jdg: amount_gross - platform_fee`, `import_services: platform_fee` (reverse charge VAT), `_warning: "Sprzedaż przez platformę e-learning — prowizja = import usług"`
- **Podstawa prawna:** Art. 28b, Art. 17 ust. 1 pkt 4 ustawy o VAT
- **Priorytet:** 594b

---

### 5.6 Gig Economy i Freelancer Edge Cases (P595b-P599b) — 5 nowych reguł

> **Stan przed:** Brak specyficznych reguł dla JDG w gig economy (Uber, Bolt, Glovo, food delivery).

#### P595b: `gig_economy_rideshare_vat_classification`
- **Cel biznesowy:** JDG jako kierowca Uber/Bolt — usługi transportowe. VAT 8% (transport pasażerski krajowy). Jeśli obrót < 200 000 PLN → zwolnienie podmiotowe.
- **Przesłanki:** `jdg_entrepreneur.pkd_main in ["49.32.Z", "49.39.Z"]` AND `invoice.category_code == "RIDESHARE_SERVICE"`
- **Rezultat:** `vat_rate: "0.08"` (jeśli VAT-payer) lub `vat_rate: "0.00"` (zwolnienie podmiotowe), `transport_passenger: true`
- **Podstawa prawna:** Art. 41 ust. 2, Art. 113 ustawy o VAT
- **Priorytet:** 595b

#### P596b: `gig_economy_food_delivery_vat`
- **Cel biznesowy:** JDG jako dostawca jedzenia (Glovo, Wolt, Uber Eats) — usługa dostawy jedzenia. VAT 8% (jeśli posiłek) lub 23% (jeśli tylko dostawa kurierska).
- **Przesłanki:** `jdg_entrepreneur.pkd_main in ["53.20.Z", "56.21.Z"]` AND `invoice.category_code == "FOOD_DELIVERY"`
- **Rezultat:** `vat_rate: "0.08"` (gastronomia) lub `vat_rate: "0.23"` (usługa kurierska)
- **Podstawa prawna:** Art. 41 ust. 2 ustawy o VAT
- **Priorytet:** 596b

#### P597b: `gig_economy_platform_commission_import`
- **Cel biznesowy:** Prowizje pobierane przez platformy gig economy (Uber 25%, Glovo 30%) — import usług z platformy zagranicznej. JDG rozlicza VAT reverse charge od prowizji.
- **Przesłanki:** `vendor.is_gig_platform == true` AND `invoice.platform_fee_deducted > 0` AND `vendor.country != "PL"`
- **Rezultat:** `import_services: true`, `reverse_charge: true`, `vat_nalezny: platform_fee * 0.23`, `vat_naliczony: platform_fee * 0.23`
- **Podstawa prawna:** Art. 28b, Art. 17 ust. 1 pkt 4 ustawy o VAT
- **Priorytet:** 597b

#### P598b: `gig_economy_lump_sum_rate_8_5_transport`
- **Cel biznesowy:** Ryczałt dla JDG transportowych (taxi, dostawy) — stawka 8.5% (PKWiU 49-53)
- **Przesłanki:** `jdg_entrepreneur.tax_form == "LUMP_SUM"` AND `invoice.pkwiu_code in ["49", "50", "51", "52", "53"]`
- **Rezultat:** `pit_rate: "0.085"`
- **Podstawa prawna:** Art. 12 ust. 1 pkt 5 lit. a ustawy o ryczałcie
- **Priorytet:** 598b

#### P599b: `gig_economy_mileage_tracking_obligation`
- **Cel biznesowy:** JDG używające pojazdu do celów gig economy — obowiązek prowadzenia ewidencji przebiegu pojazdu dla 100% KUP i 100% VAT. Bez ewidencji → 75% KUP i 50% VAT.
- **Przesłanki:** `jdg_entrepreneur.pkd_main in ["49.32.Z", "53.20.Z"]` AND `invoice.category_code == "CAR"` AND `invoice.has_mileage_log == false`
- **Rezultat:** `kus_percent: 75`, `vat_deduction_percent: 50`, `_warning: "Brak ewidencji przebiegu — ograniczenie KUP 75% i VAT 50%"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 46 PIT, Art. 86a VAT
- **Priorytet:** 599b

---

### 5.7 ESG / CSRD / AI Act (P1800-P1825) — 5 nowych reguł

> **Stan przed:** Dokument 28 wprowadził MDR/ESG/AI Act jako koncepcje. Tutaj dodajemy implementacyjne reguły.

#### P1800: `mdr_reportable_scheme_detection`
- **Cel biznesowy:** Wykrycie schematów podatkowych MDR (Mandatory Disclosure Rules). JDG korzystające z agresywnych optymalizacji.
- **Przesłanki:** Transakcja z rajem podatkowym LUB struktura transgraniczna hybrydowa LUB wynagrodzenie success fee
- **Rezultat:** `mdr_reportable: true`, `mdr_form: "MDR-1"`, `mdr_deadline: "30_dni"`, `_warning: "Schemat MDR — obowiązek raportowania. Kary do 5 mln PLN."`
- **Podstawa prawna:** Art. 86a-86o Ordynacji podatkowej
- **Priorytet:** 1800
- **ŹRÓDŁO:** Art. 86a-86o Ordynacji podatkowej (Rozdział 11a). Cechy rozpoznawcze: ogólne (11 cech, Art. 86a § 1 pkt 6 a-k — poufność, opłaty warunkowe, standaryzacja, transakcje okrężne), szczególne (9 cech, Art. 86a § 1 pkt 13 a-i — płatności transgraniczne, hybrydowe niedopasowania, transfer aktywów), inne szczególne (4 cechy, Art. 86a § 1 pkt 1 a-d — progi odroczonego podatku, WHT). Formularze: MDR-1, MDR-2, MDR-3, MDR-4. Portal: mdr.mf.gov.pl

#### P1810: `esg_csrd_supplier_obligation`
- **Cel biznesowy:** JDG będące dostawcą firmy podlegającej CSRD — obowiązek raportowania wskaźników ESG
- **Przesłanki:** `jdg_entrepreneur.is_csrd_supplier == true` AND kontrahent podlega CSRD
- **Rezultat:** `esg_data_required: true`, `esg_metrics: ["CO2", "energy", "waste"]`
- **Priorytet:** 1810

#### P1820: `ai_act_jdg_system_classification`
- **Cel biznesowy:** JDG rozwijające systemy AI — klasyfikacja ryzyka wg AI Act (unacceptable/high/limited/minimal)
- **Przesłanki:** `jdg_entrepreneur.pkd_main in ["62.01.Z", "62.02.Z"]` AND `invoice.service_type == "AI_SYSTEM_DEVELOPMENT"`
- **Rezultat:** `ai_act_risk_category: "LIMITED" | "HIGH" | "MINIMAL"`, `ai_act_registration_required: true` (dla HIGH)
- **Priorytet:** 1820
- **ŹRÓDŁO:** Regulation (EU) 2024/1689 — AI Act, opublikowany w OJ UE 12.07.2024, wszedł w życie 01.08.2024. Pełne zastosowanie większości przepisów: 02.08.2026. Kategorie ryzyka: unacceptable (zakazane od 02.02.2025), high (obowiązki od 02.08.2026 — ocena zgodności, dokumentacja techniczna, CE), limited (obowiązek transparentności), minimal (brak wymogów). GPAI modele: obowiązki od 02.08.2025

#### P1821: `ai_act_high_risk_obligations`
- **Cel biznesowy:** JDG rozwijające systemy AI wysokiego ryzyka — obowiązek oceny zgodności, dokumentacji technicznej, rejestracji w bazie UE
- **Przesłanki:** `ai_act_risk_category == "HIGH"`
- **Rezultat:** `ai_act_conformity_assessment: true`, `ai_act_technical_documentation: true`, `ai_act_ce_marking: true`
- **Priorytet:** 1821

#### P1822: `ai_act_transparency_obligations`
- **Cel biznesowy:** JDG używające AI do generowania treści — obowiązek oznaczania treści AI-generated (deepfakes, AI content)
- **Przesłanki:** `jdg_entrepreneur.uses_ai_content_generation == true` AND `invoice.category_code == "AI_GENERATED_CONTENT"`
- **Rezultat:** `ai_transparency_label_required: true`, `_warning: "Treści generowane przez AI muszą być oznaczone"`
- **Priorytet:** 1822

---

### 5.8 API Integration & Graceful Degradation (P1850-P1855) — 5 nowych reguł

> **Stan przed:** Brak reguł dla awarii API zewnętrznych (Biała Lista, CEIDG, KSeF, GUS). System powinien gracefully degrade, nie crash.

#### P1850: `api_whitelist_graceful_degradation`
- **Cel biznesowy:** Gdy API Białej Listy MF niedostępne → oznacz fakturę jako "pending verification", nie blokuj automatycznie. Cache 30 dni.
- **Przesłanki:** `vendor.whitelist_status == "UNKNOWN"` AND `vendor.whitelist_check_expired == true` AND `vendor.whitelist_checked_at` > 30 dni temu
- **Rezultat:** `_routing: "TRIAGE_QUEUE"`, `_warning: "Biała Lista MF niedostępna — faktura wstrzymana do weryfikacji manualnej"`, `whitelist_check_retry: true`
- **Priorytet:** 1850

#### P1851: `api_ceidg_graceful_degradation`
- **Cel biznesowy:** Gdy API CEIDG niedostępne → oznacz status kontrahenta jako "UNKNOWN", dodaj warning, nie blokuj (chyba że fraud_flag)
- **Przesłanki:** `vendor.ceidg_status == "UNKNOWN"` AND `vendor.fraud_flag == false`
- **Rezultat:** `_warning: "CEIDG niedostępne — status kontrahenta niezweryfikowany"`, `ceidg_check_retry: true`
- **Priorytet:** 1851

#### P1852: `api_ksef_graceful_degradation`
- **Cel biznesowy:** Gdy KSeF offline → tryb awaryjny (7 dni na wysyłkę). Faktury wystawiane offline z sufiksem /OFFLINE.
- **Przesłanki:** `system.ksef_status == "OFFLINE"`
- **Rezultat:** `ksef_offline_mode: true`, `ksef_submission_deadline_days: 7`, `invoice_suffix: "/OFFLINE"`
- **Podstawa prawna:** Art. 106ne ustawy o VAT
- **Priorytet:** 1852

#### P1853: `api_gus_graceful_degradation`
- **Cel biznesowy:** Gdy API GUS BIR niedostępne → użyj danych z faktury (vendor.nip, vendor.name), oznacz jako "pending GUS verification"
- **Przesłanki:** `vendor.gus_verified == false` AND `vendor.nip != ""`
- **Rezultat:** `_warning: "GUS BIR niedostępne — dane kontrahenta z faktury, weryfikacja pending"`, `gus_check_retry: true`
- **Priorytet:** 1853

#### P1854: `api_nbp_rate_fallback`
- **Cel biznesowy:** Gdy API NBP (kursy walut) niedostępne → użyj ostatniego znanego kursu (cache) z ostrzeżeniem. Nie blokuj transakcji walutowej.
- **Przesłanki:** `invoice.currency != "PLN"` AND `nbp_rate_available == false` AND `nbp_rate_cached == true`
- **Rezultat:** `fx_rate: cached_rate`, `fx_rate_source: "CACHED"`, `fx_rate_date: cached_date`, `_warning: "NBP niedostępne — użyto kursu z cache (data: X)"`
- **Priorytet:** 1854

---

### 5.9 Audit Trail & Compliance Automation (P1860-P1865) — 5 nowych reguł

> **Stan przed:** Brak reguł dla automatyzacji audytu i compliance (auto-korekty, auto-flagi).

#### P1860: `audit_trail_completeness_check`
- **Cel biznesowy:** Weryfikacja czy każda decyzja OPA ma kompletny audit trail (rule_id, legal_basis, timestamp, input_hash)
- **Przesłanki:** `verdict.audit_trail_complete == false` (brak rule_id LUB legal_basis LUB timestamp)
- **Rezultat:** `_routing: "TRIAGE_QUEUE"`, `_warning: "Niekompletny audit trail — decyzja nieaudytowalna"`
- **Priorytet:** 1860

#### P1861: `auto_correction_suggestion_engine`
- **Cel biznesowy:** Automatyczne sugerowanie korekt gdy OPA wykryje rozbieżności (np. stawka VAT na fakturze vs katalog NexusAI)
- **Przesłanki:** `invoice.vat_rate != verdict.vat_rate` AND `verdict.confidence > 0.90`
- **Rezultat:** `auto_correction_suggested: true`, `suggested_vat_rate: verdict.vat_rate`, `correction_reason: "Katalog NexusAI sugeruje stawkę X"`
- **Priorytet:** 1861

#### P1862: `compliance_score_calculation`
- **Cel biznesowy:** Obliczenie compliance score JDG — suma: whitelist checks (30%), KSeF compliance (20%), ZUS timeliness (20%), PIT advances (20%), VAT declarations (10%). Score < 0.70 → alert.
- **Przesłanki:** `jdg_entrepreneur.compliance_score < 0.70`
- **Rezultat:** `compliance_alert: true`, `compliance_score: <value>`, `_warning: "Niski compliance score — ryzyko kontroli skarbowej"`
- **Priorytet:** 1862

#### P1863: `auto_flag_high_risk_transaction`
- **Cel biznesowy:** Automatyczne oznaczanie transakcji wysokiego ryzyka (kwota > 50 000 PLN + nowy kontrahent + gotówka)
- **Przesłanki:** `invoice.amount_gross > 50000` AND `vendor.is_new == true` AND `invoice.is_cash_payment == true`
- **Rezultat:** `high_risk_flag: true`, `_routing: "TRIAGE_QUEUE"`, `_warning: "Transakcja wysokiego ryzyka — wymagana weryfikacja manualna"`
- **Priorytet:** 1863

#### P1864: `regulatory_change_impact_assessment`
- **Cel biznesowy:** Gdy thresholds zmienione (hot-reload) → automatyczna ocena wpływu na historyczne decyzje. Flag: "X decyzji podlega weryfikacji pod nowe przepisy".
- **Przesłanki:** `thresholds.updated_at > last_evaluation_timestamp` AND `thresholds.legal_impact == "RETROACTIVE"`
- **Rezultat:** `regulatory_change_impact: true`, `affected_decisions_count: <N>`, `_warning: "Zmiana przepisów — N decyzji wymaga weryfikacji"`
- **Priorytet:** 1864

---

### 5.10 Conflict Resolution & Multi-Domain Coherence (P1870-P1875) — 5 nowych reguł

> **Stan przed:** Brak reguł rozwiązywania konfliktów między passami OPA (np. VAT mówi 23%, PIT mówi zwolnienie).

#### P1870: `conflict_vat_vs_pit_exemption`
- **Cel biznesowy:** Gdy VAT zwolniony (Art. 113) ale PIT ma zastosowanie → oznacz, że faktura bez VAT ale przychód podlega PIT
- **Przesłanki:** `verdict.vat_exemption == "SUBJECT"` AND `verdict.pit_form != ""`
- **Rezultat:** `domain_conflict_resolved: true`, `vat_exempt_pit_applicable: true`, `_info: "Zwolnienie VAT podmiotowe — przychód nadal podlega PIT"`
- **Priorytet:** 1870

#### P1871: `conflict_kup_vs_vat_deduction`
- **Cel biznesowy:** Gdy KUP = "none" (reprezentacja) ale VAT deduction = 50% (auto) → KUP ma pierwszeństwo, VAT też blokowany (reprezentacja = NKUP i brak odliczenia VAT)
- **Przesłanki:** `verdict.kus_qualification == "none"` AND `verdict.vat_deduction_percent > 0` AND `invoice.expense_type == "REPRESENTATION"`
- **Rezultat:** `vat_deduction_override: 0`, `_warning: "Reprezentacja — brak KUP i brak odliczenia VAT"`
- **Priorytet:** 1871

#### P1872: `conflict_suspension_vs_zus`
- **Cel biznesowy:** Gdy business_status = SUSPENDED ale ZUS mówi "due" → zawieszenie ma pierwszeństwo (brak ZUS w zawieszeniu)
- **Przesłanki:** `jdg_entrepreneur.business_status == "SUSPENDED"` AND `verdict.zus_social_due == true`
- **Rezultat:** `zus_social_due: false`, `zus_health_due: false`, `_info: "Zawieszenie działalności — brak składek ZUS"`
- **Priorytet:** 1872

#### P1873: `conflict_lump_sum_vs_kup`
- **Cel biznesowy:** Gdy tax_form = LUMP_SUM ale KUP qualification = "full" → ryczałt NIE ma KUP, override KUP na "none"
- **Przesłanki:** `jdg_entrepreneur.tax_form == "LUMP_SUM"` AND `verdict.kus_qualification == "full"`
- **Rezultat:** `kus_qualification: "none"`, `_warning: "Ryczałt — brak KUP (podatek od przychodu, nie dochodu)"`
- **Priorytet:** 1873

#### P1874: `conflict_succession_vs_personal_liability`
- **Cel biznesowy:** Gdy in_succession = true ale liability = "UNLIMITED_PERSONAL" → zarządca sukcesyjny odpowiada, nie spadkobiercy osobistości
- **Przesłanki:** `jdg_entrepreneur.in_succession == true` AND `verdict.liability_scope == "UNLIMITED_PERSONAL_PROPERTY"`
- **Rezultat:** `liability_scope: "SUCCESSION_MANAGER"`, `responsible_party: "SUCCESSION_MANAGER"`
- **Priorytet:** 1874

---

### 5.11 Polish Deal (Polski Ład) Edge Cases (P1880-P1885) — 5 nowych reguł

> **Stan przed:** Polski Ład wprowadził wiele zmian (kwota wolna 30k, składka zdrowotna 9%/4.9%, brak odliczenia zdrowotnej przy skali). Brak dedykowanych reguł walidacji.

#### P1880: `polish_lad_health_contribution_no_deduction_scale`
- **Cel biznesowy:** Polski Ład — przy skali podatkowej składka zdrowotna 9% NIE podlega odliczeniu ani od podatku, ani jako KUP. **Semantyka pogrupowana — w implementacji Rego autorytatywna jest P738 (`scale_health_deduction_prohibition`).**
- **Przesłanki:** `jdg_entrepreneur.tax_form == "PIT_SCALE"` AND `invoice.expense_type == "ZUS_HEALTH_ENTREPRENEUR"`
- **Rezultat:** `kus_qualification: "none"`, `tax_deduction_prohibited: true`
- **Podstawa prawna:** Polski Ład — uchylony art. 27b PIT
- **Zależności:** Implementacyjnie = P738 — nie duplikować w `.rego`
- **Priorytet:** 1880

#### P1881: `polish_lad_tax_free_amount_30k_calculation`
- **Cel biznesowy:** Kwota wolna 30 000 PLN — pomniejszenie podatku o 3 600 PLN (30 000 × 12%). Wygasanie kwoty wolnej przy dochodzie > 120 000 PLN.
- **Przesłanki:** `jdg_entrepreneur.tax_form == "PIT_SCALE"` AND `cumulative_income_current_year <= 120000`
- **Rezultat:** `tax_free_amount: 30000`, `tax_reduction: 3600`, `tax_free_reduction_formula: "30000 * 0.12"`
- **Podstawa prawna:** Art. 27 ust. 1a PIT
- **Priorytet:** 1881

#### P1882: `polish_lad_health_lump_sum_tiers`
- **Cel biznesowy:** Ryczałt — 3 progi składki zdrowotnej: ≤ 60 000 PLN (60% śr. wynagr.), 60k-300k (100%), > 300k (180%)
- **Przesłanki:** `jdg_entrepreneur.tax_form == "LUMP_SUM"` AND `lump_sum_annual_revenue <= 60000`
- **Rezultat:** `health_tier: 1`, `health_base_percent: 0.60`, `health_base: 0.60 * average_wage`
- **Podstawa prawna:** Art. 81 ust. 2a-2c u.ś.o.z.
- **Priorytet:** 1882

#### P1883: `polish_lad_loss_one_time_5m_option`
- **Cel biznesowy:** Od 2025 — jednorazowe odliczenie straty do 5 000 000 PLN (alternatywa do 50% rocznie przez 5 lat)
- **Przesłanki:** `jdg_entrepreneur.has_loss_carry_forward == true` AND `jdg_entrepreneur.loss_one_time_election == true`
- **Rezultat:** `loss_deduction_one_time: min(5000000, loss_remaining)`, `loss_method: "ONE_TIME_5M"`
- **Podstawa prawna:** Art. 9 ust. 3 pkt 2 PIT
- **Priorytet:** 1883

#### P1884: `polish_lad_residential_depreciation_ban`
- **Cel biznesowy:** Zakaz amortyzacji budynków mieszkalnych nabytych po 2022 roku (Polski Ład). **Semantyka pogrupowana — w implementacji Rego autorytatywna jest P847 (`real_estate_residential_depreciation_ban`).**
- **Przesłanki:** `expense_type == "REAL_ESTATE_DEPRECIATION"` AND `real_estate_type == "RESIDENTIAL"` AND `building_year >= 2023`
- **Rezultat:** `depreciation_allowed: false`, `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 22c pkt 2 PIT
- **Zależności:** Implementacyjnie = P847 — nie duplikować w `.rego`
- **Priorytet:** 1884

---

### 5.12 Zbiegi i Interakcje Specjalne (P1890-P1895) — 5 nowych reguł

#### P1890: `concurrent_multiple_jdg_health_calculation`
- **Cel biznesowy:** Gdy przedsiębiorca prowadzi więcej niż jedną JDG — składka zdrowotna liczona raz (najwyższa podstawa), składki społeczne liczone raz (najwyższa podstawa)
- **Przesłanki:** `jdg_entrepreneur.concurrent_jdg_count > 1`
- **Rezultat:** `zus_health_single_payment: true`, `zus_social_single_payment: true`, `zus_base: highest_declared_base`
- **Podstawa prawna:** Art. 9 ust. 4 ustawy o SUS
- **Priorytet:** 1890

#### P1891: `concurrent_jdg_and_spouse_jdg_separate`
- **Cel biznesowy:** Małżonek też prowadzi JDG — każdy płaci ZUS osobno, ale wspólność majątkowa wpływa na odpowiedzialność
- **Przesłanki:** `jdg_entrepreneur.spouse_has_jdg == true`
- **Rezultat:** `spouse_jdg_separate_zus: true`, `joint_liability_for_taxes: true` (jeśli wspólność majątkowa)
- **Podstawa prawna:** Art. 29 Ordynacji podatkowej
- **Priorytet:** 1891

#### P1892: `foreign_tax_credit_vs_abolition_relief_interaction`
- **Cel biznesowy:** Gdy JDG ma dochód zagraniczny — wybór między metodą wyłączenia z progresją (ulga abolicyjna) a metodą odliczenia proporcjonalnego
- **Przesłanki:** `jdg_entrepreneur.foreign_income > 0` AND `jdg_entrepreneur.tax_treaty_method != ""`
- **Rezultat:** `foreign_tax_method: "proportional_deduction" | "exemption_with_progression"`, `abolition_relief_applicable: true` (jeśli metoda odliczenia)
- **Podstawa prawna:** Art. 27g, Art. 30a ust. 5-6 PIT
- **Priorytet:** 1892

#### P1893: `voluntary_health_insurance_additional`
- **Cel biznesowy:** JDG może opłacać dodatkowe dobrowolne ubezpieczenie zdrowotne (Luxmed, Medicover) — to KUP (Art. 22 PIT), ale NIE odlicza się od podatku
- **Przesłanki:** `invoice.expense_type == "VOLUNTARY_HEALTH_INSURANCE"` AND `invoice.is_work_related == true`
- **Rezultat:** `kus_qualification: "full"`, `tax_deduction: false`, `_info: "Dodatkowe ubezpieczenie zdrowotne — KUP, ale nie odliczenie od podatku"`
- **Podstawa prawna:** Art. 22 ust. 1 PIT
- **Priorytet:** 1893

#### P1894: `tax_office_correspondence_electronic_mandatory`
- **Cel biznesowy:** Od 2026 — obowiązkowa elektroniczna korespondencja z US (e-Urząd Skarbowy). Brak papieru.
- **Przesłanki:** `invoice.transaction_date >= "2026-01-01"` AND `jdg_entrepreneur.has_e_us_account == false`
- **Rezultat:** `e_us_registration_required: true`, `_warning: "Obowiązek rejestracji w e-Urzędzie Skarbowym od 2026"`
- **Podstawa prawna:** Art. 75 § 1 Ordynacji podatkowej (nowelizacja)
- **Priorytet:** 1894

#### P1895: `real_time_tax_monitoring_alert`
- **Cel biznesowy:** KSeF + ViDA umożliwiają real-time monitoring — alert gdy narastający VAT > 50 000 PLN miesięcznie (ryzyko kontroli)
- **Przesłanki:** `jdg_entrepreneur.monthly_vat_cumulative > 50000` AND `jdg_entrepreneur.under_tax_audit == false`
- **Rezultat:** `real_time_monitoring_alert: true`, `_warning: "Wysoki narastający VAT — podwyższone ryzyko kontroli real-time"`
- **Priorytet:** 1895

---

## 6. Wymagane Dane Wejściowe

### 6.1 Pełna Struktura `input` dla JDG ENTERPRISE

Struktura `input` rozszerza specyfikację z `01_INPUT_SPEC.md` o sekcje specyficzne dla JDG. Wszystkie wartości liczbowe (stawki, progi, limity) pochodzą z `input.thresholds.jdg.*` — ZERO hardcoded values w `.rego`.

```json
{
  "invoice": {
    "transaction_date": "2026-06-15",
    "category_code": "IT_OFFICE",
    "amount_net": 10000.00,
    "amount_gross": 12300.00,
    "currency": "PLN",
    "direction": "PURCHASE",
    "expense_type": "OPERATIONAL",
    "pkwiu_code": "62.01.12.0",
    "is_cash_payment": false,
    "is_paid": false,
    "days_overdue": 0,
    "procedure": "",
    "is_continuous_service": false,
    "invoice_type": "",
    "private_use_percent": 0,
    "is_home_office": false,
    "home_office_area_percent": 0,
    "is_correction": false,
    "correction_type": "",
    "has_buyer_agreement": false,
    "is_personal_expense": false,
    "vat_taxable": true,
    "is_vat_deducted": false,
    "months_since_issue": 0,
    "delivery_date": "2026-06-10",
    "payment_method": "BANK_TRANSFER",
    "is_platform_sale": false,
    "platform_fee_deducted": 0,
    "is_app_store_sale": false,
    "is_excise_duty_event": false,
    "excise_goods_type": "",
    "car_is_electric": false,
    "has_mileage_log": true,
    "real_estate_type": "",
    "building_year": 0,
    "is_spoiled_goods": false,
    "has_disposal_protocol": false,
    "is_contractual_penalty": false,
    "is_workwear_bhp": false,
    "foreign_trip_country": "",
    "foreign_trip_days": 0
  },
  "vendor": {
    "nip": "1234567890",
    "country": "PL",
    "vat_status": "active",
    "on_whitelist": true,
    "account_on_whitelist": true,
    "whitelist_checked_at": "2026-06-15T10:00:00Z",
    "whitelist_status": "VERIFIED",
    "ceidg_status": "ACTIVE",
    "pkd": "62.01.Z",
    "is_related_party": false,
    "trust_score": 0.92,
    "fraud_flag": false,
    "is_new": false,
    "is_b2b_buyer": false,
    "is_b2c": false,
    "is_app_store_platform": false,
    "is_freelance_platform": false,
    "is_gig_platform": false,
    "is_family_foundation": false,
    "is_flat_rate_farmer": false,
    "is_education_platform": false,
    "is_ngo": false,
    "is_religious_org": false,
    "gus_verified": true
  },
  "jdg_entrepreneur": {
    "nip": "9876543210",
    "tax_form": "PIT_SCALE",
    "is_vat_payer": true,
    "is_vat_eu_registered": false,
    "annual_turnover_net": 180000.00,
    "cumulative_income_current_year": 85000.00,
    "is_small_taxpayer": true,
    "uses_quarterly_advances": false,
    "business_status": "ACTIVE",
    "zus_status": "STANDARD",
    "zus_months_used_current_status": 12,
    "uses_pkpir": true,
    "ceidg_entry_date": "2020-03-01",
    "pkd_main": "62.01.Z",
    "age": 36,
    "children_count": 0,
    "joint_filing": false,
    "has_employment_contract": false,
    "concurrent_jdg_count": 1,
    "has_loss_carry_forward": false,
    "has_rd_status": false,
    "has_family_foundation": false,
    "has_foreign_crypto_accounts": false,
    "b2c_annual_turnover_for_fiscal": 0,
    "uk_b2c_annual_turnover_gbp": 0,
    "is_nft_creator": false,
    "is_unregistered_activity": false,
    "in_succession": false,
    "compliance_score": 0.85,
    "has_e_us_account": true,
    "sells_on_platforms": false,
    "annual_cross_border_eur": 0
  },
  "confidence": {
    "fc_minimum": 0.95,
    "fc_vat_rate": 0.98,
    "fc_total_net": 0.97,
    "fc_vendor_nip": 0.99,
    "fc_category_code": 0.96
  },
  "document": {
    "evaluation_date": null,
    "type": "",
    "audit_in_progress": false,
    "kks_proceedings_started": false
  },
  "system": {
    "ksef_status": "ONLINE",
    "auth_token_exists": true,
    "qualified_signature_exists": true
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
        "pit_crypto": "0.19",
        "zus_pension": "0.1952",
        "zus_disability": "0.08",
        "zus_sickness": "0.0245",
        "zus_accident": "0.0167",
        "zus_health_scale": "0.09",
        "zus_health_linear_lump": "0.049",
        "zus_labour_fund": "0.0245",
        "zus_fgsp": "0.001",
        "tax_interest_rate": "0.145",
        "tax_interest_penalty_mult": 1.5,
        "prolongation_fee": "0.50",
        "wht_standard": "0.20",
        "wht_reduced": "0.10",
        "pcc_standard": "0.02",
        "pcc_loan": "0.005",
        "tp_safe_harbour_markup": "0.05"
      },
      "limits": {
        "mpp_limit": 15000,
        "vat_exemption_limit": 200000,
        "cash_transaction_limit": 15000,
        "bad_debt_days_vat": 150,
        "bad_debt_days_cit_pit": 90,
        "retention_years_invoice": 5,
        "retention_years_pkpir": 5,
        "retention_years_payroll": 10,
        "trust_auto_post": 0.92,
        "trust_suggest": 0.75,
        "car_value_kup_limit": 150000,
        "electric_car_kup_limit": 225000,
        "cash_register_exemption_limit": 20000,
        "simplified_receipt_limit": 450,
        "small_mandate_limit": 200,
        "statute_years_tax": 5,
        "statute_years_zus": 5,
        "vat_deduction_months": 3,
        "vat_refund_standard_days": 60,
        "vat_refund_fast_days": 25,
        "vat_refund_extended_days": 180,
        "cesop_threshold_eur": 25000,
        "wst_union_threshold_eur": 10000,
        "uk_distance_selling_threshold_gbp": 90000,
        "de_minimis_3y_threshold_eur": 300000,
        "crypto_foreign_account_reporting_pln": 200000,
        "one_off_depreciation_limit_eur": 50000,
        "loss_deduction_one_time_limit": 5000000,
        "succession_max_months": 24,
        "suspension_max_months": 24,
        "copyright_kup_annual_limit": 60000,
        "employee_mileage_rate_per_km": 1.15,
        "employee_mileage_rate_over_900": 1.38
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
        "donation_limit_percent": 6,
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
        "lump_sum_annual_limit_eur": 2000000,
        "real_estate_depreciation_rate": 0.025,
        "real_estate_depreciation_period_years": 40
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
        "rate_8_5": { "value": "0.085", "pkwiu_codes": ["01-39", "45-99"] },
        "rate_5_5": { "value": "0.055", "pkwiu_codes": ["41-43", "64-66"] },
        "rate_3": { "value": "0.03", "pkwiu_codes": ["10-33", "56"] },
        "rate_2": { "value": "0.02", "pkwiu_codes": ["01-03"] }
      },
      "eu_countries": ["AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE"]
    }
  }
}
```

### 6.2 Pola Absolutnie Wymagane

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

### 6.3 Nowe Pola — Wprowadzone w Tym Dokumencie

| Sekcja | Nowe pole | Typ | Opis |
|--------|----------|-----|------|
| `invoice` | `payment_method` | `string` | Metoda płatności (CESOP): CARD, SEPA, TARGET2, BLIK, CRYPTO |
| `invoice` | `is_platform_sale` | `boolean` | Czy sprzedaż przez platformę |
| `invoice` | `is_excise_duty_event` | `boolean` | Czy zdarzenie akcyzowe |
| `invoice` | `has_mileage_log` | `boolean` | Czy prowadzona ewidencja przebiegu |
| `invoice` | `foreign_trip_country` | `string` | Kraj podróży służbowej (diety) |
| `jdg_entrepreneur` | `has_foreign_crypto_accounts` | `boolean` | Posiada konta krypto za granicą |
| `jdg_entrepreneur` | `concurrent_jdg_count` | `number` | Liczba równolegle prowadzonych JDG |
| `jdg_entrepreneur` | `annual_cross_border_eur` | `number` | Roczna wartość transakcji UE (CESOP) |
| `jdg_entrepreneur` | `compliance_score` | `number` | Wynik compliance (0-1) |
| `jdg_entrepreneur` | `has_e_us_account` | `boolean` | Rejestracja e-Urząd Skarbowy |
| `jdg_entrepreneur` | `is_nft_creator` | `boolean` | Czy twórca NFT |
| `vendor` | `is_gig_platform` | `boolean` | Czy platforma gig economy |
| `vendor` | `is_education_platform` | `boolean` | Czy platforma e-learning |
| `vendor` | `gus_verified` | `boolean` | Czy zweryfikowano w GUS BIR |
| `thresholds.jdg` | `rates.pit_crypto` | `string` | Stawka PIT dla krypto (19%) |
| `thresholds.jdg` | `limits.cesop_threshold_eur` | `number` | Próg CESOP 25 000 EUR |
| `thresholds.jdg` | `limits.uk_distance_selling_threshold_gbp` | `number` | Próg UK B2C 90 000 GBP |
| `thresholds.jdg` | `limits.crypto_foreign_account_reporting_pln` | `number` | Próg raportowania krypto 200 000 PLN |

---

## 7. Obsługa Parametrów Dynamicznych

### 7.1 Architektura Thresholds

Wszystkie progi, stawki i limity przechowywane w **DuckDB** w tabeli `jdg_thresholds`:

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

### 7.2 Hot-Reload Mechanism

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

### 7.3 Temporalność — Time-Travel

Przy budowaniu `input` dla OPA, Python wybiera thresholdy obowiązujące w `input.invoice.transaction_date`:

```python
def get_jdg_thresholds_for_date(conn, transaction_date: str) -> dict:
    rows = conn.execute("""
        SELECT threshold_key, threshold_value
        FROM jdg_thresholds
        WHERE valid_from <= ?
          AND (valid_to IS NULL OR valid_to >= ?)
    """, [transaction_date, transaction_date]).fetchall()
    # Konwersja na zagnieżdżony JSON
    ...
```

### 7.4 Kompletny Katalog ~200 Parametrów

Pełny katalog parametrów (`rates.*`, `limits.*`, `bounds.*`, `fc_thresholds.*`, `lump_sum_rates.*`) znajduje się w sekcji 6.1 powyżej oraz w dokumentach 22 i 28. Łącznie: ~200 parametrów dynamicznych.

---

## 8. Macierze Interakcji Międzyregulacyjnych

### 8.1 Macierz: Forma opodatkowania → Składka zdrowotna → KUP → Ulgi

| Forma PIT | Składka zdrow. | Odliczenie zdrow. | KUP | Ulgi B+R | Ulgi osobiste | Strata |
|-----------|:-------------:|:-----------------:|:---:|:--------:|:-------------:|:------:|
| **PIT_SCALE** | 9% dochodu | ❌ NIE | ✅ Pełny KUP | ✅ TAK | ✅ TAK | ✅ 5 lat |
| **LINEAR** | 4.9% dochodu | ✅ 12 900 PLN | ✅ Pełny KUP | ✅ TAK | ❌ NIE | ✅ 5 lat |
| **LUMP_SUM** | Progi (60k/300k) | ❌ NIE | ❌ BRAK KUP | ❌ NIE | ❌ NIE | ❌ NIE |
| **TAX_CARD** | 9% min. wyn. | ❌ NIE | ❌ BRAK KUP | ❌ NIE | ❌ NIE | ❌ NIE |

### 8.2 Macierz: Status JDG → VAT → PIT → ZUS

| Status | VAT deklaracje | PIT zaliczki | ZUS społeczne | ZUS zdrowotne | PKPiR |
|--------|:-------------:|:------------:|:-------------:|:-------------:|:-----:|
| **ACTIVE** | ✅ Tak (jeśli VAT) | ✅ Tak | ✅ Tak | ✅ Tak | ✅ Tak |
| **SUSPENDED** | ✅ Zerowe | ❌ Nie | ❌ Nie | ❌ Nie | ❌ Nie |
| **IN_SUCCESSIO** | ✅ Tak (kontynuacja) | ✅ Tak | ✅ Tak | ✅ Tak | ✅ Tak |
| **CLOSED** | ❌ VAT-Z | ❌ Zeznanie końcowe | ❌ Wyrejestrowanie | ❌ Ustaje | ❌ Zamknięcie |

### 8.3 Macierz: Konflikty Między-Domenowe (NOWE)

| Konflikt | Domena A | Domena B | Rozstrzygnięcie |
|----------|----------|----------|----------------|
| VAT zwolniony + PIT ma zastosowanie | VAT (P58) | PIT (P500) | Oba — faktura bez VAT, przychód podlega PIT |
| Reprezentacja KUP=none + VAT=50% | PIT KUP (P566) | VAT deduction (P186) | KUP ma pierwszeństwo — VAT też blokowany |
| Zawieszenie + ZUS due | Business (P910) | ZUS (P700) | Zawieszenie ma pierwszeństwo — brak ZUS |
| Ryczałt + KUP=full | PIT (P520) | KUP (P560) | Ryczałt ma pierwszeństwo — KUP=none |
| Sukcesja + odpowiedzialność osobista | Business (P920) | Liability (P1158) | Sukcesja — zarządca odpowiada |

---

## 9. Plan Wdrożenia ENTERPRISE

### 9.1 Fazy Wdrożenia

| Faza | Opis | Reguły | Czas |
|------|------|:------:|:----:|
| **Faza 0** (MVP) | Risk + Routing + Compliance + Crossborder + VAT podstawowy | ~70 | 2 tyg |
| **Faza 1** (CORE) | PIT formy + KUP + zaliczki + ZUS podstawowy + Business cycle | ~80 | 3 tyg |
| **Faza 2** (ADVANCED) | Ulgi + Leasing + Korekty + Przedawnienia + Reprezentacja + KSeF/JPK | ~70 | 3 tyg |
| **Faza 3** (ENTERPRISE CORE) | KKS/GAAR + Podatki lokalne + VAT szczegółowy + ZUS interakcje + Pracodawca | ~80 | 4 tyg |
| **Faza 4** (ENTERPRISE DEEP) | WHT + TP + Środowisko + Restrukturyzacja + Temporalne + MDR + ESG | ~72 | 4 tyg |
| **Faza 5** (NOWE — v9.0) | Krypto + CESOP + ViDA + UK + E-learning + Gig economy + AI Act + API fallback | ~56 | 4 tyg |
| **RAZEM** | | **~3 080** | **20 tyg** |

### 9.2 Statystyki Końcowe

| Metryka | Wartość |
|---------|:-------:|
| **Pakiety JDG** | 50 |
| **Reguły łącznie** | ~3 080 |
| **Nowe reguły w tym dokumencie (★)** | 56 |
| **Domeny prawne pokryte** | 100+ |
| **Podstawy prawne cytowane** | 300+ |
| **Parametry w thresholds.jdg.*** | ~200 |
| **Pola input.jdg_entrepreneur.*** | ~220 |
| **Nowe obszary (krypto, CESOP, ViDA, UK, e-learning, gig, AI Act, API + audit, conflict resolution, Polski Ład, zbiegi)** | 12 |
| **[TODO: potrzebne źródło]** | 16 |

### 9.3 Pozycje [TODO: potrzebne źródło] — 16 do uzupełnienia (6 uzupełnionych v9.1)

| # | Pozycja | Źródło do pozyskania |
|---|---------|---------------------|
| 1 | Wytyczne MF do kalkulacji wskaźnika Nexus | Interpretacje MF — Art. 30ca PIT |
| 2 | ~~Lista znamion schematów MDR~~ ✅ **UZUPEŁNIONO** | Art. 86a-86o OP — 11 cech ogólnych, 9 szczególnych, 4 inne (Art. 86a § 1 pkt 6/13/1) |
| 3 | ~~Finalna wersja AI Act (2026)~~ ✅ **UZUPEŁNIONO** | Regulation (EU) 2024/1689, OJ UE 12.07.2024, pełne zastosowanie 02.08.2026 |
| 4 | ~~Data implementacji ViDA w PL~~ ✅ **UZUPEŁNIONO** | Rada UE 11.03.2025, OJ UE 25.03.2025, w życie 14.04.2025; P1: 01.07.2030, P2/P3: 01.07.2028 |
| 5 | ~~Interpretacja MF: staking krypto~~ ✅ **UZUPEŁNIONO** | DKIS 0114-KDIP2-2.4010.579.2025.2.IN (27.02.2026) + konflikt z WSA + DAC8 |
| 6 | ~~Interpretacja MF: NFT~~ ✅ **UZUPEŁNIONO** | KIS: NFT ≠ „waluty wirtualne”; EU VAT Committee WP no. 1060 (21.03.2023) |
| 7 | ~~Interpretacja MF: DeFi~~ ✅ **UZUPEŁNIONO** | Brak dedykowanej interpretacji; DAC8 (Dir (EU) 2023/2226) od 01.01.2026 |
| 8 | Pełna lista kategorii wyłączonych z kasy fiskalnej | Rozporządzenie MF kasowe |
| 9 | Aktualne normy szacunkowe dla działów specjalnych | Załącznik nr 2 do PIT |
| 10 | Aktualne stawki akcyzy na alkohol (2026) | Ustawa o podatku akcyzowym |
| 11 | Stawki akcyzy samochodowej (2026) | Ustawa o podatku akcyzowym |
| 12 | Tabela diet zagranicznych (wszystkie kraje) | Rozporządzenie MPiPS |
| 13 | Stawki kilometrówki (2026) | Rozporządzenie MPiPS |
| 14 | Limit pomocy de minimis (2026) | Rozporządzenie KE |
| 15 | Lista PKD wymagających BDO | Rozporządzenie Ministra Klimatu |
| 16 | Stawki podatku rolnego (2026) | Uchwały gmin + przeliczniki GUS |
| 17 | Baza stawek WHT dla UPO | Umowy o unikaniu podwójnego opodatkowania |
| 18 | Pełna tabela stawek VAT dla OSS | Stawki VAT dla 27 krajów UE |
| 19 | Tabela stawek karty podatkowej | Załącznik nr 3 do ustawy o ryczałcie |
| 20 | Stawki podatku od nieruchomości | Uchwały poszczególnych gmin |
| 21 | API kursów NBP | api.nbp.pl |
| 22 | Data obowiązkowej korespondencji e-US | Nowelizacja Ordynacji podatkowej |

---

> **Plik:** `Plan OPA/32_JDG_ENTERPRISE_DEFINITIVE_PLAN.md`
> **Status:** DEFINITYWNY plan systemu reguł OPA dla JDG — v9.0 ENTERPRISE
> **Data:** 2026-07-10
> **Powiązane:** `22_JDG_ENTERPRISE_PLAN.md` | `23_JDG_EXPANSION_SUPPLEMENT.md` | `24_JDG_COMPLETE_INDEX.md` | `25_JDG_DEEP_LEGAL_AUDIT.md` | `26_JDG_COMPREHENSIVE_EXPANSION.md` | `27_JDG_ENTERPRISE_DEEP_EXPANSION.md` | `28_JDG_ENTERPRISE_MASTER_SYNTHESIS.md` | `29_JDG_DEEP_ANALYSIS_GAPS.md` | `30_JDG_MASSIVE_EXPANSION.md` | `31_JDG_3000_RULES.md` | `Plan OPA/DocsJDG` | `policies/tax/*.rego`
> **Łącznie reguł ENTERPRISE:** ~3 080
> **Gotowość wdrożeniowa:** ENTERPRISE READY — 50 pakietów, 100+ domen prawnych, 300+ podstaw prawnych, 8 nowych obszarów
