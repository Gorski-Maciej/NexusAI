# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE STRATEGIC BUSINESS ADVISOR (S5)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Strategic Advisor — Business Intelligence Layer
# description: |
#   ENTERPRISE v5.0 — Najwyższa warstwa doradcza. Analizuje biznes JDG
#   całościowo: rentowność, skalowanie, zatrudnienie, inwestycje,
#   przekształcenia (JDG → Sp. z o.o.), CIT estoński vs PIT.
#   Podejmuje decyzje strategiczne wykraczające poza pojedyncze faktury.
#   To "wirtualny CFO" — część, której NIE da się w 100% zautomatyzować,
#   ale można dostarczyć analitykę do podjęcia decyzji przez człowieka.
# architecture: Enterprise Strategic Layer, First-Match-Wins else-chain
# legal_basis: PIT, CIT, KSH, Prawo Przedsiębiorców, UoR
# package: jdg.strategic_advisor
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.strategic_advisor

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.strategic.no_match",
    "package": "jdg.strategic_advisor", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# S5-500: BUSINESS TRANSFORMATION ADVISOR — JDG → Sp. z o.o. analiza
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.strategic.transformation_jdg_to_spzoo",
    "package": "jdg.strategic_advisor",
    "priority": 500,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": "",
    "strategic_transformation_recommended": transform_recommended,
    "strategic_spzoo_estimated_tax_pct": spzoo_tax_pct,
    "strategic_breakeven_revenue_pln": breakeven_revenue,
    "strategic_transformation_roi_months": roi_months,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Analiza przekształcenia JDG→Sp. z o.o.: %s", [transform_verdict]),
    "_legal_basis": "Art. 551-584 KSH (przekształcenie); Art. 19 CIT (19%/9%); Art. 30c PIT (19% liniowy)",
    "_warnings": [
        sprintf("🏢 ANALIZA PRZEKSZTAŁCENIA JDG → SP. Z O.O.\n💰 JDG: PIT %.0f PLN + Zdrowotna %.0f PLN + ZUS %.0f PLN = %.0f PLN/rok\n💰 Sp. z o.o.: CIT %.0f PLN + Admin %.0f PLN = %.0f PLN/rok\n📊 REKOMENDACJA: %s\n💡 Próg opłacalności: ~%.0f PLN zysku rocznie.", 
            [pit_tax, health_insurance, zus_annual, jdg_total_burden, cit_tax, spzoo_admin_cost, spzoo_total_burden, transform_verdict, breakeven_revenue])
    ]
} {
    input.strategic_transformation_analysis == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 300000)
    annual_profit := object.get(input.jdg_entrepreneur, "annual_profit_actual", 100000)
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    employee_count := object.get(input.jdg_entrepreneur, "employee_count", 0)
    wants_limited_liability := object.get(input.jdg_entrepreneur, "wants_limited_liability", false)
    reinvests_profits := object.get(input.jdg_entrepreneur, "reinvests_profits", false)
    plans_exit := object.get(input.jdg_entrepreneur, "plans_business_exit_5y", false)

    # PIT costs
    pit_effective_pct := 0.19 { pit_form == "LINEAR" }
    pit_effective_pct := min([0.12 + (max([annual_profit - 120000, 0]) / annual_profit) * 0.32, 0.32]) { pit_form == "PIT_SCALE"; annual_profit > 0 }
    pit_effective_pct := 0.12 { pit_form == "PIT_SCALE"; annual_profit <= 120000; annual_profit > 0 }
    pit_effective_pct := 0.15 { pit_form == "LUMP_SUM" }
    
    pit_tax := annual_profit * pit_effective_pct
    health_insurance := annual_profit * 0.09 { pit_form == "PIT_SCALE" }
    health_insurance := min([annual_profit * 0.049, 12900]) { pit_form == "LINEAR" }
    health_insurance := 8000 { pit_form == "LUMP_SUM" }
    zus_annual := 12000  # Approx annual ZUS
    
    jdg_total_burden := pit_tax + health_insurance + zus_annual

    # Sp. z o.o. costs
    uses_cit_estonski := reinvests_profits and not has_employees
    cit_rate := 0.09 { uses_cit_estonski }  # CIT estoński 9% (mały podatnik)
    cit_rate := 0.19 { not uses_cit_estonski }
    cit_tax := 0 { uses_cit_estonski; reinvests_profits }  # Estoński: brak podatku przy reinwestycji
    cit_tax := annual_profit * cit_rate { not uses_cit_estonski }
    
    # Sp. z o.o. additional costs
    accounting_cost := 6000  # Full accounting ~500 PLN/month
    krs_cost := 3000  # KRS filings, annual reports
    management_board_zus := 12000  # Management board member ZUS
    spzoo_admin_cost := accounting_cost + krs_cost + management_board_zus
    
    spzoo_total_burden := cit_tax + spzoo_admin_cost { not uses_cit_estonski }
    spzoo_total_burden := spzoo_admin_cost { uses_cit_estonski }
    
    # Break-even analysis
    savings := jdg_total_burden - spzoo_total_burden
    breakeven_revenue := 180000  # Approximate break-even for transformation
    transform_recommended := savings > 15000
    transform_recommended := true { wants_limited_liability; annual_profit > 200000 }
    transform_recommended := true { plans_exit; annual_revenue > 500000 }
    transform_recommended := true { uses_cit_estonski; reinvests_profits }
    
    spzoo_tax_pct := cit_rate * 100
    
    roi_months := 0
    roi_months := floor(5000 / (savings / 12)) { savings > 0 }
    
    transform_verdict := sprintf("PRZEKSZTAŁCENIE OPŁACALNE — oszczędność ~%.0f PLN/rok. Zwrot kosztów w ~%d mies.", [savings, roi_months]) { transform_recommended; savings > 0 }
    transform_verdict := sprintf("POZOSTAŃ NA JDG — obecna forma optymalna. Oszczędzasz %.0f PLN vs Sp. z o.o.", [abs(savings)]) { not transform_recommended }
}

