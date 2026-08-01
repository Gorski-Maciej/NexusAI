# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE INTEREST CALCULATOR + OPTIMIZER (Innovation 9.8 / BP-8, P19 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Interest Calculator — Art. 53-56 OrdPU Dynamic Engine
# description: |
#   ENTERPRISE v7.0 — Dynamiczny kalkulator odsetek z referencyjną stopą NBP.
#   Wypełnia lukę L5 z raportu P19: brak dynamicznej stopy referencyjnej.
#
#   KLUCZOWE FUNKCJE:
#   - Dynamiczna stopa referencyjna (lombard NBP z thresholds)
#   - Stawka podstawowa: 200% lombardu (Art. 56 § 1)
#   - Stawka obniżona: 50% podstawowej (korekta + wpłata w 7 dni — Art. 56 § 1a)
#   - Stawka podwyższona: 150% podstawowej (VAT/PIT zaniżenie — Art. 56b)
#   - Optymalizator cashflow: minimalizacja odsetek przez timing wpłaty
#   - Kalkulator opłaty prolongacyjnej: 50% stawki odsetek (Art. 67b)
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 53-56, 56b, 67b OrdPU
# package: jdg.interest_calculator
# deprecated: false
# priority_range: 3060-3089
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.interest_calculator

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.interest_calculator.no_match",
    "package": "jdg.interest_calculator", "priority": 9999
}

# Reference rate helper — dynamic from thresholds
get_reference_rate() = rate {
    rate := object.get(object.get(data.thresholds, "ord", {}), "tax_interest_rate", 0.145)
}

# ═══════════════════════════════════════════════════════════════════════════════
# INT-3060: INTEREST RATE CALCULATOR — Kalkulator stawek odsetek
# ═══════════════════════════════════════════════════════════════════════════════

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
    "_routing_reason": sprintf("Stopy referencyjne: lombard %.1f%% → bazowa %.1f%% / obniżona %.1f%% / podwyższona %.1f%%", [reference_rate*100, base_rate*100, reduced_rate*100, increased_rate*100]),
    "_legal_basis": "Art. 53-56 OrdPU; Art. 67b OrdPU (opłata prolongacyjna); Art. 78 OrdPU (odsetki od nadpłaty)",
    "_warnings": [
        sprintf("📊 KALKULATOR ODSETEK — STOPY", []),
        sprintf("   Stopa referencyjna (lombard NBP): %.2f%%", [reference_rate * 100]),
        sprintf("   Podstawowa (200%% lombardu): %.2f%% rocznie", [base_rate * 100]),
        sprintf("   Obniżona (50%% — korekta+wpłata 7 dni): %.2f%% rocznie", [reduced_rate * 100]),
        sprintf("   Podwyższona (150%% — VAT/PIT zaniżenie): %.2f%% rocznie", [increased_rate * 100]),
        sprintf("   Opłata prolongacyjna (50%% podstawowej): %.2f%% rocznie", [prolongation_rate * 100]),
        sprintf("   Odsetki od nadpłaty (lombard+2pp): %.2f%% rocznie", [overpayment_rate * 100]),
        "⚠️ Stawki aktualizowane kwartalnie — sprawdź obwieszczenie MF!",
    ]
} {
    input.interest_calculator_check == true
    reference_rate := get_reference_rate()
    base_rate := reference_rate * 2.00
    reduced_rate := base_rate * 0.50
    increased_rate := base_rate * 1.50
    prolongation_rate := base_rate * 0.50
    overpayment_rate := reference_rate + 0.02
}

# ═══════════════════════════════════════════════════════════════════════════════
# INT-3070: INTEREST AMOUNT CALCULATOR — Kalkulator kwoty odsetek
# ═══════════════════════════════════════════════════════════════════════════════

else := {
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
    "_warnings": [
        sprintf("💰 KALKULATOR ODSETEK — %.0f PLN × %d dni × %.2f%%", [principal, days_late, applicable_rate * 100]),
        sprintf("   Odsetki: %.0f PLN | Łącznie do zapłaty: %.0f PLN", [interest, total]),
        sprintf("   %s", [correction_savings_text { correction_eligible } else "Stawka standardowa — rozważ korektę dla obniżenia odsetek."]),
    ]
} {
    input.interest_amount_calculate == true
    principal := object.get(input, "int_principal_pln", 0)
    days_late := object.get(input, "int_days_late", 0)
    violation_type := object.get(input, "int_violation_type", "STANDARD")

    reference_rate := get_reference_rate()
    base_rate := reference_rate * 2.00

    applicable_rate := base_rate { violation_type == "STANDARD" }
    applicable_rate := base_rate * 0.50 { violation_type == "CORRECTION_7DAYS" }
    applicable_rate := base_rate * 1.50 { violation_type == "VAT_UNDERSTATED" }
    applicable_rate := base_rate { true }

    rate_label := "podstawowa (200% lombardu)" { violation_type == "STANDARD" }
    rate_label := "obniżona (korekta+7dni)" { violation_type == "CORRECTION_7DAYS" }
    rate_label := "podwyższona (150% — VAT)" { violation_type == "VAT_UNDERSTATED" }

    interest := principal * applicable_rate * days_late / 365
    total := principal + interest

    correction_eligible := violation_type == "STANDARD" and days_late > 0
    correction_savings := interest * 0.50 { correction_eligible }

    correction_savings_text := sprintf("💡 ZŁÓŻ KOREKTĘ + WPŁAĆ W 7 DNI → oszczędzisz %.0f PLN (50%% mniej odsetek)!", [correction_savings]) { correction_eligible }

    int_routing := "TRIAGE_QUEUE" { correction_eligible; correction_savings > 1000 }
    int_routing := "" { true }
    int_reason := sprintf("Optymalizacja odsetek: złóż korektę, oszczędź %.0f PLN.", [correction_savings]) { correction_eligible; correction_savings > 1000 }
    int_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INT-3080: CASHFLOW TIMING OPTIMIZER — Optymalizacja terminu wpłaty
# ═══════════════════════════════════════════════════════════════════════════════

else := {
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
    "_routing_reason": sprintf("Optymalizacja: wpłać %s → oszczędność %.0f PLN vs płatność ostatniego dnia.", [best_date, savings]),
    "_legal_basis": "Art. 53-56 OrdPU; Optymalizacja finansowa JDG",
    "_warnings": [
        sprintf("📅 OPTYMALIZACJA TERMINU WPŁATY — %.0f PLN", [principal]),
        sprintf("   Dziś: %.0f PLN odsetek", [pay_now]),
        sprintf("   Za %d dni: %.0f PLN odsetek", [max_delay, pay_later]),
        sprintf("   Optymalna data: %s (oszczędność %.0f PLN)", [best_date, savings]),
    ]
} {
    input.interest_cashflow_optimize == true
    principal := object.get(input, "int_principal_pln", 0)
    days_until_deadline := object.get(input, "int_days_to_deadline", 25)
    current_day := object.get(input, "int_current_day", 0)
    max_delay := days_until_deadline - current_day

    reference_rate := get_reference_rate()
    base_rate := reference_rate * 2.00

    # Pay now: 0 days late
    pay_now := 0
    # Pay on last day: max_delay days late
    pay_later := principal * base_rate * max_delay / 365 { max_delay > 0 }

    pay_mid := principal * base_rate * (max_delay / 2) / 365 { max_delay > 0 }
    best_date := sprintf("w połowie okresu (dzień %d)", [max_delay / 2])
    savings := pay_later - pay_mid
}
