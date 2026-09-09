# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY V3-P45 STUB KILLER (negative-first, P39-I04)
# Pokrycie I01–I12 + determinizm łańcucha + fail-closed (brak progów → BLOCK).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p45_stub_killer_test

import future.keywords.in

import data.jdg.v3_p45_stub_killer

# ── Helper ─────────────────────────────────────────────────────────────────────
p45_input(analysis, ctx) = {"jdg_entrepreneur": {"v3_p45_check": true},
                            "v3_p45": object.union({"analysis": analysis}, ctx)}

# ═══════════════════════════════════════════════════════════════════════════════
# Determinizm łańcucha
# ═══════════════════════════════════════════════════════════════════════════════
test_p45_no_activation_no_match {
    r := v3_p45_stub_killer.decide with input as {"v3_p45": {"analysis": "stub_register"}}
    r.rule_id == "jdg.v3_p45_stub_killer.no_match"
}

test_p45_no_selector_no_match {
    r := v3_p45_stub_killer.decide with input as p45_input("brak_takiej_analizy", {})
    r.rule_id == "jdg.v3_p45_stub_killer.no_match"
}

test_p45_thresholds_missing_fail_closed {
    r := v3_p45_stub_killer.decide with input as p45_input("stub_register", {})
        with data.jdg.thresholds.v3_p45 as {}
    r.rule_id == "jdg.v3_p45_stub_killer.thresholds_missing"
    r._routing == "BLOCK_AND_ALERT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I01: stub register with SLA
# ═══════════════════════════════════════════════════════════════════════════════
test_p45_i01_ok_all_sla_declining {
    r := v3_p45_stub_killer.decide with input as p45_input("stub_register", {
        "stub_register": {"entries": {"s1": {"deadline": "2026-10-01"}}, "trend": "declining"},
    })
    r.rule_id == "jdg.v3_p45_stub_killer.stub_register"
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p45_i01_critical_stub_over_limit_blocks {
    r := v3_p45_stub_killer.decide with input as p45_input("stub_register", {
        "stub_register": {"entries": {}, "critical_domain_stubs": 3, "trend": "declining"},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
    r.critical_domain_stubs == 3
}

test_p45_i01_missing_sla_triage {
    r := v3_p45_stub_killer.decide with input as p45_input("stub_register", {
        "stub_register": {"entries": {"s1": {"deadline": ""}}, "trend": "declining"},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

test_p45_i01_rising_trend_triage {
    r := v3_p45_stub_killer.decide with input as p45_input("stub_register", {
        "stub_register": {"entries": {}, "trend": "rising"},
    })
    r._routing == "TRIAGE_QUEUE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I02: stub forensics
# ═══════════════════════════════════════════════════════════════════════════════
test_p45_i02_attributed_ok {
    r := v3_p45_stub_killer.decide with input as p45_input("stub_forensics", {
        "stub_forensics": {"unattributed_stubs": [], "pathways": {"generator_plan33": 5}},
    })
    r.decision_mode == "AUTO_POST"
}

test_p45_i02_unattributed_triage {
    r := v3_p45_stub_killer.decide with input as p45_input("stub_forensics", {
        "stub_forensics": {"unattributed_stubs": ["jdg.x.y"], "pathways": {}},
    })
    r.decision_mode == "TRIAGE"
    r.unattributed == 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# I03: auto-convert pipeline
# ═══════════════════════════════════════════════════════════════════════════════
test_p45_i03_pipeline_complete_ok {
    r := v3_p45_stub_killer.decide with input as p45_input("auto_convert", {
        "conversions": {"entries": {"c1": {"golden_replay_passed": true}}},
    })
    r.decision_mode == "AUTO_POST"
}

test_p45_i03_bypass_blocks {
    r := v3_p45_stub_killer.decide with input as p45_input("auto_convert", {
        "conversion_bypassed_pipeline": true,
        "conversions": {"entries": {}},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p45_i03_no_replay_blocks {
    r := v3_p45_stub_killer.decide with input as p45_input("auto_convert", {
        "conversions": {"entries": {"c1": {"golden_replay_passed": false}}},
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I04: negative assertion generator
# ═══════════════════════════════════════════════════════════════════════════════
test_p45_i04_negatives_present_ok {
    r := v3_p45_stub_killer.decide with input as p45_input("negative_assertion", {
        "conversion_tests": {"without_negative": []},
    })
    r.decision_mode == "AUTO_POST"
}

test_p45_i04_missing_negative_blocks {
    r := v3_p45_stub_killer.decide with input as p45_input("negative_assertion", {
        "conversion_tests": {"without_negative": ["jdg.v3_p45_conversions.uor_a2_threshold"]},
    })
    r.decision_mode == "BLOCK"
    r.without_negative == 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# I05: mutation score gate
# ═══════════════════════════════════════════════════════════════════════════════
test_p45_i05_scores_above_min_ok {
    r := v3_p45_stub_killer.decide with input as p45_input("mutation_gate", {
        "mutation_scores": {"vat": 95, "pit": 92, "zus": 90},
    })
    r.decision_mode == "AUTO_POST"
    r.domains_measured == 3
}

test_p45_i05_low_score_blocks {
    r := v3_p45_stub_killer.decide with input as p45_input("mutation_gate", {
        "mutation_scores": {"vat": 80},
    })
    r.decision_mode == "BLOCK"
    r.low_domains == ["vat"]
}

test_p45_i05_unmeasured_critical_triage {
    r := v3_p45_stub_killer.decide with input as p45_input("mutation_gate", {
        "mutation_scores": {},
        "critical_domains_unmeasured": 2,
    })
    r.decision_mode == "TRIAGE"
}

test_p45_i05_boundary_exactly_min_ok {
    r := v3_p45_stub_killer.decide with input as p45_input("mutation_gate", {
        "mutation_scores": {"kks": 90},
    })
    r.decision_mode == "AUTO_POST"   # granica: < próg blokuje, == przechodzi
}

# ═══════════════════════════════════════════════════════════════════════════════
# I06: stub-free badge
# ═══════════════════════════════════════════════════════════════════════════════
test_p45_i06_badge_with_checksum_ok {
    r := v3_p45_stub_killer.decide with input as p45_input("stub_free_badge", {
        "stub_free_badges": {"vat": {"scan_checksum": "abc123"}},
    })
    r.decision_mode == "AUTO_POST"
}

test_p45_i06_badge_without_checksum_triage {
    r := v3_p45_stub_killer.decide with input as p45_input("stub_free_badge", {
        "stub_free_badges": {"vat": {"scan_checksum": ""}},
    })
    r.decision_mode == "TRIAGE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I07: template rule policy
# ═══════════════════════════════════════════════════════════════════════════════
test_p45_i07_no_empty_templates_ok {
    r := v3_p45_stub_killer.decide with input as p45_input("template_policy", {
        "empty_templates_in_production": 0,
    })
    r.decision_mode == "AUTO_POST"
}

test_p45_i07_empty_template_blocks {
    r := v3_p45_stub_killer.decide with input as p45_input("template_policy", {
        "empty_templates_in_production": 2,
    })
    r.decision_mode == "BLOCK"
    r.empty_templates == 2
}

# ═══════════════════════════════════════════════════════════════════════════════
# I08: stub-enabling tests
# ═══════════════════════════════════════════════════════════════════════════════
test_p45_i08_no_tautologies_ok {
    r := v3_p45_stub_killer.decide with input as p45_input("stub_enabling_tests", {
        "tautological_tests": 0, "stub_test_pairs_unfixed": 0,
    })
    r.decision_mode == "AUTO_POST"
}

test_p45_i08_unfixed_pairs_block {
    r := v3_p45_stub_killer.decide with input as p45_input("stub_enabling_tests", {
        "tautological_tests": 0, "stub_test_pairs_unfixed": 3,
    })
    r.decision_mode == "BLOCK"
}

test_p45_i08_tautologies_over_threshold_triage {
    # tautological_tests > próg (pełna podmiana snapshotu — brak częściowej)
    r := v3_p45_stub_killer.decide with input as p45_input("stub_enabling_tests", {
        "tautological_tests": 102, "stub_test_pairs_unfixed": 0,
    }) with data.jdg.thresholds.v3_p45 as {"v3_p45_tautological_test_files_max": 0,
                                          "v3_p45_critical_domain_stubs_max": 0,
                                          "v3_p45_mutation_score_min": 90,
                                          "v3_p45_census_max_age_days": 7}
    r.decision_mode == "TRIAGE"
    r.tautological_test_files == 102
}

# ═══════════════════════════════════════════════════════════════════════════════
# I09: provenance of truth
# ═══════════════════════════════════════════════════════════════════════════════
test_p45_i09_full_chain_ok {
    r := v3_p45_stub_killer.decide with input as p45_input("provenance_of_truth", {
        "lifecycle_promotions": {"entries": {"p1": {"full_chain": true}}},
    })
    r.decision_mode == "AUTO_POST"
}

test_p45_i09_promotion_without_chain_blocks {
    r := v3_p45_stub_killer.decide with input as p45_input("provenance_of_truth", {
        "lifecycle_promotions": {"entries": {"p1": {"full_chain": false}}},
    })
    r.decision_mode == "BLOCK"
}

test_p45_i09_bypass_blocks {
    r := v3_p45_stub_killer.decide with input as p45_input("provenance_of_truth", {
        "promotion_bypassed_provenance": true,
        "lifecycle_promotions": {"entries": {}},
    })
    r._routing == "BLOCK_AND_ALERT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I10: stub census
# ═══════════════════════════════════════════════════════════════════════════════
test_p45_i10_fresh_census_ok {
    r := v3_p45_stub_killer.decide with input as p45_input("stub_census", {
        "stub_census": {"by_domain": {"vat": 2, "zus": 1}, "days_since_census": 1},
    })
    r.decision_mode == "AUTO_POST"
}

test_p45_i10_stale_census_triage {
    r := v3_p45_stub_killer.decide with input as p45_input("stub_census", {
        "stub_census": {"by_domain": {"vat": 2}, "days_since_census": 30},
    })
    r.decision_mode == "TRIAGE"
}

test_p45_i10_empty_census_triage {
    r := v3_p45_stub_killer.decide with input as p45_input("stub_census", {
        "stub_census": {"by_domain": {}, "days_since_census": 0},
    })
    r.decision_mode == "TRIAGE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I11: legal-empty detector
# ═══════════════════════════════════════════════════════════════════════════════
test_p45_i11_all_basis_filled_ok {
    r := v3_p45_stub_killer.decide with input as p45_input("legal_empty", {
        "legal_basis_empty_rules": 0, "material_rules_without_act": 0,
    })
    r.decision_mode == "AUTO_POST"
}

test_p45_i11_material_without_act_blocks {
    r := v3_p45_stub_killer.decide with input as p45_input("legal_empty", {
        "legal_basis_empty_rules": 0, "material_rules_without_act": 1,
    })
    r.decision_mode == "BLOCK"
}

test_p45_i11_placeholder_basis_triage {
    r := v3_p45_stub_killer.decide with input as p45_input("legal_empty", {
        "legal_basis_empty_rules": 4, "material_rules_without_act": 0,
    })
    r.decision_mode == "TRIAGE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I12: ISAP parity
# ═══════════════════════════════════════════════════════════════════════════════
test_p45_i12_all_quotes_verified_ok {
    r := v3_p45_stub_killer.decide with input as p45_input("isap_parity", {
        "isap_parity": {"without_quote": [], "unverified_quotes": []},
    })
    r.decision_mode == "AUTO_POST"
}

test_p45_i12_missing_quote_triage {
    r := v3_p45_stub_killer.decide with input as p45_input("isap_parity", {
        "isap_parity": {"without_quote": ["jdg.v3_p45_conversions.pcc_a1_condition"], "unverified_quotes": []},
    })
    r.decision_mode == "TRIAGE"
}

test_p45_i12_unverified_quote_triage {
    r := v3_p45_stub_killer.decide with input as p45_input("isap_parity", {
        "isap_parity": {"without_quote": [], "unverified_quotes": ["q1"]},
    })
    r.decision_mode == "TRIAGE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Symetria dowodu: nigdy ciche AUTO_POST przy BLOCK/TRIAGE routingu
# ═══════════════════════════════════════════════════════════════════════════════
test_p45_no_auto_post_when_blocked {
    r := v3_p45_stub_killer.decide with input as p45_input("auto_convert", {
        "conversion_bypassed_pipeline": true,
        "conversions": {"entries": {}},
    })
    r._routing == "BLOCK_AND_ALERT"
    r.decision_mode != "AUTO_POST"
}
