# Generated from Plan OPA 33 — Micro-rules for prop
# 2026-07-13 14:58:41
# Rules: 30 (new, deduplicated)

package jdg.micro.prop

default decide := {"matched":false,"rule_id":"jdg.micro.prop.no_match","package":"jdg.micro.prop","priority":99999}

# jdg.prop.a1.r1 — `real_estate_tax_land_rate`: Grunty związane z działalnością gospodarczą → Stawka max 1,16 PLN/m2 (2026)
decide :=   {"matched":true,"rule_id":"jdg.prop.a1.r1","package":"jdg.micro.prop","priority":7100,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Grunty związane z działalnością gospodarczą","_legal_basis":"Ustawa o podatkach i opłatach lokalnych Art. 5","_warnings":[]} {
    true
}

# jdg.prop.a1.r2 — `real_estate_tax_building_rate`: Budynki związane z działalnością gospodarczą → Stawka max 28,78 PLN/m2 (2026)
else :=   {"matched":true,"rule_id":"jdg.prop.a1.r2","package":"jdg.micro.prop","priority":7101,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Budynki związane z działalnością gospodarczą","_legal_basis":"Art. 5 ust. 1 pkt 2 lit. a","_warnings":[]} {
    true
}

# jdg.prop.a1.r3 — `real_estate_tax_residential_rate`: Budynki mieszkalne → Stawka max 1,00 PLN/m2 (2026)
else :=   {"matched":true,"rule_id":"jdg.prop.a1.r3","package":"jdg.micro.prop","priority":7102,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Budynki mieszkalne","_legal_basis":"Art. 5 ust. 1 pkt 2 lit. b","_warnings":[]} {
    true
}

# jdg.prop.a1.r4 — `real_estate_tax_construction_rate`: Budowle (2% wartości) → 2% wartości budowli (określonej wg przepisów o podatku dochodowym)
else :=   {"matched":true,"rule_id":"jdg.prop.a1.r4","package":"jdg.micro.prop","priority":7103,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Budowle (2% wartości)","_legal_basis":"Art. 5 ust. 1 pkt 3","_warnings":[]} {
    true
}

# jdg.prop.a1.r5 — `real_estate_tax_jdg_land`: JDG posiadający grunt pod działalność → Podatek od nieruchomości gruntowej
else :=   {"matched":true,"rule_id":"jdg.prop.a1.r5","package":"jdg.micro.prop","priority":7104,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG posiadający grunt pod działalność","_legal_basis":"Art. 5 ust. 1","_warnings":[]} {
    true
}

# jdg.prop.a1.r6 — `real_estate_tax_jdg_office`: JDG wynajmujący/własny lokal użytkowy (biuro) → Podatek od nieruchomości (lub przerzucony w czynszu)
else :=   {"matched":true,"rule_id":"jdg.prop.a1.r6","package":"jdg.micro.prop","priority":7105,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG wynajmujący/własny lokal użytkowy (biuro)","_legal_basis":"Art. 5 ust. 1","_warnings":[]} {
    true
}

# jdg.prop.a1.r7 — `real_estate_tax_garage_jdg`: Garaż/miejsce postojowe w budynku mieszkalnym (związane z JDG) → Stawka dla budynków mieszkalnych lub użytkowych
else :=   {"matched":true,"rule_id":"jdg.prop.a1.r7","package":"jdg.micro.prop","priority":7106,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Garaż/miejsce postojowe w budynku mieszkalnym (związane z JDG)","_legal_basis":"Art. 5 ust. 1 pkt 2","_warnings":[]} {
    true
}

# jdg.prop.a2.r1 — `real_estate_tax_deadline_dn1`: Deklaracja DN-1 do 31 stycznia roku podatkowego → Termin
else :=   {"matched":true,"rule_id":"jdg.prop.a2.r1","package":"jdg.micro.prop","priority":7107,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Deklaracja DN-1 do 31 stycznia roku podatkowego","_legal_basis":"Art. 6 ust. 1 u.p.o.l.","_warnings":[]} {
    true
}

