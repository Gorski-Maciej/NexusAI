# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.pit.tax_form_change
# Generated from Plan OPA specifications: 2026-07-13 14:05:06
# Rules: 7
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.pit.tax_form_change
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.pit.tax_form_change.no_match","package":"jdg.pit.tax_form_change","priority":99999}

# jdg.pit.tax_form_change.scale_to_linear — Przejście ze skali na liniowy — tylko od 1 stycznia
decide :=   {"matched":true,"rule_id":"jdg.pit.tax_form_change.scale_to_linear","package":"jdg.pit.tax_form_change","priority":590,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Przejście ze skali na liniowy — tylko od 1 stycznia","_legal_basis":"Art. 9a ust. 2 PIT","_warnings":["Przejście na liniowy — brak kwoty wolnej, brak ulg osobistych"]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
}

# jdg.pit.tax_form_change.linear_to_lump_sum — Przejście z liniowego na ryczałt
else :=   {"matched":true,"rule_id":"jdg.pit.tax_form_change.linear_to_lump_sum","package":"jdg.pit.tax_form_change","priority":591,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Przejście z liniowego na ryczałt","_legal_basis":"Art. 9 ustawy o ryczałcie","_warnings":["Przejście na ryczałt — koniec amortyzacji, nowa ewidencja"]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
}

# jdg.pit.tax_form_change.lump_sum_to_scale — Powrót z ryczałtu na skalę — remanent początkowy
else :=   {"matched":true,"rule_id":"jdg.pit.tax_form_change.lump_sum_to_scale","package":"jdg.pit.tax_form_change","priority":592,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Powrót z ryczałtu na skalę — remanent początkowy","_legal_basis":"Art. 24a PIT","_warnings":["Powrót na skalę — załóż PKPiR i sporządź remanent początkowy"]} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"; object.get(input.jdg_entrepreneur, "uses_pkpir", false) == true
}

# jdg.pit.tax_form_change.mid_year_restriction — Blokada zmiany formy opodatkowania w trakcie roku
else :=   {"matched":true,"rule_id":"jdg.pit.tax_form_change.mid_year_restriction","package":"jdg.pit.tax_form_change","priority":593,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Blokada zmiany formy opodatkowania w trakcie roku","_legal_basis":"Art. 9a ust. 2 PIT","_warnings":["Niedozwolona zmiana formy opodatkowania w trakcie roku!"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}

# jdg.pit.tax_form_change.consequences_multiple_returns — Utrata ryczałtu w trakcie roku → dwa zeznania roczne
else :=   {"matched":true,"rule_id":"jdg.pit.tax_form_change.consequences_multiple_returns","package":"jdg.pit.tax_form_change","priority":594,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Utrata ryczałtu w trakcie roku → dwa zeznania roczne","_legal_basis":"Art. 22 ustawy o ryczałcie","_warnings":["Utrata ryczałtu — złóż PIT-28 + PIT-36"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.pit.tax_form_change.inventory_remeasurement — Remanent przy zmianie formy ryczałt↔skala/liniowy
else :=   {"matched":true,"rule_id":"jdg.pit.tax_form_change.inventory_remeasurement","package":"jdg.pit.tax_form_change","priority":595,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Remanent przy zmianie formy ryczałt↔skala/liniowy","_legal_basis":"§ 24 Rozporządzenia ws. PKPiR","_warnings":["Zmiana formy — wymagany remanent na 1 stycznia"]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; object.get(input.jdg_entrepreneur, "uses_pkpir", false) == true
}

# jdg.pit.tax_form_change.zus_health_recalculation — Przeliczenie składki zdrowotnej po zmianie formy
else :=   {"matched":true,"rule_id":"jdg.pit.tax_form_change.zus_health_recalculation","package":"jdg.pit.tax_form_change","priority":596,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Przeliczenie składki zdrowotnej po zmianie formy","_legal_basis":"Art. 81 ust. 2 ustawy o świadczeniach zdrowotnych","_warnings":["Zmiana formy — zaktualizuj deklarację ZUS DRA"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != ""
}
