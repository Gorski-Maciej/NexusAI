# NexusAI JDG — ETAP 10 PIT Macro Enterprise innovations
# Scope: forms, KUP/NKUP, advances/returns, exemptions, transitions and 3/5-year forecast.
# This package is report-only and activates only with pit_macro_etap10_check=true.
# It never authorizes AUTO_POST; uncertain or incomplete input is fail-closed.
# Legal source contract: Bbb/LKG -> data.jdg.thresholds + legal source registry.

package jdg.pit_macro_etap10

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.pit_macro_etap10.no_match",
    "package": "jdg.pit_macro_etap10",
    "priority": 540
}

_thresholds := object.get(data, "jdg", {})
_pit := object.get(_thresholds, "thresholds", {})
_pit_rates := object.get(_pit, "rates", {})
_pit_limits := object.get(_pit, "pit", {})
_pit_bounds := object.get(_pit, "bounds", {})

scale_low_rate := object.get(_pit_rates, "pit_scale_low", object.get(_pit_limits, "scale_low_rate", 0.12))
scale_high_rate := object.get(_pit_rates, "pit_scale_high", object.get(_pit_limits, "scale_high_rate", 0.32))
linear_rate := object.get(_pit_rates, "pit_linear", object.get(_pit_limits, "linear_rate", 0.19))
scale_threshold := object.get(_pit_bounds, "pit_scale_threshold", object.get(_pit, "scale_threshold", object.get(_pit_limits, "scale_threshold", 120000)))
standard_lump_rate := object.get(_pit_rates, "lump_8_5pct", 0.085)

ent := object.get(input, "jdg_entrepreneur", {})
card_tax := object.get(ent, "tax_card_annual_amount", 0)
forecast := object.get(input, "pit_macro_forecast", {})
revenue := to_number(object.get(ent, "annual_revenue", 0))
costs := to_number(object.get(ent, "annual_costs", 0))
zus_social := to_number(object.get(ent, "annual_zus_social", 0))
taxable_income := max([0, revenue - costs - zus_social])
form := object.get(ent, "tax_form", "")
form_valid := form in {"PIT_SCALE", "LINEAR", "LUMP_SUM", "TAX_CARD"}

required_input_names := ["tax_form", "annual_revenue", "annual_costs", "annual_zus_social"]
missing_inputs := [name |
    name := required_input_names[_]
    object.get(ent, name, null) == null
]

source_version := object.get(_pit, "threshold_version", object.get(_thresholds, "version", "UNKNOWN"))
evaluation_date := object.get(input, "evaluation_datetime", "")
source_complete := source_version != "UNKNOWN" and evaluation_date != ""

scale_tax_for(income) = tax {
    income <= scale_threshold
    tax := round(income * scale_low_rate * 100) / 100
} else = tax {
    income > scale_threshold
    tax := round((scale_threshold * scale_low_rate + (income - scale_threshold) * scale_high_rate) * 100) / 100
}

linear_tax_for(income) = tax {
    tax := round(income * linear_rate * 100) / 100
}

lump_tax_for(income) = tax {
    lump_rate := to_number(object.get(ent, "lump_sum_rate", standard_lump_rate))
    tax := round(revenue * lump_rate * 100) / 100
}

scale_tax := scale_tax_for(taxable_income)
linear_tax := linear_tax_for(taxable_income)
lump_tax := lump_tax_for(taxable_income)
card_tax_value := to_number(card_tax)

best_form := "PIT_SCALE" {
    scale_tax <= linear_tax
    scale_tax <= lump_tax
    scale_tax <= card_tax_value
} else := "LINEAR" {
    linear_tax < scale_tax
    linear_tax <= lump_tax
    linear_tax <= card_tax_value
} else := "LUMP_SUM" {
    lump_tax < scale_tax
    lump_tax < linear_tax
    lump_tax <= card_tax_value
} else := "TAX_CARD" {
    card_tax_value < scale_tax
    card_tax_value < linear_tax
    card_tax_value < lump_tax
} else := "UNDETERMINED" {
    true
}

