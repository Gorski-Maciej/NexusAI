# Generated from Plan OPA 34 — Micro-rules for jdg.zus
# 2026-07-13 14:11:39
# Rules: 20 (deduplicated)

package jdg.micro.zus

default decide := {"matched":false,"rule_id":"jdg.micro.zus.no_match","package":"jdg.micro.zus","priority":99999}

# jdg.zus.a6.r1 — `social_insurance_obligation_entrepreneur`: Osoba prowadzaca JDG podlega obowiazkowo ubezpieczeniom emerytalnemu i rentowym → Obowiazkowe
decide :=   {"matched":true,"rule_id":"jdg.zus.a6.r1","package":"jdg.micro.zus","priority":601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Osoba prowadzaca JDG podlega obowiazkowo ubezpieczeniom emerytalnemu i rentowym","_legal_basis":"Art. 6 SUS — Obowiazek ubezpieczenia spolecznego","_warnings":["[MICRO] Obowiązek ubezpieczenia emerytalnego i rentowego — JDG aktywna"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.a6.r2 — `social_insurance_obligation_self_employed`: Osoba wspolpracujaca przy JDG -> obowiazkowo ubezpieczona → Wspolpracownik
else :=   {"matched":true,"rule_id":"jdg.zus.a6.r2","package":"jdg.micro.zus","priority":602,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Osoba wspolpracujaca przy JDG -> obowiazkowo ubezpieczona","_legal_basis":"Art. 6 SUS — Obowiazek ubezpieczenia spolecznego","_warnings":["[MICRO] Osoba współpracująca — obowiązek ubezpieczeń społecznych"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.a6.r3 — `social_insurance_voluntary_sickness`: Ubezpieczenie chorobowe dla JDG: dobrowolne → Dobrowolne
else :=   {"matched":true,"rule_id":"jdg.zus.a6.r3","package":"jdg.micro.zus","priority":603,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ubezpieczenie chorobowe dla JDG: dobrowolne","_legal_basis":"Art. 6 SUS — Obowiazek ubezpieczenia spolecznego","_warnings":["[MICRO] Ubezpieczenie chorobowe — dobrowolne, zgłoś przez ZUS ZUA"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "zus_sickness_voluntary", false) == true
}

# jdg.zus.a6.r4 — `social_insurance_voluntary_pension_for_low`: Ubezpieczenie emerytalne i rentowe dobrowolne dla JDG ponizej progu → Dobrowolne
else :=   {"matched":true,"rule_id":"jdg.zus.a6.r4","package":"jdg.micro.zus","priority":604,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ubezpieczenie emerytalne i rentowe dobrowolne dla JDG ponizej progu","_legal_basis":"Art. 6 SUS — Obowiazek ubezpieczenia spolecznego","_warnings":["[MICRO] Niska podstawa — emerytalne i rentowe dobrowolne poniżej progu"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.a6.r5 — `social_insurance_employee_hired`: Pracownik zatrudniony przez JDG -> obowiazkowe wszystkie ubezpieczenia → Pracownik
else :=   {"matched":true,"rule_id":"jdg.zus.a6.r5","package":"jdg.micro.zus","priority":605,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pracownik zatrudniony przez JDG -> obowiazkowe wszystkie ubezpieczenia","_legal_basis":"Art. 6 SUS — Obowiazek ubezpieczenia spolecznego","_warnings":["[MICRO] Pracownik — obowiązkowe wszystkie ubezpieczenia społeczne"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.a6.r6 — `social_insurance_contract_of_mandate`: Umowa zlecenia (jezeli zleceniobiorca jest bez etatu) -> obowiazkowe → Zlecenie
else :=   {"matched":true,"rule_id":"jdg.zus.a6.r6","package":"jdg.micro.zus","priority":606,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa zlecenia (jezeli zleceniobiorca jest bez etatu) -> obowiazkowe","_legal_basis":"Art. 6 SUS — Obowiazek ubezpieczenia spolecznego","_warnings":["[MICRO] Umowa zlecenia bez etatu — obowiązkowe ubezpieczenia społeczne"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.a7.r1 — `social_insurance_multiple_titles`: JDG majaca etat -> ubezpieczenia z tytulu etatu, JDG dobrowolne → Wielotytulowosc
else :=   {"matched":true,"rule_id":"jdg.zus.a7.r1","package":"jdg.micro.zus","priority":701,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG majaca etat -> ubezpieczenia z tytulu etatu, JDG dobrowolne","_legal_basis":"Art. 7 SUS — Zbieg tytulow z etatem","_warnings":["[MICRO] Zbieg tytułów — etat + JDG: etat obowiązkowy, JDG dobrowolne"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.a8.r1 — `social_insurance_scope_pension`: Ubezpieczenie emerytalne: obowiazkowe dla JDG → Emerytalne
else :=   {"matched":true,"rule_id":"jdg.zus.a8.r1","package":"jdg.micro.zus","priority":801,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ubezpieczenie emerytalne: obowiazkowe dla JDG","_legal_basis":"Art. 8 SUS — Podstawa wymiaru skladek","_warnings":["[MICRO] Ubezpieczenie emerytalne — obowiązkowe dla JDG, stawka 19.52%"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.a8.r2 — `social_insurance_scope_rent`: Ubezpieczenie rentowe: obowiazkowe dla JDG → Rentowe
else :=   {"matched":true,"rule_id":"jdg.zus.a8.r2","package":"jdg.micro.zus","priority":802,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ubezpieczenie rentowe: obowiazkowe dla JDG","_legal_basis":"Art. 8 SUS — Podstawa wymiaru skladek","_warnings":["[MICRO] Ubezpieczenie rentowe — obowiązkowe dla JDG, stawka 8.00%"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.a8.r3 — `social_insurance_scope_accident`: Ubezpieczenie wypadkowe: obowiazkowe dla JDG (placi JDG za siebie) → Wypadkowe
else :=   {"matched":true,"rule_id":"jdg.zus.a8.r3","package":"jdg.micro.zus","priority":803,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ubezpieczenie wypadkowe: obowiazkowe dla JDG (placi JDG za siebie)","_legal_basis":"Art. 8 SUS — Podstawa wymiaru skladek","_warnings":["[MICRO] Ubezpieczenie wypadkowe — obowiązkowe, składka od 0.67% do 3.33%"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.a8.r4 — `social_insurance_scope_fund_pracy`: Fundusz Pracy: obowiazkowe dla JDG (jesli nie ma etatu) → Fundusz Pracy
else :=   {"matched":true,"rule_id":"jdg.zus.a8.r4","package":"jdg.micro.zus","priority":804,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Fundusz Pracy: obowiazkowe dla JDG (jesli nie ma etatu)","_legal_basis":"Art. 8 SUS — Podstawa wymiaru skladek","_warnings":["[MICRO] Fundusz Pracy — obowiązkowy, stawka 2.45% podstawy"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.a8.r5 — `social_insurance_scope_fgsp`: Fundusz Gwarantowanych Swiadczen Pracowniczych: jak FP → FGSP
else :=   {"matched":true,"rule_id":"jdg.zus.a8.r5","package":"jdg.micro.zus","priority":805,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Fundusz Gwarantowanych Swiadczen Pracowniczych: jak FP","_legal_basis":"Art. 8 SUS — Podstawa wymiaru skladek","_warnings":["[MICRO] FGŚP — obowiązkowy jak Fundusz Pracy, stawka 0.10%"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.a9.r1 — `social_insurance_exclusion_retirement_pension`: JDG pobierajaca emeryture/rente -> zwolniona z obowiazku ZUS (opcjonalnie) → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.zus.a9.r1","package":"jdg.micro.zus","priority":901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG pobierajaca emeryture/rente -> zwolniona z obowiazku ZUS (opcjonalnie)","_legal_basis":"Art. 9 SUS — Zbieg tytulow ubezpieczenia","_warnings":["[MICRO] Wyłączenie — JDG pobierająca emeryturę/rentę zwolniona z obowiązku ZUS"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.a9.r2 — `social_insurance_exclusion_childcare_3_years`: JDG na urlopie wychowawczym -> zwolniona z obowiazku → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.zus.a9.r2","package":"jdg.micro.zus","priority":902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG na urlopie wychowawczym -> zwolniona z obowiazku","_legal_basis":"Art. 9 SUS — Zbieg tytulow ubezpieczenia","_warnings":["[MICRO] Wyłączenie — JDG na urlopie wychowawczym zwolniona z obowiązku ZUS"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.a9.r3 — `social_insurance_exclusion_conscription`: JDG w sluzbie wojskowej -> zwolniona → Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.zus.a9.r3","package":"jdg.micro.zus","priority":903,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG w sluzbie wojskowej -> zwolniona","_legal_basis":"Art. 9 SUS — Zbieg tytulow ubezpieczenia","_warnings":["[MICRO] Wyłączenie — JDG w służbie wojskowej zwolniona z obowiązku ZUS"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.a10.r1 — `social_insurance_start_date`: Obowiazek ubezpieczenia od dnia rozpoczecia JDG → Poczatek
else :=   {"matched":true,"rule_id":"jdg.zus.a10.r1","package":"jdg.micro.zus","priority":1001,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiazek ubezpieczenia od dnia rozpoczecia JDG","_legal_basis":"Art. 10 SUS — Rozpoczecie obowiazku ubezpieczenia","_warnings":["[MICRO] Obowiązek ubezpieczenia — od dnia rozpoczęcia JDG, zgłoś ZUS ZUA w 7 dni"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.a10.r2 — `social_insurance_cessation_date`: Koniec obowiazku z dniem zaprzestania JDG → Koniec
else :=   {"matched":true,"rule_id":"jdg.zus.a10.r2","package":"jdg.micro.zus","priority":1002,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koniec obowiazku z dniem zaprzestania JDG","_legal_basis":"Art. 10 SUS — Ustanie obowiazku ubezpieczenia","_warnings":["[MICRO] Ustanie obowiązku — z dniem zaprzestania JDG, zgłoś ZUS ZWUA w 7 dni"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "CLOSED"
}

# jdg.zus.a11.r1 — `social_insurance_sickness_voluntary_declaration`: Zgloszenie do dobrowolnego ubezpieczenia chorobowego: ZUS ZUA → Zgloszenie
else :=   {"matched":true,"rule_id":"jdg.zus.a11.r1","package":"jdg.micro.zus","priority":1101,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zgloszenie do dobrowolnego ubezpieczenia chorobowego: ZUS ZUA","_legal_basis":"Art. 11 SUS — Obowiazek ubezpieczenia","_warnings":["[MICRO] Zgłoszenie do dobrowolnego ubezpieczenia chorobowego — formularz ZUS ZUA"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "zus_sickness_voluntary", false) == true
}

# jdg.zus.a12.r1 — `social_insurance_sickness_waiting_90_days`: Okres wyczekiwania na zasilek chorobowy: 90 dni (JDG) → Okres wyczekiwania
else :=   {"matched":true,"rule_id":"jdg.zus.a12.r1","package":"jdg.micro.zus","priority":1201,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Okres wyczekiwania na zasilek chorobowy: 90 dni (JDG)","_legal_basis":"Art. 12 SUS — Okres wyczekiwania na zasilek chorobowy","_warnings":["[MICRO] Okres wyczekiwania 90 dni — zasiłek chorobowy dopiero po 3 miesiącach"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "zus_sickness_voluntary", false) == true
}

# jdg.zus.a13.r1 — `social_insurance_annual_reconciliation`: Roczne rozliczenie skladek ZUS w deklaracji rocznej ZUS DRA → Roczne
else :=   {"matched":true,"rule_id":"jdg.zus.a13.r1","package":"jdg.micro.zus","priority":1301,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roczne rozliczenie skladek ZUS w deklaracji rocznej ZUS DRA","_legal_basis":"Art. 13 SUS — Ubezpieczenie chorobowe","_warnings":["[MICRO] Roczne rozliczenie składek ZUS — deklaracja ZUS DRA, termin do 31.01"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}
