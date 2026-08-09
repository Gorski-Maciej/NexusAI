# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 100

package jdg.hyper.general

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.hyper.general.no_match","package":"jdg.hyper.general","priority":99999}

# jdg.hyper.general.solidarity.levy.base.calculation — Podstawa
decide :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.base.calculation","package":"jdg.hyper.general","priority":1044,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Podstawa = suma_dochodów - 1_000_000 PLN","_legal_basis":"Art. 30h ust. 2 PIT","_warnings":["Podstawa daniny = suma dochodów - 1 000 000 PLN"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.rate.4pct — Stawka
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.rate.4pct","package":"jdg.hyper.general","priority":1045,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Stawka = 4% (0.04) od podstawy","_legal_basis":"Art. 30h ust. 1 PIT","_warnings":["Stawka daniny solidarnościowej = 4% od nadwyżki ponad 1M PLN"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.minimum.zero — Minimum
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.minimum.zero","package":"jdg.hyper.general","priority":1046,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Danina nie może być ujemna (nadwyżka ≥ 0)","_legal_basis":"Art. 30h ust. 2 PIT","_warnings":["Danina nie może być ujemna — minimum 0 PLN"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.income.scale — Źródło
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.income.scale","package":"jdg.hyper.general","priority":1047,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Dochód opodatkowany skalą PIT wlicza się do podstawy","_legal_basis":"Art. 30h ust. 2 PIT","_warnings":["Dochód opodatkowany skalą (12%/32%) wlicza się do podstawy daniny"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.income.linear — Źródło
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.income.linear","package":"jdg.hyper.general","priority":1048,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Dochód opodatkowany liniowo 19% wlicza się do podstawy","_legal_basis":"Art. 30h ust. 2 PIT","_warnings":["Dochód opodatkowany liniowo 19% wlicza się do podstawy daniny"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.income.lump_sum — Źródło
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.income.lump_sum","package":"jdg.hyper.general","priority":1049,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Przychód z ryczałtu wlicza się do podstawy (po odliczeniu składek)","_legal_basis":"Art. 30h ust. 2 PIT","_warnings":["Przychód z ryczałtu wlicza się do podstawy daniny (po odliczeniu składek)"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.payment.method.mandatory_transfer — Płatność
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.payment.method.mandatory_transfer","package":"jdg.hyper.general","priority":1061,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Obowiązek przelewu na mikrorachunek podatkowy","_legal_basis":"Art. 30h ust. 6 PIT, Art. 61b OP","_warnings":["Obowiązek przelewu na mikrorachunek podatkowy"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.sanction.late_payment — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.sanction.late_payment","package":"jdg.hyper.general","priority":1062,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Odsetki za zwłokę od niezapłaconej daniny","_legal_basis":"Art. 56 OP","_warnings":["Odsetki za zwłokę od niezapłaconej daniny solidarnościowej"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.sanction.underpayment_penalty — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.sanction.underpayment_penalty","package":"jdg.hyper.general","priority":1063,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Sankcja KKS przy celowym zaniżeniu podstawy","_legal_basis":"Art. 54 KKS, Art. 56 KKS","_warnings":["Sankcja KKS przy celowym zaniżeniu podstawy daniny"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.interaction.pit_free_amount — Interakcja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.interaction.pit_free_amount","package":"jdg.hyper.general","priority":1064,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Kwota wolna 30k NIE wpływa na obliczenie daniny","_legal_basis":"Art. 30h ust. 2 PIT","_warnings":["Kwota wolna 30k nie wpływa na obliczenie daniny"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.interaction.tax_scale — Interakcja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.interaction.tax_scale","package":"jdg.hyper.general","priority":1065,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Danina NIE wpływa na próg podatkowy 120k w skali","_legal_basis":"Art. 30h ust. 4 PIT","_warnings":["Danina nie wpływa na próg podatkowy 120k w skali"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.edge.first_year_1m — Edge case
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.edge.first_year_1m","package":"jdg.hyper.general","priority":1066,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Pierwszy rok z dochodem >1M — pełna danina od nadwyżki","_legal_basis":"Art. 30h ust. 2 PIT","_warnings":["Pierwszy rok z dochodem >1M — pełna danina od nadwyżki"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.edge.loss_reduction — Edge case
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.edge.loss_reduction","package":"jdg.hyper.general","priority":1067,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Strata z JDG pomniejsza dochód łączny","_legal_basis":"Art. 30h ust. 2 PIT, Art. 9 ust. 3 PIT","_warnings":["Strata z JDG pomniejsza dochód łączny dla celów daniny"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.edge.one_time_income — Edge case
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.edge.one_time_income","package":"jdg.hyper.general","priority":1068,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Jednorazowy dochód (sprzedaż nieruchomości firmowej) wlicza się","_legal_basis":"Art. 30h ust. 2 PIT","_warnings":["Jednorazowy dochód (np. sprzedaż nieruchomości firmowej) wlicza się"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.aggregate.annual_forecast — Agregacja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.aggregate.annual_forecast","package":"jdg.hyper.general","priority":1069,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Prognoza daniny na podstawie dochodów narastających","_legal_basis":"Art. 30h PIT","_warnings":["Prognoza daniny na podstawie dochodów narastających"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.wis.monitoring.expiry_alert_6months — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.wis.monitoring.expiry_alert_6months","package":"jdg.hyper.general","priority":1086,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Alert 6 miesięcy przed wygaśnięciem WIS","_legal_basis":"Art. 42h ust. 1 VAT","_warnings":["Monitoruj termin wygaśnięcia WIS — złóż wniosek o nową"]} if {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.general.wis.monitoring.expiry_alert_3months — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.wis.monitoring.expiry_alert_3months","package":"jdg.hyper.general","priority":1087,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Alert 3 miesiące przed wygaśnięciem WIS","_legal_basis":"Art. 42h ust. 1 VAT","_warnings":["Monitoruj termin wygaśnięcia WIS — złóż wniosek o nową"]} if {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.general.wis.monitoring.expiry_alert_1month — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.wis.monitoring.expiry_alert_1month","package":"jdg.hyper.general","priority":1088,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Alert 1 miesiąc przed wygaśnięciem WIS","_legal_basis":"Art. 42h ust. 1 VAT","_warnings":["Monitoruj termin wygaśnięcia WIS — złóż wniosek o nową"]} if {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.general.wis.binding_effect.dyrektor_kis — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.wis.binding_effect.dyrektor_kis","package":"jdg.hyper.general","priority":1089,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Wiąże Dyrektora KIS i organy podatkowe","_legal_basis":"Art. 42h ust. 1 VAT","_warnings":["WIS wiąże Dyrektora KIS i organy podatkowe"]} if {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.general.audit.trigger.return_to_correct — Wyzwalacz
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.trigger.return_to_correct","package":"jdg.hyper.general","priority":1111,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Wezwanie do korekty deklaracji (Art. 274 OP)","_legal_basis":"Art. 274 OP","_warnings":["Wezwanie do korekty deklaracji"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.trigger.inspection_warrant — Wyzwalacz
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.trigger.inspection_warrant","package":"jdg.hyper.general","priority":1112,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Kontrola na podstawie imiennego upoważnienia","_legal_basis":"Art. 282 OP","_warnings":["Kontrola na podstawie imiennego upoważnienia"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.trigger.external_information — Wyzwalacz
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.trigger.external_information","package":"jdg.hyper.general","priority":1113,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Informacja od innego organu → wszczęcie kontroli","_legal_basis":"Art. 282 OP","_warnings":["Informacja od innego organu → wszczęcie kontroli"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.right.notification_7_days — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.right.notification_7_days","package":"jdg.hyper.general","priority":1114,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zawiadomienie o kontroli min. 7 dni przed (Art. 282b OP)","_legal_basis":"Art. 282b OP","_warnings":["Zawiadomienie o kontroli min. 7 dni przed"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.right.no_notification_exceptions — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.right.no_notification_exceptions","package":"jdg.hyper.general","priority":1115,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Wyjątki od 7-dniowego zawiadomienia: przestępstwo, KAS, zabezpieczenie","_legal_basis":"Art. 282b § 2 OP","_warnings":["Wyjątki od 7-dniowego zawiadomienia: przestępstwo, KAS"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.right.presence_during_activities — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.right.presence_during_activities","package":"jdg.hyper.general","priority":1116,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Prawo do obecności przy wszystkich czynnościach","_legal_basis":"Art. 285 OP","_warnings":["Prawo do obecności przy wszystkich czynnościach kontrolnych"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.right.exclusion_of_inspector — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.right.exclusion_of_inspector","package":"jdg.hyper.general","priority":1117,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Wniosek o wyłączenie kontrolera (Art. 130 OP)","_legal_basis":"Art. 130 OP","_warnings":["Wniosek o wyłączenie kontrolera"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.right.refuse_self_incrimination — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.right.refuse_self_incrimination","package":"jdg.hyper.general","priority":1118,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Odmowa odpowiedzi grożącej odpowiedzialnością KKS (Art. 199 OP)","_legal_basis":"Art. 199 OP","_warnings":["Odmowa odpowiedzi grożącej odpowiedzialnością KKS"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.right.object_to_protocol — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.right.object_to_protocol","package":"jdg.hyper.general","priority":1119,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zastrzeżenia do protokołu w ciągu 14 dni (Art. 291 OP)","_legal_basis":"Art. 291 OP","_warnings":["Zastrzeżenia do protokołu w ciągu 14 dni"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.document.electronic_evidence — Dokumenty
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.document.electronic_evidence","package":"jdg.hyper.general","priority":1141,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Dowody elektroniczne: autentyczność + integralność (Art. 193a OP)","_legal_basis":"Art. 193a OP","_warnings":["Dowody elektroniczne: autentyczność + integralność"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.document.foreign_language — Dokumenty
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.document.foreign_language","package":"jdg.hyper.general","priority":1142,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Dokumenty obcojęzyczne → tłumaczenie przysięgłe na żądanie (Art. 180a OP)","_legal_basis":"Art. 180a OP","_warnings":["Dokumenty obcojęzyczne → tłumaczenie przysięgłe na żądanie"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.protocol.deadline_14_days_after_end — Protokół
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.protocol.deadline_14_days_after_end","package":"jdg.hyper.general","priority":1143,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Protokół sporządzany w ciągu 14 dni od zakończenia kontroli","_legal_basis":"Art. 291 OP","_warnings":["Protokół sporządzany w ciągu 14 dni od zakończenia kontroli"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.protocol.required_elements — Protokół
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.protocol.required_elements","package":"jdg.hyper.general","priority":1144,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Data, oznaczenie organu, podstawa, ustalenia, pouczenie o prawach","_legal_basis":"Art. 291 § 3 OP","_warnings":["Data, oznaczenie organu, podstawa, ustalenia, pouczenie"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.protocol.objections_period — Protokół
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.protocol.objections_period","package":"jdg.hyper.general","priority":1145,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"14 dni na zastrzeżenia od podpisania protokołu","_legal_basis":"Art. 291 § 1 OP","_warnings":["14 dni na zastrzeżenia od podpisania protokołu"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.protocol.objections_to_director — Protokół
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.protocol.objections_to_director","package":"jdg.hyper.general","priority":1146,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zastrzeżenia rozpatruje bezpośredni przełożony kontrolera","_legal_basis":"Art. 291 § 2 OP","_warnings":["Zastrzeżenia rozpatruje bezpośredni przełożony kontrolera"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.protocol.electronic_service — Protokół
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.protocol.electronic_service","package":"jdg.hyper.general","priority":1147,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Protokół doręczany przez e-US z UPO","_legal_basis":"Art. 144b OP","_warnings":["Protokół doręczany przez e-US z UPO"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.representation.poa_pps1 — Pełnomocnik
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.representation.poa_pps1","package":"jdg.hyper.general","priority":1148,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Pełnomocnik ogólny PPS-1 może reprezentować podczas kontroli","_legal_basis":"Art. 138a-138o OP","_warnings":["Pełnomocnik ogólny PPS-1 może reprezentować podczas kontroli"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.representation.poa_upl1 — Pełnomocnik
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.representation.poa_upl1","package":"jdg.hyper.general","priority":1149,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Pełnomocnik szczególny UPL-1 tylko do wskazanej sprawy","_legal_basis":"Art. 138a-138o OP","_warnings":["Pełnomocnik szczególny UPL-1 tylko do wskazanej sprawy"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.force_majeure.relief.deadline_extension — Ulga podatkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.relief.deadline_extension","package":"jdg.hyper.general","priority":1171,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Przedłużenie terminu złożenia deklaracji","_legal_basis":"Art. 67a § 1 OP","_warnings":["Przedłużenie terminu złożenia deklaracji"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.relief.application_immediate — Procedura
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.relief.application_immediate","package":"jdg.hyper.general","priority":1172,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Wniosek składany niezwłocznie po zdarzeniu","_legal_basis":"Art. 67b OP","_warnings":["Wniosek składany niezwłocznie po zdarzeniu"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.relief.interest_suspension — Ulga
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.relief.interest_suspension","package":"jdg.hyper.general","priority":1173,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zawieszenie naliczania odsetek na czas rozpatrywania wniosku","_legal_basis":"Art. 67a § 1 OP","_warnings":["Zawieszenie naliczania odsetek na czas rozpatrywania wniosku"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.relief.zus_deferral — Ulga ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.relief.zus_deferral","package":"jdg.hyper.general","priority":1174,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Odroczenie terminu płatności składek ZUS (Art. 28 SUS)","_legal_basis":"Art. 28 SUS","_warnings":["Odroczenie terminu płatności składek ZUS"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.relief.zus_installments — Ulga ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.relief.zus_installments","package":"jdg.hyper.general","priority":1175,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Układ ratalny w ZUS (Art. 29 SUS)","_legal_basis":"Art. 29 SUS","_warnings":["Układ ratalny w ZUS"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.relief.zus_remission — Ulga ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.relief.zus_remission","package":"jdg.hyper.general","priority":1176,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Umorzenie składek ZUS (szczególne przypadki)","_legal_basis":"Art. 29 SUS","_warnings":["Umorzenie składek ZUS (szczególne przypadki)"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.relief.zus_contribution_suspension — Ulga ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.relief.zus_contribution_suspension","package":"jdg.hyper.general","priority":1177,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zawieszenie obowiązku opłacania składek na czas zdarzenia","_legal_basis":"Art. 18a SUS","_warnings":["Zawieszenie obowiązku opłacania składek na czas zdarzenia"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.documents.loss_reporting — Dokumenty
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.documents.loss_reporting","package":"jdg.hyper.general","priority":1178,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Obowiązek zgłoszenia utraty dokumentów w 7 dni (Art. 86 § 2 OP)","_legal_basis":"Art. 86 § 2 OP","_warnings":["Obowiązek zgłoszenia utraty dokumentów w 7 dni"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.documents.reconstruction_procedure — Dokumenty
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.documents.reconstruction_procedure","package":"jdg.hyper.general","priority":1179,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Procedura odtworzenia zniszczonej dokumentacji","_legal_basis":"Art. 86 § 2 OP","_warnings":["Procedura odtworzenia zniszczonej dokumentacji"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.family.spouse.contract_type.b2b — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.spouse.contract_type.b2b","package":"jdg.hyper.general","priority":1201,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Umowa B2B z małżonkiem → osobna JDG, ZUS własny","_legal_basis":"Art. 23 ust. 1 pkt 10 PIT","_warnings":["Umowa B2B z małżonkiem → osobna JDG, ZUS własny"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.spouse.contract_type.mandate — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.spouse.contract_type.mandate","package":"jdg.hyper.general","priority":1202,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Umowa zlecenie z małżonkiem → ZUS od zlecenia","_legal_basis":"Art. 23 ust. 1 pkt 10 PIT","_warnings":["Umowa zlecenie z małżonkiem → ZUS od zlecenia"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.children.employment.under_26 — Dzieci
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.children.employment.under_26","package":"jdg.hyper.general","priority":1203,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zatrudnienie dziecka <26 lat → podwyższone ryzyko kontroli","_legal_basis":"Art. 23 ust. 1 pkt 10 PIT","_warnings":["Zatrudnienie dziecka <26 lat → podwyższone ryzyko kontroli"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.children.work_evidence_required — Dzieci
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.children.work_evidence_required","package":"jdg.hyper.general","priority":1204,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Rzeczywiste wykonywanie pracy przez dziecko","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Rzeczywiste wykonywanie pracy przez dziecko — dokumentuj"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.children.salary_arm_length — Dzieci
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.children.salary_arm_length","package":"jdg.hyper.general","priority":1205,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Wynagrodzenie rynkowe (nie zawyżone)","_legal_basis":"Art. 22 ust. 1 PIT, Art. 23zf PIT","_warnings":["Wynagrodzenie rynkowe (nie zawyżone) — zasada ceny rynkowej"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.children.pit_ulga_young_interaction — Dzieci
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.children.pit_ulga_young_interaction","package":"jdg.hyper.general","priority":1206,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Interakcja: pensja dziecka + ulga dla młodych (do 85 528 PLN)","_legal_basis":"Art. 21 ust. 1 pkt 148 PIT","_warnings":["Interakcja: pensja dziecka + ulga dla młodych (do 85 528 PLN)"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.children.university_compatibility — Dzieci
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.children.university_compatibility","package":"jdg.hyper.general","priority":1207,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Praca musi być kompatybilna ze studiami","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Praca musi być kompatybilna ze studiami"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.cooperation.zus_person — ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.cooperation.zus_person","package":"jdg.hyper.general","priority":1208,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Osoba współpracująca → składki ZUS jak za przedsiębiorcę","_legal_basis":"Art. 8 ust. 2 SUS","_warnings":["Osoba współpracująca → składki ZUS jak za przedsiębiorcę"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.cooperation.zus_health — ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.cooperation.zus_health","package":"jdg.hyper.general","priority":1209,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Osoba współpracująca → składka zdrowotna 9%","_legal_basis":"Art. 81 ustawy zdrowotnej","_warnings":["Osoba współpracująca → składka zdrowotna 9%"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.succession.sd_z2_deadline_6months — Sukcesja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.succession.sd_z2_deadline_6months","package":"jdg.hyper.general","priority":1231,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zgłoszenie SD-Z2 w ciągu 6 miesięcy od śmierci/nabycia","_legal_basis":"Ustawa o SD, Art. 4a","_warnings":["Zgłoszenie SD-Z2 w ciągu 6 miesięcy od śmierci/nabycia"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.succession.business_continuity — Sukcesja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.succession.business_continuity","package":"jdg.hyper.general","priority":1232,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Ciągłość JDG po śmierci: zarządca sukcesyjny","_legal_basis":"Art. 12-13 ustawy o zarządzie sukcesyjnym","_warnings":["Ciągłość JDG po śmierci: zarządca sukcesyjny"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""; object.get(input.jdg_entrepreneur, "business_status", "") == "IN_SUCCESSIO"
}

# jdg.hyper.general.family.multi_generation.tax_planning — Planowanie
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.multi_generation.tax_planning","package":"jdg.hyper.general","priority":1233,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Optymalizacja podatkowa poprzez zatrudnienie w różnych pokoleniach","_legal_basis":"Art. 22-23 PIT","_warnings":["Optymalizacja podatkowa poprzez zatrudnienie w różnych pokoleniach"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.aggregate.risk_assessment — Agregacja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.aggregate.risk_assessment","package":"jdg.hyper.general","priority":1234,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Łączna ocena ryzyka podatkowego transakcji rodzinnych","_legal_basis":"Art. 119b OP","_warnings":["Łączna ocena ryzyka podatkowego transakcji rodzinnych"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""; object.get(input.vendor, "risk_flag", false) == true
}

# jdg.hyper.general.edelivery.registration.mandatory — Obowiązek
else :=   {"matched":true,"rule_id":"jdg.hyper.general.edelivery.registration.mandatory","package":"jdg.hyper.general","priority":1235,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Rejestracja adresu e-Doręczeń w BAE (od 01.01.2025 dla JDG)","_legal_basis":"Ustawa o doręczeniach elektronicznych, Art. 5","_warnings":["Rejestracja adresu e-Doręczeń w BAE (od 2025 dla JDG)"]} if {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.general.edelivery.registration.deadline_by_entity_type — Obowiązek
else :=   {"matched":true,"rule_id":"jdg.hyper.general.edelivery.registration.deadline_by_entity_type","package":"jdg.hyper.general","priority":1236,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Termin rejestracji zależny od typu podmiotu","_legal_basis":"Ustawa o doręczeniach elektronicznych","_warnings":["Termin rejestracji zależny od typu podmiotu"]} if {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.general.edelivery.fiction.delivery_14_days — Fikcja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.edelivery.fiction.delivery_14_days","package":"jdg.hyper.general","priority":1237,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Pismo nieodebrane → uznane za doręczone po 14 dniach","_legal_basis":"Art. 144b OP","_warnings":["Pismo nieodebrane → uznane za doręczone po 14 dniach"]} if {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.general.edelivery.fiction.consequences_legal — Fikcja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.edelivery.fiction.consequences_legal","package":"jdg.hyper.general","priority":1238,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Konsekwencje: bieg terminów odwoławczych od daty fikcji","_legal_basis":"Art. 144b OP","_warnings":["Konsekwencje: bieg terminów odwoławczych od daty fikcji"]} if {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.general.edelivery.fiction.critical_alert — Fikcja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.edelivery.fiction.critical_alert","package":"jdg.hyper.general","priority":1239,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Alert CRITICAL przy zbliżającej się fikcji doręczenia","_legal_basis":"Art. 144b OP","_warnings":["Alert CRITICAL przy zbliżającej się fikcji doręczenia"]} if {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.general.cross_border.eidas.recognition — Transgraniczne
else :=   {"matched":true,"rule_id":"jdg.hyper.general.cross_border.eidas.recognition","package":"jdg.hyper.general","priority":1261,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Uznawanie podpisów elektronicznych z UE (eIDAS)","_legal_basis":"Rozp. eIDAS 910/2014","_warnings":["Uznawanie podpisów elektronicznych z UE (eIDAS)"]} if {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.hyper.general.cross_border.crs.fatca.reporting — Transgraniczne
else :=   {"matched":true,"rule_id":"jdg.hyper.general.cross_border.crs.fatca.reporting","package":"jdg.hyper.general","priority":1262,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Automatyczna wymiana informacji CRS/FATCA","_legal_basis":"Ustawa o wymianie informacji podatkowych","_warnings":["Automatyczna wymiana informacji CRS/FATCA"]} if {
    object.get(input.vendor, "country", "") in {"NON_EU"}
}

# jdg.hyper.general.cross_border.dac.directives.compliance — Transgraniczne
else :=   {"matched":true,"rule_id":"jdg.hyper.general.cross_border.dac.directives.compliance","package":"jdg.hyper.general","priority":1263,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zgodność z dyrektywami DAC (DAC1-DAC8)","_legal_basis":"Dyrektywy DAC1-DAC8","_warnings":["Zgodność z dyrektywami DAC"]} if {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.hyper.general.communication.calendar.deadlines_integration — Kalendarz
else :=   {"matched":true,"rule_id":"jdg.hyper.general.communication.calendar.deadlines_integration","package":"jdg.hyper.general","priority":1264,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Integracja terminów komunikacyjnych z kalendarzem płatności","_legal_basis":"Art. 144b OP","_warnings":["Integracja terminów komunikacyjnych z kalendarzem płatności"]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.general.communication.offline.backup_procedure — Awaria
else :=   {"matched":true,"rule_id":"jdg.hyper.general.communication.offline.backup_procedure","package":"jdg.hyper.general","priority":1265,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Procedura na wypadek awarii systemów e-US","_legal_basis":"Art. 144b OP","_warnings":["Procedura na wypadek awarii systemów e-US"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.communication.offline.paper_allowed_when — Awaria
else :=   {"matched":true,"rule_id":"jdg.hyper.general.communication.offline.paper_allowed_when","package":"jdg.hyper.general","priority":1266,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Kiedy dozwolona forma papierowa","_legal_basis":"Art. 144 OP","_warnings":["Kiedy dozwolona forma papierowa"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.communication.language.polish_required — Język
else :=   {"matched":true,"rule_id":"jdg.hyper.general.communication.language.polish_required","package":"jdg.hyper.general","priority":1267,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Obowiązek komunikacji w języku polskim","_legal_basis":"Art. 4 ustawy o języku polskim","_warnings":["Obowiązek komunikacji w języku polskim"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.communication.language.foreign_documents_translation — Język
else :=   {"matched":true,"rule_id":"jdg.hyper.general.communication.language.foreign_documents_translation","package":"jdg.hyper.general","priority":1268,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Tłumaczenie przysięgłe dokumentów obcojęzycznych","_legal_basis":"Art. 180a OP","_warnings":["Tłumaczenie przysięgłe dokumentów obcojęzycznych"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.communication.aggregate.status_dashboard — Agregacja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.communication.aggregate.status_dashboard","package":"jdg.hyper.general","priority":1269,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Dashboard statusu komunikacji z organami","_legal_basis":"Art. 138e-138i OP","_warnings":["Dashboard statusu komunikacji z organami — monitoruj terminy doręczeń elektronicznych"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.kks.conviction.bank_account_termination — Bank może wypowiedzieć umowę rachunku
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.bank_account_termination","package":"jdg.hyper.general","priority":1551,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true` AND `conviction_related_to_financial_crime == true`","_legal_basis":"Art. 56 Prawa bankowego + AML","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.kks.conviction.credit_score_impact — Wpływ na zdolność kredytową
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.credit_score_impact","package":"jdg.hyper.general","priority":1552,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true` AND `conviction_not_spent == true`","_legal_basis":"BIK, praktyka bankowa","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.kks.conviction.enhanced_aml_kyc — Wzmocniona weryfikacja AML/KYC
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.enhanced_aml_kyc","package":"jdg.hyper.general","priority":1553,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true`","_legal_basis":"Art. 43 AML","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.kks.conviction.fintech_access_restriction — Ograniczenia w dostępie do fintechów
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.fintech_access_restriction","package":"jdg.hyper.general","priority":1554,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true`","_legal_basis":"Polityki fintechów","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.kks.conviction.cash_transaction_monitoring — Monitoring transakcji gotówkowych
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.cash_transaction_monitoring","package":"jdg.hyper.general","priority":1555,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true`","_legal_basis":"GIIF","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.kks.conviction.tax_office_scrutiny_increased — Zaostrzony nadzór US po skazaniu
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.tax_office_scrutiny_increased","package":"jdg.hyper.general","priority":1556,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true` AND `conviction_not_spent == true`","_legal_basis":"Praktyka US","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.kks.conviction.risk_profile_reclassification — Przeklasyfikowanie profilu ryzyka na HIGH
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.risk_profile_reclassification","package":"jdg.hyper.general","priority":1557,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true`","_legal_basis":"Art. 119b OP","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true; object.get(input.vendor, "risk_flag", false) == true
}

# jdg.hyper.general.kks.conviction.public_warning_list_art119b — Wpis na listę ostrzeżeń publicznych MF
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.public_warning_list_art119b","package":"jdg.hyper.general","priority":1558,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true` AND `tax_arrears > threshold`","_legal_basis":"Art. 119b OP","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.kks.conviction.statute_interruption — Przerwanie biegu przedawnienia przez skazanie
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.statute_interruption","package":"jdg.hyper.general","priority":1559,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true`","_legal_basis":"Art. 70 § 4 OP","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.regulated.cross_border.eu_qualifications_recognition — Uznawanie kwalifikacji UE w PL
else :=   {"matched":true,"rule_id":"jdg.hyper.general.regulated.cross_border.eu_qualifications_recognition","package":"jdg.hyper.general","priority":1601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`qualification_origin in EU` AND `regulated_profession == true`","_legal_basis":"Dyrektywa 2005/36/WE","_warnings":[]} if {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.hyper.general.regulated.cross_border.non_eu_qualifications — Uznawanie kwalifikacji spoza UE — procedura nostryfikacji
else :=   {"matched":true,"rule_id":"jdg.hyper.general.regulated.cross_border.non_eu_qualifications","package":"jdg.hyper.general","priority":1602,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`qualification_origin in NON_EU` AND `regulated_profession == true`","_legal_basis":"Ustawy branżowe","_warnings":[]} if {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.hyper.general.regulated.cross_border.temporary_services_eu — Tymczasowe świadczenie usług w UE — uznanie kwalifikacji
else :=   {"matched":true,"rule_id":"jdg.hyper.general.regulated.cross_border.temporary_services_eu","package":"jdg.hyper.general","priority":1603,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`service_temporary == true` AND `host_country in EU`","_legal_basis":"Dyrektywa 2005/36/WE","_warnings":[]} if {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.hyper.general.regulated.cross_border.double_taxation_specialist — Podwójne opodatkowanie specjalisty transgranicznego
else :=   {"matched":true,"rule_id":"jdg.hyper.general.regulated.cross_border.double_taxation_specialist","package":"jdg.hyper.general","priority":1604,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`works_in_two_countries == true` AND `regulated_profession == true`","_legal_basis":"Umowy UPO","_warnings":[]} if {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.hyper.general.regulated.cross_border.vat_registration_abroad — Obowiązek rejestracji VAT za granicą przy usługach B2C
else :=   {"matched":true,"rule_id":"jdg.hyper.general.regulated.cross_border.vat_registration_abroad","package":"jdg.hyper.general","priority":1605,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`regulated_profession == true` AND `b2c_services_to_eu == true`","_legal_basis":"Art. 28k VAT, OSS","_warnings":[]} if {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.hyper.general.regulated.aggregate.profession_specific_risk_profile — Profil ryzyka specyficzny dla zawodu regulowanego
else :=   {"matched":true,"rule_id":"jdg.hyper.general.regulated.aggregate.profession_specific_risk_profile","package":"jdg.hyper.general","priority":1606,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`regulated_profession == true`","_legal_basis":"—","_warnings":[]} if {
    object.get(input.vendor, "risk_flag", false) == true
}

# jdg.hyper.general.regulated.aggregate.annual_compliance_checklist — Checklista roczna dla zawodu regulowanego
else :=   {"matched":true,"rule_id":"jdg.hyper.general.regulated.aggregate.annual_compliance_checklist","package":"jdg.hyper.general","priority":1607,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`regulated_profession == true` AND `year_end == true`","_legal_basis":"—","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.insurance.mandatory.detection_legal — OC prawników — obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.hyper.general.insurance.mandatory.detection_legal","package":"jdg.hyper.general","priority":1608,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`pkd_main ⊆ [\"69.10.Z\"]`","_legal_basis":"Rozp. MS ws. OC adwokatów/radców","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.insurance.mandatory.detection_medical — OC lekarzy — obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.hyper.general.insurance.mandatory.detection_medical","package":"jdg.hyper.general","priority":1609,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`pkd_main ⊆ [\"86.21.Z\",\"86.22.Z\"]`","_legal_basis":"Ustawa o zawodzie lekarza","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.installments.pit_revenue_per_installment — Sprzedaż na raty — przychód PIT w dacie każdej raty
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.installments.pit_revenue_per_installment","package":"jdg.hyper.general","priority":1651,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"INSTALLMENTS\"`","_legal_basis":"Art. 14 PIT","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.installments.vat_accrual_full_immediately — VAT memoriałowy — obowiązek od całości w dacie dostawy, niezależnie od rat
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.installments.vat_accrual_full_immediately","package":"jdg.hyper.general","priority":1652,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"INSTALLMENTS\"` AND `vat_method == \"ACCRUAL\"`","_legal_basis":"Art. 19a VAT","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.installments.vat_cash_per_installment — VAT kasowy — obowiązek w dacie każdej raty
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.installments.vat_cash_per_installment","package":"jdg.hyper.general","priority":1653,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"INSTALLMENTS\"` AND `vat_method == \"CASH\"`","_legal_basis":"Art. 21 VAT","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.installments.late_payment_interest — Opóźnienie raty → odsetki od zaległości
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.installments.late_payment_interest","package":"jdg.hyper.general","priority":1654,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`installment_overdue == true`","_legal_basis":"Art. 56 OP","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.installments.contract_termination_consequences — Zerwanie umowy ratalnej — skutki podatkowe (korekta przychodu/VAT)
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.installments.contract_termination_consequences","package":"jdg.hyper.general","priority":1655,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`contract_terminated == true`","_legal_basis":"Art. 106j VAT","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.advance.vat_obligation_on_receipt — Zaliczka — obowiązek VAT w dacie otrzymania (nawet przed dostawą)
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.advance.vat_obligation_on_receipt","package":"jdg.hyper.general","priority":1656,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_type == \"ADVANCE\"` AND `vat_method == \"ACCRUAL\"`","_legal_basis":"Art. 19a ust. 8 VAT","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.advance.vat_invoice_required_15days — Faktura zaliczkowa w ciągu 15 dni od otrzymania zaliczki
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.advance.vat_invoice_required_15days","package":"jdg.hyper.general","priority":1657,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_type == \"ADVANCE\"` AND `advance_invoice_issued == false`","_legal_basis":"Art. 106i VAT","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.advance.pit_revenue_on_receipt — Zaliczka — przychód PIT w dacie otrzymania
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.advance.pit_revenue_on_receipt","package":"jdg.hyper.general","priority":1658,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_type == \"ADVANCE\"`","_legal_basis":"Art. 14 PIT","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.advance.advance_not_refunded_taxable — Niezwrócona zaliczka przy zerwaniu umowy — opodatkowana
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.advance.advance_not_refunded_taxable","package":"jdg.hyper.general","priority":1659,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`advance_retained == true` AND `contract_cancelled == true`","_legal_basis":"Art. 14 PIT","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}
