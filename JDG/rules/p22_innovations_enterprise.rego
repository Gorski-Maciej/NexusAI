# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P22 Enterprise Innovations: Force Majeure + Family + e-Delivery
# 12 Innowacji ENTERPRISE (R2201-R2248)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.p22_innovations
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.p22_innovations.no_match","package":"jdg.p22_innovations","priority":99999}

# ══ INNOVATION 1: Force Majeure Auto-Detector + Deadline Extender (R2201-R2205) ══
decide := {"matched":true,"rule_id":"jdg.p22_innovations.fm_auto_detector_rcb_imgw","package":"jdg.p22_innovations","priority":2201,"_routing":"TRIAGE_QUEUE","_routing_reason":"FM Auto-Detector: RCB/IMGW/MF","_legal_basis":"Art. 67a OP","_warnings":["Siła wyższa — automatyczna detekcja: RCB (alerty), IMGW (powodzie), komunikaty MF. Uruchom procedurę ulg (67a OP)"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_auto_detected", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.fm_relief_application_generator","package":"jdg.p22_innovations","priority":2202,"_routing":"TRIAGE_QUEUE","_routing_reason":"FM: generator wniosków ulgowych","_legal_basis":"Art. 67a-67e OP","_warnings":["Generator wniosków: odroczenie (67a §1 pkt 1), raty (67a §1 pkt 2), umorzenie (67d). Wybierz typ ulgi na podstawie oceny wpływu"]} {
    object.get(input.jdg_entrepreneur, "relief_application_needed", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.fm_deadline_auto_extender","package":"jdg.p22_innovations","priority":2203,"_routing":"","_routing_reason":"FM: auto-przedłużanie terminów","_legal_basis":"Rozporządzenia MF","_warnings":["Automatyczne stosowanie przedłużonych terminów na podstawie komunikatów MF. Monitoruj Dz.Urz. MF"]} {
    object.get(input.jdg_entrepreneur, "mf_deadline_extension_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.fm_damage_tracker_insurance","package":"jdg.p22_innovations","priority":2204,"_routing":"WARNING","_routing_reason":"FM: tracker szkód i ubezpieczeń","_legal_basis":"Art. 22 PIT","_warnings":["Tracker szkód: oszacuj straty, sprawdź polisy (business interruption), zgłoś szkodę w terminie umownym"]} {
    object.get(input.jdg_entrepreneur, "damage_assessment_ready", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.fm_loss_carry_forward_optimizer","package":"jdg.p22_innovations","priority":2205,"_routing":"","_routing_reason":"FM: optymalizator strat (carry-forward)","_legal_basis":"Art. 9 ust. 3 PIT","_warnings":["Optymalizacja straty z siły wyższej: odliczenie w 5 kolejnych latach, max 50% rocznie. Zaplanuj harmonogram odliczeń dla maksymalnej korzyści podatkowej"]} {
    object.get(input.jdg_entrepreneur, "loss_optimization_requested", false) == true
}

# ══ INNOVATION 2: Family Benefits Maximizer (R2206-R2210) — naprawa L-FAM-1 ══
else := {"matched":true,"rule_id":"jdg.p22_innovations.family_benefits_calculator_27f","package":"jdg.p22_innovations","priority":2206,"_routing":"TRIAGE_QUEUE","_routing_reason":"Family: kalkulator ulgi 27f","_legal_basis":"Art. 27f PIT","_warnings":["Kalkulator ulgi prorodzinnej: 1112,04 PLN/rok na 2+ dziecko. 1. dziecko tylko przy dochodzie ≤112k. Zwrot max 1/6 podatku. Wypełnij PIT/O"]} {
    object.get(input.jdg_entrepreneur, "family_benefits_calculation_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.family_4plus_simulator","package":"jdg.p22_innovations","priority":2207,"_routing":"TRIAGE_QUEUE","_routing_reason":"Family: symulator ulgi 4+","_legal_basis":"Art. 21 ust. 1 pkt 153 PIT","_warnings":["Symulator ulgi dla rodzin 4+: zwolnienie do 85 528 PLN przychodów. Porównaj: skala (12/32%) vs liniowy (19%) vs ryczałt. Wybierz optymalną formę opodatkowania"]} {
    object.get(input.jdg_entrepreneur, "family_4plus_simulation_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.family_joint_filing_optimizer","package":"jdg.p22_innovations","priority":2208,"_routing":"","_routing_reason":"Family: optymalizacja wspólnego PIT","_legal_basis":"Art. 6 ust. 2 PIT","_warnings":["Optymalizacja wspólnego rozliczenia: podwójna kwota wolna (60k), podwójny próg (240k). Zysk: X PLN rocznie vs rozliczenie indywidualne"]} {
    object.get(input.jdg_entrepreneur, "joint_filing_optimization_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.family_pit_o_autogenerator","package":"jdg.p22_innovations","priority":2209,"_routing":"","_routing_reason":"Family: auto-generator PIT/O","_legal_basis":"Art. 27f ust. 6 PIT","_warnings":["Generator załącznika PIT/O: PESEL dzieci, liczba miesięcy opieki, kwota ulgi. Dołącz do PIT-36 przed 30 kwietnia"]} {
    object.get(input.jdg_entrepreneur, "pit_o_autogeneration_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.family_multi_generation_strategy","package":"jdg.p22_innovations","priority":2210,"_routing":"","_routing_reason":"Family: strategia wielopokoleniowa","_legal_basis":"PIT","_warnings":["Strategia wielopokoleniowa: zatrudnienie małżonka (B2B/umowa), dzieci (ulga dla młodych), rodziców (opieka). Maksymalizacja ulg rodzinnych łącznie"]} {
    object.get(input.jdg_entrepreneur, "multi_generation_strategy_requested", false) == true
}

# ══ INNOVATION 3: E-Delivery Auto-Integration (R2211-R2214) ══
else := {"matched":true,"rule_id":"jdg.p22_innovations.edelivery_bae_api_monitor","package":"jdg.p22_innovations","priority":2211,"_routing":"TRIAGE_QUEUE","_routing_reason":"e-Delivery: monitor BAE API","_legal_basis":"Ustawa o doręczeniach el.","_warnings":["Monitor BAE: codzienne sprawdzanie skrzynki e-Doręczeń. Alerty: 7 dni, 3 dni, 1 dzień przed fikcją. Fikcja doręczenia po 14 dniach!"]} {
    object.get(input.jdg_entrepreneur, "bae_monitoring_active", false) == false
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.edelivery_outbox_dispatcher","package":"jdg.p22_innovations","priority":2212,"_routing":"","_routing_reason":"e-Delivery: warstwa wysyłkowa (L6 fix)","_legal_basis":"Ustawa o doręczeniach el.","_warnings":["Automatyczna wysyłka pism do US przez e-Doręczenia: odwołania, wnioski, deklaracje. UPO jako potwierdzenie. Zachowaj kopię w archiwum 5 lat"]} {
    object.get(input.jdg_entrepreneur, "outbox_dispatch_ready", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.edelivery_cascade_alert_system","package":"jdg.p22_innovations","priority":2213,"_routing":"BLOCK_AND_ALERT","_routing_reason":"e-Delivery: kaskada alertów","_legal_basis":"Ustawa o doręczeniach el.","_warnings":["Kaskada alertów: 7 dni (WARNING) → 3 dni (TRIAGE) → 1 dzień (BLOCK) → 0 dni (FIKCJA). Nie przegap! Konsekwencje: bieg terminów bez Twojej wiedzy"]} {
    object.get(input.jdg_entrepreneur, "unread_letters_count", 0) > 0
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.edelivery_eus_dashboard","package":"jdg.p22_innovations","priority":2214,"_routing":"","_routing_reason":"e-Delivery: pulpit e-US zintegrowany","_legal_basis":"Ustawa o KAS","_warnings":["Pulpit e-US: pisma, deklaracje, pełnomocnictwa, płatności, certyfikaty — wszystko w jednym miejscu. Integracja z kalendarzem terminów"]} {
    object.get(input.jdg_entrepreneur, "eus_dashboard_active", false) == false
}

# ══ INNOVATION 4: Digital Signature Auto-Applicator (R2215-R2218) ══
else := {"matched":true,"rule_id":"jdg.p22_innovations.esig_auto_sign_documents","package":"jdg.p22_innovations","priority":2215,"_routing":"","_routing_reason":"eSig: auto-podpisywanie dokumentów","_legal_basis":"eIDAS 910/2014","_warnings":["Auto-podpisywanie: wybierz typ podpisu (kwalifikowany vs profil zaufany) na podstawie typu dokumentu. KSeF token dla JPK, kwalifikowany dla UPL-1"]} {
    object.get(input.jdg_entrepreneur, "auto_sign_enabled", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.esig_certificate_monitor","package":"jdg.p22_innovations","priority":2216,"_routing":"WARNING","_routing_reason":"eSig: monitoring certyfikatów","_legal_basis":"eIDAS","_warnings":["Monitoring certyfikatów kwalifikowanych: 90 dni, 30 dni, 7 dni przed wygaśnięciem. Dostawcy: Certum, Szafir, ProCertum. Odnów przed terminem!"]} {
    object.get(input.jdg_entrepreneur, "certificate_expiry_days", 0) <= 90
    object.get(input.jdg_entrepreneur, "certificate_expiry_days", 0) > 0
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.esig_provider_integration","package":"jdg.p22_innovations","priority":2217,"_routing":"","_routing_reason":"eSig: integracja dostawców (L5 fix)","_legal_basis":"eIDAS","_warnings":["Integracja z dostawcami podpisu: Certum (SimplySign), Szafir (KIR), ProCertum. Automatyczne odnowienie, lista TSL, weryfikacja cross-border"]} {
    object.get(input.jdg_entrepreneur, "signature_provider_connected", false) == false
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.esig_document_registry","package":"jdg.p22_innovations","priority":2218,"_routing":"","_routing_reason":"eSig: rejestr podpisanych dokumentów","_legal_basis":"eIDAS","_warnings":["Rejestr podpisanych dokumentów: data, typ podpisu, certyfikat, dokument. Wartość dowodowa + integralność. Retencja 5 lat"]} {
    object.get(input.jdg_entrepreneur, "document_registry_needed", false) == true
}

# ══ INNOVATION 5: Seasonal Business Optimizer (R2219-R2222) — naprawa R-SEAS-1 ══
else := {"matched":true,"rule_id":"jdg.p22_innovations.seasonal_suspension_simulator_24months","package":"jdg.p22_innovations","priority":2219,"_routing":"TRIAGE_QUEUE","_routing_reason":"Seasonal: symulator zawieszenia 24 mies.","_legal_basis":"Art. 22 PP","_warnings":["Symulator zawieszenia: limit 24 miesiące łącznie (Art. 22 PP). Składka zdrowotna nadal należna. Porównaj koszty: zawieszenie vs zamknięcie i ponowne otwarcie"]} {
    object.get(input.jdg_entrepreneur, "seasonal_suspension_simulation_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.seasonal_simplified_advances_planner","package":"jdg.p22_innovations","priority":2220,"_routing":"","_routing_reason":"Seasonal: planer zaliczek uproszczonych","_legal_basis":"Art. 44 ust. 6b PIT","_warnings":["Planer zaliczek uproszczonych: stała kwota miesięczna = 1/12 podatku z poprzedniego roku. Unikaj wahań cashflow w sezonie. Złóż wniosek do 20 lutego"]} {
    object.get(input.jdg_entrepreneur, "simplified_advances_planning_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.seasonal_zus_health_calculator","package":"jdg.p22_innovations","priority":2221,"_routing":"","_routing_reason":"Seasonal: kalkulator ZUS w zawieszeniu","_legal_basis":"Art. 81 ust. 2e u.ś.o.z.","_warnings":["Kalkulator ZUS sezonowego: składka zdrowotna od rzeczywistego dochodu z aktywnych miesięcy. Mały ZUS Plus: test przychodu ≤120k rocznie"]} {
    object.get(input.jdg_entrepreneur, "zus_seasonal_calculation_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.seasonal_reopening_checklist","package":"jdg.p22_innovations","priority":2222,"_routing":"WARNING","_routing_reason":"Seasonal: checklista wznowienia","_legal_basis":"Art. 22 PP + Art. 96 VAT","_warnings":["Checklista wznowienia po sezonie: 1) odwieszenie CEIDG, 2) ZUS ZUA (7 dni), 3) VAT-R jeśli utracono zwolnienie, 4) aktualizacja BAE e-Doręczeń"]} {
    object.get(input.jdg_entrepreneur, "seasonal_reopening_planned", false) == true
}

# ══ INNOVATION 6: TAX FREE Tourist Auto-Processor (R2223-R2226) — naprawa L-TF-1 ══
else := {"matched":true,"rule_id":"jdg.p22_innovations.tourist_taxfree_detector","package":"jdg.p22_innovations","priority":2223,"_routing":"TRIAGE_QUEUE","_routing_reason":"TAX FREE: detektor sprzedaży turystycznej","_legal_basis":"Art. 126-130 VAT","_warnings":["Detektor TAX FREE: automatyczna detekcja turysty spoza UE (paszport). Min. 200 PLN netto na paragonie. Generuj dokument TAX FREE (oryginał + 2 kopie)"]} {
    object.get(input.invoice, "taxfree_eligible_transaction", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.tourist_taxfree_document_autogen","package":"jdg.p22_innovations","priority":2224,"_routing":"WARNING","_routing_reason":"TAX FREE: auto-generator dokumentu","_legal_basis":"Art. 128 VAT","_warnings":["Auto-generator dokumentu TAX FREE: dane paszportowe, kwota netto/VAT, stawka zwrotu. Termin wywozu: 3 miesiące. Potwierdzenie celne wymagane"]} {
    object.get(input.invoice, "taxfree_document_autogen_ready", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.tourist_taxfree_refund_calculator","package":"jdg.p22_innovations","priority":2225,"_routing":"","_routing_reason":"TAX FREE: kalkulator zwrotu VAT","_legal_basis":"Art. 129 VAT","_warnings":["Kalkulator zwrotu VAT: 23%→18.7%, 8%→6.5%, 5%→4.1%. Wypłata gotówkowa lub na konto w 7 dni. Ewidencja miesięczna + JPK_V7 z oznaczeniem TF"]} {
    object.get(input.invoice, "taxfree_refund_calculation_ready", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.tourist_taxfree_jpk_integration","package":"jdg.p22_innovations","priority":2226,"_routing":"","_routing_reason":"TAX FREE: integracja JPK_V7 + kasa","_legal_basis":"Art. 99 VAT + Art. 111 VAT","_warnings":["Integracja TAX FREE: kasa fiskalna online + paragon TAX FREE + JPK_V7 z oznaczeniem TF. Miesięczny raport sprzedaży turystycznej"]} {
    object.get(input.jdg_entrepreneur, "taxfree_jpk_integration_active", false) == false
}

# ══ INNOVATION 7: Employer Obligation Tracker (R2227-R2230) ══
else := {"matched":true,"rule_id":"jdg.p22_innovations.employer_obligation_calendar","package":"jdg.p22_innovations","priority":2227,"_routing":"WARNING","_routing_reason":"Employer: kalendarz obowiązków","_legal_basis":"KP + SUS + PIT","_warnings":["Kalendarz obowiązków pracodawcy: ZUS ZUA (7 dni od zatrudnienia), DRA (do 15.), PIT-4R (do 20.), PIT-11 (do 31.01.). Alerty przeddeadlinowe"]} {
    object.get(input.jdg_entrepreneur, "employer_obligation_tracker_active", false) == false
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.employer_sick_leave_manager","package":"jdg.p22_innovations","priority":2228,"_routing":"","_routing_reason":"Employer: obsługa chorobowego (L7 fix)","_legal_basis":"Art. 92 KP + ZUS ZLA","_warnings":["Obsługa wynagrodzeń chorobowych: ZUS ZLA (e-ZLA), 33 dni (14 dni po 50 r.ż.) = wynagrodzenie pracodawcy, potem zasiłek ZUS. Dokumentuj w DRA"]} {
    object.get(input.jdg_entrepreneur, "employee_sick_leave_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.employer_ppk_pfron_auto","package":"jdg.p22_innovations","priority":2229,"_routing":"","_routing_reason":"Employer: PPK + PFRON auto","_legal_basis":"Ustawa o PPK + ustawa o PFRON","_warnings":["Automat PPK/PFRON: PPK auto-zapis co 4 lata, PFRON składka (6% wynagrodzeń) przy <6% osób z niepełnosprawnością. Zwolnienie ZPChr"]} {
    object.get(input.jdg_entrepreneur, "ppk_pfron_auto_check_needed", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.employer_declaration_generator","package":"jdg.p22_innovations","priority":2230,"_routing":"","_routing_reason":"Employer: generator deklaracji","_legal_basis":"PIT + SUS","_warnings":["Generator deklaracji: PIT-4R (miesięcznie), PIT-11 (rocznie), ZUS DRA + RCA. Dane z ewidencji pracowników. Eksport do XML CSV"]} {
    object.get(input.jdg_entrepreneur, "auto_declaration_generation_requested", false) == true
}

# ══ INNOVATION 8: Power of Attorney Manager (R2231-R2234) ══
else := {"matched":true,"rule_id":"jdg.p22_innovations.poa_registry_monitor","package":"jdg.p22_innovations","priority":2231,"_routing":"WARNING","_routing_reason":"POA: rejestr pełnomocnictw","_legal_basis":"Art. 138b-138o OrdPU","_warnings":["Rejestr pełnomocnictw: PPS-1 (ogólne, 17 zł), UPL-1 (szczególne, 17 zł), PPD-1 (doręczenia), OPP-1 (odwołanie). Monitoruj daty ważności"]} {
    object.get(input.jdg_entrepreneur, "poa_registry_active", false) == false
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.poa_auto_form_generator","package":"jdg.p22_innovations","priority":2232,"_routing":"","_routing_reason":"POA: auto-generator formularzy","_legal_basis":"Art. 138b OrdPU","_warnings":["Auto-generator formularzy: PPS-1/UPL-1/PPD-1/OPP-1. Podpis kwalifikowany dla UPL-1. Opłata skarbowa 17 zł. Złóż przez ePUAP"]} {
    object.get(input.jdg_entrepreneur, "poa_form_autogen_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.poa_expiry_alert_system","package":"jdg.p22_innovations","priority":2233,"_routing":"BLOCK_AND_ALERT","_routing_reason":"POA: alerty wygaśnięcia","_legal_basis":"Art. 138o OrdPU","_warnings":["Alert wygaśnięcia pełnomocnictwa: 30 dni, 7 dni, 1 dzień. Wygaśnięcie = brak reprezentacji przed US! Odnów UPL-1 przed terminem"]} {
    object.get(input.jdg_entrepreneur, "poa_expiry_days", 0) <= 30
    object.get(input.jdg_entrepreneur, "poa_expiry_days", 0) > 0
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.poa_cross_border_validator","package":"jdg.p22_innovations","priority":2234,"_routing":"","_routing_reason":"POA: walidator transgraniczny","_legal_basis":"eIDAS + OrdPU","_warnings":["Walidator pełnomocnictw transgranicznych: apostille, tłumaczenie przysięgłe, eIDAS dla UE. Sprawdź wymogi kraju kontrahenta"]} {
    object.get(input.jdg_entrepreneur, "cross_border_poa_needed", false) == true
}

# ══ INNOVATION 9: Restructuring Tax Impact Analyzer (R2235-R2238) ══
else := {"matched":true,"rule_id":"jdg.p22_innovations.restructuring_transformation_analyzer","package":"jdg.p22_innovations","priority":2235,"_routing":"TRIAGE_QUEUE","_routing_reason":"Restructuring: analiza przekształcenia","_legal_basis":"Art. 112 OrdPU + Art. 24 ust. 3 PIT","_warnings":["Analiza przekształcenia JDG→sp. z o.o.: bilans otwarcia (wycena rynkowa), remanent likwidacyjny (10% PIT), sukcesja NIP, PCC zwolnione (Art. 6 pkt 1)"]} {
    object.get(input.jdg_entrepreneur, "transformation_analysis_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.restructuring_remanent_calculator","package":"jdg.p22_innovations","priority":2236,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Restructuring: kalkulator remanentu 10%","_legal_basis":"Art. 24 ust. 3 PIT","_warnings":["Kalkulator remanentu likwidacyjnego: nadwyżka wartości rynkowej nad kosztami = 10% PIT. Zaplanuj optymalny moment przekształcenia (rok podatkowy)"]} {
    object.get(input.jdg_entrepreneur, "remanent_calculation_ready", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.restructuring_aport_real_estate_pcc","package":"jdg.p22_innovations","priority":2237,"_routing":"WARNING","_routing_reason":"Restructuring: aport nieruchomości (L8 fix)","_legal_basis":"Art. 6 pkt 1 PCC + Art. 2 pkt 6 VAT","_warnings":["Aport nieruchomości do spółki: PCC 2% od wartości rynkowej (jeśli nie podlega VAT). Sprawdź: VAT 23% dla budynków komercyjnych (zwolnienie po 2 latach). Optymalizuj strukturę"]} {
    object.get(input.jdg_entrepreneur, "aport_real_estate_planned", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.restructuring_succession_pipeline","package":"jdg.p22_innovations","priority":2238,"_routing":"TRIAGE_QUEUE","_routing_reason":"Restructuring: pipeline sukcesji","_legal_basis":"Ustawa o zarządzie sukcesyjnym","_warnings":["Pipeline sukcesji: zarządca sukcesyjny (2 mies. od śmierci), zgłoszenie CEIDG, max 2 lata prowadzenia. Małoletni spadkobiercy → zgoda sądu (Art. 98 KRO). Spadek → SD-Z2 (6 mies.)"]} {
    object.get(input.document, "succession_pipeline_active", false) == true
}

# ══ INNOVATION 10: Special Situation Decision Tree (R2239-R2241) ══
else := {"matched":true,"rule_id":"jdg.p22_innovations.special_situation_triage","package":"jdg.p22_innovations","priority":2239,"_routing":"TRIAGE_QUEUE","_routing_reason":"SpecSit: triage zdarzeń nadzwyczajnych","_legal_basis":"—","_warnings":["Triage sytuacji specjalnych: siła wyższa, sezonowość, restrukturyzacja, sukcesja. Mapowanie do odpowiednich modułów P22. Priorytetyzacja wg pilności"]} {
    object.get(input.jdg_entrepreneur, "special_situation_detected", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.special_situation_risk_matrix","package":"jdg.p22_innovations","priority":2240,"_routing":"WARNING","_routing_reason":"SpecSit: macierz ryzyka","_legal_basis":"—","_warnings":["Macierz ryzyka sytuacji specjalnych: fikcja doręczenia (WYSOKIE), utrata ulg rodzinnych (WYSOKIE), wygaśnięcie podpisu (ŚREDNIE), strata sezonowa (ŚREDNIE)"]} {
    object.get(input.jdg_entrepreneur, "risk_matrix_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.special_situation_calendar","package":"jdg.p22_innovations","priority":2241,"_routing":"","_routing_reason":"SpecSit: kalendarz sytuacji specjalnych","_legal_basis":"—","_warnings":["Kalendarz sytuacji specjalnych: terminy zawieszenia (24 mies.), fikcji doręczeń (14 dni), sukcesji (2 mies./2 lata), wygaśnięcia certyfikatów, pełnomocnictw"]} {
    object.get(input.jdg_entrepreneur, "special_situation_calendar_active", false) == false
}

# ══ INNOVATION 11: Family Succession Planner (R2242-R2245) ══
else := {"matched":true,"rule_id":"jdg.p22_innovations.family_succession_manager_tracker","package":"jdg.p22_innovations","priority":2242,"_routing":"TRIAGE_QUEUE","_routing_reason":"Family: tracker zarządcy sukcesyjnego","_legal_basis":"Art. 51-54 u.z.s.","_warnings":["Tracker zarządcy sukcesyjnego: 2 miesiące na powołanie, zgłoszenie CEIDG-1, max 2 lata prowadzenia. Przedłużenie możliwe tylko za zgodą sądu"]} {
    object.get(input.document, "succession_manager_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.family_donation_planner","package":"jdg.p22_innovations","priority":2243,"_routing":"","_routing_reason":"Family: planer darowizn rodzinnych","_legal_basis":"Ustawa o SD + Ustawa o PCC","_warnings":["Planer darowizn: grupa 0 (małżonek, dzieci, rodzice) = SD zwolnione + PCC zwolnione. SD-Z2 w 6 mies. dla kwot >9 637 PLN (grupa 1) lub > 36 120 PLN (pozostali)"]} {
    object.get(input.jdg_entrepreneur, "donation_planning_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.family_inheritance_tax_optimizer","package":"jdg.p22_innovations","priority":2244,"_routing":"","_routing_reason":"Family: optymalizator spadkowy","_legal_basis":"SD + KRO","_warnings":["Optymalizator spadkowy: grupa 0 (zwolnienie SD), małoletni spadkobiercy (zgoda sądu), zarządca sukcesyjny (ciągłość JDG). Zaplanuj testament przedsiębiorcy"]} {
    object.get(input.document, "inheritance_planning_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.family_business_continuity_bia","package":"jdg.p22_innovations","priority":2245,"_routing":"WARNING","_routing_reason":"Family: analiza ciągłości (BIA)","_legal_basis":"—","_warnings":["Business Impact Analysis: co jeśli przedsiębiorca umrze/zachoruje? Plan ciągłości: zarządca sukcesyjny, pełnomocnictwa, dostęp do kont, dokumentacja"]} {
    object.get(input.jdg_entrepreneur, "business_continuity_bia_requested", false) == true
}

# ══ INNOVATION 12: Digital Document Vault (R2246-R2248) ══
else := {"matched":true,"rule_id":"jdg.p22_innovations.vault_5year_archive","package":"jdg.p22_innovations","priority":2246,"_routing":"","_routing_reason":"Vault: archiwum 5 lat","_legal_basis":"Art. 86 OrdPU","_warnings":["Archiwum cyfrowe 5 lat: dokumenty księgowe, deklaracje PIT/VAT/ZUS, faktury, umowy. Szyfrowanie AES-256. Indeksowanie full-text. Retencja zgodna z OrdPU"]} {
    object.get(input.jdg_entrepreneur, "digital_archive_active", false) == false
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.vault_disaster_recovery","package":"jdg.p22_innovations","priority":2247,"_routing":"TRIAGE_QUEUE","_routing_reason":"Vault: odtworzenie po katastrofie","_legal_basis":"Art. 86 OP","_warnings":["Disaster Recovery: backup off-site + chmura. Procedura odtworzenia dokumentacji po powodzi/pożarze. Zgłoszenie utraty do US w 7 dni. Odtworzenie z kopii zapasowych"]} {
    object.get(input.jdg_entrepreneur, "disaster_recovery_needed", false) == true
}
else := {"matched":true,"rule_id":"jdg.p22_innovations.vault_evidence_value_preserver","package":"jdg.p22_innovations","priority":2248,"_routing":"","_routing_reason":"Vault: wartość dowodowa + integralność","_legal_basis":"Art. 86 OP + eIDAS","_warnings":["Zachowanie wartości dowodowej: podpis elektroniczny + znacznik czasu + integralność plików (hash SHA-256). Metadane: data utworzenia, autor, wersja. Obrona w kontroli"]} {
    object.get(input.jdg_entrepreneur, "evidence_preservation_active", false) == false
}
