# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.pit
# Generated from Plan OPA specifications: 2026-07-13 14:05:06
# Rules: 1
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.pit
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.pit.no_match","package":"jdg.pit","priority":99999}

# jdg.pit.exemption_interactions_shared_limit — Zwolnienia PIT — wspólny limit 85 528 PLN
decide :=   {"matched":true,"rule_id":"jdg.pit.exemption_interactions_shared_limit","package":"jdg.pit","priority":588,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Zwolnienia PIT — wspólny limit 85 528 PLN","_legal_basis":"Art. 21 ust. 1 pkt 148, 152, 153, 154 PIT","_warnings":["Zwolnienia PIT współdzielą limit 85 528 PLN — nie sumują się"]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "married", false) == true
}
