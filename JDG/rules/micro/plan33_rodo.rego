# Generated from Plan OPA 33 — Micro-rules for rodo
# 2026-07-13 14:58:41
# Rules: 10 (new, deduplicated)

package jdg.micro.rodo.plan33

default decide := {"matched":false,"rule_id":"jdg.micro.rodo.plan33_no_match","package":"jdg.micro.rodo.plan33","priority":99999}

# jdg.micro.rodo.r1 — `rodo_applicable_to_jdg`: JDG przetwarza dane osobowe klientow/pracownikow -> RODO ma zastosowanie
decide :=   {"matched":true,"rule_id":"jdg.micro.rodo.r1","package":"jdg.micro.rodo.plan33","priority":6900,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG przetwarza dane osobowe klientow/pracownikow -> RODO ma zastosowanie","_legal_basis":"RODO — Rozporządzenie UE 2016/679","_warnings":["[MICRO] JDG przetwarza dane osobowe klientow/pracownikow -> RODO ma zastosowanie"]} {
    object.get(input.rodo, "personal_data_processed", false) == true
}

# jdg.micro.rodo.r2 — `rodo_data_controller_obligations`: JDG jako administrator danych: obowiazki
else :=   {"matched":true,"rule_id":"jdg.micro.rodo.r2","package":"jdg.micro.rodo.plan33","priority":6902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"JDG jako administrator danych: obowiazek rejestracji czynnosci przetwarzania","_legal_basis":"RODO — Rozporządzenie UE 2016/679","_warnings":["[MICRO] JDG jako administrator danych: obowiazek rejestracji czynnosci przetwarzania (RCP)"]} {
    object.get(input.rodo, "is_data_controller", false) == true
    object.get(input.rodo, "employees", 0) >= 250
}

# jdg.micro.rodo.r3 — `rodo_data_processing_register_sensitive`: RCP obowiazkowy przy danych wrazliwych
else :=   {"matched":true,"rule_id":"jdg.micro.rodo.r3","package":"jdg.micro.rodo.plan33","priority":6903,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"RCP obowiazkowy — dane wrazliwe przetwarzane","_legal_basis":"RODO — Rozporządzenie UE 2016/679","_warnings":["[MICRO] Dane wrazliwe — RCP obowiazkowy niezaleznie od liczby pracownikow"]} {
    object.get(input.rodo, "sensitive_data_processed", false) == true
}

# jdg.micro.rodo.r4 — `rodo_rcp_exception_small_jdg`: Wyjatek: JDG < 250 pracownikow i brak danych wrazliwych -> brak RCP
else :=   {"matched":true,"rule_id":"jdg.micro.rodo.r4","package":"jdg.micro.rodo.plan33","priority":6904,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wyjatek: JDG < 250 pracownikow, brak danych wrazliwych -> RCP nieobowiazkowy","_legal_basis":"RODO — Rozporządzenie UE 2016/679","_warnings":["[MICRO] Wyjatek RCP — JDG < 250 pracownikow i brak danych wrazliwych"]} {
    object.get(input.rodo, "employees", 0) < 250
    object.get(input.rodo, "sensitive_data_processed", false) == false
}

# jdg.micro.rodo.r5 — `rodo_data_breach_notification_72h`: Naruszenie danych: zgloszenie do PUODO w 72h
else :=   {"matched":true,"rule_id":"jdg.micro.rodo.r5","package":"jdg.micro.rodo.plan33","priority":6905,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Naruszenie danych: zgloszenie do PUODO w 72h","_legal_basis":"RODO — Rozporządzenie UE 2016/679","_warnings":["[MICRO] Naruszenie danych: zgloszenie do PUODO w 72h od wykrycia!"]} {
    object.get(input.rodo, "data_breach_detected", false) == true
}

# jdg.micro.rodo.r6 — `rodo_data_breach_high_risk`: Naruszenie wysokiego ryzyka: zawiadomienie osob
else :=   {"matched":true,"rule_id":"jdg.micro.rodo.r6","package":"jdg.micro.rodo.plan33","priority":6906,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Naruszenie wysokiego ryzyka: zawiadomienie osob + PUODO","_legal_basis":"RODO — Rozporządzenie UE 2016/679","_warnings":["[MICRO] Naruszenie wysokiego ryzyka — zawiadom osoby, ktorych dane dotycza"]} {
    object.get(input.rodo, "data_breach_high_risk", false) == true
}

# jdg.micro.rodo.r7 — `rodo_dpo_required`: DPO/ABI wymagany (szczegolne okolicznosci)
else :=   {"matched":true,"rule_id":"jdg.micro.rodo.r7","package":"jdg.micro.rodo.plan33","priority":6907,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"DPO wymagany — monitoring na duza skale lub dane wrazliwe","_legal_basis":"RODO — Rozporządzenie UE 2016/679","_warnings":["[MICRO] DPO/ABI WYMAGANY — duza skala przetwarzania lub szczegolne kategorie danych"]} {
    object.get(input.rodo, "large_scale_monitoring", false) == true
}

# jdg.micro.rodo.r8 — `rodo_invoice_data_retention`: Dane na fakturach — retencja 5 lat
else :=   {"matched":true,"rule_id":"jdg.micro.rodo.r8","package":"jdg.micro.rodo.plan33","priority":6908,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dane na fakturach przechowywane 5 lat","_legal_basis":"RODO — Rozporządzenie UE 2016/679","_warnings":["[MICRO] Dane na fakturach — retencja 5 lat (podstawa: obowiazek podatkowy)"]} {
    object.get(input.rodo, "invoice_data_stored", false) == true
}

# jdg.micro.rodo.r9 — `rodo_marketing_consent`: Marketing bezposredni — wymagana zgoda
else :=   {"matched":true,"rule_id":"jdg.micro.rodo.r9","package":"jdg.micro.rodo.plan33","priority":6909,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Marketing — sprawdz zgode marketingowa","_legal_basis":"RODO — Rozporządzenie UE 2016/679","_warnings":["[MICRO] Marketing bezposredni — wymagana zgoda (chyba ze istnieje relacja klienta)"]} {
    object.get(input.rodo, "marketing_active", false) == true
    object.get(input.rodo, "marketing_consent_obtained", false) == false
}

# jdg.micro.rodo.r10 — `rodo_security_measures`: Srodki bezpieczenstwa — zawsze wymagane przy przetwarzaniu
else :=   {"matched":true,"rule_id":"jdg.micro.rodo.r10","package":"jdg.micro.rodo.plan33","priority":6901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Srodki bezpieczenstwa — zawsze wymagane","_legal_basis":"RODO — Rozporządzenie UE 2016/679","_warnings":["[MICRO] Srodki bezpieczenstwa: szyfrowanie, hasla, kontrola dostepu — wymagane przy przetwarzaniu danych"]} {
    object.get(input.rodo, "personal_data_processed", false) == true
}
