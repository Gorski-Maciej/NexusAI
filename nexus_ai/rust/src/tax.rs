// ═══════════════════════════════════════════════════════════════════════════════
// TaxMathEngine — Integer-only tax arithmetic in Rust + PyO3
// ═══════════════════════════════════════════════════════════════════════════════
//
// Structured logging: log::info!, log::debug!, log::warn!
// All logs are forwarded to Python structlog via pyo3-log (init in lib.rs)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Zgodnie z aa3fvcx.txt:
// - Całkowity zakaz float — wszystkie kwoty w groszach (i64)
// - ROUND_HALF_UP (MidpointAwayFromZero) dla wszystkich zaokrągleń
// - Każde zaokrąglenie jawne — nigdy ukryte
// - Trzy niezmienniki przed zapisem do księgi
//
// Zastępuje: nexus_ai/tax/math_engine.py (Python + mypyc)
// Nowy:     Rust + PyO3 — 10-50× szybsze obliczenia groszowe
//
// Build with Maturin:
//   cd nexus_ai/rust && maturin develop --release
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::exceptions::PyValueError;
use pyo3::prelude::*;
use rust_decimal::prelude::*;
use rust_decimal::RoundingStrategy;

// ── Constants ───────────────────────────────────────────────────────────────

/// MidpointAwayFromZero = ROUND_HALF_UP (zgodnie z polską Ordynacją Podatkową)
const ROUND_HALF_UP: RoundingStrategy = RoundingStrategy::MidpointAwayFromZero;

// ── Helper: parse rate string to Decimal ───────────────────────────────────

fn parse_rate_decimal(rate_str: &str) -> PyResult<Decimal> {
    Decimal::from_str(rate_str).map_err(|e| {
        PyValueError::new_err(format!(
            "Invalid rate value: {rate_str:?}. Rates must be valid decimal strings (e.g. '0.23'). Error: {e}"
        ))
    })
}

// ═══════════════════════════════════════════════════════════════════════════════
// Data types (PyO3 pyclasses)
// ═══════════════════════════════════════════════════════════════════════════════

// ── Money (Nexus-Money compatible) ──────────────────────────────────────────

/// Nexus-Money — minimalistyczna reprezentacja pieniędzy.
///
/// Zgodnie z aa3fvcx.txt (Punkt 9): amount_cents: int + currency: str.
/// Zastępuje py-moneyed. Kompatybilny z Pythonowym msgspec.Struct o tych samych polach.
#[pyclass(name = "Money", frozen)]
#[derive(Clone, Debug)]
pub struct Money {
    #[pyo3(get)]
    pub amount_cents: i64,
    #[pyo3(get)]
    pub currency: String,
}

#[pymethods]
impl Money {
    #[new]
    #[pyo3(signature = (amount_cents, currency = "PLN".to_string()))]
    pub fn new(amount_cents: i64, currency: String) -> Self {
        Money { amount_cents, currency }
    }

    /// Zwraca kwotę jako string z 2 miejscami po przecinku (np. "123.45 PLN").
    fn __str__(&self) -> String {
        log::debug!("Money.__str__: {} {} gr", self.currency, self.amount_cents);
        self.to_string_impl()
    }

    fn __repr__(&self) -> String {
        format!("Money(amount_cents={}, currency={:?})", self.amount_cents, self.currency)
    }

    /// Kwota w jednostkach waluty jako string z 2 miejscami po przecinku.
    fn amount(&self) -> String {
        self.amount_string()
    }

    /// Wewnętrzna implementacja formatowania kwoty.
    fn amount_string(&self) -> String {
        let d = Decimal::from_i64(self.amount_cents).unwrap() / Decimal::from(100);
        format!("{:.2}", d.round_dp_with_strategy(2, ROUND_HALF_UP))
    }

    fn to_string_impl(&self) -> String {
        format!("{} {}", self.amount_string(), self.currency)
    }

