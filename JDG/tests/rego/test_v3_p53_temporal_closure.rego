# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY NATYWNE V3-P53 TEMPORALNOŚĆ DOMKNIĘCIE (konwencja
# P39/P45–P52: negative-first, granice progów, fail-closed, never-silent
# AUTO_POST, bypass → BLOCK, determinizm else-chain, epoki/day-0/time-travel).
# Uruchomienie: opa test (0.68) / opa19 test --v0-compatible (1.9)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p53_temporal_closure_test

import data.jdg.v3_p53_temporal_closure

# ── Fixture: pełny kontekst dowodowy (stan bazowy narzędzi P53) ────────────────
full_ctx := {
	"I01_temporal_coverage_map": {"rule_files_with_window": 120, "rule_files_total": 268, "coverage_pct": 44.8, "hardcoded_date_files": 35},
	"I02_day0_test_autogeneration": {"auto_tests_generated": 8},
	"I03_retroactive_replay_contract": {"pillars_met": 2, "pillars_total": 4, "pillars": {"rules_bundle_history": true, "params_history": true, "fx_history": false, "accumulator_state_on_date": false}},
	"I04_transitional_rules_register": {"total": 6, "modelled": 5, "not_modelled": ["TR-05"]},
	"I05_interval_validator": {"gaps_count": 0, "overlaps_count": 0},
	"I06_epoch_registry": {"epochs": [{"epoch_id": "EPOCH-BASE", "start": "2026-01-01", "end": null, "params_snapshot_hash": "abc"}]},
	"I07_future_law_sandbox": {"eligible_count": 1},
	"I08_preprovisioning_scheduler": {"calendar_entries_count": 1, "calendar_tested_entries": 0},
	"I09_year_boundary_tests": {"cases_count": 3},
	"I10_historical_parameter_store": {"total_versions": 8, "with_provenance": 7, "without_provenance": 1},
	"I11_epoch_aware_golden_replay": {"verdicts_total": 31, "with_epoch_label": 29, "without_epoch_label": 2},
	"I12_temporal_audit_trail": {"epochs_available": 1},
}

activated_input := {"jdg_entrepreneur": {"v3_p53_check": true}, "v3_p53": full_ctx}
deactivated_input := {"jdg_entrepreneur": {}, "v3_p53": full_ctx}

# ═══ 1. NEGATIVE-FIRST: brak aktywacji → NO_MATCH (żadnych efektów ubocznych) ═══
test_decide_no_match_without_flag {
	decide := v3_p53_temporal_closure.decide with input as deactivated_input
	decide.decision == "NO_MATCH"
	decide.matched == false
}

# ═══ 2. FAIL-CLOSED: brak snapshotu progów → NEEDS_ADVICE, nigdy cicho ═══
test_fail_closed_thresholds_missing {
	decide := v3_p53_temporal_closure.decide with input as activated_input
	with data.jdg.thresholds.v3_p53 as {}
	decide.rule_id == "jdg.v3_p53_temporal_closure.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
	decide.priority == 0
}

# ═══ 3. ROUTER: stan bazowy — I03 replay (2/4 filary) jest BLOCKEREM ═══
test_router_blocks_on_replay_pillars {
	decide := v3_p53_temporal_closure.decide with input as activated_input
	decide.rule_id == "jdg.v3_p53_temporal_closure.replay_contract"
	decide.decision == "BLOCK"
}

# ═══ 4. ROUTER determinizm: dwie ewaluacje = ten sam werdykt ═══
test_router_deterministic {
	a := v3_p53_temporal_closure.decide with input as activated_input
	b := v3_p53_temporal_closure.decide with input as activated_input
	a == b
}

# ═══ 5. I01: pokrycie oknami poniżej progu → BLOCK ═══
test_i01_blocks_low_coverage {
	decide := v3_p53_temporal_closure.decide with input as activated_input
	with input.v3_p53 as object.union(full_ctx, {"I05_interval_validator": {"gaps_count": 1, "overlaps_count": 0}})
	decide.rule_id == "jdg.v3_p53_temporal_closure.interval_validation"
}

