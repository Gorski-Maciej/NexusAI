# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 16

package jdg.hyper.wis

default decide := {"matched":false,"rule_id":"jdg.hyper.wis.no_match","package":"jdg.hyper.wis","priority":99999}

# jdg.hyper.wis.solidarity.levy.aggregate.alert_900k — Agregacja
decide :=   {"matched":true,"rule_id":"jdg.hyper.wis.solidarity.levy.aggregate.alert_900k","package":"jdg.hyper.wis","priority":1070,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Alert przy przekroczeniu 900k PLN — zbliżanie się do progu","_legal_basis":"R-ID","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.cn_code_ambiguous — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.cn_code_ambiguous","package":"jdg.hyper.wis","priority":1071,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kod CN niejednoznaczny (2+ możliwe stawki VAT) → zalecenie WIS","_legal_basis":"R1072","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.composite_product — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.composite_product","package":"jdg.hyper.wis","priority":1072,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Produkt złożony (zestaw) → niejednoznaczna klasyfikacja → zalecenie WIS","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.new_product_launch — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.new_product_launch","package":"jdg.hyper.wis","priority":1073,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nowy produkt na rynku bez utrwalonej klasyfikacji → zalecenie WIS","_legal_basis":"R1074","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.import_first_time — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.import_first_time","package":"jdg.hyper.wis","priority":1074,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pierwszy import towaru spoza UE → zalecenie WIS","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.contradictory_interpretations — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.contradictory_interpretations","package":"jdg.hyper.wis","priority":1075,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprzeczne interpretacje KIS dla podobnych towarów → zalecenie WIS","_legal_basis":"R1076","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.food_supplement_borderline — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.food_supplement_borderline","package":"jdg.hyper.wis","priority":1076,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Suplementy diety na granicy żywność/farmaceutyk → zalecenie WIS","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.software_vs_service — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.software_vs_service","package":"jdg.hyper.wis","priority":1077,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Oprogramowanie vs usługa — niejednoznaczność → zalecenie WIS","_legal_basis":"R1078","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.eligibility.annual_turnover_50k — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.eligibility.annual_turnover_50k","package":"jdg.hyper.wis","priority":1078,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roczny obrót towarem > 50k PLN → próg istotności dla WIS","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.application.cost.40pln — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.application.cost.40pln","package":"jdg.hyper.wis","priority":1079,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Opłata za wniosek WIS = 40 PLN za każdy towar/usługę","_legal_basis":"R1080","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.application.form.electronic_only — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.application.form.electronic_only","package":"jdg.hyper.wis","priority":1080,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wniosek WIS-W tylko elektronicznie przez e-US","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.application.required_fields — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.application.required_fields","package":"jdg.hyper.wis","priority":1081,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Opis towaru, kod CN, proponowana stawka, uzasadnienie","_legal_basis":"R1082","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.application.sample_may_be_required — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.application.sample_may_be_required","package":"jdg.hyper.wis","priority":1082,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dyrektor KIS może zażądać próbki towaru","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.validity.5_years_from_issue — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.validity.5_years_from_issue","package":"jdg.hyper.wis","priority":1083,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WIS ważna 5 lat od daty wydania","_legal_basis":"R1084","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.validity.early_expiry.regulation_change — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.validity.early_expiry.regulation_change","package":"jdg.hyper.wis","priority":1084,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana przepisów → WIS traci moc z dniem zmiany","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.wis.wis.validity.early_expiry.cjeu_judgment — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.wis.wis.validity.early_expiry.cjeu_judgment","package":"jdg.hyper.wis","priority":1085,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wyrok TSUE zmieniający klasyfikację → WIS traci moc","_legal_basis":"R1086","_warnings":[]} {
    object.get(input.invoice, "wis_required", false) == true
}
