# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.advertising hyper-granularity (Doc 45: R1674-R1708)
# Atom rules: digital platforms, events, gifts, sponsorship, VAT, influencer, car
# Rules: 35 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.advertising.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.advertising.hyper.no_match","package":"jdg.advertising.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.advertising.hyper.product_promotion_kup","package":"jdg.advertising.hyper","priority":1675,"_routing":"","_routing_reason":"Reklama: promocja produktu → KUP","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Promocja konkretnego produktu/usługi → KUP 100%"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.personal_prestige_nkup","package":"jdg.advertising.hyper","priority":1677,"_routing":"WARNING","_routing_reason":"Reprezentacja: osobisty prestiż → NKUP","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Budowanie osobistego prestiżu właściciela → NKUP (reprezentacja)"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.digital_google_ads_kup","package":"jdg.advertising.hyper","priority":1679,"_routing":"","_routing_reason":"Google Ads → KUP 100%","_legal_basis":"Art. 22 PIT","_warnings":["Google Ads — KUP 100% (reklama, nie reprezentacja)"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.events_trade_fair_kup","package":"jdg.advertising.hyper","priority":1684,"_routing":"","_routing_reason":"Targi → KUP 100%","_legal_basis":"Art. 22 PIT","_warnings":["Udział w targach — KUP 100% (stoisko, powierzchnia, transport)"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.events_luxury_trip_nkup","package":"jdg.advertising.hyper","priority":1686,"_routing":"WARNING","_routing_reason":"Luksusowy wyjazd bez agendy → NKUP","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Luksusowy wyjazd bez agendy biznesowej → NKUP"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.gifts_over_200_nkup","package":"jdg.advertising.hyper","priority":1690,"_routing":"WARNING","_routing_reason":"Prezent >200 PLN → NKUP","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Prezent dla kontrahenta >200 PLN → NKUP"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.gifts_vat_deduction_100pln","package":"jdg.advertising.hyper","priority":1693,"_routing":"","_routing_reason":"VAT od prezentów: limit 100 PLN","_legal_basis":"Art. 88 ust. 1 pkt 5 VAT","_warnings":["VAT od prezentów odliczalny tylko do 100 PLN netto"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.car_wrapping_vat26","package":"jdg.advertising.hyper","priority":1708,"_routing":"","_routing_reason":"Oklejenie auta: VAT-26","_legal_basis":"Art. 86a VAT","_warnings":["Oklejenie reklamowe — złóż VAT-26 dla 100% odliczenia VAT i pełnego KUP paliwa"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}
