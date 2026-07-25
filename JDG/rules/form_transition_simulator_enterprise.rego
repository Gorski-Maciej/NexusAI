# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE FORM TRANSITION SIMULATOR (Strategic Initiative S9)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Tax Form Transition Simulator — "What If" Engine
# description: |
#   ENTERPRISE v5.1 — Symulator zmiany formy opodatkowania JDG.
#   Odpowiada na pytanie: "Co by było gdybym przeszedł ze skali na liniowy?"
#   - Full comparison: skala vs liniowy vs ryczałt vs karta podatkowa
#   - Mid-year transition rules & deadlines (do 20. dnia miesiąca następującego)
#   - Health contribution impact per form (9% vs 4.9% vs 3 progi)
#   - ZUS interaction per form
#   - Transition lock-in periods & restrictions
#   - Loss of reliefs on transition
#   - Break-even analysis with visual threshold
#   Wypełnia lukę: najważniejsza decyzja JDG — wybór formy opodatkowania.
# architecture: Enterprise Simulation Engine, First-Match-Wins else-chain
# legal_basis: Art. 9a, 27, 30c PIT; Ustawa o ryczałcie; Ustawa o karcie podatkowej
# package: jdg.form_transition
# deprecated: false
# priority_range: 1750-1799
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.form_transition

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.form_transition.no_match",
    "package": "jdg.form_transition", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# FTS-1750: FULL FORM COMPARISON SIMULATION — Porównaj wszystkie formy
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.form_transition.full_comparison_simulation",
    "package": "jdg.form_transition",
    "priority": 1750,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": current_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "sim_current_form": current_form,
    "sim_recommended_form": recommended_form,
    "sim_scale_total_annual": scale_total,
    "sim_linear_total_annual": linear_total,
    "sim_lump_total_annual": lump_total,
    "sim_savings_vs_current": savings,
    "sim_savings_pct": savings_pct,
    "sim_transition_deadline": transition_deadline,
    "sim_transition_possible_now": can_transition_now,
    "_routing": trans_routing,
    "_routing_reason": trans_routing_reason,
    "_legal_basis": "Art. 9a ust. 1-5 PIT (zmiana formy); Art. 27, 30c, 30ca PIT",
    "_warnings": build_simulation_warnings(
        current_form, recommended_form, scale_total, linear_total, lump_total,
        savings, savings_pct, can_transition_now, transition_deadline
    )
} {
    input.simulate_form_transition == true

    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")

    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_projected", 180000)
    annual_costs := object.get(input.jdg_entrepreneur, "annual_costs_projected", 50000)
    annual_profit := annual_revenue - annual_costs

    business_type := object.get(input.jdg_entrepreneur, "business_type", "SERVICES")
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    is_eligible_tax_card := object.get(input.jdg_entrepreneur, "eligible_for_tax_card", false)
    uses_ip_box := object.get(input.jdg_entrepreneur, "uses_ip_box", false)

    # Exclusions from lump sum (ryczałt)
    lump_excluded_types := {"PHARMACY", "EXCHANGE", "GAMBLING", "FINANCIAL_INTERMEDIATION"}
    can_use_lump := not (business_type in lump_excluded_types)

    # Exclusions from tax card
    can_use_tax_card := is_eligible_tax_card and not has_employees and annual_revenue < 200000

    tax_free := object.get(object.get(data.thresholds, "pit", {}), "tax_free_amount", 30000)
    scale_threshold := object.get(object.get(data.thresholds, "pit", {}), "scale_threshold", 120000)

    # ══════════ SKALA PODATKOWA (12%/32%) ══════════
    scale_income_after_free := max([annual_profit - tax_free, 0])
    scale_low_part := min([scale_income_after_free, scale_threshold - tax_free])
    scale_tax_low := scale_low_part * 0.12
    scale_tax_high := max([annual_profit - scale_threshold, 0]) * 0.32
    scale_tax := scale_tax_low + scale_tax_high
    scale_health := annual_profit * 0.09
    scale_zus := object.get(input.jdg_entrepreneur, "annual_zus_total", 21600)
    scale_total := scale_tax + scale_health + scale_zus

    # ══════════ PODATEK LINIOWY (19%) ══════════
    linear_tax := annual_profit * 0.19
    linear_health := min([annual_profit * 0.049, 12900])
    linear_zus := object.get(input.jdg_entrepreneur, "annual_zus_total_linear", 21600)
    linear_total := linear_tax + linear_health + linear_zus

    # ══════════ RYCZAŁT ══════════
    lump_default_rates := {
        "SERVICES": 0.15,
        "IT": 0.12,
        "CONSULTING": 0.17,
        "TRADING": 0.03,
        "CONSTRUCTION": 0.055,
        "TRANSPORT": 0.055,
        "MANUFACTURING": 0.055,
        "RENTAL": 0.085,
        "MEDICAL": 0.14,
        "LEGAL": 0.17,
        "EDUCATION": 0.085
    }
    lump_rate := object.get(lump_default_rates, business_type, 0.15)
    lump_tax := annual_revenue * lump_rate

    avg_wage := object.get(object.get(data.thresholds, "bounds", {}), "average_wage", 8000)
    lump_health := 0
    lump_health := floor(avg_wage * 0.60 * 0.09 * 100) / 100 * 12 { annual_revenue <= 60000 }
    lump_health := floor(avg_wage * 1.00 * 0.09 * 100) / 100 * 12 { annual_revenue > 60000; annual_revenue <= 300000 }
    lump_health := floor(avg_wage * 1.80 * 0.09 * 100) / 100 * 12 { annual_revenue > 300000 }

    lump_deductible := floor(lump_health * 0.50 * 100) / 100
    lump_health_net := lump_health - lump_deductible
    lump_zus := object.get(input.jdg_entrepreneur, "annual_zus_total", 21600)
    lump_total := lump_tax + lump_health_net + lump_zus { can_use_lump }
    lump_total := 999999 { not can_use_lump }  # Ineligible — will not be chosen

    # ══════════ KARTA PODATKOWA ══════════
    tax_card_annual := 12000 { can_use_tax_card }  # Approximate average tax card rate
    tax_card_total := tax_card_annual + lump_health_net + lump_zus { can_use_tax_card }
    tax_card_total := 999999 { not can_use_tax_card }

    # ══════════ DETERMINE OPTIMAL FORM ══════════
    all_totals := {
        "PIT_SCALE": scale_total,
        "LINEAR": linear_total,
        "LUMP_SUM": lump_total,
        "TAX_CARD": tax_card_total
    }

    # Find minimum
    recommended_form := current_form
    min_total := scale_total

    recommended_form := "LINEAR" { linear_total < min_total }
    min_total := linear_total { linear_total < scale_total }

    recommended_form := "LUMP_SUM" { lump_total < min_total; can_use_lump }
    min_total := lump_total { lump_total < min_total; can_use_lump }

    recommended_form := "TAX_CARD" { tax_card_total < min_total; can_use_tax_card }

    current_total := object.get(all_totals, current_form, scale_total)
    optimal_total := object.get(all_totals, recommended_form, scale_total)
    savings := current_total - optimal_total
    savings_pct := savings / current_total * 100 { current_total > 0 }
    savings_pct := 0 { current_total == 0 }

    # ══════════ MID-YEAR TRANSITION RULES ══════════
    current_month := object.get(input, "current_month", 7)
    can_transition_now = true {
        current_form != recommended_form
        current_month <= 12
    } else = false

    # Transition deadline: do 20. dnia miesiąca następującego po miesiącu w którym
    # osiągnięto pierwszy przychód w nowym roku (dla zmiany od 1 stycznia)
    # Dla zmiany w trakcie roku: pismo do US + zaliczki wg nowej formy
    transition_deadline := sprintf("20.%02d.%d", [current_month + 1, 2026]) { can_transition_now }
    transition_deadline := "N/A (jesteś na optymalnej formie)" { current_form == recommended_form }

    trans_routing := ""
    trans_routing := "TRIAGE_QUEUE" { savings > 5000; can_transition_now }
    trans_routing_reason := ""
    trans_routing_reason := sprintf("OPTYMALIZACJA: zmiana %s→%s oszczędza %.0f PLN/rok (%.0f%%)", [current_form, recommended_form, savings, savings_pct]) { savings > 5000; can_transition_now }
    trans_routing_reason := "Jesteś na optymalnej formie opodatkowania" { current_form == recommended_form }
}

