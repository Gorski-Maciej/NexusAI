# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for P03 GLM52 Orkiestrator + Infrastruktura
# Packages: jdg.p03_orchestrator_innovations
# Source: 03_PROMT_ORKIESTRATOR_INFRASTRUKTURA.txt (prompty_glm52) — Sekcje 6-10
# Generated: 2026-08-08
# ═══════════════════════════════════════════════════════════════════════════════

package test_p03_orchestrator

import future.keywords.in

# ═══ DEFAULT: bez flagi p03_orchestrator_check → no_match ═══

test_default_no_match {
    result := data.jdg.p03_orchestrator_innovations.decide with input as {
        "jdg_entrepreneur": {"p03_orchestrator_check": false}
    }
    result.matched == false
    result.rule_id == "jdg.p03_orchestrator_innovations.no_match"
}

# ═══ INN-01: input_hash deterministyczny ═══

test_input_hash_deterministic {
    h1 := data.jdg.p03_orchestrator_innovations.input_hash with input as {
        "jdg_entrepreneur": {"nip": "1234567890"},
        "invoice": {"invoice_number": "FV/2026/001", "direction": "SALE"},
        "evaluation_datetime": "2026-08-08"
    }
    h2 := data.jdg.p03_orchestrator_innovations.input_hash with input as {
        "jdg_entrepreneur": {"nip": "1234567890"},
        "invoice": {"invoice_number": "FV/2026/001", "direction": "SALE"},
        "evaluation_datetime": "2026-08-08"
    }
    h1 == h2
    startswith(h1, "sha256:")
}

# ═══ RAPORT ORKIESTRATORA: aktywna flaga ═══

test_orchestrator_report {
    result := data.jdg.p03_orchestrator_innovations.decide with input as {
        "jdg_entrepreneur": {"p03_orchestrator_check": true}
    }
    result.matched == true
    result.rule_id == "jdg.p03_orchestrator_innovations.orchestrator_report"
    result._routing == "REPORT"
    result.orchestrator.cache_key.deterministic == true
    count(result.orchestrator.invariant_proofs) >= 6
    result.orchestrator.benchmarks.target.p95_domestic_ms == 5
    result.orchestrator.wasm.fallback == "OPA_INTERPRETER"
}

# ═══ INN-02: shadow twin aktywowany flagą ═══

test_shadow_twin_active {
    result := data.jdg.p03_orchestrator_innovations.shadow_twin_comparison with input as {
        "jdg_entrepreneur": {"shadow_twin_check": true}
    }
    result.shadow_active == true
    count(result.packages) >= 4
}

test_shadow_twin_off {
    result := data.jdg.p03_orchestrator_innovations.shadow_twin_comparison with input as {
        "jdg_entrepreneur": {"shadow_twin_check": false}
    }
    result.shadow_active == false
}

# ═══ INN-07: degraded context ═══

test_degraded_context_detected {
    result := data.jdg.p03_orchestrator_innovations.degraded_context with input as {
        "degraded_sources": ["NBP_FX"]
    }
    result.degraded == true
    result.routing == "TRIAGE_QUEUE"
}

test_degraded_context_clean {
    result := data.jdg.p03_orchestrator_innovations.degraded_context with input as {
        "degraded_sources": []
    }
    result.degraded == false
}

# ═══ INN-09: graf zależności ═══

test_dependency_graph_empty {
    result := data.jdg.p03_orchestrator_innovations.build_dependency_graph({})
    result.acyclic == true
}

test_dependency_graph_with_active {
    pkgs := {"jdg.risk": {"matched": true, "rule_id": "jdg.risk.fraud_graph_match", "package": "jdg.risk", "_legal_basis": "Art. 86 VAT", "_threshold_refs": [500000]}}
    result := data.jdg.p03_orchestrator_innovations.build_dependency_graph(pkgs)
    count(result.nodes) == 1
    result.acyclic == true
    count(result.legal_edges) == 1
}

# ═══ INN-12: merkle verify ═══

test_merkle_verify_ok {
    verdict := {
        "rule_id": "jdg.risk.fraud_graph_match",
        "_routing": "BLOCK_AND_ALERT",
        "decision_hash": "sha256:jdg.risk.fraud_graph_match|BLOCK_AND_ALERT|2026-08-08"
    }
    ok := data.jdg.p03_orchestrator_innovations.merkle_verify(verdict) with input as {
        "evaluation_datetime": "2026-08-08"
    }
    ok == true
}

test_merkle_verify_tampered {
    verdict := {
        "rule_id": "jdg.risk.fraud_graph_match",
        "_routing": "BLOCK_AND_ALERT",
        "decision_hash": "sha256:TAMPERED"
    }
    ok := data.jdg.p03_orchestrator_innovations.merkle_verify(verdict) with input as {
        "evaluation_datetime": "2026-08-08"
    }
    ok == false
}

# ═══ RUNTIME INVARIANTS: evaluate / enforce (F2 V2, ADR-022) ═══

test_invariants_evaluate_clean_verdict {
    verdict := {
        "matched": true,
        "rule_id": "jdg.fallback.domestic_23pct",
        "_routing": "",
        "vat_rate": "0.23",
        "net_amount": 100.0,
        "vat_amount": 23.0,
        "gross_amount": 123.0,
        "currency": "PLN",
        "_legal_basis": "Art. 41 ust. 1 VAT",
        "_provenance_tree": {"path": [1], "bundle_version": "1.0.0"},
        "_warnings": [],
    }
    ev := data.jdg.runtime_invariants.evaluate(verdict)
    ev.invariant_failed == false
    ev.certainty_class in {"CERTAIN", "CONDITIONAL"}
}

