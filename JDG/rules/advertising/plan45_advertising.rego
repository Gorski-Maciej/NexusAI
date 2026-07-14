# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.advertising hyper-granularity (Doc 45: R1674-R1708)
# Atom rules: advertising vs representation, digital platforms, events,
#   gifts, sponsorship, VAT, influencer, car wrapping
# Rules: 35 atom — each with differentiated trigger conditions
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.advertising.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.advertising.hyper.no_match","package":"jdg.advertising.hyper","priority":99999}

# ══ R1674-R1678: Advertising vs Representation Distinction ══
decide := {"matched":true,"rule_id":"jdg.advertising.hyper.ad_vs_repr_test","package":"jdg.advertising.hyper","priority":1674,"_routing":"","_routing_reason":"Test: reklama (KUP) vs reprezentacja (NKUP)","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Reklama = informacja o produkcie/usłudze → KUP. Reprezentacja = budowanie prestiżu → NKUP"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.product_promotion_kup","package":"jdg.advertising.hyper","priority":1675,"_routing":"","_routing_reason":"Promocja produktu → KUP 100%","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Promocja konkretnego produktu/usługi → KUP 100%"]} {
    object.get(input.invoice, "expense_subtype", "") == "PRODUCT_PROMOTION"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.brand_building_kup","package":"jdg.advertising.hyper","priority":1676,"_routing":"","_routing_reason":"Budowanie marki firmy → KUP","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Budowanie marki firmy (nie osobistej) → KUP 100%"]} {
    object.get(input.invoice, "expense_subtype", "") == "BRAND_BUILDING"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.personal_prestige_nkup","package":"jdg.advertising.hyper","priority":1677,"_routing":"WARNING","_routing_reason":"Osobisty prestiż właściciela → NKUP","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Budowanie osobistego prestiżu właściciela bez związku z produktem → NKUP (reprezentacja)"]} {
    object.get(input.invoice, "expense_subtype", "") == "PERSONAL_PRESTIGE"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.representation_capped_0025pct","package":"jdg.advertising.hyper","priority":1678,"_routing":"WARNING","_routing_reason":"Reprezentacja: limit 0.025% przychodu","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Reprezentacja — KUP ograniczony do 0.025% rocznego przychodu (limit)"]} {
    object.get(input.invoice, "expense_type", "") == "REPRESENTATION"
    object.get(input.invoice, "over_representation_limit", false) == true
}

# ══ R1679-R1683: Digital Advertising ══
else := {"matched":true,"rule_id":"jdg.advertising.hyper.digital_google_ads_kup","package":"jdg.advertising.hyper","priority":1679,"_routing":"","_routing_reason":"Google Ads → KUP 100%","_legal_basis":"Art. 22 PIT","_warnings":["Google Ads — KUP 100% (informacja o produkcie = reklama, nie reprezentacja)"]} {
    object.get(input.invoice, "ad_platform", "") == "GOOGLE_ADS"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.digital_facebook_ads_kup","package":"jdg.advertising.hyper","priority":1680,"_routing":"","_routing_reason":"Facebook/IG Ads → KUP 100%","_legal_basis":"Art. 22 PIT","_warnings":["Facebook/Instagram Ads — KUP 100%"]} {
    object.get(input.invoice, "ad_platform", "") == "FACEBOOK_ADS"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.digital_seo_sem_kup","package":"jdg.advertising.hyper","priority":1681,"_routing":"","_routing_reason":"SEO/SEM → KUP 100%","_legal_basis":"Art. 22 PIT","_warnings":["SEO/SEM — KUP 100% (optymalizacja widoczności strony firmowej)"]} {
    object.get(input.invoice, "ad_platform", "") == "SEO_SEM"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.digital_email_marketing_kup","package":"jdg.advertising.hyper","priority":1682,"_routing":"","_routing_reason":"Email marketing → KUP 100%","_legal_basis":"Art. 22 PIT","_warnings":["Email marketing komercyjny — KUP 100%"]} {
    object.get(input.invoice, "ad_platform", "") == "EMAIL_MARKETING"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.digital_affiliate_kup","package":"jdg.advertising.hyper","priority":1683,"_routing":"","_routing_reason":"Program afiliacyjny → KUP 100%","_legal_basis":"Art. 22 PIT","_warnings":["Programy afiliacyjne — KUP 100% (prowizja za sprzedaż)"]} {
    object.get(input.invoice, "ad_platform", "") == "AFFILIATE"
}

