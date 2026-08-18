# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.seasonal hyper-granularity (Doc 45: R1518-R1545)
# Atom rules: detection, suspension vs closure, ZUS, PIT, VAT, aggregate
# Rules: 28 atom — each with differentiated trigger conditions
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.seasonal.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.seasonal.hyper.no_match","package":"jdg.seasonal.hyper","priority":99999}

# ══ R1518-R1522: Seasonal Detection ══
decide := {"matched":true,"rule_id":"jdg.seasonal.hyper.detection_months_with_revenue","package":"jdg.seasonal.hyper","priority":1518,"_routing":"","_routing_reason":"Sezonowa: aktywność ≤9 miesięcy","_legal_basis":"Art. 22 PP","_warnings":["JDG sezonowa — przychody w ≤9 miesiącach roku, wzorzec powtarzalny"]} {
    object.get(input.jdg_entrepreneur, "months_with_revenue", 12) <= 9
    object.get(input.jdg_entrepreneur, "pattern_repeatable", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.detection_3plus_months_gap","package":"jdg.seasonal.hyper","priority":1519,"_routing":"","_routing_reason":"Sezonowa: przerwa ≥3 mies.","_legal_basis":"Art. 22 PP","_warnings":["Przerwa w przychodach ≥3 miesiące rocznie — rozważ strategię sezonową"]} {
    object.get(input.jdg_entrepreneur, "revenue_gap_months", 0) >= 3
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.detection_tourism","package":"jdg.seasonal.hyper","priority":1520,"_routing":"","_routing_reason":"Sezonowa: branża turystyczna","_legal_basis":"Art. 22 PP","_warnings":["Branża turystyczna — domniemanie sezonowości. Rozważ zawieszenie poza sezonem"]} {
    object.get(input.jdg_entrepreneur, "pkd_main", "") == "55.10.Z"
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.detection_agriculture","package":"jdg.seasonal.hyper","priority":1521,"_routing":"","_routing_reason":"Sezonowa: branża rolna","_legal_basis":"Art. 22 PP","_warnings":["Branża rolna — domniemanie sezonowości, dostosuj strategię podatkową"]} {
    object.get(input.jdg_entrepreneur, "pkd_main", "") == "01.11.Z"
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.detection_construction_winter","package":"jdg.seasonal.hyper","priority":1522,"_routing":"","_routing_reason":"Sezonowa: budowlanka — przerwa zimowa","_legal_basis":"Art. 22 PP","_warnings":["Budowlanka — przerwa zimowa (XII-II). Rozważ zawieszenie na zimę"]} {
    object.get(input.jdg_entrepreneur, "winter_break", false) == true
}

# ══ R1523-R1527: Suspension vs Closure ══
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.suspension_keep_nip","package":"jdg.seasonal.hyper","priority":1523,"_routing":"","_routing_reason":"Zawieszenie zamiast zamknięcia","_legal_basis":"Art. 22 PP","_warnings":["Zawieś JDG zamiast zamykać — zachowasz NIP, REGON i ciągłość działalności"]} {
    object.get(input.jdg_entrepreneur, "prefers_suspension_over_closure", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.suspension_max_24_months_total","package":"jdg.seasonal.hyper","priority":1524,"_routing":"WARNING","_routing_reason":"Zawieszenie: max 24 mies. łącznie (Art. 22 PP)","_legal_basis":"Art. 22 PP","_warnings":["Zawieszenie — max 24 miesiące łącznie (Art. 22 PP). Przy dłuższym zawieszeniu rozważ zamknięcie ze względu na składkę zdrowotną. Uwaga: składka zdrowotna NADAL należna w zawieszeniu."]} {
    object.get(input.jdg_entrepreneur, "suspension_months_total", 0) >= 24
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.closure_nip_loss","package":"jdg.seasonal.hyper","priority":1525,"_routing":"WARNING","_routing_reason":"Zamknięcie: utrata NIP","_legal_basis":"Art. 30 CEIDG","_warnings":["Zamknięcie JDG = utrata NIP. Ponowne otwarcie wymaga nowej rejestracji CEIDG"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "CLOSED"
    object.get(input.jdg_entrepreneur, "plans_to_reopen", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.reopening_zus_new_application","package":"jdg.seasonal.hyper","priority":1526,"_routing":"WARNING","_routing_reason":"Ponowne otwarcie: nowy ZUS ZUA","_legal_basis":"Art. 36 SUS","_warnings":["Ponowne otwarcie JDG — złóż ZUS ZUA w ciągu 7 dni"]} {
    object.get(input.jdg_entrepreneur, "reopening_jdg", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.reopening_vat_r_new","package":"jdg.seasonal.hyper","priority":1527,"_routing":"WARNING","_routing_reason":"Ponowne otwarcie: nowy VAT-R","_legal_basis":"Art. 96 VAT","_warnings":["Ponowne otwarcie — złóż VAT-R jeśli chcesz być czynnym podatnikiem VAT"]} {
    object.get(input.jdg_entrepreneur, "reopening_jdg", false) == true
    object.get(input.jdg_entrepreneur, "wants_vat_payer", false) == true
}

# ══ R1528-R1532: ZUS Seasonality ══
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.zus_suspension_no_social","package":"jdg.seasonal.hyper","priority":1528,"_routing":"","_routing_reason":"ZUS: zawieszenie → brak społecznych","_legal_basis":"Art. 36a SUS","_warnings":["Zawieszenie — brak składek społecznych. Składka zdrowotna NADAL należna!"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "SUSPENDED"
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.zus_suspension_health_still_due","package":"jdg.seasonal.hyper","priority":1529,"_routing":"WARNING","_routing_reason":"ZUS: zdrowotna w zawieszeniu","_legal_basis":"Art. 36a SUS","_warnings":["Mimo zawieszenia — składka zdrowotna jest nadal obowiązkowa!"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "SUSPENDED"
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.zus_closure_no_contributions","package":"jdg.seasonal.hyper","priority":1530,"_routing":"","_routing_reason":"ZUS: zamknięcie → cały ZUS zniesiony","_legal_basis":"Art. 6 SUS","_warnings":["Zamknięcie JDG — całkowity brak obowiązku ZUS"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "CLOSED"
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.zus_health_tier_seasonal","package":"jdg.seasonal.hyper","priority":1531,"_routing":"","_routing_reason":"Składka zdrowotna — dochód sezonowy","_legal_basis":"Art. 81 ust. 2e u.ś.o.z.","_warnings":["Składka zdrowotna liczona od rzeczywistego dochodu (nie przychodu w miesiącach bez przychodu)"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "LUMP_SUM"
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.zus_maly_plus_revenue_test","package":"jdg.seasonal.hyper","priority":1532,"_routing":"","_routing_reason":"Mały ZUS Plus: test przychodu","_legal_basis":"Art. 18c SUS","_warnings":["Mały ZUS Plus — limit przychodu 120k PLN z poprzedniego roku"]} {
    object.get(input.jdg_entrepreneur, "zus_status", "") == "MALY_ZUS_PLUS"
}

# ══ R1533-R1537: PIT Seasonality ══
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.pit_scale_active_months_only","package":"jdg.seasonal.hyper","priority":1533,"_routing":"","_routing_reason":"Skala: dochód tylko za aktywne miesiące","_legal_basis":"Art. 27 PIT","_warnings":["Dochód roczny = suma z aktywnych miesięcy. Składki tylko za te miesiące"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.pit_advances_simplified_recommendation","package":"jdg.seasonal.hyper","priority":1534,"_routing":"","_routing_reason":"Zaliczki uproszczone — zalecane","_legal_basis":"Art. 44 ust. 6b PIT","_warnings":["JDG sezonowa — zaliczki uproszczone: stała kwota miesięczna, brak wahań"]} {
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
    object.get(input.jdg_entrepreneur, "previous_year_tax", 0) > 0
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.pit_zero_advances_no_income","package":"jdg.seasonal.hyper","priority":1535,"_routing":"","_routing_reason":"Zaliczka 0 w miesiącach bez przychodu","_legal_basis":"Art. 44 ust. 3 PIT","_warnings":["W miesiącach bez przychodu zaliczka PIT = 0 PLN (metoda zwykła)"]} {
    object.get(input.jdg_entrepreneur, "monthly_income", 0) == 0
    object.get(input.jdg_entrepreneur, "advance_method", "") != "SIMPLIFIED"
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.pit_lump_sum_annual","package":"jdg.seasonal.hyper","priority":1536,"_routing":"","_routing_reason":"Ryczałt — podatek od całorocznego przychodu","_legal_basis":"Art. 12 ust. 1 u.z.p.d.","_warnings":["Ryczałt — podatek liczony od sumy przychodów z aktywnych miesięcy"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "LUMP_SUM"
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.pit_loss_carry_forward","package":"jdg.seasonal.hyper","priority":1537,"_routing":"","_routing_reason":"Strata sezonowa — 5 lat","_legal_basis":"Art. 9 ust. 3 PIT","_warnings":["Strata z JDG sezonowej — odliczenie w ciągu 5 kolejnych lat"]} {
    object.get(input.jdg_entrepreneur, "annual_tax_result", 0) < 0
}

# ══ R1538-R1542: VAT Seasonality ══
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.vat_zero_returns_suspension","package":"jdg.seasonal.hyper","priority":1538,"_routing":"","_routing_reason":"VAT: deklaracje zerowe w zawieszeniu","_legal_basis":"Art. 99 ust. 7a VAT","_warnings":["W zawieszeniu składaj zerowe JPK_V7 jeśli jesteś czynnym podatnikiem VAT"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "SUSPENDED"
    object.get(input.jdg_entrepreneur, "is_vat_payer", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.vat_exemption_proportional","package":"jdg.seasonal.hyper","priority":1539,"_routing":"","_routing_reason":"Zwolnienie VAT proporcjonalne","_legal_basis":"Art. 113 ust. 9 VAT","_warnings":["Nowa JDG sezonowa — limit zwolnienia = 200k × (dni aktywne / 365)"]} {
    object.get(input.jdg_entrepreneur, "first_year", false) == true
    object.get(input.jdg_entrepreneur, "vat_exempt", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.vat_exemption_breach_mid_season","package":"jdg.seasonal.hyper","priority":1540,"_routing":"WARNING","_routing_reason":"Przekroczenie 200k w sezonie","_legal_basis":"Art. 113 ust. 5 VAT","_warnings":["Przekroczenie 200k PLN w trakcie sezonu — VAT od nadwyżki, rejestracja VAT-R"]} {
    object.get(input.jdg_entrepreneur, "cumulative_revenue", 0) > 200000
    object.get(input.jdg_entrepreneur, "vat_exempt", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.vat_margin_scheme_seasonal","package":"jdg.seasonal.hyper","priority":1541,"_routing":"","_routing_reason":"VAT marża dla towarów sezonowych","_legal_basis":"Art. 120 VAT","_warnings":["Procedura VAT marża dla towarów sezonowych — sprawdź warunki"]} {
    object.get(input.invoice, "procedure", "") == "MARGIN"
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.vat_maintenance_costs_deduction","package":"jdg.seasonal.hyper","priority":1542,"_routing":"","_routing_reason":"VAT od kosztów stałych w zawieszeniu","_legal_basis":"Art. 86 VAT","_warnings":["Koszty stałe w zawieszeniu (czynsz, monitoring) — VAT odliczalny jeśli czynny podatnik"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "SUSPENDED"
    object.get(input.invoice, "expense_type", "") == "MAINTENANCE"
}

# ══ R1543-R1545: Aggregate ══
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.aggregate_annual_summary","package":"jdg.seasonal.hyper","priority":1543,"_routing":"","_routing_reason":"Podsumowanie roczne sezonowej JDG","_legal_basis":"—","_warnings":["Roczne podsumowanie: PIT, ZUS, VAT — tylko za aktywne miesiące"]} {
    object.get(input.jdg_entrepreneur, "year_end", false) == true
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.aggregate_suspend_vs_close","package":"jdg.seasonal.hyper","priority":1544,"_routing":"","_routing_reason":"Porównanie: zawiesić czy zamknąć","_legal_basis":"—","_warnings":["Porównanie kosztów: zawieszenie (składka zdrowotna) vs zamknięcie i ponowne otwarcie"]} {
    object.get(input.jdg_entrepreneur, "suspend_vs_close_analysis", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.aggregate_optimal_strategy","package":"jdg.seasonal.hyper","priority":1545,"_routing":"","_routing_reason":"Optymalna strategia sezonowa","_legal_basis":"—","_warnings":["Rekomendacja: [SUSPEND/CLOSE_AND_REOPEN] — na podstawie analizy kosztów"]} {
    object.get(input.jdg_entrepreneur, "optimal_strategy_ready", false) == true
}
