# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 21

package jdg.hyper.fx

default decide := {"matched":false,"rule_id":"jdg.hyper.fx.no_match","package":"jdg.hyper.fx","priority":99999}

# jdg.hyper.fx.edelivery.fiction.appeal_deadline_trigger — Fikcja
decide :=   {"matched":true,"rule_id":"jdg.hyper.fx.edelivery.fiction.appeal_deadline_trigger","package":"jdg.hyper.fx","priority":1240,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Data fikcji = data rozpoczęcia biegu 14 dni na odwołanie","_legal_basis":"Art. 144b OP","_warnings":["Data fikcji = data rozpoczęcia biegu 14 dni na odwołanie"]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.edelivery.monitoring.unread_messages — Monitoring
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.edelivery.monitoring.unread_messages","package":"jdg.hyper.fx","priority":1241,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Codzienne sprawdzanie nieodebranych pism","_legal_basis":"Art. 144b OP","_warnings":["Codzienne sprawdzanie nieodebranych pism"]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.edelivery.monitoring.alert_7_days — Monitoring
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.edelivery.monitoring.alert_7_days","package":"jdg.hyper.fx","priority":1242,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Alert 7 dni przed fikcją doręczenia","_legal_basis":"Art. 144b OP","_warnings":["Alert 7 dni przed fikcją doręczenia"]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.edelivery.monitoring.alert_3_days — Monitoring
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.edelivery.monitoring.alert_3_days","package":"jdg.hyper.fx","priority":1243,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Alert 3 dni przed fikcją doręczenia","_legal_basis":"R1244","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.edelivery.monitoring.alert_1_day — Monitoring
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.edelivery.monitoring.alert_1_day","package":"jdg.hyper.fx","priority":1244,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Alert 1 dzień przed fikcją doręczenia","_legal_basis":"Art. 144b OP","_warnings":["Alert 1 dzień przed fikcją doręczenia"]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.eus.platform.required — e-US
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.eus.platform.required","package":"jdg.hyper.fx","priority":1245,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Obowiązek posiadania konta e-US","_legal_basis":"R1246","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.eus.platform.incoming_letters_check — e-US
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.eus.platform.incoming_letters_check","package":"jdg.hyper.fx","priority":1246,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Monitorowanie nowych pism na e-US","_legal_basis": "Przepisy prawa podatkowego (LEGAL_REFERENCE_ACTS.md)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.eus.platform.declarations_status — e-US
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.eus.platform.declarations_status","package":"jdg.hyper.fx","priority":1247,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Status złożonych deklaracji (UPO)","_legal_basis":"R1248","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.eus.platform.payment_history — e-US
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.eus.platform.payment_history","package":"jdg.hyper.fx","priority":1248,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Historia wpłat i zaległości","_legal_basis": "Przepisy prawa podatkowego (LEGAL_REFERENCE_ACTS.md)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.eus.platform.mandates_management — e-US
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.eus.platform.mandates_management","package":"jdg.hyper.fx","priority":1249,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zarządzanie pełnomocnictwami (PPS-1, UPL-1)","_legal_basis":"R1250","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.eus.platform.certificates — e-US
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.eus.platform.certificates","package":"jdg.hyper.fx","priority":1250,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zaświadczenia o niezaleganiu","_legal_basis": "Przepisy prawa podatkowego (LEGAL_REFERENCE_ACTS.md)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.epuap.profile.required — ePUAP
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.epuap.profile.required","package":"jdg.hyper.fx","priority":1251,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Obowiązek profilu zaufanego ePUAP","_legal_basis":"R1252","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.epuap.signature.profile_zaufany — ePUAP
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.epuap.signature.profile_zaufany","package":"jdg.hyper.fx","priority":1252,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Profil zaufany jako podstawowa forma podpisu","_legal_basis": "Przepisy prawa podatkowego (LEGAL_REFERENCE_ACTS.md)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.epuap.submission.confirmation_upo — ePUAP
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.epuap.submission.confirmation_upo","package":"jdg.hyper.fx","priority":1253,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"UPO (Urzędowe Poświadczenie Odbioru) dla każdego pisma","_legal_basis":"R1254","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.epuap.submission.timestamp — ePUAP
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.epuap.submission.timestamp","package":"jdg.hyper.fx","priority":1254,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Znacznik czasowy = data skutecznego złożenia","_legal_basis": "Przepisy prawa podatkowego (LEGAL_REFERENCE_ACTS.md)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.electronic.delivery.address.update_obligation — Aktualizacja
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.electronic.delivery.address.update_obligation","package":"jdg.hyper.fx","priority":1255,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Obowiązek aktualizacji adresu e-Doręczeń","_legal_basis":"R1256","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.electronic.delivery.sanction.outdated_address — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.electronic.delivery.sanction.outdated_address","package":"jdg.hyper.fx","priority":1256,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Nieaktualny adres → fikcja doręczenia na stary adres","_legal_basis": "Przepisy prawa podatkowego (LEGAL_REFERENCE_ACTS.md)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.electronic.communication.retention.5_years — Retencja
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.electronic.communication.retention.5_years","package":"jdg.hyper.fx","priority":1257,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Przechowywanie korespondencji 5 lat","_legal_basis":"R1258","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.electronic.communication.evidence_value — Dowody
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.electronic.communication.evidence_value","package":"jdg.hyper.fx","priority":1258,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Moc dowodowa dokumentów elektronicznych","_legal_basis": "Przepisy prawa podatkowego (LEGAL_REFERENCE_ACTS.md)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.electronic.communication.encryption_requirements — Bezpieczeństwo
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.electronic.communication.encryption_requirements","package":"jdg.hyper.fx","priority":1259,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Wymogi szyfrowania komunikacji z US","_legal_basis":"R1260","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.electronic.communication.data_breach_notification — Bezpieczeństwo
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.electronic.communication.data_breach_notification","package":"jdg.hyper.fx","priority":1260,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Obowiązek zgłoszenia naruszenia danych","_legal_basis": "Przepisy prawa podatkowego (LEGAL_REFERENCE_ACTS.md)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# ══ L-FX-1 Fix: Currency Exchange Differences (P23 P1) — R1261-R1263 ══
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.currency.exchange.fifo_method","package":"jdg.hyper.fx","priority":1261,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Różnice kursowe: metoda FIFO (Art. 14b PIT)","_legal_basis":"Art. 14b ust. 3 PIT","_warnings":["Różnice kursowe — metoda podatkowa FIFO (pierwsze przyszło-pierwsze wyszło). Kurs NBP z ostatniego dnia roboczego poprzedzającego transakcję"]} {
    input.invoice.currency != "PLN"
}
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.currency.exchange.nbp_table_abc","package":"jdg.hyper.fx","priority":1262,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kurs NBP: tabela A (średni), B (kupna/sprzedaży)","_legal_basis":"Art. 14b ust. 4 PIT","_warnings":["Kursy NBP: Tabela A (kurs średni — przychody), Tabela B (kurs kupna/sprzedaży — koszty). Aktualizacja dzienna o 08:00. API: api.nbp.pl"]} {
    object.get(input.jdg_entrepreneur, "fx_transactions_active", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.currency.exchange.jpk_v7_fx_mapping","package":"jdg.hyper.fx","priority":1263,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"FX: mapowanie do JPK_V7","_legal_basis":"Art. 109 ust. 3c VAT","_warnings":["Mapowanie różnic kursowych w JPK_V7: przychody wg kursu średniego NBP, koszty wg kursu kupna. Oznaczenie GTU_12 dla transakcji walutowych"]} {
    input.invoice.currency != "PLN"
    object.get(input.jdg_entrepreneur, "jpk_v7_due", false) == true
}
