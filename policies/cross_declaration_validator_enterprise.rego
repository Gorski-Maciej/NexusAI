# NexusAI JDG — ENTERPRISE CROSS-DECLARATION VALIDATOR (XDV-2390-XDV-2405)
package jdg.cross_validator

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.cross_validator.no_match",
    "package": "jdg.cross_validator",
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

risk_label(discrepancy_pct) = "LOW" {
    discrepancy_pct <= 1
}

risk_label(discrepancy_pct) = "MEDIUM" {
    discrepancy_pct > 1
    discrepancy_pct <= 5
}

risk_label(discrepancy_pct) = "HIGH" {
    discrepancy_pct > 5
    discrepancy_pct <= 10
}

risk_label(discrepancy_pct) = "CRITICAL" {
    discrepancy_pct > 10
}

risk_routing(risk) = "BLOCK_AND_ALERT" {
    risk == "CRITICAL"
}

risk_routing(risk) = "TRIAGE_QUEUE" {
    risk == "HIGH"
}

risk_routing(risk) = "TRIAGE_QUEUE" {
    risk == "MEDIUM"
}

risk_routing(risk) = "" {
    risk == "LOW"
}

risk_reason(risk, discrepancy, pct) = reason {
    risk == "HIGH"
    reason := sprintf("ROZBIEŻNOŚĆ JPK vs PIT: %.0f PLN (%.1f%%) — ryzyko kontroli krzyżowej US!", [discrepancy, pct])
}

risk_reason(risk, discrepancy, pct) = reason {
    risk == "CRITICAL"
    reason := sprintf("ROZBIEŻNOŚĆ JPK vs PIT: %.0f PLN (%.1f%%) — ryzyko kontroli krzyżowej US!", [discrepancy, pct])
}

risk_reason(risk, discrepancy, pct) = "" {
    risk != "HIGH"
    risk != "CRITICAL"
}

build_xdv_warnings(label, val1, val2, discrepancy, discrepancy_pct, risk) = warnings {
    warnings := [
        sprintf("🔗 CROSS-CHECK: %s", [label]),
        sprintf("   Wartość A: %.0f PLN | Wartość B: %.0f PLN", [val1, val2]),
        sprintf("   Rozbieżność: %.0f PLN (%.1f%%) | Ryzyko: %s", [discrepancy, discrepancy_pct, risk])
    ]
}

ratio_consistent(ratio) {
    ratio >= 0.5
    ratio <= 2.0
}

ratio_routing(consistent) = "" {
    consistent
}

ratio_routing(consistent) = "TRIAGE_QUEUE" {
    not consistent
}

ratio_reason(consistent, pit_income, implied_income) = "" {
    consistent
}

ratio_reason(consistent, pit_income, implied_income) = reason {
    not consistent
    reason := sprintf("PIT/ZUS: dochód PIT %.0f PLN vs implikowany z ZUS %.0f PLN — sprawdź spójność.", [pit_income, implied_income])
}

# XDV-2390: JPK_V7 vs PIT-36 revenue cross-check
decide := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_validator.jpk_vs_pit_revenue",
    "package": "jdg.cross_validator",
    "priority": 2390,
    "xdv_jpk_v7_net_sales": jpk_sales,
    "xdv_pit_revenue": pit_revenue,
    "xdv_discrepancy": discrepancy,
    "xdv_discrepancy_pct": discrepancy_pct,
    "xdv_risk_flag": risk_flag,
    "_routing": xdv_routing,
    "_routing_reason": xdv_reason,
    "_legal_basis": "Art. 109 ust. 3d VAT; Art. 45 ust. 1 PIT; Art. 193 OrdPU",
    "_warnings": build_xdv_warnings("JPK_V7 vs PIT", jpk_sales, pit_revenue, discrepancy, discrepancy_pct, risk_flag)
}) {
    object.get(input, "xdv_jpk_vs_pit_check", false) == true
    jpk_sales := object.get(input, "jpk_v7_annual_net_sales", 0)
    pit_revenue := object.get(input, "pit_annual_revenue", 0)
    discrepancy := abs(jpk_sales - pit_revenue)
    discrepancy_pct := discrepancy * 100 / max([pit_revenue, 1])
    risk_flag := risk_label(discrepancy_pct)
    xdv_routing := risk_routing(risk_flag)
    xdv_reason := risk_reason(risk_flag, discrepancy, discrepancy_pct)
}

