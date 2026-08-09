# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: UoR Obligation Package (opa test)
# Package: jdg.uor.obligation
# Generated: 2026-08-02 — Q3 Critical Closure (P28 Grand Finale)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.uor.obligation_test

import future.keywords.if
import data.jdg.uor.obligation

# ── Art. 2 tests ──────────────────────────────────────────────────────────────

test_over_2m_eur_threshold if {
    result := obligation.decide with input as {
        "jdg_entrepreneur": {
            "annual_revenue_actual": 11000000,
            "eur_pln_rate": 4.5,
            "uses_uor": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.obligation.a2.r1"
    result._routing == "BLOCK_AND_ALERT"
}

test_under_2m_eur_pkpir_allowed if {
    result := obligation.decide with input as {
        "jdg_entrepreneur": {
            "annual_revenue_actual": 5000000,
            "eur_pln_rate": 4.5,
            "uses_uor": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.obligation.a2.r2"
    result.pkpir_allowed == true
}

test_voluntary_uor_choice if {
    result := obligation.decide with input as {
        "jdg_entrepreneur": {
            "annual_revenue_actual": 1000000,
            "eur_pln_rate": 4.5,
            "uor_voluntary_choice": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.obligation.a2.r3"
}

test_capital_group_mandatory if {
    result := obligation.decide with input as {
        "jdg_entrepreneur": {
            "in_capital_group": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.obligation.a2.r4"
    result._routing == "BLOCK_AND_ALERT"
}

# ── Art. 4 tests ──────────────────────────────────────────────────────────────

test_accrual_principle_violation if {
    result := obligation.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_uses_cash_method": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.obligation.a4.r1"
    result._routing == "TRIAGE_QUEUE"
}

test_prudence_violation if {
    result := obligation.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_assets_overstated": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.obligation.a4.r3"
    result._routing == "BLOCK_AND_ALERT"
}

test_continuity_threatened if {
    result := obligation.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "business_status": "SUSPENDED",
            "annual_revenue_actual": 0
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.obligation.a4.r4"
}

# ── Art. 5 tests ──────────────────────────────────────────────────────────────

test_true_and_fair_view if {
    result := obligation.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.obligation.a5.r1"
}

test_true_fair_view_violation if {
    result := obligation.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_material_misstatement": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.obligation.a5.r2"
    result._routing == "BLOCK_AND_ALERT"
}

# ── Art. 10 tests ─────────────────────────────────────────────────────────────

test_missing_accounting_policy if {
    result := obligation.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_accounting_policy_exists": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.obligation.a10.r1"
    result._routing == "BLOCK_AND_ALERT"
}

test_audit_mandatory if {
    result := obligation.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_total_assets_pln": 13000000,
            "annual_revenue_actual": 25000000,
            "avg_employees_year": 55,
            "eur_pln_rate": 4.5
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.obligation.a2.r10"
    result.audit_mandatory == true
}

# ── Negative tests ────────────────────────────────────────────────────────────

test_no_match_default if {
    result := obligation.decide with input as {
        "jdg_entrepreneur": {}
    }
    result.matched == false
    result.rule_id == "jdg.uor.obligation.no_match"
}
