# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for micro/ord
# Generated: 2026-08-02T09:14:33.026923
# Package: jdg.micro.ord
# Rules tested: 10
# Report: P27 R9 — Micro test split
# ═══════════════════════════════════════════════════════════════

package test_jdg_micro_ord
import data.jdg.micro.ord

# 1. jdg.micro.ord.no_match
test_positive_no_match {
    result := data.jdg.micro.ord.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ord.no_match"
}

test_negative_no_match {
    result := data.jdg.micro.ord.decide with input as {}
    result.rule_id != "jdg.micro.ord.no_match"
}

# 2. jdg.micro.ord.a16.r1
test_positive_r1 {
    result := data.jdg.micro.ord.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ord.a16.r1"
}

test_negative_r1 {
    result := data.jdg.micro.ord.decide with input as {}
    result.rule_id != "jdg.micro.ord.a16.r1"
}

# 3. jdg.micro.ord.a16.r2
test_positive_r2 {
    result := data.jdg.micro.ord.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ord.a16.r2"
}

test_negative_r2 {
    result := data.jdg.micro.ord.decide with input as {}
    result.rule_id != "jdg.micro.ord.a16.r2"
}

# 4. jdg.micro.ord.a16.r3
test_positive_r3 {
    result := data.jdg.micro.ord.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ord.a16.r3"
}

test_negative_r3 {
    result := data.jdg.micro.ord.decide with input as {}
    result.rule_id != "jdg.micro.ord.a16.r3"
}

# 5. jdg.micro.ord.a16.r4
test_positive_r4 {
    result := data.jdg.micro.ord.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ord.a16.r4"
}

test_negative_r4 {
    result := data.jdg.micro.ord.decide with input as {}
    result.rule_id != "jdg.micro.ord.a16.r4"
}

# 6. jdg.micro.ord.a16.r5
test_positive_r5 {
    result := data.jdg.micro.ord.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ord.a16.r5"
}

test_negative_r5 {
    result := data.jdg.micro.ord.decide with input as {}
    result.rule_id != "jdg.micro.ord.a16.r5"
}

# 7. jdg.micro.ord.a16.r6
test_positive_r6 {
    result := data.jdg.micro.ord.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ord.a16.r6"
}

test_negative_r6 {
    result := data.jdg.micro.ord.decide with input as {}
    result.rule_id != "jdg.micro.ord.a16.r6"
}

# 8. jdg.micro.ord.a20.r1
test_positive_r1 {
    result := data.jdg.micro.ord.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ord.a20.r1"
}

test_negative_r1 {
    result := data.jdg.micro.ord.decide with input as {}
    result.rule_id != "jdg.micro.ord.a20.r1"
}

# 9. jdg.micro.ord.a20.r2
test_positive_r2 {
    result := data.jdg.micro.ord.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ord.a20.r2"
}

test_negative_r2 {
    result := data.jdg.micro.ord.decide with input as {}
    result.rule_id != "jdg.micro.ord.a20.r2"
}

# 10. jdg.micro.ord.a20.r3
test_positive_r3 {
    result := data.jdg.micro.ord.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.ord.a20.r3"
}

test_negative_r3 {
    result := data.jdg.micro.ord.decide with input as {}
    result.rule_id != "jdg.micro.ord.a20.r3"
}
