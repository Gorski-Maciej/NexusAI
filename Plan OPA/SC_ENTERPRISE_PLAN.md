# 🏛️ NexusAI Spółka Cywilna — Definitywny Plan Reguł OPA/Rego ENTERPRISE v1.0

> **Status:** PLAN DEFINITYWNY — Gotowy do implementacji
> **Data:** 2026-07-11
> **Autor:** Zespół NexusAI
> **Plik:** `Plan OPA/SC_ENTERPRISE_PLAN.md`
> **Zakres:** Wyłącznie spółka cywilna (civil law partnership)
> **Źródła prawne:** `Plan OPA/Docs SC` — kompletny wykaz ustaw, rozporządzeń i interpretacji
> **Dokumenty referencyjne:** `Plan OPA/00_PLAN_STRUKTURA.md`, `Plan OPA/34_JDG_DEFINITIVE_REGO_PLAN.md`
> **Reguły łącznie w tym dokumencie:** ~400+ (opisanych szczegółowo) | **Pakietów:** 25+

---

## 📑 Spis Treści

1. [Filozofia Projektowa i Architektura](#1-filozofia-projektowa-i-architektura)
2. [Kluczowa Specyfika Spółki Cywilnej](#2-kluczowa-specyfika-spółki-cywilnej)
3. [Podział na Pakiety](#3-podział-na-pakiety)
4. [Hierarchia i Priorytety — First-Match-Wins](#4-hierarchia-i-priorytety--first-match-wins)
5. [Szczegółowy Opis Reguł per Pakiet](#5-szczegółowy-opis-reguł-per-pakiet)
   - [5.1 sc.risk — Ryzyko i Fraud (P0-P9)](#51-scrisk--ryzyko-i-fraud-p0-p9)
   - [5.2 sc.routing — Field Confidence (P10-P19)](#52-scrouting--field-confidence-p10-p19)
   - [5.3 sc.compliance — Zgodność dokumentacyjna (P20-P39)](#53-sccompliance--zgodność-dokumentacyjna-p20-p39)
   - [5.4 sc.crossborder — Transakcje transgraniczne (P40-P49)](#54-sccrossborder--transakcje-transgraniczne-p40-p49)
   - [5.5 sc.vat — VAT spółki cywilnej (P50-P69, P180-P235)](#55-scvat--vat-spółki-cywilnej-p50-p69-p180-p235)
   - [5.6 sc.pit.partners — PIT wspólników (P500-P599)](#56-scpitpartners--pit-wspólników-p500-p599)
   - [5.7 sc.pit.kup — Koszty uzyskania przychodu (P560-P582)](#57-scpitkup--koszty-uzyskania-przychodu-p560-p582)
   - [5.8 sc.pit.advances — Zaliczki PIT wspólników (P540-P559)](#58-scpitadvances--zaliczki-pit-wspólników-p540-p559)
   - [5.9 sc.pit.returns — Zeznania roczne (P550-P559)](#59-scpitreturns--zeznania-roczne-p550-p559)
   - [5.10 sc.pit.exemptions — Zwolnienia PIT (P580-P588)](#510-scpitexemptions--zwolnienia-pit-p580-p588)
   - [5.11 sc.partnership.lifecycle — Cykl życia spółki (P900-P939)](#511-scpartnershiplifecycle--cykl-życia-spółki-p900-p939)
   - [5.12 sc.partnership.liability — Odpowiedzialność solidarna (P1150-P1174)](#512-scpartnershipliability--odpowiedzialność-solidarna-p1150-p1174)
   - [5.13 sc.partnership.succession — Sukcesja (P920-P929)](#513-scpartnershipsuccession--sukcesja-p920-p929)
   - [5.14 sc.partnership.suspension — Zawieszenie (P910-P919)](#514-scpartnershipsuspension--zawieszenie-p910-p919)
   - [5.15 sc.zus.partners — ZUS wspólników (P700-P770)](#515-sczuspartners--zus-wspólników-p700-p770)
   - [5.16 sc.zus.health — Składka zdrowotna (P720-P749)](#516-sczushealth--składka-zdrowotna-p720-p749)
   - [5.17 sc.accounting.full — Pełna księgowość (P800-P894)](#517-scaccountingfull--pełna-księgowość-p800-p894)
   - [5.18 sc.accounting.pkpir — PKPiR spółki (P800-P805)](#518-scaccountingpkpir--pkpir-spółki-p800-p805)
   - [5.19 sc.accounting.depreciation — Amortyzacja (P840-P870)](#519-scaccountingdepreciation--amortyzacja-p840-p870)
   - [5.20 sc.ksef — KSeF (P950-P960)](#520-scksef--ksef-p950-p960)
   - [5.21 sc.jpk — JPK (P970-P989)](#521-scjpk--jpk-p970-p989)
   - [5.22 sc.employer — Spółka jako pracodawca (P1200-P1223)](#522-scemployer--spółka-jako-pracodawca-p1200-p1223)
   - [5.23 sc.allowances — Ulgi podatkowe (P600-P635)](#523-scallowances--ulgi-podatkowe-p600-p635)
   - [5.24 sc.local — Podatki lokalne (P1300-P1320)](#524-sclocal--podatki-lokalne-p1300-p1320)
   - [5.25 sc.corrections — Korekty (P1100-P1120)](#525-sccorrections--korekty-p1100-p1120)
   - [5.26 sc.international — Międzynarodowe (P100-P117)](#526-scinternational--międzynarodowe-p100-p117)
   - [5.27 sc.fallback — Reguły domyślne (P1000-P1099)](#527-scfallback--reguły-domyślne-p1000-p1099)
6. [Wymagane Dane Wejściowe (input)](#6-wymagane-dane-wejściowe-input)
7. [Obsługa Parametrów Dynamicznych (thresholds)](#7-obsługa-parametrów-dynamicznych-thresholds)
8. [Architektura Multi-Pass — Scalanie Werdyktów](#8-architektura-multi-pass--scalanie-werdyktów)
9. [Macierze Interakcji Międzyregulacyjnych](#9-macierze-interakcji-międzyregulacyjnych)
10. [Plan Wdrożenia ENTERPRISE](#10-plan-wdrożenia-enterprise)

---

## 1. Filozofia Projektowa i Architektura

### 1.1 Fundamenty Architektoniczne

| Zasada | Opis | Implementacja SC |
|--------|------|-------------------|
| **First-Match-Wins** | Pierwsza pasująca reguła wewnątrz każdego pakietu wygrywa | `else` chain w Rego |
| **Multi-Pass Evaluation** | Różne domeny (VAT, PIT, ZUS, Accounting) ewaluowane niezależnie | 9+ passów OPA, scalane przez `VerdictMerger` |
| **Zero Hardcoded Values** | Żadna liczba nie jest zakodowana w `.rego` | Wszystko przez `input.thresholds.sc.*` |
| **Temporalność** | Reguły obowiązują od-do; parametry zależne od daty | `valid_from` / `valid_to` w DuckDB |
| **Audytowalność** | Każda decyzja ma pełny ślad | `rule_id`, `_legal_basis` w werdykcie |
| **Partner-Proportional Design** | Wszystkie reguły PIT/KUP/ZUS rozbite na wspólników | `input.partners[]` + proporcjonalny podział |
| **Graceful Degradation** | Awaria API zewnętrznego → fallback, nie crash | Warning zamiast BLOCK |
| **Solidarna odpowiedzialność** | Reguły odpowiedzialności za zobowiązania spółki | `sc.partnership.liability` |

### 1.2 Konwencja Werdyktu SC

```json
{
    "matched": true,
    "rule_id": "sc.vat.substantive.fuel_pl",
    "package": "sc.vat.substantive",
    "priority": 52,

    "vat_rate": "0.23",
    "rounding_level": "position",
    "gtu_code": "GTU_04",
    "procedure": "",
    "vat_exemption": "",
    "vat_nip": "1234567890",

    "partners_results": [
        {
            "partner_id": "P1",
            "nip": "1111111111",
            "share_percent": 50.0,
            "pit_form": "PIT_SCALE",
            "pit_rate": "0.12",
            "pit_bracket": "LOW",
            "revenue_share": 5000.00,
            "cost_share": 3000.00,
            "income_share": 2000.00,
            "kus_qualification": "full",
            "kus_percent": 100,
            "pit_advance_required": true,
            "pit_annual_return_type": "PIT-36",
            "zus_social_base_type": "STANDARD",
            "zus_health_rate": "0.09"
        },
        {
            "partner_id": "P2",
            "nip": "2222222222",
            "share_percent": 50.0,
            "pit_form": "LINEAR",
            "pit_rate": "0.19",
            "revenue_share": 5000.00,
            "cost_share": 3000.00,
            "income_share": 2000.00,
            "kus_qualification": "full",
            "kus_percent": 100,
            "pit_advance_required": true,
            "pit_annual_return_type": "PIT-36L",
            "zus_social_base_type": "MALY_ZUS_PLUS",
            "zus_health_rate": "0.049"
        }
    ],

    "partnership": {
        "total_revenue": 10000.00,
        "total_costs": 6000.00,
        "total_income": 4000.00,
        "partner_count": 2,
        "accounting_method": "PKPIR",
        "full_accounting_required": false,
        "joint_liability_applies": true
    },

    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 1 ustawy o VAT",
    "_warnings": []
}
```

### 1.3 Architektura Multi-Pass

```
INPUT ──► PASS 0: RISK (fraud/anomaly/KKS/GAAR)               ──► risk_verdict
              ↓ (if BLOCK → abort)
          PASS 1: ROUTING (field confidence)                    ──► routing_verdict
              ↓ (if BLOCK → abort)
          PASS 2: COMPLIANCE (whitelist/MPP/cash/KSeF)         ──► compliance_verdict
              ↓
          PASS 3: CROSSBORDER (WNT/WDT/import/export)          ──► crossborder_verdict
              ↓
          PASS 4: PARTNERSHIP LIFECYCLE (formation/changes)    ──► partnership_verdict
              ↓
          PASS 5: VAT (rates + GTU + deductions + tax_point)   ──► vat_verdict
              ↓
          PASS 6: PIT per PARTNER (form + KUP + advances)      ──► pit_verdict
              ↓
          PASS 7: ALLOWANCES per PARTNER (ulgi podatkowe)      ──► allowances_verdict
              ↓
          PASS 8: ZUS per PARTNER (społeczne + zdrowotne)      ──► zus_verdict
              ↓
          PASS 9: ACCOUNTING (PKPiR/full + depreciation)       ──► accounting_verdict
              ↓
          PASS 10: KSeF + JPK + RESZTA                         ──► misc_verdict
              ↓
          VERDICT MERGER                                        ──► final_verdict
```

---

## 2. Kluczowa Specyfika Spółki Cywilnej

### 2.1 Model podatkowy — diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      SPÓŁKA CYWILNA (SC)                         │
│                                                                   │
│  ┌─────────────────────┐     ┌─────────────────────────────────┐ │
│  │  VAT: ODRĘBNY        │     │  PIT: NIE jest podatnikiem     │ │
│  │  podatnik            │     │                                 │ │
│  │  • Własny NIP         │     │  Podatnikami są WSPÓLNICY:      │ │
│  │  • Własne deklaracje  │     │  • Przychody dzielone wg       │ │
│  │    JPK_V7M/K          │     │    udziałów (Art. 8 PIT)       │ │
│  │  • Własny VAT-R       │     │  • Koszty dzielone wg          │ │
│  │  • KSeF faktury       │     │    udziałów (Art. 8 PIT)       │ │
│  │  • Biała Lista        │     │  • Każdy wspólnik rozlicza     │ │
│  └─────────────────────┘     │    swoją część indywidualnie    │ │
│                               │  • Różne formy PIT możliwe     │ │
│  ┌─────────────────────┐     │    dla różnych wspólników       │ │
│  │  ZUS: Indywidualnie  │     └─────────────────────────────────┘ │
│  │  per wspólnik        │                                          │
│  │  • Każdy opłaca       │     ┌─────────────────────────────────┐ │
│  │    własne składki     │     │  ODPOWIEDZIALNOŚĆ SOLIDARNA      │ │
│  │  • Własne ulgi ZUS    │     │  • Art. 864 KC                   │ │
│  │  • Własna zdrowotna   │     │  • Za zobowiązania spółki        │ │
│  └─────────────────────┘     │  • Za zobowiązania podatkowe      │ │
│                               │  • Za zobowiązania ZUS            │ │
│  ┌─────────────────────┐     └─────────────────────────────────┘ │
│  │  KSIĘGOWOŚĆ:         │                                          │
│  │  • PKPiR < 2M EUR    │                                          │
│  │  • Pełna księgowość  │                                          │
│  │    ≥ 2M EUR          │                                          │
│  │  • Art. 2 ust. 1     │                                          │
│  │    pkt 1 UoR         │                                          │
│  └─────────────────────┘                                          │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Kluczowe różnice vs JDG — tabela

| Aspekt | JDG (jednoosobowa) | Spółka cywilna |
|--------|-------------------|----------------|
| **Podatnik VAT** | Przedsiębiorca (osoba fizyczna) | **Spółka** (odrębny NIP) |
| **Podatnik PIT** | Przedsiębiorca | **Każdy wspólnik** (proporcjonalnie) |
| **Deklaracje VAT** | 1 deklaracja (JPK_V7) | 1 deklaracja **spółki** |
| **Deklaracje PIT** | 1 zeznanie (PIT-36/36L/28) | Tyle zeznań **ilu wspólników** |
| **ZUS** | 1 przedsiębiorca | **Każdy wspólnik osobno** |
| **Odpowiedzialność** | Osobista (cały majątek) | **Solidarna** wszystkich wspólników |
| **PKPiR** | 1 księga | **1 księga spółki** (wspólna) |
| **Pełna księgowość** | Opcjonalnie | **Obowiązkowo** po 2M EUR |
| **CEIDG** | Wpis przedsiębiorcy | Wpis **każdego wspólnika** + oznaczenie SC |
| **KSeF** | Obowiązek przedsiębiorcy | Obowiązek **spółki** |
| **Podział przychodów/kosztów** | Nie dotyczy | **Proporcjonalnie** do udziałów (Art. 8 PIT) |
| **Forma opodatkowania PIT** | Jedna dla przedsiębiorcy | **Może być różna** dla każdego wspólnika |

### 2.3 Art. 8 PIT — Święta reguła proporcjonalności

> **Art. 8 ust. 1 ustawy o PIT:** "Przychody z udziału w spółce niebędącej osobą prawną [...] u każdego podatnika określa się proporcjonalnie do jego prawa do udziału w zysku (udziału)."
>
> **Art. 8 ust. 2:** "Zasady wyrażone w ust. 1 stosuje się odpowiednio do rozliczania kosztów uzyskania przychodów, wydatków niestanowiących kosztów uzyskania przychodów i strat."

**Implikacje dla systemu reguł:**
- Każda reguła dotycząca przychodu musi go **podzielić** przez `input.partners[].share_percent`
- Każda reguła dotycząca KUP musi go **podzielić** przez `input.partners[].share_percent`
- Każdy wspólnik może mieć **inną formę opodatkowania** (skala/liniowy/ryczałt)
- Strata spółki jest dzielona między wspólników
- Ulgi podatkowe stosuje **każdy wspólnik indywidualnie**

---

## 3. Podział na Pakiety

```
policies/sc/
├── main_sc.rego                        # Główny else-chain FIRST-MATCH-WINS
├── _helpers_sc.rego                    # Funkcje pomocnicze SC (proportional split)
├── _metadata_sc.rego                   # Metadane wszystkich reguł SC
│
├── risk.rego                           # P0-P9:    Fraud, anomalie, KKS, GAAR
├── routing.rego                        # P10-P19:  Field confidence per forma
│
├── compliance/
│   ├── whitelist.rego                  # P20-P22:  Biała Lista MF (spółka jako płatnik)
│   ├── mpp.rego                        # P25:      Split payment
│   ├── cash_limit.rego                 # P35-P36:  Limit gotówki >15k PLN
│   └── ksef_compliance.rego            # P37:      KSeF compliance spółki
│
├── crossborder.rego                    # P40-P49:  WNT, WDT, import, eksport
│
├── vat/
│   ├── substantive.rego                # P50-P65:  Stawki VAT, zwolnienia, GTU
│   ├── gtu.rego                        # P65a-P65m: Mapowanie GTU (13 kodów)
│   ├── exemptions.rego                 # P55-P63:  Zwolnienia podmiotowe/przedmiotowe
│   ├── tax_point.rego                  # P230-P235: Moment obowiązku podatkowego
│   └── deductions.rego                 # P183-P192: Odliczenia VAT (proporcja, korekty)
│
├── pit/
│   ├── partners_proportional.rego      # P500:     FUNDAMENT — proporcjonalny podział
│   ├── form_scale.rego                 # P501-P509: Skala podatkowa 12%/32%
│   ├── form_linear.rego                # P510-P519: Podatek liniowy 19%
│   ├── form_lump_sum.rego              # P520-P529: Ryczałt ewidencjonowany
│   ├── form_tax_card.rego              # P530-P539: Karta podatkowa
│   ├── tax_form_change.rego            # P590-P599: Zmiana formy opodatkowania
│   ├── kup.rego                        # P560-P582: KUP — wyłączenia per wspólnik
│   ├── advances.rego                   # P540-P549: Zaliczki per wspólnik
│   ├── annual_returns.rego             # P550-P559: Zeznania roczne per wspólnik
│   └── exemptions.rego                 # P580-P588: Zwolnienia PIT per wspólnik
│
├── partnership/
│   ├── lifecycle.rego                  # P900-P909: Powstanie, zmiany składu, rozwiązanie
│   ├── liability.rego                  # P1150-P1174: Odpowiedzialność solidarna
│   ├── succession.rego                 # P920-P929: Sukcesja po śmierci wspólnika
│   └── suspension.rego                 # P910-P919: Zawieszenie działalności
│
├── zus/
│   ├── social.rego                     # P700-P701: Składki społeczne per wspólnik
│   ├── health.rego                     # P720-P749: Składka zdrowotna per wspólnik
│   ├── start_relief.rego               # P740:     Ulga na start
│   ├── maly_zus_plus.rego              # P741:     Mały ZUS Plus
│   └── preferential.rego               # P742:     Preferencyjny ZUS
│
├── accounting/
│   ├── pkpir.rego                      # P800-P805: PKPiR spółki (16 kolumn)
│   ├── full_accounting.rego            # P806-P810: Pełna księgowość (próg 2M EUR)
│   ├── depreciation.rego               # P840-P847: Amortyzacja środków trwałych
│   ├── leasing.rego                    # P860-P868: Leasing operacyjny/finansowy
│   ├── fx_differences.rego             # P870:     Różnice kursowe
│   ├── inventory.rego                  # P850-P852: Inwentaryzacja, remanent
│   └── uor_books.rego                  # P320-P330: UoR — księgi, wycena, sprawozdania
│
├── ksef/
│   ├── structured_invoice.rego         # P950-P955: Faktury ustrukturyzowane
│   └── offline_recovery.rego           # P960:     Tryb awaryjny KSeF
│
├── jpk/
│   ├── jpk_vat.rego                    # P970-P975: JPK_V7M/K spółki
│   └── jpk_pkpir.rego                  # P980:     JPK_PKPIR
│
├── employer.rego                       # P1200-P1223: Spółka jako pracodawca
├── allowances.rego                     # P600-P635: Ulgi podatkowe per wspólnik
├── corrections.rego                    # P1100-P1120: Korekty faktur, deklaracji
├── local_taxes.rego                    # P1300-P1320: PCC, nieruchomości, transport
├── international.rego                  # P100-P117: WHT, PE, ceny transferowe
├── environmental.rego                  # P1400-P1407: BDO, KOBiZE
├── restructuring.rego                  # P1500-P1505: Przekształcenie
├── digital.rego                        # P630-P1895: Krypto, AI Act, MDR
├── retention.rego                      # P990-P992: Przechowywanie dokumentów
└── fallback.rego                       # P1000-P1099: Reguły domyślne
```

### 3.1 Macierz Priorytetów

| Zakres | Pakiet | Odpowiedzialność | Skutek |
|--------|--------|-------------------|--------|
| **P0-P9** | `sc.risk` | Fraud, anomalie, KKS, GAAR | BLOCK_AND_ALERT |
| **P10-P19** | `sc.routing` | OCR confidence | BLOCK / TRIAGE |
| **P20-P39** | `sc.compliance.*` | Biała Lista, MPP, gotówka, KSeF | BLOCK / warnings |
| **P40-P49** | `sc.crossborder` | WNT, WDT, import, eksport | Procedura specjalna |
| **P50-P69, P180-P235** | `sc.vat.*` | Stawki VAT, GTU, odliczenia, tax point | Stawka VAT + GTU |
| **P100-P117** | `sc.international` | WHT, PE, TP | WHT / TP flags |
| **P500-P599** | `sc.pit.*` | Forma PIT, KUP, zaliczki, zeznania per wspólnik | Stawka PIT + KUP |
| **P600-P635** | `sc.allowances` + `sc.digital` | Ulgi, krypto per wspólnik | Odliczenie |
| **P700-P770** | `sc.zus.*` | Składki ZUS per wspólnik | Stawki składek |
| **P800-P894** | `sc.accounting.*` | PKPiR, pełna księgowość, amortyzacja | Metoda/kolumna |
| **P900-P939** | `sc.partnership.*` | Cykl życia, odpowiedzialność, sukcesja | Status |
| **P950-P989** | `sc.ksef` + `sc.jpk` | KSeF, JPK | KSeF/JPK flags |
| **P990-P1099** | `sc.retention` + `sc.fallback` | Przechowywanie, domyślne | Okres / fallback |

---

## 4. Hierarchia i Priorytety — First-Match-Wins

### 4.1 Zunifikowany Łańcuch Decyzyjny SC

```
INPUT ───────────────────────────────────────────────────────────────────────────► WERDYKT SC

═══ BLOK 0: RISK & FRAUD (P0-P9) — NATYCHMIASTOWA BLOKADA ═══
P0      fraud_graph_match                     Kontrahent w sieci fraudowej VAT
P0_sc   partnership_fraud_risk                Ryzyko fraudu wewnątrz spółki ★
P1      counterparty_trust_low                Trust score < próg
P2      anomaly_amount                        Kwota > 3σ od średniej
P3      new_counterparty_flag                 Nowy kontrahent → weryfikacja
P4      kks_hidden_income_flag                Rozbieżność wpływy vs przychody
P5      semantic_guard_disallowed             Wydatek niezwiązany z działalnością
P8      ceidg_vendor_suspended                Kontrahent zawieszony w CEIDG
P9      gaar_artificial_scheme                Klauzula GAAR
         │
═══ BLOK 1: ROUTING (P10-P19) ═══
P10     fc_vat_rate_low                       Niska pewność stawki VAT
P12     fc_vendor_nip_low                     Niska pewność NIP
P19     fc_global_minimum_low                 Ogólna pewność < minimum
         │
═══ BLOK 2: COMPLIANCE (P20-P39) ═══
P20     whitelist_missing_over_limit          Brak na WL > 15k PLN
P21     whitelist_account_mismatch            Rachunek niezgodny z WL
P25     split_payment_mandatory               Obowiązkowy MPP
P35     cash_transaction_over_limit           Gotówka > 15k PLN → NKUP
P37     ksef_compliance_sc                    KSeF compliance spółki ★
P39     vat_r_registration_sc                 Blokada: brak VAT-R spółki ★
         │
═══ BLOK 3: CROSSBORDER (P40-P49) ═══
P40     eu_reverse_charge                     WNT — reverse charge
P41     eu_import_services                    Import usług z UE
P42     wdt_intracommunity_supply             WDT — 0% VAT
P45     import_non_eu                         Import spoza UE
P48     export_goods                          Eksport towarów
         │
═══ BLOK 4: CYKL ŻYCIA SPÓŁKI (P900-P939) ═══
P900    sc_formation_valid                    Umowa spółki — walidacja ★
P902    sc_partner_change_notification        Zmiana składu wspólników ★
P904    sc_dissolution_procedure              Rozwiązanie spółki ★
P910    sc_suspension_valid                   Zawieszenie spółki ★
P920    sc_succession_continuity              Sukcesja po śmierci wspólnika ★
P930    sc_accounting_threshold_check         Próg 2M EUR — pełna księgowość ★
         │
═══ BLOK 5: VAT SPÓŁKI (P50-P235) ═══
P50     vat_margin_scheme                     Procedura marży
P52     vat_rate_fuel_pl                      Paliwo → 23% + GTU_04
P53     vat_rate_food_pl                      Żywność → 5% + GTU_07
P55     vat_exemption_education               Edukacja → zwolniona
P56     vat_exemption_healthcare              Medycyna → zwolniona
P58     vat_exemption_subject_sc              Zwolnienie podmiotowe SC (200k) ★
P60     vat_bad_debt_relief                   Ulga na złe długi VAT
P65     gtu_mapping_by_category               Mapowanie GTU (13 kodów)
P184    bad_debt_debtor_correction_mandatory  OBOWIĄZEK spółki po 90 dniach
P186    vehicle_50_vat_deduction              Auto mieszane 50% VAT
P230    vat_tax_point_continuous_service      Usługi ciągłe
P231    vat_tax_point_advance_invoice         Zaliczki
         │
═══ BLOK 6: PIT WSPÓLNIKÓW — FORMA (P500-P539) ═══
P500    partner_proportional_split            FUNDAMENT: podział przych/kosztów ★★★
P501    partner_pit_scale_bracket             Skala 12%/32% per wspólnik
P510    partner_pit_linear                    19% per wspólnik
P520    partner_pit_lump_sum                  Ryczałt per wspólnik
P530    partner_pit_tax_card                  Karta podatkowa per wspólnik
         │
═══ BLOK 7: PIT WSPÓLNIKÓW — KUP (P560-P582) ═══
P560    partner_kup_full_deductible           Pełny KUP per wspólnik
P561    partner_kup_zus_social_deductible     ZUS społeczne → KUP
P562    partner_kup_private_mixed             Wydatki mieszane
P566    partner_kup_representation_none       Reprezentacja → NKUP
P570    partner_kup_health_contrib_deduction  Zdrowotna — limit odliczenia
         │
═══ BLOK 8: PIT WSPÓLNIKÓW — ZALICZKI (P540-P549) ═══
P540    partner_advance_monthly               Zaliczka miesięczna per wspólnik
P542    partner_advance_quarterly             Zaliczka kwartalna
         │
═══ BLOK 9: PIT WSPÓLNIKÓW — ZEZNANIA (P550-P559) ═══
P550    partner_annual_return_pit36           PIT-36 per wspólnik
P552    partner_annual_return_pit36l          PIT-36L per wspólnik
P554    partner_annual_return_pit28           PIT-28 per wspólnik
         │
═══ BLOK 10: PIT WSPÓLNIKÓW — ZWOLNIENIA (P580-P588) ═══
P580    partner_exemption_young               Ulga dla młodych
P582    partner_exemption_return              Ulga na powrót
P584    partner_exemption_family_4plus        Ulga 4+
         │
═══ BLOK 11: ULGI PER WSPÓLNIK (P600-P635) ═══
P600    partner_relief_rd                     Ulga B+R
P610    partner_relief_ip_box                 IP Box 5%
P615    partner_loss_carry_forward            Rozliczenie straty
P623    partner_relief_thermo                 Ulga termomodernizacyjna
         │
═══ BLOK 12: ZUS PER WSPÓLNIK (P700-P770) ═══
P700    partner_zus_social_standard           Standardowe składki społeczne
P701    partner_zus_sickness_voluntary        Chorobowa — DOBROWOLNA
P720    partner_zus_health_scale              9% (skala)
P722    partner_zus_health_linear             4.9% (liniowy)
P724    partner_zus_health_lump_sum           Progi ryczałtowe
P740    partner_zus_start_relief              Ulga na start (6 mies.)
P741    partner_zus_maly_plus                 Mały ZUS Plus (36 mies.)
P743    partner_concurrent_employment          Zbieg etat+SC → tylko zdrowotna ★
         │
═══ BLOK 13: KSIĘGOWOŚĆ SPÓŁKI (P800-P894) ═══
P800    sc_pkpir_column_mapping               Mapowanie 16 kolumn PKPiR
P806    sc_full_accounting_threshold          Próg 2M EUR → pełna księgowość ★
P808    sc_double_entry_validation            Walidacja Wn=Ma ★
P840    sc_depreciation_linear                Amortyzacja liniowa
P842    sc_depreciation_one_off               Jednorazowa amortyzacja
P860    sc_operating_lease_kup                Leasing operacyjny → KUP
P870    sc_fx_differences                     Różnice kursowe
         │
═══ BLOK 14: ODPOWIEDZIALNOŚĆ SOLIDARNA (P1150-P1174) ═══
P1150   sc_joint_liability_tax                Solidarna za podatki ★
P1152   sc_joint_liability_zus                Solidarna za ZUS ★
P1154   sc_joint_liability_civil              Solidarna za zobowiązania cywilne ★
P1158   sc_partner_exit_liability             Odpowiedzialność po wystąpieniu ★
         │
═══ BLOK 15: PRACODAWCA (P1200-P1223) ═══
P1200   sc_employer_obligation                Spółka jako płatnik PIT ★
P1202   sc_payroll_zus                        ZUS od pracowników
P1208   sc_ppk_obligation                     Obowiązek PPK
         │
═══ BLOK 16: KSeF I JPK (P950-P989) ═══
P950    sc_ksef_mandatory                     Obowiązek KSeF od 01.02.2026 ★
P970    sc_jpk_v7m                            JPK_V7M spółki ★
P980    sc_jpk_pkpir                          JPK_PKPIR
         │
═══ BLOK 17: RETENCJA I FALLBACK (P990-P1099) ═══
P990    sc_retention_invoice_5y               Przechowywanie 5 lat
P1000   sc_domestic_fallback                  Domyślna stawka 23%
P1099   sc_no_match                           NO_MATCHING_RULE
```

---

## 5. Szczegółowy Opis Reguł per Pakiet

### 5.1 sc.risk — Ryzyko i Fraud (P0-P9)

#### P0: `fraud_graph_match`
- **Cel biznesowy:** Natychmiastowa blokada faktury od kontrahenta w sieci fraudowej VAT. Dotyczy spółki jako podatnika VAT.
- **Przesłanki:** `input.vendor.fraud_flag == true`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `fraud_detected: true`
- **Podstawa prawna:** Art. 86 ust. 1 ustawy o VAT, Art. 55 KKS
- **Priorytet:** 0

#### P0_sc: `partnership_fraud_risk` ★ NOWA
- **Cel biznesowy:** Wykrycie ryzyka fraudu wewnątrz spółki — fikcyjne faktury między wspólnikami, sztuczne zwiększanie kosztów przez jednego wspólnika kosztem drugiego.
- **Przesłanki:** `input.vendor.nip in [p.nip for p in input.partners]` (kontrahent = wspólnik) AND transakcja nietypowa (brak uzasadnienia biznesowego)
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `intra_partnership_fraud_risk: true`
- **Podstawa prawna:** Art. 55 KKS, Art. 119a Ordynacji podatkowej, Art. 860 KC (umowa spółki)
- **Priorytet:** 0.3

#### P8: `ceidg_vendor_suspended`
- **Cel biznesowy:** Kontrahent z zawieszoną działalnością w CEIDG. Dla SC kluczowe — spółka nie może odliczyć VAT od takiego kontrahenta.
- **Przesłanki:** `input.vendor.ceidg_status == "SUSPENDED"`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `vat_deduction_blocked: true`
- **Podstawa prawna:** Art. 88 ustawy o VAT, Art. 22-25 Prawa przedsiębiorców
- **Priorytet:** 8

---

### 5.2 sc.routing — Field Confidence (P10-P19)

#### P10: `fc_vat_rate_low_sc`
- **Cel biznesowy:** Niska pewność stawki VAT → blokada automatycznego księgowania. Dla SC szczególnie ważne — błędna stawka VAT wpływa na JPK_V7 spółki.
- **Przesłanki:** `input.confidence.fc_vat_rate < input.thresholds.sc.fc_thresholds.vat_rate` (0.95) AND `input.confidence.fc_vat_rate > 0`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 22 UoR (rzetelność ksiąg), Art. 99 VAT (JPK_V7)
- **Priorytet:** 10

---

### 5.3 sc.compliance — Zgodność dokumentacyjna (P20-P39)

#### P20: `whitelist_missing_over_limit`
- **Cel biznesowy:** Weryfikacja Białej Listy MF. Dla SC: przelew spółki >15k PLN → obowiązek weryfikacji. Odpowiedzialność solidarna wspólników.
- **Przesłanki:** `input.invoice.amount_gross >= input.thresholds.sc.limits.mpp_limit` AND `input.vendor.on_whitelist == false`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, joint_liability_risk: true
- **Podstawa prawna:** Art. 96b ustawy o VAT, Art. 117ba Ordynacji podatkowej, Art. 864 KC
- **Priorytet:** 20

#### P25: `split_payment_mandatory`
- **Cel biznesowy:** Obowiązkowy MPP dla faktur >15k PLN. Spółka cywilna ma własny rachunek VAT — MPP jest obowiązkiem spółki.
- **Przesłanki:** `input.invoice.amount_gross >= input.thresholds.sc.limits.mpp_limit` AND kategoria wrażliwa MPP
- **Rezultat:** `mpp_required: true`, `vat_account_required: true`
- **Podstawa prawna:** Art. 108a ustawy o VAT
- **Priorytet:** 25

#### P37: `ksef_compliance_sc` ★ NOWA
- **Cel biznesowy:** Weryfikacja zgodności KSeF dla spółki cywilnej. Spółka jako podatnik VAT czynny ma obowiązek KSeF od 01.02.2026.
- **Przesłanki:** `input.invoice.transaction_date >= "2026-02-01"` AND `input.partnership.is_vat_payer == true` AND `input.invoice.direction == "SALE"` AND `input.system.ksef_status != "ONLINE"`
- **Rezultat:** `ksef_offline_mode: true`, `ksef_submission_deadline_days: 7`
- **Podstawa prawna:** Ustawa z 16.06.2023 o zmianie ustawy o VAT (Dz.U. 2023 poz. 1598)
- **Priorytet:** 37

#### P39: `vat_r_registration_sc` ★ NOWA
- **Cel biznesowy:** Blokada transakcji gdy spółka nie jest zarejestrowana jako czynny podatnik VAT (brak VAT-R). Spółka ma własny NIP i własny VAT-R.
- **Przesłanki:** `input.partnership.vat_status == "unregistered"` AND `input.invoice.vat_taxable == true`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `vat_r_required: true`
- **Podstawa prawna:** Art. 96 ust. 1 ustawy o VAT
- **Priorytet:** 39

---

### 5.4 sc.crossborder — Transakcje transgraniczne (P40-P49)

#### P40: `eu_reverse_charge`
- **Cel biznesowy:** WNT — spółka jako nabywca rozlicza VAT (reverse charge). Transakcja w JPK_V7 spółki.
- **Przesłanki:** `input.vendor.country == "EU"` AND `input.vendor.vat_status == "active"` AND `input.invoice.procedure == "WNT"`
- **Rezultat:** `vat_rate: "0.00"`, `procedure: "VAT_REVERSE_CHARGE"`, `gtu_code: "GTU_12"`
- **Podstawa prawna:** Art. 17 ust. 1 pkt 3 VAT
- **Priorytet:** 40

#### P42_sc: `wdt_intracommunity_supply_sc` ★
- **Cel biznesowy:** WDT — spółka jako dostawca stosuje 0% VAT. Wymagany jest VAT-UE spółki.
- **Przesłanki:** `input.invoice.direction == "SALE"` AND `input.vendor.country in input.thresholds.sc.eu_countries` AND `input.partnership.is_vat_eu_registered == true`
- **Rezultat:** `vat_rate: "0.00"`, `procedure: "WDT"`, `vat_ue_summary_required: true`
- **Podstawa prawna:** Art. 42 VAT, Art. 97 VAT (rejestracja VAT-UE)
- **Priorytet:** 42

---

### 5.5 sc.vat — VAT spółki cywilnej (P50-P69, P180-P235)

> **Kluczowa zasada:** Spółka cywilna jest **odrębnym podatnikiem VAT** z własnym NIP. Wszystkie reguły VAT dotyczą **spółki jako całości**, nie poszczególnych wspólników.

#### P52: `vat_rate_fuel_pl`
- **Cel biznesowy:** Stawka VAT 23% dla paliw + GTU_04. Faktura dla spółki.
- **Przesłanki:** `input.invoice.category_code == "FUEL"` AND `input.vendor.country == "PL"`
- **Rezultat:** `vat_rate: "0.23"`, `gtu_code: "GTU_04"`, `rounding_level: "position"`
- **Podstawa prawna:** Art. 41 ust. 1 VAT
- **Priorytet:** 52

#### P58_sc: `vat_exemption_subject_sc` ★
- **Cel biznesowy:** Zwolnienie podmiotowe VAT dla spółki cywilnej. Limit 200 000 PLN dotyczy **spółki jako całości** (suma przychodów wszystkich wspólników), nie pojedynczego wspólnika.
- **Przesłanki:** `input.partnership.is_vat_payer == false` AND `input.partnership.annual_turnover_net < input.thresholds.sc.limits.vat_exemption_limit`
- **Rezultat:** `vat_rate: "0.00"`, `vat_exemption: "SUBJECT"`, `vat_exemption_entity: "PARTNERSHIP"`
- **Podstawa prawna:** Art. 113 ust. 1 i ust. 9 ustawy o VAT
- **Priorytet:** 58
- **Zależności:** Sprawdzana PRZED regułami stawek VAT. Próg liczony jako suma przychodów spółki.
- **UWAGA:** W przeciwieństwie do JDG, gdzie limit 200k dotyczy jednego przedsiębiorcy, tutaj limit dotyczy całej spółki. Przekroczenie limitu przez spółkę = wszyscy wspólnicy tracą zwolnienie.

#### P65: `gtu_mapping_by_category`
- **Cel biznesowy:** Automatyczne mapowanie kategorii na kody GTU dla JPK_V7 spółki.
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

#### P184_sc: `bad_debt_debtor_correction_sc` ★
- **Cel biznesowy:** OBOWIĄZEK spółki jako dłużnika do korekty VAT in minus po 90 dniach niezapłacenia. Konsekwencje: sankcja 30% + odpowiedzialność solidarna wspólników.
- **Przesłanki:** `input.invoice.direction == "PURCHASE"` AND `input.invoice.is_paid == false` AND `input.invoice.is_vat_deducted == true` AND `input.invoice.days_overdue >= 90`
- **Rezultat:** `vat_correction_mandatory: true`, `vat_to_return: <kwota>`, `_routing: "BLOCK_AND_ALERT"`, `sanction_risk_30pct: true`, `joint_liability_triggered: true`
- **Podstawa prawna:** Art. 89b VAT, Art. 864 KC
- **Priorytet:** 184

#### P230_sc: `vat_tax_point_sc` ★
- **Cel biznesowy:** Moment powstania obowiązku podatkowego VAT dla spółki. Wpływa na okres rozliczeniowy JPK_V7.
- **Przesłanki:** `input.invoice.delivery_date` vs `input.invoice.issue_date` — reguła ogólna: data dostawy; faktura przed dostawą → data faktury; faktura >30 dni po dostawie → 30. dzień
- **Rezultat:** `vat_tax_point: <data>`, `jpk_period: "MM-YYYY"`
- **Podstawa prawna:** Art. 19a ust. 1, 3, 5-7 VAT
- **Priorytet:** 230

---

### 5.6 sc.pit.partners — PIT wspólników (P500-P599)

> **KLUCZOWA ZASADA:** Spółka cywilna **NIE jest podatnikiem PIT**. Podatnikami są **wspólnicy**, którzy dzielą przychody i koszty **proporcjonalnie do udziałów** (Art. 8 PIT). Każdy wspólnik może mieć **inną formę opodatkowania**.

#### P500: `partner_proportional_split` ★★★ FUNDAMENT
- **Cel biznesowy:** **TO JEST NAJWAŻNIEJSZA REGUŁA W CAŁYM SYSTEMIE SC.** Proporcjonalny podział przychodów i kosztów spółki między wspólników zgodnie z Art. 8 PIT. Każdy wspólnik otrzymuje swoją część proporcjonalnie do udziału w zysku.
- **Przesłanki:** `input.partnership.total_revenue > 0` AND `count(input.partners) >= 2`
- **Rezultat:** Dla każdego wspólnika `p` w `input.partners[]`:
  - `p.revenue_share = input.partnership.total_revenue * (p.share_percent / 100)`
  - `p.cost_share = input.partnership.total_costs * (p.share_percent / 100)`
  - `p.income_share = p.revenue_share - p.cost_share`
  - `p.loss_share` (jeśli strata) = analogicznie proporcjonalnie
- **Podstawa prawna:** Art. 8 ust. 1-2 ustawy o PIT
- **Priorytet:** 500
- **Zależności:** Ta reguła MUSI być wykonana PRZED wszystkimi regułami PIT, KUP, zaliczek, zeznań. Bez niej system nie ma danych do dalszych obliczeń.

#### P501: `partner_pit_scale_bracket`
- **Cel biznesowy:** Ustalenie formy opodatkowania i progu podatkowego dla każdego wspólnika na skali. Każdy wspólnik może być na innej formie.
- **Przesłanki:** Dla każdego `p` w `input.partners[]`: `p.tax_form == "PIT_SCALE"`
- **Rezultat:**
  - `p.pit_form: "SCALE"`
  - Jeśli `p.cumulative_income <= input.thresholds.sc.bounds.pit_scale_threshold` → `p.pit_rate: "0.12"`, `p.pit_bracket: "LOW"`
  - Jeśli `p.cumulative_income > input.thresholds.sc.bounds.pit_scale_threshold` → `p.pit_rate: "0.32"` od nadwyżki, `p.pit_bracket: "HIGH"`
  - `p.tax_free_amount: 30000`, `p.tax_free_reduction: 3600`
  - `p.pit_annual_return_type: "PIT-36"`
- **Podstawa prawna:** Art. 27 ust. 1 PIT
- **Priorytet:** 501

#### P510: `partner_pit_linear`
- **Cel biznesowy:** Podatek liniowy 19% dla wspólnika. Brak kwoty wolnej, brak wspólnego rozliczenia.
- **Przesłanki:** `p.tax_form == "LINEAR"`
- **Rezultat:** `p.pit_rate: "0.19"`, `p.tax_free_amount: 0`, `p.pit_annual_return_type: "PIT-36L"`, `p.joint_filing: false`
- **Podstawa prawna:** Art. 30c PIT
- **Priorytet:** 510

#### P520: `partner_pit_lump_sum`
- **Cel biznesowy:** Ryczałt ewidencjonowany dla wspólnika. Uwaga: limit 2M EUR dotyczy **przychodów spółki**, nie pojedynczego wspólnika.
- **Przesłanki:** `p.tax_form == "LUMP_SUM"` AND `input.partnership.annual_turnover_net < input.thresholds.sc.limits.lump_sum_annual_limit_eur`
- **Rezultat:** `p.pit_rate` wg PKWiU, `p.pit_annual_return_type: "PIT-28"` (termin: 28 lutego)
- **Podstawa prawna:** Art. 12 ustawy o ryczałcie
- **Priorytet:** 520

#### P512_sc: `partner_linear_former_employer_restriction_sc` ★
- **Cel biznesowy:** Wspólnik nie może być na podatku liniowym jeśli świadczy usługi na rzecz byłego pracodawcy — nawet jeśli robi to przez spółkę cywilną.
- **Przesłanki:** `p.tax_form == "LINEAR"` AND `p.former_employer_nip in [vendor.nip for transactions in current_year]`
- **Rezultat:** `p.linear_blocked: true`, `p.must_use_scale: true`, `_warning: "Wspólnik X — zakaz podatku liniowego (były pracodawca)"`
- **Podstawa prawna:** Art. 9a ust. 3 PIT
- **Priorytet:** 512

---

### 5.7 sc.pit.kup — Koszty uzyskania przychodu (P560-P582)

#### P560_sc: `partner_kup_proportional` ★
- **Cel biznesowy:** KUP spółki są dzielone proporcjonalnie między wspólników. Każdy wspólnik odlicza swoją część KUP od swojego przychodu z udziału.
- **Przesłanki:** Dla każdego `p` w `input.partners[]` — KUP spółki × `p.share_percent / 100`
- **Rezultat:** `p.kup_amount: partnership_total_kup * (p.share_percent / 100)`
- **Podstawa prawna:** Art. 8 ust. 2 pkt 1 PIT, Art. 22 PIT
- **Priorytet:** 560

#### P562_sc: `partner_kup_private_mixed_sc` ★
- **Cel biznesowy:** Wydatki mieszane (prywatno-firmowe) — szczególnie problematyczne w SC, gdzie koszty mogą być generowane przez jednego wspólnika a dzielone na wszystkich.
- **Przesłanki:** `input.invoice.private_use_percent > 0` — KUP pomniejszony proporcjonalnie, a następnie dzielony między wspólników
- **Rezultat:** Dla każdego `p`: `p.kup_deductible: (total_cost * (1 - private_use_percent/100)) * (p.share_percent / 100)`
- **Podstawa prawna:** Art. 22 ust. 1 PIT, Art. 23 ust. 1 pkt 10 PIT
- **Priorytet:** 562

#### P578_sc: `partner_kup_own_work_nkup_sc` ★
- **Cel biznesowy:** Wartość własnej pracy wspólnika **NIE stanowi KUP**. To KLUCZOWE rozróżnienie — wspólnik nie może rozliczać swojej pracy jako kosztu spółki.
- **Przesłanki:** `input.invoice.beneficiary_nip in [p.nip for p in input.partners]` AND `input.invoice.expense_type == "LABOR"` AND brak umowy o pracę/cywilnoprawnej
- **Rezultat:** `kus_qualification: "none"`, `_routing: "BLOCK_AND_ALERT"`, `_warning: "Wartość własnej pracy wspólnika nie stanowi KUP (Art. 23 ust. 1 pkt 10 PIT)"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 10 PIT
- **Priorytet:** 578

#### P579_sc: `partner_kup_spouse_contract_sc` ★
- **Cel biznesowy:** Wynagrodzenie małżonka wspólnika — jest KUP tylko jeśli istnieje formalna umowa (o pracę, zlecenie, o dzieło). Bez umowy → NKUP.
- **Przesłanki:** `input.invoice.beneficiary_is_spouse_of_partner == true` AND `input.invoice.has_formal_contract == false`
- **Rezultat:** `kus_qualification: "none"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 10 PIT
- **Priorytet:** 579

---

### 5.8 sc.pit.advances — Zaliczki PIT wspólników (P540-P549)

#### P540_sc: `partner_advance_calculation_sc` ★
- **Cel biznesowy:** Obliczenie miesięcznej zaliczki na PIT dla każdego wspólnika. Zaliczka liczona od dochodu wspólnika (jego część przychodu spółki - jego część KUP).
- **Przesłanki:** Dla każdego `p` w `input.partners[]`:
  - Skala: `(p.income_share - p.zus_social_paid - p.pit_advances_paid_ytd) * p.pit_rate`
  - Liniowy: `p.income_share * 0.19` (bez kwoty wolnej)
  - Ryczałt: `p.revenue_share * lump_sum_rate`
- **Rezultat:** `p.monthly_advance: <kwota>`, `p.advance_due_date: "20. dnia następnego miesiąca"`
- **Podstawa prawna:** Art. 44 ust. 1 PIT, Art. 44 ust. 3 PIT
- **Priorytet:** 540

#### P542_sc: `partner_advance_quarterly_sc` ★
- **Cel biznesowy:** Możliwość kwartalnych zaliczek dla małych podatników. Status małego podatnika oceniany jest per wspólnik (od jego części przychodu).
- **Przesłanki:** `p.is_small_taxpayer == true` AND `p.chooses_quarterly == true`
- **Rezultat:** `p.advance_frequency: "QUARTERLY"`
- **Podstawa prawna:** Art. 44 ust. 3g PIT
- **Priorytet:** 542

---

### 5.9 sc.pit.returns — Zeznania roczne (P550-P559)

#### P550_sc: `partner_annual_return_pit36_sc` ★
- **Cel biznesowy:** Obowiązek złożenia PIT-36 przez wspólnika na skali podatkowej. Dochód z SC jest wykazywany w PIT-36 jako przychód z działalności gospodarczej.
- **Przesłanki:** `p.tax_form == "PIT_SCALE"`
- **Rezultat:** `p.annual_return_type: "PIT-36"`, `p.annual_return_deadline: "30 kwietnia"`, `p.sc_income_box: "poz. 51-53"`
- **Podstawa prawna:** Art. 45 ust. 1 PIT
- **Priorytet:** 550

#### P552_sc: `partner_annual_return_pit36l_sc` ★
- **Cel biznesowy:** PIT-36L dla wspólnika na podatku liniowym. Dochód z SC w poz. 10-12.
- **Przesłanki:** `p.tax_form == "LINEAR"`
- **Rezultat:** `p.annual_return_type: "PIT-36L"`, termin: 30 kwietnia
- **Podstawa prawna:** Art. 45 ust. 1a PIT
- **Priorytet:** 552

#### P554_sc: `partner_annual_return_pit28_sc` ★
- **Cel biznesowy:** PIT-28 dla wspólnika na ryczałcie. UWAGA: termin 28 lutego (nie 30 kwietnia!).
- **Przesłanki:** `p.tax_form == "LUMP_SUM"`
- **Rezultat:** `p.annual_return_type: "PIT-28"`, termin: **28 lutego**
- **Podstawa prawna:** Art. 21 ust. 1 ustawy o ryczałcie
- **Priorytet:** 554

---

### 5.10 sc.pit.exemptions — Zwolnienia PIT (P580-P588)

#### P580_sc: `partner_exemption_young_sc` ★
- **Cel biznesowy:** Ulga dla młodych (do 26 r.ż.) — dotyczy każdego wspólnika indywidualnie. Limit 85 528 PLN od przychodu wspólnika z udziału w SC.
- **Przesłanki:** `p.age <= 26` AND `p.annual_revenue_from_sc <= input.thresholds.sc.bounds.pit_young_exemption_limit`
- **Rezultat:** `p.pit_rate: "0.00"`, `p.exemption: "YOUNG"`, `p.exemption_applies_to: "SC_INCOME"`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 148 PIT
- **Priorytet:** 580

#### P584_sc: `partner_exemption_family_4plus_sc` ★
- **Cel biznesowy:** Ulga dla rodzin 4+ — dotyczy wspólnika mającego 4+ dzieci.
- **Przesłanki:** `p.children_count >= 4` AND `p.annual_revenue_from_sc <= input.thresholds.sc.bounds.pit_family_4plus_limit`
- **Rezultat:** `p.pit_rate: "0.00"`, `p.exemption: "FAMILY_4PLUS"`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 153 PIT
- **Priorytet:** 584

---

### 5.11 sc.partnership.lifecycle — Cykl życia spółki (P900-P939)

#### P900_sc: `sc_formation_valid` ★★★
- **Cel biznesowy:** Walidacja poprawności utworzenia spółki cywilnej. Umowa spółki musi być zawarta na piśmie (Art. 860 KC), wspólnicy muszą być zarejestrowani w CEIDG, każdy wspólnik musi mieć udział.
- **Przesłanki:** `count(input.partners) >= 2` AND każdy wspólnik ma `ceidg_registered == true` AND suma udziałów = 100% AND `input.partnership.agreement_written == true`
- **Rezultat:** `partnership_valid: true` lub `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 860 § 1-2 KC, Art. 14 Prawa przedsiębiorców
- **Priorytet:** 900

#### P902_sc: `sc_partner_change_notification` ★
- **Cel biznesowy:** Zmiana składu wspólników (przyjęcie nowego, wystąpienie) — wymaga aktualizacji CEIDG w ciągu 7 dni. Zmiana udziałów wpływa na podział przychodów/kosztów.
- **Przesłanki:** Zmiana `input.partners[]` względem stanu poprzedniego
- **Rezultat:** `ceidg_update_required: true`, `ceidg_update_deadline_days: 7`, `new_proportional_split_effective_date: <data zmiany>`
- **Podstawa prawna:** Art. 30 ust. 1 pkt 1-3 ustawy o CEIDG
- **Priorytet:** 902

#### P904_sc: `sc_dissolution_procedure` ★
- **Cel biznesowy:** Rozwiązanie spółki cywilnej — likwidacja majątku, spłata udziałów, zamknięcie VAT, ostatnie deklaracje.
- **Przesłanki:** `input.partnership.status == "DISSOLVING"`
- **Rezultat:** `liquidation_required: true`, `final_vat_declaration_required: true`, `final_inventory_required: true`, `partner_payout_calculation: <algorytm>`
- **Podstawa prawna:** Art. 874-875 KC, Art. 14 ust. 1 pkt 1 PIT (przychód z likwidacji)
- **Priorytet:** 904

#### P906_sc: `sc_partner_exit_settlement` ★
- **Cel biznesowy:** Wystąpienie wspólnika ze spółki — rozliczenie udziału, odpowiedzialność za dotychczasowe zobowiązania.
- **Przesłanki:** Partner `p` oznaczony jako `exiting == true`
- **Rezultat:** `partner_exit_date: <data>`, `partner_payout_amount: p.share_percent * partnership_net_assets`, `partner_continuing_liability: true` (za zobowiązania sprzed daty wyjścia)
- **Podstawa prawna:** Art. 869 KC, Art. 871 KC
- **Priorytet:** 906

---

### 5.12 sc.partnership.liability — Odpowiedzialność solidarna (P1150-P1174)

#### P1150_sc: `sc_joint_liability_tax` ★★★
- **Cel biznesowy:** Odpowiedzialność solidarna wspólników za zobowiązania podatkowe spółki. Każdy wspólnik odpowiada całym swoim majątkiem solidarnie ze spółką i pozostałymi wspólnikami.
- **Przesłanki:** Zobowiązanie podatkowe spółki (VAT, zaległości) — odpowiedzialność dotyczy wszystkich wspólników proporcjonalnie i solidarnie.
- **Rezultat:** `joint_liability_type: "TAX"`, `liable_parties: [wszyscy wspólnicy]`, `liability_scope: "UNLIMITED_PERSONAL"`, `legal_basis: "Art. 864 KC + Art. 115 Ordynacji podatkowej"`
- **Podstawa prawna:** Art. 864 KC, Art. 115 § 1 Ordynacji podatkowej
- **Priorytet:** 1150

#### P1152_sc: `sc_joint_liability_zus` ★
- **Cel biznesowy:** Odpowiedzialność solidarna za składki ZUS od pracowników spółki. Spółka jako płatnik — wspólnicy solidarnie.
- **Przesłanki:** Zaległość w składkach ZUS od wynagrodzeń pracowników spółki
- **Rezultat:** `joint_liability_type: "ZUS"`, `liable_parties: [wszyscy wspólnicy]`
- **Podstawa prawna:** Art. 864 KC, Art. 31 ustawy o SUS
- **Priorytet:** 1152

#### P1158_sc: `sc_partner_exit_liability` ★
- **Cel biznesowy:** Wspólnik, który wystąpił ze spółki, nadal odpowiada solidarnie za zobowiązania powstałe przed jego wystąpieniem. Odpowiedzialność trwa do czasu przedawnienia.
- **Przesłanki:** `p.exit_date < current_date` AND zobowiązanie powstało przed `p.exit_date`
- **Rezultat:** `p.still_liable: true`, `p.liability_period: "od daty powstania zobowiązania do przedawnienia"`, `p.liability_type: "SOLIDARNA_Z_POZOSTAŁYMI"`
- **Podstawa prawna:** Art. 869 § 1 KC, Art. 874 KC
- **Priorytet:** 1158

#### P1160_sc: `sc_new_partner_liability` ★
- **Cel biznesowy:** Nowy wspólnik przystępujący do spółki odpowiada również za zobowiązania powstałe przed jego przystąpieniem (Art. 864 KC — odpowiedzialność solidarna).
- **Przesłanki:** `p.join_date > debt_incurred_date`
- **Rezultat:** `p.liable_for_prior_debts: true`, `_warning: "Nowy wspólnik odpowiada za zobowiązania sprzed przystąpienia"`
- **Podstawa prawna:** Art. 864 KC
- **Priorytet:** 1160

---

### 5.13 sc.partnership.succession — Sukcesja (P920-P929)

#### P920_sc: `sc_succession_partner_death` ★★★
- **Cel biznesowy:** Śmierć wspólnika spółki cywilnej. Zarządca sukcesyjny może kontynuować działalność spółki. Spółka może funkcjonować dalej jeśli zostało co najmniej 2 wspólników (lub zarządca + pozostali).
- **Przesłanki:** Partner `p` oznaczony jako `deceased == true`
- **Rezultat:**
  - Jeśli `count(remaining_partners) >= 2`: spółka trwa dalej, udziały pozostałych wspólników mogą być proporcjonalnie zwiększone
  - Jeśli `count(remaining_partners) < 2`: spółka rozwiązuje się (Art. 872 KC)
  - `succession_manager_appointed: true/false`
  - `nip_with_succession_suffix: true`
- **Podstawa prawna:** Art. 872 KC, Ustawa o zarządzie sukcesyjnym (Dz.U. 2025 poz. 1234)
- **Priorytet:** 920

#### P922_sc: `sc_succession_tax_obligations` ★
- **Cel biznesowy:** Obowiązki podatkowe po śmierci wspólnika — zarządca sukcesyjny kontynuuje rozliczenia podatkowe. Spadkobiercy dziedziczą udział w SC.
- **Przesłanki:** `p.deceased == true` AND `p.has_succession_manager == true`
- **Rezultat:** `tax_continuity: true`, `succession_manager_responsible: true`, `final_pit_for_deceased: true` (zeznanie do dnia śmierci)
- **Podstawa prawna:** Art. 97 § 1 Ordynacji podatkowej, Art. 7, 11 ustawy o zarządzie sukcesyjnym
- **Priorytet:** 922

---

### 5.14 sc.partnership.suspension — Zawieszenie (P910-P919)

#### P910_sc: `sc_suspension_valid` ★
- **Cel biznesowy:** Zawieszenie działalności spółki cywilnej. Wymaga zawieszenia wszystkich wspólników. Skutki: brak zaliczek PIT, zerowe deklaracje VAT, tylko koszty stałe.
- **Przesłanki:** `input.partnership.status == "SUSPENDED"` AND wszyscy wspólnicy mają `suspended == true`
- **Rezultat:**
  - `vat_declarations: "ZERO"` (jeśli brak sprzedaży)
  - `pit_advances: "NOT_REQUIRED"`
  - `costs_allowed: "MAINTENANCE_ONLY"` (czynsz, media, ZUS)
  - `new_invoices_blocked: true`
- **Podstawa prawna:** Art. 22-25 Prawa przedsiębiorców, Art. 44 ust. 10 PIT, Art. 99 ust. 7a VAT
- **Priorytet:** 910

#### P912_sc: `sc_suspension_partial_warning` ★
- **Cel biznesowy:** Jeśli nie wszyscy wspólnicy zawiesili działalność — spółka formalnie nadal działa. Ostrzeżenie o ryzyku.
- **Przesłanki:** `input.partnership.status == "SUSPENDED"` AND `count([p | p.suspended == false]) > 0`
- **Rezultat:** `_warning: "Nie wszyscy wspólnicy zawiesili działalność — spółka może być uznana za aktywną"`
- **Podstawa prawna:** Art. 22 Prawa przedsiębiorców
- **Priorytet:** 912

---

### 5.15 sc.zus.partners — ZUS wspólników (P700-P770)

> **Kluczowa zasada:** Każdy wspólnik spółki cywilnej podlega ubezpieczeniom społecznym **indywidualnie**. Składki są liczone od dochodu wspólnika z udziału w SC. Spółka jako taka nie płaci ZUS za wspólników.

#### P700_sc: `partner_zus_social_standard_sc` ★
- **Cel biznesowy:** Standardowe składki społeczne dla wspólnika SC. Podstawa: 60% prognozowanego przeciętnego wynagrodzenia. Składki opłacane indywidualnie przez każdego wspólnika.
- **Przesłanki:** `p.zus_status == "STANDARD"`
- **Rezultat:**
  - `p.zus_pension: podstawa * 0.1952`
  - `p.zus_disability: podstawa * 0.08`
  - `p.zus_sickness: podstawa * 0.0245` (DOBROWOLNA)
  - `p.zus_accident: podstawa * 0.0167`
  - `p.zus_labour_fund: podstawa * 0.0245`
- **Podstawa prawna:** Art. 18, 18a, 22 ustawy o SUS
- **Priorytet:** 700

#### P743_sc: `partner_concurrent_employment_sc` ★
- **Cel biznesowy:** Zbieg etat + udział w SC — jeśli wspólnik jest jednocześnie pracownikiem (umowa o pracę) z wynagrodzeniem ≥ minimalne, z działalności w SC płaci tylko składkę zdrowotną.
- **Przesłanki:** `p.has_employment_contract == true` AND `p.employment_salary >= input.thresholds.sc.bounds.minimum_wage_gross`
- **Rezultat:** `p.zus_social_from_sc: "0.00"`, `p.zus_health_due: true`, `p.concurrent_status: "EMPLOYMENT_AND_SC"`
- **Podstawa prawna:** Art. 9 ust. 1a-2 ustawy o SUS
- **Priorytet:** 743

#### P745_sc: `partner_zus_different_statuses_sc` ★
- **Cel biznesowy:** Różni wspólnicy mogą mieć różny status ZUS (jeden standard, drugi Mały ZUS Plus, trzeci ulga na start). System musi obsłużyć każdą kombinację.
- **Przesłanki:** Dla każdego `p` — indywidualna ocena `p.zus_status`
- **Rezultat:** Niezależne obliczenia składek dla każdego wspólnika
- **Podstawa prawna:** Art. 18a, 18c ustawy o SUS
- **Priorytet:** 745

---

### 5.16 sc.zus.health — Składka zdrowotna (P720-P749)

#### P720_sc: `partner_zus_health_scale_sc` ★
- **Cel biznesowy:** Składka zdrowotna 9% od dochodu wspólnika na skali. NIE odlicza się od podatku przy skali (Polski Ład).
- **Przesłanki:** `p.tax_form == "PIT_SCALE"`
- **Rezultat:** `p.zus_health_rate: "0.09"`, `p.zus_health_base: "INCOME"`, `p.zus_health_deductible_from_tax: false`
- **Podstawa prawna:** Art. 79 ust. 1, art. 81 ust. 1 ustawy o świadczeniach opieki zdrowotnej
- **Priorytet:** 720

#### P722_sc: `partner_zus_health_linear_sc` ★
- **Cel biznesowy:** Składka zdrowotna 4.9% dla wspólnika na liniowym. Limit odliczenia od dochodu: 12 900 PLN rocznie.
- **Przesłanki:** `p.tax_form == "LINEAR"`
- **Rezultat:** `p.zus_health_rate: "0.049"`, `p.zus_health_deductible_limit: 12900`
- **Podstawa prawna:** Art. 81 ust. 1 ustawy o świadczeniach opieki zdrowotnej
- **Priorytet:** 722

#### P749_sc: `partner_lump_sum_health_annual_sc` ★
- **Cel biznesowy:** Roczne rozliczenie składki zdrowotnej dla wspólnika na ryczałcie. 3 progi zależne od rocznego przychodu wspólnika.
- **Przesłanki:** `p.tax_form == "LUMP_SUM"`
- **Rezultat:**
  - Próg I (≤60k): `health_base = 60% * average_wage`
  - Próg II (60k-300k): `health_base = 100% * average_wage`
  - Próg III (>300k): `health_base = 180% * average_wage`
- **Podstawa prawna:** Art. 81 ust. 2a-2c ustawy o świadczeniach opieki zdrowotnej
- **Priorytet:** 749

---

### 5.17 sc.accounting.full — Pełna księgowość (P800-P894)

#### P806_sc: `sc_full_accounting_threshold` ★★★
- **Cel biznesowy:** **KLUCZOWA REGUŁA:** Spółka cywilna, której przychód netto za poprzedni rok przekroczył równowartość 2 000 000 EUR, ma **obowiązek** prowadzenia pełnej księgowości (księgi rachunkowe) zgodnie z UoR. Poniżej progu — PKPiR.
- **Przesłanki:** `input.partnership.annual_turnover_net_prev_year >= input.thresholds.sc.limits.full_accounting_threshold_eur * nbp_eur_rate`
- **Rezultat:** `accounting_method: "FULL"`, `uor_compliance_required: true`:
  - Art. 4 UoR: zasada memoriału, współmierności, ostrożności
  - Art. 10 UoR: dziennik, księga główna, księgi pomocnicze
  - Art. 12 UoR: otwarcie i zamknięcie ksiąg
  - Art. 20-21 UoR: dowody księgowe
  - Art. 22 UoR: podwójny zapis (Wn=Ma)
  - Art. 26 UoR: inwentaryzacja
  - Art. 28 UoR: wycena aktywów i pasywów
  - Art. 32 UoR: amortyzacja
  - Art. 74 UoR: przechowywanie dokumentacji 5 lat
- **Podstawa prawna:** Art. 2 ust. 1 pkt 1 UoR (spółka cywilna jako jednostka), Art. 24a ust. 4 PIT
- **Priorytet:** 806
- **Zależności:** Sprawdzana PRZED regułami PKPiR. Jeśli FULL → pomiń PKPiR.

#### P808_sc: `sc_double_entry_validation` ★
- **Cel biznesowy:** Walidacja podwójnego zapisu — Wn musi równać się Ma. Blokada niezbilansowanego zapisu księgowego.
- **Przesłanki:** `input.partnership.accounting_method == "FULL"` AND `abs(sum(debit) - sum(credit)) > 0.01`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `_warning: "Zapis niezbilansowany — naruszenie Art. 22 UoR"`
- **Podstawa prawna:** Art. 22 ust. 1 UoR
- **Priorytet:** 808

#### P810_sc: `sc_closing_books_mandatory` ★
- **Cel biznesowy:** Blokada księgowania w zamkniętym roku obrotowym. Wymaga korekty błędu podstawowego.
- **Przesłanki:** `input.invoice.issue_date <= input.partnership.closed_financial_year_end` AND `input.partnership.fs_approved == true`
- **Rezultat:** `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 12 ust. 2 pkt 1 UoR
- **Priorytet:** 810

---

### 5.18 sc.accounting.pkpir — PKPiR spółki (P800-P805)

#### P800_sc: `sc_pkpir_column_mapping` ★
- **Cel biznesowy:** Mapowanie wydatków spółki na 16 kolumn PKPiR. Spółka prowadzi **jedną wspólną** PKPiR.
- **Przesłanki:** `input.partnership.accounting_method == "PKPIR"`
- **Rezultat:** `pkpir_column: <numer 1-16>`:
  - Kol. 6: przychód ze sprzedaży towarów
  - Kol. 7: przychód ze sprzedaży usług
  - Kol. 9: zakup towarów
  - Kol. 10: koszty uboczne zakupu
  - Kol. 11: wynagrodzenia
  - Kol. 12: pozostałe wydatki
  - Kol. 14: NKUP
  - Kol. 15: środki trwałe
- **Podstawa prawna:** Rozporządzenie MF w sprawie PKPiR
- **Priorytet:** 800

#### P805_sc: `sc_pkpir_partner_split_for_pit` ★
- **Cel biznesowy:** Dane z PKPiR spółki są podstawą do wyliczenia przychodu i KUP każdego wspólnika proporcjonalnie do udziałów (dla zeznań PIT).
- **Przesłanki:** `input.partnership.accounting_method == "PKPIR"`
- **Rezultat:** Dla każdego wspólnika: `p.pkpir_revenue = total_revenue * (p.share_percent / 100)`, `p.pkpir_costs = total_costs * (p.share_percent / 100)`
- **Podstawa prawna:** Art. 8 PIT, Art. 24a PIT
- **Priorytet:** 805

---

### 5.19 sc.accounting.depreciation — Amortyzacja (P840-P870)

#### P840_sc: `sc_depreciation_linear` ★
- **Cel biznesowy:** Amortyzacja liniowa środków trwałych spółki. Stawki z KŚT. Odpisy amortyzacyjne stanowią KUP spółki, które są następnie dzielone między wspólników.
- **Przesłanki:** `input.invoice.expense_type == "FIXED_ASSET"` AND metoda liniowa
- **Rezultat:** `depreciation_method: "LINEAR"`, `annual_rate: <z KŚT>`, `monthly_write_off: <kwota>`
- **Podstawa prawna:** Art. 22a-22m PIT, Art. 32 UoR, KŚT
- **Priorytet:** 840

#### P842_sc: `sc_depreciation_one_off` ★
- **Cel biznesowy:** Jednorazowa amortyzacja dla małych podatników. Status małego podatnika oceniany na poziomie spółki (przychód spółki < 2M EUR).
- **Przesłanki:** `input.partnership.is_small_taxpayer == true` AND `input.invoice.amount_net <= input.thresholds.sc.limits.one_off_depreciation_limit_eur * nbp_eur_rate`
- **Rezultat:** `depreciation_method: "ONE_OFF"`, `depreciation_rate: "1.00"`
- **Podstawa prawna:** Art. 22k ust. 7 PIT
- **Priorytet:** 842

---

### 5.20 sc.ksef — KSeF (P950-P960)

#### P950_sc: `sc_ksef_mandatory` ★
- **Cel biznesowy:** Obowiązek KSeF dla spółki cywilnej od 1 lutego 2026 r. Spółka jako czynny podatnik VAT wystawia faktury ustrukturyzowane.
- **Przesłanki:** `input.invoice.transaction_date >= "2026-02-01"` AND `input.partnership.is_vat_payer == true` AND `input.invoice.direction == "SALE"` AND NIE B2C
- **Rezultat:** `ksef_required: true`, `ksef_format: "XML_XSD"`, `ksef_upo_required: true`
- **Podstawa prawna:** Art. 106na-106nq VAT, Dz.U. 2023 poz. 1598
- **Priorytet:** 950

#### P955_sc: `sc_ksef_qr_code` ★
- **Cel biznesowy:** Obowiązek umieszczenia kodu QR na fakturze KSeF.
- **Przesłanki:** `input.invoice.is_ksef == true`
- **Rezultat:** `qr_code_required: true`, `qr_code_content: <URL do faktury w KSeF>`
- **Podstawa prawna:** Art. 106nh VAT
- **Priorytet:** 955

---

### 5.21 sc.jpk — JPK (P970-P989)

#### P970_sc: `sc_jpk_v7m` ★
- **Cel biznesowy:** JPK_V7M — miesięczna deklaracja VAT spółki. Spółka cywilna składa **jedną** deklarację VAT (własny NIP). Termin: 25. dnia następnego miesiąca.
- **Przesłanki:** `input.partnership.is_vat_payer == true`
- **Rezultat:** `jpk_v7m_required: true`, `jpk_deadline: "25. dnia miesiąca"`, `jpk_entity_nip: partnership_nip`
- **Podstawa prawna:** Art. 99 ust. 1 VAT
- **Priorytet:** 970

#### P975_sc: `sc_jpk_gtu_completeness` ★
- **Cel biznesowy:** Weryfikacja kompletności oznaczeń GTU w JPK_V7 spółki. Brak kodu GTU = odrzucenie JPK.
- **Przesłanki:** `input.invoice.category_code` wymaga GTU AND `input.invoice.gtu_code == ""`
- **Rezultat:** `gtu_missing: true`, `_routing: "TRIAGE_QUEUE"`
- **Podstawa prawna:** § 10 rozporządzenia JPK_VAT
- **Priorytet:** 975

---

### 5.22 sc.employer — Spółka jako pracodawca (P1200-P1223)

#### P1200_sc: `sc_employer_obligation` ★
- **Cel biznesowy:** Spółka cywilna zatrudniająca pracowników jest płatnikiem PIT i ZUS. Obowiązki płatnika ciążą na spółce, a odpowiedzialność solidarna — na wspólnikach.
- **Przesłanki:** `input.partnership.employees_count > 0`
- **Rezultat:**
  - `employer_mode: true`
  - `pit_4r_required: true` (miesięcznie)
  - `pit_11_required: true` (rocznie)
  - `zus_rca_required: true` (miesięcznie)
  - `ppk_obligation_check: true` (zależnie od liczby zatrudnionych)
- **Podstawa prawna:** Art. 31-32 PIT, Art. 17-19 SUS
- **Priorytet:** 1200

#### P1202_sc: `sc_payroll_partner_exclusion` ★
- **Cel biznesowy:** Wynagrodzenia wspólników z tytułu pracy w spółce — specyficzne zasady. Wspólnik nie jest pracownikiem w rozumieniu KP, chyba że ma umowę o pracę.
- **Przesłanki:** `input.invoice.beneficiary_is_partner == true` AND `input.invoice.type == "LABOR"`
- **Rezultat:**
  - Jeśli umowa o pracę: standardowe zasady (PIT, ZUS jak pracownik)
  - Jeśli brak umowy: NKUP (Art. 23 ust. 1 pkt 10 PIT)
- **Podstawa prawna:** Art. 23 ust. 1 pkt 10 PIT, Art. 8 ust. 2 PIT
- **Priorytet:** 1202

---

### 5.23 sc.allowances — Ulgi podatkowe (P600-P635)

> Ulgi stosowane są **indywidualnie przez każdego wspólnika** od jego części dochodu.

#### P600_sc: `partner_relief_rd_sc` ★
- **Cel biznesowy:** Ulga B+R — wspólnik może odliczyć od swojego dochodu koszty B+R poniesione przez spółkę (w części proporcjonalnej do udziału).
- **Przesłanki:** `p.has_rd_status == true` AND spółka poniosła koszty B+R
- **Rezultat:** `p.relief_rd_amount: partnership_rd_costs * (p.share_percent / 100) * relief_percent`
- **Podstawa prawna:** Art. 26e PIT
- **Priorytet:** 600

#### P615_sc: `partner_loss_carry_forward_sc` ★
- **Cel biznesowy:** Rozliczenie straty z udziału w SC. Każdy wspólnik rozlicza swoją część straty spółki (proporcjonalnie do udziału).
- **Przesłanki:** `p.has_loss_from_sc == true`
- **Rezultat:** `p.loss_deduction: min(p.current_income * 0.50, p.remaining_loss)`, `p.loss_carry_forward_years: 5`
- **Podstawa prawna:** Art. 9 ust. 3 PIT
- **Priorytet:** 615

---

### 5.24 sc.local — Podatki lokalne (P1300-P1320)

#### P1300_sc: `sc_pcc_exemption_sc_formation` ★
- **Cel biznesowy:** PCC od umowy spółki cywilnej — co do zasady nie podlega PCC (spółka cywilna nie jest spółką kapitałową). Ale PCC może wystąpić przy pożyczkach między wspólnikami a spółką.
- **Przesłanki:** `input.invoice.type == "LOAN"` AND `input.vendor.nip in [partners nips]`
- **Rezultat:** `pcc_rate: "0.005"`, `pcc_return_required: true` (PCC-3 w 14 dni)
- **Podstawa prawna:** Art. 1 ust. 1 pkt 1 lit. a, Art. 7 ust. 1 pkt 4 PCC
- **Priorytet:** 1300

---

### 5.25 sc.corrections — Korekty (P1100-P1120)

#### P1100_sc: `sc_correction_invoice_in_minus` ★
- **Cel biznesowy:** Korekta faktury in minus — wpływa na JPK_V7 spółki (zmniejszenie VAT należnego/naliczonego) ORAZ na przychody/KUP wspólników (proporcjonalnie).
- **Przesłanki:** `input.invoice.is_correction == true` AND `input.invoice.correction_type == "IN_MINUS"`
- **Rezultat:**
  - VAT: korekta w okresie otrzymania potwierdzenia
  - PIT: korekta przychodu/KUP per wspólnik proporcjonalnie
- **Podstawa prawna:** Art. 29a ust. 13 VAT, Art. 14 ust. 1m PIT
- **Priorytet:** 1100

---

### 5.26 sc.international — Międzynarodowe (P100-P117)

#### P114_sc: `sc_tp_documentation` ★
- **Cel biznesowy:** Ceny transferowe — spółka cywilna zawierająca transakcje z podmiotami powiązanymi (w tym ze wspólnikami!) powyżej progu musi sporządzić dokumentację TP.
- **Przesłanki:** `input.vendor.is_related_party == true` AND transakcja > próg TP
- **Rezultat:** `tp_documentation_required: true`, `tp_local_file: true`
- **Podstawa prawna:** Art. 23m-23zp PIT (dla wspólników)
- **Priorytet:** 114

---

### 5.27 sc.fallback — Reguły domyślne (P1000-P1099)

#### P1000: `sc_domestic_fallback`
- **Cel biznesowy:** Domyślna stawka VAT 23% dla Polski gdy żadna konkretna reguła nie pasuje.
- **Przesłanki:** `input.vendor.country == "PL"` AND brak dopasowania szczegółowej reguły
- **Rezultat:** `vat_rate: input.thresholds.sc.rates.vat_standard`, `rounding_level: "position"`
- **Podstawa prawna:** Art. 41 ust. 1 VAT
- **Priorytet:** 1000

#### P1099: `sc_no_match`
- **Cel biznesowy:** Ostateczny fallback gdy żadna reguła w systemie nie pasuje.
- **Przesłanki:** Żadna reguła nie dopasowana
- **Rezultat:** `matched: false`, `error: "NO_MATCHING_RULE"`, `_routing: "TRIAGE_QUEUE"`
- **Priorytet:** 1099


---

## 6. Wymagane Dane Wejściowe (input)

### 6.1 Pełna Struktura `input` dla Spółki Cywilnej

Struktura `input` jest rozszerzeniem specyfikacji z `01_INPUT_SPEC.md` o sekcje specyficzne dla spółki cywilnej. Wszystkie wartości liczbowe pochodzą z `input.thresholds.sc.*`.

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
    "is_correction": false,
    "correction_type": "",
    "is_vat_deducted": false,
    "months_since_issue": 0,
    "delivery_date": "2026-06-10",
    "vat_taxable": true,
    "beneficiary_nip": "",
    "beneficiary_is_partner": false,
    "beneficiary_is_spouse_of_partner": false,
    "has_formal_contract": false,
    "is_ksef": false
  },
  "vendor": {
    "nip": "1234567890",
    "country": "PL",
    "vat_status": "active",
    "on_whitelist": true,
    "account_on_whitelist": true,
    "whitelist_checked_at": "2026-06-15T10:00:00Z",
    "ceidg_status": "ACTIVE",
    "pkd": "62.01.Z",
    "is_related_party": false,
    "trust_score": 0.92,
    "fraud_flag": false,
    "is_new": false,
    "is_b2b_buyer": false,
    "is_b2c": false,
    "is_family_foundation": false,
    "is_flat_rate_farmer": false
  },
  "partnership": {
    "nip": "1234567890",
    "name": "XYZ Spółka Cywilna",
    "status": "ACTIVE",
    "is_vat_payer": true,
    "is_vat_eu_registered": true,
    "vat_status": "active",
    "agreement_written": true,
    "agreement_date": "2020-01-15",
    "annual_turnover_net": 1800000.00,
    "annual_turnover_net_prev_year": 1500000.00,
    "is_small_taxpayer": true,
    "accounting_method": "PKPIR",
    "employees_count": 3,
    "fiscal_year_start": "2026-01-01",
    "closed_financial_year_end": "2025-12-31",
    "fs_approved": false,
    "has_rd_costs": false,
    "rd_costs_annual": 0,
    "total_revenue": 10000.00,
    "total_costs": 6000.00,
    "total_income": 4000.00
  },
  "partners": [
    {
      "partner_id": "P1",
      "nip": "1111111111",
      "share_percent": 50.0,
      "tax_form": "PIT_SCALE",
      "zus_status": "STANDARD",
      "zus_months_used_current_status": 12,
      "ceidg_registered": true,
      "suspended": false,
      "age": 36,
      "children_count": 2,
      "has_employment_contract": false,
      "employment_salary": 0,
      "cumulative_income": 85000.00,
      "is_small_taxpayer": true,
      "chooses_quarterly": false,
      "has_rd_status": false,
      "has_loss_from_sc": false,
      "exit_date": null,
      "join_date": "2020-01-15",
      "deceased": false,
      "has_succession_manager": false,
      "former_employer_nip": ""
    },
    {
      "partner_id": "P2",
      "nip": "2222222222",
      "share_percent": 50.0,
      "tax_form": "LINEAR",
      "zus_status": "MALY_ZUS_PLUS",
      "zus_months_used_current_status": 18,
      "ceidg_registered": true,
      "suspended": false,
      "age": 45,
      "children_count": 0,
      "has_employment_contract": true,
      "employment_salary": 6000.00,
      "cumulative_income": 120000.00,
      "is_small_taxpayer": false,
      "chooses_quarterly": false,
      "has_rd_status": true,
      "has_loss_from_sc": false,
      "exit_date": null,
      "join_date": "2020-01-15",
      "deceased": false,
      "has_succession_manager": false,
      "former_employer_nip": ""
    }
  ],
  "confidence": {
    "fc_minimum": 0.97,
    "fc_vat_rate": 0.99,
    "fc_total_net": 0.98,
    "fc_vendor_nip": 0.99,
    "fc_category_code": 0.97
  },
  "document": {
    "evaluation_date": null,
    "type": "",
    "audit_in_progress": false
  },
  "system": {
    "ksef_status": "ONLINE",
    "auth_token_exists": true,
    "qualified_signature_exists": true
  },
  "thresholds": {
    "sc": {
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
        "pcc_standard": "0.02",
        "pcc_loan": "0.005"
      },
      "limits": {
        "mpp_limit": 15000,
        "vat_exemption_limit": 200000,
        "cash_transaction_limit": 15000,
        "bad_debt_days_vat": 150,
        "bad_debt_days_cit_pit": 90,
        "full_accounting_threshold_eur": 2000000,
        "pkpir_revenue_limit_eur": 2000000,
        "lump_sum_annual_limit_eur": 2000000,
        "one_off_depreciation_limit_eur": 50000,
        "retention_years_invoice": 5,
        "retention_years_ledger": 5,
        "retention_years_payroll": 10,
        "trust_auto_post": 0.92,
        "trust_suggest": 0.75,
        "car_value_kup_limit": 150000,
        "electric_car_kup_limit": 225000,
        "cash_register_exemption_limit": 20000,
        "statute_years_tax": 5,
        "suspension_max_months": 24
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
        "real_estate_depreciation_rate": 0.025,
        "ceidg_update_deadline_days": 7
      },
      "fc_thresholds": {
        "vat_rate": 0.95,
        "total_net": 0.90,
        "minimum": 0.85,
        "vendor_nip": 0.80,
        "category_code": 0.80,
        "global_minimum": 0.70
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

### 6.2 Kluczowe sekcje — opis

#### `input.partnership` — Dane spółki

| Pole | Typ | Opis |
|------|-----|------|
| `nip` | `string` | NIP spółki cywilnej (odrębny od NIP wspólników) |
| `name` | `string` | Nazwa spółki |
| `status` | `string` | Status: ACTIVE, SUSPENDED, DISSOLVING, DISSOLVED |
| `is_vat_payer` | `boolean` | Czy spółka jest czynnym podatnikiem VAT |
| `is_vat_eu_registered` | `boolean` | Czy spółka ma VAT-UE |
| `vat_status` | `string` | Status VAT: active, exempt, unregistered |
| `agreement_written` | `boolean` | Czy umowa spółki zawarta na piśmie (Art. 860 KC) |
| `agreement_date` | `string` | Data zawarcia umowy spółki |
| `annual_turnover_net` | `number` | Roczny obrót netto spółki (suma wszystkich wspólników) |
| `annual_turnover_net_prev_year` | `number` | Obrót netto za poprzedni rok (do progu 2M EUR) |
| `is_small_taxpayer` | `boolean` | Status małego podatnika (przychód < 2M EUR) |
| `accounting_method` | `string` | Metoda księgowa: PKPIR, FULL |
| `employees_count` | `number` | Liczba pracowników spółki |
| `total_revenue` | `number` | Całkowity przychód spółki w okresie |
| `total_costs` | `number` | Całkowite koszty spółki w okresie |

#### `input.partners[]` — Dane wspólników

| Pole | Typ | Opis |
|------|-----|------|
| `partner_id` | `string` | Unikalny identyfikator wspólnika |
| `nip` | `string` | NIP wspólnika (osoba fizyczna) |
| `share_percent` | `number` | Udział w zysku w procentach (suma = 100%) |
| `tax_form` | `string` | Forma opodatkowania: PIT_SCALE, LINEAR, LUMP_SUM, TAX_CARD |
| `zus_status` | `string` | Status ZUS: STANDARD, MALY_ZUS_PLUS, PREFERENTIAL, START_RELIEF |
| `ceidg_registered` | `boolean` | Czy zarejestrowany w CEIDG |
| `age` | `number` | Wiek (dla ulgi dla młodych) |
| `children_count` | `number` | Liczba dzieci (dla ulgi 4+) |
| `has_employment_contract` | `boolean` | Czy ma umowę o pracę (zbieg etat+SC) |
| `employment_salary` | `number` | Wynagrodzenie z etatu |
| `cumulative_income` | `number` | Narastający dochód roczny (do progu 120k) |
| `exit_date` | `string` | Data wystąpienia (null jeśli nadal w spółce) |
| `join_date` | `string` | Data przystąpienia do spółki |
| `deceased` | `boolean` | Czy zmarł |
| `has_succession_manager` | `boolean` | Czy ustanowiono zarządcę sukcesyjnego |

### 6.3 Walidacja wejścia

```rego
# Walidacja minimalna SC
required_fields_sc := [
    "invoice.category_code",
    "invoice.transaction_date",
    "vendor.country",
    "vendor.vat_status",
    "partnership.nip",
    "partners",
]

# Walidacja min. 2 wspólników
valid_partner_count {
    count(input.partners) >= 2
}

# Walidacja sumy udziałów = 100%
valid_share_total {
    sum([p.share_percent | p := input.partners[_]]) == 100.0
}
```

---

## 7. Obsługa Parametrów Dynamicznych (thresholds)

### 7.1 Katalog Thresholdów SC

#### Stawki podatkowe (`thresholds.sc.rates.*`)

| Klucz | Wartość | Typ | Podstawa prawna | Opis |
|---|---|---|---|---|
| `rates.vat_standard` | `"0.23"` | `string` | Art. 41 ust. 1 VAT | VAT 23% |
| `rates.vat_reduced_8` | `"0.08"` | `string` | Art. 41 ust. 2 VAT | VAT 8% |
| `rates.vat_reduced_5` | `"0.05"` | `string` | Art. 41 ust. 2a VAT | VAT 5% |
| `rates.vat_zero` | `"0.00"` | `string` | Art. 83 VAT | VAT 0% |
| `rates.pit_scale_low` | `"0.12"` | `string` | Art. 27 ust. 1 PIT | PIT I próg 12% |
| `rates.pit_scale_high` | `"0.32"` | `string` | Art. 27 ust. 1 PIT | PIT II próg 32% |
| `rates.pit_linear` | `"0.19"` | `string` | Art. 30c PIT | PIT liniowy 19% |
| `rates.pit_ip_box` | `"0.05"` | `string` | Art. 30ca PIT | IP Box 5% |
| `rates.pit_crypto` | `"0.19"` | `string` | Art. 30b PIT | Krypto 19% |
| `rates.zus_pension` | `"0.1952"` | `string` | Art. 22 SUS | Emerytalna 19,52% |
| `rates.zus_disability` | `"0.08"` | `string` | Art. 22 SUS | Rentowa 8% |
| `rates.zus_sickness` | `"0.0245"` | `string` | Art. 22 SUS | Chorobowa 2,45% |
| `rates.zus_accident` | `"0.0167"` | `string` | Art. 22 SUS | Wypadkowa 1,67% |
| `rates.zus_health_scale` | `"0.09"` | `string` | Art. 79 u.zdrowotnej | Zdrowotna skala 9% |
| `rates.zus_health_linear_lump` | `"0.049"` | `string` | Art. 81 u.zdrowotnej | Zdrowotna liniowy/ryczałt 4,9% |
| `rates.zus_labour_fund` | `"0.0245"` | `string` | Art. 22 SUS | FP 2,45% |
| `rates.zus_fgsp` | `"0.001"` | `string` | Art. 22 SUS | FGŚP 0,1% |

#### Limity kwotowe (`thresholds.sc.limits.*`)

| Klucz | Wartość | Typ | Podstawa prawna | Opis |
|---|---|---|---|---|
| `limits.mpp_limit` | `15000` | `number` | Art. 108a VAT | Próg MPP |
| `limits.vat_exemption_limit` | `200000` | `number` | Art. 113 VAT | Limit zwolnienia podmiotowego |
| `limits.cash_transaction_limit` | `15000` | `number` | Art. 22p PIT | Limit gotówki |
| `limits.bad_debt_days_vat` | `150` | `number` | Art. 89a VAT | Złe długi VAT |
| `limits.bad_debt_days_cit_pit` | `90` | `number` | Art. 89b VAT | OBOWIĄZEK dłużnika |
| `limits.full_accounting_threshold_eur` | `2000000` | `number` | Art. 2 ust. 1 pkt 1 UoR | Próg pełnej księgowości |
| `limits.pkpir_revenue_limit_eur` | `2000000` | `number` | Art. 24a PIT | Limit PKPiR |
| `limits.lump_sum_annual_limit_eur` | `2000000` | `number` | Art. 6 u. ryczałtowej | Limit ryczałtu |
| `limits.one_off_depreciation_limit_eur` | `50000` | `number` | Art. 22k PIT | Limit jednorazowej amortyzacji |
| `limits.retention_years_invoice` | `5` | `number` | Art. 86 Ordynacji | Okres faktur |
| `limits.retention_years_ledger` | `5` | `number` | Art. 74 UoR | Okres ksiąg |
| `limits.retention_years_payroll` | `10` | `number` | Art. 125a u.emeryt. | Okres płac |
| `limits.car_value_kup_limit` | `150000` | `number` | Art. 23 PIT | Limit auta |
| `limits.electric_car_kup_limit` | `225000` | `number` | Art. 23 PIT | Limit EV |
| `limits.suspension_max_months` | `24` | `number` | Art. 22 Pr. przeds. | Max zawieszenia |

#### Progi podatkowe (`thresholds.sc.bounds.*`)

| Klucz | Wartość | Typ | Podstawa prawna | Opis |
|---|---|---|---|---|
| `bounds.pit_scale_threshold` | `120000` | `number` | Art. 27 PIT | Próg 12%/32% |
| `bounds.pit_tax_free_amount` | `30000` | `number` | Art. 27 PIT | Kwota wolna |
| `bounds.pit_tax_free_reduction` | `3600` | `number` | Art. 27 PIT | Zmniejszenie podatku |
| `bounds.pit_young_exemption_limit` | `85528` | `number` | Art. 21 PIT | Ulga młodzi |
| `bounds.pit_return_exemption_limit` | `85528` | `number` | Art. 21 PIT | Ulga powrót |
| `bounds.pit_family_4plus_limit` | `85528` | `number` | Art. 21 PIT | Ulga 4+ |
| `bounds.relief_thermo_max` | `53000` | `number` | Art. 26h PIT | Ulga termo |
| `bounds.zus_start_months` | `6` | `number` | Art. 18a SUS | Ulga start |
| `bounds.zus_preferential_months` | `24` | `number` | Art. 18a SUS | Preferencyjny |
| `bounds.zus_maly_plus_months` | `36` | `number` | Art. 18c SUS | Mały ZUS+ |
| `bounds.zus_health_linear_deduction_limit` | `12900` | `number` | Art. 30c PIT | Limit zdrowotnej liniowy |
| `bounds.minimum_wage_gross` | `4666` | `number` | Rozp. RM | Minimalne wynagrodzenie |
| `bounds.ceidg_update_deadline_days` | `7` | `number` | Art. 30 CEIDG | Termin aktualizacji |

### 7.2 Rego Helper — proporcjonalny podział

```rego
# Helper: proporcjonalny podział dla każdego wspólnika
partner_split(result_key) := [
    {
        "partner_id": p.partner_id,
        "nip": p.nip,
        "share_percent": p.share_percent,
        "value": round(input.partnership.total_revenue * p.share_percent / 100, 2)
    }
    | p := input.partners[_]
] {
    result_key == "revenue"
}

# Helper: suma udziałów = 100%
valid_partner_shares {
    shares := [p.share_percent | p := input.partners[_]]
    sum(shares) == 100.0
}

# Helper: czy spółka przekracza próg pełnej księgowości
requires_full_accounting {
    threshold_pln := input.thresholds.sc.limits.full_accounting_threshold_eur * nbp_eur_rate
    input.partnership.annual_turnover_net_prev_year >= threshold_pln
}
```

---

## 8. Architektura Multi-Pass — Scalanie Werdyktów

### 8.1 VerdictMerger dla SC

```python
class ScVerdictMerger:
    """Scala werdykty z 10+ passów OPA w jeden finalny werdykt SC."""
    
    def merge(self, passes: list[dict]) -> dict:
        verdict = {
            "matched": True,
            "rule_id": [],
            "packages": [],
            
            # VAT (dotyczy spółki)
            "vat_rate": None,
            "rounding_level": None,
            "gtu_code": None,
            "procedure": None,
            "vat_exemption": None,
            
            # Partnerzy (tablica wyników per wspólnik)
            "partners_results": [],
            
            # Spółka
            "partnership": {
                "total_revenue": 0,
                "total_costs": 0,
                "total_income": 0,
                "partner_count": 0,
                "accounting_method": None,
                "full_accounting_required": False,
                "joint_liability_applies": True
            },
            
            # Routing
            "_routing": None,
            "_routing_reason": [],
            
            # Compliance
            "mpp_required": False,
            "_warnings": [],
            
            # Audit
            "_legal_basis": [],
        }
        
        for p in passes:
            # Routing — BLOCK przerywa
            if p.get("_routing") in ("BLOCK_AND_ALERT", "TRIAGE_QUEUE"):
                verdict["_routing"] = p["_routing"]
                verdict["_routing_reason"].append(p.get("_routing_reason", ""))
            
            # VAT pass
            if "vat_rate" in p and p["vat_rate"]:
                verdict["vat_rate"] = p["vat_rate"]
                verdict["gtu_code"] = p.get("gtu_code", "")
                verdict["procedure"] = p.get("procedure", "")
                verdict["rounding_level"] = p.get("rounding_level", "position")
            
            # PIT pass — wyniki per wspólnik
            if "partners_results" in p:
                verdict["partners_results"] = p["partners_results"]
            
            # Partnership pass
            if "partnership" in p:
                for key, value in p["partnership"].items():
                    if value is not None:
                        verdict["partnership"][key] = value
            
            # Warnings
            if "_warnings" in p:
                verdict["_warnings"].extend(p["_warnings"])
            
            # Legal basis
            if "_legal_basis" in p:
                verdict["_legal_basis"].append(p["_legal_basis"])
            
            if "rule_id" in p:
                verdict["rule_id"].append(p["rule_id"])
        
        return verdict
```

### 8.2 Priorytetyzacja Passów

| Pass | Domena | Priorytet | Abortuje na BLOCK? |
|------|--------|:---------:|:------------------:|
| 0 | `sc.risk` | P0-P9 | ✅ Tak |
| 1 | `sc.routing` | P10-P19 | ✅ Tak |
| 2 | `sc.compliance.*` | P20-P39 | ❌ Nie (warnings) |
| 3 | `sc.crossborder` | P40-P49 | ❌ Nie |
| 4 | `sc.partnership.lifecycle` | P900-P939 | ✅ Tak (invalid SC → abort) |
| 5 | `sc.vat.*` | P50-P235 | ❌ Nie |
| 6 | `sc.pit.*` | P500-P599 | ❌ Nie |
| 7 | `sc.allowances` | P600-P635 | ❌ Nie |
| 8 | `sc.zus.*` | P700-P770 | ❌ Nie |
| 9 | `sc.accounting.*` | P800-P894 | ❌ Nie |
| 10 | `sc.ksef` + `sc.jpk` + pozostałe | P950-P1174 | ❌ Nie |

---

## 9. Macierze Interakcji Międzyregulacyjnych

### 9.1 Macierz zależności między pakietami

| Pakiet źródłowy | Wpływa na | Mechanizm |
|---|---|---|
| `sc.partnership.lifecycle` | `sc.vat`, `sc.pit`, `sc.zus` | Status spółki → zakres obowiązków |
| `sc.pit.partners_proportional` | `sc.pit.kup`, `sc.pit.advances`, `sc.pit.returns` | Podział → podstawa obliczeń |
| `sc.vat` | `sc.jpk` | Stawka VAT → dane JPK_V7 |
| `sc.accounting.full` | `sc.accounting.pkpir` | Pełna → wyłącza PKPiR |
| `sc.partnership.liability` | `sc.compliance` | Solidarna → BLOCK + warning |
| `sc.pit.form_*` | `sc.zus.health` | Forma PIT → stawka zdrowotnej |

### 9.2 Macierz konfliktów i ich rozwiązywania

| Konflikt | Rozwiązanie | Reguła |
|---|---|---|
| VAT zwolniony + PIT należny | VAT=0%, PIT normalnie | P58 + P500 |
| Wspólnik na liniowym + były pracodawca | Blokada liniowego → skala | P512 |
| Zawieszenie + faktura sprzedaży | VAT mimo zawieszenia | P910 |
| Pełna księgowość + PKPiR | Pełna nadrzędna | P806 > P800 |
| Ulga B+R + strata | B+R carry-forward | P616_b > P615 |
| Zbieg etat+SC | Tylko zdrowotna z SC | P743 |
| Wspólnik wystąpił + nowe zobowiązanie | Brak odpowiedzialności | P1158 |

---

## 10. Plan Wdrożenia ENTERPRISE

### 10.1 Fazy wdrożenia

| Faza | Zakres | Pliki Rego | Czas |
|------|--------|-----------|------|
| **Faza 0 (MVP)** | Risk, Routing, Compliance, VAT podstawowy | `risk.rego`, `routing.rego`, `compliance/`, `vat/substantive.rego` | 2 tyg. |
| **Faza 1 (CORE)** | PIT wspólników (proporcjonalny podział, KUP, zaliczki), ZUS | `pit/`, `zus/` | 3 tyg. |
| **Faza 2 (ADVANCED)** | Cykl życia spółki, odpowiedzialność solidarna, sukcesja, zawieszenie | `partnership/` | 2 tyg. |
| **Faza 3 (ENTERPRISE)** | Pełna księgowość, amortyzacja, KSeF, JPK, pracodawca, ulgi | `accounting/`, `ksef/`, `jpk/`, `employer.rego`, `allowances.rego` | 3 tyg. |
| **Faza 4 (DEEP)** | Korekty, międzynarodowe, lokalne, środowisko, restrukturyzacja, digital | Pozostałe pliki | 3 tyg. |

### 10.2 Kamienie milowe

| Kamień | Opis | Kryterium sukcesu |
|--------|------|-------------------|
| **M1: MVP** | Podstawowy łańcuch decyzyjny SC | Risk + Routing + Compliance + VAT → werdykt |
| **M2: CORE** | Pełny podział proporcjonalny + PIT + ZUS | Dla 2 wspólników z różnymi formami → poprawne obliczenia |
| **M3: ENTERPRISE** | Pełna księgowość + KSeF + JPK | Spółka > 2M EUR → automatyczne przejście na pełną księgowość |
| **M4: DEEP** | Wszystkie obszary prawne | 100% pokrycia specyfiki SC |

### 10.3 Szacowany wysiłek

| Faza | Reguły | Pliki Rego | Testy | Osobodni |
|------|:------:|:---------:|:-----:|:--------:|
| Faza 0 | ~20 | 5 | ~30 | 10 |
| Faza 1 | ~50 | 12 | ~80 | 15 |
| Faza 2 | ~25 | 4 | ~40 | 10 |
| Faza 3 | ~35 | 10 | ~55 | 15 |
| Faza 4 | ~20 | 7 | ~30 | 15 |
| **RAZEM** | **~150** | **38** | **~235** | **65** |

---

## Cross-Reference: Podstawa Prawna → Reguła SC

> Kluczowe podstawy prawne specyficzne dla spółki cywilnej.

| Podstawa prawna | Reguła | Priorytet |
|---|---|---|
| Art. 8 ust. 1-2 PIT | `partner_proportional_split` | P500 ★★★ |
| Art. 860 KC | `sc_formation_valid` | P900 ★★★ |
| Art. 864 KC | `sc_joint_liability_tax`, `sc_joint_liability_zus` | P1150-P1152 ★★★ |
| Art. 869 KC | `sc_partner_exit_settlement`, `sc_partner_exit_liability` | P906, P1158 ★ |
| Art. 872 KC | `sc_succession_partner_death` | P920 ★★★ |
| Art. 874-875 KC | `sc_dissolution_procedure` | P904 ★ |
| Art. 2 ust. 1 pkt 1 UoR | `sc_full_accounting_threshold` | P806 ★★★ |
| Art. 113 VAT | `vat_exemption_subject_sc` | P58 ★ |
| Art. 96 VAT | `vat_r_registration_sc` | P39 ★ |
| Art. 22-25 Pr. przedsiębiorców | `sc_suspension_valid` | P910 ★ |
| Art. 14 Pr. przedsiębiorców | `sc_formation_valid` | P900 ★★★ |
| Art. 30 CEIDG | `sc_partner_change_notification` | P902 ★ |
| Art. 115 Ordynacji | `sc_joint_liability_tax` | P1150 ★★★ |
| Art. 9 ust. 1a-2 SUS | `partner_concurrent_employment_sc` | P743 ★ |
| Art. 23 ust. 1 pkt 10 PIT | `partner_kup_own_work_nkup_sc` | P578 ★ |
| Art. 9a ust. 3 PIT | `partner_linear_former_employer_restriction_sc` | P512 ★ |
| Art. 89b VAT | `bad_debt_debtor_correction_sc` | P184 ★ |
| Ustawa o zarządzie sukcesyjnym | `sc_succession_partner_death`, `sc_succession_tax_obligations` | P920-P922 ★★★ |
| Art. 97 VAT | `wdt_intracommunity_supply_sc` | P42 ★ |
| Art. 24a PIT | `sc_pkpir_column_mapping` | P800 ★ |

---

> **Dokument utworzony:** 2026-07-11 | **Wersja:** 1.0 | **Następny krok:** Implementacja `.rego` w `policies/sc/`
> **Powiązane dokumenty:**
> - `Plan OPA/Docs SC` — źródła prawne spółki cywilnej
> - `Plan OPA/00_PLAN_STRUKTURA.md` — master plan architektoniczny
> - `Plan OPA/34_JDG_DEFINITIVE_REGO_PLAN.md` — referencja JDG (wzorce)
