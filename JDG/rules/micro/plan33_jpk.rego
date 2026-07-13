# Generated from Plan OPA 33 — Micro-rules for jpk
# 2026-07-13 14:58:41
# Rules: 70 (new, deduplicated)

package jdg.micro.jpk

default decide := {"matched":false,"rule_id":"jdg.micro.jpk.no_match","package":"jdg.micro.jpk","priority":99999}

# jdg.jpk.a99.r11 — `jpk_v7m_monthly_structure`: JPK_V7M dla czynnych podatników VAT (miesięcznie) -> struktura JPK_VAT → Miesięczna deklaracja
decide :=   {"matched":true,"rule_id":"jdg.jpk.a99.r11","package":"jdg.micro.jpk","priority":5900,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_V7M dla czynnych podatników VAT (miesięcznie) -> struktura JPK_VAT","_legal_basis":"par. 2 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r12 — `jpk_v7k_quarterly_small`: JPK_V7K dla małych podatników (kwartalnie) -> struktura JPK_VAT → Kwartalna deklaracja
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r12","package":"jdg.micro.jpk","priority":5901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_V7K dla małych podatników (kwartalnie) -> struktura JPK_VAT","_legal_basis":"par. 3 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r13 — `jpk_v7_deadline_25`: JPK_V7M/K składa się do 25. dnia następnego miesiąca/kwartału → Termin 25. dzień
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r13","package":"jdg.micro.jpk","priority":5902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_V7M/K składa się do 25. dnia następnego miesiąca/kwartału","_legal_basis":"par. 4 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r14 — `jpk_v7_format_xml_schemat`: JPK_V7 w formacie XML (schemat XSD opublikowany przez MF) → Format XML
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r14","package":"jdg.micro.jpk","priority":5903,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_V7 w formacie XML (schemat XSD opublikowany przez MF)","_legal_basis":"par. 5 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r15 — `jpk_v7_parts_sales_purchase`: JPK_V7 zawiera: część deklaracyjną + ewidencję sprzedaży i zakupów → 3 części
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r15","package":"jdg.micro.jpk","priority":5904,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_V7 zawiera: część deklaracyjną + ewidencję sprzedaży i zakupów","_legal_basis":"par. 6 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r16 — `jpk_v7_gtu_required`: W ewidencji sprzedaży: oznaczenia GTU (13 kodów od GTU_01 do GTU_13) → GTU obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r16","package":"jdg.micro.jpk","priority":5905,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"W ewidencji sprzedaży: oznaczenia GTU (13 kodów od GTU_01 do GTU_13)","_legal_basis":"par. 10 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r17 — `jpk_v7_procedure_documents`: Oznaczenia procedur: SW (split payment), EE (eksport), TP (transakcje powiązane) → Kody procedur
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r17","package":"jdg.micro.jpk","priority":5906,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Oznaczenia procedur: SW (split payment), EE (eksport), TP (transakcje powiązane)","_legal_basis":"par. 11 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r18 — `jpk_v7_markings_fp_etc`: Oznaczenia: FP (faktura po terminie), WEW (wewnętrzna), VAT_MARZA → Znaczniki
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r18","package":"jdg.micro.jpk","priority":5907,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Oznaczenia: FP (faktura po terminie), WEW (wewnętrzna), VAT_MARZA","_legal_basis":"par. 12 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r19 — `jpk_v7_split_payment_marking`: Mechanizm podzielonej płatności: znacznik MPP w JPK_V7 → MPP yes/no
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r19","package":"jdg.micro.jpk","priority":5908,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mechanizm podzielonej płatności: znacznik MPP w JPK_V7","_legal_basis":"par. 13 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r20 — `jpk_v7_import_services_ie`: Import usług: znacznik IMP_UE/IMP_NON_UE → Znacznik
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r20","package":"jdg.micro.jpk","priority":5909,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Import usług: znacznik IMP_UE/IMP_NON_UE","_legal_basis":"par. 14 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r21 — `jpk_v7_invoice_numbering`: Numeracja faktur w JPK zgodna z oryginalnymi fakturami → Numeracja
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r21","package":"jdg.micro.jpk","priority":5910,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Numeracja faktur w JPK zgodna z oryginalnymi fakturami","_legal_basis":"par. 15 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r22 — `jpk_v7_zero_declaration`: Brak sprzedaży w okresie -> deklaracja zerowa JPK_V7 (bez ewidencji) → Zerówka
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r22","package":"jdg.micro.jpk","priority":5911,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak sprzedaży w okresie -> deklaracja zerowa JPK_V7 (bez ewidencji)","_legal_basis":"par. 16 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r23 — `jpk_v7_correction_full`: Korekta JPK_V7 -> złożenie pełnej korekty (zastąpienie poprzedniej) → Korekta przez zastąpienie
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r23","package":"jdg.micro.jpk","priority":5912,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta JPK_V7 -> złożenie pełnej korekty (zastąpienie poprzedniej)","_legal_basis":"par. 17 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r24 — `jpk_v7_correction_reason_code`: Korekta: kod przyczyny korekty (1-5) → Kod
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r24","package":"jdg.micro.jpk","priority":5913,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta: kod przyczyny korekty (1-5)","_legal_basis":"par. 18 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r25 — `jpk_v7_correction_reason_1`: Kod 1: pomyłka w kwocie (błąd rachunkowy) → Kod 1
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r25","package":"jdg.micro.jpk","priority":5914,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kod 1: pomyłka w kwocie (błąd rachunkowy)","_legal_basis":"par. 18a","_warnings":[]} {
    true
}

