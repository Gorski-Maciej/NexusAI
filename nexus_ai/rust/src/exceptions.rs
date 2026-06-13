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
// NOTE: create_exception! doc comments generate compiler warnings in pyo3 0.22.
// Using plain // comments instead of /// to avoid ~18 redundant warnings.
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::create_exception;
use pyo3::prelude::*;

// ── Exception hierarchy ─────────────────────────────────────────────────────

// Base exception for all nexus-crypto errors.
create_exception!(nexus_crypto, CryptoError, pyo3::exceptions::PyException);

// Raised when an encryption key has an invalid length (must be 32 bytes).
create_exception!(nexus_crypto, KeyLengthError, CryptoError);

// Raised when decryption fails (wrong key, tampered ciphertext, or corrupt data).
create_exception!(nexus_crypto, DecryptionError, CryptoError);

// Raised when encryption fails.
create_exception!(nexus_crypto, EncryptionError, CryptoError);

// Raised when AEAD integrity verification fails (data has been tampered with).
create_exception!(nexus_crypto, IntegrityError, CryptoError);

// Raised when a hashing operation fails.
create_exception!(nexus_crypto, HashError, CryptoError);

// ── Module registration ────────────────────────────────────────────────────

pub fn register(module: &Bound<'_, PyModule>) -> PyResult<()> {
    module.add("CryptoError", module.py().get_type_bound::<CryptoError>())?;
    module.add("KeyLengthError", module.py().get_type_bound::<KeyLengthError>())?;
    module.add("DecryptionError", module.py().get_type_bound::<DecryptionError>())?;
    module.add("EncryptionError", module.py().get_type_bound::<EncryptionError>())?;
    module.add("IntegrityError", module.py().get_type_bound::<IntegrityError>())?;
    module.add("HashError", module.py().get_type_bound::<HashError>())?;
    Ok(())
}
