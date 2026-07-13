# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.audit
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 4
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.audit
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.audit.no_match","package":"jdg.audit","priority":99999}

# jdg.audit.type_determination — Typ kontroli podatkowej — czynności sprawdzające / kontrola / postępowanie
decide :=   {"matched":true,"rule_id":"jdg.audit.type_determination","package":"jdg.audit","priority":1830,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Typ kontroli podatkowej — czynności sprawdzające / kontrola / postępowanie","_legal_basis":"Art. 272-292 Ordynacji podatkowej","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.audit.rights_and_obligations — Prawa i obowiązki JDG podczas kontroli
else :=   {"matched":true,"rule_id":"jdg.audit.rights_and_obligations","package":"jdg.audit","priority":1831,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Prawa i obowiązki JDG podczas kontroli","_legal_basis":"Art. 281-292 Ordynacji podatkowej","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.audit.protocol_objections — Zastrzeżenia do protokołu kontroli — 14 dni
else :=   {"matched":true,"rule_id":"jdg.audit.protocol_objections","package":"jdg.audit","priority":1832,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zastrzeżenia do protokołu kontroli — 14 dni","_legal_basis":"Art. 291 § 1-2 Ordynacji podatkowej","_warnings":["Termin na zastrzeżenia do protokołu upływa — zostało X dni"]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.audit.statute_suspension — Zawieszenie przedawnienia na czas kontroli
else :=   {"matched":true,"rule_id":"jdg.audit.statute_suspension","package":"jdg.audit","priority":1833,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zawieszenie przedawnienia na czas kontroli","_legal_basis":"Art. 70 § 6 pkt 1 Ordynacji podatkowej","_warnings":["Kontrola w toku — bieg przedawnienia zawieszony"]} {
    object.get(input.document, "statute_suspended", false) == true; object.get(input.document, "audit_in_progress", false) == true
}
