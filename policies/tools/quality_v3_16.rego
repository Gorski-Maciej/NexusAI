# NexusAI JDG — V3-16 NARZĘDZIA + BRAMKI JAKOŚCI + GAP REPORTS
# Przeprowadź głębokie myślenie i przeprowadź głęboką analizę przed zmianą
# progów bramek. Warstwa jest deterministyczna, guidance-only i fail-closed:
# nie wykonuje lintingu sama, tylko bramkuje WYNIKI narzędzi z evidence.

package jdg.tools.quality_v3_16

import future.keywords.if
import future.keywords.in

_snapshot := object.get(data.jdg.thresholds, "tools_quality_v3_16", {})
threshold_version := object.get(_snapshot, "threshold_version", "")
registry_version := object.get(_snapshot, "registry_version", "")
legal_basis_version := object.get(_snapshot, "legal_basis_version", "")
valid_from := object.get(_snapshot, "valid_from", "")
valid_to := object.get(_snapshot, "valid_to", null)
required_linters := object.get(_snapshot, "required_linters", [])
required_validators := object.get(_snapshot, "required_validators", [])
required_gap_reports := object.get(_snapshot, "required_gap_reports", [])
coverage_target_pct := object.get(_snapshot, "coverage_target_pct", 0)
max_tautologies := object.get(_snapshot, "max_tautologies", 0)
max_dead_criticals := object.get(_snapshot, "max_dead_criticals", 0)
max_hardcode_findings := object.get(_snapshot, "max_hardcode_findings", 0)
manifest_diff_blocking := object.get(_snapshot, "manifest_diff_blocking", true)

ctx := object.get(input, "tools_quality_v3_16", {})
tool_results := object.get(ctx, "tool_results", {})
source_refs := object.get(ctx, "source_refs", [])
legal_nodes := object.get(ctx, "legal_nodes", [])
facts_version := object.get(ctx, "facts_version", "")
evaluation_date := object.get(ctx, "evaluation_date", "")
input_hash := object.get(ctx, "input_hash", "")
owner_approval := object.get(ctx, "owner_approval", false)
manual_recipient := object.get(ctx, "manual_recipient", "")

# Narzędzie jest PASS tylko wtedy, gdy ma wpis {status: "PASS"} w evidence.
tool_passed(name) if {
    object.get(tool_results, name, {}) == "PASS"
}

missing_linters := [name |
    name := required_linters[_]
    not tool_passed(name)
]
missing_validators := [name |
    name := required_validators[_]
    not tool_passed(name)
]
missing_gap_reports := [name |
    name := required_gap_reports[_]
    not tool_passed(name)
]

linters_complete := count(missing_linters) == 0 and registry_version != ""
validators_complete := count(missing_validators) == 0 and threshold_version != ""
gap_reports_complete := count(missing_gap_reports) == 0

source_complete := count(source_refs) > 0 and count(legal_nodes) > 0 and
    legal_basis_version != ""
temporal_valid := evaluation_date != "" and facts_version != "" and
    threshold_version != "" and valid_from != ""

coverage := object.get(ctx, "coverage", {})
coverage_pct := object.get(coverage, "pct", 0)
coverage_ok := coverage_pct >= coverage_target_pct

tautology_count := object.get(object.get(ctx, "tautology", {}), "count", -1)
dead_criticals := object.get(object.get(ctx, "dead_code", {}), "criticals", -1)
hardcode_findings := object.get(object.get(ctx, "hardcode", {}), "findings", -1)

tautology_gate_pass := tautology_count >= 0 and tautology_count <= max_tautologies
dead_code_gate_pass := dead_criticals >= 0 and dead_criticals <= max_dead_criticals
hardcode_gate_pass := hardcode_findings >= 0 and hardcode_findings <= max_hardcode_findings

manifest := object.get(ctx, "manifest", {})
manifest_ok := manifest_diff_blocking == false or
    object.get(manifest, "diff_status", "") == "CLEAN"

contract_complete := linters_complete and validators_complete and
    gap_reports_complete and source_complete and temporal_valid and
    coverage_ok and tautology_gate_pass and dead_code_gate_pass and
    hardcode_gate_pass and manifest_ok and input_hash != ""

hard_block := not contract_complete or not owner_approval or manual_recipient == ""
gates_state := "GATES_VALIDATED" if {
    contract_complete
    not hard_block
} else := "GATES_BLOCKED" if {
    true
}
routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE"

# Publiczny wynik: Quality Gates Certificate — nigdy czynność zewnętrzna.
decide := {
    "matched": true,
    "rule_id": "jdg.tools.quality_v3_16.quality_gates_contract",
    "package": "jdg.tools.quality_v3_16",
    "priority": 22004,
    "stage": "V3-16",
    "state": gates_state,
    "decision_mode": "SUGGEST",
    "mode": "DECOUPLED",
    "no_auto_post": true,
    "linters_complete": linters_complete,
    "validators_complete": validators_complete,
    "gap_reports_complete": gap_reports_complete,
    "missing_linters": missing_linters,
    "missing_validators": missing_validators,
    "missing_gap_reports": missing_gap_reports,
    "source_complete": source_complete,
    "temporal_valid": temporal_valid,
    "coverage": {"pct": coverage_pct, "target": coverage_target_pct, "ok": coverage_ok},
    "tautology_gate_pass": tautology_gate_pass,
    "dead_code_gate_pass": dead_code_gate_pass,
    "hardcode_gate_pass": hardcode_gate_pass,
    "manifest_ok": manifest_ok,
    "hard_block": hard_block,
    "_routing": routing,
    "_routing_reason": "Bramki jakości wymagają pełnego zestawu narzędzi PASS, coverage >= celu, zero-hardcode, czystego manifestu i ręcznego odbiorcy.",
    "_legal_basis": "OrdPU art. 12 § 5, art. 193a; PIT art. 44-45; VAT art. 109; KKS art. 16; ADR-002 (zero-hardcode); MANIFEST.md (rejestr rule_id)",
    "_threshold_version": threshold_version,
    "_registry_version": registry_version,
    "_valid_from": valid_from,
    "_valid_to": valid_to,
    "owner_approval": owner_approval,
    "manual_recipient": manual_recipient,
    "_warnings": [
        "V3-16 bramkuje wyniki narzędzi — sam nie uruchamia linterów ani walidatorów.",
        "Coverage poniżej celu, tautologie, martwe reguły krytyczne lub hardcode blokują wynik.",
        "Diff MANIFEST bez statusu CLEAN blokuje przy manifest_diff_blocking=true.",
    ],
} if {
    object.get(input, "tools_quality_v3_16_check", false) == true
}

default decide := {
    "matched": false,
    "rule_id": "jdg.tools.quality_v3_16.no_match",
    "package": "jdg.tools.quality_v3_16",
    "priority": 999999,
    "mode": "DECOUPLED",
    "no_auto_post": true,
}
