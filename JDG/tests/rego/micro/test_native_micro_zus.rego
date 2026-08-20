# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests — ETAP 13 ZUS Micro
# Package: jdg.zus_micro_etap13
# Coverage: mapa atomów, okresy, świadczenia, property invariants,
#           testy negatywne / temporalne / graniczne / no-silent-default
# ═══════════════════════════════════════════════════════════════

package test_jdg_micro_zus

import data.jdg.zus_micro_etap13

ctx := {
    "evaluation_datetime": "2026-08-20T00:00:00Z",
    "evaluation_year": "2026",
    "threshold_version": "v9.0.0",
    "legal_basis_version": "v9.0.0",
    "facts_version": "v9.0.0",
}

# ── 1. MAPA ATOMÓW ──────────────────────────────────────────────
test_positive_atom_map_present {
    result := zus_micro_etap13.decide with input as object.union(ctx, {"zus_micro_etap13_check": true})
    result.matched == true
    result.atom_map.count > 0
    result.atom_map.count == 28
}

test_property_atom_map_has_all_five_fields {
    result := zus_micro_etap13.decide with input as object.union(ctx, {"zus_micro_etap13_check": true})
    result.atom_map.entries[0].ustawa != ""
    result.atom_map.entries[0].artykul != ""
    result.atom_map.entries[0].warunek != ""
    result.atom_map.entries[0].obliczenie != ""
    result.atom_map.entries[0].swiadectwo != ""
    result.atom_map.entries[0].test != ""
}

# ── 2. OKRESY UBEZPIECZENIA: zbieg / zawieszenie / przerwy ──────
test_temporal_concurrent_titles_jdg_plus_employment {
    result := zus_micro_etap13.decide with input as object.union(ctx, {
        "zus_micro_etap13_check": true,
        "jdg_entrepreneur": {"business_status": "ACTIVE"},
        "zus_micro": {"titles": [{"type": "JDG", "active": true}, {"type": "EMPLOYMENT", "active": true}]},
    })
    result.periods.concurrency == "CONCURRENT_JDG_EMPLOYMENT"
    result.periods.social_due == true
}

test_temporal_suspension_stops_social_but_not_health {
    result := zus_micro_etap13.decide with input as object.union(ctx, {
        "zus_micro_etap13_check": true,
        "jdg_entrepreneur": {"business_status": "SUSPENDED"},
    })
    result.periods.suspended == true
    result.periods.social_due == false
    result.periods.health_due == true
}

test_boundary_insurance_break_detected {
    result := zus_micro_etap13.decide with input as object.union(ctx, {
        "zus_micro_etap13_check": true,
        "jdg_entrepreneur": {"business_status": "ACTIVE"},
        "zus_micro": {"break_months": 3},
    })
    result.periods.insurance_gap == true
    result.periods.break_months == 3
}

# ── 3. ŚWIADCZENIA: chorobowe / macierzyńskie / opiekuńcze ──────
test_positive_chorobowe_80pct {
    result := zus_micro_etap13.decide with input as object.union(ctx, {
        "zus_micro_etap13_check": true,
        "zus_micro": {"benefit_type": "CHOROBOWE", "benefit_base": 3000, "benefit_days": 10, "hospitalization": false, "sickness_insurance_days": 100},
    })
    result.benefits.daily == 100.00
    result.benefits.rate == 0.80
    result.benefits.amount == 800.00
}

test_boundary_chorobowe_hospital_70pct {
    result := zus_micro_etap13.decide with input as object.union(ctx, {
        "zus_micro_etap13_check": true,
        "zus_micro": {"benefit_type": "CHOROBOWE", "benefit_base": 3000, "benefit_days": 10, "hospitalization": true},
    })
    result.benefits.rate == 0.70
    result.benefits.amount == 700.00
}

test_property_maternity_rate_is_one_and_140_days {
    result := zus_micro_etap13.decide with input as object.union(ctx, {
        "zus_micro_etap13_check": true,
        "zus_micro": {"benefit_type": "MACIERZYNSKIE", "benefit_base": 3000, "benefit_days": 140},
    })
    result.benefits.rate == 1.00
    result.benefits.amount == 14000.00
    result.property_invariants.maternity_rate_one == true
}

test_positive_opiekuncze_80pct {
    result := zus_micro_etap13.decide with input as object.union(ctx, {
        "zus_micro_etap13_check": true,
        "zus_micro": {"benefit_type": "OPIEKUNCZE", "benefit_base": 2400, "benefit_days": 5},
    })
    result.benefits.rate == 0.80
    result.benefits.amount == 320.00
}

# ── 4. TEMPORALNE: okres wyczekiwania (granica 89/90) ───────────
test_temporal_waiting_period_not_met_at_89 {
    result := zus_micro_etap13.decide with input as object.union(ctx, {
        "zus_micro_etap13_check": true,
        "zus_micro": {"benefit_type": "CHOROBOWE", "benefit_base": 3000, "benefit_days": 10, "sickness_insurance_days": 89},
    })
    result.benefits.waiting_met == false
}

test_boundary_waiting_period_met_at_90 {
    result := zus_micro_etap13.decide with input as object.union(ctx, {
        "zus_micro_etap13_check": true,
        "zus_micro": {"benefit_type": "CHOROBOWE", "benefit_base": 3000, "benefit_days": 10, "sickness_insurance_days": 90},
    })
    result.benefits.waiting_met == true
}

# ── 5. NEGATYWNE + NO SILENT DEFAULT ────────────────────────────
test_negative_missing_context_blocks {
    result := zus_micro_etap13.decide with input as {"zus_micro_etap13_check": true}
    result.routing == "BLOCK_AND_ALERT"
    result.manual_review == true
}

test_negative_benefit_missing_base_blocks {
    result := zus_micro_etap13.decide with input as object.union(ctx, {
        "zus_micro_etap13_check": true,
        "zus_micro": {"benefit_type": "CHOROBOWE", "benefit_base": 0, "benefit_days": 10},
    })
    result.routing == "BLOCK_AND_ALERT"
    result.property_invariants.no_silent_default == false
}

test_property_invariants_all_pass_for_valid_input {
    result := zus_micro_etap13.decide with input as object.union(ctx, {
        "zus_micro_etap13_check": true,
        "zus_micro": {"benefit_type": "MACIERZYNSKIE", "benefit_base": 3000, "benefit_days": 140},
    })
    count(result.invariant_failed) == 0
}

test_property_daily_le_base_and_amount_non_negative {
    result := zus_micro_etap13.decide with input as object.union(ctx, {
        "zus_micro_etap13_check": true,
        "zus_micro": {"benefit_type": "CHOROBOWE", "benefit_base": 3000, "benefit_days": 10},
    })
    result.property_invariants.daily_le_base == true
    result.property_invariants.amounts_non_negative == true
    result.property_invariants.rates_in_unit_interval == true
}

# ── 6. NO_MATCH (default — brak flagi) ──────────────────────────
test_no_match_without_activation_flag {
    result := zus_micro_etap13.decide with input as object.union(ctx, {})
    result.matched == false
    result.rule_id == "jdg.zus_micro_etap13.no_match"
}
