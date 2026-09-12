# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY NATYWNE V3-P51 PUSTYNIE PRAWNE (konwencja P39/P45–P50:
# negative-first, granice progów, fail-closed, never-silent AUTO_POST,
# bypass → BLOCK, determinizm else-chain).
# Uruchomienie: opa test (0.68) / opa19 test --v0-compatible (1.9)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p51_coverage_deserts_test

import data.jdg.v3_p51_coverage_deserts as p51

# ── Helper ─────────────────────────────────────────────────────────────────────
p51_input(analysis, ctx) = {"jdg_entrepreneur": {"v3_p51_check": true},
                            "v3_p51": object.union({"analysis": analysis}, ctx)}

# ═══════════════════════════════════════════════════════════════════════════════
# Determinizm łańcucha / aktywacja
# ═══════════════════════════════════════════════════════════════════════════════
test_p51_no_activation_no_match {
    r := p51.decide with input as {}
    r.rule_id == "jdg.v3_p51_coverage_deserts.no_match"
    r.matched == false
}

test_p51_no_selector_no_match {
    r := p51.decide with input as p51_input("brak_takiej_analizy", {})
    r.rule_id == "jdg.v3_p51_coverage_deserts.no_match"
}

test_p51_null_analysis_no_match {
    r := p51.decide with input as {"jdg_entrepreneur": {"v3_p51_check": true},
                                   "v3_p51": {"analysis": null}}
    r.rule_id == "jdg.v3_p51_coverage_deserts.no_match"
}

