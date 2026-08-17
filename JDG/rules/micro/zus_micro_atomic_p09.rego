# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ZUS MICRO ATOMIC RULES (GLM52 P09 — ENTERPRISE v9.x)
# Package: jdg.micro.zus_atomic_p09
# ───────────────────────────────────────────────────────────────────────────────
# Prawdziwe reguły atomowe mikro-warstwy ZUS (konwerter stubów → reguł
# warunkowych, PROMPT 09 §8): Mały ZUS Plus (art. 18c SUS), przełącznik progu
# zdrowotnej ryczałt (art. 81 ust. 2e-2f u.ś.o.z.), korekta roczna, zasiłki
# (art. 19/29/32/33 ustawy zasiłkowej), terminy (art. 36/47 SUS).
# Kontrakty P01: werdykt 25-polowy + _legal_basis kanoniczne + zero hardcode
# (data.jdg.thresholds.zus.*, ADR-002) + temporalność (valid_from/valid_to).
# Konwencja mikro (INV-018): brak catch-all {true} — brak dopasowania →
# default no_match; wypełnia LUKI makro, nigdy nie nadpisuje (safe_merge:
# lewy argument wygrywa).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.zus_atomic_p09

import future.keywords.if
import future.keywords.else
import future.keywords.in
import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.zus_atomic_p09.no_match",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 999999
}

# ── Helper: progi z data.thresholds (ADR-002 — zero hardcode) ─────────────────
_ths := object.get(data.jdg.thresholds, "zus", {
    "maly_zus_plus_revenue_limit": 120000,
    "maly_zus_plus_months": 36,
    "maly_zus_plus_months_window": 60,
    "maly_zus_plus_base_pct": 30,
    "maly_zus_plus_base_cap_pct": 60,
    "preferential_base_30pct": 1440.00,
    "social_base_standard_60pct": 5460.00,
    "health_min_base_standard": 4800.00,
    "health_min_base_first_year": 3600.00,
    "health_lump_tier_1_limit": 60000,
    "health_lump_tier_2_limit": 300000,
    "health_lump_tier_1_amount": 491.40,
    "health_lump_tier_2_amount": 819.00,
    "health_lump_tier_3_amount": 1474.20,
    "health_lump_tier_1_multiplier": 0.60,
    "health_lump_tier_2_multiplier": 1.00,
    "health_lump_tier_3_multiplier": 1.80,
    "health_scale_rate": 0.09,
    "health_linear_rate": 0.049,
    "health_lump_annual_deadline": "05-22",
    "sickness_waiting_days_employee": 30,
    "sickness_waiting_days_voluntary": 90,
    "sickness_max_days_standard": 182,
    "sickness_max_days_tb": 270,
    "sickness_benefit_rate": 0.80,
    "sickness_hospital_rate": 0.70,
    "sickness_benefit_base_months": 12,
    "sickness_benefit_daily_divisor": 30,
    "payment_deadline_social": 10,
    "payment_deadline_social_employees": 15,
    "payment_deadline_health": 10,
    "reporting_deadline_days": 7,
})

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  SUS a18c — Mały ZUS Plus (reguły atomowe, art. 18c ust. 1-11 SUS)          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zus.a18c.maly_zus_plus_eligibility — warunki wejścia do MZP:
# dochód z poprzedniego roku ≤ 120 000 zł, prowadzenie działalności w co
# najmniej 1 dniu poprzedniego roku, max 36 mies. w oknie 60 mies.
decide := {
    "matched": true,
    "rule_id": "jdg.micro.zus.a18c.maly_zus_plus_eligibility",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 91801,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "MALY_ZUS_PLUS",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Mały ZUS Plus — spełnione warunki art. 18c ust. 1 SUS",
    "_legal_basis": "Art. 18c ust. 1 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO P09] Mały ZUS Plus dostępny — podstawa = 30% dochodu z poprzedniego roku (clamp 30% min. ↔ 60% przeciętnego)"]
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "zus_relief_type", "") == "MALY_ZUS_PLUS"
    prior_income := object.get(input.jdg_entrepreneur, "prior_year_income_pln", 0)
    prior_income <= _ths.maly_zus_plus_revenue_limit
    months_used := object.get(input.jdg_entrepreneur, "maly_zus_plus_months_used", 0)
    months_used < _ths.maly_zus_plus_months
    object.get(input.jdg_entrepreneur, "prior_year_activity_days", 0) >= 1
}

