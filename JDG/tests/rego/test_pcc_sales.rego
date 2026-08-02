# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: PCC Sales Agreements (opa test)
# Package: jdg.pcc.sales_agreements
# Generated: 2026-08-02 — Q3 Critical Closure (P28 Grand Finale)
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pcc.sales_agreements_test

import data.jdg.pcc.sales_agreements

test_sale_of_movables_pcc_applies if {
    result := sales_agreements.decide with input as {
        "invoice": {
            "transaction_type": "SALE_OF_MOVABLES",
            "amount_gross": 5000,
            "has_vat": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.pcc.sales_agreements.a1.r3"
    result.pcc_rate == 0.01
}

test_sale_with_vat_excluded if {
    result := sales_agreements.decide with input as {
        "invoice": {
            "transaction_type": "SALE_OF_MOVABLES",
            "has_vat": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.pcc.sales_agreements.a1.r4"
}

test_vehicle_from_private_pcc_2pct if {
    result := sales_agreements.decide with input as {
        "invoice": {
            "transaction_type": "VEHICLE_FROM_PRIVATE",
            "amount_gross": 30000,
            "has_vat": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.pcc.sales_agreements.a1.r8"
    result.pcc_rate_vehicle == 0.02
}

test_under_threshold_no_pcc if {
    result := sales_agreements.decide with input as {
        "invoice": {
            "transaction_type": "SALE_OF_MOVABLES",
            "amount_gross": 500,
            "has_vat": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.pcc.sales_agreements.a1.r12"
    result.exemption_threshold == 1000
}

test_real_estate_pcc_2pct if {
    result := sales_agreements.decide with input as {
        "invoice": {
            "transaction_type": "SALE_OF_REAL_ESTATE"
        }
    }
    result.matched == true
    result.rule_id == "jdg.pcc.sales_agreements.a1.r2"
    result.pcc_rate == 0.02
}

test_family_first_group_exempt if {
    result := sales_agreements.decide with input as {
        "invoice": {
            "is_family_first_group": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.pcc.sales_agreements.a2.r7"
}

test_bankruptcy_sale_exempt if {
    result := sales_agreements.decide with input as {
        "invoice": {
            "is_bankruptcy_sale": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.pcc.sales_agreements.a2.r6"
}

test_undervalued_trigger if {
    result := sales_agreements.decide with input as {
        "invoice": {
            "transaction_type": "SALE_OF_MOVABLES",
            "amount_gross": 3000,
            "market_value": 10000,
            "has_vat": false
        }
    }
    result.matched == true
    result.rule_id == "jdg.pcc.sales_agreements.a1.r14"
    result._routing == "TRIAGE_QUEUE"
}

test_no_match if {
    result := sales_agreements.decide with input as {
        "invoice": {}
    }
    result.matched == false
    result.rule_id == "jdg.pcc.sales_agreements.no_match"
}