test_p51_thresholds_missing_fail_closed {
    # default-deny: brak snapshotu progów = BLOCK, nigdy cicha decyzja (AP07)
    r := p51.decide with input as p51_input("desert_register", {})
        with data.jdg.thresholds.v3_p51 as {}
    r.rule_id == "jdg.v3_p51_coverage_deserts.thresholds_missing"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
    r.priority == 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# I01: desert register (granice p0_max=0)
# ═══════════════════════════════════════════════════════════════════════════════
test_p51_i01_zero_deserts_autos {
    r := p51.decide with input as p51_input("desert_register", {
        "desert_register": {"desert_nodes": 0, "p0_count": 0,
                            "no_rule": 0, "rule_no_test": 0,
                            "test_no_rule": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
    r.desert_nodes == 0
}

test_p51_i01_deserts_triage {
    r := p51.decide with input as p51_input("desert_register", {
        "desert_register": {"desert_nodes": 159, "p0_count": 34,
                            "no_rule": 118, "rule_no_test": 41,
                            "test_no_rule": 0},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
    r.desert_nodes == 159
    r.p0_count == 34
}

test_p51_i01_no_p0_deserts_only_triages {
    # pustynie bez P0 → nadal TRIAGE (rejestr otwarty ≠ czysty stan)
    r := p51.decide with input as p51_input("desert_register", {
        "desert_register": {"desert_nodes": 5, "p0_count": 0,
                            "no_rule": 3, "rule_no_test": 2,
                            "test_no_rule": 0},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

test_p51_i01_register_bypass_blocks {
    r := p51.decide with input as p51_input("desert_register", {
        "desert_register": {"desert_nodes": 0, "p0_count": 0},
        "register_bypassed": true,
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I02: desert risk (scoring pustyni)
# ═══════════════════════════════════════════════════════════════════════════════
test_p51_i02_all_scored_no_p0p1_autos {
    r := p51.decide with input as p51_input("desert_risk", {
        "desert_risk": {"scored": 12, "unscored": 0,
                        "top_risk_score": 27, "p0_count": 0, "p1_count": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
    r.scored == 12
}

test_p51_i02_unscored_triages {
    r := p51.decide with input as p51_input("desert_risk", {
        "desert_risk": {"scored": 10, "unscored": 2,
                        "top_risk_score": 27, "p0_count": 0, "p1_count": 0},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
    r.unscored == 2
}

test_p51_i02_p0_open_triages {
    r := p51.decide with input as p51_input("desert_risk", {
        "desert_risk": {"scored": 159, "unscored": 0,
                        "top_risk_score": 64, "p0_count": 34, "p1_count": 68},
    })
    r.decision_mode == "TRIAGE"
    r.p0_count == 34
}

test_p51_i02_zero_scored_triages {
    # brak scoringu (scored<=0) = nie wiemy, które pustynie pilne → TRIAGE
    r := p51.decide with input as p51_input("desert_risk", {
        "desert_risk": {"scored": 0, "unscored": 0,
                        "top_risk_score": 0, "p0_count": 0, "p1_count": 0},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

test_p51_i02_risk_bypass_blocks {
    r := p51.decide with input as p51_input("desert_risk", {
        "desert_risk": {"scored": 1, "unscored": 0, "p0_count": 0, "p1_count": 0},
        "risk_bypassed": true,
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I03: desert cards (komplet kart TOP-10)
# ═══════════════════════════════════════════════════════════════════════════════
test_p51_i03_full_cards_autos {
    r := p51.decide with input as p51_input("desert_cards", {
        "desert_cards": {"cards_total": 10, "template_present": true},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
    r.cards_total == 10
}

test_p51_i03_missing_cards_triage {
    r := p51.decide with input as p51_input("desert_cards", {
        "desert_cards": {"cards_total": 4, "template_present": true},
    })
    r.decision_mode == "TRIAGE"
    r.cards_required == 10
}

test_p51_i03_no_template_blocks {
    r := p51.decide with input as p51_input("desert_cards", {
        "desert_cards": {"cards_total": 10, "template_present": false},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p51_i03_cards_bypass_blocks {
    r := p51.decide with input as p51_input("desert_cards", {
        "desert_cards": {"cards_total": 10, "template_present": true},
        "cards_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I04: chain metric (granica celu CCR=90%)
# ═══════════════════════════════════════════════════════════════════════════════
test_p51_i04_ccr_at_target_autos {
    r := p51.decide with input as p51_input("chain_metric", {
        "chain_metric": {"article_nodes": 251, "CCR_pct": 90.0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
    r.chain_target_pct == 90.0
}

test_p51_i04_ccr_below_target_triage {
    r := p51.decide with input as p51_input("chain_metric", {
        "chain_metric": {"article_nodes": 251, "CCR_pct": 36.65},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
    r.CCR_pct == 36.65
}

test_p51_i04_zero_articles_triage {
    # brak węzłów ARTICLE = skan nie wykonany → TRIAGE, nie AUTO
    r := p51.decide with input as p51_input("chain_metric", {
        "chain_metric": {"article_nodes": 0, "CCR_pct": 100.0},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

test_p51_i04_chain_bypass_blocks {
    r := p51.decide with input as p51_input("chain_metric", {
        "chain_metric": {"article_nodes": 251, "CCR_pct": 100.0},
        "chain_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I05: semi-auto drafting (fabryki stubów AP01 = BLOCK)
# ═══════════════════════════════════════════════════════════════════════════════
test_p51_i05_all_guarded_autos {
    r := p51.decide with input as p51_input("semi_auto_drafting", {
        "semi_auto_drafting": {"generators_total": 4, "generators_guarded": 4,
                               "legacy_stub_factories": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p51_i05_unguarded_generator_triage {
    r := p51.decide with input as p51_input("semi_auto_drafting", {
        "semi_auto_drafting": {"generators_total": 4, "generators_guarded": 0,
                               "legacy_stub_factories": 0},
    })
    r.decision_mode == "TRIAGE"
    r.generators_guarded_min == 4
}

test_p51_i05_stub_factory_blocks {
    # AP01: generator masowo produkujący {true} bez testów = fasada pokrycia
    r := p51.decide with input as p51_input("semi_auto_drafting", {
        "semi_auto_drafting": {"generators_total": 4, "generators_guarded": 2,
                               "legacy_stub_factories": 1},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
    r.legacy_stub_factories == 1
}

test_p51_i05_zero_generators_triage {
    r := p51.decide with input as p51_input("semi_auto_drafting", {
        "semi_auto_drafting": {"generators_total": 0, "generators_guarded": 0,
                               "legacy_stub_factories": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p51_i05_drafting_bypass_blocks {
    r := p51.decide with input as p51_input("semi_auto_drafting", {
        "semi_auto_drafting": {"generators_total": 4, "generators_guarded": 4,
                               "legacy_stub_factories": 0},
        "drafting_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I06: systemic sweep (pustynie systemowe)
# ═══════════════════════════════════════════════════════════════════════════════
test_p51_i06_zero_systemic_deserts_autos {
    r := p51.decide with input as p51_input("systemic_sweep", {
        "systemic_sweep": {"systemic_classes": 7, "active_systemic_classes": 0,
                           "systemic_deserts": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p51_i06_systemic_deserts_triage {
    r := p51.decide with input as p51_input("systemic_sweep", {
        "systemic_sweep": {"systemic_classes": 7, "active_systemic_classes": 3,
                           "systemic_deserts": 12},
    })
    r.decision_mode == "TRIAGE"
    r.systemic_deserts == 12
}

test_p51_i06_no_scan_triage {
    r := p51.decide with input as p51_input("systemic_sweep", {
        "systemic_sweep": {"systemic_classes": 0, "active_systemic_classes": 0,
                           "systemic_deserts": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p51_i06_systemic_bypass_blocks {
    r := p51.decide with input as p51_input("systemic_sweep", {
        "systemic_sweep": {"systemic_classes": 7, "systemic_deserts": 0},
        "systemic_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I07: law radar block (zmiany prawa bez planu reguły)
# ═══════════════════════════════════════════════════════════════════════════════
test_p51_i07_zero_unplanned_autos {
    r := p51.decide with input as p51_input("law_radar_block", {
        "law_radar_block": {"radar_present": true,
                            "changes_without_rule_plan": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p51_i07_unplanned_changes_triage {
    r := p51.decide with input as p51_input("law_radar_block", {
        "law_radar_block": {"radar_present": true,
                            "changes_without_rule_plan": 3},
    })
    r.decision_mode == "TRIAGE"
    r.changes_without_rule_plan == 3
}

test_p51_i07_radar_missing_triage {
    # fail-closed bramki: brak law_radar.json = TRIAGE, nigdy cichy AUTO_FILE
    r := p51.decide with input as p51_input("law_radar_block", {
        "law_radar_block": {"radar_present": false,
                            "changes_without_rule_plan": 0},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
    r.radar_present == false
}

test_p51_i07_radar_bypass_blocks {
    r := p51.decide with input as p51_input("law_radar_block", {
        "law_radar_block": {"radar_present": true,
                            "changes_without_rule_plan": 0},
        "radar_block_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I08: desert heatmap (kwadrant HIGH)
# ═══════════════════════════════════════════════════════════════════════════════
test_p51_i08_no_high_quadrant_autos {
    r := p51.decide with input as p51_input("desert_heatmap", {
        "desert_heatmap": {"scored_deserts": 5,
                           "quadrants": {"HIGH": 0, "MED": 2, "LOW": 2, "COLD": 1}},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p51_i08_high_quadrant_triage {
    r := p51.decide with input as p51_input("desert_heatmap", {
        "desert_heatmap": {"scored_deserts": 159,
                           "quadrants": {"HIGH": 34, "MED": 49, "LOW": 63, "COLD": 13}},
    })
    r.decision_mode == "TRIAGE"
    r.high_quadrant == 34
}

test_p51_i08_unscored_triage {
    r := p51.decide with input as p51_input("desert_heatmap", {
        "desert_heatmap": {"scored_deserts": 0, "quadrants": {}},
    })
    r.decision_mode == "TRIAGE"
}

test_p51_i08_heatmap_bypass_blocks {
    r := p51.decide with input as p51_input("desert_heatmap", {
        "desert_heatmap": {"scored_deserts": 1,
                           "quadrants": {"HIGH": 0, "MED": 0, "LOW": 1, "COLD": 0}},
        "heatmap_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I09: testless sweep (reguły bez testu + ghost testy)
# ═══════════════════════════════════════════════════════════════════════════════
test_p51_i09_zero_untested_autos {
    r := p51.decide with input as p51_input("testless_sweep", {
        "testless_sweep": {"rules_scanned": 12938, "rules_without_test": 0,
                           "ghost_tests": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p51_i09_untested_triage {
    r := p51.decide with input as p51_input("testless_sweep", {
        "testless_sweep": {"rules_scanned": 12938, "rules_without_test": 11282,
                           "ghost_tests": 24},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
    r.rules_without_test == 11282
    r.ghost_tests == 24
}

test_p51_i09_zero_scanned_triage {
    r := p51.decide with input as p51_input("testless_sweep", {
        "testless_sweep": {"rules_scanned": 0, "rules_without_test": 0,
                           "ghost_tests": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p51_i09_testless_bypass_blocks {
    r := p51.decide with input as p51_input("testless_sweep", {
        "testless_sweep": {"rules_scanned": 100, "rules_without_test": 0,
                           "ghost_tests": 0},
        "testless_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I10: quarterly goals (cele per domena)
# ═══════════════════════════════════════════════════════════════════════════════
test_p51_i10_goals_met_autos {
    r := p51.decide with input as p51_input("quarterly_goals", {
        "quarterly_goals": {"goals_total": 15, "missed": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p51_i10_goals_missed_triage {
    r := p51.decide with input as p51_input("quarterly_goals", {
        "quarterly_goals": {"goals_total": 15, "missed": 2},
    })
    r.decision_mode == "TRIAGE"
    r.missed == 2
}

test_p51_i10_no_goals_triage {
    r := p51.decide with input as p51_input("quarterly_goals", {
        "quarterly_goals": {"goals_total": 0, "missed": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p51_i10_goals_bypass_blocks {
    r := p51.decide with input as p51_input("quarterly_goals", {
        "quarterly_goals": {"goals_total": 15, "missed": 0},
        "goals_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I11: vacancy bridge (pustynie × stuby P45)
# ═══════════════════════════════════════════════════════════════════════════════
test_p51_i11_clean_state_autos {
    r := p51.decide with input as p51_input("vacancy_bridge", {
        "vacancy_bridge": {"combined_register_rows": 1, "stubs_total": 0,
                           "deserts": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p51_i11_stubs_or_deserts_triage {
    r := p51.decide with input as p51_input("vacancy_bridge", {
        "vacancy_bridge": {"combined_register_rows": 159, "stubs_total": 39,
                           "deserts": 159},
    })
    r.decision_mode == "TRIAGE"
    r.stubs_total == 39
    r.deserts == 159
}

test_p51_i11_empty_register_triage {
    r := p51.decide with input as p51_input("vacancy_bridge", {
        "vacancy_bridge": {"combined_register_rows": 0, "stubs_total": 0,
                           "deserts": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p51_i11_vacancy_bypass_blocks {
    r := p51.decide with input as p51_input("vacancy_bridge", {
        "vacancy_bridge": {"combined_register_rows": 1, "stubs_total": 0,
                           "deserts": 0},
        "vacancy_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I12: coverage attestation (liczniki niespójne = BLOCK fail-closed)
# ═══════════════════════════════════════════════════════════════════════════════
test_p51_i12_attested_autos {
    r := p51.decide with input as p51_input("coverage_attestation", {
        "coverage_attestation": {"counter_consistent": true, "attested": true,
                                 "caveats_count": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
    r.attested == true
}

test_p51_i12_caveats_triage {
    r := p51.decide with input as p51_input("coverage_attestation", {
        "coverage_attestation": {"counter_consistent": true, "attested": false,
                                 "caveats_count": 4},
    })
    r.decision_mode == "TRIAGE"
    r.caveats_count == 4
}

test_p51_i12_counters_inconsistent_blocks {
    # niespójne liczniki = atestacja nieprawdziwa = BLOCK (honesty, protokół 14)
    r := p51.decide with input as p51_input("coverage_attestation", {
        "coverage_attestation": {"counter_consistent": false, "attested": false,
                                 "caveats_count": 1},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p51_i12_attestation_bypass_blocks {
    r := p51.decide with input as p51_input("coverage_attestation", {
        "coverage_attestation": {"counter_consistent": true, "attested": true,
                                 "caveats_count": 0},
        "attestation_bypassed": true,
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Spójność kontraktu: wersje snapshotu w certyfikacie (F4)
# ═══════════════════════════════════════════════════════════════════════════════
test_p51_certificate_carries_threshold_version {
    r := p51.decide with input as p51_input("desert_register", {
        "desert_register": {"desert_nodes": 0, "p0_count": 0},
    })
    r.threshold_version == "deserts-v3p51-2026.09"
    r.legal_basis_version == "lb-deserts-v3p51-2026.09"
    r.valid_from == "2026-01-01"
}

test_p51_decide_is_deterministic {
    # dwa wywołania na tym samym input = identyczny wynik (INV: determinizm)
    a := p51.decide with input as p51_input("desert_register", {
        "desert_register": {"desert_nodes": 159, "p0_count": 34},
    })
    b := p51.decide with input as p51_input("desert_register", {
        "desert_register": {"desert_nodes": 159, "p0_count": 34},
    })
    a == b
}

test_p51_no_silent_auto_post_without_evidence {
    # symetria dowodu: AUTO_POST wyłącznie przy zero-pustyni / pełnym dowodzie;
    # jakakolwiek pustynia → nigdy AUTO_POST (fail-closed pustyni)
    r := p51.decide with input as p51_input("desert_register", {
        "desert_register": {"desert_nodes": 1, "p0_count": 0,
                            "no_rule": 1, "rule_no_test": 0,
                            "test_no_rule": 0},
    })
    r.decision_mode != "AUTO_POST"
}