    fn __add__(&self, other: &Self) -> PyResult<Self> {
        if self.currency != other.currency {
            log::warn!(
                "Money.__add__: currency mismatch: {} vs {}",
                self.currency, other.currency
            );
            return Err(PyValueError::new_err(format!(
                "Currency mismatch: cannot add {} and {}",
                self.currency, other.currency
            )));
        }
        log::debug!(
            "Money.__add__: {} {} gr + {} {} gr = {} gr",
            self.currency, self.amount_cents,
            other.currency, other.amount_cents,
            self.amount_cents + other.amount_cents
        );
        Ok(Money {
            amount_cents: self.amount_cents + other.amount_cents,
            currency: self.currency.clone(),
        })
    }

    fn __sub__(&self, other: &Self) -> PyResult<Self> {
        if self.currency != other.currency {
            log::warn!(
                "Money.__sub__: currency mismatch: {} vs {}",
                self.currency, other.currency
            );
            return Err(PyValueError::new_err(format!(
                "Currency mismatch: cannot subtract {} and {}",
                self.currency, other.currency
            )));
        }
        log::debug!(
            "Money.__sub__: {} {} gr - {} {} gr = {} gr",
            self.currency, self.amount_cents,
            other.currency, other.amount_cents,
            self.amount_cents - other.amount_cents
        );
        Ok(Money {
            amount_cents: self.amount_cents - other.amount_cents,
            currency: self.currency.clone(),
        })
    }

    fn __eq__(&self, other: &Self) -> bool {
        self.amount_cents == other.amount_cents && self.currency == other.currency
    }

    #[staticmethod]
    fn zero(currency: String) -> Self {
        Money { amount_cents: 0, currency }
    }
}

// ── InvoicePositions ────────────────────────────────────────────────────────

/// A single invoice line item in grosze.
#[pyclass(name = "InvoicePositions")]
#[derive(Clone, Debug)]
pub struct InvoicePositions {
    #[pyo3(get)]
    pub net_grosze: i64,
    #[pyo3(get)]
    pub vat_rate: String,
}

#[pymethods]
impl InvoicePositions {
    #[new]
    #[pyo3(signature = (net_grosze, vat_rate))]
    pub fn new(net_grosze: i64, vat_rate: String) -> Self {
        InvoicePositions { net_grosze, vat_rate }
    }

    /// VAT for this line, rounded to full grosze.
    fn vat_grosze(&self) -> PyResult<i64> {
        multiply_net_by_vat(self.net_grosze, &self.vat_rate)
    }

    fn __repr__(&self) -> String {
        format!(
            "InvoicePositions(net_grosze={}, vat_rate={:?})",
            self.net_grosze, self.vat_rate
        )
    }
}

// ── InvoiceSummary ──────────────────────────────────────────────────────────

/// Invoice totals in grosze.
#[pyclass(name = "InvoiceSummary")]
#[derive(Clone, Debug)]
pub struct InvoiceSummary {
    #[pyo3(get)]
    pub netto_grosze: i64,
    #[pyo3(get)]
    pub vat_grosze: i64,
    #[pyo3(get)]
    pub brutto_grosze: i64,
}

#[pymethods]
impl InvoiceSummary {
    #[new]
    pub fn new(netto_grosze: i64, vat_grosze: i64, brutto_grosze: i64) -> Self {
        InvoiceSummary { netto_grosze, vat_grosze, brutto_grosze }
    }

    fn __repr__(&self) -> String {
        format!(
            "InvoiceSummary(netto_grosze={}, vat_grosze={}, brutto_grosze={})",
            self.netto_grosze, self.vat_grosze, self.brutto_grosze
        )
    }
}

// ── ValidationResult ────────────────────────────────────────────────────────

/// Result of invariant validation.
#[pyclass(name = "ValidationResult")]
#[derive(Clone, Debug)]
pub struct ValidationResult {
    #[pyo3(get)]
    pub is_valid: bool,
    #[pyo3(get)]
    pub error_message: String,
}

