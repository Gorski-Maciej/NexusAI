# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE CROSS-DOMAIN INTELLIGENCE HUB (Strategic Initiative S2)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Cross-Domain Intelligence — VAT×PIT×ZUS×Cashflow Hub
# description: |
#   ENTERPRISE v5.0 — Centralny hub analizy między-domenowej.
#   Łączy decyzje z VAT, PIT, ZUS, cashflow i compliance w spójną
#   rekomendację dla przedsiębiorcy. Wykrywa efekty domina:
#   decyzja VAT wpływa na PIT → wpływa na ZUS → wpływa na cashflow.
#   Wykrywa pułapki podatkowe, ostrzega przed niebezpiecznymi
#   interakcjami między domenami, rekomenduje optymalną ścieżkę.
# architecture: Enterprise Hub, Post-Merge Cross-Domain Analysis
# legal_basis: Cross-domain (VAT, PIT, SUS, Ordynacja Podatkowa, KKS)
# package: jdg.cross_domain_hub
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.cross_domain_hub

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.cross_domain.no_match",
    "package": "jdg.cross_domain_hub", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# S2-200: VAT × PIT CROSS-DOMAIN DOMINO EFFECT — Efekt domina VAT→PIT
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.cross_domain.vat_pit_domino",
    "package": "jdg.cross_domain_hub",
    "priority": 200,
    "vat_rate": vat_rate, "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": kus_qual, "kus_percent": kus_pct,
    "zus_social_base_type": "", "zus_health_rate": "",
    "cross_domain_vat_impact_on_pit": vat_pit_impact,
    "cross_domain_vat_impact_on_zus": vat_zus_impact,
    "cross_domain_cashflow_60day_warning": cashflow_warning,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": routing_flag,
    "_routing_reason": routing_reason,
    "_legal_basis": "Art. 14 PIT (przychód netto), Art. 86 VAT (odliczenie), Art. 23 ust. 1 pkt 43 PIT (VAT naliczony jako KUP gdy brak odliczenia)",
    "_warnings": build_domino_warnings()
} {
    input.cross_domain_analysis == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    vat_rate := object.get(input.invoice, "vat_rate", "0.23")
    amount_net := object.get(input.invoice, "amount_net", 0)
    amount_vat := object.get(input.invoice, "amount_vat", 0)
    vat_deductible := object.get(input.invoice, "vat_deductible", true)
    is_invoice_cost := input.invoice.direction == "PURCHASE"
    uses_lump_sum := pit_form == "LUMP_SUM"
    scale_threshold := object.get(object.get(data.thresholds, "pit", {}), "scale_threshold", 120000)
    ytd_income := object.get(input.jdg_entrepreneur, "ytd_profit", 60000)

    # VAT → PIT domino: Odliczony VAT nie wchodzi w KUP. Nieodliczony VAT wchodzi w KUP.
    kus_pct := 100 { is_invoice_cost; vat_deductible }
    kus_pct := 100 { is_invoice_cost; not vat_deductible }  # Nieodliczony VAT też KUP
    kus_pct := 0 { not is_invoice_cost }
    kus_qual := "deductible_full" { is_invoice_cost }
    kus_qual := "non_deductible" { not is_invoice_cost }

    # VAT → ZUS domino: Wyższy przychód netto (przy sprzedaży) = wyższa podstawa ZUS
    vat_pit_impact := sprintf("VAT: %s%% od %.2f PLN netto = %.2f PLN VAT. %s", 
        [fmt_rate, amount_net, amount_vat, deduction_note])

    fmt_rate := sprintf("%.0f", [to_number(vat_rate) * 100])
    deduction_note := "VAT NALICZONY → odliczony → NIE wchodzi w KUP" { vat_deductible; is_invoice_cost }
    deduction_note := "VAT NALICZONY → NIEodliczony → wchodzi w KUP (Art. 23 ust. 1 pkt 43 PIT)" { not vat_deductible; is_invoice_cost }
    deduction_note := "VAT NALEŻNY → pomniejszony o VAT naliczony → neutralny dla dochodu" { not is_invoice_cost }

    vat_zus_impact := sprintf("Wpływ na podstawę ZUS: +%.2f PLN dochodu (netto) → +%.2f PLN składki zdrowotnej",
        [amount_net, amount_net * 0.09]) { not is_invoice_cost; pit_form == "PIT_SCALE" }
    vat_zus_impact := sprintf("Wpływ na podstawę ZUS: +%.2f PLN dochodu → +%.2f PLN składki (liniowy 4.9%%)",
        [amount_net, amount_net * 0.049]) { not is_invoice_cost; pit_form == "LINEAR" }
    vat_zus_impact := "Ryczałt: przychód bez kosztów, ale składka zdrowotna zależy od progu przychodu." { pit_form == "LUMP_SUM" }
    vat_zus_impact := "Faktura zakupowa — wpływa na KUP, nie bezpośrednio na ZUS." { is_invoice_cost }

    # Cashflow warning
    days_to_pay := object.get(input.invoice, "payment_days", 30)
    cashflow_warning := sprintf("⚠️ PŁYNNOŚĆ: Zapłacisz %.2f PLN brutto za %d dni. VAT (%.2f PLN) odzyskasz dopiero w deklaracji za ten miesiąc. LUKA KASOWA: %.2f PLN przez okres do zwrotu.",            [amount_net + amount_vat, days_to_pay, amount_vat, amount_vat])
    cashflow_warning := "" { not is_invoice_cost }
    cashflow_warning := "" { amount_vat <= 10000 }

    routing_flag := "TRIAGE_QUEUE" { amount_vat > 10000; pit_form == "PIT_SCALE"; ytd_income > scale_threshold * 0.80 }
    routing_flag := "" { true }
    routing_reason := "Duża faktura zbliża do 32% progu + znaczny VAT do odzyskania — rozważ optymalizację" { routing_flag == "TRIAGE_QUEUE" }
    routing_reason := "" { true }
}

