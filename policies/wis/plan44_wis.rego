# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.wis (Doc 44: P1820-P1827)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 8
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.wis
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.wis.no_match","package":"jdg.wis","priority":99999}

# jdg.wis.binding_rate_check — WIS — identyfikacja towarów wymagających WIS
decide :=   {"matched":true,"rule_id":"jdg.wis.binding_rate_check","package":"jdg.wis","priority":1820,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"WIS — identyfikacja towarów wymagających WIS","_legal_basis":"Art. 42a-42h VAT","_warnings":["Towar o niejednoznacznej klasyfikacji — rozważ uzyskanie WIS"]} {
    object.get(input.invoice, "wis_required", false) == true
}

# jdg.wis.validity_monitoring — P1821: Monitorowanie ważności WIS (bez GTU mapping)
else :=   {"matched":true,"rule_id":"jdg.wis.validity_monitoring","package":"jdg.wis","priority":1821,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Monitorowanie ważności WIS (5 lat)","_legal_basis":"Art. 42h VAT","_warnings":["WIS wygasa — złóż wniosek o nową"]} {
    object.get(input.invoice, "wis_required", false) == true
    object.get(input.invoice, "wis_obtained", false) == true
}

# jdg.wis.gtu_code_mapping — P1822: Mapowanie WIS na kody GTU w JPK_V7
else :=   {"matched":true,"rule_id":"jdg.wis.gtu_code_mapping","package":"jdg.wis","priority":1822,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Mapowanie WIS na kody GTU — spójność JPK_V7","_legal_basis":"Art. 42a VAT, Rozporządzenie JPK_V7","_warnings":["WIS determinuje kod GTU — zapewnij spójność w JPK_V7"]} {
    object.get(input.invoice, "wis_required", false) == true
    object.get(input.invoice, "wis_obtained", false) == true
    object.get(input.invoice, "gtu_mapped", false) == false
}

# jdg.wis.vs_individual_interpretation — P1823: WIS vs interpretacja indywidualna — pierwszeństwo WIS
else :=   {"matched":true,"rule_id":"jdg.wis.vs_individual_interpretation","package":"jdg.wis","priority":1823,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WIS vs interpretacja indywidualna — WIS ma pierwszeństwo w klasyfikacji CN","_legal_basis":"Art. 42b VAT","_warnings":["WIS ma pierwszeństwo przed interpretacją indywidualną w zakresie klasyfikacji towarowej"]} {
    object.get(input.invoice, "wis_required", false) == true
    object.get(input.invoice, "vs_interpretation_checked", false) == false
}

# jdg.wis.for_import_goods — P1824: WIS dla towarów importowanych
else :=   {"matched":true,"rule_id":"jdg.wis.for_import_goods","package":"jdg.wis","priority":1824,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"WIS dla towarów importowanych — unikaj błędnej stawki na granicy","_legal_basis":"Art. 42a VAT","_warnings":["Import z niejednoznaczną klasyfikacją — uzyskaj WIS dla pewności stawki VAT"]} {
    object.get(input.invoice, "wis_required", false) == true
    object.get(input.invoice, "import_goods", false) == true
}

# jdg.wis.wit_tariff_information — P1825: WIT dla ceł przy imporcie spoza UE (ważność 3 lata)
else :=   {"matched":true,"rule_id":"jdg.wis.wit_tariff_information","package":"jdg.wis","priority":1825,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WIT — Wiążąca Informacja Taryfowa dla ceł (3 lata)","_legal_basis":"Art. 33 UKC (Unijny Kodeks Celny)","_warnings":["Import spoza UE — uzyskaj WIT. Ważność 3 lata od wydania"]} {
    object.get(input.invoice, "wis_required", false) == true
    object.get(input.invoice, "wit_required", false) == true
}

# jdg.wis.wia_excise_information — P1826: WIA dla wyrobów akcyzowych
else :=   {"matched":true,"rule_id":"jdg.wis.wia_excise_information","package":"jdg.wis","priority":1826,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"WIA — Wiążąca Informacja Akcyzowa dla alkoholu, tytoniu, energii","_legal_basis":"Ustawa o podatku akcyzowym","_warnings":["Wyroby akcyzowe — uzyskaj WIA dla pewności klasyfikacji"]} {
    object.get(input.invoice, "wis_required", false) == true
    object.get(input.invoice, "wia_required", false) == true
}

# jdg.wis.cost_benefit_analysis — P1827: Analiza opłacalności WIS/WIT/WIA (ostatni else)
else :=   {"matched":true,"rule_id":"jdg.wis.cost_benefit_analysis","package":"jdg.wis","priority":1827,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Analiza opłacalności — koszt WIS 40 PLN vs ryzyko błędnej stawki","_legal_basis":"Art. 42a-42h VAT","_warnings":["WIS kosztuje 40 PLN — porównaj z ryzykiem uszczuplenia VAT od błędnej stawki"]} {
    object.get(input.invoice, "wis_required", false) == true
    object.get(input.invoice, "wis_obtained", false) == false
    object.get(input.invoice, "cost_benefit_done", false) == false
}
