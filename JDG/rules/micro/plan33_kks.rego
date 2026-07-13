# Generated from Plan OPA 33 — Micro-rules for kks
# 2026-07-13 14:58:41
# Rules: 64 (new, deduplicated)

package jdg.micro.kks

default decide := {"matched":false,"rule_id":"jdg.micro.kks.no_match","package":"jdg.micro.kks","priority":99999}

# jdg.kks.a54.r1 — `kks_non_declaration_tax_evasion`: Niezlozenie deklaracji podatkowej w terminie -> wykroczenie
decide :=   {"matched":true,"rule_id":"jdg.kks.a54.r1","package":"jdg.micro.kks","priority":3600,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niezlozenie deklaracji podatkowej w terminie -> wykroczenie","_legal_basis":"Art. 54 KKS","_warnings":[]} {
    true
}

# jdg.kks.a54.r2 — `kks_non_declaration_small_10pct_or_less`: Niezlozenie: szkodliwosc spoleczna znikoma (kwota < 10% naleznego podatku) -> brak
else :=   {"matched":true,"rule_id":"jdg.kks.a54.r2","package":"jdg.micro.kks","priority":3601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niezlozenie: szkodliwosc spoleczna znikoma (kwota < 10% naleznego podatku) -> brak","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.a54.r6 — `tax_evasion_hiding_income`: Ukrywanie dochodu/przychodu przed opodatkowaniem -> przestępstwo skarbowe → Grzywna do 720 stawek dziennych lub kara ...
else :=   {"matched":true,"rule_id":"jdg.kks.a54.r6","package":"jdg.micro.kks","priority":3602,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ukrywanie dochodu/przychodu przed opodatkowaniem -> przestępstwo skarbowe","_legal_basis":"Art. 54 par. 1 KKS","_warnings":[]} {
    true
}

# jdg.kks.a54.r7 — `tax_evasion_lesser_offense`: Ukrywanie dochodu/przychodu w małej kwocie (uszczuplenie < 10 000 PLN) → Grzywna do 720 stawek dziennych (wykroczenie...
else :=   {"matched":true,"rule_id":"jdg.kks.a54.r7","package":"jdg.micro.kks","priority":3603,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ukrywanie dochodu/przychodu w małej kwocie (uszczuplenie < 10 000 PLN)","_legal_basis":"Art. 54 par. 2 KKS","_warnings":[]} {
    true
}

# jdg.kks.a54.r8 — `tax_evasion_vat_high_value`: Ukrywanie VAT wysokiej wartości → Kara do 25 lat pozbawienia wolności (zbrodnia)
else :=   {"matched":true,"rule_id":"jdg.kks.a54.r8","package":"jdg.micro.kks","priority":3604,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ukrywanie VAT wysokiej wartości","_legal_basis":"Art. 54 par. 3 KKS","_warnings":[]} {
    true
}

# jdg.kks.a54.r9 — `tax_evasion_active_remorse`: Czynny żal po popełnieniu przestępstwa -> możliwość nadzwyczajnego złagodzenia kary → Łagodzenie kary
else :=   {"matched":true,"rule_id":"jdg.kks.a54.r9","package":"jdg.micro.kks","priority":3605,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny żal po popełnieniu przestępstwa -> możliwość nadzwyczajnego złagodzenia kary","_legal_basis":"Art. 54 par. 4 KKS","_warnings":[]} {
    true
}

# jdg.kks.a55.r10 — `false_invoice_repeat_offender`: Recydywa w wystawianiu pustych faktur → Kara podwyższona o połowę
else :=   {"matched":true,"rule_id":"jdg.kks.a55.r10","package":"jdg.micro.kks","priority":3606,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Recydywa w wystawianiu pustych faktur","_legal_basis":"Art. 55 par. 5 KKS","_warnings":[]} {
    true
}

# jdg.kks.a55.r11 — `false_invoice_active_remorse_disclosure`: Ujawnienie przestępstwa przed US -> możliwość uniknięcia kary → Bezkarność warunkowa
else :=   {"matched":true,"rule_id":"jdg.kks.a55.r11","package":"jdg.micro.kks","priority":3607,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ujawnienie przestępstwa przed US -> możliwość uniknięcia kary","_legal_basis":"Art. 55 par. 6 KKS","_warnings":[]} {
    true
}

# jdg.kks.a55.r6 — `false_invoice_issuing`: Wystawianie pustych faktur (bez dostawy towaru/usługi) → Grzywna do 720 stawek + kara do 5 lat
else :=   {"matched":true,"rule_id":"jdg.kks.a55.r6","package":"jdg.micro.kks","priority":3608,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wystawianie pustych faktur (bez dostawy towaru/usługi)","_legal_basis":"Art. 55 par. 1 KKS","_warnings":[]} {
    true
}

# jdg.kks.a55.r7 — `false_invoice_accepting`: Używanie pustej faktury (świadome odliczenie VAT) → Grzywna do 720 stawek + kara do 5 lat
else :=   {"matched":true,"rule_id":"jdg.kks.a55.r7","package":"jdg.micro.kks","priority":3609,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Używanie pustej faktury (świadome odliczenie VAT)","_legal_basis":"Art. 55 par. 2 KKS","_warnings":[]} {
    true
}

# jdg.kks.a55.r8 — `false_invoice_vat_high_1m`: Pusta faktura na kwotę VAT > 1 000 000 PLN → Kara do 25 lat (zbrodnia)
else :=   {"matched":true,"rule_id":"jdg.kks.a55.r8","package":"jdg.micro.kks","priority":3610,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pusta faktura na kwotę VAT > 1 000 000 PLN","_legal_basis":"Art. 55 par. 3 KKS","_warnings":[]} {
    true
}

# jdg.kks.a55.r9 — `false_invoice_vat_lesser`: Pusta faktura na kwotę VAT < 10 000 PLN → Tylko grzywna (wykroczenie)
else :=   {"matched":true,"rule_id":"jdg.kks.a55.r9","package":"jdg.micro.kks","priority":3611,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pusta faktura na kwotę VAT < 10 000 PLN","_legal_basis":"Art. 55 par. 4 KKS","_warnings":[]} {
    true
}

# jdg.kks.a56.r1 — `kks_false_declaration_tax_fraud`: Grzywna do 720 stawek + kara 30% zanizenia
else :=   {"matched":true,"rule_id":"jdg.kks.a56.r1","package":"jdg.micro.kks","priority":3612,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Grzywna do 720 stawek + kara 30% zanizenia","_legal_basis":"Art. 56 KKS","_warnings":[]} {
    true
}

# jdg.kks.a56.r2 — `kks_false_declaration_small_10pct`: Zanizenie < 10% -> wykroczenie, nie przestepstwo
else :=   {"matched":true,"rule_id":"jdg.kks.a56.r2","package":"jdg.micro.kks","priority":3613,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zanizenie < 10% -> wykroczenie, nie przestepstwo","_legal_basis":"Art. 56 KKS","_warnings":[]} {
    true
}

# jdg.kks.a56.r3 — `kks_false_declaration_huge_loss`: Mala szkoda (do 200 minimalnych) -> wykroczenie
else :=   {"matched":true,"rule_id":"jdg.kks.a56.r3","package":"jdg.micro.kks","priority":3614,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Mala szkoda (do 200 minimalnych) -> wykroczenie","_legal_basis":"Art. 56 KKS","_warnings":[]} {
    true
}

# jdg.kks.a56.r6 — `false_accounting_records`: Prowadzenie nierzetelnej PKPiR/ksiąg rachunkowych → Grzywna do 720 stawek dziennych
else :=   {"matched":true,"rule_id":"jdg.kks.a56.r6","package":"jdg.micro.kks","priority":3615,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Prowadzenie nierzetelnej PKPiR/ksiąg rachunkowych","_legal_basis":"Art. 56 par. 1 KKS","_warnings":[]} {
    true
}

# jdg.kks.a56.r7 — `false_accounting_revenue_hiding`: Zaniżenie przychodów w PKPiR -> przestępstwo → Grzywna + kara do 3 lat
else :=   {"matched":true,"rule_id":"jdg.kks.a56.r7","package":"jdg.micro.kks","priority":3616,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaniżenie przychodów w PKPiR -> przestępstwo","_legal_basis":"Art. 56 par. 2 KKS","_warnings":[]} {
    true
}

# jdg.kks.a56.r8 — `false_accounting_cost_inflation`: Zawyżenie kosztów w PKPiR -> przestępstwo → Grzywna + kara do 3 lat
else :=   {"matched":true,"rule_id":"jdg.kks.a56.r8","package":"jdg.micro.kks","priority":3617,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zawyżenie kosztów w PKPiR -> przestępstwo","_legal_basis":"Art. 56 par. 3 KKS","_warnings":[]} {
    true
}

# jdg.kks.a56.r9 — `false_accounting_document_lack`: Brak dokumentacji źródłowej (faktur, umów) do wpisów w PKPiR → Grzywna
else :=   {"matched":true,"rule_id":"jdg.kks.a56.r9","package":"jdg.micro.kks","priority":3618,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak dokumentacji źródłowej (faktur, umów) do wpisów w PKPiR","_legal_basis":"Art. 56 par. 4 KKS","_warnings":[]} {
    true
}

# jdg.kks.a57.r1 — `kks_vat_fraud_carousel_missing_trader`: Udział w karuzeli VAT (oszustwo na VAT) -> przestepstwo
else :=   {"matched":true,"rule_id":"jdg.kks.a57.r1","package":"jdg.micro.kks","priority":3619,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Udział w karuzeli VAT (oszustwo na VAT) -> przestepstwo","_legal_basis":"Art. 57 KKS","_warnings":[]} {
    true
}

# jdg.kks.a57.r10 — `accounting_books_destroyed`: Zniszczenie ksiąg rachunkowych/PKPiR przed upływem okresu przechowywania → Grzywna do 240 stawek
else :=   {"matched":true,"rule_id":"jdg.kks.a57.r10","package":"jdg.micro.kks","priority":3620,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zniszczenie ksiąg rachunkowych/PKPiR przed upływem okresu przechowywania","_legal_basis":"Art. 57 par. 5 KKS","_warnings":[]} {
    true
}

# jdg.kks.a57.r11 — `accounting_books_falsified`: Fałszowanie zapisów w PKPiR (dopisanie/falsyfikacja wpisów) → Grzywna + kara do 5 lat
else :=   {"matched":true,"rule_id":"jdg.kks.a57.r11","package":"jdg.micro.kks","priority":3621,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Fałszowanie zapisów w PKPiR (dopisanie/falsyfikacja wpisów)","_legal_basis":"Art. 56 par. 5 w zw. z Art. 57 KKS","_warnings":[]} {
    true
}

# jdg.kks.a57.r2 — `kks_vat_fraud_large_scale`: VAT > 10M PLN -> zbrodnia skarbowa
else :=   {"matched":true,"rule_id":"jdg.kks.a57.r2","package":"jdg.micro.kks","priority":3622,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"VAT > 10M PLN -> zbrodnia skarbowa","_legal_basis":"Art. 57 KKS","_warnings":[]} {
    true
}

# jdg.kks.a57.r6 — `vat_evidence_not_kept`: Nieprowadzenie wymaganej ewidencji VAT → Grzywna do 120 stawek dziennych (wykroczenie)
else :=   {"matched":true,"rule_id":"jdg.kks.a57.r6","package":"jdg.micro.kks","priority":3623,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nieprowadzenie wymaganej ewidencji VAT","_legal_basis":"Art. 57 par. 1 KKS","_warnings":[]} {
    true
}

# jdg.kks.a57.r7 — `vat_evidence_incorrect`: Prowadzenie ewidencji VAT niezgodnie z przepisami → Grzywna do 120 stawek
else :=   {"matched":true,"rule_id":"jdg.kks.a57.r7","package":"jdg.micro.kks","priority":3624,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Prowadzenie ewidencji VAT niezgodnie z przepisami","_legal_basis":"Art. 57 par. 2 KKS","_warnings":[]} {
    true
}

# jdg.kks.a57.r8 — `vat_evidence_not_submitted_to_us`: Brak udostępnienia ewidencji VAT na żądanie US → Grzywna do 120 stawek
else :=   {"matched":true,"rule_id":"jdg.kks.a57.r8","package":"jdg.micro.kks","priority":3625,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak udostępnienia ewidencji VAT na żądanie US","_legal_basis":"Art. 57 par. 3 KKS","_warnings":[]} {
    true
}

# jdg.kks.a57.r9 — `vat_evidence_gtu_missing`: Brak wymaganych oznaczeń GTU w JPK_V7 → Grzywna do 60 stawek
else :=   {"matched":true,"rule_id":"jdg.kks.a57.r9","package":"jdg.micro.kks","priority":3626,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak wymaganych oznaczeń GTU w JPK_V7","_legal_basis":"Art. 57 par. 4 w zw. z par. 10 JPK_VAT","_warnings":[]} {
    true
}

# jdg.kks.a58.r1 — `kks_invoice_fraud_false_invoice`: Wystawienie falszywej faktury (bez zdarzenia gospodarczego)
else :=   {"matched":true,"rule_id":"jdg.kks.a58.r1","package":"jdg.micro.kks","priority":3627,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wystawienie falszywej faktury (bez zdarzenia gospodarczego)","_legal_basis":"Art. 58 KKS","_warnings":[]} {
    true
}

# jdg.kks.a58.r2 — `kks_invoice_fraud_buyer_use`: Uzycie falszywej faktury do odliczenia VAT -> przestepstwo
else :=   {"matched":true,"rule_id":"jdg.kks.a58.r2","package":"jdg.micro.kks","priority":3628,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Uzycie falszywej faktury do odliczenia VAT -> przestepstwo","_legal_basis":"Art. 58 KKS","_warnings":[]} {
    true
}

# jdg.kks.a59.r1 — `kks_non_payment_tax_withholding`: Nieodprowadzenie podatku u zrodla (WHT, PIT od pracownikow)
else :=   {"matched":true,"rule_id":"jdg.kks.a59.r1","package":"jdg.micro.kks","priority":3629,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nieodprowadzenie podatku u zrodla (WHT, PIT od pracownikow)","_legal_basis":"Art. 59 KKS","_warnings":[]} {
    true
}

# jdg.kks.a60.r1 — `kks_non_payment_vat_payable`: Niezaplata VAT należnego (mimo posiadania srodkow)
else :=   {"matched":true,"rule_id":"jdg.kks.a60.r1","package":"jdg.micro.kks","priority":3630,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niezaplata VAT należnego (mimo posiadania srodkow)","_legal_basis":"Art. 60 KKS","_warnings":[]} {
    true
}

# jdg.kks.a61.r1 — `kks_non_payment_zus_contributions`: Nieoplacanie skladek ZUS (wlasnych i pracownikow) -> przestepstwo
else :=   {"matched":true,"rule_id":"jdg.kks.a61.r1","package":"jdg.micro.kks","priority":3631,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Nieoplacanie skladek ZUS (wlasnych i pracownikow) -> przestepstwo","_legal_basis":"Art. 61 KKS","_warnings":[]} {
    true
}

# jdg.kks.a62.r1 — `kks_obstruction_tax_audit`: Uniemozliwianie kontroli podatkowej (brak dostepu, niszczenie dokumentow)
else :=   {"matched":true,"rule_id":"jdg.kks.a62.r1","package":"jdg.micro.kks","priority":3632,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Uniemozliwianie kontroli podatkowej (brak dostepu, niszczenie dokumentow)","_legal_basis":"Art. 62 KKS","_warnings":[]} {
    true
}

# jdg.kks.a63.r1 — `kks_destruction_of_documents`: Niszczenie dokumentow ksiegowych przed uplywem terminu przechowywania
else :=   {"matched":true,"rule_id":"jdg.kks.a63.r1","package":"jdg.micro.kks","priority":3633,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niszczenie dokumentow ksiegowych przed uplywem terminu przechowywania","_legal_basis":"Art. 63 KKS","_warnings":[]} {
    true
}

# jdg.kks.a64.r1 — `kks_abuse_of_procedures`: Naduzycie procedur podatkowych (np. wykorzystanie ulg bez podstawy)
else :=   {"matched":true,"rule_id":"jdg.kks.a64.r1","package":"jdg.micro.kks","priority":3634,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Naduzycie procedur podatkowych (np. wykorzystanie ulg bez podstawy)","_legal_basis":"Art. 64 KKS","_warnings":[]} {
    true
}

# jdg.kks.a77.r6 — `declaration_not_filed`: Niezłożenie deklaracji podatkowej (PIT, VAT, ZUS) w terminie → Grzywna do 120 stawek dziennych
else :=   {"matched":true,"rule_id":"jdg.kks.a77.r6","package":"jdg.micro.kks","priority":3635,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niezłożenie deklaracji podatkowej (PIT, VAT, ZUS) w terminie","_legal_basis":"Art. 77 par. 1 KKS","_warnings":[]} {
    true
}

# jdg.kks.a77.r7 — `declaration_not_filed_over_1m_pln`: Niezłożenie deklaracji, a uszczuplenie > 1 000 000 PLN → Grzywna + kara do 3 lat
else :=   {"matched":true,"rule_id":"jdg.kks.a77.r7","package":"jdg.micro.kks","priority":3636,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niezłożenie deklaracji, a uszczuplenie > 1 000 000 PLN","_legal_basis":"Art. 77 par. 2 KKS","_warnings":[]} {
    true
}

# jdg.kks.a77.r8 — `declaration_false_data`: Złożenie deklaracji z fałszywymi danymi → Grzywna do 120 stawek
else :=   {"matched":true,"rule_id":"jdg.kks.a77.r8","package":"jdg.micro.kks","priority":3637,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Złożenie deklaracji z fałszywymi danymi","_legal_basis":"Art. 77 par. 3 KKS","_warnings":[]} {
    true
}

# jdg.kks.a77.r9 — `declaration_late_correction_before_audit`: Korekta deklaracji przed kontrolą -> brak odpowiedzialności karnej skarbowej → Brak sankcji KKS
else :=   {"matched":true,"rule_id":"jdg.kks.a77.r9","package":"jdg.micro.kks","priority":3638,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta deklaracji przed kontrolą -> brak odpowiedzialności karnej skarbowej","_legal_basis":"Art. 77 par. 4 KKS","_warnings":[]} {
    true
}

# jdg.kks.a80.r1 — `active_remorse_valid_conditions`: Czynny żal: zawiadomienie US o popełnieniu czynu zabronionego przed wykryciem → Uniknięcie kary
else :=   {"matched":true,"rule_id":"jdg.kks.a80.r1","package":"jdg.micro.kks","priority":3639,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny żal: zawiadomienie US o popełnieniu czynu zabronionego przed wykryciem","_legal_basis":"Art. 80 par. 1 KKS","_warnings":[]} {
    true
}

# jdg.kks.a80.r2 — `active_remorse_full_disclosure`: Czynny żal wymaga pełnego ujawnienia okoliczności czynu → Pełna współpraca
else :=   {"matched":true,"rule_id":"jdg.kks.a80.r2","package":"jdg.micro.kks","priority":3640,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny żal wymaga pełnego ujawnienia okoliczności czynu","_legal_basis":"Art. 80 par. 2 KKS","_warnings":[]} {
    true
}

# jdg.kks.a80.r3 — `active_remorse_tax_payment`: Czynny żal: wymóg zapłaty zaległości podatkowej wraz z odsetkami → Zapłata + odsetki
else :=   {"matched":true,"rule_id":"jdg.kks.a80.r3","package":"jdg.micro.kks","priority":3641,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny żal: wymóg zapłaty zaległości podatkowej wraz z odsetkami","_legal_basis":"Art. 80 par. 3 KKS","_warnings":[]} {
    true
}

# jdg.kks.a80.r4 — `active_remorse_not_for_repeat`: Czynny żal nie przysługuje recydywiście (w ciągu 5 lat od poprzedniego skazania) → Wykluczenie recydywy
else :=   {"matched":true,"rule_id":"jdg.kks.a80.r4","package":"jdg.micro.kks","priority":3642,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny żal nie przysługuje recydywiście (w ciągu 5 lat od poprzedniego skazania)","_legal_basis":"Art. 80 par. 4 KKS","_warnings":[]} {
    true
}

# jdg.kks.a80.r5 — `active_remorse_not_for_vat_fraud`: Czynny żal nie dotyczy przestępstw VAT o znacznej wartości (zbrodnia VAT) → Wykluczenie zbrodni VAT
else :=   {"matched":true,"rule_id":"jdg.kks.a80.r5","package":"jdg.micro.kks","priority":3643,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny żal nie dotyczy przestępstw VAT o znacznej wartości (zbrodnia VAT)","_legal_basis":"Art. 80 par. 5 KKS","_warnings":[]} {
    true
}

# jdg.kks.mit.r1 — `mitigation_active_remorse_condition`: Czynny zal: zlozenie korekty + zaplata podatku + odsetki przed ogloszeniem kontroli → Mozliwosc
else :=   {"matched":true,"rule_id":"jdg.kks.mit.r1","package":"jdg.micro.kks","priority":3644,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny zal: zlozenie korekty + zaplata podatku + odsetki przed ogloszeniem kontroli","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.mit.r10 — `mitigation_whistleblower_status`: Ujawnienie innych przestepstw (whistleblower) -> calkowite zwolnienie z kary → Immunitet
else :=   {"matched":true,"rule_id":"jdg.kks.mit.r10","package":"jdg.micro.kks","priority":3645,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ujawnienie innych przestepstw (whistleblower) -> calkowite zwolnienie z kary","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.mit.r2 — `mitigation_active_remorse_criminal_immunity`: Czynny zal -> brak odpowiedzialnosci karnej (przestepstwo wygasa) → Immunitet
else :=   {"matched":true,"rule_id":"jdg.kks.mit.r2","package":"jdg.micro.kks","priority":3646,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny zal -> brak odpowiedzialnosci karnej (przestepstwo wygasa)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.mit.r3 — `mitigation_active_remorse_tax_immunity`: Czynny zal -> brak dodatkowego zobowiazania (sankcji VAT) → Immunitet
else :=   {"matched":true,"rule_id":"jdg.kks.mit.r3","package":"jdg.micro.kks","priority":3647,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny zal -> brak dodatkowego zobowiazania (sankcji VAT)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.mit.r4 — `mitigation_active_remorse_deadline`: Czynny zal mozliwy przed wszczecem kontroli (lub przed ogloszeniem) → Termin
else :=   {"matched":true,"rule_id":"jdg.kks.mit.r4","package":"jdg.micro.kks","priority":3648,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny zal mozliwy przed wszczecem kontroli (lub przed ogloszeniem)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.mit.r5 — `mitigation_active_remorse_not_for_carousel`: Czynny zal NIE dotyczy przestepstw karuzeli VAT → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.kks.mit.r5","package":"jdg.micro.kks","priority":3649,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny zal NIE dotyczy przestepstw karuzeli VAT","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.mit.r6 — `mitigation_active_remorse_not_for_gaar`: Czynny zal NIE dotyczy GAAR → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.kks.mit.r6","package":"jdg.micro.kks","priority":3650,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny zal NIE dotyczy GAAR","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.mit.r7 — `mitigation_voluntary_submission_penalty`: Dobrowolne poddanie sie odpowiedzialnosci (wniosek o skazanie bez rozprawy) → Opcja
else :=   {"matched":true,"rule_id":"jdg.kks.mit.r7","package":"jdg.micro.kks","priority":3651,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dobrowolne poddanie sie odpowiedzialnosci (wniosek o skazanie bez rozprawy)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.mit.r8 — `mitigation_voluntary_submission_penalty_reduction`: Dobrowolne poddanie -> redukcja kary (do 50%) → Redukcja
else :=   {"matched":true,"rule_id":"jdg.kks.mit.r8","package":"jdg.micro.kks","priority":3652,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dobrowolne poddanie -> redukcja kary (do 50%)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.mit.r9 — `mitigation_cooperation_with_authorities`: Wspolpraca z US -> lagodniejsza kara (maks. 50% redukcji) → Redukcja
else :=   {"matched":true,"rule_id":"jdg.kks.mit.r9","package":"jdg.micro.kks","priority":3653,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wspolpraca z US -> lagodniejsza kara (maks. 50% redukcji)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.pen.r1 — `penalty_vat_additional_30pct`: Zanizenie VAT > 10%
else :=   {"matched":true,"rule_id":"jdg.kks.pen.r1","package":"jdg.micro.kks","priority":3654,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zanizenie VAT > 10%","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.pen.r10 — `penalty_gaar_reduced_20pct`: Gdy MDR zgloszony
else :=   {"matched":true,"rule_id":"jdg.kks.pen.r10","package":"jdg.micro.kks","priority":3655,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Gdy MDR zgloszony","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.pen.r2 — `penalty_vat_additional_20pct`: Zanizenie < 10% (wykroczenie)
else :=   {"matched":true,"rule_id":"jdg.kks.pen.r2","package":"jdg.micro.kks","priority":3656,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zanizenie < 10% (wykroczenie)","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.pen.r3 — `penalty_vat_omission_100pct`: KSeF: niedotrzymanie obowiazku
else :=   {"matched":true,"rule_id":"jdg.kks.pen.r3","package":"jdg.micro.kks","priority":3657,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"KSeF: niedotrzymanie obowiazku","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.pen.r4 — `penalty_vat_bad_debt_30pct`: Brak korekty zlych dlugow w terminie
else :=   {"matched":true,"rule_id":"jdg.kks.pen.r4","package":"jdg.micro.kks","priority":3658,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak korekty zlych dlugow w terminie","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.pen.r5 — `penalty_pit_additional_30pct`: Zanizenie dochodu o > 50%
else :=   {"matched":true,"rule_id":"jdg.kks.pen.r5","package":"jdg.micro.kks","priority":3659,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zanizenie dochodu o > 50%","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.pen.r6 — `penalty_interest_overdue`: Niezaplata w terminie
else :=   {"matched":true,"rule_id":"jdg.kks.pen.r6","package":"jdg.micro.kks","priority":3660,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Niezaplata w terminie","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.pen.r7 — `penalty_interest_reduced_75`: Korekta po ogloszeniu kontroli
else :=   {"matched":true,"rule_id":"jdg.kks.pen.r7","package":"jdg.micro.kks","priority":3661,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta po ogloszeniu kontroli","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.pen.r8 — `penalty_interest_reduced_50`: Wspolpraca z US
else :=   {"matched":true,"rule_id":"jdg.kks.pen.r8","package":"jdg.micro.kks","priority":3662,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wspolpraca z US","_legal_basis":"","_warnings":[]} {
    true
}

# jdg.kks.pen.r9 — `penalty_gaar_40pct`: Klauzula przeciwko unikaniu opodatkowania
else :=   {"matched":true,"rule_id":"jdg.kks.pen.r9","package":"jdg.micro.kks","priority":3663,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Klauzula przeciwko unikaniu opodatkowania","_legal_basis":"","_warnings":[]} {
    true
}
