# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE CROSS-DECLARATION VALIDATOR (Innovation 8.11, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Cross-Declaration Validator — JPK_V7 vs PIT vs ZUS
# description: |
#   ENTERPRISE v7.0 — Walidator spójności między deklaracjami JDG.
#   Sprawdza zgodność danych między: JPK_V7 (VAT), PIT-36/36L (dochód),
#   ZUS DRA (składki), PKPiR/Księgi (ewidencja), CEIDG (dane rejestrowe).
#
#   KLUCZOWE FUNKCJE:
#   - JPK_V7 vs PIT-36: VAT należny a przychód wg PIT
#   - PIT-36 vs ZUS DRA: dochód a podstawa składek ZUS
#   - JPK_V7 vs PKPiR: zgodność kosztów i przychodów
#   - CEIDG vs JPK_V7: kody PKD a kody GTU
#   - Detekcja ryzyka kontroli krzyżowej US
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 193 OrdPU; Art. 109 ust. 3d VAT; Art. 45 PIT
# package: jdg.cross_validator
# deprecated: false
# priority_range: 2390-2419
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.cross_validator

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.cross_validator.no_match",
    "package": "jdg.cross_validator", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# XDV-2390: JPK_V7 vs PIT-36 REVENUE CROSS-CHECK
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.cross_validator.jpk_vs_pit_revenue",
    "package": "jdg.cross_validator",
    "priority": 2390,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "xdv_jpk_v7_net_sales": jpk_sales,
    "xdv_pit_revenue": pit_revenue,
    "xdv_discrepancy": discrepancy,
    "xdv_discrepancy_pct": discrepancy_pct,
    "xdv_risk_flag": risk_flag,
    "_routing": xdv_routing,
    "_routing_reason": xdv_reason,
    "_legal_basis": "Art. 109 ust. 3d VAT; Art. 45 ust. 1 PIT; Art. 193 OrdPU",
    "_warnings": build_xdv_warnings("JPK_V7 vs PIT", jpk_sales, pit_revenue, discrepancy, discrepancy_pct, risk_flag)
} {
    input.xdv_jpk_vs_pit_check == true
    jpk_sales := object.get(input, "jpk_v7_annual_net_sales", 0)
    pit_revenue := object.get(input, "pit_annual_revenue", 0)
    discrepancy := abs(jpk_sales - pit_revenue)
    discrepancy_pct := discrepancy * 100 / max([pit_revenue, 1])

    risk_flag := "LOW" { discrepancy_pct <= 1 }
    risk_flag := "MEDIUM" { discrepancy_pct > 1; discrepancy_pct <= 5 }
    risk_flag := "HIGH" { discrepancy_pct > 5; discrepancy_pct <= 10 }
    risk_flag := "CRITICAL" { discrepancy_pct > 10 }

    xdv_routing := "BLOCK_AND_ALERT" { risk_flag == "CRITICAL" }
    xdv_routing := "TRIAGE_QUEUE" { risk_flag in {"HIGH", "MEDIUM"} }
    xdv_routing := "" { true }
    xdv_reason := sprintf("ROZBIEŻNOŚĆ JPK vs PIT: %.0f PLN (%.1f%%) — ryzyko kontroli krzyżowej US!", [discrepancy, discrepancy_pct]) { risk_flag in {"HIGH", "CRITICAL"} }
    xdv_reason := "" { true }
}

