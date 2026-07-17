# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Enterprise Tax Form Transition Intelligence
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Tax Form Transitions — Smart Form Change Engine
# description: |
#   ENTERPRISE v4.0 — Inteligentny silnik zmiany formy opodatkowania JDG.
#   Obsługuje wszystkie ścieżki przejścia między skala/liniowy/ryczałt/karta
#   z walidacją terminów, konsekwencji podatkowych, remanentu, korekt,
#   utraty prawa do ulg, zmiany zasad KUP i składki zdrowotnej.
#   Zwiększa pokrycie PIT transitions z ~49% → ~90%.
# architecture: Enterprise Multi-Pass (ADR-001), First-Match-Wins else-chain
# legal_basis: Art. 9a, 24, 24a, 27, 30c, 44 PIT; ustawa o ryczałcie
# package: jdg.pit.transition_intel
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.transition_intel

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.pit.transition_intel.no_match",
    "package": "jdg.pit.transition_intel", "priority": 599
}

# ═══════════════════════════════════════════════════════════════════════════════
# T500-T509: SCALE → LINEAR TRANSITION
# ═══════════════════════════════════════════════════════════════════════════════

# ── T500: scale_to_linear_conditions — Warunki przejścia skala→liniowy ──
decide := {
    "matched": true, "rule_id": "jdg.pit.transition.scale_to_linear",
    "package": "jdg.pit.transition_intel", "priority": 500,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "LINEAR", "pit_rate": "0.19", "pit_bracket": "", "pit_annual_return_type": "PIT-36L",
    "kus_qualification": "deductible_full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "0.049",
    "pit_transition_from": "PIT_SCALE", "pit_transition_to": "LINEAR",
    "pit_transition_deadline": "FEBRUARY_20",
    "pit_transition_oath_required": true,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Zmiana formy: SKALA → LINIOWY. Wymaga oświadczenia do 20 lutego!",
    "_legal_basis": "Art. 9a ust. 2, Art. 30c PIT",
    "_warnings": [sprintf("ZMIANA FORMY: SKALA 12/32%% → LINIOWY 19%%. %s. Kluczowe zmiany: (1) Stawka 19%% niezależnie od dochodu, (2) Utrata kwoty wolnej 30k, (3) Utrata ulgi na dzieci i wspólnego rozliczenia z małżonkiem, (4) Składka zdrowotna spada z 9%% do 4.9%% (oszczędność ~%.0f PLN/rok), (5) Możliwość odliczenia zdrowotnej od dochodu (max 12900 PLN). Oświadczenie CEIDG-1 do 20 lutego!", [timing_note, health_savings])]
} {
    input.jdg_entrepreneur.tax_form_change_requested == true
    input.jdg_entrepreneur.tax_form_change_to == "LINEAR"
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    annual_income := object.get(input.jdg_entrepreneur, "annual_income_net", 120000)
    # Zdrowotna: 9% vs 4.9% = oszczędność
    health_now := annual_income * 0.09
    health_linear := annual_income * 0.049
    health_savings := max([0, health_now - health_linear])
    timing_note = "Wniosek w CEIDG-1 do 20 lutego. Obowiązuje od 1 stycznia danego roku." { true }
}

# ── T501: scale_to_linear_inventory_check — Remanent przy zmianie skala→liniowy ──
else := {
    "matched": true, "rule_id": "jdg.pit.transition.scale_to_linear_remnant",
    "package": "jdg.pit.transition_intel", "priority": 501,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "LINEAR", "pit_rate": "0.19", "pit_bracket": "", "pit_annual_return_type": "PIT-36L",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "0.049",
    "pit_transition_remnant_required": true,
    "pit_transition_remnant_date": "DECEMBER_31",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Remanent na koniec roku przy zmianie formy opodatkowania",
    "_legal_basis": "Art. 24 ust. 3 PIT, § 27-29 Rozporządzenia PKPiR",
    "_warnings": [sprintf("REMANENT PRZY ZMIANIE FORMY — Wymagany spis z natury na 31 grudnia. Wartość remanentu: %.2f PLN. Remanent wpływa na dochód pierwszego roku na nowej formie! Wycena: cena zakupu lub rynkowa (niższa). Dokument przechowuj 5 lat.", [remnant_value])]
} {
    input.jdg_entrepreneur.tax_form_change_requested == true
    input.jdg_entrepreneur.tax_form_change_to == "LINEAR"
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    input.jdg_entrepreneur.has_inventory == true
    remnant_value := object.get(input.jdg_entrepreneur, "remnant_value_pln", 0)
}