# jdg.micro.zus.a18c.maly_zus_plus_limit_monitor — alert przy zbliżaniu się
# do limitu przychodu 120 000 zł (95% limitu) + prognoza utraty uprawnienia.
else := {
    "matched": true,
    "rule_id": "jdg.micro.zus.a18c.maly_zus_plus_limit_monitor",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 91802,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "MALY_ZUS_PLUS",
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Przychód narastająco ≥ 95% limitu Małego ZUS Plus — monitor utraty uprawnienia",
    "_legal_basis": "Art. 18c ust. 1 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO P09] Ryzyko utraty MZP: przychód narastająco przekroczył 95% limitu 120 000 zł"]
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    cumulative := object.get(input.jdg_entrepreneur, "cumulative_revenue_pln", 0)
    limit := _ths.maly_zus_plus_revenue_limit
    cumulative >= 0.95 * limit
    cumulative <= limit
}

# jdg.micro.zus.a18c.maly_zus_plus_base_calc — podstawa wymiaru składek MZP:
# 30% dochodu z poprzedniego roku, z clampem dolny 30% min. / górny 60%
# przeciętnego (art. 18c ust. 4-5 SUS). Wynik: zus_social_base_type + kwota.
else := {
    "matched": true,
    "rule_id": "jdg.micro.zus.a18c.maly_zus_plus_base_calc",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 91803,
    "vat_rate": "",
    "rounding_level": "GROSZE",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "MALY_ZUS_PLUS",
    "zus_social_base_amount_pln": base,
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Podstawa MZP = 30% dochodu poprzedniego roku (clamp 30% min. ↔ 60% przeciętnego)",
    "_legal_basis": "Art. 18c ust. 4-5 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO P09] Podstawa MZP wyliczona z clampem — patrz _provenance_tree"],
    "_provenance_tree": {
        "art": "18c ust. 4-5",
        "input": "prior_year_income_pln",
        "formula": "min(max(0.30 × dochód, 30% min.), 60% przeciętnego)",
        "base_pln": base
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "zus_relief_type", "") == "MALY_ZUS_PLUS"
    prior_income := object.get(input.jdg_entrepreneur, "prior_year_income_pln", 0)
    raw := 0.30 * prior_income
    floor := _ths.preferential_base_30pct
    cap := _ths.social_base_standard_60pct
    base := round((min(max(raw, floor), cap)) * 100) / 100
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ZDROWOTNA a81c — Przełącznik progu ryczałtu (art. 81 ust. 2e-2f u.ś.o.z.)  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zdrowotna.a81c.tier_switch — miesięczna re-ewaluacja progu wg
# przychodu narastająco (60 000 / 300 000 zł). Granice 59 999 → TIER_I,
# 60 000 → TIER_II, 300 000 → TIER_II, 300 001 → TIER_III (testy graniczne).
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81c.tier_switch.r1",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 92801,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "LUMP_SUM",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": rate,
    "zus_health_tier": tier,
    "zus_health_monthly_amount_pln": amount,
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Przełącznik progu składki zdrowotnej ryczałt — przychód narastająco vs 60k/300k",
    "_legal_basis": "Art. 81 ust. 2e-2f ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)",
    "_warnings": ["[MICRO P09] Zmiana progu zdrowotnej — sprawdź wysokość składki od następnego miesiąca"],
    "_provenance_tree": {
        "art": "81 ust. 2e-2f",
        "input": "lump_sum_cumulative_revenue",
        "tier_1_limit": _ths.health_lump_tier_1_limit,
        "tier_2_limit": _ths.health_lump_tier_2_limit,
        "monthly_amount_pln": amount
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "health_tier_switch_check", false) == true
    object.get(input.jdg_entrepreneur, "tax_form", "") == "LUMP_SUM"
    revenue := object.get(input.jdg_entrepreneur, "lump_sum_cumulative_revenue", 0)
    revenue <= _ths.health_lump_tier_1_limit
    tier := "TIER_I"
    rate := _ths.health_lump_tier_1_multiplier
    amount := _ths.health_lump_tier_1_amount
}

