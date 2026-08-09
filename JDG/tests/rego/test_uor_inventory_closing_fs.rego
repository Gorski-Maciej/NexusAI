# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: UoR Inventory + Closing + Financial Stmt
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.uor.inventory_closing_fs_test

import future.keywords.if
import data.jdg.uor.inventory
import data.jdg.uor.closing
import data.jdg.uor.financial_stmt

# ── Inventory tests ───────────────────────────────────────────────────────────

test_has_inventory if {
    result := inventory.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true, "has_inventory": true}
    }
    result.matched == true
    result.rule_id == "jdg.uor.inventory.basics.r1"
}

test_fifo_method if {
    result := inventory.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true, "inventory_method": "FIFO"}
    }
    result.matched == true
    result.rule_id == "jdg.uor.inventory.fifo.r1"
}

test_lifo_method if {
    result := inventory.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true, "inventory_method": "LIFO"}
    }
    result.matched == true
    result.rule_id == "jdg.uor.inventory.lifo.r1"
}

test_inventory_shortage if {
    result := inventory.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true, "inventory_difference": -5000}
    }
    result.matched == true
    result.rule_id == "jdg.uor.inventory.shortage.r1"
    result._routing == "TRIAGE_QUEUE"
}

test_inventory_surplus if {
    result := inventory.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true, "inventory_difference": 3000}
    }
    result.matched == true
    result.rule_id == "jdg.uor.inventory.surplus.r1"
}

test_remnant_required_for_transition if {
    result := inventory.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "transition_pkpir_to_uor": true,
            "remnant_inventory_done": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.inventory.remnant.r1"
    result._routing == "BLOCK_AND_ALERT"
}

# ── Closing tests ─────────────────────────────────────────────────────────────

test_balance_sheet_unbalanced if {
    result := closing.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_total_assets": 100000,
            "uor_total_equity_liabilities": 95000
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.closing.a45.r2"
    result._routing == "BLOCK_AND_ALERT"
}

test_balance_sheet_balanced if {
    result := closing.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_total_assets": 100000,
            "uor_total_equity_liabilities": 100000
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.closing.a45.r3"
}

test_negative_equity if {
    result := closing.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_equity": -10000
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.closing.a45.r9"
    result._routing == "TRIAGE_QUEUE"
}

test_net_profit if {
    result := closing.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_net_profit_current_year": 50000
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.closing.a47.r6"
}

test_net_loss if {
    result := closing.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "uor_net_profit_current_year": -20000
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.closing.a47.r5"
}

test_fs_not_submitted if {
    result := closing.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "fs_approved": true,
            "fs_submitted_to_krs": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.closing.procedures.r8"
    result._routing == "BLOCK_AND_ALERT"
}

# ── Financial Statement tests ─────────────────────────────────────────────────

test_balance_sheet_assets if {
    result := financial_stmt.decide with input as {
        "jdg_entrepreneur": {"uses_uor": true}
    }
    result.matched == true
    result.rule_id == "jdg.uor.financial_stmt.balance.a.r1"
}

test_rzis_comparative if {
    result := financial_stmt.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "rzis_variant": "COMPARATIVE"
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.financial_stmt.rzis.comparative.r1"
}

test_rzis_caluclation if {
    result := financial_stmt.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "rzis_variant": "CALCULATION"
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.financial_stmt.rzis.calc.r1"
}

test_opening_closing_mismatch if {
    result := financial_stmt.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "opening_balance_current_year": 50000,
            "closing_balance_previous_year": 48000
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.financial_stmt.consistency.r1"
    result._routing == "TRIAGE_QUEUE"
}
