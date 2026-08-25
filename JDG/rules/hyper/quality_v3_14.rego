# NexusAI JDG — V3-14 HYPER CONTEXTS / PLAN44-45 QUALITY CONTRACT
# Przeprowadź głębokie myślenie i przeprowadź głęboką analizę przed zmianą
# parametrów. Pakiet jest guidance-only: nie wykonuje czynności zewnętrznych.
# Poziom ENTERPRISE wymaga evidence, temporalności i ręcznego odbiorcy.

package jdg.hyper.quality_v3_14

import future.keywords.if
import future.keywords.in

# Snapshot is injected through data, never inferred from legacy Plan45 literals.
_snapshot := object.get(data.jdg.thresholds, "hyper_quality_v3_14", {})
registry_version := object.get(_snapshot, "registry_version", "")
threshold_version := object.get(_snapshot, "threshold_version", "")
legal_basis_version := object.get(_snapshot, "legal_basis_version", "")
valid_from := object.get(_snapshot, "valid_from", "")
valid_to := object.get(_snapshot, "valid_to", null)

ctx := object.get(input, "hyper_quality_v3_14", {})
requested_contexts := object.get(ctx, "contexts", [])
context_registry := object.get(ctx, "context_registry", [])
source_refs := object.get(ctx, "source_refs", [])
legal_nodes := object.get(ctx, "legal_nodes", [])
evaluation_date := object.get(ctx, "evaluation_date", "")
facts_version := object.get(ctx, "facts_version", "")
input_hash := object.get(ctx, "input_hash", "")
owner_approval := object.get(ctx, "owner_approval", false)
manual_recipient := object.get(ctx, "manual_recipient", "")

catalog := object.get(_snapshot, "context_catalog", [])
allowed_statuses := object.get(_snapshot, "allowed_deadline_statuses", [])
allowed_sanction_maps := object.get(_snapshot, "allowed_sanction_maps", [])

invalid_contexts := [name |
    name := requested_contexts[_]
    not name in catalog
]
missing_context_registry := [name |
    name := requested_contexts[_]
    count([entry | entry := context_registry[_]; object.get(entry, "context", "") == name]) == 0
]
registry_complete := count(requested_contexts) > 0 and
    count(invalid_contexts) == 0 and count(missing_context_registry) == 0 and
    registry_version != ""

source_complete := count(source_refs) > 0 and count(legal_nodes) > 0 and
    legal_basis_version != ""

temporal_complete := evaluation_date != "" and facts_version != "" and
    threshold_version != "" and valid_from != ""

temporal_overlap := object.get(ctx, "temporal_overlap", false)
temporal_gap := object.get(ctx, "temporal_gap", false)
temporal_valid := temporal_complete and not temporal_overlap and not temporal_gap

invalid_deadlines := [item |
    item := object.get(ctx, "deadline_items", [])[_]
    object.get(item, "deadline_id", "") == "" or
    object.get(item, "base_date", "") == "" or
    object.get(item, "due_date", "") == "" or
    object.get(item, "status", "") == "" or
    object.get(item, "evidence_ref", "") == "" or
    object.get(item, "recipient", "") == "" or
    not object.get(item, "status", "") in allowed_statuses
]
deadline_items := object.get(ctx, "deadline_items", [])
deadline_complete := count(deadline_items) > 0 and count(invalid_deadlines) == 0

invalid_limits := [item |
    item := object.get(ctx, "limit_items", [])[_]
    object.get(item, "limit_id", "") == "" or
    object.get(item, "value", "") == "" or
    object.get(item, "unit", "") == "" or
    object.get(item, "valid_from", "") == "" or
    object.get(item, "valid_to", "") == "" or
    object.get(item, "source_ref", "") == ""
]
limit_items := object.get(ctx, "limit_items", [])
limits_complete := count(limit_items) > 0 and count(invalid_limits) == 0

sanction_map := object.get(ctx, "sanction_map", {})
sanction_complete := object.get(ctx, "sanctions_enabled", false) == false or (
    object.get(sanction_map, "mapping", "") in allowed_sanction_maps and
    object.get(sanction_map, "violation_type", "") != "" and
    object.get(sanction_map, "legal_basis", "") != "" and
    object.get(sanction_map, "appeal_deadline", "") != "" and
    object.get(sanction_map, "evidence_ref", "") != ""
)

