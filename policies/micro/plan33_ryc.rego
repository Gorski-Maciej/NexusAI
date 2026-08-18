# Generated from Plan OPA 33 — Micro-rules for ryc
# 2026-07-13 14:58:41
# Rules: 158 (new, deduplicated)

package jdg.micro.ryc

default decide := {"matched":false,"rule_id":"jdg.micro.ryc.no_match","package":"jdg.micro.ryc","priority":99999}

# jdg.ryc.a10.r1 — `lump_sum_tax_calculation_general`: Podatek = przychód (po odliczeniach) x stawka ryczałtu → Obliczenie
decide :=   {"matched":true,"rule_id":"jdg.ryc.a10.r1","package":"jdg.micro.ryc","priority":3000,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatek = przychód (po odliczeniach) x stawka ryczałtu","_legal_basis":"Art. 10 ust. 1 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Podatek = przychód (po odliczeniach) x stawka ryczałtu"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a10.r2 — `lump_sum_tax_no_deductions_beyond_list`: Brak możliwości odliczenia innych kosztów niż wymienione w ustawie → Zamknięty katalog odliczeń
else :=   {"matched":true,"rule_id":"jdg.ryc.a10.r2","package":"jdg.micro.ryc","priority":3001,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak możliwości odliczenia innych kosztów niż wymienione w ustawie","_legal_basis":"Art. 10 ust. 2 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Brak możliwości odliczenia innych kosztów niż wymienione w ustawie"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a10.r3 — `lump_sum_tax_rounding_down`: Podatek zaokrągla się do pełnych złotych w dół → Zaokrąglenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a10.r3","package":"jdg.micro.ryc","priority":3002,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatek zaokrągla się do pełnych złotych w dół","_legal_basis":"Art. 10 ust. 3 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Podatek zaokrągla się do pełnych złotych w dół"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a10.r4 — `lump_sum_tax_annual_settlement`: Roczne rozliczenie ryczałtu w PIT-28 → Deklaracja roczna
else :=   {"matched":true,"rule_id":"jdg.ryc.a10.r4","package":"jdg.micro.ryc","priority":3003,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roczne rozliczenie ryczałtu w PIT-28","_legal_basis":"Art. 10 ust. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Roczne rozliczenie ryczałtu w PIT-28"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a11.r1 — `lump_sum_base_revenue_minus_deductions`: Podstawa opodatkowania = przychód - składki ZUS społeczne - strata z lat ubiegłych → Podstawa
else :=   {"matched":true,"rule_id":"jdg.ryc.a11.r1","package":"jdg.micro.ryc","priority":3004,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa opodatkowania = przychód - składki ZUS społeczne - strata z lat ubiegłych","_legal_basis":"Art. 11 ust. 1 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Podstawa opodatkowania = przychód - składki ZUS społeczne - strata z lat ubiegłych"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a11.r2 — `lump_sum_base_cannot_be_negative`: Podstawa opodatkowania >= 0 (nie może być ujemna) → Minimum 0
else :=   {"matched":true,"rule_id":"jdg.ryc.a11.r2","package":"jdg.micro.ryc","priority":3005,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa opodatkowania >= 0 (nie może być ujemna)","_legal_basis":"Art. 11 ust. 2 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Podstawa opodatkowania >= 0 (nie może być ujemna)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a11.r3 — `lump_sum_base_revenue_by_rate_fraction`: Przychód przypisany do poszczególnych stawek ryczałtu (gdy wiele stawek) → Alokacja stawek
else :=   {"matched":true,"rule_id":"jdg.ryc.a11.r3","package":"jdg.micro.ryc","priority":3006,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przychód przypisany do poszczególnych stawek ryczałtu (gdy wiele stawek)","_legal_basis":"Art. 11 ust. 3 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Przychód przypisany do poszczególnych stawek ryczałtu (gdy wiele stawek)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a11.r4 — `lump_sum_base_zus_deduction_order`: ZUS społeczne odliczane od przychodu z tej działalności (nie od innej) → Przynależność
else :=   {"matched":true,"rule_id":"jdg.ryc.a11.r4","package":"jdg.micro.ryc","priority":3007,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"ZUS społeczne odliczane od przychodu z tej działalności (nie od innej)","_legal_basis":"Art. 11 ust. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] ZUS społeczne odliczane od przychodu z tej działalności (nie od innej)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a11.r5 — `lump_sum_base_zus_unpaid_not_deducted`: Niezapłacone składki ZUS -> nie odlicza się (nawet jeśli wykazane w DRA) → Warunek zapłaty
else :=   {"matched":true,"rule_id":"jdg.ryc.a11.r5","package":"jdg.micro.ryc","priority":3008,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niezapłacone składki ZUS -> nie odlicza się (nawet jeśli wykazane w DRA)","_legal_basis":"Art. 11 ust. 5 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Niezapłacone składki ZUS -> nie odlicza się (nawet jeśli wykazane w DRA)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a11.r6 — `lump_sum_base_zus_deduction_in_period`: Składka ZUS odliczana w miesiącu zapłaty → Data zapłaty
else :=   {"matched":true,"rule_id":"jdg.ryc.a11.r6","package":"jdg.micro.ryc","priority":3009,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Składka ZUS odliczana w miesiącu zapłaty","_legal_basis":"Art. 11 ust. 6 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Składka ZUS odliczana w miesiącu zapłaty"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a12.r1 — `lump_sum_rate_17_freelance`: Wolne zawody: lekarze, adwokaci, radcowie, architekci, inżynierowie, tłumacze → 17%
else :=   {"matched":true,"rule_id":"jdg.ryc.a12.r1","package":"jdg.micro.ryc","priority":3010,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wolne zawody: lekarze, adwokaci, radcowie, architekci, inżynierowie, tłumacze","_legal_basis":"Art. 12 ust. 1 pkt 1","_warnings":["[MICRO] Wolne zawody: lekarze, adwokaci, radcowie, architekci, inżynierowie, tłumacze"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a12.r10 — `lump_sum_rate_3_gastronomy`: Działalność gastronomiczna (bez sprzedaży alkoholu) → 3%
else :=   {"matched":true,"rule_id":"jdg.ryc.a12.r10","package":"jdg.micro.ryc","priority":3011,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Działalność gastronomiczna (bez sprzedaży alkoholu)","_legal_basis":"Art. 12 ust. 1 pkt 7","_warnings":["[MICRO] Działalność gastronomiczna (bez sprzedaży alkoholu)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a12.r2 — `lump_sum_rate_15_agency`: Działalność agencyjna, brokerska, dealerska → 15%
else :=   {"matched":true,"rule_id":"jdg.ryc.a12.r2","package":"jdg.micro.ryc","priority":3012,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Działalność agencyjna, brokerska, dealerska","_legal_basis":"Art. 12 ust. 1 pkt 2","_warnings":["[MICRO] Działalność agencyjna, brokerska, dealerska"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a12.r3 — `lump_sum_rate_14_programming`: Usługi IT: programowanie, analiza, projektowanie systemów (PKD 62.01) → 14%
else :=   {"matched":true,"rule_id":"jdg.ryc.a12.r3","package":"jdg.micro.ryc","priority":3013,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usługi IT: programowanie, analiza, projektowanie systemów (PKD 62.01)","_legal_basis":"Art. 12 ust. 1 pkt 2b","_warnings":["[MICRO] Usługi IT: programowanie, analiza, projektowanie systemów (PKD 62.01)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a12.r4 — `lump_sum_rate_12_software`: Tworzenie oprogramowania: software house (PKD 62.02), doradztwo IT (PKD 62.03) → 12%
else :=   {"matched":true,"rule_id":"jdg.ryc.a12.r4","package":"jdg.micro.ryc","priority":3014,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Tworzenie oprogramowania: software house (PKD 62.02), doradztwo IT (PKD 62.03)","_legal_basis":"Art. 12 ust. 1 pkt 2a","_warnings":["[MICRO] Tworzenie oprogramowania: software house (PKD 62.02), doradztwo IT (PKD 62.03)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a12.r5 — `lump_sum_rate_10_construction`: Usługi budowlane (PKD 41-43) → 10%
else :=   {"matched":true,"rule_id":"jdg.ryc.a12.r5","package":"jdg.micro.ryc","priority":3015,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usługi budowlane (PKD 41-43)","_legal_basis":"Art. 12 ust. 1 pkt 3","_warnings":["[MICRO] Usługi budowlane (PKD 41-43)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a12.r6 — `lump_sum_rate_8_5_other_services`: Pozostałe usługi, handel hurtowy i detaliczny, transport, gastronomia → 8.5%
else :=   {"matched":true,"rule_id":"jdg.ryc.a12.r6","package":"jdg.micro.ryc","priority":3016,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pozostałe usługi, handel hurtowy i detaliczny, transport, gastronomia","_legal_basis":"Art. 12 ust. 1 pkt 5","_warnings":["[MICRO] Pozostałe usługi, handel hurtowy i detaliczny, transport, gastronomia"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a12.r7 — `lump_sum_rate_8_5_rental_under_100k`: Najem prywatny (poza JDG) do 100 000 PLN przychodu -> 8.5% → 8.5% (I próg)
else :=   {"matched":true,"rule_id":"jdg.ryc.a12.r7","package":"jdg.micro.ryc","priority":3017,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Najem prywatny (poza JDG) do 100 000 PLN przychodu -> 8.5%","_legal_basis":"Art. 12 ust. 1 pkt 5 lit. a","_warnings":["[MICRO] Najem prywatny (poza JDG) do 100 000 PLN przychodu -> 8.5%"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a12.r8 — `lump_sum_rate_12_5_rental_over_100k`: Najem prywatny (poza JDG) > 100 000 PLN -> 12.5% od nadwyżki → 12.5% (II próg)
else :=   {"matched":true,"rule_id":"jdg.ryc.a12.r8","package":"jdg.micro.ryc","priority":3018,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Najem prywatny (poza JDG) > 100 000 PLN -> 12.5% od nadwyżki","_legal_basis":"Art. 12 ust. 1 pkt 6","_warnings":["[MICRO] Najem prywatny (poza JDG) > 100 000 PLN -> 12.5% od nadwyżki"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a12.r9 — `lump_sum_rate_5_5_manufacturing`: Działalność wytwórcza, budowlana (z materiałami) → 5.5%
else :=   {"matched":true,"rule_id":"jdg.ryc.a12.r9","package":"jdg.micro.ryc","priority":3019,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Działalność wytwórcza, budowlana (z materiałami)","_legal_basis":"Art. 12 ust. 1 pkt 4","_warnings":["[MICRO] Działalność wytwórcza, budowlana (z materiałami)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a14.r1 — `lump_sum_deduction_zus_paid`: Odliczenie składek ZUS społecznych zapłaconych w roku podatkowym → Maksymalnie do wysokości przychodu
else :=   {"matched":true,"rule_id":"jdg.ryc.a14.r1","package":"jdg.micro.ryc","priority":3020,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie składek ZUS społecznych zapłaconych w roku podatkowym","_legal_basis":"Art. 14 ust. 1 pkt 1","_warnings":["[MICRO] Odliczenie składek ZUS społecznych zapłaconych w roku podatkowym"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a14.r10 — `lump_sum_deduction_zus_overlimit_carry`: ZUS odliczony > przychód -> nadwyżka przepada (nie przenosi się) → Przepadnięcie nadwyżki
else :=   {"matched":true,"rule_id":"jdg.ryc.a14.r10","package":"jdg.micro.ryc","priority":3021,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"ZUS odliczony > przychód -> nadwyżka przepada (nie przenosi się)","_legal_basis":"Art. 14 ust. 8","_warnings":["[MICRO] ZUS odliczony > przychód -> nadwyżka przepada (nie przenosi się)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a14.r2 — `lump_sum_deduction_loss_50pct`: Strata z ryczałtu z lat ubiegłych: max 50% straty rocznie → Limit roczny
else :=   {"matched":true,"rule_id":"jdg.ryc.a14.r2","package":"jdg.micro.ryc","priority":3022,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Strata z ryczałtu z lat ubiegłych: max 50% straty rocznie","_legal_basis":"Art. 14 ust. 1 pkt 2","_warnings":["[MICRO] Strata z ryczałtu z lat ubiegłych: max 50% straty rocznie"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a14.r3 — `lump_sum_deduction_loss_carry_5y`: Strata z ryczałtu może być odliczana przez 5 kolejnych lat → 5 lat carry-forward
else :=   {"matched":true,"rule_id":"jdg.ryc.a14.r3","package":"jdg.micro.ryc","priority":3023,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Strata z ryczałtu może być odliczana przez 5 kolejnych lat","_legal_basis":"Art. 14 ust. 1 pkt 2","_warnings":["[MICRO] Strata z ryczałtu może być odliczana przez 5 kolejnych lat"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a14.r4 — `lump_sum_deduction_health_4_9pct`: Skladka zdrowotna (4.9%) odliczana od ryczałtu (miesięcznie, nie więcej niż zapłacona) → Odliczenie od podatku
else :=   {"matched":true,"rule_id":"jdg.ryc.a14.r4","package":"jdg.micro.ryc","priority":3024,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skladka zdrowotna (4.9%) odliczana od ryczałtu (miesięcznie, nie więcej niż zapłacona)","_legal_basis":"Art. 14 ust. 2","_warnings":["[MICRO] Skladka zdrowotna (4.9%) odliczana od ryczałtu (miesięcznie, nie więcej niż zapłacona)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a14.r5 — `lump_sum_deduction_health_annual_cap`: Roczne odliczenie składki zdrowotnej nie może przekroczyć podatku → Limit roczny
else :=   {"matched":true,"rule_id":"jdg.ryc.a14.r5","package":"jdg.micro.ryc","priority":3025,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roczne odliczenie składki zdrowotnej nie może przekroczyć podatku","_legal_basis":"Art. 14 ust. 3","_warnings":["[MICRO] Roczne odliczenie składki zdrowotnej nie może przekroczyć podatku"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a14.r6 — `lump_sum_deduction_health_carry_no`: Niewykorzystana część składki zdrowotnej przepada (nie przechodzi na następny rok) → Przepadnięcie
else :=   {"matched":true,"rule_id":"jdg.ryc.a14.r6","package":"jdg.micro.ryc","priority":3026,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niewykorzystana część składki zdrowotnej przepada (nie przechodzi na następny rok)","_legal_basis":"Art. 14 ust. 4","_warnings":["[MICRO] Niewykorzystana część składki zdrowotnej przepada (nie przechodzi na następny rok)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a14.r7 — `lump_sum_deduction_order_items`: Kolejność: 1) straty, 2) ZUS, 3) składka zdrowotna → Kolejność
else :=   {"matched":true,"rule_id":"jdg.ryc.a14.r7","package":"jdg.micro.ryc","priority":3027,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kolejność: 1) straty, 2) ZUS, 3) składka zdrowotna","_legal_basis":"Art. 14 ust. 5","_warnings":["[MICRO] Kolejność: 1) straty, 2) ZUS, 3) składka zdrowotna"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a14.r8 — `lump_sum_deduction_no_other_reliefs`: Ryczałt: brak innych ulg (B+R, termo, internet, rehabilitacja) → Brak ulg
else :=   {"matched":true,"rule_id":"jdg.ryc.a14.r8","package":"jdg.micro.ryc","priority":3028,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczałt: brak innych ulg (B+R, termo, internet, rehabilitacja)","_legal_basis":"Art. 14 ust. 6","_warnings":["[MICRO] Ryczałt: brak innych ulg (B+R, termo, internet, rehabilitacja)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a14.r9 — `lump_sum_deduction_zus_unpaid_reversal`: ZUS opłacony po terminie -> odliczenie w miesiącu zapłaty → Data zapłaty
else :=   {"matched":true,"rule_id":"jdg.ryc.a14.r9","package":"jdg.micro.ryc","priority":3029,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"ZUS opłacony po terminie -> odliczenie w miesiącu zapłaty","_legal_basis":"Art. 14 ust. 7","_warnings":["[MICRO] ZUS opłacony po terminie -> odliczenie w miesiącu zapłaty"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a16.r1 — `lump_sum_spouse_joint_settlement`: Małżonkowie mogą rozliczyć ryczałt oddzielnie (każde z osobna) → Odrębne rozliczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a16.r1","package":"jdg.micro.ryc","priority":3030,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Małżonkowie mogą rozliczyć ryczałt oddzielnie (każde z osobna)","_legal_basis":"Art. 16 ust. 1","_warnings":["[MICRO] Małżonkowie mogą rozliczyć ryczałt oddzielnie (każde z osobna)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a16.r2 — `lump_sum_spouse_separate_election`: Każdy małżonek może wybrać inną formę opodatkowania (np. ryczałt + skala) → Dowolność wyboru
else :=   {"matched":true,"rule_id":"jdg.ryc.a16.r2","package":"jdg.micro.ryc","priority":3031,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Każdy małżonek może wybrać inną formę opodatkowania (np. ryczałt + skala)","_legal_basis":"Art. 16 ust. 2","_warnings":["[MICRO] Każdy małżonek może wybrać inną formę opodatkowania (np. ryczałt + skala)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a16.r3 — `lump_sum_spouse_shared_business`: Małżonkowie prowadzący działalność wspólnie (spółka cywilna) → Każdy opodatkowany osobno
else :=   {"matched":true,"rule_id":"jdg.ryc.a16.r3","package":"jdg.micro.ryc","priority":3032,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Małżonkowie prowadzący działalność wspólnie (spółka cywilna)","_legal_basis":"Art. 16 ust. 3","_warnings":["[MICRO] Małżonkowie prowadzący działalność wspólnie (spółka cywilna)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a16.r4 — `lump_sum_spouse_rental_joint`: Małżonkowie współwłaściciele wynajmowanej nieruchomości → Każdy płaci ryczałt od swojego udziału
else :=   {"matched":true,"rule_id":"jdg.ryc.a16.r4","package":"jdg.micro.ryc","priority":3033,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Małżonkowie współwłaściciele wynajmowanej nieruchomości","_legal_basis":"Art. 16 ust. 4","_warnings":["[MICRO] Małżonkowie współwłaściciele wynajmowanej nieruchomości"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a16.r5 — `lump_sum_spouse_rental_income_split`: Przychód z najmu dzielony po 50% na małżonków (chyba że inny udział) → Podział przychodu
else :=   {"matched":true,"rule_id":"jdg.ryc.a16.r5","package":"jdg.micro.ryc","priority":3034,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przychód z najmu dzielony po 50% na małżonków (chyba że inny udział)","_legal_basis":"Art. 16 ust. 5","_warnings":["[MICRO] Przychód z najmu dzielony po 50% na małżonków (chyba że inny udział)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a2.r1 — `lump_sum_eligible_entrepreneur`: Osoba fizyczna prowadzaca JDG moze wybrac ryczalt → Mozliwosc
else :=   {"matched":true,"rule_id":"jdg.ryc.a2.r1","package":"jdg.micro.ryc","priority":3035,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Osoba fizyczna prowadzaca JDG moze wybrac ryczalt","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Osoba fizyczna prowadzaca JDG moze wybrac ryczalt"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a2.r10 — `lump_sum_excluded_multi_member_companies`: Wykluczone: wspolnik sp. jawnej, komandytowej, czlonek zarzadu → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a2.r10","package":"jdg.micro.ryc","priority":3036,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykluczone: wspolnik sp. jawnej, komandytowej, czlonek zarzadu","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Wykluczone: wspolnik sp. jawnej, komandytowej, czlonek zarzadu"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a2.r11 — `lump_sum_excluded_tax_capital_groups`: Wykluczone: podatnikowe grupy kapitalowe (nie dotyczy JDG) → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a2.r11","package":"jdg.micro.ryc","priority":3037,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykluczone: podatnikowe grupy kapitalowe (nie dotyczy JDG)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Wykluczone: podatnikowe grupy kapitalowe (nie dotyczy JDG)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a2.r12 — `lump_sum_excluded_partnerships`: Wykluczone: spolki (JDG moze, ale nie w formie spolki) → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a2.r12","package":"jdg.micro.ryc","priority":3038,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykluczone: spolki (JDG moze, ale nie w formie spolki)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Wykluczone: spolki (JDG moze, ale nie w formie spolki)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a2.r13 — `lump_sum_eligible_software_development`: Tworzenie oprogramowania (software house) → Stawka 12% (PKD 62.02)
else :=   {"matched":true,"rule_id":"jdg.ryc.a2.r13","package":"jdg.micro.ryc","priority":3039,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Tworzenie oprogramowania (software house)","_legal_basis":"Art. 2 ust. 1, Art. 12 ust. 1 pkt 2a","_warnings":["[MICRO] Tworzenie oprogramowania (software house)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a2.r14 — `lump_sum_eligible_construction`: Usługi budowlane (PKD 41-43) → Stawka 10%
else :=   {"matched":true,"rule_id":"jdg.ryc.a2.r14","package":"jdg.micro.ryc","priority":3040,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usługi budowlane (PKD 41-43)","_legal_basis":"Art. 2 ust. 1, Art. 12 ust. 1 pkt 3","_warnings":["[MICRO] Usługi budowlane (PKD 41-43)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a2.r15 — `lump_sum_eligible_retail_manufacturing`: Działalność handlowa, wytwórcza, usługi (pozostałe) → Stawka 8.5% (handel) / 5.5% (budownictwo z mat.)
else :=   {"matched":true,"rule_id":"jdg.ryc.a2.r15","package":"jdg.micro.ryc","priority":3041,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Działalność handlowa, wytwórcza, usługi (pozostałe)","_legal_basis":"Art. 2 ust. 1, Art. 12 ust. 1 pkt 5/4","_warnings":["[MICRO] Działalność handlowa, wytwórcza, usługi (pozostałe)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a2.r2 — `lump_sum_eligible_scope_all_revenue`: Przychody z dzialalnosci gospodarczej (wszystkie PKD) → Zakres
else :=   {"matched":true,"rule_id":"jdg.ryc.a2.r2","package":"jdg.micro.ryc","priority":3042,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przychody z dzialalnosci gospodarczej (wszystkie PKD)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Przychody z dzialalnosci gospodarczej (wszystkie PKD)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a2.r3 — `lump_sum_excluded_services_former_employer`: Wykluczone: uslugi na rzecz bylnego pracodawcy (te same co na etacie) → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a2.r3","package":"jdg.micro.ryc","priority":3043,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykluczone: uslugi na rzecz bylnego pracodawcy (te same co na etacie)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Wykluczone: uslugi na rzecz bylnego pracodawcy (te same co na etacie)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a2.r4 — `lump_sum_excluded_lawyers`: Wykluczone: adwokaci, radcowie prawni, notariusze, doradcy podatkowi → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a2.r4","package":"jdg.micro.ryc","priority":3044,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykluczone: adwokaci, radcowie prawni, notariusze, doradcy podatkowi","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Wykluczone: adwokaci, radcowie prawni, notariusze, doradcy podatkowi"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a2.r5 — `lump_sum_excluded_pharmacies`: Wykluczone: apteki (nie dotyczy) → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a2.r5","package":"jdg.micro.ryc","priority":3045,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykluczone: apteki (nie dotyczy)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Wykluczone: apteki (nie dotyczy)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a2.r6 — `lump_sum_excluded_architects_engineers`: Wykluczone: architekci, inzynierowie budownictwa (nie dotyczy) → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a2.r6","package":"jdg.micro.ryc","priority":3046,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykluczone: architekci, inzynierowie budownictwa (nie dotyczy)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Wykluczone: architekci, inzynierowie budownictwa (nie dotyczy)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a2.r7 — `lump_sum_excluded_healthcare_self_employed`: Wykluczone: osoby swiadczace uslugi medyczne (z wyjatkami) → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a2.r7","package":"jdg.micro.ryc","priority":3047,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykluczone: osoby swiadczace uslugi medyczne (z wyjatkami)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Wykluczone: osoby swiadczace uslugi medyczne (z wyjatkami)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a2.r8 — `lump_sum_excluded_restaurants_bars`: Wykluczone: restauracje, bary, catering (nie dotyczy) → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a2.r8","package":"jdg.micro.ryc","priority":3048,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykluczone: restauracje, bary, catering (nie dotyczy)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Wykluczone: restauracje, bary, catering (nie dotyczy)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a2.r9 — `lump_sum_excluded_retirement_pensioners`: Wykluczone: JDG na emeryturze/rencie (opcjonalnie) → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a2.r9","package":"jdg.micro.ryc","priority":3049,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykluczone: JDG na emeryturze/rencie (opcjonalnie)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Wykluczone: JDG na emeryturze/rencie (opcjonalnie)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a20.r1 — `lump_sum_evidence_revenue_register`: Obowiązek prowadzenia ewidencji przychodów (uproszczona) → Ewidencja przychodów
else :=   {"matched":true,"rule_id":"jdg.ryc.a20.r1","package":"jdg.micro.ryc","priority":3050,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiązek prowadzenia ewidencji przychodów (uproszczona)","_legal_basis":"Art. 20 ust. 1","_warnings":["[MICRO] Obowiązek prowadzenia ewidencji przychodów (uproszczona)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a20.r10 — `lump_sum_evidence_storage_5_years`: Ewidencję przechowuje się 5 lat od końca roku podatkowego → Okres przechowywania
else :=   {"matched":true,"rule_id":"jdg.ryc.a20.r10","package":"jdg.micro.ryc","priority":3051,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ewidencję przechowuje się 5 lat od końca roku podatkowego","_legal_basis":"Art. 20 ust. 10","_warnings":["[MICRO] Ewidencję przechowuje się 5 lat od końca roku podatkowego"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a20.r2 — `lump_sum_evidence_revenue_by_rate`: Ewidencja przychodów w podziale na stawki ryczałtu (gdy wiele stawek) → Podział wg stawek
else :=   {"matched":true,"rule_id":"jdg.ryc.a20.r2","package":"jdg.micro.ryc","priority":3052,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ewidencja przychodów w podziale na stawki ryczałtu (gdy wiele stawek)","_legal_basis":"Art. 20 ust. 2","_warnings":["[MICRO] Ewidencja przychodów w podziale na stawki ryczałtu (gdy wiele stawek)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a20.r3 — `lump_sum_evidence_daily_revenue`: Przychód wpisywany do ewidencji na bieżąco (dzień po dniu) → Ewidencja na bieżąco
else :=   {"matched":true,"rule_id":"jdg.ryc.a20.r3","package":"jdg.micro.ryc","priority":3053,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przychód wpisywany do ewidencji na bieżąco (dzień po dniu)","_legal_basis":"Art. 20 ust. 3","_warnings":["[MICRO] Przychód wpisywany do ewidencji na bieżąco (dzień po dniu)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a20.r4 — `lump_sum_evidence_revenue_no_cost`: W ewidencji: data, kwota, stawka (NIE ma kolumny kosztów) → Brak KUP w ewidencji
else :=   {"matched":true,"rule_id":"jdg.ryc.a20.r4","package":"jdg.micro.ryc","priority":3054,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"W ewidencji: data, kwota, stawka (NIE ma kolumny kosztów)","_legal_basis":"Art. 20 ust. 4","_warnings":["[MICRO] W ewidencji: data, kwota, stawka (NIE ma kolumny kosztów)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a20.r5 — `lump_sum_evidence_electronic_allowed`: Ewidencja w formie elektronicznej (np. Excel, program) → Forma dowolna
else :=   {"matched":true,"rule_id":"jdg.ryc.a20.r5","package":"jdg.micro.ryc","priority":3055,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ewidencja w formie elektronicznej (np. Excel, program)","_legal_basis":"Art. 20 ust. 5","_warnings":["[MICRO] Ewidencja w formie elektronicznej (np. Excel, program)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a20.r6 — `lump_sum_evidence_vat_register`: Obowiązek prowadzenia ewidencji VAT (JPK_V7) dla czynnych podatników VAT → Dodatkowa ewidencja VAT
else :=   {"matched":true,"rule_id":"jdg.ryc.a20.r6","package":"jdg.micro.ryc","priority":3056,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiązek prowadzenia ewidencji VAT (JPK_V7) dla czynnych podatników VAT","_legal_basis":"Art. 20 ust. 6","_warnings":["[MICRO] Obowiązek prowadzenia ewidencji VAT (JPK_V7) dla czynnych podatników VAT"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a20.r7 — `lump_sum_evidence_inventory_required`: Obowiązek spisu z natury na 1 stycznia (remanent początkowy) → Remanent
else :=   {"matched":true,"rule_id":"jdg.ryc.a20.r7","package":"jdg.micro.ryc","priority":3057,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiązek spisu z natury na 1 stycznia (remanent początkowy)","_legal_basis":"Art. 20 ust. 7","_warnings":["[MICRO] Obowiązek spisu z natury na 1 stycznia (remanent początkowy)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a20.r8 — `lump_sum_evidence_inventory_december`: Spis z natury na 31 grudnia (remanent końcowy) → Remanent końcowy
else :=   {"matched":true,"rule_id":"jdg.ryc.a20.r8","package":"jdg.micro.ryc","priority":3058,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Spis z natury na 31 grudnia (remanent końcowy)","_legal_basis":"Art. 20 ust. 8","_warnings":["[MICRO] Spis z natury na 31 grudnia (remanent końcowy)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a20.r9 — `lump_sum_evidence_inventory_on_loss`: Przy utracie ryczałtu: remanent na dzień utraty → Obowiązek remanentu
else :=   {"matched":true,"rule_id":"jdg.ryc.a20.r9","package":"jdg.micro.ryc","priority":3059,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przy utracie ryczałtu: remanent na dzień utraty","_legal_basis":"Art. 20 ust. 9","_warnings":["[MICRO] Przy utracie ryczałtu: remanent na dzień utraty"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a21.r1 — `lump_sum_evidence_rental_separate`: Najem prywatny: odrębna ewidencja przychodów z najmu → Odrębna ewidencja
else :=   {"matched":true,"rule_id":"jdg.ryc.a21.r1","package":"jdg.micro.ryc","priority":3060,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Najem prywatny: odrębna ewidencja przychodów z najmu","_legal_basis":"Art. 21 ust. 1","_warnings":["[MICRO] Najem prywatny: odrębna ewidencja przychodów z najmu"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a21.r2 — `lump_sum_evidence_rental_shared_ownership`: Współwłasność: każdy współwłaściciel prowadzi ewidencję odrębnie → Odrębność
else :=   {"matched":true,"rule_id":"jdg.ryc.a21.r2","package":"jdg.micro.ryc","priority":3061,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Współwłasność: każdy współwłaściciel prowadzi ewidencję odrębnie","_legal_basis":"Art. 21 ust. 2","_warnings":["[MICRO] Współwłasność: każdy współwłaściciel prowadzi ewidencję odrębnie"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a21.r3 — `lump_sum_evidence_rental_income_recognition`: Przychód z najmu w dacie otrzymania zapłaty (metoda kasowa) → Data zapłaty
else :=   {"matched":true,"rule_id":"jdg.ryc.a21.r3","package":"jdg.micro.ryc","priority":3062,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przychód z najmu w dacie otrzymania zapłaty (metoda kasowa)","_legal_basis":"Art. 21 ust. 3","_warnings":["[MICRO] Przychód z najmu w dacie otrzymania zapłaty (metoda kasowa)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a21.r4 — `lump_sum_evidence_rental_advance`: Zaliczka na najem -> przychód w dacie otrzymania zaliczki → Zaliczka = przychód
else :=   {"matched":true,"rule_id":"jdg.ryc.a21.r4","package":"jdg.micro.ryc","priority":3063,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaliczka na najem -> przychód w dacie otrzymania zaliczki","_legal_basis":"Art. 21 ust. 4","_warnings":["[MICRO] Zaliczka na najem -> przychód w dacie otrzymania zaliczki"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a21.r5 — `lump_sum_evidence_rental_deposit`: Kaucja nie stanowi przychodu (zwrot kaucji nie jest kosztem) → Kaucja neutralna
else :=   {"matched":true,"rule_id":"jdg.ryc.a21.r5","package":"jdg.micro.ryc","priority":3064,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kaucja nie stanowi przychodu (zwrot kaucji nie jest kosztem)","_legal_basis":"Art. 21 ust. 5","_warnings":["[MICRO] Kaucja nie stanowi przychodu (zwrot kaucji nie jest kosztem)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a24.r1 — `lump_sum_zus_social_deduction_monthly`: Odliczenie ZUS społecznych od przychodu każdego miesiąca → Miesięczne odliczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a24.r1","package":"jdg.micro.ryc","priority":3065,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie ZUS społecznych od przychodu każdego miesiąca","_legal_basis":"Art. 24 ust. 1","_warnings":["[MICRO] Odliczenie ZUS społecznych od przychodu każdego miesiąca"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a24.r2 — `lump_sum_zus_social_deduction_limit`: Łączne odliczenie ZUS nie może przekroczyć przychodu za dany okres → Limit
else :=   {"matched":true,"rule_id":"jdg.ryc.a24.r2","package":"jdg.micro.ryc","priority":3066,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Łączne odliczenie ZUS nie może przekroczyć przychodu za dany okres","_legal_basis":"Art. 24 ust. 2","_warnings":["[MICRO] Łączne odliczenie ZUS nie może przekroczyć przychodu za dany okres"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a24.r3 — `lump_sum_zus_health_deduction_calc`: Odliczenie ZUS zdrowotnej: 4.9% lub 9% podstawy (w zależności od okresu) → Obliczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a24.r3","package":"jdg.micro.ryc","priority":3067,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie ZUS zdrowotnej: 4.9% lub 9% podstawy (w zależności od okresu)","_legal_basis":"Art. 24 ust. 3","_warnings":["[MICRO] Odliczenie ZUS zdrowotnej: 4.9% lub 9% podstawy (w zależności od okresu)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a25.r1 — `lump_sum_advance_monthly_20th`: Zaliczka miesięczna -> do 20. dnia następnego miesiąca → Termin
else :=   {"matched":true,"rule_id":"jdg.ryc.a25.r1","package":"jdg.micro.ryc","priority":3068,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaliczka miesięczna -> do 20. dnia następnego miesiąca","_legal_basis":"Art. 25 ust. 1","_warnings":["[MICRO] Zaliczka miesięczna -> do 20. dnia następnego miesiąca"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a25.r2 — `lump_sum_advance_calculation`: Zaliczka = przychód x stawka - składka zdrowotna (4.9%) → Obliczenie zaliczki
else :=   {"matched":true,"rule_id":"jdg.ryc.a25.r2","package":"jdg.micro.ryc","priority":3069,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaliczka = przychód x stawka - składka zdrowotna (4.9%)","_legal_basis":"Art. 25 ust. 2","_warnings":["[MICRO] Zaliczka = przychód x stawka - składka zdrowotna (4.9%)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a25.r3 — `lump_sum_advance_if_zero_below_zero`: Zaliczka <= 0 -> nie wpłaca się → Brak zaliczki
else :=   {"matched":true,"rule_id":"jdg.ryc.a25.r3","package":"jdg.micro.ryc","priority":3070,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaliczka <= 0 -> nie wpłaca się","_legal_basis":"Art. 25 ust. 3","_warnings":["[MICRO] Zaliczka <= 0 -> nie wpłaca się"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a25.r4 — `lump_sum_annual_deadline_28_feb`: PIT-28 do 28 lutego następnego roku (ważne: wcześniejszy niż PIT-36/36L!) → Termin roczny
else :=   {"matched":true,"rule_id":"jdg.ryc.a25.r4","package":"jdg.micro.ryc","priority":3071,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"PIT-28 do 28 lutego następnego roku (ważne: wcześniejszy niż PIT-36/36L!)","_legal_basis":"Art. 25 ust. 4","_warnings":["[MICRO] PIT-28 do 28 lutego następnego roku (ważne: wcześniejszy niż PIT-36/36L!)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a25.r5 — `lump_sum_annual_income_calc`: Podatek roczny = roczny przychód (net) x stawka - zapłacone zaliczki → Obliczenie roczne
else :=   {"matched":true,"rule_id":"jdg.ryc.a25.r5","package":"jdg.micro.ryc","priority":3072,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatek roczny = roczny przychód (net) x stawka - zapłacone zaliczki","_legal_basis":"Art. 25 ust. 5","_warnings":["[MICRO] Podatek roczny = roczny przychód (net) x stawka - zapłacone zaliczki"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a25.r6 — `lump_sum_annual_difference_refund`: Nadpłata -> zwrot w 45 dni od złożenia PIT-28 → Zwrot nadpłaty
else :=   {"matched":true,"rule_id":"jdg.ryc.a25.r6","package":"jdg.micro.ryc","priority":3073,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nadpłata -> zwrot w 45 dni od złożenia PIT-28","_legal_basis":"Art. 25 ust. 6","_warnings":["[MICRO] Nadpłata -> zwrot w 45 dni od złożenia PIT-28"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a25.r7 — `lump_sum_annual_late_penalty`: Po terminie -> odsetki za zwłokę → Odsetki
else :=   {"matched":true,"rule_id":"jdg.ryc.a25.r7","package":"jdg.micro.ryc","priority":3074,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Po terminie -> odsetki za zwłokę","_legal_basis":"Art. 25 ust. 7","_warnings":["[MICRO] Po terminie -> odsetki za zwłokę"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a3.r1 — `lump_sum_selection_deadline_20_january`: Wybor ryczaltu: oswiadczenie do 20 stycznia roku podatkowego → Termin
else :=   {"matched":true,"rule_id":"jdg.ryc.a3.r1","package":"jdg.micro.ryc","priority":3075,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wybor ryczaltu: oswiadczenie do 20 stycznia roku podatkowego","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Wybor ryczaltu: oswiadczenie do 20 stycznia roku podatkowego"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a3.r2 — `lump_sum_selection_new_business_first_year`: Nowa JDG: oswiadczenie przy rejestracji (lub do 20 dnia miesiaca po pierwszym przychodzie) → Nowa dzialalnosc
else :=   {"matched":true,"rule_id":"jdg.ryc.a3.r2","package":"jdg.micro.ryc","priority":3076,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nowa JDG: oswiadczenie przy rejestracji (lub do 20 dnia miesiaca po pierwszym przychodzie)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Nowa JDG: oswiadczenie przy rejestracji (lub do 20 dnia miesiaca po pierwszym przychodzie)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a3.r3 — `lump_sum_selection_loss_of_right`: Utrata prawa do ryczaltu w trakcie roku -> przejscie na skale od nastepnego miesiaca → Utrata
else :=   {"matched":true,"rule_id":"jdg.ryc.a3.r3","package":"jdg.micro.ryc","priority":3077,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Utrata prawa do ryczaltu w trakcie roku -> przejscie na skale od nastepnego miesiaca","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Utrata prawa do ryczaltu w trakcie roku -> przejscie na skale od nastepnego miesiaca"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a4.r1 — `lump_sum_definition_revenue`: Przychód dla ryczałtu: kwoty należne (bez VAT) — nawet nieotrzymane → Definicja przychodu
else :=   {"matched":true,"rule_id":"jdg.ryc.a4.r1","package":"jdg.micro.ryc","priority":3078,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przychód dla ryczałtu: kwoty należne (bez VAT) — nawet nieotrzymane","_legal_basis":"Art. 4 ust. 1 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Przychód dla ryczałtu: kwoty należne (bez VAT) — nawet nieotrzymane"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a4.r10 — `lump_sum_definition_net_of_vat`: Przychód w wartości netto (bez VAT, nawet gdy VAT jest należny) → Wartość netto
else :=   {"matched":true,"rule_id":"jdg.ryc.a4.r10","package":"jdg.micro.ryc","priority":3079,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przychód w wartości netto (bez VAT, nawet gdy VAT jest należny)","_legal_basis":"Art. 4 ust. 6 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Przychód w wartości netto (bez VAT, nawet gdy VAT jest należny)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a4.r2 — `lump_sum_definition_revenue_cash`: Dla ryczałtu: przychód w dacie wystawienia faktury lub 25. dnia miesiąca od wykonania usługi → Moment przychodu
else :=   {"matched":true,"rule_id":"jdg.ryc.a4.r2","package":"jdg.micro.ryc","priority":3080,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dla ryczałtu: przychód w dacie wystawienia faktury lub 25. dnia miesiąca od wykonania usługi","_legal_basis":"Art. 4 ust. 2 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Dla ryczałtu: przychód w dacie wystawienia faktury lub 25. dnia miesiąca od wykonania usługi"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a4.r3 — `lump_sum_definition_cost_not_applicable`: Ryczałt: brak kosztów uzyskania przychodu (nie dotyczy) → KUP = 0
else :=   {"matched":true,"rule_id":"jdg.ryc.a4.r3","package":"jdg.micro.ryc","priority":3081,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczałt: brak kosztów uzyskania przychodu (nie dotyczy)","_legal_basis":"Art. 4 ust. 3 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Ryczałt: brak kosztów uzyskania przychodu (nie dotyczy)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a4.r4 — `lump_sum_definition_deductions_allowed`: Ryczałt: odliczenia od przychodu (ZUS, straty z lat ubiegłych — tylko z ryczałtu) → Katalog odliczeń
else :=   {"matched":true,"rule_id":"jdg.ryc.a4.r4","package":"jdg.micro.ryc","priority":3082,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczałt: odliczenia od przychodu (ZUS, straty z lat ubiegłych — tylko z ryczałtu)","_legal_basis":"Art. 4 ust. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Ryczałt: odliczenia od przychodu (ZUS, straty z lat ubiegłych — tylko z ryczałtu)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a4.r5 — `lump_sum_definition_zus_deduction`: Składki ZUS społeczne opłacone w roku podatkowym odlicza się od przychodu → Odliczenie ZUS
else :=   {"matched":true,"rule_id":"jdg.ryc.a4.r5","package":"jdg.micro.ryc","priority":3083,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Składki ZUS społeczne opłacone w roku podatkowym odlicza się od przychodu","_legal_basis":"Art. 4 ust. 4 pkt 1 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Składki ZUS społeczne opłacone w roku podatkowym odlicza się od przychodu"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a4.r6 — `lump_sum_definition_health_deduction`: Skladka zdrowotna (4.9%) odliczana od podatku (nie od przychodu) → Odliczenie od podatku
else :=   {"matched":true,"rule_id":"jdg.ryc.a4.r6","package":"jdg.micro.ryc","priority":3084,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skladka zdrowotna (4.9%) odliczana od podatku (nie od przychodu)","_legal_basis":"Art. 4 ust. 4 pkt 2 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Skladka zdrowotna (4.9%) odliczana od podatku (nie od przychodu)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a4.r7 — `lump_sum_definition_loss_from_previous`: Strata z lat ubiegłych z ryczałtu — odliczana od przychodu (50%/rok, 5 lat) → Odliczenie straty
else :=   {"matched":true,"rule_id":"jdg.ryc.a4.r7","package":"jdg.micro.ryc","priority":3085,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Strata z lat ubiegłych z ryczałtu — odliczana od przychodu (50%/rok, 5 lat)","_legal_basis":"Art. 4 ust. 4 pkt 3 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Strata z lat ubiegłych z ryczałtu — odliczana od przychodu (50%/rok, 5 lat)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a4.r8 — `lump_sum_definition_loss_only_from_ryc`: Strata może być odliczona tylko od przychodu z ryczałtu (nie z innych form) → Tylko ryczałt
else :=   {"matched":true,"rule_id":"jdg.ryc.a4.r8","package":"jdg.micro.ryc","priority":3086,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Strata może być odliczona tylko od przychodu z ryczałtu (nie z innych form)","_legal_basis":"Art. 4 ust. 4 pkt 3 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Strata może być odliczona tylko od przychodu z ryczałtu (nie z innych form)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a4.r9 — `lump_sum_definition_write_off_order`: Kolejność odliczeń: ZUS przed stratą, strata przed zdrowotną → Kolejność
else :=   {"matched":true,"rule_id":"jdg.ryc.a4.r9","package":"jdg.micro.ryc","priority":3087,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kolejność odliczeń: ZUS przed stratą, strata przed zdrowotną","_legal_basis":"Art. 4 ust. 5 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Kolejność odliczeń: ZUS przed stratą, strata przed zdrowotną"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a6.r10 — `lump_sum_exclusion_medical_services`: Usługi medyczne (lekarz, dentysta, pielęgniarka) — wyłączone z ryczałtu → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a6.r10","package":"jdg.micro.ryc","priority":3088,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usługi medyczne (lekarz, dentysta, pielęgniarka) — wyłączone z ryczałtu","_legal_basis":"Art. 6 ust. 1 pkt 5 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Usługi medyczne (lekarz, dentysta, pielęgniarka) — wyłączone z ryczałtu"]} {
    input.jdg_entrepreneur.tax_form != "LUMP_SUM"
}

# jdg.ryc.a6.r11 — `lump_sum_exclusion_legal_services`: Usługi prawnicze (adwokat, radca prawny) — wyłączone z ryczałtu → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a6.r11","package":"jdg.micro.ryc","priority":3089,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usługi prawnicze (adwokat, radca prawny) — wyłączone z ryczałtu","_legal_basis":"Art. 6 ust. 1 pkt 6 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Usługi prawnicze (adwokat, radca prawny) — wyłączone z ryczałtu"]} {
    input.jdg_entrepreneur.tax_form != "LUMP_SUM"
}

# jdg.ryc.a6.r12 — `lump_sum_exclusion_notary`: Notariusz — wyłączony z ryczałtu → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a6.r12","package":"jdg.micro.ryc","priority":3090,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Notariusz — wyłączony z ryczałtu","_legal_basis":"Art. 6 ust. 1 pkt 7 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Notariusz — wyłączony z ryczałtu"]} {
    input.jdg_entrepreneur.tax_form != "LUMP_SUM"
}

# jdg.ryc.a6.r13 — `lump_sum_exclusion_architect`: Architekt, inżynier budownictwa — wyłączeni z ryczałtu → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a6.r13","package":"jdg.micro.ryc","priority":3091,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Architekt, inżynier budownictwa — wyłączeni z ryczałtu","_legal_basis":"Art. 6 ust. 1 pkt 8 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Architekt, inżynier budownictwa — wyłączeni z ryczałtu"]} {
    input.jdg_entrepreneur.tax_form != "LUMP_SUM"
}

# jdg.ryc.a6.r14 — `lump_sum_exclusion_food_retail`: Sprzedaż żywności na określonych zasadach (zgodnie z przepisami) → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a6.r14","package":"jdg.micro.ryc","priority":3092,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprzedaż żywności na określonych zasadach (zgodnie z przepisami)","_legal_basis":"Art. 6 ust. 1 pkt 9 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Sprzedaż żywności na określonych zasadach (zgodnie z przepisami)"]} {
    input.jdg_entrepreneur.tax_form != "LUMP_SUM"
}

# jdg.ryc.a6.r15 — `lump_sum_exclusion_high_income`: Przekroczenie limitu 2 000 000 EUR przychodu → Wyłączenie z ryczałtu (konieczna skala/liniowy)
else :=   {"matched":true,"rule_id":"jdg.ryc.a6.r15","package":"jdg.micro.ryc","priority":3093,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przekroczenie limitu 2 000 000 EUR przychodu","_legal_basis":"Art. 6 ust. 1 pkt 10 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Przekroczenie limitu 2 000 000 EUR przychodu"]} {
    input.jdg_entrepreneur.tax_form != "LUMP_SUM"
}

# jdg.ryc.a6.r6 — `lump_sum_exclusion_former_employer`: Usługi na rzecz byłego pracodawcy (takie same czynności co na etacie) → Wyłączenie z ryczałtu — konieczna skala/liniowy
else :=   {"matched":true,"rule_id":"jdg.ryc.a6.r6","package":"jdg.micro.ryc","priority":3094,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usługi na rzecz byłego pracodawcy (takie same czynności co na etacie)","_legal_basis":"Art. 6 ust. 1 pkt 1 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Usługi na rzecz byłego pracodawcy (takie same czynności co na etacie)"]} {
    input.jdg_entrepreneur.tax_form != "LUMP_SUM"
}

# jdg.ryc.a6.r7 — `lump_sum_exclusion_former_employer_prev_year`: Przychody od byłego pracodawcy >50% przychodów z działalności w poprzednim roku → Wyłączenie z ryczałtu
else :=   {"matched":true,"rule_id":"jdg.ryc.a6.r7","package":"jdg.micro.ryc","priority":3095,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przychody od byłego pracodawcy >50% przychodów z działalności w poprzednim roku","_legal_basis":"Art. 6 ust. 1 pkt 1 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Przychody od byłego pracodawcy >50% przychodów z działalności w poprzednim roku"]} {
    input.jdg_entrepreneur.tax_form != "LUMP_SUM"
}

# jdg.ryc.a6.r8 — `lump_sum_exclusion_apothecary`: Apteki — wyłączone z ryczałtu → Konieczna skala lub liniowy
else :=   {"matched":true,"rule_id":"jdg.ryc.a6.r8","package":"jdg.micro.ryc","priority":3096,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Apteki — wyłączone z ryczałtu","_legal_basis":"Art. 6 ust. 1 pkt 3 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Apteki — wyłączone z ryczałtu"]} {
    input.jdg_entrepreneur.tax_form != "LUMP_SUM"
}

# jdg.ryc.a6.r9 — `lump_sum_exclusion_tax_consulting`: Usługi doradztwa podatkowego, księgowego (doradca podatkowy) → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.ryc.a6.r9","package":"jdg.micro.ryc","priority":3097,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usługi doradztwa podatkowego, księgowego (doradca podatkowy)","_legal_basis":"Art. 6 ust. 1 pkt 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Usługi doradztwa podatkowego, księgowego (doradca podatkowy)"]} {
    input.jdg_entrepreneur.tax_form != "LUMP_SUM"
}

# jdg.ryc.a7.r1 — `lump_sum_loss_of_right_revenue_exceed`: Przekroczenie 2M EUR przychodu w trakcie roku → Utrata ryczałtu od miesiąca przekroczenia
else :=   {"matched":true,"rule_id":"jdg.ryc.a7.r1","package":"jdg.micro.ryc","priority":3098,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przekroczenie 2M EUR przychodu w trakcie roku","_legal_basis":"Art. 7 ust. 1 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Przekroczenie 2M EUR przychodu w trakcie roku"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a7.r2 — `lump_sum_loss_of_right_former_employer`: Przekroczenie 50% przychodów od byłego pracodawcy → Utrata ryczałtu od początku roku
else :=   {"matched":true,"rule_id":"jdg.ryc.a7.r2","package":"jdg.micro.ryc","priority":3099,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przekroczenie 50% przychodów od byłego pracodawcy","_legal_basis":"Art. 7 ust. 2 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Przekroczenie 50% przychodów od byłego pracodawcy"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a7.r3 — `lump_sum_loss_of_right_automatic_scale`: Utrata ryczałtu -> automatyczne przejście na skalę podatkową → Skala podatkowa
else :=   {"matched":true,"rule_id":"jdg.ryc.a7.r3","package":"jdg.micro.ryc","priority":3100,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Utrata ryczałtu -> automatyczne przejście na skalę podatkową","_legal_basis":"Art. 7 ust. 3 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Utrata ryczałtu -> automatyczne przejście na skalę podatkową"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a7.r4 — `lump_sum_loss_of_right_income_tax`: Obowiązek zapłaty odsetek od zaległości (od miesiąca utraty) → Odsetki
else :=   {"matched":true,"rule_id":"jdg.ryc.a7.r4","package":"jdg.micro.ryc","priority":3101,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiązek zapłaty odsetek od zaległości (od miesiąca utraty)","_legal_basis":"Art. 7 ust. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Obowiązek zapłaty odsetek od zaległości (od miesiąca utraty)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a7.r5 — `lump_sum_loss_of_right_inventory_required`: Utrata -> obowiązek spisu remanentu na dzień utraty → Remanent
else :=   {"matched":true,"rule_id":"jdg.ryc.a7.r5","package":"jdg.micro.ryc","priority":3102,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Utrata -> obowiązek spisu remanentu na dzień utraty","_legal_basis":"Art. 7 ust. 5 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Utrata -> obowiązek spisu remanentu na dzień utraty"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a8.r1 — `lump_sum_election_declaration_by_20_jan`: Oświadczenie o wyborze ryczałtu na dany rok do 20 stycznia → Termin wyboru
else :=   {"matched":true,"rule_id":"jdg.ryc.a8.r1","package":"jdg.micro.ryc","priority":3103,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Oświadczenie o wyborze ryczałtu na dany rok do 20 stycznia","_legal_basis":"Art. 8 ust. 1 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Oświadczenie o wyborze ryczałtu na dany rok do 20 stycznia"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a8.r2 — `lump_sum_election_first_year_30_days`: Nowa JDG: oświadczenie w 30 dni od rozpoczęcia działalności → Termin dla nowej firmy
else :=   {"matched":true,"rule_id":"jdg.ryc.a8.r2","package":"jdg.micro.ryc","priority":3104,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nowa JDG: oświadczenie w 30 dni od rozpoczęcia działalności","_legal_basis":"Art. 8 ust. 2 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Nowa JDG: oświadczenie w 30 dni od rozpoczęcia działalności"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a8.r3 — `lump_sum_election_new_form`: Oświadczenie składane do US właściwego dla siedziby (CEIDG) → Forma oświadczenia
else :=   {"matched":true,"rule_id":"jdg.ryc.a8.r3","package":"jdg.micro.ryc","priority":3105,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Oświadczenie składane do US właściwego dla siedziby (CEIDG)","_legal_basis":"Art. 8 ust. 3 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Oświadczenie składane do US właściwego dla siedziby (CEIDG)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a8.r4 — `lump_sum_election_automatic_continuation`: Brak zmiany -> domniemanie kontynuacji ryczałtu → Kontynuacja
else :=   {"matched":true,"rule_id":"jdg.ryc.a8.r4","package":"jdg.micro.ryc","priority":3106,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak zmiany -> domniemanie kontynuacji ryczałtu","_legal_basis":"Art. 8 ust. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Brak zmiany -> domniemanie kontynuacji ryczałtu"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.a8.r5 — `lump_sum_election_change_to_scale_anytime`: Zmiana z ryczałtu na skalę w trakcie roku -> tylko od początku następnego roku → Blokada zmiany w roku
else :=   {"matched":true,"rule_id":"jdg.ryc.a8.r5","package":"jdg.micro.ryc","priority":3107,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana z ryczałtu na skalę w trakcie roku -> tylko od początku następnego roku","_legal_basis":"Art. 8 ust. 5 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":["[MICRO] Zmiana z ryczałtu na skalę w trakcie roku -> tylko od początku następnego roku"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r1 — `lump_tax_revenue_minus_zus`: Podstawa = przychod - skladki ZUS spoleczne zaplacone w roku → Obliczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r1","package":"jdg.micro.ryc","priority":3108,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa = przychod - skladki ZUS spoleczne zaplacone w roku","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Podstawa = przychod - skladki ZUS spoleczne zaplacone w roku"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r10 — `lump_tax_no_rd_innovation_reliefs`: Ryczalt: brak dostepu do ulgi B+R, IP Box, prototyp, robotyzacja → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r10","package":"jdg.micro.ryc","priority":3109,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczalt: brak dostepu do ulgi B+R, IP Box, prototyp, robotyzacja","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Ryczalt: brak dostepu do ulgi B+R, IP Box, prototyp, robotyzacja"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r11 — `lump_tax_donation_relief_possible`: Darowizny: odliczenie od przychodu (do 6% przychodu) → Mozliwosc
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r11","package":"jdg.micro.ryc","priority":3110,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Darowizny: odliczenie od przychodu (do 6% przychodu)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Darowizny: odliczenie od przychodu (do 6% przychodu)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r12 — `lump_tax_donation_opp_6pct_gross`: Darowizny na OPP: 6% przychodu (nie dochodu) → Limit
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r12","package":"jdg.micro.ryc","priority":3111,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Darowizny na OPP: 6% przychodu (nie dochodu)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Darowizny na OPP: 6% przychodu (nie dochodu)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r13 — `lump_tax_advance_monthly_20th`: Zaliczki miesieczne do 20. dnia nastepnego miesiaca → Termin
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r13","package":"jdg.micro.ryc","priority":3112,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaliczki miesieczne do 20. dnia nastepnego miesiaca","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Zaliczki miesieczne do 20. dnia nastepnego miesiaca"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r14 — `lump_tax_advance_zero_gross_below_zus`: Zaliczka = 0 gdy przychod < skladki ZUS zaplacone → Zerowa
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r14","package":"jdg.micro.ryc","priority":3113,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaliczka = 0 gdy przychod < skladki ZUS zaplacone","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Zaliczka = 0 gdy przychod < skladki ZUS zaplacone"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r15 — `lump_tax_annual_return_PIT_28`: Zeznanie roczne PIT-28 do 30 kwietnia → Deklaracja
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r15","package":"jdg.micro.ryc","priority":3114,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zeznanie roczne PIT-28 do 30 kwietnia","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Zeznanie roczne PIT-28 do 30 kwietnia"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r16 — `lump_tax_annual_return_no_loss`: W PIT-28: brak KUP, brak straty -> tylko przychod i podatek → Uproszczone
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r16","package":"jdg.micro.ryc","priority":3115,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"W PIT-28: brak KUP, brak straty -> tylko przychod i podatek","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] W PIT-28: brak KUP, brak straty -> tylko przychod i podatek"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r17 — `lump_tax_annual_return_multiple_rates_annex`: Gdy JDG ma przychody w roznych stawkach -> zalacznik PIT-28/A → Zalacznik
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r17","package":"jdg.micro.ryc","priority":3116,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Gdy JDG ma przychody w roznych stawkach -> zalacznik PIT-28/A","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Gdy JDG ma przychody w roznych stawkach -> zalacznik PIT-28/A"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r18 — `lump_tax_change_from_lump_during_year`: Zmiana z ryczaltu na skale -> od nastepnego miesiaca po utracie prawa → Zmiana
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r18","package":"jdg.micro.ryc","priority":3117,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana z ryczaltu na skale -> od nastepnego miesiaca po utracie prawa","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Zmiana z ryczaltu na skale -> od nastepnego miesiaca po utracie prawa"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r19 — `lump_tax_revenue_book_required`: Ewidencja przychodow (uproszczona): kolumny: data, przychod, stawka, podatek → Ewidencja
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r19","package":"jdg.micro.ryc","priority":3118,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ewidencja przychodow (uproszczona): kolumny: data, przychod, stawka, podatek","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Ewidencja przychodow (uproszczona): kolumny: data, przychod, stawka, podatek"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r2 — `lump_tax_revenue_x_rate`: Podatek = podstawa x stawka ryczaltu (brak KUP, brak kwoty wolnej) → Formula
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r2","package":"jdg.micro.ryc","priority":3119,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatek = podstawa x stawka ryczaltu (brak KUP, brak kwoty wolnej)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Podatek = podstawa x stawka ryczaltu (brak KUP, brak kwoty wolnej)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r20 — `lump_tax_revenue_book_storage_5_years`: Ewidencja przechowywana 5 lat → Retencja
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r20","package":"jdg.micro.ryc","priority":3120,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ewidencja przechowywana 5 lat","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Ewidencja przechowywana 5 lat"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r3 — `lump_tax_deduction_health_7_75`: Odliczenie skladki zdrowotnej 7.75% (dla ryczaltu od 2022: 50% zaplaconej) → Odliczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r3","package":"jdg.micro.ryc","priority":3121,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie skladki zdrowotnej 7.75% (dla ryczaltu od 2022: 50% zaplaconej)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Odliczenie skladki zdrowotnej 7.75% (dla ryczaltu od 2022: 50% zaplaconej)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r4 — `lump_tax_50pct_health_deduction`: Ryczalt: odliczenie 50% zaplaconej skladki zdrowotnej (od 2022) → Nowa zasada
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r4","package":"jdg.micro.ryc","priority":3122,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczalt: odliczenie 50% zaplaconej skladki zdrowotnej (od 2022)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Ryczalt: odliczenie 50% zaplaconej skladki zdrowotnej (od 2022)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r5 — `lump_tax_no_health_deduction_future`: Odliczenie skladki zdrowotnej w ryczalcie stopniowo wygaszane (2026+) → Trend
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r5","package":"jdg.micro.ryc","priority":3123,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie skladki zdrowotnej w ryczalcie stopniowo wygaszane (2026+)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Odliczenie skladki zdrowotnej w ryczalcie stopniowo wygaszane (2026+)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r6 — `lump_tax_no_loss_settlement`: Ryczalt NIE pozwala na rozliczanie straty → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r6","package":"jdg.micro.ryc","priority":3124,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczalt NIE pozwala na rozliczanie straty","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Ryczalt NIE pozwala na rozliczanie straty"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r7 — `lump_tax_no_joint_settlement`: Ryczalt NIE pozwala na wspolne rozliczenie z malzonkiem → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r7","package":"jdg.micro.ryc","priority":3125,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczalt NIE pozwala na wspolne rozliczenie z malzonkiem","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Ryczalt NIE pozwala na wspolne rozliczenie z malzonkiem"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r8 — `lump_tax_no_tax_free_amount`: Ryczalt: brak kwoty wolnej od podatku → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r8","package":"jdg.micro.ryc","priority":3126,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczalt: brak kwoty wolnej od podatku","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Ryczalt: brak kwoty wolnej od podatku"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.calc.r9 — `lump_tax_no_children_relief`: Ryczalt: ulga na dzieci tylko jako non-refundable (odliczenie od podatku) → Ograniczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.calc.r9","package":"jdg.micro.ryc","priority":3127,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryczalt: ulga na dzieci tylko jako non-refundable (odliczenie od podatku)","_legal_basis":"Ustawa o ryczałcie z 20.11.1998 (Dz.U. 2025 poz. 234)","_warnings":["[MICRO] Ryczalt: ulga na dzieci tylko jako non-refundable (odliczenie od podatku)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r1 — `lump_rate_17pct_wolne_zawody`: Wolne zawody (lekarze, dentyci, weterynarze, architekci, inzynierowie, tlumacze) → 17%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r1","package":"jdg.micro.ryc","priority":3128,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wolne zawody (lekarze, dentyci, weterynarze, architekci, inzynierowie, tlumacze)","_legal_basis":"Art. 12 ust. 1 pkt 5","_warnings":["[MICRO] Wolne zawody (lekarze, dentyci, weterynarze, architekci, inzynierowie, tlumacze)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r10 — `lump_rate_14pct_it_consulting_excluded`: Wylaczone: doradztwo informatyczne (17%) → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r10","package":"jdg.micro.ryc","priority":3129,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wylaczone: doradztwo informatyczne (17%)","_legal_basis":"Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.) — Stawki","_warnings":["[MICRO] Wylaczone: doradztwo informatyczne (17%)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r11 — `lump_rate_14pct_it_support`: Uslugi zwiazane z oprogramowaniem: pomoc techniczna, hosting, utrzymanie → 14%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r11","package":"jdg.micro.ryc","priority":3130,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Uslugi zwiazane z oprogramowaniem: pomoc techniczna, hosting, utrzymanie","_legal_basis":"Art. 12 ust. 1 pkt 3b","_warnings":["[MICRO] Uslugi zwiazane z oprogramowaniem: pomoc techniczna, hosting, utrzymanie"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r12 — `lump_rate_14pct_data_processing`:  → 14%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r12","package":"jdg.micro.ryc","priority":3131,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"","_legal_basis":"Art. 12 ust. 1 pkt 3b","_warnings":["[MICRO] Uslugi zwiazane z oprogramowaniem: pomoc techniczna, hosting, utrzymanie"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r13 — `lump_rate_12pct_rental_property`: Najem nieruchomosci (prywatny, nie w ramach JDG) → 12%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r13","package":"jdg.micro.ryc","priority":3132,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Najem nieruchomosci (prywatny, nie w ramach JDG)","_legal_basis":"Art. 12 ust. 1 pkt 3a","_warnings":["[MICRO] Najem nieruchomosci (prywatny, nie w ramach JDG)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r14 — `lump_rate_12pct_rental_movable`: Najem ruchomosci (sprzetu, pojazdow) → 12%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r14","package":"jdg.micro.ryc","priority":3133,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Najem ruchomosci (sprzetu, pojazdow)","_legal_basis":"Art. 12 ust. 1 pkt 3a","_warnings":["[MICRO] Najem ruchomosci (sprzetu, pojazdow)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r15 — `lump_rate_12pct_commission_agency`: Dzialalnosc agencyjna, komisowa, maklerska (nie nieruchomosci) → 12%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r15","package":"jdg.micro.ryc","priority":3134,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dzialalnosc agencyjna, komisowa, maklerska (nie nieruchomosci)","_legal_basis":"Art. 12 ust. 1 pkt 3a","_warnings":["[MICRO] Dzialalnosc agencyjna, komisowa, maklerska (nie nieruchomosci)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r16 — `lump_rate_10pct_restaurants_catering`: Uslugi gastronomiczne, catering, bary → 10%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r16","package":"jdg.micro.ryc","priority":3135,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Uslugi gastronomiczne, catering, bary","_legal_basis":"Art. 12 ust. 1 pkt 3","_warnings":["[MICRO] Uslugi gastronomiczne, catering, bary"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r17 — `lump_rate_10pct_hairdressing_beauty`: Uslugi fryzjerskie, kosmetyczne, pielęgnacyjne → 10%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r17","package":"jdg.micro.ryc","priority":3136,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Uslugi fryzjerskie, kosmetyczne, pielęgnacyjne","_legal_basis":"Art. 12 ust. 1 pkt 3","_warnings":["[MICRO] Uslugi fryzjerskie, kosmetyczne, pielęgnacyjne"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r18 — `lump_rate_10pct_transport_passenger_goods`: Transport pasazerski i towarowy (taxi, dostawy) → 10%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r18","package":"jdg.micro.ryc","priority":3137,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Transport pasazerski i towarowy (taxi, dostawy)","_legal_basis":"Art. 12 ust. 1 pkt 3","_warnings":["[MICRO] Transport pasazerski i towarowy (taxi, dostawy)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r19 — `lump_rate_10pct_education_training`: Uslugi edukacyjne, szkoleniowe (pozostale) → 10%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r19","package":"jdg.micro.ryc","priority":3138,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Uslugi edukacyjne, szkoleniowe (pozostale)","_legal_basis":"Art. 12 ust. 1 pkt 3","_warnings":["[MICRO] Uslugi edukacyjne, szkoleniowe (pozostale)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r2 — `lump_rate_17pct_developers_maklersi`:  → 17%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r2","package":"jdg.micro.ryc","priority":3139,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"","_legal_basis":"Art. 12 ust. 1 pkt 5","_warnings":["[MICRO] Uslugi edukacyjne, szkoleniowe (pozostale)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r20 — `lump_rate_10pct_healthcare_outpatient`: Opieka medyczna ambulatoryjna (lekarze specjalisci) → 10%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r20","package":"jdg.micro.ryc","priority":3140,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Opieka medyczna ambulatoryjna (lekarze specjalisci)","_legal_basis":"Art. 12 ust. 1 pkt 3","_warnings":["[MICRO] Opieka medyczna ambulatoryjna (lekarze specjalisci)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r21 — `lump_rate_8_5pct_manufacturing`: Dzialalnosc wytworcza, produkcja przemyslowa → 8.5%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r21","package":"jdg.micro.ryc","priority":3141,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dzialalnosc wytworcza, produkcja przemyslowa","_legal_basis":"Art. 12 ust. 1 pkt 2","_warnings":["[MICRO] Dzialalnosc wytworcza, produkcja przemyslowa"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r22 — `lump_rate_8_5pct_construction_building`: Roboty budowlane (budowa, remont, modernizacja) → 8.5%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r22","package":"jdg.micro.ryc","priority":3142,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roboty budowlane (budowa, remont, modernizacja)","_legal_basis":"Art. 12 ust. 1 pkt 2","_warnings":["[MICRO] Roboty budowlane (budowa, remont, modernizacja)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r23 — `lump_rate_8_5pct_trade_wholesale`: Handel hurtowy → 8.5%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r23","package":"jdg.micro.ryc","priority":3143,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Handel hurtowy","_legal_basis":"Art. 12 ust. 1 pkt 2","_warnings":["[MICRO] Handel hurtowy"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r24 — `lump_rate_8_5pct_trade_retail`: Handel detaliczny → 8.5%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r24","package":"jdg.micro.ryc","priority":3144,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Handel detaliczny","_legal_basis":"Art. 12 ust. 1 pkt 2","_warnings":["[MICRO] Handel detaliczny"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r25 — `lump_rate_8_5pct_tourism_hotel`: Uslugi hotelarskie, turystyczne, noclegowe → 8.5%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r25","package":"jdg.micro.ryc","priority":3145,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Uslugi hotelarskie, turystyczne, noclegowe","_legal_basis":"Art. 12 ust. 1 pkt 2","_warnings":["[MICRO] Uslugi hotelarskie, turystyczne, noclegowe"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r26 — `lump_rate_5_5pct_agriculture`: Dzialalnosc rolnicza, lesna, rybacka (nie bedaca dzialem specjalnym) → 5.5%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r26","package":"jdg.micro.ryc","priority":3146,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dzialalnosc rolnicza, lesna, rybacka (nie bedaca dzialem specjalnym)","_legal_basis":"Art. 12 ust. 1 pkt 1","_warnings":["[MICRO] Dzialalnosc rolnicza, lesna, rybacka (nie bedaca dzialem specjalnym)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r27 — `lump_rate_5_5pct_manufacturing_agricultural`:  → 5.5%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r27","package":"jdg.micro.ryc","priority":3147,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"","_legal_basis":"Art. 12 ust. 1 pkt 1","_warnings":["[MICRO] Dzialalnosc rolnicza, lesna, rybacka (nie bedaca dzialem specjalnym)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r28 — `lump_rate_3pct_trade_food`: Handel artykulami spozywczymi (sklepy spozywcze, warzywniaki) → 3%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r28","package":"jdg.micro.ryc","priority":3148,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Handel artykulami spozywczymi (sklepy spozywcze, warzywniaki)","_legal_basis":"Art. 12 ust. 1 pkt 1a","_warnings":["[MICRO] Handel artykulami spozywczymi (sklepy spozywcze, warzywniaki)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r29 — `lump_rate_2pct_services_online_casino`: Uslugi swiadczone elektronicznie (gry, zaklady online, streaming) → 2%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r29","package":"jdg.micro.ryc","priority":3149,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Uslugi swiadczone elektronicznie (gry, zaklady online, streaming)","_legal_basis":"Art. 12 ust. 1 pkt 0a","_warnings":["[MICRO] Uslugi swiadczone elektronicznie (gry, zaklady online, streaming)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r3 — `lump_rate_17pct_tax_advisors_accountants`: Doradztwo podatkowe, ksiegowosc, rachunkowosc → 17%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r3","package":"jdg.micro.ryc","priority":3150,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Doradztwo podatkowe, ksiegowosc, rachunkowosc","_legal_basis":"Art. 12 ust. 1 pkt 5","_warnings":["[MICRO] Doradztwo podatkowe, ksiegowosc, rachunkowosc"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r30 — `lump_rate_standard_exception_rule`: Jesli brak PKD na liscie -> stawka 12% (standard) → Domyslna 12%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r30","package":"jdg.micro.ryc","priority":3151,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Jesli brak PKD na liscie -> stawka 12% (standard)","_legal_basis":"Art. 12 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.) — Stawki","_warnings":["[MICRO] Jesli brak PKD na liscie -> stawka 12% (standard)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r4 — `lump_rate_17pct_it_consulting`: Doradztwo informatyczne, zarzadcze, biznesowe → 17%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r4","package":"jdg.micro.ryc","priority":3152,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Doradztwo informatyczne, zarzadcze, biznesowe","_legal_basis":"Art. 12 ust. 1 pkt 5","_warnings":["[MICRO] Doradztwo informatyczne, zarzadcze, biznesowe"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r5 — `lump_rate_15pct_repair_maintenance`: Naprawa i konserwacja pojazdow, maszyn, urzadzen → 15%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r5","package":"jdg.micro.ryc","priority":3153,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Naprawa i konserwacja pojazdow, maszyn, urzadzen","_legal_basis":"Art. 12 ust. 1 pkt 4","_warnings":["[MICRO] Naprawa i konserwacja pojazdow, maszyn, urzadzen"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r6 — `lump_rate_15pct_construction_works`: Roboty budowlane, montaz, instalacje → 15%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r6","package":"jdg.micro.ryc","priority":3154,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roboty budowlane, montaz, instalacje","_legal_basis":"Art. 12 ust. 1 pkt 4","_warnings":["[MICRO] Roboty budowlane, montaz, instalacje"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r7 — `lump_rate_15pct_cleaning_services`: Uslugi sprzatania, czyszczenia, dezynfekcji → 15%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r7","package":"jdg.micro.ryc","priority":3155,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Uslugi sprzatania, czyszczenia, dezynfekcji","_legal_basis":"Art. 12 ust. 1 pkt 4","_warnings":["[MICRO] Uslugi sprzatania, czyszczenia, dezynfekcji"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r8 — `lump_rate_15pct_know_how_licenses`:  → 15%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r8","package":"jdg.micro.ryc","priority":3156,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"","_legal_basis":"Art. 12 ust. 1 pkt 4","_warnings":["[MICRO] Uslugi sprzatania, czyszczenia, dezynfekcji"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.ryc.rate.r9 — `lump_rate_14pct_it_programming`: Uslugi zwiazane z oprogramowaniem (programowanie, projektowanie stron) → 14%
else :=   {"matched":true,"rule_id":"jdg.ryc.rate.r9","package":"jdg.micro.ryc","priority":3157,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Uslugi zwiazane z oprogramowaniem (programowanie, projektowanie stron)","_legal_basis":"Art. 12 ust. 1 pkt 3b","_warnings":["[MICRO] Uslugi zwiazane z oprogramowaniem (programowanie, projektowanie stron)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}
