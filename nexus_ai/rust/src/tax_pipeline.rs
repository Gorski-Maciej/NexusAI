// ═══════════════════════════════════════════════════════════════════════════════
// TaxPipeline — Rust-native full tax processing pipeline
// ═══════════════════════════════════════════════════════════════════════════════
//
// Pełny pipeline podatkowy w Rust+PyO3:
//   1. ContextInterpreter  → flat context dict from invoice data
//   2. RuleEngine          → first-match-wins SQL condition evaluation
//   3. TaxMathEngine       → VAT calculation in grosze
//   4. InvariantGuard      → three invariants check
//   5. AuditHashChain      → SHA-256 hash chain for DecisionTrace
//
// Asynchroniczna część (DuckDB temporal queries, TigerBeetle, NATS, event
// emission) pozostaje w Pythonie. Reguły są ładowane z DuckDB przez Python
// i przekazywane jako JSON do Rusta.
//
// Structured logging: log::info!, log::debug!, log::warn!
// All logs forwarded to Python structlog via pyo3-log (init in lib.rs)
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::exceptions::PyValueError;
use pyo3::prelude::*;
use rust_decimal::prelude::*;
use rust_decimal::RoundingStrategy;
use serde_json::{json, Value};
use sha2::{Digest, Sha256};

use crate::engine::pipeline;
use crate::tax;

// ── Constants ───────────────────────────────────────────────────────────────

const ROUND_HALF_UP: RoundingStrategy = RoundingStrategy::MidpointAwayFromZero;
const GENESIS_HASH: &str = "0000000000000000000000000000000000000000000000000000000000000000";

// ═══════════════════════════════════════════════════════════════════════════════
// Step 1: ContextInterpreter — builds flat context dict from invoice data
// ═══════════════════════════════════════════════════════════════════════════════

/// Builds a flat context dict from raw invoice data for rule evaluation.
///
/// Python equivalent: `ContextInterpreter.build(invoice_data)`
/// All values are stored as strings for SQL-compatible evaluation.
#[pyclass(name = "ContextInterpreter")]
pub struct ContextInterpreter;

#[pymethods]
impl ContextInterpreter {
    /// Transform raw invoice data into a flat context JSON string.
    ///
    /// Args:
    ///     invoice_data_json: JSON string with invoice fields:
    ///         - category_code: str
    ///         - transaction_date: str (YYYY-MM-DD)
    ///         - company_tax_form: str
    ///         - vendor_country: str (PL/EU/NON_EU)
    ///         - vendor_vat_status: str (active/inactive/unknown)
    ///         - vendor_pkd: str (optional)
    ///         - amount_net: str (optional)
    ///         - fc_* fields: str (confidence scores, optional)
    ///
    /// Returns:
    ///     JSON string with flat context (all values as strings).
    #[staticmethod]
    fn build(invoice_data_json: &str) -> PyResult<String> {
        let data: Value = serde_json::from_str(invoice_data_json)
            .map_err(|e| PyValueError::new_err(format!("Invalid invoice_data JSON: {e}")))?;

        let obj = data.as_object().ok_or_else(|| {
            PyValueError::new_err("invoice_data_json must be a JSON object")
        })?;

        let mut ctx = serde_json::Map::new();

        // Required fields with defaults
        ctx.insert(
            "category_code".to_string(),
            Value::String(get_str(&obj, "category_code", "UNKNOWN")),
        );
        ctx.insert(
            "transaction_date".to_string(),
            Value::String(get_str(&obj, "transaction_date", "")),
        );
        ctx.insert(
            "company_tax_form".to_string(),
            Value::String(get_str(&obj, "company_tax_form", "CIT_STANDARD")),
        );
        ctx.insert(
            "vendor_country".to_string(),
            Value::String(get_str(&obj, "vendor_country", "PL")),
        );
        ctx.insert(
            "vendor_vat_status".to_string(),
            Value::String(get_str(&obj, "vendor_vat_status", "unknown")),
        );
        ctx.insert(
            "vendor_pkd".to_string(),
            Value::String(get_str(&obj, "vendor_pkd", "")),
        );

        // amount_net — always string
        let raw_net = obj.get("amount_net").map(|v| match v {
            Value::Number(n) => n.to_string(),
            Value::String(s) => s.clone(),
            _ => "0".to_string(),
        }).unwrap_or_else(|| "0".to_string());
        ctx.insert("amount_net".to_string(), Value::String(raw_net));

        // Copy all fc_* (field confidence) fields verbatim
        for (key, val) in obj.iter() {
            if key.starts_with("fc_") {
                let str_val = match val {
                    Value::String(s) => s.clone(),
                    Value::Number(n) => n.to_string(),
                    Value::Bool(b) => b.to_string(),
                    _ => continue,
                };
                ctx.insert(key.clone(), Value::String(str_val));
            }
        }

        let field_count = ctx.len();
        let result = serde_json::to_string(&Value::Object(ctx))
            .expect("infallible json");

        log::debug!("ContextInterpreter.build: {} fields", field_count);
        Ok(result)
    }
}

