# 🗃️ NexusAI JDG — Inwentaryzacja Plików (każdy plik w JDG/ i policies/)

> **Dokument:** INWENTARYZACJA_PLIKOW.md | **Zakres:** **wszystkie pliki** katalogów `JDG/` (1407) i `policies/` (558)
> **Cel:** kompletna mapa plików — statystyki per katalog, lista plików, przeznaczenie. Dla reguł Rego szczegóły w [KATALOG_REGUL.md](KATALOG_REGUL.md), dla narzędzi w [KATALOG_NARZEDZI.md](KATALOG_NARZEDZI.md).

---

## 🔎 Wyszukiwarka (Ctrl+F)

`inwentaryzacja` · `plik` · `files` · `katalog` · `statystyki` · `linie` · `LOK` · `gdzie co leży` · dowolna nazwa pliku/katalogu

---

## 1. Zagregowane statystyki

> ⚠️ **Uwaga o metodzie:** wartości „linie" pochodzą z licznika `wc -l` per katalog (poziom 1). Sumy w tej sekcji są **przybliżone** — małe rozbieżności wynikają z zaokrągleń.

| Obszar | Pliki | Linie (w przybliżeniu) |
|---|---:|---:|
| **JDG/ (razem, bez __pycache__)** | ~1 407 | **~520 000+** |
| `JDG/rules/` — reguły Rego (490 plików) | 490 | **~375 000+** |
| ├─ rdzeń i domeny (root + subkatalogi, bez mikro) | ~381 | ~128 000 |
| ├─ mikro-atomy (`micro/` ze wszystkimi podkatalogami) | 91 | **~241 500** |
| `JDG/tools/` (narzędzia Python) | 298 | ~80 000+ |
| `JDG/tests/` (testy, bez __pycache__) | 408 | ~60 000+ |
| `JDG/docs/` (dokumentacja) | 62 | ~10 000 |
| `JDG/api/` (OpenAPI) | 1 | 1 038 |
| `JDG/migrations/` (SQL) | 13 | ~3 000 |
| `JDG/bundles/` (OPA bundle + audit-state) | 107 | ~4 000 |
| root `JDG/` (README, plany) | 7 | 16 170 |
| **policies/ (razem)** | 558 | ~60 000+ |

---

## 2. Katalogi `JDG/` — statystyki i przeznaczenie

