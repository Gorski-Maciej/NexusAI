# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.advertising
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 4
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.advertising
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.advertising.no_match","package":"jdg.advertising","priority":99999}

# jdg.advertising.vs_representation — Rozróżnienie reklama (KUP) vs reprezentacja (NKUP)
decide :=   {"matched":true,"rule_id":"jdg.advertising.vs_representation","package":"jdg.advertising","priority":1999,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Rozróżnienie reklama (KUP) vs reprezentacja (NKUP)","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Wydatek może być reprezentacją (NKUP), nie reklamą — zweryfikuj"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.advertising.gifts_limit_200 — Prezenty dla kontrahentów — limit 200 PLN, tylko z logo
else :=   {"matched":true,"rule_id":"jdg.advertising.gifts_limit_200","package":"jdg.advertising","priority":2002,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Prezenty dla kontrahentów — limit 200 PLN, tylko z logo","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Prezent >200 PLN lub bez logo — NKUP jako reprezentacja"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.advertising.sponsorship_kup — Sponsoring — KUP z kontrświadczeniem, darowizna bez
else :=   {"matched":true,"rule_id":"jdg.advertising.sponsorship_kup","package":"jdg.advertising","priority":2003,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Sponsoring — KUP z kontrświadczeniem, darowizna bez","_legal_basis":"Art. 22 PIT, Art. 26 PIT","_warnings":["Sponsoring bez kontrświadczeń traktowany jak darowizna — limit 6%"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.advertising.car_wrapping_vat26 — Oklejenie auta reklamą — VAT-26 → 100% odliczenia
else :=   {"matched":true,"rule_id":"jdg.advertising.car_wrapping_vat26","package":"jdg.advertising","priority":2006,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Oklejenie auta reklamą — VAT-26 → 100% odliczenia","_legal_basis":"Art. 86a VAT","_warnings":["Oklejenie reklamowe — złóż VAT-26 dla 100% odliczenia VAT"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}
