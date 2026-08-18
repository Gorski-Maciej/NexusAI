# NexusAI JDG — Enterprise deadline monitor
# Calendar of upcoming PIT/VAT/ZUS payments and late-payment impact.
# Legal basis: Art. 53-56 and 67a OrdPU; Art. 103 VAT; Art. 44 PIT; Art. 18 SUS.

package jdg.deadline_monitor

import future.keywords.if

import data.jdg.thresholds

default decide := {
    "matched": false,
    "rule_id": "jdg.deadline_monitor.no_match",
    "package": "jdg.deadline_monitor",
    "priority": 9999
}

base_fields := {
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false
}

payment_list := object.get(input, "dlm_upcoming_payments", [])
payment_count := count(payment_list)

payment_total := sum([amount |
    payment := payment_list[_]
    amount := object.get(payment, "amount", 0)
])

first_payment := payment_list[0] if {
    payment_count > 0
} else := {} if {
    true
}

next_date := object.get(first_payment, "date", "—")
next_days := object.get(first_payment, "days_left", 999)
next_amount := object.get(first_payment, "amount", 0)
next_type := object.get(first_payment, "type", "")

deadline_routing(payment_days, payment_amount) := "BLOCK_AND_ALERT" if {
    payment_days <= 1
    payment_amount > 0
} else := "TRIAGE_QUEUE" if {
    payment_days <= 7
    payment_amount > 0
} else := "" if {
    true
}

deadline_reason(payment_days, payment_amount, payment_type) := sprintf("PŁATNOŚĆ JUTRO: %.0f PLN %s — przygotuj środki!", [payment_amount, payment_type]) if {
    payment_days <= 1
} else := sprintf("Płatność %.0f PLN (%s) za %d dni.", [payment_amount, payment_type, payment_days]) if {
    payment_days <= 7
} else := "" if {
    true
}

late_amount := object.get(input, "dlm_late_amount", 0)
late_days := object.get(input, "dlm_late_days", 0)
ord_thresholds := object.get(data.jdg.thresholds, "ord", {})
reference_rate := object.get(ord_thresholds, "tax_interest_rate", 0.145)
late_interest_cost := late_amount * (reference_rate * 2.00) * late_days / 365
late_penalty_risk := late_amount * 0.30
installment_eligible(amount, days) = true if {
    amount > 5000
    days > 30
} else = false if {
    true
}

installment_text(eligible) := "💡 Rozważ WNIOSEK O ROZŁOŻENIE NA RATY (Art. 67a) — opłata prolongacyjna 50% odsetek." if {
    eligible == true
} else := "" if {
    true
}

late_routing(amount) := "TRIAGE_QUEUE" if {
    amount > 0
} else := "" if {
    true
}

late_reason(amount, interest_cost) := sprintf("Opóźnienie %.0f PLN — odsetki %.0f PLN/rok. Rozważ wniosek o raty.", [amount, interest_cost]) if {
    amount > 0
} else := "" if {
    true
}

# DLM-3180: payment deadline calendar.
decide := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.deadline_monitor.payment_calendar",
    "package": "jdg.deadline_monitor",
    "priority": 3180,
    "dlm_total_upcoming_payments": payment_count,
    "dlm_total_amount_due": payment_total,
    "dlm_next_deadline_date": next_date,
    "dlm_next_deadline_days": next_days,
    "dlm_next_deadline_amount": next_amount,
    "dlm_next_deadline_type": next_type,
    "_routing": deadline_routing(next_days, next_amount),
    "_routing_reason": deadline_reason(next_days, next_amount, next_type),
    "_legal_basis": "Art. 53 OrdPU; Art. 103 VAT; Art. 44 PIT; Art. 18 SUS",
    "_warnings": [
        sprintf("📅 KALENDARZ PŁATNOŚCI — %d nadchodzących na łączną kwotę %.0f PLN", [payment_count, payment_total]),
        sprintf("   🔴 NAJBLIŻSZY: %s (za %d dni) — %s: %.0f PLN", [next_date, next_days, next_type, next_amount])
    ]
}) if {
    object.get(input, "deadline_calendar_check", false) == true
} else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.deadline_monitor.late_payment_impact",
    "package": "jdg.deadline_monitor",
    "priority": 3190,
    "dlm_late_amount": late_amount,
    "dlm_late_days": late_days,
    "dlm_late_interest_cost": late_interest_cost,
    "dlm_late_penalty_risk": late_penalty_risk,
    "dlm_installment_eligible": installment_eligible(late_amount, late_days),
    "_routing": late_routing(late_amount),
    "_routing_reason": late_reason(late_amount, late_interest_cost),
    "_legal_basis": "Art. 53-56 OrdPU (odsetki); Art. 67a OrdPU (ulgi w spłacie)",
    "_warnings": [
        sprintf("⚠️ OPÓŹNIENIE PŁATNOŚCI — %.0f PLN | %d dni po terminie", [late_amount, late_days]),
        sprintf("   Odsetki: %.0f PLN (Art. 56 OrdPU)", [late_interest_cost]),
        sprintf("   Ryzyko sankcji: %.0f PLN", [late_penalty_risk]),
        installment_text(installment_eligible(late_amount, late_days))
    ]
}) if {
    object.get(input, "deadline_late_check", false) == true
}
