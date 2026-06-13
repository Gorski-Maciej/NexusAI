// ═══════════════════════════════════════════════════════════════════════════════
// PriorityEngine — First-Match-Wins Rule Evaluation (thin wrapper)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Cienki wrapper nad shared pipeline.rs condition.rs.
// Zastępuje dawny rule_engine.rs (340+ linii duplikatu → 60 linii wrappera).
//
// PyO3 pyclass dostępny w Pythonie jako `PriorityEngine`.
// Metody delegują do shared pipeline:
//   - resolve()            → pipeline::evaluate_rules_pipeline()
//   - sort_rules()         → pipeline::sort_rules()
//   - validate_priorities() → pipeline::validate_priorities()
//
// Structured logging: log::info!, log::debug!, log::warn!
// All logs forwarded to Python structlog via pyo3-log (init in lib.rs)
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::exceptions::PyValueError;
use pyo3::prelude::*;
use serde_json::Value;

use crate::engine::pipeline;

// ═══════════════════════════════════════════════════════════════════════════════
// PriorityEngine — first-match-wins rule evaluation
// ═══════════════════════════════════════════════════════════════════════════════

/// Deterministic first-match-wins rule evaluation.
///
/// Python equivalent: `nexus_ai/services/priority_engine.py::PriorityEngine`
///
/// Usage (Python side)::
///
///     engine = PriorityEngine()
///     result_json = engine.resolve(rules_json, context_json)
///     sorted_json = engine.sort_rules(rules_json)
///     warnings_json = engine.validate_priorities(rules_json)
#[pyclass(name = "PriorityEngine")]
pub struct PriorityEngine;

#[pymethods]
impl PriorityEngine {
    /// Evaluate rules (first-match-wins) against a context.
    ///
    /// Uses the shared pipeline and condition evaluator — single source of truth.
    /// Returns the first matching rule's verdict enriched with
    /// ``_rule_id``, ``_priority``, and ``_evaluated_rules``.
    #[staticmethod]
    fn resolve(rules_json: &str, context_json: &str) -> PyResult<String> {
        log::debug!("PriorityEngine.resolve: using shared pipeline");
        let context: serde_json::Map<String, Value> = serde_json::from_str(context_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid context JSON: {e}")))?;
        let rules: Vec<Value> = serde_json::from_str(rules_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid rules JSON: {e}")))?;

        let result = pipeline::evaluate_rules_pipeline(&rules, &context);
        let output = pipeline::eval_result_to_json(&result);
        log::debug!(
            "PriorityEngine.resolve: {} rules, matched={}",
            rules.len(),
            result.matched,
        );
        Ok(serde_json::to_string(&output).expect("infallible json"))
    }

    /// Sort rules deterministically by priority then rule_id.
    #[staticmethod]
    fn sort_rules(rules_json: &str) -> PyResult<String> {
        let mut rules: Vec<Value> = serde_json::from_str(rules_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid rules JSON: {e}")))?;
        pipeline::sort_rules(&mut rules);
        log::debug!("PriorityEngine.sort_rules: sorted {} rules", rules.len());
        Ok(serde_json::to_string(&rules).expect("infallible json"))
    }

    /// Validate rule priorities for conflicts.
    #[staticmethod]
    fn validate_priorities(rules_json: &str) -> PyResult<String> {
        let rules: Vec<Value> = serde_json::from_str(rules_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid rules JSON: {e}")))?;
        let warnings = pipeline::validate_priorities(&rules);
        log::debug!(
            "PriorityEngine.validate_priorities: {} rules, {} conflicts",
            rules.len(),
            warnings.len(),
        );
        Ok(serde_json::to_string(&warnings).expect("infallible json"))
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Module registration
// ═══════════════════════════════════════════════════════════════════════════════

pub fn register(module: &Bound<'_, PyModule>) -> PyResult<()> {
    module.add_class::<PriorityEngine>()?;
    log::info!(
        "priority_engine: registered PriorityEngine (thin wrapper over shared pipeline)"
    );
    Ok(())
}
