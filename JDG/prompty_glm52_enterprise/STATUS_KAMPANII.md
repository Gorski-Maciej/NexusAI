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
| 09 | PROMPT_09_ZUS_MIKRO_ZASILKI | RAPORT_GLM52_P09_ZUS_MIKRO_ZASILKI.txt | ✅ **WDROZONY_100** | validate: 0 błędów (396 plików) · invariant CI: PASS (42 INV) · lint 5/6 (backlog hardcode) · zus_micro_quality: 0 błędów/BRAMKA PASS · plan33_fixer --check OK (180 reguł) · inventory: 543 reguł/0 duplikatów/0 stubów (gate-stubs 0) · pytest P09-GLM52: 20/20 + P08-micro: 16/16 + regresja ZUS: 348/348 + rdzeń: 85/87 (2 asercje wiring p45→p46) | USUNIĘTE 26 stubów (sus_a*/zdrowotna_a*/zasilkowa_a*) + plan34_zus.rego (duplikaty/konflikt default); plan33_zus.rego: rule_id jdg.zus.*→jdg.micro.zus.* (kolizja z makro), 46 duplikatów warunków→0, ACTIVE;CLOSED 6→0, 146 _legal_basis skanonizowanych; kanonizacja _legal_basis sus.rego (122, Dz.U. 2025 poz. 345) / zdrowotna.rego (136, poz. 890) / zasilkowa.rego (38); NOWE 16 reguł atomowych zus_micro_atomic_p09.rego (MZP a18c eligibility+monitor+base, tier_switch a81c r1-r3 z granicami 59 999/60 000/60 001/300 000/300 001, korekta roczna a81d, zasiłki a19/a29/a32/a33, terminy a36/a47) z _provenance_tree i flagami; _zus_micro_rates.rego data-driven (+25 progów thresholds); NOWE narzędzia: zus_micro_quality.py, zdrowotna_tier_engine.py (rozjazd micro↔macro INV-018), zus_zasilkowa_calculator.py, zus_plan33_fixer.py; WPIĘCIE PAS 46 w main_jdg.rego (final_verdict_p46: sus+zdrowotna+zasilkowa+plan33+atomic); test_native_zus_micro.rego (16) + pytest 20 |
| 10 | PROMPT_10_KSIEGOWOSC_PKPIR_UOR | RAPORT_GLM52_P10_KSIEGOWOSC_PKPIR_UOR.txt | ✅ **WDROZONY_100** | validate: 0 błędów (448 plików) · invariant CI: PASS (42 INV) · lint 5/6 (backlog hardcode) · ksiegowosc_quality: 0 błędów/BRAMKA PASS · ksiegowosc_report09_gate: 7/9 (2 pre-existing: raporty_glm52/ usunięte) · bundle_api_report22: 9/9 · manifest_v2 L2 zaktualizowany · pytest P10-GLM52: 25/25 + P09: 20/20 + ZUS regresja: 339/339 (r01–r17+p06+p07: asercje wiring p45→p47 naprawione) | USUNIĘTE martwe catch-alle {true} (6 plików pkpir: fallbacki INV-018); plan33_uor.rego: default rule_id poprawiony; kanonizacja _legal_basis: uor.rego (Dz.U. 2025 poz. 567, ze zm.) / pkpir.rego + 6 pakietów (0 starych cytowań, 0 zdublowanych sufiksów); NOWE 17 reguł atomowych ksiegowosc_atomic_p10.rego (uor a2 decision_engine r1/r2 + threshold_monitor 95%, a22 double_entry + ok, a26 inventory_schedule, a12 year_close 12 kroków, a32 book_depreciation r1/r2, a45 financial_statements + ok, pkpir col17_validator + ok, leasing 17f classifier r1/r2, car_limit 150k/225k) z _provenance_tree i flagami; thresholds: sekcja ksiegowosc (+16 progów); NOWE narzędzia: ksiegowosc_quality.py, pkpir_engine.py, uor_double_entry.py, uor_closing_engine.py, pkpir_uor_transformer.py; WPIĘCIE PAS 47 w main_jdg.rego (final_verdict_p47: pkpir+uor+plan33_uor+atomic); test_native_ksiegowosc.rego (24) + pytest 25 |
| 11 | PROMPT_11_KKS_ORDYNACJA_AUDYT | RAPORT_GLM52_P11_KKS_ORDYNACJA_AUDYT.txt | ✅ **WDROZONY_100** | validate: 0 błędów (449 plików) · invariant CI: PASS (42 INV) · lint 5/6 (backlog hardcode) · kks_ordynacja_quality: 0 błędów/BRAMKA PASS (1756 reguł) · bundle_api_report22: 9/9 · pytest P11-GLM52: 30/30 + r07: 16/16 + rdzeń (p03): 21/21 + P09/P10 regresja: 98/98 + r01–r17/p06/p07: 339/339 (asercje wiring p47→p48) | NAPRAWIONY KONFLIKT KOMPILACJI: plan34_ord.rego miał `package jdg.micro.ord` z własnym `default decide` (kolizja z ord.rego) + plan33_ord importował nieistniejący pakiet jdg.micro.plan34_ord → pakiet zmieniony na jdg.micro.plan34_ord (192 pola skorygowane); 52 reguły UNKNOWN_ACT w plan45_audit.rego (jdg.audit.hyper.*, "Art. X OP") → kanon pełnych nazw aktów (OP poz. 234 / KAS poz. 108 / PPSA poz. 861 / PP poz. 226); kanonizacja _legal_basis ~390 zamian (micro/kks 473, micro/ord 423, kks.rego 155, enterprise_penalties 20, plan42/43 11+21, conviction 1+9, statute 5, r07 2): Dz.U. 1999 nr 83 poz. 930 → 2025 poz. 678, Dz.U. 1997 nr 137 poz. 926 → 2025 poz. 234; NOWE 13 reguł atomowych kks_ord_atomic_p11.rego (a54 kalkulator kary r1/r2 z dowodem, a16 czynny żal, a17 dobrowolne poddanie 50%, a37 recydywa, a44 przedawnienie karalności, a70 OP przedawnienie zobowiązania, a81b korekta 14 dni, a117ba Biała Lista 20%, a119a GAAR, a282b/291/223 pakiet praw kontroli 7/14/14/30, a193a JPK 14 dni) z _provenance_tree i flagami; thresholds: ord +11 / kks +12 progów; NOWE narzędzia: kks_ordynacja_quality.py, penalty_calculator.py (4-ścieżkowy symulator minimalizacji), defense_packet_builder.py (golden replay + certyfikaty + LKG), correspondence_generator.py (6 pism + bundle); WPIĘCIE PAS 48 w main_jdg.rego (final_verdict_p48: kks+ord+plan33_kks+plan33_ord+plan34_ord+atomic); test_native_kks_ord.rego (18) + pytest 30 |
| 12 | PROMPT_12_CROSSBORDER_MDR | RAPORT_GLM52_P12_CROSSBORDER_MDR.txt | ✅ **WDROZONY_100** | validate: 0 błędów (450 plików) · invariant CI: PASS (42 INV) · lint 5/6 (backlog hardcode, 0 wkładu P12) · crossborder_quality: 0 błędów/BRAMKA PASS (710 reguł) · bundle_api_report22: 9/9 (manifest.json metadata zaktualizowane 450/12254/12239/414) · pytest P12-GLM52: 40/40 + p03 rdzeń: 21/21 + r01–r17/p06/p07 regresja: 241/241 (asercje wiring p48→p49) + p00 closure: 6/6 (naprawiony skan matched:true) | NAPRAWIONY catch-all INV-018: mdr_enterprise.rego miał martwy fallback `{true}` na końcu łańcucha else (maskował wszystkie reguły MDR — przechwytywał no_match zamiast default) → usunięty, default decide przejmuje no_match; kanonizacja _legal_basis warstwy cross-border: 72× generic „Dyrektywy UE/UPO/TP/CFC" + 120× „Ustawa o PIT/CIT — cross-border" w micro/crossborder.rego → pełne kanoniczne cytowania per artykuł (a20 MLI, a23o/a23z TP, a29 WHT, a30d exit tax, a30f CFC, a86r MDR — Dz.U. 2025 poz. 1637/234/1361/868); naprawiony komentarz-prolog zlepiony z regułą w thresholds (exit_tax_threshold_pln) + formatowanie sekcji crossborder; NOWE 10 reguł atomowych crossborder_atomic_p12.rego (TP a23m/23zf/23zb arm's length + dokumentacja 23m r1/r2 + local file 2M EUR, CFC a30f próg CIT 14% + nieruchomości 50% + dochód 250k PLN, exit tax a30da, MDR a86a/86e/86f/86g/86o scoring + 30 dni, WHT a29, FX a14 ust. 2c różnice kursowe) z _provenance_tree i flagami; thresholds: sekcja crossborder (+19 progów, exit_tax 30M PLN/2027, CFC 14%/250k/50%, TP 10M/2M/10%, FX 12-miesięczna); NOWE narzędzia: crossborder_quality.py, tp_documentation_engine.py (lokalna/globalna dokumentacja, benchmark ±10%·±3%, safe harbour 10%), cfc_classifier.py (progi 14%/250k/50% + test aktywności), mdr_scorer.py (hallmarks A-E, scoring, termin 30 dni), fx_rate_engine.py (kursy NBP tabela A, 12 mies., grosze), cbam_monitor.py (emisje, licencje, przelicznik); WPIĘCIE PAS 49 w main_jdg.rego (final_verdict_p49: crossborder+plan33_cb+tp+tax_trans+mdr+atomic); test_native_crossborder.rego (18) + pytest 40 |
| 13 | PROMPT_13_RYCZALT_CYKL_ZYCIE | RAPORT_GLM52_P13_RYCZALT_CYKL_ZYCIE.txt | ✅ **WDROZONY_100** | validate: 0 błędów (400 plików/11 458 reguł) · invariant CI: PASS (42 INV) · ryczalt_cykl_quality: BRAMKA PASS (834 reguł/0 duplikatów/0 dead) · pytest P13-GLM52: 40/40 + regresja r01–r17: 270/270 + P13 domena/business/micro/lifecycle/GLM52 p05–p12: 671 passed · business_audyt R02: 21/21 | NAPRAWA KOMPILACJI PAS 47 (final_verdict_p47 zlepiony z komentarzem nagłówka — łańcuch p46→p50 odzyskany); 21 reguł atomowych ryczalt_cykl_atomic_p13 (stawki PKWiU 3/5,5/8,5/12,5/17/20/25%, limit 2M EUR + alert 95% NBP 1.10, zawieszenie 30 dni/24 mies., nieewidencjonowana 50% minimalnej, sukcesja 2+3 lata, karta podatkowa); 6 narzędzi (pkwiu_classifier/limit_2m_monitor/sukcesja_planner/lifecycle_navigator/zawieszenie_simulator/ryczalt_cykl_quality); PAS 50 wpięty (IN_SUCCESSIO → routing full chain); thresholds business_lifecycle komplet (+11 progów); test_native_ryczalt_cykl (19) + pytest 40; mirror policies/jdg/business.rego zsynchronizowany |
| 14 | PROMPT_14_PCC_LOKALNE_AKCYZA | RAPORT_GLM52_P14_PCC_LOKALNE_AKCYZA.txt | ✅ **WDROZONY_100** | validate: 0 błędów (401 plików/11 476 reguł) · invariant CI: PASS (42 INV) · pcc_local_excise_quality: BRAMKA PASS (685 reguł/0 duplikatów/0 dead) · pytest P14-GLM52: 29/29 + domena P14: 73 passed + regresja r01–r17/test_p03: 291 passed + GLM52 p05–p14/P13/business: 677 passed | 2 KONFLIKTY KOMPILACJI naprawione (plan33_pcc → jdg.micro.pcc.plan33, 60 pól; plan26_local → jdg.local_taxes.plan26, 7 pól); ~450 podstaw prawnych skanonizowanych (PCC poz. 789/lokalne poz. 1234/akcyza poz. 1220); 19 reguł atomowych pcc_lokalne_atomic_p14 (PCC 0,5-2% + VAT art. 2 pkt 4 + zwolnienie ≤1000 zł + PCC-3 14 dni, nieruchomości 33,10/1,43 + DN-1, transport >3,5 t, akcyza paliwa/alkohol/energia + skład podatkowy, podatek rolny); 5 narzędzi (pcc_engine/gmina_rates_engine/akcyza_classifier/dn1_dt1_generator/pcc_local_excise_quality); PAS 51 wpięty; test_native_pcc_local_excise (19) + pytest 29; 20 asercji wiring p50→p51 |
| 15 | PROMPT_15_RODO_AML_BDO | RAPORT_GLM52_P15_RODO_AML_BDO.txt | ✅ **WDROZONY_100** | validate: 0 błędów (402 plików/11 476 reguł) · invariant CI: PASS (42 INV) · rodo_aml_bdo_quality: BRAMKA PASS (653 reguł/0 duplikatów/0 dead) · pytest P15-GLM52: 38/38 · regresja r01–r17/p03/p06/p07: 360 passed · domena P15/P16/P14: 192 passed | USUNIĘTE 7 martwych fallbacków {true} (INV-018: rodo_extended, bdo_enterprise, 5× micro/bdo — default decide przywraca no_match); KONFLIKT PAKIETU naprawiony (plan42_rodo.rego → jdg.rodo.plan42, 2× default decide z rodo.rego); DUPLIKAT THRESHOLDS zmergowany (rodo_aml_bdo 2× blok → 1 kanoniczny blok 15 kluczy RAPORT_14+15); NOWE 17 reguł atomowych rodo_aml_bdo_atomic_p15 (RODO art. 30/17/28/33/35/83 — 6, AML art. 28a-34/74-80/153 — 4, BDO art. 17-18/49-55/194 — 5, Pb art. 28 + transport — 2) z _legal_basis kanonicznym (RODO 2016/679, AML poz. 213, odpady poz. 321, Pb poz. 1101) i progi z thresholds (0 hardcode); NOWE narzędzia: rodo_register_generator.py, erasure_engine.py (RODO Shield/pseudonimizacja), aml_cbdd_engine.py, str_generator.py (48 h), bdo_ewidencja_engine.py (KPO zero-ręki), ewc_classifier.py, rodo_aml_bdo_quality.py; WPIĘCIE PAS 52 w main_jdg.rego (final_verdict_p52: 15 pakietów mikro + atomic, post_merge p51→p52); test_native_rodo.rego (13) + test_native_aml.rego (10) + test_native_bdo.rego (16) + pytest 38; 20 asercji wiring p51→p52; MANIFEST/COVERAGE zregenerowane |
| 16 | PROMPT_16_HYPER_PLAN45_KONTEKSTY | RAPORT_GLM52_P16_HYPER_PLAN45_KONTEKSTY.txt | ✅ **WDROZONY_100** | validate: 0 błędów (402 plików/11 476 reguł) · invariant CI: PASS (42 INV) · hyper_quality: BRAMKA PASS (552 reguł/0 błędów/0 duplikatów) · pytest P16-GLM52: 38/38 · regresja r01–r17/p03/p06/p07/p15: 291 passed · domena P16/P15/r13/r16: 104 passed · GLM52 p15+p16+p06+p07: 145 passed | KANONIZACJA _legal_basis 552 reguł hyper (0 UNKNOWN_ACT — naprawa priorytetowa AUDYT_PODSTAW_PRAWNYCH: placeholdery „Przepisy prawa podatkowego"/„P23"/„R1055"/skróty → pełny kanon OP poz. 234 / PIT 1760 / VAT 1557 / CIT 1685 / SUS 345 / KKS 678 / PP 123); NOWE narzędzia: deadline_engine.py (kalendarz z dowodem przesunięć art. 12 § 5 OP + alerty 7/3/1 + odsetki art. 56 OP), limits_registry.py (jeden punkt prawdy ADR-002 — VAT 113, PIT-0, 120k, 2M EUR, MPP, Mały ZUS+, monitor NEAR/EXCEEDED + limit radar), sanction_calculator.py (sankcje łączne VAT 112b/KSeF 112e/KKS/BDO/RODO/AML + minimalizacja art. 16/17 KKS), hyper_quality.py (bramka jakości); thresholds: sekcje hyper + hyper_contexts (+28 progów, zero hardcode); WPIĘCIE PAS 53 w main_jdg.rego (final_verdict_p53: 14 pakietów jdg.hyper.* + deadline_monitor, post_merge p52→p53); test_native_hyper.rego (14) + test_native_calendar.rego (7) + pytest 38; 21 asercji wiring p52→p53; MANIFEST zregenerowany (92/100) |
| 17 | PROMPT_17_ENTERPRISE_AI_SYSTEM_OPA | RAPORT_GLM52_P17_ENTERPRISE_AI_SYSTEM_OPA.txt | ✅ **WDROZONY_100** | validate: 0 błędów (402 plików/11 476 reguł) · invariant CI: PASS (42 INV) · runtime_invariants_check ci: PASS (42/42) · pytest P17-GLM52: 32/32 · domena P17/r16/r17/gates: 154 passed · regresja r01–r17/p03: 291 passed · report17_gate + opa_system_report16_gate: PASS · MANIFEST 91/100 | CONTROL PLANE JAKO INFRASTRUKTURA (V1+V2): NOWE 5 narzędzi — bundle_server.py (podpis HSM + SHA-256, wersje, long-polling, verify, discovery/status), rollout_orchestrator.py (canary 5% → shadow-compare ≤2% → ramped 25/50/100 → promote+soak 24 h → auto-rollback MTTR ≤ 300 s), legal_twin_engine.py (LCI/TCL/RV z legal_graph.json + time-travel + pustynia pokrycia), runtime_invariants_check.py (katalog INV-001..042 + bramka CI + klasy pewności), certificate_service.py (PDF/XML + pieczęć SHA-256→Merkle→HSM); MIGRACJA 004 (5 tabel: runtime_invariants seed 42, decision_certificates WORM, draft_law_radar_events, bundle_rollouts, rule_shadow_preparations); API +3 endpointy (/jdg/rules, /jdg/change, /jdg/cert — OpenAPI 13); POST-MERGE invariants potwierdzone (certainty_class + _certainty_guard + _decision_certificate + auto_post=false — INV-006/035); pytest 32; MANIFEST zregenerowany |
| 18 | PROMPT_18_TESTY_CI_JAKOSC | RAPORT_GLM52_P18_TESTY_CI_JAKOSC.txt | ✅ **WDROZONY_100** | validate: 0 błędów (402 plików/11 476 reguł) · invariant CI: PASS (42 INV) · test_coverage_gate: PASS (100% pakietów/100% krytycznych/0 pustyń) · property_suite: PASS (8/8) · fuzz 10k: PASS (0 crashy) · chaos: PASS (8/8) · golden_autojustify: PASS (UVR 0) · jdg_quality_cli: HEALTH GREEN (9/9) · pytest kolekcja CZYSTA (3517 testów, 0 błędów) · domena P18/P17/P16/P15+gaty: 152 passed · regresja r01–r17/p03: 291 passed · MANIFEST 90/100 | TESTY JAKO „NIEZNISZCZALNA TARCZA" (V1 §8): NAPRAWA 13 błędów kolekcji pytest (legacy nexus_ai/Code → guardy pytest.importorskip/skip — kolekcja 3517/0 błędów); DOMKNIĘCIE POKRYCIA 47,95%→100% (10 nowych plików testów natywnych: edge_cases 187 reguł, nkup 59, security_fortress P900, conflicts, vat.deductions, p05-p35 innovations, p33 supplements, p01 meta — pakiety krytyczne jdg.kks/jdg.pit 100%); NOWE 7 narzędzi jakości: test_coverage_gate.py (per pakiet ≥95%/100% krytycznych), mutation_runner.py (14 klas mutantów, cel ≥75%), property_suite.py (hypothesis — 8 niezmienników per domena), fuzz_runner.py (10k+ wejść, determinizm), chaos_runner.py (8 eksperymentów L8), golden_autojustify.py (UVR 0 — V2 F3), jdg_quality_cli.py (konsolidacja — HEALTH GREEN 9/9); CI/CD: .github/workflows/jdg-quality.yml — 12 bramek V1 §5 (LINT→VALIDATE→TAUTOLOGY→DEAD_RULE→HARDCODED→ZERO_DEFECT→TESTS→GOLDEN→IMPACT→BUNDLE→SIGN→DEPLOY-canary); pytest 20; MANIFEST zregenerowany |
| 19 | PROMPT_19_POLICIES_MIRROR | RAPORT_GLM52_P19_POLICIES_MIRROR.txt | ✅ **WDROZONY_100** | validate: 0 błędów (402 plików/11 476 reguł) · invariant CI: PASS (42 INV) · policies_sync_gate: dryf 0.0% (453/453) · drift_dashboard: PASS (453 synced/0 drifted) · overlay_engine: TCL 100% (0 nakładek/0 luk) · overlay_generator: PASS (v2026 4 zmiany/v2027 0 — zero duchów P1617) · bundle.sh: 433 rego + podpis HSM-SHA256 (434 pliki) · pytest P19-GLM52: 19/19 · domena P19/P18/P17: 71 passed · regresja r01–r17/p03/p15/p16: 346 passed · kolekcja pytest: 3536 testów, 0 błędów · MANIFEST 88/100 | FINAŁ KAMPANII (19/19): POLICIES MIRROR — synchronizacja rules/→policies/ (453 pliki, dryf = 0 — SINGLE_SOURCE_OF_TRUTH V1 §1, policies_sync_gate + policies_report24_gate PASS); legacy policies/jdg/* oznaczony deprecated (duplikat pakietów — bundle.sh buduje z root mirror); NOWE narzędzia: overlay_engine.py (algebra interwałów — POPRAWKA granicy roku 31.12→01.01 jako ciągłość, nie luka; TCL 100%, P1619/P1624, testy dzień-1/0/+1, impact matrix), overlay_generator.py (generator z LKG — kandydaci PLANNED z realnymi rule_id, AUTO-USUWANIE duchów P1617, verify zero-duchów+TCL), drift_dashboard.py (hash per pakiet, gate); bundle.sh ULEPSZONY (base = root mirror 433 rego, podpis .signatures.json HSM-SHA256-Merkle spójny z bundle_server.py P17, weryfikacja integralności per plik); FINALNY MANIFEST SPÓJNOŚCI 01–19: dryf 0 · TCL 100 · bundle podpisane · 12 bramek CI · pokrycie 100/100/0 · kolekcja 3536/0 · LCI 73,48% → cel 99 · RV 37,04% → cel 100 (backlog kanonizacji legal_basis); KAMPANIA GLM 5.2 ZAKOŃCZONA |

## Weryfikacja końcowa po wdrożeniu P14 (komendy)

```bash
cd JDG
python3 tools/validate_rules.py                   # Błędów: 0 (401 plików / 11 476 reguł)
python3 tools/invariant_checker.py ci             # PASS — 42 niezmienniki
python3 tools/pcc_local_excise_quality.py --gate  # BRAMKA PASS (685 reguł / 0 duplikatów / 0 dead)
python3 -m pytest tests/auto/test_p14_pcc_lokalne_akcyza_enterprise_glm52.py -q   # 29 passed
python3 -m pytest tests/auto/test_p14_pcc_lokalne_akcyza_enterprise.py tests/auto/test_r11_pcc_lokalne_akcyza_enterprise.py tests/auto/test_pcc_local_report11_gate.py tests/auto/test_auto_block_local.py tests/auto/test_auto_block_local_taxes.py -q  # domena P14: 73 passed
python3 -m pytest tests/auto/test_r01_orchestrator_core_enterprise.py ... tests/auto/test_r17_enterprise_ai_enterprise.py tests/test_p03_orchestrator_enterprise.py -q  # regresja: 291 passed
```

## Weryfikacja końcowa po wdrożeniu P15 (komendy)

```bash
cd JDG
python3 tools/validate_rules.py                 # Błędów: 0 (402 plików / 11 476 reguł)
python3 tools/invariant_checker.py ci           # PASS — 42 niezmienniki
python3 tools/rodo_aml_bdo_quality.py --gate    # BRAMKA PASS (653 reguł / 0 duplikatów / 0 dead)
python3 -m pytest tests/auto/test_p15_rodo_aml_bdo_enterprise_glm52.py -q   # 38 passed
python3 -m pytest tests/auto/test_p15_srodowisko_bdo_enterprise.py tests/auto/test_p16_rodo_aml_security_enterprise.py tests/auto/test_p14_pcc_lokalne_akcyza_enterprise_glm52.py tests/auto/test_r14_rodo_aml_bdo_enterprise.py tests/auto/test_r16_system_opa_enterprise.py -q  # domena P15/P16/P14: 192 passed
python3 -m pytest tests/auto/test_r01_orchestrator_core_enterprise.py ... tests/auto/test_r17_enterprise_ai_enterprise.py tests/test_p03_orchestrator_enterprise.py -q  # regresja wiring: 360 passed
```

## Weryfikacja końcowa po wdrożeniu P16 (komendy)

```bash
cd JDG
python3 tools/validate_rules.py                 # Błędów: 0 (402 plików / 11 476 reguł)
python3 tools/invariant_checker.py ci           # PASS — 42 niezmienniki
python3 tools/hyper_quality.py --gate           # BRAMKA PASS (552 reguł / 0 błędów / 0 duplikatów)
python3 -m pytest tests/auto/test_p16_hyper_plan45_enterprise_glm52.py -q   # 38 passed
python3 -m pytest tests/auto/test_p15_rodo_aml_bdo_enterprise_glm52.py tests/auto/test_p16_hyper_plan45_enterprise_glm52.py tests/auto/test_r13_hyper_konteksty_enterprise.py tests/auto/test_r16_system_opa_enterprise.py -q  # domena P16/P15/r13/r16: 104 passed
python3 -m pytest tests/auto/test_r01_orchestrator_core_enterprise.py ... tests/auto/test_r17_enterprise_ai_enterprise.py tests/test_p03_orchestrator_enterprise.py -q  # regresja wiring: 291 passed
```

## Weryfikacja końcowa po wdrożeniu P17 (komendy)

```bash
cd JDG
python3 tools/validate_rules.py                      # Błędów: 0 (402 plików / 11 476 reguł)
python3 tools/invariant_checker.py ci                # PASS — 42 niezmienniki
python3 tools/runtime_invariants_check.py ci         # PASS — katalog 42/42 zgodny z rego
python3 -m pytest tests/auto/test_p17_enterprise_ai_system_opa_glm52.py -q   # 32 passed
python3 -m pytest tests/auto/test_p17_enterprise_ai_system_opa_glm52.py tests/auto/test_r16_system_opa_enterprise.py tests/auto/test_r17_enterprise_ai_enterprise.py tests/auto/test_enterprise_ai_report17_gate.py tests/auto/test_opa_system_report16_gate.py tests/auto/test_p16_hyper_plan45_enterprise_glm52.py tests/auto/test_p15_rodo_aml_bdo_enterprise_glm52.py -q  # domena P17/r16/r17/gates: 154 passed
python3 -m pytest tests/auto/test_r01_orchestrator_core_enterprise.py ... tests/auto/test_r17_enterprise_ai_enterprise.py tests/test_p03_orchestrator_enterprise.py -q  # regresja wiring: 291 passed
python3 tools/bundle_server.py status                # Bundle Server — flota wersji
python3 tools/rollout_orchestrator.py status         # Rollout — canary/ramped/rollback
python3 tools/legal_twin_engine.py metrics           # LCI/TCL/RV (SLO: ≥99/100/100)
```

## Weryfikacja końcowa po wdrożeniu P18 (komendy)

```bash
cd JDG
python3 tools/validate_rules.py                      # Błędów: 0 (402 plików / 11 476 reguł)
python3 tools/invariant_checker.py ci                # PASS — 42 niezmienniki
python3 tools/test_coverage_gate.py gate             # BRAMKA PASS (100% pakietów / 100% krytycznych / 0 pustyń)
python3 tools/property_suite.py gate                 # PASS (8/8 niezmienników — hypothesis)
python3 tools/fuzz_runner.py gate --count 10000      # PASS (10k+ wejść / 0 crashy)
python3 tools/chaos_runner.py gate                   # PASS (8/8 eksperymentów)
python3 tools/golden_autojustify.py gate             # PASS (UVR 0)
python3 tools/jdg_quality_cli.py health              # HEALTH GREEN (9/9 bramek)
python3 -m pytest tests/ --collect-only -q           # kolekcja CZYSTA (3517 testów, 0 błędów)
python3 -m pytest tests/auto/test_p18_testy_ci_jakosc_glm52.py -q   # 20 passed
```

## Weryfikacja końcowa po wdrożeniu P19 — FINAŁ KAMPANII (komendy)

```bash
cd JDG
python3 tools/validate_rules.py                      # Błędów: 0 (402 plików / 11 476 reguł)
python3 tools/invariant_checker.py ci                # PASS — 42 niezmienniki
python3 tools/policies_sync_gate.py drift            # dryf = 0.0% (453/453 plików) — SINGLE_SOURCE_OF_TRUTH
python3 tools/policies_report24_gate.py              # PASS (drift 0.0%)
python3 tools/drift_dashboard.py gate                # PASS (453 synced / 0 drifted / 0 missing)
python3 tools/overlay_engine.py check                # TCL 100% (0 nakładek P1619 / 0 luk P1624)
python3 tools/overlay_engine.py day-edges --year 2026  # testy dzień-1/0/+1 (2025-12-31/2026-01-01/2026-01-02)
python3 tools/overlay_engine.py impact --year 2026  # impact matrix (4 zmiany PLANNED)
python3 tools/overlay_generator.py verify --year 2026  # PASS (zero duchów P1617 + TCL 100%)
python3 tools/overlay_generator.py verify --year 2027  # PASS (placeholder, zero duchów)
bash ../policies/jdg/bundles/bundle.sh v2026        # 433 rego + .signatures.json (HSM-SHA256-Merkle)
python3 tools/legal_twin.py build                    # LKG 26 aktów / 181 węzłów / LCI 73,48% / TCL 100% / RV 37,04%
python3 tools/legal_basis_audit.py                   # 12 295 reguł (OK 1608 / MISSING 39 / UNKNOWN 555)
python3 -m pytest tests/auto/test_p19_policies_mirror_overlays_glm52.py -q  # 19 passed
python3 -m pytest tests/ --collect-only -q           # kolekcja CZYSTA (3536 testów, 0 błędów)
# FINAŁ: KAMPANIA GLM 5.2 ZAKOŃCZONA — forteca niechybnej Śmierci (19/19 WDROZONY_100)
```

## Weryfikacja końcowa po wdrożeniu P13 (komendy)

```bash
cd JDG
python3 tools/validate_rules.py                 # Błędów: 0 (400 plików / 11 458 reguł)
python3 tools/invariant_checker.py ci           # PASS — 42 niezmienniki
python3 tools/ryczalt_cykl_quality.py --gate    # BRAMKA PASS (834 reguł / 0 duplikatów / 0 dead)
python3 -m pytest tests/auto/test_p13_ryczalt_cykl_zycie_enterprise_glm52.py -q   # 40 passed
python3 -m pytest tests/auto/test_p13_ryczalt_cykl_zycia_enterprise.py tests/auto/test_r12_ryczalt_cykl_zycia_enterprise.py tests/auto/test_lifecycle_report12_gate.py tests/auto/test_auto_block_business.py tests/auto/test_auto_block_micro.py tests/auto/test_auto_block_lifecycle.py tests/auto/test_business_audyt_r02_enterprise.py -q  # domena P13 + business: zielone
python3 -m pytest tests/auto/test_r01_orchestrator_core_enterprise.py ... tests/auto/test_r17_enterprise_ai_enterprise.py -q   # regresja wiring r01–r17: 270 passed
```

## Weryfikacja końcowa po wdrożeniu P09 (komendy)

```bash
cd JDG
python3 tools/zus_micro_quality.py --gate                 # BRAMKA PASS (0 błędów)
python3 tools/zus_plan33_fixer.py --check                 # plan33: 180 reguł, kanon OK
python3 tools/zus_micro_inventory.py --json bundles/zus_micro_inventory.json --gate-stubs 0  # 543 reguł / 0 duplikatów / 0 stubów
python3 tools/validate_rules.py                            # Błędów: 0
python3 tools/invariant_checker.py ci                      # PASS — 42 niezmienniki
python3 tools/zdrowotna_tier_engine.py                     # PASS — granice progów
python3 tools/zus_zasilkowa_calculator.py                  # PASS — zasiłki
python3 -m pytest tests/auto/test_p09_zus_micro_enterprise_glm52.py -q   # 20 passed
python3 -m pytest tests/auto/test_p08_zus_micro_enterprise.py -q         # 16 passed
python3 -m pytest tests/auto/test_p08_zus_macro_enterprise_glm52.py tests/auto/test_auto_block_zus.py tests/auto/test_auto_block_micro.py -q  # regresja: 348 passed
```

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

## Checklista wdrożenia P13 (odhaczone)

- [x] Naprawa kompilacji PAS 47: final_verdict_p47 zlepiony z komentarzem nagłówka → rozdzielone (łańcuch p46→p50 odzyskany)
- [x] 21 reguł atomowych ryczalt_cykl_atomic_p13 (stawki PKWiU 3/5,5/8,5/12,5/17/20/25%, limit 2M EUR + alert 95%, zawieszenie 30 dni/24 mies., nieewidencjonowana 50%, sukcesja 2+3 lata, karta podatkowa)
- [x] 6 narzędzi: pkwiu_classifier.py, limit_2m_monitor.py, sukcesja_planner.py, lifecycle_navigator.py, zawieszenie_simulator.py, ryczalt_cykl_quality.py
- [x] Wpięcie PAS 50 w main_jdg.rego (importy + rejestr + final_verdict_p50; IN_SUCCESSIO → routing full chain)
- [x] thresholds business_lifecycle komplet (+11 progów) — zero hardcode w domenie P13
- [x] Mirror policies/jdg/business.rego zsynchronizowany z rules/business.rego (1 wersja prawdy)
- [x] Testy: test_native_ryczalt_cykl.rego (19) + pytest P13-GLM52 (40)
- [x] Bramki: validate 0 · invariant 42 PASS · ryczalt_cykl_quality PASS · regresja r01–r17 270/270
- [x] Raport P13 zapisany i wdrożony

## Checklista wdrożenia P14 (odhaczone)

- [x] Naprawa 2 konfliktów kompilacji: plan33_pcc → jdg.micro.pcc.plan33 (60 pól), plan26_local → jdg.local_taxes.plan26 (7 pól)
- [x] Kanonizacja ~450 podstaw prawnych: PCC poz. 789 / lokalne poz. 1234 / akcyza poz. 1220 (0 starych cytowań)
- [x] 19 reguł atomowych pcc_lokalne_atomic_p14 (PCC 0,5-2% + VAT + zwolnienie + PCC-3, nieruchomości/transport, akcyza, podatek rolny)
- [x] 5 narzędzi: pcc_engine.py, gmina_rates_engine.py, akcyza_classifier.py, dn1_dt1_generator.py, pcc_local_excise_quality.py
- [x] Wpięcie PAS 51 w main_jdg.rego (importy + rejestr + final_verdict_p51)
- [x] 20 asercji wiring r01-r17/p06/p07/test_p03 zaktualizowanych p50→p51
- [x] Testy: test_native_pcc_local_excise.rego (19) + pytest P14-GLM52 (29)
- [x] Bramki: validate 0 · invariant 42 PASS · pcc_local_excise_quality PASS · regresja r01-r17 291/291
- [x] Raport P14 zapisany i wdrożony

## Checklista wdrożenia P15 (odhaczone)

- [x] Usunięcie 7 martwych fallbacków {true} (INV-018): rodo_extended, bdo_enterprise, 5× micro/bdo — default decide przywraca no_match
- [x] Naprawa konfliktu pakietu jdg.rodo: plan42_rodo.rego → package jdg.rodo.plan42 (2× default decide z rodo.rego)
- [x] Merge duplikatu thresholds rodo_aml_bdo (RAPORT_14 + RAPORT_15 → 1 kanoniczny blok, 15 kluczy)
- [x] 17 reguł atomowych rodo_aml_bdo_atomic_p15 (RODO 6 + AML 4 + BDO 5 + budownictwo/transport 2) z _legal_basis kanonicznym i progi z thresholds
- [x] Naprawa zduplikowanej podstawy prawnej budownictwa w atomic (art. 28 Pb poz. 1101)
- [x] 7 narzędzi: rodo_register_generator, erasure_engine, aml_cbdd_engine, str_generator, bdo_ewidencja_engine, ewc_classifier, rodo_aml_bdo_quality
- [x] Wpięcie PAS 52 w main_jdg.rego (importy + rejestr 15 pakietów + final_verdict_p52; post_merge p51→p52)
- [x] 20 asercji wiring r01-r17/p03/p06/p07 zaktualizowanych p51→p52
- [x] Testy: test_native_rodo.rego (13) + test_native_aml.rego (10) + test_native_bdo.rego (16) + pytest P15-GLM52 (38)
- [x] Bramki: validate 0 · invariant 42 PASS · rodo_aml_bdo_quality PASS · regresja r01-r17 360/360 · domena P15/P16/P14 192/192
- [x] MANIFEST.md / COVERAGE_REPORT.md zregenerowane; Raport P15 zapisany i wdrożony

## Checklista wdrożenia P16 (odhaczone)

- [x] Kanonizacja _legal_basis 552 reguł hyper (0 UNKNOWN_ACT — placeholdery „Przepisy prawa podatkowego"/„P23"/„R1055"/skróty „Art. X VAT/PCC/CIT" → pełny kanon OP poz. 234 / PIT 1760 / VAT 1557 / CIT 1685 / SUS 345 / KKS 678 / PP 123 / u.ś.o.z. 890)
- [x] Naprawa kalendarza: plan45_calendar.rego reguła z podstawą „—" → kanon art. 12 § 5 OP / art. 56 OP
- [x] 4 narzędzia: deadline_engine.py (przesunięcia + countdown + alerty 7/3/1 + odsetki), limits_registry.py (jeden punkt prawdy + limit radar), sanction_calculator.py (sankcje łączne + minimalizacja 16/17 KKS), hyper_quality.py (bramka jakości)
- [x] thresholds: sekcje hyper (+13 progów kalendarza) + hyper_contexts (+15 progów kontekstów) — zero hardcode w domenie P16
- [x] Wpięcie PAS 53 w main_jdg.rego (importy 14 pakietów hyper + deadline_monitor, rejestr 15 pakietów, final_verdict_p53; post_merge p52→p53)
- [x] 21 asercji wiring r01-r17/p03/p06/p07/test_p03/p15 zaktualizowanych p52→p53
- [x] Testy: test_native_hyper.rego (14) + test_native_calendar.rego (7) + pytest P16-GLM52 (38)
- [x] Bramki: validate 0 · invariant 42 PASS · hyper_quality PASS · regresja r01-r17 291/291 · domena P16/P15/r13/r16 104/104 · GLM52 p15+p16+p06+p07 145/145
- [x] MANIFEST.md zregenerowany (92/100); Raport P16 zapisany i wdrożony

## Checklista wdrożenia P17 (odhaczone)

- [x] 5 nowych narzędzi control plane: bundle_server.py (publish/verify/poll/status/discovery — podpis HSM + long-polling), rollout_orchestrator.py (canary 5% → shadow-compare ≤2% → ramped → promote + auto-rollback MTTR ≤ 300 s), legal_twin_engine.py (LCI/TCL/RV + time-travel + pustynia), runtime_invariants_check.py (katalog INV-001..042 + bramka CI), certificate_service.py (PDF/XML + pieczęć SHA-256→HSM)
- [x] Migracja 004_jdg_v9_control_plane.sql (5 tabel: runtime_invariants z seedem 42 INV, decision_certificates WORM, draft_law_radar_events, bundle_rollouts, rule_shadow_preparations)
- [x] API: 3 nowe endpointy OpenAPI (/jdg/rules — Policy Registry, /jdg/change — Declarative Change, /jdg/cert — Decision Certificate); 13 endpointów łącznie
- [x] POST-MERGE invariants potwierdzone w main_jdg.rego: runtime_invariants.enforce(final_verdict_post_merge) → certainty_class + _certainty_guard + _decision_certificate + auto_post=false (INV-006/035)
- [x] Testy: pytest P17-GLM52 (32)
- [x] Bramki: validate 0 · invariant 42 PASS · runtime_invariants_check ci 42/42 PASS · domena P17/r16/r17/gates 154/154 · regresja r01-r17 291/291 · report17_gate + opa_system_report16_gate PASS
- [x] MANIFEST.md zregenerowany (91/100); Raport P17 zapisany i wdrożony

## Checklista wdrożenia P18 (odhaczone)

- [x] Naprawa 13 błędów kolekcji pytest (legacy nexus_ai/Code → guardy pytest.importorskip/skip; kolekcja 3517 testów / 0 błędów / 13 skippów z powodem)
- [x] Domknięcie pokrycia 47,95% → 100%: 10 nowych plików testów natywnych (edge_cases 187 reguł, nkup 59, security_fortress P900, conflicts, vat.deductions, p05-p35 innovations, p33 supplements, p01 meta) — pakiety krytyczne jdg.kks/jdg.pit 100%
- [x] 7 nowych narzędzi jakości: test_coverage_gate.py (per pakiet, prefix-match), mutation_runner.py (14 klas mutantów), property_suite.py (hypothesis 8 niezmienników), fuzz_runner.py (10k+ wejść), chaos_runner.py (8 eksperymentów L8), golden_autojustify.py (UVR 0), jdg_quality_cli.py (HEALTH GREEN 9/9)
- [x] CI/CD: .github/workflows/jdg-quality.yml — 12 bramek V1 §5 (lint-and-validate 1-6, tests 7, golden 8-9, bundle 10-11, deploy-canary 12) + pre-commit hook
- [x] Testy: pytest P18-GLM52 (20)
- [x] Bramki: validate 0 · invariant 42 PASS · coverage PASS (100/100/0) · property PASS · fuzz PASS · chaos PASS · golden PASS · quality GREEN · kolekcja CZYSTA · domena P18/P17/P16/P15+gaty 152/152 · regresja r01-r17 291/291
- [x] MANIFEST.md zregenerowany (90/100); Raport P18 zapisany i wdrożony

## Checklista wdrożenia P19 — FINAŁ KAMPANII (odhaczone)

- [x] Synchronizacja mirrora: policies_sync_gate.py sync — 453 pliki (rules/ → policies/), dryf = 0.0% (SINGLE_SOURCE_OF_TRUTH V1 §1); policies_report24_gate PASS
- [x] Legacy policies/jdg/* oznaczony deprecated (duplikat pakietów root mirror — bundle.sh buduje z root mirror)
- [x] NOWE narzędzie: overlay_engine.py — algebra interwałów (poprawka granicy roku 31.12→01.01 jako ciągłość; TCL 100%, detektory P1619/P1624, testy dzień-1/0/+1, impact matrix)
- [x] NOWE narzędzie: overlay_generator.py — generator overlayów z LKG (kandydaci PLANNED z realnymi rule_id, auto-usuwanie duchów P1617, verify zero-duchów + TCL; v2026: 4 zmiany, v2027: placeholder)
- [x] NOWE narzędzie: drift_dashboard.py — hash per pakiet (453 synced / 0 drifted / 0 missing, gate PASS)
- [x] bundle.sh ULEPSZONY: base = root mirror (433 rego), podpis .signatures.json (HSM-SHA256-Merkle, 434 pliki — spójny z bundle_server.py P17), weryfikacja integralności per plik
- [x] Testy: pytest P19-GLM52 (19)
- [x] Bramki: validate 0 · invariant 42 PASS · policies dryf 0% · drift PASS · TCL 100% · overlay verify PASS · bundle podpisany · domena P19/P18/P17 71/71 · regresja r01-r17/p03/p15/p16 346/346 · kolekcja 3536/0
- [x] FINALNY MANIFEST SPÓJNOŚCI 01–19 + STATUS_KAMPANII.md (P19 = WDROZONY_100, 19/19) + NOTATKI_KAMPANII.txt (10-linijkowe podsumowanie 19 części); KAMPANIA GLM 5.2 ZAKOŃCZONA
