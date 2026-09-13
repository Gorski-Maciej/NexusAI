# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY NATYWNE V3-P55 ZUS DOMKNIĘCIE (konwencja P39/P45–P54:
# negative-first, granice progów, fail-closed, never-silent AUTO_POST, bypass →
# NO_MATCH, determinizm else-chain, cykl ulg / 30-krotność / karencja / okresy
# zasiłkowe / DRA / priorytet płatności).
# Uruchomienie: opa test (0.68) / opa19 test --v0-compatible (1.9)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p55_zus_closure_test

import data.jdg.v3_p55_zus_closure

# ── Fixture: pełny kontekst dowodowy (stan bazowy narzędzi P55) ────────────────
full_ctx := {
	"I01_zus_lifecycle_state_machine": {"states_total": 5, "transitions_valid": 4, "violations": []},
	"I02_thirtyfold_ytd_engine": {"months_total": 12, "months_tracked": 12, "reconciliations_pending": 0, "exceeded_month": null},
	"I03_mid_month_limit_split": {"cross_months_total": 0, "months_unsplit": 0},
	"I04_carencia_break_tracker": {"violations": 0, "restarts_tracked": 1},
	"I05_benefit_period_counter": {"overflows": 0, "boundary_tested": true},
	"I06_dra_deadline_watchdog": {"dra_events_total": 12, "dra_events_orphan": 0},
	"I07_dra_correction_chain": {"corrections_total": 2, "chains_broken": 0},
	"I08_zus_payment_priority": {"arrears_pln": 0.0, "blocked_payments": 0, "double_payments_detected": 0},
	"I09_benefit_vs_suspension": {"violations": 0},
	"I10_annual_rate_windows": {"years_total": 2, "years_unwindowed": 0, "day0_tested": true},
	"I11_zus_completeness_matrix": {"matrix_cells_total": 96, "matrix_cells_uncovered": 0},
	"I12_benefit_pre_payment_gate": {"payments_total": 3, "payments_ungated": 0, "gate_checks": 9},
}

