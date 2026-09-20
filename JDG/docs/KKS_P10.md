# P10 — KKS (Kodeks Karny Skarbowy) Enterprise

> **📌 Aktualizacja 2026-08-22:** dokument historyczny opisujący wdrożenie promptu GLM 5.2.
> Raporty źródłowe (`prompty_glm52/`, `raporty_glm52/`, `raporty_jdg_enterprise/`) zostały zarchiwizowane poza repo.
> Aktualny stan wdrożenia: [`KAMPANIA_GLM52_ETAPY_10_28.md`](KAMPANIA_GLM52_ETAPY_10_28.md) + `JDG/bundles/*audit_state.json` (certyfikacja końcowa ETAP 28 — 2026-08-22: 13/14 bramek `NIEPELNY`; domknięcie V4 2026-08-29: `WDROŻONY_100` 6/6).

Kampania: `prompty_glm52/10_PROMT_KKS_SANKCJE.txt`
Raport: `raporty_glm52/RAPORT_07_KKS.txt`
Status: **BLOCKED_BY_EVIDENCE** (8/9 bramek; 2026-08-12)
Dowód: `bundles/kks_report07_evidence.json` + `tools/kks_report07_gate.py --strict`

## Pakiet rego: `jdg.p10_kks_innovations`

Plik: `JDG/rules/p10_kks_innovations_v9.rego` (595 linii, 16 INN)

Wdraża wszystkie sekcje promptu jako działające reguły (priorytet: **gradacja kar i minimalizacja ryzyka karno-skarbowego**):

| Sekcja | Reguły | Kluczowe treści |
|---|---|---|
| **1. Mapa pokrycia artykułów KKS** | `kks_coverage_report` | 18 artykułów priorytetowych (a16 czynny żal, a37 recydywa, a44 przedawnienie, a45 zatarcie, a53 mała wartość, a54-a83 czyny), status COMPLETE/PARTIAL/MISSING z `data.jdg.kks_audit` (474 rule_id micro) + `gap_pct` |
| **2. AUDYT GRADACJI KAR ★ PRIORYTET** | `penalty_gradation_audit`, `penalty_calculator` (INN-01), `penalty_minimization_engine` (INN-02), `risk_score_simulator` (INN-03) | Matryca czynów art54-77 (max stawki 720/1080, PW 5-15 lat), **stawka dzienna 1/30 min. wynagrodzenia** (4800/30=160) do **400×** (1 920 000), próg przestępstwa **200×** (960 000), obligatoryjne PW >5M; okoliczności obciążające/łagodzące, recydywa ×2 (art. 37), mała wartość; **kalkulator kary z pełnym uzasadnieniem**; **silnik minimalizacji — 4-ścieżkowy decision tree**; **symulator ryzyka** (score → LOW/HIGH/CRITICAL) |
| **3. Czynny żal (art. 16) i dobrowolne poddanie się (art. 17)** | `voluntary_disclosure_audit`, `voluntary_disclosure_assistant` (INN-04), `voluntary_submission_generator` (INN-12) | Warunki art. 16 (zawiadomienie przed wykryciem, ujawnienie okoliczności, zapłata), wyłączenia (kontrola rozpoczęta), **asystent „czy warto złożyć czynny żal"**, **generator wniosku o dobrowolne poddanie się** |
| **4. Przedawnienie (art. 44) i zatarcie (art. 45)** | `limitation_calendar`, `conviction_expungement_tracker` (INN-05) | Przestępstwo 5 lat / wykroczenie 3 lata, interakcja z art. 70 OrdPU; **tracker zatarcia** (grzywna 1 rok, ograniczenie wolności 3 lata, PW 5 lat), wpływ na kontrakty i pozwolenia |
| **5. Spójność micro ↔ macro i duplikaty** | `kks_duplicate_report`, `kks_dead_rule_detector` (INN-06) | Realny audyt 474 rule_id micro/kks (duplikaty, stuby `{ true }`, martwe reguły) |
| **6. OPA jako system** | `kks_pipeline_snapshot`, `kks_sanction_auto_updater` (INN-11) | Pipeline ingest→generate→verify→emit (ADR-002), hot-reload, auto-aktualizacja sankcji i progów przy nowelizacjach KKS |
| **7. Genius ideas (16)** | INN-01..INN-16 | Kalkulator kary, silnik minimalizacji, symulator ryzyka, asystent czynnego żalu, tracker zatarcia, detektor martwych reguł, tarcza prewencyjna (INN-07), detektor recydywy (INN-08), ocena małej wartości (INN-09), panel ryzyka per obszar (INN-10), hook auto-aktualizacji (INN-11), generator wniosku (INN-12), **symulator co-jeśli korekta vs sankcja (INN-13)**, **gotowość na kontrolę skarbową (INN-14)**, **odpowiedzialność powiązana (INN-15)**, **przewidywacz wyroków NSA/WSA (INN-16)** |
| **8. Mapa drogowa** | — | W raporcie R10 — pokrycie art. 54-83 → symulator kar → czynny żal → przedawnienia → fraud — wszystkie domknięte |

