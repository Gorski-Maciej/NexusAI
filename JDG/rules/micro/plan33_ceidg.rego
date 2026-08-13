# Generated from Plan OPA 33 — Micro-rules for ceidg
# 2026-07-13 14:58:41
# Rules: 15 (new, deduplicated)

package jdg.micro.ceidg

default decide := {"matched":false,"rule_id":"jdg.micro.ceidg.plan33.no_match","package":"jdg.micro.ceidg","priority":99999}

# jdg.ceidg.r1 — `ceidg_registration_obligation`: Kazda JDG musi byc zarejestrowana w CEIDG → Obowiazek
decide :=   {"matched":true,"rule_id":"jdg.ceidg.r1","package":"jdg.micro.ceidg","priority":5200,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kazda JDG musi byc zarejestrowana w CEIDG","_legal_basis":"Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)","_warnings":["[MICRO] Kazda JDG musi byc zarejestrowana w CEIDG"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.ceidg.r10 — `ceidg_registration_closure_notification`: Zamkniecie dzialalnosci: wniosek o wykreślenie z CEIDG → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.ceidg.r10","package":"jdg.micro.ceidg","priority":5201,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zamkniecie dzialalnosci: wniosek o wykreślenie z CEIDG","_legal_basis":"Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)","_warnings":["[MICRO] Zamkniecie dzialalnosci: wniosek o wykreślenie z CEIDG"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.ceidg.r11 — `ceidg_registration_death_notification`: Smierc przedsiebiorcy -> CEIDG wykreśla z urzedu (na wniosek spadkobiercy) → Urzedowo
else :=   {"matched":true,"rule_id":"jdg.ceidg.r11","package":"jdg.micro.ceidg","priority":5202,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Smierc przedsiebiorcy -> CEIDG wykreśla z urzedu (na wniosek spadkobiercy)","_legal_basis":"Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)","_warnings":["[MICRO] Smierc przedsiebiorcy -> CEIDG wykreśla z urzedu (na wniosek spadkobiercy)"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.ceidg.r12 — `ceidg_registration_pkd_main_and_secondary`: Głowne PKD (jedno) + pomocnicze PKD (wiele) -> decyduje o stawce ryczaltu → PKD
else :=   {"matched":true,"rule_id":"jdg.ceidg.r12","package":"jdg.micro.ceidg","priority":5203,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Głowne PKD (jedno) + pomocnicze PKD (wiele) -> decyduje o stawce ryczaltu","_legal_basis":"Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)","_warnings":["[MICRO] Głowne PKD (jedno) + pomocnicze PKD (wiele) -> decyduje o stawce ryczaltu"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.ceidg.r13 — `ceidg_registration_bank_account_required`: Obowiazek wskazania rachunku bankowego dla dzialalnosci → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.ceidg.r13","package":"jdg.micro.ceidg","priority":5204,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiazek wskazania rachunku bankowego dla dzialalnosci","_legal_basis":"Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)","_warnings":["[MICRO] Obowiazek wskazania rachunku bankowego dla dzialalnosci"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.ceidg.r14 — `ceidg_registration_public_data`: Wiece danych w CEIDG jest publiczna (NIP, adres, PKD) → Publicznosc
else :=   {"matched":true,"rule_id":"jdg.ceidg.r14","package":"jdg.micro.ceidg","priority":5205,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wiece danych w CEIDG jest publiczna (NIP, adres, PKD)","_legal_basis":"Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)","_warnings":["[MICRO] Wiece danych w CEIDG jest publiczna (NIP, adres, PKD)"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.ceidg.r15 — `ceidg_registration_protected_data_home`: Mozliwosc ukrycia adresu zamieszkania (na wniosek) → Prywatnosc
else :=   {"matched":true,"rule_id":"jdg.ceidg.r15","package":"jdg.micro.ceidg","priority":5206,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mozliwosc ukrycia adresu zamieszkania (na wniosek)","_legal_basis":"Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)","_warnings":["[MICRO] Mozliwosc ukrycia adresu zamieszkania (na wniosek)"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.ceidg.r2 — `ceidg_registration_form_electronic`: Rejestracja online przez CEIDG (formularz elektroniczny) → Forma
else :=   {"matched":true,"rule_id":"jdg.ceidg.r2","package":"jdg.micro.ceidg","priority":5207,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rejestracja online przez CEIDG (formularz elektroniczny)","_legal_basis":"Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)","_warnings":["[MICRO] Rejestracja online przez CEIDG (formularz elektroniczny)"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.ceidg.r3 — `ceidg_registration_data_required`: Wymagane dane: imie, nazwisko, NIP, PESEL, adres, PKD, forma opodatkowania → Dane
else :=   {"matched":true,"rule_id":"jdg.ceidg.r3","package":"jdg.micro.ceidg","priority":5208,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wymagane dane: imie, nazwisko, NIP, PESEL, adres, PKD, forma opodatkowania","_legal_basis":"Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)","_warnings":["[MICRO] Wymagane dane: imie, nazwisko, NIP, PESEL, adres, PKD, forma opodatkowania"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.ceidg.r4 — `ceidg_registration_automatic_nip_regon`: Rejestracja CEIDG -> automatycznie NIP i REGON → Automatyzm
else :=   {"matched":true,"rule_id":"jdg.ceidg.r4","package":"jdg.micro.ceidg","priority":5209,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rejestracja CEIDG -> automatycznie NIP i REGON","_legal_basis":"Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)","_warnings":["[MICRO] Rejestracja CEIDG -> automatycznie NIP i REGON"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.ceidg.r5 — `ceidg_registration_automatic_zus`: Rejestracja CEIDG -> automatyczne zgloszenie do ZUS → Automatyzm
else :=   {"matched":true,"rule_id":"jdg.ceidg.r5","package":"jdg.micro.ceidg","priority":5210,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rejestracja CEIDG -> automatyczne zgloszenie do ZUS","_legal_basis":"Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)","_warnings":["[MICRO] Rejestracja CEIDG -> automatyczne zgloszenie do ZUS"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.ceidg.r6 — `ceidg_registration_automatic_us`: Rejestracja CEIDG -> automatyczne zgloszenie do US → Automatyzm
else :=   {"matched":true,"rule_id":"jdg.ceidg.r6","package":"jdg.micro.ceidg","priority":5211,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rejestracja CEIDG -> automatyczne zgloszenie do US","_legal_basis":"Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)","_warnings":["[MICRO] Rejestracja CEIDG -> automatyczne zgloszenie do US"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.ceidg.r7 — `ceidg_registration_change_7_days`: Zmiana danych w CEIDG: w 7 dni od zdarzenia → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.ceidg.r7","package":"jdg.micro.ceidg","priority":5212,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana danych w CEIDG: w 7 dni od zdarzenia","_legal_basis":"Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)","_warnings":["[MICRO] Zmiana danych w CEIDG: w 7 dni od zdarzenia"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.ceidg.r8 — `ceidg_registration_suspension_notification`: Zawieszenie dzialalnosci: zgoda do CEIDG → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.ceidg.r8","package":"jdg.micro.ceidg","priority":5213,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zawieszenie dzialalnosci: zgoda do CEIDG","_legal_basis":"Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)","_warnings":["[MICRO] Zawieszenie dzialalnosci: zgoda do CEIDG"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.ceidg.r9 — `ceidg_registration_resumption_notification`: Wznowienie po zawieszeniu: przez CEIDG → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.ceidg.r9","package":"jdg.micro.ceidg","priority":5214,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wznowienie po zawieszeniu: przez CEIDG","_legal_basis":"Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)","_warnings":["[MICRO] Wznowienie po zawieszeniu: przez CEIDG"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}
