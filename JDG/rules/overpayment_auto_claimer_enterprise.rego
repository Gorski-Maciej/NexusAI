# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE OVERPAYMENT AUTO-CLAIMER (Innovation 9.7 / BP-7, P19 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Overpayment Auto-Claimer — Art. 72-80 OrdPU Automation
# description: |
#   ENTERPRISE v7.0 — Automatyczne wykrywanie i dochodzenie nadpłat podatkowych.
#   Wykrywa nadpłaty VAT/PIT, weryfikuje art. 72-75, generuje wnioski,
#   monitoruje 30-dniowy termin zwrotu, nalicza odsetki art. 78.
#
#   KLUCZOWE FUNKCJE:
#   - Automatyczne wykrywanie nadpłat (VAT naliczony > należny, PIT nadpłacony)
#   - Weryfikacja przesłanek art. 72-75 OrdPU
#   - Generowanie wniosku o stwierdzenie nadpłaty + korekty deklaracji
#   - Monitoring 30-dniowego terminu zwrotu (art. 77)
#   - Kalkulator odsetek od nadpłaty (art. 78 — lombard + 2 pp)
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 72-80 OrdPU (nadpłata i zwrot)
# package: jdg.overpayment_claimer
# deprecated: false
# priority_range: 3030-3059
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.overpayment_claimer

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.overpayment_claimer.no_match",
    "package": "jdg.overpayment_claimer", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# OVC-3030: OVERPAYMENT DETECTOR — Automatyczne wykrywanie nadpłat
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.overpayment_claimer.overpayment_detector",
    "package": "jdg.overpayment_claimer",
    "priority": 3030,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ovc_overpayment_vat_detected": vat_detected,
    "ovc_overpayment_pit_detected": pit_detected,
    "ovc_overpayment_total_pln": total_overpayment,
    "ovc_overpayment_periods": periods,
    "ovc_overpayment_eligible_for_refund": eligible,
    "ovc_overpayment_claim_deadline": claim_deadline,
    "_routing": ovc_routing,
    "_routing_reason": ovc_reason,
    "_legal_basis": "Art. 72-75 OrdPU (nadpłata); Art. 79 § 2 OrdPU (przedawnienie 5 lat)",
    "_warnings": build_ovc_warnings(vat_detected, pit_detected, total_overpayment, periods, eligible)
} {
    input.overpayment_detection_check == true

    # VAT overpayment: input VAT > output VAT
    vat_input := object.get(input, "vat_input_total", 0)
    vat_output := object.get(input, "vat_output_total", 0)
    vat_overpayment := vat_input - vat_output
    vat_detected := vat_overpayment > 0

    # PIT overpayment: advances paid > tax due
    pit_advances := object.get(input, "pit_advances_paid_total", 0)
    pit_due := object.get(input, "pit_tax_due_total", 0)
    pit_overpayment := pit_advances - pit_due
    pit_detected := pit_overpayment > 0

    total_overpayment := max([vat_overpayment, 0]) { vat_detected }
    total_overpayment := 0 { not vat_detected }
    total_overpayment := total_overpayment + max([pit_overpayment, 0]) { pit_detected }

    periods := object.get(input, "overpayment_periods", [])

    # Check if still within 5-year statute
    oldest_period := object.get(periods[0], "year", 2021) { count(periods) > 0 }
    current_year := 2026
    eligible := total_overpayment > 0 and (current_year - oldest_period) <= 5
    claim_deadline := sprintf("do końca %d r. (5 lat od %d)", [oldest_period + 5, oldest_period])

    ovc_routing := "TRIAGE_QUEUE" { eligible; total_overpayment > 5000 }
    ovc_routing := "" { true }
    ovc_reason := sprintf("NADPŁATA WYKRYTA: %.0f PLN — złóż wniosek o zwrot! Termin: %s", [total_overpayment, claim_deadline]) { eligible; total_overpayment > 0 }
    ovc_reason := "" { true }
}

