# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for micro/ksef
# Generated: 2026-08-02T09:14:33.020531
# Package: jdg.micro.ksef
# Rules tested: 10
# Report: P27 R9 — Micro test split
# ═══════════════════════════════════════════════════════════════

package test_jdg_micro_ksef
import data.jdg.micro.ksef

# 1. jdg.micro.ksef.no_match
test_positive_no_match {
    result := data.jdg.micro.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ksef.no_match"
}

test_negative_no_match {
    result := data.jdg.micro.ksef.decide with input as {}
    result.rule_id != "jdg.micro.ksef.no_match"
}

# 2. jdg.micro.ksef.a106na.r1
test_positive_r1 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ksef.a106na.r1"
}

test_negative_r1 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.rule_id != "jdg.micro.ksef.a106na.r1"
}

# 3. jdg.micro.ksef.a106na.r2
test_positive_r2 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ksef.a106na.r2"
}

test_negative_r2 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.rule_id != "jdg.micro.ksef.a106na.r2"
}

# 4. jdg.micro.ksef.a106na.r3
test_positive_r3 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ksef.a106na.r3"
}

test_negative_r3 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.rule_id != "jdg.micro.ksef.a106na.r3"
}

# 5. jdg.micro.ksef.a106na.r4
test_positive_r4 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ksef.a106na.r4"
}

test_negative_r4 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.rule_id != "jdg.micro.ksef.a106na.r4"
}

# 6. jdg.micro.ksef.a106na.r5
test_positive_r5 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ksef.a106na.r5"
}

test_negative_r5 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.rule_id != "jdg.micro.ksef.a106na.r5"
}

# 7. jdg.micro.ksef.a106na.r6
test_positive_r6 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ksef.a106na.r6"
}

test_negative_r6 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.rule_id != "jdg.micro.ksef.a106na.r6"
}

# 8. jdg.micro.ksef.a106na.r7
test_positive_r7 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ksef.a106na.r7"
}

test_negative_r7 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.rule_id != "jdg.micro.ksef.a106na.r7"
}

# 9. jdg.micro.ksef.a106na.r8
test_positive_r8 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ksef.a106na.r8"
}

test_negative_r8 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.rule_id != "jdg.micro.ksef.a106na.r8"
}

# 10. jdg.micro.ksef.a106na.r9
test_positive_r9 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ksef.a106na.r9"
}

test_negative_r9 {
    result := data.jdg.micro.ksef.decide with input as {}
    result.rule_id != "jdg.micro.ksef.a106na.r9"
}
