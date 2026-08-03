# P13 — Ryczałt + Cykl Życia JDG (Enterprise)

> Wdrożenie raportu analitycznego **P13_Ryczalt_Cykl_zycia.txt** (v8.0)
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
| **7. Genius ideas (12)** | INN-01..INN-12 | kalkulator PKWiU, tracker limitu, asystent cyklu życia, tracker sukcesji, audyt nieewidencjonowanej, **gig economy (DAC7)**, **prokura (art. 18 PP)**, hook, **symulator ryczałt vs skala vs liniowy**, wykrywacz błędnych stawek, audyt CEIDG, panel compliance |

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
- `--table` / `--out FILE`

## Testy

- `JDG/tests/rego/test_p13_ryczalt_cykl_zycia_enterprise.rego` — 27 scenariuszy rego
- `JDG/tests/auto/test_p13_ryczalt_cykl_zycia_enterprise.py` — 27 testów pytest (narzędzia, audyt realnych plików, struktura, okablowanie, smoke CLI)

## Mapa drogowa (luki P0/P1/P2)

Wykryte przez realny audyt narzędzia:

| Luka | Priorytet | Opis |
|---|---|---|
| Karta podatkowa micro | **P1** | Reguły a21 istnieją, ale brak szczegółowych tabel stawek per zawód w micro |
| Stawki PKWiU per kod | **P1** | `a12` pokrywa ogólne zasady; mapowanie sekcja→stawka tylko w warstwie enterprise |
| Integracja z bazą PKWiU | **P2** | Pełna baza kodów PKWiU (2-6 cyfr) — obecnie prefiksy sekcji |
| Sukcesja — formularze | **P2** | Generatory wniosków (CEIDG-SU, zawiadomienia) w warstwie enterprise |
| Gig economy — DAC7 | **P2** | Integracja z raportowaniem platform (rok 2026) |

## Raport

`raporty_jdg_enterprise/R13_Ryczalt_Cykl_zycia.txt` — pełny raport wdrożenia P13.
