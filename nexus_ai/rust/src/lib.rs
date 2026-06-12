// ═══════════════════════════════════════════════════════════════════════════════
// Nexus-Crypto — Custom cryptographic module for NexusAI
// ═══════════════════════════════════════════════════════════════════════════════
//
// Provides:
//   1. AEAD encrypt/decrypt   (ChaCha20-Poly1305)
//   2. Argon2id password hashing & verification
//   3. SHA-256 one-shot + streaming (Sha256Hasher)
//   4. HMAC-SHA256
//   5. BLAKE2b hashing
//   6. Key generation (OsRng) & derivation (Argon2id)
//
// Streaming SHA-256 (Sha256Hasher) — replaces hashlib.sha256():
//   h = Sha256Hasher()
//   h.update(chunk1)
//   h.update(chunk2)
//   digest = h.hexdigest()   # or h.digest() for raw bytes
//   copy = h.copy()          # snapshot current state
//
// Replaces the ~5 MB `cryptography` library with ~50 KB of native Rust.
//
// Build with Maturin:
//   cd nexus_ai/rust && maturin develop --release
//
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::prelude::*;
use pyo3::types::PyBytes;

// ── AEAD (ChaCha20-Poly1305) ─────────────────────────────────────────────────
mod aead {
    use chacha20poly1305::{
        aead::{Aead, AeadCore, KeyInit, OsRng},
        ChaCha20Poly1305, Nonce,
    };

    const NONCE_LEN: usize = 12;
    const KEY_LEN: usize = 32;

    /// Encrypt `plaintext` with `key` using ChaCha20-Poly1305.
    /// Returns: nonce (12B) || ciphertext (variable)
    pub fn encrypt(key: &[u8], plaintext: &[u8]) -> Result<Vec<u8>, String> {
        if key.len() != KEY_LEN {
            return Err(format!(
                "Key must be exactly {KEY_LEN} bytes, got {}",
                key.len()
            ));
        }
        let cipher = ChaCha20Poly1305::new_from_slice(key).map_err(|e| e.to_string())?;
        let nonce = ChaCha20Poly1305::generate_nonce(&mut OsRng);
        let ciphertext = cipher
            .encrypt(&nonce, plaintext)
            .map_err(|e| e.to_string())?;
        let mut result = nonce.to_vec();
        result.extend_from_slice(&ciphertext);
        Ok(result)
    }

    /// Decrypt data created by `encrypt`.
    /// Input: nonce (12B) || ciphertext
    pub fn decrypt(key: &[u8], data: &[u8]) -> Result<Vec<u8>, String> {
        if key.len() != KEY_LEN {
            return Err(format!(
                "Key must be exactly {KEY_LEN} bytes, got {}",
                key.len()
            ));
        }
        if data.len() < NONCE_LEN {
            return Err("Data too short: missing nonce".to_string());
        }
        let (nonce_bytes, ciphertext) = data.split_at(NONCE_LEN);
        let cipher = ChaCha20Poly1305::new_from_slice(key).map_err(|e| e.to_string())?;
        let nonce = Nonce::from_slice(nonce_bytes);
        cipher
            .decrypt(nonce, ciphertext)
            .map_err(|e| format!("Decryption failed: {e}"))
    }
}

// ── Argon2id password hashing ─────────────────────────────────────────────────
mod password {
    use argon2::{
        password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
        Argon2,
    };

    /// Hash a password using Argon2id with default parameters.
    /// Returns the PHC string (encoded hash).
    pub fn hash(password: &str) -> Result<String, String> {
        let salt = SaltString::generate(&mut OsRng);
        let argon2 = Argon2::default();
        let hash = argon2
            .hash_password(password.as_bytes(), &salt)
            .map_err(|e| e.to_string())?;
        Ok(hash.to_string())
    }

    /// Verify a password against a PHC string hash.
    pub fn verify(password: &str, hash_str: &str) -> Result<bool, String> {
        let parsed_hash = PasswordHash::new(hash_str).map_err(|e| e.to_string())?;
        Ok(Argon2::default()
            .verify_password(password.as_bytes(), &parsed_hash)
            .is_ok())
    }
}

// ── HMAC-SHA256 ────────────────────────────────────────────────────────────
mod mac {
    use hmac::{Hmac, Mac};
    use sha2::Sha256;

    type HmacSha256 = Hmac<Sha256>;

    /// Compute HMAC-SHA256 of `data` with `key`.
    /// Returns 32 bytes (raw digest).
    pub fn hmac_sha256(key: &[u8], data: &[u8]) -> Result<[u8; 32], String> {
        let mut mac = HmacSha256::new_from_slice(key).map_err(|e| e.to_string())?;
        mac.update(data);
        let result = mac.finalize();
        let code = result.into_bytes();
        let mut digest = [0u8; 32];
        digest.copy_from_slice(&code);
        Ok(digest)
    }
}

// ── BLAKE2b (keyed hashing, deterministic) ─────────────────────────────────--
mod blake {
    use blake2::{Blake2b512, Digest};

    /// Compute BLAKE2b digest of `data` with configurable output size (1-64 bytes).
    /// Used for deterministic TigerBeetle account ID mapping.
    pub fn blake2b(data: &[u8], digest_size: u8) -> Result<Vec<u8>, String> {
        let size = digest_size.max(1).min(64) as usize;
        let mut hasher = Blake2b512::new();
        hasher.update(data);
        let result = hasher.finalize();
        // Blake2b512 produces 64 bytes; truncate to requested size
        Ok(result[..size].to_vec())
    }
}

// ── SHA-256 (one-shot + streaming) ──────────────────────────────────────────
mod digest {
    use sha2::{Digest, Sha256};

