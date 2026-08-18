# NexusAI JDG — ENTERPRISE CROSS-DOMAIN INTELLIGENCE HUB
package jdg.cross_domain_hub

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.cross_domain.no_match",
    "package": "jdg.cross_domain_hub",
    "priority": 9999
}

base_fields := {
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false
}

bool01(value) = 1 {
    value == true
}

bool01(value) = 0 {
    value != true
}

health_rate_for(form) = "0.09" {
    form == "PIT_SCALE"
}

health_rate_for(form) = "0.049" {
    form == "LINEAR"
}

health_rate_for(form) = "progresywna" {
    form == "LUMP_SUM"
}

health_rate_for(form) = "0.09" {
    form != "PIT_SCALE"
    form != "LINEAR"
    form != "LUMP_SUM"
}

domino_routing(amount_vat, is_purchase, deductible) = "TRIAGE_QUEUE" {
    amount_vat > 10000
    is_purchase
    deductible == false
}

domino_routing(amount_vat, is_purchase, deductible) = "" {
    amount_vat <= 10000
}

domino_routing(amount_vat, is_purchase, deductible) = "" {
    amount_vat > 10000
    is_purchase == false
}

domino_routing(amount_vat, is_purchase, deductible) = "" {
    amount_vat > 10000
    is_purchase
    deductible != false
}

domino_reason(routing) = "Duży nieodliczalny VAT wymaga analizy KUP." {
    routing == "TRIAGE_QUEUE"
}

domino_reason(routing) = "" {
    routing == ""
}

trap_present(name, profile) {
    name == "zus_maly_plus"
    object.get(profile, "last_year_revenue", 0) > 110000
}

trap_present(name, profile) {
    name == "linear_former_employer"
    object.get(profile, "tax_form", "") == "LINEAR"
    object.get(profile, "services_for_former_employer", false) == true
}

trap_present(name, profile) {
    name == "car_no_mileage_log"
    object.get(profile, "vehicle_mileage_log_maintained", true) == false
    object.get(profile, "vehicle_value_pln", 0) > 50000
}

trap_present(name, profile) {
    name == "scale_threshold"
    object.get(profile, "tax_form", "") == "PIT_SCALE"
    object.get(profile, "annual_income", 0) > 120000
}

trap_present(name, profile) {
    name == "vat_exemption_limit"
    object.get(profile, "vat_status", "EXEMPT") == "EXEMPT"
    object.get(profile, "annual_revenue_actual", 0) > 180000
}

trap_present(name, profile) {
    name == "employee_jdg_zus"
    object.get(profile, "has_employment_contract", false) == true
}

trap_names(profile) = names {
    names := [name | trap_present(name, profile)]
}

trap_severity(names) = "NONE" {
    count(names) == 0
}

trap_severity(names) = "HIGH" {
    count(names) > 0
}

trap_routing(names) = "BLOCK_AND_ALERT" {
    count(names) >= 2
}

trap_routing(names) = "TRIAGE_QUEUE" {
    count(names) == 1
}

trap_routing(names) = "" {
    count(names) == 0
}

health_score(revenue, costs) = score {
    profit := revenue - costs
    tax := max([profit * 0.12, 0])
    zus := 4800 * 0.60 * 0.3812 + profit * 0.09
    score := max([0, min([100, 100 - floor((tax + zus) / max([revenue, 1]) * 100)])])
}

health_routing(score) = "TRIAGE_QUEUE" {
    score < 50
}

health_routing(score) = "" {
    score >= 50
}

health_reason(score) = reason {
    score < 50
    reason := sprintf("Wysokie obciążenie: %d/100.", [score])
}

health_reason(score) = "" {
    score >= 50
}

dependency_count(profile) = count_value {
    count_value := 1 + bool01(object.get(profile, "vat_status", "") == "ACTIVE") + bool01(object.get(profile, "tax_form", "") == "PIT_SCALE") + bool01(object.get(profile, "uses_ksef", false)) + bool01(object.get(profile, "is_cross_border_active", false))
}

dependency_risk(count_value) = "NISKIE" {
    count_value <= 2
}

dependency_risk(count_value) = "SREDNIE" {
    count_value > 2
    count_value <= 4
}

dependency_risk(count_value) = "WYSOKIE" {
    count_value > 4
}

ksef_sync(ksef, jpk) = "ZSynchronizowane" {
    ksef == jpk
}

