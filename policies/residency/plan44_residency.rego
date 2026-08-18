# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.residency (Doc 44: P1940-P1949)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 10
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.residency
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.residency.no_match","package":"jdg.residency","priority":99999}

# jdg.residency.determination — Określenie rezydencji podatkowej — test 183 dni
decide :=   {"matched":true,"rule_id":"jdg.residency.determination","package":"jdg.residency","priority":1940,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Określenie rezydencji podatkowej — test 183 dni","_legal_basis":"Art. 3 PIT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
}

# jdg.residency.treaty_benefit — P1941: Umowy UPO (bez certyfikatu rezydencji)
else :=   {"matched":true,"rule_id":"jdg.residency.treaty_benefit","package":"jdg.residency","priority":1941,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowy o UPO — metoda wyłączenia z progresją vs odliczenia proporcjonalnego","_legal_basis":"Art. 27 ust. 8-9 PIT","_warnings":["Dochód zagraniczny — sprawdź umowę UPO: wyłączenie czy odliczenie"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
    object.get(input.jdg_entrepreneur, "has_foreign_income", false) == true
    object.get(input.jdg_entrepreneur, "dtt_checked", false) == false
}

# jdg.residency.certificate_of_residence — P1942: Certyfikat rezydencji (bez ulgi)
else :=   {"matched":true,"rule_id":"jdg.residency.certificate_of_residence","package":"jdg.residency","priority":1942,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Certyfikat rezydencji (CFR) — ważność 12 miesięcy od wydania","_legal_basis":"Art. 26 PIT","_warnings":["CFR kontrahenta — wymagany dla WHT i zwolnień. Ważność 12 miesięcy"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
    object.get(input.vendor, "is_foreign", false) == true
    object.get(input.vendor, "cfr_obtained", false) == false
}

# jdg.residency.foreign_tax_credit — P1943: Ulga abolicyjna / odliczenie podatku zagranicznego
else :=   {"matched":true,"rule_id":"jdg.residency.foreign_tax_credit","package":"jdg.residency","priority":1943,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga abolicyjna — maks = podatek PL przypadający na dochód zagraniczny","_legal_basis":"Art. 27g PIT","_warnings":["Maksymalne odliczenie podatku zagranicznego = podatek PL od dochodu zagranicznego"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
    object.get(input.jdg_entrepreneur, "foreign_tax_credit_needed", false) == true
}

# jdg.residency.exit_tax — P1944: Exit tax (tylko przy zmianie rezydencji)
else :=   {"matched":true,"rule_id":"jdg.residency.exit_tax","package":"jdg.residency","priority":1944,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Exit tax przy zmianie rezydencji — próg 4M PLN, stawka 19%","_legal_basis":"Art. 30da PIT","_warnings":["Zmiana rezydencji podatkowej — exit tax od aktywów >4M PLN!"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
    object.get(input.jdg_entrepreneur, "planning_residency_change", false) == true
}

# jdg.residency.dual_residency_conflict — P1945: Konflikt podwójnej rezydencji — tie-breaker rules
else :=   {"matched":true,"rule_id":"jdg.residency.dual_residency_conflict","package":"jdg.residency","priority":1945,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Konflikt podwójnej rezydencji — tie-breaker: stałe mieszkanie → interesy → pobyt → obywatelstwo","_legal_basis":"Umowy bilateralne (OECD MTC Art. 4)","_warnings":["Podwójna rezydencja — zastosuj tie-breaker rules z umowy bilateralnej"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
    object.get(input.jdg_entrepreneur, "dual_residency_conflict_active", false) == true
}

# jdg.residency.foreign_income_exemption_progression — P1946: Metoda wyłączenia z progresją
else :=   {"matched":true,"rule_id":"jdg.residency.foreign_income_exemption_progression","package":"jdg.residency","priority":1946,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"32","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Metoda wyłączenia z progresją — dochód zagraniczny wpływa na stawkę","_legal_basis":"Art. 27 ust. 8 PIT","_warnings":["Dochód zagraniczny zwolniony, ale wpływa na stawkę podatku od dochodu PL"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
    object.get(input.jdg_entrepreneur, "foreign_income_exemption_progression", false) == true
}

# jdg.residency.foreign_income_credit_method — P1947: Metoda odliczenia proporcjonalnego
else :=   {"matched":true,"rule_id":"jdg.residency.foreign_income_credit_method","package":"jdg.residency","priority":1947,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Metoda odliczenia — dochód zagraniczny opodatkowany w PL, odliczenie podatku do limitu","_legal_basis":"Art. 27 ust. 9 PIT","_warnings":["Dochód zagraniczny opodatkowany w PL — odlicz podatek zagraniczny do limitu"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
    object.get(input.jdg_entrepreneur, "foreign_income_credit_method", false) == true
}

# jdg.residency.permanent_establishment_risk — P1948: Zakład podatkowy za granicą — warunki
else :=   {"matched":true,"rule_id":"jdg.residency.permanent_establishment_risk","package":"jdg.residency","priority":1948,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Zakład podatkowy — plac budowy >12 mies., stałe miejsce, zależny przedstawiciel","_legal_basis":"Art. 4a PIT, OECD MTC Art. 5","_warnings":["Ryzyko zakładu podatkowego za granicą — >12 mies., stałe miejsce, zależny przedstawiciel"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
    object.get(input.jdg_entrepreneur, "permanent_establishment_risk", false) == true
}

# jdg.residency.digital_pe — P1949: Zakład wirtualny (bez PE fizycznego)
else :=   {"matched":true,"rule_id":"jdg.residency.digital_pe","package":"jdg.residency","priority":1949,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Digital PE — serwer za granicą, platforma, znacząca obecność cyfrowa (OECD BEPS 2.0)","_legal_basis":"OECD BEPS 2.0 Pillar 1","_warnings":["Digital PE — serwer w obcym kraju może tworzyć zakład podatkowy"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
    object.get(input.jdg_entrepreneur, "has_foreign_server", false) == true
    object.get(input.jdg_entrepreneur, "digital_pe_assessed", false) == false
}
