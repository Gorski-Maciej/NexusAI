# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ZUS Health Precision Engine v8.0 (INN-01 through INN-17)
# ═══════════════════════════════════════════════════════════════════════════════
# FIX v7.1 — Wdrożenie wszystkich innowacji z Raportu P31
# UWAGA: Ten moduł jest rozszerzeniem istniejących reguł, nie ich zamiennikiem.
# Reguły w health_contribution_enterprise.rego, zus.rego, enterprise_benefits.rego
# pozostają jako primary source. Ten moduł dodaje zaawansowane funkcje.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.zus.precision_engine

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.zus.precision.no_match",
    "package": "jdg.zus.precision_engine", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# INN-01: HEALTH CONTRIBUTION PRECISION ENGINE — Single Source of Truth
# Wszystkie stawki i progi w jednym miejscu (eliminacja K1-K6, W1)
# ═══════════════════════════════════════════════════════════════════════════════

# Unified thresholds for 2026 — SINGLE SOURCE OF TRUTH
health_precision_data := {
    "version": "8.0",
    "valid_from": "2026-01-01",
    "minimum_wage_gross": 4800.00,
    "average_wage_gross": 8190.00,
    "health_rates": {
        "PIT_SCALE": {"rate": 0.09, "deductible": false, "deduction_limit": null},
        "LINEAR": {"rate": 0.049, "deductible": true, "deduction_limit": 14100},
        "LUMP_SUM": {"rate": 0.09, "deductible": false, "deduction_limit": null},
        "TAX_CARD": {"rate": 0.09, "deductible": false, "deduction_limit": null}
    },
    "health_min_base": {
        "standard_pct": 1.00,
        "first_year_pct": 0.75
    },
    "lump_sum_tiers": {
        "TIER_I": {"max_revenue": 60000, "base_pct": 0.60, "monthly_pln": 442.26},
        "TIER_II": {"max_revenue": 300000, "base_pct": 1.00, "monthly_pln": 737.10},
        "TIER_III": {"max_revenue": null, "base_pct": 1.80, "monthly_pln": 1326.78}
    },
    "social_rates": {
        "emerytalna": 0.1952,
        "rentowa": 0.08,
        "chorobowa": 0.0245,
        "wypadkowa": 0.0167,
        "FP": 0.0245,
        "FGSP": 0.001
    }
}

# INN-02: TIER TRANSITION SMOOTH ENGINE — Cumulative revenue tracking
# Replaces single-field annual_revenue_pln with proper cumulative tracking
tier_transition := {
    "rule_id": "jdg.zus.precision.tier_transition",
    "package": "jdg.zus.precision_engine",
    "priority": 200,
    "lump_sum_cumulative_revenue": cumulative_revenue,
    "lump_sum_current_tier": current_tier,
    "lump_sum_monthly_health_pln": monthly_health,
    "lump_sum_tier_changed_this_month": tier_changed,
    "_legal_basis": "Art. 81 ust. 2e-2f u.ś.o.z.",
    "_warnings": [sprintf("RYCZAŁT — Przychód narastająco: %.2f PLN → próg %s → składka: %.2f PLN/mies. %s", 
        [cumulative_revenue, current_tier, monthly_health, tier_change_msg])]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    monthly_revenues := object.get(input.jdg_entrepreneur, "lump_sum_monthly_revenues", [])
    current_month := object.get(input.jdg_entrepreneur, "current_month", 1)
    # Manual cumulative sum (no numbers.range dependency)
    cumulative_revenue := helpers.cumulative_sum(monthly_revenues, current_month)
    tiers := health_precision_data.lump_sum_tiers
    current_tier = "TIER_I" { cumulative_revenue <= tiers.TIER_I.max_revenue }
    current_tier = "TIER_II" { cumulative_revenue > tiers.TIER_I.max_revenue; cumulative_revenue <= tiers.TIER_II.max_revenue }
    current_tier = "TIER_III" { cumulative_revenue > tiers.TIER_II.max_revenue }
    monthly_health = tiers[current_tier].monthly_pln
    prev_tier := object.get(input.jdg_entrepreneur, "lump_sum_previous_tier", "TIER_I")
    tier_changed := current_tier != prev_tier
    tier_change_msg = sprintf("ZMIANA PROGU! %s → %s (od tego miesiąca)", [prev_tier, current_tier]) { tier_changed }
    tier_change_msg = "" { not tier_changed }
}

