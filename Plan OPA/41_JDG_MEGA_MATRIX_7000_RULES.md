# 🏛️ NexusAI JDG — MEGA MATRIX: Definitywna Integracja ~7,000 Reguł ENTERPRISE

> **Status:** DEFINITIVE INTEGRATION MATRIX v1.0 — Dual-Layer Architecture, Mapowanie 550+ Artykułów  
> **Data:** 2026-07-12  
> **Autor:** Zespół NexusAI — Chief Architect  
> **Plik:** `Plan OPA/41_JDG_MEGA_MATRIX_7000_RULES.md`  
> **Bazuje na:** `31_JDG_3000_RULES.md` (dekompozycja ~3,055 reguł), `38c_JDG_CANONICAL_MAP.md` (**~779 reguł kanonicznych** — zintegrowane Docs 22-43), `28_JDG_ENTERPRISE_MASTER_SYNTHESIS.md` (~372 reguły), `39_JDG_COMPREHENSIVE_TEN_AREAS_EXPANSION.md` (~140 reguł), `40_JDG_DEEP_GAP_FINAL_FRONTIER.md` (20 reguł), `42_JDG_DEEP_GAP_DISCOVERY.md` (55 reguł), `43_JDG_KKS_MASSIVE_DECOMPOSITION.md` (230 reguł), `DocsJDG` (źródła prawne)  
> **Przeznaczenie:** DEFINITYWNY dokument integrujący wszystkie istniejące plany JDG w jedną spójną architekturę dual-layer, wyznaczający ścieżkę od obecnych **~779 reguł kanonicznych** do docelowych ~7,000 reguł mikro.

---

# 0. EXECUTIVE SUMMARY — Dlaczego Ten Dokument?

## 0.1 Problem

| Dokument | Liczba reguł | System ID | Status |
|----------|:-----------:|-----------|--------|
| `38c_JDG_CANONICAL_MAP.md` | 294 | P-ID, R-ID | ✅ Kanoniczne |
| `31_JDG_3000_RULES.md` | ~3,055 | `jdg.ustawa.artykul.regula` | ⚠️ NIEZINTEGROWANE |
| `39_JDG_COMPREHENSIVE_TEN_AREAS_EXPANSION.md` | ~140 | P-ID | ⚠️ Częściowo zintegrowane |
| `40_JDG_DEEP_GAP_FINAL_FRONTIER.md` | 20 | P-ID | ⚠️ Częściowo zintegrowane |

**Problem:** Dokument 31 zawiera masywną dekompozycję ~3,055 reguł na poziomie mikro (13 reguł na artykuł), ale używa innego systemu ID (`jdg.vat.a5.r1`) i NIE jest zintegrowany z mapą kanoniczną 38c. Użytkownik widzi "tylko ~140 reguł", podczas gdy w rzeczywistości istnieje już plan dla ponad 3,000.

**Rozwiązanie:** Ten dokument ustanawia **Dual-Layer Architecture** — dwuwarstwową architekturę, gdzie reguły Macro (P-ID, biznesowe/decyzyjne) agregują reguły Micro (`jdg.*`, prawne/walidacyjne). Każda reguła Macro jest "kontrolerem", który wywołuje zestaw 8-15 reguł Micro.

