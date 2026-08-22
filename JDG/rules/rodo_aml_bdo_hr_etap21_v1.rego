# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ETAP 21 RODO / AML-CBDD / BDO / HR / PPK / PFRON
# ═══════════════════════════════════════════════════════════════════════════════
# Kanoniczna warstwa kontrolna nad P15/P16/R14/P19. Rozdziela guidance
# compliance od decyzji podatkowej. Nie wysyła STR/KPO, nie składa wniosków,
# nie podejmuje decyzji kadrowych i nie publikuje danych osobowych.

package jdg.rodo_aml_bdo_hr_etap21

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.rodo_aml_bdo_hr_etap21.no_match",
    "package": "jdg.rodo_aml_bdo_hr_etap21",
    "priority": 999999,
    "decision_mode": "SUGGEST",
    "no_auto_post": true,
}

decision_mode := "SUGGEST"

# ADR-002: limity, wersje prawa i rejestry pochodzą z warstwy danych.
_thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
_et21 := object.get(_thresholds, "rodo_aml_bdo_hr_etap21", {})
registry_version := object.get(_et21, "registry_version", "compliance-hr-etap21-2026.08")
legal_version := object.get(_et21, "legal_basis_version", "isap-uodo-aml-bdo-kp-2026.08")
source_registry := object.get(_et21, "source_registry", "data.jdg.legal_source_registry")
valid_from := object.get(_et21, "valid_from", "2026-01-01")
valid_to := object.get(_et21, "valid_to", null)
breach_deadline_hours := to_number(object.get(_et21, "rodo_breach_deadline_hours", 72))
erasure_deadline_days := to_number(object.get(_et21, "rodo_erasure_deadline_days", 30))
aml_transaction_threshold_eur := to_number(object.get(_et21, "aml_transaction_threshold_eur", 15000))
ubo_minimum_pct := to_number(object.get(_et21, "ubo_minimum_pct", 25))
bdo_kpo_deadline_days := to_number(object.get(_et21, "bdo_kpo_deadline_days", 7))
pfron_employee_threshold := to_number(object.get(_et21, "pfron_employee_threshold", 25))

ctx := object.get(input, "rodo_aml_bdo_hr_etap21", {})
privacy := object.get(ctx, "privacy", {})
aml := object.get(ctx, "aml", {})
bdo := object.get(ctx, "bdo", {})
hr := object.get(ctx, "hr", {})
document := object.get(ctx, "document", {})
domains := object.get(ctx, "domains", [])
evaluation_date := object.get(ctx, "evaluation_date", "")
facts_version := object.get(ctx, "facts_version", "")
threshold_version := object.get(ctx, "threshold_version", "")
legal_basis_version := object.get(ctx, "legal_basis_version", legal_version)
source_refs := object.get(ctx, "source_refs", [])
legal_nodes := object.get(ctx, "legal_nodes", {})
owner_approval := object.get(ctx, "owner_approval", false)

# ── Wspólny evidence chain i zakres ──────────────────────────────────────────
invalid_domains := [domain | domain := domains[_]; not domain in ["RODO", "AML", "BDO", "HR"]]
scope_valid := count(domains) > 0 and count(invalid_domains) == 0
context_complete := evaluation_date != "" and facts_version != "" and threshold_version != "" and legal_basis_version != ""
source_complete := count(source_refs) > 0 and count(legal_nodes) > 0
document_complete := object.get(document, "document_id", "") != "" and
    object.get(document, "document_hash", "") != "" and object.get(document, "document_type", "") != ""
legal_traceability := source_complete and count(legal_nodes) >= count(domains)
stub_detector := "NO_STUB_AUTO_ACTIONS — brak dowodu nie jest zastępowany wartością domyślną"
stub_detected := object.get(ctx, "stub_detected", false)

# ── RODO: podstawa, zgoda, minimalizacja, retencja, prawa i naruszenia ────────
rodo_scope := "RODO" in domains
rodo_basis_complete := not rodo_scope or (
    object.get(privacy, "legal_basis", "") != "" and
    object.get(privacy, "purpose", "") != "" and
    count(object.get(privacy, "data_categories", [])) > 0
)
consent_required := object.get(privacy, "consent_required", false)
consent_complete := not (rodo_scope and consent_required) or (
    object.get(privacy, "consent_id", "") != "" and object.get(privacy, "consent_valid", false)
)
privacy_by_design := not rodo_scope or (
    object.get(privacy, "data_minimized", false) and
    object.get(privacy, "purpose_limitation", false) and
    object.get(privacy, "pii_redacted_in_output", false)
)
retention_complete := not rodo_scope or (
    to_number(object.get(privacy, "retention_days", 0)) > 0 and
    object.get(privacy, "retention_basis", "") != "" and
    object.get(privacy, "retention_review_date", "") != ""
)
breach_detected := object.get(privacy, "breach_detected", false)
breach_complete := not (rodo_scope and breach_detected) or (
    object.get(privacy, "incident_id", "") != "" and
    to_number(object.get(privacy, "breach_hours_elapsed", 0)) <= breach_deadline_hours and
    object.get(privacy, "breach_assessment", "") != ""
)
rights_request_open := object.get(privacy, "rights_request_open", false)
rights_workflow_complete := not (rodo_scope and rights_request_open) or (
    object.get(privacy, "rights_request_id", "") != "" and
    object.get(privacy, "rights_request_due_date", "") != "" and
    object.get(privacy, "rights_request_type", "") in ["ACCESS", "ERASURE", "RECTIFICATION", "PORTABILITY", "OBJECTION"]
)

