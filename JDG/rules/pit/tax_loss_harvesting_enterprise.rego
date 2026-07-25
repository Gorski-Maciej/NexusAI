# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE TAX LOSS HARVESTING (Art. 9 ust. 3-5 PIT)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Tax Loss Harvesting — Optymalizacja Strat Podatkowych
# description: |
#   ENTERPRISE v7.0 — Inicjatywa S8: Automatyczny optymalizator rozliczania strat.
#   Straty podatkowe można rozliczać przez 5 lat, max 50% straty rocznie.
#   Silnik optymalizuje: w których latach odliczyć jaką część straty.
#   - L160: Analiza dostępnych strat z lat ubiegłych
#   - L161: Optymalny harmonogram odliczeń (50% rocznie vs jednorazowo 5M)
#   - L162: Symulacja: "w którym roku najbardziej opłaca się odliczyć"
#   - L163: Alert o przedawniającej się stracie
#   - L164: Interakcja z innymi ulgami
# architecture: Enterprise Multi-Pass (ADR-001), First-Match-Wins else-chain
# legal_basis: Art. 9 ust. 3-5 PIT (rozliczanie strat)
# package: jdg.pit.tax_loss_harvesting
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.tax_loss_harvesting

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.pit.tax_loss.no_match",
    "package": "jdg.pit.tax_loss_harvesting", "priority": 999
}

# ═══════════════════════════════════════════════════════════════════════════════
# L160: tax_loss_inventory — Inwentaryzacja dostępnych strat
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.pit.tax_loss.inventory",
    "package": "jdg.pit.tax_loss_harvesting",
    "priority": 160,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "tax_loss_available_years": loss_years,
    "tax_loss_total_available": total_loss,
    "tax_loss_oldest_year": oldest_loss_year,
    "tax_loss_expiring_soon": expiring_loss,
    "_routing": loss_rt,
    "_routing_reason": sprintf("Straty podatkowe: %.2f PLN dostępne z %d lat. Najstarsza: %d. %s",
        [total_loss, count(loss_years), oldest_loss_year, expiring_msg]),
    "_legal_basis": "Art. 9 ust. 3-5 PIT (5 lat na rozliczenie straty)",
    "_warnings": [sprintf("📉 STRATY PODATKOWE — %.2f PLN do rozliczenia z lat: %s. %s. Maksymalnie 50%% straty rocznie. Termin: 5 lat od końca roku poniesienia straty. PO TERMINIE STRATA PRZEPADA!",
        [total_loss, concat(", ", loss_years_str), expiring_msg])]
} {
    input.tax_loss_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form in {"PIT_SCALE", "LINEAR"}

    loss_2022 := object.get(input.jdg_entrepreneur, "tax_loss_2022", 0)
    loss_2023 := object.get(input.jdg_entrepreneur, "tax_loss_2023", 0)
    loss_2024 := object.get(input.jdg_entrepreneur, "tax_loss_2024", 0)
    loss_2025 := object.get(input.jdg_entrepreneur, "tax_loss_2025", 0)
    loss_2026 := object.get(input.jdg_entrepreneur, "tax_loss_2026", 0)

    current_year := 2026
    years_map := {2022: loss_2022, 2023: loss_2023, 2024: loss_2024, 2025: loss_2025, 2026: loss_2026}
    total_loss := 0
    loss_years := []
    loss_years_str := []

    loss_years := array.concat(loss_years, [2022]) { loss_2022 > 0; current_year - 2022 < 5 }
    loss_years := array.concat(loss_years, [2023]) { loss_2023 > 0; current_year - 2023 < 5 }
    loss_years := array.concat(loss_years, [2024]) { loss_2024 > 0; current_year - 2024 < 5 }
    loss_years := array.concat(loss_years, [2025]) { loss_2025 > 0 }
    loss_years := array.concat(loss_years, [2026]) { loss_2026 > 0 }

    total_loss := loss_2022 + loss_2023 + loss_2024 + loss_2025 + loss_2026

    oldest_loss_year := 2022 { loss_2022 > 0 }
    oldest_loss_year := 2023 { loss_2023 > 0; loss_2022 == 0 }
    oldest_loss_year := 2024 { loss_2024 > 0; loss_2022 == 0; loss_2023 == 0 }

    expiring_loss := loss_2022 { loss_2022 > 0; current_year - 2022 >= 4 }
    expiring_msg = sprintf("⚠️ STRATA %d PRZEDAWNIA SIĘ w tym roku! %.2f PLN — odlicz TERAZ albo przepadnie!", [2022, loss_2022]) { loss_2022 > 0; current_year - 2022 >= 4 }
    expiring_msg = sprintf("⚠️ STRATA %d przedawnia się za rok — %.2f PLN", [2023, loss_2023]) { loss_2023 > 0; current_year - 2023 >= 3 }
    expiring_msg = "OK — najstarsza strata ważna jeszcze 2+ lat" { true }

    loss_rt = "TRIAGE_QUEUE" { expiring_loss > 0 }
    loss_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# L161: tax_loss_optimal_schedule — Optymalny harmonogram odliczeń
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.tax_loss.optimal_schedule",
    "package": "jdg.pit.tax_loss_harvesting",
    "priority": 161,
    "pit_form": pit_form,
    "tax_loss_current_income": current_income,
    "tax_loss_max_deduction_this_year": max_50pct,
    "tax_loss_recommended_deduction": recommended,
    "tax_loss_recommended_strategy": strategy,
    "_routing": "",
    "_routing_reason": sprintf("Optymalne odliczenie straty: %.2f PLN (max 50%% dochodu = %.2f PLN). Strategia: %s",
        [recommended, max_50pct, strategy]),
    "_legal_basis": "Art. 9 ust. 3 PIT (max 50% straty rocznie)",
    "_warnings": [sprintf("OPTYMALNE ODLICZENIE STRATY — Dochód: %.2f PLN. Max 50%%: %.2f PLN. Rekomendowane odliczenie: %.2f PLN. Strategia: %s. %s",
        [current_income, max_50pct, recommended, strategy, tax_bracket_note])]
} {
    input.tax_loss_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    current_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 120000)
    total_loss := object.get(input.jdg_entrepreneur, "total_available_tax_loss", 50000)

    max_50pct := current_income * 0.50
    recommended := min([max_50pct, total_loss])

    # Strategia: odliczaj WIĘCEJ w latach z wyższym progiem (32%)
    is_high_bracket := current_income > 120000
    strategy = "ODLICZ MAKSYMALNIE (50%) — jesteś w 32% progu, każda złotówka straty oszczędza 0.32 PLN!" { is_high_bracket }
    strategy = "Odlicz standardowo (50%) — jesteś w 12% progu" { not is_high_bracket }
    tax_bracket_note = "W 32% progu strata 'warta' jest więcej — odliczaj agresywnie!" { is_high_bracket }
    tax_bracket_note = "W 12% progu strata oszczędza mniej — rozważ rozłożenie na lata, gdy przewidujesz wyższy dochód." { not is_high_bracket }
}

