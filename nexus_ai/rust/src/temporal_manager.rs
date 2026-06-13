// ═══════════════════════════════════════════════════════════════════════════════
// TemporalManager — Rust-native temporal rule filtering and validation
// ═══════════════════════════════════════════════════════════════════════════════
//
// Zastępuje Python TemporalManager (nexus_ai/services/temporal_manager.py).
//
// DuckDB I/O pozostaje w Pythonie — Rust przyjmuje już załadowane reguły
// jako JSON i wykonuje czystą logikę:
//   1. filter_rules  — filtrowanie według valid_from/valid_to + sortowanie
//   2. validate_overlap — wykrywanie konfliktów temporalnych
//   3. sort_by_temporal — sortowanie temporalne (priority, valid_from DESC, rule_id)
//
// Structured logging: log::info!, log::debug!, log::warn!
// All logs forwarded to Python structlog via pyo3-log (init in lib.rs)
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::exceptions::PyValueError;
use pyo3::prelude::*;
use serde_json::{json, Value};

// ═══════════════════════════════════════════════════════════════════════════════
// TemporalManager — temporal rule filtering and validation
// ═══════════════════════════════════════════════════════════════════════════════
//
/// Temporal rule filtering and validation in pure Rust.
///
/// DuckDB I/O (temporal queries) stays in Python. This class accepts
/// pre-loaded rules as JSON and performs pure logic operations:
///   - Date-based filtering (valid_from / valid_to)
///   - Deterministic temporal sorting
///   - Overlap conflict detection
///
/// Usage (Python side)::
///
///     tm = TemporalManager()
///     filtered = tm.filter_rules(rules_json, "2024-06-01")
///     warnings = tm.validate_overlap(rules_json)
///     sorted_rules = tm.sort_by_temporal(rules_json)
///
/// Rule JSON format::
///
///     [{
///         "rule_id": str,
///         "condition_sql": str,
///         "action_json": str,
///         "priority": int,
///         "valid_from": str (ISO date YYYY-MM-DD),
///         "valid_to": str | None (ISO date or null)
///     }, ...]
#[pyclass(name = "TemporalManager")]
pub struct TemporalManager;

