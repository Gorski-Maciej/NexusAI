# Generated from Plan OPA 33 — Micro-rules for cb
# 2026-07-13 14:58:41
# Rules: 20 (new, deduplicated)

package jdg.micro.cb

default decide := {"matched":false,"rule_id":"jdg.micro.cb.no_match","package":"jdg.micro.cb","priority":99999}

# jdg.cb.r1 — `cross_border_service_eu_b2b`: Usluga B2B na rzecz podatnika VAT-UE (NIP UE nabywcy) -> miejsce swiadczenia w kraju nabywcy → Nie podlega VAT w PL
decide :=   {"matched":true,"rule_id":"jdg.cb.r1","package":"jdg.micro.cb","priority":6200,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usluga B2B na rzecz podatnika VAT-UE (NIP UE nabywcy) -> miejsce swiadczenia w kraju nabywcy","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Usluga B2B na rzecz podatnika VAT-UE (NIP UE nabywcy) -> miejsce swiadczenia w kraju nabywcy"]} {
    object.get(input.vendor, "country", "PL") != "PL"
}

# jdg.cb.r10 — `cross_border_sale_of_goods_ioss_limit_150`: IOSS: limit 150 EUR na przesyłke → Limit
else :=   {"matched":true,"rule_id":"jdg.cb.r10","package":"jdg.micro.cb","priority":6201,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"IOSS: limit 150 EUR na przesyłke","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] IOSS: limit 150 EUR na przesyłke"]} {
    object.get(input.vendor, "country", "PL") != "PL"
}

# jdg.cb.r11 — `cross_border_e_commerce_platform`: Platforma (Amazon, Allegro) jako podatnik (deemed supplier) → Platforma
else :=   {"matched":true,"rule_id":"jdg.cb.r11","package":"jdg.micro.cb","priority":6202,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Platforma (Amazon, Allegro) jako podatnik (deemed supplier)","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Platforma (Amazon, Allegro) jako podatnik (deemed supplier)"]} {
    object.get(input.vendor, "country", "PL") != "PL"
}

# jdg.cb.r12 — `cross_border_vat_refund_eu`: Zwrot VAT z innego kraju UE (wniosek VAT-REF) → Procedura
else :=   {"matched":true,"rule_id":"jdg.cb.r12","package":"jdg.micro.cb","priority":6203,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwrot VAT z innego kraju UE (wniosek VAT-REF)","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Zwrot VAT z innego kraju UE (wniosek VAT-REF)"]} {
    object.get(input.vendor, "country", "PL") != "PL"
}

# jdg.cb.r13 — `cross_border_vat_refund_deadline_30_september`: Wniosek VAT-REF do 30 wrzesnia nastepnego roku → Termin
else :=   {"matched":true,"rule_id":"jdg.cb.r13","package":"jdg.micro.cb","priority":6204,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wniosek VAT-REF do 30 wrzesnia nastepnego roku","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Wniosek VAT-REF do 30 wrzesnia nastepnego roku"]} {
    object.get(input.vendor, "country", "PL") != "PL"
}

# jdg.cb.r14 — `cross_border_wht_interest_royalties`: WHT (podatek u zrodla): odsetki, naleznosci licencyjne do podmiotow zagranicznych → 20%/19% WHT
else :=   {"matched":true,"rule_id":"jdg.cb.r14","package":"jdg.micro.cb","priority":6205,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WHT (podatek u zrodla): odsetki, naleznosci licencyjne do podmiotow zagranicznych","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] WHT (podatek u zrodla): odsetki, naleznosci licencyjne do podmiotow zagranicznych"]} {
    object.get(input.vendor, "country", "PL") != "PL"; object.get(input.invoice, "withholding_tax_applicable", false) == true
}

# jdg.cb.r15 — `cross_border_wht_dividends`: Dywidendy do podmiotu zagranicznego: 19% WHT → 19% WHT
else :=   {"matched":true,"rule_id":"jdg.cb.r15","package":"jdg.micro.cb","priority":6206,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dywidendy do podmiotu zagranicznego: 19% WHT","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Dywidendy do podmiotu zagranicznego: 19% WHT"]} {
    object.get(input.vendor, "country", "PL") != "PL"; object.get(input.invoice, "withholding_tax_applicable", false) == true
}

