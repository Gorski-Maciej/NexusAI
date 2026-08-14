# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests for R01 GLM52 Orkiestrator + Rdzeń Silnika
# Packages: jdg.r01_orchestrator_core_innovations
# Source: 01_ORKIESTRATOR_I_RDZEŃ_SILNIKA_main_jdg_routin.txt (prompty_glm52)
# Generated: 2026-08-14
# ═══════════════════════════════════════════════════════════════════════════════

package test_r01_orchestrator_core

import future.keywords.in

# ═══ DEFAULT: bez flagi r01_orchestrator_core_check → no_match ═══

test_default_no_match {
    result := data.jdg.r01_orchestrator_core_innovations.decide with input as {
        "jdg_entrepreneur": {"r01_orchestrator_core_check": false}
    }
    result.matched == false
    result.rule_id == "jdg.r01_orchestrator_core_innovations.no_match"
}

# ═══ R01-INN-02: słownik 25-polowy ═══

test_25_field_dictionary_count {
    count(data.jdg.r01_orchestrator_core_innovations.verdict_25_fields) == 25
}

test_25_field_dictionary_contains_canonical_fields {
    fields := data.jdg.r01_orchestrator_core_innovations.verdict_25_fields
    "matched" in fields
    "rule_id" in fields
    "vat_rate" in fields
    "pit_rate" in fields
    "_routing" in fields
    "_legal_basis" in fields
    "_warnings" in fields
    "valid_from" in fields
    "valid_to" in fields
}

test_verdict_complete_ok {
    complete := data.jdg.r01_orchestrator_core_innovations.verdict_complete({
        "matched": true,
        "rule_id": "r1",
        "package": "jdg.fallback",
        "priority": 1000,
        "vat_rate": "0.23",
        "rounding_level": "position",
        "gtu_code": "",
        "vat_exemption": "",
        "procedure": "",
        "pit_form": "SCALE",
        "pit_rate": "0.12",
        "pit_bracket": "LOW",
        "pit_annual_return_type": "PIT-36",
        "kus_qualification": "full",
        "kus_percent": 100,
        "zus_social_base_type": "STANDARD",
        "zus_health_rate": "0.09",
        "business_status": "ACTIVE",
        "ceidg_registration_required": false,
        "valid_from": "2026-01-01",
        "valid_to": null,
        "_routing": "",
        "_routing_reason": "",
        "_legal_basis": "Art. 41 VAT",
        "_warnings": [],
    })
    complete == true
}

test_verdict_incomplete_detected {
    incomplete := data.jdg.r01_orchestrator_core_innovations.verdict_complete({
        "matched": true,
        "rule_id": "r1",
        "package": "jdg.fallback",
    })
    incomplete == false
    count(data.jdg.r01_orchestrator_core_innovations.missing_verdict_fields({
        "matched": true,
        "rule_id": "r1",
        "package": "jdg.fallback",
    })) == 22
}

# ═══ R01-INN-01: deterministyczny routing z debugowaniem ścieżki ═══

test_select_path_domestic_sale {
    data.jdg.r01_orchestrator_core_innovations.select_path({
        "is_cross_border": false,
        "entity_status": "ACTIVE",
        "transaction_type": "DOMESTIC_SALE",
    }) == "SHARDED_DOMESTIC_SALE"
}

test_select_path_cross_border {
    data.jdg.r01_orchestrator_core_innovations.select_path({
        "is_cross_border": true,
        "entity_status": "ACTIVE",
        "transaction_type": "SALE",
    }) == "FULL_CHAIN_CROSS_BORDER"
}

test_select_path_fallback {
    data.jdg.r01_orchestrator_core_innovations.select_path({
        "is_cross_border": false,
        "entity_status": "ACTIVE",
        "transaction_type": "UNKNOWN",
    }) == "FULL_CHAIN_FALLBACK"
}

test_routing_path_trace_deterministic {
    trace := data.jdg.r01_orchestrator_core_innovations.routing_path_trace with input as {
        "_routing_context": {
            "tax_form": "SCALE",
            "transaction_type": "DOMESTIC_SALE",
            "entity_status": "ACTIVE",
            "evaluation_date": "2026-08-14",
            "is_cross_border": false,
        }
    }
    trace.selected_path == "SHARDED_DOMESTIC_SALE"
    trace.deterministic == true
    startswith(trace.debug, "path=SHARDED_DOMESTIC_SALE|")
}

test_routing_path_trace_no_context {
    trace := data.jdg.r01_orchestrator_core_innovations.routing_path_trace with input as {}
    trace.selected_path == "NO_CONTEXT"
}

# ═══ R01-INN-03: cache decyzji — deterministyczny klucz ═══

