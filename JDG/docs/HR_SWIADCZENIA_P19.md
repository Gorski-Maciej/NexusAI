# P19 — HR i Świadczenia (Pracodawca, MPiPS, Rodzina, Siła Wyższa, Ubezpieczenia, Płatności)

> **📌 Aktualizacja 2026-08-22:** dokument historyczny opisujący wdrożenie promptu GLM 5.2.
> Raporty źródłowe (`prompty_glm52/`, `raporty_glm52/`, `raporty_jdg_enterprise/`) zostały zarchiwizowane poza repo.
> Aktualny stan wdrożenia: [`KAMPANIA_GLM52_ETAPY_10_28.md`](KAMPANIA_GLM52_ETAPY_10_28.md) + `JDG/bundles/*audit_state.json` (certyfikacja końcowa ETAP 28/29 — 2026-08-22, 14/14 bramek).

**Pakiet:** `jdg.p19_hr_swiadczenia_innovations`
**Plik:** `JDG/rules/p19_hr_swiadczenia_innovations_v9.rego`
**Raport:** `raporty_jdg_enterprise/R19_HR_Swiadczenia.txt`
**Status:** [✅ WDROŻONY] — POSTĘP 19/24 | LUKI P0/P1/P2 ZAMKNIĘTE 2026-08-05 (7/7)

## Zakres (8 sekcji promptu wdrożone jako reguły)

1. **Audyt pracodawcy** — employer.rego (28) + mpips.rego (13): obowiązki pracodawcy, KUP dojazdów 300 zł, wynagrodzenia (ZUS + PIT-4), urlopy, terminy wypłat.
2. **Audyt świadczeń rodzinnych (PRIORYTET ★)** — family 85 reguł: 800+, zasiłek rodzinny, ulga prorodzinna, terminy wniosków.
3. **Audyt siły wyższej i ubezpieczeń** — art. 148¹ KP (2 dni/rok, 50% wynagrodzenia), force_majeure 64, insurance 36.
4. **Audyt PPK/PFRON/funduszu solidarnościowego** — ppk_pfron 8, solidarity 47: progi, terminy wpłat, auto-kalkulator składek.
5. **Audyt płatności, zamówień, reklamy** — payments 61, procurement 69, advertising 48: terminy, limity, klasyfikacje KUP.
6. **OPA jako rozbudowany system** — pipeline auto-aktualizacji reguł HR (płaca minimalna, progi ZUS, kwota wolna).
7. **12 genialnych pomysłów Enterprise (INN-01..INN-12)**.
8. **Mapa drogowa P0/P1/P2** (w raporcie R19).

## Genialne pomysły (INN)

| # | Reguła | Opis |
|---|--------|------|
| INN-01 | `salary_calculator` | kalkulator wynagrodzeń brutto→netto (ZUS 9.76+1.5+2.45+9%, PIT-4 12%) |
| INN-02 | `payroll_generator` | generator listy płac (6 składników per pracownik) |
| INN-03 | `leave_tracker` | tracker urlopów (26 dni, bilans urlopowy) |
| INN-04 | `family_benefit_calculator` | kalkulator świadczeń rodzinnych (800+ miesięcznie) |
| INN-05 | `force_majeure_calculator` | kalkulator siły wyższej (art. 148¹ KP, 2 dni, 50%) |
| INN-06 | `ppk_tracker` | tracker PPK (2% pracownik + 1.5% pracodawca) |
| INN-07 | `pfron_contributor` | kalkulator PFRON (od 25 pracowników, 40,75 zł/etat) |
| INN-08 | `solidarity_calculator` | kalkulator funduszu solidarnościowego (0.5%) |
| INN-09 | `severance_calculator` | kalkulator odpraw (1/2/3 mies. wg stażu) |
| INN-10 | `payroll_payments_monitor` | monitor terminów płatności (10./15./20.) |
| INN-11 | `advertising_classifier` | klasyfikator reklama vs reprezentacja (KUP) |
| INN-12 | `hr_pipeline_snapshot` | pipeline auto-aktualizacji reguł HR (ADR-002) |