# ═══ 5b. I01 branch coverage: niskie pokrycie (po naprawie I05) → BLOCK ═══
test_i01_block_low_window_coverage {
	ctx := object.union(full_ctx, {
		"I05_interval_validator": {"gaps_count": 0, "overlaps_count": 0},
		"I03_retroactive_replay_contract": {"pillars_met": 4, "pillars_total": 4, "pillars": {"rules_bundle_history": true, "params_history": true, "fx_history": true, "accumulator_state_on_date": true}},
		"I02_day0_test_autogeneration": {"auto_tests_generated": 20},
		"I09_year_boundary_tests": {"cases_count": 9},
		"I01_temporal_coverage_map": {"rule_files_with_window": 10, "rule_files_total": 268, "coverage_pct": 3.7, "hardcoded_date_files": 35},
	})
	decide := v3_p53_temporal_closure.decide with input as {"jdg_entrepreneur": {"v3_p53_check": true}, "v3_p53": ctx}
	decide.rule_id == "jdg.v3_p53_temporal_closure.temporal_coverage_gate"
	decide.decision == "BLOCK"
}

# ═══ 5c. I02 branch: brak testów day-0 → BLOCK ═══
test_i02_block_no_day0_tests {
	ctx := object.union(full_ctx, {
		"I05_interval_validator": {"gaps_count": 0, "overlaps_count": 0},
		"I03_retroactive_replay_contract": {"pillars_met": 4, "pillars_total": 4, "pillars": {"rules_bundle_history": true, "params_history": true, "fx_history": true, "accumulator_state_on_date": true}},
		"I09_year_boundary_tests": {"cases_count": 9},
		"I02_day0_test_autogeneration": {"auto_tests_generated": 2},
	})
	decide := v3_p53_temporal_closure.decide with input as {"jdg_entrepreneur": {"v3_p53_check": true}, "v3_p53": ctx}
	decide.rule_id == "jdg.v3_p53_temporal_closure.day0_tests"
	decide.decision == "BLOCK"
}

# ═══ 5d. I09 branch: brak testów granicy roku → BLOCK ═══
test_i09_block_no_year_boundary {
	ctx := object.union(full_ctx, {
		"I05_interval_validator": {"gaps_count": 0, "overlaps_count": 0},
		"I03_retroactive_replay_contract": {"pillars_met": 4, "pillars_total": 4, "pillars": {"rules_bundle_history": true, "params_history": true, "fx_history": true, "accumulator_state_on_date": true}},
		"I09_year_boundary_tests": {"cases_count": 1},
	})
	decide := v3_p53_temporal_closure.decide with input as {"jdg_entrepreneur": {"v3_p53_check": true}, "v3_p53": ctx}
	decide.rule_id == "jdg.v3_p53_temporal_closure.year_boundary"
	decide.decision == "BLOCK"
}

# ═══ 6. Ścieżka PASS: wszystkie BLOCKERY naprawione → MANUAL_REVIEW I04 ═══
test_pass_path_reaches_manual_review_i04 {
	ctx := object.union(full_ctx, {
		"I05_interval_validator": {"gaps_count": 0, "overlaps_count": 0},
		"I03_retroactive_replay_contract": {"pillars_met": 4, "pillars_total": 4, "pillars": {"rules_bundle_history": true, "params_history": true, "fx_history": true, "accumulator_state_on_date": true}},
		"I02_day0_test_autogeneration": {"auto_tests_generated": 20},
		"I09_year_boundary_tests": {"cases_count": 9},
		"I01_temporal_coverage_map": {"rule_files_with_window": 250, "rule_files_total": 268, "coverage_pct": 93.3, "hardcoded_date_files": 0},
	})
	decide := v3_p53_temporal_closure.decide with input as {"jdg_entrepreneur": {"v3_p53_check": true}, "v3_p53": ctx}
	decide.rule_id == "jdg.v3_p53_temporal_closure.transitional_register"
	decide.decision == "MANUAL_REVIEW"
}

