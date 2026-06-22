/// ═══════════════════════════════════════════════════════════════════════════════
/// Nexus-TaxEngine — Tax Math Engine (Rust)
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// Integer-only arithmetic on grosze (groszy = 1/100 PLN).
/// All operations use ROUND_HALF_UP rounding via rust_decimal.
///
/// Zgodność z Pythonowym TaxMathEngine:
///   - to_grosze() → to_grosze()
///   - multiply_net_by_vat() → multiply_net_by_vat()
///   - add_tax() → add_tax()
///   - calculate_vat_by_policy() → calculate_vat_by_policy()
///   - validate_invariants() → validate_invariants()
///
/// Zasady:
///   - Całkowity zakaz float
///   - Globalnie ROUND_HALF_UP, precyzja 28 miejsc
///   - Każde zaokrąglenie jawne
/// ═══════════════════════════════════════════════════════════════════════════════

use rust_decimal::prelude::*;
use rust_decimal_macros::dec;
use serde::{Deserialize, Serialize};
use crate::error::TaxError;

// ── Rounding strategy ────────────────────────────────────────────────────────

const ROUND_STRATEGY: RoundingStrategy = RoundingStrategy::MidpointAwayFromZero;

// ── Data structures ──────────────────────────────────────────────────────────

/// A single invoice line item in grosze (immutable).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct InvoicePositions {
    pub net_grosze: i64,
    pub vat_rate: String,
}

impl InvoicePositions {
    /// Create a new invoice position.
    pub fn new(net_grosze: i64, vat_rate: impl Into<String>) -> Self {
        Self {
            net_grosze,
            vat_rate: vat_rate.into(),
        }
    }

    /// Compute VAT for this line, rounded to full grosze.
    pub fn vat_grosze(&self) -> Result<i64, TaxError> {
        TaxMath::multiply_net_by_vat(self.net_grosze, &self.vat_rate)
    }
}

/// Invoice totals in grosze (immutable).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct InvoiceSummary {
    pub netto_grosze: i64,
    pub vat_grosze: i64,
    pub brutto_grosze: i64,
}

impl InvoiceSummary {
    pub fn new(netto_grosze: i64, vat_grosze: i64, brutto_grosze: i64) -> Self {
        Self {
            netto_grosze,
            vat_grosze,
            brutto_grosze,
        }
    }

    /// Validate invariant 3: netto + vat == brutto
    pub fn is_balanced(&self) -> bool {
        self.netto_grosze + self.vat_grosze == self.brutto_grosze
    }
}

/// Result of invariant validation.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ValidationResult {
    pub is_valid: bool,
    pub error_message: String,
}

impl ValidationResult {
    pub fn ok() -> Self {
        Self {
            is_valid: true,
            error_message: String::new(),
        }
    }

    pub fn fail(message: impl Into<String>) -> Self {
        Self {
            is_valid: false,
            error_message: message.into(),
        }
    }
}

// ── Tax Math Engine ──────────────────────────────────────────────────────────

/// Infallible tax math — integer-only, ROUND_HALF_UP, no floats.
pub struct TaxMath;

impl TaxMath {
    /// Convert a decimal string to grosze (i64) with ROUND_HALF_UP.
    ///
    /// "123.45" → 12345
    /// "0.005" → 1 (HALF_UP: 0.5 → 1)
    /// "0.0049" → 0
    pub fn to_grosze(amount: &str) -> Result<i64, TaxError> {
        let d = Decimal::from_str(amount).map_err(|e| TaxError::ParseError {
            value: amount.to_string(),
            source: e.to_string(),
        })?;

        let grosze = d
            .checked_mul(dec!(100))
            .ok_or_else(|| TaxError::Overflow {
                operation: "to_grosze multiply by 100".to_string(),
            })?;

        let rounded = grosze.round_dp_with_strategy(0, ROUND_STRATEGY);

        rounded.to_i64().ok_or_else(|| TaxError::Overflow {
            operation: "to_grosze conversion to i64".to_string(),
        })
    }

