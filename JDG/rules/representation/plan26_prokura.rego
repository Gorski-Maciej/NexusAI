# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.representation
# Generated from Plan OPA specifications: 2026-07-13 14:05:06
# Rules: 1
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.representation
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.representation.no_match","package":"jdg.representation","priority":99999}

# jdg.representation.prokura_types_detailed — Typy prokury — samoistna, łączna, oddziałowa
decide :=   {"matched":true,"rule_id":"jdg.representation.prokura_types_detailed","package":"jdg.representation","priority":1205,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Typy prokury — samoistna, łączna, oddziałowa","_legal_basis":"Art. 109¹-109⁸ KC","_warnings":["Prokura niewpisana w CEIDG — nieskuteczna!"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}
