# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 33

package jdg.hyper.limits

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.hyper.limits.no_match","package":"jdg.hyper.limits","priority":99999}

# jdg.hyper.limits.seasonal.detection.months_with_revenue — Identyfikacja JDG sezonowej
decide :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.detection.months_with_revenue","_legal_basis":"Art. 22 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.detection.revenue_gap_3plus_months — Przerwa w przychodach ≥3 miesiące
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.detection.revenue_gap_3plus_months","_legal_basis":"Art. 22 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.detection.industry_code_tourism — Branża turystyczna — domniemanie sezonowości
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.detection.industry_code_tourism","_legal_basis":"Art. 22 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.detection.industry_code_agriculture — Branża rolna — domniemanie sezonowości
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.detection.industry_code_agriculture","_legal_basis":"Art. 22 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.detection.construction_winter_break — Budowlanka — przerwa zimowa
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.detection.construction_winter_break","_legal_basis":"Art. 22 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.suspension.keep_nip — Zawieszenie zamiast zamykania — zachowanie NIP
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.suspension.keep_nip","_legal_basis":"Art. 22 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.suspension.max_24_months_total — Zawieszenie max 24 mies. łącznie (R-SEAS-1 fix)
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.suspension.max_24_months_total","_legal_basis":"Art. 22 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123) (max 24 mies. łącznie)","_warnings":["Zawieszenie — max 24 miesiące łącznie (Art. 22 PP). Przy dłuższym zawieszeniu rozważ zamknięcie ze względu na składkę zdrowotną"]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.closure.nip_loss_consequences — Skutki zamknięcia sezonowego — utrata NIP, ponowna rejestracja
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.closure.nip_loss_consequences","_legal_basis":"Art. 30 ustawy z dnia 6 marca 2018 r. o Centralnej Ewidencji i Informacji o Działalności Gospodarczej i Punkcie Informacji dla Przedsiębiorcy (Dz.U. 2025 poz. 456)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.closure.reopening_zus_new_application — Zamknięcie → ponowne otwarcie → nowe zgłoszenie ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.closure.reopening_zus_new_application","_legal_basis":"Art. 36 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.closure.vat_r_new_application — Zamknięcie → ponowne otwarcie → nowy VAT-R
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.closure.vat_r_new_application","_legal_basis":"Art. 96 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.zus.suspension_no_social — Zawieszenie sezonowe → brak składek społecznych
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.zus.suspension_no_social","_legal_basis":"Art. 36a ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.zus.suspension_health_still_due — Zawieszenie → składka zdrowotna NADAL należna
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.zus.suspension_health_still_due","_legal_basis":"Art. 36a ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.zus.closure_no_contributions — Zamknięcie JDG → całkowity brak ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.zus.closure_no_contributions","_legal_basis":"Art. 6 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.zus.annual_health_tier_lockstep — Składka zdrowotna wg rzeczywistego przychodu przy sezonowości
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.zus.annual_health_tier_lockstep","_legal_basis":"Art. 81 ust. 2e-f ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.zus.maly_plus_revenue_120k_eur_test — Mały ZUS Plus — test przychodu z poprzedniego roku sezonowego
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.zus.maly_plus_revenue_120k_eur_test","_legal_basis":"Art. 18c ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.pit.scale_annual_only_active_months — Skala PIT — dochód tylko za aktywne miesiące
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.pit.scale_annual_only_active_months","_legal_basis":"Art. 27 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.pit.advances_simplified_recommendation — Zaliczki uproszczone — rekomendowane dla JDG sezonowej
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.pit.advances_simplified_recommendation","_legal_basis":"Art. 44 ust. 6b ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.pit.advances_no_income_months_zero — Zaliczka = 0 w miesiącach bez przychodu (metoda zwykła)
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.pit.advances_no_income_months_zero","_legal_basis":"Art. 44 ust. 3 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.pit.lump_sum_annual_calculation — Ryczałt — podatek od całorocznego przychodu
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.pit.lump_sum_annual_calculation","_legal_basis":"Art. 12 ust. 1 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.pit.loss_carry_forward_5years — Strata sezonowa — odliczenie w ciągu 5 lat
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.pit.loss_carry_forward_5years","_legal_basis":"Art. 9 ust. 3 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.vat.zero_returns_in_suspension — VAT — deklaracje zerowe w zawieszeniu
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.vat.zero_returns_in_suspension","_legal_basis":"Art. 99 ust. 7a ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.vat.exemption_200k_proportion — Zwolnienie VAT — proporcjonalny limit dla nowej JDG sezonowej
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.vat.exemption_200k_proportion","_legal_basis":"Art. 113 ust. 9 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.vat.exemption_breach_mid_year — Przekroczenie limitu 200k w trakcie sezonu → VAT od nadwyżki
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.vat.exemption_breach_mid_year","_legal_basis":"Art. 113 ust. 5 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.vat.margin_scheme_seasonal_goods — Procedura marży dla towarów sezonowych
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.vat.margin_scheme_seasonal_goods","_legal_basis":"Art. 120 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.vat.deduction_maintenance_costs — VAT od kosztów stałych w zawieszeniu — odliczenie
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.vat.deduction_maintenance_costs","_legal_basis":"Art. 86 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.aggregate.annual_summary_pit_zus — Roczne podsumowanie PIT i ZUS dla JDG sezonowej
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.aggregate.annual_summary_pit_zus","_legal_basis":"Art. 44 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.), Art. 46 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.aggregate.comparison_normal_vs_seasonal — Porównanie obciążeń: czy opłaca się zawieszać zamiast zamykać
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.aggregate.comparison_normal_vs_seasonal","_legal_basis":"Art. 44 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.aggregate.optimal_strategy — Rekomendacja optymalnej strategii sezonowej
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.aggregate.optimal_strategy","_legal_basis":"Art. 44 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.kks.conviction.business_ban_art41kk — Zakaz prowadzenia działalności po skazaniu
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.kks.conviction.business_ban_art41kk","_legal_basis":"Art. 41 ustawy z dnia 6 czerwca 1997 r. — Kodeks karny","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.kks.conviction.professional_license_revocation — Utrata licencji zawodowych (doradca podatkowy, adwokat)
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.kks.conviction.professional_license_revocation","_legal_basis":"Art. 41 ustawy z dnia 6 czerwca 1997 r. — Kodeks karny, ustawy korporacyjne","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.kks.conviction.public_procurement_exclusion — Wykluczenie z zamówień publicznych
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.kks.conviction.public_procurement_exclusion","_legal_basis":"Art. 108 ustawy z dnia 11 września 2019 r. — Prawo zamówień publicznych","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.kks.conviction.eu_funds_exclusion — Wykluczenie ze środków UE
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.kks.conviction.eu_funds_exclusion","_legal_basis":"Rozp. 2018/1046","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.kks.conviction.regulated_profession_consequences — Skutki dla zawodów regulowanych — pełna lista
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.kks.conviction.regulated_profession_consequences","_legal_basis":"ustaw regulujących wykonywanie zawodów regulowanych","_warnings":[]} if {
    object.get(input.invoice, "amount_gross", 0) > 0
}
