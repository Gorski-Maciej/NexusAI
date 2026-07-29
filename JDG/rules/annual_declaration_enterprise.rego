# Annual Tax Declaration Engine (JDG Enterprise S11) - priority_range: 1900-1924

package jdg.annual_declaration

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.annual_decl.no_match",
    "package": "jdg.annual_declaration", "priority": 9999
}

# ── Helpers: tax logic ───────────────────────────────────────────────────────

compute_tax_free_amount(taxable, free_base, free_reduction) = free_base { taxable <= free_base }
else = free_base - free_reduction { taxable > free_base; taxable <= 120000 }
else = 0 { taxable > 120000 }

compute_pit_bracket(income, threshold) = "12%" { income <= threshold }
else = "32%" { income > threshold }

child_relief_amount(num, disabled) = 1112.04 * num { disabled == false }
else = 2224.08 { num >= 2; disabled }

internet_relief_amount(costs, uses) = min([costs, 760]) { uses }
else = 0 { not uses }

rehab_relief_amount(costs, taxable) = min([costs, 2280]) { taxable <= 120000 }
else = 0 { taxable > 120000 }

ip_box_savings_amount(income, uses) = income * 0.14 { uses; income > 0 }
else = 0 { not uses }

rd_relief_amount(qualified, has) = qualified { has }
else = 0 { not has }

expansion_relief_amount(costs, has) = min([costs, 1000000]) { has }
else = 0 { not has }

prototype_relief_amount(costs, has) = costs * 0.30 { has }
else = 0 { not has }

robotization_relief_amount(costs, has) = costs * 0.50 { has }
else = 0 { not has }

overpayment_amount(advances, tax) = advances - tax { advances > tax }
else = 0 { advances <= tax }

underpayment_amount(advances, tax) = tax - advances { tax > advances }
else = 0 { tax <= advances }

joint_tax_amount(half, threshold) = half * 0.12 * 2 { half <= threshold }
else = (threshold * 0.12 + (half - threshold) * 0.32) * 2 { half > threshold }

tax_scale_amount(income, threshold) = income * 0.12 { income <= threshold }
else = threshold * 0.12 + (income - threshold) * 0.32 { income > threshold }

health_lump_amount(revenue, avg_wage) = floor(avg_wage * 0.60 * 0.09 * 100) / 100 * 12 { revenue <= 60000 }
else = floor(avg_wage * 1.00 * 0.09 * 100) / 100 * 12 { revenue <= 300000 }
else = floor(avg_wage * 1.80 * 0.09 * 100) / 100 * 12 { revenue > 300000 }

# ── Helpers: routing ─────────────────────────────────────────────────────────

routing_decision_triage(flag_active, threshold_val) = "TRIAGE_QUEUE" { flag_active; threshold_val > 10000 }
else = "" { threshold_val <= 10000 }

routing_decision_block(flag_active) = "BLOCK_AND_ALERT" { flag_active }
else = "" { not flag_active }

variance_pct_value(variance, base) = variance / base * 100 { base > 0 }
else = 0 { base == 0 }

reconciliation_status(variance) = "ZGODNE" { variance >= -500; variance <= 500 }
else = "NADPŁATA" { variance < -500 }
else = "NIEDOPŁATA" { variance > 500 }

