# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 21

package jdg.hyper.audit

default decide := {"matched":false,"rule_id":"jdg.hyper.audit.no_match","package":"jdg.hyper.audit","priority":99999}

# jdg.hyper.audit.wis.binding_effect.not_against_law_change — WIS
decide :=   {"matched":true,"rule_id":"jdg.hyper.audit.wis.binding_effect.not_against_law_change","package":"jdg.hyper.audit","priority":1090,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"NIE chroni przed zmianą przepisów ustawowych","_legal_basis":"Art. 42h ust. 1 VAT","_warnings":["WIS nie chroni przed zmianą przepisów ustawowych"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.audit.wis.binding_effect.covers_future_transactions — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.wis.binding_effect.covers_future_transactions","package":"jdg.hyper.audit","priority":1091,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Obejmuje transakcje od dnia wydania WIS","_legal_basis":"Art. 42h ust. 1 VAT","_warnings":["WIS obejmuje transakcje od dnia wydania"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.audit.wis.gtu.mapping_obligation — WIS→GTU
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.wis.gtu.mapping_obligation","package":"jdg.hyper.audit","priority":1092,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"WIS determinuje kod GTU w JPK_V7","_legal_basis":"Art. 42h ust. 1 VAT, Rozp. JPK_VAT","_warnings":["WIS determinuje kod GTU w JPK_V7"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.audit.wis.sanction.incorrect_rate_no_wis — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.wis.sanction.incorrect_rate_no_wis","package":"jdg.hyper.audit","priority":1093,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Bez WIS przy niejednoznacznym CN → ryzyko KKS Art. 64","_legal_basis":"Art. 64 KKS, Art. 42b VAT","_warnings":["Bez WIS przy niejednoznacznym CN → ryzyko KKS Art. 64"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.audit.wis.interaction.tax_audit_protection — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.wis.interaction.tax_audit_protection","package":"jdg.hyper.audit","priority":1094,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Posiadanie WIS = ochrona przed zakwestionowaniem stawki","_legal_basis":"Art. 42h ust. 1 VAT","_warnings":["Posiadanie WIS = ochrona przed zakwestionowaniem stawki"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.audit.wis.interaction.individual_interpretation — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.wis.interaction.individual_interpretation","package":"jdg.hyper.audit","priority":1095,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"WIS ma pierwszeństwo przed interpretacją indywidualną w zakresie CN","_legal_basis":"Art. 42h ust. 1 VAT","_warnings":["WIS ma pierwszeństwo przed interpretacją indywidualną w zakresie CN"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.audit.wit.eligibility.import_non_eu — WIT
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.wit.eligibility.import_non_eu","package":"jdg.hyper.audit","priority":1096,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Import spoza UE → zalecenie WIT dla ceł","_legal_basis":"UKC, Art. 33 Rozp. 952/2013","_warnings":["Import spoza UE → zalecenie WIT dla ceł"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.audit.wit.validity.3_years — WIT
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.wit.validity.3_years","package":"jdg.hyper.audit","priority":1097,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"WIT ważna 3 lata (krócej niż WIS)","_legal_basis":"UKC, Art. 33 Rozp. 952/2013","_warnings":["WIT ważna 3 lata (krócej niż WIS)"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.audit.wit.cost.free — WIT
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.wit.cost.free","package":"jdg.hyper.audit","priority":1098,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WIT jest bezpłatna","_legal_basis":"UKC","_warnings":["WIT jest bezpłatna"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.audit.wit.binding_effect.customs_authorities — WIT
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.wit.binding_effect.customs_authorities","package":"jdg.hyper.audit","priority":1099,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"WIT wiąże organy celne wszystkich krajów UE","_legal_basis":"UKC, Art. 33 Rozp. 952/2013","_warnings":["WIT wiąże organy celne wszystkich krajów UE"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.audit.wia.eligibility.excise_goods — WIA
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.wia.eligibility.excise_goods","package":"jdg.hyper.audit","priority":1100,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Handel alkoholem, tytoniem, energią → zalecenie WIA","_legal_basis":"Ustawa o podatku akcyzowym","_warnings":["Handel alkoholem, tytoniem, energią → zalecenie WIA"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.audit.wia.validity.3_years — WIA
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.wia.validity.3_years","package":"jdg.hyper.audit","priority":1101,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WIA ważna 3 lata","_legal_basis":"Ustawa o podatku akcyzowym","_warnings":["WIA ważna 3 lata"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.audit.wia.cost.250_pln — WIA
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.wia.cost.250_pln","package":"jdg.hyper.audit","priority":1102,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Opłata za WIA: 250 PLN","_legal_basis":"Ustawa o podatku akcyzowym","_warnings":["Opłata za WIA: 250 PLN"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.audit.binding_info.cost_benefit_analysis — Analiza
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.binding_info.cost_benefit_analysis","package":"jdg.hyper.audit","priority":1103,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Kalkulacja: koszt WIS (40 PLN) vs ryzyko błędnej stawki (KKS + zaległość)","_legal_basis":"Art. 42g VAT, Art. 42b VAT","_warnings":["Kalkulacja: koszt WIS (40 PLN) vs ryzyko błędnej stawki"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.audit.binding_info.renewal_strategy — Strategia
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.binding_info.renewal_strategy","package":"jdg.hyper.audit","priority":1104,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Automatyczna rekomendacja odnowienia przed wygaśnięciem","_legal_basis":"Art. 42h VAT","_warnings":["Automatyczna rekomendacja odnowienia przed wygaśnięciem"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.audit.binding_info.portfolio.management — Portfolio
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.binding_info.portfolio.management","package":"jdg.hyper.audit","priority":1105,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zarządzanie portfelem wszystkich WIS/WIT/WIA","_legal_basis":"Art. 42b-42d VAT","_warnings":["Zarządzanie portfelem WIS/WIT/WIA — monitoruj daty wygaśnięcia i zmiany przepisów"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.audit.audit.type.verification — Typ
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.audit.type.verification","package":"jdg.hyper.audit","priority":1106,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Czynności sprawdzające (Art. 272-280 OP) — max 7 dni","_legal_basis":"Art. 272-280 OP","_warnings":["Czynności sprawdzające — max 7 dni"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.audit.audit.type.tax_audit — Typ
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.audit.type.tax_audit","package":"jdg.hyper.audit","priority":1107,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Kontrola podatkowa (Art. 281-292 OP) — max 30 dni","_legal_basis":"Art. 281-292 OP","_warnings":["Kontrola podatkowa — max 30 dni"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.audit.audit.type.tax_proceeding — Typ
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.audit.type.tax_proceeding","package":"jdg.hyper.audit","priority":1108,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Postępowanie podatkowe (Art. 120-129 OP) — bez limitu","_legal_basis":"Art. 120-129 OP","_warnings":["Postępowanie podatkowe — bez limitu"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.audit.audit.type.customs_fiscal — Typ
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.audit.type.customs_fiscal","package":"jdg.hyper.audit","priority":1109,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Kontrola celno-skarbowa (Art. 54-93 KAS) — max 3 mies.","_legal_basis":"Art. 54-93 KAS","_warnings":["Kontrola celno-skarbowa — max 3 mies."]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.audit.audit.trigger.cross_checking — Wyzwalacz
else :=   {"matched":true,"rule_id":"jdg.hyper.audit.audit.trigger.cross_checking","package":"jdg.hyper.audit","priority":1110,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Weryfikacja krzyżowa deklaracji → czynności sprawdzające","_legal_basis":"Art. 272-274 OP","_warnings":["Weryfikacja krzyżowa deklaracji → czynności sprawdzające"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}
