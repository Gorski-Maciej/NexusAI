# Generated from Plan OPA 33 — Micro-rules for vat
# 2026-07-13 14:58:41
# Rules: 115 (new, deduplicated)

package jdg.micro.vat

default decide := {"matched":false,"rule_id":"jdg.micro.vat.no_match","package":"jdg.micro.vat","priority":99999}

# jdg.vat.a106e.r11 — `invoice_simplified_receipt_450_over`: Paragon bez NIP lub >450 PLN = NIE faktura → Brak odliczenia VAT
decide :=   {"matched":true,"rule_id":"jdg.vat.a106e.r11","package":"jdg.micro.vat","priority":500,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Paragon bez NIP lub >450 PLN = NIE faktura","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106e.r12 — `invoice_issue_deadline_15_days`: Fakturę wystawia się do 15. dnia miesiąca po dostawie → Termin standardowy
else :=   {"matched":true,"rule_id":"jdg.vat.a106e.r12","package":"jdg.micro.vat","priority":501,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Fakturę wystawia się do 15. dnia miesiąca po dostawie","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106e.r13 — `invoice_issue_deadline_b2c_receipt`: Paragon B2C — w momencie sprzedaży (kasa fiskalna) → Termin natychmiastowy
else :=   {"matched":true,"rule_id":"jdg.vat.a106e.r13","package":"jdg.micro.vat","priority":502,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Paragon B2C — w momencie sprzedaży (kasa fiskalna)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106e.r15 — `invoice_correction_approval`: Faktura korygująca — wymagana zgoda nabywcy lub notyfikacja → Warunek
else :=   {"matched":true,"rule_id":"jdg.vat.a106e.r15","package":"jdg.micro.vat","priority":503,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura korygująca — wymagana zgoda nabywcy lub notyfikacja","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106e.r3 — `invoice_mandatory_fields_numbers`: Numer faktury (unikalny w roku/okresie) → Pole obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.vat.a106e.r3","package":"jdg.micro.vat","priority":504,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Numer faktury (unikalny w roku/okresie)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106e.r4 — `invoice_mandatory_fields_party_details`: Nazwa i adres sprzedawcy i nabywcy → Pole obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.vat.a106e.r4","package":"jdg.micro.vat","priority":505,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nazwa i adres sprzedawcy i nabywcy","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106e.r7 — `invoice_mandatory_fields_reverse_charge`: Adnotacja: \"odwrotne obciążenie\" gdy procedura → Pole warunkowe
else :=   {"matched":true,"rule_id":"jdg.vat.a106e.r7","package":"jdg.micro.vat","priority":506,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Adnotacja: \"odwrotne obciążenie\" gdy procedura","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106e.r8 — `invoice_mandatory_fields_split_payment`: Adnotacja: \"mechanizm podzielonej płatności\" → Pole warunkowe
else :=   {"matched":true,"rule_id":"jdg.vat.a106e.r8","package":"jdg.micro.vat","priority":507,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Adnotacja: \"mechanizm podzielonej płatności\"","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106e.r9 — `invoice_mandatory_fields_margin`: Adnotacja: \"procedura marży — towary używane\" → Pole warunkowe
else :=   {"matched":true,"rule_id":"jdg.vat.a106e.r9","package":"jdg.micro.vat","priority":508,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Adnotacja: \"procedura marży — towary używane\"","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106j.r10 — `correction_vat_rate_change`: Zmiana stawki VAT → korekta in plus/minus w zależności od kierunku zmiany → Stawka
else :=   {"matched":true,"rule_id":"jdg.vat.a106j.r10","package":"jdg.micro.vat","priority":509,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana stawki VAT → korekta in plus/minus w zależności od kierunku zmiany","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106j.r2 — `correction_invoice_plus_conditions`: Korekta in plus: dodatkowa należność po sprzedaży (błąd w cenie) → Warunki korekty
else :=   {"matched":true,"rule_id":"jdg.vat.a106j.r2","package":"jdg.micro.vat","priority":510,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta in plus: dodatkowa należność po sprzedaży (błąd w cenie)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106j.r4 — `correction_buyer_agreement_exceptions`: Wyjątki od zgody: WDT, eksport, dostawa wewnątrzwspólnotowa → Wyjątek
else :=   {"matched":true,"rule_id":"jdg.vat.a106j.r4","package":"jdg.micro.vat","priority":511,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wyjątki od zgody: WDT, eksport, dostawa wewnątrzwspólnotowa","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106j.r5 — `correction_no_agreement_within_6_months`: Brak potwierdzenia w 6 mies. → korekta bez potwierdzenia, ale US może zakwestionować → Konsekwencja
else :=   {"matched":true,"rule_id":"jdg.vat.a106j.r5","package":"jdg.micro.vat","priority":512,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak potwierdzenia w 6 mies. → korekta bez potwierdzenia, ale US może zakwestionować","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106j.r6 — `correction_mandatory_reason`: Faktura korygująca: przyczyna korekty (opis błędu) → Pole obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.vat.a106j.r6","package":"jdg.micro.vat","priority":513,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura korygująca: przyczyna korekty (opis błędu)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106j.r7 — `correction_mandatory_reference`: Faktura korygująca: numer faktury pierwotnej → Pole obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.vat.a106j.r7","package":"jdg.micro.vat","priority":514,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura korygująca: numer faktury pierwotnej","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106j.r9 — `correction_storno_black_adjustment`: Nota korygująca (różnica) — korekta częściowa bez anulowania → Korekta częściowa
else :=   {"matched":true,"rule_id":"jdg.vat.a106j.r9","package":"jdg.micro.vat","priority":515,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nota korygująca (różnica) — korekta częściowa bez anulowania","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106na.r2 — `ksef_obligation_vat_active_only`: Obowiązek dotyczy tylko czynnych podatników VAT → Zakres podmiotowy
else :=   {"matched":true,"rule_id":"jdg.vat.a106na.r2","package":"jdg.micro.vat","priority":516,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiązek dotyczy tylko czynnych podatników VAT","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106na.r5 — `ksef_structured_invoice_mandatory_format`: Faktura ustrukturyzowana wg schemy XSD → Format obowiązkowy
else :=   {"matched":true,"rule_id":"jdg.vat.a106na.r5","package":"jdg.micro.vat","priority":517,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura ustrukturyzowana wg schemy XSD","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106na.r6 — `ksef_self_invoicing_by_buyer`: Faktura wystawiona przez nabywcę (self-billing) — również przez KSeF → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.vat.a106na.r6","package":"jdg.micro.vat","priority":518,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura wystawiona przez nabywcę (self-billing) — również przez KSeF","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106na.r7 — `ksef_invoice_deadline_real_time`: Faktura w KSeF — w momencie sprzedaży (lub do 24h z opóźnieniem) → Termin
else :=   {"matched":true,"rule_id":"jdg.vat.a106na.r7","package":"jdg.micro.vat","priority":519,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura w KSeF — w momencie sprzedaży (lub do 24h z opóźnieniem)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106ne.r2 — `ksef_offline_status_detection`: Status systemu KSeF: ONLINE / OFFLINE → Detekcja
else :=   {"matched":true,"rule_id":"jdg.vat.a106ne.r2","package":"jdg.micro.vat","priority":520,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Status systemu KSeF: ONLINE / OFFLINE","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106ne.r3 — `ksef_offline_invoice_numbering`: Numery faktur w trybie offline (sufiks /OFFLINE) → Konwencja
else :=   {"matched":true,"rule_id":"jdg.vat.a106ne.r3","package":"jdg.micro.vat","priority":521,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Numery faktur w trybie offline (sufiks /OFFLINE)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106ng.r2 — `ksef_upo_storage_5_years`: UPO przechowuje się przez 5 lat → Retencja
else :=   {"matched":true,"rule_id":"jdg.vat.a106ng.r2","package":"jdg.micro.vat","priority":522,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"UPO przechowuje się przez 5 lat","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a106nh.r2 — `ksef_qr_code_absence_risk`: Brak kodu QR → ryzyko zakwestionowania odliczenia VAT → Ryzyko
else :=   {"matched":true,"rule_id":"jdg.vat.a106nh.r2","package":"jdg.micro.vat","priority":523,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak kodu QR → ryzyko zakwestionowania odliczenia VAT","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a20.r10 — `tax_point_wnt_water_works`: WNT robót budowlanych przez podmiot UE → Data protokołu odbioru
else :=   {"matched":true,"rule_id":"jdg.vat.a20.r10","package":"jdg.micro.vat","priority":524,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WNT robót budowlanych przez podmiot UE","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a20.r6 — `tax_point_wnt_chain_transaction`: WNT w transakcji łańcuchowej → Wg roli w łańcuchu
else :=   {"matched":true,"rule_id":"jdg.vat.a20.r6","package":"jdg.micro.vat","priority":525,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WNT w transakcji łańcuchowej","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a20.r7 — `tax_point_wnt_installation`: WNT z montażem/instalacją → Data zakończenia instalacji
else :=   {"matched":true,"rule_id":"jdg.vat.a20.r7","package":"jdg.micro.vat","priority":526,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WNT z montażem/instalacją","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a20.r8 — `tax_point_wnt_excise_goods`: WNT wyrobów akcyzowych → Zgodnie z przepisami akcyzowymi
else :=   {"matched":true,"rule_id":"jdg.vat.a20.r8","package":"jdg.micro.vat","priority":527,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WNT wyrobów akcyzowych","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a20.r9 — `tax_point_wnt_gas_electricity`: WNT gazu, energii elektrycznej → Data odczytu licznika
else :=   {"matched":true,"rule_id":"jdg.vat.a20.r9","package":"jdg.micro.vat","priority":528,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WNT gazu, energii elektrycznej","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r10 — `vat_rate_23_telecommunications`: Usługi telekomunikacyjne → 23%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r10","package":"jdg.micro.vat","priority":529,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usługi telekomunikacyjne","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r11 — `vat_rate_23_rental_commercial`: Najem lokali użytkowych, biur, magazynów → 23%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r11","package":"jdg.micro.vat","priority":530,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Najem lokali użytkowych, biur, magazynów","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r14 — `vat_rate_23_jewelry_luxury`: Biżuteria, wyroby luksusowe → 23%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r14","package":"jdg.micro.vat","priority":531,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Biżuteria, wyroby luksusowe","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r15 — `vat_rate_23_furniture`: Meble, wyposażenie wnętrz → 23%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r15","package":"jdg.micro.vat","priority":532,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Meble, wyposażenie wnętrz","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r19 — `vat_rate_8_waste_collection`: Wywóz śmieci, gospodarka odpadami → 8%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r19","package":"jdg.micro.vat","priority":533,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wywóz śmieci, gospodarka odpadami","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r20 — `vat_rate_8_cleaning_streets`: Utrzymanie czystości, dezynfekcja → 8%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r20","package":"jdg.micro.vat","priority":534,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Utrzymanie czystości, dezynfekcja","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r22 — `vat_rate_8_construction_social`: Budownictwo społeczne (TBS, gminne) → 8%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r22","package":"jdg.micro.vat","priority":535,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Budownictwo społeczne (TBS, gminne)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r25 — `vat_rate_8_transport_passenger`: Transport pasażerski (krajowy) → 8%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r25","package":"jdg.micro.vat","priority":536,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Transport pasażerski (krajowy)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r27 — `vat_rate_8_cultural_events`: Wstęp na imprezy kulturalne, sportowe → 8%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r27","package":"jdg.micro.vat","priority":537,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wstęp na imprezy kulturalne, sportowe","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r30 — `vat_rate_5_newspapers`: Gazety, czasopisma (prasa regionalna/krajowa) → 5%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r30","package":"jdg.micro.vat","priority":538,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Gazety, czasopisma (prasa regionalna/krajowa)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r32 — `vat_rate_5_baby_products`: Artykuły dla niemowląt (pieluchy, ubranka) → 5%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r32","package":"jdg.micro.vat","priority":539,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Artykuły dla niemowląt (pieluchy, ubranka)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r33 — `vat_rate_5_food_meat_fish`: Mięso, ryby, owoce morza (nieprzetworzone) → 5%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r33","package":"jdg.micro.vat","priority":540,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mięso, ryby, owoce morza (nieprzetworzone)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r34 — `vat_rate_5_agricultural_inputs`: Środki produkcji rolnej (nasiona, nawozy) → 5%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r34","package":"jdg.micro.vat","priority":541,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Środki produkcji rolnej (nasiona, nawozy)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r35 — `vat_rate_5_disposable_medical`: Maseczki, rękawiczki medyczne (jednorazowe) → 5%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r35","package":"jdg.micro.vat","priority":542,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Maseczki, rękawiczki medyczne (jednorazowe)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r37 — `vat_rate_0_export_indirect`: Eksport pośredni (przez agencję celną) → 0%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r37","package":"jdg.micro.vat","priority":543,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Eksport pośredni (przez agencję celną)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r39 — `vat_rate_0_wdt_documentation_required`: WDT — wymagane dokumenty potwierdzające wywóz z PL → 0% warunkowo
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r39","package":"jdg.micro.vat","priority":544,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WDT — wymagane dokumenty potwierdzające wywóz z PL","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r40 — `vat_rate_0_wdt_missing_docs_domestic`: WDT — brak dokumentów w 3 miesiące → stawka krajowa → Sankcja
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r40","package":"jdg.micro.vat","priority":545,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WDT — brak dokumentów w 3 miesiące → stawka krajowa","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r41 — `vat_rate_0_international_transport`: Międzynarodowy transport towarów → 0%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r41","package":"jdg.micro.vat","priority":546,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Międzynarodowy transport towarów","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r43 — `vat_rate_0_services_related_to_export`: Usługi pomocnicze do eksportu (załadowanie, spedycja) → 0%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r43","package":"jdg.micro.vat","priority":547,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usługi pomocnicze do eksportu (załadowanie, spedycja)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r44 — `vat_rate_0_supplies_to_ships_aircraft`: Dostawy na statki, samoloty w komunikacji międzynarodowej → 0%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r44","package":"jdg.micro.vat","priority":548,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dostawy na statki, samoloty w komunikacji międzynarodowej","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r47 — `vat_exemption_object_social_security`: Pomoc społeczna, opieka nad osobami starszymi → ZW
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r47","package":"jdg.micro.vat","priority":549,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pomoc społeczna, opieka nad osobami starszymi","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r48 — `vat_exemption_object_culture_sport`: Usługi kulturalne, sportowe (niekomercyjne) → ZW
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r48","package":"jdg.micro.vat","priority":550,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usługi kulturalne, sportowe (niekomercyjne)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r50 — `vat_exemption_object_land_except_building`: Dostawa gruntów (niezabudowanych, budowlanych) → ZW (z opcją VAT)
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r50","package":"jdg.micro.vat","priority":551,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dostawa gruntów (niezabudowanych, budowlanych)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r6 — `vat_rate_23_transport_goods`: Transport towarów (krajowy) → 23%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r6","package":"jdg.micro.vat","priority":552,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Transport towarów (krajowy)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r8 — `vat_rate_23_marketing_advertising`: Usługi marketingowe, reklamowe → 23%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r8","package":"jdg.micro.vat","priority":553,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usługi marketingowe, reklamowe","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a41.r9 — `vat_rate_23_cleaning_maintenance`: Usługi sprzątania, utrzymania czystości → 23%
else :=   {"matched":true,"rule_id":"jdg.vat.a41.r9","package":"jdg.micro.vat","priority":554,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usługi sprzątania, utrzymania czystości","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a43.r12 — `Usługi pocztowe świadczone przez operatora wyznaczonego`: W ramach usług powszechnych
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r12","package":"jdg.micro.vat","priority":555,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"W ramach usług powszechnych","_legal_basis":"Art. 43 ust. 1 pkt 17","_warnings":[]} {
    true
}

# jdg.vat.a43.r13 — `Udzielanie pożyczek, kredytów przez JDG (private lending)`: Gdy nie jest to działalność podstawowa
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r13","package":"jdg.micro.vat","priority":556,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Gdy nie jest to działalność podstawowa","_legal_basis":"Art. 43 ust. 1 pkt 38","_warnings":[]} {
    true
}

# jdg.vat.a43.r14 — `Działalność agentów ubezpieczeniowych`: W ramach pośrednictwa
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r14","package":"jdg.micro.vat","priority":557,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"W ramach pośrednictwa","_legal_basis":"Art. 43 ust. 1 pkt 7","_warnings":[]} {
    true
}

# jdg.vat.a43.r16 — `Pierwsze zasiedlenie nieruchomości`: Definicja pierwszego zasiedlenia
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r16","package":"jdg.micro.vat","priority":558,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Definicja pierwszego zasiedlenia","_legal_basis":"Art. 43 ust. 1 pkt 10","_warnings":[]} {
    true
}

# jdg.vat.a43.r17 — `Rezygnacja ze zwolnienia (opcja VAT) na nieruchomości`: Złożenie oświadczenia VAT-23
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r17","package":"jdg.micro.vat","priority":559,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Złożenie oświadczenia VAT-23","_legal_basis":"Art. 43 ust. 10-11","_warnings":[]} {
    true
}

# jdg.vat.a43.r21 — `Pobranie krwi, mleka, narządów`: Przez uprawnione podmioty
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r21","package":"jdg.micro.vat","priority":560,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przez uprawnione podmioty","_legal_basis":"Art. 43 ust. 1 pkt 15","_warnings":[]} {
    true
}

# jdg.vat.a43.r22 — `Usługi pogrzebowe, kremacyjne`: Przez uprawnione podmioty
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r22","package":"jdg.micro.vat","priority":561,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przez uprawnione podmioty","_legal_basis":"Art. 43 ust. 1 pkt 38","_warnings":[]} {
    true
}

# jdg.vat.a43.r23 — `Dostawa gruntów rolnych (z wyłączeniem budowlanych)`: Na cele rolnicze
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r23","package":"jdg.micro.vat","priority":562,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Na cele rolnicze","_legal_basis":"Art. 43 ust. 1 pkt 9","_warnings":[]} {
    true
}

# jdg.vat.a43.r24 — `Dzierżawa gruntów rolnych`: Na cele rolnicze
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r24","package":"jdg.micro.vat","priority":563,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Na cele rolnicze","_legal_basis":"Art. 43 ust. 1 pkt 9","_warnings":[]} {
    true
}

# jdg.vat.a43.r25 — `Usługi leśne, dostawa drewna z lasów`: Przez nadleśnictwa
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r25","package":"jdg.micro.vat","priority":564,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przez nadleśnictwa","_legal_basis":"Art. 43 ust. 1 pkt 34","_warnings":[]} {
    true
}

# jdg.vat.a43.r26 — `Usługi transportu miejskiego, regionalnego`: Finansowane ze środków publicznych
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r26","package":"jdg.micro.vat","priority":565,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Finansowane ze środków publicznych","_legal_basis":"Art. 43 ust. 1 pkt 30","_warnings":[]} {
    true
}

# jdg.vat.a43.r27 — `Usługi na rzecz organizacji międzynarodowych, ambasad`: Zwolnienie dyplomatyczne
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r27","package":"jdg.micro.vat","priority":566,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwolnienie dyplomatyczne","_legal_basis":"Art. 43 ust. 1 pkt 45","_warnings":[]} {
    true
}

# jdg.vat.a43.r28 — `Usługi nadawców publicznych (TVP, Polskie Radio)`: Misja publiczna
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r28","package":"jdg.micro.vat","priority":567,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Misja publiczna","_legal_basis":"Art. 43 ust. 1 pkt 34","_warnings":[]} {
    true
}

# jdg.vat.a43.r29 — `Usługi organizacji pożytku publicznego (OPP)`: Nieodpłatne na cele statutowe
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r29","package":"jdg.micro.vat","priority":568,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nieodpłatne na cele statutowe","_legal_basis":"Art. 43 ust. 1 pkt 31","_warnings":[]} {
    true
}

# jdg.vat.a43.r30 — `Wynajem lokali przez gminę/TBS`: Na cele mieszkaniowe
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r30","package":"jdg.micro.vat","priority":569,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Na cele mieszkaniowe","_legal_basis":"Art. 43 ust. 1 pkt 36","_warnings":[]} {
    true
}

# jdg.vat.a43.r31 — `Zarządzanie nieruchomościami mieszkalnymi`: Wspólnoty mieszkaniowe
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r31","package":"jdg.micro.vat","priority":570,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wspólnoty mieszkaniowe","_legal_basis":"Art. 43 ust. 1 pkt 39","_warnings":[]} {
    true
}

# jdg.vat.a43.r32 — `Usługi kościołów, związków wyznaniowych`: Cele religijne, duchowe
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r32","package":"jdg.micro.vat","priority":571,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Cele religijne, duchowe","_legal_basis":"Art. 43 ust. 1 pkt 35-36","_warnings":[]} {
    true
}

# jdg.vat.a43.r33 — `Usługi ślubne w kościołach, wynajem kaplic`: Przez związki wyznaniowe
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r33","package":"jdg.micro.vat","priority":572,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przez związki wyznaniowe","_legal_basis":"Art. 43 ust. 1 pkt 35","_warnings":[]} {
    true
}

# jdg.vat.a43.r34 — `Usługi adopcyjne`: Przez uprawnione podmioty
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r34","package":"jdg.micro.vat","priority":573,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przez uprawnione podmioty","_legal_basis":"Art. 43 ust. 1 pkt 40","_warnings":[]} {
    true
}

# jdg.vat.a43.r37 — `Warsztaty terapii zajęciowej, zakłady aktywności zawodowej`: Dla osób niepełnosprawnych
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r37","package":"jdg.micro.vat","priority":574,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dla osób niepełnosprawnych","_legal_basis":"Art. 43 ust. 1 pkt 41","_warnings":[]} {
    true
}

# jdg.vat.a43.r38 — `Promocja kultury, sztuki`: Niepubliczne instytucje kultury
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r38","package":"jdg.micro.vat","priority":575,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niepubliczne instytucje kultury","_legal_basis":"Art. 43 ust. 1 pkt 33","_warnings":[]} {
    true
}

# jdg.vat.a43.r40 — `Dostawa przedmiotów kolekcjonerskich (procedura marży)`: Nabyte od osób prywatnych
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r40","package":"jdg.micro.vat","priority":576,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nabyte od osób prywatnych","_legal_basis":"Art. 120 VAT","_warnings":[]} {
    true
}

# jdg.vat.a43.r5 — `Transport sanitarny pacjentów`: Przez uprawnione podmioty
else :=   {"matched":true,"rule_id":"jdg.vat.a43.r5","package":"jdg.micro.vat","priority":577,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przez uprawnione podmioty","_legal_basis":"Art. 43 ust. 1 pkt 22","_warnings":[]} {
    true
}

# jdg.vat.a8.r1 — `service_definition_b2b`: Każde świadczenie na rzecz B2B niebędące dostawą towarów → Usługa
else :=   {"matched":true,"rule_id":"jdg.vat.a8.r1","package":"jdg.micro.vat","priority":578,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Każde świadczenie na rzecz B2B niebędące dostawą towarów","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a8.r10 — `service_lunch_vouchers`: Vouchery lunchowe dla pracowników → zwolnione z VAT
else :=   {"matched":true,"rule_id":"jdg.vat.a8.r10","package":"jdg.micro.vat","priority":579,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Vouchery lunchowe dla pracowników","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a8.r11 — `service_rental_of_property`: Najem, dzierżawa, leasing nieruchomości → Usługa — miejsce świadczenia wg miejsca położenia
else :=   {"matched":true,"rule_id":"jdg.vat.a8.r11","package":"jdg.micro.vat","priority":580,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Najem, dzierżawa, leasing nieruchomości","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a8.r12 — `service_rental_of_movable`: Najem, dzierżawa ruchomości → Usługa
else :=   {"matched":true,"rule_id":"jdg.vat.a8.r12","package":"jdg.micro.vat","priority":581,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Najem, dzierżawa ruchomości","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a8.r2 — `service_definition_b2c`: Każde świadczenie na rzecz B2C niebędące dostawą towarów → Usługa
else :=   {"matched":true,"rule_id":"jdg.vat.a8.r2","package":"jdg.micro.vat","priority":582,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Każde świadczenie na rzecz B2C niebędące dostawą towarów","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a8.r3 — `service_transfer_intangible`: Zbycie praw, udzielenie licencji, know-how → Usługa
else :=   {"matched":true,"rule_id":"jdg.vat.a8.r3","package":"jdg.micro.vat","priority":583,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zbycie praw, udzielenie licencji, know-how","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a8.r4 — `service_obligation_to_abstain`: Zobowiązanie do powstrzymania się od działania → Usługa
else :=   {"matched":true,"rule_id":"jdg.vat.a8.r4","package":"jdg.micro.vat","priority":584,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zobowiązanie do powstrzymania się od działania","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a8.r5 — `service_undertaking_to_perform`: Zobowiązanie do wykonania czynności → Usługa
else :=   {"matched":true,"rule_id":"jdg.vat.a8.r5","package":"jdg.micro.vat","priority":585,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zobowiązanie do wykonania czynności","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a8.r6 — `service_free_of_charge_business`: Nieodpłatne usługi na cele firmowe → VAT NIE należny
else :=   {"matched":true,"rule_id":"jdg.vat.a8.r6","package":"jdg.micro.vat","priority":586,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nieodpłatne usługi na cele firmowe","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a8.r7 — `service_free_of_charge_owner`: Nieodpłatne usługi na cele osobiste JDG → VAT należny
else :=   {"matched":true,"rule_id":"jdg.vat.a8.r7","package":"jdg.micro.vat","priority":587,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nieodpłatne usługi na cele osobiste JDG","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a8.r8 — `service_free_of_charge_employee`: Nieodpłatne usługi na rzecz pracownika → VAT należny
else :=   {"matched":true,"rule_id":"jdg.vat.a8.r8","package":"jdg.micro.vat","priority":588,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nieodpłatne usługi na rzecz pracownika","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a8.r9 — `service_employee_benefit_exempt`: Nieodpłatne usługi dla pracowników (opieka medyczna, kultura) → zwolnione z VAT
else :=   {"matched":true,"rule_id":"jdg.vat.a8.r9","package":"jdg.micro.vat","priority":589,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nieodpłatne usługi dla pracowników (opieka medyczna, kultura)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a86.r11 — `deduction_pre_proportion_banking`: Pre-proporcja dla JDG w usługach finansowych → Specjalna proporcja
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r11","package":"jdg.micro.vat","priority":590,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pre-proporcja dla JDG w usługach finansowych","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a86.r12 — `deduction_import_goods_customs`: Podstawa odliczenia VAT od importu = wartość celna + cło + akcyza → Podstawa importu
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r12","package":"jdg.micro.vat","priority":591,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa odliczenia VAT od importu = wartość celna + cło + akcyza","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a86.r14 — `deduction_reverse_charge_domestic`: Odwrotne obciążenie krajowe (budowlanka) → VAT należny = VAT naliczony
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r14","package":"jdg.micro.vat","priority":592,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odwrotne obciążenie krajowe (budowlanka)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a86.r17 — `deduction_self_import_services`: Samodzielne świadczenie usług na własne potrzeby (np. budowa) → VAT należny od własnych usług
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r17","package":"jdg.micro.vat","priority":593,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Samodzielne świadczenie usług na własne potrzeby (np. budowa)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a86.r18 — `deduction_additional_costs`: Koszty dodatkowe (prowizja, odsetki) związane z importem → Odliczenie VAT od kosztów
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r18","package":"jdg.micro.vat","priority":594,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Koszty dodatkowe (prowizja, odsetki) związane z importem","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a86.r19 — `deduction_vat_deposit_guarantee`: VAT od kaucji, gwarancji, depozytów → Brak odliczenia
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r19","package":"jdg.micro.vat","priority":595,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"VAT od kaucji, gwarancji, depozytów","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a86.r20 — `deduction_vat_from_subsidies`: VAT dotacji, dofinansowań, grantów → Odliczenie (jeśli dot. czynności opodatkowanych)
else :=   {"matched":true,"rule_id":"jdg.vat.a86.r20","package":"jdg.micro.vat","priority":596,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"VAT dotacji, dofinansowań, grantów","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a86a.r10 — `car_vat_mileage_log_monthly_submission`: Ewidencja składana do US na żądanie → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.vat.a86a.r10","package":"jdg.micro.vat","priority":597,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ewidencja składana do US na żądanie","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a86a.r9 — `car_vat_mileage_log_retention`: Ewidencję przebiegu przechowuje się 5 lat → Okres przechowywania
else :=   {"matched":true,"rule_id":"jdg.vat.a86a.r9","package":"jdg.micro.vat","priority":598,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ewidencję przebiegu przechowuje się 5 lat","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a88.r10 — `Zakup od osoby prywatnej (nie-podatnika VAT)`: deduction_blocked_purchase_from_private
else :=   {"matched":true,"rule_id":"jdg.vat.a88.r10","package":"jdg.micro.vat","priority":599,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"deduction_blocked_purchase_from_private","_legal_basis":"Art. 15","_warnings":[]} {
    true
}

# jdg.vat.a88.r11 — `Zakup usług zwolnionych z VAT`: deduction_blocked_acquired_services_exempt
else :=   {"matched":true,"rule_id":"jdg.vat.a88.r11","package":"jdg.micro.vat","priority":600,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"deduction_blocked_acquired_services_exempt","_legal_basis":"Art. 86 ust. 2","_warnings":[]} {
    true
}

# jdg.vat.a88.r12 — `Zakup usług i towarów z państw trzecich (bez rozliczenia importu)`: deduction_blocked_tax_free_internet
else :=   {"matched":true,"rule_id":"jdg.vat.a88.r12","package":"jdg.micro.vat","priority":601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"deduction_blocked_tax_free_internet","_legal_basis":"Art. 17","_warnings":[]} {
    true
}

# jdg.vat.a88.r14 — `Samochód używany mieszanie — 50% VAT (bez ewidencji przebiegu)`: deduction_blocked_car_100pct_no_evidence
else :=   {"matched":true,"rule_id":"jdg.vat.a88.r14","package":"jdg.micro.vat","priority":602,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"deduction_blocked_car_100pct_no_evidence","_legal_basis":"Art. 86a","_warnings":[]} {
    true
}

# jdg.vat.a88.r15 — `Samochód używany tylko firmowo (100% VAT) — wymagana ewidencja`: deduction_blocked_car_100pct_with_evidence
else :=   {"matched":true,"rule_id":"jdg.vat.a88.r15","package":"jdg.micro.vat","priority":603,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"deduction_blocked_car_100pct_with_evidence","_legal_basis":"Art. 86a","_warnings":[]} {
    true
}

# jdg.vat.a88.r6 — `Próbki, prezenty małej wartości (do 20 PLN) — odliczenie dozwolone`: deduction_blocked_gifts_samples_except
else :=   {"matched":true,"rule_id":"jdg.vat.a88.r6","package":"jdg.micro.vat","priority":604,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"deduction_blocked_gifts_samples_except","_legal_basis":"Wyjątek","_warnings":[]} {
    true
}

# jdg.vat.a88.r9 — `Faktura od podmiotu niezarejestrowanego jako czynny podatnik VAT`: deduction_blocked_invoice_from_non_payer
else :=   {"matched":true,"rule_id":"jdg.vat.a88.r9","package":"jdg.micro.vat","priority":605,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"deduction_blocked_invoice_from_non_payer","_legal_basis":"Art. 88 ust. 1 pkt 2","_warnings":[]} {
    true
}

# jdg.vat.a89a.r4 — `Wierzyciel`: Korekta w deklaracji za okres, w którym upłynął 151. dzień → Termin korekty
else :=   {"matched":true,"rule_id":"jdg.vat.a89a.r4","package":"jdg.micro.vat","priority":606,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta w deklaracji za okres, w którym upłynął 151. dzień","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a89b.r3 — `Dłużnik (JDG)`: Korekta w deklaracji za okres, w którym upłynął 91. dzień → Termin
else :=   {"matched":true,"rule_id":"jdg.vat.a89b.r3","package":"jdg.micro.vat","priority":607,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta w deklaracji za okres, w którym upłynął 91. dzień","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a89b.r5 — `Dłużnik (JDG)`: Zapłata po korekcie → przywrócenie odliczenia VAT → Odwrócenie
else :=   {"matched":true,"rule_id":"jdg.vat.a89b.r5","package":"jdg.micro.vat","priority":608,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zapłata po korekcie → przywrócenie odliczenia VAT","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a99.r10 — `vat_declaration_vat_payable_payment`: VAT do zapłaty w terminie deklaracji (do 25. dnia) → Płatność
else :=   {"matched":true,"rule_id":"jdg.vat.a99.r10","package":"jdg.micro.vat","priority":609,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"VAT do zapłaty w terminie deklaracji (do 25. dnia)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a99.r3 — `vat_declaration_quarterly_deadline_25`: JPK_V7K — termin 25. dnia miesiąca po kwartale → Termin 25. dzień
else :=   {"matched":true,"rule_id":"jdg.vat.a99.r3","package":"jdg.micro.vat","priority":610,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"JPK_V7K — termin 25. dnia miesiąca po kwartale","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a99.r6 — `vat_declaration_overdue_interest`: Po terminie → odsetki za zwłokę → Sankcja finansowa
else :=   {"matched":true,"rule_id":"jdg.vat.a99.r6","package":"jdg.micro.vat","priority":611,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Po terminie → odsetki za zwłokę","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a99.r7 — `vat_declaration_correction_on_own`: Korekta deklaracji VAT na własne żądanie → Możliwość korekty
else :=   {"matched":true,"rule_id":"jdg.vat.a99.r7","package":"jdg.micro.vat","priority":612,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta deklaracji VAT na własne żądanie","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a99.r8 — `vat_declaration_correction_deadline`: Korekta w ciągu 5 lat od końca roku podatkowego → Termin korekty
else :=   {"matched":true,"rule_id":"jdg.vat.a99.r8","package":"jdg.micro.vat","priority":613,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta w ciągu 5 lat od końca roku podatkowego","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.vat.a99.r9 — `vat_declaration_correction_after_audit`: Korekta po kontroli — tylko za zgodą naczelnika US → Ograniczenie
else :=   {"matched":true,"rule_id":"jdg.vat.a99.r9","package":"jdg.micro.vat","priority":614,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta po kontroli — tylko za zgodą naczelnika US","_legal_basis":"","_warnings":[]} {
    true
}
