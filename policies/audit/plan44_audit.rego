# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.audit (Doc 44: P1830-P1844)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 15
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.audit
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.audit.no_match","package":"jdg.audit","priority":99999}

# jdg.audit.type_determination — Typ kontroli podatkowej — czynności sprawdzające / kontrola / postępowanie
decide :=   {"matched":true,"rule_id":"jdg.audit.type_determination","package":"jdg.audit","priority":1830,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Typ kontroli podatkowej — czynności sprawdzające / kontrola / postępowanie","_legal_basis":"Art. 272-292 Ordynacji podatkowej","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
}

# jdg.audit.rights_and_obligations — P1831: Prawa i obowiązki JDG (bez zastrzeżeń)
else :=   {"matched":true,"rule_id":"jdg.audit.rights_and_obligations","package":"jdg.audit","priority":1831,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Prawa i obowiązki JDG podczas kontroli","_legal_basis":"Art. 281-292 Ordynacji podatkowej","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
    object.get(input.document, "objections_filed", true) == false
}

# jdg.audit.protocol_objections — P1832: Zastrzeżenia do protokołu (bez odwołania)
else :=   {"matched":true,"rule_id":"jdg.audit.protocol_objections","package":"jdg.audit","priority":1832,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zastrzeżenia do protokołu kontroli — 14 dni","_legal_basis":"Art. 291 § 1-2 Ordynacji podatkowej","_warnings":["Termin na zastrzeżenia do protokołu upływa — zostało X dni"]} {
    object.get(input.document, "audit_in_progress", false) == true
    object.get(input.document, "appeal_filed", true) == false
}

# jdg.audit.statute_suspension — P1833: Zawieszenie przedawnienia na czas kontroli
else :=   {"matched":true,"rule_id":"jdg.audit.statute_suspension","package":"jdg.audit","priority":1833,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zawieszenie przedawnienia na czas kontroli","_legal_basis":"Art. 70 § 6 pkt 1 Ordynacji podatkowej","_warnings":["Kontrola w toku — bieg przedawnienia zawieszony"]} {
    object.get(input.document, "statute_suspended", false) == true; object.get(input.document, "audit_in_progress", false) == true
}

# jdg.audit.evidence_collection_rights — P1834: Prawa organu do zbierania dowodów
else :=   {"matched":true,"rule_id":"jdg.audit.evidence_collection_rights","package":"jdg.audit","priority":1834,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Prawa organu: żądanie dokumentów, przesłuchania świadków, opinie biegłych, oględziny","_legal_basis":"Art. 190-200, 287 Ordynacji podatkowej","_warnings":[]} {
    object.get(input.document, "audit_in_progress", false) == true
    object.get(input.document, "evidence_collection_active", false) == true
}

# jdg.audit.seizure_of_documents — P1835: Zatrzymanie dokumentów tylko za pokwitowaniem
else :=   {"matched":true,"rule_id":"jdg.audit.seizure_of_documents","package":"jdg.audit","priority":1835,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zatrzymanie dokumentów — tylko za pokwitowaniem, max na czas kontroli","_legal_basis":"Art. 288 Ordynacji podatkowej","_warnings":["Organ może zatrzymać dokumenty tylko za pokwitowaniem"]} {
    object.get(input.document, "audit_in_progress", false) == true
    object.get(input.document, "seizure_of_documents_active", false) == true
}

# jdg.audit.correction_during_audit — P1836: Korekta deklaracji podczas kontroli
else :=   {"matched":true,"rule_id":"jdg.audit.correction_during_audit","package":"jdg.audit","priority":1836,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Korekta deklaracji podczas kontroli — na niekorzyść możliwa, na korzyść blokowana","_legal_basis":"Art. 81b Ordynacji podatkowej","_warnings":["Korekta na korzyść blokowana podczas kontroli — US musi wyrazić zgodę"]} {
    object.get(input.document, "audit_in_progress", false) == true
    object.get(input.document, "correction_during_audit_attempted", false) == true
}

# jdg.audit.decision_appeal — P1837: Odwołanie od decyzji (gdy decyzja wydana)
else :=   {"matched":true,"rule_id":"jdg.audit.decision_appeal","package":"jdg.audit","priority":1837,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Odwołanie od decyzji — 14 dni do Dyrektora IAS, 30 dni do WSA","_legal_basis":"Art. 220-247 OP, Art. 52-54 PPSA","_warnings":["Odwołanie od decyzji pokontrolnej — 14 dni do organu II instancji!"]} {
    object.get(input.document, "audit_in_progress", false) == true
    object.get(input.document, "decision_issued", false) == true
    object.get(input.document, "appeal_filed", false) == false
}

