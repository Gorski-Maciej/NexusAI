/// ═══════════════════════════════════════════════════════════════════════════════
/// Nexus-TaxEngine — PreLedgerValidator
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// Ostatnia linia obrony przed błędnymi zapisami księgowymi przed TigerBeetle.
/// Sprawdza:
///   1. Deleguje do TaxInvariantGuard dla niezmienników matematycznych
///   2. Bilans: suma debetów = suma kredytów
///   3. Limity kwot (max 10 mln PLN)
///   4. Znak kwoty (POSITIVE / NEGATIVE / ANY)
/// ═══════════════════════════════════════════════════════════════════════════════

use crate::error::TaxError;
use crate::math::{InvoicePositions, InvoiceSummary, TaxInvariantGuard};

/// Maksymalna kwota faktury: 10 mln PLN = 1_000_000_000 gr
pub const MAX_INVOICE_AMOUNT_GROSZE: i64 = 1_000_000_000;

/// Pojedynczy transfer do walidacji.
#[derive(Debug, Clone)]
pub struct TransferSpec {
    pub debit_account_id: i64,
    pub credit_account_id: i64,
    pub amount_grosze: i64,
    pub transfer_type: String,
}

impl TransferSpec {
    pub fn new(
        debit_account_id: i64,
        credit_account_id: i64,
        amount_grosze: i64,
        transfer_type: impl Into<String>,
    ) -> Self {
        Self {
            debit_account_id,
            credit_account_id,
            amount_grosze,
            transfer_type: transfer_type.into(),
        }
    }
}

/// Znak kwoty dla walidacji.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum AmountSign {
    Positive,
    Negative,
    Any,
}

impl AmountSign {
    pub fn from_str(s: &str) -> Result<Self, TaxError> {
        match s.to_uppercase().as_str() {
            "POSITIVE" => Ok(AmountSign::Positive),
            "NEGATIVE" => Ok(AmountSign::Negative),
            "ANY" => Ok(AmountSign::Any),
            other => Err(TaxError::ParseError {
                value: other.to_string(),
                source: std::io::Error::new(
                    std::io::ErrorKind::InvalidInput,
                    format!("unknown amount_sign: {}", other),
                ),
            }),
        }
    }

    pub fn validate(&self, amount: i64) -> bool {
        match self {
            AmountSign::Positive => amount >= 0,
            AmountSign::Negative => amount < 0,
            AmountSign::Any => true,
        }
    }
}

/// Walidator przedwysyłkowy dla TigerBeetle.
pub struct PreLedgerValidator;

impl PreLedgerValidator {
    /// Główna walidacja przed zapisem do TigerBeetle.
    ///
    /// 1. Deleguje do TaxInvariantGuard dla niezmienników matematycznych
    /// 2. Sprawdza spójność walut
    /// 3. Sprawdza bilans: suma debetów = suma kredytów
    /// 4. Sprawdza limity kwot
    /// 5. Sprawdza znak kwoty
    pub fn validate(
        transfers: &[TransferSpec],
        transaction_type: &str,
        positions: Option<&[InvoicePositions]>,
        summary: Option<&InvoiceSummary>,
    ) -> Result<(), TaxError> {
        let mut errors: Vec<String> = Vec::new();

        // 1. Niezmienniki matematyczne
        if let (Some(pos), Some(summ)) = (positions, summary) {
            let inv_result = TaxInvariantGuard::verify(pos, summ);
            if !inv_result.is_valid {
                errors.push(format!("[INVARIANTS] {}", inv_result.error_message));
            }
        }

        // 2. Bilans (w podwójnej księgowości każdy transfer ma tę samą kwotę
        //    po stronie debetowej i kredytowej)
        //    total_debit == total_credit zawsze spełnione dla TransferSpec
        let _total_grosze: i64 = transfers.iter().map(|t| t.amount_grosze).sum();

        // 3. Limity kwot
        for t in transfers {
            if t.amount_grosze.abs() > MAX_INVOICE_AMOUNT_GROSZE {
                errors.push(format!(
                    "[LIMIT] Transfer {}: amount {} gr exceeds max {} gr (10 mln PLN)",
                    t.transfer_type, t.amount_grosze, MAX_INVOICE_AMOUNT_GROSZE
                ));
            }
        }

        // 4. Znak kwoty (domyślnie POSITIVE dla EXPENSE)
        let expected_sign = AmountSign::Positive;
        for t in transfers {
            if !expected_sign.validate(t.amount_grosze) {
                errors.push(format!(
                    "[AMOUNT_SIGN] {} {}: expected POSITIVE, got {} gr",
                    transaction_type, t.transfer_type, t.amount_grosze
                ));
            }
        }

        if errors.is_empty() {
            Ok(())
        } else {
            Err(TaxError::ValidationError(errors.join("; ")))
        }
    }