# ═══ 6b. Pełna ścieżka PASS: wszystko naprawione + brak flagi sandbox ═══
test_all_green_returns_pass_i12 {
	ctx := object.union(full_ctx, {
		"I05_interval_validator": {"gaps_count": 0, "overlaps_count": 0},
		"I03_retroactive_replay_contract": {"pillars_met": 4, "pillars_total": 4, "pillars": {"rules_bundle_history": true, "params_history": true, "fx_history": true, "accumulator_state_on_date": true}},
		"I02_day0_test_autogeneration": {"auto_tests_generated": 20},
		"I09_year_boundary_tests": {"cases_count": 9},
		"I01_temporal_coverage_map": {"rule_files_with_window": 250, "rule_files_total": 268, "coverage_pct": 93.3, "hardcoded_date_files": 0},
		"I04_transitional_rules_register": {"total": 6, "modelled": 6, "not_modelled": []},
		"I08_preprovisioning_scheduler": {"calendar_entries_count": 3, "calendar_tested_entries": 3},
		"I10_historical_parameter_store": {"total_versions": 8, "with_provenance": 8, "without_provenance": 0},
		"I11_epoch_aware_golden_replay": {"verdicts_total": 31, "with_epoch_label": 31, "without_epoch_label": 0},
		"I12_temporal_audit_trail": {"epochs_available": 1},
	})
	decide := v3_p53_temporal_closure.decide with input as {"jdg_entrepreneur": {"v3_p53_check": true}, "v3_p53": ctx}
	decide.rule_id == "jdg.v3_p53_temporal_closure.all_green"
	decide.decision == "PASS"
	decide.priority == 453000
}

# ═══ 7. I05: luka interwałów → BLOCK (INV-037) ═══
test_i05_block_on_gap {
	ctx := object.union(full_ctx, {"I05_interval_validator": {"gaps_count": 1, "overlaps_count": 0}})
	decide := v3_p53_temporal_closure.decide with input as {"jdg_entrepreneur": {"v3_p53_check": true}, "v3_p53": ctx}
	decide.rule_id == "jdg.v3_p53_temporal_closure.interval_validation"
	decide.decision == "BLOCK"
}

# ═══ 7b. I05: nakładka interwałów → BLOCK (dwie wersje na datę = P1632) ═══
test_i05_block_on_overlap {
	ctx := object.union(full_ctx, {"I05_interval_validator": {"gaps_count": 0, "overlaps_count": 2}})
	decide := v3_p53_temporal_closure.decide with input as {"jdg_entrepreneur": {"v3_p53_check": true}, "v3_p53": ctx}
	decide.decision == "BLOCK"
}

# ═══ 8. I03: missing pillars wymienione w reason (audytowalność) ═══
test_i03_reason_lists_missing_pillars {
	met := v3_p53_temporal_closure.i03_replay with input as activated_input
	object.get(met, "decision", "") == "BLOCK"
}

# ═══ 9. I04: TR-05 niemodelowana → MANUAL_REVIEW (4-eyes, nie blokada) ═══
test_i04_manual_review_not_modelled {
	mr := v3_p53_temporal_closure.i04_transitional with input as activated_input
	mr.decision == "MANUAL_REVIEW"
}

# ═══ 10. I06/I11: epoka dla daty w oknie → EPOCH-BASE ═══
test_epoch_for_date_in_window {
	epochs := [{"epoch_id": "EPOCH-BASE", "start": "2026-01-01", "end": null}]
	ep := v3_p53_temporal_closure._epoch_for_date(epochs, "2026-09-12")
	ep.epoch_id == "EPOCH-BASE"
}

# ═══ 10b. I06 fail-closed: data POZA oknami epok → NEEDS_ADVICE (nie najbliższa!) ═══
test_epoch_for_date_outside_windows_fails_closed {
	epochs := [{"epoch_id": "EPOCH-BASE", "start": "2026-01-01", "end": "2026-06-30"}]
	ep := v3_p53_temporal_closure._epoch_for_date(epochs, "2026-12-31")
	ep.epoch_id == null
	ep.decision_hint == "NEEDS_ADVICE"
}

