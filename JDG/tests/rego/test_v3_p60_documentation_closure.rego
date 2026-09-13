package jdg.v3_p60_documentation_closure_test

import data.jdg.v3_p60_documentation_closure

# Pełny kontekst zielony (wszystkie 12 analiz PASS — wartości z silników P60)
full_ctx := {
	"I01_doc_truth_audit": {"pct": 100, "mismatches": []},
	"I02_registry_snippets": {"snippets_total": 6, "missing_snippets": []},
	"I03_frontmatter_binding": {"docs_with_fm": 14, "fm_missing": []},
	"I04_ghost_documents": {"ghosts": []},
	"I05_role_reading_maps": {"maps": ["developer", "operator", "auditor", "entrepreneur"], "missing_roles": []},
	"I06_audit_export_pack": {"export_present": true, "retention_days": 1825},
	"I07_doc_freshness": {"stale_docs": []},
	"I08_holy_docs_protection": {"unprotected": [], "total": 2},
	"I09_examples_as_test": {"examples_total": 14, "untested": []},
	"I10_glossary_enforcement": {"terms_checked": 30, "violations": []},
	"I11_plen_parity": {"parity_pct": 100, "mismatched": []},
	"I12_role_coverage": {"coverage_pct": 100, "roles_without_path": []},
}

activated_input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": full_ctx}
deactivated_input := {"jdg_entrepreneur": {}, "v3_p60": full_ctx}

# ═══ 1. Fail-closed: brak flagi aktywacji → NO_MATCH ═══
test_no_match_without_flag {
	decide := v3_p60_documentation_closure.decide with input as deactivated_input
	decide.decision == "NO_MATCH"
	decide.rule_id == "jdg.v3_p60_documentation_closure.no_match"
}

