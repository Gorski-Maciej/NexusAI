# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: AMORTYZACJA MIKRO (PROMPT 06 GLM52)
# Source: rules/micro/amortyzacja/ (art. 22a-22o PIT)
# Packages: jdg.micro.amort_a22a / a22b / a22c / a22h / a22i / a22k / a22n
# Konwencja: brak catch-all {true} — brak dopasowania → default no_match (INV-018)
# ═══════════════════════════════════════════════════════════════════════════════

package test_jdg_amortyzacja_micro

# ── jdg.micro.amort_a22a (definicja ŚT, art. 22a) ────────────────────────────

test_a22a_r1_fa_definition {
    result := data.jdg.micro.amort_a22a.decide with input as {
        "invoice": {"direction": "PURCHASE", "category_code": "FIXED_ASSET", "asset_initial_value": 50000}
    }
    result.rule_id == "jdg.micro.amort_a22a.r1"
    result.matched == true
    result._legal_basis == "Art. 22a ust. 1 PIT"
}

test_a22a_r6_blocked_not_ready {
    result := data.jdg.micro.amort_a22a.decide with input as {
        "invoice": {"category_code": "FIXED_ASSET", "asset_ready_for_use": false}
    }
    result.rule_id == "jdg.micro.amort_a22a.r6"
    result._routing == "BLOCK_AND_ALERT"
}

test_a22a_r7_blocked_not_owned {
    result := data.jdg.micro.amort_a22a.decide with input as {
        "invoice": {"category_code": "VEHICLE", "is_owned_asset": false, "is_co_owned_asset": false}
    }
    result.rule_id == "jdg.micro.amort_a22a.r7"
    result.kus_qualification == "NKUP"
}

test_a22a_no_match_unrelated {
    result := data.jdg.micro.amort_a22a.decide with input as {"invoice": {"category_code": "SERVICE"}}
    result.matched == false
    result.rule_id == "jdg.micro.amort_a22a.no_match"
}

# ── jdg.micro.amort_a22b (WNiP, art. 22b) ─────────────────────────────────────

test_a22b_r1_wnip_definition {
    result := data.jdg.micro.amort_a22b.decide with input as {
        "invoice": {"category_code": "INTANGIBLE_ASSET", "wnip_kind": "SOFTWARE", "asset_initial_value": 30000}
    }
    result.rule_id == "jdg.micro.amort_a22b.r1"
    result.matched == true
    result.wnip_type == "program komputerowy"
}

test_a22b_r4_blocked_not_in_business {
    result := data.jdg.micro.amort_a22b.decide with input as {
        "invoice": {"is_wnip": true, "wnip_used_in_business": false}
    }
    result.rule_id == "jdg.micro.amort_a22b.r4"
    result._routing == "BLOCK_AND_ALERT"
}

test_a22b_no_match {
    result := data.jdg.micro.amort_a22b.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.micro.amort_a22b.no_match"
}

# ── jdg.micro.amort_a22c (wyłączenia, art. 22c) ───────────────────────────────

test_a22c_r1_blocked_land {
    result := data.jdg.micro.amort_a22c.decide with input as {
        "invoice": {"category_code": "LAND", "is_land": true}
    }
    result.rule_id == "jdg.micro.amort_a22c.r1"
    result._routing == "BLOCK_AND_ALERT"
}

test_a22c_r3_blocked_art_works {
    result := data.jdg.micro.amort_a22c.decide with input as {
        "invoice": {"category_code": "ART_WORK"}
    }
    result.rule_id == "jdg.micro.amort_a22c.r3"
}

test_a22c_no_match {
    result := data.jdg.micro.amort_a22c.decide with input as {}
    result.matched == false
}

# ── jdg.micro.amort_a22h (zasady odpisów, art. 22h) ───────────────────────────

test_a22h_r1_write_off_is_kup {
    result := data.jdg.micro.amort_a22h.decide with input as {
        "invoice": {"depreciation_write_off_pln": 1000, "depreciation_monthly_pln": 83.33}
    }
    result.rule_id == "jdg.micro.amort_a22h.r1"
    result.depreciation_is_cost == true
}

