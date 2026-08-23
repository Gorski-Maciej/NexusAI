# Generated from Plan OPA 34 — Micro-rules for jdg.vat
# 2026-07-13 14:11:39
# Rules: 179 (deduplicated)

package jdg.micro.vat.plan34

default decide := {"matched":false,"rule_id":"jdg.micro.vat.plan34.no_match","package":"jdg.micro.vat.plan34","priority":99999}

# jdg.vat.a5.r1 — `vat_taxable_goods_supply_pl`: Dostawa towarów za wynagrodzeniem w PL → VAT należny
decide :=   {"matched":true,"rule_id":"jdg.vat.a5.r1","package":"jdg.micro.vat.plan34","priority": 60551,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Dostawa towarów za wynagrodzeniem w PL","_legal_basis":"Art. 5 ust. 1 pkt 1-3 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"
}

# jdg.vat.a5.r2 — `vat_taxable_services_supply_pl`: Świadczenie usług za wynagrodzeniem w PL → VAT należny
else :=   {"matched":true,"rule_id":"jdg.vat.a5.r2","package":"jdg.micro.vat.plan34","priority": 60552,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Świadczenie usług za wynagrodzeniem w PL","_legal_basis":"Art. 5 ust. 1 pkt 1-3 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "SERVICE"
}

# jdg.vat.a5.r3 — `vat_taxable_export_goods`: Eksport towarów poza UE → VAT 0%
else :=   {"matched":true,"rule_id":"jdg.vat.a5.r3","package":"jdg.micro.vat.plan34","priority": 60553,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Eksport towarów poza UE","_legal_basis":"Art. 5 ust. 1 pkt 1-3 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "EXPORT"; object.get(input.invoice, "type", "") == "GOODS"; object.get(input.invoice, "vat_rate", 0.0) == 0.0
}

# jdg.vat.a5.r4 — `vat_taxable_import_goods`: Import towarów spoza UE → VAT należny w imporcie
else :=   {"matched":true,"rule_id":"jdg.vat.a5.r4","package":"jdg.micro.vat.plan34","priority": 60554,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Import towarów spoza UE","_legal_basis":"Art. 5 ust. 1 pkt 1-3 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "IMPORT"; object.get(input.invoice, "type", "") == "GOODS"
}

# jdg.vat.a5.r5 — `vat_taxable_wnt_intra_eu`: WNT → VAT należny w kraju nabycia
else :=   {"matched":true,"rule_id":"jdg.vat.a5.r5","package":"jdg.micro.vat.plan34","priority": 60555,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"WNT","_legal_basis":"Art. 5 ust. 1 pkt 1-3 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "WNT"
}

# jdg.vat.a5.r6 — `vat_taxable_wdt_intra_eu`: WDT → VAT 0%
else :=   {"matched":true,"rule_id":"jdg.vat.a5.r6","package":"jdg.micro.vat.plan34","priority": 60556,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"WDT","_legal_basis":"Art. 5 ust. 1 pkt 1-3 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "WDT"; object.get(input.invoice, "vat_rate", 0.0) == 0.0
}

