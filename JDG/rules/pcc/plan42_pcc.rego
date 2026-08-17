# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.pcc
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 4
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.pcc
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.pcc.no_match","package":"jdg.pcc","priority":99999}

# jdg.pcc.loan_from_private_person — PCC od pożyczki od osoby prywatnej — 0.5%
decide :=   {"matched":true,"rule_id":"jdg.pcc.loan_from_private_person","package":"jdg.pcc","priority":1301,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"PCC od pożyczki od osoby prywatnej — 0.5%","_legal_basis":"Art. 1 ust. 1 pkt 2, Art. 7 ust. 1 pkt 4 Ustawy o PCC","_warnings":["Pożyczka od osoby prywatnej — PCC-3 w ciągu 14 dni!"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "expense_type", "") == "LOAN"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.car_purchase_from_private — PCC od zakupu samochodu od osoby prywatnej — 2%
else :=   {"matched":true,"rule_id":"jdg.pcc.car_purchase_from_private","package":"jdg.pcc","priority":1302,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"PCC od zakupu samochodu od osoby prywatnej — 2%","_legal_basis":"Art. 1 ust. 1 pkt 1 lit. a Ustawy o PCC","_warnings":["Zakup auta od osoby prywatnej — PCC-3 w ciągu 14 dni, stawka 2%"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "category_code", "") == "CAR"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.real_estate_purchase — PCC od zakupu nieruchomości od osoby prywatnej — 2%
else :=   {"matched":true,"rule_id":"jdg.pcc.real_estate_purchase","package":"jdg.pcc","priority":1303,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"PCC od zakupu nieruchomości od osoby prywatnej — 2%","_legal_basis":"Art. 1 ust. 1 pkt 1 lit. a Ustawy o PCC","_warnings":["Zakup nieruchomości od osoby prywatnej — PCC 2%, notariusz pobiera"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "category_code", "") == "REAL_ESTATE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.aggregate_liability_check — Agregacja wszystkich zobowiązań PCC
else :=   {"matched":true,"rule_id":"jdg.pcc.aggregate_liability_check","package":"jdg.pcc","priority":1304,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Agregacja wszystkich zobowiązań PCC","_legal_basis":"ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)","_warnings":["Niezłożone deklaracje PCC-3 w roku podatkowym"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}
