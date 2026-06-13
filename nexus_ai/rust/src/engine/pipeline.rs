// ═══════════════════════════════════════════════════════════════════════════════
// pipeline — Shared First-Match-Wins Rule Evaluation Pipeline
// ═══════════════════════════════════════════════════════════════════════════════
//
// JEDNO źródło prawdy dla first-match-wins evaluation w całym projekcie.
// Wyodrębnione z rule_engine.rs i rules_engine.rs aby wyeliminować duplikację.
//
// Używa condition.rs jako JEDYNEGO źródła prawdy dla SQL evaluatora.
//
// Komponenty:
//   RuleEvaluation — struktura wyniku pojedynczej reguły
//   EvalResult — struktura wyniku całego pipeline'u
//   evaluate_rules_pipeline() — główna funkcja first-match-wins
//   evaluate_single() — helper dla batch_evaluate
//
// Structured logging: log::info!, log::debug!, log::warn!
// All logs forwarded to Python structlog via pyo3-log (init in lib.rs)
// ═══════════════════════════════════════════════════════════════════════════════

use serde_json::{json, Value};

use crate::engine::condition;

// ═══════════════════════════════════════════════════════════════════════════════
// Types
// ═══════════════════════════════════════════════════════════════════════════════

/// Result of evaluating a single rule.
#[derive(Debug, Clone)]
pub struct RuleEvaluation {
    pub rule_id: String,
    pub condition_sql: String,
    pub matched: bool,
    pub selected: bool,
}

/// Full result of the first-match-wins evaluation pipeline.
#[derive(Debug, Clone)]
pub struct EvalResult {
    pub matched: bool,
    pub rule_id: String,
    pub priority: i64,
    pub verdict: Value,
    pub evaluated_rules: Vec<RuleEvaluation>,
    pub error: String,
}

/// Serialize evaluated rules to JSON array.
pub fn evaluated_rules_to_json(rules: &[RuleEvaluation]) -> Value {
    Value::Array(
        rules
            .iter()
            .map(|e| {
                json!({
                    "rule_id": e.rule_id,
                    "condition_sql": e.condition_sql,
                    "result": e.matched,
                    "selected": e.selected,
                })
            })
            .collect(),
    )
}

/// Serialize EvalResult to a JSON object matching the Python API contract.
pub fn eval_result_to_json(result: &EvalResult) -> Value {
    let eval_json = evaluated_rules_to_json(&result.evaluated_rules);

    json!({
        "matched": result.matched,
        "verdict": result.verdict,
        "rule_id": result.rule_id,
        "priority": result.priority,
        "evaluated_rules_json": serde_json::to_string(&eval_json).expect("infallible json"),
        "error": result.error,
    })
}

// ═══════════════════════════════════════════════════════════════════════════════
// Pipeline: first-match-wins evaluation
// ═══════════════════════════════════════════════════════════════════════════════

/// Run the first-match-wins evaluation pipeline.
///
/// Iterates through rules in order, evaluates each condition against the
/// context using the shared `condition::evaluate_condition()`, and returns
/// the first match with its verdict enriched by `_rule_id`, `_priority`,
/// and `_evaluated_rules`.
///
/// Args:
///     json_rules: Pre-parsed JSON array of rule objects.
///         Each rule must have: rule_id, condition_sql, action_json, priority.
///     context: Flat string-valued context map.
///
/// Returns:
///     EvalResult with matched rule, enriched verdict, and full evaluation trail.
pub fn evaluate_rules_pipeline(
    json_rules: &[Value],
    context: &serde_json::Map<String, Value>,
) -> EvalResult {
    let mut evaluated: Vec<RuleEvaluation> = Vec::with_capacity(json_rules.len());
    let mut matched: Option<(Value, String, i64)> = None;

    for rule in json_rules {
        let obj = match rule.as_object() {
            Some(o) => o,
            None => continue,
        };

        let rule_id = obj
            .get("rule_id")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string();
        let condition_sql = obj
            .get("condition_sql")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string();
        let action_json_str = obj
            .get("action_json")
            .and_then(|v| v.as_str())
            .unwrap_or("{}")
            .to_string();
        let priority = obj
            .get("priority")
            .and_then(|v| v.as_i64())
            .unwrap_or(100);

        let condition_matches = condition::evaluate_condition(&condition_sql, context);
        let is_selected = matched.is_none() && condition_matches;

        evaluated.push(RuleEvaluation {
            rule_id: rule_id.clone(),
            condition_sql,
            matched: condition_matches,
            selected: is_selected,
        });

        if is_selected {
            matched = Some((
                serde_json::from_str(&action_json_str).unwrap_or_else(|_| json!({})),
                rule_id,
                priority,
            ));
            // Continue evaluating remaining rules for audit trail
        }
    }

    match matched {
        Some((mut verdict, rule_id, priority)) => {
            if let Some(v_obj) = verdict.as_object_mut() {
                v_obj.insert("_rule_id".to_string(), Value::String(rule_id.clone()));
                v_obj.insert("_priority".to_string(), json!(priority));
                v_obj.insert(
                    "_evaluated_rules".to_string(),
                    evaluated_rules_to_json(&evaluated),
                );
            }
            EvalResult {
                matched: true,
                rule_id,
                priority,
                verdict,
                evaluated_rules: evaluated,
                error: String::new(),
            }
        }
        None => EvalResult {
            matched: false,
            rule_id: String::new(),
            priority: 0,
            verdict: json!({}),
            evaluated_rules: evaluated,
            error: "No matching rule found for context".to_string(),
        },
    }
}

