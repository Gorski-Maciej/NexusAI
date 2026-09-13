package jdg.v3_p63_rbac_multitenant_closure_test

import data.jdg.v3_p63_rbac_multitenant_closure

# Pełny kontekst zielony (wszystkie 12 analiz PASS — wartości z silników P63)
full_ctx := {
	"I01_rbac_as_data": {"roles_total": 4, "missing_field_map": []},
	"I02_separation_of_duties": {"enforced": true},
	"I03_tenant_isolation": {"cross_tenant_leaks": 0, "missing_tenant": []},
	"I04_breakglass": {"flagged": true, "review_required": true},
	"I05_access_audit": {"worm_gate": "PASS", "anomaly_channels": ["night_access", "mass_export", "repeat_pattern"]},
	"I06_right_to_be_forgotten": {"erasure_path": true, "retention_exception": true},
	"I07_per_tenant_quotas": {"governor_gate": "PASS"},
	"I08_data_flow_map": {"channels": ["ksef", "bank", "csv", "api", "email", "scan"]},
	"I09_pseudonymization": {"privacy_mode": "pseudonymized"},
	"I10_schema_readiness": {"elements_with_tenant_id": ["migration:001"]},
	"I11_permission_drift": {"alarm_present": true},
	"I12_role_onboarding": {"roles": ["entrepreneur", "accountant", "auditor", "admin"], "packed_roles": ["entrepreneur", "accountant", "auditor", "admin"]},
}

activated_input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": full_ctx}
deactivated_input := {"jdg_entrepreneur": {}, "v3_p63": full_ctx}

# ═══ 1. Fail-closed: brak flagi aktywacji → NO_MATCH ═══
test_no_match_without_flag {
	decide := v3_p63_rbac_multitenant_closure.decide with input as deactivated_input
	decide.decision == "NO_MATCH"
	decide.rule_id == "jdg.v3_p63_rbac_multitenant_closure.no_match"
}

