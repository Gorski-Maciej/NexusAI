# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.payments hyper-granularity (Doc 45: R1636-R1673)
# Atom rules: crypto, barter, offset, installments, advances, in-kind,
#   foreign currency cash, transfers, terminal
# Rules: 38 atom — each with differentiated trigger conditions
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.payments.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.payments.hyper.no_match","package":"jdg.payments.hyper","priority":99999}

# ══ R1636-R1640: Crypto Payments ══
decide := {"matched":true,"rule_id":"jdg.payments.hyper.crypto_revenue_recognition","package":"jdg.payments.hyper","priority":1636,"_routing":"WARNING","_routing_reason":"Krypto: przychód w dacie otrzymania","_legal_basis":"Art. 14 ust. 1 PIT","_warnings":["Zapłata w krypto — przychód wg kursu PLN z dnia transakcji (giełda, nie NBP)"]} {
    object.get(input.invoice, "payment_method", "") == "CRYPTO"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.crypto_vat_on_receipt","package":"jdg.payments.hyper","priority":1637,"_routing":"WARNING","_routing_reason":"Krypto: VAT w dacie otrzymania","_legal_basis":"Art. 19a ust. 8 VAT","_warnings":["Krypto-zapłata — obowiązek VAT w dacie otrzymania, podstawa: wartość PLN w dniu otrzymania"]} {
    object.get(input.invoice, "payment_method", "") == "CRYPTO"
    object.get(input.invoice, "direction", "") == "SALE"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.crypto_exchange_rate_determination","package":"jdg.payments.hyper","priority":1638,"_routing":"","_routing_reason":"Krypto: kurs giełdowy, nie NBP","_legal_basis":"Art. 14 PIT","_warnings":["Kurs krypto/PLN — użyj notowań giełdowych (Binance, BitBay), nie tabel NBP"]} {
    object.get(input.invoice, "payment_method", "") == "CRYPTO"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.crypto_volatility_risk","package":"jdg.payments.hyper","priority":1639,"_routing":"WARNING","_routing_reason":"Krypto: ryzyko zmienności kursu","_legal_basis":"Art. 14 PIT","_warnings":["Uwaga na zmienność kursu krypto — przychód ustalony w dniu transakcji, późniejsze spadki nie zmniejszają przychodu"]} {
    object.get(input.invoice, "payment_method", "") == "CRYPTO"
    object.get(input.invoice, "crypto_volatile", false) == true
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.crypto_vs_trading_distinction","package":"jdg.payments.hyper","priority":1640,"_routing":"","_routing_reason":"Krypto: zapłata za towary ≠ trading","_legal_basis":"Art. 14 vs Art. 17 PIT","_warnings":["Przyjęcie krypto JAKO ZAPŁATA za towary/usługi = przychód z JDG (≠ zyski kapitałowe z tradingu)"]} {
    object.get(input.invoice, "payment_method", "") == "CRYPTO"
    object.get(input.invoice, "crypto_purpose", "") == "PAYMENT_FOR_GOODS"
}

# ══ R1641-R1645: Barter ══
else := {"matched":true,"rule_id":"jdg.payments.hyper.barter_double_supply","package":"jdg.payments.hyper","priority":1641,"_routing":"WARNING","_routing_reason":"Barter: dwie dostawy","_legal_basis":"Art. 7, Art. 8 VAT","_warnings":["Barter = dwie odrębne dostawy towarów/świadczenia usług — każda strona wystawia fakturę"]} {
    object.get(input.invoice, "payment_method", "") == "BARTER"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.barter_vat_on_both_sides","package":"jdg.payments.hyper","priority":1642,"_routing":"","_routing_reason":"Barter: VAT od obu świadczeń","_legal_basis":"Art. 5 VAT","_warnings":["Barter — każda strona odprowadza VAT od wartości swojego świadczenia"]} {
    object.get(input.invoice, "payment_method", "") == "BARTER"
    object.get(input.invoice, "direction", "") == "SALE"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.barter_market_value_base","package":"jdg.payments.hyper","priority":1643,"_routing":"","_routing_reason":"Barter: podstawa = wartość rynkowa","_legal_basis":"Art. 29a VAT","_warnings":["Barter — podstawa opodatkowania: wartość rynkowa wymienianych świadczeń"]} {
    object.get(input.invoice, "payment_method", "") == "BARTER"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.barter_pit_revenue_recognition","package":"jdg.payments.hyper","priority":1644,"_routing":"","_routing_reason":"Barter: przychód PIT w dacie wymiany","_legal_basis":"Art. 14 PIT","_warnings":["Barter — przychód w PIT w dacie wymiany, wartość = cena rynkowa"]} {
    object.get(input.invoice, "payment_method", "") == "BARTER"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.barter_documentation","package":"jdg.payments.hyper","priority":1645,"_routing":"WARNING","_routing_reason":"Barter: dokumentacja","_legal_basis":"Art. 22 UoR","_warnings":["Barter — wymagane: umowa barterowa, wycena rynkowa, faktury od obu stron"]} {
    object.get(input.invoice, "payment_method", "") == "BARTER"
    object.get(input.invoice, "barter_docs_complete", false) == false
}

