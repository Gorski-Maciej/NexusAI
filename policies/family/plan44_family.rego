# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.family (Doc 44: P1860-P1869)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 10
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.family
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.family.no_match","package":"jdg.family","priority":99999}

# jdg.family.spouse_employment_kup — Wynagrodzenie małżonka — warunki KUP
decide :=   {"matched":true,"rule_id":"jdg.family.spouse_employment_kup","package":"jdg.family","priority":1860,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Wynagrodzenie małżonka — warunki KUP","_legal_basis":"Art. 22 ust. 1 PIT, Art. 23 ust. 1 pkt 10 PIT","_warnings":["Wynagrodzenie małżonka — upewnij się, że spełnia kryteria rynkowe"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.family.child_employment_kup — P1861: Wynagrodzenie dziecka (relacja=child)
else :=   {"matched":true,"rule_id":"jdg.family.child_employment_kup","package":"jdg.family","priority":1861,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Wynagrodzenie dziecka — ograniczenia KUP","_legal_basis":"Art. 23 ust. 1 pkt 10 PIT","_warnings":["Wynagrodzenie dziecka — podwyższone ryzyko kontroli US"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}

# jdg.family.health_insurance_deduction — P1862: Ubezpieczenie zdrowotne (bez współpracy)
else :=   {"matched":true,"rule_id":"jdg.family.health_insurance_deduction","package":"jdg.family","priority":1862,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ubezpieczenie zdrowotne rodziny — tylko osoby współpracujące","_legal_basis":"Art. 27b PIT (historycznie)","_warnings":["Ubezpieczenie zdrowotne rodziny — KUP tylko dla zgłoszonych osób współpracujących"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
    not object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
    object.get(input.vendor, "relation_to_entrepreneur", "") == "SPOUSE"
    object.get(input.vendor, "health_insurance_paid", false) == true
}

# jdg.family.car_usage_kup — P1863: Samochód firmowy używany przez rodzinę — limit 75%
else :=   {"matched":true,"rule_id":"jdg.family.car_usage_kup","package":"jdg.family","priority":1863,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":75,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Samochód firmowy używany mieszanie — KUP 75%","_legal_basis":"Art. 23 ust. 1 pkt 46a PIT","_warnings":["Samochód używany przez rodzinę — limit KUP 75% kosztów eksploatacyjnych"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
    object.get(input.invoice, "expense_type", "") == "CAR_USAGE"
}

# jdg.family.cooperation_zus — P1864: Osoba współpracująca (bez planowania sukcesyjnego)
else :=   {"matched":true,"rule_id":"jdg.family.cooperation_zus","package":"jdg.family","priority":1864,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"COOPERATION","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Osoba współpracująca — ZUS jak za przedsiębiorcę","_legal_basis":"Art. 8 ust. 2 SUS","_warnings":["Małżonek/dziecko jako osoba współpracująca — pełne składki ZUS"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
    object.get(input.vendor, "is_cooperating_person", false) == true
    object.get(input.vendor, "succession_planned", true) == false
}

# jdg.family.succession_planning — P1865: Planowanie sukcesyjne — darowizna grupa 0, SD-Z2
else :=   {"matched":true,"rule_id":"jdg.family.succession_planning","package":"jdg.family","priority":1865,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Planowanie sukcesyjne — darowizna firmy rodzinie","_legal_basis":"Ustawa o podatku od spadków i darowizn","_warnings":["Darowizna firmy rodzinie — zgłoś SD-Z2 w 6 miesięcy dla grupy 0"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
    object.get(input.vendor, "succession_planned", false) == true
}

# jdg.family.joint_pit_filing — P1866: Wspólne rozliczenie PIT małżonków — warunki
else :=   {"matched":true,"rule_id":"jdg.family.joint_pit_filing","package":"jdg.family","priority":1866,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"PIT_SCALE","pit_rate":"","pit_bracket":"","pit_annual_return_type":"JOINT","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wspólne rozliczenie PIT małżonków","_legal_basis":"Art. 6 ust. 2 PIT","_warnings":["Wspólne rozliczenie możliwe tylko przy skali podatkowej — nie dla liniowego/ryczałtu"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
    object.get(input.vendor, "joint_pit_filing", false) == true
}

# jdg.family.relief_interaction — P1867: Interakcja ulg podatkowych przy wspólnym rozliczeniu
else :=   {"matched":true,"rule_id":"jdg.family.relief_interaction","package":"jdg.family","priority":1867,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Interakcja ulg: dzieci, rehabilitacja, internet — limit łączny","_legal_basis":"Art. 27f PIT","_warnings":["Limit dochodu dla ulgi na dziecko liczony łącznie dla małżonków"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
    object.get(input.vendor, "relief_interaction_checked", false) == false
}

# jdg.family.pit4r_obligation — P1868: Obowiązek płatnika PIT przy zatrudnieniu rodziny
else :=   {"matched":true,"rule_id":"jdg.family.pit4r_obligation","package":"jdg.family","priority":1868,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"PIT-4R i PIT-11 przy zatrudnieniu członków rodziny","_legal_basis":"Art. 38-42 PIT","_warnings":["Zatrudnienie rodziny — PIT-4R do 20. dnia miesiąca, PIT-11 do 31 stycznia"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
    object.get(input.vendor, "pit4r_obligation_checked", false) == false
}

# jdg.family.asset_transfer_tax — P1869: Przekazanie majątku (bez PIT-4R)
else :=   {"matched":true,"rule_id":"jdg.family.asset_transfer_tax","package":"jdg.family","priority":1869,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Przekazanie majątku — PIT (odpłatne=przychód), VAT, PCC (grupa 0 zwolnione)","_legal_basis":"Art. 14 PIT, Art. 7 VAT, Ustawa o PCC","_warnings":["Przekazanie majątku JDG rodzinie — skutki w PIT, VAT i PCC"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
    object.get(input.document, "asset_transfer_active", false) == true
}
