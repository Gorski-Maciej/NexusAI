# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY NATYWNE V3-P57 INGEST DANYCH (konwencja P39/P45–P56:
# negative-first, granice progów, fail-closed, never-silent AUTO_POST, bypass →
# NO_MATCH, determinizm else-chain, schemat / NIP checksum / dedup / WORM /
# statusy / repair path / reconciliation / chaos / metryki / proweniencja /
# tenant isolation / rate governor).
# Uruchomienie: opa test (0.68) / opa19 test --v0-compatible (1.9)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p57_ingest_data_test

import data.jdg.v3_p57_ingest_data

# ── Fixture: pełny kontekst dowodowy (stan bazowy narzędzi P57) ────────────────
full_ctx := {
	"I01_ingest_contract_schema": {"schema_version": "jdg.ingest.v1", "docs_total": 8, "rejected": ["DOC-003"], "leaked_into_engine": []},
	"I02_nip_checksum_gate": {"bad_total": 2, "rejected_bad": ["BAD-NIP-1", "BAD-NIP-2"], "accepted_bad": []},
	"I03_semantic_dedup_key": {"dups_total": 1, "registered": ["DUP-1"], "unregistered": []},
	"I04_original_first_worm": {"processed_total": 8, "with_worm": ["DOC-1", "DOC-2", "DOC-3", "DOC-4", "DOC-5", "DOC-6", "DOC-7", "DOC-8"], "missing_worm": []},
	"I05_status_state_machine": {"docs_total": 8, "illegal_transitions": 0, "missing_status": 0},
	"I06_repair_path_for_rejects": {"rejected_total": 1, "with_repair": ["DOC-003"], "no_repair": []},
	"I07_bank_reconciliation_engine": {"feed_total": 100, "matched": 97, "unmatched": 3, "unmatched_pct": 3.0},
	"I08_ingest_chaos_suite": {"cases_total": 6, "detected": ["NEG-AMT", "BAD-TYPE", "DUP", "MISSING-FIELD", "OVERFLOW", "NULL-NIP"], "undetected": []},
	"I09_ingest_metrics": {"volume": 100, "rejects": 3, "duplicates": 1, "reject_pct": 3.0, "missing_metrics": []},
	"I10_provenance_chain_to_certificate": {"certs_total": 4, "chained": ["CERT-1", "CERT-2", "CERT-3", "CERT-4"], "broken": []},
	"I11_multi_tenant_isolation": {"records_total": 8, "missing_tenant": [], "cross_tenant_leaks": 0},
	"I12_ingest_rate_governor": {"channels_total": 4, "monitored": ["ksef", "bank", "csv", "api"], "unmonitored": []},
}

activated_input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": full_ctx}
deactivated_input := {"jdg_entrepreneur": {}, "v3_p57": full_ctx}

# ═══ 1. NEGATIVE-FIRST: brak aktywacji → NO_MATCH (żadnych efektów ubocznych) ═══
test_decide_no_match_without_flag {
	decide := v3_p57_ingest_data.decide with input as deactivated_input
	decide.decision == "NO_MATCH"
	decide.matched == false
}

# ═══ 2. FAIL-CLOSED: brak snapshotu progów → NEEDS_ADVICE, nigdy cicho ═══
test_fail_closed_thresholds_missing {
	decide := v3_p57_ingest_data.decide with input as activated_input
	with data.jdg.thresholds.v3_p57 as {}
	decide.rule_id == "jdg.v3_p57_ingest_data.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
	decide.priority == 0
}

# ═══ 3. ROUTER: stan bazowy (wszystkie bramki zielone) → all_green PASS ═══
test_router_all_green_pass {
	decide := v3_p57_ingest_data.decide with input as activated_input
	decide.rule_id == "jdg.v3_p57_ingest_data.all_green"
	decide.decision == "PASS"
}

# ═══ 4. ROUTER determinizm: dwie ewaluacje = ten sam werdykt ═══
test_router_deterministic {
	a := v3_p57_ingest_data.decide with input as activated_input
	b := v3_p57_ingest_data.decide with input as activated_input
	a == b
}

# ═══ 5. I01: dokument niezgodny ze schematem, który WDARŁ się do silnika = BLOCK ═══
test_i01_leaked_doc_blocks {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I01_ingest_contract_schema": {"schema_version": "jdg.ingest.v1", "docs_total": 8, "rejected": ["DOC-003"], "leaked_into_engine": ["DOC-009"]}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.ingest_contract_schema"
	decide.decision == "BLOCK"
	decide.priority == 457001
}

# ═══ 5b. I01 pozytywna kontrola: schemat ODRZUCA zły dokument (leak=0) → nie BLOCK ═══
test_i01_rejection_positive_control {
	decide := v3_p57_ingest_data.decide with input as activated_input
	decide.rule_id != "jdg.v3_p57_ingest_data.ingest_contract_schema"
}

