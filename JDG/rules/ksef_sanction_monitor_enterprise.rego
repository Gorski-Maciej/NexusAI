# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE KSeF SANCTION EXPOSURE MONITOR (Innovation 8.9, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise KSeF Sanction Monitor — Real-Time Exposure Calculator
# description: |
#   ENTERPRISE v7.0 — Kalkulator ekspozycji sankcyjnej KSeF w czasie rzeczywistym.
#   Wypełnia lukę K6 z raportu P18: oblicza potencjalną sankcję za brak KSeF
#   jako sumę 100% VAT z nieprzekazanych faktur z limitem 500k PLN.
#
#   SPEKTRUM SANKCJI:
#   - Brak KSeF (nieprzekazane): 100% VAT, max 500 000 PLN
#   - Opóźnienie >24h: 70% VAT, max 300 000 PLN
#   - Błędy formalne: 18% VAT, max 500 000 PLN
#   - Czynny żal (korekta): 50% VAT, max 250 000 PLN
#   - Brak ZAW-NR: kara 5 000 PLN
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 106ga ust. 1 VAT (Dz.U. 2023 poz. 1598)
# package: jdg.ksef_sanction_monitor
# deprecated: false
# priority_range: 2030-2059
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.ksef_sanction_monitor

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.ksef_sanction_monitor.no_match",
    "package": "jdg.ksef_sanction_monitor", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# KSM-2030: SANCTION EXPOSURE CALCULATOR — Obliczenie łącznej ekspozycji sankcyjnej
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.ksef_sanction_monitor.exposure_calculator",
    "package": "jdg.ksef_sanction_monitor",
    "priority": 2030,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_exposure_total_vat_without_ksef": total_vat_missing,
    "ksef_exposure_invoice_count_missing": missing_count,
    "ksef_exposure_sanction_100pct": sanction_100pct,
    "ksef_exposure_sanction_70pct": sanction_70pct,
    "ksef_exposure_sanction_18pct": sanction_18pct,
    "ksef_exposure_max_aggregate": max_aggregate,
    "ksef_exposure_risk_level": risk_level,
    "ksef_exposure_zaw_nr_penalty": zaw_nr_penalty,
    "_routing": exposure_routing,
    "_routing_reason": exposure_reason,
    "_legal_basis": "Art. 106ga ust. 1 ust. 1-3 VAT (Dz.U. 2023 poz. 1598)",
    "_warnings": build_exposure_warnings(
        total_vat_missing, missing_count, sanction_100pct,
        sanction_70pct, sanction_18pct, max_aggregate, risk_level, zaw_nr_penalty
    )
} {
    input.ksef_exposure_check == true

    # Dane zbiorcze z warstwy integracyjnej
    total_vat_missing := object.get(input, "ksef_missing_invoices_vat_total", 0)
    missing_count := object.get(input, "ksef_missing_invoices_count", 0)
    delayed_count := object.get(input, "ksef_delayed_gt_24h_count", 0)
    delayed_vat := object.get(input, "ksef_delayed_gt_24h_vat_total", 0)
    error_vat := object.get(input, "ksef_formal_error_vat_total", 0)
    zaw_nr_missing := object.get(input, "ksef_zaw_nr_not_sent", false)

    sanction_max := object.get(object.get(data.thresholds, "vat", {}), "ksef_sanction_max_pln", 500000)

    # Obliczenia sankcji z limitami
    sanction_100pct := min([total_vat_missing, sanction_max])
    sanction_70pct := min([delayed_vat * 0.70, object.get(object.get(data.thresholds, "ksef_jpk_edeklaracje", {}), "ksef_sanction_70_cap_pln", 300000)])
    sanction_18pct := min([error_vat * 0.18, sanction_max])
    max_aggregate := sanction_100pct + sanction_70pct + sanction_18pct
    zaw_nr_penalty := object.get(object.get(data.thresholds, "ksef_jpk_edeklaracje", {}), "ksef_zaw_nr_penalty_pln", 5000) { zaw_nr_missing }
    zaw_nr_penalty := 0 { not zaw_nr_missing }

    # Poziom ryzyka
    risk_level := "LOW" { max_aggregate <= 10000 }
    risk_level := "MEDIUM" { max_aggregate > 10000; max_aggregate <= 50000 }
    risk_level := "HIGH" { max_aggregate > 50000; max_aggregate <= 200000 }
    risk_level := "CRITICAL" { max_aggregate > 200000 }

    exposure_routing := "BLOCK_AND_ALERT" { risk_level == "CRITICAL" }
    exposure_routing := "TRIAGE_QUEUE" { risk_level in {"HIGH", "MEDIUM"} }
    exposure_routing := "" { true }
    exposure_reason := sprintf("EKSPOZYCJA KRYTYCZNA: %.0f PLN ryzyka sankcji KSeF! Natychmiast wyślij zaległe faktury do KSeF!", [max_aggregate]) { risk_level == "CRITICAL" }
    exposure_reason := sprintf("Ryzyko sankcji: %.0f PLN — wyślij zaległe faktury.", [max_aggregate]) { risk_level == "HIGH" }
    exposure_reason := "" { true }
}

