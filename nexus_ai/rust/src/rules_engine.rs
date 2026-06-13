// ═══════════════════════════════════════════════════════════════════════════════
// RulesEngine — comprehensive first-match-wins rule evaluation pipeline
// ═══════════════════════════════════════════════════════════════════════════════
//
// SELF-CONTAINED module — no dependency on tax_pipeline.rs or other modules.
// Full SQL condition tokenizer, parser, and evaluator built in.
//
// Komponenty:
//   1. RulesEngine.evaluate()      — first-match-wins rule evaluation (full pipeline)
//   2. RulesEngine.batch_evaluate() — evaluate multiple contexts against same rules
//   3. RulesEngine.validate()       — validate rules format, detect conflicts
//   4. RulesEngine.sort()           — sort by priority ASC, rule_id ASC
//   5. SQL Condition Evaluator      — inline tokenizer + parser + evaluator
//      (supports: =, <, >, IN, AND, parentheses, fc_* fields)
//
// Logging: log::info!, log::debug!, log::warn! → Python structlog (via pyo3-log)
//
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::exceptions::PyValueError;
use pyo3::prelude::*;
use serde_json::{json, Value};

// ═══════════════════════════════════════════════════════════════════════════════
// SQL Condition Tokenizer
// ═══════════════════════════════════════════════════════════════════════════════
//
// Obsługuje wzorce używane w DEFAULT_TAX_RULES:
//   - field = 'value'          (string equality)
//   - field IN ('v1', 'v2')    (IN list)
//   - field < 'value'          (string comparison)
//   - field > ''               (non-empty check)
//   - field1 = 'v1' AND field2 = 'v2'   (AND composition)
//   - ( ... AND ... )          (parentheses groups)
//   - fc_* fields              (confidence scores as strings)
// ═══════════════════════════════════════════════════════════════════════════════

/// Token types for SQL condition parsing.
#[derive(Debug, Clone, PartialEq)]
enum Token {
    Ident(String),
    StringLit(String),
    Op(String),      // =, <, >
    In,              // IN
    And,             // AND
    LParen,          // (
    RParen,          // )
    Comma,
}

/// Tokenize a SQL WHERE condition expression into a token stream.
///
/// Handles single-quoted string literals, identifiers (alphanumeric + _),
/// operators (=, <, >), keywords (IN, AND), parentheses, and commas.
fn tokenize(input: &str) -> Vec<Token> {
    let mut tokens = Vec::new();
    let mut chars = input.chars().peekable();

    while let Some(&ch) = chars.peek() {
        match ch {
            // Whitespace
            c if c.is_whitespace() => {
                chars.next();
            }
            // String literals (single-quoted)
            '\'' => {
                chars.next(); // consume opening '
                let mut s = String::new();
                while let Some(&c) = chars.peek() {
                    if c == '\'' {
                        chars.next(); // consume closing '
                        break;
                    }
                    s.push(c);
                    chars.next();
                }
                tokens.push(Token::StringLit(s));
            }
            // Parentheses
            '(' => {
                chars.next();
                tokens.push(Token::LParen);
            }
            ')' => {
                chars.next();
                tokens.push(Token::RParen);
            }
            // Comma
            ',' => {
                chars.next();
                tokens.push(Token::Comma);
            }
            // Operators: =, <, >
            '=' => {
                chars.next();
                tokens.push(Token::Op("=".to_string()));
            }
            '<' => {
                chars.next();
                tokens.push(Token::Op("<".to_string()));
            }
            '>' => {
                chars.next();
                tokens.push(Token::Op(">".to_string()));
            }
            // Identifiers and keywords (alphanumeric + underscores)
            c if c.is_ascii_alphanumeric() || c == '_' => {
                let mut ident = String::new();
                while let Some(&c) = chars.peek() {
                    if c.is_ascii_alphanumeric() || c == '_' {
                        ident.push(c);
                        chars.next();
                    } else {
                        break;
                    }
                }
                let upper = ident.to_uppercase();
                match upper.as_str() {
                    "IN" => tokens.push(Token::In),
                    "AND" => tokens.push(Token::And),
                    _ => tokens.push(Token::Ident(ident)),
                }
            }
            _ => {
                chars.next(); // skip unknown
            }
        }
    }
    tokens
}