build_simulation_warnings(curr, reco, scale, linear, lump, savings, pct, can_change, deadline) = warnings {
    savings > 0
    form_names := {
        "PIT_SCALE": "Skala podatkowa (12%/32%)",
        "LINEAR": "Podatek liniowy (19%)",
        "LUMP_SUM": "Ryczałt od przychodów",
        "TAX_CARD": "Karta podatkowa"
    }

    curr_name := object.get(form_names, curr, "Nieznana")
    reco_name := object.get(form_names, reco, "Nieznana")

    comparison_lines := [
        sprintf("📊 SYMULACJA ZMIANY FORMY OPODATKOWANIA", []),
        sprintf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", []),
        sprintf("   Obecnie: %s — %.0f PLN/rok", [curr_name, object.get({"PIT_SCALE": scale, "LINEAR": linear, "LUMP_SUM": lump, "TAX_CARD": lump}, curr, scale)]),
        sprintf("   Optymalnie: %s — %.0f PLN/rok", [reco_name, object.get({"PIT_SCALE": scale, "LINEAR": linear, "LUMP_SUM": lump, "TAX_CARD": lump}, reco, scale)]),
        sprintf("   💰 Oszczędność: %.0f PLN/rok (%.0f%%)", [savings, pct]),
        sprintf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", []),
        "",
        "📊 PORÓWNANIE WSZYSTKICH FORM (rocznie):",
        sprintf("   Skala 12/32%%: %.0f PLN (podatek %.0f + zdrowotna %.0f + ZUS %.0f)", [scale, 0, 0, 0]),
        sprintf("   Liniowy 19%%:   %.0f PLN (podatek %.0f + zdrowotna %.0f + ZUS %.0f)", [linear, 0, 0, 0]),
        sprintf("   Ryczałt:        %.0f PLN", [lump])
    ]

    transition_info := [
        "",
        sprintf("⚠️ ZMIANA MOŻLIWA: %s", ["TAK" { can_change }, "NIE" { not can_change }][can_change == false]),
        sprintf("📅 TERMIN: %s", [deadline])
    ] { savings > 0 }

    restrictions := [
        "",
        "📋 WAŻNE OGRANICZENIA:",
        "   • Zmiana formy możliwa do 20. dnia miesiąca następującego po osiągnięciu pierwszego przychodu",
        "   • Przy zmianie na ryczałt: utrata prawa do odliczania KUP (kosztów)!",
        "   • Przy zmianie na skalę: zyskujesz kwotę wolną 30 000 PLN i ulgę na dziecko",
        "   • Przy zmianie na liniowy: brak kwoty wolnej i ulg rodzinnych, ale 4.9% zdrowotna z limitem",
        "   • IP Box (5%) dostępny przy skali i liniowym — NIE przy ryczałcie!",
        "   • Karta podatkowa — limit 200 000 PLN przychodu, brak pracowników",
        "   • Pisemne oświadczenie o zmianie formy do US (CEIDG-1 lub pismo)",
        "",
        "📌 REKOMENDACJA: Zmień formę od 1 stycznia — najprościej!"
    ]

    all_warnings := array.concat(comparison_lines, transition_info)
    all_warnings := array.concat(all_warnings, restrictions) { savings > 5000 }
    warnings := all_warnings
} else = [sprintf("✅ Jesteś na optymalnej formie opodatkowania (%s). Roczny koszt: %.0f PLN.", [curr_display, scale])] {
    curr_display := object.get({"PIT_SCALE": "Skala", "LINEAR": "Liniowy", "LUMP_SUM": "Ryczałt", "TAX_CARD": "Karta"}, curr, "Nieznana")
}

