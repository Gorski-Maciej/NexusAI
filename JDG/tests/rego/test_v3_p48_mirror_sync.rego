# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY NATYWNE V3-P48 SYNCHRONIZACJA MIRROR POLICIES (konwencja
# P39/P45/P46/P47: negative-first, granice progów, fail-closed, never-silent
# AUTO_POST). Uruchomienie: opa test (0.68) / opa19 test --v0-compatible
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p48_mirror_sync_test

import data.jdg.v3_p48_mirror_sync as p48

# ── Helper ─────────────────────────────────────────────────────────────────────
p48_input(analysis, ctx) = {"jdg_entrepreneur": {"v3_p48_check": true},
                            "v3_p48": object.union({"analysis": analysis}, ctx)}

# ═══════════════════════════════════════════════════════════════════════════════
# Determinizm łańcucha / aktywacja
# ═══════════════════════════════════════════════════════════════════════════════
test_p48_no_activation_no_match {
    r := p48.decide with input as {}
    r.rule_id == "jdg.v3_p48_mirror_sync.no_match"
}

test_p48_no_selector_no_match {
    r := p48.decide with input as p48_input("brak_takiej_analizy", {})
    r.rule_id == "jdg.v3_p48_mirror_sync.no_match"
}

test_p48_thresholds_missing_fail_closed {
    r := p48.decide with input as p48_input("semantic_ast_diff", {})
        with data.jdg.thresholds.v3_p48 as {}
    r.rule_id == "jdg.v3_p48_mirror_sync.thresholds_missing"
    r._routing == "BLOCK_AND_ALERT"
    r.decision_mode == "BLOCK"
    r.priority == 0
}