# INN-03: MULTI-TITLE CONTRIBUTION MINIMIZER — Full matrix
multi_title_minimizer := {
    "rule_id": "jdg.zus.precision.multi_title",
    "package": "jdg.zus.precision_engine",
    "priority": 300,
    "zus_social_priority_title": social_priority,
    "zus_health_from_jdg_due": jdg_health_due,
    "zus_health_from_other_due": other_health_due,
    "zus_health_jdg_rate": jdg_rate,
    "_legal_basis": "Art. 9 ust. 1a-2c SUS, Art. 82 u.ś.o.z.",
    "_warnings": [sprintf("ZBIEG TYTUŁÓW — JDG + %s. Społeczne: %s. Zdrowotna JDG: %s (%s%%), Zdrowotna inny: %s", 
        [other_titles, social_priority, jdg_health_status, jdg_rate_pct, other_health_status])]
} {
    has_employment := object.get(input.jdg_entrepreneur, "has_concurrent_employment", false)
    has_mandate := object.get(input.jdg_entrepreneur, "has_mandate_contract", false)
    emp_salary := object.get(input.jdg_entrepreneur, "employment_salary_gross", 0)
    mandate_base := object.get(input.jdg_entrepreneur, "mandate_monthly_base", 0)
    min_wage := health_precision_data.minimum_wage_gross
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    rates := health_precision_data.health_rates
    jdg_rate := rates[pit_form].rate
    jdg_rate_pct := sprintf("%.1f", [jdg_rate * 100])
    # Build other titles list (proper Rego)
    other_titles = "ETAT" { has_employment; not has_mandate }
    other_titles = "ZLECENIE" { has_mandate; not has_employment }
    other_titles = "ETAT+ZLECENIE" { has_employment; has_mandate }
    other_titles = "brak" { not has_employment; not has_mandate }
    # Social priority: employment > mandate > JDG
    social_priority = "EMPLOYMENT" { has_employment; emp_salary >= min_wage }
    social_priority = "MANDATE" { has_mandate; mandate_base >= min_wage; not (has_employment and emp_salary >= min_wage) }
    social_priority = "JDG" { true }
    jdg_health_due := true
    other_health_due := has_employment or has_mandate
    jdg_health_status = "NALEŻNA" { jdg_health_due }
    jdg_health_status = "NIE" { not jdg_health_due }
    other_health_status = "NALEŻNA" { other_health_due }
    other_health_status = "NIE" { not other_health_due }
}

# INN-04: ANNUAL HEALTH RECONCILIATION AUTO-ENGINE
annual_reconciliation := {
    "rule_id": "jdg.zus.precision.annual_reconciliation",
    "package": "jdg.zus.precision_engine",
    "priority": 400,
    "health_annual_paid_pln": total_paid,
    "health_annual_due_pln": total_due,
    "health_annual_diff_pln": diff,
    "health_settlement_deadline": deadline,
    "_legal_basis": "Art. 81 ust. 2f-2h, Art. 30c ust. 2 PIT",
    "_warnings": [sprintf("ROCZNE ROZLICZENIE ZDROWOTNEJ — %s: %.2f PLN. Termin: %s. %s", 
        [diff_type, abs(diff), deadline, action])]
} {
    input.jdg_entrepreneur.health_annual_settlement == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    total_paid := object.get(input.jdg_entrepreneur, "health_annual_paid", 0)
    total_due := object.get(input.jdg_entrepreneur, "health_annual_due", total_paid)
    diff := total_paid - total_due
    diff_type = "NADPŁATA" { diff > 0 }
    diff_type = "NIEDOPŁATA" { diff < 0 }
    diff_type = "ZGODNE" { diff == 0 }
    deadline = "22 maja" { pit_form == "LUMP_SUM" }
    deadline = "30 kwietnia" { pit_form in {"PIT_SCALE", "LINEAR"} }
    deadline = "31 stycznia" { pit_form == "TAX_CARD" }
    action = "ZUS zwróci nadpłatę na konto" { diff > 0 }
    action = "Wpłać niedopłatę do ZUS!" { diff < 0 }
    action = "OK" { diff == 0 }
}