# ═══════════════════════════════════════════════════════════════════════════════
# ADE-1900: PIT-36 COMPLETE AUTO-FILL
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.annual_decl.pit36_full_autofill",
    "package": "jdg.annual_declaration",
    "priority": 1900,
    "vat_rate": "", "rounding_level": "PLN", "gtu_code": "",
    "pit_form": "PIT_SCALE", "pit_rate": "12%/32%",
    "pit_bracket": income_bracket, "pit_annual_return_type": "PIT-36",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_path, "zus_health_rate": "0.09",
    "business_status": business_status, "ceidg_registration_required": false,
    "decl_pit36_total_income": total_income,
    "decl_pit36_total_costs": total_costs,
    "decl_pit36_taxable_income": taxable_income,
    "decl_pit36_tax_free_amount": tax_free_applied,
    "decl_pit36_tax_due": tax_due,
    "decl_pit36_health_contributions": health_total,
    "decl_pit36_social_contributions": social_total,
    "decl_pit36_tax_after_health": tax_after_health,
    "decl_pit36_advances_paid": advances_paid,
    "decl_pit36_overpayment": overpayment,
    "decl_pit36_underpayment": underpayment,
    "decl_pit36_reliefs_total": reliefs_total,
    "decl_pit36_joint_filing_savings": joint_savings,
    "decl_pit36_joint_filing_recommended": joint_recommended,
    "_routing": decl_routing,
    "_routing_reason": decl_routing_reason,
    "_legal_basis": "Art. 27, 27b, 45 PIT; Art. 26-30cb PIT; Art. 79-81 ustawy zdrowotnej",
    "_warnings": build_pit36_warnings(
        total_income, taxable_income, tax_due, health_total, tax_after_health,
        advances_paid, overpayment, underpayment, reliefs_total, joint_savings
    )
} {
    input.annual_declaration_requested == true
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"

    total_income := object.get(input.jdg_entrepreneur, "annual_gross_income", 180000)
    total_costs := object.get(input.jdg_entrepreneur, "annual_total_costs_kup", 50000)
    taxable_income := max([total_income - total_costs, 0])
    business_status := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE")
    zus_path := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")

    tax_free_base := 30000
    tax_free_reduction := min([(taxable_income - tax_free_base) * (tax_free_base / 90000), tax_free_base])
    tax_free_applied := compute_tax_free_amount(taxable_income, tax_free_base, tax_free_reduction)

    income_after_free := max([taxable_income - tax_free_applied, 0])
    scale_threshold := object.get(object.get(data.thresholds, "pit", {}), "scale_threshold", 120000)
    scale_low_part := min([income_after_free, scale_threshold])
    scale_high_part := max([income_after_free - scale_threshold, 0])
    tax_due := scale_low_part * 0.12 + scale_high_part * 0.32
    income_bracket := compute_pit_bracket(income_after_free, scale_threshold)

    social_total := object.get(input.jdg_entrepreneur, "annual_zus_social_paid", 18000)
    health_total := object.get(input.jdg_entrepreneur, "annual_health_contributions_paid", 10000)
    tax_after_health := tax_due

    has_child := object.get(input.jdg_entrepreneur, "has_children_under_18", false)
    num_children := object.get(input.jdg_entrepreneur, "num_children", 0)
    has_disabled_child := object.get(input.jdg_entrepreneur, "has_disabled_child", false)
    uses_internet_relief := object.get(input.jdg_entrepreneur, "uses_internet_relief", false)
    internet_costs := object.get(input.jdg_entrepreneur, "internet_costs_annual", 0)
    ikze_contributions := object.get(input.jdg_entrepreneur, "ikze_contributions_annual", 0)
    donations_org := object.get(input.jdg_entrepreneur, "donations_to_pozar_annual", 0)
    donations_blood := object.get(input.jdg_entrepreneur, "blood_donation_equivalent", 0)
    thermo_costs := object.get(input.jdg_entrepreneur, "thermo_modernization_costs", 0)
    rehab_costs := object.get(input.jdg_entrepreneur, "rehabilitation_costs", 0)
    uses_ip_box := object.get(input.jdg_entrepreneur, "uses_ip_box", false)
    ip_box_income := object.get(input.jdg_entrepreneur, "ip_box_qualifying_income", 0)
    has_rd_costs := object.get(input.jdg_entrepreneur, "has_rd_costs", false)
    rd_qualified := object.get(input.jdg_entrepreneur, "rd_qualified_costs", 0)
    has_expansion_costs := object.get(input.jdg_entrepreneur, "has_foreign_expansion_costs", false)
    expansion_costs := object.get(input.jdg_entrepreneur, "expansion_costs", 0)
    has_prototype_costs := object.get(input.jdg_entrepreneur, "has_prototype_costs", false)
    prototype_costs := object.get(input.jdg_entrepreneur, "prototype_costs", 0)
    has_robotization := object.get(input.jdg_entrepreneur, "has_robotization_costs", false)
    robotization_costs := object.get(input.jdg_entrepreneur, "robotization_costs", 0)

    child_relief := child_relief_amount(num_children, has_disabled_child)
    internet_relief := internet_relief_amount(internet_costs, uses_internet_relief)
    ikze_limit := min([taxable_income * 1.2, 25140])
    ikze_relief := min([ikze_contributions, ikze_limit])
    donations_total := donations_org + donations_blood
    donations_limit := taxable_income * 0.06
    donations_relief := min([donations_total, donations_limit])
    thermo_relief := min([thermo_costs, 53000])
    rehab_relief := rehab_relief_amount(rehab_costs, taxable_income)
    ip_box_savings := ip_box_savings_amount(ip_box_income, uses_ip_box)
    rd_relief := rd_relief_amount(rd_qualified, has_rd_costs)
    expansion_relief := expansion_relief_amount(expansion_costs, has_expansion_costs)
    prototype_relief := prototype_relief_amount(prototype_costs, has_prototype_costs)
    robotization_relief := robotization_relief_amount(robotization_costs, has_robotization)

    reliefs_total := child_relief + internet_relief + ikze_relief +
                     donations_relief + thermo_relief + rehab_relief +
                     rd_relief + expansion_relief + prototype_relief +
                     robotization_relief

    tax_after_reliefs := max([tax_after_health - reliefs_total, 0])
    final_tax := tax_after_reliefs

    advances_paid := object.get(input.jdg_entrepreneur, "monthly_advances_total_paid", 0)
    overpayment := overpayment_amount(advances_paid, final_tax)
    underpayment := underpayment_amount(advances_paid, final_tax)

    spouse_income := object.get(input.jdg_entrepreneur, "spouse_annual_taxable", 0)
    files_jointly := object.get(input.jdg_entrepreneur, "files_jointly_with_spouse", false)
    joint_total := (taxable_income + spouse_income) / 2
    joint_tax := joint_tax_amount(joint_total, scale_threshold)
    separate_tax := tax_scale_amount(taxable_income, scale_threshold) + tax_scale_amount(spouse_income, scale_threshold)
    joint_savings := separate_tax - joint_tax
    joint_recommended := joint_savings > 1000; not files_jointly

    decl_routing := "TRIAGE_QUEUE"
    decl_routing_reason := sprintf("PIT-36: niedoplata %.0f PLN", [underpayment])
}

