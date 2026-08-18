# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — Innovation 14.3: WIS Auto-Requester
# v7.0 — BP-3: Auto-detection + cost-benefit + WIS-W generation + e-US submit
# Package: jdg.enterprise.wis_autorequester
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.wis_autorequester

import data.jdg.helpers
import data.jdg.thresholds

# ─────────────────────────────────────────────────────────────────────────────
# WAR-3150: Ambiguous CN code detector
# ─────────────────────────────────────────────────────────────────────────────
war_detect_ambiguous_cn(input) = detection {
    cn_code := object.get(input, "cn_code", "")
    current_vat_rate := object.get(input, "assigned_vat_rate", 0.23)
    alternative_rates := object.get(input, "possible_vat_rates", [])

    is_ambiguous := count(alternative_rates) > 1
    rate_spread := 0 { not is_ambiguous }
    rate_spread := max(alternative_rates) - min(alternative_rates) { is_ambiguous }

    detection := {
        "cn_code": cn_code,
        "current_vat_rate": current_vat_rate,
        "alternative_rates": alternative_rates,
        "is_ambiguous": is_ambiguous,
        "rate_spread": rate_spread,
        "action": "ZŁÓŻ WNIOSEK WIS-W — niejednoznaczny kod CN" { is_ambiguous; rate_spread > 0.05 },
        "action": "Monitoruj — potencjalna niejasność" { is_ambiguous; rate_spread <= 0.05 },
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# WAR-3160: Cost-benefit analysis — WIS fee vs KKS risk
# ─────────────────────────────────────────────────────────────────────────────
war_cost_benefit(input) = analysis {
    annual_turnover_cn := object.get(input, "annual_turnover_for_cn_pln", 0)
    current_rate := object.get(input, "assigned_vat_rate", 0.23)
    correct_rate_estimate := object.get(input, "estimated_correct_rate", 0.08)
    wis_fee := 40  # PLN

    underpayment_risk := annual_turnover_cn * (current_rate - correct_rate_estimate)
    kks_penalty_risk := underpayment_risk * 0.30
    total_risk := kks_penalty_risk + underpayment_risk

    worth_filing := total_risk > wis_fee * 10  # 10x ROI threshold

    analysis := {
        "annual_turnover_cn": annual_turnover_cn,
        "underpayment_risk_pln": underpayment_risk,
        "kks_penalty_risk_pln": kks_penalty_risk,
        "total_risk_pln": total_risk,
        "wis_fee_pln": wis_fee,
        "roi": total_risk / max([wis_fee, 1]),
        "worth_filing": worth_filing,
        "recommendation": "ZŁÓŻ WIS-W — ryzyko KKS znacznie przewyższa opłatę 40 PLN" { worth_filing },
        "recommendation": "Opłata WIS zbliżona do ryzyka — decyzja uznaniowa" { not worth_filing; total_risk > wis_fee },
        "recommendation": "Ryzyko niskie — WIS opcjonalny" { total_risk <= wis_fee },
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# WAR-3170: WIS-W auto-generator + validity tracker
# ─────────────────────────────────────────────────────────────────────────────
war_generate_wis_w(cn_code, product_desc) = application {
    application := {
        "form": "WIS-W",
        "cn_code": cn_code,
        "product_description": product_desc,
        "fee_pln": 40,
        "recipient": "Dyrektor Krajowej Informacji Skarbowej",
        "dispatch_channel": "e-Urząd Skarbowy",
        "expected_response_days": 90,
        "validity_years": 5,
        "legal_basis": "Art. 42b ust. 4 ustawy o VAT",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# WAR-3180: 5-year validity monitor + expiry alerts
# ─────────────────────────────────────────────────────────────────────────────
war_validity_monitor(wis_ruling) = monitor {
    issue_date := object.get(wis_ruling, "issue_date_days_ago", 0)
    validity_years := 5
    expiry_days := validity_years * 365 - issue_date

    status := "OK" { expiry_days > object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "wis_expiry_warning_days", 180) }
    status := "EXPIRING_6M" { expiry_days <= object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "wis_expiry_warning_days", 180); expiry_days > object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "wis_expiry_critical_days", 90) }
    status := "EXPIRING_3M" { expiry_days <= object.get(data.jdg.thresholds.ksef_jpk_edeklaracje, "wis_expiry_critical_days", 90); expiry_days > 30 }
    status := "EXPIRING_30D" { expiry_days <= 30; expiry_days > 0 }
    status := "EXPIRED" { expiry_days <= 0 }

    monitor := {
        "days_since_issued": issue_date,
        "days_until_expiry": max([expiry_days, 0]),
        "status": status,
        "action": "ODNOWIENIE WYMAGANE — złóż nowy wniosek WIS-W!" { status == "EXPIRED" },
        "action": "PRZYGOTUJ ODNOWIENIE — WIS wygasa za 30 dni" { status == "EXPIRING_30D" },
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# WAR-3190: Build WAR warnings
# ─────────────────────────────────────────────────────────────────────────────
build_war_warnings(detection, analysis, monitor) = warnings {
    is_ambiguous := object.get(detection, "is_ambiguous", false)
    worth := object.get(analysis, "worth_filing", false)
    status := object.get(monitor, "status", "OK")

    base := ["📋 WIS AUTO-REQUESTER"]

    detection_warn := array.concat(base, [
        sprintf("   ⚠️ NIEJEDNOZNACZNY KOD CN: %s — spread stawek %.0f%%",
            [object.get(detection, "cn_code", ""),
             object.get(detection, "rate_spread", 0) * 100]),
    ]) { is_ambiguous }

    detection_warn := array.concat(base, ["   ✅ Kod CN jednoznaczny"]) { not is_ambiguous }

    base2 := detection_warn

    analysis_warn := array.concat(base2, [
        sprintf("   💰 ROI WIS: %.1fx — %s", [object.get(analysis, "roi", 0),
            object.get(analysis, "recommendation", "")]),
    ]) { worth }

    analysis_warn := base2 { not worth }

    warnings := analysis_warn
}