build_domino_warnings() = [
    "🔗 EFEKT DOMINA: Ta faktura wpływa na 3 domeny: VAT, PIT, ZUS.",
    "📊 VAT → PIT: Odliczony VAT nie zwiększa KUP. Nieodliczony VAT → KUP (Art. 23 ust.1 pkt 43).",
    "🏥 VAT → ZUS: Wyższy dochód na fakturze sprzedaży = wyższa składka zdrowotna (skala: 9%, liniowy: 4.9%).",
    "💵 PŁYNNOŚĆ: Zapłata VAT należnego do 25. dnia miesiąca. Zwrot VAT naliczonego: 60 dni (standard) lub 25 dni (przyśpieszony)."
]

# ═══════════════════════════════════════════════════════════════════════════════
# S2-210: PIT × ZUS INTERLOCK — Blokada PIT→ZUS (Polski Ład)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_domain.pit_zus_interlock",
    "package": "jdg.cross_domain_hub",
    "priority": 210,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": pit_rate, "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": health_rate,
    "cross_domain_zus_deductible_from_pit": zus_deductible,
    "cross_domain_pit_health_paradox": health_paradox,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Polski Ład 2022; Art. 26 ust. 1 pkt 2 PIT; Art. 30c ust. 2 PIT; Art. 81 ustawy zdrowotnej",
    "_warnings": [sprintf("🔒 PIT × ZUS INTERLOCK — %s. Składki społeczne: %s. Składka zdrowotna: %s. %s.", 
        [form_info, social_info, health_info, paradox_warning])]
} {
    input.cross_domain_analysis == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    monthly_profit := object.get(input.jdg_entrepreneur, "monthly_profit_avg", 8000)
    min_wage := object.get(object.get(data.thresholds, "bounds", {}), "minimum_wage_gross", 4666)

    social_base := min_wage * 0.60
    social_monthly := floor(social_base * 0.3812 * 100) / 100 { zus_status == "STANDARD" }
    social_monthly := floor(min_wage * 0.30 * 0.3812 * 100) / 100 { zus_status == "PREFERENTIAL" }
    social_monthly := 0 { zus_status == "START_RELIEF" }

    form_info := sprintf("Forma: %s, ZUS: %s", [pit_form, zus_status])

    # Skala podatkowa: składki społeczne ODLICZANE od dochodu, zdrowotna NIEodliczana
    social_info := sprintf("Społeczne %.2f PLN ODLICZANE od dochodu", [social_monthly]) { pit_form == "PIT_SCALE" }
    social_info := sprintf("Społeczne %.2f PLN ODLICZANE od dochodu", [social_monthly]) { pit_form == "LINEAR" }
    social_info := "Społeczne: NIE dotyczy (ryczałt od przychodu)" { pit_form == "LUMP_SUM" }

    health_rate := "0.09" { pit_form == "PIT_SCALE" }
    health_rate := "0.049" { pit_form == "LINEAR" }
    health_rate := "progresywna" { pit_form == "LUMP_SUM" }

    health_monthly := monthly_profit * 0.09 { pit_form == "PIT_SCALE" }
    health_monthly := min([monthly_profit * 0.049, thresholds.limits.health_linear_deduction_limit / 12]) { pit_form == "LINEAR" }
    health_monthly := 419 { pit_form == "LUMP_SUM" }

    health_info := sprintf("Zdrowotna ~%.2f PLN/mies NIEODLICZALNA od PIT (Polski Ład)", [health_monthly]) { pit_form == "PIT_SCALE" }
    health_info := sprintf("Zdrowotna ~%.2f PLN/mies ODLICZALNA (max 12 900 PLN/rok)", [health_monthly]) { pit_form == "LINEAR" }
    health_info := sprintf("Zdrowotna ~%.2f PLN/mies, 50%% odliczalne", [health_monthly]) { pit_form == "LUMP_SUM" }

    zus_deductible := social_monthly * 12 { pit_form != "LUMP_SUM" }
    zus_deductible := 0 { pit_form == "LUMP_SUM" }

    # Health paradox: wyższy dochód = wyższa składka zdrowotna
    health_paradox := sprintf("PARADOKS ZDROWOTNY: %.0f PLN więcej dochodu = +%.2f PLN składki zdrowotnej na skali. Efektywna krańcowa stopa: %.1f%% (12%% PIT + 9%% zdrowotna = 21%%). Na liniowym: %.1f%% (19%% + 4.9%% = 23.9%%).",
        [1000, 90, 21.0, 23.9]) { monthly_profit > 5000 }

    paradox_warning := "" { true }
    paradox_warning := "⚠️ PARADOKS: Wyższy dochód = wyższa składka zdrowotna = wyższy koszt stały!" { pit_form == "PIT_SCALE"; monthly_profit > 10000 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S2-220: TAX TRAP DETECTOR — Wykrywanie pułapek podatkowych
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_domain.tax_trap_detector",
    "package": "jdg.cross_domain_hub",
    "priority": 220,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "cross_domain_active_traps": active_traps,
    "cross_domain_trap_severity": max_severity,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": trap_routing,
    "_routing_reason": trap_reason,
    "_legal_basis": "Cross-domain (VAT, PIT, SUS, KKS)",
    "_warnings": trap_warnings_list
} {
    input.cross_domain_analysis == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    monthly_revenue := object.get(input.jdg_entrepreneur, "monthly_revenue_avg", 15000)
    annual_revenue := monthly_revenue * 12
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    employee_count := object.get(input.jdg_entrepreneur, "employee_count", 0)
    is_vat_payer := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT") == "ACTIVE"
    last_year_revenue := object.get(input.jdg_entrepreneur, "last_year_revenue", 100000)
    has_mileage_log := object.get(input.jdg_entrepreneur, "vehicle_mileage_log_maintained", false)
    car_value := object.get(input.jdg_entrepreneur, "vehicle_value_pln", 0)

    active_traps := []
    trap_severities := []

    # TRAP 1: Mały ZUS Plus — przekroczenie limitu 120 000 PLN
    trap1 := has_trap("zus_maly_plus_limit", pit_form, annual_revenue, last_year_revenue)
    active_traps := array.concat(active_traps, ["TRAP_ZUS_MALY_PLUS_LIMIT"]) { trap1 }
    trap_severities := array.concat(trap_severities, [3]) { trap1 }

    # TRAP 2: Podatek liniowy — były pracodawca (Art. 30c ust. 2 PIT)
    trap2 := has_trap("linear_former_employer", pit_form, annual_revenue, last_year_revenue)
    active_traps := array.concat(active_traps, ["TRAP_LINEAR_FORMER_EMPLOYER"]) { trap2 }
    trap_severities := array.concat(trap_severities, [5]) { trap2 }

    # TRAP 3: Auto firmowe bez ewidencji przebiegu — utrata 25% KUP + 50% VAT
    trap3 := has_trap("car_no_mileage_log", pit_form, annual_revenue, last_year_revenue)
    active_traps := array.concat(active_traps, ["TRAP_CAR_NO_MILEAGE_LOG"]) { trap3 }
    trap_severities := array.concat(trap_severities, [4]) { trap3 }

    # TRAP 4: Próg 32% — nieświadome wejście w wyższy próg
    trap4 := has_trap("scale_32pct_threshold", pit_form, annual_revenue, last_year_revenue)
    active_traps := array.concat(active_traps, ["TRAP_SCALE_32PCT_THRESHOLD"]) { trap4 }
    trap_severities := array.concat(trap_severities, [4]) { trap4 }

    # TRAP 5: VAT — przekroczenie limitu zwolnienia 200k
    trap5 := has_trap("vat_exemption_limit_200k", pit_form, annual_revenue, last_year_revenue)
    active_traps := array.concat(active_traps, ["TRAP_VAT_EXEMPTION_LIMIT"]) { trap5 }
    trap_severities := array.concat(trap_severities, [5]) { trap5 }

    # TRAP 6: Zatrudnienie + JDG — zbieg ubezpieczeń
    trap6 := has_trap("employee_plus_jdg_zus", pit_form, annual_revenue, last_year_revenue)
    active_traps := array.concat(active_traps, ["TRAP_EMPLOYEE_JDG_ZUS"]) { trap6 }
    trap_severities := array.concat(trap_severities, [3]) { trap6 }

    max_severity := 0
    max_severity := 5 { count(trap_severities) > 0 }

    trap_routing := ""
    trap_routing := "BLOCK_AND_ALERT" { count(active_traps) > 0; max_severity >= 5 }
    trap_routing := "TRIAGE_QUEUE" { count(active_traps) > 0; max_severity < 5 }

    trap_reason := sprintf("Wykryto %d pułapek podatkowych!", [count(active_traps)]) { count(active_traps) > 0 }
    trap_reason := "" { true }

    trap_warnings_list := [
        sprintf("⚠️ PUŁAPKI PODATKOWE WYKRYTE: %d", [count(active_traps)])
    ]
    trap_warnings_list := array.concat(trap_warnings_list, [
        "🔴 Mały ZUS Plus: limit 120 000 PLN przychodu rocznie. Przekroczenie = powrót do pełnego ZUS (+~800 PLN/mies)."
    ]) { trap1 }
    trap_warnings_list := array.concat(trap_warnings_list, [
        "🔴 Podatek liniowy: NIE wolno świadczyć usług byłemu pracodawcy (Art. 30c ust. 2 PIT)! Kary + utrata liniowego."
    ]) { trap2 }
    trap_warnings_list := array.concat(trap_warnings_list, [
        sprintf("🟡 Auto %.0f PLN bez ewidencji przebiegu: KUP 75%% + VAT 50%%. Strata ~%.0f PLN/rok. Załóż ewidencję!", [car_value, car_value * 0.024])
    ]) { trap3 }
    trap_warnings_list := array.concat(trap_warnings_list, [
        sprintf("🟠 Próg 32%%: przy %.0f PLN dochodu rocznie wchodzisz w 32%% próg. Rozważ optymalizację!", [annual_revenue])
    ]) { trap4 }
    trap_warnings_list := array.concat(trap_warnings_list, [
        "🔴 VAT: przekroczenie 200k PLN = obowiązkowa rejestracja! Złóż VAT-R natychmiast."
    ]) { trap5 }
    trap_warnings_list := array.concat(trap_warnings_list, [
        "🟡 Etat + JDG: składki społeczne tylko z etatu, z JDG tylko ZDROWOTNA. Sprawdź czy nie płacisz podwójnie!"
    ]) { trap6 }
}

has_trap("zus_maly_plus_limit", _, annual_rev, last_year) = true {
    last_year > 110000
    annual_rev > 110000
}

has_trap("linear_former_employer", pit_form, _, _) = true {
    pit_form == "LINEAR"
}

has_trap("car_no_mileage_log", _, _, _) = true {
    not object.get(input.jdg_entrepreneur, "vehicle_mileage_log_maintained", true)
    car_value > 50000
}

has_trap("scale_32pct_threshold", pit_form, annual_rev, _) = true {
    pit_form == "PIT_SCALE"
    annual_rev > 110000
}

has_trap("vat_exemption_limit_200k", _, annual_rev, _) = true {
    object.get(input.jdg_entrepreneur, "vat_status", "ACTIVE") == "EXEMPT"
    annual_rev > 180000
}

has_trap("employee_plus_jdg_zus", _, _, _) = true {
    object.get(input.jdg_entrepreneur, "has_employment_contract", false)
}

# ═══════════════════════════════════════════════════════════════════════════════
# S2-230: MONTHLY HEALTH CHECK — Miesięczny przegląd finansowy JDG
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_domain.monthly_fiscal_health",
    "package": "jdg.cross_domain_hub",
    "priority": 230,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": zus_status, "zus_health_rate": health_rate,
    "cross_domain_fiscal_health_score": health_score,
    "cross_domain_monthly_deadlines": deadlines,
    "cross_domain_estimated_tax_pln": estimated_tax,
    "cross_domain_estimated_zus_pln": estimated_zus,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": health_routing,
    "_routing_reason": health_reason,
    "_legal_basis": "Art. 44 PIT, Art. 103 VAT, Art. 47 SUS",
    "_warnings": build_health_warnings(health_score, estimated_tax, estimated_zus)
} {
    input.cross_domain_monthly_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    monthly_revenue := object.get(input.jdg_entrepreneur, "monthly_revenue_avg", 15000)
    monthly_costs := object.get(input.jdg_entrepreneur, "monthly_costs_avg", 5000)
    monthly_profit := monthly_revenue - monthly_costs
    min_wage := object.get(object.get(data.thresholds, "bounds", {}), "minimum_wage_gross", 4666)

    # Estimated PIT advance
    pit_advance := max([monthly_profit * 0.12, 0]) { pit_form == "PIT_SCALE"; monthly_profit * 12 <= 120000 }
    pit_advance := monthly_profit * 0.19 { pit_form == "LINEAR" }
    pit_advance := monthly_revenue * 0.12 { pit_form == "LUMP_SUM" }
    estimated_tax := floor(pit_advance * 100) / 100

    # Estimated ZUS
    social_amount := floor(min_wage * 0.60 * 0.3812 * 100) / 100
    health_rate := "0.09" { pit_form == "PIT_SCALE" }
    health_rate := "0.049" { pit_form == "LINEAR" }
    health_rate := "0.09" { pit_form == "LUMP_SUM" }
    health_amount := floor(monthly_profit * 0.09 * 100) / 100
    estimated_zus := social_amount + health_amount

    # Fiscal health score (0-100)
    burden_ratio := (estimated_tax + estimated_zus) / monthly_revenue
    health_score := 100 - floor(burden_ratio * 100)
    health_score := 0 { health_score < 0 }
    health_score := 100 { health_score > 100 }

    deadlines := [
        "📅 VAT: do 25. dnia miesiąca (JPK_V7M)",
        "📅 PIT: zaliczka do 20. dnia miesiąca",
        "📅 ZUS: do 10. dnia miesiąca (JDG bez pracowników)",
        "📅 ZUS: do 15. dnia miesiąca (JDG z pracownikami)"
    ]

    health_routing := "TRIAGE_QUEUE" { health_score < 50 }
    health_routing := "" { health_score >= 50 }
    health_reason := sprintf("Kondycja fiskalna: %d/100 — wysokie obciążenia!", [health_score]) { health_score < 50 }
    health_reason := "" { health_score >= 50 }
}