ksef_sync(ksef, jpk) = result {
    ksef != jpk
    result := sprintf("Rozbieżność KSeF=%d JPK=%d", [ksef, jpk])
}

stress_deficit(revenue, costs) = deficit {
    deficit := max([costs - revenue * 0.50, 0])
}

stress_months(reserves, deficit) = 0 {
    deficit == 0
}

stress_months(reserves, deficit) = months {
    deficit > 0
    months := floor(reserves / deficit)
}

stress_routing(months) = "BLOCK_AND_ALERT" {
    months < 2
}

stress_routing(months) = "TRIAGE_QUEUE" {
    months >= 2
    months < 6
}

stress_routing(months) = "" {
    months >= 6
}

paradox_rate(form) = 0.21 {
    form == "PIT_SCALE"
}

paradox_rate(form) = 0.239 {
    form == "LINEAR"
}

paradox_rate(form) = 0.15 {
    form == "LUMP_SUM"
}

paradox_rate(form) = 0.21 {
    form != "PIT_SCALE"
    form != "LINEAR"
    form != "LUMP_SUM"
}

paradox_active(form, profit) = true {
    form == "PIT_SCALE"
    profit > 6000
}

paradox_active(form, profit) = false {
    form != "PIT_SCALE"
}

paradox_active(form, profit) = false {
    form == "PIT_SCALE"
    profit <= 6000
}

deadline_priority(active, exit_risk) = "MDR FIRST (7 dni)" {
    active
}

deadline_priority(active, exit_risk) = "EXIT TAX FIRST" {
    active == false
    exit_risk
}

deadline_priority(active, exit_risk) = "BRAK" {
    active == false
    exit_risk == false
}

country_is_eu(country) {
    country in {"DE", "FR", "IT", "ES", "NL", "CZ", "SK", "LT", "LV", "EE", "AT", "BE", "BG", "HR", "CY", "DK", "FI", "GR", "HU", "IE", "LU", "MT", "PT", "RO", "SI", "SE"}
}

country_is_haven(country) {
    country in {"KY", "BM", "VG", "JE", "GG", "IM", "GI", "MC", "LI", "AD", "SM", "MH", "PW", "AE"}
}

wnt_triggered(invoice, country) {
    object.get(invoice, "direction", "") == "PURCHASE"
    country_is_eu(country)
    country != "PL"
}

mdr_active(cross_border, ip_transfer, tax_haven) {
    cross_border
    ip_transfer
}

mdr_active(cross_border, ip_transfer, tax_haven) {
    cross_border
    tax_haven
}

batch_ready(enabled, cashflow) {
    enabled
    cashflow > 0
}

impact_total(profile) = total {
    total := min([100,
        bool01(object.get(profile, "has_employees", false)) * 25 +
        bool01(object.get(profile, "vat_status", "") == "ACTIVE") * 20 +
        bool01(object.get(profile, "is_cross_border_active", false)) * 30 +
        bool01(object.get(profile, "uses_ksef", false)) * 15 +
        bool01(object.get(profile, "tax_form", "") == "PIT_SCALE") * 10])
}

impact_ranking(total) = "NISKI" {
    total < 30
}

impact_ranking(total) = "SREDNI" {
    total >= 30
    total < 60
}

impact_ranking(total) = "WYSOKI" {
    total >= 60
}

# S2-200: VAT × PIT domino
decide := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_domain.vat_pit_domino",
    "package": "jdg.cross_domain_hub",
    "priority": 200,
    "cross_domain_vat_impact_on_pit": vat_pit_impact,
    "cross_domain_vat_impact_on_zus": vat_zus_impact,
    "cross_domain_cashflow_60day_warning": cashflow_warning,
    "_routing": routing,
    "_routing_reason": domino_reason(routing),
    "_legal_basis": "Art. 14 PIT; Art. 86 VAT; Art. 23 ust. 1 pkt 43 PIT",
    "_warnings": ["🔗 EFEKT DOMINA: VAT → PIT → ZUS → cashflow."]
}) {
    object.get(input, "cross_domain_analysis", false) == true
    profile := object.get(input, "jdg_entrepreneur", {})
    invoice := object.get(input, "invoice", {})
    form := object.get(profile, "tax_form", "PIT_SCALE")
    net := object.get(invoice, "amount_net", 0)
    vat := object.get(invoice, "amount_vat", 0)
    deductible := object.get(invoice, "vat_deductible", true)
    purchase := object.get(invoice, "direction", "") == "PURCHASE"
    vat_pit_impact := sprintf("VAT %.2f PLN; forma PIT %s; odliczalny=%v", [vat, form, deductible])
    vat_zus_impact := sprintf("Wpływ netto %.2f PLN na analizę ZUS.", [net])
    cashflow_warning := sprintf("Płatność brutto %.2f PLN; monitoruj zwrot VAT.", [net + vat])
    routing := domino_routing(vat, purchase, deductible)
}