// ═══════════════════════════════════════════════════════════════════════════════
// SQL Condition Evaluator
// ═══════════════════════════════════════════════════════════════════════════════

/// Evaluate a token sequence against a context map.
///
/// Supports AND composition (top-level). Each AND group is evaluated
/// independently; all must pass for the condition to match.
fn eval_tokens(tokens: &[Token], context: &serde_json::Map<String, Value>) -> bool {
    if tokens.is_empty() {
        return true;
    }

    let and_groups: Vec<&[Token]> = split_on_and(tokens);

    for group in &and_groups {
        if !eval_and_group(group, context) {
            return false;
        }
    }
    true
}

/// Split token sequence on top-level AND tokens (not inside parentheses).
fn split_on_and(tokens: &[Token]) -> Vec<&[Token]> {
    let mut groups = Vec::new();
    let mut depth = 0;
    let mut start = 0;

    for (i, token) in tokens.iter().enumerate() {
        match token {
            Token::LParen => depth += 1,
            Token::RParen => depth -= 1,
            Token::And if depth == 0 => {
                groups.push(&tokens[start..i]);
                start = i + 1;
            }
            _ => {}
        }
    }
    if start < tokens.len() {
        groups.push(&tokens[start..]);
    }
    groups
}

/// Evaluate an AND group: either a comparison, an IN expression, or a
/// parenthesized sub-expression.
fn eval_and_group(tokens: &[Token], context: &serde_json::Map<String, Value>) -> bool {
    // Strip outer parentheses
    let inner = strip_parens(tokens);

    // Find the operator position (=, <, >, IN)
    let op_pos = inner
        .iter()
        .position(|t| matches!(t, Token::Op(_) | Token::In));

    match op_pos {
        Some(pos) => match &inner[pos] {
            Token::Op(op) => {
                // Pattern: <ident> <op> <string_lit>
                if pos >= 1 && pos + 1 < inner.len() {
                    if let Token::Ident(field) = &inner[pos - 1] {
                        if let Token::StringLit(expected) = &inner[pos + 1] {
                            return eval_compare(field, op, expected, context);
                        }
                    }
                }
                false
            }
            // Pattern: <ident> IN ( <lit>, <lit>, ... )
            _ if matches!(inner[pos], Token::In) => {
                if pos >= 1 {
                    if let Token::Ident(field) = &inner[pos - 1] {
                        let values: Vec<&str> = inner[pos + 1..]
                            .iter()
                            .filter_map(|t| {
                                if let Token::StringLit(s) = t {
                                    Some(s.as_str())
                                } else {
                                    None
                                }
                            })
                            .collect();
                        return eval_in(field, &values, context);
                    }
                }
                false
            }
            _ => false,
        },
        None => {
            // No operator — treat as true (empty group) or skip
            !inner.is_empty()
        }
    }
}

/// Strip matching outer parentheses from a token slice.
fn strip_parens(tokens: &[Token]) -> &[Token] {
    if tokens.len() >= 2 && tokens[0] == Token::LParen && tokens[tokens.len() - 1] == Token::RParen
    {
        // Verify the parens match (depth returns to 0 only at the end)
        let mut depth = 0i32;
        for (i, t) in tokens.iter().enumerate() {
            match t {
                Token::LParen => depth += 1,
                Token::RParen => {
                    depth -= 1;
                    if depth == 0 && i != tokens.len() - 1 {
                        return tokens; // early return — not matching outer parens
                    }
                }
                _ => {}
            }
        }
        &tokens[1..tokens.len() - 1]
    } else {
        tokens
    }
}

/// Evaluate `field <op> 'expected'` against context.
///
/// Supports string equality (=), less-than (<), and greater-than (>).
/// The `> ''` pattern checks for non-empty strings.
fn eval_compare(
    field: &str,
    op: &str,
    expected: &str,
    context: &serde_json::Map<String, Value>,
) -> bool {
    let actual = match context.get(field) {
        Some(Value::String(s)) => s.as_str(),
        _ => return false,
    };

    match op {
        "=" => actual == expected,
        "<" => actual < expected,  // string comparison (works for numeric strings)
        ">" => actual > expected,  // includes > '' (non-empty check)
        _ => false,
    }
}

