# Generated from Plan OPA 33 — Micro-rules for uor
# 2026-07-13 14:58:41
# Rules: 25 (new, deduplicated)

package jdg.micro.uor_plan33

default decide := {"matched":false,"rule_id":"jdg.micro.uor.no_match","package": "jdg.micro.uor_plan33","priority":99999}

# jdg.uor.r1 — `uor_pkpir_basic_record`: JDG prowadzi PKPiR (Podatkowa Ksiega Przychodow i Rozchodow) → Podstawowy obowiazek
decide :=   {"matched":true,"rule_id":"jdg.uor.r1","package": "jdg.micro.uor_plan33","priority":4800,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG prowadzi PKPiR (Podatkowa Ksiega Przychodow i Rozchodow)","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] JDG prowadzi PKPiR (Podatkowa Ksiega Przychodow i Rozchodow)"]} {
    true
}

# jdg.uor.r10 — `uor_pkpir_inventory_deadline_15_january`: Spis z natury do 15 stycznia nastepnego roku → Termin
else :=   {"matched":true,"rule_id":"jdg.uor.r10","package": "jdg.micro.uor_plan33","priority":4801,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Spis z natury do 15 stycznia nastepnego roku","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Spis z natury do 15 stycznia nastepnego roku"]} {
    true
}

# jdg.uor.r11 — `uor_pkpir_storage_5_years`: PKPiR przechowywana 5 lat → Retencja
else :=   {"matched":true,"rule_id":"jdg.uor.r11","package": "jdg.micro.uor_plan33","priority":4802,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"PKPiR przechowywana 5 lat","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] PKPiR przechowywana 5 lat"]} {
    true
}

# jdg.uor.r12 — `uor_pkpir_electronic_form`: PKPiR w formie elektronicznej (program ksiegowy) dopuszczalna → Forma
else :=   {"matched":true,"rule_id":"jdg.uor.r12","package": "jdg.micro.uor_plan33","priority":4803,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"PKPiR w formie elektronicznej (program ksiegowy) dopuszczalna","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] PKPiR w formie elektronicznej (program ksiegowy) dopuszczalna"]} {
    true
}

# jdg.uor.r13 — `uor_pkpir_errors_corrections`: Korekta bledow w PKPiR: skreslenie (przekreslenie) + data + podpis → Korekta
else :=   {"matched":true,"rule_id":"jdg.uor.r13","package": "jdg.micro.uor_plan33","priority":4804,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta bledow w PKPiR: skreslenie (przekreslenie) + data + podpis","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Korekta bledow w PKPiR: skreslenie (przekreslenie) + data + podpis"]} {
    true
}

# jdg.uor.r14 — `uor_pkpir_closing_new_beginning`: Zamkniecie PKPiR na koniec roku -> otwarcie nowej na nowy rok → Nowy rok
else :=   {"matched":true,"rule_id":"jdg.uor.r14","package": "jdg.micro.uor_plan33","priority":4805,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zamkniecie PKPiR na koniec roku -> otwarcie nowej na nowy rok","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Zamkniecie PKPiR na koniec roku -> otwarcie nowej na nowy rok"]} {
    true
}

# jdg.uor.r15 — `uor_pkpir_expenses_column_13`: Kolumna 13 (wydatki ogolem) i kolumna 14-16 (wydatki szczegolne) → Wydatki
else :=   {"matched":true,"rule_id":"jdg.uor.r15","package": "jdg.micro.uor_plan33","priority":4806,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kolumna 13 (wydatki ogolem) i kolumna 14-16 (wydatki szczegolne)","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Kolumna 13 (wydatki ogolem) i kolumna 14-16 (wydatki szczegolne)"]} {
    true
}

