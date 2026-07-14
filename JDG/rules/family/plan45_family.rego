# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.family hyper (Doc 45: R1193-R1234)
# Atom rules: członkowie rodziny — spouse, children, cooperation, assets, succession
# Rules: 42 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.family.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.family.hyper.no_match","package":"jdg.family.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.family.hyper.spouse_kup_conditions","package":"jdg.family.hyper","priority":1193,"_routing":"","_routing_reason":"Małżonek — warunki KUP","_legal_basis":"Art. 22/23 PIT","_warnings":["Wynagrodzenie małżonka: praca rzeczywista, rynkowa, udokumentowana"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "SPOUSE"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.spouse_market_benchmark","package":"jdg.family.hyper","priority":1194,"_routing":"WARNING","_routing_reason":"Małżonek — test rynkowy ±30%","_legal_basis":"Art. 22 PIT","_warnings":["Czy pensja mieści się w ±30% mediany rynkowej?"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "SPOUSE"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.spouse_qualifications","package":"jdg.family.hyper","priority":1195,"_routing":"WARNING","_routing_reason":"Małżonek — kwalifikacje","_legal_basis":"Art. 22 PIT","_warnings":["Sprawdź kwalifikacje adekwatne do stanowiska"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "SPOUSE"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.spouse_work_evidence","package":"jdg.family.hyper","priority":1196,"_routing":"WARNING","_routing_reason":"Małżonek — ewidencja pracy","_legal_basis":"Art. 22 PIT","_warnings":["Ewidencja czasu pracy, zadań, efektów — obowiązkowa"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "SPOUSE"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.spouse_salary_above_market_redflag","package":"jdg.family.hyper","priority":1197,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Małżonek — >130% mediany → HIGH risk","_legal_basis":"Art. 23 PIT","_warnings":["Wynagrodzenie >130% mediany → HIGH risk flag!"]} {
    object.get(input.vendor, "salary_above_market", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.spouse_no_qualifications_redflag","package":"jdg.family.hyper","priority":1198,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Małżonek — brak kwalifikacji + wysokie","_legal_basis":"Art. 23 PIT","_warnings":["Brak kwalifikacji + wysokie wynagrodzenie → HIGH risk!"]} {
    object.get(input.vendor, "no_qualifications_high_salary", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.spouse_no_evidence_nkup","package":"jdg.family.hyper","priority":1199,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Małżonek — brak dowodów → NKUP","_legal_basis":"Art. 23 ust. 1 pkt 10 PIT","_warnings":["Brak dowodów pracy małżonka → NKUP!"]} {
    object.get(input.vendor, "no_work_evidence", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.spouse_contract_employment","package":"jdg.family.hyper","priority":1200,"_routing":"","_routing_reason":"Małżonek — umowa o pracę","_legal_basis":"KP + PIT","_warnings":["Umowa o pracę z małżonkiem → pełny ZUS, PIT-4R"]} {
    object.get(input.vendor, "contract_type", "") == "EMPLOYMENT"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.spouse_contract_b2b","package":"jdg.family.hyper","priority":1201,"_routing":"","_routing_reason":"Małżonek — B2B","_legal_basis":"PIT","_warnings":["Umowa B2B z małżonkiem → osobna JDG, ZUS własny"]} {
    object.get(input.vendor, "contract_type", "") == "B2B"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.spouse_contract_mandate","package":"jdg.family.hyper","priority":1202,"_routing":"","_routing_reason":"Małżonek — zlecenie","_legal_basis":"SUS","_warnings":["Umowa zlecenie z małżonkiem → ZUS od zlecenia"]} {
    object.get(input.vendor, "contract_type", "") == "MANDATE"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.child_under26_risk","package":"jdg.family.hyper","priority":1203,"_routing":"WARNING","_routing_reason":"Dziecko <26 → podwyższone ryzyko","_legal_basis":"Art. 23 PIT","_warnings":["Zatrudnienie dziecka <26 lat → podwyższone ryzyko kontroli"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.child_work_evidence","package":"jdg.family.hyper","priority":1204,"_routing":"WARNING","_routing_reason":"Dziecko — dowody pracy","_legal_basis":"Art. 22 PIT","_warnings":["Rzeczywiste wykonywanie pracy przez dziecko — dokumentuj"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.child_salary_arm_length","package":"jdg.family.hyper","priority":1205,"_routing":"WARNING","_routing_reason":"Dziecko — wynagrodzenie rynkowe","_legal_basis":"Art. 22 PIT","_warnings":["Wynagrodzenie dziecka musi być rynkowe"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.child_ulga_young_interaction","package":"jdg.family.hyper","priority":1206,"_routing":"","_routing_reason":"Dziecko — ulga dla młodych","_legal_basis":"Art. 21 PIT","_warnings":["Interakcja: pensja + ulga dla młodych (do 85 528 PLN)"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.child_university","package":"jdg.family.hyper","priority":1207,"_routing":"","_routing_reason":"Dziecko — studia","_legal_basis":"Art. 22 PIT","_warnings":["Praca dziecka musi być kompatybilna ze studiami"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.cooperation_zus_person","package":"jdg.family.hyper","priority":1208,"_routing":"","_routing_reason":"Osoba współpracująca — ZUS","_legal_basis":"Art. 8 SUS","_warnings":["Osoba współpracująca → składki ZUS jak za przedsiębiorcę"]} {
    object.get(input.vendor, "is_cooperating_person", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.cooperation_zus_health","package":"jdg.family.hyper","priority":1209,"_routing":"","_routing_reason":"Osoba współpracująca — zdrowotna","_legal_basis":"Art. 82 u.ś.o.z.","_warnings":["Osoba współpracująca → składka zdrowotna 9%"]} {
    object.get(input.vendor, "is_cooperating_person", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.cooperation_notification_7days","package":"jdg.family.hyper","priority":1210,"_routing":"WARNING","_routing_reason":"Zgłoszenie w 7 dni","_legal_basis":"Art. 36 SUS","_warnings":["Zgłoś osobę współpracującą w ZUS w 7 dni"]} {
    object.get(input.vendor, "is_cooperating_person", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.cooperation_pit_treatment","package":"jdg.family.hyper","priority":1211,"_routing":"","_routing_reason":"Osoba współpracująca — KUP","_legal_basis":"Art. 22 PIT","_warnings":["Wynagrodzenie osoby współpracującej = KUP JDG"]} {
    object.get(input.vendor, "is_cooperating_person", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.car_75pct_kup","package":"jdg.family.hyper","priority":1212,"_routing":"","_routing_reason":"Auto rodzinne — 75% KUP","_legal_basis":"Art. 23 PIT","_warnings":["Auto używane przez rodzinę → 75% KUP"]} {
    object.get(input.invoice, "expense_type", "") == "CAR_USAGE"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.car_mileage_log","package":"jdg.family.hyper","priority":1213,"_routing":"","_routing_reason":"Ewidencja przebiegu","_legal_basis":"Art. 23 PIT","_warnings":["Ewidencja przebiegu z rozróżnieniem służbowe/prywatne"]} {
    object.get(input.invoice, "expense_type", "") == "CAR_USAGE"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.car_vat_50pct","package":"jdg.family.hyper","priority":1214,"_routing":"","_routing_reason":"VAT od auta — 50%","_legal_basis":"Art. 86a VAT","_warnings":["VAT od auta rodzinnego → 50% odliczenia"]} {
    object.get(input.invoice, "expense_type", "") == "CAR_USAGE"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.asset_gift_spouse","package":"jdg.family.hyper","priority":1215,"_routing":"","_routing_reason":"Darowizna dla małżonka — grupa 0","_legal_basis":"SD-Z2","_warnings":["Darowizna dla małżonka → grupa 0, SD-Z2 w 6 mies."]} {
    object.get(input.vendor, "asset_transfer_type", "") == "GIFT_SPOUSE"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.asset_gift_children","package":"jdg.family.hyper","priority":1216,"_routing":"","_routing_reason":"Darowizna dla dzieci — grupa 0","_legal_basis":"SD-Z2","_warnings":["Darowizna dla dzieci → grupa 0, SD-Z2 w 6 mies."]} {
    object.get(input.vendor, "asset_transfer_type", "") == "GIFT_CHILDREN"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.asset_sale_arm_length","package":"jdg.family.hyper","priority":1217,"_routing":"WARNING","_routing_reason":"Sprzedaż rodzinie — cena rynkowa","_legal_basis":"Art. 14 PIT","_warnings":["Sprzedaż majątku rodzinie → cena rynkowa obowiązkowa"]} {
    object.get(input.vendor, "asset_transfer_type", "") == "SALE"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.asset_sale_vat","package":"jdg.family.hyper","priority":1218,"_routing":"","_routing_reason":"Sprzedaż — VAT","_legal_basis":"Art. 5 VAT","_warnings":["Sprzedaż majątku firmowego rodzinie → VAT należny"]} {
    object.get(input.vendor, "asset_transfer_type", "") == "SALE"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.asset_pcc_exemption","package":"jdg.family.hyper","priority":1219,"_routing":"","_routing_reason":"PCC — zwolnienie grupa 0","_legal_basis":"Ustawa o PCC","_warnings":["PCC — zwolnienie w grupie 0: małżonek, dzieci, rodzice"]} {
    object.get(input.vendor, "asset_transfer_type", "") != ""
}
else := {"matched":true,"rule_id":"jdg.family.hyper.joint_filing_conditions","package":"jdg.family.hyper","priority":1220,"_routing":"","_routing_reason":"Wspólne PIT — warunki","_legal_basis":"Art. 6 ust. 2 PIT","_warnings":["Małżeństwo cały rok, wspólność majątkowa"]} {
    object.get(input.jdg_entrepreneur, "joint_pit", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.joint_filing_benefit","package":"jdg.family.hyper","priority":1221,"_routing":"","_routing_reason":"Wspólne PIT — korzyść","_legal_basis":"Art. 6 PIT","_warnings":["Podwójny próg (240k), podwójna kwota wolna (60k)"]} {
    object.get(input.jdg_entrepreneur, "joint_pit", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.joint_filing_deadline_april30","package":"jdg.family.hyper","priority":1222,"_routing":"WARNING","_routing_reason":"Wspólne PIT — 30 kwietnia","_legal_basis":"Art. 45 PIT","_warnings":["PIT-36 z adnotacją o wspólnym rozliczeniu — do 30.04"]} {
    object.get(input.jdg_entrepreneur, "joint_pit", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.joint_filing_exclusions","package":"jdg.family.hyper","priority":1223,"_routing":"","_routing_reason":"Wspólne PIT — wyłączenia","_legal_basis":"Art. 6 PIT","_warnings":["Liniowy, ryczałt, karta → NIE wspólne rozliczenie"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_LINEAR"
}
else := {"matched":true,"rule_id":"jdg.family.hyper.single_parent_calculation","package":"jdg.family.hyper","priority":1224,"_routing":"","_routing_reason":"Samotny rodzic — podwójna kwota","_legal_basis":"Art. 6 PIT","_warnings":["Samotny rodzic: podwójna kwota wolna"]} {
    object.get(input.jdg_entrepreneur, "single_parent", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.single_parent_custody","package":"jdg.family.hyper","priority":1225,"_routing":"","_routing_reason":"Samotny rodzic — opieka","_legal_basis":"Art. 6 PIT","_warnings":["Wymagane: faktyczne sprawowanie opieki nad dzieckiem"]} {
    object.get(input.jdg_entrepreneur, "single_parent", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.health_insurance_family","package":"jdg.family.hyper","priority":1226,"_routing":"","_routing_reason":"Zgłoszenie rodziny do ubezp.","_legal_basis":"u.ś.o.z.","_warnings":["Zgłoś członków rodziny do ubezpieczenia zdrowotnego"]} {
    object.get(input.jdg_entrepreneur, "family_health_insured", false) == false
}
else := {"matched":true,"rule_id":"jdg.family.hyper.health_insurance_not_kup","package":"jdg.family.hyper","priority":1227,"_routing":"","_routing_reason":"Zdrowotna za rodzinę ≠ KUP","_legal_basis":"Art. 23 PIT","_warnings":["Składka zdrowotna za członków rodziny NIE jest KUP"]} {
    object.get(input.jdg_entrepreneur, "family_health_insured", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.pit4r_obligation","package":"jdg.family.hyper","priority":1228,"_routing":"WARNING","_routing_reason":"PIT-4R przy zatrudnieniu","_legal_basis":"Art. 38 PIT","_warnings":["Obowiązek PIT-4R przy zatrudnieniu członków rodziny"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}
else := {"matched":true,"rule_id":"jdg.family.hyper.pit11_deadline_feb28","package":"jdg.family.hyper","priority":1229,"_routing":"WARNING","_routing_reason":"PIT-11 — 28 lutego","_legal_basis":"Art. 39 PIT","_warnings":["PIT-11 dla członków rodziny do 28 lutego"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}
else := {"matched":true,"rule_id":"jdg.family.hyper.succession_inheritance","package":"jdg.family.hyper","priority":1230,"_routing":"","_routing_reason":"Spadek — zwolnienie grupa 0","_legal_basis":"SD","_warnings":["Przekazanie JDG w spadku → zwolnienie grupa 0"]} {
    object.get(input.document, "inheritance_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.succession_sdz2_6months","package":"jdg.family.hyper","priority":1231,"_routing":"WARNING","_routing_reason":"SD-Z2 — 6 miesięcy","_legal_basis":"SD","_warnings":["Zgłoszenie SD-Z2 w ciągu 6 miesięcy od nabycia!"]} {
    object.get(input.document, "inheritance_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.succession_business_continuity","package":"jdg.family.hyper","priority":1232,"_routing":"TRIAGE_QUEUE","_routing_reason":"Zarządca sukcesyjny","_legal_basis":"Prawo przedsiębiorców","_warnings":["Ciągłość JDG po śmierci: zarządca sukcesyjny"]} {
    object.get(input.document, "succession_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.family.hyper.multi_generation_tax_planning","package":"jdg.family.hyper","priority":1233,"_routing":"","_routing_reason":"Optymalizacja wielopokoleniowa","_legal_basis":"PIT","_warnings":["Optymalizacja podatkowa przez zatrudnienie różnych pokoleń"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}
else := {"matched":true,"rule_id":"jdg.family.hyper.aggregate_risk","package":"jdg.family.hyper","priority":1234,"_routing":"WARNING","_routing_reason":"Łączne ryzyko transakcji rodzinnych","_legal_basis":"PIT","_warnings":["Łączna ocena ryzyka podatkowego transakcji rodzinnych"]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}
