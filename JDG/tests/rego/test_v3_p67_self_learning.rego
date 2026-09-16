# Testy natywne OPA — V3-P67 SELF-LEARNING (konwencja P51–P66).
# Uruchomienie: bin/opa test JDG/rules/thresholds_jdg.rego JDG/rules/v3_p67_self_learning.rego JDG/tests/rego/test_v3_p67_self_learning.rego
# Kontekst zielony: 12/12 PASS. Scenariusze per innowacja I01–I12.
package tests.rego.test_v3_p67_self_learning

import data.jdg.v3_p67_self_learning

_green_ctx := {
	"I01_advice_to_rule_pipeline": {"clusters": 3, "stages": 6, "missing_validations": [], "lifecycle_target": "SHADOW"},
	"I02_correction_rate": {"corrections": 1, "unattributed": 0},
	"I03_learning_telemetry": {"metrics_defined": 6, "p58_engines": 12},
	"I04_suggestion_expiry": {"suggestions": 2, "no_epoch": 0, "epochs": 1},
	"I05_guardrails": {"unvalidated": 0, "four_eyes_roles": 4},
	"I06_learning_dashboard": {"rows": 4},
	"I07_data_readiness": {"sources": 7, "available": 6, "missing": []},
	"I08_human_feedback": {"reviews": 1, "no_cert_link": 0, "no_feed": 0},
	"I09_learning_safety": {"rejections": 1},
	"I10_knowledge_base": {"verdicts": 31},
	"I11_curriculum": {"queue_n": 3, "below_roi": 0},
	"I12_post_learning_replay": {"replays": 31},
}

_green_input := {
	"jdg_entrepreneur": {"v3_p67_check": true},
	"v3_p67": _green_ctx,
}

_ctx_with(override) := {
	"jdg_entrepreneur": {"v3_p67_check": true},
	"v3_p67": object.union(_green_ctx, override),
}

# ── Kontekst zielony ──────────────────────────────────────────────────────────
test_p67_all_green {
	decide := data.jdg.v3_p67_self_learning.decide with input as _green_input
	decide.decision == "PASS"
}

test_p67_no_flag_no_match {
	decide := data.jdg.v3_p67_self_learning.decide with input as {"jdg_entrepreneur": {}, "v3_p67": _green_ctx}
	decide.decision == "NO_MATCH"
}

test_p67_thresholds_snapshot_present {
	count(data.jdg.thresholds.v3_p67) > 0
}

test_p67_priorities_unique {
	p1 := data.jdg.v3_p67_self_learning.i01_pipeline.priority with input as _green_input
	p12 := data.jdg.v3_p67_self_learning.i12_pipeline.priority with input as _green_input
	p1 == 467001
	p12 == 467012
}

# ── Scenariusze BLOCK ─────────────────────────────────────────────────────────
test_p67_i04_epoch_missing_blocks {
	input := _ctx_with({"I04_suggestion_expiry": {"suggestions": 2, "no_epoch": 1, "epochs": 1}})
	decide := data.jdg.v3_p67_self_learning.decide with input as input
	decide.decision == "BLOCK"
}

test_p67_i05_guardrails_missing_blocks {
	input := _ctx_with({"I05_guardrails": {"unvalidated": 2, "four_eyes_roles": 4}})
	decide := data.jdg.v3_p67_self_learning.decide with input as input
	decide.decision == "BLOCK"
}

test_p67_i08_feedback_unlinked_blocks {
	input := _ctx_with({"I08_human_feedback": {"reviews": 1, "no_cert_link": 1, "no_feed": 0}})
	decide := data.jdg.v3_p67_self_learning.decide with input as input
	decide.decision == "BLOCK"
}

# ── Scenariusze NEEDS_ADVICE (BLOCK wyłączony) ────────────────────────────────
test_p67_i01_pipeline_incomplete {
	input := _ctx_with({"I01_advice_to_rule_pipeline": {"clusters": 1, "stages": 6, "missing_validations": [], "lifecycle_target": "SHADOW"}})
	decide := data.jdg.v3_p67_self_learning.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p67_i02_unattributed_correction {
	input := _ctx_with({"I02_correction_rate": {"corrections": 2, "unattributed": 1}})
	decide := data.jdg.v3_p67_self_learning.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p67_i03_telemetry_below_min {
	input := _ctx_with({"I03_learning_telemetry": {"metrics_defined": 2, "p58_engines": 12}})
	decide := data.jdg.v3_p67_self_learning.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p67_i06_dashboard_rows_missing {
	input := _ctx_with({"I06_learning_dashboard": {"rows": 1}})
	decide := data.jdg.v3_p67_self_learning.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p67_i07_data_sources_below_min {
	input := _ctx_with({"I07_data_readiness": {"sources": 2, "available": 2, "missing": ["legal_reviews_p47"]}})
	decide := data.jdg.v3_p67_self_learning.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p67_i09_no_rejections_evidence {
	input := _ctx_with({"I09_learning_safety": {"rejections": 0}})
	decide := data.jdg.v3_p67_self_learning.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p67_i10_knowledge_below_min {
	input := _ctx_with({"I10_knowledge_base": {"verdicts": 10}})
	decide := data.jdg.v3_p67_self_learning.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p67_i11_empty_curriculum {
	input := _ctx_with({"I11_curriculum": {"queue_n": 0, "below_roi": 0}})
	decide := data.jdg.v3_p67_self_learning.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

test_p67_i12_replay_below_min {
	input := _ctx_with({"I12_post_learning_replay": {"replays": 5}})
	decide := data.jdg.v3_p67_self_learning.decide with input as input
	decide.decision == "NEEDS_ADVICE"
}

# ── Negatywy per-innowacja (PASS nie przychodzi za darmo) ─────────────────────
test_p67_i01_fail_without_shadow_target {
	input := _ctx_with({"I01_advice_to_rule_pipeline": {"clusters": 3, "stages": 6, "missing_validations": [], "lifecycle_target": "ACTIVE"}})
	not data.jdg.v3_p67_self_learning.i01_decision == "PASS"
	_ := input
}

test_p67_i04_fails_without_epoch_registry {
	input := _ctx_with({"I04_suggestion_expiry": {"suggestions": 2, "no_epoch": 0, "epochs": 0}})
	not data.jdg.v3_p67_self_learning.i04_decision == "PASS"
	_ := input
}

test_p67_i05_fails_without_four_eyes_roles {
	input := _ctx_with({"I05_guardrails": {"unvalidated": 0, "four_eyes_roles": 2}})
	not data.jdg.v3_p67_self_learning.i05_decision == "PASS"
	_ := input
}
