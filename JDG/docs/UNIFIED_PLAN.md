# 🎯 Zunifikowany Plan Wdrożenia Modułu JDG — v8.0

> **Scalenie 67 dokumentów Plan OPA w jeden nurt**
> **Data:** 2026-08-02 | **Generator:** auto z MANIFEST.md
> **Stan faktyczny:** 383 pliki / 10,827 unikalnych rule_id / 352 plików z matched:true

---

## Problem: 5 Konkurujących Strategii — ROZWIĄZANY

Plan OPA zawiera 67 dokumentów z wieloma konkurującymi strategiami:

| # | Dokument | Strategia | Status |
|---|----------|-----------|:------:|
| 1 | `00_PLAN_STRUKTURA.md` | 240 reguł, 13 faz | 📐 Fundament |
| 2 | `24_JDG_COMPLETE_INDEX.md` | 47 reguł ID | 🔴 DEPRECATED |
| 3 | `38c_JDG_CANONICAL_MAP.md` | ~779 reguł | ⭐ ŹRÓDŁO PRAWDY |
| 4 | `41_JDG_MEGA_MATRIX_7000_RULES.md` | ~7000 Micro | 🎯 Horyzont 2027+ |
| 5 | `45_JDG_HYPER_GRANULARITY.md` | ~700 atomowych | 🧪 Eksperyment |

**Decyzja:** 38c (~779) = źródło prawdy. Wszystkie strategie scalone w jeden nurt.

---

## Stan Faktyczny (v8.0 — 2026-08-02)

```
STAN OBECNY:  383 pliki Rego, 10,827 unikalnych rule_id
              352 pliki z matched:true, 24 inicjatyw S1-S24
              90 plików enterprise, 106 plików micro
CEL:          779 reguł kanonicznych (mapa 38c)
STATUS:       Fazy A/B/C wykonane lub przekroczone — NOWY PLAN v8.0 poniżej
HORYZONT:     7000 regułów Micro (Dual-Layer — rozpoczęte, patrz ADR-010)
```

---

## 6 Faz Wdrożenia — v8.0

### Faza 1: Domknięcie Kanoniczne (Doc 50 → 95%)

| # | Zadanie | Status | Metryka |
|---|---------|:------:|---------|
| 1.1 | Naprawa generate_coverage_report.py (R4) | ⬜ | Skrypt działa bez NameError |
| 1.2 | Ekstrakcja WSZYSTKICH prefiksów aktów (V/P/OP/K/Z/R/PP/U/Pcc) | ⬜ | Pełne pokrycie Doc 50 |
| 1.3 | Harmonizacja Doc 50 z mapą 38c | ⬜ | Jedna lista punktów prawnych |
| 1.4 | Auto-mapowanie przez rule_id OPA | ⬜ | Skok pokrycia do ~70-80% |
| 1.5 | Dopisanie brakujących reguł krytycznych | ⬜ | >=95% punktow VAT zmapowanych |

**Definition of Done:** Coverage report pokazuje >=95% punktów Doc 50 z mapowaniem na rule_id.

### Faza 2: Legal Coverage A/B/C Przeliczenie

| # | Zadanie | Status | Metryka |
|---|---------|:------:|---------|
| 2.1 | Uruchomienie validate_legal_basis.py | ⬜ | Aktualna klasyfikacja A/B/C |
| 2.2 | Aktualizacja LEGAL_COVERAGE.md (ostatnia: 2026-07-17) | ⬜ | Data = dzisiejsza |
| 2.3 | Heatmapa pokrycia prawnego per akt | ⬜ | Wizualizacja A/B/C |
| 2.4 | Auto-aktualizacja przez ISAP Crawler | ⬜ | CI sprawdza dryf >7 dni |

**Definition of Done:** LEGAL_COVERAGE.md z datą <= 7 dni od ostatniego commita rules/.

### Faza 3: Mikro-Konsolidacja (Deduplikacja 336 rule_id)

| # | Zadanie | Status | Metryka |
|---|---------|:------:|---------|
| 3.1 | Identyfikacja wszystkich duplikatów rule_id | ⬜ | Lista 336 duplikatów |
| 3.2 | Decyzja: merge/rename/remove per duplikat | ⬜ | ADR-010 wdrożony |
| 3.3 | Deduplikacja w rules/ | ⬜ | 0 duplikatów globalnych |

**Definition of Done:** `grep -rhoE 'rule_id.*' rules/ | sort | uniq -d` zwraca 0.

### Faza 4: Testy Rego + CI/CD

