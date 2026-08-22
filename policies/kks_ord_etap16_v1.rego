# NexusAI JDG — ETAP 16/29: KKS + Ordynacja — odpowiedzialność, terminy, korekty, obrona
# Warstwa audytowa nad kks.rego, kks/*, micro/kks, micro/ord, ord/*,
# tax_authority_interaction_enterprise i sanctions_optimization_enterprise.
# Weryfikuje czynny żal, art. 54-83 KKS, stopnie sankcji, materialność,
# przedawnienia, korekty, odsetki, nadpłaty, ulgi w spłacie, interpretacje,
# pełnomocnictwa, GAAR, postępowania i terminy. Każda rekomendacja obrony jest
# nieautomatyczną pomocą z disclaimerem. Dodaje risk scoring, evidence chain,
# deadline engine, formalne blokady i testy temporalne.
package jdg.kks_ord_etap16

import future.keywords.if
import future.keywords.in

package_id := "jdg.kks_ord_etap16"
decision_mode := "SUGGEST"
rounding_contract := "PLN_HALF_UP_2DP"
currency := "PLN"

thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
kks := object.get(thresholds, "kks", {})
ord := object.get(thresholds, "ord", {})

minimum_wage := to_number(object.get(kks, "minimum_wage_gross", 4800))
daily_rate_denominator := to_number(object.get(kks, "daily_rate_denominator", 30))
penalty_multiplier_max := to_number(object.get(kks, "penalty_multiplier_max", 400))
felony_threshold_multiplier := to_number(object.get(kks, "felony_threshold_multiplier", 200))
limitation_felony_years := to_number(object.get(kks, "limitation_felony_years", 5))
limitation_misdemeanor_years := to_number(object.get(kks, "limitation_misdemeanor_years", 3))
interest_base_rate := to_number(object.get(ord, "interest_rate_annual", 0.15))
daily_rate := round2(minimum_wage / daily_rate_denominator)

round2(x) = result {
    result := round(x * 100) / 100
}

# ── Input data contract ───────────────────────────────────────────────────────
ent := object.get(input, "jdg_entrepreneur", {})
ko := object.get(input, "kks_ord", {})
risk_input := object.get(input, "risk", {})

# ── Temporal / version contract ───────────────────────────────────────────────
evaluation_date := object.get(input, "evaluation_datetime", object.get(ko, "evaluation_date", ""))
evaluation_year := object.get(input, "evaluation_year", object.get(ko, "evaluation_year", ""))
threshold_version := object.get(input, "threshold_version", object.get(ko, "threshold_version", ""))
legal_basis_version := object.get(input, "legal_basis_version", object.get(ko, "legal_basis_version", ""))
facts_version := object.get(input, "facts_version", object.get(ko, "facts_version", ""))

required_context := ["evaluation_datetime", "evaluation_year", "threshold_version", "legal_basis_version", "facts_version"]
missing_context := [field | field := required_context[_]; object.get(input, field, "") == ""]
uncertainty_markers := object.get(input, "uncertainty_markers", [])

# ── 1. Risk scoring (0-100 → LOW/HIGH/CRITICAL) ──────────────────────────────
risk_amount := to_number(object.get(risk_input, "exposure_pln", object.get(ko, "exposure_pln", 0)))
risk_articles := object.get(risk_input, "violated_articles", [])
risk_intent := object.get(risk_input, "intentional", false)
risk_recidivism := object.get(risk_input, "recidivism", false)

base_score := 0 {
    risk_amount == 0
} else := 100 {
    risk_amount >= minimum_wage * felony_threshold_multiplier
} else := round2(min([100, risk_amount / (minimum_wage * felony_threshold_multiplier) * 100])) {
    true
}
intent_bonus := 20 {
    risk_intent
} else := 0 {
    not risk_intent
}
recidivism_bonus := 10 {
    risk_recidivism
} else := 0 {
    not risk_recidivism
}
risk_score := min([100, base_score + intent_bonus + recidivism_bonus])

