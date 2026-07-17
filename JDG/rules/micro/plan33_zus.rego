# Generated from Plan OPA 33 — Micro-rules for zus
# 2026-07-13 14:58:41
# Rules: 180 (new, deduplicated)

package jdg.micro.zus

default decide := {"matched":false,"rule_id":"jdg.micro.zus.no_match","package":"jdg.micro.zus","priority":99999}

# jdg.zus.a11.r2 — `insurance_disability_mandatory`: Każda osoba podlegająca ubezpieczeniom społecznym → Obowiązek ubezpieczenia rentowego (8.00%)
decide :=   {"matched":true,"rule_id":"jdg.zus.a11.r2","package":"jdg.micro.zus","priority":2300,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Każda osoba podlegająca ubezpieczeniom społecznym","_legal_basis":"Art. 12 SUS","_warnings":["[MICRO] Każda osoba podlegająca ubezpieczeniom społecznym"]} {
    true
}

# jdg.zus.a11.r3 — `insurance_sickness_voluntary`: JDG może dobrowolnie przystąpić do ubezpieczenia chorobowego → Dobrowolne
else :=   {"matched":true,"rule_id":"jdg.zus.a11.r3","package":"jdg.micro.zus","priority":2301,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG może dobrowolnie przystąpić do ubezpieczenia chorobowego","_legal_basis":"Art. 11 ust. 2 SUS","_warnings":["[MICRO] JDG może dobrowolnie przystąpić do ubezpieczenia chorobowego"]} {
    true
}

# jdg.zus.a11.r4 — `insurance_sickness_voluntary_add_after`: JDG przystępuje do chorobowego w terminie 7 dni od powstania tytułu → Termin przystąpienia
else :=   {"matched":true,"rule_id":"jdg.zus.a11.r4","package":"jdg.micro.zus","priority":2302,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG przystępuje do chorobowego w terminie 7 dni od powstania tytułu","_legal_basis":"Art. 11 ust. 2 SUS","_warnings":["[MICRO] JDG przystępuje do chorobowego w terminie 7 dni od powstania tytułu"]} {
    true
}

# jdg.zus.a11.r5 — `insurance_sickness_cessation`: 3-miesięczne opóźnienie w opłacaniu chorobowej -> ustanie dobrowolnego ubezpieczenia → Ustanie z mocy prawa
else :=   {"matched":true,"rule_id":"jdg.zus.a11.r5","package":"jdg.micro.zus","priority":2303,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"3-miesięczne opóźnienie w opłacaniu chorobowej -> ustanie dobrowolnego ubezpieczenia","_legal_basis":"Art. 11 ust. 4 SUS","_warnings":["[MICRO] 3-miesięczne opóźnienie w opłacaniu chorobowej -> ustanie dobrowolnego ubezpieczenia"]} {
    true
}

# jdg.zus.a11.r6 — `insurance_accident_mandatory`: Osoby podlegające ubezpieczeniom emerytalnemu i rentowemu → Obowiązek ubezpieczenia wypadkowego (0.67%-3.33%)
else :=   {"matched":true,"rule_id":"jdg.zus.a11.r6","package":"jdg.micro.zus","priority":2304,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Osoby podlegające ubezpieczeniom emerytalnemu i rentowemu","_legal_basis":"Art. 12 ust. 1 SUS","_warnings":["[MICRO] Osoby podlegające ubezpieczeniom emerytalnemu i rentowemu"]} {
    true
}

# jdg.zus.a11.r7 — `insurance_accident_rate_by_risk`: Stopa procentowa składki wypadkowej wg kodu PKD i liczby ubezpieczonych → Stawka zróżnicowana (9 kategorii ryzyka)
else :=   {"matched":true,"rule_id":"jdg.zus.a11.r7","package":"jdg.micro.zus","priority":2305,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stopa procentowa składki wypadkowej wg kodu PKD i liczby ubezpieczonych","_legal_basis":"Art. 22 ust. 5 SUS","_warnings":["[MICRO] Stopa procentowa składki wypadkowej wg kodu PKD i liczby ubezpieczonych"]} {
    true
}

# jdg.zus.a13.r2 — `insurance_start_suspension_jdg`: Zawieszenie JDG: ustanie ubezpieczeń społecznych od dnia zawieszenia → Ustanie
else :=   {"matched":true,"rule_id":"jdg.zus.a13.r2","package":"jdg.micro.zus","priority":2306,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zawieszenie JDG: ustanie ubezpieczeń społecznych od dnia zawieszenia","_legal_basis":"Art. 13 pkt 4 i 4a SUS","_warnings":["[MICRO] Zawieszenie JDG: ustanie ubezpieczeń społecznych od dnia zawieszenia"]} {
    true
}

# jdg.zus.a13.r3 — `insurance_start_resumption_jdg`: Wznowienie JDG: ubezpieczenie od dnia wznowienia → Powstanie na nowo
else :=   {"matched":true,"rule_id":"jdg.zus.a13.r3","package":"jdg.micro.zus","priority":2307,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wznowienie JDG: ubezpieczenie od dnia wznowienia","_legal_basis":"Art. 13 pkt 4 SUS","_warnings":["[MICRO] Wznowienie JDG: ubezpieczenie od dnia wznowienia"]} {
    true
}

# jdg.zus.a16.r1 — `contribution_base_employee`: Podstawa pracownika: przychód w rozumieniu PIT → Przychód brutto z umowy o pracę
else :=   {"matched":true,"rule_id":"jdg.zus.a16.r1","package":"jdg.micro.zus","priority":2308,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa pracownika: przychód w rozumieniu PIT","_legal_basis":"Art. 16 SUS","_warnings":["[MICRO] Podstawa pracownika: przychód w rozumieniu PIT"]} {
    true
}

# jdg.zus.a16.r2 — `contribution_base_mandate`: Podstawa zleceniobiorcy: przychód określony w umowie → Przychód z umowy zlecenia
else :=   {"matched":true,"rule_id":"jdg.zus.a16.r2","package":"jdg.micro.zus","priority":2309,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa zleceniobiorcy: przychód określony w umowie","_legal_basis":"Art. 16 SUS","_warnings":["[MICRO] Podstawa zleceniobiorcy: przychód określony w umowie"]} {
    true
}

# jdg.zus.a18.r10 — `contribution_base_jdg_small_zik`: Mały ZUS Plus: podstawa zależna od dochodu (średnia z ostatnich 3 lat) → 30% min. wynagr. do 60% prognozowanego
else :=   {"matched":true,"rule_id":"jdg.zus.a18.r10","package":"jdg.micro.zus","priority":2310,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mały ZUS Plus: podstawa zależna od dochodu (średnia z ostatnich 3 lat)","_legal_basis":"Art. 18c SUS","_warnings":["[MICRO] Mały ZUS Plus: podstawa zależna od dochodu (średnia z ostatnich 3 lat)"]} {
    true
}

# jdg.zus.a18.r11 — `contribution_base_jdg_small_zik_limit_income`: Mały ZUS Plus: dochód z JDG w poprzednim roku <= 120 000 PLN → Kryterium dostępu
else :=   {"matched":true,"rule_id":"jdg.zus.a18.r11","package":"jdg.micro.zus","priority":2311,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mały ZUS Plus: dochód z JDG w poprzednim roku <= 120 000 PLN","_legal_basis":"Art. 18c ust. 1 pkt 1 SUS","_warnings":["[MICRO] Mały ZUS Plus: dochód z JDG w poprzednim roku <= 120 000 PLN"]} {
    true
}

# jdg.zus.a18.r12 — `contribution_base_jdg_small_zik_not_in_preferential`: Mały ZUS Plus: JDG NIE może korzystać z preferencyjnych składek (24m) → Wykluczenie
else :=   {"matched":true,"rule_id":"jdg.zus.a18.r12","package":"jdg.micro.zus","priority":2312,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mały ZUS Plus: JDG NIE może korzystać z preferencyjnych składek (24m)","_legal_basis":"Art. 18c ust. 3 SUS","_warnings":["[MICRO] Mały ZUS Plus: JDG NIE może korzystać z preferencyjnych składek (24m)"]} {
    true
}

# jdg.zus.a18.r13 — `contribution_base_jdg_small_zik_36_months`: Mały ZUS Plus: max 36 miesięcy w ciągu 60 miesięcy prowadzenia JDG → Limit czasowy
else :=   {"matched":true,"rule_id":"jdg.zus.a18.r13","package":"jdg.micro.zus","priority":2313,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mały ZUS Plus: max 36 miesięcy w ciągu 60 miesięcy prowadzenia JDG","_legal_basis":"Art. 18c ust. 11 SUS","_warnings":["[MICRO] Mały ZUS Plus: max 36 miesięcy w ciągu 60 miesięcy prowadzenia JDG"]} {
    true
}

# jdg.zus.a18.r14 — `contribution_base_jdg_small_zik_not_last_year`: Mały ZUS Plus: JDG prowadziła działalność w co najmniej 1 dniu poprzedniego roku → Kryterium stażu
else :=   {"matched":true,"rule_id":"jdg.zus.a18.r14","package":"jdg.micro.zus","priority":2314,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mały ZUS Plus: JDG prowadziła działalność w co najmniej 1 dniu poprzedniego roku","_legal_basis":"Art. 18c ust. 1 pkt 2 SUS","_warnings":["[MICRO] Mały ZUS Plus: JDG prowadziła działalność w co najmniej 1 dniu poprzedniego roku"]} {
    true
}

# jdg.zus.a18.r15 — `contribution_base_jdg_start_relief`: Ulga na start (6 mies.): podstawa = 0 (zwolnienie ze składek społecznych) → 0 PLN (tylko zdrowotna)
else :=   {"matched":true,"rule_id":"jdg.zus.a18.r15","package":"jdg.micro.zus","priority":2315,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga na start (6 mies.): podstawa = 0 (zwolnienie ze składek społecznych)","_legal_basis":"Art. 18a ust. 1, Art. 18a ust. 4 SUS","_warnings":["[MICRO] Ulga na start (6 mies.): podstawa = 0 (zwolnienie ze składek społecznych)"]} {
    true
}

# jdg.zus.a18.r16 — `contribution_base_jdg_sickness_voluntary`: Dobrowolne chorobowe: podstawa = zadeklarowana kwota (nie wyższa niż 250% prognozowanego) → Kwota zadeklarowana
else :=   {"matched":true,"rule_id":"jdg.zus.a18.r16","package":"jdg.micro.zus","priority":2316,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dobrowolne chorobowe: podstawa = zadeklarowana kwota (nie wyższa niż 250% prognozowanego)","_legal_basis":"Art. 18 ust. 10 SUS","_warnings":["[MICRO] Dobrowolne chorobowe: podstawa = zadeklarowana kwota (nie wyższa niż 250% prognozowanego)"]} {
    true
}

# jdg.zus.a18.r17 — `contribution_base_jdg_sickness_preferential`: Preferencyjny ZUS + dobrowolne chorobowe: podstawa chorobowego = preferencyjna podstawa → 30% min. wynagrodzenia
else :=   {"matched":true,"rule_id":"jdg.zus.a18.r17","package":"jdg.micro.zus","priority":2317,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Preferencyjny ZUS + dobrowolne chorobowe: podstawa chorobowego = preferencyjna podstawa","_legal_basis":"Art. 18 ust. 10 w zw. z Art. 18a SUS","_warnings":["[MICRO] Preferencyjny ZUS + dobrowolne chorobowe: podstawa chorobowego = preferencyjna podstawa"]} {
    true
}

# jdg.zus.a18.r18 — `contribution_base_jdg_minimum_guarantee`: Minimalna podstawa JDG = 60% prognozowanego przeciętnego wynagrodzenia (nawet gdy strata) → Gwarancja minimalnej pods...
else :=   {"matched":true,"rule_id":"jdg.zus.a18.r18","package":"jdg.micro.zus","priority":2318,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Minimalna podstawa JDG = 60% prognozowanego przeciętnego wynagrodzenia (nawet gdy strata)","_legal_basis":"Art. 18 ust. 8 pkt 5 SUS","_warnings":["[MICRO] Minimalna podstawa JDG = 60% prognozowanego przeciętnego wynagrodzenia (nawet gdy strata)"]} {
    true
}

# jdg.zus.a18.r19 — `contribution_base_jdg_pension_fund_exception`: Osiągnięcie wieku emerytalnego -> JDG może odstąpić od opłacania składek społecznych → Zwolnienie opcjonalne
else :=   {"matched":true,"rule_id":"jdg.zus.a18.r19","package":"jdg.micro.zus","priority":2319,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Osiągnięcie wieku emerytalnego -> JDG może odstąpić od opłacania składek społecznych","_legal_basis":"Art. 18 ust. 9 SUS","_warnings":["[MICRO] Osiągnięcie wieku emerytalnego -> JDG może odstąpić od opłacania składek społecznych"]} {
    true
}

