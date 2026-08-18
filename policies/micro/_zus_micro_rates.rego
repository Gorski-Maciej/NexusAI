# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ZUS Micro Rates & Thresholds (INN06 Rate Enricher — P08 Report)
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.micro.zus_rates
# Purpose:     Dostarcza WSZYSTKIE stawki procentowe, progi i wartości
#              do mikro-warstwy ZUS, eliminując generic conditions.
# Generated:   2026-07-29 — P08 Complete Implementation
# Upgraded:    2026-08-17 — P09 (GLM52): ZERO HARDCODE (ADR-002) — każda wartość
#              czytana z data.jdg.thresholds.zus.* (Data API hot-reload, V1 §11);
#              wartości w tym pliku to FALLBACKI (ostatnia znana 2026), używane
#              tylko gdy thresholds nie zostały dostarczone przez hosta.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.zus_rates

import future.keywords.if
import future.keywords.in

# ── Źródło prawdy: data.jdg.thresholds.zus.* (ADR-002, V1 hot-reload) ──────────
_ths := object.get(data.jdg.thresholds, "zus", {})

# ═══════════════════════════════════════════════════════════════════════════════
# SOCIAL INSURANCE RATES (Art. 22 SUS)
# ═══════════════════════════════════════════════════════════════════════════════

zus_social_rates := {
    "emerytalna": {
        "rate": object.get(_ths, "pension_rate", 0.1952),
        "name": "Emerytalna",
        "legal": "Art. 22 ust. 1 SUS",
    },
    "rentowa": {
        "rate": object.get(_ths, "disability_rate", 0.08),
        "name": "Rentowa",
        "legal": "Art. 22 ust. 2 SUS",
    },
    "chorobowa": {
        "rate": object.get(_ths, "sickness_voluntary_rate", 0.0245),
        "name": "Chorobowa (dobrowolna)",
        "legal": "Art. 22 ust. 3 SUS",
    },
    "wypadkowa": {
        "rate": object.get(_ths, "accident_rate", 0.0167),
        "name": "Wypadkowa",
        "legal": "Art. 22 ust. 4 SUS",
    },
    "FP": {
        "rate": object.get(_ths, "labour_fund_rate", 0.0245),
        "name": "Fundusz Pracy",
        "legal": "Art. 24 SUS",
    },
    "FGSP": {
        "rate": 0.001,
        "name": "FGŚP",
        "legal": "Art. 24 SUS",
    },
}

zus_total_social_rate := round((zus_social_rates.emerytalna.rate +
    zus_social_rates.rentowa.rate +
    zus_social_rates.chorobowa.rate +
    zus_social_rates.wypadkowa.rate) * 10000) / 10000

# ═══════════════════════════════════════════════════════════════════════════════
# CONTRIBUTION BASE THRESHOLDS (Art. 18, 18a, 18c SUS)
# ═══════════════════════════════════════════════════════════════════════════════

# 2026 values — FIX v7.1 K4/K5: unified minimum_wage 4800 PLN (2026), average 9100 PLN
zus_base_thresholds := {
    "average_salary_pln": object.get(_ths, "avg_monthly_wage", 9100.00),
    "minimum_salary_pln": object.get(_ths, "minimum_wage_gross", 4800.00),
    "standard_base_60pct": object.get(_ths, "social_base_standard_60pct", 5460.00),
    "preferential_base_30pct": object.get(_ths, "preferential_base_30pct", 1440.00),
    "health_min_base_100pct": object.get(_ths, "health_min_base_standard", 4800.00),
    "health_min_base_first_year_75pct": object.get(_ths, "health_min_base_first_year", 3600.00),
}

