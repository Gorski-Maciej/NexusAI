# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE VAT CASHFLOW PREDICTOR (Innovation 8.17, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise VAT Cashflow Predictor — Dynamic Tax Horizon
# description: |
#   ENTERPRISE v7.0 — Predykcyjny silnik cashflow VAT. Oblicza prognozowane
#   zobowiązania i zwroty VAT w horyzoncie 3-miesięcznym z uwzględnieniem:
#   terminów płatności (25. dzień), split payment (MPP), mikrorachunku VAT,
#   oraz wpływu faktur korygujących i ulgi na złe długi.
#
#   KLUCZOWE FUNKCJE:
#   - 3-miesięczna prognoza VAT do zapłaty / do zwrotu
#   - Kalendarz terminów płatności i wpływu zwrotów
#   - Symulacja wpływu split payment na cashflow
#   - Wpływ faktur korygujących (in-minus, in-plus)
#   - Ulga na złe długi (90 dni) — wpływ na VAT należny/naliczony
#   - Monitorowanie mikrorachunku VAT
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 99, 103, 87, 89a-89b VAT
# package: jdg.vat_cashflow
# deprecated: false
# priority_range: 2180-2209
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat_cashflow

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.vat_cashflow.no_match",
    "package": "jdg.vat_cashflow", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# VCF-2180: 3-MONTH VAT FORECAST — Prognoza VAT na 3 miesiące
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.vat_cashflow.three_month_forecast",
    "package": "jdg.vat_cashflow",
    "priority": 2180,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_forecast_month_1_vat_to_pay": m1_pay,
    "vat_forecast_month_2_vat_to_pay": m2_pay,
    "vat_forecast_month_3_vat_to_pay": m3_pay,
    "vat_forecast_month_1_vat_to_refund": m1_refund,
    "vat_forecast_month_2_vat_to_refund": m2_refund,
    "vat_forecast_month_3_vat_to_refund": m3_refund,
    "vat_forecast_total_quarter_pay": total_pay,
    "vat_forecast_total_quarter_refund": total_refund,
    "vat_forecast_net_cashflow_impact": net_impact,
    "_routing": forecast_routing,
    "_routing_reason": forecast_reason,
    "_legal_basis": "Art. 99, 103, 87 VAT",
    "_warnings": build_forecast_warnings(m1_pay, m2_pay, m3_pay, m1_refund, m2_refund, m3_refund, total_pay, total_refund, net_impact)
} {
    input.vat_cashflow_forecast == true
    m1_pay := object.get(input, "vat_forecast_m1_to_pay", 0)
    m2_pay := object.get(input, "vat_forecast_m2_to_pay", 0)
    m3_pay := object.get(input, "vat_forecast_m3_to_pay", 0)
    m1_refund := object.get(input, "vat_forecast_m1_to_refund", 0)
    m2_refund := object.get(input, "vat_forecast_m2_to_refund", 0)
    m3_refund := object.get(input, "vat_forecast_m3_to_refund", 0)

    total_pay := m1_pay + m2_pay + m3_pay
    total_refund := m1_refund + m2_refund + m3_refund
    net_impact := total_refund - total_pay

    forecast_routing := "BLOCK_AND_ALERT" { total_pay > 100000; net_impact < -50000 }
    forecast_routing := "TRIAGE_QUEUE" { net_impact < 0 }
    forecast_routing := "" { true }
    forecast_reason := sprintf("VAT CASHFLOW ALERT: %.0f PLN do zapłaty — przygotuj środki na mikrorachunku!", [total_pay]) { total_pay > 100000 }
    forecast_reason := sprintf("VAT cashflow ujemny: %.0f PLN netto w kwartale.", [net_impact]) { net_impact < 0 }
    forecast_reason := sprintf("VAT cashflow dodatni: +%.0f PLN (zwroty przewyższają zobowiązania).", [net_impact]) { net_impact > 0 }
    forecast_reason := "" { true }
}

