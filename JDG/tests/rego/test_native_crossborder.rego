# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests — P12 GLM52 CROSS-BORDER / TP / CFC / MDR
# Package: jdg.micro.crossborder_atomic_p12
# Rules tested: TP (23m related party, 23zf documentation, 23zb sanction),
#               CFC (30f classifier), exit tax (30da), MDR (86a scorer),
#               WHT (30a), residency (3), FX (14 ust. 2c)
# ═══════════════════════════════════════════════════════════════════════════════

package test_jdg_crossborder

import data.jdg.micro.crossborder_atomic_p12

# ── 1. TP ART. 23M — DETEKTOR POWIĄZAŃ (≥25%) ──────────────────────────────────
test_positive_related_party {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "tp_related_check": true,
            "related_party_share_pct": 0.30
        }
    } with data.jdg.thresholds as {"crossborder": {"tp_related_party_share_pct": 0.25}}
    result.matched == true
    result.rule_id == "jdg.micro.tp.a23m.related_party"
    result.tp_related_party == true
}

test_negative_related_party_below_threshold {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "tp_related_check": true,
            "related_party_share_pct": 0.10
        }
    }
    result.rule_id != "jdg.micro.tp.a23m.related_party"
}

# ── 2. TP ART. 23ZF — PROGI DOKUMENTACYJNE (10M/2M/2.5M) ───────────────────────
test_positive_documentation_threshold_goods {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "tp_doc_check": true,
            "tp_goods_value_pln": 12000000,
            "tp_services_value_pln": 0,
            "tp_financial_value_pln": 0
        }
    } with data.jdg.thresholds as {"crossborder": {
        "tp_goods_transactions_pln": 10000000,
        "tp_services_transactions_pln": 2000000,
        "tp_financial_transactions_pln": 2500000,
        "tp_documentation_months": 6
    }}
    result.rule_id == "jdg.micro.tp.a23zf.documentation_threshold"
    result.tp_documentation_required == true
}

test_negative_documentation_threshold_below {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "tp_doc_check": true,
            "tp_goods_value_pln": 100000,
            "tp_services_value_pln": 100000,
            "tp_financial_value_pln": 100000
        }
    }
    result.rule_id != "jdg.micro.tp.a23zf.documentation_threshold"
}

# ── 3. TP ART. 23ZB — RYZYKO KOREKTY (rozbieżność >10%) ────────────────────────
test_positive_tp_sanction_risk {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "tp_price_check": true,
            "tp_price_charged_pln": 12000,
            "tp_price_market_pln": 10000
        }
    } with data.jdg.thresholds as {"crossborder": {"tp_adjustment_sanction_pct": 0.10}}
    result.rule_id == "jdg.micro.tp.a23zb.sanction_risk"
    result.tp_adjustment_risk == true
}

test_negative_tp_sanction_risk_within {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "tp_price_check": true,
            "tp_price_charged_pln": 10800,
            "tp_price_market_pln": 10000
        }
    }
    result.rule_id != "jdg.micro.tp.a23zb.sanction_risk"
}

# ── 4. CFC ART. 30F — AUTO-KLASYFIKATOR (≥50%/≥33%/<14.25%) ────────────────────
test_positive_cfc_classified {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "cfc_check": true,
            "cfc_ownership_pct": 0.60,
            "cfc_passive_income_pct": 0.50,
            "cfc_foreign_tax_rate_pct": 0.10,
            "cfc_income_pln": 100000
        }
    } with data.jdg.thresholds as {"crossborder": {
        "cfc_ownership_min_pct": 0.50,
        "cfc_passive_income_pct": 0.33,
        "cfc_tax_rate_threshold_pct": 0.1425
    }}
    result.rule_id == "jdg.micro.cfc.a30f.classifier"
    result.cfc_classified == true
    result.cfc_attributed_income_pln == 60000
}

