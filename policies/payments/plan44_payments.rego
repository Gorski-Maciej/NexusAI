# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.payments (Doc 44: P1990-P1998)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 9
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.payments
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.payments.no_match","package":"jdg.payments","priority":99999}

# jdg.payments.crypto_as_payment — Przyjęcie krypto jako zapłaty — przychód wg kursu PLN
decide :=   {"matched":true,"rule_id":"jdg.payments.crypto_as_payment","package":"jdg.payments","priority":1990,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przyjęcie krypto jako zapłaty — przychód wg kursu PLN","_legal_basis":"Art. 14 ust. 1 PIT","_warnings":["Zapłata w krypto — przelicz na PLN wg kursu z dnia transakcji"]} {
    object.get(input.invoice, "amount_gross", 0) > 0
    object.get(input.invoice, "payment_method", "") == "CRYPTO"
}

# jdg.payments.barter_transaction — P1991: Barter (nie krypto)
else :=   {"matched":true,"rule_id":"jdg.payments.barter_transaction","package":"jdg.payments","priority":1991,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Transakcje barterowe — dwustronna dostawa dla VAT","_legal_basis":"Art. 7, 8 VAT","_warnings":["Barter — każda strona wystawia fakturę VAT"]} {
    object.get(input.invoice, "amount_gross", 0) > 0
    object.get(input.invoice, "payment_method", "") == "BARTER"
}

# jdg.payments.offsetting_kompensata — P1992: Kompensata (nie barter)
else :=   {"matched":true,"rule_id":"jdg.payments.offsetting_kompensata","package":"jdg.payments","priority":1992,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kompensata wzajemnych wierzytelności","_legal_basis":"Art. 498 KC","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
    object.get(input.invoice, "payment_method", "") == "OFFSET"
}

# jdg.payments.instalment_recognition — P1993: Raty (nie kompensata)
else :=   {"matched":true,"rule_id":"jdg.payments.instalment_recognition","package":"jdg.payments","priority":1993,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprzedaż na raty — przychód w dacie każdej raty","_legal_basis":"Art. 14 PIT","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
    object.get(input.invoice, "payment_method", "") == "INSTALLMENTS"
}

# jdg.payments.advance_vat_obligation — P1994: Zaliczka — obowiązek VAT w dacie otrzymania
else :=   {"matched":true,"rule_id":"jdg.payments.advance_vat_obligation","package":"jdg.payments","priority":1994,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zaliczka — obowiązek VAT w dacie otrzymania","_legal_basis":"Art. 19a ust. 8 VAT","_warnings":["Otrzymano zaliczkę — wystaw fakturę zaliczkową w 15 dni!"]} {
    object.get(input.invoice, "amount_gross", 0) > 0
    object.get(input.invoice, "is_advance_payment", false) == true
}

# jdg.payments.payment_in_kind — P1995: In-kind (nie zaliczka)
else :=   {"matched":true,"rule_id":"jdg.payments.payment_in_kind","package":"jdg.payments","priority":1995,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Świadczenie niepieniężne — wartość rynkowa jako podstawa PIT i VAT","_legal_basis":"Art. 14 PIT, Art. 29a VAT","_warnings":["Świadczenie niepieniężne — przychód wg wartości rynkowej"]} {
    object.get(input.invoice, "amount_gross", 0) > 0
    object.get(input.invoice, "payment_method", "") == "IN_KIND"
}

# jdg.payments.fx_cash_payment_limit — P1996: Limit płatności gotówkowych w walucie obcej — 15k PLN
else :=   {"matched":true,"rule_id":"jdg.payments.fx_cash_payment_limit","package":"jdg.payments","priority":1996,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Limit 15k PLN dla płatności gotówkowych w walucie obcej","_legal_basis":"Art. 19 Prawa przedsiębiorców","_warnings":["Płatność gotówkowa w walucie obcej — limit 15 000 PLN równowartości"]} {
    object.get(input.invoice, "amount_gross", 0) > 0
    object.get(input.invoice, "fx_cash_payment", false) == true
}

# jdg.payments.electronic_payment_vat — P1997: Przelew na białą listę — warunek odliczenia VAT >15k
else :=   {"matched":true,"rule_id":"jdg.payments.electronic_payment_vat","package":"jdg.payments","priority":1997,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Przelew na białą listę — warunek odliczenia VAT dla transakcji >15k PLN","_legal_basis":"Art. 96b VAT","_warnings":["Transakcja >15k PLN — zapłać przelewem na rachunek z białej listy!"]} {
    object.get(input.invoice, "amount_gross", 0) > 15000
}

# jdg.payments.card_terminal_obligation — P1998: Terminal (B2C, po przelewie)
else :=   {"matched":true,"rule_id":"jdg.payments.card_terminal_obligation","package":"jdg.payments","priority":1998,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Obowiązek terminala — B2C, obrót >20k EUR/rok, >50% transakcji z konsumentami","_legal_basis":"Ustawa o usługach płatniczych","_warnings":["Brak terminala płatniczego — kara do 5000 PLN. Obowiązek: B2C >20k EUR/rok"]} {
    object.get(input.invoice, "amount_gross", 0) > 0
    object.get(input.jdg_entrepreneur, "terminal_required", false) == true
    object.get(input.jdg_entrepreneur, "terminal_installed", false) == false
}
