# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — P20 Supplement: S23-500/600/700
# v7.0 — Szacowanie podstawy (art. 23 OrdPU) + Kary porządkowe (art. 262) + Sankcje VAT (art. 109c)
# Package: jdg.enterprise.sanctions_supplements
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.sanctions_supplements

import data.jdg.helpers

# ═══════════════════════════════════════════════════════════════════════════════
# S23-500: Szacowanie podstawy opodatkowania (art. 23 OrdPU)
# ═══════════════════════════════════════════════════════════════════════════════

s23_500_estimation_check(input) = check {
    no_records := object.get(input, "no_tax_records", false)
    records_unreliable := object.get(input, "records_unreliable", false)
    us_estimated := object.get(input, "tax_office_estimated_base", false)
    estimation_method := object.get(input, "estimation_method", "NONE")

    can_be_estimated := no_records or records_unreliable

    taxpayer_action := "UZUPEŁNIJ BRAKUJĄCE EWIDENCJE — unikniesz szacowania przez US" { can_be_estimated; not us_estimated }
    taxpayer_action := "ODWOŁAJ SIĘ — US oszacował podstawę. Przedstaw własną kalkulację" { us_estimated }
    taxpayer_action := "Brak potrzeby szacowania" { true }

    routing := "TRIAGE" { can_be_estimated or us_estimated }
    routing := "PASS" { true }

    check := {
        "article": "23 OrdPU",
        "can_be_estimated": can_be_estimated,
        "us_already_estimated": us_estimated,
        "method": estimation_method,
        "taxpayer_action": taxpayer_action,
        "note": "Szacowanie = US sam określa podstawę opodatkowania. Ryzyko zawyżenia!",
        "routing": routing,
        "legal_basis": "Art. 23 § 1-4 Ordynacji Podatkowej",
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S23-600: Kary porządkowe (art. 262 OrdPU) — do 3 000 PLN
# ═══════════════════════════════════════════════════════════════════════════════

s23_600_disciplinary_penalty(input) = check {
    refused_testimony := object.get(input, "refused_testimony", false)
    failed_to_appear := object.get(input, "failed_to_appear_twice", false)
    obstructed_audit := object.get(input, "obstructed_audit", false)
    prior_penalties := object.get(input, "prior_disciplinary_penalties", 0)

    penalty_risk := true { refused_testimony or failed_to_appear or obstructed_audit }
    penalty_risk := false { true }

    max_penalty := 3000
    escalation_multiplier := 1 + prior_penalties

    action := sprintf("STAW SIĘ NA WEZWANIE / NIE ODMAWIAJ ZEZNAŃ — grozi kara porządkowa do %.0f PLN!",
        [max_penalty * escalation_multiplier]) { penalty_risk }
    action := "Brak ryzyka kar porządkowych" { true }

    routing := "BLOCK_AND_ALERT" { penalty_risk; prior_penalties >= 2 }
    routing := "WARN" { penalty_risk }
    routing := "PASS" { not penalty_risk }

    check := {
        "article": "262 OrdPU",
        "penalty_risk": penalty_risk,
        "max_penalty_pln": max_penalty * escalation_multiplier,
        "prior_penalties": prior_penalties,
        "action": action,
        "routing": routing,
        "legal_basis": "Art. 262 § 1-5 Ordynacji Podatkowej",
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S23-700: Sankcje VAT (art. 109c VAT) — dodatkowe zobowiązanie 15/20/30%
# ═══════════════════════════════════════════════════════════════════════════════

s23_700_vat_sanction(input) = check {
    vat_discrepancy_pct := object.get(input, "vat_discrepancy_pct", 0)
    discrepancy_amount := object.get(input, "vat_discrepancy_pln", 0)
    is_second_offense := object.get(input, "second_vat_sanction", false)
    voluntary_correction := object.get(input, "voluntary_correction_before_audit", false)

    sanction_rate := 0.30 { vat_discrepancy_pct > 0.50 }
    sanction_rate := 0.20 { is_second_offense }
    sanction_rate := 0.15 { true }

    sanction_amount := discrepancy_amount * sanction_rate
    min_sanction := 500
    effective_sanction := max([sanction_amount, min_sanction])

    avoided := voluntary_correction and vat_discrepancy_pct > 0

    action := "SKORYGUJ VAT przed kontrolą — unikniesz sankcji 15-30%!" { avoided }
    action := sprintf("SANKCJA VAT %.0f%% = %.0f PLN — złóż korektę jak najszybciej",
        [sanction_rate * 100, effective_sanction]) { not avoided; vat_discrepancy_pct > 0 }
    action := "Brak rozbieżności VAT" { true }

    routing := "BLOCK_AND_ALERT" { not avoided; vat_discrepancy_pct > 0.30 }
    routing := "TRIAGE" { not avoided; vat_discrepancy_pct > 0; vat_discrepancy_pct <= 0.30 }
    routing := "PASS" { avoided or vat_discrepancy_pct == 0 }

    check := {
        "article": "109c VAT",
        "vat_discrepancy_pct": vat_discrepancy_pct,
        "discrepancy_amount": discrepancy_amount,
        "sanction_rate_pct": sanction_rate * 100,
        "sanction_amount_pln": effective_sanction,
        "second_offense": is_second_offense,
        "voluntary_correction": voluntary_correction,
        "sanction_avoided": avoided,
        "action": action,
        "routing": routing,
        "legal_basis": "Art. 109c ustawy o VAT",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Build S23S warnings
# ─────────────────────────────────────────────────────────────────────────────
build_s23s_warnings(s500, s600, s700) = warnings {
    est_active := object.get(s500, "can_be_estimated", false) or object.get(s500, "us_already_estimated", false)
    s600_active := object.get(s600, "penalty_risk", false)
    s700_active := object.get(s700, "vat_discrepancy_pct", 0) > 0 and not object.get(s700, "sanction_avoided", false)

    base := ["⚖️ SANCTIONS SUPPLEMENTS — S23-500/600/700"]

    # Flag-based sum instead of cumulative counter
    s500_flag := 1 { est_active }
    s500_flag := 0 { not est_active }
    s600_flag := 1 { s600_active }
    s600_flag := 0 { not s600_active }
    s700_flag := 1 { s700_active }
    s700_flag := 0 { not s700_active }

    active_count := s500_flag + s600_flag + s700_flag

    status := "Brak aktywnych sankcji" { active_count == 0 }
    status := sprintf("%d aktywne ostrzeżenia!", [active_count]) { active_count > 0 }

    warnings := array.concat(base, [sprintf("   %s", [status])])
}
