# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.taxfree (Doc 44: P1920-P1925)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 6
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.taxfree
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.taxfree.no_match","package":"jdg.taxfree","priority":99999}

# jdg.taxfree.multi_source — P1920: Kwota wolna 30k przy wielu źródłach — JDG+etat+najem+kapitały
decide :=   {"matched":true,"rule_id":"jdg.taxfree.multi_source","package":"jdg.taxfree","priority":1920,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"PIT_SCALE","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kwota wolna 30k — interakcja JDG + etat + najem + kapitały","_legal_basis":"Art. 27 ust. 1 PIT","_warnings":["Kwota wolna 30k stosowana łącznie — nie dubluj jej między źródłami!"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}

# jdg.taxfree.jdg_vs_employment — P1921: JDG na skali + etat — kwota wolna łącznie
else :=   {"matched":true,"rule_id":"jdg.taxfree.jdg_vs_employment","package":"jdg.taxfree","priority":1921,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"PIT_SCALE","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"JDG + etat — pracodawca stosuje 1/12 kwoty (250 PLN/mies.), JDG nie","_legal_basis":"Art. 32 ust. 3 PIT","_warnings":["JDG na skali z etatem — pracodawca stosuje 250 PLN/mies. kwoty wolnej, JDG nie"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}

# jdg.taxfree.linear_lump_sum_exclusion — P1922: Kwota wolna NIE dotyczy liniowego i ryczałtu
else :=   {"matched":true,"rule_id":"jdg.taxfree.linear_lump_sum_exclusion","package":"jdg.taxfree","priority":1922,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kwota wolna tylko dla skali — liniowy i ryczałt bez kwoty wolnej","_legal_basis":"Art. 27, 30c, 30 PIT","_warnings":["Kwota wolna 30k NIE dotyczy podatku liniowego i ryczałtu — tylko skala podatkowa!"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}

# jdg.taxfree.deduction_optimization — P1923: Wspólne rozliczenie — 60k kwoty wolnej
else :=   {"matched":true,"rule_id":"jdg.taxfree.deduction_optimization","package":"jdg.taxfree","priority":1923,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"PIT_SCALE","pit_rate":"","pit_bracket":"","pit_annual_return_type":"JOINT","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wspólne rozliczenie z małżonkiem → 60k kwoty wolnej","_legal_basis":"Art. 6 ust. 2 PIT","_warnings":["Wspólne rozliczenie z małżonkiem daje 60 000 PLN łącznej kwoty wolnej"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}

# jdg.taxfree.withholding_tax — P1924: WHT nie korzysta z kwoty wolnej — ryczałt 19/20%
else :=   {"matched":true,"rule_id":"jdg.taxfree.withholding_tax","package":"jdg.taxfree","priority":1924,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatek u źródła — brak kwoty wolnej (ryczałt 19/20%)","_legal_basis":"Art. 29-30a PIT","_warnings":["WHT — podatek u źródła nie korzysta z kwoty wolnej (ryczałt 19/20%)"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}

# jdg.taxfree.foreign_income — P1925: Dochody zagraniczne — kwota wolna tylko od dochodów PL
else :=   {"matched":true,"rule_id":"jdg.taxfree.foreign_income","package":"jdg.taxfree","priority":1925,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"PIT_SCALE","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochody zagraniczne (metoda progresji) — kwota wolna tylko od dochodów PL","_legal_basis":"Art. 27 ust. 8 PIT","_warnings":["Dochody zagraniczne opodatkowane metodą progresji — kwota wolna stosowana tylko do PL"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}
