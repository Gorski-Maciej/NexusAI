# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.payments
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 5
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.payments
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.payments.no_match","package":"jdg.payments","priority":99999}

# jdg.payments.crypto_as_payment — Przyjęcie krypto jako zapłaty — przychód wg kursu PLN
decide :=   {"matched":true,"rule_id":"jdg.payments.crypto_as_payment","package":"jdg.payments","priority":1990,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przyjęcie krypto jako zapłaty — przychód wg kursu PLN","_legal_basis":"Art. 14 ust. 1 PIT","_warnings":["Zapłata w krypto — przelicz na PLN wg kursu z dnia transakcji"]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.payments.barter_transaction — Transakcje barterowe — dwustronna dostawa dla VAT
else :=   {"matched":true,"rule_id":"jdg.payments.barter_transaction","package":"jdg.payments","priority":1991,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Transakcje barterowe — dwustronna dostawa dla VAT","_legal_basis":"Art. 7, 8 VAT","_warnings":["Barter — każda strona wystawia fakturę VAT"]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.payments.offsetting_kompensata — Kompensata wzajemnych wierzytelności
else :=   {"matched":true,"rule_id":"jdg.payments.offsetting_kompensata","package":"jdg.payments","priority":1992,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kompensata wzajemnych wierzytelności","_legal_basis":"Art. 498 KC","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.payments.instalment_recognition — Sprzedaż na raty — przychód w dacie każdej raty
else :=   {"matched":true,"rule_id":"jdg.payments.instalment_recognition","package":"jdg.payments","priority":1993,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprzedaż na raty — przychód w dacie każdej raty","_legal_basis":"Art. 14 PIT","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.payments.advance_vat_obligation — Zaliczka — obowiązek VAT w dacie otrzymania
else :=   {"matched":true,"rule_id":"jdg.payments.advance_vat_obligation","package":"jdg.payments","priority":1994,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zaliczka — obowiązek VAT w dacie otrzymania","_legal_basis":"Art. 19a ust. 8 VAT","_warnings":["Otrzymano zaliczkę — wystaw fakturę zaliczkową w 15 dni!"]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}
