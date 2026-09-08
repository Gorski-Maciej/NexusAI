# ═══════════════════════════════════════════════════════════════════════════════
# TESTY NATYWNE — V3-P33 WARSTWA AI ENTERPRISE (jdg.v3_p33_neural_mesh_ai)
# — kampania V3 FORTRESS.
# Pokrycie: 12 analiz I01-I12 — ścieżki fail-closed (BLOCK_AND_ALERT),
# TRIAGE_QUEUE i SUGGEST + brak aktywacji (no_match) + granice progów
# (red-team kategorie, mesh k-anonymity, cost governor, percentile predictor).
# Uruchomienie (z katalogu repo):
#   ./bin/opa test JDG/tests/rego/test_v3_p33_neural_mesh_ai_enterprise.rego \
#       JDG/rules/v3_p33_neural_mesh_ai_enterprise.rego \
#       JDG/rules/thresholds_jdg.rego
#   ./bin/opa19 test --v0-compatible <te same pliki>
# ═══════════════════════════════════════════════════════════════════════════════
package test_jdg_v3_p33

import future.keywords.in
import data.jdg.v3_p33_neural_mesh_ai

_base := {"jdg_entrepreneur": {"v3_p33_check": true}}

_cases := {
    # I01: AI proposal pipeline
    "pp_bypass": {"analysis": "ai_proposal_pipeline",
                  "ai_proposal_pipeline": {"events": [
                      {"id": "P1", "stage_reached": "syntax_validate", "promoted": true},
                      {"id": "P2", "stage_reached": "shadow", "promoted": true}]}},
    "pp_no_golden": {"analysis": "ai_proposal_pipeline",
                     "ai_proposal_pipeline": {"events": [
                         {"id": "P1", "stage_reached": "shadow", "promoted": false,
                          "golden_replay_pass": false}]}},
    "pp_ok": {"analysis": "ai_proposal_pipeline",
              "ai_proposal_pipeline": {"events": [
                  {"id": "P1", "stage_reached": "shadow", "promoted": true,
                   "golden_replay_pass": true}]}},

    # I02: sandbox uprawnień AI
    "sp_self_approval": {"analysis": "ai_sandbox_permissions",
                         "ai_sandbox_permissions": {"sandbox_write_attempts": 0,
                                                    "ai_self_approvals": 1}},
    "sp_prod_write": {"analysis": "ai_sandbox_permissions",
                      "sandbox_prod_write_detected": true,
                      "ai_sandbox_permissions": {"sandbox_write_attempts": 2,
                                                 "ai_self_approvals": 0}},
    "sp_sandbox_writes": {"analysis": "ai_sandbox_permissions",
                          "ai_sandbox_permissions": {"sandbox_write_attempts": 3,
                                                     "ai_self_approvals": 0,
                                                     "mode": "read_only"}},
    "sp_ok": {"analysis": "ai_sandbox_permissions",
              "ai_sandbox_permissions": {"sandbox_write_attempts": 0,
                                         "ai_self_approvals": 0,
                                         "mode": "read_only"}},

    # I03: halucynacja prawna guard
    "hg_unverified": {"analysis": "legal_hallucination_guard",
                      "legal_hallucination_guard": {"cited_basis": [
                          {"basis": "UoR art. 4", "isap_verification_hash": ""},
                          {"basis": "VAT art. 86", "isap_verification_hash": "sha256:abc"}]}},
    "hg_crawler_down": {"analysis": "legal_hallucination_guard",
                        "isap_crawler_unavailable": true,
                        "legal_hallucination_guard": {"cited_basis": []}},
    "hg_ok": {"analysis": "legal_hallucination_guard",
              "legal_hallucination_guard": {"cited_basis": [
                  {"basis": "UoR art. 4", "isap_verification_hash": "sha256:abc"}]}},

    # I04: prompt audit ledger (WORM)
    "pl_checksum": {"analysis": "prompt_audit_ledger",
                    "prompt_audit_ledger": {"sessions_total": 5, "unlogged_sessions": 0,
                                            "checksum_mismatches": 1}},
    "pl_unlogged": {"analysis": "prompt_audit_ledger",
                    "prompt_audit_ledger": {"sessions_total": 5, "unlogged_sessions": 2,
                                            "checksum_mismatches": 0}},
    "pl_no_ledger": {"analysis": "prompt_audit_ledger",
                     "ai_sessions_ran": true,
                     "prompt_audit_ledger": {"sessions_total": 0, "unlogged_sessions": 0,
                                             "checksum_mismatches": 0}},
    "pl_ok": {"analysis": "prompt_audit_ledger",
              "prompt_audit_ledger": {"sessions_total": 12, "unlogged_sessions": 0,
                                      "checksum_mismatches": 0}},

    # I05: red-team prompt suite
    "rt_weak": {"analysis": "red_team_prompt_suite",
                "red_team_prompt_suite": {"weak_attacks": ["injection"],
                                          "attacks_tested": ["injection", "jailbreak", "exfiltration"]}},
    "rt_not_run": {"analysis": "red_team_prompt_suite",
                   "red_team_prompt_suite": {"weak_attacks": [], "attacks_tested": [],
                                             "suite_not_run": true}},
    "rt_too_few": {"analysis": "red_team_prompt_suite",
                   "red_team_prompt_suite": {"weak_attacks": [], "attacks_tested": ["injection"],
                                             "suite_not_run": false}},
    "rt_ok": {"analysis": "red_team_prompt_suite",
              "red_team_prompt_suite": {"weak_attacks": [],
                                        "attacks_tested": ["injection", "jailbreak", "exfiltration"],
                                        "suite_not_run": false}},

    # I06: trust score jako telemetria
    "ts_no_gate": {"analysis": "trust_score_telemetry",
                   "trust_score_telemetry": {"trust_influenced_decisions": 0,
                                             "auto_post_without_ai_gate": 2}},
    "ts_decides": {"analysis": "trust_score_telemetry",
                   "trust_score_telemetry": {"trust_influenced_decisions": 1,
                                             "auto_post_without_ai_gate": 0}},
    "ts_ok": {"analysis": "trust_score_telemetry",
              "trust_score_telemetry": {"trust_influenced_decisions": 0,
                                        "auto_post_without_ai_gate": 0}},

    # I07: digital twin na danych syntetycznych
    "tw_real_pii": {"analysis": "digital_twin_synthetic",
                    "digital_twin_synthetic": {"real_pii_in_twin": 3, "rule_changes_simulated": 4}},
    "tw_no_sim": {"analysis": "digital_twin_synthetic",
                  "twin_simulation_requested": true,
                  "digital_twin_synthetic": {"real_pii_in_twin": 0, "rule_changes_simulated": 0}},
    "tw_ok": {"analysis": "digital_twin_synthetic",
              "digital_twin_synthetic": {"real_pii_in_twin": 0, "rule_changes_simulated": 5}},

    # I08: cost governor
    "cg_tokens": {"analysis": "cost_governor",
                  "cost_governor": {"tokens_used": 1000001, "cost_pln": 0}},
    "cg_cost": {"analysis": "cost_governor",
                "cost_governor": {"tokens_used": 10, "cost_pln": 500.01}},
    "cg_ok": {"analysis": "cost_governor",
              "cost_governor": {"tokens_used": 500000, "cost_pln": 120}},

    # I09: explain-first UI
    "ef_unexplained": {"analysis": "explain_first_ui",
                       "explain_first_ui": {"suggestions": [
                           {"id": "S1", "legal_reference": "", "evidence": "",
                            "confidence_percentile": 90},
                           {"id": "S2", "legal_reference": "VAT art. 86", "evidence": "ev-1",
                            "confidence_percentile": 92}]}},
    "ef_no_pct": {"analysis": "explain_first_ui",
                  "explain_first_ui": {"suggestions": [
                      {"id": "S1", "legal_reference": "VAT art. 86", "evidence": "ev-1",
                       "confidence_percentile": -1}]}},
    "ef_ok": {"analysis": "explain_first_ui",
              "explain_first_ui": {"suggestions": [
                  {"id": "S1", "legal_reference": "VAT art. 86", "evidence": "ev-1",
                   "confidence_percentile": 90}]}},

    # I10: federated privacy guard
    "fp_pii": {"analysis": "federated_privacy_guard",
               "federated_privacy_guard": {"pii_in_mesh": 1, "aggregates_below_k": 0}},
    "fp_k_violations": {"analysis": "federated_privacy_guard",
                        "federated_privacy_guard": {"pii_in_mesh": 0, "aggregates_below_k": 2}},
    "fp_k_triage": {"analysis": "federated_privacy_guard",
                    "federated_privacy_guard": {"pii_in_mesh": 0, "aggregates_below_k": 1}},
    "fp_ok": {"analysis": "federated_privacy_guard",
              "federated_privacy_guard": {"pii_in_mesh": 0, "aggregates_below_k": 0}},

    # I11: quantum-safe plan
    "qs_missing": {"analysis": "quantum_safe_plan",
                   "quantum_plan_missing": true,
                   "quantum_safe_plan": {"key_types_without_plan": [], "migration_year": 2030}},
    "qs_unplanned_keys": {"analysis": "quantum_safe_plan",
                          "quantum_safe_plan": {"key_types_without_plan": ["tls_roots"],
                                                "migration_year": 2030}},
    "qs_year_diff": {"analysis": "quantum_safe_plan",
                     "quantum_safe_plan": {"key_types_without_plan": [], "migration_year": 2035}},
    "qs_ok": {"analysis": "quantum_safe_plan",
              "quantum_safe_plan": {"key_types_without_plan": [], "migration_year": 2030}},

    # I12: AI w triage NEEDS_ADVICE
    "jd_autonomous": {"analysis": "ai_triage_needs_advice",
                      "ai_triage_needs_advice": {"predictor_autonomous_decisions": 1,
                                                 "queue_unsorted": 0}},
    "jd_unsorted": {"analysis": "ai_triage_needs_advice",
                    "ai_triage_needs_advice": {"predictor_autonomous_decisions": 0,
                                               "queue_unsorted": 7}},
    "jd_ok": {"analysis": "ai_triage_needs_advice",
              "ai_triage_needs_advice": {"predictor_autonomous_decisions": 0,
                                         "queue_unsorted": 0}},
}

