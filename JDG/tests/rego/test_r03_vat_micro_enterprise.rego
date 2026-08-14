# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for R03 GLM52 VAT — WARSTWA MICRO
# Packages: jdg.r03_vat_micro_innovations, jdg.micro.vat.r03
# Source: 03_VAT_WARSTWA_MICRO.txt (prompty_glm52)
# Generated: 2026-08-14
# ═══════════════════════════════════════════════════════════════════════════════

package test_r03_vat_micro

import future.keywords.in

# ═══ DEFAULT: bez flagi r03_vat_micro_check → no_match ═══

test_default_no_match {
    result := data.jdg.r03_vat_micro_innovations.decide with input as {
        "jdg_entrepreneur": {"r03_vat_micro_check": false}
    }
    result.matched == false
    result.rule_id == "jdg.r03_vat_micro_innovations.no_match"
}

test_micro_articles_default_no_match {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a28b_check": false, "vat_a87_check": false, "vat_a91_check": false, "vat_a106a_check": false, "vat_a106i_check": false}
    }
    result.matched == false
    result.rule_id == "jdg.micro.vat.r03.no_match"
}

# ═══ R03-INN-01: ARTICLE COVERAGE MONITOR ═══

test_coverage_monitor_all_complete {
    monitor := data.jdg.r03_vat_micro_innovations.article_coverage_monitor with input as {
        "vat_micro_coverage": {"5": "COMPLETE", "7": "COMPLETE", "8": "COMPLETE", "15": "COMPLETE", "17": "COMPLETE", "19a": "COMPLETE", "20": "COMPLETE", "21": "COMPLETE", "28b": "COMPLETE", "29a": "COMPLETE", "41": "COMPLETE", "43": "COMPLETE", "86": "COMPLETE", "86a": "COMPLETE", "87": "COMPLETE", "88": "COMPLETE", "89a": "COMPLETE", "89b": "COMPLETE", "90": "COMPLETE", "91": "COMPLETE", "96": "COMPLETE", "99": "COMPLETE", "103": "COMPLETE", "106a": "COMPLETE", "106e": "COMPLETE", "106i": "COMPLETE", "106n": "COMPLETE", "108a": "COMPLETE", "113": "COMPLETE", "120": "COMPLETE"}
    }
    monitor.key_articles_total == 30
    monitor.covered == 30
    monitor.partial == 0
    monitor.missing_count == 0
}

test_coverage_monitor_detects_missing {
    monitor := data.jdg.r03_vat_micro_innovations.article_coverage_monitor with input as {
        "vat_micro_coverage": {"5": "COMPLETE", "87": "PARTIAL"}
    }
    monitor.missing_count == 28
    "87" not in monitor.missing
    "106a" in monitor.missing
}

# ═══ R03-INN-02: MICRO↔MACRO BINDING ═══

test_micro_macro_binding {
    binding := data.jdg.r03_vat_micro_innovations.micro_macro_binding
    binding.bindings_total == 30
    binding.bindings["91"] == "jdg.vat_deductions_audit"
    binding.bindings["28b"] == "jdg.vat.place_of_supply"
    binding.bindings["106e"] == "jdg.ksef_jpk"
    binding.bindings["108a"] == "jdg.vat_mpp_split_payment"
}

# ═══ R03-INN-03: MICRO↔MACRO CONSISTENCY CHECK (INV-018) ═══

test_consistency_no_conflicts {
    check := data.jdg.r03_vat_micro_innovations.micro_consistency_check with input as {
        "micro_verdicts": {
            "91": {"matched": true, "vat_rate": "23%"},
            "106e": {"matched": true, "vat_rate": "23%"},
        },
        "macro_verdicts": {
            "jdg.vat_deductions_audit": {"matched": true, "vat_rate": "23%"},
            "jdg.ksef_jpk": {"matched": true, "vat_rate": "23%"},
        },
    }
    check.conflict_count == 0
    check.matched_micro_articles == 2
}

test_consistency_detects_rate_mismatch {
    check := data.jdg.r03_vat_micro_innovations.micro_consistency_check with input as {
        "micro_verdicts": {
            "91": {"matched": true, "vat_rate": "23%"},
            "43": {"matched": true, "vat_rate": "0%"},
        },
        "macro_verdicts": {
            "jdg.vat_deductions_audit": {"matched": true, "vat_rate": "8%"},
            "jdg.vat_rates_audit": {"matched": true, "vat_rate": "0%"},
        },
    }
    check.conflict_count == 1
    check.conflicts[0].article == "91"
    check.conflicts[0].type == "RATE_MISMATCH"
    check.conflicts[0].resolution == "TRIAGE"
}

