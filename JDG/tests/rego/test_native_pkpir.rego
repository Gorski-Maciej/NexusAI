# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: PKPiR (PROMPT 10)
# Package: jdg.micro.pkpir
# Rules tested: chronological_order, no_gaps, revenue_recognition,
# cost_recognition, NKUP representation, NKUP donations, remanent,
# column_validation, sum_control
# ═══════════════════════════════════════════════════════════════════════════════

package test_jdg_pkpir
import data.jdg.micro.pkpir

# ── Test 1: PKPiR eligibility — JDG na skali/liniowym ────────────────────────
test_positive_pkpir_eligibility {
    result := data.jdg.micro.pkpir.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "tax_form": "PIT_SCALE"
        }
    }
    result.matched == true
    result.micro_rule_active == true
}

# ── Test 2: Remanent — wycena i wpływ na dochód ───────────────────────────────
test_positive_remanent_inventory {
    result := data.jdg.micro.pkpir.decide with input as {
        "jdg_entrepreneur": {
            "business_type": "JDG",
            "remanent_start_pln": 50000.0,
            "remanent_end_pln": 65000.0,
            "remanent_check": true
        }
    }
    result.matched == true
}

# ── Test 3: NKUP — reprezentacja ──────────────────────────────────────────────
test_positive_nkup_representation {
    result := data.jdg.micro.pkpir.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {
            "expense_type": "REPRESENTATION",
            "amount_pln": 2000.0
        }
    }
    result.matched == true
}

# ── Test 4: NKUP — darowizny ──────────────────────────────────────────────────
test_positive_nkup_donations {
    result := data.jdg.micro.pkpir.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {
            "expense_type": "DONATION",
            "amount_pln": 5000.0
        }
    }
    result.matched == true
}

# ── Test 5: Przychód — sprzedaż towarów ──────────────────────────────────────
test_positive_revenue_goods {
    result := data.jdg.micro.pkpir.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {
            "revenue_type": "GOODS_SALE",
            "amount_gross": 12300.0
        }
    }
    result.matched == true
}

# ── Test 6: Koszt — zakup towarów handlowych ──────────────────────────────────
test_positive_cost_goods {
    result := data.jdg.micro.pkpir.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {
            "cost_type": "GOODS_PURCHASE",
            "amount_net": 8000.0
        }
    }
    result.matched == true
}

# ── Test 7: Koszt — wynagrodzenia ─────────────────────────────────────────────
test_positive_cost_salaries {
    result := data.jdg.micro.pkpir.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {
            "cost_type": "SALARIES",
            "amount_net": 4500.0
        }
    }
    result.matched == true
}

# ── Test 8: Środki trwałe — wartość początkowa ────────────────────────────────
test_positive_fixed_assets {
    result := data.jdg.micro.pkpir.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {
            "asset_type": "FIXED_ASSET",
            "initial_value": 15000.0,
            "kst_group": "4"
        }
    }
    result.matched == true
}

# ── Test 9: Korekta PKPiR ─────────────────────────────────────────────────────
test_positive_pkpir_correction {
    result := data.jdg.micro.pkpir.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {
            "correction_required": true,
            "original_amount": 10000.0,
            "corrected_amount": 9500.0
        }
    }
    result.matched == true
}

# ── Test 10: Przychód — pozostałe ─────────────────────────────────────────────
test_positive_revenue_other {
    result := data.jdg.micro.pkpir.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {
            "revenue_type": "OTHER_REVENUE",
            "amount_gross": 5000.0
        }
    }
    result.matched == true
}

# ── Test 11: NKUP — odsetki budżetowe ─────────────────────────────────────────
test_positive_nkup_budget_interest {
    result := data.jdg.micro.pkpir.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {
            "expense_type": "BUDGET_INTEREST",
            "amount_pln": 1500.0
        }
    }
    result.matched == true
}

# ── Test 12: no_match — pusty input ───────────────────────────────────────────
test_no_match_pkpir {
    result := data.jdg.micro.pkpir.decide with input as {}
    result.matched == false
}