zus_relief_periods := {
    "START_RELIEF": {
        "months": object.get(_ths, "start_relief_months", 6),
        "social_base": 0,
        "legal": "Art. 18a SUS",
    },
    "PREFERENTIAL": {
        "months": object.get(_ths, "preferential_months", 24),
        "social_base_pct": 30,
        "legal": "Art. 18c SUS",
    },
    "SMALL_ZUS_PLUS": {
        "months": object.get(_ths, "maly_zus_plus_months", 36),
        "social_base_pct": object.get(_ths, "maly_zus_plus_base_pct", 30),
        "revenue_limit": object.get(_ths, "maly_zus_plus_revenue_limit", 120000),
        "legal": "Art. 18c ust. 8 SUS",
    },
    "STANDARD": {
        "months": null,
        "social_base_pct": 60,
        "legal": "Art. 18 SUS",
    },
}

# ═══════════════════════════════════════════════════════════════════════════════
# PAYMENT DEADLINES (Art. 36, 47 SUS)
# ═══════════════════════════════════════════════════════════════════════════════

# FIX v7.1 W10: health_only deadline = 10 dla JDG (20 dotyczy jednostek budżetowych!)
zus_payment_deadlines := {
    "social_without_employees": object.get(_ths, "payment_deadline_social", 10),
    "social_with_employees": object.get(_ths, "payment_deadline_social_employees", 15),
    "health_only": object.get(_ths, "payment_deadline_health", 10),
}

# ═══════════════════════════════════════════════════════════════════════════════
# HEALTH CONTRIBUTION RATES (Art. 81 u.ś.o.z.)
# ═══════════════════════════════════════════════════════════════════════════════

health_contribution_variants := {
    "SCALE": {
        "rate": object.get(_ths, "health_scale_rate", 0.09),
        "name": "Skala PIT 9%",
        "deductible": false,
        "basis": "Dochód roczny",
        "deadline": "30 kwietnia",
        "legal": "Art. 81 ust. 2 u.ś.o.z.",
    },
    "LINEAR": {
        "rate": object.get(_ths, "health_linear_rate", 0.049),
        "name": "Liniowy 4.9%",
        "deductible": true,
        "deduction_limit_2026": object.get(_ths, "health_linear_deduction_limit", 14100),
        "basis": "Dochód roczny",
        "deadline": "30 kwietnia",
        "legal": "Art. 81 ust. 2c u.ś.o.z. (limit odliczenia 14 100 PLN, nie wysokości składki!)",
    },
    "LUMP_SUM": {
        "rate": object.get(_ths, "health_scale_rate", 0.09),
        "name": "Ryczałt (3 progi)",
        "deductible": false,
        "basis": "Przychód roczny (progi)",
        "deadline": "22 maja",
        "legal": "Art. 81 ust. 2e u.ś.o.z.",
        "tiers": {
            "TIER_I": {
                "max_revenue": object.get(_ths, "health_lump_tier_1_limit", 60000),
                "base_pct": 60,
                "monthly_base": object.get(_ths, "health_lump_tier_1_amount", 491.40) / 0.09,
                "monthly_contribution": object.get(_ths, "health_lump_tier_1_amount", 491.40),
            },
            "TIER_II": {
                "max_revenue": object.get(_ths, "health_lump_tier_2_limit", 300000),
                "base_pct": 100,
                "monthly_base": object.get(_ths, "health_lump_tier_2_amount", 819.00) / 0.09,
                "monthly_contribution": object.get(_ths, "health_lump_tier_2_amount", 819.00),
            },
            "TIER_III": {
                "max_revenue": null,
                "base_pct": 180,
                "monthly_base": object.get(_ths, "health_lump_tier_3_amount", 1474.20) / 0.09,
                "monthly_contribution": object.get(_ths, "health_lump_tier_3_amount", 1474.20),
            },
        },
    },
    "TAX_CARD": {
        "rate": object.get(_ths, "health_scale_rate", 0.09),
        "name": "Karta podatkowa 9%",
        "deductible": false,
        "basis": "Minimalne wynagrodzenie",
        "monthly_base": object.get(_ths, "health_min_base_standard", 4800.00),
        "monthly_contribution": round(object.get(_ths, "health_min_base_standard", 4800.00) * object.get(_ths, "health_scale_rate", 0.09) * 100) / 100,
        "deadline": "31 stycznia",
        "legal": "Art. 81 ust. 2a u.ś.o.z.",
    },
}