test_invariants_evaluate_violation {
    verdict := {
        "matched": true,
        "rule_id": "jdg.risk.fraud",
        "_routing": "BLOCK_AND_ALERT",
        "vat_rate": "0.99",
        "auto_post": true,
        "_legal_basis": "Art. 86 VAT",
        "_warnings": [],
    }
    ev := data.jdg.runtime_invariants.evaluate(verdict)
    ev.invariant_failed == true
    ev.certainty_class == "NEEDS_ADVICE"
}

test_invariants_enforce_blocks_auto_post_and_is_deterministic {
    verdict := {
        "matched": true,
        "rule_id": "jdg.risk.fraud",
        "_routing": "BLOCK_AND_ALERT",
        "vat_rate": "0.99",
        "auto_post": true,
        "_legal_basis": "Art. 86 VAT",
        "_routing_context": {"tax_form": "SCALE", "transaction_type": "SALE", "entity_status": "ACTIVE", "evaluation_date": "2026-08-08"},
    }
    out1 := data.jdg.runtime_invariants.enforce(verdict) with input as {"evaluated_at": "2026-08-08T00:00:00Z"}
    out2 := data.jdg.runtime_invariants.enforce(verdict) with input as {"evaluated_at": "2026-08-08T00:00:00Z"}
    out1._certainty_guard == "CERTAINTY_BLOCKED"
    out1.auto_post == false
    out1._decision_certificate.evaluated_at == out2._decision_certificate.evaluated_at
    out1._decision_certificate.decision_hash == out2._decision_certificate.decision_hash
}

test_decision_hash_includes_all_versions {
    base := {"matched": true, "rule_id": "r1", "_routing": "", "_legal_basis": "Art. 1", "_versions": {"bundle_version": "b1", "rule_version": "r1", "threshold_version": "t1"}}
    h1 := data.jdg.runtime_invariants.enforce(base) with input as {"evaluated_at": "2026-08-08"}
    h2 := data.jdg.runtime_invariants.enforce(base) with input as {"evaluated_at": "2026-08-08"}
    h1._decision_certificate.decision_hash == h2._decision_certificate.decision_hash
    changed := object.union(base, {"_versions": {"bundle_version": "b1", "rule_version": "r2", "threshold_version": "t1"}})
    h3 := data.jdg.runtime_invariants.enforce(changed) with input as {"evaluated_at": "2026-08-08"}
    h1._decision_certificate.decision_hash != h3._decision_certificate.decision_hash
}

test_invariants_enforce_adds_certificate {
    verdict := {
        "matched": true,
        "rule_id": "jdg.fallback.domestic_23pct",
        "_routing": "",
        "vat_rate": "0.23",
        "_legal_basis": "Art. 41 ust. 1 VAT",
        "_warnings": [],
    }
    out := data.jdg.runtime_invariants.enforce(verdict) with input as {
        "bundle_version": "1.0.0",
        "threshold_version": "2026.1",
    }
    out.certainty_class in {"CERTAIN", "CONDITIONAL", "NEEDS_ADVICE"}
    out._certainty_guard in {"AUTO_POST_ALLOWED", "MANUAL_REVIEW", "CERTAINTY_BLOCKED"}
    out._decision_certificate.decision_hash
    out._invariant_report.invariant_failed == false
}

# ═══ TEMPORALNOŚĆ: P1627 interval algebra + P1628 threshold pin ═══

test_temporal_interval_algebra_no_overlap {
    result := data.jdg.temporal.decide with input as {
        "jdg_entrepreneur": {},
        "temporal": {"interval_algebra": true},
        "rule_registry": {
            "jdg.vat.a113": {"versions": [
                {"version": "1.0.0", "valid_from": "2020-01-01", "valid_to": "2025-12-31", "status": "ACTIVE"},
                {"version": "2.0.0", "valid_from": "2026-01-01", "valid_to": null, "status": "ACTIVE"}
            ]}
        }
    }
    result.rule_id == "jdg.temporal.interval_algebra"
    result.interval_proof.zero_overlaps == true
    result.interval_proof.zero_gaps == true
}

test_temporal_interval_algebra_gap_detected {
    result := data.jdg.temporal.decide with input as {
        "jdg_entrepreneur": {},
        "temporal": {"interval_algebra": true},
        "rule_registry": {
            "jdg.vat.a113": {"versions": [
                {"version": "1.0.0", "valid_from": "2020-01-01", "valid_to": "2024-12-31", "status": "ACTIVE"},
                {"version": "2.0.0", "valid_from": "2026-01-01", "valid_to": null, "status": "ACTIVE"}
            ]}
        }
    }
    result.rule_id == "jdg.temporal.interval_algebra"
    result.interval_proof.zero_gaps == false
    result.gap_total == 1
}

test_temporal_threshold_pin {
    result := data.jdg.temporal.decide with input as {
        "jdg_entrepreneur": {},
        "temporal": {"threshold_pin": true, "evaluation_date": "2026-06-01"},
        "threshold_versions": {
            "vat.standard_rate": [
                {"version": "2020", "valid_from": "2020-01-01", "valid_to": "2025-12-31", "value": 0.23},
                {"version": "2026", "valid_from": "2026-01-01", "valid_to": null, "value": 0.23}
            ]
        }
    }
    result.rule_id == "jdg.temporal.threshold_version_pin"
    result.threshold_pinned[0].threshold == "vat.standard_rate"
    result.threshold_pinned[0].version == "2026"
}
