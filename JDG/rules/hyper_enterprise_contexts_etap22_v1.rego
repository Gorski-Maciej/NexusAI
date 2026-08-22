# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ETAP 22 HYPER ENTERPRISE CONTEXTS / META-VALIDATOR
# ═══════════════════════════════════════════════════════════════════════════════
# Warstwa meta nad Hyper Plan45/R13. Egzekwuje kontrakt: wejście → dowód →
# wynik → test → odbiorca. Nie wykonuje przelewów, wysyłek ani auto-akcji.

package jdg.hyper_enterprise_contexts_etap22

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.hyper_enterprise_contexts_etap22.no_match",
    "package": "jdg.hyper_enterprise_contexts_etap22",
    "priority": 999999,
    "decision_mode": "SUGGEST",
    "no_auto_post": true,
}

decision_mode := "SUGGEST"

# ADR-002: katalogi, progi i wersje są wstrzykiwane z warstwy danych.
_thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
_et22 := object.get(_thresholds, "hyper_enterprise_contexts_etap22", {})
registry_version := object.get(_et22, "registry_version", "hyper-etap22-2026.08")
legal_version := object.get(_et22, "legal_basis_version", "isap-hyper-2026.08")
source_registry := object.get(_et22, "source_registry", "data.jdg.legal_source_registry")
valid_from := object.get(_et22, "valid_from", "2026-01-01")
valid_to := object.get(_et22, "valid_to", null)
allowed_priorities := object.get(_et22, "allowed_priorities", ["P0", "P1", "P2", "P3"])

ctx := object.get(input, "hyper_enterprise_contexts_etap22", {})
requested_contexts := object.get(ctx, "contexts", [])
source_refs := object.get(ctx, "source_refs", [])
legal_nodes := object.get(ctx, "legal_nodes", {})
evaluation_date := object.get(ctx, "evaluation_date", "")
facts_version := object.get(ctx, "facts_version", "")
threshold_version := object.get(ctx, "threshold_version", "")
legal_basis_version := object.get(ctx, "legal_basis_version", legal_version)
owner_approval := object.get(ctx, "owner_approval", false)
territory_required := object.get(ctx, "territory_required", false)
territory_code := object.get(ctx, "territory_code", "")

# ── Rejestr kontekstów i kontrakt input/evidence/result/test/recipient ────────
context_catalog := ["GENERAL", "DEADLINES", "LIMITS", "MDR", "SANCTIONS", "FX", "WIS", "EDELIVERY", "SPECIAL"]
invalid_contexts := [name | name := requested_contexts[_]; not name in context_catalog]
context_registry := object.get(ctx, "context_registry", [])
registry_missing := [name |
    name := requested_contexts[_]
    count([entry | entry := context_registry[_]; object.get(entry, "context", "") == name]) == 0
]
context_registry_complete := count(requested_contexts) > 0 and count(invalid_contexts) == 0 and count(registry_missing) == 0

context_outputs := object.get(ctx, "context_outputs", [])
output_missing_fields := [name |
    output := context_outputs[_]
    name := object.get(output, "context", "")
    object.get(output, "input_hash", "") == "" or
    object.get(output, "evidence_ref", "") == "" or
    object.get(output, "result", "") == "" or
    object.get(output, "test_ref", "") == "" or
    object.get(output, "recipient", "") == ""
]
output_contract_complete := count(context_outputs) > 0 and count(output_missing_fields) == 0

# ── Temporalność, terytorium, priorytety i dependency graph ─────────────────
source_complete := count(source_refs) > 0 and count(legal_nodes) > 0
context_complete := evaluation_date != "" and facts_version != "" and threshold_version != "" and legal_basis_version != ""
territory_complete := not territory_required or territory_code != ""
priorities := object.get(ctx, "priorities", [])
invalid_priorities := [priority | priority := priorities[_]; not priority in allowed_priorities]
priority_complete := count(priorities) > 0 and count(invalid_priorities) == 0

graph := object.get(ctx, "dependency_graph", {})
graph_nodes := object.get(graph, "nodes", [])
graph_edges := object.get(graph, "edges", [])
graph_complete := count(graph_nodes) > 0 and count(graph_edges) >= 0 and object.get(graph, "graph_version", "") != ""
conflict_pairs := object.get(graph, "conflict_pairs", [])
conflict_detector := object.get(graph, "conflict_detector", false)
conflict_gate_ok := conflict_detector and count(conflict_pairs) >= 0

# ── Deadline engine: termin, źródło, status, odbiorca i przesunięcie ──────────
deadline_items := object.get(ctx, "deadline_items", [])
invalid_deadlines := [item |
    item := deadline_items[_]
    object.get(item, "deadline_id", "") == "" or
    object.get(item, "due_date", "") == "" or
    object.get(item, "status", "") == "" or
    object.get(item, "evidence_ref", "") == "" or
    object.get(item, "recipient", "") == ""
]
deadline_engine := count(deadline_items) > 0 and count(invalid_deadlines) == 0

# ── Limit registry: wartość, jednostka, zakres, terytorium i źródło ───────────
limit_items := object.get(ctx, "limit_items", [])
invalid_limits := [item |
    item := limit_items[_]
    object.get(item, "limit_id", "") == "" or
    object.get(item, "value", "") == "" or
    object.get(item, "unit", "") == "" or
    object.get(item, "valid_from", "") == "" or
    object.get(item, "source_ref", "") == ""
]
limits_registry := count(limit_items) > 0 and count(invalid_limits) == 0

