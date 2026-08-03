# P10 — KKS (Kodeks Karny Skarbowy) Enterprise

Raport źródłowy: `prompts_glm52/P10_KKS.txt`
Status: **WDROŻONY** (raport `raporty_jdg_enterprise/R10_KKS.txt`)

## Pakiet rego: `jdg.p10_kks_innovations`

Plik: `JDG/rules/p10_kks_innovations_v9.rego`

Wdraża wszystkie 8 sekcji promptu jako działające reguły (priorytet: **gradacja kar i minimalizacja ryzyka karno-skarbowego**):

| Sekcja | Reguły | Kluczowe treści |
|---|---|---|
| **1. Mapa pokrycia artykułów KKS** | `kks_coverage_report` | 18 artykułów priorytetowych (a16 czynny żal, a37 recydywa, a44 przedawnienie, a45 zatarcie, a53 mała wartość, a54-a83 czyny), status COMPLETE/PARTIAL/MISSING z `data.jdg.kks_audit` (474 rule_id micro) + `gap_pct` |
| **2. AUDYT GRADACJI KAR ★ PRIORYTET** | `penalty_gradation_audit`, `penalty_calculator` (INN-01), `penalty_minimization_engine` (INN-02), `risk_score_simulator` (INN-03) | Matryca czynów art54-77 (max stawki 720/1080, PW 5-15 lat), **stawka dzienna 1/30 min. wynagrodzenia** (4800/30=160) do **400×** (1 920 000), próg przestępstwa **200×** (960 000), obligatoryjne PW >5M; okoliczności obciążające/łagodzące, recydywa ×2 (art. 37), mała wartość; **kalkulator kary z pełnym uzasadnieniem**; **silnik minimalizacji — 4-ścieżkowy decision tree** (czynny żal / dobrowolne poddanie / ugoda / obrona); **symulator ryzyka** (score → LOW/HIGH/CRITICAL) |
| **3. Czynny żal (art. 16) i dobrowolne poddanie się (art. 17)** | `voluntary_disclosure_audit`, `voluntary_disclosure_assistant` (INN-04) | Warunki art. 16 (zawiadomienie przed wykryciem, ujawnienie okoliczności, zapłata), wyłączenia (kontrola rozpoczęta), **asystent „czy warto złożyć czynny żal"** z krokami |
| **4. Przedawnienie (art. 44) i zatarcie (art. 45)** | `limitation_calendar`, `conviction_expungement_tracker` (INN-05) | Przestępstwo 5 lat / wykroczenie 3 lata, interakcja z art. 70 OrdPU; **tracker zatarcia** (grzywna 1 rok, ograniczenie wolności 3 lata, PW 5 lat), wpływ na kontrakty i pozwolenia |
| **5. Spójność micro ↔ macro i duplikaty** | `kks_duplicate_report`, `kks_dead_rule_detector` (INN-06) | Realny audyt 474 rule_id micro/kks (duplikaty, stuby `{ true }`, martwe reguły), MANIFEST 369 duplikatów |
| **6. OPA jako system** | `kks_pipeline_snapshot`, `kks_sanction_auto_updater` (INN-11) | Pipeline ingest→generate→verify→emit (ADR-002), hot-reload, auto-aktualizacja sankcji i progów przy nowelizacjach KKS |
| **7. Genius ideas (12)** | INN-01..INN-12 | Kalkulator kary, silnik minimalizacji, symulator ryzyka, asystent czynnego żalu, tracker zatarcia, detektor martwych reguł, **tarcza prewencyjna** (INN-07), **detektor recydywy** (INN-08), **ocena małej wartości** (INN-09), **panel ryzyka per obszar** (INN-10), hook auto-aktualizacji (INN-11), **generator wniosku o dobrowolne poddanie się** (INN-12) |
| **8. Mapa drogowa** | — | W raporcie R10 — luki P0/P1/P2 z szacunkiem czasu naprawy |

### Dane temporalne (ADR-002)
Wszystkie progi czytane z `data.jdg.thresholds.kks` z domyślnymi (min. wynagrodzenie 4800, mianownik 30, mnożniki 400×/200×, progi 720/240 stawek, 5M obligatoryjne PW, przedawnienia 5/3 lata) — **zero hardcode w regułach**.

## Podpięcie (main_jdg.rego)
- Import: `import data.jdg.p10_kks_innovations` (PAS 18k)
- `_package_decisions["jdg.p10_kks_innovations"] = p10_kks_innovations.decide`
- `final_verdict_p10 = safe_merge(final_verdict_p09, safe_merge(p10_kks_innovations.decide, fallback.decide))`
- Pakiety REPORT-owe — nie nadpisują decyzji (safe_merge: final_verdict_p09 ma priorytet)

## Narzędzie: `JDG/tools/kks_penalty_auditor.py`
- `--audit` — audyt realnych plików `micro/kks/kks.rego` (13 373 linie, 474 rule_id, prefiks `jdg.micro.kks.a{N}.r{M}`) + `plan33_kks.rego`; pokrycie artykułów a16-a83, duplikaty, stuby, martwe reguły
- `--penalty` — kalkulator kary (stawki dzienne, grzywna min/max, recydywa, uzasadnienie)
- `--minimization` — silnik minimalizacji (4-ścieżkowy)
- `--risk` — symulator ryzyka karno-skarbowego
- `--disclosure` — asystent czynnego żalu
- `--limitations` — kalendarz przedawnień
- `--conviction` — tracker zatarcia
- `--table` / `--out FILE`

## Testy
- `JDG/tests/rego/test_p10_kks_enterprise.rego` — 16 scenariuszy rego
- `JDG/tests/auto/test_p10_kks_enterprise.py` — 21 testów pytest

## Walidacja
- Pełny zestaw P01-P10: pytest + py_compile + smoke CLI + code review (code-reviewer-glm)
