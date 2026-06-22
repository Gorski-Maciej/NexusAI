/// ═══════════════════════════════════════════════════════════════════════════════
/// Nexus-TaxEngine — Error Types
/// ═══════════════════════════════════════════════════════════════════════════════

use thiserror::Error;

#[derive(Error, Debug, Clone, PartialEq)]
pub enum TaxError {
    #[error("Parse error for value '{value}': {source}")]
    ParseError {
        value: String,
        source: String,
    },

    #[error("Arithmetic overflow during {operation}")]
    Overflow {
        operation: String,
    },

    #[error("Invariant violation: {0}")]
    InvariantError(String),

    #[error("Invalid rounding level: {0}")]
    InvalidRoundingLevel(String),

    #[error("Validation failed: {0}")]
    ValidationError(String),

    #[error("Rule engine error: {0}")]
    RuleEngineError(String),

    #[error("TigerBeetle error: {0}")]
    TigerBeetleError(String),
}

unsafe impl Send for TaxError {}
unsafe impl Sync for TaxError {}

impl From<TaxError> for String {
    fn from(e: TaxError) -> Self {
        e.to_string()
    }
}