# ═══ 2. Fail-closed: brak snapshotu progów → NEEDS_ADVICE (precedencja) ═══
test_thresholds_missing_fail_closed {
	decide := v3_p63_rbac_multitenant_closure.decide with input as activated_input
	with data.jdg.thresholds.v3_p63 as {}
	decide.rule_id == "jdg.v3_p63_rbac_multitenant_closure.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 3. Kontekst zielony → PASS ═══
test_all_green_pass {
	decide := v3_p63_rbac_multitenant_closure.decide with input as activated_input
	decide.decision == "PASS"
	decide.rule_id == "jdg.v3_p63_rbac_multitenant_closure.all_green"
}

# ═══ 4. I01 BLOCK: rola bez mapowania rola→pola ═══
test_i01_block_missing_field_map {
	input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": object.union(full_ctx, {"I01_rbac_as_data": {"roles_total": 4, "missing_field_map": ["entrepreneur"]}})}
	decide := v3_p63_rbac_multitenant_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p63_rbac_multitenant_closure.rbac_as_data"
	decide.priority == 463001
}

# ═══ 5. I03 BLOCK: cross-tenant leak ═══
test_i03_block_cross_tenant_leak {
	input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": object.union(full_ctx, {"I03_tenant_isolation": {"cross_tenant_leaks": 2, "missing_tenant": []}})}
	decide := v3_p63_rbac_multitenant_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p63_rbac_multitenant_closure.tenant_isolation"
}

# ═══ 6. I06 BLOCK: brak ścieżki usunięcia (art. 17 RODO) ═══
test_i06_block_no_erasure_path {
	input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": object.union(full_ctx, {"I06_right_to_be_forgotten": {"erasure_path": false, "retention_exception": true}})}
	decide := v3_p63_rbac_multitenant_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p63_rbac_multitenant_closure.right_to_be_forgotten"
}

# ═══ 7. I06 BLOCK: brak wyjątku retencji księgowej (art. 74 UoR) ═══
test_i06_block_no_retention_exception {
	input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": object.union(full_ctx, {"I06_right_to_be_forgotten": {"erasure_path": true, "retention_exception": false}})}
	decide := v3_p63_rbac_multitenant_closure.decide with input as input
	decide.decision == "BLOCK"
}

# ═══ 8. I09 BLOCK: telemetria bez pseudonimizacji ═══
test_i09_block_wrong_privacy_mode {
	input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": object.union(full_ctx, {"I09_pseudonymization": {"privacy_mode": "raw"}})}
	decide := v3_p63_rbac_multitenant_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p63_rbac_multitenant_closure.pseudonymization_by_default"
}

# ═══ 9. I02 NEEDS_ADVICE: SoD niewymuszona ═══
test_i02_advice_sod_not_enforced {
	input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": object.union(full_ctx, {"I02_separation_of_duties": {"enforced": false}})}
	decide := v3_p63_rbac_multitenant_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p63_rbac_multitenant_closure.separation_of_duties"
}

# ═══ 10. I04 NEEDS_ADVICE: break-glass bez review ═══
test_i04_advice_no_review {
	input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": object.union(full_ctx, {"I04_breakglass": {"flagged": true, "review_required": false}})}
	decide := v3_p63_rbac_multitenant_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 11. I05 NEEDS_ADVICE: audyt bez WORM ═══
test_i05_advice_no_worm {
	input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": object.union(full_ctx, {"I05_access_audit": {"worm_gate": "MISSING", "anomaly_channels": ["night_access", "mass_export", "repeat_pattern"]}})}
	decide := v3_p63_rbac_multitenant_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 12. I05 NEEDS_ADVICE: za mało kanałów anomalii ═══
test_i05_advice_few_channels {
	input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": object.union(full_ctx, {"I05_access_audit": {"worm_gate": "PASS", "anomaly_channels": ["night_access"]}})}
	decide := v3_p63_rbac_multitenant_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 13. I07 NEEDS_ADVICE: governor nieobecny ═══
test_i07_advice_no_governor {
	input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": object.union(full_ctx, {"I07_per_tenant_quotas": {"governor_gate": "MISSING"}})}
	decide := v3_p63_rbac_multitenant_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 14. I08 NEEDS_ADVICE: za mało kanałów w mapie przepływów ═══
test_i08_advice_few_channels {
	input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": object.union(full_ctx, {"I08_data_flow_map": {"channels": ["ksef", "bank"]}})}
	decide := v3_p63_rbac_multitenant_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 15. I10 NEEDS_ADVICE: brak tenant_id w schemacie ═══
test_i10_advice_no_tenant_schema {
	input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": object.union(full_ctx, {"I10_schema_readiness": {"elements_with_tenant_id": []}})}
	decide := v3_p63_rbac_multitenant_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 16. I11 NEEDS_ADVICE: brak alarmu dryfu uprawnień ═══
test_i11_advice_no_drift_alarm {
	input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": object.union(full_ctx, {"I11_permission_drift": {"alarm_present": false}})}
	decide := v3_p63_rbac_multitenant_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 17. I12 NEEDS_ADVICE: rola bez pakietu onboardingu ═══
test_i12_advice_missing_pack {
	input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": object.union(full_ctx, {"I12_role_onboarding": {"roles": ["entrepreneur", "accountant", "auditor", "admin"], "packed_roles": ["entrepreneur"]}})}
	decide := v3_p63_rbac_multitenant_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 18. Precedencja: BLOCK (I01, 463001) wygrywa z NEEDS_ADVICE (I02) ═══
test_block_precedence {
	input := {"jdg_entrepreneur": {"v3_p63_check": true}, "v3_p63": object.union(full_ctx, {"I01_rbac_as_data": {"roles_total": 4, "missing_field_map": ["admin"]}, "I02_separation_of_duties": {"enforced": false}})}
	decide := v3_p63_rbac_multitenant_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.priority == 463001
}