# jdg.vat.a5.r7 — `vat_taxable_non_cash_contribution`: Wkład niepieniężny (aport) → VAT należny
else :=   {"matched":true,"rule_id":"jdg.vat.a5.r7","package":"jdg.micro.vat.plan34","priority": 60557,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Wkład niepieniężny (aport)","_legal_basis":"Art. 5 ust. 1 pkt 1-3 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a5.r8 — `vat_taxable_compensation_delivery`: Barter → VAT należny
else :=   {"matched":true,"rule_id":"jdg.vat.a5.r8","package":"jdg.micro.vat.plan34","priority": 60558,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Barter","_legal_basis":"Art. 5 ust. 1 pkt 1-3 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"; object.get(input.invoice, "payment_method", "") == "BARTER"
}

# jdg.vat.a5.r9 — `vat_taxable_gratis_transfer_goods`: Nieodpłatne przekazanie towarów na cele osobiste → VAT należny (gdy odliczenie)
else :=   {"matched":true,"rule_id":"jdg.vat.a5.r9","package":"jdg.micro.vat.plan34","priority": 60559,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Nieodpłatne przekazanie towarów na cele osobiste","_legal_basis":"Art. 5 ust. 1 pkt 1-3 VAT","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"; object.get(input.invoice, "is_gratis_transfer", false) == true
}

# jdg.vat.a5.r10 — `vat_taxable_gratis_services`: Nieodpłatne usługi na cele osobiste → VAT należny (gdy odliczenie)
else :=   {"matched":true,"rule_id":"jdg.vat.a5.r10","package":"jdg.micro.vat.plan34","priority": 60560,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Nieodpłatne usługi na cele osobiste","_legal_basis":"Art. 5 ust. 1 pkt 1-3 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "SERVICE"; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"; object.get(input.invoice, "is_gratis_transfer", false) == true
}

# jdg.vat.a7.r1 — `delivery_transfer_ownership`: Przeniesienie prawa do rozporządzania towarem → Definiuje dostawę
else :=   {"matched":true,"rule_id":"jdg.vat.a7.r1","package":"jdg.micro.vat.plan34","priority": 60701,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Przeniesienie prawa do rozporządzania towarem","_legal_basis":"Art. 7 ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"
}

# jdg.vat.a7.r2 — `delivery_consignment_sale`: Komis — dostawa w momencie wydania → Dostawa
else :=   {"matched":true,"rule_id":"jdg.vat.a7.r2","package":"jdg.micro.vat.plan34","priority": 60702,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Komis — dostawa w momencie wydania","_legal_basis":"Art. 7 ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"; object.get(input.invoice, "procedure", "") == "CONSIGNMENT"
}

# jdg.vat.a7.r3 — `delivery_installment_sale`: Sprzedaż ratalna — dostawa w momencie wydania → Dostawa
else :=   {"matched":true,"rule_id":"jdg.vat.a7.r3","package":"jdg.micro.vat.plan34","priority": 60703,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Sprzedaż ratalna — dostawa w momencie wydania","_legal_basis":"Art. 7 ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"
}

# jdg.vat.a7.r4 — `delivery_lease_financial`: Leasing finansowy — zrównany z dostawą → Dostawa
else :=   {"matched":true,"rule_id":"jdg.vat.a7.r4","package":"jdg.micro.vat.plan34","priority": 60704,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Leasing finansowy — zrównany z dostawą","_legal_basis":"Art. 7 ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"; object.get(input.invoice, "category_code", "") == "FINANCIAL"
}

# jdg.vat.a7.r5 — `delivery_building_construction_land`: Budynek + prawo użytkowania wieczystego → Dostawa
else :=   {"matched":true,"rule_id":"jdg.vat.a7.r5","package":"jdg.micro.vat.plan34","priority": 60705,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Budynek + prawo użytkowania wieczystego","_legal_basis":"Art. 7 ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"; object.get(input.invoice, "category_code", "") == "CONSTRUCTION"
}

# jdg.vat.a7.r6 — `delivery_electricity_gas_heat`: Energia elektryczna, cieplna, gaz → Dostawa
else :=   {"matched":true,"rule_id":"jdg.vat.a7.r6","package":"jdg.micro.vat.plan34","priority": 60706,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Energia elektryczna, cieplna, gaz","_legal_basis":"Art. 7 ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"; object.get(input.invoice, "category_code", "") == "ENERGY"
}

# jdg.vat.a7.r7 — `delivery_water_sewage`: Woda, ścieki → Dostawa
else :=   {"matched":true,"rule_id":"jdg.vat.a7.r7","package":"jdg.micro.vat.plan34","priority": 60707,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Woda, ścieki","_legal_basis":"Art. 7 ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"
}

# jdg.vat.a7.r8 — `delivery_gratis_to_employee`: Nieodpłatne przekazanie towaru pracownikowi → VAT należny
else :=   {"matched":true,"rule_id":"jdg.vat.a7.r8","package":"jdg.micro.vat.plan34","priority": 60708,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Nieodpłatne przekazanie towaru pracownikowi","_legal_basis":"Art. 7 ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"; object.get(input.invoice, "is_gratis_transfer", false) == true
}

# jdg.vat.a7.r9 — `delivery_gratis_to_owner_personal`: Na cele osobiste przedsiębiorcy → VAT należny
else :=   {"matched":true,"rule_id":"jdg.vat.a7.r9","package":"jdg.micro.vat.plan34","priority": 60709,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Na cele osobiste przedsiębiorcy","_legal_basis":"Art. 7 ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"; object.get(input.invoice, "is_gratis_transfer", false) == true
}

# jdg.vat.a7.r10 — `delivery_gratis_donation_opp`: Na cele OPP → VAT NIE należny
else :=   {"matched":true,"rule_id":"jdg.vat.a7.r10","package":"jdg.micro.vat.plan34","priority": 60710,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Na cele OPP","_legal_basis":"Art. 7 ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"; object.get(input.invoice, "is_gratis_transfer", false) == true
}

# jdg.vat.a7.r11 — `delivery_gratis_under_10_pln`: Prezenty <10 PLN → VAT NIE należny
else :=   {"matched":true,"rule_id":"jdg.vat.a7.r11","package":"jdg.micro.vat.plan34","priority": 60711,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Prezenty <10 PLN","_legal_basis":"Art. 7 ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"; object.get(input.invoice, "is_gratis_transfer", false) == true
}

# jdg.vat.a7.r12 — `delivery_gratis_samples`: Próbki towarów → VAT NIE należny
else :=   {"matched":true,"rule_id":"jdg.vat.a7.r12","package":"jdg.micro.vat.plan34","priority": 60712,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Próbki towarów","_legal_basis":"Art. 7 ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"; object.get(input.invoice, "is_gratis_transfer", false) == true
}

# jdg.vat.a15.r1 — `vat_payer_definition_jdg`: Osoba fizyczna JDG wykonująca czynności opodatkowane → Podatnik VAT
else :=   {"matched":true,"rule_id":"jdg.vat.a15.r1","package":"jdg.micro.vat.plan34","priority": 61501,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Osoba fizyczna JDG wykonująca czynności opodatkowane","_legal_basis":"Art. 15 ust. 1-9 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a15.r2 — `vat_payer_independent_activity`: Samodzielnie, ciągle, zarobkowo → Kryterium podatnika
else :=   {"matched":true,"rule_id":"jdg.vat.a15.r2","package":"jdg.micro.vat.plan34","priority": 61502,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Samodzielnie, ciągle, zarobkowo","_legal_basis":"Art. 15 ust. 1-9 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a15.r3 — `vat_payer_non_employee_relationship`: Brak stosunku pracy → Warunek podatnika
else :=   {"matched":true,"rule_id":"jdg.vat.a15.r3","package":"jdg.micro.vat.plan34","priority": 61503,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Brak stosunku pracy","_legal_basis":"Art. 15 ust. 1-9 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a15.r4 — `vat_payer_employee_exception`: Umowa o pracę → NIE podatnik VAT → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.vat.a15.r4","package":"jdg.micro.vat.plan34","priority": 61504,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Umowa o pracę → NIE podatnik VAT","_legal_basis":"Art. 15 ust. 1-9 VAT","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "vat_deduction_blocked", false) == true
}

# jdg.vat.a19a.r1 — `tax_point_general_delivery_goods`: Dostawa towarów → Data wydania
else :=   {"matched":true,"rule_id":"jdg.vat.a19a.r1","package":"jdg.micro.vat.plan34","priority": 61901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Dostawa towarów","_legal_basis":"Art. 19a ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"
}

# jdg.vat.a19a.r2 — `tax_point_general_service_completed`: Usługa wykonana → Data wykonania
else :=   {"matched":true,"rule_id":"jdg.vat.a19a.r2","package":"jdg.micro.vat.plan34","priority": 61902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Usługa wykonana","_legal_basis":"Art. 19a ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "SERVICE"
}

# jdg.vat.a19a.r3 — `tax_point_invoice_before_delivery`: Faktura przed wydaniem → Data faktury
else :=   {"matched":true,"rule_id":"jdg.vat.a19a.r3","package":"jdg.micro.vat.plan34","priority": 61903,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Faktura przed wydaniem","_legal_basis":"Art. 19a ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"; object.get(input.invoice, "invoice_type", "") == "INVOICE"
}

# jdg.vat.a19a.r4 — `tax_point_payment_before_delivery`: Zapłata przed wydaniem → Data zapłaty
else :=   {"matched":true,"rule_id":"jdg.vat.a19a.r4","package":"jdg.micro.vat.plan34","priority": 61904,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Zapłata przed wydaniem","_legal_basis":"Art. 19a ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"
}

# jdg.vat.a19a.r5 — `tax_point_invoice_30_days_after`: Faktura >30 dni po dostawie → 30. dzień od dostawy
else :=   {"matched":true,"rule_id":"jdg.vat.a19a.r5","package":"jdg.micro.vat.plan34","priority": 61905,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Faktura >30 dni po dostawie","_legal_basis":"Art. 19a ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "invoice_type", "") == "INVOICE"
}

# jdg.vat.a19a.r6 — `tax_point_continuous_services_end`: Usługi ciągłe (czynsz, abonament) → Koniec okresu
else :=   {"matched":true,"rule_id":"jdg.vat.a19a.r6","package":"jdg.micro.vat.plan34","priority": 61906,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Usługi ciągłe (czynsz, abonament)","_legal_basis":"Art. 19a ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "SERVICE"; object.get(input.invoice, "is_continuous_service", false) == true
}

# jdg.vat.a19a.r7 — `tax_point_continuous_services_payment`: Usługi ciągłe — zapłata przed końcem → Data zapłaty
else :=   {"matched":true,"rule_id":"jdg.vat.a19a.r7","package":"jdg.micro.vat.plan34","priority": 61907,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Usługi ciągłe — zapłata przed końcem","_legal_basis":"Art. 19a ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "SERVICE"; object.get(input.invoice, "is_continuous_service", false) == true
}

# jdg.vat.a19a.r8 — `tax_point_energy_supply_readings`: Energia — odczyty liczników → Data odczytu
else :=   {"matched":true,"rule_id":"jdg.vat.a19a.r8","package":"jdg.micro.vat.plan34","priority": 61908,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Energia — odczyty liczników","_legal_basis":"Art. 19a ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "category_code", "") == "ENERGY"
}

# jdg.vat.a19a.r9 — `tax_point_lease_rent_services`: Najem, dzierżawa → Koniec okresu
else :=   {"matched":true,"rule_id":"jdg.vat.a19a.r9","package":"jdg.micro.vat.plan34","priority": 61909,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Najem, dzierżawa","_legal_basis":"Art. 19a ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "SERVICE"
}

# jdg.vat.a19a.r10 — `tax_point_commission_sale`: Sprzedaż komisowa → Data sprzedaży
else :=   {"matched":true,"rule_id":"jdg.vat.a19a.r10","package":"jdg.micro.vat.plan34","priority": 61910,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Sprzedaż komisowa","_legal_basis":"Art. 19a ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "CONSIGNMENT"
}

# jdg.vat.a19a.r11 — `tax_point_consignment_goods_pickup`: Pobranie towaru z magazynu → Data pobrania
else :=   {"matched":true,"rule_id":"jdg.vat.a19a.r11","package":"jdg.micro.vat.plan34","priority": 61911,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Pobranie towaru z magazynu","_legal_basis":"Art. 19a ust. 1-8 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a19a.r12 — `tax_point_construction_acceptance`: Usługi budowlane — protokół → Data protokołu
else :=   {"matched":true,"rule_id":"jdg.vat.a19a.r12","package":"jdg.micro.vat.plan34","priority": 61912,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Usługi budowlane — protokół","_legal_basis":"Art. 19a ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "category_code", "") == "CONSTRUCTION"
}

# jdg.vat.a19a.r13 — `tax_point_construction_partial_acceptance`: Częściowy odbiór robót → Data protokołu
else :=   {"matched":true,"rule_id":"jdg.vat.a19a.r13","package":"jdg.micro.vat.plan34","priority": 61913,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Częściowy odbiór robót","_legal_basis":"Art. 19a ust. 1-8 VAT","_warnings":[]} {
    object.get(input.invoice, "category_code", "") == "CONSTRUCTION"
}

# jdg.vat.a19a.r14 — `tax_point_advertising_media`: Reklama w mediach → Data emisji
else :=   {"matched":true,"rule_id":"jdg.vat.a19a.r14","package":"jdg.micro.vat.plan34","priority": 61914,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Reklama w mediach","_legal_basis":"Art. 19a ust. 1-8 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a19a.r15 — `tax_point_transport_logistics`: Transport → Data dostarczenia
else :=   {"matched":true,"rule_id":"jdg.vat.a19a.r15","package":"jdg.micro.vat.plan34","priority": 61915,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Transport","_legal_basis":"Art. 19a ust. 1-8 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a20.r1 — `tax_point_wnt_invoice`: WNT — 15. dzień miesiąca po wydaniu → 15. dzień miesiąca
else :=   {"matched":true,"rule_id":"jdg.vat.a20.r1","package":"jdg.micro.vat.plan34","priority": 62001,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"WNT — 15. dzień miesiąca po wydaniu","_legal_basis":"Art. 20 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "WNT"
}

# jdg.vat.a20.r2 — `tax_point_wnt_invoice_before`: Faktura WNT przed 15. dniem → Data faktury
else :=   {"matched":true,"rule_id":"jdg.vat.a20.r2","package":"jdg.micro.vat.plan34","priority": 62002,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Faktura WNT przed 15. dniem","_legal_basis":"Art. 20 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "WNT"; object.get(input.invoice, "invoice_type", "") == "INVOICE"
}

# jdg.vat.a20.r3 — `tax_point_wnt_payment_advance`: Zaliczka na WNT → Data zapłaty
else :=   {"matched":true,"rule_id":"jdg.vat.a20.r3","package":"jdg.micro.vat.plan34","priority": 62003,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Zaliczka na WNT","_legal_basis":"Art. 20 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "WNT"; object.get(input.invoice, "prepayment_received", false) == true
}

# jdg.vat.a20.r4 — `tax_point_wnt_new_transport`: Nowy środek transportu → Data wydania
else :=   {"matched":true,"rule_id":"jdg.vat.a20.r4","package":"jdg.micro.vat.plan34","priority": 62004,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Nowy środek transportu","_legal_basis":"Art. 20 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "WNT"
}

# jdg.vat.a20.r5 — `tax_point_wnt_new_transport_invoice`: Nowy transport — faktura przed → Data faktury
else :=   {"matched":true,"rule_id":"jdg.vat.a20.r5","package":"jdg.micro.vat.plan34","priority": 62005,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Nowy transport — faktura przed","_legal_basis":"Art. 20 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "WNT"; object.get(input.invoice, "invoice_type", "") == "INVOICE"
}

# jdg.vat.a21.r1 — `cash_accounting_eligibility_small_payer`: Mały podatnik (<2M EUR) → Możliwość metody kasowej
else :=   {"matched":true,"rule_id":"jdg.vat.a21.r1","package":"jdg.micro.vat.plan34","priority": 62101,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Mały podatnik (<2M EUR)","_legal_basis":"Art. 21 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a21.r2 — `cash_accounting_tax_point_payment`: Metoda kasowa — obowiązek w dacie zapłaty → Data zapłaty
else :=   {"matched":true,"rule_id":"jdg.vat.a21.r2","package":"jdg.micro.vat.plan34","priority": 62102,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Metoda kasowa — obowiązek w dacie zapłaty","_legal_basis":"Art. 21 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_cash_accounting", false) == true
}

# jdg.vat.a21.r3 — `cash_accounting_tax_point_full_payment`: Płatność częściowa → Częściowa zapłata
else :=   {"matched":true,"rule_id":"jdg.vat.a21.r3","package":"jdg.micro.vat.plan34","priority": 62103,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Płatność częściowa","_legal_basis":"Art. 21 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a21.r4 — `cash_accounting_tax_point_advance`: Zaliczka przed dostawą → Data zaliczki
else :=   {"matched":true,"rule_id":"jdg.vat.a21.r4","package":"jdg.micro.vat.plan34","priority": 62104,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Zaliczka przed dostawą","_legal_basis":"Art. 21 VAT","_warnings":[]} {
    object.get(input.invoice, "prepayment_received", false) == true
}

# jdg.vat.a21.r5 — `cash_accounting_deduction_payment`: Odliczenie VAT w dacie zapłaty → Data zapłaty
else :=   {"matched":true,"rule_id":"jdg.vat.a21.r5","package":"jdg.micro.vat.plan34","priority": 62105,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Odliczenie VAT w dacie zapłaty","_legal_basis":"Art. 21 VAT","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a21.r6 — `cash_accounting_invoice_before_payment`: Faktura przed zapłatą — odroczenie → Odroczenie
else :=   {"matched":true,"rule_id":"jdg.vat.a21.r6","package":"jdg.micro.vat.plan34","priority": 62106,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Faktura przed zapłatą — odroczenie","_legal_basis":"Art. 21 VAT","_warnings":[]} {
    object.get(input.invoice, "invoice_type", "") == "INVOICE"
}

# jdg.vat.a21.r7 — `cash_accounting_loss_of_right_2m_eur`: Przekroczenie 2M EUR → Koniec metody kasowej
else :=   {"matched":true,"rule_id":"jdg.vat.a21.r7","package":"jdg.micro.vat.plan34","priority": 62107,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Przekroczenie 2M EUR","_legal_basis":"Art. 21 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a21.r8 — `cash_accounting_notification_us`: Zawiadomienie US → Obowiązek formalny
else :=   {"matched":true,"rule_id":"jdg.vat.a21.r8","package":"jdg.micro.vat.plan34","priority": 62108,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Zawiadomienie US","_legal_basis":"Art. 21 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a21.r9 — `cash_accounting_change_deadline`: Zmiana od początku okresu → Termin zmiany
else :=   {"matched":true,"rule_id":"jdg.vat.a21.r9","package":"jdg.micro.vat.plan34","priority": 62109,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Zmiana od początku okresu","_legal_basis":"Art. 21 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a21.r10 — `cash_accounting_excluded_transactions`: Wyłączenia: WDT, eksport, WNT → NIE dotyczy
else :=   {"matched":true,"rule_id":"jdg.vat.a21.r10","package":"jdg.micro.vat.plan34","priority": 62110,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Wyłączenia: WDT, eksport, WNT","_legal_basis":"Art. 21 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "EXPORT"; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "vat_deduction_blocked", false) == true
}

# jdg.vat.a29a.r1 — `tax_base_general_everything_received`: Wszystko co stanowi zapłatę → Podstawa = kwota należna
else :=   {"matched":true,"rule_id":"jdg.vat.a29a.r1","package":"jdg.micro.vat.plan34","priority": 62901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Wszystko co stanowi zapłatę","_legal_basis":"Art. 29a ust. 1-15 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a29a.r2 — `tax_base_includes_taxes_duties`: Cła, akcyza, opłaty → Powiększenie podstawy
else :=   {"matched":true,"rule_id":"jdg.vat.a29a.r2","package":"jdg.micro.vat.plan34","priority": 62902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Cła, akcyza, opłaty","_legal_basis":"Art. 29a ust. 1-15 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a29a.r3 — `tax_base_excludes_vat`: VAT nie wchodzi do podstawy → Czyszczenie
else :=   {"matched":true,"rule_id":"jdg.vat.a29a.r3","package":"jdg.micro.vat.plan34","priority": 62903,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"VAT nie wchodzi do podstawy","_legal_basis":"Art. 29a ust. 1-15 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a29a.r4 — `tax_base_includes_costs_commission`: Prowizja, opakowanie, transport → Powiększenie
else :=   {"matched":true,"rule_id":"jdg.vat.a29a.r4","package":"jdg.micro.vat.plan34","priority": 62904,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Prowizja, opakowanie, transport","_legal_basis":"Art. 29a ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "CONSIGNMENT"
}

# jdg.vat.a29a.r5 — `tax_base_includes_subsidies`: Dotacje związane z ceną → Powiększenie
else :=   {"matched":true,"rule_id":"jdg.vat.a29a.r5","package":"jdg.micro.vat.plan34","priority": 62905,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Dotacje związane z ceną","_legal_basis":"Art. 29a ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "includes_subsidy", false) == true
}

# jdg.vat.a29a.r6 — `tax_base_reduction_discount_before`: Rabat przed sprzedażą → Pomniejszenie
else :=   {"matched":true,"rule_id":"jdg.vat.a29a.r6","package":"jdg.micro.vat.plan34","priority": 62906,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Rabat przed sprzedażą","_legal_basis":"Art. 29a ust. 1-15 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a29a.r7 — `tax_base_reduction_discount_after`: Rabat po sprzedaży — korekta → Korekta in minus
else :=   {"matched":true,"rule_id":"jdg.vat.a29a.r7","package":"jdg.micro.vat.plan34","priority": 62907,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Rabat po sprzedaży — korekta","_legal_basis":"Art. 29a ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "is_correction", false) == true
}

# jdg.vat.a29a.r8 — `tax_base_reduction_return_goods`: Zwrot towarów → Korekta in minus
else :=   {"matched":true,"rule_id":"jdg.vat.a29a.r8","package":"jdg.micro.vat.plan34","priority": 62908,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Zwrot towarów","_legal_basis":"Art. 29a ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "is_correction", false) == true
}

# jdg.vat.a29a.r9 — `tax_base_reduction_bad_debt`: Złe długi — korekta → Korekta
else :=   {"matched":true,"rule_id":"jdg.vat.a29a.r9","package":"jdg.micro.vat.plan34","priority": 62909,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Złe długi — korekta","_legal_basis":"Art. 29a ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "is_paid", true) == false; object.get(input.invoice, "days_overdue", 0) >= 90; object.get(input.invoice, "is_correction", false) == true
}

# jdg.vat.a29a.r10 — `tax_base_rebate_for_early_payment`: Skonto — korekta → Korekta
else :=   {"matched":true,"rule_id":"jdg.vat.a29a.r10","package":"jdg.micro.vat.plan34","priority": 62910,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Skonto — korekta","_legal_basis":"Art. 29a ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "is_correction", false) == true
}

# jdg.vat.a29a.r11 — `tax_base_non_cash_consideration`: Barter — wartość rynkowa → Wartość rynkowa
else :=   {"matched":true,"rule_id":"jdg.vat.a29a.r11","package":"jdg.micro.vat.plan34","priority": 62911,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Barter — wartość rynkowa","_legal_basis":"Art. 29a ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "payment_method", "") == "BARTER"
}

# jdg.vat.a29a.r12 — `tax_base_related_party_market_value`: Podmiot powiązany poniżej rynku → Wartość rynkowa
else :=   {"matched":true,"rule_id":"jdg.vat.a29a.r12","package":"jdg.micro.vat.plan34","priority": 62912,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Podmiot powiązany poniżej rynku","_legal_basis":"Art. 29a ust. 1-15 VAT","_warnings":[]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.vat.a29a.r13 — `tax_base_gratis_transfer`: Nieodpłatne przekazanie → Cena nabycia/koszt
else :=   {"matched":true,"rule_id":"jdg.vat.a29a.r13","package":"jdg.micro.vat.plan34","priority": 62913,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Nieodpłatne przekazanie","_legal_basis":"Art. 29a ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "is_gratis_transfer", false) == true
}

# jdg.vat.a29a.r14 — `tax_base_personal_use`: Użytek osobisty towaru firmowego → Koszt
else :=   {"matched":true,"rule_id":"jdg.vat.a29a.r14","package":"jdg.micro.vat.plan34","priority": 62914,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Użytek osobisty towaru firmowego","_legal_basis":"Art. 29a ust. 1-15 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a29a.r15 — `tax_base_margin_scheme`: Procedura marży → Podstawa = marża
else :=   {"matched":true,"rule_id":"jdg.vat.a29a.r15","package":"jdg.micro.vat.plan34","priority": 62915,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Procedura marży","_legal_basis":"Art. 29a ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "MARGIN_SCHEME"
}

# jdg.vat.a41.r1 — `vat_rate_23_standard`: Domyślna stawka → 23%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r1","package":"jdg.micro.vat.plan34","priority": 64101,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Domyślna stawka","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.23
}

# jdg.vat.a41.r2 — `vat_rate_23_fuel`: Paliwa silnikowe → 23%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r2","package":"jdg.micro.vat.plan34","priority": 64102,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Paliwa silnikowe","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.23
}

# jdg.vat.a41.r3 — `vat_rate_23_electronics`: RTV, AGD, komputery → 23%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r3","package":"jdg.micro.vat.plan34","priority": 64103,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"RTV, AGD, komputery","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.23
}

# jdg.vat.a41.r4 — `vat_rate_23_construction_materials`: Materiały budowlane → 23%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r4","package":"jdg.micro.vat.plan34","priority": 64104,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Materiały budowlane","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.23; object.get(input.invoice, "category_code", "") == "CONSTRUCTION"
}

# jdg.vat.a41.r5 — `vat_rate_23_consulting`: Konsulting, doradztwo, prawo, księgowość → 23%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r5","package":"jdg.micro.vat.plan34","priority": 64105,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Konsulting, doradztwo, prawo, księgowość","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.23
}

# jdg.vat.a41.r7 — `vat_rate_23_it_services`: IT, programowanie, hosting, SaaS → 23%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r7","package":"jdg.micro.vat.plan34","priority": 64107,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"IT, programowanie, hosting, SaaS","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "SERVICE"; object.get(input.invoice, "vat_rate", 0.0) == 0.23
}

# jdg.vat.a41.r12 — `vat_rate_23_vehicles`: Samochody, pojazdy → 23%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r12","package":"jdg.micro.vat.plan34","priority": 64112,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Samochody, pojazdy","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.23; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.vat.a41.r13 — `vat_rate_23_alcohol_tobacco`: Alkohol, tytoń → 23%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r13","package":"jdg.micro.vat.plan34","priority": 64113,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Alkohol, tytoń","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.23
}

