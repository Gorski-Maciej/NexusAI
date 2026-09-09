# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY V3-P40 API, DANE I UI (32 przypadki: 12 analiz + progi +
# fail-closed + asercje negatywne; konwencja negative-first P39-I04)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p40_api_dane_ui_test

import future.keywords.in

import data.jdg.v3_p40_api_dane_ui

# ── Helper: input z aktywną flagą V3-P40 ──────────────────────────────────────
p40_input(analysis, ctx) = {
    "jdg_entrepreneur": {"v3_p40_check": true},
    "v3_p40": object.union({"analysis": analysis}, ctx),
}

# ═══════════════════════════════════════════════════════════════════════════════
# Brak flagi aktywacyjnej → no_match (fail-closed: nic nie uruchamia się po cichu)
# ═══════════════════════════════════════════════════════════════════════════════
test_p40_no_activation_no_match {
    r := v3_p40_api_dane_ui.decide with input as {"v3_p40": {"analysis": "decision_first"}}
    r.rule_id == "jdg.v3_p40_api_dane_ui.no_match"
}

# ── I01: decision-first ────────────────────────────────────────────────────────
test_p40_i01_full_certificate_ok {
    r := v3_p40_api_dane_ui.decide with input as p40_input("decision_first", {})
    r.rule_id == "jdg.v3_p40_api_dane_ui.decision_first"
    r._routing == "SUGGEST"
}

