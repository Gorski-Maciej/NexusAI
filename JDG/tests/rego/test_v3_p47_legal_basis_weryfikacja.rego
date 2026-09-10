# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY NATYWNE V3-P47 WERYFIKACJA PODSTAW PRAWNYCH (konwencja
# P39/P45/P46: negative-first, granice progów, fail-closed, never-silent
# AUTO_POST). Uruchomienie: opa test (0.68) / opa19 test --v0-compatible
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p47_legal_basis_test

import data.jdg.v3_p47_legal_basis_weryfikacja_enterprise as p47

# ── Helper ─────────────────────────────────────────────────────────────────────
p47_input(analysis, ctx) = {"jdg_entrepreneur": {"v3_p47_check": true},
                            "v3_p47": object.union({"analysis": analysis}, ctx)}

# ═══════════════════════════════════════════════════════════════════════════════
# Determinizm łańcucha
# ═══════════════════════════════════════════════════════════════════════════════
test_p47_no_activation_no_match {
    r := p47.decide with input as {}
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.no_match"
}

test_p47_no_selector_no_match {
    r := p47.decide with input as p47_input("brak_takiej_analizy", {})
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.no_match"
}

test_p47_thresholds_missing_fail_closed {
    r := p47.decide with input as p47_input("legal_basis_census", {})
        with data.jdg.thresholds.v3_p47 as {}
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.thresholds_missing"
    r._routing == "BLOCK_AND_ALERT"
    r.decision_mode == "BLOCK"
}