/// Evaluate `field IN ('v1', 'v2', ...)` against context.
fn eval_in(
    field: &str,
    values: &[&str],
    context: &serde_json::Map<String, Value>,
) -> bool {
    let actual = match context.get(field) {
        Some(Value::String(s)) => s.as_str(),
        _ => return false,
    };
    values.contains(&actual)
}

/// Evaluate a condition_sql expression against a context map.
///
/// Returns true if the condition matches the context.
fn evaluate_condition(
    condition_sql: &str,
    context: &serde_json::Map<String, Value>,
) -> bool {
    let tokens = tokenize(condition_sql);
    eval_tokens(&tokens, context)
}

// ═══════════════════════════════════════════════════════════════════════════════
// RuleEvaluationResult — structured result of evaluating a single rule
// ═══════════════════════════════════════════════════════════════════════════════

/// Internal representation of a single rule evaluation.
struct RuleEvaluation {
    rule_id: String,
    condition_sql: String,
    matched: bool,
    selected: bool,
}

/// The full result of a rules evaluation pipeline.
struct EvalResult {
    matched: bool,
    rule_id: String,
    priority: i64,
    verdict: Value,
    evaluated_rules: Vec<RuleEvaluation>,
    error: String,
}

// ═══════════════════════════════════════════════════════════════════════════════
// Pipeline: first-match-wins evaluation
// ═══════════════════════════════════════════════════════════════════════════════

