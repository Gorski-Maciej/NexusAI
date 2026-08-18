# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.local_taxes
# Generated from Plan OPA specifications: 2026-07-17 09:28:41
# Rules: 6
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.local_taxes.plan26
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.local_taxes.plan26_local.no_match","package":"jdg.local_taxes.plan26","priority":99999}

# jdg.local_taxes.pcc_purchase_from_private — PCC 2% od zakupu od osoby prywatnej >1000 PLN
decide :=   {"matched":true,"rule_id":"jdg.local_taxes.pcc_purchase_from_private","package":"jdg.local_taxes.plan26","priority":1300,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"PCC 2% od zakupu od osoby prywatnej >1000 PLN","_legal_basis":"ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789), Art. 1-2, Art. 7","_warnings":["Zakup od osoby prywatnej — PCC-3 w 14 dni, stawka 2%"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.local_taxes.pcc_loan_from_private — PCC 0.5% od pożyczki od osoby prywatnej
else :=   {"matched":true,"rule_id":"jdg.local_taxes.pcc_loan_from_private","package":"jdg.local_taxes.plan26","priority":1302,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"PCC 0.5% od pożyczki od osoby prywatnej","_legal_basis":"ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789), Art. 7 ust. 1 pkt 4","_warnings":["Pożyczka od osoby prywatnej — PCC-3 w 14 dni, 0.5%"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "expense_type", "") == "LOAN"; object.get(input.vendor, "is_company", true) == false
}

# jdg.local_taxes.pcc_company_exempt_info — JDG nie podlega PCC od wkładów kapitałowych
else :=   {"matched":true,"rule_id":"jdg.local_taxes.pcc_company_exempt_info","package":"jdg.local_taxes.plan26","priority":1304,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG nie podlega PCC od wkładów kapitałowych","_legal_basis":"ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.local_taxes.real_estate_commercial_rate — Podatek od nieruchomości — wyższa stawka dla powierzchni firmowej
else :=   {"matched":true,"rule_id":"jdg.local_taxes.real_estate_commercial_rate","package":"jdg.local_taxes.plan26","priority":1310,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Podatek od nieruchomości — wyższa stawka dla powierzchni firmowej","_legal_basis":"ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234), Art. 2-7","_warnings":["Home office — wyższa stawka podatku od nieruchomości. Złóż DN-1"]} {
    object.get(input.jdg_entrepreneur, "home_office_area_sqm", 0) > 0; input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.local_taxes.real_estate_dn1_filing — DN-1 — deklaracja na podatek od nieruchomości, 14 dni
else :=   {"matched":true,"rule_id":"jdg.local_taxes.real_estate_dn1_filing","package":"jdg.local_taxes.plan26","priority":1312,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"DN-1 — deklaracja na podatek od nieruchomości, 14 dni","_legal_basis":"ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)","_warnings":["DN-1 niezłożona w terminie 14 dni!"]} {
    object.get(input.jdg_entrepreneur, "home_office_area_sqm", 0) > 0; input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.local_taxes.transport_tax_applicable — Podatek od środków transportowych — pojazdy >3.5t
else :=   {"matched":true,"rule_id":"jdg.local_taxes.transport_tax_applicable","package":"jdg.local_taxes.plan26","priority":1320,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Podatek od środków transportowych — pojazdy >3.5t","_legal_basis":"ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234), Rozdział 3","_warnings":["Pojazd >3.5t — obowiązek podatku od środków transportowych"]} {
    object.get(input.invoice, "vehicle_weight_kg", 0) > 3500
}
