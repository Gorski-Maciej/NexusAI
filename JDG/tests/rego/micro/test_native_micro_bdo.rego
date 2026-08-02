# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for micro/bdo
# Generated: 2026-08-02T09:14:32.982135
# Package: jdg.micro.bdo_ewc
# Rules tested: 14
# Report: P27 R9 — Micro test split
# ═══════════════════════════════════════════════════════════════

package test_jdg_micro_bdo_ewc
import data.jdg.micro.bdo_ewc

# 1. jdg.micro.bdo_ewc.no_match
test_positive_no_match {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.bdo_ewc.no_match"
}

test_negative_no_match {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.rule_id != "jdg.micro.bdo_ewc.no_match"
}

# 2. jdg.micro.bdo_ewc.r1
test_positive_r1 {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.bdo_ewc.r1"
}

test_negative_r1 {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.rule_id != "jdg.micro.bdo_ewc.r1"
}

# 3. jdg.micro.bdo_ewc.r2
test_positive_r2 {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.bdo_ewc.r2"
}

test_negative_r2 {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.rule_id != "jdg.micro.bdo_ewc.r2"
}

# 4. jdg.micro.bdo_ewc.r3
test_positive_r3 {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.bdo_ewc.r3"
}

test_negative_r3 {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.rule_id != "jdg.micro.bdo_ewc.r3"
}

# 5. jdg.micro.bdo_ewc.r4
test_positive_r4 {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.bdo_ewc.r4"
}

test_negative_r4 {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.rule_id != "jdg.micro.bdo_ewc.r4"
}

# 6. jdg.micro.bdo_ewc.r5
test_positive_r5 {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.bdo_ewc.r5"
}

test_negative_r5 {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.rule_id != "jdg.micro.bdo_ewc.r5"
}

# 7. jdg.micro.bdo_ewc.r6
test_positive_r6 {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.bdo_ewc.r6"
}

test_negative_r6 {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.rule_id != "jdg.micro.bdo_ewc.r6"
}

# 8. jdg.micro.bdo_ewc.r7
test_positive_r7 {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.bdo_ewc.r7"
}

test_negative_r7 {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.rule_id != "jdg.micro.bdo_ewc.r7"
}

# 9. jdg.micro.bdo_ewc.fallback
test_positive_fallback {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.bdo_ewc.fallback"
}

test_negative_fallback {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.rule_id != "jdg.micro.bdo_ewc.fallback"
}

# 10. jdg.micro.bdo_ewidencja.no_match
test_positive_no_match {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.bdo_ewidencja.no_match"
}

test_negative_no_match {
    result := data.jdg.micro.bdo_ewc.decide with input as {}
    result.rule_id != "jdg.micro.bdo_ewidencja.no_match"
}
