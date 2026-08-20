# NexusAI JDG — ETAP 11 PIT Micro Reliefs evidence package
# Covers qualification, limits, documents, exclusions, accumulation, temporal
# validity and what-if optimization. Activates only with pit_micro_reliefs_etap11_check.
# It is SUGGEST-only: no optimization is allowed when formal evidence is missing.

package jdg.pit_micro_reliefs_etap11

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.pit_micro_reliefs_etap11.no_match",
    "package": "jdg.pit_micro_reliefs_etap11",
    "priority": 550
}

_thresholds := object.get(data, "jdg", {})
_pit := object.get(_thresholds, "thresholds", {})
_pit_relief := object.get(_pit, "pit", {})

relief_registry := {
    "BR": {"legal_node": "Art. 26e PIT", "documents": ["BR_EVIDENCE", "COST_REGISTER", "SEPARATE_RECORD"], "exclusions": ["NO_RESEARCH_ACTIVITY", "MISSING_COST_PROOF"]},
    "IP_BOX": {"legal_node": "Art. 30ca-30cb PIT", "documents": ["NEXUS_REGISTER", "QUALIFIED_IP_PROOF", "SEPARATE_INCOME_RECORD"], "exclusions": ["NO_QUALIFIED_IP", "NEXUS_RATIO_MISSING"]},
    "THERMO": {"legal_node": "Art. 26h PIT", "documents": ["INVOICE", "PROPERTY_TITLE", "PROJECT_COMPLETION_PROOF"], "exclusions": ["NO_OWNERSHIP", "PROJECT_NOT_COMPLETED"]},
    "PROTOTYPE": {"legal_node": "Art. 26eb PIT", "documents": ["PROTOTYPE_COST_REGISTER", "PRODUCT_LAUNCH_PROOF"], "exclusions": ["NO_NEW_PRODUCT", "COST_ALREADY_DEDUCTED"]},
    "ROBOTIZATION": {"legal_node": "Art. 26gb PIT", "documents": ["ROBOT_SPECIFICATION", "PURCHASE_INVOICE", "ROBOTIZATION_REGISTER"], "exclusions": ["NOT_QUALIFIED_ROBOT", "NO_USE_IN_BUSINESS"]},
    "EXPANSION": {"legal_node": "Art. 26ec PIT", "documents": ["SALES_GROWTH_PROOF", "EXPANSION_COST_REGISTER", "MARKET_DOCUMENTS"], "exclusions": ["NO_NEW_MARKET", "NO_SALES_EVIDENCE"]},
    "DONATION": {"legal_node": "Art. 26 ust. 1 pkt 9 PIT", "documents": ["DONATION_CONFIRMATION", "RECIPIENT_STATUS", "PAYMENT_PROOF"], "exclusions": ["NON_QUALIFIED_RECIPIENT", "CASH_WITHOUT_PROOF"]},
    "FAMILY_4PLUS": {"legal_node": "Art. 21 ust. 1 pkt 153 PIT", "documents": ["CHILD_STATUS_PROOF", "FAMILY_DECLARATION", "INCOME_SOURCE_PROOF"], "exclusions": ["FEWER_THAN_FOUR_CHILDREN", "LIMIT_EXCEEDED"]},
    "CHILD": {"legal_node": "Art. 27f PIT", "documents": ["CHILD_STATUS_PROOF", "CARE_CONFIRMATION", "INCOME_LIMIT_CHECK"], "exclusions": ["NO_CARE_RIGHT", "INCOME_LIMIT_EXCEEDED"]},
    "LOSS": {"legal_node": "Art. 9 ust. 3-6 PIT", "documents": ["PRIOR_RETURN", "LOSS_REGISTER", "YEAR_OF_ORIGIN_PROOF"], "exclusions": ["LOSS_EXPIRED", "NO_PRIOR_RETURN"]}
}

reliefs_input := object.get(input, "pit_reliefs", {})
requested_reliefs := object.get(input, "pit_reliefs_requested", [])
evaluation_date := object.get(input, "evaluation_datetime", "")
threshold_version := object.get(_pit, "threshold_version", object.get(_thresholds, "version", "UNKNOWN"))
source_complete := evaluation_date != "" and threshold_version != "UNKNOWN"

