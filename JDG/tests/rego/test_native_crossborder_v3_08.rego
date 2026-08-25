# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — NATIVE REGO TESTS: jdg.crossborder.v3_08 (Kampania V3, część 08)
# Uruchamiane przez `opa test JDG/rules JDG/tests/rego` (bramka CI).
# Lokalnie (bez binarki OPA) plik jest artefaktem kontraktowym — patrz raport 08.
# Konwencja: `v := ...decide with input as {...}` — modyfikator `with` dotyczy
# dokładnie jednego wyrażenia, dlatego każdy test wiąże wynik do zmiennej `v`.
# ═══════════════════════════════════════════════════════════════════════════════
package tests.test_native_crossborder_v3_08

import future.keywords.in

# T01: fail-closed — brak snapshotu progów blokuje domenę transgraniczną
test_v3_08_fail_closed_without_thresholds {
    v := data.jdg.crossborder.v3_08.decide with input as {"invoice": {}, "vendor": {"country": "DE"}}
         with data.jdg.thresholds as {}
    startswith(v.rule_id, "jdg.crossborder.v3_08.thresholds_missing")
    v._routing == "BLOCK_AND_ALERT"
}

# T02: exit tax — próg i stawka z thresholds (4M / 19%), wyzwalacz przeniesienia
test_v3_08_exit_tax_above_threshold {
    v := data.jdg.crossborder.v3_08.decide with input as {
        "jdg_entrepreneur": {"transferring_assets_abroad": true},
        "invoice": {"asset_market_value": 5000000, "asset_tax_value": 4000000},
    }
    v.rule_id == "jdg.crossborder.v3_08.exit_tax_calculator"
    v.exit_tax_applicable == true
    v.exit_tax_estimated_pln == 190000
    v.exit_tax_threshold_pln == 4000000
    v._routing == "BLOCK_AND_ALERT"
}

# T03: exit tax — poniżej progu → brak podatku, brak blokady
test_v3_08_exit_tax_below_threshold {
    v := data.jdg.crossborder.v3_08.decide with input as {
        "jdg_entrepreneur": {"transferring_assets_abroad": true},
        "invoice": {"asset_market_value": 1000000, "asset_tax_value": 200000},
    }
    v.rule_id == "jdg.crossborder.v3_08.exit_tax_calculator"
    v.exit_tax_applicable == false
    v.exit_tax_estimated_pln == 0
    v._routing == ""
}

# T04: CFC — podatek zagraniczny 10% < 14,25% → triggered, BLOCK_AND_ALERT
test_v3_08_cfc_low_tax_triggered {
    v := data.jdg.crossborder.v3_08.decide with input as {
        "jdg_entrepreneur": {
            "has_cfc": true,
            "cfc_ownership_pct": 60,
            "cfc_foreign_tax_rate_pct": 10,
            "cfc_passive_income_pct_raw": 10,
            "cfc_total_income_pln": 100000,
        },
    }
    v.rule_id == "jdg.crossborder.v3_08.cfc_monitor"
    v.cfc_triggered == true
    v.cfc_test_low_tax_1425 == true
    v._routing == "BLOCK_AND_ALERT"
    v.cfc_tax_due_pln == 11400
}

# T05: CFC — rzeczywista działalność EOG → zwolnienie (routing "")
test_v3_08_cfc_substantial_activity_exempt {
    v := data.jdg.crossborder.v3_08.decide with input as {
        "jdg_entrepreneur": {
            "has_cfc": true,
            "cfc_ownership_pct": 60,
            "cfc_foreign_tax_rate_pct": 10,
            "cfc_passive_income_pct_raw": 10,
            "cfc_total_income_pln": 100000,
            "cfc_substantial_activity_eea": true,
        },
    }
    v.cfc_exempt_substantial_activity == true
    v._routing == ""
}

# T06: WHT — 2,5M PLN bez certyfikatu → pay-and-refund (BLOCK_AND_ALERT)
test_v3_08_wht_pay_and_refund {
    v := data.jdg.crossborder.v3_08.decide with input as {
        "jdg_entrepreneur": {"annual_foreign_payments_pln": 2500000},
        "invoice": {},
        "vendor": {},
    }
    v.rule_id == "jdg.crossborder.v3_08.wht_gate"
    v.wht_obligation_exceeded == true
    v.wht_pay_and_refund_required == true
    v.wht_threshold_pln == 2000000
}

# T07: DAC8 — operator platformy 2500 EUR (>2000 EUR z thresholds) → raportowanie
test_v3_08_dac8_reportable {
    v := data.jdg.crossborder.v3_08.decide with input as {
        "jdg_entrepreneur": {
            "platform_operator": true,
            "dac8_total_amount_eur": 2500,
            "dac8_total_transactions": 5,
        },
    }
    v.rule_id == "jdg.crossborder.v3_08.dac8_engine"
    v.dac8_reportable == true
    v.dac8_threshold_eur == 2000
    v.dac8_threshold_tx == 30
}

# T08: UK B2C — 95k GBP > 90k GBP → obowiązek rejestracji VAT UK
test_v3_08_uk_b2c_over_threshold {
    v := data.jdg.crossborder.v3_08.decide with input as {
        "jdg_entrepreneur": {"uk_b2c_annual_turnover_gbp": 95000},
        "invoice": {"direction": "SALE"},
        "vendor": {"country": "GB", "is_b2c": true},
    }
    v.rule_id == "jdg.crossborder.v3_08.uk_vat_b2c_gate"
    v.uk_vat_registration_required == true
    v.uk_vat_threshold_gbp == 90000
}

# T09: TP — usługi 2,1M PLN > próg aktualny 2M → dokumentacja wymagana (L-08-006)
test_v3_08_tp_current_law_services {
    v := data.jdg.crossborder.v3_08.decide with input as {
        "vendor": {"is_related_party": true},
        "tp": {"annual_services_value_pln": 2100000},
    }
    v.rule_id == "jdg.crossborder.v3_08.tp_thresholds_current_law"
    v.tp_documentation_required_current_law == true
    v.tp_threshold_services_pln == 2000000
    v.tp_supersedes_plan45_legacy_thresholds == true
}

# T10: MDR — promotor + hallmark + transgraniczne → MDR-1 w 30 dni z thresholds
test_v3_08_mdr_promoter_deadline {
    v := data.jdg.crossborder.v3_08.decide with input as {
        "jdg_entrepreneur": {"is_mdr_promoter": true},
        "invoice": {"has_mdr_hallmark": true, "is_cross_border": true},
    }
    v.rule_id == "jdg.crossborder.v3_08.mdr_deadline_guard"
    v.mdr_filing_obligation == true
    v.mdr_deadline_days == 30
}

# T11: Decision Certificate — catch-all domeny z pełnym audytem (V2 F3/F4)
test_v3_08_decision_certificate_catch_all {
    v := data.jdg.crossborder.v3_08.decide with input as {
        "invoice": {"direction": "PURCHASE"},
        "vendor": {"country": "CZ"},
    }
    v.rule_id == "jdg.crossborder.v3_08.decision_certificate"
    v.cb_cross_border_detected == true
    count(v.cb_domain_packages_wired) >= 12
}

# T12: krajowy PL → certyfikat bez TRIAGE (detected=false)
test_v3_08_domestic_not_flagged {
    v := data.jdg.crossborder.v3_08.decide with input as {
        "invoice": {},
        "vendor": {"country": "PL"},
    }
    v.cb_cross_border_detected == false
}
