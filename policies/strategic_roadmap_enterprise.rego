# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — Innovation 9.5: Strategic Tax Roadmap Generator
# v7.0 — BP-5: 5-year multi-regime tax optimization strategy
# Package: jdg.enterprise.strategic_roadmap
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.strategic_roadmap

import data.jdg.helpers

# ─────────────────────────────────────────────────────────────────────────────
# STR-2800: Business form comparator — skala vs liniowy vs ryczałt vs CIT
# ─────────────────────────────────────────────────────────────────────────────
str_compare_forms(profile) = comparison {
    annual_income := object.get(profile, "annual_income_pln", 0)
    annual_costs := object.get(profile, "annual_costs_pln", 0)
    zus_base := object.get(profile, "zus_monthly_pln", 1800)

    income := annual_income
    costs := annual_costs

    # Skala podatkowa (12% / 32%)
    scale_tax_12 := min([income - costs, 120000]) * 0.12
    scale_tax_32 := max([income - costs - 120000, 0]) * 0.32
    scale_total := scale_tax_12 + scale_tax_32
    scale_health := (income - costs) * 0.09

    # Podatek liniowy 19%
    linear_tax := max([income - costs, 0]) * 0.19
    linear_health := max([income - costs, 0]) * 0.049

    # Ryczałt (zakres stawek 2%-17%, przyjmujemy średnią orientacyjną)
    lump_sum_rate := 0.055
    lump_sum_tax := income * lump_sum_rate
    lump_sum_health := income * 0.09

    # IP Box 5%
    ip_eligible := object.get(profile, "ip_box_eligible", false)
    ip_tax := (income - costs) * 0.05 { ip_eligible } else := 0

    comparison := {
        "annual_income": income,
        "annual_costs": costs,
        "options": {
            "scale": {
                "tax_pln": scale_total,
                "health_pln": scale_health,
                "total_burden": scale_total + scale_health,
                "effective_rate": (scale_total + scale_health) / max([income, 1]),
            },
            "linear": {
                "tax_pln": linear_tax,
                "health_pln": linear_health,
                "total_burden": linear_tax + linear_health,
                "effective_rate": (linear_tax + linear_health) / max([income, 1]),
            },
            "lump_sum": {
                "tax_pln": lump_sum_tax,
                "health_pln": lump_sum_health,
                "total_burden": lump_sum_tax + lump_sum_health,
                "effective_rate": (lump_sum_tax + lump_sum_health) / max([income, 1]),
            },
            "ip_box": {
                "tax_pln": ip_tax,
                "health_pln": (income - costs) * 0.049,
                "total_burden": ip_tax + (income - costs) * 0.049,
                "effective_rate": (ip_tax + (income - costs) * 0.049) / max([income, 1]),
                "eligible": ip_eligible,
            },
        },
        "recommended": "",
    }

    # Rekomendacja
    best := min([
        scale_total + scale_health,
        linear_tax + linear_health,
        lump_sum_tax + lump_sum_health,
    ])
}