# ═══ 2. Fail-closed: brak snapshotu progów → NEEDS_ADVICE (precedencja) ═══
test_thresholds_missing_fail_closed {
	decide := v3_p60_documentation_closure.decide with input as activated_input
	with data.jdg.thresholds.v3_p60 as {}
	decide.rule_id == "jdg.v3_p60_documentation_closure.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 3. Kontekst zielony → PASS ═══
test_all_green_pass {
	decide := v3_p60_documentation_closure.decide with input as activated_input
	decide.decision == "PASS"
	decide.rule_id == "jdg.v3_p60_documentation_closure.all_green"
}

# ═══ 4. I01 BLOCK: rozjazd dokument↔rejestr ═══
test_i01_block_on_mismatch {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I01_doc_truth_audit": {"pct": 50, "mismatches": ["README: 57 vs 997"]}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p60_documentation_closure.doc_truth_audit"
}

# ═══ 5. I01 granica: pct poniżej progu = BLOCK ═══
test_i01_block_below_threshold {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I01_doc_truth_audit": {"pct": 94, "mismatches": []}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.decision == "BLOCK"
}

# ═══ 6. I02 BLOCK: brakujące snippety z rejestrów ═══
test_i02_block_on_missing_snippets {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I02_registry_snippets": {"snippets_total": 3, "missing_snippets": ["SNIP-04", "SNIP-05"]}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p60_documentation_closure.registry_snippets"
}

# ═══ 7. I03 BLOCK: dokument bez front-matter ═══
test_i03_block_on_fm_missing {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I03_frontmatter_binding": {"docs_with_fm": 10, "fm_missing": ["docs/FAQ.md"]}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p60_documentation_closure.frontmatter_binding"
}

# ═══ 8. I04 BLOCK: dokument-widmo (artefakt nie istnieje) ═══
test_i04_block_on_ghost {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I04_ghost_documents": {"ghosts": ["docs/X.md -> rules/niema.rego"]}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p60_documentation_closure.ghost_documents"
}

# ═══ 9. I05 NEEDS_ADVICE: rola bez mapy czytania ═══
test_i05_needs_advice_on_missing_role {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I05_role_reading_maps": {"maps": ["developer"], "missing_roles": ["operator", "auditor", "entrepreneur"]}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p60_documentation_closure.role_reading_maps"
}

# ═══ 10. I06 NEEDS_ADVICE: brak eksportu audytowego ═══
test_i06_needs_advice_no_export {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I06_audit_export_pack": {"export_present": false, "retention_days": 1825}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p60_documentation_closure.audit_export_pack"
}

# ═══ 11. I06 NEEDS_ADVICE: retencja poniżej 1825 dni ═══
test_i06_needs_advice_short_retention {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I06_audit_export_pack": {"export_present": true, "retention_days": 365}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 12. I07 NEEDS_ADVICE: dokument przeterminowany ═══
test_i07_needs_advice_stale_doc {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I07_doc_freshness": {"stale_docs": ["docs/FAQ.md (verified 2026-01-01)"]}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p60_documentation_closure.doc_freshness"
}

# ═══ 13. I08 NEEDS_ADVICE: dokument święty bez ochrony ═══
test_i08_needs_advice_unprotected_holy {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I08_holy_docs_protection": {"unprotected": ["docs/WIZJA_OPA_ENTERPRISE_V2.md"], "total": 2}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p60_documentation_closure.holy_docs_protection"
}

# ═══ 14. I09 BLOCK: przykład bez testu ═══
test_i09_block_on_untested_example {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I09_examples_as_test": {"examples_total": 14, "untested": ["docs/FAQ.md -> python3 tools/nexist.py"]}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p60_documentation_closure.examples_as_test"
}

# ═══ 15. I10 NEEDS_ADVICE: naruszenie glosariusza ═══
test_i10_needs_advice_glossary_violation {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I10_glossary_enforcement": {"terms_checked": 30, "violations": ["termin nieobecny: ustawa o VAT"]}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.decision == "NEEDS_ADVICE"
	decide.rule_id == "jdg.v3_p60_documentation_closure.glossary_enforcement"
}

# ═══ 16. I11 BLOCK: dryf PL/EN poniżej progu ═══
test_i11_block_on_plen_drift {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I11_plen_parity": {"parity_pct": 60, "mismatched": ["ADR-016", "ADR-017"]}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p60_documentation_closure.plen_semantic_parity"
}

# ═══ 17. I12 BLOCK: rola bez ścieżki czytania ═══
test_i12_block_on_role_gap {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I12_role_coverage": {"coverage_pct": 75, "roles_without_path": ["entrepreneur"]}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.decision == "BLOCK"
	decide.rule_id == "jdg.v3_p60_documentation_closure.role_coverage"
}

# ═══ 18. Priorytet BLOCK > NEEDS_ADVICE (I01 wygrywa z I05) ═══
test_block_precedence_over_needs_advice {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {
		"I01_doc_truth_audit": {"pct": 50, "mismatches": ["x"]},
		"I05_role_reading_maps": {"maps": [], "missing_roles": ["developer", "operator", "auditor", "entrepreneur"]}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.rule_id == "jdg.v3_p60_documentation_closure.doc_truth_audit"
}

# ═══ 19. Żaden werdykt P60 nigdy nie zwraca AUTO_POST (forteca) ═══
test_no_auto_post_anywhere {
	decide := v3_p60_documentation_closure.decide with input as activated_input
	decide.decision != "AUTO_POST"
	input2 := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I04_ghost_documents": {"ghosts": ["g1"]}})}
	decide2 := v3_p60_documentation_closure.decide with input as input2
	decide2.decision != "AUTO_POST"
}

# ═══ 20. Werdykty zawsze mają pełny kształt kontraktu (P03) ═══
test_verdict_shape_full_contract {
	decide := v3_p60_documentation_closure.decide with input as activated_input
	decide.rule_id != ""
	decide["package"] == "jdg.v3_p60_documentation_closure"
	decide._legal_basis != ""
	decide.valid_from == "2026-01-01"
}

# ═══ 21. Granica progów ADR-002: I11 równy progowi 80 = PASS ═══
test_i11_boundary_equal_threshold_pass {
	input := {"jdg_entrepreneur": {"v3_p60_check": true}, "v3_p60": object.union(full_ctx, {"I11_plen_parity": {"parity_pct": 80, "mismatched": ["ADR-999"]}})}
	decide := v3_p60_documentation_closure.decide with input as input
	decide.decision == "PASS"
}