# XDV-2395: PIT vs ZUS DRA income check
else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_validator.pit_vs_zus_income",
    "package": "jdg.cross_validator",
    "priority": 2395,
    "xdv_pit_annual_income": pit_income,
    "xdv_zus_monthly_base_avg": zus_base_avg,
    "xdv_zus_annual_implied_income": implied_income,
    "xdv_pit_zus_ratio": ratio,
    "xdv_pit_zus_consistent": consistent,
    "_routing": zus_routing,
    "_routing_reason": zus_reason,
    "_legal_basis": "Art. 18-19 SUS; Art. 45 PIT; Art. 81 OrdPU",
    "_warnings": [
        "🏥 PIT vs ZUS DRA — CROSS-CHECK",
        sprintf("   Dochód PIT: %.0f PLN/rok", [pit_income]),
        sprintf("   Średnia podstawa ZUS: %.0f PLN/mies → %.0f PLN/rok implikowany dochód", [zus_base_avg, implied_income]),
        sprintf("   Ratio (implikowany PIT/ZUS): %.2f", [ratio])
    ]
}) {
    object.get(input, "xdv_pit_vs_zus_check", false) == true
    pit_income := object.get(input, "pit_annual_income", 0)
    zus_base_avg := object.get(input, "zus_monthly_contribution_base_avg", 0)
    implied_income := zus_base_avg * 12 * 2
    ratio := pit_income / max([implied_income, 1])
    consistent := ratio_consistent(ratio)
    zus_routing := ratio_routing(consistent)
    zus_reason := ratio_reason(consistent, pit_income, implied_income)
}

# XDV-2400: CEIDG vs JPK PKD-GTU cross-check
trade_or_other_pkd(ceidg_pkd) {
    contains(ceidg_pkd, "47.")
}

trade_or_other_pkd(ceidg_pkd) {
    contains(ceidg_pkd, "46.")
}

it_pkd(ceidg_pkd) {
    contains(ceidg_pkd, "62.")
}

mismatch_for_pkd(ceidg_pkd, jpk_gtu) = true {
    trade_or_other_pkd(ceidg_pkd)
    contains(jpk_gtu, "GTU_12")
}

mismatch_for_pkd(ceidg_pkd, jpk_gtu) = true {
    it_pkd(ceidg_pkd)
    contains(jpk_gtu, "GTU_10")
}

unexpected_gtu_for_pkd(ceidg_pkd, jpk_gtu) = "GTU_12 przy PKD handlowym" {
    trade_or_other_pkd(ceidg_pkd)
    contains(jpk_gtu, "GTU_12")
}

unexpected_gtu_for_pkd(ceidg_pkd, jpk_gtu) = "GTU_10 przy PKD IT" {
    it_pkd(ceidg_pkd)
    contains(jpk_gtu, "GTU_10")
}

unexpected_gtu_for_pkd(ceidg_pkd, jpk_gtu) = "" {
    not mismatch_for_pkd(ceidg_pkd, jpk_gtu)
}

ceidg_routing_for_mismatch(has_mismatch) = "TRIAGE_QUEUE" {
    has_mismatch
}

ceidg_routing_for_mismatch(has_mismatch) = "" {
    not has_mismatch
}

ceidg_mismatch_reason(has_mismatch, unexpected_gtu) = reason {
    has_mismatch
    reason := sprintf("CEIDG vs GTU: %s — potencjalna niezgodność rejestrowa vs faktyczna działalność.", [unexpected_gtu])
}

ceidg_mismatch_reason(has_mismatch, unexpected_gtu) = "" {
    not has_mismatch
}

else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_validator.ceidg_vs_jpk_pkd",
    "package": "jdg.cross_validator",
    "priority": 2400,
    "xdv_ceidg_pkd_codes": ceidg_pkd,
    "xdv_jpk_gtu_codes": jpk_gtu,
    "xdv_pkd_gtu_mismatch": has_mismatch,
    "xdv_unexpected_gtu": unexpected_gtu,
    "_routing": ceidg_routing,
    "_routing_reason": ceidg_reason,
    "_legal_basis": "Art. 22 PP (CEIDG); Art. 106e VAT (GTU)",
    "_warnings": [
        "📋 CEIDG vs JPK_V7 — PKD ↔ GTU",
        sprintf("   Kody PKD (CEIDG): %s", [ceidg_pkd]),
        sprintf("   Kody GTU (JPK): %s", [jpk_gtu]),
        sprintf("   Niezgodność: %s", [unexpected_gtu])
    ]
}) {
    object.get(input, "xdv_ceidg_vs_jpk_check", false) == true
    ceidg_pkd := object.get(input, "ceidg_pkd_codes", "62.01.Z")
    jpk_gtu := object.get(input, "jpk_gtu_codes_used", "GTU_12")
    has_mismatch := mismatch_for_pkd(ceidg_pkd, jpk_gtu)
    unexpected_gtu := unexpected_gtu_for_pkd(ceidg_pkd, jpk_gtu)
    ceidg_routing := ceidg_routing_for_mismatch(has_mismatch)
    ceidg_reason := ceidg_mismatch_reason(has_mismatch, unexpected_gtu)
}

