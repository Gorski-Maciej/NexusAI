# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ETAP 18 Ryczałt / CEIDG / Prawo Przedsiębiorców / Sukcesja
# ═══════════════════════════════════════════════════════════════════════════════
# Warstwa kontrolna nad P13/R12: state machine, formularze, terminy, rollback,
# legal source i manual gate. Nie wykonuje zgłoszeń i nie stanowi porady.

package jdg.business_lifecycle_etap18

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.business_lifecycle_etap18.no_match",
    "package": "jdg.business_lifecycle_etap18",
    "priority": 999999,
    "decision_mode": "SUGGEST",
}

decision_mode := "SUGGEST"

_thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
_bl := object.get(_thresholds, "business_lifecycle", {})
state_version := object.get(_bl, "state_machine_version", "lifecycle-2026.08")
legal_version := object.get(_bl, "legal_basis_version", "isap-lkg-2026.08")
source_registry := object.get(_bl, "source_registry", "data.jdg.legal_source_registry")
suspension_max_months := object.get(_bl, "suspension_max_months", 24)
suspension_min_days := object.get(_bl, "suspension_min_days", 30)
ceidg_days := object.get(_bl, "ceidg_registration_days", 7)
succession_days := object.get(_bl, "succession_ceidg_days", 14)
growth_transition_days := object.get(_bl, "growth_transition_days", 7)
resume_days := object.get(_bl, "resume_registration_days", 7)
tax_form_change_days := object.get(_bl, "tax_form_change_days", 20)
close_notice_days := object.get(_bl, "close_notice_days", 7)
close_finalize_days := object.get(_bl, "close_finalize_days", 30)
succession_standard_months := object.get(_bl, "succession_default_months", 24)
succession_extended_months := object.get(_bl, "succession_extended_months", 60)

ctx := object.get(input, "business_lifecycle_etap18", {})
current_state := object.get(ctx, "current_state", "")
event := object.get(ctx, "event", "")
evaluation_date := object.get(ctx, "evaluation_date", "")
facts_version := object.get(ctx, "facts_version", "")
threshold_version := object.get(ctx, "threshold_version", "")
source_refs := object.get(ctx, "source_refs", [])
legal_nodes := object.get(ctx, "legal_nodes", {})
owner_approval := object.get(ctx, "owner_approval", false)
pkwiu_verified := object.get(ctx, "pkwiu_verified", false)
declared_rate := object.get(ctx, "declared_rate", null)

states := ["PRE_START", "ACTIVE_STARTUP", "ACTIVE_GROWTH", "SUSPENDED", "SUCCESSION", "TRANSITION", "CLOSING", "CLOSED"]

