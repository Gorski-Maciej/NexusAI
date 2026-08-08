# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Rego Tests: P05 VAT MICRO ATOMIC PRECISION v9.0
# Sekcje 8-10: micro-mesh + else-chain audit + temporalność + 14 innowacji
# Format: complete rules (test_foo { ... }) — poprawna składnia OPA v0.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p05_vat_micro_atomic_test

import future.keywords.in

# ── SEKCJA 8: MICRO-MESH INDEX ────────────────────────────────────────────────

test_micro_mesh_index {
    result := data.jdg.p05_vat_micro_atomic.micro_mesh_index with input as {
        "jdg_entrepreneur": {"p05_micro_mesh_check": true}
    } with data.jdg.vat_micro_audit as {
        "total_rules": 1468, "unique_rules": 1468, "duplicate_count": 0,
        "total_stubs": 0, "total_checkpoints": 521,
        "coverage": {"5": "COMPLETE", "41": "COMPLETE", "86": "COMPLETE", "113": "PARTIAL"}
    }
    result.matched == true
    result.mesh.total_rules == 1468
    result.mesh.duplicate_count == 0
    result._routing == "REPORT"
}

# ── SEKCJA 8: ELSE-CHAIN AUDITOR ──────────────────────────────────────────────

test_else_chain_auditor {
    result := data.jdg.p05_vat_micro_atomic.else_chain_auditor with input as {
        "jdg_entrepreneur": {"p05_else_chain_check": true}
    } with data.jdg.vat_micro_audit as {
        "duplicate_count": 0, "total_else_chains": 1043, "total_tautologies": 11
    }
    result.matched == true
    result.else_chain.fmw_order_correct == true
}

# ── SEKCJA 8: PROOF-OF-LAW (LKG) ──────────────────────────────────────────────

test_proof_of_law {
    result := data.jdg.p05_vat_micro_atomic.proof_of_law with input as {
        "jdg_entrepreneur": {"p05_proof_of_law_check": true}
    } with data.jdg.vat_micro_audit as {
        "coverage": {"5": "COMPLETE", "41": "COMPLETE", "86": "COMPLETE",
            "113": "PARTIAL", "7": "COMPLETE", "8": "COMPLETE", "15": "COMPLETE",
            "17": "COMPLETE", "19a": "COMPLETE", "20": "COMPLETE", "21": "COMPLETE",
            "28b": "COMPLETE", "29a": "COMPLETE", "43": "COMPLETE", "86a": "COMPLETE",
            "87": "COMPLETE", "88": "COMPLETE", "89a": "COMPLETE", "89b": "COMPLETE",
            "90": "COMPLETE", "91": "COMPLETE", "96": "COMPLETE", "99": "COMPLETE",
            "103": "COMPLETE", "106a": "COMPLETE", "106e": "COMPLETE",
            "106i": "COMPLETE", "106n": "COMPLETE", "108a": "COMPLETE", "120": "COMPLETE"}
    }
    result.matched == true
    result.law.total_verified == 30
}

test_proof_of_law_partial_coverage {
    result := data.jdg.p05_vat_micro_atomic.proof_of_law with input as {
        "jdg_entrepreneur": {"p05_proof_of_law_check": true}
    } with data.jdg.vat_micro_audit as {
        "coverage": {"5": "COMPLETE", "41": "COMPLETE"}
    }
    result.law.total_verified == 2
}

# ── SEKCJA 8: TEMPORAL PROJECTION ─────────────────────────────────────────────

test_temporal_projection {
    result := data.jdg.p05_vat_micro_atomic.temporal_projection with input as {
        "jdg_entrepreneur": {"p05_temporal_check": true},
        "evaluation_datetime": "2026-06-01"
    } with data.jdg.thresholds as {
        "vat": {"bad_debt_days": 90, "subject_exemption_limit": 200000,
            "ksef_mandatory_from": "2026-02-01"}
    }
    result.matched == true
    result.temporal.bad_debt_days == 90
    result.temporal.slim_vat3_active == true
    result.temporal.ksef_now == true
    result.temporal.exemption_limit_pln == 200000
}

# ── SEKCJA 8: ZERO-HARDCODE GUARD ─────────────────────────────────────────────

