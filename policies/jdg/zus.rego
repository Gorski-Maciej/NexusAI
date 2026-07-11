# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — ZUS: Składki społeczne, zdrowotne, ulgi (P700-P770)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: ZUS Package — Social & Health Insurance for JDG
# description: |
#   First-Match-Wins else-chain dla składek ZUS.
#   Kolejność: P740 (start relief) → P741 (mały ZUS+) → P742 (preferencyjny) →
#   P700 (standard) → P720/P722/P724 (zdrowotna per forma) → P743 (zbieg etat+JDG).
#   Stawki: skala/karta=9%, liniowy/ryczałt=4.9%.
#   Zdrowotna NIE odlicza się od PIT na skali (Polski Ład 2022).
# legal_basis: Art. 18-36a SUS, Art. 79-81 u. zdrowotnej, Art. 30c PIT
# edge_cases:
#   - Przejście między ulgami (start→pref→standard)
#   - Zbieg etat+JDG (tylko zdrowotna, społeczne z etatu)
#   - Roczne rozliczenie zdrowotnej (ryczałt, liniowy)
# package: jdg.zus
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.zus

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.zus.no_match",
    "package": "jdg.zus", "priority": 780
}

# ═══════════════════════════════════════════════════════════════════════════════
# P740: zus_start_relief_jdg — Ulga na start (6 miesięcy)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true, "rule_id": "jdg.zus.start_relief",
    "package": "jdg.zus", "priority": 740,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "START_RELIEF", "zus_social_base_percent": 0,
    "zus_health_rate": "0.09", "zus_health_only": true,
    "zus_months_remaining": 6 - used_months,
    "zus_sickness_voluntary": false,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 18a ustawy o SUS",
    "_warnings": [sprintf("Ulga na start — %d miesięcy bez składek społecznych (tylko zdrowotna)", [6 - used_months])],
    "_future_events": [{
        "event_id":"start_relief_expiry",
        "event_type":"ZUS_RELIEF_EXPIRY",
        "description":sprintf("Ulga na start wygasa za %d miesięcy — przejdź na preferencyjny/standardowy ZUS", [6 - used_months]),
        "due_date_horizon":sprintf("+%dmo", [6 - used_months]),
        "action":"SWITCH_TO_PREFERENTIAL_OR_STANDARD",
        "priority":"HIGH"
    }]
} {
    input.jdg_entrepreneur.zus_status == "START_RELIEF"
    used_months := object.get(input.jdg_entrepreneur, "zus_months_used_current_status", 0)
    used_months < 6
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P741: zus_maly_plus_jdg — Mały ZUS Plus (36 miesięcy)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.zus.maly_plus",
    "package": "jdg.zus", "priority": 741,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "MALY_ZUS_PLUS", "zus_social_base_percent": 30,
    "zus_base_amount": floor(0.30 * min_wage),
    "zus_health_rate": "0.09",
    "zus_months_remaining": 36 - used_months,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 18c ustawy o SUS",
    "_warnings": [sprintf("Mały ZUS Plus — podstawa %.2f PLN, pozostało %d miesięcy", [floor(0.30 * min_wage), 36 - used_months])],
    "_future_events": [{
        "event_id":"maly_plus_expiry",
        "event_type":"ZUS_RELIEF_EXPIRY",
        "description":sprintf("Mały ZUS Plus wygasa za %d miesięcy — przejdź na standardowy ZUS", [36 - used_months]),
        "due_date_horizon":sprintf("+%dmo", [36 - used_months]),
        "action":"SWITCH_TO_STANDARD_ZUS",
        "priority":"HIGH"
    }]
} {
    input.jdg_entrepreneur.zus_status == "MALY_ZUS_PLUS"
    used_months := object.get(input.jdg_entrepreneur, "zus_months_used_current_status", 0)
    used_months < 36
    min_wage := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "minimum_wage_gross", 4666)
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P742: zus_preferential_jdg — Preferencyjny ZUS (24 miesiące)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.zus.preferential",
    "package": "jdg.zus", "priority": 742,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "PREFERENTIAL", "zus_social_base_percent": 30,
    "zus_health_rate": "0.09",
    "zus_months_remaining": 24 - used_months,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 18a ustawy o SUS",
    "_warnings": [sprintf("Preferencyjny ZUS — pozostało %d miesięcy", [24 - used_months])],
    "_future_events": [{
        "event_id":"preferential_expiry",
        "event_type":"ZUS_RELIEF_EXPIRY",
        "description":sprintf("Preferencyjny ZUS wygasa za %d miesięcy — przejdź na standardowy ZUS", [24 - used_months]),
        "due_date_horizon":sprintf("+%dmo", [24 - used_months]),
        "action":"SWITCH_TO_STANDARD_ZUS",
        "priority":"HIGH"
    }]
} {
    input.jdg_entrepreneur.zus_status == "PREFERENTIAL"
    used_months := object.get(input.jdg_entrepreneur, "zus_months_used_current_status", 0)
    used_months < 24
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
}