_decide(case) = d {
    d := v3_p33_neural_mesh_ai.decide with input as object.union(_base, {"v3_p33": _cases[case]})
}

# ── Oczekiwane routingi (fail-closed: BLOCK > TRIAGE > SUGGEST) ───────────────
expected := {
    "pp_bypass": "BLOCK_AND_ALERT", "pp_no_golden": "TRIAGE_QUEUE", "pp_ok": "SUGGEST",
    "sp_self_approval": "BLOCK_AND_ALERT", "sp_prod_write": "BLOCK_AND_ALERT",
    "sp_sandbox_writes": "TRIAGE_QUEUE", "sp_ok": "SUGGEST",
    "hg_unverified": "BLOCK_AND_ALERT", "hg_crawler_down": "TRIAGE_QUEUE", "hg_ok": "SUGGEST",
    "pl_checksum": "BLOCK_AND_ALERT", "pl_unlogged": "BLOCK_AND_ALERT",
    "pl_no_ledger": "TRIAGE_QUEUE", "pl_ok": "SUGGEST",
    "rt_weak": "BLOCK_AND_ALERT", "rt_not_run": "TRIAGE_QUEUE",
    "rt_too_few": "TRIAGE_QUEUE", "rt_ok": "SUGGEST",
    "ts_no_gate": "BLOCK_AND_ALERT", "ts_decides": "BLOCK_AND_ALERT", "ts_ok": "SUGGEST",
    "tw_real_pii": "BLOCK_AND_ALERT", "tw_no_sim": "TRIAGE_QUEUE", "tw_ok": "SUGGEST",
    "cg_tokens": "TRIAGE_QUEUE", "cg_cost": "TRIAGE_QUEUE", "cg_ok": "SUGGEST",
    "ef_unexplained": "BLOCK_AND_ALERT", "ef_no_pct": "TRIAGE_QUEUE", "ef_ok": "SUGGEST",
    "fp_pii": "BLOCK_AND_ALERT", "fp_k_violations": "TRIAGE_QUEUE",
    "fp_k_triage": "TRIAGE_QUEUE", "fp_ok": "SUGGEST",
    "qs_missing": "BLOCK_AND_ALERT", "qs_unplanned_keys": "TRIAGE_QUEUE",
    "qs_year_diff": "TRIAGE_QUEUE", "qs_ok": "SUGGEST",
    "jd_autonomous": "BLOCK_AND_ALERT", "jd_unsorted": "TRIAGE_QUEUE", "jd_ok": "SUGGEST",
}