build_ovc_warnings(vat, pit, total, periods, eligible) = warnings {
    eligible
    period_list := concat(", ", [sprintf("%s", [p]) | p := periods[_]])
    warnings := [
        sprintf("💰 NADPŁATA PODATKOWA WYKRYTA — %.0f PLN", [total]),
        sprintf("   VAT: %s | PIT: %s", ["TAK" { vat } else "NIE"], ["TAK" { pit } else "NIE"]),
        sprintf("   Okresy: %s", [period_list]),
        "📋 DZIAŁANIE:",
        "   1. Złóż korektę deklaracji (JPK_V7 / PIT)",
        "   2. Złóż wniosek o stwierdzenie nadpłaty (Art. 75 OrdPU)",
        "   3. US ma 30 dni na zwrot (Art. 77 OrdPU)",
        "   4. Po terminie — odsetki od nadpłaty (Art. 78)!",
    ]
} else = warnings {
    total > 0
    warnings := [sprintf("⚠️ Nadpłata %.0f PLN z okresu sprzed 5 lat — MOGŁA SIĘ PRZEDAWNIĆ.", [total])]
} else = ["✅ Brak wykrytych nadpłat."]

# ═══════════════════════════════════════════════════════════════════════════════
# OVC-3040: REFUND TIMELINE MONITOR — Monitoring 30-dniowego terminu zwrotu
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.overpayment_claimer.refund_timeline_monitor",
    "package": "jdg.overpayment_claimer",
    "priority": 3040,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ovc_refund_claim_date": claim_date,
    "ovc_refund_days_elapsed": days_elapsed,
    "ovc_refund_30day_deadline": deadline_date,
    "ovc_refund_status": refund_status,
    "ovc_refund_interest_accrued": interest_accrued,
    "ovc_refund_escalation_needed": escalation,
    "_routing": ref_routing,
    "_routing_reason": ref_reason,
    "_legal_basis": "Art. 77 OrdPU (termin zwrotu 30 dni); Art. 78 OrdPU (odsetki od nadpłaty)",
    "_warnings": build_refund_warnings(claim_date, days_elapsed, deadline_date, refund_status, interest_accrued)
} {
    input.overpayment_refund_monitor == true
    claim_date := object.get(input, "ovc_claim_submission_date", "2026-01-01")
    refund_received := object.get(input, "ovc_refund_received", false)
    days_elapsed := object.get(input, "ovc_days_since_claim", 0)
    overpayment_amount := object.get(input, "ovc_overpayment_amount", 0)
    deadline_date := "30 dni od złożenia wniosku"

    refund_status := "OCZEKUJE" { days_elapsed < 30; not refund_received }
    refund_status := "PO_TERMINIE" { days_elapsed >= 30; not refund_received }
    refund_status := "ZWROCONO" { refund_received }

    # Art. 78: odsetki = lombard + 2 pp (gdy zwrot po 30 dniach)
    reference_rate := object.get(object.get(data.thresholds, "rates", {}), "tax_interest", 0.145)
    interest_rate := reference_rate + 0.02
    days_late := days_elapsed - 30
    interest_accrued := overpayment_amount * interest_rate * days_late / 365 { days_late > 0; not refund_received }
    interest_accrued := 0 { days_late <= 0 or refund_received }

    escalation := days_elapsed >= 30 and not refund_received

    ref_routing := "BLOCK_AND_ALERT" { escalation; overpayment_amount > 10000 }
    ref_routing := "TRIAGE_QUEUE" { escalation }
    ref_routing := "" { true }
    ref_reason := sprintf("ZWROT NADPŁATY PO TERMINIE: %d dni — należy się %.0f PLN odsetek! Złóż ponaglenie.", [days_elapsed, interest_accrued]) { escalation }
    ref_reason := "" { true }
}

build_refund_warnings(claim, elapsed, deadline, status, interest) = warnings {
    status == "PO_TERMINIE"
    warnings := [
        sprintf("🚨 ZWROT NADPŁATY PO TERMINIE 30 DNI!", []),
        sprintf("   Wniosek złożony: %s | Minęło: %d dni", [claim, elapsed]),
        sprintf("   Należne odsetki: %.0f PLN (Art. 78 OrdPU — lombard + 2pp)", [interest]),
        "📋 Eskalacja: złóż ponaglenie do Naczelnika US (Art. 141 OrdPU).",
    ]
} else = warnings {
    status == "OCZEKUJE"
    warnings := [sprintf("⏳ Oczekiwanie na zwrot nadpłaty — %d/30 dni od %s.", [elapsed, claim])]
} else = [sprintf("✅ Nadpłata zwrócona.")]
