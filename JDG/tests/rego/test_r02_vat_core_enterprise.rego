# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for R02 GLM52 VAT — CORE + ENTERPRISE
# Packages: jdg.r02_vat_core_innovations
# Source: 02_VAT_CORE.txt (prompty_glm52)
# Generated: 2026-08-14
# ═══════════════════════════════════════════════════════════════════════════════

package test_r02_vat_core

import future.keywords.in

# ═══ DEFAULT: bez flagi r02_vat_core_check → no_match ═══

test_default_no_match {
    result := data.jdg.r02_vat_core_innovations.decide with input as {
        "jdg_entrepreneur": {"r02_vat_core_check": false}
    }
    result.matched == false
    result.rule_id == "jdg.r02_vat_core_innovations.no_match"
}

# ═══ R02-INN-01: REAL-TIME LIMIT TRACKER (art. 113) ═══

test_limit_tracker_ok_zone {
    tracker := data.jdg.r02_vat_core_innovations.exemption_limit_tracker with input as {
        "jdg_entrepreneur": {"ytd_turnover_net": 60000, "months_elapsed": 6}
    }
    tracker.exemption_limit == 200000
    tracker.zone == "OK"
    tracker.projected_annual_turnover == 120000
}

test_limit_tracker_watch_zone {
    tracker := data.jdg.r02_vat_core_innovations.exemption_limit_tracker with input as {
        "jdg_entrepreneur": {"ytd_turnover_net": 90000, "months_elapsed": 6}
    }
    tracker.zone == "WATCH"
    tracker.projected_annual_turnover == 180000
}

test_limit_tracker_breach {
    tracker := data.jdg.r02_vat_core_innovations.exemption_limit_tracker with input as {
        "jdg_entrepreneur": {"ytd_turnover_net": 210000, "months_elapsed": 9}
    }
    tracker.zone == "BREACH"
    tracker.breach_month == ""
}

test_limit_tracker_breach_month_computed {
    tracker := data.jdg.r02_vat_core_innovations.exemption_limit_tracker with input as {
        "jdg_entrepreneur": {"ytd_turnover_net": 120000, "months_elapsed": 6}
    }
    # projekcja 240 000 ≥ 200 000 → ALERT, miesiąc przekroczenia ceil(6*200000/120000)=10
    tracker.zone == "ALERT"
    tracker.breach_month == "10"
    tracker.registration_deadline == "25-11"
}

test_limit_tracker_zero_ytd {
    tracker := data.jdg.r02_vat_core_innovations.exemption_limit_tracker with input as {
        "jdg_entrepreneur": {"ytd_turnover_net": 0, "months_elapsed": 3}
    }
    tracker.zone == "OK"
    tracker.projected_annual_turnover == 0
}

# ═══ R02-INN-02: AUTO-GTU ═══

test_auto_gtu_by_category {
    gtu := data.jdg.r02_vat_core_innovations.auto_gtu with input as {
        "invoice": {"category_code": "FUEL", "description": "olej napędowy"}
    }
    gtu.assigned_gtu == "GTU_02"
}

test_auto_gtu_by_semantics {
    gtu := data.jdg.r02_vat_core_innovations.auto_gtu with input as {
        "invoice": {"category_code": "OTHER", "description": "Dostawa procesorów i kart graficznych"}
    }
    gtu.assigned_gtu == "GTU_06"
}

test_auto_gtu_intangible_default {
    gtu := data.jdg.r02_vat_core_innovations.auto_gtu with input as {
        "invoice": {"category_code": "IT_SERVICES", "description": "usługi programistyczne"}
    }
    gtu.assigned_gtu == "GTU_12"
}

test_auto_gtu_unknown_empty {
    gtu := data.jdg.r02_vat_core_innovations.auto_gtu with input as {
        "invoice": {"category_code": "UNKNOWN_CAT", "description": "dziwny towar bez dopasowania"}
    }
    gtu.assigned_gtu == ""
}

# ═══ R02-INN-03: ART. 91 KOREKTA WIELOLETNIA ═══

test_art91_period_real_estate {
    schedule := data.jdg.r02_vat_core_innovations.art91_correction_schedule with input as {
        "asset": {
            "asset_type": "REAL_ESTATE",
            "value_net": 500000,
            "deduction_factor_initial": 0.50,
            "deduction_factor_current": 1.0,
        }
    }
    schedule.period_years == 10
    schedule.direction == "IN_PLUS"
    count(schedule.schedule) == 10
    schedule.schedule[0].year_no == 1
}

test_art91_period_five_years {
    schedule := data.jdg.r02_vat_core_innovations.art91_correction_schedule with input as {
        "asset": {
            "asset_type": "MACHINERY",
            "value_net": 100000,
            "deduction_factor_initial": 1.0,
            "deduction_factor_current": 0.60,
        }
    }
    schedule.period_years == 5
    schedule.direction == "IN_MINUS"
    count(schedule.schedule) == 5
    schedule.annual_correction_pln == 40000
}

test_art91_one_off_small_asset {
    schedule := data.jdg.r02_vat_core_innovations.art91_correction_schedule with input as {
        "asset": {
            "asset_type": "EQUIPMENT",
            "value_net": 5000,
            "deduction_factor_initial": 1.0,
            "deduction_factor_current": 1.0,
        }
    }
    schedule.period_years == 1
    schedule.direction == "NONE"
    count(schedule.schedule) == 1
}

# ═══ RAPORT CORE: aktywna flaga ═══

test_vat_core_report {
    result := data.jdg.r02_vat_core_innovations.decide with input as {
        "jdg_entrepreneur": {"r02_vat_core_check": true},
        "invoice": {"category_code": "FUEL", "description": "olej napędowy"},
    }
    result.matched == true
    result.rule_id == "jdg.r02_vat_core_innovations.vat_core_report"
    result._routing == "REPORT"
    result.vat_core.exemption_limit_tracker.exemption_limit == 200000
    result.vat_core.auto_gtu.assigned_gtu == "GTU_02"
    result.vat_core.art91_correction_schedule.period_years >= 1
}
