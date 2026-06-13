// ═══════════════════════════════════════════════════════════════════════════════
// RulesEngine — Comprehensive Rule Evaluation Pipeline (thin wrapper)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Cienki wrapper nad shared pipeline/condition.
// Zastępuje dawny rules_engine.rs (480+ linii duplikatu → 280 linii wrappera).
//
// Zachowuje API:
//   - evaluate()        → pipeline::evaluate_rules_pipeline()
//   - batch_evaluate()  → pipeline::evaluate_single() per context
//   - validate()        → pipeline::validate_rules_format() + validate_priorities()
//   - sort_rules()      → pipeline::sort_rules()
//
// Structured logging: log::info!, log::debug!, log::warn!
// All logs forwarded to Python structlog via pyo3-log (init in lib.rs)
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::exceptions::PyValueError;
use pyo3::prelude::*;
use rayon::prelude::*;
use serde_json::{json, Value};

use crate::engine::pipeline;

// ═══════════════════════════════════════════════════════════════════════════════
// RulesEngine — comprehensive pyclass for rule evaluation
// ═══════════════════════════════════════════════════════════════════════════════

/// Comprehensive rule evaluation pipeline with first-match-wins semantics.
///
/// Self-contained SQL condition evaluator (shared — single source of truth).
/// Supports `=`, `<`, `>`, `IN`, `AND`, and parenthesized expressions.
/// All values are compared as strings (compatible with DuckDB context format).
///
/// Usage (Python side)::
///
///     engine = RulesEngine()
///
///     # Single context evaluation
///     result = engine.evaluate(rules_json, context_json)
///     # → dict with matched, verdict, rule_id, priority, evaluated_rules_json
///
///     # Batch evaluation (multi-tenancy)
///     results = engine.batch_evaluate(rules_json, contexts_json)
///     # → list of result dicts
///
///     # Validation
///     warnings = engine.validate(rules_json)
///     # → dict with valid, rule_count, errors, warnings
///
///     # Sorting
///     sorted_rules = engine.sort_rules(rules_json)
///     # → sorted JSON array
#[pyclass(name = "RulesEngine")]
pub struct RulesEngine;

