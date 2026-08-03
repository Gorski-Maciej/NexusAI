# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P09 Ksiegowosc PKPiR + UoR + Amortyzacja Enterprise — testy rego
# (RAPORT P09 v8.0)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tests.p09_ksiegowosc

import future.keywords.in

# ── 1. Audyt struktury PKPiR (kolumny 1-17) ───────────────────────────────────
test_pkpir_structure_audit {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.pkpir_structure_audit with
        input as {"jdg_entrepreneur": {"p09_ksiegowosc_check": true}}
    result.matched == true
    result.column_count == 17
    result.required_columns == 14
    result.columns["7"].name == "Przychód — sprzedaż towarów i usług"
    result.columns["14"].name == "Razem wydatki (10+11+12+13)"
}

# ── 2. SILNIK DECYZJI "PKPiR czy UoR?" (INN-01 — PRIORYTET) ───────────────────
test_uor_obligation_engine_exceeds {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.uor_obligation_engine with
        input as {"jdg_entrepreneur": {"p09_ksiegowosc_check": true, "annual_revenue_pln": 9000000}}
    result.matched == true
    result.annual_revenue_eur == round(9000000 / 4.50 * 100) / 100
    result.threshold_eur == 2000000
    result.exceeds == true
    result.decision == "UoR"
}

test_uor_obligation_engine_early_warning {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.uor_obligation_engine with
        input as {"jdg_entrepreneur": {"p09_ksiegowosc_check": true, "annual_revenue_pln": 7500000}}
    result.exceeds == false
    result.early_warning == true
    result.decision == "PKPiR"
}

test_uor_obligation_engine_below {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.uor_obligation_engine with
        input as {"jdg_entrepreneur": {"p09_ksiegowosc_check": true, "annual_revenue_pln": 3000000}}
    result.exceeds == false
    result.early_warning == false
    result.decision == "PKPiR"
}

# ── 3. Walidator PKPiR realtime (INN-03) ──────────────────────────────────────
test_pkpir_validator_realtime {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.pkpir_validator_realtime with
        input as {"jdg_entrepreneur": {"p09_ksiegowosc_check": true}, "ledger": {
            "col_7": 1000, "col_8": 200, "income_col_9": 1200,
            "col_10": 300, "col_11": 50, "col_12": 100, "col_13": 150,
            "expenses_col_14": 600,
        }}
    result.income_ok == true
    result.expenses_ok == true
    result.consistent == true
}

# ── 4. Amortyzacja bilansowa vs podatkowa (INN-04) ────────────────────────────
test_amortization_dual_calculator {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.amortization_dual_calculator with
        input as {"jdg_entrepreneur": {"p09_ksiegowosc_check": true}, "asset": {"value": 100000, "kst_group": "4"}}
    result.tax_rate == 0.14
    result.tax_annual == 14000.0
    result.book_annual == 20000.0
    result.difference == 6000.0
}

# ── 5. Jednorazowa amortyzacja 100k EUR (INN-05) ──────────────────────────────
test_one_time_depreciation_audit {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.one_time_depreciation_audit with
        input as {"jdg_entrepreneur": {"p09_ksiegowosc_check": true, "new_assets_value": 350000}}
    result.limit_pln == 450000.0
    result.within_limit == true
    result.excess == 0
}

# ── 6. Limit aut osobowych 150k/225k (INN-06) ─────────────────────────────────
test_car_limit_audit {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.car_limit_audit with
        input as {"jdg_entrepreneur": {"p09_ksiegowosc_check": true}, "asset": {"car_value": 180000}}
    result.limit == 150000
    result.excess == 30000
}

test_car_limit_audit_electric {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.car_limit_audit with
        input as {"jdg_entrepreneur": {"p09_ksiegowosc_check": true}, "asset": {"car_value": 180000, "is_electric": true}}
    result.limit == 225000
    result.excess == 0
}

# ── 7. Symulator remanentu (INN-07) ───────────────────────────────────────────
test_remanent_simulator {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.remanent_simulator with
        input as {"jdg_entrepreneur": {"p09_ksiegowosc_check": true, "opening_remanent": 10000, "projected_closing_remanent": 45000}}
    result.income_impact_next_year == 35000.0
}

# ── 8. Symulator leasingu operacyjny vs finansowy (INN-14) ────────────────────
test_leasing_comparator {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.leasing_comparator with
        input as {"jdg_entrepreneur": {"p09_ksiegowosc_check": true}, "lease": {"monthly_rent": 2000, "interest_share": 0.20}}
    result.operating_kup_monthly == 2000.0
    result.financial_kup_monthly == 400.0
    result.annual_difference == 19200.0
    result.recommendation == "operacyjny"
}

# ── 9. Tracker progu UoR w trakcie roku (INN-10) ──────────────────────────────
test_uor_threshold_tracker {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.uor_threshold_tracker with
        input as {"jdg_entrepreneur": {"p09_ksiegowosc_check": true, "ytd_revenue_pln": 7500000}}
    result.ytd_revenue_eur == round(7500000 / 4.50 * 100) / 100
    result.threshold_eur == 2000000
    result.pct_of_threshold == 83.33
    result.early_warning_active == true
}

# ── 10. Transformacja PKPiR → UoR (Sekcja 5) ──────────────────────────────────
test_pkpir_uor_transformation_audit {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.pkpir_uor_transformation_audit with
        input as {"jdg_entrepreneur": {"p09_ksiegowosc_check": true}}
    result.transformer == "pkpir_to_uor_transformer (otwarcie ksiąg, migracja sald)"
    count(result.steps) == 5
    result.differences.revenue == "przychód memoriałowy (faktura) vs kasowy (zapłata)"
}

# ── 11. Pipeline auto-aktualizacji szablonów (Sekcja 6) ───────────────────────
test_accounting_pipeline_snapshot {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.accounting_pipeline_snapshot with
        input as {"jdg_entrepreneur": {"p09_ksiegowosc_check": true}}
    result.pipeline.step_1_ingest == "data.jdg.thresholds.accounting (ADR-002)"
    result.pipeline.step_4_emit == "hot-reload pakietów jdg.accounting / jdg.uor"
}

# ── 12. Główny decide (P09) + no_match ────────────────────────────────────────
test_p09_main_decide {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.decide with
        input as {"jdg_entrepreneur": {"p09_ksiegowosc_check": true, "annual_revenue_pln": 9000000}}
    result.matched == true
    result.rule_id == "jdg.p09_ksiegowosc_pkpir_uor_innovations.report"
    result._routing == "REPORT"
    result.uor_obligation.exceeds == true
}

test_p09_default_no_match {
    result := data.jdg.p09_ksiegowosc_pkpir_uor_innovations.decide with input as {"jdg_entrepreneur": {"annual_revenue_pln": 100000}}
    result.matched == false
    result.rule_id == "jdg.p09_ksiegowosc_pkpir_uor_innovations.no_match"
}
