# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for R04 GLM52 PIT — CORE (MACRO) + ULGI
# Package: jdg.r04_pit_core_innovations
# Source: 04_PIT_CORE.txt (prompty_glm52)
# Generated: 2026-08-14
# ═══════════════════════════════════════════════════════════════════════════════

package test_r04_pit_core

import future.keywords.in

# ═══ DEFAULT: bez flagi r04_pit_core_check → no_match ═══

test_default_no_match {
    result := data.jdg.r04_pit_core_innovations.decide with input as {
        "jdg_entrepreneur": {"r04_pit_core_check": false}
    }
    result.matched == false
    result.rule_id == "jdg.r04_pit_core_innovations.no_match"
}

# ═══ R04-INN-01: 3-DROGOWY SYMULATOR ULG (B+R vs IP BOX vs ROBOTYZACJA) ═══

test_relief_whatif_br_wins {
    sim := data.jdg.r04_pit_core_innovations.relief_whatif_simulator with input as {
        "jdg_entrepreneur": {"r04_relief_whatif_check": true},
        "pit_relief_whatif": {
            "br_costs": 100000,
            "ipbox_income": 10000,
            "robotization_costs": 10000,
            "marginal_rate": 0.32,
        },
    }
    sim.simulator.best_relief == "BR"
    sim.simulator.br_saving == 32000
    sim.simulator.ipbox_saving == 2700
    sim.simulator.robot_saving == 1600
    sim.simulator.max_saving == 32000
}

test_relief_whatif_ipbox_wins {
    sim := data.jdg.r04_pit_core_innovations.relief_whatif_simulator with input as {
        "jdg_entrepreneur": {"r04_relief_whatif_check": true},
        "pit_relief_whatif": {
            "br_costs": 1000,
            "ipbox_income": 500000,
            "robotization_costs": 1000,
            "marginal_rate": 0.32,
        },
    }
    sim.simulator.best_relief == "IPBOX"
    sim.simulator.ipbox_saving == 135000
}

test_relief_whatif_robotization_wins {
    sim := data.jdg.r04_pit_core_innovations.relief_whatif_simulator with input as {
        "jdg_entrepreneur": {"r04_relief_whatif_check": true},
        "pit_relief_whatif": {
            "br_costs": 1000,
            "ipbox_income": 1000,
            "robotization_costs": 500000,
            "marginal_rate": 0.32,
        },
    }
    sim.simulator.best_relief == "ROBOTIZATION"
    sim.simulator.robot_saving == 80000
}

test_relief_whatif_no_input_zeroes {
    sim := data.jdg.r04_pit_core_innovations.relief_whatif_simulator with input as {
        "jdg_entrepreneur": {"r04_relief_whatif_check": true}
    }
    sim.simulator.br_costs == 0
    sim.simulator.ipbox_income == 0
    sim.simulator.robotization_costs == 0
    sim.simulator.best_relief == "BR"
}

# ═══ R04-INN-02: JEDNORAZOWA AMORTYZACJA 100K (art. 22k ust. 7-12) ═══

test_one_off_amortization_eligible {
    res := data.jdg.r04_pit_core_innovations.amortization_one_off_100k with input as {
        "jdg_entrepreneur": {"r04_one_off_amortization_check": true},
        "amortization_one_off": {
            "is_small_taxpayer": true,
            "kst_group": "3",
            "asset_value": 80000,
            "fully_amortized": true,
        },
    }
    res.amortization.eligible == true
    res.amortization.one_off_deduction == 80000
    res.amortization.remaining_limit == 20000
    res.amortization.annual_limit == 100000
}

test_one_off_amortization_capped_at_limit {
    res := data.jdg.r04_pit_core_innovations.amortization_one_off_100k with input as {
        "jdg_entrepreneur": {"r04_one_off_amortization_check": true},
        "amortization_one_off": {
            "is_small_taxpayer": true,
            "kst_group": "5",
            "asset_value": 250000,
            "fully_amortized": true,
        },
    }
    res.amortization.eligible == true
    res.amortization.one_off_deduction == 100000
    res.amortization.remaining_limit == 0
}

test_one_off_amortization_not_small_taxpayer {
    res := data.jdg.r04_pit_core_innovations.amortization_one_off_100k with input as {
        "jdg_entrepreneur": {"r04_one_off_amortization_check": true},
        "amortization_one_off": {
            "is_small_taxpayer": false,
            "kst_group": "3",
            "asset_value": 80000,
            "fully_amortized": true,
        },
    }
    res.amortization.eligible == false
    res.amortization.one_off_deduction == 0
}