# ══ R1684-R1688: Events ══
else := {"matched":true,"rule_id":"jdg.advertising.hyper.events_trade_fair_kup","package":"jdg.advertising.hyper","priority":1684,"_routing":"","_routing_reason":"Targi → KUP 100%","_legal_basis":"Art. 22 PIT","_warnings":["Udział w targach — KUP 100% (stoisko, powierzchnia, transport)"]} {
    object.get(input.invoice, "event_type", "") == "TRADE_FAIR"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.events_business_dinner_kup","package":"jdg.advertising.hyper","priority":1685,"_routing":"","_routing_reason":"Kolacja biznesowa z agendą → KUP","_legal_basis":"Art. 22 PIT","_warnings":["Kolacja biznesowa z agendą merytoryczną → KUP"]} {
    object.get(input.invoice, "event_type", "") == "BUSINESS_DINNER"
    object.get(input.invoice, "has_business_agenda", false) == true
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.events_luxury_trip_nkup","package":"jdg.advertising.hyper","priority":1686,"_routing":"WARNING","_routing_reason":"Luksusowy wyjazd bez agendy → NKUP","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Luksusowy wyjazd bez agendy biznesowej → NKUP (reprezentacja)"]} {
    object.get(input.invoice, "event_type", "") == "TRIP"
    object.get(input.invoice, "has_business_agenda", false) == false
    object.get(input.invoice, "luxury", false) == true
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.events_conference_speaker_kup","package":"jdg.advertising.hyper","priority":1687,"_routing":"","_routing_reason":"Prelegent na konferencji → KUP","_legal_basis":"Art. 22 PIT","_warnings":["Wystąpienie jako prelegent — KUP (promocja ekspercka firmy)"]} {
    object.get(input.invoice, "event_type", "") == "CONFERENCE_SPEAKER"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.events_networking_kup","package":"jdg.advertising.hyper","priority":1688,"_routing":"","_routing_reason":"Event networkingowy → KUP","_legal_basis":"Art. 22 PIT","_warnings":["Event networkingowy — KUP jeśli dominuje cel promocyjny"]} {
    object.get(input.invoice, "event_type", "") == "NETWORKING"
    object.get(input.invoice, "primary_purpose", "") == "PROMOTION"
}

# ══ R1689-R1693: Gifts ══
else := {"matched":true,"rule_id":"jdg.advertising.hyper.gifts_under_200_branded_kup","package":"jdg.advertising.hyper","priority":1689,"_routing":"","_routing_reason":"Prezent <200 PLN z logo → KUP","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Prezent dla kontrahenta <200 PLN z logo firmy → KUP"]} {
    object.get(input.invoice, "expense_subtype", "") == "GIFT"
    object.get(input.invoice, "gift_value", 0) <= 200
    object.get(input.invoice, "branded_with_logo", false) == true
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.gifts_over_200_nkup","package":"jdg.advertising.hyper","priority":1690,"_routing":"WARNING","_routing_reason":"Prezent >200 PLN → NKUP","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Prezent dla kontrahenta >200 PLN → NKUP (reprezentacja)"]} {
    object.get(input.invoice, "expense_subtype", "") == "GIFT"
    object.get(input.invoice, "gift_value", 0) > 200
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.gifts_unbranded_nkup","package":"jdg.advertising.hyper","priority":1691,"_routing":"WARNING","_routing_reason":"Prezent bez logo → NKUP","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Prezent bez logo firmy → NKUP (reprezentacja osobista)"]} {
    object.get(input.invoice, "expense_subtype", "") == "GIFT"
    object.get(input.invoice, "branded_with_logo", false) == false
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.gifts_samples_products_kup","package":"jdg.advertising.hyper","priority":1692,"_routing":"","_routing_reason":"Próbki produktów → KUP","_legal_basis":"Art. 22 PIT","_warnings":["Próbki własnych produktów → KUP (związane z działalnością)"]} {
    object.get(input.invoice, "expense_subtype", "") == "PRODUCT_SAMPLE"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.gifts_vat_deduction_100pln","package":"jdg.advertising.hyper","priority":1693,"_routing":"","_routing_reason":"VAT od prezentów: limit 100 PLN netto","_legal_basis":"Art. 88 ust. 1 pkt 5 VAT","_warnings":["VAT od prezentów — odliczenie tylko do 100 PLN wartości netto prezentu"]} {
    object.get(input.invoice, "expense_subtype", "") == "GIFT"
    object.get(input.invoice, "gift_value_netto", 0) > 100
}