build_exposure_warnings(total_vat, missing_cnt, s100, s70, s18, max_agg, risk, zaw_pen) = warnings {
    warnings := [
        "═══════════════════════════════════════════",
        sprintf("💰 KSeF SANCTION EXPOSURE MONITOR — %s RISK", [risk]),
        sprintf("   Faktury bez KSeF: %d (VAT: %.0f PLN)", [missing_cnt, total_vat]),
        sprintf("   → Sankcja 100%% VAT: %.0f PLN (max 500k)", [s100]),
        sprintf("   → Sankcja 70%% (opóźnienie): %.0f PLN (max 300k)", [s70]),
        sprintf("   → Sankcja 18%% (błędy): %.0f PLN (max 500k)", [s18]),
        sprintf("   → Kara ZAW-NR: %.0f PLN", [zaw_pen]),
        "───────────────────────────────────────────",
        sprintf("   ŁĄCZNA EKSPOZYCJA: %.0f PLN", [max_agg + zaw_pen]),
        "═══════════════════════════════════════════",
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# KSM-2035: PER-INVOICE SANCTION ESTIMATOR — Szacowanie sankcji dla pojedynczej faktury
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_sanction_monitor.per_invoice_estimator",
    "package": "jdg.ksef_sanction_monitor",
    "priority": 2035,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_invoice_sanction_estimated": estimated_sanction,
    "ksef_invoice_sanction_pct": sanction_pct,
    "ksef_invoice_vat_amount": invoice_vat,
    "_routing": "",
    "_routing_reason": sprintf("Faktura %.2f PLN netto — potencjalna sankcja KSeF: %.0f PLN (%s VAT)", [invoice_net, estimated_sanction, sanction_label]),
    "_legal_basis": "Art. 106ga ust. 1 VAT",
    "_warnings": [sprintf("⚠️ SANKCJA KSeF za tę fakturę: %s VAT = %.0f PLN (art. 106nq VAT). Wyślij przez KSeF aby uniknąć sankcji!", [sanction_label, estimated_sanction])]
} {
    input.ksef_per_invoice_sanction_check == true
    input.invoice.direction == "SALE"
    input.invoice.ksef_status != "SENT"

    invoice_vat := object.get(input.invoice, "amount_vat", 0)
    invoice_net := object.get(input.invoice, "amount_net", 0)
    is_delayed := object.get(input.invoice, "ksef_delayed_gt_24h", false)
    has_errors := object.get(input.invoice, "ksef_has_formal_errors", false)
    is_first_violation := object.get(input.invoice, "ksef_first_violation", true)

    sanction_max := object.get(object.get(data.thresholds, "vat", {}), "ksef_sanction_max_pln", 500000)

    sanction_pct := 100 { not is_delayed; not has_errors }
    sanction_pct := 70 { is_delayed; not has_errors }
    sanction_pct := 18 { has_errors }
    sanction_pct := 50 { is_first_violation; not has_errors }

    estimated_sanction := min([invoice_vat * sanction_pct / 100, sanction_max])
    sanction_label := sprintf("%d%%", [sanction_pct])
}
