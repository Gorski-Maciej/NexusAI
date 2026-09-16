package jdg.v3_p66_chaos_resilience_test

import data.jdg.v3_p66_chaos_resilience

# Pełny kontekst zielony (wszystkie 12 analiz PASS — wartości ze silników P66:
# tools/v3_p66_engines.py czytają bundla v3_p66_i*_engine.json)
full_ctx := {
	"I01_steady_state": {"hypothesis_present": true, "baseline_metrics": 5, "baseline_sources_missing": []},
	"I02_experiment_cards": {"cards_total": 12, "cards_incomplete_count": 0, "cards_incomplete": []},
	"I03_dependency_matrix": {"combinations_tested": 15, "failure_modes": ["timeout", "error", "halt"]},
	"I04_kill_switch": {"heavy_experiments": ["EX-09", "EX-12"], "experiment_kill_switch_defined": true, "kill_switch_tool_present": true},
	"I05_chaos_day": {"chaos_day_scheduled": true},
	"I06_auto_rollback": {"cards_total": 12, "cards_with_rollback": 12},
	"I07_maturity": {"ladder_levels": ["L1", "L2", "L3", "L4", "L5"], "current_level": "L2"},
	"I08_injection_as_data": {"experiments_as_data": true},
	"I09_findings": {"fail_closed_violations_total": 0, "feed_to_repair_register": true},
	"I10_resilience_trend": {"resilience_pct": 100},
	"I11_peak_time": {"peak_experiment_present": true},
	"I12_game_day": {"game_day_present": true},
}

activated_input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": full_ctx}
deactivated_input := {"jdg_entrepreneur": {}, "v3_p66": full_ctx}

# ═══ 1. Fail-closed: brak flagi aktywacji → NO_MATCH ═══
test_no_match_without_flag {
	decide := v3_p66_chaos_resilience.decide with input as deactivated_input
	decide.decision == "NO_MATCH"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.no_match"
}

