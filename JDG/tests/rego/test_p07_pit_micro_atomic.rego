# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Rego Tests: P07 PIT MICRO ATOMIC ENTERPRISE v9.0
# Sekcje 2-6: amortyzacja + NKUP + ulgi + mapa atomowa + 14 innowacji
# Format: complete rules (test_foo { ... }) — poprawna składnia OPA v0.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p07_pit_micro_atomic_test

import future.keywords.in

# ── SEKCJA 2: KALKULATOR AMORTYZACJI ─────────────────────────────────────────

test_amortization_calculator_linear {
    result := data.jdg.p07_pit_micro_atomic.amortization_calculator with input as {
        "jdg_entrepreneur": {"p07_depreciation_check": true},
        "depreciation": {"asset_value": 100000, "kst_group": "8",
            "small_taxpayer": true, "prefer_degressive": false}
    } with data.jdg.thresholds as {
        "depreciation": {"one_off_low_value_limit": 10000,
            "one_off_de_minimis_limit": 100000, "improvement_threshold": 10000},
        "pit": {"small_taxpayer_pit_limit_eur": 2000000}
    }
    result.matched == true
    result.calculator.base_rate == 0.20
    result.calculator.linear_annual == 20000
    result.calculator.one_time_eligible == true
    result.calculator.one_time_amount == 100000
    result.calculator.recommended_method == "ONE_TIME"
    result._routing == "REPORT"
}

test_amortization_calculator_degressive {
    result := data.jdg.p07_pit_micro_atomic.amortization_calculator with input as {
        "jdg_entrepreneur": {"p07_depreciation_check": true},
        "depreciation": {"asset_value": 200000, "kst_group": "6",
            "small_taxpayer": false, "prefer_degressive": true}
    } with data.jdg.thresholds as {
        "depreciation": {"one_off_low_value_limit": 10000,
            "one_off_de_minimis_limit": 100000, "improvement_threshold": 10000},
        "pit": {"small_taxpayer_pit_limit_eur": 2000000}
    }
    result.calculator.base_rate == 0.10
    result.calculator.declining_annual == 40000
    result.calculator.one_time_eligible == false
    result.calculator.one_time_amount == 0
    result.calculator.recommended_method == "DEGRESSIVE"
}

test_amortization_calculator_linear_default {
    result := data.jdg.p07_pit_micro_atomic.amortization_calculator with input as {
        "jdg_entrepreneur": {"p07_depreciation_check": true},
        "depreciation": {"asset_value": 300000, "kst_group": "1",
            "small_taxpayer": false, "prefer_degressive": false}
    } with data.jdg.thresholds as {
        "depreciation": {"one_off_low_value_limit": 10000,
            "one_off_de_minimis_limit": 100000, "improvement_threshold": 10000},
        "pit": {"small_taxpayer_pit_limit_eur": 2000000}
    }
    result.calculator.base_rate == 0.015
    result.calculator.linear_annual == 4500
    result.calculator.recommended_method == "LINEAR"
}

# ── SEKCJA 2: WERYFIKATOR STAWEK KŚT ─────────────────────────────────────────

test_kst_rate_verifier_ok {
    result := data.jdg.p07_pit_micro_atomic.kst_rate_verifier with input as {
        "jdg_entrepreneur": {"p07_kst_check": true},
        "depreciation": {"kst_group": "5", "declared_rate": 0.07}
    }
    result.matched == true
    result.verifier.expected_rate == 0.07
    result.verifier.rate_ok == true
    result.verifier.rate_ok_note == "ZGODNA"
}

test_kst_rate_verifier_bad {
    result := data.jdg.p07_pit_micro_atomic.kst_rate_verifier with input as {
        "jdg_entrepreneur": {"p07_kst_check": true},
        "depreciation": {"kst_group": "5", "declared_rate": 0.10}
    }
    result.verifier.rate_ok == false
}

# ── SEKCJA 2: WARTOŚĆ POCZĄTKOWA (Art. 22b) ─────────────────────────────────

test_initial_value_purchase {
    result := data.jdg.p07_pit_micro_atomic.initial_value_auditor with input as {
        "jdg_entrepreneur": {"p07_initial_value_check": true},
        "initial_value": {"purchase_price": 50000, "production_cost": 0,
            "market_value_gift": 0}
    }
    result.matched == true
    result.initial_value.base == 50000
    result.initial_value.base_source == "CENA NABYCIA"
}

test_initial_value_production {
    result := data.jdg.p07_pit_micro_atomic.initial_value_auditor with input as {
        "jdg_entrepreneur": {"p07_initial_value_check": true},
        "initial_value": {"purchase_price": 0, "production_cost": 30000,
            "market_value_gift": 0}
    }
    result.initial_value.base == 30000
    result.initial_value.base_source == "KOSZT WYTWORZENIA"
}

