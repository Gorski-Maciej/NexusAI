# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.advertising (Doc 44: P1999-P2007)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 9 (deduplicated)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.advertising
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.advertising.no_match","package":"jdg.advertising","priority":99999}

# jdg.advertising.vs_representation — P1999: Rozróżnienie reklama (KUP) vs reprezentacja (NKUP) — GENERAL
decide :=   {"matched":true,"rule_id":"jdg.advertising.vs_representation","package":"jdg.advertising","priority":1999,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Rozróżnienie reklama (KUP) vs reprezentacja (NKUP)","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Wydatek może być reprezentacją (NKUP), nie reklamą — zweryfikuj"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
    object.get(input.invoice, "ad_channel", "") == "GENERAL"
}

# jdg.advertising.online_digital_kup — P2000: Reklama cyfrowa (Google Ads, FB Ads, SEO) — KUP 100%
else :=   {"matched":true,"rule_id":"jdg.advertising.online_digital_kup","package":"jdg.advertising","priority":2000,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Reklama cyfrowa — KUP 100% (nie jest reprezentacją)","_legal_basis":"Art. 22 PIT","_warnings":["Reklama online (Google Ads, FB Ads, SEO) — KUP w 100%"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
    object.get(input.invoice, "ad_channel", "") == "ONLINE"
}

# jdg.advertising.events_hospitality — P2001: Eventy/kolacje — test: promocja produktu = KUP
else :=   {"matched":true,"rule_id":"jdg.advertising.events_hospitality","package":"jdg.advertising","priority":2001,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Eventy/kolacje — test: czy główny cel to promocja produktu?","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Event/kolacja — KUP tylko jeśli głównym celem jest promocja produktu"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
    object.get(input.invoice, "ad_channel", "") == "EVENTS"
}

# jdg.advertising.gifts_limit_200 — P2002: Prezenty dla kontrahentów — limit 200 PLN, tylko z logo
else :=   {"matched":true,"rule_id":"jdg.advertising.gifts_limit_200","package":"jdg.advertising","priority":2002,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Prezenty dla kontrahentów — limit 200 PLN, tylko z logo","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Prezent >200 PLN lub bez logo — NKUP jako reprezentacja"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
    object.get(input.invoice, "ad_channel", "") == "GIFTS"
}

# jdg.advertising.sponsorship_kup — P2003: Sponsoring — KUP z kontrświadczeniem, darowizna bez
else :=   {"matched":true,"rule_id":"jdg.advertising.sponsorship_kup","package":"jdg.advertising","priority":2003,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Sponsoring — KUP z kontrświadczeniem, darowizna bez","_legal_basis":"Art. 22 PIT, Art. 26 PIT","_warnings":["Sponsoring bez kontrświadczeń traktowany jak darowizna — limit 6%"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
    object.get(input.invoice, "ad_channel", "") == "SPONSORSHIP"
}

# jdg.advertising.vat_deduction — P2004: VAT od wydatków reklamowych — 100% odliczenia
else :=   {"matched":true,"rule_id":"jdg.advertising.vat_deduction","package":"jdg.advertising","priority":2004,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"VAT od reklamy — odliczenie 100%, limit dla prezentów 100 PLN netto","_legal_basis":"Art. 86a VAT","_warnings":["VAT od reklamy odliczalny w 100%. Prezenty do 100 PLN netto — VAT odliczalny"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
    object.get(input.invoice, "ad_vat_deduction_checked", false) == false
}

# jdg.advertising.social_media_influencer — P2005: Influencer marketing — ryzyko NKUP
else :=   {"matched":true,"rule_id":"jdg.advertising.social_media_influencer","package":"jdg.advertising","priority":2005,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Influencer marketing — KUP jeśli faktura opisuje świadczenie promocyjne","_legal_basis":"Art. 22 PIT","_warnings":["Influencer marketing — ryzyko uznania za reprezentację. Opisz świadczenie na fakturze"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
    object.get(input.invoice, "ad_channel", "") == "INFLUENCER"
}

# jdg.advertising.car_wrapping_vat26 — P2006: Oklejenie auta reklamą — VAT-26 → 100% odliczenia
else :=   {"matched":true,"rule_id":"jdg.advertising.car_wrapping_vat26","package":"jdg.advertising","priority":2006,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Oklejenie auta reklamą — VAT-26 → 100% odliczenia","_legal_basis":"Art. 86a VAT","_warnings":["Oklejenie reklamowe — złóż VAT-26 dla 100% odliczenia VAT"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
    object.get(input.invoice, "ad_channel", "") == "CAR_WRAPPING"
}

# jdg.advertising.foreign_markets_kup — P2007: Reklama na rynkach zagranicznych — ulga na ekspansję
else :=   {"matched":true,"rule_id":"jdg.advertising.foreign_markets_kup","package":"jdg.advertising","priority":2007,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Reklama zagraniczna — dodatkowo ulga na ekspansję do 1M PLN","_legal_basis":"Art. 26ec PIT","_warnings":["Reklama na rynkach zagranicznych — ulga na ekspansję do 1M PLN odliczenia"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
    object.get(input.invoice, "ad_channel", "") == "FOREIGN"
}