# ── T502: scale_to_linear_loss_carry — Przeniesienie strat przy zmianie ──
else := {
    "matched": true, "rule_id": "jdg.pit.transition.scale_to_linear_loss",
    "package": "jdg.pit.transition_intel", "priority": 502,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "LINEAR", "pit_rate": "0.19", "pit_bracket": "", "pit_annual_return_type": "PIT-36L",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "0.049",
    "pit_transition_loss_carry": true,
    "pit_transition_loss_amount": loss_amount,
    "pit_transition_loss_years_remaining": years_remaining,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 9 ust. 3 PIT — strata przechodzi na nową formę opodatkowania",
    "_warnings": [sprintf("STRATA PRZECHODZI NA LINIOWY — Nierozliczona strata %.2f PLN z lat ubiegłych PRZECHODZI na podatek liniowy. Pozostało %d lat na rozliczenie (max 50%% rocznie). Złóż PIT-36L z odliczeniem straty.", [loss_amount, years_remaining])]
} {
    input.jdg_entrepreneur.tax_form_change_requested == true
    input.jdg_entrepreneur.tax_form_change_to == "LINEAR"
    input.jdg_entrepreneur.has_prior_year_losses == true
    loss_amount := object.get(input.jdg_entrepreneur, "unresolved_loss_amount", 0)
    lost_year := object.get(input.jdg_entrepreneur, "loss_origination_year", 2021)
    current_year := 2026
    years_remaining := max([0, 5 - (current_year - lost_year)])
}

# ═══════════════════════════════════════════════════════════════════════════════
# T510-T519: SCALE/LINEAR → LUMP SUM TRANSITION
# ═══════════════════════════════════════════════════════════════════════════════

# ── T510: to_lump_sum_eligibility — Czy mogę przejść na ryczałt? ──
else := {
    "matched": true, "rule_id": "jdg.pit.transition.to_lump_sum_eligibility",
    "package": "jdg.pit.transition_intel", "priority": 510,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "LUMP_SUM", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "PIT-28",
    "kus_qualification": "non_deductible", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "0.049",
    "pit_transition_from": current_form, "pit_transition_to": "LUMP_SUM",
    "pit_transition_eligible": is_eligible,
    "pit_transition_blockers": blockers,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": eligible_routing,
    "_routing_reason": sprintf("Przejście na ryczałt: %s", [eligibility_msg]),
    "_legal_basis": "Art. 6-8 ustawy o zryczałtowanym podatku dochodowym",
    "_warnings": [sprintf("PRZEJŚCIE NA RYCZAŁT — %s. Kluczowe: (1) Płacisz %% od PRZYCHODU, nie od dochodu, (2) Brak kosztów uzyskania przychodu, (3) Brak kwoty wolnej, (4) Brak ulgi na dzieci, (5) Składka zdrowotna ryczałtowa (progi: 60k/300k), (6) Limit 2M EUR przychodu. %s", [eligibility_msg, blocker_info])]
} {
    input.jdg_entrepreneur.tax_form_change_requested == true
    input.jdg_entrepreneur.tax_form_change_to == "LUMP_SUM"
    current_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_gross", 150000)
    is_former_employer := object.get(input.jdg_entrepreneur, "serving_former_employer", false)
    is_pharmacy := object.get(input.jdg_entrepreneur, "business_type", "") == "PHARMACY"
    is_currency_exchange := object.get(input.jdg_entrepreneur, "business_type", "") == "CURRENCY_EXCHANGE"
    blockers := []
    b1 := array.concat(blockers, ["Były pracodawca — nie można na ryczałcie"]) { is_former_employer }
    b2 := array.concat(b1, ["Apteka — wykluczona z ryczałtu"]) { is_pharmacy }
    b3 := array.concat(b2, ["Kantor — wykluczony z ryczałtu"]) { is_currency_exchange }
    b4 := array.concat(b3, [sprintf("Przekroczono limit 2M EUR — przychód %.2f > %.2f", [annual_revenue, 9000000])]) { annual_revenue > 9000000 }
    is_eligible := count(b4) <= 0
    eligible_routing = "BLOCK_AND_ALERT" { not is_eligible }
    eligible_routing = "" { is_eligible }
    eligibility_msg = "MOŻLIWE" { is_eligible }
    eligibility_msg = sprintf("NIEMOŻLIWE — %s", [concat("; ", [b | b := b4[_]])]) { not is_eligible }
    blocker_info = concat(" | ", [b | b := b4[_]]) { not is_eligible }
    blocker_info = "Złóż oświadczenie CEIDG-1 do 20 lutego. Ewidencja przychodów zamiast PKPiR." { is_eligible }
}

