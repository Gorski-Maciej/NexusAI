# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.procurement (Doc 44: P1880-P1886)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 7
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.procurement
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.procurement.no_match","package":"jdg.procurement","priority":99999}

# jdg.procurement.tax_clearance — P1880: Zaświadczenie o niezaleganiu dla zamówień publicznych
decide :=   {"matched":true,"rule_id":"jdg.procurement.tax_clearance","package":"jdg.procurement","priority":1880,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaświadczenie o niezaleganiu dla zamówień publicznych","_legal_basis":"Art. 306e Ordynacji podatkowej","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.procurement.eu_funds_certificate — P1881: Zaświadczenie dla środków UE (bez procedury)
else :=   {"matched":true,"rule_id":"jdg.procurement.eu_funds_certificate","package":"jdg.procurement","priority":1881,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaświadczenie dla beneficjentów funduszy UE — dodatkowe wymogi","_legal_basis":"Art. 306e Ordynacji podatkowej","_warnings":["Środki UE — dodatkowe zaświadczenie o niezaleganiu wymagane"]} {
    object.get(input.document, "public_procurement_active", false) == true
    object.get(input.document, "eu_funds_involved", false) == true
}

# jdg.procurement.clearance_procedure — P1882: Procedura uzyskania zaświadczenia — 7/3 dni
else :=   {"matched":true,"rule_id":"jdg.procurement.clearance_procedure","package":"jdg.procurement","priority":1882,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wniosek przez e-US — termin 7 dni (standard) / 3 dni (tryb pilny+opłata)","_legal_basis":"Art. 306n Ordynacji podatkowej","_warnings":["Zaświadczenie — złóż wniosek przez e-US. Termin: 7 dni standard, 3 dni tryb pilny"]} {
    object.get(input.document, "public_procurement_active", false) == true
    object.get(input.document, "clearance_procedure_started", false) == true
}

# jdg.procurement.tax_arrears_impact — P1883: Wykluczenie z PZP (bez ZUS clearance)
else :=   {"matched":true,"rule_id":"jdg.procurement.tax_arrears_impact","package":"jdg.procurement","priority":1883,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Zaległości podatkowe — wykluczenie z zamówień publicznych","_legal_basis":"Art. 108 ust. 1 pkt 4 PZP","_warnings":["Zaległości podatkowe = wykluczenie obligatoryjne z zamówień publicznych!"]} {
    object.get(input.document, "public_procurement_active", false) == true
    object.get(input.jdg_entrepreneur, "has_tax_arrears", false) == true
}

# jdg.procurement.zus_clearance — P1884: Zaświadczenie ZUS o niezaleganiu
else :=   {"matched":true,"rule_id":"jdg.procurement.zus_clearance","package":"jdg.procurement","priority":1884,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaświadczenie ZUS o niezaleganiu — wymagane obok podatkowego","_legal_basis":"Art. 22-24 PZP","_warnings":["Zaświadczenie ZUS wymagane obok zaświadczenia podatkowego dla zamówień publicznych"]} {
    object.get(input.document, "public_procurement_active", false) == true
    object.get(input.document, "zus_clearance_required", false) == true
}

# jdg.procurement.tax_representation — P1885: Przedstawiciel podatkowy (JDG zagraniczne)
else :=   {"matched":true,"rule_id":"jdg.procurement.tax_representation","package":"jdg.procurement","priority":1885,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przedstawiciel podatkowy — JDG zagraniczne ubiegające się o zamówienia w PL","_legal_basis":"Art. 22 PZP","_warnings":["JDG zagraniczne — wskaż przedstawiciela podatkowego dla zamówień w PL"]} {
    object.get(input.document, "public_procurement_active", false) == true
    object.get(input.jdg_entrepreneur, "tax_residence", "PL") != "PL"
}

# jdg.procurement.bid_bond_tax — P1886: Wadium w przetargach — KUP, VAT
else :=   {"matched":true,"rule_id":"jdg.procurement.bid_bond_tax","package":"jdg.procurement","priority":1886,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wadium — KUP, moment zaliczenia, VAT","_legal_basis":"Art. 22 PIT, Art. 19a VAT","_warnings":["Wadium — KUP w dacie wpłaty. Zwrot wadium nie jest przychodem"]} {
    object.get(input.document, "public_procurement_active", false) == true
    object.get(input.document, "bid_bond_paid", false) == true
}
