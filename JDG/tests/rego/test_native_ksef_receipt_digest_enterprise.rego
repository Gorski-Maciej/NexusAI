# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for: ksef_receipt_digest_enterprise
# Source: ksef_receipt_digest_enterprise.rego
# Generated: 2026-08-02T09:14:32.232514
# Package: jdg.ksef_receipt_digest
# Rules tested: 4
# Report: P27 R4 — Enterprise files coverage
# ═══════════════════════════════════════════════════════════════

package test_jdg_ksef_receipt_digest
import data.jdg.ksef_receipt_digest

# 1. jdg.ksef_receipt_digest.no_match
test_positive_no_match {
    result := data.jdg.ksef_receipt_digest.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.ksef_receipt_digest.no_match"
}

test_negative_no_match {
    result := data.jdg.ksef_receipt_digest.decide with input as {}
    result.rule_id != "jdg.ksef_receipt_digest.no_match"
}

# 2. jdg.ksef_receipt_digest.digest_poll
test_positive_digest_poll {
    result := data.jdg.ksef_receipt_digest.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.ksef_receipt_digest.digest_poll"
}

test_negative_digest_poll {
    result := data.jdg.ksef_receipt_digest.decide with input as {}
    result.rule_id != "jdg.ksef_receipt_digest.digest_poll"
}

# 3. jdg.ksef_receipt_digest.receipt_jpk_reconciliation
test_positive_receipt_jpk_reconciliation {
    result := data.jdg.ksef_receipt_digest.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.ksef_receipt_digest.receipt_jpk_reconciliation"
}

test_negative_receipt_jpk_reconciliation {
    result := data.jdg.ksef_receipt_digest.decide with input as {}
    result.rule_id != "jdg.ksef_receipt_digest.receipt_jpk_reconciliation"
}

# 4. jdg.ksef_receipt_digest.missing_purchase_alert
test_positive_missing_purchase_alert {
    result := data.jdg.ksef_receipt_digest.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.ksef_receipt_digest.missing_purchase_alert"
}

test_negative_missing_purchase_alert {
    result := data.jdg.ksef_receipt_digest.decide with input as {}
    result.rule_id != "jdg.ksef_receipt_digest.missing_purchase_alert"
}
