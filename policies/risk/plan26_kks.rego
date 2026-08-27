# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.risk
# Generated from Plan OPA specifications: 2026-07-13 14:05:06
# Rules: 4
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.risk
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.risk.plan26.no_match","package":"jdg.risk","priority":99999}

# jdg.risk.kks_hidden_income_flag — Ukryty dochód — rozbieżność wpływów bankowych vs deklaracji
decide :=   {"matched":true,"rule_id":"jdg.risk.kks_hidden_income_flag_plan26","package":"jdg.risk","priority":4,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Ukryty dochód — rozbieżność wpływów bankowych vs deklaracji","_legal_basis":"Art. 54 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Rozbieżność wpływów vs przychodów — ryzyko Art. 54 KKS!"]} {
    object.get(input.jdg_entrepreneur, "income_discrepancy_detected", false) == true
}

# jdg.risk.kks_unreliable_books — Nierzetelna PKPiR — Art. 56 KKS
else :=   {"matched":true,"rule_id":"jdg.risk.kks_unreliable_books_plan26","package":"jdg.risk","priority":6,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Nierzetelna PKPiR — Art. 56 KKS","_legal_basis":"Art. 56 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Nierzetelna PKPiR — ryzyko Art. 56 KKS, grzywna do 720 stawek!"]} {
    object.get(input.vendor, "risk_flag", false) == true
}

# jdg.risk.kks_vat_evidence_gap — Niekompletna ewidencja VAT — Art. 57 KKS
else :=   {"matched":true,"rule_id":"jdg.risk.kks_vat_evidence_gap","package":"jdg.risk","priority":7,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Niekompletna ewidencja VAT — Art. 57 KKS","_legal_basis":"Art. 57 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Niekompletna ewidencja VAT — ryzyko Art. 57 KKS"]} {
    object.get(input.jdg_entrepreneur, "vat_evidence_incomplete", false) == true
}

# jdg.risk.kks_declaration_overdue — Niezłożona deklaracja — Art. 77 KKS
else :=   {"matched":true,"rule_id":"jdg.risk.kks_declaration_overdue","package":"jdg.risk","priority":8,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Niezłożona deklaracja — Art. 77 KKS","_legal_basis":"Art. 77 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Deklaracja niezłożona w terminie — ryzyko Art. 77 KKS"]} {
    object.get(input.jdg_entrepreneur, "tax_declaration_overdue", false) == true
}