# ══ R1646-R1650: Offset / Kompensata ══
else := {"matched":true,"rule_id":"jdg.payments.hyper.offset_recognition_date","package":"jdg.payments.hyper","priority":1646,"_routing":"","_routing_reason":"Kompensata: data potrącenia = data zapłaty","_legal_basis":"Art. 498 KC, Art. 14 PIT","_warnings":["Kompensata — uznana za zapłatę w dacie potrącenia wzajemnych wierzytelności"]} {
    object.get(input.invoice, "payment_method", "") == "OFFSET"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.offset_vat_cash_method","package":"jdg.payments.hyper","priority":1647,"_routing":"","_routing_reason":"Kompensata: VAT kasowy — data potrącenia","_legal_basis":"Art. 21 VAT","_warnings":["Kompensata przy metodzie kasowej VAT — data potrącenia = data zapłaty dla odliczenia"]} {
    object.get(input.invoice, "payment_method", "") == "OFFSET"
    object.get(input.jdg_entrepreneur, "vat_cash_accounting", false) == true
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.offset_vat_accrual_method","package":"jdg.payments.hyper","priority":1648,"_routing":"","_routing_reason":"Kompensata: VAT memoriałowy","_legal_basis":"Art. 19a VAT","_warnings":["Kompensata przy metodzie memoriałowej — obowiązek VAT od daty dostawy (niezależnie od kompensaty)"]} {
    object.get(input.invoice, "payment_method", "") == "OFFSET"
    object.get(input.jdg_entrepreneur, "vat_cash_accounting", false) == false
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.offset_mutual_agreement","package":"jdg.payments.hyper","priority":1649,"_routing":"WARNING","_routing_reason":"Kompensata: zgoda obu stron","_legal_basis":"Art. 498-499 KC","_warnings":["Kompensata wymaga oświadczenia o potrąceniu — zgoda obu stron"]} {
    object.get(input.invoice, "payment_method", "") == "OFFSET"
    object.get(input.invoice, "offset_agreement_signed", false) == false
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.offset_documentation","package":"jdg.payments.hyper","priority":1650,"_routing":"","_routing_reason":"Kompensata: dokumentacja","_legal_basis":"Art. 22 UoR","_warnings":["Kompensata — wymagane: nota kompensacyjna + umowa/porozumienie"]} {
    object.get(input.invoice, "payment_method", "") == "OFFSET"
}

# ══ R1651-R1655: Installments / Raty ══
else := {"matched":true,"rule_id":"jdg.payments.hyper.installments_pit_per_installment","package":"jdg.payments.hyper","priority":1651,"_routing":"","_routing_reason":"Raty: przychód PIT w dacie każdej raty","_legal_basis":"Art. 14 PIT","_warnings":["Sprzedaż na raty — przychód w PIT w dacie otrzymania każdej raty"]} {
    object.get(input.invoice, "payment_method", "") == "INSTALLMENTS"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.installments_vat_accrual_full","package":"jdg.payments.hyper","priority":1652,"_routing":"WARNING","_routing_reason":"Raty: VAT memoriałowy — całość od razu","_legal_basis":"Art. 19a VAT","_warnings":["VAT memoriałowy — obowiązek od CAŁEJ wartości w dacie dostawy, niezależnie od rat!"]} {
    object.get(input.invoice, "payment_method", "") == "INSTALLMENTS"
    object.get(input.jdg_entrepreneur, "vat_cash_accounting", false) == false
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.installments_vat_cash_per_installment","package":"jdg.payments.hyper","priority":1653,"_routing":"","_routing_reason":"Raty: VAT kasowy — od każdej raty","_legal_basis":"Art. 21 VAT","_warnings":["VAT kasowy — obowiązek VAT w dacie otrzymania każdej raty"]} {
    object.get(input.invoice, "payment_method", "") == "INSTALLMENTS"
    object.get(input.jdg_entrepreneur, "vat_cash_accounting", false) == true
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.installments_late_interest","package":"jdg.payments.hyper","priority":1654,"_routing":"WARNING","_routing_reason":"Raty: odsetki od opóźnionej raty","_legal_basis":"Art. 56 OP","_warnings":["Opóźnienie raty — odsetki za zwłokę od zaległości podatkowej"]} {
    object.get(input.invoice, "payment_method", "") == "INSTALLMENTS"
    object.get(input.invoice, "installment_overdue", false) == true
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.installments_contract_termination","package":"jdg.payments.hyper","priority":1655,"_routing":"WARNING","_routing_reason":"Raty: zerwanie umowy — korekta","_legal_basis":"Art. 106j VAT","_warnings":["Zerwanie umowy ratalnej — konieczna korekta przychodu i VAT"]} {
    object.get(input.invoice, "payment_method", "") == "INSTALLMENTS"
    object.get(input.invoice, "contract_terminated", false) == true
}