/// Helper: get string from JSON object with default fallback.
fn get_str(obj: &serde_json::Map<String, Value>, key: &str, default: &str) -> String {
    obj.get(key)
        .map(|v| match v {
            Value::String(s) => s.clone(),
            Value::Number(n) => n.to_string(),
            _ => default.to_string(),
        })
        .unwrap_or_else(|| default.to_string())
}

// ═══════════════════════════════════════════════════════════════════════════════
// Step 2: Rule Evaluation — deleguje do engine::pipeline (wspólny evaluator)
// ═══════════════════════════════════════════════════════════════════════════════
//
// ZDUPLIKOWANY SQL tokenizer/parser/evaluator usunięty.
// Używamy JEDNEGO źródła prawdy: engine::condition + engine::pipeline.
//
// evaluate_rules_inner zastąpiony delegacją do:
//   pipeline::evaluate_rules_pipeline(&rules, &context)
//   pipeline::eval_result_to_json(&result)
//
// Szczegóły:
//   Token → engine::condition::Token
//   tokenize() → engine::condition::tokenize()
//   evaluate_condition() → engine::condition::evaluate_condition()
//   evaluate_rules_pipeline() → engine::pipeline::evaluate_rules_pipeline()
// ═══════════════════════════════════════════════════════════════════════════════

/// Evaluate rules (first-match-wins) against a context.
///
/// Deleguje do wspólnego pipeline (engine::pipeline + engine::condition).
///
/// Args:
///     rules_json: JSON array of rule objects with:
///         - rule_id: str
///         - condition_sql: str
///         - action_json: str (JSON string of verdict)
///         - priority: int (lower = higher priority)
///     context_json: JSON string of the flat context dict.
///
/// Returns:
///     JSON string with:
///         - matched: bool
///         - verdict: dict (action_json + _rule_id + _priority + _evaluated_rules)
///         - error: str (if no match)
#[pyfunction]
fn evaluate_rules(rules_json: &str, context_json: &str) -> PyResult<String> {
    evaluate_rules_inner(rules_json, context_json)
}

pub(crate) fn evaluate_rules_inner(rules_json: &str, context_json: &str) -> PyResult<String> {
    let context: serde_json::Map<String, Value> = serde_json::from_str(context_json)
        .map_err(|e| PyValueError::new_err(format!("Invalid context JSON: {e}")))?;

    let rules: Vec<Value> = serde_json::from_str(rules_json)
        .map_err(|e| PyValueError::new_err(format!("Invalid rules JSON: {e}")))?;

    log::info!(
        "evaluate_rules_inner (pipeline): {} rules",
        rules.len(),
    );

    let result = pipeline::evaluate_rules_pipeline(&rules, &context);
    let output = pipeline::eval_result_to_json(&result);

    log::info!(
        "evaluate_rules_inner (pipeline): matched={}, rule_id={}",
        result.matched,
        if result.matched { &result.rule_id } else { "(none)" },
    );

    Ok(serde_json::to_string(&output).expect("infallible json"))
}

// ═══════════════════════════════════════════════════════════════════════════════
// DecisionTraceHasher — SHA-256 hash chain computation
// ═══════════════════════════════════════════════════════════════════════════════

/// SHA-256 hash chain computation for decision trace entries.
///
/// Matches the Python `DecisionTraceLogger._compute_current_hash()` signature.
/// Canonical field order:
///   previous_hash|trace_id|transaction_id|context_json|verdict_json|
///   calculation_input|calculation_output|invariants_result|risk_verdict|timestamp
#[pyclass(name = "DecisionTraceHasher")]
pub struct DecisionTraceHasher;

