# ETAP 22 — native tests for Hyper Enterprise Contexts meta-validator.
package test_jdg_hyper_enterprise_contexts_etap22

import future.keywords.if

base := {
    "jdg_entrepreneur": {"hyper_enterprise_contexts_etap22_check": true},
    "hyper_enterprise_contexts_etap22": {
        "contexts": ["DEADLINES", "LIMITS", "MDR", "SANCTIONS", "FX", "WIS", "EDELIVERY"],
        "evaluation_date": "2026-08-21",
        "facts_version": "facts-22-1",
        "threshold_version": "hyper-etap22-2026.08",
        "legal_basis_version": "isap-hyper-2026.08",
        "source_refs": ["MF-22-1", "ISAP-22-1"],
        "legal_nodes": {"PIT": "PIT art. 30ca/30h/45", "OP": "OrdPU art. 12/126"},
        "owner_approval": true,
        "context_registry": [
            {"context": "DEADLINES"}, {"context": "LIMITS"}, {"context": "MDR"},
            {"context": "SANCTIONS"}, {"context": "FX"}, {"context": "WIS"}, {"context": "EDELIVERY"}
        ],
        "context_outputs": [
            {"context": "DEADLINES", "input_hash": "h1", "evidence_ref": "e1", "result": "OK", "test_ref": "t1", "recipient": "OWNER"}
        ],
        "priorities": ["P0", "P1"],
        "dependency_graph": {"graph_version": "graph-22-1", "nodes": ["DEADLINES", "LIMITS", "MDR"], "edges": [{"from": "DEADLINES", "to": "MDR"}], "conflict_pairs": [], "conflict_detector": true},
        "deadline_items": [{"deadline_id": "D-22-1", "due_date": "2026-08-30", "status": "OPEN", "evidence_ref": "D-E-22-1", "recipient": "OWNER"}],
        "limit_items": [{"limit_id": "L-22-1", "value": "1000000", "unit": "PLN", "valid_from": "2026-01-01", "source_ref": "L-E-22-1"}],
        "mdr_enabled": true,
        "mdr": {"hallmark": "A", "reportability_assessed": true, "evidence_ref": "MDR-E-22-1", "recipient": "OWNER"},
        "sanctions_enabled": true,
        "sanctions": {"violation_type": "LATE", "legal_basis": "KKS", "appeal_deadline": "2026-09-01", "evidence_ref": "S-E-22-1"},
        "fx_enabled": true,
        "fx": {"currency": "EUR", "rate": "4.3", "rate_date": "2026-08-21", "rate_source": "NBP", "evidence_ref": "FX-E-22-1"},
        "wis_enabled": true,
        "wis": {"request_id": "WIS-22-1", "status": "VALID", "evidence_ref": "WIS-E-22-1"},
        "edelivery_enabled": true,
        "edelivery": {"address_id": "ED-22-1", "mailbox_status": "ACTIVE", "confirmation_ref": "ED-E-22-1", "evidence_ref": "ED-E-22-1"},
        "meta_test_ref": "META-TEST-22-1",
        "meta_recipient": "OWNER"
    }
}

test_no_match_without_stage_flag if {
    result := data.jdg.hyper_enterprise_contexts_etap22.decide with input as {"jdg_entrepreneur": {}}
    result.rule_id == "jdg.hyper_enterprise_contexts_etap22.no_match"
}

test_missing_evidence_blocks if {
    result := data.jdg.hyper_enterprise_contexts_etap22.decide with input as {
        "jdg_entrepreneur": {"hyper_enterprise_contexts_etap22_check": true},
        "hyper_enterprise_contexts_etap22": {"contexts": ["DEADLINES"]}
    }
    result._routing == "BLOCK_AND_ALERT"
    result.no_auto_post == true
}

test_graph_invalid_and_output_blocks if {
    bad := object.union(base, {"hyper_enterprise_contexts_etap22": object.union(base.hyper_enterprise_contexts_etap22, {
        "context_outputs": [{"context": "DEADLINES"}],
        "dependency_graph": {"graph_version": "", "nodes": [], "edges": [], "conflict_pairs": [], "conflict_detector": false}
    })})
    result := data.jdg.hyper_enterprise_contexts_etap22.decide with input as bad
    result._routing == "BLOCK_AND_ALERT"
    result.meta_validator.result == false
}

# test_deadline

test_valid_context_contract_remains_manual if {
    result := data.jdg.hyper_enterprise_contexts_etap22.decide with input as base
    result.context_registry_complete == true
    result.context_outputs_complete == true
    result.deadline_engine == true
    result.limits_registry == true
    result.dependency_graph.complete == true
    result.meta_validator.result == true
    result.manual_review_required == true
    result.decision_mode == "SUGGEST"
}

test_conflict_detector_required if {
    bad := object.union(base, {"hyper_enterprise_contexts_etap22": object.union(base.hyper_enterprise_contexts_etap22, {
        "dependency_graph": object.union(base.hyper_enterprise_contexts_etap22.dependency_graph, {"conflict_detector": false})
    })})
    result := data.jdg.hyper_enterprise_contexts_etap22.decide with input as bad
    result._routing == "BLOCK_AND_ALERT"
    result.dependency_graph.complete == false
}

test_mdr_fx_wis_edelivery_contract if {
    result := data.jdg.hyper_enterprise_contexts_etap22.decide with input as base
    result.mdr_complete == true
    result.sanctions_complete == true
    result.fx_complete == true
    result.wis_complete == true
    result.edelivery_complete == true
}
