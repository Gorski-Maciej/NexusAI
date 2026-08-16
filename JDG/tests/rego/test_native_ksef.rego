# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: micro KSeF (PROMPT 04)
# Source: rules/micro/ksef/ksef.rego (art. 106na-106nq VAT)
# Package: jdg.micro.ksef
# Rules tested: obowiązek KSeF (a106na), zwolnienia (a106na.r10),
#               tryb offline + ZAW-NR (a106ne)
# ═══════════════════════════════════════════════════════════════

package test_jdg_micro_ksef
import data.jdg.micro.ksef

# 1. jdg.micro.ksef.no_match — fallback
test_positive_no_match {
    result := data.jdg.micro.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ksef.no_match"
}

# 2. jdg.micro.ksef.a106na.r1 — obowiązek KSeF (warunek: business_type JDG)
test_positive_a106na_r1 {
    result := data.jdg.micro.ksef.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"}
    }
    result.rule_id == "jdg.micro.ksef.a106na.r1"
    result.matched == true
    result.micro_rule_active == true
}

test_negative_a106na_r1 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.rule_id != "jdg.micro.ksef.a106na.r1"
}

# 3. jdg.micro.ksef.a106na.r10 — zwolnieni z VAT (wyjątek KSeF)
test_positive_a106na_r10 {
    result := data.jdg.micro.ksef.decide with input as {
        "jdg_entrepreneur": {"cross_rule_interaction_2_ksef": true}
    }
    result.rule_id == "jdg.micro.ksef.a106na.r10"
    result.matched == true
    result._legal_basis != ""
}

# 4. jdg.micro.ksef.a106ne.r1 — tryb offline (grace 7 dni, art. 106ne)
test_positive_a106ne {
    result := data.jdg.micro.ksef.decide with input as {
        "jdg_entrepreneur": {"ksef_a106ne_r4_checks": true}
    }
    result.matched == true
    result._legal_basis != ""
}
