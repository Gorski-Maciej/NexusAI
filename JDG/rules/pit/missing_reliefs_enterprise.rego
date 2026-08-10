# NexusAI JDG — Report 04 PIT missing reliefs
# Documentation only; this is not an OPA annotation block.
# Sources: RAPORT_04_PIT_CORE.txt; Art. 9, 26, 26ec, 26gb and 27f PIT.
# Contract: recommendations only; no automatic filing or tax decision.

package jdg.pit.missing_reliefs

import future.keywords.in
import future.keywords.if
import data.jdg.thresholds

default decide := {
    "matched": false,
    "rule_id": "jdg.pit.missing_reliefs.no_match",
    "package": "jdg.pit.missing_reliefs",
    "priority": 99999
}

form_allows_relief(form) if {
    form in {"PIT_SCALE", "LINEAR"}
}

evaluation_year(input_data) := to_number(substring(object.get(input_data, "evaluation_datetime", "2026-01-01"), 0, 4))

third_relief(count, amount) := amount if {
    count >= 3
} else := 0 if {
    count < 3
}

loss_year_label(amount, year) := [year] if {
    amount > 0
} else := [] if {
    amount <= 0
}

loss_expiring(amount) := amount if {
    amount > 0
} else := 0 if {
    amount <= 0
}

loss_routing(amount) := "TRIAGE_QUEUE" if {
    amount > 50000
} else := "" if {
    amount <= 50000
}

loss_warning_lines(expiring) := [sprintf("   ⚠️ PRZEDAWNIA SIĘ: %.0f PLN — ostatni rok na rozliczenie!", [expiring])] if {
    expiring > 0
} else := [] if {
    expiring <= 0
}

internet_routing(years_used) := "TRIAGE_QUEUE" if {
    years_used == 1
} else := "" if {
    years_used != 1
}

internet_warning(years_used) := "To ostatni rok tej ulgi — wykorzystaj ją po sprawdzeniu dokumentów." if {
    years_used == 1
} else := "Pamiętaj: ulga internetowa działa tylko przez dwa kolejne lata." if {
    years_used == 0
}

child_routing(total_relief) := "TRIAGE_QUEUE" if {
    total_relief > 5000
} else := "" if {
    total_relief <= 5000
}

expansion_routing(costs) := "TRIAGE_QUEUE" if {
    costs > 500000
} else := "" if {
    costs <= 500000
}

robotization_routing(costs) := "TRIAGE_QUEUE" if {
    costs > 200000
} else := "" if {
    costs <= 200000
}

# Active loss carry-forward. It is evaluated only when at least one loss field
# is present and positive; normal PIT traffic remains no_match.
decide := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.loss_carry_forward_active",
    "package": "jdg.pit.missing_reliefs",
    "priority": 400,
    "recommendation_only": true,
    "requires_documentation": true,
    "evaluation_year": evaluation_year(input),
    "relief_type": "LOSS_CARRY_FORWARD",
    "pit_form": pit_form,
    "loss_total_available": total_loss_available,
    "loss_max_deductible_this_year": max_deduction,
    "loss_actual_deducted": actual_deduction,
    "loss_remaining_after_year": remaining_loss,
    "loss_expiring_this_year": expiring_loss,
    "loss_years_tracked": loss_years,
    "_routing": loss_routing(expiring_loss),
    "_routing_reason": sprintf("Strata: dostępne %.2f PLN; maksymalne odliczenie %.2f PLN; odliczono %.2f PLN; pozostało %.2f PLN.",
        [total_loss_available, max_deduction, actual_deduction, remaining_loss]),
    "_legal_basis": "Art. 9 ust. 3 PIT (strata — pięć lat, maksymalnie 50% dochodu rocznie)",
    "_warnings": array.concat([
        "📊 Aktywna strata podatkowa — wynik jest rekomendacją do weryfikacji dokumentów."
    ], array.concat(loss_warning_lines(expiring_loss), [
        "Kolejność i możliwość odliczenia wymagają potwierdzenia w dokumentacji rocznej."
    ]))
} if {
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    form_allows_relief(pit_form)
    annual_income := max([0, object.get(input.jdg_entrepreneur, "annual_taxable_income", 0)])
    annual_income > 0
    loss_2021 := max([0, object.get(input.jdg_entrepreneur, "tax_loss_2021", 0)])
    loss_2022 := max([0, object.get(input.jdg_entrepreneur, "tax_loss_2022", 0)])
    loss_2023 := max([0, object.get(input.jdg_entrepreneur, "tax_loss_2023", 0)])
    loss_2024 := max([0, object.get(input.jdg_entrepreneur, "tax_loss_2024", 0)])
    loss_2025 := max([0, object.get(input.jdg_entrepreneur, "tax_loss_2025", 0)])
    total_loss_available := loss_2021 + loss_2022 + loss_2023 + loss_2024 + loss_2025
    total_loss_available > 0
    max_deduction := annual_income * object.get(thresholds.pit, "loss_carry_forward_max_pct", 0.50)
    actual_deduction := min([total_loss_available, max_deduction])
    remaining_loss := total_loss_available - actual_deduction
    expiring_loss := loss_expiring(loss_2021)

    loss_years := array.concat(loss_year_label(loss_2021, "2021"),
        array.concat(loss_year_label(loss_2022, "2022"),
        array.concat(loss_year_label(loss_2023, "2023"),
        array.concat(loss_year_label(loss_2024, "2024"), loss_year_label(loss_2025, "2025")))))
}

