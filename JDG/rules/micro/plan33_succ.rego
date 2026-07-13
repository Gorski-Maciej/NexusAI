# Generated from Plan OPA 33 — Micro-rules for succ
# 2026-07-13 14:58:41
# Rules: 20 (new, deduplicated)

package jdg.micro.succ

default decide := {"matched":false,"rule_id":"jdg.micro.succ.no_match","package":"jdg.micro.succ","priority":99999}

# jdg.succ.r1 — `succession_definition_enterprise_inheritance`: Przedsiebiorstwo w spadku: ogol praw i obowiazkow zwiazanych z JDG → Definicja
decide :=   {"matched":true,"rule_id":"jdg.succ.r1","package":"jdg.micro.succ","priority":5400,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedsiebiorstwo w spadku: ogol praw i obowiazkow zwiazanych z JDG","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r10 — `succession_acceptance_direct`: Przyjecie spadku wprost -> pelna odpowiedzialnosc → Ryzyko
else :=   {"matched":true,"rule_id":"jdg.succ.r10","package":"jdg.micro.succ","priority":5401,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przyjecie spadku wprost -> pelna odpowiedzialnosc","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r11 — `succession_rejection_of_inheritance`: Odrzucenie spadku -> JDG wygasa, spadkobierca nie odpowiada → Odrzucenie
else :=   {"matched":true,"rule_id":"jdg.succ.r11","package":"jdg.micro.succ","priority":5402,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odrzucenie spadku -> JDG wygasa, spadkobierca nie odpowiada","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r12 — `succession_tax_settlement_by_manager`: Zarzadca sklada deklaracje podatkowe za okres po smierci do dnia zakonczenia zarzadu → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.succ.r12","package":"jdg.micro.succ","priority":5403,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zarzadca sklada deklaracje podatkowe za okres po smierci do dnia zakonczenia zarzadu","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r13 — `succession_vat_settlement_manager`: Zarzadca rozlicza VAT za okres po smierci (deklaracje i zaplate) → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.succ.r13","package":"jdg.micro.succ","priority":5404,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zarzadca rozlicza VAT za okres po smierci (deklaracje i zaplate)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r14 — `succession_zus_settlement_manager`: Zarzadca oplac skladki ZUS za okres zarzadu → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.succ.r14","package":"jdg.micro.succ","priority":5405,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zarzadca oplac skladki ZUS za okres zarzadu","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r15 — `succession_death_of_manager`: Smierc zarzadcy -> koniecznosc powolania nowego w 2 miesiace → Przerwanie
else :=   {"matched":true,"rule_id":"jdg.succ.r15","package":"jdg.micro.succ","priority":5406,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Smierc zarzadcy -> koniecznosc powolania nowego w 2 miesiace","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r16 — `succession_end_of_management_period`: Zarzad sukcesyjny trwa do 10 miesiecy od smierci → Max czas
else :=   {"matched":true,"rule_id":"jdg.succ.r16","package":"jdg.micro.succ","priority":5407,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zarzad sukcesyjny trwa do 10 miesiecy od smierci","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r17 — `succession_end_of_management_reasons` Zakonczenie: przyjecie spadku, uprawomocnienie sie postanowienia o stwierdzeniu nabycia spadku`: Zakonczenie
else :=   {"matched":true,"rule_id":"jdg.succ.r17","package":"jdg.micro.succ","priority":5408,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zakonczenie","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r18 — `succession_end_of_management_no_heir`: Brak spadkobiercy -> zakonczenie zarzadu, JDG wygasa → Wygasniecie
else :=   {"matched":true,"rule_id":"jdg.succ.r18","package":"jdg.micro.succ","priority":5409,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak spadkobiercy -> zakonczenie zarzadu, JDG wygasa","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r19 — `succession_inheritance_tax_3_months`: Podatek od spadku: w 3 miesiace od stwierdzenia nabycia (lub od dnia powstania obowiazku) → Termin
else :=   {"matched":true,"rule_id":"jdg.succ.r19","package":"jdg.micro.succ","priority":5410,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatek od spadku: w 3 miesiace od stwierdzenia nabycia (lub od dnia powstania obowiazku)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r2 — `succession_temporary_management_2_months`: Zarzad sukcesyjny: spadkobierca ustanawia go w 2 miesiace od smierci → Zarzad
else :=   {"matched":true,"rule_id":"jdg.succ.r2","package":"jdg.micro.succ","priority":5411,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zarzad sukcesyjny: spadkobierca ustanawia go w 2 miesiace od smierci","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r20 — `succession_inheritance_tax_exemption_family`: Zwolnienie z podatku od spadku: najblizsza rodzina (malzonek, dzieci, rodzice) → Zwolnienie
else :=   {"matched":true,"rule_id":"jdg.succ.r20","package":"jdg.micro.succ","priority":5412,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwolnienie z podatku od spadku: najblizsza rodzina (malzonek, dzieci, rodzice)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r3 — `succession_temporary_manager_appointment`: Zarzadca sukcesyjny: osoba fizyczna (spadkobierca lub inna) → Osoba
else :=   {"matched":true,"rule_id":"jdg.succ.r3","package":"jdg.micro.succ","priority":5413,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zarzadca sukcesyjny: osoba fizyczna (spadkobierca lub inna)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r4 — `succession_temporary_manager_deadline`: Wniosek o zarzad sukcesyjny: 2 miesiace od smierci → Termin
else :=   {"matched":true,"rule_id":"jdg.succ.r4","package":"jdg.micro.succ","priority":5414,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wniosek o zarzad sukcesyjny: 2 miesiace od smierci","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r5 — `succession_enterprise_continues_existence`: W okresie zarzadu: JDG istnieje nadal, NIP bez zmian → Kontynuacja
else :=   {"matched":true,"rule_id":"jdg.succ.r5","package":"jdg.micro.succ","priority":5415,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"W okresie zarzadu: JDG istnieje nadal, NIP bez zmian","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r6 — `succession_manager_rights_duties`: Zarzadca ma prawa i obowiazki przedsiebiorcy (VAT, PIT, ZUS, KSeF) → Uprawnienia
else :=   {"matched":true,"rule_id":"jdg.succ.r6","package":"jdg.micro.succ","priority":5416,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zarzadca ma prawa i obowiazki przedsiebiorcy (VAT, PIT, ZUS, KSeF)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r7 — `succession_manager_remuneration_limit`: Wynagrodzenie zarzadcy: do 6% przychodu → Limit
else :=   {"matched":true,"rule_id":"jdg.succ.r7","package":"jdg.micro.succ","priority":5417,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wynagrodzenie zarzadcy: do 6% przychodu","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r8 — `succession_deadline_for_acceptance`: Spadkobierca ma 6 miesiecy na przyjecie/odrzucenie spadku → Termin
else :=   {"matched":true,"rule_id":"jdg.succ.r8","package":"jdg.micro.succ","priority":5418,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Spadkobierca ma 6 miesiecy na przyjecie/odrzucenie spadku","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.succ.r9 — `succession_acceptance_with_benefit`: Przyjecie spadku z dobrodziejstwem inwentarza -> ograniczenie odpowiedzialnosci → Opcja
else :=   {"matched":true,"rule_id":"jdg.succ.r9","package":"jdg.micro.succ","priority":5419,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przyjecie spadku z dobrodziejstwem inwentarza -> ograniczenie odpowiedzialnosci","_legal_basis":"","_warnings":[]} {
    true
}
