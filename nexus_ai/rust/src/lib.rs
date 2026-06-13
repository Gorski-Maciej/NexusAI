// ═══════════════════════════════════════════════════════════════════════════════
// Nexus-Crypto — Custom cryptographic module for NexusAI
// ═══════════════════════════════════════════════════════════════════════════════
//
// Provides:
//   1. AEAD encrypt/decrypt   (ChaCha20-Poly1305)      → src/aead.rs
//   2. Argon2id password hashing & verification         → src/password.rs
//   3. SHA-256 one-shot + streaming (Sha256Hasher)      → src/digest.rs
//   4. HMAC-SHA256                                       → src/mac.rs
//   5. BLAKE2b hashing                                   → src/blake.rs
//   6. Key generation (OsRng) & derivation (Argon2id)   → src/password.rs
//   7. Zeroize helpers                                   → src/secure.rs
//   8. Custom exceptions (CryptoError hierarchy)        → src/exceptions.rs
//
// Features:
//   - pyo3-log: Rust log!() → Python structlog
//   - Custom PyO3 exceptions: CryptoError, KeyLengthError, DecryptionError, etc.
//   - Streaming SHA-256 with copy()
//   - Secure memory zeroing via zeroize crate
//
// Build with Maturin:
//   cd nexus_ai/rust && maturin develop --release
//
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::prelude::*;
use pyo3::types::PyBytes;

mod aead;
mod blake;
mod digest;
mod exceptions;
mod jwt;
mod ksef;
mod mac;
mod password;
mod secure;
mod tax;

// ═══════════════════════════════════════════════════════════════════════════════
// Python bindings (PyO3)
// ═══════════════════════════════════════════════════════════════════════════════

// ── Sha256Hasher — streaming SHA-256 (PyClass) ────────────────────────────────

/// Streaming SHA-256 hasher (replaces ``hashlib.sha256()``).
///
/// Usage:
///     h = Sha256Hasher()
///     h.update(chunk1)
///     h.update(chunk2)
///     return h.hexdigest()
///
/// Methods:
///     update(data: bytes)    — feed data into the hasher
///     hexdigest() -> str     — return 64-char hex digest
///     digest() -> bytes      — return 32-byte raw digest
#[pyclass(name = "Sha256Hasher")]
struct Sha256Hasher {
    inner: digest::StreamingSha256,
}

#[pymethods]
impl Sha256Hasher {
    #[new]
    fn new() -> Self {
        log::debug!("Sha256Hasher created");
        Self {
            inner: digest::StreamingSha256::new(),
        }
    }

    /// Feed data into the hasher.
    /// Can be called multiple times for streaming.
    fn update(&mut self, data: &[u8]) {
        self.inner.update(data);
    }

    /// Return the hex digest (64-char string) without consuming the hasher.
    fn hexdigest(&self) -> String {
        self.inner.hexdigest()
    }

    /// Return the raw 32-byte digest without consuming the hasher.
    fn digest(&self, py: Python<'_>) -> Py<PyBytes> {
        let raw = self.inner.digest();
        PyBytes::new_bound(py, &raw).into()
    }

    /// Return a copy of the hasher (preserves current state).
    fn copy(&self) -> Self {
        Self {
            inner: digest::StreamingSha256::copy(&self.inner),
        }
    }

    fn __repr__(&self) -> String {
        "<Sha256Hasher>".to_string()
    }
}

/// Generate a cryptographically secure 32-byte key.
///
/// Uses OS entropy (OsRng) for key generation.
///
/// Returns:
///     32 random bytes suitable for use as an encryption key.
#[pyfunction]
fn generate_key(py: Python<'_>) -> Py<PyBytes> {
    use rand::TryRngCore;
    let mut key = vec![0u8; 32];
    rand::rngs::OsRng
        .try_fill_bytes(&mut key)
        .expect("OsRng failed to generate key");
    log::debug!("Generated new 32-byte encryption key");
    PyBytes::new_bound(py, &key).into()
}

