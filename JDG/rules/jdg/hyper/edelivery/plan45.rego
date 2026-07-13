# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 21

package jdg.hyper.edelivery

default decide := {"matched":false,"rule_id":"jdg.hyper.edelivery.no_match","package":"jdg.hyper.edelivery","priority":99999}

# jdg.hyper.edelivery.force_majeure.documents.backup_obligation — Dokumenty
decide :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.documents.backup_obligation","package":"jdg.hyper.edelivery","priority":1180,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiązek posiadania backupu cyfrowego dokumentacji","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.documents.electronic_preservation — Dokumenty
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.documents.electronic_preservation","package":"jdg.hyper.edelivery","priority":1181,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przechowywanie kopii off-site / w chmurze","_legal_basis":"R1182","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.insurance.cover_check — Ubezpieczenie
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.insurance.cover_check","package":"jdg.hyper.edelivery","priority":1182,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprawdzenie zakresu ubezpieczenia business interruption","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.insurance.claim_procedure — Ubezpieczenie
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.insurance.claim_procedure","package":"jdg.hyper.edelivery","priority":1183,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Procedura zgłoszenia szkody do ubezpieczyciela","_legal_basis":"R1184","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.insurance.payout_tax_treatment — Ubezpieczenie
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.insurance.payout_tax_treatment","package":"jdg.hyper.edelivery","priority":1184,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odszkodowanie jako przychód podatkowy","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.suspension.automatic — Zawieszenie
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.suspension.automatic","package":"jdg.hyper.edelivery","priority":1185,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Automatyczne zawieszenie JDG z powodu siły wyższej","_legal_basis":"R1186","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.suspension.zus_consequences — Zawieszenie
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.suspension.zus_consequences","package":"jdg.hyper.edelivery","priority":1186,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skutki ZUS-owe zawieszenia z powodu siły wyższej","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.suspension.tax_consequences — Zawieszenie
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.suspension.tax_consequences","package":"jdg.hyper.edelivery","priority":1187,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skutki podatkowe zawieszenia z powodu siły wyższej","_legal_basis":"R1188","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.loss.carry_back — Strata
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.loss.carry_back","package":"jdg.hyper.edelivery","priority":1188,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Możliwość retrospektywnego rozliczenia straty (specustawy)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.loss.enhanced_deduction — Strata
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.loss.enhanced_deduction","package":"jdg.hyper.edelivery","priority":1189,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwiększony limit odliczenia straty (np. 100% zamiast 50%)","_legal_basis":"R1190","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.deadlines.mf_communication_monitoring — Terminy
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.deadlines.mf_communication_monitoring","package":"jdg.hyper.edelivery","priority":1190,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Monitorowanie komunikatów MF o przedłużeniu terminów","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.deadlines.auto_extension_application — Terminy
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.deadlines.auto_extension_application","package":"jdg.hyper.edelivery","priority":1191,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Automatyczne stosowanie przedłużonych terminów","_legal_basis":"R1192","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.aggregate.impact_assessment — Agregacja
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.aggregate.impact_assessment","package":"jdg.hyper.edelivery","priority":1192,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ocena łącznego wpływu siły wyższej na finanse JDG","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.employment.kup_conditions — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.employment.kup_conditions","package":"jdg.hyper.edelivery","priority":1193,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wynagrodzenie małżonka: praca rzeczywista, rynkowa, udokumentowana","_legal_basis":"R1194","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.market_benchmark_test — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.market_benchmark_test","package":"jdg.hyper.edelivery","priority":1194,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Test porównawczy: czy pensja mieści się w ±30% mediany rynkowej","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.qualifications_check — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.qualifications_check","package":"jdg.hyper.edelivery","priority":1195,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprawdzenie kwalifikacji adekwatnych do stanowiska","_legal_basis":"R1196","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.work_evidence_required — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.work_evidence_required","package":"jdg.hyper.edelivery","priority":1196,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ewidencja czasu pracy, zadań, efektów — obowiązkowa","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.salary_above_market_red_flag — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.salary_above_market_red_flag","package":"jdg.hyper.edelivery","priority":1197,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wynagrodzenie > 130% mediany rynkowej → HIGH risk flag","_legal_basis":"R1198","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.no_qualifications_red_flag — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.no_qualifications_red_flag","package":"jdg.hyper.edelivery","priority":1198,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak kwalifikacji + wysokie wynagrodzenie → HIGH risk flag","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.no_work_evidence_nkup — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.no_work_evidence_nkup","package":"jdg.hyper.edelivery","priority":1199,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak dowodów pracy → NKUP (Art. 23 ust. 1 pkt 10 PIT)","_legal_basis":"R1200","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.contract_type.employment — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.contract_type.employment","package":"jdg.hyper.edelivery","priority":1200,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa o pracę z małżonkiem → pełny ZUS, PIT-4R","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}
