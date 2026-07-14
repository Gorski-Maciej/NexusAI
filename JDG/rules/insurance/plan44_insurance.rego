# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.insurance (Doc 44: P1980-P1985)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 6
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.insurance
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.insurance.no_match","package":"jdg.insurance","priority":99999}

# jdg.insurance.mandatory_detection — P1980: Identyfikacja obowiązkowych OC wg branży
decide :=   {"matched":true,"rule_id":"jdg.insurance.mandatory_detection","package":"jdg.insurance","priority":1980,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Obowiązkowe OC — przewoźnik, prawnik, lekarz, architekt, budowlanka","_legal_basis":"Ustawy branżowe","_warnings":["Twoja branża wymaga obowiązkowego OC — sprawdź czy polisa jest aktualna!"]} {
    object.get(input.jdg_entrepreneur, "requires_mandatory_insurance", false) == true
}

# jdg.insurance.premium_kup — P1981: Składka OC obowiązkowego — KUP 100%
else :=   {"matched":true,"rule_id":"jdg.insurance.premium_kup","package":"jdg.insurance","priority":1981,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"LEGAL_INSURANCE","kus_percent":100,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"OC obowiązkowe — składka KUP w 100%","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Składka na obowiązkowe OC — KUP w 100%, nawet z elementami ponadobowiązkowymi"]} {
    object.get(input.jdg_entrepreneur, "requires_mandatory_insurance", false) == true
}

# jdg.insurance.voluntary_kup — P1982: Dobrowolne OC — KUP do wartości rynkowej
else :=   {"matched":true,"rule_id":"jdg.insurance.voluntary_kup","package":"jdg.insurance","priority":1982,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"VOLUNTARY_INSURANCE","kus_percent":100,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dobrowolne ubezpieczenia — KUP ograniczone do wartości rynkowej","_legal_basis":"Art. 22 PIT","_warnings":["Dobrowolne ubezpieczenie — KUP tylko do wartości rynkowej składki"]} {
    object.get(input.jdg_entrepreneur, "requires_mandatory_insurance", false) == true
}

# jdg.insurance.claim_tax_treatment — P1983: Odszkodowanie — przychód pomniejszony o stratę
else :=   {"matched":true,"rule_id":"jdg.insurance.claim_tax_treatment","package":"jdg.insurance","priority":1983,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odszkodowanie — przychód PIT, pomniejszony o stratę której dotyczyło","_legal_basis":"Art. 14 PIT","_warnings":["Odszkodowanie — przychód, ale pomniejszony o stratę, której dotyczyło"]} {
    object.get(input.jdg_entrepreneur, "requires_mandatory_insurance", false) == true
}

# jdg.insurance.vat_treatment — P1984: VAT od ubezpieczeń — zwolnione, assistance może być 23%
else :=   {"matched":true,"rule_id":"jdg.insurance.vat_treatment","package":"jdg.insurance","priority":1984,"vat_rate":"zw","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ubezpieczenia — zwolnione z VAT, assistance dodatkowe — 23%","_legal_basis":"Art. 43 ust. 1 pkt 37 VAT","_warnings":["Ubezpieczenia zwolnione z VAT. Usługi assistance mogą być opodatkowane 23%"]} {
    object.get(input.jdg_entrepreneur, "requires_mandatory_insurance", false) == true
}

# jdg.insurance.gap_detection — P1985: Wykrywanie luk w OC — kara + odpowiedzialność
else :=   {"matched":true,"rule_id":"jdg.insurance.gap_detection","package":"jdg.insurance","priority":1985,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Brak obowiązkowego OC — kara administracyjna + odpowiedzialność osobista","_legal_basis":"Ustawy branżowe","_warnings":["Brak obowiązkowego OC — kara + odpowiedzialność odszkodowawcza osobista!"]} {
    object.get(input.jdg_entrepreneur, "requires_mandatory_insurance", false) == true
}
