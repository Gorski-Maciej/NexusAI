# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for micro/crossborder
# Generated: 2026-08-02T09:14:33.001125
# Package: jdg.micro.crossborder
# Rules tested: 10
# Report: P27 R9 — Micro test split
# ═══════════════════════════════════════════════════════════════

package test_jdg_micro_crossborder
import data.jdg.micro.crossborder

# 1. jdg.micro.crossborder.no_match
test_positive_no_match {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.crossborder.no_match"
}

test_negative_no_match {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.rule_id != "jdg.micro.crossborder.no_match"
}

# 2. jdg.micro.crossborder.a23o.r1
test_positive_r1 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.crossborder.a23o.r1"
}

test_negative_r1 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.rule_id != "jdg.micro.crossborder.a23o.r1"
}

# 3. jdg.micro.crossborder.a23o.r2
test_positive_r2 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.crossborder.a23o.r2"
}

test_negative_r2 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.rule_id != "jdg.micro.crossborder.a23o.r2"
}

# 4. jdg.micro.crossborder.a23o.r3
test_positive_r3 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.crossborder.a23o.r3"
}

test_negative_r3 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.rule_id != "jdg.micro.crossborder.a23o.r3"
}

# 5. jdg.micro.crossborder.a23o.r4
test_positive_r4 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.crossborder.a23o.r4"
}

test_negative_r4 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.rule_id != "jdg.micro.crossborder.a23o.r4"
}

# 6. jdg.micro.crossborder.a23o.r5
test_positive_r5 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.crossborder.a23o.r5"
}

test_negative_r5 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.rule_id != "jdg.micro.crossborder.a23o.r5"
}

# 7. jdg.micro.crossborder.a23o.r6
test_positive_r6 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.crossborder.a23o.r6"
}

test_negative_r6 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.rule_id != "jdg.micro.crossborder.a23o.r6"
}

# 8. jdg.micro.crossborder.a23o.r7
test_positive_r7 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.crossborder.a23o.r7"
}

test_negative_r7 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.rule_id != "jdg.micro.crossborder.a23o.r7"
}

# 9. jdg.micro.crossborder.a23o.r8
test_positive_r8 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.crossborder.a23o.r8"
}

test_negative_r8 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.rule_id != "jdg.micro.crossborder.a23o.r8"
}

# 10. jdg.micro.crossborder.a23o.r9
test_positive_r9 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.crossborder.a23o.r9"
}

test_negative_r9 {
    result := data.jdg.micro.crossborder.decide with input as {}
    result.rule_id != "jdg.micro.crossborder.a23o.r9"
}
