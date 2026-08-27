# NexusAI JDG - Micro quality and boundary contract V3-13
# Legacy generated micro files remain source data; this package governs their
# audit, normalization, and explicit micro-to-macro handoff.

package jdg.micro.quality_v3_13

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.quality_v3_13.no_match",
    "package": "jdg.micro.quality_v3_13",
    "priority": 999999,
    "micro_decision_mode": "DECOUPLED",
    "no_auto_post": true,
}

_snapshot := object.get(data.jdg.thresholds, "micro_quality_v3_13", {})
_snapshot_ok := count(_snapshot) > 0

_th(key, fallback) = value {
    _snapshot_ok
    object.get(_snapshot, key, null) != null
    value := object.get(_snapshot, key, fallback)
} else = fallback

_certificate(priority, extra) = result {
    base := {
        "matched": true,
        "package": "jdg.micro.quality_v3_13",
        "priority": priority,
        "threshold_version": object.get(_snapshot, "threshold_version", "MISSING"),
        "legal_basis_version": object.get(_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_snapshot, "valid_from", null),
        "valid_to": object.get(_snapshot, "valid_to", null),
        "micro_decision_mode": "DECOUPLED",
        "no_auto_post": true,
    }
    result := object.union(base, extra)
}

_optional_or_null(raw, key) = value {
    value := object.get(raw, key, null)
    value != ""
} else = null {
    true
}

_normalize_optional(raw) = normalized {
    normalized := object.union(raw, {
        "vat_rate": _optional_or_null(raw, "vat_rate"),
        "rounding_level": _optional_or_null(raw, "rounding_level"),
        "gtu_code": _optional_or_null(raw, "gtu_code"),
        "pit_form": _optional_or_null(raw, "pit_form"),
        "pit_rate": _optional_or_null(raw, "pit_rate"),
        "pit_bracket": _optional_or_null(raw, "pit_bracket"),
        "pit_annual_return_type": _optional_or_null(raw, "pit_annual_return_type"),
        "kus_qualification": _optional_or_null(raw, "kus_qualification"),
        "zus_social_base_type": _optional_or_null(raw, "zus_social_base_type"),
        "zus_health_rate": _optional_or_null(raw, "zus_health_rate"),
        "business_status": _optional_or_null(raw, "business_status"),
        "_routing": _optional_or_null(raw, "_routing"),
        "_routing_reason": _optional_or_null(raw, "_routing_reason"),
        "valid_from": object.get(raw, "valid_from", null),
        "valid_to": object.get(raw, "valid_to", null),
        "_legal_basis": object.get(raw, "_legal_basis", null),
        "_warnings": object.get(raw, "_warnings", []),
        "micro_boundary": "NORMALIZED_V3_13",
        "micro_decision_mode": "DECOUPLED",
        "no_auto_post": true,
    })
}

_audit_routing(true) = ""
_audit_routing(false) = "BLOCK_AND_ALERT"

_binding_routing(true) = ""
_binding_routing(false) = "TRIAGE_QUEUE"

fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.micro.quality_v3_13.thresholds_missing",
    "package": "jdg.micro.quality_v3_13",
    "priority": 0,
    "decision_mode": "BLOCK",
    "micro_decision_mode": "DECOUPLED",
    "no_auto_post": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Micro V3-13: brak wersjonowanego snapshotu jakości.",
    "_legal_basis": "ADR-002; V1 zasada 6 fail-closed",
    "_warnings": ["[V3-13] Audyt micro zablokowany do czasu dostarczenia snapshotu."],
}

audit_contract_decision := verdict {
    audit := object.get(input, "micro_audit", {})
    object.get(audit, "enabled", false) == true
    object.get(audit, "mode", "AUDIT") == "AUDIT"
    files := object.get(audit, "files", 0)
    rules := object.get(audit, "rules", 0)
    syntax_errors := object.get(audit, "syntax_errors", 0)
    duplicates := object.get(audit, "duplicate_rule_ids", 0)
    empty_fields := object.get(audit, "empty_optional_fields", 0)
    stubs := object.get(audit, "stub_findings", 0)
    passed := syntax_errors == 0
    passed

    verdict := _certificate(110, {
        "rule_id": "jdg.micro.quality_v3_13.audit_contract",
        "decision_mode": "SUGGEST",
        "audit_files": files,
        "audit_rules": rules,
        "syntax_errors": syntax_errors,
        "duplicate_rule_ids": duplicates,
        "empty_optional_fields": empty_fields,
        "stub_findings": stubs,
        "audit_passed": passed,
        "_routing": _audit_routing(passed),
        "_routing_reason": "Whole-tree micro audit: syntax and rule_id contract evaluated.",
        "_legal_basis": "JDG Micro V3-13 quality contract; MANIFEST rule_id registry",
        "_warnings": ["[V3-13] Wynik audytu jest decoupled i wymaga bramki CI przed AUTO_POST."],
    })
}

