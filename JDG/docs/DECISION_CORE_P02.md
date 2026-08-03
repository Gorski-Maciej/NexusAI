# 📘 WARSTWA DECYZYJNA CORE — NexusAI JDG (P02, Sekcje 1-7)

> **Status:** ✅ WDROŻONY (P02 v9.0, 2026-08-02)
> **Pliki:** `JDG/rules/adaptive_trust_scoring_enterprise.rego`,
> `JDG/rules/conflict_declaration_enterprise.rego`,
> `JDG/rules/decision_core_completeness_enterprise.rego`,
> `JDG/rules/p02_decision_core_innovations_v9.rego`,
> `JDG/tools/limitations_calendar.py`, `JDG/rules/main_jdg.rego`

## Sekcja 1 — Adaptive Trust Scoring (`jdg.adaptive_trust`)

Zamiast stałych progów 0.92/0.75 — adaptacyjny scoring ML:

- **AT-01 Base Trust Score** — średnia pewności pól OCR (fc_vat_rate, fc_nip…).
- **AT-02 Domain Corrections** — accuracy historyczna per pakiet koryguje bazę
  (`data.jdg.trust_feedback.packages`).
- **AT-03 Adaptive Thresholds per pakiet** — `auto_post_threshold(pkg)` /
  `suggest_threshold(pkg)` = baza + (accuracy − 0.90) × 0.05.
- **AT-04 Counterparty Risk** — sankcje / brak białej listy / graf fraudowy.
- **AT-05 Fraud Pattern Detection** — okrągłe kwoty, self-invoicing, szybki
  obrót, zmiana NIP, split cash.
- **AT-06 Final Trust Score** — base − kara fraud − kara ryzyka + bonus pakietu.
  Routing: `AUTO_POST` / `SUGGEST` / `TRIAGE_QUEUE` / `BLOCK_AND_ALERT`.

## Sekcja 2 — Conflict Declaration System (`jdg.conflict_declaration`)

- **CD-01 Conflict Registry** — formalna deklaracja znanych konfliktów
  (ipbox_vs_br, representation_vs_marketing, car_auto_vs_kup,
  bad_debt_creditor_vs_debtor, lump_sum_vs_direct_costs) —
  zewnętrznie konfigurowalna (`data.jdg.conflict_declarations`).
- **CD-02 Deterministic Hierarchy** — priorytety rozstrzygania (1 = najwyższy).
- **CD-03 Real-Time Reporting** — aktywne konflikty do `_cross_domain_conflicts`.
- **CD-04 Conflict Simulator** — what-if na zmianę rozstrzygnięcia (sandbox).

## Sekcje 3-5 — Completeness Layer (`jdg.decision_core_completeness`)

- **DC-01 Edge Case Coverage Matrix** — macierz pokrycia kombinacji faktów
  + detektor luk (`uncovered_combinations`).
- **DC-02 Limitations Calendar** — kalendarz przedawnień per zobowiązanie
  (Art. 70 §1/§2 OP: 5/10 lat) z alertami EXPIRED/CRITICAL/ALERT/WATCH.
- **DC-03 Liability / Representation / Retention** — zgodność z Art. 70 OP,
  pełnomocnictwa, prokura, 5-letnia retencja (Art. 86 §1 OP).
- **DC-04** — decyzja `retention_non_compliant` / `edge_case_gap` / `ok`.

## Sekcja 7 — Genius Ideas (`jdg.p02_decision_core_innovations`)

12 wdrożonych: never-wrong engine (dowód poprawności), detektor martwych
reguł i tautologii, symulator konfliktów, graf zależności, samo-testy
właściwości (property-based), kaskadowy downgrade przy braku danych,
rejestr precedensów, detektor anomalii czasowych, explainability chain,
missing-field resilience, heatmapa ryzyka, testy regresyjne właściwości.

## Komendy CLI

```bash
# Kalendarz przedawnień z alertami (bramka CI: exit 2 przy alertach)
python JDG/tools/limitations_calendar.py build --file obligations.json
python JDG/tools/limitations_calendar.py alerts --file obligations.json --today-year 2026

# Aktywacja pakietów w OPA (flaga check):
#   input.jdg_entrepreneur.trust_check / conflict_check /
#   completeness_check / p02_decision_core_check = true
```

## Integracja

`main_jdg.rego` → `_package_decisions` zawiera 4 nowe pakiety P02;
`final_verdict_p02` = post-provenance merge P01+P02 (safe_merge, REPORT-only).
