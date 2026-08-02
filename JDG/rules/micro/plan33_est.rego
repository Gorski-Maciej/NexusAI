# Generated from Plan OPA 33 — Micro-rules for est
# 2026-07-13 14:58:41
# Rules: 15 (new, deduplicated)

package jdg.micro.est

default decide := {"matched":false,"rule_id":"jdg.micro.est.no_match","package":"jdg.micro.est","priority":99999}

# jdg.est.r1 — `estonian_cit_eligibility`: JDG moze wybrac estoński CIT (od 2024: JDG moze skorzystac) → Mozliwosc
decide :=   {"matched":true,"rule_id":"jdg.est.r1","package":"jdg.micro.est","priority":6600,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG moze wybrac estoński CIT (od 2024: JDG moze skorzystac)","_legal_basis":"Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG","_warnings":["[MICRO] JDG moze wybrac estoński CIT (od 2024: JDG moze skorzystac)"]} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.est.r10 — `estonian_cit_change_back_to_scale`: Zmiana z estońskiego na skale -> dozwolone po 4 latach → Limit
else :=   {"matched":true,"rule_id":"jdg.est.r10","package":"jdg.micro.est","priority":6601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana z estońskiego na skale -> dozwolone po 4 latach","_legal_basis":"Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG","_warnings":["[MICRO] Zmiana z estońskiego na skale -> dozwolone po 4 latach"]} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.est.r11 — `estonian_cit_settlement_pit_38`: Zeznanie PIT-38 (dla dochodu z dystrybucji) → Deklaracja
else :=   {"matched":true,"rule_id":"jdg.est.r11","package":"jdg.micro.est","priority":6602,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zeznanie PIT-38 (dla dochodu z dystrybucji)","_legal_basis":"Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG","_warnings":["[MICRO] Zeznanie PIT-38 (dla dochodu z dystrybucji)"]} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.est.r12 — `estonian_cit_no_zus_impact`: Estoński CIT nie wplywa na ZUS (ZUS taki sam) → Brak wplywu
else :=   {"matched":true,"rule_id":"jdg.est.r12","package":"jdg.micro.est","priority":6603,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Estoński CIT nie wplywa na ZUS (ZUS taki sam)","_legal_basis":"Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG","_warnings":["[MICRO] Estoński CIT nie wplywa na ZUS (ZUS taki sam)"]} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.est.r13 — `estonian_cit_health_insurance_different`: Skladka zdrowotna: jesli wypłata dywidendy -> 9% od dywidendy (dla wspólnika) → Zdrowotna
else :=   {"matched":true,"rule_id":"jdg.est.r13","package":"jdg.micro.est","priority":6604,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skladka zdrowotna: jesli wypłata dywidendy -> 9% od dywidendy (dla wspólnika)","_legal_basis":"Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG","_warnings":["[MICRO] Skladka zdrowotna: jesli wypłata dywidendy -> 9% od dywidendy (dla wspólnika)"]} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.est.r14 — `estonian_cit_not_for_services_former_employer`: Wykluczenie: uslugi dla bylnego pracodawcy (jw.) → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.est.r14","package":"jdg.micro.est","priority":6605,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykluczenie: uslugi dla bylnego pracodawcy (jw.)","_legal_basis":"Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG","_warnings":["[MICRO] Wykluczenie: uslugi dla bylnego pracodawcy (jw.)"]} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.est.r15 — `estonian_cit_election_notification`: Wybor estońskiego CIT: zawiadomienie US w terminie do 20. dnia miesiaca po wyborze → Formalnosc
else :=   {"matched":true,"rule_id":"jdg.est.r15","package":"jdg.micro.est","priority":6606,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wybor estońskiego CIT: zawiadomienie US w terminie do 20. dnia miesiaca po wyborze","_legal_basis":"Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG","_warnings":["[MICRO] Wybor estońskiego CIT: zawiadomienie US w terminie do 20. dnia miesiaca po wyborze"]} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.est.r2 — `estonian_cit_condition_employees_3`: Warunek: zatrudnienie min 3 pracownikow (lub wydatki > 3x minimalnej) → Warunek
else :=   {"matched":true,"rule_id":"jdg.est.r2","package":"jdg.micro.est","priority":6607,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Warunek: zatrudnienie min 3 pracownikow (lub wydatki > 3x minimalnej)","_legal_basis":"Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG","_warnings":["[MICRO] Warunek: zatrudnienie min 3 pracownikow (lub wydatki > 3x minimalnej)"]} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.est.r3 — `estonian_cit_condition_revenue_100m`: Przychod < 100M EUR → Warunek
else :=   {"matched":true,"rule_id":"jdg.est.r3","package":"jdg.micro.est","priority":6608,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przychod < 100M EUR","_legal_basis":"Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG","_warnings":["[MICRO] Przychod < 100M EUR"]} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.est.r4 — `estonian_cit_condition_equity_10pct`: Kapital wlasny > 10% aktywow (na koniec roku) → Warunek
else :=   {"matched":true,"rule_id":"jdg.est.r4","package":"jdg.micro.est","priority":6609,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kapital wlasny > 10% aktywow (na koniec roku)","_legal_basis":"Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG","_warnings":["[MICRO] Kapital wlasny > 10% aktywow (na koniec roku)"]} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.est.r5 — `estonian_cit_rate_10pct_distribution`: Podatek przy dystrybucji zysku: 10% CIT → Stawka
else :=   {"matched":true,"rule_id":"jdg.est.r5","package":"jdg.micro.est","priority":6610,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatek przy dystrybucji zysku: 10% CIT","_legal_basis":"Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG","_warnings":["[MICRO] Podatek przy dystrybucji zysku: 10% CIT"]} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.est.r6 — `estonian_cit_rate_20pct_distribution_high`: Stawka podwyzszona: 20% CIT (gdy zysk wypłacany > zysk bilansowy) → Stawka
else :=   {"matched":true,"rule_id":"jdg.est.r6","package":"jdg.micro.est","priority":6611,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawka podwyzszona: 20% CIT (gdy zysk wypłacany > zysk bilansowy)","_legal_basis":"Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG","_warnings":["[MICRO] Stawka podwyzszona: 20% CIT (gdy zysk wypłacany > zysk bilansowy)"]} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.est.r7 — `estonian_cit_tax_free_retained`: Zysk zatrzymany w firmie -> wolny od CIT → Zwolnienie
else :=   {"matched":true,"rule_id":"jdg.est.r7","package":"jdg.micro.est","priority":6612,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zysk zatrzymany w firmie -> wolny od CIT","_legal_basis":"Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG","_warnings":["[MICRO] Zysk zatrzymany w firmie -> wolny od CIT"]} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.est.r8 — `estonian_cit_termination_loss_of_right`: Utrata prawa do estońskiego CIT -> korekta do PIT-liniowego → Konsekwencja
else :=   {"matched":true,"rule_id":"jdg.est.r8","package":"jdg.micro.est","priority":6613,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Utrata prawa do estońskiego CIT -> korekta do PIT-liniowego","_legal_basis":"Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG","_warnings":["[MICRO] Utrata prawa do estońskiego CIT -> korekta do PIT-liniowego"]} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# jdg.est.r9 — `estonian_cit_termination_sanction`: Sankcja: podatek od zyskow zatrzymanych (20%) przy utracie → Sankcja
else :=   {"matched":true,"rule_id":"jdg.est.r9","package":"jdg.micro.est","priority":6614,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sankcja: podatek od zyskow zatrzymanych (20%) przy utracie","_legal_basis":"Ustawa o CIT (Art. 28c-28t) — estoński CIT dla JDG","_warnings":["[MICRO] Sankcja: podatek od zyskow zatrzymanych (20%) przy utracie"]} {
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}