# jdg.prop.a2.r2 — `real_estate_tax_installments`: Podatek płatny w 4 ratach (do 15 marca, 15 maja, 15 września, 15 listopada) → Raty kwartalne
else :=   {"matched":true,"rule_id":"jdg.prop.a2.r2","package":"jdg.micro.prop","priority":7108,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatek płatny w 4 ratach (do 15 marca, 15 maja, 15 września, 15 listopada)","_legal_basis":"Art. 7 ust. 1 u.p.o.l.","_warnings":[]} {
    true
}

# jdg.prop.a2.r3 — `real_estate_tax_single_payment`: Kwota < 100 PLN: jednorazowo do 15 marca → Jednorazowo
else :=   {"matched":true,"rule_id":"jdg.prop.a2.r3","package":"jdg.micro.prop","priority":7109,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kwota < 100 PLN: jednorazowo do 15 marca","_legal_basis":"Art. 7 ust. 2 u.p.o.l.","_warnings":[]} {
    true
}

# jdg.prop.r1 — `property_tax_subject_residential_building`: Budynek mieszkalny
else :=   {"matched":true,"rule_id":"jdg.prop.r1","package":"jdg.micro.prop","priority":7110,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Budynek mieszkalny","_legal_basis":"Art. 5 ust. 1","_warnings":[]} {
    true
}

# jdg.prop.r10 — `property_tax_subject_commercial_leased`: JDG dzierzawca nieruchomosci -> placi wlasciciel, ale moze przerzucic na JDG
else :=   {"matched":true,"rule_id":"jdg.prop.r10","package":"jdg.micro.prop","priority":7111,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG dzierzawca nieruchomosci -> placi wlasciciel, ale moze przerzucic na JDG","_legal_basis":"Art. 3","_warnings":[]} {
    true
}

# jdg.prop.r11 — `property_tax_subject_vat_exempt_lease`: Wynajem nieruchomosci mieszkalnej (zwolniony z VAT) -> JDG wynajmujacy placi podatek
else :=   {"matched":true,"rule_id":"jdg.prop.r11","package":"jdg.micro.prop","priority":7112,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wynajem nieruchomosci mieszkalnej (zwolniony z VAT) -> JDG wynajmujacy placi podatek","_legal_basis":"Art. 3","_warnings":[]} {
    true
}

# jdg.prop.r12 — `property_tax_rate_municipal`: Stawki uchwala rada gminy (w granicach ustawowych)
else :=   {"matched":true,"rule_id":"jdg.prop.r12","package":"jdg.micro.prop","priority":7113,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawki uchwala rada gminy (w granicach ustawowych)","_legal_basis":"Art. 5","_warnings":[]} {
    true
}

# jdg.prop.r13 — `property_tax_rate_max_2024`: Stawki maksymalne oglasza MF na dany rok (corocznie)
else :=   {"matched":true,"rule_id":"jdg.prop.r13","package":"jdg.micro.prop","priority":7114,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawki maksymalne oglasza MF na dany rok (corocznie)","_legal_basis":"Art. 5","_warnings":[]} {
    true
}

# jdg.prop.r14 — `property_tax_rate_annual_notice`: JDZ dostaje decyzje wymiarowa od gminy na dany rok
else :=   {"matched":true,"rule_id":"jdg.prop.r14","package":"jdg.micro.prop","priority":7115,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDZ dostaje decyzje wymiarowa od gminy na dany rok","_legal_basis":"Art. 6","_warnings":[]} {
    true
}

# jdg.prop.r15 — `property_tax_deadline_quarterly`: Termin
else :=   {"matched":true,"rule_id":"jdg.prop.r15","package":"jdg.micro.prop","priority":7116,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Termin","_legal_basis":"Art. 6","_warnings":[]} {
    true
}

# jdg.prop.r16 — `property_tax_deadline_one_time`: Opcja: jedna rata do 15. marca (jesli podatek < 100 PLN)
else :=   {"matched":true,"rule_id":"jdg.prop.r16","package":"jdg.micro.prop","priority":7117,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Opcja: jedna rata do 15. marca (jesli podatek < 100 PLN)","_legal_basis":"Art. 6","_warnings":[]} {
    true
}

# jdg.prop.r17 — `property_tax_declaration_deadline`: Deklaracja na podatek od nieruchomosci (DN-1) do 31 stycznia
else :=   {"matched":true,"rule_id":"jdg.prop.r17","package":"jdg.micro.prop","priority":7118,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Deklaracja na podatek od nieruchomosci (DN-1) do 31 stycznia","_legal_basis":"Art. 6","_warnings":[]} {
    true
}