build_transformation_warnings() = [
    sprintf("🏢 ANALIZA PRZEKSZTAŁCENIA JDG → SP. Z O.O.", []),
    "",
    "💰 PORÓWNANIE KOSZTÓW:",
    sprintf("   JDG: PIT %.0f PLN + Zdrowotna %.0f PLN + ZUS %.0f PLN = %.0f PLN/rok", [pit_tax, health_insurance, zus_annual, jdg_total_burden]),
    sprintf("   Sp. z o.o.: CIT %.0f PLN + Admin %.0f PLN = %.0f PLN/rok", [cit_tax, spzoo_admin_cost, spzoo_total_burden]),
    "",
    "✅ ZALETY SP. Z O.O.:",
    "   • Ograniczona odpowiedzialność (nie odpowiadasz majątkiem prywatnym!)",
    "   • CIT estoński 9% — brak podatku przy reinwestycji zysków",
    "   • Łatwiejsza sprzedaż firmy (udziały zamiast przedsiębiorstwa)",
    "   • Większa wiarygodność wobec kontrahentów i banków",
    "",
    "⚠️ WADY SP. Z O.O.:",
    "   • Pełna księgowość (UoR) — wyższe koszty księgowe (~500 PLN/mies)",
    "   • Obowiązki KRS (sprawozdania finansowe, zmiany w KRS)",
    "   • Podwójne opodatkowanie (CIT + PIT od dywidendy 19%)",
    "   • Więcej formalności (zgromadzenia wspólników, uchwały)",
    "",
    sprintf("📊 REKOMENDACJA: %s", [transform_verdict]),
    sprintf("💡 Próg opłacalności: ~%.0f PLN zysku rocznie.", [breakeven_revenue])
] {
    transform_verdict != ""
} else = ["📊 Brak wystarczających danych do analizy przekształcenia."] {
    warnings := [fallback_msg]
}

# Helper variables initialized inside rule body