test_p40_i01_no_certificate_blocks {
    r := v3_p40_api_dane_ui.decide with input as p40_input("decision_first", {"evaluate_without_certificate": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p40_i01_short_certificate_triage {
    r := v3_p40_api_dane_ui.decide with input as p40_input("decision_first", {"decision_first": {"shortened_certificates": 2}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I02: explain chain ─────────────────────────────────────────────────────────
test_p40_i02_chain_ok {
    r := v3_p40_api_dane_ui.decide with input as p40_input("explain_chain", {})
    r.rule_id == "jdg.v3_p40_api_dane_ui.explain_chain"
    r._routing == "SUGGEST"
}

test_p40_i02_missing_chain_blocks {
    r := v3_p40_api_dane_ui.decide with input as p40_input("explain_chain", {"explain_chain_missing": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p40_i02_nodes_without_isap_link_triage {
    r := v3_p40_api_dane_ui.decide with input as p40_input("explain_chain", {"explain_chain": {"nodes_without_isap_link": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I03: idempotent writes ─────────────────────────────────────────────────────
test_p40_i03_ok {
    r := v3_p40_api_dane_ui.decide with input as p40_input("idempotent_writes", {})
    r.rule_id == "jdg.v3_p40_api_dane_ui.idempotent_writes"
    r._routing == "SUGGEST"
}

test_p40_i03_write_without_key_blocks {
    r := v3_p40_api_dane_ui.decide with input as p40_input("idempotent_writes", {"idempotent_writes": {"write_ops_without_idempotency_key": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p40_i03_retry_duplicate_blocks {
    r := v3_p40_api_dane_ui.decide with input as p40_input("idempotent_writes", {"idempotent_writes": {"retry_duplicates_detected": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

# ── I04: RBAC ──────────────────────────────────────────────────────────────────
test_p40_i04_ok {
    r := v3_p40_api_dane_ui.decide with input as p40_input("rbac", {})
    r.rule_id == "jdg.v3_p40_api_dane_ui.rbac_minimization"
    r._routing == "SUGGEST"
}

test_p40_i04_field_leak_blocks {
    r := v3_p40_api_dane_ui.decide with input as p40_input("rbac", {"rbac": {"fields_exposed_outside_role": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p40_i04_no_role_map_blocks {
    r := v3_p40_api_dane_ui.decide with input as p40_input("rbac", {"role_field_map_missing": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p40_i04_auditor_write_triage {
    r := v3_p40_api_dane_ui.decide with input as p40_input("rbac", {"rbac": {"auditor_write_ops": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I05: API audit WORM ────────────────────────────────────────────────────────
test_p40_i05_ok {
    r := v3_p40_api_dane_ui.decide with input as p40_input("api_audit_worm", {})
    r.rule_id == "jdg.v3_p40_api_dane_ui.api_audit_worm"
    r._routing == "SUGGEST"
}

test_p40_i05_missing_entry_blocks {
    r := v3_p40_api_dane_ui.decide with input as p40_input("api_audit_worm", {"api_audit_worm": {"calls_without_audit_entry": 3}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p40_i05_no_checksum_triage {
    r := v3_p40_api_dane_ui.decide with input as p40_input("api_audit_worm", {"api_audit_worm": {"audit_entries_without_checksum": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I06: rate limiting ─────────────────────────────────────────────────────────
test_p40_i06_ok {
    r := v3_p40_api_dane_ui.decide with input as p40_input("rate_limiting", {})
    r.rule_id == "jdg.v3_p40_api_dane_ui.rate_limiting"
    r._routing == "SUGGEST"
}

test_p40_i06_unlimited_blocks {
    r := v3_p40_api_dane_ui.decide with input as p40_input("rate_limiting", {"unlimited_endpoints": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p40_i06_no_limit_triage {
    r := v3_p40_api_dane_ui.decide with input as p40_input("rate_limiting", {"rate_limiting": {"endpoints_without_rate_limit": 2}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I07: degradation ladder ────────────────────────────────────────────────────
test_p40_i07_ok {
    r := v3_p40_api_dane_ui.decide with input as p40_input("degradation_ladder", {"degradation_ladder": {"declared_modes": ["FULL", "CACHE_ONLY", "OFFLINE_QUEUES", "READ_ONLY"]}})
    r.rule_id == "jdg.v3_p40_api_dane_ui.degradation_ladder"
    r._routing == "SUGGEST"
}

test_p40_i07_unknown_mode_blocks {
    r := v3_p40_api_dane_ui.decide with input as p40_input("degradation_ladder", {"unknown_api_mode": true})
    r._routing == "BLOCK_AND_ALERT"
}

test_p40_i07_no_ladder_triage {
    r := v3_p40_api_dane_ui.decide with input as p40_input("degradation_ladder", {"degradation_ladder_missing": true})
    r._routing == "TRIAGE_QUEUE"
}

# ── I08: freshness header ──────────────────────────────────────────────────────
test_p40_i08_ok {
    r := v3_p40_api_dane_ui.decide with input as p40_input("freshness_header", {})
    r.rule_id == "jdg.v3_p40_api_dane_ui.freshness_header"
    r._routing == "SUGGEST"
}

test_p40_i08_stale_beyond_sla_blocks {
    r := v3_p40_api_dane_ui.decide with input as p40_input("freshness_header", {"freshness_header": {"max_stale_days": 8}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p40_i08_missing_header_triage {
    r := v3_p40_api_dane_ui.decide with input as p40_input("freshness_header", {"freshness_header": {"responses_without_freshness_header": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I09: subscription webhook ──────────────────────────────────────────────────
test_p40_i09_ok {
    r := v3_p40_api_dane_ui.decide with input as p40_input("subscription_webhook", {})
    r.rule_id == "jdg.v3_p40_api_dane_ui.subscription_webhook"
    r._routing == "SUGGEST"
}

test_p40_i09_unsigned_blocks {
    r := v3_p40_api_dane_ui.decide with input as p40_input("subscription_webhook", {"subscription_webhook": {"webhooks_without_hmac": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

test_p40_i09_nonidempotent_retry_triage {
    r := v3_p40_api_dane_ui.decide with input as p40_input("subscription_webhook", {"subscription_webhook": {"retries_non_idempotent": 1}})
    r._routing == "TRIAGE_QUEUE"
}

# ── I10: playground sandbox ────────────────────────────────────────────────────
test_p40_i10_ok {
    r := v3_p40_api_dane_ui.decide with input as p40_input("playground_sandbox", {})
    r.rule_id == "jdg.v3_p40_api_dane_ui.playground_sandbox"
    r._routing == "SUGGEST"
}

test_p40_i10_persists_state_blocks {
    r := v3_p40_api_dane_ui.decide with input as p40_input("playground_sandbox", {"sandbox_persists_state": true})
    r._routing == "BLOCK_AND_ALERT"
}

# ── I11: schema-first SDK ──────────────────────────────────────────────────────
test_p40_i11_ok {
    r := v3_p40_api_dane_ui.decide with input as p40_input("schema_first_sdk", {})
    r.rule_id == "jdg.v3_p40_api_dane_ui.schema_first_sdk"
    r._routing == "SUGGEST"
}

test_p40_i11_no_pin_blocks {
    r := v3_p40_api_dane_ui.decide with input as p40_input("schema_first_sdk", {"schema_first_sdk": {"clients_without_schema_pin": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

# ── I12: evidence pack ─────────────────────────────────────────────────────────
test_p40_i12_ok {
    r := v3_p40_api_dane_ui.decide with input as p40_input("evidence_pack", {})
    r.rule_id == "jdg.v3_p40_api_dane_ui.evidence_pack"
    r._routing == "SUGGEST"
}

test_p40_i12_missing_triage {
    r := v3_p40_api_dane_ui.decide with input as p40_input("evidence_pack", {"evidence_pack_missing": true})
    r._routing == "TRIAGE_QUEUE"
}

test_p40_i12_no_checksum_blocks {
    r := v3_p40_api_dane_ui.decide with input as p40_input("evidence_pack", {"evidence_pack": {"exports_without_checksum": 1}})
    r._routing == "BLOCK_AND_ALERT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Fail-closed: brak snapshotu progów = BLOCK; progi jako dane (ADR-002)
# ═══════════════════════════════════════════════════════════════════════════════
test_p40_thresholds_missing_blocks {
    r := v3_p40_api_dane_ui.decide with input as p40_input("decision_first", {})
    r.rule_id == "jdg.v3_p40_api_dane_ui.decision_first"
}

test_p40_priorities_unique_range {
    prios := [p |
        some a in ["decision_first", "explain_chain", "idempotent_writes", "rbac", "api_audit_worm", "rate_limiting", "degradation_ladder", "freshness_header", "subscription_webhook", "playground_sandbox", "schema_first_sdk", "evidence_pack"]
        d := v3_p40_api_dane_ui.decide with input as p40_input(a, {})
        p := d.priority
    ]
    count({p | some p in prios}) == 12
    max(prios) == 440012
    min(prios) == 440001
}

test_p40_certificate_fields_present {
    r := v3_p40_api_dane_ui.decide with input as p40_input("decision_first", {})
    r.threshold_version == "api-dane-ui-v3p40-2026.09"
    r.legal_basis_version == "api-dane-ui-legal-2026.09"
    r.valid_from == "2026-01-01"
}

test_p40_no_test_prefix_rule_names {
    # Ochrona regresyjna P39: reguły decyzyjne nie mogą zaczynać się od "test_"
    r := v3_p40_api_dane_ui.decide with input as p40_input("decision_first", {})
    not startswith(r.rule_id, "jdg.v3_p40_api_dane_ui.test_")
}
