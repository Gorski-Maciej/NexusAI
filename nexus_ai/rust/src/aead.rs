// ═══════════════════════════════════════════════════════════════════════════════
// AEAD — ChaCha20-Poly1305 Authenticated Encryption
// ═══════════════════════════════════════════════════════════════════════════════
//
// Provides:
//   1. encrypt(key, plaintext)          — ChaCha20-Poly1305 AEAD
//   2. decrypt(key, data)               — ChaCha20-Poly1305 AEAD + decryption
//   3. decrypt_into_sensitive(key, data) — decrypt into SensitiveBytes (RAII)
//
// Integracja z secure.rs:
//   - encrypt(key: &[u8], ...)           — działa też z &SensitiveBytes / &MlockedVec
//   - decrypt(key: &[u8], ...)           — działa też z &SensitiveBytes / &MlockedVec
//   - decrypt_into_sensitive(...)        — zwraca SensitiveBytes z plaintextem
//
// Wszystkie funkcje przyjmują &[u8] dla klucza — SensitiveBytes i MlockedVec
// implementują Deref<Target=[u8]>, więc działają bez konwersji.
//
// Conforms to the aa3fvcx.txt spec: replaces Fernet (AES-128-CBC+HMAC) with
// ChaCha20-Poly1305 AEAD as the primary encryption scheme.
// ═══════════════════════════════════════════════════════════════════════════════

use chacha20poly1305::{
    aead::{Aead, AeadCore, KeyInit, OsRng},
    ChaCha20Poly1305, Nonce,
};

use crate::secure::SensitiveBytes;

const NONCE_LEN: usize = 12;
const KEY_LEN: usize = 32;

// ═══════════════════════════════════════════════════════════════════════════════
// encrypt — ChaCha20-Poly1305 authenticated encryption
// ═══════════════════════════════════════════════════════════════════════════════
//
// Args:
//     key: 32-byte encryption key. Accepts &[u8], &SensitiveBytes, &MlockedVec
//           (wszystkie przez Deref<Target=[u8]>).
//     plaintext: Data to encrypt.
//
// Returns:
//     nonce (12B) || ciphertext — ready for storage or transmission.

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

// ═══════════════════════════════════════════════════════════════════════════════
// decrypt — ChaCha20-Poly1305 authenticated decryption
// ═══════════════════════════════════════════════════════════════════════════════
//
// Args:
//     key: 32-byte encryption key (accepts &[u8], &SensitiveBytes, &MlockedVec).
//     data: nonce (12B) || ciphertext — output of encrypt().
//
// Returns:
//     Decrypted plaintext as Vec<u8>.
//     For RAII auto-zeroizing plaintext, use decrypt_into_sensitive().

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

// ═══════════════════════════════════════════════════════════════════════════════
// decrypt_into_sensitive — decrypt with RAII-protected output
// ═══════════════════════════════════════════════════════════════════════════════
//
// Jak decrypt(), ale zwraca SensitiveBytes zamiast Vec<u8>.
// Plaintext jest automatycznie zerowany (zeroize) na drop.
//
// Usage:
//     let plaintext = decrypt_into_sensitive(&key, &ciphertext)?;
//     // ... use plaintext ...
//     // plaintext.drop() → zeroize automatically
//     // No need to manually zeroize!

/// Decrypt data and return the plaintext wrapped in SensitiveBytes (RAII).
///
/// The returned SensitiveBytes is automatically zeroized on drop.
/// Prefer this over decrypt() when handling sensitive plaintext.
///
/// Args:
///     key: 32-byte encryption key (accepts &[u8], &SensitiveBytes, &MlockedVec).
///     data: nonce (12B) || ciphertext from encrypt().
///
/// Returns:
///     SensitiveBytes containing the decrypted plaintext.
pub fn decrypt_into_sensitive(key: &[u8], data: &[u8]) -> Result<SensitiveBytes, String> {
    let plaintext = decrypt(key, data)?;
    log::debug!(
        "decrypt_into_sensitive: {} bytes plaintext wrapped in SensitiveBytes (RAII)",
        plaintext.len()
    );
    Ok(SensitiveBytes::from_vec(plaintext))
}