# ═══ ATOMOWE ARTYKUŁY (jdg.micro.vat.r03) ═══

test_micro_a28b_b2b_place_of_supply {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a28b_check": true},
        "invoice": {"is_b2b": true}
    }
    result.matched == true
    result.rule_id == "jdg.vat.a28b.r1"
    result.place_of_supply == "BUYER_ESTABLISHMENT"
    result.b2b == true
    result.micro_rule_active == true
}

test_micro_a28b_not_b2b_no_match {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a28b_check": true},
        "invoice": {"is_b2b": false}
    }
    result.matched == false
}

test_micro_a87_refund_standard {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a87_check": true, "excess_vat_pln": 5000, "is_small_taxpayer": false}
    }
    result.matched == true
    result.rule_id == "jdg.vat.a87.r1"
    result.refund.refund_days_final == 60
    result.refund.refund_method == "BANK_ACCOUNT"
    result.refund.carry_forward_available == true
}

test_micro_a87_small_taxpayer_25_days {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a87_check": true, "excess_vat_pln": 5000, "is_small_taxpayer": true}
    }
    result.matched == true
    result.refund.refund_days_final == 25
}

test_micro_a91_real_estate_10_years {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a91_check": true},
        "asset": {"is_fixed_asset": true, "asset_type": "REAL_ESTATE", "value_net": 500000}
    }
    result.matched == true
    result.rule_id == "jdg.vat.a91.r1"
    result.correction.period_years == 10
}

test_micro_a91_machinery_5_years {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a91_check": true},
        "asset": {"is_fixed_asset": true, "asset_type": "MACHINERY", "value_net": 100000}
    }
    result.matched == true
    result.correction.period_years == 5
}

test_micro_a91_small_asset_1_year {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a91_check": true},
        "asset": {"is_fixed_asset": true, "asset_type": "EQUIPMENT", "value_net": 5000}
    }
    result.matched == true
    result.correction.period_years == 1
}

test_micro_a106a_invoice_required {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a106a_check": true},
        "invoice": {"document_type": "INVOICE", "is_b2b": true}
    }
    result.matched == true
    result.rule_id == "jdg.vat.a106a.r1"
    result.invoicing.invoice_required == true
    result.invoicing.b2b == true
}

test_micro_a106a_receipt_with_nip {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a106a_check": true},
        "invoice": {"document_type": "RECEIPT", "receipt_with_nip": true}
    }
    result.matched == true
    result.invoicing.receipt_with_nip_qualifies == true
}

test_micro_a106i_deadline_15th {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a106i_check": true},
        "invoice": {"document_type": "INVOICE", "invoice_days_late": 0}
    }
    result.matched == true
    result.rule_id == "jdg.vat.a106i.r1"
    result.deadline.rule == "15TH_DAY_NEXT_MONTH"
    result.deadline.deadline_day == 15
    result.deadline.on_demand_days == 7
    result.deadline.late_invoice_risk == false
}

test_micro_a106i_late_risk {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a106i_check": true},
        "invoice": {"document_type": "INVOICE", "invoice_days_late": 3}
    }
    result.matched == true
    result.deadline.late_invoice_risk == true
}

# ═══ RAPORT MICRO: aktywna flaga ═══

test_vat_micro_report {
    result := data.jdg.r03_vat_micro_innovations.decide with input as {
        "jdg_entrepreneur": {"r03_vat_micro_check": true},
        "vat_micro_coverage": {"5": "COMPLETE", "28b": "COMPLETE", "91": "COMPLETE"},
        "micro_verdicts": {"91": {"matched": true, "vat_rate": "23%"}},
        "macro_verdicts": {"jdg.vat_deductions_audit": {"matched": true, "vat_rate": "23%"}},
    }
    result.matched == true
    result.rule_id == "jdg.r03_vat_micro_innovations.vat_micro_report"
    result._routing == "REPORT"
    result.vat_micro.article_coverage.key_articles_total == 30
    result.vat_micro.micro_macro_binding.bindings_total == 30
    result.vat_micro.micro_consistency.conflict_count == 0
}
