# HANDOFF V3 — PO P66 → START P67 (CZYSTA SESJA)

Data: 2026-09-16 | Kampania: **67/69 = 97.10%** | Następny nie wdrożony: **P67 SELF_LEARNING**

## Co się wydarzyło (P66 CHAOS_ODPORNOSC)
- Status: **WDROŻONY_100** (ledger `bundles/v3_campaign_ledger.json`; luki P0=0/P1=1/P2=3/P3=3; 12 innowacji).
- Raport: `JDG/raporty_glm52_v3/RAPORT_V3_P66_CHAOS_ODPORNOSC.txt` (sekcje 9.01–9.18).
- Run-all: `python3 tools/v3_p66_run_all.py` → engines=12 rego=PASS gate=PASS; chaos_runner gate (P18) 8/8 PASS.

## Struktury OPA dodane w P66
- `rules/v3_p66_chaos_resilience.rego` — 12 analiz I01–I12 + router else-chain (priorytety 466001–466012), fail-closed: brak snapshotu = NEEDS_ADVICE, brak flagi `v3_p66_check` = NO_MATCH, zero AUTO_POST.
- `rules/thresholds_jdg.rego` — blok `v3_p66`: threshold_version chaos-resilience-v3p66-2026.09 + legal_basis_version + 9 kluczy ADR-002 + valid_from 2026-01-01 (steady_state_metrics_min=4, card_sections_required, dependency_failure_modes=[timeout,error,halt], dependency_combinations_min=12, chaos_day_cadence=monthly, auto_rollback_sla_min=5, maturity_levels L1–L5, resilience_min_pct=80).
- `rules/main_jdg.rego` — wiring `final_verdict_p130 = safe_merge(final_verdict_p129, v3_p66_chaos_resilience.decide, fallback.decide)`; **POST-MERGE anchor = p130**.
- Mirrory `policies/` — hash-parity (p66, p65, thresholds, main).

## Artefakty dowodowe (silniki czytają PRAWDZIWE źródła)
- `tools/v3_p66_experiment_cards.json` — **12 kart eksperymentów jako dane** (schema jdg.v3_p66.experiment_cards.v1): każda karta = hipoteza + kroki + asercje (obowiązkowa `no_silent_auto_post`) + rollback + metryki P58 + blast radius + ci_runnable + kill_switch.
- `tools/v3_p66_{common,engines,run_all,rego_static_gate}.py`; 13 bundli `bundles/v3_p66_*.json`.
- Kompozycje (zero duplikacji): chaos_runner P18 (gate 8/8 — wykonawca), chaos_engineering (12 mutacji), P43 drill (gate PASS), P49 (12 scenariuszy), P57 (8/8), P65-I08 WORM (5/5), P65-I09 (196 mutacji), P07 kill switch SLA, deployments.json (44 wdrożenia: 24 fail_closed, 7 armed, 0 production_active), healthy_versions P38, P58 error budget/advice spread, P64 sweep register (feed napraw), self_healing 4-eyes, digital twin P33 (peak-time), dr_orchestrator, health_tier, rule_impact, verify_verdict_invariants.
- Wyniki: resilience_pct=100 (próg 80), kombinacje zależności=21 (próg 12), maturity L3, przełamania fail-closed=0, 10/12 eksperymentów CI-runnable (EX-09 peak, EX-12 game day poza CI z kill switchem).
- **Luka P07 package_suspend=false DOMKNIĘTA**: wyłącznik eksperymentów jako pole karty (dane) + bramka Rego I04 BLOCK.

## Testy (wszystkie zielone)
- pytest P66: `tests/auto/test_v3_p66_chaos_resilience.py` → 23 passed.
- Rego natywnie: **19/19 PASS** (OPA 0.68.0; kontrakt C2 z P65) + bramka statyczna PASS (testy=19, klucze 12/12).
- Regresja: `pytest -k "v3_p5 or v3_p6"` → **495 passed** (472 + 23 P66; kotwice POST-MERGE p129→p130 zaktualizowane w 11 plikach testowych P55–P65; uwaga na dosłowne `\n` przy masowych regexach — lesson: używać `\\n` w replacementach).

