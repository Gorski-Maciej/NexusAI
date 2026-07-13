# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.tp
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 4
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tp
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.tp.no_match","package":"jdg.tp","priority":99999}

# jdg.tp.related_party_detection — Wykrycie transakcji z podmiotami powiązanymi
decide :=   {"matched":true,"rule_id":"jdg.tp.related_party_detection","package":"jdg.tp","priority":1930,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Wykrycie transakcji z podmiotami powiązanymi","_legal_basis":"Art. 23m-23zf PIT","_warnings":["Transakcja z podmiotem powiązanym — sprawdź obowiązki TP!"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.documentation_thresholds — Progi dokumentacyjne TP: 2M/1M/0.5M PLN
else :=   {"matched":true,"rule_id":"jdg.tp.documentation_thresholds","package":"jdg.tp","priority":1931,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Progi dokumentacyjne TP: 2M/1M/0.5M PLN","_legal_basis":"Art. 23zf PIT","_warnings":["Przekroczono próg dokumentacyjny TP — wymagany Local File"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.tpr_form_filing — TPR-C — obowiązek złożenia do 30 listopada
else :=   {"matched":true,"rule_id":"jdg.tp.tpr_form_filing","package":"jdg.tp","priority":1934,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"TPR-C — obowiązek złożenia do 30 listopada","_legal_basis":"Art. 23zh PIT","_warnings":["TPR-C niezłożony — termin do 30 listopada!"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.documentation_penalty — Sankcje za brak dokumentacji TP — 10% doszacowanego dochodu
else :=   {"matched":true,"rule_id":"jdg.tp.documentation_penalty","package":"jdg.tp","priority":1938,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Sankcje za brak dokumentacji TP — 10% doszacowanego dochodu","_legal_basis":"Art. 56 KKS","_warnings":["Brak dokumentacji TP — ryzyko 10% dodatkowego opodatkowania!"]} {
    object.get(input.vendor, "is_related_party", false) == true
}
