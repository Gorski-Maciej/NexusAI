# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.business
# Generated from Plan OPA specifications: 2026-07-13 14:05:06
# Rules: 5
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.business
import data.jdg.helpers

# R02 T7: usunięto zduplikowany default decide (rule_id jdg.business.no_match) —
# pojedynczy default żyje w business.rego (1 wersja prawdy w pakiecie jdg.business).

# jdg.business.resumption_procedure_valid — Wznowienie JDG — zgłoszenie CEIDG + obowiązki
decide :=   {"matched":true,"rule_id":"jdg.business.resumption_procedure_valid","package":"jdg.business","priority":916,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Wznowienie JDG — zgłoszenie CEIDG + obowiązki","_legal_basis":"Art. 22-25 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)","_warnings":["Wznowienie bez zgłoszenia CEIDG — zgłoś natychmiast"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.business.maximum_suspension_period_check — Maks. 6 mies. ciągłego zawieszenia
else :=   {"matched":true,"rule_id":"jdg.business.maximum_suspension_period_check","package":"jdg.business","priority":918,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Maks. 6 mies. ciągłego zawieszenia","_legal_basis":"Art. 22 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)","_warnings":["Zawieszenie >6 mies. — rozważ wznowienie lub zamknięcie"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "SUSPENDED"
}

# jdg.business.succession_manager_appointment — Powołanie zarządcy sukcesyjnego — za życia lub 2 mies. po śmierci
else :=   {"matched":true,"rule_id":"jdg.business.succession_manager_appointment","package":"jdg.business","priority":925,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Powołanie zarządcy sukcesyjnego — za życia lub 2 mies. po śmierci","_legal_basis":"Art. 3-7 ustawy o zarządzie sukcesyjnym","_warnings":["Zarządca powołany niezgodnie z procedurą — zarząd nieskuteczny"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "IN_SUCCESSIO"
}

# jdg.business.succession_time_limit_expiry — Zarząd sukcesyjny — max 2 lata (5 lat z przedłużeniem)
else :=   {"matched":true,"rule_id":"jdg.business.succession_time_limit_expiry","package":"jdg.business","priority":926,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Zarząd sukcesyjny — max 2 lata (5 lat z przedłużeniem)","_legal_basis":"Art. 12-13 ustawy o zarządzie sukcesyjnym","_warnings":["Zarząd sukcesyjny wygasł — NIP nieaktywny"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "IN_SUCCESSIO"
}

# jdg.business.succession_termination_events — Wygaśnięcie zarządu — śmierć, rezygnacja, upadłość
else :=   {"matched":true,"rule_id":"jdg.business.succession_termination_events","package":"jdg.business","priority":927,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Wygaśnięcie zarządu — śmierć, rezygnacja, upadłość","_legal_basis":"Art. 14-15 ustawy o zarządzie sukcesyjnym","_warnings":["Zarząd sukcesyjny wygasł"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "IN_SUCCESSIO"
}
