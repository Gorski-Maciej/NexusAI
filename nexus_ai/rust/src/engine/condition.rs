// ═══════════════════════════════════════════════════════════════════════════════
// condition — SQL Condition Tokenizer, Parser, and Evaluator
// ═══════════════════════════════════════════════════════════════════════════════
//
// JEDNO źródło prawdy dla ewaluacji warunków SQL w całym projekcie.
// Wyodrębnione z rule_engine.rs i rules_engine.rs aby wyeliminować duplikację.
//
// Obsługuje wzorce używane w DEFAULT_TAX_RULES:
//   - field = 'value'          (string equality)
//   - field IN ('v1', 'v2')    (IN list)
//   - field < 'value'          (string comparison)
//   - field > ''               (non-empty check)
//   - field1 = 'v1' AND field2 = 'v2'   (AND composition)
//   - ( ... AND ... )          (parentheses groups)
//   - fc_* fields              (confidence scores as strings)
//
// Structured logging: log::info!, log::debug!, log::warn!
// All logs forwarded to Python structlog via pyo3-log (init in lib.rs)
// ═══════════════════════════════════════════════════════════════════════════════

use serde_json::Value;

// ═══════════════════════════════════════════════════════════════════════════════
// SQL Condition Tokenizer
// ═══════════════════════════════════════════════════════════════════════════════

/// Token types for SQL condition parsing.
#[derive(Debug, Clone, PartialEq)]
pub enum Token {
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
pub fn tokenize(input: &str) -> Vec<Token> {
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
            '(' => { chars.next(); tokens.push(Token::LParen); }
            ')' => { chars.next(); tokens.push(Token::RParen); }
            // Comma
            ',' => { chars.next(); tokens.push(Token::Comma); }
            // Operators: =, <, >
            '=' => { chars.next(); tokens.push(Token::Op("=".to_string())); }
            '<' => { chars.next(); tokens.push(Token::Op("<".to_string())); }
            '>' => { chars.next(); tokens.push(Token::Op(">".to_string())); }
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
            _ => { chars.next(); } // skip unknown
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
pub fn eval_tokens(tokens: &[Token], context: &serde_json::Map<String, Value>) -> bool {
    if tokens.is_empty() {
        return true;
    }

    for group in split_on_and(tokens) {
        if !eval_and_group(group, context) {
            return false;
        }
    }
    true
}

/// Split token sequence on top-level AND tokens (not inside parentheses).
pub fn split_on_and(tokens: &[Token]) -> Vec<&[Token]> {
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
pub fn eval_and_group(tokens: &[Token], context: &serde_json::Map<String, Value>) -> bool {
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
pub fn strip_parens(tokens: &[Token]) -> &[Token] {
    if tokens.len() >= 2 && tokens[0] == Token::LParen && tokens[tokens.len() - 1] == Token::RParen {
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
///
/// This is the MAIN public API — the only function that should be called
/// from outside this module. All other functions are pub(crate) for testing.
pub fn evaluate_condition(
    condition_sql: &str,
    context: &serde_json::Map<String, Value>,
) -> bool {
    let tokens = tokenize(condition_sql);
    eval_tokens(&tokens, context)
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tests
// ═══════════════════════════════════════════════════════════════════════════════

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

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
        assert!(evaluate_condition(
            "fc_minimum > '' AND fc_minimum < '0.90'",
            &ctx
        ));
    }

    #[test]
    fn test_roundtrip_empty_condition() {
        assert!(evaluate_condition("", &serde_json::Map::new()));
    }

    #[test]
    fn test_strip_parens_simple() {
        let tokens = tokenize("(category_code = 'FUEL')");
        let stripped = strip_parens(&tokens);
        assert_eq!(stripped.len(), 3);
        assert_eq!(stripped[0], Token::Ident("category_code".to_string()));
    }

    #[test]
    fn test_nested_parens() {
        let tokens = tokenize("((category_code = 'FUEL'))");
        let stripped = strip_parens(&tokens);
        assert_eq!(stripped.len(), 5); // ( category_code = 'FUEL' )
    }

    #[test]
    fn test_complex_expression() {
        let mut ctx = serde_json::Map::new();
        ctx.insert("category_code".to_string(), json!("FUEL"));
        ctx.insert("vendor_country".to_string(), json!("PL"));

        assert!(evaluate_condition(
            "(category_code = 'FUEL' AND vendor_country = 'PL')",
            &ctx
        ));
        assert!(!evaluate_condition(
            "(category_code = 'FOOD' AND vendor_country = 'PL')",
            &ctx
        ));
    }
}
