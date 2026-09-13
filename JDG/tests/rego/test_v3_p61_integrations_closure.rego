package jdg.v3_p61_integrations_closure_test

import data.jdg.v3_p61_integrations_closure

# Pełny kontekst zielony (wszystkie 12 analiz PASS — wartości z silników P61)
full_ctx := {
	"I01_integration_contract": {"integrations_total": 4, "contract_violators": []},
	"I02_circuit_breaker": {"mechanism_present": true},
	"I03_reference_provenance": {"datasets": [], "incomplete": []},
	"I04_sandbox_replay": {"integrations_total": 4, "missing_replay": []},
	"I05_cache_ttl": {"cache_manifest_present": true, "stale_entries": []},
	"I06_bank_reconciliation": {"unmatched_without_path_pct": 0, "conflicts_without_candidates": []},
	"I07_holiday_rate_path": {"path_present": true, "holiday_tests": 3},
	"I08_integration_registry": {"entries": [], "invalid_statuses": []},
	"I09_degradation_ladder": {"integrations_total": 4, "ladder_too_short": []},
	"I10_outbox_pattern": {"idempotent": true, "aged_entries": []},
	"I11_external_sla": {"over_threshold": [], "worst_p95_ms": 0},
	"I12_integration_attestation": {"attestation_age_days": 0, "reference_data_versions": true},
}

activated_input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": full_ctx}
deactivated_input := {"jdg_entrepreneur": {}, "v3_p61": full_ctx}

# ═══ 1. Fail-closed: brak flagi aktywacji → NO_MATCH ═══
test_no_match_without_flag {
	decide := v3_p61_integrations_closure.decide with input as deactivated_input
	decide.decision == "NO_MATCH"
	decide.rule_id == "jdg.v3_p61_integrations_closure.no_match"
}

# ═══ 2. Fail-closed: brak snapshotu progów → NEEDS_ADVICE (precedencja) ═══
test_thresholds_missing_fail_closed {
	decide := v3_p61_integrations_closure.decide with input as activated_input
	with data.jdg.thresholds.v3_p61 as {}
	decide.rule_id == "jdg.v3_p61_integrations_closure.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 3. Kontekst zielony → PASS ═══
test_all_green_pass {
	decide := v3_p61_integrations_closure.decide with input as activated_input
	decide.decision == "PASS"
	decide.rule_id == "jdg.v3_p61_integrations_closure.all_green"
}

# ═══ 4. I01 BLOCK: integracja bez pełnego kontraktu ═══
test_i01_block_on_violator {
	input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": object.union(full_ctx, {"I01_integration_contract": {"integrations_total": 4, "contract_violators": ["isap: brak elementów [\"runbook\"]"]}})}
	decide := v3_p61_integrations_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p61_integrations_closure.integration_standard_contract"
}

# ═══ 5. I02 NEEDS_ADVICE: brak mechanizmu breakera ═══
test_i02_advice_no_mechanism {
	input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": object.union(full_ctx, {"I02_circuit_breaker": {"mechanism_present": false}})}
	decide := v3_p61_integrations_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p61_integrations_closure.circuit_breaker"
}

# ═══ 6. I03 BLOCK: zbiór bez pola provenance ═══
test_i03_block_incomplete_provenance {
	input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": object.union(full_ctx, {"I03_reference_provenance": {"datasets": ["fx:NBP-A:EUR"], "incomplete": ["fx:NBP-A:EUR: brak pól [\"source\"]"]}})}
	decide := v3_p61_integrations_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p61_integrations_closure.reference_data_provenance"
}

# ═══ 7. I04 NEEDS_ADVICE: integracja bez sandbox replay ═══
test_i04_advice_missing_replay {
	input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": object.union(full_ctx, {"I04_sandbox_replay": {"integrations_total": 4, "missing_replay": ["isap"]}})}
	decide := v3_p61_integrations_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 8. I05 NEEDS_ADVICE: cache bez manifestu ═══
test_i05_advice_no_manifest {
	input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": object.union(full_ctx, {"I05_cache_ttl": {"cache_manifest_present": false, "stale_entries": []}})}
	decide := v3_p61_integrations_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 9. I06 BLOCK: rozjazd bez ścieżki (ponad próg %) ═══
test_i06_block_unmatched_no_path {
	input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": object.union(full_ctx, {"I06_bank_reconciliation": {"unmatched_without_path_pct": 66.7, "conflicts_without_candidates": []}})}
	decide := v3_p61_integrations_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p61_integrations_closure.bank_reconciliation_contract"
}

# ═══ 10. I06 BLOCK: konflikt bez kandydatów ═══
test_i06_block_conflicts {
	input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": object.union(full_ctx, {"I06_bank_reconciliation": {"unmatched_without_path_pct": 0, "conflicts_without_candidates": ["TX-101"]}})}
	decide := v3_p61_integrations_closure.decide with input as input
	decide.decision == "BLOCK"
}

# ═══ 11. I07 BLOCK: brak ścieżki ostatniej tabeli NBP ═══
test_i07_block_no_path {
	input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": object.union(full_ctx, {"I07_holiday_rate_path": {"path_present": false, "holiday_tests": 0}})}
	decide := v3_p61_integrations_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p61_integrations_closure.holiday_rate_path"
}

# ═══ 12. I08 BLOCK: status poza dozwolonymi ═══
test_i08_block_invalid_status {
	input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": object.union(full_ctx, {"I08_integration_registry": {"entries": [{"id": "x", "status": "BETA"}], "invalid_statuses": ["x: status=BETA"]}})}
	decide := v3_p61_integrations_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p61_integrations_closure.integration_registry"
}

# ═══ 13. I09 NEEDS_ADVICE: drabina krótsza niż próg ═══
test_i09_advice_short_ladder {
	input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": object.union(full_ctx, {"I09_degradation_ladder": {"integrations_total": 4, "ladder_too_short": ["isap: 1/3 szczebli"]}})}
	decide := v3_p61_integrations_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 14. I10 NEEDS_ADVICE: outbox bez idempotencji ═══
test_i10_advice_not_idempotent {
	input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": object.union(full_ctx, {"I10_outbox_pattern": {"idempotent": false, "aged_entries": []}})}
	decide := v3_p61_integrations_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 15. I11 BLOCK: SLA ponad próg ═══
test_i11_block_sla_over {
	input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": object.union(full_ctx, {"I11_external_sla": {"over_threshold": ["ksef-mf"], "worst_p95_ms": 8200}})}
	decide := v3_p61_integrations_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p61_integrations_closure.external_sla_monitoring"
}

# ═══ 16. I12 NEEDS_ADVICE: attestation przeterminowana ═══
test_i12_advice_stale_attestation {
	input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": object.union(full_ctx, {"I12_integration_attestation": {"attestation_age_days": 120, "reference_data_versions": true}})}
	decide := v3_p61_integrations_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 17. I12 NEEDS_ADVICE: brak wersji danych referencyjnych ═══
test_i12_advice_no_ref_versions {
	input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": object.union(full_ctx, {"I12_integration_attestation": {"attestation_age_days": 0, "reference_data_versions": false}})}
	decide := v3_p61_integrations_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 18. Priorytety: BLOCK wygrywa z NEEDS_ADVICE (I01 przed I02) ═══
test_block_precedence {
	input := {"jdg_entrepreneur": {"v3_p61_check": true}, "v3_p61": object.union(full_ctx, {"I01_integration_contract": {"integrations_total": 4, "contract_violators": ["x"]}, "I02_circuit_breaker": {"mechanism_present": false}})}
	decide := v3_p61_integrations_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.priority == 461001
}
