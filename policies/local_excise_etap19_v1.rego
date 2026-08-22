# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ETAP 19 PCC / PODATKI LOKALNE / NIERUCHOMOŚCI / TRANSPORT / AKCYZA
# ═══════════════════════════════════════════════════════════════════════════════
# Warstwa kontrolna nad istniejącymi silnikami P14/R11/local_taxes/*.
# Nie składa deklaracji, nie wysyła e-DD i nie stosuje stawki bez dowodu.

package jdg.local_excise_etap19

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.local_excise_etap19.no_match",
    "package": "jdg.local_excise_etap19",
    "priority": 999999,
    "decision_mode": "SUGGEST",
}

decision_mode := "SUGGEST"

_thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
_et19 := object.get(_thresholds, "local_excise_etap19", {})
registry_version := object.get(_et19, "registry_version", "local-excise-2026.08")
legal_version := object.get(_et19, "legal_basis_version", "isap-lkg-2026.08")
source_registry := object.get(_et19, "source_registry", "data.jdg.legal_source_registry")
valid_from := object.get(_et19, "valid_from", "2026-01-01")
valid_to := object.get(_et19, "valid_to", null)
pcc3_days := object.get(_et19, "pcc3_deadline_days", 14)
dn1_days := object.get(_et19, "dn1_deadline_days", 14)
transport_threshold_t := object.get(_et19, "transport_threshold_t", 3.5)

ctx := object.get(input, "local_excise_etap19", {})
domain := object.get(ctx, "domain", "")
evaluation_date := object.get(ctx, "evaluation_date", "")
facts_version := object.get(ctx, "facts_version", "")
threshold_version := object.get(ctx, "threshold_version", "")
source_refs := object.get(ctx, "source_refs", [])
legal_nodes := object.get(ctx, "legal_nodes", {})
owner_approval := object.get(ctx, "owner_approval", false)

# Jeden kontrakt dokumentu obejmuje umowę, uchwałę, deklarację i dokument akcyzowy.
document := object.get(ctx, "document", {})
document_id := object.get(document, "document_id", "")
document_type := object.get(document, "document_type", "")
document_hash := object.get(document, "document_hash", "")
document_complete := document_id != "" and document_type != "" and document_hash != ""

# ── Temporalny rejestr gminny ─────────────────────────────────────────────────
requested_gmina := object.get(ctx, "gmina", "")
requested_territory := object.get(ctx, "territory_code", "")
local_registry := object.get(ctx, "local_rate_registry", [])
local_candidates := [entry |
    entry := local_registry[_]
    object.get(entry, "gmina", "") == requested_gmina
    object.get(entry, "territory_code", "") == requested_territory
    object.get(entry, "resolution_id", "") != ""
    object.get(entry, "resolution_date", "") != ""
    object.get(entry, "source_ref", "") != ""
    object.get(entry, "valid_from", "") != ""
    object.get(entry, "valid_from", "") <= evaluation_date
    object.get(entry, "valid_to", "9999-12-31") >= evaluation_date
]
local_registry_match := count(local_candidates) == 1
selected_local_rate := local_candidates[0] if {
    local_registry_match
} else := {} if {
    true
}
local_rate_gmina := object.get(selected_local_rate, "gmina", "")
local_rate_territory := object.get(selected_local_rate, "territory_code", "")
local_rate_unit := object.get(selected_local_rate, "unit", "")
local_gmina_mismatch := requested_gmina == "" or requested_territory == "" or
    (local_rate_gmina != "" and local_rate_gmina != requested_gmina) or
    (local_rate_territory != "" and local_rate_territory != requested_territory)
local_evidence_complete := local_registry_match and not local_gmina_mismatch and local_rate_unit != ""

# ── PCC: przedmiot, VAT/PCC, PCC-3, stawka i dowód umowy ──────────────────────
pcc := object.get(ctx, "pcc", {})
pcc_type := object.get(pcc, "transaction_type", "")
pcc_amount := object.get(pcc, "amount", 0)
pcc_vat_applies := object.get(pcc, "vat_applies", false)
pcc_subject_verified := object.get(pcc, "subject_verified", false)
pcc_rate_registry := object.get(_et19, "pcc_rates", {})
pcc_rate := object.get(pcc_rate_registry, pcc_type, 0)
pcc_vat_excluded := pcc_vat_applies
pcc_small_exemption := pcc_amount <= object.get(_et19, "pcc_exemption_limit", 1000)
pcc_family_exemption := pcc_type == "LOAN" and object.get(pcc, "family_loan", false) and pcc_amount <= object.get(_et19, "family_loan_limit", 36120)
pcc_due := 0 if {
    pcc_vat_excluded or pcc_small_exemption or pcc_family_exemption
} else := pcc_amount * pcc_rate if {
    true
}
pcc3_required := domain == "PCC" and pcc_subject_verified and not pcc_vat_excluded and pcc_rate > 0 and not pcc_small_exemption and not pcc_family_exemption

