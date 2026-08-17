# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: PIT KUP (PROMPT 05)
# Source: rules/pit/kup.rego (art. 22-23 PIT)
# Package: jdg.pit.kup
# Rules tested: KUP samochodowe 75%, limity 150k/225k EV, pełna KUP
# ═══════════════════════════════════════════════════════════════

package test_jdg_pit_kup
import data.jdg.pit.kup

# 1. jdg.pit.kup.car_operating_75pct — 75% KUP bez ewidencji (art. 23 ust. 1 pkt 46)
test_positive_car_75pct {
    result := data.jdg.pit.kup.decide with input as {
        "invoice": {"direction": "PURCHASE", "expense_type": "CAR_FUEL"}
    }
    result.rule_id == "jdg.pit.kup.car_operating_75pct"
    result.matched == true
    result.kus_qualification == "car_operating_no_log"
}

test_negative_car_75pct {
    result := data.jdg.pit.kup.decide with input as {}
    result.rule_id != "jdg.pit.kup.car_operating_75pct"
}

# 2. jdg.pit.kup.car_over_150k — limit wartości auta 150k (art. 23 ust. 1 pkt 47a)
test_positive_car_over_150k {
    result := data.jdg.pit.kup.decide with input as {
        "invoice": {"category_code": "CAR", "amount_net": 180000}
    }
    result.rule_id == "jdg.pit.kup.car_over_150k"
    result.matched == true
    result.kus_qualification == "limited_car_150k"
}

# 3. jdg.pit.kup.car_electric_225k — limit EV 225k
test_positive_car_electric_225k {
    result := data.jdg.pit.kup.decide with input as {
        "invoice": {"category_code": "CAR", "is_electric": true, "has_ev_subsidy": false, "amount_net": 240000}
    }
    result.rule_id == "jdg.pit.kup.car_electric_225k"
    result.matched == true
}

# 4. jdg.pit.kup.full_deductible — pełna KUP
test_positive_full_deductible {
    result := data.jdg.pit.kup.decide with input as {
        "invoice": {"direction": "PURCHASE", "expense_type": "OFFICE_RENT"},
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.rule_id == "jdg.pit.kup.full_deductible"
    result.matched == true
}

# 5. jdg.pit.kup.no_match — fallback
test_positive_no_match {
    result := data.jdg.pit.kup.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.pit.kup.no_match"
}

# 6. jdg.pit.kup.annual_limits_monitor (P05 GLM52 — INN-04, trigger)
# Auto standard 180 000 > 150 000 → BLOCK_AND_ALERT, nadwyżka 30 000
test_positive_annual_limits_exceeded {
    result := data.jdg.pit.kup.decide with input as {
        "pit_kup_limits_check": true,
        "pit_kup_limits": {
            "income": 300000,
            "cars_standard_value": 180000,
            "cars_ev_value": 0,
            "health_linear_deducted": 5000,
            "donations_total": 5000,
            "cash_payments_total": 3000
        }
    }
    result.rule_id == "jdg.pit.kup.annual_limits_monitor"
    result.matched == true
    result._routing == "BLOCK_AND_ALERT"
    result.kup_limits.exceeded_names == ["car_standard_150k"]
    result.kup_limits.exceeded_limits[_].limit == "car_standard_150k"
    result.kup_limits.exceeded_limits[_].excess == 30000
}

# 7. annual_limits_monitor — wszystko w limitach → brak alarmu
test_positive_annual_limits_ok {
    result := data.jdg.pit.kup.decide with input as {
        "pit_kup_limits_check": true,
        "pit_kup_limits": {
            "income": 100000,
            "cars_standard_value": 100000,
            "cars_ev_value": 100000,
            "health_linear_deducted": 8000,
            "donations_total": 4000,
            "cash_payments_total": 10000
        }
    }
    result.rule_id == "jdg.pit.kup.annual_limits_monitor"
    result._routing == ""
    count(result.kup_limits.exceeded_limits) == 0
}
