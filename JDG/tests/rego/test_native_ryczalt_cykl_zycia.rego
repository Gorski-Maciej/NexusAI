# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: Ryczałt i Cykl Życia JDG
# Generated: 2026-08-23 | RAPORT_13_RYCZALT_CYKL_ZYCIE
# Tests: 20 | Domain: ryczałt, cykl życia, CEIDG, sukcesja, estoński CIT
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.tests.ryczalt_cykl_zycia

# ── T01: Stawka ryczałtu 17% — wolne zawody ──
test_ryczalt_a12_rate_17_freelance {
    result := jdg.micro.ryc.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "tax_form": "LUMP_SUM",
            "profession_type": "FREELANCE_DOCTOR"
        }
    }
    result.matched == true
    result.rule_id == "jdg.ryc.a12.r1"
}

# ── T02: Stawka ryczałtu 14% — IT programowanie ──
test_ryczalt_a12_rate_14_programming {
    result := jdg.micro.ryc.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "tax_form": "LUMP_SUM",
            "pkd_code": "62.01"
        }
    }
    result.matched == true
    result.rule_id == "jdg.ryc.a12.r3"
}

# ── T03: Stawka ryczałtu 8.5% — pozostałe usługi ──
test_ryczalt_a12_rate_8_5_other_services {
    result := jdg.micro.ryc.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "tax_form": "LUMP_SUM",
            "pkd_code": "70.22"
        }
    }
    result.matched == true
    result.rule_id == "jdg.ryc.a12.r6"
}

# ── T04: Stawka ryczałtu 3% — gastronomia ──
test_ryczalt_a12_rate_3_gastronomy {
    result := jdg.micro.ryc.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "tax_form": "LUMP_SUM",
            "pkd_code": "56.10"
        }
    }
    result.matched == true
    result.rule_id == "jdg.ryc.a12.r10"
}

# ── T05: Limit 2M EUR — poniżej limitu ──
test_ryczalt_a6_below_limit {
    result := jdg.micro.ryczalt.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "annual_revenue_actual": 5000000
        },
        "invoice": {}
    }
    # Reguła dopasowuje eligibility (a6.r1)
    result.matched == true
}

# ── T06: Limit 2M EUR — przekroczenie (sankcja) ──
test_ryczalt_a6_over_limit_sanction {
    result := jdg.micro.ryczalt.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "annual_revenue_actual": 20000000,
            "ryczalt_a6_violation": true
        },
        "invoice": {}
    }
    # Reguła sankcyjna a6.r12 powinna dopasować
    result.matched == true
}

# ── T07: Zawieszenie JDG — 30 dni ──
test_suspension_30_days {
    result := jdg.business.plan26_suspension_succession.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "business_status": "SUSPENDED",
            "suspension_days": 30,
            "suspension_start_date": "2026-01-01"
        }
    }
    result.matched == true
}

# ── T08: Zawieszenie JDG — max 24 miesiące ──
test_suspension_max_period {
    result := jdg.business.plan26_suspension_succession.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "business_status": "SUSPENDED",
            "suspension_days": 730,
            "max_suspension_check": true
        }
    }
    result.matched == true
}

# ── T09: Sukcesja — powołanie zarządcy ──
test_succession_manager_appointment {
    result := jdg.business.plan26_suspension_succession.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "succession_manager_appointed": true,
            "succession_appointment_date": "2026-01-15"
        }
    }
    result.matched == true
    contains(result.rule_id, "succession_manager")
}

# ── T10: Sukcesja — wygaśnięcie po 2 latach ──
test_succession_time_limit_expired {
    result := jdg.business.plan26_suspension_succession.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "succession_days_active": 731,
            "succession_time_expired": true
        }
    }
    result.matched == true
    contains(result.rule_id, "succession_time_limit")
}

# ── T11: CEIDG — rejestracja nowej JDG ──
test_ceidg_new_registration {
    result := jdg.micro.ceidg.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "ceidg_registration_required": true,
            "ceidg_status": "NEW_REGISTRATION"
        },
        "invoice": {}
    }
    result.matched == true
}

# ── T12: CEIDG — zmiana danych w 7 dni ──
test_ceidg_data_change_7_days {
    result := jdg.micro.ceidg.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "ceidg_data_changed": true,
            "ceidg_change_date": "2026-01-01",
            "ceidg_deadline_days": 7
        }
    }
    result.matched == true
}