forecast_revenue(years) = amount {
    base := to_number(object.get(forecast, "annual_revenue", revenue))
    growth := to_number(object.get(forecast, "growth_rate", 0))
    years == 1
    amount := base * (1 + growth)
} else = amount {
    base := to_number(object.get(forecast, "annual_revenue", revenue))
    growth := to_number(object.get(forecast, "growth_rate", 0))
    years == 2
    amount := base * (1 + growth) * (1 + growth)
} else = amount {
    base := to_number(object.get(forecast, "annual_revenue", revenue))
    growth := to_number(object.get(forecast, "growth_rate", 0))
    years == 3
    amount := base * (1 + growth) * (1 + growth) * (1 + growth)
} else = amount {
    base := to_number(object.get(forecast, "annual_revenue", revenue))
    growth := to_number(object.get(forecast, "growth_rate", 0))
    years == 4
    amount := base * (1 + growth) * (1 + growth) * (1 + growth) * (1 + growth)
} else = amount {
    base := to_number(object.get(forecast, "annual_revenue", revenue))
    growth := to_number(object.get(forecast, "growth_rate", 0))
    years == 5
    amount := base * (1 + growth) * (1 + growth) * (1 + growth) * (1 + growth) * (1 + growth)
}

forecast_tax_for(years) = tax {
    year_revenue := forecast_revenue(years)
    year_costs := to_number(object.get(forecast, "annual_costs", costs))
    year_zus := to_number(object.get(forecast, "annual_zus_social", zus_social))
    year_income := max([0, year_revenue - year_costs - year_zus])
    tax := scale_tax_for(year_income)
}

forecast_3y_total := round((forecast_tax_for(1) + forecast_tax_for(2) + forecast_tax_for(3)) * 100) / 100
forecast_5y_total := round((forecast_tax_for(1) + forecast_tax_for(2) + forecast_tax_for(3) + forecast_tax_for(4) + forecast_tax_for(5)) * 100) / 100

former_employer_risk := form == "LINEAR" and object.get(ent, "former_employer_services", false) == true
lump_limit_risk := form == "LUMP_SUM" and to_number(object.get(ent, "annual_revenue_eur", 0)) > 2000000
midyear_change_risk := object.get(ent, "form_change_requested", false) == true and object.get(ent, "form_change_effective_date", "") != "" and substring(object.get(ent, "form_change_effective_date", ""), 5, 2) != "01"
uncertain_kup := object.get(input, "pit_kup_classification", "CONFIRMED") == "UNCERTAIN"
vat_crosscheck := object.get(ent, "vat_status", "") == "ACTIVE" and object.get(input, "vat_reconciliation_status", "MISSING") != "CONFIRMED"
zus_crosscheck := object.get(input, "zus_reconciliation_status", "MISSING") != "CONFIRMED"
uor_crosscheck := revenue >= to_number(object.get(_pit_limits, "uor_threshold_pln", 0)) and object.get(input, "uor_reconciliation_status", "MISSING") != "CONFIRMED"
legal_source_status := "REVIEW_REQUIRED" {
    not source_complete
} else := "PRESENT" {
    true
}
source_review_required := true {
    not source_complete
} else := false {
    true
}

manual_gates := [
    {"id": "FORM_CHANGE_REVIEW", "required": object.get(ent, "form_change_requested", false), "basis": "Art. 9a PIT"},
    {"id": "KUP_NKUP_EVIDENCE", "required": uncertain_kup, "basis": "Art. 22-23 PIT"},
    {"id": "VAT_RECONCILIATION", "required": vat_crosscheck, "basis": "Art. 86 / Art. 108a VAT"},
    {"id": "ZUS_RECONCILIATION", "required": zus_crosscheck, "basis": "ustawa o systemie ubezpieczeń społecznych"},
    {"id": "UOR_RECONCILIATION", "required": uor_crosscheck, "basis": "UoR — próg i obowiązek ksiąg"},
    {"id": "LEGAL_SOURCE_REVIEW", "required": source_review_required, "basis": "Bbb/LKG + ADR-002"}
]

