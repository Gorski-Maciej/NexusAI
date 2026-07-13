# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.mdr
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 3
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.mdr
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.mdr.no_match","package":"jdg.mdr","priority":99999}

# jdg.mdr.reportable_scheme_detection — Wykrywanie schematów podatkowych MDR (DAC6)
decide :=   {"matched":true,"rule_id":"jdg.mdr.reportable_scheme_detection","package":"jdg.mdr","priority":1800,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Wykrywanie schematów podatkowych MDR (DAC6)","_legal_basis":"Art. 86a-86o Ordynacji podatkowej","_warnings":["Transakcja nosi cechy schematu MDR — obowiązek zgłoszenia MDR-3 w 30 dni! Sankcja do 5M PLN!"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.mdr.promoter_vs_user — Rola MDR: promotor vs korzystający
else :=   {"matched":true,"rule_id":"jdg.mdr.promoter_vs_user","package":"jdg.mdr","priority":1801,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Rola MDR: promotor vs korzystający","_legal_basis":"Art. 86a § 1 Ordynacji podatkowej","_warnings":["Ustalono rolę MDR — sprawdź obowiązki raportowania"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.mdr.deadline_tracking — Śledzenie terminów MDR i kary za brak zgłoszenia
else :=   {"matched":true,"rule_id":"jdg.mdr.deadline_tracking","package":"jdg.mdr","priority":1802,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Śledzenie terminów MDR i kary za brak zgłoszenia","_legal_basis":"Art. 86o Ordynacji podatkowej","_warnings":["MDR-3 niezłożony w terminie 30 dni! Kara administracyjna do 5M PLN + KKS!"]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}
