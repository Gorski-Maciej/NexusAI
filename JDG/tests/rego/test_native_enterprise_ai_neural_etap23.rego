package jdg.tests.enterprise_ai_neural_etap23

import data.jdg.enterprise_ai_neural_etap23

base_input := {
    "jdg_entrepreneur": {"enterprise_ai_neural_etap23_check": true},
    "enterprise_ai_neural_etap23": {
        "evaluation_date": "2026-08-22",
        "facts_version": "facts-23",
        "threshold_version": "thresholds-23",
        "source_refs": ["source://model-card"],
        "legal_nodes": ["RODO art. 22"],
        "input_hash": "sha256:input",
        "owner_approval": true,
        "legal_verdict_control": "DETERMINISTIC_REGO",
        "ai_may_decide_legal": false,
        "prediction_role": "ADVISORY_ONLY",
        "predictions": {"evidence_ref": "evidence://pred", "model_version": "model-1", "confidence": 0.8},
        "calibration": {"sample_count": 100, "brier_score": 0.08, "expected_calibration_error": 0.05, "calibration_ref": "cal://1"},
        "drift": {"status": "STABLE", "population_stability_index": 0.1, "baseline_ref": "drift://base", "monitor_ref": "drift://1"},
        "decision_quality": {"feedback_window_days": 30, "outcome_count": 100, "quality_ref": "quality://1"},
        "safety": {"bias_test_ref": "safety://bias", "bias_passed": true, "prompt_injection_test_ref": "safety://pi", "prompt_injection_passed": true, "pii_redaction_ref": "safety://pii", "pii_redaction_passed": true},
        "explanation": {"rationale_ref": "explain://rationale", "feature_attributions": ["confidence"], "provenance_ref": "prov://1", "explanation_model_version": "explain-1"},
        "llm": {"explanation_only": true, "grounded_in_evidence": true, "prompt_hash": "sha256:prompt", "output_hash": "sha256:output", "legal_decision_authority": "DETERMINISTIC_REGO", "disclaimer_ref": "disclaimer://1"},
        "feedback": {"feedback_version": "feedback-1", "outcome_ref": "outcome://1", "label_policy": "HUMAN_VERIFIED"},
        "cashflow": {"forecast_horizon_days": 90, "forecast_ref": "cash://1", "uncertainty_ref": "cash://uncertainty"},
        "banking": {"prediction_ref": "bank://1", "consent_ref": "consent://1", "transaction_authority": "NONE"},
    },
}

test_no_match if {
    result := enterprise_ai_neural_etap23.decide with input as {"jdg_entrepreneur": {}}
    result.rule_id == "jdg.enterprise_ai_neural_etap23.no_match"
}

test_missing_contract if {
    result := enterprise_ai_neural_etap23.decide with input as {"jdg_entrepreneur": {"enterprise_ai_neural_etap23_check": true}}
    result._routing == "BLOCK_AND_ALERT"
    result.no_auto_post == true
}

test_prediction_separation if {
    result := enterprise_ai_neural_etap23.decide with input as base_input
    result.legal_verdict_authority == "DETERMINISTIC_REGO"
    result.prediction_separation == true
    result.decision_mode == "SUGGEST"
}

test_quality if {
    result := enterprise_ai_neural_etap23.decide with input as base_input
    result.calibration_complete == true
    result.drift_monitoring_ok == true
    result.decision_quality_complete == true
}

test_safety if {
    result := enterprise_ai_neural_etap23.decide with input as base_input
    result.bias_safety_complete == true
    result.llm_explanation_only == true
    result.banking_prediction_complete == true
}

test_valid if {
    result := enterprise_ai_neural_etap23.decide with input as base_input
    result.state == "AI_GOVERNANCE_VALIDATED"
    result._routing == "TRIAGE_QUEUE"
    result.manual_review_required == true
}