# ── AML/CBDD: UBO, klient, screening, transakcja i STR/GIIF ──────────────────
aml_scope := "AML" in domains
ubo_complete := not aml_scope or (
    object.get(aml, "ubo_verified", false) and
    object.get(aml, "ubo_source_ref", "") != "" and
    to_number(object.get(aml, "ubo_ownership_pct", 0)) >= ubo_minimum_pct
)
cdd_complete := not aml_scope or (
    object.get(aml, "cdd_level", "") in ["SIMPLIFIED", "STANDARD", "ENHANCED"] and
    object.get(aml, "cdd_evidence_id", "") != ""
)
sanctions_screening_complete := not aml_scope or (
    object.get(aml, "sanctions_screened", false) and
    object.get(aml, "screening_date", "") != "" and
    object.get(aml, "screening_source_ref", "") != ""
)
aml_transaction_amount := to_number(object.get(aml, "transaction_amount_eur", 0))
suspicious_activity := object.get(aml, "suspicious_activity", false)
str_required := aml_scope and (aml_transaction_amount > aml_transaction_threshold_eur or suspicious_activity)
str_complete := not str_required or (
    object.get(aml, "str_submitted", false) and
    object.get(aml, "str_reference", "") != "" and
    object.get(aml, "str_due_date", "") != ""
)
aml_workflow_complete := ubo_complete and cdd_complete and sanctions_screening_complete and str_complete

# ── BDO: rejestr, KPO, EWC i transport odpadów ───────────────────────────────
bdo_scope := "BDO" in domains
bdo_registration_complete := not bdo_scope or (
    object.get(bdo, "registration_required", true) == false or
    (object.get(bdo, "registered", false) and object.get(bdo, "registration_id", "") != "")
)
kpo_complete := not bdo_scope or (
    object.get(bdo, "kpo_required", false) == false or
    (object.get(bdo, "kpo_id", "") != "" and object.get(bdo, "kpo_status", "") in ["DRAFT", "CONFIRMED", "ACCEPTED"])
)
ewc_complete := not bdo_scope or (
    object.get(bdo, "ewc_code", "") != "" and object.get(bdo, "ewc_verified", false) and
    object.get(bdo, "ewc_source_ref", "") != ""
)
waste_transport_complete := not bdo_scope or (
    object.get(bdo, "transport_required", false) == false or
    (object.get(bdo, "transport_authorized", false) and object.get(bdo, "carrier_evidence_id", "") != "")
)
waste_record_complete := not bdo_scope or (
    object.get(bdo, "waste_record_required", false) == false or
    (object.get(bdo, "waste_record_id", "") != "" and object.get(bdo, "waste_mass_unit", "") != "")
)
bdo_workflow_complete := bdo_registration_complete and kpo_complete and ewc_complete and waste_transport_complete and waste_record_complete

# ── HR / PPK / PFRON: dokumentacja zatrudnienia i obowiązki płatnika ──────────
hr_scope := "HR" in domains
employment_complete := not hr_scope or (
    object.get(hr, "employment_document_id", "") != "" and
    object.get(hr, "employment_basis", "") in ["EMPLOYMENT", "MANDATE", "WORK"]
)
payroll_complete := not hr_scope or (
    object.get(hr, "payroll_period", "") != "" and object.get(hr, "payroll_evidence_id", "") != "" and
    object.get(hr, "zus_pit_reconciled", false)
)
ppk_required := hr_scope and object.get(hr, "ppk_applicable", false)
ppk_complete := not ppk_required or (
    object.get(hr, "ppk_status", "") in ["ENROLLED", "DECLINED", "EXEMPT"] and
    object.get(hr, "ppk_evidence_id", "") != ""
)
pfron_required := hr_scope and to_number(object.get(hr, "employee_count", 0)) >= pfron_employee_threshold
pfron_complete := not pfron_required or (
    object.get(hr, "pfron_status", "") in ["REGISTERED", "FEE_PAID", "EXEMPTION_DOCUMENTED"] and
    object.get(hr, "pfron_evidence_id", "") != ""
)
hr_workflow_complete := employment_complete and payroll_complete and ppk_complete and pfron_complete