### Dane temporalne (ADR-002)
Wszystkie progi czytane z `data.jdg.thresholds.kks` z domyślnymi (min. wynagrodzenie 4800, mianownik 30, mnożniki 400×/200×, progi 720/240 stawek, 5M obligatoryjne PW, przedawnienia 5/3 lata) — **zero hardcode w regułach**.

## Podpięcie (main_jdg.rego)
- Import: `import data.jdg.p10_kks_innovations` (PAS 18k)
- `_package_decisions["jdg.p10_kks_innovations"] = p10_kks_innovations.decide`
- `final_verdict_p10 = safe_merge(final_verdict_p09, safe_merge(p10_kks_innovations.decide, fallback.decide))`
- Pakiety REPORT-owe — nie nadpisują decyzji (safe_merge: final_verdict_p09 ma priorytet)

## Warstwa reguł wspierająca
- `rules/kks.rego` — 256 rule_id (P23-P27 grzywna, P255-P269 art. 56, P270-P279 art. 57, P300-P319 art. 62)
- `rules/micro/kks/kks.rego` — 474 rule_id (atomowe per artykuł a16-a86)
- `rules/micro/plan33_kks.rego` — 65 rule_id
- `rules/kks/enterprise_penalties.rego` — 22 rule_id (symulacja kar i sankcji)
- `rules/kks/kks_innovations_v8.rego` — 14 rule_id
- `rules/p10_kks_micro_innovations_v8.rego` — 12 rule_id
- `rules/sanctions_optimization_enterprise.rego` — 5 rule_id (S23-500/600/700)
- `rules/penalty_ai_enterprise.rego` — jdg.enterprise.penalty_ai (scoring sukcesu ścieżek A-E)
- `rules/conviction_checker_enterprise.rego` — jdg.enterprise.conviction_checker (KRK, zatarcie, PZP)

## Narzędzia (12)
- `tools/kks_penalty_auditor.py` — `--audit` (474 rule_id, pokrycie a16-a83), `--penalty`, `--minimization`, `--risk`, `--disclosure`, `--limitations`, `--conviction`, `--table`
- `tools/kks_penalty_simulator.py`, `kks_risk_scorer.py`, `kks_voluntary_disclosure.py`, `kks_limitations_calendar.py`, `kks_completeness_matrix.py`
- `tools/p10_kks_jurisprudence.py`, `p10_kks_micro_simulator.py`, `p10_kks_micro_toolkit.py`, `p10_kks_proactive_shield.py`, `p10_kks_test_generator.py`

## Testy
- `JDG/tests/auto/test_p10_kks_enterprise.py` — 25 testów pytest (w tym parser `future.keywords.if`, INN-13..16, raport)
- `JDG/tests/rego/test_p10_kks_enterprise.rego` — 24 scenariusze natywne (16 + 8 dla INN-13..16)
- `JDG/tests/test_kks_enterprise.py` — testy KKS enterprise

## Walidacja (2026-08-09)
- Historycznie: pytest P01+P02+P03+PKPiR/UoR: **113/113**; obecna walidacja P10: **46/47** (stary alias raportu zastąpiony kanonicznym raportem 07; bramka dowodowa pozostaje fail-closed).
- Parser Rego: balanced braces, `import future.keywords.if` obecny
- Bundle OPA: **446 plików** (bundle.sh v9.0, SBOM)
- Spójność międzyczęściowa: P04 (fraud VAT) · P09 (art. 56 PKPiR) · P11 (Ordynacja) · P17 (KSeF sankcje) · P13 (sukcesja) · P03 (orkiestrator PAS 18k)