test_initial_value_gift {
    result := data.jdg.p07_pit_micro_atomic.initial_value_auditor with input as {
        "jdg_entrepreneur": {"p07_initial_value_check": true},
        "initial_value": {"purchase_price": 0, "production_cost": 0,
            "market_value_gift": 20000}
    }
    result.initial_value.base == 20000
    result.initial_value.base_source == "WARTOŚĆ RYNKOWA (DAROWIZNA/SPADEK)"
}

# ── SEKCJA 2: LIMIT AUTA (Art. 22k) ──────────────────────────────────────────

test_car_depreciation_limit_standard {
    result := data.jdg.p07_pit_micro_atomic.car_depreciation_limit with input as {
        "jdg_entrepreneur": {"p07_car_limit_check": true},
        "depreciation": {"car_value": 200000, "car_is_electric": false}
    } with data.jdg.thresholds as {
        "car_value_limit_standard": 150000, "car_value_limit_ev": 225000
    }
    result.matched == true
    result.car.limit == 150000
    result.car.above_limit == true
    result.car.depreciable_base == 150000
}

test_car_depreciation_limit_ev {
    result := data.jdg.p07_pit_micro_atomic.car_depreciation_limit with input as {
        "jdg_entrepreneur": {"p07_car_limit_check": true},
        "depreciation": {"car_value": 200000, "car_is_electric": true}
    } with data.jdg.thresholds as {
        "car_value_limit_standard": 150000, "car_value_limit_ev": 225000
    }
    result.car.limit == 225000
    result.car.above_limit == false
    result.car.depreciable_base == 200000
}

# ── SEKCJA 2: NISKOCENNE (Art. 22n) ──────────────────────────────────────────

test_low_value_asset {
    result := data.jdg.p07_pit_micro_atomic.low_value_asset with input as {
        "jdg_entrepreneur": {"p07_low_value_check": true},
        "depreciation": {"asset_value": 8000}
    } with data.jdg.thresholds as {
        "depreciation": {"one_off_low_value_limit": 10000}
    }
    result.matched == true
    result.low.is_low_value == true
    result.low.deductible_in_12_months == true
}

test_low_value_asset_above {
    result := data.jdg.p07_pit_micro_atomic.low_value_asset with input as {
        "jdg_entrepreneur": {"p07_low_value_check": true},
        "depreciation": {"asset_value": 15000}
    } with data.jdg.thresholds as {
        "depreciation": {"one_off_low_value_limit": 10000}
    }
    result.low.is_low_value == false
}

# ── SEKCJA 2: TRACKER REMANENTU (Art. 24a) ───────────────────────────────────

test_remnant_tracker {
    result := data.jdg.p07_pit_micro_atomic.remnant_tracker with input as {
        "jdg_entrepreneur": {"p07_remnant_check": true},
        "remnant": {"opening_remnant": 10000, "closing_remnant": 25000,
            "opening_included_in_income": false}
    }
    result.matched == true
    result.remnant.closing_due_in_income == true
    result.remnant.adjustment == 15000
}

# ── SEKCJA 3: AUDYT NKUP (Art. 23) ───────────────────────────────────────────

test_nkup_auditor_ok {
    result := data.jdg.p07_pit_micro_atomic.nkup_auditor with input as {
        "jdg_entrepreneur": {"p07_nkup_check": true},
        "nkup": {"representation_costs": false, "car_operating_pct": 75,
            "lease_insurance": 120000, "penalties": false, "late_interest": false,
            "donations": false, "zus_in_costs": false}
    }
    result.matched == true
    result.nkup.representation_nkup == false
    result.nkup.car_pct_75_limit == true
    result.nkup.violations_count == 0
    result.nkup.status == "OK"
}

test_nkup_auditor_violations {
    result := data.jdg.p07_pit_micro_atomic.nkup_auditor with input as {
        "jdg_entrepreneur": {"p07_nkup_check": true},
        "nkup": {"representation_costs": true, "car_operating_pct": 80,
            "lease_insurance": 120000, "penalties": true, "late_interest": false,
            "donations": false, "zus_in_costs": false}
    }
    result.nkup.representation_nkup == true
    result.nkup.car_pct_75_limit == false
    result.nkup.violations_count == 2
}

# ── SEKCJA 4: SYMULATOR ULG (limit wspólny 85 528) ───────────────────────────

test_relief_simulator_within_limit {
    result := data.jdg.p07_pit_micro_atomic.relief_simulator with input as {
        "jdg_entrepreneur": {"p07_relief_check": true},
        "reliefs": {"young_income": 20000, "family_income": 10000,
            "senior_income": 0, "returning_income": 0,
            "rehabilitation_expenses": 5000, "internet_expenses": 400,
            "thermo_expenses": 20000, "qualified_ip_income": 100000}
    } with data.jdg.thresholds as {
        "pit": {"pit_relief_shared_limit": 85528, "ip_box_rate": 0.05,
            "thermo_relief_limit": 53000}
    }
    result.matched == true
    result.reliefs.young_26 == 20000
    result.reliefs.family_4plus == 10000
    result.reliefs.total_used == 30000
    result.reliefs.shared_limit_guard == true
    result.reliefs.thermo == 20000
    result.reliefs.ip_box == 5000
}