## Reguły audytu (Sekcje 1-6)

- `hr_coverage_report` — mapa pokrycia 10 modułów (employer, mpips, family, force_majeure, insurance, solidarity, ppk_pfron, payments, procurement, advertising)
- `employer_audit` — obowiązki pracodawcy, KUP 300 zł
- `family_benefits_audit` — 800+, zasiłek rodzinny, ulga prorodzinna
- `force_majeure_insurance_audit` — art. 148¹ KP, ubezpieczenia
- `ppk_pfron_solidarity_audit` — progi i terminy wpłat
- `payments_procurement_advertising_audit` — terminy, limity, klasyfikacje
- `hr_pipeline_snapshot` — pipeline auto-aktualizacji (ADR-002, hot-reload)

## Progi (ADR-002 — data.jdg.thresholds, zero hardcode)

KUP dojazdów 300 zł, ZUS 9.76/1.5/2.45/9%, PIT-4 12%, siła wyższa 2 dni/50%, 800+ 800 zł, PPK 2%+1.5%, PFRON 25 pracowników/40,75 zł, solidarność 0.5%, odprawy do 3 mies., zamówienia do 30 000 zł bez PZP, reklama 0.25% przychodu.

## Mapa drogowa R19 (P0/P1/P2) — zamknięta 2026-08-05

| Priorytet | Pozycja | Reguła | Status |
|---|---|---|---|
| **P0** | Pełny moduł płac end-to-end (brutto→netto→ZUS→PIT-4→wypłata) | `payroll_end_to_end_module` | ✅ WDROŻONE |
| **P0** | Integracja z Płatnikiem ZUS (import/eksport list płac) | `platnik_zus_integration` | ✅ WDROŻONE |
| **P1** | Panel świadczeń rodzinnych z automatycznymi wnioskami do ZUS/MPiPS | `family_benefits_panel` | ✅ WDROŻONE |
| **P1** | Kalkulator wynagrodzeń z kwotą wolną i ulgami (PIT-2) | `salary_calculator_tax_optimized` | ✅ WDROŻONE |
| **P1** | Tracker PPK z pełną automatyzacją wpłat (2% + 1.5%) | `ppk_auto_contribution_tracker` | ✅ WDROŻONE |
| **P2** | Dashboard HR (urlopy, płace, PFRON) w UI | `hr_dashboard_ui` | ✅ WDROŻONE |
| **P2** | e-wnioski pracownicze (urlop, siła wyższa) z auto-akceptacją | `employee_ewnioski_workflow` | ✅ WDROŻONE |

**Konfiguracja (ADR-002):** blok `hr_swiadczenia` w `thresholds_jdg.rego` (payroll_e2e, platnik_zus, family_benefits_panel, salary_tax_optimized, ppk_auto, hr_dashboard, ewnioski).

**CLI narzędzia:** `--payroll-e2e`, `--platnik`, `--family-panel`, `--salary-tax`, `--ppk-auto`, `--hr-dashboard`, `--ewnioski`, `--roadmap` (wszystkie 7 + agregacja).

## Artefakty

- Rego: `JDG/rules/p19_hr_swiadczenia_innovations_v9.rego` (25 reguł + decide + default — 27 bloków łącznie, 12 INN, 22+ podstaw prawnych)
- Narzędzie: `JDG/tools/hr_swiadczenia_auditor.py` (audyt ~605 rule_id w 27 plikach + 21 kalkulatorów CLI)
- Testy rego: `JDG/tests/rego/test_p19_hr_swiadczenia_enterprise.rego` (38 scenariusze)
- Testy pytest: `JDG/tests/auto/test_p19_hr_swiadczenia_enterprise.py` (44 testy)
- Okablowanie: `main_jdg.rego` — import + `_package_decisions` + `final_verdict_p19 = safe_merge(final_verdict_p18, ...)` — bez kolizji ze starym `jdg.p19_innovations` (v8)
