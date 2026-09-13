# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY NATYWNE V3-P54 KSEF/JPK DOMKNIĘCIE (konwencja
# P39/P45–P53: negative-first, granice progów, fail-closed, never-silent
# AUTO_POST, bypass → NO_MATCH, determinizm else-chain, SLA/offline/watchdog).
# Uruchomienie: opa test (0.68) / opa19 test --v0-compatible (1.9)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p54_ksef_jpk_closure_test

import data.jdg.v3_p54_ksef_jpk_closure

# ── Fixture: pełny kontekst dowodowy (stan bazowy narzędzi P54) ────────────────
full_ctx := {
	"I01_ksef_compliance_calendar": {"calendar_entries_count": 5, "entries_without_deadline": 0},
	"I02_schema_version_manager": {"schemas_total": 4, "schemas_unversioned": 0},
	"I03_pre_send_dry_run": {"invoices_total": 10, "invoices_pre_validated": 10},
	"I04_sandbox_replay": {"days_since_last_run": 0},
	"I05_status_monitor_sla": {"sessions_total": 4, "stale_count": 0},
	"I06_idempotent_outbox": {"total": 1, "duplicates_detected": 1, "duplicates_undetected": 0, "failed_escalated": 0},
	"I07_ksef_to_books_sync": {"accepted_total": 3, "unbooked_count": 0, "double_booked_count": 0},
	"I08_correction_chains": {"corrections_total": 2, "chains_broken": 0},
	"I09_offline_compliance": {"oldest_age_hours": 0.0},
	"I10_error_to_action": {"errors_total": 8, "errors_unmapped": 0},
	"I11_deadline_watchdog": {"queue_total": 1, "escalated_count": 0},
	"I12_integration_attestation": {"attestation_age_days": 0},
}