build_xdv_warnings(label, val1, val2, disc, pct, risk) = warnings {
    warnings := [
        sprintf("🔗 CROSS-CHECK: %s", [label]),
        sprintf("   JPK_V7: %.0f PLN | PIT: %.0f PLN", [val1, val2]),
        sprintf("   Rozbieżność: %.0f PLN (%.1f%%) | Ryzyko: %s", [disc, pct, risk]),
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# XDV-2395: PIT vs ZUS DRA INCOME CHECK
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_validator.pit_vs_zus_income",
    "package": "jdg.cross_validator",
    "priority": 2395,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "xdv_pit_annual_income": pit_income,
    "xdv_zus_monthly_base_avg": zus_base_avg,
    "xdv_zus_annual_implied_income": implied_income,
    "xdv_pit_zus_ratio": ratio,
    "xdv_pit_zus_consistent": consistent,
    "_routing": zus_routing,
    "_routing_reason": zus_reason,
    "_legal_basis": "Art. 18-19 SUS; Art. 45 PIT; Art. 81 OrdPU",
    "_warnings": [
        sprintf("🏥 PIT vs ZUS DRA — CROSS-CHECK", []),
        sprintf("   Dochód PIT: %.0f PLN/rok", [pit_income]),
        sprintf("   Średnia podstawa ZUS: %.0f PLN/mies → %.0f PLN/rok implikowany dochód", [zus_base_avg, implied_income]),
        sprintf("   Ratio (implikowany PIT/ZUS): %.2f %s", [ratio, "✅" { consistent } else "⚠️ ROZBIEŻNOŚĆ!"]),
    ]
} {
    input.xdv_pit_vs_zus_check == true
    pit_income := object.get(input, "pit_annual_income", 0)
    zus_base_avg := object.get(input, "zus_monthly_contribution_base_avg", 0)
    implied_income := zus_base_avg * 12 * 2  # Szacowany roczny dochód z podstawy ZUS
    ratio := pit_income / max([implied_income, 1])
    consistent := ratio >= 0.5 and ratio <= 2.0

    zus_routing := "TRIAGE_QUEUE" { not consistent }
    zus_routing := "" { true }
    zus_reason := sprintf("PIT/ZUS: dochód PIT %.0f PLN vs implikowany z ZUS %.0f PLN — sprawdź spójność.", [pit_income, implied_income]) { not consistent }
    zus_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# XDV-2400: CEIDG vs JPK PKD-GTU CROSS-CHECK
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_validator.ceidg_vs_jpk_pkd",
    "package": "jdg.cross_validator",
    "priority": 2400,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "xdv_ceidg_pkd_codes": ceidg_pkd,
    "xdv_jpk_gtu_codes": jpk_gtu,
    "xdv_pkd_gtu_mismatch": has_mismatch,
    "xdv_unexpected_gtu": unexpected_gtu,
    "_routing": ceidg_routing,
    "_routing_reason": ceidg_reason,
    "_legal_basis": "Art. 22 PP (CEIDG); Art. 106e VAT (GTU)",
    "_warnings": [
        sprintf("📋 CEIDG vs JPK_V7 — PKD ↔ GTU", []),
        sprintf("   Kody PKD (CEIDG): %s", [ceidg_pkd]),
        sprintf("   Kody GTU (JPK): %s", [jpk_gtu]),
        sprintf("   %s", ["✅ Kody GTU zgodne z profilami PKD." { not has_mismatch } else sprintf("⚠️ NIEOczekiwany GTU: %s — zweryfikuj czy działalność odpowiada kodom GTU!", [unexpected_gtu])]),
    ]
} {
    input.xdv_ceidg_vs_jpk_check == true
    ceidg_pkd := object.get(input, "ceidg_pkd_codes", "62.01.Z")
    jpk_gtu := object.get(input, "jpk_gtu_codes_used", "GTU_12")

    # Heurystyka: IT (62.01.Z, 62.02.Z) → GTU_12; Handel (47.x) → GTU_01 lub brak GTU
    it_pkd := contains(ceidg_pkd, "62.")
    trade_pkd := contains(ceidg_pkd, "47.") or contains(ceidg_pkd, "46.")
    construction_pkd := contains(ceidg_pkd, "41.") or contains(ceidg_pkd, "43.")

    unexpected_gtu := ""
    has_mismatch := (trade_pkd and contains(jpk_gtu, "GTU_12")) or (it_pkd and contains(jpk_gtu, "GTU_10"))
    unexpected_gtu := "GTU_12 przy PKD handlowym" { trade_pkd; contains(jpk_gtu, "GTU_12") }
    unexpected_gtu := "" { not has_mismatch }

    ceidg_routing := "TRIAGE_QUEUE" { has_mismatch }
    ceidg_routing := "" { true }
    ceidg_reason := sprintf("CEIDG vs GTU: %s — potencjalna niezgodność rejestrowa vs faktyczna działalność.", [unexpected_gtu]) { has_mismatch }
    ceidg_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# XDV-2405: COMPREHENSIVE AUDIT RISK SCORER — Scoring ryzyka kontroli US
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_validator.audit_risk_scorer",
    "package": "jdg.cross_validator",
    "priority": 2405,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "xdv_audit_risk_score": risk_score,
    "xdv_audit_risk_level": risk_level,
    "xdv_risk_factors_count": factors_count,
    "_routing": audit_routing,
    "_routing_reason": audit_reason,
    "_legal_basis": "Art. 193 OrdPU; Art. 81-81b OrdPU (czynności sprawdzające); Art. 282b-282c OrdPU",
    "_warnings": [
        sprintf("🔍 AUDIT RISK SCORER — %d czynników ryzyka", [factors_count]),
        sprintf("   Score: %d/100 | Poziom ryzyka: %s", [risk_score, risk_level]),
    ]
} {
    input.xdv_audit_risk_score == true

    # Czynniki ryzyka kontroli US
    jpk_pit_disc := object.get(input, "xdv_jpk_pit_discrepancy_pct", 0)
    pit_zus_disc := not object.get(input, "xdv_pit_zus_consistent", true)
    ceidg_gtu_mismatch := object.get(input, "xdv_ceidg_gtu_mismatch", false)
    vat_refund_high := object.get(input, "xdv_vat_refund_over_100k", false)
    first_year := object.get(input, "xdv_first_year_business", false)
    cross_border := object.get(input, "xdv_cross_border_transactions", false)
    sector_risk := object.get(input, "xdv_high_risk_sector", false)

    # Risk score calculator — use weighted sum of boolean flags (each * weight)
    s1 := 30 { jpk_pit_disc > 10 }
    s2 := 15 { jpk_pit_disc > 5; jpk_pit_disc <= 10 }
    s3 := 20 { pit_zus_disc }
    s4 := 10 { ceidg_gtu_mismatch }
    s5 := 25 { vat_refund_high }
    s6 := 5 { first_year }
    s7 := 15 { cross_border }
    s8 := 5 { sector_risk }
    # Default to 0 when condition not met
    s1 := 0 { jpk_pit_disc <= 10 }
    s2 := 0 { not (jpk_pit_disc > 5; jpk_pit_disc <= 10) }
    s3 := 0 { not pit_zus_disc }
    s4 := 0 { not ceidg_gtu_mismatch }
    s5 := 0 { not vat_refund_high }
    s6 := 0 { not first_year }
    s7 := 0 { not cross_border }
    s8 := 0 { not sector_risk }
    risk_score := s1 + s2 + s3 + s4 + s5 + s6 + s7 + s8

    risk_level := "LOW" { risk_score <= 20 }
    risk_level := "MEDIUM" { risk_score > 20; risk_score <= 50 }
    risk_level := "HIGH" { risk_score > 50; risk_score <= 75 }
    risk_level := "CRITICAL" { risk_score > 75 }

    # Factor count as sum of booleans (1 per factor)
    f1 := 1 { jpk_pit_disc > 5 }
    f2 := 1 { pit_zus_disc }
    f3 := 1 { ceidg_gtu_mismatch }
    f4 := 1 { vat_refund_high }
    f5 := 1 { first_year }
    f6 := 1 { cross_border }
    f7 := 1 { sector_risk }
    f1 := 0 { jpk_pit_disc <= 5 }
    f2 := 0 { not pit_zus_disc }
    f3 := 0 { not ceidg_gtu_mismatch }
    f4 := 0 { not vat_refund_high }
    f5 := 0 { not first_year }
    f6 := 0 { not cross_border }
    f7 := 0 { not sector_risk }
    factors_count := f1 + f2 + f3 + f4 + f5 + f6 + f7

    audit_routing := "BLOCK_AND_ALERT" { risk_level == "CRITICAL" }
    audit_routing := "TRIAGE_QUEUE" { risk_level in {"HIGH", "MEDIUM"} }
    audit_routing := "" { true }
    audit_reason := sprintf("RYZYKO KONTROLI: %s (score %d/100) — uzgodnij deklaracje przed wysyłką!", [risk_level, risk_score]) { risk_level in {"HIGH", "CRITICAL"} }
    audit_reason := "" { true }
}