# ═══════════════════════════════════════════════════════════════════════════════
# P700: zus_social_standard_jdg — Standardowe składki społeczne JDG
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.zus.social_standard",
    "package": "jdg.zus", "priority": 700,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "STANDARD",
    "zus_pension_rate": "0.1952", "zus_disability_rate": "0.08",
    "zus_sickness_rate": sickness_rate, "zus_accident_rate": "0.0167",
    "zus_labour_fund_rate": "0.0245",
    "zus_health_rate": health_rate,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 18, 18a, 22 ustawy o SUS",
    "_warnings": []
} {
    input.jdg_entrepreneur.zus_status == "STANDARD"
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")

    # Sickness insurance is VOLUNTARY for JDG
    sickness_rate = "0.00" { input.jdg_entrepreneur.zus_sickness_voluntary == false }
    sickness_rate = "0.0245" { input.jdg_entrepreneur.zus_sickness_voluntary == true }

    # Health insurance rate depends on tax form
    health_rate = "0.09" { pit_form == "PIT_SCALE" }
    health_rate = "0.09" { pit_form == "TAX_CARD" }
    health_rate = "0.049" { pit_form == "LINEAR" }
    health_rate = "0.049" { pit_form == "LUMP_SUM" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P720: zus_health_scale_jdg — Składka zdrowotna 9% (skala)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.zus.health_scale",
    "package": "jdg.zus", "priority": 720,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "0.09",
    "zus_health_base": "INCOME", "zus_health_deductible_from_tax": false,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 79 ust. 1, art. 81 ust. 1 ustawy o świadczeniach opieki zdrowotnej",
    "_warnings": ["Składka zdrowotna 9% od dochodu — NIE odlicza się od podatku (skala)"]
} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P722: zus_health_linear_jdg — Składka zdrowotna 4.9% (liniowy)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.zus.health_linear",
    "package": "jdg.zus", "priority": 722,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LINEAR", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "0.049",
    "zus_health_base": "INCOME", "zus_health_limit_type": "LINEAR_LIMITED",
    "zus_health_annual_deduction_limit": 12900, "zus_health_deductible_from_income": true,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 79 ust. 2, art. 81 ust. 2, art. 30c ust. 2 pkt 2 PIT",
    "_warnings": ["Składka zdrowotna 4.9% — odliczenie od dochodu max 12 900 PLN rocznie"]
} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P724: zus_health_lump_sum_jdg — Składka zdrowotna ryczałt (progi)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.zus.health_lump_sum",
    "package": "jdg.zus", "priority": 724,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LUMP_SUM", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "0.049",
    "zus_health_base": "LUMP_SUM_TIERS", "zus_health_limit_type": "LUMP_SUM_TIER",
    "zus_health_tier": tier, "zus_health_tier_base_percent": tier_percent,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 81 ust. 2a-2c ustawy o świadczeniach opieki zdrowotnej",
    "_warnings": [sprintf("Składka zdrowotna ryczałt — próg %s, podstawa %.0f%% przeciętnego wynagrodzenia", [tier, tier_percent])]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    revenue := object.get(input.jdg_entrepreneur, "lump_sum_annual_revenue", 0)

    tier = "TIER_1" { revenue <= 60000 }
    tier_percent = 60 { revenue <= 60000 }

    tier = "TIER_2" { revenue > 60000; revenue <= 300000 }
    tier_percent = 100 { revenue > 60000; revenue <= 300000 }

    tier = "TIER_3" { revenue > 300000 }
    tier_percent = 180 { revenue > 300000 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P743: concurrent_employment_exemption — Zbieg etat+JDG → tylko zdrowotna
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true, "rule_id": "jdg.zus.concurrent_employment",
    "package": "jdg.zus", "priority": 743,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "CONCURRENT_EMPLOYMENT",
    "zus_social_due": false, "zus_health_due": true,
    "zus_health_rate": health_rate,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 9 ust. 2a ustawy o SUS",
    "_warnings": ["Zbieg etat+JDG — tylko składka zdrowotna z JDG (społeczne z etatu)"],
    "_future_events": [{
        "event_id":"concurrent_employment_monitor",
        "event_type":"COMPLIANCE_CHECK",
        "description":"Monitoruj zbieg etat+JDG — jeśli etat się kończy, wznów pełne składki społeczne",
        "due_date_horizon":"+30d",
        "action":"MONITOR_EMPLOYMENT_STATUS",
        "priority":"MEDIUM"
    }]
} {
    input.jdg_entrepreneur.concurrent_employment == true
    input.jdg_entrepreneur.concurrent_employment_salary >= min_wage
    min_wage := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "minimum_wage_gross", 4666)
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    health_rate = "0.09" { pit_form == "PIT_SCALE" }
    health_rate = "0.049" { pit_form == "LINEAR" }
}