test_one_off_amortization_real_estate_excluded {
    res := data.jdg.r04_pit_core_innovations.amortization_one_off_100k with input as {
        "jdg_entrepreneur": {"r04_one_off_amortization_check": true},
        "amortization_one_off": {
            "is_small_taxpayer": true,
            "kst_group": "1",
            "asset_value": 300000,
            "fully_amortized": true,
        },
    }
    res.amortization.eligible == false
    res.amortization.one_off_deduction == 0
}

# ═══ R04-INN-03: NISKOCENNE ŚRODKI TRWAŁE (art. 22f ust. 3 — 10 000 zł) ═══

test_low_value_eligible {
    res := data.jdg.r04_pit_core_innovations.low_value_asset_amortization with input as {
        "jdg_entrepreneur": {"r04_low_value_check": true},
        "low_value_asset": {"asset_value": 8000},
    }
    res.amortization.eligible == true
    res.amortization.one_off_cost == 8000
    res.amortization.threshold == 10000
}

test_low_value_at_threshold {
    res := data.jdg.r04_pit_core_innovations.low_value_asset_amortization with input as {
        "jdg_entrepreneur": {"r04_low_value_check": true},
        "low_value_asset": {"asset_value": 10000},
    }
    res.amortization.eligible == true
    res.amortization.one_off_cost == 10000
}

test_low_value_above_threshold {
    res := data.jdg.r04_pit_core_innovations.low_value_asset_amortization with input as {
        "jdg_entrepreneur": {"r04_low_value_check": true},
        "low_value_asset": {"asset_value": 12000},
    }
    res.amortization.eligible == false
    res.amortization.one_off_cost == 0
}

# ═══ R04-INN-04: KALKULATOR OPTYMALNEJ SKŁADKI ZDROWOTNEJ ═══

test_health_optimizer_scale_preferred {
    opt := data.jdg.r04_pit_core_innovations.health_contribution_optimizer with input as {
        "jdg_entrepreneur": {"r04_health_optimizer_check": true},
        "health_optimizer": {
            "annual_income": 60000,
            "annual_revenue": 70000,
            "lump_health_base": 6000,
        },
    }
    opt.optimizer.health_scale == 5400
    opt.optimizer.health_linear == 5400
    opt.optimizer.best_form == "SCALE"
}

test_health_optimizer_linear_preferred_high_income {
    opt := data.jdg.r04_pit_core_innovations.health_contribution_optimizer with input as {
        "jdg_entrepreneur": {"r04_health_optimizer_check": true},
        "health_optimizer": {
            "annual_income": 300000,
            "annual_revenue": 350000,
            "lump_health_base": 12000,
        },
    }
    opt.optimizer.best_form == "LINEAR"
}

test_health_optimizer_lump_preferred_high_revenue {
    opt := data.jdg.r04_pit_core_innovations.health_contribution_optimizer with input as {
        "jdg_entrepreneur": {"r04_health_optimizer_check": true},
        "health_optimizer": {
            "annual_income": 50000,
            "annual_revenue": 50000,
            "lump_health_base": 3000,
        },
    }
    opt.optimizer.best_form == "LUMP_SUM"
}

# ═══ RAPORT CORE: aktywna flaga ═══

test_pit_core_report {
    result := data.jdg.r04_pit_core_innovations.decide with input as {
        "jdg_entrepreneur": {"r04_pit_core_check": true},
        "pit_relief_whatif": {
            "br_costs": 100000,
            "ipbox_income": 10000,
            "robotization_costs": 10000,
            "marginal_rate": 0.32,
        },
        "amortization_one_off": {"is_small_taxpayer": true, "kst_group": "3", "asset_value": 80000, "fully_amortized": true},
        "low_value_asset": {"asset_value": 8000},
        "health_optimizer": {"annual_income": 60000, "annual_revenue": 70000, "lump_health_base": 6000},
    }
    result.matched == true
    result.rule_id == "jdg.r04_pit_core_innovations.pit_core_report"
    result._routing == "REPORT"
    result.pit_core.relief_whatif.best_relief == "BR"
    result.pit_core.one_off_amortization.one_off_deduction == 80000
    result.pit_core.low_value_amortization.eligible == true
    result.pit_core.health_optimizer.best_form == "SCALE"
}