build_pit36_warnings(income, taxable, tax, health, after_health, advances, over, under, reliefs, joint_save) = warnings {
    lines := [
        "PIT-36 — ROCZNE ZESTAWIENIE (AUTO-FILL)",
        sprintf("   Przychod brutto:       %12.0f PLN", [income]),
        sprintf("   Koszty KUP:            %12.0f PLN", [income - taxable]),
        sprintf("   Dochod do opodatkowania: %10.0f PLN", [taxable]),
        sprintf("   Podatek nalezny:       %12.0f PLN", [tax]),
        sprintf("   Skladka zdrowotna:     %12.0f PLN", [health]),
        sprintf("   Ulgi i odliczenia:     %12.0f PLN", [reliefs]),
        sprintf("   Zaliczki zaplacone:    %12.0f PLN", [advances]),
        sprintf("   NADPLATA:           %12.0f PLN", [over]),
        sprintf("   NIEDOPLATA:         %12.0f PLN", [under]),
        "",
        "TERMIN ZLOZENIA: 30 kwietnia 2027 r. przez e-Deklaracje",
    ]
    warnings := lines
}

# ═══════════════════════════════════════════════════════════════════════════════
# ADE-1905: PIT-36L COMPLETE AUTO-FILL
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.annual_decl.pit36l_full_autofill",
    "package": "jdg.annual_declaration",
    "priority": 1905,
    "vat_rate": "", "rounding_level": "PLN", "gtu_code": "",
    "pit_form": "LINEAR", "pit_rate": "19%",
    "pit_bracket": "", "pit_annual_return_type": "PIT-36L",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_path, "zus_health_rate": "0.049",
    "business_status": business_status, "ceidg_registration_required": false,
    "decl_pit36l_total_income": total_income,
    "decl_pit36l_total_costs": total_costs,
    "decl_pit36l_taxable_income": taxable_income,
    "decl_pit36l_tax_due": tax_due,
    "decl_pit36l_health_deductible": health_deductible,
    "decl_pit36l_health_contributions": health_total,
    "decl_pit36l_social_deductible": social_deductible,
    "decl_pit36l_tax_after_deductions": tax_after_deductions,
    "decl_pit36l_advances_paid": advances_paid,
    "decl_pit36l_overpayment": overpayment,
    "decl_pit36l_underpayment": underpayment,
    "decl_pit36l_ip_box_eligible": ip_box_eligible,
    "decl_pit36l_reliefs_total": reliefs_total,
    "_routing": lin_routing,
    "_routing_reason": lin_routing_reason,
    "_legal_basis": "Art. 30c, 45 PIT; Art. 30ca PIT; Art. 26 ust. 1 pkt 2 PIT",
    "_warnings": build_pit36l_warnings(
        total_income, taxable_income, tax_due, health_deductible,
        health_total, tax_after_deductions, advances_paid, overpayment,
        underpayment, reliefs_total
    )
} {
    input.annual_declaration_requested == true
    input.jdg_entrepreneur.tax_form == "LINEAR"

    total_income := object.get(input.jdg_entrepreneur, "annual_gross_income", 180000)
    total_costs := object.get(input.jdg_entrepreneur, "annual_total_costs_kup", 50000)
    taxable_income := max([total_income - total_costs, 0])
    business_status := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE")
    zus_path := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")

    tax_due := taxable_income * 0.19
    health_total := object.get(input.jdg_entrepreneur, "annual_health_contributions_paid", 6000)
    health_deductible := min([health_total, data.jdg.thresholds.limits.health_linear_deduction_limit])
    social_deductible := object.get(input.jdg_entrepreneur, "annual_zus_social_paid", 18000)

    has_rd_costs := object.get(input.jdg_entrepreneur, "has_rd_costs", false)
    rd_qualified := object.get(input.jdg_entrepreneur, "rd_qualified_costs", 0)
    ikze_contributions := object.get(input.jdg_entrepreneur, "ikze_contributions_annual", 0)
    uses_ip_box := object.get(input.jdg_entrepreneur, "uses_ip_box", false)
    ip_box_income := object.get(input.jdg_entrepreneur, "ip_box_qualifying_income", 0)

    income_after_social := max([taxable_income - social_deductible, 0])
    rd_relief := rd_relief_amount(rd_qualified, has_rd_costs)
    ikze_relief := min([ikze_contributions, income_after_social * 1.2])
    ip_box_eligible := uses_ip_box; ip_box_income > 0
    reliefs_total := rd_relief + ikze_relief

    tax_after_deductions := max([tax_due - reliefs_total - health_deductible, 0])
    advances_paid := object.get(input.jdg_entrepreneur, "monthly_advances_total_paid", 0)
    overpayment := overpayment_amount(advances_paid, tax_after_deductions)
    underpayment := underpayment_amount(advances_paid, tax_after_deductions)

    lin_routing := "TRIAGE_QUEUE"
    lin_routing_reason := sprintf("PIT-36L: niedoplata %.0f PLN", [underpayment])
}