# ═══ 6. I02: błędny NIP PRZYJĘTY bez odrzucenia = BLOCK ═══
test_i02_accepted_bad_nip_blocks {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I02_nip_checksum_gate": {"bad_total": 2, "rejected_bad": ["BAD-NIP-1"], "accepted_bad": ["BAD-NIP-2"]}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.nip_checksum_gate"
	decide.decision == "BLOCK"
}

# ═══ 6b. I02 granica: zero przyjętych błędnych → brak blokady (pozytywna kontrola) ═══
test_i02_all_bad_rejected_no_block {
	decide := v3_p57_ingest_data.decide with input as activated_input
	decide.decision != "BLOCK"
}

# ═══ 7. I03: duplikat NIEZAREJESTROWANY do przeglądu = BLOCK ═══
test_i03_unregistered_duplicate_blocks {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I03_semantic_dedup_key": {"dups_total": 2, "registered": ["DUP-1"], "unregistered": ["DUP-2"]}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.semantic_dedup_key"
	decide.decision == "BLOCK"
}

# ═══ 8. I04: dokument przetworzony BEZ checksumy oryginału = BLOCK ═══
test_i04_missing_worm_blocks {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I04_original_first_worm": {"processed_total": 2, "with_worm": ["DOC-1"], "missing_worm": ["DOC-2"]}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.original_first_worm"
	decide.decision == "BLOCK"
}