relief_record(id) := object.get(reliefs_input, id, {})
relief_eligible(id) := object.get(relief_record(id), "eligible", false) == true
relief_documents_complete(id) := object.get(relief_record(id), "documents_complete", false) == true
relief_legal_node(id) := object.get(relief_record(id), "legal_node", "") != ""
relief_calculation_complete(id) := object.get(relief_record(id), "calculation_complete", false) == true
relief_tested(id) := object.get(relief_record(id), "tested", false) == true
relief_confidence(id) := to_number(object.get(relief_record(id), "confidence", 0))
relief_manual_review(id) := object.get(relief_record(id), "manual_review", false) == true

eligible_reliefs := [id |
    some id in object.keys(relief_registry)
    relief_eligible(id)
    relief_documents_complete(id)
    relief_legal_node(id)
    relief_calculation_complete(id)
    relief_tested(id)
    not relief_manual_review(id)
]

blocked_base := [id |
    some id in object.keys(relief_registry)
    not relief_eligible(id)
]

blocked_missing_documents := [id |
    some id in object.keys(relief_registry)
    relief_eligible(id)
    not relief_documents_complete(id)
]

blocked_missing_legal_node := [id |
    some id in object.keys(relief_registry)
    relief_eligible(id)
    relief_documents_complete(id)
    not relief_legal_node(id)
]

blocked_missing_calculation := [id |
    some id in object.keys(relief_registry)
    relief_eligible(id)
    relief_documents_complete(id)
    relief_legal_node(id)
    not relief_calculation_complete(id)
]

blocked_reliefs := array.concat(blocked_base, array.concat(blocked_missing_documents, array.concat(blocked_missing_legal_node, blocked_missing_calculation)))

manual_review_reliefs := [id |
    some id in object.keys(relief_registry)
    relief_eligible(id)
    relief_confidence(id) < 0.90
]

legal_source_status := "PRESENT" {
    source_complete
} else := "REVIEW_REQUIRED" {
    true
}

evidence_status(id) := "ELIGIBLE" {
    id in eligible_reliefs
} else := "BLOCKED" {
    id in blocked_reliefs
} else := "MANUAL_REVIEW" {
    id in manual_review_reliefs
} else := "NOT_REQUESTED" {
    true
}

# B+R and IP Box can coexist only when the income streams are separated.
rd_ipbox_conflict := "BR_IP_BOX_SAME_INCOME" {
    "BR" in requested_reliefs
    "IP_BOX" in requested_reliefs
    object.get(input, "relief_income_separation", "MISSING") != "CONFIRMED"
} else := "" {
    true
}

form_conflicts := [id |
    some id in requested_reliefs
    object.get(input.jdg_entrepreneur, "tax_form", "") == "LUMP_SUM"
    id in {"BR", "IP_BOX", "PROTOTYPE", "ROBOTIZATION", "EXPANSION", "LOSS"}
]

accumulation_total := sum([to_number(object.get(relief_record(id), "claimed_amount", 0)) |
    some id in eligible_reliefs
])
annual_income := to_number(object.get(input.jdg_entrepreneur, "annual_taxable_income", 0))
accumulation_exceeded := accumulation_total > annual_income and annual_income > 0

# What-if values are supplied by the host after legal eligibility filtering.
what_if_candidates := [
    {"id": "BR", "saving": to_number(object.get(object.get(input, "pit_relief_what_if", {}), "BR", 0))},
    {"id": "IP_BOX", "saving": to_number(object.get(object.get(input, "pit_relief_what_if", {}), "IP_BOX", 0))},
    {"id": "THERMO", "saving": to_number(object.get(object.get(input, "pit_relief_what_if", {}), "THERMO", 0))},
    {"id": "PROTOTYPE", "saving": to_number(object.get(object.get(input, "pit_relief_what_if", {}), "PROTOTYPE", 0))},
    {"id": "ROBOTIZATION", "saving": to_number(object.get(object.get(input, "pit_relief_what_if", {}), "ROBOTIZATION", 0))},
    {"id": "EXPANSION", "saving": to_number(object.get(object.get(input, "pit_relief_what_if", {}), "EXPANSION", 0))},
    {"id": "DONATION", "saving": to_number(object.get(object.get(input, "pit_relief_what_if", {}), "DONATION", 0))}
]