test_zero_hardcode_guard {
    result := data.jdg.p05_vat_micro_atomic.zero_hardcode_guard with input as {
        "jdg_entrepreneur": {"p05_hardcode_check": true}
    }
    result.matched == true
    result.guard.bad_debt_days_source == "data.jdg.thresholds.vat.bad_debt_days"
}

# ── SEKCJA 9: GOLDEN DATASET VAT (granice groszy) ─────────────────────────────

test_golden_dataset_rounding {
    result := data.jdg.p05_vat_micro_atomic.golden_dataset with input as {
        "jdg_entrepreneur": {"p05_golden_check": true}
    }
    result.matched == true
    result.golden.check_below_half == true
    result.golden.check_at_half == true
    result.golden.check_above_half == true
    "23.00" in result.golden.rate_boundaries
    "0.00" in result.golden.rate_boundaries
}

# ── SEKCJA 9: MICRO↔MACRO CONFLICT DETECTOR ──────────────────────────────────

test_conflict_detector_no_duplicates {
    result := data.jdg.p05_vat_micro_atomic.micro_macro_conflict with input as {
        "jdg_entrepreneur": {"p05_conflict_check": true}
    } with data.jdg.vat_micro_audit as {
        "duplicate_count": 0
    }
    result.matched == true
    result.conflict.rule_id_overlap == true
    result.conflict.priority_contract != ""
}

# ── SEKCJA 9: SLIM VAT 3 CHECKER ──────────────────────────────────────────────

test_slim_vat3_checker {
    result := data.jdg.p05_vat_micro_atomic.slim_vat3_checker with input as {
        "jdg_entrepreneur": {"p05_slim3_check": true, "is_vat_payer": true}
    } with data.jdg.thresholds as {
        "vat": {"bad_debt_days": 90, "ksef_mandatory_from": "2026-02-01"}
    }
    result.matched == true
    result.slim3.slim_vat3_90_days == true
    result.slim3.b2c_efaktura == true
}

# ── SEKCJA 9: ARTICLE DESERT MAP ──────────────────────────────────────────────

test_article_desert_map {
    result := data.jdg.p05_vat_micro_atomic.article_desert_map with input as {
        "jdg_entrepreneur": {"p05_desert_check": true}
    } with data.jdg.vat_micro_audit as {
        "coverage": {"5": "COMPLETE", "41": "COMPLETE"}
    }
    result.matched == true
    result.deserts.desert_count == 28
}

# ── SEKCJA 10: GŁÓWNY RAPORT P05 ──────────────────────────────────────────────

test_p05_main_report {
    result := data.jdg.p05_vat_micro_atomic.decide with input as {
        "jdg_entrepreneur": {"p05_vat_micro_check": true}
    } with data.jdg.vat_micro_audit as {
        "total_rules": 1468, "unique_rules": 1468, "duplicate_count": 0,
        "total_stubs": 0, "total_checkpoints": 521,
        "coverage": {"5": "COMPLETE", "41": "COMPLETE", "86": "COMPLETE",
            "113": "PARTIAL", "7": "COMPLETE", "8": "COMPLETE", "15": "COMPLETE",
            "17": "COMPLETE", "19a": "COMPLETE", "20": "COMPLETE", "21": "COMPLETE",
            "28b": "COMPLETE", "29a": "COMPLETE", "43": "COMPLETE", "86a": "COMPLETE",
            "87": "COMPLETE", "88": "COMPLETE", "89a": "COMPLETE", "89b": "COMPLETE",
            "90": "COMPLETE", "91": "COMPLETE", "96": "COMPLETE", "99": "COMPLETE",
            "103": "COMPLETE", "106a": "COMPLETE", "106e": "COMPLETE",
            "106i": "COMPLETE", "106n": "COMPLETE", "108a": "COMPLETE", "120": "COMPLETE"}
    }
    result.matched == true
    result.rule_id == "jdg.p05_vat_micro_atomic.report"
    result._routing == "REPORT"
    count(result.p05_vat_micro_atomic.section9_genius) == 14
    result.p05_vat_micro_atomic.key_articles_verified == 30
    result.p05_vat_micro_atomic.dependencies.P17_KSEF_JPK == "ksef_micro"
}

test_p05_no_match_default {
    result := data.jdg.p05_vat_micro_atomic.decide with input as {
        "jdg_entrepreneur": {"p05_vat_micro_check": false}
    }
    result.matched == false
    result.rule_id == "jdg.p05_vat_micro_atomic.no_match"
}
