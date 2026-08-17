# 📊 STATUS KAMPANII GLM 5.2 — FORTYFIKACJA MODUŁU JDG (ENTERPRISE)

> Aktualizacja: 2026-08-16 | Metoda: każdy Prompt → RAPORT → wdrożenie → bramki → WDROZONY_100 → następny.

## Postęp kampanii

| # | Prompt | Raport | Status | Bramki po wdrożeniu | Uwagi |
|---|--------|--------|--------|---------------------|-------|
| 01 | PROMPT_01_ORKIESTRATOR_FUNDAMENT | RAPORT_GLM52_P01_ORKIESTRATOR_FUNDAMENT.txt | ✅ **WDROZONY_100** | validate: 0 błędów (z 453) · invariant CI: PASS (42 INV) · lint 5/6 (backlog domenowy) · pytest 87/87 | Backlog: 5 888 literałów domenowych → P02-P19 (mapa w raporcie §7) |
| 02 | PROMPT_02_VAT_MAKRO | RAPORT_GLM52_P02_VAT_MAKRO.txt | ✅ **WDROZONY_100** | validate: 0 błędów · invariant CI: PASS (42 INV) · lint VAT: 0 literałów (ADR-002) · verify_vat_mpp: 7/7 · vat_gap_detector: 32✅/2⚠️/0❌ · RAPORT_21: 6/6 · pytest VAT: 122/122 + P01: 87/87 | Nowe: a113_limit_monitor, mpp_monitor.py, vat_rate_engine.py, test_native_vat_mpp/a113 (14 testów rego), +10 pytest; 11 nowych progów VAT w thresholds |
| 03 | PROMPT_03_VAT_MIKRO_JPK | RAPORT_GLM52_P03_VAT_MIKRO_JPK.txt | ✅ **WDROZONY_100** | validate: 0 błędów · invariant CI: PASS (42 INV) · RAPORT_21: 6/6 · verify_vat_micro_atomic: P0 zamknięte · opa check jpk: EXIT 0 · lint P03: 0 literałów · pytest P03: 336/336 + regresja P01/P02: 112/112 | KONFLIKT KOMPILACJI naprawiony (jdg.micro.jpk ×2 default → plan33 podpakiet); warstwa mikro wpięta (PAS 43: mikro VAT+JPK); WIS 42a-42h (+8 reguł); jpk_validator.py + jpk_generator.py; stub summary → flaga; test_native_vat_micro/jpk (17 testów); +16 pytest |
| 04 | PROMPT_04_KSEF_JPK_EDEKLARACJE | RAPORT_GLM52_P04_KSEF_JPK_EDEKLARACJE.txt | ✅ **WDROZONY_100** | validate: 0 błędów · invariant CI: PASS (42 INV) · RAPORT_21: 6/6 · lint P04: 0 literałów · pytest P04: 122/122 + regresja P01–P03: 156/156 | KONFLIKT KOMPILACJI naprawiony (jdg.micro.ksef ×2 default → plan33 podpakiet, 75 pól); 16 nowych progów KSeF/JPK/WIS/eD w thresholds (ADR-002); 4 nowe narzędzia: ksef_outbox.py (exactly-once+retry+UPO), ksef_offline_queue.py (OFL+168h/120h+ZAW-NR), jpk_autogen.py (e-Deklaracje zero-ręki+3-drożny verify), edelivery_monitor.py (EDE+fiction 15d+WORM 5l); test_native_ksef/wis (10 testów); +7 pytest; test_r15 zaktualizowany (PAS 43) |
| 05 | PROMPT_05_PIT_MAKRO | RAPORT_GLM52_P05_PIT_MAKRO.txt | ✅ **WDROZONY_100** | validate: 0 błędów · invariant CI: PASS (42 INV) · RAPORT_21: 6/6 · lint PIT: 0 literałów · pytest P05: 39/39 + PIT regresja (p06+r04+r05): 96/96 + regresja P01–P04: 244/244 + wiring r01–r17: 199/199 | PAS 44: warstwa MIKRO PIT wpięta (3× default → plan33/plan34 podpakiet); 5 nowych reguł trigger-owych: what_if_recommendation (INN-06), grosz_rounding art. 63 OrdPU (INN-03), quarterly_due_dates (INN-07), annual_limits_monitor (INN-04), shared_limit_monitor PIT-0 (INN-05); 6 nowych progów thresholds; pit_annual_engine v2 (degresja art. 27 + PIT-28 per PKWiU + settlement, INN-02/08/09/10) + form_simulator v2 (simulate_3y + health_impact, INN-01/12); test_native_pit_advances/exemptions (14 testów) + forms/kup (+6); NAPRAWY: składnia exemptions.rego (brak else:= + 2× extra brace), guard what_if_scale_tax, stale wiring p42/p43→p44 (17 plików), 4 pliki z niezbalansowanymi nawiasami (ksef_jpk, ksef_offline_queue, plan33_tax_trans, poa_manager) |
| 06 | PROMPT_06_PIT_MIKRO_AMORTYZACJA | RAPORT_GLM52_P06_PIT_MIKRO_AMORTYZACJA.txt | ✅ **WDROZONY_100** | validate: 0 błędów (396 plików/11 410 reguł) · invariant CI: PASS (42 INV) · RAPORT_21: 6/6 · lint P06: 0 literałów · pytest P06-GLM52: 32/32 + P06: 15/15 + regresja P01/P03/P05/KSeF: 203/203 + wiring r01–r17: 291/291 · inventory: 0 duplikatów/0 stubów, tautologie 10→6 | PAS 45: warstwa AMORTYZACJI MIKRO wpięta (a22a/a22b/a22c/a22h/a22i/a22k/a22n — 7 pakietów, final_verdict_p45); NAPRAWA: usunięte fallbacki else {true} przejmujące no_match (INV-018, wzorzec P03-P05); NOWE pakiety: art. 22b WNiP / 22c wyłączenia / 22h zasady odpisów+invariant F2; korekta _legal_basis (degresywna = art. 22k); KŚT komplet 0-10 (kst_groups + thresholds.kst_rates); NOWE narzędzia: depreciation_engine.py (harmonogramy/limity/grosze) + nkup_classifier.py (wydatek→art. 23); 8 nowych progów thresholds; test_native_amortyzacja (18) + test_native_pit_micro (5) + pytest 32; usunięty uszkodzony test_native_micro_amortyzacja |
| 07 | PROMPT_07_ULGI_OPTYMALIZACJA | RAPORT_GLM52_P07_ULGI_OPTYMALIZACJA.txt | ✅ **WDROZONY_100** | validate: 0 błędów · invariant CI: PASS (42 INV) · RAPORT_21: 6/6 · lint 5/5 (matched/fallback/rule_id/legal_basis/temporal) · pytest P07-GLM52: 37/37 + P05/P06: 108/108 + regresja P01–P04: 67/67 + wiring r01–r17: 270/270 + P06-pytest: 68/68 | NOWE narzędzia (wymagane w PROMPT 07): relief_detector.py (13 ulg, Trust Score, dowód, tryb --txn), ipbox_nexus_calculator.py (nexus art. 30ca z dowodem), brd_project_tracker.py (karty projektów 26e ust. 2 pkt 1-5, 100/200%, ryzyka), estonian_cit_simulator.py (3-letnia prognoza PIT vs estoński CIT, 10/20%, limit 2M EUR); NOWA reguła jdg.pit.missing_reliefs.prototype (art. 26eb, 30%) — domknięcie pustyni pokrycia; thermo z data.thresholds (pit_thermo_limit 53 000, koniec hardcode); +2 progi thresholds; test_native_reliefs.rego (13 testów) + pytest 37; okablowanie 8 pakietów ulg potwierdzone (importy+rejestr+safe_merge) |
| 08 | PROMPT_08_ZUS_MAKRO_ZDROWOTNA | RAPORT_GLM52_P08_ZUS_MAKRO_ZDROWOTNA.txt | ✅ **WDROZONY_100** | validate: 0 błędów · invariant CI: PASS (42 INV) · RAPORT_21: 6/6 · lint 5/5 (matched/fallback/rule_id/legal_basis/temporal) · pytest P08-GLM52: 37/37 + ZUS regresja (p07+p08+block+r06): 132/132 + P01–P07: 138/138 + wiring r01–r17: 275/275 | NOWA reguła jdg.zus.health.tier_switch (art. 81 ust. 2e-2f u.ś.o.z., H160): miesięczna re-ewaluacja progu ryczałtu na podstawie przychodu narastająco, progi z data.thresholds, alert zmiany TIER; NOWE narzędzia: zus_calculator.py (składki z dowodem groszowym: 19,52/8/2,45/1,67% + zdrowotna per forma, invariant Σ), health_tier_engine.py (progi ryczałtu 60k/300k, korekta roczna do 22 maja, monitor 14 100 zł liniowy, predyktor), zus_calendar.py (terminy 5/10/15/20 art. 47 SUS + przesunięcie weekend, roczne rozliczenie 22 maja); ulgi składkowe w kalkulatorze (start 18a / preferencyjna 18c ust. 2 / Mały ZUS+ 18c ust. 4-5 z clampem i limitem 120k); test_native_zus_macro.rego (10 testów) + pytest 37; niemutowalność werdyktów ZUS potwierdzona (allowlist: jdg.zus + 3 pakiety) |
| 09–19 | (jak w 00_README_PROMPTOW.md §2) | — | ⏳ | — | — |