# ═══ 2. Fail-closed: brak snapshotu progów → NEEDS_ADVICE (precedencja) ═══
test_thresholds_missing_fail_closed {
	decide := v3_p66_chaos_resilience.decide with input as activated_input
	with data.jdg.thresholds.v3_p66 as {}
	decide.rule_id == "jdg.v3_p66_chaos_resilience.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 3. Kontekst zielony → PASS ═══
test_all_green_pass {
	decide := v3_p66_chaos_resilience.decide with input as activated_input
	decide.decision == "PASS"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.all_green"
}

# ═══ 4. I02 BLOCK: karta bez asercji/rollback ═══
# Uwaga: object.union robi głęboki merge — nadpisanie zagnieżdżonego obiektu
# wymaga object.remove (konwencja testów P65/P66; lekcja L06 P65).
test_i02_block_card_incomplete {
	ctx := object.remove(full_ctx, ["I02_experiment_cards"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I02_experiment_cards": {"cards_total": 12, "cards_incomplete_count": 1, "cards_incomplete": [{"id": "EX-07", "missing": ["rollback"]}]}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.experiment_card_standard"
	decide.priority == 466002
}

# ═══ 5. I04 BLOCK: eksperyment ciężki bez wyłącznika ═══
test_i04_block_heavy_without_kill_switch {
	ctx := object.remove(full_ctx, ["I04_kill_switch"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I04_kill_switch": {"heavy_experiments": ["EX-09", "EX-12"], "experiment_kill_switch_defined": false, "kill_switch_tool_present": true}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.kill_switch_experiments"
	decide.priority == 466004
}

# ═══ 6. I04 BLOCK: narzędzie P07 nieobecne ═══
test_i04_block_kill_switch_tool_missing {
	ctx := object.remove(full_ctx, ["I04_kill_switch"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I04_kill_switch": {"heavy_experiments": ["EX-12"], "experiment_kill_switch_defined": true, "kill_switch_tool_present": false}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.kill_switch_experiments"
}

# ═══ 7. I06 BLOCK: karta bez rollbacku ═══
test_i06_block_card_without_rollback {
	ctx := object.remove(full_ctx, ["I06_auto_rollback"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I06_auto_rollback": {"cards_total": 12, "cards_with_rollback": 11}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.auto_rollback_experiments"
	decide.priority == 466006
}

# ═══ 8. I10 BLOCK: wskaźnik odporności poniżej progu ═══
test_i10_block_resilience_below_min {
	ctx := object.remove(full_ctx, ["I10_resilience_trend"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I10_resilience_trend": {"resilience_pct": 55}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.resilience_trend"
	decide.priority == 466010
}

# ═══ 9. I01 NEEDS_ADVICE: hipoteza normy nieobecna ═══
test_i01_needs_advice_no_hypothesis {
	ctx := object.remove(full_ctx, ["I01_steady_state"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I01_steady_state": {"hypothesis_present": false, "baseline_metrics": 5, "baseline_sources_missing": []}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.steady_state_hypothesis"
	decide.priority == 466001
}

# ═══ 10. I01 NEEDS_ADVICE: metryk bazowych poniżej minimum ═══
test_i01_needs_advice_few_baseline_metrics {
	ctx := object.remove(full_ctx, ["I01_steady_state"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I01_steady_state": {"hypothesis_present": true, "baseline_metrics": 2, "baseline_sources_missing": ["golden_replay_uver_pct"]}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.steady_state_hypothesis"
}

# ═══ 11. I03 NEEDS_ADVICE: za mało kombinacji zależność×tryb ═══
test_i03_needs_advice_few_combinations {
	ctx := object.remove(full_ctx, ["I03_dependency_matrix"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I03_dependency_matrix": {"combinations_tested": 5, "failure_modes": ["timeout", "error", "halt"]}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.dependency_chaos_matrix"
	decide.priority == 466003
}

# ═══ 12. I05 NEEDS_ADVICE: brak harmonogramu chaos day ═══
test_i05_needs_advice_no_chaos_day {
	ctx := object.remove(full_ctx, ["I05_chaos_day"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I05_chaos_day": {"chaos_day_scheduled": false}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.chaos_day_calendar"
}

# ═══ 13. I07 NEEDS_ADVICE: drabina dojrzałości niepełna ═══
test_i07_needs_advice_ladder_incomplete {
	ctx := object.remove(full_ctx, ["I07_maturity"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I07_maturity": {"ladder_levels": ["L1"], "current_level": "L1"}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.chaos_maturity_ladder"
	decide.priority == 466007
}

# ═══ 14. I08 NEEDS_ADVICE: awarie nie jako dane ═══
test_i08_needs_advice_not_as_data {
	ctx := object.remove(full_ctx, ["I08_injection_as_data"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I08_injection_as_data": {"experiments_as_data": false}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.failure_injection_as_data"
}

# ═══ 15. I09 NEEDS_ADVICE: przełamanie fail-closed wykryte chaosem ═══
test_i09_needs_advice_fail_closed_violation {
	ctx := object.remove(full_ctx, ["I09_findings"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I09_findings": {"fail_closed_violations_total": 2, "feed_to_repair_register": true}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.chaos_findings_to_repairs"
	decide.priority == 466009
}

# ═══ 16. I09 NEEDS_ADVICE: brak feedu do rejestru napraw ═══
test_i09_needs_advice_no_repair_feed {
	ctx := object.remove(full_ctx, ["I09_findings"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I09_findings": {"fail_closed_violations_total": 0, "feed_to_repair_register": false}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.chaos_findings_to_repairs"
}

# ═══ 17. I11 NEEDS_ADVICE: szczyt niesymulowany ═══
test_i11_needs_advice_peak_not_simulated {
	ctx := object.remove(full_ctx, ["I11_peak_time"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I11_peak_time": {"peak_experiment_present": false}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.peak_time_chaos"
}

# ═══ 18. I12 NEEDS_ADVICE: brak game day złożonego ═══
test_i12_needs_advice_no_game_day {
	ctx := object.remove(full_ctx, ["I12_game_day"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I12_game_day": {"game_day_present": false}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.game_day_pack"
}

# ═══ 19. Priorytety deterministyczne (ROUTER: BLOCK przed NEEDS_ADVICE) ═══
test_router_block_wins_over_needs_advice {
	ctx := object.remove(full_ctx, ["I02_experiment_cards", "I01_steady_state"])
	input := {"jdg_entrepreneur": {"v3_p66_check": true}, "v3_p66": object.union(ctx, {"I02_experiment_cards": {"cards_total": 12, "cards_incomplete_count": 1, "cards_incomplete": [{"id": "EX-05"}]}, "I01_steady_state": {"hypothesis_present": false}})}
	decide := v3_p66_chaos_resilience.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p66_chaos_resilience.experiment_card_standard"
}
