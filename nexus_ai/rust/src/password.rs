// ═══════════════════════════════════════════════════════════════════════════════
// Password — Argon2id password hashing & verification
// ═══════════════════════════════════════════════════════════════════════════════
//
// Provides:
//   1. hash(password) — Argon2id PHC string generation
//   2. verify(password, hash_str) — Argon2id verification
//   3. derive_key(password, salt) — Key derivation function (KDF)
//
// Conforms to aa3fvcx.txt: Argon2id (PHC winner) replaces PBKDF2.
// ═══════════════════════════════════════════════════════════════════════════════

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

/// Derive a 32-byte key from a password + salt using Argon2id.
pub fn derive(password: &str, salt: &[u8]) -> Result<(Vec<u8>, Vec<u8>), String> {
    use crate::secure;

    let mut salt_bytes = if salt.len() >= 16 {
        salt[..16].to_vec()
    } else {        let mut buf = vec![0u8; 16];
        use rand::TryRngCore;
        rand::rngs::OsRng
            .try_fill_bytes(&mut buf)
            .map_err(|e| format!("OsRng failed: {e}"))?;
        buf
    };

    let mut derived_key = vec![0u8; 32];
    Argon2::default()
        .hash_password_into(password.as_bytes(), &salt_bytes, &mut derived_key)
        .map_err(|e| e.to_string())?;

    let result_key = derived_key.clone();
    let result_salt = salt_bytes.clone();

    // Securely zero sensitive buffers
    secure::zero_vec(&mut derived_key);
    secure::zero_vec(&mut salt_bytes);

    Ok((result_key, result_salt))
}