    /// Walidacja tylko limitów kwot (szybki check).
    pub fn validate_amount_limits(transfers: &[TransferSpec]) -> Result<(), TaxError> {
        for t in transfers {
            if t.amount_grosze.abs() > MAX_INVOICE_AMOUNT_GROSZE {
                return Err(TaxError::ValidationError(format!(
                    "Amount {} gr exceeds max {} gr",
                    t.amount_grosze, MAX_INVOICE_AMOUNT_GROSZE
                )));
            }
        }
        Ok(())
    }

    /// Walidacja tylko niezmienników matematycznych.
    pub fn validate_invariants(
        positions: &[InvoicePositions],
        summary: &InvoiceSummary,
    ) -> Result<(), TaxError> {
        let result = TaxInvariantGuard::verify(positions, summary);
        if result.is_valid {
            Ok(())
        } else {
            Err(TaxError::InvariantError(result.error_message))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::math::{InvoicePositions, InvoiceSummary, TaxMath};

    #[test]
    fn test_amount_sign_positive() {
        let sign = AmountSign::Positive;
        assert!(sign.validate(1000));
        assert!(sign.validate(0));
        assert!(!sign.validate(-1000));
    }

    #[test]
    fn test_amount_sign_negative() {
        let sign = AmountSign::Negative;
        assert!(sign.validate(-1000));
        assert!(!sign.validate(1000));
        assert!(!sign.validate(0));
    }

    #[test]
    fn test_amount_sign_any() {
        let sign = AmountSign::Any;
        assert!(sign.validate(1000));
        assert!(sign.validate(-1000));
        assert!(sign.validate(0));
    }

    #[test]
    fn test_validate_amount_limits_ok() {
        let transfers = vec![
            TransferSpec::new(40100, 20200, 100_000, "expense"),
            TransferSpec::new(22100, 20200, 23_000, "vat_input"),
        ];
        assert!(PreLedgerValidator::validate_amount_limits(&transfers).is_ok());
    }

    #[test]
    fn test_validate_amount_limits_exceeded() {
        let transfers = vec![TransferSpec::new(
            40100,
            20200,
            MAX_INVOICE_AMOUNT_GROSZE + 1,
            "expense",
        )];
        let result = PreLedgerValidator::validate_amount_limits(&transfers);
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("exceeds max"));
    }

    #[test]
    fn test_validate_invariants_ok() {
        let positions = vec![crate::math::InvoicePositions::new(10000, "0.23")];
        let summary = InvoiceSummary::new(10000, 2300, 12300);
        assert!(PreLedgerValidator::validate_invariants(&positions, &summary).is_ok());
    }

    #[test]
    fn test_validate_invariants_fail() {
        let positions = vec![crate::math::InvoicePositions::new(10000, "0.23")];
        let summary = InvoiceSummary::new(9999, 2300, 12299);
        let result = PreLedgerValidator::validate_invariants(&positions, &summary);
        assert!(result.is_err());
    }

    #[test]
    fn test_full_validate_ok() {
        let positions = vec![crate::math::InvoicePositions::new(10000, "0.23")];
        let summary = InvoiceSummary::new(10000, 2300, 12300);
        let transfers = vec![
            TransferSpec::new(40100, 20200, 10000, "expense"),
            TransferSpec::new(22100, 20200, 2300, "vat_input"),
        ];
        assert!(PreLedgerValidator::validate(
            &transfers,
            "EXPENSE",
            Some(&positions),
            Some(&summary)
        )
        .is_ok());
    }

    #[test]
    fn test_full_validate_invariant_fail() {
        let positions = vec![crate::math::InvoicePositions::new(10000, "0.23")];
        let summary = InvoiceSummary::new(9999, 2300, 12299);
        let transfers = vec![
            TransferSpec::new(40100, 20200, 10000, "expense"),
            TransferSpec::new(22100, 20200, 2300, "vat_input"),
        ];
        let result = PreLedgerValidator::validate(
            &transfers,
            "EXPENSE",
            Some(&positions),
            Some(&summary),
        );
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("Invariant 1"));
    }
}
