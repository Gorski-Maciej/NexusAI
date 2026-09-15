package jdg.v3_p64_luka_sweep_test

import data.jdg.v3_p64_luka_sweep

# Pełny kontekst zielony (wszystkie 12 analiz PASS — wartości z silników P64)
full_ctx := {
	"I01_sweep_register": {"open_items": [{"part": "P63", "luki": {"p1": 1, "p2": 2, "p3": 2}}], "sla_plan_registered": true},
	"I02_cross_checks": {"checks_present": ["rule_test", "test_rule", "tool_test", "integration_contract", "fail_closed", "param_window", "legal_basis"]},
	"I03_blindspots": {"classes": ["BS01", "BS02", "BS03", "BS04", "BS05"]},
	"I04_ownerless": {"orphans": ["rules/legacy.rego:not-imported-by-main"], "decisions_registered": true},
	"I05_second_pass": {"executed": true, "new_items": 0},
	"I06_declarations": {"undocumented_claims": [{"part": "P11"}], "evidence_plan_registered": true},
	"I07_risk": {"risk_score": 1165, "reduction_plan_registered": true},
	"I08_dashboard": {"channels_present": ["ci_gate", "ledger_trend", "weekly_sweep", "alert_routing"]},
	"I09_automation": {"cyclic_sweep_present": true},
	"I10_handover": {"handover_contracts": ["C1", "C2", "C3", "C4"]},
	"I11_meta": {"swept_dirs": ["rules", "tools", "bundles", "migrations", "tests", "docs", "api", "policies"], "unswept_dirs": []},
	"I12_report": {"sections_present": ["exec_summary", "classes", "cross_checks", "register", "plan", "trend"]},
}

activated_input := {"jdg_entrepreneur": {"v3_p64_check": true}, "v3_p64": full_ctx}
deactivated_input := {"jdg_entrepreneur": {}, "v3_p64": full_ctx}

# ═══ 1. Fail-closed: brak flagi aktywacji → NO_MATCH ═══
test_no_match_without_flag {
	decide := v3_p64_luka_sweep.decide with input as deactivated_input
	decide.decision == "NO_MATCH"
	decide.rule_id == "jdg.v3_p64_luka_sweep.no_match"
}

