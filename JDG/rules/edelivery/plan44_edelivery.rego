# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.edelivery
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 2
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.edelivery
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.edelivery.no_match","package":"jdg.edelivery","priority":99999}

# jdg.edelivery.fiction_detection — Fikcja doręczenia e-Doręczeń po 14 dniach
decide :=   {"matched":true,"rule_id":"jdg.edelivery.fiction_detection","package":"jdg.edelivery","priority":1870,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Fikcja doręczenia e-Doręczeń po 14 dniach","_legal_basis":"Ustawa o doręczeniach elektronicznych","_warnings":["PISMO UZNANE ZA DORĘCZONE PRZEZ FIKCJĘ! Sprawdź natychmiast e-US!"]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.edelivery.platform_monitoring — Monitorowanie konta e-US
else :=   {"matched":true,"rule_id":"jdg.edelivery.platform_monitoring","package":"jdg.edelivery","priority":1871,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Monitorowanie konta e-US","_legal_basis":"Art. 144b Ordynacji podatkowej","_warnings":["Nowe pisma na e-US — sprawdź skrzynkę"]} {
    object.get(input.document, "edelivery_notification", false) == true
}
