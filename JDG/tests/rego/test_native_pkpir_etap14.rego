# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests — ETAP 14 PKPiR
# Package: jdg.pkpir_etap14
# Coverage: evidence pack, kolumny/numeracja/chronologia, moment,
#           NKUP/pojazdy/leasing/wynagrodzenia, remanent/storno/korekty,
#           uzgodnienie 3-stronne, idempotencja, blokada AUTO_POST
# ═══════════════════════════════════════════════════════════════

package test_jdg_pkpir_etap14

import data.jdg.pkpir_etap14

ctx := {
    "evaluation_datetime": "2026-08-20T00:00:00Z",
    "evaluation_year": "2026",
    "threshold_version": "v9.0.0",
    "legal_basis_version": "v9.0.0",
    "facts_version": "v9.0.0",
}

# ── 1. EVIDENCE PACK ───────────────────────────────────────────
test_positive_evidence_pack_present {
    result := pkpir_etap14.decide with input as object.union(ctx, {"pkpir_etap14_check": true})
    result.matched == true
    result.evidence_pack.count == 13
}

test_property_evidence_pack_has_document_and_source_rule {
    result := pkpir_etap14.decide with input as object.union(ctx, {"pkpir_etap14_check": true})
    result.evidence_pack.entries[0].required_document != ""
    result.evidence_pack.entries[0].source_rule != ""
    result.evidence_pack.entries[0].decision != ""
}

# ── 2. KOLUMNY / NUMERACJA / CHRONOLOGIA ───────────────────────
test_boundary_columns_complete_at_17 {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "jdg_entrepreneur": {"uses_pkpir": true},
        "pkpir": {"column_count": 17, "document_number": "FV/1/2026", "event_date": "2026-03-01", "entry_date": "2026-03-10"},
    })
    result.columns.columns_complete == true
    result.columns.document_present == true
}

test_negative_missing_columns_blocks {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "jdg_entrepreneur": {"uses_pkpir": true},
        "pkpir": {"column_count": 10, "document_number": "FV/1/2026"},
    })
    result.columns.columns_complete == false
    result.routing == "BLOCK_AND_ALERT"
}

test_temporal_chronology_ok_when_entry_after_event {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "jdg_entrepreneur": {"uses_pkpir": true},
        "pkpir": {"column_count": 17, "document_number": "FV/1/2026", "event_date": "2026-03-01", "entry_date": "2026-03-10"},
    })
    result.columns.chronology_ok == true
}

test_negative_chronology_broken_goes_to_triage {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "jdg_entrepreneur": {"uses_pkpir": true},
        "pkpir": {"column_count": 17, "document_number": "FV/1/2026", "event_date": "2026-03-10", "entry_date": "2026-03-01"},
    })
    result.columns.chronology_ok == false
    result.routing == "TRIAGE_QUEUE"
}

# ── 3. MOMENT PRZYCHODU / KOSZTU (kasowy) ─────────────────────
test_temporal_revenue_cash_receipt {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "pkpir": {"direction": "SALE", "amount": 1000, "cash_received": true, "document_number": "FV/1/2026", "column_count": 17},
    })
    result.moment.revenue_moment == "CASH_RECEIPT"
}

test_temporal_cost_cash_paid {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "pkpir": {"direction": "PURCHASE", "amount": 500, "cash_paid": true, "document_number": "FV/2/2026", "column_count": 17},
    })
    result.moment.cost_moment == "CASH_PAID"
}

# ── 4. NKUP / POJAZDY / LEASING / WYNAGRODZENIA ────────────────
test_boundary_vehicle_over_limit {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "pkpir": {"vehicle_value": 200000, "vehicle_electric": false, "document_number": "FV/3/2026", "column_count": 17},
    })
    result.deductions.vehicle_limit == 150000
    result.deductions.vehicle_over_limit == true
}

test_boundary_electric_vehicle_limit_225k {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "pkpir": {"vehicle_value": 200000, "vehicle_electric": true, "document_number": "FV/4/2026", "column_count": 17},
    })
    result.deductions.vehicle_limit == 225000
    result.deductions.vehicle_over_limit == false
}

test_positive_leasing_operational_vs_financial {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "pkpir": {"leasing_type": "OPERATIONAL", "document_number": "UM/1/2026", "column_count": 17},
    })
    result.deductions.leasing_operational_full_installment == true
    result.deductions.leasing_financial_interest_only == false
}

# ── 5. REMANENT / STORNO / KOREKTY ─────────────────────────────
test_positive_storno_is_negative_reversal {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "pkpir": {"storno": true, "amount": -300, "document_number": "ST/1/2026", "column_count": 17},
    })
    result.adjustments.storno == true
    result.property_invariants.storno_negative == true
}

test_property_correction_requires_reason {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "pkpir": {"correction": true, "correction_reason": "", "document_number": "KOR/1/2026", "column_count": 17},
    })
    result.property_invariants.correction_reason == false
}

# ── 6. TRZYSTRONNE UZGODNIENIE PKPiR↔VAT↔bank ─────────────────
test_positive_reconciliation_balanced {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "pkpir": {"revenue_total": 10000, "cost_total": 4000, "document_number": "UZG/1/2026", "column_count": 17},
        "vat": {"sales_total": 10000, "purchase_total": 4000},
        "bank": {"inflows": 10000, "outflows": 4000},
    })
    result.reconciliation.balanced == true
}

test_negative_reconciliation_unbalanced_goes_to_triage {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "pkpir": {"revenue_total": 10000, "cost_total": 4000, "document_number": "UZG/2/2026", "column_count": 17},
        "vat": {"sales_total": 9000, "purchase_total": 4000},
        "bank": {"inflows": 10000, "outflows": 4000},
    })
    result.reconciliation.balanced == false
    result.routing == "TRIAGE_QUEUE"
}

# ── 7. IDEMPOTENCJA + BLOKADA AUTO_POST ────────────────────────
test_negative_duplicate_detected_blocks_auto_post {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "pkpir": {"already_posted": true, "idempotency_key": "FV/1/2026:1000:2026-03-01", "document_number": "FV/1/2026", "column_count": 17},
    })
    result.idempotency.duplicate_detected == true
    result.auto_post_allowed == false
    result.routing == "BLOCK_AND_ALERT"
}

test_negative_missing_document_blocks_auto_post {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "jdg_entrepreneur": {"uses_pkpir": true},
        "pkpir": {"column_count": 17, "document_number": ""},
    })
    result.columns.document_present == false
    result.auto_post_allowed == false
    result.routing == "BLOCK_AND_ALERT"
}

test_positive_auto_post_allowed_for_complete_input {
    result := pkpir_etap14.decide with input as object.union(ctx, {
        "pkpir_etap14_check": true,
        "pkpir": {"column_count": 17, "document_number": "FV/1/2026", "event_date": "2026-03-01", "entry_date": "2026-03-10", "direction": "SALE", "amount": 1000, "cash_received": true},
    })
    result.auto_post_allowed == true
    result.routing == "REPORT"
}

# ── 8. NO_MATCH (default — brak flagi) ─────────────────────────
test_no_match_without_activation_flag {
    result := pkpir_etap14.decide with input as object.union(ctx, {})
    result.matched == false
    result.rule_id == "jdg.pkpir_etap14.no_match"
}