| Katalog | Plików | Linii | Przeznaczenie |
|---|---:|---:|---|
| `JDG/` (root) | 7 | 16 170 | README, MANIFEST, COVERAGE_REPORT, plany, generatory |
| `JDG/api/` | 1 | 1 038 | specyfikacja OpenAPI 3.0.3 (`openapi.yaml`) |
| `JDG/bundles/` | 107 | ~4 000 | `bundle.sh` + manifesty + **22 audit-state (ETAP 06–28)** + golden_verdicts |
| `JDG/docs/` | 62 | ~10 000 | dokumentacja techniczna (ta rodzina plików) |
| `JDG/migrations/` | 13 | ~3 000 | DuckDB RuleStore: 001–013 (w tym Legal Twin 003, Control Plane 007) |
| `JDG/rules/` | 231 | ~100 000 | ★ 231 plików Rego (rdzeń, domeny, enterprise, hyper, ETAP 10–28) |
| `JDG/rules/accounting/` | 8 | 3 738 | PKPiR, UoR, amortyzacja, leasing, transformer |
| `JDG/rules/advertising/` | 2 | 221 | plan44/45: reklama |
| `JDG/rules/allowances/` | 1 | 54 | plan23: ulgi |
| `JDG/rules/audit/` | 2 | 274 | plan44/45: audyt |
| `JDG/rules/business/` | 3 | 617 | gig economy, zawieszenie/sukcesja, inteligencja strategiczna |
| `JDG/rules/calendar/` | 2 | 178 | plan44/45: kalendarz terminów |
| `JDG/rules/compliance/` | 1 | 606 | AML enterprise |
| `JDG/rules/conviction/` | 2 | 164 | plan44/45: zatarcie skazania |
| `JDG/rules/crossborder/` | 3 | 419 | exit tax/CFC, plan23 UE, post-Brexit |
| `JDG/rules/edelivery/` | 2 | 183 | plan44/45: e-Doręczenia |
| `JDG/rules/environmental/` | 1 | 574 | BDO enterprise |
| `JDG/rules/esig/` | 2 | 172 | plan44/45: e-Signature |
| `JDG/rules/family/` | 2 | 241 | plan44/45: rodzina |
| `JDG/rules/force_majeure/` | 2 | 162 | plan44/45: siła wyższa |
| `JDG/rules/fx/` | 2 | 236 | plan44/45: kursy walut |
| `JDG/rules/insurance/` | 2 | 146 | plan44/45: ubezpieczenia |
| `JDG/rules/jdg/hyper/` | 14 | 2 584 | ★ Hyper Plan45 (14 pakietów) |
| `JDG/rules/jpk/` | 1 | 14 | terminy JPK |
| `JDG/rules/kks/` | 6 | 1 755 | KKS: kary enterprise, innowacje, plany 42–44 |
| `JDG/rules/local_taxes/` | 10 | 3 975 | PCC, nieruchomości, transport, akcyza |
| `JDG/rules/mdr/` | 4 | 979 | MDR: enterprise, hallmarks, plan44/45 |
| `JDG/rules/micro/` | 29+ | 9 385+ | ★ mikro-atomy (serie plan33/34) |
| `JDG/rules/micro/akcyza/` | 1 | 3 639 | akcyza mikro (132 reguły) |
| `JDG/rules/micro/aml/` | 5 | 3 922 | AML: CBDD, ryzyko, STR/GIF, transakcje |
| `JDG/rules/micro/amortyzacja/` | 4 | 718 | amortyzacja Art. 22a–22n |
| `JDG/rules/micro/bdo/` | 6 | 902 | BDO: rejestracja, EWC, ewidencja, transport, WEEE |
| `JDG/rules/micro/budownictwo/` | 1 | 1 932 | budownictwo (64 reguły) |
| `JDG/rules/micro/ceidg/` | 1 | 1 242 | CEIDG (42 reguły) |
| `JDG/rules/micro/crossborder/` | 1 | 5 319 | cross-border mikro (192 reguły) |
| `JDG/rules/micro/jpk/` | 1 | 1 015 | JPK mikro (35 reguł) |
| `JDG/rules/micro/kks/` | 1 | 13 373 | KKS mikro (473 reguły) |
| `JDG/rules/micro/ksef/` | 1 | 2 275 | KSeF mikro (79 reguł) |
| `JDG/rules/micro/ord/` | 1 | 12 016 | Ordynacja mikro (423 reguły) |
| `JDG/rules/micro/pcc/` | 1 | 2 567 | PCC mikro (89 reguł) |
| `JDG/rules/micro/pit/` | 1 | 22 738 | PIT mikro (811 reguł) |
| `JDG/rules/micro/pkpir/` | 7 | 1 534 | PKPiR: kolumny, przychody, koszty, NKUP, remanent, korekty |
| `JDG/rules/micro/pp/` | 1 | 4 158 | Prawo Przedsiębiorców mikro (147 reguł) |
| `JDG/rules/micro/rodo/` | 6 | 1 591 | RODO: rejestr, erasure, podprocesorzy, AI, sankcje, zatrudnienie |
| `JDG/rules/micro/ryczalt/` | 1 | 4 387 | ryczałt mikro (155 reguł) |
| `JDG/rules/micro/srodowisko/` | 1 | 1 391 | środowisko mikro (48 reguł) |
| `JDG/rules/micro/sukcesja/` | 1 | 3 929 | sukcesja mikro (140 reguł) |
| `JDG/rules/micro/sus/` | 16 | 7 268 | SUS: art. 6–47 per artykuł |
| `JDG/rules/micro/transport/` | 1 | 1 279 | transport mikro (44 reguły) |
| `JDG/rules/micro/uor/` | 1 | 2 712 | UoR mikro (148 reguł) |
| `JDG/rules/micro/vat/` | 9 | 122 322 | ★ VAT mikro (1091 reguł) + ksef/marża/miejsce/proporcja/WDT |
| `JDG/rules/micro/zasilkowa/` | 5 | 2 256 | zasiłki: art. 19–33 |
| `JDG/rules/micro/zdrowotna/` | 7 | 7 676 | zdrowotna: art. 79–82 |
| `JDG/rules/ord/` | 1 | 1 107 | Ordynacja innowacje v8 |
| `JDG/rules/payments/` | 2 | 286 | plan44/45: płatności |
| `JDG/rules/pcc/` | 5 | 1 321 | PCC: sprzedaż, pożyczki, spółki, stawki |
| `JDG/rules/pit/` | 20 | 7 296 | ★ PIT: formy, KUP, ulgi, zwolnienia, przejścia |
| `JDG/rules/procurement/` | 2 | 185 | plan44/45: zamówienia |
| `JDG/rules/regulated/` | 2 | 172 | plan44/45: zawody regulowane |
| `JDG/rules/representation/` | 1 | 106 | prokura plan26 |
| `JDG/rules/residency/` | 2 | 263 | plan44/45: rezydencja |
| `JDG/rules/risk/` | 1 | 29 | plan26 KKS risk |
| `JDG/rules/rodo/` | 1 | 24 | plan42 RODO |
| `JDG/rules/seasonal/` | 2 | 161 | plan44/45: sezonowość |
| `JDG/rules/security/` | 1 | 855 | security fortress v8 |
| `JDG/rules/solidarity/` | 2 | 133 | plan44/45: solidarnościowe |
| `JDG/rules/statute/` | 1 | 54 | plan26 przedawnienia |
| `JDG/rules/taxfree/` | 2 | 200 | plan44/45: tax-free |
| `JDG/rules/tp/` | 2 | 281 | plan44/45: ceny transferowe |
| `JDG/rules/uor/` | 9 | 3 834 | ★ UoR: obowiązek, księgi, przychody, koszty, aktywa, inwentaryzacja, zamknięcie, sprawozdanie |
| `JDG/rules/vat/` | 8 | 5 023 | ★ VAT: substantive, deductions, procedures, POS, plany |
| `JDG/rules/wis/` | 2 | 188 | plan44/45: WIS |
| `JDG/rules/zus/` | 8 | 1 873 | ★ ZUS: składki, zasiłki, zdrowotna, silniki |
| `JDG/tests/` | 65 | ~20 000 | pytest (16 skopiowanych + enterprise + audyty ETAP 10–28) |
| `JDG/tests/auto/` | 81 | 28 792 | ★ automatyczne testy blokowe `test_auto_block_*.py` (~60) + `test_pNN_*_enterprise.py` |
| `JDG/tests/rego/` | 103 | 13 414 | ★ natywne testy Rego `test_native_*.rego` |
| `JDG/tests/rego/micro/` | 25 | 3 250 | natywne testy mikro `test_native_micro_*.rego` (27 obszarów) |
| `JDG/tools/` | 298 | ~80 000+ | ★ narzędzia deweloperskie (patrz KATALOG_NARZEDZI.md) |

