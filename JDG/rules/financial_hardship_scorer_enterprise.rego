# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — P19 Supplement: Financial Hardship Scorer (art. 67a-e)
# v7.0 FIX (LUKA-K67-3): Scoring "ważnego interesu podatnika" dla ulg
# Package: jdg.enterprise.financial_hardship
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.financial_hardship

import data.jdg.helpers

# ─────────────────────────────────────────────────────────────────────────────
# FHS-3300: Financial hardship scoring (0-100)
# Art. 67a § 1 OrdPU: ulga wymaga "ważnego interesu podatnika lub interesu publicznego"
# ─────────────────────────────────────────────────────────────────────────────
fhs_calculate_score(profile) = score {
    monthly_income := object.get(profile, "monthly_income_pln", 0)
    monthly_expenses := object.get(profile, "monthly_expenses_pln", 0)
    tax_debt := object.get(profile, "tax_debt_pln", 0)
    dependents := object.get(profile, "dependents", 0)
    health_condition := object.get(profile, "health_condition", "GOOD")
    business_viable := object.get(profile, "business_viable", true)

    # Składowe scoringu (0-100) — osobne complete rules, NIE inline guards
    surplus := monthly_income - monthly_expenses

    payment_capacity := 35 { surplus > 0 }
    payment_capacity := 20 { surplus <= 0; surplus > -1000 }
    payment_capacity := 5 { surplus <= -1000 }

    debt_ratio := tax_debt / max([monthly_income * 12, 1])
    debt_burden := 25 { debt_ratio <= 0.5 }
    debt_burden := 15 { debt_ratio > 0.5; debt_ratio <= 1.0 }
    debt_burden := 5 { debt_ratio > 1.0 }

    family_factor := 20 { dependents >= 3 }
    family_factor := 15 { dependents == 2 }
    family_factor := 10 { dependents == 1 }
    family_factor := 0 { dependents == 0 }

    health_factor := 10 { health_condition == "SERIOUS" }
    health_factor := 5 { health_condition == "MODERATE" }
    health_factor := 0 { health_condition == "GOOD" }

    viability_factor := 10 { business_viable }
    viability_factor := 0 { not business_viable }

    total := payment_capacity + debt_burden + family_factor + health_factor + viability_factor

    # Składowe poziomu i typu ulgi — osobno
    hardship_level := "HIGH_NEED" { total >= 70 }
    hardship_level := "MODERATE_NEED" { total >= 40; total < 70 }
    hardship_level := "LOW_NEED" { total < 40 }

    relief_type := "UMORZENIE" { total >= 70 }
    relief_type := "ROZŁOŻENIE_NA_RATY" { total >= 40; total < 70 }
    relief_type := "ODROCZENIE" { total < 40; total >= 20 }
    relief_type := "ODMOWA" { total < 20 }

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

# ─────────────────────────────────────────────────────────────────────────────
# FHS-3310: Public interest assessment (art. 67a § 1 — drugie kryterium)
# ─────────────────────────────────────────────────────────────────────────────
fhs_public_interest_check(profile) = public_check {
    employees := object.get(profile, "employees", 0)
    local_supplier := object.get(profile, "local_supplier", false)
    strategic_sector := object.get(profile, "strategic_sector", false)

    # Suma flag przez konkatenację — NIE cumulative redeclaration
    emp_flag := 20 { employees >= 5 }
    emp_flag := 0 { employees < 5 }
    loc_flag := 15 { local_supplier }
    loc_flag := 0 { not local_supplier }
    str_flag := 15 { strategic_sector }
    str_flag := 0 { not strategic_sector }

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

# ─────────────────────────────────────────────────────────────────────────────
# FHS-3320: Relief decision integrator
# ─────────────────────────────────────────────────────────────────────────────
fhs_relief_decision(hardship_score, public_interest) = decision {
    h_total := object.get(hardship_score, "total_score", 0)
    h_relief_type := object.get(hardship_score, "relief_type", "ODMOWA")
    pi_meets := object.get(public_interest, "meets_threshold", false)

    qualifies := h_total >= 40 or pi_meets

    routing := "APPROVE" { qualifies; h_total >= 70 }
    routing := "REVIEW" { qualifies; h_total < 70 }
    routing := "DENY" { not qualifies }

    relief_to_recommend := h_relief_type { qualifies }
    relief_to_recommend := "" { not qualifies }

    decision := {
        "qualifies": qualifies,
        "hardship_level": object.get(hardship_score, "level", "LOW_NEED"),
        "public_interest_met": pi_meets,
        "recommended_relief": relief_to_recommend,
        "legal_basis": "Art. 67a § 1 Ordynacji Podatkowej",
        "routing": routing,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# FHS-3330: Build FHS warnings
# ─────────────────────────────────────────────────────────────────────────────
build_fhs_warnings(score, decision) = warnings {
    h_level := object.get(score, "level", "LOW_NEED")
    h_total := object.get(score, "total_score", 0)
    relief := object.get(score, "relief_type", "ODMOWA")
    qualifies := object.get(decision, "qualifies", false)

    base := [sprintf("💰 FINANCIAL HARDSHIP SCORER — Score: %d/100 (%s)", [h_total, h_level])]

    qual_warn := array.concat(base, [
        sprintf("   ✅ Kwalifikuje się do ulgi: %s", [relief]),
        sprintf("   Podstawa: %s", [object.get(decision, "legal_basis", "")]),
    ]) { qualifies }

    qual_warn := array.concat(base, [
        "   ❌ NIE kwalifikuje się do ulgi — brak ważnego interesu podatnika i interesu publicznego",
    ]) { not qualifies }

    warnings := qual_warn
}
