// ═══════════════════════════════════════════════════════════════════════════════
// AEAD — ChaCha20-Poly1305 Authenticated Encryption
// ═══════════════════════════════════════════════════════════════════════════════
//
// Provides:
//   1. encrypt(key, plaintext) — ChaCha20-Poly1305 AEAD
//   2. decrypt(key, data) — ChaCha20-Poly1305 AEAD verification + decryption
//
// Conforms to the aa3fvcx.txt spec: replaces Fernet (AES-128-CBC+HMAC) with
// ChaCha20-Poly1305 AEAD as the primary encryption scheme.
// ═══════════════════════════════════════════════════════════════════════════════

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