# ═══════════════════════════════════════════════════════════════════════════════
# L162: tax_loss_progressive_simulation — Symulacja w którym roku odliczyć
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.tax_loss.progressive_simulation",
    "package": "jdg.pit.tax_loss_harvesting",
    "priority": 162,
    "pit_form": pit_form,
    "tax_loss_simulation_years": [2026, 2027, 2028],
    "tax_loss_simulation_savings": savings_comparison,
    "tax_loss_simulation_recommendation": sim_recommendation,
    "_routing": "",
    "_routing_reason": sprintf("Symulacja: odlicz teraz → oszczędność %.2f PLN; rozłożone → %.2f PLN", [savings_now, savings_spread]),
    "_legal_basis": "Art. 9 ust. 3-5 PIT",
    "_warnings": [sprintf("SYMULACJA ROZLICZENIA STRATY %.2f PLN:\n   Opcja A (odlicz CAŁOŚĆ teraz, 50%%): oszczędność %.2f PLN\n   Opcja B (rozłożone na 3 lata): oszczędność %.2f PLN\n   ➡️ REKOMENDACJA: %s",
        [total_loss, savings_now, savings_spread, sim_recommendation])]
} {
    input.tax_loss_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    current_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 120000)
    projected_income_next := object.get(input.jdg_entrepreneur, "projected_income_next_year", 150000)
    projected_income_2y := object.get(input.jdg_entrepreneur, "projected_income_2years", 180000)
    total_loss := object.get(input.jdg_entrepreneur, "total_available_tax_loss", 50000)

    # Opcja A: odlicz teraz max 50%
    max_now := current_income * 0.50
    deduct_now := min([max_now, total_loss])
    bracket_now := 0.32 { current_income > 120000 }
    bracket_now := 0.12 { current_income <= 120000 }
    savings_now := deduct_now * bracket_now

    # Opcja B: rozłóż
    d1 := min([current_income * 0.50, total_loss * 0.34])
    d2 := min([projected_income_next * 0.50, total_loss * 0.33])
    d3 := min([projected_income_2y * 0.50, total_loss - d1 - d2])
    b1 := 0.32 { current_income > 120000 } else = 0.12
    b2 := 0.32 { projected_income_next > 120000 } else = 0.12
    b3 := 0.32 { projected_income_2y > 120000 } else = 0.12
    savings_spread := d1 * b1 + d2 * b2 + d3 * b3

    sim_recommendation = "ODLICZ TERAZ — jesteś w wyższym progu podatkowym niż przewidujesz w przyszłości" { savings_now > savings_spread }
    sim_recommendation = "ROZŁÓŻ na lata — w przyszłych latach będziesz w wyższym progu (32%), odliczenie będzie więcej warte!" { savings_spread > savings_now }
}