    /// Convert grosze to złotówki string with 2 decimal places.
    ///
    /// 12345 → "123.45"
    pub fn to_zlotowki(grosze: i64) -> Result<String, TaxError> {
        let d = Decimal::from_i64(grosze).ok_or_else(|| TaxError::Overflow {
            operation: "to_zlotowki Decimal::from_i64".to_string(),
        })?;

        let zloty = d
            .checked_div(dec!(100))
            .ok_or_else(|| TaxError::Overflow {
                operation: "to_zlotowki divide by 100".to_string(),
            })?;

        Ok(format!("{:.2}", zloty))
    }

    /// Convert Decimal to grosze (overload for Decimal inputs).
    pub fn to_grosze_decimal(amount: &Decimal) -> Result<i64, TaxError> {
        let grosze = amount
            .checked_mul(dec!(100))
            .ok_or_else(|| TaxError::Overflow {
                operation: "to_grosze_decimal multiply by 100".to_string(),
            })?;

        let rounded = grosze.round_dp_with_strategy(0, ROUND_STRATEGY);
        rounded.to_i64().ok_or_else(|| TaxError::Overflow {
            operation: "to_grosze_decimal conversion to i64".to_string(),
        })
    }

    /// Multiply net amount (grosze) by VAT rate, rounded to full grosze.
    ///
    /// 10000 gr * "0.23" → 2300 gr
    pub fn multiply_net_by_vat(net_grosze: i64, vat_rate: &str) -> Result<i64, TaxError> {
        let net = Decimal::from_i64(net_grosze).ok_or_else(|| TaxError::Overflow {
            operation: "multiply_net_by_vat Decimal::from_i64".to_string(),
        })?;

        let rate = Decimal::from_str(vat_rate).map_err(|e| TaxError::ParseError {
            value: vat_rate.to_string(),
            source: e.to_string(),
        })?;

        let vat = net.checked_mul(rate).ok_or_else(|| TaxError::Overflow {
            operation: "multiply_net_by_vat checked_mul".to_string(),
        })?;

        let rounded = vat.round_dp_with_strategy(0, ROUND_STRATEGY);
        rounded.to_i64().ok_or_else(|| TaxError::Overflow {
            operation: "multiply_net_by_vat conversion to i64".to_string(),
        })
    }

    /// Sum net and VAT in grosze to get brutto.
    pub fn add_tax(net_grosze: i64, vat_grosze: i64) -> i64 {
        net_grosze + vat_grosze
    }

    /// Calculate total VAT according to the chosen rounding strategy.
    ///
    /// `RoundingLevel::Position` — round per line, then sum.
    /// `RoundingLevel::Total` — sum net first, then round once.
    pub fn calculate_vat_by_policy(
        positions: &[InvoicePositions],
        vat_rate: &str,
        rounding_level: &RoundingLevel,
    ) -> Result<i64, TaxError> {
        match rounding_level {
            RoundingLevel::Position => {
                let mut total_vat: i64 = 0;
                for pos in positions {
                    total_vat += TaxMath::multiply_net_by_vat(pos.net_grosze, vat_rate)?;
                }
                Ok(total_vat)
            }
            RoundingLevel::Total => {
                let sum_net: i64 = positions.iter().map(|p| p.net_grosze).sum();
                TaxMath::multiply_net_by_vat(sum_net, vat_rate)
            }
        }
    }

    /// Round-trip verification: to_grosze(to_zlotowki(x)) == x
    pub fn verify_round_trip(grosze: i64) -> Result<bool, TaxError> {
        let zloty = TaxMath::to_zlotowki(grosze)?;
        let back = TaxMath::to_grosze(&zloty)?;
        Ok(back == grosze)
    }
}

// ── Rounding Level ───────────────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub enum RoundingLevel {
    Position,
    Total,
}

impl RoundingLevel {
    pub fn from_str(s: &str) -> Result<Self, TaxError> {
        match s {
            "position" => Ok(RoundingLevel::Position),
            "total" => Ok(RoundingLevel::Total),
            other => Err(TaxError::ParseError {
                value: other.to_string(),
                source: format!("unknown rounding_level: {}", other),
            }),
        }
    }

