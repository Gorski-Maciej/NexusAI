# P13 — Ryczałt + Cykl Życia JDG (Enterprise)

> **📌 Aktualizacja 2026-08-22:** dokument historyczny opisujący wdrożenie promptu GLM 5.2.
> Raporty źródłowe (`prompty_glm52/`, `raporty_glm52/`, `raporty_jdg_enterprise/`) zostały zarchiwizowane poza repo.
> Aktualny stan wdrożenia: [`KAMPANIA_GLM52_ETAPY_10_28.md`](KAMPANIA_GLM52_ETAPY_10_28.md) + `JDG/bundles/*audit_state.json` (certyfikacja końcowa ETAP 28 — 2026-08-22: 13/14 bramek `NIEPELNY`; domknięcie V4 2026-08-29: `WDROŻONY_100` 6/6).

> Wdrożenie raportu analitycznego **P13_Ryczalt_Cykl_zycia.txt** (v9.4)
> jako działający pakiet rego + narzędzie audytowe + testy + dokumentacja.
> **Priorytet: stawki ryczałtu wg PKWiU (art. 12 ust. 1) i pełny cykl życia JDG.**

## Pakiet rego

**Plik:** `JDG/rules/p13_ryczalt_cykl_zycia_innovations_v9.rego`
**Pakiet:** `jdg.p13_ryczalt_cykl_zycia_innovations`
**Okablowanie:** `main_jdg.rego` — import PAS 18o + `_package_decisions` + `final_verdict_p13`

### Sekcje wdrożone jako reguły

| Sekcja | Reguły | Kluczowe elementy |
|---|---|---|
| **1. Mapa pokrycia** | `ryczalt_coverage_report` | 9 artykułów priorytetowych (a4, a6, a8, a12, a15, a21, a27, a29, a30), status z `data.jdg.p13_audit`, gap_pct |
| **1. STAWEKI RYCZAŁTU ★** | `ryczalt_rates_audit`, `ryczalt_rate_calculator` (INN-01), `wrong_rate_detector` (INN-10) | stawki 3%..25% wg PKWiU (art. 12 ust. 1), limit 2 mln EUR (9 000 000 PLN @4,50), wyłączenia art. 8, ewidencja art. 15, PIT-28 |
| **1. Limit 2M EUR** | `ryczalt_limit_tracker` (INN-02) | tracker limitu w trakcie roku, ostrzeżenie 75%, utrata ryczałtu (art. 6 ust. 4) |
| **2. Karta podatkowa** | `karta_podatkowa_audit` | stawki miesięczne wg tabel, limit zatrudnienia 5, wniosek do US (art. 21-28) |
| **3. CYKL ŻYCIA JDG ★** | `lifecycle_audit`, `lifecycle_assistant` (INN-03) | rejestracja CEIDG → ulga na start (0 zł ZUS, 0-6 mies.) → preferencyjny ZUS 30% (6-30 mies.) → wzrost (VAT 200k, KSeF 2026) → dojrzałość (optymalizacja) → zawieszenie → sukcesja; kalendarz obowiązków |
| **4. Sukcesja** | `succession_audit`, `succession_tracker` (INN-04) | zarządca sukcesyjny (art. 3-7 z.s.), wpis CEIDG 14 dni, NIP "w spadku", **2 lata + przedłużenie do 5 lat** (art. 12-13) |
| **5. Zawieszenia / nieewidencjonowana** | `suspension_audit`, `unregistered_business_audit` (INN-05) | art. 22-25 PP (max 24 mies., ZUS społeczne 0, zdrowotna nadal), art. 6 PP (limit 50% płacy min. = 2 400 PLN) |
| **6. OPA jako system** | `ryczalt_pipeline_snapshot` | pipeline ingest→generate→verify→emit (ADR-002, hot-reload stawek i płacy min.) |
| **7. Genius ideas (17)** | INN-01..INN-17 | kalkulator PKWiU, tracker limitu, asystent cyklu życia, tracker sukcesji, audyt nieewidencjonowanej, **gig economy (DAC7)**, **prokura (art. 18 PP)**, hook, **symulator ryczałt vs skala vs liniowy**, wykrywacz błędnych stawek, audyt CEIDG, panel compliance + **v9.1: asystent zakładania firmy (INN-13), licznik utraty ryczałtu (INN-14), symulator zawiesić/zamknąć (INN-15), sukcesja krok po kroku (INN-16), rekomendacja stawki PKWiU po opisie (INN-17)** |

### Progi ustawowe (ADR-002 — zero hardcode)

Wszystkie progi czytane z `data.jdg.thresholds.ryczalt`:
`limit_eur: 2 000 000` · `eur_rate_pln: 4,50` (→ limit 9 000 000 PLN) · stawki PKWiU 3%..25% · karta podatkowa (limit zatrudnienia 5) · `nieewidencjonowana_limit_pct: 50` · `zawieszenie_max_months: 24` · `succession_months_standard: 24` / `extended: 60` · `ceidg_wpis_days: 7`; płaca minimalna 2026 = 4 800 z `data.jdg.min_wage_2026`

## Narzędzie

**Plik:** `JDG/tools/ryczalt_lifecycle_auditor.py`

