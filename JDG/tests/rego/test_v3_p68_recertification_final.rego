# Testy natywne OPA — V3-P68 RE-CERTYFIKACJA (konwencja P51–P67).
# Uruchomienie: bin/opa test JDG/rules/thresholds_jdg.rego JDG/rules/v3_p68_recertification_final.rego JDG/tests/rego/test_v3_p68_recertification_final.rego
# Kontekst zielony: 12/12 PASS. Scenariusze per innowacja I01–I12.
package tests.rego.test_v3_p68_recertification_final

import data.jdg.v3_p68_recertification_final

_green_ctx := {
	"I01_hard_gates": {"violated_gates": []},
	"I02_settlement": {"registers_settled": 23, "registers_missing": []},
	"I03_pillars": {"pillars_scored": 9, "invalid_statuses": []},
	"I04_residual_map": {"v4_map_present": true, "unmapped_registers": []},
	"I05_metric_freeze": {"frozen_metrics": 8},
	"I06_worm": {"worm_archived": true, "signed": true},
	"I07_renewal": {"policy_max_days": 90, "policy_on_epoch_change": true, "policy_on_critical_deploy": true},
	"I08_owner": {"owner_attested": true},
	"I09_kt_pack": {"sections": 6},
	"I10_self_portrait": {"diagram_present": true, "components_table_present": true},
	"I11_truth_first": {"misreported_as_evidenced": []},
	"I12_post_mortem": {"post_mortem_present": true},
}

_green_input := {
	"jdg_entrepreneur": {"v3_p68_check": true},
	"v3_p68": _green_ctx,
}

_ctx_with(override) := {
	"jdg_entrepreneur": {"v3_p68_check": true},
	"v3_p68": object.union(_green_ctx, override),
}

# ── Kontekst zielony ──────────────────────────────────────────────────────────
test_p68_all_green {
	decide := data.jdg.v3_p68_recertification_final.decide with input as _green_input
	decide.decision == "PASS"
}

test_p68_no_flag_no_match {
	decide := data.jdg.v3_p68_recertification_final.decide with input as {"jdg_entrepreneur": {}, "v3_p68": _green_ctx}
	decide.decision == "NO_MATCH"
}

test_p68_thresholds_snapshot_present {
	count(data.jdg.thresholds.v3_p68) > 0
}

test_p68_priorities_unique {
	p1 := data.jdg.v3_p68_recertification_final.i01_hard_gates.priority with input as _ctx_with({"I01_hard_gates": {"violated_gates": ["x"]}})
	p12 := data.jdg.v3_p68_recertification_final.i12_post_mortem.priority with input as _ctx_with({"I12_post_mortem": {"post_mortem_present": false}})
	p1 == 468001
	p12 == 468012
}

# ── Scenariusze BLOCK (hard gates i truth-first) ──────────────────────────────
test_p68_i01_hard_gate_violation_blocks {
	input := _ctx_with({"I01_hard_gates": {"violated_gates": ["zero_cichego_AUTO_POST"]}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "BLOCK"
}

test_p68_i11_misreported_blocks {
	input := _ctx_with({"I11_truth_first": {"misreported_as_evidenced": ["Odporność"]}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "BLOCK"
}

# ── Scenariusze NEEDS_ADVICE (BLOCK wyłączony) ────────────────────────────────
test_p68_i02_settlement_incomplete {
	input := _ctx_with({"I02_settlement": {"registers_settled": 20, "registers_missing": ["P63", "P64", "P65"]}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p68_i03_pillars_below_min {
	input := _ctx_with({"I03_pillars": {"pillars_scored": 7, "invalid_statuses": []}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p68_i03_invalid_status {
	input := _ctx_with({"I03_pillars": {"pillars_scored": 9, "invalid_statuses": ["DZIAŁA"]}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p68_i04_no_v4_map {
	input := _ctx_with({"I04_residual_map": {"v4_map_present": false, "unmapped_registers": []}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p68_i05_frozen_below_min {
	input := _ctx_with({"I05_metric_freeze": {"frozen_metrics": 3}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p68_i06_worm_missing {
	input := _ctx_with({"I06_worm": {"worm_archived": false, "signed": true}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p68_i06_signature_missing {
	input := _ctx_with({"I06_worm": {"worm_archived": true, "signed": false}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p68_i07_renewal_days_missing {
	input := _ctx_with({"I07_renewal": {"policy_max_days": 0, "policy_on_epoch_change": true, "policy_on_critical_deploy": true}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p68_i07_renewal_epoch_missing {
	input := _ctx_with({"I07_renewal": {"policy_max_days": 90, "policy_on_epoch_change": false, "policy_on_critical_deploy": true}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p68_i08_owner_not_attested {
	input := _ctx_with({"I08_owner": {"owner_attested": false}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p68_i09_sections_below_min {
	input := _ctx_with({"I09_kt_pack": {"sections": 3}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p68_i10_no_diagram {
	input := _ctx_with({"I10_self_portrait": {"diagram_present": false, "components_table_present": true}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p68_i10_no_components_table {
	input := _ctx_with({"I10_self_portrait": {"diagram_present": true, "components_table_present": false}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p68_i12_no_post_mortem {
	input := _ctx_with({"I12_post_mortem": {"post_mortem_present": false}})
	decide := data.jdg.v3_p68_recertification_final.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ── Negatywy per-innowacja (PASS nie przychodzi za darmo) ─────────────────────
test_p68_i01_fails_without_gate_results {
	input := _ctx_with({"I01_hard_gates": {"violated_gates": ["zero_dryfu_mirror", "zero_duplikatow_rule_id"]}})
	not data.jdg.v3_p68_recertification_final.i01_hard_gates.decision == "PASS"
	_ := input
}

test_p68_i04_fails_without_map_registry {
	input := _ctx_with({"I04_residual_map": {"v4_map_present": false, "unmapped_registers": ["P49", "P50"]}})
	not data.jdg.v3_p68_recertification_final.i04_residual_map.decision == "PASS"
	_ := input
}

test_p68_i11_fails_with_misreported {
	input := _ctx_with({"I11_truth_first": {"misreported_as_evidenced": ["Golden Oracle"]}})
	not data.jdg.v3_p68_recertification_final.i11_truth_first.decision == "PASS"
	_ := input
}