---

## 3. Pliki główne `JDG/` (root)

| Plik | Linii | Przeznaczenie |
|---|---:|---|
| `README.md` | ~330 | strona główna (ten repo) |
| `MANIFEST.md` | ~470 | tracker pokrycia reguł (AUTO: `tools/generate_manifest.py`) |
| `COVERAGE_REPORT.md` | ~2 000+ | raport pokrycia prawnego (AUTO: `tools/generate_coverage_report.py`) |
| `generate_coverage_report.py` | ~250 | kopia narzędzia raportu |
| `generate_missing_rules.py` | ~276 | generator reguł mikro (checkpoint) |
| `unified_plan_v8.yaml` | duży | plan strategiczny v8 (24 inicjatywy, fazy, roadmap) |
| `unified_plan_progress.yaml` | średni | postęp wdrożenia planu |

## 4. `JDG/api/` i `JDG/migrations/`

| Plik | Linii | Przeznaczenie |
|---|---:|---|
| `api/openapi.yaml` | 1 038 | spec OpenAPI 3.0.3: 17 endpointów, 13 schematów, JWT |
| `migrations/001_jdg_rule_store.sql` | 296 | tabele 1–5 + seed 50 progów + wersje reguł + kartografia |
| `migrations/002_jdg_enterprise_v7.sql` | 103 | tabele 6–9 (predykcje, stale rules, konflikty, cache) |

