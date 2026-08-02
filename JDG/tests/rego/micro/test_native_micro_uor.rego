# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for micro/uor
# Generated: 2026-08-02T09:14:33.147143
# Package: jdg.micro.uor
# Rules tested: 10
# Report: P27 R9 — Micro test split
# ═══════════════════════════════════════════════════════════════

package test_jdg_micro_uor
import data.jdg.micro.uor

# 1. jdg.micro.uor.no_match
test_positive_no_match {
    result := data.jdg.micro.uor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.uor.no_match"
}

test_negative_no_match {
    result := data.jdg.micro.uor.decide with input as {}
    result.rule_id != "jdg.micro.uor.no_match"
}

# 2. jdg.micro.uor.a2.r1
test_positive_r1 {
    result := data.jdg.micro.uor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.uor.a2.r1"
}

test_negative_r1 {
    result := data.jdg.micro.uor.decide with input as {}
    result.rule_id != "jdg.micro.uor.a2.r1"
}

# 3. jdg.micro.uor.a2.r2
test_positive_r2 {
    result := data.jdg.micro.uor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.uor.a2.r2"
}

test_negative_r2 {
    result := data.jdg.micro.uor.decide with input as {}
    result.rule_id != "jdg.micro.uor.a2.r2"
}

# 4. jdg.micro.uor.a2.r3
test_positive_r3 {
    result := data.jdg.micro.uor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.uor.a2.r3"
}

test_negative_r3 {
    result := data.jdg.micro.uor.decide with input as {}
    result.rule_id != "jdg.micro.uor.a2.r3"
}

# 5. jdg.micro.uor.a2.r4
test_positive_r4 {
    result := data.jdg.micro.uor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.uor.a2.r4"
}

test_negative_r4 {
    result := data.jdg.micro.uor.decide with input as {}
    result.rule_id != "jdg.micro.uor.a2.r4"
}

# 6. jdg.micro.uor.a2.r5
test_positive_r5 {
    result := data.jdg.micro.uor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.uor.a2.r5"
}

test_negative_r5 {
    result := data.jdg.micro.uor.decide with input as {}
    result.rule_id != "jdg.micro.uor.a2.r5"
}

# 7. jdg.micro.uor.a2.r6
test_positive_r6 {
    result := data.jdg.micro.uor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.uor.a2.r6"
}

test_negative_r6 {
    result := data.jdg.micro.uor.decide with input as {}
    result.rule_id != "jdg.micro.uor.a2.r6"
}

# 8. jdg.micro.uor.a2.r7
test_positive_r7 {
    result := data.jdg.micro.uor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.uor.a2.r7"
}

test_negative_r7 {
    result := data.jdg.micro.uor.decide with input as {}
    result.rule_id != "jdg.micro.uor.a2.r7"
}

# 9. jdg.micro.uor.a2.r8
test_positive_r8 {
    result := data.jdg.micro.uor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.uor.a2.r8"
}

test_negative_r8 {
    result := data.jdg.micro.uor.decide with input as {}
    result.rule_id != "jdg.micro.uor.a2.r8"
}

# 10. jdg.micro.uor.a3.r1
test_positive_r1 {
    result := data.jdg.micro.uor.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.uor.a3.r1"
}

test_negative_r1 {
    result := data.jdg.micro.uor.decide with input as {}
    result.rule_id != "jdg.micro.uor.a3.r1"
}
