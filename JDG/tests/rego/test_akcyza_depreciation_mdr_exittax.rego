# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: Akcyza + Depreciation + MDR + Exit Tax
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.akcyza_depreciation_mdr_exittax_test

import data.jdg.akcyza.fuel_energy
import data.jdg.akcyza.alcohol_tobacco
import data.jdg.pit.depreciation
import data.jdg.mdr.hallmarks
import data.jdg.exit_tax_cfc

# ── Akcyza Fuel tests ─────────────────────────────────────────────────────────

test_motor_fuel_excise if {
    result := fuel_energy.decide with input as {
        "invoice": {"product_category": "MOTOR_FUEL"}
    }
    result.matched == true
    result.rule_id == "jdg.akcyza.fuel_energy.fuel.r1"
    result._routing == "BLOCK_AND_ALERT"
}

test_diesel_rate if {
    result := fuel_energy.decide with input as {
        "invoice": {"fuel_type": "DIESEL"}
    }
    result.matched == true
    result.rule_id == "jdg.akcyza.fuel_energy.fuel.r3"
    result.rate_per_1000l == 1206
}

test_electricity_end_user if {
    result := fuel_energy.decide with input as {
        "jdg_entrepreneur": {"is_end_user": true},
        "invoice": {"product_category": "ELECTRICITY"}
    }
    result.matched == true
    result.rule_id == "jdg.akcyza.fuel_energy.energy.r2"
}

# ── Akcyza Alcohol tests ──────────────────────────────────────────────────────

test_ethyl_alcohol_excise if {
    result := alcohol_tobacco.decide with input as {
        "invoice": {"product_category": "ETHYL_ALCOHOL"}
    }
    result.matched == true
    result.rule_id == "jdg.akcyza.alcohol_tobacco.alcohol.r1"
}

test_beer_rate if {
    result := alcohol_tobacco.decide with input as {
        "invoice": {"alcohol_type": "BEER"}
    }
    result.matched == true
    result.rule_id == "jdg.akcyza.alcohol_tobacco.alcohol.r3"
}

test_cigarette_excise if {
    result := alcohol_tobacco.decide with input as {
        "invoice": {"tobacco_type": "CIGARETTES"}
    }
    result.matched == true
    result.rule_id == "jdg.akcyza.alcohol_tobacco.tobacco.r2"
    result.rate_per_1000 == 367
}

# ── Depreciation tests ────────────────────────────────────────────────────────

test_fixed_asset_conditions if {
    result := depreciation.decide with input as {
        "invoice": {"expense_type": "FIXED_ASSET"}
    }
    result.matched == true
    result.rule_id == "jdg.pit.depreciation.a22a.r1"
}

test_low_value_one_off if {
    result := depreciation.decide with input as {
        "invoice": {
            "expense_type": "FIXED_ASSET",
            "amount_net": 5000,
            "asset_useful_life_months": 24
        }
    }
    result.matched == true
    result.rule_id in {"jdg.pit.depreciation.a22a.r3", "jdg.pit.depreciation.a22k.r1"}
}

test_one_off_limit_exceeded if {
    result := depreciation.decide with input as {
        "jdg_entrepreneur": {
            "is_small_taxpayer": true,
            "one_off_depreciation_used_ytd": 95000
        },
        "invoice": {
            "uses_one_off_depreciation": true,
            "amount_net": 15000
        }
    }
    result.matched == true
    result.rule_id == "jdg.pit.depreciation.a22d.r2"
}

test_kst_group1_building if {
    result := depreciation.decide with input as {
        "invoice": {"kst_group": 1}
    }
    result.matched == true
    result.rule_id == "jdg.pit.depreciation.kst.r2"
    result.rate_pct == 2.5
}

# ── MDR Hallmarks tests ───────────────────────────────────────────────────────

test_mdr_promoter_obligation if {
    result := hallmarks.decide with input as {
        "jdg_entrepreneur": {"is_mdr_promoter": true},
        "invoice": {"has_mdr_hallmark": true}
    }
    result.matched == true
    result.rule_id == "jdg.mdr.hallmarks.general.r1"
}

test_hallmark_a1_confidentiality if {
    result := hallmarks.decide with input as {
        "invoice": {
            "mdr_hallmark": "A1",
            "has_confidentiality_clause": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.mdr.hallmarks.a.confidentiality.r1"
}

test_hallmark_c1_tax_haven if {
    result := hallmarks.decide with input as {
        "invoice": {
            "mdr_hallmark": "C1",
            "payment_to_tax_haven": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.mdr.hallmarks.c.deductible_cross.r1"
}

# ── Exit Tax + CFC tests ──────────────────────────────────────────────────────

test_exit_tax_transfer if {
    result := exit_tax_cfc.decide with input as {
        "jdg_entrepreneur": {"transferring_assets_abroad": true},
        "invoice": {
            "asset_market_value": 500000,
            "asset_tax_value": 300000
        }
    }
    result.matched == true
    result.rule_id == "jdg.exit_tax_cfc.exit_tax.r1"
}

test_cfc_control if {
    result := exit_tax_cfc.decide with input as {
        "jdg_entrepreneur": {
            "foreign_company_stake_pct": 80,
            "foreign_cit_rate": 0.10
        }
    }
    result.matched == true
    result.rule_id == "jdg.exit_tax_cfc.cfc.r1"
}

test_pe_abroad if {
    result := exit_tax_cfc.decide with input as {
        "jdg_entrepreneur": {"has_permanent_establishment_abroad": true}
    }
    result.matched == true
    result.rule_id == "jdg.exit_tax_cfc.pe.r1"
}

test_wht_threshold_exceeded if {
    result := exit_tax_cfc.decide with input as {
        "jdg_entrepreneur": {
            "annual_foreign_payments_pln": 3000000,
            "has_tax_residence_certificates": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.exit_tax_cfc.wht.r2"
    result._routing == "BLOCK_AND_ALERT"
}
