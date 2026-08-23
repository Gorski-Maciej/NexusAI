# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.zus
# Generated from Plan OPA specifications: 2026-07-13 14:05:06
# Rules: 9
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.zus
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.zus.plan23.no_match","package":"jdg.zus","priority":99999}

# jdg.zus.health_contribution_rate_matrix — Macierz mapowania forma→składka zdrowotna
decide :=   {"matched":true,"rule_id":"jdg.zus.health_contribution_rate_matrix","package":"jdg.zus","priority":730,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Macierz mapowania forma→składka zdrowotna","_legal_basis":"Art. 81 ustawy o świadczeniach zdrowotnych","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.form_change_contribution_trigger — Alert o przeliczeniu ZUS DRA po zmianie formy
else :=   {"matched":true,"rule_id":"jdg.zus.form_change_contribution_trigger","package":"jdg.zus","priority":732,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Alert o przeliczeniu ZUS DRA po zmianie formy","_legal_basis":"Art. 81 ust. 2 ustawy o świadczeniach zdrowotnych","_warnings":["Zmiana formy — zaktualizuj ZUS DRA od nowego roku"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.tax_card_health_fixed — Karta podatkowa — składka zdrowotna 9% min. wynagrodzenia
else :=   {"matched":true,"rule_id":"jdg.zus.tax_card_health_fixed","package":"jdg.zus","priority":736,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Karta podatkowa — składka zdrowotna 9% min. wynagrodzenia","_legal_basis":"Art. 81 ust. 2za ustawy o świadczeniach zdrowotnych","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.health_insurance_obligation — Obowiązek ubezpieczenia zdrowotnego — każda aktywna JDG
else :=   {"matched":true,"rule_id":"jdg.zus.health_insurance_obligation","package":"jdg.zus","priority":739,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiązek ubezpieczenia zdrowotnego — każda aktywna JDG","_legal_basis":"Art. 66 ust. 1 pkt 1c ustawy o świadczeniach zdrowotnych","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.concurrent_employment_exemption — Zbieg etat+JDG — tylko składka zdrowotna z JDG
else :=   {"matched":true,"rule_id":"jdg.zus.concurrent_employment_exemption","package":"jdg.zus","priority":743,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zbieg etat+JDG — tylko składka zdrowotna z JDG","_legal_basis":"Art. 9 ust. 1a-2 SUS","_warnings":["Zbieg etat+JDG — z JDG płacisz tylko składkę zdrowotną"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "has_employment_contract", false) == true
}

# jdg.zus.insurance_cessation_dates — Ustanie ubezpieczeń — zamknięcie JDG / brak chorobowej 30 dni
else :=   {"matched":true,"rule_id":"jdg.zus.insurance_cessation_dates","package":"jdg.zus","priority":744,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Ustanie ubezpieczeń — zamknięcie JDG / brak chorobowej 30 dni","_legal_basis":"Art. 8-9, Art. 14 SUS","_warnings":["Dobrowolne chorobowe wygasło — brak składki >30 dni"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "zus_sickness_voluntary", false) == true; object.get(input.jdg_entrepreneur, "business_status", "") == "CLOSED"
}

# jdg.zus.payment_deadline_per_entity_type — Termin ZUS: 10/15/20 dzień wg typu JDG
else :=   {"matched":true,"rule_id":"jdg.zus.payment_deadline_per_entity_type","package":"jdg.zus","priority":745,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Termin ZUS: 10/15/20 dzień wg typu JDG","_legal_basis":"Art. 47 SUS","_warnings":["Składki ZUS po terminie!"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.dra_filing_deadline_check — Deklaracja DRA — do 15. (z pracownikami) lub 20.
else :=   {"matched":true,"rule_id":"jdg.zus.dra_filing_deadline_check","package":"jdg.zus","priority":746,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Deklaracja DRA — do 15. (z pracownikami) lub 20.","_legal_basis":"Art. 16-17 SUS","_warnings":["ZUS DRA niezłożona w terminie!"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.zus.health_payment_deadline_check — Składka zdrowotna — ten sam termin co społeczne
else :=   {"matched":true,"rule_id":"jdg.zus.health_payment_deadline_check","package":"jdg.zus","priority":748,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Składka zdrowotna — ten sam termin co społeczne","_legal_basis":"Art. 82 ustawy o świadczeniach zdrowotnych","_warnings":["Składka zdrowotna po terminie!"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"; object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}
