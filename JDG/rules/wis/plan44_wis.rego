# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.wis
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 2
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.wis
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.wis.no_match","package":"jdg.wis","priority":99999}

# jdg.wis.binding_rate_check — WIS — identyfikacja towarów wymagających WIS
decide :=   {"matched":true,"rule_id":"jdg.wis.binding_rate_check","package":"jdg.wis","priority":1820,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"WIS — identyfikacja towarów wymagających WIS","_legal_basis":"Art. 42a-42h VAT","_warnings":["Towar o niejednoznacznej klasyfikacji — rozważ uzyskanie WIS"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.wis.validity_monitoring — Monitorowanie ważności WIS (5 lat)
else :=   {"matched":true,"rule_id":"jdg.wis.validity_monitoring","package":"jdg.wis","priority":1821,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Monitorowanie ważności WIS (5 lat)","_legal_basis":"Art. 42h VAT","_warnings":["WIS wygasa — złóż wniosek o nową"]} {
    object.get(input.invoice, "wis_required", false) == true
}
