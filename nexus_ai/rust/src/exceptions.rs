// ═══════════════════════════════════════════════════════════════════════════════
// Exceptions — Custom PyO3 exception types for nexus_crypto
// ═══════════════════════════════════════════════════════════════════════════════
//
// Provides dedicated exception hierarchy instead of generic PyValueError:
//
//   CryptoError (base)
//   ├── KeyLengthError   — invalid key size
//   ├── DecryptionError  — decryption failure (wrong key / tampered data)
//   ├── EncryptionError  — encryption failure
//   ├── IntegrityError   — AEAD integrity verification failed
//   └── HashError        — hashing operation failure
//
// Python usage:
//   from nexus_crypto import CryptoError, KeyLengthError
//   try:
//       result = nexus_crypto.decrypt(key, data)
//   except KeyLengthError:
//       print("Wrong key size!")
//   except DecryptionError:
//       print("Data tampered or wrong key!")
//
// Uses `thiserror` for ergonomic Display + Error impls.
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::create_exception;
use pyo3::prelude::*;

// ── Rust-native error type (thiserror) ──────────────────────────────────────

/// Rust-native error type for cryptographic operations.
///
/// Provides ergonomic `Display` and `Error` implementations via `thiserror`.
/// Convert to PyO3 exceptions via `.into_pyerr()` or the `From` impl.
#[derive(Debug, thiserror::Error)]
pub enum CryptoErrorKind {
    #[error("Key must be exactly {expected} bytes, got {actual}")]
    KeyLength { expected: usize, actual: usize },

    #[error("Encryption failed: {0}")]
    Encryption(String),

    #[error("Decryption failed: {0}")]
    Decryption(String),

    #[error("Integrity check failed: data may have been tampered with")]
    Integrity,

    #[error("Hashing operation failed: {0}")]
    Hash(String),

    #[error("{0}")]
    General(String),

    #[error("Invalid format: {0}")]
    InvalidFormat(String),
}

impl CryptoErrorKind {
    /// Convert to a PyO3 exception value.
    pub fn into_pyerr(self) -> PyErr {
        match &self {
            CryptoErrorKind::KeyLength { .. } => KeyLengthError::new_err(self.to_string()),
            CryptoErrorKind::Encryption(_) => EncryptionError::new_err(self.to_string()),
            CryptoErrorKind::Decryption(_) => DecryptionError::new_err(self.to_string()),
            CryptoErrorKind::Integrity => IntegrityError::new_err(self.to_string()),
            CryptoErrorKind::Hash(_) => HashError::new_err(self.to_string()),
            CryptoErrorKind::General(_) => CryptoError::new_err(self.to_string()),
            CryptoErrorKind::InvalidFormat(_) => CryptoError::new_err(self.to_string()),
        }
    }
}

// ── PyO3 exception classes ──────────────────────────────────────────────────

create_exception!(nexus_crypto, CryptoError, pyo3::exceptions::PyException);
create_exception!(nexus_crypto, KeyLengthError, CryptoError);
create_exception!(nexus_crypto, DecryptionError, CryptoError);
create_exception!(nexus_crypto, EncryptionError, CryptoError);
create_exception!(nexus_crypto, IntegrityError, CryptoError);
create_exception!(nexus_crypto, HashError, CryptoError);

// ── Module registration ────────────────────────────────────────────────────

pub fn register(module: &Bound<'_, PyModule>) -> PyResult<()> {
    module.add("CryptoError", module.py().get_type_bound::<CryptoError>())?;
    module.add("KeyLengthError", module.py().get_type_bound::<KeyLengthError>())?;
    module.add("DecryptionError", module.py().get_type_bound::<DecryptionError>())?;
    module.add("EncryptionError", module.py().get_type_bound::<EncryptionError>())?;
    module.add("IntegrityError", module.py().get_type_bound::<IntegrityError>())?;
    module.add("HashError", module.py().get_type_bound::<HashError>())?;
    log::info!("exceptions: registered CryptoError hierarchy with thiserror support");
    Ok(())
}
