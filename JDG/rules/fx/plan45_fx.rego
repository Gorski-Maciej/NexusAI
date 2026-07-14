# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.fx hyper (Doc 45: R1300-R1339)
# Atom rules: VAT/PIT rates, NBP tables, methods, realized, hedging, multi-currency
# Rules: 40 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.fx.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.fx.hyper.no_match","package":"jdg.fx.hyper","priority":99999}

# VAT FX (R1300-R1305)
decide := {"matched":true,"rule_id":"jdg.fx.hyper.vat_import_customs","package":"jdg.fx.hyper","priority":1300,"_routing":"","_routing_reason":"VAT import: kurs celny","_legal_basis":"Art. 30a VAT","_warnings":["Import — stosuj kurs celny dla VAT"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.vat_wnt","package":"jdg.fx.hyper","priority":1301,"_routing":"","_routing_reason":"VAT WNT: kurs EBC","_legal_basis":"Art. 30a VAT","_warnings":["WNT — kurs EBC z dnia poprzedzającego"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.vat_import_services","package":"jdg.fx.hyper","priority":1302,"_routing":"","_routing_reason":"VAT import usług","_legal_basis":"Art. 30a VAT","_warnings":["Import usług — kurs NBP z dnia poprzedzającego"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.vat_fx_invoice","package":"jdg.fx.hyper","priority":1303,"_routing":"","_routing_reason":"Faktura walutowa: kurs NBP","_legal_basis":"Art. 31a VAT","_warnings":["Faktura walutowa — kurs NBP z dnia poprzedzającego dostawę"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.vat_correction","package":"jdg.fx.hyper","priority":1304,"_routing":"","_routing_reason":"Korekta walutowa","_legal_basis":"Art. 31a VAT","_warnings":["Korekta — kurs z dnia pierwotnej faktury"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.vat_ecb_vs_nbp","package":"jdg.fx.hyper","priority":1305,"_routing":"","_routing_reason":"EBC vs NBP","_legal_basis":"Art. 30a/31a VAT","_warnings":["EBC dla WNT, NBP dla pozostałych"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.pit_revenue","package":"jdg.fx.hyper","priority":1306,"_routing":"","_routing_reason":"PIT przychód: NBP dzień poprzedni","_legal_basis":"Art. 14 ust. 1aa PIT","_warnings":["Przychód walutowy — NBP z ostatniego dnia przed transakcją"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.pit_kup","package":"jdg.fx.hyper","priority":1307,"_routing":"","_routing_reason":"KUP walutowy","_legal_basis":"Art. 22 PIT","_warnings":["Koszt walutowy — NBP z dnia poprzedzającego"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.pit_differences","package":"jdg.fx.hyper","priority":1308,"_routing":"","_routing_reason":"Różnice kursowe","_legal_basis":"Art. 14b PIT","_warnings":["Różnice kursowe — metoda podatkowa lub rachunkowa"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.pit_method_fifo","package":"jdg.fx.hyper","priority":1309,"_routing":"","_routing_reason":"FIFO — metoda podatkowa","_legal_basis":"Art. 14b PIT","_warnings":["Metoda FIFO dla różnic kursowych"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.pit_method_weighted_avg","package":"jdg.fx.hyper","priority":1310,"_routing":"","_routing_reason":"Średnia ważona — rachunkowa","_legal_basis":"Art. 14b PIT","_warnings":["Metoda średniej ważonej — oświadczenie"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.pit_crypto_fx","package":"jdg.fx.hyper","priority":1311,"_routing":"","_routing_reason":"Krypto FX","_legal_basis":"Art. 14b PIT","_warnings":["Krypto — kurs rynkowy z giełdy, nie NBP"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.nbp_table_a","package":"jdg.fx.hyper","priority":1312,"_routing":"","_routing_reason":"NBP tabela A: średnie","_legal_basis":"PIT","_warnings":["Tabela A NBP — kursy średnie dla PIT"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.nbp_table_b","package":"jdg.fx.hyper","priority":1313,"_routing":"","_routing_reason":"NBP tabela B: ostatnie","_legal_basis":"PIT","_warnings":["Tabela B — kursy ostatnie dla walut rzadkich"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.nbp_table_c","package":"jdg.fx.hyper","priority":1314,"_routing":"","_routing_reason":"NBP tabela C: kupna/sprzedaży","_legal_basis":"PIT","_warnings":["Tabela C — kursy kupna/sprzedaży dla banków"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.nbp_table_selection","package":"jdg.fx.hyper","priority":1315,"_routing":"","_routing_reason":"Wybór tabeli NBP","_legal_basis":"PIT","_warnings":["Domyślnie tabela A; B dla walut rzadkich"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.nbp_table_validation","package":"jdg.fx.hyper","priority":1316,"_routing":"","_routing_reason":"Walidacja tabeli","_legal_basis":"PIT","_warnings":["Sprawdź czy kurs pochodzi z właściwej tabeli NBP"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.nbp_table_alert","package":"jdg.fx.hyper","priority":1317,"_routing":"","_routing_reason":"Alert: brak kursu NBP","_legal_basis":"PIT","_warnings":["Brak kursu NBP dla tej waluty — sprawdź tabelę B"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.method_tax","package":"jdg.fx.hyper","priority":1318,"_routing":"","_routing_reason":"Metoda podatkowa","_legal_basis":"Art. 14b PIT","_warnings":["Metoda podatkowa — FIFO, oświadczenie raz na rok"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.method_accounting","package":"jdg.fx.hyper","priority":1319,"_routing":"","_routing_reason":"Metoda rachunkowa","_legal_basis":"Art. 14b PIT","_warnings":["Metoda rachunkowa — średnia ważona"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.method_selection","package":"jdg.fx.hyper","priority":1320,"_routing":"","_routing_reason":"Wybór metody","_legal_basis":"Art. 14b ust. 3 PIT","_warnings":["Wybierz metodę — nie można zmieniać w trakcie roku"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.method_change","package":"jdg.fx.hyper","priority":1321,"_routing":"","_routing_reason":"Zmiana metody","_legal_basis":"Art. 14b PIT","_warnings":["Zmiana metody tylko od nowego roku"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.method_declaration","package":"jdg.fx.hyper","priority":1322,"_routing":"","_routing_reason":"Oświadczenie o metodzie","_legal_basis":"Art. 14b PIT","_warnings":["Oświadczenie o wyborze metody — dołącz do akt"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.method_consequences","package":"jdg.fx.hyper","priority":1323,"_routing":"","_routing_reason":"Skutki zmiany","_legal_basis":"Art. 14b PIT","_warnings":["Skutki zmiany metody różnic kursowych"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.realized_moment","package":"jdg.fx.hyper","priority":1324,"_routing":"","_routing_reason":"Moment realizacji","_legal_basis":"Art. 14b PIT","_warnings":["Tylko zrealizowane różnice wpływają na PIT"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.realized_valuation","package":"jdg.fx.hyper","priority":1325,"_routing":"","_routing_reason":"Wycena","_legal_basis":"Art. 14b PIT","_warnings":["Wycena: koszt nabycia vs kurs zapłaty"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.realized_documentation","package":"jdg.fx.hyper","priority":1326,"_routing":"","_routing_reason":"Dokumentowanie","_legal_basis":"Art. 14b PIT","_warnings":["Dokumentuj każdą zrealizowaną różnicę"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.hedging_forward","package":"jdg.fx.hyper","priority":1330,"_routing":"WARNING","_routing_reason":"Forward — opodatkowanie","_legal_basis":"Art. 14 PIT","_warnings":["Forward — przychody/koszty na zasadach ogólnych"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.hedging_options","package":"jdg.fx.hyper","priority":1331,"_routing":"WARNING","_routing_reason":"Opcje — opodatkowanie","_legal_basis":"Art. 14 PIT","_warnings":["Opcje walutowe — rozliczane na zasadach ogólnych"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.hedging_swap","package":"jdg.fx.hyper","priority":1332,"_routing":"","_routing_reason":"Swap walutowy","_legal_basis":"Art. 14 PIT","_warnings":["Swap — przychody/koszty na zasadach ogólnych"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.multi_currency_pkpir","package":"jdg.fx.hyper","priority":1335,"_routing":"","_routing_reason":"PKPiR w walucie","_legal_basis":"Art. 24a PIT","_warnings":["PKPiR w walucie obcej — przeliczaj miesięcznie"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.multi_currency_conversion","package":"jdg.fx.hyper","priority":1336,"_routing":"","_routing_reason":"Przeliczenie miesięczne","_legal_basis":"Art. 24a PIT","_warnings":["Przeliczaj na PLN na koniec każdego miesiąca"]} {
    input.invoice.currency != "PLN"
}
else := {"matched":true,"rule_id":"jdg.fx.hyper.multi_currency_balance","package":"jdg.fx.hyper","priority":1337,"_routing":"","_routing_reason":"Salda walutowe","_legal_basis":"Art. 24a PIT","_warnings":["Monitoruj salda walutowe — różnice kursowe od środków"]} {
    input.invoice.currency != "PLN"
}