## 0.2 Dual-Layer Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    WARSTWA 1: MACRO (P-ID / R-ID)                    │
│                    ~450 reguł biznesowych/decyzyjnych                │
│                                                                     │
│  P58 ───► vat_exemption_subject_jdg                                │
│  P500 ──► pit_form_scale                                            │
│  P740 ──► zus_start_relief_jdg                                     │
│  ...                                                                │
│                                                                     │
│  Każda reguła Macro jest KONTROLEREM, który:                        │
│  1. Sprawdza warunki wejściowe                                      │
│  2. Wywołuje zestaw reguł Micro                                     │
│  3. Agreguje wyniki w pojedynczy werdykt                            │
└───────────────────────────┬─────────────────────────────────────────┘
                            │ depends_on
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    WARSTWA 2: MICRO (jdg.*)                         │
│                    ~7,000 reguł prawnych/walidacyjnych               │
│                                                                     │
│  jdg.vat.a113.r1 ───► limit_200k_check                             │
│  jdg.vat.a113.r2 ───► new_business_proportion                      │
│  jdg.vat.a113.r3 ───► vat_payer_status                             │
│  jdg.vat.a113.r4 ───► excluded_activities_check                     │
│  jdg.vat.a113.r5 ───► turnover_monitoring                          │
│  jdg.vat.a113.r6 ───► breach_mid_year_consequences                  │
│  jdg.vat.a113.r7 ───► re_registration_after_breach                  │
│  jdg.vat.a113.r8 ───► exemption_loss_year_end                       │
│  jdg.vat.a113.r9 ───► voluntary_resignation                         │
│  jdg.vat.a113.r10 ──► evidence_obligation_during_exemption           │
│                                                                     │
│  Każda reguła Micro jest ATOMOWA:                                   │
│  1. Jeden artykuł → 8-15 mikro-reguł                                │
│  2. Jedna mikro-reguła = jeden warunek logiczny                     │
│  3. Zwraca pojedynczy bool lub wartość                              │
└─────────────────────────────────────────────────────────────────────┘
```

## 0.3 Docelowa liczba reguł

| Ustawa | Artykułów relewantnych | Współczynnik | Cel: reguł Micro |
|--------|:----------------------:|:------------:|:----------------:|
| **Ustawa o VAT** | ~85 | 13.0× | **~1,105** |
| **Ustawa o PIT** | ~70 | 13.0× | **~910** |
| **Ordynacja podatkowa** | ~50 | 13.0× | **~650** |
| **Ustawa o SUS (ZUS)** | ~30 | 13.0× | **~390** |
| **Ustawa o ryczałcie** | ~25 | 13.0× | **~325** |
| **Ustawa zdrowotna** | ~10 | 13.0× | **~130** |
| **KKS** | ~40 | 12.0× | **~480** |
| **Prawo przedsiębiorców** | ~25 | 10.0× | **~250** |
| **Ustawa o CEIDG** | ~15 | 10.0× | **~150** |
| **Ustawa o zarządzie sukcesyjnym** | ~15 | 10.0× | **~150** |
| **Ustawa o rachunkowości (dla JDG)** | ~30 | 10.0× | **~300** |
| **PCC + podatki lokalne** | ~25 | 10.0× | **~250** |
| **KSeF + JPK (rozporządzenia)** | ~30 | 12.0× | **~360** |
| **Prawo dewizowe + AML** | ~15 | 10.0× | **~150** |
| **RODO** | ~10 | 8.0× | **~80** |
| **Prawo ochrony środowiska (BDO, SUP, CBAM)** | ~15 | 10.0× | **~150** |
| **Cross-border (dyrektywy UE, TP, CFC)** | ~20 | 10.0× | **~200** |
| **Pozostałe (akcyza, transport, budowlane)** | ~20 | 8.0× | **~160** |
| **Ustawa zasiłkowa (choroba, macierzyństwo)** | ~10 | 10.0× | **~100** |
| **Pozostałe (akcyza, transport, budowlane, prawo pracy)** | ~20 | 8.0× | **~160** |
| **RAZEM (core dekompozycja)** | **~540** | **~12.3×** | **~6,090** |
| **+ Edge cases, interakcje, walidacje** | — | — | **~910** |
| **GRAND TOTAL** | — | — | **~7,000** |

---

# CZĘŚĆ I: KOMPLETNA MAPA ARTYKUŁÓW → LICZBA REGUŁ

## 1.1 USTAWA O VAT (85 artykułów → ~1,105 reguł Micro)

| Zakres artykułów | Temat | Artykuły | Reguł | Status w 31 |
|:-----------------|:------|:--------:|:-----:|:-----------:|
| Art. 5-14 | Czynności opodatkowane | 10 | 130 | ✅ Zdekomponowane |
| Art. 15-18 | Podatnicy, rejestracja VAT-R | 6 | 78 | ✅ Zdekomponowane |
| Art. 19a-21 | Obowiązek podatkowy | 8 | 104 | ✅ Zdekomponowane |
| Art. 22-28 | Miejsce świadczenia | 7 | 91 | ⚠️ Częściowo |
| Art. 29a-32 | Podstawa opodatkowania | 6 | 78 | ✅ Zdekomponowane |
| Art. 41-42 | Stawki VAT | 6 | 78 | ✅ Zdekomponowane |
| Art. 43 | Zwolnienia przedmiotowe | 3 | 39 | ✅ Zdekomponowane |
| Art. 86-96 | Odliczenia VAT | 15 | 195 | ✅ Zdekomponowane |
| Art. 97-105 | Rejestracja, deklaracje | 9 | 117 | ⚠️ Częściowo |
| Art. 106a-106nq | Faktury, KSeF | 12 | 156 | ⚠️ Częściowo |
| Art. 108-113 | Split payment, zwolnienia, sankcje | 6 | 78 | ✅ Zdekomponowane |
| Art. 119-120 | Procedury szczególne | 5 | 65 | ⚠️ Częściowo |
| Art. 129-138 | Transakcje UE | 10 | 130 | ⚠️ Częściowo |
| **RAZEM VAT** | | **~85** | **~1,105** | **~70% pokryte** |

## 1.2 USTAWA O PIT (70 artykułów → ~910 reguł Micro)

| Zakres artykułów | Temat | Artykuły | Reguł | Status w 31 |
|:-----------------|:------|:--------:|:-----:|:-----------:|
| Art. 9-9a | Rok podatkowy, forma opodatkowania | 3 | 39 | ✅ Zdekomponowane |
| Art. 10-14 | Źródła przychodów, definicje | 8 | 104 | ✅ Zdekomponowane |
| Art. 14 ust. 2c-2e | Różnice kursowe | 3 | 39 | ✅ Zdekomponowane |
| Art. 21 | Zwolnienia przedmiotowe PIT | 2 | 26 | ✅ Zdekomponowane |
| Art. 22-23 | KUP i wyłączenia z KUP | 6 | 78 | ✅ Zdekomponowane |
| Art. 24 | Dochód i strata | 2 | 26 | ✅ Zdekomponowane |
| Art. 24a-24d | PKPiR, ewidencje | 5 | 65 | ⚠️ Częściowo |
| Art. 26-26h | Ulgi podatkowe | 12 | 156 | ✅ Zdekomponowane |
| Art. 27-27f | Skala podatkowa, ulga na dzieci | 8 | 104 | ✅ Zdekomponowane |
| Art. 30-30c | Podatek liniowy, ryczałt od kapitałów | 6 | 78 | ✅ Zdekomponowane |
| Art. 30ca | IP Box | 2 | 26 | ✅ Zdekomponowane |
| Art. 30da | Exit tax | 2 | 26 | ❌ Niezdekomponowane |
| Art. 30f | CFC | 3 | 39 | ❌ Niezdekomponowane |
| Art. 31-33 | Zaliczki na podatek | 5 | 65 | ✅ Zdekomponowane |
| Art. 44-45 | Zeznania roczne | 6 | 78 | ✅ Zdekomponowane |
| Art. 45a-45f | Informacje PIT-11, IFT | 5 | 65 | ❌ Niezdekomponowane |
| **RAZEM PIT** | | **~70** | **~910** | **~75% pokryte** |

## 1.3 ORDYNACJA PODATKOWA (50 artykułów → ~650 reguł Micro)

| Zakres artykułów | Temat | Artykuły | Reguł | Status w 31 |
|:-----------------|:------|:--------:|:-----:|:-----------:|
| Art. 16-16b | Czynny żal | 3 | 39 | ✅ Zdekomponowane |
| Art. 20-21 | Zaległość i nadpłata | 2 | 26 | ✅ Zdekomponowane |
| Art. 26-29 | Odpowiedzialność podatnika | 4 | 52 | ⚠️ Częściowo |
| Art. 47-52 | Odsetki za zwłokę | 6 | 78 | ✅ Zdekomponowane |
| Art. 53-57 | Opłata prolongacyjna, odsetki karne | 5 | 65 | ⚠️ Częściowo |
| Art. 67a-67e | Ulgi w spłacie | 5 | 65 | ✅ Zdekomponowane |
| Art. 70-71 | Przedawnienie | 5 | 65 | ✅ Zdekomponowane |
| Art. 72-80 | Nadpłata | 6 | 78 | ✅ Zdekomponowane |
| Art. 81-81c | Korekta deklaracji | 4 | 52 | ✅ Zdekomponowane |
| Art. 86 | Przechowywanie dokumentów | 2 | 26 | ✅ Zdekomponowane |
| Art. 87 | Zwrot nadpłaty | 2 | 26 | ✅ Zdekomponowane |
| Art. 119a | Klauzula GAAR | 3 | 39 | ✅ Zdekomponowane |
| Art. 120-129 | Postępowanie podatkowe | 8 | 104 | ⚠️ Częściowo |
| Art. 138a-138o | Pełnomocnictwa | 6 | 78 | ✅ Zdekomponowane |
| Art. 193a | JPK na żądanie | 2 | 26 | ✅ Zdekomponowane |
| **RAZEM Ordynacja** | | **~50** | **~650** | **~80% pokryte** |

## 1.4 USTAWA O SUS — ZUS (30 artykułów → ~390 reguł Micro)

| Zakres artykułów | Temat | Artykuły | Reguł | Status w 31 |
|:-----------------|:------|:--------:|:-----:|:-----------:|
| Art. 6-6b | Podmioty podlegające ubezpieczeniom | 5 | 65 | ✅ Zdekomponowane |
| Art. 9 | Zbieg ubezpieczeń | 3 | 39 | ✅ Zdekomponowane |
| Art. 11-14 | Dobrowolność ubezpieczeń | 5 | 65 | ✅ Zdekomponowane |
| Art. 18-19 | Podstawy wymiaru składek | 5 | 65 | ✅ Zdekomponowane |
| Art. 18a | Ulga na start / preferencyjny ZUS | 3 | 39 | ✅ Zdekomponowane |
| Art. 18c | Mały ZUS Plus | 3 | 39 | ✅ Zdekomponowane |
| Art. 22 | Stopy procentowe składek | 3 | 39 | ✅ Zdekomponowane |
| Art. 24 | Przedawnienie składek | 2 | 26 | ✅ Zdekomponowane |
| Art. 36 | Terminy płatności | 2 | 26 | ✅ Zdekomponowane |
| Art. 47 | Obowiązek opłacania składek | 2 | 26 | ✅ Zdekomponowane |
| **RAZEM SUS** | | **~30** | **~390** | **~90% pokryte** |

## 1.5 KKS — KODEKS KARNY SKARBOWY (40 artykułów → ~480 reguł Micro)

| Zakres artykułów | Temat | Artykuły | Reguł | Status w 31 |
|:-----------------|:------|:--------:|:-----:|:-----------:|
| Art. 54-61 | Przestępstwa skarbowe (uchylanie się, nierzetelne księgi) | 10 | 130 | ❌ Niezdekomponowane |
| Art. 62-76 | Fałszerstwa faktur, oszustwa VAT | 15 | 195 | ❌ Niezdekomponowane |
| Art. 77-83 | Wykroczenia skarbowe (terminy, deklaracje) | 10 | 130 | ❌ Niezdekomponowane |
| Art. 16-16b | Czynny żal (KKS) | 3 | 39 | ⚠️ Częściowo |
| Art. 20-21 | Przedawnienie karalności | 2 | 26 | ❌ Niezdekomponowane |
| **RAZEM KKS** | | **~40** | **~480** | **~5% pokryte** |

## 1.6 POZOSTAŁE USTAWY (łącznie ~265 artykułów → ~2,555 reguł)

| Ustawa | Artykułów | Reguł | Status w 31 |
|:-------|:--------:|:-----:|:-----------:|
| Ustawa o ryczałcie ewidencjonowanym | 25 | 325 | ✅ Zdekomponowane |
| Ustawa o świadczeniach opieki zdrowotnej (składka zdrowotna) | 10 | 130 | ✅ Zdekomponowane |
| Ustawa zasiłkowa (choroba, macierzyństwo) ★ | 10 | 100 | ❌ Niezdekomponowane |
| Prawo przedsiębiorców | 25 | 250 | ⚠️ Częściowo |
| Ustawa o CEIDG | 15 | 150 | ✅ Zdekomponowane |
| Ustawa o zarządzie sukcesyjnym | 15 | 150 | ⚠️ Częściowo |
| Ustawa o rachunkowości (dla JDG) | 30 | 300 | ⚠️ Częściowo |
| PCC + podatki lokalne | 25 | 250 | ⚠️ Częściowo |
| KSeF + JPK (ustawy + rozporządzenia) | 30 | 360 | ⚠️ Częściowo |
| Prawo dewizowe + AML | 15 | 150 | ❌ Niezdekomponowane |
| RODO (dla JDG jako administratora) | 10 | 80 | ❌ Niezdekomponowane |
| Ochrona środowiska (BDO, SUP, CBAM) | 15 | 150 | ❌ Niezdekomponowane |
| Cross-border (dyrektywy UE, TP, CFC/exit) | 20 | 200 | ⚠️ Częściowo |
| Pozostałe (akcyza, transport, budowlane, prawo pracy) | 20 | 160 | ❌ Niezdekomponowane |
| **RAZEM POZOSTAŁE** | **~265** | **~2,555** | **~35% pokryte** |

> ⚠️ **Uwaga:** Suma wszystkich reguł z Części I (1.1-1.6) = 1,105 + 910 + 650 + 390 + 480 + 2,555 = **~6,090** — co jest spójne z taksonomią w Części IV.

---

# CZĘŚĆ II: MACIERZ PRZYPISAŃ MACRO → MICRO

Poniżej mapowanie wszystkich 294 reguł kanonicznych (38c) na odpowiadające grupy reguł Micro z dokumentu 31.

## 2.1 Grupa 1: Risk & Fraud (P0-P9) → Micro

| P-ID | Nazwa Macro | Zestaw Micro (z Doc 31) | Liczba Micro |
|:----:|-------------|:------------------------|:------------:|
| P0 | `fraud_graph_match` | `jdg.kks.a54.r1-r8`, `jdg.kks.a62.r1-r6` | 14 |
| P0_b | `kks_empty_invoice_fraud` | `jdg.kks.a62.r7-r15`, `jdg.vat.a108.r1-r5` | 18 |
| P1 | `counterparty_trust_low` | `jdg.ord.a119a.r1-r3`, walidacja zewnętrzna | 3 |
| P2 | `anomaly_amount` | `jdg.ord.a22.r1-r4` (UoR — zasada ostrożności) | 4 |
| P4 | `kks_hidden_income_flag` | `jdg.kks.a54.r1-r10` | 10 |
| P5 | `semantic_guard_disallowed` | `jdg.pit.a23.r1-r12` (katalog NKUP) | 12 |
| P6 | `kks_unreliable_books` | `jdg.kks.a56.r1-r8` | 8 |
| P6_b | `kks_declaration_overdue` | `jdg.kks.a77.r1-r6` | 6 |
| P7 | `kks_vat_evidence_gap` | `jdg.kks.a57.r1-r7` | 7 |
| P8 | `ceidg_vendor_suspended` | `jdg.ceidg.a5.r1-r5`, `jdg.pp.a22.r1-r4` | 9 |
| P9 | `gaar_artificial_scheme` | `jdg.ord.a119a.r1-r10` | 10 |
| **RAZEM Risk** | **11 Macro** | | **~101 Micro** |

## 2.2 Grupa 2: Routing & Field Confidence (P10-P19)

| P-ID | Nazwa Macro | Zestaw Micro | Liczba Micro |
|:----:|-------------|:------------|:------------:|
| P10-P19 | Routing confidence | `jdg.validate.*` (dedykowany pakiet walidacji) | ~40 |

## 2.3 Grupa 3: Compliance (P20-P39, P140-P157)

| P-ID | Nazwa Macro | Zestaw Micro | Liczba Micro |
|:----:|-------------|:------------|:------------:|
| P20 | `whitelist_missing_over_limit` | `jdg.vat.a96b.r1-r8` | 8 |
| P21 | `whitelist_account_mismatch` | `jdg.ord.a117ba.r1-r6` | 6 |
| P25 | `split_payment_mandatory` | `jdg.vat.a108a.r1-r10` | 10 |
| P35 | `cash_transaction_over_limit` | `jdg.pit.a22p.r1-r6` | 6 |
| P36 | `vat_simplified_receipt` | `jdg.vat.a106e.r1-r5` | 5 |
| P39 | `vat_r_registration_status` | `jdg.vat.a96.r1-r11` | 11 |
| **RAZEM Compliance** | **6 Macro** | | **~46 Micro** |

## 2.4 Grupa 4: Crossborder (P40-P49)

| P-ID | Nazwa Macro | Zestaw Micro | Liczba Micro |
|:----:|-------------|:------------|:------------:|
| P40-P49 | Crossborder pełny zestaw | `jdg.vat.a17.r1-r12`, `jdg.vat.a42.r1-r10`, `jdg.vat.a135.r1-r8` | ~80 |

## 2.5 Grupa 5: VAT — Stawki i zwolnienia (P50-P69)

| P-ID | Nazwa Macro | Zestaw Micro | Liczba Micro |
|:----:|-------------|:------------|:------------:|
| P50 | `vat_margin_scheme` | `jdg.vat.a120.r1-r15` | 15 |
| P52 | `vat_rate_fuel_pl` | `jdg.vat.a41.r1` (paliwo 23%) + `jdg.vat.a65.gtu04.r1-r3` (GTU_04 paliwa) | 4 |
| P53 | `vat_rate_food_pl` | `jdg.vat.a41.r16-r35` (stawki obniżone) | 20 |
| P55 | `vat_exemption_education` | `jdg.vat.a43.r6-r8` | 3 |
| P56 | `vat_exemption_healthcare` | `jdg.vat.a43.r1-r5` | 5 |
| **P58** | **`vat_exemption_subject_jdg`** 🔑 | **`jdg.vat.a113.r1-r10`** (limit 200k, proporcja, przekroczenie, rezygnacja) + **`jdg.vat.a113.r11-r18`** (edge cases: nowa firma, wznowienie, korekta) | **18** |
| P60 | `vat_bad_debt_relief` | `jdg.vat.a89a.r1-r10` (wierzyciel) + `jdg.vat.a89b.r1-r10` (dłużnik) | 20 |
| P65 | `gtu_mapping_by_category` | `jdg.vat.gtu.r1-r13` (kody GTU_01-GTU_13) | 13 |
| **RAZEM VAT stawki** | **9 Macro** | | **~124 Micro** |

## 2.6 Grupa 6: PIT — Formy opodatkowania (P500-P539)

| P-ID | Nazwa Macro | Zestaw Micro | Liczba Micro |
|:----:|-------------|:------------|:------------:|
| P500 | `pit_form_scale` | `jdg.pit.a27.r1-r15` (skala 12/32, kwota wolna, wspólne rozliczenie) | 15 |
| P501 | `pit_scale_bracket_determination` | `jdg.pit.a27.r1-r5` (ustalenie progu) | 5 |
| P502 | `pit_scale_joint_filing` | `jdg.pit.a6.r1-r5` (wspólne rozliczenie) | 5 |
| P510 | `pit_form_linear` | `jdg.pit.a30c.r1-r10` (podatek liniowy 19%) | 10 |
| P520 | `pit_form_lump_sum` | `jdg.ryczalt.a6.r1-r8`, `jdg.ryczalt.a12.r1-r10` | 18 |
| P530 | `pit_form_tax_card` | `jdg.ryczalt.a21.r1-r10`, `jdg.ryczalt.a27.r1-r6` | 16 |
| **RAZEM PIT formy** | **6 Macro** | | **~69 Micro** |

## 2.7 Grupa 7: PIT — KUP (P560-P589)

| P-ID | Nazwa Macro | Zestaw Micro | Liczba Micro |
|:----:|-------------|:------------|:------------:|
| P560 | `kup_full_deductible` | `jdg.pit.a22.r1-r15` (definicja KUP) | 15 |
| P566 | `kup_representation_none` | `jdg.pit.a23.r1-r4` (wyłączenia — reprezentacja) | 4 |
| P562 | `kup_private_mixed_jdg` | `jdg.pit.a23.r46-r50` (wydatki mieszane) | 5 |
| P564 | `kup_car_over_150k_limit` | `jdg.pit.a23.r47a.r1-r8` | 8 |
| **RAZEM PIT KUP** | **4 Macro** | | **~32 Micro** |

## 2.8 Grupa 8: Ulgi podatkowe (P600-P635)

| P-ID | Nazwa Macro | Zestaw Micro | Liczba Micro |
|:----:|-------------|:------------|:------------:|
| P600 | `relief_rd_jdg` | `jdg.pit.a26e.r1-r15` | 15 |
| P610 | `relief_ip_box_jdg` | `jdg.pit.a30ca.r1-r10` | 10 |
| P623 | `relief_thermo_jdg` | `jdg.pit.a26h.r1-r6` | 6 |
| P620 | `relief_rehabilitation` | `jdg.pit.a26.r2-r5`, `r20-r24` | 9 |
| P622 | `relief_child_tax_credit` | `jdg.pit.a27f.r1-r10` | 10 |
| P615 | `loss_carry_forward_jdg` | `jdg.pit.a9.r1-r8` | 8 |
| **RAZEM Ulgi** | **6 Macro** | | **~58 Micro** |

## 2.9 Grupa 9: ZUS (P700-P770)

| P-ID | Nazwa Macro | Zestaw Micro | Liczba Micro |
|:----:|-------------|:------------|:------------:|
| P700 | `zus_social_standard_jdg` | `jdg.sus.a18.r1-r10`, `jdg.sus.a22.r1-r6` | 16 |
| P701 | `zus_sickness_voluntary_jdg` | `jdg.sus.a11.r1-r6` | 6 |
| P720 | `zus_health_scale_jdg` | `jdg.zdrowotna.a81.r1-r8` (9%) | 8 |
| P722 | `zus_health_linear_jdg` | `jdg.zdrowotna.a81.r9-r15` (4.9%) | 7 |
| P724 | `zus_health_lump_sum_jdg` | `jdg.zdrowotna.a81.r16-r24` (progi) | 9 |
| P740 | `zus_start_relief_jdg` | `jdg.sus.a18a.r1-r8` | 8 |
| P741 | `zus_maly_plus_jdg` | `jdg.sus.a18c.r1-r10` | 10 |
| P742 | `zus_preferential_jdg` | `jdg.sus.a18a.r9-r15` | 7 |
| **RAZEM ZUS** | **8 Macro** | | **~71 Micro** |

## 2.10 Grupa 10: Cykl życia JDG (P900-P939)

| P-ID | Nazwa Macro | Zestaw Micro | Liczba Micro |
|:----:|-------------|:------------|:------------:|
| P900 | `ceidg_registration_check` | `jdg.ceidg.a5.r1-r8` | 8 |
| P910 | `business_suspension_valid` | `jdg.pp.a22.r1-r8`, `jdg.pp.a23.r1-r5`, `jdg.pp.a25.r1-r4` | 17 |
| P920 | `succession_continuity` | `jdg.sukcesja.a3.r1-r5`, `jdg.sukcesja.a12.r1-r4`, `jdg.sukcesja.a14.r1-r3` | 12 |
| P930 | `unregistered_activity_limit` | `jdg.pp.a5.r1-r6` | 6 |
| **RAZEM Cykl życia** | **4 Macro** | | **~43 Micro** |

## 2.11 Grupa 11: KSeF i JPK (P950-P989)

| P-ID | Nazwa Macro | Zestaw Micro | Liczba Micro |
|:----:|-------------|:------------|:------------:|
| P950 | `ksef_structured_mandatory_jdg` | `jdg.vat.a106na.r1-r10`, `jdg.vat.a106ne.r1-r5` | 15 |
| P970 | `jpk_v7m_structure_jdg` | `jdg.vat.a99.r1-r10` | 10 |
| P980 | `jpk_pkpir_structure_jdg` | `jdg.ord.a193a.r1-r6` | 6 |
| **RAZEM KSeF/JPK** | **3 Macro** | | **~31 Micro** |

---

# CZĘŚĆ III: METODOLOGIA DEKOMPOZYCJI — ZASADY

## 3.1 Schemat dekompozycji artykułu na mikro-reguły

Każdy artykuł prawny jest dekomponowany na 8-15 mikro-reguł wg poniższego schematu:

| # | Typ mikro-reguły | Opis | Przykład dla Art. 113 VAT |
|:--:|:----------------|:-----|:---------------------------|
| 1 | **Główna** (czy artykuł ma zastosowanie) | Podstawowy warunek: czy JDG w ogóle może być objęty tym przepisem? | `jdg.vat.a113.r1`: Czy JDG jest podatnikiem VAT? |
| 2 | **Pozytywna 1** (pierwszy warunek TAK) | Pierwszy warunek pozytywny | `jdg.vat.a113.r2`: Czy obrót roczny ≤ 200 000 PLN? |
| 3 | **Pozytywna 2** (drugi warunek TAK) | Drugi warunek pozytywny | `jdg.vat.a113.r3`: Czy JDG nie wykonuje czynności wyłączonych? |
| 4 | **Pozytywna 3** (dodatkowy warunek TAK) | Trzeci warunek pozytywny | `jdg.vat.a113.r4`: Czy JDG rozpoczął działalność w trakcie roku? (proporcja) |
| 5 | **Negatywna 1** (kiedy NIE) | Wyłączenie podmiotowe | `jdg.vat.a113.r5`: Czy JDG handluje towarami wyłączonymi (stal, paliwo, elektronika)? |
| 6 | **Negatywna 2** (kiedy NIE) | Drugie wyłączenie | `jdg.vat.a113.r6`: Czy JDG świadczy usługi wyłączone (doradztwo, prawnicze)? |
| 7 | **Wyjątek 1** (szczególna sytuacja) | Wyjątek od wyjątku | `jdg.vat.a113.r7`: Czy JDG utracił zwolnienie w trakcie roku? |
| 8 | **Wyjątek 2** | Drugi wyjątek | `jdg.vat.a113.r8`: Czy JDG może ponownie skorzystać ze zwolnienia? |
| 9 | **Interakcja 1** (zależność od innych artykułów) | Powiązanie z VAT-R | `jdg.vat.a113.r9`: Czy JDG złożył VAT-R przy rezygnacji ze zwolnienia? |
| 10 | **Interakcja 2** | Powiązanie z JPK | `jdg.vat.a113.r10`: Czy JDG składa JPK_V7 mimo zwolnienia? (NIE) |
| 11 | **Termin/procedura** | Deadline, formalność | `jdg.vat.a113.r11`: Termin na zgłoszenie przekroczenia limitu (7 dni) |
| 12 | **Sankcja** | Konsekwencje naruszenia | `jdg.vat.a113.r12`: Sankcja za brak zgłoszenia przekroczenia |
| 13 | **Edge case 1** | Nietypowa sytuacja | `jdg.vat.a113.r13`: Powrót do zwolnienia po >1 roku bycia czynnym VAT |
| 14 | **Edge case 2** | Druga nietypowa sytuacja | `jdg.vat.a113.r14`: Zwolnienie a import towarów |

## 3.2 Konwencja ID dla reguł Micro

```
jdg.<ustawa>.<artykul>[.<ustęp>].<typ_reguly><numer>
```

Gdzie:
- `<ustawa>`: `vat`, `pit`, `ord`, `sus`, `kks`, `pp`, `ceidg`, `ryczalt`, `zdrowotna`, `sukcesja`, `uor`, `pcc`, `rodo`, `aml`, `srodowisko`, `transport`
- `<artykul>`: numer artykułu (np. `a113`)
- `[.<ustęp>]`: opcjonalnie numer ustępu (np. `a113.u1`)
- `<typ_reguly>`: `r` (reguła) lub `w` (walidacja) lub `e` (edge case)
- `<numer>`: kolejny numer w ramach artykułu

Przykłady:
- `jdg.vat.a113.r1` — VAT Art. 113, reguła 1 (czy JDG jest podatnikiem VAT?)
- `jdg.pit.a26e.u2.r3` — PIT Art. 26e ust. 2, reguła 3 (koszty kwalifikowane B+R — sprzęt)
- `jdg.kks.a62.r7` — KKS Art. 62, reguła 7 (fałszerstwo faktury — znamiona)

## 3.3 Format każdej reguły Micro

Każda reguła Micro w dokumentacji zawiera:

```markdown
### jdg.vat.a113.r1: `vat_subject_exemption_eligibility_check`