test_cache_key_deterministic {
    k1 := data.jdg.r01_orchestrator_core_innovations.cache_input_hash with input as {
        "jdg_entrepreneur": {"nip": "1234567890"},
        "invoice": {"invoice_number": "FV/2026/001", "direction": "SALE"},
        "evaluation_datetime": "2026-08-14",
    }
    k2 := data.jdg.r01_orchestrator_core_innovations.cache_input_hash with input as {
        "jdg_entrepreneur": {"nip": "1234567890"},
        "invoice": {"invoice_number": "FV/2026/001", "direction": "SALE"},
        "evaluation_datetime": "2026-08-14",
    }
    k1 == k2
    startswith(k1, "sha256:")
}

test_cache_key_changes_with_bundle {
    k1 := data.jdg.r01_orchestrator_core_innovations.cache_input_hash with input as {
        "jdg_entrepreneur": {"nip": "1"},
        "invoice": {},
        "evaluation_datetime": "2026-08-14",
        "bundle_version": "v1",
    }
    k2 := data.jdg.r01_orchestrator_core_innovations.cache_input_hash with input as {
        "jdg_entrepreneur": {"nip": "1"},
        "invoice": {},
        "evaluation_datetime": "2026-08-14",
        "bundle_version": "v2",
    }
    k1 != k2
}

test_decision_cache_runtime_contract {
    contract := data.jdg.r01_orchestrator_core_innovations.decision_cache_runtime with input as {
        "decision_cache_hit": true,
        "decision_cache_ttl_ms": 60000,
    }
    contract.hit == true
    contract.ttl_ms == 60000
    contract.deterministic == true
}

# ═══ R01-INN-04: time-travel guard ═══

test_time_travel_active_consistent {
    guard := data.jdg.r01_orchestrator_core_innovations.time_travel_guard with input as {
        "temporal_evaluation_date": "2024-06-01",
        "evaluation_datetime": "2026-08-14",
    }
    guard.time_travel_active == true
    guard.consistent == true
    guard.routing == "TIME_TRAVEL"
}

test_time_travel_inconsistent {
    guard := data.jdg.r01_orchestrator_core_innovations.time_travel_guard with input as {
        "temporal_evaluation_date": "2027-06-01",
        "evaluation_datetime": "2026-08-14",
    }
    guard.consistent == false
}

test_time_travel_off {
    guard := data.jdg.r01_orchestrator_core_innovations.time_travel_guard with input as {
        "evaluation_datetime": "2026-08-14"
    }
    guard.time_travel_active == false
    guard.routing == "CURRENT_DATE"
}

# ═══ R01-INN-05: safe_merge integrity (INV-042) ═══

test_safe_merge_integrity_clean {
    report := data.jdg.r01_orchestrator_core_innovations.safe_merge_integrity with input as {
        "_package_decisions": {
            "jdg.zus": {"matched": true, "immutable_verdict": true, "_warnings": []},
            "jdg.risk": {"matched": true, "immutable_verdict": false, "_warnings": []},
        }
    }
    report.allowlist_size >= 5
    count(report.violations) == 0
    report.overwrite_warning_present == false
}

test_safe_merge_integrity_violation_detected {
    report := data.jdg.r01_orchestrator_core_innovations.safe_merge_integrity with input as {
        "_package_decisions": {
            "jdg.zus": {"matched": true, "immutable_verdict": false, "_warnings": ["IMMUTABLE_VERDICT_OVERWRITE"]},
        }
    }
    count(report.violations) == 1
    report.overwrite_warning_present == true
}

# ═══ R01-INN-06: zderzenia priorytetów (INV-018) ═══

test_priority_conflict_detected {
    conflicts := data.jdg.r01_orchestrator_core_innovations.priority_conflicts with input as {
        "_package_decisions": {
            "jdg.a": {"matched": true, "priority": 100},
            "jdg.b": {"matched": true, "priority": 100},
            "jdg.c": {"matched": true, "priority": 200},
        }
    }
    count(conflicts) == 1
    100 in conflicts
}

test_priority_conflict_clean {
    conflicts := data.jdg.r01_orchestrator_core_innovations.priority_conflicts with input as {
        "_package_decisions": {
            "jdg.a": {"matched": true, "priority": 100},
            "jdg.b": {"matched": true, "priority": 200},
        }
    }
    count(conflicts) == 0
}

# ═══ RAPORT CORE: aktywna flaga ═══

test_orchestrator_core_report {
    result := data.jdg.r01_orchestrator_core_innovations.decide with input as {
        "jdg_entrepreneur": {"r01_orchestrator_core_check": true},
        "_routing_context": {
            "tax_form": "SCALE",
            "transaction_type": "DOMESTIC_SALE",
            "entity_status": "ACTIVE",
            "evaluation_date": "2026-08-14",
            "is_cross_border": false,
        }
    }
    result.matched == true
    result.rule_id == "jdg.r01_orchestrator_core_innovations.orchestrator_core_report"
    result._routing == "REPORT"
    result.orchestrator_core.verdict_25_fields_count == 25
    result.orchestrator_core.routing_path_trace.selected_path == "SHARDED_DOMESTIC_SALE"
    result.orchestrator_core.decision_cache.deterministic == true
    result.orchestrator_core.safe_merge_integrity.allowlist_size >= 5
}