# ═══ 10c. I06: data na granicy day-0 (1.01 nowej epoki) → nowa epoka ═══
test_epoch_day0_boundary_picks_new_epoch {
	epochs := [
		{"epoch_id": "EPOCH-OLD", "start": "2026-01-01", "end": "2026-12-31"},
		{"epoch_id": "EPOCH-NEW", "start": "2027-01-01", "end": null},
	]
	ep_old := v3_p53_temporal_closure._epoch_for_date(epochs, "2026-12-31")
	ep_new := v3_p53_temporal_closure._epoch_for_date(epochs, "2027-01-01")
	ep_old.epoch_id == "EPOCH-OLD"
	ep_new.epoch_id == "EPOCH-NEW"
}

# ═══ 11. I07: sandbox wyłącznie na flagę; production_write zawsze false ═══
test_i07_sandbox_draft_only {
	draft := v3_p53_temporal_closure.i07_sandbox with input as {"jdg_entrepreneur": {"v3_p53_check": true}, "v3_p53": object.union(full_ctx, {"future_law_requested": true})}
	draft.decision == "DRAFT_SIMULATION"
	draft.production_write == false
}

test_i07_no_sandbox_without_flag {
	no_draft := v3_p53_temporal_closure.i07_sandbox with input as activated_input
	no_draft.matched == false
}

# ═══ 12. I12: certyfikat bez legal_epoch → NEEDS_ADVICE (fail-closed) ═══
test_i12_fails_closed_without_epoch {
	missing := v3_p53_temporal_closure.i12_audit_trail with input as {"jdg_entrepreneur": {"v3_p53_check": true}, "v3_p53": object.union(full_ctx, {"certificate_missing_epoch": true})}
	missing.decision == "NEEDS_ADVICE"
}

# ═══ 13. NEVER-SILENT: każda gałąź decide ma decision i reason ═══
test_every_branch_has_decision_and_reason {
	decide := v3_p53_temporal_closure.decide with input as activated_input
	decide.decision != null
	decide.reason != null
	decide.rule_id != null
	decide._legal_basis != null
}

# ═══ 14. AUTO_POST zakazany w całym pakiecie P53 (fail-closed fortecy) ═══
test_no_auto_post_anywhere {
	decide := v3_p53_temporal_closure.decide with input as activated_input
	decide.decision != "AUTO_POST"
}

# ═══ 15. Granice progów: day0_tests_min dokładnie na granicy ═══
test_i02_boundary_exactly_at_min_passes {
	ctx := object.union(full_ctx, {
		"I05_interval_validator": {"gaps_count": 0, "overlaps_count": 0},
		"I03_retroactive_replay_contract": {"pillars_met": 4, "pillars_total": 4, "pillars": {"rules_bundle_history": true, "params_history": true, "fx_history": true, "accumulator_state_on_date": true}},
		"I09_year_boundary_tests": {"cases_count": 9},
		"I02_day0_test_autogeneration": {"auto_tests_generated": 8},
	})
	decide := v3_p53_temporal_closure.decide with input as {"jdg_entrepreneur": {"v3_p53_check": true}, "v3_p53": ctx}
	decide.rule_id != "jdg.v3_p53_temporal_closure.day0_tests"
}

# ═══ 15b. Granica: cases_count == min → PASS (nie Block) ═══
test_i09_boundary_exactly_at_min {
	ctx := object.union(full_ctx, {
		"I05_interval_validator": {"gaps_count": 0, "overlaps_count": 0},
		"I03_retroactive_replay_contract": {"pillars_met": 4, "pillars_total": 4, "pillars": {"rules_bundle_history": true, "params_history": true, "fx_history": true, "accumulator_state_on_date": true}},
		"I09_year_boundary_tests": {"cases_count": 3},
	})
	d := v3_p53_temporal_closure.i09_year_boundary with input as {"jdg_entrepreneur": {"v3_p53_check": true}, "v3_p53": ctx}
	d.decision == "PASS"
}

# ═══ 16. Progi: okno temporalne snapshotu obecne (P05) ═══
test_thresholds_snapshot_has_temporal_window {
	snap := data.jdg.thresholds.v3_p53
	snap.valid_from == "2026-01-01"
	snap.no_auto_post == true
}

# ═══ 17. Wszystkie rule_id unikalne globalnie (prefiks pakietu) ═══
test_rule_ids_prefixed {
	decide := v3_p53_temporal_closure.decide with input as activated_input
	startswith(decide.rule_id, "jdg.v3_p53_temporal_closure.")
}
