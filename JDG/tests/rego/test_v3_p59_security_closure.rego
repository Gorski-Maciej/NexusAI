# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY NATYWNE V3-P59 BEZPIECZEŃSTWO DOMKNIĘCIE (konwencja
# P39/P45–P58: negative-first, granice progów, fail-closed, never-silent
# AUTO_POST, bypass → NO_MATCH, determinizm else-chain, threat model / podpisy
# 4-eyes / hash chain / anomaly stawek / sekrety / CI hardening / attestation /
# insider / SBOM / drills / granice zaufania / security score).
# Uruchomienie: opa test (0.68) / opa19 test --v0-compatible (1.9)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p59_security_closure_test

import data.jdg.v3_p59_security_closure

# ── Fixture: pełny kontekst dowodowy (stan bazowy narzędzi P59) ────────────────
full_ctx := {
	"I01_threat_model_gates": {"vectors_total": 12, "vectors_uncovered": []},
	"I02_signed_rules_4eyes": {"critical_total": 4, "critical_unsigned": []},
	"I03_rule_history_hash_chain": {"chain_valid": true, "tamper_detected": true, "tamper_cases": 1},
	"I04_rate_change_anomaly": {"hardcoded_rates": 0, "unapproved_changes": []},
	"I05_secrets_vault_contract": {"repo_hits": [], "audit_usage": true, "break_glass": true},
	"I06_ci_hardening_checklist": {"score_pct": 75, "missing_controls": []},
	"I07_build_attestation_verification": {"deps_total": 44, "deps_missing_provenance": []},
	"I08_insider_threat_program": {"elements_missing": [], "suspicious_signals": 0},
	"I09_supply_chain_sbom": {"deps_total": 0, "pinned": 0, "sbom_present": true},
	"I10_security_chaos_drills": {"security_experiments": 3, "last_drill": "2026-09-01"},
	"I11_trust_boundary_map": {"actors_total": 5, "flows_total": 8, "flows_uncontrolled": []},
	"I12_security_score_trend": {"score_pct": 83, "trend": "rising"},
}

activated_input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": full_ctx}
deactivated_input := {"jdg_entrepreneur": {}, "v3_p59": full_ctx}

# ═══ 1. NEGATIVE-FIRST: brak aktywacji → NO_MATCH (żadnych efektów ubocznych) ═══
test_decide_no_match_without_flag {
	decide := v3_p59_security_closure.decide with input as deactivated_input
	decide.decision == "NO_MATCH"
	decide.matched == false
}

# ═══ 2. FAIL-CLOSED: brak snapshotu progów → NEEDS_ADVICE, nigdy cicho ═══
test_fail_closed_thresholds_missing {
	decide := v3_p59_security_closure.decide with input as activated_input
	with data.jdg.thresholds.v3_p59 as {}
	decide.rule_id == "jdg.v3_p59_security_closure.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
	decide.priority == 0
}

# ═══ 3. ROUTER: stan bazowy (wszystkie bramki zielone) → all_green PASS ═══
test_router_all_green_pass {
	decide := v3_p59_security_closure.decide with input as activated_input
	decide.rule_id == "jdg.v3_p59_security_closure.all_green"
	decide.decision == "PASS"
}

# ═══ 4. ROUTER determinizm: dwie ewaluacje = ten sam werdykt ═══
test_router_deterministic {
	a := v3_p59_security_closure.decide with input as activated_input
	b := v3_p59_security_closure.decide with input as activated_input
	a == b
}

# ═══ 5. I01: wektor bez kontrola = BLOCK ═══
test_i01_uncovered_vector_blocks {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I01_threat_model_gates": {"vectors_total": 12, "vectors_uncovered": ["rule_injection"]}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.threat_model_gates"
	decide.decision == "BLOCK"
}

# ═══ 5b. I01: za mało wektorów (< 12) = BLOCK (else-branch) ═══
test_i01_too_few_vectors_blocks {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I01_threat_model_gates": {"vectors_total": 5, "vectors_uncovered": []}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.threat_model_gates"
	decide.decision == "BLOCK"
}