# S2-210: PIT × ZUS interlock
else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_domain.pit_zus_interlock",
    "package": "jdg.cross_domain_hub",
    "priority": 210,
    "cross_domain_zus_deductible_from_pit": deductible,
    "cross_domain_pit_health_paradox": profit > 6000,
    "zus_social_base_type": status,
    "zus_health_rate": rate,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Polski Ład 2022; Art. 26 PIT; Art. 81 ustawy zdrowotnej",
    "_warnings": [sprintf("PIT %s × ZUS %s; zdrowotna %s.", [form, status, rate])]
}) {
    object.get(input, "cross_domain_pit_zus_interlock", false) == true
    profile := object.get(input, "jdg_entrepreneur", {})
    form := object.get(profile, "tax_form", "PIT_SCALE")
    status := object.get(profile, "zus_status", "STANDARD")
    profit := object.get(profile, "monthly_profit_avg", 8000)
    rate := health_rate_for(form)
    deductible := profit * 0.3812 * 12
}

# S2-220: tax trap detector
else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_domain.tax_trap_detector",
    "package": "jdg.cross_domain_hub",
    "priority": 220,
    "cross_domain_active_traps": traps,
    "cross_domain_trap_severity": trap_severity(traps),
    "_routing": trap_routing(traps),
    "_routing_reason": sprintf("Aktywne pułapki: %d.", [count(traps)]),
    "_legal_basis": "Cross-domain VAT, PIT, SUS, KKS",
    "_warnings": [sprintf("Wykryto %d pułapek podatkowych.", [count(traps)])]
}) {
    object.get(input, "cross_domain_tax_traps", false) == true
    profile := object.get(input, "jdg_entrepreneur", {})
    traps := trap_names(profile)
}

# S2-230: monthly fiscal health
else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_domain.monthly_fiscal_health",
    "package": "jdg.cross_domain_hub",
    "priority": 230,
    "cross_domain_fiscal_health_score": score,
    "cross_domain_monthly_deadlines": ["VAT: 25.", "PIT: 20.", "ZUS: 10./15."],
    "cross_domain_estimated_tax_pln": tax,
    "cross_domain_estimated_zus_pln": zus,
    "_routing": health_routing(score),
    "_routing_reason": health_reason(score),
    "_legal_basis": "Art. 44 PIT; Art. 103 VAT; Art. 47 SUS",
    "_warnings": [sprintf("Kondycja fiskalna: %d/100.", [score])]
}) {
    object.get(input, "cross_domain_monthly_check", false) == true
    profile := object.get(input, "jdg_entrepreneur", {})
    revenue := object.get(profile, "monthly_revenue_avg", 15000)
    costs := object.get(profile, "monthly_costs_avg", 5000)
    score := health_score(revenue, costs)
    profit := revenue - costs
    tax := floor(max([profit * 0.12, 0]) * 100) / 100
    zus := floor((4800 * 0.60 * 0.3812 + profit * 0.09) * 100) / 100
}

# S2-240: dependency matrix
else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_domain.dependency_matrix",
    "package": "jdg.cross_domain_hub",
    "priority": 240,
    "cross_domain_dependency_count": dep_count,
    "cross_domain_critical_dependencies": ["ZUS→Cashflow"],
    "cross_domain_impact_score": dep_count * 12,
    "cross_domain_cascade_risk": dependency_risk(dep_count),
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Macierz zależności cross-domain.",
    "_legal_basis": "Cross-domain analysis — pakiety JDG",
    "_warnings": ["🔗 MACIERZ ZALEŻNOŚCI CROSS-DOMAIN"]
}) {
    object.get(input, "cross_domain_dependency_matrix", false) == true
    profile := object.get(input, "jdg_entrepreneur", {})
    dep_count := dependency_count(profile)
}