# ── Główna asercja: routing każdej ścieżki zgodny z oczekiwanym ───────────────
_routing_violations := {name |
    some name in object.keys(expected)
    expected[name] != _decide(name)._routing
}

test_p33_routing_matrix {
    count(_routing_violations) == 0
}

# ── I01: pipeline — ścieżka awansu z P07 ──────────────────────────────────────
test_p33_i01_bypass_block {
    d := _decide("pp_bypass")
    d.rule_id == "jdg.v3_p33_neural_mesh_ai.ai_proposal_pipeline"
    d._routing == "BLOCK_AND_ALERT"
    d.proposals_bypassed == 1
}

test_p33_i01_ok_suggest {
    d := _decide("pp_ok")
    d._routing == "SUGGEST"
    d.proposals_total == 1
}

# ── I02: sandbox — AI nie może zatwierdzać własnych propozycji (4-eyes) ───────
test_p33_i02_self_approval_block {
    d := _decide("sp_self_approval")
    d.ai_self_approvals == 1
    d._routing == "BLOCK_AND_ALERT"
}

# ── I03: podstawy prawne bez ISAP = BLOCK (zakaz fikcyjnych artykułów) ────────
test_p33_i03_unverified_basis_block {
    d := _decide("hg_unverified")
    d.cited_basis_unverified == 1
    d._routing == "BLOCK_AND_ALERT"
}