# ═══════════════════════════════════════════════════════════════════════════════
# S5-510: PROFITABILITY & SCALING ADVISOR — Analiza rentowności i skalowania
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.strategic.profitability_scaling",
    "package": "jdg.strategic_advisor",
    "priority": 510,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_gross_margin_pct": gross_margin,
    "strategic_net_margin_pct": net_margin,
    "strategic_monthly_burn_rate": burn_rate,
    "strategic_runway_months": runway_months,
    "strategic_scaling_recommendation": scaling_reco,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": margin_routing,
    "_routing_reason": margin_reason,
    "_legal_basis": "Ogólne — analiza biznesowa (best practice)",
    "_warnings": build_profitability_warnings(gross_margin, net_margin, runway_months)
} {
    input.strategic_profitability_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    monthly_revenue := object.get(input.jdg_entrepreneur, "monthly_revenue_avg", 15000)
    monthly_costs := object.get(input.jdg_entrepreneur, "monthly_costs_avg", 8000)
    monthly_salary_draw := object.get(input.jdg_entrepreneur, "monthly_owner_draw", 5000)
    cash_reserves := object.get(input.jdg_entrepreneur, "cash_reserves", 30000)
    revenue_trend_6mo := object.get(input.jdg_entrepreneur, "revenue_trend_6mo_pct", 0)
    
    # Key metrics
    gross_margin := floor((monthly_revenue - monthly_costs) / max([monthly_revenue, 1]) * 10000) / 100
    net_margin := floor((monthly_revenue - monthly_costs - monthly_salary_draw) / max([monthly_revenue, 1]) * 10000) / 100
    burn_rate := monthly_costs + monthly_salary_draw
    runway_months := floor(cash_reserves / burn_rate)
    
    scaling_reco := "🚀 SKALUJ! Rosnące przychody + wysoka marża. Rozważ: zatrudnienie, automatyzację, zwiększenie marketingu." {
        gross_margin > 50
        revenue_trend_6mo > 20
        net_margin > 30
    }
    
    scaling_reco := "📈 STABILNY WZROST. Utrzymuj kurs. Rozważ reinwestycję 30% zysków w rozwój." {
        gross_margin > 30
        revenue_trend_6mo > 5
        net_margin > 15
    }
    
    scaling_reco := "⚠️ OPTYMALIZUJ KOSZTY. Marża spada. Przejrzyj wydatki, renegocjuj umowy z dostawcami." {
        gross_margin <= 30
        gross_margin > 10
    }
    
    scaling_reco := "🔴 KRYTYCZNIE! Marża poniżej 10%. Natychmiastowa optymalizacja kosztów lub zmiana modelu biznesowego." {
        gross_margin <= 10
    }
    
    margin_routing := "TRIAGE_QUEUE" { gross_margin <= 10 }
    margin_routing := "TRIAGE_QUEUE" { runway_months <= 3 }
    margin_routing := "" { true }
    
    margin_reason := sprintf("Marża brutto %.1f%% — poniżej krytycznego poziomu", [gross_margin]) { gross_margin <= 10 }
    margin_reason := sprintf("Zapasy gotówki na %d mies — zagrożenie płynności!", [runway_months]) { runway_months <= 3 }
    margin_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S5-520: INVESTMENT & CAPEX ADVISOR — Doradca inwestycyjny
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.strategic.investment_advisor",
    "package": "jdg.strategic_advisor",
    "priority": 520,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": kus_qual, "kus_percent": kus_pct,
    "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_investment_kup_qualifies": kup_qualifies,
    "strategic_depreciation_method": depr_method,
    "strategic_one_time_depr_eligible": can_one_time,
    "strategic_rd_relief_eligible": rd_eligible,
    "strategic_leasable": is_leasable,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": invest_routing,
    "_routing_reason": invest_reason,
    "_legal_basis": "Art. 22a-22o PIT (amortyzacja); Art. 26e PIT (B+R); Art. 23b PIT (leasing)",
    "_warnings": [
        sprintf("🏭 INWESTYCJA %.0f PLN (%s)\n📋 Amortyzacja: %s\n💰 Jednorazowa: %s\n🔬 B+R: %s\n🚗 Leasing: %s\n💡 %s",
            [asset_value, asset_type, depr_method, one_time_info, rd_info, lease_info, invest_strategy])
    ]
} {
    input.strategic_investment_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    asset_type := object.get(input.invoice, "fixed_asset_type", "GENERAL")
    asset_value := object.get(input.invoice, "fixed_asset_value", 0)
    is_new_asset := object.get(input.invoice, "fixed_asset_is_new", true)
    is_used_asset := not is_new_asset
    has_rd_activity := object.get(input.jdg_entrepreneur, "has_rd_activity", false)
    uses_rd_relief := object.get(input.jdg_entrepreneur, "uses_rd_relief", false)
    ytd_profit := object.get(input.jdg_entrepreneur, "ytd_profit", 100000)
    employee_count := object.get(input.jdg_entrepreneur, "employee_count", 0)
    
    # Investment classification
    is_low_value := asset_value <= 10000
    is_medium_value := asset_value > 10000 and asset_value <= 100000
    is_high_value := asset_value > 100000 and asset_value <= 1000000
    is_capex := asset_value > 1000000
    
    # KUP qualification
    kup_qualifies := true { asset_value > 0 }
    depr_method := "Jednorazowa amortyzacja (Art. 22k ust. 7 PIT)" { is_low_value; is_new_asset; employee_count < 50 }
    depr_method := "Indywidualna stawka (używany, min 30 mies amortyzacji)" { is_used_asset }
    depr_method := "Liniowa — stawka wg KŚT" { not is_low_value; not is_used_asset }
    
    can_one_time := is_low_value and is_new_asset and employee_count < 50
    
    # R&D relief eligibility for investments
    rd_eligible := asset_type == "IT_EQUIPMENT" or asset_type == "LAB_EQUIPMENT" or asset_type == "PROTOTYPE"
    rd_eligible := rd_eligible and has_rd_activity and uses_rd_relief
    
    # Lease vs buy analysis
    is_leasable := asset_value > 50000 and asset_type != "REAL_ESTATE"
    
    kus_qual := "deductible_full" { kup_qualifies }
    kus_pct := 100 { kup_qualifies }
    
    invest_routing := "TRIAGE_QUEUE" { is_capex }
    invest_routing := "" { not is_capex }
    invest_reason := sprintf("Inwestycja %.0f PLN — Capex. Rozważ leasing zamiast zakupu.", [asset_value]) { is_capex }
    invest_reason := "" { not is_capex }

    one_time_info := "TAK — do 100 000 PLN" { can_one_time }
    one_time_info := "NIE" { not can_one_time }
    rd_info := "TAK — koszt kwalifikowany B+R" { rd_eligible }
    rd_info := "NIE" { not rd_eligible }
    lease_info := "TAK — leasing korzystniejszy" { is_leasable }
    lease_info := "NIE" { not is_leasable }
    invest_strategy := "KUP TERAZ — jednorazowa amortyzacja" { can_one_time }
    invest_strategy := "ROZWAŻ LEASING" { is_leasable; not can_one_time }
    invest_strategy := "AMORTYZUJ LINIOWO" { not can_one_time; not is_leasable }
}

