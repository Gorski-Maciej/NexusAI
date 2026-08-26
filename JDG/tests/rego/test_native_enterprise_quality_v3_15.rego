package jdg.enterprise.quality_v3_15

import data.jdg.enterprise.quality_v3_15

# Golden context: pełny kontrakt S1-S24 + Neural Mesh + Scoring (V3-15).
valid_ctx := {
    "initiatives": [object.union({"id": sprintf("S%d", [n])}, {"status": "ACTIVE"}) | n := numbers.range(1, 24)[_]],
    "initiative_registry": [{"id": sprintf("S%d", [n]), "owner": "ENTERPRISE"} | n := numbers.range(1, 24)[_]],
    "source_refs": ["isap://pit/27", "isap://vat/86"],
    "legal_nodes": ["pit.art27", "vat.art86"],
    "evaluation_date": "2026-08-26",
    "facts_version": "facts-2026.08",
    "input_hash": "sha256:enterprise-golden-15",
    "owner_approval": true,
    "manual_recipient": "OWNER_TAX",
    "scoring": {
        "score": 88,
        "sample_count": 150,
        "accuracy": 0.97,
        "brier_score": 0.08,
    },
    "mesh": {
        "nodes": ["VAT", "PIT", "ZUS", "OrdPU", "KKS", "UoR", "PP", "PCC", "PodLok", "Ryczałt", "Sukcesja", "RODO", "AML_BDO"],
        "edges": [{"from": "VAT", "to": "KKS"}, {"from": "PIT", "to": "ZUS"}, {"from": "VAT", "to": "PIT"}, {"from": "UoR", "to": "ZUS"}, {"from": "UoR", "to": "PIT"}, {"from": "RODO", "to": "AML_BDO"}, {"from": "PCC", "to": "KKS"}, {"from": "OrdPU", "to": "KKS"}, {"from": "Ryczałt", "to": "VAT"}, {"from": "PP", "to": "ZUS"}, {"from": "PodLok", "to": "PCC"}, {"from": "Sukcesja", "to": "PP"}],
        "conflicts": [],
        "version": "mesh-2026.08",
    },
    "composer": {
        "inputs": ["decision_scoring", "neural_mesh"],
        "evidence_refs": ["ev://composer/1"],
        "test_refs": ["tests/rego/test_native_enterprise_quality_v3_15.rego"],
        "deterministic": true,
    },
    "red_team": {
        "scenarios": 12,
        "undetected_failures": 0,
    },
}

full_input := {"enterprise_quality_v3_15_check": true, "enterprise_quality_v3_15": valid_ctx}

test_full_contract_validated if {
    result := quality_v3_15.decide with input as full_input
    result.state == "ENTERPRISE_VALIDATED"
    result._routing == "TRIAGE_QUEUE"
    result.no_auto_post == true
    result.mode == "DECOUPLED"
}

test_fail_closed_without_owner_approval if {
    ctx := object.union(valid_ctx, {"owner_approval": false})
    result := quality_v3_15.decide with input as {"enterprise_quality_v3_15_check": true, "enterprise_quality_v3_15": ctx}
    result.state == "ENTERPRISE_BLOCKED"
    result._routing == "BLOCK_AND_ALERT"
    result.no_auto_post == true
}

test_fail_closed_missing_initiative if {
    ctx := object.union(valid_ctx, {"initiatives": array.slice(valid_ctx.initiatives, 0, 23)})
    result := quality_v3_15.decide with input as {"enterprise_quality_v3_15_check": true, "enterprise_quality_v3_15": ctx}
    count(result.missing_initiatives) > 0
    result.state == "ENTERPRISE_BLOCKED"
}

test_scoring_calibration_gate if {
    uncalibrated := object.union(valid_ctx, {"scoring": object.union(valid_ctx.scoring, {"sample_count": 10, "accuracy": 0.5, "brier_score": 0.4})})
    result := quality_v3_15.decide with input as {"enterprise_quality_v3_15_check": true, "enterprise_quality_v3_15": uncalibrated}
    result.scoring.calibrated == false
    result.state == "ENTERPRISE_BLOCKED"
}

test_score_class_bands if {
    high := object.union(valid_ctx, {"scoring": object.union(valid_ctx.scoring, {"score": 95})})
    r_high := quality_v3_15.decide with input as {"enterprise_quality_v3_15_check": true, "enterprise_quality_v3_15": high}
    r_high.scoring.class == "AUTO_CANDIDATE"

    low := object.union(valid_ctx, {"scoring": object.union(valid_ctx.scoring, {"score": 30})})
    r_low := quality_v3_15.decide with input as {"enterprise_quality_v3_15_check": true, "enterprise_quality_v3_15": low}
    r_low.scoring.class == "ABSTAIN"
}

test_mesh_conflict_blocks_validation if {
    conflicted := object.union(valid_ctx, {"mesh": object.union(valid_ctx.mesh, {"conflicts": ["VAT:PIT:rate_mismatch"]})})
    result := quality_v3_15.decide with input as {"enterprise_quality_v3_15_check": true, "enterprise_quality_v3_15": conflicted}
    result.mesh.conflicts == ["VAT:PIT:rate_mismatch"]
    result.state == "ENTERPRISE_BLOCKED"
}

test_red_team_undetected_failure_blocks if {
    weak_rt := object.union(valid_ctx, {"red_team": {"scenarios": 12, "undetected_failures": 2}})
    result := quality_v3_15.decide with input as {"enterprise_quality_v3_15_check": true, "enterprise_quality_v3_15": weak_rt}
    result.red_team_complete == false
    result.state == "ENTERPRISE_BLOCKED"
}

test_no_auto_post_always_true if {
    blocked := quality_v3_15.decide with input as {"enterprise_quality_v3_15_check": true, "enterprise_quality_v3_15": {}}
    blocked.no_auto_post == true
}
