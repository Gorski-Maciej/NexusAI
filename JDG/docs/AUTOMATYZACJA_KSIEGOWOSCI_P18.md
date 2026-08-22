# P18 — Automatyzacja Księgowości (Bankowość, ePUAP, e-Doręczenia, WIS, Formularze)

> **📌 Aktualizacja 2026-08-22:** dokument historyczny opisujący wdrożenie promptu GLM 5.2.
> Raporty źródłowe (`prompty_glm52/`, `raporty_glm52/`, `raporty_jdg_enterprise/`) zostały zarchiwizowane poza repo.
> Aktualny stan wdrożenia: [`KAMPANIA_GLM52_ETAPY_10_28.md`](KAMPANIA_GLM52_ETAPY_10_28.md) + `JDG/bundles/*audit_state.json` (certyfikacja końcowa ETAP 28/29 — 2026-08-22, 14/14 bramek).

**Pakiet:** `jdg.p18_automatyzacja_ksiegowosci_innovations`
**Plik:** `JDG/rules/p18_automatyzacja_ksiegowosci_innovations_v9.rego`
**Raport:** `raporty_jdg_enterprise/R18_Automatyzacja_Ksiegowosci.txt`
**Status:** [✅ WDROŻONY] — POSTĘP 18/24 | LUKI P0/P1/P2 ZAMKNIĘTE 2026-08-05 (7/7)

## Zakres (8 sekcji promptu wdrożone jako reguły)

1. **Audyt bankowości (PSD2/PolishAPI)** — AIS/PIS, OAuth2/eIDAS, Elixir/ExpressElixir (cutoff 14:30/15:30), batch XML/JSON, auto-księgowanie wyciągów, auto-oznaczanie płatności, monitor PSD2 (SCA RTS 2018/389 — 100 zł/5 transakcji), rozliczanie przelewów do deklaracji.
2. **Audyt e-Doręczeń i e-podpisu (PRIORYTET ★)** — adres do doręczeń, skrzynki, auto-podpis, **"jedno kliknięcie"** — pełny obieg pisma z urzędem.
3. **Audyt formularzy i deklaracji** — auto-generacja PIT-36/36L/28, VAT-7, JPK, ZUS DRA/RCA/RZA, PCC-3; **silnik auto-fill** z danych księgowych.
4. **Audyt kalendarza i terminów** — ZUS/VAT/PIT/JPK/KSeF, tracker z alertami T-7/T-3/T-0, priorytetyzacja, **"nieśmiertelny kalendarz podatnika"**.
5. **Audyt korespondencji i przepływów** — tax_correspondence_engine, cashflow predictors, overpayment_auto_claimer, auto-koncyliacja bank.
6. **OPA jako rozbudowany system** — pipeline auto-adaptacji integracji (zmiany API banków/urzędów).
7. **15 genialnych pomysłów Enterprise (INN-01..INN-15)**.
8. **Mapa drogowa P0/P1/P2** (w raporcie R18).

## Genialne pomysły (INN)

| # | Reguła | Opis |
|---|--------|------|
| INN-01 | `bank_statement_auto_booking` | auto-księgowanie wyciągów bankowych (dokument → dane → księgowanie) |
| INN-02 | `payment_auto_tagging` | auto-oznaczanie płatności (VAT/ZUS/PIT/PCC/KOSZT z tytułu przelewu) |
| INN-03 | `psd2_monitor` | monitor PSD2 — decyzja SCA (RTS 2018/389), limity exempt, naruszenia |
| INN-04 | `transfer_to_declaration_settlement` | rozliczanie przelewów do deklaracji (VAT-7, ZUS DRA) |
| INN-05 | `one_click_letter_flow` | "jedno kliknięcie" — pełny obieg pisma z urzędem (5 kroków) |
| INN-06 | `form_autofill_engine` | silnik auto-fill formularzy z danych księgowych |
| INN-07 | `immortal_tax_calendar` | "nieśmiertelny kalendarz podatnika" — terminy ZUS/VAT/PIT/JPK |
| INN-08 | `deadline_alert_tracker` | tracker terminów z alertami (KRYTYCZNE/UWAGA/OK) |
| INN-09 | `bank_reconciliation_engine` | auto-koncyliacja bank (wyciągi vs rejestry) |
| INN-10 | `cashflow_forecaster` | predykcja przepływów (cashflow + VAT) |
| INN-11 | `overpayment_auto_claimer` | auto-wnioskowanie o zwrot nadpłat (art. 74-80 OrdPU) |
| INN-12 | `correspondence_auto_generator` | auto-generator pism do US (wezwania, zażalenia, wnioski) |
| INN-13 | `tax_deadline_priority` | priorytetyzacja terminów podatkowych |
| INN-14 | `virtual_bookkeeper_assistant` | wirtualny asystent księgowego — agregacja automatyzacji |
| INN-15 | `split_payment_adviser` | doradca MPP — mechanizm podzielonej płatności (art. 108a VAT, próg 15 000 zł) |