what_if_pairs := sort([[-1 * c.saving, c.id] |
    some c in what_if_candidates
    c.id in eligible_reliefs
])

what_if_best := {"id": "NONE", "saving": 0} {
    count(what_if_pairs) == 0
} else := {"id": what_if_pairs[0][1], "saving": -1 * what_if_pairs[0][0]} {
    count(what_if_pairs) > 0
}

blocked_requested := [id |
    some id in requested_reliefs
    id in blocked_reliefs
]

route := "BLOCK_AND_ALERT" {
    count(blocked_requested) > 0
} else := "BLOCK_AND_ALERT" {
    count(form_conflicts) > 0
} else := "BLOCK_AND_ALERT" {
    rd_ipbox_conflict != ""
} else := "BLOCK_AND_ALERT" {
    accumulation_exceeded
} else := "TRIAGE_QUEUE" {
    count(manual_review_reliefs) > 0
} else := "TRIAGE_QUEUE" {
    not source_complete
} else := "REPORT" {
    true
}

optimization_allowed := true {
    count(blocked_requested) == 0
    count(form_conflicts) == 0
    rd_ipbox_conflict == ""
    not accumulation_exceeded
    count(manual_review_reliefs) == 0
    source_complete
} else := false {
    true
}

evidence_pack := [{
    "relief_id": id,
    "legal_node": object.get(relief_record(id), "legal_node", ""),
    "facts": object.get(relief_record(id), "facts", {}),
    "documents": object.get(relief_record(id), "documents", []),
    "required_documents": relief_registry[id].documents,
    "calculation": object.get(relief_record(id), "calculation", {}),
    "tests": object.get(relief_record(id), "tests", []),
    "confidence": relief_confidence(id),
    "manual_review": relief_manual_review(id),
    "status": evidence_status(id)
} |
    some id in object.keys(relief_registry)
]

# Atomic evidence output. A valid optimization cannot be emitted without all
# formal conditions, while the report remains available for audit and review.
decide := {
    "matched": true,
    "rule_id": "jdg.pit_micro_reliefs_etap11.relief_evidence_audit",
    "package": "jdg.pit_micro_reliefs_etap11",
    "priority": 550,
    "decision_mode": "SUGGEST",
    "_routing": route,
    "_routing_reason": "ETAP 11: kwalifikacja ulg wymaga legal node, faktów, dokumentów, obliczenia, testu i confidence",
    "_legal_basis": "Art. 9, 21, 26, 26e, 26eb, 26ec, 26gb, 26h, 27f, 30ca-30cb PIT",
    "_temporal": {"valid_from": evaluation_date, "valid_to": null, "threshold_version": threshold_version},
    "_manual_review": manual_review_reliefs,
    "_legal_source": {"registry": "Bbb/LKG", "status": legal_source_status, "thresholds": "data.jdg.thresholds"},
    "pit_micro_reliefs": {
        "registry_count": count(object.keys(relief_registry)),
        "requested": requested_reliefs,
        "eligible": eligible_reliefs,
        "blocked": blocked_requested,
        "evidence_pack": evidence_pack,
        "what_if": {"candidates": what_if_candidates, "best": what_if_best, "allowed": optimization_allowed},
        "accumulation": {"claimed_total": accumulation_total, "income": annual_income, "exceeded": accumulation_exceeded},
        "conflicts": {"rd_ipbox": rd_ipbox_conflict, "lump_sum": form_conflicts},
        "innovations": ["atomic_evidence_pack", "formal_qualification_gate", "document_completeness_gate", "confidence_and_manual_review", "relief_conflict_detector", "what_if_after_eligibility", "temporal_relief_snapshot", "no_auto_post"]
    },
    "_warnings": ["ETAP 11: brak formalnego dowodu blokuje optymalizację; wynik nie jest poradą prawną."]
} {
    object.get(input, "pit_micro_reliefs_etap11_check", false) == true
}
