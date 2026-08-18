# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.tp (Doc 44: P1930-P1938)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 9
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tp
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.tp.no_match","package":"jdg.tp","priority":99999}

# jdg.tp.related_party_detection — Wykrycie transakcji z podmiotami powiązanymi
decide :=   {"matched":true,"rule_id":"jdg.tp.related_party_detection","package":"jdg.tp","priority":1930,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Wykrycie transakcji z podmiotami powiązanymi","_legal_basis":"Art. 23m-23zf PIT","_warnings":["Transakcja z podmiotem powiązanym — sprawdź obowiązki TP!"]} {
    object.get(input.vendor, "is_related_party", false) == true
}

# jdg.tp.documentation_thresholds — P1931: Progi dokumentacyjne (bez Local File)
else :=   {"matched":true,"rule_id":"jdg.tp.documentation_thresholds","package":"jdg.tp","priority":1931,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Progi dokumentacyjne TP: 2M/1M/0.5M PLN","_legal_basis":"Art. 23zf PIT","_warnings":["Przekroczono próg dokumentacyjny TP — wymagany Local File"]} {
    object.get(input.vendor, "is_related_party", false) == true
    object.get(input.invoice, "transaction_value_pln", 0) > 500000
}

# jdg.tp.local_file_requirements — P1932: Local File — analiza funkcjonalna, cen transferowych, porównywalna
else :=   {"matched":true,"rule_id":"jdg.tp.local_file_requirements","package":"jdg.tp","priority":1932,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Local File — analiza funkcjonalna, TP, porównawcza","_legal_basis":"Art. 23zf PIT","_warnings":["Przekroczono progi TP — przygotuj Local File z analizą funkcjonalną"]} {
    object.get(input.vendor, "is_related_party", false) == true
    object.get(input.tp, "local_file_required", false) == true
}

# jdg.tp.master_file_requirements — P1933: Master File — grupa >200M PLN skonsolidowanych przychodów
else :=   {"matched":true,"rule_id":"jdg.tp.master_file_requirements","package":"jdg.tp","priority":1933,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Master File — dla grup o przychodach >200M PLN","_legal_basis":"Art. 23zf PIT","_warnings":["JDG w grupie >200M PLN — Master File wymagany"]} {
    object.get(input.vendor, "is_related_party", false) == true
    object.get(input.tp, "master_file_required", false) == true
}

# jdg.tp.tpr_form_filing — P1934: TPR-C (bez Local File, z progiem)
else :=   {"matched":true,"rule_id":"jdg.tp.tpr_form_filing","package":"jdg.tp","priority":1934,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"TPR-C — obowiązek złożenia do 30 listopada","_legal_basis":"Art. 23zh PIT","_warnings":["TPR-C niezłożony — termin do 30 listopada!"]} {
    object.get(input.vendor, "is_related_party", false) == true
    object.get(input.invoice, "transaction_value_pln", 0) > 500000
    object.get(input.tp, "tpr_filed", false) == false
}

# jdg.tp.benchmarking_analysis — P1935: Benchmarking — analiza porównawcza marż, cen, warunków
else :=   {"matched":true,"rule_id":"jdg.tp.benchmarking_analysis","package":"jdg.tp","priority":1935,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Benchmarking — analiza porównawcza dla transakcji z podmiotami powiązanymi","_legal_basis":"Art. 23zf PIT","_warnings":["Wymagana analiza porównawcza (benchmarking) dla transakcji TP"]} {
    object.get(input.vendor, "is_related_party", false) == true
    object.get(input.tp, "benchmarking_analysis_required", false) == true
}

# jdg.tp.safe_harbor_low_value — P1936: Safe harbor dla niskowartościowych usług — marża 5%
else :=   {"matched":true,"rule_id":"jdg.tp.safe_harbor_low_value","package":"jdg.tp","priority":1936,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Safe harbor — usługi niskowartościowe, marża 5%, pułap 30% kosztów","_legal_basis":"Art. 23zf PIT","_warnings":["Low value-adding services — safe harbor: marża 5%, max 30% kosztów"]} {
    object.get(input.vendor, "is_related_party", false) == true
    object.get(input.tp, "safe_harbor_low_value", false) == true
}

# jdg.tp.adjustment_consequences — P1937: Doszacowanie dochodu — 10% dodatkowe opodatkowanie
else :=   {"matched":true,"rule_id":"jdg.tp.adjustment_consequences","package":"jdg.tp","priority":1937,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Doszacowanie dochodu — 10% dodatkowe + odsetki","_legal_basis":"Art. 58 Ordynacji podatkowej","_warnings":["Doszacowanie dochodu TP — 10% dodatkowego opodatkowania + odsetki za zwłokę"]} {
    object.get(input.vendor, "is_related_party", false) == true
    object.get(input.tp, "adjustment_consequences_checked", false) == false
}

# jdg.tp.documentation_penalty — P1938: Sankcje za brak dokumentacji (gdy doszacowano)
else :=   {"matched":true,"rule_id":"jdg.tp.documentation_penalty","package":"jdg.tp","priority":1938,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Sankcje za brak dokumentacji TP — 10% doszacowanego dochodu","_legal_basis":"Art. 56 KKS","_warnings":["Brak dokumentacji TP — ryzyko 10% dodatkowego opodatkowania!"]} {
    object.get(input.vendor, "is_related_party", false) == true
    object.get(input.tp, "documentation_missing", false) == true
}