# ═══ 9. I05: nielegalne przejście statusu = NEEDS_ADVICE ═══
test_i05_illegal_transition_advice {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I05_status_state_machine": {"docs_total": 8, "illegal_transitions": 1, "missing_status": 0}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.status_state_machine"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 9b. I05 granica: 0 nielegalnych + 0 braków statusu = nieaktywna ═══
test_i05_boundary_zero_inactive {
	decide := v3_p57_ingest_data.decide with input as activated_input
	decide.rule_id != "jdg.v3_p57_ingest_data.status_state_machine"
}

# ═══ 10. I06: odrzucony dokument BEZ ścieżki naprawy = NEEDS_ADVICE ═══
test_i06_no_repair_path_advice {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I06_repair_path_for_rejects": {"rejected_total": 2, "with_repair": ["DOC-003"], "no_repair": ["DOC-004"]}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.repair_path_for_rejects"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 11. I07: rozjazd powyżej progu 5% = MANUAL_REVIEW ═══
test_i07_unmatched_above_threshold {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I07_bank_reconciliation_engine": {"feed_total": 100, "matched": 94, "unmatched": 6, "unmatched_pct": 6.0}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.bank_reconciliation_engine"
	decide.decision == "MANUAL_REVIEW"
}

# ═══ 11b. I07 granica: dokładnie na progu 5% → NIE aktywne (tylko > próg) ═══
test_i07_boundary_at_threshold_inactive {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I07_bank_reconciliation_engine": {"feed_total": 100, "matched": 95, "unmatched": 5, "unmatched_pct": 5.0}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id != "jdg.v3_p57_ingest_data.bank_reconciliation_engine"
}

# ═══ 11c. I07 z prógiem obniżonym z ADR-002: 4% > próg 3% = MANUAL_REVIEW ═══
test_i07_threshold_from_adr002 {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I07_bank_reconciliation_engine": {"feed_total": 100, "matched": 96, "unmatched": 4, "unmatched_pct": 4.0}})}
	decide := v3_p57_ingest_data.decide with input as input
	with data.jdg.thresholds.v3_p57 as {"v3_p57_recon_unmatched_max_pct": 3}
	decide.rule_id == "jdg.v3_p57_ingest_data.bank_reconciliation_engine"
}

# ═══ 12. I08: przypadek chaosu NIEWYKRYTY = BLOCK (pozytywna kontrola detektorów) ═══
test_i08_undetected_chaos_blocks {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I08_ingest_chaos_suite": {"cases_total": 6, "detected": ["NEG-AMT", "BAD-TYPE", "DUP", "MISSING-FIELD", "OVERFLOW"], "undetected": ["NULL-NIP"]}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.ingest_chaos_suite"
	decide.decision == "BLOCK"
	decide.metrics.undetected == 1
}

# ═══ 13. I09: wskaźnik odrzuceń powyżej progu 10% = NEEDS_ADVICE ═══
test_i09_reject_rate_above_threshold {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I09_ingest_metrics": {"volume": 100, "rejects": 12, "duplicates": 1, "reject_pct": 12.0, "missing_metrics": []}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.ingest_metrics"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 13b. I09: niekompletne metryki (brak wolumenu) = NEEDS_ADVICE (else-branch) ═══
test_i09_missing_metrics_advice {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I09_ingest_metrics": {"volume": 0, "rejects": 0, "duplicates": 0, "reject_pct": 0, "missing_metrics": ["processing_time_p95"]}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.ingest_metrics"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 13c. I09 granica: dokładnie 10% → nieaktywne (tylko > próg) ═══
test_i09_boundary_at_threshold_inactive {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I09_ingest_metrics": {"volume": 100, "rejects": 10, "duplicates": 1, "reject_pct": 10.0, "missing_metrics": []}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id != "jdg.v3_p57_ingest_data.ingest_metrics"
}

# ═══ 14. I10: certyfikat BEZ checksumy oryginału = BLOCK (łańcuch przerwany) ═══
test_i10_broken_provenance_blocks {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I10_provenance_chain_to_certificate": {"certs_total": 4, "chained": ["CERT-1", "CERT-2", "CERT-3"], "broken": ["CERT-4"]}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.provenance_chain_to_certificate"
	decide.decision == "BLOCK"
}

# ═══ 15. I11: rekord bez tenant_id = BLOCK ═══
test_i11_missing_tenant_blocks {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I11_multi_tenant_isolation": {"records_total": 8, "missing_tenant": ["DOC-005"], "cross_tenant_leaks": 0}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.multi_tenant_isolation"
	decide.decision == "BLOCK"
}

# ═══ 15b. I11: przeciek międzytenantowy (bez braków tenant_id) = BLOCK (else-branch) ═══
test_i11_cross_tenant_leak_blocks {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I11_multi_tenant_isolation": {"records_total": 8, "missing_tenant": [], "cross_tenant_leaks": 2}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.multi_tenant_isolation"
	decide.decision == "BLOCK"
	decide.metrics.cross_tenant_leaks == 2
}

# ═══ 16. I12: kanał BEZ licznika wolumenu = NEEDS_ADVICE ═══
test_i12_unmonitored_channel_advice {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I12_ingest_rate_governor": {"channels_total": 4, "monitored": ["ksef", "bank", "csv"], "unmonitored": ["api"]}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.ingest_rate_governor"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 17. ROUTER priorytet: BLOCK (chaos) wygrywa z NEEDS_ADVICE (metryki) ═══
test_router_block_precedence_over_advice {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I08_ingest_chaos_suite": {"cases_total": 6, "detected": [], "undetected": ["X"]}, "I09_ingest_metrics": {"volume": 100, "rejects": 50, "duplicates": 0, "reject_pct": 50.0, "missing_metrics": []}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.ingest_chaos_suite"
	decide.decision == "BLOCK"
}

# ═══ 18. ROUTER priorytet: NEEDS_ADVICE (governor) wygrywa z MANUAL_REVIEW (recon) ═══
test_router_advice_precedence_over_review {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I07_bank_reconciliation_engine": {"feed_total": 100, "matched": 90, "unmatched": 10, "unmatched_pct": 10.0}, "I12_ingest_rate_governor": {"channels_total": 4, "monitored": ["ksef"], "unmonitored": ["bank", "csv", "api"]}})}
	decide := v3_p57_ingest_data.decide with input as input
	decide.rule_id == "jdg.v3_p57_ingest_data.ingest_rate_governor"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 19. Werydykty zawsze mają pełny kształt kontraktu (P03) ═══
test_verdict_shape_full_contract {
	decide := v3_p57_ingest_data.decide with input as activated_input
	decide.rule_id != ""
	decide["package"] == "jdg.v3_p57_ingest_data"
	decide._legal_basis != ""
	decide.valid_from == "2026-01-01"
}

# ═══ 20. Żaden werdykt P57 nigdy nie zwraca AUTO_POST (forteca) ═══
test_no_auto_post_anywhere {
	decide := v3_p57_ingest_data.decide with input as activated_input
	decide.decision != "AUTO_POST"
	input2 := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I01_ingest_contract_schema": {"schema_version": "jdg.ingest.v1", "docs_total": 8, "rejected": [], "leaked_into_engine": ["DOC-X"]}})}
	decide2 := v3_p57_ingest_data.decide with input as input2
	decide2.decision != "AUTO_POST"
}

# ═══ 21. Fail-closed brakuje snapshotu: flaga aktywna ale progi puste ═══
test_fail_closed_takes_precedence {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I08_ingest_chaos_suite": {"cases_total": 6, "detected": [], "undetected": ["X"]}})}
	decide := v3_p57_ingest_data.decide with input as input
	with data.jdg.thresholds.v3_p57 as {}
	decide.rule_id == "jdg.v3_p57_ingest_data.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 22. Metryki analizy dedup: klucz semantyczny z progów (ADR-002), nie hardcode ═══
test_dedup_key_from_thresholds {
	input := {"jdg_entrepreneur": {"v3_p57_check": true}, "v3_p57": object.union(full_ctx, {"I03_semantic_dedup_key": {"dups_total": 1, "registered": [], "unregistered": ["DUP-1"]}})}
	decide := v3_p57_ingest_data.decide with input as input
	with data.jdg.thresholds.v3_p57 as {"v3_p57_dedup_key_fields": ["nip", "data", "kwota_gr", "numer", "waluta"]}
	contains(decide.reason, "waluta")
}
