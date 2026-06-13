// ═══════════════════════════════════════════════════════════════════════════════
// RuleEngine — Rust-native PriorityEngine (self-contained first-match-wins)
// ═══════════════════════════════════════════════════════════════════════════════
//
// SELF-CONTAINED — no dependency on tax_pipeline.rs or its SQL evaluator.
// Uses its own inline SQL tokenizer/parser/evaluator (duplicated from
// rules_engine.rs for PriorityEngine backward compatibility).
//
// Komponenty:
//   1. PriorityEngine.resolve()  — first-match-wins rule evaluation
//   2. PriorityEngine.sort_rules() — sort by priority ASC, rule_id ASC
//   3. PriorityEngine.validate_priorities() — detect rule conflicts
//
// Structured logging: log::info!, log::debug!, log::warn!
// All logs forwarded to Python structlog via pyo3-log (init in lib.rs)
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::exceptions::PyValueError;
use pyo3::prelude::*;
use serde_json::{json, Value};

// ═══════════════════════════════════════════════════════════════════════════════
// Inline SQL Condition Evaluator (self-contained, no tax_pipeline dependency)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Supports patterns used in DEFAULT_TAX_RULES:
//   - field = 'value'          (string equality)
//   - field IN ('v1', 'v2')    (IN list)
//   - field < 'value'          (string comparison)
//   - field > ''               (non-empty check)
//   - field1 = 'v1' AND field2 = 'v2'   (AND composition)
//   - ( ... AND ... )          (parentheses)
// ═══════════════════════════════════════════════════════════════════════════════

#[derive(Debug, Clone, PartialEq)]
enum Token {
    Ident(String),
    StringLit(String),
    Op(String),
    In,
    And,
    LParen,
    RParen,
    Comma,
}

fn tokenize(input: &str) -> Vec<Token> {
    let mut tokens = Vec::new();
    let mut chars = input.chars().peekable();
    while let Some(&ch) = chars.peek() {
        match ch {
            c if c.is_whitespace() => { chars.next(); }
            '\'' => {
                chars.next();
                let mut s = String::new();
                while let Some(&c) = chars.peek() {
                    if c == '\'' { chars.next(); break; }
                    s.push(c);
                    chars.next();
                }
                tokens.push(Token::StringLit(s));
            }
            '(' => { chars.next(); tokens.push(Token::LParen); }
            ')' => { chars.next(); tokens.push(Token::RParen); }
            ',' => { chars.next(); tokens.push(Token::Comma); }
            '=' => { chars.next(); tokens.push(Token::Op("=".to_string())); }
            '<' => { chars.next(); tokens.push(Token::Op("<".to_string())); }
            '>' => { chars.next(); tokens.push(Token::Op(">".to_string())); }
            c if c.is_ascii_alphanumeric() || c == '_' => {
                let mut ident = String::new();
                while let Some(&c) = chars.peek() {
                    if c.is_ascii_alphanumeric() || c == '_' { ident.push(c); chars.next(); }
                    else { break; }
                }
                match ident.to_uppercase().as_str() {
                    "IN" => tokens.push(Token::In),
                    "AND" => tokens.push(Token::And),
                    _ => tokens.push(Token::Ident(ident)),
                }
            }
            _ => { chars.next(); }
        }
    }
    tokens
}

fn eval_tokens(tokens: &[Token], context: &serde_json::Map<String, Value>) -> bool {
    if tokens.is_empty() { return true; }
    for group in split_on_and(tokens) {
        if !eval_and_group(group, context) { return false; }
    }
    true
}

fn split_on_and(tokens: &[Token]) -> Vec<&[Token]> {
    let mut groups = Vec::new();
    let mut depth = 0;
    let mut start = 0;
    for (i, t) in tokens.iter().enumerate() {
        match t {
            Token::LParen => depth += 1,
            Token::RParen => depth -= 1,
            Token::And if depth == 0 => { groups.push(&tokens[start..i]); start = i + 1; }
            _ => {}
        }
    }
    if start < tokens.len() { groups.push(&tokens[start..]); }
    groups
}