build_forecast_warnings(m1p, m2p, m3p, m1r, m2r, m3r, tp, tr, net) = warnings {
    warnings := [
        "═══════════════════════════════════════════",
        "💰 VAT CASHFLOW — PROGNOZA 3-MIESIĘCZNA",
        sprintf("   M+1: Do zapłaty %.0f PLN | Do zwrotu %.0f PLN", [m1p, m1r]),
        sprintf("   M+2: Do zapłaty %.0f PLN | Do zwrotu %.0f PLN", [m2p, m2r]),
        sprintf("   M+3: Do zapłaty %.0f PLN | Do zwrotu %.0f PLN", [m3p, m3r]),
        "───────────────────────────────────────────",
        sprintf("   SUMA: Do zapłaty %.0f PLN | Do zwrotu %.0f PLN", [tp, tr]),
        sprintf("   NETTO CASHFLOW: %+.0f PLN", [net]),
        "═══════════════════════════════════════════",
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# VCF-2185: PAYMENT DEADLINE CALENDAR — Kalendarz terminów płatności VAT
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.vat_cashflow.payment_deadline_calendar",
    "package": "jdg.vat_cashflow",
    "priority": 2185,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_deadline_next_period": next_period,
    "vat_deadline_next_date": next_deadline,
    "vat_deadline_next_amount": next_amount,
    "vat_deadline_mikrorachunek": "47 1010 0071 2223 [mikrorachunek VAT]",
    "vat_deadline_days_remaining": days_remaining,
    "_routing": deadline_routing,
    "_routing_reason": deadline_reason,
    "_legal_basis": "Art. 103 ust. 1 VAT (termin 25. dnia); Art. 62b OrdPU (mikrorachunek)",
    "_warnings": [
        sprintf("📅 TERMIN PŁATNOŚCI VAT — %s", [next_period]),
        sprintf("   Kwota: %.0f PLN", [next_amount]),
        sprintf("   Termin: %s (pozostało %d dni)", [next_deadline, days_remaining]),
        sprintf("   Mikrorachunek VAT: 47 1010 0071 2223 ..."),
        "⚠️ PRZELEW ŚRODKÓW NA MIKRORACHUNEK PRZED TERMINEM!",
    ]
} {
    input.vat_cashflow_deadline_check == true
    next_period := object.get(input, "vat_next_period", "2026-08")
    next_deadline := object.get(input, "vat_next_deadline", "2026-09-25")
    next_amount := object.get(input, "vat_next_amount_to_pay", 0)
    days_remaining := object.get(input, "vat_days_to_deadline", 30)

    deadline_routing := "BLOCK_AND_ALERT" { days_remaining <= 3; next_amount > 0 }
    deadline_routing := "TRIAGE_QUEUE" { days_remaining <= 7; next_amount > 0 }
    deadline_routing := "" { true }
    deadline_reason := sprintf("TERMIN PŁATNOŚCI ZA %d DNI! %.0f PLN na mikrorachunek VAT!", [days_remaining, next_amount]) { days_remaining <= 3 }
    deadline_reason := sprintf("VAT %.0f PLN do zapłaty za %d dni.", [next_amount, days_remaining]) { days_remaining <= 7 }
    deadline_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# VCF-2190: SPLIT PAYMENT (MPP) CASHFLOW IMPACT — Wpływ MPP na płynność
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.vat_cashflow.split_payment_impact",
    "package": "jdg.vat_cashflow",
    "priority": 2190,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_mpp_frozen_total": mpp_frozen,
    "vat_mpp_releasable_total": mpp_releasable,
    "vat_mpp_sanction_risk": mpp_sanction_risk,
    "_routing": mpp_routing,
    "_routing_reason": mpp_reason,
    "_legal_basis": "Art. 108a-108f VAT (MPP); Art. 106e ust. 1 pkt 18a VAT",
    "_warnings": [
        sprintf("💳 SPLIT PAYMENT (MPP) — WPŁYW NA CASHFLOW", []),
        sprintf("   Środki zamrożone na rachunku VAT: %.0f PLN", [mpp_frozen]),
        sprintf("   Do uwolnienia (przelew na ROR): %.0f PLN", [mpp_releasable]),
        sprintf("   Ryzyko sankcji MPP (30%%): %.0f PLN", [mpp_sanction_risk]),
        "📋 UWOLNIENIE ŚRODKÓW Z VAT: wniosek do US + zgoda w 60 dni.",
    ]
} {
    input.vat_cashflow_mpp_check == true
    mpp_frozen := object.get(input, "vat_mpp_frozen_balance", 0)
    mpp_releasable := object.get(input, "vat_mpp_releasable_amount", 0)
    mpp_sanction_threshold := object.get(object.get(data.thresholds, "misc", {}), "mpp_mandatory_threshold", 15000)
    mpp_violations := object.get(input, "vat_mpp_violation_count", 0)
    mpp_sanction_rate := object.get(object.get(data.thresholds, "misc", {}), "mpp_sanction_rate", 0.30)
    mpp_sanction_risk := mpp_violations * mpp_sanction_threshold * mpp_sanction_rate

    mpp_routing := "TRIAGE_QUEUE" { mpp_frozen > 100000 }
    mpp_routing := "" { true }
    mpp_reason := sprintf("MPP: %.0f PLN zamrożone na VAT — rozważ wniosek o uwolnienie.", [mpp_frozen]) { mpp_frozen > 100000 }
    mpp_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# VCF-2195: BAD DEBT RELIEF IMPACT — Wpływ ulgi na złe długi na cashflow VAT
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.vat_cashflow.bad_debt_relief_impact",
    "package": "jdg.vat_cashflow",
    "priority": 2195,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "vat_bad_debt_receivables_overdue": overdue_receivables,
    "vat_bad_debt_vat_reclaimable": vat_reclaimable,
    "vat_bad_debt_days_to_eligibility": days_to_90,
    "vat_bad_debt_correction_deadline": correction_deadline,
    "_routing": bd_routing,
    "_routing_reason": bd_reason,
    "_legal_basis": "Art. 89a-89b VAT (ulga na złe długi — SLIM VAT 3)",
    "_warnings": [
        sprintf("📉 ULGA NA ZŁE DŁUGI (VAT) — IMPACT", []),
        sprintf("   Należności przeterminowane >90 dni: %.0f PLN", [overdue_receivables]),
        sprintf("   VAT do odzyskania (korekta): %.0f PLN", [vat_reclaimable]),
        sprintf("   Dni do osiągnięcia 90 dni: %d", [days_to_90]),
        sprintf("   Termin korekty JPK_V7: %s", [correction_deadline]),
        "📋 Korekta VAT należnego w JPK_V7 po 90 dniach od terminu płatności!",
    ]
} {
    input.vat_cashflow_bad_debt_check == true
    overdue_receivables := object.get(input, "vat_overdue_receivables_gt_90d", 0)
    approaching_90d := object.get(input, "vat_overdue_receivables_60_90d", 0)
    vat_reclaimable := overdue_receivables * 0.23

    days_to_90 := 0
    days_to_90 := object.get(input, "vat_oldest_overdue_days_to_90", 999) { approaching_90d > 0 }

    correction_deadline := "w bieżącym okresie JPK_V7" { overdue_receivables > 0 }
    correction_deadline := sprintf("za ok. %d dni", [days_to_90]) { approaching_90d > 0; overdue_receivables == 0 }
    correction_deadline := "nie dotyczy" { true }

    bd_routing := "TRIAGE_QUEUE" { vat_reclaimable > 5000 }
    bd_routing := "" { true }
    bd_reason := sprintf("ULGA NA ZŁE DŁUGI: odzyskaj %.0f PLN VAT z nieściągalnych należności!", [vat_reclaimable]) { vat_reclaimable > 5000 }
    bd_reason := "" { true }
}