# jdg.zus.a18.r20 — `contribution_base_jdg_annual_recalculation`: Roczne przeliczenie podstawy wymiaru składek → Przeliczenie podstawy
else :=   {"matched":true,"rule_id":"jdg.zus.a18.r20","package":"jdg.micro.zus","priority":2320,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roczne przeliczenie podstawy wymiaru składek","_legal_basis":"Art. 18 ust. 11 SUS","_warnings":["[MICRO] Roczne przeliczenie podstawy wymiaru składek"]} {
    true
}

# jdg.zus.a18.r6 — `contribution_base_jdg_standard`: Standardowa podstawa JDG: 60% prognozowanego przeciętnego wynagrodzenia → 60% prognozowanego wynagrodzenia
else :=   {"matched":true,"rule_id":"jdg.zus.a18.r6","package":"jdg.micro.zus","priority":2321,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Standardowa podstawa JDG: 60% prognozowanego przeciętnego wynagrodzenia","_legal_basis":"Art. 18 ust. 8 SUS","_warnings":["[MICRO] Standardowa podstawa JDG: 60% prognozowanego przeciętnego wynagrodzenia"]} {
    true
}

# jdg.zus.a18.r7 — `contribution_base_jdg_declared_premium`: JDG może zadeklarować wyższą podstawę (max 250% prognozowanego wynagrodzenia) → Przedział 60%-250%
else :=   {"matched":true,"rule_id":"jdg.zus.a18.r7","package":"jdg.micro.zus","priority":2322,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG może zadeklarować wyższą podstawę (max 250% prognozowanego wynagrodzenia)","_legal_basis":"Art. 18 ust. 8 pkt 5 SUS","_warnings":["[MICRO] JDG może zadeklarować wyższą podstawę (max 250% prognozowanego wynagrodzenia)"]} {
    true
}

# jdg.zus.a18.r8 — `contribution_base_jdg_lower_first_year`: Pierwsze 24 miesiące JDG: preferencyjna podstawa 30% minimalnego wynagrodzenia → 30% min. wynagrodzenia
else :=   {"matched":true,"rule_id":"jdg.zus.a18.r8","package":"jdg.micro.zus","priority":2323,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pierwsze 24 miesiące JDG: preferencyjna podstawa 30% minimalnego wynagrodzenia","_legal_basis":"Art. 18a SUS","_warnings":["[MICRO] Pierwsze 24 miesiące JDG: preferencyjna podstawa 30% minimalnego wynagrodzenia"]} {
    true
}

# jdg.zus.a18.r9 — `contribution_base_jdg_lower_2_years_from_start`: Limit czasowy preferencyjnej podstawy: 24 miesiące od dnia rozpoczęcia JDG → 24 miesiące
else :=   {"matched":true,"rule_id":"jdg.zus.a18.r9","package":"jdg.micro.zus","priority":2324,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Limit czasowy preferencyjnej podstawy: 24 miesiące od dnia rozpoczęcia JDG","_legal_basis":"Art. 18a ust. 2 SUS","_warnings":["[MICRO] Limit czasowy preferencyjnej podstawy: 24 miesiące od dnia rozpoczęcia JDG"]} {
    true
}

# jdg.zus.a22.r10 — `rate_disability_establishment`: Ustalenie stopy składki rentowej → 8.00% podstawy wymiaru
else :=   {"matched":true,"rule_id":"jdg.zus.a22.r10","package":"jdg.micro.zus","priority":2325,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ustalenie stopy składki rentowej","_legal_basis":"Art. 22 ust. 3 SUS","_warnings":["[MICRO] Ustalenie stopy składki rentowej"]} {
    true
}

# jdg.zus.a22.r11 — `rate_accident_risk_groups`: 9 grup ryzyka wypadkowego -> 9 stawek (0.67%-3.33%) wg PKD → Stawka zróżnicowana
else :=   {"matched":true,"rule_id":"jdg.zus.a22.r11","package":"jdg.micro.zus","priority":2326,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"9 grup ryzyka wypadkowego -> 9 stawek (0.67%-3.33%) wg PKD","_legal_basis":"Art. 22 ust. 5 SUS","_warnings":["[MICRO] 9 grup ryzyka wypadkowego -> 9 stawek (0.67%-3.33%) wg PKD"]} {
    true
}

# jdg.zus.a22.r12 — `rate_accident_new_employer`: Nowy płatnik w pierwszym roku: stawka 1.67% (pośrednia) → 1.67%
else :=   {"matched":true,"rule_id":"jdg.zus.a22.r12","package":"jdg.micro.zus","priority":2327,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nowy płatnik w pierwszym roku: stawka 1.67% (pośrednia)","_legal_basis":"Art. 22 ust. 5 pkt 6 SUS","_warnings":["[MICRO] Nowy płatnik w pierwszym roku: stawka 1.67% (pośrednia)"]} {
    true
}

# jdg.zus.a22.r9 — `rate_pension_establishment`: Ustalenie stopy procentowej składki emerytalnej na dany rok → 19.52% podstawy wymiaru
else :=   {"matched":true,"rule_id":"jdg.zus.a22.r9","package":"jdg.micro.zus","priority":2328,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ustalenie stopy procentowej składki emerytalnej na dany rok","_legal_basis":"Art. 22 ust. 1 SUS","_warnings":["[MICRO] Ustalenie stopy procentowej składki emerytalnej na dany rok"]} {
    true
}

# jdg.zus.a24.r1 — `rate_labour_fund_employment`: Zatrudnienie pracownika -> składka na Fundusz Pracy 2.45% → 2.45% podstawy
else :=   {"matched":true,"rule_id":"jdg.zus.a24.r1","package":"jdg.micro.zus","priority":2329,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zatrudnienie pracownika -> składka na Fundusz Pracy 2.45%","_legal_basis":"Art. 104 ustawy o promocji zatrudnienia","_warnings":["[MICRO] Zatrudnienie pracownika -> składka na Fundusz Pracy 2.45%"]} {
    true
}

# jdg.zus.a24.r2 — `rate_fgsp_employment`: Zatrudnienie pracownika -> składka na FGSP 0.10% → 0.10% podstawy
else :=   {"matched":true,"rule_id":"jdg.zus.a24.r2","package":"jdg.micro.zus","priority":2330,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zatrudnienie pracownika -> składka na FGSP 0.10%","_legal_basis":"Art. 21 ustawy o FGSP","_warnings":["[MICRO] Zatrudnienie pracownika -> składka na FGSP 0.10%"]} {
    true
}

# jdg.zus.a24.r3 — `rate_labour_fund_jdg`: JDG nie płaci składki na Fundusz Pracy z tytułu własnej działalności → 0%
else :=   {"matched":true,"rule_id":"jdg.zus.a24.r3","package":"jdg.micro.zus","priority":2331,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG nie płaci składki na Fundusz Pracy z tytułu własnej działalności","_legal_basis":"Art. 104 ust. 1 pkt 1 ustawy o promocji zatrudnienia","_warnings":["[MICRO] JDG nie płaci składki na Fundusz Pracy z tytułu własnej działalności"]} {
    true
}

# jdg.zus.a24.r4 — `rate_fgsp_not_applicable_jdg`: JDG nie płaci składki na FGSP z tytułu własnej działalności → 0%
else :=   {"matched":true,"rule_id":"jdg.zus.a24.r4","package":"jdg.micro.zus","priority":2332,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG nie płaci składki na FGSP z tytułu własnej działalności","_legal_basis":"Art. 21 ustawy o FGSP","_warnings":["[MICRO] JDG nie płaci składki na FGSP z tytułu własnej działalności"]} {
    true
}

# jdg.zus.a26.r1 — `sickness_benefit_eligibility`: Niezdolność do pracy z powodu choroby → Prawo do zasiłku chorobowego
else :=   {"matched":true,"rule_id":"jdg.zus.a26.r1","package":"jdg.micro.zus","priority":2333,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niezdolność do pracy z powodu choroby","_legal_basis":"Art. 26 ustawy zasiłkowej","_warnings":["[MICRO] Niezdolność do pracy z powodu choroby"]} {
    true
}

# jdg.zus.a26.r10 — `maternity_benefit_period_20_weeks`: Okres zasiłku macierzyńskiego: 20 tygodni (przy 1 dziecku) → 20 tyg. (+ wydł. urlop rodzicielski)
else :=   {"matched":true,"rule_id":"jdg.zus.a26.r10","package":"jdg.micro.zus","priority":2334,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Okres zasiłku macierzyńskiego: 20 tygodni (przy 1 dziecku)","_legal_basis":"Art. 29 ustawy zasiłkowej","_warnings":["[MICRO] Okres zasiłku macierzyńskiego: 20 tygodni (przy 1 dziecku)"]} {
    true
}

# jdg.zus.a26.r11 — `care_benefit_60_pct`: Zasiłek opiekuńczy: 60% podstawy (na dziecko <8 lat, max 60 dni/rok) → 60%
else :=   {"matched":true,"rule_id":"jdg.zus.a26.r11","package":"jdg.micro.zus","priority":2335,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zasiłek opiekuńczy: 60% podstawy (na dziecko <8 lat, max 60 dni/rok)","_legal_basis":"Art. 35 ustawy zasiłkowej","_warnings":["[MICRO] Zasiłek opiekuńczy: 60% podstawy (na dziecko <8 lat, max 60 dni/rok)"]} {
    true
}

# jdg.zus.a26.r12 — `sickness_benefit_not_for_jdg_30_days`: Pierwsze 30 dni choroby: JDG nie otrzymuje zasiłku z ZUS (brak wynagrodzenia chorobowego) → 30 dni bez zasiłku
else :=   {"matched":true,"rule_id":"jdg.zus.a26.r12","package":"jdg.micro.zus","priority":2336,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pierwsze 30 dni choroby: JDG nie otrzymuje zasiłku z ZUS (brak wynagrodzenia chorobowego)","_legal_basis":"Art. 8 ustawy zasiłkowej","_warnings":["[MICRO] Pierwsze 30 dni choroby: JDG nie otrzymuje zasiłku z ZUS (brak wynagrodzenia chorobowego)"]} {
    true
}

# jdg.zus.a26.r13 — `rehabilitation_benefit_90_pct`: Świadczenie rehabilitacyjne: 90% podstawy przez pierwsze 3 miesiące, potem 75% → 90%/75%
else :=   {"matched":true,"rule_id":"jdg.zus.a26.r13","package":"jdg.micro.zus","priority":2337,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Świadczenie rehabilitacyjne: 90% podstawy przez pierwsze 3 miesiące, potem 75%","_legal_basis":"Art. 18 ustawy zasiłkowej","_warnings":["[MICRO] Świadczenie rehabilitacyjne: 90% podstawy przez pierwsze 3 miesiące, potem 75%"]} {
    true
}

# jdg.zus.a26.r14 — `rehabilitation_benefit_12_months`: Okres: max 12 miesięcy → 12 mies.
else :=   {"matched":true,"rule_id":"jdg.zus.a26.r14","package":"jdg.micro.zus","priority":2338,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Okres: max 12 miesięcy","_legal_basis":"Art. 18 ust. 1 ustawy zasiłkowej","_warnings":["[MICRO] Okres: max 12 miesięcy"]} {
    true
}

# jdg.zus.a26.r2 — `sickness_benefit_waiting_period`: Okres wyczekiwania: 30 dni dobrowolnego ubezpieczenia chorobowego → 30 dni
else :=   {"matched":true,"rule_id":"jdg.zus.a26.r2","package":"jdg.micro.zus","priority":2339,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Okres wyczekiwania: 30 dni dobrowolnego ubezpieczenia chorobowego","_legal_basis":"Art. 4 ust. 1 ustawy zasiłkowej","_warnings":["[MICRO] Okres wyczekiwania: 30 dni dobrowolnego ubezpieczenia chorobowego"]} {
    true
}

# jdg.zus.a26.r3 — `sickness_benefit_80_pct`: Zasiłek chorobowy: 80% podstawy wymiaru → 80%
else :=   {"matched":true,"rule_id":"jdg.zus.a26.r3","package":"jdg.micro.zus","priority":2340,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zasiłek chorobowy: 80% podstawy wymiaru","_legal_basis":"Art. 36 ust. 1 ustawy zasiłkowej","_warnings":["[MICRO] Zasiłek chorobowy: 80% podstawy wymiaru"]} {
    true
}

# jdg.zus.a26.r4 — `sickness_benefit_100_pct_hospital`: Pobyt w szpitalu: 70% (chyba że ciąża/oddanie narządów -> 100%) → 70-100%
else :=   {"matched":true,"rule_id":"jdg.zus.a26.r4","package":"jdg.micro.zus","priority":2341,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pobyt w szpitalu: 70% (chyba że ciąża/oddanie narządów -> 100%)","_legal_basis":"Art. 36 ust. 2 ustawy zasiłkowej","_warnings":["[MICRO] Pobyt w szpitalu: 70% (chyba że ciąża/oddanie narządów -> 100%)"]} {
    true
}

# jdg.zus.a26.r5 — `sickness_benefit_182_days`: Max okres pobierania zasiłku: 182 dni w roku → 182 dni
else :=   {"matched":true,"rule_id":"jdg.zus.a26.r5","package":"jdg.micro.zus","priority":2342,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Max okres pobierania zasiłku: 182 dni w roku","_legal_basis":"Art. 8 ustawy zasiłkowej","_warnings":["[MICRO] Max okres pobierania zasiłku: 182 dni w roku"]} {
    true
}