## Reguły audytu (Sekcje 1-6)

- `automatyzacja_coverage_report` — mapa pokrycia 7 modułów (banking, edelivery, esig, wis, forms, calendar, cashflow)
- `banking_audit` — PSD2/PolishAPI, SCA 100 zł, Elixir 14:30/15:30
- `edelivery_esig_audit` — e-Doręczenia, e-podpis, jedno kliknięcie
- `forms_declarations_audit` — PIT-36/36L/28, VAT-7, JPK, ZUS DRA/RCA/RZA, PCC-3
- `calendar_deadlines_audit` — terminy + tracker z alertami
- `correspondence_cashflow_audit` — pisma do US, przepływy, nadpłaty
- `api_adaptation_pipeline` — pipeline auto-adaptacji API (ADR-002, hot-reload)

## Progi (ADR-002 — data.jdg.thresholds, zero hardcode)

Elixir cutoff 14:30, Express Elixir 15:30, SCA exempt 100 zł / 5 transakcji, MPP 15 000 zł, VAT-7 do 25., ZUS DRA do 10., PIT do 30 kwietnia, PCC-3 14 dni, WIS 3 miesiące, nadpłata odsetki po 30 dniach.

## Mapa drogowa R18 (P0/P1/P2) — zamknięta 2026-08-05

| Priorytet | Pozycja | Reguła | Status |
|---|---|---|---|
| **P0** | Integracja AIS/PIS (PolishAPI) — token OAuth2 + konsent PSD2 | `ais_pis_integration` | ✅ WDROŻONE |
| **P0** | Weryfikacja SCA w środowisku produkcyjnym banku (RTS 2018/389) | `sca_production_verification` | ✅ WDROŻONE |
| **P1** | Pełny silnik auto-fill PIT-36/36L/28 z UoR (bilans, RZiS) | `pit_uor_autofill_engine` | ✅ WDROŻONE |
| **P1** | Integracja e-Doręczeń B2B/B2G + potwierdzenia doręczenia | `edelivery_b2b_b2g_flow` | ✅ WDROŻONE |
| **P1** | Model ML predykcji cashflow (gradient boosting, horyzont 30 dni) | `ml_cashflow_prediction` | ✅ WDROŻONE |
| **P2** | Dashboard wirtualnego asystenta księgowego (ksiegowania/deklaracje/terminy/przepływy) | `bookkeeper_dashboard_ui` | ✅ WDROŻONE |
| **P2** | Automatyzacja korekt deklaracji end-to-end (art. 81 OrdPU + odsetki) | `declaration_correction_automation` | ✅ WDROŻONE |

**Konfiguracja (ADR-002):** blok `automatyzacja_ksiegowosci` w `thresholds_jdg.rego` (ais_pis_api, sca_production, pit_uor_autofill, edelivery_b2b_b2g, ml_cashflow, bookkeeper_dashboard_cfg, declaration_corrections).

**CLI narzędzia:** `--ais-pis`, `--sca-prod`, `--pit-autofill`, `--edelivery-b2b`, `--ml-cashflow`, `--bookkeeper-dashboard`, `--declaration-corrections`, `--roadmap` (wszystkie 7).

## Artefakty

- Rego: `JDG/rules/p18_automatyzacja_ksiegowosci_innovations_v9.rego` (30 reguł + decide + default, 15 INN, 30 podstaw prawnych)
- Narzędzie: `JDG/tools/automatyzacja_ksiegowosci_auditor.py` (audyt ~330 rule_id w 28 plikach + 22 kalkulatorów CLI)
- Testy rego: `JDG/tests/rego/test_p18_automatyzacja_ksiegowosci_enterprise.rego` (42 scenariusze)
- Testy pytest: `JDG/tests/auto/test_p18_automatyzacja_ksiegowosci_enterprise.py` (49 testów)
- Okablowanie: `main_jdg.rego` — import + `_package_decisions` + `final_verdict_p18 = safe_merge(final_verdict_p17, ...)` — bez kolizji ze starym `jdg.p18_innovations` (v8)
