# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.pit
# Generated from Plan OPA specifications: 2026-07-17 09:28:41
# Rules: 1
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.pit
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.pit.no_match","package":"jdg.pit","priority":99999}

# jdg.pit.revenue_exclusions_detail — Wyłączenia z przychodu — zwrot VAT, nadpłata ZUS, odszkodowania
decide :=   {"matched":true,"rule_id":"jdg.pit.revenue_exclusions_detail","package":"jdg.pit","priority":508,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wyłączenia z przychodu — zwrot VAT, nadpłata ZUS, odszkodowania","_legal_basis":"Art. 14 ust. 3 PIT","_warnings":[]} {
    true
}
