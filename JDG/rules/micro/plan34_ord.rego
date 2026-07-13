# Generated from Plan OPA 34 — Micro-rules for jdg.ord
# 2026-07-13 14:11:39
# Rules: 189 (deduplicated)

package jdg.micro.ord

default decide := {"matched":false,"rule_id":"jdg.micro.ord.no_match","package":"jdg.micro.ord","priority":99999}

# jdg.ord.a29.r1 — `taxpayer_definition_jdg`: Osoba fizyczna prowadząca JDG jest podatnikiem PIT/VAT → Definicja
decide :=   {"matched":true,"rule_id":"jdg.ord.a29.r1","package":"jdg.micro.ord","priority":2901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Osoba fizyczna prowadząca JDG jest podatnikiem PIT/VAT","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a29.r2 — `taxpayer_legal_capacity`: JDG ma zdolność prawną (podatkową) jako osoba fizyczna → Zdolność
else :=   {"matched":true,"rule_id":"jdg.ord.a29.r2","package":"jdg.micro.ord","priority":2902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG ma zdolność prawną (podatkową) jako osoba fizyczna","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a29.r3 — `taxpayer_representation_self`: Przedsiębiorca JDG działa samodzielnie → Reprezentacja
else :=   {"matched":true,"rule_id":"jdg.ord.a29.r3","package":"jdg.micro.ord","priority":2903,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedsiębiorca JDG działa samodzielnie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a29.r4 — `taxpayer_representation_attorney`: Możliwość ustanowienia pełnomocnika → Pełnomocnik
else :=   {"matched":true,"rule_id":"jdg.ord.a29.r4","package":"jdg.micro.ord","priority":2904,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Możliwość ustanowienia pełnomocnika","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a29.r5 — `taxpayer_representation_attorney_form`: Pełnomocnictwo pisemne lub UPL → Forma
else :=   {"matched":true,"rule_id":"jdg.ord.a29.r5","package":"jdg.micro.ord","priority":2905,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pełnomocnictwo pisemne lub UPL","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a32.r1 — `taxpayer_correct_declaration_duty`: Deklaracje zgodne ze stanem faktycznym → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.ord.a32.r1","package":"jdg.micro.ord","priority":3201,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Deklaracje zgodne ze stanem faktycznym","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a32.r2 — `taxpayer_correct_declaration_consequences`: Błędna deklaracja → KKS, odsetki → Konsekwencje
else :=   {"matched":true,"rule_id":"jdg.ord.a32.r2","package":"jdg.micro.ord","priority":3202,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Błędna deklaracja → KKS, odsetki","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0
}

# jdg.ord.a33.r1 — `taxpayer_obligation_to_pay`: Zapłata podatku w terminie → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.ord.a33.r1","package":"jdg.micro.ord","priority":3301,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zapłata podatku w terminie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a33.r2 — `taxpayer_payment_methods`: Przelew, gotówka (do 15k B2B), karta → Metody
else :=   {"matched":true,"rule_id":"jdg.ord.a33.r2","package":"jdg.micro.ord","priority":3302,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przelew, gotówka (do 15k B2B), karta","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a33.r3 — `taxpayer_payment_currency_pln`: Podatki w PLN → Waluta
else :=   {"matched":true,"rule_id":"jdg.ord.a33.r3","package":"jdg.micro.ord","priority":3303,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatki w PLN","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a33.r4 — `taxpayer_payment_day_electronic`: Dzień obciążenia rachunku = dzień zapłaty → Data zapłaty
else :=   {"matched":true,"rule_id":"jdg.ord.a33.r4","package":"jdg.micro.ord","priority":3304,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dzień obciążenia rachunku = dzień zapłaty","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a33.r5 — `taxpayer_payment_day_cash`: Dzien wplaty gotowki w kasie US = dzien zaplaty → Dzien zaplaty
else :=   {"matched":true,"rule_id":"jdg.ord.a33.r5","package":"jdg.micro.ord","priority":3305,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dzien wplaty gotowki w kasie US = dzien zaplaty","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a33.r6 — `taxpayer_payment_day_postal`: Dzien nadania przekazu pocztowego = dzien zaplaty (do 2026) → Dzien zaplaty
else :=   {"matched":true,"rule_id":"jdg.ord.a33.r6","package":"jdg.micro.ord","priority":3306,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dzien nadania przekazu pocztowego = dzien zaplaty (do 2026)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a33.r7 — `taxpayer_payment_priority_debts`: Najstarsze zaległości pierwsze → Priorytet
else :=   {"matched":true,"rule_id":"jdg.ord.a33.r7","package":"jdg.micro.ord","priority":3307,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Najstarsze zaległości pierwsze","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_arrears_detected", false) == true
}

# jdg.ord.a33.r8 — `taxpayer_multi_debt_allocation`: Wpłata na kilka zobowiązań → proporcjonalnie → Alokacja
else :=   {"matched":true,"rule_id":"jdg.ord.a33.r8","package":"jdg.micro.ord","priority":3308,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wpłata na kilka zobowiązań → proporcjonalnie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a47.r1 — `interest_arrears_rate`: Podstawowa stopa odsetek = 2× stopa lombardowa NBP → Stawka
else :=   {"matched":true,"rule_id":"jdg.ord.a47.r1","package":"jdg.micro.ord","priority":4701,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawowa stopa odsetek = 2× stopa lombardowa NBP","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.document, "tax_arrears_detected", false) == true
}

# jdg.ord.a47.r2 — `interest_arrears_reduced`: Obniżona = 0.75× podstawowej (przy korekcie z czynnym żalem) → 0.75×
else :=   {"matched":true,"rule_id":"jdg.ord.a47.r2","package":"jdg.micro.ord","priority":4702,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obniżona = 0.75× podstawowej (przy korekcie z czynnym żalem)","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.document, "tax_arrears_detected", false) == true
}

# jdg.ord.a47.r3 — `interest_arrears_increased`: Podwyższona = 1.5× podstawowej (przy rażącym niedoborze) → 1.5×
else :=   {"matched":true,"rule_id":"jdg.ord.a47.r3","package":"jdg.micro.ord","priority":4703,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podwyższona = 1.5× podstawowej (przy rażącym niedoborze)","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.document, "tax_arrears_detected", false) == true
}

# jdg.ord.a47.r4 — `interest_rate_reduced_50pct`: Stawka 50% (dla korekt po kontroli, przed wszczeciem postepowania) → Stawka obnizona
else :=   {"matched":true,"rule_id":"jdg.ord.a47.r4","package":"jdg.micro.ord","priority":4704,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawka 50% (dla korekt po kontroli, przed wszczeciem postepowania)","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a47.r5 — `interest_calculation_period`: Odsetki od nastepnego dnia po terminie do dnia zaplaty → Okres
else :=   {"matched":true,"rule_id":"jdg.ord.a47.r5","package":"jdg.micro.ord","priority":4705,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odsetki od nastepnego dnia po terminie do dnia zaplaty","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0
}

# jdg.ord.a47.r6 — `interest_calculation_daily`: Odsetki liczone dziennie (kwota x stawka / 365) → Sposob liczenia
else :=   {"matched":true,"rule_id":"jdg.ord.a47.r6","package":"jdg.micro.ord","priority":4706,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odsetki liczone dziennie (kwota x stawka / 365)","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0
}

# jdg.ord.a47.r7 — `interest_minimum_3_30_pln`: Minimalna kwota odsetek do zaplaty: 3.30 PLN (lub 66.60 PLN w 2024) → Minimum
else :=   {"matched":true,"rule_id":"jdg.ord.a47.r7","package":"jdg.micro.ord","priority":4707,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Minimalna kwota odsetek do zaplaty: 3.30 PLN (lub 66.60 PLN w 2024)","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0
}

# jdg.ord.a48.r1 — `interest_deferral_extension`: Odroczenie terminu zaplaty -> odsetki oplaty prolongacyjnej (obnizona stawka) → Odroczenie
else :=   {"matched":true,"rule_id":"jdg.ord.a48.r1","package":"jdg.micro.ord","priority":4801,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odroczenie terminu zaplaty -> odsetki oplaty prolongacyjnej (obnizona stawka)","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.jdg_entrepreneur, "has_active_deferral", false) == true
}

# jdg.ord.a48.r2 — `interest_deferral_fee_50pct`: Oplata prolongacyjna = 50% stawki odsetek za zwloke → Stawka
else :=   {"matched":true,"rule_id":"jdg.ord.a48.r2","package":"jdg.micro.ord","priority":4802,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Oplata prolongacyjna = 50% stawki odsetek za zwloke","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.jdg_entrepreneur, "has_active_deferral", false) == true
}

# jdg.ord.a48.r3 — `interest_deferral_not_for_sanctions`: Odroczenie nie dotyczy kar podatkowych (KKS) → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ord.a48.r3","package":"jdg.micro.ord","priority":4803,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odroczenie nie dotyczy kar podatkowych (KKS)","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.jdg_entrepreneur, "has_active_deferral", false) == true
}

# jdg.ord.a49.r1 — `interest_suspension_force_majeure`: Zawieszenie naliczania odsetek w przypadku dzialania sily wyzszej (np. powodzi) → Zawieszenie
else :=   {"matched":true,"rule_id":"jdg.ord.a49.r1","package":"jdg.micro.ord","priority":4901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zawieszenie naliczania odsetek w przypadku dzialania sily wyzszej (np. powodzi)","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0
}

# jdg.ord.a49.r2 — `interest_suspension_moratorium`: Zawieszenie na mocy ustawy szczegolnej (moratorium podatkowe) → Zawieszenie
else :=   {"matched":true,"rule_id":"jdg.ord.a49.r2","package":"jdg.micro.ord","priority":4902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zawieszenie na mocy ustawy szczegolnej (moratorium podatkowe)","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0
}

# jdg.ord.a51.r1 — `interest_calculation_from_day_after_deadline`: Odsetki od dnia następnego po terminie płatności → Okres
else :=   {"matched":true,"rule_id":"jdg.ord.a51.r1","package":"jdg.micro.ord","priority":5101,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odsetki od dnia następnego po terminie płatności","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0
}

# jdg.ord.a51.r2 — `interest_calculation_to_payment_day`: Odsetki do dnia zapłaty włącznie → Okres
else :=   {"matched":true,"rule_id":"jdg.ord.a51.r2","package":"jdg.micro.ord","priority":5102,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odsetki do dnia zapłaty włącznie","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0
}

# jdg.ord.a51.r3 — `interest_calculation_rounding`: Zaokrąglenie do pełnych złotych → Zaokrąglenie
else :=   {"matched":true,"rule_id":"jdg.ord.a51.r3","package":"jdg.micro.ord","priority":5103,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaokrąglenie do pełnych złotych","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0
}

# jdg.ord.a51.r4 — `interest_minimum_amount`: Odsetki <3× koszt upomnienia → nie pobiera się → Minimum
else :=   {"matched":true,"rule_id":"jdg.ord.a51.r4","package":"jdg.micro.ord","priority":5104,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odsetki <3× koszt upomnienia → nie pobiera się","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0
}

# jdg.ord.a52.r1 — `interest_deferral_no_interest`: Odroczenie/rozłożenie → odsetki od zaległości NIE biegną → Odroczenie
else :=   {"matched":true,"rule_id":"jdg.ord.a52.r1","package":"jdg.micro.ord","priority":5201,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odroczenie/rozłożenie → odsetki od zaległości NIE biegną","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.jdg_entrepreneur, "has_active_deferral", false) == true; object.get(input.document, "tax_arrears_detected", false) == true
}

# jdg.ord.a52.r2 — `interest_deferral_extension_fee`: Opłata prolongacyjna = 0.5× stopa odsetek → Opłata
else :=   {"matched":true,"rule_id":"jdg.ord.a52.r2","package":"jdg.micro.ord","priority":5202,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Opłata prolongacyjna = 0.5× stopa odsetek","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.jdg_entrepreneur, "has_active_deferral", false) == true
}

# jdg.ord.a52.r3 — `interest_overpayment_refund`: Nadpłata → oprocentowanie w wysokości stopy odsetek → Zwrot
else :=   {"matched":true,"rule_id":"jdg.ord.a52.r3","package":"jdg.micro.ord","priority":5203,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nadpłata → oprocentowanie w wysokości stopy odsetek","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a52.r4 — `interest_overpayment_refund_deadline_30`: Zwrot nadpłaty w 30 dni (45 dla PIT/VAT) → Termin
else :=   {"matched":true,"rule_id":"jdg.ord.a52.r4","package":"jdg.micro.ord","priority":5204,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwrot nadpłaty w 30 dni (45 dla PIT/VAT)","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a52.r5 — `interest_overpayment_late_refund`: Po terminie → odsetki jak za zwłokę → Sankcja
else :=   {"matched":true,"rule_id":"jdg.ord.a52.r5","package":"jdg.micro.ord","priority":5205,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Po terminie → odsetki jak za zwłokę","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a67b.r1 — `relief_deferral_eligibility`: Ważny interes podatnika lub interes publiczny → Podstawa
else :=   {"matched":true,"rule_id":"jdg.ord.a67b.r1","package":"jdg.micro.ord","priority":6701,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ważny interes podatnika lub interes publiczny","_legal_basis":"","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_active_deferral", false) == true
}

# jdg.ord.a67c.r1 — `relief_application_form`: Wniosek na piśmie do naczelnika US → Forma
else :=   {"matched":true,"rule_id":"jdg.ord.a67c.r1","package":"jdg.micro.ord","priority":6701,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wniosek na piśmie do naczelnika US","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a67d.r1 — `relief_decision_deadline_1_month`: Decyzja w 1 miesiąc (2 miesiące skomplikowane) → Termin
else :=   {"matched":true,"rule_id":"jdg.ord.a67d.r1","package":"jdg.micro.ord","priority":6701,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Decyzja w 1 miesiąc (2 miesiące skomplikowane)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a67e.r1 — `relief_collateral_required`: Zabezpieczenie dla kwot > 500 000 PLN → Warunek
else :=   {"matched":true,"rule_id":"jdg.ord.a67e.r1","package":"jdg.micro.ord","priority":6701,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zabezpieczenie dla kwot > 500 000 PLN","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a67b.r2 — `relief_installment_max_12_months`: Rozłożenie na raty: max 12 miesięcy → Limit
else :=   {"matched":true,"rule_id":"jdg.ord.a67b.r2","package":"jdg.micro.ord","priority":6702,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rozłożenie na raty: max 12 miesięcy","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a67c.r2 — `relief_application_justification`: Uzasadnienie + dokumenty potwierdzające → Treść
else :=   {"matched":true,"rule_id":"jdg.ord.a67c.r2","package":"jdg.micro.ord","priority":6702,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Uzasadnienie + dokumenty potwierdzające","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a67d.r2 — `relief_decision_appeal`: Odwołanie do Dyrektora IAS w 14 dni → Odwołanie
else :=   {"matched":true,"rule_id":"jdg.ord.a67d.r2","package":"jdg.micro.ord","priority":6702,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odwołanie do Dyrektora IAS w 14 dni","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a67e.r2 — `relief_collateral_types`: Hipoteka, zastaw, gwarancja bankowa, ubezpieczenie → Formy
else :=   {"matched":true,"rule_id":"jdg.ord.a67e.r2","package":"jdg.micro.ord","priority":6702,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Hipoteka, zastaw, gwarancja bankowa, ubezpieczenie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a67b.r3 — `relief_deferral_max_12_months`: Odroczenie terminu: max 12 miesięcy → Limit
else :=   {"matched":true,"rule_id":"jdg.ord.a67b.r3","package":"jdg.micro.ord","priority":6703,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odroczenie terminu: max 12 miesięcy","_legal_basis":"","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_active_deferral", false) == true
}

# jdg.ord.a67e.r3 — `relief_collateral_valuation`: Wycena zabezpieczenia na min. 100% kwoty → Wycena
else :=   {"matched":true,"rule_id":"jdg.ord.a67e.r3","package":"jdg.micro.ord","priority":6703,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wycena zabezpieczenia na min. 100% kwoty","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a67b.r4 — `relief_remission_total`: Umorzenie całości — wyjątkowe sytuacje (klęski) → Całkowite
else :=   {"matched":true,"rule_id":"jdg.ord.a67b.r4","package":"jdg.micro.ord","priority":6704,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umorzenie całości — wyjątkowe sytuacje (klęski)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_remission_granted", false) == true
}

# jdg.ord.a67b.r5 — `relief_remission_partial`: Umorzenie części — trwała niezdolność do pracy → Częściowe
else :=   {"matched":true,"rule_id":"jdg.ord.a67b.r5","package":"jdg.micro.ord","priority":6705,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umorzenie części — trwała niezdolność do pracy","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_remission_granted", false) == true
}

# jdg.ord.a67b.r6 — `relief_deferral_criteria_income`: Kryterium: wysokosc dochodu, sytuacja majatkowa, liczebnosc rodziny → Kryterium
else :=   {"matched":true,"rule_id":"jdg.ord.a67b.r6","package":"jdg.micro.ord","priority":6706,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kryterium: wysokosc dochodu, sytuacja majatkowa, liczebnosc rodziny","_legal_basis":"","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_active_deferral", false) == true
}

# jdg.ord.a67b.r7 — `relief_deferral_application`: Wniosek podatnika o ulge (wraz z uzasadnieniem i dowodami) → Formalnosc
else :=   {"matched":true,"rule_id":"jdg.ord.a67b.r7","package":"jdg.micro.ord","priority":6707,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wniosek podatnika o ulge (wraz z uzasadnieniem i dowodami)","_legal_basis":"","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_active_deferral", false) == true
}

# jdg.ord.a67b.r8 — `relief_deferral_decision_2_months`: US ma 2 miesiace na decyzje (od dnia zlozenia kompleta dokumentow) → Termin
else :=   {"matched":true,"rule_id":"jdg.ord.a67b.r8","package":"jdg.micro.ord","priority":6708,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"US ma 2 miesiace na decyzje (od dnia zlozenia kompleta dokumentow)","_legal_basis":"","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_active_deferral", false) == true
}

# jdg.ord.a70.r1 — `statute_limitation_5_years`: 5 lat od końca roku kalendarzowego płatności → Termin podstawowy
else :=   {"matched":true,"rule_id":"jdg.ord.a70.r1","package":"jdg.micro.ord","priority":7001,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"5 lat od końca roku kalendarzowego płatności","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0
}

# jdg.ord.a70.r2 — `statute_limitation_5_plus_5`: Przedawnienie z zawieszeniem = 5+5=10 lat maks. → Maksymalny
else :=   {"matched":true,"rule_id":"jdg.ord.a70.r2","package":"jdg.micro.ord","priority":7002,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedawnienie z zawieszeniem = 5+5=10 lat maks.","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0
}

# jdg.ord.a70.r3 — `statute_suspension_tax_proceedings`: Wszczęcie postępowania karnego skarbowego → zawieszenie → Zawieszenie
else :=   {"matched":true,"rule_id":"jdg.ord.a70.r3","package":"jdg.micro.ord","priority":7003,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wszczęcie postępowania karnego skarbowego → zawieszenie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0; object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a70.r4 — `statute_suspension_tax_control`: Doręczenie zawiadomienia o kontroli → zawieszenie → Zawieszenie
else :=   {"matched":true,"rule_id":"jdg.ord.a70.r4","package":"jdg.micro.ord","priority":7004,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Doręczenie zawiadomienia o kontroli → zawieszenie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0; object.get(input.document, "audit_in_progress", false) == true; object.get(input.document, "official_notice_received", false) == true
}

# jdg.ord.a70.r5 — `statute_suspension_tax_liability_secured`: Zabezpieczenie na majątku → zawieszenie → Zawieszenie
else :=   {"matched":true,"rule_id":"jdg.ord.a70.r5","package":"jdg.micro.ord","priority":7005,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zabezpieczenie na majątku → zawieszenie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.ord.a70.r6 — `statute_interruption_first_enforcement`: Pierwsza czynność egzekucyjna → przerwanie → Przerwanie
else :=   {"matched":true,"rule_id":"jdg.ord.a70.r6","package":"jdg.micro.ord","priority":7006,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pierwsza czynność egzekucyjna → przerwanie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0; object.get(input.document, "enforcement_measure_applied", false) == true
}

# jdg.ord.a70.r7 — `statute_interruption_acknowledgment`: Uznanie długu przez podatnika → przerwanie → Przerwanie
else :=   {"matched":true,"rule_id":"jdg.ord.a70.r7","package":"jdg.micro.ord","priority":7007,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Uznanie długu przez podatnika → przerwanie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0
}

# jdg.ord.a70.r8 — `statute_consequences_expiration`: Przedawnienie → wygaśnięcie zobowiązania → Skutek
else :=   {"matched":true,"rule_id":"jdg.ord.a70.r8","package":"jdg.micro.ord","priority":7008,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedawnienie → wygaśnięcie zobowiązania","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0
}

# jdg.ord.a70.r9 — `statute_criminal_offense_5_years`: Przestępstwo skarbowe → 5 lat od popełnienia → KKS
else :=   {"matched":true,"rule_id":"jdg.ord.a70.r9","package":"jdg.micro.ord","priority":7009,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przestępstwo skarbowe → 5 lat od popełnienia","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0
}

# jdg.ord.a70.r10 — `statute_criminal_offense_10_years`: Przestępstwo skarbowe z zawieszeniem → max 10 lat → KKS max
else :=   {"matched":true,"rule_id":"jdg.ord.a70.r10","package":"jdg.micro.ord","priority":7010,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przestępstwo skarbowe z zawieszeniem → max 10 lat","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0
}

# jdg.ord.a70.r11 — `statute_of_limitations_overpayment_return`: Nadplata po przedawnieniu -> podlega zwrotowi (jesli nie ma innych zaleglosci) → Nadplata
else :=   {"matched":true,"rule_id":"jdg.ord.a70.r11","package":"jdg.micro.ord","priority":7011,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nadplata po przedawnieniu -> podlega zwrotowi (jesli nie ma innych zaleglosci)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0; object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a70.r12 — `statute_of_limitations_legal_entity_jdg`: JDG jako osoba fizyczna -> przedawnienie jak dla osoby fizycznej → Podmiot
else :=   {"matched":true,"rule_id":"jdg.ord.a70.r12","package":"jdg.micro.ord","priority":7012,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG jako osoba fizyczna -> przedawnienie jak dla osoby fizycznej","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0
}

# jdg.ord.a70.r13 — `statute_of_limitations_criminal_proceedings`: Wszczece postepowania karnego skarbowego -> przedawnienie 10 lat → KKS wydluzenie
else :=   {"matched":true,"rule_id":"jdg.ord.a70.r13","package":"jdg.micro.ord","priority":7013,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wszczece postepowania karnego skarbowego -> przedawnienie 10 lat","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0; object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a71.r1 — `statute_force_majeure_suspension`: Siła wyższa (powódź, pożar) → zawieszenie → Wyjątek
else :=   {"matched":true,"rule_id":"jdg.ord.a71.r1","package":"jdg.micro.ord","priority":7101,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Siła wyższa (powódź, pożar) → zawieszenie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0
}

# jdg.ord.a71.r2 — `statute_judicial_review_suspension`: Skarga do sądu administracyjnego → zawieszenie → Zawieszenie
else :=   {"matched":true,"rule_id":"jdg.ord.a71.r2","package":"jdg.micro.ord","priority":7102,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skarga do sądu administracyjnego → zawieszenie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0
}

# jdg.ord.a72.r1 — `overpayment_definition`: Kwota zapłacona > kwota należna → Definicja
else :=   {"matched":true,"rule_id":"jdg.ord.a72.r1","package":"jdg.micro.ord","priority":7201,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kwota zapłacona > kwota należna","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a72.r2 — `overpayment_self_detected`: Podatnik sam stwierdza nadpłatę → Wniosek
else :=   {"matched":true,"rule_id":"jdg.ord.a72.r2","package":"jdg.micro.ord","priority":7202,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatnik sam stwierdza nadpłatę","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a72.r3 — `overpayment_office_detected`: US stwierdza nadpłatę z urzędu → Automatyczne
else :=   {"matched":true,"rule_id":"jdg.ord.a72.r3","package":"jdg.micro.ord","priority":7203,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"US stwierdza nadpłatę z urzędu","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a72.r4 — `overpayment_return_extension_60_days`: Przedluzenie do 60 dni gdy US wymaga uzupelnienia dokumentacji → Przedluzenie
else :=   {"matched":true,"rule_id":"jdg.ord.a72.r4","package":"jdg.micro.ord","priority":7204,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedluzenie do 60 dni gdy US wymaga uzupelnienia dokumentacji","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a72.r5 — `overpayment_interest_after_deadline`: Po terminie 45/60 dni -> odsetki za zwloke od nadplaty → Odsetki
else :=   {"matched":true,"rule_id":"jdg.ord.a72.r5","package":"jdg.micro.ord","priority":7205,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Po terminie 45/60 dni -> odsetki za zwloke od nadplaty","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a73.r1 — `overpayment_offset_against_arrears`: Nadplata zaliczana na poczet zaleglosci podatkowych (urzedowo) → Zaliczanie
else :=   {"matched":true,"rule_id":"jdg.ord.a73.r1","package":"jdg.micro.ord","priority":7301,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nadplata zaliczana na poczet zaleglosci podatkowych (urzedowo)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true; object.get(input.document, "tax_arrears_detected", false) == true
}

# jdg.ord.a73.r2 — `overpayment_offset_against_future`: Nadplata na poczet przyszlych zobowiazan na wniosek → Przyszle
else :=   {"matched":true,"rule_id":"jdg.ord.a73.r2","package":"jdg.micro.ord","priority":7302,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nadplata na poczet przyszlych zobowiazan na wniosek","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a74.r1 — `overpayment_request_form`: Wniosek o zwrot nadplaty (brak wniosku -> zaliczenie z urzedu) → Formalnosc
else :=   {"matched":true,"rule_id":"jdg.ord.a74.r1","package":"jdg.micro.ord","priority":7401,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wniosek o zwrot nadplaty (brak wniosku -> zaliczenie z urzedu)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a75.r1 — `overpayment_refund_30_days`: Zwrot w 30 dni od złożenia wniosku → Termin
else :=   {"matched":true,"rule_id":"jdg.ord.a75.r1","package":"jdg.micro.ord","priority":7501,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwrot w 30 dni od złożenia wniosku","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a75.r2 — `overpayment_refund_45_days_pit_vat`: PIT/VAT: zwrot w 45 dni → Termin szczególny
else :=   {"matched":true,"rule_id":"jdg.ord.a75.r2","package":"jdg.micro.ord","priority":7502,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"PIT/VAT: zwrot w 45 dni","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a75.r3 — `overpayment_refund_60_days_complex`: Sprawy skomplikowane: 60 dni → Termin
else :=   {"matched":true,"rule_id":"jdg.ord.a75.r3","package":"jdg.micro.ord","priority":7503,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprawy skomplikowane: 60 dni","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a76.r1 — `overpayment_offset_arrears`: Nadpłata → zaliczenie na zaległości → Automatyczne
else :=   {"matched":true,"rule_id":"jdg.ord.a76.r1","package":"jdg.micro.ord","priority":7601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nadpłata → zaliczenie na zaległości","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true; object.get(input.document, "tax_arrears_detected", false) == true
}

# jdg.ord.a76.r2 — `overpayment_offset_future_tax`: Na wniosek: zaliczenie na przyszłe zobowiązania → Opcja
else :=   {"matched":true,"rule_id":"jdg.ord.a76.r2","package":"jdg.micro.ord","priority":7602,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Na wniosek: zaliczenie na przyszłe zobowiązania","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a77.r1 — `overpayment_interest_rate`: Oprocentowanie = stopa odsetek za zwłokę → Stopa
else :=   {"matched":true,"rule_id":"jdg.ord.a77.r1","package":"jdg.micro.ord","priority":7701,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Oprocentowanie = stopa odsetek za zwłokę","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a77.r2 — `overpayment_interest_from_day_after`: Od dnia następnego po wpłacie → Okres
else :=   {"matched":true,"rule_id":"jdg.ord.a77.r2","package":"jdg.micro.ord","priority":7702,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Od dnia następnego po wpłacie","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a78.r1 — `overpayment_not_possible_minus`: Nadpłata nie może być ujemna → Ograniczenie
else :=   {"matched":true,"rule_id":"jdg.ord.a78.r1","package":"jdg.micro.ord","priority":7801,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nadpłata nie może być ujemna","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a79.r1 — `overpayment_deduction_30_days_auto`: Automatyczny zwrot w 30 dni od skorygowania → Automatyczny
else :=   {"matched":true,"rule_id":"jdg.ord.a79.r1","package":"jdg.micro.ord","priority":7901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Automatyczny zwrot w 30 dni od skorygowania","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a79.r2 — `overpayment_correction_after_audit`: Korekta po ogloszeniu kontroli -> nadplata, ale mozliwe sankcje → Sankcje
else :=   {"matched":true,"rule_id":"jdg.ord.a79.r2","package":"jdg.micro.ord","priority":7902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta po ogloszeniu kontroli -> nadplata, ale mozliwe sankcje","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true; object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a80.r1 — `overpayment_inheritance`: Nadpłata po śmierci → dziedziczenie przez spadkobierców → Dziedziczenie
else :=   {"matched":true,"rule_id":"jdg.ord.a80.r1","package":"jdg.micro.ord","priority":8001,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nadpłata po śmierci → dziedziczenie przez spadkobierców","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a81.r1 — `correction_right_anytime`: Korekta deklaracji w każdym czasie → Prawo
else :=   {"matched":true,"rule_id":"jdg.ord.a81.r1","package":"jdg.micro.ord","priority":8101,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta deklaracji w każdym czasie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a81a.r1 — `correction_jpk_v7_procedure`: Korekta JPK_V7 na tym samym formularzu → Procedura
else :=   {"matched":true,"rule_id":"jdg.ord.a81a.r1","package":"jdg.micro.ord","priority":8101,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta JPK_V7 na tym samym formularzu","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a81b.r1 — `correction_overpayment_interest_delay`: Korekta → odsetki od nadpłaty po 30 dniach → Odsetki
else :=   {"matched":true,"rule_id":"jdg.ord.a81b.r1","package":"jdg.micro.ord","priority":8101,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta → odsetki od nadpłaty po 30 dniach","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0; object.get(input.document, "overpayment_detected", false) == true
}

# jdg.ord.a81c.r1 — `correction_automatic_vat_efakturowanie`: Korekta VAT przez KSeF → automatyczna weryfikacja → Automatyczna
else :=   {"matched":true,"rule_id":"jdg.ord.a81c.r1","package":"jdg.micro.ord","priority":8101,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta VAT przez KSeF → automatyczna weryfikacja","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a81.r2 — `correction_procedure_formal`: Korekta na tym samym formularzu co pierwotna → Forma
else :=   {"matched":true,"rule_id":"jdg.ord.a81.r2","package":"jdg.micro.ord","priority":8102,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta na tym samym formularzu co pierwotna","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a81a.r2 — `correction_jpk_v7_explanation_required`: Wyjaśnienie przyczyn korekty w JPK → Wymóg
else :=   {"matched":true,"rule_id":"jdg.ord.a81a.r2","package":"jdg.micro.ord","priority":8102,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wyjaśnienie przyczyn korekty w JPK","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a81.r3 — `correction_justification_required`: Uzasadnienie przyczyn korekty → Wymóg
else :=   {"matched":true,"rule_id":"jdg.ord.a81.r3","package":"jdg.micro.ord","priority":8103,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Uzasadnienie przyczyn korekty","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a81.r4 — `correction_no_limit_pre_audit`: Przed kontrolą → bez ograniczeń → Swoboda
else :=   {"matched":true,"rule_id":"jdg.ord.a81.r4","package":"jdg.micro.ord","priority":8104,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przed kontrolą → bez ograniczeń","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a81.r5 — `correction_limited_post_audit`: Po kontroli → tylko z nowych okoliczności → Ograniczenie
else :=   {"matched":true,"rule_id":"jdg.ord.a81.r5","package":"jdg.micro.ord","priority":8105,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Po kontroli → tylko z nowych okoliczności","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a81.r6 — `correction_5_year_deadline`: Korekta max 5 lat od końca roku → Przedawnienie
else :=   {"matched":true,"rule_id":"jdg.ord.a81.r6","package":"jdg.micro.ord","priority":8106,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta max 5 lat od końca roku","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0
}

# jdg.ord.a81.r7 — `correction_active_regret_immunity`: Korekta z czynnym żalem → brak sankcji KKS → Immunitet
else :=   {"matched":true,"rule_id":"jdg.ord.a81.r7","package":"jdg.micro.ord","priority":8107,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta z czynnym żalem → brak sankcji KKS","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a81.r8 — `correction_decrease_procedure`: Korekta in minus -> US sprawdza zasadnosc (30 dni na weryfikacje) → Weryfikacja
else :=   {"matched":true,"rule_id":"jdg.ord.a81.r8","package":"jdg.micro.ord","priority":8108,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta in minus -> US sprawdza zasadnosc (30 dni na weryfikacje)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a81.r9 — `correction_increase_payment_obligation`: Korekta in plus -> zaplata podatku + odsetki od pierwotnego terminu → Obowiazek zaplaty
else :=   {"matched":true,"rule_id":"jdg.ord.a81.r9","package":"jdg.micro.ord","priority":8109,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta in plus -> zaplata podatku + odsetki od pierwotnego terminu","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "days_overdue", 0) > 0
}

# jdg.ord.a119a.r1 — `gaar_artificiality_test`: Czynność sztuczna — bez uzasadnienia ekonomicznego → Przesłanka
else :=   {"matched":true,"rule_id":"jdg.ord.a119a.r1","package":"jdg.micro.ord","priority":11901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynność sztuczna — bez uzasadnienia ekonomicznego","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a119a.r2 — `gaar_tax_benefit_test`: Korzyść podatkowa > 100 000 PLN rocznie → Próg
else :=   {"matched":true,"rule_id":"jdg.ord.a119a.r2","package":"jdg.micro.ord","priority":11902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korzyść podatkowa > 100 000 PLN rocznie","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a119a.r3 — `gaar_economic_substance_test`: Brak rzeczywistej działalności gospodarczej → Test
else :=   {"matched":true,"rule_id":"jdg.ord.a119a.r3","package":"jdg.micro.ord","priority":11903,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak rzeczywistej działalności gospodarczej","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a119a.r4 — `gaar_contradiction_of_law_intent`: Sprzeczność z celem ustawy podatkowej → Przesłanka
else :=   {"matched":true,"rule_id":"jdg.ord.a119a.r4","package":"jdg.micro.ord","priority":11904,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprzeczność z celem ustawy podatkowej","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a119a.r5 — `gaar_opinion_safeguard_application`: Wniosek o opinię zabezpieczającą do Szefa KAS → Procedura
else :=   {"matched":true,"rule_id":"jdg.ord.a119a.r5","package":"jdg.micro.ord","priority":11905,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wniosek o opinię zabezpieczającą do Szefa KAS","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a119a.r6 — `gaar_opinion_safeguard_cost_20k`: Opłata za opinię: 20 000 PLN → Koszt
else :=   {"matched":true,"rule_id":"jdg.ord.a119a.r6","package":"jdg.micro.ord","priority":11906,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Opłata za opinię: 20 000 PLN","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a119a.r7 — `gaar_sanction_additional_40pct`: Sankcja: dodatkowe 40% zobowiązania → Sankcja
else :=   {"matched":true,"rule_id":"jdg.ord.a119a.r7","package":"jdg.micro.ord","priority":11907,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sankcja: dodatkowe 40% zobowiązania","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a119a.r8 — `gaar_sanction_30pct_if_opinion_sought`: Sankcja 30% jeśli złożono wniosek o opinię → Sankcja obniżona
else :=   {"matched":true,"rule_id":"jdg.ord.a119a.r8","package":"jdg.micro.ord","priority":11908,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sankcja 30% jeśli złożono wniosek o opinię","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a119a.r9 — `gaar_not_applicable_vat_below_5k`: VAT: nie stosuje się do zobowiązań < 5 000 PLN → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.ord.a119a.r9","package":"jdg.micro.ord","priority":11909,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"VAT: nie stosuje się do zobowiązań < 5 000 PLN","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a119a.r10 — `gaar_entity_dissolution_risk`: Rozwiązanie spółki → GAAR nie stosuje się → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.ord.a119a.r10","package":"jdg.micro.ord","priority":11910,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rozwiązanie spółki → GAAR nie stosuje się","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a145.r1 — `proceedings_initiation_ex_officio`: Postępowanie z urzędu lub na wniosek → Rozpoczęcie
else :=   {"matched":true,"rule_id":"jdg.ord.a145.r1","package":"jdg.micro.ord","priority":14501,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Postępowanie z urzędu lub na wniosek","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a145.r2 — `proceedings_notification_7_days`: Zawiadomienie strony w 7 dni → Termin
else :=   {"matched":true,"rule_id":"jdg.ord.a145.r2","package":"jdg.micro.ord","priority":14502,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zawiadomienie strony w 7 dni","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a145.r3 — `proceeding_party_rights`: JDG jako strona ma prawo: wglad w akta, wypowiedzenie sie, odvolanie → Prawa strony
else :=   {"matched":true,"rule_id":"jdg.ord.a145.r3","package":"jdg.micro.ord","priority":14503,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG jako strona ma prawo: wglad w akta, wypowiedzenie sie, odvolanie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a145.r4 — `proceeding_confidentiality`: Dane podatkowe JDG sa chronione tajemnica skarbowa → Tajemnica
else :=   {"matched":true,"rule_id":"jdg.ord.a145.r4","package":"jdg.micro.ord","priority":14504,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dane podatkowe JDG sa chronione tajemnica skarbowa","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a145.r5 — `proceeding_deadline_2_months`: Zalatywienie sprawy w 2 miesiace od wszczecia → Termin
else :=   {"matched":true,"rule_id":"jdg.ord.a145.r5","package":"jdg.micro.ord","priority":14505,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zalatywienie sprawy w 2 miesiace od wszczecia","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a145.r6 — `proceeding_deadline_extension_notification`: Przedluzenie terminu -> zawiadomienie strony → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.ord.a145.r6","package":"jdg.micro.ord","priority":14506,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedluzenie terminu -> zawiadomienie strony","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a146.r1 — `proceedings_secrecy_obligation`: Tajemnica skarbowa → obowiązek US → Ochrona
else :=   {"matched":true,"rule_id":"jdg.ord.a146.r1","package":"jdg.micro.ord","priority":14601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Tajemnica skarbowa → obowiązek US","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a146.r2 — `proceedings_evidence_any_legal`: Wszelkie legalne dowody dopuszczalne → Dowody
else :=   {"matched":true,"rule_id":"jdg.ord.a146.r2","package":"jdg.micro.ord","priority":14602,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wszelkie legalne dowody dopuszczalne","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a146.r3 — `proceeding_burden_of_proof_on_taxpayer`: Podatnik ma obowiazek przedstawic dowoly na okolicznosci korzystne dla siebie → Dowody podatnika
else :=   {"matched":true,"rule_id":"jdg.ord.a146.r3","package":"jdg.micro.ord","priority":14603,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatnik ma obowiazek przedstawic dowoly na okolicznosci korzystne dla siebie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a147.r1 — `proceedings_hearing_optional`: Rozprawa fakultatywna → Opcjonalna
else :=   {"matched":true,"rule_id":"jdg.ord.a147.r1","package":"jdg.micro.ord","priority":14701,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rozprawa fakultatywna","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a147.r2 — `proceedings_hearing_mandatory`: Rozprawa obowiązkowa dla kwot > 500k PLN → Obowiązkowa
else :=   {"matched":true,"rule_id":"jdg.ord.a147.r2","package":"jdg.micro.ord","priority":14702,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rozprawa obowiązkowa dla kwot > 500k PLN","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a147.r3 — `proceeding_decision_appeal_14_days`: Termin na odvolanie: 14 dni od doręczenia decyzji → Termin
else :=   {"matched":true,"rule_id":"jdg.ord.a147.r3","package":"jdg.micro.ord","priority":14703,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Termin na odvolanie: 14 dni od doręczenia decyzji","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true; object.get(input.document, "official_notice_received", false) == true
}

# jdg.ord.a147.r4 — `proceeding_decision_appeal_suspension`: Odvolanie wstrzymuje wykonanie decyzji (co do zasady) → Suspensywnosc
else :=   {"matched":true,"rule_id":"jdg.ord.a147.r4","package":"jdg.micro.ord","priority":14704,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odvolanie wstrzymuje wykonanie decyzji (co do zasady)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a148.r1 — `proceedings_duration_1_month`: Zakończenie w 1 miesiąc (2 miesiące skomplikowane) → Termin
else :=   {"matched":true,"rule_id":"jdg.ord.a148.r1","package":"jdg.micro.ord","priority":14801,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zakończenie w 1 miesiąc (2 miesiące skomplikowane)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a148.r2 — `proceedings_duration_extension`: Przedłużenie z ważnych przyczyn → Wyjątek
else :=   {"matched":true,"rule_id":"jdg.ord.a148.r2","package":"jdg.micro.ord","priority":14802,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedłużenie z ważnych przyczyn","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a149.r1 — `proceedings_decision_written`: Decyzja na piśmie z uzasadnieniem → Forma
else :=   {"matched":true,"rule_id":"jdg.ord.a149.r1","package":"jdg.micro.ord","priority":14901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Decyzja na piśmie z uzasadnieniem","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a149.r2 — `proceedings_decision_service_14_days`: Doręczenie decyzji w 14 dni od wydania → Termin
else :=   {"matched":true,"rule_id":"jdg.ord.a149.r2","package":"jdg.micro.ord","priority":14902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Doręczenie decyzji w 14 dni od wydania","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true; object.get(input.document, "official_notice_received", false) == true
}

# jdg.ord.a149.r3 — `proceedings_appeal_14_days`: Odwołanie w 14 dni od doręczenia → Termin
else :=   {"matched":true,"rule_id":"jdg.ord.a149.r3","package":"jdg.micro.ord","priority":14903,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odwołanie w 14 dni od doręczenia","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true; object.get(input.document, "official_notice_received", false) == true
}

# jdg.ord.a149.r4 — `proceedings_appeal_suspensive`: Odwołanie wstrzymuje wykonanie decyzji → Skutek
else :=   {"matched":true,"rule_id":"jdg.ord.a149.r4","package":"jdg.micro.ord","priority":14904,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odwołanie wstrzymuje wykonanie decyzji","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a165.r1 — `tax_control_notification_required`: Zawiadomienie o kontroli min. 7 dni przed → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.ord.a165.r1","package":"jdg.micro.ord","priority":16501,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zawiadomienie o kontroli min. 7 dni przed","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a165.r2 — `tax_control_notification_content`: Zakres, data rozpoczęcia, podstawa prawna → Treść
else :=   {"matched":true,"rule_id":"jdg.ord.a165.r2","package":"jdg.micro.ord","priority":16502,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zakres, data rozpoczęcia, podstawa prawna","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a165.r3 — `tax_control_notification_exception_fraud`: Wyjątek: podejrzenie przestępstwa → bez zawiadomienia → Wyjątek
else :=   {"matched":true,"rule_id":"jdg.ord.a165.r3","package":"jdg.micro.ord","priority":16503,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wyjątek: podejrzenie przestępstwa → bez zawiadomienia","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a165.r4 — `audit_max_duration_extension_14`: Przedluzenie o 14 dni w szczegolnych przypadkach → Przedluzenie
else :=   {"matched":true,"rule_id":"jdg.ord.a165.r4","package":"jdg.micro.ord","priority":16504,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedluzenie o 14 dni w szczegolnych przypadkach","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a165.r5 — `audit_breaks_not_counted`: Przerwy w kontroli nie wliczaja sie do limitu 30 dni → Przerwy
else :=   {"matched":true,"rule_id":"jdg.ord.a165.r5","package":"jdg.micro.ord","priority":16505,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przerwy w kontroli nie wliczaja sie do limitu 30 dni","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a165.r6 — `audit_no_second_audit_same_scope`: Zakaz powtarzania kontroli w tym samym zakresie w 3 lata (chyba ze nowe fakty) → Zakaz
else :=   {"matched":true,"rule_id":"jdg.ord.a165.r6","package":"jdg.micro.ord","priority":16506,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zakaz powtarzania kontroli w tym samym zakresie w 3 lata (chyba ze nowe fakty)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a165.r7 — `audit_no_second_audit_exception_fraud`: Nowe fakty, podejrzenie oszustwa -> mozliwa powtorna kontrola → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ord.a165.r7","package":"jdg.micro.ord","priority":16507,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nowe fakty, podejrzenie oszustwa -> mozliwa powtorna kontrola","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a166.r1 — `tax_control_max_duration_30_days`: Max 30 dni roboczych (dla małych: 12 dni) → Limit
else :=   {"matched":true,"rule_id":"jdg.ord.a166.r1","package":"jdg.micro.ord","priority":16601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Max 30 dni roboczych (dla małych: 12 dni)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a166.r2 — `tax_control_duration_extension`: Przedłużenie z ważnych przyczyn + uzasadnienie → Wyjątek
else :=   {"matched":true,"rule_id":"jdg.ord.a166.r2","package":"jdg.micro.ord","priority":16602,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedłużenie z ważnych przyczyn + uzasadnienie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a168.r1 — `audit_taxpayer_rights`: Prawa JDG podczas kontroli: obecnosc, pomoc prawnika, skladanie wyjasnien → Prawa
else :=   {"matched":true,"rule_id":"jdg.ord.a168.r1","package":"jdg.micro.ord","priority":16801,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Prawa JDG podczas kontroli: obecnosc, pomoc prawnika, skladanie wyjasnien","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a168.r2 — `audit_taxpayer_obligations`: Obowiazki: udostepnienie dokumentow, dostep do lokalu, udzielenie informacji → Obowiazki
else :=   {"matched":true,"rule_id":"jdg.ord.a168.r2","package":"jdg.micro.ord","priority":16802,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiazki: udostepnienie dokumentow, dostep do lokalu, udzielenie informacji","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a168.r3 — `audit_taxpayer_refusal_consequences`: Odmowa udostepnienia -> sankcja: 5000 PLN grzywny → Sankcja
else :=   {"matched":true,"rule_id":"jdg.ord.a168.r3","package":"jdg.micro.ord","priority":16803,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odmowa udostepnienia -> sankcja: 5000 PLN grzywny","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a170.r1 — `tax_control_taxpayer_obligation_books`: Udostępnienie ksiąg, ewidencji, dokumentów → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.ord.a170.r1","package":"jdg.micro.ord","priority":17001,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Udostępnienie ksiąg, ewidencji, dokumentów","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a170.r2 — `tax_control_taxpayer_presence`: Prawo do obecności przy czynnościach → Prawo
else :=   {"matched":true,"rule_id":"jdg.ord.a170.r2","package":"jdg.micro.ord","priority":17002,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Prawo do obecności przy czynnościach","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a170.r3 — `audit_protocol_objections_14_days`: Podatnik ma 14 dni na wniesienie zastezen do protokolu → Zastezenia
else :=   {"matched":true,"rule_id":"jdg.ord.a170.r3","package":"jdg.micro.ord","priority":17003,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatnik ma 14 dni na wniesienie zastezen do protokolu","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a170.r4 — `audit_protocol_objections_response`: US rozpatruje zastezenia w 14 dni → Rozpatrzenie
else :=   {"matched":true,"rule_id":"jdg.ord.a170.r4","package":"jdg.micro.ord","priority":17004,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"US rozpatruje zastezenia w 14 dni","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a171.r1 — `tax_control_protocol_mandatory`: Protokół z kontroli obowiązkowy → Wymóg
else :=   {"matched":true,"rule_id":"jdg.ord.a171.r1","package":"jdg.micro.ord","priority":17101,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Protokół z kontroli obowiązkowy","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a171.r2 — `tax_control_protocol_objections_14_days`: Zastrzeżenia do protokołu w 14 dni → Termin
else :=   {"matched":true,"rule_id":"jdg.ord.a171.r2","package":"jdg.micro.ord","priority":17102,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zastrzeżenia do protokołu w 14 dni","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a171.r3 — `tax_control_protocol_evidence_list`: Lista dowodów, zeznań świadków, ekspertyz → Treść
else :=   {"matched":true,"rule_id":"jdg.ord.a171.r3","package":"jdg.micro.ord","priority":17103,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Lista dowodów, zeznań świadków, ekspertyz","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a172.r1 — `audit_customs_control_period_3_months`: Kontrola celno-skarbowa max 3 miesiace (przedluzenie do 6) → Czas
else :=   {"matched":true,"rule_id":"jdg.ord.a172.r1","package":"jdg.micro.ord","priority":17201,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kontrola celno-skarbowa max 3 miesiace (przedluzenie do 6)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a173.r1 — `audit_results_assessment_decision`: Wynik kontroli -> decyzja wymiarowa (okreslenie zobowiazania podatkowego) → Decyzja
else :=   {"matched":true,"rule_id":"jdg.ord.a173.r1","package":"jdg.micro.ord","priority":17301,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wynik kontroli -> decyzja wymiarowa (okreslenie zobowiazania podatkowego)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a173.r2 — `audit_results_settlement_agreement`: Porozumienie w sprawie ustalenia stanu faktycznego (protokol zgodny) → Porozumienie
else :=   {"matched":true,"rule_id":"jdg.ord.a173.r2","package":"jdg.micro.ord","priority":17302,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Porozumienie w sprawie ustalenia stanu faktycznego (protokol zgodny)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a174.r1 — `audit_appeal_to_admin_court`: Od wyniku kontroli -> skarga do Wojewodzkiego Sadu Administracyjnego (WSA) → Sad
else :=   {"matched":true,"rule_id":"jdg.ord.a174.r1","package":"jdg.micro.ord","priority":17401,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Od wyniku kontroli -> skarga do Wojewodzkiego Sadu Administracyjnego (WSA)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.ord.a180.r1 — `tax_control_dispute_resolution`: Spór → mediacja lub postępowanie podatkowe → Rozwiązanie
else :=   {"matched":true,"rule_id":"jdg.ord.a180.r1","package":"jdg.micro.ord","priority":18001,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Spór → mediacja lub postępowanie podatkowe","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a180.r2 — `tax_control_dispute_hearing_request`: Wniosek o przesłuchanie przed wydaniem decyzji → Prawo
else :=   {"matched":true,"rule_id":"jdg.ord.a180.r2","package":"jdg.micro.ord","priority":18002,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wniosek o przesłuchanie przed wydaniem decyzji","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a199a.r1 — `gaar_detection_artificial_structure`: Czynnosc gospodarcza bez ekonomicznego uzasadnienia, stworzona dla oszczednosci podatkowych → Klauzula
else :=   {"matched":true,"rule_id":"jdg.ord.a199a.r1","package":"jdg.micro.ord","priority":19901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynnosc gospodarcza bez ekonomicznego uzasadnienia, stworzona dla oszczednosci podatkowych","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a199a.r2 — `gaar_artificiality_tests`: Testy: czy czynnosc jest zgodna z celem ustawy, czy podatnik mial biznesowy cel → Testy
else :=   {"matched":true,"rule_id":"jdg.ord.a199a.r2","package":"jdg.micro.ord","priority":19902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Testy: czy czynnosc jest zgodna z celem ustawy, czy podatnik mial biznesowy cel","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a199a.r3 — `gaar_economic_substance_test`: Test substancji ekonomicznej: czy czynnosc przynosi realne korzysci ekonomiczne → Test
else :=   {"matched":true,"rule_id":"jdg.ord.a199a.r3","package":"jdg.micro.ord","priority":19903,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Test substancji ekonomicznej: czy czynnosc przynosi realne korzysci ekonomiczne","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a199a.r4 — `gaar_tax_benefit_test`: Test korzysci podatkowej: czy glownym celem jest oszczednosc podatkowa → Test
else :=   {"matched":true,"rule_id":"jdg.ord.a199a.r4","package":"jdg.micro.ord","priority":19904,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Test korzysci podatkowej: czy glownym celem jest oszczednosc podatkowa","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a199a.r5 — `gaar_consequences_recharacterization`: Zakwestionowanie skutkow: US pomija czynnosc i opodatkowuje wedlug stanu rzeczywistego → Konsekwencja
else :=   {"matched":true,"rule_id":"jdg.ord.a199a.r5","package":"jdg.micro.ord","priority":19905,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zakwestionowanie skutkow: US pomija czynnosc i opodatkowuje wedlug stanu rzeczywistego","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a199a.r6 — `gaar_additional_tax_40pct`: Dodatkowe zobowiazanie podatkowe: 40% (lub 30% dla osoby fizycznej jesli wspolpraca) → Sankcja
else :=   {"matched":true,"rule_id":"jdg.ord.a199a.r6","package":"jdg.micro.ord","priority":19906,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dodatkowe zobowiazanie podatkowe: 40% (lub 30% dla osoby fizycznej jesli wspolpraca)","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a199a.r7 — `gaar_additional_tax_reduction_cooperation`: Zmniejszenie do 20% gdy podatnik przedlozyl oswiadczenie o schemacie MDR → Redukcja
else :=   {"matched":true,"rule_id":"jdg.ord.a199a.r7","package":"jdg.micro.ord","priority":19907,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmniejszenie do 20% gdy podatnik przedlozyl oswiadczenie o schemacie MDR","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a199a.r8 — `gaar_opinia_zabezpieczajaca`: JDG moze wystapic o opinie zabezpieczajaca (czy GAAR nie bedzie stosowany) → Opinia
else :=   {"matched":true,"rule_id":"jdg.ord.a199a.r8","package":"jdg.micro.ord","priority":19908,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG moze wystapic o opinie zabezpieczajaca (czy GAAR nie bedzie stosowany)","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a199a.r9 — `gaar_opinia_fee_20k`: Oplata za opinie zabezpieczajaca: 20 000 PLN → Oplata
else :=   {"matched":true,"rule_id":"jdg.ord.a199a.r9","package":"jdg.micro.ord","priority":19909,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Oplata za opinie zabezpieczajaca: 20 000 PLN","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a199a.r10 — `gaar_small_business_exception`: JDG o przychodach < 10M EUR - klauzula stosowana tylko do istotnych korzysci > 50k PLN → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ord.a199a.r10","package":"jdg.micro.ord","priority":19910,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG o przychodach < 10M EUR - klauzula stosowana tylko do istotnych korzysci > 50k PLN","_legal_basis":"","_warnings":[]} {
    object.get(input.invoice, "gaar_risk", false) == true
}

# jdg.ord.a208.r1 — `decision_first_instance_us`: Naczelnik US jako I instancja → Instancja
else :=   {"matched":true,"rule_id":"jdg.ord.a208.r1","package":"jdg.micro.ord","priority":20801,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Naczelnik US jako I instancja","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a208.r2 — `decision_appeal_ias_14_days`: Odwołanie do Dyrektora IAS w 14 dni → II instancja
else :=   {"matched":true,"rule_id":"jdg.ord.a208.r2","package":"jdg.micro.ord","priority":20802,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odwołanie do Dyrektora IAS w 14 dni","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a208.r3 — `decision_appeal_deadline_14_days`: Termin na odvolanie: 14 dni od doręczenia decyzji → Termin
else :=   {"matched":true,"rule_id":"jdg.ord.a208.r3","package":"jdg.micro.ord","priority":20803,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Termin na odvolanie: 14 dni od doręczenia decyzji","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "official_notice_received", false) == true
}

# jdg.ord.a208.r4 — `decision_appeal_form`: Odvolanie: pisemne, z uzasadnieniem, adresowane do II instancji → Forma
else :=   {"matched":true,"rule_id":"jdg.ord.a208.r4","package":"jdg.micro.ord","priority":20804,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odvolanie: pisemne, z uzasadnieniem, adresowane do II instancji","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a208.r5 — `decision_appeal_suspension_automatic`: Odvolanie wstrzymuje wykonanie decyzji → Suspensywnosc
else :=   {"matched":true,"rule_id":"jdg.ord.a208.r5","package":"jdg.micro.ord","priority":20805,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odvolanie wstrzymuje wykonanie decyzji","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a210.r1 — `decision_formal_requirements`: Podstawa prawna, uzasadnienie, pouczenie → Wymogi
else :=   {"matched":true,"rule_id":"jdg.ord.a210.r1","package":"jdg.micro.ord","priority":21001,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa prawna, uzasadnienie, pouczenie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a210.r2 — `decision_signature_electronic`: Podpis kwalifikowany lub profil zaufany → Forma
else :=   {"matched":true,"rule_id":"jdg.ord.a210.r2","package":"jdg.micro.ord","priority":21002,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podpis kwalifikowany lub profil zaufany","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a213.r1 — `decision_nullity_grounds`: Rażące naruszenie prawa → nieważność → Nieważność
else :=   {"matched":true,"rule_id":"jdg.ord.a213.r1","package":"jdg.micro.ord","priority":21301,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rażące naruszenie prawa → nieważność","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a213.r2 — `decision_nullity_procedure`: Stwierdzenie nieważności z urzędu lub na wniosek → Procedura
else :=   {"matched":true,"rule_id":"jdg.ord.a213.r2","package":"jdg.micro.ord","priority":21302,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stwierdzenie nieważności z urzędu lub na wniosek","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a213.r3 — `decision_renewal_deadline_absolute`: Bezwzgledny termin wznowienia: 5 lat od doręczenia decyzji → Termin
else :=   {"matched":true,"rule_id":"jdg.ord.a213.r3","package":"jdg.micro.ord","priority":21303,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Bezwzgledny termin wznowienia: 5 lat od doręczenia decyzji","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "official_notice_received", false) == true
}

# jdg.ord.a219.r1 — `decision_reopening_proceedings`: Nowe dowody → wznowienie postępowania → Wznowienie
else :=   {"matched":true,"rule_id":"jdg.ord.a219.r1","package":"jdg.micro.ord","priority":21901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nowe dowody → wznowienie postępowania","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.ord.a219.r2 — `decision_reopening_deadline_5_years`: Wznowienie max 5 lat od doręczenia decyzji → Termin
else :=   {"matched":true,"rule_id":"jdg.ord.a219.r2","package":"jdg.micro.ord","priority":21902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wznowienie max 5 lat od doręczenia decyzji","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "official_notice_received", false) == true
}

# jdg.ord.a220.r1 — `enforcement_warning_before_action`: Upomnienie przed egzekucją (7 dni na zapłatę) → Procedura
else :=   {"matched":true,"rule_id":"jdg.ord.a220.r1","package":"jdg.micro.ord","priority":22001,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Upomnienie przed egzekucją (7 dni na zapłatę)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "enforcement_measure_applied", false) == true
}

# jdg.ord.a220.r2 — `enforcement_initiation_after_warning`: Egzekucja po bezskutecznym upomnieniu → Rozpoczęcie
else :=   {"matched":true,"rule_id":"jdg.ord.a220.r2","package":"jdg.micro.ord","priority":22002,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Egzekucja po bezskutecznym upomnieniu","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "enforcement_measure_applied", false) == true
}

# jdg.ord.a221.r1 — `enforcement_methods_bank_account`: Zajęcie rachunku bankowego → Metoda
else :=   {"matched":true,"rule_id":"jdg.ord.a221.r1","package":"jdg.micro.ord","priority":22101,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zajęcie rachunku bankowego","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "enforcement_measure_applied", false) == true
}

# jdg.ord.a221.r2 — `enforcement_methods_salary`: Zajęcie wynagrodzenia (max 60% netto) → Metoda
else :=   {"matched":true,"rule_id":"jdg.ord.a221.r2","package":"jdg.micro.ord","priority":22102,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zajęcie wynagrodzenia (max 60% netto)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "enforcement_measure_applied", false) == true
}

# jdg.ord.a221.r3 — `enforcement_methods_movable_property`: Zajęcie ruchomości (sprzęt, pojazdy) → Metoda
else :=   {"matched":true,"rule_id":"jdg.ord.a221.r3","package":"jdg.micro.ord","priority":22103,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zajęcie ruchomości (sprzęt, pojazdy)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "enforcement_measure_applied", false) == true
}

# jdg.ord.a221.r4 — `enforcement_methods_real_estate`: Zajęcie nieruchomości (hipoteka przymusowa) → Metoda
else :=   {"matched":true,"rule_id":"jdg.ord.a221.r4","package":"jdg.micro.ord","priority":22104,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zajęcie nieruchomości (hipoteka przymusowa)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "enforcement_measure_applied", false) == true
}

# jdg.ord.a222.r1 — `enforcement_protected_assets_tools`: Narzędzia niezbędne do pracy → wyłączenie → Ochrona
else :=   {"matched":true,"rule_id":"jdg.ord.a222.r1","package":"jdg.micro.ord","priority":22201,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Narzędzia niezbędne do pracy → wyłączenie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "enforcement_measure_applied", false) == true
}

# jdg.ord.a222.r2 — `enforcement_protected_assets_min_wage`: Kwota wolna od zajęcia (min. wynagrodzenie) → Ochrona
else :=   {"matched":true,"rule_id":"jdg.ord.a222.r2","package":"jdg.micro.ord","priority":22202,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kwota wolna od zajęcia (min. wynagrodzenie)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "enforcement_measure_applied", false) == true
}

# jdg.ord.a222.r3 — `tax_arrears_wage_seizure`: Zajecie wynagrodzenia (gdy JDG ma pracownikow) -> z wierzytelnosci → Zajecie
else :=   {"matched":true,"rule_id":"jdg.ord.a222.r3","package":"jdg.micro.ord","priority":22203,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zajecie wynagrodzenia (gdy JDG ma pracownikow) -> z wierzytelnosci","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_arrears_detected", false) == true
}

# jdg.ord.a222.r4 — `tax_arrears_movable_property_seizure`: Zajecie ruchomosci (samochod, sprzet) -> opis i oszacowanie → Ruchomosci
else :=   {"matched":true,"rule_id":"jdg.ord.a222.r4","package":"jdg.micro.ord","priority":22204,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zajecie ruchomosci (samochod, sprzet) -> opis i oszacowanie","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_arrears_detected", false) == true
}

# jdg.ord.a223.r1 — `tax_arrears_enforcement_protected_assets`: Mienie wolne od egzekucji: ubranie, zywnosc, narzedzia pracy do 2k → Ochrona
else :=   {"matched":true,"rule_id":"jdg.ord.a223.r1","package":"jdg.micro.ord","priority":22301,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mienie wolne od egzekucji: ubranie, zywnosc, narzedzia pracy do 2k","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "enforcement_measure_applied", false) == true; object.get(input.document, "tax_arrears_detected", false) == true
}

# jdg.ord.a224.r1 — `tax_arrears_mortgage_tax`: Hipoteka przymusowa na nieruchomosci JDG dla zabezpieczenia zaleglosci → Hipoteka
else :=   {"matched":true,"rule_id":"jdg.ord.a224.r1","package":"jdg.micro.ord","priority":22401,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Hipoteka przymusowa na nieruchomosci JDG dla zabezpieczenia zaleglosci","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "tax_arrears_detected", false) == true
}

# jdg.ord.a225.r1 — `tax_arrears_statute_of_limitations_enforcement`: Przedawnienie egzekucji: 5 lat od zakonczenia postepowania → Przedawnienie egzekucji
else :=   {"matched":true,"rule_id":"jdg.ord.a225.r1","package":"jdg.micro.ord","priority":22501,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedawnienie egzekucji: 5 lat od zakonczenia postepowania","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "years_since_due_year", 0) > 0; object.get(input.document, "enforcement_measure_applied", false) == true; object.get(input.document, "tax_arrears_detected", false) == true
}

# jdg.ord.a226.r1 — `enforcement_security_prior_to_decision`: Zabezpieczenie przed wydaniem decyzji → Tymczasowe
else :=   {"matched":true,"rule_id":"jdg.ord.a226.r1","package":"jdg.micro.ord","priority":22601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zabezpieczenie przed wydaniem decyzji","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "enforcement_measure_applied", false) == true
}

# jdg.ord.a226.r2 — `enforcement_security_form`: Hipoteka, zastaw, blokada rachunku → Formy
else :=   {"matched":true,"rule_id":"jdg.ord.a226.r2","package":"jdg.micro.ord","priority":22602,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Hipoteka, zastaw, blokada rachunku","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "enforcement_measure_applied", false) == true
}
