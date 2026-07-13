# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.family
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 2
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.family
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.family.no_match","package":"jdg.family","priority":99999}

# jdg.family.spouse_employment_kup — Wynagrodzenie małżonka — warunki KUP
decide :=   {"matched":true,"rule_id":"jdg.family.spouse_employment_kup","package":"jdg.family","priority":1860,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Wynagrodzenie małżonka — warunki KUP","_legal_basis":"Art. 22 ust. 1 PIT, Art. 23 ust. 1 pkt 10 PIT","_warnings":["Wynagrodzenie małżonka — upewnij się, że spełnia kryteria rynkowe"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.family.child_employment_kup — Wynagrodzenie dziecka — ograniczenia KUP
else :=   {"matched":true,"rule_id":"jdg.family.child_employment_kup","package":"jdg.family","priority":1861,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Wynagrodzenie dziecka — ograniczenia KUP","_legal_basis":"Art. 23 ust. 1 pkt 10 PIT","_warnings":["Wynagrodzenie dziecka — podwyższone ryzyko kontroli US"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}
