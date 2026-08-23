# Generated from Plan OPA 34 — Micro-rules for jdg.pit
# 2026-07-13 14:11:39
# Rules: 265 (deduplicated)

package jdg.micro.pit.plan34

import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.micro.pit.plan34.no_match","package":"jdg.micro.pit.plan34","priority":99999}

# jdg.pit.p580.r1 — `pit_exemption_young`: Ulga dla młodych (do 26 lat) → Wiek < 26 lat, przychody z pracy/działalności
decide :=   {"matched":true,"rule_id":"jdg.pit.p580.r1","package":"jdg.micro.pit.plan34","priority":1,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga dla młodych (do 26 lat)","_legal_basis":"Art. 21 ust. 1 pkt 148 PIT — Ulga dla młodych (do 26 lat)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.p582.r1 — `pit_exemption_return`: Ulga na powrót — powrót do Polski po 31.12.2021 → 3 lata zamieszkania za granicą + polska rezydencja
else :=   {"matched":true,"rule_id":"jdg.pit.p582.r1","package":"jdg.micro.pit.plan34","priority":1,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga na powrót — powrót do Polski po 31.12.2021","_legal_basis":"Art. 21 ust. 1 pkt 152 PIT — Ulga na powrót","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.p584.r1 — `pit_exemption_family_4plus`: Ulga 4+ — rodziny z min. 4 dzieci → Wychowywanie min. 4 dzieci
else :=   {"matched":true,"rule_id":"jdg.pit.p584.r1","package":"jdg.micro.pit.plan34","priority":1,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga 4+ — rodziny z min. 4 dzieci","_legal_basis":"Art. 21 ust. 1 pkt 153 PIT — Ulga 4+","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"; object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.p586.r1 — `pit_exemption_working_senior`: Ulga dla pracujących seniorów → Kobieta 60+ / mężczyzna 65+, niepobierający emerytury
else :=   {"matched":true,"rule_id":"jdg.pit.p586.r1","package":"jdg.micro.pit.plan34","priority":1,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga dla pracujących seniorów","_legal_basis":"Art. 21 ust. 1 pkt 154 PIT — Ulga dla pracujących seniorów","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.p0limit.r1 — `pit0_shared_limit_85528`: Wspólny limit 85 528 PLN dla ulg PIT-0 → Suma zwolnień ≤ 85 528 PLN
else :=   {"matched":true,"rule_id":"jdg.pit.p0limit.r1","package":"jdg.micro.pit.plan34","priority":1,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wspólny limit 85 528 PLN dla ulg PIT-0","_legal_basis":"Art. 21 ust. 1 pkt 148-154 PIT — Wspólny limit 85 528 PLN","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "married", false) == true
}

# jdg.pit.p580.r2 — `pit_exemption_young_jdg`: JDG osoby do 26 roku życia → Prowadzenie JDG + wiek < 26
else :=   {"matched":true,"rule_id":"jdg.pit.p580.r2","package":"jdg.micro.pit.plan34","priority":2,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG osoby do 26 roku życia","_legal_basis":"Art. 21 ust. 1 pkt 148 PIT — Ulga dla młodych (do 26 lat)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.p582.r2 — `pit_exemption_return_jdg`: JDG dla powracających → JDG jako źródło przychodu objęte ulgą
else :=   {"matched":true,"rule_id":"jdg.pit.p582.r2","package":"jdg.micro.pit.plan34","priority":2,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG dla powracających","_legal_basis":"Art. 21 ust. 1 pkt 152 PIT — Ulga na powrót","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.p584.r2 — `pit_exemption_family_4plus_jdg`: JDG dla rodzin 4+ → Przychód z JDG objęty zwolnieniem
else :=   {"matched":true,"rule_id":"jdg.pit.p584.r2","package":"jdg.micro.pit.plan34","priority":2,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG dla rodzin 4+","_legal_basis":"Art. 21 ust. 1 pkt 153 PIT — Ulga 4+","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"
}

# jdg.pit.p586.r2 — `pit_exemption_working_senior_jdg`: JDG dla seniorów → JDG jako źródło, niepobieranie emerytury
else :=   {"matched":true,"rule_id":"jdg.pit.p586.r2","package":"jdg.micro.pit.plan34","priority":2,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG dla seniorów","_legal_basis":"Art. 21 ust. 1 pkt 154 PIT — Ulga dla pracujących seniorów","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.p0limit.r2 — `pit0_over_limit_taxation`: Nadwyżka ponad 85 528 PLN opodatkowana normalnie → Standardowe opodatkowanie
else :=   {"matched":true,"rule_id":"jdg.pit.p0limit.r2","package":"jdg.micro.pit.plan34","priority":2,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nadwyżka ponad 85 528 PLN opodatkowana normalnie","_legal_basis":"Art. 21 ust. 1 pkt 148-154 PIT — Wspólny limit 85 528 PLN","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.p580.r3 — `pit_exemption_young_excluded`: Wyłączenie: umowa o dzieło, prawa autorskie poza JDG → Niektóre przychody wyłączone
else :=   {"matched":true,"rule_id":"jdg.pit.p580.r3","package":"jdg.micro.pit.plan34","priority":3,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wyłączenie: umowa o dzieło, prawa autorskie poza JDG","_legal_basis":"Art. 21 ust. 1 pkt 148 PIT — Ulga dla młodych (do 26 lat)","_warnings":[]} {
    object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "category_code", "") == "CAR"; object.get(input.invoice, "expense_type", "") == "COPYRIGHT"
}

# jdg.pit.p582.r3 — `pit_exemption_return_4_years`: Ulga na 4 kolejne lata podatkowe → Od roku powrotu
else :=   {"matched":true,"rule_id":"jdg.pit.p582.r3","package":"jdg.micro.pit.plan34","priority":3,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga na 4 kolejne lata podatkowe","_legal_basis":"Art. 21 ust. 1 pkt 152 PIT — Ulga na powrót","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.p584.r3 — `pit_exemption_family_4plus_spouse`: Wspólne rozliczenie małżonków 4+ → Każdy z małżonków osobno
else :=   {"matched":true,"rule_id":"jdg.pit.p584.r3","package":"jdg.micro.pit.plan34","priority":3,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wspólne rozliczenie małżonków 4+","_legal_basis":"Art. 21 ust. 1 pkt 153 PIT — Ulga 4+","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "SPOUSE"; input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "married", false) == true
}

# jdg.pit.p586.r3 — `pit_exemption_working_senior_pension_block`: Pobieranie emerytury/renty → brak ulgi → Warunek wykluczający
else :=   {"matched":true,"rule_id":"jdg.pit.p586.r3","package":"jdg.micro.pit.plan34","priority":3,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pobieranie emerytury/renty → brak ulgi","_legal_basis":"Art. 21 ust. 1 pkt 154 PIT — Ulga dla pracujących seniorów","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.p0limit.r3 — `pit0_joint_with_tax_free_30k`: Po przekroczeniu 85 528 PLN przysługuje kwota wolna 30 000 PLN → Dodatkowa korzyść
else :=   {"matched":true,"rule_id":"jdg.pit.p0limit.r3","package":"jdg.micro.pit.plan34","priority":3,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Po przekroczeniu 85 528 PLN przysługuje kwota wolna 30 000 PLN","_legal_basis":"Art. 21 ust. 1 pkt 148-154 PIT — Wspólny limit 85 528 PLN","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "married", false) == true
}

# jdg.pit.p0limit.r4 — `pit0_not_available_tax_card`: Karta podatkowa wyłączona z PIT-0 → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.p0limit.r4","package":"jdg.micro.pit.plan34","priority":4,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Karta podatkowa wyłączona z PIT-0","_legal_basis":"Art. 21 ust. 1 pkt 148-154 PIT — Wspólny limit 85 528 PLN","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "TAX_CARD"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a9a.r1 — `tax_form_selection_freedom`: JDG wybiera formę → Wolność wyboru
else :=   {"matched":true,"rule_id":"jdg.pit.a9a.r1","package":"jdg.micro.pit.plan34","priority":901,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG wybiera formę","_legal_basis":"Art. 9a PIT — Formy opodatkowania","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a9a.r2 — `tax_form_linear_option_19pct`: Liniowy 19% → brak kwoty wolnej → 19%
else :=   {"matched":true,"rule_id":"jdg.pit.a9a.r2","package":"jdg.micro.pit.plan34","priority":902,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Liniowy 19% → brak kwoty wolnej","_legal_basis":"Art. 9a PIT — Formy opodatkowania","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
}

# jdg.pit.a9a.r4 — `tax_form_linear_former_employer_3_years`: Usługi dla byłego pracodawcy → blokada 3 lata → Blokada
else :=   {"matched":true,"rule_id":"jdg.pit.a9a.r4","package":"jdg.micro.pit.plan34","priority":904,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usługi dla byłego pracodawcy → blokada 3 lata","_legal_basis":"Art. 9a PIT — Formy opodatkowania","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a9a.r5 — `tax_form_change_deadline_20_january`: Zmiana formy do 20 stycznia → Termin
else :=   {"matched":true,"rule_id":"jdg.pit.a9a.r5","package":"jdg.micro.pit.plan34","priority":905,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana formy do 20 stycznia","_legal_basis":"Art. 9a PIT — Formy opodatkowania","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a9a.r7 — `tax_form_change_automatic_return_to_scale`: Brak oświadczenia → skala domyślnie → Domyślna
else :=   {"matched":true,"rule_id":"jdg.pit.a9a.r7","package":"jdg.micro.pit.plan34","priority":907,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak oświadczenia → skala domyślnie","_legal_basis":"Art. 9a PIT — Formy opodatkowania","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a10.r1 — `income_source_business_jdg`: Działalność gospodarcza (JDG) → Art. 10 ust. 1 pkt 3
else :=   {"matched":true,"rule_id":"jdg.pit.a10.r1","package":"jdg.micro.pit.plan34","priority":1001,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Działalność gospodarcza (JDG)","_legal_basis":"Art. 10 PIT — Źródła przychodów","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a10.r2 — `income_source_employment`: Umowa o pracę (jeśli JDG również na etacie) → Art. 10 ust. 1 pkt 1
else :=   {"matched":true,"rule_id":"jdg.pit.a10.r2","package":"jdg.micro.pit.plan34","priority":1002,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa o pracę (jeśli JDG również na etacie)","_legal_basis":"Art. 10 PIT — Źródła przychodów","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a10.r3 — `income_source_civil_contracts`: Umowy zlecenia, o dzieło (poza JDG) → Art. 10 ust. 1 pkt 2
else :=   {"matched":true,"rule_id":"jdg.pit.a10.r3","package":"jdg.micro.pit.plan34","priority":1003,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowy zlecenia, o dzieło (poza JDG)","_legal_basis":"Art. 10 PIT — Źródła przychodów","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a10.r4 — `income_source_rental_sublease`: Najem, dzierżawa → Art. 10 ust. 1 pkt 6
else :=   {"matched":true,"rule_id":"jdg.pit.a10.r4","package":"jdg.micro.pit.plan34","priority":1004,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Najem, dzierżawa","_legal_basis":"Art. 10 PIT — Źródła przychodów","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a10.r5 — `income_source_capital_gains`: Zbycie akcji, udziałów → Art. 10 ust. 1 pkt 7
else :=   {"matched":true,"rule_id":"jdg.pit.a10.r5","package":"jdg.micro.pit.plan34","priority":1005,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zbycie akcji, udziałów","_legal_basis":"Art. 10 PIT — Źródła przychodów","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.invoice, "income_source", "") == "CAPITAL_GAINS"
}

# jdg.pit.a10.r6 — `income_source_real_estate_sale`: Sprzedaż nieruchomości przed upływem 5 lat → Art. 10 ust. 1 pkt 8
else :=   {"matched":true,"rule_id":"jdg.pit.a10.r6","package":"jdg.micro.pit.plan34","priority":1006,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprzedaż nieruchomości przed upływem 5 lat","_legal_basis":"Art. 10 PIT — Źródła przychodów","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.invoice, "category_code", "") == "REAL_ESTATE"
}

# jdg.pit.a10.r7 — `income_source_intellectual_property`: Zbycie praw autorskich, patentów → Art. 10 ust. 1 pkt 7
else :=   {"matched":true,"rule_id":"jdg.pit.a10.r7","package":"jdg.micro.pit.plan34","priority":1007,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zbycie praw autorskich, patentów","_legal_basis":"Art. 10 PIT — Źródła przychodów","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a10.r8 — `income_source_retirement_pension`: Emerytura, renta → Art. 10 ust. 1 pkt 1
else :=   {"matched":true,"rule_id":"jdg.pit.a10.r8","package":"jdg.micro.pit.plan34","priority":1008,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Emerytura, renta","_legal_basis":"Art. 10 PIT — Źródła przychodów","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a10.r9 — `income_source_other_sources`: Inne: alimenty, stypendia, wygrane → Art. 10 ust. 1 pkt 9
else :=   {"matched":true,"rule_id":"jdg.pit.a10.r9","package":"jdg.micro.pit.plan34","priority":1009,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Inne: alimenty, stypendia, wygrane","_legal_basis":"Art. 10 PIT — Źródła przychodów","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a10.r10 — `income_source_separate_categories`: Każde źródło opodatkowane odrębnie → Zasada odrębności
else :=   {"matched":true,"rule_id":"jdg.pit.a10.r10","package":"jdg.micro.pit.plan34","priority":1010,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Każde źródło opodatkowane odrębnie","_legal_basis":"Art. 10 PIT — Źródła przychodów","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a14.r1 — `revenue_definition_jdg`: Kwoty należne (memoriał) → Definicja przychodu
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r1","package":"jdg.micro.pit.plan34","priority":1401,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kwoty należne (memoriał)","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14c.r1 — `fx_difference_realized_revenue`: Kurs zapłaty > kurs faktury → Dodatnia FX = przychód
else :=   {"matched":true,"rule_id":"jdg.pit.a14c.r1","package":"jdg.micro.pit.plan34","priority":1401,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kurs zapłaty > kurs faktury","_legal_basis":"Art. 14c PIT — Różnice kursowe","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; input.invoice.currency != "PLN"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14.r2 — `revenue_cash_method_pkpir`: PKPiR: data faktury lub 25. dnia miesiąca → Metoda memoriałowa uproszczona
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r2","package":"jdg.micro.pit.plan34","priority":1402,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"PKPiR: data faktury lub 25. dnia miesiąca","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14c.r2 — `fx_difference_realized_cost`: Kurs zapłaty < kurs faktury → Ujemna FX = KUP
else :=   {"matched":true,"rule_id":"jdg.pit.a14c.r2","package":"jdg.micro.pit.plan34","priority":1402,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kurs zapłaty < kurs faktury","_legal_basis":"Art. 14c PIT — Różnice kursowe","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; input.invoice.currency != "PLN"
}

# jdg.pit.a14.r3 — `revenue_direct_cash_method`: Metoda kasowa — opcja → Przychód w dacie zapłaty
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r3","package":"jdg.micro.pit.plan34","priority":1403,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Metoda kasowa — opcja","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14.r5 — `revenue_exclusion_vat_refund`: Zwrot VAT → NIE przychód → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r5","package":"jdg.micro.pit.plan34","priority":1405,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwrot VAT → NIE przychód","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14c.r5 — `fx_difference_method_podatkowa`: Kurs faktycznie zastosowany lub średni NBP → Wybór metody
else :=   {"matched":true,"rule_id":"jdg.pit.a14c.r5","package":"jdg.micro.pit.plan34","priority":1405,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kurs faktycznie zastosowany lub średni NBP","_legal_basis":"Art. 14c PIT — Różnice kursowe","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.pit.a14.r6 — `revenue_exclusion_zus_overpayment`: Zwrot nadpłaty ZUS → NIE przychód → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r6","package":"jdg.micro.pit.plan34","priority":1406,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwrot nadpłaty ZUS → NIE przychód","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14.r7 — `revenue_exclusion_loan_repayment`: Spłata pożyczki → NIE przychód → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r7","package":"jdg.micro.pit.plan34","priority":1407,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Spłata pożyczki → NIE przychód","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14c.r7 — `fx_difference_unrealized_balance_sheet`: Wycena sald walutowych na dzień bilansowy → Wycena bilansowa
else :=   {"matched":true,"rule_id":"jdg.pit.a14c.r7","package":"jdg.micro.pit.plan34","priority":1407,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wycena sald walutowych na dzień bilansowy","_legal_basis":"Art. 14c PIT — Różnice kursowe","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.pit.a14.r8 — `revenue_exclusion_damages`: Odszkodowanie za składniki majątku → NIE przychód → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r8","package":"jdg.micro.pit.plan34","priority":1408,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odszkodowanie za składniki majątku → NIE przychód","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14.r13 — `revenue_in_kind_market_value`: Przychód w naturze → wartość rynkowa → Wycena
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r13","package":"jdg.micro.pit.plan34","priority":1413,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przychód w naturze → wartość rynkowa","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14.r14 — `revenue_foreign_currency_conversion`: Waluta obca → kurs NBP z dnia poprzedzającego → Kurs
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r14","package":"jdg.micro.pit.plan34","priority":1414,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Waluta obca → kurs NBP z dnia poprzedzającego","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; input.invoice.currency != "PLN"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14.r16 — `revenue_discounts_abatements`: Rabaty, upusty → pomniejszenie przychodu → Korekta
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r16","package":"jdg.micro.pit.plan34","priority":1416,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rabaty, upusty → pomniejszenie przychodu","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14.r20 — `revenue_taxable_benefit_private_car`: Prywatny użytek auta firmowego → 250 PLN/mies. → Przychód ryczałtowy
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r20","package":"jdg.micro.pit.plan34","priority":1420,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Prywatny użytek auta firmowego → 250 PLN/mies.","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"; object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "category_code", "") == "CAR"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a22.r1 — `kup_general_definition`: Koszty poniesione w celu osiągnięcia przychodu → Definicja ogólna
else :=   {"matched":true,"rule_id":"jdg.pit.a22.r1","package":"jdg.micro.pit.plan34","priority":2201,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszty poniesione w celu osiągnięcia przychodu","_legal_basis":"Art. 22 PIT — Koszty uzyskania przychodów","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a22a.r1 — `depreciation_asset_classification`: Okres >1 rok, kompletny, firmowy → Kwalifikacja ŚT
else :=   {"matched":true,"rule_id":"jdg.pit.a22a.r1","package":"jdg.micro.pit.plan34","priority":2201,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Okres >1 rok, kompletny, firmowy","_legal_basis":"Art. 22a PIT — Środki trwałe, wartości niematerialne i prawne","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22d.r1 — `depreciation_method_linear`: Równomierne odpisy → Standard
else :=   {"matched":true,"rule_id":"jdg.pit.a22d.r1","package":"jdg.micro.pit.plan34","priority":2201,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Równomierne odpisy","_legal_basis":"Art. 22d PIT — Metody amortyzacji (liniowa, degresywna)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22e.r1 — `depreciation_low_value_one_time_100k`: Mały środek trwały do 100k → Jednorazowo
else :=   {"matched":true,"rule_id":"jdg.pit.a22e.r1","package":"jdg.micro.pit.plan34","priority":2201,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mały środek trwały do 100k","_legal_basis":"Art. 22e PIT — Mała wartość (jednorazowa amortyzacja)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22g.r1 — `depreciation_buildings_2_5pct`: Budynki niemieszkalne → 2.5% (40 lat)
else :=   {"matched":true,"rule_id":"jdg.pit.a22g.r1","package":"jdg.micro.pit.plan34","priority":2201,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Budynki niemieszkalne","_legal_basis":"Art. 22g PIT — Budynki, budowle, maszyny (stawki amortyzacji)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22i.r1 — `depreciation_moment_start_next_month`: Od następnego miesiąca po przyjęciu → Moment rozpoczęcia
else :=   {"matched":true,"rule_id":"jdg.pit.a22i.r1","package":"jdg.micro.pit.plan34","priority":2201,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Od następnego miesiąca po przyjęciu","_legal_basis":"Art. 22i PIT — Moment rozpoczęcia/zakończenia amortyzacji","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22j.r1 — `depreciation_improvement_upgrade`: Ulepszenie >10k PLN → Podwyższenie wartości
else :=   {"matched":true,"rule_id":"jdg.pit.a22j.r1","package":"jdg.micro.pit.plan34","priority":2201,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulepszenie >10k PLN","_legal_basis":"Art. 22j PIT — Ulepszenia środków trwałych","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22k.r1 — `depreciation_sale_tax_consequences`: Sprzedaż ŚT → przychód → Skutki podatkowe
else :=   {"matched":true,"rule_id":"jdg.pit.a22k.r1","package":"jdg.micro.pit.plan34","priority":2201,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprzedaż ŚT → przychód","_legal_basis":"Art. 22k PIT — Sprzedaż i likwidacja środków trwałych","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22l.r1 — `depreciation_intangibles_wnip`: Licencje, patenty, know-how → Definicja WNiP
else :=   {"matched":true,"rule_id":"jdg.pit.a22l.r1","package":"jdg.micro.pit.plan34","priority":2201,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Licencje, patenty, know-how","_legal_basis":"Art. 22l PIT — Wartości niematerialne i prawne","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22f.r1 — `depreciation_used_property_60_months`: Używane ŚT — amortyzacja indywidualna min 60 mies. → Min. okres
else :=   {"matched":true,"rule_id":"jdg.pit.a22f.r1","package":"jdg.micro.pit.plan34","priority":2201,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Używane ŚT — amortyzacja indywidualna min 60 mies.","_legal_basis":"Art. 22f PIT — Używane środki trwałe","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22m.r1 — `depreciation_private_car_transfer`: Przeniesienie auta prywatnego do firmy → wartość rynkowa → Wycena
else :=   {"matched":true,"rule_id":"jdg.pit.a22m.r1","package":"jdg.micro.pit.plan34","priority":2201,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przeniesienie auta prywatnego do firmy → wartość rynkowa","_legal_basis":"Art. 22m PIT — Samochody osobowe (limit 150k/225k)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a22a.r2 — `depreciation_excluded_land`: Grunt → NIE amortyzacja → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a22a.r2","package":"jdg.micro.pit.plan34","priority":2202,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Grunt → NIE amortyzacja","_legal_basis":"Art. 22a PIT — Środki trwałe, wartości niematerialne i prawne","_warnings":[]} {
    object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22m.r2 — `depreciation_private_car_limit_150k`: Auto osobowe → limit 150k → Limit wyceny
else :=   {"matched":true,"rule_id":"jdg.pit.a22m.r2","package":"jdg.micro.pit.plan34","priority":2202,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Auto osobowe → limit 150k","_legal_basis":"Art. 22m PIT — Samochody osobowe (limit 150k/225k)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a22d.r2 — `depreciation_method_declining`: Metoda degresywna — wyższe odpisy na początku (dla maszyn) → Opcja
else :=   {"matched":true,"rule_id":"jdg.pit.a22d.r2","package":"jdg.micro.pit.plan34","priority":2202,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Metoda degresywna — wyższe odpisy na początku (dla maszyn)","_legal_basis":"Art. 22d PIT — Metody amortyzacji (liniowa, degresywna)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22e.r2 — `depreciation_low_value_deadline`: Odpis jednorazowy w miesiącu oddania do używania → Termin
else :=   {"matched":true,"rule_id":"jdg.pit.a22e.r2","package":"jdg.micro.pit.plan34","priority":2202,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odpis jednorazowy w miesiącu oddania do używania","_legal_basis":"Art. 22e PIT — Mała wartość (jednorazowa amortyzacja)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22g.r2 — `depreciation_buildings_residential_1_5`: Budynki mieszkalne firmowe — 1.5% (67 lat) → Stawka
else :=   {"matched":true,"rule_id":"jdg.pit.a22g.r2","package":"jdg.micro.pit.plan34","priority":2202,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Budynki mieszkalne firmowe — 1.5% (67 lat)","_legal_basis":"Art. 22g PIT — Budynki, budowle, maszyny (stawki amortyzacji)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22i.r2 — `depreciation_moment_stop_disposal`: Zaprzestanie odpisów po likwidacji/sprzedaży → Moment zakończenia
else :=   {"matched":true,"rule_id":"jdg.pit.a22i.r2","package":"jdg.micro.pit.plan34","priority":2202,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaprzestanie odpisów po likwidacji/sprzedaży","_legal_basis":"Art. 22i PIT — Moment rozpoczęcia/zakończenia amortyzacji","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22j.r2 — `depreciation_improvement_new_rate`: Po ulepszeniu — nowa stawka od podwyższonej wartości → Nowa stawka
else :=   {"matched":true,"rule_id":"jdg.pit.a22j.r2","package":"jdg.micro.pit.plan34","priority":2202,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Po ulepszeniu — nowa stawka od podwyższonej wartości","_legal_basis":"Art. 22j PIT — Ulepszenia środków trwałych","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22k.r2 — `depreciation_liquidation_loss`: Likwidacja ŚT → strata z likwidacji (NKUP, chyba że przyczyny gospodarcze) → Strata
else :=   {"matched":true,"rule_id":"jdg.pit.a22k.r2","package":"jdg.micro.pit.plan34","priority":2202,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Likwidacja ŚT → strata z likwidacji (NKUP, chyba że przyczyny gospodarcze)","_legal_basis":"Art. 22k PIT — Sprzedaż i likwidacja środków trwałych","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true; object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22l.r2 — `depreciation_wnip_license_5_years`: Licencje na programy komputerowe — 5 lat → Okres
else :=   {"matched":true,"rule_id":"jdg.pit.a22l.r2","package":"jdg.micro.pit.plan34","priority":2202,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Licencje na programy komputerowe — 5 lat","_legal_basis":"Art. 22l PIT — Wartości niematerialne i prawne","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22.r3 — `kup_indirect_timing_invoice`: Koszty pośrednie → data faktury → Data poniesienia
else :=   {"matched":true,"rule_id":"jdg.pit.a22.r3","package":"jdg.micro.pit.plan34","priority":2203,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszty pośrednie → data faktury","_legal_basis":"Art. 22 PIT — Koszty uzyskania przychodów","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a22d.r3 — `depreciation_method_one_time_under_10k`: Do 10 000 PLN jednorazowo → Opcja uproszczona
else :=   {"matched":true,"rule_id":"jdg.pit.a22d.r3","package":"jdg.micro.pit.plan34","priority":2203,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Do 10 000 PLN jednorazowo","_legal_basis":"Art. 22d PIT — Metody amortyzacji (liniowa, degresywna)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22m.r3 — `depreciation_electric_car_limit_225k`: Elektryczne → limit 225k → Limit EV
else :=   {"matched":true,"rule_id":"jdg.pit.a22m.r3","package":"jdg.micro.pit.plan34","priority":2203,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Elektryczne → limit 225k","_legal_basis":"Art. 22m PIT — Samochody osobowe (limit 150k/225k)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true; object.get(input.invoice, "category_code", "") == "CAR"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a22a.r3 — `depreciation_excluded_living_buildings`: Budynki mieszkalne (nie-firmowe) → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a22a.r3","package":"jdg.micro.pit.plan34","priority":2203,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Budynki mieszkalne (nie-firmowe)","_legal_basis":"Art. 22a PIT — Środki trwałe, wartości niematerialne i prawne","_warnings":[]} {
    object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22g.r3 — `depreciation_machinery_10_30pct`: Maszyny i urządzenia — 10-30% wg KŚT → Stawka
else :=   {"matched":true,"rule_id":"jdg.pit.a22g.r3","package":"jdg.micro.pit.plan34","priority":2203,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Maszyny i urządzenia — 10-30% wg KŚT","_legal_basis":"Art. 22g PIT — Budynki, budowle, maszyny (stawki amortyzacji)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22i.r3 — `depreciation_partial_year_pro_rata`: W roku przyjęcia — odpis za miesiące od przyjęcia do końca roku → Pro rata
else :=   {"matched":true,"rule_id":"jdg.pit.a22i.r3","package":"jdg.micro.pit.plan34","priority":2203,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"W roku przyjęcia — odpis za miesiące od przyjęcia do końca roku","_legal_basis":"Art. 22i PIT — Moment rozpoczęcia/zakończenia amortyzacji","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22k.r3 — `depreciation_liquidation_business_reasons`: Likwidacja z przyczyn gospodarczych → KUP (strata) → KUP
else :=   {"matched":true,"rule_id":"jdg.pit.a22k.r3","package":"jdg.micro.pit.plan34","priority":2203,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Likwidacja z przyczyn gospodarczych → KUP (strata)","_legal_basis":"Art. 22k PIT — Sprzedaż i likwidacja środków trwałych","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true; object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22l.r3 — `depreciation_wnip_patent_5_years`: Patenty, znaki towarowe — 5 lat → Okres
else :=   {"matched":true,"rule_id":"jdg.pit.a22l.r3","package":"jdg.micro.pit.plan34","priority":2203,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Patenty, znaki towarowe — 5 lat","_legal_basis":"Art. 22l PIT — Wartości niematerialne i prawne","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22.r4 — `kup_direct_timing_revenue_year`: Koszty bezpośrednie → rok odpowiadającego przychodu → Rok przychodu
else :=   {"matched":true,"rule_id":"jdg.pit.a22.r4","package":"jdg.micro.pit.plan34","priority":2204,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszty bezpośrednie → rok odpowiadającego przychodu","_legal_basis":"Art. 22 PIT — Koszty uzyskania przychodów","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a22g.r4 — `depreciation_computers_30pct`: Komputery, oprogramowanie → 30%
else :=   {"matched":true,"rule_id":"jdg.pit.a22g.r4","package":"jdg.micro.pit.plan34","priority":2204,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Komputery, oprogramowanie","_legal_basis":"Art. 22g PIT — Budynki, budowle, maszyny (stawki amortyzacji)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22m.r4 — `depreciation_firm_car_tax_consequences`: Auto mieszane → 75% KUP → 75% KUP
else :=   {"matched":true,"rule_id":"jdg.pit.a22m.r4","package":"jdg.micro.pit.plan34","priority":2204,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Auto mieszane → 75% KUP","_legal_basis":"Art. 22m PIT — Samochody osobowe (limit 150k/225k)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "is_fixed_asset", false) == true; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a22a.r4 — `depreciation_excluded_goodwill`: Wartość firmy (goodwill) → NIE amortyzowany w PIT
else :=   {"matched":true,"rule_id":"jdg.pit.a22a.r4","package":"jdg.micro.pit.plan34","priority":2204,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wartość firmy (goodwill)","_legal_basis":"Art. 22a PIT — Środki trwałe, wartości niematerialne i prawne","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22d.r4 — `depreciation_rate_standard_table`: Stawka z Wykazu stawek amortyzacyjnych KŚT → Stawka standardowa
else :=   {"matched":true,"rule_id":"jdg.pit.a22d.r4","package":"jdg.micro.pit.plan34","priority":2204,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawka z Wykazu stawek amortyzacyjnych KŚT","_legal_basis":"Art. 22d PIT — Metody amortyzacji (liniowa, degresywna)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22l.r4 — `depreciation_wnip_goodwill_5_years`: Wartość firmy — 5 lat → Okres
else :=   {"matched":true,"rule_id":"jdg.pit.a22l.r4","package":"jdg.micro.pit.plan34","priority":2204,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wartość firmy — 5 lat","_legal_basis":"Art. 22l PIT — Wartości niematerialne i prawne","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22g.r5 — `depreciation_vehicles_20pct`: Samochody → 20%
else :=   {"matched":true,"rule_id":"jdg.pit.a22g.r5","package":"jdg.micro.pit.plan34","priority":2205,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Samochody","_legal_basis":"Art. 22g PIT — Budynki, budowle, maszyny (stawki amortyzacji)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22d.r5 — `depreciation_rate_individual`: Indywidualna stawka dla używanych/ulepszonych ŚT → Opcja
else :=   {"matched":true,"rule_id":"jdg.pit.a22d.r5","package":"jdg.micro.pit.plan34","priority":2205,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Indywidualna stawka dla używanych/ulepszonych ŚT","_legal_basis":"Art. 22d PIT — Metody amortyzacji (liniowa, degresywna)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22l.r5 — `depreciation_wnip_low_10k_one_time`: WNiP do 10 000 PLN → jednorazowo w KUP → Jednorazowo
else :=   {"matched":true,"rule_id":"jdg.pit.a22l.r5","package":"jdg.micro.pit.plan34","priority":2205,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WNiP do 10 000 PLN → jednorazowo w KUP","_legal_basis":"Art. 22l PIT — Wartości niematerialne i prawne","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22m.r5 — `depreciation_firm_car_mileage_log_100pct`: Ewidencja przebiegu → 100% KUP od amortyzacji → 100% KUP
else :=   {"matched":true,"rule_id":"jdg.pit.a22m.r5","package":"jdg.micro.pit.plan34","priority":2205,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ewidencja przebiegu → 100% KUP od amortyzacji","_legal_basis":"Art. 22m PIT — Samochody osobowe (limit 150k/225k)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "is_fixed_asset", false) == true; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a22.r6 — `kup_zus_social_entrepreneur`: Składki ZUS społeczne opłacone → KUP → Data zapłaty
else :=   {"matched":true,"rule_id":"jdg.pit.a22.r6","package":"jdg.micro.pit.plan34","priority":2206,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Składki ZUS społeczne opłacone → KUP","_legal_basis":"Art. 22 PIT — Koszty uzyskania przychodów","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a22d.r6 — `depreciation_rate_increased_1_4`: Współczynnik 1.4 dla maszyn w warunkach szkodliwych → Podwyższenie
else :=   {"matched":true,"rule_id":"jdg.pit.a22d.r6","package":"jdg.micro.pit.plan34","priority":2206,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Współczynnik 1.4 dla maszyn w warunkach szkodliwych","_legal_basis":"Art. 22d PIT — Metody amortyzacji (liniowa, degresywna)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22g.r6 — `depreciation_furniture_20pct`: Meble, wyposażenie — 20% → Stawka
else :=   {"matched":true,"rule_id":"jdg.pit.a22g.r6","package":"jdg.micro.pit.plan34","priority":2206,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Meble, wyposażenie — 20%","_legal_basis":"Art. 22g PIT — Budynki, budowle, maszyny (stawki amortyzacji)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22m.r6 — `depreciation_firm_car_no_log_75pct`: Brak ewidencji → 75% KUP od amortyzacji → 75% KUP
else :=   {"matched":true,"rule_id":"jdg.pit.a22m.r6","package":"jdg.micro.pit.plan34","priority":2206,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak ewidencji → 75% KUP od amortyzacji","_legal_basis":"Art. 22m PIT — Samochody osobowe (limit 150k/225k)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "is_fixed_asset", false) == true; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a22.r7 — `kup_zus_social_unpaid_block`: Niezapłacone składki ZUS → NIE KUP → Blokada
else :=   {"matched":true,"rule_id":"jdg.pit.a22.r7","package":"jdg.micro.pit.plan34","priority":2207,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niezapłacone składki ZUS → NIE KUP","_legal_basis":"Art. 22 PIT — Koszty uzyskania przychodów","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a22d.r7 — `depreciation_rate_increased_2_0`: Współczynnik 2.0 dla maszyn w warunkach szczególnie szkodliwych → Podwyższenie
else :=   {"matched":true,"rule_id":"jdg.pit.a22d.r7","package":"jdg.micro.pit.plan34","priority":2207,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Współczynnik 2.0 dla maszyn w warunkach szczególnie szkodliwych","_legal_basis":"Art. 22d PIT — Metody amortyzacji (liniowa, degresywna)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22g.r7 — `depreciation_plant_equipment_10_20`: Urządzenia techniczne — 10-20% → Stawka
else :=   {"matched":true,"rule_id":"jdg.pit.a22g.r7","package":"jdg.micro.pit.plan34","priority":2207,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Urządzenia techniczne — 10-20%","_legal_basis":"Art. 22g PIT — Budynki, budowle, maszyny (stawki amortyzacji)","_warnings":[]} {
    object.get(input.invoice, "is_fixed_asset", false) == true
}

# jdg.pit.a22.r8 — `kup_unpaid_reversal`: Faktura nieopłacona >90 dni → OBOWIĄZKOWE wyłączenie → Koszty bezpośrednie
else :=   {"matched":true,"rule_id":"jdg.pit.a22.r8","package":"jdg.micro.pit.plan34","priority":2208,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura nieopłacona >90 dni → OBOWIĄZKOWE wyłączenie","_legal_basis":"Art. 22 PIT — Koszty uzyskania przychodów","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a22.r10 — `kup_unpaid_reversal_on_payment`: Zapłata po wyłączeniu → przywrócenie KUP → Odwrócenie
else :=   {"matched":true,"rule_id":"jdg.pit.a22.r10","package":"jdg.micro.pit.plan34","priority":2210,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zapłata po wyłączeniu → przywrócenie KUP","_legal_basis":"Art. 22 PIT — Koszty uzyskania przychodów","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a22.r12 — `kup_vat_not_deductible_as_cost`: VAT niepodlegający odliczeniu → może być KUP → KUP warunkowy
else :=   {"matched":true,"rule_id":"jdg.pit.a22.r12","package":"jdg.micro.pit.plan34","priority":2212,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"VAT niepodlegający odliczeniu → może być KUP","_legal_basis":"Art. 22 PIT — Koszty uzyskania przychodów","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a22.r13 — `kup_cost_of_purchase_of_goods`: Towary handlowe w cenie zakupu → Wycena kosztów
else :=   {"matched":true,"rule_id":"jdg.pit.a22.r13","package":"jdg.micro.pit.plan34","priority":2213,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Towary handlowe w cenie zakupu","_legal_basis":"Art. 22 PIT — Koszty uzyskania przychodów","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a22.r15 — `kup_loss_of_inventory`: Straty udokumentowane protokołem → KUP → KUP
else :=   {"matched":true,"rule_id":"jdg.pit.a22.r15","package":"jdg.micro.pit.plan34","priority":2215,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Straty udokumentowane protokołem → KUP","_legal_basis":"Art. 22 PIT — Koszty uzyskania przychodów","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true; object.get(input.jdg_entrepreneur, "uses_pkpir", false) == true
}

# jdg.pit.a23.r1 — `kup_exclusion_own_labor`: Wartość własnej pracy JDG → Art. 23 ust. 1 pkt 10
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r1","package":"jdg.micro.pit.plan34","priority":2301,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wartość własnej pracy JDG","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r2 — `kup_exclusion_spouse_minor_children`: Praca małżonka i dzieci (bez umowy) → Art. 23 ust. 1 pkt 10
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r2","package":"jdg.micro.pit.plan34","priority":2302,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Praca małżonka i dzieci (bez umowy)","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.vendor, "relation_to_entrepreneur", "") == "SPOUSE"; object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}

# jdg.pit.a23.r3 — `kup_exclusion_personal_living`: Cele osobiste, mieszkaniowe → Art. 23 ust. 1 pkt 10
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r3","package":"jdg.micro.pit.plan34","priority":2303,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Cele osobiste, mieszkaniowe","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r4 — `kup_exclusion_representation`: Reprezentacja, gastronomia, rozrywka → Art. 23 ust. 1 pkt 23
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r4","package":"jdg.micro.pit.plan34","priority":2304,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Reprezentacja, gastronomia, rozrywka","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "category_code", "") == "REPRESENTATION"
}

# jdg.pit.a23.r6 — `kup_exclusion_final_mandate`: Kary umowne, odszkodowania → Art. 23 ust. 1 pkt 19
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r6","package":"jdg.micro.pit.plan34","priority":2306,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kary umowne, odszkodowania","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r8 — `kup_exclusion_debts_forgiven`: Umorzone zobowiązania → Art. 23 ust. 1 pkt 20
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r8","package":"jdg.micro.pit.plan34","priority":2308,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umorzone zobowiązania","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r12 — `kup_exclusion_car_over_150k`: Auto >150k PLN → ograniczony KUP → Art. 23 ust. 1 pkt 47a
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r12","package":"jdg.micro.pit.plan34","priority":2312,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Auto >150k PLN → ograniczony KUP","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a23.r15 — `kup_exclusion_car_electric_225k`: Auto elektryczne → limit 225k PLN → Wyjątek
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r15","package":"jdg.micro.pit.plan34","priority":2315,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Auto elektryczne → limit 225k PLN","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "category_code", "") == "CAR"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a23.r17 — `kup_exclusion_mileage_log_absence`: Brak ewidencji → 75% KUP → Art. 23 ust. 1 pkt 46
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r17","package":"jdg.micro.pit.plan34","priority":2317,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak ewidencji → 75% KUP","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r21 — `kup_exclusion_tax_penalties`: Kary podatkowe, grzywny, mandaty → Art. 23 ust. 1 pkt 19
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r21","package":"jdg.micro.pit.plan34","priority":2321,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kary podatkowe, grzywny, mandaty","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r23 — `kup_exclusion_capital_investment`: Środki trwałe → amortyzacja → Art. 23 ust. 1 pkt 1
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r23","package":"jdg.micro.pit.plan34","priority":2323,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Środki trwałe → amortyzacja","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "is_fixed_asset", false) == true; object.get(input.invoice, "income_source", "") == "CAPITAL_GAINS"
}

# jdg.pit.a23.r24 — `kup_exclusion_land_purchase`: Zakup gruntu → NKUP → Art. 23 ust. 1 pkt 1
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r24","package":"jdg.micro.pit.plan34","priority":2324,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zakup gruntu → NKUP","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r26 — `kup_exclusion_self_education`: Własne kształcenie → NKUP (chyba że związane) → Art. 23 ust. 1 pkt 10
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r26","package":"jdg.micro.pit.plan34","priority":2326,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Własne kształcenie → NKUP (chyba że związane)","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r27 — `kup_exclusion_self_education_related`: Kształcenie związane z działalnością → KUP → Wyjątek
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r27","package":"jdg.micro.pit.plan34","priority":2327,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kształcenie związane z działalnością → KUP","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r28 — `kup_exclusion_tax_costs`: Podatek dochodowy → NKUP → Art. 23 ust. 1 pkt 4
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r28","package":"jdg.micro.pit.plan34","priority":2328,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatek dochodowy → NKUP","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r29 — `kup_exclusion_fines_state`: Grzywny państwowe → NKUP → Art. 23 ust. 1 pkt 5
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r29","package":"jdg.micro.pit.plan34","priority":2329,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Grzywny państwowe → NKUP","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r30 — `kup_exclusion_lost_unreported`: Straty nieudokumentowane → NKUP → Art. 23 ust. 1 pkt 5
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r30","package":"jdg.micro.pit.plan34","priority":2330,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Straty nieudokumentowane → NKUP","_legal_basis":"Art. 23 PIT — Wydatki nieuznawane za koszty uzyskania przychodów (NKUP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a24.r1 — `income_definition_revenue_minus_costs`: Dochód = przychód - KUP → Definicja
else :=   {"matched":true,"rule_id":"jdg.pit.a24.r1","package":"jdg.micro.pit.plan34","priority":2401,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochód = przychód - KUP","_legal_basis":"Art. 24 PIT — Dochód","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a24.r2 — `income_negative_loss`: Dochód ujemny = strata → Strata
else :=   {"matched":true,"rule_id":"jdg.pit.a24.r2","package":"jdg.micro.pit.plan34","priority":2402,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochód ujemny = strata","_legal_basis":"Art. 24 PIT — Dochód","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true
}

# jdg.pit.a24.r3 — `income_loss_carry_forward_5_years`: Strata rozliczana w 5 kolejnych lat → Rozliczenie straty
else :=   {"matched":true,"rule_id":"jdg.pit.a24.r3","package":"jdg.micro.pit.plan34","priority":2403,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Strata rozliczana w 5 kolejnych lat","_legal_basis":"Art. 24 PIT — Dochód","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a24.r4 — `income_loss_max_50pct_annually`: Max 50% straty rocznie → Limit roczny
else :=   {"matched":true,"rule_id":"jdg.pit.a24.r4","package":"jdg.micro.pit.plan34","priority":2404,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Max 50% straty rocznie","_legal_basis":"Art. 24 PIT — Dochód","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true
}

# jdg.pit.a24.r5 — `income_loss_one_time_5m`: Opcja: jednorazowo do 5M PLN → Alternatywa
else :=   {"matched":true,"rule_id":"jdg.pit.a24.r5","package":"jdg.micro.pit.plan34","priority":2405,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Opcja: jednorazowo do 5M PLN","_legal_basis":"Art. 24 PIT — Dochód","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true
}

# jdg.pit.a24.r6 — `income_loss_only_scale_linear`: TYLKO skala i liniowy → Zakres
else :=   {"matched":true,"rule_id":"jdg.pit.a24.r6","package":"jdg.micro.pit.plan34","priority":2406,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"TYLKO skala i liniowy","_legal_basis":"Art. 24 PIT — Dochód","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true
}

# jdg.pit.a24.r7 — `income_loss_not_available_lump_sum`: Ryczałt i karta → NIE → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a24.r7","package":"jdg.micro.pit.plan34","priority":2407,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczałt i karta → NIE","_legal_basis":"Art. 24 PIT — Dochód","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true
}

# jdg.pit.a24.r8 — `income_inventory_adjustment`: Różnica remanentu końcowego i początkowego koryguje dochód → Korekta remanentem
else :=   {"matched":true,"rule_id":"jdg.pit.a24.r8","package":"jdg.micro.pit.plan34","priority":2408,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Różnica remanentu końcowego i początkowego koryguje dochód","_legal_basis":"Art. 24 PIT — Dochód","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "uses_pkpir", false) == true
}

# jdg.pit.a24.r9 — `income_inventory_positive_increase`: Remanent końcowy > początkowy → Zwiększa dochód
else :=   {"matched":true,"rule_id":"jdg.pit.a24.r9","package":"jdg.micro.pit.plan34","priority":2409,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Remanent końcowy > początkowy","_legal_basis":"Art. 24 PIT — Dochód","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "uses_pkpir", false) == true
}

# jdg.pit.a24.r10 — `income_inventory_negative_decrease`: Remanent końcowy < początkowy → Zmniejsza dochód
else :=   {"matched":true,"rule_id":"jdg.pit.a24.r10","package":"jdg.micro.pit.plan34","priority":2410,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Remanent końcowy < początkowy","_legal_basis":"Art. 24 PIT — Dochód","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "uses_pkpir", false) == true
}

# jdg.pit.a24.r11 — `income_balance_sheet_comparison`: Dochód JDG na PKPiR = różnica przychodów i wydatków + różnica remanentów → Obliczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a24.r11","package":"jdg.micro.pit.plan34","priority":2411,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochód JDG na PKPiR = różnica przychodów i wydatków + różnica remanentów","_legal_basis":"Art. 24 PIT — Dochód","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "uses_pkpir", false) == true
}

# jdg.pit.a24.r12 — `income_source_separation`: Dochód z działalności nie łączy się z innymi źródłami → Odrębność
else :=   {"matched":true,"rule_id":"jdg.pit.a24.r12","package":"jdg.micro.pit.plan34","priority":2412,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochód z działalności nie łączy się z innymi źródłami","_legal_basis":"Art. 24 PIT — Dochód","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a24.r13 — `income_source_aggregation_scale`: Dla skali podatkowej: dochód z JDG + dochód z innych źródeł = łączny dochód → Łączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a24.r13","package":"jdg.micro.pit.plan34","priority":2413,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dla skali podatkowej: dochód z JDG + dochód z innych źródeł = łączny dochód","_legal_basis":"Art. 24 PIT — Dochód","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a24.r14 — `income_averaging_not_available_jdg`: Przeciętowanie dochodów — tylko dla twórców i artystów → Ograniczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a24.r14","package":"jdg.micro.pit.plan34","priority":2414,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przeciętowanie dochodów — tylko dla twórców i artystów","_legal_basis":"Art. 24 PIT — Dochód","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a24.r15 — `income_tax_free_amount_scale_only`: Kwota wolna 30k → TYLKO skala → Kwota wolna
else :=   {"matched":true,"rule_id":"jdg.pit.a24.r15","package":"jdg.micro.pit.plan34","priority":2415,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kwota wolna 30k → TYLKO skala","_legal_basis":"Art. 24 PIT — Dochód","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; input.jdg_entrepreneur.tax_form == "PIT_SCALE"
}

# jdg.pit.a26.r1 — `relief_zus_social_contributions`: Składki ZUS społeczne → Brak limitu
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r1","package":"jdg.micro.pit.plan34","priority":2601,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Składki ZUS społeczne","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26e.r1 — `rd_status_verification`: Status B+R faktycznie prowadzony → Warunek dostępu
else :=   {"matched":true,"rule_id":"jdg.pit.a26e.r1","package":"jdg.micro.pit.plan34","priority":2601,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Status B+R faktycznie prowadzony","_legal_basis":"Art. 26e PIT — Ulga B+R (100-200% kosztów)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a26eb.r1 — `relief_prototype_30pct`: Ulga na prototyp → 30% kosztów
else :=   {"matched":true,"rule_id":"jdg.pit.a26eb.r1","package":"jdg.micro.pit.plan34","priority":2601,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga na prototyp","_legal_basis":"Art. 26eb PIT — Ulga na prototyp (30% kosztów)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26ec.r1 — `relief_expansion_100pct`: Ulga na ekspansję → 1 000 000 PLN
else :=   {"matched":true,"rule_id":"jdg.pit.a26ec.r1","package":"jdg.micro.pit.plan34","priority":2601,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga na ekspansję","_legal_basis":"Art. 26ec PIT — Ulga na ekspansję (do 1M PLN)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26gb.r1 — `relief_robotization_50pct`: Ulga na robotyzację → 50% kosztów
else :=   {"matched":true,"rule_id":"jdg.pit.a26gb.r1","package":"jdg.micro.pit.plan34","priority":2601,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga na robotyzację","_legal_basis":"Art. 26gb PIT — Ulga na robotyzację (50% kosztów)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26h.r1 — `relief_thermo_53k`: Ulga termomodernizacyjna → 53 000 PLN
else :=   {"matched":true,"rule_id":"jdg.pit.a26h.r1","package":"jdg.micro.pit.plan34","priority":2601,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga termomodernizacyjna","_legal_basis":"Art. 26h PIT — Ulga termomodernizacyjna (do 53 000 PLN)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26b.r1 — `ikze_eligibility`: Posiadanie rachunku IKZE (umowa z instytucją finansową) → Odliczenie od dochodu
else :=   {"matched":true,"rule_id":"jdg.pit.a26b.r1","package":"jdg.micro.pit.plan34","priority":2601,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Posiadanie rachunku IKZE (umowa z instytucją finansową)","_legal_basis":"Art. 26b PIT — Ulga B+R (koszty kwalifikowane)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a26ha.r1 — `csr_sponsoring_eligibility`: Wydatki na sport, kulturę, szkolnictwo wyższe lub naukę → Koszt kwalifikowany
else :=   {"matched":true,"rule_id":"jdg.pit.a26ha.r1","package":"jdg.micro.pit.plan34","priority":2601,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wydatki na sport, kulturę, szkolnictwo wyższe lub naukę","_legal_basis":"Art. 26ha PIT — Ulga termomodernizacyjna (rozszerzona)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a26hd.r1 — `payment_terminal_eligibility`: Nabycie terminala płatniczego + opłaty za obsługę → Koszt kwalifikowany
else :=   {"matched":true,"rule_id":"jdg.pit.a26hd.r1","package":"jdg.micro.pit.plan34","priority":2601,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nabycie terminala płatniczego + opłaty za obsługę","_legal_basis":"Art. 26hd PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a26i.r1 — `bad_debt_pit_creditor_90_days`: Wierzytelność nieuregulowana >90 dni od terminu płatności → Prawo do pomniejszenia dochodu
else :=   {"matched":true,"rule_id":"jdg.pit.a26i.r1","package":"jdg.micro.pit.plan34","priority":2601,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wierzytelność nieuregulowana >90 dni od terminu płatności","_legal_basis":"Art. 26i PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a26.r2 — `relief_rehabilitation`: Ulga rehabilitacyjna → 2 280 PLN
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r2","package":"jdg.micro.pit.plan34","priority":2602,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga rehabilitacyjna","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26e.r2 — `rd_qualifying_costs_salaries`: Wynagrodzenia pracowników B+R → Koszt kwalifikowany
else :=   {"matched":true,"rule_id":"jdg.pit.a26e.r2","package":"jdg.micro.pit.plan34","priority":2602,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wynagrodzenia pracowników B+R","_legal_basis":"Art. 26e PIT — Ulga B+R (100-200% kosztów)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a26eb.r2 — `relief_prototype_qualifying_costs`: Koszty kwalifikowane: produkcja próbna, certyfikacja, badania → Katalog kosztów
else :=   {"matched":true,"rule_id":"jdg.pit.a26eb.r2","package":"jdg.micro.pit.plan34","priority":2602,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszty kwalifikowane: produkcja próbna, certyfikacja, badania","_legal_basis":"Art. 26eb PIT — Ulga na prototyp (30% kosztów)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26ec.r2 — `relief_expansion_qualifying_costs`: Koszty kwalifikowane: targi, misje, reklama, przystosowanie opakowań → Katalog kosztów
else :=   {"matched":true,"rule_id":"jdg.pit.a26ec.r2","package":"jdg.micro.pit.plan34","priority":2602,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszty kwalifikowane: targi, misje, reklama, przystosowanie opakowań","_legal_basis":"Art. 26ec PIT — Ulga na ekspansję (do 1M PLN)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26gb.r2 — `relief_robotization_qualifying`: Koszty kwalifikowane: robot, oprogramowanie, szkolenia, instalacja → Katalog
else :=   {"matched":true,"rule_id":"jdg.pit.a26gb.r2","package":"jdg.micro.pit.plan34","priority":2602,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszty kwalifikowane: robot, oprogramowanie, szkolenia, instalacja","_legal_basis":"Art. 26gb PIT — Ulga na robotyzację (50% kosztów)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26h.r2 — `relief_thermo_qualifying_works`: Roboty: ocieplenie, okna, drzwi, ogrzewanie, wentylacja, OZE → Katalog robót
else :=   {"matched":true,"rule_id":"jdg.pit.a26h.r2","package":"jdg.micro.pit.plan34","priority":2602,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roboty: ocieplenie, okna, drzwi, ogrzewanie, wentylacja, OZE","_legal_basis":"Art. 26h PIT — Ulga termomodernizacyjna (do 53 000 PLN)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26b.r2 — `ikze_limit_entrepreneur_2024`: JDG — limit wpłat 2024: 14 083,20 PLN → Limit podwyższony
else :=   {"matched":true,"rule_id":"jdg.pit.a26b.r2","package":"jdg.micro.pit.plan34","priority":2602,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG — limit wpłat 2024: 14 083,20 PLN","_legal_basis":"Art. 26b PIT — Ulga B+R (koszty kwalifikowane)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a26ha.r2 — `csr_sponsoring_50pct_additional`: Dodatkowe 50% kosztów ponad standardowe KUP (łącznie 150%) → 50% dodatkowo
else :=   {"matched":true,"rule_id":"jdg.pit.a26ha.r2","package":"jdg.micro.pit.plan34","priority":2602,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dodatkowe 50% kosztów ponad standardowe KUP (łącznie 150%)","_legal_basis":"Art. 26ha PIT — Ulga termomodernizacyjna (rozszerzona)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a26hd.r2 — `payment_terminal_200pct_deduction`: Odliczenie 200% poniesionych wydatków (2× koszt) → 200%
else :=   {"matched":true,"rule_id":"jdg.pit.a26hd.r2","package":"jdg.micro.pit.plan34","priority":2602,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie 200% poniesionych wydatków (2× koszt)","_legal_basis":"Art. 26hd PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a26i.r2 — `bad_debt_pit_creditor_in_revenue`: Wierzytelność uprzednio zaliczona do przychodów (memoriałowo) → Warunek konieczny
else :=   {"matched":true,"rule_id":"jdg.pit.a26i.r2","package":"jdg.micro.pit.plan34","priority":2602,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wierzytelność uprzednio zaliczona do przychodów (memoriałowo)","_legal_basis":"Art. 26i PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a26e.r3 — `rd_qualifying_costs_equipment`: Sprzęt specjalistyczny B+R → Koszt kwalifikowany
else :=   {"matched":true,"rule_id":"jdg.pit.a26e.r3","package":"jdg.micro.pit.plan34","priority":2603,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprzęt specjalistyczny B+R","_legal_basis":"Art. 26e PIT — Ulga B+R (100-200% kosztów)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a26.r3 — `relief_rehabilitation_car`: Wydatki na przystosowanie samochodu do niepełnosprawności → Wymagane orzeczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r3","package":"jdg.micro.pit.plan34","priority":2603,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wydatki na przystosowanie samochodu do niepełnosprawności","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a26eb.r3 — `relief_prototype_documentation`: Wymóg dokumentacji: opis prototypu, kosztorys, harmonogram → Warunek formalny
else :=   {"matched":true,"rule_id":"jdg.pit.a26eb.r3","package":"jdg.micro.pit.plan34","priority":2603,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wymóg dokumentacji: opis prototypu, kosztorys, harmonogram","_legal_basis":"Art. 26eb PIT — Ulga na prototyp (30% kosztów)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26ec.r3 — `relief_expansion_market_definition`: Rynek zagraniczny — kraj inny niż Polska → Definicja
else :=   {"matched":true,"rule_id":"jdg.pit.a26ec.r3","package":"jdg.micro.pit.plan34","priority":2603,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rynek zagraniczny — kraj inny niż Polska","_legal_basis":"Art. 26ec PIT — Ulga na ekspansję (do 1M PLN)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26gb.r3 — `relief_robotization_evidence`: Wymóg ewidencji: robot musi być środkiem trwałym → Warunek
else :=   {"matched":true,"rule_id":"jdg.pit.a26gb.r3","package":"jdg.micro.pit.plan34","priority":2603,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wymóg ewidencji: robot musi być środkiem trwałym","_legal_basis":"Art. 26gb PIT — Ulga na robotyzację (50% kosztów)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a26h.r3 — `relief_thermo_owner_or_co_owner`: Ulga przysługuje właścicielowi/współwłaścicielowi budynku → Podmiot
else :=   {"matched":true,"rule_id":"jdg.pit.a26h.r3","package":"jdg.micro.pit.plan34","priority":2603,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga przysługuje właścicielowi/współwłaścicielowi budynku","_legal_basis":"Art. 26h PIT — Ulga termomodernizacyjna (do 53 000 PLN)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26b.r3 — `ikze_limit_entrepreneur_2025`: JDG — limit wpłat 2025: 15 611,40 PLN → Limit indeksowany
else :=   {"matched":true,"rule_id":"jdg.pit.a26b.r3","package":"jdg.micro.pit.plan34","priority":2603,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG — limit wpłat 2025: 15 611,40 PLN","_legal_basis":"Art. 26b PIT — Ulga B+R (koszty kwalifikowane)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a26ha.r3 — `csr_sponsoring_capped_at_income`: Suma odliczenia ≤ dochód z pozarolniczej działalności gospodarczej → Limit
else :=   {"matched":true,"rule_id":"jdg.pit.a26ha.r3","package":"jdg.micro.pit.plan34","priority":2603,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Suma odliczenia ≤ dochód z pozarolniczej działalności gospodarczej","_legal_basis":"Art. 26ha PIT — Ulga termomodernizacyjna (rozszerzona)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a26hd.r3 — `payment_terminal_limit_2500_exempt`: Podatnik zwolniony z kasy fiskalnej → limit 2 500 PLN/rok → Wyższy limit
else :=   {"matched":true,"rule_id":"jdg.pit.a26hd.r3","package":"jdg.micro.pit.plan34","priority":2603,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatnik zwolniony z kasy fiskalnej → limit 2 500 PLN/rok","_legal_basis":"Art. 26hd PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a26i.r3 — `bad_debt_pit_creditor_not_sold`: Wierzytelność nie została zbyta (sprzedana, wniesiona aportem) → Warunek
else :=   {"matched":true,"rule_id":"jdg.pit.a26i.r3","package":"jdg.micro.pit.plan34","priority":2603,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wierzytelność nie została zbyta (sprzedana, wniesiona aportem)","_legal_basis":"Art. 26i PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a26e.r4 — `rd_qualifying_costs_materials`: Materiały i surowce B+R → Koszt kwalifikowany
else :=   {"matched":true,"rule_id":"jdg.pit.a26e.r4","package":"jdg.micro.pit.plan34","priority":2604,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Materiały i surowce B+R","_legal_basis":"Art. 26e PIT — Ulga B+R (100-200% kosztów)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a26h.r4 — `relief_thermo_certificate`: Wymóg audytu energetycznego → Warunek formalny
else :=   {"matched":true,"rule_id":"jdg.pit.a26h.r4","package":"jdg.micro.pit.plan34","priority":2604,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wymóg audytu energetycznego","_legal_basis":"Art. 26h PIT — Ulga termomodernizacyjna (do 53 000 PLN)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26.r4 — `relief_rehabilitation_home`: Przebudowa domu/mieszkania dla osoby niepełnosprawnej → Wymagane orzeczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r4","package":"jdg.micro.pit.plan34","priority":2604,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przebudowa domu/mieszkania dla osoby niepełnosprawnej","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26b.r4 — `ikze_limit_entrepreneur_2026`: JDG — limit wpłat 2026: 16 956,00 PLN → Limit indeksowany
else :=   {"matched":true,"rule_id":"jdg.pit.a26b.r4","package":"jdg.micro.pit.plan34","priority":2604,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG — limit wpłat 2026: 16 956,00 PLN","_legal_basis":"Art. 26b PIT — Ulga B+R (koszty kwalifikowane)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a26eb.r4 — `innovative_employee_pit4_reduction`: Pomniejszenie zaliczki PIT-4 od wynagrodzenia pracownika B+R → Redukcja PIT-4
else :=   {"matched":true,"rule_id":"jdg.pit.a26eb.r4","package":"jdg.micro.pit.plan34","priority":2604,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pomniejszenie zaliczki PIT-4 od wynagrodzenia pracownika B+R","_legal_basis":"Art. 26eb PIT — Ulga na prototyp (30% kosztów)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a26ha.r4 — `csr_sponsoring_cost_must_be_kup`: Wydatek musi być uprzednio zaliczony do KUP → Warunek formalny
else :=   {"matched":true,"rule_id":"jdg.pit.a26ha.r4","package":"jdg.micro.pit.plan34","priority":2604,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wydatek musi być uprzednio zaliczony do KUP","_legal_basis":"Art. 26ha PIT — Ulga termomodernizacyjna (rozszerzona)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a26hd.r4 — `payment_terminal_limit_1000_others`: Pozostali podatnicy → limit 1 000 PLN/rok → Limit podstawowy
else :=   {"matched":true,"rule_id":"jdg.pit.a26hd.r4","package":"jdg.micro.pit.plan34","priority":2604,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pozostali podatnicy → limit 1 000 PLN/rok","_legal_basis":"Art. 26hd PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a26i.r4 — `bad_debt_pit_creditor_not_restructuring`: Dłużnik nie jest w restrukturyzacji ani upadłości → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a26i.r4","package":"jdg.micro.pit.plan34","priority":2604,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dłużnik nie jest w restrukturyzacji ani upadłości","_legal_basis":"Art. 26i PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a26e.r5 — `rd_qualifying_costs_expertise`: Ekspertyzy, opinie, usługi badawcze → Koszt kwalifikowany
else :=   {"matched":true,"rule_id":"jdg.pit.a26e.r5","package":"jdg.micro.pit.plan34","priority":2605,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ekspertyzy, opinie, usługi badawcze","_legal_basis":"Art. 26e PIT — Ulga B+R (100-200% kosztów)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a26.r5 — `relief_rehabilitation_equipment`: Zakup sprzętu rehabilitacyjnego, leki (ponad 100 PLN/mies.) → Wymagane orzeczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r5","package":"jdg.micro.pit.plan34","priority":2605,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zakup sprzętu rehabilitacyjnego, leki (ponad 100 PLN/mies.)","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26h.r5 — `relief_thermo_deadline_3_years`: Roboty muszą być zakończone w ciągu 3 lat od pierwszego wydatku → Termin
else :=   {"matched":true,"rule_id":"jdg.pit.a26h.r5","package":"jdg.micro.pit.plan34","priority":2605,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roboty muszą być zakończone w ciągu 3 lat od pierwszego wydatku","_legal_basis":"Art. 26h PIT — Ulga termomodernizacyjna (do 53 000 PLN)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26b.r5 — `ikze_annual_return_only`: Odliczenie TYLKO w zeznaniu rocznym PIT-36/PIT-36L (nie pomniejsza zaliczek!) → Roczne rozliczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a26b.r5","package":"jdg.micro.pit.plan34","priority":2605,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie TYLKO w zeznaniu rocznym PIT-36/PIT-36L (nie pomniejsza zaliczek!)","_legal_basis":"Art. 26b PIT — Ulga B+R (koszty kwalifikowane)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a26eb.r5 — `innovative_employee_monthly_limit`: Miesięczna redukcja ≤ kwota zaliczki PIT-4 danego pracownika → Limit miesięczny
else :=   {"matched":true,"rule_id":"jdg.pit.a26eb.r5","package":"jdg.micro.pit.plan34","priority":2605,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Miesięczna redukcja ≤ kwota zaliczki PIT-4 danego pracownika","_legal_basis":"Art. 26eb PIT — Ulga na prototyp (30% kosztów)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a26ha.r5 — `csr_sponsoring_documentation`: Wymóg dokumentacji: umowa sponsoringowa, faktury, dowody zapłaty → Dokumentacja
else :=   {"matched":true,"rule_id":"jdg.pit.a26ha.r5","package":"jdg.micro.pit.plan34","priority":2605,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wymóg dokumentacji: umowa sponsoringowa, faktury, dowody zapłaty","_legal_basis":"Art. 26ha PIT — Ulga termomodernizacyjna (rozszerzona)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a26hd.r5 — `payment_terminal_7_years_carry`: Niewykorzystana ulga → 6 kolejnych lat (łącznie 7 lat odliczania) → Carry-forward 6 lat
else :=   {"matched":true,"rule_id":"jdg.pit.a26hd.r5","package":"jdg.micro.pit.plan34","priority":2605,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niewykorzystana ulga → 6 kolejnych lat (łącznie 7 lat odliczania)","_legal_basis":"Art. 26hd PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a26i.r5 — `bad_debt_pit_creditor_reversal_on_payment`: Późniejsza zapłata → OBOWIĄZEK zwiększenia dochodu → Odwrócenie
else :=   {"matched":true,"rule_id":"jdg.pit.a26i.r5","package":"jdg.micro.pit.plan34","priority":2605,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Późniejsza zapłata → OBOWIĄZEK zwiększenia dochodu","_legal_basis":"Art. 26i PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a26.r6 — `relief_donation_opp_6pct`: Darowizny na OPP → Max 6% dochodu
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r6","package":"jdg.micro.pit.plan34","priority":2606,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Darowizny na OPP","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.invoice, "expense_type", "") == "DONATION"
}

# jdg.pit.a26e.r6 — `rd_qualifying_costs_patents`: Koszty uzyskania i utrzymania patentu → Koszt kwalifikowany
else :=   {"matched":true,"rule_id":"jdg.pit.a26e.r6","package":"jdg.micro.pit.plan34","priority":2606,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszty uzyskania i utrzymania patentu","_legal_basis":"Art. 26e PIT — Ulga B+R (100-200% kosztów)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a26b.r6 — `ikze_excess_not_carried`: Niewykorzystana nadwyżka limitu NIE przechodzi na kolejny rok → Przepadnięcie
else :=   {"matched":true,"rule_id":"jdg.pit.a26b.r6","package":"jdg.micro.pit.plan34","priority":2606,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niewykorzystana nadwyżka limitu NIE przechodzi na kolejny rok","_legal_basis":"Art. 26b PIT — Ulga B+R (koszty kwalifikowane)","_warnings":[]} {
    object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a26eb.r6 — `innovative_employee_evidence_required`: Wymóg prowadzenia ewidencji czasu pracy B+R dla każdego pracownika → Warunek formalny
else :=   {"matched":true,"rule_id":"jdg.pit.a26eb.r6","package":"jdg.micro.pit.plan34","priority":2606,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wymóg prowadzenia ewidencji czasu pracy B+R dla każdego pracownika","_legal_basis":"Art. 26eb PIT — Ulga na prototyp (30% kosztów)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a26hd.r6 — `payment_terminal_documentation`: Wymóg posiadania faktur i dowodów zapłaty za terminal i obsługę → Warunek formalny
else :=   {"matched":true,"rule_id":"jdg.pit.a26hd.r6","package":"jdg.micro.pit.plan34","priority":2606,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wymóg posiadania faktur i dowodów zapłaty za terminal i obsługę","_legal_basis":"Art. 26hd PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a26i.r6 — `bad_debt_pit_creditor_annual_return`: Pomniejszenie w rocznym zeznaniu PIT-36/PIT-36L → Roczne rozliczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a26i.r6","package":"jdg.micro.pit.plan34","priority":2606,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pomniejszenie w rocznym zeznaniu PIT-36/PIT-36L","_legal_basis":"Art. 26i PIT — Ulga podatkowa","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a26.r7 — `relief_donation_blood`: Krwiodawstwo — 130 PLN/litr → Brak % limitu
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r7","package":"jdg.micro.pit.plan34","priority":2607,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Krwiodawstwo — 130 PLN/litr","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.invoice, "expense_type", "") == "DONATION"; object.get(input.jdg_entrepreneur, "blood_donated_liters", 0) > 0
}

# jdg.pit.a26e.r7 — `rd_qualifying_costs_collective_bargaining`: Odpisy na fundusz innowacyjności → Koszt kwalifikowany
else :=   {"matched":true,"rule_id":"jdg.pit.a26e.r7","package":"jdg.micro.pit.plan34","priority":2607,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odpisy na fundusz innowacyjności","_legal_basis":"Art. 26e PIT — Ulga B+R (100-200% kosztów)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a26eb.r7 — `innovative_employee_scale_linear_only`: Ulga dostępna tylko dla skali i podatku liniowego (JDG jako pracodawca) → Zakres
else :=   {"matched":true,"rule_id":"jdg.pit.a26eb.r7","package":"jdg.micro.pit.plan34","priority":2607,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga dostępna tylko dla skali i podatku liniowego (JDG jako pracodawca)","_legal_basis":"Art. 26eb PIT — Ulga na prototyp (30% kosztów)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26i.r7 — `bad_debt_pit_creditor_documentation`: Wymóg dokumentacji: faktura, wezwanie do zapłaty, potwierdzenie nadania → Warunek formalny
else :=   {"matched":true,"rule_id":"jdg.pit.a26i.r7","package":"jdg.micro.pit.plan34","priority":2607,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wymóg dokumentacji: faktura, wezwanie do zapłaty, potwierdzenie nadania","_legal_basis":"Art. 26i PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a26.r8 — `relief_donation_church`: Darowizny na cele kultu → Max 6% dochodu
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r8","package":"jdg.micro.pit.plan34","priority":2608,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Darowizny na cele kultu","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.invoice, "expense_type", "") == "DONATION"
}

# jdg.pit.a26e.r8 — `rd_deduction_base_100pct`: 100% kosztów kwalifikowanych → Odliczenie standardowe
else :=   {"matched":true,"rule_id":"jdg.pit.a26e.r8","package":"jdg.micro.pit.plan34","priority":2608,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"100% kosztów kwalifikowanych","_legal_basis":"Art. 26e PIT — Ulga B+R (100-200% kosztów)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a26e.r9 — `rd_deduction_centrum_200pct`: 200% dla Centrum B+R → Odliczenie podwyższone
else :=   {"matched":true,"rule_id":"jdg.pit.a26e.r9","package":"jdg.micro.pit.plan34","priority":2609,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"200% dla Centrum B+R","_legal_basis":"Art. 26e PIT — Ulga B+R (100-200% kosztów)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a26.r9 — `relief_donation_ngo_public_benefit`: Darowizny na cele innych organizacji (nie-OPP) → Potwierdzenie
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r9","package":"jdg.micro.pit.plan34","priority":2609,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Darowizny na cele innych organizacji (nie-OPP)","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "expense_type", "") == "DONATION"
}

# jdg.pit.a26.r10 — `relief_donation_on_bank_transfer`: Darowizny tylko przelewem → Warunek formy
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r10","package":"jdg.micro.pit.plan34","priority":2610,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Darowizny tylko przelewem","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.invoice, "expense_type", "") == "DONATION"
}

# jdg.pit.a26e.r10 — `rd_evidence_separate_required`: Wyodrębniona ewidencja B+R → Warunek formalny
else :=   {"matched":true,"rule_id":"jdg.pit.a26e.r10","package":"jdg.micro.pit.plan34","priority":2610,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wyodrębniona ewidencja B+R","_legal_basis":"Art. 26e PIT — Ulga B+R (100-200% kosztów)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a26.r11 — `relief_internet`: Ulga internetowa → 760 PLN/rok, 2 lata
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r11","package":"jdg.micro.pit.plan34","priority":2611,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga internetowa","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26e.r11 — `rd_evidence_separate_check`: Sprawdzenie czy ewidencja B+R istnieje (PKPiR kolumna 16) → Weryfikacja
else :=   {"matched":true,"rule_id":"jdg.pit.a26e.r11","package":"jdg.micro.pit.plan34","priority":2611,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprawdzenie czy ewidencja B+R istnieje (PKPiR kolumna 16)","_legal_basis":"Art. 26e PIT — Ulga B+R (100-200% kosztów)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a26e.r12 — `rd_relief_capped_at_income`: Ograniczona do dochodu → Limit
else :=   {"matched":true,"rule_id":"jdg.pit.a26e.r12","package":"jdg.micro.pit.plan34","priority":2612,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ograniczona do dochodu","_legal_basis":"Art. 26e PIT — Ulga B+R (100-200% kosztów)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a26.r12 — `relief_internet_years_limit`: Ulga internetowa przysługuje przez 2 kolejne lata → Limit lat
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r12","package":"jdg.micro.pit.plan34","priority":2612,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga internetowa przysługuje przez 2 kolejne lata","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26e.r13 — `rd_relief_carry_forward_3_years`: Niewykorzystana → 3 kolejne lata → Przeniesienie
else :=   {"matched":true,"rule_id":"jdg.pit.a26e.r13","package":"jdg.micro.pit.plan34","priority":2613,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niewykorzystana → 3 kolejne lata","_legal_basis":"Art. 26e PIT — Ulga B+R (100-200% kosztów)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a26.r13 — `relief_internet_first_time`: Ulga dla podatników, którzy po raz pierwszy korzystają z internetu → Warunek
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r13","package":"jdg.micro.pit.plan34","priority":2613,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga dla podatników, którzy po raz pierwszy korzystają z internetu","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26.r14 — `relief_joint_allowances_cap`: Suma ulg ≤ dochód → Ograniczenie łączne
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r14","package":"jdg.micro.pit.plan34","priority":2614,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Suma ulg ≤ dochód","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "married", false) == true; object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26e.r14 — `rd_relief_scale_linear_only`: TYLKO skala i liniowy → Zakres
else :=   {"matched":true,"rule_id":"jdg.pit.a26e.r14","package":"jdg.micro.pit.plan34","priority":2614,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"TYLKO skala i liniowy","_legal_basis":"Art. 26e PIT — Ulga B+R (100-200% kosztów)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a26.r15 — `relief_joint_exceeded_carry`: Nadwyżka → przepada → Przepadnięcie
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r15","package":"jdg.micro.pit.plan34","priority":2615,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nadwyżka → przepada","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "married", false) == true; object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a26e.r15 — `rd_relief_not_lump_sum_tax_card`: Ryczałt i karta — NIE mogą skorzystać z ulgi B+R → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a26e.r15","package":"jdg.micro.pit.plan34","priority":2615,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczałt i karta — NIE mogą skorzystać z ulgi B+R","_legal_basis":"Art. 26e PIT — Ulga B+R (100-200% kosztów)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a26.r16 — `relief_donation_ukraine`: Darowizny na cele pomocy Ukrainie (2022-2024) — odliczenie do 100% dochodu → Specjalna
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r16","package":"jdg.micro.pit.plan34","priority":2616,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Darowizny na cele pomocy Ukrainie (2022-2024) — odliczenie do 100% dochodu","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.invoice, "expense_type", "") == "DONATION"
}

# jdg.pit.a26.r17 — `relief_donation_covid`: Darowizny na cele przeciwdziałania COVID-19 → Specjalna (tymczasowa)
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r17","package":"jdg.micro.pit.plan34","priority":2617,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Darowizny na cele przeciwdziałania COVID-19","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.invoice, "expense_type", "") == "DONATION"
}

# jdg.pit.a26.r18 — `relief_donation_opp_verification_annual`: Weryfikacja statusu OPP (czy organizacja jest OPP w danym roku) → Warunek
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r18","package":"jdg.micro.pit.plan34","priority":2618,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Weryfikacja statusu OPP (czy organizacja jest OPP w danym roku)","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.invoice, "expense_type", "") == "DONATION"
}

# jdg.pit.a26.r19 — `relief_donation_double_check`: Jedna darowizna nie może być odliczona na dwóch różnych podstawach → Wykluczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r19","package":"jdg.micro.pit.plan34","priority":2619,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Jedna darowizna nie może być odliczona na dwóch różnych podstawach","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.invoice, "expense_type", "") == "DONATION"
}

# jdg.pit.a26.r20 — `relief_rehabilitation_housing_rent`: Wydatki na wynajem mieszkania dla osoby niepełnosprawnej → Orzeczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r20","package":"jdg.micro.pit.plan34","priority":2620,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wydatki na wynajem mieszkania dla osoby niepełnosprawnej","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26.r21 — `relief_rehabilitation_guide_dog`: Utrzymanie psa asystującego osoby niepełnosprawnej → Orzeczenie + dokument
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r21","package":"jdg.micro.pit.plan34","priority":2621,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Utrzymanie psa asystującego osoby niepełnosprawnej","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26.r22 — `relief_rehabilitation_purchase_of_drugs`: Leki przepisane przez lekarza (ponad 100 PLN miesięcznie) → Recepty + faktury
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r22","package":"jdg.micro.pit.plan34","priority":2622,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Leki przepisane przez lekarza (ponad 100 PLN miesięcznie)","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26.r23 — `relief_rehabilitation_hearing_aids`: Aparaty słuchowe, wózki inwalidzkie, protezy → Orzeczenie + faktura
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r23","package":"jdg.micro.pit.plan34","priority":2623,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Aparaty słuchowe, wózki inwalidzkie, protezy","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26.r24 — `relief_rehabilitation_adaptation_of_vehicle`: Przystosowanie samochodu dla osoby niepełnosprawnej → Orzeczenie + faktura
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r24","package":"jdg.micro.pit.plan34","priority":2624,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przystosowanie samochodu dla osoby niepełnosprawnej","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a26.r25 — `relief_aggregate_verification`: Weryfikacja sumy ulg z Art. 26 względem zeznania rocznego → Koordynacja
else :=   {"matched":true,"rule_id":"jdg.pit.a26.r25","package":"jdg.micro.pit.plan34","priority":2625,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Weryfikacja sumy ulg z Art. 26 względem zeznania rocznego","_legal_basis":"Art. 26 PIT — Ulgi podatkowe (darowizny, IKZE, rehabilitacja)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a27.r1 — `tax_scale_detection`: Wybrano skalę PIT-36 → Skala 12%/32%
else :=   {"matched":true,"rule_id":"jdg.pit.a27.r1","package":"jdg.micro.pit.plan34","priority":2701,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wybrano skalę PIT-36","_legal_basis":"Art. 27 PIT — Skala podatkowa (12%/32%, kwota wolna 30 000 PLN)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a27a.r1 — `child_tax_credit_eligibility`: Dziecko małoletnie → Prawo do ulgi
else :=   {"matched":true,"rule_id":"jdg.pit.a27a.r1","package":"jdg.micro.pit.plan34","priority":2701,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dziecko małoletnie","_legal_basis":"Art. 27a PIT — Ulga na dzieci","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}

# jdg.pit.a27g.r1 — `abolition_foreign_income_detected`: Dochód zagraniczny rozliczany metodą kredytu podatkowego → Prawo do ulgi
else :=   {"matched":true,"rule_id":"jdg.pit.a27g.r1","package":"jdg.micro.pit.plan34","priority":2701,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochód zagraniczny rozliczany metodą kredytu podatkowego","_legal_basis":"Art. 27g PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a27.r2 — `tax_scale_rate_12pct_up_to_120k`: Dochód ≤ 120 000 PLN → 12%
else :=   {"matched":true,"rule_id":"jdg.pit.a27.r2","package":"jdg.micro.pit.plan34","priority":2702,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochód ≤ 120 000 PLN","_legal_basis":"Art. 27 PIT — Skala podatkowa (12%/32%, kwota wolna 30 000 PLN)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; input.jdg_entrepreneur.tax_form == "PIT_SCALE"
}

# jdg.pit.a27a.r2 — `child_tax_credit_first_child`: Limit doch. 112k/150k → 1 112.04 PLN/rok
else :=   {"matched":true,"rule_id":"jdg.pit.a27a.r2","package":"jdg.micro.pit.plan34","priority":2702,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Limit doch. 112k/150k","_legal_basis":"Art. 27a PIT — Ulga na dzieci","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}

# jdg.pit.a27g.r2 — `abolition_limit_1360_pln`: Limit roczny 1 360 PLN (od 2021 r.) → Odliczenie max 1 360 PLN
else :=   {"matched":true,"rule_id":"jdg.pit.a27g.r2","package":"jdg.micro.pit.plan34","priority":2702,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Limit roczny 1 360 PLN (od 2021 r.)","_legal_basis":"Art. 27g PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a27.r3 — `tax_scale_rate_32pct_over_120k`: Dochód > 120 000 PLN → 32% od nadwyżki
else :=   {"matched":true,"rule_id":"jdg.pit.a27.r3","package":"jdg.micro.pit.plan34","priority":2703,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochód > 120 000 PLN","_legal_basis":"Art. 27 PIT — Skala podatkowa (12%/32%, kwota wolna 30 000 PLN)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; input.jdg_entrepreneur.tax_form == "PIT_SCALE"
}

# jdg.pit.a27a.r3 — `child_tax_credit_second_child`: Drugie dziecko → 1 668.12 PLN/rok
else :=   {"matched":true,"rule_id":"jdg.pit.a27a.r3","package":"jdg.micro.pit.plan34","priority":2703,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Drugie dziecko","_legal_basis":"Art. 27a PIT — Ulga na dzieci","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}

# jdg.pit.a27g.r3 — `abolition_maritime_exception`: Praca poza terytorium lądowym (marynarze, platformy) → Limit NIE obowiązuje
else :=   {"matched":true,"rule_id":"jdg.pit.a27g.r3","package":"jdg.micro.pit.plan34","priority":2703,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Praca poza terytorium lądowym (marynarze, platformy)","_legal_basis":"Art. 27g PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a27.r4 — `tax_scale_tax_free_30k`: Kwota wolna 30 000 PLN → Redukcja 3 600 PLN
else :=   {"matched":true,"rule_id":"jdg.pit.a27.r4","package":"jdg.micro.pit.plan34","priority":2704,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kwota wolna 30 000 PLN","_legal_basis":"Art. 27 PIT — Skala podatkowa (12%/32%, kwota wolna 30 000 PLN)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; input.jdg_entrepreneur.tax_form == "PIT_SCALE"
}

# jdg.pit.a27a.r4 — `child_tax_credit_third_child`: Trzecie dziecko → 2 000.04 PLN/rok
else :=   {"matched":true,"rule_id":"jdg.pit.a27a.r4","package":"jdg.micro.pit.plan34","priority":2704,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Trzecie dziecko","_legal_basis":"Art. 27a PIT — Ulga na dzieci","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a27g.r4 — `abolition_scale_linear_only`: TYLKO skala i podatek liniowy → Zakres
else :=   {"matched":true,"rule_id":"jdg.pit.a27g.r4","package":"jdg.micro.pit.plan34","priority":2704,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"TYLKO skala i podatek liniowy","_legal_basis":"Art. 27g PIT — Ulga podatkowa","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
}

# jdg.pit.a27a.r5 — `child_tax_credit_fourth_plus`: Czwarte i każde kolejne dziecko → 2 700,00 PLN
else :=   {"matched":true,"rule_id":"jdg.pit.a27a.r5","package":"jdg.micro.pit.plan34","priority":2705,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czwarte i każde kolejne dziecko","_legal_basis":"Art. 27a PIT — Ulga na dzieci","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}

# jdg.pit.a27g.r5 — `abolition_not_for_lump_sum`: Ryczałt i karta → NIE → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a27g.r5","package":"jdg.micro.pit.plan34","priority":2705,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczałt i karta → NIE","_legal_basis":"Art. 27g PIT — Ulga podatkowa","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a27a.r6 — `child_tax_credit_disabled_child`: Dziecko z orzeczeniem o niepełnosprawności → ×2 kwoty
else :=   {"matched":true,"rule_id":"jdg.pit.a27a.r6","package":"jdg.micro.pit.plan34","priority":2706,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dziecko z orzeczeniem o niepełnosprawności","_legal_basis":"Art. 27a PIT — Ulga na dzieci","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}

# jdg.pit.a27g.r6 — `abolition_reduces_tax_not_income`: Ulga pomniejsza podatek (NIE dochód!) — odliczenie od podatku → Typ ulgi
else :=   {"matched":true,"rule_id":"jdg.pit.a27g.r6","package":"jdg.micro.pit.plan34","priority":2706,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga pomniejsza podatek (NIE dochód!) — odliczenie od podatku","_legal_basis":"Art. 27g PIT — Ulga podatkowa","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.pit.a27a.r7 — `child_tax_credit_income_limit_single`: Samotny rodzic: limit 112 000 PLN dochodu → Warunek progu
else :=   {"matched":true,"rule_id":"jdg.pit.a27a.r7","package":"jdg.micro.pit.plan34","priority":2707,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Samotny rodzic: limit 112 000 PLN dochodu","_legal_basis":"Art. 27a PIT — Ulga na dzieci","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}

# jdg.pit.a27a.r8 — `child_tax_credit_income_limit_joint`: Małżonkowie: limit 150 000 PLN łącznego dochodu → Warunek progu
else :=   {"matched":true,"rule_id":"jdg.pit.a27a.r8","package":"jdg.micro.pit.plan34","priority":2708,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Małżonkowie: limit 150 000 PLN łącznego dochodu","_legal_basis":"Art. 27a PIT — Ulga na dzieci","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.vendor, "relation_to_entrepreneur", "") == "SPOUSE"; object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"; input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "married", false) == true
}

# jdg.pit.a27a.r9 — `child_tax_credit_refundable_scale_only`: Zwracana TYLKO przy skali → Refundacja
else :=   {"matched":true,"rule_id":"jdg.pit.a27a.r9","package":"jdg.micro.pit.plan34","priority":2709,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwracana TYLKO przy skali","_legal_basis":"Art. 27a PIT — Ulga na dzieci","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}

# jdg.pit.a27.r10 — `tax_scale_joint_settlement_spouse`: Wspólne rozliczenie z małżonkiem → 2× kwota wolna
else :=   {"matched":true,"rule_id":"jdg.pit.a27.r10","package":"jdg.micro.pit.plan34","priority":2710,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wspólne rozliczenie z małżonkiem","_legal_basis":"Art. 27 PIT — Skala podatkowa (12%/32%, kwota wolna 30 000 PLN)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.vendor, "relation_to_entrepreneur", "") == "SPOUSE"; input.jdg_entrepreneur.tax_form == "PIT_SCALE"; input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "married", false) == true
}

# jdg.pit.a27.r13 — `tax_scale_floor_0`: Podatek nie może być ujemny → Minimum 0
else :=   {"matched":true,"rule_id":"jdg.pit.a27.r13","package":"jdg.micro.pit.plan34","priority":2713,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatek nie może być ujemny","_legal_basis":"Art. 27 PIT — Skala podatkowa (12%/32%, kwota wolna 30 000 PLN)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
}

# jdg.pit.a27.r14 — `tax_scale_not_available_linear`: Liniowy → NIE skala → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a27.r14","package":"jdg.micro.pit.plan34","priority":2714,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Liniowy → NIE skala","_legal_basis":"Art. 27 PIT — Skala podatkowa (12%/32%, kwota wolna 30 000 PLN)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a27.r15 — `tax_scale_not_available_lump_sum`: Ryczałt → NIE skala → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a27.r15","package":"jdg.micro.pit.plan34","priority":2715,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczałt → NIE skala","_legal_basis":"Art. 27 PIT — Skala podatkowa (12%/32%, kwota wolna 30 000 PLN)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a30ca.r1 — `ip_box_eligible_ip_detection`: Patent, wzór użytkowy, program komputerowy → Definicja IP
else :=   {"matched":true,"rule_id":"jdg.pit.a30ca.r1","package":"jdg.micro.pit.plan34","priority":3001,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Patent, wzór użytkowy, program komputerowy","_legal_basis":"Art. 30ca PIT — IP Box (5% stawka dla kwalifikowanych IP)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a30a.r1 — `capital_income_dividends`: Dywidendy, udziały w zyskach → 19% ryczałt
else :=   {"matched":true,"rule_id":"jdg.pit.a30a.r1","package":"jdg.micro.pit.plan34","priority":3001,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dywidendy, udziały w zyskach","_legal_basis":"Art. 30a PIT — Ryczałt od przychodów ewidencjonowanych","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.invoice, "income_source", "") == "CAPITAL_GAINS"
}

# jdg.pit.a30b.r1 — `real_estate_sale_before_5_years`: Sprzedaż przed 5 laty → opodatkowane → 19%
else :=   {"matched":true,"rule_id":"jdg.pit.a30b.r1","package":"jdg.micro.pit.plan34","priority":3001,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprzedaż przed 5 laty → opodatkowane","_legal_basis":"Art. 30b PIT — Ryczałt (szczegółowe przepisy)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
}

# jdg.pit.a30ca.r2 — `ip_box_rate_5pct`: Stawka 5% od dochodu z IP → 5%
else :=   {"matched":true,"rule_id":"jdg.pit.a30ca.r2","package":"jdg.micro.pit.plan34","priority":3002,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawka 5% od dochodu z IP","_legal_basis":"Art. 30ca PIT — IP Box (5% stawka dla kwalifikowanych IP)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a30a.r2 — `capital_income_interest`: Odsetki od pożyczek, obligacji → 19% ryczałt
else :=   {"matched":true,"rule_id":"jdg.pit.a30a.r2","package":"jdg.micro.pit.plan34","priority":3002,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odsetki od pożyczek, obligacji","_legal_basis":"Art. 30a PIT — Ryczałt od przychodów ewidencjonowanych","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.invoice, "income_source", "") == "CAPITAL_GAINS"
}

# jdg.pit.a30b.r2 — `real_estate_sale_after_5_years`: Sprzedaż po 5 latach → zwolnione → Zwolnione
else :=   {"matched":true,"rule_id":"jdg.pit.a30b.r2","package":"jdg.micro.pit.plan34","priority":3002,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprzedaż po 5 latach → zwolnione","_legal_basis":"Art. 30b PIT — Ryczałt (szczegółowe przepisy)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a30ca.r3 — `ip_box_nexus_formula`: Dochód × wskaźnik Nexus → Formuła
else :=   {"matched":true,"rule_id":"jdg.pit.a30ca.r3","package":"jdg.micro.pit.plan34","priority":3003,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochód × wskaźnik Nexus","_legal_basis":"Art. 30ca PIT — IP Box (5% stawka dla kwalifikowanych IP)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a30ca.r4 — `ip_box_nexus_numerator_a`: Koszty własnej działalności B+R (czynnik a) → Składnik Nexus
else :=   {"matched":true,"rule_id":"jdg.pit.a30ca.r4","package":"jdg.micro.pit.plan34","priority":3004,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszty własnej działalności B+R (czynnik a)","_legal_basis":"Art. 30ca PIT — IP Box (5% stawka dla kwalifikowanych IP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true
}

# jdg.pit.a30ca.r5 — `ip_box_nexus_numerator_b`: Koszty nabycia od podmiotu niepowiązanego (czynnik b) → Składnik Nexus
else :=   {"matched":true,"rule_id":"jdg.pit.a30ca.r5","package":"jdg.micro.pit.plan34","priority":3005,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszty nabycia od podmiotu niepowiązanego (czynnik b)","_legal_basis":"Art. 30ca PIT — IP Box (5% stawka dla kwalifikowanych IP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a30b.r6 — `real_estate_sale_deduction_own_housing`: Wydatki na własne cele mieszkaniowe → Zwolnienie warunkowe
else :=   {"matched":true,"rule_id":"jdg.pit.a30b.r6","package":"jdg.micro.pit.plan34","priority":3006,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wydatki na własne cele mieszkaniowe","_legal_basis":"Art. 30b PIT — Ryczałt (szczegółowe przepisy)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a30ca.r6 — `ip_box_nexus_denominator_c`: Koszty nabycia od podmiotu powiązanego (czynnik c) → Składnik Nexus
else :=   {"matched":true,"rule_id":"jdg.pit.a30ca.r6","package":"jdg.micro.pit.plan34","priority":3006,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszty nabycia od podmiotu powiązanego (czynnik c)","_legal_basis":"Art. 30ca PIT — IP Box (5% stawka dla kwalifikowanych IP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a30a.r7 — `capital_income_separate_source`: Dochody kapitałowe — odrębne źródło → Nie łączy się z JDG
else :=   {"matched":true,"rule_id":"jdg.pit.a30a.r7","package":"jdg.micro.pit.plan34","priority":3007,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochody kapitałowe — odrębne źródło","_legal_basis":"Art. 30a PIT — Ryczałt od przychodów ewidencjonowanych","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.invoice, "income_source", "") == "CAPITAL_GAINS"
}

# jdg.pit.a30ca.r7 — `ip_box_nexus_denominator_d`: Koszty nabycia know-how, patentów od podmiotu powiązanego (czynnik d) → Składnik Nexus
else :=   {"matched":true,"rule_id":"jdg.pit.a30ca.r7","package":"jdg.micro.pit.plan34","priority":3007,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszty nabycia know-how, patentów od podmiotu powiązanego (czynnik d)","_legal_basis":"Art. 30ca PIT — IP Box (5% stawka dla kwalifikowanych IP)","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a30ca.r8 — `ip_box_separate_bookkeeping`: Wyodrębniona ewidencja IP Box → Warunek formalny
else :=   {"matched":true,"rule_id":"jdg.pit.a30ca.r8","package":"jdg.micro.pit.plan34","priority":3008,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wyodrębniona ewidencja IP Box","_legal_basis":"Art. 30ca PIT — IP Box (5% stawka dla kwalifikowanych IP)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_qualified_ip", false) == true
}

# jdg.pit.a30a.r8 — `capital_income_loss_not_deductible`: Strata na kapitałach → NIE odlicza się → Ograniczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a30a.r8","package":"jdg.micro.pit.plan34","priority":3008,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Strata na kapitałach → NIE odlicza się","_legal_basis":"Art. 30a PIT — Ryczałt od przychodów ewidencjonowanych","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true; object.get(input.invoice, "income_source", "") == "CAPITAL_GAINS"
}

# jdg.pit.a30ca.r9 — `ip_box_annual_settlement`: Roczne rozliczenie IP Box w zeznaniu PIT-36/PIT-36L → Procedura
else :=   {"matched":true,"rule_id":"jdg.pit.a30ca.r9","package":"jdg.micro.pit.plan34","priority":3009,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roczne rozliczenie IP Box w zeznaniu PIT-36/PIT-36L","_legal_basis":"Art. 30ca PIT — IP Box (5% stawka dla kwalifikowanych IP)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "has_qualified_ip", false) == true
}

# jdg.pit.a30ca.r10 — `ip_box_scale_linear_only`: TYLKO skala i liniowy → Zakres
else :=   {"matched":true,"rule_id":"jdg.pit.a30ca.r10","package":"jdg.micro.pit.plan34","priority":3010,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"TYLKO skala i liniowy","_legal_basis":"Art. 30ca PIT — IP Box (5% stawka dla kwalifikowanych IP)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
}

# jdg.pit.a31.r1 — `advance_monthly_obligation_scale`: Skala → zaliczki miesięczne do 20. → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r1","package":"jdg.micro.pit.plan34","priority":3101,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skala → zaliczki miesięczne do 20.","_legal_basis":"Art. 31 PIT — Przepisy zbiorcze","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r2 — `advance_monthly_obligation_linear`: Liniowy → zaliczki miesięczne do 20. → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r2","package":"jdg.micro.pit.plan34","priority":3102,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Liniowy → zaliczki miesięczne do 20.","_legal_basis":"Art. 31 PIT — Przepisy zbiorcze","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r3 — `advance_quarterly_small_payer`: Mały podatnik → kwartalne → Opcja
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r3","package":"jdg.micro.pit.plan34","priority":3103,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mały podatnik → kwartalne","_legal_basis":"Art. 31 PIT — Przepisy zbiorcze","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r5 — `advance_calculation_progressive`: Narastająco: dochód × stawka - zapłacone → Obliczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r5","package":"jdg.micro.pit.plan34","priority":3105,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Narastająco: dochód × stawka - zapłacone","_legal_basis":"Art. 31 PIT — Przepisy zbiorcze","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r6 — `advance_deduction_zus_contributions`: Odliczenie ZUS od dochodu → Pomniejszenie
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r6","package":"jdg.micro.pit.plan34","priority":3106,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie ZUS od dochodu","_legal_basis":"Art. 31 PIT — Przepisy zbiorcze","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r14 — `advance_if_zero_or_negative`: Dochód ≤ 0 → zaliczka 0 → Brak zaliczki
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r14","package":"jdg.micro.pit.plan34","priority":3114,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochód ≤ 0 → zaliczka 0","_legal_basis":"Art. 31 PIT — Przepisy zbiorcze","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a32.r1 — `advance_lump_sum_monthly_20`: Ryczałt → zaliczki miesięczne do 20. → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.pit.a32.r1","package":"jdg.micro.pit.plan34","priority":3201,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczałt → zaliczki miesięczne do 20.","_legal_basis":"Art. 32 PIT — Informacje i zeznania innych podmiotów","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a32.r2 — `advance_lump_sum_rate_applied`: Przychód × stawka ryczałtu → Obliczenie uproszczone
else :=   {"matched":true,"rule_id":"jdg.pit.a32.r2","package":"jdg.micro.pit.plan34","priority":3202,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przychód × stawka ryczałtu","_legal_basis":"Art. 32 PIT — Informacje i zeznania innych podmiotów","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"; object.get(input.invoice, "direction", "") == "SALE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a45.r1 — `annual_return_scale_PIT_36`: Skala → PIT-36 → Deklaracja
else :=   {"matched":true,"rule_id":"jdg.pit.a45.r1","package":"jdg.micro.pit.plan34","priority":4501,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skala → PIT-36","_legal_basis":"Art. 45 PIT — Zeznania roczne (PIT-36, PIT-36L, PIT-28)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a45.r2 — `annual_return_linear_PIT_36L`: Liniowy → PIT-36L → Deklaracja
else :=   {"matched":true,"rule_id":"jdg.pit.a45.r2","package":"jdg.micro.pit.plan34","priority":4502,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Liniowy → PIT-36L","_legal_basis":"Art. 45 PIT — Zeznania roczne (PIT-36, PIT-36L, PIT-28)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a45.r3 — `annual_return_lump_PIT_28`: Ryczałt → PIT-28 → Deklaracja
else :=   {"matched":true,"rule_id":"jdg.pit.a45.r3","package":"jdg.micro.pit.plan34","priority":4503,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczałt → PIT-28","_legal_basis":"Art. 45 PIT — Zeznania roczne (PIT-36, PIT-36L, PIT-28)","_warnings":[]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a45.r5 — `annual_return_deadline_30_april`: Termin 30 kwietnia → Termin
else :=   {"matched":true,"rule_id":"jdg.pit.a45.r5","package":"jdg.micro.pit.plan34","priority":4505,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Termin 30 kwietnia","_legal_basis":"Art. 45 PIT — Zeznania roczne (PIT-36, PIT-36L, PIT-28)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a45.r7 — `annual_return_electronic_mandatory`: e-Deklaracja obowiązkowa → Forma
else :=   {"matched":true,"rule_id":"jdg.pit.a45.r7","package":"jdg.micro.pit.plan34","priority":4507,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"e-Deklaracja obowiązkowa","_legal_basis":"Art. 45 PIT — Zeznania roczne (PIT-36, PIT-36L, PIT-28)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a45.r9 — `annual_return_overpayment_refund_45_days`: Zwrot nadpłaty w 45 dni → Termin zwrotu
else :=   {"matched":true,"rule_id":"jdg.pit.a45.r9","package":"jdg.micro.pit.plan34","priority":4509,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwrot nadpłaty w 45 dni","_legal_basis":"Art. 45 PIT — Zeznania roczne (PIT-36, PIT-36L, PIT-28)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a45.r10 — `annual_return_correction_after_filing`: Korekta po złożeniu → możliwa → Możliwość
else :=   {"matched":true,"rule_id":"jdg.pit.a45.r10","package":"jdg.micro.pit.plan34","priority":4510,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta po złożeniu → możliwa","_legal_basis":"Art. 45 PIT — Zeznania roczne (PIT-36, PIT-36L, PIT-28)","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}