build_health_warnings(score, tax, zus) = warnings {
    score >= 80
    warnings := [
        sprintf("🟢 KONDYCJA FISKALNA: %d/100 — DOSKONAŁA", [score]),
        sprintf("💰 Szacowany miesięczny PIT: %.2f PLN + ZUS: %.2f PLN = %.2f PLN", [tax, zus, tax + zus]),
        "✅ Terminy podatkowe: VAT 25., PIT 20., ZUS 10. (lub 15. z pracownikami)"
    ]
}

build_health_warnings(score, tax, zus) = warnings {
    score >= 50
    score < 80
    warnings := [
        sprintf("🟡 KONDYCJA FISKALNA: %d/100 — DOBRA (monitoruj)", [score]),
        sprintf("💰 Szacowany miesięczny PIT: %.2f PLN + ZUS: %.2f PLN = %.2f PLN", [tax, zus, tax + zus]),
        "⚠️ Rozważ optymalizację formy opodatkowania lub ulg podatkowych."
    ]
}

build_health_warnings(score, tax, zus) = warnings {
    score < 50
    warnings := [
        sprintf("🔴 KONDYCJA FISKALNA: %d/100 — SŁABA!", [score]),
        sprintf("💰 Obciążenia fiskalne: %.2f PLN (%.1f%% przychodu!).", [tax + zus, (tax+zus)/max([monthly_rev, 1]) * 100]),
        "🚨 NATYCHMIASTOWA OPTYMALIZACJA KONIECZNA! Rozważ zmianę formy opodatkowania / Mały ZUS Plus."
    ]
}

