# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: PIT Critical Rules (P30)
# ═══════════════════════════════════════════════════════════════════════════════
# Testy natywne OPA dla plan26_pit_critical.rego
# Uruchom: opa test JDG/tests/rego/test_p30_pit_critical.rego -v
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.plan26_critical_test

import data.jdg.pit.plan26_critical

# ── Test: Tax Bracket Precision ─────────────────────────────────────────────

test_tax_bracket_below_30k if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "annual_taxable_income": 29999.00
        }
    }
    result.tax_free_degression_applied == false
    result.pit_bracket == "LOW (12%)"
}

test_tax_bracket_120k_boundary if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "annual_taxable_income": 120000.00
        }
    }
    result.pit_bracket == "LOW (12%)"
    result.pit_reducing_amount == 0
}

test_tax_bracket_120k_01_above if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "annual_taxable_income": 120000.01
        }
    }
    result.pit_bracket != "LOW (12%)"
}

# ── Test: Exit Tax ──────────────────────────────────────────────────────────

test_exit_tax_below_4m if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "has_asset_transfer_abroad": true,
            "asset_transfer_market_value": 3500000.00,
            "asset_unrealized_gains": 1000000.00
        }
    }
    result.exit_tax_applicable == false
    result._routing == ""
}

test_exit_tax_above_4m if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "has_asset_transfer_abroad": true,
            "asset_transfer_market_value": 5000000.00,
            "asset_unrealized_gains": 2000000.00
        }
    }
    result.exit_tax_applicable == true
    result._routing == "BLOCK_AND_ALERT"
}

# ── Test: NKUP Extended ─────────────────────────────────────────────────────

test_nkup_unpaid_wages_p55 if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "expense_type": "COST",
            "nkup_category": "unpaid_wages_p55",
            "amount_net": 5000.00
        }
    }
    result.nkup_blocked == true
    result.nkup_point == "55"
}

# ── Test: Rehabilitation Relief ─────────────────────────────────────────────

test_rehab_drugs if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {"has_disability_certificate": true},
        "invoice": {
            "rehab_expense_type": "REHAB_DRUGS",
            "amount_net": 3000.00
        }
    }
    result.rehab_relief_capped == true
    result.rehab_relief_amount == 2280
}

# ── Test: Innovation Reliefs ────────────────────────────────────────────────

test_prototype_relief if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "expense_type": "COST",
            "innovation_relief_type": "PROTOTYPE",
            "amount_net": 100000.00
        }
    }
    result.innovation_relief_rate > 0
}

test_robotization_relief if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "expense_type": "COST",
            "innovation_relief_type": "ROBOTIZATION",
            "amount_net": 200000.00
        }
    }
    result.innovation_relief_rate > 0
}

# ── Test: Family Relief ─────────────────────────────────────────────────────

test_family_relief_2_children if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "has_children": true,
            "children_count": 2
        }
    }
    result.family_relief_total > 0
}

# ── Test: Small Taxpayer ────────────────────────────────────────────────────

test_small_taxpayer_below if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "annual_revenue_net": 5000000.00
        }
    }
    result.small_taxpayer_status == "SMALL"
}

test_small_taxpayer_above if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "annual_revenue_net": 12000000.00
        }
    }
    result.small_taxpayer_status == "REGULAR"
}

# ── Test: CFC Aggregation ───────────────────────────────────────────────────

test_cfc_aggregation if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "has_cfc_entities": true,
            "cfc_entities": [
                {"passive_income": 50000, "foreign_tax_paid": 5000},
                {"passive_income": 30000, "foreign_tax_paid": 3000}
            ]
        }
    }
    result.cfc_entities_count == 2
}

# ── Test: Representation NKUP ───────────────────────────────────────────────

test_representation_nkup_full if {
    result := plan26_critical.decide with input as {
        "invoice": {
            "expense_type": "COST",
            "category_code": "REPRESENTATION",
            "amount_net": 30000.00
        }
    }
    result.representation_nkup_full == true
    result._routing == "BLOCK_AND_ALERT"
}

# ── Test: Tax Residency ─────────────────────────────────────────────────────

test_residency_below_183 if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "has_foreign_connections": true,
            "days_in_poland_current_year": 150
        }
    }
    result.residency_status == "NON_RESIDENT"
}

test_residency_above_183 if {
    result := plan26_critical.decide with input as {
        "jdg_entrepreneur": {
            "has_foreign_connections": true,
            "days_in_poland_current_year": 200
        }
    }
    result.residency_status == "PL_TAX_RESIDENT"
}
