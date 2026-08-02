# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for micro/budownictwo
# Generated: 2026-08-02T09:14:32.988116
# Package: jdg.micro.budownictwo
# Rules tested: 10
# Report: P27 R9 — Micro test split
# ═══════════════════════════════════════════════════════════════

package test_jdg_micro_budownictwo
import data.jdg.micro.budownictwo

# 1. jdg.micro.budownictwo.no_match
test_positive_no_match {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.budownictwo.no_match"
}

test_negative_no_match {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.rule_id != "jdg.micro.budownictwo.no_match"
}

# 2. jdg.micro.budownictwo.a1.r1
test_positive_r1 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.budownictwo.a1.r1"
}

test_negative_r1 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.rule_id != "jdg.micro.budownictwo.a1.r1"
}

# 3. jdg.micro.budownictwo.a1.r2
test_positive_r2 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.budownictwo.a1.r2"
}

test_negative_r2 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.rule_id != "jdg.micro.budownictwo.a1.r2"
}

# 4. jdg.micro.budownictwo.a1.r3
test_positive_r3 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.budownictwo.a1.r3"
}

test_negative_r3 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.rule_id != "jdg.micro.budownictwo.a1.r3"
}

# 5. jdg.micro.budownictwo.a1.r4
test_positive_r4 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.budownictwo.a1.r4"
}

test_negative_r4 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.rule_id != "jdg.micro.budownictwo.a1.r4"
}

# 6. jdg.micro.budownictwo.a1.r5
test_positive_r5 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.budownictwo.a1.r5"
}

test_negative_r5 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.rule_id != "jdg.micro.budownictwo.a1.r5"
}

# 7. jdg.micro.budownictwo.a1.r6
test_positive_r6 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.budownictwo.a1.r6"
}

test_negative_r6 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.rule_id != "jdg.micro.budownictwo.a1.r6"
}

# 8. jdg.micro.budownictwo.a1.r7
test_positive_r7 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.budownictwo.a1.r7"
}

test_negative_r7 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.rule_id != "jdg.micro.budownictwo.a1.r7"
}

# 9. jdg.micro.budownictwo.a1.r8
test_positive_r8 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.budownictwo.a1.r8"
}

test_negative_r8 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.rule_id != "jdg.micro.budownictwo.a1.r8"
}

# 10. jdg.micro.budownictwo.a2.r1
test_positive_r1 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.budownictwo.a2.r1"
}

test_negative_r1 {
    result := data.jdg.micro.budownictwo.decide with input as {}
    result.rule_id != "jdg.micro.budownictwo.a2.r1"
}