# jdg.audit.right_to_be_heard — P1838: Prawo do wypowiedzenia się przed wydaniem decyzji
else :=   {"matched":true,"rule_id":"jdg.audit.right_to_be_heard","package":"jdg.audit","priority":1838,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Prawo do wypowiedzenia się przed wydaniem decyzji — Art. 200 OP","_legal_basis":"Art. 200 Ordynacji podatkowej","_warnings":["Przed decyzją organ musi umożliwić zapoznanie się z aktami i wypowiedzenie"]} {
    object.get(input.document, "audit_in_progress", false) == true
    object.get(input.document, "right_to_be_heard_given", false) == false
}

# jdg.audit.legal_privilege — P1839: Tajemnica zawodowa adwokata/radcy/doradcy
else :=   {"matched":true,"rule_id":"jdg.audit.legal_privilege","package":"jdg.audit","priority":1839,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Tajemnica zawodowa — dokumenty nietykalne podczas kontroli","_legal_basis":"Art. 180 § 3 Ordynacji podatkowej","_warnings":["Dokumenty objęte tajemnicą adwokacką/radcowską — wyłączone z kontroli"]} {
    object.get(input.document, "audit_in_progress", false) == true
    object.get(input.document, "legal_privilege_involved", false) == true
}

# jdg.audit.representation_rights — P1840: Prawa pełnomocnika podczas kontroli
else :=   {"matched":true,"rule_id":"jdg.audit.representation_rights","package":"jdg.audit","priority":1840,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Prawa pełnomocnika — PPS-1/UPL-1, wgląd w akta, udział w czynnościach","_legal_basis":"Art. 178, 138e, 291 Ordynacji podatkowej","_warnings":["Pełnomocnik ma prawo wglądu w akta i udziału w czynnościach kontrolnych"]} {
    object.get(input.document, "audit_in_progress", false) == true
    object.get(input.document, "representative_appointed", false) == true
}

# jdg.audit.obstruction_penalty — P1841: Sankcje za utrudnianie (gdy wykryte)
else :=   {"matched":true,"rule_id":"jdg.audit.obstruction_penalty","package":"jdg.audit","priority":1841,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Sankcje za utrudnianie kontroli — grzywna do 5k PLN + KKS Art. 69","_legal_basis":"Art. 262 OP, Art. 69 KKS","_warnings":["Utrudnianie kontroli — grzywna do 5000 PLN + odpowiedzialność KKS do 720 stawek!"]} {
    object.get(input.document, "audit_in_progress", false) == true
    object.get(input.document, "obstruction_detected", false) == true
}

# jdg.audit.electronic_evidence — P1842: Dowody elektroniczne podczas kontroli
else :=   {"matched":true,"rule_id":"jdg.audit.electronic_evidence","package":"jdg.audit","priority":1842,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dowody elektroniczne — wydruki, e-maile, e-faktury, JPK","_legal_basis":"Art. 193a-193d Ordynacji podatkowej","_warnings":["Dowody elektroniczne wymagają autentyczności i integralności"]} {
    object.get(input.document, "audit_in_progress", false) == true
    object.get(input.document, "electronic_evidence_used", false) == true
}

# jdg.audit.foreign_language_documents — P1843: Dokumenty w języku obcym — tłumaczenie przysięgłe
else :=   {"matched":true,"rule_id":"jdg.audit.foreign_language_documents","package":"jdg.audit","priority":1843,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dokumenty obcojęzyczne — organ może żądać tłumaczenia przysięgłego","_legal_basis":"Art. 180a Ordynacji podatkowej","_warnings":["Dokumenty w języku obcym — koszt tłumaczenia ponosi JDG"]} {
    object.get(input.document, "audit_in_progress", false) == true
    object.get(input.document, "foreign_language_documents", false) == true
}

# jdg.audit.closure_and_follow_up — P1844: Zakończenie kontroli (gdy audyt zamknięty)
else :=   {"matched":true,"rule_id":"jdg.audit.closure_and_follow_up","package":"jdg.audit","priority":1844,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Zakończenie kontroli — monitoring post-kontrolny","_legal_basis":"Art. 291-292 Ordynacji podatkowej","_warnings":["Kontrola zakończona — monitoruj realizację zaleceń, korekty, wpłaty"]} {
    object.get(input.document, "audit_in_progress", false) == true
    object.get(input.document, "audit_closed", false) == true
    object.get(input.document, "follow_up_completed", false) == false
}
