# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ETAP 20 KSeF / JPK / e-Deklaracje / e-Doręczenia / WIS
# ═══════════════════════════════════════════════════════════════════════════════
# Warstwa kontrolna nad istniejącymi pakietami P17/R15. Reguła nie wysyła
# dokumentów, nie pobiera tokenów i nie twierdzi, że dokument został doręczony.
# Każdy wynik jest sugestią z evidence packiem i manualnym gate'em.

package jdg.ksef_jpk_etap20

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.ksef_jpk_etap20.no_match",
    "package": "jdg.ksef_jpk_etap20",
    "priority": 999999,
    "decision_mode": "SUGGEST",
    "no_auto_post": true,
}

decision_mode := "SUGGEST"

# ADR-002: progi, schematy i wersje są danymi konfiguracyjnymi.
_thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
_et20 := object.get(_thresholds, "ksef_jpk_etap20", {})
registry_version := object.get(_et20, "registry_version", "ksef-jpk-etap20-2026.08")
legal_version := object.get(_et20, "legal_basis_version", "isap-mf-2026.08")
source_registry := object.get(_et20, "source_registry", "data.jdg.legal_source_registry")
valid_from := object.get(_et20, "valid_from", "2026-01-01")
valid_to := object.get(_et20, "valid_to", null)
offline_grace_days := to_number(object.get(_et20, "offline_grace_days", 7))
max_retries := to_number(object.get(_et20, "max_retries", 3))
reconciliation_tolerance := to_number(object.get(_et20, "reconciliation_tolerance_pln", 0.01))
upo_deadline_days := to_number(object.get(_et20, "upo_deadline_days", 1))

ctx := object.get(input, "ksef_jpk_etap20", {})
ksef := object.get(ctx, "ksef", {})
jpk := object.get(ctx, "jpk", {})
document := object.get(ctx, "document", {})
source_refs := object.get(ctx, "source_refs", [])
legal_nodes := object.get(ctx, "legal_nodes", {})
evaluation_date := object.get(ctx, "evaluation_date", "")
facts_version := object.get(ctx, "facts_version", "")
threshold_version := object.get(ctx, "threshold_version", "")
legal_basis_version := object.get(ctx, "legal_basis_version", legal_version)
owner_approval := object.get(ctx, "owner_approval", false)

# ── State machine dokumentu ──────────────────────────────────────────────────
state_machine := "DRAFT → VALIDATED → QUEUED → SUBMITTED → ACCEPTED/REJECTED → CORRECTION_REQUIRED → ARCHIVED"
document_states := ["DRAFT", "VALIDATED", "QUEUED", "SUBMITTED", "ACCEPTED", "REJECTED", "CORRECTION_REQUIRED", "CANCELLED", "ARCHIVED"]
transition_catalog := [
    {"from": "DRAFT", "to": "VALIDATED", "event": "VALIDATE"},
    {"from": "VALIDATED", "to": "QUEUED", "event": "ENQUEUE"},
    {"from": "QUEUED", "to": "SUBMITTED", "event": "SUBMIT_OBSERVED"},
    {"from": "SUBMITTED", "to": "ACCEPTED", "event": "UPO_ACCEPTED"},
    {"from": "SUBMITTED", "to": "REJECTED", "event": "MF_REJECTED"},
    {"from": "REJECTED", "to": "CORRECTION_REQUIRED", "event": "CORRECT"},
    {"from": "CORRECTION_REQUIRED", "to": "VALIDATED", "event": "REVALIDATE"},
    {"from": "QUEUED", "to": "CANCELLED", "event": "CANCEL"},
    {"from": "ACCEPTED", "to": "ARCHIVED", "event": "ARCHIVE"},
    {"from": "CANCELLED", "to": "ARCHIVED", "event": "ARCHIVE"},
]
current_state := object.get(document, "state", "DRAFT")
target_state := object.get(document, "target_state", current_state)
transition_requested := current_state != target_state
transition_candidates := [t |
    t := transition_catalog[_]
    t["from"] == current_state
    t["to"] == target_state
]
state_valid := current_state in document_states and target_state in document_states
transition_valid := state_valid and (not transition_requested or count(transition_candidates) == 1)
selected_transition := transition_candidates[0] if {
    count(transition_candidates) == 1
} else := {} if {
    true
}

# ── Format, XSD i identyfikatory ──────────────────────────────────────────────
schema_registry := object.get(_et20, "schema_registry", ["FA(2)", "FA(2)-KOREKTA", "JPK_V7M", "JPK_V7K", "JPK_KR", "JPK_ST"])
schema_version := object.get(document, "schema_version", "")
provided_fields := object.get(document, "fields", {})
required_fields := object.get(_et20, "required_invoice_fields", ["P_1", "P_2", "P_3", "P_4", "P_5", "P_6", "P_7", "P_8"])
missing_fields := [f | f := required_fields[_]; not object.get(provided_fields, f, false)]
schema_valid := schema_version in schema_registry and count(missing_fields) == 0
identifier_complete := object.get(document, "document_id", "") != "" and
    object.get(document, "document_hash", "") != "" and
    object.get(document, "idempotency_key", "") != "" and
    object.get(document, "issuer_nip", "") != "" and
    object.get(document, "buyer_nip", "") != ""
