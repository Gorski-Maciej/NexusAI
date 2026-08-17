# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests — P10 GLM52 KSIĘGOWOŚĆ PKPiR/UoR
# Package: jdg.micro.ksiegowosc_atomic_p10
# Rules tested: uor decision engine (a2), double entry (a22), inventory (a26),
#               year close (a12), book depreciation (a32), statements (a45),
#               PKPiR 17 columns, leasing classifier (17f), car limit 150k/225k
# ═══════════════════════════════════════════════════════════════════════════════

package test_jdg_ksiegowosc

import data.jdg.micro.ksiegowosc_atomic_p10

# ── 1. UoR ART. 2 — SILNIK DECYZJI PKPiR-czy-UoR (próg 2 000 000 EUR) ─────────
test_positive_uor_obligation_over_2m_eur {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "uor_decision_check": true,
            "annual_revenue_net_pln": 10000000,
            "eur_pln_rate": 4.50
        }
    } with data.jdg.thresholds as {"ksiegowosc": {"uor_threshold_eur": 2000000}}
    result.matched == true
    result.rule_id == "jdg.micro.uor.a2.decision_engine.r1"
    result.accounting_system == "UoR"
}

test_positive_pkpir_below_threshold {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "uor_decision_check": true,
            "annual_revenue_net_pln": 5000000,
            "eur_pln_rate": 4.50
        }
    }
    result.rule_id == "jdg.micro.uor.a2.decision_engine.r2"
    result.accounting_system == "PKPiR"
}

test_positive_threshold_monitor_95pct_zone {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "uor_decision_check": true,
            "annual_revenue_net_pln": 8640000,
            "eur_pln_rate": 4.50
        }
    } with data.jdg.thresholds as {"ksiegowosc": {"uor_threshold_eur": 2000000}}
    result.rule_id == "jdg.micro.uor.a2.threshold_monitor"
    result.uor_threshold_projection_pct == 96
}

# ── 2. UoR ART. 15/22 — PODWÓJNY ZAPIS (invariant ΣD = ΣC) ────────────────────
test_positive_double_entry_unbalanced {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "uor_double_entry_check": true,
            "debits_sum_pln": 1000.00,
            "credits_sum_pln": 999.99
        }
    }
    result.rule_id == "jdg.micro.uor.a22.double_entry"
    result.double_entry_balanced == false
    result._routing == "BLOCK_AND_ALERT"
}

test_positive_double_entry_balanced {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "uor_double_entry_check": true,
            "debits_sum_pln": 1000.00,
            "credits_sum_pln": 1000.00
        }
    }
    result.rule_id == "jdg.micro.uor.a22.double_entry_ok"
    result.double_entry_balanced == true
}

# ── 3. UoR ART. 26 — INWENTARYZACJA (cykl 4-letni) ─────────────────────────────
test_positive_inventory_due {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "uor_inventory_check": true,
            "years_since_last_inventory": 4
        }
    }
    result.rule_id == "jdg.micro.uor.a26.inventory_schedule"
    result.inventory_due == true
}

test_negative_inventory_not_due_yet {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "uor_inventory_check": true,
            "years_since_last_inventory": 2
        }
    }
    result.rule_id != "jdg.micro.uor.a26.inventory_schedule"
}

# ── 4. UoR ART. 12 — ZAMKNIĘCIE ROKU (12 kroków) ───────────────────────────────
test_positive_year_close_incomplete {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "uor_year_close_check": true,
            "year_close_steps_done": ["inwentaryzacja", "zamkniecie_ksieg"]
        }
    }
    result.rule_id == "jdg.micro.uor.a12.year_close"
    result.year_close_complete == false
    count(result.year_close_steps_missing) == 10
}

# ── 5. UoR ART. 32 — AMORTYZACJA KSIĘGOWA (liniowa/degresywna/jednorazowa) ────
test_positive_depreciation_one_time {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "uor_depreciation_check": true,
            "asset_value_pln": 300000,
            "one_time_depreciation": true
        }
    } with data.jdg.thresholds as {"ksiegowosc": {"depreciation_one_time_limit_eur": 100000, "eur_pln_rate_default": 4.50}}
    result.rule_id == "jdg.micro.uor.a32.book_depreciation.r1"
    result.book_depreciation_method == "JEDNORAZOWY"
    result.book_depreciation_annual_pln == 300000
}

test_positive_depreciation_linear {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "uor_depreciation_check": true,
            "asset_value_pln": 100000,
            "depreciation_rate": 0.2
        }
    }
    result.rule_id == "jdg.micro.uor.a32.book_depreciation.r2"
    result.book_depreciation_method == "LINIOWA"
    result.book_depreciation_annual_pln == 20000
}

