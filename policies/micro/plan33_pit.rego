# Generated from Plan OPA 33 — Micro-rules for pit
# 2026-07-13 14:58:41
# Rules: 86 (new, deduplicated)

package jdg.micro.pit.plan33

import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.micro.pit.plan33.no_match","package":"jdg.micro.pit.plan33","priority":99999}

# jdg.pit.a14.r10 — `revenue_exclusion_mandate_return`: Zwrot wydatków poniesionych w imieniu mandanta — NIE przychód → Wyłączenie
decide :=   {"matched":true,"rule_id":"jdg.pit.a14.r10","package":"jdg.micro.pit.plan33","priority":1200,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwrot wydatków poniesionych w imieniu mandanta — NIE przychód","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":["[MICRO] Zwrot wydatków poniesionych w imieniu mandanta — NIE przychód"]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14.r11 — `revenue_exclusion_deposit`: Otrzymana kaucja, depozyt, gwarancja — NIE przychód → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r11","package":"jdg.micro.pit.plan33","priority":1201,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Otrzymana kaucja, depozyt, gwarancja — NIE przychód","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":["[MICRO] Otrzymana kaucja, depozyt, gwarancja — NIE przychód"]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14.r12 — `revenue_exclusion_donation_goods`: Nieodpłatne otrzymanie towarów — NIE przychód do czasu sprzedaży → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r12","package":"jdg.micro.pit.plan33","priority":1202,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nieodpłatne otrzymanie towarów — NIE przychód do czasu sprzedaży","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":["[MICRO] Nieodpłatne otrzymanie towarów — NIE przychód do czasu sprzedaży"]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "expense_type", "") == "DONATION"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14.r15 — `revenue_foreign_currency_payment_conversion`: Wpływ waluty na rachunek walutowy — kurs z dnia wpływu → Kurs
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r15","package":"jdg.micro.pit.plan33","priority":1203,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wpływ waluty na rachunek walutowy — kurs z dnia wpływu","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":["[MICRO] Wpływ waluty na rachunek walutowy — kurs z dnia wpływu"]} {
    object.get(input.invoice, "direction", "") == "SALE"; input.invoice.currency != "PLN"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14.r17 — `revenue_bad_debt_write_off`: Nieściągalne należności — NIE pomniejszają przychodu (wyjątek: strata) → Skutek
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r17","package":"jdg.micro.pit.plan33","priority":1204,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nieściągalne należności — NIE pomniejszają przychodu (wyjątek: strata)","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":["[MICRO] Nieściągalne należności — NIE pomniejszają przychodu (wyjątek: strata)"]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14.r18 — `revenue_subcontractor_division`: Przychód pomniejszony o koszt podwykonawcy (w przypadku usług budowlanych) → Specjalna zasada
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r18","package":"jdg.micro.pit.plan33","priority":1205,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przychód pomniejszony o koszt podwykonawcy (w przypadku usług budowlanych)","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":["[MICRO] Przychód pomniejszony o koszt podwykonawcy (w przypadku usług budowlanych)"]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14.r19 — `revenue_taxable_gratis_benefits`: Nieodpłatne świadczenia (użycie firmowego auta, telefonu na cele prywatne) → Przychód
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r19","package":"jdg.micro.pit.plan33","priority":1206,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nieodpłatne świadczenia (użycie firmowego auta, telefonu na cele prywatne)","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":["[MICRO] Nieodpłatne świadczenia (użycie firmowego auta, telefonu na cele prywatne)"]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14.r4 — `revenue_exclusions_definition`: Nie wszystkie wpływy są przychodem (Art. 14 ust. 3) → Lista wyłączeń
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r4","package":"jdg.micro.pit.plan33","priority":1207,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nie wszystkie wpływy są przychodem (Art. 14 ust. 3)","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":["[MICRO] Nie wszystkie wpływy są przychodem (Art. 14 ust. 3)"]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14.r9 — `revenue_exclusion_compensation_loss_profits`: Odszkodowanie za utracone przychody — stanowi przychód → Przychód
else :=   {"matched":true,"rule_id":"jdg.pit.a14.r9","package":"jdg.micro.pit.plan33","priority":1208,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odszkodowanie za utracone przychody — stanowi przychód","_legal_basis":"Art. 14 PIT — Przychody z działalności gospodarczej","_warnings":["[MICRO] Odszkodowanie za utracone przychody — stanowi przychód"]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a14c.r10 — `fx_difference_bank_account_conversion`: Przeliczenie waluty z rachunku walutowego na PLN przy wypłacie → Realizacja FX
else :=   {"matched":true,"rule_id":"jdg.pit.a14c.r10","package":"jdg.micro.pit.plan33","priority":1209,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przeliczenie waluty z rachunku walutowego na PLN przy wypłacie","_legal_basis":"Art. 14c PIT — Różnice kursowe","_warnings":["[MICRO] Przeliczenie waluty z rachunku walutowego na PLN przy wypłacie"]} {
    input.invoice.currency != "PLN"
}

# jdg.pit.a14c.r3 — `fx_difference_realized_cost_income`: Koszt (PURCHASE): kurs > kurs faktury → ujemna FX = KUP → FX od kosztów
else :=   {"matched":true,"rule_id":"jdg.pit.a14c.r3","package":"jdg.micro.pit.plan33","priority":1210,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszt (PURCHASE): kurs > kurs faktury → ujemna FX = KUP","_legal_basis":"Art. 14c PIT — Różnice kursowe","_warnings":["[MICRO] Koszt (PURCHASE): kurs > kurs faktury → ujemna FX = KUP"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.invoice, "direction", "") == "PURCHASE"; input.invoice.currency != "PLN"
}

# jdg.pit.a14c.r4 — `fx_difference_realized_cost_expense`: Koszt (PURCHASE): kurs < kurs faktury → dodatnia FX = przychód → FX od kosztów
else :=   {"matched":true,"rule_id":"jdg.pit.a14c.r4","package":"jdg.micro.pit.plan33","priority":1211,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszt (PURCHASE): kurs < kurs faktury → dodatnia FX = przychód","_legal_basis":"Art. 14c PIT — Różnice kursowe","_warnings":["[MICRO] Koszt (PURCHASE): kurs < kurs faktury → dodatnia FX = przychód"]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "direction", "") == "PURCHASE"; input.invoice.currency != "PLN"
}

# jdg.pit.a14c.r6 — `fx_difference_method_kursowa`: Metoda kursowa (Art. 24c PIT): wycena na koniec okresu → Metoda alternatywna
else :=   {"matched":true,"rule_id":"jdg.pit.a14c.r6","package":"jdg.micro.pit.plan33","priority":1212,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Metoda kursowa (Art. 24c PIT): wycena na koniec okresu","_legal_basis":"Art. 14c PIT — Różnice kursowe","_warnings":["[MICRO] Metoda kursowa (Art. 24c PIT): wycena na koniec okresu"]} {
    input.invoice.currency != "PLN"
}

# jdg.pit.a14c.r8 — `fx_difference_balance_sheet_rate`: Kurs NBP z ostatniego dnia roboczego poprzedzającego dzień bilansowy → Kurs bilansowy
else :=   {"matched":true,"rule_id":"jdg.pit.a14c.r8","package":"jdg.micro.pit.plan33","priority":1213,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kurs NBP z ostatniego dnia roboczego poprzedzającego dzień bilansowy","_legal_basis":"Art. 14c PIT — Różnice kursowe","_warnings":["[MICRO] Kurs NBP z ostatniego dnia roboczego poprzedzającego dzień bilansowy"]} {
    input.invoice.currency != "PLN"
}

# jdg.pit.a14c.r9 — `fx_difference_payment_different_currencies`: Zapłata w innej walucie niż faktura — wycena wg kursu z dnia zapłaty → Różne waluty
else :=   {"matched":true,"rule_id":"jdg.pit.a14c.r9","package":"jdg.micro.pit.plan33","priority":1214,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zapłata w innej walucie niż faktura — wycena wg kursu z dnia zapłaty","_legal_basis":"Art. 14c PIT — Różnice kursowe","_warnings":["[MICRO] Zapłata w innej walucie niż faktura — wycena wg kursu z dnia zapłaty"]} {
    input.invoice.currency != "PLN"
}

# jdg.pit.a22.r11 — `kup_provisions_reserves`: Rezerwy, odpisy, bierne rozliczenia międzyokresowe — NIE są KUP (chyba że ustawa stanowi inaczej) → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.pit.a22.r11","package":"jdg.micro.pit.plan33","priority":1215,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rezerwy, odpisy, bierne rozliczenia międzyokresowe — NIE są KUP (chyba że ustawa stanowi inaczej)","_legal_basis":"Art. 22 PIT — Koszty uzyskania przychodów","_warnings":["[MICRO] Rezerwy, odpisy, bierne rozliczenia międzyokresowe — NIE są KUP (chyba że ustawa stanowi inaczej)"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a22.r14 — `kup_cost_of_manufacturing`: Koszt wytworzenia produktu (materiały + robocizna + koszty wydziałowe) → Wycena kosztów
else :=   {"matched":true,"rule_id":"jdg.pit.a22.r14","package":"jdg.micro.pit.plan33","priority":1216,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszt wytworzenia produktu (materiały + robocizna + koszty wydziałowe)","_legal_basis":"Art. 22 PIT — Koszty uzyskania przychodów","_warnings":["[MICRO] Koszt wytworzenia produktu (materiały + robocizna + koszty wydziałowe)"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a22.r2 — `kup_all_expenses_business`: Wszystkie koszty związane z prowadzeniem JDG (przy spełnieniu Art. 22 ust. 1) → Kwalifikacja
else :=   {"matched":true,"rule_id":"jdg.pit.a22.r2","package":"jdg.micro.pit.plan33","priority":1217,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wszystkie koszty związane z prowadzeniem JDG (przy spełnieniu Art. 22 ust. 1)","_legal_basis":"Art. 22 PIT — Koszty uzyskania przychodów","_warnings":["[MICRO] Wszystkie koszty związane z prowadzeniem JDG (przy spełnieniu Art. 22 ust. 1)"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a22.r5 — `kup_direct_not_yet_earned`: Koszty bezpośrednie poniesione przed osiągnięciem przychodu — potrącalne w roku poniesienia → Wyjątek timing
else :=   {"matched":true,"rule_id":"jdg.pit.a22.r5","package":"jdg.micro.pit.plan33","priority":1218,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszty bezpośrednie poniesione przed osiągnięciem przychodu — potrącalne w roku poniesienia","_legal_basis":"Art. 22 PIT — Koszty uzyskania przychodów","_warnings":["[MICRO] Koszty bezpośrednie poniesione przed osiągnięciem przychodu — potrącalne w roku poniesienia"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a22.r9 — `kup_unpaid_reversal_indirect`: Koszty pośrednie nieopłacone — NIE wyłącza się (kasowość nie dotyczy) → Brak wyłączenia
else :=   {"matched":true,"rule_id":"jdg.pit.a22.r9","package":"jdg.micro.pit.plan33","priority":1219,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszty pośrednie nieopłacone — NIE wyłącza się (kasowość nie dotyczy)","_legal_basis":"Art. 22 PIT — Koszty uzyskania przychodów","_warnings":["[MICRO] Koszty pośrednie nieopłacone — NIE wyłącza się (kasowość nie dotyczy)"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a23.r10 — `Składki w organizacjach dobrowolnych (nieobowiązkowe izby)`: kup_exclusion_donations_voluntary_associations
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r10","package":"jdg.micro.pit.plan33","priority":1220,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"kup_exclusion_donations_voluntary_associations","_legal_basis":"Art. 23 ust. 1 pkt 30","_warnings":["[MICRO] kup_exclusion_donations_voluntary_associations"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "expense_type", "") == "DONATION"
}

# jdg.pit.a23.r11 — `Obowiązkowe składki izb zawodowych (lekarska, adwokacka) — są KUP`: kup_exclusion_mandatory_chamber_fees
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r11","package":"jdg.micro.pit.plan33","priority":1221,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"kup_exclusion_mandatory_chamber_fees","_legal_basis":"Wyjątek (są KUP)","_warnings":["[MICRO] kup_exclusion_mandatory_chamber_fees"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r13 — `Leasing operacyjny auta >150k PLN — część raty NKUP`: kup_exclusion_car_lease_over_150k
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r13","package":"jdg.micro.pit.plan33","priority":1222,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"kup_exclusion_car_lease_over_150k","_legal_basis":"Art. 23 ust. 1 pkt 47a","_warnings":["[MICRO] kup_exclusion_car_lease_over_150k"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a23.r14 — `AC auta >150k — proporcjonalne wyłączenie (150k/wartość)`: kup_exclusion_car_insurance_proportional
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r14","package":"jdg.micro.pit.plan33","priority":1223,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"kup_exclusion_car_insurance_proportional","_legal_basis":"Art. 23 ust. 1 pkt 47a","_warnings":["[MICRO] kup_exclusion_car_insurance_proportional"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a23.r16 — `Samochód elektryczny z dotacją — limit wraca do 150 000 PLN`: kup_exclusion_car_electric_with_subsidy
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r16","package":"jdg.micro.pit.plan33","priority":1224,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"kup_exclusion_car_electric_with_subsidy","_legal_basis":"Limit 150k","_warnings":["[MICRO] kup_exclusion_car_electric_with_subsidy"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"; object.get(input.invoice, "category_code", "") == "CAR"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a23.r18 — `Wydatki mieszane (prywatne+firmowe) — tylko część firmowa KUP`: kup_exclusion_private_use_mixed
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r18","package":"jdg.micro.pit.plan33","priority":1225,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"kup_exclusion_private_use_mixed","_legal_basis":"Art. 23 ust. 1 pkt 46","_warnings":["[MICRO] kup_exclusion_private_use_mixed"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r19 — `Ubezpieczenie na życie, od następstw nieszczęśliwych wypadków (prywatne)`: kup_exclusion_personal_accident_insurance
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r19","package":"jdg.micro.pit.plan33","priority":1226,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"kup_exclusion_personal_accident_insurance","_legal_basis":"Art. 23 ust. 1 pkt 42","_warnings":["[MICRO] kup_exclusion_personal_accident_insurance"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r20 — `Ubezpieczenia pracowników (grupowe) — KUP (wyjątek od pkt 42)`: kup_exclusion_employee_insurance_except
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r20","package":"jdg.micro.pit.plan33","priority":1227,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"kup_exclusion_employee_insurance_except","_legal_basis":"Wyjątek","_warnings":["[MICRO] kup_exclusion_employee_insurance_except"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r22 — `Niezapłacone odsetki od składek ZUS (odsetki)`: kup_exclusion_zus_unpaid_arrears
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r22","package":"jdg.micro.pit.plan33","priority":1228,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"kup_exclusion_zus_unpaid_arrears","_legal_basis":"Art. 23 ust. 1 pkt 19","_warnings":["[MICRO] kup_exclusion_zus_unpaid_arrears"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r25 — `Opłata za użytkowanie wieczyste gruntu (raz w roku)`: kup_exclusion_perpetual_usufruct
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r25","package":"jdg.micro.pit.plan33","priority":1229,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"kup_exclusion_perpetual_usufruct","_legal_basis":"Art. 23 ust. 1 pkt 1","_warnings":["[MICRO] kup_exclusion_perpetual_usufruct"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r5 — `Odzież (chyba że robocza/BHP zgodnie z przepisami)`: kup_exclusion_clothing_not_bhp
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r5","package":"jdg.micro.pit.plan33","priority":1230,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"kup_exclusion_clothing_not_bhp","_legal_basis":"Art. 23 ust. 1 pkt 23","_warnings":["[MICRO] kup_exclusion_clothing_not_bhp"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r7 — `Wyjątek: kary otrzymane od dostawcy = przychód (nie KUP)`: kup_exclusion_final_exception_delivery_defects
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r7","package":"jdg.micro.pit.plan33","priority":1231,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"kup_exclusion_final_exception_delivery_defects","_legal_basis":"Art. 23 ust. 1 pkt 19","_warnings":["[MICRO] kup_exclusion_final_exception_delivery_defects"]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a23.r9 — `Umorzenie w restrukturyzacji → zwolnione z PIT, ale NIE KUP`: kup_exclusion_debts_forgiven_restructuring
else :=   {"matched":true,"rule_id":"jdg.pit.a23.r9","package":"jdg.micro.pit.plan33","priority":1232,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"kup_exclusion_debts_forgiven_restructuring","_legal_basis":"Wyjątek","_warnings":["[MICRO] kup_exclusion_debts_forgiven_restructuring"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.a26h.r6 — `Limit 53 000 PLN dotyczy wszystkich budynków (łącznie)`: Globalny limit
else :=   {"matched":true,"rule_id":"jdg.pit.a26h.r6","package":"jdg.micro.pit.plan33","priority":1233,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Globalny limit","_legal_basis":"Art. 26h PIT — Ulga termomodernizacyjna","_warnings":["[MICRO] Globalny limit"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a27.r11 — `tax_scale_single_parent`: Rozliczenie jako osoba samotnie wychowujaca dzieci → Specjalne zasady
else :=   {"matched":true,"rule_id":"jdg.pit.a27.r11","package":"jdg.micro.pit.plan33","priority":1234,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rozliczenie jako osoba samotnie wychowujaca dzieci","_legal_basis":"Art. 27 PIT — Skala podatkowa 12%/32%","_warnings":["[MICRO] Rozliczenie jako osoba samotnie wychowujaca dzieci"]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}

# jdg.pit.a27.r12 — `tax_scale_tax_calc_formula`: Podatek = (dochod * 0.12) - kwota_wolna, dla nadwyzki (dochod * 0.32) → Formula
else :=   {"matched":true,"rule_id":"jdg.pit.a27.r12","package":"jdg.micro.pit.plan33","priority":1235,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatek = (dochod * 0.12) - kwota_wolna, dla nadwyzki (dochod * 0.32)","_legal_basis":"Art. 27 PIT — Skala podatkowa 12%/32%","_warnings":["[MICRO] Podatek = (dochod * 0.12) - kwota_wolna, dla nadwyzki (dochod * 0.32)"]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
}

# jdg.pit.a27.r5 — `tax_scale_tax_free_phase_out`: Dochód > 120k -> kwota wolna wygasa liniowo do 0 → Phasing out
else :=   {"matched":true,"rule_id":"jdg.pit.a27.r5","package":"jdg.micro.pit.plan33","priority":1236,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochód > 120k -> kwota wolna wygasa liniowo do 0","_legal_basis":"Art. 27 PIT — Skala podatkowa 12%/32%","_warnings":["[MICRO] Dochód > 120k -> kwota wolna wygasa liniowo do 0"]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; input.jdg_entrepreneur.tax_form == "PIT_SCALE"; input.jdg_entrepreneur.tax_form == "PIT_SCALE"
}

# jdg.pit.a27.r6 — `tax_scale_tax_free_full_120k`: Dochód do 120k -> pelna kwota wolna 3 600 PLN → Pełne odliczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a27.r6","package":"jdg.micro.pit.plan33","priority":1237,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochód do 120k -> pelna kwota wolna 3 600 PLN","_legal_basis":"Art. 27 PIT — Skala podatkowa 12%/32%","_warnings":["[MICRO] Dochód do 120k -> pelna kwota wolna 3 600 PLN"]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; input.jdg_entrepreneur.tax_form == "PIT_SCALE"; input.jdg_entrepreneur.tax_form == "PIT_SCALE"
}

# jdg.pit.a27.r7 — `tax_scale_income_aggregation`: Laczny dochod z JDG + etat + inne zrodla → Podstawa skali
else :=   {"matched":true,"rule_id":"jdg.pit.a27.r7","package":"jdg.micro.pit.plan33","priority":1238,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Laczny dochod z JDG + etat + inne zrodla","_legal_basis":"Art. 27 PIT — Skala podatkowa 12%/32%","_warnings":["[MICRO] Laczny dochod z JDG + etat + inne zrodla"]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a27.r8 — `tax_scale_deductions_before_calc`: Odliczenia od dochodu (Art. 26) przed obliczeniem podatku → Kolejnosc
else :=   {"matched":true,"rule_id":"jdg.pit.a27.r8","package":"jdg.micro.pit.plan33","priority":1239,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenia od dochodu (Art. 26) przed obliczeniem podatku","_legal_basis":"Art. 27 PIT — Skala podatkowa 12%/32%","_warnings":["[MICRO] Odliczenia od dochodu (Art. 26) przed obliczeniem podatku"]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
}

# jdg.pit.a27.r9 — `tax_scale_tax_credits_after`: Ulgi odliczane od podatku po obliczeniu → Kolejnosc
else :=   {"matched":true,"rule_id":"jdg.pit.a27.r9","package":"jdg.micro.pit.plan33","priority":1240,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulgi odliczane od podatku po obliczeniu","_legal_basis":"Art. 27 PIT — Skala podatkowa 12%/32%","_warnings":["[MICRO] Ulgi odliczane od podatku po obliczeniu"]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
}

# jdg.pit.a27a.r10 — `child_tax_credit_non_refundable_others`: Dla liniowego/ryczaltu -> NIE jest zwracana (non-refundable) → Brak zwrotu
else :=   {"matched":true,"rule_id":"jdg.pit.a27a.r10","package":"jdg.micro.pit.plan33","priority":1241,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dla liniowego/ryczaltu -> NIE jest zwracana (non-refundable)","_legal_basis":"Art. 27f PIT — Ulga na dzieci","_warnings":["[MICRO] Dla liniowego/ryczaltu -> NIE jest zwracana (non-refundable)"]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}

# jdg.pit.a30a.r10 — `capital_income_exemption_employee_shares`: Dochody z pracowniczych programow akcyjnych → Zwolnienie
else :=   {"matched":true,"rule_id":"jdg.pit.a30a.r10","package":"jdg.micro.pit.plan33","priority":1242,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochody z pracowniczych programow akcyjnych","_legal_basis":"Art. 30a PIT — Dochody kapitałowe","_warnings":["[MICRO] Dochody z pracowniczych programow akcyjnych"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.invoice, "income_source", "") == "CAPITAL_GAINS"
}

# jdg.pit.a30a.r3 — `capital_income_bonds`: Odsetki od obligacji (skarbowych, komunalnych) → 19%
else :=   {"matched":true,"rule_id":"jdg.pit.a30a.r3","package":"jdg.micro.pit.plan33","priority":1243,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odsetki od obligacji (skarbowych, komunalnych)","_legal_basis":"Art. 30a PIT — Dochody kapitałowe","_warnings":["[MICRO] Odsetki od obligacji (skarbowych, komunalnych)"]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.invoice, "income_source", "") == "CAPITAL_GAINS"
}

# jdg.pit.a30a.r4 — `capital_income_sale_of_shares`: Zbycie akcji, udzialow, tytulow uczestnictwa → Dochód jako przychod - koszty
else :=   {"matched":true,"rule_id":"jdg.pit.a30a.r4","package":"jdg.micro.pit.plan33","priority":1244,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zbycie akcji, udzialow, tytulow uczestnictwa","_legal_basis":"Art. 30a PIT — Dochody kapitałowe","_warnings":["[MICRO] Zbycie akcji, udzialow, tytulow uczestnictwa"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "income_source", "") == "CAPITAL_GAINS"
}

# jdg.pit.a30a.r5 — `capital_income_derivatives`: Instrumenty pochodne, kontrakty terminowe, opcje → 19%
else :=   {"matched":true,"rule_id":"jdg.pit.a30a.r5","package":"jdg.micro.pit.plan33","priority":1245,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Instrumenty pochodne, kontrakty terminowe, opcje","_legal_basis":"Art. 30a PIT — Dochody kapitałowe","_warnings":["[MICRO] Instrumenty pochodne, kontrakty terminowe, opcje"]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.invoice, "income_source", "") == "CAPITAL_GAINS"
}

# jdg.pit.a30a.r6 — `capital_income_investment_funds`: Dochody z funduszy inwestycyjnych → 19%
else :=   {"matched":true,"rule_id":"jdg.pit.a30a.r6","package":"jdg.micro.pit.plan33","priority":1246,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochody z funduszy inwestycyjnych","_legal_basis":"Art. 30a PIT — Dochody kapitałowe","_warnings":["[MICRO] Dochody z funduszy inwestycyjnych"]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.invoice, "income_source", "") == "CAPITAL_GAINS"
}

# jdg.pit.a30a.r9 — `capital_income_withholding_tax`: Pobrany podatek u zrodla (podatek u zrodla 19%) → WHT
else :=   {"matched":true,"rule_id":"jdg.pit.a30a.r9","package":"jdg.micro.pit.plan33","priority":1247,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pobrany podatek u zrodla (podatek u zrodla 19%)","_legal_basis":"Art. 30a PIT — Dochody kapitałowe","_warnings":["[MICRO] Pobrany podatek u zrodla (podatek u zrodla 19%)"]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.invoice, "income_source", "") == "CAPITAL_GAINS"
}

# jdg.pit.a30b.r10 — `real_estate_sale_declaration_PIT_39`: Zeznanie PIT-39 w terminie do 30 kwietnia nastepnego roku → Deklaracja
else :=   {"matched":true,"rule_id":"jdg.pit.a30b.r10","package":"jdg.micro.pit.plan33","priority":1248,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zeznanie PIT-39 w terminie do 30 kwietnia nastepnego roku","_legal_basis":"Art. 30e PIT — Sprzedaż nieruchomości","_warnings":["[MICRO] Zeznanie PIT-39 w terminie do 30 kwietnia nastepnego roku"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a30b.r3 — `real_estate_sale_5_year_countdown`: 5 lat liczone od konca roku kalendarzowego nabycia → Sposob liczenia
else :=   {"matched":true,"rule_id":"jdg.pit.a30b.r3","package":"jdg.micro.pit.plan33","priority":1249,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"5 lat liczone od konca roku kalendarzowego nabycia","_legal_basis":"Art. 30e PIT — Sprzedaż nieruchomości","_warnings":["[MICRO] 5 lat liczone od konca roku kalendarzowego nabycia"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a30b.r4 — `real_estate_sale_inheritance`: Dziedziczenie -> 5 lat od smierci spadkodawcy → Specjalna zasada
else :=   {"matched":true,"rule_id":"jdg.pit.a30b.r4","package":"jdg.micro.pit.plan33","priority":1250,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dziedziczenie -> 5 lat od smierci spadkodawcy","_legal_basis":"Art. 30e PIT — Sprzedaż nieruchomości","_warnings":["[MICRO] Dziedziczenie -> 5 lat od smierci spadkodawcy"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a30b.r5 — `real_estate_sale_rate_19pct`: Stawka 19% od dochodu ze sprzedazy → Stawka
else :=   {"matched":true,"rule_id":"jdg.pit.a30b.r5","package":"jdg.micro.pit.plan33","priority":1251,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawka 19% od dochodu ze sprzedazy","_legal_basis":"Art. 30e PIT — Sprzedaż nieruchomości","_warnings":["[MICRO] Stawka 19% od dochodu ze sprzedazy"]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
}

# jdg.pit.a30b.r7 — `real_estate_sale_housing_deadline_3_years`: Wydatki mieszkaniowe w 3 lata od sprzedazy → Termin
else :=   {"matched":true,"rule_id":"jdg.pit.a30b.r7","package":"jdg.micro.pit.plan33","priority":1252,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wydatki mieszkaniowe w 3 lata od sprzedazy","_legal_basis":"Art. 30e PIT — Sprzedaż nieruchomości","_warnings":["[MICRO] Wydatki mieszkaniowe w 3 lata od sprzedazy"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a30b.r8 — `real_estate_sale_housing_catalog`: Katalog: zakup domu/mieszkania, budowa, remont, spolka mieszkaniowa → Katalog wydatkow
else :=   {"matched":true,"rule_id":"jdg.pit.a30b.r8","package":"jdg.micro.pit.plan33","priority":1253,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Katalog: zakup domu/mieszkania, budowa, remont, spolka mieszkaniowa","_legal_basis":"Art. 30e PIT — Sprzedaż nieruchomości","_warnings":["[MICRO] Katalog: zakup domu/mieszkania, budowa, remont, spolka mieszkaniowa"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.a30b.r9 — `real_estate_sale_share_of_property`: Sprzedaz udzialu we wlasnosci -> proporcjonalnie → Udzial
else :=   {"matched":true,"rule_id":"jdg.pit.a30b.r9","package":"jdg.micro.pit.plan33","priority":1254,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprzedaz udzialu we wlasnosci -> proporcjonalnie","_legal_basis":"Art. 30e PIT — Sprzedaż nieruchomości","_warnings":["[MICRO] Sprzedaz udzialu we wlasnosci -> proporcjonalnie"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a31.r10 — `advance_health_contribution_cap`: Skladka zdrowotna odliczana do wysokosci zaplaconej w okresie → Limit
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r10","package":"jdg.micro.pit.plan33","priority":1255,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skladka zdrowotna odliczana do wysokosci zaplaconej w okresie","_legal_basis":"Art. 44 PIT — Zaliczki na podatek","_warnings":["[MICRO] Skladka zdrowotna odliczana do wysokosci zaplaconej w okresie"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r11 — `advance_income_calculation_cumulative`: Dochód narastajaco od poczatku roku → Metoda kumulatywna
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r11","package":"jdg.micro.pit.plan33","priority":1256,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochód narastajaco od poczatku roku","_legal_basis":"Art. 44 PIT — Zaliczki na podatek","_warnings":["[MICRO] Dochód narastajaco od poczatku roku"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r12 — `advance_revenue_recognition_pkpir`: Przychod w PKPiR w dacie wystawienia faktury (lub 25. dnia miesiaca) → Moment przychodu
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r12","package":"jdg.micro.pit.plan33","priority":1257,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przychod w PKPiR w dacie wystawienia faktury (lub 25. dnia miesiaca)","_legal_basis":"Art. 44 PIT — Zaliczki na podatek","_warnings":["[MICRO] Przychod w PKPiR w dacie wystawienia faktury (lub 25. dnia miesiaca)"]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.a31.r13 — `advance_expense_recognition_pkpir`: Koszt w PKPiR w dacie poniesienia (faktury) → Moment kosztu
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r13","package":"jdg.micro.pit.plan33","priority":1258,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszt w PKPiR w dacie poniesienia (faktury)","_legal_basis":"Art. 44 PIT — Zaliczki na podatek","_warnings":["[MICRO] Koszt w PKPiR w dacie poniesienia (faktury)"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r15 — `advance_no_obligation_if_under_income`: Brak obowiazku gdy przychod < koszty + ZUS → Brak obowiazku
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r15","package":"jdg.micro.pit.plan33","priority":1259,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak obowiazku gdy przychod < koszty + ZUS","_legal_basis":"Art. 44 PIT — Zaliczki na podatek","_warnings":["[MICRO] Brak obowiazku gdy przychod < koszty + ZUS"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r16 — `advance_overpayment_refund`: Nadplata w zaliczkach -> zwrot na wniosek lub z deklaracji rocznej → Zwrot
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r16","package":"jdg.micro.pit.plan33","priority":1260,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nadplata w zaliczkach -> zwrot na wniosek lub z deklaracji rocznej","_legal_basis":"Art. 44 PIT — Zaliczki na podatek","_warnings":["[MICRO] Nadplata w zaliczkach -> zwrot na wniosek lub z deklaracji rocznej"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r17 — `advance_underpayment_interest`: Niedoplata -> odsetki za zwloke od terminu platnosci → Odsetki
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r17","package":"jdg.micro.pit.plan33","priority":1261,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niedoplata -> odsetki za zwloke od terminu platnosci","_legal_basis":"Art. 44 PIT — Zaliczki na podatek","_warnings":["[MICRO] Niedoplata -> odsetki za zwloke od terminu platnosci"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r18 — `advance_change_to_quarterly_mid_year`: Zmiana na kwartalne w trakcie roku -> od poczatku nastepnego kwartalu → Zmiana
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r18","package":"jdg.micro.pit.plan33","priority":1262,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana na kwartalne w trakcie roku -> od poczatku nastepnego kwartalu","_legal_basis":"Art. 44 PIT — Zaliczki na podatek","_warnings":["[MICRO] Zmiana na kwartalne w trakcie roku -> od poczatku nastepnego kwartalu"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r19 — `advance_cessation_income_liquidation`: Zaprzestanie dzialalnosci -> zaliczka za okres do dnia zaprzestania → Zakonczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r19","package":"jdg.micro.pit.plan33","priority":1263,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaprzestanie dzialalnosci -> zaliczka za okres do dnia zaprzestania","_legal_basis":"Art. 44 PIT — Zaliczki na podatek","_warnings":["[MICRO] Zaprzestanie dzialalnosci -> zaliczka za okres do dnia zaprzestania"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r20 — `advance_cessation_deadline_20`: Ostatnia zaliczka do 20. dnia nastepnego miesiaca po zaprzestaniu → Termin
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r20","package":"jdg.micro.pit.plan33","priority":1264,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ostatnia zaliczka do 20. dnia nastepnego miesiaca po zaprzestaniu","_legal_basis":"Art. 44 PIT — Zaliczki na podatek","_warnings":["[MICRO] Ostatnia zaliczka do 20. dnia nastepnego miesiaca po zaprzestaniu"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r21 — `advance_annual_settlement_difference`: Roznica miedzy suma zaliczek a podatkiem rocznym -> doplata/zwrot → Rozliczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r21","package":"jdg.micro.pit.plan33","priority":1265,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roznica miedzy suma zaliczek a podatkiem rocznym -> doplata/zwrot","_legal_basis":"Art. 44 PIT — Zaliczki na podatek","_warnings":["[MICRO] Roznica miedzy suma zaliczek a podatkiem rocznym -> doplata/zwrot"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r4 — `advance_quarterly_deadline_20`: Zaliczka kwartalna do 20. dnia po kwartale → Termin
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r4","package":"jdg.micro.pit.plan33","priority":1266,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaliczka kwartalna do 20. dnia po kwartale","_legal_basis":"Art. 44 PIT — Zaliczki na podatek","_warnings":["[MICRO] Zaliczka kwartalna do 20. dnia po kwartale"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r7 — `advance_deduction_zus_timing`: Składka ZUS za dany miesiac odliczana w zaliczce za ten miesiac → Timing
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r7","package":"jdg.micro.pit.plan33","priority":1267,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Składka ZUS za dany miesiac odliczana w zaliczce za ten miesiac","_legal_basis":"Art. 44 PIT — Zaliczki na podatek","_warnings":["[MICRO] Składka ZUS za dany miesiac odliczana w zaliczce za ten miesiac"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r8 — `advance_deduction_health_7_75`: Skladka zdrowotna 7.75% podstawy (dla skali) -> odliczenie od podatku → Odliczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r8","package":"jdg.micro.pit.plan33","priority":1268,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skladka zdrowotna 7.75% podstawy (dla skali) -> odliczenie od podatku","_legal_basis":"Art. 44 PIT — Zaliczki na podatek","_warnings":["[MICRO] Skladka zdrowotna 7.75% podstawy (dla skali) -> odliczenie od podatku"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a31.r9 — `advance_deduction_health_4_9_linear`: Dla liniowego: skladka zdrowotna 4.9% -> odliczenie od podatku → Odliczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a31.r9","package":"jdg.micro.pit.plan33","priority":1269,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dla liniowego: skladka zdrowotna 4.9% -> odliczenie od podatku","_legal_basis":"Art. 44 PIT — Zaliczki na podatek","_warnings":["[MICRO] Dla liniowego: skladka zdrowotna 4.9% -> odliczenie od podatku"]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a32.r3 — `advance_lump_sum_deduction_zus`: Odliczenie skladek ZUS od przychodu przed opodatkowaniem → Pomniejszenie
else :=   {"matched":true,"rule_id":"jdg.pit.a32.r3","package":"jdg.micro.pit.plan33","priority":1270,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie skladek ZUS od przychodu przed opodatkowaniem","_legal_basis":"Art. 30c PIT / Ustawa o ryczałcie — Zaliczki uproszczone","_warnings":["[MICRO] Odliczenie skladek ZUS od przychodu przed opodatkowaniem"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a32.r4 — `advance_lump_sum_deduction_health`: Odliczenie skladki zdrowotnej 4.9% (dla ryczaltu od 2022) → Odliczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a32.r4","package":"jdg.micro.pit.plan33","priority":1271,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie skladki zdrowotnej 4.9% (dla ryczaltu od 2022)","_legal_basis":"Art. 30c PIT / Ustawa o ryczałcie — Zaliczki uproszczone","_warnings":["[MICRO] Odliczenie skladki zdrowotnej 4.9% (dla ryczaltu od 2022)"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true
}

# jdg.pit.a32.r5 — `advance_tax_card_monthly_fixed`: Karta podatkowa -> stala miesieczna kwota podatku → Stala kwota
else :=   {"matched":true,"rule_id":"jdg.pit.a32.r5","package":"jdg.micro.pit.plan33","priority":1272,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Karta podatkowa -> stala miesieczna kwota podatku","_legal_basis":"Art. 30c PIT / Ustawa o ryczałcie — Zaliczki uproszczone","_warnings":["[MICRO] Karta podatkowa -> stala miesieczna kwota podatku"]} {
    input.jdg_entrepreneur.tax_form == "TAX_CARD"; object.get(input.jdg_entrepreneur, "tax_form", "") != ""; object.get(input.jdg_entrepreneur, "advance_required", true) == true; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a44.r1 — `annual_income_estimated_current_year`: Zaliczki w roku biezacym na podstawie dochodu roku poprzedniego → Szacowanie
else :=   {"matched":true,"rule_id":"jdg.pit.a44.r1","package":"jdg.micro.pit.plan33","priority":1273,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaliczki w roku biezacym na podstawie dochodu roku poprzedniego","_legal_basis":"Art. 44 PIT — Zaliczki uproszczone","_warnings":["[MICRO] Zaliczki w roku biezacym na podstawie dochodu roku poprzedniego"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a44.r2 — `annual_income_actual_current_year`: Opcja: zaliczki na podstawie faktycznego dochodu biezacego roku → Faktyczny
else :=   {"matched":true,"rule_id":"jdg.pit.a44.r2","package":"jdg.micro.pit.plan33","priority":1274,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Opcja: zaliczki na podstawie faktycznego dochodu biezacego roku","_legal_basis":"Art. 44 PIT — Zaliczki uproszczone","_warnings":["[MICRO] Opcja: zaliczki na podstawie faktycznego dochodu biezacego roku"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a44.r3 — `annual_income_change_method_notification`: Zmiana metody szacowania -> zawiadomienie US do 20. lutego → Obowiazek formalny
else :=   {"matched":true,"rule_id":"jdg.pit.a44.r3","package":"jdg.micro.pit.plan33","priority":1275,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana metody szacowania -> zawiadomienie US do 20. lutego","_legal_basis":"Art. 44 PIT — Zaliczki uproszczone","_warnings":["[MICRO] Zmiana metody szacowania -> zawiadomienie US do 20. lutego"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a45.r11 — `annual_return_deadline_after_cessation`: Zaprzestanie dzialalnosci -> deklaracja do 30 kwietnia roku po zaprzestaniu → Termin szczegolny
else :=   {"matched":true,"rule_id":"jdg.pit.a45.r11","package":"jdg.micro.pit.plan33","priority":1276,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaprzestanie dzialalnosci -> deklaracja do 30 kwietnia roku po zaprzestaniu","_legal_basis":"Art. 45 PIT — Zeznania roczne","_warnings":["[MICRO] Zaprzestanie dzialalnosci -> deklaracja do 30 kwietnia roku po zaprzestaniu"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a45.r12 — `annual_return_death_entrepreneur`: Smierc przedsiebiorcy -> deklaracja sklada spadkobierca w 3 miesiace → Sukcesja
else :=   {"matched":true,"rule_id":"jdg.pit.a45.r12","package":"jdg.micro.pit.plan33","priority":1277,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Smierc przedsiebiorcy -> deklaracja sklada spadkobierca w 3 miesiace","_legal_basis":"Art. 45 PIT — Zeznania roczne","_warnings":["[MICRO] Smierc przedsiebiorcy -> deklaracja sklada spadkobierca w 3 miesiace"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a45.r4 — `annual_return_tax_card_PIT_16A`: Karta podatkowa -> PIT-16A → Deklaracja
else :=   {"matched":true,"rule_id":"jdg.pit.a45.r4","package":"jdg.micro.pit.plan33","priority":1278,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Karta podatkowa -> PIT-16A","_legal_basis":"Art. 45 PIT — Zeznania roczne","_warnings":["[MICRO] Karta podatkowa -> PIT-16A"]} {
    input.jdg_entrepreneur.tax_form == "TAX_CARD"; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.a45.r6 — `annual_return_self_employed_extension`: JDG moze zlozyc deklaracje bez posrednictwa (e-Deklaracja) → Sposob
else :=   {"matched":true,"rule_id":"jdg.pit.a45.r6","package":"jdg.micro.pit.plan33","priority":1279,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG moze zlozyc deklaracje bez posrednictwa (e-Deklaracja)","_legal_basis":"Art. 45 PIT — Zeznania roczne","_warnings":["[MICRO] JDG moze zlozyc deklaracje bez posrednictwa (e-Deklaracja)"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a45.r8 — `annual_return_tax_due_calculation`: Podatek należny = podatek roczny - suma zaliczek - ulgi → Obliczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a45.r8","package":"jdg.micro.pit.plan33","priority":1280,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatek należny = podatek roczny - suma zaliczek - ulgi","_legal_basis":"Art. 45 PIT — Zeznania roczne","_warnings":["[MICRO] Podatek należny = podatek roczny - suma zaliczek - ulgi"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a9a.r10 — `tax_form_change_to_lump_sum_PIT_28`: Zmiana na ryczalt do 20 stycznia lub przy rozpoczynaniu dzialalnosci → Procedura
else :=   {"matched":true,"rule_id":"jdg.pit.a9a.r10","package":"jdg.micro.pit.plan33","priority":1281,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana na ryczalt do 20 stycznia lub przy rozpoczynaniu dzialalnosci","_legal_basis":"Art. 9a PIT — Wybór formy opodatkowania","_warnings":["[MICRO] Zmiana na ryczalt do 20 stycznia lub przy rozpoczynaniu dzialalnosci"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.pit.a9a.r3 — `tax_form_linear_restriction_services_client`: Liniowy niedostepny dla uslug na rzecz bylego pracodawcy (j.w.) → Ograniczenie
else :=   {"matched":true,"rule_id":"jdg.pit.a9a.r3","package":"jdg.micro.pit.plan33","priority":1282,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Liniowy niedostepny dla uslug na rzecz bylego pracodawcy (j.w.)","_legal_basis":"Art. 9a PIT — Wybór formy opodatkowania","_warnings":["[MICRO] Liniowy niedostepny dla uslug na rzecz bylego pracodawcy (j.w.)"]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
}

# jdg.pit.a9a.r6 — `tax_form_change_first_year_start`: Dla nowej JDG: oswiadczenie o wyborze formy w pierwszym roku → Nowa dzialalnosc
else :=   {"matched":true,"rule_id":"jdg.pit.a9a.r6","package":"jdg.micro.pit.plan33","priority":1283,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dla nowej JDG: oswiadczenie o wyborze formy w pierwszym roku","_legal_basis":"Art. 9a PIT — Wybór formy opodatkowania","_warnings":["[MICRO] Dla nowej JDG: oswiadczenie o wyborze formy w pierwszym roku"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.a9a.r8 — `tax_form_change_from_scale_to_linear`: Zmiana ze skali na liniowy -> zawiadomienie US → Procedura
else :=   {"matched":true,"rule_id":"jdg.pit.a9a.r8","package":"jdg.micro.pit.plan33","priority":1284,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana ze skali na liniowy -> zawiadomienie US","_legal_basis":"Art. 9a PIT — Wybór formy opodatkowania","_warnings":["[MICRO] Zmiana ze skali na liniowy -> zawiadomienie US"]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
}

# jdg.pit.a9a.r9 — `tax_form_change_from_linear_to_scale`: Zmiana z liniowego na skale -> zawiadomienie US → Procedura
else :=   {"matched":true,"rule_id":"jdg.pit.a9a.r9","package":"jdg.micro.pit.plan33","priority":1285,"micro_rule_active":true,"valid_from":"1992-01-01","valid_to":null,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana z liniowego na skale -> zawiadomienie US","_legal_basis":"Art. 9a PIT — Wybór formy opodatkowania","_warnings":["[MICRO] Zmiana z liniowego na skale -> zawiadomienie US"]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
}
