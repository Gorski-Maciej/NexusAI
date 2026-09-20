# 🗃️ NexusAI JDG — Inwentaryzacja Plików (każdy plik w JDG/ i policies/)

> **Dokument:** INWENTARYZACJA_PLIKOW.md | **Zakres:** **wszystkie pliki** katalogów `JDG/` (**3737**) i `policies/` (**635**)
> **Pomiar:** 2026-09-19 (`find … -type f ! -path '*__pycache__*'`; LINIE = `wc -l` zsumowane per katalog)
> **Cel:** kompletna mapa plików — statystyki per katalog, przeznaczenie, metoda pomiaru. Dla reguł Rego szczegóły w [KATALOG_REGUL.md](KATALOG_REGUL.md), dla narzędzi w [KATALOG_NARZEDZI.md](KATALOG_NARZEDZI.md).

---

## 🔎 Wyszukiwarka (Ctrl+F)

`inwentaryzacja` · `plik` · `files` · `katalog` · `statystyki` · `linie` · `LOK` · `gdzie co leży` · `liczba plików` · `3737` · `635` · dowolna nazwa pliku/katalogu

---

## 1. Zagregowane statystyki

> ⚠️ **Metoda:** pliki liczone `find <katalog> -type f ! -path '*__pycache__*'`. Suma **3737** obejmuje również zagnieżdżone `JDG/JDG/` (4), `JDG/policies/` (6), `JDG/reports/` (2) i `JDG/.hypothesis/` (214 — artefakty testowe). „Linie” = suma `wc -l` plików danego obszaru.

| Obszar | Pliki | Linie (≈) |
|---|---:|---:|
| **JDG/ (razem, bez `__pycache__`)** | **3737** | **~460 000** |
| `JDG/rules/` — reguły Rego (543 `.rego` + 4 kopie `.bak*` + 1 summary) | 548 | **335 474** (rego) |
| ├─ top-level `rules/*.rego` | 284 | — |
| ├─ podkatalogi (49 katalogów, 259 `.rego`; w tym `micro/` 94) | 259 | — |
| `JDG/tests/` | 569 | ~95 000 |
| `JDG/tools/` (narzędzia Python) | 1051 (1033 top-level + 12 podkatalogi) | ~150 000 |
| `JDG/bundles/` | 1043 | ~9 000 |
| `JDG/docs/` | 92 (85 top-level + `prompty_enterprise_v3/`) | ~18 000 |
| `JDG/prompty_v3/` | 70 | ~12 000 |
| `JDG/raporty_glm52_v3/` | 79 | ~14 000 |
| `JDG/raporty_glm52/` · `raporty_glm52_enterprise/` · `raporty_enterprise_v3/` | 3 · 11 · 8 | ~5 000 |
| `JDG/migrations/` (SQL) | 13 | ~3 000 |
| `JDG/api/` (OpenAPI) | 1 | 1433 |
| root `JDG/` (README, MANIFEST, plany, prompty GLM 5.2) | 16 | ~30 000 |
| `JDG/JDG/` · `JDG/policies/` · `JDG/reports/` (zagnieżdżone, patrz §8) | 4 · 6 · 2 | — |
| `JDG/.hypothesis/` · `.pytest_cache/` · `.benchmarks/` (artefakty) | 214 · 5 · 1 | — |
| **policies/ (razem)** | **635** | ~55 000 |

---

## 2. Drzewo katalogów `JDG/` — przeznaczenie

| Katalog | Plików | Przeznaczenie |
|---|---:|---|
| `JDG/` (root) | 16 | `README.md`, `MANIFEST.md` (auto: `tools/generate_manifest.py`), `COVERAGE_REPORT.md`, `unified_plan_v8.yaml` + `unified_plan_progress.yaml`, `prompts_status.yaml`, `requirements.txt`, `stale_rules_registry.json`, 2 generatory (`generate_coverage_report.py`, `generate_missing_rules.py`), 6 plików promptów GLM 5.2 (`PROMPTY_GLM52_*.txt`) |
| `JDG/api/` | 1 | `openapi.yaml` — spec REST **OpenAPI 3.0.3 v1.0.0: 18 operacji, 13 schematów, JWT** |
| `JDG/bundles/` | 1043 | `bundle.sh`, manifesty, **22 audit-state (ETAP 06–28)**, golden_verdicts, evidence certyfikacji, **862 plików `v3_*`** (kampania V3) |
| `JDG/docs/` | 92 | dokumentacja techniczna (85 top-level + `prompty_enterprise_v3/` 7) — spis w [INDEX.md](INDEX.md) |
| `JDG/migrations/` | 13 | RuleStore SQL 001–013 — **58 tabel `CREATE TABLE`**, seed progów w 001 |
| `JDG/prompty_v3/` | 70 | prompty kampanii V3 (P00–P68) |
| `JDG/raporty_glm52_v3/` | 79 | raporty + HANDOFF kampanii V3 (po 1+ per część P00–P68) |
| `JDG/raporty_glm52/` | 3 | raporty kampanii GLM 5.2 (faza przygotowania) |
| `JDG/raporty_glm52_enterprise/` | 11 | raporty enterprise kampanii GLM 5.2 |
| `JDG/raporty_enterprise_v3/` | 8 | raporty wcześniejszej kampanii enterprise V3 (21/21, 2026-08-26) |
| `JDG/reports/` | 2 | raporty pomocnicze |
| `JDG/rules/` | 548 | 543 plików `.rego` + 4 kopie `.bak*` (nieładowane) + `micro/GENERATION_SUMMARY.txt` |
| `JDG/tests/` | 569 | 288 pytest (root 84 + `auto/` 204) + 278 natywnych Rego (`rego/` 276 + root 2) + README |
| `JDG/tools/` | 1051 | 1033 narzędzi top-level (689 `v3_*`) + `glm52_v3_campaign/` (12) |
| `JDG/JDG/` (zagnieżdżony) | 4 | patrz §8 |
| `JDG/policies/` (zagnieżdżony) | 6 | patrz §8 |

