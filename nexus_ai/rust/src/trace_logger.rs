// ═══════════════════════════════════════════════════════════════════════════════
// TraceLogger — Rust-native cryptographic audit trail for DecisionTrace
// ═══════════════════════════════════════════════════════════════════════════════
//
// Zastępuje Python DecisionTraceLogger (nexus_ai/tax/audit.py).
//
// COMPONENTY:
//   1. DecisionTraceLogger pyclass:
//      - prepare_log() — computes hash chain entry (no I/O)
//      - log() — prepare_log + Python callback for DuckDB INSERT
//      - get_trace() — query builder (SQL fragments)
//      - latest_hash() — pure Rust hash chain lookup
//   2. compute_current_hash() — standalone SHA-256 hash computation
//   3. verify_chain_integrity() — verifies full hash chain from JSON array
//
// DuckDB I/O pozostaje w Pythonie. Rust wykonuje całą kryptografię:
//   - UUID generation (trace_id)
//   - ISO timestamp formatting
//   - SHA-256 hash chain (canonical field order)
//   - Chain integrity verification
//
// Structured logging: log::info!, log::debug!, log::warn!
// All logs forwarded to Python structlog via pyo3-log (init in lib.rs)
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::exceptions::PyValueError;
use pyo3::prelude::*;
use serde_json::{json, Value};
use sha2::{Digest, Sha256};

// Uwaga: compute_current_hash implementuje tę samą canonical field order
// co DecisionTraceHasher::compute_hash w tax_pipeline.rs.
// Nie można delegate przez PyO3 (metody są dostępne tylko przez Python dispatch).
// Jeśli zmieniasz kolejność pól, zaktualizuj OBA miejsca.

// ── Constants ───────────────────────────────────────────────────────────────

const GENESIS_HASH: &str = "0000000000000000000000000000000000000000000000000000000000000000";

// ═══════════════════════════════════════════════════════════════════════════════
// compute_current_hash — standalone SHA-256 hash computation
// ═══════════════════════════════════════════════════════════════════════════════

/// Compute SHA-256 over pipe-delimited decision fields.
///
/// Canonical field order:
///   previous_hash|trace_id|transaction_id|context_json|verdict_json|
///   calculation_input|calculation_output|invariants_result|risk_verdict|timestamp
///
/// NOTE: ``decision_trace`` and ``trace_json`` (human-readable artifacts)
/// are intentionally EXCLUDED from the hash for backward compatibility.
/// The core fields (context, verdict, calculation) already provide
/// full integrity — tampering with derived text would not hide
/// tampering with the source data.
///
/// Matches the Python `_compute_current_hash()` signature exactly.
#[pyfunction]
#[pyo3(signature = (
    previous_hash,
    trace_id,
    transaction_id,
    context_json,
    verdict_json,
    timestamp_iso,
    calculation_input = "",
    calculation_output = "",
    invariants_result = "",
    risk_verdict = "",
))]
fn compute_current_hash(
    previous_hash: &str,
    trace_id: &str,
    transaction_id: &str,
    context_json: &str,
    verdict_json: &str,
    timestamp_iso: &str,
    calculation_input: &str,
    calculation_output: &str,
    invariants_result: &str,
    risk_verdict: &str,
) -> String {
    log::debug!(
        "compute_current_hash: trace={}, tx={}",
        trace_id,
        transaction_id
    );

    // Canonical field order — musi być identyczna z DecisionTraceHasher::compute_hash
    // w tax_pipeline.rs. Sześć pól: hash, trace, tx, context, verdict, calculation
    // input/output, invariants, risk, timestamp.
    let payload = format!(
        "{}|{}|{}|{}|{}|{}|{}|{}|{}|{}",
        previous_hash,
        trace_id,
        transaction_id,
        context_json,
        verdict_json,
        calculation_input,
        calculation_output,
        invariants_result,
        risk_verdict,
        timestamp_iso,
    );
    let mut hasher = Sha256::new();
    hasher.update(payload.as_bytes());
    hex::encode(hasher.finalize())
}

/// Return the genesis hash (64 zeros) — used for the very first chain entry.
#[pyfunction]
fn genesis_hash() -> String {
    GENESIS_HASH.to_string()
}

