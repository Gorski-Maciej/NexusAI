# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY NATYWNE V3-P58 OBSERWOWALNOŚĆ DOMKNIĘCIE (konwencja
# P39/P45–P57: negative-first, granice progów, fail-closed, never-silent
# AUTO_POST, bypass → NO_MATCH, determinizm else-chain, freshness / regresja
# pokrycia / advice-spread / penny drift / telemetria / error budget / runbooki /
# post-mortemy / eskalacja / risk-mining / prywatność / SLO per domena).
# Uruchomienie: opa test (0.68) / opa19 test --v0-compatible (1.9)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p58_observability_closure_test

import data.jdg.v3_p58_observability_closure

# ── Fixture: pełny kontekst dowodowy (stan bazowy narzędzi P58) ────────────────
full_ctx := {
	"I01_legal_freshness_sla": {"acts_total": 12, "acts_beyond_sla": [], "acts_unverified": []},
	"I02_coverage_regression_alarm": {"coverage_current": 87.5, "coverage_baseline": 87.5, "new_deserts": [], "drop_pp": 0},
	"I03_advice_spread_radar": {"domains_total": 8, "domains_hot": []},
	"I04_penny_drift_telemetry": {"drift_gr": 0, "trend": "zero", "traces": []},
	"I05_decision_telemetry_registry": {"certs_total": 10, "certs_incomplete": []},
	"I06_error_budget_freeze": {"budget_pct": 85, "freeze_active": false},
	"I07_runbook_per_alarm": {"alarms_total": 12, "with_runbook": ["A01", "A02", "A03", "A04", "A05", "A06", "A07", "A08", "A09", "A10", "A11", "A12"], "without_runbook": []},
	"I08_postmortem_registry": {"incidents_total": 3, "pending_postmortem": [], "registry_size": 3},
	"I09_escalation_matrix": {"levels_total": 3, "levels_incomplete": []},
	"I10_risk_pattern_mining": {"events_total": 100, "patterns_high_risk": []},
	"I11_telemetry_privacy_guard": {"records_scanned": 10, "pii_hits": [], "privacy_mode": "pseudonymized"},
	"I12_slo_per_domain": {"domains_total": 6, "domains_missing_slo": []},
}

activated_input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": full_ctx}
deactivated_input := {"jdg_entrepreneur": {}, "v3_p58": full_ctx}

# ═══ 1. NEGATIVE-FIRST: brak aktywacji → NO_MATCH (żadnych efektów ubocznych) ═══
test_decide_no_match_without_flag {
	decide := v3_p58_observability_closure.decide with input as deactivated_input
	decide.decision == "NO_MATCH"
	decide.matched == false
}

# ═══ 2. FAIL-CLOSED: brak snapshotu progów → NEEDS_ADVICE, nigdy cicho ═══
test_fail_closed_thresholds_missing {
	decide := v3_p58_observability_closure.decide with input as activated_input
	with data.jdg.thresholds.v3_p58 as {}
	decide.rule_id == "jdg.v3_p58_observability_closure.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
	decide.priority == 0
}

# ═══ 3. ROUTER: stan bazowy (wszystkie bramki zielone) → all_green PASS ═══
test_router_all_green_pass {
	decide := v3_p58_observability_closure.decide with input as activated_input
	decide.rule_id == "jdg.v3_p58_observability_closure.all_green"
	decide.decision == "PASS"
}

# ═══ 4. ROUTER determinizm: dwie ewaluacje = ten sam werdykt ═══
test_router_deterministic {
	a := v3_p58_observability_closure.decide with input as activated_input
	b := v3_p58_observability_closure.decide with input as activated_input
	a == b
}