# jdg.cb.r16 — `cross_border_wht_exemption_treaty`: Zwolnienie z WHT na podstawie umowy o unikaniu podwojnego opodatkowania → Zwolnienie
else :=   {"matched":true,"rule_id":"jdg.cb.r16","package":"jdg.micro.cb","priority":6207,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zwolnienie z WHT na podstawie umowy o unikaniu podwojnego opodatkowania","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Zwolnienie z WHT na podstawie umowy o unikaniu podwojnego opodatkowania"]} {
    object.get(input.vendor, "country", "PL") != "PL"; object.get(input.invoice, "withholding_tax_applicable", false) == true
}

# jdg.cb.r17 — `cross_border_wht_refund_procedure`: Refundacja WHT: wniosek do US o zwrot nadplaty → Refundacja
else :=   {"matched":true,"rule_id":"jdg.cb.r17","package":"jdg.micro.cb","priority":6208,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Refundacja WHT: wniosek do US o zwrot nadplaty","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Refundacja WHT: wniosek do US o zwrot nadplaty"]} {
    object.get(input.vendor, "country", "PL") != "PL"; object.get(input.invoice, "withholding_tax_applicable", false) == true
}

# jdg.cb.r18 — `cross_border_wht_pay_and_refund`: Mechanizm: zaplata WHT, nastepnie wniosek o zwrot (gdy przysluguje na podstawie umowy) → Procedura
else :=   {"matched":true,"rule_id":"jdg.cb.r18","package":"jdg.micro.cb","priority":6209,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mechanizm: zaplata WHT, nastepnie wniosek o zwrot (gdy przysluguje na podstawie umowy)","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Mechanizm: zaplata WHT, nastepnie wniosek o zwrot (gdy przysluguje na podstawie umowy)"]} {
    object.get(input.vendor, "country", "PL") != "PL"; object.get(input.invoice, "withholding_tax_applicable", false) == true
}

# jdg.cb.r19 — `cross_border_wht_exemption_certificate`: Certyfikat rezydencji podatkowej kontrahenta zagranicznego (warunek zwolnienia) → Wymog
else :=   {"matched":true,"rule_id":"jdg.cb.r19","package":"jdg.micro.cb","priority":6210,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Certyfikat rezydencji podatkowej kontrahenta zagranicznego (warunek zwolnienia)","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Certyfikat rezydencji podatkowej kontrahenta zagranicznego (warunek zwolnienia)"]} {
    object.get(input.vendor, "country", "PL") != "PL"; object.get(input.invoice, "withholding_tax_applicable", false) == true
}

# jdg.cb.r2 — `cross_border_service_eu_b2c`: Usluga B2C na rzecz osoby fizycznej z UE -> miejsce swiadczenia w PL (VAT PL) → VAT w PL
else :=   {"matched":true,"rule_id":"jdg.cb.r2","package":"jdg.micro.cb","priority":6211,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usluga B2C na rzecz osoby fizycznej z UE -> miejsce swiadczenia w PL (VAT PL)","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Usluga B2C na rzecz osoby fizycznej z UE -> miejsce swiadczenia w PL (VAT PL)"]} {
    object.get(input.vendor, "country", "PL") != "PL"
}

# jdg.cb.r20 — `cross_border_fx_risk_assessment`: Ryzyko kursowe w transakcjach walutowych -> przeliczniki NBP → Ryzyko
else :=   {"matched":true,"rule_id":"jdg.cb.r20","package":"jdg.micro.cb","priority":6212,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ryzyko kursowe w transakcjach walutowych -> przeliczniki NBP","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Ryzyko kursowe w transakcjach walutowych -> przeliczniki NBP"]} {
    object.get(input.vendor, "country", "PL") != "PL"
}

