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
    }
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
    health_monthly := min([monthly_profit * 0.049, 12900/12]) { pit_form == "LINEAR" }
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
