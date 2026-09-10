# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY NATYWNE V3-P46 ELIMINACJA HARDCODE (konwencja P39/P45:
# negative-first, granice progów, fail-closed, never-silent AUTO_POST)
# Uruchomienie: opa test (0.68) / opa19 test --v0-compatible
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p46_hardcode_test

import data.jdg.v3_p46_hardcode_eliminacja_enterprise as p46

# ── Helper ─────────────────────────────────────────────────────────────────────
p46_input(analysis, ctx) = {"jdg_entrepreneur": {"v3_p46_check": true},
                            "v3_p46": object.union({"analysis": analysis}, ctx)}

# ═══════════════════════════════════════════════════════════════════════════════
# Determinizm łańcucha
# ═══════════════════════════════════════════════════════════════════════════════
test_p46_no_activation_no_match {
    r := p46.decide with input as {}
    r.rule_id == "jdg.v3_p46_hardcode_eliminacja_enterprise.no_match"
}

test_p46_no_selector_no_match {
    r := p46.decide with input as p46_input("brak_takiej_analizy", {})
    r.rule_id == "jdg.v3_p46_hardcode_eliminacja_enterprise.no_match"
}

test_p46_thresholds_missing_fail_closed {
    r := p46.decide with input as p46_input("parameter_registry", {})
        with data.jdg.thresholds.v3_p46 as {}
    r.rule_id == "jdg.v3_p46_hardcode_eliminacja_enterprise.thresholds_missing"
    r._routing == "BLOCK_AND_ALERT"
    r.decision_mode == "BLOCK"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I01: parameter registry
# ═══════════════════════════════════════════════════════════════════════════════
test_p46_i01_empty_registry_triages {
    r := p46.decide with input as p46_input("parameter_registry", {
        "parameter_registry": {"entries": {}, "registry_age_days": 0},
    })
    r.rule_id == "jdg.v3_p46_hardcode_eliminacja_enterprise.parameter_registry"
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

test_p46_i01_stale_registry_triages {
    r := p46.decide with input as p46_input("parameter_registry", {
        "parameter_registry": {"registry_age_days": 40, "entries": {"vat.standard_rate": {}}},
    })
    r.decision_mode == "TRIAGE"
    r.registry_age_days == 40
}

test_p46_i01_fresh_registry_auto {
    r := p46.decide with input as p46_input("parameter_registry", {
        "parameter_registry": {"registry_age_days": 1, "entries": {"a": {}, "b": {}}},
    })
    r.decision_mode == "AUTO_POST"
    r._routing == "AUTO_FILE"
    r.parameters_total == 2
}

# ═══════════════════════════════════════════════════════════════════════════════
# I02: value provenance chain
# ═══════════════════════════════════════════════════════════════════════════════
test_p46_i02_weak_chain_blocks {
    r := p46.decide with input as p46_input("value_provenance", {
        "value_provenance": {"entries": {"vat.standard_rate": {"chain_depth": 1}}},
    })
    r.rule_id == "jdg.v3_p46_hardcode_eliminacja_enterprise.value_provenance"
    r.decision_mode == "BLOCK"
    r._routing == "BLOCK_AND_ALERT"
}

test_p46_i02_bypass_blocks {
    r := p46.decide with input as p46_input("value_provenance", {
        "value_provenance": {"entries": {}},
        "provenance_bypassed_chain": true,
    })
    r.decision_mode == "BLOCK"
}

test_p46_i02_full_chain_auto {
    r := p46.decide with input as p46_input("value_provenance", {
        "value_provenance": {"entries": {"vat.standard_rate": {"chain_depth": 4}}},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I03: temporal parameter gate
# ═══════════════════════════════════════════════════════════════════════════════
test_p46_i03_missing_valid_from_blocks {
    r := p46.decide with input as p46_input("temporal_gate", {
        "temporal_gate": {"missing_valid_from": 2},
    })
    r.rule_id == "jdg.v3_p46_hardcode_eliminacja_enterprise.temporal_parameter_gate"
    r.decision_mode == "BLOCK"
    r.missing_valid_from == 2
}

test_p46_i03_gate_off_narrowed_to_triage {
    r := p46.decide with input as p46_input("temporal_gate", {
        "temporal_gate": {"missing_valid_from": 2},
    }) with data.jdg.thresholds.v3_p46 as {"v3_p46_threshold_version": "test", "valid_from": "2026-01-01", "v3_p46_temporal_gate_enabled": false, "v3_p46_parameter_registry_max_age_days": 30, "v3_p46_provenance_chain_min_depth": 3, "v3_p46_schema_errors_max": 0, "v3_p46_orphan_values_max": 0, "v3_p46_extreme_literal_max": 0, "v3_p46_replay_drift_max_auto_changes": 0, "v3_p46_replay_drift_four_eyes_min": 1, "v3_p46_known_units": ["PLN"], "no_auto_post": true, "manual_review_required": true}
    r.decision_mode == "TRIAGE"
}

test_p46_i03_window_complete_auto {
    r := p46.decide with input as p46_input("temporal_gate", {
        "temporal_gate": {"missing_valid_from": 0},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I04: schema validation
# ═══════════════════════════════════════════════════════════════════════════════
test_p46_i04_schema_errors_block {
    r := p46.decide with input as p46_input("schema_validation", {
        "schema_validation": {"checked": true, "errors": 3},
    })
    r.rule_id == "jdg.v3_p46_hardcode_eliminacja_enterprise.schema_validation"
    r.decision_mode == "BLOCK"
    r.schema_errors == 3
}

test_p46_i04_not_checked_blocks {
    r := p46.decide with input as p46_input("schema_validation", {
        "schema_validation": {"checked": false, "errors": 0},
    })
    r.decision_mode == "BLOCK"
}

test_p46_i04_clean_auto {
    r := p46.decide with input as p46_input("schema_validation", {
        "schema_validation": {"checked": true, "errors": 0},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I05: signed parameter bundles
# ═══════════════════════════════════════════════════════════════════════════════
test_p46_i05_unsigned_block {
    r := p46.decide with input as p46_input("signed_bundles", {
        "signed_bundles": {"without_checksum": ["thresholds_data.json"], "tampered": 0},
    })
    r.rule_id == "jdg.v3_p46_hardcode_eliminacja_enterprise.signed_parameter_bundles"
    r.decision_mode == "BLOCK"
    r.without_checksum == 1
}

test_p46_i05_tampered_block {
    r := p46.decide with input as p46_input("signed_bundles", {
        "signed_bundles": {"without_checksum": [], "tampered": 1},
    })
    r.decision_mode == "BLOCK"
    r.tampered == 1
}

test_p46_i05_signed_auto {
    r := p46.decide with input as p46_input("signed_bundles", {
        "signed_bundles": {"without_checksum": [], "tampered": 0, "sha256": "abc"},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I06: day-0 test generation
# ═══════════════════════════════════════════════════════════════════════════════
test_p46_i06_missing_day0_triages {
    r := p46.decide with input as p46_input("day0_tests", {
        "day0_tests": {"missing_transitions": ["zus.pension_rate"], "generated": 0},
    })
    r.rule_id == "jdg.v3_p46_hardcode_eliminacja_enterprise.day0_test_generation"
    r.decision_mode == "TRIAGE"
}

test_p46_i06_generated_auto {
    r := p46.decide with input as p46_input("day0_tests", {
        "day0_tests": {"missing_transitions": [], "generated": 3},
    })
    r.decision_mode == "AUTO_POST"
    r.generated_transitions == 3
}

# ═══════════════════════════════════════════════════════════════════════════════
# I07: parameter change workflow
# ═══════════════════════════════════════════════════════════════════════════════
test_p46_i07_unvalidated_deploy_blocks {
    r := p46.decide with input as p46_input("change_workflow", {
        "change_workflow": {"deployed_without_validation": 1,
                            "without_citation": [], "without_day0_tests": []},
    })
    r.rule_id == "jdg.v3_p46_hardcode_eliminacja_enterprise.parameter_change_workflow"
    r.decision_mode == "BLOCK"
}

test_p46_i07_bypass_blocks {
    r := p46.decide with input as p46_input("change_workflow", {
        "parameter_change_bypassed_workflow": true,
        "change_workflow": {},
    })
    r.decision_mode == "BLOCK"
}

test_p46_i07_no_citation_triages {
    r := p46.decide with input as p46_input("change_workflow", {
        "change_workflow": {"deployed_without_validation": 0,
                            "without_citation": ["vat.standard_rate"],
                            "without_day0_tests": []},
    })
    r.decision_mode == "TRIAGE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I08: unit semantics
# ═══════════════════════════════════════════════════════════════════════════════
test_p46_i08_unit_mismatch_blocks {
    r := p46.decide with input as p46_input("unit_semantics", {
        "unit_semantics": {"unit_mismatch": 1, "unknown_unit_values": 0},
    })
    r.rule_id == "jdg.v3_p46_hardcode_eliminacja_enterprise.unit_semantics"
    r.decision_mode == "BLOCK"
    r.unit_mismatch == 1
}

test_p46_i08_unknown_unit_triages {
    r := p46.decide with input as p46_input("unit_semantics", {
        "unit_semantics": {"unit_mismatch": 0, "unknown_unit_values": 2},
    })
    r.decision_mode == "TRIAGE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I09: parameter drift alarm
# ═══════════════════════════════════════════════════════════════════════════════
test_p46_i09_unreported_drift_blocks {
    r := p46.decide with input as p46_input("drift_alarm", {
        "drift_alarm": {"unreported_drifts": 1, "reported_drifts": 0},
    })
    r.rule_id == "jdg.v3_p46_hardcode_eliminacja_enterprise.parameter_drift_alarm"
    r.decision_mode == "BLOCK"
    r.unreported_drifts == 1
}

test_p46_i09_reported_drift_triages {
    r := p46.decide with input as p46_input("drift_alarm", {
        "drift_alarm": {"unreported_drifts": 0, "reported_drifts": 1},
    })
    r.decision_mode == "TRIAGE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I10: legacy value sweeper (granice: zero / ponad próg / trend rosnący)
# ═══════════════════════════════════════════════════════════════════════════════
test_p46_i10_orphans_above_max_triages {
    r := p46.decide with input as p46_input("legacy_sweep", {
        "legacy_sweep": {"orphan_values": 5, "extreme_literals": 0, "trend": "declining"},
    })
    r.rule_id == "jdg.v3_p46_hardcode_eliminacja_enterprise.legacy_value_sweeper"
    r.decision_mode == "TRIAGE"
    r._routing == "TRIAGE_QUEUE"
}

test_p46_i10_rising_trend_blocks {
    r := p46.decide with input as p46_input("legacy_sweep", {
        "legacy_sweep": {"orphan_values": 5, "extreme_literals": 0, "trend": "rising"},
    })
    r.decision_mode == "BLOCK"
}

test_p46_i10_zero_orphans_auto {
    r := p46.decide with input as p46_input("legacy_sweep", {
        "legacy_sweep": {"orphan_values": 0, "extreme_literals": 0, "trend": "declining"},
    })
    r.decision_mode == "AUTO_POST"
    r.orphan_values == 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# I11: golden replay per parameter change (limit 0 z data.thresholds)
# ═══════════════════════════════════════════════════════════════════════════════
test_p46_i11_drift_over_limit_blocks {
    r := p46.decide with input as p46_input("parameter_replay", {
        "parameter_replay": {"runs": [{"drift_auto_changes": 1, "old": 0.23}],
                             "drift_over_limit": 1, "missing_old_params": 0},
    })
    r.rule_id == "jdg.v3_p46_hardcode_eliminacja_enterprise.golden_replay_per_change"
    r.decision_mode == "BLOCK"
}

test_p46_i11_drift_at_limit_auto {
    r := p46.decide with input as p46_input("parameter_replay", {
        "parameter_replay": {"runs": [{"drift_auto_changes": 0, "old": 0.23}],
                             "drift_over_limit": 0, "missing_old_params": 0},
    })
    r.decision_mode == "AUTO_POST"
}

test_p46_i11_missing_old_triages {
    r := p46.decide with input as p46_input("parameter_replay", {
        "parameter_replay": {"runs": [], "drift_over_limit": 0, "missing_old_params": 1},
    })
    r.decision_mode == "TRIAGE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# I12: documentation anchors
# ═══════════════════════════════════════════════════════════════════════════════
test_p46_i12_missing_anchor_triages {
    r := p46.decide with input as p46_input("doc_anchors", {
        "doc_anchors": {"without_anchor": 3, "documented": 5},
    })
    r.rule_id == "jdg.v3_p46_hardcode_eliminacja_enterprise.documentation_anchor"
    r.decision_mode == "TRIAGE"
}

test_p46_i12_documented_auto {
    r := p46.decide with input as p46_input("doc_anchors", {
        "doc_anchors": {"without_anchor": 0, "documented": 8},
    })
    r.decision_mode == "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Never-silent AUTO_POST: 5 przypadków naraz (AP07 domknięty dla P46)
# ═══════════════════════════════════════════════════════════════════════════════
test_p46_never_silent_auto_post_on_missing_data {
    d1 := p46.decide with input as p46_input("value_provenance", {"value_provenance": {"entries": {}}})
    d2 := p46.decide with input as p46_input("temporal_gate", {"temporal_gate": {"missing_valid_from": 1}})
    d3 := p46.decide with input as p46_input("schema_validation", {"schema_validation": {"checked": true, "errors": 9}})
    d4 := p46.decide with input as p46_input("signed_bundles", {"signed_bundles": {"without_checksum": ["a"], "tampered": 0}})
    d5 := p46.decide with input as p46_input("parameter_replay", {"parameter_replay": {"runs": [], "drift_over_limit": 0, "missing_old_params": 0}})
    object.get(d1, "decision_mode", "NO_MATCH") != "AUTO_POST"
    object.get(d2, "decision_mode", "NO_MATCH") != "AUTO_POST"
    object.get(d3, "decision_mode", "NO_MATCH") != "AUTO_POST"
    object.get(d4, "decision_mode", "NO_MATCH") != "AUTO_POST"
    object.get(d5, "decision_mode", "NO_MATCH") != "AUTO_POST"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Progi jako dane (ADR-002): wersje i okno temporalne obecne; fe:N (P47)
# ═══════════════════════════════════════════════════════════════════════════════
test_p46_thresholds_version_present {
    data.jdg.thresholds.v3_p46.v3_p46_threshold_version != ""
    data.jdg.thresholds.v3_p46.valid_from == "2026-01-01"
}

test_p46_migration_map_fe_n_no_invented_rates {
    data.jdg.thresholds.v3_p46_migration_map.v3_p46_mig_zus_2026q1_spotykane[0] == "fe:N"
}