# jdg.zus.a26.r6 — `sickness_benefit_270_tuberculosis`: Gruźlica: max 270 dni → 270 dni
else :=   {"matched":true,"rule_id":"jdg.zus.a26.r6","package":"jdg.micro.zus","priority":2343,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Gruźlica: max 270 dni","_legal_basis":"Art. 8 pkt 2 ustawy zasiłkowej","_warnings":["[MICRO] Gruźlica: max 270 dni"]} {
    true
}

# jdg.zus.a26.r7 — `sickness_benefit_base_jdg`: Podstawa wymiaru zasiłku = średnia z 12 miesięcy składkowych → Średnia z 12 miesięcy
else :=   {"matched":true,"rule_id":"jdg.zus.a26.r7","package":"jdg.micro.zus","priority":2344,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa wymiaru zasiłku = średnia z 12 miesięcy składkowych","_legal_basis":"Art. 36 ust. 2 ustawy zasiłkowej","_warnings":["[MICRO] Podstawa wymiaru zasiłku = średnia z 12 miesięcy składkowych"]} {
    true
}

# jdg.zus.a26.r8 — `sickness_benefit_base_minimum_jdg`: Minimalna podstawa dla JDG: 60% prognozowanego przeciętnego wynagrodzenia → Minimum gwarantowane
else :=   {"matched":true,"rule_id":"jdg.zus.a26.r8","package":"jdg.micro.zus","priority":2345,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Minimalna podstawa dla JDG: 60% prognozowanego przeciętnego wynagrodzenia","_legal_basis":"Art. 36 ust. 3 ustawy zasiłkowej","_warnings":["[MICRO] Minimalna podstawa dla JDG: 60% prognozowanego przeciętnego wynagrodzenia"]} {
    true
}

# jdg.zus.a26.r9 — `maternity_benefit_100_pct`: Zasiłek macierzyński: 100% podstawy wymiaru → 100%
else :=   {"matched":true,"rule_id":"jdg.zus.a26.r9","package":"jdg.micro.zus","priority":2346,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zasiłek macierzyński: 100% podstawy wymiaru","_legal_basis":"Art. 38 ustawy zasiłkowej","_warnings":["[MICRO] Zasiłek macierzyński: 100% podstawy wymiaru"]} {
    true
}

# jdg.zus.a32.r1 — `labour_fund_small_employer_exception`: Pracodawca zatrudniający <20 pracowników -> niższa składka FP (1.00%) → 1.00%
else :=   {"matched":true,"rule_id":"jdg.zus.a32.r1","package":"jdg.micro.zus","priority":2347,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pracodawca zatrudniający <20 pracowników -> niższa składka FP (1.00%)","_legal_basis":"Art. 104b ustawy o promocji zatrudnienia","_warnings":["[MICRO] Pracodawca zatrudniający <20 pracowników -> niższa składka FP (1.00%)"]} {
    true
}

# jdg.zus.a32.r2 — `labour_fund_employer_over_20`: Pracodawca zatrudniający 20+ pracowników -> standard 2.45% → 2.45%
else :=   {"matched":true,"rule_id":"jdg.zus.a32.r2","package":"jdg.micro.zus","priority":2348,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pracodawca zatrudniający 20+ pracowników -> standard 2.45%","_legal_basis":"Art. 104a ustawy o promocji zatrudnienia","_warnings":["[MICRO] Pracodawca zatrudniający 20+ pracowników -> standard 2.45%"]} {
    true
}

# jdg.zus.a35.r1 — `fgsp_employer_obligation`: Pracodawca -> składka na FGSP 0.10% od podstawy → 0.10%
else :=   {"matched":true,"rule_id":"jdg.zus.a35.r1","package":"jdg.micro.zus","priority":2349,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pracodawca -> składka na FGSP 0.10% od podstawy","_legal_basis":"Art. 21 ustawy o FGSP","_warnings":["[MICRO] Pracodawca -> składka na FGSP 0.10% od podstawy"]} {
    true
}

# jdg.zus.a35.r2 — `fgsp_employer_not_obligated_jdg`: JDG bez pracowników -> brak obowiązku FGSP → 0%
else :=   {"matched":true,"rule_id":"jdg.zus.a35.r2","package":"jdg.micro.zus","priority":2350,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG bez pracowników -> brak obowiązku FGSP","_legal_basis":"Art. 21 ust. 1 ustawy o FGSP","_warnings":["[MICRO] JDG bez pracowników -> brak obowiązku FGSP"]} {
    true
}

# jdg.zus.a36.r1 — `employee_guaranteed_benefits_fund`: Świadczenia z FGSP dla pracowników w razie niewypłacalności pracodawcy → Gwarancja wynagrodzeń
else :=   {"matched":true,"rule_id":"jdg.zus.a36.r1","package":"jdg.micro.zus","priority":2351,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Świadczenia z FGSP dla pracowników w razie niewypłacalności pracodawcy","_legal_basis":"Ustawa o FGSP","_warnings":["[MICRO] Świadczenia z FGSP dla pracowników w razie niewypłacalności pracodawcy"]} {
    true
}

# jdg.zus.a46.r4 — `declaration_dra_monthly`: Obowiązek składania DRA miesięcznie → DRA do 15. dnia następnego miesiąca
else :=   {"matched":true,"rule_id":"jdg.zus.a46.r4","package":"jdg.micro.zus","priority":2352,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiązek składania DRA miesięcznie","_legal_basis":"Art. 46 ust. 1 SUS","_warnings":["[MICRO] Obowiązek składania DRA miesięcznie"]} {
    true
}

# jdg.zus.a46.r5 — `declaration_dra_zero_skip`: Gdy składki = 0 (zawieszenie JDG) -> DRA nie jest wymagana → Brak obowiązku
else :=   {"matched":true,"rule_id":"jdg.zus.a46.r5","package":"jdg.micro.zus","priority":2353,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Gdy składki = 0 (zawieszenie JDG) -> DRA nie jest wymagana","_legal_basis":"Art. 46 ust. 2 SUS","_warnings":["[MICRO] Gdy składki = 0 (zawieszenie JDG) -> DRA nie jest wymagana"]} {
    true
}

# jdg.zus.a46.r6 — `declaration_rc_monthly`: Obowiązek składania RCA miesięcznie → RCA do 15. dnia następnego miesiąca
else :=   {"matched":true,"rule_id":"jdg.zus.a46.r6","package":"jdg.micro.zus","priority":2354,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiązek składania RCA miesięcznie","_legal_basis":"Art. 46 ust. 3 SUS","_warnings":["[MICRO] Obowiązek składania RCA miesięcznie"]} {
    true
}

# jdg.zus.a46.r7 — `declaration_correction_dra`: Korekta DRA w ciągu 5 lat od końca roku kalendarzowego → Korekta możliwa
else :=   {"matched":true,"rule_id":"jdg.zus.a46.r7","package":"jdg.micro.zus","priority":2355,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta DRA w ciągu 5 lat od końca roku kalendarzowego","_legal_basis":"Art. 46 ust. 4 SUS","_warnings":["[MICRO] Korekta DRA w ciągu 5 lat od końca roku kalendarzowego"]} {
    true
}

# jdg.zus.a46.r8 — `declaration_electronic_mandatory`: DRA/RCA składane elektronicznie (PUE ZUS/e-ZUS) → Obowiązek od 2024/2025
else :=   {"matched":true,"rule_id":"jdg.zus.a46.r8","package":"jdg.micro.zus","priority":2356,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"DRA/RCA składane elektronicznie (PUE ZUS/e-ZUS)","_legal_basis":"Art. 46 ust. 6 SUS","_warnings":["[MICRO] DRA/RCA składane elektronicznie (PUE ZUS/e-ZUS)"]} {
    true
}

# jdg.zus.a47.r4 — `payment_deadline_social_15th`: Składki społeczne za dany miesiąc -> do 15. dnia następnego miesiąca → Termin 15. dzień
else :=   {"matched":true,"rule_id":"jdg.zus.a47.r4","package":"jdg.micro.zus","priority":2357,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Składki społeczne za dany miesiąc -> do 15. dnia następnego miesiąca","_legal_basis":"Art. 47 ust. 1 SUS","_warnings":["[MICRO] Składki społeczne za dany miesiąc -> do 15. dnia następnego miesiąca"]} {
    true
}

# jdg.zus.a47.r5 — `payment_deadline_health_20th`: Składka zdrowotna za dany miesiąc -> do 20. dnia następnego miesiąca → Termin 20. dzień
else :=   {"matched":true,"rule_id":"jdg.zus.a47.r5","package":"jdg.micro.zus","priority":2358,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Składka zdrowotna za dany miesiąc -> do 20. dnia następnego miesiąca","_legal_basis":"Art. 79b ustawy zdrowotnej","_warnings":["[MICRO] Składka zdrowotna za dany miesiąc -> do 20. dnia następnego miesiąca"]} {
    true
}

# jdg.zus.a47.r6 — `payment_deadline_weekend_rule`: Termin wypada w weekend -> ostatni dzień roboczy przed weekendem → Przesunięcie
else :=   {"matched":true,"rule_id":"jdg.zus.a47.r6","package":"jdg.micro.zus","priority":2359,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Termin wypada w weekend -> ostatni dzień roboczy przed weekendem","_legal_basis":"Art. 12 par. 5 Ordynacji podatkowej","_warnings":["[MICRO] Termin wypada w weekend -> ostatni dzień roboczy przed weekendem"]} {
    true
}

# jdg.zus.a47.r7 — `payment_interest_after_deadline`: Po terminie -> odsetki za zwłokę (stawka 200% lombardowej NBP) → Odsetki
else :=   {"matched":true,"rule_id":"jdg.zus.a47.r7","package":"jdg.micro.zus","priority":2360,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Po terminie -> odsetki za zwłokę (stawka 200% lombardowej NBP)","_legal_basis":"Art. 47 ust. 2 SUS","_warnings":["[MICRO] Po terminie -> odsetki za zwłokę (stawka 200% lombardowej NBP)"]} {
    true
}

# jdg.zus.a6.r10 — `insurance_mandatory_board_member`: Członek rady nadzorczej wynagradzany → Obowiązkowe ubezpieczenia
else :=   {"matched":true,"rule_id":"jdg.zus.a6.r10","package":"jdg.micro.zus","priority":2361,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Członek rady nadzorczej wynagradzany","_legal_basis":"Art. 6 ust. 1 pkt 22 SUS","_warnings":["[MICRO] Członek rady nadzorczej wynagradzany"]} {
    true
}

# jdg.zus.a6.r11 — `insurance_mandatory_priest`: Osoba duchowna → Obowiązkowe ubezpieczenia
else :=   {"matched":true,"rule_id":"jdg.zus.a6.r11","package":"jdg.micro.zus","priority":2362,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Osoba duchowna","_legal_basis":"Art. 6 ust. 1 pkt 16 SUS","_warnings":["[MICRO] Osoba duchowna"]} {
    true
}

# jdg.zus.a6.r12 — `insurance_mandatory_solicitor`: Aplikant radcowski, adwokacki → Obowiązkowe ubezpieczenia
else :=   {"matched":true,"rule_id":"jdg.zus.a6.r12","package":"jdg.micro.zus","priority":2363,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Aplikant radcowski, adwokacki","_legal_basis":"Art. 6 ust. 1 pkt 17 SUS","_warnings":["[MICRO] Aplikant radcowski, adwokacki"]} {
    true
}

# jdg.zus.a6.r13 — `insurance_mandatory_artist`: Artysta, twórca → Obowiązkowe ubezpieczenia
else :=   {"matched":true,"rule_id":"jdg.zus.a6.r13","package":"jdg.micro.zus","priority":2364,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Artysta, twórca","_legal_basis":"Art. 6 ust. 1 pkt 20 SUS","_warnings":["[MICRO] Artysta, twórca"]} {
    true
}

# jdg.zus.a6.r14 — `insurance_mandatory_foster_parent`: Rodzina zastępcza zawodowa → Obowiązkowe ubezpieczenia
else :=   {"matched":true,"rule_id":"jdg.zus.a6.r14","package":"jdg.micro.zus","priority":2365,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rodzina zastępcza zawodowa","_legal_basis":"Art. 6 ust. 1 pkt 23 SUS","_warnings":["[MICRO] Rodzina zastępcza zawodowa"]} {
    true
}

# jdg.zus.a6.r15 — `insurance_mandatory_physician`: Lekarz, lekarz dentysta wykonujący zawód w ramach JDG → Obowiązkowe ubezpieczenia
else :=   {"matched":true,"rule_id":"jdg.zus.a6.r15","package":"jdg.micro.zus","priority":2366,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Lekarz, lekarz dentysta wykonujący zawód w ramach JDG","_legal_basis":"Art. 6 ust. 1 pkt 5 w zw. z Art. 8 ust. 6 SUS","_warnings":["[MICRO] Lekarz, lekarz dentysta wykonujący zawód w ramach JDG"]} {
    true
}