else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81c.tier_switch.r2",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 92802,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "LUMP_SUM",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": rate,
    "zus_health_tier": tier,
    "zus_health_monthly_amount_pln": amount,
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Przełącznik progu składki zdrowotnej ryczałt — TIER II",
    "_legal_basis": "Art. 81 ust. 2e-2f ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)",
    "_warnings": ["[MICRO P09] TIER II — składka 819.00 zł/mies (100% przeciętnego)"],
    "_provenance_tree": {
        "art": "81 ust. 2e-2f",
        "input": "lump_sum_cumulative_revenue",
        "tier_1_limit": _ths.health_lump_tier_1_limit,
        "tier_2_limit": _ths.health_lump_tier_2_limit,
        "monthly_amount_pln": amount
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "health_tier_switch_check", false) == true
    object.get(input.jdg_entrepreneur, "tax_form", "") == "LUMP_SUM"
    revenue := object.get(input.jdg_entrepreneur, "lump_sum_cumulative_revenue", 0)
    revenue > _ths.health_lump_tier_1_limit
    revenue <= _ths.health_lump_tier_2_limit
    tier := "TIER_II"
    rate := _ths.health_lump_tier_2_multiplier
    amount := _ths.health_lump_tier_2_amount
}

else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81c.tier_switch.r3",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 92803,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "LUMP_SUM",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": rate,
    "zus_health_tier": tier,
    "zus_health_monthly_amount_pln": amount,
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Przychód > 300 000 zł — TIER III (180% przeciętnego)",
    "_legal_basis": "Art. 81 ust. 2e-2f ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)",
    "_warnings": ["[MICRO P09] TIER III — składka 1474.20 zł/mies (180% przeciętnego)"],
    "_provenance_tree": {
        "art": "81 ust. 2e-2f",
        "input": "lump_sum_cumulative_revenue",
        "tier_2_limit": _ths.health_lump_tier_2_limit,
        "monthly_amount_pln": amount
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "health_tier_switch_check", false) == true
    object.get(input.jdg_entrepreneur, "tax_form", "") == "LUMP_SUM"
    revenue := object.get(input.jdg_entrepreneur, "lump_sum_cumulative_revenue", 0)
    revenue > _ths.health_lump_tier_2_limit
    tier := "TIER_III"
    rate := _ths.health_lump_tier_3_multiplier
    amount := _ths.health_lump_tier_3_amount
}

# jdg.micro.zdrowotna.a81d.annual_reconciliation — korekta roczna składki
# zdrowotnej ryczałt: porównanie wpłaconych miesięcznych z 9% przychodu rocznego,
# termin rozliczenia 22 maja (art. 81 ust. 2g-2h u.ś.o.z.).
else := {
    "matched": true,
    "rule_id": "jdg.micro.zdrowotna.a81d.annual_reconciliation",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 92811,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "LUMP_SUM",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": _ths.health_scale_rate,
    "zus_health_annual_due_pln": due,
    "zus_health_annual_paid_pln": paid,
    "zus_health_annual_diff_pln": diff,
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Korekta roczna zdrowotnej ryczałt — rozliczenie do 22 maja",
    "_legal_basis": "Art. 81 ust. 2g-2h ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)",
    "_warnings": ["[MICRO P09] Korekta roczna: dopłata/nadpłata vs wpłacone miesięczne — termin 22 maja"],
    "_provenance_tree": {
        "art": "81 ust. 2g-2h",
        "formula": "9% × przychód roczny − Σ wpłat miesięcznych (stawka z data.jdg.thresholds.zus)",
        "annual_due_pln": due,
        "annual_paid_pln": paid,
        "diff_pln": diff
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "health_annual_reconciliation_check", false) == true
    object.get(input.jdg_entrepreneur, "tax_form", "") == "LUMP_SUM"
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_pln", 0)
    paid := object.get(input.jdg_entrepreneur, "health_contributions_paid_pln", 0)
    due := round(_ths.health_scale_rate * annual_revenue * 100) / 100
    diff := round((due - paid) * 100) / 100
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ZASIŁKOWA a19/a29/a32/a33 — zasiłki (ustawa zasiłkowa)                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.zasilkowa.a19.benefit_base — podstawa wymiaru zasiłku: średnia
# podstaw składek z 12 mies. (art. 19 ust. 1), podstawa dzienna = /30.
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a19.benefit_base",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 93801,
    "vat_rate": "",
    "rounding_level": "GROSZE",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "sickness_benefit_base_pln": base,
    "sickness_benefit_daily_pln": daily,
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Podstawa zasiłku = średnia 12 mies. podstaw składek; dzienna = /30",
    "_legal_basis": "Art. 19 ust. 1 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO P09] Podstawa zasiłku z historii 12 mies. — zaokrąglenie do pełnych groszy"],
    "_provenance_tree": {
        "art": "19 ust. 1",
        "formula": "Σ podstaw 12 mies. / 12; dzienna = /30",
        "base_pln": base,
        "daily_pln": daily
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    months := object.get(input.jdg_entrepreneur, "sickness_contribution_bases_12m", [])
    count := count(months)
    count == _ths.sickness_benefit_base_months
    sum := sum(months)
    base := round((sum / count) * 100) / 100
    daily := round((base / _ths.sickness_benefit_daily_divisor) * 100) / 100
    base > 0
}