# ── Podatki lokalne: nieruchomość, DN-1, transport i DT-1 ────────────────────
property := object.get(ctx, "property", {})
property_area := object.get(property, "area_m2", 0)
property_unit := object.get(property, "unit", "")
property_type := object.get(property, "property_type", "")
property_rate := object.get(selected_local_rate, property_type, 0)
property_calculation_ready := domain == "REAL_ESTATE" and local_evidence_complete and property_area >= 0 and property_unit == "PLN_PER_M2"
property_tax_due := property_area * property_rate if {
    property_calculation_ready
} else := 0

dn1_filed := object.get(property, "dn1_filed", false)
dn1_required := domain == "REAL_ESTATE" and property_calculation_ready and not dn1_filed

transport := object.get(ctx, "transport", {})
gvw_t := object.get(transport, "gvw_t", 0)
transport_taxable := gvw_t > transport_threshold_t
transport_unit := object.get(transport, "unit", "")
dt1_required := domain == "TRANSPORT" and transport_taxable and transport_unit == "TONNES" and not object.get(transport, "dt1_filed", false)

# ── Akcyza: CN/produkt, stawka, e-DD, skład i znaki ──────────────────────────
excise := object.get(ctx, "excise", {})
product_classified := object.get(excise, "classification_verified", false)
product_type := object.get(excise, "product_type", "")
product_rate := object.get(object.get(_et19, "excise_rates", {}), product_type, 0)
excise_quantity := object.get(excise, "quantity", 0)
excise_unit := object.get(excise, "unit", "")
excise_known := product_classified and product_type != "" and product_rate > 0
excise_due := excise_quantity * product_rate if {
    excise_known
} else := 0
warehouse_required := object.get(excise, "warehouse_required", false)
warehouse_evidence := not warehouse_required or object.get(excise, "warehouse_id", "") != ""
stamps_required := object.get(excise, "stamps_required", false)
stamps_evidence := not stamps_required or object.get(excise, "stamps_document_id", "") != ""
e_dd_required := domain == "EXCISE" and excise_known
edd_evidence := not e_dd_required or object.get(excise, "e_dd_id", "") != ""
exemption_claimed := object.get(excise, "exemption_claimed", false)
exemption_evidence := not exemption_claimed or object.get(excise, "exemption_basis", "") != "" and object.get(excise, "exemption_document_id", "") != ""

# ── Wspólne bramy evidence-first / fail-closed ───────────────────────────────
context_complete := domain in {"PCC", "REAL_ESTATE", "TRANSPORT", "EXCISE"} and evaluation_date != "" and facts_version != "" and threshold_version != ""
source_complete := count(source_refs) > 0 and count(legal_nodes) > 0
local_required := domain in {"REAL_ESTATE", "TRANSPORT"}
local_gate_ok := not local_required or local_evidence_complete
document_required := domain in {"PCC", "REAL_ESTATE", "TRANSPORT", "EXCISE"}
classification_ambiguous := domain == "EXCISE" and not product_classified
excise_gate_ok := domain != "EXCISE" or (excise_known and warehouse_evidence and stamps_evidence and edd_evidence and exemption_evidence and excise_unit != "")
manual_review_required := not owner_approval or domain in {"PCC", "EXCISE"} or classification_ambiguous or exemption_claimed
hard_block := not context_complete or not source_complete or not document_complete or not local_gate_ok or local_gmina_mismatch or (domain == "EXCISE" and not excise_gate_ok)
routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE" if {
    manual_review_required or pcc_vat_excluded or dn1_required or dt1_required
} else := "" if {
    true
}

registry_certificate := {
    "registry_version": registry_version,
    "gmina": requested_gmina,
    "territory_code": requested_territory,
    "match_count": count(local_candidates),
    "scope_match": local_evidence_complete,
    "resolution_id": object.get(selected_local_rate, "resolution_id", ""),
    "resolution_date": object.get(selected_local_rate, "resolution_date", ""),
    "valid_from": object.get(selected_local_rate, "valid_from", ""),
    "valid_to": object.get(selected_local_rate, "valid_to", null),
    "unit": local_rate_unit,
    "source_ref": object.get(selected_local_rate, "source_ref", ""),
}

