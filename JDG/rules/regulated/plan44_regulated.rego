# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.regulated (Doc 44: P1970-P1977)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 8
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.regulated
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.regulated.no_match","package":"jdg.regulated","priority":99999}

# jdg.regulated.vat_exemption — P1970: Zwolnienia VAT dla zawodów regulowanych (lekarze, prawnicy)
decide :=   {"matched":true,"rule_id":"jdg.regulated.vat_exemption","package":"jdg.regulated","priority":1970,"vat_rate":"ZW","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"REGULATED","_routing":"","_routing_reason":"Zwolnienia VAT: lekarze (terapeutyczne), radcy/adwokaci (brak zwolnienia)","_legal_basis":"Art. 43 ust. 1 pkt 18-19 VAT","_warnings":["Zawody regulowane — lekarze zwolnieni z VAT, prawnicy opodatkowani 23%"]} {
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}

# jdg.regulated.kup_catalog — P1971: Specyficzne KUP: składki korporacyjne, OC, doskonalenie
else :=   {"matched":true,"rule_id":"jdg.regulated.kup_catalog","package":"jdg.regulated","priority":1971,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"KUP specyficzne: składki korporacyjne (KUP), OC zawodowe (KUP), doskonalenie","_legal_basis":"Art. 22-23 PIT","_warnings":["Zawody regulowane — składki korporacyjne i OC obowiązkowe są KUP"]} {
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}

# jdg.regulated.zus_obligations — P1972: ZUS dla zawodów regulowanych — brak ulgi na start
else :=   {"matched":true,"rule_id":"jdg.regulated.zus_obligations","package":"jdg.regulated","priority":1972,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"ZUS — brak ulgi na start gdy świadczenie dla byłego pracodawcy","_legal_basis":"Art. 18a SUS","_warnings":["Zawody regulowane — często brak ulgi na start (świadczenie usług dla byłego pracodawcy)"]} {
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}

# jdg.regulated.legal_privilege — P1973: Tajemnica zawodowa a obowiązki podatkowe
else :=   {"matched":true,"rule_id":"jdg.regulated.legal_privilege","package":"jdg.regulated","priority":1973,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Tajemnica adwokacka/radcowska — dokumenty wyłączone z kontroli","_legal_basis":"Art. 180 Ordynacji podatkowej","_warnings":["Dokumenty objęte tajemnicą adwokacką/radcowską — wyłączone z kontroli US"]} {
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}

# jdg.regulated.compulsory_membership — P1974: Obowiązkowe składki korporacyjne — KUP
else :=   {"matched":true,"rule_id":"jdg.regulated.compulsory_membership","package":"jdg.regulated","priority":1974,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Składki korporacyjne — adwokacka, radcowska, lekarska — KUP w dacie poniesienia","_legal_basis":"Art. 22 PIT","_warnings":["Składki korporacyjne — KUP w dacie poniesienia"]} {
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}

# jdg.regulated.cross_border_qualifications — P1975: Uznawanie kwalifikacji zagranicznych
else :=   {"matched":true,"rule_id":"jdg.regulated.cross_border_qualifications","package":"jdg.regulated","priority":1975,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zagraniczne kwalifikacje — wpływ na formę opodatkowania","_legal_basis":"Ustawa o zawodach regulowanych","_warnings":["Kwalifikacje zagraniczne — sprawdź czy są uznawane w PL dla celów podatkowych"]} {
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}

# jdg.regulated.public_office_interaction — P1976: Notariusz/komornik — ograniczenia JDG
else :=   {"matched":true,"rule_id":"jdg.regulated.public_office_interaction","package":"jdg.regulated","priority":1976,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Notariusz/komornik — ograniczenia w prowadzeniu JDG","_legal_basis":"Ustawa o notariacie, Ustawa o komornikach","_warnings":["Notariusz/komornik — ograniczenia w prowadzeniu dodatkowej JDG"]} {
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}

# jdg.regulated.healthcare_taxation — P1977: Zawody medyczne — zwolnienie VAT vs 23%, ryczałt 14%
else :=   {"matched":true,"rule_id":"jdg.regulated.healthcare_taxation","package":"jdg.regulated","priority":1977,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"0.14","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zawody medyczne — zwolnienie VAT (terapia) vs 23% (estetyczna), ryczałt PIT 14%","_legal_basis":"Art. 43 VAT, Art. 12 PIT","_warnings":["Medycyna — usługi terapeutyczne zwolnione z VAT, estetyczne opodatkowane 23%. Ryczałt 14%"]} {
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}
