package jdg.tests.policies_mirror_sync_etap26

import data.jdg.policies_mirror_sync_etap26

base_input := {
    "jdg_entrepreneur": {"policies_mirror_sync_etap26_check": true},
    "policies_mirror_sync_etap26": {
        "evaluation_date": "2026-08-22",
        "run_id": "run-26",
        "evidence_refs": ["evidence://mirror-sync", "evidence://overlays"],
        "source_of_truth": {"declared": true, "path": "JDG/rules/", "mirror_role": "OVERLAY"},
        "mirror": {
            "drift": {"drift_pct": 0.0, "drift_files": 0, "changed_checksum": []},
            "hash_parity": {"parity_pct": 100.0, "mismatched_count": 0, "missing_count": 0},
        },
        "contract": {"decision_parity_pct": 100.0, "missing_from_mirror": 0},
        "legal_parity": {"legal_parity_pct": 100.0, "missing_from_mirror": 0},
        "overlays": {
            "intervals": {"tcl_100": true, "overlaps_count": 0, "gaps_count": 0},
            "ghost_count": 0, "ghosts": [], "manifest_count": 2,
        },
        "experimental_variants": {"marked": true, "excluded_from_decisions": true},
    },
}

test_no_match if {
    result := policies_mirror_sync_etap26.decide with input as {"jdg_entrepreneur": {}}
    result.rule_id == "jdg.policies_mirror_sync_etap26.no_match"
}

test_missing if {
    result := policies_mirror_sync_etap26.decide with input as {"jdg_entrepreneur": {"policies_mirror_sync_etap26_check": true}}
    result._routing == "BLOCK_AND_ALERT"
    result.state == "MIRROR_DRIFT"
}

test_mirror if {
    result := policies_mirror_sync_etap26.decide with input as base_input
    result.mirror_synced == true
    result.source_of_truth_declared == true
}

test_hash_parity if {
    result := policies_mirror_sync_etap26.decide with input as base_input
    result.hash_parity_complete == true
}

test_decision_parity if {
    result := policies_mirror_sync_etap26.decide with input as base_input
    result.decision_parity_complete == true
    result.no_silent_change == true
}

test_legal_parity if {
    result := policies_mirror_sync_etap26.decide with input as base_input
    result.legal_parity_complete == true
}

test_overlays if {
    result := policies_mirror_sync_etap26.decide with input as base_input
    result.overlays_complete == true
    result.overlays_tcl_100 == true
    result.overlays_no_ghosts == true
}

test_experimental if {
    result := policies_mirror_sync_etap26.decide with input as base_input
    result.experimental_marked == true
}

test_fail_closed if {
    result := policies_mirror_sync_etap26.decide with input as base_input
    result.decision_mode == "SUGGEST"
    result.manual_review_required == true
}

test_valid if {
    result := policies_mirror_sync_etap26.decide with input as base_input
    result.state == "MIRROR_SYNCED"
    result._routing == "TRIAGE_QUEUE"
}