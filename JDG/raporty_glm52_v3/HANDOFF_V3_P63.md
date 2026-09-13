# HANDOFF V3 — PO P63 → START P64 (CZYSTA SESJA)

Data: 2026-09-13 | Kampania: **64/69 = 92.75%** | Następny nie wdrożony: **P64 LUKA_SWEEP**

## Co się wydarzyło (P63 RBAC, MULTI-TENANT I DANE)
- Status: **WDROŻONY_100** (ledger `bundles/v3_campaign_ledger.json`; luki P0=0/P1=1/P2=2/P3=2; 12 innowacji).
- Raport: `JDG/raporty_glm52_v3/RAPORT_V3_P63_RBAC_MULTITENANT.txt` (sekcje 9.01–9.17, T1–T16).
- 12/12 bramek: `python3 tools/v3_p63_run_all.py` → gate=PASS.

## Struktury OPA dodane w P63
- `rules/v3_p63_rbac_multitenant_closure.rego` — 12 analiz I01–I12 + router else-chain (priorytety 463001–463012), fail-closed, zero AUTO_POST.
- `rules/thresholds_jdg.rego` — blok `v3_p63`: threshold_version + 12 kluczy ADR-002 (roles_required 4 role, sod_required, cross_tenant_leaks_max=0, breakglass_review, access_audit_anomalies [night/mass/repeat], erasure_retention_years=5, quota 500/h, dataflow_channels_min=6, privacy_mode=pseudonymized, multitenant_tables_min=1, drift_alarm, onboarding_required), valid_from 2026-01-01.
- `rules/main_jdg.rego` — wiring `final_verdict_p127 = safe_merge(final_verdict_p126, v3_p63_rbac_multitenant_closure.decide, fallback.decide)`; **POST-MERGE anchor = p127**.
- Mirrory `policies/`: hash-parity 4/4 (p63, p62, thresholds, main).
- `docs/ROLE_MAPS.md` — **rozszerzony** o sekcje ACCOUNTANT (ścieżka księgowa) i ADMIN (ścieżka operacyjna) + zasada onboardingu roli (P63-I12).

## Artefakty dowodowe (silniki czytają PRAWDZIWE źródła)
- `tools/v3_p63_{common,engines,run_all}.py`; 13 bundli `bundles/v3_p63_*.json`.
- Źródła wykorzystane (rozszerzone, nie zdublowane): v3_p40_rbac_minimization, v3_p40_api_audit_worm, v3_p57_tenant_isolation + rate_governor, v3_p58_privacy + escalation, v3_p42_retention_calculator, v3_p33_federated_privacy_guard, v3_p44_owner_attestation, v3_p47_human_stamps, v3_p25_tenant_calendar, v3_p60_role_maps, rules/rodo_extended.rego (P1640 erasure art. 17/19 RODO + wyjątek art. 74 UoR), migrations/*.sql (tenant_id w 001+002), rodo_register_generator.py.
- Lekcje techniczne (kopiuj do kolejnych części): read_threshold string-aware (P62); Rego MUSI odwoływać się wprost do progów ADR-002 w każdej analizie (test no-hardcode to wymusza); heurystyki dopasowania ról = regex nagłówków `## ROLA`, nie prefix.

## Testy (wszystkie zielone)
- pytest P63: `tests/auto/test_v3_p63_rbac_multitenant_closure.py` → 22 passed.
- Rego: `tests/rego/test_v3_p63_rbac_multitenant_closure.rego` → 18 testów (walidacja statyczna — opa CLI niedostępny; nawiasy OK, klucze Rego↔testy 1:1).
- Regresja: `pytest -k "v3_p5 or v3_p6"` → **429 passed** (kotwice p126→p127 zaktualizowane w P55–P62).

## Konwencja (stała, P51→P63)
1. Wybór: pierwszy NIE_WDROŻONY z `python3 tools/v3_campaign_ledger.py` → obecnie **P64 LUKA_SWEEP**; prompt: `JDG/prompty_v3/V3_PROMPT_P64_*.txt`.
2. Progi: blok `v3_p64` w `rules/thresholds_jdg.rego` (ADR-002, valid_from), NIE hardcode w Rego.
3. Rego: `rules/v3_p64_*.rego` — 12 analiz + router else-chain, priorytety 464001–464012, fail-closed (brak snapshotu → NEEDS_ADVICE; brak flagi `v3_p64_check` → NO_MATCH; zero AUTO_POST).
4. Wiring: `final_verdict_p128 = safe_merge(final_verdict_p127, …)` + POST-MERGE anchor p127→**p128** + aktualizacja kotwic w testach P55–P63 + mirrory `policies/` (hash-parity!).
5. Silniki: `tools/v3_p64_{common,engines,run_all}.py` czytają PRAWDZIWE źródła (luki z ledgera: `--json` ma pole luki per część; rejestry luk w raportach `RAPORT_V3_P*_*.txt` sekcja 9.06/REJESTR LUK); zero fikcyjnych bramek.
6. Testy: pytest `tests/auto/test_v3_p64_*.py` + Rego `tests/rego/test_v3_p64_*.rego`; regresja `pytest -k "v3_p5 or v3_p6"`.
7. Raport `RAPORT_V3_P64_*.txt` (sekcje 9.01–9.17, T1–T16) → `--mark P64 --luki-p0..p3 --innovations 12 --notes … --write` → `HANDOFF_V3_P64.md`.
8. Kotwice w testach starszych części: P60/P61/P62/P63 — każda ma asercję POST-MERGE do aktualizacji przy p128.

## Jawne luki przeniesione z P63 (naturalny materiał wejściowy dla P64 LUKA_SWEEP)
- P1: podpis właściciela 4-eyes (P44: signed=false, reservations=2) — krok ludzki.
- P2: analiza anomalii audytu bez feedu zdarzeń runtime; art. 17/20 bez CLI wykonawczego end-to-end.
- P3: tenant_id w 2/8 migracji SQL (plan migracji pozostałych tabel); break-glass bez odrębnych ról awaryjnych.
- Także z P62: UI prognozy cashflow (P40), SMTP przypomnień, feed przychodów rzeczywistych, rejestry profili bankowych, CLI scenariuszy.

## Następna sesja
Start WYŁĄCZNIE z tego pliku → `python3 tools/v3_campaign_ledger.py` → P64 LUKA_SWEEP → wdróż 12 innowacji wg konwencji powyżej (P64 = zbieranie i domykanie luk z całej kampanii — ledger i rejestry luk raportów P00–P63 są źródłem) → oznacz → HANDOFF_V3_P64 → czyste okno dla P65.