# ══ R1694-R1698: Sponsorship ══
else := {"matched":true,"rule_id":"jdg.advertising.hyper.sponsorship_with_benefits_kup","package":"jdg.advertising.hyper","priority":1694,"_routing":"","_routing_reason":"Sponsoring z kontrświadczeniami → KUP","_legal_basis":"Art. 22 PIT","_warnings":["Sponsoring z ekspozycją logo/promocją → KUP 100%"]} {
    object.get(input.invoice, "expense_subtype", "") == "SPONSORSHIP"
    object.get(input.invoice, "brand_exposure", false) == true
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.sponsorship_without_benefits_donation","package":"jdg.advertising.hyper","priority":1695,"_routing":"WARNING","_routing_reason":"Sponsoring bez kontrświadczeń → darowizna","_legal_basis":"Art. 26 PIT","_warnings":["Sponsoring bez kontrświadczeń → traktowany jak darowizna (odliczenie max 6% dochodu)"]} {
    object.get(input.invoice, "expense_subtype", "") == "SPONSORSHIP"
    object.get(input.invoice, "brand_exposure", false) == false
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.sponsorship_sport_culture_kup","package":"jdg.advertising.hyper","priority":1696,"_routing":"","_routing_reason":"Sponsoring sportu/kultury → KUP","_legal_basis":"Art. 22 PIT","_warnings":["Sponsoring sportu/kultury z ekspozycją marki → KUP 100%"]} {
    object.get(input.invoice, "sponsorship_area", "") == "SPORT"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.sponsorship_local_event_kup","package":"jdg.advertising.hyper","priority":1697,"_routing":"","_routing_reason":"Sponsoring lokalnego wydarzenia → KUP","_legal_basis":"Art. 22 PIT","_warnings":["Sponsoring lokalnego wydarzenia → KUP (promocja lokalna)"]} {
    object.get(input.invoice, "sponsorship_area", "") == "LOCAL_EVENT"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.sponsorship_vat_deduction","package":"jdg.advertising.hyper","priority":1698,"_routing":"","_routing_reason":"VAT od sponsoringu → 100% odliczenia","_legal_basis":"Art. 86 VAT","_warnings":["VAT od sponsoringu z kontrświadczeniami — odliczenie 100%"]} {
    object.get(input.invoice, "expense_subtype", "") == "SPONSORSHIP"
    object.get(input.invoice, "brand_exposure", false) == true
}