# jdg.jpk.a99.r26 — `jpk_v7_correction_reason_2`: Kod 2: błąd w stawce VAT → Kod 2
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r26","package":"jdg.micro.jpk","priority":5915,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kod 2: błąd w stawce VAT","_legal_basis":"par. 18b","_warnings":[]} {
    true
}

# jdg.jpk.a99.r27 — `jpk_v7_correction_reason_3`: Kod 3: korekta po stwierdzeniu nadpłaty/niedopłaty → Kod 3
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r27","package":"jdg.micro.jpk","priority":5916,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kod 3: korekta po stwierdzeniu nadpłaty/niedopłaty","_legal_basis":"par. 18c","_warnings":[]} {
    true
}

# jdg.jpk.a99.r28 — `jpk_v7_correction_reason_4`: Kod 4: korekta w związku z korektą faktury pierwotnej → Kod 4
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r28","package":"jdg.micro.jpk","priority":5917,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kod 4: korekta w związku z korektą faktury pierwotnej","_legal_basis":"par. 18d","_warnings":[]} {
    true
}

# jdg.jpk.a99.r29 — `jpk_v7_correction_reason_5`: Kod 5: inna przyczyna (z opisem) → Kod 5
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r29","package":"jdg.micro.jpk","priority":5918,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kod 5: inna przyczyna (z opisem)","_legal_basis":"par. 18e","_warnings":[]} {
    true
}

# jdg.jpk.a99.r30 — `jpk_v7_electronic_signature`: JPK_V7 podpisany podpisem kwalifikowanym lub profilem zaufanym → Podpis obowiązkowy
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r30","package":"jdg.micro.jpk","priority":5919,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_V7 podpisany podpisem kwalifikowanym lub profilem zaufanym","_legal_basis":"par. 19 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r31 — `jpk_v7_send_platform`: JPK_V7 wysyłany przez: bramka MF (PUESC), API KSeF, lub system JPK → Platforma wysyłki
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r31","package":"jdg.micro.jpk","priority":5920,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_V7 wysyłany przez: bramka MF (PUESC), API KSeF, lub system JPK","_legal_basis":"par. 20 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r32 — `jpk_v7_upo_check`: UPO dla JPK (urzędowe poświadczenie odbioru) wymagane jako potwierdzenie → UPO obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r32","package":"jdg.micro.jpk","priority":5921,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"UPO dla JPK (urzędowe poświadczenie odbioru) wymagane jako potwierdzenie","_legal_basis":"par. 21 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r33 — `jpk_v7_late_filing_penalty`: Po terminie -> sankcje KKS + odsetki za zwłokę → Sankcje
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r33","package":"jdg.micro.jpk","priority":5922,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Po terminie -> sankcje KKS + odsetki za zwłokę","_legal_basis":"par. 22 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r34 — `jpk_v7_past_periods_5_years`: Korekta JPK za okresy wsteczne: max 5 lat wstecz (przedawnienie) → 5 lat
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r34","package":"jdg.micro.jpk","priority":5923,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta JPK za okresy wsteczne: max 5 lat wstecz (przedawnienie)","_legal_basis":"par. 23 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.a99.r35 — `jpk_v7_audit_request`: US może zażądać wyjaśnień do JPK_V7 w terminie 7 dni → 7 dni na wyjaśnienia
else :=   {"matched":true,"rule_id":"jdg.jpk.a99.r35","package":"jdg.micro.jpk","priority":5924,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"US może zażądać wyjaśnień do JPK_V7 w terminie 7 dni","_legal_basis":"par. 24 rozp. JPK_VAT","_warnings":[]} {
    true
}

