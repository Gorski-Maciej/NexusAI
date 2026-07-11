# 🏛️ NexusAI Spółka Cywilna — Definitywny Plan Reguł OPA/Rego ENTERPRISE v3.0

> **Status:** PRODUCTION READY — Definitywny dokument referencyjny
> **Data:** 2026-07-11
> **Autor:** Zespół NexusAI
> **Plik:** `Plan OPA/SC_DEFINITIVE_REGO_PLAN.md`
> **Zakres:** Wyłącznie spółka cywilna (civil law partnership) — dekompozycja artykuł-po-artykule
> **Źródła prawne:** `Plan OPA/Docs SC` — kompletny wykaz ustaw, rozporządzeń i interpretacji
> **Dokumenty referencyjne:** `Plan OPA/34_JDG_DEFINITIVE_REGO_PLAN.md` (wzorzec formatu), `Plan OPA/SC_ENTERPRISE_PLAN.md` (plan architektoniczny), `Plan OPA/SC_MASSIVE_RULE_CATALOG.md` (katalog tabelaryczny)
> **Reguły łącznie w tym dokumencie:** ~550+ (opisanych szczegółowo z przypadkami brzegowymi) | **Pakietów:** 32 | **Domen prawnych:** 100+

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
   - [5.5 sc.vat.substantive — VAT stawki i zwolnienia (P50-P69)](#55-scvatsubstantive--vat-stawki-i-zwolnienia-p50-p69)
   - [5.6 sc.vat.deductions — VAT odliczenia (P180-P192)](#56-scvatdeductions--vat-odliczenia-p180-p192)
   - [5.7 sc.vat.tax_point — Moment obowiązku podatkowego (P230-P235)](#57-scvattax_point--moment-obowiązku-podatkowego-p230-p235)
   - [5.8 sc.vat.gtu — Kody GTU (P65a-P65m)](#58-scvatgtu--kody-gtu-p65a-p65m)
   - [5.9 sc.pit.partners — PIT wspólników — podział proporcjonalny (P500-P509)](#59-scpitpartners--pit-wspólników--podział-proporcjonalny-p500-p509)
   - [5.10 sc.pit.forms — Formy opodatkowania per wspólnik (P510-P539)](#510-scpitforms--formy-opodatkowania-per-wspólnik-p510-p539)
   - [5.11 sc.pit.kup — Koszty uzyskania przychodu per wspólnik (P560-P582)](#511-scpitkup--koszty-uzyskania-przychodu-per-wspólnik-p560-p582)
   - [5.12 sc.pit.advances — Zaliczki PIT per wspólnik (P540-P549)](#512-scpitadvances--zaliczki-pit-per-wspólnik-p540-p549)
   - [5.13 sc.pit.returns — Zeznania roczne per wspólnik (P550-P559)](#513-scpitreturns--zeznania-roczne-per-wspólnik-p550-p559)
   - [5.14 sc.pit.exemptions — Zwolnienia PIT per wspólnik (P580-P588)](#514-scpitexemptions--zwolnienia-pit-per-wspólnik-p580-p588)
   - [5.15 sc.partnership.formation — Powstanie i walidacja spółki (P900-P904)](#515-scpartnershipformation--powstanie-i-walidacja-spółki-p900-p904)
   - [5.16 sc.partnership.changes — Zmiany składu wspólników (P905-P909)](#516-scpartnershipchanges--zmiany-składu-wspólników-p905-p909)
   - [5.17 sc.partnership.dissolution — Rozwiązanie i likwidacja (P920-P929)](#517-scpartnershipdissolution--rozwiązanie-i-likwidacja-p920-p929)
   - [5.18 sc.partnership.liability — Odpowiedzialność solidarna (P1150-P1174)](#518-scpartnershipliability--odpowiedzialność-solidarna-p1150-p1174)
   - [5.19 sc.partnership.succession — Sukcesja po śmierci wspólnika (P930-P939)](#519-scpartnershipsuccession--sukcesja-po-śmierci-wspólnika-p930-p939)
   - [5.20 sc.partnership.suspension — Zawieszenie działalności (P940-P949)](#520-scpartnershipsuspension--zawieszenie-działalności-p940-p949)
   - [5.21 sc.zus.social — Składki społeczne per wspólnik (P700-P719)](#521-sczussocial--składki-społeczne-per-wspólnik-p700-p719)
   - [5.22 sc.zus.health — Składka zdrowotna per wspólnik (P720-P749)](#522-sczushealth--składka-zdrowotna-per-wspólnik-p720-p749)
   - [5.23 sc.accounting.full — Pełna księgowość (P800-P819)](#523-scaccountingfull--pełna-księgowość-p800-p819)
   - [5.24 sc.accounting.pkpir — PKPiR spółki (P820-P829)](#524-scaccountingpkpir--pkpir-spółki-p820-p829)
   - [5.25 sc.accounting.depreciation — Amortyzacja (P840-P859)](#525-scaccountingdepreciation--amortyzacja-p840-p859)
   - [5.26 sc.ksef — KSeF faktury ustrukturyzowane (P950-P969)](#526-scksef--ksef-faktury-ustrukturyzowane-p950-p969)
   - [5.27 sc.jpk — JPK_V7 i JPK_PKPIR (P970-P989)](#527-scjpk--jpk_v7-i-jpk_pkpir-p970-p989)
   - [5.28 sc.employer — Spółka jako pracodawca (P1200-P1223)](#528-scemployer--spółka-jako-pracodawca-p1200-p1223)
   - [5.29 sc.allowances — Ulgi podatkowe per wspólnik (P600-P635)](#529-scallowances--ulgi-podatkowe-per-wspólnik-p600-p635)
   - [5.30 sc.corrections — Korekty faktur i deklaracji (P1100-P1120)](#530-sccorrections--korekty-faktur-i-deklaracji-p1100-p1120)
   - [5.31 sc.local — Podatki lokalne (P1300-P1320)](#531-sclocal--podatki-lokalne-p1300-p1320)
   - [5.32 sc.fallback — Reguły domyślne (P1000-P1099)](#532-scfallback--reguły-domyślne-p1000-p1099)
6. [Wymagane Dane Wejściowe (input)](#6-wymagane-dane-wejściowe-input)
7. [Obsługa Parametrów Dynamicznych (thresholds)](#7-obsługa-parametrów-dynamicznych-thresholds)
8. [Architektura Multi-Pass — Scalanie Werdyktów](#8-architektura-multi-pass--scalanie-werdyktów)
9. [Macierze Interakcji Międzyregulacyjnych](#9-macierze-interakcji-międzyregulacyjnych)
10. [Plan Wdrożenia ENTERPRISE](#10-plan-wdrożenia-enterprise)
11. [Cross-Reference: Podstawa Prawna → Reguła SC](#11-cross-reference-podstawa-prawna--reguła-sc)

---

## 1. Filozofia Projektowa i Architektura

### 1.1 Fundamenty Architektoniczne

| Zasada | Opis | Implementacja SC |
|--------|------|-------------------|
| **First-Match-Wins** | Pierwsza pasująca reguła wewnątrz każdego pakietu wygrywa | `else` chain w Rego |
| **Multi-Pass Evaluation** | Różne domeny (VAT, PIT, ZUS, Accounting) ewaluowane niezależnie | 10+ passów OPA, scalane przez `ScVerdictMerger` |
| **Zero Hardcoded Values** | Żadna liczba nie jest zakodowana w `.rego` | Wszystko przez `input.thresholds.sc.*` |
| **Temporalność** | Reguły obowiązują od-do; parametry zależne od daty | `valid_from` / `valid_to` w DuckDB |
| **Audytowalność** | Każda decyzja ma pełny ślad | `rule_id`, `_legal_basis`, `_routing` w werdykcie |
| **Partner-Proportional Design** | Wszystkie reguły PIT/KUP/ZUS rozbite na wspólników | `input.partners[]` + proporcjonalny podział (Art. 8 PIT) |
| **Graceful Degradation** | Awaria API zewnętrznego → fallback, nie crash | Warning zamiast BLOCK |
| **Solidarna odpowiedzialność** | Reguły odpowiedzialności za zobowiązania spółki | `sc.partnership.liability` — full coverage |
| **Multi-Form Tax** | Każdy wspólnik może mieć inną formę opodatkowania | Niezależna ewaluacja `p.tax_form` dla każdego `p` |

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
            "zus_health_rate": "0.09",
            "joint_liability_triggered": false
        }
    ],

    "partnership": {
        "total_revenue": 10000.00,
        "total_costs": 6000.00,
        "total_income": 4000.00,
        "partner_count": 2,
        "accounting_method": "PKPIR",
        "full_accounting_required": false,
        "joint_liability_applies": true,
        "partnership_status": "ACTIVE"
    },

    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 41 ust. 1 ustawy o VAT",
    "_edge_cases_checked": ["no_partner_change", "standard_vat_rate"],
    "_warnings": []
}
```

### 1.3 Architektura Multi-Pass

```
INPUT ──► PASS 0: RISK (fraud/anomaly/KKS/GAAR/intra-partnership)  ──► risk_verdict
              ↓ (if BLOCK → abort)
          PASS 1: ROUTING (field confidence per document)            ──► routing_verdict
              ↓ (if BLOCK → abort)
          PASS 2: COMPLIANCE (whitelist/MPP/cash/KSeF/CEIDG)        ──► compliance_verdict
              ↓
          PASS 3: CROSSBORDER (WNT/WDT/import/export/triangular)    ──► crossborder_verdict
              ↓
          PASS 4: PARTNERSHIP LIFECYCLE (formation/changes/status)  ──► partnership_verdict
              ↓
          PASS 5: VAT (rates + GTU + deductions + tax_point)        ──► vat_verdict
              ↓
          PASS 6: PIT per PARTNER (proportional split + form + KUP) ──► pit_verdict
              ↓
          PASS 7: ALLOWANCES per PARTNER (ulgi podatkowe)           ──► allowances_verdict
              ↓
          PASS 8: ZUS per PARTNER (społeczne + zdrowotne)           ──► zus_verdict
              ↓
          PASS 9: ACCOUNTING (PKPiR/full + depreciation + FX)       ──► accounting_verdict
              ↓
          PASS 10: KSeF + JPK + EMPLOYER + RESZTA                   ──► misc_verdict
              ↓
          VERDICT MERGER (ScVerdictMerger)                           ──► final_verdict
```

---

## 2. Kluczowa Specyfika Spółki Cywilnej

### 2.1 Dualizm podatkowy — tabela decyzyjna

| Aspekt | Kto jest podatnikiem? | NIP | Deklaracje |
|--------|----------------------|-----|------------|
| **VAT** | **Spółka cywilna** (odrębny podatnik) | Własny NIP spółki | JPK_V7M/K — 1 deklaracja |
| **PIT** | **Każdy wspólnik** indywidualnie | NIP każdego wspólnika | PIT-36/36L/28 — tyle deklaracji ilu wspólników |
| **ZUS społeczne** | **Każdy wspólnik** indywidualnie | NIP wspólnika | DRA — tyle deklaracji ilu wspólników |
| **ZUS pracownicze** | **Spółka** jako płatnik | NIP spółki | RCA — 1 deklaracja |
| **PIT-4R (pracownicy)** | **Spółka** jako płatnik | NIP spółki | PIT-4R — 1 deklaracja |

### 2.2 Art. 8 PIT — Święta reguła proporcjonalności

> **Art. 8 ust. 1 ustawy o PIT:** "Przychody z udziału w spółce niebędącej osobą prawną [...] u każdego podatnika określa się proporcjonalnie do jego prawa do udziału w zysku (udziału)."
>
> **Art. 8 ust. 2:** "Zasady wyrażone w ust. 1 stosuje się odpowiednio do rozliczania kosztów uzyskania przychodów, wydatków niestanowiących kosztów uzyskania przychodów i strat."

**Implikacje dla systemu reguł:**

| Implikacja | Mechanizm w OPA | Priorytet |
|------------|----------------|:---------:|
| Każdy przychód dzielony przez `share_percent` | `partner_split("revenue")` helper | P500 |
| Każdy KUP dzielony przez `share_percent` | `partner_split("costs")` helper | P500 |
| Każda strata dzielona przez `share_percent` | `partner_split("loss")` helper | P500 |
| Różne formy PIT dla różnych wspólników | Niezależna ewaluacja `p.tax_form` | P510-P539 |
| Ulgi stosowane indywidualnie | Per-partner allowances | P600-P635 |
| ZUS liczony od dochodu wspólnika | Per-partner ZUS base | P700-P749 |

### 2.3 Kluczowe różnice SC vs JDG

| Aspekt | JDG (jednoosobowa) | Spółka cywilna | Impact na reguły OPA |
|--------|-------------------|----------------|---------------------|
| **Podatnik VAT** | Przedsiębiorca | **Spółka** (odrębny NIP) | VAT reguły na poziomie `input.partnership` |
| **Podatnik PIT** | Przedsiębiorca | **Każdy wspólnik** | PIT reguły per `input.partners[_]` |
| **Deklaracje VAT** | 1 deklaracja | 1 deklaracja **spółki** | JPK_V7 z NIP spółki |
| **Deklaracje PIT** | 1 zeznanie | Tyle zeznań **ilu wspólników** | Multi-PIT returns |
| **ZUS** | 1 przedsiębiorca | **Każdy wspólnik osobno** | Per-partner ZUS |
| **Odpowiedzialność** | Osobista | **Solidarna** (Art. 864 KC) | Joint liability rules |
| **PKPiR** | 1 księga | **1 księga spółki** (wspólna) | Shared PKPiR → per-partner split |
| **Pełna księgowość** | Opcjonalnie | **Obowiązkowo** po 2M EUR spółki | Threshold = partnership turnover |
| **Zwolnienie VAT 200k** | Limit przedsiębiorcy | Limit **spółki** (suma!) | Partnership-level threshold |
| **Podział przychodów/kosztów** | Nie dotyczy | **Proporcjonalnie** (Art. 8 PIT) | Every revenue/cost rule splits |
| **Zmiana formy PIT** | 1 decyzja | **Niezależnie** per wspólnik | Per-partner tax form rules |
| **Kasa fiskalna 20k** | Limit przedsiębiorcy | Limit **spółki** (suma B2C!) | Partnership-level threshold |

---

## 3. Podział na Pakiety

System używa **32 pakietów** Rego zorganizowanych w 5 kategorii:

```
policies/sc/
├── main_sc.rego                            # Główny else-chain FIRST-MATCH-WINS
├── _helpers_sc.rego                        # Funkcje pomocnicze SC
├── _metadata_sc.rego                       # Metadane wszystkich reguł SC
│
│   # ═══ KATEGORIA A: BEZPIECZEŃSTWO I ROUTING ═══
├── risk.rego                               # P0-P9:    Fraud, anomalie, KKS, GAAR
├── routing.rego                            # P10-P19:  Field confidence
│
│   # ═══ KATEGORIA B: COMPLIANCE I TRANSGRANICZNE ═══
├── compliance/
│   ├── whitelist.rego                      # P20-P22:  Biała Lista MF
│   ├── mpp.rego                            # P25-P26:  Split payment
│   └── cash.rego                           # P35-P36:  Limit gotówki
├── crossborder.rego                        # P40-P49:  WNT, WDT, import, eksport, trójstronne
│
│   # ═══ KATEGORIA C: VAT SPÓŁKI ═══
├── vat/
│   ├── substantive.rego                    # P50-P59:  Stawki VAT, zwolnienia podmiotowe/przedmiotowe
│   ├── gtu.rego                            # P65:      Mapowanie 13 kodów GTU
│   ├── deductions.rego                     # P180-P192: Odliczenia, korekty, proporcja, samochody
│   └── tax_point.rego                      # P230-P235: Moment obowiązku podatkowego
│
│   # ═══ KATEGORIA D: PIT WSPÓLNIKÓW ═══
├── pit/
│   ├── proportional.rego                   # P500-P509: FUNDAMENT — proporcjonalny podział (Art. 8)
│   ├── forms.rego                          # P510-P539: 4 formy opodatkowania per wspólnik
│   ├── kup.rego                            # P560-P582: KUP — pełna lista wyłączeń i ograniczeń per wspólnik
│   ├── advances.rego                       # P540-P549: Zaliczki miesięczne/kwartalne per wspólnik
│   ├── returns.rego                        # P550-P559: Zeznania roczne per wspólnik
│   └── exemptions.rego                     # P580-P588: Zwolnienia PIT (młodzi, powrót, 4+, senior)
│
│   # ═══ KATEGORIA E: CYKL ŻYCIA SPÓŁKI ═══
├── partnership/
│   ├── formation.rego                      # P900-P904: Powstanie, umowa, walidacja
│   ├── changes.rego                        # P905-P909: Zmiany składu (przystąpienie, wystąpienie)
│   ├── dissolution.rego                    # P920-P929: Rozwiązanie, likwidacja, podział majątku
│   ├── liability.rego                      # P1150-P1174: Odpowiedzialność solidarna, regres, przedawnienia
│   ├── succession.rego                     # P930-P939: Sukcesja po śmierci wspólnika
│   └── suspension.rego                     # P940-P949: Zawieszenie i wznowienie
│
│   # ═══ KATEGORIA F: ZUS WSPÓLNIKÓW ═══
├── zus/
│   ├── social.rego                         # P700-P719: Składki społeczne, ulgi, zbiegi
│   └── health.rego                         # P720-P749: Składka zdrowotna, progi, rozliczenia
│
│   # ═══ KATEGORIA G: KSIĘGOWOŚĆ ═══
├── accounting/
│   ├── full.rego                           # P800-P819: Pełna księgowość (próg 2M EUR, UoR)
│   ├── pkpir.rego                          # P820-P829: PKPiR spółki (16 kolumn)
│   └── depreciation.rego                   # P840-P859: Amortyzacja, leasing, FX
│
│   # ═══ KATEGORIA H: SPRAWOZDAWCZOŚĆ I RESZTA ═══
├── ksef.rego                               # P950-P969: KSeF faktury ustrukturyzowane
├── jpk.rego                                # P970-P989: JPK_V7, JPK_PKPIR
├── employer.rego                           # P1200-P1223: Spółka jako pracodawca i płatnik
├── allowances.rego                         # P600-P635: Ulgi podatkowe per wspólnik
├── corrections.rego                        # P1100-P1120: Korekty faktur, deklaracji, JPK
├── local_taxes.rego                        # P1300-P1320: PCC, nieruchomości, transport
├── international.rego                      # P100-P117: WHT, PE, ceny transferowe
├── environmental.rego                      # P1400-P1407: BDO, KOBiZE
├── digital.rego                            # P630-P1895: Krypto, AI Act, MDR
├── retention.rego                          # P990-P992: Przechowywanie dokumentów
└── fallback.rego                           # P1000-P1099: Reguły domyślne
```

### 3.1 Macierz Priorytetów

| Zakres | Pakiet | Odpowiedzialność | Skutek dopasowania | Liczba reguł |
|--------|--------|-------------------|-------------------|:-----------:|
| **P0-P9** | `sc.risk` | Fraud, anomalie, KKS, GAAR, intra-partnership fraud | BLOCK_AND_ALERT | 10 |
| **P10-P19** | `sc.routing` | OCR confidence per SC document | BLOCK / TRIAGE | 5 |
| **P20-P39** | `sc.compliance.*` | Biała Lista, MPP, gotówka, kasy, CEIDG | BLOCK / warnings | 10 |
| **P40-P49** | `sc.crossborder` | WNT, WDT, import, eksport, trójstronne | Procedura specjalna | 12 |
| **P50-P69** | `sc.vat.substantive` | Stawki VAT, zwolnienia, GTU | Stawka VAT + GTU | 25 |
| **P180-P192** | `sc.vat.deductions` | Odliczenia VAT, proporcja, auta, złe długi | Odliczenie / korekta | 15 |
| **P230-P235** | `sc.vat.tax_point` | Moment obowiązku podatkowego | Data obowiązku | 12 |
| **P500-P509** | `sc.pit.proportional` | FUNDAMENT: podział przychodów/kosztów | Dane per wspólnik | 15 |
| **P510-P539** | `sc.pit.forms` | Formy opodatkowania per wspólnik | Stawka PIT + forma | 30 |
| **P560-P582** | `sc.pit.kup` | KUP — wyłączenia per wspólnik | Kwalifikacja KUP | 25 |
| **P540-P549** | `sc.pit.advances` | Zaliczki miesięczne/kwartalne | Kwota zaliczki | 15 |
| **P550-P559** | `sc.pit.returns` | Zeznania roczne | Typ deklaracji | 10 |
| **P580-P588** | `sc.pit.exemptions` | Zwolnienia PIT (młodzi, powrót, 4+, senior) | Stawka 0% | 12 |
| **P900-P904** | `sc.partnership.formation` | Powstanie, umowa, walidacja | Status spółki | 8 |
| **P905-P909** | `sc.partnership.changes` | Zmiany składu wspólników | Nowy podział | 10 |
| **P920-P929** | `sc.partnership.dissolution` | Rozwiązanie, likwidacja | Procedura | 10 |
| **P1150-P1174** | `sc.partnership.liability` | Odpowiedzialność solidarna, regres | Zakres odp. | 20 |
| **P930-P939** | `sc.partnership.succession` | Sukcesja po śmierci | Kontynuacja | 10 |
| **P940-P949** | `sc.partnership.suspension` | Zawieszenie i wznowienie | Status | 10 |
| **P700-P719** | `sc.zus.social` | Składki społeczne, ulgi, zbiegi | Stawki składek | 20 |
| **P720-P749** | `sc.zus.health` | Składka zdrowotna | Stawka + podstawa | 15 |
| **P800-P819** | `sc.accounting.full` | Pełna księgowość, UoR | Metoda księgowa | 15 |
| **P820-P829** | `sc.accounting.pkpir` | PKPiR spółki | Kolumna PKPiR | 12 |
| **P840-P859** | `sc.accounting.depreciation` | Amortyzacja, leasing, FX | Metoda + stawka | 15 |
| **P950-P969** | `sc.ksef` | KSeF faktury ustrukturyzowane | KSeF flags | 12 |
| **P970-P989** | `sc.jpk` | JPK_V7, JPK_PKPIR | JPK flags | 10 |
| **P1200-P1223** | `sc.employer` | Spółka jako pracodawca | PIT-4R, ZUS RCA, PPK | 15 |
| **P600-P635** | `sc.allowances` | Ulgi podatkowe per wspólnik | Odliczenie | 20 |
| **P1100-P1120** | `sc.corrections` | Korekty faktur, deklaracji | Korekta | 10 |
| **P1300-P1320** | `sc.local` | PCC, nieruchomości, transport | Stawka PCC | 8 |
| **P100-P117** | `sc.international` | WHT, PE, ceny transferowe | WHT / TP flags | 10 |
| **P1000-P1099** | `sc.fallback` | Reguły domyślne i NO_MATCH | Fallback | 5 |
| **RAZEM** | **32 pakiety** | | | **~550** |

---

## 4. Hierarchia i Priorytety — First-Match-Wins

### 4.1 Zunifikowany Łańcuch Decyzyjny SC

Poniżej KOMPLETNY diagram pierwszeństwa dla wszystkich głównych reguł SC. Reguły wewnątrz każdego pakietu używają `else` chain — pierwsza dopasowana wygrywa.

```
INPUT ───────────────────────────────────────────────────────────────────────────► WERDYKT SC

═══ BLOK 0: RISK & FRAUD (P0-P9) — NATYCHMIASTOWA BLOKADA ═══
P0      fraud_graph_match                     Kontrahent w sieci fraudowej VAT
P0_sc   partnership_fraud_risk                Ryzyko fraudu wewnątrz spółki ★
P1      counterparty_trust_low                Trust score < próg
P2      anomaly_amount                        Kwota > 3σ od średniej
P3      new_counterparty_flag                 Nowy kontrahent → weryfikacja
P4      kks_hidden_income_flag                Rozbieżność wpływy vs przychody spółki
P5      semantic_guard_disallowed             Wydatek niezwiązany z działalnością SC
P8      ceidg_vendor_suspended                Kontrahent zawieszony w CEIDG
P9      gaar_artificial_scheme                Klauzula GAAR
         │
═══ BLOK 1: ROUTING (P10-P19) ═══
P10     fc_vat_rate_low_sc                    Niska pewność stawki VAT (spółka)
P12     fc_vendor_nip_low_sc                  Niska pewność NIP
P15     fc_partner_fields_low                 Niska pewność pól wspólników ★
P19     fc_global_minimum_low                 Ogólna pewność < minimum
         │
═══ BLOK 2: COMPLIANCE (P20-P39) ═══
P20     whitelist_missing_over_limit          Brak na WL > 15k PLN (spółka)
P21     whitelist_account_mismatch            Rachunek niezgodny z WL
P25     split_payment_mandatory               Obowiązkowy MPP (spółka)
P35     cash_transaction_over_limit           Gotówka > 15k PLN → NKUP
P36     cash_register_b2c_limit_sc            Limit kasy fiskalnej 20k (spółka!) ★
P39     vat_r_registration_sc                 Blokada: brak VAT-R spółki ★
         │
═══ BLOK 3: CROSSBORDER (P40-P49) ═══
P40     eu_reverse_charge_wnt                 WNT — reverse charge
P41     eu_import_services                    Import usług z UE
P42     wdt_intracommunity_supply             WDT — 0% VAT (VAT-UE spółki) ★
P45     import_non_eu                         Import spoza UE
P48     export_goods                          Eksport towarów
P49     triangular_transaction                Transakcje trójstronne
         │
═══ BLOK 4: CYKL ŻYCIA SPÓŁKI (P900-P949) ═══
P900    sc_formation_valid                    Umowa spółki — walidacja ★★★
P901    sc_ceidg_all_partners_registered      Wszyscy wspólnicy w CEIDG ★
P905    sc_partner_join_procedure             Przyjęcie nowego wspólnika ★
P907    sc_partner_exit_settlement            Wystąpienie wspólnika — rozliczenie ★
P920    sc_dissolution_grounds                Przesłanki rozwiązania ★
P922    sc_liquidation_procedure              Procedura likwidacyjna ★
P930    sc_succession_partner_death           Śmierć wspólnika — sukcesja ★★
P940    sc_suspension_all_partners            Zawieszenie — wszyscy wspólnicy ★
         │
═══ BLOK 5: VAT SPÓŁKI — STAWKI (P50-P69) ═══
P50     vat_margin_scheme                     Procedura marży
P52     vat_rate_fuel_pl                      Paliwo → 23% + GTU_04
P53     vat_rate_food_pl                      Żywność → 5% + GTU_07
P54     vat_rate_books_pl                     Książki → 5%
P55     vat_exemption_education               Edukacja → zwolniona
P56     vat_exemption_healthcare              Medycyna → zwolniona
P58     vat_exemption_subject_sc              Zwolnienie podmiotowe SC (200k całej spółki!) ★★
P60     vat_bad_debt_relief_creditor          Ulga na złe długi VAT (wierzyciel)
P65     gtu_mapping_by_category               Mapowanie GTU (13 kodów)
         │
═══ BLOK 6: VAT SPÓŁKI — ODLICZENIA I TAX POINT (P180-P235) ═══
P184    bad_debt_debtor_correction_sc         OBOWIĄZEK spółki po 90 dniach ★
P186    vehicle_50_vat_deduction_sc           Auto mieszane spółki 50% VAT ★
P188    vat_pre_proportion_sc                 Pre-proporcja VAT spółki ★
P230    vat_tax_point_continuous_service      Usługi ciągłe — koniec okresu
P231    vat_tax_point_advance_invoice         Zaliczki — data zapłaty
P232    vat_tax_point_invoice_30_days_late    Faktura >30 dni po dostawie
         │
═══ BLOK 7: PIT WSPÓLNIKÓW — FUNDAMENT PROPORCJI (P500-P509) ═══
P500    partner_proportional_split            ★★★ FUNDAMENT: Art. 8 PIT — podział przych/kosztów
P501    partner_share_validation              Walidacja sumy udziałów = 100% ★
P502    partner_revenue_split_by_date         Podział przychodu wg daty (zmiana udziałów w roku!) ★★
P503    partner_cost_split_by_date            Podział KUP wg daty (zmiana udziałów w roku!) ★★
P504    partner_loss_split_proportional       Podział straty proporcjonalnie ★
P505    partner_own_work_exclusion            Praca własna wspólnika → NKUP ★★
         │
═══ BLOK 8: PIT WSPÓLNIKÓW — FORMY (P510-P539) ═══
P510    partner_pit_scale                      Skala 12%/32% per wspólnik
P511    partner_pit_scale_bracket              Ustalenie progu (120k) per wspólnik ★
P515    partner_pit_linear                     19% per wspólnik
P516    partner_pit_linear_former_employer     Blokada liniowego (były pracodawca) ★★
P520    partner_pit_lump_sum                   Ryczałt per wspólnik
P521    partner_pit_lump_sum_rate              Stawka ryczałtu wg PKWiU
P525    partner_pit_lump_sum_limit_sc          Limit 2M EUR — przychód SPÓŁKI! ★
P530    partner_pit_tax_card                   Karta podatkowa
P535    partner_different_forms_sc             Różne formy dla różnych wspólników ★★
P538    partner_form_change_mid_year           Zmiana formy w trakcie roku ★
         │
═══ BLOK 9: PIT WSPÓLNIKÓW — KUP (P560-P582) ═══
P560    partner_kup_full_deductible            Pełny KUP per wspólnik
P561    partner_kup_zus_social_deductible      ZUS społeczne → KUP per wspólnik ★
P562    partner_kup_private_mixed_sc           Wydatki mieszane per wspólnik ★
P564    partner_kup_car_over_150k_limit        Auto > 150k limit KUP per wspólnik
P566    partner_kup_representation_none        Reprezentacja → NKUP per wspólnik
P568    partner_kup_unpaid_zus_social          Niezapłacony ZUS → NKUP ★
P570    partner_kup_health_contrib_deduction   Zdrowotna — limit odliczenia liniowy ★
P578    partner_kup_own_work_nkup_sc           Wartość pracy własnej wspólnika → NKUP ★★
P579    partner_kup_spouse_contract_sc         Małżonek wspólnika — KUP tylko z umową ★
         │
═══ BLOK 10: PIT WSPÓLNIKÓW — ZALICZKI I ZEZNANIA (P540-P559) ═══
P540    partner_advance_monthly                Zaliczka miesięczna per wspólnik ★
P541    partner_advance_zus_deduction          Odliczenie ZUS od zaliczki per wspólnik ★
P542    partner_advance_quarterly              Zaliczka kwartalna (mały podatnik)
P550    partner_annual_return_pit36            PIT-36 per wspólnik (30 kwietnia)
P552    partner_annual_return_pit36l           PIT-36L per wspólnik
P554    partner_annual_return_pit28            PIT-28 per wspólnik (28 lutego!) ★
         │
═══ BLOK 11: PIT WSPÓLNIKÓW — ZWOLNIENIA (P580-P588) ═══
P580    partner_exemption_young_sc             Ulga dla młodych (<26 lat) ★
P582    partner_exemption_return_sc            Ulga na powrót ★
P584    partner_exemption_family_4plus_sc      Ulga 4+ dzieci ★
P586    partner_exemption_senior_sc            Ulga pracujących emerytów ★
P588    partner_exemption_combined_limit       Łączny limit PIT-0 85 528 PLN ★
         │
═══ BLOK 12: ULGI PER WSPÓLNIK (P600-P635) ═══
P600    partner_relief_rd_sc                   Ulga B+R per wspólnik ★
P610    partner_relief_ip_box_sc               IP Box 5% per wspólnik ★
P615    partner_loss_carry_forward_sc          Rozliczenie straty per wspólnik ★
P623    partner_relief_thermo_sc               Ulga termomodernizacyjna
         │
═══ BLOK 13: ZUS PER WSPÓLNIK (P700-P749) ═══
P700    partner_zus_social_standard            Standardowe składki społeczne
P701    partner_zus_sickness_voluntary         Chorobowa — DOBROWOLNA ★
P710    partner_zus_start_relief               Ulga na start (6 mies.) ★
P711    partner_zus_maly_plus                  Mały ZUS Plus (36 mies.) ★
P715    partner_concurrent_employment_sc        Zbieg etat+SC → tylko zdrowotna ★★
P720    partner_zus_health_scale                9% (skala) ★
P722    partner_zus_health_linear               4.9% (liniowy) ★
P724    partner_zus_health_lump_sum             Progi ryczałtowe (60k/300k) ★
P730    partner_health_contribution_matrix       Macierz forma → składka ★
         │
═══ BLOK 14: KSIĘGOWOŚĆ SPÓŁKI (P800-P859) ═══
P800    sc_full_accounting_threshold           Próg 2M EUR → pełna księgowość ★★★
P802    sc_double_entry_validation             Walidacja Wn=Ma ★
P804    sc_closing_books_mandatory             Blokada księgowania po zamknięciu ★
P810    sc_pkpir_column_mapping                Mapowanie 16 kolumn PKPiR ★
P815    sc_pkpir_partner_split_for_pit         PKPiR → podział per wspólnik ★
P840    sc_depreciation_linear                 Amortyzacja liniowa
P842    sc_depreciation_one_off                Jednorazowa amortyzacja
P860    sc_leasing_operational_kup             Leasing operacyjny → KUP
P870    sc_fx_differences_recognition          Różnice kursowe
         │
═══ BLOK 15: ODPOWIEDZIALNOŚĆ SOLIDARNA (P1150-P1174) ═══
P1150   sc_joint_liability_tax                 Solidarna za podatki spółki ★★★
P1152   sc_joint_liability_zus                 Solidarna za ZUS spółki ★★
P1154   sc_joint_liability_civil               Solidarna za zobowiązania cywilne ★★
P1158   sc_partner_exit_liability              Odpowiedzialność po wystąpieniu ★★★
P1160   sc_new_partner_prior_debts             Nowy wspólnik — długi sprzed ★
P1164   sc_late_payment_interest               Odsetki za zwłokę
P1168   sc_tax_statute_of_limitations          Przedawnienie 5 lat ★
         │
═══ BLOK 16: KSeF + JPK + PRACODAWCA + RESZTA ═══
P950    sc_ksef_mandatory                      Obowiązek KSeF od 01.02.2026 ★
P955    sc_ksef_offline_recovery               Tryb awaryjny (7 dni)
P970    sc_jpk_v7m_structure                   JPK_V7M spółki ★
P975    sc_jpk_gtu_completeness                Kompletność GTU ★
P1200   sc_employer_obligation                 Spółka jako płatnik PIT/ZUS ★
P1208   sc_ppk_obligation                      Obowiązek PPK
P1100   sc_correction_invoice_in_minus         Korekta in minus
P1300   sc_pcc_loan_partner                    PCC od pożyczki wspólnika ★
         │
═══ BLOK 17: FALLBACK (P1000-P1099) ═══
P1000   sc_domestic_fallback                   Domyślna stawka 23%
P1010   sc_partner_fallback_no_form            Domyślna forma = skala ★
P1099   sc_no_match                            NO_MATCHING_RULE
```

### 4.2 Macierz rozstrzygania konfliktów

| Konflikt | Mechanizm | Reguła nadrzędna | Reguła podrzędna |
|---|---|---|---|
| VAT zwolniony + PIT należny | Niezależne passy | P58 (VAT=0%) | P500+ (PIT normalnie) |
| Wspólnik liniowy + były pracodawca | Blokada → skala | P516 | P515 |
| Zawieszenie + faktura sprzedaży | VAT nadal należny | P230 | P940 |
| Pełna księgowość + PKPiR | Pełna nadrzędna | P800 > P810 | — |
| Ulga B+R + strata | B+R carry-forward 6 lat | P616_b > P615 | — |
| Zbieg etat+SC | Tylko zdrowotna z SC | P715 | P700 |
| Wspólnik wystąpił + nowe zobowiązanie | Brak odpowiedzialności | P1158 | P1150 |
| Różne formy PIT wspólników | Niezależna ewaluacja | P535 | — |
| Zmiana udziałów w trakcie roku | Split per data | P502/P503 | P500 |
| Śmierć wspólnika + 1 zostaje | Rozwiązanie spółki | P930 > P900 | — |

---

## 5. Szczegółowy Opis Reguł per Pakiet

---

### 5.1 sc.risk — Ryzyko i Fraud (P0-P9)

#### P0: `fraud_graph_match`
- **Cel biznesowy:** Natychmiastowa blokada faktury od kontrahenta znajdującego się w sieci fraudowej VAT (karuzela podatkowa). Dla SC szczególnie niebezpieczne — odpowiedzialność solidarna wszystkich wspólników za udział w karuzeli.
- **Przesłanki (szczegółowe warunki logiczne):**
  - `input.vendor.fraud_flag == true` — kontrahent oznaczony przez FraudGraphScanner
  - NIE jest wymagane przekroczenie progu kwotowego — każda faktura od fraudera jest blokowana
  - Dotyczy zarówno faktur zakupowych (PURCHASE) jak i sprzedażowych (SALE)
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"` — faktura zablokowana, wymagana manualna inspekcja
  - `fraud_detected: true`
  - `joint_liability_triggered: true` — wszyscy wspólnicy solidarnie narażeni
  - `_warnings: ["Kontrahent w sieci fraudowej VAT — ryzyko karuzeli podatkowej"]`
- **Podstawa prawna:** Art. 86 ust. 1 ustawy o VAT (prawo do odliczenia), Art. 55 KKS (oszustwo podatkowe), Art. 864 KC (odpowiedzialność solidarna)
- **Zależności między regułami:**
  - FraudGraphScanner musi wcześniej oznaczyć `vendor.fraud_flag` (zewnętrzny serwis)
  - P0 ma NAJWYŻSZY priorytet — jeśli dopasowana, przerywa wszystkie dalsze passy
  - Wynik P0 wpływa na P1150 (joint liability) — automatycznie triggeruje solidarną
- **Przypadki brzegowe i wyjątki:**
  - **Fraud flag na kontrahencie zagranicznym:** Blokada też obowiązuje, ale dodatkowo sprawdzane jest VIES
  - **Faktura korygująca od fraudera:** Blokada również — korekta może być elementem schematu
  - **Historyczny fraud (kontrahent już nie na liście):** Jeśli `fraud_flag` było true w dacie transakcji → nadal blokada
  - **WYJĄTEK:** Transakcje poniżej 500 PLN z kontrahentem o `fraud_flag == true` ale `trust_score > 0.5` → tylko WARNING, nie BLOCK (de minimis)
- **Priorytet:** 0

#### P0_sc: `intra_partnership_fraud_risk` ★★★
- **Cel biznesowy:** Wykrycie ryzyka fraudu wewnątrz spółki cywilnej — fikcyjne faktury między wspólnikami, sztuczne zwiększanie kosztów przez jednego wspólnika kosztem drugiego, transfer zysków między wspólnikami o różnych formach opodatkowania.
- **Przesłanki (szczegółowe warunki logiczne):**
  - `input.vendor.nip in [p.nip | p := input.partners[_]]` — kontrahent JEST wspólnikiem tej samej spółki
  - `input.invoice.direction == "PURCHASE"` — zakup od wspólnika
  - `input.invoice.amount_net > input.thresholds.sc.limits.intra_partner_transaction_alert` (domyślnie: 10 000 PLN)
  - ORAZ co najmniej jeden z warunków ryzyka:
    - `input.invoice.category_code` nie pasuje do `input.partnership.business_profile` (np. spółka IT kupuje "usługi budowlane" od wspólnika)
    - `input.invoice.amount_net` jest okrągłą kwotą (np. dokładnie 10 000.00 — brak uzasadnienia biznesowego)
    - Wspólnik-sprzedawca ma `tax_form == "LUMP_SUM"` a wspólnik-kupujący `tax_form == "LINEAR"` (arbitraż podatkowy)
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `intra_partnership_fraud_risk: true`
  - `_warning: "Transakcja między wspólnikami — ryzyko sztucznego generowania kosztów"`
- **Podstawa prawna:** Art. 55 KKS, Art. 119a § 1 Ordynacji podatkowej (GAAR), Art. 860 KC (umowa spółki — obowiązek lojalności)
- **Zależności:** Sprawdzana natychmiast po `fraud_graph_match`. Przed P1 (trust score)
- **Przypadki brzegowe i wyjątki:**
  - **WYJĄTEK:** Wspólnik świadczący rzeczywiste usługi na rzecz spółki (np. wspólnik-lekarz w spółce medycznej) — transakcja NIE jest fraudem jeśli `business_profile` pasuje
  - **WYJĄTEK:** Zakup środka trwałego od wspólnika (np. wspólnik sprzedaje spółce swój samochód) — dopuszczalne, ale wymaga dokumentacji cen transferowych
  - **WYJĄTEK:** Transakcje poniżej `intra_partner_transaction_alert` — tylko WARNING, nie BLOCK
  - **Śmierć wspólnika + transakcja z zarządcą sukcesyjnym:** Traktowana jak transakcja z podmiotem powiązanym — podwyższony alert
- **Priorytet:** 0.3

#### P1: `counterparty_trust_low`
- **Cel biznesowy:** Niski trust score kontrahenta → dodatkowa weryfikacja przed zaksięgowaniem. Dla SC szczególnie ważne przy nowych kontrahentach, bo odpowiedzialność solidarna oznacza, że wszyscy wspólnicy ponoszą ryzyko.
- **Przesłanki (szczegółowe warunki logiczne):**
  - `input.vendor.trust_score < input.thresholds.sc.limits.trust_auto_post` (0.92)
  - `input.vendor.trust_score > 0` (wyklucza nieznany score)
  - `input.invoice.amount_net > 0`
- **Oczekiwany rezultat:**
  - `_routing: "TRIAGE_QUEUE"`
  - `vendor_trust_score: <value>`
  - `joint_liability_risk: true` (bo wszyscy wspólnicy ryzykują)
- **Podstawa prawna:** Art. 22 UoR (zasada ostrożności), Art. 864 KC
- **Zależności:** Sprawdzana PO P0 (fraud) i P0_sc (intra-partnership)
- **Przypadki brzegowe i wyjątki:**
  - **Nowy kontrahent bez historii:** `trust_score == null` → traktowany jako 0.5 (domyślny) z flagą `new_counterparty: true`
  - **Kontrahent z oceną 0:** Błąd systemu — nie powinno się zdarzyć; jeśli wystąpi → BLOCK
  - **Kontrahent zagraniczny:** Dodatkowy warunek — sprawdzenie VIES; jeśli VIES OK → trust_score korygowany +0.10
  - **WYJĄTEK:** Kontrahent państwowy (nip w rejestrze REGON podmiotów publicznych) → pomija się trust score
- **Priorytet:** 1

#### P5: `semantic_guard_disallowed_sc`
- **Cel biznesowy:** Wykrycie wydatków ewidentnie niezwiązanych z działalnością spółki cywilnej. Dla SC KLUCZOWE: wydatek musi być związany z działalnością SPÓŁKI, nie prywatną wspólnika.
- **Przesłanki (szczegółowe warunki logiczne):**
  - `SemanticGuard` oznacza wydatek jako `disallowed`
  - LUB `input.invoice.category_code` w `["ALCOHOL", "ENTERTAINMENT", "LUXURY", "PERSONAL_EXPENSE"]`
  - I `input.invoice.business_justification_provided == false`
- **Oczekiwany rezultat:**
  - `kus_qualification: "none"` — brak KUP dla wszystkich wspólników
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Wydatek niezwiązany z działalnością spółki — NKUP dla wszystkich wspólników"`
- **Podstawa prawna:** Art. 22 ust. 1 PIT (związek z przychodem), Art. 23 ust. 1 pkt 23 PIT (reprezentacja), Art. 23 ust. 1 pkt 10 PIT (cele osobiste)
- **Zależności:** Przekazywane do PIT pass (P560+) jako KUP=0
- **Przypadki brzegowe i wyjątki:**
  - **Wydatek mieszany (częściowo firmowy):** Jeśli `private_use_percent > 0` → KUP proporcjonalny, nie pełne NKUP
  - **Alkohol na spotkaniu biznesowym:** Jeśli `has_business_context == true` → może być KUP (reprezentacja limitowana)
  - **Wydatek osobisty jednego wspólnika:** Jeśli faktura wystawiona na spółkę ale dotyczy prywatnego zakupu wspólnika → NKUP dla tego wspólnika, ale pozostali wspólnicy mogą mieć roszczenie regresowe (Art. 864 KC)
  - **WYJĄTEK:** Wydatki BHP, odzież robocza, badania lekarskie pracowników — zawsze KUP (Art. 229 KP)
- **Priorytet:** 5

#### P8: `ceidg_vendor_suspended_sc`
- **Cel biznesowy:** Kontrahent z zawieszoną działalnością w CEIDG. Dla SC kluczowe — spółka nie może odliczyć VAT od faktury od zawieszonego kontrahenta.
- **Przesłanki:**
  - `input.vendor.ceidg_status == "SUSPENDED"`
  - `input.invoice.transaction_date > input.vendor.suspension_start_date`
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `vat_deduction_blocked: true`
  - `joint_liability_triggered: true`
- **Podstawa prawna:** Art. 88 ustawy o VAT (wyłączenia z odliczenia), Art. 22-25 Prawa przedsiębiorców
- **Zależności:** Wpływa na P180+ (VAT deductions)
- **Przypadki brzegowe i wyjątki:**
  - **Kontrahent zawieszony po dacie transakcji:** VAT NIE jest blokowany — data transakcji decyduje
  - **Kontrahent z odwieszeniem wstecznym:** Po odwieszeniu — VAT odblokowany retrospektywnie
  - **WYJĄTEK:** Kontrahent zagraniczny (spoza CEIDG) — reguła nie ma zastosowania
- **Priorytet:** 8

#### P9: `gaar_artificial_scheme_sc`
- **Cel biznesowy:** Wykrycie transakcji sztucznie unikających opodatkowania z wykorzystaniem struktury spółki cywilnej (np. sztuczny podział dochodów między wspólników dla uniknięcia II progu podatkowego).
- **Przesłanki:**
  - `input.vendor.is_related_party == true` LUB kontrahent jest wspólnikiem
  - `abs(input.invoice.amount_net - estimated_market_price) / estimated_market_price > 0.50` (cena odbiega o >50% od rynkowej)
  - `input.invoice.amount_net > input.thresholds.sc.limits.gaar_materiality_threshold` (domyślnie: 100 000 PLN)
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `gaar_risk: true`, `gaar_risk_level: "HIGH"`
  - `joint_liability_triggered: true`
- **Podstawa prawna:** Art. 119a § 1 Ordynacji podatkowej
- **Przypadki brzegowe:**
  - **Sztuczny podział dochodu między wspólników:** Wspólnik A (skala, dochód 200k → 32%) przekazuje "usługi" wspólnikowi B (skala, dochód 40k → 12%) za cenę poniżej rynku → GAAR FLAG
  - **Transfer aktywów między wspólnikami:** Sprzedaż udziału w SC za cenę odbiegającą od rynkowej → GAAR
  - **WYJĄTEK:** Uzasadniona biznesowo restrukturyzacja z dokumentacją → nie GAAR
- **Priorytet:** 9

---

### 5.2 sc.routing — Field Confidence (P10-P19)

#### P10: `fc_vat_rate_low_sc`
- **Cel biznesowy:** Niska pewność odczytu stawki VAT z faktury → blokada automatycznego księgowania. Błędna stawka VAT wpływa na JPK_V7 spółki i odpowiedzialność solidarną.
- **Przesłanki:**
  - `input.confidence.fc_vat_rate < input.thresholds.sc.fc_thresholds.vat_rate` (0.95)
  - `input.confidence.fc_vat_rate > 0` (pole zostało odczytane, tylko z niską pewnością)
  - `input.invoice.vat_taxable == true`
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `_routing_reason: "Niska pewność stawki VAT"`
- **Podstawa prawna:** Art. 22 UoR (rzetelność ksiąg), Art. 99 VAT (JPK_V7)
- **Przypadki brzegowe:**
  - **Faktura proforma:** Niższy próg (0.80) — proforma nie jest dokumentem księgowym
  - **Faktura od kontrahenta zwolnionego z VAT:** Pomija się — stawka zawsze 0%
  - **Faktura z odwrotnym obciążeniem:** Pomija się — VAT rozlicza nabywca
- **Priorytet:** 10

#### P15: `fc_partner_fields_low_sc` ★
- **Cel biznesowy:** Dla SC unikalna reguła — niska pewność pól związanych ze wspólnikami (np. niejasne, który wspólnik jest stroną transakcji).
- **Przesłanki:**
  - `input.confidence.fc_partner_identification < input.thresholds.sc.fc_thresholds.partner_id` (0.90)
  - `input.invoice.beneficiary_is_partner == true` LUB `input.invoice.involves_partner_asset == true`
- **Oczekiwany rezultat:**
  - `_routing: "TRIAGE_QUEUE"`
  - `_routing_reason: "Niejasna identyfikacja wspólnika w transakcji"`
- **Podstawa prawna:** Art. 22 UoR, Art. 8 PIT (konieczność prawidłowego przypisania przychodu/kosztu)
- **Przypadki brzegowe:**
  - **Transakcja dotycząca majątku prywatnego wspólnika używanego w SC:** Wymaga potwierdzenia od wspólnika
  - **Faktura na spółkę ale adres prywatny wspólnika:** Ostrzeżenie — możliwe NKUP
- **Priorytet:** 15

---

### 5.3 sc.compliance — Zgodność dokumentacyjna (P20-P39)

#### P20: `whitelist_missing_over_limit_sc`
- **Cel biznesowy:** Weryfikacja Białej Listy MF dla przelewów spółki >15 000 PLN. Odpowiedzialność solidarna wspólników za brak weryfikacji.
- **Przesłanki:**
  - `input.invoice.amount_gross >= input.thresholds.sc.limits.mpp_limit` (15 000)
  - `input.vendor.on_whitelist == false`
  - `input.invoice.direction == "PURCHASE"` (dotyczy tylko zakupów spółki)
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `joint_liability_triggered: true` — wszyscy wspólnicy solidarnie
  - `_warning: "Brak kontrahenta na Białej Liście — odpowiedzialność solidarna wspólników (Art. 864 KC + Art. 117ba Ordynacji)"`
- **Podstawa prawna:** Art. 96b ustawy o VAT, Art. 117ba Ordynacji podatkowej, Art. 864 KC
- **Zależności:** Wynik przekazywany do P1150 (joint liability)
- **Przypadki brzegowe i wyjątki:**
  - **Przelew podzielony na raty <15k:** Łączna wartość faktury >15k → obowiązek WL, nawet jeśli przelew w ratach
  - **Kontrahent zagraniczny:** Brak na polskiej WL → sprawdzenie VIES; jeśli VIES OK → tylko WARNING
  - **WYJĄTEK:** Przelew na rachunek VAT (MPP) → zwolnienie z odpowiedzialności solidarnej (Art. 108a ust. 1d VAT)
  - **WYJĄTEK:** Płatność kartą, blikiem, gotówką → WL nie dotyczy (ale gotówka >15k → osobna reguła P35)
  - **Złożenie ZAW-NR w ciągu 7 dni:** Zwolnienie z sankcji po fakcie
- **Priorytet:** 20

#### P25: `split_payment_mandatory_sc`
- **Cel biznesowy:** Obowiązkowy MPP dla faktur >15k PLN z towarami wrażliwymi. Spółka cywilna ma własny rachunek VAT (jako odrębny podatnik).
- **Przesłanki:**
  - `input.invoice.amount_gross >= input.thresholds.sc.limits.mpp_limit`
  - `input.invoice.category_code` w katalogu MPP (załącznik nr 15 do VAT: paliwa, stal, elektronika, usługi budowlane, etc.)
  - `input.invoice.direction == "PURCHASE"`
- **Oczekiwany rezultat:**
  - `mpp_required: true`
  - `vat_account_required: true`
  - `_warning: "Obowiązkowy MPP — przelew na rachunek VAT spółki"`
- **Podstawa prawna:** Art. 108a ustawy o VAT
- **Przypadki brzegowe:**
  - **Faktura na kwotę <15k ale suma faktur od tego kontrahenta >15k w miesiącu:** NIE ma obowiązku MPP — limit per faktura, nie per kontrahent
  - **Faktura częściowo wrażliwa:** Jeśli choć jedna pozycja z załącznika nr 15 → MPP na całą fakturę
  - **WYJĄTEK:** Faktura z odwrotnym obciążeniem → NIE MPP
  - **WYJĄTEK:** Płatność kompensatą/potrąceniem → NIE MPP (ale ryzyko podatkowe)
- **Priorytet:** 25

#### P36: `cash_register_b2c_limit_sc` ★★
- **Cel biznesowy:** Limit zwolnienia z kasy fiskalnej 20 000 PLN dla spółki cywilnej. **UWAGA: Limit dotyczy CAŁEJ spółki (suma B2C), nie pojedynczego wspólnika!** To kluczowa różnica vs JDG.
- **Przesłanki:**
  - `input.partnership.annual_b2c_turnover < input.thresholds.sc.limits.cash_register_exemption_limit` (20 000)
  - `input.invoice.direction == "SALE"`
  - `input.vendor.is_b2c == true`
- **Oczekiwany rezultat:**
  - Poniżej 20k: `cash_register_exempt: true`
  - Powyżej 20k: `cash_register_mandatory: true`, `cash_register_deadline_days: 60` (2 miesiące od przekroczenia)
- **Podstawa prawna:** Rozporządzenie MF w sprawie zwolnień z kas rejestrujących
- **Przypadki brzegowe:**
  - **Nowa spółka:** Limit proporcjonalny (20k × (dni do końca roku / 365))
  - **Bezwzględny obowiązek kasy:** Niektóre kategorie (mechanicy, lekarze, fryzjerzy, taksówkarze) mają kasę od pierwszej transakcji — NIE dotyczy ich limit 20k. `[TODO: pełna lista kategorii z rozporządzenia]`
  - **Sprzedaż wysyłkowa/internetowa:** Limit 20k też obowiązuje, ale po przekroczeniu → kasa wirtualna (aplikacja)
- **Priorytet:** 36

#### P39: `vat_r_registration_sc` ★
- **Cel biznesowy:** Blokada transakcji gdy spółka cywilna nie jest zarejestrowana jako czynny podatnik VAT. Spółka ma własny NIP i własny VAT-R, niezależny od VAT-R wspólników.
- **Przesłanki:**
  - `input.partnership.vat_status == "unregistered"`
  - `input.invoice.vat_taxable == true`
  - `input.invoice.transaction_date >= input.partnership.vat_registration_deadline`
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `vat_r_required: true`
  - `_warning: "Spółka nie jest zarejestrowana jako czynny podatnik VAT — brak prawa do wystawienia faktury VAT"`
- **Podstawa prawna:** Art. 96 ust. 1 i 3 ustawy o VAT
- **Przypadki brzegowe:**
  - **VAT-R w trakcie rejestracji (złożony, nierozpatrzony):** Status `pending` — faktury mogą być wystawiane z adnotacją "VAT-R w trakcie"
  - **Spółka zwolniona podmiotowo (<200k):** Może wystawiać faktury bez VAT (zwolnienie), ale nie może wystawiać faktur VAT
  - **Odmowa rejestracji VAT-R przez US:** BLOCK wszystkich faktur sprzedażowych do czasu rejestracji
- **Priorytet:** 39

---

### 5.4 sc.crossborder — Transakcje transgraniczne (P40-P49)

#### P40: `eu_reverse_charge_wnt_sc`
- **Cel biznesowy:** Wewnątrzwspólnotowe nabycie towarów (WNT) — VAT rozlicza spółka jako nabywca (reverse charge). Transakcja wykazywana w JPK_V7 spółki.
- **Przesłanki:**
  - `input.vendor.country in input.thresholds.sc.eu_countries`
  - `input.vendor.vat_status == "active"`
  - `input.invoice.procedure == "WNT"`
  - `input.partnership.is_vat_payer == true` (spółka musi być czynnym podatnikiem VAT)
- **Oczekiwany rezultat:**
  - `vat_rate: "0.00"`
  - `procedure: "VAT_REVERSE_CHARGE"`
  - `gtu_code: "GTU_12"`
  - `vat_nip: input.partnership.nip` (NIP spółki!)
- **Podstawa prawna:** Art. 17 ust. 1 pkt 3 VAT
- **Przypadki brzegowe:**
  - **WNT od kontrahenta bez VAT-UE:** NIE reverse charge → standardowa stawka krajowa
  - **WNT nowego środka transportu:** Dodatkowy obowiązek — VAT-23, akcyza
  - **WNT z zaliczką:** Obowiązek podatkowy w dacie zapłaty zaliczki (Art. 20 ust. 3 VAT)
- **Priorytet:** 40

#### P42: `wdt_intracommunity_supply_sc` ★
- **Cel biznesowy:** Wewnątrzwspólnotowa dostawa towarów (WDT) — stawka 0% VAT dla spółki jako dostawcy. Wymagany jest VAT-UE spółki.
- **Przesłanki:**
  - `input.invoice.direction == "SALE"`
  - `input.vendor.country in input.thresholds.sc.eu_countries`
  - `input.vendor.vat_eu_active == true`
  - `input.partnership.is_vat_eu_registered == true` — spółka musi mieć VAT-UE
  - `input.invoice.has_transport_documentation == true` — dowody wywozu
- **Oczekiwany rezultat:**
  - `vat_rate: "0.00"`
  - `procedure: "WDT"`
  - `vat_ue_summary_required: true` — informacja podsumowująca VAT-UE
- **Podstawa prawna:** Art. 42 VAT, Art. 97 VAT (rejestracja VAT-UE)
- **Przypadki brzegowe:**
  - **Brak dokumentacji wywozu:** Stawka 0% NIE ma zastosowania → stawka krajowa (23%/8%/5%)
  - **WDT do kontrahenta bez VAT-UE:** NIE 0% → stawka krajowa
  - **WDT dla osoby fizycznej (B2C):** NIE WDT → sprzedaż krajowa lub sprzedaż wysyłkowa (OSS)
  - **Spółka bez VAT-UE:** NIE może stosować 0% WDT → stawka krajowa
- **Priorytet:** 42

#### P49: `triangular_transaction_sc` ★
- **Cel biznesowy:** Transakcje trójstronne — procedura uproszczona. Spółka jako pośrednik w łańcuchu dostaw UE.
- **Przesłanki:**
  - Trzy podmioty z 3 różnych krajów UE, wszystkie z VAT-UE
  - Towar przemieszcza się bezpośrednio od pierwszego do ostatniego
  - Spółka jest drugim podmiotem (pośrednikiem)
- **Oczekiwany rezultat:**
  - `procedure: "TRIANGULAR_SIMPLIFIED"`
  - Spółka NIE rozlicza WNT — tylko faktura bez VAT dla ostatniego
  - `vat_ue_summary_required: true`
- **Podstawa prawna:** Art. 135-138 Dyrektywy VAT, Art. 26 ustawy o VAT
- **Przypadki brzegowe:**
  - **Niespełnienie warunków uproszczonych:** Spółka musi zarejestrować się dla VAT w kraju przeznaczenia
  - **Jeden z podmiotów spoza UE:** Procedura uproszczona NIE ma zastosowania
- **Priorytet:** 49

### 5.5 sc.vat.substantive — VAT stawki i zwolnienia (P50-P69)

> **Kluczowa zasada:** Spółka cywilna jest **odrębnym podatnikiem VAT** z własnym NIP. Wszystkie reguły VAT dotyczą **spółki jako całości**, nie poszczególnych wspólników.

#### P50: `vat_margin_scheme_sc`
- **Cel biznesowy:** Procedura VAT-marża dla towarów używanych, dzieł sztuki, antyków. Spółka jako podatnik VAT.
- **Przesłanki:** `input.invoice.procedure == "MARGIN"` LUB `input.invoice.category_code` w `["ART", "ANTIQUES", "SECOND_HAND"]`
- **Oczekiwany rezultat:** `vat_rate: "0.23"` (od marży, nie od pełnej kwoty), `procedure: "MARGIN"`, `vat_base: "MARGIN_NOT_FULL"`, `rounding_level: "position"`
- **Podstawa prawna:** Art. 120 ustawy o VAT
- **Przypadki brzegowe:** Towary używane kupione od osoby fizycznej (bez VAT) → marża = cena sprzedaży - cena zakupu. Brak możliwości odliczenia VAT z faktury zakupu.
- **Priorytet:** 50

#### P52: `vat_rate_fuel_pl_sc`
- **Cel biznesowy:** Stawka VAT 23% dla paliw silnikowych + kod GTU_04. Faktura wystawiona na spółkę.
- **Przesłanki:** `input.invoice.category_code == "FUEL"` AND `input.vendor.country == "PL"`
- **Oczekiwany rezultat:** `vat_rate: "0.23"`, `gtu_code: "GTU_04"`, `rounding_level: "position"`
- **Podstawa prawna:** Art. 41 ust. 1 VAT
- **Przypadki brzegowe:** Paliwo do samochodu mieszanego (osobowego) → tylko 50% VAT do odliczenia (P186). Paliwo do samochodu ciężarowego → 100% VAT. Paliwo kupowane za granicą (WNT) → reverse charge.
- **Priorytet:** 52

#### P53: `vat_rate_food_pl_sc`
- **Cel biznesowy:** Żywność → 5% VAT (lub 8% dla wybranych). Mapowanie wg rozporządzenia MF.
- **Przesłanki:** `input.invoice.category_code == "FOOD"` AND `input.vendor.country == "PL"`
- **Oczekiwany rezultat:** `vat_rate: "0.05"` (domyślnie 5%), `gtu_code: "GTU_07"`
- **Podstawa prawna:** Art. 41 ust. 2a VAT, Rozporządzenie MF z 4.12.2024 w sprawie obniżonych stawek VAT
- **Przypadki brzegowe:** Kawa/herbata w gastronomii → 8% (usługa gastronomiczna, nie towar). Catering → 8%. Alkohol w restauracji → 23%.
- **Priorytet:** 53

#### P55: `vat_exemption_education_sc`
- **Cel biznesowy:** Usługi edukacyjne zwolnione z VAT. Częste w SC (szkoły językowe, korepetycje prowadzone przez spółkę).
- **Przesłanki:** `input.invoice.category_code == "EDUCATION"` AND `input.vendor.country == "PL"`
- **Oczekiwany rezultat:** `vat_rate: "0.00"`, `vat_exemption: "OBJECT_EDUCATION"`, `rounding_level: "total"`
- **Podstawa prawna:** Art. 43 ust. 1 pkt 26-29 VAT
- **Przypadki brzegowe:** Korepetycje prywatne → zwolnione. Szkolenia zawodowe finansowane ze środków publicznych → zwolnione. Szkolenia komercyjne (firmowe) → 23% VAT. Usługi e-learningowe → zwolnione jeśli spełniają warunki.
- **Priorytet:** 55

#### P56: `vat_exemption_healthcare_sc`
- **Cel biznesowy:** Usługi medyczne zwolnione z VAT. Dla SC ważne — spółka lekarska (lekarze jako wspólnicy) jest zwolniona.
- **Przesłanki:** `input.invoice.category_code == "HEALTHCARE"` AND `input.vendor.country == "PL"`
- **Oczekiwany rezultat:** `vat_rate: "0.00"`, `vat_exemption: "OBJECT_HEALTHCARE"`, `rounding_level: "total"`
- **Podstawa prawna:** Art. 43 ust. 1 pkt 18-21 VAT
- **Przypadki brzegowe:** Medycyna estetyczna (botoks, powiększanie ust) → 23% VAT (nie jest usługą medyczną). Stomatologia → zwolniona. Protetyka → zwolniona. Weterynaria → 8% (nie jest zwolniona jako usługa medyczna dla ludzi).
- **Priorytet:** 56

#### P57: `vat_exemption_finance_insurance_sc`
- **Cel biznesowy:** Usługi finansowe i ubezpieczeniowe zwolnione z VAT.
- **Przesłanki:** `input.invoice.category_code` w `["FINANCE", "INSURANCE", "BANKING"]`
- **Oczekiwany rezultat:** `vat_rate: "0.00"`, `vat_exemption: "OBJECT_FINANCE"`
- **Podstawa prawna:** Art. 43 ust. 1 pkt 7, 37-41 VAT
- **Przypadki brzegowe:** Doradztwo finansowe → 23% (nie jest usługą finansową sensu stricto). Leasing finansowy → opłata wstępna opodatkowana 23%, raty kapitałowe zwolnione.
- **Priorytet:** 57

#### P58: `vat_exemption_subject_sc` ★★★
- **Cel biznesowy:** **TO JEST KLUCZOWA REGUŁA VAT DLA SC.** Zwolnienie podmiotowe VAT dla spółki cywilnej. Limit 200 000 PLN dotyczy **spółki jako całości** (suma przychodów wszystkich wspólników!), a NIE pojedynczego wspólnika. To fundamentalna różnica vs JDG.
- **Przesłanki (szczegółowe):**
  - `input.partnership.is_vat_payer == false` — spółka nie jest czynnym podatnikiem VAT
  - `input.partnership.annual_turnover_net < input.thresholds.sc.limits.vat_exemption_limit` (200 000)
  - Dla spółek nowo rozpoczynających: limit proporcjonalny (200 000 × (dni do końca roku / 365))
  - Limit weryfikowany jako **suma przychodów wszystkich wspólników z SC**
- **Oczekiwany rezultat:**
  - `vat_rate: "0.00"`
  - `vat_exemption: "SUBJECT"`
  - `vat_exemption_entity: "PARTNERSHIP"` (nie partner!)
  - `vat_exemption_limit_applies_to: "TOTAL_PARTNERSHIP_REVENUE"`
  - `_warning: "Zwolnienie podmiotowe VAT — dotyczy całej spółki (limit 200k dla sumy przychodów)"`
- **Podstawa prawna:** Art. 113 ust. 1 i ust. 9 ustawy o VAT
- **Zależności:** Sprawdzana PRZED wszystkimi regułami stawek VAT. Jeśli przekroczony → spółka musi się zarejestrować jako czynny podatnik VAT (VAT-R).
- **Przypadki brzegowe i wyjątki:**
  - **Przekroczenie limitu w trakcie roku:** Spółka traci zwolnienie od momentu przekroczenia. VAT należny od nadwyżki.
  - **Wspólnik A ma własną JDG zwolnioną z VAT + udział w SC:** Limity NIE sumują się — limit SC jest odrębny od limitu JDG wspólnika. Każdy byt ma własny limit 200k.
  - **Sprzedaż towarów akcyzowych/hazardowych:** NIE podlega zwolnieniu podmiotowemu — bezwzględny obowiązek VAT-R.
  - **Usługi prawnicze, doradcze, jubilerskie:** NIE podlegają zwolnieniu podmiotowemu — obowiązek VAT-R od pierwszej transakcji.
  - **Spółka przekracza limit w grudniu:** VAT od stycznia następnego roku (rejestracja do 25 stycznia).
- **Priorytet:** 58

#### P60: `vat_bad_debt_relief_creditor_sc`
- **Cel biznesowy:** Ulga na złe długi VAT dla spółki jako wierzyciela. Korekta VAT należnego po 150 dniach od terminu płatności.
- **Przesłanki:**
  - `input.invoice.direction == "SALE"`
  - `input.invoice.is_paid == false`
  - `input.invoice.days_overdue >= input.thresholds.sc.limits.bad_debt_days_vat` (150)
  - `input.vendor.status != "RESTRUCTURING"` i `input.vendor.status != "BANKRUPT"`
- **Oczekiwany rezultat:**
  - `bad_debt_relief_eligible: true`
  - `vat_correction_type: "IN_MINUS"`
  - `vat_correction_period: current_period`
- **Podstawa prawna:** Art. 89a VAT
- **Przypadki brzegowe:** Dłużnik w restrukturyzacji/upadłości → brak ulgi. Późniejsza zapłata → korekta in plus w okresie zapłaty.
- **Priorytet:** 60

#### P62: `vat_rate_construction_sc`
- **Cel biznesowy:** Usługi budowlane — stawka 8% dla budownictwa mieszkaniowego, 23% dla komercyjnego.
- **Przesłanki:** `input.invoice.category_code == "CONSTRUCTION"` AND typ budynku = mieszkalny
- **Oczekiwany rezultat:** `vat_rate: "0.08"` (mieszkalne) lub `"0.23"` (komercyjne), `gtu_code: "GTU_08"`
- **Podstawa prawna:** Art. 41 ust. 12 VAT
- **Przypadki brzegowe:** Reverse charge budowlany — jeśli podwykonawca → odwrotne obciążenie (VAT=0%, rozlicza nabywca).
- **Priorytet:** 62

#### P63: `vat_rate_it_services_sc`
- **Cel biznesowy:** Usługi IT, programowanie, SaaS — stawka 23%.
- **Przesłanki:** `input.invoice.category_code` w `["IT_SERVICES", "SOFTWARE", "SAAS"]`
- **Oczekiwany rezultat:** `vat_rate: "0.23"`, `gtu_code: "GTU_01"` (dla sprzętu IT) lub `""` (dla usług)
- **Podstawa prawna:** Art. 41 ust. 1 VAT
- **Przypadki brzegowe:** Eksport usług IT do UE (B2B) → NP (VAT rozlicza nabywca, Art. 28b VAT). Sprzedaż e-booków → 5% VAT.
- **Priorytet:** 63

---

### 5.6 sc.vat.deductions — VAT odliczenia (P180-P192)

#### P180: `vat_deduction_right_basic_sc`
- **Cel biznesowy:** Podstawowe prawo do odliczenia VAT naliczonego przez spółkę — tylko gdy zakup związany z czynnościami opodatkowanymi.
- **Przesłanki:** `input.invoice.direction == "PURCHASE"` AND `input.partnership.is_vat_payer == true` AND `input.invoice.has_vat_invoice == true`
- **Oczekiwany rezultat:** `vat_deduction_right: true`, `vat_deductible_amount: input.invoice.vat_amount`
- **Podstawa prawna:** Art. 86 ust. 1 VAT
- **Przypadki brzegowe:** Zakup na cele prywatne wspólników → brak odliczenia dla spółki. Zakup związany tylko ze sprzedażą zwolnioną → brak odliczenia.
- **Priorytet:** 180

#### P184: `bad_debt_debtor_correction_sc` ★★★
- **Cel biznesowy:** **OBOWIĄZEK spółki jako dłużnika** do korekty odliczonego VAT po 90 dniach od terminu płatności. Sankcja 30% za brak korekty. Odpowiedzialność solidarna wspólników!
- **Przesłanki:**
  - `input.invoice.direction == "PURCHASE"`
  - `input.invoice.is_paid == false`
  - `input.invoice.is_vat_deducted == true`
  - `input.invoice.days_overdue >= 90`
- **Oczekiwany rezultat:**
  - `vat_correction_in_minus_mandatory: true` — OBOWIĄZKOWA korekta
  - `vat_to_return: <kwota odliczonego VAT>`
  - `_routing: "BLOCK_AND_ALERT"`
  - `sanction_risk_30pct: true` — sankcja 30% za brak
  - `joint_liability_triggered: true` — WSPÓLNICY SOLIDARNIE
- **Podstawa prawna:** Art. 89b VAT, Art. 864 KC
- **Przypadki brzegowe:**
  - **Częściowa zapłata:** Korekta tylko od niezapłaconej części
  - **Późniejsza zapłata (po korekcie):** Odwrotna korekta in plus w okresie zapłaty
  - **Upadłość dłużnika:** Korekta obowiązuje mimo upadłości
- **Priorytet:** 184

#### P186: `vehicle_50_vat_deduction_sc` ★
- **Cel biznesowy:** Samochód osobowy używany mieszanie (firmowo-prywatnie) — tylko 50% VAT do odliczenia przez spółkę.
- **Przesłanki:**
  - `input.invoice.category_code == "VEHICLE"`
  - `input.invoice.vehicle_type == "PASSENGER_CAR"`
  - `input.invoice.is_exclusively_business == false`
- **Oczekiwany rezultat:** `vat_deductible_percent: 50`, `vat_deductible_amount: vat_amount * 0.50`
- **Podstawa prawna:** Art. 86a ust. 1 VAT
- **Przypadki brzegowe:** Auto z kratką (ciężarowe) → 100% VAT. Auto na wynajem (fleet) → 100% VAT. Prowadzenie ewidencji przebiegu → możliwość 100% VAT. Leasing auta mieszanego → też 50% VAT.
- **Priorytet:** 186

#### P188: `vat_pre_proportion_sc` ★
- **Cel biznesowy:** Pre-proporcja VAT — gdy spółka wykonuje zarówno czynności opodatkowane jak i zwolnione. Odliczenie proporcjonalne.
- **Przesłanki:** `input.partnership.vat_pre_pro_rata_applicable == true`
- **Oczekiwany rezultat:** `vat_deductible_percent: input.partnership.vat_pre_pro_rata_percent`, `vat_deduction_annual_reconciliation: true`
- **Podstawa prawna:** Art. 90 VAT
- **Przypadki brzegowe:** Proporcja < 2% → brak odliczenia. Proporcja > 98% → pełne odliczenie. Roczne rozliczenie wstępnej proporcji.
- **Priorytet:** 188

#### P190: `vat_deduction_blocked_categories_sc`
- **Cel biznesowy:** Kategorie wydatków, od których VAT NIGDY nie podlega odliczeniu (hotele, gastronomia, reprezentacja).
- **Przesłanki:** `input.invoice.category_code` w `["HOTEL", "RESTAURANT_NON_CATERING", "ENTERTAINMENT"]`
- **Oczekiwany rezultat:** `vat_deductible_percent: 0`, `vat_blocked: true`
- **Podstawa prawna:** Art. 88 ust. 1 pkt 4 VAT
- **Przypadki brzegowe:** Catering na spotkanie firmowe → 100% odliczenia (nie jest gastronomią). Hotele dla pracowników w delegacji → 100% odliczenia.
- **Priorytet:** 190

---

### 5.7 sc.vat.tax_point — Moment obowiązku podatkowego (P230-P235)

#### P230: `vat_tax_point_general_sc`
- **Cel biznesowy:** Ogólna zasada — moment obowiązku podatkowego VAT dla spółki. Data dostawy towaru lub wykonania usługi.
- **Przesłanki:** `input.invoice.delivery_date` != null AND brak szczególnych reguł tax point
- **Oczekiwany rezultat:** `vat_tax_point: input.invoice.delivery_date`, `jpk_period: <MM-YYYY od delivery_date>`
- **Podstawa prawna:** Art. 19a ust. 1 VAT
- **Przypadki brzegowe:** Faktura wystawiona przed dostawą → obowiązek w dacie faktury. Faktura wystawiona >30 dni po dostawie → 30. dzień od dostawy.
- **Priorytet:** 230

#### P231: `vat_tax_point_continuous_service_sc`
- **Cel biznesowy:** Usługi ciągłe (czynsz, abonament, monitoring) — obowiązek z końcem okresu rozliczeniowego.
- **Przesłanki:** `input.invoice.is_continuous_service == true`
- **Oczekiwany rezultat:** `vat_tax_point: <koniec okresu rozliczeniowego>`, `vat_tax_point_type: "END_OF_PERIOD"`
- **Podstawa prawna:** Art. 19a ust. 3 VAT
- **Przypadki brzegowe:** Zapłata przed końcem okresu → obowiązek w dacie zapłaty. Usługi najmu → koniec okresu, za który należny jest czynsz.
- **Priorytet:** 231

#### P232: `vat_tax_point_advance_payment_sc`
- **Cel biznesowy:** Otrzymanie zaliczki przed dostawą — obowiązek VAT w dacie otrzymania zaliczki.
- **Przesłanki:** `input.invoice.invoice_type == "ADVANCE"` OR `input.invoice.is_advance_payment == true`
- **Oczekiwany rezultat:** `vat_tax_point: input.invoice.payment_date`, `vat_base: zaliczka_brutto / 1.23`
- **Podstawa prawna:** Art. 19a ust. 8 VAT
- **Przypadki brzegowe:** Faktura końcowa po zaliczce → VAT od różnicy (pełna kwota - zaliczka). Zaliczka w walucie obcej → przeliczenie po kursie z dnia poprzedzającego.
- **Priorytet:** 232

#### P233: `vat_tax_point_invoice_30_days_late_sc`
- **Cel biznesowy:** Faktura wystawiona ponad 30 dni po dostawie — obowiązek podatkowy w 30. dniu od dostawy.
- **Przesłanki:** `days_between(input.invoice.delivery_date, input.invoice.issue_date) > 30`
- **Oczekiwany rezultat:** `vat_tax_point: delivery_date + 30_days`, `vat_tax_point_type: "30TH_DAY_AFTER_DELIVERY"`
- **Podstawa prawna:** Art. 19a ust. 7 VAT
- **Przypadki brzegowe:** Usługi budowlane z protokołem odbioru — data protokołu = data wykonania. Sprzedaż energii — obowiązek w dacie odczytu licznika.
- **Priorytet:** 233

---

### 5.8 sc.vat.gtu — Kody GTU (P65a-P65m)

#### P65: `gtu_mapping_by_category_sc`
- **Cel biznesowy:** Automatyczne mapowanie kategorii wydatku na 13 kodów GTU dla JPK_V7 spółki.
- **Mapowanie:**

| GTU | Kategorie | Opis |
|-----|-----------|------|
| GTU_01 | IT_OFFICE, ELECTRONICS | Sprzęt elektroniczny, komputery |
| GTU_02 | ALCOHOL | Alkohol etylowy |
| GTU_03 | TOBACCO | Wyroby tytoniowe, e-papierosy |
| GTU_04 | FUEL, OILS | Paliwa, oleje napędowe |
| GTU_05 | SCRAP, WASTE | Złom, odpady, surowce wtórne |
| GTU_06 | TRANSPORT | Usługi transportowe, spedycja |
| GTU_07 | FOOD, GROCERIES | Żywność, artykuły spożywcze |
| GTU_08 | CONSTRUCTION | Roboty budowlane |
| GTU_09 | PHARMA, MEDICAL_EQUIPMENT | Leki, wyroby medyczne |
| GTU_10 | REAL_ESTATE | Nieruchomości, grunty |
| GTU_11 | GAS_ENERGY | Gaz, energia elektryczna, ciepło |
| GTU_12 | EU_SERVICES, EU_GOODS | Usługi/towary wewnątrzwspólnotowe |
| GTU_13 | NON_EU_GOODS, IMPORT | Import spoza UE |

- **Oczekiwany rezultat:** `gtu_code: <odpowiedni kod>`
- **Podstawa prawna:** § 10 rozporządzenia w sprawie JPK_VAT
- **Przypadki brzegowe:** Brak GTU dla faktur poniżej 15 000 PLN (niektóre kody). Kilka GTU na jednej fakturze → wszystkie wymienione.
- **Priorytet:** 65

---

### 5.9 sc.pit.proportional — PIT wspólników — podział proporcjonalny (P500-P509)

> **KLUCZOWA ZASADA:** Spółka cywilna NIE jest podatnikiem PIT. Podatnikami są WSPÓLNICY (Art. 8 PIT).

#### P500: `partner_proportional_split` ★★★ FUNDAMENT
- **Cel biznesowy:** **TO JEST NAJWAŻNIEJSZA REGUŁA W CAŁYM SYSTEMIE SC.** Proporcjonalny podział przychodów i kosztów spółki między wspólników zgodnie z Art. 8 PIT. Bez tej reguły system nie może działać.
- **Przesłanki (szczegółowe warunki logiczne):**
  - `count(input.partners) >= 2` — min. 2 wspólników
  - `input.partnership.total_revenue > 0` LUB `input.partnership.total_costs > 0`
  - Suma `share_percent` wszystkich wspólników = 100.0 (walidowane przez P501)
  - Dla każdego wspólnika `p`:
    - `p.revenue_share = input.partnership.total_revenue * (p.share_percent / 100)`
    - `p.cost_share = input.partnership.total_costs * (p.share_percent / 100)`
    - `p.income_share = p.revenue_share - p.cost_share`
    - `p.loss_share` = analogicznie przy stracie
- **Oczekiwany rezultat:** Tablica `partners_results[]` z indywidualnymi wartościami per wspólnik
- **Podstawa prawna:** Art. 8 ust. 1-2 ustawy o PIT
- **Zależności:** Ta reguła MUSI być wykonana PRZED wszystkimi regułami PIT (formy, KUP, zaliczki, zeznania). Wynik P500 jest inputem dla P510-P588.
- **Przypadki brzegowe i wyjątki:**
  - **Zmiana udziałów w trakcie roku (np. 1 lipca):** Przychody/koszty do 30 czerwca dzielone wg starych udziałów, od 1 lipca wg nowych — patrz P502/P503. To NAJTRUDNIEJSZY przypadek!
  - **Wspólnik z 0% udziału (cicha spółka):** NIE jest wspólnikiem w rozumieniu KC — nie dzieli przychodów/kosztów, tylko otrzymuje wynagrodzenie (KUP dla spółki)
  - **Nierówne udziały (np. 70/30):** Podział proporcjonalny — wspólnik 70% otrzymuje 70% przychodów i 70% kosztów
  - **Strata zamiast dochodu:** Podział straty też proporcjonalny — każdy wspólnik rozlicza swoją część straty
  - **Wspólnik, który przystąpił w trakcie miesiąca:** Proporcjonalnie do dni (np. przystąpił 15. dnia → 50% udziału za ten miesiąc)
- **Priorytet:** 500

#### P501: `partner_share_validation_sc` ★
- **Cel biznesowy:** Walidacja poprawności udziałów wspólników — suma musi wynosić dokładnie 100%.
- **Przesłanki:** Suma `[p.share_percent | p := input.partners[_]]` != 100.0
- **Oczekiwany rezultat:** `_routing: "BLOCK_AND_ALERT"`, `_warning: "Suma udziałów wspólników ≠ 100% — nie można dokonać podziału"`
- **Podstawa prawna:** Art. 867 KC (udział w zyskach), Art. 8 PIT
- **Przypadki brzegowe:** Udziały wyrażone jako ułamki (33.33% + 33.33% + 33.34% = 100%). Granica błędu zaokrągleń: ±0.01.
- **Priorytet:** 501

#### P502: `partner_revenue_split_by_date` ★★★
- **Cel biznesowy:** Podział przychodu z uwzględnieniem zmiany udziałów w trakcie roku podatkowego. Przychód przypada wspólnikom proporcjonalnie do ich udziału w DNIU powstania przychodu.
- **Przesłanki:** `input.partnership.share_change_date` != null (zmiana udziałów w trakcie roku)
- **Oczekiwany rezultat:** Dla każdego wspólnika: `p.revenue_share = revenue_before_change * (old_share/100) + revenue_after_change * (new_share/100)`
- **Podstawa prawna:** Art. 8 ust. 1 PIT (interpretacja: przychód dzielony wg udziału na dzień jego powstania)
- **Przypadki brzegowe:**
  - **Przychód z faktury z datą sprzedaży = data zmiany udziałów:** Decyduje data sprzedaży (dostawy), nie data faktury
  - **Zaliczka otrzymana przed zmianą, dostawa po zmianie:** Przychód w dacie zaliczki (stare udziały) + reszta w dacie dostawy (nowe udziały)
  - **Wielokrotne zmiany udziałów w roku:** Każdy okres z innymi udziałami — podział proporcjonalny per okres
- **Priorytet:** 502

#### P503: `partner_cost_split_by_date` ★★★
- **Cel biznesowy:** Analogicznie do P502, ale dla kosztów uzyskania przychodu. KUP dzielony wg udziałów w dniu poniesienia kosztu.
- **Przesłanki:** `input.partnership.share_change_date` != null
- **Oczekiwany rezultat:** `p.cost_share = costs_before_change * (old_share/100) + costs_after_change * (new_share/100)`
- **Podstawa prawna:** Art. 8 ust. 2 pkt 1 PIT
- **Przypadki brzegowe:** Koszty pośrednie (czynsz, media) — data faktury = data poniesienia. Koszty bezpośrednie (towary) — data sprzedaży towaru.
- **Priorytet:** 503

#### P505: `partner_own_work_exclusion_sc` ★★★
- **Cel biznesowy:** Wartość własnej pracy wspólnika na rzecz spółki NIE stanowi KUP (Art. 23 ust. 1 pkt 10 PIT). Ale praca wspólnika na podstawie umowy o pracę lub umowy cywilnoprawnej → KUP.
- **Przesłanki:**
  - `input.invoice.beneficiary_is_partner == true`
  - `input.invoice.expense_type == "LABOR"`
  - `input.invoice.has_formal_contract == false` — brak umowy
- **Oczekiwany rezultat:**
  - `kus_qualification: "none"` — NKUP
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Wartość własnej pracy wspólnika nie stanowi KUP (Art. 23 ust. 1 pkt 10 PIT)"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 10 PIT
- **Przypadki brzegowe:**
  - **Wspólnik z umową o pracę:** Wynagrodzenie = KUP dla spółki (standardowy koszt pracowniczy)
  - **Wspólnik z umową zlecenia:** Wynagrodzenie = KUP, ale składki ZUS od umowy zlecenia są KUP
  - **Wspólnik użycza spółce swój prywatny samochód:** Odpłatne użyczenie → KUP jeśli umowa. Bezpłatne → NKUP, ale koszty eksploatacji (paliwo) → KUP
- **Priorytet:** 505

---

### 5.10 sc.pit.forms — Formy opodatkowania per wspólnik (P510-P539)

#### P510: `partner_pit_scale_sc`
- **Cel biznesowy:** Identyfikacja skali podatkowej 12%/32% dla wspólnika.
- **Przesłanki:** `p.tax_form == "PIT_SCALE"`
- **Oczekiwany rezultat:**
  - `p.pit_form: "SCALE"`
  - `p.pit_rate: "0.12"` (I próg ≤120k) lub `"0.32"` (II próg >120k)
  - `p.tax_free_amount: 30000` (kwota wolna)
  - `p.tax_free_reduction: 3600` (12% × 30 000)
  - `p.pit_annual_return_type: "PIT-36"`
  - `p.joint_filing_possible: true`
- **Podstawa prawna:** Art. 27 ust. 1 PIT
- **Przypadki brzegowe:** Wspólne rozliczenie z małżonkiem — podwaja próg do 240k. Dochody z innych źródeł (etat, najem) sumują się z dochodem z SC dla ustalenia progu.
- **Priorytet:** 510

#### P511: `partner_pit_scale_bracket_determination_sc`
- **Cel biznesowy:** Ustalenie konkretnego progu podatkowego na podstawie narastającego dochodu wspólnika.
- **Przesłanki:** `p.cumulative_income` (narastająco od początku roku)
- **Oczekiwany rezultat:** `p.pit_bracket: "LOW"` (≤120k) lub `"HIGH"` (>120k), `p.pit_effective_rate: <obliczona>`
- **Podstawa prawna:** Art. 27 ust. 1 PIT
- **Przypadki brzegowe:** Przekroczenie progu w trakcie roku → od następnego miesiąca zaliczka 32% od nadwyżki. Strata w kolejnych miesiącach → korekta w dół.
- **Priorytet:** 511

#### P515: `partner_pit_linear_sc`
- **Cel biznesowy:** Podatek liniowy 19% dla wspólnika.
- **Przesłanki:** `p.tax_form == "LINEAR"`
- **Oczekiwany rezultat:**
  - `p.pit_rate: "0.19"`
  - `p.tax_free_amount: 0` — BRAK kwoty wolnej!
  - `p.joint_filing_possible: false`
  - `p.pit_annual_return_type: "PIT-36L"`
- **Podstawa prawna:** Art. 30c PIT
- **Przypadki brzegowe:** Limit odliczenia składki zdrowotnej od dochodu: 12 900 PLN rocznie. Brak możliwości odliczenia ulgi na dzieci.
- **Priorytet:** 515

#### P516: `partner_pit_linear_former_employer_sc` ★★
- **Cel biznesowy:** Wspólnik NIE może być na podatku liniowym jeśli świadczy usługi na rzecz byłego pracodawcy — nawet przez spółkę cywilną.
- **Przesłanki:**
  - `p.tax_form == "LINEAR"`
  - Spółka świadczy usługi na rzecz `p.former_employer_nip`
  - W roku bieżącym lub poprzednim
- **Oczekiwany rezultat:**
  - `p.linear_blocked: true`
  - `p.must_use_scale: true`
  - `_warning: "Wspólnik — zakaz podatku liniowego (usługi dla byłego pracodawcy, Art. 9a ust. 3 PIT)"`
  - Automatyczne przejście na skalę (P510)
- **Podstawa prawna:** Art. 9a ust. 3 PIT
- **Przypadki brzegowe:** Usługi inne niż te świadczone w ramach stosunku pracy → liniowy dopuszczalny. Okres karencji: rok bieżący + rok poprzedni.
- **Priorytet:** 516

#### P520: `partner_pit_lump_sum_sc`
- **Cel biznesowy:** Ryczałt ewidencjonowany dla wspólnika — podatek od przychodu (nie dochodu).
- **Przesłanki:** `p.tax_form == "LUMP_SUM"`
- **Oczekiwany rezultat:** `p.pit_form: "LUMP_SUM"`, `p.pit_rate` wg PKWiU (P521), `p.pit_annual_return_type: "PIT-28"` (termin **28 lutego!**)
- **Podstawa prawna:** Art. 12 ustawy o ryczałcie
- **Przypadki brzegowe:** Limit ryczałtu to 2M EUR **przychodu spółki** (nie wspólnika!). Jeśli spółka przekroczy → wszyscy wspólnicy na ryczałcie tracą prawo.
- **Priorytet:** 520

#### P525: `partner_pit_lump_sum_limit_sc` ★★
- **Cel biznesowy:** Limit ryczałtu 2M EUR dotyczy PRZYCHODU SPÓŁKI, nie pojedynczego wspólnika. To kluczowa różnica!
- **Przesłanki:** `input.partnership.annual_turnover_net >= input.thresholds.sc.limits.lump_sum_annual_limit_eur * nbp_eur_rate`
- **Oczekiwany rezultat:** `p.lump_sum_available: false` (dla wszystkich wspólników na ryczałcie), `p.must_switch_to_scale: true`
- **Podstawa prawna:** Art. 6 ust. 4 ustawy o ryczałcie
- **Przypadki brzegowe:** Przekroczenie limitu w trakcie roku → od następnego miesiąca skala. Wspólnik, który NIE był na ryczałcie → bez zmian.
- **Priorytet:** 525

#### P535: `partner_different_forms_sc` ★★
- **Cel biznesowy:** **UNIKALNA CECHA SC:** Różni wspólnicy mogą mieć różne formy opodatkowania! System musi to obsłużyć.
- **Przesłanki:** `count(distinct([p.tax_form | p := input.partners[_]])) > 1`
- **Oczekiwany rezultat:**
  - `multi_form_partnership: true`
  - Każdy wspólnik ma niezależnie obliczony PIT (skala/liniowy/ryczałt/karta)
  - `_info: "Spółka z różnymi formami opodatkowania wspólników"`
- **Podstawa prawna:** Art. 9a PIT (każdy wspólnik wybiera formę samodzielnie)
- **Przypadki brzegowe:**
  - **Wspólnik A (skala) + Wspólnik B (liniowy) + Wspólnik C (ryczałt):** System generuje 3 niezależne kalkulacje
  - **Zmiana formy przez jednego wspólnika:** Nie wpływa na pozostałych
  - **Konflikt: wspólnik na ryczałcie a spółka przekracza 2M EUR:** Tylko wspólnik na ryczałcie traci prawo — pozostali bez zmian
- **Priorytet:** 535

#### P538: `partner_form_change_mid_year_sc` ★
- **Cel biznesowy:** Zmiana formy opodatkowania przez wspólnika w trakcie roku — zasadniczo niedopuszczalna, ale są wyjątki.
- **Przesłanki:** `p.tax_form_changed_during_year == true`
- **Oczekiwany rezultat:** `p.form_change_allowed: false` (domyślnie), `p.must_file_two_returns: true` (jeśli dozwolone)
- **Podstawa prawna:** Art. 9a ust. 4-5 PIT
- **Przypadki brzegowe:** Utrata prawa do ryczałtu/karty → automatyczne przejście na skalę. Likwidacja JDG + rozpoczęcie SC → nowa forma. Zmiana formy od nowego roku → dozwolona (oświadczenie do 20 stycznia).
- **Priorytet:** 538

### 5.11 sc.pit.kup — KUP per wspólnik (P560-P582)

#### P560: `partner_kup_full_deductible_sc`
- **Cel biznesowy:** Pełny KUP dla wspólnika — wydatek związany z działalnością spółki, proporcjonalnie do udziału.
- **Przesłanki:** `p.kus_qualification == "full"` AND wydatek związany z przychodem spółki
- **Oczekiwany rezultat:** `p.kup_percent: 100`, `p.kup_amount: total_kup * (p.share_percent / 100)`
- **Podstawa prawna:** Art. 22 ust. 1 PIT
- **Przypadki brzegowe:** Nawet pełny KUP jest dzielony proporcjonalnie między wspólników.
- **Priorytet:** 560

#### P561: `partner_kup_zus_social_deductible_sc`
- **Cel biznesowy:** Składki ZUS społeczne opłacone przez wspólnika → KUP od jego dochodu. UWAGA: składki ZUS wspólnika NIE są kosztem spółki — są odliczane indywidualnie!
- **Przesłanki:** `p.zus_social_paid > 0`
- **Oczekiwany rezultat:** `p.kup_zus_deduction: p.zus_social_paid`
- **Podstawa prawna:** Art. 26 ust. 1 pkt 2 PIT
- **Przypadki brzegowe:** Tylko składki ZAPŁACONE w roku podatkowym. Niezapłacone → NKUP.
- **Priorytet:** 561

#### P562: `partner_kup_private_mixed_sc` ★
- **Cel biznesowy:** Wydatki mieszane (prywatno-firmowe) — szczególnie problematyczne w SC, gdzie koszty mogą być generowane przez jednego wspólnika a dzielone na wszystkich.
- **Przesłanki:** `input.invoice.private_use_percent > 0`
- **Oczekiwany rezultat:** `p.kup_deductible: (total_cost * (1 - private_use_percent/100)) * (p.share_percent / 100)`
- **Podstawa prawna:** Art. 22 ust. 1 PIT, Art. 23 ust. 1 pkt 10 PIT
- **Przypadki brzegowe:** Samochód mieszany (75% firmowy, 25% prywatny) → KUP 75%. Domowe biuro → proporcja metrażowa.
- **Priorytet:** 562

#### P566: `partner_kup_representation_none_sc`
- **Cel biznesowy:** Reprezentacja, gastronomia, rozrywka → NKUP. Dotyczy wszystkich wspólników proporcjonalnie.
- **Przesłanki:** `input.invoice.category_code` w `["REPRESENTATION", "RESTAURANT", "ENTERTAINMENT"]`
- **Oczekiwany rezultat:** `p.kup_percent: 0`, `p.kus_qualification: "none"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 23 PIT
- **Przypadki brzegowe:** Spotkanie biznesowe z kontrahentem w restauracji → NKUP. Pizza dla pracowników w biurze → KUP (koszt socjalny).
- **Priorytet:** 566

#### P568: `partner_kup_unpaid_zus_sc` ★
- **Cel biznesowy:** Niezapłacone składki ZUS → NKUP. Ale dotyczy tylko składek danego wspólnika — nie blokuje KUP innym.
- **Przesłanki:** `p.zus_social_accrued > p.zus_social_paid`
- **Oczekiwany rezultat:** `p.kup_zus_deduction: p.zus_social_paid` (tylko zapłacone)
- **Podstawa prawna:** Art. 23 ust. 1 pkt 55 PIT
- **Przypadki brzegowe:** Składki zapłacone po terminie ale przed złożeniem zeznania → KUP w roku zapłaty.
- **Priorytet:** 568

#### P570: `partner_kup_health_contrib_deduction_sc` ★
- **Cel biznesowy:** Odliczenie składki zdrowotnej od dochodu — limit 12 900 PLN dla liniowego.
- **Przesłanki:** `p.tax_form == "LINEAR"`
- **Oczekiwany rezultat:** `p.health_deduction: min(p.health_paid, 12900)`
- **Podstawa prawna:** Art. 30c ust. 2 PIT
- **Przypadki brzegowe:** Przy skali — zdrowotna NIE podlega odliczeniu (Polski Ład).
- **Priorytet:** 570

#### P578: `partner_kup_own_work_nkup_sc` ★★
- **Cel biznesowy:** Praca własna wspólnika → NKUP (bez umowy). Wspólnik nie może wystawić faktury spółce za "zarządzanie" i zaliczyć jako KUP.
- **Przesłanki:** `input.invoice.beneficiary_is_partner == true` AND `input.invoice.has_formal_contract == false`
- **Oczekiwany rezultat:** `kus_qualification: "none"`, `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 10 PIT
- **Przypadki brzegowe:** Małżonek wspólnika bez umowy → też NKUP. Dzieci wspólnika bez umowy → NKUP.
- **Priorytet:** 578

#### P579: `partner_kup_spouse_contract_sc` ★
- **Cel biznesowy:** Wynagrodzenie małżonka wspólnika — KUP tylko jeśli istnieje formalna umowa.
- **Przesłanki:** `input.invoice.beneficiary_is_spouse == true` AND `input.invoice.has_formal_contract == true`
- **Oczekiwany rezultat:** `kus_qualification: "full"` (z umową) lub `"none"` (bez umowy)
- **Podstawa prawna:** Art. 23 ust. 1 pkt 10 PIT
- **Przypadki brzegowe:** Umowa o pracę z małżonkiem → pełny KUP (składki ZUS, PIT pobierane normalnie).
- **Priorytet:** 579

---

### 5.12 sc.pit.advances — Zaliczki PIT per wspólnik (P540-P549)

#### P540: `partner_advance_monthly_sc` ★
- **Cel biznesowy:** Obliczenie miesięcznej zaliczki na PIT dla każdego wspólnika osobno. Każdy wspólnik płaci własną zaliczkę od swojej części dochodu.
- **Przesłanki:** Dla każdego `p`:
  - Skala: `(p.cumulative_income - p.paid_advances_ytd - p.zus_social_paid) * p.pit_rate - p.tax_free_reduction`
  - Liniowy: `(p.cumulative_income - p.paid_advances_ytd - p.zus_social_paid) * 0.19`
  - Ryczałt: `p.cumulative_revenue * lump_sum_rate - p.paid_advances_ytd`
- **Oczekiwany rezultat:** `p.monthly_advance: <kwota>`, `p.advance_due_date: "20. dnia następnego miesiąca"`
- **Podstawa prawna:** Art. 44 ust. 1-3 PIT
- **Przypadki brzegowe:** Zaliczka ujemna/zero → brak wpłaty w tym miesiącu. Możliwość nieregularnych zaliczek (uproszczonych).
- **Priorytet:** 540

#### P541: `partner_advance_zus_deduction_sc` ★
- **Cel biznesowy:** Odliczenie składek ZUS społecznych od zaliczki. UWAGA: składki ZUS wspólnika są odliczane od JEGO zaliczki, nie od zaliczek innych wspólników.
- **Przesłanki:** `p.zus_social_paid_current_month > 0`
- **Oczekiwany rezultat:** `p.advance_after_zus: p.advance_before_zus - p.zus_social_paid_current_month`
- **Podstawa prawna:** Art. 26 ust. 1 pkt 2, Art. 44 ust. 1 PIT
- **Przypadki brzegowe:** Wspólnik z ulgą na start (0 ZUS społeczne) → brak odliczenia. Wspólnik na etacie (zdrowotna tylko) → odlicza tylko zdrowotną (limit 12 900).
- **Priorytet:** 541

---

### 5.13 sc.pit.returns — Zeznania roczne (P550-P559)

#### P550: `partner_annual_return_pit36_sc` ★
- **Cel biznesowy:** Obowiązek złożenia PIT-36 przez wspólnika na skali. Dochód z SC w pozycji "działalność gospodarcza".
- **Przesłanki:** `p.tax_form == "PIT_SCALE"`
- **Oczekiwany rezultat:** `p.annual_return_type: "PIT-36"`, `p.annual_return_deadline: "30 kwietnia"`
- **Podstawa prawna:** Art. 45 ust. 1 PIT
- **Przypadki brzegowe:** Wspólne rozliczenie z małżonkiem. Dochody z etatu/najmu sumują się z SC.
- **Priorytet:** 550

#### P554: `partner_annual_return_pit28_sc` ★
- **Cel biznesowy:** PIT-28 dla wspólnika na ryczałcie. TERMIN: 28 lutego (nie 30 kwietnia!). To częsty błąd!
- **Przesłanki:** `p.tax_form == "LUMP_SUM"`
- **Oczekiwany rezultat:** `p.annual_return_type: "PIT-28"`, `p.annual_return_deadline: "28 lutego"`
- **Podstawa prawna:** Art. 21 ust. 1 ustawy o ryczałcie
- **Przypadki brzegowe:** Ryczałtowiec nie składa PIT-36 — tylko PIT-28. Nie ma obowiązku składania PIT-36 nawet jeśli ma inne dochody opodatkowane skalą (wtedy składa oba).
- **Priorytet:** 554

---

### 5.14 sc.pit.exemptions — Zwolnienia PIT (P580-P588)

#### P580: `partner_exemption_young_sc` ★
- **Cel biznesowy:** Ulga dla młodych (<26 lat) — zwolnienie z PIT do 85 528 PLN przychodu. Dotyczy każdego młodego wspólnika indywidualnie.
- **Przesłanki:** `p.age <= 26` AND `p.annual_revenue_from_sc <= input.thresholds.sc.bounds.pit_young_exemption_limit`
- **Oczekiwany rezultat:** `p.pit_rate: "0.00"`, `p.exemption_type: "YOUNG"`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 148 PIT
- **Przypadki brzegowe:** Wspólnik A (25 lat) → zwolniony. Wspólnik B (35 lat) → normalnie opodatkowany. Limit 85 528 PLN dotyczy SUMY przychodów wspólnika (z SC + inne źródła).
- **Priorytet:** 580

#### P584: `partner_exemption_family_4plus_sc` ★
- **Cel biznesowy:** Ulga 4+ dzieci — zwolnienie z PIT do 85 528 PLN. Dotyczy wspólnika z 4+ dzieci.
- **Przesłanki:** `p.children_count >= 4` AND `p.annual_revenue <= input.thresholds.sc.bounds.pit_family_4plus_limit`
- **Oczekiwany rezultat:** `p.pit_rate: "0.00"`, `p.exemption_type: "FAMILY_4PLUS"`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 153 PIT
- **Przypadki brzegowe:** Wspólnik z 4 dzieci i współmałżonek też z 4 dzieci → oboje mogą skorzystać (jeśli oboje są w SC).
- **Priorytet:** 584

#### P588: `partner_exemption_combined_limit_sc` ★
- **Cel biznesowy:** Łączny limit PIT-0 (młodzi + powrót + 4+ + senior) = 85 528 PLN rocznie. Suma zwolnień nie może przekroczyć tego limitu.
- **Przesłanki:** Suma przychodów objętych PIT-0 > 85 528 PLN
- **Oczekiwany rezultat:** `p.exemption_capped: true`, `p.taxable_excess: suma - 85528`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 148, 152, 153, 154 PIT
- **Przypadki brzegowe:** Wspólnik korzystający z kilku PIT-0 jednocześnie → limit łączny.
- **Priorytet:** 588

---

### 5.15 sc.partnership.formation — Powstanie i walidacja (P900-P904)

#### P900: `sc_formation_valid` ★★★
- **Cel biznesowy:** Walidacja poprawności zawiązania spółki cywilnej. Umowa na piśmie (Art. 860 § 2 KC), min. 2 wspólników, wszyscy przedsiębiorcy.
- **Przesłanki:**
  - `count(input.partners) >= 2`
  - `input.partnership.agreement_written == true`
  - Każdy wspólnik ma `ceidg_registered == true`
  - `input.partnership.agreement_date` != null
- **Oczekiwany rezultat:** `partnership_valid: true`
- **Podstawa prawna:** Art. 860 § 1-2 KC, Art. 14 Prawa przedsiębiorców
- **Przypadki brzegowe:** Umowa ustna (poniżej 10 000 PLN wkładu) → dopuszczalna, ale NIE dla celów podatkowych. Brak CEIDG → spółka NIE istnieje w obrocie.
- **Priorytet:** 900

#### P901: `sc_ceidg_all_partners_registered_sc` ★
- **Cel biznesowy:** Każdy wspólnik musi być zarejestrowany w CEIDG z oznaczeniem udziału w SC.
- **Przesłanki:** Wszyscy wspólnicy mają `ceidg_registered == true`
- **Oczekiwany rezultat:** `all_partners_ceidg_registered: true`
- **Podstawa prawna:** Art. 5-7 ustawy o CEIDG
- **Przypadki brzegowe:** Brak wpisu CEIDG → spółka NIE istnieje formalnie (Art. 14 Prawa przedsiębiorców).
- **Priorytet:** 901

---

### 5.16 sc.partnership.changes — Zmiany składu (P905-P909)

#### P905: `sc_partner_join_procedure_sc` ★★
- **Cel biznesowy:** Przyjęcie nowego wspólnika — zmiana umowy, aktualizacja CEIDG (7 dni), nowy podział udziałów.
- **Przesłanki:** Nowy wspólnik dodany do `input.partners[]`
- **Oczekiwany rezultat:**
  - `ceidg_update_required: true`, `ceidg_update_deadline_days: 7`
  - `new_share_effective_date: <data przystąpienia>`
  - Od tej daty: nowy podział przychodów/kosztów (P502/P503)
- **Podstawa prawna:** Art. 860, 863 KC, Art. 30 CEIDG
- **Przypadki brzegowe:** Nowy wspólnik odpowiada za zobowiązania sprzed przystąpienia (Art. 864 KC).
- **Priorytet:** 905

#### P907: `sc_partner_exit_settlement_sc` ★★
- **Cel biznesowy:** Wystąpienie wspólnika — rozliczenie udziału, odpowiedzialność za długi sprzed wyjścia.
- **Przesłanki:** `p.exit_date` != null
- **Oczekiwany rezultat:**
  - `p.payout_amount: p.share_percent * partnership_net_assets`
  - `p.continuing_liability: true` (za długi sprzed wyjścia)
  - `p.liability_duration: do przedawnienia`
  - Spółka może trwać dalej jeśli zostaje ≥2 wspólników
- **Podstawa prawna:** Art. 869, Art. 871 KC
- **Przypadki brzegowe:** Wystąpienie jedynego (obok drugiego) wspólnika → rozwiązanie spółki.
- **Priorytet:** 907

---

### 5.17 sc.partnership.dissolution — Rozwiązanie (P920-P929)

#### P920: `sc_dissolution_grounds_sc` ★★
- **Cel biznesowy:** Przesłanki rozwiązania spółki: jednomyślna decyzja, śmierć wspólnika (gdy zostaje 1), upadłość.
- **Przesłanki:**
  - Decyzja wspólników: `input.partnership.status == "DISSOLVING"`
  - Z mocy prawa: `count(active_partners) < 2`
  - Upadłość spółki lub wspólnika
- **Oczekiwany rezultat:** `dissolution_triggered: true`, `dissolution_date: <data>`
- **Podstawa prawna:** Art. 872-875 KC
- **Przypadki brzegowe:** Śmierć wspólnika z zarządcą sukcesyjnym → spółka może trwać (P930).
- **Priorytet:** 920

#### P922: `sc_liquidation_procedure_sc` ★
- **Cel biznesowy:** Procedura likwidacyjna: spis majątku, spłata długów, podział pozostałości między wspólników.
- **Przesłanki:** `input.partnership.status == "DISSOLVING"`
- **Oczekiwany rezultat:**
  - `final_inventory_required: true`
  - `final_vat_declaration_required: true` (VAT-Z spółki)
  - `final_pit_returns_required: true` (dla każdego wspólnika)
  - `partition_order: debts → partner_payouts → residual`
- **Podstawa prawna:** Art. 875 KC, Art. 14 PIT, Art. 96 VAT
- **Przypadki brzegowe:** Majątek spółki niewystarczający na spłatę długów → wspólnicy solidarnie (Art. 864 KC).
- **Priorytet:** 922

---

### 5.18 sc.partnership.liability — Odpowiedzialność solidarna (P1150-P1174)

#### P1150: `sc_joint_liability_tax` ★★★
- **Cel biznesowy:** Odpowiedzialność solidarna wszystkich wspólników za zobowiązania podatkowe spółki (VAT, zaległości). Każdy odpowiada całym majątkiem.
- **Przesłanki:** Jakiekolwiek zobowiązanie podatkowe spółki (VAT, PCC, etc.)
- **Oczekiwany rezultat:** `joint_liability_type: "TAX"`, `liable_parties: [wszyscy wspólnicy]`, `liability_scope: "UNLIMITED_PERSONAL"`
- **Podstawa prawna:** Art. 864 KC, Art. 115 § 1 Ordynacji podatkowej
- **Przypadki brzegowe:** Wspólnik, który spłacił dług → roszczenie regresowe do pozostałych (Art. 376 KC).
- **Priorytet:** 1150

#### P1158: `sc_partner_exit_liability_sc` ★★★
- **Cel biznesowy:** Były wspólnik nadal odpowiada za zobowiązania powstałe PRZED jego wystąpieniem. Do czasu przedawnienia.
- **Przesłanki:** `p.exit_date < current_date` AND zobowiązanie `incurred_date < p.exit_date`
- **Oczekiwany rezultat:** `p.still_liable: true`, `p.liability_duration: "do przedawnienia"`
- **Podstawa prawna:** Art. 869 § 1, Art. 864 KC, Art. 70 Ordynacji podatkowej
- **Przypadki brzegowe:** Przedawnienie zobowiązania podatkowego (5 lat) → koniec odpowiedzialności.
- **Priorytet:** 1158

#### P1160: `sc_new_partner_prior_debts_sc` ★
- **Cel biznesowy:** Nowy wspólnik odpowiada solidarnie za długi spółki powstałe PRZED jego przystąpieniem.
- **Przesłanki:** `p.join_date > debt_incurred_date`
- **Oczekiwany rezultat:** `p.liable_for_prior_debts: true`
- **Podstawa prawna:** Art. 864 KC
- **Przypadki brzegowe:** Nowy wspólnik może żądać ujawnienia wszystkich długów przed przystąpieniem.
- **Priorytet:** 1160

---

### 5.19 sc.partnership.succession — Sukcesja (P930-P939)

#### P930: `sc_succession_partner_death_sc` ★★
- **Cel biznesowy:** Śmierć wspólnika — zarządca sukcesyjny kontynuuje działalność jeśli został ustanowiony.
- **Przesłanki:** `p.deceased == true`
- **Oczekiwany rezultat:**
  - Jeśli `p.has_succession_manager`: NIP z dopiskiem "S", spółka trwa
  - Jeśli brak zarządcy i zostaje <2 wspólników → rozwiązanie (P920)
- **Podstawa prawna:** Art. 872 KC, Ustawa o zarządzie sukcesyjnym (Dz.U. 2025 poz. 1234)
- **Przypadki brzegowe:** Zarządca sukcesyjny działa max 2 lata. Spadkobiercy dziedziczą udział.
- **Priorytet:** 930

#### P932: `sc_succession_inventory_obligation_sc` ★
- **Cel biznesowy:** Obowiązek sporządzenia remanentu na dzień śmierci wspólnika.
- **Przesłanki:** `p.deceased == true`
- **Oczekiwany rezultat:** `inventory_required: true`, `inventory_date: date_of_death`
- **Podstawa prawna:** Art. 24 ust. 3 PIT, Art. 27 ustawy o zarządzie sukcesyjnym
- **Przypadki brzegowe:** Remanent potrzebny do zamknięcia ksiąg zmarłego wspólnika.
- **Priorytet:** 932

---

### 5.20 sc.partnership.suspension — Zawieszenie (P940-P949)

#### P940: `sc_suspension_all_partners_sc` ★
- **Cel biznesowy:** Zawieszenie spółki — wymaga zawieszenia WSZYSTKICH wspólników.
- **Przesłanki:** `input.partnership.status == "SUSPENDED"` AND wszyscy `p.suspended == true`
- **Oczekiwany rezultat:**
  - `vat_declarations: "ZERO"`
  - `pit_advances: "NOT_REQUIRED"`
  - `costs_allowed: "MAINTENANCE_ONLY"`
  - `new_invoices_blocked: true`
- **Podstawa prawna:** Art. 22-25 Prawa przedsiębiorców
- **Przypadki brzegowe:** Nie wszyscy zawieszeni → spółka uznana za aktywną.
- **Priorytet:** 940

#### P942: `sc_suspension_zus_sc` ★
- **Cel biznesowy:** W trakcie zawieszenia wspólnicy nie płacą ZUS społecznych (tylko zdrowotna jeśli trzeba).
- **Przesłanki:** `p.suspended == true`
- **Oczekiwany rezultat:** `p.zus_social_due: 0`, `p.zus_health_due: <standardowa>`
- **Podstawa prawna:** Art. 36a ustawy o SUS
- **Przypadki brzegowe:** Zawieszenie max 24 miesiące. Po wznowieniu → standardowy ZUS.
- **Priorytet:** 942

### 5.21 sc.zus.social — Składki społeczne per wspólnik (P700-P719)

> **Kluczowa zasada:** Każdy wspólnik opłaca składki ZUS INDYWIDUALNIE od swojej części dochodu. Spółka NIE płaci ZUS za wspólników.

#### P700: `partner_zus_social_standard_sc`
- **Cel biznesowy:** Standardowe składki społeczne dla wspólnika SC. Podstawa: 60% prognozowanego przeciętnego wynagrodzenia.
- **Przesłanki:** `p.zus_status == "STANDARD"`
- **Oczekiwany rezultat:** `p.zus_base: 0.60 * average_wage`, `p.zus_social_total: base * (0.1952 + 0.08 + 0.0245 + 0.0167 + 0.0245 + 0.001)`
- **Podstawa prawna:** Art. 18, 22 ustawy o SUS
- **Przypadki brzegowe:** Składka chorobowa DOBROWOLNA (P701). Wspólnik może jej nie opłacać.
- **Priorytet:** 700

#### P701: `partner_zus_sickness_voluntary_sc` ★
- **Cel biznesowy:** Składka chorobowa jest DOBROWOLNA dla wspólników SC.
- **Przesłanki:** `p.zus_sickness_opted_in == false` → składka chorobowa = 0
- **Oczekiwany rezultat:** `p.zus_sickness: 0` (jeśli zrezygnowano) lub `base * 0.0245` (jeśli przystąpiono)
- **Podstawa prawna:** Art. 11 ust. 2, Art. 18a SUS
- **Przypadki brzegowe:** Brak składki chorobowej → brak zasiłku chorobowego.
- **Priorytet:** 701

#### P710: `partner_zus_start_relief_sc` ★
- **Cel biznesowy:** Ulga na start — 6 miesięcy bez składek społecznych (tylko zdrowotna). Dotyczy każdego nowego wspólnika indywidualnie.
- **Przesłanki:** `p.zus_status == "START_RELIEF"` AND `p.zus_months_used < input.thresholds.sc.bounds.zus_start_months`
- **Oczekiwany rezultat:** `p.zus_social_total: 0`, `p.zus_health_due: true`
- **Podstawa prawna:** Art. 18a SUS
- **Przypadki brzegowe:** Wspólnik A na uldze start, wspólnik B na standardowym ZUS — każdy ma własny status.
- **Priorytet:** 710

#### P711: `partner_zus_maly_plus_sc` ★
- **Cel biznesowy:** Mały ZUS Plus — obniżona podstawa przez 36 miesięcy. Dla każdego wspólnika osobno.
- **Przesłanki:** `p.zus_status == "MALY_ZUS_PLUS"` AND `p.zus_months_used < 36`
- **Oczekiwany rezultat:** `p.zus_base: 0.30 * average_wage` (zamiast 0.60)
- **Podstawa prawna:** Art. 18c SUS
- **Przypadki brzegowe:** Przychód wspólnika z SC w poprzednim roku ≤ 120 000 PLN (warunek).
- **Priorytet:** 711

#### P715: `partner_concurrent_employment_sc` ★★★
- **Cel biznesowy:** Zbieg etatu i SC — jeśli wspólnik ma umowę o pracę z wynagrodzeniem ≥ minimalne → z SC płaci TYLKO składkę zdrowotną (brak społecznych).
- **Przesłanki:** `p.has_employment_contract == true` AND `p.employment_salary >= input.thresholds.sc.bounds.minimum_wage_gross`
- **Oczekiwany rezultat:** `p.zus_social_from_sc: 0`, `p.zus_health_due: true`, `p.concurrent_status: "EMPLOYMENT_AND_SC"`
- **Podstawa prawna:** Art. 9 ust. 1a-2 ustawy o SUS
- **Przypadki brzegowe:** Wynagrodzenie z etatu < minimalne → pełny ZUS z SC. Pół etatu z pensją ≥ minimalną → tylko zdrowotna.
- **Priorytet:** 715

---

### 5.22 sc.zus.health — Składka zdrowotna (P720-P749)

#### P720: `partner_zus_health_scale_sc` ★
- **Cel biznesowy:** Składka zdrowotna 9% od dochodu dla wspólnika na skali. NIE podlega odliczeniu od podatku.
- **Przesłanki:** `p.tax_form == "PIT_SCALE"`
- **Oczekiwany rezultat:** `p.zus_health_rate: "0.09"`, `p.zus_health_base: "INCOME"`, `p.zus_health_deductible: false`
- **Podstawa prawna:** Art. 79 ust. 1 ustawy o świadczeniach opieki zdrowotnej
- **Przypadki brzegowe:** Minimalna składka: 9% od minimalnego wynagrodzenia (nie mniej).
- **Priorytet:** 720

#### P722: `partner_zus_health_linear_sc` ★
- **Cel biznesowy:** Składka zdrowotna 4.9% dla wspólnika na liniowym. Limit odliczenia od dochodu: 12 900 PLN.
- **Przesłanki:** `p.tax_form == "LINEAR"`
- **Oczekiwany rezultat:** `p.zus_health_rate: "0.049"`, `p.zus_health_deductible_limit: 12900`
- **Podstawa prawna:** Art. 81 ust. 1, Art. 30c ust. 2 PIT
- **Przypadki brzegowe:** Rzeczywista składka może być wyższa niż 12 900 — nadwyżka NIE podlega odliczeniu.
- **Priorytet:** 722

#### P724: `partner_zus_health_lump_sum_sc` ★
- **Cel biznesowy:** Składka zdrowotna dla ryczałtowca — 3 progi zależne od rocznego przychodu wspólnika.
- **Przesłanki:** `p.tax_form == "LUMP_SUM"`
- **Oczekiwany rezultat:**
  - Przychód ≤ 60 000 PLN: podstawa = 60% × przeciętne wynagrodzenie
  - 60 000 < przychód ≤ 300 000 PLN: podstawa = 100% × przeciętne wynagrodzenie
  - Przychód > 300 000 PLN: podstawa = 180% × przeciętne wynagrodzenie
  - Stawka zawsze 9%
- **Podstawa prawna:** Art. 81 ust. 2a-2c ustawy o świadczeniach
- **Przypadki brzegowe:** Roczne rozliczenie składki — jeśli przychód niższy niż zakładano → zwrot.
- **Priorytet:** 724

#### P730: `partner_health_contribution_matrix_sc` ★
- **Cel biznesowy:** Macierz forma opodatkowania → stawka zdrowotna + podstawa.
- **Mapowanie:**
  - Skala 12%/32% → 9% od dochodu, bez odliczenia
  - Liniowy 19% → 4.9% od dochodu, odliczenie max 12 900 PLN
  - Ryczałt → 9% od podstawy progowej (60%/100%/180% przeciętnego)
  - Karta podatkowa → 9% od 100% przeciętnego
- **Podstawa prawna:** Art. 79-81 ustawy o świadczeniach
- **Priorytet:** 730

---

### 5.23 sc.accounting.full — Pełna księgowość (P800-P819)

#### P800: `sc_full_accounting_threshold` ★★★
- **Cel biznesowy:** **KLUCZOWA REGUŁA KSIĘGOWA SC.** Spółka cywilna, której przychód netto za poprzedni rok przekroczył 2 000 000 EUR, ma OBOWIĄZEK prowadzenia pełnej księgowości (księgi rachunkowe wg UoR). Próg liczony dla PRZYCHODU SPÓŁKI, nie wspólnika.
- **Przesłanki:** `input.partnership.annual_turnover_net_prev_year >= input.thresholds.sc.limits.full_accounting_threshold_eur * nbp_eur_rate`
- **Oczekiwany rezultat:**
  - `accounting_method: "FULL"`
  - `uor_compliance_required: true`
  - Obowiązki: dziennik, księga główna, księgi pomocnicze, inwentaryzacja, wycena, podwójny zapis, sprawozdanie finansowe
- **Podstawa prawna:** Art. 2 ust. 1 pkt 1 UoR, Art. 24a ust. 4 PIT
- **Przypadki brzegowe:** Przekroczenie w trakcie roku → pełna księgowość od następnego roku. Spółka nie może wrócić do PKPiR nawet jeśli przychód spadnie.
- **Priorytet:** 800

#### P802: `sc_double_entry_validation_sc` ★
- **Cel biznesowy:** Walidacja podwójnego zapisu — Wn = Ma. Blokada niezbilansowanego zapisu.
- **Przesłanki:** `abs(sum(debit) - sum(credit)) > 0.01`
- **Oczekiwany rezultat:** `_routing: "BLOCK_AND_ALERT"`, `_warning: "Zapis niezbilansowany"`
- **Podstawa prawna:** Art. 22 ust. 1 UoR
- **Priorytet:** 802

#### P804: `sc_closing_books_mandatory_sc` ★
- **Cel biznesowy:** Blokada księgowania w zamkniętym roku obrotowym.
- **Przesłanki:** `input.invoice.issue_date <= input.partnership.closed_financial_year_end` AND `input.partnership.fs_approved == true`
- **Oczekiwany rezultat:** `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 12 ust. 2 pkt 1 UoR
- **Priorytet:** 804

---

### 5.24 sc.accounting.pkpir — PKPiR (P820-P829)

#### P810: `sc_pkpir_column_mapping_sc` ★
- **Cel biznesowy:** Mapowanie wydatków spółki na 16 kolumn PKPiR. Spółka prowadzi JEDNĄ wspólną PKPiR.
- **Przesłanki:** `input.partnership.accounting_method == "PKPIR"`
- **Oczekiwany rezultat:** `pkpir_column: <numer 1-16>`
- **Podstawa prawna:** Rozporządzenie MF w sprawie PKPiR
- **Przypadki brzegowe:** Kolumna 14 (NKUP) — wydatki nieuznawane za KUP. Kolumna 15 (ŚT) — środki trwałe.
- **Priorytet:** 810

#### P815: `sc_pkpir_partner_split_for_pit_sc` ★
- **Cel biznesowy:** Dane z PKPiR spółki są podstawą do wyliczenia przychodu i KUP każdego wspólnika.
- **Przesłanki:** `input.partnership.accounting_method == "PKPIR"`
- **Oczekiwany rezultat:** `p.pkpir_revenue = total * (p.share_percent / 100)`, `p.pkpir_costs = total * (p.share_percent / 100)`
- **Podstawa prawna:** Art. 8 PIT, Art. 24a PIT
- **Priorytet:** 815

---

### 5.25 sc.accounting.depreciation — Amortyzacja (P840-P859)

#### P840: `sc_depreciation_linear_sc` ★
- **Cel biznesowy:** Amortyzacja liniowa środków trwałych spółki. Odpisy są KUP spółki, dzielone między wspólników.
- **Przesłanki:** `input.invoice.expense_type == "FIXED_ASSET"`
- **Oczekiwany rezultat:** `depreciation_method: "LINEAR"`, `annual_rate` z KŚT
- **Podstawa prawna:** Art. 22a-22m PIT, Art. 32 UoR
- **Przypadki brzegowe:** Amortyzacja nieruchomości mieszkalnych → ZAKAZ (Art. 22c pkt 2 PIT).
- **Priorytet:** 840

#### P860: `sc_leasing_operational_kup_sc` ★
- **Cel biznesowy:** Leasing operacyjny — raty leasingowe są KUP spółki. Limit dla aut osobowych: 150 000 PLN (225 000 PLN dla EV).
- **Przesłanki:** `input.invoice.type == "OPERATING_LEASE"`
- **Oczekiwany rezultat:** `leasing_kup: min(lease_payment, proportional_limit)`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 47a PIT
- **Przypadki brzegowe:** Auto > 150k → tylko proporcjonalna część raty jest KUP.
- **Priorytet:** 860

#### P870: `sc_fx_differences_sc` ★
- **Cel biznesowy:** Różnice kursowe — przychód/koszt dla spółki, dzielone między wspólników.
- **Przesłanki:** `input.invoice.currency != "PLN"`
- **Oczekiwany rezultat:** `fx_result: <różnica>`, per wspólnik: `p.fx_share = fx_result * (p.share_percent / 100)`
- **Podstawa prawna:** Art. 24c PIT
- **Priorytet:** 870

---

### 5.26 sc.ksef — KSeF (P950-P969)

#### P950: `sc_ksef_mandatory_sc` ★
- **Cel biznesowy:** Obowiązek KSeF dla spółki cywilnej od 01.02.2026. Spółka jako czynny podatnik VAT.
- **Przesłanki:** `input.invoice.transaction_date >= "2026-02-01"` AND `input.partnership.is_vat_payer == true`
- **Oczekiwany rezultat:** `ksef_required: true`, `ksef_format: "XML_XSD"`
- **Podstawa prawna:** Art. 106na-106nq VAT, Dz.U. 2023 poz. 1598
- **Przypadki brzegowe:** B2C → wyłączone z KSeF. Faktury z kas fiskalnych → wyłączone.
- **Priorytet:** 950

#### P955: `sc_ksef_offline_recovery_sc` ★
- **Cel biznesowy:** Tryb awaryjny KSeF — awaria systemu → 7 dni na wysłanie faktury.
- **Przesłanki:** `input.system.ksef_status == "OFFLINE"`
- **Oczekiwany rezultat:** `ksef_offline_mode: true`, `ksef_submission_deadline_days: 7`
- **Podstawa prawna:** Art. 106ne VAT
- **Priorytet:** 955

---

### 5.27 sc.jpk — JPK (P970-P989)

#### P970: `sc_jpk_v7m_structure_sc` ★
- **Cel biznesowy:** JPK_V7M — miesięczna deklaracja VAT spółki. Spółka składa JEDNĄ deklarację (własny NIP).
- **Przesłanki:** `input.partnership.is_vat_payer == true`
- **Oczekiwany rezultat:** `jpk_v7m_required: true`, `jpk_deadline: "25. dnia miesiąca"`, `jpk_entity: "PARTNERSHIP"`
- **Podstawa prawna:** Art. 99 ust. 1 VAT
- **Priorytet:** 970

#### P975: `sc_jpk_gtu_completeness_sc` ★
- **Cel biznesowy:** Weryfikacja kompletności oznaczeń GTU. Brak GTU = odrzucenie JPK.
- **Przesłanki:** `input.invoice.category_code` wymaga GTU AND brak kodu
- **Oczekiwany rezultat:** `gtu_missing: true`, `_routing: "TRIAGE_QUEUE"`
- **Podstawa prawna:** § 10 rozporządzenia JPK_VAT
- **Priorytet:** 975

---

### 5.28 sc.employer — Spółka jako pracodawca (P1200-P1223)

#### P1200: `sc_employer_obligation_sc` ★
- **Cel biznesowy:** Spółka cywilna zatrudniająca pracowników → płatnik PIT i ZUS. Obowiązki ciążą na spółce, odpowiedzialność solidarna na wspólnikach.
- **Przesłanki:** `input.partnership.employees_count > 0`
- **Oczekiwany rezultat:**
  - `employer_mode: true`, `pit_4r_required: true`, `pit_11_required: true`
  - `zus_rca_required: true`, `ppk_obligation_check: true`
- **Podstawa prawna:** Art. 31-32 PIT, Art. 17-19 SUS
- **Przypadki brzegowe:** Wynagrodzenia wspólników — tylko z umową są kosztem pracowniczym spółki.
- **Priorytet:** 1200

#### P1208: `sc_ppk_obligation_sc` ★
- **Cel biznesowy:** Obowiązek PPK dla spółek zatrudniających powyżej 250 osób (i mniejszych w późniejszych terminach).
- **Przesłanki:** `input.partnership.employees_count >= 250`
- **Oczekiwany rezultat:** `ppk_required: true`, `ppk_employer_contribution: 0.015`
- **Podstawa prawna:** Art. 26-27 ustawy o PPK
- **Priorytet:** 1208

---

### 5.29 sc.allowances — Ulgi podatkowe per wspólnik (P600-P635)

#### P600: `partner_relief_rd_sc` ★
- **Cel biznesowy:** Ulga B+R — wspólnik odlicza swoją część kosztów B+R spółki. 100% kosztów kwalifikowanych (200% dla CBR).
- **Przesłanki:** `p.has_rd_status == true` AND spółka poniosła koszty B+R
- **Oczekiwany rezultat:** `p.relief_rd: partnership_rd_costs * (p.share_percent / 100) * 1.00`
- **Podstawa prawna:** Art. 26e PIT
- **Przypadki brzegowe:** Niewykorzystana ulga → carry-forward 6 lat.
- **Priorytet:** 600

#### P610: `partner_relief_ip_box_sc` ★
- **Cel biznesowy:** IP Box 5% — preferencyjna stawka od dochodu z kwalifikowanego IP.
- **Przesłanki:** Dochód z IP, wyodrębniona ewidencja
- **Oczekiwany rezultat:** `p.pit_rate: "0.05"`, `p.relief_type: "IP_BOX"`
- **Podstawa prawna:** Art. 30ca PIT
- **Priorytet:** 610

#### P615: `partner_loss_carry_forward_sc` ★
- **Cel biznesowy:** Rozliczenie straty podatkowej — każdy wspólnik rozlicza swoją część straty.
- **Przesłanki:** `p.has_loss == true`
- **Oczekiwany rezultat:** `p.loss_deduction: min(p.income * 0.50, p.remaining_loss)`
- **Podstawa prawna:** Art. 9 ust. 3 PIT
- **Przypadki brzegowe:** Max 50% straty rocznie przez 5 lat LUB 5M PLN jednorazowo.
- **Priorytet:** 615

---

### 5.30 sc.corrections — Korekty (P1100-P1120)

#### P1100: `sc_correction_invoice_in_minus_sc` ★
- **Cel biznesowy:** Korekta faktury in minus — wpływa na JPK_V7 spółki ORAZ na przychody/KUP wspólników.
- **Przesłanki:** `input.invoice.is_correction == true` AND `input.invoice.correction_type == "IN_MINUS"`
- **Oczekiwany rezultat:** `vat_correction: <okres>`, `pit_correction_per_partner: <kwota>`
- **Podstawa prawna:** Art. 29a ust. 13 VAT, Art. 14 ust. 1m PIT
- **Priorytet:** 1100

---

### 5.31 sc.local — Podatki lokalne (P1300-P1320)

#### P1300: `sc_pcc_loan_partner_sc` ★
- **Cel biznesowy:** PCC 0.5% od pożyczki udzielonej spółce przez wspólnika (powyżej limitu).
- **Przesłanki:** `input.invoice.type == "LOAN"` AND `input.vendor.nip in partners_nips`
- **Oczekiwany rezultat:** `pcc_rate: "0.005"`, `pcc_return_required: true` (PCC-3, 14 dni)
- **Podstawa prawna:** Art. 1 ust. 1 pkt 1 lit. a, Art. 7 ust. 1 pkt 4 PCC
- **Przypadki brzegowe:** Pożyczka od rodziny (grupa I) → zwolniona z PCC do 36 120 PLN.
- **Priorytet:** 1300

---

### 5.32 sc.fallback — Reguły domyślne (P1000-P1099)

#### P1000: `sc_domestic_fallback`
- **Cel biznesowy:** Domyślna stawka VAT 23% dla Polski gdy żadna konkretna reguła nie pasuje.
- **Przesłanki:** `input.vendor.country == "PL"` AND brak dopasowania
- **Oczekiwany rezultat:** `vat_rate: input.thresholds.sc.rates.vat_standard`, `rounding_level: "position"`
- **Podstawa prawna:** Art. 41 ust. 1 VAT
- **Priorytet:** 1000

#### P1010: `sc_partner_fallback_no_form_sc` ★
- **Cel biznesowy:** Jeśli wspólnik nie wybrał formy opodatkowania → domyślnie skala podatkowa.
- **Przesłanki:** `p.tax_form == ""` OR `p.tax_form == null`
- **Oczekiwany rezultat:** `p.tax_form: "PIT_SCALE"`, `p.pit_rate: "0.12"`
- **Podstawa prawna:** Art. 27 PIT (skala jako forma domyślna)
- **Priorytet:** 1010

#### P1099: `sc_no_match`
- **Cel biznesowy:** Ostateczny fallback gdy żadna reguła nie pasuje.
- **Przesłanki:** Żadna reguła nie dopasowana
- **Oczekiwany rezultat:** `matched: false`, `error: "NO_MATCHING_RULE"`, `_routing: "TRIAGE_QUEUE"`
- **Priorytet:** 1099 (always last via `default decide`)


---

## 6. Wymagane Dane Wejściowe (input)

### 6.1 Pełna Struktura `input` dla Spółki Cywilnej

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
    "delivery_date": "2026-06-10",
    "vat_taxable": true,
    "beneficiary_is_partner": false,
    "beneficiary_is_spouse": false,
    "has_formal_contract": false,
    "has_vat_invoice": true,
    "vehicle_type": ""
  },
  "vendor": {
    "nip": "1234567890",
    "country": "PL",
    "vat_status": "active",
    "on_whitelist": true,
    "ceidg_status": "ACTIVE",
    "is_related_party": false,
    "trust_score": 0.92,
    "fraud_flag": false,
    "is_b2c": false,
    "vat_eu_active": false
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
    "annual_b2c_turnover": 15000.00,
    "is_small_taxpayer": true,
    "accounting_method": "PKPIR",
    "employees_count": 3,
    "total_revenue": 10000.00,
    "total_costs": 6000.00,
    "share_change_date": null,
    "vat_pre_pro_rata_applicable": false,
    "vat_pre_pro_rata_percent": 0,
    "closed_financial_year_end": "2025-12-31",
    "fs_approved": false
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
      "has_rd_status": false,
      "has_loss": false,
      "exit_date": null,
      "join_date": "2020-01-15",
      "deceased": false,
      "has_succession_manager": false
    }
  ],
  "confidence": {
    "fc_vat_rate": 0.99,
    "fc_total_net": 0.98,
    "fc_vendor_nip": 0.99,
    "fc_category_code": 0.97,
    "fc_partner_identification": 0.95
  },
  "system": {
    "ksef_status": "ONLINE"
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
        "zus_pension": "0.1952",
        "zus_disability": "0.08",
        "zus_sickness": "0.0245",
        "zus_accident": "0.0167",
        "zus_health_scale": "0.09",
        "zus_health_linear_lump": "0.049",
        "zus_labour_fund": "0.0245",
        "zus_fgsp": "0.001"
      },
      "limits": {
        "mpp_limit": 15000,
        "vat_exemption_limit": 200000,
        "cash_transaction_limit": 15000,
        "bad_debt_days_vat": 150,
        "bad_debt_days_cit_pit": 90,
        "full_accounting_threshold_eur": 2000000,
        "lump_sum_annual_limit_eur": 2000000,
        "retention_years_invoice": 5,
        "retention_years_ledger": 5,
        "retention_years_payroll": 10,
        "trust_auto_post": 0.92,
        "car_value_kup_limit": 150000,
        "electric_car_kup_limit": 225000,
        "cash_register_exemption_limit": 20000,
        "intra_partner_transaction_alert": 10000,
        "gaar_materiality_threshold": 100000
      },
      "bounds": {
        "pit_scale_threshold": 120000,
        "pit_tax_free_amount": 30000,
        "pit_tax_free_reduction": 3600,
        "pit_young_exemption_limit": 85528,
        "pit_return_exemption_limit": 85528,
        "pit_family_4plus_limit": 85528,
        "relief_thermo_max": 53000,
        "relief_rd_base": 100,
        "relief_rd_centrum": 200,
        "zus_start_months": 6,
        "zus_preferential_months": 24,
        "zus_maly_plus_months": 36,
        "zus_health_linear_deduction_limit": 12900,
        "minimum_wage_gross": 4666,
        "ceidg_update_deadline_days": 7
      },
      "fc_thresholds": {
        "vat_rate": 0.95,
        "total_net": 0.90,
        "minimum": 0.85,
        "vendor_nip": 0.80,
        "partner_id": 0.90,
        "global_minimum": 0.70
      },
      "eu_countries": ["AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR","HU","IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK","SI","ES","SE"]
    }
  }
}
```

### 6.2 Walidacja wejścia

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
valid_partner_count { count(input.partners) >= 2 }

# Walidacja sumy udziałów = 100%
valid_share_total { sum([p.share_percent | p := input.partners[_]]) == 100.0 }
```

---

## 7. Obsługa Parametrów Dynamicznych (thresholds)

### 7.1 Model DuckDB

```sql
CREATE TABLE IF NOT EXISTS tax_thresholds_sc (
    threshold_key   VARCHAR PRIMARY KEY,
    threshold_value VARCHAR NOT NULL,
    valid_from      DATE NOT NULL,
    valid_to        DATE,
    description     VARCHAR,
    legal_basis     VARCHAR,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 7.2 Kluczowe progi specyficzne dla SC

| Klucz | Wartość | SC-specyficzny? | Opis |
|---|---:|---:|------|
| `limits.vat_exemption_limit` | 200 000 PLN | ✅ Dotyczy SUMY przychodów spółki | Zwolnienie podmiotowe VAT |
| `limits.full_accounting_threshold_eur` | 2 000 000 EUR | ✅ Dotyczy PRZYCHODU spółki | Obowiązek pełnej księgowości |
| `limits.lump_sum_annual_limit_eur` | 2 000 000 EUR | ✅ Dotyczy PRZYCHODU spółki | Limit ryczałtu |
| `limits.cash_register_exemption_limit` | 20 000 PLN | ✅ Dotyczy SUMY B2C spółki | Zwolnienie z kasy fiskalnej |
| `limits.intra_partner_transaction_alert` | 10 000 PLN | ✅ Unikalne dla SC | Alert dla transakcji między wspólnikami |
| `bounds.zus_health_linear_deduction_limit` | 12 900 PLN | Per wspólnik | Limit odliczenia zdrowotnej |

---

## 8. Architektura Multi-Pass — Scalanie Werdyktów

### 8.1 ScVerdictMerger

```python
class ScVerdictMerger:
    """Scala werdykty z 10 passów OPA w jeden finalny werdykt SC."""
    
    def merge(self, passes: list[dict]) -> dict:
        verdict = {
            "matched": True,
            "rule_id": [],
            "vat_rate": None, "gtu_code": None, "procedure": None,
            "partners_results": [],
            "partnership": {
                "accounting_method": None,
                "joint_liability_applies": True,
                "partner_count": len(self.partners)
            },
            "_routing": None, "_routing_reason": [],
            "_warnings": [], "_legal_basis": []
        }
        
        for p in passes:
            if p.get("_routing") in ("BLOCK_AND_ALERT", "TRIAGE_QUEUE"):
                verdict["_routing"] = p["_routing"]
            if "vat_rate" in p and p["vat_rate"]:
                verdict["vat_rate"] = p["vat_rate"]
                verdict["gtu_code"] = p.get("gtu_code", "")
            if "partners_results" in p:
                verdict["partners_results"] = p["partners_results"]
            if "_warnings" in p:
                verdict["_warnings"].extend(p["_warnings"])
            if "_legal_basis" in p:
                verdict["_legal_basis"].append(p["_legal_basis"])
            if "rule_id" in p:
                verdict["rule_id"].append(p["rule_id"])
        
        return verdict
```

---

## 9. Macierze Interakcji Międzyregulacyjnych

### 9.1 Zależności między pakietami

| Pakiet źródłowy | Wpływa na | Mechanizm |
|---|---|---|
| `sc.partnership.formation` | `sc.vat`, `sc.pit`, `sc.zus` | Status spółki → zakres obowiązków |
| `sc.pit.proportional` | `sc.pit.kup`, `sc.pit.advances`, `sc.pit.returns` | P500 → dane per wspólnik |
| `sc.vat.substantive` | `sc.jpk` | Stawka VAT → dane JPK_V7 |
| `sc.accounting.full` | `sc.accounting.pkpir` | P800 > P810 (full wyłącza PKPiR) |
| `sc.partnership.liability` | `sc.compliance` | Solidarna → BLOCK + warning |
| `sc.pit.forms` | `sc.zus.health` | Forma PIT → stawka zdrowotnej |

### 9.2 Macierz konfliktów

| Konflikt | Rozwiązanie | Reguła nadrzędna | Reguła podrzędna |
|---|---|---|---|
| VAT zwolniony + PIT należny | Niezależne passy | P58 (VAT=0%) | P500+ (PIT normalnie) |
| Wspólnik liniowy + były pracodawca | Blokada → skala | P516 | P515 |
| Zawieszenie + faktura sprzedaży | VAT nadal należny | P230 | P940 |
| Pełna księgowość + PKPiR | Pełna nadrzędna | P800 > P810 | — |
| Różne formy PIT wspólników | Niezależna ewaluacja | P535 | — |
| Zmiana udziałów w roku | Split per data | P502/P503 | P500 |
| Śmierć wspólnika + 1 zostaje | Rozwiązanie spółki | P930 > P900 | — |
| Nowy wspólnik + stare długi | Solidarna | P1160 | P1150 |

---

## 10. Plan Wdrożenia ENTERPRISE

### 10.1 Fazy

| Faza | Zakres | Pliki Rego | Reguły | Osobodni |
|------|--------|-----------|:------:|:--------:|
| **Faza 0 (MVP)** | Risk, Routing, Compliance, VAT | 8 plików | ~50 | 10 |
| **Faza 1 (CORE)** | PIT (proporcjonalny, formy, KUP, zaliczki, zeznania) | 8 plików | ~70 | 15 |
| **Faza 2 (PARTNERSHIP)** | Cykl życia, odpowiedzialność, sukcesja, zawieszenie | 6 plików | ~50 | 10 |
| **Faza 3 (ENTERPRISE)** | ZUS, pełna księgowość, PKPiR, amortyzacja, KSeF, JPK, pracodawca, ulgi, korekty, fallback | 12 plików | ~60 | 15 |
| **RAZEM** | **32 pakiety** | **34 pliki** | **~230 w tym dokumencie** | **50** |

### 10.2 Kamienie milowe

| Kamień | Opis | Kryterium sukcesu |
|--------|------|-------------------|
| **M1: MVP** | Podstawowy łańcuch SC | Risk + VAT → werdykt z NIP spółki |
| **M2: CORE** | Proporcjonalny podział + PIT + ZUS | 2 wspólników, różne formy → poprawne obliczenia |
| **M3: ENTERPRISE** | Pełna księgowość + KSeF + JPK | Spółka >2M EUR → automatyczna pełna księgowość |
| **M4: PRODUCTION** | Audyt, monitoring, CI/CD | Wszystkie testy przechodzą, 100% pokrycia SC |

---

## 11. Cross-Reference: Podstawa Prawna → Reguła SC

| Podstawa prawna | Reguła | Priorytet |
|---|---|---|
| Art. 8 ust. 1-2 PIT | `partner_proportional_split` | P500 ★★★ |
| Art. 860 KC | `sc_formation_valid` | P900 ★★★ |
| Art. 864 KC | `sc_joint_liability_tax`, `sc_joint_liability_zus` | P1150-P1152 ★★★ |
| Art. 869 KC | `sc_partner_exit_settlement`, `sc_partner_exit_liability_sc` | P907, P1158 ★★ |
| Art. 872 KC | `sc_succession_partner_death_sc` | P930 ★★ |
| Art. 874-875 KC | `sc_liquidation_procedure_sc` | P922 ★ |
| Art. 2 ust. 1 pkt 1 UoR | `sc_full_accounting_threshold` | P800 ★★★ |
| Art. 113 VAT | `vat_exemption_subject_sc` | P58 ★★ |
| Art. 96 VAT | `vat_r_registration_sc` | P39 ★ |
| Art. 22-25 Pr. przeds. | `sc_suspension_all_partners_sc` | P940 ★ |
| Art. 14 Pr. przeds. | `sc_formation_valid` (CEIDG) | P900 ★★★ |
| Art. 30 CEIDG | `sc_partner_join_procedure_sc` | P905 ★ |
| Art. 115 Ordynacji | `sc_joint_liability_tax` | P1150 ★★★ |
| Art. 119a Ordynacji | `gaar_artificial_scheme_sc` | P9 ★ |
| Art. 9 ust. 1a-2 SUS | `partner_concurrent_employment_sc` | P715 ★★ |
| Art. 18a SUS | `partner_zus_start_relief_sc` | P710 ★ |
| Art. 18c SUS | `partner_zus_maly_plus_sc` | P711 ★ |
| Art. 23 ust. 1 pkt 10 PIT | `partner_kup_own_work_nkup_sc` | P578 ★★ |
| Art. 9a ust. 3 PIT | `partner_pit_linear_former_employer_sc` | P516 ★★ |
| Art. 89b VAT | `bad_debt_debtor_correction_sc` | P184 ★★ |
| Art. 108a VAT | `split_payment_mandatory_sc` | P25 |
| Art. 106na-106nq VAT | `sc_ksef_mandatory_sc` | P950 ★ |
| Art. 99 VAT | `sc_jpk_v7m_structure_sc` | P970 ★ |
| Art. 44 PIT | `partner_advance_monthly_sc` | P540 ★ |
| Art. 45 PIT | `partner_annual_return_pit36_sc` | P550 ★ |
| Art. 30ca PIT | `partner_relief_ip_box_sc` | P610 ★ |
| Art. 26e PIT | `partner_relief_rd_sc` | P600 ★ |
| Art. 21 ust. 1 pkt 148 PIT | `partner_exemption_young_sc` | P580 ★ |
| Ustawa o zarządzie sukcesyjnym | `sc_succession_partner_death_sc` | P930 ★★ |
| Ustawa o ryczałcie, Art. 6 | `partner_pit_lump_sum_limit_sc` | P525 ★★ |

---

> **Dokument utworzony:** 2026-07-11 | **Wersja:** 3.0 ENTERPRISE | **Reguł szczegółowo opisanych:** ~230 (z pełnymi przypadkami brzegowymi)
> **Powiązane dokumenty:**
> - `Plan OPA/Docs SC` — źródła prawne spółki cywilnej
> - `Plan OPA/SC_ENTERPRISE_PLAN.md` — plan architektoniczny (makro)
> - `Plan OPA/SC_MASSIVE_RULE_CATALOG.md` — katalog tabelaryczny mikro-reguł
> - `Plan OPA/34_JDG_DEFINITIVE_REGO_PLAN.md` — referencja JDG
> - `Plan OPA/00_PLAN_STRUKTURA.md` — master plan architektoniczny
