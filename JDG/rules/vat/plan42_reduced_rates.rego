# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.vat.reduced_rates
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 6
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.vat.reduced_rates
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.vat.reduced_rates.no_match","package":"jdg.vat.reduced_rates","priority":99999}

# jdg.vat.reduced_rate_8pct_food — Walidacja stawki 8% VAT dla żywności
decide :=   {"matched":true,"rule_id":"jdg.vat.reduced_rate_8pct_food","package":"jdg.vat.reduced_rates","priority":66,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Walidacja stawki 8% VAT dla żywności","_legal_basis":"Rozporządzenie MF z 4.12.2024 r. ws. obniżonych stawek VAT","_warnings":["Kod CN nie pasuje do stawki 8% — sprawdź klasyfikację"]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.08
}

# jdg.vat.reduced_rate_5pct_books — Walidacja stawki 5% VAT dla książek/e-booków
else :=   {"matched":true,"rule_id":"jdg.vat.reduced_rate_5pct_books","package":"jdg.vat.reduced_rates","priority":67,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Walidacja stawki 5% VAT dla książek/e-booków","_legal_basis":"Rozporządzenie MF z 4.12.2024 r., Załącznik nr 2","_warnings":["Kod CN nie pasuje do stawki 5% dla książek"]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.05
}

# jdg.vat.rate_8pct_construction — Stawka 8% VAT dla budownictwa mieszkaniowego
else :=   {"matched":true,"rule_id":"jdg.vat.rate_8pct_construction","package":"jdg.vat.reduced_rates","priority":68,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Stawka 8% VAT dla budownictwa mieszkaniowego","_legal_basis":"Art. 41 ust. 12-12c VAT","_warnings":["Budynek nie spełnia kryteriów budownictwa mieszkaniowego dla stawki 8%"]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.08; object.get(input.invoice, "category_code", "") == "CONSTRUCTION"
}

# jdg.vat.rate_8pct_medical — Stawka 8% VAT dla sprzętu medycznego
else :=   {"matched":true,"rule_id":"jdg.vat.rate_8pct_medical","package":"jdg.vat.reduced_rates","priority":70,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"TRIAGE_QUEUE","_routing_reason":"Stawka 8% VAT dla sprzętu medycznego","_legal_basis":"Rozporządzenie MF z 4.12.2024 r., Załącznik nr 1","_warnings":["Sprzęt nie kwalifikuje się jako wyrób medyczny — stawka 23%"]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.08; object.get(input.invoice, "category_code", "") == "HEALTHCARE"
}

# jdg.vat.rate_5pct_baby — Stawka 5% VAT dla produktów dla niemowląt
else :=   {"matched":true,"rule_id":"jdg.vat.rate_5pct_baby","package":"jdg.vat.reduced_rates","priority":71,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Stawka 5% VAT dla produktów dla niemowląt","_legal_basis":"Rozporządzenie MF z 4.12.2024 r., Załącznik nr 2","_warnings":["Produkt spoza listy artykułów dziecięcych objętych stawką 5%"]} {
    object.get(input.invoice, "vat_rate", 0.0) == 0.05
}

# jdg.vat.reduced_rate_cross_check — Cross-check wszystkich obniżonych stawek VAT
else :=   {"matched":true,"rule_id":"jdg.vat.reduced_rate_cross_check","package":"jdg.vat.reduced_rates","priority":72,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Cross-check wszystkich obniżonych stawek VAT","_legal_basis":"Art. 64 KKS — procedury audytowe","_warnings":["Nietypowy udział obniżonych stawek VAT — zalecany audyt"]} {
    object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"
}