    /// Compute SHA-256 hex digest of `data` (one-shot).
    pub fn sha256_hex(data: &[u8]) -> String {
        let mut hasher = Sha256::new();
        hasher.update(data);
        hex::encode(hasher.finalize())
    }

    /// Streaming SHA-256 hasher.
    /// Python wrapper: `Sha256Hasher`
    pub struct StreamingSha256 {
        inner: Sha256,
    }

    impl StreamingSha256 {
        pub fn new() -> Self {
            Self {
                inner: Sha256::new(),
            }
        }

        pub fn update(&mut self, data: &[u8]) {
            self.inner.update(data);
        }

        /// Return hex digest without consuming the hasher.
        pub fn hexdigest(&self) -> String {
            hex::encode(self.inner.clone().finalize())
        }

        /// Return raw 32-byte digest without consuming the hasher.
        pub fn digest(&self) -> [u8; 32] {
            self.inner.clone().finalize().into()
        }

        /// Return a deep copy of the streaming hasher.
        pub fn copy(&self) -> Self {
            Self {
                inner: self.inner.clone(),
            }
        }
    }
}

// ── Zeroize helper — securely clear sensitive memory ─────────────────────────
// Uses the `zeroize` crate to zero out sensitive data on drop.
// NOTE: Only affects Rust-side buffers (Vec<u8>). Python bytes objects
// are immutable — key zeroing must happen at the Python caller level
// (del key + gc.collect()).
mod secure {
    use zeroize::Zeroize;

    /// Securely zero out a mutable byte slice.
    pub fn zero(data: &mut [u8]) {
        data.zeroize();
    }

    /// Securely zero out a Vec<u8>.
    pub fn zero_vec(data: &mut Vec<u8>) {
        data.zeroize();
    }
}

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
#[pyfunction]
fn encrypt(py: Python<'_>, key: &[u8], plaintext: &[u8]) -> PyResult<Py<PyBytes>> {
    let ciphertext = aead::encrypt(key, plaintext)
        .map_err(|e| pyo3::exceptions::PyValueError::new_err(e))?;
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
#[pyfunction]
fn decrypt(py: Python<'_>, key: &[u8], data: &[u8]) -> PyResult<Py<PyBytes>> {
    let plaintext = aead::decrypt(key, data)
        .map_err(|e| pyo3::exceptions::PyValueError::new_err(e))?;
    Ok(PyBytes::new_bound(py, &plaintext).into())
}

/// Hash a password using Argon2id.
///
/// Args:
///     password: Password string to hash.
///
/// Returns:
///     PHC string containing the encoded hash + salt + params.
#[pyfunction]
fn hash_password(password: &str) -> PyResult<String> {
    password::hash(password).map_err(|e| pyo3::exceptions::PyValueError::new_err(e))
}

/// Verify a password against an Argon2id PHC hash.
///
/// Args:
///     password: Password string to verify.
///     hash_str: PHC hash string (from `hash_password`).
///
/// Returns:
///     True if password matches the hash.
#[pyfunction]
fn verify_password(password: &str, hash_str: &str) -> PyResult<bool> {
    password::verify(password, hash_str).map_err(|e| pyo3::exceptions::PyValueError::new_err(e))
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
#[pyfunction]
fn hmac_sha256(py: Python<'_>, key: &[u8], data: &[u8]) -> PyResult<Py<PyBytes>> {
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
#[pyfunction]
fn blake2b(py: Python<'_>, data: &[u8], digest_size: u8) -> PyResult<Py<PyBytes>> {
    let digest = blake::blake2b(data, digest_size)
        .map_err(|e| pyo3::exceptions::PyValueError::new_err(e))?;
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
#[pyfunction]
#[pyo3(signature = (password, salt=None))]
fn derive_key(password: &str, salt: Option<&[u8]>) -> PyResult<(Vec<u8>, Vec<u8>)> {
    use argon2::Argon2;
    use rand::RngCore;

    let mut salt_bytes = match salt {
        Some(s) if s.len() >= 16 => s[..16].to_vec(),
        _ => {
            let mut buf = vec![0u8; 16];
            use rand::TryRngCore;
            rand::rngs::OsRng
                .try_fill_bytes(&mut buf)
                .expect("OsRng failed to generate salt");
            buf
        }
    };

    let mut derived_key = vec![0u8; 32];
    Argon2::default()
        .hash_password_into(password.as_bytes(), &salt_bytes, &mut derived_key)
        .map_err(|e| pyo3::exceptions::PyValueError::new_err(e.to_string()))?;

    // Clone results before zeroizing intermediates
    let result_key = derived_key.clone();
    let result_salt = salt_bytes.clone();

    // Securely zero sensitive buffers
    secure::zero_vec(&mut derived_key);
    secure::zero_vec(&mut salt_bytes);

    Ok((result_key, result_salt))
}

/// Python module definition.
#[pymodule]
fn nexus_crypto(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(encrypt, m)?)?;
    m.add_function(wrap_pyfunction!(decrypt, m)?)?;
    m.add_function(wrap_pyfunction!(hash_password, m)?)?;
    m.add_function(wrap_pyfunction!(verify_password, m)?)?;
    m.add_function(wrap_pyfunction!(sha256, m)?)?;
    m.add_function(wrap_pyfunction!(derive_key, m)?)?;
    m.add_function(wrap_pyfunction!(generate_key, m)?)?;
    m.add_function(wrap_pyfunction!(hmac_sha256, m)?)?;
    m.add_function(wrap_pyfunction!(blake2b, m)?)?;
    m.add_class::<Sha256Hasher>()?;
    Ok(())
}