/// Run the first-match-wins evaluation pipeline.
///
/// Iterates through rules in order, evaluates each condition against the
/// context, and returns the first match with its verdict enriched by
/// `_rule_id`, `_priority`, and `_evaluated_rules`.
fn evaluate_rules_pipeline(
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

        let condition_matches = evaluate_condition(&condition_sql, context);
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
            // Enrich verdict with metadata
            if let Some(v_obj) = verdict.as_object_mut() {
                v_obj.insert("_rule_id".to_string(), Value::String(rule_id.clone()));
                v_obj.insert("_priority".to_string(), json!(priority));
                // Serialize evaluated rules to JSON array
                let evals: Vec<Value> = evaluated
                    .iter()
                    .map(|e| {
                        json!({
                            "rule_id": e.rule_id,
                            "condition_sql": e.condition_sql,
                            "result": e.matched,
                            "selected": e.selected,
                        })
                    })
                    .collect();
                v_obj.insert("_evaluated_rules".to_string(), Value::Array(evals));
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

// ═══════════════════════════════════════════════════════════════════════════════
// RulesEngine — comprehensive pyclass for rule evaluation
// ═══════════════════════════════════════════════════════════════════════════════
//
/// Comprehensive rule evaluation pipeline with first-match-wins semantics.
///
/// Self-contained SQL condition evaluator — no external dependencies.
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
///     # → list of conflict warnings
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
    ///   4. Evaluate each condition via inline SQL evaluator
    ///   5. Return first match with enriched verdict
    ///
    /// Args:
    ///     rules_json: JSON array of rule objects:
    ///         [{
    ///             "rule_id": str,
    ///             "condition_sql": str,
    ///             "action_json": str (JSON string),
    ///             "priority": int
    ///         }, ...]
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

        let result = evaluate_rules_pipeline(&rules, &context);

        let evaluated_json =
            serde_json::to_string(&result.evaluated_rules.iter().map(|e| {
                json!({
                    "rule_id": e.rule_id,
                    "condition_sql": e.condition_sql,
                    "result": e.matched,
                    "selected": e.selected,
                })
            }).collect::<Vec<Value>>())
            .expect("infallible json");

        let output = json!({
            "matched": result.matched,
            "verdict": result.verdict,
            "rule_id": result.rule_id,
            "priority": result.priority,
            "evaluated_rules_json": evaluated_json,
            "error": result.error,
        });

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
        log::info!("RulesEngine.batch_evaluate: starting batch evaluation");

        let rules: Vec<Value> = serde_json::from_str(rules_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid rules JSON: {e}")))?;

        let contexts: Vec<Value> = serde_json::from_str(contexts_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid contexts JSON: {e}")))?;

        let mut results: Vec<Value> = Vec::with_capacity(contexts.len());

        for (i, ctx_val) in contexts.iter().enumerate() {
            let context = match ctx_val.as_object() {
                Some(o) => o.clone(),
                None => {
                    log::warn!("RulesEngine.batch_evaluate: context {} is not an object", i);
                    results.push(json!({
                        "matched": false,
                        "verdict": {},
                        "rule_id": "",
                        "priority": 0,
                        "evaluated_rules_json": "[]",
                        "error": format!("Context {} is not a JSON object", i),
                    }));
                    continue;
                }
            };

            let result = evaluate_rules_pipeline(&rules, &context);

            let evaluated_json =
                serde_json::to_string(&result.evaluated_rules.iter().map(|e| {
                    json!({
                        "rule_id": e.rule_id,
                        "condition_sql": e.condition_sql,
                        "result": e.matched,
                        "selected": e.selected,
                    })
                }).collect::<Vec<Value>>())
                .expect("infallible json");

            results.push(json!({
                "matched": result.matched,
                "verdict": result.verdict,
                "rule_id": result.rule_id,
                "priority": result.priority,
                "evaluated_rules_json": evaluated_json,
                "error": result.error,
                "_context_index": i,
            }));
        }

        log::info!(
            "RulesEngine.batch_evaluate: {} contexts evaluated with {} rules",
            contexts.len(),
            rules.len(),
        );

        Ok(serde_json::to_string(&results).expect("infallible json"))
    }

    /// Validate rules format and detect priority conflicts.
    ///
    /// Checks:
    ///   - Each rule has required fields (rule_id, condition_sql, action_json, priority)
    ///   - No conflicting rules with same ``condition_sql`` AND same ``priority``
    ///     (which would make first-match-wins depend on input order rather than priority)
    ///   - Valid JSON structure
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

        let mut errors: Vec<String> = Vec::new();
        let mut warnings: Vec<Value> = Vec::new();

        // Check each rule for required fields
        for (i, rule) in rules.iter().enumerate() {
            let obj = match rule.as_object() {
                Some(o) => o,
                None => {
                    errors.push(format!("Rule {}: not a JSON object", i));
                    continue;
                }
            };

            // Required fields
            if !obj.contains_key("rule_id") {
                errors.push(format!("Rule {}: missing 'rule_id' field", i));
            }
            if !obj.contains_key("condition_sql") {
                errors.push(format!("Rule {}: missing 'condition_sql' field", i));
            }
            if !obj.contains_key("action_json") {
                errors.push(format!("Rule {}: missing 'action_json' field", i));
            }
            if !obj.contains_key("priority") {
                errors.push(format!("Rule {}: missing 'priority' field", i));
            }

            // Validate types
            if let Some(rule_id) = obj.get("rule_id") {
                if !rule_id.is_string() {
                    errors.push(format!("Rule {}: 'rule_id' must be a string", i));
                }
            }
            if let Some(condition) = obj.get("condition_sql") {
                if !condition.is_string() {
                    errors.push(format!("Rule {}: 'condition_sql' must be a string", i));
                }
            }
            if let Some(action) = obj.get("action_json") {
                if let Some(action_str) = action.as_str() {
                    // Verify action_json is valid JSON
                    if serde_json::from_str::<Value>(action_str).is_err() {
                        errors.push(format!(
                            "Rule {}: 'action_json' is not valid JSON: {}",
                            i, action_str
                        ));
                    }
                } else {
                    errors.push(format!("Rule {}: 'action_json' must be a string", i));
                }
            }
            if let Some(priority) = obj.get("priority") {
                if !priority.is_i64() && !priority.is_f64() {
                    errors.push(format!("Rule {}: 'priority' must be a number", i));
                }
            }
        }

        // Detect priority conflicts only if no structural errors
        if errors.is_empty() {
            let mut groups: std::collections::HashMap<(String, i64), Vec<String>> =
                std::collections::HashMap::new();

            for rule in &rules {
                let obj = rule.as_object().unwrap();
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
        }

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
    ///   1. ``priority`` ASC (lower = higher priority, evaluated first)
    ///   2. ``rule_id`` ASC (stable tie-breaker for equal priorities)
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

        log::debug!("RulesEngine.sort_rules: sorted {} rules", rules.len());
        Ok(serde_json::to_string(&rules).expect("infallible json"))
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Module registration
// ═══════════════════════════════════════════════════════════════════════════════

/// Register the RulesEngine pyclass with the Python module.
///
/// Adds the following to the module:
///   - ``RulesEngine`` class with ``evaluate``, ``batch_evaluate``,
///     ``validate``, and ``sort_rules`` static methods.
pub fn register(module: &Bound<'_, PyModule>) -> PyResult<()> {
    module.add_class::<RulesEngine>()?;
    log::info!("rules_engine: registered RulesEngine (self-contained pipeline)");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tokenize_simple_equality() {
        let tokens = tokenize("category_code = 'FUEL'");
        assert_eq!(tokens.len(), 3);
        assert_eq!(tokens[0], Token::Ident("category_code".to_string()));
        assert_eq!(tokens[1], Token::Op("=".to_string()));
        assert_eq!(tokens[2], Token::StringLit("FUEL".to_string()));
    }

    #[test]
    fn test_tokenize_in_list() {
        let tokens = tokenize("category_code IN ('FOOD', 'EDUCATION')");
        assert!(tokens.contains(&Token::In));
        assert!(tokens.contains(&Token::LParen));
        assert!(tokens.contains(&Token::RParen));
        assert!(tokens.contains(&Token::Comma));
    }

    #[test]
    fn test_tokenize_and() {
        let tokens = tokenize("category_code = 'FUEL' AND vendor_country = 'PL'");
        let and_count = tokens.iter().filter(|t| **t == Token::And).count();
        assert_eq!(and_count, 1);
    }

    #[test]
    fn test_evaluate_equality() {
        let mut ctx = serde_json::Map::new();
        ctx.insert("category_code".to_string(), json!("FUEL"));
        ctx.insert("vendor_country".to_string(), json!("PL"));

        assert!(evaluate_condition("category_code = 'FUEL'", &ctx));
        assert!(!evaluate_condition("category_code = 'FOOD'", &ctx));
    }

    #[test]
    fn test_evaluate_and() {
        let mut ctx = serde_json::Map::new();
        ctx.insert("category_code".to_string(), json!("FUEL"));
        ctx.insert("vendor_country".to_string(), json!("PL"));

        assert!(evaluate_condition(
            "category_code = 'FUEL' AND vendor_country = 'PL'",
            &ctx
        ));
        assert!(!evaluate_condition(
            "category_code = 'FUEL' AND vendor_country = 'EU'",
            &ctx
        ));
    }

    #[test]
    fn test_evaluate_in() {
        let mut ctx = serde_json::Map::new();
        ctx.insert("category_code".to_string(), json!("FOOD"));

        assert!(evaluate_condition(
            "category_code IN ('FOOD', 'EDUCATION')",
            &ctx
        ));
        assert!(!evaluate_condition(
            "category_code IN ('FUEL', 'IT_OFFICE')",
            &ctx
        ));
    }

    #[test]
    fn test_evaluate_empty_check() {
        let mut ctx = serde_json::Map::new();
        ctx.insert("fc_vat_rate".to_string(), json!("0.95"));

        assert!(evaluate_condition("fc_vat_rate > '0.90'", &ctx));
        assert!(!evaluate_condition("fc_vat_rate > '0.99'", &ctx));
        assert!(evaluate_condition("fc_vat_rate > ''", &ctx));
    }

    #[test]
    fn test_evaluate_no_context() {
        let ctx = serde_json::Map::new();
        assert!(!evaluate_condition("category_code = 'FUEL'", &ctx));
    }

    #[test]
    fn test_tokenize_empty() {
        let tokens = tokenize("");
        assert!(tokens.is_empty());
    }

    #[test]
    fn test_evaluate_confidence_field() {
        let mut ctx = serde_json::Map::new();
        ctx.insert("fc_minimum".to_string(), json!("0.85"));

        assert!(evaluate_condition("fc_minimum > '0.80'", &ctx));
        assert!(evaluate_condition("fc_minimum < '0.90'", &ctx));
        assert!(evaluate_condition("fc_minimum > '' AND fc_minimum < '0.90'", &ctx));
    }

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
}
