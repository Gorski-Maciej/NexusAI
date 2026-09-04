# V3-P14 — native Rego tests for the PIT reliefs/forms enterprise layer (campaign V3).
# Scenariusze pokrywają innowacje I01–I12: macierz ulg (I01), limity-as-data (I02),
# IP Box nexus (I03), optymalizacja kolejności odliczeń pod invariant P04 (I04),
# doradca formy 20.02 (I05), symulator 12M (I06), loss harvesting 50%/5 lat (I07),
# checklist dokumentacyjne (I08), sentinel wygasania (I09), golden set granic (I10),
# detektor kolizji ulg — BLOCKER (I11), wyjaśnienie decyzji (I12).
package test_jdg_v3_p14_pit_reliefs

import future.keywords.in

base_input := {
    "jdg_entrepreneur": {"v3_p14_check": true},
    "v3_p14": {},
}

test_not_activated_no_match {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {"jdg_entrepreneur": {}}
    result.rule_id == "jdg.v3_p14_pit_reliefs.no_match"
}

# ── I01: RELIEFS MATRIX COMPLETE ───────────────────────────────────────────────
test_i01_matrix_catalog_size {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "reliefs_matrix", "claims": [{"relief_id": "thermo", "amount_pln": 20000, "conditions_met": true}]},
    }
    result.rule_id == "jdg.v3_p14_pit_reliefs.reliefs_matrix_complete"
    result.reliefs_matrix.catalog_size >= 14
    result.fail_closed == false
}

test_i01_unknown_relief_needs_advice {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "reliefs_matrix", "claims": [{"relief_id": "nieznana_ulga", "amount_pln": 100}]},
    }
    result.reliefs_matrix.unknown_claims == ["nieznana_ulga"]
    result._routing == "NEEDS_ADVICE"
}

# ── I02: LIMIT-AS-DATA ENGINE ──────────────────────────────────────────────────
test_i02_limits_valid {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "limits_as_data"},
    }
    result.rule_id == "jdg.v3_p14_pit_reliefs.limit_as_data_engine"
    result.limits_as_data.valid == true
    result.limits_as_data.young_matches_shared_limit == true
}

test_i02_limits_contain_required {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "limits_as_data"},
    }
    count(result.limits_as_data.missing) == 0
    count(result.limits_as_data.non_positive) == 0
}

# ── I03: NEXUS RATIO AUDITOR (art. 30ca) ───────────────────────────────────────
test_i03_nexus_full_with_docs {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "nexus_ratio",
                   "ip_qualifying_costs_pln": 60000, "ip_total_costs_pln": 100000,
                   "ip_income_pln": 200000, "ip_documented": true, "ip_evidence_kept": true},
    }
    result.rule_id == "jdg.v3_p14_pit_reliefs.nexus_ratio_auditor"
    result.nexus_ratio.nexus_tier == "FULL"
    result.fail_closed == false
}

test_i03_nexus_missing_docs_needs_advice {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "nexus_ratio",
                   "ip_qualifying_costs_pln": 60000, "ip_total_costs_pln": 100000,
                   "ip_income_pln": 200000, "ip_documented": false, "ip_evidence_kept": false},
    }
    result._routing == "NEEDS_ADVICE"
    result.fail_closed == true
}

# ── I04: RELIEF ORDER OPTIMIZER (invariant P04) ───────────────────────────────
test_i04_within_invariant {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "relief_order",
                   "annual_income_pln": 100000,
                   "claims": [{"relief_id": "donation", "amount_pln": 5000},
                              {"relief_id": "thermo", "amount_pln": 40000}]},
    }
    result.rule_id == "jdg.v3_p14_pit_reliefs.relief_order_optimizer"
    result.relief_order.within_invariant == true
    result._routing == ""
}

test_i04_invariant_violation_blocks {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "relief_order",
                   "annual_income_pln": 50000,
                   "claims": [{"relief_id": "thermo", "amount_pln": 40000},
                              {"relief_id": "rd_relief", "amount_pln": 20000}]},
    }
    result._routing == "BLOCK_AND_ALERT"
    result.fail_closed == true
}

# ── I05: FORM CHANGER PROACTIVE (art. 9 ust. 2 — 20.02) ───────────────────────
test_i05_switch_before_deadline_allowed {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "form_changer", "decision_date": "2026-02-10",
                   "current_form": "PIT_SCALE", "target_form": "LINEAR",
                   "projected_income_pln": 200000},
    }
    result.rule_id == "jdg.v3_p14_pit_reliefs.form_changer_proactive"
    result.form_changer.within_deadline == true
    result.form_changer.change_allowed == true
}

test_i05_switch_after_deadline_needs_advice {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "form_changer", "decision_date": "2026-03-01",
                   "current_form": "PIT_SCALE", "target_form": "LINEAR",
                   "projected_income_pln": 200000},
    }
    result.form_changer.within_deadline == false
    result._routing == "NEEDS_ADVICE"
}

