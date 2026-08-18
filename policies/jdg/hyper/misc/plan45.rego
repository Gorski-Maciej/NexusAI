# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 49

package jdg.hyper.misc

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.hyper.misc.no_match","package":"jdg.hyper.misc","priority":99999}

# jdg.hyper.misc.payment.advance.kup_from_advance_to_supplier — Zaliczka do dostawcy — KUP w dacie zapłaty (metoda kasowa) lub dostawy (memoriałowa)
decide :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.advance.kup_from_advance_to_supplier","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.inkind.market_value_determination — Świadczenie niepieniężne — przychód wg wartości rynkowej
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.inkind.market_value_determination","_legal_basis":"Art. 14 ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.inkind.vat_base_market_value — Podstawa VAT dla świadczenia niepieniężnego — wartość rynkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.inkind.vat_base_market_value","_legal_basis":"Art. 29a ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.inkind.mixed_cash_inkind_split — Płatność mieszana (część gotówka, część niepieniężna) — rozdzielenie
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.inkind.mixed_cash_inkind_split","_legal_basis":"Art. 29a ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.inkind.employee_compensation_tax — Wynagrodzenie pracownika w naturze — PIT + ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.inkind.employee_compensation_tax","_legal_basis":"Art. 12 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.inkind.shareholder_benefit_tax — Świadczenie dla właściciela JDG — traktowane jak dywidenda (19% ryczałt)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.inkind.shareholder_benefit_tax","_legal_basis":"Art. 30a ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.foreign.cash_limit_15k_pln_equivalent — Limit 15k PLN dla płatności gotówkowych w walucie obcej
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.foreign.cash_limit_15k_pln_equivalent","_legal_basis":"Art. 22p ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.foreign.transfer_whitelist_required — Przelew zagraniczny >15k PLN — weryfikacja WL (dla PL kontrahentów)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.foreign.transfer_whitelist_required","_legal_basis":"Art. 96b ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.foreign.transfer_giif_reporting — Przelew zagraniczny >15k EUR → obowiązek raportu GIIF
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.foreign.transfer_giif_reporting","_legal_basis":"Art. 72 ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.foreign.swift_sepa_authorization — Płatność SEPA/SWIFT — autoryzacja bankowa
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.foreign.swift_sepa_authorization","_legal_basis":"ustawy z dnia 27 lipca 2002 r. — Prawo dewizowe","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.foreign.fx_spread_recognition — Spread walutowy banku — KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.foreign.fx_spread_recognition","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    input.invoice.currency != "PLN"
}

# jdg.hyper.misc.payment.terminal.obligation_20k_eur_turnover — Terminal płatniczy — obowiązek przy obrocie >20k EUR i >50% B2C
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.terminal.obligation_20k_eur_turnover","_legal_basis":"ustawy z dnia 19 sierpnia 2011 r. o usługach płatniczych","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.terminal.sanction_no_terminal_5000 — Brak terminala → kara 5 000 PLN
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.terminal.sanction_no_terminal_5000","_legal_basis":"ustawy z dnia 19 sierpnia 2011 r. o usługach płatniczych","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.terminal.vat_deduction_terminal_cost — Koszt terminala + prowizje — KUP + VAT odliczalny
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.terminal.vat_deduction_terminal_cost","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.), Art. 86 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.advertising.vs_representation.distinction_test — Test rozróżnienia: reklama (KUP) vs reprezentacja (NKUP)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.vs_representation.distinction_test","_legal_basis":"Art. 23 ust. 1 pkt 23 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.product_promotion_kup — Promocja konkretnego produktu/usługi → KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.product_promotion_kup","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.brand_building_kup — Budowanie marki (nie osobistej) → KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.brand_building_kup","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.representation_personal_prestige_nkup — Budowanie osobistego prestiżu właściciela → NKUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.representation_personal_prestige_nkup","_legal_basis":"Art. 23 ust. 1 pkt 23 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.representation_nkup_100pct — Reprezentacja NKUP 100% (R-ADV-1 fix: limit 0.25% zniesiony 01.01.2018)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.representation_nkup_100pct","_legal_basis":"Art. 23 ust. 1 pkt 23 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.) (stan prawny 01.01.2018+)","_warnings":["Reprezentacja = NKUP w 100%! Historyczny limit 0.25% przychodu został zniesiony 01.01.2018. Nie stosuj limitu — reprezentacja NIE jest KUP"]} if {
    object.get(input.invoice, "expense_type", "") == "REPRESENTATION"
}