force_majeure := object.get(ctx, "force_majeure", {})
force_majeure_complete := object.get(ctx, "force_majeure_enabled", false) == false or (
    object.get(force_majeure, "event_id", "") != "" and
    object.get(force_majeure, "started_at", "") != "" and
    object.get(force_majeure, "ended_at", "") != "" and
    object.get(force_majeure, "evidence_ref", "") != "" and
    object.get(force_majeure, "manual_review", false)
)

fx := object.get(ctx, "fx", {})
fx_complete := object.get(ctx, "fx_enabled", false) == false or (
    object.get(fx, "currency", "") != "" and
    object.get(fx, "rate", "") != "" and
    object.get(fx, "rate_date", "") != "" and
    object.get(fx, "rate_source", "") != "" and
    object.get(fx, "evidence_ref", "") != ""
)

edelivery := object.get(ctx, "edelivery", {})
edelivery_complete := object.get(ctx, "edelivery_enabled", false) == false or (
    object.get(edelivery, "address_id", "") != "" and
    object.get(edelivery, "mailbox_status", "") in ["ACTIVE", "SUSPENDED"] and
    object.get(edelivery, "confirmation_ref", "") != "" and
    object.get(edelivery, "evidence_ref", "") != ""
)

graph := object.get(ctx, "dependency_graph", {})
graph_complete := count(object.get(graph, "nodes", [])) > 0 and
    object.get(graph, "graph_version", "") != "" and
    object.get(graph, "conflict_detector", false)

binding := object.get(ctx, "cross_domain_binding", {})
binding_complete := object.get(binding, "micro_rule_id", "") != "" or
    object.get(binding, "macro_rule_id", "") != ""

stub_detected := object.get(ctx, "stub_detected", false)
all_invariants := registry_complete and source_complete and temporal_valid and
    deadline_complete and limits_complete and sanction_complete and
    force_majeure_complete and fx_complete and edelivery_complete and
    graph_complete and binding_complete and input_hash != ""

hard_block := not all_invariants or stub_detected or not owner_approval or manual_recipient == ""
state := "HYPER_VALIDATED" if {
    all_invariants
    not hard_block
} else := "HYPER_BLOCKED"

routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE" if {
    true
}

# Public result: explicit DECOUPLED mode and no automatic posting.
decide := {
    "matched": true,
    "rule_id": "jdg.hyper.quality_v3_14.hyper_context_contract",
    "package": "jdg.hyper.quality_v3_14",
    "priority": 22002,
    "stage": "V3-14",
    "state": state,
    "decision_mode": "SUGGEST",
    "mode": "DECOUPLED",
    "no_auto_post": true,
    "requested_contexts": requested_contexts,
    "context_registry_complete": registry_complete,
    "source_complete": source_complete,
    "temporal_valid": temporal_valid,
    "deadline_engine_complete": deadline_complete,
    "limits_registry_complete": limits_complete,
    "sanction_map_complete": sanction_complete,
    "force_majeure_complete": force_majeure_complete,
    "fx_complete": fx_complete,
    "edelivery_complete": edelivery_complete,
    "dependency_graph_complete": graph_complete,
    "cross_domain_binding_complete": binding_complete,
    "invalid_contexts": invalid_contexts,
    "missing_context_registry": missing_context_registry,
    "invalid_deadlines": invalid_deadlines,
    "invalid_limits": invalid_limits,
    "hard_block": hard_block,
    "_routing": routing,
    "_routing_reason": "V3-14 wymaga jednego registry, temporalności, dowodów, grafu zależności i ręcznego odbiorcy.",
    "_legal_basis": "OrdPU art. 12 § 5, art. 70, art. 193a; PIT art. 44-45; VAT art. 99, 109; SUS art. 47; MDR art. 86a-86o; RODO; eIDAS; ustawa o doręczeniach elektronicznych",
    "_threshold_version": threshold_version,
    "_registry_version": registry_version,
    "_valid_from": valid_from,
    "_valid_to": valid_to,
    "_warnings": [
        "Wynik V3-14 jest guidance-only i nie wykonuje wysyłki, płatności ani AUTO_POST.",
        "Brak źródła, aktualnego progu, terminu, odbiorcy, grafu lub zatwierdzenia blokuje wynik.",
    ],
    "owner_approval": owner_approval,
    "manual_recipient": manual_recipient,
} if {
    object.get(input, "hyper_quality_v3_14_check", false) == true
}

default decide := {
    "matched": false,
    "rule_id": "jdg.hyper.quality_v3_14.no_match",
    "package": "jdg.hyper.quality_v3_14",
    "priority": 999999,
    "mode": "DECOUPLED",
    "no_auto_post": true,
}