| # | Zadanie | Status | Metryka |
|---|---------|:------:|---------|
| 4.1 | Testy Rego dla kluczowych pakietów (VAT, PIT, ZUS, KKS) | ⬜ | >=20 plików _test.rego |
| 4.2 | Pre-commit hook: validate_rules + manifest --check | ⬜ | .pre-commit-config.yaml |
| 4.3 | GitHub Action: CI dla dokumentacji | ⬜ | .github/workflows/jdg-docs.yml |
| 4.4 | Testy regresyjne dla else-chain | ⬜ | Testy kolejności reguł |

**Definition of Done:** `opa test JDG/tests/ -v` przechodzi z >=20 testami Rego.

### Faza 5: Bundle Pipeline + Deployment OPA

| # | Zadanie | Status | Metryka |
|---|---------|:------:|---------|
| 5.1 | Naprawa bundle.sh (R1) | ✅ | Zachowana struktura katalogów, 0 kolizji |
| 5.2 | Weryfikacja bundle: liczba plików .rego | ✅ | Bundle = źródło |
| 5.3 | Test deploymentu OPA | ⬜ | curl PUT bundle → OPA server |

**Definition of Done:** `bash bundle.sh` tworzy poprawny bundle.tar.gz z wszystkimi plikami.

### Faza 6: Enterprise Rozszerzenia S25+

| # | Zadanie | Status |
|---|---------|:------:|
| 6.1 | AI Agent — asystent podatkowy (LLM Bridge C2 rozszerzenie) | ⬜ |
| 6.2 | Dashboard — metryki pokrycia i health | ⬜ |
| 6.3 | API: /manifest, /coverage, /rules/{id}, /legal-coverage (R14) | ⬜ |

---

## Inicjatywy Enterprise S1-S24 — Status

| ID | Inicjatywa | Status |
|:--:|-----------|:------:|
| S1 | Tax Optimization Engine | ✅ |
| S2 | Banking Automation | ✅ |
| S3 | Cashflow Tax Predictor | ✅ |
| S4 | JPK_V7 Auto-Generation | ✅ |
| S5 | KSeF Resilience | ✅ |
| S6 | Annual Declaration | ✅ |
| S7 | Form Transition Simulator | ✅ |
| S8 | Audit Defense | ✅ |
| S9 | Strategic Advisor | ✅ |
| S10 | Neural Rule Mesh | ✅ |
| S11 | Legislative Monitor | ✅ |
| S12 | Cross-Domain Intelligence | ✅ |
| S13 | Judicial Interpretations | ✅ |
| S14 | Lifecycle Manager | ✅ |
| S15 | Sanctions Optimization | ✅ |
| S16 | Tax Authority Interaction | ✅ |
| S17 | Exit Tax & MDR | ✅ |
| S18 | PPK & PFRON | ✅ |
| S19 | VAT Substantive Complete | ✅ |
| S20 | NKUP Enterprise Complete | ✅ |
| S21 | VAT Complete (rozszerzenie S19) | ✅ |
| S22 | Tax Authority Interaction (rozszerzenie S16) | ✅ |
| S23 | Sanctions Optimization (rozszerzenie S15) | ✅ |
| S24 | Lifecycle Manager (rozszerzenie S14) | ✅ |

---

## Metryki Docelowe

| Etap | Pliki Rego | Unikalne rule_id | Pokrycie Doc 50 |
|------|:----------:|:----------------:|:---------------:|
| **Stan obecny (v8.0)** ✅ | 383 | 10,827 | ~8% (VAT only) |
| Po Fazie 1 | 383 | ~10,900 | ~80% (VAT full) |
| Po Fazie 2 | 383 | ~10,900 | 80% + aktualna klasyfikacja A/B/C |
| Po Fazie 3 | 383 | ~10,564 | 80% (bez duplikatów) |
| Po Fazie 4 | 383 | ~10,564 | 80% + testy Rego |
| Po Fazie 5 | 383 | ~10,564 | 80% + pipeline deployment |

---

## Roadmap Czasowy Q3-Q4 2026

| Kamień milowy | Data | Faza |
|---------------|------|------|
| **M1:** Coverage Report naprawiony | 2026-08-15 | Faza 1 |
| **M2:** 80% pokrycia Doc 50 | 2026-09-01 | Faza 1 |
| **M3:** Legal Coverage zaktualizowany | 2026-09-15 | Faza 2 |
| **M4:** 0 duplikatów rule_id | 2026-10-01 | Faza 3 |
| **M5:** Testy Rego + CI/CD | 2026-10-15 | Faza 4 |
| **M6:** Bundle deployment | 2026-11-01 | Faza 5 |
| **M7:** AI Agent + Dashboard | 2026-12-15 | Faza 6 |

---

*Wygenerowano przez NexusAI Unified Plan Engine v8.0 — 2026-08-02*
*Liczby auto-generowane z MANIFEST.md przez `python JDG/tools/generate_manifest.py`*