monthly_rev := 15000

# ═══════════════════════════════════════════════════════════════════════════════
# S2-240: CROSS-PACKAGE DEPENDENCY MATRIX — Macierz zależności 60×60
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_domain.dependency_matrix",
    "package": "jdg.cross_domain_hub",
    "priority": 240,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "cross_domain_dependency_count": dep_count,
    "cross_domain_critical_dependencies": critical_deps,
    "cross_domain_impact_score": impact_score,
    "cross_domain_cascade_risk": cascade_risk,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": dep_routing,
    "_routing_reason": dep_reason,
    "_legal_basis": "Cross-domain analysis — wszystkie pakiety JDG",
    "_warnings": [
        sprintf("🔗 MACIERZ ZALEZNOSCI MIEDZY PAKIETAMI", []),
        sprintf("   Aktywne zaleznosci: %d", [dep_count]),
        sprintf("   Krytyczne: %d", [count(critical_deps)]),
        sprintf("   Impact Score: %d/100", [impact_score]),
        sprintf("   Ryzyko kaskadowe: %s", [cascade_risk])
    ]
} {
    input.cross_domain_dependency_matrix == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    is_vat_payer := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT") == "ACTIVE"
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    is_cross_border := object.get(input.jdg_entrepreneur, "is_cross_border_active", false)
    uses_ksef := object.get(input.jdg_entrepreneur, "uses_ksef", false)
    has_ip_box := object.get(input.jdg_entrepreneur, "has_qualifying_ip", false)

    critical_deps := []
    critical_deps := array.concat(critical_deps, ["VAT→PIT: zmiana stawki VAT wpływa na KUP i dochód PIT"]) { is_vat_payer }
    critical_deps := array.concat(critical_deps, ["PIT→ZUS: zmiana formy PIT zmienia składkę zdrowotną"]) { pit_form == "PIT_SCALE" }
    critical_deps := array.concat(critical_deps, ["ZUS→Cashflow: składki ZUS to stałe obciążenie miesięczne"]) { true }
    critical_deps := array.concat(critical_deps, ["KSeF→VAT→PIT: faktury ustrukturyzowane wpływają na JPK i KUP"]) { uses_ksef }
    critical_deps := array.concat(critical_deps, ["IPBox→PIT→ZUS: dochód z IP 5% zmienia PIT i podstawę zdrowotną"]) { has_ip_box }
    critical_deps := array.concat(critical_deps, ["CrossBorder→VAT→MDR: transakcje transgraniczne trigger MDR DAC6"]) { is_cross_border }
    critical_deps := array.concat(critical_deps, ["Employer→ZUS→PPK: zatrudnienie trigger składki PPK+PFRON"]) { has_employees }

    dep_count := count(critical_deps)
    impact_score := dep_count * 12
    impact_score := 100 { impact_score > 100 }
    cascade_risk := "NISKIE" { dep_count <= 2 }
    cascade_risk := "SREDNIE" { dep_count > 2; dep_count <= 4 }
    cascade_risk := "WYSOKIE" { dep_count > 4 }

    dep_routing := "TRIAGE_QUEUE" { dep_count > 4 }
    dep_routing := "" { true }
    dep_reason := sprintf("Wysoka liczba zależności (%d) — ryzyko efektu domina", [dep_count]) { dep_count > 4 }
    dep_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S2-250: KSeF × VAT × PIT TRIPLE INTERACTION — Trójstronna interakcja
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_domain.ksef_vat_pit_triple",
    "package": "jdg.cross_domain_hub",
    "priority": 250,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "cross_domain_ksef_sync_status": ksef_sync,
    "cross_domain_ksef_jpk_discrepancy": discrepancy_pct,
    "cross_domain_ksef_pkpir_alignment": pkpir_aligned,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": triple_routing,
    "_routing_reason": triple_reason,
    "_legal_basis": "Art. 106na-106nw VAT (KSeF); Art. 109 ust. 3d-e VAT (JPK)",
    "_warnings": [
        sprintf("📊 KSeF × VAT × PIT — TROJSTRONNA INTERAKCJA", []),
        sprintf("   Synchronizacja KSeF-JPK: %s", [ksef_sync]),
        sprintf("   Rozbieznosc: %.1f%%", [discrepancy_pct * 100]),
        sprintf("   PKPiR alignment: %s", ["OK" { pkpir_aligned } else "ROZBIEZNOSCI"])
    ]
} {
    input.cross_domain_ksef_triple == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    ksef_invoices := object.get(input.jdg_entrepreneur, "ksef_invoice_count_month", 0)
    jpk_invoices := object.get(input.jdg_entrepreneur, "jpk_invoice_count_month", 0)
    pkpir_entries := object.get(input.jdg_entrepreneur, "pkpir_entries_month", 0)

    ksef_sync := "ZSynchronizowane" { ksef_invoices == jpk_invoices }
    ksef_sync := sprintf("Rozbieznosc: KSeF=%d, JPK=%d", [ksef_invoices, jpk_invoices]) { ksef_invoices != jpk_invoices }

    max_invoices := max([ksef_invoices, jpk_invoices, 1])
    discrepancy_pct := (ksef_invoices - jpk_invoices) / max_invoices { ksef_invoices >= jpk_invoices }
    discrepancy_pct := (jpk_invoices - ksef_invoices) / max_invoices { jpk_invoices > ksef_invoices }

    pkpir_aligned := pkpir_entries >= ksef_invoices

    triple_routing := "TRIAGE_QUEUE" { not pkpir_aligned }
    triple_routing := "" { true }
    triple_reason := "Niezgodnosc KSeF/JPK/PKPiR — sprawdz księgowania" { not pkpir_aligned }
    triple_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S2-260: CASHFLOW STRESS TEST CROSS-DOMAIN — Test warunków skrajnych
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_domain.cashflow_stress_test",
    "package": "jdg.cross_domain_hub",
    "priority": 260,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "cross_domain_stress_liquid_ratio": liquid_ratio,
    "cross_domain_stress_months_survival": months_survival,
    "cross_domain_stress_worst_case_deficit": worst_deficit,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": stress_routing,
    "_routing_reason": stress_reason,
    "_legal_basis": "Ogólne — analiza płynności",
    "_warnings": [
        sprintf("💧 CASHFLOW STRESS TEST — CROSS-DOMAIN", []),
        sprintf("   Wskaznik plynnosci: %.2f", [liquid_ratio]),
        sprintf("   Miesiace przetrwania (scenariusz pesymistyczny): %d", [months_survival]),
        sprintf("   Deficyt w najgorszym scenariuszu: %.0f PLN", [worst_deficit])
    ]
} {
    input.cross_domain_stress_test == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    cash_reserves := object.get(input.jdg_entrepreneur, "cash_reserves", 30000)
    monthly_fixed_costs := object.get(input.jdg_entrepreneur, "monthly_fixed_costs", 8000)
    monthly_revenue := object.get(input.jdg_entrepreneur, "monthly_revenue_avg", 15000)
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)

    # Stress scenario: revenue drops 50%, costs stay same
    stress_revenue := monthly_revenue * 0.50
    stress_monthly_deficit := monthly_fixed_costs - stress_revenue
    worst_deficit := max([stress_monthly_deficit, 0])

    liquid_ratio := cash_reserves / max([monthly_fixed_costs, 1])
    months_survival := 0 { worst_deficit <= 0 }
    months_survival := floor(cash_reserves / worst_deficit) { worst_deficit > 0 }

    stress_routing := "BLOCK_AND_ALERT" { months_survival < 2 }
    stress_routing := "TRIAGE_QUEUE" { months_survival >= 2; months_survival < 6 }
    stress_routing := "" { true }
    stress_reason := sprintf("KRYTYCZNE: tylko %d mies przetrwania przy spadku przychodow o 50%%!", [months_survival]) { months_survival < 2 }
    stress_reason := sprintf("Umiarkowane ryzyko — %d mies bufferu", [months_survival]) { months_survival >= 2; months_survival < 6 }
    stress_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S2-270: ZUS × PIT HEALTH CONTRIBUTION PARADOX DEEP
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_domain.zus_pit_health_paradox_deep",
    "package": "jdg.cross_domain_hub",
    "priority": 270,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "cross_domain_effective_marginal_rate": effective_rate,
    "cross_domain_health_paradox_active": has_paradox,
    "cross_domain_break_even_income": break_even,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": paradox_routing,
    "_routing_reason": paradox_reason,
    "_legal_basis": "Art. 79-81 ustawy zdrowotnej; Art. 27, 30c PIT",
    "_warnings": [
        sprintf("🏥 PARADOKS SKŁADKI ZDROWOTNEJ — ANALIZA GŁĘBOKA", []),
        sprintf("   Efektywna krańcowa stopa: %.1f%%", [effective_rate * 100]),
        sprintf("   Paradoks aktywny: %s", ["TAK — 1000 PLN wiecej = +%.0f PLN zdrowotnej" { has_paradox } else "NIE"]),
        sprintf("   Break-even dla zmiany na liniowy: %.0f PLN dochodu", [break_even])
    ]
} {
    input.cross_domain_health_paradox == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    monthly_profit := object.get(input.jdg_entrepreneur, "monthly_profit_avg", 8000)
    annual_profit := monthly_profit * 12

    effective_rate := 0.12 + 0.09 { pit_form == "PIT_SCALE" }
    effective_rate := 0.19 + 0.049 { pit_form == "LINEAR" }
    effective_rate := 0.15 { pit_form == "LUMP_SUM" }

    has_paradox := pit_form == "PIT_SCALE" and monthly_profit > 6000
    break_even := 150000

    paradox_routing := "" { true }
    paradox_reason := sprintf("Efektywna stopa %.0f%% — rozwaz zmiane formy na liniowy (%.0f%%)", [effective_rate * 100, 0.239 * 100]) { has_paradox }
    paradox_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S2-280: CROSS-BORDER × VAT × PIT DOMINO — Transgraniczny efekt domina
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_domain.crossborder_vat_pit_domino",
    "package": "jdg.cross_domain_hub",
    "priority": 280,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "cross_domain_cb_wnt_triggered": wnt_triggered,
    "cross_domain_cb_mdr_risk": mdr_risk,
    "cross_domain_cb_tax_haven_flag": tax_haven_flag,
    "cross_domain_cb_vat_registration_needed": vat_reg_needed,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": cb_routing,
    "_routing_reason": cb_reason,
    "_legal_basis": "Art. 17 VAT (WNT); Art. 86a-86o OrdPU (MDR); Art. 30c PIT",
    "_warnings": [
        sprintf("🌍 CROSS-BORDER × VAT × PIT — ANALIZA TRANSGRANICZNA", []),
        sprintf("   WNT trigger: %s", ["TAK" { wnt_triggered } else "NIE"]),
        sprintf("   Ryzyko MDR: %s", ["WYSOKIE" { mdr_risk } else "NISKIE"]),
        sprintf("   Tax haven: %s — %s", ["TAK" { tax_haven_flag } else "NIE", "WYMAGA MDR!" { tax_haven_flag } else "OK"])
    ]
} {
    input.cross_domain_cb_analysis == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    vendor_country := object.get(input.vendor, "country", "PL")
    is_eu := vendor_country in {"DE","FR","IT","ES","NL","CZ","SK","LT","LV","EE","AT","BE","BG","HR","CY","DK","FI","GR","HU","IE","LU","MT","PT","RO","SI","SE"}
    is_tax_haven := vendor_country in {"KY","BM","VG","JE","GG","IM","GI","MC","LI","AD","SM","MH","PW","CK","NR","NU","WS","VU","AE"}
    amount_net := object.get(input.invoice, "amount_net", 0)

    wnt_triggered := input.invoice.direction == "PURCHASE" and is_eu and vendor_country != "PL"
    mdr_risk := is_tax_haven or (is_eu and amount_net > 1000000)
    tax_haven_flag := is_tax_haven
    vat_reg_needed := wnt_triggered and object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT") == "EXEMPT"

    cb_routing := "TRIAGE_QUEUE" { mdr_risk }
    cb_routing := "" { true }
    cb_reason := sprintf("Transakcja z %s — ryzyko MDR i sankcji!", [vendor_country]) { mdr_risk }
    cb_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S2-290: MDR × EXIT TAX × VAT INTERACTION — Interakcja MDR z exit tax
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_domain.mdr_exit_tax_vat",
    "package": "jdg.cross_domain_hub",
    "priority": 290,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "cross_domain_mdr_active": mdr_active,
    "cross_domain_exit_tax_risk": exit_tax_risk,
    "cross_domain_mdr_deadline_priority": deadline_priority,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": mdr_routing,
    "_routing_reason": mdr_reason,
    "_legal_basis": "Art. 86a-86o OrdPU (MDR); Art. 30da PIT (exit tax); Art. 108a-108d VAT",
    "_warnings": [
        sprintf("🔗 MDR × EXIT TAX × VAT — INTERAKCJA", []),
        sprintf("   MDR DAC6: %s", ["AKTYWNY" { mdr_active } else "BRAK"]),
        sprintf("   Exit tax risk: %s", ["AKTYWNY" { exit_tax_risk } else "BRAK"]),
        sprintf("   Priorytet deadline: %s", [deadline_priority])
    ]
} {
    input.cross_domain_mdr_analysis == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    is_cross_border := object.get(input.jdg_entrepreneur, "is_cross_border_active", false)
    has_ip_transfer := object.get(input, "mdr_ip_transfer", false)
    involves_tax_haven := object.get(input, "mdr_involves_tax_haven", false)
    changes_tax_residency := object.get(input, "changes_tax_residency", false)

    mdr_active := is_cross_border and (has_ip_transfer or involves_tax_haven)
    exit_tax_risk := changes_tax_residency and is_cross_border

    deadline_priority := "MDR FIRST (7 dni)" { mdr_active }
    deadline_priority := "EXIT TAX FIRST (przed zmiana rezydencji)" { exit_tax_risk; not mdr_active }
    deadline_priority := "BRAK" { not mdr_active; not exit_tax_risk }

    mdr_routing := "TRIAGE_QUEUE" { mdr_active or exit_tax_risk }
    mdr_routing := "" { true }
    mdr_reason := "MDR i Exit Tax aktywne — priorytetowe raportowanie!" { mdr_active and exit_tax_risk }
    mdr_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S2-300: S10 (BANKING) × S8 (CASHFLOW) INTEGRATION
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_domain.banking_cashflow_integration",
    "package": "jdg.cross_domain_hub",
    "priority": 300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "cross_domain_banking_auto_enabled": banking_auto,
    "cross_domain_cashflow_forecast_30d": cashflow_30d,
    "cross_domain_upcoming_payments_total": upcoming_total,
    "cross_domain_banking_batch_ready": batch_ready,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": bc_routing,
    "_routing_reason": bc_reason,
    "_legal_basis": "Art. 108a VAT (MPP); Art. 47 SUS; PSD2 Art. 64-67",
    "_warnings": [
        sprintf("💳 BANKING × CASHFLOW — INTEGRACJA S10+S8", []),
        sprintf("   Automatyzacja bankowa: %s", ["WLACZONA" { banking_auto } else "WYLACZONA"]),
        sprintf("   Cashflow 30 dni: %.0f PLN", [cashflow_30d]),
        sprintf("   Nadchodzace platnosci: %.0f PLN", [upcoming_total]),
        sprintf("   Paczka gotowa do wysylki: %s", ["TAK" { batch_ready } else "NIE"])
    ]
} {
    input.cross_domain_banking_cashflow == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    banking_auto := object.get(input.jdg_entrepreneur, "banking_psd2_enabled", false)
    monthly_zus := object.get(input.jdg_entrepreneur, "monthly_zus_total", 1500)
    monthly_vat := object.get(input.jdg_entrepreneur, "monthly_vat_to_pay", 2000)
    monthly_pit := object.get(input.jdg_entrepreneur, "monthly_pit_advance", 1000)
    cash_reserves := object.get(input.jdg_entrepreneur, "cash_reserves", 30000)

    upcoming_total := monthly_zus + monthly_vat + monthly_pit
    cashflow_30d := cash_reserves - upcoming_total
    batch_ready := banking_auto and upcoming_total > 0 and cashflow_30d > 0

    bc_routing := "BLOCK_AND_ALERT" { upcoming_total > 0; cashflow_30d < 0 }
    bc_routing := "TRIAGE_QUEUE" { upcoming_total > 0; cashflow_30d < upcoming_total * 0.5 }
    bc_routing := "" { true }
    bc_reason := sprintf("DEFICYT: platnosci %.0f PLN > rezerwy %.0f PLN!", [upcoming_total, cash_reserves]) { cashflow_30d < 0 }
    bc_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S2-310: IMPACT SCORING CALCULATOR — Punktacja wpływu zmian
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_domain.impact_scoring",
    "package": "jdg.cross_domain_hub",
    "priority": 310,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "cross_domain_impact_total": impact_total,
    "cross_domain_impact_ranking": impact_ranking,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": imp_routing,
    "_routing_reason": imp_reason,
    "_legal_basis": "Cross-domain impact analysis",
    "_warnings": [
        sprintf("📊 IMPACT SCORING — CROSS-DOMAIN", []),
        sprintf("   Wynik: %d/100", [impact_total]),
        sprintf("   Ranking: %s", [impact_ranking])
    ]
} {
    input.cross_domain_impact_score == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    is_vat_payer := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT") == "ACTIVE"
    is_cross_border := object.get(input.jdg_entrepreneur, "is_cross_border_active", false)
    uses_ksef := object.get(input.jdg_entrepreneur, "uses_ksef", false)

    impact_total := 0
    impact_total := impact_total + 25 { has_employees }
    impact_total := impact_total + 20 { is_vat_payer }
    impact_total := impact_total + 30 { is_cross_border }
    impact_total := impact_total + 15 { uses_ksef }
    impact_total := impact_total + 10 { pit_form == "PIT_SCALE" }

    impact_ranking := "NISKI" { impact_total < 30 }
    impact_ranking := "SREDNI" { impact_total >= 30; impact_total < 60 }
    impact_ranking := "WYSOKI" { impact_total >= 60 }

    imp_routing := "TRIAGE_QUEUE" { impact_total >= 60 }
    imp_routing := "" { true }
    imp_reason := sprintf("Wysoki impact score %d/100 — wymagany monitoring cross-domain", [impact_total]) { impact_total >= 60 }
    imp_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# S2-320: MERMAID DIAGRAM GENERATOR — Generowanie diagramów zależności
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_domain.mermaid_diagram_generator",
    "package": "jdg.cross_domain_hub",
    "priority": 320,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "cross_domain_mermaid_diagram": mermaid_code,
    "cross_domain_mermaid_nodes": node_count,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Wizualizacja zależności — narzędzie analityczne",
    "_warnings": [
        sprintf("📐 DIAGRAM MERMAID — ZALEZNOSCI CROSS-DOMAIN", []),
        sprintf("   Wezlow: %d", [node_count]),
        "   Skopiuj kod do https://mermaid.live aby zobaczyc diagram"
    ]
} {
    input.cross_domain_mermaid == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    is_vat_payer := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT") == "ACTIVE"
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)
    is_cross_border := object.get(input.jdg_entrepreneur, "is_cross_border_active", false)

    # Generate Mermaid flowchart code
    mermaid_lines := ["graph TD"]
    mermaid_lines := array.concat(mermaid_lines, ["    VAT[VAT] --> PIT[PIT]"])
    mermaid_lines := array.concat(mermaid_lines, ["    VAT --> JPK[JPK_V7/KSeF]"])
    mermaid_lines := array.concat(mermaid_lines, ["    PIT --> ZUS[ZUS/Skladka zdrowotna]"])
    mermaid_lines := array.concat(mermaid_lines, ["    ZUS --> CASHFLOW[Cashflow]"])
    mermaid_lines := array.concat(mermaid_lines, ["    PIT --> ALLOW[Ulgi/IP Box]"])

    mermaid_lines := array.concat(mermaid_lines, ["    VAT --> CB[Cross-Border]"]) { is_cross_border }
    mermaid_lines := array.concat(mermaid_lines, ["    CB --> MDR[MDR DAC6]"])
    mermaid_lines := array.concat(mermaid_lines, ["    CB --> EXIT[Exit Tax]"])

    mermaid_lines := array.concat(mermaid_lines, ["    ZUS --> EMP[Employer/PPK]"]) { has_employees }
    mermaid_lines := array.concat(mermaid_lines, ["    EMP --> PFRON[PFRON]"])

    mermaid_lines := array.concat(mermaid_lines, ["    VAT --> BANKING[Banking PSD2]"]) { is_vat_payer }
    mermaid_lines := array.concat(mermaid_lines, ["    BANKING --> CASHFLOW"])

    mermaid_lines := array.concat(mermaid_lines, ["    PIT --> STRATEGIC[Strategic Advisor S5]"])
    mermaid_lines := array.concat(mermaid_lines, ["    STRATEGIC --> TRANSFORM[JDG->Sp. z o.o.]"])

    mermaid_code := concat("\n", mermaid_lines)
    node_count := count(mermaid_lines) - 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# S2-330: CROSS-INITIATIVE DEPENDENCY MAP — Mapa zależności między S1-S24
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_domain.initiative_dependency_map",
    "package": "jdg.cross_domain_hub",
    "priority": 330,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "cross_domain_s1_depends_on": ["S9", "S11", "S14"],
    "cross_domain_s2_depends_on": ["S1", "S8", "S10", "S12", "S14", "S16", "S21", "S22", "S23", "S24"],
    "cross_domain_s4_depends_on": ["S22", "S23"],
    "cross_domain_s8_depends_on": ["S1", "S9", "S10"],
    "cross_domain_s10_depends_on": ["S8", "S12"],
    "cross_domain_s16_depends_on": ["S13", "S21"],
    "cross_domain_s22_depends_on": ["S4", "S23"],
    "cross_domain_s23_depends_on": ["S4", "S22"],
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Mapa zależności inicjatyw strategicznych S1-S24",
    "_warnings": [
        "🗺️ MAPA ZALEZNOSCI INICJATYW S1-S24:",
        "   S1 (Tax Opt) → S9 (Form Transition), S11 (Annual Declaration), S14 (Neural Mesh)",
        "   S2 (Cross-Domain) → S1, S8, S10, S12, S14, S16, S21, S22, S23, S24",
        "   S4 (Audit Defense) ↔ S22 (Tax Authority), S23 (Sanctions)",
        "   S8 (Cashflow) → S1, S9, S10",
        "   S10 (Banking) → S8, S12",
        "   S16 (MDR) → S13 (Legislative), S21 (VAT Complete)",
        "   S22 ↔ S4, S23",
        "   S23 ↔ S4, S22"
    ]
} {
    input.cross_domain_initiative_map == true
    true
}

