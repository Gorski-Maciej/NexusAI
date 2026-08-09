# NexusAI JDG — Enterprise Interest Calculator.
# Package: jdg.interest_calculator. Legacy metadata retained as comments.

package jdg.interest_calculator

import data.jdg.thresholds
import future.keywords.if

default decide := {
    "matched": false,
    "rule_id": "jdg.interest_calculator.no_match",
    "package": "jdg.interest_calculator",
    "priority": 9999,
}

get_reference_rate() := object.get(thresholds.ord, "tax_interest_rate", 0.145)
bool_text(value) := sprintf("%v", [value])
bool_not(value) := object.get({"true": false, "false": true}, bool_text(value), false)
both_true(a, b) := object.get({"true|true": true}, sprintf("%v|%v", [a, b]), false)

rate_for(violation, base) := base * 0.50 if {
    violation == "CORRECTION_7DAYS"
} else := base * 1.50 if {
    violation == "VAT_UNDERSTATED"
} else := base if {
    true
}

label_for(violation) := "obniżona (korekta+7dni)" if {
    violation == "CORRECTION_7DAYS"
} else := "podwyższona (150% — VAT)" if {
    violation == "VAT_UNDERSTATED"
} else := "podstawowa (200% lombardu)" if {
    true
}

# INT-3060: interest rates.
decide := {
    "matched": true,
    "rule_id": "jdg.interest_calculator.rate_calculator",
    "package": "jdg.interest_calculator",
    "priority": 3060,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "int_reference_rate": reference_rate,
    "int_base_rate_200pct": base_rate,
    "int_reduced_rate_50pct": reduced_rate,
    "int_increased_rate_150pct": increased_rate,
    "int_prolongation_rate_50pct_of_base": prolongation_rate,
    "int_overpayment_rate_lombard_plus_2pp": overpayment_rate,
    "_routing": "",
    "_routing_reason": sprintf("Stopy: lombard %.1f%% → bazowa %.1f%% / obniżona %.1f%% / podwyższona %.1f%%", [reference_rate * 100, base_rate * 100, reduced_rate * 100, increased_rate * 100]),
    "_legal_basis": "Art. 53-56 OrdPU; Art. 67b OrdPU; Art. 78 OrdPU",
    "_warnings": [sprintf("KALKULATOR ODSETEK: bazowa %.2f%%, obniżona %.2f%%, podwyższona %.2f%%.", [base_rate * 100, reduced_rate * 100, increased_rate * 100])],
} if {
    input.interest_calculator_check == true
    reference_rate := get_reference_rate()
    base_rate := reference_rate * 2
    reduced_rate := base_rate * 0.5
    increased_rate := base_rate * 1.5
    prolongation_rate := base_rate * 0.5
    overpayment_rate := reference_rate + 0.02
} else := {
    "matched": true,
    "rule_id": "jdg.interest_calculator.amount_calculator",
    "package": "jdg.interest_calculator",
    "priority": 3070,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "int_principal_amount": principal,
    "int_days_late": days_late,
    "int_applicable_rate": applicable_rate,
    "int_rate_label": rate_label,
    "int_interest_accrued": interest,
    "int_total_to_pay": total,
    "int_7day_correction_eligible": correction_eligible,
    "int_7day_savings": correction_savings,
    "_routing": int_routing,
    "_routing_reason": int_reason,
    "_legal_basis": "Art. 56 § 1-1a OrdPU; Art. 56b OrdPU",
    "_warnings": [sprintf("Odsetki %.0f PLN; łącznie %.0f PLN; stawka %s.", [interest, total, rate_label])],
} if {
    input.interest_amount_calculate == true
    principal := object.get(input, "int_principal_pln", 0)
    days_late := object.get(input, "int_days_late", 0)
    violation := object.get(input, "int_violation_type", "STANDARD")
    base_rate := get_reference_rate() * 2
    applicable_rate := rate_for(violation, base_rate)
    rate_label := label_for(violation)
    interest := principal * applicable_rate * days_late / 365
    total := principal + interest
    correction_eligible := both_true(violation == "STANDARD", days_late > 0)
    correction_savings := object.get({"true": interest * 0.5, "false": 0}, bool_text(correction_eligible), 0)
    int_routing := object.get({"true": "TRIAGE_QUEUE", "false": ""}, bool_text(both_true(correction_eligible, correction_savings > 1000)), "")
    int_reason := object.get({"true": sprintf("Korekta może oszczędzić %.0f PLN.", [correction_savings]), "false": ""}, bool_text(correction_eligible), "")
} else := {
    "matched": true,
    "rule_id": "jdg.interest_calculator.cashflow_optimizer",
    "package": "jdg.interest_calculator",
    "priority": 3080,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "int_optimize_pay_now_cost": pay_now,
    "int_optimize_pay_later_cost": pay_later,
    "int_optimize_best_date": best_date,
    "int_optimize_savings": savings,
    "_routing": "",
    "_routing_reason": sprintf("Optymalna data: %s — oszczędność %.0f PLN.", [best_date, savings]),
    "_legal_basis": "Art. 53-56 OrdPU",
    "_warnings": [sprintf("Optymalizacja wpłaty %.0f PLN: dziś %.0f PLN, później %.0f PLN.", [principal, pay_now, pay_later])],
} if {
    input.interest_cashflow_optimize == true
    principal := object.get(input, "int_principal_pln", 0)
    days_until_deadline := object.get(input, "int_days_to_deadline", 25)
    current_day := object.get(input, "int_current_day", 0)
    max_delay := max([days_until_deadline - current_day, 0])
    base_rate := get_reference_rate() * 2
    pay_now := 0
    pay_later := principal * base_rate * max_delay / 365
    mid_days := floor(max_delay / 2)
    pay_mid := principal * base_rate * mid_days / 365
    best_date := sprintf("w połowie okresu (dzień %d)", [mid_days])
    savings := pay_later - pay_mid
}
