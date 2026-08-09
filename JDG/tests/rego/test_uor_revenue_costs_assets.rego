# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: UoR Revenue + Costs + Assets
# Packages: jdg.uor.revenue, jdg.uor.costs, jdg.uor.assets
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.uor.revenue_costs_assets_test

import future.keywords.if
import data.jdg.uor.revenue
import data.jdg.uor.costs
import data.jdg.uor.assets

# ── Revenue tests ─────────────────────────────────────────────────────────────

test_revenue_net_of_vat if {
    result := revenue.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {"is_revenue": true}
    }
    result.matched == true
    result.rule_id == "jdg.uor.revenue.a28.r1"
}

test_revenue_goods if {
    result := revenue.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {"revenue_type": "GOODS"}
    }
    result.matched == true
    result.rule_id == "jdg.uor.revenue.sales.goods.r1"
}

test_revenue_services if {
    result := revenue.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {"revenue_type": "SERVICES"}
    }
    result.matched == true
    result.rule_id == "jdg.uor.revenue.sales.services.r1"
}

test_revenue_accrual if {
    result := revenue.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {"is_revenue": true, "delivery_date": "2026-07-15"}
    }
    result.matched == true
    result.rule_id == "jdg.uor.revenue.timing.delivery.r1"
}

test_cash_basis_violation if {
    result := revenue.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_uses_cash_method": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.revenue.timing.cash_basis.r1"
    result._routing == "TRIAGE_QUEUE"
}

# ── Costs tests ───────────────────────────────────────────────────────────────

test_depreciation_cost if {
    result := costs.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {"expense_type": "DEPRECIATION"}
    }
    result.matched == true
    result.rule_id == "jdg.uor.costs.depreciation.r1"
}

test_materials_cost if {
    result := costs.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {"cost_type": "MATERIALS"}
    }
    result.matched == true
    result.rule_id == "jdg.uor.costs.materials.r1"
}

test_salaries_cost if {
    result := costs.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {"cost_type": "SALARIES"}
    }
    result.matched == true
    result.rule_id == "jdg.uor.costs.salaries.r1"
}

test_nkup_warning if {
    result := costs.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {"is_nkup": true}
    }
    result.matched == true
    result.rule_id == "jdg.uor.costs.nkup.r1"
}

test_representation_cost if {
    result := costs.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {"expense_type": "REPRESENTATION"}
    }
    result.matched == true
    result.rule_id == "jdg.uor.costs.representation.r1"
    result._routing == "WARNING"
}

# ── Assets tests ──────────────────────────────────────────────────────────────

test_fixed_asset_valuation if {
    result := assets.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {"expense_type": "FIXED_ASSET"}
    }
    result.matched == true
    result.rule_id == "jdg.uor.assets.a28b.r1"
}

test_asset_no_depreciation if {
    result := assets.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {
            "expense_type": "FIXED_ASSET",
            "asset_age_months": 3,
            "depreciation_booked": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.assets.a28b.r4"
    result._routing == "WARNING"
}

test_intangible_asset if {
    result := assets.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {"asset_type": "INTANGIBLE"}
    }
    result.matched == true
    result.rule_id == "jdg.uor.assets.a28c.r1"
}

test_receivable_overdue_180 if {
    result := assets.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {
            "is_receivable": true,
            "payment_overdue_days": 200,
            "receivable_impairment_booked": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.assets.a28d.r2"
    result._routing == "WARNING"
}

test_kst_group7_car if {
    result := assets.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {"kst_group": 7}
    }
    result.matched == true
    result.rule_id == "jdg.uor.assets.kst.group7.r1"
    result.depreciation_rate == 20.0
}

test_kst_group0_no_depreciation if {
    result := assets.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true},
        "invoice": {"kst_group": 0}
    }
    result.matched == true
    result.rule_id == "jdg.uor.assets.kst.group0.r1"
    result.depreciation_rate == 0.00
}
