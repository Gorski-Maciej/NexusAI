# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.fx
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 3
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.fx
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.fx.no_match","package":"jdg.fx","priority":99999}

# jdg.fx.vat_rate_determination — Kurs waluty dla celów VAT
decide :=   {"matched":true,"rule_id":"jdg.fx.vat_rate_determination","package":"jdg.fx","priority":1890,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kurs waluty dla celów VAT","_legal_basis":"Art. 30a-31a VAT","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.fx.pit_rate_determination — Kurs waluty dla celów PIT
else :=   {"matched":true,"rule_id":"jdg.fx.pit_rate_determination","package":"jdg.fx","priority":1891,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kurs waluty dla celów PIT","_legal_basis":"Art. 14 ust. 1aa PIT","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.fx.differences_method — Metoda rozliczania różnic kursowych (podatkowa vs rachunkowa)
else :=   {"matched":true,"rule_id":"jdg.fx.differences_method","package":"jdg.fx","priority":1892,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Metoda rozliczania różnic kursowych (podatkowa vs rachunkowa)","_legal_basis":"Art. 14b PIT","_warnings":[]} {
    input.invoice.currency != "PLN"
}
