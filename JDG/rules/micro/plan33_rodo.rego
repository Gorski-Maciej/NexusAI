# Generated from Plan OPA 33 — Micro-rules for rodo
# 2026-07-13 14:58:41
# Rules: 10 (new, deduplicated)

package jdg.micro.rodo

default decide := {"matched":false,"rule_id":"jdg.micro.rodo.no_match","package":"jdg.micro.rodo","priority":99999}

# jdg.rodo.r1 — `rodo_applicable_to_jdg`: JDG przetwarza dane osobowe klientow/pracownikow -> RODO ma zastosowanie → Zastosowanie
decide :=   {"matched":true,"rule_id":"jdg.rodo.r1","package":"jdg.micro.rodo","priority":6900,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG przetwarza dane osobowe klientow/pracownikow -> RODO ma zastosowanie","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.rodo.r10 — `rodo_data_storage_security_measures`: Srodki bezpieczenstwa: szyfrowanie, hasla, kontrola dostepu → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.rodo.r10","package":"jdg.micro.rodo","priority":6901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Srodki bezpieczenstwa: szyfrowanie, hasla, kontrola dostepu","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.rodo.r2 — `rodo_data_controller_obligations`: JDG jako administrator danych: obowiazek rejestracji czynnosci przetwarzania → Obowiazki
else :=   {"matched":true,"rule_id":"jdg.rodo.r2","package":"jdg.micro.rodo","priority":6902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG jako administrator danych: obowiazek rejestracji czynnosci przetwarzania","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.rodo.r3 — `rodo_data_processing_register`: Rejestr czynnosci przetwarzania (RCP) - obowiazkowy dla JDG (chyba ze < 250 pracownikow) → Rejestr
else :=   {"matched":true,"rule_id":"jdg.rodo.r3","package":"jdg.micro.rodo","priority":6903,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rejestr czynnosci przetwarzania (RCP) - obowiazkowy dla JDG (chyba ze < 250 pracownikow)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.rodo.r4 — `rodo_data_processing_register_exception`: Wyjatek: JDG < 250 pracownikow nie musi prowadzic RCP (chyba ze dane wrażliwe) → Wyjatek
else :=   {"matched":true,"rule_id":"jdg.rodo.r4","package":"jdg.micro.rodo","priority":6904,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wyjatek: JDG < 250 pracownikow nie musi prowadzic RCP (chyba ze dane wrażliwe)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.rodo.r5 — `rodo_data_breach_notification_72h`: Naruszenie danych: zgloszenie do PUODO w 72h → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.rodo.r5","package":"jdg.micro.rodo","priority":6905,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Naruszenie danych: zgloszenie do PUODO w 72h","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.rodo.r6 — `rodo_data_breach_notification_subject`: Naruszenie wysokiego ryzyka: zawiadomienie osoby, ktorej dane dotycza → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.rodo.r6","package":"jdg.micro.rodo","priority":6906,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Naruszenie wysokiego ryzyka: zawiadomienie osoby, ktorej dane dotycza","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.rodo.r7 — `rodo_dpo_not_required_for_jdg`: ABI/DPO nie jest wymagane dla JDG (chyba ze szczegolne okolicznosci) → Brak obowiazku
else :=   {"matched":true,"rule_id":"jdg.rodo.r7","package":"jdg.micro.rodo","priority":6907,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"ABI/DPO nie jest wymagane dla JDG (chyba ze szczegolne okolicznosci)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.rodo.r8 — `rodo_invoice_data_retention_5_years`: Dane na fakturach przechowywane 5 lat (podstawa prawna: obowiazek podatkowy) → Retencja
else :=   {"matched":true,"rule_id":"jdg.rodo.r8","package":"jdg.micro.rodo","priority":6908,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dane na fakturach przechowywane 5 lat (podstawa prawna: obowiazek podatkowy)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.rodo.r9 — `rodo_marketing_consent_required`: Marketing bezposredni: zgoda klienta (chyba ze istnieje relacja klienta) → Zgoda
else :=   {"matched":true,"rule_id":"jdg.rodo.r9","package":"jdg.micro.rodo","priority":6909,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Marketing bezposredni: zgoda klienta (chyba ze istnieje relacja klienta)","_legal_basis":"","_warnings":[]} {
    true
}