# jdg.zus.a6.r7 — `insurance_mandatory_cooperative`: Członek spółdzielni (dodatkowa działalność) → Obowiązkowe ubezpieczenia
else :=   {"matched":true,"rule_id":"jdg.zus.a6.r7","package":"jdg.micro.zus","priority":2367,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Członek spółdzielni (dodatkowa działalność)","_legal_basis":"Art. 6 ust. 1 pkt 6 SUS","_warnings":["[MICRO] Członek spółdzielni (dodatkowa działalność)"]} {
    true
}

# jdg.zus.a6.r8 — `insurance_mandatory_commission_contract`: Osoba wykonująca umowę zlecenia → Obowiązkowe ubezpieczenia
else :=   {"matched":true,"rule_id":"jdg.zus.a6.r8","package":"jdg.micro.zus","priority":2368,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Osoba wykonująca umowę zlecenia","_legal_basis":"Art. 6 ust. 1 pkt 4 SUS","_warnings":["[MICRO] Osoba wykonująca umowę zlecenia"]} {
    true
}

# jdg.zus.a6.r9 — `insurance_mandatory_agency_contract`: Osoba wykonująca umowę agencyjną → Obowiązkowe ubezpieczenia
else :=   {"matched":true,"rule_id":"jdg.zus.a6.r9","package":"jdg.micro.zus","priority":2369,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Osoba wykonująca umowę agencyjną","_legal_basis":"Art. 6 ust. 1 pkt 4 SUS","_warnings":["[MICRO] Osoba wykonująca umowę agencyjną"]} {
    true
}

# jdg.zus.a8.r10 — `title_concurrent_multiple_jdg`: Prowadzenie 2+ JDG → Składki opłacane od jednej (wybranej lub najwyższej) podstawy
else :=   {"matched":true,"rule_id":"jdg.zus.a8.r10","package":"jdg.micro.zus","priority":2370,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Prowadzenie 2+ JDG","_legal_basis":"Art. 9 ust. 4 SUS","_warnings":["[MICRO] Prowadzenie 2+ JDG"]} {
    true
}

# jdg.zus.a8.r11 — `title_concurrent_rent_pension_jdg`: Zbieg emerytury/renty z JDG → Obowiązkowe składki na ubezpieczenia społeczne z JDG
else :=   {"matched":true,"rule_id":"jdg.zus.a8.r11","package":"jdg.micro.zus","priority":2371,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zbieg emerytury/renty z JDG","_legal_basis":"Art. 9 ust. 6 SUS","_warnings":["[MICRO] Zbieg emerytury/renty z JDG"]} {
    true
}

# jdg.zus.a8.r12 — `title_concurrent_agricultural_jdg`: Zbieg działalności rolniczej z JDG → Obowiązkowe składki społeczne z JDG (chyba że KRUS)
else :=   {"matched":true,"rule_id":"jdg.zus.a8.r12","package":"jdg.micro.zus","priority":2372,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zbieg działalności rolniczej z JDG","_legal_basis":"Art. 9 ust. 1 pkt 5 SUS","_warnings":["[MICRO] Zbieg działalności rolniczej z JDG"]} {
    true
}

# jdg.zus.a8.r13 — `title_concurrent_student_jdg`: Zbieg statusu studenta <26 lat z JDG → Student: NIE podlega ZUS z tytułu studiów; JDG: pełne składki
else :=   {"matched":true,"rule_id":"jdg.zus.a8.r13","package":"jdg.micro.zus","priority":2373,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zbieg statusu studenta <26 lat z JDG","_legal_basis":"Art. 6 ust. 1 pkt 4 w zw. z Art. 9 SUS","_warnings":["[MICRO] Zbieg statusu studenta <26 lat z JDG"]} {
    true
}

# jdg.zus.a8.r14 — `title_cessation_of_concurrent_title`: Ustanie tytułu do ubezpieczeń z etatu/zlecenia w trakcie trwania JDG → JDG: automatycznie pełne składki społeczne od ...
else :=   {"matched":true,"rule_id":"jdg.zus.a8.r14","package":"jdg.micro.zus","priority":2374,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ustanie tytułu do ubezpieczeń z etatu/zlecenia w trakcie trwania JDG","_legal_basis":"Art. 9 ust. 5 SUS","_warnings":["[MICRO] Ustanie tytułu do ubezpieczeń z etatu/zlecenia w trakcie trwania JDG"]} {
    true
}

# jdg.zus.a8.r15 — `title_concurrent_preferential_jdg`: Zbieg: JDG na preferencyjnym ZUS + inny tytuł → Preferencyjny ZUS NIE dotyczy — standardowe składki
else :=   {"matched":true,"rule_id":"jdg.zus.a8.r15","package":"jdg.micro.zus","priority":2375,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zbieg: JDG na preferencyjnym ZUS + inny tytuł","_legal_basis":"Art. 18a ust. 5 SUS","_warnings":["[MICRO] Zbieg: JDG na preferencyjnym ZUS + inny tytuł"]} {
    true
}

# jdg.zus.a8.r6 — `title_concurrent_employee_plus_jdg`: Zbieg etatu (pracownik) z JDG → JDG: tylko dobrowolne chorobowe, reszta z etatu
else :=   {"matched":true,"rule_id":"jdg.zus.a8.r6","package":"jdg.micro.zus","priority":2376,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zbieg etatu (pracownik) z JDG","_legal_basis":"Art. 9 ust. 1a SUS","_warnings":["[MICRO] Zbieg etatu (pracownik) z JDG"]} {
    true
}

# jdg.zus.a8.r7 — `title_concurrent_employee_jdg_same_base`: Zbieg: etat (podstawa >= min. wynagr.) + JDG → Z JDG tylko składka zdrowotna (NIE społeczne)
else :=   {"matched":true,"rule_id":"jdg.zus.a8.r7","package":"jdg.micro.zus","priority":2377,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zbieg: etat (podstawa >= min. wynagr.) + JDG","_legal_basis":"Art. 9 ust. 1c SUS","_warnings":["[MICRO] Zbieg: etat (podstawa >= min. wynagr.) + JDG"]} {
    true
}

# jdg.zus.a8.r8 — `title_concurrent_mandate_jdg`: Zbieg umowy zlecenia z JDG (zlecenie podstawa < min. wynagr.) → JDG płaci pełne składki społeczne
else :=   {"matched":true,"rule_id":"jdg.zus.a8.r8","package":"jdg.micro.zus","priority":2378,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zbieg umowy zlecenia z JDG (zlecenie podstawa < min. wynagr.)","_legal_basis":"Art. 9 ust. 2 SUS","_warnings":["[MICRO] Zbieg umowy zlecenia z JDG (zlecenie podstawa < min. wynagr.)"]} {
    true
}

# jdg.zus.a8.r9 — `title_concurrent_mandate_above_minimum`: Zbieg umowy zlecenia (podstawa >= min. wynagr.) z JDG → Zlecenie: pełne składki; JDG: tylko zdrowotna
else :=   {"matched":true,"rule_id":"jdg.zus.a8.r9","package":"jdg.micro.zus","priority":2379,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zbieg umowy zlecenia (podstawa >= min. wynagr.) z JDG","_legal_basis":"Art. 9 ust. 2a SUS","_warnings":["[MICRO] Zbieg umowy zlecenia (podstawa >= min. wynagr.) z JDG"]} {
    true
}

# jdg.zus.a9.r10 — `exclusion_parental_benefit_jdg`: Przedsiębiorca pobierający zasiłek macierzyński → Zwolnienie ze składek społecznych
else :=   {"matched":true,"rule_id":"jdg.zus.a9.r10","package":"jdg.micro.zus","priority":2380,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedsiębiorca pobierający zasiłek macierzyński","_legal_basis":"Art. 9 ust. 1e SUS","_warnings":["[MICRO] Przedsiębiorca pobierający zasiłek macierzyński"]} {
    true
}

# jdg.zus.a9.r11 — `exclusion_incarceration_jdg`: Przedsiębiorca tymczasowo aresztowany → Zwolnienie ze składek społecznych
else :=   {"matched":true,"rule_id":"jdg.zus.a9.r11","package":"jdg.micro.zus","priority":2381,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedsiębiorca tymczasowo aresztowany","_legal_basis":"Art. 9 ust. 1f SUS","_warnings":["[MICRO] Przedsiębiorca tymczasowo aresztowany"]} {
    true
}

# jdg.zus.a9.r12 — `exclusion_pre_retirement_benefit_jdg`: Przedsiębiorca pobierający świadczenie przedemerytalne → Zwolnienie ze składek społecznych
else :=   {"matched":true,"rule_id":"jdg.zus.a9.r12","package":"jdg.micro.zus","priority":2382,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedsiębiorca pobierający świadczenie przedemerytalne","_legal_basis":"Art. 9 ust. 1g SUS","_warnings":["[MICRO] Przedsiębiorca pobierający świadczenie przedemerytalne"]} {
    true
}

# jdg.zus.a9.r13 — `exclusion_holiday_contribution_jdg`: Przedsiębiorca z opłaconą składką za wakacje (ulga) → Zwolnienie ze składek społecznych za okres wakacji
else :=   {"matched":true,"rule_id":"jdg.zus.a9.r13","package":"jdg.micro.zus","priority":2383,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedsiębiorca z opłaconą składką za wakacje (ulga)","_legal_basis":"Art. 9 ust. 1h SUS","_warnings":["[MICRO] Przedsiębiorca z opłaconą składką za wakacje (ulga)"]} {
    true
}

# jdg.zus.a9.r14 — `exclusion_rehabilitation_jdg`: Przedsiębiorca pobierający świadczenie rehabilitacyjne → Zwolnienie ze składek społecznych
else :=   {"matched":true,"rule_id":"jdg.zus.a9.r14","package":"jdg.micro.zus","priority":2384,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedsiębiorca pobierający świadczenie rehabilitacyjne","_legal_basis":"Art. 9 ust. 1i SUS","_warnings":["[MICRO] Przedsiębiorca pobierający świadczenie rehabilitacyjne"]} {
    true
}

# jdg.zus.a9.r15 — `exclusion_retirement_jdg`: Przedsiębiorca osiągający wiek emerytalny (60/65 lat) — kontynuacja bez składek społecznych → Zwolnienie ze składek s...
else :=   {"matched":true,"rule_id":"jdg.zus.a9.r15","package":"jdg.micro.zus","priority":2385,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedsiębiorca osiągający wiek emerytalny (60/65 lat) — kontynuacja bez składek społecznych","_legal_basis":"Art. 9 ust. 6 SUS","_warnings":["[MICRO] Przedsiębiorca osiągający wiek emerytalny (60/65 lat) — kontynuacja bez składek społecznych"]} {
    true
}

# jdg.zus.a9.r6 — `exclusion_employee_jdg_health_only`: Pracownik na etacie z podstawą >= min. wynagr. -> JDG zwolniona ze składek społecznych → Tylko składka zdrowotna z JDG
else :=   {"matched":true,"rule_id":"jdg.zus.a9.r6","package":"jdg.micro.zus","priority":2386,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pracownik na etacie z podstawą >= min. wynagr. -> JDG zwolniona ze składek społecznych","_legal_basis":"Art. 9 ust. 1a SUS","_warnings":["[MICRO] Pracownik na etacie z podstawą >= min. wynagr. -> JDG zwolniona ze składek społecznych"]} {
    true
}

# jdg.zus.a9.r7 — `exclusion_maternity_leave_jdg`: Przedsiębiorca na urlopie macierzyńskim/rodzicielskim → Zwolnienie ze składek społecznych (nie zdrowotnej)
else :=   {"matched":true,"rule_id":"jdg.zus.a9.r7","package":"jdg.micro.zus","priority":2387,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedsiębiorca na urlopie macierzyńskim/rodzicielskim","_legal_basis":"Art. 9 ust. 1b SUS","_warnings":["[MICRO] Przedsiębiorca na urlopie macierzyńskim/rodzicielskim"]} {
    true
}

# jdg.zus.a9.r8 — `exclusion_sick_benefit_jdg`: Przedsiębiorca pobierający zasiłek chorobowy >30 dni → Zwolnienie ze składek społecznych (nie zdrowotnej)
else :=   {"matched":true,"rule_id":"jdg.zus.a9.r8","package":"jdg.micro.zus","priority":2388,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedsiębiorca pobierający zasiłek chorobowy >30 dni","_legal_basis":"Art. 9 ust. 1c SUS","_warnings":["[MICRO] Przedsiębiorca pobierający zasiłek chorobowy >30 dni"]} {
    true
}

# jdg.zus.a9.r9 — `exclusion_care_benefit_jdg`: Przedsiębiorca pobierający zasiłek opiekuńczy → Zwolnienie ze składek społecznych
else :=   {"matched":true,"rule_id":"jdg.zus.a9.r9","package":"jdg.micro.zus","priority":2389,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedsiębiorca pobierający zasiłek opiekuńczy","_legal_basis":"Art. 9 ust. 1d SUS","_warnings":["[MICRO] Przedsiębiorca pobierający zasiłek opiekuńczy"]} {
    true
}