# jdg.jpk.b.r1 — `jpk_pkpir_obligation`: JDG z PKPiR -> obowiązek posiadania JPK_PKPIR (na żądanie US) → Na żądanie
else :=   {"matched":true,"rule_id":"jdg.jpk.b.r1","package":"jdg.micro.jpk","priority":5925,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JDG z PKPiR -> obowiązek posiadania JPK_PKPIR (na żądanie US)","_legal_basis":"Art. 30a ustawy o rachunkowości","_warnings":[]} {
    true
}

# jdg.jpk.b.r10 — `jpk_fa_format_xml`: JPK_FA w formacie XML (zakres danych wg szablonu MF) → XML
else :=   {"matched":true,"rule_id":"jdg.jpk.b.r10","package":"jdg.micro.jpk","priority":5926,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_FA w formacie XML (zakres danych wg szablonu MF)","_legal_basis":"Rozp. MF","_warnings":[]} {
    true
}

# jdg.jpk.b.r11 — `jpk_wb_on_demand`: JPK_WB (wyciągi bankowe) -> na żądanie US w 30 dni → 30 dni
else :=   {"matched":true,"rule_id":"jdg.jpk.b.r11","package":"jdg.micro.jpk","priority":5927,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_WB (wyciągi bankowe) -> na żądanie US w 30 dni","_legal_basis":"Art. 30a ust. 4 u.o.r.","_warnings":[]} {
    true
}

# jdg.jpk.b.r12 — `jpk_mag_on_demand`: JPK_MAG (magazyn) -> na żądanie US (jeśli JDG prowadzi magazyn) → 30 dni
else :=   {"matched":true,"rule_id":"jdg.jpk.b.r12","package":"jdg.micro.jpk","priority":5928,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_MAG (magazyn) -> na żądanie US (jeśli JDG prowadzi magazyn)","_legal_basis":"Art. 30a ust. 5 u.o.r.","_warnings":[]} {
    true
}

# jdg.jpk.b.r13 — `jpk_cit_on_demand`: JPK_CIT (księgi rachunkowe) -> na żądanie US dla JDG z pełną księgowością → 30 dni
else :=   {"matched":true,"rule_id":"jdg.jpk.b.r13","package":"jdg.micro.jpk","priority":5929,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_CIT (księgi rachunkowe) -> na żądanie US dla JDG z pełną księgowością","_legal_basis":"Art. 30a ust. 6 u.o.r.","_warnings":[]} {
    true
}

# jdg.jpk.b.r14 — `jpk_automatic_audit_jpk7`: US automatycznie analizuje JPK_V7 w poszukiwaniu anomalii (algorytm ryzyka) → Automatyczna analiza
else :=   {"matched":true,"rule_id":"jdg.jpk.b.r14","package":"jdg.micro.jpk","priority":5930,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"US automatycznie analizuje JPK_V7 w poszukiwaniu anomalii (algorytm ryzyka)","_legal_basis":"Art. 30a ust. 7 u.o.r.","_warnings":[]} {
    true
}

# jdg.jpk.b.r15 — `jpk_correction_rules`: Korekta JPK (na żądanie): korekta wysyłana jako nowy plik zastępujący poprzedni → Korekta
else :=   {"matched":true,"rule_id":"jdg.jpk.b.r15","package":"jdg.micro.jpk","priority":5931,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta JPK (na żądanie): korekta wysyłana jako nowy plik zastępujący poprzedni","_legal_basis":"Art. 30a ust. 8 u.o.r.","_warnings":[]} {
    true
}

# jdg.jpk.b.r2 — `jpk_pkpir_structure_16_columns`: JPK_PKPIR: 16 kolumn (od kol. 1 do 16 wg wzorca MF) → 16 kolumn
else :=   {"matched":true,"rule_id":"jdg.jpk.b.r2","package":"jdg.micro.jpk","priority":5932,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_PKPIR: 16 kolumn (od kol. 1 do 16 wg wzorca MF)","_legal_basis":"Rozp. MF w sprawie PKPiR","_warnings":[]} {
    true
}