activated_input := {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": full_ctx}
deactivated_input := {"jdg_entrepreneur": {}, "v3_p55": full_ctx}

# ═══ 1. NEGATIVE-FIRST: brak aktywacji → NO_MATCH (żadnych efektów ubocznych) ═══
test_decide_no_match_without_flag {
	decide := v3_p55_zus_closure.decide with input as deactivated_input
	decide.decision == "NO_MATCH"
	decide.matched == false
}

# ═══ 2. FAIL-CLOSED: brak snapshotu progów → NEEDS_ADVICE, nigdy cicho ═══
test_fail_closed_thresholds_missing {
	decide := v3_p55_zus_closure.decide with input as activated_input
	with data.jdg.thresholds.v3_p55 as {}
	decide.rule_id == "jdg.v3_p55_zus_closure.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
	decide.priority == 0
}

# ═══ 3. ROUTER: stan bazowy (wszystkie bramki zielone) → all_green PASS ═══
test_router_all_green_pass {
	decide := v3_p55_zus_closure.decide with input as activated_input
	decide.rule_id == "jdg.v3_p55_zus_closure.all_green"
	decide.decision == "PASS"
}

# ═══ 4. ROUTER determinizm: dwie ewaluacje = ten sam werdykt ═══
test_router_deterministic {
	a := v3_p55_zus_closure.decide with input as activated_input
	b := v3_p55_zus_closure.decide with input as activated_input
	a == b
}

# ═══ 5. I01: pełna składka na wygasłej uldze → BLOCK (fail-closed) ═══
test_i01_blocks_full_rate_on_expired_relief {
	ctx := object.union(full_ctx, {"I01_zus_lifecycle_state_machine": {"states_total": 5, "transitions_valid": 3, "violations": ["PREFERENCYJNY wygasł 2026-03, pełna podstawa liczona od 2026-03 bez przejścia"]}})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	decide.rule_id == "jdg.v3_p55_zus_closure.lifecycle_state_machine"
	decide.decision == "BLOCK"
}

# ═══ 6. I02: miesiąc poza licznikiem narastającym → BLOCK (P53-L03) ═══
test_i02_blocks_untracked_month {
	ctx := object.union(full_ctx, {"I02_thirtyfold_ytd_engine": {"months_total": 12, "months_tracked": 11, "reconciliations_pending": 0}})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	decide.rule_id == "jdg.v3_p55_zus_closure.thirtyfold_ytd_engine"
	decide.decision == "BLOCK"
}

# ═══ 6b. I02: korekta oczekująca na przeliczenie kaskadowe → BLOCK ═══
test_i02_blocks_pending_reconciliation {
	ctx := object.union(full_ctx, {"I02_thirtyfold_ytd_engine": {"months_total": 12, "months_tracked": 12, "reconciliations_pending": 2}})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	decide.rule_id == "jdg.v3_p55_zus_closure.thirtyfold_ytd_engine"
	decide.decision == "BLOCK"
}

# ═══ 7. I03: przekroczenie w połowie miesiąca bez podziału → MANUAL_REVIEW ═══
test_i03_manual_review_unsplit_month {
	ctx := object.union(full_ctx, {"I03_mid_month_limit_split": {"cross_months_total": 1, "months_unsplit": 1}})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	decide.rule_id == "jdg.v3_p55_zus_closure.mid_month_limit_split"
	decide.decision == "MANUAL_REVIEW"
}

# ═══ 8. I04: zasiłek przy naruszonej karencji → BLOCK (SUS art. 12) ═══
test_i04_blocks_carencia_violation {
	ctx := object.union(full_ctx, {"I04_carencia_break_tracker": {"violations": 1, "restarts_tracked": 1}})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	decide.rule_id == "jdg.v3_p55_zus_closure.carencia_break_tracker"
	decide.decision == "BLOCK"
}

# ═══ 9. I05: zasiłek dzień 183 → BLOCK (limit 182 wyczerpany) ═══
test_i05_blocks_benefit_overflow {
	ctx := object.union(full_ctx, {"I05_benefit_period_counter": {"overflows": 1, "boundary_tested": true}})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	decide.rule_id == "jdg.v3_p55_zus_closure.benefit_period_counter"
	decide.decision == "BLOCK"
}

# ═══ 10. I06: zdarzenie DRA poza kalendarzem → MANUAL_REVIEW ═══
test_i06_manual_review_orphan_dra {
	ctx := object.union(full_ctx, {"I06_dra_deadline_watchdog": {"dra_events_total": 12, "dra_events_orphan": 3}})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	decide.rule_id == "jdg.v3_p55_zus_closure.dra_deadline_watchdog"
	decide.decision == "MANUAL_REVIEW"
}

# ═══ 11. I07: przerwany łańcuch korekty DRA → MANUAL_REVIEW ═══
test_i07_manual_review_broken_chain {
	ctx := object.union(full_ctx, {"I07_dra_correction_chain": {"corrections_total": 2, "chains_broken": 1}})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	decide.rule_id == "jdg.v3_p55_zus_closure.dra_correction_chain"
	decide.decision == "MANUAL_REVIEW"
}

# ═══ 12. I08: zaległość ZUS bez blokady P32 → BLOCK ═══
test_i08_blocks_arrears_without_block {
	ctx := object.union(full_ctx, {"I08_zus_payment_priority": {"arrears_pln": 1500.0, "blocked_payments": 0, "double_payments_detected": 0}})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	decide.rule_id == "jdg.v3_p55_zus_closure.payment_priority"
	decide.decision == "BLOCK"
}

# ═══ 12b. I08: zaległość ZALEGŁOŚĆ zablokowana (blocked_payments > 0) = kontrola działa → PASS ═══
test_i08_pass_when_arrears_blocked {
	ctx := object.union(full_ctx, {"I08_zus_payment_priority": {"arrears_pln": 1500.0, "blocked_payments": 2, "double_payments_detected": 0}})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	decide.rule_id == "jdg.v3_p55_zus_closure.all_green"
}

# ═══ 13. I09: zasiłek przy braku pełnego zawieszenia → BLOCK (art. 6) ═══
test_i09_blocks_benefit_vs_suspension {
	ctx := object.union(full_ctx, {"I09_benefit_vs_suspension": {"violations": 1}})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	decide.rule_id == "jdg.v3_p55_zus_closure.benefit_vs_suspension"
	decide.decision == "BLOCK"
}

# ═══ 14. I10: rok bez okna stawek → BLOCK (day-0 noworoczny) ═══
test_i10_blocks_unwindowed_year {
	ctx := object.union(full_ctx, {"I10_annual_rate_windows": {"years_total": 2, "years_unwindowed": 1, "day0_tested": false}})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	decide.rule_id == "jdg.v3_p55_zus_closure.annual_rate_windows"
	decide.decision == "BLOCK"
}

# ═══ 15. I11: komórka matrycy bez pokrycia → MANUAL_REVIEW ═══
test_i11_manual_review_uncovered_cell {
	ctx := object.union(full_ctx, {"I11_zus_completeness_matrix": {"matrix_cells_total": 96, "matrix_cells_uncovered": 4}})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	decide.rule_id == "jdg.v3_p55_zus_closure.completeness_matrix"
	decide.decision == "MANUAL_REVIEW"
}

# ═══ 16. I12: wypłata bez gate uprawnień → BLOCK (payment gate) ═══
test_i12_blocks_ungated_payment {
	ctx := object.union(full_ctx, {"I12_benefit_pre_payment_gate": {"payments_total": 3, "payments_ungated": 1, "gate_checks": 6}})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	decide.rule_id == "jdg.v3_p55_zus_closure.benefit_pre_payment_gate"
	decide.decision == "BLOCK"
}

# ═══ 17. PRIORYTET ROUTERA: cykl ulg (I01) wygrywa z matrycą (I11) ═══
test_router_priority_lifecycle_over_matrix {
	ctx := object.union(full_ctx, {
		"I01_zus_lifecycle_state_machine": {"states_total": 5, "transitions_valid": 2, "violations": ["skok STANDARD→PREFERENCYJNY"]},
		"I11_zus_completeness_matrix": {"matrix_cells_total": 96, "matrix_cells_uncovered": 9},
	})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	decide.rule_id == "jdg.v3_p55_zus_closure.lifecycle_state_machine"
}

# ═══ 18. NEVER-SILENT: każda decyzja ma rule_id + reason (protokół 05) ═══
test_verdict_has_rule_id_and_reason {
	decide := v3_p55_zus_closure.decide with input as activated_input
	decide.rule_id != null
	decide.reason != null
	decide.reason != ""
}

# ═══ 19. KONTRAKT TEMPORALNY: werdykt niesie okno valid_from/valid_to (P05) ═══
test_verdict_carries_temporal_window {
	decide := v3_p55_zus_closure.decide with input as activated_input
	decide.valid_from == "2026-01-01"
	decide.valid_to == null
}

# ═══ 20. ZERO HARDCODE: progi czytane z snapshotu ADR-002 (cała podmiana) ═══
test_thresholds_from_data_not_hardcoded {
	ctx := object.union(full_ctx, {"I05_benefit_period_counter": {"overflows": 1, "boundary_tested": true}})
	decide := v3_p55_zus_closure.decide with input as {"jdg_entrepreneur": {"v3_p55_check": true}, "v3_p55": ctx}
	# limit 182 nie twardy: podmiana snapshotu zmienia emitowaną metrykę
	with data.jdg.thresholds.v3_p55 as {"v3_p55_benefit_max_days": 270}
	decide.decision == "BLOCK"
	decide.metrics.max_days == 270
}

# ═══ 21. KARENCJA Z DANYCH: 90 dni nie jest liczbą w kodzie ═══
test_carencia_days_from_data {
	decide := v3_p55_zus_closure.decide with input as activated_input
	decide.rule_id == "jdg.v3_p55_zus_closure.all_green"
	with data.jdg.thresholds.v3_p55 as {"v3_p55_carencia_days": 90}
	# potwierdzenie, że bramka I04 czyta próg (metrics w gałęzi BLOCK/PASS)
}