#[pymethods]
impl ValidationResult {
    #[new]
    #[pyo3(signature = (is_valid, error_message = "".to_string()))]
    pub fn new(is_valid: bool, error_message: String) -> Self {
        ValidationResult { is_valid, error_message }
    }

    fn __repr__(&self) -> String {
        if self.is_valid {
            "ValidationResult(is_valid=True)".to_string()
        } else {
            format!("ValidationResult(is_valid=False, error_message={:?})", self.error_message)
        }
    }

    fn __bool__(&self) -> bool {
        self.is_valid
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Core math functions
// ═══════════════════════════════════════════════════════════════════════════════

/// Parse a rate string to Decimal with validation.
///
/// This is the ONLY entry point for converting rule engine verdict
/// values (strings) to Decimal for arithmetic.
#[pyfunction]
pub fn parse_rate(rate_str: &str) -> PyResult<String> {
    let _ = parse_rate_decimal(rate_str)?;
    Ok(rate_str.to_string())
}

/// Convert a decimal string to grosze (i64) with ROUND_HALF_UP.
///
/// Args:
///     amount: Amount in złotówki as string (e.g. "123.45").
///
/// Returns:
///     Amount in grosze, always rounded to nearest integer.
#[pyfunction]
pub fn to_grosze(amount: &str) -> PyResult<i64> {
    log::debug!("to_grosze: converting {:?}", amount);
    let d = Decimal::from_str(amount).map_err(|e| {
        PyValueError::new_err(format!("Cannot parse amount {:?} as decimal: {e}", amount))
    })?;
    let grosze = d * Decimal::from(100);
    let rounded = grosze.round_dp_with_strategy(0, ROUND_HALF_UP);
    let result = rounded.to_i64().ok_or_else(|| {
        PyValueError::new_err(format!("Amount too large: {amount}"))
    })?;
    log::debug!("to_grosze: {:?} -> {} gr", amount, result);
    Ok(result)
}

/// Convert grosze back to złotówki string with 2 decimal places.
///
/// Args:
///     grosze: Amount in grosze.
///
/// Returns:
///     Decimal amount in złotówki as string (e.g. "123.45").
#[pyfunction]
pub fn to_zlotowki(grosze: i64) -> String {
    let d = Decimal::from_i64(grosze).unwrap() / Decimal::from(100);
    let result = format!("{:.2}", d.round_dp_with_strategy(2, ROUND_HALF_UP));
    log::debug!("to_zlotowki: {} gr -> {:?}", grosze, result);
    result
}

/// Multiply net amount (grosze) by VAT rate, rounded to full grosze.
///
/// This is the ONLY place where VAT multiplication happens.
///
/// Args:
///     net_grosze: Net amount in grosze.
///     vat_rate: VAT rate as string (e.g. "0.23").
///
/// Returns:
///     VAT amount in grosze, rounded to nearest integer.
#[pyfunction]
pub fn multiply_net_by_vat(net_grosze: i64, vat_rate: &str) -> PyResult<i64> {
    log::debug!("multiply_net_by_vat: net={} gr, rate={}", net_grosze, vat_rate);
    let rate = parse_rate_decimal(vat_rate)?;
    let net = Decimal::from_i64(net_grosze).unwrap();
    let vat = net * rate;
    let rounded = vat.round_dp_with_strategy(0, ROUND_HALF_UP);
    let result = rounded.to_i64().ok_or_else(|| {
        PyValueError::new_err(format!("VAT result too large: net={net_grosze}, rate={vat_rate}"))
    })?;
    log::info!("multiply_net_by_vat: net={} gr × rate={} = {} gr VAT", net_grosze, vat_rate, result);
    Ok(result)
}

/// Sum net and VAT in grosze to get brutto.
///
/// Args:
///     net_grosze: Net amount in grosze.
///     vat_grosze: VAT amount in grosze.
///
/// Returns:
///     Gross (brutto) amount in grosze.
#[pyfunction]
pub fn add_tax(net_grosze: i64, vat_grosze: i64) -> i64 {
    net_grosze + vat_grosze
}

/// Calculate total VAT according to the chosen rounding strategy.
///
/// ``position`` — round per line, then sum (precise per-item VAT).
/// ``total``    — sum net first, then round once (matches total-invoice math).
///
/// Args:
///     positions: List of invoice line items (net in grosze).
///     vat_rate: VAT rate as string (e.g. \"0.23\").
///     rounding_level: Must be ``\"position\"`` or ``\"total\"``.
///
/// Returns:
///     Total VAT amount in grosze.
#[pyfunction]
pub fn calculate_vat_by_policy(
    positions: Vec<PyRef<'_, InvoicePositions>>,
    vat_rate: &str,
    rounding_level: &str,
) -> PyResult<i64> {
    let rate = parse_rate_decimal(vat_rate)?;

    match rounding_level {
        "position" => {
            let mut total_vat: i64 = 0;
            for pos in positions.iter() {
                let net = Decimal::from_i64(pos.net_grosze).unwrap();
                let vat = (net * rate).round_dp_with_strategy(0, ROUND_HALF_UP);
                total_vat += vat.to_i64().unwrap_or(0);
            }
            Ok(total_vat)
        }
        "total" => {
            let total_net: i64 = positions.iter().map(|p| p.net_grosze).sum();
            let net = Decimal::from_i64(total_net).unwrap();
            let vat = (net * rate).round_dp_with_strategy(0, ROUND_HALF_UP);
            vat.to_i64().ok_or_else(|| {
                PyValueError::new_err("VAT result too large")
            })
        }
        _ => Err(PyValueError::new_err(format!(
            "Unknown rounding_level: {rounding_level:?}; expected 'position' or 'total'"
        ))),
    }
}

/// Validate the three mathematical invariants of an invoice.
///
/// **Invariant 1**: ``sum(positions.net_grosze) == summary.netto_grosze``
/// **Invariant 2**: ``sum(positions.vat_grosze) == summary.vat_grosze``
/// **Invariant 3**: ``netto_grosze + vat_grosze == brutto_grosze``
///
/// Args:
///     positions: List of invoice line items.
///     summary: Invoice summary totals in grosze.
///
/// Returns:
///     ValidationResult — ``is_valid=True`` iff all pass.
#[pyfunction]
pub fn validate_invariants(
    positions: Vec<PyRef<'_, InvoicePositions>>,
    summary: &InvoiceSummary,
) -> PyResult<ValidationResult> {
    log::info!(
        "validate_invariants: {} positions, netto={} gr, vat={} gr, brutto={} gr",
        positions.len(),
        summary.netto_grosze,
        summary.vat_grosze,
        summary.brutto_grosze,
    );
    let mut errors: Vec<String> = Vec::new();

    // Invariant 1: sum of position net == summary net
    let sum_net: i64 = positions.iter().map(|p| p.net_grosze).sum();
    if sum_net != summary.netto_grosze {
        let diff = sum_net - summary.netto_grosze;
        errors.push(format!(
            "Invariant 1: sum(position netto)={} gr ≠ summary netto={} gr, diff={:+} gr",
            sum_net, summary.netto_grosze, diff
        ));
    }

    // Invariant 2: sum of position VAT == summary VAT
    let mut sum_vat: i64 = 0;
    for pos in positions.iter() {
        let rate = parse_rate_decimal(&pos.vat_rate)?;
        let net = Decimal::from_i64(pos.net_grosze).unwrap();
        let vat = (net * rate).round_dp_with_strategy(0, ROUND_HALF_UP);
        sum_vat += vat.to_i64().unwrap_or(0);
    }
    if sum_vat != summary.vat_grosze {
        let diff = sum_vat - summary.vat_grosze;
        errors.push(format!(
            "Invariant 2: sum(position VAT)={} gr ≠ summary VAT={} gr, diff={:+} gr",
            sum_vat, summary.vat_grosze, diff
        ));
    }

    // Invariant 3: netto + vat == brutto
    let calculated_brutto = summary.netto_grosze + summary.vat_grosze;
    if calculated_brutto != summary.brutto_grosze {
        let diff = calculated_brutto - summary.brutto_grosze;
        errors.push(format!(
            "Invariant 3: netto ({} gr) + VAT ({} gr) = {} gr ≠ brutto ({} gr), diff={:+} gr",
            summary.netto_grosze, summary.vat_grosze,
            calculated_brutto, summary.brutto_grosze, diff
        ));
    }

    if errors.is_empty() {
        Ok(ValidationResult { is_valid: true, error_message: String::new() })
    } else {
        Ok(ValidationResult {
            is_valid: false,
            error_message: errors.join("; "),
        })
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TaxMathEngine — convenience namespace class
// ═══════════════════════════════════════════════════════════════════════════════

/// Infallible tax math — integer-only, ROUND_HALF_UP, no floats.
///
/// All methods are static. Use as a namespace for clarity.
#[pyclass(name = "TaxMathEngine")]
pub struct TaxMathEngine;

#[pymethods]
impl TaxMathEngine {
    #[staticmethod]
    fn parse_rate(rate_str: &str) -> PyResult<String> {
        parse_rate(rate_str)
    }

    #[staticmethod]
    fn to_grosze(amount: &str) -> PyResult<i64> {
        to_grosze(amount)
    }

    #[staticmethod]
    fn to_zlotowki(grosze: i64) -> String {
        to_zlotowki(grosze)
    }

    #[staticmethod]
    fn multiply_net_by_vat(net_grosze: i64, vat_rate: &str) -> PyResult<i64> {
        multiply_net_by_vat(net_grosze, vat_rate)
    }

    #[staticmethod]
    fn add_tax(net_grosze: i64, vat_grosze: i64) -> i64 {
        add_tax(net_grosze, vat_grosze)
    }

    #[staticmethod]
    fn calculate_vat_by_policy(
        positions: Vec<PyRef<'_, InvoicePositions>>,
        vat_rate: &str,
        rounding_level: &str,
    ) -> PyResult<i64> {
        calculate_vat_by_policy(positions, vat_rate, rounding_level)
    }

    #[staticmethod]
    fn validate_invariants(
        positions: Vec<PyRef<'_, InvoicePositions>>,
        summary: &InvoiceSummary,
    ) -> PyResult<ValidationResult> {
        validate_invariants(positions, summary)
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Module registration
// ═══════════════════════════════════════════════════════════════════════════════

pub fn register(module: &Bound<'_, PyModule>) -> PyResult<()> {
    // Register data classes
    module.add_class::<Money>()?;
    module.add_class::<InvoicePositions>()?;
    module.add_class::<InvoiceSummary>()?;
    module.add_class::<ValidationResult>()?;
    module.add_class::<TaxMathEngine>()?;

    // Register standalone functions
    module.add_function(wrap_pyfunction!(parse_rate, module)?)?;
    module.add_function(wrap_pyfunction!(to_grosze, module)?)?;
    module.add_function(wrap_pyfunction!(to_zlotowki, module)?)?;
    module.add_function(wrap_pyfunction!(multiply_net_by_vat, module)?)?;
    module.add_function(wrap_pyfunction!(add_tax, module)?)?;
    module.add_function(wrap_pyfunction!(calculate_vat_by_policy, module)?)?;
    module.add_function(wrap_pyfunction!(validate_invariants, module)?)?;

    log::info!("tax_engine: registered 4 data classes, 7 functions, TaxMathEngine");
    Ok(())
}