# ═══════════════════════════════════════════════════════════════════════════════
# L163: tax_loss_expiration_alert — Alert o przedawniającej się stracie
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.tax_loss.expiration_alert",
    "package": "jdg.pit.tax_loss_harvesting",
    "priority": 163,
    "pit_form": pit_form,
    "tax_loss_expiring_this_year": expiring_amount,
    "tax_loss_expiring_year": expiring_year,
    "tax_loss_urgent_action": "ODLICZ NATYCHMIAST — strata PRZEPADNIE po tym roku!",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("STRATA %d PRZEDAWNIA SIĘ! %.2f PLN — odlicz w tym roku lub PRZEPADNIE!",
        [expiring_year, expiring_amount]),
    "_legal_basis": "Art. 9 ust. 3 PIT (przedawnienie straty po 5 latach)",
    "_warnings": [sprintf("🚨 STRATA PRZEDAWNIA SIĘ W TYM ROKU! Rok %d: %.2f PLN. To OSTATNI rok na odliczenie! Jeśli nie odliczysz — strata PRZEPADA BEZPOWROTNIE. Maksymalne odliczenie w tym roku: %.2f PLN (50%% dochodu).",
        [expiring_year, expiring_amount, max_deduction])]
} {
    input.tax_loss_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    current_year := 2026
    loss_2022 := object.get(input.jdg_entrepreneur, "tax_loss_2022", 0)
    loss_2021 := object.get(input.jdg_entrepreneur, "tax_loss_2021", 0)
    expiring_amount := loss_2022 { loss_2022 > 0; current_year - 2022 >= 4 }
    expiring_amount := loss_2021 { loss_2021 > 0; current_year - 2021 >= 4 }
    expiring_year := current_year - 4 { expiring_amount > 0 }
    current_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", 120000)
    max_deduction := current_income * 0.50
    expiring_amount > 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# L164: tax_loss_relief_interaction — Interakcja straty z innymi ulgami
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.tax_loss.relief_interaction",
    "package": "jdg.pit.tax_loss_harvesting",
    "priority": 164,
    "pit_form": pit_form,
    "tax_loss_applied_before_reliefs": true,
    "tax_loss_interaction_note": "Strata jest odliczana PRZED ulgami! Najpierw odlicz stratę, potem stosuj B+R, IP Box, darowizny itd. To obniża dochód dla kolejnych ulg, ale strata jest 'pierwsza w kolejce'.",
    "_routing": "",
    "_routing_reason": "Strata → najpierw odlicz, potem ulgi",
    "_legal_basis": "Art. 9 ust. 3 PIT (pierwszeństwo straty przed ulgami)",
    "_warnings": ["KOLEJNOŚĆ: 1. STRATA (50% rocznie, 5 lat) → 2. IP Box → 3. B+R → 4. pozostałe ulgi. Pamiętaj: strata obniża dochód, od którego liczysz LIMIT 6% dla darowizn i limit 50% dla kolejnych strat!"]
} {
    input.tax_loss_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
}

# ═══════════════════════════════════════════════════════════════════════════════
# FALLBACK
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.tax_loss.fallback",
    "package": "jdg.pit.tax_loss_harvesting",
    "priority": 999,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 9 ust. 3-5 PIT",
    "_warnings": ["Tax Loss Harvesting — rozliczaj straty w ciągu 5 lat, max 50% rocznie. Odliczaj w latach z wyższym dochodem dla maksymalnej oszczędności."]
} {
    true
}