pcc_certificate := {
    "subject_verified": pcc_subject_verified,
    "transaction_type": pcc_type,
    "amount": pcc_amount,
    "vat_applies": pcc_vat_applies,
    "pcc_excluded_by_vat": pcc_vat_excluded,
    "rate": pcc_rate,
    "tax_due": pcc_due,
    "pcc3_required": pcc3_required,
    "pcc3_deadline_days": pcc3_days,
    "form": "PCC-3/PCC-3A" if {pcc3_required} else "NOT_REQUIRED_OR_MANUAL_REVIEW",
}

local_certificate := {
    "property_type": property_type,
    "property_area": property_area,
    "property_unit": property_unit,
    "property_rate": property_rate,
    "property_tax_due": property_tax_due,
    "dn1_required": dn1_required,
    "dn1_deadline_days": dn1_days,
    "dn1_form": "DN-1",
    "transport_gvw_t": gvw_t,
    "transport_threshold_t": transport_threshold_t,
    "transport_taxable": transport_taxable,
    "dt1_required": dt1_required,
    "dt1_form": "DT-1",
}

excise_certificate := {
    "product_type": product_type,
    "classification_verified": product_classified,
    "quantity": excise_quantity,
    "unit": excise_unit,
    "rate": product_rate,
    "duty_due": excise_due,
    "warehouse_required": warehouse_required,
    "warehouse_evidence": warehouse_evidence,
    "stamps_required": stamps_required,
    "stamps_evidence": stamps_evidence,
    "e_dd_required": e_dd_required,
    "e_dd_evidence": edd_evidence,
    "exemption_claimed": exemption_claimed,
    "exemption_evidence": exemption_evidence,
}

ambiguities := ["MISSING_CONTEXT" | not context_complete] ++
    ["MISSING_SOURCE_OR_LEGAL_TRACE" | not source_complete] ++
    ["MISSING_DOCUMENT_EVIDENCE" | not document_complete] ++
    ["GMINA_OR_TERRITORY_MISMATCH" | local_gmina_mismatch] ++
    ["LOCAL_RESOLUTION_NOT_UNIQUE" | local_required and not local_registry_match] ++
    ["EXCISE_CLASSIFICATION_UNVERIFIED" | classification_ambiguous] ++
    ["EXCISE_EVIDENCE_INCOMPLETE" | domain == "EXCISE" and not excise_gate_ok] ++
    ["OWNER_APPROVAL_MISSING" | not owner_approval]

# ETAP 19: jedna sugestia z trzema certyfikatami domenowymi; nigdy AUTO_POST.
decide := {
    "matched": true,
    "rule_id": "jdg.local_excise_etap19.pcc_local_excise_verdict",
    "package": "jdg.local_excise_etap19",
    "priority": 19001,
    "stage": "ETAP_19",
    "decision_mode": "SUGGEST",
    "valid_from": valid_from,
    "valid_to": valid_to,
    "registry_certificate": registry_certificate,
    "pcc_certificate": pcc_certificate,
    "local_certificate": local_certificate,
    "excise_certificate": excise_certificate,
    "required_document": {"document_id": document_id, "document_type": document_type, "document_hash": document_hash},
    "legal_traceability": legal_nodes,
    "source_refs": source_refs,
    "versions": {"registry": registry_version, "legal_basis": legal_version, "evaluation_date": evaluation_date, "facts_version": facts_version, "threshold_version": threshold_version},
    "ambiguities": ambiguities,
    "manual_review_required": manual_review_required,
    "_routing": routing,
    "_routing_reason": "ETAP 19: PCC/VAT, stawka lokalna i akcyza wymagają właściwego terytorium, uchwały, dokumentu, źródła i aktualności; brak dowodu blokuje.",
    "_legal_basis": "ustawa o PCC art. 1, 2 pkt 4, 6-10; ustawa o podatkach i opłatach lokalnych art. 2-9, 12; ustawa o podatku akcyzowym art. 8-11, 16, 30-32, 89, 93-100, 114-118; KKS art. 65",
    "_warnings": ["Nie stanowi porady prawnej.", "Nie składa PCC-3, DN-1/DT-1 ani nie wysyła e-DD.", "Stawka gminna jest ważna wyłącznie dla wskazanej gminy, terytorium, uchwały i okresu."],
    "no_auto_post": true,
} {
    object.get(object.get(input, "jdg_entrepreneur", {}), "local_excise_etap19_check", false) == true
}