identifier_unique := not object.get(document, "duplicate_detected", false)

# ── Token, UPO, offline, retry i exactly-once outbox ──────────────────────────
token_present := object.get(ksef, "token_present", false)
ksef_number_present := object.get(ksef, "ksef_number", "") != ""
upo_present := object.get(ksef, "upo_present", false)
upo_id_present := object.get(ksef, "upo_id", "") != ""
upo_deadline_ok := object.get(ksef, "upo_deadline_ok", false)
mf_available := object.get(ksef, "mf_available", false)
offline_mode := object.get(ksef, "offline_mode", false)
offline_days := to_number(object.get(ksef, "offline_days", 0))
offline_within_grace := offline_days <= offline_grace_days
retry_attempts := to_number(object.get(ksef, "retry_attempts", 0))
retry_within_limit := retry_attempts <= max_retries
outbox_entry_present := object.get(ksef, "outbox_entry_present", false)
outbox_key_matches := object.get(ksef, "outbox_idempotency_key", "") == object.get(document, "idempotency_key", "")
duplicate_detected := object.get(ksef, "duplicate_detected", false)
exactly_once := outbox_entry_present and outbox_key_matches and not duplicate_detected

# ── JPK, deklaracje, GTU, terminy i korekty ────────────────────────────────────
declaration_type := object.get(jpk, "declaration_type", "")
declaration_types := object.get(_et20, "declaration_types", ["JPK_V7M", "JPK_V7K", "JPK_KR", "JPK_ST", "E_DEKLARACJA"])
declaration_type_valid := declaration_type in declaration_types
gtu_codes := object.get(_et20, "gtu_codes", ["GTU_01", "GTU_02", "GTU_03", "GTU_04", "GTU_05", "GTU_06", "GTU_07", "GTU_08", "GTU_09", "GTU_10", "GTU_11", "GTU_12", "GTU_13"] )
gtu_transaction_codes := object.get(jpk, "gtu_codes", [])
invalid_gtu_codes := [code | code := gtu_transaction_codes[_]; not code in gtu_codes]
gtu_valid := count(invalid_gtu_codes) == 0
jpk_deadline := object.get(jpk, "deadline", "")
deadline_ok := jpk_deadline != "" and evaluation_date != "" and evaluation_date <= jpk_deadline
correction_requested := object.get(document, "is_correction", false)
correction_complete := not correction_requested or (
    object.get(document, "original_document_id", "") != "" and
    object.get(document, "correction_reason", "") != "" and
    object.get(document, "correction_number", "") != ""
)

# ── Rekonsyliacja księga ↔ JPK ↔ KSeF ─────────────────────────────────────────
ledger_total := to_number(object.get(ctx, "ledger_total", 0))
jpk_total := to_number(object.get(ctx, "jpk_total", 0))
ksef_total := to_number(object.get(ctx, "ksef_total", 0))
ledger_jpk_delta := abs(ledger_total - jpk_total)
jpk_ksef_delta := abs(jpk_total - ksef_total)
reconciliation_ok := ledger_jpk_delta <= reconciliation_tolerance and jpk_ksef_delta <= reconciliation_tolerance

# ── WIS, e-Doręczenia i e-podpis ─────────────────────────────────────────────
wis_required := object.get(ctx, "wis_required", false)
wis_complete := not wis_required or (
    object.get(object.get(ctx, "wis", {}), "wis_id", "") != "" and
    object.get(object.get(ctx, "wis", {}), "status", "") in ["REQUESTED", "ISSUED", "VALID"]
)
edelivery_required := object.get(ctx, "edelivery_required", false)
edelivery_complete := not edelivery_required or (
    object.get(object.get(ctx, "edelivery", {}), "address_id", "") != "" and
    object.get(object.get(ctx, "edelivery", {}), "mailbox_active", false) and
    object.get(object.get(ctx, "edelivery", {}), "confirmation_id", "") != ""
)
signature_required := object.get(ctx, "signature_required", false)
signature_type := object.get(object.get(ctx, "signature", {}), "type", "")
signature_complete := not signature_required or (
    signature_type in object.get(_et20, "signature_types", ["QUALIFIED", "TRUSTED"]) and
    object.get(object.get(ctx, "signature", {}), "digest", "") != "" and
    object.get(object.get(ctx, "signature", {}), "verified", false)
)

# ── Sandbox, evidence i manual gate ──────────────────────────────────────────
sandbox_required := object.get(ctx, "sandbox_required", true)
sandbox_complete := not sandbox_required or (
    object.get(object.get(ctx, "sandbox", {}), "run_id", "") != "" and
    object.get(object.get(ctx, "sandbox", {}), "passed", false) and
    object.get(object.get(ctx, "sandbox", {}), "schema_version", "") == schema_version
)
context_complete := evaluation_date != "" and facts_version != "" and threshold_version != "" and legal_basis_version != ""
source_complete := count(source_refs) > 0 and count(legal_nodes) > 0
document_evidence_complete := object.get(document, "document_id", "") != "" and object.get(document, "document_hash", "") != ""
format_evidence_complete := schema_valid and identifier_complete and identifier_unique
transport_gate_ok := mf_available and token_present and ksef_number_present and retry_within_limit and
    (not offline_mode or offline_within_grace) and exactly_once
