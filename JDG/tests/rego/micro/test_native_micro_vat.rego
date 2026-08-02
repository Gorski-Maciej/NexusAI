# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for micro/vat
# Generated: 2026-08-02T09:14:33.169307
# Package: jdg.micro.vat.ksef
# Rules tested: 15
# Report: P27 R9 — Micro test split
# ═══════════════════════════════════════════════════════════════

package test_jdg_micro_vat_ksef
import data.jdg.micro.vat.ksef

# 1. jdg.micro.vat.ksef.no_match
test_positive_no_match {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.vat.ksef.no_match"
}

test_negative_no_match {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.rule_id != "jdg.micro.vat.ksef.no_match"
}

# 2. jdg.micro.vat.ksef.ksef_m01
test_positive_ksef_m01 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.vat.ksef.ksef_m01"
}

test_negative_ksef_m01 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.rule_id != "jdg.micro.vat.ksef.ksef_m01"
}

# 3. jdg.micro.vat.ksef.ksef_m02
test_positive_ksef_m02 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.vat.ksef.ksef_m02"
}

test_negative_ksef_m02 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.rule_id != "jdg.micro.vat.ksef.ksef_m02"
}

# 4. jdg.micro.vat.ksef.ksef_m03
test_positive_ksef_m03 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.vat.ksef.ksef_m03"
}

test_negative_ksef_m03 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.rule_id != "jdg.micro.vat.ksef.ksef_m03"
}

# 5. jdg.micro.vat.ksef.ksef_m04
test_positive_ksef_m04 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.vat.ksef.ksef_m04"
}

test_negative_ksef_m04 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.rule_id != "jdg.micro.vat.ksef.ksef_m04"
}

# 6. jdg.micro.vat.ksef.ksef_m05
test_positive_ksef_m05 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.vat.ksef.ksef_m05"
}

test_negative_ksef_m05 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.rule_id != "jdg.micro.vat.ksef.ksef_m05"
}

# 7. jdg.micro.vat.ksef.ksef_m06
test_positive_ksef_m06 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.vat.ksef.ksef_m06"
}

test_negative_ksef_m06 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.rule_id != "jdg.micro.vat.ksef.ksef_m06"
}

# 8. jdg.micro.vat.ksef.ksef_m07
test_positive_ksef_m07 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.vat.ksef.ksef_m07"
}

test_negative_ksef_m07 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.rule_id != "jdg.micro.vat.ksef.ksef_m07"
}

# 9. jdg.micro.vat.ksef.ksef_m08
test_positive_ksef_m08 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.vat.ksef.ksef_m08"
}

test_negative_ksef_m08 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.rule_id != "jdg.micro.vat.ksef.ksef_m08"
}

# 10. jdg.micro.vat.ksef.ksef_m09
test_positive_ksef_m09 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.micro.vat.ksef.ksef_m09"
}

test_negative_ksef_m09 {
    result := data.jdg.micro.vat.ksef.decide with input as {}
    result.rule_id != "jdg.micro.vat.ksef.ksef_m09"
}