# ── T13: Test przedsiębiorcy — JDG bezpieczna (>65 pkt) ──
test_entrepreneur_test_safe {
    result := jdg.entrepreneur_test.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "entrepreneur_test": true,
            "et_has_fixed_workplace": false,
            "et_has_fixed_hours": false,
            "et_has_direct_supervisor": false,
            "et_has_single_client": false,
            "et_client_provides_tools": false,
            "et_has_fixed_salary": false,
            "et_has_paid_leave": false,
            "et_integrated_in_team": false,
            "et_owns_tools_and_materials": true,
            "et_bears_economic_risk": true,
            "et_has_flexible_schedule": true,
            "et_client_count": 5,
            "et_is_organizationally_independent": true,
            "et_liability_to_third_parties": true,
            "et_has_subcontractors": true,
            "et_has_own_office": true
        }
    }
    result.matched == true
    result.et_score >= 65
}

# ── T14: Test przedsiębiorcy — szara strefa (35-60 pkt) ──
test_entrepreneur_test_gray_zone {
    result := jdg.entrepreneur_test.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "entrepreneur_test": true,
            "et_has_fixed_workplace": false,
            "et_has_fixed_hours": true,
            "et_has_direct_supervisor": true,
            "et_has_single_client": true,
            "et_client_provides_tools": false,
            "et_has_fixed_salary": false,
            "et_has_paid_leave": false,
            "et_integrated_in_team": false,
            "et_owns_tools_and_materials": true,
            "et_bears_economic_risk": true,
            "et_has_flexible_schedule": true,
            "et_client_count": 1,
            "et_is_organizationally_independent": true,
            "et_liability_to_third_parties": true,
            "et_has_subcontractors": false,
            "et_has_own_office": false
        }
    }
    result.matched == true
    result.et_score >= 35
    result.et_score < 65
}

# ── T15: Test przedsiębiorcy — ryzyko etatu (<35 pkt) ──
test_entrepreneur_test_employment_risk {
    result := jdg.entrepreneur_test.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "entrepreneur_test": true,
            "et_has_fixed_workplace": true,
            "et_has_fixed_hours": true,
            "et_has_direct_supervisor": true,
            "et_has_single_client": true,
            "et_client_provides_tools": true,
            "et_has_fixed_salary": true,
            "et_has_paid_leave": true,
            "et_integrated_in_team": true,
            "et_owns_tools_and_materials": false,
            "et_bears_economic_risk": false,
            "et_has_flexible_schedule": false,
            "et_client_count": 1,
            "et_is_organizationally_independent": false,
            "et_liability_to_third_parties": false,
            "et_has_subcontractors": false,
            "et_has_own_office": false
        }
    }
    result.matched == true
    result.et_score < 35
}

# ── T16: Estoński CIT — eligibility check ──
test_estonian_cit_eligibility {
    result := jdg.estonian_cit.decide with input as {
        "jdg_entrepreneur": {
            "estonian_cit_check": true,
            "legal_form": "SP_ZOO",
            "annual_revenue_actual": 5000000,
            "has_employees": true,
            "employee_count": 5,
            "months_active": 48,
            "has_krs_entry": true,
            "has_full_accounting": true,
            "has_financial_statements": true,
            "has_simple_share_structure": true,
            "passive_income_pct": 10
        }
    }
    result.matched == true
    result.rule_id == "jdg.estonian_cit.eligibility"
}

# ── T17: Estoński CIT — JDG nie kwalifikuje się ──
test_estonian_cit_jdg_not_eligible {
    result := jdg.estonian_cit.decide with input as {
        "jdg_entrepreneur": {
            "estonian_cit_check": true,
            "legal_form": "JDG",
            "annual_revenue_actual": 200000,
            "has_employees": false,
            "employee_count": 0
        }
    }
    result.matched == true
    result.estonian_cit_eligible == false
}

# ── T18: Działalność nieewidencjonowana — poniżej limitu ──
test_unregistered_activity_below_limit {
    limit_50pct := 2150  # 50% minimalnego wynagrodzenia 2026
    result := jdg.micro.pp.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "unregistered_activity": true,
            "monthly_revenue": 1500,
            "unregistered_limit": limit_50pct
        },
        "invoice": {}
    }
    result.matched == true
}

# ── T19: Działalność nieewidencjonowana — przekroczenie limitu ──
test_unregistered_activity_exceeds_limit {
    limit_50pct := 2150
    result := jdg.micro.pp.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "unregistered_activity": true,
            "monthly_revenue": 3000,
            "unregistered_limit": limit_50pct
        },
        "invoice": {}
    }
    result.matched == true
}

# ── T20: Zmiana formy opodatkowania — ryczałt → skala ──
test_tax_form_change_lump_sum_to_scale {
    result := jdg.micro.ryc.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "tax_form": "PIT_SCALE",
            "previous_tax_form": "LUMP_SUM",
            "tax_form_change_date": "2026-01-01"
        }
    }
    result.matched == true
}