build_pit36l_warnings(income, taxable, tax, health_ded, health, final, advances, over, under, reliefs) = warnings {
    lines := [
        "PIT-36L — PODATEK LINIOWY (AUTO-FILL)",
        sprintf("   Przychod:              %12.0f PLN", [income]),
        sprintf("   Koszty KUP:            %12.0f PLN", [income - taxable]),
        sprintf("   Dochod:                %12.0f PLN", [taxable]),
        sprintf("   Podatek 19%%:           %12.0f PLN", [tax]),
        sprintf("   Odliczenie zdrowotna:  %12.0f PLN", [health_ded]),
        sprintf("   Ulgi:                  %12.0f PLN", [reliefs]),
        sprintf("   PODATEK KONCOWY:       %12.0f PLN", [final]),
        sprintf("   Zaliczki zaplacone:    %12.0f PLN", [advances]),
        sprintf("   NADPLATA:           %12.0f PLN", [over]),
        sprintf("   NIEDOPLATA:         %12.0f PLN", [under]),
        "TERMIN: 30 kwietnia 2027 r. (PIT-36L przez e-Deklaracje)",
    ]
    warnings := lines
}

# ═══════════════════════════════════════════════════════════════════════════════
# ADE-1910: PIT-28 COMPLETE AUTO-FILL
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.annual_decl.pit28_full_autofill",
    "package": "jdg.annual_declaration",
    "priority": 1910,
    "vat_rate": "", "rounding_level": "PLN", "gtu_code": "",
    "pit_form": "LUMP_SUM", "pit_rate": lump_rate_str,
    "pit_bracket": "", "pit_annual_return_type": "PIT-28",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_path, "zus_health_rate": "3 progi (60%/100%/180% avg)",
    "business_status": business_status, "ceidg_registration_required": false,
    "decl_pit28_total_revenue": total_revenue,
    "decl_pit28_tax_rate": lump_rate,
    "decl_pit28_tax_due": tax_due,
    "decl_pit28_health_contributions": health_total,
    "decl_pit28_health_deductible": health_deductible,
    "decl_pit28_social_contributions": social_total,
    "decl_pit28_tax_after_deductions": tax_final,
    "decl_pit28_advances_paid": advances_paid,
    "decl_pit28_overpayment": overpayment,
    "decl_pit28_underpayment": underpayment,
    "decl_pit28_reliefs_total": reliefs_total,
    "decl_pit28_revenue_by_rate": {},
    "_routing": lump_routing,
    "_routing_reason": lump_routing_reason,
    "_legal_basis": "Art. 6-8, 21 ustawy o ryczalcie; Art. 45 ust. 1a PIT",
    "_warnings": build_pit28_warnings(
        total_revenue, lump_rate, tax_due, health_total, health_deductible,
        tax_final, advances_paid, overpayment, underpayment
    )
} {
    input.annual_declaration_requested == true
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"

    total_revenue := object.get(input.jdg_entrepreneur, "annual_revenue", 200000)
    business_status := object.get(input.jdg_entrepreneur, "business_status", "ACTIVE")
    zus_path := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    business_type := object.get(input.jdg_entrepreneur, "business_type", "SERVICES")

    lump_rates_map := {
        "SERVICES": 0.15, "IT": 0.12, "CONSULTING": 0.17,
        "TRADING": 0.03, "CONSTRUCTION": 0.055, "TRANSPORT": 0.055,
        "MANUFACTURING": 0.055, "RENTAL": 0.085, "MEDICAL": 0.14,
        "LEGAL": 0.17, "EDUCATION": 0.085, "ARTISTIC": 0.085,
        "GAMBLING": 0.15, "PHARMACY": 0.14
    }
    lump_rate := object.get(lump_rates_map, business_type, 0.15)
    lump_rate_str := sprintf("%.0f%%", [lump_rate * 100])
    tax_due := total_revenue * lump_rate

    avg_wage := object.get(object.get(data.thresholds, "bounds", {}), "average_wage", 8000)
    health_total := health_lump_amount(total_revenue, avg_wage)
    health_deductible := floor(health_total * 0.50 * 100) / 100

    social_total := object.get(input.jdg_entrepreneur, "annual_zus_social_paid", 18000)

    ikze_contributions := object.get(input.jdg_entrepreneur, "ikze_contributions_annual", 0)
    donations_total := object.get(input.jdg_entrepreneur, "donations_to_pozar_annual", 0)
    thermo_costs := object.get(input.jdg_entrepreneur, "thermo_modernization_costs", 0)

    ikze_relief := min([ikze_contributions, total_revenue * 0.015])
    donations_relief := min([donations_total, total_revenue * 0.06])
    thermo_relief := min([thermo_costs, 53000])
    reliefs_total := ikze_relief + donations_relief + thermo_relief

    tax_final := max([tax_due - health_deductible - social_total - reliefs_total, 0])

    advances_paid := object.get(input.jdg_entrepreneur, "monthly_advances_total_paid", 0)
    overpayment := overpayment_amount(advances_paid, tax_final)
    underpayment := underpayment_amount(advances_paid, tax_final)

    lump_routing := "TRIAGE_QUEUE"
    lump_routing_reason := sprintf("PIT-28: niedoplata %.0f PLN", [underpayment])
}

