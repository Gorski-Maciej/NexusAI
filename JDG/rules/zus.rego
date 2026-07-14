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
    "package": "jdg.zus", "priority": 800
}

# ═══════════════════════════════════════════════════════════════════════════════
# P779: zus_health_minimum_base_guarantee_jdg — Gwarancja minimalnej podstawy
# ═══════════════════════════════════════════════════════════════════════════════
# 🚨 CRITICAL: Nawet przy zerowym dochodzie składka ≥ 9%/4.9% min. wynagrodzenia
# Podstawa prawna: Art. 81 ust. 2, Art. 81 ust. 2a u.ś.o.z.
# ═══════════════════════════════════════════════════════════════════════════════

# ── P779: Minimum base guarantee — standalone helper ────────────────────────────
zus_health_minimum_base_guarantee := {
    "rule_id": "jdg.zus.health_minimum_base",
    "package": "jdg.zus",
    "priority": 779,
    "zus_health_base_min": min_wage,
    "zus_health_base_rule": "MAX_OF_INCOME_OR_MINIMUM_WAGE",
    "_legal_basis": "Art. 81 ust. 2 u.ś.o.z.",
    "_info": sprintf("Minimalna podstawa składki zdrowotnej: %.2f PLN (100%% minimalnego wynagrodzenia)", [min_wage])
}

# ═══════════════════════════════════════════════════════════════════════════════
# P773: zus_maly_plus_income_limit_monitoring_jdg — Monitorowanie limitu MZP
# ═══════════════════════════════════════════════════════════════════════════════

maly_zus_plus_limit_monitor := {
    "rule_id": "jdg.zus.maly_plus_limit_exceeded",
    "package": "jdg.zus",
    "priority": 773,
    "maly_zus_plus_loss_next_year": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Przekroczono limit 120 000 PLN przychodu — utrata Małego ZUS Plus od stycznia", []),
    "_legal_basis": "Art. 18c ust. 8 SUS",
    "_warnings": [sprintf("Przekroczyłeś limit przychodu 120 000 PLN (%.2f PLN) — od stycznia przyszłego roku utrata Małego ZUS Plus. Standardowy ZUS.", [cum_rev])],
    "_future_events": [{
        "event_id": "maly_plus_loss",
        "event_type": "ZUS_STATUS_CHANGE",
        "description": "Utrata Małego ZUS Plus od stycznia przyszłego roku",
        "due_date_horizon": "NEXT_YEAR_JANUARY",
        "action": "SWITCH_TO_STANDARD_ZUS",
        "priority": "HIGH"
    }]
} {
    object.get(input.jdg_entrepreneur, "zus_status", "") == "MALY_ZUS_PLUS"
    cum_rev := object.get(input.jdg_entrepreneur, "cumulative_revenue_current_year", 0)
    revenue_limit := object.get(object.get(object.get(data.thresholds, "jdg", {}), "limits", {}), "zus_maly_plus_revenue_limit", 120000)
    cum_rev > revenue_limit
}

# ═══════════════════════════════════════════════════════════════════════════════
# P782: zus_concurrent_mandate_jdg — Zbieg JDG + umowa zlecenie
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Zlecenie ma pierwszeństwo przed JDG jeśli podstawa ≥ min. wynagrodzenie
# Podstawa prawna: Art. 9 ust. 2-2c SUS
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true, "rule_id": "jdg.zus.concurrent_mandate",
    "package": "jdg.zus", "priority": 782,
    "immutable_verdict": true,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_social_priority": "MANDATE",
    "zus_social_from_jdg": false,
    "zus_health_due": true,
    "zus_health_rate": health_rate,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 9 ust. 2-2c SUS",
    "_warnings": [sprintf("Zbieg JDG+zlecenie — podstawa zlecenia %.2f PLN ≥ min. %.2f PLN. Społeczne ze zlecenia, z JDG tylko zdrowotna.", [mandate_base, min_wage])]
} {
    input.jdg_entrepreneur.has_mandate_contract == true
    mandate_base := object.get(input.jdg_entrepreneur, "mandate_monthly_base", 0)
    min_wage := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "minimum_wage_gross", 4666)
    mandate_base >= min_wage
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    health_rate = "0.09" { pit_form == "PIT_SCALE" }
    health_rate = "0.049" { pit_form == "LINEAR" }
    health_rate = "0.049" { pit_form == "LUMP_SUM" }
    health_rate = "0.09" { pit_form == "TAX_CARD" }
}

