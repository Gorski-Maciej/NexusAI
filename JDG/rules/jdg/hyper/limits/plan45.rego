# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 33

package jdg.hyper.limits

default decide := {"matched":false,"rule_id":"jdg.hyper.limits.no_match","package":"jdg.hyper.limits","priority":99999}

# jdg.hyper.limits.seasonal.detection.months_with_revenue — Identyfikacja JDG sezonowej
decide :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.detection.months_with_revenue","package":"jdg.hyper.limits","priority":1518,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`months_with_revenue` ≤ 9 AND wzorzec powtarzalny w 2+ latach","_legal_basis":"Art. 22 PP","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.detection.revenue_gap_3plus_months — Przerwa w przychodach ≥3 miesiące
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.detection.revenue_gap_3plus_months","package":"jdg.hyper.limits","priority":1519,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`revenue_gap_months` ≥ 3 AND `gap_annual_repeat` == true","_legal_basis":"Art. 22 PP","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.detection.industry_code_tourism — Branża turystyczna — domniemanie sezonowości
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.detection.industry_code_tourism","package":"jdg.hyper.limits","priority":1520,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`pkd_main` ∈ ["55.10.Z", "55.20.Z", "79.11.A", "79.12.Z"]","_legal_basis":"Art. 22 PP","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.detection.industry_code_agriculture — Branża rolna — domniemanie sezonowości
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.detection.industry_code_agriculture","package":"jdg.hyper.limits","priority":1521,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`pkd_main` ∈ ["01.11.Z"–"01.63.Z"]","_legal_basis":"Art. 22 PP","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.detection.construction_winter_break — Budowlanka — przerwa zimowa
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.detection.construction_winter_break","package":"jdg.hyper.limits","priority":1522,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`pkd_main` ∈ ["41.10.Z"–"43.99.Z"] AND revenue=0 w grudniu-lutym","_legal_basis":"Art. 22 PP","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.suspension.keep_nip — Zawieszenie zamiast zamykania — zachowanie NIP
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.suspension.keep_nip","package":"jdg.hyper.limits","priority":1523,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`is_seasonal == true` AND `prefers_suspension_over_closure == true`","_legal_basis":"Art. 22 PP","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.suspension.max_6_months — Limit zawieszenia — 6 mies. ciągłych
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.suspension.max_6_months","package":"jdg.hyper.limits","priority":1524,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`suspension_months_continuous` ≥ 6","_legal_basis":"Art. 22 PP","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.closure.nip_loss_consequences — Skutki zamknięcia sezonowego — utrata NIP, ponowna rejestracja
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.closure.nip_loss_consequences","package":"jdg.hyper.limits","priority":1525,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`business_status == "CLOSED"` AND `plans_to_reopen == true`","_legal_basis":"Art. 30 CEIDG","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.closure.reopening_zus_new_application — Zamknięcie → ponowne otwarcie → nowe zgłoszenie ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.closure.reopening_zus_new_application","package":"jdg.hyper.limits","priority":1526,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`business_status changed CLOSED→ACTIVE`","_legal_basis":"Art. 36 SUS","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.closure.vat_r_new_application — Zamknięcie → ponowne otwarcie → nowy VAT-R
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.closure.vat_r_new_application","package":"jdg.hyper.limits","priority":1527,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`business_status changed CLOSED→ACTIVE` AND `wants_vat_payer == true`","_legal_basis":"Art. 96 VAT","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.zus.suspension_no_social — Zawieszenie sezonowe → brak składek społecznych
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.zus.suspension_no_social","package":"jdg.hyper.limits","priority":1528,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`business_status == "SUSPENDED"`","_legal_basis":"Art. 36a SUS","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.zus.suspension_health_still_due — Zawieszenie → składka zdrowotna NADAL należna
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.zus.suspension_health_still_due","package":"jdg.hyper.limits","priority":1529,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`business_status == "SUSPENDED"` AND `tax_form` in ["SCALE","LINEAR","LUMP_SUM"]","_legal_basis":"Art. 36a SUS","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.zus.closure_no_contributions — Zamknięcie JDG → całkowity brak ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.zus.closure_no_contributions","package":"jdg.hyper.limits","priority":1530,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`business_status == "CLOSED"`","_legal_basis":"Art. 6 SUS","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.zus.annual_health_tier_lockstep — Składka zdrowotna wg rzeczywistego przychodu przy sezonowości
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.zus.annual_health_tier_lockstep","package":"jdg.hyper.limits","priority":1531,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`tax_form == "LUMP_SUM"` AND `is_seasonal == true`","_legal_basis":"Art. 81 ust. 2e-f u.ś.o.z.","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.zus.maly_plus_revenue_120k_eur_test — Mały ZUS Plus — test przychodu z poprzedniego roku sezonowego
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.zus.maly_plus_revenue_120k_eur_test","package":"jdg.hyper.limits","priority":1532,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`zus_status == "MALY_ZUS_PLUS"` AND `previous_year_revenue` ≤ 120k PLN","_legal_basis":"Art. 18c SUS","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.pit.scale_annual_only_active_months — Skala PIT — dochód tylko za aktywne miesiące
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.pit.scale_annual_only_active_months","package":"jdg.hyper.limits","priority":1533,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`tax_form == "PIT_SCALE"` AND `is_seasonal == true`","_legal_basis":"Art. 27 PIT","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.pit.advances_simplified_recommendation — Zaliczki uproszczone — rekomendowane dla JDG sezonowej
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.pit.advances_simplified_recommendation","package":"jdg.hyper.limits","priority":1534,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`is_seasonal == true` AND `previous_year_tax > 0`","_legal_basis":"Art. 44 ust. 6b PIT","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.pit.advances_no_income_months_zero — Zaliczka = 0 w miesiącach bez przychodu (metoda zwykła)
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.pit.advances_no_income_months_zero","package":"jdg.hyper.limits","priority":1535,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`tax_form` in ["SCALE","LINEAR"] AND `monthly_income` == 0","_legal_basis":"Art. 44 ust. 3 PIT","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.pit.lump_sum_annual_calculation — Ryczałt — podatek od całorocznego przychodu
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.pit.lump_sum_annual_calculation","package":"jdg.hyper.limits","priority":1536,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`tax_form == "LUMP_SUM"` AND `is_seasonal == true`","_legal_basis":"Art. 12 ust. 1 u.z.p.d.","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.pit.loss_carry_forward_5years — Strata sezonowa — odliczenie w ciągu 5 lat
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.pit.loss_carry_forward_5years","package":"jdg.hyper.limits","priority":1537,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`annual_tax_result < 0`","_legal_basis":"Art. 9 ust. 3 PIT","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.vat.zero_returns_in_suspension — VAT — deklaracje zerowe w zawieszeniu
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.vat.zero_returns_in_suspension","package":"jdg.hyper.limits","priority":1538,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`business_status == "SUSPENDED"` AND `is_vat_payer == true`","_legal_basis":"Art. 99 ust. 7a VAT","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.vat.exemption_200k_proportion — Zwolnienie VAT — proporcjonalny limit dla nowej JDG sezonowej
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.vat.exemption_200k_proportion","package":"jdg.hyper.limits","priority":1539,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`vat_exempt == true` AND `first_year == true`","_legal_basis":"Art. 113 ust. 9 VAT","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.vat.exemption_breach_mid_year — Przekroczenie limitu 200k w trakcie sezonu → VAT od nadwyżki
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.vat.exemption_breach_mid_year","package":"jdg.hyper.limits","priority":1540,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`cumulative_revenue > 200000` AND `vat_exempt == true`","_legal_basis":"Art. 113 ust. 5 VAT","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.vat.margin_scheme_seasonal_goods — Procedura marży dla towarów sezonowych
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.vat.margin_scheme_seasonal_goods","package":"jdg.hyper.limits","priority":1541,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`procedure == "MARGIN"` AND `goods_seasonal == true`","_legal_basis":"Art. 120 VAT","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.vat.deduction_maintenance_costs — VAT od kosztów stałych w zawieszeniu — odliczenie
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.vat.deduction_maintenance_costs","package":"jdg.hyper.limits","priority":1542,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`business_status == "SUSPENDED"` AND `expense_type == "MAINTENANCE"`","_legal_basis":"Art. 86 VAT","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.aggregate.annual_summary_pit_zus — Roczne podsumowanie PIT i ZUS dla JDG sezonowej
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.aggregate.annual_summary_pit_zus","package":"jdg.hyper.limits","priority":1543,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`is_seasonal == true` AND `year_end == true`","_legal_basis":"—","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.aggregate.comparison_normal_vs_seasonal — Porównanie obciążeń: czy opłaca się zawieszać zamiast zamykać
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.aggregate.comparison_normal_vs_seasonal","package":"jdg.hyper.limits","priority":1544,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`is_seasonal == true`","_legal_basis":"—","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.seasonal.aggregate.optimal_strategy — Rekomendacja optymalnej strategii sezonowej
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.seasonal.aggregate.optimal_strategy","package":"jdg.hyper.limits","priority":1545,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`comparison_result`","_legal_basis":"—","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.kks.conviction.business_ban_art41kk — Zakaz prowadzenia działalności po skazaniu
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.kks.conviction.business_ban_art41kk","package":"jdg.hyper.limits","priority":1546,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`kks_convicted == true` AND `sentence_includes_business_ban == true`","_legal_basis":"Art. 41 KK","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.kks.conviction.professional_license_revocation — Utrata licencji zawodowych (doradca podatkowy, adwokat)
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.kks.conviction.professional_license_revocation","package":"jdg.hyper.limits","priority":1547,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`kks_convicted == true` AND `profession in ["TAX_ADVISOR","LAWYER"]`","_legal_basis":"Art. 41 KK, ustawy korporacyjne","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.kks.conviction.public_procurement_exclusion — Wykluczenie z zamówień publicznych
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.kks.conviction.public_procurement_exclusion","package":"jdg.hyper.limits","priority":1548,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`kks_convicted == true` AND `conviction_not_spent == true`","_legal_basis":"Art. 108 PZP","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.kks.conviction.eu_funds_exclusion — Wykluczenie ze środków UE
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.kks.conviction.eu_funds_exclusion","package":"jdg.hyper.limits","priority":1549,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`kks_convicted == true` AND `fraud_related == true`","_legal_basis":"Rozp. 2018/1046","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}

# jdg.hyper.limits.kks.conviction.regulated_profession_consequences — Skutki dla zawodów regulowanych — pełna lista
else :=   {"matched":true,"rule_id":"jdg.hyper.limits.kks.conviction.regulated_profession_consequences","package":"jdg.hyper.limits","priority":1550,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`kks_convicted == true` AND `regulated_profession == true`","_legal_basis":"Ustawy branżowe","_warnings":[]} {
    object.get(input.invoice, "amount_gross", 0) > 0
}