# ═══════════════════════════════════════════════════════════════════════════════
# FTS-1760: TRANSITION RESTRICTIONS CHECK — Sprawdzenie ograniczeń zmiany
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.form_transition.restrictions_check",
    "package": "jdg.form_transition",
    "priority": 1760,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": current_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "trans_eligible_for_target": target_possible,
    "trans_restrictions": restrictions,
    "trans_lockin_until": lockin_date,
    "_routing": restr_routing,
    "_routing_reason": restr_routing_reason,
    "_legal_basis": "Art. 9a ust. 1-5 PIT; Art. 6-8 ustawy o ryczałcie",
    "_warnings": build_restriction_warnings(target_possible, restrictions, lockin_date)
} {
    input.simulate_transition_restrictions == true

    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    target_form := object.get(input, "target_tax_form", "LINEAR")
    business_type := object.get(input.jdg_entrepreneur, "business_type", "SERVICES")
    is_first_year := object.get(input.jdg_entrepreneur, "is_first_year_of_business", false)
    changed_last_year := object.get(input.jdg_entrepreneur, "changed_form_last_year", false)
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    is_pharmacy := business_type == "PHARMACY"
    is_financial := business_type == "FINANCIAL_INTERMEDIATION"
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 180000)

    target_possible := true
    restrictions := []
    lockin_date := ""

    # Ryczałt exclusions
    lump_excluded := is_pharmacy or is_financial
    target_possible := false { target_form == "LUMP_SUM"; lump_excluded }
    restrictions := array.concat(restrictions, ["Branża wykluczona z ryczałtu (apteka/finanse)"]) { target_form == "LUMP_SUM"; lump_excluded }

    # Karta podatkowa exclusions
    target_possible := false { target_form == "TAX_CARD"; has_employees }
    restrictions := array.concat(restrictions, ["Karta podatkowa nie dla pracodawców"]) { target_form == "TAX_CARD"; has_employees }

    target_possible := false { target_form == "TAX_CARD"; annual_revenue > 200000 }
    restrictions := array.concat(restrictions, ["Limit 200k PLN dla karty podatkowej przekroczony"]) { target_form == "TAX_CARD"; annual_revenue > 200000 }

    # Can't change form if changed last year (lock-in)
    target_possible := false { changed_last_year }
    restrictions := array.concat(restrictions, ["Zmiana formy była już w poprzednim roku podatkowym — lock-in!"]) { changed_last_year }
    lockin_date := "2027-01-01" { changed_last_year }

    # IP Box requires scale or linear
    uses_ip_box := object.get(input.jdg_entrepreneur, "uses_ip_box", false)
    target_possible := false { target_form in {"LUMP_SUM", "TAX_CARD"}; uses_ip_box }
    restrictions := array.concat(restrictions, ["IP Box dostępny tylko przy skali i liniowym — utrata IP Box!"]) { target_form in {"LUMP_SUM", "TAX_CARD"}; uses_ip_box }

    restr_routing := ""
    restr_routing := "BLOCK_AND_ALERT" { not target_possible }
    restr_routing_reason := ""
    restr_routing_reason := concat("; ", restrictions) { not target_possible }
}