# jdg.jpk.b.r3 — `jpk_pkpir_columns_1_5`: Kol. 1-5: data, nr faktury, kontrahent, adres, opis → Pola podstawowe
else :=   {"matched":true,"rule_id":"jdg.jpk.b.r3","package":"jdg.micro.jpk","priority":5933,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kol. 1-5: data, nr faktury, kontrahent, adres, opis","_legal_basis":"Rozp. MF","_warnings":[]} {
    true
}

# jdg.jpk.b.r4 — `jpk_pkpir_columns_6_7`: Kol. 6: przychód ze sprzedaży towarów; Kol. 7: pozostałe przychody → Przychody
else :=   {"matched":true,"rule_id":"jdg.jpk.b.r4","package":"jdg.micro.jpk","priority":5934,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kol. 6: przychód ze sprzedaży towarów; Kol. 7: pozostałe przychody","_legal_basis":"Rozp. MF","_warnings":[]} {
    true
}

# jdg.jpk.b.r5 — `jpk_pkpir_columns_8_10`: Kol. 8-10: zakup towarów, koszty uboczne, wynagrodzenia → Koszty bezpośrednie
else :=   {"matched":true,"rule_id":"jdg.jpk.b.r5","package":"jdg.micro.jpk","priority":5935,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kol. 8-10: zakup towarów, koszty uboczne, wynagrodzenia","_legal_basis":"Rozp. MF","_warnings":[]} {
    true
}

# jdg.jpk.b.r6 — `jpk_pkpir_columns_11_13`: Kol. 11-13: pozostałe wydatki, odsetki, raty leasingu → Pozostałe koszty
else :=   {"matched":true,"rule_id":"jdg.jpk.b.r6","package":"jdg.micro.jpk","priority":5936,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kol. 11-13: pozostałe wydatki, odsetki, raty leasingu","_legal_basis":"Rozp. MF","_warnings":[]} {
    true
}

# jdg.jpk.b.r7 — `jpk_pkpir_columns_14_16`: Kol. 14-16: NKUP, środki trwałe, uwagi → NKUP + środki trwale
else :=   {"matched":true,"rule_id":"jdg.jpk.b.r7","package":"jdg.micro.jpk","priority":5937,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kol. 14-16: NKUP, środki trwałe, uwagi","_legal_basis":"Rozp. MF","_warnings":[]} {
    true
}

# jdg.jpk.b.r8 — `jpk_pkpir_on_demand_30_days`: JPK_PKPIR wysyłany w 30 dni od wezwania US → 30 dni
else :=   {"matched":true,"rule_id":"jdg.jpk.b.r8","package":"jdg.micro.jpk","priority":5938,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_PKPIR wysyłany w 30 dni od wezwania US","_legal_basis":"Art. 30a ust. 2 u.o.r.","_warnings":[]} {
    true
}

# jdg.jpk.b.r9 — `jpk_fa_on_demand`: JPK_FA (faktury) -> na żądanie US w 30 dni → 30 dni
else :=   {"matched":true,"rule_id":"jdg.jpk.b.r9","package":"jdg.micro.jpk","priority":5939,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_FA (faktury) -> na żądanie US w 30 dni","_legal_basis":"Art. 30a ust. 3 u.o.r.","_warnings":[]} {
    true
}

