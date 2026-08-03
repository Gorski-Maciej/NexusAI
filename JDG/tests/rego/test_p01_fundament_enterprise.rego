# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for P01 Fundament OPA v9.0
# Packages: jdg.rule_lifecycle, jdg.reliability_guarantee, jdg.p01_fundament_innovations
# Source: P01_Fundament_OPA.txt (prompts_glm52) — Sekcje 2, 4, 7
# Generated: 2026-08-02
# ═══════════════════════════════════════════════════════════════════════════════

package test_p01_fundament

import future.keywords.in

# ═══ RULE LIFECYCLE (Sekcja 2) ═══

# default no_match — bez flagi check
test_rule_lifecycle_default_no_match {
    result := data.jdg.rule_lifecycle.decide with input as {
        "jdg_entrepreneur": {"rule_lifecycle_check": false}
    }
    result.matched == false
    result.rule_id == "jdg.rule_lifecycle.no_match"
}

# registry_report — aktywna flaga, pusty rejestr
test_rule_lifecycle_registry_report {
    result := data.jdg.rule_lifecycle.decide with input as {
        "jdg_entrepreneur": {"rule_lifecycle_check": true}
    }
    result.matched == true
    result.rule_id == "jdg.rule_lifecycle.registry_report"
    result.lifecycle.registered_rules == 0
    result.lifecycle.conflict_count == 0
}

# shadow_activation — wersja SHADOW w rejestrze
test_rule_lifecycle_shadow_activation {
    result := data.jdg.rule_lifecycle.decide with input as {
        "jdg_entrepreneur": {"rule_lifecycle_check": true},
        "rule_registry": {
            "jdg.vat.a113.r1": {"versions": [
                {"version": "1.0.0", "valid_from": "2020-01-01", "valid_to": null, "status": "ACTIVE"},
                {"version": "2.0.0", "valid_from": "2026-08-01", "valid_to": null, "status": "SHADOW"}
            ]}
        }
    }
    result.matched == true
    result.rule_id == "jdg.rule_lifecycle.shadow_activation"
    count(result.shadow_versions) == 1
}

# ab_rollout — kandydat z rollout 10%
test_rule_lifecycle_ab_rollout {
    result := data.jdg.rule_lifecycle.decide with input as {
        "jdg_entrepreneur": {"rule_lifecycle_check": true, "nip": "1234567890"},
        "invoice": {"invoice_number": "FV/2026/001"},
        "rule_registry": {
            "jdg.vat.a113.r1": {"versions": [
                {"version": "1.0.0", "valid_from": "2020-01-01", "valid_to": null, "status": "ACTIVE"},
                {"version": "2.0.0", "valid_from": "2026-08-01", "valid_to": null,
                 "status": "CANDIDATE", "rollout_pct": 10, "error_rate": 0.0}
            ]}
        }
    }
    result.matched == true
    result.rule_id == "jdg.rule_lifecycle.ab_rollout"
    count(result.rollout) == 1
}

# auto_rollback — kandydat z error_rate > 5%
test_rule_lifecycle_auto_rollback {
    result := data.jdg.rule_lifecycle.decide with input as {
        "jdg_entrepreneur": {"rule_lifecycle_check": true, "nip": "1234567890"},
        "invoice": {"invoice_number": "FV/2026/002"},
        "rule_registry": {
            "jdg.vat.a113.r1": {"versions": [
                {"version": "1.0.0", "valid_from": "2020-01-01", "valid_to": null, "status": "ACTIVE"},
                {"version": "2.0.0", "valid_from": "2026-08-01", "valid_to": null,
                 "status": "CANDIDATE", "rollout_pct": 50, "error_rate": 0.12, "supersedes": "1.0.0"}
            ]}
        }
    }
    result.matched == true
    result.rule_id == "jdg.rule_lifecycle.auto_rollback"
    result._routing == "BLOCK_AND_ALERT"
    count(result.rollback_required) == 1
}

