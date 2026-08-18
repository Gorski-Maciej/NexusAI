# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 100

package jdg.hyper.general

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.hyper.general.no_match","package":"jdg.hyper.general","priority":99999}

# jdg.hyper.general.solidarity.levy.base.calculation — Podstawa
decide :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.base.calculation","_legal_basis":"Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Podstawa daniny = suma dochodów - 1 000 000 PLN"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.rate.4pct — Stawka
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.rate.4pct","_legal_basis":"Art. 30h ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Stawka daniny solidarnościowej = 4% od nadwyżki ponad 1M PLN"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.minimum.zero — Minimum
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.minimum.zero","_legal_basis":"Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Danina nie może być ujemna — minimum 0 PLN"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.income.scale — Źródło
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.income.scale","_legal_basis":"Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Dochód opodatkowany skalą (12%/32%) wlicza się do podstawy daniny"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.income.linear — Źródło
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.income.linear","_legal_basis":"Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Dochód opodatkowany liniowo 19% wlicza się do podstawy daniny"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.income.lump_sum — Źródło
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.income.lump_sum","_legal_basis":"Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Przychód z ryczałtu wlicza się do podstawy daniny (po odliczeniu składek)"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.payment.method.mandatory_transfer — Płatność
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.payment.method.mandatory_transfer","_legal_basis":"Art. 30h ust. 6 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.), Art. 61b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Obowiązek przelewu na mikrorachunek podatkowy"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.sanction.late_payment — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.sanction.late_payment","_legal_basis":"Art. 56 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Odsetki za zwłokę od niezapłaconej daniny solidarnościowej"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.sanction.underpayment_penalty — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.sanction.underpayment_penalty","_legal_basis":"Art. 54 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.), Art. 56 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Sankcja KKS przy celowym zaniżeniu podstawy daniny"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.interaction.pit_free_amount — Interakcja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.interaction.pit_free_amount","_legal_basis":"Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Kwota wolna 30k nie wpływa na obliczenie daniny"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.interaction.tax_scale — Interakcja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.interaction.tax_scale","_legal_basis":"Art. 30h ust. 4 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Danina nie wpływa na próg podatkowy 120k w skali"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.edge.first_year_1m — Edge case
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.edge.first_year_1m","_legal_basis":"Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Pierwszy rok z dochodem >1M — pełna danina od nadwyżki"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.edge.loss_reduction — Edge case
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.edge.loss_reduction","_legal_basis":"Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.), Art. 9 ust. 3 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Strata z JDG pomniejsza dochód łączny dla celów daniny"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.edge.one_time_income — Edge case
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.edge.one_time_income","_legal_basis":"Art. 30h ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Jednorazowy dochód (np. sprzedaż nieruchomości firmowej) wlicza się"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.solidarity.levy.aggregate.annual_forecast — Agregacja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.solidarity.levy.aggregate.annual_forecast","_legal_basis":"Art. 30h ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Prognoza daniny na podstawie dochodów narastających"]} if {
    object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000
}

