# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.procurement
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 1
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.procurement
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.procurement.no_match","package":"jdg.procurement","priority":99999}

# jdg.procurement.tax_clearance — Zaświadczenie o niezaleganiu dla zamówień publicznych
decide :=   {"matched":true,"rule_id":"jdg.procurement.tax_clearance","package":"jdg.procurement","priority":1880,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaświadczenie o niezaleganiu dla zamówień publicznych","_legal_basis":"Art. 306e Ordynacji podatkowej","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}