- **Warunek:** `input.jdg_entrepreneur.is_vat_payer == false OR input.jdg_entrepreneur.vat_status == "EXEMPT"`
- **Rezultat:** `bool` — true jeśli JDG może być objęty zwolnieniem podmiotowym
- **Podstawa:** Art. 113 ust. 1 VAT
- **Edge cases:** (a) nowa JDG (b) JDG po wznowieniu
- **Zależności:** Wywoływana przez P58 `vat_exemption_subject_jdg`
- **Przykład +:** JDG z obrotem 150k PLN → `true`
- **Przykład −:** JDG z obrotem 250k PLN → `false`
```

---

# CZĘŚĆ IV: KOMPLETNA TAKSONOMIA — 7,000 REGUŁ

Poniżej KOMPLETNA taksonomia wszystkich ~7,000 reguł w podziale na ustawy, działy i artykuły. Każdy wpis zawiera liczbę reguł Micro.

## 4.1 USTAWA O VAT — 1,105 reguł Micro

```
jdg.vat.* (1,105 reguł)
├── jdg.vat.a5 (10r) — Czynności opodatkowane
├── jdg.vat.a7 (12r) — Dostawa towarów
├── jdg.vat.a8 (12r) — Świadczenie usług
├── jdg.vat.a15 (4r) — Podatnicy
├── jdg.vat.a17 (12r) — Reverse charge (odwrotne obciążenie)
├── jdg.vat.a19a (15r) — Obowiązek podatkowy — zasada ogólna
├── jdg.vat.a20 (10r) — Obowiązek podatkowy — WNT
├── jdg.vat.a21 (10r) — Metoda kasowa VAT
├── jdg.vat.a28a-28m (20r) — Miejsce świadczenia usług
├── jdg.vat.a29a (15r) — Podstawa opodatkowania
├── jdg.vat.a41 (50r) — Stawki VAT
├── jdg.vat.a42 (10r) — Stawka 0% — WDT
├── jdg.vat.a43 (40r) — Zwolnienia przedmiotowe
├── jdg.vat.a86 (20r) — Prawo do odliczenia
├── jdg.vat.a86a (10r) — VAT od samochodów
├── jdg.vat.a87 (10r) — Terminy zwrotu VAT
├── jdg.vat.a88 (15r) — Wyłączenia z odliczenia
├── jdg.vat.a89a (10r) — Złe długi — wierzyciel
├── jdg.vat.a89b (10r) — Złe długi — dłużnik
├── jdg.vat.a96 (11r) — Rejestracja VAT-R
├── jdg.vat.a96b (8r) — Biała Lista VAT
├── jdg.vat.a97 (8r) — VAT-UE rejestracja
├── jdg.vat.a99 (10r) — Deklaracje VAT
├── jdg.vat.a100 (5r) — VAT-UE informacje podsumowujące
├── jdg.vat.a103 (5r) — Terminy płatności VAT
├── jdg.vat.a106a-106e (15r) — Faktury — wymogi formalne
├── jdg.vat.a106f-106k (10r) — Faktury korygujące
├── jdg.vat.a106na-106nq (20r) — KSeF
├── jdg.vat.a108 (10r) — Split payment
├── jdg.vat.a108a-108f (5r) — MPP — sankcje
├── jdg.vat.a109 (8r) — Ewidencja VAT
├── jdg.vat.a113 (18r) — Zwolnienie podmiotowe 200k ★
├── jdg.vat.a119 (5r) — Faktury zaliczkowe — zasady
├── jdg.vat.a120 (15r) — Procedura marży
├── jdg.vat.a129-138 (20r) — Transakcje UE (WDT, WNT, trójstronne, OSS)
```

## 4.2 USTAWA O PIT — 910 reguł Micro

```
jdg.pit.* (910 reguł)
├── jdg.pit.a6 (8r) — Wspólne rozliczenie małżonków
├── jdg.pit.a9 (8r) — Strata podatkowa
├── jdg.pit.a9a (10r) — Wybór formy opodatkowania
├── jdg.pit.a10 (10r) — Źródła przychodów
├── jdg.pit.a14 (20r) — Przychody z działalności gospodarczej
├── jdg.pit.a14c (10r) — Różnice kursowe
├── jdg.pit.a21.u1.p148 (8r) — Ulga dla młodych
├── jdg.pit.a21.u1.p152 (6r) — Ulga na powrót
├── jdg.pit.a21.u1.p153 (5r) — Ulga dla rodzin 4+
├── jdg.pit.a21.u1.p154 (5r) — Ulga dla pracujących emerytów
├── jdg.pit.a22 (15r) — KUP — definicja ogólna
├── jdg.pit.a22a-22m (40r) — Amortyzacja
├── jdg.pit.a22p (6r) — Limit płatności gotówkowych
├── jdg.pit.a23 (30r) — Wyłączenia z KUP
├── jdg.pit.a24 (15r) — Dochód i strata
├── jdg.pit.a24a (8r) — Obowiązek PKPiR
├── jdg.pit.a26 (25r) — Ulgi odliczane od dochodu
├── jdg.pit.a26e (15r) — Ulga B+R
├── jdg.pit.a26eb (5r) — Ulga na prototyp
├── jdg.pit.a26ec (6r) — Ulga na ekspansję
├── jdg.pit.a26gb (6r) — Ulga na robotyzację
├── jdg.pit.a26h (6r) — Ulga termomodernizacyjna
├── jdg.pit.a27 (15r) — Skala podatkowa 12%/32%
├── jdg.pit.a27f (10r) — Ulga na dzieci
├── jdg.pit.a30 (10r) — Ryczałt od kapitałów
├── jdg.pit.a30a (10r) — Dochody kapitałowe
├── jdg.pit.a30b (10r) — Sprzedaż nieruchomości
├── jdg.pit.a30c (10r) — Podatek liniowy 19%
├── jdg.pit.a30ca (10r) — IP Box 5%
├── jdg.pit.a30da (10r) — Exit tax ★ NOWE
├── jdg.pit.a30f (15r) — CFC ★ NOWE
├── jdg.pit.a31 (25r) — Zaliczki na podatek
├── jdg.pit.a32 (10r) — Zaliczki — ryczałt
├── jdg.pit.a33 (5r) — Zaliczki — karta podatkowa
├── jdg.pit.a44 (10r) — Zaliczki uproszczone
├── jdg.pit.a45 (15r) — Zeznania roczne (PIT-36, PIT-36L, PIT-28)
├── jdg.pit.a45a-45f (25r) — Informacje PIT-11, IFT, PIT-R ★ NOWE
```

## 4.3 ORDYNACJA PODATKOWA — 650 reguł Micro

```
jdg.ord.* (650 reguł)
├── jdg.ord.a16 (6r) — Czynny żal
├── jdg.ord.a20 (5r) — Zaległość podatkowa
├── jdg.ord.a21 (5r) — Nadpłata
├── jdg.ord.a26 (8r) — Odpowiedzialność podatnika
├── jdg.ord.a27 (6r) — Odpowiedzialność małżonka
├── jdg.ord.a28 (5r) — Odpowiedzialność rozwiedzionego małżonka
├── jdg.ord.a29 (8r) — Podatnicy, płatnicy, inkasenci
├── jdg.ord.a32 (5r) — Obowiązek składania deklaracji
├── jdg.ord.a33 (5r) — Obowiązek zapłaty podatku
├── jdg.ord.a47 (8r) — Odsetki za zwłokę — stawka
├── jdg.ord.a48 (5r) — Odsetki — opłata prolongacyjna
├── jdg.ord.a51 (5r) — Umorzenie odsetek
├── jdg.ord.a52 (5r) — Kolejność zaliczania wpłat
├── jdg.ord.a53 (5r) — Odsetki — zasady ogólne
├── jdg.ord.a54 (5r) — Odsetki — minimalna kwota
├── jdg.ord.a56 (5r) — Odsetki — stawka podstawowa
├── jdg.ord.a56b (5r) — Odsetki karne 150%
├── jdg.ord.a67a (5r) — Ulgi w spłacie — rodzaje
├── jdg.ord.a67b (8r) — Odroczenie / raty
├── jdg.ord.a67c (5r) — Ulgi automatyczne (klęski)
├── jdg.ord.a67d (5r) — Zabezpieczenie przy ulgach
├── jdg.ord.a67e (5r) — Odwołanie ulgi
├── jdg.ord.a70 (15r) — Przedawnienie zobowiązań ★★★
├── jdg.ord.a71 (10r) — Przerwanie i zawieszenie przedawnienia ★★★
├── jdg.ord.a72 (8r) — Nadpłata — definicja
├── jdg.ord.a73 (5r) — Nadpłata — zaliczenie
├── jdg.ord.a74 (5r) — Nadpłata — wniosek o zwrot
├── jdg.ord.a75 (5r) — Nadpłata po przedawnieniu
├── jdg.ord.a76 (5r) — Nadpłata — minimum 5 PLN
├── jdg.ord.a77 (5r) — Nadpłata — dziedziczenie
├── jdg.ord.a78 (5r) — Nadpłata — termin korekty
├── jdg.ord.a79 (5r) — Nadpłata — korekta przed/po kontroli
├── jdg.ord.a80 (5r) — Nadpłata — waluta obca
├── jdg.ord.a81 (10r) — Korekta deklaracji
├── jdg.ord.a81b (5r) — Korekta w trakcie kontroli
├── jdg.ord.a86 (8r) — Przechowywanie dokumentów
├── jdg.ord.a87 (5r) — Zwrot nadpłaty — 45 dni
├── jdg.ord.a119a (10r) — Klauzula GAAR ★★★
├── jdg.ord.a120 (5r) — Postępowanie — wszczęcie
├── jdg.ord.a121 (5r) — Postępowanie — strona
├── jdg.ord.a122 (5r) — Postępowanie — pełnomocnik
├── jdg.ord.a123 (5r) — Postępowanie — dowody
├── jdg.ord.a124 (5r) — Postępowanie — terminy
├── jdg.ord.a125 (5r) — Postępowanie — decyzja
├── jdg.ord.a126 (5r) — Postępowanie — odwołanie
├── jdg.ord.a127 (5r) — Postępowanie — skarga do WSA
├── jdg.ord.a138a-138o (30r) — Pełnomocnictwa podatkowe
├── jdg.ord.a193a (10r) — JPK na żądanie
```

## 4.4 KKS — 480 reguł Micro ★ NOWY MASYWNY BLOK

```
jdg.kks.* (480 reguł) ★★★ KRYTYCZNE — OBECNIE ~5% POKRYCIA
├── jdg.kks.a16 (10r) — Czynny żal — warunki formalne
├── jdg.kks.a20 (5r) — Przedawnienie karalności — przestępstwa
├── jdg.kks.a21 (5r) — Przedawnienie karalności — wykroczenia
├── jdg.kks.a54 (15r) — Uchylanie się od opodatkowania ★★★
├── jdg.kks.a55 (10r) — Oszustwo podatkowe
├── jdg.kks.a56 (12r) — Nierzetelne księgi / PKPiR ★★★
├── jdg.kks.a57 (10r) — Nierzetelna ewidencja VAT ★★★
├── jdg.kks.a58 (8r) — Oszustwo w zakresie faktur
├── jdg.kks.a59 (8r) — Fałszowanie dokumentów
├── jdg.kks.a60 (10r) — Przekroczenie uprawnień
├── jdg.kks.a61 (8r) — Narażenie na uszczuplenie
├── jdg.kks.a62 (15r) — Puste faktury / fałszerstwo faktur ★★★
├── jdg.kks.a63 (8r) — Niewystawienie faktury
├── jdg.kks.a64 (8r) — Niewłaściwa stawka VAT
├── jdg.kks.a65 (8r) — Zawyżenie zwrotu VAT
├── jdg.kks.a66 (8r) — Nierzetelne zeznanie
├── jdg.kks.a67 (8r) — Nieprowadzenie ksiąg
├── jdg.kks.a68 (8r) — Zniszczenie dokumentów
├── jdg.kks.a69 (8r) — Utrudnianie kontroli
├── jdg.kks.a70 (8r) — Nieskładanie deklaracji
├── jdg.kks.a71 (8r) — Naruszenie obowiązków płatniczych
├── jdg.kks.a72 (8r) — Niepobranie podatku
├── jdg.kks.a73 (8r) — Niewpłacenie podatku
├── jdg.kks.a74 (8r) — Naruszenie obowiązków ewidencyjnych
├── jdg.kks.a75 (8r) — Naruszenie obowiązków w zakresie KSeF ★
├── jdg.kks.a76 (8r) — Naruszenie obowiązków w zakresie JPK ★
├── jdg.kks.a77 (10r) — Niezłożenie deklaracji w terminie ★★★
├── jdg.kks.a78 (8r) — Nieprawidłowe dane w deklaracji
├── jdg.kks.a79 (8r) — Niezapłacenie podatku w terminie
├── jdg.kks.a80 (10r) — Sankcje — grzywny, kara pozbawienia wolności
├── jdg.kks.a81 (8r) — Nadzwyczajne złagodzenie kary
├── jdg.kks.a82 (8r) — Odstąpienie od wymierzenia kary
├── jdg.kks.a83 (8r) — Przepadek przedmiotów / korzyści
```

## 4.5 POZOSTAŁE USTAWY — 2,555 reguł Micro

```
jdg.sus.* (390 reguł) — Ustawa o systemie ubezpieczeń społecznych
jdg.ryczalt.* (325 reguł) — Ustawa o ryczałcie ewidencjonowanym
jdg.zdrowotna.* (130 reguł) — Ustawa o świadczeniach opieki zdrowotnej
jdg.zasilkowa.* (100 reguł) — Ustawa o świadczeniach pieniężnych (choroba, macierzyństwo) ★
jdg.pp.* (250 reguł) — Prawo przedsiębiorców
jdg.ceidg.* (150 reguł) — Ustawa o CEIDG
jdg.sukcesja.* (150 reguł) — Ustawa o zarządzie sukcesyjnym
jdg.uor.* (300 reguł) — Ustawa o rachunkowości
jdg.pcc.* (150 reguł) — PCC + podatki lokalne
jdg.ksef.* (200 reguł) — KSeF (ustawa + rozporządzenia)
jdg.jpk.* (160 reguł) — JPK (rozporządzenia)
jdg.aml.* (150 reguł) — Prawo dewizowe + AML
jdg.rodo.* (80 reguł) — RODO dla JDG
jdg.srodowisko.* (150 reguł) — BDO, SUP, CBAM
jdg.crossborder.* (200 reguł) — TP, CFC, Exit Tax, dyrektywy UE
jdg.transport.* (80 reguł) — Transport drogowy, Pakiet Mobilności ★
jdg.budownictwo.* (50 reguł) — Prawo budowlane, reverse charge ★
jdg.akcyza.* (30 reguł) — Akcyza dla JDG ★
```

> 💡 **Poprawka:** Sekcja `specjalistyczne` rozbita na trzy osobne pakiety: `transport.*` (80r), `budownictwo.*` (50r), `akcyza.*` (30r). Łącznie 160 reguł — tyle samo, co poprzednio, ale z lepszą separacją domen.

---

# CZĘŚĆ V: IMPLEMENTACJA — TEMPLATE OPA

## 5.1 Template dla reguły Macro (P-ID)

```rego
package jdg.vat.exemptions

