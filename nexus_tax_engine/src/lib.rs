/// ═══════════════════════════════════════════════════════════════════════════════
/// Nexus-TaxEngine — Native Rust tax computation engine for NexusAI
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// Zastępuje Pythonowe TaxMathEngine, TaxInvariantGuard, RoundingPolicy,
/// PreLedgerValidator.
///
/// Kompilacja:
///   cd nexus_tax_engine && maturin develop --release
///
/// Integracja z Python:
///   from nexus_tax_engine import TaxMath, InvoicePositions, ...
/// ═══════════════════════════════════════════════════════════════════════════════

pub mod error;
pub mod math;
pub mod pre_ledger;

pub use error::TaxError;
pub use math::{
    InvoicePositions, InvoiceSummary, RoundingLevel, RoundingPolicy, TaxInvariantGuard, TaxMath,
    ValidationResult,
};
pub use pre_ledger::{AmountSign, PreLedgerValidator, TransferSpec};

// ── PyO3 bindings ────────────────────────────────────────────────────────────

use std::str::FromStr;

use pyo3::exceptions::PyValueError;
use pyo3::prelude::*;

/// PyO3 wrapper for TaxMath operations.
#[pyclass(name = "TaxMath")]
struct PyTaxMath;

#[pymethods]
impl PyTaxMath {
    /// Convert a decimal string to grosze (i64) with ROUND_HALF_UP.
    #[staticmethod]
    fn to_grosze(amount: &str) -> PyResult<i64> {
        TaxMath::to_grosze(amount).map_err(|e| PyValueError::new_err(e.to_string()))
    }

    /// Convert grosze to złotówki string with 2 decimal places.
    #[staticmethod]
    fn to_zlotowki(grosze: i64) -> PyResult<String> {
        TaxMath::to_zlotowki(grosze).map_err(|e| PyValueError::new_err(e.to_string()))
    }

    /// Multiply net amount (grosze) by VAT rate, rounded to full grosze.
    #[staticmethod]
    fn multiply_net_by_vat(net_grosze: i64, vat_rate: &str) -> PyResult<i64> {
        TaxMath::multiply_net_by_vat(net_grosze, vat_rate)
            .map_err(|e| PyValueError::new_err(e.to_string()))
    }

    /// Sum net and VAT in grosze to get brutto.
    #[staticmethod]
    fn add_tax(net_grosze: i64, vat_grosze: i64) -> i64 {
        TaxMath::add_tax(net_grosze, vat_grosze)
    }

    /// Calculate total VAT according to the chosen rounding strategy.
    #[staticmethod]
    fn calculate_vat_by_policy(
        positions: Vec<PyInvoicePositions>,
        vat_rate: &str,
        rounding_level: &str,
    ) -> PyResult<i64> {
        let native_positions: Vec<InvoicePositions> = positions
            .into_iter()
            .map(|p| InvoicePositions::new(p.net_grosze, p.vat_rate))
            .collect();

        let level = RoundingLevel::from_str(rounding_level)
            .map_err(|e| PyValueError::new_err(e.to_string()))?;

        TaxMath::calculate_vat_by_policy(&native_positions, vat_rate, &level)
            .map_err(|e| PyValueError::new_err(e.to_string()))
    }

    /// Validate the three mathematical invariants of an invoice.
    #[staticmethod]
    fn validate_invariants(
        positions: Vec<PyInvoicePositions>,
        summary: PyInvoiceSummary,
    ) -> PyValidationResult {
        let native_positions: Vec<InvoicePositions> = positions
            .into_iter()
            .map(|p| InvoicePositions::new(p.net_grosze, p.vat_rate))
            .collect();

        let native_summary = InvoiceSummary::new(
            summary.netto_grosze,
            summary.vat_grosze,
            summary.brutto_grosze,
        );

        let result = TaxInvariantGuard::verify(&native_positions, &native_summary);
        PyValidationResult {
            is_valid: result.is_valid,
            error_message: result.error_message,
        }
    }

    /// Convert Decimal string to grosze with ROUND_HALF_UP.
    #[staticmethod]
    fn to_grosze_decimal(amount: &str) -> PyResult<i64> {
        let d = rust_decimal::Decimal::from_str(amount)
            .map_err(|e| PyValueError::new_err(e.to_string()))?;
        TaxMath::to_grosze_decimal(&d).map_err(|e| PyValueError::new_err(e.to_string()))
    }
}

/// PyO3 wrapper for InvoicePositions.
#[pyclass(name = "InvoicePositions")]
#[derive(Debug, Clone)]
struct PyInvoicePositions {
    #[pyo3(get)]
    net_grosze: i64,
    #[pyo3(get)]
    vat_rate: String,
}

#[pymethods]
impl PyInvoicePositions {
    #[new]
    fn new(net_grosze: i64, vat_rate: &str) -> Self {
        Self {
            net_grosze,
            vat_rate: vat_rate.to_string(),
        }
    }

    /// VAT for this line, rounded to full grosze.
    fn vat_grosze(&self) -> PyResult<i64> {
        TaxMath::multiply_net_by_vat(self.net_grosze, &self.vat_rate)
            .map_err(|e| PyValueError::new_err(e.to_string()))
    }
}

