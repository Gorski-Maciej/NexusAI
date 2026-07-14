# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.audit hyper-granularity (Doc 45: R1106-R1160)
# Atom rules: kontrola podatkowa — types, triggers, rights, obligations, sanctions
# Rules: 55 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.audit.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.audit.hyper.no_match","package":"jdg.audit.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.audit.hyper.type_verification","package":"jdg.audit.hyper","priority":1106,"_routing":"","_routing_reason":"Czynn. sprawdzające — max 7 dni","_legal_basis":"Art. 272-280 OP","_warnings":["Czynności sprawdzające — max 7 dni ciągłych"]} {
    object.get(input.document, "audit_type", "") == "VERIFICATION"
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.type_tax_audit","package":"jdg.audit.hyper","priority":1107,"_routing":"","_routing_reason":"Kontrola podatkowa — max 30 dni","_legal_basis":"Art. 281-292 OP","_warnings":["Kontrola podatkowa — max 30 dni standard"]} {
    object.get(input.document, "audit_type", "") == "TAX_AUDIT"
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.type_tax_proceeding","package":"jdg.audit.hyper","priority":1108,"_routing":"TRIAGE_QUEUE","_routing_reason":"Postępowanie podatkowe — bez limitu","_legal_basis":"Art. 120-129 OP","_warnings":["Postępowanie podatkowe — bez limitu czasu trwania"]} {
    object.get(input.document, "audit_type", "") == "TAX_PROCEEDING"
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.type_customs_fiscal","package":"jdg.audit.hyper","priority":1109,"_routing":"TRIAGE_QUEUE","_routing_reason":"Kontrola celno-skarbowa — max 3 mies.","_legal_basis":"Art. 54-93 KAS","_warnings":["Kontrola celno-skarbowa — max 3 miesiące standard"]} {
    object.get(input.document, "audit_type", "") == "CUSTOMS_FISCAL"
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.trigger_cross_checking","package":"jdg.audit.hyper","priority":1110,"_routing":"","_routing_reason":"Trigger: weryfikacja krzyżowa","_legal_basis":"Art. 272 OP","_warnings":["Weryfikacja krzyżowa deklaracji → czynności sprawdzające"]} {
    object.get(input.document, "cross_check_triggered", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.trigger_return_to_correct","package":"jdg.audit.hyper","priority":1111,"_routing":"WARNING","_routing_reason":"Trigger: wezwanie do korekty","_legal_basis":"Art. 274 OP","_warnings":["Wezwanie do korekty deklaracji — 7 dni na korektę"]} {
    object.get(input.document, "correction_summoned", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.trigger_inspection_warrant","package":"jdg.audit.hyper","priority":1112,"_routing":"","_routing_reason":"Trigger: imienne upoważnienie","_legal_basis":"Art. 283 OP","_warnings":["Kontrola na podstawie imiennego upoważnienia"]} {
    object.get(input.document, "inspection_warrant_presented", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.trigger_external_information","package":"jdg.audit.hyper","priority":1113,"_routing":"WARNING","_routing_reason":"Trigger: informacja z innego organu","_legal_basis":"Art. 281 OP","_warnings":["Informacja od innego organu → wszczęcie kontroli"]} {
    object.get(input.document, "external_trigger", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.right_notification_7days","package":"jdg.audit.hyper","priority":1114,"_routing":"","_routing_reason":"Prawo: zawiadomienie 7 dni przed","_legal_basis":"Art. 282b OP","_warnings":["Zawiadomienie o kontroli min. 7 dni przed"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.right_no_notification_exceptions","package":"jdg.audit.hyper","priority":1115,"_routing":"WARNING","_routing_reason":"Wyjątki od 7-dniowego zawiadomienia","_legal_basis":"Art. 282b OP","_warnings":["Wyjątki: przestępstwo, KAS, zabezpieczenie — bez 7-dniowego zawiadomienia"]} {
    object.get(input.document, "no_notification", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.right_presence","package":"jdg.audit.hyper","priority":1116,"_routing":"","_routing_reason":"Prawo: obecność przy czynnościach","_legal_basis":"Art. 285 OP","_warnings":["Prawo do obecności przy wszystkich czynnościach kontrolnych"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.right_exclusion_inspector","package":"jdg.audit.hyper","priority":1117,"_routing":"","_routing_reason":"Prawo: wyłączenie kontrolera","_legal_basis":"Art. 130 OP","_warnings":["Wniosek o wyłączenie kontrolera — złoż w ciągu 7 dni"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.right_refuse_self_incrimination","package":"jdg.audit.hyper","priority":1118,"_routing":"WARNING","_routing_reason":"Prawo: odmowa samooskarżenia","_legal_basis":"Art. 199 OP","_warnings":["Masz prawo odmówić odpowiedzi grożącej odpowiedzialnością KKS"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.right_object_to_protocol","package":"jdg.audit.hyper","priority":1119,"_routing":"WARNING","_routing_reason":"Prawo: zastrzeżenia 14 dni","_legal_basis":"Art. 291 OP","_warnings":["Zastrzeżenia do protokołu — 14 dni od podpisania"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.right_record_activities","package":"jdg.audit.hyper","priority":1120,"_routing":"","_routing_reason":"Prawo: nagrywanie czynności","_legal_basis":"Art. 286 § 3 OP","_warnings":["Nagrywanie za zgodą kontrolującego"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.right_break_request","package":"jdg.audit.hyper","priority":1121,"_routing":"","_routing_reason":"Prawo: przerwa w kontroli","_legal_basis":"Art. 84c PP","_warnings":["Przerwa w kontroli — max 3 dni robocze"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.right_oppose_inspection","package":"jdg.audit.hyper","priority":1122,"_routing":"TRIAGE_QUEUE","_routing_reason":"Prawo: sprzeciw wobec kontroli","_legal_basis":"Art. 84c PP","_warnings":["Sprzeciw wobec kontroli naruszającej przepisy"]} {
    object.get(input.document, "inspection_violation", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.right_correction_minus_blocked","package":"jdg.audit.hyper","priority":1123,"_routing":"WARNING","_routing_reason":"Blokada korekty na korzyść","_legal_basis":"Art. 81b OP","_warnings":["Korekta na korzyść blokowana podczas kontroli"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.right_correction_plus_allowed","package":"jdg.audit.hyper","priority":1124,"_routing":"","_routing_reason":"Korekta na niekorzyść dozwolona","_legal_basis":"Art. 81b OP","_warnings":["Korekta na niekorzyść zawsze dozwolona podczas kontroli"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.right_to_be_heard","package":"jdg.audit.hyper","priority":1125,"_routing":"","_routing_reason":"Prawo do wypowiedzenia","_legal_basis":"Art. 200 OP","_warnings":["Prawo do wypowiedzenia przed wydaniem decyzji"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.right_appeal_14days","package":"jdg.audit.hyper","priority":1126,"_routing":"TRIAGE_QUEUE","_routing_reason":"Odwołanie — 14 dni","_legal_basis":"Art. 223 OP","_warnings":["Odwołanie od decyzji — 14 dni od doręczenia!"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.right_wsa_30days","package":"jdg.audit.hyper","priority":1127,"_routing":"TRIAGE_QUEUE","_routing_reason":"Skarga do WSA — 30 dni","_legal_basis":"Art. 52-54 PPSA","_warnings":["Skarga do WSA — 30 dni od decyzji II instancji"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.obligation_provide_docs","package":"jdg.audit.hyper","priority":1128,"_routing":"","_routing_reason":"Obowiązek: udostępnienie dokumentów","_legal_basis":"Art. 287 OP","_warnings":["Udostępnij żądane dokumenty w wyznaczonym terminie"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.obligation_allow_inspection","package":"jdg.audit.hyper","priority":1129,"_routing":"","_routing_reason":"Obowiązek: oględziny lokalu","_legal_basis":"Art. 287 OP","_warnings":["Umożliw oględziny lokalu w godzinach 7-18"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.obligation_provide_explanations","package":"jdg.audit.hyper","priority":1130,"_routing":"","_routing_reason":"Obowiązek: wyjaśnienia","_legal_basis":"Art. 287 OP","_warnings":["Składaj wyjaśnienia ustne i pisemne na żądanie kontrolującego"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.obligation_sign_protocol","package":"jdg.audit.hyper","priority":1131,"_routing":"","_routing_reason":"Obowiązek: podpisanie protokołu","_legal_basis":"Art. 291 OP","_warnings":["Podpisz protokół — odmowa wymaga uzasadnienia"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.obligation_retain_audit_docs","package":"jdg.audit.hyper","priority":1132,"_routing":"","_routing_reason":"Obowiązek: retencja dokumentacji","_legal_basis":"Art. 86 OP","_warnings":["Przechowuj dokumentację kontrolną przez min. 5 lat"]} {
    object.get(input.document, "audit_closed", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.statute_suspension_effect","package":"jdg.audit.hyper","priority":1133,"_routing":"","_routing_reason":"Zawieszenie przedawnienia","_legal_basis":"Art. 70 § 6 OP","_warnings":["Wszczęcie kontroli → zawieszenie biegu przedawnienia"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.statute_suspension_duration","package":"jdg.audit.hyper","priority":1134,"_routing":"","_routing_reason":"Zawieszenie trwa przez całą kontrolę","_legal_basis":"Art. 70 § 6 OP","_warnings":["Zawieszenie przedawnienia trwa przez cały okres kontroli"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.statute_resume_after_close","package":"jdg.audit.hyper","priority":1135,"_routing":"","_routing_reason":"Wznowienie przedawnienia","_legal_basis":"Art. 70 § 6 OP","_warnings":["Bieg przedawnienia wznawia się po zakończeniu kontroli"]} {
    object.get(input.document, "audit_closed", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.penalty_obstruction_5000","package":"jdg.audit.hyper","priority":1136,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Utrudnianie — grzywna 5k PLN","_legal_basis":"Art. 262 OP","_warnings":["Utrudnianie kontroli — grzywna do 5 000 PLN!"]} {
    object.get(input.document, "obstruction_detected", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.penalty_obstruction_kks69","package":"jdg.audit.hyper","priority":1137,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Utrudnianie — KKS Art. 69","_legal_basis":"Art. 69 KKS","_warnings":["Utrudnianie — odpowiedzialność KKS do 720 stawek!"]} {
    object.get(input.document, "obstruction_detected", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.penalty_coercion","package":"jdg.audit.hyper","priority":1138,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Środki przymusu","_legal_basis":"Art. 151 OP","_warnings":["Środki przymusu: grzywna, przymuszenie bezpośrednie"]} {
    object.get(input.document, "coercion_imposed", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.doc_seizure_receipt","package":"jdg.audit.hyper","priority":1139,"_routing":"WARNING","_routing_reason":"Zatrzymanie dok. — pokwitowanie","_legal_basis":"Art. 288 OP","_warnings":["Zatrzymanie dokumentów tylko za pokwitowaniem"]} {
    object.get(input.document, "seizure_of_documents_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.doc_seizure_duration","package":"jdg.audit.hyper","priority":1140,"_routing":"","_routing_reason":"Zatrzymanie — max na czas kontroli","_legal_basis":"Art. 288 OP","_warnings":["Dokumenty zatrzymane max na czas kontroli"]} {
    object.get(input.document, "seizure_of_documents_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.doc_electronic_evidence","package":"jdg.audit.hyper","priority":1141,"_routing":"","_routing_reason":"Dowody elektroniczne","_legal_basis":"Art. 193a OP","_warnings":["E-dowody: autentyczność + integralność + czytelność"]} {
    object.get(input.document, "electronic_evidence_used", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.doc_foreign_language","package":"jdg.audit.hyper","priority":1142,"_routing":"","_routing_reason":"Dokumenty obcojęzyczne","_legal_basis":"Art. 180a OP","_warnings":["Dok. obcojęzyczne → tłumaczenie przysięgłe na żądanie"]} {
    object.get(input.document, "foreign_language_documents", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.protocol_deadline_14days","package":"jdg.audit.hyper","priority":1143,"_routing":"WARNING","_routing_reason":"Protokół — 14 dni od zakończenia","_legal_basis":"Art. 291 OP","_warnings":["Protokół sporządzany w ciągu 14 dni od zakończenia"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.protocol_required_elements","package":"jdg.audit.hyper","priority":1144,"_routing":"","_routing_reason":"Protokół: wymagane elementy","_legal_basis":"Art. 291 OP","_warnings":["Protokół: data, organ, podstawa, ustalenia, pouczenie"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.protocol_objections_period","package":"jdg.audit.hyper","priority":1145,"_routing":"WARNING","_routing_reason":"14 dni na zastrzeżenia","_legal_basis":"Art. 291 OP","_warnings":["14 dni na zastrzeżenia od podpisania protokołu"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.protocol_objections_to_director","package":"jdg.audit.hyper","priority":1146,"_routing":"","_routing_reason":"Zastrzeżenia: bezpośredni przełożony","_legal_basis":"Art. 291 OP","_warnings":["Zastrzeżenia rozpatruje bezpośredni przełożony kontrolera"]} {
    object.get(input.document, "objections_filed", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.protocol_electronic_service","package":"jdg.audit.hyper","priority":1147,"_routing":"","_routing_reason":"Protokół e-US z UPO","_legal_basis":"Art. 144b OP","_warnings":["Protokół doręczany przez e-US z Urzędowym Poświadczeniem Odbioru"]} {
    object.get(input.document, "audit_closed", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.representation_pps1","package":"jdg.audit.hyper","priority":1148,"_routing":"","_routing_reason":"Pełnomocnik: PPS-1","_legal_basis":"Art. 138e OP","_warnings":["Pełnomocnik ogólny PPS-1 może reprezentować"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.representation_upl1","package":"jdg.audit.hyper","priority":1149,"_routing":"","_routing_reason":"Pełnomocnik: UPL-1","_legal_basis":"Art. 138e OP","_warnings":["Pełnomocnik szczególny UPL-1 tylko do wskazanej sprawy"]} {
    object.get(input.document, "upl1_filed", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.representation_access_files","package":"jdg.audit.hyper","priority":1150,"_routing":"","_routing_reason":"Pełnomocnik: wgląd w akta","_legal_basis":"Art. 178 OP","_warnings":["Pełnomocnik ma prawo wglądu w akta sprawy"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.representation_participation","package":"jdg.audit.hyper","priority":1151,"_routing":"","_routing_reason":"Pełnomocnik: udział w czynnościach","_legal_basis":"Art. 138e OP","_warnings":["Pełnomocnik ma prawo udziału we wszystkich czynnościach"]} {
    object.get(input.document, "audit_in_progress", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.cross_border_mutual_assistance","package":"jdg.audit.hyper","priority":1152,"_routing":"","_routing_reason":"Współpraca transgraniczna organów","_legal_basis":"DAC, UPO","_warnings":["Współpraca z organami innych krajów UE"]} {
    object.get(input.document, "cross_border_audit", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.cross_border_simultaneous","package":"jdg.audit.hyper","priority":1153,"_routing":"TRIAGE_QUEUE","_routing_reason":"Kontrola jednoczesna w UE","_legal_basis":"DAC","_warnings":["Kontrola jednoczesna w kilku krajach UE"]} {
    object.get(input.document, "simultaneous_audit", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.cross_border_foreign_officials","package":"jdg.audit.hyper","priority":1154,"_routing":"","_routing_reason":"Udział zagranicznych kontrolerów","_legal_basis":"DAC","_warnings":["Udział zagranicznych kontrolerów w kontroli w PL"]} {
    object.get(input.document, "foreign_officials_present", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.closure_decision_issuance","package":"jdg.audit.hyper","priority":1155,"_routing":"WARNING","_routing_reason":"Decyzja wymiarowa","_legal_basis":"Art. 107 OP","_warnings":["Decyzja wymiarowa po zakończeniu kontroli"]} {
    object.get(input.document, "audit_closed", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.closure_decision_deadline","package":"jdg.audit.hyper","priority":1156,"_routing":"","_routing_reason":"Decyzja — bez zbędnej zwłoki","_legal_basis":"Art. 107 OP","_warnings":["Decyzja wydawana bez zbędnej zwłoki po kontroli"]} {
    object.get(input.document, "audit_closed", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.closure_correction_window","package":"jdg.audit.hyper","priority":1157,"_routing":"","_routing_reason":"Korekta po kontroli","_legal_basis":"Art. 81b OP","_warnings":["Możliwość korekty po zakończeniu kontroli"]} {
    object.get(input.document, "audit_closed", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.followup_recommendations","package":"jdg.audit.hyper","priority":1158,"_routing":"WARNING","_routing_reason":"Zalecenia pokontrolne","_legal_basis":"Art. 292 OP","_warnings":["Wdróż zalecenia pokontrolne — monitoruj terminy"]} {
    object.get(input.document, "audit_closed", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.followup_deadline_monitoring","package":"jdg.audit.hyper","priority":1159,"_routing":"WARNING","_routing_reason":"Monitoring terminów","_legal_basis":"Art. 292 OP","_warnings":["Monitoruj terminy wdrożenia zaleceń pokontrolnych"]} {
    object.get(input.document, "audit_closed", false) == true
}
else := {"matched":true,"rule_id":"jdg.audit.hyper.aggregate_risk_update","package":"jdg.audit.hyper","priority":1160,"_routing":"","_routing_reason":"Aktualizacja profilu ryzyka","_legal_basis":"Art. 119b OP","_warnings":["Aktualizacja profilu ryzyka JDG po zakończeniu kontroli"]} {
    object.get(input.document, "audit_closed", false) == true
}