# S2-250: KSeF × VAT × PIT
else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_domain.ksef_vat_pit_triple",
    "package": "jdg.cross_domain_hub",
    "priority": 250,
    "cross_domain_ksef_sync_status": sync,
    "cross_domain_ksef_jpk_discrepancy": discrepancy,
    "cross_domain_ksef_pkpir_alignment": aligned,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "KSeF/JPK/PKPiR wymaga weryfikacji.",
    "_legal_basis": "Art. 106na-106nw VAT; Art. 109 ust. 3d-e VAT",
    "_warnings": [sprintf("KSeF/JPK: %s.", [sync])]
}) {
    object.get(input, "cross_domain_ksef_triple", false) == true
    profile := object.get(input, "jdg_entrepreneur", {})
    ksef := object.get(profile, "ksef_invoice_count_month", 0)
    jpk := object.get(profile, "jpk_invoice_count_month", 0)
    pkpir := object.get(profile, "pkpir_entries_month", 0)
    sync := ksef_sync(ksef, jpk)
    discrepancy := abs(ksef - jpk) / max([ksef, jpk, 1])
    aligned := pkpir >= ksef
}

# S2-260: cashflow stress test
else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_domain.cashflow_stress_test",
    "package": "jdg.cross_domain_hub",
    "priority": 260,
    "cross_domain_stress_liquid_ratio": ratio,
    "cross_domain_stress_months_survival": months,
    "cross_domain_stress_worst_case_deficit": deficit,
    "_routing": stress_routing(months),
    "_routing_reason": sprintf("Buffer płynności: %d mies.", [months]),
    "_legal_basis": "Analiza płynności cross-domain",
    "_warnings": [sprintf("Płynność %.2f; przetrwanie %d mies.", [ratio, months])]
}) {
    object.get(input, "cross_domain_stress_test", false) == true
    profile := object.get(input, "jdg_entrepreneur", {})
    reserves := object.get(profile, "cash_reserves", 30000)
    costs := object.get(profile, "monthly_fixed_costs", 8000)
    revenue := object.get(profile, "monthly_revenue_avg", 15000)
    deficit := stress_deficit(revenue, costs)
    ratio := reserves / max([costs, 1])
    months := stress_months(reserves, deficit)
}

# S2-270: ZUS × PIT health paradox
else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_domain.zus_pit_health_paradox_deep",
    "package": "jdg.cross_domain_hub",
    "priority": 270,
    "cross_domain_effective_marginal_rate": rate,
    "cross_domain_health_paradox_active": active,
    "cross_domain_break_even_income": 150000,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 79-81 ustawy zdrowotnej; Art. 27, 30c PIT",
    "_warnings": [sprintf("Efektywna stopa marginalna: %.1f%%.", [rate * 100])]
}) {
    object.get(input, "cross_domain_health_paradox", false) == true
    profile := object.get(input, "jdg_entrepreneur", {})
    form := object.get(profile, "tax_form", "PIT_SCALE")
    profit := object.get(profile, "monthly_profit_avg", 8000)
    rate := paradox_rate(form)
    active := paradox_active(form, profit)
}

# S2-280: cross-border VAT × PIT
else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_domain.crossborder_vat_pit_domino",
    "package": "jdg.cross_domain_hub",
    "priority": 280,
    "cross_domain_cb_wnt_triggered": wnt,
    "cross_domain_cb_mdr_risk": haven,
    "cross_domain_cb_tax_haven_flag": haven,
    "cross_domain_cb_vat_registration_needed": wnt,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Transakcja transgraniczna wymaga weryfikacji.",
    "_legal_basis": "Art. 17 VAT; przepisy MDR; Art. 30c PIT",
    "_warnings": ["🌍 CROSS-BORDER — sprawdź WNT, MDR i rejestrację VAT."]
}) {
    object.get(input, "cross_domain_cb_analysis", false) == true
    invoice := object.get(input, "invoice", {})
    vendor := object.get(input, "vendor", {})
    country := object.get(vendor, "country", "PL")
    wnt := wnt_triggered(invoice, country)
    haven := country_is_haven(country)
}

# S2-290: MDR × exit tax × VAT
else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_domain.mdr_exit_tax_vat",
    "package": "jdg.cross_domain_hub",
    "priority": 290,
    "cross_domain_mdr_active": active,
    "cross_domain_exit_tax_risk": exit_risk,
    "cross_domain_mdr_deadline_priority": deadline,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "MDR/exit tax wymaga priorytetowego raportowania.",
    "_legal_basis": "Art. 86a-86o OrdPU; Art. 30da PIT",
    "_warnings": ["🔗 MDR × EXIT TAX × VAT"]
}) {
    object.get(input, "cross_domain_mdr_analysis", false) == true
    profile := object.get(input, "jdg_entrepreneur", {})
    cross_border := object.get(profile, "is_cross_border_active", false)
    ip_transfer := object.get(input, "mdr_ip_transfer", false)
    tax_haven := object.get(input, "mdr_involves_tax_haven", false)
    residency := object.get(input, "changes_tax_residency", false)
    active := mdr_active(cross_border, ip_transfer, tax_haven)
    exit_risk := cross_border
    deadline := deadline_priority(active, exit_risk)
}