## Konwencja (stała, P51→P66)
1. Wybór: pierwszy NIE_WDROŻONY z `python3 tools/v3_campaign_ledger.py` → obecnie **P67 SELF_LEARNING**; prompt: `JDG/prompty_v3/V3_PROMPT_P67_*.txt`.
2. Progi: blok `v3_p67` w `rules/thresholds_jdg.rego` (ADR-002, valid_from), NIE hardcode.
3. Rego: `rules/v3_p67_*.rego` — 12 analiz + router else-chain, priorytety 467001–467012, fail-closed (brak snapshotu → NEEDS_ADVICE; brak flagi `v3_p67_check` → NO_MATCH; zero AUTO_POST).
4. Wiring: `final_verdict_p131 = safe_merge(final_verdict_p130, …)` + POST-MERGE anchor p130→**p131** + aktualizacja kotwic w testach P55–P66 + mirrory `policies/` (hash-parity sha256!).
5. Silniki: `tools/v3_p67_{common,engines,run_all}.py` czytają PRAWDZIWE źródła/bundle bramek; zero fikcyjnych liczeń.
6. Testy: pytest `tests/auto/test_v3_p67_*.py` + Rego `tests/rego/test_v3_p67_*.rego` — **natywne opa test OBOWIĄZKOWY** (kontrakt C2; runner faza 3); regresja `pytest -k "v3_p5 or v3_p6"` (kotwica p131!).
7. Raport `RAPORT_V3_P67_*.txt` (sekcje 9.01–9.18) → `--mark P67 --luki-p0..p3 --innovations 12 --notes … --write` → `HANDOFF_V3_P67.md`.
8. Rego pułapki (naprawiane w P65/P66): unsafe_var = zmienna w `reason/metrics` musi mieć definicję w body (też gałąź else!); comprehension `[c.id | some i; c := list[i]]` (nie `some c := ...` w OPA 0.68); `object.union` = deep merge → nadpisanie zagnieżdżonego kontekstu wymaga `object.remove`.

## Jawne luki przeniesione z P66 (naturalny materiał wejściowy dla P67 SELF_LEARNING)
- **V3-P66-L01 (P3, otwarta → Q03): chaos_runner gate + resilience_pct NIE SĄ w workflow CI** (skan .github/workflows = zero trafień) — podpięcie = decyzja właściciela CI; P67 może użyć resilience_pct jako metryki pętli uczenia.
- V3-P66-L07 (P1, przeniesiona z P65-L07 → P68): 212 rego nieimportowanych + 87 reguł bez testu — decyzje per plik 4-eyes (Q02 P64).
- V3-P66-L08 (P3, → P68): 6 podstaw prawnych [NIEZWERYFIKOWANE — ISAP] — weryfikacja w P68 (isap_crawler P34-I03).
- Kontrakty wyjściowe P66: C1 katalog eksperymentów (P68/P43/V4), C2 program chaos ciągły (chaos day monthly + resilience_pct kwartalnie → P68), C3 kill switch obowiązkowy (poza CI = BLOCK), C4 natywne opa test (z P65), C5 macierz zależności jako dane (nowa integracja = wiersz + karta), C6 silniki z bundli bramek (z P65).
- Pytania otwarte (4-eyes): Q01 chaos gate w CI, Q02 pakietowy kill switch P07, Q03 częstotliwość chaos day, Q04 okno godzinowe game day.

## Materiał dla P67 SELF_LEARNING (kontrakt 11.1)
- Pętla uczenia: luki z chaos (I09 feed) + rejestry napraw P64 + adoption metrics P65-I11 + resilience trend P66-I10 + advice spread P58 + ledger adopcji rekomendacji (P29/parts_j).
- Pytania z kampanii: „Czy override człowieka jest nagrywany z powodem i wraca do pętli jakości?" — sprawdzić decision certificate/certainty flow w main_jdg (runtime_invariants).

## Następna sesja
Start WYŁĄCZNIE z tego pliku → `python3 tools/v3_campaign_ledger.py` → P67 SELF_LEARNING → wdróż 12 innowacji wg konwencji powyżej (P67 = pętla samouczenia — kompozycja z I09 feed, P64 naprawy, P65 adoption, P58 metryki; nie duplikuj) → oznacz → HANDOFF_V3_P67 → czyste okno dla P68.