# jdg.prop.r18 — `property_tax_exemption_church`: Zwolnienie: budynki koscielne, sakralne
else :=   {"matched":true,"rule_id":"jdg.prop.r18","package":"jdg.micro.prop","priority":7119,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwolnienie: budynki koscielne, sakralne","_legal_basis":"Art. 7","_warnings":[]} {
    true
}

# jdg.prop.r19 — `property_tax_exemption_public_infrastructure`: Zwolnienie: infrastruktura publiczna (drogi, sieci)
else :=   {"matched":true,"rule_id":"jdg.prop.r19","package":"jdg.micro.prop","priority":7120,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwolnienie: infrastruktura publiczna (drogi, sieci)","_legal_basis":"Art. 7","_warnings":[]} {
    true
}

# jdg.prop.r2 — `property_tax_subject_commercial_building`: Budynek uzytkowy (biura, magazyny, lokale)
else :=   {"matched":true,"rule_id":"jdg.prop.r2","package":"jdg.micro.prop","priority":7121,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Budynek uzytkowy (biura, magazyny, lokale)","_legal_basis":"Art. 5 ust. 1","_warnings":[]} {
    true
}

# jdg.prop.r20 — `property_tax_loss_partial_year`: Zmiana w trakcie roku (sprzedaz, zakup, zniszczenie) -> za miesiace faktycznego posiadania
else :=   {"matched":true,"rule_id":"jdg.prop.r20","package":"jdg.micro.prop","priority":7122,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana w trakcie roku (sprzedaz, zakup, zniszczenie) -> za miesiace faktycznego posiadania","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.prop.r3 — `property_tax_subject_garage`: Garaz (w budynku mieszkalnym)
else :=   {"matched":true,"rule_id":"jdg.prop.r3","package":"jdg.micro.prop","priority":7123,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Garaz (w budynku mieszkalnym)","_legal_basis":"Art. 5 ust. 1","_warnings":[]} {
    true
}

# jdg.prop.r4 — `property_tax_subject_land_residential`: Grunt pod budynkiem mieszkalnym
else :=   {"matched":true,"rule_id":"jdg.prop.r4","package":"jdg.micro.prop","priority":7124,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Grunt pod budynkiem mieszkalnym","_legal_basis":"Art. 5 ust. 1","_warnings":[]} {
    true
}

# jdg.prop.r5 — `property_tax_subject_land_business`: Grunt pod dzialalnoscia gospodarcza
else :=   {"matched":true,"rule_id":"jdg.prop.r5","package":"jdg.micro.prop","priority":7125,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Grunt pod dzialalnoscia gospodarcza","_legal_basis":"Art. 5 ust. 1","_warnings":[]} {
    true
}

# jdg.prop.r6 — `property_tax_subject_land_other`: od 0.53 PLN/m2
else :=   {"matched":true,"rule_id":"jdg.prop.r6","package":"jdg.micro.prop","priority":7126,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"od 0.53 PLN/m2","_legal_basis":"Art. 5 ust. 1","_warnings":[]} {
    true
}

# jdg.prop.r7 — `property_tax_subject_structure_commercial`: Budowla (hala, plac, silos, wiata)
else :=   {"matched":true,"rule_id":"jdg.prop.r7","package":"jdg.micro.prop","priority":7127,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Budowla (hala, plac, silos, wiata)","_legal_basis":"Art. 5 ust. 1","_warnings":[]} {
    true
}

# jdg.prop.r8 — `property_tax_subject_structure_definition`: Definicja budowli wg Prawa budowlanego
else :=   {"matched":true,"rule_id":"jdg.prop.r8","package":"jdg.micro.prop","priority":7128,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Definicja budowli wg Prawa budowlanego","_legal_basis":"Art. 1a","_warnings":[]} {
    true
}

# jdg.prop.r9 — `property_tax_subject_commercial_firm_owned`: JDG wlasiciel nieruchomosci -> placi podatek od nieruchomosci
else :=   {"matched":true,"rule_id":"jdg.prop.r9","package":"jdg.micro.prop","priority":7129,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG wlasiciel nieruchomosci -> placi podatek od nieruchomosci","_legal_basis":"Art. 3","_warnings":[]} {
    true
}
