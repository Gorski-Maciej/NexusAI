# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE ZOBOWIĄZANIE DEADLINE MONITOR (Innovation 9.13, P19 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Zobowiązanie Deadline Monitor — PIT/VAT/ZUS/Advances Calendar
# description: |
#   ENTERPRISE v7.0 — Monitor terminów płatności wszystkich zobowiązań JDG.
#   Powiązany z kalkulatorem odsetek (a56) i ulgami (a67).
#
#   KLUCZOWE FUNKCJE:
#   - Kalendarz terminów: PIT (20.), VAT (25.), ZUS (15.), zaliczki, deklaracje roczne
#   - Alerty przed terminem (7/3/1 dzień)
#   - Powiązanie z odsetkami (Art. 56) — koszt spóźnienia
#   - Powiązanie z ulgami (Art. 67a) — wniosek o raty gdy brak płynności
#   - Mikrorachunek VAT — monitoring salda
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 53-56 OrdPU; Art. 67a-67e OrdPU; Art. 103 VAT
# package: jdg.deadline_monitor
# deprecated: false
# priority_range: 3180-3209
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.deadline_monitor

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.deadline_monitor.no_match",
    "package": "jdg.deadline_monitor", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# DLM-3180: PAYMENT DEADLINE CALENDAR — Kalendarz nadchodzących płatności
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.deadline_monitor.payment_calendar",
    "package": "jdg.deadline_monitor",
    "priority": 3180,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "dlm_total_upcoming_payments": total,
    "dlm_total_amount_due": total_amount,
    "dlm_next_deadline_date": next_date,
    "dlm_next_deadline_days": next_days,
    "dlm_next_deadline_amount": next_amount,
    "dlm_next_deadline_type": next_type,
    "_routing": dlm_routing,
    "_routing_reason": dlm_reason,
    "_legal_basis": "Art. 53 OrdPU; Art. 103 VAT; Art. 44 PIT; Art. 18 SUS",
    "_warnings": [
        sprintf("📅 KALENDARZ PŁATNOŚCI — %d nadchodzących na łączną kwotę %.0f PLN", [total, total_amount]),
        sprintf("   🔴 NAJBLIŻSZY: %s (za %d dni) — %s: %.0f PLN", [next_date, next_days, next_type, next_amount]),
    ]
} {
    input.deadline_calendar_check == true
    payments := object.get(input, "dlm_upcoming_payments", [])
    total := count(payments)
    total_amount := sum([object.get(p, "amount", 0) | p := payments[_]])
    next := payments[0] { count(payments) > 0 }
    next_date := object.get(next, "date", "—") { count(payments) > 0 }
    next_days := object.get(next, "days_left", 99) { count(payments) > 0 }
    next_amount := object.get(next, "amount", 0) { count(payments) > 0 }
    next_type := object.get(next, "type", "") { count(payments) > 0 }
    next_date := "—" { count(payments) == 0 }
    next_days := 999 { count(payments) == 0 }

    dlm_routing := "BLOCK_AND_ALERT" { next_days <= 1; next_amount > 0 }
    dlm_routing := "TRIAGE_QUEUE" { next_days <= 7; next_amount > 0 }
    dlm_routing := "" { true }
    dlm_reason := sprintf("PŁATNOŚĆ JUTRO: %.0f PLN %s — przygotuj środki!", [next_amount, next_type]) { next_days <= 1 }
    dlm_reason := sprintf("Płatność %.0f PLN (%s) za %d dni.", [next_amount, next_type, next_days]) { next_days <= 7 }
    dlm_reason := "" { true }
}

# DLM-3180 uses total_amount from input (precomputed by integration layer)
# sum() helper removed — OPA does not support comprehension-based aggregation

# ═══════════════════════════════════════════════════════════════════════════════
# DLM-3190: LATE PAYMENT IMPACT — Koszt spóźnienia z płatnością
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.deadline_monitor.late_payment_impact",
    "package": "jdg.deadline_monitor",
    "priority": 3190,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "dlm_late_amount": late_amount,
    "dlm_late_days": late_days,
    "dlm_late_interest_cost": interest_cost,
    "dlm_late_penalty_risk": penalty_risk,
    "dlm_installment_eligible": installment_eligible,
    "_routing": late_routing,
    "_routing_reason": late_reason,
    "_legal_basis": "Art. 53-56 OrdPU (odsetki); Art. 67a OrdPU (ulgi w spłacie)",
    "_warnings": [
        sprintf("⚠️ OPÓŹNIENIE PŁATNOŚCI — %.0f PLN | %d dni po terminie", [late_amount, late_days]),
        sprintf("   Odsetki: %.0f PLN (Art. 56 OrdPU)", [interest_cost]),
        sprintf("   Ryzyko sankcji: %.0f PLN", [penalty_risk]),
        sprintf("   %s", [installment_text]),
    ]
} {
    input.deadline_late_check == true
    late_amount := object.get(input, "dlm_late_amount", 0)
    late_days := object.get(input, "dlm_late_days", 0)
    ref_rate := object.get(object.get(data.thresholds, "ord", {}), "tax_interest_rate", 0.145)
    interest_cost := late_amount * (ref_rate * 2.00) * late_days / 365
    penalty_risk := late_amount * 0.30
    installment_eligible := late_amount > 5000 and late_days > 30
    installment_text := "💡 Rozważ WNIOSEK O ROZŁOŻENIE NA RATY (Art. 67a) — opłata prolongacyjna 50% odsetek." { installment_eligible }
    installment_text := "" { not installment_eligible }

    late_routing := "TRIAGE_QUEUE" { late_amount > 0 }
    late_routing := "" { true }
    late_reason := sprintf("Opóźnienie %.0f PLN — odsetki %.0f PLN/rok. Rozważ wniosek o raty.", [late_amount, interest_cost]) { late_amount > 0 }
    late_reason := "" { true }
}