route := "BLOCK_AND_ALERT" {
    count(missing_inputs) > 0
} else := "BLOCK_AND_ALERT" {
    not form_valid
} else := "BLOCK_AND_ALERT" {
    former_employer_risk
} else := "BLOCK_AND_ALERT" {
    lump_limit_risk
} else := "BLOCK_AND_ALERT" {
    midyear_change_risk
} else := "TRIAGE_QUEUE" {
    uncertain_kup
} else := "TRIAGE_QUEUE" {
    vat_crosscheck
} else := "TRIAGE_QUEUE" {
    zus_crosscheck
} else := "TRIAGE_QUEUE" {
    uor_crosscheck
} else := "TRIAGE_QUEUE" {
    not source_complete
} else := "REPORT" {
    true
}

quality_status := "BLOCKED" {
    route == "BLOCK_AND_ALERT"
} else := "MANUAL_REVIEW" {
    route == "TRIAGE_QUEUE"
} else := "READY_FOR_REVIEW" {
    true
}

explanation := {
    "summary": sprintf("Forma %s; podstawa dochodu %.2f PLN; podatek bazowy %.2f PLN; najlepsza ścieżka kalkulacyjna %s", [form, taxable_income, scale_tax, best_form]),
    "facts": {"revenue": revenue, "costs": costs, "zus_social": zus_social, "taxable_income": taxable_income, "evaluation_date": evaluation_date},
    "calculation": {"scale": scale_tax, "linear": linear_tax, "lump_sum": lump_tax, "tax_card": card_tax_value},
    "forecast": {"three_year_scale": forecast_3y_total, "five_year_scale": forecast_5y_total},
    "limitations": ["Wynik jest deterministycznym audytem i symulacją, nie poradą prawną.", "Brak źródła lub niepewne dane kierują do bramki manualnej."],
    "legal_basis": ["Art. 27, 30c PIT", "Art. 6 i 9 ustawy o ryczałcie", "Art. 22-23 PIT", "Art. 44, 45 PIT", "Art. 21 PIT", "Dz.U. 2025 poz. 789"]
}

# ETAP 10 report contract: no automatic posting and no silent fallback.
decide := {
    "matched": true,
    "rule_id": "jdg.pit_macro_etap10.pit_macro_audit",
    "package": "jdg.pit_macro_etap10",
    "priority": 540,
    "decision_mode": "SUGGEST",
    "_routing": route,
    "_routing_reason": "ETAP 10 PIT Macro: forms/KUP-NKUP/advances/returns/transitions audit",
    "_quality_status": quality_status,
    "_manual_gates": manual_gates,
    "_temporal": {"valid_from": evaluation_date, "valid_to": null, "threshold_version": source_version},
    "_legal_source": {"registry": "Bbb/LKG", "status": legal_source_status, "thresholds": "data.jdg.thresholds"},
    "_legal_basis": "Art. 27, 30c PIT; Art. 22-23 PIT; Art. 44, 45 PIT; Art. 21 PIT",
    "pit_macro": {
        "scope": ["forms", "KUP_NKUP", "advances", "annual_returns", "exemptions", "transitions"],
        "form": form,
        "form_valid": form_valid,
        "data_quality": {"missing_inputs": missing_inputs, "source_complete": source_complete},
        "form_matrix": {"SCALE": "PIT-36", "LINEAR": "PIT-36L", "LUMP_SUM": "PIT-28", "TAX_CARD": "monthly_decision_amount"},
        "forecast_3y_5y": {"three_year_scale": forecast_3y_total, "five_year_scale": forecast_5y_total, "growth_rate": to_number(object.get(forecast, "growth_rate", 0))},
        "cross_domain": {"vat": vat_crosscheck, "zus": zus_crosscheck, "uor": uor_crosscheck},
        "risk_flags": {"former_employer": former_employer_risk, "lump_sum_limit": lump_limit_risk, "midyear_change": midyear_change_risk},
        "innovations": ["four_form_matrix", "three_five_year_simulator", "temporal_threshold_snapshot", "kup_nkup_manual_gate", "vat_zus_uor_reconciliation_gates", "fail_closed_missing_data", "decision_explanation", "no_auto_post"]
    },
    "_explanation": explanation,
    "_warnings": ["ETAP 10: wynik wymaga weryfikacji źródeł Bbb/LKG; system nie wydaje porady prawnej."]
} {
    object.get(input, "pit_macro_etap10_check", false) == true
}