# Dozwolone zdarzenia i odwracalne przejścia. CLOSED jest terminalny.
transition_catalog := [
    {"from": "PRE_START", "event": "REGISTER", "to": "ACTIVE_STARTUP", "legal_basis": "CEIDG art. 5-7; SUS art. 43", "forms": ["CEIDG-1", "ZUS ZUA/ZZA", "wybór formy PIT", "VAT-R — jeżeli wymagany"], "deadline_days": ceidg_days, "deadline_unit": "days", "rollback_event": "CANCEL_REGISTRATION"},
    {"from": "ACTIVE_STARTUP", "event": "GROW", "to": "ACTIVE_GROWTH", "legal_basis": "SUS art. 18a/18c; VAT art. 113", "forms": ["ZUS ZUA — zmiana kodu", "VAT-R — po przekroczeniu limitu", "aktualizacja CEIDG"], "deadline_days": growth_transition_days, "deadline_unit": "days", "rollback_event": "PAUSE_GROWTH"},
    {"from": "ACTIVE_STARTUP", "event": "SUSPEND", "to": "SUSPENDED", "legal_basis": "Prawo przedsiębiorców art. 22-25", "forms": ["CEIDG-1 — zawieszenie", "ZUS ZWUA — zakres ubezpieczeń"], "deadline_days": suspension_min_days, "deadline_unit": "days", "rollback_event": "RESUME"},
    {"from": "ACTIVE_GROWTH", "event": "SUSPEND", "to": "SUSPENDED", "legal_basis": "Prawo przedsiębiorców art. 22-25", "forms": ["CEIDG-1 — zawieszenie", "ZUS ZWUA — zakres ubezpieczeń", "VAT — status rozliczeń"], "deadline_days": suspension_min_days, "deadline_unit": "days", "rollback_event": "RESUME"},
    {"from": "SUSPENDED", "event": "RESUME", "to": "ACTIVE_GROWTH", "legal_basis": "Prawo przedsiębiorców art. 25", "forms": ["CEIDG-1 — wznowienie", "ZUS ZUA/ZWUA — aktualizacja", "VAT-R — jeżeli zmiana statusu"], "deadline_days": resume_days, "deadline_unit": "days", "rollback_event": "SUSPEND"},
    {"from": "ACTIVE_GROWTH", "event": "SUCCESSION", "to": "SUCCESSION", "legal_basis": "ustawa o zarządzie sukcesyjnym art. 3-15", "forms": ["akt notarialny zarządcy", "CEIDG — wpis zarządcy", "zawiadomienie US/ZUS"], "deadline_days": succession_days, "deadline_unit": "days", "rollback_event": "END_SUCCESSION"},
    {"from": "SUCCESSION", "event": "END_SUCCESSION", "to": "ACTIVE_GROWTH", "legal_basis": "ustawa o zarządzie sukcesyjnym art. 12-15", "forms": ["CEIDG — zakończenie zarządu", "rozliczenie sukcesyjne"], "deadline_days": succession_standard_months, "deadline_unit": "months", "rollback_event": "SUCCESSION"},
    {"from": "ACTIVE_STARTUP", "event": "CHANGE_TAX_FORM", "to": "TRANSITION", "legal_basis": "PIT art. 9a; ustawa o ryczałcie art. 6/12", "forms": ["oświadczenie o formie PIT", "ewidencja przychodów albo PKPiR", "aktualizacja CEIDG"], "deadline_days": tax_form_change_days, "deadline_unit": "days", "rollback_event": "REVERT_TAX_FORM"},
    {"from": "ACTIVE_GROWTH", "event": "CHANGE_TAX_FORM", "to": "TRANSITION", "legal_basis": "PIT art. 9a; ustawa o ryczałcie art. 6/12", "forms": ["oświadczenie o formie PIT", "ewidencja właściwa dla formy", "aktualizacja CEIDG"], "deadline_days": tax_form_change_days, "deadline_unit": "days", "rollback_event": "REVERT_TAX_FORM"},
    {"from": "TRANSITION", "event": "CONFIRM_TAX_FORM", "to": "ACTIVE_GROWTH", "legal_basis": "PIT art. 9a; ustawa o ryczałcie art. 12", "forms": ["potwierdzenie wyboru formy", "kontrola ciągłości ewidencji"], "deadline_days": tax_form_change_days, "deadline_unit": "days", "rollback_event": "REVERT_TAX_FORM"},
    {"from": "ACTIVE_STARTUP", "event": "CLOSE", "to": "CLOSING", "legal_basis": "Prawo przedsiębiorców art. 31-36; PIT art. 24", "forms": ["CEIDG-1 — wykreślenie", "VAT-Z — jeżeli VAT", "ZUS ZWUA", "remanent likwidacyjny"], "deadline_days": close_notice_days, "deadline_unit": "days", "rollback_event": "CANCEL_CLOSURE"},
    {"from": "ACTIVE_GROWTH", "event": "CLOSE", "to": "CLOSING", "legal_basis": "Prawo przedsiębiorców art. 31-36; VAT art. 14; PIT art. 24", "forms": ["CEIDG-1 — wykreślenie", "VAT-Z", "ZUS ZWUA", "remanent likwidacyjny", "ostatni JPK/PIT"], "deadline_days": close_notice_days, "deadline_unit": "days", "rollback_event": "CANCEL_CLOSURE"},
    {"from": "CLOSING", "event": "FINALIZE_CLOSE", "to": "CLOSED", "legal_basis": "Prawo przedsiębiorców art. 31-36; OrdPU art. 86", "forms": ["ostatni JPK/PIT", "potwierdzenie archiwizacji dokumentów"], "deadline_days": close_finalize_days, "deadline_unit": "days", "rollback_event": "MANUAL_REOPEN_ONLY"},
]

matching_transitions := [t |
    t := transition_catalog[_]
    object.get(t, "from", "") == current_state
    object.get(t, "event", "") == event
]
transition_exists := count(matching_transitions) == 1
transition := matching_transitions[0] if {
    transition_exists
} else := {} if {
    true
}
next_state := object.get(transition, "to", current_state)
rollback_event := object.get(transition, "rollback_event", "MANUAL_REVIEW_REQUIRED")

context_complete := current_state != "" and event != "" and evaluation_date != "" and facts_version != "" and threshold_version != ""
source_complete := count(source_refs) > 0 and count(legal_nodes) > 0
known_state := current_state in states

