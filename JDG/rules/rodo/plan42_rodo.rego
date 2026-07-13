# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.rodo
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 3
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.rodo
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.rodo.no_match","package":"jdg.rodo","priority":99999}

# jdg.rodo.dpa_registration_check — Obowiązek rejestracji DPA w UODO
decide :=   {"matched":true,"rule_id":"jdg.rodo.dpa_registration_check","package":"jdg.rodo","priority":1610,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Obowiązek rejestracji DPA w UODO","_legal_basis":"Art. 30, 36 RODO","_warnings":["JDG przetwarza dane osobowe — sprawdź obowiązek rejestracji w UODO"]} {
    object.get(input.jdg_entrepreneur, "processes_personal_data", false) == true
}

# jdg.rodo.data_retention_policy — Okresy retencji danych osobowych
else :=   {"matched":true,"rule_id":"jdg.rodo.data_retention_policy","package":"jdg.rodo","priority":1612,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Okresy retencji danych osobowych","_legal_basis":"Art. 5 ust. 1 lit. e RODO","_warnings":["Przekroczony okres przechowywania danych osobowych"]} {
    object.get(input.jdg_entrepreneur, "processes_personal_data", false) == true
}

# jdg.rodo.dpo_requirement — Sprawdzenie czy JDG musi wyznaczyć DPO
else :=   {"matched":true,"rule_id":"jdg.rodo.dpo_requirement","package":"jdg.rodo","priority":1613,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Sprawdzenie czy JDG musi wyznaczyć DPO","_legal_basis":"Art. 37 RODO","_warnings":["JDG może wymagać Inspektora Ochrony Danych (DPO)"]} {
    object.get(input.jdg_entrepreneur, "processes_personal_data", false) == true
}