/// PyO3 wrapper for InvoiceSummary.
#[pyclass(name = "InvoiceSummary")]
#[derive(Debug, Clone)]
struct PyInvoiceSummary {
    #[pyo3(get)]
    netto_grosze: i64,
    #[pyo3(get)]
    vat_grosze: i64,
    #[pyo3(get)]
    brutto_grosze: i64,
}

#[pymethods]
impl PyInvoiceSummary {
    #[new]
    fn new(netto_grosze: i64, vat_grosze: i64, brutto_grosze: i64) -> Self {
        Self {
            netto_grosze,
            vat_grosze,
            brutto_grosze,
        }
    }

    /// Check if netto + vat == brutto.
    fn is_balanced(&self) -> bool {
        self.netto_grosze + self.vat_grosze == self.brutto_grosze
    }
}

/// PyO3 wrapper for ValidationResult.
#[pyclass(name = "ValidationResult")]
#[derive(Debug, Clone)]
struct PyValidationResult {
    #[pyo3(get)]
    is_valid: bool,
    #[pyo3(get)]
    error_message: String,
}

#[pymethods]
impl PyValidationResult {
    fn __bool__(&self) -> bool {
        self.is_valid
    }

    fn __repr__(&self) -> String {
        if self.is_valid {
            "ValidationResult(is_valid=True)".to_string()
        } else {
            format!(
                "ValidationResult(is_valid=False, error_message={:?})",
                self.error_message
            )
        }
    }
}

/// PyO3 wrapper for RoundingPolicy constants.
#[pyclass(name = "RoundingPolicy")]
struct PyRoundingPolicy;

#[pymethods]
impl PyRoundingPolicy {
    #[classattr]
    const POSITION: &'static str = "position";
    #[classattr]
    const TOTAL: &'static str = "total";

    #[staticmethod]
    fn calculate(
        positions: Vec<PyInvoicePositions>,
        vat_rate: &str,
        rounding_level: &str,
    ) -> PyResult<i64> {
        let native_positions: Vec<InvoicePositions> = positions
            .into_iter()
            .map(|p| InvoicePositions::new(p.net_grosze, p.vat_rate))
            .collect();

        RoundingPolicy::calculate(&native_positions, vat_rate, rounding_level)
            .map_err(|e| PyValueError::new_err(e.to_string()))
    }
}

/// PyO3 wrapper for PreLedgerValidator.
#[pyclass(name = "PreLedgerValidator")]
struct PyPreLedgerValidator;

#[pymethods]
impl PyPreLedgerValidator {
    #[staticmethod]
    fn validate_amount_limits(transfers: Vec<PyRef<PyTransferSpec>>) -> PyResult<bool> {
        let native_transfers: Vec<TransferSpec> = transfers
            .into_iter()
            .map(|t| TransferSpec::new(t.debit_account_id, t.credit_account_id, t.amount_grosze, t.transfer_type.clone()))
            .collect();

        PreLedgerValidator::validate_amount_limits(&native_transfers)
            .map(|_| true)
            .map_err(|e| PyValueError::new_err(e.to_string()))
    }

    #[staticmethod]
    fn validate_invariants(
        positions: Vec<PyInvoicePositions>,
        summary: PyInvoiceSummary,
    ) -> PyResult<bool> {
        let native_positions: Vec<InvoicePositions> = positions
            .into_iter()
            .map(|p| InvoicePositions::new(p.net_grosze, p.vat_rate))
            .collect();

        let native_summary = InvoiceSummary::new(
            summary.netto_grosze,
            summary.vat_grosze,
            summary.brutto_grosze,
        );

        PreLedgerValidator::validate_invariants(&native_positions, &native_summary)
            .map(|_| true)
            .map_err(|e| PyValueError::new_err(e.to_string()))
    }
}

/// PyO3 wrapper for TransferSpec.
#[pyclass(name = "TransferSpec")]
struct PyTransferSpec {
    #[pyo3(get)]
    debit_account_id: i64,
    #[pyo3(get)]
    credit_account_id: i64,
    #[pyo3(get)]
    amount_grosze: i64,
    #[pyo3(get)]
    transfer_type: String,
}

#[pymethods]
impl PyTransferSpec {
    #[new]
    fn new(
        debit_account_id: i64,
        credit_account_id: i64,
        amount_grosze: i64,
        transfer_type: &str,
    ) -> Self {
        Self {
            debit_account_id,
            credit_account_id,
            amount_grosze,
            transfer_type: transfer_type.to_string(),
        }
    }
}

/// PyO3 module definition.
#[pymodule]
fn nexus_tax_engine(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_class::<PyTaxMath>()?;
    m.add_class::<PyInvoicePositions>()?;
    m.add_class::<PyInvoiceSummary>()?;
    m.add_class::<PyValidationResult>()?;
    m.add_class::<PyRoundingPolicy>()?;
    m.add_class::<PyPreLedgerValidator>()?;
    m.add_class::<PyTransferSpec>()?;

    // Add constants
    m.add("__version__", "0.1.0")?;

    Ok(())
}
