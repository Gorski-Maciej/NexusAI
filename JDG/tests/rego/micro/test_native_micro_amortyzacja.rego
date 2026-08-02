# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for micro/amortyzacja
# Generated: 2026-08-02T09:14:32.963461
# Package: jdg.micro.amort_a22a
# Rules tested: 13
# Report: P27 R9 — Micro test split
# ═══════════════════════════════════════════════════════════════

package test_jdg_micro_amort_a22a
import data.jdg.micro.amort_a22a

# 1. jdg.micro.amort_a22a.no_match
test_positive_no_match {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.amort_a22a.no_match"
}

test_negative_no_match {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.rule_id != "jdg.micro.amort_a22a.no_match"
}

# 2. jdg.micro.amort_a22a.r1
test_positive_r1 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.amort_a22a.r1"
}

test_negative_r1 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.rule_id != "jdg.micro.amort_a22a.r1"
}

# 3. jdg.micro.amort_a22a.r2
test_positive_r2 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.amort_a22a.r2"
}

test_negative_r2 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.rule_id != "jdg.micro.amort_a22a.r2"
}

# 4. jdg.micro.amort_a22a.r3
test_positive_r3 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.amort_a22a.r3"
}

test_negative_r3 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.rule_id != "jdg.micro.amort_a22a.r3"
}

# 5. jdg.micro.amort_a22a.r4
test_positive_r4 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.amort_a22a.r4"
}

test_negative_r4 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.rule_id != "jdg.micro.amort_a22a.r4"
}

# 6. jdg.micro.amort_a22a.r5
test_positive_r5 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.amort_a22a.r5"
}

test_negative_r5 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.rule_id != "jdg.micro.amort_a22a.r5"
}

# 7. jdg.micro.amort_a22a.r6
test_positive_r6 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.amort_a22a.r6"
}

test_negative_r6 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.rule_id != "jdg.micro.amort_a22a.r6"
}

# 8. jdg.micro.amort_a22a.r7
test_positive_r7 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.amort_a22a.r7"
}

test_negative_r7 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.rule_id != "jdg.micro.amort_a22a.r7"
}

# 9. jdg.micro.amort_a22a.r8
test_positive_r8 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.amort_a22a.r8"
}

test_negative_r8 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.rule_id != "jdg.micro.amort_a22a.r8"
}

# 10. jdg.micro.amort_a22a.r9
test_positive_r9 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.amort_a22a.r9"
}

test_negative_r9 {
    result := data.jdg.micro.amort_a22a.decide with input as {}
    result.rule_id != "jdg.micro.amort_a22a.r9"
}
