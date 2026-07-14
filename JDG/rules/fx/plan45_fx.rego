# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.fx hyper (Doc 45: R1300-R1339)
# Atom rules: VAT/PIT rates, NBP tables, methods, realized, hedging, multi-currency
# Rules: 40 atom — each with differentiated trigger conditions
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.fx.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.fx.hyper.no_match","package":"jdg.fx.hyper","priority":99999}

# ══ R1300-R1305: VAT FX Rules ══
decide := {"matched":true,"rule_id":"jdg.fx.hyper.vat_import_customs_rate","package":"jdg.fx.hyper","priority":1300,"_routing":"","_routing_reason":"VAT import: kurs celny","_legal_basis":"Art. 30a VAT","_warnings":["Import towarów spoza UE — stosuj kurs celny dla VAT"]} {
    object.get(input.invoice, "procedure", "") == "IMPORT"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.vat_wnt_ecb_rate","package":"jdg.fx.hyper","priority":1301,"_routing":"","_routing_reason":"VAT WNT: kurs EBC","_legal_basis":"Art. 30a VAT","_warnings":["WNT — stosuj kurs EBC z ostatniego dnia roboczego poprzedzającego WNT"]} {
    object.get(input.invoice, "procedure", "") == "WNT"
    object.get(input.invoice, "currency", "PLN") == "EUR"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.vat_import_services_nbp","package":"jdg.fx.hyper","priority":1302,"_routing":"","_routing_reason":"VAT import usług: kurs NBP","_legal_basis":"Art. 30a VAT","_warnings":["Import usług — kurs NBP z ostatniego dnia roboczego przed powstaniem obowiązku"]} {
    object.get(input.invoice, "procedure", "") == "IMPORT_SERVICES"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.vat_fx_invoice_nbp","package":"jdg.fx.hyper","priority":1303,"_routing":"","_routing_reason":"Faktura walutowa: kurs NBP","_legal_basis":"Art. 31a VAT","_warnings":["Faktura w walucie obcej — kurs NBP z dnia poprzedzającego powstanie obowiązku"]} {
    object.get(input.invoice, "currency", "PLN") != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.vat_correction_original_rate","package":"jdg.fx.hyper","priority":1304,"_routing":"","_routing_reason":"Korekta walutowa: kurs pierwotny","_legal_basis":"Art. 31a VAT","_warnings":["Korekta faktury walutowej — stosuj kurs z dnia pierwotnej faktury"]} {
    object.get(input.invoice, "correction", false) == true
    object.get(input.invoice, "currency", "PLN") != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.vat_ecb_vs_nbp_choice","package":"jdg.fx.hyper","priority":1305,"_routing":"","_routing_reason":"EBC vs NBP — wybór","_legal_basis":"Art. 30a/31a VAT","_warnings":["EUR: możesz wybrać kurs EBC zamiast NBP (dla WNT obowiązkowy EBC)"]} {
    object.get(input.invoice, "currency", "PLN") == "EUR"
}