build_investment_warnings() = [
    sprintf("🏭 ANALIZA INWESTYCJI: %.0f PLN (%s)", [asset_value, asset_type]),
    "",
    sprintf("📋 Metoda amortyzacji: %s", [depr_method]),
    "",
    sprintf("💰 JEDNORAZOWA AMORTYZACJA: %s", ["TAK — do 100 000 PLN w roku (mały podatnik + nowy środek trwały)"]) { can_one_time },
    sprintf("💰 JEDNORAZOWA AMORTYZACJA: %s", ["NIE — nie spełniasz warunków (limit 100k, nowy ŚT, <50 pracowników)"]) { not can_one_time },
    "",
    sprintf("🔬 ULGA B+R: %s", ["TAK — sprzęt może być kosztem kwalifikowanym B+R (100%% odliczenia + 100-200%% ulgi!)"]) { rd_eligible },
    sprintf("🔬 ULGA B+R: %s", ["NIE — nie prowadzisz działalności B+R lub sprzęt nie jest laboratoryjny"]) { not rd_eligible },
    "",
    sprintf("🚗 LEASING: %s", ["TAK — leasing operacyjny da Ci 100%% rat w KUP zamiast amortyzacji przez kilka lat"]) { is_leasable },
    "",
    "💡 STRATEGIA:",
    sprintf("   %s", [strategy])
] {
    true
}

