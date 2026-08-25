package jdg.hyper.quality_v3_14

import data.jdg.hyper.quality_v3_14

valid_ctx := {
    "contexts": ["DEADLINES", "LIMITS", "SANCTIONS", "FX", "EDELIVERY"],
    "context_registry": [
        {"context": "DEADLINES"}, {"context": "LIMITS"}, {"context": "SANCTIONS"},
        {"context": "FX"}, {"context": "EDELIVERY"},
    ],
    "source_refs": ["isap://ordpu/12", "isap://vat/99"],
    "legal_nodes": ["ordpu.art12", "vat.art99"],
    "evaluation_date": "2026-08-25",
    "facts_version": "facts-2026.08",
    "input_hash": "sha256:hyper-golden-14",
    "owner_approval": true,
    "manual_recipient": "OWNER_TAX",
    "deadline_items": [{
        "deadline_id": "VAT-JPK-25",
        "base_date": "2026-08-25",
        "due_date": "2026-08-25",
        "status": "DUE",
        "evidence_ref": "ev://deadline/1",
        "recipient": "US",
    }],
    "limit_items": [{
        "limit_id": "VAT-113",
        "value": 200000,
        "unit": "PLN",
        "valid_from": "2026-01-01",
        "valid_to": "2026-12-31",
        "source_ref": "isap://vat/113",
    }],
    "sanctions_enabled": true,
    "sanction_map": {
        "mapping": "VAT",
        "violation_type": "LATE_FILING",
        "legal_basis": "VAT art. 112b",
        "appeal_deadline": "2026-09-08",
        "evidence_ref": "ev://sanction/1",
    },
    "force_majeure_enabled": true,
    "force_majeure": {
        "event_id": "FM-1",
        "started_at": "2026-08-20",
        "ended_at": "2026-08-21",
        "evidence_ref": "ev://fm/1",
        "manual_review": true,
    },
    "fx_enabled": true,
    "fx": {
        "currency": "EUR",
        "rate": 4.25,
        "rate_date": "2026-08-25",
        "rate_source": "NBP",
        "evidence_ref": "ev://fx/1",
    },
    "edelivery_enabled": true,
    "edelivery": {
        "address_id": "BAE-1",
        "mailbox_status": "ACTIVE",
        "confirmation_ref": "UPD-1",
        "evidence_ref": "ev://edelivery/1",
    },
    "dependency_graph": {
        "nodes": ["VAT", "ORD"],
        "graph_version": "graph-2026.08",
        "conflict_detector": true,
    },
    "cross_domain_binding": {"macro_rule_id": "jdg.vat.a113"},
    "temporal_overlap": false,
    "temporal_gap": false,
}

test_full_contract_validated if {
    result := quality_v3_14.decide with input as {"hyper_quality_v3_14_check": true, "hyper_quality_v3_14": valid_ctx}
    result.state == "HYPER_VALIDATED"
    result._routing == "TRIAGE_QUEUE"
    result.no_auto_post == true
    result.mode == "DECOUPLED"
}

test_fail_closed_without_owner_approval if {
    ctx := object.union(valid_ctx, {"owner_approval": false})
    result := quality_v3_14.decide with input as {"hyper_quality_v3_14_check": true, "hyper_quality_v3_14": ctx}
    result.state == "HYPER_BLOCKED"
    result._routing == "BLOCK_AND_ALERT"
    result.no_auto_post == true
}

test_fail_closed_with_temporal_gap if {
    ctx := object.union(valid_ctx, {"temporal_gap": true})
    result := quality_v3_14.decide with input as {"hyper_quality_v3_14_check": true, "hyper_quality_v3_14": ctx}
    result.temporal_valid == false
    result.state == "HYPER_BLOCKED"
}