build_restriction_warnings(possible, rest, locked) = warnings {
    possible == true
    warnings := ["✅ Zmiana formy na wybraną jest możliwa — brak przeciwwskazań."]
} else = {
    rest_list := concat(", ", rest)
    locked_msg := ""
    locked_msg := sprintf("LOCK-IN do %s.", [locked]) { locked != "" }
    [sprintf("🔴 ZMIANA NIEMOŻLIWA: %s. %s", [rest_list, locked_msg])]
}

# ═══════════════════════════════════════════════════════════════════════════════
# FTS-1770: RELIEF LOSS CALCULATOR — Utrata ulg przy zmianie formy
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.form_transition.relief_loss_calculator",
    "package": "jdg.form_transition",
    "priority": 1770,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": target_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "trans_reliefs_lost": lost_reliefs,
    "trans_reliefs_lost_value_pln": lost_value,
    "trans_reliefs_kept": kept_reliefs,
    "_routing": loss_routing,
    "_routing_reason": loss_routing_reason,
    "_legal_basis": "Art. 26-30ca PIT; Art. 18d-18dc CIT",
    "_warnings": build_relief_loss_warnings(lost_reliefs, lost_value, kept_reliefs)
} {
    input.simulate_relief_loss == true

    target_form := object.get(input, "target_tax_form", "LINEAR")
    has_child := object.get(input.jdg_entrepreneur, "has_children_under_18", false)
    files_jointly := object.get(input.jdg_entrepreneur, "files_jointly_with_spouse", false)
    uses_ip_box := object.get(input.jdg_entrepreneur, "uses_ip_box", false)
    ip_box_income := object.get(input.jdg_entrepreneur, "ip_box_qualifying_income", 30000)

    lost_reliefs := []
    lost_value := 0
    kept_reliefs := []

    # Ulga na dziecko: tylko na skali
    has_child_relief := has_child
    lost_reliefs := array.concat(lost_reliefs, ["Ulga na dziecko (1112 PLN/rok/dziecko)"]) { target_form != "PIT_SCALE"; has_child_relief }
    lost_value := lost_value + 1112 { target_form != "PIT_SCALE"; has_child_relief }

    # Wspólne rozliczenie z małżonkiem: tylko na skali
    lost_reliefs := array.concat(lost_reliefs, ["Wspólne rozliczenie małżonków"]) { target_form != "PIT_SCALE"; files_jointly }
    lost_value := lost_value + 2000 { target_form != "PIT_SCALE"; files_jointly }  # Approximate

    # IP Box: skala i liniowy zachowują, ryczałt i karta tracą
    lost_reliefs := array.concat(lost_reliefs, [sprintf("IP Box (5%% na %.0f PLN dochodu = %.0f PLN oszczędności)", [ip_box_income, ip_box_income * 0.14])]) { target_form in {"LUMP_SUM", "TAX_CARD"}; uses_ip_box }
    lost_value := lost_value + ip_box_income * 0.14 { target_form in {"LUMP_SUM", "TAX_CARD"}; uses_ip_box }

    # Kwota wolna: tylko skala
    lost_reliefs := array.concat(lost_reliefs, ["Kwota wolna 30 000 PLN"]) { target_form != "PIT_SCALE" }
    lost_value := lost_value + 3600 { target_form != "PIT_SCALE" }  # 30k * 12% = 3600

    # Co zostaje przy każdej formie
    kept_reliefs := ["Ulga B+R", "Ulga na prototyp", "Ulga na ekspansję", "Ulga na robotyzację"] { target_form in {"PIT_SCALE", "LINEAR"} }
    kept_reliefs := ["Ulga IKZE", "Ulga związkowa"] { target_form == "LUMP_SUM" }

    loss_routing := ""
    loss_routing := "TRIAGE_QUEUE" { lost_value > 5000 }
    loss_routing_reason := ""
    loss_routing_reason := sprintf("Przy zmianie na %s tracisz ulgi o wartości %.0f PLN/rok!", [target_form, lost_value]) { lost_value > 5000 }
}

