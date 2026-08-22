# NexusAI JDG — ETAP 23 ENTERPRISE AI / NEURAL MESH GOVERNANCE
# Canonical safety layer around existing AI, trust, mesh, cashflow, banking and LLM modules.
# AI produces bounded predictions and explanations; deterministic Rego remains the legal authority.

package jdg.enterprise_ai_neural_etap23

import future.keywords.if
import future.keywords.in

decision_mode := "SUGGEST"


default decide := {
    "matched": false,
    "rule_id": "jdg.enterprise_ai_neural_etap23.no_match",
    "package": "jdg.enterprise_ai_neural_etap23",
    "priority": 999998,
    "decision_mode": "SUGGEST",
    "no_auto_post": true,
}

_thresholds := object.get(object.get(data, "jdg", {}), "thresholds", {})
_et23 := object.get(_thresholds, "enterprise_ai_neural_etap23", {})
registry_version := object.get(_et23, "registry_version", "enterprise-ai-neural-etap23-2026.08")
legal_basis_version := object.get(_et23, "legal_basis_version", "ai-governance-isap-2026.08")
valid_from := object.get(_et23, "valid_from", "2026-01-01")
valid_to := object.get(_et23, "valid_to", null)
calibration_min_samples := object.get(_et23, "calibration_min_samples", 100)
max_expected_calibration_error := object.get(_et23, "max_expected_calibration_error", 0.10)
max_population_stability_index := object.get(_et23, "max_population_stability_index", 0.20)

ai := object.get(input, "enterprise_ai_neural_etap23", {})
activated := object.get(object.get(input, "jdg_entrepreneur", {}), "enterprise_ai_neural_etap23_check", false)
evaluation_date := object.get(ai, "evaluation_date", "")
facts_version := object.get(ai, "facts_version", "")
threshold_version := object.get(ai, "threshold_version", "")
source_refs := object.get(ai, "source_refs", [])
legal_nodes := object.get(ai, "legal_nodes", [])
input_hash := object.get(ai, "input_hash", "")
owner_approval := object.get(ai, "owner_approval", false)

# ── Canonical AI contract ────────────────────────────────────────────────────
context_complete := evaluation_date != "" and facts_version != "" and threshold_version != "" and input_hash != ""
source_complete := count(source_refs) > 0 and count(legal_nodes) > 0

predictions := object.get(ai, "predictions", {})
prediction_separation := object.get(ai, "legal_verdict_control", "") == "DETERMINISTIC_REGO" and
    object.get(ai, "ai_may_decide_legal", true) == false and
    object.get(ai, "prediction_role", "") == "ADVISORY_ONLY"
prediction_evidence := object.get(predictions, "evidence_ref", "") != "" and
    object.get(predictions, "model_version", "") != "" and
    object.get(predictions, "confidence", "") != ""

# ── Calibration, drift and quality monitoring ────────────────────────────────
calibration := object.get(ai, "calibration", {})
calibration_complete := object.get(calibration, "sample_count", 0) >= calibration_min_samples and
    object.get(calibration, "brier_score", "") != "" and
    object.get(calibration, "expected_calibration_error", 1) <= max_expected_calibration_error and
    object.get(calibration, "calibration_ref", "") != ""

drift := object.get(ai, "drift", {})
drift_ok := object.get(drift, "status", "") in ["STABLE", "MONITORED"] and
    object.get(drift, "population_stability_index", 1) <= max_population_stability_index and
    object.get(drift, "baseline_ref", "") != "" and
    object.get(drift, "monitor_ref", "") != ""

quality := object.get(ai, "decision_quality", {})
quality_complete := object.get(quality, "feedback_window_days", 0) > 0 and
    object.get(quality, "outcome_count", 0) > 0 and
    object.get(quality, "quality_ref", "") != ""

# ── Bias, safety and privacy gates ───────────────────────────────────────────
safety := object.get(ai, "safety", {})
bias_safety_complete := object.get(safety, "bias_test_ref", "") != "" and
    object.get(safety, "bias_passed", false) and
    object.get(safety, "prompt_injection_test_ref", "") != "" and
    object.get(safety, "prompt_injection_passed", false) and
    object.get(safety, "pii_redaction_ref", "") != "" and
    object.get(safety, "pii_redaction_passed", false)

# ── Explainability and grounded LLM bridge ───────────────────────────────────
explanation := object.get(ai, "explanation", {})
explainability_complete := object.get(explanation, "rationale_ref", "") != "" and
    object.get(explanation, "feature_attributions", []) != [] and
    object.get(explanation, "provenance_ref", "") != "" and
    object.get(explanation, "explanation_model_version", "") != ""

llm := object.get(ai, "llm", {})
llm_safe := object.get(llm, "explanation_only", false) and
    object.get(llm, "grounded_in_evidence", false) and
    object.get(llm, "prompt_hash", "") != "" and
    object.get(llm, "output_hash", "") != "" and
    object.get(llm, "legal_decision_authority", "") == "DETERMINISTIC_REGO" and
    object.get(llm, "disclaimer_ref", "") != ""

