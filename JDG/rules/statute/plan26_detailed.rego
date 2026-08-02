# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.statute
# Generated from Plan OPA specifications: 2026-07-13 14:05:06
# Rules: 9
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.statute
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.statute.no_match","package":"jdg.statute","priority":99999}

# jdg.statute.zus_suspension_during_proceedings — Zawieszenie przedawnienia ZUS — egzekucja/KKS
decide :=   {"matched":true,"rule_id":"jdg.statute.zus_suspension_during_proceedings","package":"jdg.statute","priority":1153,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zawieszenie przedawnienia ZUS — egzekucja/KKS","_legal_basis":"Art. 24 ust. 5b-5d SUS","_warnings":["Bieg przedawnienia ZUS zawieszony"]} {
    object.get(input.document, "statute_suspended", false) == true
}

# jdg.statute.interruption_detailed_events — Przerwanie przedawnienia — uznanie długu, KKS, upadłość
else :=   {"matched":true,"rule_id":"jdg.statute.interruption_detailed_events","package":"jdg.statute","priority":1157,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przerwanie przedawnienia — uznanie długu, KKS, upadłość","_legal_basis":"Art. 71 OP","_warnings":["Bieg przedawnienia przerwany — nowy 5-letni termin"]} {
    object.get(input.document, "statute_interrupted", false) == true
}

# jdg.statute.tax_arrears_detection — Wykrycie zaległości podatkowej — VAT/PIT/ZUS
else :=   {"matched":true,"rule_id":"jdg.statute.tax_arrears_detection","package":"jdg.statute","priority":1167,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Wykrycie zaległości podatkowej — VAT/PIT/ZUS","_legal_basis":"Art. 20-21 OP","_warnings":["Zaległość podatkowa — kwota X, dni Y"]} {
    object.get(input.document, "tax_arrears_detected", false) == true
}

# jdg.statute.voluntary_disclosure_protection — Czynny żal PRZED korektą — ochrona przed KKS
else :=   {"matched":true,"rule_id":"jdg.statute.voluntary_disclosure_protection","package":"jdg.statute","priority":1168,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Czynny żal PRZED korektą — ochrona przed KKS","_legal_basis":"Art. 16 § 1-4 KKS, Art. 16a KKS","_warnings":["Brak czynnego żalu przed korektą! Ryzyko KKS!"]} {
    object.get(input.document, "years_since_due_year", 0) > 0
}

# jdg.statute.overpayment_detection_and_refund — Nadpłata podatku — zwrot 45 dni (VAT) / 3 mies. (PIT)
else :=   {"matched":true,"rule_id":"jdg.statute.overpayment_detection_and_refund","package":"jdg.statute","priority":1169,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nadpłata podatku — zwrot 45 dni (VAT) / 3 mies. (PIT)","_legal_basis":"Art. 72-80 OP","_warnings":["Nadpłata — złóż wniosek o zwrot"]} {
    object.get(input.document, "overpayment_detected", false) == true
}

# jdg.statute.deferral_active_interest_suspended — Odroczenie/raty — odsetki zawieszone, opłata prolongacyjna
else :=   {"matched":true,"rule_id":"jdg.statute.deferral_active_interest_suspended","package":"jdg.statute","priority":1170,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odroczenie/raty — odsetki zawieszone, opłata prolongacyjna","_legal_basis":"Art. 48, Art. 67a-67e OP","_warnings":["Odroczenie aktywne — przestrzegaj terminów rat"]} {
    object.get(input.document, "deferral_active", false) == true
}

# jdg.statute.tax_remission_liability_extinguished — Umorzenie zaległości — zobowiązanie wygasa
else :=   {"matched":true,"rule_id":"jdg.statute.tax_remission_liability_extinguished","package":"jdg.statute","priority":1171,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umorzenie zaległości — zobowiązanie wygasa","_legal_basis":"Art. 51 OP","_warnings":["Zaległość umorzona — zobowiązanie wygasło"]} {
    object.get(input.document, "remission_granted", false) == true
}

# jdg.statute.overpayment_offset_auto — Zaliczenie nadpłaty na przyszłe zobowiązania
else :=   {"matched":true,"rule_id":"jdg.statute.overpayment_offset_auto","package":"jdg.statute","priority":1172,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaliczenie nadpłaty na przyszłe zobowiązania","_legal_basis":"Art. 72-80, Art. 87 OP","_warnings":[]} {
    object.get(input.document, "offset_requested", false) == true
}

# jdg.statute.tax_proceedings_deadlines_alert — Terminy proceduralne — 7/14/30/60 dni
else :=   {"matched":true,"rule_id":"jdg.statute.tax_proceedings_deadlines_alert","package":"jdg.statute","priority":1174,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Terminy proceduralne — 7/14/30/60 dni","_legal_basis":"Art. 120-129 OP","_warnings":["Termin procesowy — zostało X dni"]} {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}