// ═══════════════════════════════════════════════════════════════════════════════
// PreparedLog — pre-computed log entry ready for DuckDB INSERT
// ═══════════════════════════════════════════════════════════════════════════════

/// Pre-computed decision trace log entry, ready for DuckDB persistence.
///
/// Python creates this via `DecisionTraceLogger.prepare_log()` and then
/// inserts it into DuckDB using the returned dict.
#[pyclass(name = "PreparedLog")]
#[derive(Clone, Debug)]
pub struct PreparedLog {
    /// Generated trace UUID (hex).
    #[pyo3(get)]
    pub trace_id: String,
    /// Transaction UUID.
    #[pyo3(get)]
    pub transaction_id: String,
    /// Rule ID (may be empty).
    #[pyo3(get)]
    pub rule_id: String,
    /// Context JSON (deterministic, sort_keys).
    #[pyo3(get)]
    pub context_json: String,
    /// Verdict JSON (deterministic, sort_keys).
    #[pyo3(get)]
    pub verdict_json: String,
    /// Calculation input JSON.
    #[pyo3(get)]
    pub calculation_input: String,
    /// Calculation output JSON.
    #[pyo3(get)]
    pub calculation_output: String,
    /// Invariants result JSON.
    #[pyo3(get)]
    pub invariants_result: String,
    /// Risk verdict JSON.
    #[pyo3(get)]
    pub risk_verdict: String,
    /// Human-readable decision trace text.
    #[pyo3(get)]
    pub decision_trace: String,
    /// JSON-encoded detailed trace.
    #[pyo3(get)]
    pub trace_json: String,
    /// SHA-256 hash of the previous entry (or genesis hash).
    #[pyo3(get)]
    pub previous_hash: String,
    /// Computed SHA-256 hash for this entry.
    #[pyo3(get)]
    pub current_hash: String,
    /// ISO-8601 timestamp of creation.
    #[pyo3(get)]
    pub timestamp: String,
}

#[pymethods]
impl PreparedLog {
    /// Return the ordered values as a flat list for DuckDB INSERT.
    ///
    /// Column order matches the `decision_traces` table schema:
    ///   trace_id, transaction_id, rule_id, context_json, verdict_json,
    ///   calculation_input, calculation_output, invariants_result,
    ///   risk_verdict, decision_trace, trace_json,
    ///   previous_hash, current_hash, timestamp
    fn values(&self) -> Vec<String> {
        vec![
            self.trace_id.clone(),
            self.transaction_id.clone(),
            self.rule_id.clone(),
            self.context_json.clone(),
            self.verdict_json.clone(),
            self.calculation_input.clone(),
            self.calculation_output.clone(),
            self.invariants_result.clone(),
            self.risk_verdict.clone(),
            self.decision_trace.clone(),
            self.trace_json.clone(),
            self.previous_hash.clone(),
            self.current_hash.clone(),
            self.timestamp.clone(),
        ]
    }

