# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 41

package jdg.hyper.deadlines

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.hyper.deadlines.no_match","package":"jdg.hyper.deadlines","priority":99999}

# jdg.hyper.deadlines.insurance.mandatory.detection_construction — OC budowlane — obowiązkowe
decide :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.mandatory.detection_construction","_legal_basis":"Art. 4 ustawy z dnia 22 maja 2003 r. o ubezpieczeniach obowiązkowych, Ubezpieczeniowym Funduszu Gwarancyjnym i Polskim Biurze Ubezpieczycieli Komunikacyjnych","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.mandatory.detection_transport — OC przewoźnika — obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.mandatory.detection_transport","_legal_basis":"ustawy z dnia 6 września 2001 r. o transporcie drogowym","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.mandatory.detection_tax_advisor — OC doradcy podatkowego — obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.mandatory.detection_tax_advisor","_legal_basis":"ustawy z dnia 5 lipca 1996 r. o doradztwie podatkowym","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.kup.mandatory_oc_premium_full — Składka OC obowiązkowego — 100% KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.kup.mandatory_oc_premium_full","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.kup.mandatory_oc_over_limit_proportion — Składka ponad minimum — proporcjonalny KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.kup.mandatory_oc_over_limit_proportion","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.kup.voluntary_oc_business — Dobrowolne OC — KUP jeśli uzasadnione biznesowo
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.kup.voluntary_oc_business","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.kup.life_insurance_limited — Ubezpieczenie na życie — ograniczone KUP (tylko składki za pracowników)
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.kup.life_insurance_limited","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.kup.property_insurance_full — Ubezpieczenie mienia firmowego — pełny KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.kup.property_insurance_full","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.claim.payout_as_revenue — Odszkodowanie z OC — przychód podatkowy
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.claim.payout_as_revenue","_legal_basis":"Art. 14 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.claim.payout_reduced_by_damage — Odszkodowanie pomniejszone o poniesioną stratę
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.claim.payout_reduced_by_damage","_legal_basis":"Art. 14 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.claim.business_interruption_taxable — Odszkodowanie za przerwę w działalności — w pełni opodatkowane
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.claim.business_interruption_taxable","_legal_basis":"Art. 14 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.claim.personal_injury_exempt — Odszkodowanie za uszczerbek na zdrowiu — zwolnione z PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.claim.personal_injury_exempt","_legal_basis":"Art. 21 ust. 1 pkt 3c ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.claim.late_payment_interest_taxable — Odsetki od opóźnionej wypłaty odszkodowania — opodatkowane
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.claim.late_payment_interest_taxable","_legal_basis":"Art. 17 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.vat.exemption_general — Usługi ubezpieczeniowe — zwolnione z VAT
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.vat.exemption_general","_legal_basis":"Art. 43 ust. 1 pkt 37 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.vat.exception_assistance_services — Usługi assistance — NIE zwolnione (23% VAT)
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.vat.exception_assistance_services","_legal_basis":"Art. 41 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.vat.exception_damage_assessment — Wycena szkód przez niezależnego eksperta — 23% VAT
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.vat.exception_damage_assessment","_legal_basis":"Art. 41 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.vat.exception_broker_services — Usługi brokera ubezpieczeniowego — 23% VAT
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.vat.exception_broker_services","_legal_basis":"Art. 41 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.vat.input_vat_deduction_blocked — VAT od wydatków na ubezpieczenia osobiste — NIE odlicza się
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.vat.input_vat_deduction_blocked","_legal_basis":"Art. 88 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.voluntary.cyber_risk — Cyber-OC — KUP (rekomendowane dla IT JDG)
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.voluntary.cyber_risk","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.voluntary.directors_officers — D&O dla JDG z prokurentami — KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.voluntary.directors_officers","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.voluntary.key_person — Ubezpieczenie kluczowej osoby (właściciela JDG)
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.voluntary.key_person","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.voluntary.trade_credit — Ubezpieczenie należności — KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.voluntary.trade_credit","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.voluntary.inventory_theft — Ubezpieczenie od kradzieży zapasów — KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.voluntary.inventory_theft","_legal_basis":"Art. 22 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.gap.detection_mandatory_missing — Brak obowiązkowego OC → kara + odpowiedzialność osobista
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.gap.detection_mandatory_missing","_legal_basis":"ustawy z dnia 22 maja 2003 r. o ubezpieczeniach obowiązkowych, Ubezpieczeniowym Funduszu Gwarancyjnym i Polskim Biurze Ubezpieczycieli Komunikacyjnych","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.gap.detection_sum_insufficient — Suma ubezpieczenia poniżej wymaganego minimum
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.gap.detection_sum_insufficient","_legal_basis":"ustawy z dnia 22 maja 2003 r. o ubezpieczeniach obowiązkowych, Ubezpieczeniowym Funduszu Gwarancyjnym i Polskim Biurze Ubezpieczycieli Komunikacyjnych","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.insurance.gap.detection_policy_expiring — Polisa wygasająca — alert o odnowieniu
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.insurance.gap.detection_policy_expiring","_legal_basis":"ustawy z dnia 22 maja 2003 r. o ubezpieczeniach obowiązkowych, Ubezpieczeniowym Funduszu Gwarancyjnym i Polskim Biurze Ubezpieczycieli Komunikacyjnych","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.crypto.receiving_as_payment — Przyjęcie krypto jako zapłaty za fakturę — moment przychodu
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.crypto.receiving_as_payment","_legal_basis":"Art. 14 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.crypto.vat_obligation_on_receipt — VAT od zapłaty w krypto — obowiązek w dacie otrzymania
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.crypto.vat_obligation_on_receipt","_legal_basis":"Art. 19a ust. 8 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.crypto.exchange_rate_determination — Kurs krypto/PLN — notowania giełdowe (nie NBP)
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.crypto.exchange_rate_determination","_legal_basis":"Art. 14 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.crypto.volatility_risk_warning — Ostrzeżenie o zmienności kursu krypto
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.crypto.volatility_risk_warning","_legal_basis":"ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.crypto.difference_from_crypto_trading — Odróżnienie zapłaty krypto od tradingu krypto
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.crypto.difference_from_crypto_trading","_legal_basis":"Art. 14 vs Art. 17 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.barter.double_supply — Barter — dwie dostawy (towar za usługę)
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.barter.double_supply","_legal_basis":"Art. 7, Art. 8 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.barter.vat_on_both_sides — VAT od barteru — każda strona odprowadza VAT od swojego świadczenia
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.barter.vat_on_both_sides","_legal_basis":"Art. 5 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.barter.market_value_as_base — Podstawa opodatkowania: wartość rynkowa wymienianych świadczeń
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.barter.market_value_as_base","_legal_basis":"Art. 29a ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.barter.pit_revenue_recognition — Przychód w PIT z barteru — data wymiany
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.barter.pit_revenue_recognition","_legal_basis":"Art. 14 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.barter.documentation_requirements — Dokumentacja barteru: umowa + faktury + wycena rynkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.barter.documentation_requirements","_legal_basis":"Art. 22 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.offset.when_recognized — Kompensata — uznanie za zapłatę w dacie potrącenia
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.offset.when_recognized","_legal_basis":"Art. 498 ustawy z dnia 23 kwietnia 1964 r. — Kodeks cywilny, Art. 14 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.offset.vat_cash_method — Kompensata przy metodzie kasowej VAT — data potrącenia = data zapłaty
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.offset.vat_cash_method","_legal_basis":"Art. 21 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.offset.vat_accrual_method — Kompensata przy metodzie memoriałowej VAT — obowiązek w dacie dostawy
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.offset.vat_accrual_method","_legal_basis":"Art. 19a ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.offset.mutual_agreement_required — Kompensata wymaga zgody obu stron (oświadczenie o potrąceniu)
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.offset.mutual_agreement_required","_legal_basis":"Art. 498-499 ustawy z dnia 23 kwietnia 1964 r. — Kodeks cywilny","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# jdg.hyper.deadlines.payment.offset.documentation_required — Dokumentacja kompensaty: nota kompensacyjna + umowa
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.payment.offset.documentation_required","_legal_basis":"Art. 22 ustawy z dnia 29 września 1994 r. o rachunkowości (Dz.U. 2025 poz. 567, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}