# ── I06: 12-MONTH SIMULATOR ───────────────────────────────────────────────────
test_i06_simulator_12m_recommendation {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "form_simulator",
                   "monthly_revenues_pln": [10000, 10000, 10000, 10000, 10000, 10000,
                                            10000, 10000, 10000, 10000, 10000, 10000],
                   "annual_kup_pln": 30000, "annual_zus_social_pln": 15000,
                   "projected_growth_pct": 5},
    }
    result.rule_id == "jdg.v3_p14_pit_reliefs.form_simulator_12m"
    result.form_simulator.monthly_complete == true
    result.form_simulator.recommended_form in {"PIT_SCALE", "LINEAR", "LUMP_SUM"}
}

test_i06_simulator_incomplete_data {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "form_simulator",
                   "monthly_revenues_pln": [10000, 10000, 10000]},
    }
    result.form_simulator.monthly_complete == false
    result._routing == "NEEDS_ADVICE"
}

# ── I07: LOSS HARVESTING PLANNER (art. 9 ust. 3 — 50%/5 lat) ──────────────────
test_i07_loss_50pct_5yr {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "loss_harvesting",
                   "loss_amount_pln": 40000, "loss_year": 2024, "current_year_income_pln": 30000},
    }
    result.rule_id == "jdg.v3_p14_pit_reliefs.loss_harvesting_planner"
    result.loss_harvesting.window_years == 5
    result.loss_harvesting.annual_cap_pct == 0.5
    result.loss_harvesting.annual_cap_pln == 20000
}

test_i07_loss_double_use_blocks {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "loss_harvesting",
                   "loss_amount_pln": 40000, "loss_year": 2024, "current_year_income_pln": 30000,
                   "loss_already_used_elsewhere": true},
    }
    result._routing == "BLOCK_AND_ALERT"
}

# ── I08: RELIEF DOCUMENTATION PACK ─────────────────────────────────────────────
test_i08_docs_complete {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "doc_pack", "relief_id": "thermo",
                   "provided_docs": ["faktura VAT", "dokumentacja techniczna przedsięwzięcia",
                                     "dowód własności budynku"],
                   "amount_claimed_pln": 20000},
    }
    result.rule_id == "jdg.v3_p14_pit_reliefs.relief_documentation_pack"
    result.doc_pack.complete == true
    result.fail_closed == false
}

test_i08_missing_docs_needs_advice {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "doc_pack", "relief_id": "thermo",
                   "provided_docs": ["faktura VAT"], "amount_claimed_pln": 20000},
    }
    result.doc_pack.complete == false
    result._routing == "NEEDS_ADVICE"
}

# ── I09: RELIEF EXPIRY SENTINEL ────────────────────────────────────────────────
test_i09_expiry_sentinel_alerts {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "expiry_sentinel",
                   "taxpayer_age": 25, "years_since_return_to_work": 4,
                   "robotization_investment_year": 2025},
    }
    result.rule_id == "jdg.v3_p14_pit_reliefs.relief_expiry_sentinel"
    result.expiry_sentinel.young_relief_active == true
    result.expiry_sentinel.robotization_window_alert == true
}

# ── I10: RELIEF GOLDEN SET (granice) ───────────────────────────────────────────
test_i10_golden_tax_free_boundary {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "golden_set", "golden_case": "tax_free_boundary", "probe_pln": 30000},
    }
    result.rule_id == "jdg.v3_p14_pit_reliefs.relief_golden_set"
    result.golden_set.verdict.expected == true
}

test_i10_golden_unknown_case {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "golden_set", "golden_case": "fake_case", "probe_pln": 1},
    }
    result._routing == "NEEDS_ADVICE"
}

# ── I11: MULTI-RELIEF CONFLICT DETECTOR — BLOCKER ──────────────────────────────
test_i11_conflict_detected_blocks {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "conflict_detector",
                   "claims": [{"relief_id": "rd_relief", "cost_ids": ["c1"]},
                              {"relief_id": "robotization", "cost_ids": ["c1"]}]},
    }
    result.rule_id == "jdg.v3_p14_pit_reliefs.multi_relief_conflict_detector"
    result.conflict_detector.conflict_count == 1
    result._routing == "BLOCK_AND_ALERT"
}

test_i11_no_conflict_clean {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "conflict_detector",
                   "claims": [{"relief_id": "rd_relief", "cost_ids": ["c1"]},
                              {"relief_id": "thermo", "cost_ids": ["c2"]}]},
    }
    result.conflict_detector.conflict_count == 0
    result._routing == ""
}

# ── I12: RELIEF EXPLANATION ENGINE ─────────────────────────────────────────────
test_i12_explanation_generated {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "explanation", "relief_id": "thermo", "amount_claimed_pln": 20000},
    }
    result.rule_id == "jdg.v3_p14_pit_reliefs.relief_explanation_engine"
    count(result.explanation.explanation_pl) >= 2
    result.explanation.certificate_ready == true
}

test_i12_unknown_relief_needs_advice {
    result := data.jdg.v3_p14_pit_reliefs.decide with input as {
        "jdg_entrepreneur": {"v3_p14_check": true},
        "v3_p14": {"analysis": "explanation", "relief_id": "fake_relief", "amount_claimed_pln": 100},
    }
    result._routing == "NEEDS_ADVICE"
}