build_relief_loss_warnings(lost, value, kept) = warnings {
    count(lost) > 0
    lost_list := concat("\n      • ", lost)
    kept_list := concat("\n      • ", kept)

    warnings := [
        sprintf("⚠️ UTRATA ULG PRZY ZMIANIE FORMY — wartość: %.0f PLN/rok", [value]),
        sprintf("   TRACISZ: %s", [lost_list]),
        sprintf("   ZOSTAJE: %s", [kept_list]),
        "",
        "💡 Pamiętaj: oszczędność z niższej stawki może zrekompensować utratę ulg!",
        "📊 Porównaj całkowity koszt (podatek + utracone ulgi) przed decyzją."
    ]
} else = [sprintf("✅ Przy przejściu na %s zachowujesz wszystkie ulgi.", [""])]

# ═══════════════════════════════════════════════════════════════════════════════
# FTS-1775: JDG → SP. Z O.O. TRANSITION ANALYSIS — Analiza przekształcenia
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.form_transition.jdg_to_spzoo_analysis",
    "package": "jdg.form_transition",
    "priority": 1775,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": current_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "sim_transition_to_spzoo_recommended": spzoo_recommended,
    "sim_spzoo_jdg_annual_cost": jdg_annual,
    "sim_spzoo_spzoo_annual_cost": spzoo_annual,
    "sim_spzoo_breakeven_months": breakeven_months,
    "_routing": spzoo_routing,
    "_routing_reason": spzoo_reason,
    "_legal_basis": "Art. 551-584 KSH (przekształcenie); Art. 19 CIT; Art. 30c PIT",
    "_warnings": [
        sprintf("🏢 PRZEKSZTAŁCENIE JDG → SP. Z O.O.", []),
        sprintf("   JDG (obecnie): %.0f PLN/rok", [jdg_annual]),
        sprintf("   Sp. z o.o.: %.0f PLN/rok", [spzoo_annual]),
        sprintf("   💰 Oszczędność: %.0f PLN/rok", [jdg_annual - spzoo_annual]),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "✅ ZALETY: Ograniczona odpowiedzialność, CIT estoński 9%, łatwiejsza sprzedaż",
        "⚠️ WADY: Pełna księgowość, podwójne opodatkowanie, obowiązki KRS",
        "📋 KOSZTY DODATKOWE: księgowa ~500 PLN/mies, KRS ~3000 PLN/rok, ZUS zarządu ~1000 PLN/mies",
        sprintf("💡 %s", [spzoo_verdict])
    ]
} {
    input.simulate_spzoo_transition == true
    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    annual_profit := object.get(input.jdg_entrepreneur, "annual_profit_projected", 100000)
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)

    # JDG annual cost (simplified)
    pit_tax := annual_profit * 0.19 { current_form == "LINEAR" }
    pit_tax := annual_profit * 0.19 { current_form == "PIT_SCALE"; annual_profit > 120000 }
    pit_tax := max([annual_profit - 30000, 0]) * 0.12 { current_form == "PIT_SCALE"; annual_profit <= 120000 }
    health_jdg := annual_profit * 0.09 { current_form == "PIT_SCALE" }
    health_jdg := min([annual_profit * 0.049, 12900]) { current_form == "LINEAR" }
    zus_jdg := 21600
    jdg_annual := pit_tax + health_jdg + zus_jdg

    # Sp. z o.o. annual cost
    cit_estonski := not has_employees
    cit_tax := 0 { cit_estonski }
    cit_tax := annual_profit * 0.09 { not cit_estonski; annual_profit <= 2000000 }
    cit_tax := annual_profit * 0.19 { not cit_estonski; annual_profit > 2000000 }
    admin_cost := 21000
    spzoo_annual := cit_tax + admin_cost

    spzoo_recommended := jdg_annual > spzoo_annual + 15000
    annual_savings := jdg_annual - spzoo_annual
    breakeven_months := floor(21000 / max([annual_savings / 12, 1])) { annual_savings > 0 }
    breakeven_months := 99 { annual_savings <= 0 }

    spzoo_routing := "TRIAGE_QUEUE" { spzoo_recommended }
    spzoo_routing := "" { true }
    spzoo_reason := sprintf("Przekształcenie w Sp. z o.o. opłacalne — oszczędność %.0f PLN/rok", [jdg_annual - spzoo_annual]) { spzoo_recommended }
    spzoo_reason := "Pozostań na JDG" { true }
    spzoo_verdict := "PRZEKSZTAŁĆ — opłacalne finansowo" { spzoo_recommended }
    spzoo_verdict := "POZOSTAŃ NA JDG — obecna forma optymalna" { not spzoo_recommended }
}

