# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: PIT ADVANCES (PROMPT 05 GLM52)
# Source: rules/pit/advances_returns.rego (art. 44-45 PIT)
# Package: jdg.pit.advances
# Rules tested: miesięczne, kwartalne (mały podatnik), uproszczone 1/12,
# groszowe zaokrąglanie art. 63 OrdPU, terminarz kwartalny, zeznania
# roczne PIT-36/36L/28, fallback no_match
# ═══════════════════════════════════════════════════════════════

package test_jdg_pit_advances
import data.jdg.pit.advances

# 1. jdg.pit.advances.monthly — zaliczka miesięczna (art. 44 ust. 1 i 3)
test_positive_monthly {
    result := data.jdg.pit.advances.decide with input as {
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE", "uses_quarterly_advances": false}
    }
    result.rule_id == "jdg.pit.advances.monthly"
    result.matched == true
    result.pit_advance_frequency == "MONTHLY"
    result.pit_advance_due_day == 20
}

# 2. jdg.pit.advances.quarterly — kwartalna małego podatnika (art. 44 ust. 3g)
test_positive_quarterly {
    result := data.jdg.pit.advances.decide with input as {
        "jdg_entrepreneur": {"tax_form": "LINEAR", "is_small_taxpayer": true,
                             "uses_quarterly_advances": true}
    }
    result.rule_id == "jdg.pit.advances.quarterly"
    result.matched == true
    result.pit_advance_frequency == "QUARTERLY"
}

# 3. jdg.pit.advances.simplified — uproszczone 1/12 (art. 44 ust. 6b)
test_positive_simplified {
    result := data.jdg.pit.advances.decide with input as {
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE", "uses_simplified_advances": true}
    }
    result.rule_id == "jdg.pit.advances.simplified"
    result.matched == true
    result.pit_advance_frequency == "SIMPLIFIED"
}

# 4. jdg.pit.advances.grosz_rounding — pełne złote, bez groszy (art. 63 § 1 OrdPU)
test_positive_grosz_rounding_flat {
    result := data.jdg.pit.advances.decide with input as {
        "pit_advance_grosz_check": true,
        "pit_advance_grosz": {"base_amount": 10000, "rate": 0.12}
    }
    result.rule_id == "jdg.pit.advances.grosz_rounding"
    result.matched == true
    result.pit_advance_raw == 1200.00
    result.pit_advance_rounded == 1200
    result.rounding_rule == "ART_63_ORDYNACJA"
}

# 5. grosz_rounding — końcówka 50 gr → zaokrąglenie W GÓRĘ (art. 63 § 1 OrdPU)
test_positive_grosz_rounding_up {
    result := data.jdg.pit.advances.decide with input as {
        "pit_advance_grosz_check": true,
        "pit_advance_grosz": {"base_amount": 12504.17, "rate": 0.12}
    }
    result.rule_id == "jdg.pit.advances.grosz_rounding"
    result.matched == true
    result.pit_advance_rounded == 1501
    result.rounding_proof.abs_diff_pln < 1.0
}

# 6. grosz_rounding — końcówka 49 gr → zaokrąglenie W DÓŁ (art. 63 § 1 OrdPU)
test_positive_grosz_rounding_down {
    result := data.jdg.pit.advances.decide with input as {
        "pit_advance_grosz_check": true,
        "pit_advance_grosz": {"base_amount": 12504.08, "rate": 0.12}
    }
    result.rule_id == "jdg.pit.advances.grosz_rounding"
    result.matched == true
    result.pit_advance_rounded == 1500
}

# 7. jdg.pit.advances.quarterly_due_dates — terminarz kwartalny (art. 44 ust. 3g)
test_positive_quarterly_due_dates {
    result := data.jdg.pit.advances.decide with input as {
        "pit_quarterly_advance_check": true
    }
    result.rule_id == "jdg.pit.advances.quarterly_due_dates"
    result.matched == true
    result.pit_quarterly_due_dates[_].due_date == "20-04"
    result.pit_quarterly_due_dates[_].due_date == "20-07"
    result.pit_quarterly_due_dates[_].due_date == "20-10"
    result.pit_quarterly_due_dates[_].due_date == "20-01"
}

# 8. jdg.pit.advances.annual_pit28 — PIT-28 termin 28 lutego (art. 21 ust. 1 u.z.p.d.)
test_positive_annual_pit28 {
    result := data.jdg.pit.advances.decide with input as {
        "jdg_entrepreneur": {"tax_form": "LUMP_SUM"}
    }
    result.rule_id == "jdg.pit.advances.annual_pit28"
    result.matched == true
    result.pit_annual_return_type == "PIT-28"
    result.pit_annual_return_deadline == "02-28"
}

# 9. jdg.pit.advances.no_match — fallback
test_positive_no_match {
    result := data.jdg.pit.advances.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.pit.advances.no_match"
}
