# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.crossborder
# Generated from Plan OPA specifications: 2026-07-13 14:05:06
# Rules: 8
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.crossborder
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.crossborder.plan23_ue.no_match","package":"jdg.crossborder","priority":99999}

# jdg.crossborder.vat_ue_registration_mandatory — Blokada transakcji wewnątrzwspólnotowych bez VAT-UE
decide :=   {"matched":true,"rule_id":"jdg.crossborder.vat_ue_registration_mandatory","package":"jdg.crossborder","priority":43,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Blokada transakcji wewnątrzwspólnotowych bez VAT-UE","_legal_basis":"Art. 97 ust. 1-3 VAT","_warnings":["Brak rejestracji VAT-UE — wymagany VAT-R przed transakcją"]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.crossborder.vat_r_ue_filing_deadline — VAT-R UE — złóż przed pierwszą transakcją WNT/WDT
else :=   {"matched":true,"rule_id":"jdg.crossborder.vat_r_ue_filing_deadline","package":"jdg.crossborder","priority":44,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"VAT-R UE — złóż przed pierwszą transakcją WNT/WDT","_legal_basis":"Art. 97 ust. 1-3 VAT","_warnings":["Zarejestruj VAT-UE przed pierwszą transakcją wewnątrzwspólnotową"]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.crossborder.intra_community_acquisition_detailed — WNT — naliczenie VAT należnego wg stawki krajowej + odliczenie
else :=   {"matched":true,"rule_id":"jdg.crossborder.intra_community_acquisition_detailed","package":"jdg.crossborder","priority":46,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WNT — naliczenie VAT należnego wg stawki krajowej + odliczenie","_legal_basis":"Art. 9, Art. 11, Art. 20 ust. 5 VAT","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.crossborder.import_services_non_eu — Import usług spoza UE — reverse charge
else :=   {"matched":true,"rule_id":"jdg.crossborder.import_services_non_eu","package":"jdg.crossborder","priority":47,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Import usług spoza UE — reverse charge","_legal_basis":"Art. 28b, Art. 17 ust. 1 pkt 4 VAT","_warnings":["Import usług spoza UE — rozlicz VAT należny i naliczony"]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.crossborder.triangular_transaction_rules — Transakcja trójstronna UE — procedura uproszczona
else :=   {"matched":true,"rule_id":"jdg.crossborder.triangular_transaction_rules","package":"jdg.crossborder","priority":49,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Transakcja trójstronna UE — procedura uproszczona","_legal_basis":"Art. 135-138 VAT","_warnings":["Transakcja trójstronna — procedura uproszczona, brak rejestracji w kraju dostawy"]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.crossborder.wnt_intra_community_detailed — WNT — obowiązek podatkowy 15. dnia nast. miesiąca lub data faktury
else :=   {"matched":true,"rule_id":"jdg.crossborder.wnt_intra_community_detailed","package":"jdg.crossborder","priority":190,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WNT — obowiązek podatkowy 15. dnia nast. miesiąca lub data faktury","_legal_basis":"Art. 20 ust. 5 VAT","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.crossborder.import_vat_deduction_timing — Odliczenie VAT od importu — w okresie otrzymania dokumentu celnego
else :=   {"matched":true,"rule_id":"jdg.crossborder.import_vat_deduction_timing","package":"jdg.crossborder","priority":191,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odliczenie VAT od importu — w okresie otrzymania dokumentu celnego","_legal_basis":"Art. 86 ust. 2 pkt 2, Art. 86 ust. 10b pkt 3 VAT","_warnings":["VAT od importu — odliczenie w okresie otrzymania dokumentu celnego"]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}

# jdg.crossborder.vat_ue_quarterly_summary — VAT-UE — informacja podsumowująca kwartalna
else :=   {"matched":true,"rule_id":"jdg.crossborder.vat_ue_quarterly_summary","package":"jdg.crossborder","priority":232,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"VAT-UE — informacja podsumowująca kwartalna","_legal_basis":"Art. 100 ust. 1 i 3 VAT","_warnings":["VAT-UE — złóż informację podsumowującą do 25. dnia po kwartale"]} {
    object.get(input.document, "tax_proceedings_active", false) == true
}
