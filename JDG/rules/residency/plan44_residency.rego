# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.residency
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 2
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.residency
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.residency.no_match","package":"jdg.residency","priority":99999}

# jdg.residency.determination — Określenie rezydencji podatkowej — test 183 dni
decide :=   {"matched":true,"rule_id":"jdg.residency.determination","package":"jdg.residency","priority":1940,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Określenie rezydencji podatkowej — test 183 dni","_legal_basis":"Art. 3 PIT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
}

# jdg.residency.exit_tax — Exit tax przy zmianie rezydencji — próg 4M PLN, stawka 19%
else :=   {"matched":true,"rule_id":"jdg.residency.exit_tax","package":"jdg.residency","priority":1944,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Exit tax przy zmianie rezydencji — próg 4M PLN, stawka 19%","_legal_basis":"Art. 30da PIT","_warnings":["Zmiana rezydencji podatkowej — exit tax od aktywów >4M PLN!"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
}
