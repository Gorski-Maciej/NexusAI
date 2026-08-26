package jdg.tools.quality_v3_16

import data.jdg.tools.quality_v3_16

# Golden evidence: wszystkie 19 narzędzi PASS + coverage 97% (cel 95).
tool_pass(name) := {name: "PASS"}

all_tools := array.union(
    ["lint_rego_rules", "validate_rules", "dead_rule_detector", "tautology_guard",
     "else_chain_dead_code_detector", "hardcoded_audit_gate"],
    array.union(
        ["validate_legal_basis", "validate_enterprise_contract", "cross_ref_validator",
         "doc_consistency_validator", "inventory_reconciliation", "test_coverage_gate",
         "temporal_interval_gate", "manifest_v2", "legal_basis_audit"],
        ["legal_coverage_gap_report", "legal_coverage_heatmap", "traceability_matrix", "coverage_95_plan"],
    ))

valid_ctx := {
    "tool_results": object.union({name: "PASS" | name := all_tools[_]}, {}),
    "source_refs": ["isap://ordpu/12", "isap://vat/109"],
    "legal_nodes": ["ordpu.art12", "vat.art109"],
    "evaluation_date": "2026-08-26",
    "facts_version": "facts-2026.08",
    "input_hash": "sha256:quality-golden-16",
    "owner_approval": true,
    "manual_recipient": "OWNER_QA",
    "coverage": {"pct": 97},
    "tautology": {"count": 0},
    "dead_code": {"criticals": 0},
    "hardcode": {"findings": 0},
    "manifest": {"diff_status": "CLEAN"},
}

full_input := {"tools_quality_v3_16_check": true, "tools_quality_v3_16": valid_ctx}

test_full_contract_validated if {
    result := quality_v3_16.decide with input as full_input
    result.state == "GATES_VALIDATED"
    result._routing == "TRIAGE_QUEUE"
    result.no_auto_post == true
    result.mode == "DECOUPLED"
}

test_fail_closed_without_owner_approval if {
    ctx := object.union(valid_ctx, {"owner_approval": false})
    result := quality_v3_16.decide with input as {"tools_quality_v3_16_check": true, "tools_quality_v3_16": ctx}
    result.state == "GATES_BLOCKED"
    result._routing == "BLOCK_AND_ALERT"
    result.no_auto_post == true
}

test_missing_linter_blocks if {
    ctx := object.remove(valid_ctx, ["tool_results"])
    partial := object.union(ctx, {"tool_results": object.remove(valid_ctx.tool_results, ["tautology_guard"])})
    result := quality_v3_16.decide with input as {"tools_quality_v3_16_check": true, "tools_quality_v3_16": partial}
    count(result.missing_linters) == 1
    result.linters_complete == false
    result.state == "GATES_BLOCKED"
}

test_coverage_below_target_blocks if {
    ctx := object.union(valid_ctx, {"coverage": {"pct": 80}})
    result := quality_v3_16.decide with input as {"tools_quality_v3_16_check": true, "tools_quality_v3_16": ctx}
    result.coverage.ok == false
    result.coverage.pct == 80
    result.state == "GATES_BLOCKED"
}

test_hardcode_findings_block if {
    ctx := object.union(valid_ctx, {"hardcode": {"findings": 3}})
    result := quality_v3_16.decide with input as {"tools_quality_v3_16_check": true, "tools_quality_v3_16": ctx}
    result.hardcode_gate_pass == false
    result.state == "GATES_BLOCKED"
}

test_manifest_diff_blocking if {
    ctx := object.union(valid_ctx, {"manifest": {"diff_status": "DIRTY"}})
    result := quality_v3_16.decide with input as {"tools_quality_v3_16_check": true, "tools_quality_v3_16": ctx}
    result.manifest_ok == false
    result.state == "GATES_BLOCKED"
}

test_tautology_and_dead_code_gates if {
    ctx := object.union(valid_ctx, {"tautology": {"count": 2}, "dead_code": {"criticals": 1}})
    result := quality_v3_16.decide with input as {"tools_quality_v3_16_check": true, "tools_quality_v3_16": ctx}
    result.tautology_gate_pass == false
    result.dead_code_gate_pass == false
    result.state == "GATES_BLOCKED"
}

test_no_auto_post_always_true if {
    blocked := quality_v3_16.decide with input as {"tools_quality_v3_16_check": true, "tools_quality_v3_16": {}}
    blocked.no_auto_post == true
}