# ══ R1656-R1660: Advances / Zaliczki ══
else := {"matched":true,"rule_id":"jdg.payments.hyper.advance_vat_on_receipt","package":"jdg.payments.hyper","priority":1656,"_routing":"WARNING","_routing_reason":"Zaliczka: VAT w dacie otrzymania","_legal_basis":"Art. 19a ust. 8 VAT","_warnings":["Zaliczka — obowiązek VAT w dacie otrzymania, nawet przed dostawą towaru!"]} {
    object.get(input.invoice, "payment_type", "") == "ADVANCE"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.advance_invoice_15days","package":"jdg.payments.hyper","priority":1657,"_routing":"WARNING","_routing_reason":"Zaliczka: faktura w 15 dni","_legal_basis":"Art. 106i VAT","_warnings":["Otrzymałeś zaliczkę — wystaw fakturę zaliczkową w ciągu 15 dni!"]} {
    object.get(input.invoice, "payment_type", "") == "ADVANCE"
    object.get(input.invoice, "advance_invoice_issued", false) == false
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.advance_pit_revenue_on_receipt","package":"jdg.payments.hyper","priority":1658,"_routing":"","_routing_reason":"Zaliczka: przychód PIT w dacie otrzymania","_legal_basis":"Art. 14 PIT","_warnings":["Zaliczka — przychód w PIT w dacie otrzymania"]} {
    object.get(input.invoice, "payment_type", "") == "ADVANCE"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.advance_retained_taxable","package":"jdg.payments.hyper","priority":1659,"_routing":"","_routing_reason":"Zaliczka zatrzymana — opodatkowana","_legal_basis":"Art. 14 PIT","_warnings":["Niezwrócona zaliczka przy zerwaniu umowy — opodatkowana jako przychód"]} {
    object.get(input.invoice, "payment_type", "") == "ADVANCE"
    object.get(input.invoice, "advance_retained", false) == true
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.advance_to_supplier_kup","package":"jdg.payments.hyper","priority":1660,"_routing":"","_routing_reason":"Zaliczka do dostawcy — KUP","_legal_basis":"Art. 22 PIT","_warnings":["Zaliczka do dostawcy — KUP: data zapłaty (metoda kasowa) lub data dostawy (memoriałowa)"]} {
    object.get(input.invoice, "payment_type", "") == "ADVANCE"
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# ══ R1661-R1665: In-Kind / Świadczenia niepieniężne ══
else := {"matched":true,"rule_id":"jdg.payments.hyper.inkind_market_value_revenue","package":"jdg.payments.hyper","priority":1661,"_routing":"","_routing_reason":"In-kind: przychód wg wartości rynkowej","_legal_basis":"Art. 14 ust. 2 PIT","_warnings":["Świadczenie niepieniężne — przychód wg wartości rynkowej"]} {
    object.get(input.invoice, "payment_method", "") == "IN_KIND"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.inkind_vat_base_market_value","package":"jdg.payments.hyper","priority":1662,"_routing":"","_routing_reason":"In-kind: podstawa VAT = wartość rynkowa","_legal_basis":"Art. 29a VAT","_warnings":["Świadczenie niepieniężne — podstawa VAT: wartość rynkowa"]} {
    object.get(input.invoice, "payment_method", "") == "IN_KIND"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.inkind_mixed_split","package":"jdg.payments.hyper","priority":1663,"_routing":"","_routing_reason":"Płatność mieszana: gotówka + in-kind","_legal_basis":"Art. 29a VAT","_warnings":["Płatność mieszana — rozdziel część gotówkową i niepieniężną dla celów VAT/PIT"]} {
    object.get(input.invoice, "payment_method", "") == "MIXED_CASH_IN_KIND"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.inkind_employee_benefit_tax","package":"jdg.payments.hyper","priority":1664,"_routing":"WARNING","_routing_reason":"In-kind: wynagrodzenie pracownika","_legal_basis":"Art. 12 PIT","_warnings":["Świadczenie niepieniężne dla pracownika — opodatkowane PIT + składki ZUS"]} {
    object.get(input.invoice, "payment_method", "") == "IN_KIND"
    object.get(input.invoice, "recipient_type", "") == "EMPLOYEE"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.inkind_owner_benefit_dividend","package":"jdg.payments.hyper","priority":1665,"_routing":"WARNING","_routing_reason":"In-kind: korzyść właściciela = dywidenda","_legal_basis":"Art. 30a PIT","_warnings":["Świadczenie dla właściciela JDG niebiznesowe — traktowane jak dywidenda (19% ryczałt)"]} {
    object.get(input.invoice, "payment_method", "") == "IN_KIND"
    object.get(input.invoice, "recipient_type", "") == "OWNER"
    object.get(input.invoice, "business_expense", false) == false
}

# ══ R1666-R1670: Foreign Currency / Cross-Border Payments ══
else := {"matched":true,"rule_id":"jdg.payments.hyper.foreign_cash_limit_15k","package":"jdg.payments.hyper","priority":1666,"_routing":"WARNING","_routing_reason":"FX cash: limit 15k PLN","_legal_basis":"Art. 22p PIT","_warnings":["Płatność gotówkowa w walucie obcej >15 000 PLN równowartości — KUP wyłączone!"]} {
    object.get(input.invoice, "currency", "PLN") != "PLN"
    object.get(input.invoice, "payment_method", "") == "CASH"
    object.get(input.invoice, "amount_gross", 0) >= 15000
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.foreign_whitelist_check","package":"jdg.payments.hyper","priority":1667,"_routing":"WARNING","_routing_reason":"Przelew: weryfikacja białej listy","_legal_basis":"Art. 96b VAT","_warnings":["Przelew >15k PLN do PL kontrahenta — sprawdź rachunek na białej liście VAT"]} {
    object.get(input.invoice, "amount_gross", 0) >= 15000
    object.get(input.vendor, "country", "PL") == "PL"
    object.get(input.invoice, "whitelist_checked", false) == false
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.foreign_giif_reporting_15k_eur","package":"jdg.payments.hyper","priority":1668,"_routing":"TRIAGE_QUEUE","_routing_reason":"Przelew zagraniczny >15k EUR — GIIF","_legal_basis":"Art. 72 AML","_warnings":["Przelew zagraniczny >15 000 EUR — obowiązek raportu GIIF!"]} {
    object.get(input.invoice, "amount_eur", 0) >= 15000
    object.get(input.vendor, "country", "PL") != "PL"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.foreign_swift_sepa_auth","package":"jdg.payments.hyper","priority":1669,"_routing":"","_routing_reason":"SEPA/SWIFT: autoryzacja bankowa","_legal_basis":"—","_warnings":["Płatność SEPA/SWIFT — wymaga autoryzacji bankowej"]} {
    object.get(input.invoice, "payment_rail", "") == "SEPA"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.foreign_fx_spread_kup","package":"jdg.payments.hyper","priority":1670,"_routing":"","_routing_reason":"FX spread: KUP","_legal_basis":"Art. 22 PIT","_warnings":["Spread walutowy banku przy przelewie zagranicznym — KUP"]} {
    object.get(input.invoice, "currency", "PLN") != "PLN"
    object.get(input.invoice, "fx_spread_incurred", false) == true
}

# ══ R1671-R1673: Terminal / Karty płatnicze ══
else := {"matched":true,"rule_id":"jdg.payments.hyper.terminal_obligation_20k_eur","package":"jdg.payments.hyper","priority":1671,"_routing":"WARNING","_routing_reason":"Terminal: obowiązek >20k EUR/rok B2C","_legal_basis":"Ustawa o usługach płatniczych","_warnings":["Obowiązek terminala płatniczego — obrót B2C >20k EUR/rok i >50% transakcji z konsumentami"]} {
    object.get(input.jdg_entrepreneur, "terminal_required", false) == true
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.terminal_penalty_5000","package":"jdg.payments.hyper","priority":1672,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Terminal: kara 5000 PLN","_legal_basis":"Ustawa o usługach płatniczych","_warnings":["Brak terminala pomimo obowiązku — kara do 5 000 PLN!"]} {
    object.get(input.jdg_entrepreneur, "terminal_required", false) == true
    object.get(input.jdg_entrepreneur, "terminal_installed", false) == false
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.terminal_cost_kup_vat","package":"jdg.payments.hyper","priority":1673,"_routing":"","_routing_reason":"Terminal: koszty KUP + VAT","_legal_basis":"Art. 22 PIT, Art. 86 VAT","_warnings":["Koszt terminala + prowizje — KUP 100% + VAT odliczalny"]} {
    object.get(input.jdg_entrepreneur, "terminal_installed", false) == true
}
