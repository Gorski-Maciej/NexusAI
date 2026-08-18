# Generated from Plan OPA 33 — Micro-rules for pcc
# 2026-07-13 14:58:41
# Rules: 59 (new, deduplicated)

package jdg.micro.pcc.plan33

default decide := {"matched":false,"rule_id":"jdg.micro.pcc.plan33.no_match","package":"jdg.micro.pcc.plan33","priority":99999}

# jdg.pcc.a1.r1 — `pcc_subject_loan`: Umowa pozyczki → 0.5%
decide :=   {"matched":true,"rule_id":"jdg.pcc.a1.r1","package":"jdg.micro.pcc.plan33","priority":4000,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa pozyczki","_legal_basis":"Art. 1 ust. 1 pkt 1 + Art. 7","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "expense_type", "") == "LOAN"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r10 — `pcc_subject_settlement_agreement`: Ugoda, porozumienie → 2%
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r10","package":"jdg.micro.pcc.plan33","priority":4001,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ugoda, porozumienie","_legal_basis":"Art. 1 ust. 1 pkt 3 + Art. 7","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r11 — `pcc_subject_gift`: Umowa darowizny (od osoby innej niż najbliższa rodzina) → PCC 2% (z progresją do 12%)
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r11","package":"jdg.micro.pcc.plan33","priority":4002,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa darowizny (od osoby innej niż najbliższa rodzina)","_legal_basis":"Art. 1 ust. 1 pkt 3 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r12 — `pcc_subject_establishment_of_mortgage`: Ustanowienie hipoteki (zabezpieczenie wierzytelności) → PCC 0.1% (od kwoty zabezpieczenia)
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r12","package":"jdg.micro.pcc.plan33","priority":4003,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ustanowienie hipoteki (zabezpieczenie wierzytelności)","_legal_basis":"Art. 1 ust. 1 pkt 4 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r13 — `pcc_subject_lease_sublease`: Umowa dzierżawy, najmu (jeśli poza VAT) → PCC 1%
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r13","package":"jdg.micro.pcc.plan33","priority":4004,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa dzierżawy, najmu (jeśli poza VAT)","_legal_basis":"Art. 1 ust. 1 pkt 5 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r14 — `pcc_subject_lifetime_maintenance`: Umowa dożywocia → PCC 2%
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r14","package":"jdg.micro.pcc.plan33","priority":4005,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa dożywocia","_legal_basis":"Art. 1 ust. 1 pkt 6 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r15 — `pcc_subject_partnership_agreement`: Umowa spółki cywilnej, jawnej (wkłady do spółki) → PCC 0.5% od wkładów
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r15","package":"jdg.micro.pcc.plan33","priority":4006,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa spółki cywilnej, jawnej (wkłady do spółki)","_legal_basis":"Art. 1 ust. 1 pkt 7 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r16 — `pcc_subject_change_of_partnership`: Zmiana umowy spółki (podwyższenie wkładów, dopłaty) → PCC 0.5%
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r16","package":"jdg.micro.pcc.plan33","priority":4007,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana umowy spółki (podwyższenie wkładów, dopłaty)","_legal_basis":"Art. 1 ust. 1 pkt 8 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r17 — `pcc_subject_annuity`: Ustanowienie odpłatnej renty → PCC 2%
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r17","package":"jdg.micro.pcc.plan33","priority":4008,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ustanowienie odpłatnej renty","_legal_basis":"Art. 1 ust. 1 pkt 9 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r18 — `pcc_subject_compensation_agreement`: Ugoda sądowa lub pozasądowa (odszkodowanie, zadośćuczynienie) → PCC 2%
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r18","package":"jdg.micro.pcc.plan33","priority":4009,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ugoda sądowa lub pozasądowa (odszkodowanie, zadośćuczynienie)","_legal_basis":"Art. 1 ust. 1 pkt 10 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r2 — `pcc_subject_credit`: Umowa kredytu → 0.5%
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r2","package":"jdg.micro.pcc.plan33","priority":4010,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa kredytu","_legal_basis":"Art. 1 ust. 1 pkt 1 + Art. 7","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r3 — `pcc_subject_sale_real_estate`: Umowa sprzedazy nieruchomosci → 2%
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r3","package":"jdg.micro.pcc.plan33","priority":4011,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa sprzedazy nieruchomosci","_legal_basis":"Art. 1 ust. 1 pkt 1 + Art. 7","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r4 — `pcc_subject_sale_movable`: Umowa sprzedazy ruchomosci (samochod, sprzet) → 2%
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r4","package":"jdg.micro.pcc.plan33","priority":4012,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa sprzedazy ruchomosci (samochod, sprzet)","_legal_basis":"Art. 1 ust. 1 pkt 1 + Art. 7","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r5 — `pcc_subject_exchange`: Umowa zamiany → 2% (od kazdej strony)
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r5","package":"jdg.micro.pcc.plan33","priority":4013,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa zamiany","_legal_basis":"Art. 1 ust. 1 pkt 2 + Art. 7","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r6 — `pcc_subject_company_formation`: Umowa spolki (akt zalozycielski) → 0.5%
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r6","package":"jdg.micro.pcc.plan33","priority":4014,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa spolki (akt zalozycielski)","_legal_basis":"Art. 1 ust. 1 pkt 2 + Art. 7","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r7 — `pcc_subject_company_increase_capital`:  → 0.5%
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r7","package":"jdg.micro.pcc.plan33","priority":4015,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"","_legal_basis":"Art. 1 ust. 1 pkt 2 + Art. 7","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r8 — `pcc_subject_lease_sublease`: Umowa dzierzawy, najmu (gdy poza VAT) → 1%
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r8","package":"jdg.micro.pcc.plan33","priority":4016,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa dzierzawy, najmu (gdy poza VAT)","_legal_basis":"Art. 1 ust. 1 pkt 2 + Art. 7","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a1.r9 — `pcc_subject_power_of_attorney`:  → 1% (od kazdego)
else :=   {"matched":true,"rule_id":"jdg.pcc.a1.r9","package":"jdg.micro.pcc.plan33","priority":4017,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"","_legal_basis":"Art. 1 ust. 1 pkt 2 + Art. 7","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a10.r1 — `pcc_duty_moment_sale`: Obowiązek PCC powstaje z chwilą dokonania czynności cywilnoprawnej → Moment zawarcia umowy
else :=   {"matched":true,"rule_id":"jdg.pcc.a10.r1","package":"jdg.micro.pcc.plan33","priority":4018,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiązek PCC powstaje z chwilą dokonania czynności cywilnoprawnej","_legal_basis":"Art. 10 ust. 1 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a10.r2 — `pcc_duty_moment_sale_condition`: Umowa pod warunkiem -> obowiązek z chwilą spełnienia warunku → Spełnienie warunku
else :=   {"matched":true,"rule_id":"jdg.pcc.a10.r2","package":"jdg.micro.pcc.plan33","priority":4019,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa pod warunkiem -> obowiązek z chwilą spełnienia warunku","_legal_basis":"Art. 10 ust. 2 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a10.r3 — `pcc_duty_moment_preliminary`: Umowa przedwstępna (jeśli przenosi własność przed zawarciem ostatecznej) → Data umowy przedwstępnej
else :=   {"matched":true,"rule_id":"jdg.pcc.a10.r3","package":"jdg.micro.pcc.plan33","priority":4020,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa przedwstępna (jeśli przenosi własność przed zawarciem ostatecznej)","_legal_basis":"Art. 10 ust. 3 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a10.r4 — `pcc_duty_moment_court_decision`: Orzeczenie sądu (zasiedzenie, zniesienie współwłasności) -> data uprawomocnienia → Data orzeczenia
else :=   {"matched":true,"rule_id":"jdg.pcc.a10.r4","package":"jdg.micro.pcc.plan33","priority":4021,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Orzeczenie sądu (zasiedzenie, zniesienie współwłasności) -> data uprawomocnienia","_legal_basis":"Art. 10 ust. 4 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a12.r1 — `pcc_declaration_deadline_14_days`: Deklaracja PCC-3 w 14 dni od powstania obowiązku podatkowego → 14 dni
else :=   {"matched":true,"rule_id":"jdg.pcc.a12.r1","package":"jdg.micro.pcc.plan33","priority":4022,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Deklaracja PCC-3 w 14 dni od powstania obowiązku podatkowego","_legal_basis":"Art. 12 ust. 1 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a12.r2 — `pcc_declaration_notary_obligation`: Akt notarialny: notariusz pobiera PCC i przekazuje do US (płatnik) → Obowiązek notariusza
else :=   {"matched":true,"rule_id":"jdg.pcc.a12.r2","package":"jdg.micro.pcc.plan33","priority":4023,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Akt notarialny: notariusz pobiera PCC i przekazuje do US (płatnik)","_legal_basis":"Art. 12 ust. 2 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a12.r3 — `pcc_declaration_electronic_obligation`: PCC-3 przez e-Deklaracje (podpis kwalifikowany lub profil zaufany) → Forma elektroniczna
else :=   {"matched":true,"rule_id":"jdg.pcc.a12.r3","package":"jdg.micro.pcc.plan33","priority":4024,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"PCC-3 przez e-Deklaracje (podpis kwalifikowany lub profil zaufany)","_legal_basis":"Art. 12 ust. 3 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a12.r4 — `pcc_payment_deadline_14_days`: Zapłata PCC w 14 dni od czynności (wraz z deklaracją) → Termin płatności
else :=   {"matched":true,"rule_id":"jdg.pcc.a12.r4","package":"jdg.micro.pcc.plan33","priority":4025,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zapłata PCC w 14 dni od czynności (wraz z deklaracją)","_legal_basis":"Art. 12 ust. 4 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a12.r5 — `pcc_correction_of_declaration`: Korekta PCC-3 w ciągu 5 lat (przedawnienie) → Korekta
else :=   {"matched":true,"rule_id":"jdg.pcc.a12.r5","package":"jdg.micro.pcc.plan33","priority":4026,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta PCC-3 w ciągu 5 lat (przedawnienie)","_legal_basis":"Art. 12 ust. 5 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a12.r6 — `pcc_late_payment_interest`: Po terminie -> odsetki za zwłokę (200% lombardowej NBP) → Odsetki
else :=   {"matched":true,"rule_id":"jdg.pcc.a12.r6","package":"jdg.micro.pcc.plan33","priority":4027,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Po terminie -> odsetki za zwłokę (200% lombardowej NBP)","_legal_basis":"Art. 12 ust. 6 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a2.r1 — `pcc_exemption_vat`: Czynnosc opodatkowana VAT -> zwolniona z PCC → Zwolnienie
else :=   {"matched":true,"rule_id":"jdg.pcc.a2.r1","package":"jdg.micro.pcc.plan33","priority":4028,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynnosc opodatkowana VAT -> zwolniona z PCC","_legal_basis":"Art. 2 pkt 4","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a2.r2 — `pcc_exemption_vat_exception_real_estate`: Nieruchomosci: zwolnienie z PCC tylko gdy VAT (jesli zwolniona z VAT -> PCC) → Wyjatek
else :=   {"matched":true,"rule_id":"jdg.pcc.a2.r2","package":"jdg.micro.pcc.plan33","priority":4029,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nieruchomosci: zwolnienie z PCC tylko gdy VAT (jesli zwolniona z VAT -> PCC)","_legal_basis":"Art. 2 pkt 4","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a2.r3 — `pcc_exemption_employment_contract`: Umowa o prace -> brak PCC → Zwolnienie
else :=   {"matched":true,"rule_id":"jdg.pcc.a2.r3","package":"jdg.micro.pcc.plan33","priority":4030,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowa o prace -> brak PCC","_legal_basis":"Art. 2 pkt 2","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a2.r4 — `pcc_exemption_sale_of_shares_on_stock_exchange`: Sprzedaz akcji na gieldzie -> brak PCC → Zwolnienie
else :=   {"matched":true,"rule_id":"jdg.pcc.a2.r4","package":"jdg.micro.pcc.plan33","priority":4031,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprzedaz akcji na gieldzie -> brak PCC","_legal_basis":"Art. 2 pkt 1","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a2.r5 — `pcc_exemption_loan_up_to_1000`:  → Zwolnienie
else :=   {"matched":true,"rule_id":"jdg.pcc.a2.r5","package":"jdg.micro.pcc.plan33","priority":4032,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"","_legal_basis":"Art. 2 pkt 1","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "expense_type", "") == "LOAN"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a2.r6 — `pcc_exemption_loan_from_family`:  → Zwolnienie
else :=   {"matched":true,"rule_id":"jdg.pcc.a2.r6","package":"jdg.micro.pcc.plan33","priority":4033,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"","_legal_basis":"Art. 9 pkt 10","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "expense_type", "") == "LOAN"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a2.r7 — `pcc_exemption_own_dwelling_first`: Zakup pierwszego mieszkania na rynku wtornym (do 100m2) → Zwolnienie
else :=   {"matched":true,"rule_id":"jdg.pcc.a2.r7","package":"jdg.micro.pcc.plan33","priority":4034,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zakup pierwszego mieszkania na rynku wtornym (do 100m2)","_legal_basis":"Art. 9 pkt 17","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a2.r8 — `pcc_exemption_own_dwelling_conditions`: Warunki: kupujacy <35 lat, wczesniej nie mial mieszkania → Warunki
else :=   {"matched":true,"rule_id":"jdg.pcc.a2.r8","package":"jdg.micro.pcc.plan33","priority":4035,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Warunki: kupujacy <35 lat, wczesniej nie mial mieszkania","_legal_basis":"Art. 9 pkt 17","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a3.r1 — `pcc_taxpayer_buyer`:  → Podmiot
else :=   {"matched":true,"rule_id":"jdg.pcc.a3.r1","package":"jdg.micro.pcc.plan33","priority":4036,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"","_legal_basis":"Art. 4","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a3.r2 — `pcc_taxpayer_both_for_exchange`:  → Obie strony
else :=   {"matched":true,"rule_id":"jdg.pcc.a3.r2","package":"jdg.micro.pcc.plan33","priority":4037,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"","_legal_basis":"Art. 4","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a4.r1 — `pcc_tax_base_purchase_price`:  → Podstawa
else :=   {"matched":true,"rule_id":"jdg.pcc.a4.r1","package":"jdg.micro.pcc.plan33","priority":4038,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"","_legal_basis":"Art. 6","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a4.r2 — `pcc_tax_base_loan_amount`:  → Podstawa
else :=   {"matched":true,"rule_id":"jdg.pcc.a4.r2","package":"jdg.micro.pcc.plan33","priority":4039,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"","_legal_basis":"Art. 6","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "expense_type", "") == "LOAN"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a5.r1 — `pcc_deadline_14_days`: Zaplata PCC w 14 dni od powstania obowiazku podatkowego → Termin
else :=   {"matched":true,"rule_id":"jdg.pcc.a5.r1","package":"jdg.micro.pcc.plan33","priority":4040,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaplata PCC w 14 dni od powstania obowiazku podatkowego","_legal_basis":"Art. 10","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a5.r2 — `pcc_declaration_PCC_3`: Deklaracja PCC-3 do US w terminie 14 dni → Deklaracja
else :=   {"matched":true,"rule_id":"jdg.pcc.a5.r2","package":"jdg.micro.pcc.plan33","priority":4041,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Deklaracja PCC-3 do US w terminie 14 dni","_legal_basis":"Art. 10","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a5.r3 — `pcc_notary_obligation_collection`: Notariusz pobiera PCC przy umowie notarialnej (przekazuje do US) → Notariusz
else :=   {"matched":true,"rule_id":"jdg.pcc.a5.r3","package":"jdg.micro.pcc.plan33","priority":4042,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Notariusz pobiera PCC przy umowie notarialnej (przekazuje do US)","_legal_basis":"Art. 10","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a5.r4 — `pcc_taxpayer_joint_obligation`: Przy umowie spółki: obowiązek solidarny wspólników → Solidarność
else :=   {"matched":true,"rule_id":"jdg.pcc.a5.r4","package":"jdg.micro.pcc.plan33","priority":4043,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przy umowie spółki: obowiązek solidarny wspólników","_legal_basis":"Art. 5 ust. 4 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a6.r1 — `pcc_base_sale_price`: Podstawa = wartość rynkowa rzeczy lub prawa (nie niższa niż cena) → Wartość rynkowa
else :=   {"matched":true,"rule_id":"jdg.pcc.a6.r1","package":"jdg.micro.pcc.plan33","priority":4044,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa = wartość rynkowa rzeczy lub prawa (nie niższa niż cena)","_legal_basis":"Art. 6 ust. 1 pkt 1 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a6.r2 — `pcc_base_loan_amount`: Podstawa = kwota pożyczki (kapitał) → Kwota pożyczki
else :=   {"matched":true,"rule_id":"jdg.pcc.a6.r2","package":"jdg.micro.pcc.plan33","priority":4045,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa = kwota pożyczki (kapitał)","_legal_basis":"Art. 6 ust. 1 pkt 2 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "expense_type", "") == "LOAN"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a6.r3 — `pcc_base_mortgage_amount`: Podstawa = kwota zabezpieczona hipoteką → Kwota hipoteki
else :=   {"matched":true,"rule_id":"jdg.pcc.a6.r3","package":"jdg.micro.pcc.plan33","priority":4046,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa = kwota zabezpieczona hipoteką","_legal_basis":"Art. 6 ust. 1 pkt 3 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a6.r4 — `pcc_base_lease_annual`: Podstawa = 10-krotność rocznego czynszu (przy dzierżawie na czas określony) → 10x czynszu
else :=   {"matched":true,"rule_id":"jdg.pcc.a6.r4","package":"jdg.micro.pcc.plan33","priority":4047,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podstawa = 10-krotność rocznego czynszu (przy dzierżawie na czas określony)","_legal_basis":"Art. 6 ust. 1 pkt 4 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a6.r5 — `pcc_base_lease_indefinite`: Dzierżawa na czas nieokreślony: 10-krotność czynszu rocznego → 10x czynszu
else :=   {"matched":true,"rule_id":"jdg.pcc.a6.r5","package":"jdg.micro.pcc.plan33","priority":4048,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dzierżawa na czas nieokreślony: 10-krotność czynszu rocznego","_legal_basis":"Art. 6 ust. 1 pkt 4 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a7.r1 — `pcc_rate_2_sale`: Stawka PCC dla umów sprzedaży nieruchomości i ruchomości → 2%
else :=   {"matched":true,"rule_id":"jdg.pcc.a7.r1","package":"jdg.micro.pcc.plan33","priority":4049,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawka PCC dla umów sprzedaży nieruchomości i ruchomości","_legal_basis":"Art. 7 ust. 1 pkt 1 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "category_code", "") == "REAL_ESTATE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a7.r2 — `pcc_rate_1_property_rights`: Stawka PCC dla sprzedaży praw majątkowych → 1%
else :=   {"matched":true,"rule_id":"jdg.pcc.a7.r2","package":"jdg.micro.pcc.plan33","priority":4050,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawka PCC dla sprzedaży praw majątkowych","_legal_basis":"Art. 7 ust. 1 pkt 2 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a7.r3 — `pcc_rate_0_5_loan`: Stawka PCC dla pożyczek → 0.5%
else :=   {"matched":true,"rule_id":"jdg.pcc.a7.r3","package":"jdg.micro.pcc.plan33","priority":4051,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawka PCC dla pożyczek","_legal_basis":"Art. 7 ust. 1 pkt 4 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "expense_type", "") == "LOAN"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a7.r4 — `pcc_rate_0_1_mortgage`: Stawka PCC dla hipotek → 0.1%
else :=   {"matched":true,"rule_id":"jdg.pcc.a7.r4","package":"jdg.micro.pcc.plan33","priority":4052,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawka PCC dla hipotek","_legal_basis":"Art. 7 ust. 1 pkt 5 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a7.r5 — `pcc_rate_1_lease`: Stawka PCC dla dzierżawy → 1%
else :=   {"matched":true,"rule_id":"jdg.pcc.a7.r5","package":"jdg.micro.pcc.plan33","priority":4053,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawka PCC dla dzierżawy","_legal_basis":"Art. 7 ust. 1 pkt 6 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a7.r6 — `pcc_rate_0_5_company`: Stawka PCC dla umowy spółki i zmiany → 0.5%
else :=   {"matched":true,"rule_id":"jdg.pcc.a7.r6","package":"jdg.micro.pcc.plan33","priority":4054,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawka PCC dla umowy spółki i zmiany","_legal_basis":"Art. 7 ust. 1 pkt 7 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a7.r7 — `pcc_rate_gift_progressive`: Darowizna: 2% od 10k-30k PLN, 4% od 30k-60k, 6% od 60k-150k, 12% powyżej 150k (I grupa) → Progresja
else :=   {"matched":true,"rule_id":"jdg.pcc.a7.r7","package":"jdg.micro.pcc.plan33","priority":4055,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Darowizna: 2% od 10k-30k PLN, 4% od 30k-60k, 6% od 60k-150k, 12% powyżej 150k (I grupa)","_legal_basis":"Art. 7 ust. 2 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a7.r8 — `pcc_rate_gift_group_ii`: Darowizna II grupa podatkowa: stawki podwojone → 4%, 8%, 12%, 24%
else :=   {"matched":true,"rule_id":"jdg.pcc.a7.r8","package":"jdg.micro.pcc.plan33","priority":4056,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Darowizna II grupa podatkowa: stawki podwojone","_legal_basis":"Art. 7 ust. 3 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a8.r1 — `pcc_exemption_own_housing_1st`: Pierwsze mieszkanie (od 2023): zwolnienie z PCC przy zakupie pierwszej nieruchomości → Zwolnienie do 100 000 PLN
else :=   {"matched":true,"rule_id":"jdg.pcc.a8.r1","package":"jdg.micro.pcc.plan33","priority":4057,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pierwsze mieszkanie (od 2023): zwolnienie z PCC przy zakupie pierwszej nieruchomości","_legal_basis":"Art. 8 pkt 1 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "category_code", "") == "REAL_ESTATE"; object.get(input.vendor, "is_company", true) == false
}

# jdg.pcc.a8.r2 — `pcc_exemption_own_housing_2nd_limit`: Drugie mieszkanie: zwolnienie tylko do 100 000 PLN (licząc 2% od nadwyżki) → Zwolnienie częściowe
else :=   {"matched":true,"rule_id":"jdg.pcc.a8.r2","package":"jdg.micro.pcc.plan33","priority":4058,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Drugie mieszkanie: zwolnienie tylko do 100 000 PLN (licząc 2% od nadwyżki)","_legal_basis":"Art. 8 pkt 2 ustawy o PCC","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.vendor, "is_company", true) == false
}