# ═══════════════════════════════════════════════════════════════════════════════
# FTS-1780: HEALTH CONTRIBUTION IMPACT — Wpływ składki zdrowotnej per forma
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.form_transition.health_contribution_details",
    "package": "jdg.form_transition",
    "priority": 1780,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "trans_health_scale": health_scale,
    "trans_health_linear": health_linear,
    "trans_health_linear_deductible": health_linear_ded,
    "trans_health_lump": health_lump,
    "trans_health_lump_deductible": health_lump_ded,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 79-81 ustawy o świadczeniach zdrowotnych; Art. 30c ust. 2 PIT",
    "_warnings": [sprintf("🏥 SKŁADKA ZDROWOTNA per forma:\n   Skala: %.0f PLN (9%% od dochodu, BEZ odliczenia)\n   Liniowy: %.0f PLN (4.9%% od dochodu, odliczenie %.0f PLN = netto %.0f PLN)\n   Ryczałt: %.0f PLN (50%% podlega odliczeniu = netto %.0f PLN)", [health_scale, health_linear, health_linear_ded, health_linear - health_linear_ded, health_lump, health_lump - health_lump_ded])]
} {
    input.simulate_health_impact == true

    annual_profit := object.get(input.jdg_entrepreneur, "annual_profit_projected", 96000)
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_projected", 180000)
    avg_wage := object.get(object.get(data.thresholds, "bounds", {}), "average_wage", 8000)

    health_scale := annual_profit * 0.09

    health_linear := annual_profit * 0.049
    health_linear_ded := min([health_linear, 12900])

    health_lump := floor(avg_wage * 0.60 * 0.09 * 100) / 100 * 12 { annual_revenue <= 60000 }
    health_lump := floor(avg_wage * 1.00 * 0.09 * 100) / 100 * 12 { annual_revenue > 60000; annual_revenue <= 300000 }
    health_lump := floor(avg_wage * 1.80 * 0.09 * 100) / 100 * 12 { annual_revenue > 300000 }
    health_lump_ded := floor(health_lump * 0.50 * 100) / 100
}