# jdg.hyper.misc.advertising.digital.google_ads_kup — Google Ads — KUP 100%
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.digital.google_ads_kup","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.digital.facebook_ads_kup — Facebook/Instagram Ads — KUP 100%
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.digital.facebook_ads_kup","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.digital.seo_sem_kup — SEO/SEM — KUP 100%
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.digital.seo_sem_kup","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.digital.email_marketing_kup — Email marketing — KUP 100%
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.digital.email_marketing_kup","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.digital.affiliate_program_kup — Programy afiliacyjne — KUP 100%
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.digital.affiliate_program_kup","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.events.trade_fair_kup — Udział w targach — KUP 100% (stoisko, powierzchnia, transport)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.events.trade_fair_kup","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.), Art. 26ec ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.events.business_dinner_with_agenda_kup — Kolacja biznesowa z agendą merytoryczną → KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.events.business_dinner_with_agenda_kup","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.events.luxury_trip_no_agenda_nkup — Luksusowy wyjazd bez agendy → NKUP (reprezentacja)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.events.luxury_trip_no_agenda_nkup","_legal_basis":"Art. 23 ust. 1 pkt 23 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.events.conference_speaker_kup — Wystąpienie jako prelegent na konferencji — KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.events.conference_speaker_kup","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.events.networking_event_kup — Event networkingowy — KUP jeśli dominuje cel promocyjny
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.events.networking_event_kup","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.gifts.under_200_pln_branded_kup — Prezent dla kontrahenta <200 PLN z logo → KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.gifts.under_200_pln_branded_kup","_legal_basis":"Art. 23 ust. 1 pkt 23 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.gifts.over_200_pln_nkup — Prezent dla kontrahenta >200 PLN → NKUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.gifts.over_200_pln_nkup","_legal_basis":"Art. 23 ust. 1 pkt 23 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.gifts.unbranded_nkup — Prezent bez logo firmy → NKUP (reprezentacja)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.gifts.unbranded_nkup","_legal_basis":"Art. 23 ust. 1 pkt 23 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.gifts.samples_products_kup — Próbki produktów → KUP (jeśli mają związek z działalnością)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.gifts.samples_products_kup","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.gifts.vat_deduction_100_pln_limit — VAT od prezentów — odliczenie tylko do 100 PLN netto
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.gifts.vat_deduction_100_pln_limit","_legal_basis":"Art. 88 ust. 1 pkt 5 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.sponsorship.with_benefits_kup — Sponsoring z kontrświadczeniami (logo, promocja) → KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.sponsorship.with_benefits_kup","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.sponsorship.charity_donation_treatment — Sponsoring bez kontrświadczeń → traktowany jak darowizna (limit 6%)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.sponsorship.charity_donation_treatment","_legal_basis":"Art. 26 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.sponsorship.sport_culture_kup — Sponsoring sportu/kultury z ekspozycją marki → KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.sponsorship.sport_culture_kup","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.sponsorship.local_event_kup — Sponsoring lokalnego wydarzenia → KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.sponsorship.local_event_kup","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.sponsorship.vat_on_sponsorship — VAT od sponsoringu — odliczenie w 100% (czynności opodatkowane)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.sponsorship.vat_on_sponsorship","_legal_basis":"Art. 86 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.vat.deduction_full_standard — VAT od standardowej reklamy — 100% odliczenia
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.vat.deduction_full_standard","_legal_basis":"Art. 86 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.vat.deduction_gifts_100pln_limit — VAT od prezentów reklamowych — limit 100 PLN netto
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.vat.deduction_gifts_100pln_limit","_legal_basis":"Art. 88 ust. 1 pkt 5 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.vat.imported_ad_services_reverse_charge — Import usług reklamowych z UE — reverse charge
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.vat.imported_ad_services_reverse_charge","_legal_basis":"Art. 28b ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.vat.cross_border_ads_vat_rules — VAT od reklamy transgranicznej — miejsce świadczenia = siedziba nabywcy B2B
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.vat.cross_border_ads_vat_rules","_legal_basis":"Art. 28b ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.document, "tax_proceedings_active", false) == true; object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.vat.ads_on_platform_google_fb — Reklama na Google/Facebook — import usług, reverse charge (B2B)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.vat.ads_on_platform_google_fb","_legal_basis":"Art. 28b ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.influencer.kup_with_invoice_description — Influencer marketing — KUP jeśli faktura opisuje świadczenie promocyjne
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.influencer.kup_with_invoice_description","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.influencer.nkup_no_business_connection — Influencer bez związku z biznesem → NKUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.influencer.nkup_no_business_connection","_legal_basis":"Art. 23 ust. 1 pkt 23 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.influencer.vat_treatment_b2b — Influencer B2B → reverse charge lub NP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.influencer.vat_treatment_b2b","_legal_basis":"Art. 28b ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.influencer.gift_vs_service_classification — Rozróżnienie: prezent dla influencera vs. usługa promocyjna
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.influencer.gift_vs_service_classification","_legal_basis":"Art. 22 vs 23 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.car_wrapping.vat26_full_deduction — Oklejenie auta reklamą → VAT-26 → 100% odliczenia VAT + 100% KUP paliwa
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.car_wrapping.vat26_full_deduction","_legal_basis":"Art. 86a ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.), Art. 23 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}
