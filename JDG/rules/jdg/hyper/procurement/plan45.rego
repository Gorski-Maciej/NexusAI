# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 21

package jdg.hyper.procurement

default decide := {"matched":false,"rule_id":"jdg.hyper.procurement.no_match","package":"jdg.hyper.procurement","priority":99999}

# jdg.hyper.procurement.family.cooperation.notification_to_zus_7days — ZUS
decide :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.cooperation.notification_to_zus_7days","package":"jdg.hyper.procurement","priority":1210,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zgłoszenie osoby współpracującej w 7 dni","_legal_basis":"Art. 36 ust. 14 SUS","_warnings":["Zgłoszenie osoby współpracującej w 7 dni"]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.cooperation.pit_treatment — PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.cooperation.pit_treatment","package":"jdg.hyper.procurement","priority":1211,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Wynagrodzenie osoby współpracującej jako KUP JDG","_legal_basis":"R1212","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.car.usage.mixed_75pct_kup — Samochód
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.car.usage.mixed_75pct_kup","package":"jdg.hyper.procurement","priority":1212,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Auto używane przez rodzinę → 75% KUP","_legal_basis":"Art. 23 ust. 1 pkt 46 PIT","_warnings":["Auto używane przez rodzinę → 75% KUP"]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.car.usage.mileage_log_family — Samochód
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.car.usage.mileage_log_family","package":"jdg.hyper.procurement","priority":1213,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Ewidencja przebiegu z rozróżnieniem na służbowe/prywatne","_legal_basis":"R1214","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.car.usage.vat_deduction_50pct — Samochód
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.car.usage.vat_deduction_50pct","package":"jdg.hyper.procurement","priority":1214,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"VAT od auta rodzinnego → 50%","_legal_basis":"Art. 86a VAT","_warnings":["VAT od auta rodzinnego → 50%"]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.asset.transfer.gift_to_spouse — Majątek
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.asset.transfer.gift_to_spouse","package":"jdg.hyper.procurement","priority":1215,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Darowizna dla małżonka → grupa 0, SD-Z2 w 6 mies.","_legal_basis":"Ustawa o SD, Art. 4a","_warnings":["Darowizna dla dzieci → grupa 0, SD-Z2 w 6 mies."]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.asset.transfer.gift_to_children — Majątek
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.asset.transfer.gift_to_children","package":"jdg.hyper.procurement","priority":1216,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Darowizna dla dzieci → grupa 0, SD-Z2 w 6 mies.","_legal_basis":"Ustawa o SD, Art. 4a","_warnings":["Darowizna dla dzieci → grupa 0, SD-Z2 w 6 mies."]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.asset.transfer.sale_arm_length — Majątek
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.asset.transfer.sale_arm_length","package":"jdg.hyper.procurement","priority":1217,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Sprzedaż majątku rodzinie → cena rynkowa (Art. 14 PIT)","_legal_basis":"Sprzedaż majątku rodzinie → cena rynkowa (Art. 14 PIT)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.asset.transfer.vat_opodatkowanie — Majątek
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.asset.transfer.vat_opodatkowanie","package":"jdg.hyper.procurement","priority":1218,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Sprzedaż majątku firmowego rodzinie → VAT naliczony","_legal_basis":"Art. 7 VAT","_warnings":["Sprzedaż majątku firmowego rodzinie → VAT naliczony"]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.asset.transfer.pcc_exemption — Majątek
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.asset.transfer.pcc_exemption","package":"jdg.hyper.procurement","priority":1219,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"PCC — zwolnienie w grupie 0 (małżonek, dzieci, rodzice)","_legal_basis":"R1220","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.joint_filing.conditions — PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.joint_filing.conditions","package":"jdg.hyper.procurement","priority":1220,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Wspólne rozliczenie: małżeństwo cały rok, wspólność majątkowa","_legal_basis": "Przepisy prawa podatkowego (LEGAL_REFERENCE_ACTS.md)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.joint_filing.benefit_calculation — PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.joint_filing.benefit_calculation","package":"jdg.hyper.procurement","priority":1221,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Korzyść: podwójny próg (240k), podwójna kwota wolna (60k)","_legal_basis":"R1222","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.joint_filing.deadline_april30 — PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.joint_filing.deadline_april30","package":"jdg.hyper.procurement","priority":1222,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Termin: 30 kwietnia (PIT-36 z adnotacją o wspólnym rozliczeniu)","_legal_basis": "Przepisy prawa podatkowego (LEGAL_REFERENCE_ACTS.md)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.joint_filing.exclusions — PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.joint_filing.exclusions","package":"jdg.hyper.procurement","priority":1223,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Wyłączenie: liniowy, ryczałt, karta → NIE wspólne","_legal_basis":"R1224","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.single_parent.preferential_calculation — PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.single_parent.preferential_calculation","package":"jdg.hyper.procurement","priority":1224,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Samotny rodzic: podwójna kwota wolna","_legal_basis": "Przepisy prawa podatkowego (LEGAL_REFERENCE_ACTS.md)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.single_parent.child_custody_required — PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.single_parent.child_custody_required","package":"jdg.hyper.procurement","priority":1225,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Wymagane: faktyczne sprawowanie opieki","_legal_basis":"R1226","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.health_insurance.family_members — Ubezpieczenie
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.health_insurance.family_members","package":"jdg.hyper.procurement","priority":1226,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zgłoszenie członków rodziny do ubezpieczenia zdrowotnego","_legal_basis": "Przepisy prawa podatkowego (LEGAL_REFERENCE_ACTS.md)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.health_insurance.kup_deduction — Ubezpieczenie
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.health_insurance.kup_deduction","package":"jdg.hyper.procurement","priority":1227,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Składka zdrowotna za członków rodziny NIE jest KUP","_legal_basis":"R1228","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.pit4r.obligation — Płatnik
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.pit4r.obligation","package":"jdg.hyper.procurement","priority":1228,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Obowiązek PIT-4R przy zatrudnieniu rodziny","_legal_basis": "Przepisy prawa podatkowego (LEGAL_REFERENCE_ACTS.md)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.pit11.deadline_feb28 — Płatnik
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.pit11.deadline_feb28","package":"jdg.hyper.procurement","priority":1229,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"PIT-11 dla członków rodziny do 28 lutego","_legal_basis":"R1230","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.succession.planning_inheritance — Sukcesja
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.succession.planning_inheritance","package":"jdg.hyper.procurement","priority":1230,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Przekazanie JDG w spadku → zwolnienie z podatku od spadków (grupa 0)","_legal_basis": "Przepisy prawa podatkowego (LEGAL_REFERENCE_ACTS.md)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}
