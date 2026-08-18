# Generated from Plan OPA 33 — Micro-rules for agricultural_tax
# 2026-07-13 14:58:41
# Rules: 5 (new, deduplicated)

package jdg.micro.agricultural_tax

default decide := {"matched":false,"rule_id":"jdg.micro.agricultural_tax.no_match","package":"jdg.micro.agricultural_tax","priority":99999}

# jdg.agricultural_tax.r1 — `agricultural_tax_jdg_farmland`: JDG posiadająca grunt rolny → Podatek rolny od hektara przeliczeniowego
decide :=   {"matched":true,"rule_id":"jdg.agricultural_tax.r1","package":"jdg.micro.agricultural_tax","priority":7500,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG posiadająca grunt rolny","_legal_basis":"Ustawa o podatku rolnym","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "land_owned_sqm", 0) > 0
}

# jdg.agricultural_tax.r2 — `agricultural_tax_rate_per_ha`: Stawka = 2,5 q żyta x cena skupu żyta (GUS) → Stawka zmienna rocznie
else :=   {"matched":true,"rule_id":"jdg.agricultural_tax.r2","package":"jdg.micro.agricultural_tax","priority":7501,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawka = 2,5 q żyta x cena skupu żyta (GUS)","_legal_basis":"Art. 4 ustawy o podatku rolnym","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "land_owned_sqm", 0) > 0
}

# jdg.agricultural_tax.r3 — `agricultural_tax_exemption_small`: Gospodarstwo < 1 ha (powierzchnia użytków rolnych) → Zwolnienie z podatku rolnego
else :=   {"matched":true,"rule_id":"jdg.agricultural_tax.r3","package":"jdg.micro.agricultural_tax","priority":7502,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Gospodarstwo < 1 ha (powierzchnia użytków rolnych)","_legal_basis":"Art. 12 ustawy o podatku rolnym","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "land_owned_sqm", 0) > 0
}

# jdg.agricultural_tax.r4 — `agricultural_tax_classification`: Grunt rolny pod zabudowę (działalność gospodarcza) -> podatek od nieruchomości → WYŁĄCZENIE z podatku rolnego (przejś...
else :=   {"matched":true,"rule_id":"jdg.agricultural_tax.r4","package":"jdg.micro.agricultural_tax","priority":7503,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Grunt rolny pod zabudowę (działalność gospodarcza) -> podatek od nieruchomości","_legal_basis":"Art. 2 ustawy o podatku rolnym","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "land_owned_sqm", 0) > 0
}

# jdg.agricultural_tax.r5 — `agricultural_tax_deadline_31_jan`: Deklaracja do 31 stycznia; płatność w 4 ratach → Termin roczny
else :=   {"matched":true,"rule_id":"jdg.agricultural_tax.r5","package":"jdg.micro.agricultural_tax","priority":7504,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Deklaracja do 31 stycznia; płatność w 4 ratach","_legal_basis":"Art. 6 ustawy o podatku rolnym","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "land_owned_sqm", 0) > 0
}