/// Encrypt data using ChaCha20-Poly1305 (AEAD).
///
/// Args:
///     key: 32-byte encryption key (bytes).
///     plaintext: Data to encrypt (bytes).
///
/// Returns:
///     Ciphertext bytes: nonce (12B) || encrypted data.
///
/// Raises:
///     KeyLengthError: If key is not exactly 32 bytes.
///     EncryptionError: If encryption fails.
#[pyfunction]
fn encrypt(py: Python<'_>, key: &[u8], plaintext: &[u8]) -> PyResult<Py<PyBytes>> {
    log::info!("encrypt: {} bytes with {} byte key", plaintext.len(), key.len());
    let ciphertext = aead::encrypt(key, plaintext).map_err(|e| {
        if e.contains("Key must be exactly") {
            exceptions::KeyLengthError::new_err(e)
        } else {
            exceptions::EncryptionError::new_err(e)
        }
    })?;
    log::debug!("encrypt: success, {} bytes output", ciphertext.len());
    Ok(PyBytes::new_bound(py, &ciphertext).into())
}

/// Decrypt data encrypted with `encrypt`.
///
/// Args:
///     key: 32-byte encryption key (bytes).
///     data: nonce (12B) || ciphertext (bytes).
///
/// Returns:
///     Decrypted plaintext (bytes).
///
/// Raises:
///     KeyLengthError: If key is not exactly 32 bytes.
///     DecryptionError: If decryption fails (wrong key or tampered data).
///     IntegrityError: If AEAD integrity check fails.
#[pyfunction]
fn decrypt(py: Python<'_>, key: &[u8], data: &[u8]) -> PyResult<Py<PyBytes>> {
    log::info!("decrypt: {} bytes of ciphertext", data.len());
    let plaintext = aead::decrypt(key, data).map_err(|e| {
        if e.contains("Key must be exactly") {
            exceptions::KeyLengthError::new_err(e)
        } else        if e.contains("Decryption failed") {
            // Map AEAD failures to DecryptionError; AEAD implicitly
            // verifies integrity (tag mismatch = decryption failure)
            exceptions::DecryptionError::new_err(e)
        } else {
            exceptions::DecryptionError::new_err(e)
        }
    })?;
    log::debug!("decrypt: success, {} bytes plaintext", plaintext.len());
    Ok(PyBytes::new_bound(py, &plaintext).into())
}

/// Hash a password using Argon2id.
///
/// Args:
///     password: Password string to hash.
///
/// Returns:
///     PHC string containing the encoded hash + salt + params.
///
/// Raises:
///     HashError: If hashing fails.
#[pyfunction]
fn hash_password(password: &str) -> PyResult<String> {
    log::info!("hash_password: hashing password with Argon2id");
    password::hash(password)
        .map_err(|e| exceptions::HashError::new_err(e))
}

/// Verify a password against an Argon2id PHC hash.
///
/// Args:
///     password: Password string to verify.
///     hash_str: PHC hash string (from `hash_password`).
///
/// Returns:
///     True if password matches the hash.
///
/// Raises:
///     HashError: If verification fails due to invalid hash format.
#[pyfunction]
fn verify_password(password: &str, hash_str: &str) -> PyResult<bool> {
    log::debug!("verify_password: verifying against PHC hash");
    password::verify(password, hash_str)
        .map_err(|e| exceptions::HashError::new_err(e))
}

/// Compute SHA-256 hex digest.
///
/// Args:
///     data: Data bytes to hash.
///
/// Returns:
///     64-character hex string.
#[pyfunction]
fn sha256(data: &[u8]) -> String {
    log::debug!("sha256: hashing {} bytes", data.len());
    digest::sha256_hex(data)
}

