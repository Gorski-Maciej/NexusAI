# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.allowances
# Generated from Plan OPA specifications: 2026-07-13 14:05:06
# Rules: 9
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.allowances
import data.jdg.helpers
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.allowances.plan23.no_match","package":"jdg.allowances","priority":99999}

# jdg.allowances.prototype_relief — Ulga na prototyp — 30% kosztów produkcji próbnej
decide :=   {"matched":true,"rule_id":"jdg.allowances.prototype_relief","package":"jdg.allowances","priority":601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga na prototyp — 30% kosztów produkcji próbnej","_legal_basis":"Art. 26eb PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "PROTOTYPE"
}

# jdg.allowances.robotization_relief — Ulga na robotyzację — 50% kosztów robotów
else :=   {"matched":true,"rule_id":"jdg.allowances.robotization_relief","package":"jdg.allowances","priority":602,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga na robotyzację — 50% kosztów robotów","_legal_basis":"Art. 26gb PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ROBOTIZATION"
}

# jdg.allowances.expansion_relief — Ulga ekspansyjna — max 1M PLN rocznie
else :=   {"matched":true,"rule_id":"jdg.allowances.expansion_relief","package":"jdg.allowances","priority":603,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga ekspansyjna — max 1M PLN rocznie","_legal_basis":"Art. 26ec PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "EXPANSION"
}

# jdg.allowances.rehabilitation_relief — Ulga rehabilitacyjna dla JDG z niepełnosprawnością
else :=   {"matched":true,"rule_id":"jdg.allowances.rehabilitation_relief","package":"jdg.allowances","priority":604,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga rehabilitacyjna dla JDG z niepełnosprawnością","_legal_basis":"Art. 26 ust. 1 pkt 6 PIT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.allowances.internet_relief — Ulga internetowa — max 760 PLN/rok przez 2 lata
else :=   {"matched":true,"rule_id":"jdg.allowances.internet_relief","package":"jdg.allowances","priority":605,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga internetowa — max 760 PLN/rok przez 2 lata","_legal_basis":"Art. 26 ust. 1 pkt 6a PIT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.allowances.donation_ngo_relief — Darowizna OPP — limit 6% dochodu
else :=   {"matched":true,"rule_id":"jdg.allowances.donation_ngo_relief","package":"jdg.allowances","priority":606,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Darowizna OPP — limit 6% dochodu","_legal_basis":"Art. 26 ust. 1 pkt 9 lit. a PIT","_warnings":["Darowizna OPP — sprawdź limit 6% dochodu"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.allowances.donation_blood_relief — Ulga krwiodawcza — 130 PLN/litr
else :=   {"matched":true,"rule_id":"jdg.allowances.donation_blood_relief","package":"jdg.allowances","priority":607,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga krwiodawcza — 130 PLN/litr","_legal_basis":"Art. 26 ust. 1 pkt 9 lit. c PIT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.allowances.donation_church_relief — Darowizna na cele kultu religijnego — limit 6%
else :=   {"matched":true,"rule_id":"jdg.allowances.donation_church_relief","package":"jdg.allowances","priority":608,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Darowizna na cele kultu religijnego — limit 6%","_legal_basis":"Art. 26 ust. 1 pkt 9 lit. b PIT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}

# jdg.allowances.abolition_relief — Ulga abolicyjna dla dochodów zagranicznych
else :=   {"matched":true,"rule_id":"jdg.allowances.abolition_relief","package":"jdg.allowances","priority":609,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Ulga abolicyjna dla dochodów zagranicznych","_legal_basis":"Art. 27g PIT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}
}
