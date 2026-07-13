# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 38

package jdg.hyper.mdr

default decide := {"matched":false,"rule_id":"jdg.hyper.mdr.no_match","package":"jdg.hyper.mdr","priority":99999}

# jdg.hyper.mdr.mdr.hallmark.a4.loss_buying — A4
decide :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.a4.loss_buying","package":"jdg.hyper.mdr","priority":1004,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nabycie spółki ze stratą głównie dla korzyści podatkowej","_legal_basis":"R1005","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.a5.conversion_income — A5
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.a5.conversion_income","package":"jdg.hyper.mdr","priority":1005,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Konwersja dochodu do kategorii niżej opodatkowanej","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.a6.circular_transactions — A6
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.a6.circular_transactions","package":"jdg.hyper.mdr","priority":1006,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Transakcje okrężne bez treści ekonomicznej","_legal_basis":"R1007","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.a7.double_deduction — A7
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.a7.double_deduction","package":"jdg.hyper.mdr","priority":1007,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ten sam koszt odliczany w dwóch jurysdykcjach","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.a8.double_depreciation — A8
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.a8.double_depreciation","package":"jdg.hyper.mdr","priority":1008,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ten sam składnik amortyzowany w dwóch krajach","_legal_basis":"R1009","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.a9.double_tax_relief — A9
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.a9.double_tax_relief","package":"jdg.hyper.mdr","priority":1009,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podwójne zwolnienie podatkowe dla tego samego dochodu","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.a10.main_benefit_test — MBT
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.a10.main_benefit_test","package":"jdg.hyper.mdr","priority":1010,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Test głównej korzyści — czy głównym celem jest korzyść podatkowa","_legal_basis":"R-ID","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b1.loss_utilization_group — B1
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b1.loss_utilization_group","package":"jdg.hyper.mdr","priority":1011,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykorzystanie straty w grupie poprzez transfer do podmiotu z zyskiem","_legal_basis":"R1012","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b2.income_conversion_capital — B2
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b2.income_conversion_capital","package":"jdg.hyper.mdr","priority":1012,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Konwersja dochodu bieżącego w kapitałowy (niżej opodatkowany)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b3.deduction_cross_border — B3
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b3.deduction_cross_border","package":"jdg.hyper.mdr","priority":1013,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Transgraniczne przesunięcie odliczenia do jurysdykcji z wyższą stawką","_legal_basis":"R1014","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b4.tax_haven_transfer — B4
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b4.tax_haven_transfer","package":"jdg.hyper.mdr","priority":1014,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Transfer aktywów do/z raju podatkowego","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b5.non_arm_length_payment — B5
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b5.non_arm_length_payment","package":"jdg.hyper.mdr","priority":1015,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Płatności nierynkowe wykorzystujące preferencyjny reżim","_legal_basis":"R1016","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b6.deductible_cross_border — B6
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b6.deductible_cross_border","package":"jdg.hyper.mdr","priority":1016,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie tej samej płatności w dwóch krajach","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b7.non_taxation_claim — B7
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b7.non_taxation_claim","package":"jdg.hyper.mdr","priority":1017,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Roszczenie o nieopodatkowanie w żadnej jurysdykcji","_legal_basis":"R1018","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.b8.hybrid_mismatch — B8
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.b8.hybrid_mismatch","package":"jdg.hyper.mdr","priority":1018,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rozbieżność kwalifikacji prawnej (hybryda) — np. pożyczka vs kapitał","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c1.strategic_acquisition — C1
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c1.strategic_acquisition","package":"jdg.hyper.mdr","priority":1019,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nabycie podmiotu ze stratą > 50% wartości przejętego podmiotu","_legal_basis":"R1020","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c2.income_reclassification — C2
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c2.income_reclassification","package":"jdg.hyper.mdr","priority":1020,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana klasyfikacji dochodu (np. dywidenda → odsetki) dla niższego WHT","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c3.circular_flow_round_trip — C3
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c3.circular_flow_round_trip","package":"jdg.hyper.mdr","priority":1021,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Transakcja okrężna z udziałem podmiotu pośredniczącego bez funkcji ekonomicznej","_legal_basis":"R1022","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c4.cross_border_deduction — C4
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c4.cross_border_deduction","package":"jdg.hyper.mdr","priority":1022,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Transgraniczne odliczenie związane z podmiotem powiązanym w kraju niskopodatkowym","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c5.transfer_pricing_gap — C5
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c5.transfer_pricing_gap","package":"jdg.hyper.mdr","priority":1023,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykorzystanie różnic w metodologii TP między jurysdykcjami","_legal_basis":"R1024","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c6.ip_transfer_hard_to_value — C6
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c6.ip_transfer_hard_to_value","package":"jdg.hyper.mdr","priority":1024,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Transfer trudnych do wyceny wartości niematerialnych","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c7.business_restructuring — C7
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c7.business_restructuring","package":"jdg.hyper.mdr","priority":1025,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Restrukturyzacja biznesu z przeniesieniem funkcji/ryzyk/aktywów transgranicznie","_legal_basis":"R1026","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.c8.safe_harbour_manipulation — C8
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.c8.safe_harbour_manipulation","package":"jdg.hyper.mdr","priority":1026,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sztuczne spełnienie warunków safe harbour dla uniknięcia dokumentacji TP","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.d1.ip_transfer_cross_border — D1
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.d1.ip_transfer_cross_border","package":"jdg.hyper.mdr","priority":1027,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Transgraniczny transfer wartości niematerialnych bez odpowiedniego wynagrodzenia","_legal_basis":"R1028","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.d2.business_transfer — D2
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.d2.business_transfer","package":"jdg.hyper.mdr","priority":1028,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Transfer funkcji/ryzyk/aktywów zmieniający EBIT o > 50%","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.e1.automatic_exchange_bypass — E1
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.e1.automatic_exchange_bypass","package":"jdg.hyper.mdr","priority":1029,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obchodzenie automatycznej wymiany informacji (CRS/DAC)","_legal_basis":"R1030","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.e2.ubo_concealment — E2
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.e2.ubo_concealment","package":"jdg.hyper.mdr","priority":1030,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ukrywanie rzeczywistego beneficjenta poprzez łańcuch podmiotów","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.e3.trust_foundation_chain — E3
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.e3.trust_foundation_chain","package":"jdg.hyper.mdr","priority":1031,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykorzystanie trustów/fundacji w jurysdykcjach nieprzejrzystych","_legal_basis":"R1032","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.hallmark.e4.nominee_director — E4
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.hallmark.e4.nominee_director","package":"jdg.hyper.mdr","priority":1032,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wykorzystanie podstawionych dyrektorów (nominee directors)","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.obligation.user_reporting — Obowiązek
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.obligation.user_reporting","package":"jdg.hyper.mdr","priority":1034,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korzystający → MDR-3 w 30 dni od pierwszej czynności w schemacie","_legal_basis":"R1035","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.obligation.legal_professional_privilege — Wyłączenie
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.obligation.legal_professional_privilege","package":"jdg.hyper.mdr","priority":1035,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Adwokat/radca → zwolnienie; obowiązek przeniesiony na korzystającego","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.obligation.quarterly_mdr4_report — Raport
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.obligation.quarterly_mdr4_report","package":"jdg.hyper.mdr","priority":1036,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"MDR-4 — kwartalne zestawienie schematów (do końca miesiąca po kwartale)","_legal_basis":"R1037","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.deadline.30_days_from_scheme_available — Termin
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.deadline.30_days_from_scheme_available","package":"jdg.hyper.mdr","priority":1037,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"30 dni od udostępnienia schematu","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.deadline.30_days_from_first_implementation — Termin
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.deadline.30_days_from_first_implementation","package":"jdg.hyper.mdr","priority":1038,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"30 dni od pierwszej czynności wykonawczej","_legal_basis":"R1039","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.sanction.administrative_penalty_5m — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.sanction.administrative_penalty_5m","package":"jdg.hyper.mdr","priority":1039,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kara administracyjna do 5 000 000 PLN za brak MDR","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.sanction.kks_liability — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.sanction.kks_liability","package":"jdg.hyper.mdr","priority":1040,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odpowiedzialność KKS (Art. 54-56) za niezgłoszenie schematu","_legal_basis":"R1041","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.retention.scheme_documentation_6_years — Retencja
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.retention.scheme_documentation_6_years","package":"jdg.hyper.mdr","priority":1041,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przechowywanie dokumentacji MDR przez 6 lat","_legal_basis":"","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}

# jdg.hyper.mdr.mdr.aggregate.annual_risk_score — Agregacja
else :=   {"matched":true,"rule_id":"jdg.hyper.mdr.mdr.aggregate.annual_risk_score","package":"jdg.hyper.mdr","priority":1042,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skumulowany wskaźnik ryzyka MDR dla JDG","_legal_basis":"R-ID","_warnings":[]} {
    object.get(input.document, "mdr_scheme_detected", false) == true
}