test_positive_depreciation_degresive {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "uor_depreciation_check": true,
            "asset_value_pln": 100000,
            "depreciation_rate": 0.2,
            "degresive_depreciation": true
        }
    } with data.jdg.thresholds as {"ksiegowosc": {"depreciation_degresja_multiplier": 2.0}}
    result.rule_id == "jdg.micro.uor.a32.book_depreciation.r2"
    result.book_depreciation_method == "DEGRESYWNA"
    result.book_depreciation_annual_pln == 40000
}

# ── 6. UoR ART. 45-49 — SPRAWOZDANIE FINANSOWE (bilans: aktywa = pasywa) ───────
test_positive_balance_unbalanced {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "uor_statements_check": true,
            "assets_sum_pln": 500000,
            "liabilities_sum_pln": 450000
        }
    }
    result.rule_id == "jdg.micro.uor.a45.financial_statements"
    result.balance_sheet_balanced == false
}

test_positive_balance_balanced {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "uor_statements_check": true,
            "assets_sum_pln": 500000,
            "liabilities_sum_pln": 500000
        }
    }
    result.rule_id == "jdg.micro.uor.a45.financial_statements_ok"
    result.balance_sheet_balanced == true
}

# ── 7. PKPiR — WALIDATOR 17 KOLUMN (§10-12 rozp. MF 15.11.2025) ────────────────
test_positive_pkpir_row_incomplete {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "pkpir_row_check": true,
            "pkpir_columns_filled": ["col1_data", "col2_numer"]
        }
    }
    result.rule_id == "jdg.micro.pkpir.col17_validator"
    result.pkpir_row_complete == false
}

test_positive_pkpir_row_complete {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "pkpir_row_check": true,
            "pkpir_columns_filled": ["col1_data", "col2_numer", "col3_kontrahent", "col4_opis",
                "col5_przychod_wartosc", "col7_przychody_razem", "col10_zakupy_towary",
                "col12_zakupy_pozostale", "col14_amortyzacja", "col15_pozostale_wydatki",
                "col16_pozostale", "col17_uwagi"]
        }
    }
    result.rule_id == "jdg.micro.pkpir.col17_validator_ok"
    result.pkpir_row_complete == true
}

# ── 8. LEASING — KLASYFIKATOR OPERACYJNY/FINANSOWY (art. 17f ust. 1 PIT) ───────
test_positive_leasing_financial_value_test {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "leasing_classifier_check": true,
            "leasing_total_fees_pln": 95000,
            "leasing_asset_value_pln": 100000,
            "leasing_contract_years": 3,
            "leasing_normative_years": 5,
            "leasing_realestate": false
        }
    } with data.jdg.thresholds as {"ksiegowosc": {"leasing_value_test_pct": 90, "leasing_period_test_pct": 75}}
    result.rule_id == "jdg.micro.leasing.classifier.r1"
    result.leasing_type == "FINANSOWY"
}

test_positive_leasing_operational {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "leasing_classifier_check": true,
            "leasing_total_fees_pln": 50000,
            "leasing_asset_value_pln": 100000,
            "leasing_contract_years": 2,
            "leasing_normative_years": 5,
            "leasing_realestate": false
        }
    }
    result.rule_id == "jdg.micro.leasing.classifier.r2"
    result.leasing_type == "OPERACYJNY"
}

# ── 9. LIMIT SAMOCHODÓW 150k/225k (PIT art. 23 ust. 1 pkt 47a / VAT art. 86a) ──
test_positive_car_limit_excess_spalinowy {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "car_limit_check": true,
            "car_value_pln": 200000,
            "car_electric": false
        }
    } with data.jdg.thresholds as {"ksiegowosc": {"car_limit_150k": 150000, "car_limit_225k": 225000}}
    result.rule_id == "jdg.micro.leasing.car_limit"
    result.car_limit_pln == 150000
    result.car_excess_pln == 50000
}

test_positive_car_limit_electric_225k {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "car_limit_check": true,
            "car_value_pln": 200000,
            "car_electric": true
        }
    }
    result.rule_id == "jdg.micro.leasing.car_limit"
    result.car_limit_pln == 225000
    result.car_excess_pln == 0
}

test_negative_car_limit_within {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "car_limit_check": true,
            "car_value_pln": 100000,
            "car_electric": false
        }
    }
    result.rule_id != "jdg.micro.leasing.car_limit"
}

# ── 10. NO_MATCH — brak flagi domenowej → default (INV-018, zero catch-all) ────
test_no_match_without_domain_flag {
    result := ksiegowosc_atomic_p10.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE"
        }
    }
    result.matched == false
    result.rule_id == "jdg.micro.ksiegowosc_atomic_p10.no_match"
}
