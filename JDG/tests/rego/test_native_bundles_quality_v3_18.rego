package jdg.bundles.quality_v3_18

import data.jdg.bundles.quality_v3_18

# Golden evidence: pełny cykl delivery (bundle+SBOM+podpis, verify lokalny,
# overlay matrix v2026/v2027, mirror 0% drift, RuleStore 13 migracji z seedem
# obwieszczeń, hot-reload 30 s, canary rollback MTTR 4 min, DR RTO 10/RPO 10,
# game-day 12 dni temu).
valid_ctx := {
    "source_refs": ["isap://ordpu/12", "isap://vat/109"],
    "legal_nodes": ["ordpu.art12", "vat.art109"],
    "evaluation_date": "2026-08-26",
    "facts_version": "facts-2026.08",
    "input_hash": "sha256:bundles-golden-18",
    "owner_approval": true,
    "manual_recipient": "OWNER_RELEASE",
    "bundle": {"build_passed": true, "sbom_generated": true, "signature_present": true},
    "verify": {"local_verify_passed": true},
    "overlay": {"matrix_pass": true, "versions_tested": ["v2026", "v2027"]},
    "mirror": {"drift_pct": 0, "hash_parity_pct": 100},
    "rulestore": {"migrations_applied": 13, "schema_versioned": true, "seeded_from_official_gazettes": true},
    "deploy": {"hot_reload_seconds": 30, "rollback_mttr_min": 4},
    "dr": {"rto_min": 10, "rpo_min": 10, "days_since_game_day": 12},
}

full_input := {"bundles_quality_v3_18_check": true, "bundles_quality_v3_18": valid_ctx}

test_full_contract_validated if {
    result := quality_v3_18.decide with input as full_input
    result.state == "BUNDLES_VALIDATED"
    result._routing == "TRIAGE_QUEUE"
    result.no_auto_post == true
    result.mode == "DECOUPLED"
}

test_fail_closed_without_owner_approval if {
    ctx := object.union(valid_ctx, {"owner_approval": false})
    result := quality_v3_18.decide with input as {"bundles_quality_v3_18_check": true, "bundles_quality_v3_18": ctx}
    result.state == "BUNDLES_BLOCKED"
    result._routing == "BLOCK_AND_ALERT"
    result.no_auto_post == true
}

test_unsigned_bundle_blocks if {
    ctx := object.union(valid_ctx, {"bundle": {"build_passed": true, "sbom_generated": true, "signature_present": false}})
    r1 := quality_v3_18.decide with input as {"bundles_quality_v3_18_check": true, "bundles_quality_v3_18": ctx}
    r1.bundle_ok == false
    r1.state == "BUNDLES_BLOCKED"

    ctx2 := object.union(valid_ctx, {"verify": {"local_verify_passed": false}})
    r2 := quality_v3_18.decide with input as {"bundles_quality_v3_18_check": true, "bundles_quality_v3_18": ctx2}
    r2.verify_ok == false
    r2.state == "BUNDLES_BLOCKED"
}

test_mirror_drift_blocks if {
    ctx := object.union(valid_ctx, {"mirror": {"drift_pct": 2, "hash_parity_pct": 98}})
    result := quality_v3_18.decide with input as {"bundles_quality_v3_18_check": true, "bundles_quality_v3_18": ctx}
    result.mirror.ok == false
    result.state == "BUNDLES_BLOCKED"
}

test_rulestore_migrations_below_min_block if {
    ctx := object.union(valid_ctx, {"rulestore": {"migrations_applied": 9, "schema_versioned": true, "seeded_from_official_gazettes": false}})
    result := quality_v3_18.decide with input as {"bundles_quality_v3_18_check": true, "bundles_quality_v3_18": ctx}
    result.rulestore.ok == false
    result.rulestore.migrations_applied == 9
    result.state == "BUNDLES_BLOCKED"
}

test_canary_rollback_sla_blocks if {
    slow := object.union(valid_ctx, {"deploy": {"hot_reload_seconds": 120, "rollback_mttr_min": 25}})
    r_slow := quality_v3_18.decide with input as {"bundles_quality_v3_18_check": true, "bundles_quality_v3_18": slow}
    r_slow.canary_ok == false

    fast_reload := object.union(valid_ctx, {"deploy": {"hot_reload_seconds": 30, "rollback_mttr_min": 8}})
    r_mttr := quality_v3_18.decide with input as {"bundles_quality_v3_18_check": true, "bundles_quality_v3_18": fast_reload}
    r_mttr.canary_ok == false
}

test_dr_game_day_stale_blocks if {
    ctx := object.union(valid_ctx, {"dr": {"rto_min": 10, "rpo_min": 10, "days_since_game_day": 45}})
    result := quality_v3_18.decide with input as {"bundles_quality_v3_18_check": true, "bundles_quality_v3_18": ctx}
    result.dr_ok == false
    result.state == "BUNDLES_BLOCKED"
}

test_no_auto_post_always_true if {
    blocked := quality_v3_18.decide with input as {"bundles_quality_v3_18_check": true, "bundles_quality_v3_18": {}}
    blocked.no_auto_post == true
}