# ═══ 2. Fail-closed: brak snapshotu progów → NEEDS_ADVICE (precedencja) ═══
test_thresholds_missing_fail_closed {
	decide := v3_p64_luka_sweep.decide with input as activated_input
	with data.jdg.thresholds.v3_p64 as {}
	decide.rule_id == "jdg.v3_p64_luka_sweep.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 3. Kontekst zielony → PASS ═══
test_all_green_pass {
	decide := v3_p64_luka_sweep.decide with input as activated_input
	decide.decision == "PASS"
	decide.rule_id == "jdg.v3_p64_luka_sweep.all_green"
}

# ═══ 4. I01 BLOCK: rejestr rezydualny bez planu SLA ═══
test_i01_block_no_sla_plan {
	input := {"jdg_entrepreneur": {"v3_p64_check": true}, "v3_p64": object.union(full_ctx, {"I01_sweep_register": {"open_items": [{"part": "P63"}], "sla_plan_registered": false}})}
	decide := v3_p64_luka_sweep.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p64_luka_sweep.sweep_register_sla"
	decide.priority == 464001
}

# ═══ 5. I02 BLOCK: niekompletny zestaw 7 kontroli ═══
test_i02_block_missing_cross_check {
	input := {"jdg_entrepreneur": {"v3_p64_check": true}, "v3_p64": object.union(full_ctx, {"I02_cross_checks": {"checks_present": ["rule_test", "test_rule", "tool_test"]}})}
	decide := v3_p64_luka_sweep.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p64_luka_sweep.seven_cross_checks"
}

# ═══ 6. I04 BLOCK: osierocone bez decyzji przypisz/usuń ═══
test_i04_block_ownerless_no_decision {
	input := {"jdg_entrepreneur": {"v3_p64_check": true}, "v3_p64": object.union(full_ctx, {"I04_ownerless": {"orphans": ["rules/x.rego"], "decisions_registered": false}})}
	decide := v3_p64_luka_sweep.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p64_luka_sweep.ownerless_artifacts"
}

# ═══ 7. I07 BLOCK: ryzyko rezydualne bez planu redukcji ═══
test_i07_block_risk_no_plan {
	input := {"jdg_entrepreneur": {"v3_p64_check": true}, "v3_p64": object.union(full_ctx, {"I07_risk": {"risk_score": 9999, "reduction_plan_registered": false}})}
	decide := v3_p64_luka_sweep.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p64_luka_sweep.residual_risk_score"
}

# ═══ 8. I03 NEEDS_ADVICE: za mało klas ślepych plam ═══
test_i03_needs_advice_few_blindspot_classes {
	input := {"jdg_entrepreneur": {"v3_p64_check": true}, "v3_p64": object.union(full_ctx, {"I03_blindspots": {"classes": ["BS01"]}})}
	decide := v3_p64_luka_sweep.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p64_luka_sweep.blindspot_taxonomy"
}

# ═══ 9. I05 NEEDS_ADVICE: brak drugiego przebiegu sweep ═══
test_i05_needs_advice_no_second_pass {
	input := {"jdg_entrepreneur": {"v3_p64_check": true}, "v3_p64": object.union(full_ctx, {"I05_second_pass": {"executed": false, "new_items": 0}})}
	decide := v3_p64_luka_sweep.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p64_luka_sweep.second_pass_stability"
}

# ═══ 10. I05 NEEDS_ADVICE: drugi przebieg z nowymi pozycjami ═══
test_i05_needs_advice_new_items {
	input := {"jdg_entrepreneur": {"v3_p64_check": true}, "v3_p64": object.union(full_ctx, {"I05_second_pass": {"executed": true, "new_items": 3}})}
	decide := v3_p64_luka_sweep.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 11. I06 NEEDS_ADVICE: deklaracje bez dowodu bez planu ═══
test_i06_needs_advice_undocumented_no_plan {
	input := {"jdg_entrepreneur": {"v3_p64_check": true}, "v3_p64": object.union(full_ctx, {"I06_declarations": {"undocumented_claims": [{"part": "P11"}, {"part": "P12"}], "evidence_plan_registered": false}})}
	decide := v3_p64_luka_sweep.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p64_luka_sweep.declaration_vs_evidence"
}

# ═══ 12. I08 NEEDS_ADVICE: brak kanału dashboardu ═══
test_i08_needs_advice_missing_channel {
	input := {"jdg_entrepreneur": {"v3_p64_check": true}, "v3_p64": object.union(full_ctx, {"I08_dashboard": {"channels_present": ["ci_gate"]}})}
	decide := v3_p64_luka_sweep.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p64_luka_sweep.cross_check_dashboard"
}

# ═══ 13. I09 NEEDS_ADVICE: sweep jednorazowy bez automatu ═══
test_i09_needs_advice_no_automation {
	input := {"jdg_entrepreneur": {"v3_p64_check": true}, "v3_p64": object.union(full_ctx, {"I09_automation": {"cyclic_sweep_present": false}})}
	decide := v3_p64_luka_sweep.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p64_luka_sweep.sweep_automation"
}

# ═══ 14. I10 NEEDS_ADVICE: handover bez kontraktów ═══
test_i10_needs_advice_no_contracts {
	input := {"jdg_entrepreneur": {"v3_p64_check": true}, "v3_p64": object.union(full_ctx, {"I10_handover": {"handover_contracts": []}})}
	decide := v3_p64_luka_sweep.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p64_luka_sweep.handover_v4"
}

# ═══ 15. I11 NEEDS_ADVICE: katalogi nieobjęte meta-kontrolą ═══
test_i11_needs_advice_unswept_dirs {
	input := {"jdg_entrepreneur": {"v3_p64_check": true}, "v3_p64": object.union(full_ctx, {"I11_meta": {"swept_dirs": ["rules", "tools", "bundles", "migrations", "tests", "docs", "api", "policies"], "unswept_dirs": ["policies"]}})}
	decide := v3_p64_luka_sweep.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p64_luka_sweep.sweep_of_sweeps"
}

# ═══ 16. I12 NEEDS_ADVICE: brak sekcji standardu raportu ═══
test_i12_needs_advice_missing_sections {
	input := {"jdg_entrepreneur": {"v3_p64_check": true}, "v3_p64": object.union(full_ctx, {"I12_report": {"sections_present": ["exec_summary"]}})}
	decide := v3_p64_luka_sweep.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p64_luka_sweep.residual_report_format"
}

# ═══ 17. Priorytety deterministyczne (ROUTER: BLOCK przed NEEDS_ADVICE) ═══
test_router_block_wins_over_needs_advice {
	input := {"jdg_entrepreneur": {"v3_p64_check": true}, "v3_p64": object.union(full_ctx, {"I02_cross_checks": {"checks_present": []}, "I03_blindspots": {"classes": []}})}
	decide := v3_p64_luka_sweep.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p64_luka_sweep.seven_cross_checks"
}