test_p47_acts_missing_fail_closed {
    r := p47.decide with input as p47_input("legal_basis_census", {})
        with data.jdg.thresholds.v3_p47_acts as {}
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.acts_missing"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I01: legal basis census
# ═══════════════════════════════════════════════════════════════════════════════
test_p47_i01_empty_census_triages {
    r := p47.decide with input as p47_input("legal_basis_census", {
        "legal_basis_census": {"rules_total": 0, "ok": 0, "unverified": 0,
                               "suspect": 0, "census_age_days": 0},
    })
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.legal_basis_census"
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

test_p47_i01_stale_census_triages {
    r := p47.decide with input as p47_input("legal_basis_census", {
        "legal_basis_census": {"rules_total": 12439, "ok": 667, "unverified": 11772,
                               "suspect": 0, "census_age_days": 31},
    })
    r.decision_mode == "TRIAGE"
    r.census_age_days == 31
}

# granica: wiek == 30 (max) → AUTO przy zero podejrzanych
test_p47_i01_census_at_age_boundary_autos {
    r := p47.decide with input as p47_input("legal_basis_census", {
        "legal_basis_census": {"rules_total": 100, "ok": 100, "unverified": 0,
                               "suspect": 0, "census_age_days": 30},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

# granica: podejrzane > 0 → TRIAGE nawet przy świeżym spisie
test_p47_i01_suspect_triages {
    r := p47.decide with input as p47_input("legal_basis_census", {
        "legal_basis_census": {"rules_total": 100, "ok": 99, "unverified": 0,
                               "suspect": 1, "census_age_days": 0},
    })
    r.decision_mode == "TRIAGE"
    r.suspect == 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# I02: citation linter
# ═══════════════════════════════════════════════════════════════════════════════
test_p47_i02_lint_error_blocks {
    r := p47.decide with input as p47_input("citation_linter", {
        "citation_linter": {"errors": 1, "rules_without_legal_basis": 0},
    })
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.citation_linter"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
    r.lint_errors == 1
}

# granica: errors == 0 → nie blokuje
test_p47_i02_zero_errors_autos {
    r := p47.decide with input as p47_input("citation_linter", {
        "citation_linter": {"errors": 0, "rules_without_legal_basis": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p47_i02_bypass_flag_blocks {
    r := p47.decide with input as p47_input("citation_linter", {
        "citation_bypassed_lint": true,
        "citation_linter": {"errors": 0, "rules_without_legal_basis": 0},
    })
    r.decision_mode == "BLOCK"
}

test_p47_i02_missing_basis_triages {
    r := p47.decide with input as p47_input("citation_linter", {
        "citation_linter": {"errors": 0, "rules_without_legal_basis": 59},
    })
    r.decision_mode == "TRIAGE"
    r.rules_without_legal_basis == 59
}

# ═══════════════════════════════════════════════════════════════════════════════
# I03: ISAP anchors
# ═══════════════════════════════════════════════════════════════════════════════
test_p47_i03_acts_without_anchor_triages {
    r := p47.decide with input as p47_input("isap_anchors", {
        "isap_anchors": {"acts_total": 12, "acts_without_anchor": 2},
    })
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.isap_anchor"
    r.decision_mode == "TRIAGE"
    r.acts_without_anchor == 2
}

test_p47_i03_all_anchored_autos {
    r := p47.decide with input as p47_input("isap_anchors", {
        "isap_anchors": {"acts_total": 12, "acts_without_anchor": 0},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I04: temporal act versions
# ═══════════════════════════════════════════════════════════════════════════════
test_p47_i04_version_without_window_blocks {
    r := p47.decide with input as p47_input("act_versions", {
        "act_versions": {"versions_total": 12, "versions_without_window": 1},
    })
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.temporal_act_versions"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p47_i04_empty_versions_triages {
    r := p47.decide with input as p47_input("act_versions", {
        "act_versions": {"versions_total": 0, "versions_without_window": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p47_i04_all_windows_autos {
    r := p47.decide with input as p47_input("act_versions", {
        "act_versions": {"versions_total": 12, "versions_without_window": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._legal_basis != ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# I05: re-check scheduler
# ═══════════════════════════════════════════════════════════════════════════════
test_p47_i05_overdue_cadence_blocks {
    r := p47.decide with input as p47_input("recheck_scheduler", {
        "recheck_scheduler": {"stale_acts": 0, "days_since_last_run": 2},
    })
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.recheck_scheduler"
    r.decision_mode == "BLOCK"
    r.days_since_last_run == 2
}

# granica: days == 1 (ACTIVE codziennie) → w kadencji
test_p47_i05_in_cadence_no_stale_autos {
    r := p47.decide with input as p47_input("recheck_scheduler", {
        "recheck_scheduler": {"stale_acts": 0, "days_since_last_run": 1},
    })
    r.decision_mode == "AUTO_POST"
}

test_p47_i05_stale_acts_triage {
    r := p47.decide with input as p47_input("recheck_scheduler", {
        "recheck_scheduler": {"stale_acts": 12, "days_since_last_run": 1},
    })
    r.decision_mode == "TRIAGE"
    r.stale_acts == 12
}

# ═══════════════════════════════════════════════════════════════════════════════
# I06: mediation workflow
# ═══════════════════════════════════════════════════════════════════════════════
test_p47_i06_overdue_dispute_blocks {
    r := p47.decide with input as p47_input("mediation_workflow", {
        "mediation_workflow": {"open_disputes": 5, "overdue_disputes": 1},
    })
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.mediation_workflow"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
    r.overdue_disputes == 1
}

test_p47_i06_open_dispute_triages {
    r := p47.decide with input as p47_input("mediation_workflow", {
        "mediation_workflow": {"open_disputes": 5, "overdue_disputes": 0},
    })
    r.decision_mode == "TRIAGE"
    r.sla_days == 14
}

test_p47_i06_no_disputes_autos {
    r := p47.decide with input as p47_input("mediation_workflow", {
        "mediation_workflow": {"open_disputes": 0, "overdue_disputes": 0},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I07: fictional basis blocker
# ═══════════════════════════════════════════════════════════════════════════════
test_p47_i07_no_fiction_autos {
    r := p47.decide with input as p47_input("fictional_basis", {
        "fictional_basis": {"fictional_detected": 0, "rules_shadowed": 0,
                            "decisions_reexamined": 0},
    })
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.fictional_basis_blocker"
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p47_i07_fiction_without_shadow_triages {
    r := p47.decide with input as p47_input("fictional_basis", {
        "fictional_basis": {"fictional_detected": 1, "rules_shadowed": 0,
                            "decisions_reexamined": 0},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

test_p47_i07_bypass_blocks {
    r := p47.decide with input as p47_input("fictional_basis", {
        "fiction_blocker_bypassed": true,
        "fictional_basis": {"fictional_detected": 1, "rules_shadowed": 2,
                            "decisions_reexamined": 3},
    })
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I08: completeness score
# ═══════════════════════════════════════════════════════════════════════════════
test_p47_i08_below_target_triages {
    r := p47.decide with input as p47_input("completeness_score", {
        "completeness_score": {"complete_chains": 667, "active_rules": 12439,
                               "chains_below_min_depth": 0},
    })
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.completeness_score"
    r.decision_mode == "TRIAGE"
    r.completeness_pct < 100
}

test_p47_i08_below_min_chain_blocks {
    r := p47.decide with input as p47_input("completeness_score", {
        "completeness_score": {"complete_chains": 100, "active_rules": 200,
                               "chains_below_min_depth": 5},
    })
    r.decision_mode == "BLOCK"
    r.chains_below_min_depth == 5
}

test_p47_i08_perfect_score_autos {
    r := p47.decide with input as p47_input("completeness_score", {
        "completeness_score": {"complete_chains": 200, "active_rules": 200,
                               "chains_below_min_depth": 0},
    })
    r.decision_mode == "AUTO_POST"
    r.completeness_pct == 100
}

# ═══════════════════════════════════════════════════════════════════════════════
# I09: ISAP diff watch
# ═══════════════════════════════════════════════════════════════════════════════
test_p47_i09_unreported_diff_blocks {
    r := p47.decide with input as p47_input("isap_diff_watch", {
        "isap_diff_watch": {"unreported_diffs": 2, "reported_diffs": 0,
                            "rules_shadowed": 0},
    })
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.isap_diff_watch"
    r.decision_mode == "BLOCK"
}

test_p47_i09_reported_without_shadow_triages {
    r := p47.decide with input as p47_input("isap_diff_watch", {
        "isap_diff_watch": {"unreported_diffs": 0, "reported_diffs": 3,
                            "rules_shadowed": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p47_i09_clean_autos {
    r := p47.decide with input as p47_input("isap_diff_watch", {
        "isap_diff_watch": {"unreported_diffs": 0, "reported_diffs": 0,
                            "rules_shadowed": 0},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I10: human verification stamp
# ═══════════════════════════════════════════════════════════════════════════════
test_p47_i10_bypass_blocks {
    r := p47.decide with input as p47_input("human_verification_stamp", {
        "stamp_bypassed": true,
        "human_verification_stamp": {"acts_verified_by_human": 30, "acts_total": 30},
    })
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.human_verification_stamp"
    r.decision_mode == "BLOCK"
}

test_p47_i10_partial_verification_triages {
    r := p47.decide with input as p47_input("human_verification_stamp", {
        "human_verification_stamp": {"acts_verified_by_human": 0, "acts_total": 30},
    })
    r.decision_mode == "TRIAGE"
    r.acts_verified_by_human == 0
}

test_p47_i10_all_verified_autos {
    r := p47.decide with input as p47_input("human_verification_stamp", {
        "human_verification_stamp": {"acts_verified_by_human": 30, "acts_total": 30},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I11: acts coverage heatmap
# ═══════════════════════════════════════════════════════════════════════════════
test_p47_i11_deserts_triage {
    r := p47.decide with input as p47_input("acts_heatmap", {
        "acts_heatmap": {"covered_acts": 50, "desert_acts": 20,
                         "desert_acts_with_active_rules": 0},
    })
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.acts_heatmap"
    r.decision_mode == "TRIAGE"
    r.desert_acts == 20
}

test_p47_i11_desert_with_active_triages {
    r := p47.decide with input as p47_input("acts_heatmap", {
        "acts_heatmap": {"covered_acts": 50, "desert_acts": 20,
                         "desert_acts_with_active_rules": 3},
    })
    r.decision_mode == "TRIAGE"
    r.desert_acts_with_active_rules == 3
}

test_p47_i11_no_deserts_autos {
    r := p47.decide with input as p47_input("acts_heatmap", {
        "acts_heatmap": {"covered_acts": 70, "desert_acts": 0,
                         "desert_acts_with_active_rules": 0},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I12: citation style guide
# ═══════════════════════════════════════════════════════════════════════════════
test_p47_i12_missing_guide_triages {
    r := p47.decide with input as p47_input("style_guide", {
        "style_guide": {"guide_present": false, "examples_valid": 0,
                        "examples_invalid": 0},
    })
    r.rule_id == "jdg.v3_p47_legal_basis_weryfikacja_enterprise.citation_style_guide"
    r.decision_mode == "TRIAGE"
}

test_p47_i12_invalid_examples_triage {
    r := p47.decide with input as p47_input("style_guide", {
        "style_guide": {"guide_present": true, "examples_valid": 6,
                        "examples_invalid": 2},
    })
    r.decision_mode == "TRIAGE"
    r.examples_invalid == 2
}

test_p47_i12_guide_ok_autos {
    r := p47.decide with input as p47_input("style_guide", {
        "style_guide": {"guide_present": true, "examples_valid": 6,
                        "examples_invalid": 0},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Never-silent AUTO_POST — AUTO tylko przy pełnym dowodzie (AP07)
# ═══════════════════════════════════════════════════════════════════════════════
test_p47_never_silent_auto_post {
    auto := [d |
        input_cases := [
            p47_input("legal_basis_census", {"legal_basis_census": {}}),
            p47_input("citation_linter", {"citation_linter": {}}),
            p47_input("isap_anchors", {"isap_anchors": {}}),
            p47_input("act_versions", {"act_versions": {}}),
            p47_input("recheck_scheduler", {"recheck_scheduler": {}}),
            p47_input("mediation_workflow", {"mediation_workflow": {}}),
            p47_input("fictional_basis", {"fictional_basis": {}}),
            p47_input("completeness_score", {"completeness_score": {}}),
            p47_input("isap_diff_watch", {"isap_diff_watch": {}}),
            p47_input("human_verification_stamp", {"human_verification_stamp": {}}),
            p47_input("acts_heatmap", {"acts_heatmap": {}}),
            p47_input("style_guide", {"style_guide": {}}),
        ]
        inp := input_cases[_]
        r := p47.decide with input as inp
        r.decision_mode == "AUTO_POST"
        d := r.rule_id
    ]
    count(auto) == 0  # puste konteksty nigdy nie dają AUTO_POST (fail-closed)
}