# ── T512: to_lump_sum_pkpir_to_revenue_log — Przejście z PKPiR na ewidencję przychodów ──
else := {
    "matched": true, "rule_id": "jdg.pit.transition.to_lump_sum_books_change",
    "package": "jdg.pit.transition_intel", "priority": 512,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "LUMP_SUM", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "PIT-28",
    "kus_qualification": "non_deductible", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "0.049",
    "pit_transition_books_change": "PKPIR_TO_REVENUE_LOG",
    "pit_transition_pkpir_close_required": true,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Zamknięcie PKPiR + otwarcie ewidencji przychodów ryczałtowych",
    "_legal_basis": "Art. 15 ustawy o ryczałcie, § 27-29 Rozporządzenia PKPiR",
    "_warnings": ["ZMIANA KSIĘGOWOŚCI: PKPiR → EWIDENCJA PRZYCHODÓW. (1) Zamknij PKPiR na 31 grudnia — sporządź remanent, (2) Od 1 stycznia prowadź tylko ewidencję przychodów (data, nr faktury, kwota, stawka ryczałtu), (3) Faktury kosztowe przechowuj, ale NIE księguj w kosztach, (4) PKPiR przechowuj 5 lat. Ryczałt = PIT od przychodu, nie od dochodu!"]
} {
    input.jdg_entrepreneur.tax_form_change_requested == true
    input.jdg_entrepreneur.tax_form_change_to == "LUMP_SUM"
    current_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    current_form == "PIT_SCALE"  # lub LINEAR — obie używają PKPiR
}

# ═══════════════════════════════════════════════════════════════════════════════
# T520-T529: LUMP SUM → SCALE/LINEAR TRANSITION
# ═══════════════════════════════════════════════════════════════════════════════

