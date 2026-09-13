# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — TESTY NATYWNE V3-P56 VAT/PIT SZCZEGÓŁY (konwencja P39/P45–P55:
# negative-first, granice progów, fail-closed, never-silent AUTO_POST, bypass →
# NO_MATCH, determinizm else-chain, place-of-supply / GTU / procedury / art. 23 /
# ryczałt per PKWiU / proporcje art. 90 / interakcje ulg / VAT↔PIT).
# Uruchomienie: opa test (0.68) / opa19 test --v0-compatible (1.9)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.v3_p56_vat_pit_details_test

import data.jdg.v3_p56_vat_pit_details

# ── Fixture: pełny kontekst dowodowy (stan bazowy narzędzi P56) ────────────────
full_ctx := {
	"I01_place_of_supply_pack": {"cases_total": 6, "gaps_nip_ue": []},
	"I02_gtu_classification_data": {"rows_total": 13, "rows_missing_window": []},
	"I03_procedure_markers_engine": {"checks_total": 24, "conflicts": []},
	"I04_kis_interpretation_registry": {"registry_size": 8, "uncovered_topics": []},
	"I05_cost_exclusion_guard": {"costs_total": 40, "excluded_ids": []},
	"I06_ryczalt_table_by_pkwiu": {"rows_total": 42, "rows_missing_window": []},
	"I07_mixed_sales_proportions": {"taxable_turnover": 300000, "exempt_turnover": 100000, "turnover_varies_in_year": false},
	"I08_relief_interaction_matrix": {"reliefs_active": 2, "conflicts": []},
	"I09_non_monetary_income": {"items_total": 2, "unvalued_ids": []},
	"I10_vat_nondeductible_cost_flow": {"items_total": 5, "mismatch_ids": []},
	"I11_suspicious_pattern_advice": {"signals_total": 12, "high_hits": []},
	"I12_detail_coverage_score": {"domains_total": 4, "domains_below_min": []},
}