# jdg.vat.a41.r16 — `vat_rate_8_food_basic`: Podstawowe produkty spożywcze → 8%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r16","package":"jdg.micro.vat.plan34","priority": 64116,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Podstawowe produkty spożywcze","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.08
}

# jdg.vat.a41.r17 — `vat_rate_8_food_baby`: Żywność dla niemowląt → 8%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r17","package":"jdg.micro.vat.plan34","priority": 64117,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Żywność dla niemowląt","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.08
}

# jdg.vat.a41.r18 — `vat_rate_8_water_supply`: Woda, ścieki → 8%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r18","package":"jdg.micro.vat.plan34","priority": 64118,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Woda, ścieki","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.08
}

# jdg.vat.a41.r21 — `vat_rate_8_construction_residential`: Roboty budowlane w mieszkalnych → 8%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r21","package":"jdg.micro.vat.plan34","priority": 64121,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Roboty budowlane w mieszkalnych","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.08; object.get(input.invoice, "category_code", "") == "CONSTRUCTION"
}

# jdg.vat.a41.r23 — `vat_rate_8_pharmaceuticals`: Leki, farmaceutyki → 8%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r23","package":"jdg.micro.vat.plan34","priority": 64123,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Leki, farmaceutyki","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.08
}

# jdg.vat.a41.r24 — `vat_rate_8_medical_equipment`: Sprzęt medyczny → 8%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r24","package":"jdg.micro.vat.plan34","priority": 64124,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Sprzęt medyczny","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.08; object.get(input.invoice, "category_code", "") == "HEALTHCARE"
}