# jdg.hyper.general.wis.monitoring.expiry_alert_6months — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.wis.monitoring.expiry_alert_6months","_legal_basis":"Art. 42h ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Monitoruj termin wygaśnięcia WIS — złóż wniosek o nową"]} if {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.general.wis.monitoring.expiry_alert_3months — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.wis.monitoring.expiry_alert_3months","_legal_basis":"Art. 42h ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Monitoruj termin wygaśnięcia WIS — złóż wniosek o nową"]} if {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.general.wis.monitoring.expiry_alert_1month — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.wis.monitoring.expiry_alert_1month","_legal_basis":"Art. 42h ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Monitoruj termin wygaśnięcia WIS — złóż wniosek o nową"]} if {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.general.wis.binding_effect.dyrektor_kis — WIS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.wis.binding_effect.dyrektor_kis","_legal_basis":"Art. 42h ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["WIS wiąże Dyrektora KIS i organy podatkowe"]} if {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.hyper.general.audit.trigger.return_to_correct — Wyzwalacz
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.trigger.return_to_correct","_legal_basis":"Art. 274 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Wezwanie do korekty deklaracji"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.trigger.inspection_warrant — Wyzwalacz
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.trigger.inspection_warrant","_legal_basis":"Art. 282 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Kontrola na podstawie imiennego upoważnienia"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.trigger.external_information — Wyzwalacz
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.trigger.external_information","_legal_basis":"Art. 282 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Informacja od innego organu → wszczęcie kontroli"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.right.notification_7_days — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.right.notification_7_days","_legal_basis":"Art. 282b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Zawiadomienie o kontroli min. 7 dni przed"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.right.no_notification_exceptions — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.right.no_notification_exceptions","_legal_basis":"Art. 282b § 2 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Wyjątki od 7-dniowego zawiadomienia: przestępstwo, KAS"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.right.presence_during_activities — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.right.presence_during_activities","_legal_basis":"Art. 285 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Prawo do obecności przy wszystkich czynnościach kontrolnych"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.right.exclusion_of_inspector — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.right.exclusion_of_inspector","_legal_basis":"Art. 130 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Wniosek o wyłączenie kontrolera"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.right.refuse_self_incrimination — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.right.refuse_self_incrimination","_legal_basis":"Art. 199 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Odmowa odpowiedzi grożącej odpowiedzialnością KKS"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.right.object_to_protocol — Prawo JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.right.object_to_protocol","_legal_basis":"Art. 291 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Zastrzeżenia do protokołu w ciągu 14 dni"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.document.electronic_evidence — Dokumenty
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.document.electronic_evidence","_legal_basis":"Art. 193a Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Dowody elektroniczne: autentyczność + integralność"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.document.foreign_language — Dokumenty
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.document.foreign_language","_legal_basis":"Art. 180a Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Dokumenty obcojęzyczne → tłumaczenie przysięgłe na żądanie"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.protocol.deadline_14_days_after_end — Protokół
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.protocol.deadline_14_days_after_end","_legal_basis":"Art. 291 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Protokół sporządzany w ciągu 14 dni od zakończenia kontroli"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.protocol.required_elements — Protokół
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.protocol.required_elements","_legal_basis":"Art. 291 § 3 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Data, oznaczenie organu, podstawa, ustalenia, pouczenie"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.protocol.objections_period — Protokół
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.protocol.objections_period","_legal_basis":"Art. 291 § 1 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["14 dni na zastrzeżenia od podpisania protokołu"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.protocol.objections_to_director — Protokół
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.protocol.objections_to_director","_legal_basis":"Art. 291 § 2 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Zastrzeżenia rozpatruje bezpośredni przełożony kontrolera"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.protocol.electronic_service — Protokół
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.protocol.electronic_service","_legal_basis":"Art. 144b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Protokół doręczany przez e-US z UPO"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.representation.poa_pps1 — Pełnomocnik
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.representation.poa_pps1","_legal_basis":"Art. 138a-138o Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Pełnomocnik ogólny PPS-1 może reprezentować podczas kontroli"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.audit.representation.poa_upl1 — Pełnomocnik
else :=   {"matched":true,"rule_id":"jdg.hyper.general.audit.representation.poa_upl1","_legal_basis":"Art. 138a-138o Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Pełnomocnik szczególny UPL-1 tylko do wskazanej sprawy"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.force_majeure.relief.deadline_extension — Ulga podatkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.relief.deadline_extension","_legal_basis":"Art. 67a § 1 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Przedłużenie terminu złożenia deklaracji"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.relief.application_immediate — Procedura
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.relief.application_immediate","_legal_basis":"Art. 67b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Wniosek składany niezwłocznie po zdarzeniu"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.relief.interest_suspension — Ulga
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.relief.interest_suspension","_legal_basis":"Art. 67a § 1 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Zawieszenie naliczania odsetek na czas rozpatrywania wniosku"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.relief.zus_deferral — Ulga ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.relief.zus_deferral","_legal_basis":"Art. 28 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":["Odroczenie terminu płatności składek ZUS"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.relief.zus_installments — Ulga ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.relief.zus_installments","_legal_basis":"Art. 29 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":["Układ ratalny w ZUS"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.relief.zus_remission — Ulga ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.relief.zus_remission","_legal_basis":"Art. 29 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":["Umorzenie składek ZUS (szczególne przypadki)"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.relief.zus_contribution_suspension — Ulga ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.relief.zus_contribution_suspension","_legal_basis":"Art. 18a ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":["Zawieszenie obowiązku opłacania składek na czas zdarzenia"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.documents.loss_reporting — Dokumenty
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.documents.loss_reporting","_legal_basis":"Art. 86 § 2 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Obowiązek zgłoszenia utraty dokumentów w 7 dni"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.force_majeure.documents.reconstruction_procedure — Dokumenty
else :=   {"matched":true,"rule_id":"jdg.hyper.general.force_majeure.documents.reconstruction_procedure","_legal_basis":"Art. 86 § 2 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Procedura odtworzenia zniszczonej dokumentacji"]} if {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}

# jdg.hyper.general.family.spouse.contract_type.b2b — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.spouse.contract_type.b2b","_legal_basis":"Art. 23 ust. 1 pkt 10 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Umowa B2B z małżonkiem → osobna JDG, ZUS własny"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.spouse.contract_type.mandate — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.spouse.contract_type.mandate","_legal_basis":"Art. 23 ust. 1 pkt 10 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Umowa zlecenie z małżonkiem → ZUS od zlecenia"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.children.employment.under_26 — Dzieci
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.children.employment.under_26","_legal_basis":"Art. 23 ust. 1 pkt 10 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Zatrudnienie dziecka <26 lat → podwyższone ryzyko kontroli"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.children.work_evidence_required — Dzieci
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.children.work_evidence_required","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Rzeczywiste wykonywanie pracy przez dziecko — dokumentuj"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.children.salary_arm_length — Dzieci
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.children.salary_arm_length","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.), Art. 23zf ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Wynagrodzenie rynkowe (nie zawyżone) — zasada ceny rynkowej"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.children.pit_ulga_young_interaction — Dzieci
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.children.pit_ulga_young_interaction","_legal_basis":"Art. 21 ust. 1 pkt 148 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Interakcja: pensja dziecka + ulga dla młodych (do 85 528 PLN)"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.children.university_compatibility — Dzieci
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.children.university_compatibility","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Praca musi być kompatybilna ze studiami"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.cooperation.zus_person — ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.cooperation.zus_person","_legal_basis":"Art. 8 ust. 2 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":["Osoba współpracująca → składki ZUS jak za przedsiębiorcę"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.cooperation.zus_health — ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.cooperation.zus_health","_legal_basis":"Art. 81 ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)","_warnings":["Osoba współpracująca → składka zdrowotna 9%"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.succession.sd_z2_deadline_6months — Sukcesja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.succession.sd_z2_deadline_6months","_legal_basis":"Art. 4a ustawy z dnia 28 lipca 1983 r. o podatku od spadków i darowizn","_warnings":["Zgłoszenie SD-Z2 w ciągu 6 miesięcy od śmierci/nabycia"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.succession.business_continuity — Sukcesja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.succession.business_continuity","_legal_basis":"Art. 12-13 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)","_warnings":["Ciągłość JDG po śmierci: zarządca sukcesyjny"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""; object.get(input.jdg_entrepreneur, "business_status", "") == "IN_SUCCESSIO"
}

# jdg.hyper.general.family.multi_generation.tax_planning — Planowanie
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.multi_generation.tax_planning","_legal_basis":"Art. 22-23 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Optymalizacja podatkowa poprzez zatrudnienie w różnych pokoleniach"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.general.family.aggregate.risk_assessment — Agregacja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.family.aggregate.risk_assessment","_legal_basis":"Art. 119b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Łączna ocena ryzyka podatkowego transakcji rodzinnych"]} if {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""; object.get(input.vendor, "risk_flag", false) == true
}

