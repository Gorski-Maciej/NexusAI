// ═══════════════════════════════════════════════════════════════════════════════
// Nexus-Crypto — Custom cryptographic module for NexusAI
// ═══════════════════════════════════════════════════════════════════════════════
//
// Provides three high-level operations:
//   1. AEAD encrypt/decrypt  (ChaCha20-Poly1305)
//   2. Argon2id password hashing & verification
//   3. SHA-256 hashing
//
// Replaces the ~5 MB `cryptography` library with ~50 KB of native Rust.
//
// Build with Maturin:
//   cd nexus_crypto && maturin develop --release
//
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::prelude::*;

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

// ── SHA-256 ──────────────────────────────────────────────────────────────────
mod digest {
    use sha2::{Digest, Sha256};

    /// Compute SHA-256 hex digest of `data`.
    pub fn sha256_hex(data: &[u8]) -> String {
        let mut hasher = Sha256::new();
        hasher.update(data);
        hex::encode(hasher.finalize())
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Python bindings (PyO3)
// ═══════════════════════════════════════════════════════════════════════════════

/// Encrypt data using ChaCha20-Poly1305 (AEAD).
///
/// Args:
///     key: 32-byte encryption key (bytes).
///     plaintext: Data to encrypt (bytes).
///
/// Returns:
///     Ciphertext bytes: nonce (12B) || encrypted data.
#[pyfunction]
fn encrypt(key: &[u8], plaintext: &[u8]) -> PyResult<pyo3::types::PyBytes> {
    let ciphertext = aead::encrypt(key, plaintext)
        .map_err(|e| pyo3::exceptions::PyValueError::new_err(e))?;
    Ok(pyo3::types::PyBytes::new_bound(pyo3::Python::with_gil(|py| py), &ciphertext))
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
fn decrypt(key: &[u8], data: &[u8]) -> PyResult<pyo3::types::PyBytes> {
    let plaintext = aead::decrypt(key, data)
        .map_err(|e| pyo3::exceptions::PyValueError::new_err(e))?;
    Ok(pyo3::types::PyBytes::new_bound(pyo3::Python::with_gil(|py| py), &plaintext))
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

/// Derive an encryption key from a password using Argon2id.
///
/// Args:
///     password: Password to derive key from.
///     salt: Optional 16-byte salt. If empty, generates a random one.
///
/// Returns:
///     Tuple of (derived_key: bytes, salt: bytes).
#[pyfunction]
fn derive_key(password: &str, salt: Option<&[u8]>) -> PyResult<(Vec<u8>, Vec<u8>)> {
    use argon2::Argon2;
    use rand::RngCore;

    let salt_bytes = match salt {
        Some(s) if s.len() >= 16 => s[..16].to_vec(),
        _ => {
            let mut buf = vec![0u8; 16];
            rand::rngs::OsRng.fill_bytes(&mut buf);
            buf
        }
    };

    let mut derived_key = vec![0u8; 32];
    Argon2::default()
        .hash_password_into(password.as_bytes(), &salt_bytes, &mut derived_key)
        .map_err(|e| pyo3::exceptions::PyValueError::new_err(e.to_string()))?;

    Ok((derived_key, salt_bytes))
}

/// Python module definition.
#[pymodule]
fn _core(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(encrypt, m)?)?;
    m.add_function(wrap_pyfunction!(decrypt, m)?)?;
    m.add_function(wrap_pyfunction!(hash_password, m)?)?;
    m.add_function(wrap_pyfunction!(verify_password, m)?)?;
    m.add_function(wrap_pyfunction!(sha256, m)?)?;
    m.add_function(wrap_pyfunction!(derive_key, m)?)?;
    Ok(())
}