activated_input := {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": full_ctx}
deactivated_input := {"jdg_entrepreneur": {}, "v3_p54": full_ctx}

# ═══ 1. NEGATIVE-FIRST: brak aktywacji → NO_MATCH (żadnych efektów ubocznych) ═══
test_decide_no_match_without_flag {
	decide := v3_p54_ksef_jpk_closure.decide with input as deactivated_input
	decide.decision == "NO_MATCH"
	decide.matched == false
}

# ═══ 2. FAIL-CLOSED: brak snapshotu progów → NEEDS_ADVICE, nigdy cicho ═══
test_fail_closed_thresholds_missing {
	decide := v3_p54_ksef_jpk_closure.decide with input as activated_input
	with data.jdg.thresholds.v3_p54 as {}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
	decide.priority == 0
}

# ═══ 3. ROUTER: stan bazowy (wszystkie bramki zielone) → all_green PASS ═══
test_router_all_green_pass {
	decide := v3_p54_ksef_jpk_closure.decide with input as activated_input
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.all_green"
	decide.decision == "PASS"
}

# ═══ 4. ROUTER determinizm: dwie ewaluacje = ten sam werdykt ═══
test_router_deterministic {
	a := v3_p54_ksef_jpk_closure.decide with input as activated_input
	b := v3_p54_ksef_jpk_closure.decide with input as activated_input
	a == b
}

# ═══ 5. I09: kolejka offline ponad grace 168h → BLOCK (twarde prawo) ═══
test_i09_blocks_past_grace {
	ctx := object.union(full_ctx, {"I09_offline_compliance": {"oldest_age_hours": 169.0}})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.offline_compliance"
	decide.decision == "BLOCK"
}

# ═══ 5b. I09 granica: dokładnie 168h = PASS (grace włącznie) ═══
test_i09_pass_at_grace_boundary {
	ctx := object.union(full_ctx, {"I09_offline_compliance": {"oldest_age_hours": 168.0}})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.all_green"
}

# ═══ 6. I03: walidacja pre-send poniżej 100% → BLOCK ═══
test_i03_blocks_below_validation_min {
	ctx := object.union(full_ctx, {"I03_pre_send_dry_run": {"invoices_total": 10, "invoices_pre_validated": 8}})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.pre_send_dry_run"
	decide.decision == "BLOCK"
}

# ═══ 7. I05: sesje STALE (SENT bez UPO ponad SLA) → BLOCK ═══
test_i05_blocks_on_stale {
	ctx := object.union(full_ctx, {"I05_status_monitor_sla": {"sessions_total": 4, "stale_count": 2}})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.status_monitor_sla"
	decide.decision == "BLOCK"
}

# ═══ 8. I02: schemat bez okna wersji → BLOCK (przełączenie FA(2)→FA(3)) ═══
test_i02_blocks_unversioned_schema {
	ctx := object.union(full_ctx, {"I02_schema_version_manager": {"schemas_total": 4, "schemas_unversioned": 1}})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.schema_versions"
	decide.decision == "BLOCK"
}

# ═══ 9. I04: sandbox replay przestarzały (>14 dni) → BLOCK ═══
test_i04_blocks_stale_sandbox {
	ctx := object.union(full_ctx, {"I04_sandbox_replay": {"days_since_last_run": 15}})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.sandbox_replay"
	decide.decision == "BLOCK"
}

# ═══ 10. I06: duplikat NIEwykryty → BLOCK (naruszenie exactly-once) ═══
test_i06_blocks_undetected_duplicate {
	ctx := object.union(full_ctx, {"I06_idempotent_outbox": {"total": 2, "duplicates_detected": 0, "duplicates_undetected": 1, "failed_escalated": 0}})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.idempotent_outbox"
	decide.decision == "BLOCK"
}

# ═══ 10b. I06: duplikat WYKRYTY = kontrola pozytywna → nie blokuje ═══
test_i06_pass_on_detected_duplicate {
	ctx := object.union(full_ctx, {"I06_idempotent_outbox": {"total": 2, "duplicates_detected": 1, "duplicates_undetected": 0, "failed_escalated": 0}})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.all_green"
}

# ═══ 11. I11: faktura w kolejce ponad próg watchdog → BLOCK (eskalacja P0) ═══
test_i11_blocks_escalated {
	ctx := object.union(full_ctx, {"I11_deadline_watchdog": {"queue_total": 3, "escalated_count": 1}})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.deadline_watchdog"
	decide.decision == "BLOCK"
}

# ═══ 12. I07: przyjęte bez zaksięgowania → MANUAL_REVIEW (sync P32) ═══
test_i07_manual_review_unbooked {
	ctx := object.union(full_ctx, {"I07_ksef_to_books_sync": {"accepted_total": 3, "unbooked_count": 1, "double_booked_count": 0}})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.ksef_to_books_sync"
	decide.decision == "MANUAL_REVIEW"
}

# ═══ 12b. I07: podwójne księgowanie → MANUAL_REVIEW (idempotencja wspólna P32) ═══
test_i07_manual_review_double_booked {
	ctx := object.union(full_ctx, {"I07_ksef_to_books_sync": {"accepted_total": 3, "unbooked_count": 0, "double_booked_count": 1}})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.ksef_to_books_sync"
	decide.decision == "MANUAL_REVIEW"
}

# ═══ 13. I01: wpis kalendarza bez terminu → MANUAL_REVIEW ═══
test_i01_manual_review_incomplete_calendar {
	ctx := object.union(full_ctx, {"I01_ksef_compliance_calendar": {"calendar_entries_count": 5, "entries_without_deadline": 2}})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.compliance_calendar"
	decide.decision == "MANUAL_REVIEW"
}

# ═══ 14. I08: przerwany łańcuch korekty (art. 106j) → MANUAL_REVIEW ═══
test_i08_manual_review_broken_chain {
	ctx := object.union(full_ctx, {"I08_correction_chains": {"corrections_total": 2, "chains_broken": 1}})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.correction_chains"
	decide.decision == "MANUAL_REVIEW"
}

# ═══ 15. I10: błąd MF bez zmapowanej akcji → MANUAL_REVIEW ═══
test_i10_manual_review_unmapped_error {
	ctx := object.union(full_ctx, {"I10_error_to_action": {"errors_total": 8, "errors_unmapped": 3}})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.error_to_action"
	decide.decision == "MANUAL_REVIEW"
}

# ═══ 16. I12: attestation przestarzały (>90 dni) → NEEDS_ADVICE ═══
test_i12_needs_advice_stale_attestation {
	ctx := object.union(full_ctx, {"I12_integration_attestation": {"attestation_age_days": 91}})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.integration_attestation"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 17. PRIORYTET ROUTERA: offline BLOCK wygrywa z attestation NEEDS_ADVICE ═══
test_router_priority_offline_over_attestation {
	ctx := object.union(full_ctx, {
		"I09_offline_compliance": {"oldest_age_hours": 200.0},
		"I12_integration_attestation": {"attestation_age_days": 99},
	})
	decide := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	decide.rule_id == "jdg.v3_p54_ksef_jpk_closure.offline_compliance"
}

# ═══ 18. NEVER-SILENT: każda decyzja ma rule_id + reason (protokół 05) ═══
test_verdict_has_rule_id_and_reason {
	decide := v3_p54_ksef_jpk_closure.decide with input as activated_input
	decide.rule_id != null
	decide.reason != null
	decide.reason != ""
}

# ═══ 19. KONTRAKT TEMPORALNY: werdykt niesie okno valid_from/valid_to (P05/P53) ═══
test_verdict_carries_temporal_window {
	decide := v3_p54_ksef_jpk_closure.decide with input as activated_input
	decide.valid_from == "2026-01-01"
	decide.valid_to == null
}

# ═══ 20. ZERO HARDCODE: progi czytane z snapshotu ADR-002 (cała podmiana) ═══
test_thresholds_from_data_not_hardcoded {
	ctx := object.union(full_ctx, {"I09_offline_compliance": {"oldest_age_hours": 49.0}})
	decide2 := v3_p54_ksef_jpk_closure.decide with input as {"jdg_entrepreneur": {"v3_p54_check": true}, "v3_p54": ctx}
	with data.jdg.thresholds.v3_p54 as {"v3_p54_offline_grace_hours": 48}
	decide2.rule_id == "jdg.v3_p54_ksef_jpk_closure.offline_compliance"
	decide2.decision == "BLOCK"
}
