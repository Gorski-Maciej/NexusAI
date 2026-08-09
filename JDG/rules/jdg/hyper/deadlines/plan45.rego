# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 41

package jdg.hyper.deadlines

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.hyper.deadlines.no_match","package":"jdg.hyper.deadlines","priority":99999}

# jdg.hyper.deadlines.insurance.mandatory.detection_construction — OC budowlane — obowiązkowe
decide :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.mandatory.detection_construction","package":"jdg.hyper.deadlines","priority":1610,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`pkd_main ⊆ [\"41.10.Z\"–\"43.99.Z\"]`","_legal_basis":"Art. 648 KC","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.mandatory.detection_transport — OC przewoźnika — obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.mandatory.detection_transport","package":"jdg.hyper.deadlines","priority":1611,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`pkd_main ⊆ [\"49.41.Z\",\"49.42.Z\"]`","_legal_basis":"Ustawa o transporcie drogowym","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.mandatory.detection_tax_advisor — OC doradcy podatkowego — obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.mandatory.detection_tax_advisor","package":"jdg.hyper.deadlines","priority":1612,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`pkd_main == \"69.20.Z\"` AND `tax_advisor_license == true`","_legal_basis":"Ustawa o doradztwie podatkowym","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.kup.mandatory_oc_premium_full — Składka OC obowiązkowego — 100% KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.kup.mandatory_oc_premium_full","package":"jdg.hyper.deadlines","priority":1613,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`mandatory_oc == true` AND `premium_paid == true`","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.kup.mandatory_oc_over_limit_proportion — Składka ponad minimum — proporcjonalny KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.kup.mandatory_oc_over_limit_proportion","package":"jdg.hyper.deadlines","priority":1614,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`mandatory_oc == true` AND `coverage_exceeds_minimum == true`","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.kup.voluntary_oc_business — Dobrowolne OC — KUP jeśli uzasadnione biznesowo
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.kup.voluntary_oc_business","package":"jdg.hyper.deadlines","priority":1615,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`voluntary_oc == true` AND `business_justification == true`","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.kup.life_insurance_limited — Ubezpieczenie na życie — ograniczone KUP (tylko składki za pracowników)
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.kup.life_insurance_limited","package":"jdg.hyper.deadlines","priority":1616,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`insurance_type == \"LIFE\"` AND `insured == \"EMPLOYEE\"`","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.kup.property_insurance_full — Ubezpieczenie mienia firmowego — pełny KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.kup.property_insurance_full","package":"jdg.hyper.deadlines","priority":1617,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`insurance_type == \"PROPERTY\"` AND `asset_business_use == true`","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.claim.payout_as_revenue — Odszkodowanie z OC — przychód podatkowy
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.claim.payout_as_revenue","package":"jdg.hyper.deadlines","priority":1618,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`insurance_payout_received == true`","_legal_basis":"Art. 14 ust. 1 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.claim.payout_reduced_by_damage — Odszkodowanie pomniejszone o poniesioną stratę
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.claim.payout_reduced_by_damage","package":"jdg.hyper.deadlines","priority":1619,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`payout_compensates_for_loss == true`","_legal_basis":"Art. 14 ust. 1 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.claim.business_interruption_taxable — Odszkodowanie za przerwę w działalności — w pełni opodatkowane
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.claim.business_interruption_taxable","package":"jdg.hyper.deadlines","priority":1620,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`insurance_type == \"BUSINESS_INTERRUPTION\"` AND `payout_received == true`","_legal_basis":"Art. 14 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.claim.personal_injury_exempt — Odszkodowanie za uszczerbek na zdrowiu — zwolnione z PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.claim.personal_injury_exempt","package":"jdg.hyper.deadlines","priority":1621,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`claim_type == \"PERSONAL_INJURY\"`","_legal_basis":"Art. 21 ust. 1 pkt 3c PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.claim.late_payment_interest_taxable — Odsetki od opóźnionej wypłaty odszkodowania — opodatkowane
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.claim.late_payment_interest_taxable","package":"jdg.hyper.deadlines","priority":1622,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`interest_on_late_payout_received == true`","_legal_basis":"Art. 17 ust. 1 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.vat.exemption_general — Usługi ubezpieczeniowe — zwolnione z VAT
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.vat.exemption_general","package":"jdg.hyper.deadlines","priority":1623,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`transaction_type == \"INSURANCE\"`","_legal_basis":"Art. 43 ust. 1 pkt 37 VAT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.vat.exception_assistance_services — Usługi assistance — NIE zwolnione (23% VAT)
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.vat.exception_assistance_services","package":"jdg.hyper.deadlines","priority":1624,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`service_type == \"ASSISTANCE\"` AND `not_integral_to_insurance == true`","_legal_basis":"Art. 41 VAT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.vat.exception_damage_assessment — Wycena szkód przez niezależnego eksperta — 23% VAT
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.vat.exception_damage_assessment","package":"jdg.hyper.deadlines","priority":1625,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`service_type == \"DAMAGE_ASSESSMENT\"` AND `provider_not_insurer == true`","_legal_basis":"Art. 41 VAT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.vat.exception_broker_services — Usługi brokera ubezpieczeniowego — 23% VAT
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.vat.exception_broker_services","package":"jdg.hyper.deadlines","priority":1626,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`provider_type == \"INSURANCE_BROKER\"`","_legal_basis":"Art. 41 VAT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.vat.input_vat_deduction_blocked — VAT od wydatków na ubezpieczenia osobiste — NIE odlicza się
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.vat.input_vat_deduction_blocked","package":"jdg.hyper.deadlines","priority":1627,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`insurance_personal == true` AND `not_business_related == true`","_legal_basis":"Art. 88 VAT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.voluntary.cyber_risk — Cyber-OC — KUP (rekomendowane dla IT JDG)
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.voluntary.cyber_risk","package":"jdg.hyper.deadlines","priority":1628,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`insurance_type == \"CYBER\"` AND `pkd_main in IT_CODES`","_legal_basis":"Art. 22 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.voluntary.directors_officers — D&O dla JDG z prokurentami — KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.voluntary.directors_officers","package":"jdg.hyper.deadlines","priority":1629,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`insurance_type == \"DAO\"` AND `has_procuration == true`","_legal_basis":"Art. 22 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.voluntary.key_person — Ubezpieczenie kluczowej osoby (właściciela JDG)
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.voluntary.key_person","package":"jdg.hyper.deadlines","priority":1630,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`insurance_type == \"KEY_PERSON\"` AND `sole_proprietor == true`","_legal_basis":"Art. 22 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.voluntary.trade_credit — Ubezpieczenie należności — KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.voluntary.trade_credit","package":"jdg.hyper.deadlines","priority":1631,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`insurance_type == \"TRADE_CREDIT\"` AND `b2b_receivables == true`","_legal_basis":"Art. 22 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.voluntary.inventory_theft — Ubezpieczenie od kradzieży zapasów — KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.voluntary.inventory_theft","package":"jdg.hyper.deadlines","priority":1632,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`insurance_type == \"THEFT\"` AND `has_inventory == true`","_legal_basis":"Art. 22 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.gap.detection_mandatory_missing — Brak obowiązkowego OC → kara + odpowiedzialność osobista
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.gap.detection_mandatory_missing","package":"jdg.hyper.deadlines","priority":1633,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`mandatory_oc_required == true` AND `policy_active == false`","_legal_basis":"Ustawy branżowe","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.gap.detection_sum_insufficient — Suma ubezpieczenia poniżej wymaganego minimum
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.gap.detection_sum_insufficient","package":"jdg.hyper.deadlines","priority":1634,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`mandatory_oc_required == true` AND `sum_insured < legal_minimum`","_legal_basis":"Ustawy branżowe","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.gap.detection_policy_expiring — Polisa wygasająca — alert o odnowieniu
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.gap.detection_policy_expiring","package":"jdg.hyper.deadlines","priority":1635,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`policy_expiry_date - today() < 30_days`","_legal_basis":"—","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.crypto.receiving_as_payment — Przyjęcie krypto jako zapłaty za fakturę — moment przychodu
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.crypto.receiving_as_payment","package":"jdg.hyper.deadlines","priority":1636,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"CRYPTO\"` AND `direction == \"SALE\"`","_legal_basis":"Art. 14 ust. 1 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.crypto.vat_obligation_on_receipt — VAT od zapłaty w krypto — obowiązek w dacie otrzymania
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.crypto.vat_obligation_on_receipt","package":"jdg.hyper.deadlines","priority":1637,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"CRYPTO\"` AND `direction == \"SALE\"`","_legal_basis":"Art. 19a ust. 8 VAT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.crypto.exchange_rate_determination — Kurs krypto/PLN — notowania giełdowe (nie NBP)
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.crypto.exchange_rate_determination","package":"jdg.hyper.deadlines","priority":1638,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"CRYPTO\"`","_legal_basis":"Art. 14 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.crypto.volatility_risk_warning — Ostrzeżenie o zmienności kursu krypto
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.crypto.volatility_risk_warning","package":"jdg.hyper.deadlines","priority":1639,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"CRYPTO\"` AND `crypto_volatility_index > threshold`","_legal_basis":"—","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.crypto.difference_from_crypto_trading — Odróżnienie zapłaty krypto od tradingu krypto
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.crypto.difference_from_crypto_trading","package":"jdg.hyper.deadlines","priority":1640,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_purpose == \"PAYMENT_FOR_GOODS\"` (≠ \"INVESTMENT\")","_legal_basis":"Art. 14 vs Art. 17 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.barter.double_supply — Barter — dwie dostawy (towar za usługę)
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.barter.double_supply","package":"jdg.hyper.deadlines","priority":1641,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"BARTER\"`","_legal_basis":"Art. 7, Art. 8 VAT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.barter.vat_on_both_sides — VAT od barteru — każda strona odprowadza VAT od swojego świadczenia
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.barter.vat_on_both_sides","package":"jdg.hyper.deadlines","priority":1642,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"BARTER\"`","_legal_basis":"Art. 5 VAT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.barter.market_value_as_base — Podstawa opodatkowania: wartość rynkowa wymienianych świadczeń
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.barter.market_value_as_base","package":"jdg.hyper.deadlines","priority":1643,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"BARTER\"`","_legal_basis":"Art. 29a VAT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.barter.pit_revenue_recognition — Przychód w PIT z barteru — data wymiany
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.barter.pit_revenue_recognition","package":"jdg.hyper.deadlines","priority":1644,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"BARTER\"`","_legal_basis":"Art. 14 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.barter.documentation_requirements — Dokumentacja barteru: umowa + faktury + wycena rynkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.barter.documentation_requirements","package":"jdg.hyper.deadlines","priority":1645,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"BARTER\"`","_legal_basis":"Art. 22 UoR","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.offset.when_recognized — Kompensata — uznanie za zapłatę w dacie potrącenia
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.offset.when_recognized","package":"jdg.hyper.deadlines","priority":1646,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"OFFSET\"`","_legal_basis":"Art. 498 KC + Art. 14 PIT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.offset.vat_cash_method — Kompensata przy metodzie kasowej VAT — data potrącenia = data zapłaty
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.offset.vat_cash_method","package":"jdg.hyper.deadlines","priority":1647,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"OFFSET\"` AND `vat_method == \"CASH\"`","_legal_basis":"Art. 21 VAT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.offset.vat_accrual_method — Kompensata przy metodzie memoriałowej VAT — obowiązek w dacie dostawy
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.offset.vat_accrual_method","package":"jdg.hyper.deadlines","priority":1648,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"OFFSET\"` AND `vat_method == \"ACCRUAL\"`","_legal_basis":"Art. 19a VAT","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.offset.mutual_agreement_required — Kompensata wymaga zgody obu stron (oświadczenie o potrąceniu)
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.offset.mutual_agreement_required","package":"jdg.hyper.deadlines","priority":1649,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"OFFSET\"`","_legal_basis":"Art. 498-499 KC","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.offset.documentation_required — Dokumentacja kompensaty: nota kompensacyjna + umowa
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.offset.documentation_required","package":"jdg.hyper.deadlines","priority":1650,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`payment_method == \"OFFSET\"`","_legal_basis":"Art. 22 UoR","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# ══ L-DL-1 Fix: Tax Deadlines (P23 P0) — R1651-R1665 ══
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.vat_jpk_v7m_25th","package":"jdg.hyper.deadlines","priority":1651,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"JPK_V7M: 25. dzień miesiąca","_legal_basis":"Art. 109 ust. 3c VAT","_warnings":["JPK_V7M — termin: 25. dzień miesiąca za poprzedni miesiąc. Przesunięcie na następny dzień roboczy wg Art. 12 § 5 OrdPU"]} if {
    object.get(input.jdg_entrepreneur, "is_vat_payer", false) == true
    object.get(input.jdg_entrepreneur, "current_day", 0) >= 20
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.vat7_quarterly_25th","package":"jdg.hyper.deadlines","priority":1652,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"VAT-7K: 25. dzień po kwartale","_legal_basis":"Art. 99 ust. 2 VAT","_warnings":["Deklaracja VAT-7K (kwartalna) — termin: 25. dzień miesiąca po zakończeniu kwartału"]} if {
    object.get(input.jdg_entrepreneur, "vat_filing_period", "") == "QUARTERLY"
    object.get(input.jdg_entrepreneur, "quarter_end", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.pit_advance_20th","package":"jdg.hyper.deadlines","priority":1653,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zaliczka PIT: 20. dzień miesiąca","_legal_basis":"Art. 44 ust. 6 PIT","_warnings":["Zaliczka PIT (PIT-5/PIT-28) — termin: 20. dzień miesiąca za poprzedni miesiąc. Przesunięcie na następny dzień roboczy wg Art. 12 § 5 OrdPU"]} if {
    object.get(input.jdg_entrepreneur, "current_day", 0) >= 15
    object.get(input.jdg_entrepreneur, "current_day", 0) <= 20
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.pit_annual_april30","package":"jdg.hyper.deadlines","priority":1654,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"PIT roczny: 30.04","_legal_basis":"Art. 45 ust. 1 PIT","_warnings":["PIT-36/PIT-28 roczny — termin: 30 kwietnia roku następnego. Nie przegap — kara za spóźnienie!"]} if {
    object.get(input.jdg_entrepreneur, "current_month", 0) == 3
    object.get(input.jdg_entrepreneur, "current_day", 0) >= 25
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.zus_dra_10th","package":"jdg.hyper.deadlines","priority":1655,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"ZUS DRA: 10. dzień","_legal_basis":"Art. 47 u.s.u.s.","_warnings":["Deklaracja ZUS DRA — termin: 10. dzień miesiąca za poprzedni miesiąc"]} if {
    object.get(input.jdg_entrepreneur, "current_day", 0) >= 8
    object.get(input.jdg_entrepreneur, "current_day", 0) <= 10
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.zus_contributions_15th_20th","package":"jdg.hyper.deadlines","priority":1656,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Składki ZUS: 15. (korekta) / 20.","_legal_basis":"Art. 47 ust. 1-3 u.s.u.s.","_warnings":["Składki ZUS — korekty DRA: 15. dzień, pozostałe składki: 20. dzień miesiąca"]} if {
    object.get(input.jdg_entrepreneur, "current_day", 0) >= 14
    object.get(input.jdg_entrepreneur, "current_day", 0) <= 20
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.cit8_march31","package":"jdg.hyper.deadlines","priority":1657,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"CIT-8: 31.03 (JDG na CIT)","_legal_basis":"Art. 27 ust. 1 CIT","_warnings":["CIT-8 roczny (JDG na CIT) — termin: 31 marca roku następnego"]} if {
    object.get(input.jdg_entrepreneur, "tax_regime", "") == "CIT"
    object.get(input.jdg_entrepreneur, "current_month", 0) == 3
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.holiday_shift_art12p5_ordpu","package":"jdg.hyper.deadlines","priority":1658,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przesunięcie terminu na dzień roboczy (Art. 12 § 5)","_legal_basis":"Art. 12 § 5 OrdPU","_warnings":["Gdy termin podatkowy przypada w sobotę, niedzielę lub święto — przesuwa się na następny dzień roboczy (Art. 12 § 5 OrdPU)"]} if {
    object.get(input.jdg_entrepreneur, "deadline_is_weekend_or_holiday", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.ksef_invoice_immediately_2026","package":"jdg.hyper.deadlines","priority":1659,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"KSeF: faktura niezwłocznie (od 02.2026)","_legal_basis":"Art. 106na-106nb VAT","_warnings":["KSeF obowiązkowy od 01.02.2026 — faktura B2B musi być wystawiona w KSeF niezwłocznie po dostawie"]} if {
    object.get(input.jdg_entrepreneur, "ksef_obligatory", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.appeal_14days","package":"jdg.hyper.deadlines","priority":1660,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Odwołanie: 14 dni","_legal_basis":"Art. 223 § 1 OrdPU","_warnings":["Odwołanie od decyzji podatkowej — termin: 14 dni od doręczenia. Nie przegap!"]} if {
    object.get(input.document, "appeal_deadline_days", 99) <= 14
    object.get(input.document, "appeal_deadline_days", 99) > 0
}

# ══ L-DL-1 Complete: Additional Tax Deadlines R1661-R1665 ══
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.jpk_on_demand_7days","package":"jdg.hyper.deadlines","priority":1661,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"JPK na żądanie: 7 dni","_legal_basis":"Art. 193a OrdPU","_warnings":["JPK na żądanie organu — termin: 7 dni od doręczenia żądania. Niezłożenie = kara porządkowa"]} if {
    object.get(input.document, "jpk_demand_received", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.complaint_7days","package":"jdg.hyper.deadlines","priority":1662,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Zażalenie: 7 dni","_legal_basis":"Art. 220 § 1 OrdPU","_warnings":["Zażalenie na postanowienie — termin: 7 dni od doręczenia"]} if {
    object.get(input.document, "complaint_deadline_days", 99) <= 7
    object.get(input.document, "complaint_deadline_days", 99) > 0
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.interpretation_3months","package":"jdg.hyper.deadlines","priority":1663,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Interpretacja indywidualna: 3 mies.","_legal_basis":"Art. 14c § 1 OrdPU","_warnings":["Wniosek o interpretację indywidualną — organ ma 3 miesiące na odpowiedź. Po terminie: milcząca zgoda na stanowisko wnioskodawcy"]} if {
    object.get(input.jdg_entrepreneur, "interpretation_requested", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.ksef_appeal_30days","package":"jdg.hyper.deadlines","priority":1664,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"KSeF: odwołanie od decyzji 30 dni","_legal_basis":"Art. 106n ust. 6 VAT","_warnings":["Odwołanie od decyzji KSeF o karze — termin: 30 dni. Złożenie faktury w KSeF w terminie 14 dni od terminu = redukcja kary o 50%"]} if {
    object.get(input.jdg_entrepreneur, "ksef_penalty_appeal_due", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.edelivery_pickup_14days","package":"jdg.hyper.deadlines","priority":1665,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"e-Doręczenia: odbiór 14 dni","_legal_basis":"Ustawa o doręczeniach el.","_warnings":["e-Doręczenia — odbiór pisma w ciągu 14 dni od umieszczenia w BAE. Po 14 dniach: FIKCJA DORĘCZENIA — bieg terminów prawnych!"]} if {
    object.get(input.document, "edelivery_unread_days", 0) >= 10
}