test_p48_packages_missing_fail_closed {
    r := p48.decide with input as p48_input("mirror_ownership", {})
        with data.jdg.thresholds.v3_p48_packages as {}
    r.rule_id == "jdg.v3_p48_mirror_sync.packages_missing"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I01: mirror as build output
# ═══════════════════════════════════════════════════════════════════════════════
test_p48_i01_manifest_missing_blocks {
    r := p48.decide with input as p48_input("mirror_build_output", {
        "mirror_build_output": {"sync_manifest_present": false, "sync_age_days": 0,
                                 "hand_edits": 0},
    })
    r.rule_id == "jdg.v3_p48_mirror_sync.mirror_build_output"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p48_i01_hand_edits_block {
    r := p48.decide with input as p48_input("mirror_build_output", {
        "mirror_build_output": {"sync_manifest_present": true, "sync_age_days": 0,
                                 "hand_edits": 1},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
    r.hand_edits == 1
}

# granica: sync_age_days == 7 (max) → AUTO; == 7.01 → TRIAGE
test_p48_i01_sync_age_at_boundary_autos {
    r := p48.decide with input as p48_input("mirror_build_output", {
        "mirror_build_output": {"sync_manifest_present": true, "sync_age_days": 7,
                                 "hand_edits": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p48_i01_sync_age_over_boundary_triages {
    r := p48.decide with input as p48_input("mirror_build_output", {
        "mirror_build_output": {"sync_manifest_present": true, "sync_age_days": 8,
                                 "hand_edits": 0},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
    r.sync_age_days == 8
}

# ═══════════════════════════════════════════════════════════════════════════════
# I02: semantic AST diff gate
# ═══════════════════════════════════════════════════════════════════════════════
test_p48_i02_no_drift_map_blocks {
    r := p48.decide with input as p48_input("semantic_ast_diff", {
        "semantic_ast_diff": {"semantic_diffs": 0, "textual_diffs": 0,
                               "unreported_semantic": 0, "drift_map_present": false},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p48_i02_unreported_semantic_blocks {
    r := p48.decide with input as p48_input("semantic_ast_diff", {
        "semantic_ast_diff": {"semantic_diffs": 1, "textual_diffs": 0,
                               "unreported_semantic": 1, "drift_map_present": true},
    })
    r.decision_mode == "BLOCK"
    r.unreported_semantic == 1
}

test_p48_i02_textual_only_autos {
    # dryf tekstowy (komentarze/nagłówki) jest dozwolony — semantyka czysta
    r := p48.decide with input as p48_input("semantic_ast_diff", {
        "semantic_ast_diff": {"semantic_diffs": 0, "textual_diffs": 3,
                               "unreported_semantic": 0, "drift_map_present": true},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
    r.textual_diffs == 3
}

test_p48_i02_reported_semantic_blocks {
    # próg v3_p48_semantic_drift_max = 0: KAŻDY dryf semantyczny > 0 blokuje,
    # nawet gdy zaraportowany w mapie dryfu ( STRICT mode — zero tolerancji)
    r := p48.decide with input as p48_input("semantic_ast_diff", {
        "semantic_ast_diff": {"semantic_diffs": 2, "textual_diffs": 0,
                               "unreported_semantic": 0, "drift_map_present": true},
    })
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
    r.semantic_diffs == 2
}

# ═══════════════════════════════════════════════════════════════════════════════
# I03: sync-in-PR rule
# ═══════════════════════════════════════════════════════════════════════════════
test_p48_i03_canonical_without_mirror_blocks {
    r := p48.decide with input as p48_input("sync_in_pr", {
        "sync_in_pr": {"canonical_changed": 2, "mirror_changed": 0,
                        "out_of_pr_sync": 0},
    })
    r.rule_id == "jdg.v3_p48_mirror_sync.sync_in_pr"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p48_i03_out_of_pr_sync_blocks {
    r := p48.decide with input as p48_input("sync_in_pr", {
        "sync_in_pr": {"canonical_changed": 0, "mirror_changed": 1,
                        "out_of_pr_sync": 1},
    })
    r.decision_mode == "BLOCK"
}

test_p48_i03_both_changed_autos {
    r := p48.decide with input as p48_input("sync_in_pr", {
        "sync_in_pr": {"canonical_changed": 1, "mirror_changed": 1,
                        "out_of_pr_sync": 0},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I04: drift heatmap
# ═══════════════════════════════════════════════════════════════════════════════
test_p48_i04_worst_drift_over_block_threshold_blocks {
    # próg v3_p48_drift_block_pct = 20; 20.01 → BLOCK
    r := p48.decide with input as p48_input("drift_heatmap", {
        "drift_heatmap": {"packages_total": 2, "packages_clean": 1,
                           "worst_package_drift": 20.01, "trend_rising": false},
    })
    r.rule_id == "jdg.v3_p48_mirror_sync.drift_heatmap"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p48_i04_trend_rising_triages {
    r := p48.decide with input as p48_input("drift_heatmap", {
        "drift_heatmap": {"packages_total": 2, "packages_clean": 2,
                           "worst_package_drift": 0, "trend_rising": true},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

test_p48_i04_all_clean_autos {
    r := p48.decide with input as p48_input("drift_heatmap", {
        "drift_heatmap": {"packages_total": 54, "packages_clean": 54,
                           "worst_package_drift": 0, "trend_rising": false},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p48_i04_dirty_package_triages {
    # dryf 15% poniżej progu blokady, ale pakiety brudne → TRIAGE
    r := p48.decide with input as p48_input("drift_heatmap", {
        "drift_heatmap": {"packages_total": 2, "packages_clean": 1,
                           "worst_package_drift": 15.0, "trend_rising": false},
    })
    r.decision_mode == "TRIAGE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I05: overlay declaration
# ═══════════════════════════════════════════════════════════════════════════════
test_p48_i05_undeclared_overlay_blocks {
    r := p48.decide with input as p48_input("overlay_declaration", {
        "overlay_declaration": {"declared_overlays": 0, "undeclared_overlays": 1,
                                 "expired_overlays": 0},
    })
    r.rule_id == "jdg.v3_p48_mirror_sync.overlay_declaration"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p48_i05_expired_overlay_triages {
    r := p48.decide with input as p48_input("overlay_declaration", {
        "overlay_declaration": {"declared_overlays": 2, "undeclared_overlays": 0,
                                 "expired_overlays": 1},
    })
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

test_p48_i05_all_declared_autos {
    r := p48.decide with input as p48_input("overlay_declaration", {
        "overlay_declaration": {"declared_overlays": 1, "undeclared_overlays": 0,
                                 "expired_overlays": 0},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I06: mirror test parity
# ═══════════════════════════════════════════════════════════════════════════════
test_p48_i06_result_mismatch_blocks {
    r := p48.decide with input as p48_input("mirror_test_parity", {
        "mirror_test_parity": {"parity_runs": 1, "result_mismatches": 1,
                                "mirror_tests_total": 230},
    })
    r.rule_id == "jdg.v3_p48_mirror_sync.mirror_test_parity"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p48_i06_no_evidence_triages {
    r := p48.decide with input as p48_input("mirror_test_parity", {
        "mirror_test_parity": {"parity_runs": 0, "result_mismatches": 0,
                                "mirror_tests_total": 230},
    })
    r.decision_mode == "TRIAGE"
}

test_p48_i06_no_mirror_tests_triages {
    r := p48.decide with input as p48_input("mirror_test_parity", {
        "mirror_test_parity": {"parity_runs": 1, "result_mismatches": 0,
                                "mirror_tests_total": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p48_i06_parity_full_autos {
    r := p48.decide with input as p48_input("mirror_test_parity", {
        "mirror_test_parity": {"parity_runs": 1, "result_mismatches": 0,
                                "mirror_tests_total": 230},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I07: golden replay on mirror
# ═══════════════════════════════════════════════════════════════════════════════
test_p48_i07_decision_delta_blocks {
    r := p48.decide with input as p48_input("golden_replay_mirror", {
        "golden_replay_mirror": {"verdicts_total": 10, "decision_deltas": 1,
                                  "replay_done": true},
    })
    r.rule_id == "jdg.v3_p48_mirror_sync.golden_replay_mirror"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p48_i07_replay_not_done_triages {
    r := p48.decide with input as p48_input("golden_replay_mirror", {
        "golden_replay_mirror": {"verdicts_total": 10, "decision_deltas": 0,
                                  "replay_done": false},
    })
    r.decision_mode == "TRIAGE"
}

test_p48_i07_zero_delta_autos {
    r := p48.decide with input as p48_input("golden_replay_mirror", {
        "golden_replay_mirror": {"verdicts_total": 10, "decision_deltas": 0,
                                  "replay_done": true},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I08: mirror ownership register
# ═══════════════════════════════════════════════════════════════════════════════
test_p48_i08_orphan_packages_block {
    r := p48.decide with input as p48_input("mirror_ownership", {
        "mirror_ownership": {"packages_total": 54, "orphan_packages": 1,
                              "stale_reviews": 0},
    })
    r.rule_id == "jdg.v3_p48_mirror_sync.mirror_ownership"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p48_i08_stale_reviews_triage {
    r := p48.decide with input as p48_input("mirror_ownership", {
        "mirror_ownership": {"packages_total": 54, "orphan_packages": 0,
                              "stale_reviews": 3},
    })
    r.decision_mode == "TRIAGE"
}

test_p48_i08_all_owned_autos {
    r := p48.decide with input as p48_input("mirror_ownership", {
        "mirror_ownership": {"packages_total": 54, "orphan_packages": 0,
                              "stale_reviews": 0},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I09: post-deploy mirror check
# ═══════════════════════════════════════════════════════════════════════════════
test_p48_i09_source_mismatch_blocks {
    r := p48.decide with input as p48_input("post_deploy_check", {
        "post_deploy_check": {"deploys_checked": 44, "source_mismatches": 1},
    })
    r.rule_id == "jdg.v3_p48_mirror_sync.post_deploy_check"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p48_i09_no_checks_triage {
    r := p48.decide with input as p48_input("post_deploy_check", {
        "post_deploy_check": {"deploys_checked": 0, "source_mismatches": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p48_i09_checksum_match_autos {
    r := p48.decide with input as p48_input("post_deploy_check", {
        "post_deploy_check": {"deploys_checked": 44, "source_mismatches": 0},
    })
    r.decision_mode == "AUTO_POST"
}

# ═════════════════════════════════ JDG/tools/v3_p48_gate.py
# I10: case-study template
# ═════════════════════════════════ JDG/tools/v3_p48_gate.py
test_p48_i10_overdue_case_blocks {
    r := p48.decide with input as p48_input("case_study", {
        "case_study": {"open_cases": 1, "cases_without_repair_plan": 0,
                        "overdue_cases": 1},
    })
    r.rule_id == "jdg.v3_p48_mirror_sync.case_study"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p48_i10_case_without_plan_triages {
    r := p48.decide with input as p48_input("case_study", {
        "case_study": {"open_cases": 1, "cases_without_repair_plan": 1,
                        "overdue_cases": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p48_i10_zero_open_cases_autos {
    r := p48.decide with input as p48_input("case_study", {
        "case_study": {"open_cases": 0, "cases_without_repair_plan": 0,
                        "overdue_cases": 0},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I11: mirror lifecycle alignment
# ═══════════════════════════════════════════════════════════════════════════════
test_p48_i11_status_mismatch_blocks {
    r := p48.decide with input as p48_input("lifecycle_alignment", {
        "lifecycle_alignment": {"compared_rules": 12, "status_mismatches": 1},
    })
    r.rule_id == "jdg.v3_p48_mirror_sync.lifecycle_alignment"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p48_i11_no_comparison_triages {
    r := p48.decide with input as p48_input("lifecycle_alignment", {
        "lifecycle_alignment": {"compared_rules": 0, "status_mismatches": 0},
    })
    r.decision_mode == "TRIAGE"
}

test_p48_i11_aligned_autos {
    r := p48.decide with input as p48_input("lifecycle_alignment", {
        "lifecycle_alignment": {"compared_rules": 12, "status_mismatches": 0},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I12: one-truth attestation
# ═══════════════════════════════════════════════════════════════════════════════
test_p48_i12_missing_hashes_triage {
    r := p48.decide with input as p48_input("one_truth_attestation", {
        "one_truth_attestation": {"certificates_total": 1,
                                   "certificates_with_rule_hash": 0},
    })
    r.rule_id == "jdg.v3_p48_mirror_sync.one_truth_attestation"
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

test_p48_i12_all_hashed_autos {
    r := p48.decide with input as p48_input("one_truth_attestation", {
        "one_truth_attestation": {"certificates_total": 1,
                                   "certificates_with_rule_hash": 1},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
}

test_p48_i12_zero_certificates_autos {
    # brak certyfikatów = brak naruszenia (TRIAGE tylko gdy istnieją bez hashu)
    r := p48.decide with input as p48_input("one_truth_attestation", {
        "one_truth_attestation": {"certificates_total": 0,
                                   "certificates_with_rule_hash": 0},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Bypass flags nigdy nie omijają BLOCK (fail-closed, AP11)
# ═══════════════════════════════════════════════════════════════════════════════
test_p48_bypass_never_silences_block {
    r := p48.decide with input as object.union(p48_input("semantic_ast_diff", {
        "semantic_ast_diff": {"semantic_diffs": 5, "textual_diffs": 0,
                               "unreported_semantic": 0, "drift_map_present": true},
    }), {"v3_p48": {"ast_diff_bypassed": true}})
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Certyfikat decyzji: wersje progów/legal_basis w każdym werdykcie (V2 F4)
# ═══════════════════════════════════════════════════════════════════════════════
test_p48_certificate_carries_versions {
    r := p48.decide with input as p48_input("case_study", {
        "case_study": {"open_cases": 0, "cases_without_repair_plan": 0,
                        "overdue_cases": 0},
    })
    r.threshold_version == "mirror-sync-v3p48-2026.09"
    r.legal_basis_version == "lb-mirror-v3p48-2026.09"
    r.valid_from == "2026-01-01"
}
