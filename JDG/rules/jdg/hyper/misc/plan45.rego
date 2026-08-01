# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 49

package jdg.hyper.misc

default decide := {"matched":false,"rule_id":"jdg.hyper.misc.no_match","package":"jdg.hyper.misc","priority":99999}

# jdg.hyper.misc.payment.advance.kup_from_advance_to_supplier — Zaliczka do dostawcy — KUP w dacie zapłaty (metoda kasowa) lub dostawy (memoriałowa)
decide :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.advance.kup_from_advance_to_supplier","package":"jdg.hyper.misc","priority":1660,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_type == "ADVANCE"` AND `direction == "PURCHASE"`","_legal_basis":"Art. 22 PIT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.inkind.market_value_determination — Świadczenie niepieniężne — przychód wg wartości rynkowej
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.inkind.market_value_determination","package":"jdg.hyper.misc","priority":1661,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == "IN_KIND"`","_legal_basis":"Art. 14 ust. 2 PIT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.inkind.vat_base_market_value — Podstawa VAT dla świadczenia niepieniężnego — wartość rynkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.inkind.vat_base_market_value","package":"jdg.hyper.misc","priority":1662,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == "IN_KIND"`","_legal_basis":"Art. 29a VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.inkind.mixed_cash_inkind_split — Płatność mieszana (część gotówka, część niepieniężna) — rozdzielenie
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.inkind.mixed_cash_inkind_split","package":"jdg.hyper.misc","priority":1663,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == "MIXED_CASH_IN_KIND"`","_legal_basis":"Art. 29a VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.inkind.employee_compensation_tax — Wynagrodzenie pracownika w naturze — PIT + ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.inkind.employee_compensation_tax","package":"jdg.hyper.misc","priority":1664,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_type == "EMPLOYEE_BENEFIT_IN_KIND"`","_legal_basis":"Art. 12 PIT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.inkind.shareholder_benefit_tax — Świadczenie dla właściciela JDG — traktowane jak dywidenda (19% ryczałt)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.inkind.shareholder_benefit_tax","package":"jdg.hyper.misc","priority":1665,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_type == "OWNER_BENEFIT_IN_KIND"` AND `not_business_expense == true`","_legal_basis":"Art. 30a PIT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.foreign.cash_limit_15k_pln_equivalent — Limit 15k PLN dla płatności gotówkowych w walucie obcej
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.foreign.cash_limit_15k_pln_equivalent","package":"jdg.hyper.misc","priority":1666,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == "CASH"` AND `currency != "PLN"` AND `amount_pln_equivalent ≥ 15000`","_legal_basis":"Art. 22p PIT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.foreign.transfer_whitelist_required — Przelew zagraniczny >15k PLN — weryfikacja WL (dla PL kontrahentów)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.foreign.transfer_whitelist_required","package":"jdg.hyper.misc","priority":1667,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`transfer_cross_border == true` AND `amount_pln ≥ 15000` AND `vendor_country == "PL"`","_legal_basis":"Art. 96b VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.foreign.transfer_giif_reporting — Przelew zagraniczny >15k EUR → obowiązek raportu GIIF
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.foreign.transfer_giif_reporting","package":"jdg.hyper.misc","priority":1668,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`transfer_cross_border == true` AND `amount_eur ≥ 15000`","_legal_basis":"Art. 72 AML","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.foreign.swift_sepa_authorization — Płatność SEPA/SWIFT — autoryzacja bankowa
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.foreign.swift_sepa_authorization","package":"jdg.hyper.misc","priority":1669,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_rail in ["SEPA","SWIFT"]`","_legal_basis":"—","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.foreign.fx_spread_recognition — Spread walutowy banku — KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.foreign.fx_spread_recognition","package":"jdg.hyper.misc","priority":1670,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_rail in ["SWIFT","SEPA"]` AND `currency != "PLN"`","_legal_basis":"Art. 22 PIT","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.misc.payment.terminal.obligation_20k_eur_turnover — Terminal płatniczy — obowiązek przy obrocie >20k EUR i >50% B2C
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.terminal.obligation_20k_eur_turnover","package":"jdg.hyper.misc","priority":1671,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`annual_b2c_turnover_eur ≥ 20000` AND `b2c_share ≥ 0.50`","_legal_basis":"Ustawa o usługach płatniczych","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.terminal.sanction_no_terminal_5000 — Brak terminala → kara 5 000 PLN
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.terminal.sanction_no_terminal_5000","package":"jdg.hyper.misc","priority":1672,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`terminal_required == true` AND `terminal_installed == false`","_legal_basis":"Ustawa o usługach płatniczych","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.payment.terminal.vat_deduction_terminal_cost — Koszt terminala + prowizje — KUP + VAT odliczalny
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.payment.terminal.vat_deduction_terminal_cost","package":"jdg.hyper.misc","priority":1673,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`terminal_installed == true`","_legal_basis":"Art. 22 PIT, Art. 86 VAT","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"
}

# jdg.hyper.misc.advertising.vs_representation.distinction_test — Test rozróżnienia: reklama (KUP) vs reprezentacja (NKUP)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.vs_representation.distinction_test","package":"jdg.hyper.misc","priority":1674,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`expense_type == "MARKETING"`","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.product_promotion_kup — Promocja konkretnego produktu/usługi → KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.product_promotion_kup","package":"jdg.hyper.misc","priority":1675,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`promotes_specific_product == true`","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.brand_building_kup — Budowanie marki (nie osobistej) → KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.brand_building_kup","package":"jdg.hyper.misc","priority":1676,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`promotes_company_brand == true` AND `not_personal_brand == true`","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.representation_personal_prestige_nkup — Budowanie osobistego prestiżu właściciela → NKUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.representation_personal_prestige_nkup","package":"jdg.hyper.misc","priority":1677,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`promotes_owner_personally == true` AND `no_product_connection == true`","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.representation_nkup_100pct — Reprezentacja NKUP 100% (R-ADV-1 fix: limit 0.25% zniesiony 01.01.2018)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.representation_nkup_100pct","package":"jdg.hyper.misc","priority":1678,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Reprezentacja = NKUP 100% (R-ADV-1 fix: limit zniesiony 2018)","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT (stan prawny 01.01.2018+)","_warnings":["Reprezentacja = NKUP w 100%! Historyczny limit 0.25% przychodu został zniesiony 01.01.2018. Nie stosuj limitu — reprezentacja NIE jest KUP"]} {
    object.get(input.invoice, "expense_type", "") == "REPRESENTATION"
}

# jdg.hyper.misc.advertising.digital.google_ads_kup — Google Ads — KUP 100%
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.digital.google_ads_kup","package":"jdg.hyper.misc","priority":1679,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`platform == "GOOGLE_ADS"` AND `promotes_business == true`","_legal_basis":"Art. 22 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.digital.facebook_ads_kup — Facebook/Instagram Ads — KUP 100%
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.digital.facebook_ads_kup","package":"jdg.hyper.misc","priority":1680,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`platform == "FACEBOOK_ADS"` AND `promotes_business == true`","_legal_basis":"Art. 22 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.digital.seo_sem_kup — SEO/SEM — KUP 100%
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.digital.seo_sem_kup","package":"jdg.hyper.misc","priority":1681,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`expense_type in ["SEO","SEM"]`","_legal_basis":"Art. 22 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.digital.email_marketing_kup — Email marketing — KUP 100%
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.digital.email_marketing_kup","package":"jdg.hyper.misc","priority":1682,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`platform == "EMAIL_MARKETING"` AND `commercial_in_nature == true`","_legal_basis":"Art. 22 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.digital.affiliate_program_kup — Programy afiliacyjne — KUP 100%
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.digital.affiliate_program_kup","package":"jdg.hyper.misc","priority":1683,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`expense_type == "AFFILIATE"` AND `commission_for_sales == true`","_legal_basis":"Art. 22 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.events.trade_fair_kup — Udział w targach — KUP 100% (stoisko, powierzchnia, transport)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.events.trade_fair_kup","package":"jdg.hyper.misc","priority":1684,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`event_type == "TRADE_FAIR"`","_legal_basis":"Art. 22 PIT, Art. 26ec PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.events.business_dinner_with_agenda_kup — Kolacja biznesowa z agendą merytoryczną → KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.events.business_dinner_with_agenda_kup","package":"jdg.hyper.misc","priority":1685,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`event_type == "BUSINESS_DINNER"` AND `has_business_agenda == true`","_legal_basis":"Art. 22 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.events.luxury_trip_no_agenda_nkup — Luksusowy wyjazd bez agendy → NKUP (reprezentacja)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.events.luxury_trip_no_agenda_nkup","package":"jdg.hyper.misc","priority":1686,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`event_type == "TRIP"` AND `no_business_agenda == true` AND `luxury == true`","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.events.conference_speaker_kup — Wystąpienie jako prelegent na konferencji — KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.events.conference_speaker_kup","package":"jdg.hyper.misc","priority":1687,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`event_type == "CONFERENCE_SPEAKER"` AND `promotes_business == true`","_legal_basis":"Art. 22 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.events.networking_event_kup — Event networkingowy — KUP jeśli dominuje cel promocyjny
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.events.networking_event_kup","package":"jdg.hyper.misc","priority":1688,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`event_type == "NETWORKING"` AND `primary_purpose == "PROMOTION"`","_legal_basis":"Art. 22 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.gifts.under_200_pln_branded_kup — Prezent dla kontrahenta <200 PLN z logo → KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.gifts.under_200_pln_branded_kup","package":"jdg.hyper.misc","priority":1689,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`gift_value ≤ 200` AND `branded_with_logo == true`","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.gifts.over_200_pln_nkup — Prezent dla kontrahenta >200 PLN → NKUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.gifts.over_200_pln_nkup","package":"jdg.hyper.misc","priority":1690,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`gift_value > 200` AND `recipient == "BUSINESS_PARTNER"`","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.gifts.unbranded_nkup — Prezent bez logo firmy → NKUP (reprezentacja)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.gifts.unbranded_nkup","package":"jdg.hyper.misc","priority":1691,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`branded_with_logo == false` AND `gift_value > 0`","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.gifts.samples_products_kup — Próbki produktów → KUP (jeśli mają związek z działalnością)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.gifts.samples_products_kup","package":"jdg.hyper.misc","priority":1692,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`gift_type == "PRODUCT_SAMPLE"` AND `related_to_business == true`","_legal_basis":"Art. 22 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.gifts.vat_deduction_100_pln_limit — VAT od prezentów — odliczenie tylko do 100 PLN netto
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.gifts.vat_deduction_100_pln_limit","package":"jdg.hyper.misc","priority":1693,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`gift_value_netto > 100`","_legal_basis":"Art. 88 ust. 1 pkt 5 VAT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.sponsorship.with_benefits_kup — Sponsoring z kontrświadczeniami (logo, promocja) → KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.sponsorship.with_benefits_kup","package":"jdg.hyper.misc","priority":1694,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`sponsorship_type == "WITH_BENEFITS"` AND `logo_exposure == true`","_legal_basis":"Art. 22 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.sponsorship.charity_donation_treatment — Sponsoring bez kontrświadczeń → traktowany jak darowizna (limit 6%)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.sponsorship.charity_donation_treatment","package":"jdg.hyper.misc","priority":1695,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`sponsorship_type == "WITHOUT_BENEFITS"`","_legal_basis":"Art. 26 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.sponsorship.sport_culture_kup — Sponsoring sportu/kultury z ekspozycją marki → KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.sponsorship.sport_culture_kup","package":"jdg.hyper.misc","priority":1696,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`sponsorship_area in ["SPORT","CULTURE"]` AND `brand_exposure == true`","_legal_basis":"Art. 22 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.sponsorship.local_event_kup — Sponsoring lokalnego wydarzenia → KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.sponsorship.local_event_kup","package":"jdg.hyper.misc","priority":1697,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`sponsorship_area == "LOCAL_EVENT"` AND `local_business == true`","_legal_basis":"Art. 22 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.sponsorship.vat_on_sponsorship — VAT od sponsoringu — odliczenie w 100% (czynności opodatkowane)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.sponsorship.vat_on_sponsorship","package":"jdg.hyper.misc","priority":1698,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`sponsorship_with_benefits == true`","_legal_basis":"Art. 86 VAT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.vat.deduction_full_standard — VAT od standardowej reklamy — 100% odliczenia
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.vat.deduction_full_standard","package":"jdg.hyper.misc","priority":1699,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`ad_type == "STANDARD_ADVERTISING"`","_legal_basis":"Art. 86 VAT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.vat.deduction_gifts_100pln_limit — VAT od prezentów reklamowych — limit 100 PLN netto
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.vat.deduction_gifts_100pln_limit","package":"jdg.hyper.misc","priority":1700,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`ad_type == "GIFT"` AND `value_netto > 100`","_legal_basis":"Art. 88 ust. 1 pkt 5 VAT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.vat.imported_ad_services_reverse_charge — Import usług reklamowych z UE — reverse charge
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.vat.imported_ad_services_reverse_charge","package":"jdg.hyper.misc","priority":1701,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`ad_services_from_eu == true` AND `direction == "PURCHASE"`","_legal_basis":"Art. 28b VAT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.vat.cross_border_ads_vat_rules — VAT od reklamy transgranicznej — miejsce świadczenia = siedziba nabywcy B2B
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.vat.cross_border_ads_vat_rules","package":"jdg.hyper.misc","priority":1702,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`ad_services_to_eu_b2b == true`","_legal_basis":"Art. 28b VAT","_warnings":[]} {
    object.get(input.document, "tax_proceedings_active", false) == true; object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.vat.ads_on_platform_google_fb — Reklama na Google/Facebook — import usług, reverse charge (B2B)
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.vat.ads_on_platform_google_fb","package":"jdg.hyper.misc","priority":1703,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`platform in ["GOOGLE","FACEBOOK"]` AND `account_type == "BUSINESS"`","_legal_basis":"Art. 28b VAT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.influencer.kup_with_invoice_description — Influencer marketing — KUP jeśli faktura opisuje świadczenie promocyjne
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.influencer.kup_with_invoice_description","package":"jdg.hyper.misc","priority":1704,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`expense_type == "INFLUENCER"` AND `invoice_describes_promotional_service == true`","_legal_basis":"Art. 22 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.influencer.nkup_no_business_connection — Influencer bez związku z biznesem → NKUP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.influencer.nkup_no_business_connection","package":"jdg.hyper.misc","priority":1705,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`expense_type == "INFLUENCER"` AND `promotes_business == false`","_legal_basis":"Art. 23 ust. 1 pkt 23 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.influencer.vat_treatment_b2b — Influencer B2B → reverse charge lub NP
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.influencer.vat_treatment_b2b","package":"jdg.hyper.misc","priority":1706,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`influencer_b2b == true` AND `influencer_country != "PL"`","_legal_basis":"Art. 28b VAT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.influencer.gift_vs_service_classification — Rozróżnienie: prezent dla influencera vs. usługa promocyjna
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.influencer.gift_vs_service_classification","package":"jdg.hyper.misc","priority":1707,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`transaction_with_influencer == true`","_legal_basis":"Art. 22 vs 23 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}

# jdg.hyper.misc.advertising.car_wrapping.vat26_full_deduction — Oklejenie auta reklamą → VAT-26 → 100% odliczenia VAT + 100% KUP paliwa
else :=   {"matched":true,"rule_id":"jdg.hyper.misc.advertising.car_wrapping.vat26_full_deduction","package":"jdg.hyper.misc","priority":1708,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`car_wrapping_for_ads == true` AND `vat26_filed == true`","_legal_basis":"Art. 86a VAT, Art. 23 PIT","_warnings":[]} {
    object.get(input.invoice, "expense_type", "") == "ADVERTISING"
}
