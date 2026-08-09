# Native Rego contract tests for jdg.hyper_plan45_meta.

package test_jdg_hyper_plan45_meta


test_no_match_for_empty_input {
    result := data.jdg.hyper_plan45_meta.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.meta.no_match"
}

test_consistency_check {
    result := data.jdg.hyper_plan45_meta.decide with input as {
        "meta_consistency_check": true,
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "vat_status": "ACTIVE",
            "has_employees": true,
            "is_cross_border_active": true,
            "has_qualifying_ip": true,
        },
    }
    result.matched == true
    result.rule_id == "jdg.meta.consistency_check"
    result.priority == 100
    result.meta_consistency_score < 100
    count(result.meta_active_modules) > 0
}

test_coverage_analyzer {
    result := data.jdg.hyper_plan45_meta.decide with input as {
        "meta_coverage_analysis": true,
        "jdg_entrepreneur": {
            "vat_status": "ACTIVE",
            "has_employees": true,
            "is_cross_border_active": true,
        },
    }
    result.rule_id == "jdg.meta.coverage_analyzer"
    result.priority == 200
    result.meta_total_rules_available == 455
    result.meta_active_rules > 0
    result.meta_coverage_pct <= 100
}

test_optimal_path_recommender {
    result := data.jdg.hyper_plan45_meta.decide with input as {
        "meta_optimal_path": true,
        "jdg_entrepreneur": {"tax_form": "LINEAR"},
    }
    result.rule_id == "jdg.meta.optimal_path_recommender"
    result.priority == 300
    count(result.meta_recommended_s1_to_s9) > 0
}

test_first_match_prefers_consistency {
    result := data.jdg.hyper_plan45_meta.decide with input as {
        "meta_consistency_check": true,
        "meta_coverage_analysis": true,
        "meta_optimal_path": true,
        "jdg_entrepreneur": {},
    }
    result.rule_id == "jdg.meta.consistency_check"
    result.priority == 100
}

test_unrelated_input_is_no_match {
    result := data.jdg.hyper_plan45_meta.decide with input as {"invoice": {"amount_net": 100}}
    result.matched == false
    result.rule_id == "jdg.meta.no_match"
}