# ─────────────────────────────────────────────────────────────────────────────
# STR-2810: 5-Year projection model
# ─────────────────────────────────────────────────────────────────────────────
str_five_year_projection(profile, growth_rate) = projection {
    base_income := object.get(profile, "annual_income_pln", 0)
    base_costs := object.get(profile, "annual_costs_pln", 0)

    y1 := str_compare_forms(profile)
    y2_income := base_income * (1 + growth_rate)
    y2_costs := base_costs * (1 + growth_rate)

    projection := {
        "year_1": y1,
        "growth_assumption": sprintf("%.1f%% rocznie", [growth_rate * 100]),
        "note": "Projekcja uproszczona — nie uwzględnia zmian stawek podatkowych ani progów",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# STR-2820: Investment strategy optimizer
# ─────────────────────────────────────────────────────────────────────────────
str_investment_optimizer(profile) = strategy {
    annual_income := object.get(profile, "annual_income_pln", 0)

    # Leasing vs zakup
    leasing_limit := 150000
    leasing_recommended := annual_income > 50000

    # Jednorazowa amortyzacja (do 100k PLN dla małych podatników)
    one_time_depreciation_limit := 100000
    is_small_taxpayer := annual_income < 2000000

    # IP Box eligibility
    ip_eligible := object.get(profile, "ip_box_eligible", false)

    strategy := {
        "leasing": {
            "recommended": leasing_recommended,
            "limit_pln": leasing_limit,
            "benefit": "Wpisanie rat leasingowych w koszty (100%)",
        },
        "one_time_depreciation": {
            "available": is_small_taxpayer,
            "limit_pln": one_time_depreciation_limit,
            "benefit": "Jednorazowa amortyzacja do 100 000 PLN rocznie",
        },
        "ip_box": {
            "available": ip_eligible,
            "rate": "5% CIT",
            "benefit": "Preferencyjna stawka dla dochodów z kwalifikowanych IP",
        },
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# STR-2830: Succession/scenario planner — JDG → Sp. z o.o.
# ─────────────────────────────────────────────────────────────────────────────
str_succession_planner(profile) = plan {
    annual_income := object.get(profile, "annual_income_pln", 0)
    jdg_years := object.get(profile, "jdg_years", 0)

    # Próg opłacalności transformacji JDG → Sp. z o.o.
    transformation_threshold := 300000

    # PCC risk
    pcc_applies := annual_income > 1000
    pcc_rate := 0.005

    # GAAR art. 119a risk
    gaar_risk := "HIGH" { pcc_applies; annual_income > transformation_threshold * 2 }
    gaar_risk := "MEDIUM" { annual_income > transformation_threshold }
    gaar_risk := "LOW" { true }

    plan := {
        "jdg_years": jdg_years,
        "transformation_recommended": annual_income > transformation_threshold,
        "transformation_threshold": transformation_threshold,
        "pcc": {
            "applies": pcc_applies,
            "rate": sprintf("%.1f%%", [pcc_rate * 100]),
            "note": "PCC od aportu przedsiębiorstwa — art. 1 ust. 1 pkt 1 lit. a ustawy o PCC",
        },
        "gaar_risk": gaar_risk,
        "kks_risk": "Monitoruj KKS art. 16 (czynny żal) dla bezpieczeństwa transformacji",
        "next_steps": [
            "1. Wycena przedsiębiorstwa JDG",
            "2. Sporządzenie planu transformacji (aport / sprzedaż)",
            "3. Analiza PCC + VAT (aport zwolniony z VAT?)",
            "4. Zgłoszenie do KRS + CEIDG (wyrejestrowanie JDG)",
            "5. Konsultacja GAAR shield (art. 119a OrdPU)",
        ],
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# STR-2840: Tax risk scorer per strategy
# ─────────────────────────────────────────────────────────────────────────────
str_tax_risk_scorer(form_type, profile) = risk {
    annual_income := object.get(profile, "annual_income_pln", 0)

    # Baza ryzyka per forma opodatkowania
    base_risk := {
        "scale": 10,
        "linear": 15,
        "lump_sum": 30,
        "ip_box": 40,
    }[form_type]

    # Bonus za wysokie dochody
    income_bonus := 25 { annual_income > 2000000 }
    income_bonus := 10 { annual_income > 500000 }
    income_bonus := 0 { true }

    # Bonus za skomplikowaną strukturę
    has_employees := object.get(profile, "has_employees", false)
    employee_bonus := 5 { has_employees }
    employee_bonus := 0 { not has_employees }

    total_risk_score := min([base_risk + income_bonus + employee_bonus, 100])

    risk_level := "CRITICAL" { total_risk_score >= 80 }
    risk_level := "HIGH" { total_risk_score >= 60; total_risk_score < 80 }
    risk_level := "MEDIUM" { total_risk_score >= 30; total_risk_score < 60 }
    risk_level := "LOW" { total_risk_score < 30 }

    risk := {
        "form_type": form_type,
        "base_risk": base_risk,
        "income_risk": income_bonus,
        "complexity_risk": employee_bonus,
        "total_risk": total_risk_score,
        "level": risk_level,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# STR-2850: Build roadmap warnings
# ─────────────────────────────────────────────────────────────────────────────
build_str_warnings(comparison, risk, succession) = warnings {
    recommended_form := object.get(comparison, "recommended", "scale")
    transformation := object.get(succession, "transformation_recommended", false)
    gaar := object.get(succession, "gaar_risk", "LOW")

    base := ["🗺️ STRATEGIC TAX ROADMAP — 5-Year Plan"]

    form_warn := array.concat(base, [
        sprintf("   📊 Rekomendowana forma: %s (ryzyko: %s)",
            [recommended_form, object.get(risk, "level", "LOW")]),
    ])

    trans_warn := array.concat(form_warn, [
        "   🏢 REKOMENDOWANA TRANSFORMACJA JDG → Sp. z o.o.",
        sprintf("   ⚠️ Ryzyko GAAR: %s — rozważ GAAR Shield Detector", [gaar]),
    ]) { transformation }

    trans_warn := form_warn { not transformation }

    warnings := trans_warn
}