# ══ L-DL-1 Fix: Tax Deadlines (P23 P0) — R1651-R1665 ══
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.vat_jpk_v7m_25th","_legal_basis":"Art. 109 ust. 3c ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["JPK_V7M — termin: 25. dzień miesiąca za poprzedni miesiąc. Przesunięcie na następny dzień roboczy wg Art. 12 § 5 OrdPU"]} if {
    object.get(input.jdg_entrepreneur, "is_vat_payer", false) == true
    object.get(input.jdg_entrepreneur, "current_day", 0) >= 20
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.vat7_quarterly_25th","_legal_basis":"Art. 99 ust. 2 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Deklaracja VAT-7K (kwartalna) — termin: 25. dzień miesiąca po zakończeniu kwartału"]} if {
    object.get(input.jdg_entrepreneur, "vat_filing_period", "") == "QUARTERLY"
    object.get(input.jdg_entrepreneur, "quarter_end", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.pit_advance_20th","_legal_basis":"Art. 44 ust. 6 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Zaliczka PIT (PIT-5/PIT-28) — termin: 20. dzień miesiąca za poprzedni miesiąc. Przesunięcie na następny dzień roboczy wg Art. 12 § 5 OrdPU"]} if {
    object.get(input.jdg_entrepreneur, "current_day", 0) >= 15
    object.get(input.jdg_entrepreneur, "current_day", 0) <= 20
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.pit_annual_april30","_legal_basis":"Art. 45 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["PIT-36/PIT-28 roczny — termin: 30 kwietnia roku następnego. Nie przegap — kara za spóźnienie!"]} if {
    object.get(input.jdg_entrepreneur, "current_month", 0) == 3
    object.get(input.jdg_entrepreneur, "current_day", 0) >= 25
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.zus_dra_10th","_legal_basis":"Art. 47 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":["Deklaracja ZUS DRA — termin: 10. dzień miesiąca za poprzedni miesiąc"]} if {
    object.get(input.jdg_entrepreneur, "current_day", 0) >= 8
    object.get(input.jdg_entrepreneur, "current_day", 0) <= 10
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.zus_contributions_15th_20th","_legal_basis":"Art. 47 ust. 1-3 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":["Składki ZUS — korekty DRA: 15. dzień, pozostałe składki: 20. dzień miesiąca"]} if {
    object.get(input.jdg_entrepreneur, "current_day", 0) >= 14
    object.get(input.jdg_entrepreneur, "current_day", 0) <= 20
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.cit8_march31","_legal_basis":"Art. 27 ust. 1 ustawy z dnia 15 lutego 1992 r. o podatku dochodowym od osób prawnych","_warnings":["CIT-8 roczny (JDG na CIT) — termin: 31 marca roku następnego"]} if {
    object.get(input.jdg_entrepreneur, "tax_regime", "") == "CIT"
    object.get(input.jdg_entrepreneur, "current_month", 0) == 3
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.holiday_shift_art12p5_ordpu","_legal_basis":"Art. 12 § 5 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Gdy termin podatkowy przypada w sobotę, niedzielę lub święto — przesuwa się na następny dzień roboczy (Art. 12 § 5 OrdPU)"]} if {
    object.get(input.jdg_entrepreneur, "deadline_is_weekend_or_holiday", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.ksef_invoice_immediately_2026","_legal_basis":"Art. 106na-106nb ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["KSeF obowiązkowy od 01.02.2026 — faktura B2B musi być wystawiona w KSeF niezwłocznie po dostawie"]} if {
    object.get(input.jdg_entrepreneur, "ksef_obligatory", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.appeal_14days","_legal_basis":"Art. 223 § 1 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Odwołanie od decyzji podatkowej — termin: 14 dni od doręczenia. Nie przegap!"]} if {
    object.get(input.document, "appeal_deadline_days", 99) <= 14
    object.get(input.document, "appeal_deadline_days", 99) > 0
}

# ══ L-DL-1 Complete: Additional Tax Deadlines R1661-R1665 ══
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.jpk_on_demand_7days","_legal_basis":"Art. 193a Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["JPK na żądanie organu — termin: 7 dni od doręczenia żądania. Niezłożenie = kara porządkowa"]} if {
    object.get(input.document, "jpk_demand_received", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.complaint_7days","_legal_basis":"Art. 220 § 1 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Zażalenie na postanowienie — termin: 7 dni od doręczenia"]} if {
    object.get(input.document, "complaint_deadline_days", 99) <= 7
    object.get(input.document, "complaint_deadline_days", 99) > 0
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.interpretation_3months","_legal_basis":"Art. 14c § 1 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Wniosek o interpretację indywidualną — organ ma 3 miesiące na odpowiedź. Po terminie: milcząca zgoda na stanowisko wnioskodawcy"]} if {
    object.get(input.jdg_entrepreneur, "interpretation_requested", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.ksef_appeal_30days","_legal_basis":"Art. 106n ust. 6 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Odwołanie od decyzji KSeF o karze — termin: 30 dni. Złożenie faktury w KSeF w terminie 14 dni od terminu = redukcja kary o 50%"]} if {
    object.get(input.jdg_entrepreneur, "ksef_penalty_appeal_due", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.deadlines.tax.edelivery_pickup_14days","_legal_basis":"Art. 144b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["e-Doręczenia — odbiór pisma w ciągu 14 dni od umieszczenia w BAE. Po 14 dniach: FIKCJA DORĘCZENIA — bieg terminów prawnych!"]} if {
    object.get(input.document, "edelivery_unread_days", 0) >= 10
}
