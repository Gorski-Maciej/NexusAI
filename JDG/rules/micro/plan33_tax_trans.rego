# Generated from Plan OPA 33 — Micro-rules for tax_trans
# 2026-07-13 14:58:41
# Rules: 10 (new, deduplicated)

package jdg.micro.tax_trans

default decide := {"matched":false,"rule_id":"jdg.micro.tax_trans.no_match","package":"jdg.micro.tax_trans","priority":99999}

# jdg.tax_trans.r1 — `transport_tax_subject_truck_3_5t`: Samochod ciezarowy o DMC > 3.5t → Zalezy od DMC
decide :=   {"matched":true,"rule_id":"jdg.tax_trans.r1","package":"jdg.micro.tax_trans","priority":7400,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Samochod ciezarowy o DMC > 3.5t","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.tax_trans.r10 — `transport_tax_sale_during_year`: Sprzedaz -> podatek do konca miesiaca sprzedazy → Pro rata
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r10","package":"jdg.micro.tax_trans","priority":7401,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprzedaz -> podatek do konca miesiaca sprzedazy","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.tax_trans.r2 — `transport_tax_subject_bus`: Autobus (powyzej 9 miejsc) → Zalezy od liczby miejsc
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r2","package":"jdg.micro.tax_trans","priority":7402,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Autobus (powyzej 9 miejsc)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.tax_trans.r3 — `transport_tax_subject_trailer`:  → Zalezy od DMC
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r3","package":"jdg.micro.tax_trans","priority":7403,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.tax_trans.r4 — `transport_tax_subject_tractor`: Ciagnik siodlowy i balastowy → Zalezy od DMC
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r4","package":"jdg.micro.tax_trans","priority":7404,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ciagnik siodlowy i balastowy","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.tax_trans.r5 — `transport_tax_rate_municipal`: Stawki uchwala rada gminy → Ograniczone MF
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r5","package":"jdg.micro.tax_trans","priority":7405,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawki uchwala rada gminy","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.tax_trans.r6 — `transport_tax_deadline_2_raty`: Dwie raty: do 15. marca i 15. wrzesnia → Terminy
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r6","package":"jdg.micro.tax_trans","priority":7406,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dwie raty: do 15. marca i 15. wrzesnia","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.tax_trans.r7 — `transport_tax_declaration_deadline`: Deklaracja DT-1 do 31 stycznia → Deklaracja
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r7","package":"jdg.micro.tax_trans","priority":7407,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Deklaracja DT-1 do 31 stycznia","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.tax_trans.r8 — `transport_tax_exemption_hybrid`: Zwolnienie: pojazdy hybrydowe, elektryczne, gazowe (gminne) → Mozliwe zwolnienie
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r8","package":"jdg.micro.tax_trans","priority":7408,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwolnienie: pojazdy hybrydowe, elektryczne, gazowe (gminne)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.tax_trans.r9 — `transport_tax_purchase_during_year`: Zakup w ciagu roku -> podatek od nastepnego miesiaca → Pro rata
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r9","package":"jdg.micro.tax_trans","priority":7409,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zakup w ciagu roku -> podatek od nastepnego miesiaca","_legal_basis":"","_warnings":[]} {
    true
}
