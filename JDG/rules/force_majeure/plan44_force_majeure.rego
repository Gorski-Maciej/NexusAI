# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.force_majeure
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 3
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.force_majeure
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.force_majeure.no_match","package":"jdg.force_majeure","priority":99999}

# jdg.force_majeure.tax_relief — Ulgi podatkowe w przypadku siły wyższej
decide :=   {"matched":true,"rule_id":"jdg.force_majeure.tax_relief","package":"jdg.force_majeure","priority":1850,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulgi podatkowe w przypadku siły wyższej","_legal_basis":"Art. 67a-67e Ordynacji podatkowej","_warnings":["Siła wyższa — sprawdź dostępne ulgi podatkowe"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.force_majeure.zus_relief — Ulgi ZUS w przypadku siły wyższej
else :=   {"matched":true,"rule_id":"jdg.force_majeure.zus_relief","package":"jdg.force_majeure","priority":1851,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulgi ZUS w przypadku siły wyższej","_legal_basis":"Art. 28-29 SUS","_warnings":["Siła wyższa — możliwe odroczenie/umorzenie składek ZUS"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.force_majeure.documentation_loss — Utrata dokumentacji przez siłę wyższą — procedura odtworzenia
else :=   {"matched":true,"rule_id":"jdg.force_majeure.documentation_loss","package":"jdg.force_majeure","priority":1852,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Utrata dokumentacji przez siłę wyższą — procedura odtworzenia","_legal_basis":"Art. 86 § 2 Ordynacji podatkowej","_warnings":["Utrata dokumentów — zgłoś do US w 7 dni!"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