# ── I04: WORM ledger — integrity = BLOCK, brak ledgera = BLOCK ────────────────
test_p33_i04_checksum_mismatch_block {
    d := _decide("pl_checksum")
    d._routing == "BLOCK_AND_ALERT"
}

test_p33_i04_unlogged_block {
    d := _decide("pl_unlogged")
    d._routing == "BLOCK_AND_ALERT"
}

# ── I05: red-team — słabość = BLOCK (blokuje merge) ───────────────────────────
test_p33_i05_weak_attack_block {
    d := _decide("rt_weak")
    d.weak_attacks == 1
    d._routing == "BLOCK_AND_ALERT"
}

# ── I06: trust score odcięty od AUTO_POST (inwariant P04) ─────────────────────
test_p33_i06_no_gate_block {
    d := _decide("ts_no_gate")
    d.auto_post_without_ai_gate == 2
    d._routing == "BLOCK_AND_ALERT"
}

test_p33_i06_decides_block {
    d := _decide("ts_decides")
    d._routing == "BLOCK_AND_ALERT"
}

# ── I07: twin — PII w twin = BLOCK (RODO by design) ───────────────────────────
test_p33_i07_real_pii_block {
    d := _decide("tw_real_pii")
    d._routing == "BLOCK_AND_ALERT"
}

# ── I08: cost governor — przekroczenie budżetu = TRIAGE (degradacja, nie block) ─
test_p33_i08_token_budget_triage {
    d := _decide("cg_tokens")
    d._routing == "TRIAGE_QUEUE"
    d.tokens_used == 1000001
    d.token_budget == 1000000
}

test_p33_i08_cost_limit_triage {
    d := _decide("cg_cost")
    d._routing == "TRIAGE_QUEUE"
}

# ── I09: explain-first — brak wyjaśnienia = BLOCK (AI Act przejrzystość) ──────
test_p33_i09_unexplained_block {
    d := _decide("ef_unexplained")
    d.suggestions_unexplained == 1
    d._routing == "BLOCK_AND_ALERT"
}

# ── I10: mesh — PII = BLOCK; agregaty poniżej k = TRIAGE (limit 0) ─────────
test_p33_i10_pii_block {
    d := _decide("fp_pii")
    d._routing == "BLOCK_AND_ALERT"
}