## Weryfikacja końcowa po wdrożeniu P03 (komendy)

```bash
cd JDG
python3 tools/validate_rules.py                 # Błędów: 0
python3 tools/invariant_checker.py ci           # PASS — 42 niezmienniki
python3 tools/native_rego_report21_gate.py      # WDROZONY_100 (6/6)
python3 tools/verify_vat_micro_atomic.py        # WSZYSTKIE BRAMKI P0 ZAMKNIĘTE
python3 -m pytest tests/auto/test_p04_vat_micro_enterprise.py tests/auto/test_r03_vat_micro_enterprise.py tests/auto/test_vat_audyt_r03_enterprise.py tests/auto/test_auto_block_micro.py -q  # 336 passed
python3 -m pytest tests/test_p01_control_plane.py tests/test_p02_legal.py tests/test_p03_orchestrator_enterprise.py -q  # 112 passed (regresja)
```

## Weryfikacja końcowa po wdrożeniu P02 (komendy)

```bash
cd JDG
python3 tools/validate_rules.py                 # Błędów: 0
python3 tools/invariant_checker.py ci           # PASS — 42 niezmienniki
python3 tools/verify_vat_mpp.py --gate          # ALL MPP CHECKS PASSED
python3 tools/vat_gap_detector.py rules        # 32 ✅ / 2 ⚠️ / 0 ❌
python3 tools/native_rego_report21_gate.py      # WDROZONY_100 (6/6)
python3 -m pytest tests/auto/test_p03_vat_macro_enterprise.py tests/auto/test_p02_decision_core_enterprise.py tests/auto/test_r02_vat_core_enterprise.py tests/auto/test_vat_audyt_r03_enterprise.py -q  # 122 passed
```

