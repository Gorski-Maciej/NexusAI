package jdg.v3_p65_tool_forge_test

import data.jdg.v3_p65_tool_forge

# Pełny kontekst zielony (wszystkie 12 analiz PASS — wartości ze silników P65:
# tools/v3_p65_engines.py czytają bundla v3_p65_i*_engine.json)
full_ctx := {
	"I01_tool_contract": {"contract_fields_present": {"schema": true, "tool": true, "status": true, "provenance": true}},
	"I02_semantic_diff": {"classes_present": ["cosmetic", "threshold", "semantic"]},
	"I03_test_generator": {"edge_case_classes_present": ["dates", "thresholds", "currencies", "rounding"]},
	"I04_cashflow": {"scenarios_present": ["base", "delays", "vat_refund"]},
	"I05_temporal": {"transitions_present": ["day_minus_1", "day_0"]},
	"I06_rbac": {"roles_matrix": {
		"owner": {"field_map": {"*": 1}},
		"accountant": {"field_map": {"amount_gr": 1, "declaration": 1}},
		"auditor": {"field_map": {"certificate": 1}},
		"viewer": {"field_map": {"dashboard": 1}},
	}},
	"I07_benchmark": {"p95_ms": 320, "reduction_plan_registered": true},
	"I08_worm": {"tamper_probes": 5, "tampering_detected": 5},
	"I09_chaos": {"mutations": 196, "fail_closed_breaches": 0},
	"I10_composition": {"composition_analysis_present": true},
	"I11_adoption": {"unused_tools_without_decision": 0},
	"I12_docs": {"doc_binding_present": true},
}

activated_input := {"jdg_entrepreneur": {"v3_p65_check": true}, "v3_p65": full_ctx}
deactivated_input := {"jdg_entrepreneur": {}, "v3_p65": full_ctx}

# ═══ 1. Fail-closed: brak flagi aktywacji → NO_MATCH ═══
test_no_match_without_flag {
	decide := v3_p65_tool_forge.decide with input as deactivated_input
	decide.decision == "NO_MATCH"
	decide.rule_id == "jdg.v3_p65_tool_forge.no_match"
}