# XDV-2405: comprehensive audit risk scorer
risk_points_jpk(discrepancy) = 30 {
    discrepancy > 10
}

risk_points_jpk(discrepancy) = 15 {
    discrepancy > 5
    discrepancy <= 10
}

risk_points_jpk(discrepancy) = 0 {
    discrepancy <= 5
}

pit_zus_discrepant(payload) = true {
    object.get(payload, "xdv_pit_zus_consistent", true) == false
}

pit_zus_discrepant(payload) = false {
    object.get(payload, "xdv_pit_zus_consistent", true) != false
}

risk_point_pit_zus(discrepant) = 20 {
    discrepant
}

risk_point_pit_zus(discrepant) = 0 {
    not discrepant
}

risk_point_flag(flag, points) = points {
    flag == true
}

risk_point_flag(flag, points) = 0 {
    flag == false
}

risk_level_from_score(score) = "LOW" {
    score <= 20
}

risk_level_from_score(score) = "MEDIUM" {
    score > 20
    score <= 50
}

risk_level_from_score(score) = "HIGH" {
    score > 50
    score <= 75
}

risk_level_from_score(score) = "CRITICAL" {
    score > 75
}

risk_count_flag(flag) = 1 {
    flag == true
}

risk_count_flag(flag) = 0 {
    flag == false
}

risk_routing_from_level(level) = "BLOCK_AND_ALERT" {
    level == "CRITICAL"
}

risk_routing_from_level(level) = "TRIAGE_QUEUE" {
    level == "HIGH"
}

risk_routing_from_level(level) = "TRIAGE_QUEUE" {
    level == "MEDIUM"
}

risk_routing_from_level(level) = "" {
    level == "LOW"
}

risk_reason_from_level(level, score) = reason {
    level == "HIGH"
    reason := sprintf("RYZYKO KONTROLI: %s (score %d/100) — uzgodnij deklaracje przed wysyłką!", [level, score])
}

risk_reason_from_level(level, score) = reason {
    level == "CRITICAL"
    reason := sprintf("RYZYKO KONTROLI: %s (score %d/100) — uzgodnij deklaracje przed wysyłką!", [level, score])
}

risk_reason_from_level(level, score) = "" {
    level == "LOW"
}

risk_reason_from_level(level, score) = "" {
    level == "MEDIUM"
}

else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_validator.audit_risk_scorer",
    "package": "jdg.cross_validator",
    "priority": 2405,
    "xdv_audit_risk_score": risk_score,
    "xdv_audit_risk_level": risk_level,
    "xdv_risk_factors_count": factors_count,
    "_routing": audit_routing,
    "_routing_reason": audit_reason,
    "_legal_basis": "Art. 193 OrdPU; Art. 81-81b OrdPU; Art. 282b-282c OrdPU",
    "_warnings": [
        sprintf("🔍 AUDIT RISK SCORER — %d czynników ryzyka", [factors_count]),
        sprintf("   Score: %d/100 | Poziom ryzyka: %s", [risk_score, risk_level])
    ]
}) {
    object.get(input, "xdv_audit_risk_score", false) == true
    jpk_pit_disc := object.get(input, "xdv_jpk_pit_discrepancy_pct", 0)
    pit_zus_disc := pit_zus_discrepant(input)
    ceidg_gtu_mismatch := object.get(input, "xdv_ceidg_gtu_mismatch", false)
    vat_refund_high := object.get(input, "xdv_vat_refund_over_100k", false)
    first_year := object.get(input, "xdv_first_year_business", false)
    cross_border := object.get(input, "xdv_cross_border_transactions", false)
    sector_risk := object.get(input, "xdv_high_risk_sector", false)

    s1 := risk_points_jpk(jpk_pit_disc)
    s2 := risk_point_pit_zus(pit_zus_disc)
    s3 := risk_point_flag(ceidg_gtu_mismatch, 10)
    s4 := risk_point_flag(vat_refund_high, 25)
    s5 := risk_point_flag(first_year, 5)
    s6 := risk_point_flag(cross_border, 15)
    s7 := risk_point_flag(sector_risk, 5)
    risk_score := s1 + s2 + s3 + s4 + s5 + s6 + s7
    risk_level := risk_level_from_score(risk_score)
    factors_count := risk_count_flag(jpk_pit_disc > 5) + risk_count_flag(pit_zus_disc) + risk_count_flag(ceidg_gtu_mismatch) + risk_count_flag(vat_refund_high) + risk_count_flag(first_year) + risk_count_flag(cross_border) + risk_count_flag(sector_risk)
    audit_routing := risk_routing_from_level(risk_level)
    audit_reason := risk_reason_from_level(risk_level, risk_score)
}
