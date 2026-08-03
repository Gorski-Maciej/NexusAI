# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Rego Tests: P06 PIT MICRO + AMORTYZACJA ENTERPRISE v9.0
# Sekcje: 1 (mapa pokrycia), 2 (amortyzacja — PRIORYTET), 3 (duplikaty/stuby),
#         4 (micro↔macro), 5 (obliczenia), 6 (pipeline), 7 (genius ideas)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.p06_pit_micro_enterprise_test

import future.keywords.in

# ── SEKCJA 1: MAPA POKRYCIA ARTYKUŁÓW PIT ─────────────────────────────────────

test_pit_coverage_report := {
    result := data.jdg.p06_pit_micro_innovations.pit_coverage_report
    result.coverage.total_priority_articles == 33
    result.coverage.complete >= 15
    result.coverage.missing >= 1
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p06_micro_audit_check": true}
} with data.jdg.pit_micro_audit as {
    "coverage": {
        "9": "COMPLETE", "10": "COMPLETE", "14": "COMPLETE", "21": "COMPLETE",
        "22": "COMPLETE", "22a": "COMPLETE", "23": "COMPLETE", "24": "COMPLETE",
        "26": "COMPLETE", "26e": "COMPLETE", "26h": "COMPLETE", "27": "COMPLETE",
        "30c": "COMPLETE", "44": "COMPLETE", "45": "COMPLETE", "45a": "COMPLETE",
        "13": "MISSING", "22o": "MISSING"
    }
}

# ── SEKCJA 2: AUDYT AMORTYZACJI (PRIORYTET) ───────────────────────────────────

test_amortization_calculator := {
    result := data.jdg.p06_pit_micro_innovations.amortization_calculator
    result.calculator.annual_depreciation == 14000.0
    result.calculator.years == 8
    result.calculator.kst_group == "4"
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p06_amort_check": true},
    "asset": {"value": 100000, "kst_group": "4"}
} with data.jdg.thresholds as {
    "amortization_limits": {"ONE_TIME_EUR_LIMIT": 100000, "SMALL_TAXPAYER_EUR": 2000000,
        "CAR_LIMIT_STANDARD": 150000, "CAR_LIMIT_ELECTRIC": 225000, "EUR_PLN_RATE": 4.3}
}

test_kst_rate_verifier := {
    result := data.jdg.p06_pit_micro_innovations.kst_rate_verifier
    result.verification.expected_rate == 0.14
    result.verification.correct == false
    result._routing == "TRIAGE_QUEUE"
} with input as {
    "jdg_entrepreneur": {"p06_amort_check": true},
    "asset": {"kst_group": "4", "declared_rate": 0.20}
} with data.jdg.thresholds as {
    "amortization_limits": {"ONE_TIME_EUR_LIMIT": 100000, "SMALL_TAXPAYER_EUR": 2000000,
        "CAR_LIMIT_STANDARD": 150000, "CAR_LIMIT_ELECTRIC": 225000, "EUR_PLN_RATE": 4.3}
}

test_one_time_amortization := {
    result := data.jdg.p06_pit_micro_innovations.one_time_amortization
    result.audit.eligible_small_taxpayer == true
    result.audit.eur_limit == 100000
    result.audit.within_limit == true
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p06_amort_check": true, "prev_year_revenue_eur": 1000000,
        "new_assets_value": 300000}
} with data.jdg.thresholds as {
    "amortization_limits": {"ONE_TIME_EUR_LIMIT": 100000, "SMALL_TAXPAYER_EUR": 2000000,
        "CAR_LIMIT_STANDARD": 150000, "CAR_LIMIT_ELECTRIC": 225000, "EUR_PLN_RATE": 4.3}
}

test_car_depreciation_audit := {
    result := data.jdg.p06_pit_micro_innovations.car_depreciation_audit
    result.audit.limit == 150000
    result.audit.deductible_base == 150000
    result.audit.excess == 50000
    result._routing == "TRIAGE_QUEUE"
} with input as {
    "jdg_entrepreneur": {"p06_amort_check": true},
    "asset": {"car_value": 200000, "is_electric": false}
} with data.jdg.thresholds as {
    "amortization_limits": {"ONE_TIME_EUR_LIMIT": 100000, "SMALL_TAXPAYER_EUR": 2000000,
        "CAR_LIMIT_STANDARD": 150000, "CAR_LIMIT_ELECTRIC": 225000, "EUR_PLN_RATE": 4.3}
}

test_car_electric_limit := {
    result := data.jdg.p06_pit_micro_innovations.car_depreciation_audit
    result.audit.limit == 225000
} with input as {
    "jdg_entrepreneur": {"p06_amort_check": true},
    "asset": {"car_value": 240000, "is_electric": true}
} with data.jdg.thresholds as {
    "amortization_limits": {"ONE_TIME_EUR_LIMIT": 100000, "SMALL_TAXPAYER_EUR": 2000000,
        "CAR_LIMIT_STANDARD": 150000, "CAR_LIMIT_ELECTRIC": 225000, "EUR_PLN_RATE": 4.3}
}