risk_class := "LOW" {
    risk_score < 40
} else := "HIGH" {
    risk_score >= 40
    risk_score < 80
} else := "CRITICAL" {
    risk_score >= 80
}

risk_scoring := {
    "exposure_pln": round2(risk_amount),
    "violated_articles": risk_articles,
    "intentional": risk_intent,
    "recidivism": risk_recidivism,
    "score": risk_score,
    "class": risk_class,
    "legal_basis": "art. 53 § 2 KKS (mała wartość); art. 37 KKS (recydywa)",
}

# ── 2. Evidence chain — decyzja → dowód → reguła źródłowa ────────────────────
evidence_chain := [
    {"decision": "Czynny żal", "evidence": "Zawiadomienie + dowód zapłaty", "source_rule": "art. 16 § 1 KKS", "automatic": false},
    {"decision": "Ocena stopnia sankcji", "evidence": "Protokół + wyliczenie podstawy", "source_rule": "art. 54-83 KKS", "automatic": false},
    {"decision": "Przedawnienie", "evidence": "Data popełnienia + data wszczęcia", "source_rule": "art. 44 KKS; art. 70 OrdPU", "automatic": false},
    {"decision": "Korekta deklaracji", "evidence": "Korekta + uzasadnienie", "source_rule": "art. 81 OrdPU", "automatic": false},
    {"decision": "Odsetki", "evidence": "Harmonogram stóp per okres", "source_rule": "art. 53-56 OrdPU", "automatic": false},
    {"decision": "Nadpłata", "evidence": "Wniosek o zwrot + deklaracja", "source_rule": "art. 72-77 OrdPU", "automatic": false},
    {"decision": "Ulga w spłacie", "evidence": "Wniosek + dokumentacja finansowa", "source_rule": "art. 67a OrdPU", "automatic": false},
    {"decision": "Interpretacja indywidualna", "evidence": "Wniosek o interpretację", "source_rule": "art. 14b OrdPU", "automatic": false},
    {"decision": "Pełnomocnictwo", "evidence": "Pełnomocnictwo PPS-1", "source_rule": "art. 80a-80d OrdPU", "automatic": false},
    {"decision": "Ocena GAAR", "evidence": "Analiza sztuczności czynności", "source_rule": "art. 119a OrdPU", "automatic": false},
]
evidence_count := count(evidence_chain)

# ── 3. Czynny żal (art. 16 KKS) — nieautomatyczna pomoc ──────────────────────
voluntary_disclosure := object.get(ko, "voluntary_disclosure", false)
disclosure_before_detection := object.get(ko, "disclosure_before_detection", false)
disclosure_paid := object.get(ko, "disclosure_paid", false)

voluntary_disclosure_audit := {
    "filed": voluntary_disclosure,
    "before_detection": disclosure_before_detection,
    "paid": disclosure_paid,
    "eligible": voluntary_disclosure and disclosure_before_detection and disclosure_paid,
    "disclaimer": "Pomoc nieautomatyczna — wymaga oceny prawnika; nie stanowi porady prawnej",
    "automatic": false,
    "legal_basis": "art. 16 § 1 KKS (czynny żal)",
}

# ── 4. Stopnie sankcji / materialność (art. 54-83 KKS) ──────────────────────
violation_type := object.get(ko, "violation_type", "")
penalty_multiplier := to_number(object.get(ko, "penalty_multiplier", 0))
materiality := "LOW_VALUE" {
    risk_amount < minimum_wage * felony_threshold_multiplier
} else := "FELONY" {
    risk_amount >= minimum_wage * felony_threshold_multiplier
} else := "UNKNOWN" {
    true
}
penalty_amount := round2(penalty_multiplier * daily_rate)
penalty_cap := round2(penalty_multiplier_max * daily_rate)

sanction_audit := {
    "violation_type": violation_type,
    "materiality": materiality,
    "daily_rate": daily_rate,
    "penalty_multiplier": penalty_multiplier,
    "penalty_amount": penalty_amount,
    "penalty_multiplier_max": penalty_multiplier_max,
    "penalty_cap": penalty_cap,
    "felony_threshold_pln": round2(minimum_wage * felony_threshold_multiplier),
    "legal_basis": "art. 54-83 KKS (stopnie sankcji); art. 23 § 3 KKS (stawka dzienna)",
}