- `--audit` — audyt realnych plików: `micro/ryczalt/ryczalt.rego` (156 rule_id, artykuły a4-a30), `micro/plan33_ryc.rego` (159), `micro/pp/pp.rego` (148), `micro/ceidg/ceidg.rego` (43), `micro/sukcesja/sukcesja.rego` (138); pokrycie 9 artykułów priorytetowych, duplikaty, stuby
- `--rate` — auto-kalkulator stawki ryczałtu z kodu PKWiU (sekcje G/C/F/H/I/J/M → stawki)
- `--limit` — tracker limitu 2M EUR (9M PLN)
- `--tax-card` — audyt karty podatkowej
- `--lifecycle` — asystent cyklu życia JDG (fazy, kalendarz obowiązków)
- `--succession` — tracker sukcesji (2 lata / 5 lat)
- `--suspension` — audyt zawieszeń (art. 22-25 PP)
- `--unregistered` — audyt działalności nieewidencjonowanej (50% płacy min.)
- `--compare` — symulator ryczałt vs skala vs liniowy
- `--setup` ★ — asystent zakładania firmy — onboarding CEIDG+NIP+ZUS (INN-13)
- `--loss-detector` ★ — auto-wykrycie utraty ryczałtu — licznik limitu 2M EUR (INN-14)
- `--suspend-or-close` ★ — symulator „zawiesić czy zamknąć" (INN-15)
- `--succession-guide` ★ — sukcesja krok po kroku — checklista prawna (INN-16)
- `--recommend` ★ — inteligentna rekomendacja stawki PKWiU po opisie działalności (INN-17)
- `--table` / `--out FILE`

## Testy

- `JDG/tests/rego/test_p13_ryczalt_cykl_zycia_enterprise.rego` — **36 scenariuszy rego** (27 + 9 nowych dla INN-13..17)
- `JDG/tests/auto/test_p13_ryczalt_cykl_zycia_enterprise.py` — **35 testów pytest** (27 + 8 nowych: funkcje narzędzia v9.1, parser `future.keywords.in/.if`, struktura INN-13..17)

## Nowe innowacje v9.1 (INN-13..17)

| INN | Reguła | Funkcja narzędzia | Wartość biznesowa |
|---|---|---|---|
| **INN-13** | `company_setup_assistant` | `company_setup_assistant(setup_ceidg_done, setup_zus_done)` | Asystent zakładania firmy — onboarding CEIDG+NIP+ZUS+wybór formy (6 kroków, onboarding_pct, TRIAGE_QUEUE) |
| **INN-14** | `ryczalt_loss_detector` | `ryczalt_loss_detector(revenue_ytd, projected_annual_revenue)` | Licznik limitu 2M EUR real-time — warning 75% (6,75M), projected_loss_risk, loss_triggered (art. 6 ust. 4) |
| **INN-15** | `suspend_or_close_simulator` | `suspend_or_close_simulator(planned_months, will_resume)` | Rekomendacja ZAWIESZENIE vs LIKWIDACJA + skutki ZUS/VAT/PIT (art. 22-25 PP) |
| **INN-16** | `succession_step_guide` | `succession_step_guide(months_elapsed)` | Sukcesja krok po kroku — checklista 6 kroków prawnych + 3 formularze, terminy 2/5 lat (art. 3-15 z.s.) |
| **INN-17** | `pkwiu_rate_recommender` | `pkwiu_rate_recommender(activity_description)` | Rekomendacja stawki PKWiU po opisie (handel 3%, budowlana 5,5%, transport 12,5%, gastronomia 15%, IT 12%, architekt 14%, usługi 8,5%) |

Parser: dodane `import future.keywords.in` + `import future.keywords.if` (plik używał if/else bez żadnego importu) — zbalansowany (717 linii, 26 rule_id).

## Mapa drogowa (luki P0/P1/P2)

Wykryte przez realny audyt narzędzia:

| Luka | Priorytet | Opis |
|---|---|---|
| `micro/pp a6` (nieewidencjonowana) | **P1** | Brak reguł micro dla art. 6 PP — pokryte enterprise INN-05 |
| `micro/pp a18` (prokura) | **P1** | Brak reguł micro dla art. 18 PP — pokryte enterprise INN-07 |
| Karta podatkowa micro | **P1** | Reguły a21 istnieją, ale brak szczegółowych tabel stawek per zawód w micro |
| Stawki PKWiU per kod | **P1** | `a12` pokrywa ogólne zasady; mapowanie sekcja→stawka tylko w warstwie enterprise |
| Integracja z bazą PKWiU | **P2** | Pełna baza kodów PKWiU (2-6 cyfr) — obecnie prefiksy sekcji |
| Sukcesja — formularze | **P2** | Generatory wniosków (CEIDG-SU, zawiadomienia) w warstwie enterprise |
| Gig economy — DAC7 | **P2** | Integracja z raportowaniem platform (rok 2026) |

## Raport

`raporty_glm52/raport_enterprise_P13.txt` — pełny raport analityczny ENTERPRISE P13 (9 sekcji: TOP 10, mapa pokrycia, tabela stawek PKWiU, audyt cyklu życia, estoński CIT, CEIDG, Lifecycle Navigator, 17 genialnych pomysłów, roadmapa).

## Status kampanii

**P13 → WDROZONY_100** (v9.4.0-p13) — wpis w `unified_plan_progress.yaml`.