# ═══════════════════════════════════════════════════════════════════════════════
# P784: zus_payment_deadlines_by_entity_type_jdg — Terminy płatności ZUS
# ═══════════════════════════════════════════════════════════════════════════════

zus_payment_deadlines_info := {
    "rule_id": "jdg.zus.payment_deadlines",
    "package": "jdg.zus",
    "priority": 784,
    "zus_payment_deadline_day": 10,
    "zus_declaration_deadline_day": 10,
    "_legal_basis": "Art. 47 ust. 1 pkt 2 SUS",
    "_warnings": ["Składki ZUS opłać do 10. dnia następnego miesiąca. Jeśli 10. wypada w weekend/święto → następny dzień roboczy."]
} {
    object.get(input.jdg_entrepreneur, "entity_type", "") == "JDG"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P780: zus_health_annual_reconciliation_all_forms_jdg — Roczne rozliczenie
# ═══════════════════════════════════════════════════════════════════════════════

zus_annual_health_reconciliation := {
    "rule_id": "jdg.zus.health_annual_reconciliation",
    "package": "jdg.zus",
    "priority": 780,
    "health_annual_overpayment": max([0, paid_total - due_total]),
    "health_annual_underpayment": max([0, due_total - paid_total]),
    "_legal_basis": "Art. 81 ust. 2e-2g u.ś.o.z.",
    "_warnings": [sprintf("Roczne rozliczenie składki zdrowotnej — zapłacono %.2f PLN, należne %.2f PLN. %s", [paid_total, due_total, balance_info])]
} {
    paid_total := object.get(input.jdg_entrepreneur, "zus_health_paid_annual", 0)
    due_total := object.get(input.jdg_entrepreneur, "zus_health_due_annual", 0)
    paid_total != due_total
    balance_info = sprintf("Dopłać %.2f PLN do ZUS", [due_total - paid_total]) { due_total > paid_total }
    balance_info = sprintf("Nadpłata %.2f PLN — ZUS powinien zwrócić", [paid_total - due_total]) { paid_total > due_total }
}

decide := {
    "matched": true, "rule_id": "jdg.zus.start_relief",
    "package": "jdg.zus", "priority": 740,
    "immutable_verdict": true,
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
    "immutable_verdict": true,
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
    "immutable_verdict": true,
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
    "immutable_verdict": true,
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
    "immutable_verdict": true,
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
    "immutable_verdict": true,
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
    "immutable_verdict": true,
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
    "immutable_verdict": true,
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

# ══════ P1222: zus_concurrent_low_salary — Zbieg etat+JDG (pensja < min) (Doc 36) ══════
else := {
    "matched": true, "rule_id": "jdg.zus.concurrent_low_salary",
    "package": "jdg.zus", "priority": 1222,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "STANDARD_FROM_JDG",
    "zus_social_due": true, "zus_health_due": true,
    "zus_health_rate": health_rate,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Pensja z etatu < minimalna — składki społeczne z JDG",
    "_legal_basis": "Art. 9 ust. 2a ustawy o SUS",
    "_warnings": [sprintf("Pensja z etatu (%.2f PLN) < minimalna (%.2f PLN) — składki społeczne MUSZĄ być płacone z JDG!", [salary, min_wage])]
} {
    input.jdg_entrepreneur.concurrent_employment == true
    salary := object.get(input.jdg_entrepreneur, "concurrent_employment_salary", 0)
    min_wage := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "minimum_wage_gross", 4666)
    salary < min_wage
    salary > 0
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    health_rate := "0.09" { pit_form == "PIT_SCALE" }
    health_rate := "0.049" { pit_form == "LINEAR" }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Ustawa o świadczeniach pieniężnych z ubezpieczenia społecznego           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════ P1200zs: zus_sickness_benefit — Zasiłek chorobowy 80% / 100% ══════
else := {
    "matched": true, "rule_id": "jdg.zus.sickness_benefit",
    "package": "jdg.zus", "priority": 1200,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "zus_benefit_type": "SICKNESS", "zus_benefit_rate": benefit_rate,
    "zus_benefit_eligible": true, "zus_waiting_period_days": waiting_days,
    "zus_benefit_max_days": 182,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 6-18 Ustawy o świadczeniach pieniężnych z ubezpieczenia społecznego",
    "_warnings": [sprintf("ZASIŁEK CHOROBOWY — stawka %s%% podstawy wymiaru. Okres oczekiwania: %d dni. Max 182 dni (270 dni przy gruźlicy/ciąży)", [benefit_pct, waiting_days])]
} {
    input.jdg_entrepreneur.zus_sickness_voluntary == true
    sickness_days := object.get(input.jdg_entrepreneur, "zus_sickness_days", 0)
    sickness_days > 0

    # 80% standard, 100% przy wypadku przy pracy / ciąży
    is_accident := object.get(input.jdg_entrepreneur, "zus_sickness_accident_related", false)
    is_pregnancy := object.get(input.jdg_entrepreneur, "zus_sickness_pregnancy_related", false)

    benefit_rate = "1.00" { is_accident == true }
    benefit_rate = "1.00" { is_pregnancy == true }
    benefit_rate = "0.80" { is_accident == false; is_pregnancy == false }

    benefit_pct = "100" { benefit_rate == "1.00" }
    benefit_pct = "80" { benefit_rate == "0.80" }

    # Okres oczekiwania: 30 dni dla JDG (ubezpieczenie dobrowolne)
    waiting_days = 30 {
        object.get(input.jdg_entrepreneur, "zus_sickness_insurance_months", 0) < 3
    }
    waiting_days = 0 {
        object.get(input.jdg_entrepreneur, "zus_sickness_insurance_months", 0) >= 3
    }
}

# ══════ P1201zs: zus_maternity_benefit — Zasiłek macierzyński ══════
else := {
    "matched": true, "rule_id": "jdg.zus.maternity_benefit",
    "package": "jdg.zus", "priority": 1201,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "zus_benefit_type": "MATERNITY", "zus_benefit_rate": "1.00",
    "zus_benefit_eligible": true, "zus_maternity_weeks": maternity_weeks,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 29-31 Ustawy o świadczeniach pieniężnych z ubezpieczenia społecznego",
    "_warnings": [sprintf("ZASIŁEK MACIERZYŃSKI — 100%% podstawy przez %d tygodni. JDG musi być objęta ubezpieczeniem chorobowym min. 90 dni", [maternity_weeks])]
} {
    input.jdg_entrepreneur.zus_sickness_voluntary == true
    input.jdg_entrepreneur.zus_maternity_claim == true

    child_count := object.get(input.jdg_entrepreneur, "zus_maternity_children", 1)
    maternity_weeks = 20 { child_count == 1 }
    maternity_weeks = 31 { child_count == 2 }
    maternity_weeks = 33 { child_count == 3 }
    maternity_weeks = 35 { child_count == 4 }
    maternity_weeks = 37 { child_count >= 5 }
}

# ══════ P1202zs: zus_care_benefit — Zasiłek opiekuńczy ══════
else := {
    "matched": true, "rule_id": "jdg.zus.care_benefit",
    "package": "jdg.zus", "priority": 1202,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "zus_benefit_type": "CARE", "zus_benefit_rate": "0.80",
    "zus_benefit_eligible": true, "zus_care_max_days": care_max_days,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 32-35 Ustawy o świadczeniach pieniężnych z ubezpieczenia społecznego",
    "_warnings": [sprintf("ZASIŁEK OPIEKUŃCZY — 80%% podstawy. Max %d dni w roku. Opieka nad dzieckiem do 14 lat lub innym członkiem rodziny", [care_max_days])]
} {
    input.jdg_entrepreneur.zus_sickness_voluntary == true
    input.jdg_entrepreneur.zus_care_claim == true

    care_type := object.get(input.jdg_entrepreneur, "zus_care_type", "")
    care_max_days = 60 { care_type == "CHILD_UNDER_14" }
    care_max_days = 14 { care_type == "OTHER_FAMILY_MEMBER" }
    care_max_days = 30 { care_type == "DISABLED_CHILD_UNDER_18" }
}

# ══════ P1203zs: zus_rehabilitation_benefit — Świadczenie rehabilitacyjne ══════
else := {
    "matched": true, "rule_id": "jdg.zus.rehabilitation_benefit",
    "package": "jdg.zus", "priority": 1203,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "zus_benefit_type": "REHABILITATION", "zus_benefit_rate": rehab_rate,
    "zus_benefit_eligible": true, "zus_rehab_max_months": 12,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 18 Ustawy o świadczeniach pieniężnych z ubezpieczenia społecznego",
    "_warnings": [sprintf("ŚWIADCZENIE REHABILITACYJNE — %s%% podstawy przez max 12 miesięcy. Po wyczerpaniu zasiłku chorobowego (182 dni)", [rehab_pct])]
} {
    input.jdg_entrepreneur.zus_sickness_voluntary == true
    input.jdg_entrepreneur.zus_rehabilitation_claim == true

    rehab_month := object.get(input.jdg_entrepreneur, "zus_rehab_month", 1)
    rehab_rate = "0.90" { rehab_month <= 3 }
    rehab_rate = "0.75" { rehab_month > 3; rehab_month <= 9 }
    rehab_rate = "0.60" { rehab_month > 9 }
    rehab_pct = "90" { rehab_month <= 3 }
    rehab_pct = "75" { rehab_month > 3; rehab_month <= 9 }
    rehab_pct = "60" { rehab_month > 9 }
}

# ══════ P1204zs: zus_accident_benefit — Zasiłek wypadkowy 100% ══════
else := {
    "matched": true, "rule_id": "jdg.zus.accident_benefit",
    "package": "jdg.zus", "priority": 1204,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "zus_benefit_type": "ACCIDENT", "zus_benefit_rate": "1.00",
    "zus_benefit_eligible": true, "zus_accident_from_day_1": true,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 6-9 Ustawy o ubezpieczeniu społecznym z tytułu wypadków przy pracy",
    "_warnings": ["ZASIŁEK WYPADKOWY — 100%% podstawy od 1 dnia niezdolności! Wypadek przy pracy / w drodze do pracy. Wymagany protokół powypadkowy"]
} {
    input.jdg_entrepreneur.zus_sickness_voluntary == true
    input.jdg_entrepreneur.zus_accident_at_work == true
}

# ══════ P1205zs: zus_funeral_grant — Zasiłek pogrzebowy ══════
else := {
    "matched": true, "rule_id": "jdg.zus.funeral_grant",
    "package": "jdg.zus", "priority": 1205,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "zus_benefit_type": "FUNERAL", "zus_benefit_amount": funeral_amount,
    "zus_benefit_eligible": true, "zus_funeral_deadline_days": 12,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 77-81 Ustawy o emeryturach i rentach z FUS",
    "_warnings": [sprintf("ZASIŁEK POGRZEBOWY — %.2f PLN. Złóż wniosek w ciągu 12 miesięcy od śmierci. Przysługuje osobie, która pokryła koszty pogrzebu", [funeral_amount])]
} {
    input.jdg_entrepreneur.zus_funeral_claim == true
    # Kwota zasiłku pogrzebowego: 4000 PLN (2024)
    funeral_amount := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "funeral_grant_amount", 4000)
}

# ══════ P1206zs: zus_benefit_coordination — Koordynacja zasiłków ══════
else := {
    "matched": true, "rule_id": "jdg.zus.benefit_coordination",
    "package": "jdg.zus", "priority": 1206,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "zus_benefit_type": "COORDINATION", "zus_active_benefits_count": active_count,
    "zus_benefit_conflict_detected": has_conflict,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Koordynacja zasiłków — sprawdź czy nie ma konfliktu okresów",
    "_legal_basis": "Art. 41-43 Ustawy o świadczeniach pieniężnych z ubezpieczenia społecznego",
    "_warnings": [sprintf("KOORDYNACJA ZASIŁKÓW — %d aktywnych świadczeń. %s. Zasiłki nie kumulują się — przysługuje jedno świadczenie (wyższe)", [active_count, conflict_info])]
} {
    active_benefits := object.get(input.jdg_entrepreneur, "zus_active_benefits", [])
    active_count := count(active_benefits)
    active_count >= 1

    has_conflict := active_count > 1
    conflict_info = "KONFLIKT: wiele świadczeń w tym samym okresie — wybierz wyższe" { has_conflict == true }
    conflict_info = "Brak konfliktów — jedno świadczenie aktywne" { has_conflict == false }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  P1207zs-P1212zs — EMERYTURY I RENTY ZUS (swiadczenia dlugoterminowe)    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════ P1207zs: zus_old_age_pension — Emerytura ══════
else := {
    "matched": true, "rule_id": "jdg.zus.old_age_pension",
    "package": "jdg.zus", "priority": 1207,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "zus_benefit_type": "OLD_AGE_PENSION", "zus_pension_eligible": true,
    "zus_pension_age": pension_age, "zus_pension_min_years": min_years,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 24-28 Ustawy o emeryturach i rentach z FUS",
    "_warnings": [sprintf("EMERYTURA — wiek: %d lat (kobieta) / %d lat (mezczyzna). Staz: %d lat. Wniosek do ZUS: formularz EMP. Decyzja w 30 dni.", [pension_age_f, pension_age_m, min_years])]
} {
    input.jdg_entrepreneur.pension_claim == true
    min_years := object.get(input.jdg_entrepreneur, "zus_insurance_years", 0)
    is_female := object.get(input.jdg_entrepreneur, "is_female", false)
    pension_age = 60 { is_female == true }
    pension_age = 65 { is_female == false }
    pension_age_f = 60 { is_female == true }
    pension_age_f = 65 { is_female == false }
    pension_age_m = 65
    min_years >= 20
}

# ══════ P1208zs: zus_bridge_pension — Emerytura pomostowa ══════
else := {
    "matched": true, "rule_id": "jdg.zus.bridge_pension",
    "package": "jdg.zus", "priority": 1208,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "zus_benefit_type": "BRIDGE_PENSION", "zus_bridge_pension_eligible": eligible,
    "zus_bridge_pension_special_work_years": special_years,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Ustawa o emeryturach pomostowych z dn. 19.12.2008",
    "_warnings": [sprintf("EMERYTURA POMOSTOWA — %s. Praca w szczegolnych warunkach: %d lat. Wymagany FEP (Fundusz Emerytur Pomostowych).", [eligibility_info, special_years])]
} {
    input.jdg_entrepreneur.bridge_pension_claim == true
    special_years := object.get(input.jdg_entrepreneur, "zus_special_work_years", 0)
    has_fep := object.get(input.jdg_entrepreneur, "zus_fep_contributions", false)
    eligible = (special_years >= 15)
    eligible == true
    eligibility_info = "Spelnione warunki" { has_fep == true }
    eligibility_info = "BRAK skladek FEP — NIE przysluguje" { has_fep == false }
}

# ══════ P1209zs: zus_disability_pension — Renta z tytulu niezdolnosci do pracy ══════
else := {
    "matched": true, "rule_id": "jdg.zus.disability_pension",
    "package": "jdg.zus", "priority": 1209,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "zus_benefit_type": "DISABILITY_PENSION", "zus_disability_degree": degree,
    "zus_disability_min_years": min_years,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Renta — wymagane orzeczenie lekarza orzecznika ZUS",
    "_legal_basis": "Art. 57-64 Ustawy o emeryturach i rentach z FUS",
    "_warnings": [sprintf("RENTA Z TYTULU NIEZDOLNOSCI DO PRACY — stopien: %s. Staz: %d lat (wymagane: 1-5 lat w zaleznosci od wieku). Orzeczenie ZUS + wniosek ERN.", [degree, min_years])]
} {
    input.jdg_entrepreneur.disability_pension_claim == true
    degree := object.get(input.jdg_entrepreneur, "zus_disability_degree", "PARTIAL")
    degree in {"PARTIAL", "FULL", "UNABLE_TO_WORK_INDEPENDENTLY"}
    min_years := object.get(input.jdg_entrepreneur, "zus_insurance_years", 0)
    min_years >= 5
}

# ══════ P1210zs: zus_survivors_pension — Renta rodzinna ══════
else := {
    "matched": true, "rule_id": "jdg.zus.survivors_pension",
    "package": "jdg.zus", "priority": 1210,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "zus_benefit_type": "SURVIVORS_PENSION", "zus_survivors_beneficiaries": beneficiaries,
    "zus_survivors_pension_pct": pension_pct,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 65-74 Ustawy o emeryturach i rentach z FUS",
    "_warnings": [sprintf("RENTA RODZINNA — %d uprawnionych. Swiadczenie: %d%% emerytury/renty zmarlego. Przysluguje: dzieci do 25 lat (nauka), wdowiec/wdowa 50+, sieroty.", [beneficiaries, pension_pct])]
} {
    input.jdg_entrepreneur.survivors_pension_claim == true
    beneficiaries := object.get(input.jdg_entrepreneur, "zus_survivors_beneficiary_count", 0)
    beneficiaries >= 1
    pension_pct = 85 { beneficiaries == 1 }
    pension_pct = 90 { beneficiaries == 2 }
    pension_pct = 95 { beneficiaries >= 3 }
}

# ══════ P1211zs: zus_pre_retirement_benefit — Swiadczenie przedemerytalne ══════
else := {
    "matched": true, "rule_id": "jdg.zus.pre_retirement_benefit",
    "package": "jdg.zus", "priority": 1211,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "zus_benefit_type": "PRE_RETIREMENT", "zus_pre_retirement_eligible": eligible,
    "zus_pre_retirement_amount": pre_ret_amount,
    "_routing": "TRIAGE_QUEUE", "_routing_reason": "Swiadczenie przedemerytalne — wymagany wniosek do ZUS + zaswiadczenie PUP",
    "_legal_basis": "Ustawa o swiadczeniach przedemerytalnych z dn. 30.04.2004",
    "_warnings": [sprintf("SWIADCZENIE PRZEDEMERYTALNE — %.2f PLN/mies. %s. Wymagane: wiek min. 56 lat (kobieta) / 61 lat (mezczyzna), staz 20+ lat, rejestracja w PUP 6+ mies.", [pre_ret_amount, eligibility_info])]
} {
    input.jdg_entrepreneur.pre_retirement_claim == true
    is_female := object.get(input.jdg_entrepreneur, "is_female", false)
    min_age = 56 { is_female == true }
    min_age = 61 { is_female == false }
    current_age := object.get(input.jdg_entrepreneur, "age", 0)
    insurance_years := object.get(input.jdg_entrepreneur, "zus_insurance_years", 0)
    registered_pup := object.get(input.jdg_entrepreneur, "registered_in_pup_6m", false)
    eligible = (current_age >= min_age; insurance_years >= 20; registered_pup == true)
    eligible == true
    pre_ret_amount := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "pre_retirement_benefit_amount", 1800)
    eligibility_info = "Spelnione wszystkie warunki"
}

# ══════ P1212zs: zus_ikze_ike — IKZE / IKE — Dobrowolne konta emerytalne ══════
else := {
    "matched": true, "rule_id": "jdg.zus.ikze_ike",
    "package": "jdg.zus", "priority": 1212,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "zus_ikze_ike_type": account_type,
    "zus_ikze_annual_limit": annual_limit,
    "zus_ikze_tax_benefit": tax_benefit,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Ustawa o IKE z dn. 20.04.2004, Ustawa o IKZE z dn. 12.05.2011",
    "_warnings": [sprintf("IKZE/IKE — %s. Limit roczny: %.2f PLN. Korzysc podatkowa: %s. Wplaty dobrowolne, wyplata po 60 r.z. (IKE) / 65 r.z. (IKZE) zwolniona z PIT.", [account_type, annual_limit, tax_benefit])]
} {
    has_ike := object.get(input.jdg_entrepreneur, "has_ike_account", false)
    has_ikze := object.get(input.jdg_entrepreneur, "has_ikze_account", false)
    account_exists := has_ike | has_ikze
    account_exists == true

    account_type = "IKE" { has_ike == true; has_ikze == false }
    account_type = "IKZE" { has_ikze == true; has_ike == false }
    account_type = "IKE+IKZE" { has_ike == true; has_ikze == true }

    avg_wage := object.get(object.get(object.get(data.thresholds, "jdg", {}), "bounds", {}), "avg_monthly_wage", 7000)
    annual_limit = avg_wage * 3 { has_ike == true; has_ikze == false }
    annual_limit = avg_wage * 1.2 { has_ikze == true; has_ike == false }
    annual_limit = avg_wage * 4.2 { has_ike == true; has_ikze == true }

    tax_benefit = "Zwolnienie z PIT przy wyplacie po 60 r.z. (IKE)" { has_ike == true; has_ikze == false }
    tax_benefit = "Odliczenie od dochodu + 10% zryczaltowany PIT przy wyplacie (IKZE)" { has_ikze == true; has_ike == false }
    tax_benefit = "IKE: zwolnienie PIT + IKZE: odliczenie od dochodu" { has_ike == true; has_ikze == true }
}
