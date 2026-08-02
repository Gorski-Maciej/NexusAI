# Generated from Plan OPA 33 — Micro-rules for prop_transport
# 2026-07-13 14:58:41
# Rules: 5 (new, deduplicated)

package jdg.micro.prop_transport

default decide := {"matched":false,"rule_id":"jdg.micro.prop_transport.no_match","package":"jdg.micro.prop_transport","priority":99999}

# jdg.prop_transport.r1 — `transport_tax_truck_above_3_5t`: Samochód ciężarowy o DMC > 3,5 tony → Podatek od środków transportowych
decide :=   {"matched":true,"rule_id":"jdg.prop_transport.r1","package":"jdg.micro.prop_transport","priority":7550,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Samochód ciężarowy o DMC > 3,5 tony","_legal_basis":"Art. 8 u.p.o.l.","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "home_office_area_sqm", 0) > 0; object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.prop_transport.r2 — `transport_tax_truck_12t_above`: Samochód ciężarowy o DMC >= 12 ton → Podatek wyższy (zależny od emisji Euro)
else :=   {"matched":true,"rule_id":"jdg.prop_transport.r2","package":"jdg.micro.prop_transport","priority":7551,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Samochód ciężarowy o DMC >= 12 ton","_legal_basis":"Art. 8 ust. 2 u.p.o.l.","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "home_office_area_sqm", 0) > 0; object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.prop_transport.r3 — `transport_tax_trailer_semi`: Przyczepa, naczepa o DMC > 7 ton → Podatek od przyczep
else :=   {"matched":true,"rule_id":"jdg.prop_transport.r3","package":"jdg.micro.prop_transport","priority":7552,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przyczepa, naczepa o DMC > 7 ton","_legal_basis":"Art. 8 ust. 3 u.p.o.l.","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "home_office_area_sqm", 0) > 0; object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.prop_transport.r4 — `transport_tax_bus_seats_above_22`: Autobus o liczbie miejsc > 22 → Podatek od autobusów
else :=   {"matched":true,"rule_id":"jdg.prop_transport.r4","package":"jdg.micro.prop_transport","priority":7553,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Autobus o liczbie miejsc > 22","_legal_basis":"Art. 8 ust. 4 u.p.o.l.","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "home_office_area_sqm", 0) > 0; object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.prop_transport.r5 — `transport_tax_deadline_31_jan`: Deklaracja DT-1 do 31 stycznia; płatność w 2 ratach (15 mar, 15 wrz) → Termin
else :=   {"matched":true,"rule_id":"jdg.prop_transport.r5","package":"jdg.micro.prop_transport","priority":7554,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Deklaracja DT-1 do 31 stycznia; płatność w 2 ratach (15 mar, 15 wrz)","_legal_basis":"Art. 9 u.p.o.l.","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "home_office_area_sqm", 0) > 0; object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}