test_negative_cfc_not_controlled {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "cfc_check": true,
            "cfc_ownership_pct": 0.40,
            "cfc_passive_income_pct": 0.50,
            "cfc_foreign_tax_rate_pct": 0.10
        }
    }
    result.rule_id != "jdg.micro.cfc.a30f.classifier"
}

# ── 5. EXIT TAX ART. 30DA (próg 4M zł, 19%) ────────────────────────────────────
test_positive_exit_tax {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "exit_tax_check": true,
            "exit_tax_market_value_pln": 5000000
        }
    } with data.jdg.thresholds as {"crossborder": {
        "exit_tax_threshold_pln": 4000000,
        "exit_tax_rate_pct": 0.19
    }}
    result.rule_id == "jdg.micro.exit_tax.a30da.calculator"
    result.exit_tax_due == true
    result.exit_tax_pln == 950000
}

test_negative_exit_tax_below {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "exit_tax_check": true,
            "exit_tax_market_value_pln": 1000000
        }
    }
    result.rule_id != "jdg.micro.exit_tax.a30da.calculator"
}

# ── 6. MDR ART. 86A — SCORER (hallmark + MBT → raport w 30 dni) ────────────────
test_positive_mdr_reportable {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "mdr_check": true,
            "mdr_hallmark": "A",
            "mdr_main_benefit_test": true
        }
    } with data.jdg.thresholds as {"crossborder": {"mdr_deadline_days": 30}}
    result.rule_id == "jdg.micro.mdr.a86a.scorer"
    result.mdr_reportable == true
    result.mdr_deadline_days == 30
}

test_negative_mdr_not_reportable {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "mdr_check": true,
            "mdr_hallmark": "",
            "mdr_main_benefit_test": false
        }
    }
    result.rule_id != "jdg.micro.mdr.a86a.scorer"
}

# ── 7. WHT ART. 30A/29 (20% / 15% z UPDO + certyfikat) ─────────────────────────
test_positive_wht_updo_rate {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "wht_check": true,
            "wht_gross_pln": 10000,
            "wht_updo_applicable": true,
            "wht_residency_certificate": true
        }
    }
    result.rule_id == "jdg.micro.wht.a30a.rate"
    result.wht_rate_pct == 0.15
    result.wht_amount_pln == 1500
}

test_positive_wht_standard_rate {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "wht_check": true,
            "wht_gross_pln": 10000,
            "wht_updo_applicable": false,
            "wht_residency_certificate": false
        }
    }
    result.wht_rate_pct == 0.20
    result.wht_amount_pln == 2000
    result.wht_certificate_required == true
}

# ── 8. REZYDENCJA ART. 3 (183 dni lub centrum interesów) ───────────────────────
test_positive_residency_days {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "residency_check": true,
            "days_present_in_pl": 200,
            "center_of_life_interests_pl": false
        }
    } with data.jdg.thresholds as {"crossborder": {"residency_days": 183}}
    result.rule_id == "jdg.micro.residency.a3.tracker"
    result.polish_resident == true
}

test_negative_residency_not_met {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "residency_check": true,
            "days_present_in_pl": 100,
            "center_of_life_interests_pl": false
        }
    }
    result.rule_id != "jdg.micro.residency.a3.tracker"
}

# ── 9. FX ART. 14 UST. 2C (różnice kursowe, NBP time-travel) ───────────────────
test_positive_fx_difference {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE",
            "fx_check": true,
            "fx_amount_pln": 10000,
            "fx_rate_income_nbp": 4.29,
            "fx_rate_expense_nbp": 4.37
        }
    }
    result.rule_id == "jdg.micro.fx.a14.fx_difference"
    result.fx_difference_pln == 186.48
}

# ── 10. NO_MATCH — brak flagi domenowej → default (INV-018) ────────────────────
test_no_match_without_domain_flag {
    result := crossborder_atomic_p12.decide with input as {
        "jdg_entrepreneur": {
            "business_status": "ACTIVE"
        }
    }
    result.matched == false
    result.rule_id == "jdg.micro.crossborder_atomic_p12.no_match"
}