activated_input := {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": full_ctx}
deactivated_input := {"jdg_entrepreneur": {}, "v3_p56": full_ctx}

# ═══ 1. NEGATIVE-FIRST: brak aktywacji → NO_MATCH (żadnych efektów ubocznych) ═══
test_decide_no_match_without_flag {
	decide := v3_p56_vat_pit_details.decide with input as deactivated_input
	decide.decision == "NO_MATCH"
	decide.matched == false
}

# ═══ 2. FAIL-CLOSED: brak snapshotu progów → NEEDS_ADVICE, nigdy cicho ═══
test_fail_closed_thresholds_missing {
	decide := v3_p56_vat_pit_details.decide with input as activated_input
	with data.jdg.thresholds.v3_p56 as {}
	decide.rule_id == "jdg.v3_p56_vat_pit_details.thresholds_missing"
	decide.decision == "NEEDS_ADVICE"
	decide.priority == 0
}

# ═══ 3. ROUTER: stan bazowy (wszystkie bramki zielone) → all_green PASS ═══
test_router_all_green_pass {
	decide := v3_p56_vat_pit_details.decide with input as activated_input
	decide.rule_id == "jdg.v3_p56_vat_pit_details.all_green"
	decide.decision == "PASS"
}

# ═══ 4. ROUTER determinizm: dwie ewaluacje = ten sam werdykt ═══
test_router_deterministic {
	a := v3_p56_vat_pit_details.decide with input as activated_input
	b := v3_p56_vat_pit_details.decide with input as activated_input
	a == b
}

# ═══ 5. I01: cross-border B2B bez NIP UE → NEEDS_ADVICE (pustynia art. 28b) ═══
test_i01_advises_missing_nip_ue {
	ctx := object.union(full_ctx, {"I01_place_of_supply_pack": {"cases_total": 6, "gaps_nip_ue": ["DE:usluga_konsultingowa"]}})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.rule_id == "jdg.v3_p56_vat_pit_details.place_of_supply"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 6. I02: wiersz GTU bez rocznika/okna → BLOCK (P46 parametry-as-data) ═══
test_i02_blocks_gtu_row_without_window {
	ctx := object.union(full_ctx, {"I02_gtu_classification_data": {"rows_total": 13, "rows_missing_window": ["GTU_07.pkwiu_2019"]}})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.rule_id == "jdg.v3_p56_vat_pit_details.gtu_classification_data"
	decide.decision == "BLOCK"
}

# ═══ 7. I03: niezgodne oznaczenie procedury JPK → BLOCK (fail-closed) ═══
test_i03_blocks_procedure_marker_conflict {
	ctx := object.union(full_ctx, {"I03_procedure_markers_engine": {"checks_total": 24, "conflicts": ["pole_MPP_manual_M_automatic_"]}})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.rule_id == "jdg.v3_p56_vat_pit_details.procedure_markers"
	decide.decision == "BLOCK"
}

# ═══ 8. I04: reguła wysokiego ryzyka bez interpretacji KIS → NEEDS_ADVICE ═══
test_i04_advises_uncovered_high_risk_rule {
	ctx := object.union(full_ctx, {"I04_kis_interpretation_registry": {"registry_size": 8, "uncovered_topics": ["miejsce_swiaadczenia_uslug_elektronicznych"]}})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.rule_id == "jdg.v3_p56_vat_pit_details.kis_interpretation_registry"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 9. I05: koszt w kategorii wyłączonej art. 23 → BLOCK ═══
test_i05_blocks_excluded_cost_category {
	ctx := object.union(full_ctx, {"I05_cost_exclusion_guard": {"costs_total": 40, "excluded_ids": ["KST-0102:reprezentacja"]}})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.rule_id == "jdg.v3_p56_vat_pit_details.cost_exclusion_guard"
	decide.decision == "BLOCK"
}

# ═══ 10. I06: wiersz ryczałtu art. 12 bez okna ważności → BLOCK ═══
test_i06_blocks_ryczalt_row_without_window {
	ctx := object.union(full_ctx, {"I06_ryczalt_table_by_pkwiu": {"rows_total": 42, "rows_missing_window": ["62.01.Z:8.5"]}})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.rule_id == "jdg.v3_p56_vat_pit_details.ryczalt_table_by_pkwiu"
	decide.decision == "BLOCK"
}

# ═══ 11. I07 granica: obroty zmienne w roku → MANUAL_REVIEW (przeliczenie art. 90) ═══
test_i07_reviews_varying_turnover {
	ctx := object.union(full_ctx, {"I07_mixed_sales_proportions": {"taxable_turnover": 300000, "exempt_turnover": 100000, "turnover_varies_in_year": true}})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.rule_id == "jdg.v3_p56_vat_pit_details.mixed_sales_proportions"
	decide.decision == "MANUAL_REVIEW"
}

# ═══ 11b. I07 granica: obroty stabilne → brak przeliczenia kwartalnego (PASS path) ═══
test_i07_stable_turnover_no_review {
	decide := v3_p56_vat_pit_details.decide with input as activated_input
	decide.rule_id != "jdg.v3_p56_vat_pit_details.mixed_sales_proportions"
}

# ═══ 11c. I07 matematyka: proporcja liczona dokładnym ułamkiem (75/25) ═══
test_i07_ratio_exact_fraction {
	ctx := object.union(full_ctx, {"I07_mixed_sales_proportions": {"taxable_turnover": 300000, "exempt_turnover": 100000, "turnover_varies_in_year": true}})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.metrics.ratio_pct == 75.0
}

# ═══ 12. I08: konflikt ulg (IP Box przy ryczałcie) → MANUAL_REVIEW ═══
test_i08_reviews_relief_conflict {
	ctx := object.union(full_ctx, {"I08_relief_interaction_matrix": {"reliefs_active": 2, "conflicts": ["IP_BOX+RYCZALT"]}})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.rule_id == "jdg.v3_p56_vat_pit_details.relief_interaction_matrix"
	decide.decision == "MANUAL_REVIEW"
}

# ═══ 13. I09: przychód nieodpłatny bez wyceny → NEEDS_ADVICE (art. 14 ust. 2 pkt 8) ═══
test_i09_advises_unvalued_non_monetary {
	ctx := object.union(full_ctx, {"I09_non_monetary_income": {"items_total": 2, "unvalued_ids": ["SW-0007:niematerialne_swiaadczenie"]}})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.rule_id == "jdg.v3_p56_vat_pit_details.non_monetary_income"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 14. I10: rozjazd VAT nieodliczony ↔ koszt → BLOCK (spójność VAT↔PIT) ═══
test_i10_blocks_vat_cost_mismatch {
	ctx := object.union(full_ctx, {"I10_vat_nondeductible_cost_flow": {"items_total": 5, "mismatch_ids": ["FV-2026/09/13"]}})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.rule_id == "jdg.v3_p56_vat_pit_details.vat_nondeductible_cost_flow"
	decide.decision == "BLOCK"
}

# ═══ 15. I11: sygnał wysoki (schemat MPP) → NEEDS_ADVICE z powodem (GAAR) ═══
test_i11_advises_high_severity_signal {
	ctx := object.union(full_ctx, {"I11_suspicious_pattern_advice": {"signals_total": 12, "high_hits": ["MPP_SPLIT:4xFV_14_9k"]}})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.rule_id == "jdg.v3_p56_vat_pit_details.suspicious_pattern_advice"
	decide.decision == "NEEDS_ADVICE"
}

# ═══ 16. I12: pokrycie poniżej progu z ADR-002 → MANUAL_REVIEW ═══
test_i12_reviews_below_min_coverage {
	ctx := object.union(full_ctx, {"I12_detail_coverage_score": {"domains_total": 4, "domains_below_min": ["dotacje", "klauzule_ochronne"]}})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.rule_id == "jdg.v3_p56_vat_pit_details.detail_coverage_score"
	decide.decision == "MANUAL_REVIEW"
	decide.metrics.min_coverage_pct == 80
}

# ═══ 17. PRIORYTET: BLOCK wygrywa z NEEDS_ADVICE (router else-chain) ═══
test_router_prefers_block_over_advice {
	ctx := object.union(full_ctx, {
		"I02_gtu_classification_data": {"rows_total": 13, "rows_missing_window": ["GTU_07.pkwiu_2019"]},
		"I09_non_monetary_income": {"items_total": 2, "unvalued_ids": ["SW-0007"]},
	})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.rule_id == "jdg.v3_p56_vat_pit_details.gtu_classification_data"
	decide.decision == "BLOCK"
}

# ═══ 18. HONESTY: reason zawsze niepuste w kluczowych ścieżkach (never-silent, P49) ═══
test_every_decision_has_reason {
	d1 := v3_p56_vat_pit_details.decide with input as activated_input
	d2 := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": object.union(full_ctx, {"I02_gtu_classification_data": {"rows_total": 13, "rows_missing_window": ["x"]}})}
	d3 := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": object.union(full_ctx, {"I09_non_monetary_income": {"items_total": 2, "unvalued_ids": ["y"]}})}
	count(d1.reason) > 0
	count(d2.reason) > 0
	count(d3.reason) > 0
}

# ═══ 19. TEMPORALNOŚĆ: każda decyzja niesie okno valid_from (P05) ═══
test_decisions_carry_validity_window {
	d := v3_p56_vat_pit_details.decide with input as activated_input
	d.valid_from == "2026-01-01"
}

# ═══ 20. DETERMINIZM danych: roczny fixture bez flagi → NO_MATCH nawet z naruszeniami ═══
test_no_side_effects_without_flag_even_with_violations {
	ctx := object.union(full_ctx, {
		"I02_gtu_classification_data": {"rows_total": 13, "rows_missing_window": ["x"]},
		"I10_vat_nondeductible_cost_flow": {"items_total": 5, "mismatch_ids": ["y"]},
	})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {}, "v3_p56": ctx}
	decide.decision == "NO_MATCH"
}

# ═══ 21. I05 granica: zero kosztów wyłączonych → brak BLOCK z I05 ═══
test_i05_empty_exclusions_no_block {
	decide := v3_p56_vat_pit_details.decide with input as activated_input
	decide.rule_id != "jdg.v3_p56_vat_pit_details.cost_exclusion_guard"
}

# ═══ 22. I01 granica: pusty pakiet place-of-supply → brak NEEDS_ADVICE z I01 ═══
test_i01_empty_pack_no_advice {
	ctx := object.union(full_ctx, {"I01_place_of_supply_pack": {"cases_total": 0, "gaps_nip_ue": []}})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.rule_id != "jdg.v3_p56_vat_pit_details.place_of_supply"
}

# ═══ 23. FAIL-CLOSED dane: total=0 w I07 (dzielenie przez zero niemożliwe) ═══
test_i07_zero_total_no_review {
	ctx := object.union(full_ctx, {"I07_mixed_sales_proportions": {"taxable_turnover": 0, "exempt_turnover": 0, "turnover_varies_in_year": true}})
	decide := v3_p56_vat_pit_details.decide with input as {"jdg_entrepreneur": {"v3_p56_check": true}, "v3_p56": ctx}
	decide.rule_id != "jdg.v3_p56_vat_pit_details.mixed_sales_proportions"
}

# ═══ 24. PRIORYTET końcowy: PASS ma priorytet 1 (poniżej wszystkich analiz) ═══
test_all_green_priority_is_lowest {
	decide := v3_p56_vat_pit_details.decide with input as activated_input
	decide.priority == 1
}
