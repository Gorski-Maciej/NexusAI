# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.uor
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 5
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.uor
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.uor.no_match","package":"jdg.uor","priority":99999}

# jdg.uor.inventory_obligation — Inwentaryzacja — obowiązek w pełnej księgowości
decide :=   {"matched":true,"rule_id":"jdg.uor.inventory_obligation","package":"jdg.uor","priority":875,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Inwentaryzacja — obowiązek w pełnej księgowości","_legal_basis":"Art. 26 ust. 1-3 UoR","_warnings":["Inwentaryzacja zaległa — wymagana minimum raz na 2 lata"]} {
    object.get(input.jdg_entrepreneur, "full_accounting_required", false) == true
}

# jdg.uor.asset_valuation — Wycena aktywów i pasywów — zasada ostrożności
else :=   {"matched":true,"rule_id":"jdg.uor.asset_valuation","package":"jdg.uor","priority":876,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Wycena aktywów i pasywów — zasada ostrożności","_legal_basis":"Art. 28 ust. 1-7 UoR","_warnings":["Brak odpisu aktualizującego przy trwałej utracie wartości"]} {
    object.get(input.jdg_entrepreneur, "full_accounting_required", false) == true
}

# jdg.uor.accruals_deferrals — Rozliczenia międzyokresowe kosztów (RMK)
else :=   {"matched":true,"rule_id":"jdg.uor.accruals_deferrals","package":"jdg.uor","priority":877,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Rozliczenia międzyokresowe kosztów (RMK)","_legal_basis":"Art. 39 UoR","_warnings":["Brak rozliczeń międzyokresowych — koszty w złym okresie"]} {
    object.get(input.jdg_entrepreneur, "full_accounting_required", false) == true
}

# jdg.uor.financial_statement — Sprawozdanie finansowe — termin 3 miesiące od dnia bilansowego
else :=   {"matched":true,"rule_id":"jdg.uor.financial_statement","package":"jdg.uor","priority":878,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Sprawozdanie finansowe — termin 3 miesiące od dnia bilansowego","_legal_basis":"Art. 45, 52 UoR","_warnings":["Sprawozdanie finansowe niezłożone w terminie!"]} {
    object.get(input.jdg_entrepreneur, "full_accounting_required", false) == true
}

# jdg.uor.document_storage — Przechowywanie dokumentacji księgowej 5 lat
else :=   {"matched":true,"rule_id":"jdg.uor.document_storage","package":"jdg.uor","priority":879,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Przechowywanie dokumentacji księgowej 5 lat","_legal_basis":"Art. 74 UoR","_warnings":["Dokumenty księgowe — okres przechowywania 5 lat"]} {
    object.get(input.jdg_entrepreneur, "full_accounting_required", false) == true
}
