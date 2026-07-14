# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.solidarity (Doc 44: P1810-P1814)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 5
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.solidarity
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.solidarity.no_match","package":"jdg.solidarity","priority":99999}

# jdg.solidarity.threshold_detection — P1810: Danina solidarnościowa 4% — próg 1 000 000 PLN
decide :=   {"matched":true,"rule_id":"jdg.solidarity.threshold_detection","package":"jdg.solidarity","priority":1810,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Danina solidarnościowa 4% — próg 1 000 000 PLN","_legal_basis":"Art. 30h PIT","_warnings":["Dochód przekroczył 1M PLN — danina solidarnościowa 4% od nadwyżki!"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.solidarity.income_aggregation — P1811: Agregacja dochodów z różnych źródeł
else :=   {"matched":true,"rule_id":"jdg.solidarity.income_aggregation","package":"jdg.solidarity","priority":1811,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Agregacja dochodów z różnych źródeł dla daniny solidarnościowej","_legal_basis":"Art. 30h ust. 2-4 PIT","_warnings":["Sumujesz dochody ze wszystkich źródeł — próg 1M PLN łączny"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
    object.get(input.jdg_entrepreneur, "income_aggregated", false) == false
}

# jdg.solidarity.zus_exclusion — P1812: Wyłączenie składek ZUS społecznych z podstawy daniny
else :=   {"matched":true,"rule_id":"jdg.solidarity.zus_exclusion","package":"jdg.solidarity","priority":1812,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wyłączenie składek ZUS (społecznych) z podstawy daniny solidarnościowej","_legal_basis":"Art. 30h ust. 2 PIT","_warnings":["Składki emerytalne i rentowe ZUS pomniejszają podstawę daniny"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
    object.get(input.jdg_entrepreneur, "zus_excluded_from_base", false) == false
}

# jdg.solidarity.payment_deadline — P1813: Termin zapłaty daniny — 30 kwietnia następnego roku
else :=   {"matched":true,"rule_id":"jdg.solidarity.payment_deadline","package":"jdg.solidarity","priority":1813,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Danina solidarnościowa — termin zapłaty do 30 kwietnia","_legal_basis":"Art. 30h ust. 5 PIT","_warnings":["Danina solidarnościowa — zapłać do 30 kwietnia następnego roku. Brak zaliczek!"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
    object.get(input.jdg_entrepreneur, "payment_deadline_notified", false) == false
}

# jdg.solidarity.foreign_income_exemption — P1814: Wyłączenie dochodów zagranicznych
else :=   {"matched":true,"rule_id":"jdg.solidarity.foreign_income_exemption","package":"jdg.solidarity","priority":1814,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wyłączenie dochodów zagranicznych — metoda wyłączenia z progresją","_legal_basis":"Art. 30h ust. 3 PIT","_warnings":["Dochody zagraniczne zwolnione przez UPO nie wchodzą do podstawy daniny"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
    object.get(input.jdg_entrepreneur, "has_foreign_income", false) == true
    object.get(input.jdg_entrepreneur, "foreign_income_excluded", false) == false
}