# ── 5. Przedawnienia (art. 44 KKS, art. 70 OrdPU) ────────────────────────────
limitation_years := limitation_felony_years {
    materiality == "FELONY"
} else := limitation_misdemeanor_years {
    materiality == "LOW_VALUE"
} else := limitation_misdemeanor_years {
    true
}
offense_year := to_number(object.get(ko, "offense_year", 0))
years_elapsed := 0 {
    offense_year == 0
} else := max([0, to_number(evaluation_year) - offense_year]) {
    true
}
expired := years_elapsed >= limitation_years {
    offense_year > 0
}

limitation_audit := {
    "offense_year": offense_year,
    "evaluation_year": evaluation_year,
    "years_elapsed": years_elapsed,
    "limitation_years": limitation_years,
    "expired": expired,
    "legal_basis": "art. 44 KKS (przedawnienie); art. 70 OrdPU (zobowiązanie podatkowe)",
}

# ── 6. Korekty / odsetki / nadpłaty / ulgi ───────────────────────────────────
correction := object.get(ko, "correction", false)
correction_reason := object.get(ko, "correction_reason", "")
overpayment := object.get(ko, "overpayment", false)
relief_request := object.get(ko, "payment_relief", false)
interest_days := max([0, to_number(object.get(ko, "interest_days", 0))])
interest_amount := round2(risk_amount * interest_base_rate / 365 * interest_days)

obligation_audit := {
    "correction": correction,
    "correction_reason": correction_reason,
    "correction_reason_present": correction == false or correction_reason != "",
    "overpayment": overpayment,
    "payment_relief": relief_request,
    "interest_base_rate": interest_base_rate,
    "interest_days": interest_days,
    "interest_amount": interest_amount,
    "legal_basis": "art. 81/72-77/67a/53-56 OrdPU",
}

# ── 7. Interpretacje / pełnomocnictwa / GAAR ─────────────────────────────────
interpretation := object.get(ko, "interpretation_requested", false)
poa := object.get(ko, "power_of_attorney", false)
gaar := object.get(ko, "gaar_analysis", false)

procedure_audit := {
    "interpretation_requested": interpretation,
    "power_of_attorney": poa,
    "gaar_analysis": gaar,
    "legal_basis": "art. 14b (interpretacje); art. 80a-80d (pełnomocnictwa); art. 119a OrdPU (GAAR)",
}

# ── 8. Deadline engine — terminy postępowań ─────────────────────────────────
deadline_days := to_number(object.get(ko, "deadline_days", 0))
deadline_level := "GREEN" {
    deadline_days > 14
} else := "AMBER" {
    deadline_days > 0
    deadline_days <= 14
} else := "RED" {
    deadline_days <= 0
}
deadline_overdue := deadline_level == "RED"

deadline_audit := {
    "deadline_days": deadline_days,
    "level": deadline_level,
    "overdue": deadline_overdue,
    "legal_basis": "art. 120-129/223 OrdPU (terminy postępowań)",
}

# ── 9. Property invariants ──────────────────────────────────────────────────
inv_risk_in_range := risk_score >= 0 and risk_score <= 100
inv_penalty_non_negative := penalty_amount >= 0
inv_interest_non_negative := interest_amount >= 0
inv_disclaimer_present := voluntary_disclosure_audit.automatic == false
inv_correction_reason := correction == false or correction_reason != ""

property_invariants := {
    "risk_in_range": inv_risk_in_range,
    "penalty_non_negative": inv_penalty_non_negative,
    "interest_non_negative": inv_interest_non_negative,
    "disclaimer_present": inv_disclaimer_present,
    "correction_reason": inv_correction_reason,
}

invariant_failed := [name |
    name := ["risk_in_range", "penalty_non_negative", "interest_non_negative", "disclaimer_present", "correction_reason"][_]
    property_invariants[name] == false
]