# jdg.uor.r16 — `uor_pkpir_revenue_cash_registered`: Przychod: data wystawienia faktury (lub 25. dnia miesiaca) → Przychod
else :=   {"matched":true,"rule_id":"jdg.uor.r16","package": "jdg.micro.uor_plan33","priority":4807,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przychod: data wystawienia faktury (lub 25. dnia miesiaca)","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Przychod: data wystawienia faktury (lub 25. dnia miesiaca)"]} {
    true
}

# jdg.uor.r17 — `uor_pkpir_expense_date_invoice`: Wydatek: data faktury (lub data zaplaty jesli kasa) → Wydatek
else :=   {"matched":true,"rule_id":"jdg.uor.r17","package": "jdg.micro.uor_plan33","priority":4808,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wydatek: data faktury (lub data zaplaty jesli kasa)","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Wydatek: data faktury (lub data zaplaty jesli kasa)"]} {
    true
}

# jdg.uor.r18 — `uor_pkpir_salary_end_of_month`: Wynagrodzenia: na koniec miesiaca (za miesiac) → Wyplata
else :=   {"matched":true,"rule_id":"jdg.uor.r18","package": "jdg.micro.uor_plan33","priority":4809,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wynagrodzenia: na koniec miesiaca (za miesiac)","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Wynagrodzenia: na koniec miesiaca (za miesiac)"]} {
    true
}

# jdg.uor.r19 — `uor_pkpir_fixed_assets_register`: Ewidencja srodkow trwalych (osobna od PKPiR) → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.uor.r19","package": "jdg.micro.uor_plan33","priority":4810,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ewidencja srodkow trwalych (osobna od PKPiR)","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Ewidencja srodkow trwalych (osobna od PKPiR)"]} {
    true
}

# jdg.uor.r2 — `uor_pkpir_eligible_for_jdg`: JDG moze prowadzic PKPiR (jesli przychod < 2M EUR) → Mozliwosc
else :=   {"matched":true,"rule_id":"jdg.uor.r2","package": "jdg.micro.uor_plan33","priority":4811,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG moze prowadzic PKPiR (jesli przychod < 2M EUR)","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] JDG moze prowadzic PKPiR (jesli przychod < 2M EUR)"]} {
    true
}

# jdg.uor.r20 — `uor_pkpir_fixed_assets_format`: Ewidencja ST: data, wartosc, stawka, odpisy, zbycie → Format
else :=   {"matched":true,"rule_id":"jdg.uor.r20","package": "jdg.micro.uor_plan33","priority":4812,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ewidencja ST: data, wartosc, stawka, odpisy, zbycie","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Ewidencja ST: data, wartosc, stawka, odpisy, zbycie"]} {
    true
}

# jdg.uor.r21 — `uor_pkpir_wnip_register`: Ewidencja WNiP (wartosci niematerialnych i prawnych) → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.uor.r21","package": "jdg.micro.uor_plan33","priority":4813,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ewidencja WNiP (wartosci niematerialnych i prawnych)","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Ewidencja WNiP (wartosci niematerialnych i prawnych)"]} {
    true
}

# jdg.uor.r22 — `uor_pkpir_employee_salary_register`: Ewidencja wynagrodzen pracownikow (imienna) → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.uor.r22","package": "jdg.micro.uor_plan33","priority":4814,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ewidencja wynagrodzen pracownikow (imienna)","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Ewidencja wynagrodzen pracownikow (imienna)"]} {
    true
}

# jdg.uor.r23 — `uor_pkpir_vat_register`: Ewidencja VAT (sprzedaz i zakup) dla czynnych podatnikow → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.uor.r23","package": "jdg.micro.uor_plan33","priority":4815,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ewidencja VAT (sprzedaz i zakup) dla czynnych podatnikow","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Ewidencja VAT (sprzedaz i zakup) dla czynnych podatnikow"]} {
    true
}

# jdg.uor.r24 — `uor_pkpir_vehicle_expense_log`: Ewidencja przebiegu pojazdu dla auta firmowego (100% KUP opcja) → Obowiazek warunkowy
else :=   {"matched":true,"rule_id":"jdg.uor.r24","package": "jdg.micro.uor_plan33","priority":4816,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ewidencja przebiegu pojazdu dla auta firmowego (100% KUP opcja)","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Ewidencja przebiegu pojazdu dla auta firmowego (100% KUP opcja)"]} {
    true
}