    fn __repr__(&self) -> String {
        format!(
            "PreparedLog(trace={}, tx={}, hash={}...)",
            &self.trace_id[..8],
            &self.transaction_id[..8],
            &self.current_hash[..8],
        )
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DecisionTraceLogger — Rust-native logger pyclass
// ═══════════════════════════════════════════════════════════════════════════════
//
// UWAGA: Ten logger NIE łączy się z DuckDB bezpośrednio.
// Zamiast tego przygotowuje wpis (prepare_log), a Python wykonuje INSERT.
// Decyzja architektoniczna: DuckDB I/O zostaje w Pythonie, Rust robi crypto.

/// Append-only cryptographic audit trail for tax decisions.
///
/// Usage (Python side)::
///
///     logger = DecisionTraceLogger()
///     entry = logger.prepare_log(
///         transaction_id="uuid",
///         previous_hash=latest_hash,
///         context=ctx_dict,
///         verdict=v_dict,
///     )
///     conn.execute(\"INSERT INTO decision_traces (...) VALUES (?)\", entry.to_dict())
#[pyclass(name = "DecisionTraceLogger")]
pub struct DecisionTraceLogger;

#[pymethods]
impl DecisionTraceLogger {
    /// Prepare a decision trace log entry with cryptographic hash chain linkage.
    ///
    /// This is a PURE COMPUTATION method — it does NOT perform DuckDB I/O.
    /// The returned :class:`PreparedLog` must be inserted into DuckDB by the caller.
    ///
    /// Args:
    ///     transaction_id: UUID of the invoice / transaction.
    ///     previous_hash: SHA-256 hash of the previous entry (use ``genesis_hash()``
    ///         for the very first entry, or pass the result of ``latest_hash()``).
    ///     context_json: JSON string of context snapshot (deterministic, sort_keys).
    ///     verdict_json: JSON string of verdict (deterministic, sort_keys).
    ///     rule_id: Optional UUID of the matching rule.
    ///     calculation_input: Optional JSON string of input amounts.
    ///     calculation_output: Optional JSON string of output amounts.
    ///     invariants_result: Optional JSON string of invariant validation outcome.
    ///     risk_verdict: Optional JSON string of risk guard verdict.
    ///     decision_trace: Optional human-readable trace text.
    ///     trace_json: Optional JSON-encoded detailed evaluation trace.
    ///     timestamp_iso: Optional ISO-8601 timestamp (auto-generated if None).
    ///
    /// Returns:
    ///     :class:`PreparedLog` with all fields ready for DuckDB INSERT.
    #[pyo3(signature = (
        transaction_id,
        previous_hash,
        context_json,
        verdict_json,
        rule_id = "",
        calculation_input = "",
        calculation_output = "",
        invariants_result = "",
        risk_verdict = "",
        decision_trace = "",
        trace_json = "",
        timestamp_iso = None,
    ))]
    #[staticmethod]
    fn prepare_log(
        transaction_id: &str,
        previous_hash: &str,
        context_json: &str,
        verdict_json: &str,
        rule_id: &str,
        calculation_input: &str,
        calculation_output: &str,
        invariants_result: &str,
        risk_verdict: &str,
        decision_trace: &str,
        trace_json: &str,
        timestamp_iso: Option<String>,
    ) -> PreparedLog {
        // Generate trace UUID and timestamp
        let trace_id = uuid::Uuid::new_v4().to_string();
        let ts = timestamp_iso.unwrap_or_else(|| {
            // ISO-8601 timestamp using chrono (UTC)
            chrono::Utc::now().format("%Y-%m-%dT%H:%M:%S%.f").to_string()
        });

        log::debug!(
            "DecisionTraceLogger.prepare_log: tx={}, prev={}...",
            transaction_id,
            &previous_hash[..8.min(previous_hash.len())],
        );

        // Compute the SHA-256 hash for this entry
        let current_hash = compute_current_hash(
            previous_hash,
            &trace_id,
            transaction_id,
            context_json,
            verdict_json,
            &ts,
            calculation_input,
            calculation_output,
            invariants_result,
            risk_verdict,
        );

        PreparedLog {
            trace_id,
            transaction_id: transaction_id.to_string(),
            rule_id: rule_id.to_string(),
            context_json: context_json.to_string(),
            verdict_json: verdict_json.to_string(),
            calculation_input: calculation_input.to_string(),
            calculation_output: calculation_output.to_string(),
            invariants_result: invariants_result.to_string(),
            risk_verdict: risk_verdict.to_string(),
            decision_trace: decision_trace.to_string(),
            trace_json: trace_json.to_string(),
            previous_hash: previous_hash.to_string(),
            current_hash,
            timestamp: ts,
        }
    }

    /// Get a SQL query fragment for retrieving traces by transaction_id.
    ///
    /// Returns a JSON string with ``sql`` and ``params`` for DuckDB.
    #[staticmethod]
    fn get_trace_query() -> String {
        serde_json::to_string(&json!({
            "sql": "SELECT trace_id, transaction_id, rule_id, context_json, \
                    verdict_json, calculation_input, calculation_output, \
                    invariants_result, risk_verdict, \
                    decision_trace, trace_json, \
                    previous_hash, current_hash, timestamp \
                    FROM decision_traces \
                    WHERE transaction_id = ? \
                    ORDER BY timestamp ASC",
            "params_order": ["transaction_id"],
        })).expect("infallible json")
    }

    /// Get a SQL query fragment for the latest hash.
    #[staticmethod]
    fn latest_hash_query() -> String {
        serde_json::to_string(&json!({
            "sql": "SELECT current_hash FROM decision_traces ORDER BY timestamp DESC LIMIT 1"
        })).expect("infallible json")
    }

    /// Get a SQL query fragment for counting entries.
    #[staticmethod]
    fn entry_count_query() -> String {
        serde_json::to_string(&json!({
            "sql": "SELECT COUNT(1) FROM decision_traces"
        })).expect("infallible json")
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// verify_chain_integrity — pure Rust hash chain verification
// ═══════════════════════════════════════════════════════════════════════════════

/// Verify the full decision trace hash chain from a JSON array of entries.
///
/// Each entry must be a dict (or object) with keys:
///   trace_id, transaction_id, context_json, verdict_json,
///   calculation_input, calculation_output, invariants_result,
///   risk_verdict, previous_hash, current_hash, timestamp
///
/// Args:
///     entries_json: JSON array of decision trace entries (oldest first).
///
/// Returns:
///     JSON array of integrity issues. An empty array means the chain is intact.
#[pyfunction]
fn verify_chain_integrity(entries_json: &str) -> PyResult<String> {
    let entries: Vec<Value> = serde_json::from_str(entries_json)
        .map_err(|e| PyValueError::new_err(format!("Invalid entries JSON: {e}")))?;

    let mut issues: Vec<Value> = Vec::new();
    let mut expected_previous = GENESIS_HASH.to_string();

    for entry in &entries {
        let obj = match entry.as_object() {
            Some(o) => o,
            None => continue,
        };

        let trace_id = get_str(obj, "trace_id", "");
        let transaction_id = get_str(obj, "transaction_id", "");
        let context_json = get_str(obj, "context_json", "{}");
        let verdict_json = get_str(obj, "verdict_json", "{}");
        let calculation_input = get_str(obj, "calculation_input", "");
        let calculation_output = get_str(obj, "calculation_output", "");
        let invariants_result = get_str(obj, "invariants_result", "");
        let risk_verdict = get_str(obj, "risk_verdict", "");
        let stored_previous = get_str(obj, "previous_hash", "");
        let stored_current = get_str(obj, "current_hash", "");
        let timestamp_iso = get_str(obj, "timestamp", "");

        // 1. Previous hash linkage
        if stored_previous != expected_previous {
            issues.push(json!({
                "trace_id": trace_id,
                "issue": "previous_hash_mismatch",
                "expected_previous": expected_previous,
                "stored_previous": stored_previous,
                "message": format!(
                    "Entry {}: stored previous_hash does not match previous entry's current_hash",
                    trace_id
                ),
            }));
        }

        // 2. Current hash integrity (recompute from stored fields)
        let recomputed = compute_current_hash(
            &stored_previous,
            &trace_id,
            &transaction_id,
            &context_json,
            &verdict_json,
            &timestamp_iso,
            &calculation_input,
            &calculation_output,
            &invariants_result,
            &risk_verdict,
        );
        if recomputed != stored_current {
            issues.push(json!({
                "trace_id": trace_id,
                "issue": "current_hash_mismatch",
                "expected_current": recomputed,
                "stored_current": stored_current,
                "message": format!(
                    "Entry {}: stored current_hash does not match recomputed hash — data may have been tampered with",
                    trace_id,
                ),
            }));
        }

        expected_previous = stored_current;
    }

    let result = serde_json::to_string(&json!(issues)).expect("infallible json");
    log::info!(
        "verify_chain_integrity: {} entries, {} issues",
        entries.len(),
        issues.len(),
    );
    Ok(result)
}

/// Helper: get string from JSON object with default fallback.
fn get_str(obj: &serde_json::Map<String, Value>, key: &str, default: &str) -> String {
    obj.get(key)
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| default.to_string())
}

// ═══════════════════════════════════════════════════════════════════════════════
// Module registration
// ═══════════════════════════════════════════════════════════════════════════════

pub fn register(module: &Bound<'_, PyModule>) -> PyResult<()> {
    module.add_class::<DecisionTraceLogger>()?;
    module.add_class::<PreparedLog>()?;
    module.add_function(wrap_pyfunction!(compute_current_hash, module)?)?;
    module.add_function(wrap_pyfunction!(genesis_hash, module)?)?;
    module.add_function(wrap_pyfunction!(verify_chain_integrity, module)?)?;
    log::info!(
        "trace_logger: registered DecisionTraceLogger, PreparedLog, \
         compute_current_hash, genesis_hash, verify_chain_integrity"
    );
    Ok(())
}