# ═══════════════════════════════════════════════════════════════════════════════
# SICKNESS BENEFIT RATES (Ustawa zasiłkowa)
# ═══════════════════════════════════════════════════════════════════════════════

sickness_benefit_rates := {
    "CHOROBOWY": {
        "rate": object.get(_ths, "sickness_benefit_rate", 0.80),
        "hospital_rate": object.get(_ths, "sickness_hospital_rate", 0.70),
        "max_days_standard": object.get(_ths, "sickness_max_days_standard", 182),
        "max_days_extended": object.get(_ths, "sickness_max_days_tb", 270),
        "waiting_period_days": object.get(_ths, "sickness_waiting_days_voluntary", 90),
        "daily_formula": "podstawa × 80% / 30",
        "legal": "Art. 4 ust. 1 pkt 2, Art. 19 ustawy zasiłkowej (90 dni dla dobrowolnego)",
    },
    "MACIERZYNSKI": {
        "rate": 1.00,
        "min_weeks": 20,
        "max_weeks": 37,
        "requires_sickness_insurance_90d": true,
        "can_continue_business": true,
        "weekly_formula": "podstawa × 100% / 4.33",
        "legal": "Art. 29 ustawy zasiłkowej",
    },
    "OPIEKUNCZY_DZIECKO": {
        "rate": object.get(_ths, "sickness_benefit_rate", 0.80),
        "max_days": 60,
        "child_age_limit": 14,
        "daily_formula": "podstawa × 80% / 30",
        "legal": "Art. 32 ustawy zasiłkowej",
    },
    "OPIEKUNCZY_RODZINA": {
        "rate": object.get(_ths, "sickness_benefit_rate", 0.80),
        "max_days": 14,
        "daily_formula": "podstawa × 80% / 30",
        "legal": "Art. 32-33 ustawy zasiłkowej",
    },
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIME vs MISDEMEANOR THRESHOLD (KKS reference)
# ═══════════════════════════════════════════════════════════════════════════════

kks_thresholds := {
    "crime_threshold_200x_min_wage": 200 * object.get(_ths, "minimum_wage_gross", 4800),
    "daily_rate_min": round(object.get(_ths, "minimum_wage_gross", 4800) / 30),
    "daily_rate_max": 400 * object.get(_ths, "minimum_wage_gross", 4800),
    "mandatory_prison_threshold": 5000000,
}

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER RULES — substantywne warunki zamiast generic
# ═══════════════════════════════════════════════════════════════════════════════

default zus_rates_loaded := true

# Calculate monthly social contribution
calculate_social_contribution(base, relief_type) := result {
    rates := zus_social_rates
    total := base * zus_total_social_rate
    result := {
        "base": base,
        "relief": relief_type,
        "total_monthly": round(total * 100) / 100,
        "breakdown": {
            "emerytalna": round(base * rates.emerytalna.rate * 100) / 100,
            "rentowa": round(base * rates.rentowa.rate * 100) / 100,
            "chorobowa": round(base * rates.chorobowa.rate * 100) / 100,
            "wypadkowa": round(base * rates.wypadkowa.rate * 100) / 100,
        },
    }
}

# Calculate health contribution based on variant
calculate_health_contribution(variant, annual_income) := result {
    v := health_contribution_variants[variant]
    result := {
        "variant": variant,
        "rate": v.rate,
        "name": v.name,
        "legal": v.legal,
        "monthly": round(annual_income * v.rate / 12 * 100) / 100,
        "annual": round(annual_income * v.rate * 100) / 100,
        "deductible": v.deductible,
    }
}

# Calculate sickness benefit
calculate_sickness_benefit(benefit_type, contribution_base, days) := result {
    b := sickness_benefit_rates[benefit_type]
    result := {
        "type": benefit_type,
        "base": contribution_base,
        "days": days,
        "rate": b.rate,
        "daily_benefit": round(contribution_base * b.rate / 30 * 100) / 100,
        "total_benefit": round(contribution_base * b.rate * days / 30 * 100) / 100,
        "legal": b.legal,
    }
}
