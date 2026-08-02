# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: UoR Books Package (opa test)
# Package: jdg.uor.books — P28 Grand Finale
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.uor.books_test

import data.jdg.uor.books

# ── Art. 11 tests ─────────────────────────────────────────────────────────────

test_books_not_opened if {
    result := books.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "books_opened": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.books.a11.r1"
    result._routing == "BLOCK_AND_ALERT"
}

test_opening_balance_sheet if {
    result := books.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "opening_assets": 100000,
            "opening_equity_liabilities": 100000
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.books.a11.r2"
}

test_unbalanced_opening if {
    result := books.decide with input as {
        "jdg_entrepreneur": {
            "opening_assets": 100000,
            "opening_equity_liabilities": 90000
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.books.a11.r3"
    result._routing == "BLOCK_AND_ALERT"
}

# ── Art. 12-13 tests ──────────────────────────────────────────────────────────

test_books_not_closed_year_end if {
    result := books.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "books_closed": false
        },
        "invoice": {
            "is_year_end": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.books.a12.r1"
    result._routing == "BLOCK_AND_ALERT"
}

test_cannot_modify_after_final_close if {
    result := books.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "books_finally_closed": true
        },
        "invoice": {
            "attempt_modification_after_close": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.books.a13.r1"
    result._routing == "BLOCK_AND_ALERT"
}

test_fs_not_approved if {
    result := books.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "fs_approved": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.books.a13.r2"
    result._routing == "BLOCK_AND_ALERT"
}

test_books_closed_and_approved if {
    result := books.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "books_closed": true,
            "fs_approved": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.books.a13.r3"
}

# ── Art. 17 tests ─────────────────────────────────────────────────────────────

test_journal_missing if {
    result := books.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true,
            "journal_exists": false,
            "general_ledger_exists": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.books.a17.r1"
    result._routing == "BLOCK_AND_ALERT"
}

test_double_entry_violation if {
    result := books.decide with input as {
        "jdg_entrepreneur": {
            "uses_uor": true
        },
        "invoice": {
            "journal_debit_total": 1000,
            "journal_credit_total": 500
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.books.a23.r1"
    result._routing == "BLOCK_AND_ALERT"
}

test_double_entry_ok if {
    result := books.decide with input as {
        "invoice": {
            "journal_debit_total": 1000,
            "journal_credit_total": 1000
        }
    }
    result.matched == true
    result.rule_id == "jdg.uor.books.a23.r2"
}

test_no_match if {
    result := books.decide with input as {
        "jdg_entrepreneur": {}
    }
    result.matched == false
    result.rule_id == "jdg.uor.books.no_match"
}