# jdg.vat.a41.r26 — `vat_rate_8_hotel_services`: Hotele, noclegi → 8%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r26","package":"jdg.micro.vat.plan34","priority": 64126,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Hotele, noclegi","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "SERVICE"; object.get(input.invoice, "vat_rate", 0.0) == 0.08
}

# jdg.vat.a41.r28 — `vat_rate_5_books_print`: Książki drukowane → 5%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r28","package":"jdg.micro.vat.plan34","priority": 64128,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Książki drukowane","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.05
}

# jdg.vat.a41.r29 — `vat_rate_5_ebooks_digital`: E-booki, audiobooki → 5%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r29","package":"jdg.micro.vat.plan34","priority": 64129,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"E-booki, audiobooki","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.05
}

# jdg.vat.a41.r31 — `vat_rate_5_food_basic_extended`: Produkty spożywcze z załącznika MF → 5%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r31","package":"jdg.micro.vat.plan34","priority": 64131,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Produkty spożywcze z załącznika MF","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.05
}

# jdg.vat.a41.r36 — `vat_rate_0_export_direct`: Eksport bezpośredni poza UE → 0%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r36","package":"jdg.micro.vat.plan34","priority": 64136,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Eksport bezpośredni poza UE","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "EXPORT"; object.get(input.invoice, "vat_rate", 0.0) == 0.0
}