# ══ R1306-R1311: PIT FX Rules ══
else := {"matched":true,"rule_id":"jdg.fx.hyper.pit_revenue_nbp_day_before","package":"jdg.fx.hyper","priority":1306,"_routing":"","_routing_reason":"PIT przychód: NBP dzień przed","_legal_basis":"Art. 14 ust. 1aa PIT","_warnings":["Przychód w walucie obcej — kurs NBP z ostatniego dnia roboczego przed uzyskaniem"]} {
    object.get(input.invoice, "currency", "PLN") != "PLN"
    object.get(input.invoice, "direction", "") == "SALE"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.pit_kup_nbp_day_before","package":"jdg.fx.hyper","priority":1307,"_routing":"","_routing_reason":"KUP walutowy: NBP dzień przed","_legal_basis":"Art. 22 ust. 1e PIT","_warnings":["Koszt w walucie obcej — kurs NBP z dnia poprzedzającego poniesienie"]} {
    object.get(input.invoice, "currency", "PLN") != "PLN"
    object.get(input.invoice, "direction", "") == "PURCHASE"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.pit_differences_tax_method","package":"jdg.fx.hyper","priority":1308,"_routing":"","_routing_reason":"Różnice kursowe: metoda podatkowa","_legal_basis":"Art. 14b PIT","_warnings":["Różnice kursowe — metoda podatkowa (FIFO) jako domyślna"]} {
    object.get(input.jdg_entrepreneur, "fx_method", "") == "TAX"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.pit_fifo_method_detail","package":"jdg.fx.hyper","priority":1309,"_routing":"","_routing_reason":"FIFO — szczegóły","_legal_basis":"Art. 14b PIT","_warnings":["Metoda FIFO: pierwsza wpłata = pierwsza wypłata. Różnica kursów = przychód/koszt"]} {
    object.get(input.jdg_entrepreneur, "fx_method", "") == "TAX"
    object.get(input.jdg_entrepreneur, "fx_transaction_occurred", false) == true
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.pit_weighted_avg_method","package":"jdg.fx.hyper","priority":1310,"_routing":"","_routing_reason":"Średnia ważona — rachunkowa","_legal_basis":"Art. 14b PIT","_warnings":["Metoda średniej ważonej — wymaga oświadczenia. Nie można zmieniać w roku"]} {
    object.get(input.jdg_entrepreneur, "fx_method", "") == "WEIGHTED_AVG"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.pit_crypto_fx_exchange_rate","package":"jdg.fx.hyper","priority":1311,"_routing":"","_routing_reason":"Krypto: kurs giełdowy, nie NBP","_legal_basis":"Art. 14b PIT","_warnings":["Kryptowaluty — stosuj kurs rynkowy z giełdy, nie tabele NBP"]} {
    object.get(input.invoice, "payment_method", "") == "CRYPTO"
}

# ══ R1312-R1317: NBP Tables ══
else := {"matched":true,"rule_id":"jdg.fx.hyper.nbp_table_a_avg","package":"jdg.fx.hyper","priority":1312,"_routing":"","_routing_reason":"Tabela A: kursy średnie","_legal_basis":"PIT, VAT","_warnings":["Tabela A NBP — kursy średnie, domyślna dla PIT i VAT"]} {
    object.get(input.invoice, "nbp_table_used", "") == "A"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.nbp_table_b_last","package":"jdg.fx.hyper","priority":1313,"_routing":"","_routing_reason":"Tabela B: kursy ostatnie","_legal_basis":"PIT","_warnings":["Tabela B NBP — kursy ostatnie dla walut niewystępujących w tabeli A"]} {
    object.get(input.invoice, "nbp_table_used", "") == "B"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.nbp_table_c_bid_ask","package":"jdg.fx.hyper","priority":1314,"_routing":"","_routing_reason":"Tabela C: kupna/sprzedaży","_legal_basis":"PIT","_warnings":["Tabela C NBP — kursy kupna/sprzedaży, dla transakcji bankowych"]} {
    object.get(input.invoice, "nbp_table_used", "") == "C"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.nbp_table_a_default_selection","package":"jdg.fx.hyper","priority":1315,"_routing":"","_routing_reason":"Domyślnie tabela A","_legal_basis":"PIT, VAT","_warnings":["Domyślnie stosuj tabelę A. Tabela B tylko dla walut rzadkich"]} {
    object.get(input.invoice, "currency", "PLN") != "PLN"
    object.get(input.invoice, "nbp_table_used", "") == ""
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.nbp_table_validation","package":"jdg.fx.hyper","priority":1316,"_routing":"","_routing_reason":"Walidacja tabeli NBP","_legal_basis":"PIT","_warnings":["Sprawdź czy kurs pochodzi z właściwej tabeli dla danego typu transakcji"]} {
    object.get(input.invoice, "nbp_table_validated", false) == false
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.nbp_table_alert_missing","package":"jdg.fx.hyper","priority":1317,"_routing":"WARNING","_routing_reason":"Brak kursu NBP dla waluty","_legal_basis":"PIT","_warnings":["Brak kursu NBP dla tej waluty w tabeli A — sprawdź tabelę B"]} {
    object.get(input.invoice, "nbp_rate_missing", false) == true
}