## 5. `JDG/bundles/`

| Plik | Przeznaczenie |
|---|---|
| `bundle.sh` | budowa `jdg-bundle-{wersja}.tar.gz` (zachowuje strukturę katalogów, weryfikacja licznika plików) |
| `manifest.json` | manifest bundle: reguły i pliki (aktualizowany przy `bundle.sh`) |

## 6. `JDG/docs/` — pełna lista (62 pliki)

**Nowa dokumentacja enterprise (ta seria):** `README.md` (root), `ARCHITEKTURA.md`, `STRUKTURA_PROJEKTU.md`, `API_REFERENCJA.md`, `LOGIKA_BIZNESOWA.md`, `ZGODNOSC_PRAWNA.md`, `PODRECZNIK_UZYTKOWNIKA.md`, `FAQ.md`, `KATALOG_REGUL.md`, `INWENTARYZACJA_PLIKOW.md` (ten), `KATALOG_NARZEDZI.md`.

**Dokumenty istniejące wcześniej:**

| Plik | Zakres |
|---|---|
| `ARCHITECTURE.md` | ADR 001–015 (decyzje projektowe) |
| `DEVELOPER_GUIDE.md` | przewodnik dewelopera v8.0 (8 warstw, cykl życia reguły, CI/CD) |
| `OPA_REGO_DEVELOPER_GUIDE.md` | przewodnik Rego (rule ID, werdykt, bundle) |
| `UNIFIED_PLAN.md` | plan wdrożenia v8 |
| `LEGAL_COVERAGE.md` | pokrycie prawne (Doc 50) |
| `LEGAL_REFERENCE_ACTS.md` | kompletna lista aktów prawnych |
| `RULE_LIFECYCLE.md` | zarządzanie cyklem życia reguł |
| `DECISION_CORE_P02.md` | warstwa decyzyjna core |
| `VAT_MACRO_P03.md` · `VAT_MICRO_P04.md` | VAT makro/mikro |
| `PIT_MACRO_P05.md` · `PIT_MICRO_P06.md` | PIT makro/mikro |
| `ZUS_MACRO_P07.md` · `ZUS_MICRO_P08.md` | ZUS makro/mikro |
| `KSIEGOWOSC_PKPIR_UOR_P09.md` | księgowość |
| `KKS_P10.md` · `ORDYNACJA_PODATKOWA_P11.md` | KKS, Ordynacja |
| `CROSSBORDER_P12.md` · `RYCZALT_CYKL_ZYCIE_P13.md` · `PCC_LOKALNE_AKCYZA_P14.md` | domeny P12–P14 |
| `SRODOWISKO_BDO_P15.md` · `RODO_AML_BEZPIECZENSTWO_P16.md` · `KSEF_JPK_EDEKLARACJE_P17.md` | P15–P17 |
| `AUTOMATYZACJA_KSIEGOWOSCI_P18.md` · `HR_SWIADCZENIA_P19.md` · `NEURAL_MESH_INNOWACJE_P20.md` | P18–P20 |
| `OPA_JAKO_SYSTEM_P21.md` · `NARZEDZIA_WALIDACJI_P22.md` · `TESTY_REGO_CI_P23.md` | P21–P23 |
| `AUDYT_KOMPLETNY_P24.md` | P24 synteza master |
| `PIT_AUDYT_R04.md` · `PRAWA_PRZEDSIEBIORCOW_AUDYT_R02.md` · `VAT_AUDYT_R03.md` | raporty audytowe R02–R04 |
| `api.md` | dokumentacja API (auto-generowana z openapi.yaml) |
| `Bbb` / `Bbb.md` | artefakt pomocniczy (nie dokumentacja operacyjna) |
| `CORE_GUARDS_TEMPORAL_THRESHOLDS.md` | ETAP 06 — 42 niezmienniki INV-001..042 |
| `ORCHESTRATOR_DATA_CONTRACT.md` | ETAP 05 — 25-polowy werdykt, PASS 0–8, safe_merge |
| `CONTROL_PLANE_RULE_LIFECYCLE.md` | ETAP 04 — fail-closed cykl życia reguł |
| `KAMPANIA_GLM52_ETAPY_10_28.md` | ETAP 10–28 — audyty kampanii GLM 5.2, certyfikacja końcowa (2026-08-22) |
| `prompty_enterprise_v3/STATUS_KAMPANII_V3.txt` · `prompty_enterprise_v3/README_PLIKI_PROMPT.txt` | kampania V3 — status 21/21 WDROŻONY_100, KAMPANIA_V3_KOMPLETNA (2026-08-26); raporty per część: `raporty_enterprise_v3/NN_NAZWA.txt`; rejestr: `bundles/enterprise_v3_registry.json` |
| `LEGAL_SOURCE_REGISTRY.md` · `LEGAL_TWIN_RAPORT.md` · `LEGAL_TWIN_TRACEABILITY.md` | Legal Twin / LKG (ETAP 02–03) |
| `AUDYT_PODSTAW_PRAWNYCH.md` · `P00_REMEDIACJA_PODSTAW_PRAWNYCH.md` · `LEGAL_COVERAGE_GAP_RAPORT.md` | audyty podstaw prawnych (P00/P02) |
| `MANIFEST_2_0.md` · `PEWNOSC_DASHBOARD.md` · `KALENDARZ_ZMIAN_PRAWNYCH.md` | manifest 2.0, dashboard pewności, kalendarz zmian prawnych |
| `SLOWNIK_REFERENCJI_PRAWNYCH.md` · `ZGODNOSC_DOKUMENTY_KSIEGOWE.md` | słownik referencji, zgodność dokumentów księgowych |