fn eval_and_group(tokens: &[Token], context: &serde_json::Map<String, Value>) -> bool {
    let inner = strip_parens(tokens);
    let op_pos = inner.iter().position(|t| matches!(t, Token::Op(_) | Token::In));
    match op_pos {
        Some(pos) => {
            match &inner[pos] {
                Token::Op(op) => {
                    if pos >= 1 && pos + 1 < inner.len() {
                        if let Token::Ident(field) = &inner[pos - 1] {
                            if let Token::StringLit(expected) = &inner[pos + 1] {
                                return eval_compare(field, op, expected, context);
                            }
                        }
                    }
                    false
                }
                _ => {
                    // IN expression or unexpected token — treat as IN if Token::In
                    if matches!(inner[pos], Token::In) && pos >= 1 {
                        if let Token::Ident(field) = &inner[pos - 1] {
                            let values: Vec<&str> = inner[pos + 1..]
                                .iter()
                                .filter_map(|t| if let Token::StringLit(s) = t { Some(s.as_str()) } else { None })
                                .collect();
                            return eval_in(field, &values, context);
                        }
                    }
                    false
                }
            }
        },
        None => !inner.is_empty(),
    }
}

fn strip_parens(tokens: &[Token]) -> &[Token] {
    if tokens.len() >= 2 && tokens[0] == Token::LParen && tokens[tokens.len() - 1] == Token::RParen {
        let mut depth = 0i32;
        for (i, t) in tokens.iter().enumerate() {
            match t {
                Token::LParen => depth += 1,
                Token::RParen => {
                    depth -= 1;
                    if depth == 0 && i != tokens.len() - 1 { return tokens; }
                }
                _ => {}
            }
        }
        &tokens[1..tokens.len() - 1]
    } else {
        tokens
    }
}

fn eval_compare(field: &str, op: &str, expected: &str, context: &serde_json::Map<String, Value>) -> bool {
    let actual = match context.get(field) { Some(Value::String(s)) => s.as_str(), _ => return false };
    match op {
        "=" => actual == expected,
        "<" => actual < expected,
        ">" => actual > expected,
        _ => false,
    }
}

fn eval_in(field: &str, values: &[&str], context: &serde_json::Map<String, Value>) -> bool {
    let actual = match context.get(field) { Some(Value::String(s)) => s.as_str(), _ => return false };
    values.contains(&actual)
}

fn evaluate_condition(condition_sql: &str, context: &serde_json::Map<String, Value>) -> bool {
    let tokens = tokenize(condition_sql);
    eval_tokens(&tokens, context)
}

// ═══════════════════════════════════════════════════════════════════════════════
// Inline first-match-wins pipeline (self-contained, no tax_pipeline dependency)
// ═══════════════════════════════════════════════════════════════════════════════