test_p33_i10_k_violations_triage {
    d := _decide("fp_k_violations")
    d.aggregates_below_k == 2
    d._routing == "TRIAGE_QUEUE"
}

test_p33_i10_k_triage_boundary {
    d := _decide("fp_k_triage")
    d._routing == "TRIAGE_QUEUE"
    d.min_k == 5
}

# ── I11: quantum-safe — brak planu = BLOCK ────────────────────────────────────
test_p33_i11_missing_plan_block {
    d := _decide("qs_missing")
    d._routing == "BLOCK_AND_ALERT"
}

# ── I12: predictor — decyzja autonomiczna = BLOCK (AI tylko advisory) ─────────
test_p33_i12_autonomous_block {
    d := _decide("jd_autonomous")
    d.predictor_autonomous_decisions == 1
    d._routing == "BLOCK_AND_ALERT"
}

# ── Certyfikat werdyktu zgodny z kontraktem P03 ────────────────────────────────
test_p33_certificate_fields {
    d := _decide("pp_ok")
    d.matched == true
    d["package"] == "jdg.v3_p33_neural_mesh_ai"
    d.priority == 433001
    d.threshold_version == "ai-enterprise-v3p33-2026.09"
    d.legal_basis_version == "ai-enterprise-legal-2026.09"
    d.valid_from == "2026-01-01"
}

# ── Brak aktywacji: no_match (nie aktywny bez flagi) ──────────────────────────
test_p33_no_match_without_flag {
    d := v3_p33_neural_mesh_ai.decide with input as {"v3_p33": _cases["pp_ok"]}
    d.matched == false
    d.rule_id == "jdg.v3_p33_neural_mesh_ai.no_match"
}

# ── Fail-closed: brak snapshotu progów = BLOCK ────────────────────────────────
test_p33_fail_closed_no_snapshot {
    d := v3_p33_neural_mesh_ai.decide with input as object.union(_base, {"v3_p33": _cases["pp_ok"]}) with data.jdg.thresholds.v3_p33 as {}
    d.rule_id == "jdg.v3_p33_neural_mesh_ai.thresholds_missing"
    d._routing == "BLOCK_AND_ALERT"
}

# ── Parametry jako dane (ADR-002) — progi czytane z snapshotu ─────────────────
test_p33_thresholds_snapshot_complete {
    s := data.jdg.thresholds.v3_p33
    s.v3_p33_token_budget == 1000000
    s.v3_p33_cost_limit_pln == 500
    s.v3_p33_mesh_min_k == 5
    s.v3_p33_judgment_min_percentile == 80
    s.v3_p33_red_team_min_categories == 3
    s.v3_p33_quantum_migration_year == 2030
    s.v3_p33_ai_gate_required == true
    s.v3_p33_twin_synthetic_only == true
    s.v3_p33_isap_verification_required == true
    s.v3_p33_prompt_ledger_worm == true
    s.v3_p33_explanation_required == true
    s.v3_p33_mesh_aggregates_only == true
    count(s.v3_p33_pipeline_stages) == 6
    s.v3_p33_pipeline_stages[0] == "llm_output"
    s.v3_p33_pipeline_stages[5] == "shadow"
}

# ── Każdy routing decyzyjny ma niepusty reason (audytowalność) ────────────────
_reason_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    count(d._routing_reason) <= 10
}

test_p33_routing_reasons_present {
    count(_reason_violations) == 0
}

# ── _legal_basis w każdej decyzji (proweniencja, 7.1h) ────────────────────────
_basis_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    count(d._legal_basis) == 0
}

test_p33_legal_basis_in_all_decisions {
    count(_basis_violations) == 0
}

# ── Priorytety unikalne per innowacja (433001-433012) ─────────────────────────
_priority_violations := {name |
    some name in object.keys(_cases)
    d := _decide(name)
    d.matched == true
    d.priority != 433001
    d.priority != 433002
    d.priority != 433003
    d.priority != 433004
    d.priority != 433005
    d.priority != 433006
    d.priority != 433007
    d.priority != 433008
    d.priority != 433009
    d.priority != 433010
    d.priority != 433011
    d.priority != 433012
}

test_p33_unique_priorities {
    count(_priority_violations) == 0
}
