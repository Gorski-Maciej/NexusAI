# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — V3-P27 Native Tests: exit_tax_mdr_enterprise (Rego v0)
# OPA 0.68 + OPA 1.9 (--v0-compatible). Fail-closed: no_match bez wyzwalaczy.
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_exit_tax_mdr

import data.jdg.exit_tax_mdr

# ── ET-001: exit tax — przeniesienie aktywów za granicę ───────────────────────
test_exit_tax_transfer_abroad {
    result := data.jdg.exit_tax_mdr.decide with input as {
        "exit_tax_check": true,
        "invoice": {"is_transfer_abroad": true, "asset_fair_market_value": 6000000,
                    "asset_tax_basis_pl": 4000000, "description": "maszyny produkcyjne"},
        "vendor": {"country": "DE"},
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.rule_id == "jdg.exit_tax.asset_transfer_abroad_detected"
    result.exit_tax_applies == true
    result.exit_tax_unrealized_gain == 2000000
    result.exit_tax_estimated_pln == 380000
    result.exit_tax_deferral_possible == true
    result._routing == "BLOCK_AND_ALERT"
}

test_exit_tax_non_eu_no_deferral {
    result := data.jdg.exit_tax_mdr.decide with input as {
        "exit_tax_check": true,
        "invoice": {"is_transfer_abroad": true, "asset_fair_market_value": 1000000,
                    "asset_tax_basis_pl": 300000},
        "vendor": {"country": "US"},
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.rule_id == "jdg.exit_tax.asset_transfer_abroad_detected"
    result.exit_tax_deferral_possible == false
}

test_exit_tax_not_triggered_without_flag {
    result := data.jdg.exit_tax_mdr.decide with input as {
        "invoice": {"is_transfer_abroad": true, "asset_fair_market_value": 6000000}
    }
    result.rule_id == "jdg.exit_tax_mdr.no_match"
    result.matched == false
}

# ── CFC-001: zagraniczna spółka kontrolowana ──────────────────────────────────
test_cfc_detected {
    result := data.jdg.exit_tax_mdr.decide with input as {
        "cfc_check": true,
        "jdg_entrepreneur": {"cfc_company_name": "Test sp. z o.o. (CY)", "cfc_country": "CY",
                             "cfc_ownership_pct": 0.75, "cfc_passive_income_pct": 0.60,
                             "cfc_total_income_pln": 500000}
    }
    result.rule_id == "jdg.exit_tax.cfc_foreign_company_detected"
    result.cfc_detected == true
    result.cfc_estimated_cfc_income_pln == 375000
    result._routing == "BLOCK_AND_ALERT"
}

test_cfc_not_triggered_low_passive {
    # Próg pasywny 33% nieosiągnięty → gałąź CFC nie pali się (fail-closed)
    result := data.jdg.exit_tax_mdr.decide with input as {
        "cfc_check": true,
        "jdg_entrepreneur": {"cfc_ownership_pct": 0.75, "cfc_passive_income_pct": 0.20,
                             "cfc_total_income_pln": 500000}
    }
    result.rule_id != "jdg.exit_tax.cfc_foreign_company_detected"
}

# ── MDR-001: schemat podatkowy (DAC6) ─────────────────────────────────────────
test_mdr_scheme_detected {
    result := data.jdg.exit_tax_mdr.decide with input as {
        "mdr_check": true,
        "invoice": {"mdr_hallmark": "C_CROSS_BORDER", "mdr_scheme_description": "Transakcja z ENO"}
    }
    result.rule_id == "jdg.exit_tax.mdr_scheme_detected"
    result.mdr_reportable == true
    result.mdr_hallmark_category == "C_CROSS_BORDER"
    result._routing == "BLOCK_AND_ALERT"
}

# ── TP-001: ceny transferowe ──────────────────────────────────────────────────
test_tp_documentation_required {
    result := data.jdg.exit_tax_mdr.decide with input as {
        "tp_check": true,
        "vendor": {"name": "Powiązany GmbH", "is_related_party": true},
        "invoice": {"amount_net": 3000000}
    }
    result.rule_id == "jdg.exit_tax.transfer_pricing_obligation"
    result.tp_documentation_required == true
    result._routing == "BLOCK_AND_ALERT"
}

test_tp_below_threshold_triage {
    result := data.jdg.exit_tax_mdr.decide with input as {
        "tp_check": true,
        "vendor": {"name": "Powiązany SRL", "is_related_party": true},
        "invoice": {"amount_net": 700000}
    }
    result.rule_id == "jdg.exit_tax.transfer_pricing_obligation"
    result.tp_documentation_required == false
    result._routing == "TRIAGE_QUEUE"
}

# ── CIT-EST: estoński CIT vs PIT ──────────────────────────────────────────────
test_estonian_cit_analysis {
    result := data.jdg.exit_tax_mdr.decide with input as {
        "estonian_cit_analysis": true,
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE", "annual_profit_actual": 200000,
                             "annual_revenue_actual": 500000, "reinvests_profits": true,
                             "employee_count": 3}
    }
    result.rule_id == "jdg.exit_tax.estonian_cit_vs_pit_analysis"
    result.estonian_cit_available == true
    result._routing == "TRIAGE_QUEUE"
}

# ── INT-001: UPO ──────────────────────────────────────────────────────────────
test_treaty_analyzer {
    result := data.jdg.exit_tax_mdr.decide with input as {
        "international_tax_treaty_check": true,
        "jdg_entrepreneur": {"foreign_income_country": "DE", "foreign_income_pln": 100000,
                             "foreign_tax_paid_pln": 30000, "tax_form": "PIT_SCALE"}
    }
    result.rule_id == "jdg.exit_tax.double_tax_treaty_analyzer"
    result.tax_treaty_polish_tax_before_relief == 12000
    result.tax_treaty_relief_amount == 12000
    result.tax_treaty_polish_tax_after_relief == 0
}

# ── AGGREGATE: cross-border risk ──────────────────────────────────────────────
test_cross_border_risk_summary {
    result := data.jdg.exit_tax_mdr.decide with input as {
        "cross_border_risk_summary": true,
        "jdg_entrepreneur": {"exit_tax_active": true, "cfc_active": true, "mdr_active": true}
    }
    result.rule_id == "jdg.exit_tax.cross_border_risk_summary"
    count(result.cross_border_active_flags) == 3
    result.cross_border_total_risk_score == 60
    # 3+ aktywne flagi → BLOCK_AND_ALERT (cross_border_routing_for)
    result._routing == "BLOCK_AND_ALERT"
}

# ── Fail-closed: pusty input → no_match ───────────────────────────────────────
test_no_match_empty_input {
    result := data.jdg.exit_tax_mdr.decide with input as {}
    result.rule_id == "jdg.exit_tax_mdr.no_match"
    result.matched == false
}