# jdg.zus.base.r1 — `zus_base_declared_60pct`: Podstawa = zadeklarowana kwota, nie nizsza niz 60% prognozowanego przecietnego wynagrodzenia → Minimum
else :=   {"matched":true,"rule_id":"jdg.zus.base.r1","package":"jdg.micro.zus","priority":2390,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa = zadeklarowana kwota, nie nizsza niz 60% prognozowanego przecietnego wynagrodzenia","_legal_basis":"Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG","_warnings":["[MICRO] Podstawa = zadeklarowana kwota, nie nizsza niz 60% prognozowanego przecietnego wynagrodzenia"]} {
    true
}

# jdg.zus.base.r10 — `zus_base_sickness_ceiling`: Podstawa zasiłku chorobowego ograniczona do 250% prognozowanego wynagrodzenia → Limit
else :=   {"matched":true,"rule_id":"jdg.zus.base.r10","package":"jdg.micro.zus","priority":2391,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa zasiłku chorobowego ograniczona do 250% prognozowanego wynagrodzenia","_legal_basis":"Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG","_warnings":["[MICRO] Podstawa zasiłku chorobowego ograniczona do 250% prognozowanego wynagrodzenia"]} {
    true
}

# jdg.zus.base.r11 — `zus_base_annual_recalculation`: Roczna korekta skladek (jesli podstawa byla nizsza niz faktyczny przychod < 60%) → Roczne
else :=   {"matched":true,"rule_id":"jdg.zus.base.r11","package":"jdg.micro.zus","priority":2392,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roczna korekta skladek (jesli podstawa byla nizsza niz faktyczny przychod < 60%)","_legal_basis":"Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG","_warnings":["[MICRO] Roczna korekta skladek (jesli podstawa byla nizsza niz faktyczny przychod < 60%)"]} {
    true
}

# jdg.zus.base.r12 — `zus_base_months_without_income`: Miesiace bez przychodu -> podstawa minimalna (60% prognozowanego) → Minimum
else :=   {"matched":true,"rule_id":"jdg.zus.base.r12","package":"jdg.micro.zus","priority":2393,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Miesiace bez przychodu -> podstawa minimalna (60% prognozowanego)","_legal_basis":"Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG","_warnings":["[MICRO] Miesiace bez przychodu -> podstawa minimalna (60% prognozowanego)"]} {
    true
}

# jdg.zus.base.r13 — `zus_base_sick_leave_reduction`: Chorobowe powyzej 33 dni (lub 14 dla JDG >50 lat) -> ZUS placi zasilek, skladki zawieszone → Zawieszenie
else :=   {"matched":true,"rule_id":"jdg.zus.base.r13","package":"jdg.micro.zus","priority":2394,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Chorobowe powyzej 33 dni (lub 14 dla JDG >50 lat) -> ZUS placi zasilek, skladki zawieszone","_legal_basis":"Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG","_warnings":["[MICRO] Chorobowe powyzej 33 dni (lub 14 dla JDG >50 lat) -> ZUS placi zasilek, skladki zawieszone"]} {
    true
}

# jdg.zus.base.r14 — `zus_base_pregnancy_protection`: Ciąza -> ochrona, ZUS placi zasilek macierzynski przez rok → Macierzynski
else :=   {"matched":true,"rule_id":"jdg.zus.base.r14","package":"jdg.micro.zus","priority":2395,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ciąza -> ochrona, ZUS placi zasilek macierzynski przez rok","_legal_basis":"Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG","_warnings":["[MICRO] Ciąza -> ochrona, ZUS placi zasilek macierzynski przez rok"]} {
    true
}

# jdg.zus.base.r15 — `zus_base_new_business_2_year_pref`: Nowa JDG: preferencyjny ZUS przez 2 lata (nie dotyczy jesli juz prowadzila dzialalnosc) → Warunek
else :=   {"matched":true,"rule_id":"jdg.zus.base.r15","package":"jdg.micro.zus","priority":2396,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nowa JDG: preferencyjny ZUS przez 2 lata (nie dotyczy jesli juz prowadzila dzialalnosc)","_legal_basis":"Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG","_warnings":["[MICRO] Nowa JDG: preferencyjny ZUS przez 2 lata (nie dotyczy jesli juz prowadzila dzialalnosc)"]} {
    true
}

# jdg.zus.base.r2 — `zus_base_minimum_2024`: Minimalna podstawa (60% prognozowanego przecietnego wynagrodzenia) → ~4 800 PLN (2025)
else :=   {"matched":true,"rule_id":"jdg.zus.base.r2","package":"jdg.micro.zus","priority":2397,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Minimalna podstawa (60% prognozowanego przecietnego wynagrodzenia)","_legal_basis":"Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG","_warnings":["[MICRO] Minimalna podstawa (60% prognozowanego przecietnego wynagrodzenia)"]} {
    true
}

# jdg.zus.base.r3 — `zus_base_maximum_30x`: Maksymalna podstawa: 30-krotnosc prognozowanego przecietnego wynagrodzenia → ~234 000 PLN (2025)
else :=   {"matched":true,"rule_id":"jdg.zus.base.r3","package":"jdg.micro.zus","priority":2398,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Maksymalna podstawa: 30-krotnosc prognozowanego przecietnego wynagrodzenia","_legal_basis":"Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG","_warnings":["[MICRO] Maksymalna podstawa: 30-krotnosc prognozowanego przecietnego wynagrodzenia"]} {
    true
}

# jdg.zus.base.r4 — `zus_base_30x_cutoff`: Po przekroczeniu 30x w danym roku -> skladki ZUS nie sa juz naliczane (emeryt+rent) → Odciecie
else :=   {"matched":true,"rule_id":"jdg.zus.base.r4","package":"jdg.micro.zus","priority":2399,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Po przekroczeniu 30x w danym roku -> skladki ZUS nie sa juz naliczane (emeryt+rent)","_legal_basis":"Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG","_warnings":["[MICRO] Po przekroczeniu 30x w danym roku -> skladki ZUS nie sa juz naliczane (emeryt+rent)"]} {
    true
}

# jdg.zus.base.r5 — `zus_base_first_year_freedom`: W pierwszym roku JDG: podstawa 30% minimalnego wynagrodzenia (ulga na start) → Obnizona
else :=   {"matched":true,"rule_id":"jdg.zus.base.r5","package":"jdg.micro.zus","priority":2400,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"W pierwszym roku JDG: podstawa 30% minimalnego wynagrodzenia (ulga na start)","_legal_basis":"Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG","_warnings":["[MICRO] W pierwszym roku JDG: podstawa 30% minimalnego wynagrodzenia (ulga na start)"]} {
    true
}

# jdg.zus.base.r6 — `zus_base_after_24_months`: Po 24 miesiacach od rozpoczecia: podstawa 60% prognozowanego wynagrodzenia → Standard
else :=   {"matched":true,"rule_id":"jdg.zus.base.r6","package":"jdg.micro.zus","priority":2401,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Po 24 miesiacach od rozpoczecia: podstawa 60% prognozowanego wynagrodzenia","_legal_basis":"Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG","_warnings":["[MICRO] Po 24 miesiacach od rozpoczecia: podstawa 60% prognozowanego wynagrodzenia"]} {
    true
}

# jdg.zus.base.r7 — `zus_base_preferential_24_months`: Preferencyjny ZUS przez 24 miesiace (maly ZUS) → ~500 PLN
else :=   {"matched":true,"rule_id":"jdg.zus.base.r7","package":"jdg.micro.zus","priority":2402,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Preferencyjny ZUS przez 24 miesiace (maly ZUS)","_legal_basis":"Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG","_warnings":["[MICRO] Preferencyjny ZUS przez 24 miesiace (maly ZUS)"]} {
    true
}

# jdg.zus.base.r8 — `zus_base_declaration_change_possible`: Mozliwosc zmiany zadeklarowanej podstawy (do maksimum) → Zmiana
else :=   {"matched":true,"rule_id":"jdg.zus.base.r8","package":"jdg.micro.zus","priority":2403,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mozliwosc zmiany zadeklarowanej podstawy (do maksimum)","_legal_basis":"Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG","_warnings":["[MICRO] Mozliwosc zmiany zadeklarowanej podstawy (do maksimum)"]} {
    true
}

# jdg.zus.base.r9 — `zus_base_sickness_sole_proprietor`: Podstawa chorobowego = srednia podstaw wymiaru z 12 miesiecy → Chorobowe
else :=   {"matched":true,"rule_id":"jdg.zus.base.r9","package":"jdg.micro.zus","priority":2404,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa chorobowego = srednia podstaw wymiaru z 12 miesiecy","_legal_basis":"Art. 18 ust. 8 SUS — Podstawa wymiaru składek JDG","_warnings":["[MICRO] Podstawa chorobowego = srednia podstaw wymiaru z 12 miesiecy"]} {
    true
}

# jdg.zus.benefit.r1 — `zus_benefit_pension_calculation`: Emerytura = suma skladek zewidencjonowanych na koncie / srednie dalsze trwanie zycia → Emerytura
else :=   {"matched":true,"rule_id":"jdg.zus.benefit.r1","package":"jdg.micro.zus","priority":2405,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Emerytura = suma skladek zewidencjonowanych na koncie / srednie dalsze trwanie zycia","_legal_basis":"Ustawa zasiłkowa — Świadczenia z ZUS","_warnings":["[MICRO] Emerytura = suma skladek zewidencjonowanych na koncie / srednie dalsze trwanie zycia"]} {
    true
}

# jdg.zus.benefit.r10 — `zus_benefit_maternity_100pct`: Zasilek macierzynski: 100% podstawy wymiaru przez 52 tygodnie → Macierzynski
else :=   {"matched":true,"rule_id":"jdg.zus.benefit.r10","package":"jdg.micro.zus","priority":2406,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zasilek macierzynski: 100% podstawy wymiaru przez 52 tygodnie","_legal_basis":"Ustawa zasiłkowa — Świadczenia z ZUS","_warnings":["[MICRO] Zasilek macierzynski: 100% podstawy wymiaru przez 52 tygodnie"]} {
    true
}

# jdg.zus.benefit.r11 — `zus_benefit_maternity_20_weeks_base`: Podstawowy urlop macierzynski: 20 tygodni (urlop rodzicielski: 32 tygodnie) → Okres
else :=   {"matched":true,"rule_id":"jdg.zus.benefit.r11","package":"jdg.micro.zus","priority":2407,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawowy urlop macierzynski: 20 tygodni (urlop rodzicielski: 32 tygodnie)","_legal_basis":"Ustawa zasiłkowa — Świadczenia z ZUS","_warnings":["[MICRO] Podstawowy urlop macierzynski: 20 tygodni (urlop rodzicielski: 32 tygodnie)"]} {
    true
}

# jdg.zus.benefit.r12 — `zus_benefit_rehabilitation_benefit`: Swiadczenie rehabilitacyjne: po wyczerpaniu zasilku, przez 12 miesiecy → Rehabilitacyjne
else :=   {"matched":true,"rule_id":"jdg.zus.benefit.r12","package":"jdg.micro.zus","priority":2408,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Swiadczenie rehabilitacyjne: po wyczerpaniu zasilku, przez 12 miesiecy","_legal_basis":"Ustawa zasiłkowa — Świadczenia z ZUS","_warnings":["[MICRO] Swiadczenie rehabilitacyjne: po wyczerpaniu zasilku, przez 12 miesiecy"]} {
    true
}

# jdg.zus.benefit.r13 — `zus_benefit_rehabilitation_90pct_then_75pct`: Swiadczenie: 90% podstawy przez 3 miesiace, 75% przez pozostale → Stawka
else :=   {"matched":true,"rule_id":"jdg.zus.benefit.r13","package":"jdg.micro.zus","priority":2409,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Swiadczenie: 90% podstawy przez 3 miesiace, 75% przez pozostale","_legal_basis":"Ustawa zasiłkowa — Świadczenia z ZUS","_warnings":["[MICRO] Swiadczenie: 90% podstawy przez 3 miesiace, 75% przez pozostale"]} {
    true
}

# jdg.zus.benefit.r14 — `zus_benefit_family_allowances`: Zasilki rodzinne, becikowe (swiadczenia rodzinne) -> kryterium dochodowe → Rodzinne
else :=   {"matched":true,"rule_id":"jdg.zus.benefit.r14","package":"jdg.micro.zus","priority":2410,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zasilki rodzinne, becikowe (swiadczenia rodzinne) -> kryterium dochodowe","_legal_basis":"Ustawa zasiłkowa — Świadczenia z ZUS","_warnings":["[MICRO] Zasilki rodzinne, becikowe (swiadczenia rodzinne) -> kryterium dochodowe"]} {
    true
}

