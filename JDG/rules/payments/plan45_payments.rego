# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.payments hyper-granularity (Doc 45: R1636-R1673)
# Atom rules: crypto, barter, offset, installments, advances, in-kind, foreign, terminal
# Rules: 38 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.payments.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.payments.hyper.no_match","package":"jdg.payments.hyper","priority":99999}

# ══ Crypto (R1636-R1640) ══
decide := {"matched":true,"rule_id":"jdg.payments.hyper.crypto_revenue_recognition","package":"jdg.payments.hyper","priority":1636,"_routing":"WARNING","_routing_reason":"Krypto: przychód w dacie otrzymania po kursie giełdowym","_legal_basis":"Art. 14 ust. 1 PIT","_warnings":["Zapłata w krypto — przychód wg kursu PLN z dnia transakcji"]} {
    object.get(input.invoice, "payment_method", "") == "CRYPTO"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.crypto_vat_on_receipt","package":"jdg.payments.hyper","priority":1637,"_routing":"WARNING","_routing_reason":"Krypto: VAT w dacie otrzymania","_legal_basis":"Art. 19a ust. 8 VAT","_warnings":["Krypto-zapłata — obowiązek VAT w dacie otrzymania"]} {
    object.get(input.invoice, "payment_method", "") == "CRYPTO"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.crypto_vs_trading_distinction","package":"jdg.payments.hyper","priority":1640,"_routing":"","_routing_reason":"Krypto: zapłata ≠ trading","_legal_basis":"Art. 14 vs 17 PIT","_warnings":["Krypto jako zapłata (przychód) ≠ krypto jako inwestycja (zyski kapitałowe)"]} {
    object.get(input.invoice, "payment_method", "") == "CRYPTO"
}

# ══ Barter (R1641-R1645) ══
else := {"matched":true,"rule_id":"jdg.payments.hyper.barter_double_supply","package":"jdg.payments.hyper","priority":1641,"_routing":"WARNING","_routing_reason":"Barter: dwie dostawy","_legal_basis":"Art. 7, 8 VAT","_warnings":["Barter — każda strona wystawia fakturę za swoje świadczenie"]} {
    object.get(input.invoice, "payment_method", "") == "BARTER"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.barter_market_value_base","package":"jdg.payments.hyper","priority":1643,"_routing":"","_routing_reason":"Barter: podstawa = wartość rynkowa","_legal_basis":"Art. 29a VAT","_warnings":["Barter — podstawa opodatkowania: wartość rynkowa wymienianych świadczeń"]} {
    object.get(input.invoice, "payment_method", "") == "BARTER"
}

# ══ Kompensata (R1646-R1650) ══
else := {"matched":true,"rule_id":"jdg.payments.hyper.offset_recognition_date","package":"jdg.payments.hyper","priority":1646,"_routing":"","_routing_reason":"Kompensata: data potrącenia = data zapłaty","_legal_basis":"Art. 498 KC, Art. 14 PIT","_warnings":["Kompensata — uznana za zapłatę w dacie potrącenia"]} {
    object.get(input.invoice, "payment_method", "") == "OFFSET"
}

# ══ Raty (R1651-R1655) / Zaliczki (R1656-R1660) ══
else := {"matched":true,"rule_id":"jdg.payments.hyper.installments_pit_per_installment","package":"jdg.payments.hyper","priority":1651,"_routing":"","_routing_reason":"Raty: przychód PIT w dacie każdej raty","_legal_basis":"Art. 14 PIT","_warnings":["Sprzedaż na raty — przychód w dacie otrzymania każdej raty"]} {
    object.get(input.invoice, "payment_method", "") == "INSTALLMENTS"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.advance_invoice_15days","package":"jdg.payments.hyper","priority":1657,"_routing":"WARNING","_routing_reason":"Zaliczka: faktura w 15 dni","_legal_basis":"Art. 106i VAT","_warnings":["Otrzymano zaliczkę — wystaw fakturę zaliczkową w 15 dni!"]} {
    object.get(input.invoice, "payment_method", "") == "ADVANCE"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.advance_retained_taxable","package":"jdg.payments.hyper","priority":1659,"_routing":"","_routing_reason":"Zaliczka zatrzymana — opodatkowana","_legal_basis":"Art. 14 PIT","_warnings":["Niezwrócona zaliczka przy zerwaniu umowy — opodatkowana"]} {
    object.get(input.invoice, "payment_method", "") == "ADVANCE"
}

# ══ In-kind / Foreign / Terminal ══
else := {"matched":true,"rule_id":"jdg.payments.hyper.inkind_market_value","package":"jdg.payments.hyper","priority":1661,"_routing":"","_routing_reason":"In-kind: wartość rynkowa","_legal_basis":"Art. 14 ust. 2 PIT","_warnings":["Świadczenie niepieniężne — przychód wg wartości rynkowej"]} {
    object.get(input.invoice, "payment_method", "") == "IN_KIND"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.foreign_cash_limit_15k","package":"jdg.payments.hyper","priority":1666,"_routing":"WARNING","_routing_reason":"FX cash: limit 15k PLN","_legal_basis":"Art. 22p PIT","_warnings":["Płatność gotówkowa w walucie obcej — limit 15 000 PLN równowartości"]} {
    object.get(input.invoice, "amount_gross", 0) >= 15000
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.terminal_obligation_20k_eur","package":"jdg.payments.hyper","priority":1671,"_routing":"WARNING","_routing_reason":"Terminal: obowiązek >20k EUR/rok B2C","_legal_basis":"Ustawa o usługach płatniczych","_warnings":["B2C >20k EUR/rok — obowiązek terminala płatniczego!"]} {
    object.get(input.jdg_entrepreneur, "terminal_required", false) == true
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.terminal_penalty_5000","package":"jdg.payments.hyper","priority":1672,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Terminal: kara 5000 PLN","_legal_basis":"Ustawa o usługach płatniczych","_warnings":["Brak terminala — kara do 5 000 PLN!"]} {
    object.get(input.jdg_entrepreneur, "terminal_required", false) == true
}
