# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.zus
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 8
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.zus
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.zus.plan42.no_match","package":"jdg.zus","priority":99999}

# jdg.zus.contribution_base_calculation — Podstawa wymiaru składek społecznych — 60% przeciętnego wynagrodzenia
decide :=   {"matched":true,"rule_id":"jdg.zus.contribution_base_calculation","package":"jdg.zus","priority":770,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa wymiaru składek społecznych — 60% przeciętnego wynagrodzenia","_legal_basis":"Art. 18 ust. 8 SUS","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.contribution_split_by_fund — Rozbicie składek ZUS na fundusze
else :=   {"matched":true,"rule_id":"jdg.zus.contribution_split_by_fund","package":"jdg.zus","priority":771,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rozbicie składek ZUS na fundusze","_legal_basis":"Art. 22 SUS","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.contribution_deadline — Terminy opłacania składek ZUS (10/15/20 dzień miesiąca)
else :=   {"matched":true,"rule_id":"jdg.zus.contribution_deadline","package":"jdg.zus","priority":772,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Terminy opłacania składek ZUS (10/15/20 dzień miesiąca)","_legal_basis":"Art. 47 ust. 1-2 SUS","_warnings":["Składki ZUS po terminie — naliczane odsetki!"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.contribution_payment_verification — Weryfikacja czy wszystkie składki ZUS opłacone
else :=   {"matched":true,"rule_id":"jdg.zus.contribution_payment_verification","package":"jdg.zus","priority":773,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Weryfikacja czy wszystkie składki ZUS opłacone","_legal_basis":"Art. 47 SUS","_warnings":["Niedopłata składek ZUS — ryzyko egzekucji!"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.sickness_benefit_eligibility — Zasiłek chorobowy JDG — warunki (90 dni wyczekiwania)
else :=   {"matched":true,"rule_id":"jdg.zus.sickness_benefit_eligibility","package":"jdg.zus","priority":1200,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zasiłek chorobowy JDG — warunki (90 dni wyczekiwania)","_legal_basis":"Art. 4 ust. 1, Art. 7, Art. 48-54 Ustawy zasiłkowej","_warnings":["Sprawdź uprawnienia do zasiłku chorobowego — okres wyczekiwania 90 dni"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "zus_sickness_voluntary", false) == true; object.get(input.jdg_entrepreneur, "benefit_claim_filed", false) == true
}

# jdg.zus.sickness_benefit_amount — Wysokość zasiłku chorobowego — 80% podstawy
else :=   {"matched":true,"rule_id":"jdg.zus.sickness_benefit_amount","package":"jdg.zus","priority":1201,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wysokość zasiłku chorobowego — 80% podstawy","_legal_basis":"Art. 36-45 Ustawy zasiłkowej","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "zus_sickness_voluntary", false) == true; object.get(input.jdg_entrepreneur, "benefit_claim_filed", false) == true
}

# jdg.zus.benefit_payment_deadline — Terminy wypłaty zasiłków — ZUS ma 30 dni
else :=   {"matched":true,"rule_id":"jdg.zus.benefit_payment_deadline","package":"jdg.zus","priority":1205,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Terminy wypłaty zasiłków — ZUS ma 30 dni","_legal_basis":"Art. 61-64 Ustawy zasiłkowej","_warnings":["ZUS nie wypłacił zasiłku w terminie 30 dni — należą się odsetki"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "benefit_claim_filed", false) == true; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.benefit_overpayment_detection — Nienależnie pobrany zasiłek — praca podczas L4
else :=   {"matched":true,"rule_id":"jdg.zus.benefit_overpayment_detection","package":"jdg.zus","priority":1206,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Nienależnie pobrany zasiłek — praca podczas L4","_legal_basis":"Art. 66-68 Ustawy zasiłkowej","_warnings":["Aktywność biznesowa podczas zwolnienia — zasiłek nienależny!"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "benefit_claim_filed", false) == true
}