# jdg.zus.benefit.r15 — `zus_benefit_survivor_pension`: Renta rodzinna: smierc zywiciela -> uprawnieni: malzonek, dzieci, rodzice → Renta rodzinna
else :=   {"matched":true,"rule_id":"jdg.zus.benefit.r15","package":"jdg.micro.zus","priority":2411,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Renta rodzinna: smierc zywiciela -> uprawnieni: malzonek, dzieci, rodzice","_legal_basis":"Ustawa zasiłkowa — Świadczenia z ZUS","_warnings":["[MICRO] Renta rodzinna: smierc zywiciela -> uprawnieni: malzonek, dzieci, rodzice"]} {
    true
}

# jdg.zus.benefit.r2 — `zus_benefit_pension_minimum`: Emerytura minimalna (gdy wyliczona < minimalnej) -> dopelnienie do minimalnej → Minimum
else :=   {"matched":true,"rule_id":"jdg.zus.benefit.r2","package":"jdg.micro.zus","priority":2412,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Emerytura minimalna (gdy wyliczona < minimalnej) -> dopelnienie do minimalnej","_legal_basis":"Ustawa zasiłkowa — Świadczenia z ZUS","_warnings":["[MICRO] Emerytura minimalna (gdy wyliczona < minimalnej) -> dopelnienie do minimalnej"]} {
    true
}

# jdg.zus.benefit.r3 — `zus_benefit_pension_early_if_job_before`: Wczesniejsza emerytura: prace w szczegolnych warunkach -> mozliwe → Wczesniejsza
else :=   {"matched":true,"rule_id":"jdg.zus.benefit.r3","package":"jdg.micro.zus","priority":2413,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wczesniejsza emerytura: prace w szczegolnych warunkach -> mozliwe","_legal_basis":"Ustawa zasiłkowa — Świadczenia z ZUS","_warnings":["[MICRO] Wczesniejsza emerytura: prace w szczegolnych warunkach -> mozliwe"]} {
    true
}

# jdg.zus.benefit.r4 — `zus_benefit_rent_disability`: Renta z tytulu niezdolnosci do pracy -> orzeczenie lekarza orzecznika ZUS → Renta
else :=   {"matched":true,"rule_id":"jdg.zus.benefit.r4","package":"jdg.micro.zus","priority":2414,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Renta z tytulu niezdolnosci do pracy -> orzeczenie lekarza orzecznika ZUS","_legal_basis":"Ustawa zasiłkowa — Świadczenia z ZUS","_warnings":["[MICRO] Renta z tytulu niezdolnosci do pracy -> orzeczenie lekarza orzecznika ZUS"]} {
    true
}

# jdg.zus.benefit.r5 — `zus_benefit_rent_partial_or_full`: Renta calkowita (cala niezdolnosc) lub czesciowa (czesciowa niezdolnosc) → Stopnie
else :=   {"matched":true,"rule_id":"jdg.zus.benefit.r5","package":"jdg.micro.zus","priority":2415,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Renta calkowita (cala niezdolnosc) lub czesciowa (czesciowa niezdolnosc)","_legal_basis":"Ustawa zasiłkowa — Świadczenia z ZUS","_warnings":["[MICRO] Renta calkowita (cala niezdolnosc) lub czesciowa (czesciowa niezdolnosc)"]} {
    true
}

# jdg.zus.benefit.r6 — `zus_benefit_sickness_67pct`: Zasilek chorobowy: 80% podstawy wymiaru (lub 67% po 33 dniach) → Stawka
else :=   {"matched":true,"rule_id":"jdg.zus.benefit.r6","package":"jdg.micro.zus","priority":2416,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zasilek chorobowy: 80% podstawy wymiaru (lub 67% po 33 dniach)","_legal_basis":"Ustawa zasiłkowa — Świadczenia z ZUS","_warnings":["[MICRO] Zasilek chorobowy: 80% podstawy wymiaru (lub 67% po 33 dniach)"]} {
    true
}

# jdg.zus.benefit.r7 — `zus_benefit_sickness_self_pay_33_days`: JDG sama placi zasilek za pierwsze 33 dni (lub 14 dni dla >50 lat) w roku → Samoplatny
else :=   {"matched":true,"rule_id":"jdg.zus.benefit.r7","package":"jdg.micro.zus","priority":2417,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG sama placi zasilek za pierwsze 33 dni (lub 14 dni dla >50 lat) w roku","_legal_basis":"Ustawa zasiłkowa — Świadczenia z ZUS","_warnings":["[MICRO] JDG sama placi zasilek za pierwsze 33 dni (lub 14 dni dla >50 lat) w roku"]} {
    true
}

# jdg.zus.benefit.r8 — `zus_benefit_sickness_zus_pays_after_33`: Od 34. dnia -> ZUS placi zasilek chorobowy → ZUS
else :=   {"matched":true,"rule_id":"jdg.zus.benefit.r8","package":"jdg.micro.zus","priority":2418,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Od 34. dnia -> ZUS placi zasilek chorobowy","_legal_basis":"Ustawa zasiłkowa — Świadczenia z ZUS","_warnings":["[MICRO] Od 34. dnia -> ZUS placi zasilek chorobowy"]} {
    true
}

# jdg.zus.benefit.r9 — `zus_benefit_sickness_max_182_days`: Maksymalny okres zasilku chorobowego: 182 dni (270 dla gruzlicy) → Max
else :=   {"matched":true,"rule_id":"jdg.zus.benefit.r9","package":"jdg.micro.zus","priority":2419,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Maksymalny okres zasilku chorobowego: 182 dni (270 dla gruzlicy)","_legal_basis":"Ustawa zasiłkowa — Świadczenia z ZUS","_warnings":["[MICRO] Maksymalny okres zasilku chorobowego: 182 dni (270 dla gruzlicy)"]} {
    true
}

# jdg.zus.deadline.r1 — `zus_deadline_monthly_15th`: Skladki ZUS za dany miesiac platne do 15. dnia nastepnego miesiaca → Termin
else :=   {"matched":true,"rule_id":"jdg.zus.deadline.r1","package":"jdg.micro.zus","priority":2420,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skladki ZUS za dany miesiac platne do 15. dnia nastepnego miesiaca","_legal_basis":"Art. 47 SUS — Terminy płatności składek","_warnings":["[MICRO] Skladki ZUS za dany miesiac platne do 15. dnia nastepnego miesiaca"]} {
    true
}

# jdg.zus.deadline.r10 — `zus_declaration_annual_correction`: Korekta deklaracji rocznej: po terminie -> odsetki → Korekta
else :=   {"matched":true,"rule_id":"jdg.zus.deadline.r10","package":"jdg.micro.zus","priority":2421,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta deklaracji rocznej: po terminie -> odsetki","_legal_basis":"Art. 47 SUS — Terminy płatności składek","_warnings":["[MICRO] Korekta deklaracji rocznej: po terminie -> odsetki"]} {
    true
}

# jdg.zus.deadline.r2 — `zus_deadline_15th_calendar`: Termin 15. dnia miesiaca za miesiac poprzedni (w cywilu: dzien 15-tego) → Termin
else :=   {"matched":true,"rule_id":"jdg.zus.deadline.r2","package":"jdg.micro.zus","priority":2422,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Termin 15. dnia miesiaca za miesiac poprzedni (w cywilu: dzien 15-tego)","_legal_basis":"Art. 47 SUS — Terminy płatności składek","_warnings":["[MICRO] Termin 15. dnia miesiaca za miesiac poprzedni (w cywilu: dzien 15-tego)"]} {
    true
}

# jdg.zus.deadline.r3 — `zus_deadline_weekend_shift`: Jesli 15. wypada w sobote/niule -> termin nastepny dzien roboczy → Przesuniecie
else :=   {"matched":true,"rule_id":"jdg.zus.deadline.r3","package":"jdg.micro.zus","priority":2423,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Jesli 15. wypada w sobote/niule -> termin nastepny dzien roboczy","_legal_basis":"Art. 47 SUS — Terminy płatności składek","_warnings":["[MICRO] Jesli 15. wypada w sobote/niule -> termin nastepny dzien roboczy"]} {
    true
}

# jdg.zus.deadline.r4 — `zus_deadline_health_by_20th`: Skladka zdrowotna: do 20. dnia nastepnego miesiaca → Termin
else :=   {"matched":true,"rule_id":"jdg.zus.deadline.r4","package":"jdg.micro.zus","priority":2424,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skladka zdrowotna: do 20. dnia nastepnego miesiaca","_legal_basis":"Art. 47 SUS — Terminy płatności składek","_warnings":["[MICRO] Skladka zdrowotna: do 20. dnia nastepnego miesiaca"]} {
    true
}

# jdg.zus.deadline.r5 — `zus_deadline_health_20th_shift`: Przesuniecie jak dla 15. (weekend) → Przesuniecie
else :=   {"matched":true,"rule_id":"jdg.zus.deadline.r5","package":"jdg.micro.zus","priority":2425,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przesuniecie jak dla 15. (weekend)","_legal_basis":"Art. 47 SUS — Terminy płatności składek","_warnings":["[MICRO] Przesuniecie jak dla 15. (weekend)"]} {
    true
}

# jdg.zus.deadline.r6 — `zus_declaration_dra_monthly`: Deklaracja ZUS DRA miesieczna: do 15. dnia nastepnego miesiaca → Deklaracja
else :=   {"matched":true,"rule_id":"jdg.zus.deadline.r6","package":"jdg.micro.zus","priority":2426,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Deklaracja ZUS DRA miesieczna: do 15. dnia nastepnego miesiaca","_legal_basis":"Art. 47 SUS — Terminy płatności składek","_warnings":["[MICRO] Deklaracja ZUS DRA miesieczna: do 15. dnia nastepnego miesiaca"]} {
    true
}

# jdg.zus.deadline.r7 — `zus_declaration_zua_new_employee_7_days`: Zgloszenie nowego pracownika do ZUS: w 7 dni od rozpoczecia pracy → Zgloszenie
else :=   {"matched":true,"rule_id":"jdg.zus.deadline.r7","package":"jdg.micro.zus","priority":2427,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zgloszenie nowego pracownika do ZUS: w 7 dni od rozpoczecia pracy","_legal_basis":"Art. 47 SUS — Terminy płatności składek","_warnings":["[MICRO] Zgloszenie nowego pracownika do ZUS: w 7 dni od rozpoczecia pracy"]} {
    true
}

# jdg.zus.deadline.r8 — `zus_declaration_zya_withdrawal_7_days`: Wyrejestrowanie z ZUS: w 7 dni od zakonczenia tytulu → Wyrejestrowanie
else :=   {"matched":true,"rule_id":"jdg.zus.deadline.r8","package":"jdg.micro.zus","priority":2428,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wyrejestrowanie z ZUS: w 7 dni od zakonczenia tytulu","_legal_basis":"Art. 47 SUS — Terminy płatności składek","_warnings":["[MICRO] Wyrejestrowanie z ZUS: w 7 dni od zakonczenia tytulu"]} {
    true
}

# jdg.zus.deadline.r9 — `zus_declaration_annual_rozliczenie`: Deklaracja roczna ZUS DRA do 31 lipca nastepnego roku → Roczne
else :=   {"matched":true,"rule_id":"jdg.zus.deadline.r9","package":"jdg.micro.zus","priority":2429,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Deklaracja roczna ZUS DRA do 31 lipca nastepnego roku","_legal_basis":"Art. 47 SUS — Terminy płatności składek","_warnings":["[MICRO] Deklaracja roczna ZUS DRA do 31 lipca nastepnego roku"]} {
    true
}

# jdg.zus.rate.r1 — `zus_rate_pension_19_52pct`: Emerytalna (JDG) → 19.52%
else :=   {"matched":true,"rule_id":"jdg.zus.rate.r1","package":"jdg.micro.zus","priority":2430,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Emerytalna (JDG)","_legal_basis":"Art. 22 ustawy SUS","_warnings":["[MICRO] Emerytalna (JDG)"]} {
    true
}

# jdg.zus.rate.r10 — `zus_rate_employer_pension_9_76pct`: Emerytalna platnika za pracownika → 9.76%
else :=   {"matched":true,"rule_id":"jdg.zus.rate.r10","package":"jdg.micro.zus","priority":2431,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Emerytalna platnika za pracownika","_legal_basis":"Art. 16 ustawy SUS","_warnings":["[MICRO] Emerytalna platnika za pracownika"]} {
    true
}

# jdg.zus.rate.r11 — `zus_rate_employer_rent_6_5pct`: Rentowa platnika za pracownika → 6.50%
else :=   {"matched":true,"rule_id":"jdg.zus.rate.r11","package":"jdg.micro.zus","priority":2432,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rentowa platnika za pracownika","_legal_basis":"Art. 16 ustawy SUS","_warnings":["[MICRO] Rentowa platnika za pracownika"]} {
    true
}

# jdg.zus.rate.r12 — `zus_rate_employer_accident_0_67_3_33pct`: Wypadkowa za pracownika → 0.67%-3.33%
else :=   {"matched":true,"rule_id":"jdg.zus.rate.r12","package":"jdg.micro.zus","priority":2433,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wypadkowa za pracownika","_legal_basis":"Art. 16 ustawy SUS","_warnings":["[MICRO] Wypadkowa za pracownika"]} {
    true
}