## 7. `JDG/tests/` — struktura

| Katalog | Plików | Przykłady |
|---|---:|---|
| `JDG/tests/` | 65 | `test_temporal_validity.py` (40/40 PASS), `test_ksef_generator.py`, `test_risk_guard.py`, `test_tax_pipeline.py`, audyty ETAP 10–28 (`test_*_etapNN_audit.py`)… |
| `JDG/tests/auto/` | 133 | `test_auto_block_*.py` (~60 bloków: vat, pit, zus, kks, rodo, ksef_jpk…) + `test_pNN_*_enterprise.py` (P01–P24) + `test_pit_audyt_r04_enterprise.py` itd. |
| `JDG/tests/rego/` | 180 | `test_native_*.rego` (annual_declaration, audit_defense, banking, cashflow, ksef_*, mdr, neural_mesh, poa, strategic…, `test_native_*_etapNN.rego` dla ETAP 14–28) |
| `JDG/tests/rego/micro/` | 25 | `test_native_micro_*.rego` (akcyza, aml, amortyzacja, bdo, budownictwo, ceidg, crossborder, jpk, kks, ksef, ord, pcc, pit, pkpir, pp, rodo, ryczalt, srodowisko, sukcesja, sus, transport, uor, vat, zasilkowa, zdrowotna) |
| `JDG/tests/` (rego root) | 3 | `jdg_rules_test.rego`, `p26_regression_test.rego`, `test_uor_obligation.rego` + testy uor/pcc/kks |

---

## 8. `policies/` — pełna inwentaryzacja (558 plików; mirror zsynchronizowany ETAP 26 — hash-parity 0% drift)

### 8.1. `policies/` (root)

| Plik | Linii | Przeznaczenie |
|---|---:|---|
| `Makefile` | 115 | zadania (build, test, lint) |
| `bundle.sh` | 91 | budowa bundle |
| `data/thresholds_sc.rego` | 195 | progi dla serii SC (`data.sc.thresholds`) |

### 8.2. `policies/jdg/` — mirror reguł JDG (ETAP 26, v2026.08; 52 pliki rego — w tym `*_etapNN_v1.rego` dla ETAP 10–28)

**Orkiestracja:** `main_jdg.rego` (194), `_helpers_jdg.rego` (268), `_metadata_jdg.rego` (273), `README.md` (233).

**Rdzeń:** `risk.rego` (190), `routing.rego` (135), `compliance.rego` (156), `kks.rego` (1564), `fallback.rego` (52), `validation.rego` (264), `temporal.rego` (166), `conflicts.rego` (700), `edge_cases.rego` (874).