# ═══ 5. I01: akt poza SLA świeżości ISAP = NEEDS_ADVICE ═══
test_i01_stale_act_advice {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I01_legal_freshness_sla": {"acts_total": 12, "acts_beyond_sla": ["UST-VAT"], "acts_unverified": []}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.legal_freshness_sla"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 5b. I01: akt niezweryfikowany w ogóle = NEEDS_ADVICE ═══
test_i01_unverified_act_advice {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I01_legal_freshness_sla": {"acts_total": 12, "acts_beyond_sla": [], "acts_unverified": ["UST-KKS"]}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.legal_freshness_sla"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 6. I02: nowa pustynia prawna = BLOCK ═══
test_i02_new_desert_blocks {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I02_coverage_regression_alarm": {"coverage_current": 86.0, "coverage_baseline": 87.5, "new_deserts": ["ksef_e"], "drop_pp": 1.5}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.coverage_regression_alarm"
	decide.decision == "BLOCK"
}

# ═══ 6b. I02 granica: spadek dokładnie 0 pp (próg 0) → nieaktywny; tylko > 0 ═══
test_i02_boundary_drop_only_above_threshold {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I02_coverage_regression_alarm": {"coverage_current": 87.0, "coverage_baseline": 87.5, "new_deserts": [], "drop_pp": 0.5}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.coverage_regression_alarm"
}

# ═══ 6c. I02: pokrycie wzrosło (drop_pp = 0) → nieaktywny ═══
test_i02_improvement_inactive {
	decide := v3_p58_observability_closure.decide with input as activated_input
	decide.rule_id != "jdg.v3_p58_observability_closure.coverage_regression_alarm"
}

# ═══ 7. I03: domena z spreadem powyżej progu 15% = NEEDS_ADVICE ═══
test_i03_hot_domain_advice {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I03_advice_spread_radar": {"domains_total": 8, "domains_hot": [{"domain": "vat", "spread_pct": 22}]}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.advice_spread_radar"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 7b. I03 granica (kontrakt ról): silnik oznacza hot tylko gdy spread > próg;
# domain dokładnie na 15.0% NIE jest hot → Rego nieaktywne. Asercja silnika (15.0
# nie-hot, 15.1 hot) w pytest (test_i03_engine_boundary). ═══
test_i03_boundary_at_threshold_inactive {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I03_advice_spread_radar": {"domains_total": 8, "domains_hot": []}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id != "jdg.v3_p58_observability_closure.advice_spread_radar"
}

# ═══ 8. I04: dryf groszowy powyżej progu 0 gr = BLOCK ═══
test_i04_drift_above_threshold_blocks {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I04_penny_drift_telemetry": {"drift_gr": 3, "trend": "rising", "traces": ["W1"]}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.penny_drift_telemetry"
	decide.decision == "BLOCK"
}

# ═══ 8b. I04 granica: dryf 0 gr (trend: zero) → nieaktywny ═══
test_i04_boundary_zero_inactive {
	decide := v3_p58_observability_closure.decide with input as activated_input
	decide.rule_id != "jdg.v3_p58_observability_closure.penny_drift_telemetry"
}

# ═══ 9. I05: certyfikat bez pełnego kontekstu = NEEDS_ADVICE ═══
test_i05_incomplete_cert_advice {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I05_decision_telemetry_registry": {"certs_total": 10, "certs_incomplete": ["DC-1"]}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.decision_telemetry_registry"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 10. I06: budżet poniżej progu BEZ zamrożenia = BLOCK ═══
test_i06_budget_exhausted_no_freeze_blocks {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I06_error_budget_freeze": {"budget_pct": 10, "freeze_active": false}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.error_budget_freeze"
	decide.decision == "BLOCK"
}

# ═══ 10b. I06: budżet poniżej progu ALE zamrożenie aktywne → nie BLOCK ═══
test_i06_freeze_active_no_block {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I06_error_budget_freeze": {"budget_pct": 10, "freeze_active": true}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id != "jdg.v3_p58_observability_closure.error_budget_freeze"
}

# ═══ 10c. I06 granica: budżet dokładnie na progu 20% → nieaktywny (tylko < próg) ═══
test_i06_boundary_at_threshold_inactive {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I06_error_budget_freeze": {"budget_pct": 20, "freeze_active": false}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id != "jdg.v3_p58_observability_closure.error_budget_freeze"
}

# ═══ 11. I07: alarm bez runbooka = BLOCK ═══
test_i07_alarm_without_runbook_blocks {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I07_runbook_per_alarm": {"alarms_total": 12, "with_runbook": ["A01"], "without_runbook": ["A13"]}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.runbook_per_alarm"
	decide.decision == "BLOCK"
}

# ═══ 12. I08: incydent bez post-mortemu = NEEDS_ADVICE ═══
test_i08_pending_postmortem_advice {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I08_postmortem_registry": {"incidents_total": 3, "pending_postmortem": ["INC-2"], "registry_size": 2}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.postmortem_registry"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 13. I09: niekompletny poziom eskalacji = NEEDS_ADVICE ═══
test_i09_incomplete_level_advice {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I09_escalation_matrix": {"levels_total": 3, "levels_incomplete": ["L2-prawnik"]}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.escalation_matrix"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 13b. I09: za mało poziomów (2 < wymagane 3) = NEEDS_ADVICE (else-branch) ═══
test_i09_too_few_levels_advice {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I09_escalation_matrix": {"levels_total": 2, "levels_incomplete": []}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.escalation_matrix"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 14. I10: wzorce wysokiego ryzyka = MANUAL_REVIEW ═══
test_i10_risk_patterns_review {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I10_risk_pattern_mining": {"events_total": 100, "patterns_high_risk": [{"domain": "vat", "concentration_pct": 40}]}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.risk_pattern_mining"
	decide.decision == "MANUAL_REVIEW"
}

# ═══ 15. I11: PII w telemetrii = BLOCK ═══
test_i11_pii_leak_blocks {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I11_telemetry_privacy_guard": {"records_scanned": 10, "pii_hits": ["DC-3:contractor_name"], "privacy_mode": "pseudonymized"}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.telemetry_privacy_guard"
	decide.decision == "BLOCK"
}

# ═══ 15b. I11: tryb prywatności niezgodny z wymaganym = BLOCK (else-branch) ═══
test_i11_wrong_privacy_mode_blocks {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I11_telemetry_privacy_guard": {"records_scanned": 10, "pii_hits": [], "privacy_mode": "raw"}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.telemetry_privacy_guard"
	decide.decision == "BLOCK"
}

# ═══ 16. I12: domena bez SLO = NEEDS_ADVICE ═══
test_i12_missing_slo_advice {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I12_slo_per_domain": {"domains_total": 6, "domains_missing_slo": ["pcc"]}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.slo_per_domain"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 17. ROUTER priorytet: BLOCK (budget bez freeze) wygrywa z NEEDS_ADVICE ═══
test_router_block_precedence {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I06_error_budget_freeze": {"budget_pct": 5, "freeze_active": false}, "I01_legal_freshness_sla": {"acts_total": 12, "acts_beyond_sla": ["UST-VAT"], "acts_unverified": []}})}
	decide := v3_p58_observability_closure.decide with input as input
	decide.rule_id == "jdg.v3_p58_observability_closure.error_budget_freeze"
	decide.decision == "BLOCK"
}

# ═══ 18. Werydykty zawsze mają pełny kształt kontraktu (P03) ═══
test_verdict_shape_full_contract {
	decide := v3_p58_observability_closure.decide with input as activated_input
	decide.rule_id != ""
	decide["package"] == "jdg.v3_p58_observability_closure"
	decide._legal_basis != ""
	decide.valid_from == "2026-01-01"
}

# ═══ 19. Żaden werdykt P58 nigdy nie zwraca AUTO_POST (forteca) ═══
test_no_auto_post_anywhere {
	decide := v3_p58_observability_closure.decide with input as activated_input
	decide.decision != "AUTO_POST"
	input2 := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I04_penny_drift_telemetry": {"drift_gr": 100, "trend": "rising", "traces": []}})}
	decide2 := v3_p58_observability_closure.decide with input as input2
	decide2.decision != "AUTO_POST"
}

# ═══ 20. Progi z ADR-002 respektowane: SLA obniżone do 0 → akt wieku 1 dnia go nie dotnie... ═══
# (kontrola odwrotna: SLA=0 → każdy akt niezweryfikowany nadal łapie niezweryfikowane)
test_thresholds_respected {
	input := {"jdg_entrepreneur": {"v3_p58_check": true}, "v3_p58": object.union(full_ctx, {"I01_legal_freshness_sla": {"acts_total": 12, "acts_beyond_sla": [], "acts_unverified": ["UST-X"]}})}
	decide := v3_p58_observability_closure.decide with input as input
	with data.jdg.thresholds.v3_p58 as {"v3_p58_isap_freshness_sla_days": 0}
	decide.rule_id == "jdg.v3_p58_observability_closure.legal_freshness_sla"
	contains(decide.reason, "0 dni")
}