# temporal conflict — dwie wersje z nakładającymi się oknami
test_rule_lifecycle_temporal_conflict {
    result := data.jdg.rule_lifecycle.lifecycle_report with input as {
        "rule_registry": {
            "jdg.vat.a113.r1": {"versions": [
                {"version": "1.0.0", "valid_from": "2020-01-01", "valid_to": "2026-12-31", "status": "ACTIVE"},
                {"version": "2.0.0", "valid_from": "2026-06-01", "valid_to": null, "status": "ACTIVE"}
            ]}
        }
    }
    count(result.temporal_conflicts) == 1
}

# ═══ RELIABILITY GUARANTEE (Sekcja 4) ═══

# provenance_gate — werdykt bez _provenance_tree → BLOCK
test_reliability_provenance_gate {
    result := data.jdg.reliability_guarantee.decide with input as {
        "jdg_entrepreneur": {"reliability_check": true},
        "verdict": {"matched": true, "rule_id": "x"},
        "_package_decisions": {"jdg.risk": {"matched": true}}
    }
    result.matched == true
    result.rule_id == "jdg.reliability_guarantee.provenance_gate"
    result._routing == "BLOCK_AND_ALERT"
}

# ok — pełna gwarancja
test_reliability_ok {
    result := data.jdg.reliability_guarantee.decide with input as {
        "jdg_entrepreneur": {"reliability_check": true},
        "verdict": {"_provenance_tree": {"path": [{"step": 1}], "root_hash": "sha256:x"}},
        "_package_decisions": {
            "jdg.risk": {"matched": true},
            "jdg.fallback": {"matched": false}
        }
    }
    result.matched == true
    result.rule_id == "jdg.reliability_guarantee.ok"
    result.reliability.guarantee_level == "FULL"
}

# determinism warning — niska pewność OCR
test_reliability_determinism_warning {
    result := data.jdg.reliability_guarantee.decide with input as {
        "jdg_entrepreneur": {"reliability_check": true},
        "verdict": {"_provenance_tree": {"path": [{"step": 1}], "root_hash": "sha256:x"}},
        "_package_decisions": {"jdg.risk": {"matched": true}},
        "confidence": {"fc_vat_rate": 0.72}
    }
    result.rule_id == "jdg.reliability_guarantee.determinism_warning"
    count(result.reliability.determinism_risks) == 1
}

# ═══ P01 FUNDAMENT INNOVATIONS (Sekcja 7) ═══

# report innowacji — flaga p01_fundament_check
test_p01_fundament_report {
    result := data.jdg.p01_fundament_innovations.decide with input as {
        "jdg_entrepreneur": {"p01_fundament_check": true},
        "_package_decisions": {
            "jdg.risk": {"matched": true, "rule_id": "jdg.risk.x", "package": "jdg.risk",
                         "priority": 1, "_legal_basis": "Art. 1", "_routing": "ALLOW", "_routing_reason": "ok"}
        }
    }
    result.matched == true
    result.rule_id == "jdg.p01_fundament_innovations.report"
    result.innovations.INN02_hot_reload_ready == false
    count(result.innovations.INN05_verdict_contract_violations) == 0
    count(result.innovations.INN14_legal_basis_violations) == 0
}

# hot_reload true gdy data.jdg.rule_registry obecny
test_p01_hot_reload_true {
    result := data.jdg.p01_fundament_innovations.decide with input as {
        "jdg_entrepreneur": {"p01_fundament_check": true}
    } with data.jdg.rule_registry as {"x": {"versions": []}}
    result.innovations.INN02_hot_reload_ready == true
}

# digital twin — aktywacja
test_p01_digital_twin {
    result := data.jdg.p01_fundament_innovations.decide with input as {
        "jdg_entrepreneur": {"p01_fundament_check": true},
        "digital_twin": {"scenario": "test", "override": {"vat_rate": 0.23}}
    }
    result.innovations.digital_twin_verdict.twin.scenario == "test"
}

# adaptive thresholds — feedback obecny
test_p01_adaptive_thresholds with data.jdg.trust_feedback as {"correct": 950, "incorrect": 50} {
    result := data.jdg.p01_fundament_innovations.innovations_summary with input as {}
    result.adaptive_trust_score.auto_post <= 0.92
}