## Weryfikacja końcowa po wdrożeniu P01 (komendy)

```bash
cd JDG
python3 tools/validate_rules.py                 # Błędów: 0
python3 tools/invariant_checker.py ci           # PASS — 42 niezmienniki
python3 tools/lint_rego_rules.py --ci           # 5/6 PASS
python3 -m pytest tests/test_p01_control_plane.py tests/test_p02_legal.py tests/test_p03_orchestrator_enterprise.py -q   # 87 passed
# Wymagane w CI (binarka OPA v1.x):
# opa check rules/ -b && opa test tests/rego/ -v
# python3 tools/generate_manifest.py && python3 tools/generate_coverage_report.py
```

## Metryki kampanii (cel końcowy — po P19)

- LCI ≥ 99% · RV = 100% · TCL = 100% · UVR = 0
- Zero duplikatów i stubów · zero hardcode w regułach (backlog domenowy domyka się P02–P19)
- 100% pakietów krytycznych z testami natywnymi + mutation ≥ 75%
- Golden replay bez nieuzasadnionych zmian · podpisane bundle (HSM)
- Nowelizacja P0 ≤ 4 h, parametry < 1 min, auto-rollback ≤ 5 min

## Checklista wdrożenia P03 (odhaczone)

- [x] Naprawa konfliktu kompilacji jdg.micro.jpk (plan33 → jdg.micro.jpk.plan33, 71 pól package)
- [x] Wpięcie warstwy mikro VAT + JPK do orkiestratora (PAS 43, importy, rejestr — Dual-Layer ADR-005)
- [x] Domknięcie pustyni pokrycia: art. 42a-42h WIS (8 reguł atomowych jdg.micro.vat.a42*.r1)
- [x] Nowe narzędzia: jpk_validator.py (sumy/GTU/terminy/KSeF) + jpk_generator.py (werdykty → JPK)
- [x] Stub summary p03 → flaga; fix unsafe var refund_days (art. 87)
- [x] Testy: test_native_vat_micro.rego (10) + test_native_jpk.rego (7) + 16 pytest

## Checklista wdrożenia P02 (odhaczone)

- [x] Monitor limitu art. 113 (jdg.vat.substantive.a113_limit_monitor — alert 95% + proporcja + prognoza)
- [x] MPP: weryfikacja kompletności art. 108a-108f (verify_vat_mpp 7/7) + nowe mpp_monitor.py (PSD2, sankcja 30%)
- [x] Nowy silnik stawek vat_rate_engine.py (PKWiU/CN + Trust Score + indeks)
- [x] Zero hardcode w domenie VAT: 15+ literałów → 11 nowych progów w thresholds.vat
- [x] SLIM VAT 3 (90 dni) + KSeF 2026-02-01 — temporalność potwierdzona/spójna
- [x] Testy: test_native_vat_mpp.rego + test_native_vat_a113_tracker.rego (14) + 10 pytest

## Checklista wdrożenia P01 (odhaczone)

- [x] Naprawa 453 błędów walidatora (440× _legal_basis + 13× duplikaty)
- [x] Uzupełnienie policy_registry.json (120 wpisów)
- [x] Wypełnienie 38 pustych _legal_basis
- [x] Zero hardcode w rdzeniu (30+ literałów → data.thresholds.jdg.*)
- [x] _routing w 186 blokach reguł (kontrakt 25-polowy)
- [x] Poprawki narzędzi: validate_rules, lint_rego_rules, invariant_checker
- [x] Testy rdzenia: 87/87 PASS
- [x] Raport P01 zapisany i wdrożony
- [ ] (CI) opa check / opa test — wymaga binarki OPA