micro_macro_binding_decision := verdict {
    audit := object.get(input, "micro_audit", {})
    object.get(audit, "enabled", false) == true
    object.get(audit, "mode", "AUDIT") == "BINDING"
    binding := object.get(audit, "binding", {})
    object.get(binding, "micro_rule_id", "") != ""
    object.get(binding, "macro_rule_id", "") != ""
    object.get(binding, "legal_basis", "") != ""
    object.get(binding, "golden_input_ref", "") != ""

    verdict := _certificate(120, {
        "rule_id": "jdg.micro.quality_v3_13.micro_macro_binding",
        "decision_mode": "SUGGEST",
        "binding": binding,
        "binding_passed": true,
        "_routing": "",
        "_routing_reason": "Micro rule bound to macro rule with legal basis and golden input.",
        "_legal_basis": "V1 Control/Data Plane; V2 F2 Legal Twin",
        "_warnings": [],
    })
}

normalized_boundary_decision := verdict {
    audit := object.get(input, "micro_audit", {})
    object.get(audit, "enabled", false) == true
    object.get(audit, "mode", "AUDIT") == "NORMALIZE"
    raw := object.get(input, "micro_verdict", {})
    object.get(raw, "rule_id", "") != ""
    normalized := _normalize_optional(raw)
    base := _certificate(130, normalized)
    verdict := object.union(base, {
        "rule_id": "jdg.micro.quality_v3_13.normalized_boundary",
        "decision_mode": "SUGGEST",
        "binding_passed": object.get(audit, "binding_passed", false),
        "_routing": _binding_routing(object.get(audit, "binding_passed", false)),
        "_routing_reason": "Raw micro verdict normalized; macro handoff remains decoupled.",
        "_legal_basis": "JDG Micro V3-13 boundary normalization contract",
        "_warnings": ["[V3-13] Normalizacja nie zatwierdza automatycznego księgowania."],
    })
}

golden_input_decision := verdict {
    audit := object.get(input, "micro_audit", {})
    object.get(audit, "enabled", false) == true
    object.get(audit, "mode", "AUDIT") == "GOLDEN"
    object.get(audit, "golden_input_ref", "") != ""
    object.get(audit, "golden_verdict_hash", "") != ""

    verdict := _certificate(140, {
        "rule_id": "jdg.micro.quality_v3_13.golden_input",
        "decision_mode": "SUGGEST",
        "golden_input_ref": object.get(audit, "golden_input_ref", ""),
        "golden_verdict_hash": object.get(audit, "golden_verdict_hash", ""),
        "_routing": "",
        "_routing_reason": "Golden input and verdict hash supplied for replay.",
        "_legal_basis": "V2 F3 Golden Oracle; V1 zasada 9 audytowalność",
        "_warnings": [],
    })
}

domain_certificate := _certificate(200, {
    "rule_id": "jdg.micro.quality_v3_13.domain_certificate",
    "decision_mode": "INFORM",
    "domain": "micro_quality_boundary",
    "audit_mode": "DECOUPLED",
    "raw_empty_fields_are_normalized": true,
    "macro_handoff": "EXPLICIT_BINDING_ONLY",
    "snapshot_status": "OK",
    "_routing": "",
    "_routing_reason": "Micro V3-13 quality contract active; no audit event supplied.",
    "_legal_basis": "JDG Micro V3-13; V1/V2 Control Plane and Legal Twin",
    "_warnings": [],
})

decide := fail_closed_decision {
    not _snapshot_ok
}

decide := audit_contract_decision {
    _snapshot_ok
}

decide := micro_macro_binding_decision {
    _snapshot_ok
    not audit_contract_decision
}

decide := normalized_boundary_decision {
    _snapshot_ok
    not audit_contract_decision
    not micro_macro_binding_decision
}

decide := golden_input_decision {
    _snapshot_ok
    not audit_contract_decision
    not micro_macro_binding_decision
    not normalized_boundary_decision
}

decide := domain_certificate {
    _snapshot_ok
}