test_a22h_r3_blocked_before_acceptance {
    result := data.jdg.micro.amort_a22h.decide with input as {
        "invoice": {"depreciation_write_off_pln": 1000, "asset_ready_for_use": false}
    }
    result.rule_id == "jdg.micro.amort_a22h.r3"
    result._routing == "BLOCK_AND_ALERT"
}

test_a22h_r5_invariant_ok {
    result := data.jdg.micro.amort_a22h.decide with input as {
        "invoice": {"asset_initial_value": 100000, "cumulative_depreciation_pln": 40000}
    }
    result.rule_id == "jdg.micro.amort_a22h.r5"
    result.write_offs_ok == true
}

test_a22h_r6_blocked_invariant_broken {
    result := data.jdg.micro.amort_a22h.decide with input as {
        "invoice": {"asset_initial_value": 100000, "cumulative_depreciation_pln": 120000}
    }
    result.rule_id == "jdg.micro.amort_a22h.r6"
    result._routing == "BLOCK_AND_ALERT"
}

# ── jdg.micro.amort_a22i (metody: liniowa/degresywna, art. 22h/22k) ───────────

test_a22i_r1_linear_default {
    result := data.jdg.micro.amort_a22i.decide with input as {
        "invoice": {"category_code": "MACHINERY", "asset_initial_value": 100000}
    }
    result.rule_id == "jdg.micro.amort_a22i.r1"
    result.kus_qualification == "KUP_DEDUCTIBLE"
}

test_a22i_r4_degressive {
    result := data.jdg.micro.amort_a22i.decide with input as {
        "invoice": {"depreciation_method": "DEGRESSIVE", "depreciation_base_rate": 20, "degressive_coefficient": 2.0}
    }
    result.rule_id == "jdg.micro.amort_a22i.r4"
    result._legal_basis == "Art. 22k ust. 1 PIT (metoda degresywna)"
}

test_a22i_r6_blocked_wrong_coefficient {
    result := data.jdg.micro.amort_a22i.decide with input as {
        "invoice": {"degressive_coefficient": 2.5, "kst_group": "1"}
    }
    result.rule_id == "jdg.micro.amort_a22i.r6"
    result._routing == "BLOCK_AND_ALERT"
}

# ── jdg.micro.amort_a22k (jednorazowa de minimis + limity, art. 22k) ──────────

test_a22k_r1_one_time_small_taxpayer {
    result := data.jdg.micro.amort_a22k.decide with input as {
        "jdg_entrepreneur": {"is_small_taxpayer": true},
        "invoice": {"one_time_depreciation": true}
    }
    result.rule_id == "jdg.micro.amort_a22k.r1"
    result.matched == true
}

test_a22k_r4_blocked_car {
    result := data.jdg.micro.amort_a22k.decide with input as {
        "invoice": {"category_code": "VEHICLE", "one_time_depreciation": true, "is_passenger_car": true}
    }
    result.rule_id == "jdg.micro.amort_a22k.r4"
    result._routing == "BLOCK_AND_ALERT"
}

test_a22k_r5_low_value {
    result := data.jdg.micro.amort_a22k.decide with input as {
        "invoice": {"category_code": "COMPUTER_EQUIPMENT", "amount_net": 9000}
    }
    result.rule_id == "jdg.micro.amort_a22k.r5"
    result.kus_qualification == "KUP_DEDUCTIBLE"
}

# ── jdg.micro.amort_a22n (ewidencja ŚT, art. 22n) ─────────────────────────────

test_a22n_r1_register_mandatory {
    result := data.jdg.micro.amort_a22n.decide with input as {
        "jdg_entrepreneur": {"has_fixed_assets": true, "fixed_asset_count": 3}
    }
    result.rule_id == "jdg.micro.amort_a22n.r1"
}

test_a22n_r5_blocked_no_register {
    result := data.jdg.micro.amort_a22n.decide with input as {
        "jdg_entrepreneur": {"asset_register_exists": false, "has_fixed_assets": true}
    }
    result.rule_id == "jdg.micro.amort_a22n.r5"
    result._routing == "BLOCK_AND_ALERT"
}

test_a22n_no_match {
    result := data.jdg.micro.amort_a22n.decide with input as {}
    result.matched == false
}