# jdg.vat.a41.r38 — `vat_rate_0_wdt_intra_eu`: WDT do nabywcy z VAT-UE → 0%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r38","package":"jdg.micro.vat.plan34","priority": 64138,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"WDT do nabywcy z VAT-UE","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "WDT"; object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.jdg_entrepreneur, "is_vat_eu_registered", false) == true
}

# jdg.vat.a41.r42 — `vat_rate_0_international_transport_passenger`: Transport międzynarodowy pasażerski → 0%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r42","package":"jdg.micro.vat.plan34","priority": 64142,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Transport międzynarodowy pasażerski","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0
}

# jdg.vat.a41.r45 — `vat_exemption_object_education`: Usługi edukacyjne → ZW
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r45","package":"jdg.micro.vat.plan34","priority": 64145,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Usługi edukacyjne","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "category_code", "") == "EDUCATION"
}

# jdg.vat.a41.r46 — `vat_exemption_object_healthcare`: Usługi medyczne → ZW
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r46","package":"jdg.micro.vat.plan34","priority": 64146,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Usługi medyczne","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "category_code", "") == "HEALTHCARE"; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.vat.a41.r49 — `vat_exemption_object_financial_insurance`: Finanse, ubezpieczenia → ZW
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r49","package":"jdg.micro.vat.plan34","priority": 64149,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Finanse, ubezpieczenia","_legal_basis":"Art. 41 ust. 1-15 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "category_code", "") == "FINANCIAL"
}

# jdg.vat.a43.r1 — `object_exemption_medical_doctors`: Lekarze, dentyści, weterynarze → Art. 43 ust. 1 pkt 18
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r1","package":"jdg.micro.vat.plan34","priority": 64301,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Lekarze, dentyści, weterynarze","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.invoice, "category_code", "") == "HEALTHCARE"
}

# jdg.vat.a43.r2 — `object_exemption_medical_nurses`: Pielęgniarki, położne → Art. 43 ust. 1 pkt 19
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r2","package":"jdg.micro.vat.plan34","priority": 64302,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Pielęgniarki, położne","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a43.r3 — `object_exemption_medical_rehabilitation`: Rehabilitacja, fizjoterapia → Art. 43 ust. 1 pkt 20
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r3","package":"jdg.micro.vat.plan34","priority": 64303,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Rehabilitacja, fizjoterapia","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a43.r4 — `object_exemption_medical_psychology`: Psychologowie, psychoterapeuci → Art. 43 ust. 1 pkt 21
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r4","package":"jdg.micro.vat.plan34","priority": 64304,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Psychologowie, psychoterapeuci","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a43.r6 — `object_exemption_school_university`: Szkoły, przedszkola, uczelnie → Art. 43 ust. 1 pkt 26
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r6","package":"jdg.micro.vat.plan34","priority": 64306,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Szkoły, przedszkola, uczelnie","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a43.r7 — `object_exemption_private_tutoring`: Korepetycje, lekcje prywatne → Art. 43 ust. 1 pkt 27
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r7","package":"jdg.micro.vat.plan34","priority": 64307,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Korepetycje, lekcje prywatne","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a43.r8 — `object_exemption_vocational_training`: Szkolenia zawodowe → Art. 43 ust. 1 pkt 29
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r8","package":"jdg.micro.vat.plan34","priority": 64308,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Szkolenia zawodowe","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a43.r9 — `object_exemption_social_welfare`: Pomoc społeczna, opieka → Art. 43 ust. 1 pkt 22-25
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r9","package":"jdg.micro.vat.plan34","priority": 64309,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Pomoc społeczna, opieka","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a43.r10 — `object_exemption_culture_non_commercial`: Teatry, muzea, biblioteki → Art. 43 ust. 1 pkt 33
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r10","package":"jdg.micro.vat.plan34","priority": 64310,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Teatry, muzea, biblioteki","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a43.r11 — `object_exemption_sport_non_commercial`: Sport niekomercyjny → Art. 43 ust. 1 pkt 32
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r11","package":"jdg.micro.vat.plan34","priority": 64311,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Sport niekomercyjny","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a43.r15 — `object_exemption_real_estate_existing`: Budynki po pierwszym zasiedleniu → Art. 43 ust. 1 pkt 10
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r15","package":"jdg.micro.vat.plan34","priority": 64315,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Budynki po pierwszym zasiedleniu","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a43.r18 — `object_exemption_buildings_for_rent`: Wynajem mieszkalny na cele mieszkaniowe → Art. 43 ust. 1 pkt 36
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r18","package":"jdg.micro.vat.plan34","priority": 64318,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Wynajem mieszkalny na cele mieszkaniowe","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a43.r19 — `object_exemption_buildings_rent_short`: Airbnb → NIE zwolniony (23%) → Art. 43 ust. 1 pkt 36
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r19","package":"jdg.micro.vat.plan34","priority": 64319,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Airbnb → NIE zwolniony (23%)","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.23; object.get(input.invoice, "vat_exemption", "") != ""
}

# jdg.vat.a43.r20 — `object_exemption_dental_services`: Protetyka stomatologiczna → Art. 43 ust. 1 pkt 14
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r20","package":"jdg.micro.vat.plan34","priority": 64320,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Protetyka stomatologiczna","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "SERVICE"
}

# jdg.vat.a43.r35 — `object_exemption_child_care`: Żłobki, kluby dziecięce → Art. 43 ust. 1 pkt 24
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r35","package":"jdg.micro.vat.plan34","priority": 64335,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Żłobki, kluby dziecięce","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.vat.a43.r36 — `object_exemption_elderly_care`: Opieka nad starszymi → Art. 43 ust. 1 pkt 22
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r36","package":"jdg.micro.vat.plan34","priority": 64336,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Opieka nad starszymi","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.vat.a43.r39 — `object_exemption_second_hand_goods_margin`: Towary używane (marża) → Art. 120 VAT
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r39","package":"jdg.micro.vat.plan34","priority": 64339,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Towary używane (marża)","_legal_basis":"Art. 43 ust. 1 pkt 1-38 VAT","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "MARGIN_SCHEME"
}

# jdg.vat.a86.r1 — `deduction_right_general`: Zakup związany z czynnościami opodatkowanymi → Prawo do odliczenia
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r1","package":"jdg.micro.vat.plan34","priority": 68601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Zakup związany z czynnościami opodatkowanymi","_legal_basis":"Art. 86 ust. 1-10 VAT (odliczenia)","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a86a.r1 — `car_vat_deduction_50pct_no_evidence`: Bez ewidencji przebiegu → 50% VAT
else :=   {"matched":true,"rule_id":"jdg.vat.a86a.r1","package":"jdg.micro.vat.plan34","priority": 68601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Bez ewidencji przebiegu","_legal_basis":"Art. 86a VAT (limit aut)","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"; object.get(input.invoice, "category_code", "") == "CAR"; object.get(input.invoice, "mileage_log_present", false) == true
}

# jdg.vat.a86.r2 — `deduction_vat_payer_only`: Tylko czynny podatnik VAT → Warunek podmiotowy
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r2","package":"jdg.micro.vat.plan34","priority": 68602,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Tylko czynny podatnik VAT","_legal_basis":"Art. 86 ust. 1-10 VAT (odliczenia)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a86a.r2 — `car_vat_deduction_100pct_evidence`: Ewidencja przebiegu → tylko firmowe → 100% VAT
else :=   {"matched":true,"rule_id":"jdg.vat.a86a.r2","package":"jdg.micro.vat.plan34","priority": 68602,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Ewidencja przebiegu → tylko firmowe","_legal_basis":"Art. 86a VAT (limit aut)","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"; object.get(input.invoice, "category_code", "") == "CAR"; object.get(input.invoice, "mileage_log_present", false) == true
}

# jdg.vat.a86.r3 — `deduction_invoice_possession`: Faktura VAT lub SAD → Warunek formalny
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r3","package":"jdg.micro.vat.plan34","priority": 68603,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Faktura VAT lub SAD","_legal_basis":"Art. 86 ust. 1-10 VAT (odliczenia)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"; object.get(input.invoice, "invoice_type", "") == "INVOICE"
}