# Nieznany kod PKWiU/stawka lub brak potwierdzenia nie może wybrać formy automatycznie.
rate_ambiguity := declared_rate != null and pkwiu_verified == false
invalid_transition := not transition_exists or not known_state
manual_review_required := not context_complete or not source_complete or invalid_transition or rate_ambiguity or owner_approval == false or event in {"SUCCESSION", "CHANGE_TAX_FORM", "CLOSE", "FINALIZE_CLOSE"}

routing := "BLOCK_AND_ALERT" if {
    not context_complete
} else := "BLOCK_AND_ALERT" if {
    not source_complete
} else := "BLOCK_AND_ALERT" if {
    invalid_transition
} else := "BLOCK_AND_ALERT" if {
    next_state == "CLOSED"
    owner_approval == false
} else := "TRIAGE_QUEUE" if {
    manual_review_required
} else := "" if {
    true
}

# Kalendarz wymaga potwierdzenia daty wejścia w życie; dni są parametrem, nie
# dowodem wykonania formularza.
deadline_calendar := {
    "event": event,
    "deadline_days": object.get(transition, "deadline_days", null),
    "deadline_unit": object.get(transition, "deadline_unit", "days"),
    "effective_from": object.get(_bl, "valid_from", "2025-01-01"),
    "effective_to": object.get(_bl, "valid_to", null),
    "source": source_registry,
    "status": "MANUAL_CONFIRMATION_REQUIRED" if {manual_review_required} else "READY_FOR_OWNER_REVIEW",
}

rate_registry := {
    "pkwiu_verified": pkwiu_verified,
    "declared_rate": declared_rate,
    "rate_min": object.get(_bl, "ryczalt_rate_min", null),
    "rate_max": object.get(_bl, "ryczalt_rate_max", null),
    "classification_source": "P13/R12 PKWiU classifier + owner/doradca confirmation",
    "ambiguity": rate_ambiguity,
}

state_machine := {
    "states": states,
    "current_state": current_state,
    "event": event,
    "next_state": next_state,
    "transition_valid": transition_exists and known_state,
    "transition_catalog_size": count(transition_catalog),
    "rollback_event": rollback_event,
    "terminal_state": next_state == "CLOSED",
    "suspension_max_months": suspension_max_months,
    "succession_standard_months": succession_standard_months,
    "succession_extended_months": succession_extended_months,
}

ambiguities := ["UNKNOWN_STATE" | not known_state] ++ ["INVALID_TRANSITION" | not transition_exists] ++ ["PKWIU_UNVERIFIED" | rate_ambiguity] ++ ["OWNER_APPROVAL_MISSING" | not owner_approval]

# ETAP 18 verdict: tylko sugestia / manual review, nigdy wykonanie operacji.
decide := {
    "matched": true,
    "rule_id": "jdg.business_lifecycle_etap18.state_machine_verdict",
    "package": "jdg.business_lifecycle_etap18",
    "priority": 18001,
    "stage": "ETAP_18",
    "decision_mode": "SUGGEST",
    "valid_from": object.get(_bl, "valid_from", "2025-01-01"),
    "valid_to": object.get(_bl, "valid_to", null),
    "state_machine": state_machine,
    "required_forms": object.get(transition, "forms", []),
    "deadline_calendar": deadline_calendar,
    "rate_registry": rate_registry,
    "legal_traceability": legal_nodes,
    "source_refs": source_refs,
    "versions": {"state_machine": state_version, "legal_basis": legal_version, "evaluation_date": evaluation_date, "facts_version": facts_version, "threshold_version": threshold_version},
    "ambiguities": ambiguities,
    "manual_review_required": manual_review_required,
    "_routing": routing,
    "_routing_reason": "ETAP 18: przejście cyklu życia wymaga poprawnego stanu, źródła, wersji i zatwierdzenia właściciela; brak spełnienia blokuje.",
    "_legal_basis": "CEIDG art. 5-15; Prawo przedsiębiorców art. 18, 22-25, 31-36; ustawa o ryczałcie art. 6, 8, 12, 15, 21-28; ustawa o zarządzie sukcesyjnym art. 3-15; PIT art. 9a, 24; VAT art. 14, 96, 113; SUS art. 18a/18c/43",
    "_warnings": ["Nie stanowi porady prawnej.", "Pakiet nie składa CEIDG, VAT-Z, ZUS ani oświadczeń podatkowych.", "PKWiU i wybór formy wymagają potwierdzenia właściciela/doradcy."],
    "no_auto_post": true,
} {
    object.get(object.get(input, "jdg_entrepreneur", {}), "business_lifecycle_etap18_check", false) == true
}