# ── Feedback and domain predictions ──────────────────────────────────────────
feedback := object.get(ai, "feedback", {})
feedback_complete := object.get(feedback, "feedback_version", "") != "" and
    object.get(feedback, "outcome_ref", "") != "" and
    object.get(feedback, "label_policy", "") == "HUMAN_VERIFIED"

cashflow := object.get(ai, "cashflow", {})
cashflow_complete := object.get(cashflow, "forecast_horizon_days", 0) > 0 and
    object.get(cashflow, "forecast_ref", "") != "" and
    object.get(cashflow, "uncertainty_ref", "") != ""

banking := object.get(ai, "banking", {})
banking_complete := object.get(banking, "prediction_ref", "") != "" and
    object.get(banking, "consent_ref", "") != "" and
    object.get(banking, "transaction_authority", "") == "NONE"

# ── Fail-closed meta result ──────────────────────────────────────────────────
all_contracts_complete := context_complete and source_complete and prediction_separation and
    prediction_evidence and calibration_complete and drift_ok and quality_complete and
    bias_safety_complete and explainability_complete and llm_safe and feedback_complete and
    cashflow_complete and banking_complete and owner_approval

manual_review_required := true
hard_block := not all_contracts_complete
routing := "BLOCK_AND_ALERT" if {
    hard_block
} else := "TRIAGE_QUEUE" if {
    manual_review_required
} else := "" if {
    true
}

# ETAP 23 is activated explicitly. A missing contract is represented as a blocked,
# auditable result rather than silently allowing an AI-driven operation.
decide := {
    "matched": true,
    "rule_id": "jdg.enterprise_ai_neural_etap23.governance_verdict",
    "package": "jdg.enterprise_ai_neural_etap23",
    "priority": 23001,
    "stage": "ETAP_23",
    "decision_mode": "SUGGEST",
    "no_auto_post": true,
    "state": "AI_GOVERNANCE_VALIDATED" if {all_contracts_complete} else "AI_GOVERNANCE_BLOCKED",
    "context_complete": context_complete,
    "source_complete": source_complete,
    "prediction_separation": prediction_separation,
    "prediction_evidence": prediction_evidence,
    "calibration_complete": calibration_complete,
    "drift_monitoring_ok": drift_ok,
    "decision_quality_complete": quality_complete,
    "bias_safety_complete": bias_safety_complete,
    "explainability_complete": explainability_complete,
    "llm_explanation_only": llm_safe,
    "feedback_complete": feedback_complete,
    "cashflow_prediction_complete": cashflow_complete,
    "banking_prediction_complete": banking_complete,
    "manual_review_required": manual_review_required,
    "owner_approval": owner_approval,
    "legal_verdict_authority": "DETERMINISTIC_REGO",
    "prediction_role": "ADVISORY_ONLY",
    "prediction_domains": ["adaptive_trust", "neural_mesh", "cashflow", "banking", "legislative"],
    "evidence_chain": {
        "input_hash": input_hash,
        "source_refs": source_refs,
        "legal_nodes": legal_nodes,
        "evaluation_date": evaluation_date,
        "facts_version": facts_version,
        "threshold_version": threshold_version,
        "legal_basis_version": legal_basis_version,
        "registry_version": registry_version,
    },
    "quality_controls": {
        "calibration": calibration_complete,
        "drift": drift_ok,
        "bias_and_safety": bias_safety_complete,
        "feedback": feedback_complete,
        "quality_ref": object.get(quality, "quality_ref", ""),
    },
    "explainability": {
        "rationale_ref": object.get(explanation, "rationale_ref", ""),
        "provenance_ref": object.get(explanation, "provenance_ref", ""),
        "feature_attributions": object.get(explanation, "feature_attributions", []),
    },
    "llm_boundary": {
        "explanation_only": object.get(llm, "explanation_only", false),
        "grounded_in_evidence": object.get(llm, "grounded_in_evidence", false),
        "legal_decision_authority": object.get(llm, "legal_decision_authority", ""),
    },
    "_routing": routing,
    "_routing_reason": "ETAP 23: predykcje AI są advisory-only; brak kalibracji, driftu, safety, evidence lub owner approval blokuje wynik.",
    "_legal_basis": "RODO art. 5; RODO art. 22; RODO art. 25; AI governance/ADR-001; ADR-006; ADR-022; OrdPU art. 4; PIT art. 44; VAT art. 103; PSD2",
    "_warnings": [
        "AI nie podejmuje decyzji prawnej; legal verdict pochodzi wyłącznie z deterministycznego Rego.",
        "Predykcje cashflow, bankowe, trust i neural mesh wymagają kalibracji, drift monitoring i manual review.",
        "Wyjaśnienie LLM jest niewiążące, oparte na evidence i wymaga disclaimeru.",
    ],
    "auto_action": "NONE — MANUAL_REVIEW_REQUIRED",
    "valid_from": valid_from,
    "valid_to": valid_to,
} {
    activated
}
