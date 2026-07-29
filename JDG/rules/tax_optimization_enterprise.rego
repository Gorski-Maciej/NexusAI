# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE TAX OPTIMIZATION ENGINE (Strategic Initiative S1)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Tax Optimization — Strategic Advisor Engine
# description: |
#   ENTERPRISE v5.0 — Inteligentny silnik optymalizacji podatkowej JDG.
#   Porównuje formy opodatkowania (skala, liniowy, ryczałt, karta) i rekomenduje
#   optymalną strategię na podstawie rzeczywistych danych finansowych JDG.
#   Analizuje: zmianę formy, próg dochodowy, wpływ składki zdrowotnej,
#   optymalizację kosztów, strategie łączenia ulg, timing przychodów/kosztów.
#   Wypełnia lukę: doradztwo strategiczne (częściowa automatyzacja).
# architecture: Enterprise Strategic Engine, First-Match-Wins else-chain
# legal_basis: PIT Art. 27, 30c, 30ca; Ustawa o ryczałcie; Ustawa o świadczeniach zdrowotnych
# package: jdg.tax_optimization
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.tax_optimization

import data.jdg.helpers
import data.jdg.allowances

default decide := {
    "matched": false, "rule_id": "jdg.tax_opt.no_match",
    "package": "jdg.tax_optimization", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# S1-100: COMPREHENSIVE TAX FORM COMPARISON — Porównanie wszystkich form
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.tax_opt.form_comparison_annual",
    "package": "jdg.tax_optimization",
    "priority": 100,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": current_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "tax_opt_annual_income": annual_income,
    "tax_opt_annual_costs": annual_costs,
    "tax_opt_scale_tax": scale_tax,
    "tax_opt_linear_tax": linear_tax,
    "tax_opt_lump_sum_tax": lump_tax,
    "tax_opt_optimal_form": optimal_form,
    "tax_opt_savings_vs_current": savings,
    "tax_opt_health_contrib_impact": health_impact,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 27, 30c, 30ca PIT; Ustawa o ryczałcie; Art. 79-81 ustawy zdrowotnej",
    "_warnings": [
        sprintf("💡 OPTYMALIZACJA: %s\n📊 Obecna forma: %s, Roczne obciążenie: skala=%.0f PLN, liniowy=%.0f PLN, ryczałt=%.0f PLN\n💰 Oszczędność vs obecna forma: %.0f PLN/rok\n%s", [optimal_form, current_form, scale_total, linear_total, lump_total, savings, health_impact])
    ],
    "_optimization_details": {
        "scale": {"rate": "12%/32%", "tax_free": 30000, "health_rate": 0.09},
        "linear": {"rate": "19%", "health_rate": 0.049, "deductible_cap": data.thresholds.zus.health_linear_deduction_limit},
        "lump_sum": {"rate": "3-17%", "health_rate": "3 tiers", "no_cost_deduction": true}
    }
} {
    input.tax_optimization_requested == true
    annual_income := object.get(input.jdg_entrepreneur, "annual_income_projected", 120000)
    annual_costs := object.get(input.jdg_entrepreneur, "annual_costs_projected", 30000)
    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    business_type := object.get(input.jdg_entrepreneur, "business_type", "SERVICES")
    uses_ip_box := object.get(input.jdg_entrepreneur, "uses_ip_box", false)
    is_eligible_lump := business_type != "TRADING_CAR_PARTS"  # Wyłączenia z ryczałtu

    # Obliczenia dla SKALI PODATKOWEJ (12%/32%)
    tax_free := object.get(object.get(data.thresholds, "pit", {}), "tax_free_amount", 30000)
    scale_threshold := object.get(object.get(data.thresholds, "pit", {}), "scale_threshold", 120000)
    health_rate_scale := 0.09
    scale_income := annual_income - annual_costs  # Dochód
    scale_tax_low := min([scale_income - tax_free, scale_threshold - tax_free]) * 0.12
    scale_tax_low := max([scale_tax_low, 0])
    scale_tax_high := max([scale_income - scale_threshold, 0]) * 0.32
    scale_tax := scale_tax_low + scale_tax_high
    scale_health := floor(scale_income * health_rate_scale * 100) / 100
    scale_total := scale_tax + scale_health

    # Obliczenia dla PODATKU LINIOWEGO (19%)
    linear_rate := 0.19
    linear_income := annual_income - annual_costs
    linear_tax := linear_income * linear_rate
    linear_health_floor := floor(linear_income * 0.049 * 100) / 100
    linear_health := min([linear_health_floor, data.jdg.thresholds.limits.health_linear_deduction_limit])
    linear_total := linear_tax + linear_health

    # Obliczenia dla RYCZAŁTU
    lump_rate := object.get(object.get(data.thresholds, "lump", {}), "default_rate", 0.12)
    lump_rates := {"SERVICES": 0.15, "TRADING": 0.03, "CONSTRUCTION": 0.055, "IT": 0.12, "CONSULTING": 0.17}
    lump_rate := object.get(lump_rates, business_type, 0.12)
    lump_tax := annual_income * lump_rate
    lump_health_rates := {"SERVICES": 0.09, "IT": 0.09, "TRADING": 0.09}
    lump_health_pct := object.get(lump_health_rates, business_type, 0.09)
    avg_wage := object.get(object.get(data.thresholds, "bounds", {}), "average_wage", 8000)
    lump_health := floor(avg_wage * lump_health_pct * 100) / 100 * 12
    lump_total := lump_tax + lump_health

    # Wybór optymalnej formy
    totals := {"PIT_SCALE": scale_total, "LINEAR": linear_tax + linear_health, "LUMP_SUM": lump_total}
    optimal_form := "PIT_SCALE" { scale_total <= linear_tax + linear_health; scale_total <= lump_total }
    optimal_form := "LINEAR" { linear_tax + linear_health < scale_total; linear_tax + linear_health <= lump_total }
    optimal_form := "LUMP_SUM" { lump_total < scale_total; lump_total < linear_tax + linear_health; is_eligible_lump }
    optimal_form := "LINEAR" { not is_eligible_lump; lump_total < scale_total }  # Fallback gdy ryczałt niedozwolony

    current_total := object.get(totals, current_form, scale_total)
    optimal_total := object.get(totals, optimal_form, scale_total)
    savings := current_total - optimal_total

    health_impact := sprintf("Składka zdrowotna: skala=%.2f PLN, liniowy=%.2f PLN (max %.0f), ryczałt=%.2f PLN", [scale_health, linear_health, data.thresholds.zus.health_linear_deduction_limit, lump_health])
}

