# NexusAI JDG - Native Rego tests V3-13 Micro Quality
package tests.test_native_micro_quality_v3_13

# T01: missing snapshot is fail-closed
test_v3_13_fail_closed_without_snapshot {
    v := data.jdg.micro.quality_v3_13.decide with input as {"micro_audit": {"enabled": true}}
         with data.jdg.thresholds as {}
    v.rule_id == "jdg.micro.quality_v3_13.thresholds_missing"
    v._routing == "BLOCK_AND_ALERT"
    v.no_auto_post == true
}

# T02: a clean audit remains decoupled
test_v3_13_audit_contract {
    v := data.jdg.micro.quality_v3_13.decide with input as {
        "micro_audit": {"enabled": true, "mode": "AUDIT", "files": 93, "rules": 10000,
                        "syntax_errors": 0, "duplicate_rule_ids": 0,
                        "empty_optional_fields": 7977, "stub_findings": 0}
    }
    v.rule_id == "jdg.micro.quality_v3_13.audit_contract"
    v.audit_passed == true
    v.micro_decision_mode == "DECOUPLED"
    v.no_auto_post == true
}

# T03: explicit micro-to-macro binding
test_v3_13_binding {
    v := data.jdg.micro.quality_v3_13.decide with input as {
        "micro_audit": {"enabled": true, "mode": "BINDING",
                        "binding": {"micro_rule_id": "jdg.micro.pit.a22.r1",
                                    "macro_rule_id": "jdg.pit.kup.kup_general",
                                    "legal_basis": "Art. 22 PIT",
                                    "golden_input_ref": "golden/pit-a22-r1.json"}}
    }
    v.rule_id == "jdg.micro.quality_v3_13.micro_macro_binding"
    v.binding_passed == true
    v._routing == ""
}

# T04: empty generated strings normalize to null at the boundary
test_v3_13_boundary_normalization {
    v := data.jdg.micro.quality_v3_13.decide with input as {
        "micro_audit": {"enabled": true, "mode": "NORMALIZE", "binding_passed": true},
        "micro_verdict": {"rule_id": "jdg.micro.pit.a22.r1", "vat_rate": "",
                          "pit_form": "", "_routing": ""}
    }
    v.rule_id == "jdg.micro.quality_v3_13.normalized_boundary"
    v.micro_boundary == "NORMALIZED_V3_13"
    v.vat_rate == null
    v.pit_form == null
    v.no_auto_post == true
}

# T05: golden input requires a reference and a hash
test_v3_13_golden_input {
    v := data.jdg.micro.quality_v3_13.decide with input as {
        "micro_audit": {"enabled": true, "mode": "GOLDEN", "golden_input_ref": "golden/x.json",
                        "golden_verdict_hash": "sha256:x"}
    }
    v.rule_id == "jdg.micro.quality_v3_13.golden_input"
}

# T06: catch-all certificate
test_v3_13_domain_certificate {
    v := data.jdg.micro.quality_v3_13.decide with input as {}
    v.rule_id == "jdg.micro.quality_v3_13.domain_certificate"
    v.snapshot_status == "OK"
    v.macro_handoff == "EXPLICIT_BINDING_ONLY"
}

# T07: incomplete binding is not accepted
test_v3_13_incomplete_binding_falls_back_to_certificate {
    v := data.jdg.micro.quality_v3_13.decide with input as {
        "micro_audit": {"enabled": true, "mode": "BINDING",
                        "binding": {"micro_rule_id": "jdg.micro.pit.a22.r1"}}
    }
    v.rule_id == "jdg.micro.quality_v3_13.domain_certificate"
}

# T08: audit errors block even while preserving decoupled mode
test_v3_13_audit_error_blocks {
    v := data.jdg.micro.quality_v3_13.decide with input as {
        "micro_audit": {"enabled": true, "mode": "AUDIT", "syntax_errors": 1}
    }
    v.rule_id == "jdg.micro.quality_v3_13.audit_contract"
    v.audit_passed == false
    v._routing == "BLOCK_AND_ALERT"
    v.no_auto_post == true
}