test_relief_simulator_over_limit {
    result := data.jdg.p07_pit_micro_atomic.relief_simulator with input as {
        "jdg_entrepreneur": {"p07_relief_check": true},
        "reliefs": {"young_income": 100000, "family_income": 20000,
            "senior_income": 0, "returning_income": 0,
            "rehabilitation_expenses": 0, "internet_expenses": 0,
            "thermo_expenses": 0, "qualified_ip_income": 0}
    } with data.jdg.thresholds as {
        "pit": {"pit_relief_shared_limit": 85528, "ip_box_rate": 0.05,
            "thermo_relief_limit": 53000}
    }
    result.reliefs.young_26 == 85528
    result.reliefs.family_4plus == 20000
    result.reliefs.shared_limit_guard == false
}

# ── SEKCJA 4: IP BOX NEXUS (Art. 30ca) ───────────────────────────────────────

test_ip_box_nexus {
    result := data.jdg.p07_pit_micro_atomic.ip_box_nexus with input as {
        "jdg_entrepreneur": {"p07_ipbox_check": true},
        "ip_box": {"qualified_revenue": 80000, "total_revenue": 100000,
            "qualified_ip_income": 50000}
    } with data.jdg.thresholds as {
        "pit": {"ip_box_rate": 0.05}
    }
    result.matched == true
    result.nexus.nexus_ratio == 0.8
    result.nexus.nexus_ratio_ok == true
    result.nexus.tax_at_5pct == 2500
}

# ── SEKCJA 5: PROOF-OF-LAW (LKG) + GOLDEN DATASET ────────────────────────────

test_proof_of_law {
    result := data.jdg.p07_pit_micro_atomic.proof_of_law with input as {
        "jdg_entrepreneur": {"p07_lkg_check": true},
        "proof": {"art_22a": "Art. 22a PIT", "art_23": "Art. 23 PIT",
            "art_26": "Art. 26 PIT"}
    }
    result.matched == true
    result.lkg.citation_count == 3
    result.lkg.verified == true
}

test_golden_dataset_boundaries {
    result := data.jdg.p07_pit_micro_atomic.golden_dataset with input as {
        "jdg_entrepreneur": {"p07_golden_check": true}
    } with data.jdg.thresholds as {
        "pit": {"scale_threshold": 120000, "pit_relief_shared_limit": 85528,
            "tax_free_amount": 30000},
        "depreciation": {"one_off_low_value_limit": 10000},
        "car_value_limit_standard": 150000, "car_value_limit_ev": 225000
    }
    result.golden.scale_threshold == 120000
    result.golden.relief_shared_limit == 85528
    result.golden.tax_free_amount == 30000
    result.golden.car_limit_standard == 150000
    result.golden.car_limit_ev == 225000
}

# ── SEKCJA 1+6: MAPA ATOMOWA + GŁÓWNY RAPORT ─────────────────────────────────

test_coverage_status_with_audit_data {
    result := data.jdg.p07_pit_micro_atomic.article_coverage_status with data.jdg.pit_micro_audit as {
        "coverage": {"22a": "COMPLETE", "22b": "MISSING", "23": "COMPLETE"}
    }
    result.total_articles == 3
    result.complete_count == 2
    result.missing_count == 1
}

test_p07_main_report {
    result := data.jdg.p07_pit_micro_atomic.decide with input as {
        "jdg_entrepreneur": {"p07_pit_micro_check": true}
    } with data.jdg.thresholds as {
        "pit": {"scale_threshold": 120000, "pit_relief_shared_limit": 85528,
            "ip_box_rate": 0.05, "thermo_relief_limit": 53000,
            "tax_free_amount": 30000, "small_taxpayer_pit_limit_eur": 2000000},
        "depreciation": {"one_off_low_value_limit": 10000,
            "one_off_de_minimis_limit": 100000, "improvement_threshold": 10000},
        "car_value_limit_standard": 150000, "car_value_limit_ev": 225000
    }
    result.matched == true
    result.rule_id == "jdg.p07_pit_micro_atomic.report"
    result._routing == "REPORT"
    count(result.p07_pit_micro.section5_genius) == 15
    result.p07_pit_micro.dependencies.P06_PIT_MACRO == "źródło prawdy atomowej dla macro"
}

test_p07_no_match_default {
    result := data.jdg.p07_pit_micro_atomic.decide with input as {
        "jdg_entrepreneur": {"p07_pit_micro_check": false}
    }
    result.matched == false
    result.rule_id == "jdg.p07_pit_micro_atomic.no_match"
}