    pub fn as_str(&self) -> &'static str {
        match self {
            RoundingLevel::Position => "position",
            RoundingLevel::Total => "total",
        }
    }
}

// ── Invariant Guard ──────────────────────────────────────────────────────────

/// Validate the three mathematical invariants of an invoice.
pub struct TaxInvariantGuard;

impl TaxInvariantGuard {
    /// Validate invariants 1-2-3.
    ///
    /// Invariant 1: sum(positions.net_grosze) == summary.netto_grosze
    /// Invariant 2: sum(positions.vat_grosze) == summary.vat_grosze
    /// Invariant 3: netto_grosze + vat_grosze == brutto_grosze
    pub fn verify(positions: &[InvoicePositions], summary: &InvoiceSummary) -> ValidationResult {
        let mut errors: Vec<String> = Vec::new();

        // Invariant 1
        let sum_net: i64 = positions.iter().map(|p| p.net_grosze).sum();
        if sum_net != summary.netto_grosze {
            let diff = sum_net - summary.netto_grosze;
            errors.push(format!(
                "Invariant 1: sum(position netto)={} gr ≠ summary netto={} gr, diff={:+} gr",
                sum_net, summary.netto_grosze, diff
            ));
        }

        // Invariant 2
        let sum_vat_result: Result<i64, TaxError> =
            positions.iter().map(|p| p.vat_grosze()).sum();

        match sum_vat_result {
            Ok(sum_vat) => {
                if sum_vat != summary.vat_grosze {
                    let diff = sum_vat - summary.vat_grosze;
                    errors.push(format!(
                        "Invariant 2: sum(position VAT)={} gr ≠ summary VAT={} gr, diff={:+} gr",
                        sum_vat, summary.vat_grosze, diff
                    ));
                }
            }
            Err(e) => {
                errors.push(format!("Invariant 2: computation error — {}", e));
            }
        }

        // Invariant 3
        let calculated_brutto = summary.netto_grosze + summary.vat_grosze;
        if calculated_brutto != summary.brutto_grosze {
            let diff = calculated_brutto - summary.brutto_grosze;
            errors.push(format!(
                "Invariant 3: netto ({} gr) + VAT ({} gr) = {} gr ≠ brutto ({} gr), diff={:+} gr",
                summary.netto_grosze,
                summary.vat_grosze,
                calculated_brutto,
                summary.brutto_grosze,
                diff
            ));
        }

        if errors.is_empty() {
            ValidationResult::ok()
        } else {
            ValidationResult::fail(errors.join("; "))
        }
    }
}

// ── Rounding Policy convenience ──────────────────────────────────────────────

pub struct RoundingPolicy;

impl RoundingPolicy {
    pub const POSITION: &'static str = "position";
    pub const TOTAL: &'static str = "total";