# jdg.vat.a86a.r3 — `car_vat_deduction_100pct_exclusively`: Wyłącznie firmowo → 100% VAT
else :=   {"matched":true,"rule_id":"jdg.vat.a86a.r3","package":"jdg.micro.vat.plan34","priority": 68603,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Wyłącznie firmowo","_legal_basis":"Art. 86a VAT (limit aut)","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.vat.a86.r4 — `deduction_invoice_required_fields`: NIP, data, kwota, stawka VAT → Pola faktury
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r4","package":"jdg.micro.vat.plan34","priority": 68604,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"NIP, data, kwota, stawka VAT","_legal_basis":"Art. 86 ust. 1-10 VAT (odliczenia)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a86a.r4 — `car_vat_100pct_exclusively_test`: Test: umowa + brak użycia prywatnego + konstrukcja → Test wyłączności
else :=   {"matched":true,"rule_id":"jdg.vat.a86a.r4","package":"jdg.micro.vat.plan34","priority": 68604,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Test: umowa + brak użycia prywatnego + konstrukcja","_legal_basis":"Art. 86a VAT (limit aut)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "vat_deduction_blocked", false) == true; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.vat.a86.r5 — `deduction_invoice_incorrect_nip_block`: Błędny NIP → brak odliczenia → Blokada
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r5","package":"jdg.micro.vat.plan34","priority": 68605,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Błędny NIP → brak odliczenia","_legal_basis":"Art. 86 ust. 1-10 VAT (odliczenia)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a86a.r5 — `car_vat_100pct_taxi_delivery`: Taxi, przewóz, dostawa → 100% VAT
else :=   {"matched":true,"rule_id":"jdg.vat.a86a.r5","package":"jdg.micro.vat.plan34","priority": 68605,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Taxi, przewóz, dostawa","_legal_basis":"Art. 86a VAT (limit aut)","_warnings":[]} {
    object.get(input.invoice, "type", "") == "GOODS"; object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.vat.a86.r6 — `deduction_proportion_mixed`: Wydatek mieszany → proporcja → Odliczenie %
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r6","package":"jdg.micro.vat.plan34","priority": 68606,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Wydatek mieszany → proporcja","_legal_basis":"Art. 86 ust. 1-10 VAT (odliczenia)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"; object.get(input.invoice, "private_use_percent", 0) > 0; object.get(input.jdg_entrepreneur, "has_mixed_vat_activity", false) == true
}

# jdg.vat.a86a.r6 — `car_vat_leasing_50pct`: Leasing auta mieszanego → 50% VAT
else :=   {"matched":true,"rule_id":"jdg.vat.a86a.r6","package":"jdg.micro.vat.plan34","priority": 68606,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Leasing auta mieszanego","_legal_basis":"Art. 86a VAT (limit aut)","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "category_code", "") == "CAR"; object.get(input.invoice, "private_use_percent", 0) > 0
}

# jdg.vat.a86.r7 — `deduction_proportion_estimated`: Proporcja wstępna z roku poprzedniego → Wstępna
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r7","package":"jdg.micro.vat.plan34","priority": 68607,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Proporcja wstępna z roku poprzedniego","_legal_basis":"Art. 86 ust. 1-10 VAT (odliczenia)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "has_mixed_vat_activity", false) == true
}

# jdg.vat.a86a.r7 — `car_vat_fuel_50pct`: Paliwo do auta mieszanego → 50% VAT
else :=   {"matched":true,"rule_id":"jdg.vat.a86a.r7","package":"jdg.micro.vat.plan34","priority": 68607,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Paliwo do auta mieszanego","_legal_basis":"Art. 86a VAT (limit aut)","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "category_code", "") == "CAR"; object.get(input.invoice, "private_use_percent", 0) > 0
}

# jdg.vat.a86.r8 — `deduction_proportion_actual_year_end`: Korekta na koniec roku → Ostateczna
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r8","package":"jdg.micro.vat.plan34","priority": 68608,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Korekta na koniec roku","_legal_basis":"Art. 86 ust. 1-10 VAT (odliczenia)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "has_mixed_vat_activity", false) == true; object.get(input.invoice, "is_correction", false) == true
}

# jdg.vat.a86a.r8 — `car_vat_mileage_log_mandatory_fields`: Ewidencja: data, trasa, cel, km → Wymagane pola
else :=   {"matched":true,"rule_id":"jdg.vat.a86a.r8","package":"jdg.micro.vat.plan34","priority": 68608,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Ewidencja: data, trasa, cel, km","_legal_basis":"Art. 86a VAT (limit aut)","_warnings":[]} {
    object.get(input.invoice, "category_code", "") == "CAR"; object.get(input.invoice, "mileage_log_present", false) == true
}

# jdg.vat.a86.r9 — `deduction_proportion_de_minimis`: Proporcja <2% → brak odliczenia → 0%
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r9","package":"jdg.micro.vat.plan34","priority": 68609,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Proporcja <2% → brak odliczenia","_legal_basis":"Art. 86 ust. 1-10 VAT (odliczenia)","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "has_mixed_vat_activity", false) == true
}

# jdg.vat.a86.r10 — `deduction_proportion_full_98`: Proporcja >98% → pełne odliczenie → 100%
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r10","package":"jdg.micro.vat.plan34","priority": 68610,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Proporcja >98% → pełne odliczenie","_legal_basis":"Art. 86 ust. 1-10 VAT (odliczenia)","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.08; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "has_mixed_vat_activity", false) == true
}