manual_review_required := not owner_approval or correction_requested or wis_required or edelivery_required or signature_required
hard_block := not context_complete or not source_complete or not document_evidence_complete or
    not format_evidence_complete or not transition_valid or not transport_gate_ok or
    not upo_present or not upo_id_present or not upo_deadline_ok or not declaration_type_valid or
    not gtu_valid or not deadline_ok or not correction_complete or not reconciliation_ok or
    not wis_complete or not edelivery_complete or not signature_complete or not sandbox_complete
routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE" if {
    manual_review_required
} else := "" if {
    true
}

# ── Werdykt: tylko observation/suggestion, nigdy twierdzenie o wysyłce ────────
decide := {
    "matched": true,
    "rule_id": "jdg.ksef_jpk_etap20.ksef_jpk_declaration_verdict",
    "package": "jdg.ksef_jpk_etap20",
    "priority": 20001,
    "stage": "ETAP_20",
    "decision_mode": "SUGGEST",
    "state_machine": state_machine,
    "document_state": {"current": current_state, "target": target_state, "state_valid": state_valid, "transition_valid": transition_valid, "transition": selected_transition},
    "format_certificate": {"schema_version": schema_version, "schema_valid": schema_valid, "required_fields": required_fields, "missing_fields": missing_fields, "identifier_complete": identifier_complete, "identifier_unique": identifier_unique},
    "transport_certificate": {"mf_available": mf_available, "token_present": token_present, "ksef_number_present": ksef_number_present, "offline_mode": offline_mode, "offline_days": offline_days, "offline_grace_days": offline_grace_days, "retry_attempts": retry_attempts, "max_retries": max_retries, "upo_present": upo_present, "upo_id_present": upo_id_present, "upo_deadline_ok": upo_deadline_ok},
    "outbox_certificate": {"outbox_entry_present": outbox_entry_present, "outbox_key_matches": outbox_key_matches, "duplicate_detected": duplicate_detected, "exactly_once_semantics": exactly_once},
    "jpk_certificate": {"declaration_type": declaration_type, "declaration_type_valid": declaration_type_valid, "gtu_codes": gtu_transaction_codes, "invalid_gtu_codes": invalid_gtu_codes, "gtu_valid": gtu_valid, "deadline": jpk_deadline, "deadline_ok": deadline_ok, "correction_requested": correction_requested, "correction_complete": correction_complete},
    "reconciliation_certificate": {"ledger_total": ledger_total, "jpk_total": jpk_total, "ksef_total": ksef_total, "ledger_jpk_delta": ledger_jpk_delta, "jpk_ksef_delta": jpk_ksef_delta, "tolerance_pln": reconciliation_tolerance, "reconciliation_ok": reconciliation_ok},
    "wis_certificate": {"required": wis_required, "complete": wis_complete},
    "edelivery_certificate": {"required": edelivery_required, "complete": edelivery_complete},
    "signature_certificate": {"required": signature_required, "type": signature_type, "complete": signature_complete},
    "sandbox_certificate": {"required": sandbox_required, "complete": sandbox_complete},
    "required_evidence": {"context_complete": context_complete, "source_complete": source_complete, "document_complete": document_evidence_complete, "source_refs": source_refs, "legal_nodes": legal_nodes, "facts_version": facts_version, "threshold_version": threshold_version, "legal_basis_version": legal_basis_version, "registry_version": registry_version, "source_registry": source_registry},
    "manual_review_required": manual_review_required,
    "owner_approval": owner_approval,
    "_routing": routing,
    "_routing_reason": "ETAP 20: format/XSD, identyfikatory, UPO, token, MF availability, offline/retry, outbox exactly-once, JPK/GTU, terminy, korekty, WIS, e-Doręczenia i podpis wymagają dowodu.",
    "_legal_basis": "VAT art. 106na-106nq, 106j, 42a; OrdPU art. 193a; rozporządzenie JPK; eIDAS; ustawa o doręczeniach elektronicznych",
    "_warnings": ["Reguła nie wysyła dokumentu do MF i nie pobiera tokenu.", "SENT/ACCEPTED wymaga obserwacji zewnętrznego systemu oraz UPO.", "Brak aktualnego XSD, tokenu, UPO, dowodu lub dostępności MF blokuje decyzję."],
    "no_auto_post": true,
    "submitted_by_rule": false,
    "sent_by_rule": false,
    "delivery_claim": "NOT_SENT_BY_RULE",
    "valid_from": valid_from,
    "valid_to": valid_to,
} {
    object.get(object.get(input, "jdg_entrepreneur", {}), "ksef_jpk_etap20_check", false) == true
}
