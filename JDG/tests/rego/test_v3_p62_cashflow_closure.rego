package jdg.v3_p62_cashflow_closure_test

import data.jdg.v3_p62_cashflow_closure

# Pełny kontekst zielony (wszystkie 12 analiz PASS — wartości z silników P62)
full_ctx := {
	"I01_payment_rule_engine": {"rule_backed": true},
	"I02_idempotent_execution": {"idempotent": true},
	"I03_two_phase_payment": {"pipeline_present": true},
	"I04_cashflow_schedule": {"predictor_present": true},
	"I05_interest_live": {"engine_present": true},
	"I06_reminder_ladder": {"ladder_days": [7, 3, 1]},
	"I07_payment_archive_worm": {"worm_gate": "PASS"},
	"I08_failure_playbook": {"chaos_gate": "PASS", "offline_queue": true},
	"I09_duplication_ledger": {"dups_detected": 2, "unregistered": 0, "refund_path": true},
	"I10_balance_guard": {"pre_payment_gate": "PASS"},
	"I11_multibank_ready": {"missing_fields": []},
	"I12_scenario_runner": {"runner_present": true},
}

activated_input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": full_ctx}
deactivated_input := {"jdg_entrepreneur": {}, "v3_p62": full_ctx}

# ═══ 1. Fail-closed: brak flagi aktywacji → NO_MATCH ═══
test_no_match_without_flag {
	decide := v3_p62_cashflow_closure.decide with input as deactivated_input
	decide.decision == "NO_MATCH"
	decide.rule_id == "jdg.v3_p62_cashflow_closure.no_match"
}

# ═══ 2. Fail-closed: brak snapshotu progów → NEEDS_ADVICE (precedencja) ═══
test_thresholds_missing_fail_closed {
	decide := v3_p62_cashflow_closure.decide with input as activated_input
	with data.jdg.thresholds.v3_p62 as {}
	decide.rule_id == "jdg.v3_p62_cashflow_closure.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 3. Kontekst zielony → PASS ═══
test_all_green_pass {
	decide := v3_p62_cashflow_closure.decide with input as activated_input
	decide.decision == "PASS"
	decide.rule_id == "jdg.v3_p62_cashflow_closure.all_green"
}

# ═══ 4. I02 BLOCK: płatność bez idempotencji (podwójna płatność!) ═══
test_i02_block_not_idempotent {
	input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": object.union(full_ctx, {"I02_idempotent_execution": {"idempotent": false}})}
	decide := v3_p62_cashflow_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p62_cashflow_closure.idempotent_execution"
	decide.priority == 462002
}

# ═══ 5. I04 BLOCK: harmonogram bez predyktora salda ═══
test_i04_block_no_predictor {
	input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": object.union(full_ctx, {"I04_cashflow_schedule": {"predictor_present": false}})}
	decide := v3_p62_cashflow_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p62_cashflow_closure.cashflow_aware_schedule"
}

# ═══ 6. I07 BLOCK: potwierdzenia bez WORM ═══
test_i07_block_no_worm {
	input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": object.union(full_ctx, {"I07_payment_archive_worm": {"worm_gate": "FAIL"}})}
	decide := v3_p62_cashflow_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p62_cashflow_closure.payment_archive_worm"
}

# ═══ 7. I09 BLOCK: duplikat niezarejestrowany (cicha strata) ═══
test_i09_block_unregistered_dup {
	input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": object.union(full_ctx, {"I09_duplication_ledger": {"dups_detected": 3, "unregistered": 1, "refund_path": true}})}
	decide := v3_p62_cashflow_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p62_cashflow_closure.payment_duplication_ledger"
}

# ═══ 8. I09 BLOCK: brak procedury zwrotu ═══
test_i09_block_no_refund_path {
	input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": object.union(full_ctx, {"I09_duplication_ledger": {"dups_detected": 0, "unregistered": 0, "refund_path": false}})}
	decide := v3_p62_cashflow_closure.decide with input as input
	decide.decision == "BLOCK"
}

# ═══ 9. I10 BLOCK: balance guard nieobecny (debet podatkowy) ═══
test_i10_block_no_guard {
	input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": object.union(full_ctx, {"I10_balance_guard": {"pre_payment_gate": "MISSING"}})}
	decide := v3_p62_cashflow_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p62_cashflow_closure.balance_guard"
}

# ═══ 10. I01 NEEDS_ADVICE: kolejność ręczna (rule_backed=false) ═══
test_i01_advice_manual_order {
	input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": object.union(full_ctx, {"I01_payment_rule_engine": {"rule_backed": false}})}
	decide := v3_p62_cashflow_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p62_cashflow_closure.payment_rule_engine"
}

# ═══ 11. I03 NEEDS_ADVICE: brak wzorca dwufazowego ═══
test_i03_advice_no_two_phase {
	input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": object.union(full_ctx, {"I03_two_phase_payment": {"pipeline_present": false}})}
	decide := v3_p62_cashflow_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 12. I05 NEEDS_ADVICE: brak silnika odsetek live ═══
test_i05_advice_no_interest {
	input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": object.union(full_ctx, {"I05_interest_live": {"engine_present": false}})}
	decide := v3_p62_cashflow_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 13. I06 NEEDS_ADVICE: drabina przypomnień krótsza niż próg ═══
test_i06_advice_short_ladder {
	input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": object.union(full_ctx, {"I06_reminder_ladder": {"ladder_days": [7]}})}
	decide := v3_p62_cashflow_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 14. I08 NEEDS_ADVICE: chaos nieprzetestowany ═══
test_i08_advice_chaos_missing {
	input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": object.union(full_ctx, {"I08_failure_playbook": {"chaos_gate": "MISSING", "offline_queue": true}})}
	decide := v3_p62_cashflow_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 15. I08 NEEDS_ADVICE: brak kolejki offline ═══
test_i08_advice_no_offline_queue {
	input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": object.union(full_ctx, {"I08_failure_playbook": {"chaos_gate": "PASS", "offline_queue": false}})}
	decide := v3_p62_cashflow_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 16. I11 NEEDS_ADVICE: brak pola multi-bank ═══
test_i11_advice_missing_field {
	input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": object.union(full_ctx, {"I11_multibank_ready": {"missing_fields": ["bank_id"]}})}
	decide := v3_p62_cashflow_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 17. I12 NEEDS_ADVICE: brak scenario runnera ═══
test_i12_advice_no_runner {
	input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": object.union(full_ctx, {"I12_scenario_runner": {"runner_present": false}})}
	decide := v3_p62_cashflow_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 18. Precedencja: BLOCK (I02, 462002) wygrywa z NEEDS_ADVICE (I01) ═══
test_block_precedence {
	input := {"jdg_entrepreneur": {"v3_p62_check": true}, "v3_p62": object.union(full_ctx, {"I01_payment_rule_engine": {"rule_backed": false}, "I02_idempotent_execution": {"idempotent": false}})}
	decide := v3_p62_cashflow_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.priority == 462002
}