# jdg.vat.a86.r13 — `deduction_wnt_goods`: WNT → VAT należny = naliczony → Odliczenie WNT
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r13","package":"jdg.micro.vat.plan34","priority": 68613,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"WNT → VAT należny = naliczony","_legal_basis":"Art. 86 ust. 1-10 VAT (odliczenia)","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "WNT"; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a86.r15 — `deduction_services_import_eu`: Import usług B2B z UE → Reverse charge
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r15","package":"jdg.micro.vat.plan34","priority": 68615,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Import usług B2B z UE","_legal_basis":"Art. 86 ust. 1-10 VAT (odliczenia)","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "IMPORT_SERVICES"; object.get(input.invoice, "type", "") == "SERVICE"; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a86.r16 — `deduction_services_import_non_eu`: Import usług B2B spoza UE → Reverse charge
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r16","package":"jdg.micro.vat.plan34","priority": 68616,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Import usług B2B spoza UE","_legal_basis":"Art. 86 ust. 1-10 VAT (odliczenia)","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "IMPORT_SERVICES"; object.get(input.invoice, "type", "") == "SERVICE"; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a88.r1 — `deduction_blocked_hotel_services`: Noclegi, hotele → Art. 88 ust. 1 pkt 4
else :=   {"matched":true,"rule_id":"jdg.vat.a88.r1","package":"jdg.micro.vat.plan34","priority": 68801,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Noclegi, hotele","_legal_basis":"Art. 88 VAT","_warnings":[]} {
    object.get(input.invoice, "type", "") == "SERVICE"; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a88.r2 — `deduction_blocked_restaurant_except_catering`: Gastronomia (oprócz cateringu) → Art. 88 ust. 1 pkt 4
else :=   {"matched":true,"rule_id":"jdg.vat.a88.r2","package":"jdg.micro.vat.plan34","priority": 68802,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Gastronomia (oprócz cateringu)","_legal_basis":"Art. 88 VAT","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a88.r3 — `deduction_blocked_fuel_car_mixed`: Paliwo do aut mieszanych → Art. 88 ust. 1 pkt 3
else :=   {"matched":true,"rule_id":"jdg.vat.a88.r3","package":"jdg.micro.vat.plan34","priority": 68803,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Paliwo do aut mieszanych","_legal_basis":"Art. 88 VAT","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"; object.get(input.invoice, "category_code", "") == "CAR"; object.get(input.invoice, "private_use_percent", 0) > 0
}

# jdg.vat.a88.r4 — `deduction_blocked_entertainment`: Rozrywka, reprezentacja → Art. 88 ust. 1 pkt 4
else :=   {"matched":true,"rule_id":"jdg.vat.a88.r4","package":"jdg.micro.vat.plan34","priority": 68804,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Rozrywka, reprezentacja","_legal_basis":"Art. 88 VAT","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a88.r5 — `deduction_blocked_gifts_large`: Prezenty >20 PLN → Art. 88 ust. 1 pkt 5
else :=   {"matched":true,"rule_id":"jdg.vat.a88.r5","package":"jdg.micro.vat.plan34","priority": 68805,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Prezenty >20 PLN","_legal_basis":"Art. 88 VAT","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a88.r7 — `deduction_blocked_personal_use`: Cele osobiste JDG → Art. 88 ust. 1 pkt 1
else :=   {"matched":true,"rule_id":"jdg.vat.a88.r7","package":"jdg.micro.vat.plan34","priority": 68807,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Cele osobiste JDG","_legal_basis":"Art. 88 VAT","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a88.r8 — `deduction_blocked_no_invoice`: Zakup bez faktury → Art. 88 ust. 1 pkt 2
else :=   {"matched":true,"rule_id":"jdg.vat.a88.r8","package":"jdg.micro.vat.plan34","priority": 68808,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Zakup bez faktury","_legal_basis":"Art. 88 VAT","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a88.r13 — `deduction_blocked_invoice_after_deadline`: Faktura >3 mies. po terminie → Art. 86 ust. 11
else :=   {"matched":true,"rule_id":"jdg.vat.a88.r13","package":"jdg.micro.vat.plan34","priority": 68813,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Faktura >3 mies. po terminie","_legal_basis":"Art. 88 VAT","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"; object.get(input.invoice, "invoice_type", "") == "INVOICE"
}

# jdg.vat.a89a.r1 — `bad_debt_creditor_150_days`: Wierzyciel → Niezapłacone 150 dni
else :=   {"matched":true,"rule_id":"jdg.vat.a89a.r1","package":"jdg.micro.vat.plan34","priority": 68901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Wierzyciel","_legal_basis":"Art. 89a VAT (złe długi)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a89b.r1 — `bad_debt_debtor_90_days_mandatory`: Dłużnik (JDG) → Niezapłacone 90 dni
else :=   {"matched":true,"rule_id":"jdg.vat.a89b.r1","package":"jdg.micro.vat.plan34","priority": 68901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Dłużnik (JDG)","_legal_basis":"Art. 89b VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a89a.r2 — `bad_debt_creditor_debtor_not_restructuring`: Wierzyciel → Dłużnik nie w restrukturyzacji
else :=   {"matched":true,"rule_id":"jdg.vat.a89a.r2","package":"jdg.micro.vat.plan34","priority": 68902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Wierzyciel","_legal_basis":"Art. 89a VAT (złe długi)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a89b.r2 — `bad_debt_debtor_amount_to_return`: Dłużnik → VAT odliczony = do zwrotu
else :=   {"matched":true,"rule_id":"jdg.vat.a89b.r2","package":"jdg.micro.vat.plan34","priority": 68902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Dłużnik","_legal_basis":"Art. 89b VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a89a.r3 — `bad_debt_creditor_notification_debtor`: Wierzyciel → Zawiadomienie dłużnika
else :=   {"matched":true,"rule_id":"jdg.vat.a89a.r3","package":"jdg.micro.vat.plan34","priority": 68903,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Wierzyciel","_legal_basis":"Art. 89a VAT (złe długi)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a89b.r4 — `bad_debt_debtor_30pct_sanction`: Dłużnik → Brak korekty → sankcja
else :=   {"matched":true,"rule_id":"jdg.vat.a89b.r4","package":"jdg.micro.vat.plan34","priority": 68904,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Dłużnik","_legal_basis":"Art. 89b VAT","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true; object.get(input.invoice, "is_correction", false) == true
}

# jdg.vat.a89a.r5 — `bad_debt_creditor_reversal_on_payment`: Wierzyciel → Zapłata po korekcie
else :=   {"matched":true,"rule_id":"jdg.vat.a89a.r5","package":"jdg.micro.vat.plan34","priority": 68905,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Wierzyciel","_legal_basis":"Art. 89a VAT (złe długi)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a96.r1 — `vat_r_registration_before_first_sale`: VAT-R przed pierwszą czynnością → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.vat.a96.r1","package":"jdg.micro.vat.plan34","priority": 69601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"VAT-R przed pierwszą czynnością","_legal_basis":"Art. 96 VAT (rejestracja)","_warnings":[]} {
    input.jdg_entrepreneur.vat_status != "ACTIVE"
}

# jdg.vat.a96.r2 — `vat_r_deadline_for_registration`: Przed pierwszym dniem działalności VAT → Termin
else :=   {"matched":true,"rule_id":"jdg.vat.a96.r2","package":"jdg.micro.vat.plan34","priority": 69602,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Przed pierwszym dniem działalności VAT","_legal_basis":"Art. 96 VAT (rejestracja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a96.r3 — `vat_r_office_deadline_3_months`: US ma 3 miesiące na rejestrację → Czas oczekiwania
else :=   {"matched":true,"rule_id":"jdg.vat.a96.r3","package":"jdg.micro.vat.plan34","priority": 69603,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"US ma 3 miesiące na rejestrację","_legal_basis":"Art. 96 VAT (rejestracja)","_warnings":[]} {
    input.jdg_entrepreneur.vat_status != "ACTIVE"
}

# jdg.vat.a96.r4 — `vat_r_refusal_grounds`: Brak adresu, zaległości, fraud → Podstawy odmowy
else :=   {"matched":true,"rule_id":"jdg.vat.a96.r4","package":"jdg.micro.vat.plan34","priority": 69604,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Brak adresu, zaległości, fraud","_legal_basis":"Art. 96 VAT (rejestracja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a96.r5 — `vat_r_mandatory_fields`: NIP, REGON, adres, PKD, rachunek → Dane VAT-R
else :=   {"matched":true,"rule_id":"jdg.vat.a96.r5","package":"jdg.micro.vat.plan34","priority": 69605,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"NIP, REGON, adres, PKD, rachunek","_legal_basis":"Art. 96 VAT (rejestracja)","_warnings":[]} {
    input.jdg_entrepreneur.vat_status != "ACTIVE"
}

# jdg.vat.a96.r6 — `vat_r_change_of_data`: Zmiana danych → aktualizacja w 7 dni → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.vat.a96.r6","package":"jdg.micro.vat.plan34","priority": 69606,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Zmiana danych → aktualizacja w 7 dni","_legal_basis":"Art. 96 VAT (rejestracja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a96.r7 — `vat_z_deregistration_on_closure`: VAT-Z przy zaprzestaniu VAT → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.vat.a96.r7","package":"jdg.micro.vat.plan34","priority": 69607,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"VAT-Z przy zaprzestaniu VAT","_legal_basis":"Art. 96 VAT (rejestracja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a96.r8 — `vat_z_deadline_30_days`: VAT-Z w 30 dni → Termin
else :=   {"matched":true,"rule_id":"jdg.vat.a96.r8","package":"jdg.micro.vat.plan34","priority": 69608,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"VAT-Z w 30 dni","_legal_basis":"Art. 96 VAT (rejestracja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a96.r9 — `vat_z_ex_officio_deregistration`: 6 mies. bez sprzedaży → z urzędu → Sankcja
else :=   {"matched":true,"rule_id":"jdg.vat.a96.r9","package":"jdg.micro.vat.plan34","priority": 69609,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"6 mies. bez sprzedaży → z urzędu","_legal_basis":"Art. 96 VAT (rejestracja)","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.vat.a96.r10 — `vat_r_eu_registration_for_wdt`: VAT-UE przed pierwszym WDT → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.vat.a96.r10","package":"jdg.micro.vat.plan34","priority": 69610,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"VAT-UE przed pierwszym WDT","_legal_basis":"Art. 96 VAT (rejestracja)","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "WDT"; object.get(input.jdg_entrepreneur, "is_vat_eu_registered", false) == true
}

# jdg.vat.a96.r11 — `vat_r_eu_refusal_crossborder`: Brak VAT-UE = brak WDT → Konsekwencja
else :=   {"matched":true,"rule_id":"jdg.vat.a96.r11","package":"jdg.micro.vat.plan34","priority": 69611,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Brak VAT-UE = brak WDT","_legal_basis":"Art. 96 VAT (rejestracja)","_warnings":[]} {
    object.get(input.invoice, "procedure", "") == "WDT"; object.get(input.jdg_entrepreneur, "is_vat_eu_registered", false) == true
}

# jdg.vat.a99.r1 — `vat_declaration_monthly_obligation`: Czynny podatnik VAT → JPK_V7M miesięcznie
else :=   {"matched":true,"rule_id":"jdg.vat.a99.r1","package":"jdg.micro.vat.plan34","priority": 69901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Czynny podatnik VAT","_legal_basis":"Art. 99 ustawy o VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a99.r2 — `vat_declaration_quarterly_small`: Mały podatnik → JPK_V7K kwartalnie
else :=   {"matched":true,"rule_id":"jdg.vat.a99.r2","package":"jdg.micro.vat.plan34","priority": 69902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Mały podatnik","_legal_basis":"Art. 99 ustawy o VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a99.r4 — `vat_declaration_monthly_deadline_25`: Termin 25. dnia miesiąca → Termin
else :=   {"matched":true,"rule_id":"jdg.vat.a99.r4","package":"jdg.micro.vat.plan34","priority": 69904,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Termin 25. dnia miesiąca","_legal_basis":"Art. 99 ustawy o VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a99.r5 — `vat_declaration_zero_if_no_sales`: Brak sprzedaży → zerowa → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.vat.a99.r5","package":"jdg.micro.vat.plan34","priority": 69905,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Brak sprzedaży → zerowa","_legal_basis":"Art. 99 ustawy o VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}

# jdg.vat.a106e.r1 — `invoice_mandatory_fields_nip`: NIP sprzedawcy i nabywcy → Pole obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.vat.a106e.r1","package":"jdg.micro.vat.plan34","priority": 70601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"NIP sprzedawcy i nabywcy","_legal_basis":"Art. 106e VAT (elementy faktury)","_warnings":[]} {
    object.get(input.invoice, "invoice_type", "") == "INVOICE"
}

# jdg.vat.a106j.r1 — `correction_invoice_minus_conditions`: Błąd ceny, rabat, zwrot → Korekta in minus
else :=   {"matched":true,"rule_id":"jdg.vat.a106j.r1","package":"jdg.micro.vat.plan34","priority": 70601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Błąd ceny, rabat, zwrot","_legal_basis":"Art. 106j ustawy o VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "is_correction", false) == true
}

# jdg.vat.a106na.r1 — `ksef_obligation_from_2026_02_01`: Faktury od 01.02.2026 → Obowiązek KSeF
else :=   {"matched":true,"rule_id":"jdg.vat.a106na.r1","package":"jdg.micro.vat.plan34","priority": 70601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Faktury od 01.02.2026","_legal_basis":"Art. 106na ustawy o VAT","_warnings":[]} {
    object.get(input.invoice, "ksef_required", false) == true
}

# jdg.vat.a106ne.r1 — `ksef_offline_7_days_recovery`: Awaria KSeF → 7 dni → Tryb awaryjny
else :=   {"matched":true,"rule_id":"jdg.vat.a106ne.r1","package":"jdg.micro.vat.plan34","priority": 70601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Awaria KSeF → 7 dni","_legal_basis":"Art. 106ne ustawy o VAT","_warnings":[]} {
    object.get(input.invoice, "ksef_required", false) == true
}

# jdg.vat.a106ng.r1 — `ksef_upo_confirmation_mandatory`: UPO dla każdej faktury → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.vat.a106ng.r1","package":"jdg.micro.vat.plan34","priority": 70601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"UPO dla każdej faktury","_legal_basis":"Art. 106ng ustawy o VAT","_warnings":[]} {
    object.get(input.invoice, "ksef_required", false) == true
}

# jdg.vat.a106nh.r1 — `ksef_qr_code_mandatory`: Kod QR na fakturze → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.vat.a106nh.r1","package":"jdg.micro.vat.plan34","priority": 70601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Kod QR na fakturze","_legal_basis":"Art. 106nh ustawy o VAT","_warnings":[]} {
    object.get(input.invoice, "ksef_required", false) == true
}

# jdg.vat.a106nq.r1 — `ksef_sanction_100pct_additional`: Sankcja: 100% VAT (max 500k) → Sankcja
else :=   {"matched":true,"rule_id":"jdg.vat.a106nq.r1","package":"jdg.micro.vat.plan34","priority": 70601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Sankcja: 100% VAT (max 500k)","_legal_basis":"Art. 106ga ust. 1 ustawy o VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "ksef_required", false) == true; object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.vat.a106e.r2 — `invoice_mandatory_fields_date`: Data wystawienia i sprzedaży → Pole obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.vat.a106e.r2","package":"jdg.micro.vat.plan34","priority": 70602,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Data wystawienia i sprzedaży","_legal_basis":"Art. 106e VAT (elementy faktury)","_warnings":[]} {
    object.get(input.invoice, "invoice_type", "") == "INVOICE"
}

# jdg.vat.a106j.r3 — `correction_buyer_agreement_minus`: Potwierdzenie nabywcy → Warunek korekty
else :=   {"matched":true,"rule_id":"jdg.vat.a106j.r3","package":"jdg.micro.vat.plan34","priority": 70603,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Potwierdzenie nabywcy","_legal_basis":"Art. 106j ustawy o VAT","_warnings":[]} {
    object.get(input.invoice, "is_correction", false) == true
}

# jdg.vat.a106na.r3 — `ksef_obligation_vat_exempt_exception`: Zwolnieni z VAT → wyłączeni → Wyjątek
else :=   {"matched":true,"rule_id":"jdg.vat.a106na.r3","package":"jdg.micro.vat.plan34","priority": 70603,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Zwolnieni z VAT → wyłączeni","_legal_basis":"Art. 106na ustawy o VAT","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "vat_deduction_blocked", false) == true; object.get(input.invoice, "ksef_required", false) == true
}

# jdg.vat.a106na.r4 — `ksef_obligation_b2c_exception`: B2C → wyłączone → Wyjątek
else :=   {"matched":true,"rule_id":"jdg.vat.a106na.r4","package":"jdg.micro.vat.plan34","priority": 70604,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"B2C → wyłączone","_legal_basis":"Art. 106na ustawy o VAT","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "vat_deduction_blocked", false) == true; object.get(input.invoice, "ksef_required", false) == true
}

# jdg.vat.a106e.r5 — `invoice_mandatory_fields_item_description`: Nazwa, ilość, cena jednostkowa → Pole obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.vat.a106e.r5","package":"jdg.micro.vat.plan34","priority": 70605,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Nazwa, ilość, cena jednostkowa","_legal_basis":"Art. 106e VAT (elementy faktury)","_warnings":[]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.0; object.get(input.invoice, "invoice_type", "") == "INVOICE"
}

# jdg.vat.a106e.r6 — `invoice_mandatory_fields_vat_rate`: Stawka VAT i kwota → Pole obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.vat.a106e.r6","package":"jdg.micro.vat.plan34","priority": 70606,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Stawka VAT i kwota","_legal_basis":"Art. 106e VAT (elementy faktury)","_warnings":[]} {
    object.get(input.invoice, "invoice_type", "") == "INVOICE"
}

# jdg.vat.a106j.r8 — `correction_storno_full_cancel`: Anulowanie faktury → Storno
else :=   {"matched":true,"rule_id":"jdg.vat.a106j.r8","package":"jdg.micro.vat.plan34","priority": 70608,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Anulowanie faktury","_legal_basis": "Ustawa o VAT (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} {
    object.get(input.invoice, "is_correction", false) == true; object.get(input.invoice, "is_storno", false) == true
}

# jdg.vat.a106e.r10 — `invoice_simplified_receipt_450_pln`: Paragon z NIP ≤450 PLN → Faktura uproszczona
else :=   {"matched":true,"rule_id":"jdg.vat.a106e.r10","package":"jdg.micro.vat.plan34","priority": 70610,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Paragon z NIP ≤450 PLN","_legal_basis":"Art. 106e VAT (elementy faktury)","_warnings":[]} {
    object.get(input.invoice, "invoice_type", "") == "INVOICE"; object.get(input.invoice, "invoice_type", "") == "RECEIPT"
}

# jdg.vat.a106e.r14 — `invoice_advance_invoice`: Otrzymanie zaliczki → Faktura zaliczkowa
else :=   {"matched":true,"rule_id":"jdg.vat.a106e.r14","package":"jdg.micro.vat.plan34","priority": 70614,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","valid_from":"2026-01-01","valid_to":null,"_routing":"","_routing_reason":"Otrzymanie zaliczki","_legal_basis":"Art. 106e VAT (elementy faktury)","_warnings":[]} {
    object.get(input.invoice, "invoice_type", "") == "INVOICE"; object.get(input.invoice, "prepayment_received", false) == true
}