fn evaluate_rules_pipeline(rules: &[Value], context: &serde_json::Map<String, Value>) -> String {
    let mut evaluated: Vec<Value> = Vec::with_capacity(rules.len());
    let mut matched_rule: Option<(Value, String, i64)> = None;

    for rule in rules {
        let obj = match rule.as_object() { Some(o) => o, None => continue };
        let rule_id = obj.get("rule_id").and_then(|v| v.as_str()).unwrap_or("").to_string();
        let condition_sql = obj.get("condition_sql").and_then(|v| v.as_str()).unwrap_or("").to_string();
        let action_json_str = obj.get("action_json").and_then(|v| v.as_str()).unwrap_or("{}").to_string();
        let priority = obj.get("priority").and_then(|v| v.as_i64()).unwrap_or(100);

        let matches = evaluate_condition(&condition_sql, context);
        let is_selected = matched_rule.is_none() && matches;

        evaluated.push(json!({
            "rule_id": rule_id,
            "condition_sql": condition_sql,
            "result": matches,
            "selected": is_selected,
        }));

        if is_selected {
            matched_rule = Some((
                serde_json::from_str(&action_json_str).unwrap_or_else(|_| json!({})),
                rule_id,
                priority,
            ));
        }
    }

    let evaluated_json = serde_json::to_string(&evaluated).expect("infallible json");

    match matched_rule {
        Some((mut verdict, rule_id, priority)) => {
            if let Some(v_obj) = verdict.as_object_mut() {
                v_obj.insert("_rule_id".to_string(), Value::String(rule_id.clone()));
                v_obj.insert("_priority".to_string(), json!(priority));
                v_obj.insert("_evaluated_rules".to_string(), Value::Array(evaluated));
            }
            serde_json::to_string(&json!({
                "matched": true,
                "verdict": verdict,
                "rule_id": rule_id,
                "priority": priority,
                "evaluated_rules_json": evaluated_json,
            })).expect("infallible json")
        }
        None => serde_json::to_string(&json!({
            "matched": false,
            "error": "No matching rule found for context",
            "evaluated_rules_json": evaluated_json,
        })).expect("infallible json"),
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PriorityEngine — first-match-wins rule evaluation (self-contained)
// ═══════════════════════════════════════════════════════════════════════════════

/// Deterministic first-match-wins rule evaluation (self-contained).
///
/// SELF-CONTAINED — no delegation to tax_pipeline. Uses its own inline
/// SQL condition tokenizer/parser/evaluator.
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
    /// Uses self-contained SQL evaluator (no dependency on tax_pipeline.rs).
    /// Returns the first matching rule's verdict enriched with
    /// ``_rule_id``, ``_priority``, and ``_evaluated_rules``.
    #[staticmethod]
    fn resolve(rules_json: &str, context_json: &str) -> PyResult<String> {
        log::debug!("PriorityEngine.resolve: self-contained evaluation");
        let context: serde_json::Map<String, Value> = serde_json::from_str(context_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid context JSON: {e}")))?;
        let rules: Vec<Value> = serde_json::from_str(rules_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid rules JSON: {e}")))?;

        let result = evaluate_rules_pipeline(&rules, &context);
        log::debug!("PriorityEngine.resolve: done");
        Ok(result)
    }

    /// Sort rules deterministically by priority then rule_id.
    #[staticmethod]
    fn sort_rules(rules_json: &str) -> PyResult<String> {
        let mut rules: Vec<Value> = serde_json::from_str(rules_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid rules JSON: {e}")))?;
        rules.sort_by(|a, b| {
            let a_p = a.get("priority").and_then(|v| v.as_i64()).unwrap_or(100);
            let b_p = b.get("priority").and_then(|v| v.as_i64()).unwrap_or(100);
            let a_id = a.get("rule_id").and_then(|v| v.as_str()).unwrap_or("");
            let b_id = b.get("rule_id").and_then(|v| v.as_str()).unwrap_or("");
            (a_p, a_id).cmp(&(b_p, b_id))
        });
        log::debug!("PriorityEngine.sort_rules: sorted {} rules", rules.len());
        Ok(serde_json::to_string(&rules).expect("infallible json"))
    }

    /// Validate rule priorities for conflicts.
    #[staticmethod]
    fn validate_priorities(rules_json: &str) -> PyResult<String> {
        let rules: Vec<Value> = serde_json::from_str(rules_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid rules JSON: {e}")))?;
        let mut warnings: Vec<Value> = Vec::new();
        let mut groups: std::collections::HashMap<(String, i64), Vec<String>> = std::collections::HashMap::new();

        for rule in &rules {
            let condition = rule.get("condition_sql").and_then(|v| v.as_str()).unwrap_or("").to_string();
            let priority = rule.get("priority").and_then(|v| v.as_i64()).unwrap_or(100);
            let rule_id = rule.get("rule_id").and_then(|v| v.as_str()).unwrap_or("").to_string();
            groups.entry((condition, priority)).or_default().push(rule_id);
        }

        for ((condition, priority), rule_ids) in &groups {
            if rule_ids.len() > 1 {
                warnings.push(json!({
                    "condition_sql": condition,
                    "priority": priority,
                    "rule_ids": rule_ids,
                    "warning": format!("Rule conflict: {} rules with same condition and priority={}.", rule_ids.len(), priority),
                }));
            }
        }

        log::debug!("PriorityEngine.validate_priorities: {} rules, {} conflicts", rules.len(), warnings.len());
        Ok(serde_json::to_string(&warnings).expect("infallible json"))
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Module registration
// ═══════════════════════════════════════════════════════════════════════════════

pub fn register(module: &Bound<'_, PyModule>) -> PyResult<()> {
    module.add_class::<PriorityEngine>()?;
    log::info!("rule_engine: registered PriorityEngine (self-contained, no tax_pipeline dependency)");
    Ok(())
}