# ═══════════════════════════════════════════════════════════════════════════════
# S2-340: ANNUAL CROSS-DOMAIN STRATEGIC REVIEW — Roczny przegląd
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.cross_domain.annual_strategic_review",
    "package": "jdg.cross_domain_hub",
    "priority": 340,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "cross_domain_annual_review_score": review_score,
    "cross_domain_annual_recommendations": annual_recs,
    "cross_domain_top_3_priorities": top_3,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": annual_routing,
    "_routing_reason": annual_reason,
    "_legal_basis": "Kompleksowy przegląd roczny — wszystkie inicjatywy",
    "_warnings": [
        sprintf("📅 ROCZNY PRZEGLAD CROSS-DOMAIN %d", [2026]),
        sprintf("   Ocena: %d/100", [review_score]),
        sprintf("   Rekomendacje: %d", [count(annual_recs)])
    ]
} {
    input.cross_domain_annual_review == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_actual", 200000)
    is_vat_payer := object.get(input.jdg_entrepreneur, "vat_status", "EXEMPT") == "ACTIVE"
    has_employees := object.get(input.jdg_entrepreneur, "has_employees", false)

    review_score := 50
    review_score := review_score + 10 { is_vat_payer }
    review_score := review_score + 15 { has_employees }
    review_score := review_score + 10 { annual_revenue > 300000 }

    annual_recs := [
        "Przeglad zgodnosci VAT/JPK/PKPiR",
        "Analiza optymalizacji formy opodatkowania",
        "Aktualizacja kalendarza compliance S13",
        "Weryfikacja MDR DAC6 dla transakcji transgranicznych"
    ]

    top_3 := ["Optymalizacja podatkowa S1", "Compliance cross-check S2", "Strategia transformacji S5"]

    annual_routing := "TRIAGE_QUEUE" { review_score > 70 }
    annual_routing := "" { true }
    annual_reason := "Przeglad roczny zalecany" { true }
}