# ══ R1699-R1703: VAT on Advertising ══
else := {"matched":true,"rule_id":"jdg.advertising.hyper.vat_standard_deduction_full","package":"jdg.advertising.hyper","priority":1699,"_routing":"","_routing_reason":"VAT od reklamy standardowej → 100%","_legal_basis":"Art. 86 VAT","_warnings":["VAT od standardowych wydatków reklamowych — odliczenie 100%"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
    object.get(input.invoice, "vat_rate", "") == "0.23"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.vat_gifts_100pln_limit","package":"jdg.advertising.hyper","priority":1700,"_routing":"","_routing_reason":"VAT od prezentów: limit 100 PLN","_legal_basis":"Art. 88 ust. 1 pkt 5 VAT","_warnings":["VAT od prezentów odliczalny tylko do 100 PLN wartości netto prezentu"]} {
    object.get(input.invoice, "expense_subtype", "") == "GIFT"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.vat_imported_ad_reverse_charge","package":"jdg.advertising.hyper","priority":1701,"_routing":"WARNING","_routing_reason":"Import usług reklamowych z UE → reverse charge","_legal_basis":"Art. 28b VAT","_warnings":["Import usług reklamowych z UE — rozlicz reverse charge (import usług)"]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
    object.get(input.vendor, "country", "PL") != "PL"
    object.get(input.vendor, "eu_country", false) == true
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.vat_cross_border_ads_b2b","package":"jdg.advertising.hyper","priority":1702,"_routing":"","_routing_reason":"Reklama B2B transgraniczna → reverse charge","_legal_basis":"Art. 28b VAT","_warnings":["Reklama B2B do UE — miejsce świadczenia = siedziba nabywcy, reverse charge lub NP"]} {
    object.get(input.invoice, "ad_service_to_eu", false) == true
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.vat_google_fb_import_services","package":"jdg.advertising.hyper","priority":1703,"_routing":"WARNING","_routing_reason":"Google/FB Ads → import usług","_legal_basis":"Art. 28b VAT","_warnings":["Google/Facebook Ads — import usług, reverse charge (konto firmowe)"]} {
    object.get(input.invoice, "ad_platform", "") == "GOOGLE_ADS"
}

# ══ R1704-R1707: Influencer Marketing ══
else := {"matched":true,"rule_id":"jdg.advertising.hyper.influencer_with_description_kup","package":"jdg.advertising.hyper","priority":1704,"_routing":"","_routing_reason":"Influencer z opisem usługi → KUP","_legal_basis":"Art. 22 PIT","_warnings":["Influencer marketing — KUP jeśli faktura opisuje świadczenie promocyjne"]} {
    object.get(input.invoice, "expense_subtype", "") == "INFLUENCER"
    object.get(input.invoice, "invoice_describes_service", false) == true
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.influencer_no_biz_connection_nkup","package":"jdg.advertising.hyper","priority":1705,"_routing":"WARNING","_routing_reason":"Influencer bez związku z biznesem → NKUP","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":["Influencer bez związku z produktem/usługą → NKUP (reprezentacja)"]} {
    object.get(input.invoice, "expense_subtype", "") == "INFLUENCER"
    object.get(input.invoice, "promotes_business", false) == false
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.influencer_vat_b2b","package":"jdg.advertising.hyper","priority":1706,"_routing":"","_routing_reason":"Influencer B2B zagraniczny → reverse charge","_legal_basis":"Art. 28b VAT","_warnings":["Influencer B2B spoza PL — reverse charge lub brak VAT (NP)"]} {
    object.get(input.invoice, "expense_subtype", "") == "INFLUENCER"
    object.get(input.vendor, "country", "PL") != "PL"
}
else := {"matched":true,"rule_id":"jdg.advertising.hyper.influencer_gift_vs_service","package":"jdg.advertising.hyper","priority":1707,"_routing":"WARNING","_routing_reason":"Influencer: prezent vs usługa","_legal_basis":"Art. 22 vs 23 PIT","_warnings":["Rozróżnij: prezent dla influencera (NKUP jeśli >200 PLN) od usługi promocyjnej (KUP)"]} {
    object.get(input.invoice, "expense_subtype", "") == "INFLUENCER"
    object.get(input.invoice, "classification_unclear", false) == true
}

# ══ R1708: Car Wrapping ══
else := {"matched":true,"rule_id":"jdg.advertising.hyper.car_wrapping_vat26_full","package":"jdg.advertising.hyper","priority":1708,"_routing":"","_routing_reason":"Oklejenie auta → VAT-26 → 100%","_legal_basis":"Art. 86a VAT, Art. 23 PIT","_warnings":["Oklejenie reklamowe auta — złóż VAT-26: 100% odliczenia VAT + 100% KUP paliwa i eksploatacji"]} {
    object.get(input.invoice, "expense_subtype", "") == "CAR_WRAPPING"
}