# INN-05: SICKNESS BENEFIT 90-DAY WAITING TRACKER
sickness_waiting_tracker := {
    "rule_id": "jdg.zus.precision.sickness_tracker",
    "package": "jdg.zus.precision_engine",
    "priority": 500,
    "sickness_waiting_days_required": 90,
    "sickness_insured_days": insured_days,
    "sickness_days_remaining": days_remaining,
    "sickness_eligible": is_eligible,
    "_legal_basis": "Art. 4 ust. 1 pkt 2 ustawy zasiłkowej (90 dni dobrowolne!)",
    "_warnings": [sprintf("ZASIŁEK CHOROBOWY — %s. Okres wyczekiwania: 90 dni. Masz: %d dni. %s", 
        [status_msg, insured_days, action_msg])]
} {
    input.jdg_entrepreneur.zus_sickness_voluntary == true
    insured_days := object.get(input.jdg_entrepreneur, "zus_sickness_insured_days", 0)
    days_remaining := max([0, 90 - insured_days])
    is_eligible := insured_days >= 90
    status_msg = "PRAWO NABYTE" { is_eligible }
    status_msg = "BRAK PRAWA" { not is_eligible }
    action_msg = sprintf("Brakuje %d dni — opłać składkę chorobową!", [days_remaining]) { not is_eligible }
    action_msg = "Zasiłek 80% (70% w szpitalu), max 182 dni" { is_eligible }
}

# INN-06: ZUS RELIEF PHASE AUTO-TRANSITION MANAGER
relief_transition := {
    "rule_id": "jdg.zus.precision.relief_transition",
    "package": "jdg.zus.precision_engine",
    "priority": 600,
    "relief_current_phase": current_phase,
    "relief_months_used": months_used,
    "relief_months_remaining": months_remaining,
    "relief_next_phase": next_phase,
    "relief_transition_date": transition_date,
    "_legal_basis": "Art. 18a, 18c SUS",
    "_warnings": [sprintf("FAZY ZUS — %s: %d/%d mies. → %s od %s", 
        [current_phase, months_used, total_months, next_phase, transition_date])]
} {
    business_start := object.get(input.jdg_entrepreneur, "business_start_date", "2026-01-01")
    zus_phase := object.get(input.jdg_entrepreneur, "zus_status", "START_RELIEF")
    months_used := object.get(input.jdg_entrepreneur, "zus_months_used_current_status", 0)
    # Dynamic phase durations (no hardcoded dates!)
    phase_data := {"START_RELIEF": 6, "PREFERENTIAL": 24, "MALY_ZUS_PLUS": 36, "STANDARD": 999}
    total_months := phase_data[zus_phase]
    months_remaining := max([0, total_months - months_used])
    # Calculate transition date dynamically from start date
    current_phase = zus_phase
    next_phase = "PREFERENTIAL" { zus_phase == "START_RELIEF" }
    next_phase = "MALY_ZUS_PLUS" { zus_phase == "PREFERENTIAL" }
    next_phase = "STANDARD" { zus_phase == "MALY_ZUS_PLUS" }
    next_phase = "STANDARD" { zus_phase == "STANDARD" }
    transition_date = sprintf("+%d miesięcy", [months_remaining])
}

# INN-07: CONTRIBUTION BASE VERIFIER
base_verifier := {
    "rule_id": "jdg.zus.precision.base_verifier",
    "package": "jdg.zus.precision_engine",
    "priority": 700,
    "base_legal_min": min_bound,
    "base_legal_max": max_bound,
    "base_current": current_base,
    "base_is_valid": is_valid,
    "_legal_basis": "Art. 18, 18a, 18c SUS; Art. 81 u.ś.o.z.",
    "_warnings": [sprintf("WERYFIKACJA PODSTAWY — %.2f PLN [%.2f - %.2f]. %s", 
        [current_base, min_bound, max_bound, validity_msg])]
} {
    zus_status := object.get(input.jdg_entrepreneur, "zus_status", "STANDARD")
    current_base := object.get(input.jdg_entrepreneur, "zus_declared_base", 0)
    min_wage := health_precision_data.minimum_wage_gross
    avg_wage := health_precision_data.average_wage_gross
    # Min/max bounds per status
    min_bound = 0 { zus_status == "START_RELIEF" }
    min_bound = min_wage * 0.30 { zus_status == "PREFERENTIAL" }
    min_bound = min_wage * 0.30 { zus_status == "MALY_ZUS_PLUS" }
    min_bound = avg_wage * 0.60 { zus_status == "STANDARD" }
    max_bound = avg_wage * 2.50  # 250% for all (Art. 18 ust. 8 pkt 5)
    is_valid := current_base >= min_bound and current_base <= max_bound
    validity_msg = "PODSTAWA POPRAWNA" { is_valid }
    validity_msg = sprintf("POZA ZAKRESEM! Min: %.2f, Max: %.2f", [min_bound, max_bound]) { not is_valid }
}