---

## 3. `JDG/rules/` — 543 plików Rego (12 111 unikalnych rule_id)

**Podział:** 284 top-level + 259 w 49 podkatalogach. Suma linii Rego: **335 474**.

| Grupa | Plików | Zawartość |
|---|---:|---|
| top-level `rules/*.rego` | 284 | rdzeń (`main_jdg.rego` — orkiestrator Multi-Pass + anchor `final_verdict_p132`, `thresholds_jdg.rego` — progi ADR-002, `risk`, `routing`, `compliance`, `kks`), domeny, enterprise S1–S24, **53 pakiety `v3_*`** kampanii V3 |
| `micro/` | 94 | atomowe reguły per artykuł (VAT, PIT, ZUS, KKS, UoR…) |
| `pit/` | 23 | forms, kup, advances_returns, exemptions, transitions |
| `jdg/` | 14 | reguły biznesowe JDG |
| `local_taxes/` | 11 | podatki lokalne |
| `uor/`, `vat/`, `zus/` | 9 / 9 / 9 | UoR (księgi, sprawozdania), VAT (substantive, deductions, procedures), ZUS (składki, zasiłki) |
| `kks/` | 7 | KKS (kary, strategia obrony) |
| `pcc/` | 5 | PCC |
| `accounting/` | 8 | PKPiR, UoR, amortyzacja, leasing |
| `business/`, `crossborder/`, `mdr/` | 4 / 4 / 4 | sukcesja, exit tax/CFC, MDR |
| `advertising/`, `audit/`, `calendar/`, `compliance/`, `conviction/`, `edelivery/`, `esig/`, `family/`, `force_majeure/`, `fx/`, `insurance/`, `payments/`, `procurement/`, `regulated/`, `residency/`, `seasonal/`, `solidarity/`, `taxfree/`, `tp/`, `wis/` | 2–3 każdy | plany 44/45 + domeny szczegółowe |
| pozostałe (1 plik): `api_ui`, `bundles`, `docs`, `enterprise`, `environmental`, `hyper`, `jpk`, `ksef_jpk`, `ord`, `representation`, `risk`, `rodo`, `security`, `statute`, `tests_ci`, `tools` | 16 | domeny pojedyncze + jakości |

---

## 4. `JDG/tests/` — 569 plików

| Katalog | Plików | Zawartość |
|---|---:|---|
| `tests/` (root) | 87 | **84 pytest** (`test_*.py`: enterprise, audyty ETAP, quality V3) + 2 natywne Rego (`jdg_rules_test.rego`, `p26_regression_test.rego`) + README |
| `tests/auto/` | 206 | **204 pytest**: `test_auto_block_*.py` + `test_pNN_*_enterprise.py` (P01–P68) |
| `tests/rego/` (top-level) | 251 | natywne `test_native_*.rego` + `test_v3_*.rego` (52 — kampania V3) |
| `tests/rego/micro/` | 25 | `test_native_micro_*.rego` (27 obszarów domeny) |
| **Razem** | **569** | **288 pytest + 278 natywnych Rego + README + p26/jdg_rules** |

---

## 5. `JDG/tools/` — 1051 plików (1033 top-level + 12 `glm52_v3_campaign/`)

| Grupa | Plików | Przykłady |
|---|---:|---|
| narzędzia V3 (`v3_*.py`) | 689 | silniki dowodowe, bramki statyczne, run-all, ledger (`v3_campaign_ledger.py`), settlement P68 |
| narzędzia rdzenia | 344 | `generate_manifest.py` (auto-MANIFEST), `bundle_server.py`, `decision_certificate.py`, linter, walidatory, chaos/self-healing, audyty ETAP |
| JSON | 3 | `v3_p67_learning_data.json` i inne rejestry danych |
| `glm52_v3_campaign/` (podkatalog) | 12 | generator promptów kampanii V3 (produkuje `prompty_v3/`) |
| pozostałe | 3 | `README.md`, `.hypothesis/` |

---

## 6. `JDG/bundles/` — 1043 plików

