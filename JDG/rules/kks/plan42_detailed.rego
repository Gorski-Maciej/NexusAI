# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.kks
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 12
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.kks
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.kks.no_match","package":"jdg.kks","priority":99999}

# jdg.kks.unreliable_pkpir_art56 — Nierzetelne prowadzenie PKPiR — Art. 56 KKS
decide :=   {"matched":true,"rule_id":"jdg.kks.unreliable_pkpir_art56","package":"jdg.kks","priority":130,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Nierzetelne prowadzenie PKPiR — Art. 56 KKS","_legal_basis":"Art. 56 § 1-4 KKS","_warnings":["Ryzyko KKS Art. 56 — nierzetelne PKPiR! Kara grzywny do 720 stawek dziennych"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.unreliable_vat_evidence_art57 — Nierzetelna ewidencja VAT — Art. 57 KKS
else :=   {"matched":true,"rule_id":"jdg.kks.unreliable_vat_evidence_art57","package":"jdg.kks","priority":131,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Nierzetelna ewidencja VAT — Art. 57 KKS","_legal_basis":"Art. 57 § 1 KKS","_warnings":["Ryzyko KKS Art. 57 — nierzetelna ewidencja VAT!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.empty_invoice_art62 — Pusta faktura — Art. 62 § 2 KKS (kara do 8 lat pozbawienia wolności)
else :=   {"matched":true,"rule_id":"jdg.kks.empty_invoice_art62","package":"jdg.kks","priority":132,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Pusta faktura — Art. 62 § 2 KKS (kara do 8 lat pozbawienia wolności)","_legal_basis":"Art. 62 § 2 KKS","_warnings":["PUSTA FAKTURA! Czynność nie miała miejsca. Ryzyko KKS Art. 62 § 2 — do 8 lat pozbawienia wolności!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.wrong_vat_rate_art64 — Niewłaściwa stawka VAT — Art. 64 KKS
else :=   {"matched":true,"rule_id":"jdg.kks.wrong_vat_rate_art64","package":"jdg.kks","priority":133,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Niewłaściwa stawka VAT — Art. 64 KKS","_legal_basis":"Art. 64 KKS","_warnings":["Ryzyko KKS Art. 64 — niewłaściwa stawka VAT!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.tax_return_non_filing_art77 — Niezłożenie deklaracji w terminie — Art. 77 KKS
else :=   {"matched":true,"rule_id":"jdg.kks.tax_return_non_filing_art77","package":"jdg.kks","priority":134,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Niezłożenie deklaracji w terminie — Art. 77 KKS","_legal_basis":"Art. 77 § 1-3 KKS","_warnings":["Deklaracja niezłożona w terminie! Ryzyko KKS Art. 77"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.non_payment_of_tax_art79 — Niezapłacenie podatku w terminie — Art. 79 KKS
else :=   {"matched":true,"rule_id":"jdg.kks.non_payment_of_tax_art79","package":"jdg.kks","priority":135,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Niezapłacenie podatku w terminie — Art. 79 KKS","_legal_basis":"Art. 79 KKS","_warnings":["Zaległość podatkowa — ryzyko KKS Art. 79"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.destruction_of_documents_art68 — Zniszczenie/ukrycie dokumentów — Art. 68 KKS
else :=   {"matched":true,"rule_id":"jdg.kks.destruction_of_documents_art68","package":"jdg.kks","priority":136,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Zniszczenie/ukrycie dokumentów — Art. 68 KKS","_legal_basis":"Art. 68 KKS","_warnings":["Luki w dokumentacji podatkowej — ryzyko KKS Art. 68!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.voluntary_disclosure_art16 — Czynny żal — warunki uniknięcia kary KKS
else :=   {"matched":true,"rule_id":"jdg.kks.voluntary_disclosure_art16","package":"jdg.kks","priority":137,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny żal — warunki uniknięcia kary KKS","_legal_basis":"Art. 16 § 1-3 KKS","_warnings":["Czynny żal — złóż zawiadomienie przed wykryciem przez US"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.criminal_statute_art44 — Przedawnienie karalności KKS — 5 lat (przestępstwo), 3 lata (wykroczenie)
else :=   {"matched":true,"rule_id":"jdg.kks.criminal_statute_art44","package":"jdg.kks","priority":138,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Przedawnienie karalności KKS — 5 lat (przestępstwo), 3 lata (wykroczenie)","_legal_basis":"Art. 44 § 1-5 KKS","_warnings":["Zbliża się termin przedawnienia karalności"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.fiscal_penalty_calculation — Kalkulacja grzywny KKS — stawka dzienna × liczba stawek
else :=   {"matched":true,"rule_id":"jdg.kks.fiscal_penalty_calculation","package":"jdg.kks","priority":139,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Kalkulacja grzywny KKS — stawka dzienna × liczba stawek","_legal_basis":"Art. 23 § 1-3 KKS","_warnings":["Szacowana grzywna KKS — zweryfikuj poprawność deklaracji"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.obstruction_of_audit_art69 — Utrudnianie kontroli podatkowej — Art. 69 KKS
else :=   {"matched":true,"rule_id":"jdg.kks.obstruction_of_audit_art69","package":"jdg.kks","priority":140,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Utrudnianie kontroli podatkowej — Art. 69 KKS","_legal_basis":"Art. 69 § 1-3 KKS","_warnings":["Utrudnianie kontroli — ryzyko KKS Art. 69!"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}

# jdg.kks.aggregate_risk_score — Agregacja wszystkich flag KKS w jeden wskaźnik ryzyka
else :=   {"matched":true,"rule_id":"jdg.kks.aggregate_risk_score","package":"jdg.kks","priority":141,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Agregacja wszystkich flag KKS w jeden wskaźnik ryzyka","_legal_basis":"Całość KKS — reguła pomocnicza","_warnings":["Podwyższony profil ryzyka KKS — sprawdź szczegółowe alerty"]} {
    object.get(input.invoice, "kks_risk_detected", false) == true
}