# ═══ 2. Fail-closed: brak snapshotu progów → NEEDS_ADVICE (precedencja) ═══
test_thresholds_missing_fail_closed {
	decide := v3_p65_tool_forge.decide with input as activated_input
	with data.jdg.thresholds.v3_p65 as {}
	decide.rule_id == "jdg.v3_p65_tool_forge.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 3. Kontekst zielony → PASS ═══
test_all_green_pass {
	decide := v3_p65_tool_forge.decide with input as activated_input
	decide.decision == "PASS"
	decide.rule_id == "jdg.v3_p65_tool_forge.all_green"
}

# ═══ 4. I01 BLOCK: narzędzie bez pola kontraktu raportu JSON ═══
# Uwaga: object.union robi głęboki merge — nadpisanie zagnieżdżonego obiektu
# wymaga object.remove (konwencja testów P65; lekcja z przebiegu day-1).
test_i01_block_missing_contract_field {
	ctx := object.remove(full_ctx, ["I01_tool_contract"])
	input := {"jdg_entrepreneur": {"v3_p65_check": true}, "v3_p65": object.union(ctx, {"I01_tool_contract": {"contract_fields_present": {"schema": true, "tool": true}}})}
	decide := v3_p65_tool_forge.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p65_tool_forge.tool_standard_contract"
	decide.priority == 465001
}

# ═══ 5. I02 NEEDS_ADVICE: brak klasy zmiany semantycznej ═══
test_i02_needs_advice_missing_class {
	input := {"jdg_entrepreneur": {"v3_p65_check": true}, "v3_p65": object.union(full_ctx, {"I02_semantic_diff": {"classes_present": ["cosmetic"]}})}
	decide := v3_p65_tool_forge.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p65_tool_forge.semantic_diff"
	decide.priority == 465002
}

# ═══ 6. I03 NEEDS_ADVICE: brak klasy brzegowej (waluty) ═══
test_i03_needs_advice_missing_edge_class {
	input := {"jdg_entrepreneur": {"v3_p65_check": true}, "v3_p65": object.union(full_ctx, {"I03_test_generator": {"edge_case_classes_present": ["dates", "thresholds"]}})}
	decide := v3_p65_tool_forge.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p65_tool_forge.rule_to_tests_generator"
}

# ═══ 7. I04 NEEDS_ADVICE: brak scenariusza zwrotu VAT ═══
test_i04_needs_advice_missing_scenario {
	input := {"jdg_entrepreneur": {"v3_p65_check": true}, "v3_p65": object.union(full_ctx, {"I04_cashflow": {"scenarios_present": ["base"]}})}
	decide := v3_p65_tool_forge.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p65_tool_forge.cashflow_simulator"
}

# ═══ 8. I05 NEEDS_ADVICE: brak przełączenia day-0 ═══
test_i05_needs_advice_missing_transition {
	input := {"jdg_entrepreneur": {"v3_p65_check": true}, "v3_p65": object.union(full_ctx, {"I05_temporal": {"transitions_present": ["day_minus_1"]}})}
	decide := v3_p65_tool_forge.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p65_tool_forge.temporal_simulator"
}

# ═══ 9. I06 BLOCK: rola bez mapy pól (ślepe uprawnienie) ═══
test_i06_block_role_without_field_map {
	ctx := object.remove(full_ctx, ["I06_rbac"])
	input := {"jdg_entrepreneur": {"v3_p65_check": true}, "v3_p65": object.union(ctx, {"I06_rbac": {"roles_matrix": {
		"owner": {"field_map": {"*": 1}},
		"accountant": {"field_map": {}},
		"auditor": {"field_map": {}},
		"viewer": {"field_map": {}},
	}}})}
	decide := v3_p65_tool_forge.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p65_tool_forge.rbac_validator"
	decide.priority == 465006
}

# ═══ 10. I07 BLOCK: regresja p95 ponad próg bez planu redukcji ═══
test_i07_block_p95_regression_no_plan {
	input := {"jdg_entrepreneur": {"v3_p65_check": true}, "v3_p65": object.union(full_ctx, {"I07_benchmark": {"p95_ms": 900, "reduction_plan_registered": false}})}
	decide := v3_p65_tool_forge.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p65_tool_forge.eval_benchmark"
	decide.priority == 465007
}

# ═══ 11. I08 BLOCK: próby naruszenia WORM niewykryte ═══
test_i08_block_tamper_undetected {
	input := {"jdg_entrepreneur": {"v3_p65_check": true}, "v3_p65": object.union(full_ctx, {"I08_worm": {"tamper_probes": 5, "tampering_detected": 3}})}
	decide := v3_p65_tool_forge.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p65_tool_forge.worm_tamper_tester"
	decide.priority == 465008
}

# ═══ 12. I09 NEEDS_ADVICE: mutacje poniżej minimum ═══
test_i09_needs_advice_below_min_mutations {
	input := {"jdg_entrepreneur": {"v3_p65_check": true}, "v3_p65": object.union(full_ctx, {"I09_chaos": {"mutations": 3, "fail_closed_breaches": 0}})}
	decide := v3_p65_tool_forge.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p65_tool_forge.legal_chaos_suite"
}

# ═══ 13. I09 NEEDS_ADVICE: przełamanie fail-closed (cichy AUTO_POST) ═══
test_i09_needs_advice_fail_closed_breach {
	input := {"jdg_entrepreneur": {"v3_p65_check": true}, "v3_p65": object.union(full_ctx, {"I09_chaos": {"mutations": 200, "fail_closed_breaches": 1}})}
	decide := v3_p65_tool_forge.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p65_tool_forge.legal_chaos_suite"
	decide.priority == 465009
}

# ═══ 14. I10 NEEDS_ADVICE: brak analizy kompozycji ═══
test_i10_needs_advice_no_composition_analysis {
	input := {"jdg_entrepreneur": {"v3_p65_check": true}, "v3_p65": object.union(full_ctx, {"I10_composition": {"composition_analysis_present": false}})}
	decide := v3_p65_tool_forge.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p65_tool_forge.composition_first"
}

# ═══ 15. I11 NEEDS_ADVICE: narzędzie nieużywane bez decyzji ═══
test_i11_needs_advice_unused_tool_no_decision {
	input := {"jdg_entrepreneur": {"v3_p65_check": true}, "v3_p65": object.union(full_ctx, {"I11_adoption": {"unused_tools_without_decision": 2}})}
	decide := v3_p65_tool_forge.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p65_tool_forge.tool_adoption_metrics"
}

# ═══ 16. I12 NEEDS_ADVICE: dryf dokumentacji (binding P60) ═══
test_i12_needs_advice_doc_drift {
	input := {"jdg_entrepreneur": {"v3_p65_check": true}, "v3_p65": object.union(full_ctx, {"I12_docs": {"doc_binding_present": false}})}
	decide := v3_p65_tool_forge.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p65_tool_forge.doc_generator"
}

# ═══ 17. Priorytety deterministyczne (ROUTER: BLOCK przed NEEDS_ADVICE) ═══
test_router_block_wins_over_needs_advice {
	ctx := object.remove(full_ctx, ["I01_tool_contract", "I02_semantic_diff"])
	input := {"jdg_entrepreneur": {"v3_p65_check": true}, "v3_p65": object.union(ctx, {"I01_tool_contract": {"contract_fields_present": {}}, "I02_semantic_diff": {"classes_present": []}})}
	decide := v3_p65_tool_forge.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p65_tool_forge.tool_standard_contract"
}