# jdg.hyper.general.edelivery.registration.mandatory — Obowiązek
else :=   {"matched":true,"rule_id":"jdg.hyper.general.edelivery.registration.mandatory","_legal_basis":"ustawy z dnia 18 listopada 2020 r. o doręczeniach elektronicznych, Art. 5","_warnings":["Rejestracja adresu e-Doręczeń w BAE (od 2025 dla JDG)"]} if {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.general.edelivery.registration.deadline_by_entity_type — Obowiązek
else :=   {"matched":true,"rule_id":"jdg.hyper.general.edelivery.registration.deadline_by_entity_type","_legal_basis":"ustawy z dnia 18 listopada 2020 r. o doręczeniach elektronicznych","_warnings":["Termin rejestracji zależny od typu podmiotu"]} if {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.general.edelivery.fiction.delivery_14_days — Fikcja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.edelivery.fiction.delivery_14_days","_legal_basis":"Art. 144b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Pismo nieodebrane → uznane za doręczone po 14 dniach"]} if {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.general.edelivery.fiction.consequences_legal — Fikcja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.edelivery.fiction.consequences_legal","_legal_basis":"Art. 144b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Konsekwencje: bieg terminów odwoławczych od daty fikcji"]} if {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.general.edelivery.fiction.critical_alert — Fikcja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.edelivery.fiction.critical_alert","_legal_basis":"Art. 144b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Alert CRITICAL przy zbliżającej się fikcji doręczenia"]} if {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.general.cross_border.eidas.recognition — Transgraniczne
else :=   {"matched":true,"rule_id":"jdg.hyper.general.cross_border.eidas.recognition","_legal_basis":"rozporządzenia Parlamentu Europejskiego i Rady (UE) nr 910/2014 z dnia 23 lipca 2014 r. w sprawie identyfikacji elektronicznej i usług zaufania (eIDAS)","_warnings":["Uznawanie podpisów elektronicznych z UE (eIDAS)"]} if {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.hyper.general.cross_border.crs.fatca.reporting — Transgraniczne
else :=   {"matched":true,"rule_id":"jdg.hyper.general.cross_border.crs.fatca.reporting","_legal_basis":"ustawy z dnia 9 marca 2017 r. o wymianie informacji podatkowych z innymi państwami","_warnings":["Automatyczna wymiana informacji CRS/FATCA"]} if {
    object.get(input.vendor, "country", "") in {"NON_EU"}
}

# jdg.hyper.general.cross_border.dac.directives.compliance — Transgraniczne
else :=   {"matched":true,"rule_id":"jdg.hyper.general.cross_border.dac.directives.compliance","_legal_basis":"Dyrektyw Rady 2011/16/UE (DAC1-DAC8) w sprawie współpracy administracyjnej w dziedzinie opodatkowania","_warnings":["Zgodność z dyrektywami DAC"]} if {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.hyper.general.communication.calendar.deadlines_integration — Kalendarz
else :=   {"matched":true,"rule_id":"jdg.hyper.general.communication.calendar.deadlines_integration","_legal_basis":"Art. 144b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Integracja terminów komunikacyjnych z kalendarzem płatności"]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.general.communication.offline.backup_procedure — Awaria
else :=   {"matched":true,"rule_id":"jdg.hyper.general.communication.offline.backup_procedure","_legal_basis":"Art. 144b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Procedura na wypadek awarii systemów e-US"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.communication.offline.paper_allowed_when — Awaria
else :=   {"matched":true,"rule_id":"jdg.hyper.general.communication.offline.paper_allowed_when","_legal_basis":"Art. 144 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Kiedy dozwolona forma papierowa"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.communication.language.polish_required — Język
else :=   {"matched":true,"rule_id":"jdg.hyper.general.communication.language.polish_required","_legal_basis":"Art. 4 ustawy z dnia 7 października 1999 r. o języku polskim","_warnings":["Obowiązek komunikacji w języku polskim"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.communication.language.foreign_documents_translation — Język
else :=   {"matched":true,"rule_id":"jdg.hyper.general.communication.language.foreign_documents_translation","_legal_basis":"Art. 180a Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Tłumaczenie przysięgłe dokumentów obcojęzycznych"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.communication.aggregate.status_dashboard — Agregacja
else :=   {"matched":true,"rule_id":"jdg.hyper.general.communication.aggregate.status_dashboard","_legal_basis":"Art. 138e-138i Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Dashboard statusu komunikacji z organami — monitoruj terminy doręczeń elektronicznych"]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.kks.conviction.bank_account_termination — Bank może wypowiedzieć umowę rachunku
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.bank_account_termination","_legal_basis":"Art. 56 ustawy z dnia 29 sierpnia 1997 r. — Prawo bankowe + ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.kks.conviction.credit_score_impact — Wpływ na zdolność kredytową
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.credit_score_impact","_legal_basis":"Art. 105 ustawy z dnia 29 sierpnia 1997 r. — Prawo bankowe","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.kks.conviction.enhanced_aml_kyc — Wzmocniona weryfikacja AML/KYC
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.enhanced_aml_kyc","_legal_basis":"Art. 43 ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.kks.conviction.fintech_access_restriction — Ograniczenia w dostępie do fintechów
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.fintech_access_restriction","_legal_basis":"ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.kks.conviction.cash_transaction_monitoring — Monitoring transakcji gotówkowych
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.cash_transaction_monitoring","_legal_basis":"ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.kks.conviction.tax_office_scrutiny_increased — Zaostrzony nadzór US po skazaniu
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.tax_office_scrutiny_increased","_legal_basis":"Art. 119b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.kks.conviction.risk_profile_reclassification — Przeklasyfikowanie profilu ryzyka na HIGH
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.risk_profile_reclassification","_legal_basis":"Art. 119b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true; object.get(input.vendor, "risk_flag", false) == true
}

# jdg.hyper.general.kks.conviction.public_warning_list_art119b — Wpis na listę ostrzeżeń publicznych MF
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.public_warning_list_art119b","_legal_basis":"Art. 119b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.kks.conviction.statute_interruption — Przerwanie biegu przedawnienia przez skazanie
else :=   {"matched":true,"rule_id":"jdg.hyper.general.kks.conviction.statute_interruption","_legal_basis":"Art. 70 § 4 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.hyper.general.regulated.cross_border.eu_qualifications_recognition — Uznawanie kwalifikacji UE w PL
else :=   {"matched":true,"rule_id":"jdg.hyper.general.regulated.cross_border.eu_qualifications_recognition","_legal_basis":"Dyrektywa 2005/36/WE","_warnings":[]} if {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.hyper.general.regulated.cross_border.non_eu_qualifications — Uznawanie kwalifikacji spoza UE — procedura nostryfikacji
else :=   {"matched":true,"rule_id":"jdg.hyper.general.regulated.cross_border.non_eu_qualifications","_legal_basis":"ustaw regulujących wykonywanie zawodów regulowanych","_warnings":[]} if {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.hyper.general.regulated.cross_border.temporary_services_eu — Tymczasowe świadczenie usług w UE — uznanie kwalifikacji
else :=   {"matched":true,"rule_id":"jdg.hyper.general.regulated.cross_border.temporary_services_eu","_legal_basis":"Dyrektywa 2005/36/WE","_warnings":[]} if {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.hyper.general.regulated.cross_border.double_taxation_specialist — Podwójne opodatkowanie specjalisty transgranicznego
else :=   {"matched":true,"rule_id":"jdg.hyper.general.regulated.cross_border.double_taxation_specialist","_legal_basis":"umów o unikaniu podwójnego opodatkowania (UPO)","_warnings":[]} if {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.hyper.general.regulated.cross_border.vat_registration_abroad — Obowiązek rejestracji VAT za granicą przy usługach B2C
else :=   {"matched":true,"rule_id":"jdg.hyper.general.regulated.cross_border.vat_registration_abroad","_legal_basis":"Art. 28k ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.), OSS","_warnings":[]} if {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.hyper.general.regulated.aggregate.profession_specific_risk_profile — Profil ryzyka specyficzny dla zawodu regulowanego
else :=   {"matched":true,"rule_id":"jdg.hyper.general.regulated.aggregate.profession_specific_risk_profile","_legal_basis":"Art. 119b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} if {
    object.get(input.vendor, "risk_flag", false) == true
}

# jdg.hyper.general.regulated.aggregate.annual_compliance_checklist — Checklista roczna dla zawodu regulowanego
else :=   {"matched":true,"rule_id":"jdg.hyper.general.regulated.aggregate.annual_compliance_checklist","_legal_basis":"ustaw regulujących wykonywanie zawodów regulowanych","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.insurance.mandatory.detection_legal — OC prawników — obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.hyper.general.insurance.mandatory.detection_legal","_legal_basis":"Rozp. MS ws. OC adwokatów/radców","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.insurance.mandatory.detection_medical — OC lekarzy — obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.hyper.general.insurance.mandatory.detection_medical","_legal_basis":"ustawy z dnia 5 grudnia 1996 r. o zawodach lekarza i lekarza dentysty","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.installments.pit_revenue_per_installment — Sprzedaż na raty — przychód PIT w dacie każdej raty
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.installments.pit_revenue_per_installment","_legal_basis":"Art. 14 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.installments.vat_accrual_full_immediately — VAT memoriałowy — obowiązek od całości w dacie dostawy, niezależnie od rat
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.installments.vat_accrual_full_immediately","_legal_basis":"Art. 19a ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.installments.vat_cash_per_installment — VAT kasowy — obowiązek w dacie każdej raty
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.installments.vat_cash_per_installment","_legal_basis":"Art. 21 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.installments.late_payment_interest — Opóźnienie raty → odsetki od zaległości
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.installments.late_payment_interest","_legal_basis":"Art. 56 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.installments.contract_termination_consequences — Zerwanie umowy ratalnej — skutki podatkowe (korekta przychodu/VAT)
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.installments.contract_termination_consequences","_legal_basis":"Art. 106j ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.advance.vat_obligation_on_receipt — Zaliczka — obowiązek VAT w dacie otrzymania (nawet przed dostawą)
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.advance.vat_obligation_on_receipt","_legal_basis":"Art. 19a ust. 8 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.advance.vat_invoice_required_15days — Faktura zaliczkowa w ciągu 15 dni od otrzymania zaliczki
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.advance.vat_invoice_required_15days","_legal_basis":"Art. 106i ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.advance.pit_revenue_on_receipt — Zaliczka — przychód PIT w dacie otrzymania
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.advance.pit_revenue_on_receipt","_legal_basis":"Art. 14 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.general.payment.advance.advance_not_refunded_taxable — Niezwrócona zaliczka przy zerwaniu umowy — opodatkowana
else :=   {"matched":true,"rule_id":"jdg.hyper.general.payment.advance.advance_not_refunded_taxable","_legal_basis":"Art. 14 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}