# S2-300: banking × cashflow
else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_domain.banking_cashflow_integration",
    "package": "jdg.cross_domain_hub",
    "priority": 300,
    "cross_domain_banking_auto_enabled": enabled,
    "cross_domain_cashflow_forecast_30d": cashflow,
    "cross_domain_upcoming_payments_total": payments,
    "cross_domain_banking_batch_ready": ready,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 108a VAT; Art. 47 SUS; PSD2",
    "_warnings": [sprintf("Cashflow 30 dni: %.0f PLN.", [cashflow])]
}) {
    object.get(input, "cross_domain_banking_cashflow", false) == true
    profile := object.get(input, "jdg_entrepreneur", {})
    enabled := object.get(profile, "banking_psd2_enabled", false)
    payments := object.get(profile, "monthly_zus_total", 1500) + object.get(profile, "monthly_vat_to_pay", 2000) + object.get(profile, "monthly_pit_advance", 1000)
    cashflow := object.get(profile, "cash_reserves", 30000) - payments
    ready := batch_ready(enabled, cashflow)
}

# S2-310: impact scoring
else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_domain.impact_scoring",
    "package": "jdg.cross_domain_hub",
    "priority": 310,
    "cross_domain_impact_total": total,
    "cross_domain_impact_ranking": impact_ranking(total),
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Impact score wymaga monitoringu.",
    "_legal_basis": "Cross-domain impact analysis",
    "_warnings": [sprintf("Impact score: %d/100.", [total])]
}) {
    object.get(input, "cross_domain_impact_score", false) == true
    profile := object.get(input, "jdg_entrepreneur", {})
    total := impact_total(profile)
}

# S2-320: Mermaid diagram generator
else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_domain.mermaid_diagram_generator",
    "package": "jdg.cross_domain_hub",
    "priority": 320,
    "cross_domain_mermaid_diagram": "graph TD\nVAT-->PIT\nPIT-->ZUS\nZUS-->CASHFLOW",
    "cross_domain_mermaid_nodes": 4,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Wizualizacja zależności cross-domain",
    "_warnings": ["📐 DIAGRAM MERMAID — ZALEŻNOŚCI CROSS-DOMAIN"]
}) {
    object.get(input, "cross_domain_mermaid", false) == true
}

# S2-330: initiative dependency map
else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_domain.initiative_dependency_map",
    "package": "jdg.cross_domain_hub",
    "priority": 330,
    "cross_domain_s1_depends_on": ["S9", "S11", "S14"],
    "cross_domain_s2_depends_on": ["S1", "S8", "S10", "S12", "S14", "S16", "S21", "S22", "S23", "S24"],
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Mapa zależności inicjatyw S1-S24",
    "_warnings": ["🗺️ MAPA ZALEŻNOŚCI INICJATYW S1-S24"]
}) {
    object.get(input, "cross_domain_initiative_map", false) == true
}

# S2-340: annual strategic review
else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.cross_domain.annual_strategic_review",
    "package": "jdg.cross_domain_hub",
    "priority": 340,
    "cross_domain_annual_review_score": score,
    "cross_domain_annual_recommendations": ["Przegląd VAT/JPK/PKPiR", "Optymalizacja formy PIT", "Aktualizacja MDR"],
    "cross_domain_top_3_priorities": ["Compliance cross-check", "Cashflow", "Strategia podatkowa"],
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Przegląd roczny zalecany.",
    "_legal_basis": "Kompleksowy przegląd roczny cross-domain",
    "_warnings": [sprintf("Roczny przegląd cross-domain: %d/100.", [score])]
}) {
    object.get(input, "cross_domain_annual_review", false) == true
    profile := object.get(input, "jdg_entrepreneur", {})
    score := min([100, 50 + bool01(object.get(profile, "vat_status", "") == "ACTIVE") * 10 + bool01(object.get(profile, "has_employees", false)) * 15 + bool01(object.get(profile, "annual_revenue_actual", 0) > 300000) * 10])
}