# ── MDR, sankcje, waluty, WIS i e-Doręczenia ──────────────────────────────────
mdr_enabled := object.get(ctx, "mdr_enabled", false)
mdr := object.get(ctx, "mdr", {})
mdr_complete := not mdr_enabled or (
    object.get(mdr, "hallmark", "") != "" and
    object.get(mdr, "reportability_assessed", false) and
    object.get(mdr, "evidence_ref", "") != "" and
    object.get(mdr, "recipient", "") != ""
)

sanctions := object.get(ctx, "sanctions", {})
sanctions_complete := object.get(ctx, "sanctions_enabled", false) == false or (
    object.get(sanctions, "violation_type", "") != "" and
    object.get(sanctions, "legal_basis", "") != "" and
    object.get(sanctions, "appeal_deadline", "") != "" and
    object.get(sanctions, "evidence_ref", "") != ""
)

fx_enabled := object.get(ctx, "fx_enabled", false)
fx := object.get(ctx, "fx", {})
fx_complete := not fx_enabled or (
    object.get(fx, "currency", "") != "" and
    object.get(fx, "rate", "") != "" and
    object.get(fx, "rate_date", "") != "" and
    object.get(fx, "rate_source", "") != "" and
    object.get(fx, "evidence_ref", "") != ""
)

wis_enabled := object.get(ctx, "wis_enabled", false)
wis := object.get(ctx, "wis", {})
wis_complete := not wis_enabled or (
    object.get(wis, "request_id", "") != "" and
    object.get(wis, "status", "") in ["REQUESTED", "ISSUED", "VALID", "EXPIRED"] and
    object.get(wis, "evidence_ref", "") != ""
)

edelivery_enabled := object.get(ctx, "edelivery_enabled", false)
edelivery := object.get(ctx, "edelivery", {})
edelivery_complete := not edelivery_enabled or (
    object.get(edelivery, "address_id", "") != "" and
    object.get(edelivery, "mailbox_status", "") in ["ACTIVE", "SUSPENDED"] and
    object.get(edelivery, "confirmation_ref", "") != "" and
    object.get(edelivery, "evidence_ref", "") != ""
)

# ── Meta-validator i fail-closed routing ──────────────────────────────────────
stub_detected := object.get(ctx, "stub_detected", false)
meta_validation := context_registry_complete and output_contract_complete and
    source_complete and context_complete and territory_complete and priority_complete and
    graph_complete and conflict_gate_ok and deadline_engine and limits_registry and
    mdr_complete and sanctions_complete and fx_complete and wis_complete and edelivery_complete
manual_review_required := true
hard_block := not meta_validation or stub_detected or not owner_approval
routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE" if {
    manual_review_required
} else := "" if {
    true
}

# ── Werdykt guidance-only z grafem zależności ──────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.hyper_enterprise_contexts_etap22.hyper_meta_verdict",
    "package": "jdg.hyper_enterprise_contexts_etap22",
    "priority": 22001,
    "stage": "ETAP_22",
    "decision_mode": "SUGGEST",
    "state": "META_VALIDATED" if {meta_validation} else "META_BLOCKED",
    "context_catalog": context_catalog,
    "requested_contexts": requested_contexts,
    "context_registry_complete": context_registry_complete,
    "context_outputs_complete": output_contract_complete,
    "output_missing_fields": output_missing_fields,
    "deadline_engine": deadline_engine,
    "limits_registry": limits_registry,
    "mdr_complete": mdr_complete,
    "sanctions_complete": sanctions_complete,
    "fx_complete": fx_complete,
    "wis_complete": wis_complete,
    "edelivery_complete": edelivery_complete,
    "dependency_graph": {"version": object.get(graph, "graph_version", ""), "nodes": graph_nodes, "edges": graph_edges, "conflict_pairs": conflict_pairs, "conflict_detector": conflict_detector, "complete": graph_complete and conflict_gate_ok},
    "priority_validation": {"priorities": priorities, "invalid": invalid_priorities, "complete": priority_complete},
    "territorial_validation": {"required": territory_required, "territory_code": territory_code, "complete": territory_complete},
    "evidence_chain": {"source_complete": source_complete, "context_complete": context_complete, "source_refs": source_refs, "legal_nodes": legal_nodes, "facts_version": facts_version, "threshold_version": threshold_version, "legal_basis_version": legal_basis_version, "registry_version": registry_version, "source_registry": source_registry},
    "meta_validator": {"input": count(requested_contexts) > 0, "evidence": source_complete and output_contract_complete, "result": meta_validation, "tests": object.get(ctx, "meta_test_ref", ""), "recipient": object.get(ctx, "meta_recipient", "")},
    "manual_review_required": manual_review_required,
    "owner_approval": owner_approval,
    "compliance_guidance_only": true,
    "_routing": routing,
    "_routing_reason": "ETAP 22: każdy kontekst Hyper Plan45 wymaga wejścia, evidence, wyniku, testu, odbiorcy, temporalności, terytorium i kontroli konfliktów.",
    "_legal_basis": "PIT art. 30ca, 30h, 45; OrdPU art. 12, 126, 193a; MDR art. 86a-86o; VAT art. 42a; eIDAS; ustawa o doręczeniach elektronicznych; KKS",
    "_warnings": ["Meta-validator nie wykonuje czynności zewnętrznych.", "Brak źródła, testu, odbiorcy, aktualnego limitu, terminu lub grafu blokuje wynik.", "Konflikty i sankcje wymagają manualnego odbiorcy; wynik jest guidance-only."],
    "no_auto_post": true,
    "auto_action": "NONE — MANUAL_REVIEW_REQUIRED",
    "valid_from": valid_from,
    "valid_to": valid_to,
} {
    object.get(object.get(input, "jdg_entrepreneur", {}), "hyper_enterprise_contexts_etap22_check", false) == true
}
