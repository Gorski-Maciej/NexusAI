# Generated from Plan OPA 33 — Micro-rules for tp
# 2026-07-13 14:58:41
# Rules: 15 (new, deduplicated)

package jdg.micro.tp

default decide := {"matched":false,"rule_id":"jdg.micro.tp.no_match","package":"jdg.micro.tp","priority":99999}

# jdg.tp.r1 — `tp_related_party_detection`: Podmiot powiazany (kapitalowo, rodzinnie, zarzadczo) z JDG → Definicja
decide :=   {"matched":true,"rule_id":"jdg.tp.r1","package":"jdg.micro.tp","priority":6500,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podmiot powiazany (kapitalowo, rodzinnie, zarzadczo) z JDG","_legal_basis":"Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["[MICRO] Podmiot powiazany (kapitalowo, rodzinnie, zarzadczo) z JDG"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.r10 — `tp_arm_s_length_comparison`: Porownanie z transakcjami na wolnym rynku (benchmark) → Benchmark
else :=   {"matched":true,"rule_id":"jdg.tp.r10","package":"jdg.micro.tp","priority":6501,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Porownanie z transakcjami na wolnym rynku (benchmark)","_legal_basis":"Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["[MICRO] Porownanie z transakcjami na wolnym rynku (benchmark)"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.r11 — `tp_method_cup`: Metoda CUP (porównywalnej ceny niekontrolowanej) → Metoda
else :=   {"matched":true,"rule_id":"jdg.tp.r11","package":"jdg.micro.tp","priority":6502,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Metoda CUP (porównywalnej ceny niekontrolowanej)","_legal_basis":"Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["[MICRO] Metoda CUP (porównywalnej ceny niekontrolowanej)"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.r12 — `tp_method_cost_plus`: Metoda koszt plus (marza) → Metoda
else :=   {"matched":true,"rule_id":"jdg.tp.r12","package":"jdg.micro.tp","priority":6503,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Metoda koszt plus (marza)","_legal_basis":"Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["[MICRO] Metoda koszt plus (marza)"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.r13 — `tp_method_resale_price`: Metoda ceny odsprzedazy → Metoda
else :=   {"matched":true,"rule_id":"jdg.tp.r13","package":"jdg.micro.tp","priority":6504,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Metoda ceny odsprzedazy","_legal_basis":"Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["[MICRO] Metoda ceny odsprzedazy"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.r14 — `tp_method_transactional_profit`: Metoda podzialu zysku / marzy transakcyjnej → Metoda
else :=   {"matched":true,"rule_id":"jdg.tp.r14","package":"jdg.micro.tp","priority":6505,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Metoda podzialu zysku / marzy transakcyjnej","_legal_basis":"Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["[MICRO] Metoda podzialu zysku / marzy transakcyjnej"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.r15 — `tp_apa_advance_pricing_agreement`: Porozumienie cenowe (APA) z MF: okreslenie ceny transferowej z wyprzedzeniem → APA
else :=   {"matched":true,"rule_id":"jdg.tp.r15","package":"jdg.micro.tp","priority":6506,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Porozumienie cenowe (APA) z MF: okreslenie ceny transferowej z wyprzedzeniem","_legal_basis":"Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["[MICRO] Porozumienie cenowe (APA) z MF: okreslenie ceny transferowej z wyprzedzeniem"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.r2 — `tp_related_party_family`: Powiazanie rodzinne: malzonek, dzieci, rodzic, rodzenstwo → Rodzina
else :=   {"matched":true,"rule_id":"jdg.tp.r2","package":"jdg.micro.tp","priority":6507,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Powiazanie rodzinne: malzonek, dzieci, rodzic, rodzenstwo","_legal_basis":"Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["[MICRO] Powiazanie rodzinne: malzonek, dzieci, rodzic, rodzenstwo"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.r3 — `tp_related_party_capital_25pct`: Powiazanie kapitalowe: udzial > 25% w spolce → Kapital
else :=   {"matched":true,"rule_id":"jdg.tp.r3","package":"jdg.micro.tp","priority":6508,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Powiazanie kapitalowe: udzial > 25% w spolce","_legal_basis":"Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["[MICRO] Powiazanie kapitalowe: udzial > 25% w spolce"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.r4 — `tp_related_party_management`: Powiazanie zarzadcze: czlonek zarzadu, rady nadzorczej → Zarzad
else :=   {"matched":true,"rule_id":"jdg.tp.r4","package":"jdg.micro.tp","priority":6509,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Powiazanie zarzadcze: czlonek zarzadu, rady nadzorczej","_legal_basis":"Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["[MICRO] Powiazanie zarzadcze: czlonek zarzadu, rady nadzorczej"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.r5 — `tp_documentation_threshold_revenue_2m`: Obowiazek dokumentacji TP: przychod/koszty > 10M EUR (dla JDG rzadko) → Prog
else :=   {"matched":true,"rule_id":"jdg.tp.r5","package":"jdg.micro.tp","priority":6510,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiazek dokumentacji TP: przychod/koszty > 10M EUR (dla JDG rzadko)","_legal_basis":"Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["[MICRO] Obowiazek dokumentacji TP: przychod/koszty > 10M EUR (dla JDG rzadko)"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.r6 — `tp_documentation_threshold_transaction_500k`: Obowiazek dokumentacji lokalnej: transakcja > 500k PLN (uslugi) + 2.5M PLN (towary) → Prog
else :=   {"matched":true,"rule_id":"jdg.tp.r6","package":"jdg.micro.tp","priority":6511,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiazek dokumentacji lokalnej: transakcja > 500k PLN (uslugi) + 2.5M PLN (towary)","_legal_basis":"Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["[MICRO] Obowiazek dokumentacji lokalnej: transakcja > 500k PLN (uslugi) + 2.5M PLN (towary)"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.r7 — `tp_documentation_threshold_services_100k`: Obowiazek dla uslug: transakcja > 100k PLN z podmiotem powiazanym (JDG mikropodmiot) → Prog
else :=   {"matched":true,"rule_id":"jdg.tp.r7","package":"jdg.micro.tp","priority":6512,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiazek dla uslug: transakcja > 100k PLN z podmiotem powiazanym (JDG mikropodmiot)","_legal_basis":"Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["[MICRO] Obowiazek dla uslug: transakcja > 100k PLN z podmiotem powiazanym (JDG mikropodmiot)"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.r8 — `tp_micro_exemption`: Mikropodmiot (JDG o przychodach < 2M EUR) -> zwolniony z dokumentacji TP → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.tp.r8","package":"jdg.micro.tp","priority":6513,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mikropodmiot (JDG o przychodach < 2M EUR) -> zwolniony z dokumentacji TP","_legal_basis":"Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["[MICRO] Mikropodmiot (JDG o przychodach < 2M EUR) -> zwolniony z dokumentacji TP"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.r9 — `tp_arm_s_length_principle`: Zasada ceny rynkowej: transakcje z podmiotami powiazanymi na warunkach rynkowych → Zasada
else :=   {"matched":true,"rule_id":"jdg.tp.r9","package":"jdg.micro.tp","priority":6514,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zasada ceny rynkowej: transakcje z podmiotami powiazanymi na warunkach rynkowych","_legal_basis":"Art. 23m-23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["[MICRO] Zasada ceny rynkowej: transakcje z podmiotami powiazanymi na warunkach rynkowych"]} {
    object.get(input.vendor, "is_related_party", false) == true
}