import data.jdg.vat.a113

# ── P58: vat_exemption_subject_jdg ─────────────────────
# Cel: Zwolnienie podmiotowe VAT (limit 200 000 PLN)
# Warstwa: MACRO — agreguje wyniki z warstwy MICRO
# Micro zależności: jdg.vat.a113.r1-r18
# Priorytet: 58

default vat_exemption_subject_jdg := {"matched": false}

vat_exemption_subject_jdg := result {
    # Warunki wejściowe (Macro sprawdza kontekst)
    input.vendor.country == "PL"
    input.jdg_entrepreneur.business_status == "ACTIVE"

    # Delegacja do warstwy Micro — sprawdzenie wszystkich warunków
    # (w rzeczywistym Rego: data.jdg.vat.a113.limit_200k_check == true)
    data.jdg.vat.a113.limit_200k_check == true
    data.jdg.vat.a113.excluded_activities_check == false
    data.jdg.vat.a113.excluded_goods_check == false
    data.jdg.vat.a113.excluded_services_check == false

    result := {
        "matched": true,
        "rule_id": "jdg.vat.exemptions.vat_exemption_subject_jdg",
        "priority": 58,
        "vat_rate": "0.00",
        "vat_exemption": "SUBJECT",
        "vat_exemption_limit": input.thresholds.jdg.limits.vat_exemption_limit,
        "_legal_basis": "Art. 113 ust. 1, Art. 113 ust. 9 VAT",
        "_micro_rules_executed": [
            "jdg.vat.a113.r1",
            "jdg.vat.a113.r2",
            "jdg.vat.a113.r3",
            "jdg.vat.a113.r5",
            "jdg.vat.a113.r6"
        ]
    }
}
```

## 5.2 Template dla reguły Micro (jdg.*)

```rego
package jdg.vat.a113

