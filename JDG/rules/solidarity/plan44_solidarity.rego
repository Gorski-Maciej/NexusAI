# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.solidarity
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 1
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.solidarity
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.solidarity.no_match","package":"jdg.solidarity","priority":99999}

# jdg.solidarity.threshold_detection — Danina solidarnościowa 4% — próg 1 000 000 PLN
decide :=   {"matched":true,"rule_id":"jdg.solidarity.threshold_detection","package":"jdg.solidarity","priority":1810,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Danina solidarnościowa 4% — próg 1 000 000 PLN","_legal_basis":"Art. 30h PIT","_warnings":["Dochód przekroczył 1M PLN — danina solidarnościowa 4% od nadwyżki!"]} {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}
