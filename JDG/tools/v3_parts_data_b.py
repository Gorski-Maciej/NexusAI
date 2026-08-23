#!/usr/bin/env python3
"""Dane czesci 11-20 kampanii V3 (rozszerzone).

Format: (num, tag, out, cons, scope, luki, pomysly, groups)
"""

PARTS_B = [
    # 11
    ("11", "KSEF + BIALA LISTA + E-DORECZENIA + ePUAP + WIS + ESIG", "11_KSEF_JPK",
     "01,02,08,15,17,18",
     "VAT art. 106na-106nq (KSeF; obowiazek od 01.02.2026), art. 106e (elementy faktury), "
     "ustawa z 16.06.2023 (Dz.U. 2023 poz. 1598), rozporzadzenie MF o strukturze JPK_V7M "
     "(2025), ustawa o e-Doreczeniach 2020 (art. 8-9, 155), informatyzacja (ePUAP), "
     "WIS art. 42a-42h, eIDAS (910/2014), JPK_KR/ST.",
     "LUKI: brak walidacji UPO i okna offline 7 dni; sandbox bez asercji; brak monitora "
     "kar KSeF (do 500 tys.); e-doreczenia 2026 - weryfikacja adresu; b2c bez NIP.",
     "1) KSeF State Machine z UPO tracker; 2) offline queue 7 dni z retry; "
     "3) JPK_V7M auto-generator skorelowany z KSeF; 4) e-Doreczenia calendar; "
     "5) ePUAP auto-podpis (ESig); 6) WIS requester z cache; 7) monitoring sankcji "
     "KSeF (do 500 tys.); 8) reconcile JPK <-> KSeF (hash).",
     [
        ("KSeF (★)", ["rules/ksef_innovations_enterprise.rego", "rules/ksef_outbox_enterprise.rego",
            "rules/ksef_offline_queue_enterprise.rego", "rules/ksef_sandbox_harness_enterprise.rego",
            "rules/ksef_upo_tracker_enterprise.rego", "rules/ksef_receipt_digest_enterprise.rego",
            "rules/ksef_sanction_monitor_enterprise.rego"]),
        ("JPK (★)", ["rules/jpk_v7_autogen_enterprise.rego", "rules/jpk_corrections_workflow_enterprise.rego",
            "rules/jpk_kr_st_generator_enterprise.rego", "rules/jpk_cit.rego", "rules/micro/jpk/jpk.rego",
            "rules/micro/plan33_jpk.rego"]),
        ("E-deklaracje i doreczenia (★)", ["rules/edelivery_gateway_enterprise.rego",
            "rules/edelivery_gateway_v2_enterprise.rego", "rules/epuap_enterprise.rego",
            "rules/esig_auto_applicator_enterprise.rego", "rules/wis_autorequester_enterprise.rego",
            "rules/wis_api_enterprise.rego"]),
        ("Narzedzia (★)", ["tools/ksef_outbox.py", "tools/ksef_offline_queue.py", "tools/jpk_validator.py",
            "tools/jpk_autogen.py", "tools/edelivery_monitor.py"]),
        ("Testy i dokumentacja (★)", ["tests/test_ksef_jpk_etap20_audit.py",
            "docs/KSEF_JPK_EDEKLARACJE_P17.md"]),
     ]),
    # 12
    ("12", "RODO + AML + BDO + SRODOWISKO + HR", "12_RODO_AML_BDO", "01,04,05,14,16",
     "RODO (UE 2016/679): art. 5-13, 15-22, 24-35, 37, 44-49, 82-83; ustawa z 1.03.2018 "
     "o AML (Dz.U. 2025 poz. 213): art. 2, 28-34, 74-80, 153; ustawa o odpadach (BDO) "
     "z 14.12.2012: art. 17-18, 41-48, 49-55, 66-74, 194, 233; PPK 2018; HR.",
     "LUKI: rejestr czynnosci i powierzenia niekompletny; CBDD progi i beneficjenci "
     "rzeczywisci; BDO KPO (waznosc 5 lat); zgodnosc RODO dla AI; braki w "
     "rodo_extended.",
     ["1) RODO Register Generator + zglozenie 72h; 2) AML-CBDD engine z progami; "
      "3) STR auto-raport; 4) BDO ewidencja (KPO, kody 2-27); 5) erasure engine (art. 17); "
      "6) DPIA robot; 7) HR swiadczenia (mpips); 8) Decision Certificate dla zgody."],
     [
        ("RODO (★★)", ["rules/rodo.rego", "rules/rodo_extended.rego", "rules/micro/rodo/rodo.rego",
            "rules/micro/plan33_rodo.rego"]),
        ("AML+CBDD (★★)", ["rules/micro/aml/aml.rego", "rules/micro/aml/aml_cbdd.rego",
            "rules/micro/aml/aml_ryzyko.rego", "rules/micro/aml/aml_str_gif.rego",
            "rules/micro/aml/aml_transakcje.rego"]),
        ("BDO/srodowisko (★★)", ["rules/environmental.rego", "rules/environmental/bdo_enterprise.rego",
            "rules/micro/srodowisko/srodowisko.rego"]),
        ("HR (★★)", ["rules/mpips.rego", "rules/employer.rego", "rules/ppk_pfron_enterprise.rego"]),
        ("Narzedzia (★★)", ["tools/rodo_register_generator.py", "tools/aml_cbdd_engine.py",
            "tools/str_generator.py", "tools/bdo_ewidencja_engine.py", "tools/erasure_engine.py"]),
        ("Testy i dokumentacja (★★)", ["tests/test_aml_enterprise.py", "tests/test_bdo_enterprise.py",
            "docs/RODO_AML_BEZPIECZENSTWO_P16.md", "docs/SRODOWISKO_BDO_P15.md"]),
     ]),
    # 13 MICRO
    ("13", "WARSTWA MICRO - NAPRAWA 53 PLIKOW (SKLADNIA, PUSTE POLA)", "13_MICRO", "ALL",
     "Pakiety JDG/rules/micro (pit, kks, ord, ryczalt, sus, uor, amortyzacja, pkpir, "
     "amL, rodo, bdo, ksef, jpk, pcc, akcyza, sukcesja, ceidg, srodowisko, "
     "crossborder, plan33/34) + testy natywne. Cel: zamiana szablonow na reguly z "
     "logika prawna (legal_basis, progi, temporalnosc).",
     "LUKI: 54 pliki z blednym przecinkiem (wzorzec priority 999999); 7 977 pustych "
     "pol; staby/tautologii; testy natywne identyczne dla input {}; powielenie makro.",
     ["1) naprawa skladni + opa check w CI; 2) PORownawczy generator warunkow; "
      "3) mapa mikro->makro (bind verdyktu); 4) testy semantyczne (golden input); "
      "5) rejestr rule_id bez duplikatow; 6) tryb DECOUPLED; 7) auto-doc per artykul; "
      "8) monitor rozjazdu mikro/makro."],
     [
        ("Mapa mikro (★★★)", ["rules/micro/GENERATION_SUMMARY.txt", "dir:rules/micro"]),
        ("Pliki mikro kluczowe (★★)", ["rules/micro/pit/pit.rego", "rules/micro/kks/kks.rego",
            "rules/micro/ord/ord.rego", "rules/micro/ryczalt/ryczalt.rego", "rules/micro/sus/sus.rego",
            "rules/micro/uor/uor.rego"]),
        ("Testy natywne (★★)", ["tests/rego/micro/test_native_micro_pit.rego",
            "tests/rego/micro/test_native_micro_vat.rego", "tests/rego/micro/test_native_micro_kks.rego"]),
     ]),
    # 14 hyper
    ("14", "HYPER CONTEXTS PLAN44/45 - DEADLINES, LIMITS, KALENDARZE", "14_HYPER_CTX",
     "01,03,07,11,15,16",
     "Zakres: katalog kontekstow (general, deadlines, limits, sanctions, mdr, fx, "
     "audyt, edelivery, family, force_majeure, procurement, solidarity, wis, "
     "residency, tp, esig) - kalendarz podatkowy (VAT 25., PIT 20/30.04, ZUS "
     "5/10/15/20, JPK 25.), limity, sankcje.",
     "LUKI: plan45 491 regu niejust spójnych; deadline engine czesciowy; brak "
     "powiazan z cz. 07 (przedawnienia) i cz. 04 (ZUS); registry bez walidacji.",
     ["1) Fiscal Calendar Engine z kontuarem dow; 2) jedyny registry deadlineow; "
      "3) sankcje map (KKS vs ORD); 4) Family 4+ z progress; 5) edelivery tracker; "
      "6) force majeure - provizja; 7) fx auto-kalk; 8) sprzenge z Golden replay."],
     [
        ("Hyper Plan44/45 (★)", ["rules/jdg/hyper/general/plan45.rego", "rules/jdg/hyper/deadlines/plan45.rego",
            "rules/jdg/hyper/limits/plan45.rego", "rules/jdg/hyper/sanctions/plan45.rego",
            "rules/jdg/hyper/mdr/plan45.rego", "rules/jdg/hyper/fx/plan45.rego",
            "rules/jdg/hyper/audit/plan45.rego", "rules/jdg/hyper/family/plan45.rego"]),
        ("Kalendarze i deadlines (★)", ["rules/calendar/plan44_calendar.rego", "rules/calendar/plan45_calendar.rego",
            "rules/conviction/plan44_conviction.rego", "rules/conviction/plan45_conviction.rego"]),
        ("Pozostale (★)", ["rules/edelivery/plan44_edelivery.rego", "rules/family/plan44_family.rego",
            "rules/fx/plan44_fx.rego", "rules/insurance/plan44_insurance.rego"]),
        ("Narzedzia (★)", ["tools/deadline_engine.py", "tools/legal_change_calendar.py",
            "tools/limits_registry.py", "tools/sanction_calculator.py", "tools/hyper_quality.py"]),
        ("Testy (★)", ["tests/test_hyper_plan45_enterprise.py"]),
     ]),
    # 15
    ("15", "INICJATYWY ENTERPRISE S1-S24 + NEURONAL MESH + SCORING", "15_ENTERPRISE",
     "01,05,11,13,16,17",
     "Zakres: inicjatywy S1-S24 (auto-deklaracje, autogen JPK_V7M, KSeF resilience, "
     "banking PSD2, legislatywny monitor, optymalizacja, cross-domain intelligence, "
     "red team, strategic advisor, defencja audytowa), Neural Mesh, Decision Scoring "
     "(Trust Score), taxonomy.",
     "LUKI: inicjatywy niekompletne (estoński CIT); overlap z domenami; decision "
     "scoring bez kalibracji; neural mesh skromny.",
     ["1) Trust Score v2 (multi-warstwowy); 2) Auto-Strategy Engine (wybor formy); "
      "3) Decision Composer z kontraktem; 4) cross-domain intelligence; "
      "5) red team jako CI; 6) predykcje wynikow; 7) symulacje what-if; 8) SLO dashboard."],
     [
        ("Enterprise: wybrane (★)", ["rules/hyper_plan45_meta_enterprise.rego",
            "rules/enterprise_ai_neural_etap23_v1.rego", "rules/neural_mesh_v2_enterprise.rego",
            "rules/decision_scoring_enterprise.rego", "rules/cross_domain_intelligence_enterprise.rego",
            "rules/cross_domain_red_team_etap27_v1.rego", "rules/tax_optimization_enterprise.rego"]),
        ("Neural mesh (★)", ["rules/neural_rule_mesh_enterprise.rego", "rules/decision_composer_enterprise.rego"]),
        ("Narzedzia (★)", ["tools/autonomous_tax_strategy.py", "tools/cross_domain_red_team_etap27_audit.py",
            "tools/penalty_calculator.py", "tools/decision_quality_monitor.py"]),
     ]),
    # 16 GATES
    ("16", "NARZEDZIA + BRAMKI JAKOSCI + GAP REPORTS", "16_GATES", "01,02,05,13,17,18",
     "Zakres: linter Rego (6 checks), validate (9), dead_rule_detector, "
     "tautology_guard, else_chain_dead_code, hardcoded_audit_gate, legal "
     "coverage gap report, heatmap, traceability, inventory, doc_consistency, "
     "cross_ref_validator, manifest_v2.",
     "LUKI: bramki sprawdzaja stringi, nie skladnie; brak gate na puste pola; "
     "coverage_95 nieaktywny; brak walidacji 54 plikow micro.",
     ["1) Zero-hardcode gate; 2) empty-field gate (0 pol); 3) coverage 95 w CI; "
      "4) SLO dashboard; 5) manifest diff blokujacy; 6) tautology gate; "
      "7) mutacja regol automatyczna; 8) gate legal_basis z rejestru."],
     [
        ("Lintery i walidatory (★)", ["tools/lint_rego_rules.py", "tools/validate_rules.py",
            "tools/dead_rule_detector.py", "tools/tautology_guard.py",
            "tools/else_chain_dead_code_detector.py", "tools/hardcoded_audit_gate.py"]),
        ("Gap reports (★)", ["tools/legal_coverage_gap_report.py", "tools/legal_coverage_heatmap.py",
            "tools/traceability_matrix.py", "tools/coverage_95_plan.py", "tools/legal_basis_audit.py"]),
        ("Spójnosc (★)", ["tools/doc_consistency_validator.py", "tools/cross_ref_validator.py",
            "tools/inventory_reconciliation.py", "tools/manifest_v2.py"]),
        ("Bramki quality gates (★)", ["tools/test_coverage_gate.py", "tools/validate_enterprise_contract.py",
            "tools/temporal_interval_gate.py"]),
     ]),
    # 17 TESTS
    ("17", "TESTY + CI/CD + CHAOS + MUTATION + GOLDEN", "17_TESTY_CI", "01,13,15,16,18,20",
     "Zakres: testy pytest (198) + natywne Rego (207), golden verdicts (12m), "
     "mutation runner, chaos runner, fuzz, property, workflows CI (ci, opa-ci, "
     "jdg-quality-gates-blocking, jdg-scheduled-drift), kana ry.",
     "LUKI: testy tautologiczne; golden bez diff a prawnego; brak automatycznej "
     "rejestracji regresji; CI wymaga opa - check; bramka 13/14.",
     ["1) Golden Verdicts v2 z diff prawnym (F3); 2) replay historyczny na PR; "
      "3) mutation coverage blokowany; 4) chaos jako CRON; 5) fuzz schema KSeF/JPK; "
      "6) kalibracja srednich bledow; 7) raporty CI; 8) gate 100% natywnych dla "
      "krytycznych pakietow."],
     [
        ("Testy (★)", ["tests/rego/micro/test_native_micro_pit.rego",
            "tests/rego/micro/test_native_micro_vat.rego", "tests/test_final_certification_etap28_audit.py"]),
        ("Chaos / mutation / fuzz (★★)", ["tools/chaos_runner.py", "tools/fuzz_runner.py",
            "tools/mutation_runner.py", "tools/property_suite.py", "tools/golden_replay.py"]),
        ("CI/CD workflows (★★)", [".github/workflows/ci.yml", ".github/workflows/opa-ci.yml",
            ".github/workflows/jdg-quality-gates-blocking.yml"]),
     ]),
    # 18 BUNDLES/MIGRACJE
    ("18", "BUNDLES + POLICIES MIRROR + RULESTORE + MIGRACJE + DEPLOY", "18_BUNDLES",
     "01,02,13,16,17,20",
     "Zakres: bundle.sh (v9.x), manifest.json, podpis, overlays v2026/v2027, mirror "
     "policies (546 plikow, hash-parity 0% drift), RuleStore DuckDB (13 migracje, "
     "9 tabel), data_service (hot-reload), deployment_orchestrator (canary), "
     "dr_orchestrator (RTO/RPO).",
     "LUKI: podpisy bunday bez weryfikacji lokalnie; overlay v2027 testy; mirror "
     "oraz generat; brak test& siły podpisu kryptograficznego.",
     ["1) Bundle sign + verify w CI (F2); 2) overlay matrix test; 3) hash-parity "
      "blokujaca (0% drift); 4) RuleStore seed wg obwieszczen; 5) hot-reload test; "
      "6) canary z rollback 5 min; 7) SBOM na kazdy bundle; 8) DR game-day co miesiac."],
     [
        ("Bundles (★)", ["bundles/bundle.sh", "dir:bundles"]),
        ("Overlays / policies (★)", ["tools/overlay_engine.py", "tools/overlay_generator.py",
            "policies", "policies/README.md"]),
        ("RuleStore / migracje (★)", ["dir:migrations", "migrations/001_jdg_rule_store.sql",
            "migrations/013_jdg_v18_tools_api_rulestore_bundles.sql"]),
        ("Narzedzia (★)", ["tools/bundle_server.py", "tools/deployment_orchestrator.py",
            "tools/data_service.py", "tools/dr_orchestrator.py", "tools/policies_sync_gate.py"]),
     ]),
    # 19 API
    ("19", "API + CONTROL PLANE + UI / CENTRUM DECYZJI", "19_API_UI", "01,11,15,17,20",
     "Zakres: api/openapi.yaml (17 endpointow, JWT), docs/API_REFERENCJA.md, "
     "api_spec_consistency, control_plane_lifecycle, rule_lifecycle_manager, "
     "declarative_change, centrum decyzji (AUTO_POST / SUGGEST / ASK_USER).",
     "LUKI: brak serwera (tylko spec); brak Flet; brak authZ testow; declarative "
     "change bez obslugi uzytka.",
     ["1) Litestar API z OpenAPI; 2) JWT+RBAC testy; 3) centrum decyzji web "
      "(AUTO_POST/SUGGEST/ASK_USER); 4) declarative change wizard; 5) rate-limit "
      "i idempotencja; 6) health/readiness; 7) API gateway wersignment; "
      "8) OpenAPI diff gate."],
     [
        ("API (★)", ["api/openapi.yaml", "docs/API_REFERENCJA.md", "tools/api_spec_consistency.py"]),
        ("Control Plane (★)", ["tools/control_plane_lifecycle.py", "tools/rule_lifecycle_manager.py",
            "tools/declarative_change.py", "docs/CONTROL_PLANE_RULE_LIFECYCLE.md"]),
        ("UI / centrum decyzji (★)", ["docs/PODRECZNIK_UZYTKOWNIKA.md"]),
     ]),
    # 20
    ("20", "DOKUMENTACJA + LEGAL TWIN + HARMONIZACJA KONCOWA", "20_DOKUMENTACJA", "ALL",
     "Zakres: Legal Twin (narzedzia, raporty, sledzenie powiazan regula-artykul), "
     "harmonizacja (MANIFEST v2, KATALOG_REGUL, SLOWNIK_REFERENCJI_PRAWNYCH, "
     "LEGAL_SOURCE_REGISTRY, GAP_REPORT, AUDYT_PODSTAW_PRAWNYCH), dokumentacja "
     "uzytkownika i FAQ, finalnie certyfikacja kampanii i rejestr V3.",
     "LUKI: Legal Twin bez pelnego sledzenia zmian (diff artykul -> rule_id); "
     "MANIFEST v2 moze nie zawierac nowych pakietow; brak gate spójnosci docs-rules; "
     "brak finalnego certyfikatu po kampanii V3.",
     "1) Legal Twin v2 - auto-trace artykul -> rule_id -> test; 2) dokumentacyjny "
     "gate (kazda regula ma legal_basis, kazdy legal_basis ma regule); 3) MANIFEST "
     "v3 auto-generowany z pakietow; 4) harmonizacja slownikow; 5) spójnosc docs "
     "z V1/V2; 6) finalny raport certyfikacji V3; 7) decision narrative PL; "
     "8) baseline README do stanu po kampanii.",
     [
        ("Legal Twin (★★)", ["tools/legal_twin.py", "tools/legal_twin_traceability.py",
            "tools/legal_twin_engine.py", "docs/LEGAL_TWIN_RAPORT.md",
            "docs/LEGAL_TWIN_TRACEABILITY.md"]),
        ("Harmonizacja (★★)", ["docs/LEGAL_COVERAGE_GAP_RAPORT.md",
            "docs/SLOWNIK_REFERENCJI_PRAWNYCH.md", "docs/LEGAL_SOURCE_REGISTRY.md",
            "docs/AUDYT_PODSTAW_PRAWNYCH.md", "docs/KATALOG_REGUL.md",
            "docs/KATALOG_NARZEDZI.md"]),
        ("Dokumentacja uzytkownika (★★)", ["docs/FAQ.md", "docs/LOGIKA_BIZNESOWA.md",
            "docs/ZGODNOSC_PRAWNA.md", "docs/PODRECZNIK_UZYTKOWNIKA.md"]),
        ("Certyfikacja (★)", ["tools/final_certification_etap28_audit.py",
            "tests/test_final_certification_etap28_audit.py"]),
     ]),
]