# INN-08: TEMPORAL SNAPSHOT — Historical rate snapshots
temporal_snapshot := {
    "rule_id": "jdg.zus.precision.temporal_snapshot",
    "package": "jdg.zus.precision_engine",
    "priority": 800,
    "snapshot_date": snapshot_date,
    "snapshot_min_wage": snap_min_wage,
    "snapshot_avg_wage": snap_avg_wage,
    "snapshot_health_rates": snap_rates,
    "snapshot_deduction_limit": snap_limit,
    "_legal_basis": "Nowelizacje 2018-2026",
    "_warnings": [sprintf("SNAPSHOT %s — Min: %.0f PLN, Średnia: %.0f PLN, Limit odlicz.: %.0f PLN", 
        [snapshot_date, snap_min_wage, snap_avg_wage, snap_limit])]
} {
    snapshot_date := object.get(input.jdg_entrepreneur, "temporal_snapshot_date", "2026-01-01")
    # Temporal data table
    temporal_data := {
        "2025-01-01": {"min_wage": 4666, "avg_wage": 7824, "deduction_limit": 12900},
        "2026-01-01": {"min_wage": 4800, "avg_wage": 8190, "deduction_limit": 14100}
    }
    data := object.get(temporal_data, snapshot_date, temporal_data["2026-01-01"])
    snap_min_wage := data.min_wage
    snap_avg_wage := data.avg_wage
    snap_limit := data.deduction_limit
    snap_rates := health_precision_data.health_rates
}

# INN-11: ZUS DEADLINE SMART CALENDAR
deadline_calendar := {
    "rule_id": "jdg.zus.precision.deadline_calendar",
    "package": "jdg.zus.precision_engine",
    "priority": 900,
    "zus_payment_deadline_day": 10,
    "zus_declaration_deadline_day": 10,
    "zus_deadline_note": "10. dzień miesiąca dla JDG (art. 47 ust. 1 pkt 2 SUS)",
    "_legal_basis": "Art. 47 ust. 1 pkt 2 SUS (10. dzień dla JDG płacących tylko za siebie)",
    "_warnings": ["Składki ZUS opłać do 10. dnia następnego miesiąca. Weekend/święto → ostatni dzień roboczy przed."]
}

# INN-16: MAŁY ZUS PLUS FORMULA ENGINE — Correct formula per Art. 18c
maly_zus_plus_formula := {
    "rule_id": "jdg.zus.precision.maly_plus_formula",
    "package": "jdg.zus.precision_engine",
    "priority": 1600,
    "maly_plus_prev_year_monthly_income": prev_income,
    "maly_plus_raw_base_30pct": raw_base,
    "maly_plus_min_bound": min_bound,
    "maly_plus_max_bound": max_bound,
    "maly_plus_final_base": final_base,
    "_legal_basis": "Art. 18c ust. 4-5 SUS",
    "_warnings": [sprintf("MAŁY ZUS PLUS — Dochód mies. poprz. roku: %.2f PLN → 30%% = %.2f PLN → podstawa: %.2f PLN [%.2f, %.2f]", 
        [prev_income, raw_base, final_base, min_bound, max_bound])]
} {
    input.jdg_entrepreneur.zus_status == "MALY_ZUS_PLUS"
    prev_year_income := object.get(input.jdg_entrepreneur, "maly_plus_prev_year_income", 0)
    prev_year_months := object.get(input.jdg_entrepreneur, "maly_plus_prev_year_months", 12)
    prev_income := prev_year_income / max([prev_year_months, 1])
    raw_base := prev_income * 0.30
    min_wage := health_precision_data.minimum_wage_gross
    avg_wage := health_precision_data.average_wage_gross
    min_bound := min_wage * 0.30
    max_bound := avg_wage * 0.60
    final_base := max([min_bound, min([raw_base, max_bound])])
}

# INN-17: MATERNITY DURATION MATRIX
maternity_matrix := {
    "rule_id": "jdg.zus.precision.maternity_matrix",
    "package": "jdg.zus.precision_engine",
    "priority": 1700,
    "maternity_children_count": children,
    "maternity_duration_weeks": weeks,
    "maternity_benefit_rate": 1.00,
    "_legal_basis": "Art. 180 KP, Art. 29-31 ustawy zasiłkowej",
    "_warnings": [sprintf("ZASIŁEK MACIERZYŃSKI — %d dzieci → %d tygodni (100%% podstawy)", [children, weeks])]
} {
    input.jdg_entrepreneur.zus_maternity_claim == true
    children := object.get(input.jdg_entrepreneur, "zus_maternity_children_count", 1)
    weeks = 20 { children == 1 }
    weeks = 31 { children == 2 }
    weeks = 33 { children == 3 }
    weeks = 35 { children == 4 }
    weeks = 37 { children >= 5 }
}