**Domeny:** `vat/substantive.rego` (1072), `vat/deductions.rego` (602), `vat/procedures.rego` (420), `pit/forms.rego` (230), `pit/kup.rego` (245), `pit/advances_returns.rego` (203), `pit/exemptions.rego` (136), `pit/transitions.rego` (130), `allowances.rego` (617), `zus.rego` (453), `accounting.rego` (1340), `business.rego` (608), `crossborder.rego` (317).

**Pozostałe:** `corrections.rego` (122), `liability.rego` (102), `representation.rego` (130), `restructuring.rego` (132), `local_taxes.rego` (188), `ksef_jpk.rego` (112), `international.rego` (83), `employer.rego` (169), `environmental.rego` (148), `digital.rego` (116), `retention.rego` (116), `mpips.rego` (127), `rodo.rego` (152).

**Bundle:** `bundles/README.md` (79), `bundles/bundle.sh` (75), `bundles/base/manifest.json` (27), `bundles/overlays/v2026/manifest.json` (33), `bundles/overlays/v2027/manifest.json` (11) — **mechanizm nakładek czasowych** (v2026/v2027) na bazowy bundle.

### 8.3. `policies/tax/` — seria SC (Spółka Cywilna + podatki)

**Orkiestracja:** `main_sc.rego` (148), `_helpers.rego` (192), `_helpers_sc.rego` (228), `_metadata.rego` (365), `sc_fallback.rego` (199), `README.md` (213).

**Domeny:** `direct/cit.rego` (156), `direct/pit.rego` (217), `vat/substantive.rego` (244), `vat/gtu.rego` (54), `vat/deductions.rego` (21), `vat/procedures.rego` (22), `vat_registration.rego` (52), `cit_deductions.rego` (58), `pit_withholding.rego` (54), `uor_books.rego` (154), `uor_reports.rego` (68), `uor_valuation.rego` (83).

**Pozostałe:** `risk.rego` (174), `routing.rego` (92), `compliance.rego` (119), `crossborder.rego` (137), `allowances.rego` (294), `accounting.rego` (152), `zus.rego` (173), `temporal.rego` (156), `fallback.rego` (65), `anomaly.rego` (165), `what_if.rego` (143), `ordynacja_extended.rego` (82), `labor_extended.rego` (50), `partner_mirror.rego` (169), `sc_partnership.rego` (165), `sc_liability.rego` (160), `sc_ksef_jpk.rego` (160).

### 8.4. `policies/tests/`

| Plik | Linii | Przeznaczenie |
|---|---:|---|
| `sc_main_test.rego` | 293 | natywne testy serii SC (`tax.main_sc_test`, 6 reguł testowych) |

---

## 9. Artefakty pomocnicze (do uwagi)

| Ścieżka | Uwaga |
|---|---|
| `JDG/rules/micro/vat/vat.rego.bak_stubs_removed` · `vat.rego.p03backup` | kopie zapasowe przed usunięciem stubów — **nie ładowane** do bundle (rozszerzenie ≠ .rego) |
| `JDG/rules/micro/GENERATION_SUMMARY.txt` | raport generacji reguł mikro |
| `JDG/tests/__pycache__/` · `JDG/tools/__pycache__/` · `JDG/tests/auto/__pycache__/` | artefakty Pythona — ignorować |
| `JDG/.benchmarks/` · `JDG/.hypothesis/` | artefakty testowe (pytest-benchmark, hypothesis) |
| `JDG/docs/Bbb` · `JDG/docs/Bbb.md` | artefakt roboczy |

---

## 10. Jak używać tej inwentaryzacji

1. **Szukasz reguły po nazwie pliku** → [KATALOG_REGUL.md](KATALOG_REGUL.md) (tabela z pakietem i liczbami).
2. **Szukasz narzędzia** → [KATALOG_NARZEDZI.md](KATALOG_NARZEDZI.md).
3. **Szukasz katalogu/statystyk** → sekcje 2–8 tego dokumentu.
4. **Szukasz opisu architektury** → [ARCHITEKTURA.md](ARCHITEKTURA.md).

---

*Spójny z: KATALOG_REGUL.md · KATALOG_NARZEDZI.md · STRUKTURA_PROJEKTU.md · MANIFEST.md*
