# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests — ETAP 15 UoR
# Package: jdg.uor_etap15
# Coverage: obowiązek UoR, podwójny zapis, dowody, bilans, amortyzacja
#           bilansowa/podatkowa, inwentaryzacja, zamknięcie, sprawozdania,
#           przejście PKPiR→UoR, property invariants, manual approval
# ═══════════════════════════════════════════════════════════════

package test_jdg_uor_etap15

import data.jdg.uor_etap15

ctx := {
    "evaluation_datetime": "2026-08-20T00:00:00Z",
    "evaluation_year": "2026",
    "threshold_version": "v9.0.0",
    "legal_basis_version": "v9.0.0",
    "facts_version": "v9.0.0",
}

# ── 1. OBOWIĄZEK UoR (próg 2 mln EUR) ─────────────────────────
test_boundary_uor_required_above_threshold {
    result := uor_etap15.decide with input as object.union(ctx, {
        "uor_etap15_check": true,
        "uor": {"annual_revenue": 10000000},
    })
    result.obligation.uor_required == true
}

test_boundary_uor_not_required_below_threshold {
    result := uor_etap15.decide with input as object.union(ctx, {
        "uor_etap15_check": true,
        "uor": {"annual_revenue": 5000000},
    })
    result.obligation.uor_required == false
    result.obligation.early_warning == true
}

# ── 2. PODWÓJNY ZAPIS (ΣD = ΣC) ───────────────────────────────
test_balance_double_entry_balanced {
    result := uor_etap15.decide with input as object.union(ctx, {
        "uor_etap15_check": true,
        "uor": {"debits_total": 10000, "credits_total": 10000},
    })
    result.double_entry.balanced == true
    result.property_invariants.double_entry_balanced == true
}

test_negative_double_entry_unbalanced_blocks {
    result := uor_etap15.decide with input as object.union(ctx, {
        "uor_etap15_check": true,
        "uor": {"debits_total": 10000, "credits_total": 9000, "document_number": "PK/1/2026"},
    })
    result.double_entry.balanced == false
    result.routing == "BLOCK_AND_ALERT"
}

# ── 3. BILANS (aktywa = pasywa) ───────────────────────────────
test_balance_assets_equal_liabilities_plus_equity {
    result := uor_etap15.decide with input as object.union(ctx, {
        "uor_etap15_check": true,
        "uor": {"assets_total": 50000, "liabilities_total": 30000, "equity_total": 20000},
    })
    result.assets.balance_ok == true
    result.property_invariants.balance_ok == true
}

test_negative_balance_broken_goes_to_triage {
    result := uor_etap15.decide with input as object.union(ctx, {
        "uor_etap15_check": true,
        "uor": {"assets_total": 50000, "liabilities_total": 30000, "equity_total": 10000, "document_number": "BIL/1/2026"},
    })
    result.assets.balance_ok == false
    result.routing == "TRIAGE_QUEUE"
}

# ── 4. DOWODY KSIĘGOWE ────────────────────────────────────────
test_negative_missing_document_blocks {
    result := uor_etap15.decide with input as object.union(ctx, {
        "uor_etap15_check": true,
        "jdg_entrepreneur": {"uses_uor": true},
        "uor": {"document_number": ""},
    })
    result.documents.document_present == false
    result.routing == "BLOCK_AND_ALERT"
}

# ── 5. AMORTYZACJA BILANSOWA vs PODATKOWA ─────────────────────
test_property_amortization_mismatch_flagged_as_conflict {
    result := uor_etap15.decide with input as object.union(ctx, {
        "uor_etap15_check": true,
        "jdg_entrepreneur": {"uses_uor": true},
        "uor": {"amortization_balance": 1200, "amortization_tax": 1000, "document_number": "AM/1/2026"},
    })
    result.amortization.mismatch == true
    result.amortization.pit_conflict == true
}

# ── 6. INWENTARYZACJA + ZAMKNIĘCIE ────────────────────────────
test_temporal_inventory_missing_goes_to_triage {
    result := uor_etap15.decide with input as object.union(ctx, {
        "uor_etap15_check": true,
        "uor": {"inventory_due": true, "inventory_done": false, "document_number": "INW/1/2026"},
    })
    result.inventory.inventory_missing == true
    result.routing == "TRIAGE_QUEUE"
}

test_boundary_closing_complete_at_12_steps {
    result := uor_etap15.decide with input as object.union(ctx, {
        "uor_etap15_check": true,
        "uor": {"closing_steps_done": 12, "document_number": "ZAM/1/2026"},
    })
    result.closing.closing_complete == true
}

# ── 7. SPRAWOZDANIA — MANUAL APPROVAL ─────────────────────────
test_property_financial_stmt_requires_manual_approval {
    result := uor_etap15.decide with input as object.union(ctx, {
        "uor_etap15_check": true,
        "uor": {"financial_stmt_prepared": true, "financial_stmt_approved": false, "document_number": "SF/1/2026"},
    })
    result.financial_stmt.requires_manual_approval == true
    result.property_invariants.no_auto_fs_approval == true
    result.routing == "TRIAGE_QUEUE"
}

# ── 8. PRZEJŚCIE PKPiR→UoR ────────────────────────────────────
test_balance_transition_opening_equals_closing {
    result := uor_etap15.decide with input as object.union(ctx, {
        "uor_etap15_check": true,
        "uor": {"opening_balance_pln": 40000, "pkpir_closing_balance": 40000, "transition_idempotency_key": "MIG/2026/1", "document_number": "MIG/1/2026"},
    })
    result.transition.balanced == true
    result.property_invariants.transition_balanced == true
}

test_negative_transition_duplicate_detected {
    result := uor_etap15.decide with input as object.union(ctx, {
        "uor_etap15_check": true,
        "uor": {"transition_already_posted": true, "transition_idempotency_key": "MIG/2026/1", "document_number": "MIG/1/2026"},
    })
    result.transition.duplicate_detected == true
    result.routing == "TRIAGE_QUEUE"
}

# ── 9. POZORNE COMPLETE ───────────────────────────────────────
test_negative_fake_complete_detected {
    result := uor_etap15.decide with input as object.union(ctx, {
        "uor_etap15_check": true,
        "uor": {"declared_complete_articles": ["a2", "a26"], "article_atom_count": {"a2": 8, "a26": 0}, "document_number": "COV/1/2026"},
    })
    result.coverage.fake_complete_detected == true
    result.routing == "TRIAGE_QUEUE"
}

# ── 10. NO_MATCH (default — brak flagi) ───────────────────────
test_no_match_without_activation_flag {
    result := uor_etap15.decide with input as object.union(ctx, {})
    result.matched == false
    result.rule_id == "jdg.uor_etap15.no_match"
}
