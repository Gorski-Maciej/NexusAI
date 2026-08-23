# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: PIT ZERO-DOUBT (PROMPT 04)
# Source: rules/pit/pit_enterprise_zero_doubt.rego
# Package: jdg.pit.zero_doubt
# Rules tested: solidarity_danina_30h (art. 30h), tp_related_parties_23m
# (art. 23m), tp_local_documentation_23w (art. 23w), tp_information_23zf
# (art. 23zf)
# ═══════════════════════════════════════════════════════════════

package test_jdg_pit_zero_doubt
import data.jdg.pit.zero_doubt

# 1. Danina solidarnościowa 4% (art. 30h PIT) — nadwyżka ponad 1 000 000 zł
test_positive_solidarity {
    result := data.jdg.pit.zero_doubt.decide with input as {
        "jdg_entrepreneur": {
            "solidarity_check": {"active": true, "solidarity_base_pln": 1500000}
        }
    }
    result.rule_id == "jdg.pit.zero_doubt.solidarity_danina_30h"
    result.matched == true
    result.solidarity.rate == 0.04
    result.solidarity.amount_pln == 20000
    result.solidarity.due_date == "2026-04-30"
}

test_negative_solidarity_below_threshold {
    result := data.jdg.pit.zero_doubt.decide with input as {
        "jdg_entrepreneur": {
            "solidarity_check": {"active": true, "solidarity_base_pln": 500000}
        }
    }
    result.rule_id != "jdg.pit.zero_doubt.solidarity_danina_30h"
}

# 2. Podmioty powiązane — znaczący wpływ >=25% (art. 23m ust. 2 pkt 1 PIT)
test_positive_related_capital {
    result := data.jdg.pit.zero_doubt.decide with input as {
        "jdg_entrepreneur": {
            "transfer_pricing": {"check": true, "influence_pct": 0.30}
        }
    }
    result.rule_id == "jdg.pit.zero_doubt.tp_related_parties_23m"
    result.transfer_pricing.related_parties == true
    result.transfer_pricing.influence_basis == "CAPITAL_OR_VOTES"
}

test_positive_related_family {
    result := data.jdg.pit.zero_doubt.decide with input as {
        "jdg_entrepreneur": {
            "transfer_pricing": {"check": true, "influence_pct": 0.05, "family_ties": true}
        }
    }
    result.rule_id == "jdg.pit.zero_doubt.tp_related_parties_family_23m"
    result.transfer_pricing.influence_basis == "FAMILY"
}

test_negative_related {
    result := data.jdg.pit.zero_doubt.decide with input as {
        "jdg_entrepreneur": {
            "transfer_pricing": {"check": true, "influence_pct": 0.05}
        }
    }
    result.rule_id != "jdg.pit.zero_doubt.tp_related_parties_23m"
    result.rule_id != "jdg.pit.zero_doubt.tp_related_parties_family_23m"
}

# 3. Lokalna dokumentacja TP (art. 23w ust. 2 PIT) — próg towarowy 10 000 000 zł
test_positive_tp_documentation_goods {
    result := data.jdg.pit.zero_doubt.decide with input as {
        "jdg_entrepreneur": {
            "transfer_pricing": {
                "related_parties": true,
                "transaction_type": "GOODS",
                "transaction_value_pln": 12000000
            }
        }
    }
    result.rule_id == "jdg.pit.zero_doubt.tp_local_documentation_23w"
    result.transfer_pricing.local_documentation_required == true
    result._routing == "BLOCK_AND_ALERT"
}

test_positive_tp_documentation_haven {
    result := data.jdg.pit.zero_doubt.decide with input as {
        "jdg_entrepreneur": {
            "transfer_pricing": {
                "related_parties": true,
                "transaction_type": "SERVICES",
                "transaction_value_pln": 600000,
                "haven_country": true
            }
        }
    }
    result.rule_id == "jdg.pit.zero_doubt.tp_local_documentation_23w"
    result.transfer_pricing.haven_country == true
}

test_negative_tp_documentation_below {
    result := data.jdg.pit.zero_doubt.decide with input as {
        "jdg_entrepreneur": {
            "transfer_pricing": {
                "related_parties": true,
                "transaction_type": "SERVICES",
                "transaction_value_pln": 1000000
            }
        }
    }
    result.rule_id != "jdg.pit.zero_doubt.tp_local_documentation_23w"
}

# 4. Informacja o cenach transferowych TP-R (art. 23zf ust. 1 PIT)
test_positive_tp_information {
    result := data.jdg.pit.zero_doubt.decide with input as {
        "jdg_entrepreneur": {
            "transfer_pricing": {
                "related_parties": true,
                "tp_information_obligation": true
            }
        }
    }
    result.rule_id == "jdg.pit.zero_doubt.tp_information_23zf"
    result.transfer_pricing.content_elements == 7
    result.transfer_pricing.arm_length_declaration == true
}

# 5. no_match — pusty input
test_no_match {
    result := data.jdg.pit.zero_doubt.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.pit.zero_doubt.no_match"
}