/// Compute HMAC-SHA256 digest.
///
/// Args:
///     key: Secret key (bytes).
///     data: Message to authenticate (bytes).
///
/// Returns:
///     32-byte HMAC-SHA256 digest.
///
/// Raises:
///     CryptoError: If HMAC computation fails.
#[pyfunction]
fn hmac_sha256(py: Python<'_>, key: &[u8], data: &[u8]) -> PyResult<Py<PyBytes>> {
    log::debug!("hmac_sha256: computing HMAC-SHA256");
    let digest = mac::hmac_sha256(key, data)
        .map_err(|e| pyo3::exceptions::PyValueError::new_err(e))?;
    Ok(PyBytes::new_bound(py, &digest).into())
}

/// Compute BLAKE2b digest.
///
/// Args:
///     data: Data bytes to hash.
///     digest_size: Output size in bytes (1-64, default 64).
///
/// Returns:
///     BLAKE2b digest as bytes.
///
/// Raises:
///     CryptoError: If hashing fails.
#[pyfunction]
fn blake2b(py: Python<'_>, data: &[u8], digest_size: u8) -> PyResult<Py<PyBytes>> {
    log::debug!("blake2b: hashing {} bytes, size={}", data.len(), digest_size);
    let digest = blake::blake2b(data, digest_size)
        .map_err(|e| exceptions::HashError::new_err(e))?;
    Ok(PyBytes::new_bound(py, &digest).into())
}

/// Derive an encryption key from a password using Argon2id.
///
/// Args:
///     password: Password to derive key from.
///     salt: Optional 16-byte salt. If empty, generates a random one.
///
/// Returns:
///     Tuple of (derived_key: bytes, salt: bytes).
///
/// Raises:
///     HashError: If key derivation fails.
#[pyfunction]
#[pyo3(signature = (password, salt=None))]
fn derive_key(password: &str, salt: Option<&[u8]>) -> PyResult<(Vec<u8>, Vec<u8>)> {
    let salt_bytes = salt.unwrap_or_default();
    log::info!("derive_key: deriving 32-byte key from password with {} byte salt", salt_bytes.len());
    password::derive(password, salt_bytes)
        .map_err(|e| exceptions::HashError::new_err(e))
}

/// Python module definition.
///
/// Registers all functions, classes, and custom exceptions.
/// Initializes `pyo3-log` so Rust `log::info!()` / `log::debug!()` calls
/// are forwarded to Python's structlog.
///
/// NOTE: Function name must match the last segment of module-name
/// in pyproject.toml (i.e., `_core` for `module-name = "nexus_crypto._core"`).
#[pymodule]
fn _core(m: &Bound<'_, PyModule>) -> PyResult<()> {
    // Initialize pyo3-log: Rust log!() → Python logging → structlog
    // This must happen FIRST, before any other initialization
    // Use let _ = to gracefully handle double-init (e.g., importlib.reload)
    let _ = pyo3_log::init();

    // Register custom exception hierarchy
    exceptions::register(m)?;
    log::info!("nexus_crypto module initialized with custom exceptions");

    // Register functions
    m.add_function(wrap_pyfunction!(encrypt, m)?)?;
    m.add_function(wrap_pyfunction!(decrypt, m)?)?;
    m.add_function(wrap_pyfunction!(hash_password, m)?)?;
    m.add_function(wrap_pyfunction!(verify_password, m)?)?;
    m.add_function(wrap_pyfunction!(sha256, m)?)?;
    m.add_function(wrap_pyfunction!(derive_key, m)?)?;
    m.add_function(wrap_pyfunction!(generate_key, m)?)?;
    m.add_function(wrap_pyfunction!(hmac_sha256, m)?)?;
    m.add_function(wrap_pyfunction!(blake2b, m)?)?;

    // Register classes
    m.add_class::<Sha256Hasher>()?;

    // Register TaxMathEngine (Rust + PyO3 — integer-only tax arithmetic)
    tax::register(m)?;

    // Register JWT verification
    jwt::register(m)?;

    // Register KSeF XML generator
    ksef::register(m)?;

    log::info!("nexus_crypto: registered 9 functions, 1 class, 5 custom exceptions, TaxMathEngine, JWT, KSeF");
    Ok(())
}
