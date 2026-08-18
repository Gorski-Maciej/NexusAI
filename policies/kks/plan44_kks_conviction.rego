# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.kks
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 2
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.kks
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.kks.no_match","package":"jdg.kks","priority":99999}

# jdg.kks.conviction_business_ban — Zakaz prowadzenia działalności po skazaniu KKS
decide :=   {"matched":true,"rule_id":"jdg.kks.conviction_business_ban","package":"jdg.kks","priority":1960,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Zakaz prowadzenia działalności po skazaniu KKS","_legal_basis":"Art. 41 KK","_warnings":["Skazanie KKS — zakaz prowadzenia działalności gospodarczej!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.conviction_rehabilitation — Zatarcie skazania KKS — 3/5 lat
else :=   {"matched":true,"rule_id":"jdg.kks.conviction_rehabilitation","package":"jdg.kks","priority":1964,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zatarcie skazania KKS — 3/5 lat","_legal_basis":"Art. 21 KKS, Art. 106 KK","_warnings":[]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}