#[pymethods]
impl TemporalManager {
    /// Filter rules by date and sort temporally.
    ///
    /// Returns only rules where ``valid_from <= date <= valid_to``
    /// (or ``valid_to IS NULL`` for open-ended rules), sorted by:
    ///   1. ``priority`` ASC (lower = higher priority)
    ///   2. ``valid_from`` DESC (newer rules win for same priority)
    ///   3. ``rule_id`` ASC (stable tie-breaker)
    ///
    /// Args:
    ///     rules_json: JSON array of rule objects (see class doc for format).
    ///     date_str: ISO date string (``YYYY-MM-DD``) for filtering.
    ///
    /// Returns:
    ///     JSON array of filtered rules, sorted temporally.
    #[staticmethod]
    fn filter_rules(rules_json: &str, date_str: &str) -> PyResult<String> {
        log::debug!(
            "TemporalManager.filter_rules: filtering by date={}, {} rules input",
            date_str,
            rules_json.len(),
        );

        let rules: Vec<Value> = serde_json::from_str(rules_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid rules JSON: {e}")))?;

        let date_parsed = parse_date(date_str)?;

        // Filter by valid_from <= date AND (valid_to IS NULL OR valid_to >= date)
        let mut active: Vec<Value> = rules
            .into_iter()
            .filter(|rule| {
                let obj = match rule.as_object() {
                    Some(o) => o,
                    None => return false,
                };

                // valid_from
                let vf = obj
                    .get("valid_from")
                    .and_then(|v| v.as_str())
                    .and_then(parse_date_inner);

                let vf_ok = match vf {
                    Some(vf_date) => vf_date <= date_parsed,
                    None => true, // no valid_from = always active
                };

                if !vf_ok {
                    return false;
                }

                // valid_to (nullable)
                let vt = obj
                    .get("valid_to")
                    .and_then(|v| {
                        if v.is_null() {
                            None // NULL = open-ended
                        } else {
                            v.as_str().and_then(parse_date_inner)
                        }
                    });

                match vt {
                    Some(vt_date) => vt_date >= date_parsed,
                    None => true, // NULL valid_to = active indefinitely
                }
            })
            .collect();

        // Sort by (priority ASC, valid_from DESC, rule_id ASC)
        active.sort_by(|a, b| {
            let a_priority = a
                .get("priority")
                .and_then(|v| v.as_i64())
                .unwrap_or(100);
            let b_priority = b
                .get("priority")
                .and_then(|v| v.as_i64())
                .unwrap_or(100);

            match a_priority.cmp(&b_priority) {
                std::cmp::Ordering::Equal => {
                    // valid_from DESC (newer first)
                    let a_vf = a
                        .get("valid_from")
                        .and_then(|v| v.as_str())
                        .and_then(parse_date_inner)
                        .unwrap_or(0);
                    let b_vf = b
                        .get("valid_from")
                        .and_then(|v| v.as_str())
                        .and_then(parse_date_inner)
                        .unwrap_or(0);
                    match b_vf.cmp(&a_vf) {
                        // note: b_vf.cmp(&a_vf) for DESC
                        std::cmp::Ordering::Equal => {
                            let a_id = a
                                .get("rule_id")
                                .and_then(|v| v.as_str())
                                .unwrap_or("");
                            let b_id = b
                                .get("rule_id")
                                .and_then(|v| v.as_str())
                                .unwrap_or("");
                            a_id.cmp(b_id)
                        }
                        other => other,
                    }
                }
                other => other,
            }
        });

        log::debug!(
            "TemporalManager.filter_rules: {} active rules after filtering",
            active.len(),
        );

        Ok(serde_json::to_string(&active).expect("infallible json"))
    }

    /// Sort rules temporally by (priority, valid_from DESC, rule_id).
    ///
    /// Args:
    ///     rules_json: JSON array of rule objects.
    ///
    /// Returns:
    ///     JSON array of rules sorted temporally.
    #[staticmethod]
    fn sort_by_temporal(rules_json: &str) -> PyResult<String> {
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

            match a_priority.cmp(&b_priority) {
                std::cmp::Ordering::Equal => {
                    let a_vf = a
                        .get("valid_from")
                        .and_then(|v| v.as_str())
                        .and_then(parse_date_inner)
                        .unwrap_or(0);
                    let b_vf = b
                        .get("valid_from")
                        .and_then(|v| v.as_str())
                        .and_then(parse_date_inner)
                        .unwrap_or(0);
                    match b_vf.cmp(&a_vf) {
                        // DESC
                        std::cmp::Ordering::Equal => {
                            let a_id = a
                                .get("rule_id")
                                .and_then(|v| v.as_str())
                                .unwrap_or("");
                            let b_id = b
                                .get("rule_id")
                                .and_then(|v| v.as_str())
                                .unwrap_or("");
                            a_id.cmp(b_id)
                        }
                        other => other,
                    }
                }
                other => other,
            }
        });

