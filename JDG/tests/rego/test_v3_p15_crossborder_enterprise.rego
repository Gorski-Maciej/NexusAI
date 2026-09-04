# V3-P15 — native Rego tests for the cross-border enterprise layer (campaign V3).
package test_jdg_v3_p15_crossborder

import future.keywords.in

base_input := {
    "jdg_entrepreneur": {"v3_p15_check": true},
    "v3_p15": {},
}

th := {"crossborder": {
    "residency_days": 183,
    "pos_b2b_rule": "28b",
    "pos_digital_b2c_rule": "28k",
    "tp_goods_transactions_pln": 10000000,
    "tp_services_transactions_pln": 2000000,
    "tp_financial_transactions_pln": 2500000,
    "tp_documentation_months": 6,
    "mdr_deadline_days": 30,
    "mdr_human_review_required": true,
    "exit_tax_threshold_pln": 4000000,
    "exit_tax_rate_pct": 0.19,
    "exit_tax_deferral_years_eea": 5,
    "oss_distance_selling_threshold_eur": 10000,
    "distance_selling_limit_eur": 10000,
    "golden_set_min_verdicts": 30,
    "fx_rounding_rule": "round_half_up",
    "fx_rounding_scale": 2,
    "fx_use_previous_day_rate": true,
    "wdt_invariant_required": true,
    "fx_d1_invariant_required": true,
    "import_services_rc_required": true,
    "currency_consistency_required": true,
    "threshold_version": "crossborder-2026.08",
    "legal_basis_version": "isap-lkg-2026.08",
    "valid_from": "2025-01-01",
    "valid_to": null,
}}

# Uwaga: testy natywne ewaluują się przez `opa test tests/rego/` z data.jdg.thresholds
# dostarczonym przez host (thresholds_jdg.rego). Poniżej jawne scenariusze.

test_not_activated_no_match {
    result := data.jdg.v3_p15_crossborder.decide with input as {"jdg_entrepreneur": {}}
    result.rule_id == "jdg.v3_p15_crossborder.no_match"
}

test_place_of_supply_b2b {
    result := data.jdg.v3_p15_crossborder.decide with input as {
        "jdg_entrepreneur": {"v3_p15_check": true},
        "v3_p15": {"analysis": "place_of_supply", "service_type": "software",
                   "customer_type": "B2B", "destination_country": "DE"},
    }
    result.rule_id == "jdg.v3_p15_crossborder.place_of_supply_matrix"
    result.place_of_supply.zone == "B2B_MIEJSCE_NABYWCY"
    result.place_of_supply.art == "28b"
    result.fail_closed == false
}

test_place_of_supply_digital_b2c {
    result := data.jdg.v3_p15_crossborder.decide with input as {
        "jdg_entrepreneur": {"v3_p15_check": true},
        "v3_p15": {"analysis": "place_of_supply", "service_type": "digital",
                   "customer_type": "B2C", "destination_country": "FR"},
    }
    result.place_of_supply.zone == "USLUGI_ELEKTRONICZNE_B2C"
    result.place_of_supply.art == "28k"
}

test_place_of_supply_unknown_is_needs_advice {
    result := data.jdg.v3_p15_crossborder.decide with input as {
        "jdg_entrepreneur": {"v3_p15_check": true},
        "v3_p15": {"analysis": "place_of_supply", "service_type": "software",
                   "customer_type": "B2B", "destination_country": ""},
    }
    result.place_of_supply.status == "BRAK_ŚCIEŻKI"
    result._routing == "NEEDS_ADVICE"
    result.fail_closed == true
}

test_residency_183_days {
    result := data.jdg.v3_p15_crossborder.decide with input as {
        "jdg_entrepreneur": {"v3_p15_check": true},
        "v3_p15": {"analysis": "residency", "days_in_poland": 200, "center_of_interests_pl": true},
    }
    result.residency.determination == "REZYDENT_PL_183_DNI"
    result.residency.needs_advice == false
}