# ── jdg.vat.a113.r2: limit_200k_check ─────────────────
# Cel: Sprawdzenie czy obrót roczny ≤ 200 000 PLN
# Warstwa: MICRO — atomowa reguła prawna
# Wywoływana przez: P58 (Macro)
# Podstawa: Art. 113 ust. 1 VAT

limit_200k_check := true {
    input.jdg_entrepreneur.annual_turnover_net <= input.thresholds.jdg.limits.vat_exemption_limit
    input.jdg_entrepreneur.annual_turnover_net > 0
}

# ── jdg.vat.a113.r4: new_business_proportion ──────────
# Cel: Obliczenie proporcjonalnego limitu dla nowych JDG
# Wywoływana przez: P58, P59 (Macro)

new_business_proportion := result {
    input.jdg_entrepreneur.ceidg_entry_date != null
    days_active := date_diff(input.jdg_entrepreneur.ceidg_entry_date, fiscal_year_end)
    proportion := days_active / 365
    proportional_limit := input.thresholds.jdg.limits.vat_exemption_limit * proportion

    result := {
        "limit": proportional_limit,
        "days_active": days_active,
        "proportion": proportion
    }
}

# ── jdg.vat.a113.r7: breach_mid_year_consequences ─────
# Cel: Konsekwencje przekroczenia limitu w trakcie roku
# Edge case: utrata zwolnienia, obowiązek rejestracji

