# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — P19 Supplement: Financial Hardship Scorer (art. 67a-e)
# v7.0 FIX (LUKA-K67-3): Scoring "ważnego interesu podatnika" dla ulg
# Package: jdg.enterprise.financial_hardship
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.financial_hardship

# Deterministic helper functions keep the public FHS API compatible with strict OPA.
payment_capacity_for(surplus) = 35 {
    surplus > 0
} else = 20 {
    surplus <= 0
    surplus > -1000
} else = 5 {
    surplus <= -1000
}

debt_burden_for(ratio) = 25 {
    ratio <= 0.5
} else = 15 {
    ratio > 0.5
    ratio <= 1.0
} else = 5 {
    ratio > 1.0
}

family_factor_for(dependents) = 20 {
    dependents >= 3
} else = 15 {
    dependents == 2
} else = 10 {
    dependents == 1
} else = 0 {
    dependents == 0
}

health_factor_for(condition) = 10 {
    condition == "SERIOUS"
} else = 5 {
    condition == "MODERATE"
} else = 0 {
    condition == "GOOD"
}

viability_factor_for(viable) = 10 {
    viable
} else = 0 {
    not viable
}

hardship_level_for(total) = "HIGH_NEED" {
    total >= 70
} else = "MODERATE_NEED" {
    total >= 40
    total < 70
} else = "LOW_NEED" {
    total < 40
}

relief_type_for(total) = "UMORZENIE" {
    total >= 70
} else = "ROZŁOŻENIE_NA_RATY" {
    total >= 40
    total < 70
} else = "ODROCZENIE" {
    total < 40
    total >= 20
} else = "ODMOWA" {
    total < 20
}

# FHS-3300: Financial hardship scoring (0-100)
# Art. 67a § 1 OrdPU: ulga wymaga "ważnego interesu podatnika lub interesu publicznego"
fhs_calculate_score(profile) = score {
    monthly_income := object.get(profile, "monthly_income_pln", 0)
    monthly_expenses := object.get(profile, "monthly_expenses_pln", 0)
    tax_debt := object.get(profile, "tax_debt_pln", 0)
    dependents := object.get(profile, "dependents", 0)
    health_condition := object.get(profile, "health_condition", "GOOD")
    business_viable := object.get(profile, "business_viable", true)
    surplus := monthly_income - monthly_expenses
    payment_capacity := payment_capacity_for(surplus)
    debt_ratio := tax_debt / max([monthly_income * 12, 1])
    debt_burden := debt_burden_for(debt_ratio)
    family_factor := family_factor_for(dependents)
    health_factor := health_factor_for(health_condition)
    viability_factor := viability_factor_for(business_viable)
    total := payment_capacity + debt_burden + family_factor + health_factor + viability_factor
    hardship_level := hardship_level_for(total)
    relief_type := relief_type_for(total)
    score := {
        "payment_capacity": payment_capacity,
        "debt_burden": debt_burden,
        "family_factor": family_factor,
        "health_factor": health_factor,
        "viability_factor": viability_factor,
        "total_score": total,
        "level": hardship_level,
        "relief_recommended": total >= 40,
        "relief_type": relief_type,
    }
}

public_employment_factor(employees) = 20 {
    employees >= 5
} else = 0 {
    employees < 5
}

public_boolean_factor(value) = 15 {
    value
} else = 0 {
    not value
}

# FHS-3310: Public interest assessment (art. 67a § 1 — drugie kryterium)
fhs_public_interest_check(profile) = public_check {
    employees := object.get(profile, "employees", 0)
    local_supplier := object.get(profile, "local_supplier", false)
    strategic_sector := object.get(profile, "strategic_sector", false)
    emp_flag := public_employment_factor(employees)
    loc_flag := public_boolean_factor(local_supplier)
    str_flag := public_boolean_factor(strategic_sector)
    pi_score := emp_flag + loc_flag + str_flag
    public_check := {
        "public_interest_score": pi_score,
        "meets_threshold": pi_score >= 30,
        "factors": {
            "employees_gte_5": employees >= 5,
            "local_supplier": local_supplier,
            "strategic_sector": strategic_sector,
        },
    }
}

qualifies_for(h_total, pi_meets) = true {
    h_total >= 40
} else = true {
    pi_meets
} else = false {
    h_total < 40
    not pi_meets
}

routing_for(qualifies, total) = "APPROVE" {
    qualifies
    total >= 70
} else = "REVIEW" {
    qualifies
    total < 70
} else = "DENY" {
    not qualifies
}

relief_recommendation_for(qualifies, relief_type) = relief_type {
    qualifies
} else = "" {
    not qualifies
}

# FHS-3320: Relief decision integrator
fhs_relief_decision(hardship_score, public_interest) = decision {
    h_total := object.get(hardship_score, "total_score", 0)
    h_relief_type := object.get(hardship_score, "relief_type", "ODMOWA")
    pi_meets := object.get(public_interest, "meets_threshold", false)
    qualifies := qualifies_for(h_total, pi_meets)
    routing := routing_for(qualifies, h_total)
    relief_to_recommend := relief_recommendation_for(qualifies, h_relief_type)
    decision := {
        "qualifies": qualifies,
        "hardship_level": object.get(hardship_score, "level", "LOW_NEED"),
        "public_interest_met": pi_meets,
        "recommended_relief": relief_to_recommend,
        "legal_basis": "Art. 67a § 1 Ordynacji Podatkowej",
        "routing": routing,
    }
}

warnings_for_qualified(base, score, decision) = warnings {
    relief := object.get(score, "relief_type", "ODMOWA")
    warnings := array.concat(base, [
        sprintf("   ✅ Kwalifikuje się do ulgi: %s", [relief]),
        sprintf("   Podstawa: %s", [object.get(decision, "legal_basis", "")]),
    ])
}

warnings_for_denied(base) = warnings {
    warnings := array.concat(base, [
        "   ❌ NIE kwalifikuje się do ulgi — brak ważnego interesu podatnika i interesu publicznego",
    ])
}

# FHS-3330: Build FHS warnings
build_fhs_warnings(score, decision) = warnings {
    h_level := object.get(score, "level", "LOW_NEED")
    h_total := object.get(score, "total_score", 0)
    qualifies := object.get(decision, "qualifies", false)
    base := [sprintf("💰 FINANCIAL HARDSHIP SCORER — Score: %d/100 (%s)", [h_total, h_level])]
    warnings := warnings_for_qualified(base, score, decision)
    qualifies
}

build_fhs_warnings(score, decision) = warnings {
    h_level := object.get(score, "level", "LOW_NEED")
    h_total := object.get(score, "total_score", 0)
    qualifies := object.get(decision, "qualifies", false)
    base := [sprintf("💰 FINANCIAL HARDSHIP SCORER — Score: %d/100 (%s)", [h_total, h_level])]
    warnings := warnings_for_denied(base)
    not qualifies
}
