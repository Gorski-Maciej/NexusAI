# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: ppk_pfron_enterprise
# Rewritten 2026-09-06: behavioral tests po naprawie Rego v0
# (łańcuch else decide + helpery poza łańcuchem + snapshot progów ADR-002)
# Package: jdg.ppk_pfron
# ═══════════════════════════════════════════════════════════════

package test_jdg_ppk_pfron

import data.jdg.ppk_pfron

# ── 1. no_match: brak zatrudnienia → default decide ──────────────
test_no_match_empty_input {
    result := data.jdg.ppk_pfron.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.ppk_pfron.no_match"
}

# FGŚP dotyczy KAŻDEGO pracodawcy (brak flagi wyzwalającej — obowiązek ustawowy),
# więc zatrudnienie bez innych wyzwalaczy → fgsp_contribution (nie no_match).
test_fgsp_fires_for_any_employer {
    result := data.jdg.ppk_pfron.decide with input as {
        "employment": {"has_employees": true, "employee_count": 5}
    }
    result.rule_id == "jdg.ppk_pfron.fgsp_contribution"
    result.fgsp_monthly_pln == 20.0
}

# ── 2. PPK-1650: enrollment check ────────────────────────────────
test_ppk_enrollment_triage {
    result := data.jdg.ppk_pfron.decide with input as {
        "ppk_check_requested": true,
        "employment": {
            "has_employees": true,
            "employee_count": 12,
            "employees_age_18_55": 10,
            "ppk_enrolled_count": 3
        }
    }
    result.matched == true
    result.rule_id == "jdg.ppk_pfron.ppk_enrollment_check"
    result.ppk_obligated == true
    result._routing == "TRIAGE_QUEUE"
    result.ppk_auto_enrollment_date == "2027-01-01"
}

test_ppk_enrollment_all_enrolled_ok {
    result := data.jdg.ppk_pfron.decide with input as {
        "ppk_check_requested": true,
        "employment": {
            "has_employees": true,
            "employee_count": 4,
            "employees_age_18_55": 4,
            "ppk_enrolled_count": 4
        }
    }
    result.rule_id == "jdg.ppk_pfron.ppk_enrollment_check"
    result._routing == ""
    result.ppk_obligated == true
}

test_ppk_enrollment_ppe_exempts {
    result := data.jdg.ppk_pfron.decide with input as {
        "ppk_check_requested": true,
        "employment": {
            "has_employees": true,
            "employee_count": 12,
            "employees_age_18_55": 10,
            "ppk_enrolled_count": 0,
            "has_ppe": true
        }
    }
    result.rule_id == "jdg.ppk_pfron.ppk_enrollment_check"
    result.ppk_obligated == false
    result._routing == ""
}

# ── 3. PPK-1655: contribution calculation ────────────────────────
test_ppk_contribution_basic {
    result := data.jdg.ppk_pfron.decide with input as {
        "ppk_calculate_contributions": true,
        "employment": {
            "has_employees": true,
            "ppk_enrolled_count": 5,
            "monthly_payroll_gross": 20000
        }
    }
    result.rule_id == "jdg.ppk_pfron.ppk_contribution_calculation"
    result.ppk_employer_total_monthly == 300.0
    result.ppk_employee_total_monthly == 400.0
    result.ppk_monthly_kup_pln == 300.0
    result.ppk_annual_state_subsidy_pln == 1200.0
}

# ── 4. PFRON-1660: obligation check ──────────────────────────────
test_pfron_obligation_triage {
    result := data.jdg.ppk_pfron.decide with input as {
        "pfron_check_requested": true,
        "employment": {
            "has_employees": true,
            "employee_count": 30,
            "disabled_employee_count": 1,
            "is_zpchr": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.ppk_pfron.pfron_obligation_check"
    result.pfron_required == true
    result._routing == "TRIAGE_QUEUE"
    result.pfron_disabled_employed == 1
    result.pfron_monthly_amount_pln == 3699.15
}

test_pfron_no_obligation_small_firm {
    result := data.jdg.ppk_pfron.decide with input as {
        "pfron_check_requested": true,
        "employment": {
            "has_employees": true,
            "employee_count": 10,
            "disabled_employee_count": 0,
            "is_zpchr": false
        }
    }
    result.rule_id == "jdg.ppk_pfron.pfron_obligation_check"
    result.pfron_required == false
    result._routing == ""
}

test_pfron_zpchr_exempt {
    result := data.jdg.ppk_pfron.decide with input as {
        "pfron_check_requested": true,
        "employment": {
            "has_employees": true,
            "employee_count": 30,
            "disabled_employee_count": 1,
            "is_zpchr": true
        }
    }
    result.rule_id == "jdg.ppk_pfron.pfron_obligation_check"
    result.pfron_required == false
    result._routing == ""
}

# ── 5. FGSP-1670 ─────────────────────────────────────────────────
test_fgsp_contribution {
    result := data.jdg.ppk_pfron.decide with input as {
        "employment": {"has_employees": true, "monthly_payroll_gross": 20000}
    }
    result.rule_id == "jdg.ppk_pfron.fgsp_contribution"
    result.fgsp_rate_pct == 0.10
    result.fgsp_monthly_pln == 20.0
    result.fgsp_annual_pln == 240.0
}

# ── 6. ZFŚS-1675 ─────────────────────────────────────────────────
test_zfss_required_50plus {
    result := data.jdg.ppk_pfron.decide with input as {
        "zfss_check_requested": true,
        "employment": {"has_employees": true, "employee_count": 60}
    }
    result.rule_id == "jdg.ppk_pfron.zfss_obligation"
    result.zfss_required == true
    result._routing == "TRIAGE_QUEUE"
    result.zfss_annual_budget_pln == 204750.0
}

test_zfss_not_required_below_50 {
    result := data.jdg.ppk_pfron.decide with input as {
        "zfss_check_requested": true,
        "employment": {"has_employees": true, "employee_count": 30}
    }
    result.rule_id == "jdg.ppk_pfron.zfss_obligation"
    result.zfss_required == false
    result._routing == ""
}

# ── 7. PPK-1680: employer total cost summary ─────────────────────
test_employer_total_cost_summary {
    result := data.jdg.ppk_pfron.decide with input as {
        "employer_cost_summary": true,
        "employment": {
            "has_employees": true,
            "zus_employer_monthly": 1000,
            "ppk_employer_monthly": 100,
            "pfron_monthly": 50,
            "fgsp_monthly": 20
        }
    }
    result.rule_id == "jdg.ppk_pfron.employer_total_cost_summary"
    result.employer_total_monthly_cost == 1170.0
}

test_employer_cost_precedence_over_fgsp {
    result := data.jdg.ppk_pfron.decide with input as {
        "employer_cost_summary": true,
        "employment": {"has_employees": true, "zus_employer_monthly": 500}
    }
    result.rule_id == "jdg.ppk_pfron.employer_total_cost_summary"
    result.employer_total_monthly_cost == 500.0
}
