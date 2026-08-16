# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: PIT FORMS (PROMPT 05)
# Source: rules/pit/forms.rego (art. 9a, 27, 30c PIT)
# Package: jdg.pit.forms
# Rules tested: skala, liniowy, ryczałt, karta, blokada byłego pracodawcy
# ═══════════════════════════════════════════════════════════════

package test_jdg_pit_forms
import data.jdg.pit.forms

# 1. jdg.pit.forms.scale — skala 12/32% (art. 27)
test_positive_scale {
    result := data.jdg.pit.forms.decide with input as {
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE", "cumulative_income_current_year": 100000}
    }
    result.rule_id == "jdg.pit.forms.scale"
    result.matched == true
    result.pit_form == "SCALE"
    result.pit_annual_return_type == "PIT-36"
}

test_negative_scale {
    result := data.jdg.pit.forms.decide with input as {}
    result.rule_id != "jdg.pit.forms.scale"
}

# 2. jdg.pit.forms.linear — liniowy 19% (art. 30c)
test_positive_linear {
    result := data.jdg.pit.forms.decide with input as {
        "jdg_entrepreneur": {"tax_form": "LINEAR"}
    }
    result.rule_id == "jdg.pit.forms.linear"
    result.matched == true
    result.pit_annual_return_type == "PIT-36L"
}

# 3. jdg.pit.forms.lump_sum — ryczałt (ustawa o ryczałcie)
test_positive_lump_sum {
    result := data.jdg.pit.forms.decide with input as {
        "jdg_entrepreneur": {"tax_form": "LUMP_SUM"},
        "invoice": {"pkwiu_code": "62.01.Z"}
    }
    result.rule_id == "jdg.pit.forms.lump_sum"
    result.matched == true
}

# 4. jdg.pit.forms.linear_former_employer_block — blokada liniowego (art. 30c ust. 2)
test_positive_former_employer_block {
    result := data.jdg.pit.forms.decide with input as {
        "jdg_entrepreneur": {"tax_form": "LINEAR", "former_employer_services": true}
    }
    result.rule_id == "jdg.pit.forms.linear_former_employer_block"
    result.matched == true
}

# 5. jdg.pit.forms.tax_card — karta podatkowa
test_positive_tax_card {
    result := data.jdg.pit.forms.decide with input as {
        "jdg_entrepreneur": {"tax_form": "TAX_CARD"}
    }
    result.rule_id == "jdg.pit.forms.tax_card"
    result.matched == true
}

# 6. jdg.pit.forms.no_match — fallback
test_positive_no_match {
    result := data.jdg.pit.forms.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.pit.forms.no_match"
}

# 7. jdg.pit.forms.what_if_recommendation (P05 GLM52 — INN-06, trigger)
# Skala 40 000 vs liniowy 38 000 vs ryczałt 17 000 vs karta 40 000 → LUMP_SUM
test_positive_what_if_recommendation {
    result := data.jdg.pit.forms.decide with input as {
        "pit_what_if_check": true,
        "pit_what_if": {"income": 200000, "revenue": 250000, "kup": 50000,
                        "zus_social": 0, "lump_category": "services"}
    }
    result.rule_id == "jdg.pit.forms.what_if_recommendation"
    result.matched == true
    result.what_if.recommendation == "LUMP_SUM"
    result.what_if.paths.SCALE == 40000
    result.what_if.paths.LINEAR == 38000
    result.what_if.paths.LUMP_SUM == 17000
    result.what_if.savings_vs_scale == 23000
}

# 8. what_if — bez triggera reguła nie odpala się (fallback no_match)
test_negative_what_if_without_trigger {
    result := data.jdg.pit.forms.decide with input as {
        "pit_what_if": {"income": 200000}
    }
    result.rule_id == "jdg.pit.forms.no_match"
}