# jdg.uor.r25 — `uor_pkpir_bank_account_separate`: Obowiazek posiadania osobnego rachunku bankowego dla JDG → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.uor.r25","package": "jdg.micro.uor_plan33","priority":4817,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiazek posiadania osobnego rachunku bankowego dla JDG","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Obowiazek posiadania osobnego rachunku bankowego dla JDG"]} {
    true
}

# jdg.uor.r3 — `uor_financial_statements_mandatory_over_2m_eur`: Przekroczenie 2M EUR przychodu -> obowiazek pelnej ksiegowosci (ksiegi rachunkowe) → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.uor.r3","package": "jdg.micro.uor_plan33","priority":4818,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przekroczenie 2M EUR przychodu -> obowiazek pelnej ksiegowosci (ksiegi rachunkowe)","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Przekroczenie 2M EUR przychodu -> obowiazek pelnej ksiegowosci (ksiegi rachunkowe)"]} {
    true
}

# jdg.uor.r4 — `uor_financial_statements_mandatory_capital_group`: JDG w grupie kapitalowej -> ksiegi rachunkowe → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.uor.r4","package": "jdg.micro.uor_plan33","priority":4819,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG w grupie kapitalowej -> ksiegi rachunkowe","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] JDG w grupie kapitalowej -> ksiegi rachunkowe"]} {
    true
}

# jdg.uor.r5 — `uor_financial_statements_filing`: Sprawozdanie finansowe do KRS w 15 dni od zatwierdzenia → Termin
else :=   {"matched":true,"rule_id":"jdg.uor.r5","package": "jdg.micro.uor_plan33","priority":4820,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprawozdanie finansowe do KRS w 15 dni od zatwierdzenia","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Sprawozdanie finansowe do KRS w 15 dni od zatwierdzenia"]} {
    true
}

# jdg.uor.r6 — `uor_pkpir_columns`: PKPiR: 17 kolumn (przychody, wydatki, uwagi) → Struktura
else :=   {"matched":true,"rule_id":"jdg.uor.r6","package": "jdg.micro.uor_plan33","priority":4821,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"PKPiR: 17 kolumn (przychody, wydatki, uwagi)","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] PKPiR: 17 kolumn (przychody, wydatki, uwagi)"]} {
    true
}

# jdg.uor.r7 — `uor_pkpir_chronological_order`: Wpisy chronologiczne, dzien po dniu, na podstawie dokumentow → Zasada
else :=   {"matched":true,"rule_id":"jdg.uor.r7","package": "jdg.micro.uor_plan33","priority":4822,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wpisy chronologiczne, dzien po dniu, na podstawie dokumentow","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Wpisy chronologiczne, dzien po dniu, na podstawie dokumentow"]} {
    true
}

# jdg.uor.r8 — `uor_pkpir_annual_reconciliation`: Roczne zamkniecie PKPiR (suma przychodow i wydatkow) → Roczne
else :=   {"matched":true,"rule_id":"jdg.uor.r8","package": "jdg.micro.uor_plan33","priority":4823,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roczne zamkniecie PKPiR (suma przychodow i wydatkow)","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Roczne zamkniecie PKPiR (suma przychodow i wydatkow)"]} {
    true
}

# jdg.uor.r9 — `uor_pkpir_inventory_mandatory`: Obowiazkowa inwentaryzacja (spis z natury) na koniec roku → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.uor.r9","package": "jdg.micro.uor_plan33","priority":4824,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiazkowa inwentaryzacja (spis z natury) na koniec roku","_legal_basis":"Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)","_warnings":["[MICRO] Obowiazkowa inwentaryzacja (spis z natury) na koniec roku"]} {
    true
}
