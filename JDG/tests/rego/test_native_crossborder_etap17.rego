# ETAP 17 — native Rego tests for evidence-first cross-border safety layer.
package test_jdg_crossborder_etap17

import future.keywords.if

base_input := {
    "jdg_entrepreneur": {"crossborder_etap17_check": true},
    "crossborder_etap17": {
        "evaluation_date": "2026-08-21",
        "threshold_version": "crossborder-2026.08",
        "legal_basis_version": "isap-lkg-2026.08",
        "facts_version": "facts-1",
        "source_refs": ["ISAP:VAT", "ISAP:PIT", "DAC6", "CBAM", "ViDA"],
        "legal_nodes": {"vat": "VAT art. 9-42", "pit": "PIT art. 3/24c/30f"},
        "transaction_direction": "WDT",
        "destination_country": "DE",
        "origin_country": "PL",
        "vat_chargeable": false,
        "pcc_claimed": false,
        "days_in_poland": 100,
        "tax_resident_declared": true,
        "fx_rate_present": true,
        "mdr_risk_score": 10,
        "cfc_triggered": false,
        "cbam_triggered": false,
        "evidence": {
            "residency": {"fact": "100 dni", "document": "calendar", "calculation": "days", "test": "boundary", "confidence": "HIGH", "manual_review": false},
            "direction": {"fact": "WDT", "document": "invoice", "calculation": "direction", "test": "country", "confidence": "HIGH", "manual_review": false},
            "place_of_supply": {"fact": "B2B", "document": "contract", "calculation": "art28b", "test": "country", "confidence": "HIGH", "manual_review": false},
            "wdt_wnt": {"fact": "export", "document": "proof", "calculation": "0pct", "test": "VIES", "confidence": "HIGH", "manual_review": false},
            "tp_cfc": {"fact": "none", "document": "ownership", "calculation": "threshold", "test": "30f", "confidence": "HIGH", "manual_review": false},
            "mdr_dac": {"fact": "none", "document": "assessment", "calculation": "score", "test": "hallmarks", "confidence": "HIGH", "manual_review": false},
            "cbam_vida_dac8": {"fact": "monitor", "document": "registry", "calculation": "status", "test": "effective-date", "confidence": "HIGH", "manual_review": false},
            "fx": {"fact": "EUR", "document": "NBP", "calculation": "rate", "test": "date", "confidence": "HIGH", "manual_review": false}
        }
    }
}

test_no_match_without_stage_flag if {
    result := data.jdg.crossborder_etap17.decide with input as {"jdg_entrepreneur": {}}
    result.rule_id == "jdg.crossborder_etap17.no_match"
}

test_missing_context_is_blocked if {
    result := data.jdg.crossborder_etap17.decide with input as {
        "jdg_entrepreneur": {"crossborder_etap17_check": true},
        "crossborder_etap17": {"source_refs": ["ISAP:VAT"]}
    }
    result.rule_id == "jdg.crossborder_etap17.evidence_first_verdict"
    result._routing == "BLOCK_AND_ALERT"
    result.manual_review_required == true
    result.confidence == "LOW"
}

test_conflict_is_blocked if {
    result := data.jdg.crossborder_etap17.decide with input as {
        "jdg_entrepreneur": {"crossborder_etap17_check": true},
        "crossborder_etap17": {
            "evaluation_date": "2026-08-21",
            "threshold_version": "v1",
            "legal_basis_version": "v1",
            "facts_version": "v1",
            "source_refs": ["ISAP:VAT"],
            "transaction_direction": "WDT",
            "destination_country": "PL",
            "fx_rate_present": true
        }
    }
    result.conflict_count > 0
    result._routing == "BLOCK_AND_ALERT"
}

test_high_risk_requires_manual_review if {
    high_risk_input := object.union(base_input, {"crossborder_etap17": object.union(base_input.crossborder_etap17, {"mdr_risk_score": 80})})
    result := data.jdg.crossborder_etap17.decide with input as high_risk_input
    result.high_risk == true
    result._routing == "TRIAGE_QUEUE"
    result.manual_review_required == true
}

test_complete_evidence_is_suggest_only if {
    result := data.jdg.crossborder_etap17.decide with input as base_input
    result.confidence == "HIGH"
    result.manual_review_required == false
    result._routing == ""
    result.decision_mode == "SUGGEST"
    result.no_auto_post == true
}
