# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ZUS Micro Rates & Thresholds (INN06 Rate Enricher — P08 Report)
# ═══════════════════════════════════════════════════════════════════════════════
# Package:     jdg.micro.zus_rates
# Purpose:     Dostarcza WSZYSTKIE stawki procentowe, progi i wartości
#              do mikro-warstwy ZUS, eliminując generic conditions.
# Generated:   2026-07-29 — P08 Complete Implementation
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.zus_rates

import future.keywords.if
import future.keywords.in

# ═══════════════════════════════════════════════════════════════════════════════
# SOCIAL INSURANCE RATES (Art. 22 SUS)
# ═══════════════════════════════════════════════════════════════════════════════

zus_social_rates := {
    "emerytalna": {"rate": 0.1952, "name": "Emerytalna", "legal": "Art. 22 ust. 1 SUS"},
    "rentowa": {"rate": 0.08, "name": "Rentowa", "legal": "Art. 22 ust. 2 SUS"},
    "chorobowa": {"rate": 0.0245, "name": "Chorobowa (dobrowolna)", "legal": "Art. 22 ust. 3 SUS"},
    "wypadkowa": {"rate": 0.0167, "name": "Wypadkowa", "legal": "Art. 22 ust. 4 SUS"},
    "FP": {"rate": 0.0245, "name": "Fundusz Pracy", "legal": "Art. 24 SUS"},
    "FGSP": {"rate": 0.001, "name": "FGŚP", "legal": "Art. 24 SUS"},
}

zus_total_social_rate := 0.3164  # 19.52 + 8 + 2.45 + 1.67

# ═══════════════════════════════════════════════════════════════════════════════
# CONTRIBUTION BASE THRESHOLDS (Art. 18, 18a, 18c SUS)
# ═══════════════════════════════════════════════════════════════════════════════

# 2026 values
zus_base_thresholds := {
    "average_salary_pln": 8190.00,
    "minimum_salary_pln": 4666.00,
    "standard_base_60pct": 4914.00,        # 60% przeciętnego
    "preferential_base_30pct": 1399.80,    # 30% minimalnego
    "health_min_base_75pct": 6142.50,       # 75% przeciętnego
}

zus_relief_periods := {
    "START_RELIEF": {"months": 6, "social_base": 0, "legal": "Art. 18a SUS"},
    "PREFERENTIAL": {"months": 24, "social_base_pct": 30, "legal": "Art. 18c SUS"},
    "SMALL_ZUS_PLUS": {"months": 36, "social_base_pct": 30, "revenue_limit": 120000, "legal": "Art. 18c ust. 8 SUS"},
    "STANDARD": {"months": null, "social_base_pct": 60, "legal": "Art. 18 SUS"},
}

# ═══════════════════════════════════════════════════════════════════════════════
# PAYMENT DEADLINES (Art. 36, 47 SUS)
# ═══════════════════════════════════════════════════════════════════════════════

zus_payment_deadlines := {
    "social_without_employees": 10,   # 10. dzień miesiąca
    "social_with_employees": 15,       # 15. dzień miesiąca (DRA)
    "health_only": 20,                  # 20. dzień miesiąca
}

# ═══════════════════════════════════════════════════════════════════════════════
# HEALTH CONTRIBUTION RATES (Art. 81 u.ś.o.z.)
# ═══════════════════════════════════════════════════════════════════════════════

health_contribution_variants := {
    "SCALE": {
        "rate": 0.09,
        "name": "Skala PIT 9%",
        "deductible": false,
        "basis": "Dochód roczny",
        "deadline": "30 kwietnia",
        "legal": "Art. 81 ust. 2 u.ś.o.z."
    },
    "LINEAR": {
        "rate": 0.049,
        "name": "Liniowy 4.9%",
        "deductible": true,
        "deduction_limit_2026": 12900,
        "basis": "Dochód roczny",
        "deadline": "30 kwietnia",
        "legal": "Art. 81 ust. 2c u.ś.o.z."
    },
    "LUMP_SUM": {
        "rate": 0.09,
        "name": "Ryczałt (3 progi)",
        "deductible": false,
        "basis": "Przychód roczny (progi)",
        "deadline": "22 maja",
        "legal": "Art. 81 ust. 2e u.ś.o.z.",
        "tiers": {
            "TIER_I": {"max_revenue": 60000, "base_pct": 60, "monthly_base": 4914.00, "monthly_contribution": 442.26},
            "TIER_II": {"max_revenue": 300000, "base_pct": 100, "monthly_base": 8190.00, "monthly_contribution": 737.10},
            "TIER_III": {"max_revenue": null, "base_pct": 180, "monthly_base": 14742.00, "monthly_contribution": 1326.78},
        }
    },
    "TAX_CARD": {
        "rate": 0.09,
        "name": "Karta podatkowa 9%",
        "deductible": false,
        "basis": "Minimalne wynagrodzenie",
        "monthly_base": 4666.00,
        "monthly_contribution": 419.94,
        "deadline": "31 stycznia",
        "legal": "Art. 81 ust. 2a u.ś.o.z."
    },
}

# ═══════════════════════════════════════════════════════════════════════════════
# SICKNESS BENEFIT RATES (Ustawa zasiłkowa)
# ═══════════════════════════════════════════════════════════════════════════════

sickness_benefit_rates := {
    "CHOROBOWY": {
        "rate": 0.80,
        "hospital_rate": 0.70,
        "max_days_standard": 182,
        "max_days_extended": 270,
        "waiting_period_days": 90,
        "daily_formula": "podstawa × 80% / 30",
        "legal": "Art. 19 ustawy zasiłkowej"
    },
    "MACIERZYNSKI": {
        "rate": 1.00,
        "min_weeks": 20,
        "max_weeks": 37,
        "requires_sickness_insurance_90d": true,
        "can_continue_business": true,
        "weekly_formula": "podstawa × 100% / 4.33",
        "legal": "Art. 29 ustawy zasiłkowej"
    },
    "OPIEKUNCZY_DZIECKO": {
        "rate": 0.80,
        "max_days": 60,
        "child_age_limit": 14,
        "daily_formula": "podstawa × 80% / 30",
        "legal": "Art. 32 ustawy zasiłkowej"
    },
    "OPIEKUNCZY_RODZINA": {
        "rate": 0.80,
        "max_days": 14,
        "daily_formula": "podstawa × 80% / 30",
        "legal": "Art. 32-33 ustawy zasiłkowej"
    },
}

# ═══════════════════════════════════════════════════════════════════════════════
# CRIME vs MISDEMEANOR THRESHOLD (KKS reference)
# ═══════════════════════════════════════════════════════════════════════════════

kks_thresholds := {
    "crime_threshold_200x_min_wage": 933200,  # 200 × 4666 PLN
    "daily_rate_min": 155.53,                  # 4666 / 30
    "daily_rate_max": 1866400.00,              # 400 × 4666
    "mandatory_prison_threshold": 5000000,     # Art. 62 §3 KKS
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
        }
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
