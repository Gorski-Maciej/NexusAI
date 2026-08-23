#!/usr/bin/env python3
"""Dane czesci 01-10 kampanii V3 (rozszerzone: zakres prawny, luki, pomysly).

Format kazdej czesci (tuple, dokladnie 8 pol):
  (num, tag, out, cons, scope, luki, pomysly, groups)
"""

PARTS_A = [
    # 01 - FUNDAMENTY I ORKIESTRATOR
    ("01", "FUNDAMENTY + ORKIESTRATOR + ROUTING/RISK/TEMPORALNOSC/STRAZNICY",
     "01_FUNDAMENTY_ORKIESTRATOR", "02,03,04,08,13,16,17,18",
     "Zakres prawny i techniczny: Multi-Pass PASS 0-8 + POST-MERGE, Safe Merge, "
     "Sharded Router (ADR-009), werdykt 25-polowy (ADR-004), temporalnosc "
     "(valid_from/to, time-travel, ADR-003), zero-hardcode (ADR-002, "
     "data.thresholds), invarianty INV-001..INV-042, Decision Certificate (F4), "
     "runtime invariants (F2), Control/Data Plane (V1), metryki SLO/SLA z V1. "
     "Sprawdz podpięcie wszystkich pakietow w main_jdg.rego zgodnie z MANIFEST.",
     "LUKI: 3 duplikaty rule_id wg MANIFEST; routing tylko ~64% pakietow; "
     "main_jdg.rego.bak do usuniecia/oznaczenia; brak twardej bramki opa check -b "
     "w CI (54 pliki micro z bledem skladni); brak PASS 9 (trust-adaptive); "
     "brak auto-rollbacku wg zasady 5 V1.",
     "1) PASS 9 TRUST-ADAPTIVE - dynamiczne skladanie werdyktow wg Trust Score; "
     "2) Sharded Router v3 - routing kontekstowy z prekompilacja shardow; "
     "3) Decision Certificate inline w orkiestratorze (SHA-256, klasa pewnosci); "
     "4) runtime invariants jako twarda bramka BLOCK_AND_ALERT z auto-revert; "
     "5) hook Golden Oracle (diff werdyktow vs archiwum 12 mies.); "
     "6) auto-rollback 5 min + canary 5-25-50-100; "
     "7) metryki SLO/SLA w kazdym werdykcie; "
     "8) graf zaleznosci pakietow do analizy wplywu zmiany reguly.",
     [
        ("Orkiestrator + routing (★★★)", ["rules/main_jdg.rego", "rules/risk.rego", "rules/routing.rego"]),
        ("Temporalnosc + proweniencja + progi (★★)", [
            "rules/temporal.rego", "rules/provenance.rego", "rules/thresholds_jdg.rego"]),
        ("Pakiety core (★★)", [
            "rules/compliance.rego", "rules/conflicts.rego", "rules/edge_cases.rego"]),
        ("Invarianty / straz / decision core (★★)", [
            "rules/security/security_fortress_v8.rego",
            "rules/audit/runtime_invariants_enterprise.rego",
            "rules/decision_core_completeness_enterprise.rego",
            "rules/rule_lifecycle_enterprise.rego",
            "rules/conflict_declaration_enterprise.rego"]),
        ("Innowacje orkiestratora (★)", [
            "rules/p01_core_architecture_innovations_v8.rego",
            "rules/p02_decision_core_innovations_v9.rego",
            "rules/p03_orchestrator_innovations_v9.rego",
            "rules/r01_orchestrator_core_innovations_v9.rego"]),
        ("Dokumentacja kotwica (★)", [
            "docs/ORCHESTRATOR_DATA_CONTRACT.md",
            "docs/CORE_GUARDS_TEMPORAL_THRESHOLDS.md",
            "docs/CONTROL_PLANE_RULE_LIFECYCLE.md",
            "docs/ANALIZA_STANU_OPA_JAKO_SYSTEM.md"]),
        ("Narzedzia i bramki (★)", [
            "tools/orchestrator_wiring_gate.py", "tools/orchestrator_data_contract.py",
            "tools/core_guards_temporal_thresholds.py", "tools/invariant_checker.py",
            "tools/decision_certificate.py", "tools/rule_lifecycle_manager.py",
            "tools/control_plane_lifecycle.py", "tools/temporal_interval_gate.py"]),
        ("Testy kontraktu (★)", [
            "tests/test_orchestrator_data_contract.py",
            "tests/test_core_guards_temporal_thresholds.py",
            "tests/test_control_plane_lifecycle.py"]),
     ]),
    # 02
    ("02", "VAT - MAKRO + MIKRO + ODLICZENIA + KSEF-VAT + STAWKI + ZWOLNIENIA",
     "02_VAT", "01,03,08,11,13,16",
     "Ustawa z 11.03.2004 o VAT (Dz.U. 2025 poz. 456 ze zm.): art. 5-14 (zakres), "
     "15-18 (podatnicy), 19a-21 (obowiazek podatkowy), 28a-28n (miejsce), "
     "29a-32 (podstawa), 41-42 + zal. nr 3/10 (stawki 23/8/5/0), 43 (zwolnienia), "
     "86-96 (odliczenia, proporcja, pre-), 97-99 (deklaracje, JPK_V7M), "
     "106a-106nq (faktury, KSEF), 108a-108f (split payment), 113 (zwolnienie "
     "podmiotowe 200 000 PLN, w tym ust 1/5/9/13), 120 (marza).",
     "LUKI: COVERAGE_REPORT pokazuje braki V.012, V.013, V.022, V.024, V.036, "
     "V.053; micro/vat jest warstwa szablonowa (puste pola, tautologie); "
     "brak runtime reconcilacji JPK<->KSEF; brak geodezji pod załaczniki 3/10.",
     "1) Fraud-graph - detekcja faktur kuzynkich (karuzela VAT); "
     "2) auto-sugestia GTU wg klasyfikacji PKWiU; "
     "3) rekoncyliacja JPK_V7M vs KSeF w czasie rzeczywistym; "
     "4) korekta roczna pro-rata art. 90-91 z symulacja (SLIM 3: 150->90 dni); "
     "5) Decision Certificate dla kazej stawki; "
     "6) temporal lock na date transakcji; "
     "7) sandbox KSeF z UPO; "
     "8) rejestr stawiek wg obwieszczen MF (hot-reload).",
     [
        ("Makro VAT (★★★)", [
            "rules/vat/substantive.rego", "rules/vat/deductions.rego",
            "rules/vat/procedures.rego", "rules/vat/place_of_supply.rego",
            "rules/vat/plan23_detailed.rego", "rules/vat/plan26_critical.rego",
            "rules/vat/plan42_reduced_rates.rego"]),
        ("VAT Enterprise / zero-doubt (★)", [
            "rules/vat/enterprise_vat_bridge.rego", "rules/vat/vat_enterprise_zero_doubt.rego",
            "rules/vat_mpp_split_payment_enterprise.rego",
            "rules/vat_rates_exemptions_audit_enterprise.rego",
            "rules/vat_deductions_corrections_enterprise.rego",
            "rules/vat_fraud_detection_enterprise.rego",
            "rules/vat_cashflow_predictor_enterprise.rego"]),
        ("VAT mikro (★)", [
            "dir:rules/micro/vat", "rules/micro/plan33_vat.rego", "rules/micro/plan34_vat.rego"]),
        ("KSEF/JPK po stronie VAT (★)", [
            "rules/ksef_jpk.rego", "rules/ksef_firewall_enterprise.rego",
            "rules/ksef_offline_queue_enterprise.rego", "rules/ksef_receipt_digest_enterprise.rego"]),
        ("Innowacje VAT (★)", [
            "rules/p02_vat_macro_innovations_v8.rego", "rules/p03_vat_micro_innovations_v8.rego",
            "rules/r02_vat_core_innovations_v9.rego", "rules/r03_vat_micro_innovations_v9.rego"]),
        ("Narzedzia i audyty (★)", [
            "tools/vat_rate_engine.py", "tools/vat_micro_inventory.py", "tools/vat_macro_audit.py",
            "tools/vat_micro_core_audit.py", "tools/vat_micro_special_audit.py", "tools/vat_gap_detector.py"]),
        ("Testy i dokumentacja (★)", [
            "tests/rego/micro/test_native_micro_vat.rego",
            "docs/VAT_MACRO_P03.md", "docs/VAT_MICRO_P04.md", "docs/VAT_AUDYT_R03.md"]),
     ]),
    # 03
    ("03", "PIT - FORMY, KUP, ULGI, ZALICZKI, DEKLARACJE", "03_PIT",
     "01,02,04,09,13",
     "Ustawa z 26.07.1991 o PIT (Dz.U. 2025 poz. 789 ze zm.): art. 9 (zakres), "
     "10 (zrodla), 14 (przychody), 22 (KUP i moment potracenia), 23 (NKUP), "
     "22a-22o (amortyzacja), 26-26h (ulgi), 26e (BR), 30ca (IP Box 5%), 30f (CFC), "
     "30da (exit p), 27 (skala 12/32), 30c (liniowy), 44 (zaliczki), 45 (roczne: "
     "PIT-36, PIT-36L, PIT-28); rozporzadzenia MF o wzorach zeznan 2025/2026.",
     "LUKI: art. 23 luki detaliczne (reprezentacja, limity samochodowe, 75%); "
     "brak pełnych procedur ulg (IP Box warunki 30ca ust 4-11); "
     "micro/pit 7977 pustych pol; brak walidatora wyboru formy.",
     "1) Cross-Relief Optimizer - kombinacje ulg z maksymalizacja; "
     "2) symulacja zmiany formy opodatkowania (skala vs liniowy vs ryczalt); "
     "3) silnik auto-deklaracji PIT-36/36L/28 (rozporzenie 2025); "
     "4) monitor progowy (kwota wolna, II proj 120 000, ulgi); "
     "5) temporal tracker nowelizacji PIT; 6) klasyfikator KUP/NKUP; "
     "7) golden tests per forma; 8) Decision Certificate dla ulgi.",
     [
        ("PIT - formy i KUP (★)", [
            "rules/pit/forms.rego", "rules/pit/kup.rego", "rules/pit/kup_extended.rego",
            "rules/pit/advances_returns.rego", "rules/pit/exemptions.rego"]),
        ("Ulgi PIT (★★)", [
            "rules/pit/rd_relief_enterprise.rego", "rules/pit/ipbox_enterprise.rego",
            "rules/pit/missing_reliefs_enterprise.rego", "rules/pit/donation_relief_enterprise.rego",
            "rules/pit/cross_relief_optimizer_enterprise.rego", "rules/pit/art21_exemptions_enterprise.rego"]),
        ("Formy / przejscia / deklaracje (★★)", [
            "rules/pit/tax_form_transition_intelligence.rego",
            "rules/form_transition_simulator_enterprise.rego",
            "rules/annual_declaration_enterprise.rego"]),
        ("PIT mikro (★)", [
            "rules/micro/pit/pit.rego", "rules/micro/plan33_pit.rego", "rules/micro/plan34_pit.rego"]),
        ("Innowacje PIT (★)", [
            "rules/p04_pit_macro_innovations_v8.rego", "rules/p06_pit_micro_innovations_v8.rego",
            "rules/r04_pit_core_innovations_v9.rego"]),
        ("Narzedzia (★)", [
            "tools/pit_micro_inventory.py", "tools/pit_macro_audit.py", "tools/pit_reliefs_optimizer.py"]),
        ("Testy i dokumentacja (★)", [
            "tests/rego/micro/test_native_micro_pit.rego", "docs/PIT_MACRO_P05.md", "docs/PIT_MICRO_P06.md"]),
     ]),
    # 04
    ("04", "ZUS + SKLADKA ZDROWOTNA (DRA, ULGI, ZASILKI, PPK/PFRON)", "04_ZUS_HEALTH",
     "01,03,05,12,14",
     "Ustawa z 13.10.1998 o systemie ubezpieczen spolecznych (Dz.U. 2025 poz. 345): "
     "art. 6 (objetowanie), 9 (zbieg etat+JDG), 11-12 (chorobowe), 18 (podstawa), "
     "18a (ulga na start - 6 mies.), 18c (maly ZEF+ 36 mies.), 22 (stopy), 36 (terminy) "
     "47; ustawa z 27.08.2004 o swiaterniach (art. 79-81: skia zdrowotna 9% skala, "
     "4.9% liniowy, 4.9% rycz wg progow 3-tier: 60K->60% przecietnej, 60-300K->100%, "
     ">300K->180%); PPK; PFRON; DRA.",
     "LUKI: limit zdrowotny liniowy 12 900 PLN do weryfiwacji; okresy ulg 24 mies. "
     "i 36 podstawa; brak walidatora DRA; brak testu zbiegu; 240+ stolki w sus/micro; "
     "normalizacja nazw",
     "1) DRA Reconcilement (zaplaty <-> zobowiazania, niemutowalnosc); "
     "2) kalkulator optymalnej skladki wg formy ze sprzezeniem z ryczaltem; "
     "3) tracker okresow preferencyjnych + alerty; 4) symulator zasilku; "
     "5) temporal time analytics; 6) PPK-opt wg progow; 7) PFRON relase; "
     "8) Decision Certificate dla kazej skladki.",
     [
        ("ZUS makro (★)", [
            "rules/zus.rego", "rules/zus/plan23_interactions.rego", "rules/zus/plan42_benefits.rego",
            "rules/zus/enterprise_benefits.rego", "rules/zus/sickness_benefits_enterprise.rego",
            "rules/zus/health_contribution_enterprise.rego", "rules/zus/health_precision_engine_v8.rego",
            "rules/zus/zus_enterprise_zero_doubt.rego"]),
        ("ZUS mikro (★)", [
            "rules/micro/sus/sus.rego", "rules/micro/plan33_zus.rego", "rules/micro/plan34_zus.rego",
            "dir:rules/micro/zdrowotna", "dir:rules/micro/zasilkowa"]),
        ("Ulgi i PPK (★)", [
            "rules/ppk_pfron_enterprise.rego", "rules/p07_zus_macro_innovations_v8.rego",
            "rules/p08_zus_micro_innovations_v8.rego"]),
        ("Narzedzia (★)", [
            "tools/zus_calculator.py", "tools/zdrowotna_tier_engine.py", "tools/zus_micro_quality.py",
            "tools/health_reconciliation_micro.py", "tools/contribution_base_validator.py"]),
        ("Testy i dokumentacja (★)", [
            "tests/rego/micro/test_native_micro_zus.rego", "docs/ZUS_MACRO_P07.md", "docs/ZUS_MICRO_P08.md"]),
     ]),
    # 05 Ksiegowosc
    ("05", "KSIEGOWOSC: PKPiR + UoR + AMORTYZACJA (double-entry)", "05_KSIEGOWOSC",
     "01,03,04,13,15,16",
     "Ustawa o rachunkowosci z 29.09.1994 (Dz.U. 2025 poz. 567): art. 2 (obowiazek), "
     "4 (zasady: memoria!, wspolmiernosc, ostroznosc), 20 (dowody ksiegowe), 21-22 "
     "(zapis podwojny), 26 (inwentaryzacja), 28, 32 (amortyzacja), 74 (retencja); "
     "rozporzadenie MF z 15.11.2025 (PKPiR); PIT art. 24a; ryczalt art. 15; "
     "VAT art. 109 (ewidencje).",
     "LUKI: 56 regu PKPiR ma matched:false (martwa warstwa); brak walidatora kolumn "
     "PKPiR; remanent bez wsparcia; double-entry w UoR czesciowy; bez reconciliation "
     "z JPK_B.",
     "1) Double-Entry Gate (debet=credit, zero nierownowagi);2) PKPiR Columns Validator (K1-K13 wg rozporzadzenia PKPiR); 3) remanent auto ze Zbioru; 4) symulator "
     "amortyzacji (stopy, limity, metody); 5) transformacja PKPiR->UoR; "
     "6) rozrachunki i salda; 7) plan kont referencyjny; 8) reconcile z JPK_B.",
     [
        ("Ksiegowosc makro (★)", [
            "rules/accounting.rego", "rules/accounting/pkpir_enterprise_live.rego",
            "rules/accounting/pkpir_enterprise_validation.rego",
            "rules/accounting/depreciation_enterprise_complete.rego",
            "rules/accounting/plan23_leasing.rego", "rules/accounting/plan42_pkpir.rego"]),
        ("UoR (★)", [
            "rules/uor/plan42_uor.rego", "rules/micro/uor/uor.rego", "rules/p12_uor_innovations_v8.rego"]),
        ("PKPiR mikro (★)", [
            "rules/micro/pkpir/pkpir.rego", "rules/micro/pkpir/pkpir_kolumny.rego",
            "rules/micro/pkpir/pkpir_przychody.rego", "rules/micro/pkpir/pkpir_koszty.rego",
            "rules/micro/pkpir/pkpir_nkup.rego", "rules/micro/pkpir/pkpir_remanent.rego",
            "rules/micro/pkpir/pkpir_korekty.rego"]),
        ("Amortyzacja (★)", [
            "rules/micro/amortyzacja/pit_a22a.rego", "rules/micro/amortyzacja/pit_a22b.rego",
            "rules/micro/amortyzacja/pit_a22c.rego", "rules/micro/amortyzacja/pit_a22h.rego",
            "rules/micro/amortyzacja/pit_a22i.rego", "rules/micro/amortyzacja/pit_a22k.rego",
            "rules/micro/amortyzacja/pit_a22n.rego"]),
        ("Narzedzia (★)", [
            "tools/p11_accounting_toolkit.py", "tools/p12_uor_accounting_toolkit.py",
            "tools/uor_double_entry.py", "tools/pkpir_engine.py", "tools/depreciation_engine.py"]),
        ("Testy i dokumentacja (★)", [
            "tests/test_pkpir_uor_enterprise.py", "docs/KSIEGOWOSC_PKPIR_UOR_P09.md"]),
     ]),
    # 06 KKS
    ("06", "KKS - KODEKS KARNY SKARBOWY", "06_KKS", "01,07,13,15,16",
     "KKS z 10.09.1999 (Dz.U. 2025 poz. 678): art. 16 (czynny zal), 44 (przedawnienie), "
     "53 (wykliczenie), 54 (uchylanie), 56 (nierzetelne ksiegi/PKiR), 57 (nierzetelna "
     "ewidencja VAT), 62 par. 2 (karta), 76-77 (niezlozenie deklaracji), 83 (uspiech), "
     "par. 10 program gradient; grzywny/każenie wg stopnia spolecznego niebezpieczenstwa i "
     "recydywy; przepis marialny.",
     "LUKI: ok. 78 regul art. 54-83 brak; malen male wartosc vs istotna zgodn. z "
     "praktyka; integracja z Ordynacja (art. 70); brak kalend przynowniane; "
     "sciezki procedur: 4-sciezKŹ (dobrowolne, czynny zal, postepowanie, sad).",
     "1) PenaltySim v4 (sciezki, kamulacja kar); 2) lancuch dowodowy KKS z podpisem; "
     "3) limity malych wartosci temporalne; 4) podwojne przedawnienia KKS+ORd; "
     "5) auto-trigger czynnego zalu (art. 16); 6) klasyfikator ryzyka kontrahenta; "
     "7) monitor 4-5% upomnienia; 8) Decision Narrative PL.",
     [
        ("KKS makro (★★★)", [
            "rules/kks.rego", "rules/kks/enterprise_penalties.rego", "rules/kks/kks_extensions_enterprise.rego",
            "rules/kks/kks_innovations_v8.rego", "rules/kks/plan42_detailed.rego",
            "rules/kks/plan43_decomposition.rego", "rules/kks/plan44_kks_conviction.rego"]),
        ("KKS mikro (★)", [
            "rules/micro/kks/kks.rego", "rules/micro/kks_ord_atomic_p11.rego", "rules/micro/plan33_kks.rego"]),
        ("Narzedzia (★)", [
            "tools/kks_penalty_simulator.py", "tools/kks_voluntary_disclosure.py",
            "tools/kks_limitations_calendar.py", "tools/kks_risk_scorer.py",
            "tools/kks_completeness_matrix.py", "tools/kks_penalty_auditor.py"]),
        ("Testy i dokumentacja (★)", [
            "tests/test_kks_enterprise.py", "docs/KKS_P10.md"]),
     ]),
    # 07 ORDYNACJA
    ("07", "ORDYNACJA PODATKOWA", "07_ORDYNACJA", "01,06,08,14,16",
     "Ordynacja podatkowa z 29.08.1997 (Dz.U. 2025 poz. 234): art. 14a-14d "
     "(interpretacje), 16-16c (czynny zal), 20-21, 48 (odroczenie), 51 (umorzenie), "
     "53-56 (odsetki), 67a-67e (ulgi w splacie), 70-71 (przedawnienie 5 lat), "
     "72-80 (nadplata), 81-81b (korekty), 86-87, 117ba (kredyt biala 15k, 30 dni), "
     "119a (GAAR), 120-129 (postepowanie), 138a-138o (pelnomocniczy), 193a (JPK).",
     "LUKI: interpretacje nie sparowane z reguami (Legal Twin); brak kalendarza "
     "przedawnien operacyjn; korekta uproszczona; brak raka w zakresie naruszenie "
     "zalom; brak proks spadknic.",
     "1) PrzedawnienieTracker z 2 flag (zawieszenie/wznowienie); 2) auto-claim nadplaty; "
     "3) korekta 81-81b z symulatorem; 4) rejestr pełnomocniczych; 5) radar zmian ORD "
     "(2026); 6) mapy interpretacji w Legal Twin; 7) kalkulator odsetek 53-56; "
     "8) e-protokol postepowania.",
     [
        ("Ordynacja (★★)", [
            "rules/ord/ord_innovations_v8.rego", "rules/micro/ord/ord.rego", "rules/micro/plan33_ord.rego",
            "rules/micro/plan34_ord.rego", "rules/kks_ord_etap16_v1.rego"]),
        ("Zobowiazania / przedawnnia / ulgi (★)", [
            "rules/liability.rego", "rules/statute_of_limitations.rego", "rules/ord_supplements_enterprise.rego"]),
        ("Narzedzia (★)", [
            "tools/limitations_calendar.py", "tools/ordpu_auditor.py",
            "tools/penalty_calculator.py"]),
        ("Testy i dokumentacja (★)", [
            "tests/test_kks_ord_etap16_audit.py", "docs/ORDYNACJA_PODATKOWA_P11.md"]),
     ]),
    # 08 CROSSBORDER
    ("08", "CROSS-BORDER / TP / CFC / MDR-DAS6 / ZIDETY / EXIT", "08_CROSSBORDER",
     "01,02,10,13,15",
     "VAT: art. 28a-28n (uslugi), WDT/WNT/eksport (41-42, 97-99), EB-a; PIT: art. 9, "
     "14 ust. 2c (kursualne), 22 (KUP), 23m-23z (TP), 30f (CFC), 30da (exit), "
     "30ca (IP e); ORD: art. 86a-86d (MDR/DAC6); Dyrektywa ViDA 2026-2030; "
     "post-Brexit (Wielka Brytania).",
     "LUKI: exit/CFC klasa B/C; TP-doc czesciowy; ViDA/DST zalazek; MDR hallmarks "
     "druizne; brak rejestry 10 porownawcze (OECD).",
     "1) Transfer Pricing Complete (TPR-C, osw); 2) CFC Monitor (testy 50%/33%); "
     "3) Exit Tax Calculator; 4) MDR-DAC6 filing; 5) ViDA plan implementacji; "
     "6) VAT-UE registry ops; 7) risk scorer transgran; 8) generator doc TP.",
     [
        ("Cross-border (★)", [
            "rules/crossborder.rego", "rules/crossborder/plan23_ue.rego",
            "rules/crossborder/post_brexit.rego", "rules/crossborder/exit_tax_cfc_complete.rego",
            "rules/micro/crossborder/crossborder.rego", "rules/micro/plan33_cb.rego"]),
        ("TP / CFC / MDR (★)", [
            "rules/tp/plan44_tp.rego", "rules/tp/plan45_tp.rego", "rules/cfc_auto_classifier.rego",
            "rules/mdr/mdr_hallmarks.rego", "rules/mdr/mdr_enterprise.rego",
            "rules/mdr/plan44_mdr.rego", "rules/mdr/plan45_mdr.rego"]),
        ("International + ViDA (★)", [
            "rules/international.rego", "rules/international_expanded.rego", "rules/vida_drr_full.rego"]),
        ("Narzedzia (★)", [
            "tools/crossborder_quality.py", "tools/mdr_scorer.py", "tools/cfc_classifier.py",
            "tools/tp_documentation_engine.py"]),
        ("Testy i dokumentacja (★)", [
            "tests/test_crossborder_etap17_audit.py", "docs/CROSSBORDER_P12.md"]),
     ]),
    # 09
    ("09", "RYCZALT + FORMY + CYKL ZYCIA JDG (CEIDG, PRZERWA, SUKCESJA)", "09_RYCZALT",
     "01,03,04,10,13,15",
     "Ustawa z 20.11.1998 o ryczałtowym podatku (Dz.U. 2025 poz. 234): art. 6-12 "
     "(stawki PKWIU 2-17%), 6e (limit 2 000 000 EUR), 21-30 (karta), 15 (ewidencja); "
     "CEIDG 2018 (wpis, zmiana, wykreślenie); Prawo przedsiebiorcy art. 22-25 "
     "(zawieszenie); ustawa o zarzadze sukcesanym 2018 (art. 3-4, 12-15); "
     "dzialalnosc nieewidencjonowana (PP art. 5).",
     "LUKI: niezglosz dna (brak automatycznego miernika progu 2M EUR); estonski bez "
     "procedur; business_lifecycle_etap18 jest tylko 1 reg; zwiazek z form uncertainties.",
     "1) FormAdvisor: 5-prog (skala/liniowy/ryczalt/karta) z checkpointem; "
     "2) limit 2M EUR progress bar; 3) zawieszenie - checklist B2B; "
     "4) Succession Planner 2 lata; 5) state machine cyklu; "
     "6) stawki PKWIU (obwieszczenie) z walidatora; 7) klasyfikator PKWIU; "
     "8) rejestr CEIDG z alertami.",
     [
        ("Ryczalt (★)", [
            "rules/micro/ryczalt/ryczalt.rego", "rules/micro/ryczalt_cykl_atomic_p13.rego",
            "rules/micro/plan33_ryc.rego", "tools/ryczalt_zus_health_harmonizer.py"]),
        ("Cykl zycia JDG (★)", [
            "rules/business.rego", "rules/business_lifecycle_etap18_v1.rego",
            "rules/business/plan26_suspension_succession.rego", "rules/business/gig_economy.rego"]),
        ("CEIDG / sukcesja (★)", [
            "rules/micro/ceidg/ceidg.rego", "rules/micro/plan33_ceidg.rego",
            "rules/micro/sukcesja/sukcesja.rego", "rules/micro/plan33_succ.rego"]),
        ("Narzedzia (★)", [
            "tools/lifecycle_navigator.py", "tools/zawieszenie_simulator.py", "tools/sukcesja_planner.py",
            "tools/ryczalt_rate_validator.py", "tools/pkwiu_classifier.py"]),
        ("Testy i dokumentacja (★)", [
            "tests/test_business_lifecycle_etap18_audit.py", "docs/RYCZALT_CYKL_ZYCIE_P13.md"]),
     ]),
    # 10
    ("10", "PCC + LOKALNE + AKCYZA (PCC-3, DN-1, DT-1)", "10_PCC_LOKALNE",
     "01,02,13,14,16",
     "Ustawa o PCC z 9.09.2000 (Dz.U. 2025 poz. 789): art. 1-10 (umowy, stawki "
     "0.5/1/2%, zw.). art. 7-8; dekl. PCC-3 w 14 dni. Pod: lokalne z 12.01.1991 "
     "(nieruchomosci art. 2-7, srodki transportu 8-12); ust. o akcyzie z 6.12.2008 "
     "(paliwa 29-32, alkohol 92-99, tytoniowe; zezwolenia, ED docs).",
     "LUKI: 4/80 lok lokale; PKC 3/51; nieresowanie PCC-3 (14 dni) vs akcyza;",
     "1) DN-1/DT-1 generator; 2) synchronizacja stawiek GUS/gmina; "
     "3) auto-PCC-3 z kalendarzem; 4) akcyza classifier (CN 8); 5) rejestr "
     "lokalny per jednosta; 6) akcyza vs VAT krotka; 7) wnioski/zezw IU; "
     "8) mapy stawkowe per gmina.",
     [
        ("PCC (★)", ["rules/local_taxes/pcc.rego", "rules/local_taxes/pcc_enterprise_complete.rego",
            "rules/local_taxes/pcc_excise_enterprise.rego", "rules/micro/pcc/pcc.rego",
            "rules/micro/plan33_pcc.rego"]),
        ("Lokalne (★)", ["rules/local_taxes.rego", "rules/local_taxes/real_estate.rego",
            "rules/local_taxes/transport.rego", "rules/local_taxes/plan26_local.rego", "rules/micro/plan33_prop.rego"]),
        ("Akcy za (★)", ["rules/local_taxes/akcyza_alcohol.rego", "rules/local_taxes/akcyza_fuel.rego",
            "rules/local_taxes/excise_enterprise_complete.rego", "rules/micro/akcyza/akcyza.rego"]),
        ("Narzedzia (★)", ["tools/pcc_engine.py", "tools/gmina_rates_engine.py", "tools/akcyza_classifier.py",
            "tools/dn1_dt1_generator.py"]),
        ("Testy i documentacja (★)", ["tests/test_pcc_excise_enterprise.py", "docs/PCC_LOKALNE_AKCYZA_P14.md"]),
     ]),
]