strategy := "KUP TERAZ — skorzystaj z jednorazowej amortyzacji (100% w koszty od razu!)" { can_one_time }
strategy := "ROZWAŻ LEASING — raty leasingowe w 100% KUP od razu" { is_leasable; not can_one_time }
strategy := "AMORTYZUJ LINIOWO — zachowaj płynność" { not can_one_time; not is_leasable }

# ═══════════════════════════════════════════════════════════════════════════════
# S5-530: ANNUAL STRATEGIC REVIEW — Roczny przegląd strategiczny
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.strategic.annual_review",
    "package": "jdg.strategic_advisor",
    "priority": 530,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": "",
    "strategic_annual_recommendations": recommendations,
    "strategic_next_year_goals": goals,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Roczny przegląd strategiczny — zaplanuj działania na kolejny rok",
    "_legal_basis": "Ogólne — planowanie strategiczne",
    "_warnings": build_annual_warnings()
} {
    input.strategic_annual_review == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 200000)
    annual_profit := object.get(input.jdg_entrepreneur, "annual_profit_actual", 80000)
    business_age_years := object.get(input.jdg_entrepreneur, "business_age_years", 3)
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    
    recommendations := []
    goals := []
    
    # Strategic recommendations based on business stage
    recommendations := array.concat(recommendations, ["ZMIEŃ FORMĘ OPODATKOWANIA — przy %.0f PLN zysku liniowy 19%% może być korzystniejszy niż skala 32%%", [annual_profit]]) {
        pit_form == "PIT_SCALE"; annual_profit > 150000
    }
    
    recommendations := array.concat(recommendations, ["ROZWAŻ CIT ESTOŃSKI — reinwestuj zyski bez podatku (9%% CIT tylko przy wypłacie)"]) {
        annual_profit > 200000; not has_employees
    }
    
    recommendations := array.concat(recommendations, ["ZATRUDNIJ PRACOWNIKA — przy %.0f PLN przychodu sam już nie ogarniasz. Deleguj.", [annual_revenue]]) {
        annual_revenue > 300000; not has_employees
    }
    
    recommendations := array.concat(recommendations, ["ZMIEŃ NA MAŁY ZUS PLUS — przychód %.0f PLN kwalifikuje Cię do niższych składek.", [annual_revenue]]) {
        zus_status == "STANDARD"; annual_revenue <= 120000; business_age_years > 2
    }
    
    recommendations := array.concat(recommendations, ["ZAINWESTUJ W B+R — przy %.0f PLN zysku ulga B+R da Ci dodatkowe odliczenia.", [annual_profit]]) {
        annual_profit > 50000; not has_employees
    }
    
    goals := array.concat(goals, [sprintf("Cel: zwiększyć przychód o 20%% do %.0f PLN", [annual_revenue * 1.20])])
    goals := array.concat(goals, [sprintf("Cel: obniżyć efektywną stopę podatkową o 2pp przez ulgi", [])])
    goals := array.concat(goals, ["Cel: zbudować poduszkę finansową na 6 miesięcy"])
}