# ═══════════════════════════════════════════════════════════════════════════════
# S1-110: ALLOWANCE STACKING OPTIMIZATION — Strategiczne łączenie ulg
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.tax_opt.allowance_stacking_strategy",
    "package": "jdg.tax_optimization",
    "priority": 110,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "tax_opt_available_reliefs": available_reliefs,
    "tax_opt_best_combination": best_combo,
    "tax_opt_estimated_relief_pln": estimated_relief,
    "tax_opt_stacking_warnings": stacking_warnings,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": routing_decision,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 26-30ca PIT; Art. 18d-18dc CIT (przez analogię)",
    "_warnings": build_stacking_warnings(best_combo, estimated_relief)
} {
    input.tax_optimization_allowances == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    annual_income := object.get(input.jdg_entrepreneur, "annual_income_projected", 120000)
    hiring_rd_staff := object.get(input.jdg_entrepreneur, "hires_rd_staff", false)
    has_ip := object.get(input.jdg_entrepreneur, "has_qualifying_ip", false)
    has_rd_costs := object.get(input.jdg_entrepreneur, "has_rd_costs", false)
    has_expansion_costs := object.get(input.jdg_entrepreneur, "has_foreign_expansion_costs", false)
    has_prototype_costs := object.get(input.jdg_entrepreneur, "has_prototype_costs", false)
    has_robotization := object.get(input.jdg_entrepreneur, "has_robotization_costs", false)
    rd_costs := object.get(input.jdg_entrepreneur, "rd_qualified_costs", 0)
    expansion_costs := object.get(input.jdg_entrepreneur, "expansion_costs", 0)
    ip_income := object.get(input.jdg_entrepreneur, "ip_box_qualifying_income", 0)

    available_reliefs := []
    available_reliefs := array.concat(available_reliefs, ["IP_BOX_5PCT"]) { has_ip; ip_income > 0; pit_form == "PIT_SCALE" }
    available_reliefs := array.concat(available_reliefs, ["IP_BOX_5PCT"]) { has_ip; ip_income > 0; pit_form == "LINEAR" }
    available_reliefs := array.concat(available_reliefs, ["RD_RELIEF_100PCT"]) { has_rd_costs; rd_costs > 0 }
    available_reliefs := array.concat(available_reliefs, ["RD_RELIEF_200PCT"]) { has_rd_costs; rd_costs > 0; hiring_rd_staff }
    available_reliefs := array.concat(available_reliefs, ["EXPANSION_RELIEF"]) { has_expansion_costs; expansion_costs > 0 }
    available_reliefs := array.concat(available_reliefs, ["PROTOTYPE_RELIEF"]) { has_prototype_costs }
    available_reliefs := array.concat(available_reliefs, ["ROBOTIZATION_RELIEF"]) { has_robotization }
    available_reliefs := array.concat(available_reliefs, ["INNOVATIVE_EMPLOYEE"]) { has_rd_costs; hiring_rd_staff; pit_form == "PIT_SCALE" }

    # IP Box + B+R NIE mogą być łączone na tym samym dochodzie!
    has_ip_rd_conflict := has_ip and has_rd_costs
    best_combo := available_reliefs
    estimated_relief := rd_costs * 0.12 { pit_form == "PIT_SCALE" }
    estimated_relief := rd_costs * 0.19 { pit_form == "LINEAR" }

    stacking_warnings := ""
    stacking_warnings := "⚠️ IP Box (5%) i B+R NIE mogą być stosowane na tym samym dochodzie! Wybierz korzystniejszą ulgę. IP Box zastępuje B+R dla dochodu z kwalifikowanego IP." { has_ip_rd_conflict }

    routing_decision := ""
    routing_decision := "TRIAGE_QUEUE" { has_ip_rd_conflict }
    routing_reason := ""
    routing_reason := "Konflikt IP Box vs B+R — wymaga decyzji księgowego" { has_ip_rd_conflict }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S1-130: IP BOX DEEP INTEGRATION — Analiza IP Box + B+R + CIT Estonski
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.tax_opt.ip_box_deep_analysis",
    "package": "jdg.tax_optimization",
    "priority": 130,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "tax_opt_ip_box_eligible": ip_eligible,
    "tax_opt_ip_box_effective_rate": ip_effective_rate,
    "tax_opt_ip_box_vs_linear_breakeven": ip_breakeven,
    "tax_opt_ip_box_requires_separate_evidence": true,
    "tax_opt_ip_box_nexus_index_required": true,
    "tax_opt_allowances_active": allowances_active,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": ip_routing,
    "_routing_reason": ip_routing_reason,
    "_legal_basis": "Art. 30ca-30cb PIT; Art. 24d ust. 4 PIT (wskaźnik Nexus)",
    "_warnings": [
        sprintf("🔬 IP BOX — ANALIZA GŁĘBOKA", []),
        sprintf("   Kwalifikowane IP: %s", ["TAK" { ip_eligible } else "NIE"]),
        sprintf("   Efektywna stawka: %.1f%%", [ip_effective_rate * 100]),
        sprintf("   Próg opłacalności vs liniowy 19%%: %.0f PLN dochodu z IP", [ip_breakeven]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "📋 WYMAGANIA IP BOX:",
        "   • Wyodrębniona ewidencja księgowa (Art. 30cb PIT)",
        "   • Obliczenie wskaźnika Nexus [(a+b)*1.3/(a+b+c+d)]",
        "   • Oddzielne konto bankowe dla IP (zalecane)",
        "   • Dokumentacja kosztów kwalifikowanych B+R",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "💡 STRATEGIA ŁĄCZENIA:",
        "   • IP Box (5%%) od dochodu z IP + B+R (100-200%% KUP) od POZOSTAŁEGO dochodu",
        "   • Ulgi NIE mogą być stosowane na tym samym dochodzie!",
        "   • Optymalnie: rozdziel dochód na IP i non-IP, zastosuj IP Box + B+R osobno"
    ]
} {
    input.tax_optimization_ip_box_deep == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    has_ip := object.get(input.jdg_entrepreneur, "has_qualifying_ip", false)
    ip_income := object.get(input.jdg_entrepreneur, "ip_box_qualifying_income", 0)
    ip_costs := object.get(input.jdg_entrepreneur, "ip_box_costs", 0)
    total_income := object.get(input.jdg_entrepreneur, "annual_income_projected", 120000)
    non_ip_income := total_income - ip_income
    has_rd_costs := object.get(input.jdg_entrepreneur, "has_rd_costs", false)

    ip_eligible := has_ip and ip_income > 0 and pit_form != "LUMP_SUM"
    ip_effective_rate := 0.05
    ip_breakeven := ip_costs * 1.2
    allowances_active := object.get(allowances.decide, "relief_type", "none")

    ip_routing := "TRIAGE_QUEUE" { ip_eligible; ip_income > 50000 }
    ip_routing := "" { true }
    ip_routing_reason := sprintf("IP Box opłacalny — %.0f PLN dochodu z IP @ 5%%", [ip_income]) { ip_eligible; ip_income > 50000 }
    ip_routing_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S1-140: ZUS COMPARISON BETWEEN TAX FORMS — Porównanie ZUS między formami
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.tax_opt.zus_comparison_by_form",
    "package": "jdg.tax_optimization",
    "priority": 140,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": current_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": "",
    "tax_opt_zus_scale_total": zus_scale_total,
    "tax_opt_zus_linear_total": zus_linear_total,
    "tax_opt_zus_lump_total": zus_lump_total,
    "tax_opt_zus_optimal_form": zus_optimal_form,
    "tax_opt_zus_savings_vs_current": zus_savings,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 79-81 ustawy zdrowotnej; Art. 18-22 SUS; Art. 30c ust. 2 PIT",
    "_warnings": [
        sprintf("🏥 PORÓWNANIE ZUS MIĘDZY FORMAMI", []),
        sprintf("   Skala (9%% zdrowotna): %.0f PLN/rok", [zus_scale_total]),
        sprintf("   Liniowy (4.9%% + odliczenie): %.0f PLN/rok", [zus_linear_total]),
        sprintf("   Ryczałt (3 progi): %.0f PLN/rok", [zus_lump_total]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        sprintf("   💡 Najniższy ZUS: %s — oszczędność %.0f PLN/rok", [zus_optimal_form, zus_savings]),
        "   ⚠️ UWAGA: Przy skali 9%% zdrowotna BEZ odliczenia od PIT!",
        "   ✅ Liniowy: 4.9%% z możliwością odliczenia max 12 900 PLN/rok"
    ]
} {
    input.tax_optimization_zus_comparison == true
    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    annual_profit := object.get(input.jdg_entrepreneur, "annual_income_projected", 120000) - object.get(input.jdg_entrepreneur, "annual_costs_projected", 30000)
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_income_projected", 120000)
    avg_wage := object.get(object.get(data.thresholds, "bounds", {}), "average_wage", 8000)

    zus_scale_health := annual_profit * 0.09
    zus_scale_total := zus_scale_health

    zus_linear_health := min([annual_profit * 0.049, data.jdg.thresholds.limits.health_linear_deduction_limit])
    zus_linear_total := zus_linear_health

    zus_lump_health := floor(avg_wage * 0.60 * 0.09 * 100) / 100 * 12 { annual_revenue <= 60000 }
    zus_lump_health := floor(avg_wage * 1.00 * 0.09 * 100) / 100 * 12 { annual_revenue > 60000; annual_revenue <= 300000 }
    zus_lump_health := floor(avg_wage * 1.80 * 0.09 * 100) / 100 * 12 { annual_revenue > 300000 }
    zus_lump_ded := floor(zus_lump_health * 0.50 * 100) / 100
    zus_lump_total := zus_lump_health - zus_lump_ded

    zus_optimal_form := "LINIOWY" { zus_linear_total < zus_scale_total; zus_linear_total <= zus_lump_total }
    zus_optimal_form := "RYCZALT" { zus_lump_total < zus_scale_total; zus_lump_total < zus_linear_total }
    zus_optimal_form := "SKALA" { zus_scale_total <= zus_linear_total; zus_scale_total <= zus_lump_total }

    zus_current := object.get({"PIT_SCALE": zus_scale_total, "LINEAR": zus_linear_total, "LUMP_SUM": zus_lump_total}, current_form, zus_scale_total)
    zus_optimal := object.get({"PIT_SCALE": zus_scale_total, "LINEAR": zus_linear_total, "LUMP_SUM": zus_lump_total}, zus_optimal_form, zus_scale_total)
    zus_savings := zus_current - zus_optimal
}

# ═══════════════════════════════════════════════════════════════════════════════
# S1-150: ESTONSKI CIT CONSIDERATION — Czy warto przejść na CIT estoński?
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.tax_opt.estonian_cit_analysis",
    "package": "jdg.tax_optimization",
    "priority": 150,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": current_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "tax_opt_estonian_eligible": est_eligible,
    "tax_opt_estonian_effective_rate": 0.09,
    "tax_opt_estonian_deferral_benefit": est_deferral,
    "tax_opt_estonian_profit_withdrawal_tax": est_withdrawal_tax,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Analiza CIT estońskiego — rozważ przekształcenie",
    "_legal_basis": "Art. 28c-28t CIT (rozdz. 6b — ryczałt od dochodów spółek)",
    "_warnings": [
        sprintf("🏢 CIT ESTOŃSKI — ANALIZA OPŁACALNOŚCI", []),
        sprintf("   Kwalifikacja: %s", ["TAK" { est_eligible } else "NIE — JDG musi przekształcić się w Sp. z o.o."]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "✅ ZALETY CIT ESTOŃSKIEGO:",
        "   • 0%% podatku dopóki zyski są reinwestowane",
        "   • 9%% CIT tylko przy wypłacie zysku (mały podatnik)",
        "   • 19%% CIT przy wypłacie (duży podatnik)",
        "   • Brak zaliczek miesięcznych — podatek tylko przy dystrybucji",
        "   • Uproszczona księgowość (brak odroczonego podatku)",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "⚠️ WYMAGANIA:",
        "   • Sp. z o.o. / S.A. (NIE dostępne dla JDG!)",
        "   • <50% przychodów pasywnych",
        "   • Zatrudnienie minimum 3 pracowników (nie właściciel)",
        "   • Nakłady inwestycyjne",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        sprintf("💰 Szacowana oszczędność przez odroczenie: %.0f PLN (przy reinwestycji)", [est_deferral])
    ]
} {
    input.tax_optimization_estonian_cit_check == true
    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    annual_profit := object.get(input.jdg_entrepreneur, "annual_income_projected", 120000) - object.get(input.jdg_entrepreneur, "annual_costs_projected", 30000)
    is_jdg := true
    has_min_employees := object.get(input.jdg_entrepreneur, "employee_count", 0) >= 3
    passive_income_pct := object.get(input.jdg_entrepreneur, "passive_income_pct", 0)

    est_eligible := not is_jdg and has_min_employees and passive_income_pct < 0.50
    est_deferral := annual_profit * 0.19
    est_withdrawal_tax := annual_profit * 0.09
}

# ═══════════════════════════════════════════════════════════════════════════════
# S1-160: JOINT FILING OPTIMIZATION — Wspólne rozliczenie z małżonkiem
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.tax_opt.joint_filing_optimizer",
    "package": "jdg.tax_optimization",
    "priority": 160,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": current_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "tax_opt_joint_filing_possible": joint_possible,
    "tax_opt_joint_filing_saves": joint_savings,
    "tax_opt_spouse_income": spouse_income,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": joint_routing,
    "_routing_reason": joint_routing_reason,
    "_legal_basis": "Art. 6 ust. 2-3 PIT (wspólne rozliczenie małżonków)",
    "_warnings": [
        sprintf("👫 WSPÓLNE ROZLICZENIE Z MAŁŻONKIEM", []),
        sprintf("   Dochód JDG: %.0f PLN | Dochód małżonka: %.0f PLN", [jdg_income, spouse_income]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        sprintf("   💰 Oszczędność: %.0f PLN", [joint_savings]),
        "   ✅ Rozliczenie na skali podatkowej (12%/32%)",
        "   ⚠️ TYLKO skala — NIE liniowy, NIE ryczałt!",
        "   ⚠️ Małżonek musi mieć PIT od etatu, emerytury lub renty",
        "   📅 Wniosek do 30 kwietnia roku następnego"
    ]
} {
    input.tax_optimization_joint_filing == true
    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    jdg_income := object.get(input.jdg_entrepreneur, "annual_income_projected", 120000) - object.get(input.jdg_entrepreneur, "annual_costs_projected", 30000)
    spouse_income := object.get(input.jdg_entrepreneur, "spouse_annual_income", 30000)
    spouse_has_own_income := spouse_income > 0

    joint_possible := current_form == "PIT_SCALE"
    joint_savings := 0
    joint_savings := jdg_income * 0.04 { current_form == "PIT_SCALE"; spouse_income < 30000 }
    joint_savings := jdg_income * 0.02 { current_form == "PIT_SCALE"; spouse_income >= 30000 }

    joint_routing := "TRIAGE_QUEUE" { joint_possible; joint_savings > 5000 }
    joint_routing := "" { true }
    joint_routing_reason := sprintf("Wspólne rozliczenie — oszczędność %.0f PLN", [joint_savings]) { joint_possible; joint_savings > 5000 }
    joint_routing_reason := sprintf("Liniowy/ryczałt — wspólne rozliczenie NIEMOŻLIWE", []) { not joint_possible }
    joint_routing_reason := "" { true }
}

build_stacking_warnings(combo, relief_pln) = warnings {
    count(combo) > 0
    relief_list := concat(" + ", combo)
    warnings := [
        sprintf("🎯 DOSTĘPNE ULGI: %s", [relief_list]),
        sprintf("💰 Szacowana oszczędność: ~%.0f PLN rocznie", [relief_pln]),
        "📋 IP Box wymaga OSOBNEJ ewidencji (Art. 30cb PIT) — załóż ją przed rozpoczęciem roku!",
        "⚠️ Ulgi odliczasz od DOCHODU (nie od podatku!) — kolejność ma znaczenie.",
        "💡 Strategia: najpierw odlicz ulgi limitowane kwotowo (B+R), potem IP Box od pozostałego dochodu."
    ]
} else = ["ℹ️ Nie wykryto dostępnych ulg podatkowych. Rozważ inwestycje w B+R, prototypy lub ekspansję zagraniczną."] {
    warnings := [true_warning]
}

# ═══════════════════════════════════════════════════════════════════════════════
# S1-120: CROSS-YEAR INCOME SMOOTHING — Strategiczne przesuwanie przychodów/kosztów
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.tax_opt.income_smoothing_strategy",
    "package": "jdg.tax_optimization",
    "priority": 120,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": income_bracket, "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "tax_opt_ytd_income": ytd_income,
    "tax_opt_proximity_to_threshold": proximity_pct,
    "tax_opt_smoothing_recommendation": recommendation,
    "tax_opt_potential_savings": potential_savings,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": routing_flag,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 14, 22 PIT; Art. 27 PIT",
    "_warnings": [sprintf("📅 STRATEGIA CZASOWA — Dochód YTD: %.0f PLN (%.0f%% progu %s). %s", [ytd_income, proximity_pct * 100, income_bracket, recommendation])]
} {
    input.tax_optimization_timing == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form == "PIT_SCALE"  # Income smoothing relevant only for progressive scale
    ytd_income := object.get(input.jdg_entrepreneur, "ytd_profit", 60000)
    months_elapsed := object.get(input.jdg_entrepreneur, "months_elapsed_in_year", 6)
    scale_threshold := object.get(object.get(data.thresholds, "pit", {}), "scale_threshold", 120000)
    projected_annual := ytd_income / months_elapsed * 12
    income_bracket := "12%" { projected_annual <= scale_threshold }
    income_bracket := "32%" { projected_annual > scale_threshold }
    proximity_pct := projected_annual / scale_threshold

    # Strategic timing recommendations
    recommendation := sprintf("Jesteś na granicy 32%% progu! Zaplanuj duże wydatki (sprzęt, szkolenia) jeszcze w tym roku. Możliwość przesunięcia przychodów (faktura w styczniu zamiast grudnia). Potencjalna oszczędność: ~%.0f PLN.", [potential_savings]) {
        proximity_pct >= 0.85
        proximity_pct <= 1.15
        potential_savings := (projected_annual - scale_threshold) * 0.20
    }

    recommendation := "Jesteś bezpiecznie poniżej 32% progu. Kontynuuj obecną strategię." { proximity_pct < 0.85 }

    recommendation := sprintf("Jesteś już w 32%% progu. Rozważ: amortyzację jednorazową (do 100k PLN), zwiększenie składek IKZE, przyspieszenie wydatków firmowych (Art. 22 PIT). Zaplanuj to PRZED końcem roku!", []) { proximity_pct > 1.15 }

    potential_savings := 0
    potential_savings := (projected_annual - scale_threshold) * 0.20 { proximity_pct > 0.85 }

    routing_flag := "TRIAGE_QUEUE" { proximity_pct >= 0.85 }
    routing_flag := "" { proximity_pct < 0.85 }
    routing_reason := sprintf("Blisko progu 32%% — rozważ optymalizację czasową (~%.0f PLN oszczędności)", [potential_savings]) { proximity_pct >= 0.85 }
    routing_reason := "" { proximity_pct < 0.85 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S1-130: HEALTH CONTRIBUTION OPTIMIZATION — Optymalizacja składki zdrowotnej
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.tax_opt.health_contribution_strategy",
    "package": "jdg.tax_optimization",
    "priority": 130,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": health_rate,
    "tax_opt_health_annual_pln": health_annual,
    "tax_opt_health_deductible_pln": health_deductible,
    "tax_opt_health_net_cost_pln": health_net_cost,
    "tax_opt_health_vs_public": public_comparison,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 79-81 ustawy o świadczeniach zdrowotnych; Art. 30c ust. 2 PIT",
    "_warnings": [sprintf("🏥 SKŁADKA ZDROWOTNA — Roczne obciążenie: %.0f PLN. %s. %s", [health_annual, deduction_info, strategy_hint])]
} {
    input.tax_optimization_health == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    monthly_income := object.get(input.jdg_entrepreneur, "monthly_profit_avg", 8000)
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")

    # Skala: 9% od dochodu, NIE podlega odliczeniu
    health_rate := "0.09" { pit_form == "PIT_SCALE" }
    health_annual := monthly_income * 0.09 * 12 { pit_form == "PIT_SCALE" }
    health_deductible := 0 { pit_form == "PIT_SCALE" }
    health_net_cost := health_annual { pit_form == "PIT_SCALE" }
    deduction_info := "Skala 12%: składka 9% NIE podlega odliczeniu od PIT (Polski Ład)" { pit_form == "PIT_SCALE" }
    strategy_hint := "Nie ma możliwości optymalizacji — składka zdrowotna na skali jest kosztem definitywnym." { pit_form == "PIT_SCALE" }

    # Liniowy: 4.9% od dochodu, podlega odliczeniu max 12 900 PLN/rok
    health_rate := "0.049" { pit_form == "LINEAR" }
    health_annual := monthly_income * 0.049 * 12 { pit_form == "LINEAR" }
    health_deductible := min([health_annual, data.jdg.thresholds.limits.health_linear_deduction_limit]) { pit_form == "LINEAR" }
    health_net_cost := health_annual - health_deductible { pit_form == "LINEAR" }
    deduction_info := sprintf("Liniowy: składka 4.9%% podlega odliczeniu od PIT (max 12 900 PLN). Odliczasz %.0f PLN.", [health_deductible]) { pit_form == "LINEAR" }
    strategy_hint := "Rozważ zwiększenie dochodu (odliczenie rośnie z dochodem do limitu 12 900 PLN)." { pit_form == "LINEAR" }

    # Ryczałt: 3 progi w zależności od przychodu
    health_rate := "progressywna (3 progi)" { pit_form == "LUMP_SUM" }
    annual_revenue := monthly_income * 12 { pit_form == "LUMP_SUM" }
    health_annual := 419 * 12 { pit_form == "LUMP_SUM"; annual_revenue <= 60000 }
    health_annual := 698 * 12 { pit_form == "LUMP_SUM"; annual_revenue > 60000; annual_revenue <= 300000 }
    health_annual := 1257 * 12 { pit_form == "LUMP_SUM"; annual_revenue > 300000 }
    health_deductible := floor(health_annual * 0.5) { pit_form == "LUMP_SUM" }
    health_net_cost := health_annual - health_deductible { pit_form == "LUMP_SUM" }
    deduction_info := sprintf("Ryczałt: składka w 3 progach. Płacisz %.0f PLN/mies. 50%% podlega odliczeniu.", [health_annual/12]) { pit_form == "LUMP_SUM" }
    strategy_hint := "Uważaj na przekroczenie progów ryczałtowych — składka skokowo rośnie!" { pit_form == "LUMP_SUM" }

    public_comparison := sprintf("Dla porównania: etatowiec płaci 9%% od pensji brutto (pracownik ~7.75%% + pracodawca ~1.25%%).", [])
}

# ═══════════════════════════════════════════════════════════════════════════════
# S1-140: ZUS RELIEF PATH OPTIMIZATION — Optymalizacja ścieżki ulg ZUS
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.tax_opt.zus_relief_path",
    "package": "jdg.tax_optimization",
    "priority": 140,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": "",
    "tax_opt_zus_path": optimal_path,
    "tax_opt_zus_monthly_now": current_zus,
    "tax_opt_zus_monthly_optimal": optimal_zus,
    "tax_opt_zus_annual_savings": annual_savings,
    "business_status": business_age_months,
    "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Optymalizacja ZUS: %s → roczna oszczędność %.0f PLN", [optimal_path, annual_savings]),
    "_legal_basis": "Art. 18a, 18c SUS; Art. 5 Prawa przedsiębiorców",
    "_warnings": [sprintf("🛡️ OPTYMALIZACJA ZUS — Obecnie: %s (~%.0f PLN/mies). Optymalna ścieżka: %s (~%.0f PLN/mies). Roczna oszczędność: %.0f PLN! %s", [zus_status, current_zus, optimal_path, optimal_zus, annual_savings, action])]
} {
    input.tax_optimization_zus == true
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    business_age_months := object.get(input.jdg_entrepreneur, "business_age_months", 24)
    monthly_revenue := object.get(input.jdg_entrepreneur, "monthly_revenue_avg", 8000)
    last_year_revenue := object.get(input.jdg_entrepreneur, "last_year_revenue", 96000)
    had_previous_business := object.get(input.jdg_entrepreneur, "had_previous_business_24mo", false)
    is_previous_employee := object.get(input.jdg_entrepreneur, "was_employee_same_employer_12mo", false)
    min_wage := object.get(object.get(data.thresholds, "bounds", {}), "minimum_wage_gross", 4666)

    standard_zus := floor(min_wage * 0.60 * 0.3812 * 100) / 100 + floor(min_wage * 0.09 * 100) / 100
    preferential_zus := floor(min_wage * 0.30 * 0.3812 * 100) / 100 + floor(min_wage * 0.09 * 100) / 100
    maly_zus_plus := floor(last_year_revenue / 12 * 0.30 * 0.3812 * 100) / 100 + floor(min_wage * 0.09 * 100) / 100
    unregistered_zus := floor(min_wage * 0.09 * 100) / 100  # Tylko zdrowotna

    current_zus := standard_zus { zus_status == "STANDARD" }
    current_zus := preferential_zus { zus_status == "PREFERENTIAL" }
    current_zus := maly_zus_plus { zus_status == "MALY_ZUS_PLUS" }
    current_zus := 0 { zus_status == "START_RELIEF" }
    current_zus := unregistered_zus { zus_status == "UNREGISTERED" }

    # Determine optimal path
    optimal_path := "DZIAŁALNOŚĆ NIEEWIDENCJONOWANA" { monthly_revenue < min_wage * 0.50; business_age_months < 1 }
    optimal_path := "ULGA NA START (6 mies)" { business_age_months < 6; not had_previous_business; not is_previous_employee }
    optimal_path := "PREFERENCYJNY ZUS (24 mies)" { business_age_months < 24; business_age_months >= 6; not had_previous_business }
    optimal_path := "MAŁY ZUS PLUS (36 mies)" { last_year_revenue <= 120000; business_age_months >= 24; business_age_months < 60 }
    optimal_path := "STANDARD ZUS" { true }

    optimal_zus := 0 { optimal_path == "DZIAŁALNOŚĆ NIEEWIDENCJONOWANA" }
    optimal_zus := 0 { optimal_path == "ULGA NA START (6 mies)" }
    optimal_zus := preferential_zus { optimal_path == "PREFERENCYJNY ZUS (24 mies)" }
    optimal_zus := maly_zus_plus { optimal_path == "MAŁY ZUS PLUS (36 mies)" }
    optimal_zus := standard_zus { optimal_path == "STANDARD ZUS" }

    annual_savings := (current_zus - optimal_zus) * 12

    action := sprintf("Zmień status w CEIDG-1 + złóż ZUS ZZA. Oszczędzasz %.0f PLN/rok!", [annual_savings]) {
        zus_status != optimal_path 
        optimal_path != "STANDARD ZUS"
        annual_savings > 0
    }

    action := sprintf("Jesteś już na optymalnej ścieżce %s. Monitoruj limity przychodowe.", [optimal_path]) {
        zus_status == optimal_path
    }

    action := "Koniec ulg — jesteś na standardowym ZUS. Rozważ optymalizację przez formę opodatkowania." {
        optimal_path == "STANDARD ZUS"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S1-150: VAT EXEMPTION VS REGISTRATION STRATEGY — Strategia VAT
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.tax_opt.vat_registration_strategy",
    "package": "jdg.tax_optimization",
    "priority": 150,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "tax_opt_vat_status": vat_status,
    "tax_opt_vat_recommendation": recommendation,
    "tax_opt_vat_net_benefit": net_benefit,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Strategia VAT: %s", [recommendation]),
    "_legal_basis": "Art. 113 VAT (zwolnienie podmiotowe 200 000 PLN)",
    "_warnings": [sprintf("📊 STRATEGIA VAT — Status: %s. %s. Korzyść netto: %.0f PLN/rok. %s", [vat_status, recommendation, net_benefit, action_item])]
} {
    input.tax_optimization_vat == true
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 150000)
    vat_limit := object.get(object.get(data.thresholds, "vat", {}), "subject_exemption_limit", 200000)
    sells_to_consumers := object.get(input.jdg_entrepreneur, "sells_b2c_mostly", false)
    buys_from_vat_payers := object.get(input.jdg_entrepreneur, "buys_from_vat_payers", true)
    purchases_with_vat := object.get(input.jdg_entrepreneur, "annual_purchases_vat_pln", 30000)
    business_margin_pct := object.get(input.jdg_entrepreneur, "business_margin_pct", 0.30)

    vat_status := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT")
    is_exempt := vat_status == "EXEMPT"
    close_to_limit := annual_revenue > vat_limit * 0.80

    # Benefit of being VAT payer
    vat_on_purchases := purchases_with_vat * 0.23
    vat_on_sales := annual_revenue * 0.23
    net_vat_paid := vat_on_sales - vat_on_purchases
    admin_cost := 2000  # Estimated annual compliance cost

    recommendation := "✅ POZOSTAŃ NA ZWOLNIENIU — Twoje przychody są bezpiecznie poniżej limitu 200k PLN. Zwolnienie z VAT upraszcza księgowość (brak JPK, brak deklaracji)." {
        is_exempt
        annual_revenue <= vat_limit * 0.50
        sells_to_consumers
    }

    recommendation := "⚠️ ROZWAŻ REJESTRACJĘ VAT — Jesteś blisko limitu 200k PLN. Rejestracja przed przekroczeniem daje Ci prawo do odliczenia VAT od zakupów." {
        is_exempt
        close_to_limit
        buys_from_vat_payers
    }

    recommendation := sprintf("🔴 PRZEKROCZYŁEŚ LIMIT %.0f PLN — REJESTRACJA VAT OBOWIĄZKOWA! Złóż VAT-R natychmiast (przed pierwszą transakcją po przekroczeniu).", [vat_limit]) {
        is_exempt
        annual_revenue > vat_limit
    }

    recommendation := "✅ JESTEŚ CZYNNYM VAT-owcem. Prowadź dalej." { not is_exempt }

    net_benefit := 0
    net_benefit := vat_on_purchases - net_vat_paid - admin_cost { is_exempt; buys_from_vat_payers }
    net_benefit := 0 - net_vat_paid - admin_cost { is_exempt; not buys_from_vat_payers }

    action_item := "Złóż VAT-R przez CEIDG. KSeF będzie obowiązkowy od 2026-02-01." { close_to_limit }
    action_item := "Nie wymaga działań." { not close_to_limit }
}