# jdg.micro.zasilkowa.a29.waiting_period — okres wyczekiwania: 90 dni dla
# dobrowolnego chorobowego (JDG), 30 dni dla obowiązkowego (art. 4 ust. 1 pkt 2).
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a29.waiting_period",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 93802,
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
    "sickness_waiting_period_days": waiting,
    "sickness_waiting_met": true,
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Okres wyczekiwania na zasiłek chorobowy spełniony",
    "_legal_basis": "Art. 4 ust. 1 pkt 2 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO P09] Wyczekiwanie spełnione — prawo do zasiłku chorobowego"],
    "_provenance_tree": {
        "art": "4 ust. 1 pkt 2",
        "voluntary_days": _ths.sickness_waiting_days_voluntary,
        "employee_days": _ths.sickness_waiting_days_employee
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    voluntary := object.get(input.jdg_entrepreneur, "zus_sickness_voluntary", false)
    insured_days := object.get(input.jdg_entrepreneur, "sickness_insurance_days", 0)
    insured_days > 0
    waiting := _ths.sickness_waiting_days_voluntary if voluntary else _ths.sickness_waiting_days_employee
    insured_days >= waiting
}

# jdg.micro.zasilkowa.a32.limit_tracker — limit dni zasiłku chorobowego:
# 182 dni w roku (270 przy gruźlicy) — alert przy 90% limitu i blokada
# informacyjna po przekroczeniu (art. 8 ustawy zasiłkowej).
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a32.limit_tracker",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 93803,
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
    "sickness_days_used": days_used,
    "sickness_days_limit": limit,
    "sickness_days_remaining": remaining,
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Limit dni zasiłku chorobowego — stan wykorzystania",
    "_legal_basis": "Art. 8 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO P09] Zbliżanie się do limitu 182 dni zasiłku chorobowego"] if days_used >= 0.9 * limit else [],
    "_provenance_tree": {
        "art": "8",
        "limit_standard": _ths.sickness_max_days_standard,
        "limit_tb": _ths.sickness_max_days_tb,
        "days_used": days_used
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    days_used := object.get(input.jdg_entrepreneur, "sickness_days_used", 0)
    days_used > 0
    tb := object.get(input.jdg_entrepreneur, "sickness_tuberculosis", false)
    limit := _ths.sickness_max_days_tb if tb else _ths.sickness_max_days_standard
    remaining := limit - days_used
}

# jdg.micro.zasilkowa.a33.benefit_rate — stawka zasiłku: 80% podstawy
# (70% w szpitalu) — art. 33 ustawy zasiłkowej (zasiłek rehabilitacyjny 90%).
else := {
    "matched": true,
    "rule_id": "jdg.micro.zasilkowa.a33.benefit_rate",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 93804,
    "vat_rate": "",
    "rounding_level": "GROSZE",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "sickness_benefit_rate": rate,
    "sickness_benefit_daily_pln": daily_amount,
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Stawka zasiłku chorobowego: 80% (70% w szpitalu)",
    "_legal_basis": "Art. 33 ustawy z dnia 25 czerwca 1999 r. o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa",
    "_warnings": ["[MICRO P09] Zasiłek chorobowy — 80% podstawy dziennej"],
    "_provenance_tree": {
        "art": "33",
        "rate_standard": _ths.sickness_benefit_rate,
        "rate_hospital": _ths.sickness_hospital_rate
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    base_daily := object.get(input.jdg_entrepreneur, "sickness_benefit_daily_pln", 0)
    base_daily > 0
    hospital := object.get(input.jdg_entrepreneur, "sickness_hospitalization", false)
    rate := _ths.sickness_hospital_rate if hospital else _ths.sickness_benefit_rate
    daily_amount := round((base_daily * rate) * 100) / 100
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  SUS a19/a36/a47 — podstawa i terminy (art. 19, 36, 47 SUS)                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.micro.sus.a19.base_standard_preferential — podstawa wymiaru składek JDG:
# standardowa 60% przeciętnego / preferencyjna 30% minimalnego (art. 19 ust. 1
# w zw. z art. 18a-18c SUS).
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a19.base_standard_preferential.r1",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 90801,
    "vat_rate": "",
    "rounding_level": "GROSZE",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": base_type,
    "zus_social_base_amount_pln": base,
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Podstawa wymiaru składek JDG: 60% przeciętnego / 30% minimalnego (preferencyjna)",
    "_legal_basis": "Art. 19 ust. 1 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO P09] Podstawa składek społecznych — wg formy ulgi (start/preferencyjna/standard)"],
    "_provenance_tree": {
        "art": "19 ust. 1 w zw. z art. 18a-18c",
        "standard_60pct": _ths.social_base_standard_60pct,
        "preferential_30pct": _ths.preferential_base_30pct
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "zus_base_check", false) == true
    relief := object.get(input.jdg_entrepreneur, "zus_relief_type", "STANDARD")
    relief == "PREFERENTIAL"
    base_type := "PREFERENTIAL_30PCT_MIN"
    base := _ths.preferential_base_30pct
}