# jdg.zus.rate.r13 — `zus_rate_employer_fp_2_45pct`: Fundusz Pracy za pracownika → 2.45%
else :=   {"matched":true,"rule_id":"jdg.zus.rate.r13","package":"jdg.micro.zus","priority":2434,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Fundusz Pracy za pracownika","_legal_basis":"Art. 104 ustawy o promocji zatrudnienia","_warnings":["[MICRO] Fundusz Pracy za pracownika"]} {
    true
}

# jdg.zus.rate.r14 — `zus_rate_employer_fgsp_0_10pct`: FGSP za pracownika → 0.10%
else :=   {"matched":true,"rule_id":"jdg.zus.rate.r14","package":"jdg.micro.zus","priority":2435,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"FGSP za pracownika","_legal_basis":"Art. 25 ustawy o FGSP","_warnings":["[MICRO] FGSP za pracownika"]} {
    true
}

# jdg.zus.rate.r15 — `zus_rate_total_jdg_min`: Laczna minimalna skladka ZUS dla JDG (emeryt + rent + chor + wypad + FP + FGSP) → ~30-32% podstawy
else :=   {"matched":true,"rule_id":"jdg.zus.rate.r15","package":"jdg.micro.zus","priority":2436,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Laczna minimalna skladka ZUS dla JDG (emeryt + rent + chor + wypad + FP + FGSP)","_legal_basis":"Suma skladek","_warnings":["[MICRO] Laczna minimalna skladka ZUS dla JDG (emeryt + rent + chor + wypad + FP + FGSP)"]} {
    true
}

# jdg.zus.rate.r2 — `zus_rate_rent_8_0pct`: Rentowa (JDG) → 8.00%
else :=   {"matched":true,"rule_id":"jdg.zus.rate.r2","package":"jdg.micro.zus","priority":2437,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rentowa (JDG)","_legal_basis":"Art. 22 ustawy SUS","_warnings":["[MICRO] Rentowa (JDG)"]} {
    true
}

# jdg.zus.rate.r3 — `zus_rate_sickness_2_45pct`: Chorobowa (dobrowolna, JDG) → 2.45%
else :=   {"matched":true,"rule_id":"jdg.zus.rate.r3","package":"jdg.micro.zus","priority":2438,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Chorobowa (dobrowolna, JDG)","_legal_basis":"Art. 22 ustawy SUS","_warnings":["[MICRO] Chorobowa (dobrowolna, JDG)"]} {
    true
}

# jdg.zus.rate.r4 — `zus_rate_accident_0_67_3_33pct`: Wypadkowa (zalezy od PKD, JDG) → 0.67%-3.33%
else :=   {"matched":true,"rule_id":"jdg.zus.rate.r4","package":"jdg.micro.zus","priority":2439,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wypadkowa (zalezy od PKD, JDG)","_legal_basis":"Art. 22 ustawy SUS","_warnings":["[MICRO] Wypadkowa (zalezy od PKD, JDG)"]} {
    true
}

# jdg.zus.rate.r5 — `zus_rate_fund_pracy_2_45pct`: Fundusz Pracy → 2.45%
else :=   {"matched":true,"rule_id":"jdg.zus.rate.r5","package":"jdg.micro.zus","priority":2440,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Fundusz Pracy","_legal_basis":"Art. 104 ustawy o promocji zatrudnienia","_warnings":["[MICRO] Fundusz Pracy"]} {
    true
}

# jdg.zus.rate.r6 — `zus_rate_fgsp_0_10pct`:  → 0.10%
else :=   {"matched":true,"rule_id":"jdg.zus.rate.r6","package":"jdg.micro.zus","priority":2441,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"","_legal_basis":"Art. 25 ustawy o FGSP","_warnings":["[MICRO] Fundusz Pracy"]} {
    true
}

# jdg.zus.rate.r7 — `zus_rate_employee_pension_9_76pct`: Emerytalna pracownika → 9.76%
else :=   {"matched":true,"rule_id":"jdg.zus.rate.r7","package":"jdg.micro.zus","priority":2442,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Emerytalna pracownika","_legal_basis":"Art. 16 ustawy SUS","_warnings":["[MICRO] Emerytalna pracownika"]} {
    true
}

# jdg.zus.rate.r8 — `zus_rate_employee_rent_4_5pct`: Rentowa pracownika → 4.50%
else :=   {"matched":true,"rule_id":"jdg.zus.rate.r8","package":"jdg.micro.zus","priority":2443,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rentowa pracownika","_legal_basis":"Art. 16 ustawy SUS","_warnings":["[MICRO] Rentowa pracownika"]} {
    true
}

# jdg.zus.rate.r9 — `zus_rate_employee_sickness_2_45pct`: Chorobowa pracownika → 2.45%
else :=   {"matched":true,"rule_id":"jdg.zus.rate.r9","package":"jdg.micro.zus","priority":2444,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Chorobowa pracownika","_legal_basis":"Art. 16 ustawy SUS","_warnings":["[MICRO] Chorobowa pracownika"]} {
    true
}

# jdg.zus.small_plus.r1 — `small_zus_plus_eligibility`: JDG z przychodem rocznym < 120 000 PLN (2025) w poprzednim roku → Kwalifikacja
else :=   {"matched":true,"rule_id":"jdg.zus.small_plus.r1","package":"jdg.micro.zus","priority":2445,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG z przychodem rocznym < 120 000 PLN (2025) w poprzednim roku","_legal_basis":"Art. 18c SUS — Mały ZUS Plus","_warnings":["[MICRO] JDG z przychodem rocznym < 120 000 PLN (2025) w poprzednim roku"]} {
    true
}

# jdg.zus.small_plus.r10 — `small_zus_plus_not_with_preferential_24`: Maly ZUS+ LUB preferencyjny ZUS (24 miesiace) -> nie mozna lacznie → Alternatywa
else :=   {"matched":true,"rule_id":"jdg.zus.small_plus.r10","package":"jdg.micro.zus","priority":2446,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Maly ZUS+ LUB preferencyjny ZUS (24 miesiace) -> nie mozna lacznie","_legal_basis":"Art. 18c SUS — Mały ZUS Plus","_warnings":["[MICRO] Maly ZUS+ LUB preferencyjny ZUS (24 miesiace) -> nie mozna lacznie"]} {
    true
}

# jdg.zus.small_plus.r11 — `small_zus_plus_sickness_optional`: Ubezpieczenie chorobowe w malym ZUS+ -> dobrowolne (dodatkowy koszt) → Dobrowolne
else :=   {"matched":true,"rule_id":"jdg.zus.small_plus.r11","package":"jdg.micro.zus","priority":2447,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ubezpieczenie chorobowe w malym ZUS+ -> dobrowolne (dodatkowy koszt)","_legal_basis":"Art. 18c SUS — Mały ZUS Plus","_warnings":["[MICRO] Ubezpieczenie chorobowe w malym ZUS+ -> dobrowolne (dodatkowy koszt)"]} {
    true
}

# jdg.zus.small_plus.r12 — `small_zus_plus_annual_reconciliation_july`: Roczne rozliczenie do 31 lipca nastepnego roku (korekta ZUS DRA) → Termin
else :=   {"matched":true,"rule_id":"jdg.zus.small_plus.r12","package":"jdg.micro.zus","priority":2448,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roczne rozliczenie do 31 lipca nastepnego roku (korekta ZUS DRA)","_legal_basis":"Art. 18c SUS — Mały ZUS Plus","_warnings":["[MICRO] Roczne rozliczenie do 31 lipca nastepnego roku (korekta ZUS DRA)"]} {
    true
}

# jdg.zus.small_plus.r13 — `small_zus_plus_over_limit_sanctions`: Brak korekty po przekroczeniu -> sankcje: odsetki + naliczenie pelnych skladek → Sankcje
else :=   {"matched":true,"rule_id":"jdg.zus.small_plus.r13","package":"jdg.micro.zus","priority":2449,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak korekty po przekroczeniu -> sankcje: odsetki + naliczenie pelnych skladek","_legal_basis":"Art. 18c SUS — Mały ZUS Plus","_warnings":["[MICRO] Brak korekty po przekroczeniu -> sankcje: odsetki + naliczenie pelnych skladek"]} {
    true
}

# jdg.zus.small_plus.r14 — `small_zus_plus_health_insurance_base`: Podstawa skladki zdrowotnej = zadeklarowana (maly ZUS+ nie wplywa na zdrowotna) → Zdrowotna
else :=   {"matched":true,"rule_id":"jdg.zus.small_plus.r14","package":"jdg.micro.zus","priority":2450,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa skladki zdrowotnej = zadeklarowana (maly ZUS+ nie wplywa na zdrowotna)","_legal_basis":"Art. 18c SUS — Mały ZUS Plus","_warnings":["[MICRO] Podstawa skladki zdrowotnej = zadeklarowana (maly ZUS+ nie wplywa na zdrowotna)"]} {
    true
}

# jdg.zus.small_plus.r15 — `small_zus_plus_cessation_annual_obligation`: Koniec malego ZUS+ po uplywie roku podatkowego → Koniec
else :=   {"matched":true,"rule_id":"jdg.zus.small_plus.r15","package":"jdg.micro.zus","priority":2451,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koniec malego ZUS+ po uplywie roku podatkowego","_legal_basis":"Art. 18c SUS — Mały ZUS Plus","_warnings":["[MICRO] Koniec malego ZUS+ po uplywie roku podatkowego"]} {
    true
}

# jdg.zus.small_plus.r2 — `small_zus_plus_base_calculation`: Podstawa = 30% minimalnego wynagrodzenia x (przychod / 120 000) → Wzor
else :=   {"matched":true,"rule_id":"jdg.zus.small_plus.r2","package":"jdg.micro.zus","priority":2452,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa = 30% minimalnego wynagrodzenia x (przychod / 120 000)","_legal_basis":"Art. 18c SUS — Mały ZUS Plus","_warnings":["[MICRO] Podstawa = 30% minimalnego wynagrodzenia x (przychod / 120 000)"]} {
    true
}

# jdg.zus.small_plus.r3 — `small_zus_plus_min_base`: Minimalna podstawa: 30% minimalnego wynagrodzenia → Minimum
else :=   {"matched":true,"rule_id":"jdg.zus.small_plus.r3","package":"jdg.micro.zus","priority":2453,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Minimalna podstawa: 30% minimalnego wynagrodzenia","_legal_basis":"Art. 18c SUS — Mały ZUS Plus","_warnings":["[MICRO] Minimalna podstawa: 30% minimalnego wynagrodzenia"]} {
    true
}

# jdg.zus.small_plus.r4 — `small_zus_plus_max_base`: Maksymalna podstawa: 60% prognozowanego przecietnego wynagrodzenia → Maksimum
else :=   {"matched":true,"rule_id":"jdg.zus.small_plus.r4","package":"jdg.micro.zus","priority":2454,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Maksymalna podstawa: 60% prognozowanego przecietnego wynagrodzenia","_legal_basis":"Art. 18c SUS — Mały ZUS Plus","_warnings":["[MICRO] Maksymalna podstawa: 60% prognozowanego przecietnego wynagrodzenia"]} {
    true
}

# jdg.zus.small_plus.r5 — `small_zus_plus_first_year_start`: W pierwszym roku dzialalnosci -> maly ZUS+ przez 12 miesiecy (brak limitu przychodu) → Pierwszy rok
else :=   {"matched":true,"rule_id":"jdg.zus.small_plus.r5","package":"jdg.micro.zus","priority":2455,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"W pierwszym roku dzialalnosci -> maly ZUS+ przez 12 miesiecy (brak limitu przychodu)","_legal_basis":"Art. 18c SUS — Mały ZUS Plus","_warnings":["[MICRO] W pierwszym roku dzialalnosci -> maly ZUS+ przez 12 miesiecy (brak limitu przychodu)"]} {
    true
}

# jdg.zus.small_plus.r6 — `small_zus_plus_application_annual`: ZUS ZEA: zgloszenie do malego ZUS+ w ciagu 7 dni od rozpoczecia → Zgloszenie
else :=   {"matched":true,"rule_id":"jdg.zus.small_plus.r6","package":"jdg.micro.zus","priority":2456,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"ZUS ZEA: zgloszenie do malego ZUS+ w ciagu 7 dni od rozpoczecia","_legal_basis":"Art. 18c SUS — Mały ZUS Plus","_warnings":["[MICRO] ZUS ZEA: zgloszenie do malego ZUS+ w ciagu 7 dni od rozpoczecia"]} {
    true
}

# jdg.zus.small_plus.r7 — `small_zus_plus_loss_of_right_120k`: Przekroczenie 120 000 PLN przychodu -> utrata prawa od nastepnego roku → Utrata
else :=   {"matched":true,"rule_id":"jdg.zus.small_plus.r7","package":"jdg.micro.zus","priority":2457,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przekroczenie 120 000 PLN przychodu -> utrata prawa od nastepnego roku","_legal_basis":"Art. 18c SUS — Mały ZUS Plus","_warnings":["[MICRO] Przekroczenie 120 000 PLN przychodu -> utrata prawa od nastepnego roku"]} {
    true
}