| Grupa | Plików | Zawartość |
|---|---:|---|
| `v3_*` (kampania V3) | 862 | bundele bramek, silników, run-all, settlement, evidence, ledger |
| `*_audit_state.json` | 22 | ETAP 06–28 (stan `WDROZONY_100`/`PASS`) |
| manifesty i pozostałe | 159 | `manifest.json`, `manifest_v2.json`, golden_verdicts, `final_certification_v4_evidence.json`, `bundle.sh` |

---

## 7. Root `JDG/` — 16 plików

| Plik | Przeznaczenie |
|---|---|
| `README.md` | strona główna modułu |
| `MANIFEST.md` | tracker pokrycia reguł — **auto** (`python3 tools/generate_manifest.py`; regen. 2026-09-19: 12 111 rule_id, Completeness 83/100) |
| `COVERAGE_REPORT.md` | raport pokrycia prawnego Doc 50 (archiwalny — aktualne metryki: MANIFEST + evidence v4) |
| `unified_plan_v8.yaml` · `unified_plan_progress.yaml` | plan strategiczny v8 + postęp |
| `prompts_status.yaml` | statusy promptów kampanii |
| `requirements.txt` | zależności Python modułu |
| `stale_rules_registry.json` | rejestr reguł do przeglądu |
| `generate_coverage_report.py` · `generate_missing_rules.py` | generatory (kopie narzędzi) |
| `PROMPTY_GLM52_*.txt` (6 plików) | prompty kampanii GLM 5.2 (ETAP 10–28) |

---

## 8. Zagnieżdżone katalogi i artefakty (do uwagi)

| Ścieżka | Plików | Uwaga |
|---|---:|---|
| `JDG/JDG/rules/` | 4 | zagnieżdżona kopia reguł (artefakt historii katalogów) — mirror kanoniczny to `policies/` w repo root |
| `JDG/policies/jdg/` | 6 | zagnieżdżony fragment mirrora |
| `JDG/reports/` | 2 | raporty pomocnicze |
| `JDG/rules/micro/vat/vat.rego.bak*` (3) · `rules/main_jdg.rego.bak` | 4 | kopie zapasowe — **nie ładowane** do bundle (rozszerzenie ≠ `.rego`) |
| `JDG/.hypothesis/` · `.pytest_cache/` · `.benchmarks/` | 220 | artefakty testowe Pythona — ignorować |
| `__pycache__/` (wszędzie) | 823 `.pyc` | wyłączone ze wszystkich liczników |

---

## 9. `policies/` — 635 plików (mirror reguł; hash-parity dla 3 par kanonicznych V3)

> **Struktura faktyczna (2026-09-19):** płaski mirror `policies/*.rego` (284 pliki = 1:1 z `JDG/rules/*.rego` top-level) + podkatalogi domen (jak w `JDG/rules/`) + `policies/jdg/` (starszy mirror selektywny) + `policies/tax/` (seria SC) + `policies/tests/`.

| Obszar | Plików | Zawartość |
|---|---:|---|
| root `policies/*.rego` | 284 | mirror 1:1 top-level `JDG/rules/` (`main_jdg.rego`, `thresholds_jdg.rego`, `v3_p67…`, `v3_p68…` — hash-parity sha256) |
| podkatalogi domen (49) | 259 | mirror podkatalogów `JDG/rules/` |
| `policies/jdg/` | 65 | starszy mirror selektywny: 30 `.rego` flat + `rules/` (6 `v3_p1x…`) + `vat/`, `pit/`, `hyper/` + `bundles/` (base/overlays v2026/v2027) + README |
| `policies/tax/` | 35 | seria SC (Spółka Cywilna): `main_sc.rego`, CIT, PIT, VAT/GTU, UoR, partnerzy |
| `policies/tests/` | 1 | `sc_main_test.rego` (testy natywne SC) |
| `policies/data/`, `docs/`, root .md/.sh/Makefile | ~9 | `thresholds_sc.rego`, Makefile, `bundle.sh`, README |

> **Konwencja P48/V3:** dla pakietów kampanii V3 mirror to **3 pary kanoniczne z wymuszonym hash-parity** (`v3_p67_self_learning.rego`, `v3_p68_recertification_final.rego`, `thresholds_jdg.rego`) — weryfikacja: `sha256sum JDG/rules/X policies/X`. Pozostałe pliki mirrora sync’dowane per fala kampanii.

---

## 10. Jak używać tej inwentaryzacji

1. **Szukasz reguły po nazwie pliku** → [KATALOG_REGUL.md](KATALOG_REGUL.md) (tabela z pakietem i liczbami).
2. **Szukasz narzędzia** → [KATALOG_NARZEDZI.md](KATALOG_NARZEDZI.md).
3. **Szukasz katalogu/statystyk** → sekcje 2–9 tego dokumentu.
4. **Szukasz opisu architektury** → [ARCHITEKTURA.md](ARCHITEKTURA.md).
5. **Odtwarzasz liczniki** → komendy z §1 (`find` per katalog) — każdy podany tu numer ma jawną metodę pomiaru.

---

*Spójny z: KATALOG_REGUL.md · KATALOG_NARZEDZI.md · STRUKTURA_PROJEKTU.md · MANIFEST.md · Stan: 2026-09-19*