#[pymethods]
impl DecisionTraceHasher {
    /// Compute the current SHA-256 hash for a decision trace entry.
    #[staticmethod]
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
    fn compute_hash(
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
            "DecisionTraceHasher.compute_hash: trace={}, tx={}",
            trace_id,
            transaction_id
        );
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
    #[staticmethod]
    fn genesis_hash() -> String {
        GENESIS_HASH.to_string()
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AuditParams — optional audit trail metadata
// ═══════════════════════════════════════════════════════════════════════════════

/// Optional audit trail parameters for pipeline results.
///
/// Contains verbose JSON strings needed only for audit logging.
/// When audit is not requested, this is `None` to reduce memory overhead.
///
/// Fields:
///   - current_hash: SHA-256 of the audit hash chain entry
///   - context_json: Flat context dict (from ContextInterpreter.build)
///   - verdict_json: Enriched verdict dict (from rule evaluation)
///   - evaluated_rules_json: All rules with their evaluation results
#[pyclass(name = "AuditParams")]
#[derive(Clone, Debug)]
pub struct AuditParams {
    #[pyo3(get)]
    pub current_hash: String,
    #[pyo3(get)]
    pub context_json: String,
    #[pyo3(get)]
    pub verdict_json: String,
    #[pyo3(get)]
    pub evaluated_rules_json: String,
}

#[pymethods]
impl AuditParams {
    #[new]
    pub fn new(
        current_hash: String,
        context_json: String,
        verdict_json: String,
        evaluated_rules_json: String,
    ) -> Self {
        AuditParams {
            current_hash,
            context_json,
            verdict_json,
            evaluated_rules_json,
        }
    }

    fn __repr__(&self) -> String {
        format!(
            "AuditParams(hash={}..., ctx={}B, verdict={}B, rules={}B)",
            &self.current_hash[..16.min(self.current_hash.len())],
            self.context_json.len(),
            self.verdict_json.len(),
            self.evaluated_rules_json.len(),
        )
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PipelineComputeResult — pure computation result (no I/O), optimized 14+4 fields
// ═══════════════════════════════════════════════════════════════════════════════

/// Result of the synchronous pipeline computation (context + rules + math + invariants).
///
/// **Core fields (14):** is_valid, error_message, netto/vat/brutto grosze,
/// positions, calculation JSONs, matched rule, routing, parsed values.
///
/// **Audit fields (4 in optional AuditParams):** current_hash, context_json,
/// verdict_json, evaluated_rules_json — populated only when audit requested.
///
/// Returned by `compute_pipeline()` and consumed by Python
/// `TaxPipeline.process_invoice()` for async I/O (TigerBeetle, events).
#[pyclass(name = "PipelineComputeResult")]
#[derive(Clone, Debug)]
pub struct PipelineComputeResult {
    #[pyo3(get)]
    pub is_valid: bool,
    #[pyo3(get)]
    pub error_message: String,
    #[pyo3(get)]
    pub netto_grosze: i64,
    #[pyo3(get)]
    pub vat_grosze: i64,
    #[pyo3(get)]
    pub brutto_grosze: i64,
    #[pyo3(get)]
    pub positions_net_grosze: Vec<i64>,
    #[pyo3(get)]
    pub calculation_input_json: String,
    #[pyo3(get)]
    pub calculation_output_json: String,
    #[pyo3(get)]
    pub invariants_result_json: String,
    /// Optional audit trail metadata (None when audit not requested).
    #[pyo3(get)]
    pub audit_params: Option<AuditParams>,
    /// Rule ID of the matched rule (empty if no match).
    #[pyo3(get)]
    pub matched_rule_id: String,
    /// Routing action from verdict (BLOCK_AND_ALERT, TRIAGE_QUEUE, or empty).
    #[pyo3(get)]
    pub routing: String,
    /// Routing reason.
    #[pyo3(get)]
    pub routing_reason: String,
    /// Parsed VAT rate from verdict.
    #[pyo3(get)]
    pub parsed_vat_rate: String,
    /// Parsed rounding level from verdict.
    #[pyo3(get)]
    pub parsed_rounding_level: String,
}

#[pymethods]
impl PipelineComputeResult {
    #[new]
    #[pyo3(signature = (
        is_valid,
        error_message,
        netto_grosze,
        vat_grosze,
        brutto_grosze,
        positions_net_grosze,
        calculation_input_json,
        calculation_output_json,
        invariants_result_json,
        audit_params = None,
        matched_rule_id = "".to_string(),
        routing = "".to_string(),
        routing_reason = "".to_string(),
        parsed_vat_rate = "".to_string(),
        parsed_rounding_level = "".to_string(),
    ))]
    #[allow(clippy::too_many_arguments)]
    pub fn new(
        is_valid: bool,
        error_message: String,
        netto_grosze: i64,
        vat_grosze: i64,
        brutto_grosze: i64,
        positions_net_grosze: Vec<i64>,
        calculation_input_json: String,
        calculation_output_json: String,
        invariants_result_json: String,
        audit_params: Option<AuditParams>,
        matched_rule_id: String,
        routing: String,
        routing_reason: String,
        parsed_vat_rate: String,
        parsed_rounding_level: String,
    ) -> Self {
        PipelineComputeResult {
            is_valid,
            error_message,
            netto_grosze,
            vat_grosze,
            brutto_grosze,
            positions_net_grosze,
            calculation_input_json,
            calculation_output_json,
            invariants_result_json,
            audit_params,
            matched_rule_id,
            routing,
            routing_reason,
            parsed_vat_rate,
            parsed_rounding_level,
        }
    }

    fn __repr__(&self) -> String {
        format!(
            "PipelineComputeResult(valid={}, net={} gr, vat={} gr, brutto={} gr, rule={}, audit={})",
            self.is_valid,
            self.netto_grosze,
            self.vat_grosze,
            self.brutto_grosze,
            self.matched_rule_id,
            self.audit_params.is_some(),
        )
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// compute_pipeline — main synchronous compute function (math + invariants only)
// ═══════════════════════════════════════════════════════════════════════════════

/// Perform the synchronous tax pipeline computation (math + invariants + audit).
///
/// This is the CORE COMPUTE step — it assumes context and rules have already
/// been evaluated. Use `run_full_pipeline()` to execute all 5 steps.
///
/// Steps executed:
///   1. Parse and validate VAT rate and rounding level.
///   2. Convert positions to grosze (integer) via tax::to_grosze.
///   3. Calculate VAT per policy (position or total rounding).
///   4. Build InvoiceSummary with netto, vat, brutto in grosze.
///   5. Validate all three mathematical invariants.
///   6. (Optional) Compute SHA-256 current_hash for audit trail.
///   7. Serialize computation metadata to JSON using serde_json.
///   8. Return PipelineComputeResult with all computed values.
#[pyfunction]
#[pyo3(signature = (
    vat_rate,
    rounding_level,
    positions_net_str,
    previous_hash = None,
    context_json = None,
    verdict_json = None,
    trace_id = None,
    transaction_id = None,
    timestamp_iso = None,
))]
pub fn compute_pipeline(
    vat_rate: &str,
    rounding_level: &str,
    positions_net_str: Vec<String>,
    previous_hash: Option<String>,
    context_json: Option<String>,
    verdict_json: Option<String>,
    trace_id: Option<String>,
    transaction_id: Option<String>,
    timestamp_iso: Option<String>,
) -> PyResult<PipelineComputeResult> {
    log::info!(
        "compute_pipeline: rate={}, rounding={}, {} positions, audit={}",
        vat_rate,
        rounding_level,
        positions_net_str.len(),
        previous_hash.is_some(),
    );

    // Parse VAT rate once
    let rate_decimal = Decimal::from_str(vat_rate).map_err(|e| {
        PyValueError::new_err(format!("Invalid VAT rate: {vat_rate:?}: {e}"))
    })?;

    // ── Step 1: Convert positions to grosze ──────────────────────────
    let mut positions_net_grosze: Vec<i64> = Vec::with_capacity(positions_net_str.len());
    for net_str in &positions_net_str {
        let net_grosze = tax::to_grosze(net_str)?;
        positions_net_grosze.push(net_grosze);
    }

    // ── Step 2: Calculate VAT per rounding policy ────────────────────
    let total_vat_grosze = match rounding_level {
        "position" => {
            let mut total: i64 = 0;
            for &net_gr in &positions_net_grosze {
                let net = Decimal::from_i64(net_gr).unwrap();
                let vat = (net * rate_decimal).round_dp_with_strategy(0, ROUND_HALF_UP);
                total += vat.to_i64().unwrap_or(0);
            }
            total
        }
        "total" => {
            let total_net: i64 = positions_net_grosze.iter().sum();
            let net = Decimal::from_i64(total_net).unwrap();
            let vat = (net * rate_decimal).round_dp_with_strategy(0, ROUND_HALF_UP);
            vat.to_i64().unwrap_or(0)
        }
        _ => {
            return Err(PyValueError::new_err(format!(
                "Unknown rounding_level: {rounding_level:?}; expected 'position' or 'total'"
            )));
        }
    };

    // ── Step 3 & 4: Calculate totals and build Summary ────────────────
    let total_net_grosze: i64 = positions_net_grosze.iter().sum();
    let total_brutto_grosze = total_net_grosze + total_vat_grosze;

    let summary = tax::InvoiceSummary {
        netto_grosze: total_net_grosze,
        vat_grosze: total_vat_grosze,
        brutto_grosze: total_brutto_grosze,
    };

    log::debug!(
        "compute_pipeline: net={} gr, vat={} gr, brutto={} gr",
        total_net_grosze,
        total_vat_grosze,
        total_brutto_grosze,
    );

    // ── Step 5: Validate three invariants ─────────────────────────────
    let mut errors: Vec<String> = Vec::new();

    // Invariant 1: sum(positions.net_grosze) == summary.netto_grosze
    if total_net_grosze != summary.netto_grosze {
        errors.push(format!(
            "Invariant 1: sum(position netto)={} gr != summary netto={} gr",
            total_net_grosze, summary.netto_grosze
        ));
    }

    // Invariant 2: sum(positions.vat_grosze) == summary.vat_grosze
    let mut sum_vat: i64 = 0;
    for &net_gr in &positions_net_grosze {
        let net = Decimal::from_i64(net_gr).unwrap();
        let vat = (net * rate_decimal).round_dp_with_strategy(0, ROUND_HALF_UP);
        sum_vat += vat.to_i64().unwrap_or(0);
    }
    if sum_vat != summary.vat_grosze {
        errors.push(format!(
            "Invariant 2: sum(position VAT)={} gr != summary VAT={} gr",
            sum_vat, summary.vat_grosze
        ));
    }

    // Invariant 3: netto_grosze + vat_grosze == brutto_grosze
    let calc_brutto = summary.netto_grosze + summary.vat_grosze;
    if calc_brutto != summary.brutto_grosze {
        errors.push(format!(
            "Invariant 3: netto ({} gr) + VAT ({} gr) = {} gr != brutto ({} gr)",
            summary.netto_grosze, summary.vat_grosze,
            calc_brutto, summary.brutto_grosze
        ));
    }

    let is_valid = errors.is_empty();
    let error_message = if is_valid { String::new() } else { errors.join("; ") };

    log::info!(
        "compute_pipeline: invariants {} ({} errors)",
        if is_valid { "PASS" } else { "FAIL" },
        errors.len()
    );

    // ── Step 6: Serialize metadata to JSON ─────────────────────────────
    let calc_input = serde_json::to_string(&json!({
        "positions_net_grosze": positions_net_grosze.clone(),
        "vat_rate": vat_rate,
        "rounding_level": rounding_level,
    })).expect("infallible json");

    let calc_output = serde_json::to_string(&json!({
        "netto_grosze": total_net_grosze,
        "vat_grosze": total_vat_grosze,
        "brutto_grosze": total_brutto_grosze,
    })).expect("infallible json");

    let inv_result = serde_json::to_string(&json!({
        "is_valid": is_valid,
        "error_message": &error_message,
    })).expect("infallible json");

    // ── Step 7: Compute audit trail hash ───────────────────────────────
    let ctx_default = "{}".to_string();
    let v_default = "{}".to_string();
    let ctx = context_json.as_ref().unwrap_or(&ctx_default);
    let v_json = verdict_json.as_ref().unwrap_or(&v_default);

    let audit_params = if let (
        Some(prev_hash),
        Some(t_id),
        Some(tx_id),
        Some(ts_iso),
    ) = (&previous_hash, &trace_id, &transaction_id, &timestamp_iso) {
        let hash = DecisionTraceHasher::compute_hash(
            prev_hash, t_id, tx_id, ctx, v_json, ts_iso,
            &calc_input, &calc_output, &inv_result, "",
        );
        Some(AuditParams {
            current_hash: hash,
            context_json: ctx.clone(),
            verdict_json: v_json.clone(),
            evaluated_rules_json: String::new(),
        })
    } else {
        None
    };

    Ok(PipelineComputeResult {
        is_valid,
        error_message,
        netto_grosze: total_net_grosze,
        vat_grosze: total_vat_grosze,
        brutto_grosze: total_brutto_grosze,
        positions_net_grosze,
        calculation_input_json: calc_input,
        calculation_output_json: calc_output,
        invariants_result_json: inv_result,
        audit_params,
        matched_rule_id: String::new(),
        routing: String::new(),
        routing_reason: String::new(),
        parsed_vat_rate: vat_rate.to_string(),
        parsed_rounding_level: rounding_level.to_string(),
    })
}

