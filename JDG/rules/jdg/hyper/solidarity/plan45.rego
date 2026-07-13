# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 11

package jdg.hyper.solidarity

default decide := {"matched":false,"rule_id":"jdg.hyper.solidarity.no_match","package":"jdg.hyper.solidarity","priority":99999}

# jdg.hyper.solidarity.solidarity.levy.income.ip_box — Źródło
decide :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.income.ip_box","package":"jdg.hyper.solidarity","priority":1050,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochód z IP Box (5%) wlicza się do podstawy","_legal_basis":"R1051","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.income.capital_gains — Źródło
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.income.capital_gains","package":"jdg.hyper.solidarity","priority":1051,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochody kapitałowe (19%) wlicza się do podstawy","_legal_basis":"","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.income.foreign — Źródło
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.income.foreign","package":"jdg.hyper.solidarity","priority":1052,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochody zagraniczne (opodatkowane i zwolnione) wlicza się do podstawy","_legal_basis":"R1053","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.zus.social.exclusion — Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.zus.social.exclusion","package":"jdg.hyper.solidarity","priority":1053,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Składki ZUS społeczne (emerytalne + rentowe) POMNIEJSZAJĄ dochód","_legal_basis":"","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.zus.health.no_exclusion — Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.zus.health.no_exclusion","package":"jdg.hyper.solidarity","priority":1054,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Składka zdrowotna NIE pomniejsza dochodu dla celów daniny","_legal_basis":"R1055","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.exemption.metoda_wylaczenia — Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.exemption.metoda_wylaczenia","package":"jdg.hyper.solidarity","priority":1055,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochody zwolnione metodą wyłączenia z progresją NIE wlicza się","_legal_basis":"","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.exemption.foreign_tax_credit — Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.exemption.foreign_tax_credit","package":"jdg.hyper.solidarity","priority":1056,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochody opodatkowane metodą odliczenia — wlicza się, ale z korektą","_legal_basis":"R1057","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.spouse.individual_calculation — Indywidualnie
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.spouse.individual_calculation","package":"jdg.hyper.solidarity","priority":1057,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Każdy małżonek oblicza osobno (nawet przy wspólnym rozliczeniu)","_legal_basis":"","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.spouse.no_income_transfer — Indywidualnie
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.spouse.no_income_transfer","package":"jdg.hyper.solidarity","priority":1058,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nie można przenieść dochodu na małżonka dla uniknięcia daniny","_legal_basis":"R1059","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.payment.deadline.april30 — Termin
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.payment.deadline.april30","package":"jdg.hyper.solidarity","priority":1059,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zapłata do 30 kwietnia następnego roku","_legal_basis":"","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.solidarity.solidarity.levy.payment.no_advances — Termin
else :=   {"matched":true,"rule_id":"jdg.hyper.solidarity.solidarity.levy.payment.no_advances","package":"jdg.hyper.solidarity","priority":1060,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak zaliczek — jednorazowa płatność roczna","_legal_basis":"R1061","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}
