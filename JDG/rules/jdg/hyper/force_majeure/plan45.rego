# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 21

package jdg.hyper.force_majeure

default decide := {"matched":false,"rule_id":"jdg.hyper.force_majeure.no_match","package":"jdg.hyper.force_majeure","priority":99999}

# jdg.hyper.force_majeure.audit.right.record_activities — Prawo JDG
decide :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.record_activities","package":"jdg.hyper.force_majeure","priority":1120,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Nagrywanie czynności za zgodą kontrolującego (Art. 286 § 3 OP)","_legal_basis":"Nagrywanie czynności za zgodą kontrolującego (Art. 286 § 3 OP)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.right.break_request — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.break_request","package":"jdg.hyper.force_majeure","priority":1121,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Przerwa w kontroli — max 3 dni robocze","_legal_basis":"Art. 286 OP","_warnings":["Przerwa w kontroli — max 3 dni robocze"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.right.oppose_inspection — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.oppose_inspection","package":"jdg.hyper.force_majeure","priority":1122,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Sprzeciw wobec kontroli naruszającej przepisy (Art. 84c PP)","_legal_basis":"Sprzeciw wobec kontroli naruszającej przepisy (Art. 84c PP)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.right.correction_in_minus_blocked — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.correction_in_minus_blocked","package":"jdg.hyper.force_majeure","priority":1123,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Korekta na korzyść blokowana podczas kontroli (Art. 81b OP)","_legal_basis":"Art. 81b OP","_warnings":["Korekta na korzyść blokowana podczas kontroli"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.right.correction_in_plus_allowed — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.correction_in_plus_allowed","package":"jdg.hyper.force_majeure","priority":1124,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Korekta na niekorzyść zawsze dozwolona","_legal_basis":"Art. 81b OP","_warnings":["Korekta na korzyść blokowana podczas kontroli"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.right.right_to_be_heard — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.right_to_be_heard","package":"jdg.hyper.force_majeure","priority":1125,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Prawo do wypowiedzenia przed decyzją (Art. 200 OP)","_legal_basis":"Art. 200 OP","_warnings":["Prawo do wypowiedzenia przed decyzją"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.right.appeal_14_days — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.appeal_14_days","package":"jdg.hyper.force_majeure","priority":1126,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Odwołanie od decyzji w 14 dni (Art. 223 OP)","_legal_basis":"Odwołanie od decyzji w 14 dni (Art. 223 OP)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.right.wsa_complaint_30_days — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.right.wsa_complaint_30_days","package":"jdg.hyper.force_majeure","priority":1127,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Skarga do WSA w 30 dni od decyzji II instancji","_legal_basis":"","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.obligation.provide_documents — Obowiązek JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.obligation.provide_documents","package":"jdg.hyper.force_majeure","priority":1128,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Udostępnienie żądanych dokumentów","_legal_basis":"R1129","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.obligation.allow_inspection — Obowiązek JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.obligation.allow_inspection","package":"jdg.hyper.force_majeure","priority":1129,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Umożliwienie oględzin lokalu","_legal_basis":"","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.obligation.provide_explanations — Obowiązek JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.obligation.provide_explanations","package":"jdg.hyper.force_majeure","priority":1130,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Składanie wyjaśnień ustnych i pisemnych","_legal_basis":"R1131","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.obligation.sign_protocol — Obowiązek JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.obligation.sign_protocol","package":"jdg.hyper.force_majeure","priority":1131,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Podpisanie protokołu (odmowa wymaga uzasadnienia)","_legal_basis":"","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.obligation.retain_audit_docs — Obowiązek JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.obligation.retain_audit_docs","package":"jdg.hyper.force_majeure","priority":1132,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Przechowywanie dokumentacji kontrolnej","_legal_basis":"R1133","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.statute.suspension_effect — Przedawnienie
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.statute.suspension_effect","package":"jdg.hyper.force_majeure","priority":1133,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Wszczęcie kontroli → zawieszenie biegu przedawnienia (Art. 70 § 6 OP)","_legal_basis":"Wszczęcie kontroli → zawieszenie biegu przedawnienia (Art. 70 § 6 OP)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.statute.suspension_duration — Przedawnienie
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.statute.suspension_duration","package":"jdg.hyper.force_majeure","priority":1134,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zawieszenie trwa przez cały okres kontroli","_legal_basis":"R1135","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.statute.resume_after_close — Przedawnienie
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.statute.resume_after_close","package":"jdg.hyper.force_majeure","priority":1135,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Bieg przedawnienia wznawia się po zakończeniu kontroli","_legal_basis":"","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.penalty.obstruction_fine_5000 — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.penalty.obstruction_fine_5000","package":"jdg.hyper.force_majeure","priority":1136,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Utrudnianie kontroli → grzywna do 5 000 PLN (Art. 262 OP)","_legal_basis":"Utrudnianie kontroli → grzywna do 5 000 PLN (Art. 262 OP)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.penalty.obstruction_kks_art69 — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.penalty.obstruction_kks_art69","package":"jdg.hyper.force_majeure","priority":1137,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Utrudnianie → odpowiedzialność KKS (Art. 69 KKS)","_legal_basis":"Utrudnianie → odpowiedzialność KKS (Art. 69 KKS)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.penalty.coercion_measures — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.penalty.coercion_measures","package":"jdg.hyper.force_majeure","priority":1138,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Środki przymusu: grzywna, przymuszenie bezpośrednie (Art. 151 OP)","_legal_basis":"Środki przymusu: grzywna, przymuszenie bezpośrednie (Art. 151 OP)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.document.seizure_receipt — Dokumenty
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.document.seizure_receipt","package":"jdg.hyper.force_majeure","priority":1139,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zatrzymanie dokumentów tylko za pokwitowaniem (Art. 288 OP)","_legal_basis":"Zatrzymanie dokumentów tylko za pokwitowaniem (Art. 288 OP)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.force_majeure.audit.document.seizure_duration — Dokumenty
else :=   {"matched":true,"rule_id":"jdg.hyper.force_majeure.audit.document.seizure_duration","package":"jdg.hyper.force_majeure","priority":1140,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Max na czas kontroli; po zakończeniu → zwrot","_legal_basis":"R1141","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