// ═══════════════════════════════════════════════════════════════════════════════
// Full Pipeline: context → rules → math → invariants → audit
// ═══════════════════════════════════════════════════════════════════════════════

/// Run the COMPLETE synchronous tax pipeline (all 5 steps) in Rust.
///
/// Steps executed:
///   1. ContextInterpreter.build() — build flat context from invoice data
///   2. RuleEngine.evaluate() — first-match-wins against rules JSON
///   3. TaxMathEngine — VAT calculation in grosze
///   4. InvariantGuard — three mathematical invariants
///   5. AuditHashChain — SHA-256 hash for decision trace
///
/// Args:
///     invoice_data_json: JSON string with invoice fields (see ContextInterpreter.build).
///     rules_json: JSON array of rule objects (pre-loaded from DuckDB by Python):
///         [{"rule_id": str, "condition_sql": str, "action_json": str, "priority": int}, ...]
///     previous_hash: Optional SHA-256 hash of the previous audit entry.
///     trace_id: Optional trace UUID.
///     transaction_id: Optional transaction UUID.
///     timestamp_iso: Optional ISO timestamp.
///
/// Returns:
///     PipelineComputeResult with all computed values including context, verdict,
///     evaluated rules, VAT calculation, invariants, and audit hash.
#[pyfunction]
#[pyo3(signature = (
    invoice_data_json,
    rules_json,
    previous_hash = None,
    trace_id = None,
    transaction_id = None,
    timestamp_iso = None,
))]
fn run_full_pipeline(
    invoice_data_json: &str,
    rules_json: &str,
    previous_hash: Option<String>,
    trace_id: Option<String>,
    transaction_id: Option<String>,
    timestamp_iso: Option<String>,
) -> PyResult<PipelineComputeResult> {
    log::info!("run_full_pipeline: starting all 5 steps");

    // ── Step 1: ContextInterpreter ──────────────────────────────────────
    let context_json = ContextInterpreter::build(invoice_data_json)?;
    log::debug!("run_full_pipeline: step 1 (context) done");

    // ── Step 2: Rule Engine ─────────────────────────────────────────────
    let rule_result = evaluate_rules_inner(rules_json, &context_json)?;
    let rule_result_value: Value = serde_json::from_str(&rule_result)
        .map_err(|e| PyValueError::new_err(format!("Invalid rule result JSON: {e}")))?;

    let matched = rule_result_value["matched"].as_bool().unwrap_or(false);
    let evaluated_rules_json = rule_result_value["evaluated_rules_json"]
        .as_str()
        .unwrap_or("[]")
        .to_string();

    if !matched {
        let error = rule_result_value["error"]
            .as_str()
            .unwrap_or("No matching rule");
        log::warn!("run_full_pipeline: step 2 (rules) — no match: {error}");
        return Ok(PipelineComputeResult {
            is_valid: false,
            error_message: format!("NO_MATCHING_RULE: {error}"),
            netto_grosze: 0,
            vat_grosze: 0,
            brutto_grosze: 0,
            positions_net_grosze: Vec::new(),
            calculation_input_json: String::new(),
            calculation_output_json: String::new(),
            invariants_result_json: String::new(),
            audit_params: Some(AuditParams {
                current_hash: String::new(),
                context_json,
                verdict_json: String::new(),
                evaluated_rules_json,
            }),
            matched_rule_id: String::new(),
            routing: String::new(),
            routing_reason: String::new(),
            parsed_vat_rate: String::new(),
            parsed_rounding_level: String::new(),
        });
    }

    let verdict = &rule_result_value["verdict"];
    let verdict_json = serde_json::to_string(verdict).expect("infallible json");
    let matched_rule_id = rule_result_value["rule_id"].as_str().unwrap_or("").to_string();

    // Extract fields from verdict
    let vat_rate = verdict["vat_rate"].as_str().unwrap_or("0.23");
    let rounding_level = verdict["rounding_level"].as_str().unwrap_or("position");
    let routing = verdict["_routing"].as_str().unwrap_or("");
    let routing_reason = verdict["_routing_reason"].as_str().unwrap_or("");

    log::info!(
        "run_full_pipeline: step 2 (rules) matched rule={}, vat={}, rounding={}",
        matched_rule_id, vat_rate, rounding_level,
    );

    // Extract positions from invoice data
    let invoice_data: Value = serde_json::from_str(invoice_data_json)
        .map_err(|e| PyValueError::new_err(format!("Invalid invoice_data JSON: {e}")))?;

    let positions = match invoice_data.get("positions") {
        Some(Value::Array(arr)) => {
            let mut net_strs: Vec<String> = Vec::with_capacity(arr.len());
            for pos in arr {
                let net = pos.get("net_amount")
                    .or_else(|| pos.get("net_amount_grosze"))
                    .map(|v| match v {
                        Value::String(s) => s.clone(),
                        Value::Number(n) => n.to_string(),
                        _ => "0".to_string(),
                    })
                    .unwrap_or_else(|| "0".to_string());
                net_strs.push(net);
            }
            net_strs
        }
        _ => {
            // Single-line invoice: use amount_net
            let single_net = match invoice_data.get("amount_net") {
                Some(Value::String(s)) => s.clone(),
                Some(Value::Number(n)) => n.to_string(),
                _ => "0".to_string(),
            };
            vec![single_net]
        }
    };

    log::debug!(
        "run_full_pipeline: step 3 (math) with {} positions",
        positions.len()
    );

    // ── Steps 3-5: compute_pipeline (math + invariants + audit) ─────────
    let result = compute_pipeline(
        vat_rate,
        rounding_level,
        positions,
        previous_hash,
        Some(context_json.clone()),
        Some(verdict_json.clone()),
        trace_id,
        transaction_id,
        timestamp_iso,
    )?;

    // Enrich result with context, verdict, evaluated rules
    // Build audit_params with full context + verdict + evaluated_rules
    let current_hash = result.audit_params.as_ref()
        .map(|a| a.current_hash.clone())
        .unwrap_or_default();

    let enriched_audit = Some(AuditParams {
        current_hash,
        context_json,
        verdict_json,
        evaluated_rules_json,
    });

    Ok(PipelineComputeResult {
        audit_params: enriched_audit,
        matched_rule_id,
        routing: routing.to_string(),
        routing_reason: routing_reason.to_string(),
        parsed_vat_rate: vat_rate.to_string(),
        parsed_rounding_level: rounding_level.to_string(),
        ..result
    })
}

// ═══════════════════════════════════════════════════════════════════════════════
// Module registration
// ═══════════════════════════════════════════════════════════════════════════════

pub fn register(module: &Bound<'_, PyModule>) -> PyResult<()> {
    module.add_class::<DecisionTraceHasher>()?;
    module.add_class::<AuditParams>()?;
    module.add_class::<PipelineComputeResult>()?;
    module.add_class::<ContextInterpreter>()?;
    module.add_function(wrap_pyfunction!(compute_pipeline, module)?)?;
    module.add_function(wrap_pyfunction!(evaluate_rules, module)?)?;
    module.add_function(wrap_pyfunction!(run_full_pipeline, module)?)?;
    log::info!(
        "tax_pipeline: registered ContextInterpreter, DecisionTraceHasher, AuditParams, \
         PipelineComputeResult, compute_pipeline, evaluate_rules, run_full_pipeline"
    );
    Ok(())
}