# jdg.jpk.fa.r1 — `jpk_fa_obligation_on_demand`: JPK_FA (faktury): na zadanie US → Na zadanie
else :=   {"matched":true,"rule_id":"jdg.jpk.fa.r1","package":"jdg.micro.jpk","priority":5940,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_FA (faktury): na zadanie US","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.fa.r2 — `jpk_fa_scope_all_invoices`: JPK_FA: wszystkie faktury za wskazany okres → Zakres
else :=   {"matched":true,"rule_id":"jdg.jpk.fa.r2","package":"jdg.micro.jpk","priority":5941,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_FA: wszystkie faktury za wskazany okres","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.fa.r3 — `jpk_fa_deadline_14_days`: JPK_FA: 14 dni od wezwania → Termin
else :=   {"matched":true,"rule_id":"jdg.jpk.fa.r3","package":"jdg.micro.jpk","priority":5942,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_FA: 14 dni od wezwania","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.fa.r4 — `jpk_fa_obligation_for_all_vat`: Obowiazek dla wszystkich czynnych podatnikow VAT → Podmiot
else :=   {"matched":true,"rule_id":"jdg.jpk.fa.r4","package":"jdg.micro.jpk","priority":5943,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiazek dla wszystkich czynnych podatnikow VAT","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.mag.r1 — `jpk_mag_obligation_on_demand`: JPK_MAG (magazyn): na zadanie US → Na zadanie
else :=   {"matched":true,"rule_id":"jdg.jpk.mag.r1","package":"jdg.micro.jpk","priority":5944,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_MAG (magazyn): na zadanie US","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.mag.r2 — `jpk_mag_scope_inventory`: JPK_MAG: stany magazynowe na koniec okresu → Zakres
else :=   {"matched":true,"rule_id":"jdg.jpk.mag.r2","package":"jdg.micro.jpk","priority":5945,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_MAG: stany magazynowe na koniec okresu","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.mag.r3 — `jpk_mag_deadline_14_days`: JPK_MAG: 14 dni od wezwania → Termin
else :=   {"matched":true,"rule_id":"jdg.jpk.mag.r3","package":"jdg.micro.jpk","priority":5946,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_MAG: 14 dni od wezwania","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.pkpir.r1 — `jpk_pkpir_obligation_on_demand`: JPK_PKPIR: na zadanie US (nie obowiazkowo cyklicznie) → Na zadanie
else :=   {"matched":true,"rule_id":"jdg.jpk.pkpir.r1","package":"jdg.micro.jpk","priority":5947,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_PKPIR: na zadanie US (nie obowiazkowo cyklicznie)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.pkpir.r2 — `jpk_pkpir_scope_all_entries`: JPK_PKPIR: wszystkie wpisy z PKPiR za wskazany okres → Zakres
else :=   {"matched":true,"rule_id":"jdg.jpk.pkpir.r2","package":"jdg.micro.jpk","priority":5948,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_PKPIR: wszystkie wpisy z PKPiR za wskazany okres","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.pkpir.r3 — `jpk_pkpir_deadline_14_days`: Po wezwaniu US: 14 dni na przeslanie JPK_PKPIR → Termin
else :=   {"matched":true,"rule_id":"jdg.jpk.pkpir.r3","package":"jdg.micro.jpk","priority":5949,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Po wezwaniu US: 14 dni na przeslanie JPK_PKPIR","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.pkpir.r4 — `jpk_pkpir_mandatory_for_all_jdg`: Obowiazek dotyczy wszystkich JDG prowadzacych PKPiR → Podmiot
else :=   {"matched":true,"rule_id":"jdg.jpk.pkpir.r4","package":"jdg.micro.jpk","priority":5950,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiazek dotyczy wszystkich JDG prowadzacych PKPiR","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.pkpir.r5 — `jpk_pkpir_schema`: Struktura JPK_PKPIR zgodna z MF → Schema
else :=   {"matched":true,"rule_id":"jdg.jpk.pkpir.r5","package":"jdg.micro.jpk","priority":5951,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Struktura JPK_PKPIR zgodna z MF","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.r1 — `jpk_v7m_monthly_mandatory`: Czynny podatnik VAT -> JPK_V7M miesiecznie → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.jpk.r1","package":"jdg.micro.jpk","priority":5952,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny podatnik VAT -> JPK_V7M miesiecznie","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.r10 — `jpk_zero_filing_if_no_transactions`: JPK zerowe przy braku transakcji (sprzedaz = 0, zakup = 0) → Zerowe
else :=   {"matched":true,"rule_id":"jdg.jpk.r10","package":"jdg.micro.jpk","priority":5953,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK zerowe przy braku transakcji (sprzedaz = 0, zakup = 0)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.r11 — `jpk_correction_file`: Korekta JPK: przeslanie nowego pliku (z adnotacja korekta) → Korekta
else :=   {"matched":true,"rule_id":"jdg.jpk.r11","package":"jdg.micro.jpk","priority":5954,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta JPK: przeslanie nowego pliku (z adnotacja korekta)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.r12 — `jpk_automatic_validation_by_mf`: Walidacja JPK przez system MF (bledy krytyczne -> odrzucenie) → Walidacja
else :=   {"matched":true,"rule_id":"jdg.jpk.r12","package":"jdg.micro.jpk","priority":5955,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Walidacja JPK przez system MF (bledy krytyczne -> odrzucenie)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.r13 — `jpk_validation_errors_critical`: Bledy krytyczne: bledny NIP, bledny okres, bledne sumy → Odrzucenie
else :=   {"matched":true,"rule_id":"jdg.jpk.r13","package":"jdg.micro.jpk","priority":5956,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Bledy krytyczne: bledny NIP, bledny okres, bledne sumy","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.r14 — `jpk_validation_errors_warnings`: Ostrzezenia: drobne niezgodnosci (np. brak NIP nabywcy) → Zaakceptowane
else :=   {"matched":true,"rule_id":"jdg.jpk.r14","package":"jdg.micro.jpk","priority":5957,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ostrzezenia: drobne niezgodnosci (np. brak NIP nabywcy)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.r15 — `jpk_storage_5_years`: JPK przechowywany 5 lat od konca roku → Retencja
else :=   {"matched":true,"rule_id":"jdg.jpk.r15","package":"jdg.micro.jpk","priority":5958,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK przechowywany 5 lat od konca roku","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.r2 — `jpk_v7k_quarterly_small`: Maly podatnik (obrot < 2M EUR) -> moze skladac JPK_V7K kwartalnie → Opcja
else :=   {"matched":true,"rule_id":"jdg.jpk.r2","package":"jdg.micro.jpk","priority":5959,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Maly podatnik (obrot < 2M EUR) -> moze skladac JPK_V7K kwartalnie","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.r3 — `jpk_v7k_deadline_25_after`: JPK_V7K: do 25. dnia po kwartale → Termin
else :=   {"matched":true,"rule_id":"jdg.jpk.r3","package":"jdg.micro.jpk","priority":5960,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_V7K: do 25. dnia po kwartale","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.r4 — `jpk_v7m_deadline_25_monthly`: JPK_V7M: do 25. dnia nastepnego miesiaca → Termin
else :=   {"matched":true,"rule_id":"jdg.jpk.r4","package":"jdg.micro.jpk","priority":5961,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_V7M: do 25. dnia nastepnego miesiaca","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.r5 — `jpk_part_vat_sales_sprzedaz`: Czesc ewidencyjna: sprzedaz (faktury, paragony, WDT, eksport) → Sprzedaz
else :=   {"matched":true,"rule_id":"jdg.jpk.r5","package":"jdg.micro.jpk","priority":5962,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czesc ewidencyjna: sprzedaz (faktury, paragony, WDT, eksport)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.r6 — `jpk_part_vat_purchase_zakup`: Czesc ewidencyjna: zakup (faktury kosztowe, import, WNT) → Zakup
else :=   {"matched":true,"rule_id":"jdg.jpk.r6","package":"jdg.micro.jpk","priority":5963,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czesc ewidencyjna: zakup (faktury kosztowe, import, WNT)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.r7 — `jpk_part_vat_vat_declaration_deklaracja`: Czesc deklaracyjna: podsumowanie VAT (nalezny, naliczony, do zaplaty) → Deklaracja
else :=   {"matched":true,"rule_id":"jdg.jpk.r7","package":"jdg.micro.jpk","priority":5964,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czesc deklaracyjna: podsumowanie VAT (nalezny, naliczony, do zaplaty)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.r8 — `jpk_xml_structure_mandatory`: JPK w formacie XML (struktura logiczna MF) → Format
else :=   {"matched":true,"rule_id":"jdg.jpk.r8","package":"jdg.micro.jpk","priority":5965,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK w formacie XML (struktura logiczna MF)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.r9 — `jpk_xml_schema_v7m_1_0`: Schemat JPK_V7M-1 (obowiazujacy od 2024) → Schema
else :=   {"matched":true,"rule_id":"jdg.jpk.r9","package":"jdg.micro.jpk","priority":5966,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Schemat JPK_V7M-1 (obowiazujacy od 2024)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.wb.r1 — `jpk_wb_obligation_on_demand`: JPK_WB (wyciagi bankowe): na zadanie US → Na zadanie
else :=   {"matched":true,"rule_id":"jdg.jpk.wb.r1","package":"jdg.micro.jpk","priority":5967,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_WB (wyciagi bankowe): na zadanie US","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.wb.r2 — `jpk_wb_scope_all_accounts`: JPK_WB: wszystkie rachunki bankowe JDG we wskazanym okresie → Zakres
else :=   {"matched":true,"rule_id":"jdg.jpk.wb.r2","package":"jdg.micro.jpk","priority":5968,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_WB: wszystkie rachunki bankowe JDG we wskazanym okresie","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.jpk.wb.r3 — `jpk_wb_deadline_14_days`: JPK_WB: 14 dni od wezwania → Termin
else :=   {"matched":true,"rule_id":"jdg.jpk.wb.r3","package":"jdg.micro.jpk","priority":5969,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_WB: 14 dni od wezwania","_legal_basis":"","_warnings":[]} {
    true
}