build_annual_warnings() = [
    "📅 ROCZNY PRZEGLĄD STRATEGICZNY JDG",
    sprintf("   Przychód: %.0f PLN | Zysk: %.0f PLN | Forma: %s | ZUS: %s", [annual_revenue, annual_profit, pit_form, zus_status]),
    "",
    "🎯 REKOMENDACJE:"
] {
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# S5-540: HIRING DECISION ADVISOR — Analiza opłacalności zatrudnienia
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.strategic.hiring_advisor",
    "package": "jdg.strategic_advisor",
    "priority": 540,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_hiring_breakeven_revenue": hiring_breakeven,
    "strategic_hiring_monthly_cost": hiring_monthly_cost,
    "strategic_hiring_recommended": hiring_recommended,
    "strategic_hiring_rd_eligible": hiring_rd,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": hiring_routing,
    "_routing_reason": hiring_reason,
    "_legal_basis": "KP; Art. 26eb PIT (innowacyjni pracownicy); Art. 18d CIT",
    "_warnings": [
        sprintf("👥 DECYZJA O ZATRUDNIENIU", []),
        sprintf("   Koszt miesieczny: %.0f PLN", [hiring_monthly_cost]),
        sprintf("   Prog oplacalnosci: %.0f PLN dodatkowego przychodu/mies", [hiring_breakeven]),
        sprintf("   %s", ["✅ ZATRUDNIJ — zwiekszysz moc przerobowa" { hiring_recommended } else "⏳ POCZEKAJ — za wczesnie"])
    ]
} {
    input.strategic_hiring_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    monthly_revenue := object.get(input.jdg_entrepreneur, "monthly_revenue_avg", 15000)
    revenue_trend := object.get(input.jdg_entrepreneur, "revenue_trend_6mo_pct", 0)
    current_hours_utilization := object.get(input.jdg_entrepreneur, "hours_utilization_pct", 0.80)
    min_wage := object.get(object.get(data.thresholds, "bounds", {}), "minimum_wage_gross", 4666)

    hiring_monthly_cost := min_wage * 1.40
    hiring_breakeven := hiring_monthly_cost / 0.30
    hiring_recommended := current_hours_utilization > 0.90 and revenue_trend > 15
    hiring_rd := object.get(input.jdg_entrepreneur, "has_rd_activity", false) and hiring_recommended

    hiring_routing := "TRIAGE_QUEUE" { hiring_recommended }
    hiring_routing := "" { true }
    hiring_reason := "Zatrudnienie rekomendowane — wykorzystanie >90% i trend wzrostowy" { hiring_recommended }
    hiring_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S5-550: EXIT STRATEGY PLANNER — Plan wyjścia z biznesu
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.strategic.exit_planner",
    "package": "jdg.strategic_advisor",
    "priority": 550,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_exit_options": exit_options,
    "strategic_exit_estimated_value": exit_value,
    "strategic_exit_tax_impact": exit_tax,
    "strategic_exit_recommended_path": exit_path,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": exit_routing,
    "_routing_reason": exit_reason,
    "_legal_basis": "Art. 30da PIT (exit tax); Art. 551-584 KSH; Art. 24 ust. 5 PIT",
    "_warnings": [
        sprintf("🚪 PLANOWANIE EXIT — STRATEGIA WYJSCIA", []),
        sprintf("   Szacowana wartosc: %.0f PLN", [exit_value]),
        sprintf("   Exit tax: %.0f PLN", [exit_tax]),
        sprintf("   Rekomendowana sciezka: %s", [exit_path])
    ]
} {
    input.strategic_exit_plan == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    annual_profit := object.get(input.jdg_entrepreneur, "annual_profit_actual", 100000)
    business_assets := object.get(input.jdg_entrepreneur, "business_assets_value", 50000)
    plans_exit := object.get(input.jdg_entrepreneur, "plans_business_exit_5y", false)
    has_successor := object.get(input.jdg_entrepreneur, "has_successor", false)

    exit_value := annual_profit * 2.5 + business_assets * 0.80
    exit_tax := exit_value * 0.19

    exit_options := ["Sprzedaz firmy", "Przeksztalcenie w Sp. z o.o. + sprzedaz udzialow", "Sukcesja familyjna", "Likwidacja"]
    exit_path := "Przeksztalcenie w Sp. z o.o. + sprzedaz udzialow" { plans_exit; exit_value > 500000 }
    exit_path := "Sukcesja familyjna" { has_successor }
    exit_path := "Sprzedaz JDG" { true }

    exit_routing := "TRIAGE_QUEUE" { plans_exit }
    exit_routing := "" { true }
    exit_reason := "Planowanie exit — rozpoczac przygotowania 2 lata przed" { plans_exit }
    exit_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S5-560: ESG/SUSTAINABILITY ADVISOR — Doradca zrównoważonego rozwoju
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.strategic.esg_advisor",
    "package": "jdg.strategic_advisor",
    "priority": 560,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_esg_score": esg_score,
    "strategic_esg_carbon_estimate": carbon_est,
    "strategic_esg_csr_relief_eligible": csr_eligible,
    "strategic_esg_bdo_required": bdo_required,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": esg_routing,
    "_routing_reason": esg_reason,
    "_legal_basis": "Art. 26ha PIT (ulga CSR); Ustawa o BDO; Taksonomia EU",
    "_warnings": [
        sprintf("🌱 ESG — ZROWNOWAZONY ROZWOJ", []),
        sprintf("   ESG Score: %d/100", [esg_score]),
        sprintf("   Szacowany slad weglowy: %.1f t CO2/rok", [carbon_est]),
        sprintf("   Ulga CSR: %s", ["DOSTEPNA (150%% KUP)" { csr_eligible } else "BRAK"])
    ]
} {
    input.strategic_esg_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 200000)
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    industry := object.get(input.jdg_entrepreneur, "industry", "GENERAL")
    has_csr_expenses := object.get(input.jdg_entrepreneur, "has_csr_sponsoring", false)

    esg_score := 50
    esg_score := esg_score + 20 { has_csr_expenses }
    esg_score := esg_score + 10 { has_employees }

    carbon_est := annual_revenue * 0.00005
    csr_eligible := has_csr_expenses and pit_form != "LUMP_SUM"
    bdo_required := industry in {"MANUFACTURING", "CONSTRUCTION", "TRANSPORT", "WASTE"}

    esg_routing := "TRIAGE_QUEUE" { bdo_required }
    esg_routing := "" { true }
    esg_reason := "BDO wymagane — zarejestruj sie w bazie BDO" { bdo_required }
    esg_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S5-570: DIGITAL TRANSFORMATION ADVISOR — Doradca cyfryzacji
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.strategic.digital_transformation",
    "package": "jdg.strategic_advisor",
    "priority": 570,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "strategic_digital_ksef_ready": ksef_ready,
    "strategic_digital_epuap_active": epuap_active,
    "strategic_digital_automation_potential_pct": automation_pct,
    "strategic_digital_next_steps": digital_steps,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": dig_routing,
    "_routing_reason": dig_reason,
    "_legal_basis": "Ustawa o KSeF; Ustawa o e-Doreczeniach; Ustawa o dostepnosci cyfrowej",
    "_warnings": [
        sprintf("💻 TRANSFORMACJA CYFROWA JDG", []),
        sprintf("   KSeF gotowosc: %s", ["TAK" { ksef_ready } else "NIE — wymagane do 2026"]),
        sprintf("   ePUAP/e-Doreczenia: %s", ["AKTYWNE" { epuap_active } else "NIEAKTYWNE"]),
        sprintf("   Potencjal automatyzacji: %.0f%%", [automation_pct * 100])
    ]
} {
    input.strategic_digital_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    uses_ksef := object.get(input.jdg_entrepreneur, "uses_ksef", false)
    has_epuap := object.get(input.jdg_entrepreneur, "has_epuap", false)
    uses_banking_api := object.get(input.jdg_entrepreneur, "banking_psd2_enabled", false)
    manual_processes_count := object.get(input.jdg_entrepreneur, "manual_processes_count", 5)

    ksef_ready := uses_ksef
    epuap_active := has_epuap
    automation_pct := 0.20 { uses_ksef }
    automation_pct := automation_pct + 0.15 { has_epuap }
    automation_pct := automation_pct + 0.10 { uses_banking_api }

    digital_steps := []
    digital_steps := array.concat(digital_steps, ["Wdróż KSeF do fakturowania"]) { not uses_ksef }
    digital_steps := array.concat(digital_steps, ["Aktywuj ePUAP/e-Doreczenia"]) { not has_epuap }
    digital_steps := array.concat(digital_steps, ["Podłącz PSD2 API bankowe"]) { not uses_banking_api }
    digital_steps := array.concat(digital_steps, ["Automatyzuj JPK_V7 i deklaracje"]) { manual_processes_count > 3 }

    dig_routing := "TRIAGE_QUEUE" { count(digital_steps) > 2 }
    dig_routing := "" { true }
    dig_reason := sprintf("%d krokow do pelnej cyfryzacji", [count(digital_steps)]) { count(digital_steps) > 0 }
    dig_reason := "" { true }
}

asset_value := 0
asset_type := "GENERAL"
depr_method := ""
can_one_time := false
rd_eligible := false
is_leasable := false
kup_qualifies := false
kus_qual := ""
kus_pct := 0
is_capex := false
one_time_info := ""
rd_info := ""
lease_info := ""
invest_strategy := ""
