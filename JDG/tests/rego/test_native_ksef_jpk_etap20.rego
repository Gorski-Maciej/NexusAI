# ETAP 20 — native tests for KSeF/JPK/e-Deklaracje evidence contract.
package test_jdg_ksef_jpk_etap20

import future.keywords.if

base := {
    "jdg_entrepreneur": {"ksef_jpk_etap20_check": true},
    "ksef_jpk_etap20": {
        "evaluation_date": "2026-08-21",
        "facts_version": "facts-20-1",
        "threshold_version": "ksef-jpk-etap20-2026.08",
        "legal_basis_version": "isap-mf-2026.08",
        "source_refs": ["MF-KSeF-2026", "JPK-XSD-2026"],
        "legal_nodes": {"vat": "VAT art. 106na-106nq", "ordpu": "OrdPU art. 193a"},
        "owner_approval": true,
        "document": {
            "state": "VALIDATED",
            "target_state": "VALIDATED",
            "schema_version": "FA(2)",
            "document_id": "DOC-20-1",
            "document_hash": "sha256:document-20-1",
            "idempotency_key": "idem-20-1",
            "issuer_nip": "1111111111",
            "buyer_nip": "2222222222",
            "duplicate_detected": false,
            "fields": {"P_1": true, "P_2": true, "P_3": true, "P_4": true, "P_5": true, "P_6": true, "P_7": true, "P_8": true}
        },
        "ksef": {
            "token_present": true,
            "ksef_number": "KSEF-20-1",
            "mf_available": true,
            "upo_present": true,
            "upo_id": "UPO-20-1",
            "upo_deadline_ok": true,
            "offline_mode": false,
            "offline_days": 0,
            "retry_attempts": 0,
            "outbox_entry_present": true,
            "outbox_idempotency_key": "idem-20-1",
            "duplicate_detected": false
        },
        "jpk": {
            "declaration_type": "JPK_V7M",
            "gtu_codes": ["GTU_04"],
            "deadline": "2026-08-25"
        },
        "ledger_total": 1000,
        "jpk_total": 1000,
        "ksef_total": 1000,
        "sandbox_required": true,
        "sandbox": {"run_id": "SB-20-1", "passed": true, "schema_version": "FA(2)"}
    }
}

test_no_match_without_stage_flag if {
    result := data.jdg.ksef_jpk_etap20.decide with input as {"jdg_entrepreneur": {}}
    result.rule_id == "jdg.ksef_jpk_etap20.no_match"
}

test_missing_evidence_blocks if {
    result := data.jdg.ksef_jpk_etap20.decide with input as {
        "jdg_entrepreneur": {"ksef_jpk_etap20_check": true},
        "ksef_jpk_etap20": {"document": {"state": "DRAFT"}}
    }
    result._routing == "BLOCK_AND_ALERT"
    result.no_auto_post == true
    result.sent_by_rule == false
}

test_invalid_transition_blocks if {
    bad := object.union(base, {"ksef_jpk_etap20": object.union(base.ksef_jpk_etap20, {
        "document": object.union(base.ksef_jpk_etap20.document, {"target_state": "ACCEPTED"})
    })})
    result := data.jdg.ksef_jpk_etap20.decide with input as bad
    result._routing == "BLOCK_AND_ALERT"
    result.document_state.transition_valid == false
}

test_exactly_once_and_state_contract if {
    result := data.jdg.ksef_jpk_etap20.decide with input as base
    result.outbox_certificate.exactly_once_semantics == true
    result.transport_certificate.mf_available == true
    result.format_certificate.schema_valid == true
    result.document_state.state_valid == true
    result.decision_mode == "SUGGEST"
    result.sent_by_rule == false
    result.delivery_claim == "NOT_SENT_BY_RULE"
}

test_reconciliation_mismatch_blocks if {
    bad := object.union(base, {"ksef_jpk_etap20": object.union(base.ksef_jpk_etap20, {
        "ksef_total": 999
    })})
    result := data.jdg.ksef_jpk_etap20.decide with input as bad
    result._routing == "BLOCK_AND_ALERT"
    result.reconciliation_certificate.reconciliation_ok == false
}

test_mf_unavailable_blocks if {
    bad := object.union(base, {"ksef_jpk_etap20": object.union(base.ksef_jpk_etap20, {
        "ksef": object.union(base.ksef_jpk_etap20.ksef, {"mf_available": false})
    })})
    result := data.jdg.ksef_jpk_etap20.decide with input as bad
    result._routing == "BLOCK_AND_ALERT"
    result.transport_certificate.mf_available == false
    result.transport_certificate.upo_present == true
}
