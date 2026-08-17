# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests — P07 GLM52 ULGI + OPTYMALIZACJA
# Package: jdg.pit.missing_reliefs / jdg.pit.thermo_relief
#          jdg.pit.rd_relief / jdg.pit.ipbox / jdg.estonian_cit
# Rules tested: prototype (26eb), thermo threshold (26h),
#               BRD staff (26e), IP Box nexus (30ca), expansion (26ec),
#               robotization (26gb), estonian eligibility (28c-28t CIT)
# ═══════════════════════════════════════════════════════════════

package test_jdg_reliefs

import data.jdg.pit.missing_reliefs
import data.jdg.pit.thermo_relief
import data.jdg.pit.rd_relief
import data.jdg.pit.ipbox
import data.jdg.estonian_cit

# ── 1. PROTOTYPE (art. 26eb) — jdg.pit.missing_reliefs.prototype ──────────────
test_positive_prototype_relief {
    result := missing_reliefs.decide with input as {
        "pit_prototype_check": true,
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "prototype_trial_production_costs": 40000,
            "prototype_documentation_costs": 5000,
        }
    }
    result.matched == true
    result.rule_id == "jdg.pit.missing_reliefs.prototype"
    result.relief_type == "PROTOTYPE"
    result.relief_percent == 30
    result.relief_deductible == 13500
    result._legal_basis == "Art. 26eb PIT"
}

test_negative_prototype_relief_no_costs {
    result := missing_reliefs.decide with input as {
        "pit_prototype_check": true,
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "prototype_trial_production_costs": 0
        }
    }
    result.rule_id != "jdg.pit.missing_reliefs.prototype"
}

test_prototype_not_triggered_without_check {
    result := missing_reliefs.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "prototype_trial_production_costs": 50000
        }
    }
    result.rule_id != "jdg.pit.missing_reliefs.prototype"
}

# ── 2. THERMO (art. 26h) — próg z data.thresholds (pit_thermo_limit 53 000) ───
test_positive_thermo_aggregate_limit {
    result := thermo_relief.decide with input as {
        "thermo_relief_requested": true,
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "thermo_expenses_annual_total": 60000
        }
    }
    result.matched == true
    result.rule_id == "jdg.pit.thermo.aggregate_limit_53k"
    result.thermo_limit_pln == 53000
    result.thermo_deductible_pln == 53000
    result.thermo_excess_pln == 7000
}

test_thermo_within_limit {
    result := thermo_relief.decide with input as {
        "thermo_relief_requested": true,
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "thermo_expenses_annual_total": 20000
        }
    }
    result.rule_id == "jdg.pit.thermo.aggregate_limit_53k"
    result.thermo_deductible_pln == 20000
    result.thermo_excess_pln == 0
}

# ── 3. B+R (art. 26e) — jdg.pit.rd_relief.qualifying_staff_costs ─────────────
test_positive_brd_staff_costs {
    result := rd_relief.decide with input as {
        "jdg_entrepreneur": {
            "rd_staff_costs_qualified": 100000,
            "is_rd_center": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.pit.rd.qualifying_staff_costs"
    result.rd_deduction_pct == 1.0
    result.rd_deductible_amount == 100000
}

test_positive_brd_center_200pct {
    result := rd_relief.decide with input as {
        "jdg_entrepreneur": {
            "rd_staff_costs_qualified": 50000,
            "is_rd_center": true
        }
    }
    result.rule_id == "jdg.pit.rd.center_200pct"
    result.rd_deduction_pct == 2.0
    result.rd_deductible_amount == 100000
}

# ── 4. IP BOX (art. 30ca) — jdg.pit.ipbox.nexus_formula ──────────────────────
test_positive_ipbox_nexus {
    result := ipbox.decide with input as {
        "jdg_entrepreneur": {
            "ipbox_nexus_qualified_costs": 100000,
            "ipbox_nexus_total_costs": 130000,
            "ipbox_qualifying_income": 200000
        }
    }
    result.matched == true
    result.rule_id == "jdg.pit.ipbox.nexus_formula"
    result.ipbox_nexus_ratio == 1.0
    result.ipbox_nexus_ratio_pct == 100
}

# ── 5. EXPANSION (art. 26ec) ──────────────────────────────────────────────────
test_positive_expansion_relief {
    result := missing_reliefs.decide with input as {
        "pit_expansion_check": true,
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "expansion_trade_fairs_costs": 150000
        }
    }
    result.matched == true
    result.rule_id == "jdg.pit.missing_reliefs.expansion"
    result.relief_type == "EXPANSION"
    result.relief_limit == 1000000
    result.relief_deductible == 150000
}

# ── 6. ROBOTIZATION (art. 26gb) ───────────────────────────────────────────────
test_positive_robotization_relief {
    result := missing_reliefs.decide with input as {
        "pit_robotization_check": true,
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "robotization_purchase_costs": 200000
        }
    }
    result.matched == true
    result.rule_id == "jdg.pit.missing_reliefs.robotization"
    result.relief_type == "ROBOTIZATION"
    result.relief_percent == 50
    result.relief_deductible == 100000
}

# ── 7. ESTOŃSKI CIT (art. 28c-28t ustawy o CIT) — jdg.estonian_cit ────────────
test_positive_estonian_eligibility {
    result := estonian_cit.decide with input as {
        "jdg_entrepreneur": {
            "estonian_cit_check": true,
            "legal_form": "SP_ZOO",
            "annual_revenue_actual": 500000,
            "has_employees": true,
            "employee_count": 4,
            "has_full_accounting": true,
            "has_financial_statements": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.estonian_cit.eligibility"
    result.estonian_cit_eligible == true
}

test_estonian_no_match_empty {
    result := estonian_cit.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.estonian_cit.no_match"
}