#[pymethods]
impl RulesEngine {
    /// Evaluate rules (first-match-wins) against a single context.
    ///
    /// Runs the full rule evaluation pipeline:
    ///   1. Parse rules JSON (validate format)
    ///   2. Parse context JSON
    ///   3. Iterate rules in provided order (priority-sorted expected)
    ///   4. Evaluate each condition via shared SQL evaluator (condition.rs)
    ///   5. Return first match with enriched verdict
    ///
    /// Args:
    ///     rules_json: JSON array of rule objects:
    ///         [{"rule_id": str, "condition_sql": str, "action_json": str, "priority": int}, ...]
    ///     context_json: JSON object with flat string-valued context:
    ///         {"category_code": "FUEL", "vendor_country": "PL", ...}
    ///
    /// Returns:
    ///     JSON string with:
    ///         - matched: bool
    ///         - verdict: dict (enriched action_json + _rule_id + _priority + _evaluated_rules)
    ///         - rule_id: str (matched rule, empty if no match)
    ///         - priority: int (matched priority, 0 if no match)
    ///         - evaluated_rules_json: str (JSON array of all evaluated rules)
    ///         - error: str (error message if no match, empty otherwise)
    #[staticmethod]
    fn evaluate(rules_json: &str, context_json: &str) -> PyResult<String> {
        log::info!("RulesEngine.evaluate: starting first-match-wins pipeline");

        let context: serde_json::Map<String, Value> = serde_json::from_str(context_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid context JSON: {e}")))?;

        let rules: Vec<Value> = serde_json::from_str(rules_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid rules JSON: {e}")))?;

        if rules.is_empty() {
            log::warn!("RulesEngine.evaluate: empty rules list");
            return Ok(serde_json::to_string(&json!({
                "matched": false,
                "verdict": {},
                "rule_id": "",
                "priority": 0,
                "evaluated_rules_json": "[]",
                "error": "Empty rules list — no rules to evaluate",
            }))
            .expect("infallible json"));
        }

        let result = pipeline::evaluate_rules_pipeline(&rules, &context);
        let output = pipeline::eval_result_to_json(&result);

        log::info!(
            "RulesEngine.evaluate: {} rules, matched={}, rule_id={}",
            rules.len(),
            result.matched,
            if result.matched { &result.rule_id } else { "(none)" },
        );

        Ok(serde_json::to_string(&output).expect("infallible json"))
    }

    /// Evaluate rules against MULTIPLE contexts (batch mode).
    ///
    /// Reuses the same rules JSON for all contexts — useful for
    /// multi-tenancy or batch processing of similar invoices.
    ///
    /// Args:
    ///     rules_json: JSON array of rule objects (same format as ``evaluate``).
    ///     contexts_json: JSON array of context objects:
    ///         [{"category_code": "FUEL", ...}, {"category_code": "FOOD", ...}, ...]
    ///
    /// Returns:
    ///     JSON array of result objects (one per context), in the same order.
    ///     Each result has the same structure as ``evaluate()`` response.
    #[staticmethod]
    fn batch_evaluate(rules_json: &str, contexts_json: &str) -> PyResult<String> {
        log::info!("RulesEngine.batch_evaluate: starting batch evaluation (rayon parallel)");

        let rules: Vec<Value> = serde_json::from_str(rules_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid rules JSON: {e}")))?;

        let contexts: Vec<Value> = serde_json::from_str(contexts_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid contexts JSON: {e}")))?;

        let context_count = contexts.len();
        let rule_count = rules.len();

        // Parallel evaluation: rayon par_iter with indexed map
        let results: Vec<Value> = contexts
            .par_iter()
            .enumerate()
            .map(|(i, ctx_val)| {
                let context = match ctx_val.as_object() {
                    Some(o) => o.clone(),
                    None => {
                        log::warn!(
                            "RulesEngine.batch_evaluate: context {} is not an object",
                            i
                        );
                        return json!({
                            "matched": false,
                            "verdict": {},
                            "rule_id": "",
                            "priority": 0,
                            "evaluated_rules_json": "[]",
                            "error": format!("Context {} is not a JSON object", i),
                        });
                    }
                };

                let result = pipeline::evaluate_single(&rules, &context);
                pipeline::eval_result_to_json(&result)
            })
            .collect();

        log::info!(
            "RulesEngine.batch_evaluate (rayon): {} contexts, {} rules, {} results",
            context_count,
            rule_count,
            results.len(),
        );

        Ok(serde_json::to_string(&results).expect("infallible json"))
    }

    /// Validate rules format and detect priority conflicts.
    ///
    /// Args:
    ///     rules_json: JSON array of rule objects (same format as ``evaluate``).
    ///
    /// Returns:
    ///     JSON string with:
    ///         - valid: bool
    ///         - rule_count: int
    ///         - warnings: list of conflict warnings (empty if valid)
    ///         - errors: list of structural errors (empty if all valid)
    #[staticmethod]
    fn validate(rules_json: &str) -> PyResult<String> {
        log::debug!("RulesEngine.validate: validating rules");

        let rules: Vec<Value> = serde_json::from_str(rules_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid rules JSON: {e}")))?;

        // Use shared pipeline::validate_rules_format for structural validation
        let format_result = pipeline::validate_rules_format(&rules);
        let errors: Vec<String> = match format_result {
            Ok(()) => Vec::new(),
            Err(e) => e,
        };

        let warnings = if errors.is_empty() {
            pipeline::validate_priorities(&rules)
        } else {
            Vec::new()
        };

        log::info!(
            "RulesEngine.validate: {} rules, {} errors, {} warnings",
            rules.len(),
            errors.len(),
            warnings.len(),
        );

        let output = json!({
            "valid": errors.is_empty(),
            "rule_count": rules.len(),
            "errors": errors,
            "warnings": warnings,
        });
        Ok(serde_json::to_string(&output).expect("infallible json"))
    }

    /// Sort rules deterministically by priority then rule_id.
    ///
    /// Sorting order:
    ///   1. priority ASC (lower = higher priority, evaluated first)
    ///   2. rule_id ASC (stable tie-breaker for equal priorities)
    ///
    /// Args:
    ///     rules_json: JSON array of rule objects (same format as ``evaluate``).
    ///
    /// Returns:
    ///     JSON array of rules sorted by (priority ASC, rule_id ASC).
    #[staticmethod]
    fn sort_rules(rules_json: &str) -> PyResult<String> {
        let mut rules: Vec<Value> = serde_json::from_str(rules_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid rules JSON: {e}")))?;

        pipeline::sort_rules(&mut rules);
        log::debug!("RulesEngine.sort_rules: sorted {} rules", rules.len());
        Ok(serde_json::to_string(&rules).expect("infallible json"))
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Module registration
// ═══════════════════════════════════════════════════════════════════════════════

pub fn register(module: &Bound<'_, PyModule>) -> PyResult<()> {
    module.add_class::<RulesEngine>()?;
    log::info!("rules_engine: registered RulesEngine (thin wrapper over shared pipeline)");
    Ok(())
}