test_residency_uncertain_needs_advice {
    result := data.jdg.v3_p15_crossborder.decide with input as {
        "jdg_entrepreneur": {"v3_p15_check": true},
        "v3_p15": {"analysis": "residency", "days_in_poland": 100, "center_of_interests_pl": null},
    }
    result.residency.determination == "NIEPEWNA"
    result.residency.needs_advice == true
    result._routing == "NEEDS_ADVICE"
}

test_fx_precision_grosz {
    result := data.jdg.v3_p15_crossborder.decide with input as {
        "jdg_entrepreneur": {"v3_p15_check": true},
        "v3_p15": {"analysis": "fx", "amount_foreign": 1234.56, "rate_nbp": 4.30,
                   "expected_pln": 5308.61},
    }
    result.fx.amount_pln == 5308.61
    result.invariant_ok == true
    result.fail_closed == false
}

test_fx_missing_rate_fail_closed {
    result := data.jdg.v3_p15_crossborder.decide with input as {
        "jdg_entrepreneur": {"v3_p15_check": true},
        "v3_p15": {"analysis": "fx", "amount_foreign": 1000, "rate_nbp": 0},
    }
    result.fail_closed == true
    result._routing == "BLOCK_AND_ALERT"
}

test_tp_threshold_exceeded {
    result := data.jdg.v3_p15_crossborder.decide with input as {
        "jdg_entrepreneur": {"v3_p15_check": true},
        "v3_p15": {"analysis": "tp", "tp_goods_pln": 12000000,
                   "tp_services_pln": 100000, "tp_financial_pln": 0},
    }
    result.tp.exceeded == true
    result._routing == "TRIAGE_QUEUE"
}

test_mdr_high_risk_human_review {
    result := data.jdg.v3_p15_crossborder.decide with input as {
        "jdg_entrepreneur": {"v3_p15_check": true},
        "v3_p15": {"analysis": "mdr", "mdr_score": 80},
    }
    result.mdr.high_risk == true
    result.mdr.human_review_required == true
    result._routing == "TRIAGE_QUEUE"
}

test_exit_tax_triggered {
    result := data.jdg.v3_p15_crossborder.decide with input as {
        "jdg_entrepreneur": {"v3_p15_check": true},
        "v3_p15": {"analysis": "exit_tax", "transferring_assets_abroad": true,
                   "asset_market_value": 5000000, "asset_tax_value": 1000000},
    }
    result.exit_tax.triggered == true
    result._routing == "BLOCK_AND_ALERT"
}

test_oss_suggest {
    result := data.jdg.v3_p15_crossborder.decide with input as {
        "jdg_entrepreneur": {"v3_p15_check": true},
        "v3_p15": {"analysis": "oss", "distance_sales_eur": 25000},
    }
    result.oss.oss_recommended == true
    result.oss.no_auto_post == true
    result._routing == "SUGGEST"
}

test_invariants_violation_blocked {
    result := data.jdg.v3_p15_crossborder.decide with input as {
        "jdg_entrepreneur": {"v3_p15_check": true},
        "v3_p15": {"analysis": "invariants", "wdt_claim": true,
                   "vat_ue_registered": false, "eu_customer_vat_id_valid": true,
                   "rate_date_used": "D-1", "import_services": false},
    }
    result.invariants.wdt_vat_ue_ok == false
    result.invariants.all_ok == false
    result._routing == "BLOCK_AND_ALERT"
}

test_currency_consistency_mismatch_blocked {
    result := data.jdg.v3_p15_crossborder.decide with input as {
        "jdg_entrepreneur": {"v3_p15_check": true},
        "v3_p15": {"analysis": "currency", "vat_rate": 4.30, "pkpir_rate": 4.29},
    }
    result.currency_consistency.consistent == false
    result._routing == "BLOCK_AND_ALERT"
}

test_golden_set_incomplete_triage {
    result := data.jdg.v3_p15_crossborder.decide with input as {
        "jdg_entrepreneur": {"v3_p15_check": true},
        "v3_p15": {"analysis": "golden_set", "golden_coverage": {"fx_d1": true},
                   "golden_verdicts": 12},
    }
    result.golden_set.complete == false
    result._routing == "TRIAGE_QUEUE"
}