    pub fn calculate(
        positions: &[InvoicePositions],
        vat_rate: &str,
        rounding_level: &str,
    ) -> Result<i64, TaxError> {
        let level = RoundingLevel::from_str(rounding_level)?;
        TaxMath::calculate_vat_by_policy(positions, vat_rate, &level)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── to_grosze / to_zlotowki ────────────────────────────────────────────────

    #[test]
    fn test_to_grosze_basic() {
        assert_eq!(TaxMath::to_grosze("123.45").unwrap(), 12345);
        assert_eq!(TaxMath::to_grosze("0.01").unwrap(), 1);
        assert_eq!(TaxMath::to_grosze("0").unwrap(), 0);
        assert_eq!(TaxMath::to_grosze("0.00").unwrap(), 0);
    }

    #[test]
    fn test_to_grosze_half_up() {
        assert_eq!(TaxMath::to_grosze("0.005").unwrap(), 1);
        assert_eq!(TaxMath::to_grosze("0.0049").unwrap(), 0);
        assert_eq!(TaxMath::to_grosze("1.235").unwrap(), 124);
        assert_eq!(TaxMath::to_grosze("1.234").unwrap(), 123);
    }

    #[test]
    fn test_to_grosze_large() {
        assert_eq!(TaxMath::to_grosze("1000000.00").unwrap(), 100_000_000);
        assert_eq!(TaxMath::to_grosze("999999999.99").unwrap(), 99_999_999_999);
    }

    #[test]
    fn test_to_zlotowki() {
        assert_eq!(TaxMath::to_zlotowki(12345).unwrap(), "123.45");
        assert_eq!(TaxMath::to_zlotowki(1).unwrap(), "0.01");
        assert_eq!(TaxMath::to_zlotowki(0).unwrap(), "0.00");
        assert_eq!(TaxMath::to_zlotowki(100).unwrap(), "1.00");
    }

    #[test]
    fn test_round_trip() {
        for &grosze in &[0, 1, 100, 12345, 999999, 100_000_000] {
            let zloty = TaxMath::to_zlotowki(grosze).unwrap();
            let back = TaxMath::to_grosze(&zloty).unwrap();
            assert_eq!(back, grosze, "Round-trip failed for {} gr", grosze);
        }
    }

    #[test]
    fn test_verify_round_trip() {
        for &grosze in &[0, 1, 99, 100, 10001, 99999999] {
            assert!(TaxMath::verify_round_trip(grosze).unwrap());
        }
    }

    // ── multiply_net_by_vat ────────────────────────────────────────────────────

    #[test]
    fn test_multiply_standard_rate() {
        assert_eq!(TaxMath::multiply_net_by_vat(10000, "0.23").unwrap(), 2300);
        assert_eq!(TaxMath::multiply_net_by_vat(10000, "0.08").unwrap(), 800);
        assert_eq!(TaxMath::multiply_net_by_vat(10000, "0.05").unwrap(), 500);
        assert_eq!(TaxMath::multiply_net_by_vat(10000, "0.00").unwrap(), 0);
    }

    #[test]
    fn test_multiply_rounding() {
        assert_eq!(TaxMath::multiply_net_by_vat(1, "0.23").unwrap(), 0); // 0.23 → 0
        assert_eq!(TaxMath::multiply_net_by_vat(3, "0.23").unwrap(), 1); // 0.69 → 1
        assert_eq!(TaxMath::multiply_net_by_vat(4, "0.23").unwrap(), 1); // 0.92 → 1
        assert_eq!(TaxMath::multiply_net_by_vat(5, "0.23").unwrap(), 1); // 1.15 → 1
    }

    #[test]
    fn test_multiply_large_amount() {
        assert_eq!(
            TaxMath::multiply_net_by_vat(1_000_000, "0.23").unwrap(),
            230_000
        );
    }

    // ── add_tax ────────────────────────────────────────────────────────────────

    #[test]
    fn test_add_tax_basic() {
        assert_eq!(TaxMath::add_tax(10000, 2300), 12300);
        assert_eq!(TaxMath::add_tax(10000, 0), 10000);
        assert_eq!(TaxMath::add_tax(0, 2300), 2300);
        assert_eq!(TaxMath::add_tax(0, 0), 0);
    }

    // ── RoundingPolicy ─────────────────────────────────────────────────────────

    #[test]
    fn test_position_single_line() {
        let positions = vec![InvoicePositions::new(10000, "0.23")];
        let result = TaxMath::calculate_vat_by_policy(&positions, "0.23", &RoundingLevel::Position);
        assert_eq!(result.unwrap(), 2300);
    }

    #[test]
    fn test_position_multi_line() {
        let positions = vec![
            InvoicePositions::new(100, "0.23"),  // 23 gr
            InvoicePositions::new(200, "0.23"),  // 46 gr
            InvoicePositions::new(150, "0.23"),  // 34.5 → 35 gr
        ];
        let result = TaxMath::calculate_vat_by_policy(&positions, "0.23", &RoundingLevel::Position);
        assert_eq!(result.unwrap(), 104); // 23 + 46 + 35
    }

    #[test]
    fn test_total_multi_line() {
        let positions = vec![
            InvoicePositions::new(100, "0.23"),
            InvoicePositions::new(200, "0.23"),
            InvoicePositions::new(150, "0.23"),
        ];
        let result = TaxMath::calculate_vat_by_policy(&positions, "0.23", &RoundingLevel::Total);
        assert_eq!(result.unwrap(), 104); // 450 * 0.23 = 103.5 → 104
    }

    #[test]
    fn test_position_vs_total_difference() {
        let positions = vec![
            InvoicePositions::new(1, "0.23"),
            InvoicePositions::new(1, "0.23"),
            InvoicePositions::new(1, "0.23"),
        ];
        let pos_vat =
            TaxMath::calculate_vat_by_policy(&positions, "0.23", &RoundingLevel::Position).unwrap();
        let total_vat =
            TaxMath::calculate_vat_by_policy(&positions, "0.23", &RoundingLevel::Total).unwrap();
        assert_eq!(pos_vat, 0); // each: 0.23→0, sum: 0
        assert_eq!(total_vat, 1); // total: 0.69→1
    }

    // ── InvoicePositions ────────────────────────────────────────────────────────

    #[test]
    fn test_invoice_positions_vat_grosze() {
        let pos = InvoicePositions::new(10000, "0.23");
        assert_eq!(pos.vat_grosze().unwrap(), 2300);
    }

    #[test]
    fn test_invoice_positions_zero_vat() {
        let pos = InvoicePositions::new(10000, "0.00");
        assert_eq!(pos.vat_grosze().unwrap(), 0);
    }

    // ── Invariant Guard ─────────────────────────────────────────────────────────

    #[test]
    fn test_invariants_all_pass() {
        let positions = vec![InvoicePositions::new(10000, "0.23")];
        let summary = InvoiceSummary::new(10000, 2300, 12300);
        let result = TaxInvariantGuard::verify(&positions, &summary);
        assert!(result.is_valid);
        assert!(result.error_message.is_empty());
    }

    #[test]
    fn test_invariant_1_fails() {
        let positions = vec![InvoicePositions::new(10000, "0.23")];
        let summary = InvoiceSummary::new(9999, 2300, 12299);
        let result = TaxInvariantGuard::verify(&positions, &summary);
        assert!(!result.is_valid);
        assert!(result.error_message.contains("Invariant 1"));
    }

    #[test]
    fn test_invariant_2_fails() {
        let positions = vec![InvoicePositions::new(10000, "0.23")];
        let summary = InvoiceSummary::new(10000, 2299, 12299);
        let result = TaxInvariantGuard::verify(&positions, &summary);
        assert!(!result.is_valid);
        assert!(result.error_message.contains("Invariant 2"));
    }

    #[test]
    fn test_invariant_3_fails() {
        let positions = vec![InvoicePositions::new(10000, "0.23")];
        let summary = InvoiceSummary::new(10000, 2300, 13000);
        let result = TaxInvariantGuard::verify(&positions, &summary);
        assert!(!result.is_valid);
        assert!(result.error_message.contains("Invariant 3"));
    }

    #[test]
    fn test_invariants_all_fail() {
        let positions = vec![InvoicePositions::new(10000, "0.23")];
        let summary = InvoiceSummary::new(5000, 1000, 2000);
        let result = TaxInvariantGuard::verify(&positions, &summary);
        assert!(!result.is_valid);
        assert!(result.error_message.contains("Invariant 1"));
        assert!(result.error_message.contains("Invariant 2"));
        assert!(result.error_message.contains("Invariant 3"));
    }

    #[test]
    fn test_empty_positions_zero_summary() {
        let result = TaxInvariantGuard::verify(&[], &InvoiceSummary::new(0, 0, 0));
        assert!(result.is_valid);
    }

    #[test]
    fn test_zero_amounts() {
        let positions = vec![InvoicePositions::new(0, "0.23")];
        let summary = InvoiceSummary::new(0, 0, 0);
        let result = TaxInvariantGuard::verify(&positions, &summary);
        assert!(result.is_valid);
    }

    // ── Edge cases ──────────────────────────────────────────────────────────────

    #[test]
    fn test_negative_input_error() {
        let result = TaxMath::to_grosze("-100.00");
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), -10000);
    }

    #[test]
    fn test_invalid_rate_error() {
        let result = TaxMath::multiply_net_by_vat(10000, "not-a-number");
        assert!(result.is_err());
    }
}