        log::debug!("TemporalManager.sort_by_temporal: sorted {} rules", rules.len());
        Ok(serde_json::to_string(&rules).expect("infallible json"))
    }

    /// Detect temporal overlap conflicts between rules.
    ///
    /// Two rules conflict if they have the same ``condition_sql`` and
    /// their temporal windows overlap (i.e., the date range [valid_from, valid_to]
    /// intersects). Open-ended rules (valid_to = null) are treated as
    /// extending to infinite future.
    ///
    /// Args:
    ///     rules_json: JSON array of rule objects (see class doc for format).
    ///
    /// Returns:
    ///     JSON array of conflict warnings. Empty array = no conflicts.
    #[staticmethod]
    fn validate_overlap(rules_json: &str) -> PyResult<String> {
        let rules: Vec<Value> = serde_json::from_str(rules_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid rules JSON: {e}")))?;

        let mut conflicts: Vec<Value> = Vec::new();

        // Group by condition_sql
        let mut by_condition: std::collections::HashMap<String, Vec<&Value>> =
            std::collections::HashMap::new();

        for rule in &rules {
            let condition = rule
                .get("condition_sql")
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .to_string();
            by_condition.entry(condition).or_default().push(rule);
        }

        for (condition, group) in &by_condition {
            if group.len() < 2 {
                continue;
            }

            for i in 0..group.len() {
                for j in (i + 1)..group.len() {
                    let a = group[i];
                    let b = group[j];

                    let a_vf = a
                        .get("valid_from")
                        .and_then(|v| v.as_str())
                        .and_then(parse_date_inner)
                        .unwrap_or(0);
                    let a_vt = a
                        .get("valid_to")
                        .and_then(|v| {
                            if v.is_null() {
                                Some(i64::MAX) // open-ended
                            } else {
                                v.as_str().and_then(parse_date_inner)
                            }
                        })
                        .unwrap_or(i64::MAX);

                    let b_vf = b
                        .get("valid_from")
                        .and_then(|v| v.as_str())
                        .and_then(parse_date_inner)
                        .unwrap_or(0);
                    let b_vt = b
                        .get("valid_to")
                        .and_then(|v| {
                            if v.is_null() {
                                Some(i64::MAX)
                            } else {
                                v.as_str().and_then(parse_date_inner)
                            }
                        })
                        .unwrap_or(i64::MAX);

                    // Overlap: a_start <= b_end AND b_start <= a_end
                    if a_vf <= b_vt && b_vf <= a_vt {
                        let a_id = a
                            .get("rule_id")
                            .and_then(|v| v.as_str())
                            .unwrap_or("");
                        let b_id = b
                            .get("rule_id")
                            .and_then(|v| v.as_str())
                            .unwrap_or("");

                        conflicts.push(json!({
                            "condition_sql": condition,
                            "rule_a": a_id,
                            "rule_b": b_id,
                            "window_a": format!(
                                "{} – {}",
                                a.get("valid_from").and_then(|v| v.as_str()).unwrap_or("?"),
                                a.get("valid_to")
                                    .map(|v| if v.is_null() { "∞".to_string() } else { v.as_str().unwrap_or("?").to_string() })
                                    .unwrap_or_else(|| "∞".to_string()),
                            ),
                            "window_b": format!(
                                "{} – {}",
                                b.get("valid_from").and_then(|v| v.as_str()).unwrap_or("?"),
                                b.get("valid_to")
                                    .map(|v| if v.is_null() { "∞".to_string() } else { v.as_str().unwrap_or("?").to_string() })
                                    .unwrap_or_else(|| "∞".to_string()),
                            ),
                        }));
                    }
                }
            }
        }

        log::debug!(
            "TemporalManager.validate_overlap: {} rules, {} conflicts",
            rules.len(),
            conflicts.len(),
        );

        Ok(serde_json::to_string(&conflicts).expect("infallible json"))
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Date parsing utilities
// ═══════════════════════════════════════════════════════════════════════════════

/// Parse an ISO date string (YYYY-MM-DD) to an integer YYYYMMDD for comparison.
fn parse_date(date_str: &str) -> PyResult<i64> {
    parse_date_inner(date_str).ok_or_else(|| {
        PyValueError::new_err(format!("Invalid date format: {date_str:?}; expected YYYY-MM-DD"))
    })
}

/// Parse ISO date to YYYYMMDD integer. Returns None on invalid format.
fn parse_date_inner(date_str: &str) -> Option<i64> {
    let trimmed = date_str.trim();
    if trimmed.len() < 10 {
        return None;
    }
    let year: i64 = trimmed[..4].parse().ok()?;
    let month: i64 = trimmed[5..7].parse().ok()?;
    let day: i64 = trimmed[8..10].parse().ok()?;
    Some(year * 10000 + month * 100 + day)
}

// ═══════════════════════════════════════════════════════════════════════════════
// Module registration
// ═══════════════════════════════════════════════════════════════════════════════

pub fn register(module: &Bound<'_, PyModule>) -> PyResult<()> {
    module.add_class::<TemporalManager>()?;
    log::info!("temporal_manager: registered TemporalManager (date filtering, overlap validation)");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_date() {
        assert_eq!(parse_date_inner("2024-06-01"), Some(20240601));
        assert_eq!(parse_date_inner("2024-01-15"), Some(20240115));
        assert_eq!(parse_date_inner("invalid"), None);
    }

    #[test]
    fn test_filter_rules_date_comparison() {
        let rules = json!([
            {
                "rule_id": "r1",
                "condition_sql": "cat = 'FUEL'",
                "action_json": "{}",
                "priority": 10,
                "valid_from": "2024-01-01",
                "valid_to": json!(null),
            },
            {
                "rule_id": "r2",
                "condition_sql": "cat = 'FOOD'",
                "action_json": "{}",
                "priority": 20,
                "valid_from": "2025-01-01",
                "valid_to": "2025-12-31",
            },
        ]);

        let result = serde_json::from_str::<Value>(
            &TemporalManager::filter_rules(
                &serde_json::to_string(&rules).unwrap(),
                "2024-06-15",
            )
            .unwrap(),
        )
        .unwrap();
        let arr = result.as_array().unwrap();
        assert_eq!(arr.len(), 1); // r1 active, r2 not yet valid
        assert_eq!(arr[0]["rule_id"], "r1");
    }

    #[test]
    fn test_filter_rules_closed_window() {
        let rules = json!([
            {
                "rule_id": "r1",
                "condition_sql": "cat = 'FUEL'",
                "action_json": "{}",
                "priority": 10,
                "valid_from": "2024-01-01",
                "valid_to": "2024-06-30",
            },
        ]);

        // Active within window
        let result = serde_json::from_str::<Value>(
            &TemporalManager::filter_rules(
                &serde_json::to_string(&rules).unwrap(),
                "2024-06-15",
            )
            .unwrap(),
        )
        .unwrap();
        assert_eq!(result.as_array().unwrap().len(), 1);

        // Inactive after window closes
        let result = serde_json::from_str::<Value>(
            &TemporalManager::filter_rules(
                &serde_json::to_string(&rules).unwrap(),
                "2024-07-01",
            )
            .unwrap(),
        )
        .unwrap();
        assert_eq!(result.as_array().unwrap().len(), 0);
    }

    #[test]
    fn test_validate_overlap_no_conflict() {
        let rules = json!([
            {
                "rule_id": "r1",
                "condition_sql": "cat = 'FUEL'",
                "action_json": "{}",
                "priority": 10,
                "valid_from": "2024-01-01",
                "valid_to": "2024-06-30",
            },
            {
                "rule_id": "r2",
                "condition_sql": "cat = 'FUEL'",
                "action_json": "{}",
                "priority": 10,
                "valid_from": "2024-07-01",
                "valid_to": json!(null),
            },
        ]);

        let result = serde_json::from_str::<Value>(
            &TemporalManager::validate_overlap(
                &serde_json::to_string(&rules).unwrap(),
            )
            .unwrap(),
        )
        .unwrap();
        assert_eq!(result.as_array().unwrap().len(), 0); // no overlap
    }

    #[test]
    fn test_validate_overlap_conflict() {
        let rules = json!([
            {
                "rule_id": "r1",
                "condition_sql": "cat = 'FUEL'",
                "action_json": "{}",
                "priority": 10,
                "valid_from": "2024-01-01",
                "valid_to": "2024-12-31",
            },
            {
                "rule_id": "r2",
                "condition_sql": "cat = 'FUEL'",
                "action_json": "{}",
                "priority": 10,
                "valid_from": "2024-06-01",
                "valid_to": json!(null),
            },
        ]);

        let result = serde_json::from_str::<Value>(
            &TemporalManager::validate_overlap(
                &serde_json::to_string(&rules).unwrap(),
            )
            .unwrap(),
        )
        .unwrap();
        assert_eq!(result.as_array().unwrap().len(), 1); // overlap detected
    }

    #[test]
    fn test_empty_rules() {
        let result = serde_json::from_str::<Value>(
            &TemporalManager::filter_rules("[]", "2024-06-01").unwrap(),
        )
        .unwrap();
        assert_eq!(result.as_array().unwrap().len(), 0);
    }
}