# jdg.zus.small_plus.r8 — `small_zus_plus_retroactive_correction`: W ciagu roku -> korekta gdy przychod = 120k+ (za miesiace calego roku) → Korekta
else :=   {"matched":true,"rule_id":"jdg.zus.small_plus.r8","package":"jdg.micro.zus","priority":2458,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"W ciagu roku -> korekta gdy przychod = 120k+ (za miesiace calego roku)","_legal_basis":"Art. 18c SUS — Mały ZUS Plus","_warnings":["[MICRO] W ciagu roku -> korekta gdy przychod = 120k+ (za miesiace calego roku)"]} {
    true
}

# jdg.zus.small_plus.r9 — `small_zus_plus_excluded_activities`: Wykluczone: wspolnicy sp. jawnej, komandytowej, zarzad, czlonkowie rad nadzorczych → Wykluczenie
else :=   {"matched":true,"rule_id":"jdg.zus.small_plus.r9","package":"jdg.micro.zus","priority":2459,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykluczone: wspolnicy sp. jawnej, komandytowej, zarzad, czlonkowie rad nadzorczych","_legal_basis":"Art. 18c SUS — Mały ZUS Plus","_warnings":["[MICRO] Wykluczone: wspolnicy sp. jawnej, komandytowej, zarzad, czlonkowie rad nadzorczych"]} {
    true
}

# jdg.zus.start.r1 — `start_up_relief_6_months`: Nowa JDG: zwolnienie ze skladek ZUS przez pierwsze 6 miesiecy → Zwolnienie
else :=   {"matched":true,"rule_id":"jdg.zus.start.r1","package":"jdg.micro.zus","priority":2460,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nowa JDG: zwolnienie ze skladek ZUS przez pierwsze 6 miesiecy","_legal_basis":"Art. 18a SUS — Ulga na start (6 mies.)","_warnings":["[MICRO] Nowa JDG: zwolnienie ze skladek ZUS przez pierwsze 6 miesiecy"]} {
    true
}

# jdg.zus.start.r10 — `start_up_relief_sickness_benefit_during_ulga`: Chorobowe w okresie ulgi -> jesli zgloszone dobrowolne chorobowe → Swiadczenie
else :=   {"matched":true,"rule_id":"jdg.zus.start.r10","package":"jdg.micro.zus","priority":2461,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Chorobowe w okresie ulgi -> jesli zgloszone dobrowolne chorobowe","_legal_basis":"Art. 18a SUS — Ulga na start (6 mies.)","_warnings":["[MICRO] Chorobowe w okresie ulgi -> jesli zgloszone dobrowolne chorobowe"]} {
    true
}

# jdg.zus.start.r2 — `start_up_relief_condition_first_business`: Zwolnienie dotyczy TYLKO pierwszej dzialalnosci (nie jest JDG po wznowieniu) → Warunek
else :=   {"matched":true,"rule_id":"jdg.zus.start.r2","package":"jdg.micro.zus","priority":2462,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwolnienie dotyczy TYLKO pierwszej dzialalnosci (nie jest JDG po wznowieniu)","_legal_basis":"Art. 18a SUS — Ulga na start (6 mies.)","_warnings":["[MICRO] Zwolnienie dotyczy TYLKO pierwszej dzialalnosci (nie jest JDG po wznowieniu)"]} {
    true
}

# jdg.zus.start.r3 — `start_up_relief_no_previous_business_60_months`: JDG nie prowadzila dzialalnosci w ostatnich 60 miesiacach → Warunek
else :=   {"matched":true,"rule_id":"jdg.zus.start.r3","package":"jdg.micro.zus","priority":2463,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG nie prowadzila dzialalnosci w ostatnich 60 miesiacach","_legal_basis":"Art. 18a SUS — Ulga na start (6 mies.)","_warnings":["[MICRO] JDG nie prowadzila dzialalnosci w ostatnich 60 miesiacach"]} {
    true
}

# jdg.zus.start.r4 — `start_up_relief_health_insurance_excluded`: Ulga na start NIE obejmuje skladki zdrowotnej (trzeba placic) → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.zus.start.r4","package":"jdg.micro.zus","priority":2464,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga na start NIE obejmuje skladki zdrowotnej (trzeba placic)","_legal_basis":"Art. 18a SUS — Ulga na start (6 mies.)","_warnings":["[MICRO] Ulga na start NIE obejmuje skladki zdrowotnej (trzeba placic)"]} {
    true
}

# jdg.zus.start.r5 — `start_up_relief_voluntary_insurance_option`: Mozliwosc dobrowolnego ubezpieczenia emerytalno-rentowego w okresie ulgi → Opcja
else :=   {"matched":true,"rule_id":"jdg.zus.start.r5","package":"jdg.micro.zus","priority":2465,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mozliwosc dobrowolnego ubezpieczenia emerytalno-rentowego w okresie ulgi","_legal_basis":"Art. 18a SUS — Ulga na start (6 mies.)","_warnings":["[MICRO] Mozliwosc dobrowolnego ubezpieczenia emerytalno-rentowego w okresie ulgi"]} {
    true
}

# jdg.zus.start.r6 — `start_up_relief_voluntary_sickness`: Mozliwosc dobrowolnego ubezpieczenia chorobowego → Opcja
else :=   {"matched":true,"rule_id":"jdg.zus.start.r6","package":"jdg.micro.zus","priority":2466,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mozliwosc dobrowolnego ubezpieczenia chorobowego","_legal_basis":"Art. 18a SUS — Ulga na start (6 mies.)","_warnings":["[MICRO] Mozliwosc dobrowolnego ubezpieczenia chorobowego"]} {
    true
}

# jdg.zus.start.r7 — `start_up_relief_transition_to_preferential_24`: Po 6 miesiacach -> automatyczne przejscie na preferencyjny ZUS (24 miesiace) → Przejscie
else :=   {"matched":true,"rule_id":"jdg.zus.start.r7","package":"jdg.micro.zus","priority":2467,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Po 6 miesiacach -> automatyczne przejscie na preferencyjny ZUS (24 miesiace)","_legal_basis":"Art. 18a SUS — Ulga na start (6 mies.)","_warnings":["[MICRO] Po 6 miesiacach -> automatyczne przejscie na preferencyjny ZUS (24 miesiace)"]} {
    true
}

# jdg.zus.start.r8 — `start_up_relief_cessation_before_6_months`: Zawieszenie przed 6 miesiacami -> ulga nie przysluguje za miesiace zawieszenia → Zawieszenie
else :=   {"matched":true,"rule_id":"jdg.zus.start.r8","package":"jdg.micro.zus","priority":2468,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zawieszenie przed 6 miesiacami -> ulga nie przysluguje za miesiace zawieszenia","_legal_basis":"Art. 18a SUS — Ulga na start (6 mies.)","_warnings":["[MICRO] Zawieszenie przed 6 miesiacami -> ulga nie przysluguje za miesiace zawieszenia"]} {
    true
}

# jdg.zus.start.r9 — `start_up_relief_resumption_60_months`: Wznowienie po >60 miesiacach przerwy -> ponowna ulga → Ponowna ulga
else :=   {"matched":true,"rule_id":"jdg.zus.start.r9","package":"jdg.micro.zus","priority":2469,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wznowienie po >60 miesiacach przerwy -> ponowna ulga","_legal_basis":"Art. 18a SUS — Ulga na start (6 mies.)","_warnings":["[MICRO] Wznowienie po >60 miesiacach przerwy -> ponowna ulga"]} {
    true
}

# jdg.zus.suspension.r1 — `zus_suspension_cessation_of_obligation`: Zawieszenie JDG -> ustaje obowiazek oplacania skladek ZUS od nastepnego dnia → Ustanie
else :=   {"matched":true,"rule_id":"jdg.zus.suspension.r1","package":"jdg.micro.zus","priority":2470,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zawieszenie JDG -> ustaje obowiazek oplacania skladek ZUS od nastepnego dnia","_legal_basis":"Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)","_warnings":["[MICRO] Zawieszenie JDG -> ustaje obowiazek oplacania skladek ZUS od nastepnego dnia"]} {
    true
}

# jdg.zus.suspension.r10 — `zus_suspension_sickness_benefit_during`: Chorobowe w okresie zawieszenia -> jesli dobrowolnie kontynuowane → Swiadczenie
else :=   {"matched":true,"rule_id":"jdg.zus.suspension.r10","package":"jdg.micro.zus","priority":2471,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Chorobowe w okresie zawieszenia -> jesli dobrowolnie kontynuowane","_legal_basis":"Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)","_warnings":["[MICRO] Chorobowe w okresie zawieszenia -> jesli dobrowolnie kontynuowane"]} {
    true
}

# jdg.zus.suspension.r2 — `zus_suspension_min_30_days`: Zawieszenie co najmniej 30 dni -> brak skladek ZUS za caly okres → Warunek
else :=   {"matched":true,"rule_id":"jdg.zus.suspension.r2","package":"jdg.micro.zus","priority":2472,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zawieszenie co najmniej 30 dni -> brak skladek ZUS za caly okres","_legal_basis":"Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)","_warnings":["[MICRO] Zawieszenie co najmniej 30 dni -> brak skladek ZUS za caly okres"]} {
    true
}

# jdg.zus.suspension.r3 — `zus_suspension_health_insurance`: Skladka zdrowotna: zwolnienie w okresie zawieszenia (jesli brak przychodu) → Zwolnienie
else :=   {"matched":true,"rule_id":"jdg.zus.suspension.r3","package":"jdg.micro.zus","priority":2473,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skladka zdrowotna: zwolnienie w okresie zawieszenia (jesli brak przychodu)","_legal_basis":"Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)","_warnings":["[MICRO] Skladka zdrowotna: zwolnienie w okresie zawieszenia (jesli brak przychodu)"]} {
    true
}

# jdg.zus.suspension.r4 — `zus_suspension_health_income_during`: Przychod w okresie zawieszenia (do pelnej skladki) -> obowiazek oplacenia → Wyjatek
else :=   {"matched":true,"rule_id":"jdg.zus.suspension.r4","package":"jdg.micro.zus","priority":2474,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przychod w okresie zawieszenia (do pelnej skladki) -> obowiazek oplacenia","_legal_basis":"Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)","_warnings":["[MICRO] Przychod w okresie zawieszenia (do pelnej skladki) -> obowiazek oplacenia"]} {
    true
}

# jdg.zus.suspension.r5 — `zus_suspension_voluntary_continuation`: Mozliwosc kontynuacji ubezpieczenia emerytalno-rentowego w okresie zawieszenia → Opcja
else :=   {"matched":true,"rule_id":"jdg.zus.suspension.r5","package":"jdg.micro.zus","priority":2475,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mozliwosc kontynuacji ubezpieczenia emerytalno-rentowego w okresie zawieszenia","_legal_basis":"Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)","_warnings":["[MICRO] Mozliwosc kontynuacji ubezpieczenia emerytalno-rentowego w okresie zawieszenia"]} {
    true
}

# jdg.zus.suspension.r6 — `zus_suspension_return_obligation`: Wznowienie -> obowiazek ZUS od dnia wznowienia → Wznowienie
else :=   {"matched":true,"rule_id":"jdg.zus.suspension.r6","package":"jdg.micro.zus","priority":2476,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wznowienie -> obowiazek ZUS od dnia wznowienia","_legal_basis":"Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)","_warnings":["[MICRO] Wznowienie -> obowiazek ZUS od dnia wznowienia"]} {
    true
}

# jdg.zus.suspension.r7 — `zus_suspension_zua_withdrawal`: Wyrejestrowanie z ZUS przy zawieszeniu (ZUS ZWUA) → Formalnosc
else :=   {"matched":true,"rule_id":"jdg.zus.suspension.r7","package":"jdg.micro.zus","priority":2477,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wyrejestrowanie z ZUS przy zawieszeniu (ZUS ZWUA)","_legal_basis":"Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)","_warnings":["[MICRO] Wyrejestrowanie z ZUS przy zawieszeniu (ZUS ZWUA)"]} {
    true
}

# jdg.zus.suspension.r8 — `zus_suspension_re_registration_zua`: Ponowne zgloszenie przy wznowieniu (ZUS ZUA) → Formalnosc
else :=   {"matched":true,"rule_id":"jdg.zus.suspension.r8","package":"jdg.micro.zus","priority":2478,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ponowne zgloszenie przy wznowieniu (ZUS ZUA)","_legal_basis":"Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)","_warnings":["[MICRO] Ponowne zgloszenie przy wznowieniu (ZUS ZUA)"]} {
    true
}

# jdg.zus.suspension.r9 — `zus_suspension_annual_during_suspension`: Deklaracja roczna ZUS DRA za rok, w ktorym bylo zawieszenie → Deklaracja
else :=   {"matched":true,"rule_id":"jdg.zus.suspension.r9","package":"jdg.micro.zus","priority":2479,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Deklaracja roczna ZUS DRA za rok, w ktorym bylo zawieszenie","_legal_basis":"Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)","_warnings":["[MICRO] Deklaracja roczna ZUS DRA za rok, w ktorym bylo zawieszenie"]} {
    true
}
