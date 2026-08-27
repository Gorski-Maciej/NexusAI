# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.kks
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 21
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.kks
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.kks.plan43.no_match","package":"jdg.kks","priority":99999}

# jdg.kks.vd_conditions_art16_p1 — Czynny żal — warunki formalne (zawiadomienie przed wykryciem)
decide :=   {"matched":true,"rule_id":"jdg.kks.vd_conditions_art16_p1","package":"jdg.kks","priority":200,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny żal — warunki formalne (zawiadomienie przed wykryciem)","_legal_basis":"Art. 16 § 1 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Czynny żal — złóż zawiadomienie przed wszczęciem kontroli"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.vd_payment_obligation_art16_p2 — Czynny żal — obowiązek wpłaty w 7 dni
else :=   {"matched":true,"rule_id":"jdg.kks.vd_payment_obligation_art16_p2","package":"jdg.kks","priority":201,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Czynny żal — obowiązek wpłaty w 7 dni","_legal_basis":"Art. 16 § 2 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Czynny żal — nie wpłacono należności w terminie 7 dni!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.vd_incomplete_notification_art16_p3 — Czynny żal — kompletność zawiadomienia
else :=   {"matched":true,"rule_id":"jdg.kks.vd_incomplete_notification_art16_p3","package":"jdg.kks","priority":202,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Czynny żal — kompletność zawiadomienia","_legal_basis":"Art. 16 § 3 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Czynny żal — zawiadomienie niekompletne"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.vd_effect_no_penalty_art16_p8 — Czynny żal — skutek: brak kary
else :=   {"matched":true,"rule_id":"jdg.kks.vd_effect_no_penalty_art16_p8","package":"jdg.kks","priority":207,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny żal — skutek: brak kary","_legal_basis":"Art. 16 § 8 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":[]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.statute_crime_5y_art20_p1 — Przedawnienie przestępstw KKS — 5 lat
else :=   {"matched":true,"rule_id":"jdg.kks.statute_crime_5y_art20_p1","package":"jdg.kks","priority":220,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedawnienie przestępstw KKS — 5 lat","_legal_basis":"Art. 20 § 1 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":[]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.statute_misdemeanor_3y_art20_p2 — Przedawnienie wykroczeń KKS — 3 lata
else :=   {"matched":true,"rule_id":"jdg.kks.statute_misdemeanor_3y_art20_p2","package":"jdg.kks","priority":221,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedawnienie wykroczeń KKS — 3 lata","_legal_basis":"Art. 20 § 2 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":[]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.statute_extension_5y_art20_p3 — Przedłużenie przedawnienia o 5 lat
else :=   {"matched":true,"rule_id":"jdg.kks.statute_extension_5y_art20_p3","package":"jdg.kks","priority":222,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedłużenie przedawnienia o 5 lat","_legal_basis":"Art. 20 § 3 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Przedawnienie wydłużone o 5 lat — wszczęto postępowanie"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.statute_interruption_art21_p1 — Przerwanie biegu przedawnienia KKS
else :=   {"matched":true,"rule_id":"jdg.kks.statute_interruption_art21_p1","package":"jdg.kks","priority":223,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przerwanie biegu przedawnienia KKS","_legal_basis":"Art. 21 § 1 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Bieg przedawnienia przerwany — nowy termin"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.tax_evasion_elements_art54_p1 — Znamiona uchylania się od opodatkowania
else :=   {"matched":true,"rule_id":"jdg.kks.tax_evasion_elements_art54_p1","package":"jdg.kks","priority":240,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Znamiona uchylania się od opodatkowania","_legal_basis":"Art. 54 § 1 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Wykryto znamiona uchylania się od opodatkowania! Ryzyko KKS Art. 54!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.tax_evasion_significant_art54_p2 — Kwalifikowana forma uchylania — duża wartość
else :=   {"matched":true,"rule_id":"jdg.kks.tax_evasion_significant_art54_p2","package":"jdg.kks","priority":241,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Kwalifikowana forma uchylania — duża wartość","_legal_basis":"Art. 54 § 2 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Uszczuplenie dużej wartości — zaostrzona odpowiedzialność KKS!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.tax_evasion_concealed_business_art54_p3 — Całkowicie ukryta działalność gospodarcza
else :=   {"matched":true,"rule_id":"jdg.kks.tax_evasion_concealed_business_art54_p3","package":"jdg.kks","priority":242,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Całkowicie ukryta działalność gospodarcza","_legal_basis":"Art. 54 § 3 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Działalność bez rejestracji CEIDG — ryzyko KKS Art. 54!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.unreliable_pkpir_systematic_art56_p2 — Systematyczne nierzetelne PKPiR
else :=   {"matched":true,"rule_id":"jdg.kks.unreliable_pkpir_systematic_art56_p2","package":"jdg.kks","priority":256,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Systematyczne nierzetelne PKPiR","_legal_basis":"Art. 56 § 2 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Systematyczna nierzetelność PKPiR — zaostrzona odpowiedzialność!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.pkpir_fictitious_entries_art56_p3 — Fikcyjne wpisy w PKPiR
else :=   {"matched":true,"rule_id":"jdg.kks.pkpir_fictitious_entries_art56_p3","package":"jdg.kks","priority":257,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Fikcyjne wpisy w PKPiR","_legal_basis":"Art. 56 § 3 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Fikcyjne wpisy w PKPiR — ryzyko KKS Art. 56 § 3!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.empty_invoice_carousel_art62_p3 — Karuzela VAT — łańcuch pustych faktur
else :=   {"matched":true,"rule_id":"jdg.kks.empty_invoice_carousel_art62_p3","package":"jdg.kks","priority":302,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Karuzela VAT — łańcuch pustych faktur","_legal_basis":"Art. 62 § 2 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["KARUZELA VAT! Łańcuch pustych faktur — ryzyko do 15 lat pozbawienia wolności!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.invoice_falsification_art62_p4 — Podrobienie/przerobienie faktury
else :=   {"matched":true,"rule_id":"jdg.kks.invoice_falsification_art62_p4","package":"jdg.kks","priority":303,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Podrobienie/przerobienie faktury","_legal_basis":"Art. 62 § 1 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Faktura podrobiona/przerobiona — ryzyko KKS Art. 62!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.declaration_non_filing_art77_p1 — Niezłożenie deklaracji w terminie — wykroczenie
else :=   {"matched":true,"rule_id":"jdg.kks.declaration_non_filing_art77_p1","package":"jdg.kks","priority":400,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Niezłożenie deklaracji w terminie — wykroczenie","_legal_basis":"Art. 77 § 1 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Deklaracja niezłożona w terminie — wykroczenie skarbowe, grzywna do 180 stawek"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.declaration_persistent_art77_p2 — Uporczywe niezłożenie deklaracji — przestępstwo
else :=   {"matched":true,"rule_id":"jdg.kks.declaration_persistent_art77_p2","package":"jdg.kks","priority":401,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Uporczywe niezłożenie deklaracji — przestępstwo","_legal_basis":"Art. 77 § 2 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Uporczywe niezłożenie deklaracji — przestępstwo skarbowe!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.tax_non_payment_art79_p1 — Niezapłacenie podatku w terminie — wykroczenie
else :=   {"matched":true,"rule_id":"jdg.kks.tax_non_payment_art79_p1","package":"jdg.kks","priority":411,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Niezapłacenie podatku w terminie — wykroczenie","_legal_basis":"Art. 79 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Podatek niezapłacony w terminie — ryzyko KKS Art. 79"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.fine_daily_rate_art23 — Stawka dzienna grzywny KKS
else :=   {"matched":true,"rule_id":"jdg.kks.fine_daily_rate_art23","package":"jdg.kks","priority":490,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawka dzienna grzywny KKS","_legal_basis":"Art. 23 § 1-3 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":[]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.fine_amount_range_art23_p4 — Zakres kar grzywny — 10-720 stawek dziennych
else :=   {"matched":true,"rule_id":"jdg.kks.fine_amount_range_art23_p4","package":"jdg.kks","priority":491,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zakres kar grzywny — 10-720 stawek dziennych","_legal_basis":"Art. 23 § 4 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":[]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.imprisonment_substitute_art25 — Kara zastępcza pozbawienia wolności za nieuiszczoną grzywnę
else :=   {"matched":true,"rule_id":"jdg.kks.imprisonment_substitute_art25","package":"jdg.kks","priority":492,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Kara zastępcza pozbawienia wolności za nieuiszczoną grzywnę","_legal_basis":"Art. 25 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Grzywna nieuiszczona — ryzyko zastępczej kary pozbawienia wolności!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}