# ══ R1318-R1323: FX Methods ══
else := {"matched":true,"rule_id":"jdg.fx.hyper.method_tax_fifo_default","package":"jdg.fx.hyper","priority":1318,"_routing":"","_routing_reason":"Metoda podatkowa: FIFO","_legal_basis":"Art. 14b PIT","_warnings":["Metoda podatkowa — FIFO. Oświadczenie raz na rok"]} {
    object.get(input.jdg_entrepreneur, "fx_method_selected", false) == true
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.method_accounting_weighted_avg","package":"jdg.fx.hyper","priority":1319,"_routing":"","_routing_reason":"Metoda rachunkowa: średnia ważona","_legal_basis":"Art. 14b PIT","_warnings":["Metoda rachunkowa — średnia ważona. Wybór na cały rok"]} {
    object.get(input.jdg_entrepreneur, "fx_method", "") == "WEIGHTED_AVG"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.method_selection_annual","package":"jdg.fx.hyper","priority":1320,"_routing":"WARNING","_routing_reason":"Wybór metody — na cały rok","_legal_basis":"Art. 14b ust. 3 PIT","_warnings":["Wybierz metodę różnic kursowych przed rozpoczęciem roku. Nie zmieniaj w trakcie!"]} {
    object.get(input.jdg_entrepreneur, "fx_method_selection_pending", false) == true
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.method_change_next_year","package":"jdg.fx.hyper","priority":1321,"_routing":"","_routing_reason":"Zmiana metody od nowego roku","_legal_basis":"Art. 14b PIT","_warnings":["Zmiana metody różnic kursowych — tylko od początku nowego roku podatkowego"]} {
    object.get(input.jdg_entrepreneur, "fx_method_change_requested", false) == true
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.method_declaration_document","package":"jdg.fx.hyper","priority":1322,"_routing":"","_routing_reason":"Oświadczenie o metodzie","_legal_basis":"Art. 14b PIT","_warnings":["Złóż oświadczenie o wyborze metody i dołącz do dokumentacji podatkowej"]} {
    object.get(input.jdg_entrepreneur, "fx_method_declaration_done", false) == false
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.method_consequences_tax","package":"jdg.fx.hyper","priority":1323,"_routing":"","_routing_reason":"Skutki zmiany metody","_legal_basis":"Art. 14b PIT","_warnings":["Zmiana metody może wpłynąć na wysokość dochodu — skonsultuj z księgowym"]} {
    object.get(input.jdg_entrepreneur, "fx_method_change_impact_assessed", false) == false
}

# ══ R1324-R1329: Realized FX Differences ══
else := {"matched":true,"rule_id":"jdg.fx.hyper.realized_moment_payment","package":"jdg.fx.hyper","priority":1324,"_routing":"","_routing_reason":"Moment realizacji: zapłata","_legal_basis":"Art. 14b PIT","_warnings":["Tylko zrealizowane różnice kursowe wpływają na PIT — moment zapłaty"]} {
    object.get(input.invoice, "payment_completed", false) == true
    object.get(input.invoice, "currency", "PLN") != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.realized_valuation_cost_vs_payment","package":"jdg.fx.hyper","priority":1325,"_routing":"","_routing_reason":"Wycena: koszt nabycia vs zapłata","_legal_basis":"Art. 14b PIT","_warnings":["Różnica dodatnia = przychód (kurs zapłaty > kurs zarachowania). Ujemna = koszt"]} {
    object.get(input.jdg_entrepreneur, "fx_difference_calculated", false) == false
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.realized_documentation","package":"jdg.fx.hyper","priority":1326,"_routing":"","_routing_reason":"Dokumentacja różnic","_legal_basis":"Art. 14b PIT","_warnings":["Dokumentuj każdą zrealizowaną różnicę kursową: data, kurs, kwota"]} {
    object.get(input.invoice, "fx_difference_documented", false) == false
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.realized_loss_tax_deductible","package":"jdg.fx.hyper","priority":1327,"_routing":"","_routing_reason":"Ujemna różnica: KUP","_legal_basis":"Art. 14b PIT","_warnings":["Ujemna różnica kursowa = koszt uzyskania przychodu"]} {
    object.get(input.invoice, "fx_difference", 0) < 0
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.realized_gain_taxable","package":"jdg.fx.hyper","priority":1328,"_routing":"","_routing_reason":"Dodatnia różnica: przychód","_legal_basis":"Art. 14b PIT","_warnings":["Dodatnia różnica kursowa = przychód podatkowy"]} {
    object.get(input.invoice, "fx_difference", 0) > 0
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.realized_annual_aggregation","package":"jdg.fx.hyper","priority":1329,"_routing":"","_routing_reason":"Agregacja roczna różnic","_legal_basis":"Art. 14b PIT","_warnings":["Sumuj różnice kursowe na koniec roku — netto = przychód lub koszt"]} {
    object.get(input.jdg_entrepreneur, "year_end_fx_reconciliation", false) == true
}

