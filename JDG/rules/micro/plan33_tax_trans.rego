# Generated from Plan OPA 33 — Micro-rules for tax_trans
# 2026-07-13 14:58:41
# Rules: 10 (new, deduplicated)

package jdg.micro.tax_trans

default decide := {"matched":false,"rule_id":"jdg.micro.tax_trans.no_match","package":"jdg.micro.tax_trans","priority":99999}

# jdg.tax_trans.r1 — `transport_tax_subject_truck_3_5t`: Samochod ciezarowy o DMC > 3.5t → Zalezy od DMC
decide :=   {"matched":true,"rule_id":"jdg.tax_trans.r1","package":"jdg.micro.tax_trans","priority":7400,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Samochod ciezarowy o DMC > 3.5t","_legal_basis":"Ustawa o podatkach i opłatach lokalnych (Art. 8-13)","_warnings":["[MICRO] Samochod ciezarowy o DMC > 3.5t"]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.tax_trans.r10 — `transport_tax_sale_during_year`: Sprzedaz -> podatek do konca miesiaca sprzedazy → Pro rata
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r10","package":"jdg.micro.tax_trans","priority":7401,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprzedaz -> podatek do konca miesiaca sprzedazy","_legal_basis":"Ustawa o podatkach i opłatach lokalnych (Art. 8-13)","_warnings":["[MICRO] Sprzedaz -> podatek do konca miesiaca sprzedazy"]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.tax_trans.r2 — `transport_tax_subject_bus`: Autobus (powyzej 9 miejsc) → Zalezy od liczby miejsc
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r2","package":"jdg.micro.tax_trans","priority":7402,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Autobus (powyzej 9 miejsc)","_legal_basis":"Ustawa o podatkach i opłatach lokalnych (Art. 8-13)","_warnings":["[MICRO] Autobus (powyzej 9 miejsc)"]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.tax_trans.r3 — `transport_tax_subject_trailer`:  → Zalezy od DMC
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r3","package":"jdg.micro.tax_trans","priority":7403,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"","_legal_basis":"Ustawa o podatkach i opłatach lokalnych (Art. 8-13)","_warnings":["[MICRO] tax_trans/r3 — walidacja automatyczna"]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.tax_trans.r4 — `transport_tax_subject_tractor`: Ciagnik siodlowy i balastowy → Zalezy od DMC
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r4","package":"jdg.micro.tax_trans","priority":7404,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ciagnik siodlowy i balastowy","_legal_basis":"Ustawa o podatkach i opłatach lokalnych (Art. 8-13)","_warnings":["[MICRO] Ciagnik siodlowy i balastowy"]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.tax_trans.r5 — `transport_tax_rate_municipal`: Stawki uchwala rada gminy → Ograniczone MF
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r5","package":"jdg.micro.tax_trans","priority":7405,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawki uchwala rada gminy","_legal_basis":"Ustawa o podatkach i opłatach lokalnych (Art. 8-13)","_warnings":["[MICRO] Stawki uchwala rada gminy"]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.tax_trans.r6 — `transport_tax_deadline_2_raty`: Dwie raty: do 15. marca i 15. wrzesnia → Terminy
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r6","package":"jdg.micro.tax_trans","priority":7406,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dwie raty: do 15. marca i 15. wrzesnia","_legal_basis":"Ustawa o podatkach i opłatach lokalnych (Art. 8-13)","_warnings":["[MICRO] Dwie raty: do 15. marca i 15. wrzesnia"]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.tax_trans.r7 — `transport_tax_declaration_deadline`: Deklaracja DT-1 do 31 stycznia → Deklaracja
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r7","package":"jdg.micro.tax_trans","priority":7407,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Deklaracja DT-1 do 31 stycznia","_legal_basis":"Ustawa o podatkach i opłatach lokalnych (Art. 8-13)","_warnings":["[MICRO] Deklaracja DT-1 do 31 stycznia"]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.tax_trans.r8 — `transport_tax_exemption_hybrid`: Zwolnienie: pojazdy hybrydowe, elektryczne, gazowe (gminne) → Mozliwe zwolnienie
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r8","package":"jdg.micro.tax_trans","priority":7408,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwolnienie: pojazdy hybrydowe, elektryczne, gazowe (gminne)","_legal_basis":"Ustawa o podatkach i opłatach lokalnych (Art. 8-13)","_warnings":["[MICRO] Zwolnienie: pojazdy hybrydowe, elektryczne, gazowe (gminne)"]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

    true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  L-TR-1: Progi DMC i stawki podatku transportowego (6 reguł) P24          ║
# ║  Legal basis: Art. 8-13 ustawy o podatkach i opłatach lokalnych            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# jdg.tax_trans.r11 — `transport_tax_dmc_threshold_3_5_12t`
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r11","package":"jdg.micro.tax_trans","priority":7410,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"L-TR-1: Próg DMC 3.5t-12t — stawka wg uchwały rady gminy (max MF ~2800 PLN/rok)","_legal_basis":"Art. 8 pkt 1 ustawy o podatkach i opłatach lokalnych","_warnings":["[MICRO] L-TR-1: Ciężarowy 3.5-12t DMC — podatek wg uchwały rady gminy."]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.tax_trans.r12 — `transport_tax_dmc_threshold_above_12t`
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r12","package":"jdg.micro.tax_trans","priority":7411,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"L-TR-1: Próg DMC >12t — stawka wyższa (max MF ~3500 PLN/rok)","_legal_basis":"Art. 8 pkt 2 ustawy o podatkach i opłatach lokalnych","_warnings":["[MICRO] L-TR-1: Ciężarowy >12t DMC — podatek wyższy."]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.tax_trans.r13 — `transport_tax_tractor_unit`
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r13","package":"jdg.micro.tax_trans","priority":7412,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"L-TR-1: Ciągnik siodłowy/balastowy — podatek transportowy","_legal_basis":"Art. 8 pkt 3 ustawy o podatkach i opłatach lokalnych","_warnings":["[MICRO] L-TR-1: Ciągnik siodłowy i balastowy DMC >3.5t."]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.tax_trans.r14 — `transport_tax_trailer`
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r14","package":"jdg.micro.tax_trans","priority":7413,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"L-TR-1: Przyczepa/naczepa DMC >7t — podatek transportowy","_legal_basis":"Art. 8 pkt 4 ustawy o podatkach i opłatach lokalnych","_warnings":["[MICRO] L-TR-1: Przyczepa/naczepa DMC >7t."]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.tax_trans.r15 — `transport_tax_bus_threshold`
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r15","package":"jdg.micro.tax_trans","priority":7414,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"L-TR-1: Autobus >9 miejsc — podatek zależny od liczby miejsc","_legal_basis":"Art. 8 pkt 5 ustawy o podatkach i opłatach lokalnych","_warnings":["[MICRO] L-TR-1: Autobus — podatek zależy od liczby miejsc."]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}

# jdg.tax_trans.r16 — `transport_tax_municipal_rate_cap`
else :=   {"matched":true,"rule_id":"jdg.tax_trans.r16","package":"jdg.micro.tax_trans","priority":7415,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"L-TR-1: Stawki maksymalne ogłaszane przez MF","_legal_basis":"Art. 10-13 ustawy o podatkach i opłatach lokalnych","_warnings":["[MICRO] L-TR-1: Stawki max wg obwieszczenia MF na dany rok."]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}