# ── Manual review, stubs i routing fail-closed ────────────────────────────────
manual_review_required := true
compliance_guidance_only := true
tax_decision := false
privacy_or_aml_high_risk := breach_detected or str_required or object.get(aml, "high_risk_client", false)
hard_block := not scope_valid or not context_complete or not source_complete or not document_complete or
    not legal_traceability or stub_detected or not rodo_basis_complete or not consent_complete or
    not privacy_by_design or not retention_complete or not breach_complete or not rights_workflow_complete or
    not aml_workflow_complete or not bdo_workflow_complete or not hr_workflow_complete or not owner_approval
routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE" if {
    manual_review_required or privacy_or_aml_high_risk
} else := "" if {
    true
}

# ── Kanoniczny wynik: guidance + dowody, bez nieuprawnionych auto-actions ─────
decide := {
    "matched": true,
    "rule_id": "jdg.rodo_aml_bdo_hr_etap21.compliance_hr_verdict",
    "package": "jdg.rodo_aml_bdo_hr_etap21",
    "priority": 21001,
    "stage": "ETAP_21",
    "decision_mode": "SUGGEST",
    "compliance_guidance_only": compliance_guidance_only,
    "tax_decision": tax_decision,
    "privacy_by_design": privacy_by_design,
    "stub_detector": stub_detector,
    "rodo_certificate": {"scope": rodo_scope, "basis_complete": rodo_basis_complete, "consent_complete": consent_complete, "retention_complete": retention_complete, "breach_complete": breach_complete, "rights_workflow_complete": rights_workflow_complete, "erasure_deadline_days": erasure_deadline_days},
    "aml_certificate": {"scope": aml_scope, "ubo_complete": ubo_complete, "ubo_minimum_pct": ubo_minimum_pct, "cdd_complete": cdd_complete, "sanctions_screening_complete": sanctions_screening_complete, "transaction_amount_eur": aml_transaction_amount, "transaction_threshold_eur": aml_transaction_threshold_eur, "str_required": str_required, "str_complete": str_complete},
    "bdo_certificate": {"scope": bdo_scope, "registration_complete": bdo_registration_complete, "kpo_complete": kpo_complete, "ewc_complete": ewc_complete, "waste_transport_complete": waste_transport_complete, "waste_record_complete": waste_record_complete, "kpo_deadline_days": bdo_kpo_deadline_days},
    "hr_certificate": {"scope": hr_scope, "employment_complete": employment_complete, "payroll_complete": payroll_complete, "ppk_complete": ppk_complete, "pfron_required": pfron_required, "pfron_complete": pfron_complete},
    "evidence_chain": {"context_complete": context_complete, "source_complete": source_complete, "document_complete": document_complete, "legal_traceability": legal_traceability, "source_refs": source_refs, "legal_nodes": legal_nodes, "facts_version": facts_version, "threshold_version": threshold_version, "legal_basis_version": legal_basis_version, "registry_version": registry_version, "source_registry": source_registry},
    "manual_review_required": manual_review_required,
    "owner_approval": owner_approval,
    "_routing": routing,
    "_routing_reason": "ETAP 21: RODO/AML/BDO/HR wymagają podstawy, dowodu, wersji, minimalizacji danych i manualnego zatwierdzenia; brak dowodu blokuje.",
    "_legal_basis": "RODO art. 5; RODO art. 17; RODO art. 22, 24, 28, 30, 32-34, 83; u.AML art. 2, 28-34, 41; u.AML art. 74-80; u.AML art. 153; UoO art. 49; UoO art. 66-70, 89, 194; KP art. 85, 148¹, 154-172; ustawa o PPK; ustawa o PFRON",
    "_warnings": ["Wynik jest guidance compliance, nie decyzją podatkową ani kadrową.", "Pakiet nie wysyła STR/GIIF, KPO, zgłoszeń BDO, wypłat ani danych do pracowników.", "Brak aktualnego źródła, zgody, retencji, UBO, KPO/EWC, dokumentu HR albo owner approval blokuje."],
    "no_auto_post": true,
    "auto_action": "NONE — MANUAL_APPROVAL_REQUIRED",
    "valid_from": valid_from,
    "valid_to": valid_to,
} {
    object.get(object.get(input, "jdg_entrepreneur", {}), "rodo_aml_bdo_hr_etap21_check", false) == true
}