breach_mid_year_consequences := result {
    input.jdg_entrepreneur.annual_turnover_net > input.thresholds.jdg.limits.vat_exemption_limit
    input.jdg_entrepreneur.vat_status == "EXEMPT"

    result := {
        "exemption_lost": true,
        "vat_payer_from": "date_of_breach",
        "vat_r_required": true,
        "vat_r_deadline_days": 7,
        "vat_due_from_first_exceeding_sale": true
    }
}
```

## 5.3 Template dla pliku mikro-reguł (pełny artykuł)

Każdy plik `.rego` w warstwie Micro zawiera:
- Nagłówek z nazwą ustawy i zakresem artykułów
- 8-15 atomowych reguł
- Metadane z podstawą prawną
- Testy jednostkowe w komentarzach

---

# CZĘŚĆ VI: PLAN WDROŻENIA — 4 FAZY DO 7,000 REGUŁ

> ⚠️ **WAŻNE:** Poniższy harmonogram dotyczy **specyfikacji i dekompozycji** reguł (dokumentacja). Pełna implementacja w Rego z testami jednostkowymi to osobny, dłuższy proces (~6-9 miesięcy przy zespole 3-5 inżynierów). Szacowane tempo: ~10 reguł/dzień dla implementacji vs ~30-50/dzień dla specyfikacji.

## Faza 1: INTEGRACJA ISTNIEJĄCYCH ZASOBÓW (2 tygodnie)

| Zadanie | Opis | Czas |
|---------|------|:----:|
| **Mapowanie 294 P-ID → Micro** | Dla każdej reguły kanonicznej: przypisać zestaw reguł Micro z Doc 31 | 3 dni |
| **Aktualizacja 38c** | Dodać kolumnę `Micro Dependencies` do mapy kanonicznej | 1 dzień |
| **Walidacja dual-layer** | Sprawdzić spójność: czy każda Macro ma przypisane Micro i odwrotnie | 2 dni |
| **Generacja metadanych** | Wygenerować pliki METADATA dla wszystkich 294 reguł Macro | 1 dzień |

## Faza 2: DEKOMPOZYCJA KKS — NAJWIĘKSZA LUKA (3 tygodnie)

| Zadanie | Opis | Czas |
|---------|------|:----:|
| **KKS Art. 54-61** | Przestępstwa skarbowe — ~130 reguł | 5 dni |
| **KKS Art. 62-76** | Fałszerstwa faktur, VAT — ~195 reguł | 5 dni |
| **KKS Art. 77-83** | Wykroczenia skarbowe — ~130 reguł | 5 dni |
| **KKS Art. 16-21** | Czynny żal, przedawnienie — ~65 reguł | 3 dni |

## Faza 3: DEKOMPOZYCJA POZOSTAŁYCH USTAW (4 tygodnie)

| Zadanie | Opis | Czas |
|---------|------|:----:|
| **AML + RODO** | ~230 reguł (ustawa AML, RODO dla JDG) | 5 dni |
| **Ochrona środowiska** | ~150 reguł (BDO, SUP, CBAM) | 3 dni |
| **Cross-border rozszerzone** | ~200 reguł (CFC, Exit Tax, TP, dyrektywy) | 5 dni |
| **Specjalistyczne branże** | ~160 reguł (transport, budownictwo, akcyza) | 4 dni |
| **PIT Art. 30da, 30f, 45a-45f** | ~65 reguł (Exit Tax, CFC, PIT-11) | 3 dni |

## Faza 4: EDGE CASES, INTERAKCJE, WALIDACJE (2 tygodnie)

| Zadanie | Opis | Czas |
|---------|------|:----:|
| **Interakcje kaskadowe** | ~100 reguł (VAT↔PIT↔ZUS↔KUP) | 3 dni |
| **Walidacje wejściowe** | ~200 reguł (NIP, REGON, PKWiU, numery faktur) | 4 dni |
| **Konflikty między regułami** | ~100 reguł (IP Box vs B+R, ulgi vs dochód) | 3 dni |
| **Testy graniczne** | ~200 testów jednostkowych dla wszystkich Micro | 4 dni |

---

# CZĘŚĆ VII: PODSUMOWANIE — STATYSTYKI KOŃCOWE

## 7.1 Liczby

| Metryka | Obecnie (38c) | Po integracji Doc 31 | Docelowo (Faza 1-4) |
|---------|:------------:|:--------------------:|:--------------------:|
| **Reguły Macro (P-ID/R-ID)** | 294 | 450 | 500 |
| **Reguły Micro (jdg.*)** | 0 (niezintegrowane) | 3,055 | 7,000 |
| **Łącznie reguł** | 294 | 3,505 | 7,500 |
| **Pakiety .rego** | 32 | 45 | 70+ |
| **Pliki .rego** | 32 | 60 | 100+ |
| **Podstawy prawne** | 250+ | 500+ | 1,000+ |
| **Thresholds** | ~160 | ~250 | ~400 |

## 7.2 Status pokrycia DocsJDG

| Ustawa | Artykułów w DocsJDG | % pokrycia obecnie | % po integracji Doc 31 | % docelowo |
|--------|:-------------------:|:------------------:|:----------------------:|:----------:|
| Ustawa o VAT | 60+ | ~70% | ~85% | **100%** |
| Ustawa o PIT | 40+ | ~75% | ~85% | **100%** |
| Ordynacja podatkowa | 30+ | ~80% | ~90% | **100%** |
| Ustawa o SUS | 15+ | ~90% | ~95% | **100%** |
| KKS | 10+ | ~5% | ~5% | **100%** |
| Prawo przedsiębiorców | 15+ | ~60% | ~70% | **100%** |
| Ustawa o CEIDG | 10+ | ~90% | ~95% | **100%** |
| Ustawa o ryczałcie | 17+ | ~80% | ~90% | **100%** |
| Ustawa zdrowotna | 5+ | ~90% | ~95% | **100%** |
| Ustawa o rachunkowości | 25+ | ~40% | ~55% | **100%** |
| PCC + podatki lokalne | 15+ | ~50% | ~60% | **100%** |
| Zarząd sukcesyjny | 15+ | ~60% | ~75% | **100%** |
| KSeF + JPK | 20+ | ~50% | ~65% | **100%** |
| RODO | 10+ | ~5% | ~5% | **100%** |
| AML + dewizowe | 15+ | ~5% | ~5% | **100%** |
| Środowisko (BDO, SUP, CBAM) | 15+ | ~10% | ~10% | **100%** |
| Transport + akcyza | 20+ | ~10% | ~10% | **100%** |

## 7.3 Kluczowe wnioski

1. **Dokument 31_JDG_3000_RULES.md** już zawiera masywną dekompozycję ~3,055 reguł — NIE zaczynamy od zera!
2. **KKS jest największą luką** (~480 reguł, obecnie ~5% pokrycia) — to priorytet Fazy 2
3. **RODO, AML, środowisko, exit tax, CFC** — całkowicie nowe obszary, niezbędne dla ENTERPRISE
4. **Dual-Layer Architecture** rozwiązuje problem dwóch systemów ID: Macro (P-ID) agreguje Micro (jdg.*)
5. **Target ~7,000 reguł** jest realny: 530 artykułów × 13 mikro-reguł + edge cases/interakcje/walidacje

---

> **🔥 WNIOSEK KOŃCOWY:** System NexusAI JDG NIE ma "tylko 140 reguł". Ma **już zintegrowane ~779 reguł kanonicznych** (w `38c_JDG_CANONICAL_MAP.md`), **~3,055 reguł zdekomponowanych** (w `31_JDG_3000_RULES.md`), a po pełnej integracji Dual-Layer Architecture osiągnie **~7,000 reguł** — poziom ENTERPRISE adekwatny do złożoności polskiego prawa podatkowego. Dokumenty `42_JDG_DEEP_GAP_DISCOVERY.md` (55 reguł) i `43_JDG_KKS_MASSIVE_DECOMPOSITION.md` (230 reguł) dostarczają dodatkowych szczegółowych reguł dla obszarów o najniższym pokryciu.

> **Następny krok:** Implementacja reguł kanonicznych w Rego — priorytetyzacja wg `38c_JDG_CANONICAL_MAP.md`. Równolegle: dalsza dekompozycja KKS, AML, RODO, środowisko.

---

*Wygenerowano przez NexusAI Mega Matrix Integration Engine v1.1*  
*Data: 2026-07-12*  
*Bazuje na: 31_JDG_3000_RULES.md (~3,055 reguł), 38c_JDG_CANONICAL_MAP.md (~779 reguł kanonicznych), 42_JDG_DEEP_GAP_DISCOVERY.md (55 reguł), 43_JDG_KKS_MASSIVE_DECOMPOSITION.md (230 reguł), DocsJDG (źródła prawne)*  
*Target: ~7,000 reguł ENTERPRISE*  
*Gotowość wdrożeniowa: Plan strategiczny — Faza 1 gotowa do natychmiastowej implementacji*