# ═══ 6. I02: krytyczna reguła bez podpisu = NEEDS_ADVICE ═══
test_i02_unsigned_rule_advice {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I02_signed_rules_4eyes": {"critical_total": 4, "critical_unsigned": ["jdg.vat.rate"]}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.signed_rules_4eyes"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 7. I03: łańcuch przerwany = BLOCK ═══
test_i03_broken_chain_blocks {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I03_rule_history_hash_chain": {"chain_valid": false, "tamper_detected": false, "tamper_cases": 1}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.rule_history_hash_chain"
	decide.decision == "BLOCK"
}

# ═══ 7b. I03: tamper niewykryty = BLOCK (else-branch — pozytywna kontrola drillu) ═══
test_i03_undetected_tamper_blocks {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I03_rule_history_hash_chain": {"chain_valid": true, "tamper_detected": false, "tamper_cases": 2}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.rule_history_hash_chain"
	decide.decision == "BLOCK"
}

# ═══ 7c. I03 granica: zero tamper cases → drill nieaktywny (brak else-BLOCK) ═══
test_i03_no_tamper_cases_inactive {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I03_rule_history_hash_chain": {"chain_valid": true, "tamper_detected": false, "tamper_cases": 0}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id != "jdg.v3_p59_security_closure.rule_history_hash_chain"
}

# ═══ 8. I04: hardcode stawki = BLOCK ═══
test_i04_hardcoded_rate_blocks {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I04_rate_change_anomaly": {"hardcoded_rates": 2, "unapproved_changes": []}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.rate_change_anomaly"
	decide.decision == "BLOCK"
}

# ═══ 8b. I04: zmiana ponad próg bez 4-eyes = BLOCK (else-branch) ═══
test_i04_unapproved_change_blocks {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I04_rate_change_anomaly": {"hardcoded_rates": 0, "unapproved_changes": ["vat_23_to_8"]}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.rate_change_anomaly"
	decide.decision == "BLOCK"
}

# ═══ 9. I05: sekret w repo = BLOCK ═══
test_i05_secret_in_repo_blocks {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I05_secrets_vault_contract": {"repo_hits": ["tools/leak.py:12"], "audit_usage": true, "break_glass": true}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.secrets_vault_contract"
	decide.decision == "BLOCK"
}

# ═══ 9b. I05: brak audytu użycia kluczy = BLOCK (else-branch) ═══
test_i05_no_audit_usage_blocks {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I05_secrets_vault_contract": {"repo_hits": [], "audit_usage": false, "break_glass": true}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.secrets_vault_contract"
	decide.decision == "BLOCK"
}

# ═══ 9c. I05: brak break-glass = BLOCK (drugi else-branch) ═══
test_i05_no_break_glass_blocks {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I05_secrets_vault_contract": {"repo_hits": [], "audit_usage": true, "break_glass": false}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.secrets_vault_contract"
	decide.decision == "BLOCK"
}

# ═══ 10. I06: hardening poniżej progu = BLOCK ═══
test_i06_hardening_below_threshold_blocks {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I06_ci_hardening_checklist": {"score_pct": 50, "missing_controls": ["pinning", "cve_scan"]}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.ci_hardening_checklist"
	decide.decision == "BLOCK"
}

# ═══ 10b. I06 granica: dokładnie 75% = nieaktywne (tylko < próg) ═══
test_i06_boundary_at_threshold_inactive {
	decide := v3_p59_security_closure.decide with input as activated_input
	decide.rule_id != "jdg.v3_p59_security_closure.ci_hardening_checklist"
}

# ═══ 10c. I06 z progiem z ADR-002: 80 > próg 60 → nieaktywne ═══
test_i06_threshold_from_adr002 {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I06_ci_hardening_checklist": {"score_pct": 80, "missing_controls": []}})}
	decide := v3_p59_security_closure.decide with input as input
	with data.jdg.thresholds.v3_p59 as {"v3_p59_ci_hardening_min_pct": 60}
	decide.rule_id != "jdg.v3_p59_security_closure.ci_hardening_checklist"
}

# ═══ 11. I07: attestation wymagane a wdrożenie bez provenance = NEEDS_ADVICE ═══
test_i07_missing_attestation_advice {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I07_build_attestation_verification": {"deps_total": 44, "deps_missing_provenance": ["jdg-bundle-v0.9.0"]}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.build_attestation_verification"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 11b. I07: attestation niewymagane → nieaktywne (polityka z ADR-002) ═══
test_i07_attestation_not_required_inactive {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I07_build_attestation_verification": {"deps_total": 44, "deps_missing_provenance": ["X"]}})}
	decide := v3_p59_security_closure.decide with input as input
	with data.jdg.thresholds.v3_p59 as {"v3_p59_attestation_required": false}
	decide.rule_id != "jdg.v3_p59_security_closure.build_attestation_verification"
}

# ═══ 12. I08: niekompletny program = NEEDS_ADVICE ═══
test_i08_incomplete_program_advice {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I08_insider_threat_program": {"elements_missing": ["rotation"], "suspicious_signals": 0}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.insider_threat_program"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 12b. I08: sygnał podejrzany = MANUAL_REVIEW (else-branch) ═══
test_i08_suspicious_signal_review {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I08_insider_threat_program": {"elements_missing": [], "suspicious_signals": 1}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.insider_threat_program"
	decide.decision == "MANUAL_REVIEW"
}

# ═══ 13. I09: brak SBOM = NEEDS_ADVICE ═══
test_i09_no_sbom_advice {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I09_supply_chain_sbom": {"deps_total": 0, "pinned": 0, "sbom_present": false}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.supply_chain_sbom"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 13b. I09: zależności niepinowane = NEEDS_ADVICE (else-branch) ═══
test_i09_unpinned_deps_advice {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I09_supply_chain_sbom": {"deps_total": 3, "pinned": 1, "sbom_present": true}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.supply_chain_sbom"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 14. I10: mało eksperymentów security (< 3) = NEEDS_ADVICE ═══
test_i10_few_experiments_advice {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I10_security_chaos_drills": {"security_experiments": 1, "last_drill": "2026-01-01"}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.security_chaos_drills"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 14b. I10 granica: dokładnie 3 = nieaktywne (tylko < 3) ═══
test_i10_boundary_at_threshold_inactive {
	decide := v3_p59_security_closure.decide with input as activated_input
	decide.rule_id != "jdg.v3_p59_security_closure.security_chaos_drills"
}

# ═══ 15. I11: przejście granicy bez kontrola = BLOCK ═══
test_i11_uncontrolled_flow_blocks {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I11_trust_boundary_map": {"actors_total": 5, "flows_total": 8, "flows_uncontrolled": ["fork_pr→secrets"]}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.trust_boundary_map"
	decide.decision == "BLOCK"
}

# ═══ 16. I12: score poniżej progu = NEEDS_ADVICE ═══
test_i12_score_below_threshold_advice {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I12_security_score_trend": {"score_pct": 60, "trend": "falling"}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.security_score_trend"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 16b. I12 granica: dokładnie 75% = nieaktywne ═══
test_i12_boundary_at_threshold_inactive {
	decide := v3_p59_security_closure.decide with input as activated_input
	decide.rule_id != "jdg.v3_p59_security_closure.security_score_trend"
}

# ═══ 17. ROUTER priorytet: BLOCK (sekret) wygrywa z NEEDS_ADVICE (SBOM) ═══
test_router_block_precedence {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I05_secrets_vault_contract": {"repo_hits": ["x.py:1"], "audit_usage": true, "break_glass": true}, "I09_supply_chain_sbom": {"deps_total": 0, "pinned": 0, "sbom_present": false}})}
	decide := v3_p59_security_closure.decide with input as input
	decide.rule_id == "jdg.v3_p59_security_closure.secrets_vault_contract"
	decide.decision == "BLOCK"
}

# ═══ 18. Werydykty zawsze mają pełny kształt kontraktu (P03) ═══
test_verdict_shape_full_contract {
	decide := v3_p59_security_closure.decide with input as activated_input
	decide.rule_id != ""
	decide["package"] == "jdg.v3_p59_security_closure"
	decide._legal_basis != ""
	decide.valid_from == "2026-01-01"
}

# ═══ 19. Żaden werdykt P59 nigdy nie zwraca AUTO_POST (forteca) ═══
test_no_auto_post_anywhere {
	decide := v3_p59_security_closure.decide with input as activated_input
	decide.decision != "AUTO_POST"
	input2 := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I03_rule_history_hash_chain": {"chain_valid": false, "tamper_detected": false, "tamper_cases": 1}})}
	decide2 := v3_p59_security_closure.decide with input as input2
	decide2.decision != "AUTO_POST"
}

# ═══ 20. Fail-closed wygrywa z BLOCK (brak progów = najpierw NEEDS_ADVICE) ═══
test_fail_closed_precedence {
	input := {"jdg_entrepreneur": {"v3_p59_check": true}, "v3_p59": object.union(full_ctx, {"I05_secrets_vault_contract": {"repo_hits": ["leak"], "audit_usage": true, "break_glass": true}})}
	decide := v3_p59_security_closure.decide with input as input
	with data.jdg.thresholds.v3_p59 as {}
	decide.rule_id == "jdg.v3_p59_security_closure.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
}