# Explicit audit request with no available loss balance.
else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.loss_fully_used",
    "package": "jdg.pit.missing_reliefs",
    "priority": 401,
    "recommendation_only": true,
    "requires_documentation": true,
    "evaluation_year": evaluation_year(input),
    "pit_form": object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE"),
    "loss_status": "EXHAUSTED",
    "_routing": "",
    "_routing_reason": "Audyt straty: brak nierozliczonego salda w przekazanych danych.",
    "_legal_basis": "Art. 9 ust. 3 PIT",
    "_warnings": ["Brak nierozliczonej straty w przekazanych danych; potwierdź zeznania za poprzednie lata."]
} if {
    input.pit_loss_check == true
    object.get(input.jdg_entrepreneur, "has_unresolved_losses", false) == false
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.rehabilitation",
    "package": "jdg.pit.missing_reliefs",
    "priority": 650,
    "recommendation_only": true,
    "requires_documentation": true,
    "evaluation_year": evaluation_year(input),
    "relief_type": "REHABILITATION",
    "relief_deductible": rehab_expenses,
    "relief_disability_group": disability_group,
    "relief_requires_documentation": true,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": sprintf("Ulga rehabilitacyjna: %.2f PLN; wymagana weryfikacja uprawnienia i dokumentów.", [rehab_expenses]),
    "_legal_basis": "Art. 26 ust. 1 pkt 6, ust. 7a–7g PIT",
    "_warnings": ["Rekomendacja: potwierdź orzeczenie/warunki ustawowe oraz imienne faktury lub rachunki."]
} if {
    input.pit_rehabilitation_check == true
    input.jdg_entrepreneur.has_disability == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    form_allows_relief(pit_form)
    disability_group := object.get(input.jdg_entrepreneur, "disability_group", "I")
    meds := max([0, object.get(input.jdg_entrepreneur, "rehab_meds_expenses", 0)])
    treatments := max([0, object.get(input.jdg_entrepreneur, "rehab_treatments_expenses", 0)])
    equipment := max([0, object.get(input.jdg_entrepreneur, "rehab_equipment_expenses", 0)])
    car_limit := object.get(thresholds.pit, "rehab_car_limit", 2280)
    car := min([max([0, object.get(input.jdg_entrepreneur, "rehab_car_expenses", 0)]), car_limit])
    rehab_expenses := meds + treatments + equipment + car
    rehab_expenses > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.internet",
    "package": "jdg.pit.missing_reliefs",
    "priority": 660,
    "recommendation_only": true,
    "requires_documentation": true,
    "evaluation_year": evaluation_year(input),
    "relief_type": "INTERNET",
    "relief_limit": internet_limit,
    "relief_deductible": min([internet_expenses, internet_limit]),
    "relief_max_years": 2,
    "relief_years_used": years_used,
    "relief_years_remaining": 2 - years_used,
    "_routing": internet_routing(years_used),
    "_routing_reason": sprintf("Ulga internetowa: %.2f PLN; rok %d z 2.", [min([internet_expenses, internet_limit]), years_used + 1]),
    "_legal_basis": "Art. 26 ust. 1 pkt 6a PIT",
    "_warnings": [internet_warning(years_used)]
} if {
    input.pit_internet_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    form_allows_relief(pit_form)
    internet_expenses := max([0, object.get(input.jdg_entrepreneur, "internet_expenses_annual", 0)])
    internet_expenses > 0
    years_used := object.get(input.jdg_entrepreneur, "internet_relief_years_used", 0)
    years_used >= 0
    years_used < 2
    internet_limit := object.get(thresholds.pit, "internet_relief_limit", 760)
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.internet_exhausted",
    "package": "jdg.pit.missing_reliefs",
    "priority": 661,
    "recommendation_only": true,
    "requires_documentation": true,
    "evaluation_year": evaluation_year(input),
    "relief_type": "INTERNET",
    "internet_relief_exhausted": true,
    "_routing": "",
    "_routing_reason": "Ulga internetowa: wykorzystany limit dwóch lat.",
    "_legal_basis": "Art. 26 ust. 1 pkt 6a PIT",
    "_warnings": ["Ulga internetowa została oznaczona jako wykorzystana; nie odliczaj jej ponownie bez korekty danych."]
} if {
    input.pit_internet_check == true
    object.get(input.jdg_entrepreneur, "internet_relief_years_used", 0) >= 2
    object.get(input.jdg_entrepreneur, "internet_expenses_annual", 0) > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.blood_donation",
    "package": "jdg.pit.missing_reliefs",
    "priority": 670,
    "recommendation_only": true,
    "requires_documentation": true,
    "evaluation_year": evaluation_year(input),
    "relief_type": "BLOOD_DONATION",
    "relief_blood_liters": blood_liters,
    "relief_blood_value_per_liter": blood_value_per_liter,
    "relief_deductible": min([blood_value, max_deduction]),
    "relief_max_percent_income": donation_limit_pct * 100,
    "_routing": "",
    "_routing_reason": sprintf("Krwiodawstwo: %.2f PLN po zastosowaniu limitu dochodu.", [min([blood_value, max_deduction])]),
    "_legal_basis": "Art. 26 ust. 1 pkt 9c PIT",
    "_warnings": ["Wymagane zaświadczenie z centrum krwiodawstwa i potwierdzenie limitu odliczeń od dochodu."]
} if {
    input.pit_blood_donation_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    form_allows_relief(pit_form)
    blood_liters := max([0, object.get(input.jdg_entrepreneur, "blood_donation_liters", 0)])
    blood_liters > 0
    blood_value_per_liter := object.get(thresholds.pit, "blood_value_per_liter", 130)
    blood_value := blood_liters * blood_value_per_liter
    annual_income := max([0, object.get(input.jdg_entrepreneur, "annual_taxable_income", 0)])
    donation_limit_pct := object.get(thresholds.pit, "donation_limit_pct", 0.06)
    max_deduction := annual_income * donation_limit_pct
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.child_tax_credit",
    "package": "jdg.pit.missing_reliefs",
    "priority": 680,
    "recommendation_only": true,
    "requires_documentation": true,
    "evaluation_year": evaluation_year(input),
    "relief_type": "CHILD_TAX_CREDIT",
    "relief_child_count_total": total_children,
    "relief_child_eligible_count": total_children,
    "relief_amount_per_first_second": first_second_amount,
    "relief_amount_per_third": third_amount,
    "relief_amount_per_fourth_plus": fourth_plus_amount,
    "relief_total_deductible": total_relief,
    "_routing": child_routing(total_relief),
    "_routing_reason": sprintf("Ulga na dzieci: %d dzieci; odliczenie %.2f PLN.", [total_children, total_relief]),
    "_legal_basis": "Art. 27f PIT",
    "_warnings": ["Ulga dotyczy wyłącznie skali PIT i wymaga sprawdzenia warunków opieki oraz dokumentów dzieci."]
} if {
    input.pit_child_check == true
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    total_children := object.get(input.jdg_entrepreneur, "children_count", 0)
    total_children > 0
    first_second_amount := object.get(thresholds.pit, "family_relief_amount_per_child", 1112.04)
    third_amount := object.get(thresholds.pit, "family_relief_amount_third_child", 2000.04)
    fourth_plus_amount := object.get(thresholds.pit, "family_relief_amount_fourth_plus", 2700)
    first_two := min([total_children, 2]) * first_second_amount
    third := third_relief(total_children, third_amount)
    fourth_plus := max([total_children - 3, 0]) * fourth_plus_amount
    total_relief := first_two + third + fourth_plus
    total_relief > 0
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.expansion",
    "package": "jdg.pit.missing_reliefs",
    "priority": 690,
    "recommendation_only": true,
    "requires_documentation": true,
    "evaluation_year": evaluation_year(input),
    "relief_type": "EXPANSION",
    "relief_limit": expansion_limit,
    "relief_deductible": min([expansion_costs, expansion_limit]),
    "relief_carry_forward_years": 6,
    "_routing": expansion_routing(expansion_costs),
    "_routing_reason": sprintf("Ulga ekspansyjna: %.2f PLN z limitu %.2f PLN.", [min([expansion_costs, expansion_limit]), expansion_limit]),
    "_legal_basis": "Art. 26ec PIT",
    "_warnings": ["Prowadź odrębną ewidencję kosztów i potwierdź spełnienie ustawowych warunków wzrostu sprzedaży."]
} if {
    input.pit_expansion_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    form_allows_relief(pit_form)
    trade_fairs := max([0, object.get(input.jdg_entrepreneur, "expansion_trade_fairs_costs", 0)])
    ads_abroad := max([0, object.get(input.jdg_entrepreneur, "expansion_ads_abroad_costs", 0)])
    export_prep := max([0, object.get(input.jdg_entrepreneur, "expansion_export_prep_costs", 0)])
    expansion_costs := trade_fairs + ads_abroad + export_prep
    expansion_costs > 0
    expansion_limit := object.get(thresholds.pit, "expansion_relief_max_costs", 1000000)
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.robotization",
    "package": "jdg.pit.missing_reliefs",
    "priority": 700,
    "recommendation_only": true,
    "requires_documentation": true,
    "evaluation_year": evaluation_year(input),
    "relief_type": "ROBOTIZATION",
    "relief_percent": robotization_rate * 100,
    "relief_total_qualified": total_qualified,
    "relief_deductible": total_qualified * robotization_rate,
    "relief_requires_documentation": true,
    "_routing": robotization_routing(total_qualified),
    "_routing_reason": sprintf("Ulga robotyzacyjna: %.2f PLN kosztów; odliczenie %.2f PLN.", [total_qualified, total_qualified * robotization_rate]),
    "_legal_basis": "Art. 26gb PIT",
    "_warnings": ["Potwierdź, że koszty dotyczą kwalifikowanych robotów i są udokumentowane; wynik nie jest automatyczną decyzją podatkową."]
} if {
    input.pit_robotization_check == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    form_allows_relief(pit_form)
    robot_purchase := max([0, object.get(input.jdg_entrepreneur, "robotization_purchase_costs", 0)])
    robot_training := max([0, object.get(input.jdg_entrepreneur, "robotization_training_costs", 0)])
    robot_maintenance := max([0, object.get(input.jdg_entrepreneur, "robotization_maintenance_first_year", 0)])
    total_qualified := robot_purchase + robot_training + robot_maintenance
    total_qualified > 0
    robotization_rate := object.get(thresholds.pit, "robotization_relief_rate", 0.50)
}

else := {
    "matched": true,
    "rule_id": "jdg.pit.missing_reliefs.coverage_summary",
    "package": "jdg.pit.missing_reliefs",
    "priority": 999,
    "recommendation_only": true,
    "requires_documentation": true,
    "evaluation_year": evaluation_year(input),
    "relief_coverage": {
        "LOSS_CARRY_FORWARD": "active loss audit",
        "REHABILITATION": "documentation-gated",
        "INTERNET": "two-year limit",
        "BLOOD_DONATION": "income-limited",
        "CHILD_TAX_CREDIT": "scale-only",
        "EXPANSION": "cost and legal-condition audit",
        "ROBOTIZATION": "qualified-cost audit"
    },
    "total_new_rules": 7,
    "generated_from": "RAPORT_04_PIT_CORE.txt",
    "_routing": "",
    "_routing_reason": "Jawne podsumowanie pokrycia raportu 04.",
    "_legal_basis": "Art. 9, 26, 26ec, 26gb and 27f PIT",
    "_warnings": ["Podsumowanie ma charakter audytowy; rekomendacje wymagają dokumentów i weryfikacji."]
} if {
    input.pit_missing_reliefs_summary == true
}