# ══ R1330-R1334: Hedging ══
else := {"matched":true,"rule_id":"jdg.fx.hyper.hedging_forward_tax","package":"jdg.fx.hyper","priority":1330,"_routing":"WARNING","_routing_reason":"Forward walutowy: zasady ogólne","_legal_basis":"Art. 14 PIT","_warnings":["Forward — rozliczenie na zasadach ogólnych. Moment realizacji = data rozliczenia"]} {
    object.get(input.jdg_entrepreneur, "has_fx_forward", false) == true
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.hedging_options_tax","package":"jdg.fx.hyper","priority":1331,"_routing":"WARNING","_routing_reason":"Opcje walutowe: zasady ogólne","_legal_basis":"Art. 14 PIT","_warnings":["Opcje walutowe — przychód/koszt w momencie realizacji opcji"]} {
    object.get(input.jdg_entrepreneur, "has_fx_options", false) == true
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.hedging_swap_tax","package":"jdg.fx.hyper","priority":1332,"_routing":"","_routing_reason":"Swap walutowy","_legal_basis":"Art. 14 PIT","_warnings":["Swap walutowy — rozliczenie na zasadach ogólnych"]} {
    object.get(input.jdg_entrepreneur, "has_fx_swap", false) == true
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.hedging_documentation","package":"jdg.fx.hyper","priority":1333,"_routing":"","_routing_reason":"Dokumentacja hedgingu","_legal_basis":"Art. 14 PIT","_warnings":["Dokumentuj cel hedgingowy — uzasadnienie biznesowe dla ochrony przed ryzykiem"]} {
    object.get(input.jdg_entrepreneur, "hedging_documentation_needed", false) == true
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.hedging_kup_treatment","package":"jdg.fx.hyper","priority":1334,"_routing":"","_routing_reason":"Koszty hedge: KUP","_legal_basis":"Art. 22 PIT","_warnings":["Koszty instrumentów zabezpieczających — KUP w dacie poniesienia"]} {
    object.get(input.invoice, "expense_type", "") == "HEDGING_COST"
}

# ══ R1335-R1339: Multi-Currency Accounting ══
else := {"matched":true,"rule_id":"jdg.fx.hyper.multi_pkpir_foreign_currency","package":"jdg.fx.hyper","priority":1335,"_routing":"","_routing_reason":"PKPiR w walucie obcej","_legal_basis":"Art. 24a PIT","_warnings":["PKPiR może być prowadzona w walucie obcej — przeliczaj na PLN na koniec miesiąca"]} {
    object.get(input.jdg_entrepreneur, "pkpir_in_foreign_currency", false) == true
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.multi_monthly_conversion","package":"jdg.fx.hyper","priority":1336,"_routing":"","_routing_reason":"Przeliczenie miesięczne na PLN","_legal_basis":"Art. 24a PIT","_warnings":["Przeliczaj PKPiR na PLN na koniec każdego miesiąca wg kursu NBP"]} {
    object.get(input.jdg_entrepreneur, "monthly_fx_conversion_due", false) == true
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.multi_balance_monitoring","package":"jdg.fx.hyper","priority":1337,"_routing":"","_routing_reason":"Monitorowanie sald walutowych","_legal_basis":"Art. 24a PIT","_warnings":["Monitoruj salda walutowe — różnice kursowe od własnych środków"]} {
    object.get(input.jdg_entrepreneur, "has_fx_bank_account", false) == true
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.multi_reporting_requirements","package":"jdg.fx.hyper","priority":1338,"_routing":"","_routing_reason":"Raportowanie wielowalutowe","_legal_basis":"Art. 24a PIT","_warnings":["Raportuj wszystkie transakcje w PLN w deklaracjach podatkowych"]} {
    object.get(input.jdg_entrepreneur, "multi_currency_reporting_needed", false) == true
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.multi_audit_preparedness","package":"jdg.fx.hyper","priority":1339,"_routing":"","_routing_reason":"Audyt wielowalutowy","_legal_basis":"Art. 86 OP","_warnings":["Zachowaj dokumentację przeliczeń walutowych dla celów kontroli"]} {
    object.get(input.jdg_entrepreneur, "fx_audit_documentation_ready", false) == false
}