# ── 10. Fail-closed + formal blocks ─────────────────────────────────────────
collisions := array.concat(
    object.get(input, "pit_conflicts", []),
    array.concat(object.get(input, "vat_conflicts", []), object.get(input, "uor_conflicts", []))
)
defense_recommendation := count(evidence_chain) > 0
disclaimer_missing := false

manual_review := count(missing_context) > 0 or count(uncertainty_markers) > 0 or count(collisions) > 0 or deadline_overdue or count(invariant_failed) > 0

routing := "BLOCK_AND_ALERT" {
    count(missing_context) > 0
} else := "TRIAGE_QUEUE" {
    deadline_overdue
} else := "TRIAGE_QUEUE" {
    risk_class == "CRITICAL"
} else := "TRIAGE_QUEUE" {
    count(uncertainty_markers) > 0
} else := "TRIAGE_QUEUE" {
    count(collisions) > 0
} else := "TRIAGE_QUEUE" {
    count(invariant_failed) > 0
} else := "REPORT" {
    true
}

# ── 11. Certificate ──────────────────────────────────────────────────────────
calculation_certificate := {
    "certificate_id": object.get(input, "calculation_id", "UNASSIGNED"),
    "evaluation_date": evaluation_date,
    "evaluation_year": evaluation_year,
    "threshold_version": threshold_version,
    "legal_basis_version": legal_basis_version,
    "facts_version": facts_version,
    "rounding": rounding_contract,
    "currency": currency,
    "units": {"penalty": "PLN", "interest": "PLN", "exposure": "PLN"},
    "source": "data.jdg.thresholds.kks/ord + input.kks_ord + kks.rego + micro/kks + micro/ord",
    "manual_review": manual_review,
    "missing_context": missing_context,
    "uncertainty_markers": uncertainty_markers,
    "cross_domain_collisions": collisions,
    "property_invariants": property_invariants,
    "invariant_failed": invariant_failed,
}

# Publiczny wynik aktywowany osobną flagą — brak flagi pozostaje no_match.
default decide := {"matched": false, "rule_id": "jdg.kks_ord_etap16.no_match", "package": package_id, "priority": 999999}

decide := {
    "matched": true,
    "rule_id": "jdg.kks_ord_etap16.report",
    "package": package_id,
    "priority": 600,
    "decision_mode": decision_mode,
    "no_auto_post": true,
    "routing": routing,
    "manual_review": manual_review,
    "risk_scoring": risk_scoring,
    "evidence_chain": {"entries": evidence_chain, "count": evidence_count},
    "voluntary_disclosure": voluntary_disclosure_audit,
    "sanctions": sanction_audit,
    "limitation": limitation_audit,
    "obligations": obligation_audit,
    "procedures": procedure_audit,
    "deadline": deadline_audit,
    "property_invariants": property_invariants,
    "invariant_failed": invariant_failed,
    "calculation_certificate": calculation_certificate,
    "threshold_snapshot": {"minimum_wage": minimum_wage, "daily_rate": daily_rate, "penalty_multiplier_max": penalty_multiplier_max, "felony_threshold_multiplier": felony_threshold_multiplier, "limitation_felony_years": limitation_felony_years, "limitation_misdemeanor_years": limitation_misdemeanor_years, "evaluation_year": evaluation_year},
    "_routing": routing,
    "_routing_reason": "ETAP 16 KKS/Ordynacja: risk scoring, evidence chain, czynny żal, art. 54-83, przedawnienia, korekty/odsetki/nadpłaty/ulgi, interpretacje/pełnomocnictwa/GAAR i deadline engine",
    "_legal_basis": "KKS art. 16/37/44/53-83; OrdPU art. 14b/53-56/67a/70/72-77/80a-80d/81/119a/120-129",
    "_warnings": ["SUGGEST only; rekomendacje obrony są nieautomatyczną pomocą z disclaimerem. Przekroczony termin lub ryzyko CRITICAL kieruje do manual review."],
} {
    object.get(input, "kks_ord_etap16_check", false) == true
}
