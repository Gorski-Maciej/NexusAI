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

# ══ R1674-R1678: Split Payment (Mechanizm Podzielonej Płatności) — P0 L-PAY-3 ══
else := {"matched":true,"rule_id":"jdg.payments.hyper.split_voluntary_108a","package":"jdg.payments.hyper","priority":1674,"_routing":"","_routing_reason":"Split payment: dobrowolny (Art. 108a VAT)","_legal_basis":"Art. 108a VAT","_warnings":["Split payment dobrowolny — możesz użyć mechanizmu podzielonej płatności dla każdej faktury VAT"]} {
    object.get(input.invoice, "split_payment_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.split_mandatory_108b","package":"jdg.payments.hyper","priority":1675,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Split payment: obowiązkowy dla towarów wrażliwych (Art. 108b VAT, załącznik 15)","_legal_basis":"Art. 108b VAT","_warnings":["TOWARY WRAŻLIWE — OBOWIĄZKOWY SPLIT PAYMENT! Faktura >15 000 PLN brutto za towary z załącznika 15 (paliwa, stal, elektronika, części samochodowe, złom, metale szlachetne) WYMAGA mechanizmu podzielonej płatności. Przelew standardowy = ryzyko sankcji."]} {
    object.get(input.invoice, "amount_gross", 0) >= 15000
    object.get(input.invoice, "sensitive_goods_annex15", false) == true
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.split_sanctions_108h","package":"jdg.payments.hyper","priority":1676,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Split payment: sankcje za brak MPP (Art. 108h VAT)","_legal_basis":"Art. 108h VAT","_warnings":["Brak mechanizmu podzielonej płatności przy obowiązku = sankcja: dodatkowe zobowiązanie 30% kwoty VAT! + Naczelnik US może wyłączyć z KUP kwotę netto (Art. 22p PIT)."]} {
    object.get(input.invoice, "sensitive_goods_annex15", false) == true
    object.get(input.invoice, "split_payment_used", false) == false
    object.get(input.invoice, "amount_gross", 0) >= 15000
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.split_vat_account_62b","package":"jdg.payments.hyper","priority":1677,"_routing":"","_routing_reason":"Split payment: rachunek VAT (Art. 62b OrdUS)","_legal_basis":"Art. 62b OrdUS, Art. 108a ust. 3 VAT","_warnings":["Środki na rachunku VAT — ograniczone dysponowanie: tylko przelew do US, ZUS lub na rachunek VAT kontrahenta. Zwrot na ROR: wniosek do naczelnika US, termin 60 dni."]} {
    object.get(input.invoice, "split_payment_used", false) == true
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.split_communication_message","package":"jdg.payments.hyper","priority":1678,"_routing":"WARNING","_routing_reason":"Split payment: komunikat przelewu (numer faktury, NIP, kwota VAT)","_legal_basis":"Art. 108a ust. 3 VAT","_warnings":["W komunikacie przelewu SPLIT PAYMENT podaj: numer faktury, NIP dostawcy, kwotę brutto, kwotę VAT. Bez tych danych przelew może być odrzucony."]} {
    object.get(input.invoice, "split_payment_used", false) == true
    object.get(input.invoice, "split_communication_complete", false) == false
}

# ══ R1679-R1681: White List US Notification (L-PAY-2) ══
else := {"matched":true,"rule_id":"jdg.payments.hyper.whitelist_us_notify_3days","package":"jdg.payments.hyper","priority":1679,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Biała Lista: zgłoś US w 3 dni robocze — rachunek spoza listy","_legal_basis":"Art. 96b ust. 1 pkt 2 VAT, Art. 117ba OrdPU","_warnings":["PRZELEW NA RACHUNEK SPOZA BIAŁEJ LISTY! Masz 3 dni robocze na zgłoszenie do naczelnika US. Niezgłoszenie = odpowiedzialność solidarna za VAT kontrahenta (Art. 117ba OrdPU) + wyłączenie z KUP (Art. 22p PIT)!"]} {
    object.get(input.invoice, "amount_gross", 0) >= 15000
    object.get(input.vendor, "country", "PL") == "PL"
    object.get(input.invoice, "whitelist_checked", false) == true
    object.get(input.invoice, "whitelist_account_ok", false) == false
    object.get(input.invoice, "whitelist_us_notified_3days", false) == false
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.whitelist_penalty_nkup","package":"jdg.payments.hyper","priority":1680,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Biała Lista: skutki braku zgłoszenia — NKUP + odp. solidarna","_legal_basis":"Art. 22p PIT, Art. 117ba OrdPU","_warnings":["Nie zgłosiłeś rachunku spoza białej listy w 3 dni → KUP WYŁĄCZONE (Art. 22p PIT) + odpowiedzialność solidarna za VAT kontrahenta (Art. 117ba OrdPU)!"]} {
    object.get(input.invoice, "whitelist_account_ok", false) == false
    object.get(input.invoice, "whitelist_us_notified_3days", false) == false
    object.get(input.invoice, "whitelist_deadline_passed", false) == true
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.whitelist_auto_verify_pre_transfer","package":"jdg.payments.hyper","priority":1681,"_routing":"WARNING","_routing_reason":"Biała Lista: weryfikuj przed każdym przelewem >15k PLN","_legal_basis":"Art. 96b ust. 1 VAT","_warnings":["Przed przelewem >15 000 PLN do kontrahenta PL — ZAWSZE weryfikuj rachunek na białej liście VAT (API MF). Rachunek spoza listy = obowiązek zgłoszenia w 3 dni."]} {
    object.get(input.invoice, "amount_gross", 0) >= 15000
    object.get(input.vendor, "country", "PL") == "PL"
}

# ══ R1682-R1685: Commercial Delay Interest (L-PAY-1) ══
else := {"matched":true,"rule_id":"jdg.payments.hyper.commercial_delay_14days","package":"jdg.payments.hyper","priority":1682,"_routing":"WARNING","_routing_reason":"Opóźnienie handlowe: 14 dni — mikroprzedsiębiorcy","_legal_basis":"Ustawa o przeciwdziałaniu nadmiernym opóźnieniom w transakcjach handlowych, Art. 481 KC","_warnings":["Termin zapłaty 14 dni (transakcje między mikroprzedsiębiorcami). Po terminie — odsetki ustawowe: stopa referencyjna NBP + 8 p.p. (11.25% w 2025). Naliczaj odsetki od dnia następnego po terminie."]} {
    object.get(input.invoice, "payment_overdue", false) == true
    object.get(input.invoice, "payment_term_days", 0) <= 14
    object.get(input.invoice, "contractor_type", "") == "MICRO"
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.commercial_delay_30days","package":"jdg.payments.hyper","priority":1683,"_routing":"WARNING","_routing_reason":"Opóźnienie handlowe: 30 dni — standard","_legal_basis":"Ustawa o przeciwdziałaniu nadmiernym opóźnieniom w transakcjach handlowych","_warnings":["Termin zapłaty 30 dni. Opóźnienie >30 dni — naliczaj odsetki ustawowe (11.25% w 2025). Dodatkowo: możesz żądać rekompensaty 40 EUR + 100 EUR (powyżej 60 dni) za koszty odzyskiwania."]} {
    object.get(input.invoice, "payment_overdue", false) == true
    object.get(input.invoice, "days_overdue", 0) > 30
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.commercial_delay_60days","package":"jdg.payments.hyper","priority":1684,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Opóźnienie handlowe: 60 dni — rekompensata + windykacja","_legal_basis":"Ustawa o przeciwdziałaniu nadmiernym opóźnieniom, Art. 481 KC","_warnings":["Opóźnienie >60 dni — natychmiastowa windykacja! Należne: odsetki (11.25%/rok), rekompensata 40 EUR + dodatkowe 100 EUR. Rozważ pozew do e-sądu."]} {
    object.get(input.invoice, "payment_overdue", false) == true
    object.get(input.invoice, "days_overdue", 0) > 60
}
else := {"matched":true,"rule_id":"jdg.payments.hyper.commercial_interest_calculator","package":"jdg.payments.hyper","priority":1685,"_routing":"","_routing_reason":"Odsetki handlowe: kalkulacja (stopa ref. NBP + 8 p.p.)","_legal_basis":"Art. 481 KC, ustawa o przeciwdziałaniu nadmiernym opóźnieniom","_warnings":["Wzór: odsetki = kwota brutto × (stopa_ref_NBP + 8%) × (dni_opóźnienia/365). W 2025: stopa ref. NBP 5.75% → odsetki = 13.75% dla transakcji >60 dni. Dla 30-60 dni: odsetki podstawowe = 11.25%."]} {
    object.get(input.invoice, "payment_overdue", false) == true
    object.get(input.invoice, "interest_calculation_needed", false) == true
}