/// Evaluate a SINGLE rule set against a SINGLE context (for batch use).
///
/// Returns the EvalResult directly.
pub fn evaluate_single(rules: &[Value], context: &serde_json::Map<String, Value>) -> EvalResult {
    evaluate_rules_pipeline(rules, context)
}

/// Sort rules deterministically by priority then rule_id.
///
/// Sorting order:
///   1. priority ASC (lower = higher priority, evaluated first)
///   2. rule_id ASC (stable tie-breaker for equal priorities)
pub fn sort_rules(rules: &mut [Value]) {
    rules.sort_by(|a, b| {
        let a_priority = a
            .get("priority")
            .and_then(|v| v.as_i64())
            .unwrap_or(100);
        let b_priority = b
            .get("priority")
            .and_then(|v| v.as_i64())
            .unwrap_or(100);
        let a_id = a.get("rule_id").and_then(|v| v.as_str()).unwrap_or("");
        let b_id = b.get("rule_id").and_then(|v| v.as_str()).unwrap_or("");
        (a_priority, a_id).cmp(&(b_priority, b_id))
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// Validation helpers
// ═══════════════════════════════════════════════════════════════════════════════

/// Validate rule priorities for conflicts.
///
/// Returns a Vec of warning JSON objects.
pub fn validate_priorities(rules: &[Value]) -> Vec<Value> {
    let mut warnings: Vec<Value> = Vec::new();
    let mut groups: std::collections::HashMap<(String, i64), Vec<String>> =
        std::collections::HashMap::new();

    for rule in rules {
        let obj = match rule.as_object() {
            Some(o) => o,
            None => continue,
        };
        let condition = obj
            .get("condition_sql")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string();
        let priority = obj
            .get("priority")
            .and_then(|v| v.as_i64())
            .unwrap_or(100);
        let rule_id = obj
            .get("rule_id")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string();
        groups
            .entry((condition, priority))
            .or_default()
            .push(rule_id);
    }

    for ((condition, priority), rule_ids) in &groups {
        if rule_ids.len() > 1 {
            warnings.push(json!({
                "type": "priority_conflict",
                "condition_sql": condition,
                "priority": priority,
                "rule_ids": rule_ids,
                "message": format!(
                    "Rule conflict: {} rules share the same condition and priority={}. \
                     First-match-wins will depend on input order.",
                    rule_ids.len(),
                    priority,
                ),
            }));
        }
    }

    warnings
}

/// Validate rules format — checks required fields and action_json validity.
///
/// Returns Ok(()) if all rules are valid, or Err with a list of error messages.
pub fn validate_rules_format(rules: &[Value]) -> Result<(), Vec<String>> {
    let mut errors: Vec<String> = Vec::new();

    for (i, rule) in rules.iter().enumerate() {
        let obj = match rule.as_object() {
            Some(o) => o,
            None => {
                errors.push(format!("Rule {}: not a JSON object", i));
                continue;
            }
        };

        let fields = ["rule_id", "condition_sql", "action_json", "priority"];
        for field in &fields {
            if !obj.contains_key(*field) {
                errors.push(format!("Rule {}: missing '{}' field", i, field));
            }
        }

        // Validate action_json is valid JSON
        if let Some(action) = obj.get("action_json").and_then(|v| v.as_str()) {
            if serde_json::from_str::<Value>(action).is_err() {
                errors.push(format!(
                    "Rule {}: 'action_json' is not valid JSON: {}",
                    i, action
                ));
            }
        }

        // Validate types
        if let Some(rule_id) = obj.get("rule_id") {
            if !rule_id.is_string() {
                errors.push(format!("Rule {}: 'rule_id' must be a string", i));
            }
        }
        if let Some(priority) = obj.get("priority") {
            if !priority.is_i64() && !priority.is_f64() {
                errors.push(format!("Rule {}: 'priority' must be a number", i));
            }
        }
    }

    if errors.is_empty() {
        Ok(())
    } else {
        Err(errors)
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tests
// ═══════════════════════════════════════════════════════════════════════════════

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_pipeline_no_match() {
        let rules = vec![json!({
            "rule_id": "r1",
            "condition_sql": "category_code = 'FUEL'",
            "action_json": "{\"vat_rate\": \"0.23\"}",
            "priority": 10,
        })];

        let mut ctx = serde_json::Map::new();
        ctx.insert("category_code".to_string(), json!("FOOD"));

        let result = evaluate_rules_pipeline(&rules, &ctx);
        assert!(!result.matched);
        assert_eq!(result.error, "No matching rule found for context");
        assert_eq!(result.evaluated_rules.len(), 1);
        assert!(!result.evaluated_rules[0].matched);
    }

    #[test]
    fn test_pipeline_first_match_wins() {
        let rules = vec![
            json!({
                "rule_id": "r1",
                "condition_sql": "category_code = 'FUEL'",
                "action_json": "{\"vat_rate\": \"0.23\"}",
                "priority": 10,
            }),
            json!({
                "rule_id": "r2",
                "condition_sql": "category_code = 'FUEL'",
                "action_json": "{\"vat_rate\": \"0.08\"}",
                "priority": 20,
            }),
        ];

        let mut ctx = serde_json::Map::new();
        ctx.insert("category_code".to_string(), json!("FUEL"));

        let result = evaluate_rules_pipeline(&rules, &ctx);
        assert!(result.matched);
        assert_eq!(result.rule_id, "r1"); // first-match-wins
        assert_eq!(result.priority, 10);
    }

    #[test]
    fn test_pipeline_empty_rules() {
        let rules: Vec<Value> = vec![];
        let ctx = serde_json::Map::new();

        let result = evaluate_rules_pipeline(&rules, &ctx);
        assert!(!result.matched);
        assert_eq!(result.error, "No matching rule found for context");
        assert_eq!(result.evaluated_rules.len(), 0);
    }

    #[test]
    fn test_pipeline_match_second_rule() {
        let rules = vec![
            json!({
                "rule_id": "r1",
                "condition_sql": "category_code = 'FUEL'",
                "action_json": "{\"vat_rate\": \"0.23\"}",
                "priority": 10,
            }),
            json!({
                "rule_id": "r2",
                "condition_sql": "category_code = 'FOOD'",
                "action_json": "{\"vat_rate\": \"0.08\"}",
                "priority": 20,
            }),
        ];

        let mut ctx = serde_json::Map::new();
        ctx.insert("category_code".to_string(), json!("FOOD"));

        let result = evaluate_rules_pipeline(&rules, &ctx);
        assert!(result.matched);
        assert_eq!(result.rule_id, "r2");
    }

    #[test]
    fn test_sort_rules() {
        let mut rules = vec![
            json!({"rule_id": "b", "priority": 20}),
            json!({"rule_id": "a", "priority": 10}),
            json!({"rule_id": "c", "priority": 10}),
        ];

        sort_rules(&mut rules);

        assert_eq!(rules[0]["rule_id"], "a");
        assert_eq!(rules[1]["rule_id"], "c");
        assert_eq!(rules[2]["rule_id"], "b");
    }

    #[test]
    fn test_validate_priorities_no_conflict() {
        let rules = vec![
            json!({
                "rule_id": "r1",
                "condition_sql": "cat = 'FUEL'",
                "priority": 10,
            }),
            json!({
                "rule_id": "r2",
                "condition_sql": "cat = 'FOOD'",
                "priority": 10,
            }),
        ];

        let warnings = validate_priorities(&rules);
        assert_eq!(warnings.len(), 0);
    }

    #[test]
    fn test_validate_priorities_with_conflict() {
        let rules = vec![
            json!({
                "rule_id": "r1",
                "condition_sql": "cat = 'FUEL'",
                "priority": 10,
            }),
            json!({
                "rule_id": "r2",
                "condition_sql": "cat = 'FUEL'",
                "priority": 10,
            }),
        ];

        let warnings = validate_priorities(&rules);
        assert_eq!(warnings.len(), 1);
    }

    #[test]
    fn test_eval_result_to_json() {
        let result = EvalResult {
            matched: true,
            rule_id: "r1".to_string(),
            priority: 10,
            verdict: json!({"vat_rate": "0.23"}),
            evaluated_rules: vec![RuleEvaluation {
                rule_id: "r1".to_string(),
                condition_sql: "cat = 'FUEL'".to_string(),
                matched: true,
                selected: true,
            }],
            error: String::new(),
        };

        let json = eval_result_to_json(&result);
        assert_eq!(json["matched"], true);
        assert_eq!(json["rule_id"], "r1");
        assert_eq!(json["priority"], 10);
        assert!(json["evaluated_rules_json"].is_string());
    }

    #[test]
    fn test_validate_rules_format_ok() {
        let rules = vec![json!({
            "rule_id": "r1",
            "condition_sql": "cat = 'FUEL'",
            "action_json": "{\"vat_rate\": \"0.23\"}",
            "priority": 10,
        })];

        assert!(validate_rules_format(&rules).is_ok());
    }

    #[test]
    fn test_validate_rules_format_missing_fields() {
        let rules = vec![json!({
            "rule_id": "r1",
        })];

        assert!(validate_rules_format(&rules).is_err());
        let errs = validate_rules_format(&rules).unwrap_err();
        assert!(errs.len() >= 3); // missing: condition_sql, action_json, priority
    }
}