build_pit28_warnings(revenue, rate, tax, health, health_ded, final, advances, over, under) = warnings {
    lines := [
        "PIT-28 — RYCZALT OD PRZYCHODOW (AUTO-FILL)",
        sprintf("   Przychod:              %12.0f PLN", [revenue]),
        sprintf("   Stawka:                %12.0f%%", [rate * 100]),
        sprintf("   Podatek ryczaltowy:    %12.0f PLN", [tax]),
        sprintf("   Skladka zdrowotna:     %12.0f PLN", [health]),
        sprintf("   Odliczenie 50%% zdrow.: %12.0f PLN", [health_ded]),
        sprintf("   PODATEK KONCOWY:       %12.0f PLN", [final]),
        sprintf("   Zaliczki zaplacone:    %12.0f PLN", [advances]),
        sprintf("   NADPLATA:           %12.0f PLN", [over]),
        sprintf("   NIEDOPLATA:         %12.0f PLN", [under]),
        "TERMIN: 28 lutego 2027 r. (PIT-28 — wczesniejszy termin!)",
    ]
    warnings := lines
}

# ═══════════════════════════════════════════════════════════════════════════════
# ADE-1915: ADVANCE RECONCILIATION
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.annual_decl.advance_reconciliation",
    "package": "jdg.annual_declaration",
    "priority": 1915,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "decl_monthly_advances": monthly_advances,
    "decl_total_advances": total_advances,
    "decl_annual_tax_due": annual_tax,
    "decl_reconciliation_status": rec_status,
    "decl_variance_pln": variance,
    "decl_variance_pct": variance_pct,
    "decl_requires_correction_months": [],
    "_routing": rec_routing,
    "_routing_reason": rec_routing_reason,
    "_legal_basis": "Art. 44 ust. 1-6 PIT; Art. 45 ust. 6 PIT",
    "_warnings": build_reconciliation_warnings(
        total_advances, annual_tax, rec_status, variance, []
    )
} {
    input.annual_declaration_reconciliation == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")

    monthly_advances := object.get(input.jdg_entrepreneur, "monthly_advance_history", {})
    total_advances := 0
    annual_tax := object.get(input.jdg_entrepreneur, "annual_tax_calculated", total_advances)

    variance := annual_tax - total_advances
    variance_pct := variance_pct_value(variance, annual_tax)
    rec_status := reconciliation_status(variance)

    rec_routing := "TRIAGE_QUEUE"
    rec_routing_reason := sprintf("UZGODNIENIE: %s (%.0f PLN).", [rec_status, variance])
}