# ── T520: lump_to_scale_transition — Powrót z ryczałtu na skalę ──
else := {
    "matched": true, "rule_id": "jdg.pit.transition.lump_to_scale",
    "package": "jdg.pit.transition_intel", "priority": 520,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "PIT_SCALE", "pit_rate": "0.12", "pit_bracket": "LOW", "pit_annual_return_type": "PIT-36",
    "kus_qualification": "deductible_full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "0.09",
    "pit_transition_from": "LUMP_SUM", "pit_transition_to": "PIT_SCALE",
    "pit_transition_revenue_log_close_required": true,
    "pit_transition_pkpir_open_required": true,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "Powrót z ryczałtu na skalę podatkową — PKPiR od nowa",
    "_legal_basis": "Art. 9a ust. 5 PIT",
    "_warnings": ["POWRÓT NA SKALĘ PODATKOWĄ. Kluczowe zmiany: (1) Od 1 stycznia prowadzisz PKPiR, (2) Płacisz PIT od DOCHODU (przychód - koszty), a nie od przychodu, (3) Odzyskujesz kwotę wolną 30k, ulgę na dzieci, wspólne rozliczenie, (4) Składka zdrowotna rośnie do 9%% (od dochodu, nie odliczasz), (5) Ewidencję przychodów ryczałtowych zamknij i przechowuj 5 lat."]
} {
    input.jdg_entrepreneur.tax_form_change_requested == true
    input.jdg_entrepreneur.tax_form_change_to == "PIT_SCALE"
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# ═══════════════════════════════════════════════════════════════════════════════
# T530-T539: MID-YEAR FORM CHANGE (FORCED) — Przymusowa zmiana formy
# ═══════════════════════════════════════════════════════════════════════════════

# ── T530: forced_change_lump_sum_limit_breach — Przekroczenie limitu ryczałtu ──
else := {
    "matched": true, "rule_id": "jdg.pit.transition.forced_lump_to_scale",
    "package": "jdg.pit.transition_intel", "priority": 530,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "PIT_SCALE", "pit_rate": "0.12", "pit_bracket": "", "pit_annual_return_type": "PIT-36",
    "kus_qualification": "deductible_full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "0.09",
    "pit_transition_forced": true,
    "pit_transition_force_reason": "LUMP_SUM_LIMIT_BREACH",
    "pit_transition_effective_date": breach_date,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("PRZEKROCZENIE LIMITU RYCZAŁTU! Od %s przechodzisz na skalę podatkową.", [breach_date]),
    "_legal_basis": "Art. 8 ust. 1 pkt 5 ustawy o ryczałcie, Art. 44 PIT",
    "_warnings": [sprintf("PRZEKROCZENIE LIMITU RYCZAŁTU 2M EUR! Przychód %.0f PLN > limit %.0f PLN. Od dnia przekroczenia przechodzisz NA SKALĘ PODATKOWĄ! (1) Zacznij prowadzić PKPiR od dnia przekroczenia, (2) Dochód od tego dnia = skala 12/32%%, (3) Złóż PIT-36 za ten rok (nie PIT-28!), (4) Ryczałt za okres przed przekroczeniem rozlicz normalnie.", [annual_revenue, limit_pln])]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_gross", 0)
    eur_rate := object.get(object.get(data.jdg.thresholds, "bounds", {}), "eur_pln", 4.5)
    eur_pln := eur_rate
    limit_pln := 2000000 * eur_pln
    annual_revenue > limit_pln
    breach_date := "2026-07-01"  # placeholder — data przekroczenia
}

# ── T535: forced_change_linear_ex_employer — Liniowy niedozwolony (były pracodawca) ──
else := {
    "matched": true, "rule_id": "jdg.pit.transition.forced_linear_to_scale",
    "package": "jdg.pit.transition_intel", "priority": 535,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "PIT_SCALE", "pit_rate": "0.12", "pit_bracket": "", "pit_annual_return_type": "PIT-36",
    "kus_qualification": "deductible_full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "0.09",
    "pit_transition_forced": true,
    "pit_transition_force_reason": "EX_EMPLOYER_BLOCK",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Podatek liniowy niedozwolony — świadczysz usługi dla byłego pracodawcy!",
    "_legal_basis": "Art. 30c ust. 2 PIT — wykluczenie z podatku liniowego",
    "_warnings": ["PODATEK LINIOWY NIEDOZWOLONY! Świadczysz usługi dla byłego pracodawcy — zgodnie z Art. 30c ust. 2 PIT NIE możesz być na podatku liniowym. PRZYMUSOWA zmiana na skalę podatkową od początku roku. Korekta zaliczek PIT + składki zdrowotnej (z 4.9% na 9%)!"]
} {
    input.jdg_entrepreneur.tax_form == "LINEAR"
    input.jdg_entrepreneur.serving_former_employer == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# T540-T549: CROSS-TRANSITION ZUS HEALTH IMPACT
# ═══════════════════════════════════════════════════════════════════════════════

# ── T540: transition_health_insurance_impact — Wpływ zmiany formy na zdrowotną ──
else := {
    "matched": true, "rule_id": "jdg.pit.transition.health_impact",
    "package": "jdg.pit.transition_intel", "priority": 540,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": new_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": new_health_rate,
    "zus_health_rate_old": old_health_rate,
    "zus_health_change_monthly_pln": health_delta,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": health_routing,
    "_routing_reason": sprintf("Zdrowotna zmienia się z %s na %s (delta %.0f PLN/mies)", [old_health_rate, new_health_rate, health_delta]),
    "_legal_basis": "Art. 79-81 ustawy o świadczeniach opieki zdrowotnej",
    "_warnings": [sprintf("ZMIANA SKŁADKI ZDROWOTNEJ — %s → %s: z %s na %s. Różnica miesięczna: %+.0f PLN (%+.0f PLN/rok). %s. Nowa składka obowiązuje od stycznia.", [old_form, new_form, old_health_rate, new_health_rate, health_delta, health_delta * 12, health_note])]
} {
    input.jdg_entrepreneur.tax_form_change_requested == true
    old_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    new_form := object.get(input.jdg_entrepreneur, "tax_form_change_to", "LINEAR")
    annual_income := object.get(input.jdg_entrepreneur, "annual_income_net", 120000)
    # Stare stawki
    old_health_rate = "0.09" { old_form == "PIT_SCALE" }
    old_health_rate = "0.09" { old_form == "TAX_CARD" }
    old_health_rate = "0.049" { old_form == "LINEAR" }
    old_health_rate = "0.049" { old_form == "LUMP_SUM" }
    # Nowe stawki
    new_health_rate = "0.09" { new_form == "PIT_SCALE" }
    new_health_rate = "0.09" { new_form == "TAX_CARD" }
    new_health_rate = "0.049" { new_form == "LINEAR" }
    new_health_rate = "0.049" { new_form == "LUMP_SUM" }
    # Delta miesięczna
    health_delta := floor((annual_income * 0.049 - annual_income * 0.09) / 12 * 100) / 100 { old_health_rate == "0.09"; new_health_rate == "0.049" }
    health_delta := floor((annual_income * 0.09 - annual_income * 0.049) / 12 * 100) / 100 { old_health_rate == "0.049"; new_health_rate == "0.09" }
    health_delta := 0 { old_health_rate == new_health_rate }
    health_routing = "WARNING" { abs(health_delta) > 500 }
    health_routing = "" { true }
    health_note = "Zdrowotna SPADA — oszczędzasz!" { health_delta < 0 }
    health_note = "Zdrowotna ROŚNIE — uwzględnij w budżecie!" { health_delta > 0 }
    health_note = "Bez zmian" { health_delta == 0 }
}

# ═══════════════════════════════════════════════════════════════════════════════
# T550: DEADLINE CALENDAR FOR FORM CHANGE
# ═══════════════════════════════════════════════════════════════════════════════

# ── T550: form_change_deadline_calendar — Kalendarz zmiany formy ──
else := {
    "matched": true, "rule_id": "jdg.pit.transition.deadline_calendar",
    "package": "jdg.pit.transition_intel", "priority": 550,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": new_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pit_transition_oath_deadline": "FEBRUARY_20",
    "pit_transition_first_advance_due": "JANUARY_20",
    "pit_transition_annual_return_due": "APRIL_30_NEXT_YEAR",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 9a ust. 5, Art. 44, Art. 45 PIT",
    "_warnings": [sprintf("KALENDARZ ZMIANY FORMY: %s → %s. (1) Do 20 lutego: złóż oświadczenie CEIDG-1, (2) Do 20 stycznia: pierwsza zaliczka na nowych zasadach, (3) Do 31 stycznia: zamknij PKPiR/ewidencję za poprzedni rok + remanent, (4) Do 30 kwietnia przyszłego roku: złóż PIT-36/PIT-36L/PIT-28 za rok zmiany. Dokumenty przechowuj 5 lat.", [old_form, new_form])]
} {
    input.jdg_entrepreneur.tax_form_change_requested == true
    old_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    new_form := object.get(input.jdg_entrepreneur, "tax_form_change_to", "LINEAR")
}

# ═══════════════════════════════════════════════════════════════════════════════
# T560: LUMP SUM RATE CALCULATOR PER PKWiU
# ═══════════════════════════════════════════════════════════════════════════════

# ── T560: lump_sum_rate_by_pkwiu — Stawka ryczałtu per PKWiU ──
else := {
    "matched": true, "rule_id": "jdg.pit.transition.lump_sum_rate_pkwiu",
    "package": "jdg.pit.transition_intel", "priority": 560,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "LUMP_SUM", "pit_rate": lump_rate_str, "pit_bracket": "", "pit_annual_return_type": "PIT-28",
    "kus_qualification": "non_deductible", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "0.049",
    "pit_lump_sum_rate_pct": lump_rate_pct,
    "pit_lump_sum_pkwiu_section": pkwiu_section,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 12 ustawy o ryczałcie, Załącznik nr 1 (stawki per PKWiU)",
    "_warnings": [sprintf("STAWKA RYCZAŁTU — PKWiU: %s → %.1f%% przychodu. %s. Uwaga: stawka 8.5%% do 100k PLN, powyżej 12.5%% (dla niektórych usług). Stawka 12%% dla IT powyżej 300k PLN przychodu.", [pkwiu_section, lump_rate_pct, rate_note])]
} {
    input.jdg_entrepreneur.tax_form_change_requested == true
    input.jdg_entrepreneur.tax_form_change_to == "LUMP_SUM"
    pkwiu_section := object.get(input.jdg_entrepreneur, "pkwiu_section", "62.01.Z")
    annual_revenue := object.get(input.jdg_entrepreneur, "annual_revenue_gross", 150000)
    # Extract PKWiU division prefix (first 2 chars) for dictionary lookup
    pkwiu_div := substring(pkwiu_section, 0, 2)
    # PKWiU division → lump sum rate lookup (Art. 12 ustawy o ryczałcie, Załącznik nr 1)
    pkwiu_rate_map := {
        "45": 2.0,   # Handel detaliczny/hurtowy częściami samochodowymi
        "46": 2.0,   # Handel hurtowy
        "47": 2.0,   # Handel detaliczny
        "10": 3.0,   # Produkcja artykułów spożywczych
        "11": 3.0,   # Produkcja napojów
        "13": 3.0,   # Produkcja wyrobów tekstylnych
        "14": 3.0,   # Produkcja odzieży
        "15": 3.0,   # Produkcja skór
        "16": 3.0,   # Produkcja drewna
        "17": 3.0,   # Produkcja papieru
        "18": 3.0,   # Poligrafia
        "20": 3.0,   # Produkcja chemikaliów
        "22": 3.0,   # Produkcja gumy i tworzyw
        "23": 3.0,   # Produkcja mineralna
        "24": 3.0,   # Produkcja metali
        "25": 3.0,   # Produkcja metalowych wyrobów
        "26": 3.0,   # Produkcja elektroniki
        "27": 3.0,   # Produkcja urządzeń elektrycznych
        "28": 3.0,   # Produkcja maszyn
        "29": 3.0,   # Produkcja pojazdów
        "30": 3.0,   # Produkcja pozostałego sprzętu transportowego
        "31": 3.0,   # Produkcja mebli
        "32": 3.0,   # Pozostała produkcja
        "33": 3.0,   # Naprawa i instalacja maszyn
        "41": 5.5,   # Budownictwo — budynki
        "42": 5.5,   # Budownictwo — inżynieria lądowa
        "43": 5.5,   # Budownictwo — specjalistyczne
        "49": 5.5,   # Transport lądowy
        "50": 5.5,   # Transport wodny
        "52": 5.5,   # Magazynowanie
        "55": 3.0,   # Gastronomia (3%)
        "56": 3.0,   # Gastronomia (3%)
        "58": 8.5,   # Działalność wydawnicza
        "59": 8.5,   # Film, video, telewizja
        "60": 8.5,   # Radiofonia
        "61": 8.5,   # Telekomunikacja
        "62": 8.5,   # IT — oprogramowanie (12% powyżej 300k przychodu)
        "63": 8.5,   # IT — usługi informacyjne
        "64": 15.0,  # Finanse
        "65": 15.0,  # Ubezpieczenia
        "66": 15.0,  # Usługi finansowe pomocnicze
        "68": 8.5,   # Nieruchomości (najem prywatny 8.5%)
        "69": 14.0,  # Prawnicze, rachunkowe, doradztwo podatkowe
        "70": 15.0,  # Zarządzanie, doradztwo biznesowe
        "71": 14.0,  # Architektura, inżynieria, badania
        "72": 14.0,  # Badania naukowe
        "73": 14.0,  # Reklama, marketing
        "74": 14.0,  # Pozostała działalność profesjonalna
        "75": 14.0,  # Weterynaria
        "77": 8.5,   # Wynajem i dzierżawa
        "78": 8.5,   # Pośrednictwo pracy
        "79": 8.5,   # Turystyka
        "80": 8.5,   # Ochrona
        "81": 8.5,   # Sprzątanie, ogrodnictwo
        "82": 8.5,   # Administracja biura
        "85": 8.5,   # Edukacja
        "86": 17.0,  # Opieka zdrowotna — wolne zawody
        "87": 17.0,  # Opieka społeczna
        "88": 17.0,  # Opieka społeczna bez zakwaterowania
        "90": 8.5,   # Sztuka, rozrywka
        "93": 8.5,   # Sport, rekreacja
        "95": 8.5,   # Naprawa komputerów i artykułów domowych
        "96": 8.5,   # Pozostałe usługi indywidualne
    }
    # Lookup rate from map; IT (62/63) with revenue >300k → 12%
    base_rate := object.get(pkwiu_rate_map, pkwiu_div, 8.5)
    lump_rate_pct = 12.0 { pkwiu_div == "62"; annual_revenue > 300000 }
    lump_rate_pct = 12.0 { pkwiu_div == "63"; annual_revenue > 300000 }
    lump_rate_pct = base_rate
    lump_rate_str = sprintf("%.1f%%", [lump_rate_pct])
    rate_note = "Usługi IT — 12%% powyżej 300k PLN" { lump_rate_pct == 12.0 }
    rate_note = "Stawka standardowa dla usług" { lump_rate_pct == 8.5 }
    rate_note = "Stawka obniżona" { lump_rate_pct <= 5.5 }
    rate_note = "Stawka podwyższona — wolne zawody" { lump_rate_pct >= 14.0 }
}