# jdg.cb.r3 — `cross_border_service_non_eu`: Usluga na rzecz podmiotu spoza UE -> miejsce swiadczenia poza UE → Brak VAT w PL
else :=   {"matched":true,"rule_id":"jdg.cb.r3","package":"jdg.micro.cb","priority":6213,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Usluga na rzecz podmiotu spoza UE -> miejsce swiadczenia poza UE","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Usluga na rzecz podmiotu spoza UE -> miejsce swiadczenia poza UE"]} {
    object.get(input.vendor, "country", "PL") != "PL"
}

# jdg.cb.r4 — `cross_border_service_oss_union`: OSS (One Stop Shop): JDG moze rozliczac VAT od uslug B2C w UE przez OSS → Opcja
else :=   {"matched":true,"rule_id":"jdg.cb.r4","package":"jdg.micro.cb","priority":6214,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"OSS (One Stop Shop): JDG moze rozliczac VAT od uslug B2C w UE przez OSS","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] OSS (One Stop Shop): JDG moze rozliczac VAT od uslug B2C w UE przez OSS"]} {
    object.get(input.vendor, "country", "PL") != "PL"
}

# jdg.cb.r5 — `cross_border_service_oss_threshold_10k`: Limit OSS: 10 000 EUR przychodu z uslug B2C w UE (jesli nizej -> VAT PL) → Limit
else :=   {"matched":true,"rule_id":"jdg.cb.r5","package":"jdg.micro.cb","priority":6215,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Limit OSS: 10 000 EUR przychodu z uslug B2C w UE (jesli nizej -> VAT PL)","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Limit OSS: 10 000 EUR przychodu z uslug B2C w UE (jesli nizej -> VAT PL)"]} {
    object.get(input.vendor, "country", "PL") != "PL"
}

# jdg.cb.r6 — `cross_border_service_oss_excess_10k`: Przekroczenie 10k EUR -> obowiazkowo OSS (lub rejestracja w kazdym kraju) → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.cb.r6","package":"jdg.micro.cb","priority":6216,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przekroczenie 10k EUR -> obowiazkowo OSS (lub rejestracja w kazdym kraju)","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Przekroczenie 10k EUR -> obowiazkowo OSS (lub rejestracja w kazdym kraju)"]} {
    object.get(input.vendor, "country", "PL") != "PL"
}

# jdg.cb.r7 — `cross_border_service_import_from_eu`: Import uslug z UE (od podatnika VAT-UE) -> reverse charge w PL → Reverse charge
else :=   {"matched":true,"rule_id":"jdg.cb.r7","package":"jdg.micro.cb","priority":6217,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Import uslug z UE (od podatnika VAT-UE) -> reverse charge w PL","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Import uslug z UE (od podatnika VAT-UE) -> reverse charge w PL"]} {
    object.get(input.vendor, "country", "PL") != "PL"
}

# jdg.cb.r8 — `cross_border_service_import_from_non_eu`: Import uslug spoza UE -> reverse charge w PL → Reverse charge
else :=   {"matched":true,"rule_id":"jdg.cb.r8","package":"jdg.micro.cb","priority":6218,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Import uslug spoza UE -> reverse charge w PL","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Import uslug spoza UE -> reverse charge w PL"]} {
    object.get(input.vendor, "country", "PL") != "PL"
}

# jdg.cb.r9 — `cross_border_sale_of_goods_eu_to_consumer`: Sprzedaz towarow do konsumenta w UE (IOSS) -> IOSS lub rejestracja lokalna → IOSS
else :=   {"matched":true,"rule_id":"jdg.cb.r9","package":"jdg.micro.cb","priority":6219,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprzedaz towarow do konsumenta w UE (IOSS) -> IOSS lub rejestracja lokalna","_legal_basis":"transakcje międzynarodowe (WNT/WDT/TP/CFC/MDR)","_warnings":["[MICRO] Sprzedaz towarow do konsumenta w UE (IOSS) -> IOSS lub rejestracja lokalna"]} {
    object.get(input.vendor, "country", "PL") != "PL"
}
