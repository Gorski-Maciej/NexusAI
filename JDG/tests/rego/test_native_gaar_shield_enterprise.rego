# Native Rego contract tests for jdg.gaar_shield.

package test_jdg_gaar_shield


test_no_match_for_empty_input {
    result := data.jdg.gaar_shield.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.gaar_shield.no_match"
}

test_three_test_analyzer_low_risk {
    result := data.jdg.gaar_shield.decide with input as {
        "gaar_shield_analyze": true,
        "gaar_estimated_tax_benefit_pln": 50000,
        "gaar_tax_purpose_override": false,
        "gaar_regulatory_arbitrage": false,
        "gaar_business_rationale_exists": true,
        "gaar_substance_level": "HIGH",
    }
    result.matched == true
    result.rule_id == "jdg.gaar_shield.three_test_analyzer"
    result.priority == 3000
    result.gaar_test_1_tax_benefit == true
    result.gaar_overall_risk == "LOW"
}

test_three_test_analyzer_critical_risk {
    result := data.jdg.gaar_shield.decide with input as {
        "gaar_shield_analyze": true,
        "gaar_estimated_tax_benefit_pln": 250000,
        "gaar_tax_purpose_override": true,
        "gaar_business_rationale_exists": false,
        "gaar_substance_level": "NONE",
        "gaar_related_parties": true,
        "gaar_circular_structure": true,
        "gaar_offshore_elements": true,
        "gaar_aggressive_timeline": true,
    }
    result.rule_id == "jdg.gaar_shield.three_test_analyzer"
    result.gaar_test_2_contrary_to_purpose == true
    result.gaar_test_3_artificiality == true
    result.gaar_overall_risk == "CRITICAL"
    result._routing == "BLOCK_AND_ALERT"
    result.gaar_mdr_reportable == true
}

test_round_tripping_detector {
    result := data.jdg.gaar_shield.decide with input as {
        "gaar_round_trip_check": true,
        "gaar_cycle_days": 14,
        "gaar_transaction_chain": [
            {"party_id": "A"},
            {"party_id": "B"},
            {"party_id": "A"},
        ],
    }
    result.matched == true
    result.rule_id == "jdg.gaar_shield.round_tripping_detector"
    result.priority == 3010
    result.gaar_round_trip_detected == true
}

test_round_tripping_non_cycle_is_not_detected {
    result := data.jdg.gaar_shield.decide with input as {
        "gaar_round_trip_check": true,
        "gaar_transaction_chain": [
            {"party_id": "A"},
            {"party_id": "B"},
            {"party_id": "C"},
        ],
    }
    result.rule_id == "jdg.gaar_shield.round_tripping_detector"
    result.gaar_round_trip_detected == false
    result._routing == ""
}

test_first_match_prefers_three_test_analyzer {
    result := data.jdg.gaar_shield.decide with input as {
        "gaar_shield_analyze": true,
        "gaar_round_trip_check": true,
        "gaar_transaction_chain": [{"party_id": "A"}, {"party_id": "A"}, {"party_id": "A"}],
    }
    result.rule_id == "jdg.gaar_shield.three_test_analyzer"
    result.priority == 3000
}
