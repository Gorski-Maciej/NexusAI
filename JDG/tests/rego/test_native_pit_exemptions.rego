# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: PIT EXEMPTIONS (PROMPT 05 GLM52)
# Source: rules/pit/exemptions.rego (art. 21 PIT, pkt 148-154)
# Package: jdg.pit.exemptions
# Rules tested: ulga dla młodych, powrót, 4+, monitor wspólnego limitu
# PIT-0 (85 528 zł) — alert 95% i przekroczenie, fallback no_match
# ═══════════════════════════════════════════════════════════════

package test_jdg_pit_exemptions
import data.jdg.pit.exemptions

# 1. jdg.pit.exemptions.young — ulga dla młodych <26 lat (art. 21 ust. 1 pkt 148)
test_positive_young {
    result := data.jdg.pit.exemptions.decide with input as {
        "jdg_entrepreneur": {"age": 25, "tax_form": "PIT_SCALE",
                             "cumulative_income_current_year": 50000,
                             "income_source_type": "JDG"}
    }
    result.rule_id == "jdg.pit.exemptions.young"
    result.matched == true
    result.exemption == "YOUNG"
    result.exemption_limit == 85528
}

# 2. jdg.pit.exemptions.return — ulga na powrót (art. 21 ust. 1 pkt 152)
test_positive_return {
    result := data.jdg.pit.exemptions.decide with input as {
        "jdg_entrepreneur": {"return_from_emigration": true, "return_years_used": 1,
                             "tax_form": "PIT_SCALE",
                             "cumulative_income_current_year": 40000,
                             "income_source_type": "JDG"}
    }
    result.rule_id == "jdg.pit.exemptions.return"
    result.matched == true
    result.exemption_years_remaining == 3
}

# 3. jdg.pit.exemptions.family_4plus — ulga 4+ (art. 21 ust. 1 pkt 153)
test_positive_family_4plus {
    result := data.jdg.pit.exemptions.decide with input as {
        "jdg_entrepreneur": {"children_count": 4, "tax_form": "PIT_SCALE",
                             "cumulative_income_current_year": 30000,
                             "income_source_type": "JDG"}
    }
    result.rule_id == "jdg.pit.exemptions.family_4plus"
    result.matched == true
    result.exemption == "FAMILY_4PLUS"
}

# 4. jdg.pit.exemptions.shared_limit_monitor — alert 95% limitu (trigger)
# 82 000 z 85 528 → 95,9% ≥ 95% (próg 81 251,60) → TRIAGE_QUEUE
test_positive_shared_limit_alert {
    result := data.jdg.pit.exemptions.decide with input as {
        "pit_exemption_monitor_check": true,
        "pit_exemption_monitor": {"young_used": 82000, "return_used": 0,
                                  "family_4plus_used": 0, "senior_used": 0}
    }
    result.rule_id == "jdg.pit.exemptions.shared_limit_monitor"
    result.matched == true
    result._routing == "TRIAGE_QUEUE"
    result.exemption_shared_usage == 82000
    result.exemption_shared_limit == 85528
}

# 5. jdg.pit.exemptions.shared_limit_monitor — PRZEKROCZENIE limitu (trigger)
# 90 000 > 85 528 → BLOCK_AND_ALERT
test_positive_shared_limit_exceeded {
    result := data.jdg.pit.exemptions.decide with input as {
        "pit_exemption_monitor_check": true,
        "pit_exemption_monitor": {"young_used": 90000, "return_used": 0,
                                  "family_4plus_used": 0, "senior_used": 0}
    }
    result.rule_id == "jdg.pit.exemptions.shared_limit_monitor"
    result.matched == true
    result._routing == "BLOCK_AND_ALERT"
}

# 6. jdg.pit.exemptions.no_match — fallback
test_positive_no_match {
    result := data.jdg.pit.exemptions.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.pit.exemptions.no_match"
}
