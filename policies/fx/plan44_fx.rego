# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.fx (Doc 44: P1890-P1898)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 9
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.fx
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.fx.no_match","package":"jdg.fx","priority":99999}

# jdg.fx.vat_rate_determination — Kurs waluty dla celów VAT
decide :=   {"matched":true,"rule_id":"jdg.fx.vat_rate_determination","package":"jdg.fx","priority":1890,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kurs waluty dla celów VAT","_legal_basis":"Art. 30a-31a VAT","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.fx.pit_rate_determination — P1891: Kurs PIT (nie VAT)
else :=   {"matched":true,"rule_id":"jdg.fx.pit_rate_determination","package":"jdg.fx","priority":1891,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kurs waluty dla celów PIT","_legal_basis":"Art. 14 ust. 1aa PIT","_warnings":[]} {
    input.invoice.currency != "PLN"
    object.get(input.invoice, "pit_fx_calculated", false) == false
}

# jdg.fx.differences_method — P1892: Metoda różnic kursowych (bez realizowanych)
else :=   {"matched":true,"rule_id":"jdg.fx.differences_method","package":"jdg.fx","priority":1892,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Metoda rozliczania różnic kursowych (podatkowa vs rachunkowa)","_legal_basis":"Art. 14b PIT","_warnings":[]} {
    input.invoice.currency != "PLN"
    object.get(input.invoice, "fx_method_selected", false) == false
}

# jdg.fx.realized_vs_unrealized — P1893: Rozróżnienie zrealizowanych/niezrealizowanych różnic kursowych
else :=   {"matched":true,"rule_id":"jdg.fx.realized_vs_unrealized","package":"jdg.fx","priority":1893,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zrealizowane vs niezrealizowane różnice kursowe — tylko zrealizowane wpływają na PIT","_legal_basis":"Art. 14b PIT","_warnings":["Tylko zrealizowane różnice kursowe wpływają na PIT"]} {
    input.invoice.currency != "PLN"
    object.get(input.invoice, "fx_realized_checked", false) == false
}

# jdg.fx.differences_method_selection — P1894: Wybór metody: podatkowa (FIFO) vs rachunkowa (średnia ważona)
else :=   {"matched":true,"rule_id":"jdg.fx.differences_method_selection","package":"jdg.fx","priority":1894,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Oświadczenie raz na rok — metoda podatkowa (FIFO) vs rachunkowa","_legal_basis":"Art. 14b ust. 3 PIT","_warnings":["Wybierz metodę różnic kursowych — oświadczenie raz na rok. FIFO lub średnia ważona"]} {
    input.invoice.currency != "PLN"
    object.get(input.invoice, "differences_method_selection_needed", false) == true
}

# jdg.fx.own_funds — P1895: Brak różnic kursowych od własnych środków na rachunku walutowym
else :=   {"matched":true,"rule_id":"jdg.fx.own_funds","package":"jdg.fx","priority":1895,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak różnic kursowych od środków własnych na rachunku walutowym w PIT","_legal_basis":"Art. 14b ust. 1 PIT","_warnings":["Różnice kursowe od własnych środków — NIE są przychodem/KUP w PIT (inaczej niż CIT)"]} {
    input.invoice.currency != "PLN"
    object.get(input.invoice, "own_funds_fx", false) == true
}

# jdg.fx.crypto_fx_differences — P1896: Różnice kursowe na kryptowalutach — kurs rynkowy, nie NBP
else :=   {"matched":true,"rule_id":"jdg.fx.crypto_fx_differences","package":"jdg.fx","priority":1896,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Krypto — przeliczenie po kursie rynkowym, nie NBP","_legal_basis":"Art. 14b PIT","_warnings":["Kryptowaluty — przeliczaj po kursie rynkowym z giełdy, nie NBP"]} {
    input.invoice.currency != "PLN"
    object.get(input.invoice, "crypto_fx", false) == true
}

# jdg.fx.hedging_instruments — P1897: Instrumenty zabezpieczające ryzyko walutowe (forward, opcje)
else :=   {"matched":true,"rule_id":"jdg.fx.hedging_instruments","package":"jdg.fx","priority":1897,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Forward, opcje walutowe — przychody/koszty z pochodnych","_legal_basis":"Art. 14 PIT","_warnings":["Instrumenty pochodne FX — przychody/koszty rozliczane na zasadach ogólnych"]} {
    input.invoice.currency != "PLN"
    object.get(input.invoice, "hedging_instruments_used", false) == true
}

# jdg.fx.multi_currency_accounting — P1898: Prowadzenie PKPiR w walucie obcej — przeliczenie miesięczne
else :=   {"matched":true,"rule_id":"jdg.fx.multi_currency_accounting","package":"jdg.fx","priority":1898,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"PKPiR w walucie obcej — przeliczenie na PLN na koniec każdego miesiąca","_legal_basis":"Art. 24a PIT","_warnings":["PKPiR w walucie obcej — przeliczaj na PLN na koniec każdego miesiąca"]} {
    input.invoice.currency != "PLN"
    object.get(input.invoice, "multi_currency_accounting_active", false) == true
}