test_individual_rate_audit := {
    result := data.jdg.p06_pit_micro_innovations.individual_rate_audit
    result.audit.within_max == true
    result.audit.max_individual_rate == 0.28
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p06_amort_check": true},
    "asset": {"used_or_improved": true, "kst_group": "4", "declared_rate": 0.25}
} with data.jdg.thresholds as {
    "amortization_limits": {"ONE_TIME_EUR_LIMIT": 100000, "SMALL_TAXPAYER_EUR": 2000000,
        "CAR_LIMIT_STANDARD": 150000, "CAR_LIMIT_ELECTRIC": 225000, "EUR_PLN_RATE": 4.3}
}

# ── SEKCJA 3: DUPLIKATY I MARTWE REGUŁY ───────────────────────────────────────

test_pit_stub_duplicate_report := {
    result := data.jdg.p06_pit_micro_innovations.pit_stub_duplicate_report
    result.audit.duplicate_count >= 0
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p06_micro_audit_check": true}
} with data.jdg.pit_micro_audit as {
    "duplicates": ["jdg.micro.pit.a22.r1"],
    "stubs": [],
    "dead_rules": []
}

# ── SEKCJA 4: SPÓJNOŚĆ MICRO ↔ MACRO ──────────────────────────────────────────

test_pit_micro_macro_report := {
    result := data.jdg.p06_pit_micro_innovations.pit_micro_macro_report
    result.consistency.coherent == true
    result.consistency.macro_decisions_mapped == 2
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p06_micro_audit_check": true}
} with data.jdg.pit_micro_audit as {
    "macro_micro_map": {
        "art. 22": {"micro_priority": 10, "macro_priority": 500},
        "art. 23": {"micro_priority": 10, "macro_priority": 500}
    }
}

# ── SEKCJA 5: AUDYT OBLICZEŃ ──────────────────────────────────────────────────

test_pit_math_audit := {
    result := data.jdg.p06_pit_micro_innovations.pit_math_audit
    result.audit.rounding_ok == true
    result.audit.tax_free_amount == 30000
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p06_math_check": true, "advance_amount": 1200,
        "income_sources": [50000, 20000]}
} with data.jdg.thresholds as {
    "tax_free_amount": 30000
}

# ── SEKCJA 7: GENIALNE POMYSŁY ────────────────────────────────────────────────

test_amort_pit_impact := {
    result := data.jdg.p06_pit_micro_innovations.amort_pit_impact
    result.impact.tax_saving_scale == 1680.0
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p06_amort_check": true},
    "asset": {"value": 100000, "kst_group": "4"}
} with data.jdg.thresholds as {
    "amortization_limits": {"ONE_TIME_EUR_LIMIT": 100000, "SMALL_TAXPAYER_EUR": 2000000,
        "CAR_LIMIT_STANDARD": 150000, "CAR_LIMIT_ELECTRIC": 225000, "EUR_PLN_RATE": 4.3}
}

# ── GŁÓWNY RAPORT P06 ─────────────────────────────────────────────────────────

test_p06_main_decide := {
    result := data.jdg.p06_pit_micro_innovations.decide
    result.matched == true
    result.rule_id == "jdg.p06_pit_micro_innovations.report"
    result.p06_pit_micro.section2_amortization.kst_groups == 9
    result.p06_pit_micro.section2_amortization.one_time_eur_limit == 100000
    result.p06_pit_micro.section2_amortization.car_limit == 150000
    result.p06_pit_micro.section7_innovations.INN14_proof_of_correctness >= 1
    result._routing == "REPORT"
} with input as {
    "jdg_entrepreneur": {"p06_pit_micro_check": true}
} with data.jdg.pit_micro_audit as {
    "coverage": {
        "9": "COMPLETE", "10": "COMPLETE", "22": "COMPLETE", "23": "COMPLETE",
        "26e": "COMPLETE", "30c": "COMPLETE", "13": "MISSING"
    }
} with data.jdg.thresholds as {
    "amortization_limits": {"ONE_TIME_EUR_LIMIT": 100000, "SMALL_TAXPAYER_EUR": 2000000,
        "CAR_LIMIT_STANDARD": 150000, "CAR_LIMIT_ELECTRIC": 225000, "EUR_PLN_RATE": 4.3}
}

# ── DOMYŚLNE no_match (normalny ruch bez flag P06) ────────────────────────────

test_p06_default_no_match := {
    data.jdg.p06_pit_micro_innovations.decide.matched == false
    data.jdg.p06_pit_micro_innovations.decide.rule_id == "jdg.p06_pit_micro_innovations.no_match"
} with input as {
    "invoice": {"direction": "SALE", "amount_net": 1000},
    "jdg_entrepreneur": {"tax_form": "SCALE"}
}