build_reconciliation_warnings(advances, annual, status, variance, corrections) = warnings {
    lines := [
        "UZGODNIENIE ZALICZEK vs DEKLARACJA ROCZNA",
        sprintf("   Suma zaliczek:         %12.0f PLN", [advances]),
        sprintf("   Podatek roczny:        %12.0f PLN", [annual]),
        sprintf("   Roznica:               %12.0f PLN", [variance]),
        sprintf("   Status:                %s", [status]),
        "Sprawdz poprawnosc miesiecznych zaliczek jesli roznica > 5000 PLN.",
    ]
    warnings := lines
}

# ═══════════════════════════════════════════════════════════════════════════════
# ADE-1920: JOINT FILING OPTIMIZATION
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.annual_decl.joint_filing_optimizer",
    "package": "jdg.annual_declaration",
    "priority": 1920,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "PIT_SCALE", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "PIT-36",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "decl_spouse_income": spouse_income,
    "decl_entrepreneur_income": entrepreneur_income,
    "decl_joint_total_income": joint_total,
    "decl_joint_tax": joint_tax,
    "decl_separate_tax_total": separate_tax,
    "decl_joint_vs_separate_savings": joint_savings,
    "decl_joint_recommended": joint_recommended,
    "decl_joint_benefits": joint_benefits,
    "decl_joint_restrictions": joint_restrictions,
    "_routing": joint_routing,
    "_routing_reason": joint_routing_reason,
    "_legal_basis": "Art. 6 ust. 2 PIT; Art. 27 PIT",
    "_warnings": build_joint_filing_warnings(
        spouse_income, entrepreneur_income, joint_tax, separate_tax,
        joint_savings, joint_recommended, joint_restrictions
    )
} {
    input.annual_declaration_joint_filing == true
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"

    entrepreneur_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 80000)
    spouse_income := object.get(input.jdg_entrepreneur, "spouse_annual_taxable", 30000)
    spouse_has_jdg := object.get(input.jdg_entrepreneur, "spouse_has_jdg", false)
    spouse_form := object.get(input.jdg_entrepreneur, "spouse_tax_form", "PIT_SCALE")
    files_jointly_already := object.get(input.jdg_entrepreneur, "files_jointly_with_spouse", false)

    scale_threshold := object.get(object.get(data.thresholds, "pit", {}), "scale_threshold", 120000)

    separate_tax := tax_scale_amount(entrepreneur_income, scale_threshold) + tax_scale_amount(spouse_income, scale_threshold)
    joint_total := entrepreneur_income + spouse_income
    joint_tax := joint_tax_amount(joint_total / 2, scale_threshold)
    joint_savings := separate_tax - joint_tax
    joint_recommended := joint_savings > 1000; not files_jointly_already

    joint_benefits := [
        "Kwota wolna 30k PLN x 2",
        "Nizszy prog 32%%",
        "Ulga na dziecko"
    ]

    joint_restrictions := ["Wspolne rozliczenie tylko do 30 kwietnia"]

    joint_routing := "TRIAGE_QUEUE"
    joint_routing_reason := sprintf("WSPOLNE ROZLICZENIE oszczedza %.0f PLN!", [joint_savings])
}