else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a19.base_standard_preferential.r2",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 90802,
    "vat_rate": "",
    "rounding_level": "GROSZE",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": base_type,
    "zus_social_base_amount_pln": base,
    "zus_health_rate": "",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Podstawa wymiaru składek JDG — standardowa 60% przeciętnego",
    "_legal_basis": "Art. 19 ust. 1 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO P09] Podstawa standardowa 60% przeciętnego wynagrodzenia"],
    "_provenance_tree": {
        "art": "19 ust. 1",
        "standard_60pct": _ths.social_base_standard_60pct
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "zus_base_check", false) == true
    relief := object.get(input.jdg_entrepreneur, "zus_relief_type", "STANDARD")
    relief != "PREFERENTIAL"
    base_type := "STANDARD_60PCT_AVG"
    base := _ths.social_base_standard_60pct
}

# jdg.micro.sus.a36.reporting_deadline — termin zgłoszenia do ubezpieczeń:
# 7 dni od powstania tytułu (art. 36 ust. 4 SUS).
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a36.reporting_deadline",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 93601,
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
    "zus_reporting_deadline_days": _ths.reporting_deadline_days,
    "business_status": "ACTIVE",
    "ceidg_registration_required": true,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Zgłoszenie do ubezpieczeń w terminie 7 dni (ZUS ZUA)",
    "_legal_basis": "Art. 36 ust. 4 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO P09] Termin zgłoszenia ZUS ZUA — 7 dni od rozpoczęcia działalności"]
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "zus_reporting_check", false) == true
    days_since_start := object.get(input.jdg_entrepreneur, "days_since_business_start", 999)
    days_since_start <= _ths.reporting_deadline_days
}

# jdg.micro.sus.a47.payment_deadline — termin opłacania składek: 10. dzień
# miesiąca (JDG bez pracowników, art. 47 ust. 1 pkt 2 SUS), 15. z pracownikami.
else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a47.payment_deadline.r1",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 94701,
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
    "zus_payment_deadline_day": deadline,
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Termin płatności składek ZUS: 10. dzień miesiąca (JDG)",
    "_legal_basis": "Art. 47 ust. 1 pkt 2 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO P09] Składki ZUS do 10. dnia miesiąca (JDG bez pracowników)"],
    "_provenance_tree": {
        "art": "47 ust. 1 pkt 2",
        "deadline_social": _ths.payment_deadline_social,
        "deadline_with_employees": _ths.payment_deadline_social_employees
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "zus_payment_check", false) == true
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    not has_employees
    deadline := _ths.payment_deadline_social
}

else := {
    "matched": true,
    "rule_id": "jdg.micro.sus.a47.payment_deadline.r2",
    "package": "jdg.micro.zus_atomic_p09",
    "priority": 94702,
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
    "zus_payment_deadline_day": deadline,
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "valid_from": "2026-01-01",
    "valid_to": null,
    "_routing": "",
    "_routing_reason": "Termin płatności składek ZUS z pracownikami: 15. dzień miesiąca (DRA)",
    "_legal_basis": "Art. 47 ust. 1 pkt 2 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)",
    "_warnings": ["[MICRO P09] Składki ZUS do 15. dnia miesiąca (JDG z pracownikami — DRA)"],
    "_provenance_tree": {
        "art": "47 ust. 1 pkt 2",
        "deadline_with_employees": _ths.payment_deadline_social_employees
    }
} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
    object.get(input.jdg_entrepreneur, "zus_payment_check", false) == true
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    has_employees
    deadline := _ths.payment_deadline_social_employees
}
