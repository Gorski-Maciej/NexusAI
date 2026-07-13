# Generated from Plan OPA 33 — Micro-rules for mdr
# 2026-07-13 14:58:41
# Rules: 10 (new, deduplicated)

package jdg.micro.mdr

default decide := {"matched":false,"rule_id":"jdg.micro.mdr.no_match","package":"jdg.micro.mdr","priority":99999}

# jdg.mdr.r1 — `mdr_detection_arrangement_qualifying`: Schemat podatkowy: czynnosci mające na celu oszczędność podatkową (kryterium glównej korzyści) → Definicja
decide :=   {"matched":true,"rule_id":"jdg.mdr.r1","package":"jdg.micro.mdr","priority":6800,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Schemat podatkowy: czynnosci mające na celu oszczędność podatkową (kryterium glównej korzyści)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.mdr.r10 — `mdr_exception_for_advice_legal`: Wyjatek: ochrona tajemnicy adwokackiej/radcowskiej (do 2 lat) → Wyjatek
else :=   {"matched":true,"rule_id":"jdg.mdr.r10","package":"jdg.micro.mdr","priority":6801,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wyjatek: ochrona tajemnicy adwokackiej/radcowskiej (do 2 lat)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.mdr.r2 — `mdr_hallmark_generic_confidentiality`: Znamiona ogólne: poufnosc, wynagrodzenie w % oszczednosci → Znamie
else :=   {"matched":true,"rule_id":"jdg.mdr.r2","package":"jdg.micro.mdr","priority":6802,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Znamiona ogólne: poufnosc, wynagrodzenie w % oszczednosci","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.mdr.r3 — `mdr_hallmark_specific_loss_buyout`: Znamiona szczególne: nabycie spolki z strata, transakcje transgraniczne → Znamie
else :=   {"matched":true,"rule_id":"jdg.mdr.r3","package":"jdg.micro.mdr","priority":6803,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Znamiona szczególne: nabycie spolki z strata, transakcje transgraniczne","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.mdr.r4 — `mdr_reporting_deadline_30_days`: Raportowanie MDR do Szefa KAS: w 30 dni od udostepnienia schematu → Termin
else :=   {"matched":true,"rule_id":"jdg.mdr.r4","package":"jdg.micro.mdr","priority":6804,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Raportowanie MDR do Szefa KAS: w 30 dni od udostepnienia schematu","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.mdr.r5 — `mdr_reporting_form_mdr_1`: Formularz MDR-1 (schemat krajowy) lub MDR-3 (schemat transgraniczny) → Forma
else :=   {"matched":true,"rule_id":"jdg.mdr.r5","package":"jdg.micro.mdr","priority":6805,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Formularz MDR-1 (schemat krajowy) lub MDR-3 (schemat transgraniczny)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.mdr.r6 — `mdr_reporting_obligation_promoter`: Obowiazek promotora (doradcy) do raportowania MDR → Promotor
else :=   {"matched":true,"rule_id":"jdg.mdr.r6","package":"jdg.micro.mdr","priority":6806,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiazek promotora (doradcy) do raportowania MDR","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.mdr.r7 — `mdr_reporting_obligation_beneficiary`: Jesli brak promotora -> korzystajacy (JDG) ma obowiazek raportowania → Beneficjent
else :=   {"matched":true,"rule_id":"jdg.mdr.r7","package":"jdg.micro.mdr","priority":6807,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Jesli brak promotora -> korzystajacy (JDG) ma obowiazek raportowania","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.mdr.r8 — `mdr_sanction_10pct_gaar`: Sankcja za brak raportu: 10% wartosci schematu (max 5M PLN) → Sankcja
else :=   {"matched":true,"rule_id":"jdg.mdr.r8","package":"jdg.micro.mdr","priority":6808,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sankcja za brak raportu: 10% wartosci schematu (max 5M PLN)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.mdr.r9 — `mdr_sanction_20pct_for_hallmark_d`: Sankcja za brak raportu znamienia D (E): 20% wartosci → Sankcja
else :=   {"matched":true,"rule_id":"jdg.mdr.r9","package":"jdg.micro.mdr","priority":6809,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sankcja za brak raportu znamienia D (E): 20% wartosci","_legal_basis":"","_warnings":[]} {
    true
}