build_joint_filing_warnings(spouse, entrep, joint, separate, savings, recommended, restrictions) = warnings {
    lines := [
        "WSPOLNE ROZLICZENIE MALZONKOW — PIT-36",
        sprintf("   Dochod JDG:            %12.0f PLN", [entrep]),
        sprintf("   Dochod malzonka:       %12.0f PLN", [spouse]),
        sprintf("   Podatek OSOBNO:        %12.0f PLN", [separate]),
        sprintf("   Podatek RAZEM:         %12.0f PLN", [joint]),
        sprintf("   OSZCZEDNOSC:        %12.0f PLN", [savings]),
        "REKOMENDACJA: Zloz PIT-36 wspolnie z malzonkiem!",
        "Termin: 30 kwietnia 2027 r.",
    ]
    rest_lines := [sprintf("   UWAGA: %s", [r]) | r := restrictions[_]]
    all := array.concat(lines, rest_lines)
    warnings := all
}

# ═══════════════════════════════════════════════════════════════════════════════
# ADE-1922: RELIEF CROSS-VALIDATION
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.annual_decl.relief_cross_validation",
    "package": "jdg.annual_declaration",
    "priority": 1922,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "decl_relief_conflicts": conflicts,
    "decl_relief_conflict_count": count(conflicts),
    "decl_relief_valid_reliefs": valid_reliefs,
    "decl_relief_optimization_order": optimal_order,
    "_routing": conf_routing,
    "_routing_reason": conf_routing_reason,
    "_legal_basis": "Art. 26-30cb PIT; Art. 18d-18dc CIT",
    "_warnings": build_relief_validation_warnings(conflicts, valid_reliefs)
} {
    input.annual_declaration_reliefs == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    uses_ip_box := object.get(input.jdg_entrepreneur, "uses_ip_box", false)
    has_rd_costs := object.get(input.jdg_entrepreneur, "has_rd_costs", false)
    uses_internet := object.get(input.jdg_entrepreneur, "uses_internet_relief", false)
    internet_years_used := object.get(input.jdg_entrepreneur, "internet_relief_years_used", 2)

    conflicts := ["KONFLIKT IP Box vs B+R", "Ulga internetowa: limit 2 lat", "IP Box niedostepny na ryczalcie"]

    valid_reliefs := ["Ulga na dziecko", "IKZE", "Darowizny", "Termomodernizacja", "Rehabilitacyjna", "B+R", "IP Box", "Ekspansja", "Prototyp", "Robotyzacja"]

    optimal_order := [
        "1. Skladki spoleczne ZUS (od dochodu)",
        "2. Ulgi limitowane kwotowo: IKZE, darowizny, termo, internet, rehabilitacja",
        "3. Ulga B+R (od dochodu — NIE od podatku!)",
        "4. IP Box (osobno — PIT/IP, 5% stawka)",
        "5. Skladka zdrowotna (od podatku — tylko liniowy)"
    ]

    conf_routing := "TRIAGE_QUEUE"
    conf_routing_reason := concat("; ", conflicts)
}

build_relief_validation_warnings(conflicts, valid) = warnings {
    count(conflicts) > 0
    conf_lines := [sprintf("   %s", [c]) | c := conflicts[_]]
    valid_lines := [sprintf("   VALID: %s", [v]) | v := valid[_]]
    all := array.concat(
        array.concat(["WALIDACJA KRZYZOWA ULG:", "", "WYKRYTO KONFLIKTY:"], conf_lines),
        array.concat(["", "DOSTEPNE ULGI:"], valid_lines)
    )
    warnings := all
} else = ["Brak konfliktow ulg. Dostepnych ulg: %d.", count(valid)]
